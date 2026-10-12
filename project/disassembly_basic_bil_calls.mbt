// The Basic BIL of the x86 calls and returns, as the upstream x86 lifter
// (`plugins/x86/x86_lifter.ml`): a call pushes the return address and
// jumps to the callee; a return pops the return address (and the
// immediate number of bytes) and jumps to it.

///|
priv suberror ProjectBasicBilFailure {
  ProjectBasicBilFailure(String)
}

///|
fn[T] bil_ok(result : Result[T, String]) -> T raise ProjectBasicBilFailure {
  match result {
    Ok(value) => value
    Err(reason) => raise ProjectBasicBilFailure(reason)
  }
}

///|
fn project_basic_bil_result(
  f : () -> Array[@types.Stmt] raise ProjectBasicBilFailure,
) -> Result[Array[@types.Stmt], String] {
  try f() catch {
    ProjectBasicBilFailure(reason) => Err(reason)
  } noraise {
    stmts => Ok(stmts)
  }
}

///|
/// `SP := SP - w/8; mem[SP] := next` (the return address push of a call
/// with `w`-bit addresses).
fn ProjectDisassemblyInstruction::project_basic_bil_push_return(
  self : ProjectDisassemblyInstruction,
  width : Int32,
) -> Array[@types.Stmt] raise ProjectBasicBilFailure {
  let sp = bil_ok(project_basic_bil_stack_pointer(width))
  let decremented = bil_ok(project_basic_bil_stack_decrement(sp, width, width))
  let size = bil_ok(@types.Size::of_int(width))
  let next = bil_ok(
    project_basic_bil_addr_with_width(self.memory().max_addr() + 1UL, width),
  )
  let mem = project_basic_bil_stack_mem(width)
  [
    @types.Stmt::move_stmt(sp, decremented),
    @types.Stmt::move_stmt(
      mem,
      @types.Exp::store(
        mem=@types.Exp::var_exp(mem),
        addr=@types.Exp::var_exp(sp),
        next,
        LittleEndian,
        size,
      ),
    ),
  ]
}

///|
/// A direct call: the return address push, then the jump to the callee
/// (with the Basic `call` hint).
fn ProjectDisassemblyInstruction::project_basic_bil_call(
  self : ProjectDisassemblyInstruction,
  width : Int32,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let target = bil_ok(self.project_basic_bil_direct_target())
    let push = self.project_basic_bil_push_return(width)
    let jump = bil_ok(
      project_basic_bil_control_with_width(@types.Stmt::call(), target, width),
    )
    push + jump
  })
}

///|
/// An indirect call through `target`: the target is evaluated first (it may
/// depend on the stack pointer), then the return address is pushed and
/// control jumps to the target.
fn ProjectDisassemblyInstruction::project_basic_bil_indirect_call(
  self : ProjectDisassemblyInstruction,
  width : Int32,
  target : @types.Exp,
) -> Array[@types.Stmt] raise ProjectBasicBilFailure {
  let tmp = project_basic_bil_virtual("call_target", width)
  let push = self.project_basic_bil_push_return(width)
  [@types.Stmt::move_stmt(tmp, target)] +
  push +
  project_basic_bil_indirect_control(
    @types.Stmt::call(),
    @types.Exp::var_exp(tmp),
  )
}

///|
/// A call through a register.
fn ProjectDisassemblyInstruction::project_basic_bil_call_reg(
  self : ProjectDisassemblyInstruction,
  width : Int32,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let target = bil_ok(self.project_basic_bil_register(0, width))
    self.project_basic_bil_indirect_call(width, @types.Exp::var_exp(target))
  })
}

///|
/// A call through memory.
fn ProjectDisassemblyInstruction::project_basic_bil_call_mem(
  self : ProjectDisassemblyInstruction,
  width : Int32,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let (addr, mem, _) = bil_ok(self.project_basic_bil_memory_addr(0))
    let size = bil_ok(@types.Size::of_int(width))
    self.project_basic_bil_indirect_call(
      width,
      @types.Exp::load(mem=@types.Exp::var_exp(mem), addr~, LittleEndian, size),
    )
  })
}

///|
/// A return with `w`-bit addresses: `tmp := mem[SP]; SP := SP + w/8` (for
/// a far return, the code segment selector slot is popped too, and the
/// selector is ignored); `SP := SP + imm` when the instruction has an
/// immediate operand; `jmp tmp`.
fn ProjectDisassemblyInstruction::project_basic_bil_ret(
  self : ProjectDisassemblyInstruction,
  width : Int32,
  far~ : Bool,
) -> Result[Array[@types.Stmt], String] {
  project_basic_bil_result(() => {
    let sp = bil_ok(project_basic_bil_stack_pointer(width))
    let size = bil_ok(@types.Size::of_int(width))
    let mem = project_basic_bil_stack_mem(width)
    let tmp = project_basic_bil_virtual("ret_addr", width)
    let slots = if far { 2 * width } else { width }
    let stmts = [
      @types.Stmt::move_stmt(
        tmp,
        @types.Exp::load(
          mem=@types.Exp::var_exp(mem),
          addr=@types.Exp::var_exp(sp),
          LittleEndian,
          size,
        ),
      ),
      @types.Stmt::move_stmt(
        sp,
        bil_ok(project_basic_bil_stack_increment(sp, slots, width)),
      ),
    ]
    if self.operands().length() > 0 {
      let imm = bil_ok(self.project_basic_bil_immediate(0))
      stmts.push(
        @types.Stmt::move_stmt(
          sp,
          @types.Exp::binop(
            @types.BinOp::plus(),
            @types.Exp::var_exp(sp),
            bil_ok(project_basic_bil_int(imm, width)),
          ),
        ),
      )
    }
    stmts.push(@types.Stmt::jmp(@types.Exp::var_exp(tmp)))
    stmts
  })
}
