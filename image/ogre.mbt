///|
pub(all) enum OgreFieldType {
  OgreInt
  OgreStr
  OgreBool
  OgreFloat
} derive(Eq, Debug)

///|
pub(all) struct OgreField {
  name : String
  typ : OgreFieldType
} derive(Eq, Debug)

///|
struct OgreFact {
  attribute_value : String
  fields_value : Map[String, String]
}

///|
struct OgreDoc {
  declarations_value : Map[String, Array[OgreField]]
  facts_value : Map[String, Array[OgreFact]]
}

///|
priv enum OgreSexp {
  OgreAtom(String)
  OgreList(Array[OgreSexp])
}

///|
pub fn OgreFieldType::to_string(self : OgreFieldType) -> String {
  match self {
    OgreInt => "int"
    OgreStr => "str"
    OgreBool => "bool"
    OgreFloat => "float"
  }
}

///|
fn ogre_field_type_of_string(text : String) -> OgreFieldType? {
  match text {
    "int" => Some(OgreInt)
    "str" => Some(OgreStr)
    "bool" => Some(OgreBool)
    "float" => Some(OgreFloat)
    _ => None
  }
}

///|
pub fn OgreField::create(name~ : String, typ~ : OgreFieldType) -> OgreField {
  { name, typ }
}

///|
pub fn OgreField::name(self : OgreField) -> String {
  self.name
}

///|
pub fn OgreField::typ(self : OgreField) -> OgreFieldType {
  self.typ
}

///|
pub fn OgreFact::attribute(self : OgreFact) -> String {
  self.attribute_value
}

///|
pub fn OgreFact::fields(self : OgreFact) -> Map[String, String] {
  self.fields_value.copy()
}

///|
pub fn OgreFact::value(self : OgreFact, field : String) -> String? {
  self.fields_value.get(field)
}

///|
pub fn OgreDoc::empty() -> OgreDoc {
  { declarations_value: {}, facts_value: {} }
}

///|
pub fn OgreDoc::declaration_count(self : OgreDoc) -> Int {
  self.declarations_value.length()
}

///|
pub fn OgreDoc::fact_count(self : OgreDoc, attribute : String) -> Int {
  match self.facts_value.get(attribute) {
    Some(items) => items.length()
    None => 0
  }
}

///|
pub fn OgreDoc::declaration_names(self : OgreDoc) -> Array[String] {
  let names = []
  self.declarations_value.each((name, _) => names.push(name))
  names
}

///|
pub fn OgreDoc::declaration(
  self : OgreDoc,
  attribute : String,
) -> Array[OgreField]? {
  self.declarations_value.get(attribute).map(fields => fields.copy())
}

///|
pub fn OgreDoc::facts(self : OgreDoc, attribute : String) -> Array[OgreFact] {
  match self.facts_value.get(attribute) {
    Some(items) => items.copy()
    None => []
  }
}

///|
fn ogre_field_array(
  fields : Array[(String, OgreFieldType)],
) -> Array[OgreField] {
  [
    for field in fields => OgreField::create(name=field.0, typ=field.1)
  ]
}

///|
fn ogre_declaration_map(
  declarations : Array[(String, Array[OgreField])],
) -> Map[String, Array[OgreField]] {
  let result : Map[String, Array[OgreField]] = {}
  for declaration in declarations {
    result[declaration.0] = declaration.1.copy()
  }
  result
}

///|
fn ogre_fact(attribute : String, fields : Array[(String, String)]) -> OgreFact {
  let values : Map[String, String] = {}
  for field in fields {
    values[field.0] = field.1
  }
  { attribute_value: attribute, fields_value: values }
}

///|
fn ogre_fact_map(facts : Array[OgreFact]) -> Map[String, Array[OgreFact]] {
  let result : Map[String, Array[OgreFact]] = {}
  for fact in facts {
    let values = match result.get(fact.attribute_value) {
      Some(items) => items.copy()
      None => []
    }
    values.push(fact)
    result[fact.attribute_value] = values
  }
  result
}

