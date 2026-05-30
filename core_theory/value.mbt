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
pub fn Value::forget(self : Value) -> Value {
  {
    sort_value: Sym(@knowledge.Name::create("unit", pkg="core")),
    facts: self.facts.copy(),
  }
}
