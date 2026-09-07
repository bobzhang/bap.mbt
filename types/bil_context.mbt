///|
struct BilContext {
  entries : Array[(Var, BilResult)]
} derive(Eq, Debug)

///|
pub extend BilContext with Eq::{not_equal, equal}

///|
pub extend BilContext with Debug::{to_repr}

///|
pub fn BilContext::new() -> BilContext {
  { entries: [], }
}

///|
fn bil_context_same_var(left : Var, right : Var) -> Bool {
  left.name() == right.name()
}

///|
pub fn BilContext::lookup(self : BilContext, variable : Var) -> BilResult? {
  for entry in self.entries {
    if bil_context_same_var(entry.0, variable) {
      return Some(entry.1)
    }
  }
  None
}

///|
pub fn BilContext::update(
  self : BilContext,
  variable : Var,
  result : BilResult,
) -> BilContext {
  let entries = self.entries.copy()
  for i in 0..<entries.length() {
    if bil_context_same_var(entries[i].0, variable) {
      entries[i] = (variable, result)
      return { entries, }
    }
  }
  entries.push((variable, result))
  { entries, }
}

///|
pub fn BilContext::bindings(self : BilContext) -> Array[(Var, BilResult)] {
  let entries = self.entries.copy()
  entries.sort_by((left, right) => left.0.name().compare(right.0.name()))
  entries
}
