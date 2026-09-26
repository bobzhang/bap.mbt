///|
/// The facts of one attribute: newest first (upstream keeps an `entry list`
/// and conses new facts onto it), plus a set for duplicate detection.
priv struct Facts {
  items : @list.List[Entry]
  set : @hashset.HashSet[Entry]
}

///|
/// An Ogre document: a set of attribute declarations and facts (upstream
/// `Ogre.doc`).
///
/// Documents are persistent values: every update returns a new document and
/// leaves the original unchanged.
struct Doc {
  scheme : @hashmap.HashMap[String, Array[Header]]
  entries : @hashmap.HashMap[String, Facts]
}

///|
/// The empty document (upstream `Doc.empty`).
pub fn Doc::empty() -> Doc {
  { scheme: @hashmap.new(), entries: @hashmap.new(), }
}

///|
/// `true` iff the document has no declarations (upstream `Doc.is_empty`).
pub fn Doc::is_empty(self : Doc) -> Bool {
  self.scheme.length() == 0
}

///|
/// The number of declared attributes (upstream `Doc.declarations`).
pub fn Doc::declarations(self : Doc) -> Int {
  self.scheme.length()
}

///|
/// The number of attributes that have at least one fact (upstream
/// `Doc.definitions`, which counts attributes rather than individual facts).
pub fn Doc::definitions(self : Doc) -> Int {
  self.entries.length()
}

///|
/// Removes all facts, keeping the declarations (upstream `Doc.clear`).
pub fn Doc::clear(self : Doc) -> Doc {
  { ..self, entries: @hashmap.new(), }
}

///|
/// The names of all declared attributes, in document (byte-wise) order.
pub fn Doc::attributes(self : Doc) -> Array[String] {
  sort_strings(self.scheme.keys().collect())
}

///|
/// The declared signature of an attribute.
pub fn Doc::declaration(self : Doc, name : String) -> Array[Header]? {
  self.scheme.get(name).map(sign => sign.copy())
}

///|
/// The facts of an attribute, newest first (the order used by queries and
/// by the textual form).
pub fn Doc::facts(self : Doc, name : String) -> Array[Entry] {
  match self.entries.get(name) {
    None => []
    Some(facts) => facts.items.to_array()
  }
}

///|
fn sexp_of_signature(sign : Array[Header]) -> Sexp {
  List(
    sign.map(header => {
      List([
        List([Atom("fname"), Atom(header.name)]),
        List([Atom("ftype"), Atom(header.typ.sexp_name())]),
      ])
    }),
  )
}

///|
fn signature_mismatch(expect : Array[Header], got : Array[Header]) -> OgreError {
  let expect = sexp_to_string_hum(sexp_of_signature(expect), indent=2)
  let got = sexp_to_string_hum(sexp_of_signature(got), indent=2)
  OgreError(
    "Failed to parse an OGRE document, got a signature mismatch. Expected:\n\{expect}\nGot:\n\{got}\n",
  )
}

///|
fn Doc::update_scheme(
  self : Doc,
  name : String,
  sign : Array[Header],
) -> Doc raise OgreError {
  match self.scheme.get(name) {
    Some(existing) if existing != sign =>
      raise signature_mismatch(existing, sign)
    _ => { ..self, scheme: self.scheme.add(name, sign.copy()), }
  }
}

///|
fn Doc::typecheck_entry(
  self : Doc,
  name : String,
  entry : Entry,
) -> Array[Header] raise OgreError {
  guard self.scheme.get(name) is Some(sign) else {
    ogre_fail("The attribute \{name} is not declared")
  }
  let mut checked = 0
  for header in sign {
    match entry.get(header.name) {
      None =>
        ogre_fail(
          "attribute \{ocaml_quote(name)} didn't provide a value for the field \{ocaml_quote(header.name)}",
        )
      Some(value) =>
        if header.typ.check(value) {
          checked += 1
        } else {
          ogre_fail(
            "value \{ocaml_quote(value)} is not in a domain of values of field '\{name}.\{header.name}'",
          )
        }
    }
  }
  if checked != entry.length() {
    ogre_fail(
      "attribute \{ocaml_quote(name)} has an arity \{checked}, while a value with arity \{entry.length()} was provided",
    )
  }
  sign
}

