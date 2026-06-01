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
pub fn[K, S] Class::create(
  name~ : Name,
  sort~ : S,
  desc? : String,
) -> Class[K, S] {
  { name, sort_value: sort, desc, _phantom: None }
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
) -> Slot[K, P] {
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
  { name: self.owner, sort_value: (), desc: None, _phantom: None }
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
