///|
/// The name of the plugin (and of its rooter and symbolizer sources).
pub let name : String = "patterns"

///|
/// The features provided by the plugin.
pub let provides : Array[String] = ["symbolizer", "rooter", "function-starts"]

///|
/// The directories searched for the patterns by default (upstream:
/// `/usr/share/ghidra` and the `signatures` folders of the data
/// directories), followed by the user-specified paths.
pub fn default_roots(paths~ : ArrayView[String] = []) -> Array[String] {
  [
    "/usr/share/ghidra",
    concat_path(@bap_main.Configuration::datadir(), "signatures"),
    concat_path(@bap_main.Configuration::sysdatadir(), "signatures"),
    ..paths,
  ]
}

///|
let roots : Ref[Array[String]] = { val: [], }

///|
/// Sets the pattern directories used by `register_for_image` (upstream
/// `Repository.enable`).
pub fn enable(paths~ : ArrayView[String] = []) -> Unit {
  roots.val = default_roots(paths~)
}

///|
/// The currently enabled pattern directories.
pub fn enabled_roots() -> Array[String] {
  roots.val.copy()
}

///|
/// Loads the patterns for the target of the image from the enabled
/// directories, analyzes the image, and registers the outcome as the
/// `patterns` rooter and symbolizer sources for the unit at `path`.
pub fn register_for_image(
  image : @image.Image,
  path? : String,
  target? : @core_theory.Target,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Outcome {
  let target = match target {
    Some(t) => t
    None => image.target().unwrap_or(image.arch())
  }
  let rules = load(roots.val, target, fs~)
  let outcome = analyze_image(image, rules)
  @project.register_rooter_source_value(name~, outcome.rooter(path?))
  @project.register_symbolizer_source_value(name~, outcome.symbolizer(path?))
  outcome
}

///|
/// Lines `matching <addr> -> <action>` for every match of the rules in
/// the memory (upstream `print_matches`).
pub fn matches(rules : Rules, mem : @memory.Memory) -> Array[String] {
  rules.search(
    mem,
    (addr, action, out : Array[String]) => {
      out.push("matching 0x\{addr.to_string(radix=16)} -> \{action}")
      out
    },
    [],
  )
}

///|
/// Runs the patterns of the file `spec` on the segments of the binary
/// (the `match-patterns` command, upstream `test_on_file`), writing the
/// report to `out`.
pub fn match_patterns(
  spec~ : String,
  binary~ : String,
  out~ : (String) -> Unit,
  fs~ : @bap_main.FileSystem = @bap_main.FileSystem::native(),
) -> Unit {
  let text = match (fs.read_file)(spec) {
    Some(bytes) => @utf8.decode_lossy(bytes)
    None => {
      log.warning(message="Failed to read the spec: \{spec}")
      return
    }
  }
  let rules = match parse_patterns(text) {
    Err(err) => {
      log.warning(message="Failed to parse the spec: \{err}")
      return
    }
    Ok(rules) => Rules::create(rules)
  }
  log.warning(message="Applying rules\n\{rules.to_string()}")
  match @image.Image::of_file(binary) {
    Err(err) => log.warning(message="Failed to open the binary: \{err}")
    Ok((img, _)) =>
      for seg in img.segments() {
        let mem = img.memory_of_segment(seg)
        out("Analyzing segment \{seg.name()}:\n\{mem.to_string()}")
        for line in matches(rules, mem) {
          out(line)
        }
      }
  }
}

///|
let doc : String =
  #|Applies semantic actions to the matching byte patterns. The patterns
  #|are specified in an XML format (derived from the Ghidra bytesearch
  #|patterns, so that the patterns provided by Ghidra could be used as is)
  #|and the actions are implemented with Primus Lisp methods of the
  #|bap:patterns-action signal. Used to identify function starts,
  #|instruction encodings, function names, etc. The patternconstraints.xml
  #|files map targets (BAP target names or Ghidra language specifications
  #|arch:endianness:bits:variant) to the files with patterns. Each pattern
  #|is a ditted sequence of bits (0, 1, .) or nibbles (0x followed by
  #|hexadecimal digits or .). The funcstart and possiblefuncstart actions
  #|mark the matching sequence as a function start.

///|
/// Declares the `patterns` plugin to `bap_main` with its `path` parameter
/// and the `match-patterns` command. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides~, doc~, () => {
    let paths = @bap_main.Configuration::parameters(
      doc="Add the specified path to the list of patterns directories.",
      @bap_main.Type::dir(),
      "path",
    )
    let spec = @bap_main.Command::parameter(
      doc="The patterns file.",
      aliases=["s"],
      @bap_main.Type::file(),
      "specification",
    )
    let binary = @bap_main.Command::argument(@bap_main.Type::file())
    @bap_main.Command::register(
      "match-patterns",
      @bap_main.Command::args().add(spec).add(binary),
      doc="Run the specified patterns file on the input file and prints the matches",
      spec => binary => _ => match_patterns(spec~, binary~, out=s => println(s)),
    )
    @bap_main.Extension::register(provides~, ctxt => {
      enable(paths=ctxt.get(paths))
    })
  })
}
