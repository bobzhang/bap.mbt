// Branches, exception generation and system instructions.

///|
/// Branches, exception generation and system instructions.
fn a64_branch_system(w : UInt) -> A64Insn? {
  if fld(w, 26, 5) == 0b00101 {
    let offset = sext(fld(w, 0, 26), 26)
    let name = if bit(w, 31) { "BL" } else { "B" }
    a64(
      name,
      [imm(offset)],
      "\{name.to_lower()} \{imm_text(offset.to_int64() * 4L)}",
    )
  } else if fld(w, 24, 8) == 0b01010100 {
    guard !bit(w, 4) else { return None }
    let cond = fld(w, 0, 4)
    let offset = sext(fld(w, 5, 19), 19)
    a64(
      "Bcc",
      [imm(cond), imm(offset)],
      "b.\{cond_asm(cond)} \{imm_text(offset.to_int64() * 4L)}",
    )
  } else if fld(w, 24, 8) == 0b11010100 {
    a64_exception(w)
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
    )
  } else if fld(w, 25, 7) == 0b1101011 {
    a64_branch_register(w)
  } else {
    None
  }
}

///|
/// Exception generation.
fn a64_exception(w : UInt) -> A64Insn? {
  guard fld(w, 2, 3) == 0 else { return None }
  let v = fld(w, 5, 16)
  let (name, mnemonic) = match (fld(w, 21, 3), fld(w, 0, 2)) {
    (0, 1) => ("SVC", "svc")
    (0, 2) => ("HVC", "hvc")
    (0, 3) => ("SMC", "smc")
    (1, 0) => ("BRK", "brk")
    (2, 0) => ("HLT", "hlt")
    (5, 1) => ("DCPS1", "dcps1")
    (5, 2) => ("DCPS2", "dcps2")
    (5, 3) => ("DCPS3", "dcps3")
    _ => return None
  }
  let text = if name.has_prefix("DCPS") && v == 0 {
    mnemonic
  } else {
    "\{mnemonic} \{hex_imm(v)}"
  }
  a64(name, [imm(v)], text)
}

///|
/// Unconditional branch (register), including the pointer authenticating
/// branches and returns.
fn a64_branch_register(w : UInt) -> A64Insn? {
  let opc = fld(w, 21, 4)
  let op2 = fld(w, 16, 5)
  let op3 = fld(w, 10, 6)
  let rn = fld(w, 5, 5)
  let op4 = fld(w, 0, 5)
  guard op2 == 31 else { return None }
  let n = reg_asm(true, rn)
  match (opc, op3) {
    (0 | 1, 0) if op4 == 0 => {
      let name = if opc == 0 { "BR" } else { "BLR" }
      a64(name, [mc_x(rn)], "\{name.to_lower()} \{n}")
    }
    (0 | 1, 2 | 3) if op4 == 31 => {
      // BRAAZ, BRABZ, BLRAAZ, BLRABZ
      let name = (if opc == 0 { "BRA" } else { "BLRA" }) +
        (if op3 == 2 { "A" } else { "B" }) +
        "Z"
      a64(name, [mc_x(rn)], "\{name.to_lower()} \{n}")
    }
    (2, 0) if op4 == 0 =>
      a64("RET", [mc_x(rn)], if rn == 30 { "ret" } else { "ret \{n}" })
    (2 | 4, 2 | 3) if rn == 31 && op4 == 31 => {
      let name = (if opc == 2 { "RETA" } else { "ERETA" }) +
        (if op3 == 2 { "A" } else { "B" })
      a64(name, [], name.to_lower())
    }
    (4 | 5, 0) if rn == 31 && op4 == 0 => {
      let name = if opc == 4 { "ERET" } else { "DRPS" }
      a64(name, [], name.to_lower())
    }
    (8 | 9, 2 | 3) => {
      // BRAA, BRAB, BLRAA, BLRAB
      let name = (if opc == 8 { "BRA" } else { "BLRA" }) +
        (if op3 == 2 { "A" } else { "B" })
      a64(
        name,
        [mc_x(rn), mc_x(op4, sp=true)],
        "\{name.to_lower()} \{n}, \{reg_asm(true, op4, sp=true)}",
      )
    }
    _ => None
  }
}
