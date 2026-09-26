// The symbol-table based lifting of disassembled code into IR, mirroring
// upstream `Bap_sema_lift.blk`, `Bap_sema_lift.sub` and
// `Bap_sema_lift.program` (`Blk.lift`, `Sub.lift` and `Program.lift`).

///|
/// The known subroutine starts of `symtab`.
fn project_sema_entries(symtab : ProjectDisassemblySymtab?) -> Array[UInt64] {
  match symtab {
    Some(symtab) => symtab.to_sequence().map(function => function.addr())
    None => []
  }
}

///|
/// Upstream `tid_for_name_or_addr`: the label of the entry of the function
/// `name` of `symtab`, or the label of the name.
fn ProjectIrLifter::name_or_addr(
  self : ProjectIrLifter,
  symtab : ProjectDisassemblySymtab,
  name : String,
) -> @types.Tid {
  match
    symtab
    .find_by_name(name)
    .bind(function => self.block_label(function.addr())) {
    Some(tid) => tid
    None => @types.Tid::for_name(name, pkg?=self.pkg)
  }
}

///|
/// Upstream `fall_of_block`: the destination of the fall edge of `block` in
/// `cfg` (restricted to the blocks `within`, when given), or else the
/// implicit callee of `block` in `symtab`.
fn ProjectIrLifter::cfg_fall(
  self : ProjectIrLifter,
  cfg : ProjectDisassemblyCfg,
  symtab : ProjectDisassemblySymtab?,
  within : Array[ProjectDisassemblyBlock]?,
  block : ProjectDisassemblyBlock,
) -> @types.IrFall? {
  for edge in cfg.outputs(block) {
    let dst = edge.dst()
    let inside = match within {
      Some(blocks) => blocks.any(item => item.same(dst))
      None => true
    }
    if edge.kind() == FallEdge && inside {
      match self.block_label(dst.addr()) {
        Some(tid) => return Some(IntraFall(@types.Jmp::resolved(tid)))
        None => ()
      }
    }
  }
  match symtab {
    Some(symtab) =>
      symtab
      .implicit_callee(block.addr())
      .map(name => {
        InterFall(@types.Jmp::resolved(self.name_or_addr(symtab, name)))
      })
    None => None
  }
}

///|
fn ProjectIrLifter::cfg_blk(
  self : ProjectIrLifter,
  cfg : ProjectDisassemblyCfg,
  symtab : ProjectDisassemblySymtab?,
  within : Array[ProjectDisassemblyBlock]?,
  block : ProjectDisassemblyBlock,
) -> Result[Array[@types.Term[@types.Blk]], String] {
  let explicit_call = match symtab {
    Some(symtab) => symtab.explicit_callee(block.addr()) is Some(_)
    None => false
  }
  self.lift_blk(
    block.addr(),
    block.instructions(),
    fall=self.cfg_fall(cfg, symtab, within, block),
    explicit_call~,
  )
}

///|
/// Upstream `lift_sub`: the blocks of `function` lifted in reverse
/// postorder from its entry along the edges of `cfg` between its blocks.
fn ProjectIrLifter::cfg_sub_blks(
  self : ProjectIrLifter,
  cfg : ProjectDisassemblyCfg,
  symtab : ProjectDisassemblySymtab?,
  function : ProjectDisassemblyFunction,
) -> Result[Array[@types.Term[@types.Blk]], String] {
  let entry = function.entry()
  let blocks = [entry]
  for block in function.blocks() {
    if !blocks.any(item => item.same(block)) {
      blocks.push(block)
    }
  }
  let succs = blocks.map(block => {
    let result : Array[Int] = []
    for edge in cfg.outputs(block) {
      match blocks.search_by(item => item.same(edge.dst())) {
        Some(index) if !result.contains(index) => result.push(index)
        _ => ()
      }
    }
    result
  })
  let blks : Array[@types.Term[@types.Blk]] = []
  for index in project_ir_reverse_postorder(succs) {
    match self.cfg_blk(cfg, symtab, Some(blocks), blocks[index]) {
      Ok(items) => blks.push_iter(items.iter())
      Err(reason) => return Err(reason)
    }
  }
  Ok(blks)
}

///|
/// The IR of the basic block (upstream `Blk.lift`/`Sema.blk cfg block`):
/// its instructions lifted on `target` through `registry` into one or more
/// blocks, the first labeled by the block address. The block falls to the
/// destination of its fall edge in `cfg`, or else into the implicit callee
/// of the block in `symtab`; its jumps become calls when its terminator is
/// a call or it has an explicit callee in `symtab`, and jumps to the
/// functions of `symtab` are calls. Returns the blocks and the instructions
/// that could not be lifted (which contribute no semantics).
pub fn ProjectDisassemblyBlock::lift_ir(
  self : ProjectDisassemblyBlock,
  target~ : @core_theory.Target,
  cfg? : ProjectDisassemblyCfg = ProjectDisassemblyCfg::empty(),
  symtab? : ProjectDisassemblySymtab,
  registry? : @mc.Registry = project_lift_registry(),
  pkg? : String,
) -> Result[(Array[@types.Term[@types.Blk]], Array[ProjectLiftError]), String] {
  let lifter = ProjectIrLifter::new(
    target,
    registry,
    pkg,
    project_sema_entries(symtab),
  )
  match lifter.cfg_blk(cfg, symtab, None, self) {
    Ok(blks) => Ok((blks, lifter.errors))
    Err(reason) => Err(reason)
  }
}

