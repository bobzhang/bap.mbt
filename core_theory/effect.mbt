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
  Effect::named("barr", EffectBoth)
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
pub fn Effect::cjump() -> Effect {
  Effect::named("cjump", EffectCtrl)
}
