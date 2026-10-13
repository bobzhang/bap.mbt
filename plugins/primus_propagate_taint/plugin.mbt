// Registration and configuration of the `primus-propagate-taint` plugin.

///|
/// Errors in the plugin configuration (upstream `invalid_arg`).
pub(all) suberror ConfigError {
  ConfigError(String)
} derive(Eq, Debug)

///|
pub extend ConfigError with Eq::{not_equal, equal}

///|
pub extend ConfigError with Debug::{to_repr}

///|
/// The components provided by the plugin: `(name, description, init)`.
fn components() -> Array[(String, String, (@primus.Machine) -> Unit raise)] {
  [
    (
      "taint-mapper",
      "Maintains a mapping between tainted objects and term identifiers.",
      m => mapper_component(m),
    ),
    (
      "taint-marker",
      "Translates tainted values of the Taint engine to tainted-regs and tainted-ptrs term attributes of the IR.",
      m => marker_component(m),
    ),
    (
      "taint-intro",
      "Introduces a taint when a term marked with tainted-reg or tainted-ptr is entered.",
      m => intro_component(m),
    ),
  ]
}

///|
fn is_registered(name : String) -> Bool {
  let full = "bap:\{name}"
  @primus.Components::list().iter().any(info => info.name().to_string() == full)
}

///|
/// Registers the `taint-mapper`, `taint-marker` and `taint-intro`
/// components (package `bap`). Idempotent; returns the number of newly
/// registered components.
pub fn register() -> Int32 {
  let mut added = 0
  for c in components() {
    let (name, desc, init) = c
    if !is_registered(name) {
      @primus.Components::register_generic(name, init, pkg="bap", desc~) catch {
        _ => continue
      }
      added += 1
    }
  }
  added
}

///|
let injection_enabled : Ref[Bool] = { val: false, }

///|
let projection_enabled : Ref[Bool] = { val: false, }

///|
/// Configures the plugin (upstream `declare_extension` body) and adds the
/// selected components to the legacy main system:
///
/// - `from_attributes` introduces taints from the `tainted-reg` and
///   `tainted-ptr` attributes (`taint-intro`);
/// - `to_attributes` reflects the state of the engine into the
///   `tainted-regs` and `tainted-ptrs` attributes (`taint-mapper` and
///   `taint-marker`);
/// - `run` (legacy interface) enables both, unless `no_marks` disables the
///   projection.
///
/// Mixing the options of the new and the legacy interfaces, or passing
/// `no_marks` without `run`, is an error. The components are registered
/// (see `register`) and every component is added at most once.
pub fn enable(
  from_attributes~ : Bool = false,
  to_attributes~ : Bool = false,
  run~ : Bool = false,
  no_marks~ : Bool = false,
) -> Unit raise ConfigError {
  if (from_attributes || to_attributes) && (run || no_marks) {
    raise ConfigError("Incorrect mix of old and new parameters")
  }
  if no_marks && !run {
    raise ConfigError(
      "The no-marks option is only valid if the run option is specified",
    )
  }
  ignore(register())
  let enable_injection = () => {
    if !injection_enabled.val {
      injection_enabled.val = true
      @primus.Machine::add_component(m => intro_component(m))
    }
  }
  let enable_projection = () => {
    if !projection_enabled.val {
      projection_enabled.val = true
      @primus.Machine::add_component(m => mapper_component(m))
      @primus.Machine::add_component(m => marker_component(m))
    }
  }
  if from_attributes {
    enable_injection()
  }
  if to_attributes {
    enable_projection()
  }
  if run {
    enable_injection()
    if !no_marks {
      enable_projection()
    }
  }
}

///|
/// Whether the injection (`taint-intro`) and the projection
/// (`taint-mapper`, `taint-marker`) are enabled in the legacy main system.
pub fn enabled() -> (Bool, Bool) {
  (injection_enabled.val, projection_enabled.val)
}
