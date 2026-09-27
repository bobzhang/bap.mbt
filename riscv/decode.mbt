// Native RISC-V decoder producing LLVM MC compatible instructions.
//
// Upstream BAP decodes RISC-V code with the LLVM MC disassembler and lifts
// the resulting `MCInst`s with the Primus Lisp semantics of
// `plugins/riscv/semantics/riscv.lisp`, which are keyed by the LLVM opcode
// names (`ADDI`, `C_ADDI`, `LD`, ...) and take the operands in LLVM's
// order, with `X0`..`X31` register names. The port has no LLVM, so this
// decoder mirrors the relevant part of LLVM's `RISCVDisassembler`: RV32
// and RV64 with the M, A, F, D and C extensions and Zicsr/Zifencei. The
// assembly is the text printed by LLVM's `RISCVInstPrinter`, whose
// compressed instructions are printed as their expansions.

///|
/// The LLVM MC encoding (`Theory.Language`) of RISC-V code for `xlen`.
pub fn encoding(xlen : Xlen) -> @core_theory.Language {
  match xlen {
    RV32 => @core_theory.Language::llvm_riscv32()
    RV64 => @core_theory.Language::llvm_riscv64()
  }
}

///|
/// Decode the (little-endian) instruction at the start of `bytes`, located
/// at `addr`: a 16-bit compressed instruction when the two low bits of the
/// first halfword are not `11` (and `compressed` is set, the default),
/// otherwise a 32-bit one.
///
/// Returns `None` when there are not enough bytes or the encoding is not
/// a valid (or not a supported) instruction.
///
/// ```mbt check
/// test {
///   // c.addi sp, -16
///   guard @riscv.decode(b"\x41\x11", 0x10000UL) is Some(insn) else {
///     fail("invalid")
///   }
///   inspect(insn.name, content="C_ADDI")
///   inspect(insn.assembly, content="addi sp, sp, -16")
///   inspect(insn.size, content="2")
/// }
/// ```
pub fn decode(
  bytes : BytesView,
  addr : UInt64,
  xlen? : Xlen = RV64,
  compressed? : Bool = true,
) -> @mc.Insn? {
  if bytes.length() < 2 {
    return None
  }
  let low = bytes[0].to_uint() | (bytes[1].to_uint() << 8)
  let (result, size) = if (low & 3U) != 3U {
    guard compressed else { return None }
    (decode_compressed(low, xlen), 2)
  } else {
    // longer encodings (bits 4:2 all set) are not supported
    guard (low & 0x1cU) != 0x1cU && bytes.length() >= 4 else { return None }
    let word = low | (bytes[2].to_uint() << 16) | (bytes[3].to_uint() << 24)
    (decode_base(word, xlen), 4)
  }
  match result {
    None => None
    Some(f) =>
      Some(
        @mc.Insn::create(
          f.name,
          f.operands.map(o => o.op),
          addr~,
          size~,
          assembly=f.assembly,
          encoding=encoding(xlen),
          kinds=f.kinds,
          raw=bytes[0:size].to_owned(),
        ),
      )
  }
}

///|
/// The size of the instruction starting with `bytes` (2 or 4), if the
/// bytes hold at least its first halfword.
fn instruction_size(bytes : BytesView) -> Int? {
  if bytes.length() < 2 {
    None
  } else if (bytes[0].to_int() & 3) != 3 {
    Some(2)
  } else {
    Some(4)
  }
}

///|
/// Name of the decoder installed by `register_decoder`.
pub let decoder_name : String = "riscv"

///|
/// Whether the decoder applies to `ctx`: RISC-V targets decoded with an
/// LLVM RISC-V encoding (or an unknown one).
pub fn accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::riscv()) &&
  (
    ctx.encoding.is_unknown() ||
    ctx.encoding == @core_theory.Language::llvm_riscv32() ||
    ctx.encoding == @core_theory.Language::llvm_riscv64()
  )
}

///|
/// The register width implied by `ctx`: RV32 for 32-bit targets or the
/// `llvm-riscv32` encoding, RV64 otherwise.
pub fn xlen_of_context(ctx : @mc.Context) -> Xlen {
  if ctx.target.bits() == 32 ||
    ctx.encoding == @core_theory.Language::llvm_riscv32() {
    RV32
  } else {
    RV64
  }
}

///|
/// The RISC-V decoder for the `@mc` decoder table (see `accepts` and
/// `xlen_of_context`).
pub fn decoder() -> @mc.Decoder {
  @mc.Decoder::create(decoder_name, accepts~, decode=(ctx, bytes, addr) => {
    guard instruction_size(bytes) is Some(size) && bytes.length() >= size else {
      return Truncated
    }
    match decode(bytes, addr, xlen=xlen_of_context(ctx)) {
      Some(insn) => Decoded(insn)
      None => Invalid(size~)
    }
  })
}

///|
/// Register the RISC-V decoder in the `@mc` decoder table. Idempotent:
/// the decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(decoder())
}
