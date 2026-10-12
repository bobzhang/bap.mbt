///|
/// A typed key of a heterogeneous record (`Dict.Key`).
///
/// MoonBit has neither existential types nor a universal `Any`, so records
/// store their fields in a type-erased form using the classic "universal
/// type" embedding: a stored field is a closure that, when invoked, writes
/// the typed payload into the key's private cell. Projecting a field with
/// its key runs the closure and reads the cell back, so the typed value is
/// recovered without any unsafe cast. Every key has a unique `uid`, which
/// is the record index.
priv struct Key[T] {
  uid : Int32
  name : Name
  cell : Ref[T?]
}

///|
let key_counter : Ref[Int32] = { val: 0, }

///|
fn[T] Key::fresh(name : Name) -> Key[T] {
  key_counter.val = key_counter.val + 1
  { uid: key_counter.val, name, cell: { val: None, }, }
}

///|
/// The type-erased storage of a single field.
priv struct Entry {
  store : () -> Unit
  ops : EntryOps
}

///|
/// The domain operations of a field (upstream `Record.vtable` plus the
/// persistence `slot_io`), closed over the field's typed key.
priv struct EntryOps {
  uid : Int32
  name : Name
  order : (Entry, Entry) -> PartialOrder
  join : (Entry, Entry) -> Result[() -> Unit, String]
  inspect : (Entry) -> String
  encode : ((Entry) -> String)?
}

///|
fn[T] Key::project(self : Key[T], entry : Entry) -> T? {
  if entry.ops.uid != self.uid {
    return None
  }
  self.cell.val = None
  (entry.store)()
  let result = self.cell.val
  self.cell.val = None
  result
}

///|
fn[T] Key::storing(self : Key[T], value : T) -> () -> Unit {
  let cell = self.cell
  () => cell.val = Some(value)
}

///|
fn[T] Key::inject(self : Key[T], ops : EntryOps, value : T) -> Entry {
  { store: self.storing(value), ops, }
}

///|
fn[T] entry_ops(
  key : Key[T],
  domain : Domain[T],
  persistent : Persistent[T]?,
) -> EntryOps {
  let get = (entry : Entry) => key.project(entry).unwrap()
  {
    uid: key.uid,
    name: key.name,
    order: (x, y) => domain.order(get(x), get(y)),
    join: (x, y) => {
      match domain.join(get(x), get(y)) {
        Ok(joined) => Ok(key.storing(joined))
        Err(reason) => Err(reason)
      }
    },
    inspect: entry => domain.inspect(get(entry)),
    encode: match persistent {
      Some(io) => Some(entry => io.encode(get(entry)))
      None => None
    },
  }
}

///|
/// A heterogeneous record of slot values (`Record.t`), an immutable map
/// from key uids to type-erased fields.
priv struct Record {
  fields : @sorted_map.SortedMap[Int32, Entry]
}

///|
let empty_record : Record = { fields: @sorted_map.SortedMap::new(), }

///|
fn Record::is_empty(self : Record) -> Bool {
  self.fields.is_empty()
}

///|
fn[T] Record::find(self : Record, key : Key[T]) -> T? {
  match self.fields.get(key.uid) {
    Some(entry) => key.project(entry)
    None => None
  }
}

///|
fn[T] Record::put(
  self : Record,
  key : Key[T],
  ops : EntryOps,
  value : T,
) -> Record {
  { fields: self.fields.add(key.uid, key.inject(ops, value)), }
}

///|
fn Record::put_entry(self : Record, entry : Entry) -> Record {
  { fields: self.fields.add(entry.ops.uid, entry), }
}

///|
/// `Record.commit`: joins `value` into the field, failing on conflicts.
fn[T] Record::commit(
  self : Record,
  key : Key[T],
  ops : EntryOps,
  value : T,
) -> Result[Record, String] {
  let entry = key.inject(ops, value)
  match self.fields.get(key.uid) {
    None => Ok({ fields: self.fields.add(key.uid, entry), })
    Some(old) =>
      match (ops.join)(old, entry) {
        Ok(store) => Ok({ fields: self.fields.add(key.uid, { store, ops, }), })
        Err(reason) => Err(reason)
      }
  }
}

///|
/// `x <:= y`: every field of `x` is present in `y` with no less
/// information.
fn Record::leq(self : Record, other : Record) -> Bool {
  for uid, entry in self.fields {
    match other.fields.get(uid) {
      None => return false
      Some(that) =>
        match (entry.ops.order)(entry, that) {
          Less | Equal => ()
          Greater | Incomparable => return false
        }
    }
  }
  true
}

///|
/// `Record.order`: orders records by their information content.
fn Record::order(self : Record, other : Record) -> PartialOrder {
  if physical_equal(self.fields, other.fields) {
    return Equal
  }
  match (self.is_empty(), other.is_empty()) {
    (true, true) => Equal
    (true, false) => Less
    (false, true) => Greater
    (false, false) =>
      match (self.leq(other), other.leq(self)) {
        (true, false) => Less
        (true, true) => Equal
        (false, true) => Greater
        (false, false) => Incomparable
      }
  }
}

///|
/// Pairwise merge; `resolve` decides the result of a conflicting field
/// (`None` means fail with the conflict).
fn Record::merge_with(
  self : Record,
  other : Record,
  resolve : (Entry, Entry) -> Entry?,
) -> Result[Record, String] {
  let mut fields = self.fields
  for uid, entry in other.fields {
    match fields.get(uid) {
      None => fields = fields.add(uid, entry)
      Some(mine) =>
        match (mine.ops.join)(mine, entry) {
          Ok(store) => fields = fields.add(uid, { store, ops: mine.ops, })
          Err(reason) =>
            match resolve(mine, entry) {
              Some(chosen) => fields = fields.add(uid, chosen)
              None => return Err(reason)
            }
        }
    }
  }
  Ok({ fields, })
}

///|
/// `Record.join`: pairwise join, failing on the first conflict.
fn Record::join(self : Record, other : Record) -> Result[Record, String] {
  self.merge_with(other, (_, _) => None)
}

///|
/// `Record.inspect`: `((slot value) ...)`, one entry per non-empty field.
fn Record::inspect(self : Record) -> String {
  let parts = []
  for _, entry in self.fields {
    parts.push("(\{entry.ops.name.show()} \{(entry.ops.inspect)(entry)})")
  }
  "(\{parts.join(" ")})"
}

///|
/// Renders only the fields whose (shown) names are in `slots`.
fn Record::inspect_slots(self : Record, slots : Array[String]) -> String {
  let only_one = slots.length() == 1
  let parts = []
  for _, entry in self.fields {
    let name = entry.ops.name.show()
    if slots.contains(name) || slots.contains(entry.ops.name.unqualified()) {
      let value = (entry.ops.inspect)(entry)
      parts.push(if only_one { value } else { "(\{name} \{value})" })
    }
  }
  parts.join("\n")
}

///|
/// The persistent fields of the record as `(slot name, data)` pairs,
/// sorted by name (`Io.serialize_record`).
fn Record::serialize(self : Record) -> Array[(Name, String)] {
  let result = []
  for _, entry in self.fields {
    match entry.ops.encode {
      Some(encode) => result.push((entry.ops.name, encode(entry)))
      None => ()
    }
  }
  result.sort_by((x, y) => x.0.compare(y.0))
  result
}