///|
/// The subroutine of the function (upstream `Sub.lift`/`Sema.sub`): its
/// blocks lifted like `ProjectDisassemblyBlock::lift_ir` in reverse
/// postorder from the entry along the edges of `cfg` between them, named
/// after the function and with the address of its entry.
pub fn ProjectDisassemblyFunction::lift_ir(
  self : ProjectDisassemblyFunction,
  target~ : @core_theory.Target,
  cfg~ : ProjectDisassemblyCfg,
  symtab? : ProjectDisassemblySymtab,
  registry? : @mc.Registry = project_lift_registry(),
  pkg? : String,
) -> Result[(@types.Term[@types.Sub], Array[ProjectLiftError]), String] {
  let lifter = ProjectIrLifter::new(
    target,
    registry,
    pkg,
    project_sema_entries(symtab),
  )
  match lifter.cfg_sub_blks(cfg, symtab, self) {
    Ok(blks) => {
      let mut sub = @types.Sub::create(
        name=self.name(),
        blks~,
        tid=@types.Tid::for_name(self.name(), pkg?),
      )
      match lifter.word(self.addr()) {
        Some(addr) => sub = sub.set_attr(@types.Attr::address(addr))
        None => ()
      }
      Ok((sub, lifter.errors))
    }
    Err(reason) => Err(reason)
  }
}

///|
/// The program of the symbol table (upstream `Program.lift`/`Sema.program`):
/// a subroutine for each function (see `ProjectDisassemblyFunction::lift_ir`,
/// with the functions of the table as the known subroutines), the jumps of
/// which are then relinked (`Program::relink_calls`): jumps that may leave
/// their subroutines become calls, destinations that are function entries
/// are linked to their subroutines, and calls of blocks with explicit
/// callees are linked to the callees. Every called label that is not a
/// subroutine gets a synthetic one (`Program::insert_synthetic`). Functions
/// with a name already taken get a fresh tid and the name `name@addr`
/// (upstream `fix_names`).
pub fn ProjectDisassemblySymtab::lift_ir(
  self : ProjectDisassemblySymtab,
  target~ : @core_theory.Target,
  cfg~ : ProjectDisassemblyCfg,
  registry? : @mc.Registry = project_lift_registry(),
  pkg? : String,
) -> Result[(@types.Term[@types.Program], Array[ProjectLiftError]), String] {
  let lifter = ProjectIrLifter::new(
    target,
    registry,
    pkg,
    project_sema_entries(Some(self)),
  )
  let subs : Array[@types.Term[@types.Sub]] = []
  let entries : Map[@types.Tid, @types.Tid] = Map([])
  let callees : Map[@types.Tid, @types.Tid] = Map([])
  let taken : Map[@types.Tid, Unit] = Map([])
  for function in self.to_sequence() {
    guard lifter.block_label(function.addr()) is Some(entry) else {
      return Err("function entry is not representable by project target")
    }
    let blks = match lifter.cfg_sub_blks(cfg, Some(self), function) {
      Ok(blks) => blks
      Err(reason) => return Err(reason)
    }
    for block in function.blocks() {
      match
        (lifter.block_label(block.addr()), self.explicit_callee(block.addr())) {
        (Some(tid), Some(name)) =>
          callees[tid] = @types.Tid::for_name(name, pkg?)
        _ => ()
      }
    }
    let named = @types.Tid::for_name(function.name(), pkg?)
    let (tid, name) = if taken.contains(named) {
      let addr = "0x" + function.addr().to_string(radix=16)
      (@types.Tid::fresh(), "\{function.name()}@\{addr}")
    } else {
      (named, function.name())
    }
    taken[tid] = ()
    let mut sub = @types.Sub::create(name~, blks~, tid~)
    match lifter.word(function.addr()) {
      Some(addr) => sub = sub.set_attr(@types.Attr::address(addr))
      None => ()
    }
    subs.push(sub)
    if !entries.contains(entry) {
      entries[entry] = tid
    }
  }
  let program = @types.Program::relink_calls(
    @types.Program::create(subs~),
    entries,
    external_callee=blk => callees.get(blk.tid()),
  )
  Ok((@types.Program::insert_synthetic(program), lifter.errors))
}

///|
/// The program of the project lifted from its symbol table and CFG (see
/// `ProjectDisassemblySymtab::lift_ir`).
pub fn Project::lift_ir(
  self : Project,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[(@types.Term[@types.Program], Array[ProjectLiftError]), String] {
  self
  .disassembly_symtab()
  .lift_ir(
    target=self.target(),
    cfg=self.disassembly_cfg(),
    registry~,
    pkg?=self.pkg(),
  )
}
