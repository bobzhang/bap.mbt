///|
/// A typed machine state slot (upstream `Primus.Machine.State.t`).
///
/// A state is declared once (usually as a toplevel value) and is then
/// accessed through a machine with `Machine::get_local`/`put_local`
/// (per-fork state), `get_global`/`put_global` (shared by all forks) or
/// `get_other`/`put_other` (the local state of another fork).
///
/// # Clone policy
///
/// Forking a machine shares the local state bag between the parent and the
/// child (O(1), like the upstream immutable `Univ_map`). Values stored in
/// states should therefore be persistent data: `@sorted_map.SortedMap`,
/// `@immut/hashmap.HashMap`, `@list.List`, immutable structs, or
/// `PersistentMap` (a thin wrapper provided by this package). Mutating a
/// shared `Array`, `Map` or `Ref` in place after a fork would leak the write
/// into the other machine; a *shallow* copy is not enough either when the
/// value contains further mutable data.
///
/// States that must hold mutable data declare a `clone` function: on every
/// fork the child receives `clone(value)` for each such state while the
/// parent keeps the original, so writes are isolated. The same rule applies
/// to data captured by host closures pushed as frames (tasks, handlers,
/// continuations: frames are shared between the parent and the child) and
/// to custom generator iterator states (`next` must return a new state).
pub struct State[T] {
  priv id : Int
  priv uuid : String
  priv name : String
  priv init : (@project.Project) -> T
  priv inspect : (T) -> Sexp
  priv clone : ((T) -> T)?
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
/// state is read in a machine. `clone`, when given, is applied to the value
/// of the state in the child of every fork (see the clone policy above).
/// The `uuid` must be a valid UUID and must not be reused by another
/// state; violations abort, like the upstream `invalid_arg`.
pub fn[T] State::declare_(
  uuid~ : String,
  name~ : String,
  inspect? : (T) -> Sexp = opaque_sexp,
  clone? : (T) -> T,
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
  {
    id: last_state_id.val,
    uuid,
    name,
    init,
    inspect,
    clone,
    cell: { val: None, },
  }
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
/// universal map and keeps the bag immutable, so forking is O(1) unless
/// some states declare a `clone` function.
priv struct Bag {
  slots : @sorted_map.SortedMap[Int, Slot]
  cloneable : Int
}

///|
priv struct Slot {
  load : () -> Unit
  copy : (() -> Slot)?
}

///|
fn Bag::empty() -> Bag {
  { slots: @sorted_map.SortedMap::new(), cloneable: 0, }
}

///|
fn[T] Bag::find(self : Bag, state : State[T]) -> T? {
  match self.slots.get(state.id) {
    None => None
    Some(slot) => {
      (slot.load)()
      let v = state.cell.val
      state.cell.val = None
      v
    }
  }
}

///|
fn[T] make_slot(state : State[T], value : T) -> Slot {
  let cell = state.cell
  {
    load: () => cell.val = Some(value),
    copy: match state.clone {
      None => None
      Some(f) => Some(() => make_slot(state, f(value)))
    },
  }
}

///|
fn[T] Bag::set(self : Bag, state : State[T], value : T) -> Bag {
  let old = match self.slots.get(state.id) {
    Some({ copy: Some(_), .. }) => 1
    _ => 0
  }
  let slot = make_slot(state, value)
  let new = if slot.copy is Some(_) { 1 } else { 0 }
  {
    slots: self.slots.add(state.id, slot),
    cloneable: self.cloneable - old + new,
  }
}

///|
/// The bag given to the child of a fork: states with a clone policy get a
/// cloned value, the others are shared.
fn Bag::fork(self : Bag) -> Bag {
  if self.cloneable == 0 {
    return self
  }
  {
    slots: self.slots.map((_, slot) => {
      match slot.copy {
        Some(copy) => copy()
        None => slot
      }
    }),
    cloneable: self.cloneable,
  }
}
