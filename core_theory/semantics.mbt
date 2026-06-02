///|
struct Semantics {
  effect_value : Effect
  value_value : Value
  code_value : Bytes?
}

///|
fn semantics_default_value() -> Value {
  Value::empty(Sort::top())
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
pub fn Semantics::cls() -> @knowledge.Class[Unit, EffectSort] {
  @knowledge.Class::create(
    name=core_name("semantics"),
    sort=EffectTop,
    desc="program semantics values",
    public=true,
  )
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
pub fn Semantics::persistent() -> @knowledge.Persistent[Semantics] {
  let effect_codec = Effect::persistent()
  let value_codec = Value::persistent()
  let code_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::bytes(),
  )
  @knowledge.Persistent::convert(
    to_persistent=semantics => {
      [
        effect_codec.encode(semantics.effect()),
        value_codec.encode(semantics.value()),
        code_codec.encode(semantics.code()),
      ]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 3, "semantics") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let effect = match effect_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let value = match value_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let code = match code_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Semantics::create(effect~, value~, code?))
    },
    persistent_string_fields(),
  )
}

///|
fn effect_equal(lhs : Effect, rhs : Effect) -> Bool {
  lhs.equal(rhs)
}

///|
fn value_equal(lhs : Value, rhs : Value) -> Bool {
  lhs.equal(rhs)
}

///|
fn semantics_equal(lhs : Semantics, rhs : Semantics) -> Bool {
  effect_equal(lhs.effect_value, rhs.effect_value) &&
  value_equal(lhs.value_value, rhs.value_value) &&
  lhs.code_value == rhs.code_value
}

///|
pub fn Semantics::equal(self : Semantics, other : Semantics) -> Bool {
  semantics_equal(self, other)
}

///|
fn optional_bytes_compare(lhs : Bytes?, rhs : Bytes?) -> Int {
  match (lhs, rhs) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left), Some(right)) => bytes_compare(left, right)
  }
}

///|
fn bytes_compare(lhs : BytesView, rhs : BytesView) -> Int {
  let limit = if lhs.length() < rhs.length() {
    lhs.length()
  } else {
    rhs.length()
  }
  for i in 0..<limit {
    let order = lhs[i].to_int().compare(rhs[i].to_int())
    if order != 0 {
      return order
    }
  }
  lhs.length().compare(rhs.length())
}

///|
pub fn Semantics::compare(self : Semantics, other : Semantics) -> Int {
  let effect_order = self.effect_value.compare(other.effect_value)
  if effect_order != 0 {
    return effect_order
  }
  let value_order = self.value_value.compare(other.value_value)
  if value_order != 0 {
    return value_order
  }
  optional_bytes_compare(self.code_value, other.code_value)
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

///|
pub fn Semantics::domain() -> @knowledge.Domain[Semantics] {
  semantics_domain()
}
