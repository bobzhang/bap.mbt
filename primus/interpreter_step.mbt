///|
/// The result of evaluating the jumps of a block (upstream `constr`): no
/// jump taken yet (`Init`), none of the conditions held so far (`Conj`,
/// with the conjunction of negated conditions) or a jump was taken
/// (`Disj`, with the accumulated condition and the taken jump).
priv enum Constr {
  Init
  Conj(Value)
  Disj(Value, @types.Term[@types.Jmp])
}

///|
/// The interpreter context of a caller, saved when a subroutine is entered
/// (and around nested runs) and restored when it returns: the current
/// position and the block bookkeeping used to select phi-node options.
priv struct Ctx {
  curr : Pos
  last_blk : @types.Tid?
  prev_blk : @types.Tid?
}

///|
fn save_ctx(m : Machine) -> Ctx {
  let s = m.get_local(interpreter_state)
  { curr: s.curr, last_blk: s.last_blk, prev_blk: s.prev_blk, }
}

///|
fn restore_ctx(m : Machine, ctx : Ctx) -> Unit {
  m.update_local(interpreter_state, s => {
    ..s,
    curr: ctx.curr,
    last_blk: ctx.last_blk,
    prev_blk: ctx.prev_blk,
  })
}

///|
fn[T] update_pc(m : Machine, t : @types.Term[T]) -> Unit raise {
  guard term_address(t) is Some(addr) else { return }
  let s = m.get_local(interpreter_state)
  m.put_local(interpreter_state, { ..s, addr, })
  if s.addr != addr {
    m.make(pc_changed_stmt, addr)
  }
}

///|
fn set_curr(m : Machine, curr : Pos) -> Unit {
  m.update_local(interpreter_state, s => { ..s, curr, })
}

///|
fn curr_pos(m : Machine) -> Pos {
  m.get_local(interpreter_state).curr
}

///|
/// Moves to the term and posts `enter-pos`, `enter-term` and `enter-<kind>`
/// as a resumable boundary (must be the last action of a step).
fn[T] enter_boundary(
  m : Machine,
  pos : Pos,
  t : @types.Term[T],
  stmt : Statement[@types.Term[T]],
) -> Unit raise {
  update_pc(m, t)
  set_curr(m, pos)
  let b = m.boundary()
  b.add(enter_pos_stmt, pos)
  b.add(enter_term_stmt, t.tid())
  b.add(stmt, t)
  b.dispatch()
}

///|
/// Posts `leave-<kind>`, `leave-term` and `leave-pos` as a resumable
/// boundary (must be the last action of a step).
fn[T] leave_boundary(
  m : Machine,
  pos : Pos,
  t : @types.Term[T],
  stmt : Statement[@types.Term[T]],
) -> Unit raise {
  let b = m.boundary()
  b.add(stmt, t)
  b.add(leave_term_stmt, t.tid())
  b.add(leave_pos_stmt, pos)
  b.dispatch()
}

///|
/// Evaluates an argument term synchronously (inside the subroutine entry
/// and return steps).
fn eval_arg(
  m : Machine,
  arg : @types.Term[@types.Arg],
  when_ : (@types.Intent?) -> Bool,
) -> Unit raise {
  let pos = curr_pos(m).next_arg(arg)
  update_pc(m, arg)
  set_curr(m, pos)
  m.make(enter_pos_stmt, pos)
  m.make(enter_term_stmt, arg.tid())
  m.make(enter_arg_stmt, arg)
  if when_(arg.intent()) {
    let x = Interpreter::exp(m, arg.arg_rhs())
    Interpreter::set(m, arg.arg_lhs(), x)
  }
  m.make(leave_arg_stmt, arg)
  m.make(leave_term_stmt, arg.tid())
  m.make(leave_pos_stmt, pos)
}

///|
fn is_out_intent(i : @types.Intent?) -> Bool {
  i is Some(Out)
}

