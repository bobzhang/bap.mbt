// The `api` plugin: a port of upstream `plugins/api/api_main.ml`.
//
// API specifications are files grouped by language in API directories
// (`<dir>/<lang>/<name>`, e.g., `<dir>/c/posix.h`). The `api` pass
// collects the files of every language that has a registered API
// processor (`@c.api_processors`, the C processor is registered by the ABI
// pass of the project's target), parses them with the processor, and maps
// the program with the result, which for C applies the prototypes to the
// subroutines through the target's ABI.
//
// The API directories are, in the order of precedence (a later
// declaration of the same name overrides an earlier one): the system and
// user data directories (`<sysdatadir>/api`, `<datadir>/api`), the
// directories listed in `BAP_API_PATH`, the installation site of the
// bundled APIs, and the directories specified with `--api-path`.
//
// Deviations:
// - The bundled API files (upstream `plugins/api/api/c/*.h`, installed in
//   the `bap-common` `api` site) are embedded in the executable and served
//   from `site_dir()` by an overlay of the `bap_main` file system that is
//   installed while the plugin inspects and parses the API files.
// - The deprecated `--api-add`/`--api-remove` options (which copy/remove
//   API files to/from the API directories) are not ported.
// - Upstream exits the process when the API cannot be applied; here the
//   pass fails.
// - Upstream processors are applied from the most recently registered one;
//   `@c.api_processors` lists them in the registration order, so the list
//   is reversed.

///|
/// The name of the plugin and of its pass.
pub let name : String = "api"

///|
/// The features provided by the plugin.
pub let provides : Array[String] = ["abi", "api", "pass"]

///|
/// A description of an API: its language and name.
pub(all) struct ApiDescr {
  lang : String
  name : String
} derive(Eq, Debug)

///|
pub extend ApiDescr with Eq::{equal, not_equal}

///|
pub extend ApiDescr with Debug::{to_repr}

///|
/// An API: its description and the path to its specification.
pub(all) struct Api {
  desc : ApiDescr
  path : String
} derive(Eq, Debug)

///|
pub extend Api with Eq::{equal, not_equal}

///|
pub extend Api with Debug::{to_repr}

// Paths

///|
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(0) => "/"
    Some(i) => path.unsafe_substring(start=0, end=i)
    None => "."
  }
}

///|
fn basename(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.unsafe_substring(start=i + 1, end=path.length())
    None => path
  }
}

///|
fn concat(dir : String, file : String) -> String {
  if dir == "" {
    file
  } else if dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}

///|
/// Normalizes a path: removes empty and `.` components and resolves `..`
/// against the preceding component (upstream `FilePath.reduce`).
pub fn reduce(path : String) -> String {
  let absolute = path.has_prefix("/")
  let parts : Array[String] = []
  for part in path.split("/") {
    let part = part.to_owned()
    match part {
      "" | "." => ()
      ".." =>
        match parts.last() {
          Some(p) if p != ".." => parts.pop() |> ignore
          _ => if !absolute { parts.push("..") }
        }
      p => parts.push(p)
    }
  }
  let joined = parts.join("/")
  if absolute {
    "/" + joined
  } else if joined == "" {
    "."
  } else {
    joined
  }
}

///|
/// Parses a path: normalizes it and expands the leading `~` to `HOME`.
pub fn path_of_string(
  x : String,
  getenv~ : (String) -> String? = @env.get_env_var,
) -> String {
  let path = reduce(x)
  if path.has_prefix("~") {
    match getenv("HOME") {
      Some(home) =>
        reduce(concat(home, path.unsafe_substring(start=1, end=path.length())))
      None => path
    }
  } else {
    path
  }
}

///|
fn is_dir(path : String) -> Bool {
  (@bap_main.file_system().kind)(path) is Some(Directory)
}

///|
fn is_file(path : String) -> Bool {
  (@bap_main.file_system().kind)(path) is Some(RegularFile)
}

///|
/// The lexicographic order of strings (`String::compare` orders by the
/// length first).
fn lex_compare(a : String, b : String) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let c = a.code_unit_at(i).to_int() - b.code_unit_at(i).to_int()
    if c != 0 {
      return c
    }
  }
  a.length() - b.length()
}

///|
/// All regular files under `path` (recursively), in the lexicographic
/// order of their names within a directory.
fn find_files(path : String) -> Array[String] {
  let out = []
  fn walk(p : String, depth : Int32) {
    if is_file(p) {
      out.push(p)
    } else if depth < 32 && is_dir(p) {
      match (@bap_main.file_system().read_dir)(p) {
        Some(names) => {
          let names = names.copy()
          names.sort_by(lex_compare)
          for n in names {
            walk(concat(p, n), depth + 1)
          }
        }
        None => ()
      }
    }
  }

  walk(path, 0)
  out
}

