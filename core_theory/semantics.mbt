///|
struct Semantics {
  effect_value : Effect
  value_value : Value
  code_value : Bytes?
}

///|
fn semantics_default_value() -> Value {
  Value::empty(Sym(@knowledge.Name::create("unit", pkg="core")))
}

///|
pub fn Semantics::empty() -> Semantics {
  {
    effect_value: Effect::empty(EffectTop),
    value_value: semantics_default_value(),
    code_value: None,
  }
}

///|
pub fn Semantics::create(
  effect? : Effect,
  value? : Value,
  code? : Bytes,
) -> Semantics {
  {
    effect_value: match effect {
      Some(item) => item
      None => Effect::empty(EffectTop)
    },
    value_value: match value {
      Some(item) => item
      None => semantics_default_value()
    },
    code_value: code,
  }
}

///|
pub fn Semantics::effect(self : Semantics) -> Effect {
  self.effect_value
}

///|
pub fn Semantics::value(self : Semantics) -> Value {
  self.value_value
}

///|
pub fn Semantics::code(self : Semantics) -> Bytes? {
  self.code_value
}

///|
pub fn Semantics::with_effect(self : Semantics, effect : Effect) -> Semantics {
  { ..self, effect_value: effect }
}

///|
pub fn Semantics::with_value(self : Semantics, value : Value) -> Semantics {
  { ..self, value_value: value }
}

///|
pub fn Semantics::with_code(self : Semantics, code : Bytes) -> Semantics {
  { ..self, code_value: Some(code) }
}

///|
fn semantics_hex_digit(value : Int) -> Char {
  if value < 10 {
    (value + '0').unsafe_to_char()
  } else {
    (value - 10 + 'a').unsafe_to_char()
  }
}

///|
fn semantics_bytes_hex(bytes : BytesView) -> String {
  let out = StringBuilder()
  for byte in bytes {
    let value = byte.to_int()
    out.write_char(semantics_hex_digit(value >> 4))
    out.write_char(semantics_hex_digit(value & 0x0f))
  }
  out.to_string()
}

///|
pub fn Semantics::code_hex(self : Semantics) -> String? {
  self.code_value.map(bytes => semantics_bytes_hex(bytes))
}

///|
fn effect_equal(lhs : Effect, rhs : Effect) -> Bool {
  lhs.sort_value == rhs.sort_value && lhs.name_value == rhs.name_value
}

///|
fn value_equal(lhs : Value, rhs : Value) -> Bool {
  lhs.sort_value == rhs.sort_value && string_map_equal(lhs.facts, rhs.facts)
}

///|
fn semantics_equal(lhs : Semantics, rhs : Semantics) -> Bool {
  effect_equal(lhs.effect_value, rhs.effect_value) &&
  value_equal(lhs.value_value, rhs.value_value) &&
  lhs.code_value == rhs.code_value
}

///|
fn semantics_is_empty(value : Semantics) -> Bool {
  semantics_equal(value, Semantics::empty())
}

///|
fn semantics_inspect(value : Semantics) -> String {
  let code = match value.code_hex() {
    Some(hex) => hex
    None => "none"
  }
  "semantics(effect=\{value.effect().to_string()}, code=\{code})"
}

///|
fn bytes_domain(name : String) -> @knowledge.Domain[Bytes] {
  @knowledge.Domain::new(
    name=core_name(name),
    empty=None,
    is_empty=(_ : Bytes) => false,
    order=(lhs : Bytes, rhs : Bytes) => {
      if lhs == rhs {
        Equal
      } else {
        Incomparable
      }
    },
    join=(lhs : Bytes, rhs : Bytes) => {
      if lhs == rhs {
        Ok(lhs)
      } else {
        Err("conflicting byte facts")
      }
    },
    inspect=(bytes : Bytes) => semantics_bytes_hex(bytes),
  )
}

///|
fn semantics_domain() -> @knowledge.Domain[Semantics] {
  @knowledge.Domain::new(
    name=core_name("semantics"),
    empty=Some(Semantics::empty()),
    is_empty=semantics_is_empty,
    order=(lhs : Semantics, rhs : Semantics) => {
      if semantics_equal(lhs, rhs) {
        Equal
      } else if semantics_is_empty(lhs) {
        Less
      } else if semantics_is_empty(rhs) {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Semantics, rhs : Semantics) => {
      if semantics_equal(lhs, rhs) || semantics_is_empty(rhs) {
        Ok(lhs)
      } else if semantics_is_empty(lhs) {
        Ok(rhs)
      } else {
        Err("conflicting program semantics")
      }
    },
    inspect=semantics_inspect,
  )
}
