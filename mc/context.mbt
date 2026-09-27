///|
/// The lifting context of an instruction: the target (architecture family,
/// word size and endianness) and the encoding (`Language`) the instruction
/// was decoded with, as in upstream where lifters consult
/// `Theory.Label.target` and `Theory.Label.encoding` of the program label.
///
/// The encoding distinguishes, e.g., ARM (`Language::llvm_a32()`) from Thumb
/// (`Language::llvm_t32()`) instructions of the same `arm` target.
pub struct Context {
  target : @core_theory.Target
  encoding : @core_theory.Language
}

///|
/// `target:encoding`, e.g. `bap:mips:llvm-mips32`.
pub fn Context::to_string(self : Context) -> String {
  "\{self.target.to_string()}:\{self.encoding.to_string()}"
}

///|
/// Create a lifting context. When `encoding` is omitted (or unknown) it
/// defaults to `default_encoding(target)`.
pub fn Context::create(
  target : @core_theory.Target,
  encoding? : @core_theory.Language,
) -> Context {
  let encoding = match encoding {
    Some(language) if !language.is_unknown() => language
    _ => default_encoding(target)
  }
  { target, encoding, }
}

///|
pub fn Context::target(self : Context) -> @core_theory.Target {
  self.target
}

///|
pub fn Context::encoding(self : Context) -> @core_theory.Language {
  self.encoding
}

///|
/// Whether the target is (a descendant of) `family`.
pub fn Context::belongs(self : Context, family : @core_theory.Target) -> Bool {
  self.target.belongs(family)
}

///|
/// Whether the encoding of the context is `language`.
pub fn Context::encoded_as(
  self : Context,
  language : @core_theory.Language,
) -> Bool {
  self.encoding == language
}

///|
/// The encoding an instruction of `target` is decoded with when nothing
/// else is known (upstream: the default `Theory.Label.encoding` provided by
/// the target plugins): `llvm-thumb` for Thumb targets, `llvm-armv7` for
/// other 32-bit ARM targets, `llvm-aarch64` for 64-bit ARM, the LLVM MIPS,
/// PowerPC, SystemZ, x86 and RISC-V encodings for those families, and
/// `Language::unknown()` otherwise.
pub fn default_encoding(target : @core_theory.Target) -> @core_theory.Language {
  let little = target.endianness() is LittleEndian
  if target.belongs(@core_theory.Target::thumb()) ||
    target.belongs(@core_theory.Target::thumbeb()) {
    @core_theory.Language::llvm_t32()
  } else if target.belongs(@core_theory.Target::arm_family()) {
    if target.bits() == 64 {
      @core_theory.Language::llvm_a64()
    } else {
      @core_theory.Language::llvm_a32()
    }
  } else if target.belongs(@core_theory.Target::mips_family()) {
    match (target.bits() == 64, little) {
      (true, true) => @core_theory.Language::llvm_mips64le()
      (true, false) => @core_theory.Language::llvm_mips64()
      (false, true) => @core_theory.Language::llvm_mips32le()
      (false, false) => @core_theory.Language::llvm_mips32()
    }
  } else if target.belongs(@core_theory.Target::powerpc_family()) {
    if target.bits() == 64 {
      @core_theory.Language::llvm_powerpc64()
    } else {
      @core_theory.Language::llvm_powerpc32()
    }
  } else if target.belongs(@core_theory.Target::systemz()) {
    @core_theory.Language::llvm_systemz()
  } else if target.belongs(@core_theory.Target::x86_64()) {
    @core_theory.Language::llvm_x86_64()
  } else if target.belongs(@core_theory.Target::i86()) ||
    target.belongs(@core_theory.Target::x86()) {
    @core_theory.Language::llvm_x86()
  } else if target.belongs(@core_theory.Target::riscv()) {
    if target.bits() == 32 {
      @core_theory.Language::llvm_riscv32()
    } else {
      @core_theory.Language::llvm_riscv64()
    }
  } else {
    @core_theory.Language::unknown()
  }
}
