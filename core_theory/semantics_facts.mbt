///|
struct SemanticsFacts {
  state_value : @knowledge.State
  class_value : @knowledge.Class[Unit, EffectSort]
  effect_value : @knowledge.FactTable[Unit, Effect]
  value_value : @knowledge.FactTable[Unit, Value]
  code_value : @knowledge.FactTable[Unit, Bytes?]
}

///|
fn semantics_effect_domain() -> @knowledge.Domain[Effect] {
  @knowledge.Domain::new(
    name=core_name("semantics-effect"),
    empty=Some(Effect::empty(EffectTop)),
    is_empty=effect => effect.equal(Effect::empty(EffectTop)),
    order=(lhs : Effect, rhs : Effect) => {
      if lhs.equal(rhs) {
        Equal
      } else if lhs.equal(Effect::empty(EffectTop)) {
        Less
      } else if rhs.equal(Effect::empty(EffectTop)) {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Effect, rhs : Effect) => {
      if lhs.equal(rhs) || rhs.equal(Effect::empty(EffectTop)) {
        Ok(lhs)
      } else if lhs.equal(Effect::empty(EffectTop)) {
        Ok(rhs)
      } else {
        Err("conflicting program semantics effects")
      }
    },
    inspect=effect => effect.to_string(),
  )
}

///|
fn semantics_code_domain() -> @knowledge.Domain[Bytes?] {
  @knowledge.Domain::optional(bytes_domain("insn-code"))
}

///|
pub fn Semantics::slot() -> @knowledge.Slot[Unit, Semantics] {
  Program::cls().property(
    name=core_name("semantics"),
    domain=semantics_domain(),
    desc="the program semantics",
    persistent=Semantics::persistent(),
    public=true,
  )
}

///|
pub fn Semantics::value_slot() -> @knowledge.Slot[Unit, Value] {
  Semantics::cls().property(
    name=core_name("value"),
    domain=Value::domain(),
    desc="the program semantics value",
    persistent=Value::persistent(),
    public=true,
  )
}

///|
pub fn Semantics::effect_slot() -> @knowledge.Slot[Unit, Effect] {
  Semantics::cls().property(
    name=core_name("effect"),
    domain=semantics_effect_domain(),
    desc="the program semantics effect",
    persistent=Effect::persistent(),
    public=true,
  )
}

///|
pub fn Semantics::code_slot() -> @knowledge.Slot[Unit, Bytes?] {
  Semantics::cls().property(
    name=core_name("insn-code"),
    domain=semantics_code_domain(),
    desc="the program memory contents",
    persistent=@knowledge.Persistent::optional(@knowledge.Persistent::bytes()),
    public=true,
  )
}

///|
pub fn SemanticsFacts::new() -> SemanticsFacts {
  let cls = Semantics::cls()
  let effect = Semantics::effect_slot()
  let value = Semantics::value_slot()
  let code = Semantics::code_slot()
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
    effect_value: @knowledge.FactTable::new(effect),
    value_value: @knowledge.FactTable::new(value),
    code_value: @knowledge.FactTable::new(code),
  }
}

///|
pub fn SemanticsFacts::class(
  self : SemanticsFacts,
) -> @knowledge.Class[Unit, EffectSort] {
  self.class_value
}

///|
pub fn SemanticsFacts::create(self : SemanticsFacts) -> @knowledge.Object[Unit] {
  self.state_value.create(self.class_value)
}

///|
pub fn SemanticsFacts::value(
  self : SemanticsFacts,
) -> @knowledge.FactTable[Unit, Value] {
  self.value_value
}

///|
pub fn SemanticsFacts::effect(
  self : SemanticsFacts,
) -> @knowledge.FactTable[Unit, Effect] {
  self.effect_value
}

///|
pub fn SemanticsFacts::code(
  self : SemanticsFacts,
) -> @knowledge.FactTable[Unit, Bytes?] {
  self.code_value
}

///|
pub fn SemanticsFacts::provide_semantics(
  self : SemanticsFacts,
  object : @knowledge.Object[Unit],
  semantics : Semantics,
) -> Result[Unit, String] {
  match self.effect_value.provide(object, semantics.effect()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.value_value.provide(object, semantics.value()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match self.code_value.provide(object, semantics.code()) {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  Ok(())
}

///|
pub fn SemanticsFacts::for_semantics(
  self : SemanticsFacts,
  semantics : Semantics,
) -> Result[@knowledge.Object[Unit], String] {
  let object = self.create()
  match self.provide_semantics(object, semantics) {
    Ok(_) => Ok(object)
    Err(reason) => Err(reason)
  }
}

///|
pub fn SemanticsFacts::collect_effect(
  self : SemanticsFacts,
  object : @knowledge.Object[Unit],
) -> Effect {
  match self.effect_value.collect(object) {
    Some(effect) => effect
    None => Effect::empty(EffectTop)
  }
}

///|
pub fn SemanticsFacts::collect_value(
  self : SemanticsFacts,
  object : @knowledge.Object[Unit],
) -> Value {
  match self.value_value.collect(object) {
    Some(value) => value
    None => semantics_default_value()
  }
}

///|
pub fn SemanticsFacts::collect_code(
  self : SemanticsFacts,
  object : @knowledge.Object[Unit],
) -> Bytes? {
  match self.code_value.collect(object) {
    Some(code) => code
    None => None
  }
}

///|
pub fn SemanticsFacts::collect_semantics(
  self : SemanticsFacts,
  object : @knowledge.Object[Unit],
) -> Semantics {
  Semantics::create(
    effect=self.collect_effect(object),
    value=self.collect_value(object),
    code?=self.collect_code(object),
  )
}
