// Bridge between project disassembly instructions and the architecture
// lifters registered in the shared `mc` package.

///|
/// Convert a decoded project instruction into the shared `@mc.Insn`
/// representation consumed by architecture lifters.
pub fn ProjectDisassemblyInstruction::to_mc_insn(
  self : ProjectDisassemblyInstruction,
) -> @mc.Insn {
  let ops = self
    .operands()
    .map(op => {
      match op {
        ProjectRegisterOperand(code, name) => @mc.Reg(name~, code~)
        ProjectImmediateOperand(value) => @mc.Imm(value)
        ProjectFloatingOperand(value) => @mc.Fmm(value)
      }
    })
  @mc.Insn::create(
    self.name(),
    ops,
    addr=self.addr(),
    size=self.memory().length(),
    assembly=self.assembly(),
  )
}

///|
/// Lift the instruction with the lifter registered in `@mc` for `target`
/// (e.g. `mips`, `powerpc`, `arm`), falling back to an error message when no
/// lifter is registered or lifting fails.
pub fn ProjectDisassemblyInstruction::lift_registered_bil(
  self : ProjectDisassemblyInstruction,
  target~ : String,
) -> Result[Array[@types.Stmt], String] {
  try @mc.lift(target, self.to_mc_insn()) catch {
    err => Err(err.message())
  } noraise {
    stmts => Ok(stmts)
  }
}
