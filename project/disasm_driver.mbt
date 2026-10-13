// The incremental disassembler (upstream `lib/bap_disasm/bap_disasm_driver.ml`,
// `Disasm.Driver`).
//
// The disassembler scans memory regions one at a time and merges the
// results into its state: the subroutine starts, the basic block starts,
// the jumps and their destinations, the addresses proven to be data, the
// scanned regions, the work that could not be finished because it lies
// outside of the scanned regions (the debt, finished by the scans of later
// regions) and the external destinations.
//
// A scan is driven by the knowledge base: the classification of the
// addresses of the region (`Theory.Label.is_valid`, `is_subroutine`), the
// encodings (`Theory.Label.encoding`) and the destinations of the decoded
// instructions (`project_insn_dests_slot`, upstream `Insn.Slot.dests`) are
// collected from it, so rooters, branchers and lifters contribute by
// promising these properties.
//
// The scan is the upstream machine of tasks: the destinations of jumps
// (`Dest`), the fallthroughs (`Fall`) and the jumps themselves (`Jump`,
// possibly delayed). When an instruction fails to decode, the chain of
// tasks that led to it is reverted and the addresses are marked as data.
//
// Deviation: the upstream knowledge monad is replaced with direct-style
// functions taking the knowledge base (`@knowledge.State`), and the
// callback-driven Basic disassembler is driven by a loop.

///|
/// The encoding of an instruction: the language and the target.
priv struct DriverEncoding {
  coding : @core_theory.Language
  target : @core_theory.Target
}

///|
fn DriverEncoding::unknown() -> DriverEncoding {
  {
    coding: @core_theory.Language::unknown(),
    target: @core_theory.Target::unknown(),
  }
}

///|
fn DriverEncoding::is_known(self : DriverEncoding) -> Bool {
  !self.coding.is_unknown()
}

///|
fn DriverEncoding::same(self : DriverEncoding, other : DriverEncoding) -> Bool {
  self.coding == other.coding && self.target.equal(other.target)
}

///|
/// A jump of the disassembled program (upstream `Driver.jump`): whether it
/// is a call, a barrier (control does not fall through), or indirect, and
/// its resolved destinations and unresolved (external) destinations.
struct ProjectDisassemblyDriverJump {
  encoding : DriverEncoding
  call : Bool
  barrier : Bool
  indirect : Bool
  resolved : @sorted_set.SortedSet[UInt64]
  unresolved : @sorted_set.SortedSet[@knowledge.Object[Unit]]
}

///|
fn ProjectDisassemblyDriverJump::same(
  self : ProjectDisassemblyDriverJump,
  other : ProjectDisassemblyDriverJump,
) -> Bool {
  self.encoding.same(other.encoding) &&
  self.call == other.call &&
  self.barrier == other.barrier &&
  self.indirect == other.indirect &&
  self.resolved == other.resolved &&
  self.unresolved == other.unresolved
}

///|
/// `Driver.destinations`: the resolved destinations of the jump.
pub fn ProjectDisassemblyDriverJump::destinations(
  self : ProjectDisassemblyDriverJump,
) -> Array[UInt64] {
  self.resolved.to_array()
}

///|
/// The unresolved destinations of the jump (the labels without addresses,
/// e.g., external functions; the null label stands for an unknown
/// destination).
pub fn ProjectDisassemblyDriverJump::unresolved(
  self : ProjectDisassemblyDriverJump,
) -> Array[@knowledge.Object[Unit]] {
  self.unresolved.to_array()
}

///|
/// `Driver.is_call`.
pub fn ProjectDisassemblyDriverJump::is_call(
  self : ProjectDisassemblyDriverJump,
) -> Bool {
  self.call
}

///|
/// `Driver.is_barrier`: control does not fall through the jump.
pub fn ProjectDisassemblyDriverJump::is_barrier(
  self : ProjectDisassemblyDriverJump,
) -> Bool {
  self.barrier
}

///|
/// Whether the jump has unresolved destinations.
pub fn ProjectDisassemblyDriverJump::is_indirect(
  self : ProjectDisassemblyDriverJump,
) -> Bool {
  self.indirect
}

// The machine.

///|
/// A task of the disassembler machine (upstream `Machine.task`):
///
/// - `TaskDest(dst, parent)`: `dst` is a destination of the jump `parent`,
///   or a root (function start) when `parent` is `None`;
/// - `TaskFall(dst, parent)`: the fallthrough from `parent`;
/// - `TaskJump(src, dsts)`: a jump from `src` to `dsts`, possibly delayed
///   and waiting until its `age` is 0.
priv enum DriverTask {
  TaskDest(dst~ : UInt64, parent~ : DriverTask?, encoding~ : DriverEncoding)
  TaskFall(
    dst~ : UInt64,
    parent~ : DriverTask,
    delay~ : DriverDelaySlot,
    encoding~ : DriverEncoding
  )
  TaskJump(
    src~ : UInt64,
    age~ : Int32,
    dsts~ : ProjectDisassemblyDriverJump,
    parent~ : DriverTask,
    encoding~ : DriverEncoding
  )
}

///|
/// The delay-slot status of a fallthrough (upstream `Machine.slot`).
priv enum DriverDelaySlot {
  DelayReady(DriverTask?)
  DelayWait
}

///|
fn DriverTask::encoding(self : DriverTask) -> DriverEncoding {
  match self {
    TaskDest(encoding~, ..)
    | TaskFall(encoding~, ..)
    | TaskJump(encoding~, ..) => encoding
  }
}

///|
fn DriverTask::with_encoding(
  self : DriverTask,
  encoding : DriverEncoding,
) -> DriverTask {
  match self {
    TaskFall(dst~, parent~, delay~, ..) =>
      TaskFall(dst~, parent~, delay~, encoding~)
    TaskDest(dst~, parent~, ..) => TaskDest(dst~, parent~, encoding~)
    TaskJump(..) => self
  }
}

