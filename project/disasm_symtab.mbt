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
  let known_blocks : Map[(UInt64, UInt64, Int32), Unit] = Map([])
  // the callees of the call sites (as `insert_call` would record them)
  let explicit_calls : Map[UInt64, String] = Map([])
  let implicit_calls : Map[UInt64, String] = Map([])
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
      let key = (entry, addr, node.memory_value.length())
      let known = known_blocks.contains(key)
      known_blocks[key] = ()
      match graphs.get(entry) {
        None => graphs[entry] = (start, [node])
        Some((first, blocks)) => {
          if !known {
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
        if next == dst.addr() {
          implicit_calls[src.addr()] = name
        } else {
          explicit_calls[src.addr()] = name
        }
      }
    },
  )
  let sorted_calls = (calls : Map[UInt64, String]) => {
    let items = calls.to_array()
    items.sort_by((left, right) => left.0.compare(right.0))
    items
  }
  let externals : Array[String] = []
  for label in driver.externals() {
    match kb.collect(project_label_name, label) {
      Some(name) if !externals.contains(name) => externals.push(name)
      _ => ()
    }
  }
  // the functions, as successive `add_symbol`s would leave them: a symbol
  // replaces the ones with its name or its address
  let functions : Array[ProjectDisassemblyFunction?] = []
  let by_name : Map[String, Int32] = Map([])
  let by_addr : Map[UInt64, Int32] = Map([])
  let drop = (index : Int32) => {
    match functions[index] {
      Some(function) => {
        by_name.remove(function.name())
        by_addr.remove(function.addr())
        functions[index] = None
      }
      None => ()
    }
  }
  for entry in graphs.keys().collect() {
    guard graphs.get(entry) is Some((Some(first), blocks)) else { continue }
    let name = ProjectSymbolizer::get_name(kb, entry)
    let function = ProjectDisassemblyFunction::create(
      name~,
      entry=first,
      blocks~,
    )
    if by_name.get(function.name()) is Some(index) {
      drop(index)
    }
    if by_addr.get(function.addr()) is Some(index) {
      drop(index)
    }
    by_name[function.name()] = functions.length()
    by_addr[function.addr()] = functions.length()
    functions.push(Some(function))
  }
  {
    functions_value: project_disassembly_symtab_unique_functions(
      functions.filter_map(function => function),
    ),
    explicit_calls_value: sorted_calls(explicit_calls),
    implicit_calls_value: sorted_calls(implicit_calls),
    externals_value: externals,
  }
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
