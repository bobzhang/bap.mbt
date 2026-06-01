///|
struct Value {
  sort_value : Sort
  facts : Map[String, String]
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
  {
    sort_value: Sym(@knowledge.Name::create("unit", pkg="core")),
    facts: self.facts.copy(),
  }
}