///|
fn step_sub_enter(m : Machine, sub : @types.Term[@types.Sub]) -> Unit raise {
  let ctx = save_ctx(m)
  let pos = curr_pos(m).next_sub(sub)
  m.push(SubStart(sub, pos, ctx))
  enter_boundary(m, pos, sub, enter_sub_stmt)
}

///|
fn step_sub_start(
  m : Machine,
  sub : @types.Term[@types.Sub],
  pos : Pos,
  ctx : Ctx,
) -> Unit raise {
  match sub.first_blk() {
    None => {
      restore_ctx(m, ctx)
      leave_boundary(m, pos, sub, leave_sub_stmt)
    }
    Some(entry) => {
      let args = sub.args()
      for arg in args {
        eval_arg(m, arg, i => !is_out_intent(i))
      }
      let inputs = []
      for arg in args {
        if !is_out_intent(arg.intent()) {
          inputs.push(Interpreter::exp(m, arg.arg_rhs()))
        }
      }
      m.post(call_entered, () => (@types.Sub::name(sub), inputs.copy()))
      m.push(SubLeave(sub, pos, inputs, ctx))
      m.push(BlkEnter(entry))
    }
  }
}

///|
fn step_sub_leave(
  m : Machine,
  sub : @types.Term[@types.Sub],
  pos : Pos,
  inputs : Array[Value],
  ctx : Ctx,
) -> Unit raise {
  let args = sub.args()
  for arg in args {
    eval_arg(m, arg, is_out_intent)
  }
  let mut result : Value? = None
  for arg in args {
    if is_out_intent(arg.intent()) && Env::is_set(m, arg.arg_lhs()) {
      result = Some(Env::get(m, arg.arg_lhs()))
      break
    }
  }
  m.post(call_returned, () => {
    let all = inputs.copy()
    for arg in args {
      if is_out_intent(arg.intent()) {
        all.push(Interpreter::exp(m, arg.arg_rhs()))
      }
    }
    (@types.Sub::name(sub), all)
  })
  restore_ctx(m, ctx)
  m.current.result = result
  leave_boundary(m, pos, sub, leave_sub_stmt)
}

///|
fn step_blk_enter(m : Machine, blk : @types.Term[@types.Blk]) -> Unit raise {
  let pos = curr_pos(m).next_blk(blk)
  let s = m.get_local(interpreter_state)
  m.put_local(interpreter_state, {
    ..s,
    prev_blk: s.last_blk,
    last_blk: Some(blk.tid()),
  })
  m.push(BlkElt(blk, pos, 0))
  enter_boundary(m, pos, blk, enter_blk_stmt)
}

///|
/// Enters the i-th phi node or definition of the block; after the last
/// one, enters the first jump.
fn step_blk_elt(
  m : Machine,
  blk : @types.Term[@types.Blk],
  pos : Pos,
  i : Int,
) -> Unit raise {
  let b = blk.payload()
  let nphis = b.phis.length()
  let ndefs = b.defs.length()
  if i < nphis {
    let phi = b.phis[i]
    let epos = curr_pos(m).next_phi(phi)
    m.push(BlkEltBody(blk, pos, i, epos))
    enter_boundary(m, epos, phi, enter_phi_stmt)
  } else if i < nphis + ndefs {
    let def = b.defs[i - nphis]
    let epos = curr_pos(m).next_def(def)
    m.push(BlkEltBody(blk, pos, i, epos))
    enter_boundary(m, epos, def, enter_def_stmt)
  } else {
    step_blk_jmp(m, blk, pos, 0, Init)
  }
}

