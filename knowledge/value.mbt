///|
/// A knowledge value of the class `Class[K, S]` (`('k,'s) cls value`).
///
/// A value is a snapshot of all properties of an object: an extensible
/// record whose fields are the slots of the class `K`, plus the sort `S`
/// of the class. Values are ordered by their information content and,
/// additionally, totally ordered (by information, then by age), so they
/// can be used as keys of ordered collections. Every new value gets a
/// unique time-stamp (except `refine`, which keeps it).
struct Value[K, S] {
  cls : Class[K, S]
  data : Record
  time : Int
}

///|
let value_clock : Ref[Int] = { val: 0, }

///|
fn next_second() -> Int {
  value_clock.val = value_clock.val + 1
  value_clock.val
}

///|
fn[K, S] Value::create(cls : Class[K, S], data : Record) -> Value[K, S] {
  { cls, data, time: next_second(), }
}

///|
/// `Value.empty cls`: the value of the class with all slots empty.
pub fn[K, S] Value::empty(cls : Class[K, S]) -> Value[K, S] {
  Value::create(cls, empty_record)
}

///|
/// `Value.is_empty x`: all properties of `x` are empty.
pub fn[K, S] Value::is_empty(self : Value[K, S]) -> Bool {
  self.data.is_empty()
}

///|
/// `Value.cls x`: the class (and sort) of the value.
pub fn[K, S] Value::cls(self : Value[K, S]) -> Class[K, S] {
  self.cls
}

///|
/// `Value.order x y`: orders values by their information content.
pub fn[K, S] Value::order(
  self : Value[K, S],
  other : Value[K, S],
) -> PartialOrder {
  self.data.order(other.data)
}

///|
/// The total order of values: by information content, and values with
/// non-comparable information are ordered by their age.
pub fn[K, S] Value::compare(self : Value[K, S], other : Value[K, S]) -> Int {
  match self.data.order(other.data) {
    Less => -1
    Equal => 0
    Greater => 1
    Incomparable => self.time.compare(other.time)
  }
}

///|
/// Values with equal information content are equal.
pub fn[K, S] Value::equal(self : Value[K, S], other : Value[K, S]) -> Bool {
  self.compare(other) == 0
}

///|
/// `Value.get p v`: the property `p` of `v` (the empty value of the slot
/// domain if the property is not set).
///
/// Panics if the property is not set and the slot domain has no bottom;
/// use `Value::find` for such slots.
pub fn[K, S, P] Value::get(self : Value[K, S], slot : Slot[K, P]) -> P {
  match self.find(slot) {
    Some(value) => value
    None =>
      match slot.domain_value.empty() {
        Some(empty) => empty
        None => abort("Value.get: slot \{slot.name.show()} has no bottom")
      }
  }
}

///|
/// The property `p` of `v` if it is set.
pub fn[K, S, P] Value::find(self : Value[K, S], slot : Slot[K, P]) -> P? {
  self.data.find(slot.key)
}

///|
/// `Value.put p v x`: a new value with the property `p` set to `x`. The
/// previous value of the property is ignored (no monotonicity check).
/// Putting an empty value returns `v` unchanged.
pub fn[K, S, P] Value::put(
  self : Value[K, S],
  slot : Slot[K, P],
  value : P,
) -> Value[K, S] {
  if slot.domain_value.is_empty(value) {
    self
  } else {
    {
      ..self,
      data: self.data.put(slot.key, slot.ops, value),
      time: next_second(),
    }
  }
}

///|
/// `Value.has p v`: the property `p` of `v` is not empty.
pub fn[K, S, P] Value::has(self : Value[K, S], slot : Slot[K, P]) -> Bool {
  match self.find(slot) {
    Some(value) => !slot.domain_value.is_empty(value)
    None => false
  }
}

///|
/// `x.![p]`: the property `p` or rejects with `Empty` if it is empty.
pub fn[K, S, P] Value::require(
  self : Value[K, S],
  slot : Slot[K, P],
) -> P raise Conflict {
  match self.find(slot) {
    Some(value) if !slot.domain_value.is_empty(value) => value
    _ => raise Empty(slot.name)
  }
}

///|
/// `x.?[p]`: the optional property `p` or rejects with `Empty` if `None`.
pub fn[K, S, P] Value::require_some(
  self : Value[K, S],
  slot : Slot[K, P?],
) -> P raise Conflict {
  match self.find(slot) {
    Some(Some(value)) => value
    _ => raise Empty(slot.name)
  }
}

