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
  _phantom : K?
}

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
pub fn[K, S, T] Class::refine(
  self : Class[K, S],
  name~ : Name,
  sort~ : T,
  desc? : String,
) -> Class[K, T] {
  {
    name,
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
  {
    owner: self.name,
    name,
    domain_value: domain,
    desc,
    persistent_value: persistent,
    _phantom: None,
  }
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
