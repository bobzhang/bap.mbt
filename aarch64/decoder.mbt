// A native decoder of the A64 instruction set producing the instructions
// of the LLVM AArch64 disassembler (upstream decodes AArch64 code with LLVM
// MC, with the `+v8.1a,+v8.2a,+v8.3a` target features): LLVM opcode names
// (`SUBSXri`, `LDRXui`, `MADDXrrr`, ...), operand lists as LLVM builds
// them, which is what the AArch64 Lisp semantics (`aarch64-*.lisp`)
// consume, the assembly text of LLVM's instruction printer (with its
// preferred aliases) and the kinds of LLVM's `MCInstrDesc`:
//
// - registers are named as in `registers.mbt`; register 31 is `SP`/`WSP`
//   or `XZR`/`WZR` depending on the operand class;
// - immediates are the encoded fields: `imm12` and its shift amount (0 or
//   12) for add/sub, `ARM_AM::getShifterImm` (`type << 6 | amount`) for
//   shifted registers, `getArithExtendImm` (`option << 3 | amount`) for
//   extended registers, the 13-bit `N:immr:imms` for logical immediates,
//   `imm16` and the shift amount (`hw * 16`) for wide moves, unscaled
//   (element count) unsigned offsets, signed `imm7`/`imm9` offsets, branch
//   offsets in instructions (`imm26`, `imm19`, `imm14`), `ADRP` offsets in
//   pages, the 16-bit `op0:op1:CRn:CRm:op2` of system registers;
// - register-offset loads and stores (`ro[WX]`) end with the two extend
//   operands (sign extension, shift);
// - writeback loads and stores (`pre`/`post`) start with the written back
//   base register.
//
// The decoder covers the whole instruction set that LLVM decodes with
// those features: data processing (immediate and
// register, including CRC32 and pointer authentication), loads and stores
// (all addressing modes, exclusives, load-acquire/store-release, LSE
// atomics and compare and swap, `LDRAA`/`LDRAB`, prefetches), branches,
// exception generation and the system instructions (hints, barriers,
// `PSTATE` moves, `SYS`/`SYSL` with their `AT`/`DC`/`IC`/`TLBI` aliases and
// `MRS`/`MSR` with named system registers). The FlagM instructions
// `CFINV`, `RMIF` and `SETF8`/`SETF16` are decoded too (the Lisp semantics
// define them) although they need `+flagm`. The floating-point and
// Advanced SIMD instructions (`simd.mbt`) use the same register names
// (`B0`..`Q31`, and `D0_D1`-style lists for the structure loads and
// stores). SVE and SME instructions, and the extensions that upstream does
// not enable (half-precision arithmetic, dot product, cryptography, ...),
// are reported as invalid, as LLVM does.

///|
priv struct A64Insn {
  name : String
  ops : Array[@mc.Op]
  text : String
}

///|
fn a64(name : String, ops : Array[@mc.Op], text : String) -> A64Insn? {
  Some({ name, ops, text, })
}

///|
fn fld(w : UInt, lo : Int, len : Int) -> Int {
  ((w >> lo) & ((1U << len) - 1)).reinterpret_as_int()
}

///|
fn bit(w : UInt, n : Int) -> Bool {
  ((w >> n) & 1) == 1
}

///|
fn sext(v : Int, bits : Int) -> Int {
  v << (32 - bits) >> (32 - bits)
}

///|
fn imm(v : Int) -> @mc.Op {
  Imm(v.to_int64())
}

///|
/// A signed decimal immediate (`#-8`, `#16`).
fn imm_text(v : Int64) -> String {
  "#\{v}"
}

///|
/// A hexadecimal immediate as LLVM's `printImmHex` prints it (`#%#llx`:
/// zero has no `0x` prefix).
fn hex_imm(v : Int) -> String {
  if v == 0 {
    "#0"
  } else {
    "#0x" + v.to_string(radix=16)
  }
}

///|
fn hex_text(v : UInt64) -> String {
  "#0x" + v.to_string(radix=16)
}

///|
fn size_char(sf : Bool) -> String {
  if sf {
    "X"
  } else {
    "W"
  }
}

