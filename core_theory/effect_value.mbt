///|
/// The phantom kind of the class of effects (`Effect.cls`), which is also
/// the class of program semantics (`Semantics.cls`).
pub enum EffectCls {}

///|
/// A denotation of an effectful computation (`Theory.Effect.t`).
///
/// An effect is a knowledge value of the class `core:effect` refined by
/// the effect sort: an extensible record of the properties of the effect
/// class (e.g., the BIL statements of the effect), which different
/// theories provide independently.
struct Effect(@knowledge.Value[EffectCls, EffectSort])

///|
let effect_cls : @knowledge.Class[EffectCls, Unit] = @knowledge.Class::create(
  name=core_name("effect"),
  sort=(),
  desc="denotation of a result of effectful computation",
  public=true,
)

///|
/// `Effect.cls`: the class of all effects.
pub fn Effect::cls() -> @knowledge.Class[EffectCls, Unit] {
  effect_cls
}

///|
/// The class of effects of the given sort.
pub fn Effect::sorted_cls(
  sort : EffectSort,
) -> @knowledge.Class[EffectCls, EffectSort] {
  effect_cls.refine(sort~)
}

///|
/// Wraps a knowledge value of the effect class.
pub fn Effect::of_kb(value : @knowledge.Value[EffectCls, EffectSort]) -> Effect {
  Effect(value)
}

///|
/// The underlying knowledge value.
pub fn Effect::kb(self : Effect) -> @knowledge.Value[EffectCls, EffectSort] {
  self.0
}

///|
/// `Effect.empty s`: the effect of sort `s` with no properties.
pub fn Effect::empty(sort : EffectSort) -> Effect {
  Effect(@knowledge.Value::empty(Effect::sorted_cls(sort)))
}

///|
/// `Effect.sort e`: the sort of the effect.
pub fn Effect::sort(self : Effect) -> EffectSort {
  self.0.cls().sort()
}

///|
/// The same effect with the sort changed to `sort` (`KB.Value.refine`).
pub fn Effect::refine(self : Effect, sort : EffectSort) -> Effect {
  Effect(self.0.refine(sort))
}

///|
/// `KB.Value.get p e`.
pub fn[P] Effect::get(self : Effect, slot : @knowledge.Slot[EffectCls, P]) -> P {
  self.0.get(slot)
}

///|
/// The property `p` of the effect, if it was set.
pub fn[P] Effect::find(
  self : Effect,
  slot : @knowledge.Slot[EffectCls, P],
) -> P? {
  self.0.find(slot)
}

///|
/// `KB.Value.put p e x`.
pub fn[P] Effect::put(
  self : Effect,
  slot : @knowledge.Slot[EffectCls, P],
  value : P,
) -> Effect {
  Effect(self.0.put(slot, value))
}

///|
/// `KB.Value.has p e`.
pub fn[P] Effect::has(
  self : Effect,
  slot : @knowledge.Slot[EffectCls, P],
) -> Bool {
  self.0.has(slot)
}

///|
/// All properties of the effect are empty.
pub fn Effect::is_empty(self : Effect) -> Bool {
  self.0.is_empty()
}

///|
/// Joins the properties of two effects, keeping the sort of `self`.
pub fn Effect::join(
  self : Effect,
  other : Effect,
) -> Effect raise @knowledge.Conflict {
  Effect(self.0.join(other.0))
}

///|
/// Merges the properties of two effects (the newer property wins on a
/// conflict by default), keeping the sort of `self`.
pub fn Effect::merge(
  self : Effect,
  other : Effect,
  on_conflict~ : @knowledge.MergeStrategy = DropOld,
) -> Effect {
  Effect(self.0.merge(other.0, on_conflict~))
}

///|
/// Orders effects by their information content.
pub fn Effect::order(self : Effect, other : Effect) -> @knowledge.PartialOrder {
  self.0.order(other.0)
}

///|
/// Effects are equal if they have equal sorts and properties.
pub fn Effect::equal(self : Effect, other : Effect) -> Bool {
  self.sort().normalized() == other.sort().normalized() && self.0.equal(other.0)
}

