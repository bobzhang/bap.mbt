///|
struct Object[K] {
  id : Int
  class_name : Name
  _phantom : K?
}

///|
struct State {
  mut next_id : Int
  mut current_pkg_value : String
  objects_by_class : Map[Name, Array[Int]]
  symbols_by_class : Map[Name, Map[Name, Int]]
}

///|
struct FactTable[K, P] {
  slot : Slot[K, P]
  facts : Map[Int, P]
  observers : Array[(Object[K], P) -> Result[Unit, String]]
  promises : Array[(Object[K]) -> Result[P, String]]
  _phantom : K?
}

///|
pub fn State::new() -> State {
  {
    next_id: 1,
    current_pkg_value: "user",
    objects_by_class: {},
    symbols_by_class: {},
  }
}

///|
fn[K, S] State::allocate(self : State, cls : Class[K, S]) -> Object[K] {
  let id = self.next_id
  self.next_id = id + 1
  let class_name = cls.name()
  match self.objects_by_class.get(class_name) {
    Some(ids) => ids.push(id)
    None => self.objects_by_class[class_name] = [id]
  }
  { id, class_name, _phantom: None }
}

///|
pub fn[K, S] State::create(self : State, cls : Class[K, S]) -> Object[K] {
  self.allocate(cls)
}

///|
fn State::forget_object(self : State, class_name : Name, id : Int) -> Unit {
  match self.objects_by_class.get(class_name) {
    Some(ids) => {
      let kept = []
      for current in ids {
        if current != id {
          kept.push(current)
        }
      }
      self.objects_by_class[class_name] = kept
    }
    None => ()
  }
}

///|
pub fn[K, S, R] State::scoped(
  self : State,
  cls : Class[K, S],
  body : (Object[K]) -> R,
) -> R {
  let object = self.allocate(cls)
  let result = body(object)
  self.forget_object(object.class_name(), object.id())
  result
}

///|
pub fn State::current_pkg(self : State) -> String {
  self.current_pkg_value
}

///|
pub fn State::set_current_pkg(self : State, pkg : String) -> Unit {
  self.current_pkg_value = pkg
}

///|
pub fn[R] State::with_pkg(self : State, pkg : String, body : () -> R) -> R {
  let previous = self.current_pkg_value
  self.current_pkg_value = pkg
  let result = body()
  self.current_pkg_value = previous
  result
}

///|
pub fn[K, S] State::intern(
  self : State,
  cls : Class[K, S],
  name~ : Name,
) -> Object[K] {
  let class_name = cls.name()
  match self.symbols_by_class.get(class_name) {
    Some(symbols) =>
      match symbols.get(name) {
        Some(id) => { id, class_name, _phantom: None }
        None => {
          let object = self.allocate(cls)
          symbols[name] = object.id()
          object
        }
      }
    None => {
      let object = self.allocate(cls)
      let symbols : Map[Name, Int] = {}
      symbols[name] = object.id()
      self.symbols_by_class[class_name] = symbols
      object
    }
  }
}

///|
pub fn[K, S] State::intern_named(
  self : State,
  cls : Class[K, S],
  name : String,
  pkg? : String,
) -> Object[K] {
  let pkg_name = match pkg {
    Some(value) => value
    None => self.current_pkg_value
  }
  self.intern(cls, name=Name::create(name, pkg=pkg_name))
}

///|
pub fn[K, S] State::read(
  self : State,
  cls : Class[K, S],
  input : String,
  pkg? : String,
) -> Result[Object[K], String] {
  if input == "nil" || input.has_prefix("#<") {
    Object::read(cls, input)
  } else {
    let pkg_name = match pkg {
      Some(value) => value
      None => self.current_pkg_value
    }
    Ok(self.intern(cls, name=Name::read(input, pkg=pkg_name)))
  }
}

///|
pub fn[K, S] State::objects(
  self : State,
  cls : Class[K, S],
) -> Array[Object[K]] {
  let class_name = cls.name()
  match self.objects_by_class.get(class_name) {
    Some(ids) => ids.map(id => { id, class_name, _phantom: None })
    None => []
  }
}

