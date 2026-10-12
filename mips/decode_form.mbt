// Building blocks of the native MIPS decoder (`decode.mbt`): operands with
// the LLVM MC register names and the text printed for them by LLVM's
// `MipsInstPrinter`, and decoded instruction forms.

///|
/// A decoded operand: the `@mc.Op` (LLVM register name or immediate) and
/// its textual form as printed by LLVM (`$sp`, `$8`, `$f12`, `-32`).
priv struct Operand {
  op : @mc.Op
  text : String
}

///|
/// How the assembly text of a form is laid out.
priv enum Layout {
  /// `mnemonic op, op, ...`
  Plain
  /// `mnemonic rt, offset(base)` over the operands `[.., rt, base, offset]`
  Mem
  /// the given text, verbatim
  Text(String)
}

///|
/// A decoded instruction before it is materialized as an `@mc.Insn`.
priv struct Form {
  name : String
  mnemonic : String
  operands : Array[Operand]
  kinds : Array[@mc.Kind]
  layout : Layout
}

///|
fn form(
  name : String,
  mnemonic : String,
  operands : Array[Operand],
  kinds~ : Array[@mc.Kind] = [],
  layout~ : Layout = Plain,
) -> Form {
  { name, mnemonic, operands, kinds, layout, }
}

///|
fn Form::assembly(self : Form) -> String {
  match self.layout {
    Text(text) => text
    Plain =>
      if self.operands.is_empty() {
        self.mnemonic
      } else {
        self.mnemonic + " " + self.operands.map(o => o.text).join(", ")
      }
    Mem => {
      let n = self.operands.length()
      let rt = self.operands[n - 3].text
      let base = self.operands[n - 2].text
      let offset = self.operands[n - 1].text
      "\{self.mnemonic} \{rt}, \{offset}(\{base})"
    }
  }
}

///|
/// The name LLVM prints for GPR number `n`: numbers, except for `zero`,
/// `gp`, `sp`, `fp` and `ra`.
fn gpr_asm_name(n : Int32) -> String {
  match n {
    0 => "zero"
    28 => "gp"
    29 => "sp"
    30 => "fp"
    31 => "ra"
    _ => n.to_string()
  }
}

///|
/// GPR `n` of the LLVM `GPR32` register class (`ZERO`, `AT`, ..., `RA`).
fn gpr32(n : Int32) -> Operand {
  { op: Reg(name=gpr_names[n], code=n), text: "$" + gpr_asm_name(n), }
}

///|
/// GPR `n` of the LLVM `GPR64` register class (`ZERO_64`, ..., `RA_64`).
fn gpr64(n : Int32) -> Operand {
  { op: Reg(name=gpr_names[n] + "_64", code=n), text: "$" + gpr_asm_name(n), }
}

///|
/// A signed immediate, printed in decimal.
fn imm(value : Int64) -> Operand {
  { op: Imm(value), text: value.to_string(), }
}

///|
/// Single-precision FPU register `n` (`FGR32`: `F0`..`F31`).
fn fgr32(n : Int32) -> Operand {
  { op: Reg(name="F\{n}", code=n), text: "$f\{n}", }
}

///|
/// Double-precision FPU register `n` in the 64-bit FPU mode (`FGR64`:
/// `D0_64`..`D31_64`).
fn fgr64(n : Int32) -> Operand {
  { op: Reg(name="D\{n}_64", code=n), text: "$f\{n}", }
}

///|
/// Double-precision FPU register pair `n`/`n+1` in the 32-bit FPU mode
/// (`AFGR64`: `D0`..`D15`); odd register numbers are invalid.
fn afgr64(n : Int32) -> Operand? {
  if n % 2 == 0 {
    Some({ op: Reg(name="D\{n / 2}", code=n / 2), text: "$f\{n}", })
  } else {
    None
  }
}

///|
/// FPU condition code `n` (`FCC0`..`FCC7`).
fn fcc(n : Int32) -> Operand {
  { op: Reg(name="FCC\{n}", code=n), text: "$fcc\{n}", }
}

///|
/// FPU control register `n` (`FCR0`..`FCR31`).
fn fcr(n : Int32) -> Operand {
  { op: Reg(name="FCR\{n}", code=n), text: "$\{n}", }
}

///|
/// Coprocessor 0 register `n` (`COP00`..`COP031`).
fn cop0(n : Int32) -> Operand {
  { op: Reg(name="COP0\{n}", code=n), text: "$\{n}", }
}

///|
/// Hardware register `n` (`HWR0`..`HWR31`), read by `rdhwr`.
fn hwr(n : Int32) -> Operand {
  { op: Reg(name="HWR\{n}", code=n), text: "$\{n}", }
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
let load_kinds : Array[@mc.Kind] = [MayLoad]

///|
let store_kinds : Array[@mc.Kind] = [MayStore]
