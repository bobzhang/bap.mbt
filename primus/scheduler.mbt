///|
/// # Frames and the scheduler
///
/// The control stack of a machine is a persistent stack of frames. The
/// scheduler pops the top frame of the current machine and executes it (a
/// *step*); frames pushed by host code during a step are buffered and put
/// on top of the stack when the step ends (so they run before the frames
/// that the step itself scheduled as its successors). After every
/// top-level step pending fork/switch requests are applied.
///
/// ## Writing host code as frames (the resumable call protocol)
///
/// Host code that must stay forkable in the middle of its execution (for
/// example a Primus Lisp evaluator) is written in continuation-passing
/// style over the frame stack instead of calling the synchronous helpers:
///
/// - `m.schedule(k)` pushes a task: `k` runs as the next step;
/// - `m.call(name, args=[..], then=k)` calls linked code and continues with
///   `k(m, result)` when it returns. The callee is looked up when the call
///   is executed. `Code::Host(f)` callees read `m.call_args()` on entry and
///   return a value with `m.set_result(v)`; they may push further frames
///   (their own continuation), in which case the result is the value of
///   the result register when those frames are done. `Code::Subroutine`
///   callees receive `args` in their input arguments (assigned to the
///   argument expressions) and return the value of their first output
///   argument. `m.call_code(code, ...)` calls anonymous code;
/// - `m.push_handler(h)` installs an exception handler for the frames
///   pushed after it: if a later step raises, the stack is unwound down to
///   the handler, which then runs as a step with the error. The handler
///   frame is popped silently when the protected frames complete;
/// - `m.push_cleanup(f)` pushes a frame that runs `f` both when it is
///   reached normally and when an exception unwinds through it (dynamic
///   scope restoration, `unwind-protect`).
///
/// All these frames live in the persistent control stack, so they survive
/// forks and switches: after a fork both machines return to the same
/// continuations and handlers. The result register and the call arguments
/// are per-fork too.
priv enum Frame {
  /// Host code (scheduled tasks, `then` continuations).
  Task((Machine) -> Unit raise)
  /// A call continuation: receives the result register.
  Cont((Machine, Value?) -> Unit raise)
  /// An exception handler (`Machine::push_handler`).
  Catch((Machine, Error) -> Unit raise)
  /// A cleanup (`Machine::push_cleanup`).
  Cleanup((Machine) -> Unit raise)
  /// The remaining observers of a suspended observation dispatch.
  Dispatch(Array[() -> Unit raise], Int)
  /// Marks the bottom of a nested (synchronous) run.
  Barrier(Int)
  /// Executes a linked name (`Linker::schedule_exec`).
  Exec(Name)
  /// Calls a linked name with arguments (`Machine::call`).
  CallName(Name, Array[Value])
  /// Calls code with arguments (`Machine::call_code`).
  CallCode(Code, Array[Value])
  /// Enters a subroutine term.
  SubEnter(@types.Term[@types.Sub])
  /// Binds the input arguments of a subroutine and schedules its entry
  /// block.
  SubStart(@types.Term[@types.Sub], Pos, Ctx)
  /// Returns from a subroutine: binds output arguments, restores the
  /// caller context and leaves the subroutine.
  SubLeave(@types.Term[@types.Sub], Pos, Array[Value], Ctx)
  /// Enters a block term.
  BlkEnter(@types.Term[@types.Blk])
  /// Enters the i-th phi node or definition of a block (phis first).
  BlkElt(@types.Term[@types.Blk], Pos, Int)
  /// Evaluates and leaves the i-th phi node or definition of a block.
  BlkEltBody(@types.Term[@types.Blk], Pos, Int, Pos)
  /// Enters the i-th jump of a block with the accumulated constraint.
  BlkJmp(@types.Term[@types.Blk], Pos, Int, Constr)
  /// Evaluates the condition of the i-th jump and leaves it.
  BlkJmpBody(@types.Term[@types.Blk], Pos, Int, Constr, Pos)
  /// Performs the jump taken by a block.
  Jump(Value, @types.Term[@types.Jmp])
  /// Continues after a call returns: pops the call prompt and jumps to
  /// the return destination.
  CallReturn(Value, @types.Tid?, @types.Word)
}

