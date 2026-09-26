// The `cxxfilt` plugin (upstream `plugins/cxxfilt`).
//
// Upstream the plugin provides the `bap:c++filt` demangler by running
// `c++filt -p NAME` for every name. Processes cannot be spawned here, so
// the demangler is the native Itanium C++ ABI demangler of
// `demangle/itanium`, which reproduces the output of `llvm-cxxfilt`.

///|
/// The plugin name.
pub let name : String = "cxxfilt"

///|
/// The name of the demangler (in the `bap` package), as upstream.
pub let demangler_name : String = "c++filt"

///|
/// The name of the demangler that keeps function parameters (in the `bap`
/// package): `c++filt` without `-p`.
pub let full_demangler_name : String = "itanium"

///|
let doc : String =
  #|Provides a native Itanium C++ ABI demangler compatible with c++filt.
  #|
  #|It demangles C++ names mangled according to the Itanium C++ ABI (the
  #|mangling of GCC and Clang).
  #|
  #|Provides the `c++filt` demangler, which prints demangled names without
  #|the function parameters (as `c++filt -p`), and the `itanium`
  #|demangler, which keeps them. Names that are not mangled are left
  #|unchanged.

///|
/// Demangles a name like `c++filt -p`: without function parameters.
/// Names that are not valid manglings are returned unchanged.
///
/// ```mbt check
/// test {
///   inspect(@cxxfilt.run("_ZN3foo3barEi"), content="foo::bar")
///   inspect(@cxxfilt.run("main"), content="main")
/// }
/// ```
pub fn run(name : String) -> String {
  @itanium.cxxfilt(name, params=false)
}

///|
/// Demangles a name with its function parameters, like `c++filt`.
///
/// ```mbt check
/// test {
///   inspect(@cxxfilt.run_full("_ZN3foo3barEi"), content="foo::bar(int)")
/// }
/// ```
pub fn run_full(name : String) -> String {
  @itanium.cxxfilt(name)
}

///|
fn declare_demangler(
  name : String,
  run : (String) -> String,
) -> Result[Unit, String] {
  match @demangle.Demanglers::lookup(name, pkg="bap") {
    Some(_) => Ok(())
    None => @demangle.Demangler::declare_(name, run, pkg="bap")
  }
}

///|
/// Registers the `bap:c++filt` and `bap:itanium` demanglers (idempotent).
pub fn register() -> Result[Unit, String] {
  match declare_demangler(demangler_name, run) {
    Ok(_) => declare_demangler(full_demangler_name, run_full)
    Err(e) => Err(e)
  }
}

///|
/// Declares the `cxxfilt` plugin in the `bap_main` framework.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["c++", "demangler", "c++filt"],
    doc~,
    () => {
      @bap_main.Extension::register(_ => {
        match register() {
          Ok(_) => ()
          Err(e) => fail(e)
        }
      })
    },
  )
}
