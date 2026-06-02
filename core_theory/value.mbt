///|
struct Value {
  sort_value : Sort
  facts : Map[String, String]
}

///|
pub fn Value::cls() -> @knowledge.Class[Unit, Unit] {
  @knowledge.Class::create(
    name=core_name("value"),
    sort=(),
    desc="the denotation of an expression",
    public=true,
  )
}

///|
pub fn Value::empty(sort : Sort) -> Value {
  { sort_value: sort, facts: {} }
}

///|
pub fn Value::sort(self : Value) -> Sort {
  self.sort_value
}

///|
pub fn Value::resort(self : Value, refine : (Sort) -> Sort?) -> Value? {
  match refine(self.sort_value.forget()) {
    Some(sort) => Some({ sort_value: sort, facts: self.facts.copy() })
    None => None
  }
}

///|
pub fn[A] Value::match_can(
  self : Value,
  refine : (Sort) -> Sort?,
  action : (Value) -> A,
  otherwise : () -> A,
) -> A {
  match self.resort(refine) {
    Some(value) => action(value)
    None => otherwise()
  }
}

///|
pub fn[A] Value::can(
  self : Value,
  refine : (Sort) -> Sort?,
  action : (Value) -> A,
  otherwise : () -> A,
) -> A {
  self.match_can(refine, action, otherwise)
}

///|
pub fn[A] Value::match_both(
  self : Value,
  refine_self : (Sort) -> Sort?,
  other : Value,
  refine_other : (Sort) -> Sort?,
  action : (Value, Value) -> A,
  otherwise : () -> A,
) -> A {
  match (self.resort(refine_self), other.resort(refine_other)) {
    (Some(lhs), Some(rhs)) => action(lhs, rhs)
    _ => otherwise()
  }
}

///|
pub fn[A] Value::both(
  self : Value,
  refine_self : (Sort) -> Sort?,
  other : Value,
  refine_other : (Sort) -> Sort?,
  action : (Value, Value) -> A,
  otherwise : () -> A,
) -> A {
  self.match_both(refine_self, other, refine_other, action, otherwise)
}

///|
pub fn Value::equal(self : Value, other : Value) -> Bool {
  self.sort_value == other.sort_value &&
  string_map_equal(self.facts, other.facts)
}

///|
pub fn Value::compare(self : Value, other : Value) -> Int {
  let sort_order = self.sort_value
    .to_string()
    .compare(other.sort_value.to_string())
  if sort_order != 0 {
    return sort_order
  }
  string_map_compare(self.facts, other.facts)
}

///|
fn string_map_subset(
  lhs : Map[String, String],
  rhs : Map[String, String],
) -> Bool {
  for entry in lhs {
    if rhs.get(entry.0) != Some(entry.1) {
      return false
    }
  }
  true
}

///|
fn value_join_facts(
  lhs : Value,
  rhs : Value,
) -> Result[Map[String, String], String] {
  if lhs.sort_value != rhs.sort_value {
    return Err("conflicting value sorts")
  }
  let facts = lhs.facts.copy()
  for entry in rhs.facts {
    match facts.get(entry.0) {
      Some(value) if value != entry.1 => return Err("conflicting value facts")
      _ => facts[entry.0] = entry.1
    }
  }
  Ok(facts)
}

///|
fn value_inspect(value : Value) -> String {
  value.sort().to_string()
}

///|
pub fn Value::domain() -> @knowledge.Domain[Value] {
  let empty = Value::empty(Sort::top())
  @knowledge.Domain::new(
    name=core_name("value"),
    empty=Some(empty),
    is_empty=value => value.equal(empty),
    order=(lhs, rhs) => {
      if lhs.equal(rhs) {
        Equal
      } else if lhs.equal(empty) {
        Less
      } else if rhs.equal(empty) {
        Greater
      } else if lhs.sort_value == rhs.sort_value {
        let lhs_subset = string_map_subset(lhs.facts, rhs.facts)
        let rhs_subset = string_map_subset(rhs.facts, lhs.facts)
        if lhs_subset && rhs_subset {
          Equal
        } else if lhs_subset {
          Less
        } else if rhs_subset {
          Greater
        } else {
          Incomparable
        }
      } else {
        Incomparable
      }
    },
    join=(lhs, rhs) => {
      if lhs.equal(empty) {
        Ok(rhs)
      } else if rhs.equal(empty) {
        Ok(lhs)
      } else {
        match value_join_facts(lhs, rhs) {
          Ok(facts) => Ok({ sort_value: lhs.sort_value, facts })
          Err(reason) => Err(reason)
        }
      }
    },
    inspect=value_inspect,
  )
}

///|
pub fn Value::with_fact(self : Value, key : String, value : String) -> Value {
  let facts = self.facts.copy()
  facts[key] = value
  { sort_value: self.sort_value, facts }
}

///|
pub fn Value::fact(self : Value, key : String) -> String? {
  self.facts.get(key)
}

///|
pub fn Value::persistent() -> @knowledge.Persistent[Value] {
  let string_codec = @knowledge.Persistent::string()
  let facts_codec = @knowledge.Persistent::map(string_codec, string_codec)
  let sort_codec = Sort::persistent()
  @knowledge.Persistent::convert(
    to_persistent=value => {
      [sort_codec.encode(value.sort()), facts_codec.encode(value.facts)]
    },
    of_persistent=fields => {
      match persistent_decode_fields(fields, 2, "value") {
        Ok(_) => ()
        Err(reason) => return Err(reason)
      }
      let sort = match sort_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let facts = match facts_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok({ sort_value: sort, facts })
    },
    persistent_string_fields(),
  )
}

///|
pub fn Value::forget(self : Value) -> Value {
  { sort_value: self.sort_value.forget(), facts: self.facts.copy() }
}
