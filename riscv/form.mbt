// Building blocks of the native RISC-V decoder: operands with the LLVM MC
// register names and the text printed for them by LLVM's
// `RISCVInstPrinter` (ABI register names), and decoded instruction forms.

///|
/// A decoded operand: the `@mc.Op` (LLVM register name or immediate) and
/// its textual form (`sp`, `fa0`, `-16`).
priv struct Operand {
  op : @mc.Op
  text : String
}

///|
/// A decoded instruction before it is materialized as an `@mc.Insn`: the
/// LLVM opcode name, the operands, the kinds and the printed assembly.
priv struct Form {
  name : String
  operands : Array[Operand]
  kinds : Array[@mc.Kind]
  assembly : String
}

///|
/// `mnemonic op, op, ...`.
fn plain(mnemonic : String, operands : Array[Operand]) -> String {
  if operands.is_empty() {
    mnemonic
  } else {
    mnemonic + " " + operands.map(o => o.text).join(", ")
  }
}

///|
/// A form printed as `mnemonic op, ...` over its operands, unless
/// `assembly` is given.
fn form(
  name : String,
  mnemonic : String,
  operands : Array[Operand],
  kinds~ : Array[@mc.Kind] = [],
  assembly? : String,
) -> Form {
  {
    name,
    operands,
    kinds,
    assembly: match assembly {
      Some(text) => text
      None => plain(mnemonic, operands)
    },
  }
}

///|
let gpr_abi_names : ReadOnlyArray[String] = [
  "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2",
  "a3", "a4", "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10",
  "s11", "t3", "t4", "t5", "t6",
]

///|
let fpr_abi_names : ReadOnlyArray[String] = [
  "ft0", "ft1", "ft2", "ft3", "ft4", "ft5", "ft6", "ft7", "fs0", "fs1", "fa0", "fa1",
  "fa2", "fa3", "fa4", "fa5", "fa6", "fa7", "fs2", "fs3", "fs4", "fs5", "fs6", "fs7",
  "fs8", "fs9", "fs10", "fs11", "ft8", "ft9", "ft10", "ft11",
]

///|
/// Integer register `n` (`X0`..`X31`).
fn x(n : Int32) -> Operand {
  { op: Reg(name="X\{n}", code=n), text: gpr_abi_names[n], }
}

///|
/// Single-precision FP register `n` (`F0_F`..`F31_F`).
fn fs(n : Int32) -> Operand {
  { op: Reg(name="F\{n}_F", code=n), text: fpr_abi_names[n], }
}

///|
/// Double-precision FP register `n` (`F0_D`..`F31_D`).
fn fd(n : Int32) -> Operand {
  { op: Reg(name="F\{n}_D", code=n), text: fpr_abi_names[n], }
}

///|
/// An immediate, printed in decimal.
fn imm(value : Int64) -> Operand {
  { op: Imm(value), text: value.to_string(), }
}

///|
/// An immediate printed as `text`.
fn imm_text(value : Int64, text : String) -> Operand {
  { op: Imm(value), text, }
}

///|
/// Kinds of conditional branches (LLVM `isBranch`, `isTerminator`).
let cond_branch : Array[@mc.Kind] = [
  ConditionalBranch,
  Terminator,
  MayAffectControlFlow,
]

///|
/// Kinds of direct unconditional jumps (`isBranch`, `isBarrier`,
/// `isTerminator`).
let uncond_branch : Array[@mc.Kind] = [
  UnconditionalBranch,
  Barrier,
  Terminator,
  MayAffectControlFlow,
]

///|
/// Kinds of indirect jumps (`isBranch`, `isIndirectBranch`, `isBarrier`,
/// `isTerminator`).
let indirect_branch : Array[@mc.Kind] = [
  IndirectBranch,
  Barrier,
  Terminator,
  MayAffectControlFlow,
]

///|
/// Kinds of calls (`isCall`).
let call_kinds : Array[@mc.Kind] = [Call, MayAffectControlFlow]

///|
/// The kinds of a jump-and-link (`JAL`, `JALR`) that links `rd`: a call,
/// unless it links no register (`rd` is `zero`), when it is a plain jump
/// of the `jump` kinds (e.g., `j` and `ret`), as its compressed forms
/// (`C_J`, `C_JR`) are. Deviation: LLVM marks `JAL` and `JALR` as calls
/// whatever their link register, which makes every `ret` a call that
/// falls through into the next function.
fn link_kinds(rd : Int32, jump : Array[@mc.Kind]) -> Array[@mc.Kind] {
  if rd == 0 {
    jump
  } else {
    call_kinds
  }
}

///|
/// Kinds of returns from traps (`isReturn`, `isBarrier`, `isTerminator`).
let return_kinds : Array[@mc.Kind] = [
  Return,
  Barrier,
  Terminator,
  MayAffectControlFlow,
]

///|
let load_kinds : Array[@mc.Kind] = [MayLoad]

///|
let store_kinds : Array[@mc.Kind] = [MayStore]

///|
let load_store_kinds : Array[@mc.Kind] = [MayLoad, MayStore]