///|
/// `Value.refine v s`: the same value with the sort refined to `s` (the
/// time-stamp is preserved, so `v = refine v s`).
pub fn[K, S, T] Value::refine(self : Value[K, S], sort : T) -> Value[K, T] {
  {
    cls: {
      name: self.cls.name,
      sort_value: sort,
      desc: self.cls.desc,
      _phantom: None,
    },
    data: self.data,
    time: self.time,
  }
}

///|
/// `Value.join x y`: joins pairwise all slots of `x` and `y`, raising a
/// `JoinConflict` if any pair is not joinable.
pub fn[K, S] Value::join(
  self : Value[K, S],
  other : Value[K, S],
) -> Value[K, S] raise Conflict {
  match self.data.join(other.data) {
    Ok(data) => { ..self, data, time: next_second(), }
    Err(reason) => raise JoinConflict(reason)
  }
}

///|
/// Conflict resolution strategies of `Value::merge`.
pub(all) enum MergeStrategy {
  /// a conflicting property of the older value is ignored
  DropOld
  /// a conflicting property of the newer value is ignored
  DropNew
  /// a conflicting property of the right value is ignored
  DropRight
  /// a conflicting property of the left value is ignored
  DropLeft
} derive(Eq, Debug)

///|
pub extend MergeStrategy with Eq::{not_equal, equal}

///|
pub extend MergeStrategy with Debug::{to_repr}

///|
/// `Value.merge ?on_conflict x y`: joins `x` and `y`, resolving conflicting
/// properties with the given strategy (defaults to `DropOld`).
pub fn[K, S] Value::merge(
  self : Value[K, S],
  other : Value[K, S],
  on_conflict? : MergeStrategy = DropOld,
) -> Value[K, S] {
  let drop_left = match on_conflict {
    DropOld => self.time < other.time
    DropNew => !(self.time < other.time)
    DropLeft => true
    DropRight => false
  }
  let merged = self.data.merge_with(other.data, (x, y) => {
    Some(if drop_left { y } else { x })
  })
  match merged {
    Ok(data) => { ..self, data, time: next_second(), }
    Err(_) => abort("Value.merge: unresolved conflict")
  }
}

///|
/// `Value.pp`: all properties of the value, `((slot value) ...)`.
pub fn[K, S] Value::inspect(self : Value[K, S]) -> String {
  self.data.inspect()
}

///|
/// `Value.pp_slots slots`: only the properties named in `slots` (a single
/// requested slot is printed without its name).
pub fn[K, S] Value::inspect_slots(
  self : Value[K, S],
  slots : Array[String],
) -> String {
  self.data.inspect_slots(slots)
}

///|
pub fn[K, S] Value::to_string(self : Value[K, S]) -> String {
  self.inspect()
}

///|
/// The persistent properties of the value, as `(slot name, data)` pairs.
pub fn[K, S] Value::serialize(self : Value[K, S]) -> Array[(Name, String)] {
  self.data.serialize()
}

///|
/// `Value.derive cls` (domain part): values of the class form a domain
/// with the empty value as the bottom and pairwise join, so that values
/// could themselves be properties (e.g., Core Theory semantics).
pub fn[K, S] Value::domain(cls : Class[K, S]) -> Domain[Value[K, S]] {
  Domain::new(
    name=cls.name(),
    empty=Some(Value::empty(cls)),
    is_empty=v => v.is_empty(),
    order=(x, y) => x.order(y),
    join=(x, y) => {
      match x.data.join(y.data) {
        Ok(data) => Ok({ ..x, data, time: next_second(), })
        Err(reason) => Err(reason)
      }
    },
    inspect=v => v.inspect(),
  )
}

///|
/// `Value.derive cls` (binable part): persists the persistent properties
/// of a value (non-persistent properties are dropped).
pub fn[K, S] Value::persistent(cls : Class[K, S]) -> Persistent[Value[K, S]] {
  Persistent::create(
    to_string=v => {
      let parts = []
      for field in v.data.serialize() {
        let name = field.0.show()
        parts.push("\{name.length()}:\{name}\{field.1.length()}:\{field.1}")
      }
      parts.join("")
    },
    of_string=input => {
      let mut data = empty_record
      let mut offset = 0
      while offset < input.length() {
        let (name, next) = match
          persistent_decode_chunk(input, offset, "value") {
          Ok(chunk) => chunk
          Err(reason) => return Err(reason)
        }
        let (payload, next) = match
          persistent_decode_chunk(input, next, "value") {
          Ok(chunk) => chunk
          Err(reason) => return Err(reason)
        }
        offset = next
        match slots_by_name.get(Name::read(name)) {
          Some({ decode: Some(decode), .. }) =>
            match decode(payload) {
              Ok(entry) => data = data.put_entry(entry)
              Err(reason) => return Err(reason)
            }
          _ => ()
        }
      }
      Ok(Value::create(cls, data))
    },
  )
}
