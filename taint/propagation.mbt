// Policy based taint propagation (upstream `Taint.Propagation`).
//
// A propagation policy is associated with a kind of objects; objects of
// a kind that didn't select its own policy are propagated with the
// default policy. The policy selection is local to every machine.

///|
/// A taint propagation policy (upstream `Taint.Propagation.Policy.t`),
/// represented by the Primus symbol value of its name.
pub struct Policy {
  priv value : @primus.Value
}

///|
/// Injects the policy into the value domain (`Policy.to_value`).
pub fn Policy::to_value(self : Policy) -> @primus.Value {
  self.value
}

///|
/// Projects a value to a policy (`Policy.of_value`).
pub fn Policy::of_value(value : @primus.Value) -> Policy {
  { value, }
}

///|
/// The policy that is denoted by the given name (upstream
/// `Value.Symbol.to_value name >>= Policy.of_value`).
pub fn Policy::of_name(m : @primus.Machine, name : String) -> Policy raise {
  { value: @primus.Value::symbol_to_value(m, name), }
}

///|
/// The name of the policy.
pub fn Policy::name(self : Policy, m : @primus.Machine) -> String {
  @primus.Value::symbol_of_value(m, self.value)
}

///|
pub impl Eq for Policy with fn equal(self, other) {
  self.value.to_word() == other.value.to_word()
}

///|
pub extend Policy with Eq::{not_equal, equal}

///|
priv struct Policies {
  servers : @sorted_map.SortedMap[Kind, Policy]
  default : Policy?
}

///|
let policies : @primus.State[Policies] = @primus.State::declare_(
  name="taint-policies",
  uuid="4c370c33-ef1b-4e10-be27-ee751a4d6cf3",
  _ => { servers: @sorted_map.SortedMap::new(), default: None, },
)

///|
/// [select(m, p, k)] selects the policy `p` for the objects of kind `k`.
/// The first selected policy also becomes the default one, unless a
/// default policy is already set.
pub fn Policy::select(m : @primus.Machine, p : Policy, kind : Kind) -> Unit {
  m.update_local(policies, s => {
    servers: s.servers.add(kind, p),
    default: match s.default {
      Some(d) => Some(d)
      None => Some(p)
    },
  })
}

///|
/// [set_default(m, p)] makes `p` the default policy for all kinds that
/// didn't select their own policies.
pub fn Policy::set_default(m : @primus.Machine, p : Policy) -> Unit {
  m.update_local(policies, s => { ..s, default: Some(p), })
}

///|
fn has_selected(s : Policies, policy : Policy, kind : Kind) -> Bool {
  match s.servers.get(kind) {
    Some(p) => p == policy
    None =>
      match s.default {
        None => false
        Some(p) => p == policy
      }
  }
}

///|
/// [selected(m, p, k)] is `true` if the policy `p` is selected for the
/// kind `k` (either explicitly or as the default).
pub fn Policy::selected(m : @primus.Machine, p : Policy, kind : Kind) -> Bool {
  has_selected(m.get_local(policies), p, kind)
}

///|
/// The default policy, if any.
pub fn Policy::default(m : @primus.Machine) -> Policy? {
  m.get_local(policies).default
}

///|
/// [propagate(m, p, rs, rd, srcs, dst)] transfers objects associated
/// with `srcs` to `dst`: all objects that selected the policy `p` and are
/// related to the `srcs` values by `rs` are attached to `dst` with the
/// relation `rd`. The associations of `srcs` are unaffected.
pub fn Policy::propagate(
  m : @primus.Machine,
  p : Policy,
  rs : Rel,
  rd : Rel,
  srcs : ArrayView[@primus.Value],
  dst : @primus.Value,
) -> Unit raise {
  let state = m.get_local(tainter)
  let objects = m.get_global(kinds).objects
  let ps = m.get_local(policies)
  let mut taints = @sorted_set.SortedSet::new()
  for src in srcs {
    match find(state, src, rs) {
      None => ()
      Some(objs) =>
        taints = objs
          .filter(o => {
            match objects.get(o) {
              None => false
              Some(kind) => has_selected(ps, p, kind)
            }
          })
          .union(taints)
    }
  }
  Tracker::attach(m, dst, rd, taints)
}
