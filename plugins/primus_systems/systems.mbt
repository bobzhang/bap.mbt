///|
/// # Primus systems (upstream `plugins/primus_systems`)
///
/// Loads Primus systems and registers them in the system repository of
/// `@primus` (`System::register`). The systems are searched in
///
/// - the current working directory;
/// - the directories specified by `--primus-systems-add-path`;
/// - `$datadir/primus/systems` and `$sysdatadir/primus/systems`;
///
/// and every file with the `.asd` extension is loaded (a file may define
/// several systems; references to other systems and components are
/// resolved when a system is run). The systems of the plugin itself
/// (`core_systems`, upstream `core.asd`) are embedded and registered first.
///
/// The plugin also provides the introspection commands `primus-systems`,
/// `primus-components` and `primus-observations`, which list the known
/// systems, components and observations (with details when a single name
/// is given).

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-systems",
)

///|
/// Registers the systems of the description, reporting (and skipping)
/// the ones that are already registered. Returns the registered systems.
fn register_all(systems : Array[@primus.System]) -> Array[@primus.System] {
  let out = []
  for sys in systems {
    @primus.System::register(sys) catch {
      e => {
        log.warning(message=@primus.exn_to_string(e))
        continue
      }
    }
    out.push(sys)
  }
  out
}

///|
/// Registers the systems shipped with the plugin (`core_systems`).
/// Idempotent: returns the systems registered by this call.
pub fn load_core_systems() -> Array[@primus.System] raise @primus.SystemError {
  let systems = @primus.System::from_string(core_systems)
  systems.filter(s => @primus.System::find(s.name()) is None) |> register_all
}

///|
/// Loads and registers all systems defined in the `.asd` files of the
/// directory (upstream `Extension.declare` body for one path). Files that
/// fail to parse are reported and skipped. Returns the loaded systems.
pub fn load_directory(path : String) -> Array[@primus.System] {
  let fs = @bap_main.file_system()
  guard (fs.kind)(path) is Some(Directory) else { return [] }
  guard (fs.read_dir)(path) is Some(files) else { return [] }
  let files = files.copy()
  files.sort()
  let out = []
  for file in files {
    if !file.has_suffix(".asd") {
      continue
    }
    let full = if path.has_suffix("/") {
      path + file
    } else {
      "\{path}/\{file}"
    }
    guard (fs.read_file)(full) is Some(bytes) else { continue }
    let systems = try {
      let text = @utf8.decode(bytes)
      @primus.System::from_string(text)
    } catch {
      e => {
        log.error(
          message="Failed to parse system \{file}: \{@primus.exn_to_string(e)}",
        )
        continue
      }
    }
    out.append(register_all(systems))
  }
  out
}

///|
fn systems_dir(root : String) -> String {
  "\{root}/primus/systems"
}

///|
/// The directories searched for systems, in order.
pub fn search_paths(user~ : Array[String] = []) -> Array[String] {
  [
    ".",
    ..user,
    systems_dir(@bap_main.Configuration::datadir()),
    systems_dir(@bap_main.Configuration::sysdatadir()),
  ]
}

///|
/// Loads the core systems and all systems found in the search paths.
pub fn load_systems(user~ : Array[String] = []) -> Array[@primus.System] {
  let out = load_core_systems() catch {
    e => {
      log.error(
        message="Failed to parse the core systems: \{@primus.exn_to_string(e)}",
      )
      []
    }
  }
  for path in search_paths(user~) {
    out.append(load_directory(path))
  }
  out
}

///|
/// Renders the list of the information entries as upstream
/// `make_info_command`: all entries when `names` is empty, otherwise only
/// the named ones, with the long description when a single name is given.
pub fn info_listing(
  infos : Array[@primus.Info],
  names : Array[String],
) -> String {
  let detailed = names.length() == 1
  let names = names.map(n => @knowledge.Name::read(n))
  let buf = StringBuilder()
  for info in infos {
    if names.is_empty() || names.contains(info.name()) {
      buf.write_string(info.to_string())
      buf.write_string("\n")
      if detailed {
        buf.write_string(info.long())
        buf.write_string("\n")
      }
    }
  }
  buf.to_string()
}

///|
fn command_doc(what : String) -> String {
  "Prints a list of Primus \{what}s. If an argument is specified, then prints the detailed information about the \{what} with that name. If several arguments are specified then prints information (not detailed) about only those \{what}s that have the specified names"
}

///|
fn make_info_command(
  list : () -> Array[@primus.Info],
  what : String,
) -> Unit raise {
  let names = @bap_main.Command::argument(@bap_main.Type::string().list())
  @bap_main.Command::register(
    "primus-\{what}s",
    @bap_main.Command::args().add(names),
    doc=command_doc(what),
    names => _ => println(info_listing(list(), names)),
  )
}

///|
/// The name of the plugin.
pub let name : String = "primus-systems"

///|
/// Declares the `primus-systems` plugin to `bap_main` with its `add-path`
/// parameter and the introspection commands. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "primus-systems"],
    doc="Loads Primus systems and registers them in the system repository.",
    () => {
      let paths = @bap_main.Configuration::parameters(
        @bap_main.Type::dir().list(),
        "add-path",
        doc="adds the path to the list of paths where Primus systems are searched",
      )
      @bap_main.Extension::register(ctxt => {
        let user = []
        for ps in ctxt.get(paths) {
          user.append(ps)
        }
        load_systems(user~) |> ignore
      })
      make_info_command(@primus.System::list, "system")
      make_info_command(@primus.Components::list, "component")
      make_info_command(@primus.Observation::list, "observation")
    },
  )
}
