// Port of the `Context` module of `bap_main.ml`: the immutable evaluation
// context (`ctxt`) that captures the values of all configuration
// parameters and the set of enabled plugins with their features.

///|
priv struct CtxtValue {
  scope : String
  value : String
  digest : String
}

///|
/// The evaluation context (`Bap_main.ctxt`, `Extension.Configuration.t`).
///
/// It maps every configuration parameter (`<plugin>-<name>`) of the enabled
/// plugins to its textual value and digest, and records the features
/// provided by each enabled plugin.
pub struct Ctxt {
  priv env : Map[String, CtxtValue]
  priv plugins : Map[String, Array[String]]
}

///|
priv struct PluginInfo {
  cons : Array[String]
  tags : Array[String]
  docs : String
}

///|
/// A piece of information about a plugin or a command
/// (`Extension.Configuration.info`).
pub struct Info {
  priv name : String
  priv doc : String
}

///|
/// The name of the plugin or command.
pub fn Info::name(self : Info) -> String {
  self.name
}

///|
/// The short (one sentence, uncapitalized) description.
pub fn Info::doc(self : Info) -> String {
  short_description(first_sentence_of_man(markdown_to_manpage(self.doc)))
}

///|
priv enum Builder {
  Building(Ctxt)
  Sealed
}

///|
priv struct ContextState {
  mut builder : Builder
  ready : @future.Future[Ctxt]
  seal : @future.Promise[Ctxt]
  plugin_descriptions : Map[String, PluginInfo]
  command_descriptions : Map[String, Array[(String, String)]]
}

///|
fn empty_ctxt() -> Ctxt {
  { env: Map([]), plugins: Map([]), }
}

///|
fn fresh_context_state() -> ContextState {
  let (ready, seal) = @future.Future::create()
  {
    builder: Building(empty_ctxt()),
    ready,
    seal,
    plugin_descriptions: Map([]),
    command_descriptions: Map([]),
  }
}

///|
let context_state : Ref[ContextState] = Ref(fresh_context_state())

///|
fn context_reset() -> Unit {
  context_state.val = fresh_context_state()
}

///|
fn context_update(f : (Ctxt) -> Ctxt raise) -> Unit raise {
  match context_state.val.builder {
    Building(ctxt) => context_state.val.builder = Building(f(ctxt))
    Sealed => raise AlreadyDefined
  }
}

///|
fn context_set(
  scope~ : String,
  key~ : String,
  value~ : String,
  digest~ : String,
) -> Unit raise {
  context_update(ctxt => {
    if ctxt.env.contains(key) {
      raise Invalid("the parameter \{ocaml_quote(key)} is defined twice")
    }
    let env = ctxt.env.copy()
    env[key] = { scope, value, digest, }
    { ..ctxt, env, }
  })
}

///|
fn sorted_unique(xs : Array[String]) -> Array[String] {
  let out = xs.copy()
  sort_strings(out)
  out.dedup()
  out
}

///|
fn[V] sorted_keys(m : Map[String, V]) -> Array[String] {
  let keys = m.keys().collect()
  sort_strings(keys)
  keys
}

///|
fn context_set_plugins(
  disabled : Array[String],
  plugins : Array[(String, PluginInfo)],
  commands : Array[(String, Array[(String, String)])],
) -> Unit raise {
  let st = context_state.val
  for p in plugins {
    if !disabled.contains(p.0) {
      st.plugin_descriptions[p.0] = p.1
    }
  }
  for c in commands {
    if !disabled.contains(c.0) {
      st.command_descriptions[c.0] = c.1
    }
  }
  context_update(ctxt => {
    let env : Map[String, CtxtValue] = Map([])
    for k, v in ctxt.env {
      if !disabled.contains(v.scope) {
        env[k] = v
      }
    }
    let enabled : Map[String, Array[String]] = Map([])
    for p in plugins {
      if !disabled.contains(p.0) {
        enabled[p.0] = sorted_unique(p.1.tags)
      }
    }
    { env, plugins: enabled, }
  })
}

