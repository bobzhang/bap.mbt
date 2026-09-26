// Port of `Text_tags`: control of semantic tags in format strings.

///|
/// A name of a mode. By default the `html`, `blocks`, `attr` and `none`
/// modes are available.
pub type Mode = String

///|
/// Raised by `install` when the mode is not registered.
pub(all) suberror UnknownMode {
  UnknownMode(String)
} derive(Eq, Debug)

///|
pub extend UnknownMode with Eq::{not_equal, equal}

///|
pub extend UnknownMode with Debug::{to_repr}

///|
fn expect_tag() -> Unit {
  abort("Expect: tag := (<name> [<arg> <arg>...]) | <name>")
}

///|
fn expect_arg() -> Unit {
  abort("Expect: arg := (<name> <val>)")
}

///|
fn parse_tag(tag : String) -> Sexp {
  Sexp::of_string(tag) catch {
    SexpError(msg) => abort("Text_tags: malformed tag \{tag}: \{msg}")
  }
}

///|
fn is_quoted(s : String) -> Bool {
  s.has_prefix("\"")
}

///|
/// Quotes a string as OCaml's `%S` conversion does.
fn ocaml_quote(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for byte in @utf8.encode(s) {
    let c = byte.to_int()
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
          let d = c.to_string()
          buf.write_char('\\')
          for _ in d.length()..<3 {
            buf.write_char('0')
          }
          buf.write_string(d)
        }
    }
  }
  buf.write_char('"')
  buf.to_string()
}

// Html mode

///|
fn html_mark_open_tag(tag : String) -> String {
  match parse_tag(tag) {
    List([Atom(name), .. attrs]) => {
      let rendered = attrs.map(attr => {
        match attr {
          List([Atom(name), Atom(value)]) =>
            if is_quoted(value) {
              "\{name}=\{value}"
            } else {
              "\{name}=\{ocaml_quote(value)}"
            }
          _ => {
            expect_arg()
            ""
          }
        }
      })
      "<\{name} \{rendered.join(" ")}>"
    }
    Atom(name) => "<\{name}>"
    _ => {
      expect_tag()
      ""
    }
  }
}

///|
fn html_mark_close_tag(tag : String) -> String {
  match parse_tag(tag) {
    List([Atom(name), ..]) | Atom(name) => "</\{name}>"
    _ => {
      expect_tag()
      ""
    }
  }
}

///|
fn install_html(fmt : Formatter) -> Unit {
  fmt.set_mark_tags(true)
  fmt.set_print_tags(true)
  fmt.set_tag_functions({
    mark_open_tag: html_mark_open_tag,
    mark_close_tag: html_mark_close_tag,
    print_open_tag: _ => {
      fmt.open_vbox(1)
      fmt.print_cut()
    },
    print_close_tag: _ => {
      fmt.close_box()
      fmt.print_cut()
    },
  })
}

// Blocks mode

///|
priv enum BlockAttr {
  Title(String)
  Id(String)
}

///|
fn blocks_filter_attrs(tag : String) -> String? {
  match parse_tag(tag) {
    List([Atom(_), .. attrs]) => {
      let found : Array[BlockAttr] = []
      for attr in attrs {
        match attr {
          List([Atom("title"), Atom(v)]) => found.push(Title(v))
          List([Atom("id"), Atom(v)]) => found.push(Id(v))
          List([_, _]) => ()
          _ => expect_arg()
        }
      }
      match found {
        [Title(v), _] | [_, Title(v)] | [Title(v)] | [Id(v)] => Some(v)
        _ => None
      }
    }
    Atom(_) => None
    _ => {
      expect_tag()
      None
    }
  }
}

///|
fn install_blocks(fmt : Formatter) -> Unit {
  fmt.set_mark_tags(true)
  fmt.set_print_tags(true)
  fmt.set_tag_functions({
    mark_open_tag: tag => {
      match blocks_filter_attrs(tag) {
        Some(v) => "begin(\{v}) "
        None => ""
      }
    },
    mark_close_tag: tag => {
      match blocks_filter_attrs(tag) {
        Some(v) => "end(\{v})"
        None => ""
      }
    },
    print_open_tag: tag => {
      if blocks_filter_attrs(tag) is Some(_) {
        fmt.open_vbox(1)
        fmt.print_cut()
      }
    },
    print_close_tag: tag => {
      if blocks_filter_attrs(tag) is Some(_) {
        fmt.close_box()
        fmt.print_cut()
      }
    },
  })
}

// Attr mode

///|
let shown_attrs : Map[String, Unit] = Map([])

///|
let colorify : Ref[Bool] = { val: false, }

