///|
pub(all) struct Name {
  pkg : String
  text : String
} derive(Eq, Hash, Debug)

///|
pub extend Name with Eq::{not_equal}

///|
pub extend Name with Hash::{hash_combine}

///|
pub extend Name with Debug::{to_repr}

///|
fn default_pkg(pkg : String?) -> String {
  match pkg {
    Some("") => "user"
    Some(value) => value
    None => "user"
  }
}

///|
fn escape_name_part(input : String) -> String {
  if !input.contains_any(chars=":\\") {
    return input
  }
  let out = StringBuilder()
  for ch in input {
    if ch == ':' || ch == '\\' {
      out.write_char('\\')
    }
    out.write_char(ch)
  }
  out.to_string()
}

///|
fn keyword_name_text(text : String) -> String {
  if text.has_prefix(":") {
    text
  } else {
    ":" + text
  }
}

///|
fn escape_keyword_name(input : String) -> String {
  if input.has_prefix(":") {
    ":" + escape_name_part(input[1:].to_owned())
  } else {
    ":" + escape_name_part(input)
  }
}

///|
fn unescape_name_part(input : String) -> String {
  if !input.contains_char('\\') {
    return input
  }
  let out = StringBuilder()
  let mut escaped = false
  for ch in input {
    if escaped {
      out.write_char(ch)
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else {
      out.write_char(ch)
    }
  }
  if escaped {
    out.write_char('\\')
  }
  out.to_string()
}

///|
fn split_qualified(input : String) -> (String?, String) {
  let mut escaped = false
  for i, ch in input {
    if escaped {
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == ':' {
      return (
        Some(unescape_name_part(input[:i].to_owned())),
        unescape_name_part(input[i + 1:].to_owned()),
      )
    }
  }
  (None, unescape_name_part(input))
}

///|
fn fnv1a_hash_step(hash : UInt64, text : String) -> UInt64 {
  let mut value = hash
  for ch in text {
    value = value ^ ch.to_uint().to_uint64()
    value = value * 0x100000001b3
  }
  value
}

///|
fn fnv1a_hash_parts(pkg : String, text : String) -> Int {
  fnv1a_hash_step(fnv1a_hash_step(0xcbf29ce484222325, pkg), text).to_int()
}

///|
pub fn Name::create(text : String, pkg? : String) -> Name {
  let pkg = default_pkg(pkg)
  let text = if pkg == "keyword" { keyword_name_text(text) } else { text }
  { pkg, text, }
}

///|
pub fn Name::read(input : String, pkg? : String) -> Name {
  match split_qualified(input) {
    (Some(""), text) => { pkg: "keyword", text: keyword_name_text(text), }
    (Some(found_pkg), text) => {
      let pkg = default_pkg(Some(found_pkg))
      let text = if pkg == "keyword" { keyword_name_text(text) } else { text }
      { pkg, text, }
    }
    (None, text) => {
      let pkg = default_pkg(pkg)
      let text = if pkg == "keyword" { keyword_name_text(text) } else { text }
      { pkg, text, }
    }
  }
}

///|
pub fn Name::of_string(input : String) -> Name {
  Name::read(input)
}

///|
pub fn Name::show(self : Name) -> String {
  if self.pkg == "keyword" {
    escape_keyword_name(self.text)
  } else if self.pkg == "user" {
    escape_name_part(self.text)
  } else {
    "\{escape_name_part(self.pkg)}:\{escape_name_part(self.text)}"
  }
}

///|
pub fn Name::unqualified(self : Name) -> String {
  self.text
}

///|
pub fn Name::pkg(self : Name) -> String {
  self.pkg
}

///|
pub fn Name::equal(self : Name, other : Name) -> Bool {
  self == other
}

///|
pub fn Name::compare(self : Name, other : Name) -> Int {
  let pkg_order = self.pkg.compare(other.pkg)
  if pkg_order != 0 {
    pkg_order
  } else {
    self.text.compare(other.text)
  }
}

///|
pub fn Name::hash(self : Name) -> Int {
  fnv1a_hash_parts(self.pkg, self.text)
}

///|
pub fn Name::to_string(self : Name) -> String {
  self.show()
}

///|
pub fn Name::str() -> (Name) -> String {
  name => name.show()
}
