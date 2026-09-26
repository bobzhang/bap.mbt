///|
/// The field and attribute vocabulary of BAP image specifications (upstream
/// `Image.Scheme`), expressed as typed `@ogre` fields and attributes.
pub(all) struct Scheme {}

///|
/// A memory region with extra information (upstream `Scheme.region`).
pub(all) struct Region[A] {
  addr : Int64
  size : Int64
  info : A
} derive(Eq, Debug)

///|
pub extend Region with Eq::{equal, not_equal}

///|
pub extend Region with Debug::{to_repr}

///|
fn[A] region(addr : Int64, size : Int64, info : A) -> Region[A] {
  { addr, size, info, }
}

///|
fn int_field(name : String) -> @ogre.Field[Int64] {
  @ogre.def(name, @ogre.Type::int())
}

///|
fn bool_field(name : String) -> @ogre.Field[Bool] {
  @ogre.def(name, @ogre.Type::bool())
}

///|
pub fn Scheme::off() -> @ogre.Field[Int64] {
  int_field("off")
}

///|
pub fn Scheme::size() -> @ogre.Field[Int64] {
  int_field("size")
}

///|
pub fn Scheme::addr() -> @ogre.Field[Int64] {
  int_field("addr")
}

///|
pub fn Scheme::value() -> @ogre.Field[Int64] {
  int_field("value")
}

///|
pub fn Scheme::name() -> @ogre.Field[String] {
  @ogre.def("name", @ogre.Type::str())
}

///|
pub fn Scheme::root() -> @ogre.Field[Int64] {
  int_field("root")
}

///|
pub fn Scheme::fixup() -> @ogre.Field[Int64] {
  int_field("fixup")
}

///|
pub fn Scheme::readable() -> @ogre.Field[Bool] {
  bool_field("r")
}

///|
pub fn Scheme::writable() -> @ogre.Field[Bool] {
  bool_field("w")
}

///|
pub fn Scheme::executable() -> @ogre.Field[Bool] {
  bool_field("x")
}

///|
pub fn Scheme::flag() -> @ogre.Field[Bool] {
  bool_field("flag")
}

///|
fn named_attribute(name : String) -> @ogre.Attribute[String, String] {
  @ogre.Attribute::new(name~, @ogre.scheme(Scheme::name()), x => x)
}

///|
fn int_attribute(
  name : String,
  field : @ogre.Field[Int64],
) -> @ogre.Attribute[Int64, Int64] {
  @ogre.Attribute::new(name~, @ogre.scheme(field), x => x)
}

///|
fn flag_attribute(name : String) -> @ogre.Attribute[Bool, Bool] {
  @ogre.Attribute::new(name~, @ogre.scheme(Scheme::flag()), x => x)
}

///|
pub fn Scheme::arch() -> @ogre.Attribute[String, String] {
  named_attribute("arch")
}

///|
pub fn Scheme::subarch() -> @ogre.Attribute[String, String] {
  named_attribute("subarch")
}

///|
pub fn Scheme::vendor() -> @ogre.Attribute[String, String] {
  named_attribute("vendor")
}

///|
pub fn Scheme::system() -> @ogre.Attribute[String, String] {
  named_attribute("system")
}

///|
pub fn Scheme::format() -> @ogre.Attribute[String, String] {
  named_attribute("format")
}

///|
pub fn Scheme::require() -> @ogre.Attribute[String, String] {
  named_attribute("require")
}

///|
pub fn Scheme::abi() -> @ogre.Attribute[String, String] {
  named_attribute("abi")
}

///|
pub fn Scheme::bits() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("bits", Scheme::size())
}

///|
pub fn Scheme::is_little_endian() -> @ogre.Attribute[Bool, Bool] {
  flag_attribute("is-little-endian")
}

///|
pub fn Scheme::is_executable() -> @ogre.Attribute[Bool, Bool] {
  flag_attribute("is-executable")
}

///|
pub fn Scheme::bias() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("bias", Scheme::off())
}

///|
pub fn Scheme::section() -> @ogre.Attribute[Region[Unit], (Int64, Int64)] {
  @ogre.Attribute::new(
    name="section",
    @ogre.scheme2(Scheme::addr(), Scheme::size()),
    t => region(t.0, t.1, ()),
  )
}

///|
pub fn Scheme::code_start() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("code-start", Scheme::addr())
}

///|
pub fn Scheme::entry_point() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("entry-point", Scheme::addr())
}

///|
pub fn Scheme::symbol_chunk() -> @ogre.Attribute[
  Region[Int64],
  (Int64, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="symbol-chunk",
    @ogre.scheme3(Scheme::addr(), Scheme::size(), Scheme::root()),
    t => region(t.0, t.1, t.2),
  )
}

///|
pub fn Scheme::named_region() -> @ogre.Attribute[
  Region[String],
  (Int64, Int64, String),
] {
  @ogre.Attribute::new(
    name="named-region",
    @ogre.scheme3(Scheme::addr(), Scheme::size(), Scheme::name()),
    t => region(t.0, t.1, t.2),
  )
}

///|
pub fn Scheme::named_symbol() -> @ogre.Attribute[
  (Int64, String),
  (Int64, String),
] {
  @ogre.Attribute::new(
    name="named-symbol",
    @ogre.scheme2(Scheme::addr(), Scheme::name()),
    t => t,
  )
}

///|
pub fn Scheme::segment() -> @ogre.Attribute[
  Region[(Bool, Bool, Bool)],
  (Int64, Int64, Bool, Bool, Bool),
] {
  @ogre.Attribute::new(
    name="segment",
    @ogre.scheme5(
      Scheme::addr(),
      Scheme::size(),
      Scheme::readable(),
      Scheme::writable(),
      Scheme::executable(),
    ),
    t => region(t.0, t.1, (t.2, t.3, t.4)),
  )
}

///|
pub fn Scheme::mapped() -> @ogre.Attribute[Region[Int64], (Int64, Int64, Int64)] {
  @ogre.Attribute::new(
    name="mapped",
    @ogre.scheme3(Scheme::addr(), Scheme::size(), Scheme::off()),
    t => region(t.0, t.1, t.2),
  )
}

///|
pub fn Scheme::code_region() -> @ogre.Attribute[
  (Int64, Int64, Int64),
  (Int64, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="code-region",
    @ogre.scheme3(Scheme::addr(), Scheme::size(), Scheme::off()),
    t => t,
  )
}

///|
pub fn Scheme::relocation() -> @ogre.Attribute[(Int64, Int64), (Int64, Int64)] {
  @ogre.Attribute::new(
    name="relocation",
    @ogre.scheme2(Scheme::fixup(), Scheme::addr()),
    t => t,
  )
}

///|
pub fn Scheme::relative_relocation() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("relative-relocation", Scheme::fixup())
}

///|
pub fn Scheme::external_reference() -> @ogre.Attribute[
  (Int64, String),
  (Int64, String),
] {
  @ogre.Attribute::new(
    name="external-reference",
    @ogre.scheme2(Scheme::addr(), Scheme::name()),
    t => t,
  )
}

///|
pub fn Scheme::base_address() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("base-address", Scheme::addr())
}

///|
pub fn Scheme::symbol_value() -> @ogre.Attribute[(Int64, Int64), (Int64, Int64)] {
  @ogre.Attribute::new(
    name="symbol-value",
    @ogre.scheme2(Scheme::addr(), Scheme::value()),
    t => t,
  )
}
