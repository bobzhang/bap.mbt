// Lifting sequences of disassembled instructions (blocks, the whole
// disassembly) through the lifter registry, with delay-slot handling and
// retention of per-instruction lifting failures.

///|
/// A failure to lift one instruction: its address, opcode name and the
/// reason reported by the lifters.
pub struct ProjectLiftError {
  addr : UInt64
  opcode : String
  message : String
} derive(Eq, Debug)

///|
pub extend ProjectLiftError with Eq::{equal, not_equal}

///|
pub extend ProjectLiftError with Debug::{to_repr}

///|
pub fn ProjectLiftError::create(
  addr~ : UInt64,
  opcode~ : String,
  message~ : String,
) -> ProjectLiftError {
  { addr, opcode, message, }
}

///|
pub fn ProjectLiftError::addr(self : ProjectLiftError) -> UInt64 {
  self.addr
}

///|
pub fn ProjectLiftError::opcode(self : ProjectLiftError) -> String {
  self.opcode
}

///|
pub fn ProjectLiftError::message(self : ProjectLiftError) -> String {
  self.message
}

///|
/// `<opcode> at 0x<addr>: <message>`.
pub fn ProjectLiftError::to_string(self : ProjectLiftError) -> String {
  "\{self.opcode} at 0x\{self.addr.to_string(radix=16)}: \{self.message}"
}

///|
/// The registry used by project-level lifting when none is given: the
/// process-wide `@mc` registry, with the built-in lifters registered.
fn project_lift_registry() -> @mc.Registry {
  register_builtin_lifters()
  @mc.Registry::global()
}

///|
/// Whether `stmt` transfers control (or marks a transfer, like the `call`
/// and `goto` specials of the Basic lifter).
fn project_lift_is_control(stmt : @types.Stmt) -> Bool {
  match stmt {
    Jmp(_) | Special(_) | CpuExn(_) => true
    If(yes~, no~, ..) =>
      yes.iter().any(project_lift_is_control) ||
      no.iter().any(project_lift_is_control)
    While(body~, ..) => body.iter().any(project_lift_is_control)
    Move(_, _) => false
  }
}

///|
/// Whether `exp` reads a variable assigned by `stmts`.
fn project_lift_reads_assigned(
  exp : @types.Exp,
  stmts : Array[@types.Stmt],
) -> Bool {
  exp.free_vars().iter().any(v => @types.is_assigned(stmts, v))
}

///|
/// Fresh virtual variables holding the values the delayed control
/// statements of a branch must observe.
priv struct ProjectDelayTemps {
  prefix : String
  mut next : Int
  defs : Array[@types.Stmt]
}

///|
/// `exp`, or a fresh temporary assigned `exp` now when the delay-slot code
/// `delayed` assigns one of the variables `exp` reads.
fn ProjectDelayTemps::capture(
  self : ProjectDelayTemps,
  exp : @types.Exp,
  delayed : Array[@types.Stmt],
) -> @types.Exp {
  if !project_lift_reads_assigned(exp, delayed) {
    return exp
  }
  match exp.infer_type() {
    Ok(typ) => {
      let tmp = @types.Var::new(
        name="\{self.prefix}\{self.next}",
        typ~,
        is_virtual=true,
      )
      self.next += 1
      self.defs.push(@types.Stmt::move_stmt(tmp, exp))
      @types.Exp::var_exp(tmp)
    }
    Err(_) => exp
  }
}

///|
/// Rewrite a delayed control statement so that its condition and
/// destinations read the values from before the delay slot.
fn ProjectDelayTemps::control(
  self : ProjectDelayTemps,
  stmt : @types.Stmt,
  delayed : Array[@types.Stmt],
) -> @types.Stmt {
  match stmt {
    Jmp(dst) => Jmp(self.capture(dst, delayed))
    If(cond~, yes~, no~) =>
      If(
        cond=self.capture(cond, delayed),
        yes=yes.map(s => self.control(s, delayed)),
        no=no.map(s => self.control(s, delayed)),
      )
    stmt => stmt
  }
}

///|
/// Concatenate the semantics of a sequence of instructions, honoring delay
/// slots (upstream `Insn.Slot.delay`): the control-transfer statements of
/// an instruction with `delay = n` are placed after the semantics of the
/// next `n` instructions, as the disassembler driver of upstream moves the
/// jump after its delay slot. Conditions and destinations that read
/// variables written by the delay-slot instructions are captured in virtual
/// temporaries (`delay_slot_<addr>_<n>`) before the delay slot, so the
/// branch still observes the values from before it.
///
/// `lifted` holds one result per instruction; failures (`Err`) contribute no
/// statements but still occupy their delay-slot position.
fn project_lift_sequence(
  instructions : Array[ProjectDisassemblyInstruction],
  lifted : Array[Result[@mc.Lifted, String]],
) -> Array[@types.Stmt] {
  let result : Array[@types.Stmt] = []
  // delayed control statements with the number of instructions to wait
  let pending : Array[(Int, Array[@types.Stmt])] = []
  for i, insn in instructions {
    match lifted[i] {
      Ok(item) if item.delay() > 0 => {
        let delayed : Array[@types.Stmt] = []
        let last = i + item.delay()
        for j in (i + 1)..<=last {
          if lifted.get(j) is Some(Ok(slot)) {
            delayed.push_iter(slot.bil().iter())
          }
        }
        let temps : ProjectDelayTemps = {
          prefix: "delay_slot_\{insn.addr().to_string(radix=16)}_",
          next: 0,
          defs: [],
        }
        let now : Array[@types.Stmt] = []
        let later : Array[@types.Stmt] = []
        for stmt in item.bil() {
          if project_lift_is_control(stmt) {
            later.push(temps.control(stmt, delayed))
          } else {
            now.push(stmt)
          }
        }
        result.push_iter(now.iter())
        result.push_iter(temps.defs.iter())
        project_lift_release(pending, result)
        pending.push((item.delay(), later))
      }
      Ok(item) => {
        result.push_iter(item.bil().iter())
        project_lift_release(pending, result)
      }
      Err(_) => project_lift_release(pending, result)
    }
  }
  for entry in pending {
    result.push_iter(entry.1.iter())
  }
  result
}

