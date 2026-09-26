// Operands of decoded PowerPC instructions and their textual form.
//
// The operands follow the conventions of the LLVM PowerPC disassembler
// (`PPCDisassembler.cpp`): general purpose registers are `R0`..`R31`
// (`gprc`) or `X0`..`X31` (`g8rc`); register operands that cannot be `r0`
// (`gprc_nor0`, the base of memory operands) decode `0` as `ZERO` (or
// `ZERO8` for `g8rc_nox0`); condition register fields are `CR0`..`CR7` and
// condition register bits `CR0LT`, `CR0GT`, `CR0EQ`, `CR0UN`, ...,
// `CR7UN`. Memory operands are a displacement followed by the base
// register. Branch targets are the (sign-extended) word offsets as encoded,
// not multiplied by four.

///|
/// A decoded operand, before it is turned into `@mc.Op`s and text.
priv enum Arg {
  /// `gprc` register.
  Gpr(Int)
  /// `gprc_nor0` register: `0` is `ZERO`.
  Gpr0(Int)
  /// `g8rc` register.
  G8(Int)
  /// Condition register field.
  Crf(Int)
  /// Condition register bit.
  Crb(Int)
  /// Integer immediate.
  Imm(Int64)
  /// Memory operand `disp(base)`: an immediate and a `gprc_nor0` base.
  Mem(Int64, Int)
  /// Branch target (in words): relative unless absolute.
  Target(Int64, absolute~ : Bool)
  /// An operand present in the instruction but not printed (tied operands
  /// and operands elided by extended mnemonics).
  Silent(Arg)
}

///|
let crbit_names : FixedArray[String] = ["LT", "GT", "EQ", "UN"]

///|
fn gpr_op(n : Int) -> @mc.Op {
  @mc.Op::reg("R\{n}")
}

///|
fn gpr0_op(n : Int) -> @mc.Op {
  if n == 0 {
    @mc.Op::reg("ZERO")
  } else {
    gpr_op(n)
  }
}

///|
/// The `@mc.Op`s of the argument, in order.
fn Arg::ops(self : Arg) -> Array[@mc.Op] {
  match self {
    Gpr(n) => [gpr_op(n)]
    Gpr0(n) => [gpr0_op(n)]
    G8(n) => [@mc.Op::reg("X\{n}")]
    Crf(n) => [@mc.Op::reg("CR\{n}")]
    Crb(n) => [@mc.Op::reg("CR\{n / 4}\{crbit_names[n % 4]}")]
    Imm(v) => [Imm(v)]
    Mem(disp, base) => [Imm(disp), gpr0_op(base)]
    Target(v, ..) => [Imm(v)]
    Silent(arg) => arg.ops()
  }
}

///|
/// The textual form of the argument (as printed by LLVM, registers by
/// number), or `None` when it is not printed.
fn Arg::text(self : Arg) -> String? {
  match self {
    Gpr(n) | Gpr0(n) | G8(n) | Crf(n) | Crb(n) => Some(n.to_string())
    Imm(v) => Some(v.to_string())
    Mem(disp, base) => Some("\{disp}(\{base})")
    Target(v, absolute~) => {
      let offset = v * 4
      if absolute {
        Some(offset.to_string())
      } else if offset < 0 {
        Some(".\{offset}")
      } else {
        Some(".+\{offset}")
      }
    }
    Silent(_) => None
  }
}

///|
/// A decoded instruction: the LLVM opcode name, the printed mnemonic, the
/// operands and the instruction kinds.
priv struct Spec {
  name : String
  mnemonic : String
  args : Array[Arg]
  kinds : Array[@mc.Kind]
}

///|
fn spec(
  name : String,
  mnemonic : String,
  args : Array[Arg],
  kinds? : Array[@mc.Kind] = [],
) -> Spec {
  { name, mnemonic, args, kinds, }
}

///|
fn Spec::ops(self : Spec) -> Array[@mc.Op] {
  let ops = []
  for arg in self.args {
    ops.push_iter(arg.ops().iter())
  }
  ops
}

///|
fn Spec::assembly(self : Spec) -> String {
  let texts = self.args.filter_map(arg => arg.text())
  if texts.is_empty() {
    self.mnemonic
  } else {
    "\{self.mnemonic} \{texts.join(", ")}"
  }
}