///|
/// The state of the disassembler machine (upstream `Machine.state`).
priv struct DriverMachine {
  /// true if finished
  stop : Bool
  /// the work list
  work : @list.List[DriverTask]
  /// the work that can't be finished
  debt : @list.List[DriverTask]
  /// the current task
  curr : DriverTask
  /// the current address
  addr : UInt64
  /// the delay slots
  dels : @sorted_set.SortedSet[UInt64]
  /// the beginnings of basic blocks and the tasks that lead to them
  begs : @sorted_map.SortedMap[UInt64, @list.List[DriverTask]]
  /// the jumps
  jmps : @sorted_map.SortedMap[UInt64, ProjectDisassemblyDriverJump]
  /// all valid instructions
  code : @sorted_map.SortedMap[UInt64, @core_theory.Language]
  /// all non-instructions
  data : @sorted_set.SortedSet[UInt64]
  /// unsatisfied constraints (addresses known to be code)
  usat : @sorted_set.SortedSet[UInt64]
}

///|
fn DriverMachine::is_code(self : DriverMachine, addr : UInt64) -> Bool {
  self.code.contains(addr)
}

///|
fn DriverMachine::is_data(self : DriverMachine, addr : UInt64) -> Bool {
  self.data.contains(addr)
}

///|
fn DriverMachine::is_visited(self : DriverMachine, addr : UInt64) -> Bool {
  self.is_code(addr) || self.is_data(addr)
}

///|
fn DriverMachine::is_slot(self : DriverMachine, addr : UInt64) -> Bool {
  self.dels.contains(addr)
}

///|
fn DriverMachine::wrong_encoding(
  self : DriverMachine,
  addr : UInt64,
  encoding : DriverEncoding,
) -> Bool {
  match self.code.get(addr) {
    None => false
    Some(other) =>
      @core_theory.Language::domain().join(other, encoding.coding) is Err(_)
  }
}

///|
fn DriverMachine::has_valid(
  self : DriverMachine,
  dsts : ProjectDisassemblyDriverJump,
) -> Bool {
  dsts.indirect || dsts.resolved.any(dst => !self.data.contains(dst))
}

///|
fn[T] driver_add_multi(
  map : @sorted_map.SortedMap[UInt64, @list.List[T]],
  key : UInt64,
  value : T,
) -> @sorted_map.SortedMap[UInt64, @list.List[T]] {
  let tasks = match map.get(key) {
    Some(tasks) => tasks
    None => @list.List([])
  }
  map.add(key, tasks.prepend(value))
}

///|
/// `revert t s`: reverts the chain that produced the task `t`.
fn DriverMachine::revert(
  self : DriverMachine,
  task : DriverTask,
) -> DriverMachine {
  let parent = match task {
    TaskDest(parent=None, ..) => return self
    TaskDest(parent=Some(parent), ..) => parent
    TaskFall(parent~, ..) | TaskJump(parent~, ..) => parent
  }
  match parent {
    TaskFall(..) | TaskDest(..) => self.cancel(parent)
    TaskJump(..) =>
      match task {
        TaskFall(delay=DelayReady(Some(_)) | DelayWait, ..) =>
          self.cancel(parent)
        _ => self
      }
  }
}

///|
/// `cancel t s`: marks the address of `t` as data and reverts `t`.
fn DriverMachine::cancel(
  self : DriverMachine,
  task : DriverTask,
) -> DriverMachine {
  let s = match task {
    TaskDest(dst~, ..) | TaskFall(dst~, ..) => self.delete(dst)
    TaskJump(dsts~, ..) if self.has_valid(dsts) => self
    TaskJump(src~, ..) => self.delete(src)
  }
  s.revert(task)
}

///|
/// `revert_incoming s addr`: reverts the tasks that lead to `addr`.
fn DriverMachine::revert_incoming(
  self : DriverMachine,
  addr : UInt64,
) -> DriverMachine {
  match self.begs.get(addr) {
    None => self
    Some(tasks) => {
      let init = { ..self, begs: self.begs.remove(addr), }
      tasks.rev().fold(init~, (s, task) => s.revert(task))
    }
  }
}

///|
/// `delete s addr`: marks `addr` as data.
fn DriverMachine::delete(self : DriverMachine, addr : UInt64) -> DriverMachine {
  let s = self.revert_incoming(addr)
  {
    ..s,
    data: s.data.add(addr),
    begs: s.begs.remove(addr),
    usat: s.usat.remove(addr),
    code: s.code.remove(addr),
    jmps: s.jmps.remove(addr),
  }
}

