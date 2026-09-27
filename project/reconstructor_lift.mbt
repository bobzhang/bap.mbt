// Lifting disassembled code into IR (upstream `lib/bap_sema/bap_sema_lift.ml`:
// `IrBuilder.blk`, `lift_sub` and `program`): every basic block is lifted
// instruction by instruction into one or more IR blocks with
// `@types.Blk::lift_block`, which keeps the structured control flow of the
// BIL (conditionals, loops), the calls with their returns, the interrupts
// and the fallthroughs given by the CFG.
//
// Two front ends share the per-block lifting: the default reconstructor,
// which groups the disassembled blocks itself, and the symbol-table based
// `lift_ir` functions that mirror upstream `Blk.lift`, `Sub.lift` and
// `Program.lift`.

///|
/// The state of one IR lifting: where the lifted instructions come from,
/// the failures, and the knowledge upstream takes from the knowledge base.
priv struct ProjectIrLifter {
  target : @core_theory.Target
  registry : @mc.Registry
  errors : Array[ProjectLiftError]
  pkg : String?
  /// the width of code addresses
  width : Int
  /// the labels of the known subroutine starts (upstream
  /// `Theory.Label.is_subroutine`)
  subroutines : Map[@types.Tid, Unit]
}

///|
fn ProjectIrLifter::new(
  target : @core_theory.Target,
  registry : @mc.Registry,
  pkg : String?,
  subroutines : Array[UInt64],
) -> ProjectIrLifter {
  let code_width = target.code_addr_size()
  let width = if code_width <= 0 { 32 } else { code_width }
  let lifter : ProjectIrLifter = {
    target,
    registry,
    errors: [],
    pkg,
    width,
    subroutines: Map([]),
  }
  for addr in subroutines {
    match lifter.block_label(addr) {
      Some(label) => lifter.subroutines[label] = ()
      None => ()
    }
  }
  lifter
}

///|
fn ProjectIrLifter::word(self : ProjectIrLifter, addr : UInt64) -> @types.Word? {
  try @types.Word::of_uint64(width=self.width, addr) catch {
    _ => None
  } noraise {
    word => Some(word)
  }
}

///|
/// The label of the block starting at `addr` (upstream
/// `Theory.Label.for_addr`).
fn ProjectIrLifter::block_label(
  self : ProjectIrLifter,
  addr : UInt64,
) -> @types.Tid? {
  self.word(addr).map(word => @types.Tid::for_addr(word, pkg?=self.pkg))
}

///|
/// The `insn` attribute of an instruction, in the upstream `Insn.pp` form
/// `name(op1,op2)`.
fn project_ir_insn_text(insn : ProjectDisassemblyInstruction) -> String {
  let name = insn.name()
  if name == "" {
    name
  } else {
    let ops = insn.operands().map(op => op.to_string())
    "\{name}(\{ops.join(",")})"
  }
}

///|
/// The index of the instruction that terminates a block: the last one, or
/// the delayed branch whose delay slot ends the block.
fn project_ir_terminator(lifted : Array[Result[@mc.Lifted, String]]) -> Int {
  let last = lifted.length() - 1
  for i, item in lifted {
    if item is Ok(value) && value.delay() > 0 && i + value.delay() >= last {
      return i
    }
  }
  last
}

