///|
/// Lexicographic (byte/code-unit) order of strings, as OCaml's
/// `String.compare` (MoonBit's `String::compare` orders by length first).
pub fn lexical_compare(a : String, b : String) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let c = a[i].to_int() - b[i].to_int()
    if c != 0 {
      return if c < 0 { -1 } else { 1 }
    }
  }
  a.length().compare(b.length())
}

///|
/// A set of words (upstream `Beagle_prey.Words.t = String.Set.t`), ordered
/// lexicographically.
pub struct Words {
  priv items : Array[String]
} derive(Eq, Debug)

///|
pub extend Words with Eq::{not_equal, equal}

///|
pub extend Words with Debug::{to_repr}

///|
pub extend Words with Show::{output}

///|
/// The empty set of words.
pub fn Words::empty() -> Words {
  { items: [], }
}

///|
/// The set of the given words.
pub fn Words::of_array(words : ArrayView[String]) -> Words {
  let items = words.to_owned()
  items.sort_by(lexical_compare)
  let out : Array[String] = []
  for w in items {
    if out.last() is Some(last) && last == w {
      continue
    }
    out.push(w)
  }
  { items: out, }
}

///|
/// Adds a word to the set.
pub fn Words::add(self : Words, word : String) -> Words {
  if self.mem(word) {
    self
  } else {
    Words::of_array([..self.items, word])
  }
}

///|
/// The union of two sets.
pub fn Words::union(self : Words, other : Words) -> Words {
  Words::of_array([..self.items, ..other.items])
}

///|
/// `true` if the word is in the set.
pub fn Words::mem(self : Words, word : String) -> Bool {
  self.items.binary_search_by(x => lexical_compare(x, word)) is Ok(_)
}

///|
/// The number of words.
pub fn Words::length(self : Words) -> Int32 {
  self.items.length()
}

///|
/// `true` if the set is empty.
pub fn Words::is_empty(self : Words) -> Bool {
  self.items.is_empty()
}

///|
/// The words in the increasing order.
pub fn Words::to_array(self : Words) -> Array[String] {
  self.items.copy()
}

///|
/// The maximum length of the printed representation (upstream
/// `Words.max`).
pub let max_printed : Int32 = 80

///|
/// OCaml's `String.escaped`: escapes quotes, backslashes, the usual control
/// characters and prints other non-printable bytes as `\ddd`.
pub fn ocaml_escaped(s : String) -> String {
  let buf = StringBuilder()
  for i in 0..<s.length() {
    let c = s[i].to_int()
    match c {
      0x22 => buf.write_string("\\\"")
      0x5c => buf.write_string("\\\\")
      0x0a => buf.write_string("\\n")
      0x09 => buf.write_string("\\t")
      0x0d => buf.write_string("\\r")
      0x08 => buf.write_string("\\b")
      _ =>
        if c >= 0x20 && c <= 0x7e {
          buf.write_char(c.unsafe_to_char())
        } else {
          let d = c & 0xff
          buf.write_char('\\')
          buf.write_char((0x30 + d / 100).unsafe_to_char())
          buf.write_char((0x30 + d / 10 % 10).unsafe_to_char())
          buf.write_char((0x30 + d % 10).unsafe_to_char())
        }
    }
  }
  buf.to_string()
}

///|
/// The printed representation (upstream `Words.pp`/`to_string`): the words
/// separated with `", "`, truncated to `max_printed` characters and
/// escaped.
pub fn Words::to_string(self : Words) -> String {
  let words = self.items.join(", ")
  let words = if words.length() < max_printed {
    words
  } else {
    words.unsafe_substring(start=0, end=max_printed)
  }
  ocaml_escaped(words)
}

///|
pub impl Show for Words with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// The S-expression of the set (upstream `String.Set.sexp_of_t`).
pub fn Words::to_sexp(self : Words) -> @primus.Sexp {
  @primus.Sexp::atoms(self.items)
}

///|
/// Parses the S-expression representation of a set.
pub fn Words::of_sexp(sexp : @primus.Sexp) -> Words? {
  match sexp {
    List(xs) => {
      let words = []
      for x in xs {
        match x {
          Atom(w) => words.push(w)
          List(_) => return None
        }
      }
      Some(Words::of_array(words))
    }
    Atom(_) => None
  }
}