///|
/// The API specified by the file at `path`: its name is the file name and
/// its language is the name of the parent directory.
pub fn api_of_path(path : String) -> Api? {
  if is_file(path) {
    Some({
      desc: { name: basename(path), lang: basename(dirname(path)), },
      path,
    })
  } else {
    None
  }
}

///|
/// The APIs in the directory `path` (in its `lang` subdirectory if `lang`
/// is specified).
pub fn find_apis(path : String, lang? : String) -> Array[Api] {
  let path = match lang {
    Some(lang) => concat(path, lang)
    None => path
  }
  find_files(path).filter_map(api_of_path)
}

// The bundled APIs

///|
/// The directory from which the bundled APIs are served (the upstream
/// installation site, `<prefix>/share/bap-common/api`).
pub fn site_dir() -> String {
  concat(dirname(@bap_main.Configuration::sysdatadir()), "bap-common/api")
}

///|
/// An in-memory file system with the bundled API files under `site_dir()`.
pub fn bundled_file_system() -> @bap_main.FileSystem {
  let site = site_dir()
  let files = bundled_api_files().map(f => (concat(site, f.0), f.1))
  let dirs = [site]
  for f in files {
    let d = dirname(f.0)
    if !dirs.contains(d) {
      dirs.push(d)
    }
  }
  @bap_main.FileSystem::in_memory(files~, dirs~)
}

///|
/// The file system `top` over `base`: a path is looked up in `top` first;
/// directory listings are merged.
pub fn overlay(
  top : @bap_main.FileSystem,
  base : @bap_main.FileSystem,
) -> @bap_main.FileSystem {
  {
    kind: path => {
      match (top.kind)(path) {
        Some(k) => Some(k)
        None => (base.kind)(path)
      }
    },
    read_file: path => {
      match (top.read_file)(path) {
        Some(b) => Some(b)
        None => (base.read_file)(path)
      }
    },
    read_dir: path => {
      match ((top.read_dir)(path), (base.read_dir)(path)) {
        (None, None) => None
        (Some(xs), None) | (None, Some(xs)) => Some(xs)
        (Some(xs), Some(ys)) => {
          let out = xs.copy()
          for y in ys {
            if !out.contains(y) {
              out.push(y)
            }
          }
          Some(out)
        }
      }
    },
  }
}

///|
/// Runs `f` with the bundled API files visible in the `bap_main` file
/// system.
pub fn[T] with_bundled_files(f : () -> T) -> T {
  let saved = @bap_main.file_system()
  @bap_main.set_file_system(overlay(bundled_file_system(), saved))
  let result = f()
  @bap_main.set_file_system(saved)
  result
}

///|
/// The API directories (upstream `all_paths`): the existing directories
/// among `api_paths`, the bundled site, `BAP_API_PATH`, and the data
/// directories, from the lowest to the highest precedence. Must be called
/// with the bundled files visible (`with_bundled_files`).
pub fn all_paths(
  api_paths : Array[String],
  getenv~ : (String) -> String? = @env.get_env_var,
) -> Array[String] {
  let env_paths = match getenv("BAP_API_PATH") {
    Some(p) =>
      p.split(":").map(s => s.to_owned()).filter(s => s != "").collect()
    None => []
  }
  let paths = api_paths.map(p => path_of_string(p, getenv~)) +
    [site_dir()] +
    env_paths.map(p => path_of_string(p, getenv~)) +
    [
      concat(@bap_main.Configuration::datadir(getenv~), "api"),
      concat(@bap_main.Configuration::sysdatadir(), "api"),
    ]
  let out = []
  for p in paths.rev() {
    if is_dir(p) && !out.contains(p) {
      out.push(p)
    }
  }
  out
}

///|
/// The API files of the language `lang` in the directories `paths`.
pub fn files(paths : Array[String], lang : String) -> Array[String] {
  let out = []
  for p in paths {
    for api in find_apis(p, lang~) {
      out.push(api.path)
    }
  }
  out
}

///|
/// The output of `--api-list-paths`: one directory per line.
pub fn list_paths(paths : Array[String]) -> String {
  paths.map(p => p + "\n").join("")
}