///|
/// The IR blocks of the basic block at `addr` made of `insns` (upstream
/// `IrBuilder.blk`): the block falls to `fall`, and its jumps become calls
/// when its terminator is a call or `explicit_call` holds. When the
/// terminator cannot be lifted and `fallback` is given, the exit block gets
/// the jumps `fallback` instead of the fallthrough (upstream lifts such a
/// block like any other, its terminator having empty semantics).
fn ProjectIrLifter::lift_blk(
  self : ProjectIrLifter,
  addr : UInt64,
  insns : Array[ProjectDisassemblyInstruction],
  fall~ : @types.IrFall?,
  explicit_call~ : Bool,
  fallback? : Array[@types.Term[@types.Jmp]],
) -> Result[Array[@types.Term[@types.Blk]], String] {
  guard self.word(addr) is Some(word) else {
    return Err(
      "disassembly block address is not representable by project target",
    )
  }
  let tid = @types.Tid::for_addr(word, pkg?=self.pkg)
  let lifted = insns.map(insn => {
    insn.lift(target=self.target, registry=self.registry)
  })
  for i, insn in insns {
    if lifted[i] is Err(message) {
      self.errors.push({ addr: insn.addr(), opcode: insn.name(), message, })
    }
  }
  let ir_insns = project_lift_segments(insns, lifted).map(segment => {
    let insn = insns[segment.0]
    @types.IrInsn::new(
      segment.1,
      addr?=self.word(insn.addr()),
      insn=project_ir_insn_text(insn),
    )
  })
  let terminator = project_ir_terminator(lifted)
  let is_subroutine = (label : @types.Tid) => self.subroutines.contains(label)
  let lifted_terminator = terminator >= 0 && lifted[terminator] is Ok(_)
  guard !lifted_terminator && fallback is Some(fallback) else {
    // upstream `Insn.derive_props`: from the semantics of the terminator
    let (is_call, is_barrier) = match insns.get(terminator) {
      Some(insn) => {
        let bil = match lifted[terminator] {
          Ok(value) => Some(value.bil())
          Err(_) => None
        }
        project_insn_derived_props(Some(insn), bil)
      }
      None => (false, false)
    }
    return Ok(
      @types.Blk::lift_block(
        tid,
        ir_insns,
        addr=word,
        fall?,
        is_call=is_call || explicit_call,
        is_barrier~,
        pkg?=self.pkg,
        addr_width=self.width,
        is_subroutine~,
      ),
    )
  }
  let blks = @types.Blk::lift_block(
    tid,
    ir_insns,
    addr=word,
    is_call=false,
    is_barrier=true,
    pkg?=self.pkg,
    addr_width=self.width,
    is_subroutine~,
  )
  let last = blks.length() - 1
  let mut exit = blks[last]
  for jmp in fallback {
    exit = exit.append_jmp(jmp)
  }
  blks[last] = exit
  Ok(blks)
}

///|
/// The indices of `nodes` in reverse postorder of a depth-first traversal
/// from `nodes[0]` along `succs` (upstream
/// `Graphlib.reverse_postorder_traverse`), followed by the unreached
/// indices in order.
fn project_ir_reverse_postorder(succs : Array[Array[Int]]) -> Array[Int] {
  let n = succs.length()
  let visited = Array::make(n, false)
  let postorder : Array[Int] = []
  if n > 0 {
    let stack : Array[(Int, Int)] = [(0, 0)]
    visited[0] = true
    while stack.last() is Some((node, next)) {
      if next < succs[node].length() {
        stack[stack.length() - 1] = (node, next + 1)
        let succ = succs[node][next]
        if !visited[succ] {
          visited[succ] = true
          stack.push((succ, 0))
        }
      } else {
        postorder.push(node)
        ignore(stack.pop())
      }
    }
  }
  let order = postorder.rev()
  for i in 0..<n {
    if !visited[i] {
      order.push(i)
    }
  }
  order
}

// Lifting the subroutines of the default reconstructor.

///|
/// The fallthrough of `block` of the reconstructed `group` (upstream
/// `fall_of_block`): the destination of its fall edge, intraprocedural when
/// the destination is in `group`, into another subroutine otherwise.
fn ProjectIrLifter::group_fall(
  self : ProjectIrLifter,
  project : Project,
  block : @memory.Memory,
  group : Array[@memory.Memory],
) -> @types.IrFall? {
  for edge in project.disassembly().edges_from_block(block) {
    if edge.kind() == FallEdge && edge.target() is Some(target) {
      let (inside, dst_block) = match
        project_reconstructor_find_block_containing(group, target) {
        Some(index) => (true, Some(group[index]))
        None => {
          let blocks = project.disassembly().blocks()
          (
            false,
            project_reconstructor_find_block_containing(blocks, target).map(i => {
              blocks[i]
            }),
          )
        }
      }
      guard dst_block is Some(dst_block) &&
        self.block_label(dst_block.min_addr()) is Some(tid) else {
        continue
      }
      let dst = @types.Jmp::resolved(tid)
      return Some(if inside { IntraFall(dst) } else { InterFall(dst) })
    }
  }
  None
}