///|
pub fn[K] State::interned_name(self : State, object : Object[K]) -> Name? {
  match self.symbols_by_class.get(object.class_name()) {
    Some(symbols) => {
      for entry in symbols {
        if entry.1 == object.id() {
          return Some(entry.0)
        }
      }
      None
    }
    None => None
  }
}

///|
pub fn[K] State::repr(self : State, object : Object[K]) -> String {
  match self.interned_name(object) {
    Some(name) =>
      if name.pkg() == self.current_pkg_value {
        name.unqualified()
      } else {
        name.show()
      }
    None => object.repr()
  }
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
fn object_read_id(input : String) -> Result[Int, String] {
  if !(input.has_prefix("#<") && input.has_suffix(">")) {
    return Err("invalid object representation: \{input}")
  }
  let inner = input[2:input.length() - 1]
  let mut split = -1
  for i, ch in inner {
    if ch == ' ' {
      split = i
    }
  }
  if split < 0 || split + 1 >= inner.length() {
    return Err("invalid object representation: \{input}")
  }
  try @string.parse_int(inner[split + 1:]) catch {
    _ => Err("invalid object representation: \{input}")
  } noraise {
    id if id >= 0 => Ok(id)
    _ => Err("invalid object representation: \{input}")
  }
}

///|
pub fn[K] Object::equal(self : Object[K], other : Object[K]) -> Bool {
  self.id == other.id && self.class_name == other.class_name
}

///|
pub fn[K] Object::compare(self : Object[K], other : Object[K]) -> Int {
  let class_order = self.class_name.compare(other.class_name)
  if class_order != 0 {
    class_order
  } else {
    self.id.compare(other.id)
  }
}

///|
pub fn[K] Object::repr(self : Object[K]) -> String {
  if self.is_null() {
    "nil"
  } else {
    "#<\{self.class_name.show()} \{self.id}>"
  }
}

///|
pub fn[K, S] Object::read(
  cls : Class[K, S],
  input : String,
) -> Result[Object[K], String] {
  if input == "nil" {
    Ok(Object::null(cls))
  } else {
    match object_read_id(input) {
      Ok(id) => Ok({ id, class_name: cls.name(), _phantom: None })
      Err(reason) => Err(reason)
    }
  }
}

///|
pub fn[K, P] FactTable::new(slot : Slot[K, P]) -> FactTable[K, P] {
  { slot, facts: {}, observers: [], promises: [], _phantom: None }
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
  } else if object.is_null() || self.slot.domain().is_empty(value) {
    match self.slot.domain().empty() {
      Some(empty) =>
        match self.collect(object) {
          Some(current) => Ok(current)
          None => Ok(empty)
        }
      None =>
        match self.collect(object) {
          Some(current) => Ok(current)
          None => Ok(value)
        }
    }
  } else {
    let domain = self.slot.domain()
    let next = match self.facts.get(object.id()) {
      Some(previous) => domain.join(previous, value)
      None =>
        match domain.empty() {
          Some(empty) => domain.join(empty, value)
          None => Ok(value)
        }
    }
    match next {
      Ok(joined) => {
        self.facts[object.id()] = joined
        match self.notify(object, joined) {
          Ok(_) => Ok(joined)
          Err(reason) => Err(reason)
        }
      }
      Err(reason) => Err(reason)
    }
  }
}

