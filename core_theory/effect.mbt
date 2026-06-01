///|
pub(all) enum EffectSort {
  EffectBot
  EffectData
  EffectCtrl
  EffectBoth
  EffectTop
} derive(Eq, Debug)

///|
struct Effect {
  sort_value : EffectSort
  name_value : String
}

///|
pub fn EffectSort::bot() -> EffectSort {
  EffectBot
}

///|
pub fn EffectSort::top() -> EffectSort {
  EffectTop
}

///|
pub fn EffectSort::data() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::ctrl() -> EffectSort {
  EffectCtrl
}

///|
pub fn EffectSort::rreg() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::wreg() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::rmem() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::wmem() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::barr() -> EffectSort {
  EffectData
}

///|
pub fn EffectSort::fall() -> EffectSort {
  EffectCtrl
}

///|
pub fn EffectSort::jump() -> EffectSort {
  EffectCtrl
}

///|
pub fn EffectSort::cjmp() -> EffectSort {
  EffectCtrl
}

///|
pub fn EffectSort::both(self : EffectSort, other : EffectSort) -> EffectSort {
  self.union(other)
}

///|
pub fn EffectSort::union(self : EffectSort, other : EffectSort) -> EffectSort {
  match (self, other) {
    (EffectTop, _) | (_, EffectTop) => EffectTop
    (EffectBot, value) | (value, EffectBot) => value
    (EffectData, EffectData) => EffectData
    (EffectCtrl, EffectCtrl) => EffectCtrl
    (EffectBoth, _) | (_, EffectBoth) => EffectBoth
    (EffectData, EffectCtrl) | (EffectCtrl, EffectData) => EffectBoth
  }
}

///|
pub fn EffectSort::union_all(items : Array[EffectSort]) -> EffectSort {
  let mut result = EffectBot
  for item in items {
    result = result.union(item)
  }
  result
}

///|
pub fn EffectSort::join(
  lhs : Array[EffectSort],
  rhs : Array[EffectSort],
) -> EffectSort {
  EffectSort::union_all(lhs).union(EffectSort::union_all(rhs))
}

///|
pub fn EffectSort::order(
  self : EffectSort,
  other : EffectSort,
) -> @knowledge.PartialOrder {
  if self == other {
    Equal
  } else if self == EffectBot || other == EffectTop {
    Less
  } else if other == EffectBot || self == EffectTop {
    Greater
  } else if other == EffectBoth && (self == EffectData || self == EffectCtrl) {
    Less
  } else if self == EffectBoth && (other == EffectData || other == EffectCtrl) {
    Greater
  } else {
    Incomparable
  }
}

///|
pub fn EffectSort::to_string(self : EffectSort) -> String {
  match self {
    EffectBot => "bot"
    EffectData => "data"
    EffectCtrl => "ctrl"
    EffectBoth => "both"
    EffectTop => "top"
  }
}

///|
fn EffectSort::of_string(input : String) -> EffectSort? {
  match input {
    "bot" => Some(EffectBot)
    "data" => Some(EffectData)
    "ctrl" => Some(EffectCtrl)
    "both" => Some(EffectBoth)
    "top" => Some(EffectTop)
    _ => None
  }
}

///|
pub fn EffectSort::persistent() -> @knowledge.Persistent[EffectSort] {
  @knowledge.Persistent::convert(
    to_persistent=sort => sort.to_string(),
    of_persistent=input => {
      match EffectSort::of_string(input) {
        Some(sort) => Ok(sort)
        None => Err("invalid persistent effect sort")
      }
    },
    @knowledge.Persistent::string(),
  )
}

///|
fn EffectSort::rank(self : EffectSort) -> Int {
  match self {
    EffectBot => 0
    EffectData => 1
    EffectCtrl => 2
    EffectBoth => 3
    EffectTop => 4
  }
}

///|
pub fn Effect::empty(sort : EffectSort) -> Effect {
  { sort_value: sort, name_value: sort.to_string() }
}

///|
pub fn Effect::named(name : String, sort : EffectSort) -> Effect {
  { sort_value: sort, name_value: name }
}

///|
pub fn Effect::sort(self : Effect) -> EffectSort {
  self.sort_value
}

///|
pub fn Effect::name(self : Effect) -> String {
  self.name_value
}

///|
pub fn Effect::to_string(self : Effect) -> String {
  self.name_value
}

///|
pub fn Effect::equal(self : Effect, other : Effect) -> Bool {
  self.sort_value == other.sort_value && self.name_value == other.name_value
}

///|
pub fn Effect::compare(self : Effect, other : Effect) -> Int {
  let sort_order = self.sort_value.rank().compare(other.sort_value.rank())
  if sort_order != 0 {
    return sort_order
  }
  self.name_value.compare(other.name_value)
}

///|
pub fn Effect::persistent() -> @knowledge.Persistent[Effect] {
  let sort_codec = EffectSort::persistent()
  @knowledge.Persistent::convert(
    to_persistent=effect => [sort_codec.encode(effect.sort()), effect.name()],
    of_persistent=fields => {
      match persistent_decode_fields(fields, 2, "effect") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let sort = match sort_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Effect::named(fields[1], sort))
    },
    persistent_string_fields(),
  )
}

///|
pub fn Effect::rreg() -> Effect {
  Effect::named("rreg", EffectData)
}

///|
pub fn Effect::wreg() -> Effect {
  Effect::named("wreg", EffectData)
}

///|
pub fn Effect::rmem() -> Effect {
  Effect::named("rmem", EffectData)
}

///|
pub fn Effect::wmem() -> Effect {
  Effect::named("wmem", EffectData)
}

///|
pub fn Effect::barr() -> Effect {
  Effect::named("barr", EffectData)
}

///|
pub fn Effect::fall() -> Effect {
  Effect::named("fall", EffectCtrl)
}

///|
pub fn Effect::jump() -> Effect {
  Effect::named("jump", EffectCtrl)
}

///|
pub fn Effect::cjmp() -> Effect {
  Effect::named("cjmp", EffectCtrl)
}

///|
pub fn Effect::cjump() -> Effect {
  Effect::cjmp()
}
