// The symbol table of the incremental disassembler (upstream
// `Bap_disasm_symtab.create disasm calls`).

///|
/// `Symtab.create disasm calls`: the functions of the program disassembled
/// by `driver`, partitioned by `calls`. The blocks reachable from the
/// subroutine starts are explored; a block goes to the function of its
/// entry (`ProjectDisassemblyCalls::entry`); an edge between blocks of
/// different functions is a call of the destination, implicit when it is
/// the fallthrough. The functions and the callees are named after the
/// program labels (`ProjectSymbolizer::get_name`), and the externals of
/// `driver` are the external functions.
pub fn ProjectDisassemblySymtab::create_from_driver(
  driver : ProjectDisassemblyDriverState,
  calls : ProjectDisassemblyCalls,
  kb : @knowledge.State,
) -> ProjectDisassemblySymtab raise {
  // entry -> (the entry block, the blocks)
  let graphs : Map[
    UInt64,
    (ProjectDisassemblyBlock?, Array[ProjectDisassemblyBlock]),
  ] = Map([])
  let mut tab = ProjectDisassemblySymtab::empty()
  driver.explore(
    kb,
    entries=driver.subroutines(),
    init=(),
    block=(mem, insns) => {
      let instructions : Array[ProjectDisassemblyInstruction] = []
      for label in insns.execution_order(kb) {
        match kb.collect(project_insn_slot, label) {
          Some(insn) => instructions.push(insn)
          None => ()
        }
      }
      match ProjectDisassemblyBlock::create(mem, instructions) {
        Ok(block) => block
        Err(reason) => raise @knowledge.Failure(reason)
      }
    },
    node=(node, _) => {
      let addr = node.addr()
      let entry = calls.entry(addr)
      let start = if addr == entry { Some(node) } else { None }
      match graphs.get(entry) {
        None => graphs[entry] = (start, [node])
        Some((first, blocks)) => {
          if !blocks.any(block => block.same(node)) {
            blocks.push(node)
          }
          graphs[entry] = (
            match first {
              Some(_) => first
              None => start
            },
            blocks,
          )
        }
      }
    },
    edge=(src, dst, _) => {
      let next = src.memory().max_addr() + 1UL
      if !calls.siblings(src.addr(), dst.addr()) {
        let name = ProjectSymbolizer::get_name(kb, dst.addr())
        tab = tab.insert_call(src, name, implicit=next == dst.addr())
      }
    },
  )
  let externals : Array[String] = []
  for label in driver.externals() {
    match kb.collect(project_label_name, label) {
      Some(name) if !externals.contains(name) => externals.push(name)
      _ => ()
    }
  }
  tab = { ..tab, externals_value: externals, }
  for entry in graphs.keys().collect() {
    guard graphs.get(entry) is Some((Some(first), blocks)) else { continue }
    let name = ProjectSymbolizer::get_name(kb, entry)
    tab = tab.add_symbol(
      ProjectDisassemblyFunction::create(name~, entry=first, blocks~),
    )
  }
  tab
}

///|
/// `Symtab.externals`: the names of the external functions called by the
/// program.
pub fn ProjectDisassemblySymtab::externals(
  self : ProjectDisassemblySymtab,
) -> Array[String] {
  self.externals_value.copy()
}

///|
/// The symbol table with the external functions `names`.
pub fn ProjectDisassemblySymtab::with_externals(
  self : ProjectDisassemblySymtab,
  names : Array[String],
) -> ProjectDisassemblySymtab {
  { ..self, externals_value: names.copy(), }
}
