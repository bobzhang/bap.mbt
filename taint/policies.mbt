// The standard taint propagation policies (upstream
// `plugins/primus_taint/primus_taint_policies.ml`). They live in this
// package so that every client of the framework can use them; the
// `primus_taint` plugin registers them as Primus components.

///|
/// The name of the policy implemented by `propagate_by_computation`.
pub let computation_policy_name : String = "propagate-by-computation"

///|
/// The name of the policy implemented by `propagate_exactly`.
pub let exact_policy_name : String = "propagate-exactly"

///|
fn propagator(
  m : @primus.Machine,
  name : String,
  rs : Rel,
  rd : Rel,
  srcs : Array[@primus.Value],
  dst : @primus.Value,
) -> Unit raise {
  Policy::propagate(m, Policy::of_name(m, name), rs, rd, srcs, dst)
}

///|
/// A store kills the indirect taints of the address and attaches the
/// direct taints of the stored value to it.
///
/// As upstream, the store handler of a policy kills *all* indirect taints
/// of the address, including the ones propagated by another policy
/// component that observed the same store before it. Installing both
/// components therefore loses the memory taints of the policy whose
/// handler runs first; select policies per kind with care when both are
/// installed.
fn propagate_store(
  m : @primus.Machine,
  name : String,
  addr : @primus.Value,
  value : @primus.Value,
) -> Unit raise {
  let ts = Tracker::lookup(m, addr, Indirect)
  Tracker::detach(m, addr, Indirect, ts)
  propagator(m, name, Direct, Indirect, [value], addr)
}

///|
/// Observers shared by both policies: loads, stores, extracts, concats
/// and casts transfer taints.
fn transparent_operations(m : @primus.Machine, name : String) -> Unit {
  m.observe(@primus.loaded, p => {
    let (addr, value) = p
    propagator(m, name, Indirect, Direct, [addr], value)
  })
  m.observe(@primus.stored, p => propagate_store(m, name, p.0, p.1))
  m.observe(@primus.extract, p => {
    let ((_, _, x), r) = p
    propagator(m, name, Direct, Direct, [x], r)
  })
  m.observe(@primus.concat, p => {
    let ((x, y), r) = p
    propagator(m, name, Direct, Direct, [x, y], r)
  })
  m.observe(@primus.cast, p => {
    let ((_, _, x), r) = p
    propagator(m, name, Direct, Direct, [x], r)
  })
}

///|
/// The `propagate-by-computation` policy component (upstream
/// `Primus_taint_policies.Computation`): a value is tainted if it was
/// computed from a tainted value. Loaded values receive the indirect
/// taints of their addresses; stored values replace the indirect taints
/// of their addresses.
pub fn propagate_by_computation(m : @primus.Machine) -> Unit {
  let name = computation_policy_name
  transparent_operations(m, name)
  m.observe(@primus.binop, p => {
    let ((_, x, y), r) = p
    propagator(m, name, Direct, Direct, [x, y], r)
  })
  m.observe(@primus.unop, p => {
    let ((_, x), r) = p
    propagator(m, name, Direct, Direct, [x], r)
  })
}

///|
/// The `propagate-exactly` policy component (upstream
/// `Primus_taint_policies.Exact`): a taint is propagated only through
/// operations that transfer the value without computing on it (loads,
/// stores, casts, concats and extracts).
pub fn propagate_exactly(m : @primus.Machine) -> Unit {
  transparent_operations(m, exact_policy_name)
}
