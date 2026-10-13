// Operands of decoded PowerPC instructions and their textual form.
//
// The operands follow the conventions of the LLVM PowerPC disassembler
// (`PPCDisassembler.cpp`, LLVM 22): general purpose registers are
// `R0`..`R31` (`gprc`) or `X0`..`X31` (`g8rc`); register operands that
// cannot be `r0` (`gprc_nor0`, the base of memory operands) decode `0` as
// `ZERO`; condition register fields are `CR0`..`CR7` and condition
// register bits `CR0LT`, `CR0GT`, `CR0EQ`, `CR0UN`, ..., `CR7UN`. Memory
// operands are a displacement followed by the base register; the
// displacement of the D-form loads and stores is the raw (zero-extended)
// 16-bit field, as LLVM leaves it (the printer and the lifter sign-extend
// it), the DS-form displacement is sign-extended and scaled. Branch
// targets are the (sign-extended) word offsets as encoded, not multiplied
// by four.

///|
/// A decoded operand, before it is turned into `@mc.Op`s and text.
priv enum Arg {
  /// `gprc` register.
  Gpr(Int32)
  /// `gprc_nor0` register: `0` is `ZERO`.
  Gpr0(Int32)
  /// `g8rc` register.
  G8(Int32)
  /// Condition register field.
  Crf(Int32)
  /// Condition register bit.
  Crb(Int32)
  /// Integer immediate.
  Imm(Int64)
  /// Memory operand `disp(base)`: an immediate and a `gprc_nor0` base. The
  /// displacement is printed sign-extended from 16 bits.
  Mem(Int64, Int32)
  /// Branch target (in words): relative unless absolute.
  Target(Int64, absolute~ : Bool)
  /// An operand present in the instruction but not printed (tied operands
  /// and operands elided by extended mnemonics).
  Silent(Arg)
}

///|
let crbit_names : FixedArray[String] = ["LT", "GT", "EQ", "UN"]

///|
fn gpr_op(n : Int32) -> @mc.Op {
  @mc.Op::reg("R\{n}")
}

///|
fn gpr0_op(n : Int32) -> @mc.Op {
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
/// `v` in LLVM's `formatHex` style (`0x` and lowercase digits).
fn hex(v : UInt64) -> String {
  "0x" + v.to_string(radix=16)
}

///|
/// The textual form of the argument (as printed by LLVM, registers by
/// number), or `None` when it is not printed. Absolute branch targets are
/// printed as addresses, truncated to 32 bits unless `wide`.
fn Arg::text(self : Arg, wide~ : Bool) -> String? {
  match self {
    Gpr(n) | Gpr0(n) | G8(n) | Crf(n) | Crb(n) => Some(n.to_string())
    Imm(v) => Some(v.to_string())
    Mem(disp, base) => Some("\{sext(disp.to_int() & 0xffff, 16)}(\{base})")
    Target(v, absolute~) => {
      let offset = v * 4
      if absolute {
        let target = offset.reinterpret_as_uint64()
        Some(hex(if wide { target } else { target & 0xffff_ffffUL }))
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
/// operands and the instruction kinds. The printed operands are the
/// operands themselves unless `printed` overrides them (extended mnemonics
/// that reorder or recompute operands, e.g. `sub` or `srwi`).
priv struct Spec {
  name : String
  mnemonic : String
  args : Array[Arg]
  kinds : Array[@mc.Kind]
  printed : Array[Arg]?
}

///|
fn spec(
  name : String,
  mnemonic : String,
  args : Array[Arg],
  kinds~ : Array[@mc.Kind] = [],
) -> Spec {
  { name, mnemonic, args, kinds, printed: None, }
}

///|
/// The same instruction printed as `mnemonic printed...`.
fn Spec::printed_as(
  self : Spec,
  mnemonic : String,
  printed : Array[Arg],
) -> Spec {
  { ..self, mnemonic, printed: Some(printed), }
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
/// The assembly of the instruction; `wide` for 64-bit code (see
/// `Arg::text`).
fn Spec::assembly(self : Spec, wide~ : Bool) -> String {
  let printed = match self.printed {
    Some(printed) => printed
    None => self.args
  }
  let texts = printed.filter_map(arg => arg.text(wide~))
  if texts.is_empty() {
    self.mnemonic
  } else {
    "\{self.mnemonic} \{texts.join(", ")}"
  }
}
