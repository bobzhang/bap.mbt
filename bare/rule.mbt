///|
priv struct BareRuleState {
  patterns : Array[BareTerm]
  template : Array[BareFact]
  bindings : Map[String, BareTerm]
}

///|
struct Rule {
  rule_value : BareRuleState
  work_value : Array[BareRuleState]
}

///|
fn bare_is_variable(atom : String) -> Bool {
  match atom.get_char(0) {
    Some('?') => true
    _ => false
  }
}

///|
fn bare_collect_vars(term : BareTerm, vars : Map[String, Bool]) -> Unit {
  match term {
    BareAtom(atom) => if bare_is_variable(atom) { vars[atom] = true }
    BareList(items) =>
      for item in items {
        bare_collect_vars(item, vars)
      }
  }
}

///|
fn bare_collect_free_vars(terms : Array[BareTerm]) -> Map[String, Bool] {
  let vars : Map[String, Bool] = {}
  for term in terms {
    bare_collect_vars(term, vars)
  }
  vars
}

///|
fn bare_check_rule(
  lhs : Array[BareTerm],
  rhs : Array[BareTerm],
) -> Result[Unit, BareError] {
  let defined = bare_collect_free_vars(lhs)
  let used = bare_collect_free_vars(rhs)
  if used.contains("?") {
    return Err(BareWildcard)
  }
  let mut missing : String? = None
  used.each(fn(name, _) {
    if !defined.contains(name) {
      match missing {
        None => missing = Some(name)
        Some(best) => if name.compare(best) < 0 { missing = Some(name) }
      }
    }
  })
  match missing {
    Some(name) => Err(BareUnbound(name))
    None => Ok(())
  }
}

///|
fn bare_rule_of_pair(
  patterns : Array[BareTerm],
  template : Array[BareTerm],
) -> Result[Rule, BareError] {
  match bare_check_rule(patterns, template) {
    Err(reason) => Err(reason)
    Ok(_) => {
      let state = {
        patterns: patterns.copy(),
        template: template.copy(),
        bindings: {},
      }
      Ok({ rule_value: state, work_value: [state] })
    }
  }
}

///|
fn bare_rule_of_term(term : BareTerm) -> Result[Rule, BareError] {
  match term {
    BareAtom(_) => Err(bare_parse_error(0, "expected rule pair"))
    BareList(items) =>
      if items.length() != 2 {
        Err(bare_parse_error(0, "expected rule pair"))
      } else {
        match (items[0], items[1]) {
          (BareList(patterns), BareList(template)) =>
            bare_rule_of_pair(patterns, template)
          (BareAtom(_), _) | (_, BareAtom(_)) =>
            Err(bare_parse_error(0, "rule sides must be lists"))
        }
      }
  }
}

///|
pub fn Rule::of_string(text : String) -> Result[Rule, BareError] {
  match BareTerm::parse(text) {
    Ok(term) => bare_rule_of_term(term)
    Err(reason) => Err(reason)
  }
}

///|
pub fn Rule::from_string(text : String) -> Result[Array[Rule], BareError] {
  match BareTerm::parse_many(text) {
    Ok(terms) => {
      let rules = []
      for term in terms {
        match bare_rule_of_term(term) {
          Ok(rule) => rules.push(rule)
          Err(reason) => return Err(reason)
        }
      }
      Ok(rules)
    }
    Err(reason) => Err(reason)
  }
}

///|
pub fn Rule::from_file(path : String) -> Result[Array[Rule], BareError] {
  match @native_io.read_file(path) {
    Ok(data) => {
      let text = try @utf8.decode(data) catch {
        _ => return Err(BareNotASexp("BARE specification is not valid UTF-8"))
      } noraise {
        value => value
      }
      Rule::from_string(text)
    }
    Err(reason) => Err(BareNotASexp(reason))
  }
}

///|
pub fn Rule::lhs(self : Rule) -> Array[BareTuple] {
  self.rule_value.patterns.copy()
}

///|
pub fn Rule::patterns(self : Rule) -> Array[BareTuple] {
  self.lhs()
}

///|
pub fn Rule::rhs(self : Rule) -> Array[BareFact] {
  self.rule_value.template.copy()
}

