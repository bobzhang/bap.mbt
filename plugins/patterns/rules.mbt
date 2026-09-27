///|
/// The size constraints of a `patternpairs` element: the minimal total
/// number of non-masked bits and in the postpattern part.
pub(all) struct Sizes {
  total : Int
  post : Int
} derive(Eq, Debug)

///|
pub extend Sizes with Eq::{not_equal, equal}

///|
pub extend Sizes with Debug::{to_repr}

///|
/// A parsed `pattern` or `patternpairs` element (upstream `Rule`).
pub(all) struct Rule {
  sizes : Sizes?
  prepatterns : Array[Pattern]
  postpatterns : Array[Pattern]
  actions : Array[Action]
}

///|
/// The rule without patterns and actions.
pub fn Rule::empty() -> Rule {
  { sizes: None, prepatterns: [], postpatterns: [], actions: [], }
}

///|
/// Merges several partial rules (upstream `Rule.collapse`).
pub fn Rule::collapse(matches : Array[Rule]) -> Rule {
  let r = Rule::empty()
  let mut sizes = None
  for m in matches {
    if sizes is None {
      sizes = m.sizes
    }
    r.prepatterns.append(m.prepatterns)
    r.postpatterns.append(m.postpatterns)
    r.actions.append(m.actions)
  }
  { ..r, sizes, }
}

///|
/// The printed representation (upstream `Rule.pp`).
pub fn Rule::to_string(self : Rule) -> String {
  let block = (name : String, xs : Array[String]) => {
    let buf = StringBuilder()
    buf.write_string("\{name} {")
    for x in xs {
      buf.write_string("\n  \{x}")
    }
    buf.write_string("\n}")
    buf.to_string()
  }
  [
    block("preps", self.prepatterns.map(p => p.to_string())),
    block("posts", self.postpatterns.map(p => p.to_string())),
    block("actions", self.actions.map(a => a.to_string())),
  ].join("\n")
}

///|
/// A case of the matcher: a pattern, the actions triggered when it matches
/// and the size of its prepattern part (the actions apply to the address
/// of the postpattern).
pub struct Case {
  pattern : Pattern
  actions : ActionSet
  shifted : Int
}

///|
/// The compiled rules (upstream `Rules.t`): all cases and all actions
/// that they can trigger.
pub struct Rules {
  priv cases : Array[Case]
  priv known : ActionSet
}

///|
/// No rules.
pub fn Rules::empty() -> Rules {
  { cases: [], known: ActionSet::empty(), }
}

///|
/// The cases of the matcher.
pub fn Rules::cases(self : Rules) -> Array[Case] {
  self.cases.copy()
}

///|
/// All actions that the rules may trigger.
pub fn Rules::known(self : Rules) -> ActionSet {
  self.known
}

///|
/// Concatenates the rules.
pub fn Rules::concat(self : Rules, other : Rules) -> Rules {
  { cases: self.cases + other.cases, known: self.known.union(other.known), }
}

///|
fn is_large_enough(sizes : Sizes?, pre : Pattern, post : Pattern) -> Bool {
  match sizes {
    None => true
    Some({ total, post: p, }) =>
      post.weight() >= p && post.weight() + pre.weight() >= total
  }
}

///|
/// Compiles the parsed rules (upstream `Rules.create`): every prepattern
/// is concatenated with every postpattern, keeping only the combinations
/// that satisfy the size constraints.
pub fn Rules::create(rules : ArrayView[Rule]) -> Rules {
  // cases are accumulated in the reverse order, as upstream conses them
  let rev : Array[Case] = []
  let mut known = ActionSet::empty()
  for r in rules {
    let pre = if r.prepatterns.is_empty() {
      [Pattern::empty()]
    } else {
      r.prepatterns
    }
    for p in pre {
      for q in r.postpatterns {
        if is_large_enough(r.sizes, p, q) {
          let actions = ActionSet::of_array(r.actions)
          known = known.union(actions)
          rev.push({ actions, pattern: p.concat(q), shifted: p.length(), })
        }
      }
    }
  }
  { cases: rev.rev(), known, }
}

///|
/// The printed representation (upstream `Rules.pp`).
pub fn Rules::to_string(self : Rules) -> String {
  self.cases
  .map(c => {
    "\{c.pattern} -> \{c.actions.to_array().map(a => a.to_string()).join(" ")}"
  })
  .join("\n")
}

///|
/// Searches the memory for the patterns (upstream `Rules.search`), calling
/// `f(addr, action, acc)` for every action of every matching case, where
/// `addr` is the address of the postpattern part.
///
/// Faithful to upstream: the patterns are tried at every address except
/// the last one of the memory; at each address the actions that were
/// already applied are not considered again; and the search stops
/// completely when a partial match reaches the end of the memory.
pub fn[X] Rules::search(
  self : Rules,
  mem : @memory.Memory,
  f : (UInt64, Action, X) -> X,
  init : X,
) -> X {
  let max_addr = mem.max_addr()
  let mut x = init
  let mut addr = mem.min_addr()
  while addr < max_addr {
    // the cases are kept in the order in which upstream keeps its list
    let mut cases = self.cases.rev()
    let mut known = self.known
    let mut pos = 0
    while !(known.is_empty() || cases.is_empty()) {
      let byte = match mem.get(addr=addr + pos.to_uint64()) {
        Err(_) => return x
        Ok(byte) => byte.to_int() catch { _ => return x }
      }
      let next : Array[Case] = []
      // upstream folds over its list, which is our array reversed
      for i = cases.length() - 1; i >= 0; i = i - 1 {
        let case = cases[i]
        let hits = case.pattern.matches(pos~, byte)
        if hits && case.pattern.length() == pos + 1 {
          let a = addr + case.shifted.to_uint64()
          for action in case.actions.to_array() {
            x = f(a, action, x)
          }
          known = known.diff(case.actions)
        } else if hits {
          next.push(case)
        }
      }
      // upstream conses the hits, so its next list is `next` reversed,
      // which is exactly how `cases` represents it
      cases = next
      pos += 1
    }
    addr = addr + 1
  }
  x
}
