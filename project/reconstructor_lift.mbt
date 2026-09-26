// Lifting the reconstructed subroutines into IR (upstream
// `Bap_sema_lift.program`/`lift_sub`/`IrBuilder.blk`): every basic block is
// lifted instruction by instruction into one or more IR blocks with
// `Blk::lift_block`, which keeps the structured control flow of the BIL
// (conditionals, loops), the calls with their returns, the interrupts and
// the fallthroughs given by the disassembly edges.

///|
/// The state of the IR lifting of one reconstruction.
priv struct ProjectIrLifter {
  project : Project
  registry : @mc.Registry
  errors : Array[ProjectLiftError]
  /// the width of code addresses
  width : Int
  /// the labels of the known subroutine starts (upstream
  /// `Theory.Label.is_subroutine`, provided by the rooter)
  subroutines : Map[@types.Tid, Unit]
}

///|
fn ProjectIrLifter::new(
  project : Project,
  registry : @mc.Registry,
  errors : Array[ProjectLiftError],
) -> ProjectIrLifter {
  let code_width = project.target().code_addr_size()
  let width = if code_width <= 0 { 32 } else { code_width }
  let lifter : ProjectIrLifter = {
    project,
    registry,
    errors,
    width,
    subroutines: Map([]),
  }
  for root in project.rooter().roots() {
    match lifter.word(root) {
      Some(word) => lifter.subroutines[lifter.label(word)] = ()
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
fn ProjectIrLifter::label(
  self : ProjectIrLifter,
  word : @types.Word,
) -> @types.Tid {
  @types.Tid::for_addr(word, pkg?=self.project.pkg())
}

///|
/// The label of the block starting at `addr`.
fn ProjectIrLifter::block_label(
  self : ProjectIrLifter,
  addr : UInt64,
) -> @types.Tid? {
  self.word(addr).map(word => self.label(word))
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
/// The fallthrough of `block` (upstream `fall_of_block`): the destination
/// of its fall edge, intraprocedural when the destination is in `group`,
/// into another subroutine otherwise.
fn ProjectIrLifter::fall(
  self : ProjectIrLifter,
  block : @memory.Memory,
  group : Array[@memory.Memory],
) -> @types.IrFall? {
  let blocks = self.project.disassembly().blocks()
  for edge in self.project.disassembly().edges_from_block(block) {
    if edge.kind() == FallEdge && edge.target() is Some(target) {
      let (inside, index) = match
        project_reconstructor_find_block_containing(group, target) {
        Some(index) => (true, Some(index))
        None =>
          (false, project_reconstructor_find_block_containing(blocks, target))
      }
      guard index is Some(index) else { continue }
      let dst_block = if inside { group[index] } else { blocks[index] }
      guard self.block_label(dst_block.min_addr()) is Some(tid) else {
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
fn ProjectIrLifter::edge_jmps(
  self : ProjectIrLifter,
  block : @memory.Memory,
  group : Array[@memory.Memory],
  ir_blocks : Array[@types.Tid],
) -> Array[@types.Term[@types.Jmp]] {
  let edges = self.project.disassembly().edges_from_block(block)
  let ordered = edges.filter(edge => edge.kind() != FallEdge) +
    edges.filter(edge => edge.kind() == FallEdge)
  let result : Array[@types.Term[@types.Jmp]] = []
  for edge in ordered {
    if edge.target() is Some(target) &&
      project_reconstructor_find_block_containing(group, target) is Some(index) {
      result.push(project_reconstructor_edge_jmp(edge, ir_blocks[index]))
    }
  }
  result
}

///|
/// The IR blocks of `block` (upstream `IrBuilder.blk`). A block without
/// instructions, or whose terminator cannot be lifted, gets jumps along its
/// disassembly edges instead of the lifted control flow.
fn ProjectIrLifter::blk(
  self : ProjectIrLifter,
  block : @memory.Memory,
  group : Array[@memory.Memory],
  ir_blocks : Array[@types.Tid],
) -> Result[Array[@types.Term[@types.Blk]], String] {
  guard self.word(block.min_addr()) is Some(addr) else {
    return Err(
      "disassembly block address is not representable by project target",
    )
  }
  let tid = self.label(addr)
  let insns = self.project.disassembly().instructions_in(block)
  let lifted = insns.map(insn => {
    insn.lift(target=self.project.target(), registry=self.registry)
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
  let options_pkg = self.project.pkg()
  let is_subroutine = (label : @types.Tid) => self.subroutines.contains(label)
  if terminator >= 0 && lifted[terminator] is Ok(_) {
    let insn = insns[terminator]
    Ok(
      @types.Blk::lift_block(
        tid,
        ir_insns,
        addr~,
        fall?=self.fall(block, group),
        is_call=insn.is_kind(ProjectCall),
        is_barrier=insn.is_kind(ProjectBarrier),
        pkg?=options_pkg,
        addr_width=self.width,
        is_subroutine~,
      ),
    )
  } else {
    let blks = @types.Blk::lift_block(
      tid,
      ir_insns,
      addr~,
      is_call=false,
      is_barrier=true,
      pkg?=options_pkg,
      addr_width=self.width,
      is_subroutine~,
    )
    let last = blks.length() - 1
    let mut exit = blks[last]
    for jmp in self.edge_jmps(block, group, ir_blocks) {
      exit = exit.append_jmp(jmp)
    }
    blks[last] = exit
    Ok(blks)
  }
}

///|
/// The blocks of `group` in reverse postorder from its first block along
/// the disassembly edges (upstream `lift_sub` traverses the CFG of a
/// subroutine in reverse postorder), followed by the unreached blocks in
/// address order.
fn ProjectIrLifter::order(
  self : ProjectIrLifter,
  group : Array[@memory.Memory],
) -> Array[Int] {
  let n = group.length()
  let succs : Array[Array[Int]] = Array::makei(n, _ => [])
  for i, block in group {
    for edge in self.project.disassembly().edges_from_block(block) {
      if edge.target() is Some(target) &&
        project_reconstructor_find_block_containing(group, target)
        is Some(index) &&
        !succs[i].contains(index) {
        succs[i].push(index)
      }
    }
  }
  let visited = Array::make(n, false)
  let postorder : Array[Int] = []
  // iterative depth-first search
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

///|
/// The subroutine `name` lifted from the blocks of `group` (upstream
/// `lift_sub`), with its address and entry-point attributes.
fn ProjectIrLifter::subroutine(
  self : ProjectIrLifter,
  name : String,
  group : Array[@memory.Memory],
) -> Result[@types.Term[@types.Sub], String] {
  let ir_blocks : Array[@types.Tid] = []
  for block in group {
    match self.block_label(block.min_addr()) {
      Some(tid) => ir_blocks.push(tid)
      None =>
        return Err(
          "disassembly block address is not representable by project target",
        )
    }
  }
  let blks : Array[@types.Term[@types.Blk]] = []
  for index in self.order(group) {
    match self.blk(group[index], group, ir_blocks) {
      Ok(items) => blks.push_iter(items.iter())
      Err(reason) => return Err(reason)
    }
  }
  let project = self.project
  let mut sub = @types.Sub::create(
    name~,
    blks~,
    tid=@types.Tid::for_name(name, pkg?=project.pkg()),
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
fn project_reconstructor_subroutine(
  project : Project,
  name : String,
  blocks : Array[@memory.Memory],
  registry : @mc.Registry,
  errors : Array[ProjectLiftError],
) -> Result[@types.Term[@types.Sub], String] {
  ProjectIrLifter::new(project, registry, errors).subroutine(name, blocks)
}

///|
/// Install the reconstructed subroutines, relinking their jumps at the
/// program level (upstream `alternate_nonlocal` and `link_call`): jumps
/// that may leave their subroutines become calls, and destinations that are
/// entries of subroutines are relinked to the subroutines.
fn project_reconstructor_apply(
  project : Project,
  subroutines : Array[@types.Term[@types.Sub]],
  errors : Array[ProjectLiftError],
) -> Project {
  let entries : Map[@types.Tid, @types.Tid] = Map([])
  for sub in subroutines {
    match sub.blks() {
      [entry, ..] if !entries.contains(entry.tid()) =>
        entries[entry.tid()] = sub.tid()
      _ => ()
    }
  }
  let program = @types.Program::relink_calls(
    @types.Program::create(subs=subroutines),
    entries,
  )
  let subroutines = program.subs()
  project
  .with_program(program)
  .with_state(project.state().with_subroutines(subroutines))
  .with_lift_errors(errors)
}
