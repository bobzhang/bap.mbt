// Loads and stores of the general-purpose registers.

///|
/// The name of a prefetch operation (`prfm`), `#n` for unnamed ones.
fn prfop_text(op : Int) -> String {
  let kind = op >> 3
  let target = (op >> 1) & 3
  if kind > 2 || target == 3 {
    return "#\{op}"
  }
  "\{["pld", "pli", "pst"][kind]}l\{target + 1}\{if (op & 1) == 0 { "keep" } else { "strm" }}"
}

///|
/// The name of a range prefetch operation (`rprfm`), `#n` for unnamed ones.
fn rprfop_text(op : Int) -> String {
  match op {
    0 => "pldkeep"
    1 => "pstkeep"
    4 => "pldstrm"
    5 => "pststrm"
    _ => "#\{op}"
  }
}

///|
/// A base register with an optional immediate offset, `[xN]` when the
/// offset is zero.
fn mem_text(base : String, offset : Int64) -> String {
  if offset == 0L {
    "[\{base}]"
  } else {
    "[\{base}, \{imm_text(offset)}]"
  }
}

///|
/// The name of a single-register load or store of the given `size` and
/// `opc` (without the addressing mode suffix), the assembly mnemonic,
/// whether the transfer register is 64-bit. `prefix` selects the
/// `LDR`/`LDUR`/`LDTR` spelling.
fn a64_ldst_name(size : Int, opc : Int, mode : Int) -> (String, String, Bool)? {
  // mode: 0 = LDR/STR, 1 = LDUR/STUR, 2 = LDTR/STTR
  let (load, suffix, m, sf) = match (size, opc) {
    (0, 0) => (false, "BB", "b", false)
    (0, 1) => (true, "BB", "b", false)
    (0, 2) => (true, "SBX", "sb", true)
    (0, 3) => (true, "SBW", "sb", false)
    (1, 0) => (false, "HH", "h", false)
    (1, 1) => (true, "HH", "h", false)
    (1, 2) => (true, "SHX", "sh", true)
    (1, 3) => (true, "SHW", "sh", false)
    (2, 0) => (false, "W", "", false)
    (2, 1) => (true, "W", "", false)
    (2, 2) => (true, "SW", "sw", true)
    (3, 0) => (false, "X", "", true)
    (3, 1) => (true, "X", "", true)
    _ => return None
  }
  let op = ["R", "UR", "TR"][mode]
  let suffix = if mode == 2 {
    // LDTRBi, LDTRSBXi, STTRHi: a single B/H
    match suffix {
      "BB" => "B"
      "HH" => "H"
      s => s
    }
  } else {
    suffix
  }
  let name = (if load { "LD" } else { "ST" }) + op + suffix
  let mnemonic = (if load { "ld" } else { "st" }) + op.to_lower() + m
  Some((name, mnemonic, sf))
}

///|
/// Loads and stores.
fn a64_load_store(w : UInt) -> A64Insn? {
  if bit(w, 26) {
    // SIMD and floating point
    return None
  }
  if fld(w, 24, 6) == 0b001000 {
    return a64_exclusive(w)
  }
  match fld(w, 27, 3) {
    0b101 => a64_ldst_pair(w)
    0b011 => {
      // load register (literal)
      guard fld(w, 24, 2) == 0 else { return None }
      let rt = fld(w, 0, 5)
      let offset = sext(fld(w, 5, 19), 19)
      let off = imm_text(offset.to_int64() * 4L)
      match fld(w, 30, 2) {
        0 =>
          a64(
            "LDRWl",
            [mc_w(rt), imm(offset)],
            "ldr \{reg_asm(false, rt)}, \{off}",
          )
        1 =>
          a64(
            "LDRXl",
            [mc_x(rt), imm(offset)],
            "ldr \{reg_asm(true, rt)}, \{off}",
          )
        2 =>
          a64(
            "LDRSWl",
            [mc_x(rt), imm(offset)],
            "ldrsw \{reg_asm(true, rt)}, \{off}",
          )
        _ =>
          a64("PRFMl", [imm(rt), imm(offset)], "prfm \{prfop_text(rt)}, \{off}")
      }
    }
    0b111 =>
      if bit(w, 24) {
        a64_ldst_unsigned(w)
      } else if !bit(w, 21) {
        a64_ldst_imm9(w)
      } else {
        match fld(w, 10, 2) {
          0 => a64_atomic(w)
          2 => a64_ldst_register(w)
          _ => a64_ldra(w)
        }
      }
    _ => None
  }
}

