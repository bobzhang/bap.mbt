// Project creation, passes, and outputs (upstream `create_and_process`,
// `process`, `run_passes`, and the `Dump_formats` module).

///|
/// Where a dump goes.
pub(all) enum Destination {
  Stdout
  File(String)
} derive(Eq, Debug)

///|
/// A parsed `--dump` specification: the destination, the format name,
/// and the optional format version (`<FMT>[-<VER>][:<FILE>]`).
pub(all) struct Output {
  dst : Destination
  fmt : String
  ver : String?
} derive(Eq, Debug)

///|
fn parse_fmt(fmt : String) -> (String, String?) {
  let parts = fmt.split("-").map(s => s.to_owned()).collect()
  match parts {
    [fmt, ver] => (fmt, Some(ver))
    _ => (fmt, None)
  }
}

///|
/// Parses a `--dump` value (upstream `Dump_formats.split`).
pub fn Output::split(str : String) -> Output {
  let parts = str.split(":").map(s => s.to_owned()).collect()
  match parts {
    [fmt, dst] => {
      let (fmt, ver) = parse_fmt(fmt)
      { dst: File(dst), fmt, ver, }
    }
    _ => {
      let (fmt, ver) = parse_fmt(str)
      { dst: Stdout, fmt, ver, }
    }
  }
}

///|
/// Parses and validates a `--dump` value against the registered project
/// writers (upstream `Dump_formats.parse_format`).
pub fn Output::parse(str : String) -> Output raise DisassembleError {
  let r = Output::split(str)
  match @print.find_writer(r.fmt) {
    None => raise Fail(UnknownFormat(r.fmt))
    Some(w) =>
      match r.ver {
        Some(ver) if ver != w.version() =>
          raise Fail(UnavailableFormatVersion(r.fmt))
        _ => r
      }
  }
}

///|
/// Checks that `update` is only used with a knowledge base
/// (upstream `validate_knowledge`).
pub fn validate_knowledge(
  update : Bool,
  kb : String?,
) -> Unit raise DisassembleError {
  match kb {
    None => if update { raise Fail(NoKnowledge) }
    Some(path) => if !(file_exists(path) || update) { raise Fail(NoKnowledge) }
  }
}

///|
fn file_exists(path : String) -> Bool {
  (@bap_main.file_system().kind)(path) is Some(_)
}

///|
/// Checks that the input exists (upstream `validate_input`).
pub fn validate_input(file : String) -> Unit raise DisassembleError {
  if !file_exists(file) {
    raise Fail(ExpectsARegularFile(file))
  }
}

///|
/// Old-style passes (`--<pass>`) and new-style passes (`--passes`) can
/// not be mixed (upstream `validate_passes_style`).
pub fn validate_passes_style(
  old_style : Array[String],
  new_style : Array[String],
) -> Array[String] raise DisassembleError {
  match (old_style, new_style) {
    (xs, []) | ([], xs) => xs
    _ => raise Fail(OldAndNewStylePasses)
  }
}

///|
/// Resolves pass names to the registered passes (upstream
/// `validate_passes`).
pub fn validate_passes(
  names : Array[String],
) -> Array[@project.ProjectPass] raise DisassembleError {
  names.map(name => {
    match @project.find_pass(name) {
      Some(p) => p
      None => raise Fail(UnknownPass(name))
    }
  })
}

///|
fn pass_failure(err : @project.ProjectPassRunError) -> Failure {
  match err {
    ProjectPassUnsatDep(p, dep) => PassUnsatDep(p.name(), dep)
    ProjectPassRuntimeError(p, reason) => PassRuntimeError(p.name(), reason)
  }
}

///|
/// Runs `passes` in order (upstream `run_passes`); each pass pulls its
/// dependencies in first.
fn run_passes(
  project : @project.Project,
  passes : Array[@project.ProjectPass],
) -> @project.Project raise DisassembleError {
  let mut proj = project
  for pass in passes {
    match pass.run(proj) {
      Ok(next) => proj = next
      Err(err) => raise Fail(pass_failure(err))
    }
  }
  proj
}

///|
/// Runs the autorun passes followed by `passes` and dumps the result in
/// the requested formats (upstream `process`).
pub fn process(
  passes : Array[@project.ProjectPass],
  outputs : Array[Output],
  project : @project.Project,
  out~ : (String) -> Unit,
  write_file~ : (String, String) -> Result[Unit, String],
) -> @project.Project raise DisassembleError {
  let autoruns = @project.passes().filter(p => p.autorun())
  let proj = run_passes(project, autoruns)
  let proj = run_passes(proj, passes)
  for output in outputs {
    let text = match @print.write(output.fmt, proj) {
      Ok(text) => text
      Err(_) => raise Fail(UnknownFormat(output.fmt))
    }
    match output.dst {
      Stdout => out(text)
      File(path) =>
        match write_file(path, text) {
          Ok(_) => ()
          Err(reason) => raise Fail(ProjectFailure(reason))
        }
    }
  }
  proj
}

