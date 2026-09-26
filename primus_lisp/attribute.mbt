// Attributes of definitions (upstream `Bap_primus_lisp_attribute` and
// `Bap_primus_lisp_attributes`).
//
// Upstream attributes are an open set of knowledge-base slots. The port
// represents the standard attributes (`context`, `external`, `global`,
// `static`, `visibility`, `advice`) as fields of the `Attrs` record, and
// keeps a registry of custom attributes (declared with
// `declare_attribute`), whose raw arguments are stored in `Attrs`.

///|
/// The visibility of a definition.
pub(all) enum Visibility {
  Public
  Private
} derive(Eq, Debug)

///|
/// The advice method (upstream `Advice.cmethod`).
pub(all) enum AdviceMethod {
  Before
  After
} derive(Eq, Debug)

///|
/// What went wrong when an attribute was parsed.
pub(all) enum AttrProblem {
  ExpectAtom
  ExpectList
  UnterminatedQuote
  VarError(VarReadError)
  ExpectPublicOrPrivate
  UnknownMethod(String)
  BadSyntax
  EmptyAdvice
  NoTargets
  Custom(String)
} derive(Eq, Debug)

///|
pub(all) suberror AttributeError {
  UnknownAttr(String, Tree)
  Failure(AttrProblem, Array[Tree])
} derive(Debug)

///|
pub impl Show for AttributeError with fn output(self, logger) {
  match self {
    UnknownAttr(name, _) => logger.write_string("unknown attribute `\{name}'")
    Failure(problem, _) => {
      let msg = match problem {
        ExpectAtom => "expected an atom"
        ExpectList => "expected a list"
        UnterminatedQuote => "unterminated quote"
        VarError(e) => "bad variable - \{string_of_var_error(e)}"
        ExpectPublicOrPrivate => "expected :public or :private"
        UnknownMethod(m) => "unknown advice method \{m}"
        BadSyntax => "bad syntax"
        EmptyAdvice => "empty advice"
        NoTargets => "no advice targets"
        Custom(m) => m
      }
      logger.write_string("Attribute parse error: \{msg}")
    }
  }
}

///|
/// The attributes of a definition.
pub struct Attrs {
  /// the context in which the definition is applicable
  context : Context
  /// the names under which the definition is exported (`external`)
  externals : @sorted_set.SortedSet[String]
  /// global variables declared with `(declare (global ...))`
  globals : Array[LVar]
  /// static variables declared with `(declare (static ...))`
  statics : Array[LVar]
  /// visibility declarations, the most recent first
  visibility : Array[Visibility]
  /// `:before` advice targets
  before : Array[@knowledge.Name]
  /// `:after` advice targets
  after : Array[@knowledge.Name]
  /// custom attributes: name -> list of argument lists
  custom : @sorted_map.SortedMap[String, Array[Array[Tree]]]
}

///|
pub fn Attrs::empty() -> Attrs {
  {
    context: Context::empty(),
    externals: @sorted_set.SortedSet::new(),
    globals: [],
    statics: [],
    visibility: [],
    before: [],
    after: [],
    custom: @sorted_map.SortedMap::new(),
  }
}

///|
/// Upstream `Visibility.is_public`.
pub fn Attrs::is_public(self : Attrs) -> Bool {
  !(self.visibility is [Private, ..])
}

///|
/// The advice targets of the given method.
pub fn Attrs::advice(self : Attrs, m : AdviceMethod) -> Array[@knowledge.Name] {
  match m {
    Before => self.before
    After => self.after
  }
}

///|
/// Arguments of all occurrences of a custom attribute.
pub fn Attrs::get_custom(self : Attrs, name : String) -> Array[Array[Tree]] {
  match self.custom.get(name) {
    Some(xs) => xs
    None => []
  }
}

///|
/// Joins two sets of attributes (the knowledge-base join of every
/// attribute domain).
pub fn Attrs::join(self : Attrs, other : Attrs) -> Attrs {
  let mut custom = self.custom
  for kv in other.custom.iter() {
    let old = match custom.get(kv.0) {
      Some(xs) => xs
      None => []
    }
    custom = custom.add(kv.0, old + kv.1)
  }
  {
    context: self.context.merge(other.context),
    externals: self.externals.union(other.externals),
    globals: union_vars(self.globals, other.globals),
    statics: union_vars(self.statics, other.statics),
    visibility: other.visibility + self.visibility,
    before: union_names(self.before, other.before),
    after: union_names(self.after, other.after),
    custom,
  }
}

///|
fn union_vars(xs : Array[LVar], ys : Array[LVar]) -> Array[LVar] {
  let out = xs.copy()
  for y in ys {
    if !out.iter().any(x => x.name == y.name && x.typ == y.typ) {
      out.push(y)
    }
  }
  out
}

///|
fn union_names(
  xs : Array[@knowledge.Name],
  ys : Array[@knowledge.Name],
) -> Array[@knowledge.Name] {
  let out = xs.copy()
  for y in ys {
    if !out.contains(y) {
      out.push(y)
    }
  }
  out.sort_by((a, b) => compare_names(a, b))
  out
}

///|
/// A total order on names: by package, then by the unqualified name.
pub fn compare_names(a : @knowledge.Name, b : @knowledge.Name) -> Int {
  let c = a.pkg().compare(b.pkg())
  if c != 0 {
    c
  } else {
    a.unqualified().compare(b.unqualified())
  }
}

