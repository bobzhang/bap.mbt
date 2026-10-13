// Plain-text rendering of manual pages, following the layout of
// Cmdliner's `plain` format: section headers at column 0, paragraphs
// indented by 7 columns and filled to 80 columns, item labels at column 7
// with their descriptions at column 11.

///|
let man_width = 80

///|
let p_indent = 7

///|
let l_indent = 4

///|
/// Substitutes Cmdliner markup: `$(b,text)` and `$(i,text)` become `text`,
/// `$(var)` is looked up with `vars` (and kept verbatim when unknown).
fn subst_markup(s : String, vars : (String) -> String?) -> String {
  let cs = s.to_array()
  let n = cs.length()
  let sb = StringBuilder()
  let mut i = 0
  while i < n {
    if cs[i] == '$' && i + 1 < n && cs[i + 1] == '(' {
      // find the matching close paren
      let mut depth = 1
      let mut j = i + 2
      while j < n && depth > 0 {
        if cs[j] == '(' {
          depth += 1
        } else if cs[j] == ')' {
          depth -= 1
        }
        if depth > 0 {
          j += 1
        }
      }
      if j >= n {
        sb.write_char(cs[i])
        i += 1
        continue
      }
      let inner = String::from_array(cs[i + 2:j])
      let replaced = match lsplit2(inner, ',') {
        Some(("b" | "i", text)) => subst_markup(text, vars)
        _ =>
          match vars(inner) {
            Some(v) => v
            None => "$(" + inner + ")"
          }
      }
      sb.write_string(replaced)
      i = j + 1
    } else {
      sb.write_char(cs[i])
      i += 1
    }
  }
  sb.to_string()
}

///|
/// Fills `text` (whitespace collapsed) into lines of at most `man_width`
/// columns, each prefixed by `indent` spaces.
fn fill(sb : StringBuilder, text : String, indent : Int32) -> Unit {
  let words = text
    .split(" ")
    .flat_map(w => w.split("\n"))
    .flat_map(w => w.split("\t"))
    .map(w => w.to_owned())
    .filter(w => w != "")
    .collect()
  let pad = " ".repeat(indent)
  sb.write_string(pad)
  let mut col = indent
  let mut first = true
  for w in words {
    if !first && col + 1 + w.length() > man_width {
      sb.write_char('\n')
      sb.write_string(pad)
      col = indent
      first = true
    }
    if !first {
      sb.write_char(' ')
      col += 1
    }
    sb.write_string(w)
    col += w.length()
    first = false
  }
}

///|
/// Renders manual page blocks in Cmdliner's plain format.
fn render_plain(blocks : Array[ManBlock], vars : (String) -> String?) -> String {
  let sb = StringBuilder()
  let subst = (s : String) => subst_markup(s, vars)
  for i, block in blocks {
    match block {
      NoBlank => ()
      Section(s) => sb.write_string(subst(s))
      Paragraph(s) => {
        fill(sb, subst(s), p_indent)
        sb.write_char('\n')
      }
      Verbatim(s) => {
        let lines = subst(s).split("\n").map(l => l.to_owned()).collect()
        for j, line in lines {
          if j > 0 {
            sb.write_char('\n')
          }
          if line != "" {
            sb.write_string(" ".repeat(p_indent))
            sb.write_string(line)
          }
        }
        sb.write_char('\n')
      }
      Item(label, s) => {
        let label = subst(label)
        let s = subst(s)
        sb.write_string(" ".repeat(p_indent))
        sb.write_string(label)
        if s != "" {
          let ll = label.length()
          if ll < l_indent {
            // continue on the same line
            let tmp = StringBuilder()
            fill(tmp, s, p_indent + l_indent)
            let filled = tmp.to_string()
            sb.write_string(" ".repeat(l_indent - ll))
            sb.write_string(filled[p_indent + l_indent:].to_owned())
          } else {
            sb.write_char('\n')
            fill(sb, s, p_indent + l_indent)
          }
        }
        sb.write_char('\n')
      }
    }
    // blank line between blocks unless suppressed
    match blocks.get(i + 1) {
      Some(NoBlank) | None => ()
      Some(_) => sb.write_char('\n')
    }
  }
  sb.to_string()
}
