///|
struct OgreAttribute {
  name_value : String
  fields_value : Array[OgreField]
}

///|
pub(all) struct Scheme {}

///|
fn scheme_field(name : String, typ : OgreFieldType) -> OgreField {
  OgreField::create(name~, typ~)
}

///|
fn scheme_attribute(name : String, fields : Array[OgreField]) -> OgreAttribute {
  { name_value: name, fields_value: fields.copy() }
}

///|
fn scheme_named(name : String) -> OgreAttribute {
  scheme_attribute(name, [Scheme::name()])
}

///|
fn scheme_region(fields? : Array[OgreField] = []) -> Array[OgreField] {
  let result = [Scheme::addr(), Scheme::size()]
  for field in fields {
    result.push(field)
  }
  result
}

///|
pub fn Scheme::off() -> OgreField {
  scheme_field("off", OgreInt)
}

///|
pub fn Scheme::size() -> OgreField {
  scheme_field("size", OgreInt)
}

///|
pub fn Scheme::addr() -> OgreField {
  scheme_field("addr", OgreInt)
}

///|
pub fn Scheme::value() -> OgreField {
  scheme_field("value", OgreInt)
}

///|
pub fn Scheme::name() -> OgreField {
  scheme_field("name", OgreStr)
}

///|
pub fn Scheme::root() -> OgreField {
  scheme_field("root", OgreInt)
}

///|
pub fn Scheme::fixup() -> OgreField {
  scheme_field("fixup", OgreInt)
}

///|
pub fn Scheme::readable() -> OgreField {
  scheme_field("r", OgreBool)
}

///|
pub fn Scheme::writable() -> OgreField {
  scheme_field("w", OgreBool)
}

///|
pub fn Scheme::executable() -> OgreField {
  scheme_field("x", OgreBool)
}

///|
pub fn Scheme::arch() -> OgreAttribute {
  scheme_named("arch")
}

///|
pub fn Scheme::subarch() -> OgreAttribute {
  scheme_named("subarch")
}

///|
pub fn Scheme::format() -> OgreAttribute {
  scheme_named("format")
}

///|
pub fn Scheme::vendor() -> OgreAttribute {
  scheme_named("vendor")
}

///|
pub fn Scheme::system() -> OgreAttribute {
  scheme_named("system")
}

///|
pub fn Scheme::require() -> OgreAttribute {
  scheme_named("require")
}

///|
pub fn Scheme::abi() -> OgreAttribute {
  scheme_named("abi")
}

///|
pub fn Scheme::bits() -> OgreAttribute {
  scheme_attribute("bits", [Scheme::size()])
}

///|
pub fn Scheme::is_little_endian() -> OgreAttribute {
  scheme_attribute("is-little-endian", [scheme_field("flag", OgreBool)])
}

///|
pub fn Scheme::is_executable() -> OgreAttribute {
  scheme_attribute("is-executable", [scheme_field("flag", OgreBool)])
}

///|
pub fn Scheme::bias() -> OgreAttribute {
  scheme_attribute("bias", [Scheme::off()])
}

///|
pub fn Scheme::segment() -> OgreAttribute {
  scheme_attribute(
    "segment",
    scheme_region(fields=[
      Scheme::readable(),
      Scheme::writable(),
      Scheme::executable(),
    ]),
  )
}

///|
pub fn Scheme::section() -> OgreAttribute {
  scheme_attribute("section", scheme_region())
}

///|
pub fn Scheme::code_start() -> OgreAttribute {
  scheme_attribute("code-start", [Scheme::addr()])
}

///|
pub fn Scheme::entry_point() -> OgreAttribute {
  scheme_attribute("entry-point", [Scheme::addr()])
}

///|
pub fn Scheme::symbol_chunk() -> OgreAttribute {
  scheme_attribute("symbol-chunk", scheme_region(fields=[Scheme::root()]))
}

