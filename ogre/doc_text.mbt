// The textual (s-expression) and YAML representations of documents.
//
// Grammar (upstream):
//   document    ::= entry*
//   entry       ::= (declare <attribute-name> <decl>*)
//                 | (<attribute-name> <value>*)
//   decl        ::= <field-type> | (<field-name> <field-type>)
//   value       ::= <field-value> | (<field-name> <field-value>)
//   field-type  ::= int | str | bool | float

///|
fn parse_tname(name : String) -> Typ raise OgreError {
  match Typ::of_string(name) {
    Some(typ) => typ
    None =>
      ogre_fail(
        "expected <field-type> ::= \{Typ::all().map(t => t.to_string()).join(" | ")}",
      )
  }
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn parse_fname(name : String) -> String raise OgreError {
  let valid = match name.get_char(0) {
    Some(first) if is_alpha(first) =>
      name.iter().all(c => is_alpha(c) || (c >= '0' && c <= '9') || c == '-')
    _ => false
  }
  if valid {
    name
  } else {
    ogre_fail("bad field name \{name}, expected [a..z][a..z-]*")
  }
}

///|
fn parse_fdecl(pos : Int32, sexp : Sexp) -> Header raise OgreError {
  match sexp {
    Atom(tname) => { name: pos.to_string(), typ: parse_tname(tname), }
    List([Atom(fname), Atom(tname)]) => {
      let name = parse_fname(fname)
      { name, typ: parse_tname(tname), }
    }
    _ =>
      ogre_fail(
        "expected <decl> ::= <field-type> | (<field-name> <field-type>)",
      )
  }
}

///|
priv enum FieldDefn {
  Positional(String)
  Named(String, String)
}

///|
fn parse_fdefn(sexp : Sexp) -> FieldDefn raise OgreError {
  match sexp {
    Atom(value) => Positional(value)
    List([Atom(fname), Atom(value)]) => Named(fname, value)
    _ =>
      ogre_fail(
        "expected <attribute-value> ::= <field-value> | (<field-name> <field-value>)",
      )
  }
}

///|
fn Doc::nest_defn(
  self : Doc,
  name : String,
  values : Array[FieldDefn],
) -> Entry raise OgreError {
  guard self.scheme.get(name) is Some(header) else {
    ogre_fail("\{name} is not declared in the scheme")
  }
  let pairs : Array[(String, String)] = []
  for pos, defn in values {
    let pair = match defn {
      Positional(value) =>
        match header.get(pos) {
          None => ogre_fail("wrong arity")
          Some(field) => (field.name, value)
        }
      Named(fname, value) =>
        if header.iter().any(field => field.name == fname) {
          (fname, value)
        } else {
          ogre_fail("unknown field \{fname}")
        }
    }
    pairs.push(pair)
  }
  let seen : Map[String, Unit] = Map([])
  for pair in pairs {
    if seen.contains(pair.0) {
      let key = sexp_to_string_hum(Atom(pair.0))
      ogre_fail("(\"Map.of_alist_or_error: duplicate key\" \{key})")
    }
    seen[pair.0] = ()
  }
  Entry::of_pairs(pairs)
}

///|
fn Doc::parse_entry(self : Doc, sexp : Sexp) -> Doc raise OgreError {
  match sexp {
    List([Atom("declare"), Atom(name), .. flds]) => {
      let sign = []
      for i, fld in flds {
        sign.push(parse_fdecl(i, fld))
      }
      self.update_scheme(name, sign)
    }
    List([Atom("declare"), ..]) =>
      ogre_fail("expected (declare <attribute-name> <field-decls>)")
    List([Atom(name), .. flds]) => {
      let values = []
      for fld in flds {
        values.push(parse_fdefn(fld))
      }
      let entry = self.nest_defn(name, values)
      self.update_entries(name, entry)
    }
    _ =>
      ogre_fail(
        "expected <ogre-entry> ::= | (declare <attribute-name> <field-decls>)| (<attribute-name> <attribute-value>)",
      )
  }
}

///|
/// Parses a document from its textual representation (upstream
/// `Doc.from_string`).
///
/// Accepts everything upstream's sexplib reader accepts: positional and
/// named field values, quoted strings with OCaml escapes, and `;`, `#| |#`
/// and `#;` comments. Values are checked against the declarations and
/// normalized (e.g. `0x10` is stored as `16`, `True` as `true`).
pub fn Doc::from_string(text : String) -> Doc raise OgreError {
  let mut doc = Doc::empty()
  for sexp in parse_sexps(text) {
    doc = doc.parse_entry(sexp)
  }
  doc
}

///|
fn sexp_of_header(header : Header) -> Sexp {
  let tname = Atom(header.typ.to_string())
  if header.name.iter().all(c => c >= '0' && c <= '9') {
    tname
  } else {
    List([Atom(header.name), tname])
  }
}

///|
fn sexp_of_decl(name : String, sign : Array[Header]) -> Sexp {
  let items = [Atom("declare"), Atom(name)]
  for header in sign {
    items.push(sexp_of_header(header))
  }
  List(items)
}

///|
fn sexp_of_attr(sign : Array[Header], name : String, entry : Entry) -> Sexp {
  let items = [Atom(name)]
  for header in sign {
    match entry.get(header.name) {
      Some(value) => items.push(Atom(value))
      None =>
        abort(
          "malformed data base - attribute \{name} misses field \{header.name}",
        )
    }
  }
  List(items)
}

///|
/// The textual representation of the document (upstream `Doc.to_string`
/// and `Doc.pp`): declarations then facts, one per line, with long entries
/// wrapped like OCaml's `Format` does at margin 78.
///
/// Attributes are printed in byte-wise name order and facts of the same
/// attribute newest first, exactly as upstream prints them.
pub fn Doc::to_string(self : Doc) -> String {
  let fmt = Formatter::new()
  fmt.open_vbox(0)
  for name in self.attributes() {
    fmt.open_box(0)
    fmt.pp_sexp(1, sexp_of_decl(name, self.scheme.at(name)))
    fmt.close_box()
    fmt.print_space()
  }
  fmt.close_box()
  fmt.force_newline()
  fmt.open_vbox(0)
  for name in sort_strings(self.entries.keys().collect()) {
    let sign = match self.scheme.get(name) {
      Some(sign) => sign
      None => abort("can't find a header for attribute \{name}")
    }
    for entry in self.entries.at(name).items {
      fmt.open_box(0)
      fmt.pp_sexp(1, sexp_of_attr(sign, name, entry))
      fmt.close_box()
      fmt.print_space()
    }
  }
  fmt.close_box()
  fmt.contents()
}

///|
pub impl Show for Doc with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// The YAML representation of the document (upstream `Doc.pp_yaml`).
pub fn Doc::to_yaml(self : Doc) -> String {
  let out = StringBuilder()
  out.write_string("scheme:\n")
  for name in self.attributes() {
    let headers = self.scheme
      .at(name)
      .map(h => "\{ocaml_quote(h.name)} : \{h.typ}")
      .join(", ")
    out.write_string("  \{ocaml_quote(name)} : {\{headers}}\n")
  }
  for name in sort_strings(self.entries.keys().collect()) {
    out.write_string("\{ocaml_quote(name)}:\n")
    let sign = self.scheme.get(name).unwrap_or([])
    for entry in self.entries.at(name).items {
      let objects = sign.map(header => {
        let value = entry.get(header.name).unwrap_or("")
        match header.typ {
          Str => "\{ocaml_quote(header.name)}: \{ocaml_quote(value)}\n"
          _ => "\{ocaml_quote(header.name)}: \{value}\n"
        }
      })
      if !objects.is_empty() {
        out.write_string("  - ")
        out.write_string(objects.join("    "))
      }
    }
  }
  out.to_string()
}

///|
pub extend Doc with Show::{output}
