///|
/// Documentation record for observations, systems and components
/// (upstream `Primus.Info.t`).
pub struct Info {
  priv name : @knowledge.Name
  priv desc : String
  priv long : () -> String
}

///|
pub fn Info::name(self : Info) -> @knowledge.Name {
  self.name
}

///|
pub fn Info::desc(self : Info) -> String {
  self.desc
}

///|
pub fn Info::long(self : Info) -> String {
  (self.long)()
}

///|
fn info_unquote(s : String) -> String {
  if s.length() >= 2 && s.has_prefix("\"") && s.has_suffix("\"") {
    s.view(start_offset=1, end_offset=s.length() - 1).to_owned()
  } else {
    s
  }
}

///|
fn info_dedup_whitespace(s : String) -> String {
  let buf = StringBuilder()
  let mut white = true
  for c in s {
    let ws = c == ' ' || c == '\t' || c == '\n' || c == '\r'
    if !ws {
      buf.write_char(c)
      white = false
    } else if !white {
      buf.write_char(c)
      white = true
    }
  }
  buf.to_string()
}

///|
/// Normalizes a documentation string: strips blanks, removes surrounding
/// quotes and collapses runs of whitespace.
pub fn info_normalize_text(s : String) -> String {
  info_dedup_whitespace(info_unquote(s.trim(chars=" \t\n\r").to_owned()))
}

///|
pub fn Info::create(
  name : @knowledge.Name,
  desc? : String = "",
  long? : () -> String = () => "",
) -> Info {
  { name, desc: info_normalize_text(desc), long, }
}

///|
pub fn Info::to_string(self : Info) -> String {
  "- \{self.name.show()}:\n\{self.desc}\n"
}
