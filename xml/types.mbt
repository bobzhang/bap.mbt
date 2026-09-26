///|
/// # A small XML reader
///
/// A streaming XML 1.0 reader modeled after the `Xmlm` OCaml library (the
/// subset used by BAP): the input is decoded into a sequence of *signals*,
/// a document starts with a `Dtd` signal, followed by the signals of the
/// root element: `ElStart` and `ElEnd` for elements (empty-element tags
/// produce both) and `Data` for the character data in between.
///
/// Supported: the XML declaration and processing instructions (skipped),
/// comments (skipped), the document type declaration (reported verbatim,
/// including the internal subset), elements and attributes with
/// namespace resolution (`xmlns` and `xmlns:prefix` declarations, the
/// predefined `xml` and `xmlns` prefixes), character data with the
/// predefined entities, character references and custom entities (via a
/// callback), CDATA sections, `\r\n` line-end normalization and attribute
/// value normalization. Optionally (`strip=true`) consecutive white space
/// in character data is collapsed into one space, leading and trailing
/// white space is removed, and white-space-only data is dropped.
///
/// The `Node` tree API is built on top of the signal stream.

///|
/// The namespace of the `xml` prefix.
pub let ns_xml : String = "http://www.w3.org/XML/1998/namespace"

///|
/// The namespace of the `xmlns` prefix (namespace declarations).
pub let ns_xmlns : String = "http://www.w3.org/2000/xmlns/"

///|
/// An expanded name: the namespace URI (empty when the name is not in a
/// namespace) and the local_name part.
pub(all) struct Name {
  uri : String
  local_name : String
} derive(Eq, Hash, Debug)

///|
pub extend Name with Eq::{not_equal, equal}

///|
pub extend Name with Hash::{hash, hash_combine}

///|
pub extend Name with Show::{output}

///|
pub extend Name with Debug::{to_repr}

///|
/// A name that is not in a namespace.
pub fn Name::local_name(local_name : String) -> Name {
  { uri: "", local_name, }
}

///|
/// The name as `uri:local_name`, or just `local_name` when the URI is empty.
pub fn Name::to_string(self : Name) -> String {
  if self.uri == "" {
    self.local_name
  } else {
    "\{self.uri}:\{self.local_name}"
  }
}

///|
pub impl Show for Name with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// An attribute: its name and its (normalized, entity-expanded) value.
pub(all) struct Attribute {
  name : Name
  value : String
} derive(Eq, Debug)

///|
pub extend Attribute with Eq::{not_equal, equal}

///|
pub extend Attribute with Debug::{to_repr}

///|
/// A start tag: the element name and its attributes, in the document
/// order (namespace declarations included).
pub(all) struct Tag {
  name : Name
  attrs : Array[Attribute]
} derive(Eq, Debug)

///|
pub extend Tag with Eq::{not_equal, equal}

///|
pub extend Tag with Debug::{to_repr}

///|
/// The value of the first attribute with the given local_name name and URI
/// (empty by default).
pub fn Tag::attr(
  self : Tag,
  local_name : String,
  uri? : String = "",
) -> String? {
  for a in self.attrs {
    if a.name.local_name == local_name && a.name.uri == uri {
      return Some(a.value)
    }
  }
  None
}

///|
/// An input signal (`Xmlm.signal`).
pub(all) enum Signal {
  /// the document type declaration (verbatim), if any; always the first
  /// signal of a document
  Dtd(String?)
  /// a start tag
  ElStart(Tag)
  /// an end tag (also generated for an empty-element tag)
  ElEnd
  /// character data (entities and CDATA sections are expanded)
  Data(String)
} derive(Eq, Debug)

///|
pub extend Signal with Eq::{not_equal, equal}

///|
pub extend Signal with Debug::{to_repr}

///|
/// A position in the input: line and column, both starting at 1.
pub(all) struct Pos {
  line : Int
  col : Int
} derive(Eq, Debug)

///|
pub extend Pos with Eq::{not_equal, equal}

///|
pub extend Pos with Debug::{to_repr}

///|
/// An error, with the position where it was detected.
pub(all) suberror XmlError {
  XmlError(pos~ : Pos, String)
} derive(Eq, Debug)

///|
pub extend XmlError with Eq::{not_equal, equal}

///|
pub extend XmlError with Debug::{to_repr}

///|
pub extend XmlError with Show::{output}

///|
/// `line:col: message`.
pub fn XmlError::to_string(self : XmlError) -> String {
  match self {
    XmlError(pos~, msg) => "\{pos.line}:\{pos.col}: \{msg}"
  }
}

///|
pub impl Show for XmlError with fn output(self, logger) {
  logger.write_string(self.to_string())
}