///|
/// Load/store register (unsigned immediate).
fn a64_ldst_unsigned(w : UInt) -> A64Insn? {
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base = reg_asm(true, rn, sp=true)
  let size = fld(w, 30, 2)
  let opc = fld(w, 22, 2)
  let imm12 = fld(w, 10, 12)
  let offset = (imm12 << size).to_int64()
  if (size, opc) == (3, 2) {
    return a64(
      "PRFMui",
      [imm(rt), mc_x(rn, sp=true), imm(imm12)],
      "prfm \{prfop_text(rt)}, \{mem_text(base, offset)}",
    )
  }
  guard a64_ldst_name(size, opc, 0) is Some((name, m, sf)) else { return None }
  a64(
    name + "ui",
    [mc_reg(sf, rt), mc_x(rn, sp=true), imm(imm12)],
    "\{m} \{reg_asm(sf, rt)}, \{mem_text(base, offset)}",
  )
}

///|
/// Load/store register with a signed 9-bit offset: unscaled, unprivileged,
/// pre- and post-indexed.
fn a64_ldst_imm9(w : UInt) -> A64Insn? {
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base = reg_asm(true, rn, sp=true)
  let size = fld(w, 30, 2)
  let opc = fld(w, 22, 2)
  let simm9 = sext(fld(w, 12, 9), 9)
  let mode = fld(w, 10, 2)
  if (size, opc) == (3, 2) {
    guard mode == 0 else { return None }
    return a64(
      "PRFUMi",
      [imm(rt), mc_x(rn, sp=true), imm(simm9)],
      "prfum \{prfop_text(rt)}, \{mem_text(base, simm9.to_int64())}",
    )
  }
  let kind = match mode {
    0 => 1
    2 => 2
    _ => 0
  }
  guard a64_ldst_name(size, opc, kind) is Some((name, m, sf)) else {
    return None
  }
  let t = reg_asm(sf, rt)
  match mode {
    0 | 2 =>
      a64(
        name + "i",
        [mc_reg(sf, rt), mc_x(rn, sp=true), imm(simm9)],
        "\{m} \{t}, \{mem_text(base, simm9.to_int64())}",
      )
    _ => {
      let pre = mode == 3
      a64(
        name + (if pre { "pre" } else { "post" }),
        [mc_x(rn, sp=true), mc_reg(sf, rt), mc_x(rn, sp=true), imm(simm9)],
        if pre {
          "\{m} \{t}, [\{base}, \{imm_text(simm9.to_int64())}]!"
        } else {
          "\{m} \{t}, [\{base}], \{imm_text(simm9.to_int64())}"
        },
      )
    }
  }
}

///|
/// Load/store register (register offset), including the range prefetch.
fn a64_ldst_register(w : UInt) -> A64Insn? {
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base = reg_asm(true, rn, sp=true)
  let size = fld(w, 30, 2)
  let opc = fld(w, 22, 2)
  let option = fld(w, 13, 3)
  guard (option & 2) != 0 else { return None }
  let x = (option & 1) == 1
  let rm = fld(w, 16, 5)
  let sign = option >> 2
  let shift = fld(w, 12, 1)
  let prefetch = (size, opc) == (3, 2)
  if prefetch && rt >= 24 {
    let op = (sign << 5) | ((option & 1) << 4) | (shift << 3) | (rt & 7)
    return a64(
      "RPRFM",
      [imm(op), mc_x(rm), mc_x(rn, sp=true)],
      "rprfm \{rprfop_text(op)}, \{reg_asm(true, rm)}, [\{base}]",
    )
  }
  let (name, m, sf) = if prefetch {
    ("PRFM", "prfm", false)
  } else {
    guard a64_ldst_name(size, opc, 0) is Some(r) else { return None }
    r
  }
  let ext_text = if x && sign == 0 && shift == 0 {
    ""
  } else {
    let ext = match option {
      2 => "uxtw"
      3 => "lsl"
      6 => "sxtw"
      _ => "sxtx"
    }
    ", \{ext}\{if shift == 1 { " #\{size}" } else { "" }}"
  }
  let t = if prefetch { prfop_text(rt) } else { reg_asm(sf, rt) }
  a64(
    name + (if x { "roX" } else { "roW" }),
    [
      if prefetch {
        imm(rt)
      } else {
        mc_reg(sf, rt)
      },
      mc_x(rn, sp=true),
      mc_reg(x, rm),
      imm(sign),
      imm(shift),
    ],
    "\{m} \{t}, [\{base}, \{reg_asm(x, rm)}\{ext_text}]",
  )
}