///|
/// Seals the context and returns it (idempotent).
fn context_request() -> Ctxt {
  let st = context_state.val
  if st.seal.is_fulfilled() {
    st.ready.peek().unwrap()
  } else {
    match st.builder {
      Sealed => panic()
      Building(ctxt) => {
        st.builder = Sealed
        st.seal.try_fulfill(ctxt) |> ignore
        ctxt
      }
    }
  }
}

///|
fn make_filter(
  features : Array[String]?,
  exclude : Array[String]?,
) -> (Array[String]) -> Bool {
  let intersects = (xs : Array[String], tags : Array[String]) => {
    tags.iter().any(t => xs.contains(t))
  }
  tags => {
    let selected = match features {
      None => true
      Some(xs) => intersects(xs, tags)
    }
    let filtered = match exclude {
      None => false
      Some(xs) => intersects(xs, tags)
    }
    selected && !filtered
  }
}

///|
/// `ctxt.get(p)` is the value of the configuration parameter `p`
/// (`Configuration.get`, or `ctxt --> p` with `Extension.Syntax`).
///
/// As in BAP, the context argument is not consulted: parameters are
/// determined once the context is sealed. Aborts if the parameter is not
/// yet determined (i.e., when called before the framework is initialized).
pub fn[A] Ctxt::get(self : Ctxt, p : Parameter[A]) -> A {
  ignore(self)
  match p.value.peek() {
    Some((_, v)) => v
    None => abort("Bap_main: the configuration parameter is not determined")
  }
}

///|
/// `ctxt.refine(provides?, exclude?)` restricts the context to the plugins
/// that provide at least one of `provides` (all plugins if not specified)
/// and none of `exclude`, dropping the parameters of the other plugins.
pub fn Ctxt::refine(
  self : Ctxt,
  provides? : Array[String],
  exclude? : Array[String],
) -> Ctxt {
  let is_selected = make_filter(provides, exclude)
  let plugins : Map[String, Array[String]] = Map([])
  for k, tags in self.plugins {
    if is_selected(tags) {
      plugins[k] = tags
    }
  }
  let env : Map[String, CtxtValue] = Map([])
  for k, v in self.env {
    if plugins.contains(v.scope) {
      env[k] = v
    }
  }
  { plugins, env, }
}

///|
/// The enabled plugins of the context, in alphabetical order.
pub fn Ctxt::plugins(self : Ctxt) -> Array[Info] {
  let descrs = context_state.val.plugin_descriptions
  sorted_keys(self.plugins).map(p => {
    let doc = match descrs.get(p) {
      None => "no description provided"
      Some(info) => info.docs
    }
    { name: p, doc, }
  })
}

///|
/// The commands declared by the enabled plugins of the context.
pub fn Ctxt::commands(self : Ctxt) -> Array[Info] {
  let out = []
  for plugin, cmds in context_state.val.command_descriptions {
    if self.plugins.contains(plugin) {
      for c in cmds {
        out.push({ name: c.0, doc: c.1, })
      }
    }
  }
  out
}

///|
/// All features provided by the enabled plugins, sorted.
pub fn Ctxt::features(self : Ctxt) -> Array[String] {
  let all = []
  for _, tags in self.plugins {
    all.append(tags)
  }
  sorted_unique(all)
}

///|
/// The hexadecimal MD5 digest of the context: the names of its plugins and
/// the digests of all of its parameters.
pub fn Ctxt::digest(self : Ctxt) -> String {
  let sb = StringBuilder()
  for p in sorted_keys(self.plugins) {
    sb.write_string(p)
  }
  for k in sorted_keys(self.env) {
    sb.write_string("\{k} = \{self.env[k].digest}\n")
  }
  md5_string(sb.to_string())
}

///|
/// The `<plugin>-<name> = <value>` lines of the context.
pub fn Ctxt::to_string(self : Ctxt) -> String {
  let sb = StringBuilder()
  for k in sorted_keys(self.env) {
    sb.write_string("\{k} = \{self.env[k].value}\n")
  }
  sb.to_string()
}

///|
pub impl Show for Ctxt with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend Ctxt with Show::{output}
