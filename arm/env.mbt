// Port of `Arm_env` and the `CPU` module of `Arm_lifter`: the BIL
// variables that model the ARM machine state.

///|
fn reg32(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::reg32_t())
}

///|
fn flag(name : String) -> @types.Var {
  @types.Var::new(name~, typ=@types.ValueType::bool_t())
}

///|
/// The placeholder `Nil` register.
pub let nil : @types.Var = reg32("Nil")

///|
/// Saved program status register.
pub let spsr : @types.Var = reg32("SPSR")

///|
/// Current program status register.
pub let cpsr : @types.Var = reg32("CPSR")

///|
pub let nf : @types.Var = flag("NF")

///|
pub let zf : @types.Var = flag("ZF")

///|
pub let cf : @types.Var = flag("CF")

///|
pub let vf : @types.Var = flag("VF")

///|
pub let qf : @types.Var = flag("QF")

///|
/// Greater-than-or-equal flags `GE0`..`GE3` used by SIMD instructions.
pub let ge : ReadOnlyArray[@types.Var] = [
  flag("GE0"),
  flag("GE1"),
  flag("GE2"),
  flag("GE3"),
]

///|
/// Thumb if-then state register.
pub let itstate : @types.Var = @types.Var::new(
  name="ITSTATE",
  typ=@types.ValueType::reg8_t(),
)

///|
pub let lr : @types.Var = reg32("LR")

///|
pub let pc : @types.Var = reg32("PC")

///|
pub let sp : @types.Var = reg32("SP")

///|
pub let r0 : @types.Var = reg32("R0")

///|
pub let r1 : @types.Var = reg32("R1")

///|
pub let r2 : @types.Var = reg32("R2")

///|
pub let r3 : @types.Var = reg32("R3")

///|
pub let r4 : @types.Var = reg32("R4")

///|
pub let r5 : @types.Var = reg32("R5")

///|
pub let r6 : @types.Var = reg32("R6")

///|
pub let r7 : @types.Var = reg32("R7")

///|
pub let r8 : @types.Var = reg32("R8")

///|
pub let r9 : @types.Var = reg32("R9")

///|
pub let r10 : @types.Var = reg32("R10")

///|
pub let r11 : @types.Var = reg32("R11")

///|
pub let r12 : @types.Var = reg32("R12")

///|
/// The byte-addressed 32-bit memory.
pub let mem : @types.Var = @types.Var::new(
  name="mem",
  typ=@types.ValueType::mem32_t(R8),
)

///|
/// `Arm_env.of_reg`: the BIL variable of a register.
pub fn Reg::to_var(self : Reg) -> @types.Var {
  match self {
    Nil => nil
    R0 => r0
    R1 => r1
    R2 => r2
    R3 => r3
    R4 => r4
    R5 => r5
    R6 => r6
    R7 => r7
    R8 => r8
    R9 => r9
    R10 => r10
    R11 => r11
    R12 => r12
    LR => lr
    PC => pc
    SP => sp
    CPSR => cpsr
    SPSR => spsr
    ITSTATE => itstate
  }
}

///|
/// `CPU.regs`: all machine registers.
pub fn cpu_regs() -> Array[@types.Var] {
  [
    r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, pc, sp, lr, spsr, cpsr,
    itstate,
  ]
}

///|
/// `CPU.gpr`: general purpose registers (PC excluded).
pub fn cpu_gpr() -> Array[@types.Var] {
  cpu_regs().filter(v => !(v == pc || v == spsr || v == cpsr || v == itstate))
}

///|
/// `CPU.perms`: callee-preserved registers.
pub fn cpu_perms() -> Array[@types.Var] {
  [r4, r5, r6, r7, r8, r9, r10, r11]
}

///|
/// `CPU.flags`: status flags.
pub fn cpu_flags() -> Array[@types.Var] {
  [nf, zf, cf, qf, vf, ge[0], ge[1], ge[2], ge[3]]
}

///|
fn contains_base(vars : Array[@types.Var], v : @types.Var) -> Bool {
  let base = v.base()
  vars.iter().any(x => x.same(base))
}

///|
pub fn is_reg(v : @types.Var) -> Bool {
  contains_base(cpu_regs(), v)
}

///|
pub fn is_flag(v : @types.Var) -> Bool {
  contains_base(cpu_flags(), v)
}

///|
pub fn is_sp(v : @types.Var) -> Bool {
  v.same(sp)
}

///|
/// The frame pointer is `R11`.
pub fn is_bp(v : @types.Var) -> Bool {
  v.same(r11)
}

///|
pub fn is_pc(v : @types.Var) -> Bool {
  v.same(pc)
}

///|
pub fn is_mem(v : @types.Var) -> Bool {
  v.same(mem)
}

///|
pub fn is_zf(v : @types.Var) -> Bool {
  v.same(zf)
}

///|
pub fn is_cf(v : @types.Var) -> Bool {
  v.same(cf)
}

///|
pub fn is_vf(v : @types.Var) -> Bool {
  v.same(vf)
}

///|
pub fn is_nf(v : @types.Var) -> Bool {
  v.same(nf)
}

///|
/// `CPU.addr_of_pc`: reading `PC` yields the instruction address plus 8.
pub fn addr_of_pc(addr : UInt64) -> UInt64 {
  addr + 8
}