///|
/// The pointer authenticating loads `LDRAA`/`LDRAB`.
fn a64_ldra(w : UInt) -> A64Insn? {
  guard fld(w, 30, 2) == 3 else { return None }
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base = reg_asm(true, rn, sp=true)
  let key = if bit(w, 23) { "B" } else { "A" }
  let offset = sext((fld(w, 22, 1) << 9) | fld(w, 12, 9), 10)
  let bytes = offset.to_int64() * 8L
  let m = "ldra\{key.to_lower()} \{reg_asm(true, rt)}"
  if bit(w, 11) {
    a64(
      "LDRA" + key + "writeback",
      [mc_x(rn, sp=true), mc_x(rt), mc_x(rn, sp=true), imm(offset)],
      "\{m}, [\{base}, \{imm_text(bytes)}]!",
    )
  } else {
    a64(
      "LDRA" + key + "indexed",
      [mc_x(rt), mc_x(rn, sp=true), imm(offset)],
      "\{m}, \{mem_text(base, bytes)}",
    )
  }
}

///|
/// Load/store pair (all addressing modes) and the no-allocate pairs.
fn a64_ldst_pair(w : UInt) -> A64Insn? {
  let rt = fld(w, 0, 5)
  let rn = fld(w, 5, 5)
  let base = reg_asm(true, rn, sp=true)
  let opc = fld(w, 30, 2)
  let mode = fld(w, 23, 2)
  let load = bit(w, 22)
  let (kind, sf, scale) = match opc {
    0 => ("W", false, 4)
    1 if load && mode != 0 => ("SW", true, 4)
    2 => ("X", true, 8)
    _ => return None
  }
  let offset = sext(fld(w, 15, 7), 7)
  let rt2 = fld(w, 10, 5)
  let op = (if load { "LD" } else { "ST" }) +
    (if mode == 0 { "NP" } else { "P" })
  let name = op + kind + ["i", "post", "i", "pre"][mode]
  let m = op.to_lower() + (if opc == 1 { "sw" } else { "" })
  let regs = "\{reg_asm(sf, rt)}, \{reg_asm(sf, rt2)}"
  let off = (offset * scale).to_int64()
  if mode == 0 || mode == 2 {
    a64(
      name,
      [mc_reg(sf, rt), mc_reg(sf, rt2), mc_x(rn, sp=true), imm(offset)],
      "\{m} \{regs}, \{mem_text(base, off)}",
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
        "\{m} \{regs}, [\{base}, \{imm_text(off)}]!"
      } else {
        "\{m} \{regs}, [\{base}], \{imm_text(off)}"
      },
    )
  }
}

