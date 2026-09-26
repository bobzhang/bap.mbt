///|
/// The semantics of a program (`Theory.Semantics.t`).
///
/// Upstream the semantics is an effect refined to the top effect sort: a
/// knowledge value of the `core:effect` class. It shares all properties of
/// the effect class (e.g., the BIL statements), plus the `value` of the
/// program (for expressions) and the `insn-code` (the program memory
/// contents). The whole semantics is itself a property of programs
/// (`Semantics::slot`), so that different lifters and theories can provide
/// different properties of the same semantics, which are joined.
struct Semantics(@knowledge.Value[EffectCls, EffectSort])

///|
let semantics_cls : @knowledge.Class[EffectCls, EffectSort] = Effect::sorted_cls(
  EffectTop,
)

///|
/// `Semantics.cls`: the effect class refined to the top sort.
pub fn Semantics::cls() -> @knowledge.Class[EffectCls, EffectSort] {
  semantics_cls
}

///|
/// The empty semantics.
pub fn Semantics::empty() -> Semantics {
  Semantics(@knowledge.Value::empty(semantics_cls))
}

///|
/// Views an effect as a program semantics (refining its sort to top).
pub fn Semantics::of_effect(effect : Effect) -> Semantics {
  Semantics(effect.kb().refine(EffectTop))
}

///|
/// The semantics viewed as an effect (of the top sort).
pub fn Semantics::effect(self : Semantics) -> Effect {
  Effect::of_kb(self.0)
}

///|
/// Wraps a knowledge value of the semantics class.
pub fn Semantics::of_kb(
  value : @knowledge.Value[EffectCls, EffectSort],
) -> Semantics {
  Semantics(value.refine(EffectTop))
}

///|
/// The underlying knowledge value.
pub fn Semantics::kb(
  self : Semantics,
) -> @knowledge.Value[EffectCls, EffectSort] {
  self.0
}

///|
/// Creates a semantics from the properties of `effect`, with the `value`
/// and `code` properties set.
pub fn Semantics::create(
  effect? : Effect,
  value? : Value,
  code? : Bytes,
) -> Semantics {
  let base = match effect {
    Some(effect) => Semantics::of_effect(effect)
    None => Semantics::empty()
  }
  let base = match value {
    Some(value) => base.with_value(value)
    None => base
  }
  match code {
    Some(code) => base.with_code(code)
    None => base
  }
}

///|
/// `KB.Value.get p s`.
pub fn[P] Semantics::get(
  self : Semantics,
  slot : @knowledge.Slot[EffectCls, P],
) -> P {
  self.0.get(slot)
}

///|
/// The property `p` of the semantics, if it was set.
pub fn[P] Semantics::find(
  self : Semantics,
  slot : @knowledge.Slot[EffectCls, P],
) -> P? {
  self.0.find(slot)
}

///|
/// `KB.Value.put p s x`.
pub fn[P] Semantics::put(
  self : Semantics,
  slot : @knowledge.Slot[EffectCls, P],
  value : P,
) -> Semantics {
  Semantics(self.0.put(slot, value))
}

///|
/// `KB.Value.has p s`.
pub fn[P] Semantics::has(
  self : Semantics,
  slot : @knowledge.Slot[EffectCls, P],
) -> Bool {
  self.0.has(slot)
}

///|
/// All properties of the semantics are empty.
pub fn Semantics::is_empty(self : Semantics) -> Bool {
  self.0.is_empty()
}

///|
/// `Semantics.value`: the value of the program (for expressions).
pub fn Semantics::value(self : Semantics) -> Value {
  self.0.get(semantics_value_slot)
}

///|
/// `Semantics.code`: the program memory contents, if known.
pub fn Semantics::code(self : Semantics) -> Bytes? {
  self.0.get(semantics_code_slot)
}

///|
/// Merges the properties of `effect` into the semantics (the properties
/// of `effect` win on conflicts).
pub fn Semantics::with_effect(self : Semantics, effect : Effect) -> Semantics {
  Semantics(self.0.merge(effect.kb().refine(EffectTop), on_conflict=DropLeft))
}

///|
/// Sets the `value` property.
pub fn Semantics::with_value(self : Semantics, value : Value) -> Semantics {
  self.put(semantics_value_slot, value)
}

///|
/// Sets the `insn-code` property.
pub fn Semantics::with_code(self : Semantics, code : Bytes) -> Semantics {
  self.put(semantics_code_slot, Some(code))
}