///|
/// `Machine.step`: processes the work list until the next address to
/// decode, or until the work is done.
fn DriverMachine::step(self : DriverMachine) -> DriverMachine {
  for s = self {
    match s.work {
      Empty =>
        if s.usat.is_empty() {
          break { ..s, stop: true, code: @sorted_map.new(), }
        } else {
          // restart from the first unsatisfied address
          continue {
              ..s,
              work: @list.singleton(
                TaskDest(
                  dst=s.usat.min(),
                  parent=None,
                  encoding=DriverEncoding::unknown(),
                ),
              ),
            }
        }
      More(TaskDest(dst=next, encoding~, ..) as curr, tail=work) =>
        if s.wrong_encoding(next, encoding) ||
          s.is_data(next) ||
          s.is_slot(next) {
          continue { ..s, work, }.revert(curr)
        } else {
          let s = { ..s, begs: driver_add_multi(s.begs, next, curr), }
          if s.is_visited(next) {
            continue { ..s, work, }
          } else {
            break { ..s, work, addr: next, curr, }
          }
        }
      More(TaskFall(dst=next, encoding~, ..) as curr, tail=work) =>
        if s.is_code(next) {
          if s.is_slot(next) || s.wrong_encoding(next, encoding) {
            continue { ..s, work, }.revert(curr)
          } else {
            continue { ..s, begs: driver_add_multi(s.begs, next, curr), work, }
          }
        } else if s.is_data(next) {
          continue { ..s, work, }.revert(curr)
        } else {
          break { ..s, work, addr: next, curr, }
        }
      More(TaskJump(src~, dsts~, age~, ..) as jump, tail=work) if work.is_empty() ||
        age == 0 =>
        if s.data.contains(src) {
          continue { ..s, work, }.revert(jump)
        } else {
          let resolved = dsts.resolved.difference(s.data)
          if resolved.is_empty() && !dsts.indirect {
            continue { ..s, work, }.revert(jump)
          } else {
            let dsts = { ..dsts, resolved, }
            let init = { ..s, jmps: s.jmps.add(src, dsts), work, }
            continue resolved.fold(init~, (s, next) => {
                ..s,
                work: s.work.prepend(
                  TaskDest(dst=next, parent=Some(jump), encoding=dsts.encoding),
                ),
              })
          }
        }
      More(
        TaskJump(age~, dsts~, parent~, encoding~, ..) as self_,
        tail=More(
          TaskFall(dst=next, parent=slot_parent, encoding=slot_encoding, ..),
          tail=work
        )
      ) => {
        let s = s.revert_incoming(next)
        let delay = if age == 1 { DelayReady(Some(self_)) } else { DelayWait }
        let jump = TaskJump(src=next, age=age - 1, dsts~, parent~, encoding~)
        continue {
            ..s,
            work: work
            .prepend(jump)
            .prepend(
              TaskFall(
                dst=next,
                parent=slot_parent,
                delay~,
                encoding=slot_encoding,
              ),
            ),
            dels: s.dels.add(next),
          }
      }
      More(TaskJump(src~, dsts~, parent~, encoding~, ..), tail=work) =>
        continue {
            ..s,
            work: work.prepend(TaskJump(src~, age=0, dsts~, parent~, encoding~)),
          }
    }
  }
}

///|
fn DriverMachine::decoded(
  self : DriverMachine,
  mem : @memory.Memory,
  encoding : DriverEncoding,
) -> DriverMachine {
  let addr = mem.min_addr()
  {
    ..self,
    code: self.code.add(addr, encoding.coding),
    usat: self.usat.remove(addr),
  }
}

///|
/// `Machine.jumped`: the instruction at `mem` is a jump to `dsts`.
fn DriverMachine::jumped(
  self : DriverMachine,
  encoding : DriverEncoding,
  mem : @memory.Memory,
  dsts : ProjectDisassemblyDriverJump,
  delay : Int32,
) -> DriverMachine {
  let s = self.decoded(mem, encoding)
  let parent = s.curr
  let src = mem.min_addr()
  let jump = TaskJump(src~, age=delay, dsts~, parent~, encoding~)
  let dst = mem.max_addr() + 1UL
  let next = if dsts.barrier && delay == 0 {
    TaskDest(dst~, parent=None, encoding=DriverEncoding::unknown())
  } else {
    TaskFall(dst~, parent=jump, delay=DelayReady(None), encoding~)
  }
  { ..s, work: s.work.prepend(next).prepend(jump), }.step()
}

///|
/// `Machine.moved`: the instruction at `mem` passes control to the next
/// one.
fn DriverMachine::moved(
  self : DriverMachine,
  encoding : DriverEncoding,
  mem : @memory.Memory,
) -> DriverMachine {
  let parent = match self.curr {
    TaskFall(delay=DelayReady(Some(parent)), ..) => parent
    curr => curr
  }
  let dst = mem.max_addr() + 1UL
  let next = match parent {
    TaskJump(dsts~, ..) if dsts.barrier =>
      TaskDest(dst~, parent=None, encoding=DriverEncoding::unknown())
    parent => TaskFall(dst~, parent~, delay=DelayReady(None), encoding~)
  }
  let work = match self.curr {
    TaskFall(delay=DelayWait, ..) =>
      match self.work {
        More(x, tail=xs) => xs.prepend(next).prepend(x)
        Empty => @list.singleton(next)
      }
    _ => self.work.prepend(next)
  }
  { ..self, work, }.decoded(mem, encoding).step()
}

///|
/// `Machine.failed`: the current task failed to decode.
fn DriverMachine::failed(self : DriverMachine) -> DriverMachine {
  self.cancel(self.curr).step()
}

///|
/// `Machine.skipped`: the address has an unknown encoding.
fn DriverMachine::skipped(self : DriverMachine, addr : UInt64) -> DriverMachine {
  { ..self, usat: self.usat.remove(addr), }.step()
}

///|
/// `Machine.stopped`: the memory ended in the middle of an instruction.
fn DriverMachine::stopped(self : DriverMachine) -> DriverMachine {
  self.cancel(self.curr).step()
}

///|
fn DriverMachine::switch(
  self : DriverMachine,
  encoding : DriverEncoding,
) -> DriverMachine {
  { ..self, curr: self.curr.with_encoding(encoding), }
}

///|
/// The outcome of `Machine.view`.
priv enum DriverView {
  /// the machine is finished
  ViewEmpty(DriverMachine)
  /// the machine is ready to decode the memory with the encoding
  ViewReady(DriverMachine, DriverEncoding, @memory.Memory)
}

///|
/// `Machine.view s base`: the memory at the current address of `s`;
/// the tasks outside of `base` are either reverted or, for destinations,
/// kept as debt.
fn DriverMachine::view(
  self : DriverMachine,
  base : @memory.Memory,
) -> DriverView {
  for s = self {
    if s.stop {
      break ViewEmpty(s)
    }
    match base.view(from=s.addr) {
      Ok(mem) if base.contains(s.addr) =>
        break ViewReady(s, s.curr.encoding(), mem)
      _ => {
        let s = match s.curr {
          TaskFall(..) | TaskJump(..) as task => s.revert(task)
          task => { ..s, debt: s.debt.prepend(task), }
        }
        match s.work {
          Empty => break ViewEmpty(s.step())
          _ => continue s.step()
        }
      }
    }
  }
}

