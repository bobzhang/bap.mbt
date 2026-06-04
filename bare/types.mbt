///|
pub(all) enum BareTerm {
  BareAtom(String)
  BareList(Array[BareTerm])
} derive(Eq, Debug)

///|
pub type BareTuple = BareTerm

///|
pub type BareFact = BareTerm

///|
pub(all) enum BareError {
  BareUnbound(String)
  BareWildcard
  BareParseError(String)
  BareNotASexp(String)
} derive(Eq, Debug)

///|
pub fn BareTerm::atom(value : String) -> BareTerm {
  BareAtom(value)
}

///|
pub fn BareTerm::list(values : Array[BareTerm]) -> BareTerm {
  BareList(values.copy())
}

///|
fn bare_is_space(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\r' || c == '\t'
}

///|
fn bare_atom_needs_quotes(atom : String) -> Bool {
  if atom.length() == 0 {
    true
  } else {
    let mut needs = false
    for c in atom {
      if bare_is_space(c) || c == '(' || c == ')' || c == '"' || c == '\\' {
        needs = true
      }
    }
    needs
  }
}

///|
fn bare_quote_atom(atom : String) -> String {
  let out = StringBuilder()
  out.write_char('"')
  for c in atom {
    match c {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      other => out.write_char(other)
    }
  }
  out.write_char('"')
  out.to_string()
}

///|
pub fn BareTerm::to_string(self : BareTerm) -> String {
  match self {
    BareAtom(atom) =>
      if bare_atom_needs_quotes(atom) {
        bare_quote_atom(atom)
      } else {
        atom
      }
    BareList(items) =>
      "(\{[ for item in items => item.to_string() ].join(" ")})"
  }
}

///|
pub fn BareError::to_string(self : BareError) -> String {
  match self {
    BareUnbound(name) => "unbound BARE variable \{name}"
    BareWildcard => "BARE wildcard cannot be used on a rule right-hand side"
    BareParseError(reason) => reason
    BareNotASexp(reason) => "not a BARE S-expression: \{reason}"
  }
}
