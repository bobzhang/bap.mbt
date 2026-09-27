// Native MIPS decoder producing LLVM MC compatible instructions.
//
// Upstream BAP decodes MIPS code with the LLVM MC disassembler and lifts
// the resulting `MCInst`s by opcode name. The port has no LLVM, so this
// decoder mirrors the relevant part of LLVM's `MipsDisassembler`: the
// opcode names, operand orders and register names of
// `MipsGenDisassemblerTables`, the branch-target operands of
// `DecodeBranchTarget` (the offset from the branch address), the
// instruction properties (`MCInstrDesc` flags) as `@mc.Kind`s and the
// assembly text of `MipsInstPrinter` (including its preferred aliases such
// as `nop`, `move`, `b`, `beqz`, `bal` and `jalr $25`).
//
// It covers the MIPS32/MIPS64 Release 2 integer ISA, COP0 moves and
// control, the common COP1 instructions, and (with `r6=true`) the Release
// 6 encodings that replace them, including all Release 6 opcodes modeled
// by the lifter. Branches and jumps carry the `delay_slot` of the lifter.

///|
/// The LLVM MC encoding (`Theory.Language`) of MIPS code for `arch` in the
/// byte order `endian`.
pub fn encoding(arch : Arch, endian : @bitvec.Endian) -> @core_theory.Language {
  match (arch, endian) {
    (Mips32, BigEndian) => @core_theory.Language::llvm_mips32()
    (Mips32, LittleEndian) => @core_theory.Language::llvm_mips32le()
    (Mips64, BigEndian) => @core_theory.Language::llvm_mips64()
    (Mips64, LittleEndian) => @core_theory.Language::llvm_mips64le()
  }
}

///|
/// Assemble the instruction word from the first four bytes of `bytes`.
fn read_word(bytes : BytesView, endian : @bitvec.Endian) -> UInt {
  let b0 = bytes[0].to_uint()
  let b1 = bytes[1].to_uint()
  let b2 = bytes[2].to_uint()
  let b3 = bytes[3].to_uint()
  match endian {
    BigEndian => (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    LittleEndian => (b3 << 24) | (b2 << 16) | (b1 << 8) | b0
  }
}

///|
/// Decode the instruction at the start of `bytes`, located at `addr`.
///
/// `arch` selects the MIPS32 or MIPS64 instruction set (and the register
/// classes and FPU mode), `endian` the byte order of the instruction
/// words, and `r6` the Release 6 encodings instead of the Release 2 ones
/// (upstream: the `mips32r6`/`mips64r6` LLVM CPUs).
///
/// Returns `None` when fewer than four bytes are available or the word is
/// not a valid (or not a supported) instruction.
///
/// ```mbt check
/// test {
///   // addiu $sp, $sp, -32
///   guard @mips.decode(b"\x27\xbd\xff\xe0", 0x400000UL) is Some(insn) else {
///     fail("invalid")
///   }
///   inspect(insn.name, content="ADDiu")
///   inspect(insn.assembly, content="addiu $sp, $sp, -32")
/// }
/// ```
pub fn decode(
  bytes : BytesView,
  addr : UInt64,
  arch? : Arch = Mips32,
  endian? : @bitvec.Endian = BigEndian,
  r6? : Bool = false,
) -> @mc.Insn? {
  if bytes.length() < 4 {
    return None
  }
  let word = read_word(bytes, endian)
  match decode_form(word, arch, r6) {
    None => None
    Some(result) =>
      Some(
        @mc.Insn::create(
          result.name,
          result.operands.map(o => o.op),
          addr~,
          size=4,
          assembly=result.assembly(),
          encoding=encoding(arch, endian),
          kinds=result.kinds,
          raw=bytes[0:4].to_owned(),
        ),
      )
  }
}

///|
/// Name of the decoder installed by `register_decoder`.
pub let decoder_name : String = "mips"

///|
/// The MIPS decoder for the `@mc` decoder table: it accepts the contexts
/// accepted by the lifter (`accepts`), and decodes in the mode implied by
/// the context (`mode_of_context`). With `r6` it decodes the Release 6
/// encodings (the default decoder decodes Release 2, like the default
/// LLVM CPUs of the MIPS targets).
pub fn decoder(r6? : Bool = false) -> @mc.Decoder {
  let name = if r6 { decoder_name + "-r6" } else { decoder_name }
  @mc.Decoder::create(name, accepts~, decode=(ctx, bytes, addr) => {
    if bytes.length() < 4 {
      return Truncated
    }
    let (arch, endian) = mode_of_context(ctx)
    match decode(bytes, addr, arch~, endian~, r6~) {
      Some(insn) => Decoded(insn)
      None => Invalid(size=4)
    }
  })
}

///|
/// Register the (Release 2) MIPS decoder in the `@mc` decoder table.
/// Idempotent: the decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(decoder())
}
