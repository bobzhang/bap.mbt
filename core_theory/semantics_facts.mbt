///|
struct SemanticsFacts {
  state_value : @knowledge.State
  class_value : @knowledge.Class[Unit, EffectSort]
  value_value : @knowledge.FactTable[Unit, Value]
  code_value : @knowledge.FactTable[Unit, Bytes?]
}

///|
fn value_inspect(value : Value) -> String {
  value.sort().to_string()
}

///|
fn value_domain() -> @knowledge.Domain[Value] {
  let empty = semantics_default_value()
  @knowledge.Domain::new(
    name=core_name("semantics-value"),
    empty=Some(empty),
    is_empty=(value : Value) => value_equal(value, empty),
    order=(lhs : Value, rhs : Value) => {
      if value_equal(lhs, rhs) {
        Equal
      } else if value_equal(lhs, empty) {
        Less
      } else if value_equal(rhs, empty) {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Value, rhs : Value) => {
      if value_equal(lhs, rhs) || value_equal(rhs, empty) {
        Ok(lhs)
      } else if value_equal(lhs, empty) {
        Ok(rhs)
      } else {
        Err("conflicting semantics values")
      }
    },
    inspect=value_inspect,
  )
}

///|
fn semantics_code_domain() -> @knowledge.Domain[Bytes?] {
  @knowledge.Domain::optional(bytes_domain("insn-code"))
}

///|
pub fn SemanticsFacts::new() -> SemanticsFacts {
  let cls : @knowledge.Class[Unit, EffectSort] = @knowledge.Class::create(
    name=core_name("semantics"),
    sort=EffectTop,
    desc="program semantics values",
    public=true,
  )
  let value = cls.property(
    name=core_name("value"),
    domain=value_domain(),
    desc="the program semantics value",
    public=true,
  )
  let code = cls.property(
    name=core_name("insn-code"),
    domain=semantics_code_domain(),
    desc="the program memory contents",
    public=true,
  )
  {
    state_value: @knowledge.State::new(),
    class_value: cls,
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
    value=self.collect_value(object),
    code?=self.collect_code(object),
  )
}
