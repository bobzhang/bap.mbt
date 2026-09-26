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
  { name_value: name, uuid_value: uuid, _phantom: None, }
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
/// `Spec::domain`, declared once.
let spec_domain_value : @knowledge.Domain[OgreDoc] = @knowledge.Domain::new(
  name=image_name("spec"),
  empty=Some(@ogre.Doc::empty()),
  is_empty=ogre_doc_is_empty,
  order=ogre_doc_order,
  join=ogre_doc_merge,
  inspect=doc => doc.to_string(),
)

///|
/// The flat `bap:spec` domain of image specifications (upstream
/// `Bap_ogre.domain`): documents are joined with `Doc.merge`.
pub fn Spec::domain() -> @knowledge.Domain[OgreDoc] {
  spec_domain_value
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
/// `Spec::slot`, declared once.
let spec_slot_value : @knowledge.Slot[Unit, OgreDoc] = @core_theory.ProgramUnit::cls().property(
  name=image_name("unit-spec"),
  domain=Spec::domain(),
  desc="Ogre image specification of the unit",
  persistent=Spec::persistent(),
  public=true,
)

///|
pub fn Spec::slot() -> @knowledge.Slot[Unit, OgreDoc] {
  spec_slot_value
}