///|
pub fn OgreDoc::from_target(target : @core_theory.Target) -> OgreDoc {
  let declarations = ogre_declaration_map([
    ("arch", ogre_field_array([("name", OgreStr)])),
    ("bits", ogre_field_array([("size", OgreInt)])),
    ("is-little-endian", ogre_field_array([("flag", OgreBool)])),
    ("system", ogre_field_array([("name", OgreStr)])),
    ("abi", ogre_field_array([("name", OgreStr)])),
    ("format", ogre_field_array([("name", OgreStr)])),
  ])
  let facts = [ogre_fact("arch", [("name", target.name().unqualified())])]
  if target.bits() > 0 {
    facts.push(ogre_fact("bits", [("size", target.bits().to_string())]))
  }
  match target.endianness() {
    LittleEndian =>
      facts.push(ogre_fact("is-little-endian", [("flag", "true")]))
    BigEndian => facts.push(ogre_fact("is-little-endian", [("flag", "false")]))
    BiEndian => ()
  }
  if target.system() != UnknownSystem {
    facts.push(ogre_fact("system", [("name", target.system().to_string())]))
  }
  if target.abi() != UnknownAbi {
    facts.push(ogre_fact("abi", [("name", target.abi().to_string())]))
  }
  if target.filetype() != UnknownFiletype {
    facts.push(ogre_fact("format", [("name", target.filetype().to_string())]))
  }
  { declarations_value: declarations, facts_value: ogre_fact_map(facts) }
}

///|
fn ogre_is_space(c : Char) -> Bool {
  c == ' ' || c == '\n' || c == '\r' || c == '\t'
}

///|
fn ogre_is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn ogre_is_alphanum(c : Char) -> Bool {
  ogre_is_alpha(c) || (c >= '0' && c <= '9')
}

///|
fn ogre_skip_ws(text : String, pos : Ref[Int]) -> Unit {
  while pos.val < text.length() {
    match text.get_char(pos.val) {
      Some(c) if ogre_is_space(c) => pos.val = pos.val + c.utf16_len()
      _ => return
    }
  }
}

///|
fn ogre_parse_error(pos : Int, reason : String) -> String {
  "invalid Ogre document at offset \{pos}: \{reason}"
}

///|
fn ogre_parse_quoted(text : String, pos : Ref[Int]) -> Result[String, String] {
  pos.val = pos.val + 1
  let builder = StringBuilder()
  while pos.val < text.length() {
    let c = match text.get_char(pos.val) {
      Some(c) => c
      None => return Err(ogre_parse_error(pos.val, "invalid string offset"))
    }
    if c == '"' {
      pos.val = pos.val + 1
      return Ok(builder.to_string())
    } else if c == '\\' {
      pos.val = pos.val + 1
      if pos.val >= text.length() {
        return Err(ogre_parse_error(pos.val, "unterminated escape sequence"))
      }
      let escaped = match text.get_char(pos.val) {
        Some(c) => c
        None => return Err(ogre_parse_error(pos.val, "invalid escape offset"))
      }
      match escaped {
        '"' => builder.write_char('"')
        '\\' => builder.write_char('\\')
        'n' => builder.write_char('\n')
        'r' => builder.write_char('\r')
        't' => builder.write_char('\t')
        other => builder.write_char(other)
      }
      pos.val = pos.val + escaped.utf16_len()
    } else {
      builder.write_char(c)
      pos.val = pos.val + c.utf16_len()
    }
  }
  Err(ogre_parse_error(pos.val, "unterminated string literal"))
}

///|
fn ogre_parse_atom(text : String, pos : Ref[Int]) -> Result[String, String] {
  let start = pos.val
  while pos.val < text.length() {
    let c = match text.get_char(pos.val) {
      Some(c) => c
      None => return Err(ogre_parse_error(pos.val, "invalid atom offset"))
    }
    if ogre_is_space(c) || c == '(' || c == ')' {
      return Ok(text[start:pos.val].to_owned())
    }
    pos.val = pos.val + c.utf16_len()
  }
  if start == pos.val {
    Err(ogre_parse_error(pos.val, "expected atom"))
  } else {
    Ok(text[start:pos.val].to_owned())
  }
}