///|
/// The output of `--api-show`: the APIs grouped by language, then their
/// total number.
pub fn show_apis(paths : Array[String]) -> String {
  let apis = []
  for p in paths {
    apis.append(find_apis(p))
  }
  // a stable sort by the language (upstream `List.sort`), then grouping
  let langs : Array[String] = []
  for api in apis {
    if !langs.contains(api.desc.lang) {
      langs.push(api.desc.lang)
    }
  }
  langs.sort_by(lex_compare)
  let out = StringBuilder()
  for lang in langs {
    out.write_string("Language: \{lang}\n")
    for api in apis {
      if api.desc.lang == lang {
        out.write_string("   \{api.desc.name} : \{api.path}\n")
      }
    }
    out.write_string("\n")
  }
  out.write_string("Total number of available API: \{apis.length()}\n")
  out.to_string()
}

///|
/// Applies the APIs found in `paths` to the program of the project
/// (upstream `main`).
pub fn apply(
  paths : Array[String],
  project : @project.Project,
) -> Result[@project.Project, String] {
  with_bundled_files(() => {
    let mappers = []
    for processor in @c.api_processors().rev() {
      let files = files(paths, processor.language)
      match (processor.parse)(file => Some(file), files) {
        Ok(mapper) => mappers.push(mapper)
        Err(e) => return Err("api wasn't applied: \{e}")
      }
    }
    Ok(
      project.map_program(prog => {
        mappers.fold(init=prog, (prog, map) => map(prog))
      }),
    )
  })
}

///|
/// The `api` pass for the given `--api-path` directories: an autorun pass
/// that depends on the `abi` pass (which is registered if it isn't yet).
/// The directories are computed when the pass runs.
pub fn pass(
  api_paths~ : Array[String] = [],
  getenv~ : (String) -> String? = @env.get_env_var,
) -> @project.ProjectPass {
  pass_with(() => (api_paths, getenv))
}

///|
fn pass_with(
  config : () -> (Array[String], (String) -> String?),
) -> @project.ProjectPass {
  @abi.register_project_pass_if_absent() |> ignore
  @project.ProjectPass::create(name~, autorun=true, deps=["abi"], run=project => {
    let (api_paths, getenv) = config()
    let paths = with_bundled_files(() => all_paths(api_paths, getenv~))
    apply(paths, project)
  })
}

///|
/// The configuration of the registered pass (the pass registry outlives a
/// run of the frontend, so the pass reads the latest configuration).
let registered_config : Ref[(Array[String], (String) -> String?)] = Ref(
  ([], @env.get_env_var),
)

///|
/// Registers the `api` pass (and the `abi` pass it depends on) with the
/// given configuration. If the pass is already registered, only its
/// configuration is updated and `false` is returned.
pub fn register(
  api_paths~ : Array[String] = [],
  getenv~ : (String) -> String? = @env.get_env_var,
) -> Result[Bool, String] {
  registered_config.val = (api_paths, getenv)
  @project.register_pass_if_absent(pass_with(() => registered_config.val))
}

///|
/// Normalizes the `--api-path` directories: `.` is the current directory.
fn normalize_paths(paths : Array[String]) -> Array[String] {
  paths.map(p => {
    if p == "." {
      match @env.current_dir() {
        Some(cwd) => cwd
        None => p
      }
    } else {
      p
    }
  })
}

///|
/// Prints complete text (that ends with a newline) to the standard output.
fn print_text(s : String) -> Unit {
  if s.has_suffix("\n") {
    println(s.unsafe_substring(start=0, end=s.length() - 1))
  } else {
    println(s)
  }
}

///|
let doc : String =
  #|inserts subroutines arg terms
  #|
  #|Automatically apply API bundled in the plugin.

///|
/// Declares the `api` plugin with its `--api-path`, `--api-list-paths`,
/// and `--api-show` options. `out` receives the output of the listing
/// options, after which the plugin requests the exit (as upstream exits).
/// Does nothing if already declared.
pub fn declare_plugin(out~ : (String) -> Unit = print_text) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides~, doc~, () => {
    let path = @bap_main.Configuration::parameter(
      doc="Add a list of a paths where to store/search apis",
      @bap_main.Type::list(@bap_main.Type::dir()),
      "path",
    )
    let list_paths_flag = @bap_main.Configuration::flag(
      doc="List of all registered paths",
      "list-paths",
    )
    let show_flag = @bap_main.Configuration::flag(
      doc="Show all registered api",
      "show",
    )
    @bap_main.Extension::register(ctxt => {
      let api_paths = normalize_paths(ctxt.get(path))
      let show_paths = ctxt.get(list_paths_flag)
      let show = ctxt.get(show_flag)
      if show_paths || show {
        let text = with_bundled_files(() => {
          let paths = all_paths(api_paths)
          (if show_paths { list_paths(paths) } else { "" }) +
          (if show { show_apis(paths) } else { "" })
        })
        out(text)
        raise @bap_main.ExitRequested(0)
      }
      match register(api_paths~) {
        Ok(_) => ()
        Err(e) => fail(e)
      }
    })
  })
}
