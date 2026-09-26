///|
/// # Beagle prey (upstream `lib/beagle/beagle_prey`)
///
/// The data types, observations and attributes shared by the Beagle
/// obfuscated-string solver (`plugins/beagle`) and its clients.
///
/// A *prey* is the result of the beagle hunting: during the execution of a
/// sequence of terms the characters of the prey were observed, in that
/// specific order.
pub struct Prey {
  priv terms_ : Array[@types.Tid]
  priv chars_ : Bytes
}

///|
/// `Prey::create(terms, chars)` states that during the execution of the
/// `terms` the `chars` were observed in that order (upstream `create`).
pub fn Prey::create(terms : ArrayView[@types.Tid], chars : BytesView) -> Prey {
  { terms_: terms.to_owned(), chars_: chars.to_owned(), }
}

///|
/// The sequence of caught characters (upstream `data`).
pub fn Prey::data(self : Prey) -> Bytes {
  self.chars_
}

///|
/// The caught characters as a string (each byte is a character).
pub fn Prey::text(self : Prey) -> String {
  latin1(self.chars_)
}

///|
/// The terms that, when executed, consumed or produced one of the caught
/// characters (upstream `terms`).
pub fn Prey::terms(self : Prey) -> Array[@types.Tid] {
  self.terms_.copy()
}

///|
/// Decodes bytes as Latin-1 text, one character per byte.
pub fn latin1(bytes : BytesView) -> String {
  let buf = StringBuilder()
  for b in bytes {
    buf.write_char(b.to_int().unsafe_to_char())
  }
  buf.to_string()
}

///|
fn inspect_prey(prey : Prey) -> @primus.Sexp {
  Atom(prey.text())
}

///|
fn inspect_caught(caught : (Prey, Words)) -> @primus.Sexp {
  let (prey, words) = caught
  List([inspect_prey(prey), words.to_sexp()])
}

///|
let prey_observation : (@primus.Observation[Prey], @primus.Statement[Prey]) = @primus.Observation::provide(
  "beagle-prey",
  desc="Occurs when the sequence of characters is detected.",
  inspect=inspect_prey,
)

///|
let caught_observation : (
  @primus.Observation[(Prey, Words)],
  @primus.Statement[(Prey, Words)],
) = @primus.Observation::provide(
  "beagle",
  desc="Occurs when the sequence of characters is classified as text.",
  inspect=inspect_caught,
)

///|
/// Made when a prey is detected (upstream `detected`).
pub fn detected() -> @primus.Observation[Prey] {
  prey_observation.0
}

///|
/// The statement that a prey was detected (upstream `finished`).
pub fn finished() -> @primus.Statement[Prey] {
  prey_observation.1
}

///|
/// Made when a prey is classified as text, together with the words built
/// from it (upstream `caught`).
pub fn caught() -> @primus.Observation[(Prey, Words)] {
  caught_observation.0
}

///|
/// The statement that a prey was classified (upstream `catch`).
pub fn catch_() -> @primus.Statement[(Prey, Words)] {
  caught_observation.1
}

// Attributes added by the beagle analysis. Upstream registers them as
// value tags; in the port they are term attributes whose values are the
// S-expressions of the word sets.

///|
/// Each string in the set is a sequence of characters detected by Beagle
/// on an emulation of the term, in the order they were observed (upstream
/// `chars`, the `beagle-chars` tag).
pub let chars_tag : String = "beagle-chars"

///|
/// The words that can be built from the observed characters with the
/// selected alphabet (upstream `words`, the `beagle-words` tag).
pub let words_tag : String = "beagle-words"

///|
/// The static strings directly or indirectly referenced by the emulation
/// of the term (upstream `strings`, the `beagle-strings` tag).
pub let strings_tag : String = "beagle-strings"

///|
/// The statically discovered strings (upstream `statics`, the
/// `static-strings` tag).
pub let statics_tag : String = "static-strings"

///|
/// The attribute that stores a set of words under the tag `tag`.
pub fn words_attr(tag : String, words : Words) -> @types.Attr {
  @types.Attr::new(key=tag, value=words.to_sexp().to_string())
}

///|
/// The set of words stored in a term under the tag `tag`.
pub fn[T] term_words(term : @types.Term[T], tag : String) -> Words? {
  match term.get_attr(tag) {
    None => None
    Some(text) => Words::of_sexp(@primus.Sexp::parse(text)) catch { _ => None }
  }
}

///|
/// Statically discovered strings indexed by their addresses (upstream
/// `Statics.t = string Addr.Map.t`).
pub struct Statics {
  priv items : Array[(@types.Word, String)]
}

///|
/// Creates the map from the list of bindings (later bindings override
/// earlier ones), ordered by address.
pub fn Statics::of_array(xs : ArrayView[(@types.Word, String)]) -> Statics {
  let items : Array[(@types.Word, String)] = []
  for x in xs {
    match items.search_by(y => y.0 == x.0) {
      Some(i) => items[i] = x
      None => items.push(x)
    }
  }
  items.sort_by((a, b) => a.0.compare(b.0))
  { items, }
}

///|
/// The bindings, ordered by address.
pub fn Statics::to_array(self : Statics) -> Array[(@types.Word, String)] {
  self.items.copy()
}

///|
/// The string at the address.
pub fn Statics::find(self : Statics, addr : @types.Word) -> String? {
  match self.items.search_by(y => y.0 == addr) {
    Some(i) => Some(self.items[i].1)
    None => None
  }
}

///|
/// Prints each binding as `<addr>: <str>` on its own line (upstream
/// `Statics.pp`).
pub fn Statics::to_string(self : Statics) -> String {
  let buf = StringBuilder()
  for x in self.items {
    buf.write_string("0x\{x.0.string_of_value(hex=true)}: \{x.1}\n")
  }
  buf.to_string()
}
