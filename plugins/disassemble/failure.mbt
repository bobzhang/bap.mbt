// The failures of the `disassemble` and `compare` commands (upstream
// `Disassemble_main.failure` and `string_of_failure`).

///|
/// A reason why the `disassemble` (or `compare`) command failed.
pub(all) enum Failure {
  /// The input file (or a library) does not exist.
  ExpectsARegularFile(String)
  /// Passes are given both as `--<pass>` flags and `--passes`.
  OldAndNewStylePasses
  /// There is no pass with the given name.
  UnknownPass(String)
  /// Two command-line options can not be used together.
  IncompatibleOptions(String, String)
  /// The project could not be built.
  ProjectFailure(String)
  /// A pass has an unsatisfied dependency (pass, dependency).
  PassUnsatDep(String, String)
  /// A pass failed at runtime (pass, reason).
  PassRuntimeError(String, String)
  /// The output format is not known.
  UnknownFormat(String)
  /// The output format exists but not with the requested version.
  UnavailableFormatVersion(String)
  /// There is no collator with the given name.
  UnknownCollator(String)
  /// There is no analysis with the given name.
  UnknownAnalysis(String)
  /// `--update` requires the path to a knowledge base.
  NoKnowledge
} derive(Eq, Debug)

///|
/// The error raised by the commands of the plugin (`Fail` in upstream).
pub(all) suberror DisassembleError {
  Fail(Failure)
} derive(Debug)

///|
/// Suggestions for a mistyped pass name (upstream `pp_guesses`).
fn guesses(badname : String) -> String {
  let guess = StringBuilder()
  for c in badname {
    guess.write_char(if c == '_' { '-' } else { c.to_ascii_lowercase() })
  }
  let guess = guess.to_string()
  let suffix = "-" + plugin_name
  let found = []
  for p in @project.passes() {
    let name = p.name()
    if name == guess || name.has_suffix(suffix) {
      found.push(name)
    }
  }
  if found.is_empty() {
    "make sure that your plugin is installed"
  } else {
    "did you mean \{found.join(", or")}?"
  }
}

///|
/// The human-readable description of a failure.
pub fn Failure::to_string(self : Failure) -> String {
  match self {
    ExpectsARegularFile(name) => "Unable to open file `\{name}'."
    OldAndNewStylePasses =>
      "Bad invocation: passes are specified in both old an new style, please switch to the new style, e.g., `-p<p1>,<p2>,<p3>'"
    UnknownPass(name) =>
      "Bad invocation: failed to find the pass named \{quote(name)}, \{guesses(name)}"
    IncompatibleOptions(o1, o2) =>
      "Bad invocation: the options `\{o1}' and `\{o2}' can not be used together"
    ProjectFailure(err) => "Failed to build the project: \{err}"
    PassUnsatDep(p, s) =>
      "Can't run passes - the dependency \{quote(s)} of pass \{quote(p)} is not available."
    PassRuntimeError(p, reason) =>
      "The pass \{quote(p)} failed with:\n\{reason}"
    UnknownFormat(fmt) => "The format \{quote(fmt)} is not known."
    UnavailableFormatVersion(fmt) =>
      "The selected version of the format \{quote(fmt)} is not supported."
    UnknownCollator("") => "Please specify the collator that you want to use."
    UnknownCollator(s) => "The collator `\{s}' is not registered."
    UnknownAnalysis(s) => "There is no analysis with the name `\{s}'"
    NoKnowledge =>
      "Expected the path to an existing knowledge base (either add or remove the --update option)"
  }
}

///|
/// OCaml's `%S`: a double-quoted string with escapes.
fn quote(s : String) -> String {
  let sb = StringBuilder()
  sb.write_char('"')
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
let printer_registered : Ref[Bool] = Ref(false)

///|
/// Registers the printer of `DisassembleError` in `bap_main` (once).
fn register_error_printer() -> Unit {
  if printer_registered.val {
    return
  }
  printer_registered.val = true
  @bap_main.register_error_printer(err => {
    match err {
      Fail(failure) => Some(failure.to_string())
      _ => None
    }
  })
}
