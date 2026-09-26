// A native decoder of the A64 instruction set producing the instructions
// of the LLVM AArch64 disassembler (upstream decodes AArch64 code with LLVM
// MC): LLVM opcode names (`SUBSXri`, `LDRXui`, `MADDXrrr`, ...) and operand
// lists as LLVM builds them, which is what the AArch64 Lisp semantics
// (`aarch64-*.lisp`) consume:
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
//   pages;
// - register-offset loads and stores (`ro[WX]`) end with the two extend
//   operands (sign extension, shift).
//
// The decoder covers the base integer instructions: data processing
// (immediate and register), loads and stores (unsigned and unscaled
// offsets, pre/post indexed, register offsets, pairs, literals, compare
// and swap), branches, and the hint, barrier, exception and flag
// manipulation instructions. SIMD/FP, SVE and the other system
// instructions are reported as invalid.

///|
priv struct A64Insn {
  name : String
  ops : Array[@mc.Op]
  text : String
  kinds : Array[@mc.Kind]
}

///|
fn a64(
  name : String,
  ops : Array[@mc.Op],
  text : String,
  kinds? : Array[@mc.Kind] = [],
) -> A64Insn? {
  Some({ name, ops, text, kinds, })
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
fn imm_text(v : Int64) -> String {
  if v < 0L {
    "#-\{-v}"
  } else {
    "#\{v}"
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
/// The kinds of a direct branch with the condition `cond` (14 for none).
fn branch_kinds(conditional : Bool) -> Array[@mc.Kind] {
  if conditional {
    [ConditionalBranch, MayAffectControlFlow]
  } else {
    [UnconditionalBranch, Barrier, Terminator, MayAffectControlFlow]
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
        a64("UDF", [imm(v)], "udf #\{v}", kinds=[
          Barrier,
          Terminator,
          MayAffectControlFlow,
        ])
      } else {
        None
      }
    8 | 9 => a64_dp_imm(word)
    10 | 11 => a64_branch_system(word, addr)
    4 | 6 | 12 | 14 => a64_load_store(word)
    5 | 13 => a64_dp_reg(word)
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
      kinds=d.kinds,
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
/// Data processing (immediate).
fn a64_dp_imm(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let width = if sf { 64 } else { 32 }
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  match fld(w, 23, 3) {
    0 | 1 => {
      let offset = sext((fld(w, 5, 19) << 2) | fld(w, 29, 2), 21)
      if sf {
        a64(
          "ADRP",
          [mc_x(rd), imm(offset)],
          "adrp \{reg_asm(true, rd)}, \{imm_text(offset.to_int64() * 4096L)}",
        )
      } else {
        a64(
          "ADR",
          [mc_x(rd), imm(offset)],
          "adr \{reg_asm(true, rd)}, \{imm_text(offset.to_int64())}",
        )
      }
    }
    2 => {
      let sub = bit(w, 30)
      let s = bit(w, 29)
      let shift = if bit(w, 22) { 12 } else { 0 }
      let imm12 = fld(w, 10, 12)
      let name = (if sub { "SUB" } else { "ADD" }) +
        (if s { "S" } else { "" }) +
        sz +
        "ri"
      let shift_text = if shift == 0 { "" } else { ", lsl #12" }
      let text = if s && rd == 31 {
        "\{if sub { "cmp" } else { "cmn" }} \{reg_asm(sf, rn, sp=true)}, #\{imm12}\{shift_text}"
      } else if !sub && !s && imm12 == 0 && shift == 0 && (rd == 31 || rn == 31) {
        "mov \{reg_asm(sf, rd, sp=true)}, \{reg_asm(sf, rn, sp=true)}"
      } else {
        "\{if sub { "sub" } else { "add" }}\{if s { "s" } else { "" }} \{reg_asm(sf, rd, sp=!s)}, \{reg_asm(sf, rn, sp=true)}, #\{imm12}\{shift_text}"
      }
      a64(
        name,
        [mc_reg(sf, rd, sp=!s), mc_reg(sf, rn, sp=true), imm(imm12), imm(shift)],
        text,
      )
    }
    4 => {
      let opc = fld(w, 29, 2)
      let n = fld(w, 22, 1)
      guard sf || n == 0 else { return None }
      let immr = fld(w, 16, 6)
      let imms = fld(w, 10, 6)
      guard decode_bit_masks(n, imms, immr, width) is Some(value) else {
        return None
      }
      let base = ["AND", "ORR", "EOR", "ANDS"][opc]
      let ands = opc == 3
      let text = if ands && rd == 31 {
        "tst \{reg_asm(sf, rn)}, \{hex_text(value)}"
      } else if opc == 1 && rn == 31 {
        "mov \{reg_asm(sf, rd, sp=true)}, \{hex_text(value)}"
      } else {
        "\{base.to_lower()} \{reg_asm(sf, rd, sp=!ands)}, \{reg_asm(sf, rn)}, \{hex_text(value)}"
      }
      a64(
        base + sz + "ri",
        [
          mc_reg(sf, rd, sp=!ands),
          mc_reg(sf, rn),
          imm((n << 12) | (immr << 6) | imms),
        ],
        text,
      )
    }
    5 => {
      let opc = fld(w, 29, 2)
      let hw = fld(w, 21, 2)
      guard opc != 1 && (sf || hw < 2) else { return None }
      let imm16 = fld(w, 5, 16)
      let shift = hw * 16
      let base = ["MOVN", "", "MOVZ", "MOVK"][opc]
      let shift_text = if shift == 0 { "" } else { ", lsl #\{shift}" }
      let text = "\{base.to_lower()} \{reg_asm(sf, rd)}, #\{imm16}\{shift_text}"
      if opc == 3 {
        a64(
          base + sz + "i",
          [mc_reg(sf, rd), mc_reg(sf, rd), imm(imm16), imm(shift)],
          text,
        )
      } else {
        a64(base + sz + "i", [mc_reg(sf, rd), imm(imm16), imm(shift)], text)
      }
    }
    6 => {
      let opc = fld(w, 29, 2)
      guard opc != 3 && fld(w, 22, 1) == (if sf { 1 } else { 0 }) else {
        return None
      }
      let immr = fld(w, 16, 6)
      let imms = fld(w, 10, 6)
      guard sf || (immr < 32 && imms < 32) else { return None }
      let base = ["SBFM", "BFM", "UBFM"][opc]
      let d = reg_asm(sf, rd)
      let s = reg_asm(sf, rn)
      let text = match opc {
        2 if imms == width - 1 => "lsr \{d}, \{s}, #\{immr}"
        2 if imms + 1 == immr => "lsl \{d}, \{s}, #\{width - 1 - imms}"
        0 if imms == width - 1 => "asr \{d}, \{s}, #\{immr}"
        _ => "\{base.to_lower()} \{d}, \{s}, #\{immr}, #\{imms}"
      }
      if opc == 1 {
        a64(
          base + sz + "ri",
          [mc_reg(sf, rd), mc_reg(sf, rd), mc_reg(sf, rn), imm(immr), imm(imms)],
          text,
        )
      } else {
        a64(
          base + sz + "ri",
          [mc_reg(sf, rd), mc_reg(sf, rn), imm(immr), imm(imms)],
          text,
        )
      }
    }
    7 => {
      guard fld(w, 29, 2) == 0 &&
        !bit(w, 21) &&
        fld(w, 22, 1) == (if sf { 1 } else { 0 }) else {
        return None
      }
      let imms = fld(w, 10, 6)
      guard sf || imms < 32 else { return None }
      let rm = fld(w, 16, 5)
      a64(
        "EXTR" + sz + "rri",
        [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), imm(imms)],
        "extr \{reg_asm(sf, rd)}, \{reg_asm(sf, rn)}, \{reg_asm(sf, rm)}, #\{imms}",
      )
    }
    _ => None
  }
}

///|
/// Branches, exception generation and system instructions.
fn a64_branch_system(w : UInt, _addr : UInt64) -> A64Insn? {
  if fld(w, 26, 5) == 0b00101 {
    let offset = sext(fld(w, 0, 26), 26)
    if bit(w, 31) {
      a64("BL", [imm(offset)], "bl \{imm_text(offset.to_int64() * 4L)}", kinds=[
        Call,
        MayAffectControlFlow,
      ])
    } else {
      a64(
        "B",
        [imm(offset)],
        "b \{imm_text(offset.to_int64() * 4L)}",
        kinds=branch_kinds(false),
      )
    }
  } else if fld(w, 25, 7) == 0b0101010 {
    guard !bit(w, 24) && !bit(w, 4) else { return None }
    let cond = fld(w, 0, 4)
    let offset = sext(fld(w, 5, 19), 19)
    a64(
      "Bcc",
      [imm(cond), imm(offset)],
      "b.\{cond_asm(cond)} \{imm_text(offset.to_int64() * 4L)}",
      kinds=branch_kinds(cond < 14),
    )
  } else if fld(w, 24, 8) == 0b11010100 {
    guard fld(w, 2, 3) == 0 else { return None }
    let v = fld(w, 5, 16)
    match (fld(w, 21, 3), fld(w, 0, 2)) {
      (0, 1) => a64("SVC", [imm(v)], "svc #\{v}", kinds=[MayAffectControlFlow])
      (1, 0) =>
        a64("BRK", [imm(v)], "brk #\{v}", kinds=[
          Barrier,
          Terminator,
          MayAffectControlFlow,
        ])
      (2, 0) => a64("HLT", [imm(v)], "hlt #\{v}")
      _ => None
    }
  } else if fld(w, 22, 10) == 0b1101010100 {
    a64_system(w)
  } else if fld(w, 25, 6) == 0b011010 {
    let sf = bit(w, 31)
    let nz = bit(w, 24)
    let rt = fld(w, 0, 5)
    let offset = sext(fld(w, 5, 19), 19)
    let name = (if nz { "CBNZ" } else { "CBZ" }) + size_char(sf)
    a64(
      name,
      [mc_reg(sf, rt), imm(offset)],
      "\{if nz { "cbnz" } else { "cbz" }} \{reg_asm(sf, rt)}, \{imm_text(offset.to_int64() * 4L)}",
      kinds=branch_kinds(true),
    )
  } else if fld(w, 25, 6) == 0b011011 {
    let b5 = bit(w, 31)
    let nz = bit(w, 24)
    let rt = fld(w, 0, 5)
    let pos = ((if b5 { 1 } else { 0 }) << 5) | fld(w, 19, 5)
    let offset = sext(fld(w, 5, 14), 14)
    let name = (if nz { "TBNZ" } else { "TBZ" }) + size_char(b5)
    a64(
      name,
      [mc_reg(b5, rt), imm(pos), imm(offset)],
      "\{if nz { "tbnz" } else { "tbz" }} \{reg_asm(b5, rt)}, #\{pos}, \{imm_text(offset.to_int64() * 4L)}",
      kinds=branch_kinds(true),
    )
  } else if fld(w, 25, 7) == 0b1101011 {
    guard fld(w, 16, 5) == 31 && fld(w, 10, 6) == 0 && fld(w, 0, 5) == 0 else {
      return None
    }
    let rn = fld(w, 5, 5)
    match fld(w, 21, 4) {
      0 =>
        a64("BR", [mc_x(rn)], "br \{reg_asm(true, rn)}", kinds=[
          IndirectBranch,
          Barrier,
          Terminator,
          MayAffectControlFlow,
        ])
      1 =>
        a64("BLR", [mc_x(rn)], "blr \{reg_asm(true, rn)}", kinds=[
          Call,
          MayAffectControlFlow,
        ])
      2 =>
        a64(
          "RET",
          [mc_x(rn)],
          if rn == 30 {
            "ret"
          } else {
            "ret \{reg_asm(true, rn)}"
          },
          kinds=[Return, Barrier, Terminator, MayAffectControlFlow],
        )
      _ => None
    }
  } else {
    None
  }
}

///|
/// Hints, barriers, `CFINV` and the system register moves.
fn a64_system(w : UInt) -> A64Insn? {
  if w == 0xD500401F {
    a64("CFINV", [], "cfinv")
  } else if (w & 0xFFFFF01F) == 0xD503201F {
    let v = fld(w, 5, 7)
    let text = match v {
      0 => "nop"
      1 => "yield"
      2 => "wfe"
      3 => "wfi"
      4 => "sev"
      5 => "sevl"
      _ => "hint #\{v}"
    }
    a64("HINT", [imm(v)], text)
  } else if (w & 0xFFFFF01F) == 0xD503301F {
    let crm = fld(w, 8, 4)
    let (name, m) = match fld(w, 5, 3) {
      4 => ("DSB", "dsb")
      5 => ("DMB", "dmb")
      6 => ("ISB", "isb")
      _ => return None
    }
    a64(name, [imm(crm)], "\{m} #\{crm}")
  } else if (w & 0xFFF00000) == 0xD5300000 {
    let rt = fld(w, 0, 5)
    let sysreg = fld(w, 5, 15)
    a64("MRS", [mc_x(rt), imm(sysreg)], "mrs \{reg_asm(true, rt)}, s\{sysreg}")
  } else if (w & 0xFFF00000) == 0xD5100000 {
    let rt = fld(w, 0, 5)
    let sysreg = fld(w, 5, 15)
    a64("MSR", [imm(sysreg), mc_x(rt)], "msr s\{sysreg}, \{reg_asm(true, rt)}")
  } else {
    None
  }
}

///|
/// The name of a single-register load or store of the given `size` and
/// `opc` (without the addressing mode suffix), whether it loads, and
/// whether the transfer register is 64-bit. `unscaled` selects the
/// `LDUR`/`STUR` spelling.
fn a64_ldst_name(
  size : Int,
  opc : Int,
  unscaled : Bool,
) -> (String, Bool, Bool)? {
  let (op, suffix, load, sf) = match (size, opc) {
    (0, 0) => ("STR", "BB", false, false)
    (0, 1) => ("LDR", "BB", true, false)
    (0, 2) => ("LDR", "SBX", true, true)
    (0, 3) => ("LDR", "SBW", true, false)
    (1, 0) => ("STR", "HH", false, false)
    (1, 1) => ("LDR", "HH", true, false)
    (1, 2) => ("LDR", "SHX", true, true)
    (1, 3) => ("LDR", "SHW", true, false)
    (2, 0) => ("STR", "W", false, false)
    (2, 1) => ("LDR", "W", true, false)
    (2, 2) => ("LDR", "SW", true, true)
    (3, 0) => ("STR", "X", false, true)
    (3, 1) => ("LDR", "X", true, true)
    _ => return None
  }
  let op = if unscaled { if op == "LDR" { "LDUR" } else { "STUR" } } else { op }
  Some((op + suffix, load, sf))
}

///|
/// The assembly mnemonic of a single-register load or store.
fn a64_ldst_mnemonic(name : String) -> String {
  let op = if name.has_prefix("LDUR") {
    "ldur"
  } else if name.has_prefix("STUR") {
    "stur"
  } else if name.has_prefix("LDR") {
    "ldr"
  } else {
    "str"
  }
  let suffix = if name.has_suffix("BB") {
    "b"
  } else if name.has_suffix("HH") {
    "h"
  } else if name.has_suffix("SBX") || name.has_suffix("SBW") {
    "sb"
  } else if name.has_suffix("SHX") || name.has_suffix("SHW") {
    "sh"
  } else if name.has_suffix("SW") {
    "sw"
  } else {
    ""
  }
  op + suffix
}

///|
/// Loads and stores.
fn a64_load_store(w : UInt) -> A64Insn? {
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base_text = reg_asm(true, rn, sp=true)
  if (w & 0x3FA07C00) == 0x08A07C00 {
    // compare and swap
    let size = fld(w, 30, 2)
    let sf = size == 3
    let rs = fld(w, 16, 5)
    let acquire = bit(w, 22)
    let release = bit(w, 15)
    let name = "CAS" +
      (if acquire { "A" } else { "" }) +
      (if release { "L" } else { "" }) +
      ["B", "H", "W", "X"][size]
    let suffix = ["b", "h", "", ""][size]
    return a64(
      name,
      [mc_reg(sf, rs), mc_reg(sf, rs), mc_reg(sf, rt), mc_x(rn, sp=true)],
      "cas\{if acquire { "a" } else { "" }}\{if release { "l" } else { "" }}\{suffix} \{reg_asm(sf, rs)}, \{reg_asm(sf, rt)}, [\{base_text}]",
      kinds=[MayLoad, MayStore],
    )
  }
  if bit(w, 26) {
    // SIMD and floating point
    return None
  }
  match fld(w, 27, 3) {
    0b101 => {
      // load/store pair
      let opc = fld(w, 30, 2)
      let mode = fld(w, 23, 2)
      let load = bit(w, 22)
      guard mode != 0 else { return None }
      let (kind, sf, scale) = match opc {
        0 => ("W", false, 4)
        1 if load => ("SW", true, 4)
        2 => ("X", true, 8)
        _ => return None
      }
      let offset = sext(fld(w, 15, 7), 7)
      let rt2 = fld(w, 10, 5)
      let name = (if load { "LDP" } else { "STP" }) +
        kind +
        ["", "post", "i", "pre"][mode]
      let m = (if load { "ldp" } else { "stp" }) +
        (if opc == 1 { "sw" } else { "" })
      let regs = "\{reg_asm(sf, rt)}, \{reg_asm(sf, rt2)}"
      let off = imm_text((offset * scale).to_int64())
      let kinds : Array[@mc.Kind] = if load { [MayLoad] } else { [MayStore] }
      if mode == 2 {
        a64(
          name,
          [mc_reg(sf, rt), mc_reg(sf, rt2), mc_x(rn, sp=true), imm(offset)],
          "\{m} \{regs}, [\{base_text}, \{off}]",
          kinds~,
        )
      } else {
        a64(
          name,
          [
            mc_x(rn, sp=true),
            mc_reg(sf, rt),
            mc_reg(sf, rt2),
            mc_x(rn, sp=true),
            imm(offset),
          ],
          if mode == 3 {
            "\{m} \{regs}, [\{base_text}, \{off}]!"
          } else {
            "\{m} \{regs}, [\{base_text}], \{off}"
          },
          kinds~,
        )
      }
    }
    0b011 => {
      // load register (literal)
      guard fld(w, 24, 2) == 0 else { return None }
      let offset = sext(fld(w, 5, 19), 19)
      let off = imm_text(offset.to_int64() * 4L)
      match fld(w, 30, 2) {
        0 =>
          a64(
            "LDRWl",
            [mc_w(rt), imm(offset)],
            "ldr \{reg_asm(false, rt)}, \{off}",
            kinds=[MayLoad],
          )
        1 =>
          a64(
            "LDRXl",
            [mc_x(rt), imm(offset)],
            "ldr \{reg_asm(true, rt)}, \{off}",
            kinds=[MayLoad],
          )
        2 =>
          a64(
            "LDRSWl",
            [mc_x(rt), imm(offset)],
            "ldrsw \{reg_asm(true, rt)}, \{off}",
            kinds=[MayLoad],
          )
        _ => a64("PRFMl", [imm(rt), imm(offset)], "prfm #\{rt}, \{off}")
      }
    }
    0b111 => {
      let size = fld(w, 30, 2)
      let opc = fld(w, 22, 2)
      if fld(w, 24, 2) == 1 {
        // unsigned offset
        let imm12 = fld(w, 10, 12)
        if (size, opc) == (3, 2) {
          return a64(
            "PRFMui",
            [imm(rt), mc_x(rn, sp=true), imm(imm12)],
            "prfm #\{rt}, [\{base_text}, #\{imm12 * 8}]",
          )
        }
        guard a64_ldst_name(size, opc, false) is Some((name, load, sf)) else {
          return None
        }
        a64(
          name + "ui",
          [mc_reg(sf, rt), mc_x(rn, sp=true), imm(imm12)],
          "\{a64_ldst_mnemonic(name)} \{reg_asm(sf, rt)}, [\{base_text}, #\{imm12 << size}]",
          kinds=if load { [MayLoad] } else { [MayStore] },
        )
      } else if fld(w, 24, 2) == 0 && !bit(w, 21) {
        let simm9 = sext(fld(w, 12, 9), 9)
        let mode = fld(w, 10, 2)
        guard mode != 2 else { return None }
        guard a64_ldst_name(size, opc, mode == 0) is Some((name, load, sf)) else {
          return None
        }
        let m = a64_ldst_mnemonic(name)
        let t = reg_asm(sf, rt)
        let kinds : Array[@mc.Kind] = if load { [MayLoad] } else { [MayStore] }
        match mode {
          0 =>
            a64(
              name + "i",
              [mc_reg(sf, rt), mc_x(rn, sp=true), imm(simm9)],
              "\{m} \{t}, [\{base_text}, \{imm_text(simm9.to_int64())}]",
              kinds~,
            )
          _ => {
            let pre = mode == 3
            a64(
              name + (if pre { "pre" } else { "post" }),
              [mc_x(rn, sp=true), mc_reg(sf, rt), mc_x(rn, sp=true), imm(simm9)],
              if pre {
                "\{m} \{t}, [\{base_text}, \{imm_text(simm9.to_int64())}]!"
              } else {
                "\{m} \{t}, [\{base_text}], \{imm_text(simm9.to_int64())}"
              },
              kinds~,
            )
          }
        }
      } else if fld(w, 24, 2) == 0 && bit(w, 21) && fld(w, 10, 2) == 2 {
        // register offset
        let option = fld(w, 13, 3)
        guard (option & 2) != 0 else { return None }
        guard a64_ldst_name(size, opc, false) is Some((name, load, sf)) else {
          return None
        }
        let x = (option & 1) == 1
        let rm = fld(w, 16, 5)
        let sign = option >> 2
        let shift = fld(w, 12, 1)
        let ext_name = match option {
          2 => "uxtw"
          3 => "lsl"
          6 => "sxtw"
          _ => "sxtx"
        }
        let amount = if shift == 1 { " #\{size}" } else { "" }
        let ext_text = if option == 3 && shift == 0 {
          ""
        } else {
          ", \{ext_name}\{amount}"
        }
        a64(
          name + (if x { "roX" } else { "roW" }),
          [
            mc_reg(sf, rt),
            mc_x(rn, sp=true),
            mc_reg(x, rm),
            imm(sign),
            imm(shift),
          ],
          "\{a64_ldst_mnemonic(name)} \{reg_asm(sf, rt)}, [\{base_text}, \{reg_asm(x, rm)}\{ext_text}]",
          kinds=if load { [MayLoad] } else { [MayStore] },
        )
      } else {
        None
      }
    }
    _ => None
  }
}

///|
/// Data processing (register).
fn a64_dp_reg(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let rm = fld(w, 16, 5)
  let d = reg_asm(sf, rd)
  let n = reg_asm(sf, rn)
  let m = reg_asm(sf, rm)
  let shift_names = ["lsl", "lsr", "asr", "ror"]
  if !bit(w, 28) {
    let shift = fld(w, 22, 2)
    let imm6 = fld(w, 10, 6)
    let shift_text = if imm6 == 0 && shift == 0 {
      ""
    } else {
      ", \{shift_names[shift]} #\{imm6}"
    }
    if !bit(w, 24) {
      // logical (shifted register)
      guard sf || imm6 < 32 else { return None }
      let opc = fld(w, 29, 2)
      let inverted = bit(w, 21)
      let base = [
          ["AND", "BIC"],
          ["ORR", "ORN"],
          ["EOR", "EON"],
          ["ANDS", "BICS"],
        ][opc][if inverted {
          1
        } else {
          0
        }]
      let text = if opc == 1 && rn == 31 && shift_text == "" {
        if inverted {
          "mvn \{d}, \{m}"
        } else {
          "mov \{d}, \{m}"
        }
      } else if opc == 3 && !inverted && rd == 31 {
        "tst \{n}, \{m}\{shift_text}"
      } else {
        "\{base.to_lower()} \{d}, \{n}, \{m}\{shift_text}"
      }
      a64(
        base + sz + "rs",
        [
          mc_reg(sf, rd),
          mc_reg(sf, rn),
          mc_reg(sf, rm),
          imm((shift << 6) | imm6),
        ],
        text,
      )
    } else if !bit(w, 21) {
      // add/subtract (shifted register)
      guard shift != 3 && (sf || imm6 < 32) else { return None }
      let sub = bit(w, 30)
      let s = bit(w, 29)
      let name = (if sub { "SUB" } else { "ADD" }) +
        (if s { "S" } else { "" }) +
        sz +
        "rs"
      let text = if s && rd == 31 {
        "\{if sub { "cmp" } else { "cmn" }} \{n}, \{m}\{shift_text}"
      } else if sub && rn == 31 {
        "neg\{if s { "s" } else { "" }} \{d}, \{m}\{shift_text}"
      } else {
        "\{if sub { "sub" } else { "add" }}\{if s { "s" } else { "" }} \{d}, \{n}, \{m}\{shift_text}"
      }
      a64(
        name,
        [
          mc_reg(sf, rd),
          mc_reg(sf, rn),
          mc_reg(sf, rm),
          imm((shift << 6) | imm6),
        ],
        text,
      )
    } else {
      // add/subtract (extended register)
      guard fld(w, 22, 2) == 0 else { return None }
      let option = fld(w, 13, 3)
      let amount = fld(w, 10, 3)
      guard amount <= 4 else { return None }
      let sub = bit(w, 30)
      let s = bit(w, 29)
      let x64 = sf && (option & 3) == 3
      let name = (if sub { "SUB" } else { "ADD" }) +
        (if s { "S" } else { "" }) +
        sz +
        "rx" +
        (if x64 { "64" } else { "" })
      let ext = ["uxtb", "uxth", "uxtw", "uxtx", "sxtb", "sxth", "sxtw", "sxtx"][option]
      let amount_text = if amount == 0 { "" } else { " #\{amount}" }
      a64(
        name,
        [
          mc_reg(sf, rd, sp=!s),
          mc_reg(sf, rn, sp=true),
          mc_reg(x64, rm),
          imm((option << 3) | amount),
        ],
        "\{if sub { "sub" } else { "add" }}\{if s { "s" } else { "" }} \{reg_asm(sf, rd, sp=!s)}, \{reg_asm(sf, rn, sp=true)}, \{reg_asm(x64, rm)}, \{ext}\{amount_text}",
      )
    }
  } else if bit(w, 24) {
    // data processing (3 source)
    guard fld(w, 29, 2) == 0 else { return None }
    let ra = fld(w, 10, 5)
    let o0 = bit(w, 15)
    let a = reg_asm(sf, ra)
    match (fld(w, 21, 3), o0) {
      (0, _) => {
        let base = if o0 { "MSUB" } else { "MADD" }
        let text = if ra == 31 {
          "\{if o0 { "mneg" } else { "mul" }} \{d}, \{n}, \{m}"
        } else {
          "\{base.to_lower()} \{d}, \{n}, \{m}, \{a}"
        }
        a64(
          base + sz + "rrr",
          [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), mc_reg(sf, ra)],
          text,
        )
      }
      (1 | 5 as op, _) => {
        guard sf else { return None }
        let name = (if op == 1 { "S" } else { "U" }) +
          (if o0 { "MSUBL" } else { "MADDL" })
        a64(
          name + "rrr",
          [mc_x(rd), mc_w(rn), mc_w(rm), mc_x(ra)],
          "\{name.to_lower()} \{reg_asm(true, rd)}, \{reg_asm(false, rn)}, \{reg_asm(false, rm)}, \{reg_asm(true, ra)}",
        )
      }
      (2 | 6 as op, false) => {
        guard sf && ra == 31 else { return None }
        let name = if op == 2 { "SMULH" } else { "UMULH" }
        a64(
          name + "rr",
          [mc_x(rd), mc_x(rn), mc_x(rm)],
          "\{name.to_lower()} \{d}, \{n}, \{m}",
        )
      }
      _ => None
    }
  } else {
    match fld(w, 21, 4) {
      0 =>
        if fld(w, 10, 6) == 0 {
          let sbc = bit(w, 30)
          let s = bit(w, 29)
          let name = (if sbc { "SBC" } else { "ADC" }) +
            (if s { "S" } else { "" })
          a64(
            name + sz + "r",
            [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm)],
            "\{name.to_lower()} \{d}, \{n}, \{m}",
          )
        } else if fld(w, 10, 5) == 1 && fld(w, 29, 3) == 0b101 && !bit(w, 4) {
          let imm6 = fld(w, 15, 6)
          let mask = fld(w, 0, 4)
          a64(
            "RMIF",
            [mc_x(rn), imm(imm6), imm(mask)],
            "rmif \{reg_asm(true, rn)}, #\{imm6}, #\{mask}",
          )
        } else if fld(w, 10, 4) == 0b0010 &&
          fld(w, 29, 3) == 0b001 &&
          fld(w, 15, 6) == 0 &&
          fld(w, 0, 5) == 0b01101 {
          let name = if bit(w, 14) { "SETF16" } else { "SETF8" }
          a64(name, [mc_w(rn)], "\{name.to_lower()} \{reg_asm(false, rn)}")
        } else {
          None
        }
      2 => {
        // conditional compare
        guard bit(w, 29) && !bit(w, 10) && !bit(w, 4) else { return None }
        let cmp = if bit(w, 30) { "CCMP" } else { "CCMN" }
        let cond = fld(w, 12, 4)
        let nzcv = fld(w, 0, 4)
        if bit(w, 11) {
          a64(
            cmp + sz + "i",
            [mc_reg(sf, rn), imm(rm), imm(nzcv), imm(cond)],
            "\{cmp.to_lower()} \{n}, #\{rm}, #\{nzcv}, \{cond_asm(cond)}",
          )
        } else {
          a64(
            cmp + sz + "r",
            [mc_reg(sf, rn), mc_reg(sf, rm), imm(nzcv), imm(cond)],
            "\{cmp.to_lower()} \{n}, \{m}, #\{nzcv}, \{cond_asm(cond)}",
          )
        }
      }
      4 => {
        // conditional select
        guard !bit(w, 29) && !bit(w, 11) else { return None }
        let cond = fld(w, 12, 4)
        let base = match (bit(w, 30), bit(w, 10)) {
          (false, false) => "CSEL"
          (false, true) => "CSINC"
          (true, false) => "CSINV"
          (true, true) => "CSNEG"
        }
        a64(
          base + sz + "r",
          [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), imm(cond)],
          "\{base.to_lower()} \{d}, \{n}, \{m}, \{cond_asm(cond)}",
        )
      }
      6 =>
        if !bit(w, 30) {
          // data processing (2 source)
          guard !bit(w, 29) else { return None }
          let base = match fld(w, 10, 6) {
            2 => "UDIV"
            3 => "SDIV"
            8 => "LSLV"
            9 => "LSRV"
            10 => "ASRV"
            11 => "RORV"
            _ => return None
          }
          a64(
            base + sz + "r",
            [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm)],
            "\{base.to_lower()} \{d}, \{n}, \{m}",
          )
        } else {
          // data processing (1 source)
          guard !bit(w, 29) && rm == 0 else { return None }
          let (name, mnemonic) = match (fld(w, 10, 6), sf) {
            (0, _) => ("RBIT" + sz + "r", "rbit")
            (1, _) => ("REV16" + sz + "r", "rev16")
            (2, true) => ("REV32Xr", "rev32")
            (2, false) => ("REVWr", "rev")
            (3, true) => ("REVXr", "rev")
            (4, _) => ("CLZ" + sz + "r", "clz")
            (5, _) => ("CLS" + sz + "r", "cls")
            _ => return None
          }
          a64(name, [mc_reg(sf, rd), mc_reg(sf, rn)], "\{mnemonic} \{d}, \{n}")
        }
      _ => None
    }
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