///|
/// `Machine.start mem ~debt ~code ~data ~init`.
fn driver_machine_start(
  mem : @memory.Memory,
  debt~ : @list.List[DriverTask],
  code~ : @sorted_set.SortedSet[UInt64],
  data~ : @sorted_set.SortedSet[UInt64],
  init~ : @sorted_set.SortedSet[UInt64],
) -> DriverView {
  let init = if init.is_empty() {
    @sorted_set.singleton(mem.min_addr())
  } else {
    init
  }
  let work = init
    .rev_iter()
    .fold(init=debt, (work, root) => {
      work.prepend(
        TaskDest(dst=root, parent=None, encoding=DriverEncoding::unknown()),
      )
    })
  let start = init.min()
  let machine : DriverMachine = {
    work,
    data,
    usat: code,
    addr: start,
    debt: @list.List([]),
    curr: TaskDest(dst=start, parent=None, encoding=DriverEncoding::unknown()),
    stop: false,
    dels: @sorted_set.new(),
    begs: @sorted_map.new(),
    jmps: @sorted_map.new(),
    code: @sorted_map.new(),
  }
  machine.view(mem)
}

// Knowledge.

///|
/// `new_insn mem insn`: the label of the instruction decoded from `mem`,
/// with its memory, instruction (carrying the relocations of its unit) and
/// unit.
fn driver_new_insn(
  kb : @knowledge.State,
  mem : @memory.Memory,
  insn : ProjectDisassemblyInstruction,
  unit : @core_theory.ProgramUnit?,
) -> @knowledge.Object[Unit] raise {
  let label = project_label_for_addr(kb, mem.min_addr())
  let insn = project_insn_with_unit_relocations(kb, insn, unit)
  kb.provide(project_label_unit, label, unit)
  kb.provide(project_insn_memory_slot, label, Some(mem))
  kb.provide(project_insn_slot, label, Some(insn))
  label
}