///|
fn ogre_parse_sexp(text : String, pos : Ref[Int]) -> Result[OgreSexp, String] {
  ogre_skip_ws(text, pos)
  if pos.val >= text.length() {
    return Err(ogre_parse_error(pos.val, "expected expression"))
  }
  match text.get_char(pos.val) {
    None => Err(ogre_parse_error(pos.val, "invalid expression offset"))
    Some(c) =>
      match c {
        '(' => {
          pos.val = pos.val + 1
          let items = []
          while true {
            ogre_skip_ws(text, pos)
            if pos.val >= text.length() {
              return Err(ogre_parse_error(pos.val, "unterminated list"))
            }
            if text.get_char(pos.val) == Some(')') {
              pos.val = pos.val + 1
              return Ok(OgreList(items))
            }
            match ogre_parse_sexp(text, pos) {
              Ok(item) => items.push(item)
              Err(reason) => return Err(reason)
            }
          }
          Err(ogre_parse_error(pos.val, "unreachable parser state"))
        }
        ')' => Err(ogre_parse_error(pos.val, "unexpected ')'"))
        '"' =>
          match ogre_parse_quoted(text, pos) {
            Ok(value) => Ok(OgreAtom(value))
            Err(reason) => Err(reason)
          }
        _ =>
          match ogre_parse_atom(text, pos) {
            Ok(value) => Ok(OgreAtom(value))
            Err(reason) => Err(reason)
          }
      }
  }
}

///|
fn ogre_parse_sexps(text : String) -> Result[Array[OgreSexp], String] {
  let pos : Ref[Int] = Ref(0)
  let sexps = []
  while true {
    ogre_skip_ws(text, pos)
    if pos.val >= text.length() {
      return Ok(sexps)
    }
    match ogre_parse_sexp(text, pos) {
      Ok(sexp) => sexps.push(sexp)
      Err(reason) => return Err(reason)
    }
  }
  Ok(sexps)
}

///|
fn ogre_valid_field_name(name : String) -> Bool {
  match name.get_char(0) {
    Some(first) if ogre_is_alpha(first) => {
      let mut valid = true
      for c in name {
        if !(ogre_is_alphanum(c) || c == '-') {
          valid = false
        }
      }
      valid
    }
    _ => false
  }
}

///|
fn ogre_parse_field_decl(
  pos : Int,
  sexp : OgreSexp,
) -> Result[OgreField, String] {
  match sexp {
    OgreAtom(type_name) =>
      match ogre_field_type_of_string(type_name) {
        Some(typ) => Ok(OgreField::create(name=pos.to_string(), typ~))
        None => Err("unknown Ogre field type \{type_name}")
      }
    OgreList([OgreAtom(name), OgreAtom(type_name)]) =>
      if !ogre_valid_field_name(name) {
        Err("bad Ogre field name \{name}")
      } else {
        match ogre_field_type_of_string(type_name) {
          Some(typ) => Ok(OgreField::create(name~, typ~))
          None => Err("unknown Ogre field type \{type_name}")
        }
      }
    _ => Err("expected Ogre field declaration")
  }
}

///|
fn ogre_parse_declaration(
  items : Array[OgreSexp],
) -> Result[(String, Array[OgreField]), String] {
  match items {
    [OgreAtom("declare"), OgreAtom(name), .. fields] => {
      let result = []
      for i in 0..<fields.length() {
        match ogre_parse_field_decl(i, fields[i]) {
          Ok(field) => result.push(field)
          Err(reason) => return Err(reason)
        }
      }
      Ok((name, result))
    }
    _ => Err("expected (declare <attribute-name> <field-decls>)")
  }
}

///|
fn ogre_normalize_value(
  typ : OgreFieldType,
  value : String,
) -> Result[String, String] {
  match typ {
    OgreStr => Ok(value)
    OgreBool =>
      match value {
        "true" => Ok("true")
        "false" => Ok("false")
        _ => Err("invalid bool value \{value}")
      }
    OgreInt => {
      let parsed : Int64 = try @string.from_str(value) catch {
        _ => return Err("invalid int value \{value}")
      } noraise {
        parsed => parsed
      }
      Ok(parsed.to_string())
    }
    OgreFloat =>
      try @string.parse_double(value) catch {
        _ => Err("invalid float value \{value}")
      } noraise {
        parsed => Ok(parsed.to_string())
      }
  }
}

