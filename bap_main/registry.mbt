// Plugins, extensions, and the global framework state.
//
// OCaml BAP discovers plugins as `.plugin` bundles and loads them with
// `Dynlink`; the toplevel expressions of a plugin call `Extension.declare`,
// `Configuration.parameter`, `Command.declare`, etc., and those
// declarations are attributed to the plugin when the loader reports it as
// loaded. Dynamic loading is not available in MoonBit, so this port keeps a
// static registry of plugin initialization functions (`register_plugin`).
// During `init`, every selected plugin's function is called in alphabetical
// order, exactly where BAP would dynlink the bundle; the declarations it
// performs are attributed to it in the same way.

///|
priv struct PluginEntry {
  name : String
  provides : Array[String]
  features : Array[String]
  doc : String
  load : () -> Unit raise
}

///|
/// The per-plugin context used to build plugin options.
priv struct PluginCtxt {
  name : String
  config : Array[(String, String)]
  getenv : (String) -> String?
}

///|
/// The declarations collected while a plugin is being loaded.
priv struct Slot {
  specs : Array[(PluginCtxt) -> Term[() -> Unit raise] raise]
  mut page : Array[ManBlock]
  codes : Array[(Ctxt) -> Unit raise]
  mut info : PluginInfo?
  actions : Array[(String, String)]
}

///|
fn Slot::new() -> Slot {
  { specs: [], page: [], codes: [], info: None, actions: [], }
}

///|
priv struct CommandDecl {
  name : String
  term : Term[(Ctxt) -> Unit raise]
  doc : String
  man : Array[ManBlock]
  requires : Array[String]?
}

///|
priv struct LoadedPlugin {
  name : String
  spec : Array[Term[() -> Unit raise]]
  code : Array[(Ctxt) -> Unit raise]
}

///|
priv enum Status {
  Uninitialized
  Initializing
  Loaded(Array[String])
  Failed(Error)
}

///|
priv struct MainState {
  mut slot : Slot
  registry : Array[PluginEntry]
  loaded : Array[LoadedPlugin]
  plugin_pages : Map[String, Array[ManBlock]]
  plugin_infos : Array[(String, PluginInfo)]
  plugin_cmds : Array[(String, Array[(String, String)])]
  commands : Array[CommandDecl]
  mut status : Status
  mut log_subscription : Int?
}

///|
fn fresh_main_state() -> MainState {
  {
    slot: Slot::new(),
    registry: [],
    loaded: [],
    plugin_pages: Map([]),
    plugin_infos: [],
    plugin_cmds: [],
    commands: [],
    status: Uninitialized,
    log_subscription: None,
  }
}

///|
let main_state : Ref[MainState] = Ref(fresh_main_state())

///|
/// Resets the framework to its pristine state: forgets all registered
/// plugins, declarations, commands, and the configuration context, so that
/// `init` can be called again. BAP has no counterpart (a process is
/// initialized once); this is meant for tests and for embedding.
pub fn reset() -> Unit {
  if main_state.val.log_subscription is Some(id) {
    @main_event.unsubscribe(id)
  }
  main_state.val = fresh_main_state()
  context_reset()
}

///|
/// `register_plugin(name, load)` registers a statically linked plugin.
///
/// This replaces BAP's dynamically loaded plugin bundles: `load` plays the
/// role of the plugin's toplevel and is called during `init` if the plugin
/// is selected. `provides` and `features` are the bundle manifest's tags
/// and constraints: a plugin is loaded only if it provides one of the
/// features `required` by `init` (when specified) and all of its `features`
/// are among the features `init` was called with. `doc` is the manifest
/// description, used when the plugin does not document itself.
///
/// Raises `Invalid` if a plugin with the same name is already registered.
pub fn register_plugin(
  name : String,
  provides? : Array[String] = [],
  features? : Array[String] = [],
  doc? : String = "",
  load : () -> Unit raise,
) -> Unit raise {
  let st = main_state.val
  if st.registry.iter().any(p => p.name == name) {
    raise Invalid("the plugin \{ocaml_quote(name)} is already registered")
  }
  st.registry.push({ name, provides, features, doc, load, })
}

///|
/// The names of all registered plugins, sorted.
pub fn registered_plugins() -> Array[String] {
  let names = main_state.val.registry.map(p => p.name)
  sort_strings(names)
  names
}