///|
/// A total order: by sort, then by the knowledge value order.
pub fn Effect::compare(self : Effect, other : Effect) -> Int32 {
  let order = self.sort().rank().compare(other.sort().rank())
  if order != 0 {
    return order
  }
  let order = self.sort().to_string().compare(other.sort().to_string())
  if order != 0 {
    order
  } else {
    self.0.compare(other.0)
  }
}

///|
/// Renders the sort and the properties of the effect.
pub fn Effect::to_string(self : Effect) -> String {
  if self.0.is_empty() {
    self.sort().to_string()
  } else {
    "\{self.sort().to_string()}:\{self.0.inspect()}"
  }
}

///|
/// The domain of effects (`Knowledge.Value.derive` of the effect class):
/// the empty effect is the bottom and effects join property-wise. The
/// joined effect keeps the sort of the left operand unless it is the top
/// sort.
let effect_domain : @knowledge.Domain[Effect] = {
  let empty = Effect::empty(EffectTop)
  @knowledge.Domain::new(
    name=core_name("effect"),
    empty=Some(empty),
    is_empty=effect => effect.is_empty(),
    order=(lhs, rhs) => lhs.order(rhs),
    join=(lhs, rhs) => {
      let lhs = if lhs.sort().is_top() && !rhs.sort().is_top() {
        lhs.refine(rhs.sort())
      } else {
        lhs
      }
      try lhs.join(rhs) catch {
        error => Err(@knowledge.Conflict::to_string(error))
      } noraise {
        effect => Ok(effect)
      }
    },
    inspect=effect => effect.to_string(),
  )
}

///|
/// The domain of effects.
pub fn Effect::domain() -> @knowledge.Domain[Effect] {
  effect_domain
}

///|
let effect_persistent : @knowledge.Persistent[Effect] = {
  let sort_codec = EffectSort::persistent()
  let data_codec = @knowledge.Value::persistent(
    Effect::sorted_cls(EffectSort::top()),
  )
  @knowledge.Persistent::convert(
    to_persistent=effect => {
      [sort_codec.encode(effect.sort()), data_codec.encode(effect.0)]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 2, "effect") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let sort = match sort_codec.decode(fields[0]) {
        Ok(sort) => sort
        Err(reason) => return Err(reason)
      }
      match data_codec.decode(fields[1]) {
        Ok(data) => Ok(Effect(data.refine(sort)))
        Err(reason) => Err(reason)
      }
    },
    persistent_string_fields(),
  )
}

///|
/// Persists the sort and the persistent properties of an effect.
pub fn Effect::persistent() -> @knowledge.Persistent[Effect] {
  effect_persistent
}

///|
/// The empty effect of the `rreg` sort.
pub fn Effect::rreg() -> Effect {
  Effect::empty(EffectSort::rreg())
}

///|
/// The empty effect of the `wreg` sort.
pub fn Effect::wreg() -> Effect {
  Effect::empty(EffectSort::wreg())
}

///|
/// The empty effect of the `rmem` sort.
pub fn Effect::rmem() -> Effect {
  Effect::empty(EffectSort::rmem())
}

///|
/// The empty effect of the `wmem` sort.
pub fn Effect::wmem() -> Effect {
  Effect::empty(EffectSort::wmem())
}

///|
/// The empty effect of the `barr` sort.
pub fn Effect::barr() -> Effect {
  Effect::empty(EffectSort::barr())
}

///|
/// The empty effect of the `fall` sort.
pub fn Effect::fall() -> Effect {
  Effect::empty(EffectSort::fall())
}

///|
/// The empty effect of the `jump` sort.
pub fn Effect::jump() -> Effect {
  Effect::empty(EffectSort::jump())
}

///|
/// The empty effect of the `cjmp` sort.
pub fn Effect::cjmp() -> Effect {
  Effect::empty(EffectSort::cjmp())
}

///|
/// Alias of `Effect::cjmp`.
pub fn Effect::cjump() -> Effect {
  Effect::cjmp()
}
