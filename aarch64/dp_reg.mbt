// Data processing (register): logical and add/subtract (shifted and
// extended register), add/subtract with carry, conditional compare and
// select, one, two and three source operations.

///|
/// The shift suffix of a shifted register operand (`ARM_AM` shifter
/// immediates print nothing for `lsl #0`).
fn shift_suffix(shift : Int, amount : Int) -> String {
  if shift == 0 && amount == 0 {
    ""
  } else {
    ", \{["lsl", "lsr", "asr", "ror"][shift]} #\{amount}"
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
  if !bit(w, 28) {
    let shift = fld(w, 22, 2)
    let imm6 = fld(w, 10, 6)
    let shift_text = shift_suffix(shift, imm6)
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
      let text = if opc == 1 && !inverted && rn == 31 && shift_text == "" {
        "mov \{d}, \{m}"
      } else if opc == 1 && inverted && rn == 31 {
        "mvn \{d}, \{m}\{shift_text}"
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
      a64_add_sub_extended(w)
    }
  } else if bit(w, 24) {
    a64_dp_3src(w)
  } else {
    match fld(w, 21, 4) {
      0 =>
        if fld(w, 10, 6) == 0 {
          let sbc = bit(w, 30)
          let s = bit(w, 29)
          let name = (if sbc { "SBC" } else { "ADC" }) +
            (if s { "S" } else { "" })
          let text = if sbc && rn == 31 {
            "ngc\{if s { "s" } else { "" }} \{d}, \{m}"
          } else {
            "\{name.to_lower()} \{d}, \{n}, \{m}"
          }
          a64(
            name + sz + "r",
            [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm)],
            text,
          )
        } else if fld(w, 10, 5) == 1 && fld(w, 29, 3) == 0b101 && !bit(w, 4) {
          // FlagM (not enabled in upstream's LLVM features)
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
          // FlagM (not enabled in upstream's LLVM features)
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
        let op = bit(w, 30)
        let o2 = bit(w, 10)
        let base = match (op, o2) {
          (false, false) => "CSEL"
          (false, true) => "CSINC"
          (true, false) => "CSINV"
          (true, true) => "CSNEG"
        }
        let inv = cond_asm(cond ^ 1)
        let text = if (o2 || op) && cond < 14 && rn == rm {
          if rn == 31 && !(op && o2) {
            "\{if op { "csetm" } else { "cset" }} \{d}, \{inv}"
          } else {
            let mnem = match (op, o2) {
              (false, _) => "cinc"
              (true, false) => "cinv"
              (true, true) => "cneg"
            }
            "\{mnem} \{d}, \{n}, \{inv}"
          }
        } else {
          "\{base.to_lower()} \{d}, \{n}, \{m}, \{cond_asm(cond)}"
        }
        a64(
          base + sz + "r",
          [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), imm(cond)],
          text,
        )
      }
      6 => if !bit(w, 30) { a64_dp_2src(w) } else { a64_dp_1src(w) }
      _ => None
    }
  }
}

///|
/// Add/subtract (extended register).
fn a64_add_sub_extended(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let rm = fld(w, 16, 5)
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
  // `printArithExtend`: `uxtw`/`uxtx` of the register width print as `lsl`
  // (or nothing) when the destination or first source is the stack pointer
  let sp_involved = (!s && rd == 31) || rn == 31
  let ext_text = if sp_involved && option == (if sf { 3 } else { 2 }) {
    if amount == 0 {
      ""
    } else {
      ", lsl #\{amount}"
    }
  } else {
    let ext = ["uxtb", "uxth", "uxtw", "uxtx", "sxtb", "sxth", "sxtw", "sxtx"][option]
    ", \{ext}\{if amount == 0 { "" } else { " #\{amount}" }}"
  }
  let text = if s && rd == 31 {
    "\{if sub { "cmp" } else { "cmn" }} \{reg_asm(sf, rn, sp=true)}, \{reg_asm(x64, rm)}\{ext_text}"
  } else {
    "\{if sub { "sub" } else { "add" }}\{if s { "s" } else { "" }} \{reg_asm(sf, rd, sp=!s)}, \{reg_asm(sf, rn, sp=true)}, \{reg_asm(x64, rm)}\{ext_text}"
  }
  a64(
    name,
    [
      mc_reg(sf, rd, sp=!s),
      mc_reg(sf, rn, sp=true),
      mc_reg(x64, rm),
      imm((option << 3) | amount),
    ],
    text,
  )
}

