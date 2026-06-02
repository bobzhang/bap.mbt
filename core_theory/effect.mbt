///|
pub(all) enum EffectSort {
  EffectBot
  EffectData
  EffectCtrl
  EffectBoth
  EffectSet(names~ : Array[String])
  EffectTop
} derive(Eq, Debug)

///|
struct Effect {
  sort_value : EffectSort
  name_value : String
}

///|
pub fn Effect::cls() -> @knowledge.Class[Unit, Unit] {
  @knowledge.Class::create(
    name=core_name("effect"),
    sort=(),
    desc="denotation of a result of effectful computation",
    public=true,
  )
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
pub fn EffectSort::data_named(name : String) -> EffectSort {
  effect_sort_single(name)
}

///|
pub fn EffectSort::ctrl_named(name : String) -> EffectSort {
  effect_sort_single(name)
}

///|
pub fn EffectSort::rreg() -> EffectSort {
  effect_sort_single("rreg")
}

///|
pub fn EffectSort::wreg() -> EffectSort {
  effect_sort_single("wreg")
}

///|
pub fn EffectSort::rmem() -> EffectSort {
  effect_sort_single("rmem")
}

///|
pub fn EffectSort::wmem() -> EffectSort {
  effect_sort_single("wmem")
}

///|
pub fn EffectSort::barr() -> EffectSort {
  effect_sort_single("barr")
}

///|
pub fn EffectSort::fall() -> EffectSort {
  effect_sort_single("fall")
}

///|
pub fn EffectSort::jump() -> EffectSort {
  effect_sort_single("jump")
}

///|
pub fn EffectSort::cjmp() -> EffectSort {
  effect_sort_single("cjmp")
}

///|
fn effect_sort_normalize_names(names : Array[String]) -> Array[String] {
  let result = []
  for name in names {
    if !result.contains(name) {
      result.push(name)
    }
  }
  result.sort_by((lhs, rhs) => lhs.compare(rhs))
  result
}

///|
fn effect_sort_from_names(names : Array[String]) -> EffectSort {
  let normalized = effect_sort_normalize_names(names)
  if normalized.length() == 0 {
    EffectBot
  } else if normalized.length() == 1 && normalized[0] == "data" {
    EffectData
  } else if normalized.length() == 1 && normalized[0] == "ctrl" {
    EffectCtrl
  } else if normalized.length() == 2 &&
    normalized[0] == "ctrl" &&
    normalized[1] == "data" {
    EffectBoth
  } else {
    EffectSet(names=normalized)
  }
}

///|
fn effect_sort_single(name : String) -> EffectSort {
  effect_sort_from_names([name])
}

///|
fn EffectSort::names(self : EffectSort) -> Array[String] {
  match self {
    EffectBot => []
    EffectData => ["data"]
    EffectCtrl => ["ctrl"]
    EffectBoth => ["ctrl", "data"]
    EffectSet(names~) => effect_sort_normalize_names(names)
    EffectTop => []
  }
}

///|
fn EffectSort::is_top(self : EffectSort) -> Bool {
  self is EffectTop
}

///|
fn EffectSort::normalized(self : EffectSort) -> EffectSort {
  match self {
    EffectTop => EffectTop
    _ => effect_sort_from_names(self.names())
  }
}

///|
pub fn EffectSort::both(self : EffectSort, other : EffectSort) -> EffectSort {
  self.union(other)
}

///|
pub fn EffectSort::union(self : EffectSort, other : EffectSort) -> EffectSort {
  if self.is_top() || other.is_top() {
    EffectTop
  } else {
    effect_sort_from_names(self.names() + other.names())
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
  if self.normalized() == other.normalized() {
    Equal
  } else if self is EffectBot || other is EffectTop {
    Less
  } else if other is EffectBot || self is EffectTop {
    Greater
  } else {
    let self_names = self.names()
    let other_names = other.names()
    let self_le_other = self_names.all(name => other_names.contains(name))
    let other_le_self = other_names.all(name => self_names.contains(name))
    if self_le_other && other_le_self {
      Equal
    } else if self_le_other {
      Less
    } else if other_le_self {
      Greater
    } else {
      Incomparable
    }
  }
}

///|
pub fn EffectSort::to_string(self : EffectSort) -> String {
  match self.normalized() {
    EffectBot => "bot"
    EffectData => "data"
    EffectCtrl => "ctrl"
    EffectBoth => "both"
    EffectSet(names~) => names.join("&")
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
    _ =>
      if input.contains("&") {
        Some(
          effect_sort_from_names(
            input.split("&").to_array().map(view => view.to_owned()),
          ),
        )
      } else {
        Some(effect_sort_single(input))
      }
  }
}

///|
pub fn EffectSort::persistent() -> @knowledge.Persistent[EffectSort] {
  let fields_codec = persistent_string_fields()
  @knowledge.Persistent::create(
    to_string=sort => {
      match sort.normalized() {
        EffectTop => fields_codec.encode(["top"])
        value => fields_codec.encode(["set"] + value.names())
      }
    },
    of_string=input => {
      match fields_codec.decode(input) {
        Ok(fields) =>
          match fields {
            ["top"] => Ok(EffectTop)
            ["set", .. names] => Ok(effect_sort_from_names(names.to_owned()))
            _ => Err("invalid persistent effect sort")
          }
        Err(_) =>
          match EffectSort::of_string(input) {
            Some(sort) => Ok(sort)
            None => Err("invalid persistent effect sort")
          }
      }
    },
  )
}

///|
fn EffectSort::rank(self : EffectSort) -> Int {
  match self.normalized() {
    EffectBot => 0
    EffectData | EffectCtrl | EffectBoth | EffectSet(_) => 1
    EffectTop => 2
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
  self.sort_value.normalized() == other.sort_value.normalized() &&
  self.name_value == other.name_value
}

///|
pub fn Effect::compare(self : Effect, other : Effect) -> Int {
  let sort_order = self.sort_value.rank().compare(other.sort_value.rank())
  if sort_order != 0 {
    return sort_order
  }
  let sort_text_order = self.sort_value
    .to_string()
    .compare(other.sort_value.to_string())
  if sort_text_order != 0 {
    return sort_text_order
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
pub fn Effect::domain() -> @knowledge.Domain[Effect] {
  let empty = Effect::empty(EffectTop)
  @knowledge.Domain::new(
    name=core_name("effect"),
    empty=Some(empty),
    is_empty=effect => effect.equal(empty),
    order=(lhs : Effect, rhs : Effect) => {
      if lhs.equal(rhs) {
        Equal
      } else if lhs.equal(empty) {
        Less
      } else if rhs.equal(empty) {
        Greater
      } else {
        Incomparable
      }
    },
    join=(lhs : Effect, rhs : Effect) => {
      if lhs.equal(rhs) || rhs.equal(empty) {
        Ok(lhs)
      } else if lhs.equal(empty) {
        Ok(rhs)
      } else {
        Err("conflicting effects")
      }
    },
    inspect=effect => effect.to_string(),
  )
}

///|
pub fn Effect::rreg() -> Effect {
  Effect::named("rreg", EffectSort::rreg())
}

///|
pub fn Effect::wreg() -> Effect {
  Effect::named("wreg", EffectSort::wreg())
}

///|
pub fn Effect::rmem() -> Effect {
  Effect::named("rmem", EffectSort::rmem())
}

///|
pub fn Effect::wmem() -> Effect {
  Effect::named("wmem", EffectSort::wmem())
}

///|
pub fn Effect::barr() -> Effect {
  Effect::named("barr", EffectSort::barr())
}

///|
pub fn Effect::fall() -> Effect {
  Effect::named("fall", EffectSort::fall())
}

///|
pub fn Effect::jump() -> Effect {
  Effect::named("jump", EffectSort::jump())
}

///|
pub fn Effect::cjmp() -> Effect {
  Effect::named("cjmp", EffectSort::cjmp())
}

///|
pub fn Effect::cjump() -> Effect {
  Effect::cjmp()
}