///|
/// `get_encoding label`.
fn driver_get_encoding(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> DriverEncoding raise {
  let target = project_label_target(kb, label)
  let coding = kb.collect(project_label_encoding, label)
  { coding, target, }
}

///|
/// A label of the program class that lives while `f` evaluates, with its
/// address (and unit) provided (upstream `KB.Object.scoped
/// Theory.Program.cls`).
fn[R] driver_scoped(
  kb : @knowledge.State,
  addr : UInt64,
  unit~ : @core_theory.ProgramUnit? = None,
  f : (@knowledge.Object[Unit]) -> R raise,
) -> R raise {
  kb.scoped(project_label_cls, label => {
    kb.provide(project_label_addr, label, Some(project_label_word(addr)))
    kb.provide(project_label_unit, label, unit)
    f(label)
  })
}

///|
/// `unit_for_mem mem`: the unit of the memory, as known to the knowledge
/// base.
fn driver_unit_for_mem(
  kb : @knowledge.State,
  mem : @memory.Memory,
) -> @core_theory.ProgramUnit? raise {
  driver_scoped(kb, mem.min_addr(), label => {
    kb.collect(project_label_unit, label)
  })
}

///|
/// `collect_dests source code`: the jump made by the instruction of
/// `label`, decoded with the `source` encoding.
fn driver_collect_dests(
  kb : @knowledge.State,
  source : DriverEncoding,
  label : @knowledge.Object[Unit],
) -> ProjectDisassemblyDriverJump raise {
  let (call, barrier) = driver_insn_props(kb, label)
  let init : ProjectDisassemblyDriverJump = {
    encoding: { ..source, coding: @core_theory.Language::unknown(), },
    call,
    barrier,
    indirect: false,
    resolved: @sorted_set.new(),
    unresolved: @sorted_set.new(),
  }
  match kb.collect(project_insn_dests_slot, label) {
    None => { ..init, encoding: source, }
    Some(dests) => {
      let mut dest = init
      for dst in dests {
        let encoding = driver_get_encoding(kb, dst)
        let coding = match
          @core_theory.Language::domain().join(
            dest.encoding.coding,
            encoding.coding,
          ) {
          Ok(coding) => coding
          Err(mismatch) => raise @knowledge.JoinConflict(mismatch)
        }
        let encoding = { ..dest.encoding, coding, }
        let is_call = kb.collect(project_label_is_subroutine, dst)
        dest = match project_label_addr_of(kb, dst) {
          Some(addr) =>
            {
              ..dest,
              encoding,
              call: dest.call || is_call == Some(true),
              resolved: dest.resolved.add(addr),
            }
          None =>
            {
              ..dest,
              indirect: true,
              unresolved: dest.unresolved.add(dst),
              encoding,
            }
        }
      }
      if dest.encoding.is_known() {
        dest
      } else {
        { ..dest, encoding: source, }
      }
    }
  }
}

///|
/// The jumps of lifted code (upstream `Insn.Analyzer`): whether it jumps,
/// whether a jump is under a condition (in a branch or a loop), and whether
/// it calls (a `call` special).
priv struct DriverBilJumps {
  mut jump : Bool
  mut cond : Bool
  mut call : Bool
  /// whether it calls unconditionally
  mut top_call : Bool
}

///|
fn DriverBilJumps::visit(
  self : DriverBilJumps,
  bil : Array[@types.Stmt],
  under_condition : Bool,
) -> Unit {
  for stmt in bil {
    match stmt {
      Jmp(_) => {
        self.jump = true
        if under_condition {
          self.cond = true
        }
      }
      If(yes~, no~, ..) => {
        self.visit(yes, true)
        self.visit(no, true)
      }
      While(body~, ..) => self.visit(body, true)
      Special(_) =>
        if @types.Stmt::decode(@types.Stmt::call(), stmt) is Some(_) {
          self.call = true
          if !under_condition {
            self.top_call = true
          }
        }
      _ => ()
    }
  }
}

///|
/// The `call` and `barrier` properties of an instruction (upstream
/// `Insn.derive_props`): derived from its lifted semantics `bil` when it has
/// some, from the instruction kinds otherwise. An instruction is a barrier
/// (control does not fall through it) when it jumps, is not a call and its
/// jump is not conditional; e.g., a predicated ARM return is not a barrier,
/// even though LLVM marks the instruction as one.
fn project_insn_derived_props(
  insn : ProjectDisassemblyInstruction?,
  bil : Array[@types.Stmt]?,
) -> (Bool, Bool) {
  let insn_is = (kind : ProjectInstructionKind) => {
    match insn {
      Some(insn) => insn.has_kind(kind)
      None => false
    }
  }
  match bil {
    Some(bil) if !bil.is_empty() => {
      let jumps : DriverBilJumps = {
        jump: false,
        cond: false,
        call: false,
        top_call: false,
      }
      jumps.visit(bil, false)
      let call = jumps.call || insn_is(ProjectCall)
      // a branch (that is not a call instruction) that the relocation
      // fixups made an unconditional call of an external symbol (e.g., the
      // jump of a stub through its slot, or the tail call `jmp printf` of
      // an object) is still a barrier
      let tail_call = jumps.top_call &&
        !jumps.jump &&
        !insn_is(ProjectCall) &&
        (
          insn_is(ProjectUnconditionalBranch) ||
          insn_is(ProjectIndirectBranch) ||
          insn_is(ProjectConditionalBranch) ||
          insn_is(ProjectBarrier)
        )
      (call, (jumps.jump && !call && !jumps.cond) || tail_call)
    }
    // no (or empty) semantics, e.g., an instruction the lifters do not
    // know: from the kinds; a return or a barrier (e.g., the arm64e
    // `retab`) does not fall through, which would otherwise make the
    // driver decode past the end of the function, and revert the whole
    // chain of blocks that led to it when that fails
    _ => {
      let call = insn_is(ProjectCall)
      let cond = insn_is(ProjectConditionalBranch)
      let jump = cond ||
        insn_is(ProjectUnconditionalBranch) ||
        insn_is(ProjectIndirectBranch) ||
        insn_is(ProjectReturn) ||
        insn_is(ProjectBarrier)
      (call, jump && !call && !cond)
    }
  }
}

///|
/// The `call` and `barrier` properties of the instruction of `label` (see
/// `project_insn_derived_props`).
fn driver_insn_props(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> (Bool, Bool) raise {
  let insn = kb.collect(project_insn_slot, label)
  let bil = kb.collect(project_insn_lifted_slot, label).map(l => l.bil())
  project_insn_derived_props(insn, bil)
}

///|
/// `delay code`: the length of the delay slot of the instruction.
fn driver_delay(
  kb : @knowledge.State,
  label : @knowledge.Object[Unit],
) -> Int32 raise {
  match kb.collect(project_insn_delay_slot, label) {
    Some(delay) => delay
    None => 0
  }
}

///|
/// `classify mem`: the addresses of `mem` known to be code, data, and
/// subroutine starts.
fn driver_classify(
  kb : @knowledge.State,
  mem : @memory.Memory,
) -> (
  @sorted_set.SortedSet[UInt64],
  @sorted_set.SortedSet[UInt64],
  @sorted_set.SortedSet[UInt64],
) raise {
  let unit = driver_unit_for_mem(kb, mem)
  let mut code = @sorted_set.new()
  let mut data = @sorted_set.new()
  let mut root = @sorted_set.new()
  let base = mem.min_addr()
  for off in 0..<mem.length() {
    let addr = base + off.to_uint64()
    driver_scoped(kb, addr, unit~, label => {
      match kb.collect(project_label_is_valid, label) {
        Some(false) => data = data.add(addr)
        valid => {
          if valid is Some(_) {
            code = code.add(addr)
          }
          if kb.collect(project_label_is_subroutine, label) is Some(true) {
            root = root.add(addr)
          }
        }
      }
    })
  }
  (code, data, root)
}

///|
/// `create_disassembler encoding`.
fn driver_create_disassembler(
  encoding : DriverEncoding,
) -> Result[ProjectDisassemblyBasic, String] {
  ProjectDisassemblyBasic::lookup(encoding.target, encoding.coding)
}

///|
/// Decodes the first instruction of `mem` with `dis` (upstream: a `run`
/// stopping on the first valid instruction).
fn driver_decode(
  dis : ProjectDisassemblyBasic,
  mem : @memory.Memory,
) -> ProjectDisassemblyBasicDecoded {
  match dis.project_disassembly_basic_decode(mem) {
    Ok(decoded) => decoded
    Err(_) => BasicDecodedEnd
  }
}

///|
/// `disassemble ~code ~data ~funs debt base`: runs the machine over `base`.
fn driver_disassemble(
  kb : @knowledge.State,
  code~ : @sorted_set.SortedSet[UInt64],
  data~ : @sorted_set.SortedSet[UInt64],
  funs~ : @sorted_set.SortedSet[UInt64],
  debt : @list.List[DriverTask],
  base : @memory.Memory,
) -> DriverMachine raise {
  let unit = driver_unit_for_mem(kb, base)
  let mut dis : ProjectDisassemblyBasic? = None
  for view = driver_machine_start(base, debt~, code~, data~, init=funs) {
    match view {
      ViewEmpty(s) => break s
      ViewReady(s, current, mem) => {
        // next_encoding
        let addr = mem.min_addr()
        let encoding = driver_scoped(kb, addr, unit~, label => {
          driver_get_encoding(kb, label)
        })
        let encoding = match (encoding.is_known(), current.is_known()) {
          (false, false) => continue s.skipped(addr).view(base)
          (true, false) => encoding
          (false, true) => current
          (true, true) =>
            if current.same(encoding) {
              current
            } else {
              continue s.failed().view(base)
            }
        }
        let decoder = match dis {
          None =>
            match driver_create_disassembler(encoding) {
              // no disassembler for the first instruction: give up
              Err(_) => break s
              Ok(d) => d
            }
          Some(d) =>
            match driver_create_disassembler(encoding) {
              Ok(d) => d
              Err(_) => d
            }
        }
        dis = Some(decoder)
        let s = s.switch(encoding)
        let next = match driver_decode(decoder, mem) {
          BasicDecodedValid(chunk, insn) => {
            let hit = kb.transaction(() => {
              let label = driver_new_insn(kb, chunk, insn, unit)
              kb.provide(project_label_encoding, label, encoding.coding)
              let dests = driver_collect_dests(kb, encoding, label)
              // a barrier without known destinations (an instruction
              // without semantics, e.g., the arm64e `retab`) jumps to an
              // unknown destination, as a return does
              let dests = if dests.barrier &&
                dests.resolved.is_empty() &&
                !dests.indirect {
                { ..dests, indirect: true, }
              } else {
                dests
              }
              if dests.resolved.is_empty() && !dests.indirect {
                None
              } else {
                Some((dests, driver_delay(kb, label)))
              }
            })
            match hit {
              Ok(None) => s.moved(encoding, chunk)
              Ok(Some((dests, delay))) =>
                s.jumped(encoding, chunk, dests, delay)
              Err(_) => s.failed()
            }
          }
          BasicDecodedInvalid(_) => s.failed()
          BasicDecodedEnd => s.stopped()
        }
        if next.stop {
          break next
        }
        continue next.view(base)
      }
    }
  }
}

// The driver state.

///|
/// The state of the incremental disassembler (upstream `Driver.state`):
/// the subroutine starts, the basic block starts, the jumps, the data, the
/// scanned memory regions, the unfinished work and the external
/// destinations.
struct ProjectDisassemblyDriverState {
  funs : @sorted_set.SortedSet[UInt64]
  begs : @sorted_set.SortedSet[UInt64]
  jmps : @sorted_map.SortedMap[UInt64, ProjectDisassemblyDriverJump]
  data : @sorted_set.SortedSet[UInt64]
  mems : @list.List[@memory.Memory]
  debt : @list.List[DriverTask]
  exts : @sorted_set.SortedSet[@knowledge.Object[Unit]]
}

///|
/// `Driver.init`: nothing is disassembled.
pub fn ProjectDisassemblyDriverState::init() -> ProjectDisassemblyDriverState {
  {
    funs: @sorted_set.new(),
    begs: @sorted_set.new(),
    jmps: @sorted_map.new(),
    data: @sorted_set.new(),
    mems: @list.List([]),
    debt: @list.List([]),
    exts: @sorted_set.new(),
  }
}

///|
/// `Driver.equal`: the states have the same blocks and jumps.
pub fn ProjectDisassemblyDriverState::equal(
  self : ProjectDisassemblyDriverState,
  other : ProjectDisassemblyDriverState,
) -> Bool {
  physical_equal(self, other) ||
  (
    self.begs == other.begs &&
    self.jmps.length() == other.jmps.length() &&
    self.jmps
    .iter()
    .all(entry => {
      match other.jmps.get(entry.0) {
        Some(jump) => jump.same(entry.1)
        None => false
      }
    })
  )
}

///|
/// `Driver.forget_debt`: drops the unfinished work.
pub fn ProjectDisassemblyDriverState::forget_debt(
  self : ProjectDisassemblyDriverState,
) -> ProjectDisassemblyDriverState {
  { ..self, debt: @list.List([]), }
}

///|
/// `Driver.subroutines`: the subroutine starts, in increasing order.
pub fn ProjectDisassemblyDriverState::subroutines(
  self : ProjectDisassemblyDriverState,
) -> Array[UInt64] {
  self.funs.to_array()
}

///|
/// `Driver.externals`: the external destinations of calls (labels without
/// addresses).
pub fn ProjectDisassemblyDriverState::externals(
  self : ProjectDisassemblyDriverState,
) -> Array[@knowledge.Object[Unit]] {
  self.exts.to_array()
}

///|
/// `Driver.blocks`: the basic block starts, in increasing order.
pub fn ProjectDisassemblyDriverState::blocks(
  self : ProjectDisassemblyDriverState,
) -> Array[UInt64] {
  self.begs.to_array()
}

///|
/// `Driver.jump s addr`: the jump made by the instruction at `addr`.
pub fn ProjectDisassemblyDriverState::jump(
  self : ProjectDisassemblyDriverState,
  addr : UInt64,
) -> ProjectDisassemblyDriverJump? {
  self.jmps.get(addr)
}

///|
/// `Driver.is_data`.
pub fn ProjectDisassemblyDriverState::is_data(
  self : ProjectDisassemblyDriverState,
  addr : UInt64,
) -> Bool {
  self.data.contains(addr)
}

///|
/// `Driver.is_subroutine`.
pub fn ProjectDisassemblyDriverState::is_subroutine(
  self : ProjectDisassemblyDriverState,
  addr : UInt64,
) -> Bool {
  self.funs.contains(addr)
}

///|
/// `Driver.is_jump`.
pub fn ProjectDisassemblyDriverState::is_jump(
  self : ProjectDisassemblyDriverState,
  addr : UInt64,
) -> Bool {
  self.jmps.contains(addr)
}

///|
/// `Driver.is_block`.
pub fn ProjectDisassemblyDriverState::is_block(
  self : ProjectDisassemblyDriverState,
  addr : UInt64,
) -> Bool {
  self.begs.contains(addr)
}

///|
/// The number of the unfinished tasks (the destinations outside of the
/// scanned regions).
pub fn ProjectDisassemblyDriverState::debt_count(
  self : ProjectDisassemblyDriverState,
) -> Int32 {
  self.debt.length()
}

///|
/// The scanned memory regions, the most recent first.
pub fn ProjectDisassemblyDriverState::memory(
  self : ProjectDisassemblyDriverState,
) -> Array[@memory.Memory] {
  self.mems.to_array()
}

///|
fn driver_merge_dests(
  d1 : ProjectDisassemblyDriverJump,
  d2 : ProjectDisassemblyDriverJump,
) -> ProjectDisassemblyDriverJump {
  {
    encoding: d1.encoding,
    call: d1.call || d2.call,
    barrier: d1.barrier || d2.barrier,
    indirect: d1.indirect || d2.indirect,
    resolved: d1.resolved.union(d2.resolved),
    unresolved: d1.unresolved.union(d2.unresolved),
  }
}

///|
fn driver_valid_dsts(
  data : @sorted_set.SortedSet[UInt64],
  dsts : ProjectDisassemblyDriverJump,
) -> ProjectDisassemblyDriverJump? {
  let resolved = dsts.resolved.difference(data)
  if resolved.is_empty() && !dsts.indirect {
    None
  } else {
    Some({ ..dsts, resolved, })
  }
}

///|
/// `commit_calls`: the resolved destinations of the calls are valid
/// subroutine starts.
fn driver_commit_calls(
  kb : @knowledge.State,
  jmps : @sorted_map.SortedMap[UInt64, ProjectDisassemblyDriverJump],
) -> @sorted_set.SortedSet[UInt64] raise {
  let mut calls = @sorted_set.new()
  for entry in jmps.iter() {
    let dsts = entry.1
    if dsts.call {
      for addr in dsts.resolved {
        let dst = project_label_for_addr(kb, addr)
        kb.provide(project_label_is_valid, dst, Some(true))
        kb.provide(project_label_is_subroutine, dst, Some(true))
        calls = calls.add(addr)
      }
    }
  }
  calls
}

///|
/// `commit_externals`: the unresolved (non-null) destinations of the calls.
fn driver_commit_externals(
  jmps : @sorted_map.SortedMap[UInt64, ProjectDisassemblyDriverJump],
) -> @sorted_set.SortedSet[@knowledge.Object[Unit]] {
  let mut exts = @sorted_set.new()
  for entry in jmps.iter() {
    let dsts = entry.1
    if dsts.call {
      for dst in dsts.unresolved {
        if !dst.is_null() {
          exts = exts.add(dst)
        }
      }
    }
  }
  exts
}

///|
/// `owns mem s`: some unfinished destination lies in `mem`.
fn ProjectDisassemblyDriverState::owns(
  self : ProjectDisassemblyDriverState,
  mem : @memory.Memory,
) -> Bool {
  self.debt.any(task => task is TaskDest(dst~, ..) && mem.contains(dst))
}

///|
fn ProjectDisassemblyDriverState::scan_step(
  self : ProjectDisassemblyDriverState,
  kb : @knowledge.State,
  mem : @memory.Memory,
  code~ : @sorted_set.SortedSet[UInt64] = @sorted_set.new(),
  data~ : @sorted_set.SortedSet[UInt64] = @sorted_set.new(),
  funs~ : @sorted_set.SortedSet[UInt64] = @sorted_set.new(),
) -> ProjectDisassemblyDriverState raise {
  let m = driver_disassemble(kb, code~, data~, funs~, self.debt, mem)
  let data = self.data.union(m.data)
  let mut jmps = @sorted_map.new()
  for entry in m.jmps.iter() {
    match driver_valid_dsts(data, entry.1) {
      Some(dsts) => jmps = jmps.add(entry.0, dsts)
      None => ()
    }
  }
  let exts = driver_commit_externals(jmps)
  let funs_ = driver_commit_calls(kb, jmps)
  let mut merged = @sorted_map.new()
  for entry in self.jmps.iter() {
    let dsts = match jmps.get(entry.0) {
      None => driver_valid_dsts(data, entry.1)
      Some(d2) => driver_valid_dsts(data, driver_merge_dests(entry.1, d2))
    }
    match dsts {
      Some(dsts) => merged = merged.add(entry.0, dsts)
      None => ()
    }
  }
  for entry in jmps.iter() {
    if !self.jmps.contains(entry.0) {
      merged = merged.add(entry.0, entry.1)
    }
  }
  let begs = @sorted_set.from_iter(m.begs.keys_as_iter()).difference(data)
  let funs = self.funs
    .union(funs)
    .union(funs_)
    .difference(data)
    .difference(m.dels)
  let begs = self.begs.union(begs).difference(m.dels)
  {
    funs,
    begs,
    data,
    jmps: merged,
    mems: self.mems,
    debt: m.debt,
    exts: self.exts.union(exts),
  }
}

///|
/// `Driver.scan mem s`: disassembles the memory region `mem` (unless it is
/// already scanned) and merges the result into the state; the previously
/// scanned regions that own some unfinished work are then scanned again.
pub fn ProjectDisassemblyDriverState::scan(
  self : ProjectDisassemblyDriverState,
  mem : @memory.Memory,
  kb : @knowledge.State,
) -> ProjectDisassemblyDriverState raise {
  project_disasm_knowledge_init()
  let start = mem.min_addr()
  if mem.length() == 0 || self.mems.any(scanned => scanned.contains(start)) {
    return self
  }
  let (code, data, funs) = driver_classify(kb, mem)
  let s = self.scan_step(kb, mem, code~, data~, funs~)
  let mut result = { ..s, mems: s.mems.prepend(mem), }
  for scanned in s.mems {
    if result.owns(scanned) {
      result = result.scan_step(kb, scanned)
    }
  }
  result
}

///|
/// `Driver.merge`: the union of two states.
pub fn ProjectDisassemblyDriverState::merge(
  self : ProjectDisassemblyDriverState,
  other : ProjectDisassemblyDriverState,
) -> ProjectDisassemblyDriverState {
  let mut jmps = self.jmps
  for entry in other.jmps.iter() {
    let dsts = match jmps.get(entry.0) {
      Some(d1) => driver_merge_dests(d1, entry.1)
      None => entry.1
    }
    jmps = jmps.add(entry.0, dsts)
  }
  {
    funs: self.funs.union(other.funs),
    exts: self.exts.union(other.exts),
    begs: self.begs.union(other.begs),
    data: self.data.union(other.data),
    mems: other.mems.rev_concat(self.mems),
    debt: other.debt.rev_concat(self.debt),
    jmps,
  }
}

// Exploration.

///|
/// The instructions of a basic block (upstream `Driver.insns`): their
/// labels, the last instruction first.
struct ProjectDisassemblyDriverInsns {
  stack : @list.List[@knowledge.Object[Unit]]
}

///|
/// `Driver.list_insns ?rev insns`: the labels of the instructions in the
/// order of their addresses (the reverse order with `rev`).
pub fn ProjectDisassemblyDriverInsns::list(
  self : ProjectDisassemblyDriverInsns,
  rev~ : Bool = false,
) -> Array[@knowledge.Object[Unit]] {
  if rev {
    self.stack.to_array()
  } else {
    self.stack.rev().to_array()
  }
}

///|
/// `Driver.execution_order insns`: the labels of the instructions in the
/// order of their execution (an instruction with a delay slot of `d`
/// instructions executes after them).
pub fn ProjectDisassemblyDriverInsns::execution_order(
  self : ProjectDisassemblyDriverInsns,
  kb : @knowledge.State,
) -> Array[@knowledge.Object[Unit]] raise {
  let mut insns : Array[@knowledge.Object[Unit]] = []
  for insn in self.stack {
    match kb.collect(project_insn_delay_slot, insn) {
      None => insns = [insn] + insns
      Some(d) => {
        let pos = if d < insns.length() { d } else { insns.length() }
        insns = insns[:pos].to_owned() + [insn] + insns[pos:].to_owned()
      }
    }
  }
  insns
}

///|
/// `Driver.explore ?entries ?entry ?follow ~block ~node ~edge ~init s`:
/// folds over the control flow graph of the disassembled program: every
/// basic block reachable from the entries (by default, from all block
/// starts) is decoded and passed to `block` together with its
/// instructions, the resulting node to `node`, and every edge between two
/// nodes (along jumps, including calls, and fallthroughs) to `edge`.
/// Blocks for which `follow` does not hold are not explored.
pub fn[N, C] ProjectDisassemblyDriverState::explore(
  self : ProjectDisassemblyDriverState,
  kb : @knowledge.State,
  entries? : Array[UInt64],
  entry? : UInt64,
  follow~ : (UInt64) -> Bool raise = _ => true,
  block~ : (@memory.Memory, ProjectDisassemblyDriverInsns) -> N raise,
  node~ : (N, C) -> C raise,
  edge~ : (N, N, C) -> C raise,
  init~ : C,
) -> C raise {
  project_disasm_knowledge_init()
  let blocks : Map[UInt64, N] = Map([])
  let find_base = (addr : UInt64) => {
    if self.data.contains(addr) {
      None
    } else {
      self.mems.find(mem => mem.contains(addr))
    }
  }
  let entries = match (entry, entries) {
    (None, None) => self.begs.to_array()
    (Some(beg), None) => [beg]
    (None, Some(begs)) => begs
    (Some(beg), Some(begs)) => [beg] + begs
  }
  let mut cfg = init
  fn build(beg : UInt64) -> N? raise {
    if self.data.contains(beg) || !follow(beg) {
      return None
    }
    let label = project_label_for_addr(kb, beg)
    let encoding = driver_get_encoding(kb, label)
    guard driver_create_disassembler(encoding) is Ok(dis) else { None }
    match blocks.get(beg) {
      Some(block) => return Some(block)
      None => ()
    }
    guard find_base(beg) is Some(base) else { None }
    let unit = kb.collect(project_label_unit, label)
    // decode the instructions of the block
    let mut curr = beg
    let mut len = 0
    let mut insns : @list.List[@knowledge.Object[Unit]] = @list.List([])
    let mut pos = beg
    while base.contains(pos) {
      guard base.view(from=pos) is Ok(mem) else { break }
      match driver_decode(dis, mem) {
        BasicDecodedEnd => break
        BasicDecodedInvalid(chunk) => pos = chunk.max_addr() + 1UL
        BasicDecodedValid(chunk, insn) => {
          insns = insns.prepend(driver_new_insn(kb, chunk, insn, unit))
          len += chunk.length()
          let next = chunk.max_addr() + 1UL
          if self.begs.contains(next) ||
            self.jmps.contains(curr) ||
            self.data.contains(next) {
            break
          }
          curr = next
          pos = next
        }
      }
    }
    guard len > 0 && base.view(from=beg, words=len) is Ok(mem) else { None }
    let n = block(mem, { stack: insns, })
    let fall = mem.max_addr() + 1UL
    blocks[beg] = n
    cfg = node(n, cfg)
    let dsts = match self.jmps.get(curr) {
      None => [fall]
      Some(jump) =>
        if jump.barrier {
          jump.resolved.to_array()
        } else {
          jump.resolved.add(fall).to_array()
        }
    }
    for dst in dsts {
      match build(dst) {
        Some(dst) => cfg = edge(n, dst, cfg)
        None => ()
      }
    }
    Some(n)
  }

  for beg in entries {
    build(beg) |> ignore
  }
  cfg
}
