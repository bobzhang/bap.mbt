///|
struct Class[K, S] {
  name : Name
  sort_value : S
  desc : String?
  _phantom : K?
}

///|
struct Slot[K, P] {
  owner : Name
  name : Name
  domain_value : Domain[P]
  desc : String?
  persistent_value : Persistent[P]?
  key : Key[P]
  ops : EntryOps
  /// promises registered for this slot (`Slot.promises`), keyed by pid in
  /// registration order
  promises : Map[Int, (State, Object[K]) -> Unit raise]
  /// observers registered for this slot (`Slot.watchers`)
  watchers : Map[Int, (State, Object[K], P) -> Unit raise]
}

///|
/// A type-erased handle on a declared slot, used by `run` to compute all
/// promised properties of an object (`Slot.enum`) and by the knowledge
/// base loader to find persistent readers.
priv struct SlotPack {
  uid : Int
  has_promises : () -> Bool
  collect : (State, Int) -> Unit raise
  decode : ((String) -> Result[Entry, String])?
}

///|
/// Slots of each class (by class name, then by slot name). Redeclaring a
/// slot with the same name replaces the previous registration.
let class_slots : Map[Name, Map[Name, SlotPack]] = Map([])

///|
/// The most recent declaration of every slot, by slot name.
let slots_by_name : Map[Name, SlotPack] = Map([])

///|
struct DocumentationClass {
  name_value : Name
  desc_value : String
}

///|
struct DocumentationProperty {
  name_value : Name
  desc_value : String
}

///|
let documented_classes : Map[String, DocumentationClass] = Map([])

///|
let documented_properties : Map[String, Array[DocumentationProperty]] = Map([])

///|
fn documentation_desc(desc : String?) -> String {
  match desc {
    Some(text) => text
    None => ""
  }
}

///|
fn documentation_add_property(
  properties : Array[DocumentationProperty],
  property : DocumentationProperty,
) -> Unit {
  match properties.search_by(item => item.name().equal(property.name())) {
    Some(index) => properties[index] = property
    None => properties.push(property)
  }
}

///|
pub fn[K, S] Class::create(
  name~ : Name,
  sort~ : S,
  desc? : String,
  public? : Bool = false,
) -> Class[K, S] {
  if public {
    documented_classes[name.show()] = {
      name_value: name,
      desc_value: documentation_desc(desc),
    }
    if !documented_properties.contains(name.show()) {
      documented_properties[name.show()] = []
    }
  }
  { name, sort_value: sort, desc, _phantom: None, }
}

///|
/// `Class.refine cls s`: the same class with the sort refined to `s`.
///
/// Upstream a refinement always denotes the same class (same name, same
/// slots and objects). The optional `name` is a port extension that
/// declares a *different* class sharing the sort description; objects of
/// such a class do not share the slots of `cls`.
pub fn[K, S, T] Class::refine(
  self : Class[K, S],
  name? : Name,
  sort~ : T,
  desc? : String,
) -> Class[K, T] {
  {
    name: match name {
      Some(name) => name
      None => self.name
    },
    sort_value: sort,
    desc: match desc {
      Some(text) => Some(text)
      None => self.desc
    },
    _phantom: None,
  }
}

///|
pub fn[K, S, T] Class::same(self : Class[K, S], other : Class[K, T]) -> Bool {
  self.name == other.name
}

///|
pub fn[K, S] Class::name(self : Class[K, S]) -> Name {
  self.name
}

///|
pub fn[K, S] Class::sort(self : Class[K, S]) -> S {
  self.sort_value
}

///|
pub fn[K, S] Class::desc(self : Class[K, S]) -> String? {
  self.desc
}

///|
pub fn[K, S, P] Class::property(
  self : Class[K, S],
  name~ : Name,
  domain~ : Domain[P],
  desc? : String,
  persistent? : Persistent[P],
  public? : Bool = false,
) -> Slot[K, P] {
  if public {
    match documented_properties.get(self.name.show()) {
      Some(properties) =>
        documentation_add_property(properties, {
          name_value: name,
          desc_value: documentation_desc(desc),
        })
      None => ()
    }
  }
  let key : Key[P] = Key::fresh(name)
  let ops = entry_ops(key, domain, persistent)
  let slot : Slot[K, P] = {
    owner: self.name,
    name,
    domain_value: domain,
    desc,
    persistent_value: persistent,
    key,
    ops,
    promises: {},
    watchers: {},
  }
  let owner = self.name
  let pack : SlotPack = {
    uid: key.uid,
    has_promises: () => !slot.promises.is_empty(),
    collect: (state, id) => {
      ignore(state.collect(slot, { id, class_name: owner, _phantom: None, }))
    },
    decode: match persistent {
      Some(io) =>
        Some(data => {
          match io.decode(data) {
            Ok(value) => Ok(key.inject(ops, value))
            Err(reason) => Err(reason)
          }
        })
      None => None
    },
  }
  match class_slots.get(owner) {
    Some(slots) => slots[name] = pack
    None => class_slots[owner] = Map::from_array([(name, pack)])
  }
  slots_by_name[name] = pack
  slot
}

///|
pub fn[K, P] Slot::owner(self : Slot[K, P]) -> Name {
  self.owner
}

///|
pub fn[K, P] Slot::cls(self : Slot[K, P]) -> Class[K, Unit] {
  { name: self.owner, sort_value: (), desc: None, _phantom: None, }
}

///|
pub fn[K, P] Slot::name(self : Slot[K, P]) -> Name {
  self.name
}

///|
pub fn[K, P] Slot::domain(self : Slot[K, P]) -> Domain[P] {
  self.domain_value
}

///|
pub fn[K, P] Slot::desc(self : Slot[K, P]) -> String {
  match self.desc {
    Some(text) => text
    None => "no description"
  }
}

///|
/// The number of promises currently registered for the slot.
pub fn[K, P] Slot::promise_count(self : Slot[K, P]) -> Int {
  self.promises.length()
}

///|
/// The number of observers currently registered for the slot.
pub fn[K, P] Slot::observer_count(self : Slot[K, P]) -> Int {
  self.watchers.length()
}

///|
pub fn[K, P] Slot::persistent(self : Slot[K, P]) -> Persistent[P]? {
  self.persistent_value
}

///|
pub fn DocumentationClass::name(self : DocumentationClass) -> Name {
  self.name_value
}

///|
pub fn DocumentationClass::desc(self : DocumentationClass) -> String {
  self.desc_value
}

///|
pub fn DocumentationProperty::name(self : DocumentationProperty) -> Name {
  self.name_value
}

///|
pub fn DocumentationProperty::desc(self : DocumentationProperty) -> String {
  self.desc_value
}

///|
pub fn Documentation::classes() -> Array[
  (DocumentationClass, Array[DocumentationProperty]),
] {
  let entries = []
  documented_classes.each((key, cls) => {
    let properties = match documented_properties.get(key) {
      Some(values) => values.copy()
      None => []
    }
    properties.sort_by((left, right) => left.name().compare(right.name()))
    entries.push((cls, properties))
  })
  entries.sort_by((left, right) => left.0.name().compare(right.0.name()))
  entries
}