///|
/// Evaluates and leaves the i-th phi node or definition of the block.
fn step_blk_elt_body(
  m : Machine,
  blk : @types.Term[@types.Blk],
  pos : Pos,
  i : Int,
  epos : Pos,
) -> Unit raise {
  let b = blk.payload()
  let nphis = b.phis.length()
  m.push(BlkElt(blk, pos, i + 1))
  if i < nphis {
    let phi = b.phis[i]
    if m.get_local(interpreter_state).prev_blk is Some(pred) {
      for option in phi.payload().values {
        if option.0 == pred {
          let x = Interpreter::exp(m, option.1)
          Interpreter::set(m, phi.phi_lhs(), x)
          break
        }
      }
    }
    leave_boundary(m, epos, phi, leave_phi_stmt)
  } else {
    let def = b.defs[i - nphis]
    let x = Interpreter::exp(m, def.def_value())
    Interpreter::set(m, def.def_var(), x)
    leave_boundary(m, epos, def, leave_def_stmt)
  }
}

///|
/// Enters the i-th jump of the block; after the last one, leaves the block.
fn step_blk_jmp(
  m : Machine,
  blk : @types.Term[@types.Blk],
  pos : Pos,
  i : Int,
  constr : Constr,
) -> Unit raise {
  let jmps = blk.payload().jmps
  if i < jmps.length() {
    let t = jmps[i]
    let jpos = curr_pos(m).next_jmp(t)
    m.push(BlkJmpBody(blk, pos, i, constr, jpos))
    enter_boundary(m, jpos, t, enter_jmp_stmt)
  } else {
    // the taken jump is performed by its own step, after `leave-blk`
    if constr is Disj(cond, t) {
      m.push(Jump(cond, t))
    }
    leave_boundary(m, pos, blk, leave_blk_stmt)
  }
}

///|
/// Evaluates the condition of the i-th jump (upstream `jmp constr t`) and
/// leaves the jump.
fn step_blk_jmp_body(
  m : Machine,
  blk : @types.Term[@types.Blk],
  pos : Pos,
  i : Int,
  constr : Constr,
  jpos : Pos,
) -> Unit raise {
  let t = blk.payload().jmps[i]
  let v = Interpreter::exp(m, t.cond())
  let r = match (constr, v.value.is_one()) {
    (Init, true) => {
      m.make(on_cond_stmt, v)
      Disj(v, t)
    }
    (Init, false) => {
      m.make(on_cond_stmt, v)
      Conj(Interpreter::unop(m, Not, v))
    }
    (Conj(u), false) => {
      let w = Interpreter::binop(m, And, u, v)
      m.make(on_cond_stmt, w)
      let nv = Interpreter::unop(m, Not, v)
      Conj(Interpreter::binop(m, And, u, nv))
    }
    (Conj(u), true) => {
      let w = Interpreter::binop(m, And, u, v)
      m.make(on_cond_stmt, w)
      Disj(w, t)
    }
    (Disj(u, taken), _) => {
      let p = Interpreter::unop(m, Not, u)
      let w = Interpreter::binop(m, And, p, v)
      m.make(on_cond_stmt, w)
      Disj(Interpreter::binop(m, Or, u, v), taken)
    }
  }
  m.push(BlkJmp(blk, pos, i + 1, r))
  leave_boundary(m, jpos, t, leave_jmp_stmt)
}

///|
fn top_prompt(m : Machine) -> @types.Tid? {
  m.get_local(interpreter_state).prompts.head()
}

///|
fn exec_to_prompt(m : Machine, dst : @types.Tid) -> Unit raise {
  if top_prompt(m) is Some(p) && p == dst {
    ()
  } else {
    exec_tail(m, Tid(dst))
  }
}

///|
fn will_jump_to_tid(m : Machine, cond : Value, dst : @types.Tid) -> Unit raise {
  guard Linker::resolve_addr(m, Tid(dst)) is Some(addr) else { return }
  let dst = value(m, addr)
  Interpreter::tick(m)
  m.post(will_jump_stmt, () => (cond, dst))
}

