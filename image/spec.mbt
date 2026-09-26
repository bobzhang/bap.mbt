///|
/// The typed tags of image memory annotations (upstream `Image.segment`,
/// `Image.symbol`, ...): they are universal value tags from `types`.
pub type ImageTag[T] = @types.Tag[T]

///|
pub(all) struct Spec {}

///|
fn image_name(text : String) -> @knowledge.Name {
  @knowledge.Name::create(text, pkg="bap")
}

///|
fn string_image_tag(name : String, uuid : String) -> ImageTag[String] {
  @types.Tag::register(name~, uuid~, encode=x => x, decode=x => Some(x))
}

///|
fn unit_image_tag(name : String, uuid : String) -> ImageTag[Unit] {
  @types.Tag::register(name~, uuid~, encode=_ => "", decode=_ => Some(()))
}

///|
let segment_tag : ImageTag[Segment] = @types.Tag::register_with(
  name="segment",
  uuid="a0eec123-5937-4283-b141-58d579a9b0df",
  show=Segment::to_string,
  compare=Segment::compare,
)

///|
let symbol_tag : ImageTag[String] = string_image_tag(
  "symbol", "768bc13d-d4be-43fc-9f7a-c369ebab9c7e",
)

///|
let function_start_tag : ImageTag[Unit] = unit_image_tag(
  "function-start", "1c1809ec-a38a-4aee-a46c-3d49127ba85a",
)

///|
let symbol_info_tag : ImageTag[Symbol] = @types.Tag::register_with(
  name="symbol-info",
  uuid="706e78cf-07de-4417-a422-effa7821dd02",
  show=Symbol::to_string,
  compare=Symbol::compare,
)

///|
let section_tag : ImageTag[String] = string_image_tag(
  "section", "4014408d-a3af-488f-865b-5413beaf198e",
)

///|
let code_region_tag : ImageTag[Unit] = unit_image_tag(
  "code-region", "5296b7e9-d5c3-40ce-98ba-7655ec68fad7",
)

///|
let file_tag : ImageTag[String] = string_image_tag(
  "file", "c119f700-4069-47ad-ba99-fc29791e0d47",
)

///|
let specification_tag : ImageTag[OgreDoc] = @types.Tag::register_with(
  name="image-specification",
  uuid="a0c98f1f-3693-412a-a11a-2b6c3f6935a7",
  show=OgreDoc::to_string,
  compare=OgreDoc::compare,
  encode=OgreDoc::to_string,
  decode=text => ogre_doc_of_string(text).to_option(),
)

///|
/// The tag of segment annotations (upstream `Image.segment`).
pub fn segment() -> ImageTag[Segment] {
  segment_tag
}

///|
/// The tag of symbol name annotations (upstream `Image.symbol`).
pub fn symbol() -> ImageTag[String] {
  symbol_tag
}

///|
/// The tag of function start annotations (upstream
/// `Image.function_start`).
pub fn function_start() -> ImageTag[Unit] {
  function_start_tag
}

///|
/// The tag of symbol annotations (upstream `Image.symbol_info`).
pub fn symbol_info() -> ImageTag[Symbol] {
  symbol_info_tag
}

///|
/// The tag of section name annotations (upstream `Image.section`).
pub fn section() -> ImageTag[String] {
  section_tag
}

///|
/// The tag of code region annotations (upstream `Image.code_region`).
pub fn code_region() -> ImageTag[Unit] {
  code_region_tag
}

///|
/// The tag of file name annotations (upstream `Image.file`).
pub fn file() -> ImageTag[String] {
  file_tag
}

///|
/// The tag of image specifications (upstream `Image.specification`).
pub fn specification() -> ImageTag[OgreDoc] {
  specification_tag
}

///|
fn ogre_doc_is_empty(doc : OgreDoc) -> Bool {
  doc == @ogre.Doc::empty()
}

///|
fn ogre_doc_order(lhs : OgreDoc, rhs : OgreDoc) -> @knowledge.PartialOrder {
  if lhs == rhs {
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
fn ogre_doc_merge(lhs : OgreDoc, rhs : OgreDoc) -> Result[OgreDoc, String] {
  try lhs.merge(rhs) catch {
    error => Err(error.message())
  } noraise {
    doc => Ok(doc)
  }
}

///|
fn ogre_doc_of_string(text : String) -> Result[OgreDoc, String] {
  try @ogre.Doc::from_string(text) catch {
    error => Err(error.message())
  } noraise {
    doc => Ok(doc)
  }
}

///|
/// The persistence of image specifications: their textual Ogre form
/// (upstream `Bap_ogre` persists documents via `Doc.to_string`).
pub fn Spec::persistent() -> @knowledge.Persistent[OgreDoc] {
  @knowledge.Persistent::create(
    to_string=doc => doc.to_string(),
    of_string=ogre_doc_of_string,
  )
}

///|
/// The flat `bap:spec` domain of image specifications (upstream
/// `Bap_ogre.domain`): documents are joined with `Doc.merge`.
pub fn Spec::domain() -> @knowledge.Domain[OgreDoc] {
  @knowledge.Domain::new(
    name=image_name("spec"),
    empty=Some(@ogre.Doc::empty()),
    is_empty=ogre_doc_is_empty,
    order=ogre_doc_order,
    join=ogre_doc_merge,
    inspect=doc => doc.to_string(),
  )
}

///|
/// The specification of a target (upstream `Spec.from_arch`): its
/// architecture name, address size and endianness, plus the system, ABI
/// and file format when the target defines them.
pub fn Spec::from_arch(arch : @core_theory.Target) -> OgreDoc {
  @ogre.exec(provide_target_facts(arch), @ogre.Doc::empty()) catch {
    error => abort("got a malformed ogre document: \{error.message()}")
  }
}

///|
pub fn Spec::slot() -> @knowledge.Slot[Unit, OgreDoc] {
  @core_theory.ProgramUnit::cls().property(
    name=image_name("unit-spec"),
    domain=Spec::domain(),
    desc="Ogre image specification of the unit",
    persistent=Spec::persistent(),
    public=true,
  )
}
