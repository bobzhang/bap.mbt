// Components and registration of the `primus-taint` plugin.

///|
/// The default value of the `--primus-taint-default-policy` option.
pub let default_policy : String = @taint.computation_policy_name

///|
/// A component that makes the named policy the default taint propagation
/// policy (upstream `policy_selector`).
pub fn policy_selector(name : String) -> (@primus.Machine) -> Unit raise {
  m => @taint.Policy::set_default(m, @taint.Policy::of_name(m, name))
}

///|
/// The components provided by the plugin: `(name, description, init)`.
fn components(
  policy : String,
) -> Array[(String, String, (@primus.Machine) -> Unit raise)] {
  [
    (
      "taint-primitives", "Exposes Primus Lisp primitives that controls the Primus Taint Engine.",
      install_lisp_primitives,
    ),
    (
      "taint-signals",
      "Reflects Primus Taint observations to Lisp signals.",
      m => install_lisp_signals(m),
    ),
    (
      "propagate-taint-exact",
      "Enables the exact taint propagation policy. In this policy, a taint is only propagated between values when one value is derived from another using some transparent (not changing the value computation), e.g., store, load, cast, concat, extract.",
      m => @taint.propagate_exactly(m),
    ),
    (
      "propagate-taint-by-computation",
      "Enables the propagate-by-computation taint propagation policy. In this policy, a value is tainted if it was computed using a tainted value.",
      m => @taint.propagate_by_computation(m),
    ),
    (
      "conservative-garbage-collector",
      "Enables taint garbage collector. The component scans the memory and registers and deletes taints that are no longer reachable.",
      m => @taint.Gc::conservative(m),
    ),
    (
      "select-default-taint-policy",
      "Sets the default policy to the value selected by a user via the --primus-taint-default-policy command-line option.",
      policy_selector(policy),
    ),
    (
      // upstream: `register_policy_selector "propagate-by-computation"`
      "select-propagate-by-computation-policy",
      "Selects the propagate-by-computation as the default taint propagation policy. This policy could be overwritten per each taint kind individually.",
      policy_selector("propagate-by-computation"),
    ),
    (
      // upstream: `register_policy_selector "propagate-taint-exact"`; note
      // that the exact policy is named `propagate-exactly`, so, as
      // upstream, this selector selects a policy that no component
      // implements.
      "select-propagate-taint-exact-policy",
      "Selects the propagate-taint-exact as the default taint propagation policy. This policy could be overwritten per each taint kind individually.",
      policy_selector("propagate-taint-exact"),
    ),
  ]
}

///|
fn is_registered(name : String) -> Bool {
  let full = "bap:\{name}"
  @primus.Components::list().iter().any(info => info.name().to_string() == full)
}

///|
/// Registers the components of the plugin in the Primus component
/// registry (package `bap`). The `select-default-taint-policy` component
/// selects `default_policy`. Idempotent: components that are already
/// registered are left untouched. Returns the number of newly registered
/// components.
pub fn register(default_policy~ : String = default_policy) -> Int32 {
  let mut added = 0
  for c in components(default_policy) {
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
let enabled : Ref[Bool] = { val: false, }

///|
/// Enables the plugin in the legacy main system (upstream
/// `declare_extension` body): both propagation policies, the default
/// policy selector and, if `gc` is `true` (the `--primus-taint-gc=
/// conservative` option), the conservative garbage collector. The
/// components are also registered (see `register`). Idempotent: only the
/// first call adds components to the machine; returns `false` if the
/// plugin was already enabled.
pub fn enable(
  default_policy~ : String = default_policy,
  gc~ : Bool = false,
) -> Bool {
  ignore(register(default_policy~))
  if enabled.val {
    return false
  }
  enabled.val = true
  @primus.Machine::add_component(m => @taint.propagate_exactly(m))
  @primus.Machine::add_component(m => @taint.propagate_by_computation(m))
  @primus.Machine::add_component(policy_selector(default_policy))
  if gc {
    @primus.Machine::add_component(m => @taint.Gc::conservative(m))
  }
  true
}
