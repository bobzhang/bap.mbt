///|
/// A node of a document tree.
pub(all) enum Node {
  Element(Tag, Array[Node])
  Text(String)
} derive(Eq, Debug)

///|
pub extend Node with Eq::{not_equal, equal}

///|
pub extend Node with Debug::{to_repr}

///|
/// A parsed document: the document type declaration and the root element.
pub(all) struct Document {
  dtd : String?
  root : Node
} derive(Eq, Debug)

///|
pub extend Document with Eq::{not_equal, equal}

///|
pub extend Document with Debug::{to_repr}

///|
/// Reads the next element (the input is at its start tag) as a tree.
pub fn Input::read_tree(self : Input) -> Node raise XmlError {
  match self.input() {
    ElStart(tag) => {
      let children = []
      for ;; {
        match self.peek() {
          ElEnd => {
            let _ = self.input()
            break
          }
          Data(text) => {
            let _ = self.input()
            children.push(Text(text))
          }
          ElStart(_) => children.push(self.read_tree())
          Dtd(_) => raise XmlError(pos=self.pos(), "unexpected DTD")
        }
      }
      Element(tag, children)
    }
    _ => raise XmlError(pos=self.pos(), "expected an element")
  }
}

///|
/// Parses a whole document.
pub fn parse_document(
  text : StringView,
  strip~ : Bool = false,
  entity~ : (String) -> String? = _ => None,
  ns~ : (String) -> String? = _ => None,
) -> Document raise XmlError {
  let input = Input::from_string(text, strip~, entity~, ns~)
  let dtd = match input.input() {
    Dtd(d) => d
    _ => None
  }
  let root = input.read_tree()
  { dtd, root, }
}

///|
/// The name of an element (`None` for text nodes).
pub fn Node::name(self : Node) -> Name? {
  match self {
    Element(tag, _) => Some(tag.name)
    Text(_) => None
  }
}

///|
/// The children of an element (empty for text nodes).
pub fn Node::children(self : Node) -> Array[Node] {
  match self {
    Element(_, xs) => xs
    Text(_) => []
  }
}

///|
/// The child elements with the given local_name name.
pub fn Node::elements(self : Node, local_name : String) -> Array[Node] {
  self
  .children()
  .filter(n => n is Element(tag, _) && tag.name.local_name == local_name)
}

///|
/// The value of the attribute of an element (see `Tag::attr`).
pub fn Node::attr(
  self : Node,
  local_name : String,
  uri~ : String = "",
) -> String? {
  match self {
    Element(tag, _) => tag.attr(local_name, uri~)
    Text(_) => None
  }
}

///|
/// The concatenated text of a node and its descendants.
pub fn Node::text(self : Node) -> String {
  match self {
    Text(s) => s
    Element(_, xs) => xs.map(x => x.text()).join("")
  }
}

///|
/// Escapes the character data (`<`, `>`, `&`, and, when `quotes`, `"`).
pub fn escape(s : String, quotes~ : Bool = false) -> String {
  let buf = StringBuilder()
  for c in s {
    match c {
      '<' => buf.write_string("&lt;")
      '>' => buf.write_string("&gt;")
      '&' => buf.write_string("&amp;")
      '"' if quotes => buf.write_string("&quot;")
      _ => buf.write_char(c)
    }
  }
  buf.to_string()
}

///|
/// Serializes a node (names are printed with their local_name parts; the
/// namespace declarations are kept as attributes).
pub fn Node::to_string(self : Node) -> String {
  match self {
    Text(s) => escape(s)
    Element(tag, xs) => {
      let buf = StringBuilder()
      buf.write_string("<" + tag.name.local_name)
      for a in tag.attrs {
        let n = if a.name.uri == ns_xmlns {
          if a.name.local_name == "xmlns" {
            "xmlns"
          } else {
            "xmlns:" + a.name.local_name
          }
        } else {
          a.name.local_name
        }
        buf.write_string(" \{n}=\"\{escape(a.value, quotes=true)}\"")
      }
      if xs.is_empty() {
        buf.write_string("/>")
      } else {
        buf.write_string(">")
        for x in xs {
          buf.write_string(x.to_string())
        }
        buf.write_string("</\{tag.name.local_name}>")
      }
      buf.to_string()
    }
  }
}
