// Data processing (immediate): PC-relative addressing, add/subtract,
// logical, move wide, bitfield and extract.

///|
/// `AArch64_AM::isMOVZMovAlias`.
fn is_movz_mov_alias(value : UInt64, shift : Int32, width : Int32) -> Bool {
  let value = if width == 32 { value & 0xFFFFFFFFUL } else { value }
  if value == 0UL && shift != 0 {
    return false
  }
  (value & (0xFFFFUL << shift).lnot()) == 0UL
}

///|
/// `AArch64_AM::isAnyMOVZMovAlias`.
fn is_any_movz_mov_alias(value : UInt64, width : Int32) -> Bool {
  for shift = 0; shift <= width - 16; shift = shift + 16 {
    if is_movz_mov_alias(value, shift, width) {
      return true
    }
  }
  false
}

///|
/// `AArch64_AM::isMOVNMovAlias`.
fn is_movn_mov_alias(value : UInt64, shift : Int32, width : Int32) -> Bool {
  if is_any_movz_mov_alias(value, width) {
    return false
  }
  let value = value.lnot()
  let value = if width == 32 { value & 0xFFFFFFFFUL } else { value }
  is_movz_mov_alias(value, shift, width)
}

///|
/// `AArch64_AM::isAnyMOVWMovAlias`.
fn is_any_movw_mov_alias(value : UInt64, width : Int32) -> Bool {
  if is_any_movz_mov_alias(value, width) {
    return true
  }
  let value = value.lnot()
  let value = if width == 32 { value & 0xFFFFFFFFUL } else { value }
  is_any_movz_mov_alias(value, width)
}

///|
/// A `width`-bit value as a signed decimal immediate.
fn signed_imm_text(value : UInt64, width : Int32) -> String {
  let v = if width == 32 {
    value.reinterpret_as_int64() << 32 >> 32
  } else {
    value.reinterpret_as_int64()
  }
  imm_text(v)
}

///|
/// Data processing (immediate).
fn a64_dp_imm(w : UInt32) -> A64Insn? {
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
      } else if opc == 1 && rn == 31 && !is_any_movw_mov_alias(value, width) {
        "mov \{reg_asm(sf, rd, sp=true)}, \{signed_imm_text(value, width)}"
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
      let plain = "\{base.to_lower()} \{reg_asm(sf, rd)}, #\{imm16}\{shift_text}"
      if opc == 3 {
        return a64(
          base + sz + "i",
          [mc_reg(sf, rd), mc_reg(sf, rd), imm(imm16), imm(shift)],
          plain,
        )
      }
      let shifted = imm16.to_uint64() << shift
      let text = if opc == 2 && is_movz_mov_alias(shifted, shift, width) {
        "mov \{reg_asm(sf, rd)}, \{signed_imm_text(shifted, width)}"
      } else if opc == 0 {
        let value = if sf {
          shifted.lnot()
        } else {
          shifted.lnot() & 0xFFFFFFFFUL
        }
        if is_movn_mov_alias(value, shift, width) {
          "mov \{reg_asm(sf, rd)}, \{signed_imm_text(value, width)}"
        } else {
          plain
        }
      } else {
        plain
      }
      a64(base + sz + "i", [mc_reg(sf, rd), imm(imm16), imm(shift)], text)
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
      if opc == 1 {
        return a64(
          base + sz + "ri",
          [mc_reg(sf, rd), mc_reg(sf, rd), mc_reg(sf, rn), imm(immr), imm(imms)],
          bfm_text(sf, rd, rn, immr, imms),
        )
      }
      a64(
        base + sz + "ri",
        [mc_reg(sf, rd), mc_reg(sf, rn), imm(immr), imm(imms)],
        sbfm_ubfm_text(opc == 0, sf, rd, rn, immr, imms),
      )
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
      let text = if rn == rm {
        "ror \{reg_asm(sf, rd)}, \{reg_asm(sf, rn)}, #\{imms}"
      } else {
        "extr \{reg_asm(sf, rd)}, \{reg_asm(sf, rn)}, \{reg_asm(sf, rm)}, #\{imms}"
      }
      a64(
        "EXTR" + sz + "rri",
        [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), imm(imms)],
        text,
      )
    }
    _ => None
  }
}

///|
/// The assembly of `SBFM`/`UBFM` with LLVM's preferred aliases.
fn sbfm_ubfm_text(
  signed : Bool,
  sf : Bool,
  rd : Int32,
  rn : Int32,
  immr : Int32,
  imms : Int32,
) -> String {
  let d = reg_asm(sf, rd)
  let n = reg_asm(sf, rn)
  let width = if sf { 64 } else { 32 }
  if immr == 0 {
    let ext = match imms {
      7 if signed => Some("sxtb")
      7 if !sf => Some("uxtb")
      15 if signed => Some("sxth")
      15 if !sf => Some("uxth")
      31 if signed && sf => Some("sxtw")
      _ => None
    }
    if ext is Some(ext) {
      return "\{ext} \{d}, \{reg_asm(false, rn)}"
    }
  }
  if !signed && imms != width - 1 && imms + 1 == immr {
    "lsl \{d}, \{n}, #\{width - 1 - imms}"
  } else if imms == width - 1 {
    "\{if signed { "asr" } else { "lsr" }} \{d}, \{n}, #\{immr}"
  } else if immr > imms {
    "\{if signed { "sbfiz" } else { "ubfiz" }} \{d}, \{n}, #\{width - immr}, #\{imms + 1}"
  } else {
    "\{if signed { "sbfx" } else { "ubfx" }} \{d}, \{n}, #\{immr}, #\{imms - immr + 1}"
  }
}

///|
/// The assembly of `BFM` with LLVM's preferred aliases (`bfc` needs the
/// v8.2a features, which are enabled).
fn bfm_text(
  sf : Bool,
  rd : Int32,
  rn : Int32,
  immr : Int32,
  imms : Int32,
) -> String {
  let d = reg_asm(sf, rd)
  let width = if sf { 64 } else { 32 }
  let lsb = (width - immr) % width
  if rn == 31 && (immr == 0 || imms < immr) {
    "bfc \{d}, #\{lsb}, #\{imms + 1}"
  } else if imms < immr {
    "bfi \{d}, \{reg_asm(sf, rn)}, #\{lsb}, #\{imms + 1}"
  } else {
    "bfxil \{d}, \{reg_asm(sf, rn)}, #\{immr}, #\{imms - immr + 1}"
  }
}
