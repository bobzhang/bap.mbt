// Port of BAP `plugins/mips/mips_logic.ml`.
//
// Deliberate deviations from upstream: `WSBH`/`BITSWAP` sign-extend their
// word results into MIPS64 registers, and `BITSWAP`/`DBITSWAP` reverse
// the bits of each byte of `rt` (upstream's loop does not); `DSHD` (defined
// but not registered upstream) and the bit field operations `EXT`, `INS`,
// `DEXT` and `DINS` (TODO upstream) are modeled.

///|
/// `rd := op rs rt` over unsigned registers.
fn logic3(op : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rs = cpu.ureg(1)
    let rt = cpu.ureg(2)
    [rd.assign(op(rs, rt))]
  }
}

///|
/// `rd := op rs imm` with an unsigned (zero-extended) immediate.
fn logic_imm(op : (Exp, Exp) -> Exp) -> Semantics {
  cpu => {
    let rd = cpu.ureg(0)
    let rs = cpu.ureg(1)
    let im = cpu.uimm(2)
    [rd.assign(op(rs, im))]
  }
}

///|
/// NOR rd, rs, rt - Not Or, MIPS32.
fn sem_nor(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  let rt = cpu.ureg(2)
  [rd.assign(lnot(rs | rt))]
}

///|
/// NOT rd, rs (not in the manual).
fn sem_not(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  [rd.assign(lnot(rs))]
}

///|
/// Concatenate byte `indexes` of `rs` (most significant first). Like
/// upstream's right-associative `^`, the concatenation nests to the right.
fn concat_bytes(rs : Exp, indexes : Array[Int32]) -> Exp raise @mc.LiftError {
  let n = indexes.length()
  let mut acc = nth(byte, rs, indexes[n - 1])
  for i = n - 2; i >= 0; i = i - 1 {
    acc = nth(byte, rs, indexes[i]).concat(acc)
  }
  acc
}

///|
/// WSBH rd, rt - Word Swap Bytes Within Halfwords, MIPS32 Release 2 (the
/// result is sign-extended into MIPS64 registers).
fn sem_wsbh(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rt = cpu.wreg(1, Unsigned)
  [rd.assign(concat_bytes(rt, [2, 3, 0, 1]).signed())]
}

///|
/// DSBH rd, rt - Doubleword Swap Bytes Within Halfwords, MIPS64 Release 2.
fn sem_dsbh(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  [rd.assign(concat_bytes(rs, [6, 7, 4, 5, 2, 3, 0, 1]))]
}

///|
/// DSHD rd, rt - Doubleword Swap Halfwords Within Doublewords, MIPS64
/// Release 2 (not in upstream).
fn sem_dshd(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rt = cpu.ureg(1)
  let halves = [0, 1, 2, 3].map(i => nth(halfword, rt, i))
  [rd.assign(halves[0].concat(halves[1]).concat(halves[2]).concat(halves[3]))]
}

///|
/// `x` with the bits of each of its bytes reversed.
fn reverse_bits_in_bytes(x : Exp) -> Exp raise @mc.LiftError {
  let mut acc : Exp? = None
  for i = x.width / 8 - 1; i >= 0; i = i - 1 {
    for j in 0..<8 {
      let b = x.extract(8 * i + j, 8 * i + j)
      acc = match acc {
        None => Some(b)
        Some(e) => Some(e.concat(b))
      }
    }
  }
  acc.unwrap()
}

///|
/// BITSWAP rd, rt - Swap Bits Within Each Byte, MIPS32 Release 6 (the
/// result is sign-extended into MIPS64 registers).
fn sem_bitswap(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.sreg(0)
  let rt = cpu.wreg(1, Unsigned)
  [rd.assign(reverse_bits_in_bytes(rt).signed())]
}

///|
/// DBITSWAP rd, rt - Swap Bits Within Each Byte of a Doubleword, MIPS64
/// Release 6.
fn sem_dbitswap(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rt = cpu.ureg(1)
  [rd.assign(reverse_bits_in_bytes(rt))]
}

///|
/// The immediate operand `index` as an `Int`.
fn Cpu::int_imm(self : Cpu, index : Int32) -> Int32 raise @mc.LiftError {
  match self.op(index) {
    Imm(x) => x.to_int()
    _ => raise mips_fail("imm operand expected")
  }
}

///|
/// EXT/DEXT rt, rs, pos, size - Extract Bit Field (LLVM decodes `dextm`
/// and `dextu` as `DEXT`).
fn extract_field(width : Int32) -> Semantics {
  cpu => {
    let rt = cpu.reg(0, if width == word { Signed } else { Unsigned })
    let rs = cpu.ureg(1)
    let pos = cpu.int_imm(2)
    let size = cpu.int_imm(3)
    if pos < 0 || size <= 0 || pos + size > width {
      raise mips_fail("invalid bit field \{pos}:\{size}")
    }
    let field = rs.extract(pos + size - 1, pos).cast(width, Unsigned)
    [rt.assign(if width == word { field.signed() } else { field })]
  }
}

///|
/// INS/DINS rt, rs, pos, size - Insert Bit Field (LLVM decodes `dinsm`
/// and `dinsu` as `DINS`).
fn insert_field(width : Int32) -> Semantics {
  cpu => {
    let rt = cpu.reg(0, if width == word { Signed } else { Unsigned })
    let rs = cpu.ureg(1)
    let pos = cpu.int_imm(2)
    let size = cpu.int_imm(3)
    if pos < 0 || size <= 0 || pos + size > width {
      raise mips_fail("invalid bit field \{pos}:\{size}")
    }
    let old = low(width, rt)
    let field = low(size, rs)
    let parts : Array[Exp] = []
    if pos + size < width {
      parts.push(old.extract(width - 1, pos + size))
    }
    parts.push(field)
    if pos > 0 {
      parts.push(old.extract(pos - 1, 0))
    }
    let mut value = parts[0]
    for part in parts[1:] {
      value = value.concat(part)
    }
    [rt.assign(if width == word { value.signed() } else { value })]
  }
}

///|
let logic_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("AND", logic3((x, y) => x & y)),
  ("ANDi", logic_imm((x, y) => x & y)),
  ("NOP", _ => []),
  // hints and barriers without effect on the modeled state (not in
  // upstream)
  ("SSNOP", _ => []),
  ("EHB", _ => []),
  ("PAUSE", _ => []),
  ("SYNC", _ => []),
  ("SYNCI", _ => []),
  ("PREF", _ => []),
  ("PREF_R6", _ => []),
  ("NOR", sem_nor),
  ("NOT", sem_not),
  ("OR", logic3((x, y) => x | y)),
  ("ORi", logic_imm((x, y) => x | y)),
  ("XOR", logic3((x, y) => x ^ y)),
  ("XORi", logic_imm((x, y) => x ^ y)),
  ("BITSWAP", sem_bitswap),
  ("DBITSWAP", sem_dbitswap),
  ("WSBH", sem_wsbh),
  ("DSBH", sem_dsbh),
  ("DSHD", sem_dshd),
  ("EXT", extract_field(word)),
  ("DEXT", extract_field(doubleword)),
  ("INS", insert_field(word)),
  ("DINS", insert_field(doubleword)),
]