///|
fn label(m : Machine, cond : Value, l : @types.Label) -> Unit raise {
  match l {
    Direct(dst) => {
      will_jump_to_tid(m, cond, dst)
      exec_to_prompt(m, dst)
    }
    Indirect(x) => {
      let dst = Interpreter::exp(m, x)
      Interpreter::tick(m)
      m.post(will_jump_stmt, () => (cond, dst))
      match Linker::resolve_tid(m, Addr(dst.value)) {
        None => exec_tail(m, Addr(dst.value))
        Some(tid) => exec_to_prompt(m, tid)
      }
    }
  }
}

///|
fn resolve_return(m : Machine, c : @types.Call) -> @types.Tid? raise {
  match c.return_label {
    None => None
    Some(Direct(dst)) => Some(dst)
    Some(Indirect(e)) => {
      let dst = Interpreter::exp(m, e)
      Linker::resolve_tid(m, Addr(dst.value))
    }
  }
}

///|
fn push_prompt(m : Machine, dst : @types.Tid?) -> Unit {
  guard dst is Some(p) else { return }
  m.update_local(interpreter_state, s => { ..s, prompts: s.prompts.prepend(p), })
}

///|
fn pop_prompt(m : Machine) -> Unit {
  m.update_local(interpreter_state, s => { ..s, prompts: s.prompts.drop(1), })
}

///|
fn do_call(m : Machine, cond : Value, c : @types.Call) -> Unit raise {
  let callsite = m.get_local(interpreter_state).addr
  let ret = resolve_return(m, c)
  push_prompt(m, ret)
  m.push(CallReturn(cond, ret, callsite))
  label(m, cond, c.target)
}

///|
fn trap_cfi_violation(m : Machine, callsite : @types.Word) -> Unit raise {
  m.make(cfi_will_diverge_stmt, callsite)
  if !call_when_provided(m, cfi_violation_handler) {
    m.raise_exn(CfiViolation(callsite))
  }
}

///|
fn step_call_return(
  m : Machine,
  cond : Value,
  ret : @types.Tid?,
  callsite : @types.Word,
) -> Unit raise {
  guard top_prompt(m) is Some(p) else { return }
  match ret {
    None => ()
    Some(r) if r != p => {
      trap_cfi_violation(m, callsite)
      pop_prompt(m)
      label(m, cond, Direct(r))
    }
    Some(r) => {
      pop_prompt(m)
      label(m, cond, Direct(r))
    }
  }
}

///|
fn jump(m : Machine, cond : Value, t : @types.Term[@types.Jmp]) -> Unit raise {
  match t.kind() {
    Ret(dst) => label(m, cond, dst)
    JmpCall(c) => do_call(m, cond, c)
    Goto(l) => label(m, cond, l)
    Interrupt(n, r) => {
      Interpreter::interrupt(m, n)
      exec_tail(m, Tid(r))
    }
  }
}

///|
/// Evaluates a subroutine and waits for it to return (`Interpreter.sub`).
pub fn Interpreter::sub(
  m : Machine,
  sub : @types.Term[@types.Sub],
) -> Unit raise {
  m.run_nested(() => m.push(SubEnter(sub)))
}

///|
/// Evaluates a block, and the blocks it jumps to, until the control
/// returns (`Interpreter.blk`).
pub fn Interpreter::blk(
  m : Machine,
  blk : @types.Term[@types.Blk],
) -> Unit raise {
  m.run_nested(() => m.push(BlkEnter(blk)))
}

///|
/// Schedules the evaluation of a subroutine as top-level steps of the
/// current machine (see `Machine::schedule`).
pub fn Interpreter::schedule_sub(
  m : Machine,
  sub : @types.Term[@types.Sub],
) -> Unit {
  m.push(SubEnter(sub))
}

///|
/// Schedules the evaluation of a block as top-level steps of the current
/// machine (see `Machine::schedule`).
pub fn Interpreter::schedule_blk(
  m : Machine,
  blk : @types.Term[@types.Blk],
) -> Unit {
  m.push(BlkEnter(blk))
}