///|
/// `DecodeBitMasks` of the ARM ARM (the immediate of a logical
/// instruction): the value of `N:immr:imms` for a `width`-bit register,
/// `None` for reserved encodings.
pub fn decode_bit_masks(
  n : Int,
  imms : Int,
  immr : Int,
  width : Int,
) -> UInt64? {
  let combined = (n << 6) | (imms.lnot() & 0x3F)
  guard combined != 0 else { return None }
  let len = 31 - combined.clz()
  guard len >= 1 else { return None }
  let esize = 1 << len
  guard esize <= width else { return None }
  let levels = esize - 1
  guard (imms & levels) != levels else { return None }
  let s = imms & levels
  let r = immr & levels
  let emask = if esize == 64 {
    0xFFFFFFFFFFFFFFFFUL
  } else {
    (1UL << esize) - 1
  }
  let welem = (1UL << (s + 1)) - 1
  let rotated = if r == 0 {
    welem
  } else {
    ((welem >> r) | (welem << (esize - r))) & emask
  }
  let mut value = 0UL
  for pos = 0; pos < width; pos = pos + esize {
    value = value | (rotated << pos)
  }
  Some(if width == 64 { value } else { value & 0xFFFFFFFFUL })
}

///|
/// Decodes the A64 instruction word `word` located at `addr`. The raw
/// bytes are the little-endian bytes of the word unless `raw` is given.
pub fn decode_a64_word(
  word : UInt,
  addr? : UInt64 = 0,
  raw? : Bytes,
) -> @mc.Insn? {
  let decoded = match fld(word, 25, 4) {
    0 =>
      if word >> 16 == 0 {
        let v = fld(word, 0, 16)
        a64("UDF", [imm(v)], "udf #\{v}")
      } else {
        None
      }
    8 | 9 => a64_dp_imm(word)
    10 | 11 => a64_branch_system(word)
    4 | 6 | 12 | 14 => a64_load_store(word)
    5 | 13 => a64_dp_reg(word)
    7 | 15 => a64_simd(word)
    _ => None
  }
  let raw = match raw {
    Some(raw) => raw
    None => Bytes::makei(4, i => (word >> (8 * i)).to_byte())
  }
  decoded.map(d => {
    @mc.Insn::create(
      d.name,
      d.ops,
      addr~,
      size=4,
      assembly=d.text,
      encoding=@core_theory.Language::llvm_a64(),
      kinds=a64_kinds(d.name),
      raw~,
    )
  })
}

///|
/// Decodes the A64 instruction at the start of `bytes` loaded at `addr`.
/// Instructions are always little-endian (also on big-endian targets).
pub fn decode_a64(bytes : BytesView, addr? : UInt64 = 0) -> @mc.Decoded {
  if bytes.length() < 4 {
    return Truncated
  }
  let word = bytes[0].to_uint() |
    (bytes[1].to_uint() << 8) |
    (bytes[2].to_uint() << 16) |
    (bytes[3].to_uint() << 24)
  match decode_a64_word(word, addr~, raw=bytes[:4].to_owned()) {
    Some(insn) => Decoded(insn)
    None => Invalid(size=4)
  }
}

///|
/// Name of the A64 decoder installed by `register_decoder`.
pub let a64_decoder_name : String = "aarch64-a64"

///|
/// Whether the A64 decoder applies to `ctx`: 64-bit targets of the ARM
/// family decoded as AArch64 (`llvm-aarch64`) instructions.
pub fn a64_decoder_accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::arm_family()) &&
  ctx.target.bits() == 64 &&
  ctx.encoding == @core_theory.Language::llvm_a64()
}

///|
/// The A64 decoder (see `decode_a64`).
pub fn a64_decoder() -> @mc.Decoder {
  @mc.Decoder::create(a64_decoder_name, accepts=a64_decoder_accepts, decode=(
    _,
    bytes,
    addr,
  ) => decode_a64(bytes, addr~))
}

///|
/// Registers the A64 decoder with `@mc.register_decoder`. Idempotent: the
/// decoder is replaced by name.
pub fn register_decoder() -> Unit {
  @mc.register_decoder(a64_decoder())
}

///|
/// `s` without its last `n` characters.
fn chop(s : String, n : Int) -> String {
  s[:s.length() - n].to_owned()
}