///|
/// Joins the properties of two semantics.
pub fn Semantics::join(
  self : Semantics,
  other : Semantics,
) -> Semantics raise @knowledge.Conflict {
  Semantics(self.0.join(other.0))
}

///|
/// Merges the properties of two semantics (the newer property wins on a
/// conflict by default).
pub fn Semantics::merge(
  self : Semantics,
  other : Semantics,
  on_conflict? : @knowledge.MergeStrategy = DropOld,
) -> Semantics {
  Semantics(self.0.merge(other.0, on_conflict~))
}

///|
/// Orders semantics by their information content.
pub fn Semantics::order(
  self : Semantics,
  other : Semantics,
) -> @knowledge.PartialOrder {
  self.0.order(other.0)
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
/// The program memory contents as a hexadecimal string.
pub fn Semantics::code_hex(self : Semantics) -> String? {
  self.code().map(bytes => semantics_bytes_hex(bytes))
}

///|
/// Semantics with equal properties are equal.
pub fn Semantics::equal(self : Semantics, other : Semantics) -> Bool {
  self.0.equal(other.0)
}

///|
/// A total order on semantics (by information, then by age).
pub fn Semantics::compare(self : Semantics, other : Semantics) -> Int {
  self.0.compare(other.0)
}

///|
/// Renders all properties of the semantics.
pub fn Semantics::to_string(self : Semantics) -> String {
  self.0.inspect()
}

///|
/// Renders only the named properties (`KB.Value.pp_slots`).
pub fn Semantics::inspect_slots(
  self : Semantics,
  slots : Array[String],
) -> String {
  self.0.inspect_slots(slots)
}

///|
let semantics_domain : @knowledge.Domain[Semantics] = {
  let empty = Semantics::empty()
  @knowledge.Domain::new(
    name=core_name("semantics"),
    empty=Some(empty),
    is_empty=semantics => semantics.is_empty(),
    order=(lhs, rhs) => lhs.order(rhs),
    join=(lhs, rhs) => {
      try lhs.join(rhs) catch {
        error => Err(@knowledge.Conflict::to_string(error))
      } noraise {
        semantics => Ok(semantics)
      }
    },
    inspect=semantics => semantics.to_string(),
  )
}

///|
/// The domain of semantics (`Semantics.domain`).
pub fn Semantics::domain() -> @knowledge.Domain[Semantics] {
  semantics_domain
}

///|
let semantics_persistent : @knowledge.Persistent[Semantics] = @knowledge.Persistent::convert(
  to_persistent=(semantics : Semantics) => semantics.0,
  of_persistent=value => Ok(Semantics(value)),
  @knowledge.Value::persistent(semantics_cls),
)

///|
/// Persists the persistent properties of a semantics.
pub fn Semantics::persistent() -> @knowledge.Persistent[Semantics] {
  semantics_persistent
}

///|
let bytes_domain : @knowledge.Domain[Bytes] = @knowledge.Domain::new(
  name=core_name("insn-code"),
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

///|
let semantics_code_slot : @knowledge.Slot[EffectCls, Bytes?] = semantics_cls.property(
  name=core_name("insn-code"),
  domain=@knowledge.Domain::optional(bytes_domain),
  desc="the program memory contents",
  persistent=@knowledge.Persistent::optional(@knowledge.Persistent::bytes()),
  public=true,
)

///|
let semantics_value_slot : @knowledge.Slot[EffectCls, Value] = semantics_cls.property(
  name=core_name("value"),
  domain=Value::domain(),
  desc="the program semantics",
  persistent=Value::persistent(),
  public=true,
)

///|
let program_semantics_slot : @knowledge.Slot[Unit, Semantics] = Program::cls().property(
  name=core_name("semantics"),
  domain=Semantics::domain(),
  desc="the program semantics",
  persistent=Semantics::persistent(),
  public=true,
)

///|
/// `Semantics.slot`: the semantics of a program.
pub fn Semantics::slot() -> @knowledge.Slot[Unit, Semantics] {
  program_semantics_slot
}

///|
/// `Semantics.value`: the value property of a semantics.
pub fn Semantics::value_slot() -> @knowledge.Slot[EffectCls, Value] {
  semantics_value_slot
}

///|
/// `Semantics.code`: the program memory contents.
pub fn Semantics::code_slot() -> @knowledge.Slot[EffectCls, Bytes?] {
  semantics_code_slot
}
