///|
struct RuleDef {
  name_value : Name
  requires_value : Array[Name]
  parameters_value : Array[Array[String]]
}

///|
struct RuleDoc {
  name_value : Name
  provides_value : Name
  requires_value : Array[Name]
  parameters_value : Array[Array[String]]
}

///|
struct Rule {
  name_value : Name
  provides_value : Name
  requires_value : Array[Name]
  parameters_value : Array[Array[String]]
  comment_value : String
}

///|
struct Documentation {
  _unit : Unit
}

///|
let rule_registry : Map[String, Rule] = Map([])

///|
pub fn Documentation::new() -> Documentation {
  { _unit: (), }
}

///|
fn clone_string_groups(groups : Array[Array[String]]) -> Array[Array[String]] {
  groups.map(group => group.copy())
}

///|
pub fn Rule::create(name : String, pkg? : String) -> RuleDef {
  {
    name_value: Name::create(name, pkg?),
    requires_value: [],
    parameters_value: [],
  }
}

///|
pub fn Rule::registry() -> Array[Rule] {
  let rules = []
  rule_registry.each((_, rule) => rules.push(rule))
  rules.sort_by((left, right) => left.name().compare(right.name()))
  rules
}

///|
pub fn Rule::name(self : Rule) -> Name {
  self.name_value
}

///|
pub fn Rule::desc(self : Rule) -> String {
  self.comment_value
}

///|
pub fn Rule::provides(self : Rule) -> Name {
  self.provides_value
}

///|
pub fn Rule::requires(self : Rule) -> Array[Name] {
  self.requires_value.copy()
}

///|
pub fn Rule::parameters(self : Rule) -> Array[Array[String]] {
  clone_string_groups(self.parameters_value)
}

///|
pub fn RuleDef::dynamic(self : RuleDef, parameters : Array[String]) -> RuleDef {
  let next = clone_string_groups(self.parameters_value)
  next.push(parameters.copy())
  {
    ..self,
    requires_value: self.requires_value.copy(),
    parameters_value: next,
  }
}

///|
pub fn[K, P] RuleDef::require(self : RuleDef, slot : Slot[K, P]) -> RuleDef {
  let next = self.requires_value.copy()
  next.push(slot.name())
  {
    ..self,
    requires_value: next,
    parameters_value: clone_string_groups(self.parameters_value),
  }
}

///|
pub fn[K, P] RuleDef::provide(self : RuleDef, slot : Slot[K, P]) -> RuleDoc {
  {
    name_value: self.name_value,
    provides_value: slot.name(),
    requires_value: self.requires_value.copy(),
    parameters_value: clone_string_groups(self.parameters_value),
  }
}

///|
pub fn RuleDoc::comment(self : RuleDoc, comment : String) -> Unit {
  let rule = {
    name_value: self.name_value,
    provides_value: self.provides_value,
    requires_value: self.requires_value.copy(),
    parameters_value: clone_string_groups(self.parameters_value),
    comment_value: comment,
  }
  rule_registry[rule.name().show()] = rule
}

///|
pub fn Documentation::agents() -> Array[Agent] {
  Agent::registry()
}

///|
pub fn Documentation::rules() -> Array[Rule] {
  Rule::registry()
}