///|
priv enum Stack {
  Nil
  Cons(Frame, Stack)
}

///|
fn Machine::push(self : Machine, frame : Frame) -> Unit {
  self.current.stack = Cons(frame, self.current.stack)
}

///|
/// Pushes a frame on behalf of host code: during a step the frame is
/// buffered and pushed when the step ends, otherwise it is pushed now.
fn Machine::push_user(self : Machine, frame : Frame) -> Unit {
  if self.depth == 0 {
    self.push(frame)
  } else {
    self.deferred.push(frame)
  }
}

///|
/// Schedules a host task on the current machine: it runs as a separate
/// step right after the current step (tasks follow the stack discipline:
/// the last scheduled task runs first).
pub fn Machine::schedule(
  self : Machine,
  task : (Machine) -> Unit raise,
) -> Unit {
  self.push_user(Task(task))
}

///|
/// Calls the code linked under `name` with the arguments and continues
/// with `then(m, result)` when it returns (see the resumable call
/// protocol above). The call is performed by the scheduler as the next
/// step, so the caller should return right after scheduling it.
pub fn Machine::call(
  self : Machine,
  name : Name,
  args? : Array[Value] = [],
  then~ : (Machine, Value?) -> Unit raise,
) -> Unit {
  self.push_user(Cont(then))
  self.push_user(CallName(name, args))
}

///|
/// Like `Machine::call`, for code that is not linked.
pub fn Machine::call_code(
  self : Machine,
  code : Code,
  args? : Array[Value] = [],
  then~ : (Machine, Value?) -> Unit raise,
) -> Unit {
  self.push_user(Cont(then))
  self.push_user(CallCode(code, args))
}

///|
/// The arguments of the innermost call (valid when a callee starts).
pub fn Machine::call_args(self : Machine) -> Array[Value] {
  self.current.call_args
}

///|
/// Sets the result register of the current machine (the value returned by
/// a callee to its `then` continuation).
pub fn Machine::set_result(self : Machine, v : Value?) -> Unit {
  self.current.result = v
}

///|
/// The result register of the current machine.
pub fn Machine::result(self : Machine) -> Value? {
  self.current.result
}

///|
/// Installs an exception handler for the frames pushed after it (see the
/// frame protocol above).
pub fn Machine::push_handler(
  self : Machine,
  handler : (Machine, Error) -> Unit raise,
) -> Unit {
  self.push_user(Catch(handler))
}

///|
/// Pushes a cleanup frame that runs when it is reached or when an
/// exception unwinds through it.
pub fn Machine::push_cleanup(
  self : Machine,
  cleanup : (Machine) -> Unit raise,
) -> Unit {
  self.push_user(Cleanup(cleanup))
}

///|
/// The number of frames on the control stack of the current machine.
pub fn Machine::stack_depth(self : Machine) -> Int {
  let mut n = 0
  for s = self.current.stack {
    match s {
      Nil => break
      Cons(_, rest) => {
        n += 1
        continue rest
      }
    }
  }
  n
}