///|
fn[K, P] FactTable::notify(
  self : FactTable[K, P],
  object : Object[K],
  value : P,
) -> Result[Unit, String] {
  for observer in self.observers {
    match observer(object, value) {
      Ok(_) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok(())
}

///|
pub fn[K, P] FactTable::observe(
  self : FactTable[K, P],
  observer : (Object[K], P) -> Result[Unit, String],
) -> Unit {
  self.observers.push(observer)
}

///|
pub fn[K, P, R] FactTable::observing(
  self : FactTable[K, P],
  observer : (Object[K], P) -> Result[Unit, String],
  body : () -> R,
) -> R {
  let index = self.observers.length()
  self.observers.push(observer)
  let result = body()
  ignore(self.observers.remove(index))
  result
}

///|
pub fn[K, P] FactTable::observer_count(self : FactTable[K, P]) -> Int {
  self.observers.length()
}

///|
pub fn[K, P] FactTable::promise(
  self : FactTable[K, P],
  provider : (Object[K]) -> Result[P, String],
) -> Unit {
  self.promises.push(provider)
}

///|
pub fn[K, P, R] FactTable::promising(
  self : FactTable[K, P],
  provider : (Object[K]) -> Result[P, String],
  body : () -> R,
) -> R {
  let index = self.promises.length()
  self.promises.push(provider)
  let result = body()
  ignore(self.promises.remove(index))
  result
}

///|
pub fn[K, P] FactTable::promise_count(self : FactTable[K, P]) -> Int {
  self.promises.length()
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
pub fn[K, P] FactTable::collect_promised(
  self : FactTable[K, P],
  object : Object[K],
) -> Result[P?, String] {
  if object.is_null() {
    return Ok(self.collect(object))
  }
  if object.class_name() != self.slot.owner() {
    return Err(
      "slot \{self.slot.name().show()} does not belong to class \{object.class_name().show()}",
    )
  }
  match self.collect(object) {
    Some(value) if !self.slot.domain().is_empty(value) => Ok(Some(value))
    _ => {
      for provider in self.promises {
        match provider(object) {
          Ok(value) if self.slot.domain().is_empty(value) => ()
          Ok(value) =>
            match self.provide(object, value) {
              Ok(_) => ()
              Err(reason) => return Err(reason)
            }
          Err(reason) => return Err(reason)
        }
      }
      Ok(self.collect(object))
    }
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
  match self.collect_promised(object) {
    Ok(Some(value)) if !self.slot.domain().is_empty(value) => Ok(value)
    Ok(_) =>
      Err(
        "required fact \{self.slot.name().show()} is empty for object \{object.id()}",
      )
    Err(reason) => Err(reason)
  }
}

///|
pub fn[K, P] FactTable::require_cached(
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

///|
pub fn[K, P] FactTable::suggest(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  object : Object[K],
  value : P,
) -> Result[Opinions[P], String] {
  match self.collect(object) {
    Some(opinions) => self.provide(object, opinions.add(agent, value))
    None =>
      Err(
        "opinion fact \{self.slot.name().show()} has no empty value for object \{object.id()}",
      )
  }
}

///|
fn[K, P] FactTable::proposal(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  provider : (Object[K]) -> Result[P, String],
) -> (Object[K]) -> Result[Opinions[P], String] {
  object => {
    match self.collect(object) {
      Some(opinions) =>
        match provider(object) {
          Ok(value) => Ok(opinions.add(agent, value))
          Err(reason) => Err(reason)
        }
      None =>
        Err(
          "opinion fact \{self.slot.name().show()} has no empty value for object \{object.id()}",
        )
    }
  }
}

///|
pub fn[K, P] FactTable::propose(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  provider : (Object[K]) -> Result[P, String],
) -> Unit {
  self.promise(self.proposal(agent, provider))
}

///|
pub fn[K, P, R] FactTable::proposing(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  provider : (Object[K]) -> Result[P, String],
  body : () -> R,
) -> R {
  self.promising(self.proposal(agent, provider), body)
}

///|
pub fn[K, P] FactTable::resolve(
  self : FactTable[K, Opinions[P]],
  object : Object[K],
) -> Result[P, String] {
  match self.collect_promised(object) {
    Ok(Some(opinions)) => Ok(opinions.choice())
    Ok(None) =>
      Err(
        "opinion fact \{self.slot.name().show()} has no empty value for object \{object.id()}",
      )
    Err(reason) => Err(reason)
  }
}
