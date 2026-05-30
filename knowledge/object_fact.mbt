///|
struct Object[K] {
  id : Int
  class_name : Name
  _phantom : K?
}

///|
struct State {
  mut next_id : Int
}

///|
struct FactTable[K, P] {
  slot : Slot[K, P]
  facts : Map[Int, P]
  _phantom : K?
}

///|
pub fn State::new() -> State {
  { next_id: 1 }
}

///|
pub fn[K, S] State::create(self : State, cls : Class[K, S]) -> Object[K] {
  let id = self.next_id
  self.next_id = id + 1
  { id, class_name: cls.name(), _phantom: None }
}

///|
pub fn[K, S] Object::null(cls : Class[K, S]) -> Object[K] {
  { id: 0, class_name: cls.name(), _phantom: None }
}

///|
pub fn[K] Object::id(self : Object[K]) -> Int {
  self.id
}

///|
pub fn[K] Object::class_name(self : Object[K]) -> Name {
  self.class_name
}

///|
pub fn[K] Object::is_null(self : Object[K]) -> Bool {
  self.id == 0
}

///|
pub fn[K, P] FactTable::new(slot : Slot[K, P]) -> FactTable[K, P] {
  { slot, facts: {}, _phantom: None }
}

///|
pub fn[K, P] FactTable::slot(self : FactTable[K, P]) -> Slot[K, P] {
  self.slot
}

///|
pub fn[K, P] FactTable::provide(
  self : FactTable[K, P],
  object : Object[K],
  value : P,
) -> Result[P, String] {
  if object.class_name() != self.slot.owner() {
    Err(
      "slot \{self.slot.name().show()} does not belong to class \{object.class_name().show()}",
    )
  } else if object.is_null() {
    match self.slot.domain().empty() {
      Some(empty) => Ok(empty)
      None => Ok(value)
    }
  } else {
    let domain = self.slot.domain()
    let next = match self.facts.get(object.id()) {
      Some(previous) => domain.join(previous, value)
      None => Ok(value)
    }
    match next {
      Ok(joined) => {
        self.facts[object.id()] = joined
        Ok(joined)
      }
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn[K, P] FactTable::collect(
  self : FactTable[K, P],
  object : Object[K],
) -> P? {
  if object.is_null() {
    return self.slot.domain().empty()
  }
  match self.facts.get(object.id()) {
    Some(value) => Some(value)
    None => self.slot.domain().empty()
  }
}

///|
pub fn[K, P] FactTable::has(self : FactTable[K, P], object : Object[K]) -> Bool {
  match self.collect(object) {
    Some(value) => !self.slot.domain().is_empty(value)
    None => false
  }
}

///|
pub fn[K, P] FactTable::require(
  self : FactTable[K, P],
  object : Object[K],
) -> Result[P, String] {
  match self.collect(object) {
    Some(value) if !self.slot.domain().is_empty(value) => Ok(value)
    _ =>
      Err(
        "required fact \{self.slot.name().show()} is empty for object \{object.id()}",
      )
  }
}
