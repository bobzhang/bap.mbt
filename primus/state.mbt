///|
/// A typed machine state slot (upstream `Primus.Machine.State.t`).
///
/// A state is declared once (usually as a toplevel value) and is then
/// accessed through a machine with `Machine::get_local`/`put_local`
/// (per-fork state), `get_global`/`put_global` (shared by all forks) or
/// `get_other`/`put_other` (the local state of another fork).
///
/// Values stored in states must be persistent (immutable) data: forking a
/// machine shares the state bag between the parent and the child, exactly
/// as the upstream implementation shares its immutable `Univ_map`.
pub struct State[T] {
  priv id : Int
  priv uuid : String
  priv name : String
  priv init : (@project.Project) -> T
  priv inspect : (T) -> Sexp
  priv cell : Ref[T?]
}

///|
let state_uuids : Map[String, String] = Map([])

///|
let last_state_id : Ref[Int] = { val: 0, }

///|
fn is_hex_char(c : Char) -> Bool {
  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
}

///|
/// Checks that the string is an RFC4122-shaped UUID
/// (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).
pub fn is_valid_uuid(uuid : String) -> Bool {
  let groups = [8, 4, 4, 4, 12]
  let parts = uuid.split("-").collect()
  if parts.length() != groups.length() {
    return false
  }
  for i, part in parts {
    if part.length() != groups[i] {
      return false
    }
    for c in part {
      if !is_hex_char(c) {
        return false
      }
    }
  }
  true
}

///|
/// Declares a new state (upstream `Machine.State.declare`).
///
/// `init` computes the initial value from the project the first time the
/// state is read in a machine. The `uuid` must be a valid UUID and must not
/// be reused by another state; violations abort, like the upstream
/// `invalid_arg`.
pub fn[T] State::declare_(
  uuid~ : String,
  name~ : String,
  inspect? : (T) -> Sexp = opaque_sexp,
  init : (@project.Project) -> T,
) -> State[T] {
  if !is_valid_uuid(uuid) {
    abort("UUID: '\{uuid}' is not RFC4122 compliant")
  }
  if state_uuids.get(uuid) is Some(other) {
    abort(
      "State invariant is broken - the same key witnesses different types. Key \{name} with uuid \{uuid} was already created for \{other}",
    )
  }
  state_uuids[uuid] = name
  last_state_id.val += 1
  { id: last_state_id.val, uuid, name, init, inspect, cell: { val: None, }, }
}

///|
pub fn[T] State::name(self : State[T]) -> String {
  self.name
}

///|
pub fn[T] State::uuid(self : State[T]) -> String {
  self.uuid
}

///|
pub fn[T] State::inspect(self : State[T], x : T) -> Sexp {
  (self.inspect)(x)
}

///|
/// A persistent heterogeneous map from states to their values
/// (upstream `State.Bag.t`).
///
/// Each binding is an erased closure that, when called, writes the stored
/// value into the owning state's private cell; the typed accessor reads it
/// back immediately. This is the classic reference-based encoding of a
/// universal map and keeps the bag immutable, so forking is O(1).
priv struct Bag {
  slots : @sorted_map.SortedMap[Int, () -> Unit]
}

///|
fn Bag::empty() -> Bag {
  { slots: @sorted_map.SortedMap::new(), }
}

///|
fn[T] Bag::find(self : Bag, state : State[T]) -> T? {
  match self.slots.get(state.id) {
    None => None
    Some(load) => {
      load()
      let v = state.cell.val
      state.cell.val = None
      v
    }
  }
}

///|
fn[T] Bag::set(self : Bag, state : State[T], value : T) -> Bag {
  let cell = state.cell
  { slots: self.slots.add(state.id, () => cell.val = Some(value)), }
}
