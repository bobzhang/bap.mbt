///|
pub(all) struct Name {
  pkg : String
  text : String
} derive(Eq, Hash, Debug)

///|
fn default_pkg(pkg : String?) -> String {
  match pkg {
    Some(value) => value
    None => "user"
  }
}

///|
fn escape_name_part(input : String) -> String {
  let mut out = ""
  for ch in input {
    if ch == ':' || ch == '\\' {
      out = out + "\\"
    }
    out = out + "\{ch}"
  }
  out
}

///|
fn unescape_name_part(input : String) -> String {
  let mut out = ""
  let mut escaped = false
  for ch in input {
    if escaped {
      out = out + "\{ch}"
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else {
      out = out + "\{ch}"
    }
  }
  if escaped {
    out + "\\"
  } else {
    out
  }
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
pub fn Name::create(text : String, pkg? : String) -> Name {
  { pkg: default_pkg(pkg), text }
}

///|
pub fn Name::read(input : String, pkg? : String) -> Name {
  match split_qualified(input) {
    (Some(found_pkg), text) => { pkg: found_pkg, text }
    (None, text) => { pkg: default_pkg(pkg), text }
  }
}

///|
pub fn Name::show(self : Name) -> String {
  "\{escape_name_part(self.pkg)}:\{escape_name_part(self.text)}"
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
pub fn Name::to_string(self : Name) -> String {
  self.show()
}
