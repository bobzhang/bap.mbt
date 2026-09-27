// Port of `Arm_branch`.

///|
/// `Arm_branch.lift`: jump to a register or to a PC-relative immediate
/// target (the ARM PC reads as the instruction address plus 8), optionally
/// saving the return address in `LR`.
fn branch_lift(
  operand : Op,
  link? : Bool = false,
  cond? : Op,
  addr : UInt,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let target = match operand {
    Reg(r) => v(r.to_var())
    Imm(offset) => {
      let offset = if offset == 0x80000000 { 0U } else { offset }
      int32(addr + 8 + offset)
    }
  }
  let stmts : Array[@types.Stmt] = if link {
    [assign(lr, int32(addr + 8 - 4))]
  } else {
    []
  }
  stmts.push(Jmp(target))
  match cond {
    Some(c) => exec(stmts, c)
    None => stmts
  }
}
