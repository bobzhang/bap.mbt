///|
/// A view of one slot of a knowledge base (port-specific convenience).
///
/// A fact table does not store anything itself: facts live in the
/// knowledge base `State` and rules (promises and observers) are
/// registered on the `Slot`, as upstream. The table offers a
/// `Result[_, String]`-based interface where every update is a
/// transaction: a diverging operation leaves the knowledge base unchanged.
struct FactTable[K, P] {
  slot : Slot[K, P]
  state : State
}

///|
/// A view of `slot` in `state` (defaults to a fresh, private knowledge
/// base).
pub fn[K, P] FactTable::new(
  slot : Slot[K, P],
  state? : State = State::new(),
) -> FactTable[K, P] {
  { slot, state, }
}

///|
pub fn[K, P] FactTable::slot(self : FactTable[K, P]) -> Slot[K, P] {
  self.slot
}

///|
/// The knowledge base of the table.
pub fn[K, P] FactTable::state(self : FactTable[K, P]) -> State {
  self.state
}

///|
fn[K, P] FactTable::owner_error(
  self : FactTable[K, P],
  object : Object[K],
) -> String? {
  if object.class_name() != self.slot.owner() {
    Some(
      "slot \{self.slot.name().show()} does not belong to class \{object.class_name().show()}",
    )
  } else {
    None
  }
}

///|
/// `Knowledge.provide` as a transaction; returns the value of the
/// property after the update (the joined value).
pub fn[K, P] FactTable::provide(
  self : FactTable[K, P],
  object : Object[K],
  value : P,
) -> Result[P, String] {
  if self.owner_error(object) is Some(reason) {
    return Err(reason)
  }
  match
    self.state.transaction(() => self.state.provide(self.slot, object, value)) {
    Ok(_) =>
      match self.state.current_opt(self.slot, object) {
        Some(current) => Ok(current)
        None => Ok(value)
      }
    Err(err) => Err(Conflict::to_string(err))
  }
}

///|
/// The value currently stored in the property (upstream `current`),
/// without running any promises; the empty value of the domain (or `None`
/// if the domain has no bottom) when nothing is stored. Use
/// `collect_promised` for upstream `collect`.
pub fn[K, P] FactTable::collect(
  self : FactTable[K, P],
  object : Object[K],
) -> P? {
  if object.is_null() {
    return self.slot.domain().empty()
  }
  self.state.current_opt(self.slot, object)
}

///|
/// `Knowledge.collect` (the least fixed point of all promises) as a
/// transaction. `Ok(None)` if nothing is known and the domain has no
/// bottom.
pub fn[K, P] FactTable::collect_promised(
  self : FactTable[K, P],
  object : Object[K],
) -> Result[P?, String] {
  if self.owner_error(object) is Some(reason) {
    return Err(reason)
  }
  match self.state.transaction(() => self.state.collect(self.slot, object)) {
    Ok(value) => Ok(Some(value))
    Err(Empty(_)) => Ok(None)
    Err(err) => Err(Conflict::to_string(err))
  }
}

///|
/// `true` if the stored value is not empty.
pub fn[K, P] FactTable::has(self : FactTable[K, P], object : Object[K]) -> Bool {
  match self.collect(object) {
    Some(value) => !self.slot.domain().is_empty(value)
    None => false
  }
}

///|
/// `Knowledge.require`: collects (running promises) and fails if empty.
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
/// Like `require` but only consults the stored value.
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
fn[K, P] legacy_provider(
  provider : (Object[K]) -> Result[P, String],
) -> (State, Object[K]) -> P raise {
  (_, object) => {
    match provider(object) {
      Ok(value) => value
      Err(reason) => raise Failure(reason)
    }
  }
}

///|
fn[K, P] legacy_observer(
  observer : (Object[K], P) -> Result[Unit, String],
) -> (State, Object[K], P) -> Unit raise {
  (_, object, value) => {
    match observer(object, value) {
      Ok(_) => ()
      Err(reason) => raise Failure(reason)
    }
  }
}

///|
/// `Knowledge.observe` on the table slot (observers are registered on the
/// slot and apply to every knowledge base).
pub fn[K, P] FactTable::observe(
  self : FactTable[K, P],
  observer : (Object[K], P) -> Result[Unit, String],
) -> Unit {
  ignore(self.slot.observe(legacy_observer(observer)))
}

///|
/// `Knowledge.observing` on the table slot.
pub fn[K, P, R] FactTable::observing(
  self : FactTable[K, P],
  observer : (Object[K], P) -> Result[Unit, String],
  body : () -> R,
) -> R {
  self.slot.observing(observe=legacy_observer(observer), body)
}

///|
pub fn[K, P] FactTable::observer_count(self : FactTable[K, P]) -> Int {
  self.slot.observer_count()
}

///|
/// `Knowledge.promise` on the table slot (promises are registered on the
/// slot and apply to every knowledge base). A provider error diverges the
/// collection with that message.
pub fn[K, P] FactTable::promise(
  self : FactTable[K, P],
  provider : (Object[K]) -> Result[P, String],
) -> Unit {
  ignore(self.slot.promise(legacy_provider(provider)))
}

///|
/// `Knowledge.promising` on the table slot.
pub fn[K, P, R] FactTable::promising(
  self : FactTable[K, P],
  provider : (Object[K]) -> Result[P, String],
  body : () -> R,
) -> R {
  self.slot.promising(promise=legacy_provider(provider), body)
}

///|
pub fn[K, P] FactTable::promise_count(self : FactTable[K, P]) -> Int {
  self.slot.promise_count()
}

///|
/// `Knowledge.suggest` as a transaction; returns the resulting opinions.
pub fn[K, P] FactTable::suggest(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  object : Object[K],
  value : P,
) -> Result[Opinions[P], String] {
  if self.owner_error(object) is Some(reason) {
    return Err(reason)
  }
  let result = self.state.transaction(() => {
    self.state.suggest(agent, self.slot, object, value)
    self.state.current(self.slot, object)
  })
  match result {
    Ok(opinions) => Ok(opinions)
    Err(err) => Err(Conflict::to_string(err))
  }
}

///|
/// `Knowledge.propose` on the table slot.
pub fn[K, P] FactTable::propose(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  provider : (Object[K]) -> Result[P, String],
) -> Unit {
  ignore(self.slot.propose(agent, legacy_provider(provider)))
}

///|
/// `Knowledge.proposing` on the table slot.
pub fn[K, P, R] FactTable::proposing(
  self : FactTable[K, Opinions[P]],
  agent : Agent,
  provider : (Object[K]) -> Result[P, String],
  body : () -> R,
) -> R {
  self.slot.proposing(agent, propose=legacy_provider(provider), body)
}

///|
/// `Knowledge.resolve` as a transaction.
pub fn[K, P] FactTable::resolve(
  self : FactTable[K, Opinions[P]],
  object : Object[K],
) -> Result[P, String] {
  if self.owner_error(object) is Some(reason) {
    return Err(reason)
  }
  match self.state.transaction(() => self.state.resolve(self.slot, object)) {
    Ok(value) => Ok(value)
    Err(err) => Err(Conflict::to_string(err))
  }
}
