///|
/// A semantic action (upstream `Action`): any element of a pattern other
/// than `data`. The element name becomes the action name (in the `bap`
/// package unless the element is in a namespace) and its attributes the
/// action arguments (keywords unless in a namespace).
pub struct Action {
  priv name_ : @knowledge.Name
  priv args_ : Array[(@knowledge.Name, String)]
}

///|
/// The host of a URI (`scheme://[userinfo@]host[:port]/...`), if any.
fn uri_host(uri : String) -> String? {
  match uri.find("://") {
    None => None
    Some(i) => {
      let rest = uri.unsafe_substring(start=i + 3, end=uri.length())
      let mut end = rest.length()
      for j in 0..<rest.length() {
        if rest[j] is ('/' | '?' | '#') {
          end = j
          break
        }
      }
      let auth = rest.unsafe_substring(start=0, end~)
      let auth = match auth.rev_find("@") {
        Some(k) => auth.unsafe_substring(start=k + 1, end=auth.length())
        None => auth
      }
      let host = match auth.rev_find(":") {
        Some(k) if !auth.has_prefix("[") ||
          (auth.rev_find("]") is Some(b) && b < k) =>
          auth.unsafe_substring(start=0, end=k)
        _ => auth
      }
      Some(host)
    }
  }
}

///|
/// Translates an XML name into a knowledge name (upstream `xml_name`).
fn xml_name(name : @xml.Name, default : String) -> @knowledge.Name {
  if name.uri == "" {
    @knowledge.Name::create(name.local_name, pkg=default)
  } else {
    match uri_host(name.uri) {
      None | Some("") => @knowledge.Name::create(name.local_name, pkg=name.uri)
      Some(host) => @knowledge.Name::create(name.local_name, pkg=host)
    }
  }
}

///|
fn args_compare(
  a : Array[(@knowledge.Name, String)],
  b : Array[(@knowledge.Name, String)],
) -> Int32 {
  let n = @cmp.minimum(a.length(), b.length())
  for i in 0..<n {
    let c = a[i].0.compare(b[i].0)
    if c != 0 {
      return c
    }
    let c = a[i].1.compare(b[i].1)
    if c != 0 {
      return c
    }
  }
  a.length().compare(b.length())
}

///|
/// Creates an action from a start tag (upstream `Action.of_tag`).
pub fn Action::of_tag(tag : @xml.Tag) -> Action {
  let args : Array[(@knowledge.Name, String)] = []
  for a in tag.attrs {
    let k = xml_name(a.name, "keyword")
    match args.search_by(x => x.0 == k) {
      Some(i) => args[i] = (k, a.value)
      None => args.push((k, a.value))
    }
  }
  args.sort_by((x, y) => x.0.compare(y.0))
  { name_: xml_name(tag.name, "bap"), args_: args, }
}

///|
/// Creates an action from its name and arguments.
pub fn Action::create(
  name : @knowledge.Name,
  args~ : Array[(@knowledge.Name, String)] = [],
) -> Action {
  let args = args.copy()
  args.sort_by((x, y) => x.0.compare(y.0))
  { name_: name, args_: args, }
}

///|
/// The name of the action.
pub fn Action::name(self : Action) -> @knowledge.Name {
  self.name_
}

///|
/// The arguments of the action (ordered by name).
pub fn Action::args(self : Action) -> Array[(@knowledge.Name, String)] {
  self.args_.copy()
}

///|
/// The value of the argument, looked up by its name as it is read by
/// upstream's `patterns-attribute` primitive (a plain `after` is the
/// keyword `:after`).
pub fn Action::attribute(self : Action, name : String) -> String? {
  let key = @knowledge.Name::read(name, pkg="keyword")
  for a in self.args_ {
    if a.0 == key {
      return Some(a.1)
    }
  }
  None
}

///|
/// The total order on actions: by names, then by arguments.
pub fn Action::compare(self : Action, other : Action) -> Int32 {
  let c = self.name_.compare(other.name_)
  if c != 0 {
    c
  } else {
    args_compare(self.args_, other.args_)
  }
}

///|
pub impl Eq for Action with fn equal(self, other) {
  self.compare(other) == 0
}

///|
pub extend Action with Eq::{not_equal, equal}

///|
/// OCaml's `%S`: a quoted and escaped string.
fn quoted(s : String) -> String {
  "\"" + ocaml_escaped(s) + "\""
}

///|
/// `(name)` or `(name arg "value" ...)` (upstream `Action.pp`).
pub fn Action::to_string(self : Action) -> String {
  if self.args_.is_empty() {
    "(\{self.name_.show()})"
  } else {
    let args = self.args_.map(a => "\{a.0.show()} \{quoted(a.1)}")
    "(\{self.name_.show()} \{args.join(" ")})"
  }
}

///|
pub impl Show for Action with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend Action with Show::{output}

///|
pub impl Debug for Action with fn to_repr(self) {
  @debug.Repr(self.to_string())
}

///|
pub extend Action with Debug::{to_repr}

///|
/// A set of actions, ordered by `Action::compare`.
pub struct ActionSet {
  priv items : Array[Action]
}

///|
/// The empty set.
pub fn ActionSet::empty() -> ActionSet {
  { items: [], }
}

///|
/// The set of the given actions.
pub fn ActionSet::of_array(xs : ArrayView[Action]) -> ActionSet {
  let items = xs.to_owned()
  items.sort_by(Action::compare)
  let out : Array[Action] = []
  for x in items {
    if out.last() is Some(y) && y == x {
      continue
    }
    out.push(x)
  }
  { items: out, }
}

///|
/// The union of two sets.
pub fn ActionSet::union(self : ActionSet, other : ActionSet) -> ActionSet {
  ActionSet::of_array(self.items + other.items)
}

///|
/// The actions of `self` that are not in `other`.
pub fn ActionSet::diff(self : ActionSet, other : ActionSet) -> ActionSet {
  { items: self.items.filter(x => !other.mem(x)), }
}

///|
/// `true` if the action is in the set.
pub fn ActionSet::mem(self : ActionSet, x : Action) -> Bool {
  self.items.binary_search_by(y => y.compare(x)) is Ok(_)
}

///|
/// `true` if the set is empty.
pub fn ActionSet::is_empty(self : ActionSet) -> Bool {
  self.items.is_empty()
}

///|
/// The actions in the increasing order.
pub fn ActionSet::to_array(self : ActionSet) -> Array[Action] {
  self.items.copy()
}