///|
let clean : Ref[Bool] = { val: true, }

///|
/// [attr_show(name)] enables printing of the attribute [name] in the
/// `attr` mode (upstream `Attr.show`).
pub fn attr_show(name : String) -> Unit {
  shown_attrs[name] = ()
}

///|
/// [attr_hide(name)] disables printing of the attribute [name] (upstream
/// `Attr.hide`).
pub fn attr_hide(name : String) -> Unit {
  shown_attrs.remove(name)
}

///|
/// Enables or disables the ANSI color submode of the `attr` mode (upstream
/// `Attr.print_colors`). It is disabled by default (upstream enables it
/// when the standard output is a terminal).
pub fn attr_print_colors(enabled : Bool) -> Unit {
  colorify.val = enabled
}

///|
/// Parses an attribute tag `.<name> <value>` into its name and value
/// (the value stops at the first newline).
fn parse_attr(tag : String) -> (String, String)? {
  let chars = tag.to_array()
  let mut i = 0
  while i < chars.length() && is_sexp_space(chars[i]) {
    i += 1
  }
  guard i < chars.length() && chars[i] == '.' else { None }
  i += 1
  let name = StringBuilder()
  while i < chars.length() && !is_sexp_space(chars[i]) {
    name.write_char(chars[i])
    i += 1
  }
  while i < chars.length() && is_sexp_space(chars[i]) {
    i += 1
  }
  let value = StringBuilder()
  while i < chars.length() && chars[i] != '\n' {
    value.write_char(chars[i])
    i += 1
  }
  Some((name.to_string(), value.to_string()))
}

///|
fn ascii_color(tag : String) -> String? {
  match parse_attr(tag) {
    Some(("foreground" | "background", color)) => Some(color)
    _ => None
  }
}

///|
fn need_to_print(tag : String) -> Bool {
  match parse_attr(tag) {
    Some((name, _)) => shown_attrs.contains(name)
    None => false
  }
}

///|
fn install_attr(fmt : Formatter) -> Unit {
  fmt.set_print_tags(true)
  let tags = fmt.get_tag_functions()
  fmt.set_tag_functions({
    ..tags,
    print_open_tag: tag => {
      if need_to_print(tag) {
        match ascii_color(tag) {
          Some(color) if colorify.val => {
            fmt.print_string(color)
            clean.val = false
          }
          _ => {
            fmt.print_string(tag)
            fmt.print_newline()
          }
        }
      }
    },
  })
  let out = fmt.get_out_functions()
  fmt.set_out_functions({
    ..out,
    out_newline: () => {
      if !clean.val {
        fmt.print_string("\u{1b}[39;49m")
      }
      clean.val = true
      (out.out_newline)()
    },
  })
}

// None mode

///|
fn install_none(fmt : Formatter) -> Unit {
  fmt.set_mark_tags(false)
  fmt.set_print_tags(false)
}

// Mode registry

///|
let modes : Array[(Mode, (Formatter) -> Unit)] = [
  ("blocks", install_blocks),
  ("none", install_none),
  ("html", install_html),
  ("attr", install_attr),
]

///|
/// [register_mode(mode, init)] registers a new mode. The [init] function
/// must install all mode hooks on the formatter. A newer registration of
/// the same name shadows the older one.
pub fn register_mode(mode : Mode, init : (Formatter) -> Unit) -> Unit {
  modes.insert(0, (mode, init))
}

///|
/// Lists all registered modes, most recently registered first.
pub fn available_modes() -> Array[Mode] {
  modes.map(entry => entry.0)
}

///|
/// [install(fmt, mode)] switches the formatter [fmt] into [mode]. In the
/// default `none` mode the semantic tags are ignored; once another mode is
/// installed, all tags are rendered according to the mode.
pub fn install(fmt : Formatter, mode : Mode) -> Unit raise UnknownMode {
  for entry in modes {
    if entry.0 == mode {
      (entry.1)(fmt)
      return
    }
  }
  raise UnknownMode(mode)
}

///|
/// [with_mode(fmt, mode, f)] installs [mode], calls [f], and then restores
/// the previous tag settings of [fmt] (even if [f] raises).
pub fn[A] with_mode(fmt : Formatter, mode : Mode, f : () -> A raise) -> A raise {
  let tags = fmt.get_tag_functions()
  let mark = fmt.get_mark_tags()
  let print = fmt.get_print_tags()
  install(fmt, mode)
  defer {
    fmt.set_mark_tags(mark)
    fmt.set_print_tags(print)
    fmt.set_tag_functions(tags)
  }
  f()
}