///|
pub fn Scheme::named_region() -> OgreAttribute {
  scheme_attribute("named-region", scheme_region(fields=[Scheme::name()]))
}

///|
pub fn Scheme::named_symbol() -> OgreAttribute {
  scheme_attribute("named-symbol", [Scheme::addr(), Scheme::name()])
}

///|
pub fn Scheme::mapped() -> OgreAttribute {
  scheme_attribute("mapped", scheme_region(fields=[Scheme::off()]))
}

///|
pub fn Scheme::relocation() -> OgreAttribute {
  scheme_attribute("relocation", [Scheme::fixup(), Scheme::addr()])
}

///|
pub fn Scheme::relative_relocation() -> OgreAttribute {
  scheme_attribute("relative-relocation", [Scheme::fixup()])
}

///|
pub fn Scheme::external_reference() -> OgreAttribute {
  scheme_attribute("external-reference", [Scheme::addr(), Scheme::name()])
}

///|
pub fn Scheme::base_address() -> OgreAttribute {
  scheme_attribute("base-address", [Scheme::addr()])
}

///|
pub fn Scheme::code_region() -> OgreAttribute {
  scheme_attribute("code-region", [
    Scheme::addr(),
    Scheme::size(),
    Scheme::off(),
  ])
}

///|
pub fn Scheme::symbol_value() -> OgreAttribute {
  scheme_attribute("symbol-value", [Scheme::addr(), Scheme::value()])
}

///|
pub fn OgreAttribute::name(self : OgreAttribute) -> String {
  self.name_value
}

///|
pub fn OgreAttribute::fields(self : OgreAttribute) -> Array[OgreField] {
  self.fields_value.copy()
}

///|
pub fn OgreAttribute::field_names(self : OgreAttribute) -> Array[String] {
  self.fields_value.map(field => field.name())
}

///|
pub fn OgreAttribute::declaration(self : OgreAttribute) -> String {
  ogre_render_declaration(self.name_value, self.fields_value)
}

///|
pub fn OgreAttribute::fact(
  self : OgreAttribute,
  values : Array[String],
) -> Result[String, String] {
  if values.length() != self.fields_value.length() {
    return Err("wrong arity for Ogre attribute \{self.name_value}")
  }
  let rendered = []
  for i in 0..<values.length() {
    match ogre_normalize_value(self.fields_value[i].typ(), values[i]) {
      Ok(value) => rendered.push(ogre_render_atom(value))
      Err(reason) => return Err(reason)
    }
  }
  if rendered.is_empty() {
    Ok("(\{ogre_render_atom(self.name_value)})")
  } else {
    Ok("(\{ogre_render_atom(self.name_value)} \{rendered.join(" ")})")
  }
}

///|
pub fn OgreAttribute::named_fact(
  self : OgreAttribute,
  values : Map[String, String],
) -> Result[String, String] {
  if values.length() != self.fields_value.length() {
    return Err("wrong arity for Ogre attribute \{self.name_value}")
  }
  let rendered = []
  for field in self.fields_value {
    match values.get(field.name()) {
      Some(raw) =>
        match ogre_normalize_value(field.typ(), raw) {
          Ok(value) =>
            rendered.push(
              "(\{ogre_render_atom(field.name())} \{ogre_render_atom(value)})",
            )
          Err(reason) => return Err(reason)
        }
      None => return Err("missing Ogre field \{field.name()}")
    }
  }
  if rendered.is_empty() {
    Ok("(\{ogre_render_atom(self.name_value)})")
  } else {
    Ok("(\{ogre_render_atom(self.name_value)} \{rendered.join(" ")})")
  }
}

///|
pub fn OgreDoc::from_scheme(
  attributes : Array[OgreAttribute],
  facts? : Array[String] = [],
) -> Result[OgreDoc, String] {
  let entries = attributes.map(attribute => attribute.declaration())
  for fact in facts {
    entries.push(fact)
  }
  OgreDoc::from_string(entries.join(" "))
}