///|
fn Machine::exec_frame(self : Machine, frame : Frame) -> Unit raise {
  match frame {
    Task(f) => f(self)
    Cont(k) => k(self, self.current.result)
    Catch(_) | Barrier(_) => ()
    Cleanup(f) => f(self)
    Dispatch(items, from) => self.dispatch(items, from)
    Exec(name) => {
      self.current.result = None
      self.current.call_args = []
      exec_tail(self, name)
    }
    CallName(name, args) => call_name(self, name, args)
    CallCode(code, args) => call_code_now(self, None, code, args)
    SubEnter(sub) => step_sub_enter(self, sub)
    SubStart(sub, pos, ctx) => step_sub_start(self, sub, pos, ctx)
    SubLeave(sub, pos, inputs, ctx) =>
      step_sub_leave(self, sub, pos, inputs, ctx)
    BlkEnter(blk) => step_blk_enter(self, blk)
    BlkElt(blk, pos, i) => step_blk_elt(self, blk, pos, i)
    BlkEltBody(blk, pos, i, elt) => step_blk_elt_body(self, blk, pos, i, elt)
    BlkJmp(blk, pos, i, constr) => step_blk_jmp(self, blk, pos, i, constr)
    BlkJmpBody(blk, pos, i, constr, jpos) =>
      step_blk_jmp_body(self, blk, pos, i, constr, jpos)
    Jump(cond, t) => jump(self, cond, t)
    CallReturn(cond, ret, callsite) =>
      step_call_return(self, cond, ret, callsite)
  }
}

///|
/// Executes one frame as a step. Frames pushed by host code during the
/// step are put on the stack when it succeeds; if it raises, they and the
/// fork/switch requests issued during the step are discarded and the error
/// is returned.
fn Machine::run_step(self : Machine, frame : Frame) -> Error? {
  let dmark = self.deferred.length()
  let pmark = self.pending.length()
  self.depth += 1
  let err = try self.exec_frame(frame) catch {
    e => Some(e)
  } noraise {
    _ => None
  }
  self.depth -= 1
  match err {
    None => {
      let frames = self.deferred[dmark:].to_owned()
      self.deferred.truncate(dmark)
      for f in frames {
        self.push(f)
      }
      None
    }
    Some(e) => {
      self.deferred.truncate(dmark)
      self.pending.truncate(pmark)
      Some(e)
    }
  }
}

///|
/// Unwinds the control stack of the current machine after an exception,
/// down to the nearest handler frame (or to the barrier `floor`). Cleanup
/// frames met on the way are run. Returns `None` if a handler was found (it
/// is scheduled as the next step), otherwise the error to propagate.
fn Machine::recover(self : Machine, e : Error, floor : Int?) -> Error? {
  let mut err = e
  for ;; {
    match self.current.stack {
      Nil => return Some(err)
      Cons(Barrier(k), _) if floor is Some(f) && f == k => return Some(err)
      Cons(Catch(h), rest) => {
        self.current.stack = rest
        let failure = err
        self.push(Task(m => h(m, failure)))
        return None
      }
      Cons(Cleanup(f), rest) => {
        self.current.stack = rest
        if self.run_step(Task(f)) is Some(e2) {
          err = e2
        }
      }
      Cons(_, rest) => self.current.stack = rest
    }
  }
}

///|
/// Runs the top-level scheduler loop: executes steps of the current
/// machine until its control stack is empty and returns how it finished.
/// Pending fork/switch requests are applied after each step. An exception
/// (from a step or from applying a request) unwinds the stack of the
/// current machine to the nearest handler; without a handler the stack is
/// discarded (the continuation is aborted, as upstream) and the exception
/// becomes the exit status.
fn Machine::drive(self : Machine) -> ExitStatus {
  while self.current.stack is Cons(frame, rest) {
    self.current.stack = rest
    let err = match self.run_step(frame) {
      Some(e) => Some(e)
      None =>
        try self.apply_pending() catch {
          e => {
            self.pending.clear()
            Some(e)
          }
        } noraise {
          _ => None
        }
    }
    if err is Some(e) {
      match self.recover(e, None) {
        None => ()
        Some(e) => {
          self.current.stack = Nil
          return Exn(e)
        }
      }
    }
  }
  Normal
}

///|
fn Machine::unwind_barrier(self : Machine, marker : Int) -> Unit {
  for ;; {
    match self.current.stack {
      Cons(Barrier(k), rest) if k == marker => {
        self.current.stack = rest
        break
      }
      Cons(_, rest) => self.current.stack = rest
      Nil => break
    }
  }
}

