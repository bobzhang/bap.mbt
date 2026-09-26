// Registration of the `primus-test` plugin.

///|
/// The name of the plugin.
pub let name : String = "primus-test"

///|
/// The Lisp features of the testing framework (in the `primus-test`
/// directory of the embedded Lisp library): `incident`, `check-value`,
/// `memcheck`, `memcheck-malloc`, and `warn-unused`.
pub fn features() -> Array[String] {
  @primus_lisp.embedded_features(["primus-test"])
}

///|
/// Registers the components `bap:incident-location-recorder` and
/// `bap:lisp-incidents`. Idempotent: returns the number of newly
/// registered components.
pub fn register() -> Int {
  let comps : Array[(String, String, (@primus.Machine) -> Unit raise)] = [
    (
      "incident-location-recorder",
      "Records tracepoints for incident reporting.",
      m => record_locations(m),
    ),
    (
      "lisp-incidents",
      "Exposes the incident reporting facitilites to Primus Lisp.",
      m => install_lisp(m),
    ),
  ]
  let mut added = 0
  for c in comps {
    @primus.Components::register_generic(c.0, c.2, pkg="bap", desc=c.1) catch {
      _ => continue
    }
    added += 1
  }
  added
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the components and adds them to the legacy main system, as
/// the upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  ignore(register())
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => record_locations(m))
    @primus.Machine::add_component(m => install_lisp(m))
  }
}

///|
/// Declares the plugin in the `bap_main` registry.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "primus-lisp", "primus-library", "verification"],
    doc="provides primitives for Primus Tesing and Verification Framework",
    () => @bap_main.Extension::register(_ => enable()),
  )
}