///|
/// The default file writer (the host file system).
pub fn default_write_file(path : String, text : String) -> Result[Unit, String] {
  @native_io.write_file(path, @utf8.encode(text))
}

///|
fn is_explicit_path(path : String) -> Bool {
  path.has_prefix("/") || path.has_prefix("./") || path.has_prefix("../")
}

///|
/// Loads the input file (upstream `Project.Input.load`).
///
/// The default loader `llvm` of upstream BAP is not available; it selects
/// the port's loaders by the file name and contents instead.
pub fn load_input(
  input : String,
  loader~ : String,
  libraries~ : Array[String],
  target~ : @core_theory.Target,
) -> @project.ProjectInput raise DisassembleError {
  let target = if target.is_unknown() { None } else { Some(target) }
  let explicit_loader = loader != "llvm" && !is_explicit_path(loader)
  if !libraries.is_empty() {
    match
      @project.ProjectInput::file(
        filename=input,
        loader?=if explicit_loader { Some(loader) } else { None },
        libraries~,
        target?,
      ) {
      Ok(r) => return r
      Err(reason) => raise Fail(ProjectFailure(reason))
    }
  }
  let data = match (@bap_main.file_system().read_file)(input) {
    Some(data) => data
    None => raise Fail(ExpectsARegularFile(input))
  }
  let result = if explicit_loader {
    match @project.ProjectInput::load(data, loader~, target?) {
      Ok(input) => Ok(input)
      Err(e) => Err(e)
    }
  } else {
    match
      @project.ProjectInput::load_for_filename(data, filename=input, target?) {
      Ok(r) => Ok(r)
      Err(e) =>
        // no extension (or an unknown one): try the loaders in order
        match @project.ProjectInput::load(data, loader="elf", target?) {
          Ok(r) => Ok(r)
          Err(_) => Err(e)
        }
    }
  }
  match result {
    Ok(r) => r
    Err(reason) => raise Fail(ProjectFailure(reason))
  }
}

///|
/// The options that select the disassembly components (the port's
/// counterparts of the disassembler, rooter, symbolizer, brancher, and
/// reconstructor services of upstream BAP, which are provided there by the
/// plugins that implement them).
///
/// The rooters, symbolizers, and branchers are the names of the registered
/// sources (`@project.register_rooter_source`, ...); when not specified,
/// all registered sources (and root providers) are used, as upstream BAP
/// combines all providers of the knowledge base.
pub(all) struct Components {
  disassembler : String?
  rooters : Array[String]?
  symbolizers : Array[String]?
  branchers : Array[String]?
  reconstructor : String?
} derive(Eq, Debug)

///|
pub fn Components::default() -> Components {
  {
    disassembler: None,
    rooters: None,
    symbolizers: None,
    branchers: None,
    reconstructor: None,
  }
}

///|
/// The name of the recursive-descent disassembly driver.
pub let recursive_driver : String = "recursive"

///|
/// Registers the `recursive` disassembly driver: the recursive descent
/// disassembler (upstream `Disasm.Driver`) that decodes the project memory
/// with the Basic decoder and splits it into basic blocks connected with
/// the control-flow edges.
pub fn register_recursive_driver() -> Unit {
  let driver = @project.ProjectDisassemblyDriver::create(
    name=recursive_driver,
    description="recursive descent disassembly with the Basic decoder",
    priority=-98,
    run=project => {
      match project.disassemble_rec(driver="basic") {
        Ok(rec) => Ok(rec.project().set("disassembler", recursive_driver))
        Err(reason) => Err(reason)
      }
    },
  )
  @project.register_disassembly_driver_if_absent(driver) |> ignore
}

///|
/// A function that computes the roots (function starts) of the loaded
/// input, e.g., with the byteweight algorithm.
pub type RootProvider = (@project.ProjectInput) -> Result[Array[UInt64], String]

///|
let root_providers : Array[(String, RootProvider)] = []

///|
/// Registers (or replaces) a root provider. The roots of all providers are
/// added to the rooters of the project unless the rooters are selected
/// explicitly.
pub fn register_root_provider(name : String, provider : RootProvider) -> Unit {
  match root_providers.search_by(p => p.0 == name) {
    Some(i) => root_providers[i] = (name, provider)
    None => root_providers.push((name, provider))
  }
}

///|
/// Removes the root provider.
pub fn remove_root_provider(name : String) -> Unit {
  match root_providers.search_by(p => p.0 == name) {
    Some(i) => root_providers.remove(i) |> ignore
    None => ()
  }
}