///|
/// Count down the pending delayed control statements after one more
/// instruction, emitting those whose delay slots are complete.
fn project_lift_release(
  pending : Array[(Int, Array[@types.Stmt])],
  result : Array[@types.Stmt],
) -> Unit {
  let waiting : Array[(Int, Array[@types.Stmt])] = []
  for entry in pending {
    let (count, stmts) = entry
    if count <= 1 {
      result.push_iter(stmts.iter())
    } else {
      waiting.push((count - 1, stmts))
    }
  }
  pending.clear()
  pending.push_iter(waiting.iter())
}

///|
/// Lift `instructions` on `target`, keeping the semantics of the lifted ones
/// and a `ProjectLiftError` for each failure.
fn project_lift_instructions(
  instructions : Array[ProjectDisassemblyInstruction],
  target : @core_theory.Target,
  registry : @mc.Registry,
) -> (Array[@types.Stmt], Array[ProjectLiftError]) {
  let lifted = instructions.map(insn => insn.lift(target~, registry~))
  let errors : Array[ProjectLiftError] = []
  for i, insn in instructions {
    if lifted[i] is Err(message) {
      errors.push({ addr: insn.addr(), opcode: insn.name(), message, })
    }
  }
  (project_lift_sequence(instructions, lifted), errors)
}

///|
/// Lift `instructions` on `target`, failing on the first instruction that
/// cannot be lifted.
fn project_lift_instructions_strict(
  instructions : Array[ProjectDisassemblyInstruction],
  target : @core_theory.Target,
  registry : @mc.Registry,
  context : String,
) -> Result[Array[@types.Stmt], String] {
  let (stmts, errors) = project_lift_instructions(
    instructions, target, registry,
  )
  match errors {
    [] => Ok(stmts)
    [error, ..] =>
      Err(
        "failed to lift \{error.opcode} at 0x\{error.addr.to_string(radix=16)}\{context}: \{error.message}",
      )
  }
}

///|
/// Lift the instructions of the block on `target` (see
/// `ProjectDisassemblyInstruction::lift`), placing the control transfers of
/// delayed branches after their delay slots. Fails on the first instruction
/// that cannot be lifted.
pub fn ProjectDisassemblyBlock::lift(
  self : ProjectDisassemblyBlock,
  target~ : @core_theory.Target,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[Array[@types.Stmt], String] {
  project_lift_instructions_strict(
    self.instructions(),
    target,
    registry,
    " in block \{self.to_string()}",
  )
}

///|
/// Lift the instructions of the block on `target`, keeping going past
/// failures: returns the semantics of the lifted instructions and the
/// failures.
pub fn ProjectDisassemblyBlock::lift_partial(
  self : ProjectDisassemblyBlock,
  target~ : @core_theory.Target,
  registry? : @mc.Registry = project_lift_registry(),
) -> (Array[@types.Stmt], Array[ProjectLiftError]) {
  project_lift_instructions(self.instructions(), target, registry)
}

///|
/// Lift all disassembled instructions on `target`. Fails on the first
/// instruction that cannot be lifted.
pub fn ProjectDisassemblyState::lift(
  self : ProjectDisassemblyState,
  target~ : @core_theory.Target,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[Array[@types.Stmt], String] {
  project_lift_instructions_strict(self.instructions(), target, registry, "")
}

///|
/// Lift all disassembled instructions on `target`, returning a failure for
/// each instruction that cannot be lifted (and nothing else).
pub fn ProjectDisassemblyState::lift_errors(
  self : ProjectDisassemblyState,
  target~ : @core_theory.Target,
  registry? : @mc.Registry = project_lift_registry(),
) -> Array[ProjectLiftError] {
  project_lift_instructions(self.instructions(), target, registry).1
}

///|
/// Lift the disassembly of the project on the project target.
pub fn ProjectDisasm::lift(
  self : ProjectDisasm,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[Array[@types.Stmt], String] {
  let project = self.project_value
  project.disassembly().lift(target=project.target(), registry~)
}

///|
/// Lift the disassembly of the project on the project target.
pub fn Project::lift(
  self : Project,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[Array[@types.Stmt], String] {
  self.disassembly().lift(target=self.target(), registry~)
}

///|
/// The instructions that could not be lifted during the last
/// reconstruction of the project (empty before any reconstruction), in
/// block order. Reconstruction keeps the semantics of the other
/// instructions of a block.
pub fn Project::lift_errors(self : Project) -> Array[ProjectLiftError] {
  self.lift_errors_value.copy()
}

///|
/// Replace the recorded lift errors.
pub fn Project::with_lift_errors(
  self : Project,
  errors : Array[ProjectLiftError],
) -> Project {
  { ..self, lift_errors_value: errors.copy(), }
}