///|
/// Namespace for `Bap_main.Extension` functions.
pub(all) struct Extension {}

///|
/// `Extension::register(f)` declares an extension (`Extension.declare`).
///
/// The function is called with the configuration context during `init`,
/// after all parameters are determined, unless its plugin is disabled.
/// If it raises, no other extension is evaluated and `init` raises the
/// same error. The extensions of a plugin run in reverse order of their
/// declaration (as in BAP).
///
/// `provides` and `features` extend the plugin's features and constraints;
/// `doc` is appended to the plugin documentation.
pub fn Extension::register(
  features? : Array[String] = [],
  provides? : Array[String] = [],
  doc? : String = "",
  code : (Ctxt) -> Unit raise,
) -> Unit {
  let slot = main_state.val.slot
  slot.info = Some(
    match slot.info {
      None => { tags: provides, cons: features, docs: doc, }
      Some(info) =>
        {
          tags: [..info.tags, ..provides],
          cons: [..info.cons, ..features],
          docs: info.docs + doc,
        }
    },
  )
  slot.codes.push(code)
}

///|
/// `Extension::documentation(doc)` prepends the markdown `doc` to the
/// documentation of the plugin being loaded.
pub fn Extension::documentation(doc : String) -> Unit {
  let slot = main_state.val.slot
  slot.page = [..markdown_to_manpage(doc), ..slot.page]
}

///|
fn reset_plugin() -> Unit {
  main_state.val.slot = Slot::new()
}

///|
fn merge_sets(xs : Array[String], ys : Array[String]) -> Array[String] {
  sorted_unique([..xs, ..ys])
}

///|
fn update_from_bundle(info : PluginInfo?, p : PluginEntry) -> PluginInfo {
  match info {
    None => { docs: p.doc, tags: p.provides, cons: p.features, }
    Some(info) =>
      {
        docs: if info.docs == "" {
          p.doc
        } else {
          info.docs
        },
        tags: merge_sets(p.provides, info.tags),
        cons: merge_sets(p.features, info.cons),
      }
  }
}

///|
fn is_selected(
  p : PluginEntry,
  requires : Array[String]?,
  features : Array[String],
) -> Bool {
  let has_feature = match requires {
    None => true
    Some(req) => p.provides.iter().any(t => req.contains(t))
  }
  has_feature && p.features.iter().all(c => features.contains(c))
}

///|
/// Attributes the pending declarations to the loaded plugin `p`
/// (`hook_plugin_loads` in BAP).
fn plugin_loaded(
  p : PluginEntry,
  config : Array[(String, String)],
  getenv : (String) -> String?,
) -> Unit raise {
  let st = main_state.val
  let slot = st.slot
  let pctxt = { name: p.name, config, getenv, }
  let spec = []
  for make in slot.specs {
    spec.push(make(pctxt))
  }
  let info = update_from_bundle(slot.info, p)
  let man = if slot.page.is_empty() {
    markdown_to_manpage(info.docs)
  } else {
    slot.page
  }
  st.plugin_pages[p.name] = match st.plugin_pages.get(p.name) {
    None => man
    Some(men) => [..men, ..man]
  }
  st.plugin_infos.push((p.name, info))
  if !slot.actions.is_empty() {
    let actions = slot.actions.copy()
    actions.rev_in_place()
    st.plugin_cmds.push((p.name, actions))
  }
  st.loaded.push({ name: p.name, spec, code: slot.codes.copy(), })
  reset_plugin()
}

///|
/// Loads the selected plugins. Returns the loaded names and the failures.
fn load_plugins(
  features : Array[String],
  requires : Array[String]?,
  config : Array[(String, String)],
  getenv : (String) -> String?,
) -> (Array[String], Array[(String, String)]) raise {
  let st = main_state.val
  let entries = st.registry.copy()
  entries.sort_by((a, b) => lex_compare(a.name, b.name))
  let loaded = []
  let failures = []
  for p in entries {
    if !is_selected(p, requires, features) {
      continue
    }
    try (p.load)() catch {
      e => {
        failures.push((p.name, error_to_string(e)))
        reset_plugin()
      }
    } noraise {
      _ => {
        plugin_loaded(p, config, getenv)
        loaded.push(p.name)
      }
    }
  }
  (loaded, failures)
}
