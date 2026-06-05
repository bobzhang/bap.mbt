///|
struct ImageTag[T] {
  name_value : String
  uuid_value : String
  _phantom : T?
}

///|
pub(all) struct Spec {}

///|
fn image_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="bap")
}

///|
fn[T] image_tag(name : String, uuid : String) -> ImageTag[T] {
  { name_value: name, uuid_value: uuid, _phantom: None }
}

///|
pub fn[T] ImageTag::name(self : ImageTag[T]) -> String {
  self.name_value
}

///|
pub fn[T] ImageTag::uuid(self : ImageTag[T]) -> String {
  self.uuid_value
}

///|
pub fn ImageTag::segment() -> ImageTag[Segment] {
  image_tag("segment", "a0eec123-5937-4283-b141-58d579a9b0df")
}

///|
pub fn ImageTag::symbol() -> ImageTag[String] {
  image_tag("symbol", "768bc13d-d4be-43fc-9f7a-c369ebab9c7e")
}

///|
pub fn ImageTag::section() -> ImageTag[String] {
  image_tag("section", "4014408d-a3af-488f-865b-5413beaf198e")
}

///|
pub fn ImageTag::code_region() -> ImageTag[Unit] {
  image_tag("code-region", "5296b7e9-d5c3-40ce-98ba-7655ec68fad7")
}

///|
pub fn ImageTag::specification() -> ImageTag[OgreDoc] {
  image_tag("image-specification", "a0c98f1f-3693-412a-a11a-2b6c3f6935a7")
}

///|
pub fn segment() -> ImageTag[Segment] {
  ImageTag::segment()
}

///|
pub fn symbol() -> ImageTag[String] {
  ImageTag::symbol()
}

///|
pub fn section() -> ImageTag[String] {
  ImageTag::section()
}

///|
pub fn code_region() -> ImageTag[Unit] {
  ImageTag::code_region()
}

///|
pub fn specification() -> ImageTag[OgreDoc] {
  ImageTag::specification()
}

///|
fn ogre_doc_is_empty(doc : OgreDoc) -> Bool {
  doc.declarations_value.length() == 0 && doc.facts_value.length() == 0
}

///|
fn ogre_field_arrays_equal(
  lhs : Array[OgreField],
  rhs : Array[OgreField],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if lhs[i] != rhs[i] {
      return false
    }
  }
  true
}

///|
fn ogre_fact_equal(lhs : OgreFact, rhs : OgreFact) -> Bool {
  lhs.attribute_value == rhs.attribute_value &&
  string_map_equal(lhs.fields_value, rhs.fields_value)
}

///|
fn ogre_fact_arrays_equal(lhs : Array[OgreFact], rhs : Array[OgreFact]) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for i in 0..<lhs.length() {
    if !ogre_fact_equal(lhs[i], rhs[i]) {
      return false
    }
  }
  true
}

///|
fn string_map_equal(
  lhs : Map[String, String],
  rhs : Map[String, String],
) -> Bool {
  if lhs.length() != rhs.length() {
    return false
  }
  for entry in lhs {
    if rhs.get(entry.0) != Some(entry.1) {
      return false
    }
  }
  true
}

///|
fn ogre_doc_equal(lhs : OgreDoc, rhs : OgreDoc) -> Bool {
  if lhs.declarations_value.length() != rhs.declarations_value.length() ||
    lhs.facts_value.length() != rhs.facts_value.length() {
    return false
  }
  for entry in lhs.declarations_value {
    match rhs.declarations_value.get(entry.0) {
      Some(fields) if ogre_field_arrays_equal(entry.1, fields) => ()
      _ => return false
    }
  }
  for entry in lhs.facts_value {
    match rhs.facts_value.get(entry.0) {
      Some(facts) if ogre_fact_arrays_equal(entry.1, facts) => ()
      _ => return false
    }
  }
  true
}

///|
fn ogre_doc_order(lhs : OgreDoc, rhs : OgreDoc) -> @knowledge.PartialOrder {
  if ogre_doc_equal(lhs, rhs) {
    Equal
  } else if ogre_doc_is_empty(lhs) {
    Less
  } else if ogre_doc_is_empty(rhs) {
    Greater
  } else {
    Incomparable
  }
}

///|
fn ogre_field_array_copy(fields : Array[OgreField]) -> Array[OgreField] {
  fields.copy()
}

///|
fn ogre_fact_array_copy(facts : Array[OgreFact]) -> Array[OgreFact] {
  facts.copy()
}

///|
fn ogre_doc_copy_declarations(
  declarations : Map[String, Array[OgreField]],
) -> Map[String, Array[OgreField]] {
  let result : Map[String, Array[OgreField]] = {}
  for entry in declarations {
    result[entry.0] = ogre_field_array_copy(entry.1)
  }
  result
}

///|
fn ogre_doc_copy_facts(
  facts : Map[String, Array[OgreFact]],
) -> Map[String, Array[OgreFact]] {
  let result : Map[String, Array[OgreFact]] = {}
  for entry in facts {
    result[entry.0] = ogre_fact_array_copy(entry.1)
  }
  result
}