///|
/// Data processing (3 source).
fn a64_dp_3src(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let rm = fld(w, 16, 5)
  let ra = fld(w, 10, 5)
  let d = reg_asm(sf, rd)
  let n = reg_asm(sf, rn)
  let m = reg_asm(sf, rm)
  guard fld(w, 29, 2) == 0 else { return None }
  let o0 = bit(w, 15)
  match (fld(w, 21, 3), o0) {
    (0, _) => {
      let base = if o0 { "MSUB" } else { "MADD" }
      let text = if ra == 31 {
        "\{if o0 { "mneg" } else { "mul" }} \{d}, \{n}, \{m}"
      } else {
        "\{base.to_lower()} \{d}, \{n}, \{m}, \{reg_asm(sf, ra)}"
      }
      a64(
        base + sz + "rrr",
        [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm), mc_reg(sf, ra)],
        text,
      )
    }
    (1 | 5 as op, _) => {
      guard sf else { return None }
      let signed = op == 1
      let name = (if signed { "S" } else { "U" }) +
        (if o0 { "MSUBL" } else { "MADDL" })
      let args = "\{reg_asm(true, rd)}, \{reg_asm(false, rn)}, \{reg_asm(false, rm)}"
      let text = if ra == 31 {
        let mnem = if o0 { "mnegl" } else { "mull" }
        "\{if signed { "s" } else { "u" }}\{mnem} \{args}"
      } else {
        "\{name.to_lower()} \{args}, \{reg_asm(true, ra)}"
      }
      a64(name + "rrr", [mc_x(rd), mc_w(rn), mc_w(rm), mc_x(ra)], text)
    }
    (2 | 6 as op, false) => {
      guard sf else { return None }
      let name = if op == 2 { "SMULH" } else { "UMULH" }
      a64(
        name + "rr",
        [mc_x(rd), mc_x(rn), mc_x(rm)],
        "\{name.to_lower()} \{d}, \{n}, \{m}",
      )
    }
    _ => None
  }
}

///|
/// Data processing (2 source).
fn a64_dp_2src(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let rm = fld(w, 16, 5)
  guard !bit(w, 29) else { return None }
  let opcode = fld(w, 10, 6)
  if opcode >= 0b010000 && opcode <= 0b010111 {
    // CRC32
    let size = opcode & 3
    guard (size == 3) == sf else { return None }
    let c = if (opcode & 4) != 0 { "C" } else { "" }
    let name = "CRC32" + c + ["B", "H", "W", "X"][size]
    return a64(
      name + "rr",
      [mc_w(rd), mc_w(rn), mc_reg(sf, rm)],
      "\{name.to_lower()} \{reg_asm(false, rd)}, \{reg_asm(false, rn)}, \{reg_asm(sf, rm)}",
    )
  }
  if opcode == 0b001100 {
    guard sf else { return None }
    return a64(
      "PACGA",
      [mc_x(rd), mc_x(rn), mc_x(rm, sp=true)],
      "pacga \{reg_asm(true, rd)}, \{reg_asm(true, rn)}, \{reg_asm(true, rm, sp=true)}",
    )
  }
  let (base, mnemonic) = match opcode {
    2 => ("UDIV", "udiv")
    3 => ("SDIV", "sdiv")
    8 => ("LSLV", "lsl")
    9 => ("LSRV", "lsr")
    10 => ("ASRV", "asr")
    11 => ("RORV", "ror")
    _ => return None
  }
  a64(
    base + sz + "r",
    [mc_reg(sf, rd), mc_reg(sf, rn), mc_reg(sf, rm)],
    "\{mnemonic} \{reg_asm(sf, rd)}, \{reg_asm(sf, rn)}, \{reg_asm(sf, rm)}",
  )
}

///|
/// Data processing (1 source), including pointer authentication.
fn a64_dp_1src(w : UInt) -> A64Insn? {
  let sf = bit(w, 31)
  let sz = size_char(sf)
  let rd = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  guard !bit(w, 29) else { return None }
  let opcode = fld(w, 10, 6)
  match fld(w, 16, 5) {
    0 => {
      let (name, mnemonic) = match (opcode, sf) {
        (0, _) => ("RBIT" + sz + "r", "rbit")
        (1, _) => ("REV16" + sz + "r", "rev16")
        (2, true) => ("REV32Xr", "rev32")
        (2, false) => ("REVWr", "rev")
        (3, true) => ("REVXr", "rev")
        (4, _) => ("CLZ" + sz + "r", "clz")
        (5, _) => ("CLS" + sz + "r", "cls")
        _ => return None
      }
      a64(
        name,
        [mc_reg(sf, rd), mc_reg(sf, rn)],
        "\{mnemonic} \{reg_asm(sf, rd)}, \{reg_asm(sf, rn)}",
      )
    }
    1 => {
      guard sf && opcode < 0b010010 else { return None }
      let d = reg_asm(true, rd)
      if opcode >= 0b010000 {
        guard rn == 31 else { return None }
        let name = if opcode == 0b010000 { "XPACI" } else { "XPACD" }
        return a64(name, [mc_x(rd), mc_x(rd)], "\{name.to_lower()} \{d}")
      }
      let base = [
          "PACIA", "PACIB", "PACDA", "PACDB", "AUTIA", "AUTIB", "AUTDA", "AUTDB",
        ][opcode & 7]
      if opcode >= 0b001000 {
        guard rn == 31 else { return None }
        // PACIZA, AUTDZB, ...
        let name = [
            "PACIZA", "PACIZB", "PACDZA", "PACDZB", "AUTIZA", "AUTIZB", "AUTDZA",
            "AUTDZB",
          ][opcode & 7]
        a64(name, [mc_x(rd), mc_x(rd)], "\{name.to_lower()} \{d}")
      } else {
        a64(
          base,
          [mc_x(rd), mc_x(rd), mc_x(rn, sp=true)],
          "\{base.to_lower()} \{d}, \{reg_asm(true, rn, sp=true)}",
        )
      }
    }
    _ => None
  }
}
