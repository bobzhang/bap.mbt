// Construction of `@mc` operands as the LLVM ARM disassembler produces
// them, shared by the A32 decoder of this package and the T32 decoder of
// the `thumb` package.
//
// Register codes are port-local: a register's code is its position in
// `Reg::all()` (so `Nil`, LLVM's `NoRegister`, has code 0, as upstream
// `Bap_disasm_basic` expects). The pairs of the `GPRPair` class (`R0_R1`,
// ...), used by the exclusive doubleword accesses, get codes from 32 on.

///|
/// The port-local code of a register (see the file header).
pub fn Reg::code(self : Reg) -> Int {
  match self {
    Nil => 0
    R0 => 1
    R1 => 2
    R2 => 3
    R3 => 4
    R4 => 5
    R5 => 6
    R6 => 7
    R7 => 8
    R8 => 9
    R9 => 10
    R10 => 11
    R11 => 12
    R12 => 13
    LR => 14
    PC => 15
    SP => 16
    CPSR => 17
    SPSR => 18
    ITSTATE => 19
  }
}

///|
/// The register as an `@mc` operand.
pub fn Reg::to_mc(self : Reg) -> @mc.Op {
  Reg(name=self.name(), code=self.code())
}

///|
/// The general purpose register with the architectural number `n`
/// (`0..=15`, `13` is `SP`, `14` is `LR`, `15` is `PC`).
pub fn gpr(n : Int) -> Reg {
  match n & 15 {
    0 => R0
    1 => R1
    2 => R2
    3 => R3
    4 => R4
    5 => R5
    6 => R6
    7 => R7
    8 => R8
    9 => R9
    10 => R10
    11 => R11
    12 => R12
    13 => SP
    14 => LR
    _ => PC
  }
}

///|
/// The general purpose register `n` as an `@mc` operand.
pub fn mc_gpr(n : Int) -> @mc.Op {
  gpr(n).to_mc()
}

///|
/// The `GPRPair` register made of `R<n>` and `R<n+1>` (`n` even), as used
/// by `LDREXD`/`STREXD`.
pub fn mc_gpr_pair(n : Int) -> @mc.Op {
  let lo = gpr(n).name()
  let hi = gpr(n + 1).name()
  Reg(name="\{lo}_\{hi}", code=32 + n / 2)
}

///|
/// The absent register (LLVM `NoRegister`).
pub fn mc_nil() -> @mc.Op {
  Nil.to_mc()
}

///|
/// The two operands of an LLVM `pred` operand: the condition code and
/// `CPSR` when the instruction is conditional or `Nil` when it is not.
pub fn mc_pred(cond : Int) -> Array[@mc.Op] {
  [Imm(cond.to_int64()), if cond == 14 { mc_nil() } else { CPSR.to_mc() }]
}

///|
/// The optional flag-setting operand (`cc_out`): `CPSR` when the
/// instruction sets the flags, `Nil` otherwise.
pub fn mc_cc_out(set_flags : Bool) -> @mc.Op {
  if set_flags {
    CPSR.to_mc()
  } else {
    mc_nil()
  }
}

///|
/// An immediate operand.
pub fn mc_imm(value : Int) -> @mc.Op {
  Imm(value.to_int64())
}

///|
/// The assembly name of the general purpose register `n`.
pub fn gpr_asm(n : Int) -> String {
  match n & 15 {
    13 => "sp"
    14 => "lr"
    15 => "pc"
    n => "r\{n}"
  }
}

///|
/// The assembly suffix of the condition code `cond` (empty for `AL`).
pub fn cond_asm(cond : Int) -> String {
  match cond {
    0 => "eq"
    1 => "ne"
    2 => "hs"
    3 => "lo"
    4 => "mi"
    5 => "pl"
    6 => "vs"
    7 => "vc"
    8 => "hi"
    9 => "ls"
    10 => "ge"
    11 => "lt"
    12 => "gt"
    13 => "le"
    _ => ""
  }
}

///|
/// The assembly of a register list (`{r0, r4, lr}`) from a register mask.
pub fn reglist_asm(mask : Int) -> String {
  let names = []
  for n in 0..<16 {
    if ((mask >> n) & 1) == 1 {
      names.push(gpr_asm(n))
    }
  }
  "{" + names.join(", ") + "}"
}

///|
/// The register operands of a register list mask, in ascending order.
pub fn mc_reglist(mask : Int) -> Array[@mc.Op] {
  let ops = []
  for n in 0..<16 {
    if ((mask >> n) & 1) == 1 {
      ops.push(mc_gpr(n))
    }
  }
  ops
}

///|
/// An immediate in assembly (`#4`, `#-4`).
pub fn imm_asm(value : Int) -> String {
  if value < 0 {
    "#-\{-value.to_int64()}"
  } else {
    "#\{value}"
  }
}

///|
/// The name of an LLVM `ARM_AM::ShiftOpc` (1 `asr`, 2 `lsl`, 3 `lsr`, 4
/// `ror`, 5 `rrx`).
pub fn shift_opc_asm(opc : Int) -> String {
  match opc {
    1 => "asr"
    2 => "lsl"
    3 => "lsr"
    4 => "ror"
    5 => "rrx"
    _ => ""
  }
}

///|
/// The LLVM `ARM_AM::ShiftOpc` of the 2-bit shift type of an instruction
/// with an immediate shift amount `imm5` (`ror #0` is `rrx`).
pub fn shift_opc_of_type(typ : Int, imm5 : Int) -> Int {
  match typ {
    0 => 2
    1 => 3
    2 => 1
    _ => if imm5 == 0 { 5 } else { 4 }
  }
}

///|
/// The assembly of the shift of a register by an immediate, as a suffix
/// (`, lsl #2`, `, rrx`, or the empty string for no shift).
pub fn shift_imm_asm(opc : Int, amount : Int) -> String {
  match opc {
    5 => ", rrx"
    2 if amount == 0 => ""
    1 | 3 if amount == 0 => ", \{shift_opc_asm(opc)} #32"
    _ => ", \{shift_opc_asm(opc)} #\{amount}"
  }
}

///|
/// Sign-extends the `bits` low bits of `value`.
pub fn sign_extend(value : Int, bits : Int) -> Int {
  value << (32 - bits) >> (32 - bits)
}

///|
/// The kinds of an instruction that writes `PC` (other than a branch):
/// an indirect jump when it is unconditional.
pub fn pc_write_kinds(cond : Int) -> Array[@mc.Kind] {
  if cond == 14 {
    [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
  } else {
    [ConditionalBranch, MayAffectControlFlow]
  }
}