///|
pub fn Rule::reset(self : Rule) -> Rule {
  { rule_value: self.rule_value, work_value: [self.rule_value] }
}

///|
pub fn Rule::spec(self : Rule) -> String {
  "(\{BareList(self.rule_value.patterns).to_string()} \{BareList(self.rule_value.template).to_string()})"
}

///|
fn bare_empty_bindings() -> Map[String, BareTerm] {
  {}
}

///|
fn bare_binding(name : String, value : BareTerm) -> Map[String, BareTerm] {
  let bindings = bare_empty_bindings()
  bindings[name] = value
  bindings
}

///|
fn bare_merge_bindings(
  base : Map[String, BareTerm],
  extra : Map[String, BareTerm],
) -> Map[String, BareTerm]? {
  let result = base.copy()
  let mut valid = true
  extra.each(fn(name, value) {
    if valid {
      match result.get(name) {
        Some(previous) => if previous != value { valid = false }
        None => result[name] = value
      }
    }
  })
  if valid {
    Some(result)
  } else {
    None
  }
}

///|
fn bare_term_bindings(
  pattern : BareTerm,
  fact : BareTerm,
) -> Map[String, BareTerm]? {
  match (pattern, fact) {
    (BareAtom(lhs), BareAtom(rhs)) if lhs == rhs => Some(bare_empty_bindings())
    (BareAtom("?"), _) => Some(bare_empty_bindings())
    (BareAtom(name), term) if bare_is_variable(name) =>
      Some(bare_binding(name, term))
    (BareList(lhs), BareList(rhs)) => bare_list_bindings(lhs, rhs)
    _ => None
  }
}

///|
fn bare_list_bindings(
  patterns : Array[BareTerm],
  facts : Array[BareTerm],
) -> Map[String, BareTerm]? {
  if patterns.length() != facts.length() {
    None
  } else {
    let result = bare_empty_bindings()
    let mut valid = true
    for i in 0..<patterns.length() {
      if valid {
        match bare_term_bindings(patterns[i], facts[i]) {
          Some(bindings) =>
            match bare_merge_bindings(result, bindings) {
              Some(merged) => {
                result.clear()
                merged.each(fn(name, value) { result[name] = value })
              }
              None => valid = false
            }
          None => valid = false
        }
      }
    }
    if valid {
      Some(result)
    } else {
      None
    }
  }
}

///|
fn bare_apply_bindings(
  bindings : Map[String, BareTerm],
  term : BareTerm,
) -> BareTerm {
  match term {
    BareList(items) =>
      BareList([ for item in items => bare_apply_bindings(bindings, item) ])
    BareAtom(name) if bare_is_variable(name) =>
      match bindings.get(name) {
        Some(value) => value
        None => BareAtom(name)
      }
    BareAtom(_) => term
  }
}

///|
fn bare_apply_template(state : BareRuleState) -> Array[BareFact] {
  [
    for term in state.template => bare_apply_bindings(state.bindings, term)
  ]
}

///|
fn bare_match_state(fact : BareFact, state : BareRuleState) -> BareRuleState? {
  for i in 0..<state.patterns.length() {
    match bare_term_bindings(state.patterns[i], fact) {
      Some(bindings) =>
        match bare_merge_bindings(state.bindings, bindings) {
          Some(merged) => {
            let remaining = state.patterns.copy()
            ignore(remaining.remove(i))
            return Some({
              patterns: remaining,
              template: state.template,
              bindings: merged,
            })
          }
          None => ()
        }
      None => ()
    }
  }
  None
}

///|
pub fn Rule::apply(self : Rule, fact : BareFact) -> (Rule, Array[BareFact]) {
  let work = self.work_value.copy()
  let acts = []
  for state in self.work_value {
    match bare_match_state(fact, state) {
      Some(matched) =>
        if matched.patterns.length() == 0 {
          for output in bare_apply_template(matched) {
            acts.insert(0, output)
          }
        } else {
          work.insert(0, matched)
        }
      None => ()
    }
  }
  ({ rule_value: self.rule_value, work_value: work }, acts)
}
