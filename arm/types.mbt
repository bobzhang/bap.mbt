// Port of upstream `lib/arm/arm_types.ml`: condition codes, registers,
// operands, the grouped instruction type, and the auxiliary enums that
// parameterize the memory, data-movement and multiply lifters.

///|
/// ARM condition codes (`Arm_types.cond`).
pub(all) enum Cond {
  EQ
  NE
  CS
  CC
  MI
  PL
  VS
  VC
  HI
  LS
  GE
  LT
  GT
  LE
  AL
} derive(Eq, Debug)

///|
pub extend Cond with Eq::{equal, not_equal}

///|
pub extend Cond with Debug::{to_repr}

///|
/// ARM registers known to the lifter (`Arm_types.reg`): the `Nil`
/// placeholder, the general purpose registers, and the condition-code
/// registers.
pub(all) enum Reg {
  Nil
  R0
  R1
  R2
  R3
  R4
  R5
  R6
  R7
  R8
  R9
  R10
  R11
  R12
  LR
  PC
  SP
  CPSR
  SPSR
  ITSTATE
} derive(Eq, Debug)

///|
pub extend Reg with Eq::{equal, not_equal}

///|
pub extend Reg with Debug::{to_repr}

///|
/// Decoded ARM operand (`Arm_types.op`). Immediates are 32-bit words.
pub(all) enum Op {
  Reg(Reg)
  Imm(UInt)
} derive(Eq, Debug)

///|
pub extend Op with Eq::{equal, not_equal}

///|
pub extend Op with Debug::{to_repr}

///|
/// Instruction groups of `Arm_types.insn`. Upstream uses a single
/// polymorphic variant made of the group variants; here each group is its
/// own enum and `Insn` tags the group.
pub(all) enum Insn {
  Move(MoveInsn)
  Bits(BitsInsn)
  Mult(MultInsn)
  Mem(MemInsn)
  MemMulti(MemMultiInsn)
  Branch(BranchInsn)
  Special(SpecialInsn)
} derive(Eq, Debug)

///|
pub extend Insn with Eq::{equal, not_equal}

///|
pub extend Insn with Debug::{to_repr}

///|
/// Addressing mode of single-register memory accesses.
priv enum ModeR {
  Offset
  PreIndex
  PostIndex
}

///|
/// Sign extension mode.
priv enum Sign {
  Signed
  Unsigned
}

///|
/// Memory operation direction.
priv enum Operation {
  Ld
  St
}

///|
/// Memory access size: byte, halfword, word, doubleword (register pair).
priv enum MemSize {
  B
  H
  W
  D
}

///|
/// Addressing mode of multiple-register memory accesses.
priv enum ModeM {
  IA
  IB
  DA
  DB
}

///|
/// Whether a multiple-register access writes back the base register.
priv enum UpdateM {
  Update
  NoUpdate
}

///|
/// Data-processing operation (`Arm_types.data_oper`); the first six are
/// the `arth` operations, the others the `move` operations.
priv enum DataOper {
  ADD
  ADC
  SBC
  RSC
  SUB
  RSB
  AND
  BIC
  EOR
  MOV
  MVN
  ORR
}

///|
/// How an immediate sign bit is interpreted when repairing an offset.
priv enum Repair {
  POS
  NEG
}

///|
/// Shift types.
priv enum Shift {
  ASR
  LSL
  LSR
  ROR
  RRX
}

///|
/// Operand halves/words used by signed multiplies (`Arm_types.smul_size`).
/// Upstream also declares `TT`, `DX` and `WT`, which no instruction uses.
priv enum SmulSize {
  BB
  BT
  TB
  D
  WB
}

///|
/// Instruction set encoding of the lifted instruction. Upstream reads it
/// from `Theory.Language` (`llvm-armv7` vs `llvm-thumb`); it only affects
/// decoding of modified immediate constants.
pub(all) enum Encoding {
  A32
  T32
} derive(Eq, Debug)

///|
pub extend Encoding with Eq::{equal, not_equal}

///|
pub extend Encoding with Debug::{to_repr}
