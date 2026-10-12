// Port of `Bap_main.Extension.Error`.
//
// OCaml's `error = ..` is an extensible variant; in MoonBit every
// `suberror` is already a member of the open `Error` type, so extensions
// and `init` use plain `Error` and the framework-specific conditions are
// collected in `MainError`.

///|
/// Error conditions raised by the BAP main framework.
///
/// Note that, as in BAP, not every condition is a failure: `ExitRequested(0)`
/// is raised when the user asked for a plugin manual page.
pub(all) suberror MainError {
  /// Failed to process command-line options or configuration parameters.
  Configuration
  /// An invalid parameter value or an invalid declaration.
  Invalid(String)
  /// An internal error with its backtrace.
  Bug(Error, String)
  /// `init` was called after a successful initialization.
  AlreadyInitialized
  /// `init` was called after a failed initialization.
  AlreadyFailed(Error)
  /// `init` was called during the initialization.
  RecursiveInit
  /// Some plugins failed to load, `(name, reason)` pairs.
  BrokenPlugins(Array[(String, String)])
  /// Reference to a plugin that is not loaded.
  UnknownPlugin(String)
  /// The program shall exit with the given code.
  ExitRequested(Int32)
  /// The specified recipe could not be loaded.
  BadRecipe(String)
  /// The configuration context is already sealed.
  AlreadyDefined
}

///|
let error_printers : Array[(Error) -> String?] = []

///|
/// `register_error_printer to_string` registers a printer for a subset of
/// errors (`Extension.Error.register_printer`). Printers registered later
/// are tried first.
pub fn register_error_printer(printer : (Error) -> String?) -> Unit {
  error_printers.push(printer)
}

///|
/// OCaml `%S` formatting (a double-quoted, escaped string).
fn ocaml_quote(s : String) -> String {
  let sb = StringBuilder()
  sb.write_char('"')
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\t' => sb.write_string("\\t")
      '\r' => sb.write_string("\\r")
      c => sb.write_char(c)
    }
  }
  sb.write_char('"')
  sb.to_string()
}

///|
fn builtin_error_message(err : Error) -> String? {
  match err {
    Configuration =>
      Some(
        "Failed to process command-line options and configuration paratemers.",
      )
    Invalid(msg) => Some("Invalid parameter: \{msg}")
    Bug(exn, backtrace) =>
      Some("Internal error: \{error_to_string(exn)}\nBacktrace:\n\{backtrace}")
    AlreadyInitialized => Some("The system was already initialized")
    AlreadyFailed(e) =>
      Some(
        "The system was left in an inconsistent state after the last attempt to initialize, which failed with:\n\{error_to_string(e)}",
      )
    RecursiveInit =>
      Some(
        "The system initialization procedure was called during the initialization. Aborting the infinite cycle.",
      )
    BrokenPlugins(errors) => {
      let details = errors.map(e => {
        "The plugin `\{e.0}' has failed with the following error:\n\{e.1}\n"
      })
      Some(
        "Failed to load \{errors.length()} plugins, details follow:\n\{details.join("\n")}",
      )
    }
    UnknownPlugin(p) =>
      Some("There is no plugin \{ocaml_quote(p)} in the search path.")
    ExitRequested(0) => Some("All is good.")
    ExitRequested(n) => Some("Exiting with \{n}.")
    BadRecipe(msg) => Some("Can't load the specified recipe:\n\{msg}")
    AlreadyDefined => Some("Already_defined")
    _ => None
  }
}

///|
/// `error_to_string err` is a human readable description of `err`
/// (`Extension.Error.pp`).
pub fn error_to_string(err : Error) -> String {
  for i = error_printers.length() - 1; i >= 0; i = i - 1 {
    if error_printers[i](err) is Some(msg) {
      return msg
    }
  }
  match builtin_error_message(err) {
    Some(msg) => msg
    None => err.to_string()
  }
}

///|
pub impl Show for MainError with fn output(self, logger) {
  logger.write_string(error_to_string(self))
}

///|
pub extend MainError with Show::{to_string, output}
