// Port of BAP `plugins/powerpc/powerpc.ml` (`Powerpc.Std` registration and
// lifting) and `powerpc_main.ml` (target registration).

///|
/// An instruction lifter: produces RTL for one decoded instruction.
pub type InsnLift = (Cpu, Operands) -> Array[Rtl] raise @mc.LiftError

///|
/// Lift with a lifter that cannot fail.
pub fn infallible(f : (Cpu, Operands) -> Array[Rtl]) -> InsnLift {
  (cpu, ops) => f(cpu, ops)
}

///|
/// `concat(f, g)` lifts with `f` then `g` and concatenates the code.
pub fn concat(f : InsnLift, g : InsnLift) -> InsnLift {
  (cpu, ops) => f(cpu, ops) + g(cpu, ops)
}

///|
/// Extend the code of `f` with a signed comparison of the result (the first
/// operand) against zero, recorded in the `CR0` field (the `Rc=1` forms).
pub fn dot(f : InsnLift) -> InsnLift {
  (cpu, ops) => {
    let res = cpu.sreg(ops, 0)
    let x = svar(cpu.word_width)
    f(cpu, ops) +
    [
      x.set(res.low(cpu.word_width)),
      cpu.cr.nth(bit, 0).set(x.lt(zero)),
      cpu.cr.nth(bit, 1).set(x.gt(zero)),
      cpu.cr.nth(bit, 2).set(x.eq(zero)),
    ]
  }
}

///|
let insn_lifters : Map[String, InsnLift] = Map([])

///|
/// Register `lift` as the lifter of the LLVM opcode `name`.
pub fn register_insn(name : String, lift : InsnLift) -> Unit {
  init_builtin_lifters()
  insn_lifters[name] = lift
}

///|
/// See https://reviews.llvm.org/D70758: record forms renamed from `XXXo` to
/// `XXX_rec`.
fn rename_dot_to_rec(name : String) -> String {
  match name.strip_suffix("o") {
    Some(base) => base.to_owned() + "_rec"
    None => name + "_rec"
  }
}

///|
/// Register `dot(lift)` for the record form `name` (e.g. `ADD4o`) and its
/// newer LLVM spelling (`ADD4_rec`).
pub fn register_dot_insn(name : String, lift : InsnLift) -> Unit {
  let lift = dot(lift)
  register_insn(name, lift)
  register_insn(rename_dot_to_rec(name), lift)
}

///|
let builtins_initialized : Ref[Bool] = Ref(false)

///|
fn init_builtin_lifters() -> Unit {
  if !builtins_initialized.val {
    builtins_initialized.val = true
    init_add()
    init_branch()
    init_compare()
    init_cr()
    init_div()
    init_load()
    init_logical()
    init_move()
    init_mul()
    init_rotate()
    init_shift()
    init_store()
    init_sub()
  }
}

///|
/// Instruction lifter registered for the opcode `name`.
pub fn find_insn_lifter(name : String) -> InsnLift? {
  init_builtin_lifters()
  insn_lifters.get(name)
}

///|
/// Names of all opcodes with a registered lifter, sorted.
pub fn supported_insns() -> Array[String] {
  init_builtin_lifters()
  let names = insn_lifters.keys().collect()
  names.sort()
  names
}

///|
/// Lift `insn` to RTL.
pub fn lift_rtl(
  addr_size : AddrSize,
  endian : @bitvec.Endian,
  insn : @mc.Insn,
) -> Array[Rtl] raise @mc.LiftError {
  match find_insn_lifter(insn.name) {
    None => raise Unsupported(insn.name)
    Some(lifter) =>
      lifter(Cpu::create(addr_size, endian, insn.addr), Operands::of_insn(insn))
  }
}

///|
/// Lift `insn` to BIL. Raises `Unsupported` for unknown opcodes and
/// `Failure` when the produced BIL is not well typed.
pub fn lift(
  addr_size : AddrSize,
  endian : @bitvec.Endian,
  insn : @mc.Insn,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let bil = bil_of_rtl(lift_rtl(addr_size, endian, insn))
  match @types.check_stmt_types(bil) {
    Ok(_) => bil
    Err(err) =>
      raise Failure("BIL doesn't type check \{insn.name}: \{err.to_string()}")
  }
}

///|
/// 32-bit big-endian PowerPC lifter (`ppc`).
pub fn lift32(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift(R32, BigEndian, insn)
}

///|
/// 64-bit big-endian PowerPC lifter (`ppc64`).
pub fn lift64(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift(R64, BigEndian, insn)
}

///|
/// 64-bit little-endian PowerPC lifter (`ppc64le`).
pub fn lift64le(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift(R64, LittleEndian, insn)
}

///|
/// Register the PowerPC lifters with `@mc` under the target names `ppc`,
/// `ppc64` and `ppc64le`. Idempotent.
pub fn register() -> Unit {
  init_builtin_lifters()
  @mc.register_lifter("ppc", lift32)
  @mc.register_lifter("ppc64", lift64)
  @mc.register_lifter("ppc64le", lift64le)
}
