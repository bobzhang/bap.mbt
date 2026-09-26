// The `llvm:*` attributes of the upstream LLVM loader specification
// (`lib/bap_llvm/llvm_loader.hpp` declares them, `bap_llvm_loader.ml`
// reads them) that the ELF loader does not already use (see
// `elf_spec.mbt`).

///|
fn at_field() -> @ogre.Field[Int64] {
  int_field("at")
}

///|
/// `(llvm:base-address addr)`: the address of the start of the image.
fn llvm_base_address() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("llvm:base-address", Scheme::addr())
}

///|
/// `(llvm:relocation at addr)`: the word at `at` refers to `addr`.
fn llvm_relocation() -> @ogre.Attribute[(Int64, Int64), (Int64, Int64)] {
  @ogre.Attribute::new(
    name="llvm:relocation",
    @ogre.scheme2(at_field(), Scheme::addr()),
    t => t,
  )
}

///|
/// `(llvm:relative-relocation at)`: the word at `at` is relative to the
/// image base.
fn llvm_relative_relocation() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("llvm:relative-relocation", at_field())
}

///|
/// `(llvm:name-reference at name)`: the external symbol `name` is
/// referenced at `at`.
fn llvm_name_reference() -> @ogre.Attribute[(Int64, String), (Int64, String)] {
  @ogre.Attribute::new(
    name="llvm:name-reference",
    @ogre.scheme2(at_field(), Scheme::name()),
    t => t,
  )
}

///|
/// `(llvm:symbol-entry name addr size off value)`: a symbol.
fn llvm_symbol_entry() -> @ogre.Attribute[
  (String, Int64, Int64, Int64, Int64),
  (String, Int64, Int64, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:symbol-entry",
    @ogre.scheme5(
      Scheme::name(),
      Scheme::addr(),
      Scheme::size(),
      Scheme::off(),
      Scheme::value(),
    ),
    t => t,
  )
}

///|
/// `(llvm:segment-command name off size)`: a Mach-O segment as it is in
/// the file.
fn llvm_segment_command() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:segment-command",
    @ogre.scheme3(Scheme::name(), Scheme::off(), Scheme::size()),
    t => t,
  )
}

///|
/// `(llvm:segment-command-flags name r w x)`: the initial protection of a
/// Mach-O segment.
fn llvm_segment_command_flags() -> @ogre.Attribute[
  (String, Bool, Bool, Bool),
  (String, Bool, Bool, Bool),
] {
  @ogre.Attribute::new(
    name="llvm:segment-command-flags",
    @ogre.scheme4(
      Scheme::name(),
      Scheme::readable(),
      Scheme::writable(),
      Scheme::executable(),
    ),
    t => t,
  )
}

///|
/// `(llvm:virtual-segment-command name addr size)`: a Mach-O segment as it
/// is in memory.
fn llvm_virtual_segment_command() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:virtual-segment-command",
    @ogre.scheme3(Scheme::name(), Scheme::addr(), Scheme::size()),
    t => t,
  )
}

///|
/// `(llvm:macho-symbol name value)`: a Mach-O symbol that doesn't belong
/// to any section.
fn llvm_macho_symbol() -> @ogre.Attribute[(String, Int64), (String, Int64)] {
  @ogre.Attribute::new(
    name="llvm:macho-symbol",
    @ogre.scheme2(Scheme::name(), Scheme::value()),
    t => t,
  )
}

///|
/// `(llvm:coff-virtual-section-header name addr size)`: a COFF section as
/// it is in memory.
fn llvm_coff_virtual_section_header() -> @ogre.Attribute[
  (String, Int64, Int64),
  (String, Int64, Int64),
] {
  @ogre.Attribute::new(
    name="llvm:coff-virtual-section-header",
    @ogre.scheme3(Scheme::name(), Scheme::addr(), Scheme::size()),
    t => t,
  )
}

///|
/// `(llvm:function-start addr)`: the start of a function listed by the
/// Mach-O `LC_FUNCTION_STARTS` command.
///
/// This fact is an extension of the port: the upstream LLVM loader does
/// not read the function starts. They become `code-start` facts, i.e.
/// disassembly roots (as they are in upstream `disassemble` rules).
fn llvm_function_start() -> @ogre.Attribute[Int64, Int64] {
  int_attribute("llvm:function-start", Scheme::addr())
}