///|
fn ogre_doc_merge(lhs : OgreDoc, rhs : OgreDoc) -> Result[OgreDoc, String] {
  if ogre_doc_is_empty(lhs) {
    return Ok(rhs)
  }
  if ogre_doc_is_empty(rhs) {
    return Ok(lhs)
  }
  let declarations = ogre_doc_copy_declarations(lhs.declarations_value)
  for entry in rhs.declarations_value {
    match declarations.get(entry.0) {
      Some(fields) =>
        if !ogre_field_arrays_equal(fields, entry.1) {
          return Err("conflicting Ogre declaration for \{entry.0}")
        }
      None => declarations[entry.0] = ogre_field_array_copy(entry.1)
    }
  }
  let facts = ogre_doc_copy_facts(lhs.facts_value)
  for entry in rhs.facts_value {
    let merged = match facts.get(entry.0) {
      Some(items) => items.copy()
      None => []
    }
    for fact in entry.1 {
      merged.push(fact)
    }
    facts[entry.0] = merged
  }
  Ok({ declarations_value: declarations, facts_value: facts })
}

///|
fn ogre_doc_fact_total(doc : OgreDoc) -> Int {
  let mut total = 0
  for entry in doc.facts_value {
    total += entry.1.length()
  }
  total
}

///|
fn ogre_doc_inspect(doc : OgreDoc) -> String {
  "ogre(declarations=\{doc.declaration_count()}, facts=\{ogre_doc_fact_total(doc)})"
}

///|
fn ogre_atom_needs_quotes(text : String) -> Bool {
  if text.length() == 0 {
    return true
  }
  for char in text {
    if char == ' ' ||
      char == '\n' ||
      char == '\r' ||
      char == '\t' ||
      char == '(' ||
      char == ')' ||
      char == '"' ||
      char == '\\' {
      return true
    }
  }
  false
}

///|
fn ogre_render_atom(text : String) -> String {
  if !ogre_atom_needs_quotes(text) {
    return text
  }
  let builder = StringBuilder()
  builder.write_char('"')
  for char in text {
    match char {
      '"' => builder.write_string("\\\"")
      '\\' => builder.write_string("\\\\")
      '\n' => builder.write_string("\\n")
      '\r' => builder.write_string("\\r")
      '\t' => builder.write_string("\\t")
      other => builder.write_char(other)
    }
  }
  builder.write_char('"')
  builder.to_string()
}

///|
fn[T] ogre_map_keys(items : Map[String, T]) -> Array[String] {
  let keys = []
  for entry in items {
    keys.push(entry.0)
  }
  keys.sort()
  keys
}

///|
fn ogre_render_field(field : OgreField) -> String {
  "(\{ogre_render_atom(field.name())} \{field.typ().to_string()})"
}

///|
fn ogre_render_declaration(name : String, fields : Array[OgreField]) -> String {
  let field_text = fields.map(ogre_render_field).join(" ")
  if field_text == "" {
    "(declare \{ogre_render_atom(name)})"
  } else {
    "(declare \{ogre_render_atom(name)} \{field_text})"
  }
}

///|
fn ogre_render_fact_field(fact : OgreFact, field : OgreField) -> String {
  let value = match fact.value(field.name()) {
    Some(value) => value
    None => ""
  }
  "(\{ogre_render_atom(field.name())} \{ogre_render_atom(value)})"
}

///|
fn ogre_render_fact(doc : OgreDoc, fact : OgreFact) -> String {
  let fields = match doc.declarations_value.get(fact.attribute()) {
    Some(fields) => fields
    None => []
  }
  let field_text = fields
    .map(field => ogre_render_fact_field(fact, field))
    .join(" ")
  if field_text == "" {
    "(\{ogre_render_atom(fact.attribute())})"
  } else {
    "(\{ogre_render_atom(fact.attribute())} \{field_text})"
  }
}

///|
pub fn OgreDoc::to_string(self : OgreDoc) -> String {
  let entries = []
  for name in ogre_map_keys(self.declarations_value) {
    match self.declarations_value.get(name) {
      Some(fields) => entries.push(ogre_render_declaration(name, fields))
      None => ()
    }
  }
  for name in ogre_map_keys(self.facts_value) {
    match self.facts_value.get(name) {
      Some(facts) =>
        for fact in facts {
          entries.push(ogre_render_fact(self, fact))
        }
      None => ()
    }
  }
  entries.join(" ")
}

///|
pub fn OgreDoc::persistent() -> @knowledge.Persistent[OgreDoc] {
  @knowledge.Persistent::create(to_string=doc => doc.to_string(), of_string=input => {
    OgreDoc::from_string(input)
  })
}

///|
pub fn OgreDoc::domain() -> @knowledge.Domain[OgreDoc] {
  @knowledge.Domain::new(
    name=image_name("spec"),
    empty=Some(OgreDoc::empty()),
    is_empty=ogre_doc_is_empty,
    order=ogre_doc_order,
    join=ogre_doc_merge,
    inspect=ogre_doc_inspect,
  )
}

///|
pub fn Spec::from_arch(arch : @core_theory.Target) -> OgreDoc {
  OgreDoc::from_target(arch)
}

///|
pub fn Spec::slot() -> @knowledge.Slot[Unit, OgreDoc] {
  @core_theory.ProgramUnit::cls().property(
    name=image_name("unit-spec"),
    domain=OgreDoc::domain(),
    desc="Ogre image specification of the unit",
    persistent=OgreDoc::persistent(),
    public=true,
  )
}