///|
let custom_attributes : Map[
  String,
  (String, Array[Tree]) -> Unit raise AttributeError,
] = Map([])

///|
/// Registers a custom attribute `name` (in the `core` package unless the
/// name is qualified). The `check` function validates the arguments of the
/// attribute, the arguments are stored unparsed in `Attrs::custom`.
pub fn declare_attribute(
  name : String,
  check? : (String, Array[Tree]) -> Unit raise AttributeError = (_, _) => (),
) -> Unit {
  let key = @knowledge.Name::read(name, pkg="core").show()
  custom_attributes[key] = check
}

///|
fn parse_attr_name(t : Tree) -> String raise AttributeError {
  match t.data {
    Atom(x) => {
      let n = x.length()
      if n < 2 {
        x
      } else if x.has_prefix("\"") {
        if x.has_suffix("\"") {
          x.unsafe_substring(start=1, end=n - 1)
        } else {
          raise Failure(UnterminatedQuote, [t])
        }
      } else {
        x
      }
    }
    List(_) => raise Failure(ExpectAtom, [t])
  }
}

///|
fn parse_attr_vars(
  pkg : String,
  xs : Array[Tree],
) -> Array[LVar] raise AttributeError {
  let vars = []
  for t in xs {
    match t.data {
      List(_) => raise Failure(ExpectAtom, [t])
      Atom(v) =>
        match read_var(pkg~, t.id, v) {
          Ok(v) => vars.push(v)
          Err(e) => raise Failure(VarError(e), [t])
        }
    }
  }
  union_vars([], vars)
}

///|
fn parse_advice(
  xs : Array[Tree],
) -> (AdviceMethod, Array[@knowledge.Name]) raise AttributeError {
  let targets = (m : AdviceMethod, ts : ArrayView[Tree]) => {
    if ts.length() == 0 {
      raise Failure(NoTargets, ts.to_owned())
    }
    let names = []
    for t in ts {
      match t.data {
        Atom(x) => names.push(@knowledge.Name::read(x, pkg="external"))
        List(_) => raise Failure(ExpectAtom, [t])
      }
    }
    (m, union_names([], names))
  }
  match xs {
    [] => raise Failure(EmptyAdvice, xs)
    [{ data: List(_), .. } as s, ..] => raise Failure(BadSyntax, [s])
    [{ data: Atom(s), .. } as lit, .. ss] =>
      if s == "" {
        raise Failure(UnknownMethod(s), [lit])
      } else if s == ":before" {
        targets(Before, ss)
      } else if s == ":after" {
        targets(After, ss)
      } else if s.has_prefix(":") {
        raise Failure(UnknownMethod(s), [lit])
      } else {
        targets(Before, xs[:])
      }
  }
}

///|
/// Parses one attribute declaration (an element of a `declare` form) and
/// joins it with `attrs` (upstream `Attribute.parse`).
pub fn Attrs::parse(
  attrs : Attrs,
  pkg~ : String,
  tree : Tree,
) -> Attrs raise AttributeError {
  let (head, name, values) = match tree.data {
    List([{ data: Atom(name), .. } as s, .. values]) =>
      (s, name, values.to_owned())
    Atom(name) => (tree, name, [])
    _ => raise Failure(ExpectList, [tree])
  }
  let qname = @knowledge.Name::read(name, pkg="core")
  let key = qname.show()
  let empty = Attrs::empty()
  let attr = match key {
    "core:context" => { ..empty, context: Context::parse(values), }
    "core:external" => {
      let names = []
      for v in values {
        names.push(parse_attr_name(v))
      }
      { ..empty, externals: @sorted_set.SortedSet(names), }
    }
    "core:global" => { ..empty, globals: parse_attr_vars(pkg, values), }
    "core:static" => { ..empty, statics: parse_attr_vars(pkg, values), }
    "core:visibility" =>
      match values {
        [{ data: Atom(":public"), .. }] => { ..empty, visibility: [Public], }
        [{ data: Atom(":private"), .. }] => { ..empty, visibility: [Private], }
        _ => raise Failure(ExpectPublicOrPrivate, values)
      }
    "core:advice" => {
      let (m, names) = parse_advice(values)
      match m {
        Before => { ..empty, before: names, }
        After => { ..empty, after: names, }
      }
    }
    _ =>
      match custom_attributes.get(key) {
        None => raise UnknownAttr(qname.show(), head)
        Some(check) => {
          check(pkg, values)
          { ..empty, custom: @sorted_map.SortedMap::singleton(key, [values]), }
        }
      }
  }
  attrs.join(attr)
}

///|
fn string_of_var_error(e : VarReadError) -> String {
  match e {
    VarEmpty => "empty string can't be used as a variable name"
    NotAVar => "not a valid identifier"
    VarBadType => "variable type should be a decimal number"
    VarBadFormat => "variable name contains extra `:' symbol"
  }
}

///|
fn string_of_word_error(e : WordReadError) -> String {
  match e {
    WordEmpty => "an empty string"
    NotAnInt => "doesn't start with a number"
    BadLiteral =>
      "must start with a digit and contain no more than one `:' symbol"
    Unclosed => "unmatching single quote in a character literal"
    WordBadType => "the type annotation should be a decimal number"
  }
}
