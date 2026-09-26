// Port of BAP `plugins/mips/mips_logic.ml`. EXT/INS are TODO upstream,
// and upstream's DSHD lifter is defined but never registered.

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
fn concat_bytes(rs : Exp, indexes : Array[Int]) -> Exp raise @mc.LiftError {
  let n = indexes.length()
  let mut acc = nth(byte, rs, indexes[n - 1])
  for i = n - 2; i >= 0; i = i - 1 {
    acc = nth(byte, rs, indexes[i]).concat(acc)
  }
  acc
}

///|
/// WSBH rd, rs - Word Swap Bytes Within Halfwords, MIPS32 Release 2.
fn sem_wsbh(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  [rd.assign(concat_bytes(rs, [2, 3, 0, 1]))]
}

///|
/// DSBH rd, rs - Doubleword Swap Bytes Within Halfwords, MIPS64 Release 2.
fn sem_dsbh(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rs = cpu.ureg(1)
  [rd.assign(concat_bytes(rs, [6, 7, 4, 5, 2, 3, 0, 1]))]
}

///|
/// BITSWAP rd, rt - reverse bits in each byte, MIPS32 Release 6 (also
/// DBITSWAP, iterating over all bits of the destination).
fn sem_bitswap(cpu : Cpu) -> Array[Rtl] raise @mc.LiftError {
  let rd = cpu.ureg(0)
  let rt = cpu.ureg(1)
  let cnt = cpu.uvar(byte)
  let biti = cpu.uvar(bit)
  let width = uconst(byte, 8)
  let pos = cpu.uvar(byte)
  let max_ind = uconst(byte, 7)
  let byte_ind = cpu.uvar(byte)
  [
    cnt.assign(zero),
    foreach(biti, rd, [
      byte_ind.assign(cnt / width),
      pos.assign(byte_ind * width + (max_ind - cnt % width)),
      biti.assign(lsb(rt.lsr(pos))),
      cnt.assign(cnt + one),
    ]),
  ]
}

///|
let logic_semantics : ReadOnlyArray[(String, Semantics)] = [
  ("AND", logic3((x, y) => x & y)),
  ("ANDi", logic_imm((x, y) => x & y)),
  ("NOP", _ => []),
  ("NOR", sem_nor),
  ("NOT", sem_not),
  ("OR", logic3((x, y) => x | y)),
  ("ORi", logic_imm((x, y) => x | y)),
  ("XOR", logic3((x, y) => x ^ y)),
  ("XORi", logic_imm((x, y) => x ^ y)),
  ("BITSWAP", sem_bitswap),
  ("DBITSWAP", sem_bitswap),
  ("WSBH", sem_wsbh),
  ("DSBH", sem_dsbh),
]