///|
fn ogre_parse_fact_value(sexp : OgreSexp) -> Result[(String?, String), String] {
  match sexp {
    OgreAtom(value) => Ok((None, value))
    OgreList([OgreAtom(name), OgreAtom(value)]) => Ok((Some(name), value))
    _ => Err("expected Ogre fact value")
  }
}

///|
fn ogre_add_fact_field(
  fields : Map[String, String],
  name : String,
  value : String,
) -> Result[Map[String, String], String] {
  if fields.contains(name) {
    Err("duplicate Ogre field \{name}")
  } else {
    let result = fields.copy()
    result[name] = value
    Ok(result)
  }
}

///|
fn ogre_parse_fact(
  doc : OgreDoc,
  items : Array[OgreSexp],
) -> Result[OgreFact, String] {
  match items {
    [OgreAtom(attribute), .. values] =>
      match doc.declarations_value.get(attribute) {
        None => Err("Ogre attribute \{attribute} is not declared")
        Some(schema) => {
          let mut fields : Map[String, String] = {}
          if values.length() != schema.length() {
            return Err("wrong arity for Ogre attribute \{attribute}")
          }
          for i in 0..<values.length() {
            match ogre_parse_fact_value(values[i]) {
              Err(reason) => return Err(reason)
              Ok((field_name, raw_value)) => {
                let field = match field_name {
                  Some(name) =>
                    match schema.search_by(item => item.name == name) {
                      Some(index) => schema[index]
                      None => return Err("unknown Ogre field \{name}")
                    }
                  None => schema[i]
                }
                match ogre_normalize_value(field.typ, raw_value) {
                  Err(reason) => return Err(reason)
                  Ok(value) =>
                    match ogre_add_fact_field(fields, field.name, value) {
                      Ok(next) => fields = next
                      Err(reason) => return Err(reason)
                    }
                }
              }
            }
          }
          Ok({ attribute_value: attribute, fields_value: fields })
        }
      }
    _ => Err("expected Ogre fact")
  }
}

///|
fn ogre_update_declaration(
  doc : OgreDoc,
  attribute : String,
  fields : Array[OgreField],
) -> Result[OgreDoc, String] {
  match doc.declarations_value.get(attribute) {
    Some(existing) if existing != fields =>
      Err("Ogre declaration mismatch for \{attribute}")
    _ => {
      let declarations = doc.declarations_value.copy()
      declarations[attribute] = fields.copy()
      Ok({ ..doc, declarations_value: declarations })
    }
  }
}

///|
fn ogre_update_fact(doc : OgreDoc, fact : OgreFact) -> OgreDoc {
  let facts = doc.facts_value.copy()
  let values = match facts.get(fact.attribute_value) {
    Some(items) => items.copy()
    None => []
  }
  if !values.any(item => item.fields_value == fact.fields_value) {
    values.push(fact)
  }
  facts[fact.attribute_value] = values
  { ..doc, facts_value: facts }
}

///|
fn ogre_add_entry(doc : OgreDoc, sexp : OgreSexp) -> Result[OgreDoc, String] {
  match sexp {
    OgreList(items) =>
      match items {
        [OgreAtom("declare"), ..] =>
          match ogre_parse_declaration(items) {
            Ok((attribute, fields)) =>
              ogre_update_declaration(doc, attribute, fields)
            Err(reason) => Err(reason)
          }
        _ =>
          match ogre_parse_fact(doc, items) {
            Ok(fact) => Ok(ogre_update_fact(doc, fact))
            Err(reason) => Err(reason)
          }
      }
    OgreAtom(_) => Err("expected Ogre list entry")
  }
}

///|
pub fn OgreDoc::from_string(text : String) -> Result[OgreDoc, String] {
  match ogre_parse_sexps(text) {
    Err(reason) => Err(reason)
    Ok(sexps) => {
      let mut doc = OgreDoc::empty()
      for sexp in sexps {
        match ogre_add_entry(doc, sexp) {
          Ok(next) => doc = next
          Err(reason) => return Err(reason)
        }
      }
      Ok(doc)
    }
  }
}
