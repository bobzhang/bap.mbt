///|
/// # A binding to the Z3 SMT solver
///
/// The subset of the Z3 C API used by the Primus symbolic executor:
/// contexts, bitvector and boolean terms, solvers with scopes and
/// timeouts, and models whose values are read back as `@types.Word`.
///
/// On the native target the Z3 shared library is loaded at run time (see
/// `z3_stub.c`), so the binding builds without Z3 and reports the solver
/// as unavailable when the library cannot be found. The library is
/// looked up at the path set with `load_library`, then at the path in the
/// `BAP_Z3_LIBRARY` environment variable, then on the dynamic linker path
/// (`libz3.dylib`, `libz3.so`) and in the Homebrew and `/usr/local`
/// locations. On the other targets the solver is never available.
///
/// Every object keeps its context alive; Z3 errors are reported as
/// `Z3Error::Failure` instead of aborting the process.
pub(all) suberror Z3Error {
  /// The solver library is not available (with the reason).
  Unavailable(String)
  /// A Z3 call failed (with the Z3 error message).
  Failure(String)
} derive(Eq, Debug)

///|
/// The message of the error.
pub fn Z3Error::message(self : Z3Error) -> String {
  match self {
    Unavailable(m) | Failure(m) => m
  }
}

///|
pub impl Show for Z3Error with fn output(self, logger) {
  logger.write_string(self.message())
}

///|
fn bytes_to_string(b : Bytes) -> String {
  @utf8.decode_lossy(b)
}

///|
fn c_string(s : String) -> Bytes {
  @utf8.encode(s)
}

///|
/// Whether the Z3 library is available (loading it on first use).
pub fn is_available() -> Bool {
  raw_available()
}

///|
/// Why the solver is unavailable (the last library loading error).
pub fn unavailable_reason() -> String {
  bytes_to_string(raw_load_error())
}

///|
/// Loads the Z3 library from an explicit path. Does nothing if a library
/// is already loaded.
pub fn load_library(path : String) -> Unit raise Z3Error {
  let err = bytes_to_string(raw_load(c_string(path)))
  if err != "" {
    raise Unavailable(err)
  }
}

///|
/// The version of the loaded Z3 library (`major.minor.build.revision`).
pub fn version() -> String? {
  if !is_available() {
    return None
  }
  Some(bytes_to_string(raw_version()))
}

///|
/// A Z3 context. Terms of different contexts must not be mixed.
pub struct Context {
  priv raw : RawCtx
}

///|
/// Creates a context with the configuration parameters (e.g.,
/// `("model", "true")`, `("timeout", "16")`). Raises `Unavailable` if the
/// solver library is not available.
pub fn Context::new(
  params~ : Array[(String, String)] = [("model", "true")],
) -> Context raise Z3Error {
  if !is_available() {
    raise Unavailable("SMT solver unavailable: " + unavailable_reason())
  }
  let buf = StringBuilder()
  for kv in params {
    buf.write_string(kv.0)
    buf.write_char('\u{0}')
    buf.write_string(kv.1)
    buf.write_char('\u{0}')
  }
  let raw = raw_mk_context(c_string(buf.to_string()))
  if raw_ctx_is_null(raw) {
    raise Unavailable("SMT solver unavailable: unable to create a context")
  }
  { raw, }
}

///|
/// Raises the error of the last Z3 call made in the context, if any.
fn Context::check(self : Context) -> Unit raise Z3Error {
  if raw_error_code(self.raw) != 0 {
    raise Failure(bytes_to_string(raw_error(self.raw)))
  }
}

///|
/// Updates a context parameter (`Z3_update_param_value`), e.g.,
/// `ctx.update_param("timeout", "100")`.
pub fn Context::update_param(
  self : Context,
  key : String,
  value : String,
) -> Unit raise Z3Error {
  raw_update_param(self.raw, c_string(key), c_string(value))
  self.check()
}