///|
/// The jumps along the disassembly edges of `block` to blocks of `group`,
/// the fallthrough last, used for blocks without lifted terminators.
fn project_ir_group_edge_jmps(
  project : Project,
  block : @memory.Memory,
  group : Array[@memory.Memory],
  labels : Array[@types.Tid],
) -> Array[@types.Term[@types.Jmp]] {
  let edges = project.disassembly().edges_from_block(block)
  let ordered = edges.filter(edge => edge.kind() != FallEdge) +
    edges.filter(edge => edge.kind() == FallEdge)
  let result : Array[@types.Term[@types.Jmp]] = []
  for edge in ordered {
    if edge.target() is Some(target) &&
      project_reconstructor_find_block_containing(group, target) is Some(index) {
      result.push(project_reconstructor_edge_jmp(edge, labels[index]))
    }
  }
  result
}

///|
/// The subroutine `name` lifted from the blocks of `group` (upstream
/// `lift_sub`): the blocks are lifted in reverse postorder from the first
/// block along the disassembly edges. Blocks without instructions, or whose
/// terminator cannot be lifted, get jumps along their disassembly edges.
fn ProjectIrLifter::group_subroutine(
  self : ProjectIrLifter,
  project : Project,
  name : String,
  group : Array[@memory.Memory],
) -> Result[@types.Term[@types.Sub], String] {
  let labels : Array[@types.Tid] = []
  for block in group {
    match self.block_label(block.min_addr()) {
      Some(tid) => labels.push(tid)
      None =>
        return Err(
          "disassembly block address is not representable by project target",
        )
    }
  }
  let succs : Array[Array[Int]] = group.map(block => {
    let result : Array[Int] = []
    for edge in project.disassembly().edges_from_block(block) {
      if edge.target() is Some(target) &&
        project_reconstructor_find_block_containing(group, target)
        is Some(index) &&
        !result.contains(index) {
        result.push(index)
      }
    }
    result
  })
  let blks : Array[@types.Term[@types.Blk]] = []
  for index in project_ir_reverse_postorder(succs) {
    let block = group[index]
    match
      self.lift_blk(
        block.min_addr(),
        project.disassembly().instructions_in(block),
        fall=self.group_fall(project, block, group),
        explicit_call=false,
        fallback=project_ir_group_edge_jmps(project, block, group, labels),
      ) {
      Ok(items) => blks.push_iter(items.iter())
      Err(reason) => return Err(reason)
    }
  }
  let mut sub = @types.Sub::create(
    name~,
    blks~,
    tid=@types.Tid::for_name(name, pkg?=self.pkg),
  )
  if !group.is_empty() {
    match self.word(group[0].min_addr()) {
      Some(addr) => sub = sub.set_attr(@types.Attr::address(addr))
      None => ()
    }
  }
  match project.image() {
    Some(image) if group.any(block => block.contains(image.entry_point())) =>
      Ok(sub.with_entry_point())
    _ => Ok(sub)
  }
}

///|
/// The subroutines named `names` lifted from the block `groups` of the
/// default reconstructors, installed into `project` with their jumps
/// relinked at the program level (upstream `alternate_nonlocal` and
/// `link_call`): jumps that may leave their subroutines become calls, and
/// destinations that are entries of subroutines are relinked to the
/// subroutines; every called label that is not a subroutine gets a
/// synthetic subroutine (`insert_synthetic`). The rooter roots are the
/// known subroutine starts.
fn project_reconstructor_lift_groups(
  project : Project,
  names : Array[String],
  groups : Array[Array[@memory.Memory]],
  registry : @mc.Registry,
) -> Result[Project, String] {
  let lifter = ProjectIrLifter::new(
    project.target(),
    registry,
    project.pkg(),
    project.rooter().roots(),
  )
  let subroutines : Array[@types.Term[@types.Sub]] = []
  for i, group in groups {
    match lifter.group_subroutine(project, names[i], group) {
      Ok(sub) => subroutines.push(sub)
      Err(reason) => return Err(reason)
    }
  }
  let entries : Map[@types.Tid, @types.Tid] = Map([])
  for sub in subroutines {
    match sub.blks() {
      [entry, ..] if !entries.contains(entry.tid()) =>
        entries[entry.tid()] = sub.tid()
      _ => ()
    }
  }
  // as upstream `Program.lift`, every called label that is not a
  // subroutine gets a synthetic one (`insert_synthetic`)
  let program = @types.Program::insert_synthetic(
    @types.Program::relink_calls(
      @types.Program::create(subs=subroutines),
      entries,
    ),
  )
  Ok(
    project
    .with_program(program)
    .with_state(project.state().with_subroutines(program.subs()))
    .with_lift_errors(lifter.errors),
  )
}