///|
/// Load/store exclusive, load-acquire/store-release and compare and swap
/// (single and pair).
fn a64_exclusive(w : UInt) -> A64Insn? {
  let size = fld(w, 30, 2)
  let o2 = bit(w, 23)
  let l = bit(w, 22)
  let o1 = bit(w, 21)
  let rs = fld(w, 16, 5)
  let o0 = bit(w, 15)
  let rt2 = fld(w, 10, 5)
  let rn = fld(w, 5, 5)
  let rt = fld(w, 0, 5)
  let sf = size == 3
  let sz = ["B", "H", "W", "X"][size]
  let msz = ["b", "h", "", ""][size]
  let base = "[\{reg_asm(true, rn, sp=true)}]"
  let t = reg_asm(sf, rt)
  match (o2, o1) {
    (false, false) =>
      if l {
        let name = if o0 { "LDAXR" } else { "LDXR" }
        a64(
          name + sz,
          [mc_reg(sf, rt), mc_x(rn, sp=true)],
          "\{name.to_lower()}\{msz} \{t}, \{base}",
        )
      } else {
        let name = if o0 { "STLXR" } else { "STXR" }
        a64(
          name + sz,
          [mc_w(rs), mc_reg(sf, rt), mc_x(rn, sp=true)],
          "\{name.to_lower()}\{msz} \{reg_asm(false, rs)}, \{t}, \{base}",
        )
      }
    (false, true) =>
      if size >= 2 {
        let t2 = reg_asm(sf, rt2)
        if l {
          let name = (if o0 { "LDAXP" } else { "LDXP" }) + sz
          a64(
            name,
            [mc_reg(sf, rt), mc_reg(sf, rt2), mc_x(rn, sp=true)],
            "\{chop(name, 1).to_lower()} \{t}, \{t2}, \{base}",
          )
        } else {
          let name = (if o0 { "STLXP" } else { "STXP" }) + sz
          a64(
            name,
            [mc_w(rs), mc_reg(sf, rt), mc_reg(sf, rt2), mc_x(rn, sp=true)],
            "\{chop(name, 1).to_lower()} \{reg_asm(false, rs)}, \{t}, \{t2}, \{base}",
          )
        }
      } else {
        // compare and swap pair
        guard rt2 == 31 && rs % 2 == 0 && rt % 2 == 0 else { return None }
        let psf = size == 1
        let name = "CASP" +
          (if l { "A" } else { "" }) +
          (if o0 { "L" } else { "" }) +
          (if psf { "X" } else { "W" })
        let s = mc_pair(psf, rs)
        a64(
          name,
          [s, s, mc_pair(psf, rt), mc_x(rn, sp=true)],
          "\{chop(name, 1).to_lower()} \{reg_asm(psf, rs)}, \{reg_asm(psf, rs + 1)}, \{reg_asm(psf, rt)}, \{reg_asm(psf, rt + 1)}, \{base}",
        )
      }
    (true, false) => {
      let name = match (l, o0) {
        (false, false) => "STLLR"
        (false, true) => "STLR"
        (true, false) => "LDLAR"
        (true, true) => "LDAR"
      }
      a64(
        name + sz,
        [mc_reg(sf, rt), mc_x(rn, sp=true)],
        "\{name.to_lower()}\{msz} \{t}, \{base}",
      )
    }
    (true, true) => {
      guard rt2 == 31 else { return None }
      let name = "CAS" +
        (if l { "A" } else { "" }) +
        (if o0 { "L" } else { "" }) +
        sz
      a64(
        name,
        [mc_reg(sf, rs), mc_reg(sf, rs), mc_reg(sf, rt), mc_x(rn, sp=true)],
        "\{chop(name, 1).to_lower()}\{msz} \{reg_asm(sf, rs)}, \{t}, \{base}",
      )
    }
  }
}

///|
/// Atomic memory operations (LSE) and `LDAPR`.
fn a64_atomic(w : UInt) -> A64Insn? {
  let size = fld(w, 30, 2)
  let a = bit(w, 23)
  let r = bit(w, 22)
  let rs = fld(w, 16, 5)
  let o3 = bit(w, 15)
  let opc = fld(w, 12, 3)
  let rn = fld(w, 5, 5)
  let rt = fld(w, 0, 5)
  let sf = size == 3
  let sz = ["B", "H", "W", "X"][size]
  let msz = ["b", "h", "", ""][size]
  let base = "[\{reg_asm(true, rn, sp=true)}]"
  let ord = (if a { "A" } else { "" }) + (if r { "L" } else { "" })
  let op = match (o3, opc) {
    (false, _) =>
      ["ADD", "CLR", "EOR", "SET", "SMAX", "SMIN", "UMAX", "UMIN"][opc]
    (true, 0) => "SWP"
    (true, 4) => {
      guard a && !r && rs == 31 else { return None }
      return a64(
        "LDAPR" + sz,
        [mc_reg(sf, rt), mc_x(rn, sp=true)],
        "ldapr\{msz} \{reg_asm(sf, rt)}, \{base}",
      )
    }
    _ => return None
  }
  let name = (if op == "SWP" { "" } else { "LD" }) + op + ord + sz
  let s = reg_asm(sf, rs)
  let text = if op != "SWP" && !a && rt == 31 {
    "st\{op.to_lower()}\{ord.to_lower()}\{msz} \{s}, \{base}"
  } else {
    let plain = "\{chop(name, sz.length()).to_lower()}\{msz} \{s}, \{reg_asm(sf, rt)}, \{base}"
    if a && rt == 31 {
      plain + " // acquire semantics dropped since destination is zero"
    } else {
      plain
    }
  }
  a64(name, [mc_reg(sf, rt), mc_reg(sf, rs), mc_x(rn, sp=true)], text)
}
