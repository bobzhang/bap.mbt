// Port of the `Markdown` module of `bap_main.ml`: a tiny markdown subset
// (paragraphs, `#` section headers, list items, and ``` verbatim blocks)
// translated into Cmdliner-style manual page blocks.

///|
/// A manual page block (`Cmdliner.Manpage.block`).
pub(all) enum ManBlock {
  /// A section header.
  Section(String)
  /// A paragraph.
  Paragraph(String)
  /// A verbatim (preformatted) block.
  Verbatim(String)
  /// A labeled item.
  Item(String, String)
  /// Suppresses the blank line before the next block.
  NoBlank
} derive(Eq, Debug)

///|
pub extend ManBlock with Eq::{equal, not_equal}

///|
pub extend ManBlock with Debug::{to_repr}

///|
fn md_section(s : String) -> String? {
  let s = strip(s)
  let cs = s.to_array()
  let len = cs.length()
  for n in 0..<len {
    if cs[n] != '#' {
      return if n == 0 || n == len - 1 {
        None
      } else {
        Some(strip(String::from_array(cs[n:])))
      }
    }
  }
  None
}

///|
priv enum Verb {
  Nocode
  End(String)
  Beg(String)
  Pre(String)
}

///|
fn md_verbatim(s : String) -> Verb {
  let delimiter = "```"
  let chop_prefix = (s : String) => {
    let s = lstrip(s)
    if s.has_prefix(delimiter) {
      Some(s[delimiter.length():].to_owned())
    } else {
      None
    }
  }
  let chop_suffix = (s : String) => {
    let s = rstrip(s)
    if s.has_suffix(delimiter) {
      Some(s[:s.length() - delimiter.length()].to_owned())
    } else {
      None
    }
  }
  match chop_prefix(s) {
    None =>
      match chop_suffix(s) {
        None => Nocode
        Some(code) => End(code)
      }
    Some(code) =>
      match chop_suffix(code) {
        None => Beg(code)
        Some(code) => Pre(code)
      }
  }
}

///|
fn md_list_item(s : String) -> (String, String)? {
  let s = strip(s)
  let cs = s.to_array()
  let len = cs.length()
  if len <= 2 {
    return None
  }
  match (cs[0], cs[1]) {
    ('*' | '+' | '-', ' ') =>
      Some((String::from_array(cs[:1]), String::from_array(cs[2:])))
    (x, _) =>
      if x is ('0'..<='9') {
        for n = 1; n + 1 < len; n = n + 1 {
          match (cs[n], cs[n + 1]) {
            ('.' | ')', ' ') =>
              return Some(
                (
                  String::from_array(cs[:n]),
                  strip(String::from_array(cs[n + 1:])),
                ),
              )
            (d, _) if d is ('0'..<='9') => continue
            _ => return None
          }
        }
        None
      } else {
        None
      }
  }
}

///|
/// Splits the input into paragraphs separated by blank lines. This is a
/// faithful port of BAP's scanner, including its quirks (the character
/// after a single newline is skipped by the scanner, which only matters
/// for detecting a following newline).
fn md_split(input : String) -> Array[String] {
  let cs = input.to_array()
  let len = cs.length()
  let paras = []
  let mut start = 0
  let mut curr = 0
  while curr < len {
    if cs[curr] == '\n' {
      if curr + 2 < len {
        if cs[curr + 1] == '\n' {
          paras.push(String::from_array(cs[start:curr]))
          start = curr + 2
          curr = curr + 3
        } else {
          curr = curr + 2
        }
      } else {
        curr = curr + 1
      }
    } else {
      curr = curr + 1
    }
  }
  if start < curr && curr - start <= len {
    paras.push(String::from_array(cs[start:curr]))
  }
  paras
}

///|
/// `markdown_to_manpage(text)` translates the markdown subset understood
/// by BAP into manual page blocks.
///
/// ```mbt check
/// test {
///   let blocks = @bap_main.markdown_to_manpage(
///     "# DESCRIPTION\n\nHello.\n\n- item",
///   )
///   debug_inspect(
///     blocks,
///     content=(
///       #|[Section("DESCRIPTION"), Paragraph("Hello."), Item("-", "item")]
///     ),
///   )
/// }
/// ```
pub fn markdown_to_manpage(input : String) -> Array[ManBlock] {
  let paras = md_split(input)
  let out : Array[ManBlock] = []
  let mut i = 0
  while i < paras.length() {
    let para = paras[i]
    i += 1
    match md_section(para) {
      Some(name) => out.push(Section(name))
      None =>
        match md_verbatim(para) {
          Pre(code) => out.push(Verbatim(code))
          Beg(code) => {
            // collect until the closing delimiter
            let codes = [code]
            let mut closed = false
            while i < paras.length() {
              let para = paras[i]
              i += 1
              match md_verbatim(para) {
                End(code) | Beg(code) => {
                  codes.push(code)
                  closed = true
                  break
                }
                _ => codes.push(para)
              }
            }
            if closed {
              out.push(Verbatim(codes.join("\n\n")))
            } else {
              out.push(Paragraph("ERROR : unbalanced ```"))
            }
          }
          End(para) => {
            out.push(Paragraph("ERROR: Unbalanced ```"))
            out.push(Paragraph(para))
          }
          Nocode =>
            match md_list_item(para) {
              Some((item, desc)) => out.push(Item(item, desc))
              None => out.push(Paragraph(strip(para)))
            }
        }
    }
  }
  out
}

///|
fn first_paragraph(man : Array[ManBlock]) -> String? {
  match man {
    [Paragraph(p), ..] | [Section(_), Paragraph(p), ..] => Some(p)
    _ => None
  }
}

///|
fn first_sentence(text : String) -> String {
  let mut stop = text.length()
  for i, c in text.to_array() {
    if c == '\n' || c == '.' {
      stop = i
      break
    }
  }
  String::from_array(text.to_array()[:stop])
}

///|
fn first_sentence_of_man(man : Array[ManBlock]) -> String? {
  match first_paragraph(man) {
    Some(p) => Some(first_sentence(p))
    None => None
  }
}

///|
/// Lowercases the first character (OCaml `String.uncapitalize`).
fn uncapitalize(s : String) -> String {
  match s.to_array() {
    [c, .. rest] if c is ('A'..<='Z') =>
      String::from_array([(c.to_int() + 32).unsafe_to_char(), ..rest])
    _ => s
  }
}

///|
fn short_description(
  default~ : String = "no description provided",
  input : String?,
) -> String {
  match input {
    Some(s) => uncapitalize(s)
    None => default
  }
}