///|
/// Combines the named sources (all registered ones when `names` is
/// `None`); unknown names are errors.
fn[T] combine(
  kind : String,
  names : Array[String]?,
  all : () -> Array[String],
  find : (String) -> @project.ProjectDisassemblySource[T]?,
  extra? : Array[Result[T, String]] = [],
) -> @project.ProjectDisassemblySource[T]? raise DisassembleError {
  let names = match names {
    Some(names) => names
    None => all()
  }
  let items = []
  for name in names {
    match find(name) {
      Some(source) => items.append(source.items())
      None => raise Fail(ProjectFailure("unknown \{kind} \{name}"))
    }
  }
  items.append(extra)
  if items.is_empty() {
    None
  } else {
    Some(@project.ProjectDisassemblySource::create(items))
  }
}

///|
/// Creates the project from the loaded input with the selected
/// components. Without an explicit `disassembler`, the `recursive` driver
/// (the recursive descent over the port's Basic decoder) is used, falling
/// back to the other available drivers.
pub fn create_project(
  input : @project.ProjectInput,
  components~ : Components,
  pkg~ : String,
) -> @project.Project raise DisassembleError {
  register_recursive_driver()
  let provided = if components.rooters is None {
    root_providers.map(p => {
      match (p.1)(input) {
        Ok(roots) => Ok(@project.ProjectRooter::create(roots))
        Err(reason) => Err(reason)
      }
    })
  } else {
    []
  }
  let rooter = combine(
    "rooter",
    components.rooters,
    @project.rooter_source_names,
    @project.find_rooter_source,
    extra=provided,
  )
  let symbolizer = combine(
    "symbolizer",
    components.symbolizers,
    @project.symbolizer_source_names,
    @project.find_symbolizer_source,
  )
  let brancher = combine(
    "brancher",
    components.branchers,
    @project.brancher_source_names,
    @project.find_brancher_source,
  )
  let reconstructor = match components.reconstructor {
    None => None
    Some(name) =>
      match @project.find_reconstructor_source(name) {
        Some(source) => Some(source)
        None =>
          match @project.find_reconstructor(name) {
            Some(r) => Some(@project.ProjectDisassemblySource::single(r))
            None =>
              raise Fail(
                ProjectFailure("unknown project reconstructor \{name}"),
              )
          }
      }
  }
  let create = (disassembler : String?) => {
    @project.Project::create_from_input(
      input,
      disassembler?,
      rooter?,
      symbolizer?,
      brancher?,
      reconstructor?,
      pkg~,
    )
  }
  let result = match components.disassembler {
    Some(d) => create(Some(d))
    None =>
      match create(Some(recursive_driver)) {
        Ok(p) => Ok(p)
        // the Basic decoder may not support the target
        Err(_) => create(None)
      }
  }
  match result {
    Ok(p) => p
    Err(reason) => raise Fail(ProjectFailure(reason))
  }
}

///|
/// Loads the knowledge base (the persisted project) from `path`, if
/// enabled and the file exists (upstream `load_knowledge`).
fn load_knowledge(disable : Bool, kb : String?) -> @project.Project? {
  if disable {
    return None
  }
  match kb {
    None => None
    Some(path) =>
      match (@bap_main.file_system().read_file)(path) {
        None => None
        Some(bytes) => {
          let text = @utf8.decode_lossy(bytes)
          match @project.Project::persistent().decode(text) {
            Ok(p) => Some(p)
            Err(_) => None
          }
        }
      }
  }
}

///|
/// The project storage key of the path of the unit in the knowledge base.
pub let unit_path_key : String = "bap:unit-path"

///|
/// Stores the project in the knowledge base (upstream `save_knowledge`).
fn save_knowledge(
  update : Bool,
  kb : String?,
  project : @project.Project,
  write_file : (String, String) -> Result[Unit, String],
) -> Unit raise DisassembleError {
  match kb {
    Some(path) if update => {
      let text = @project.Project::persistent().encode(project)
      match write_file(path, text) {
        Ok(_) => ()
        Err(reason) => raise Fail(ProjectFailure(reason))
      }
    }
    _ => ()
  }
}

///|
/// Loads the input, builds the project, runs the passes, dumps the outputs,
/// and updates the knowledge base (upstream `create_and_process`).
pub fn create_and_process(
  input : String,
  libraries? : Array[String] = [],
  outputs? : Array[Output] = [],
  passes? : Array[@project.ProjectPass] = [],
  loader? : String = "llvm",
  target? : @core_theory.Target = @core_theory.Target::unknown(),
  components? : Components = Components::default(),
  update? : Bool = false,
  knowledge? : String? = None,
  print_missing? : Bool = false,
  out~ : (String) -> Unit,
  write_file? : (String, String) -> Result[Unit, String] = default_write_file,
) -> @project.Project raise DisassembleError {
  let proj = match load_knowledge(print_missing, knowledge) {
    Some(proj) => proj
    None => {
      let loaded = load_input(input, loader~, libraries~, target~)
      create_project(loaded, components~, pkg=input).set(unit_path_key, input)
    }
  }
  let proj = process(passes, outputs, proj, out~, write_file~)
  if print_missing {
    out(missing_report(proj))
  }
  save_knowledge(update, knowledge, proj, write_file)
  proj
}