///|
fn Doc::update_entries(
  self : Doc,
  name : String,
  entry : Entry,
) -> Doc raise OgreError {
  let sign = self.typecheck_entry(name, entry)
  let normalized = Entry::of_pairs(
    entry.fields.map(field => {
      let typ = match sign.search_by(header => header.name == field.0) {
        Some(index) => sign[index].typ
        None => Str
      }
      match typ.normalize(field.1) {
        Some(value) => (field.0, value)
        None => field
      }
    }),
  )
  let facts = match self.entries.get(name) {
    None => { items: @list.singleton(normalized), set: @hashset.new(), }
    Some(facts) =>
      if facts.set.contains(normalized) {
        return self
      } else {
        { items: facts.items.add(normalized), set: facts.set, }
      }
  }
  let facts = { ..facts, set: facts.set.add(normalized), }
  { ..self, entries: self.entries.add(name, facts), }
}

///|
/// Adds an attribute value to the document, declaring the attribute if
/// needed (upstream `Doc.put`). Fails if the attribute was declared with a
/// different signature.
pub fn[A, K] Doc::put(
  self : Doc,
  attr : Attribute[A, K],
  value : K,
) -> Doc raise OgreError {
  self
  .update_scheme(attr.name, attr.sign)
  .update_entries(attr.name, (attr.save)(value))
}

///|
/// All values of an attribute that can be read with the attribute's scheme,
/// newest first (upstream `Doc.get`).
pub fn[A, K] Doc::get(self : Doc, attr : Attribute[A, K]) -> Array[A] {
  let result = []
  match self.entries.get(attr.name) {
    None => ()
    Some(facts) =>
      for entry in facts.items {
        if (attr.read)(entry) is Some(value) {
          result.push(value)
        }
      }
  }
  result
}

///|
fn[V] compare_maps(
  m1 : @hashmap.HashMap[String, V],
  m2 : @hashmap.HashMap[String, V],
  compare_data : (V, V) -> Int,
) -> Int {
  let k1 = sort_strings(m1.keys().collect())
  let k2 = sort_strings(m2.keys().collect())
  let n = if k1.length() < k2.length() { k1.length() } else { k2.length() }
  for i in 0..<n {
    let c = string_compare(k1[i], k2[i])
    if c != 0 {
      return c
    }
    let c = compare_data(m1.at(k1[i]), m2.at(k2[i]))
    if c != 0 {
      return c
    }
  }
  k1.length().compare(k2.length())
}

///|
fn[T] compare_lists(xs : Array[T], ys : Array[T], cmp : (T, T) -> Int) -> Int {
  let n = if xs.length() < ys.length() { xs.length() } else { ys.length() }
  for i in 0..<n {
    let c = cmp(xs[i], ys[i])
    if c != 0 {
      return c
    }
  }
  xs.length().compare(ys.length())
}

///|
/// The structural document order of upstream's derived `Doc.compare`:
/// declarations first, then facts, both in byte-wise key order.
pub fn Doc::compare(self : Doc, other : Doc) -> Int {
  let c = compare_maps(self.scheme, other.scheme, (s1, s2) => {
    compare_lists(s1, s2, Header::compare)
  })
  if c != 0 {
    return c
  }
  compare_maps(self.entries, other.entries, (f1, f2) => {
    compare_lists(f1.items.to_array(), f2.items.to_array(), Entry::compare)
  })
}

///|
pub impl Eq for Doc with fn equal(self, other) {
  self.compare(other) == 0
}

///|
fn Doc::do_merge(self : Doc, other : Doc) -> Doc raise OgreError {
  let mut doc = self
  for name in other.attributes() {
    doc = doc.update_scheme(name, other.scheme.at(name))
  }
  for name in sort_strings(other.entries.keys().collect()) {
    for entry in other.entries.at(name).items {
      doc = doc.update_entries(name, entry)
    }
  }
  doc
}

///|
/// Merges two documents (upstream `Doc.merge`). Fails if the documents
/// declare the same attribute with different signatures.
///
/// As upstream, the larger document (in [Doc::compare] order) is the base
/// and the facts of the other one are added on top of it.
pub fn Doc::merge(self : Doc, other : Doc) -> Doc raise OgreError {
  match (self.is_empty(), other.is_empty()) {
    (true, true) | (false, true) => self
    (true, false) => other
    (false, false) => {
      let c = self.compare(other)
      if c == 0 {
        self
      } else if c > 0 {
        self.do_merge(other)
      } else {
        other.do_merge(self)
      }
    }
  }
}

///|
pub extend Doc with Eq::{equal, not_equal}