///|
fn Machine::nested_loop(self : Machine, push : () -> Unit raise) -> Unit raise {
  self.last_barrier += 1
  let marker = self.last_barrier
  self.push(Barrier(marker))
  let ctx = save_ctx(self)
  self.nested += 1
  defer {
    self.nested -= 1
    restore_ctx(self, ctx)
  }
  {
    errdefer self.unwind_barrier(marker)
    push()
  }
  for ;; {
    match self.current.stack {
      Cons(Barrier(k), rest) if k == marker => {
        self.current.stack = rest
        break
      }
      Cons(frame, rest) => {
        self.current.stack = rest
        if self.run_step(frame) is Some(e) {
          match self.recover(e, Some(marker)) {
            None => ()
            Some(e) => {
              self.unwind_barrier(marker)
              raise e
            }
          }
        }
      }
      Nil => break
    }
  }
}

///|
/// Runs the frames pushed by `push` until they are consumed (a nested,
/// synchronous run) and restores the interpreter position afterwards. Used
/// by synchronous APIs like `Linker::exec`. Fork and switch requests are
/// deferred until the enclosing top-level step ends (or applied at the end
/// if no step is running).
fn Machine::run_nested(self : Machine, push : () -> Unit raise) -> Unit raise {
  self.nested_loop(push)
  if self.depth == 0 && self.nested == 0 {
    self.apply_pending()
  }
}

///|
/// Runs host code as a step (used for `boot`, `init` and `fini`).
fn Machine::host_step(self : Machine, f : (Machine) -> Unit raise) -> Error? {
  match self.run_step(Task(f)) {
    Some(e) => Some(e)
    None =>
      try self.apply_pending() catch {
        e => {
          self.pending.clear()
          Some(e)
        }
      } noraise {
        _ => None
      }
  }
}

///|
/// Runs a machine (upstream `Machine.run`).
///
/// - `boot` is run in the restricted mode (observations are dropped);
/// - `init` is run after the restriction is lifted;
/// - `start` is scheduled as the first task of the global machine, after
///   `system_start` is posted with `system`;
/// - the scheduler runs the current machine to completion; when it
///   finishes (normally or with an exception) `fini` is run; if `fini` (for
///   example a scheduler component observing `system_fini`) switched to
///   another live machine with a non-empty control stack, the scheduler
///   continues with that machine, otherwise `system_stop` is posted in the
///   restricted mode and the result is returned.
///
/// Returns the exit status of the last finished machine and the (possibly
/// updated) project.
pub fn Machine::run(
  proj : @project.Project,
  start? : (Machine) -> Unit raise = _ => (),
  boot? : (Machine) -> Unit raise = _ => (),
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  system? : String = "primus",
  args? : Array[String] = [],
  envp? : Array[String] = [],
) -> (ExitStatus, @project.Project) {
  let m = Machine::new(proj, args~, envp~)
  m.run_with(start~, boot~, init~, fini~, system~)
}

///|
/// Runs an already created machine (see `Machine::run`).
pub fn Machine::run_with(
  self : Machine,
  start? : (Machine) -> Unit raise = _ => (),
  boot? : (Machine) -> Unit raise = _ => (),
  init? : (Machine) -> Unit raise = _ => (),
  fini? : (Machine) -> Unit raise = _ => (),
  system? : String = "primus",
) -> (ExitStatus, @project.Project) {
  let m = self
  m.restricted = true
  if m.host_step(boot) is Some(e) {
    return (Exn(e), m.proj)
  }
  m.restricted = false
  if m.host_step(init) is Some(e) {
    return (Exn(e), m.proj)
  }
  m.push(
    Task(m => {
      m.make(started_stmt, system)
      start(m)
    }),
  )
  for ;; {
    let status = m.drive()
    let final_status = match m.host_step(fini) {
      Some(e) => Exn(e)
      None => status
    }
    if m.current.stack is Cons(_, _) {
      continue
    }
    m.restricted = true
    m.make_even_if_restricted(stopped_stmt, system) catch {
      e => return (Exn(e), m.proj)
    }
    return (final_status, m.proj)
  }
}
