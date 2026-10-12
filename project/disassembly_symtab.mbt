///|
struct ProjectDisassemblyFunction {
  name_value : String
  entry_value : ProjectDisassemblyBlock
  blocks_value : Array[ProjectDisassemblyBlock]
}

///|
struct ProjectDisassemblySymtab {
  functions_value : Array[ProjectDisassemblyFunction]
  explicit_calls_value : Array[(UInt64, String)]
  implicit_calls_value : Array[(UInt64, String)]
  /// the names of the external functions called by the program (upstream
  /// `Symtab.externals`, the labels without addresses)
  externals_value : Array[String]
}

///|
fn project_disassembly_function_sort(
  blocks : Array[ProjectDisassemblyBlock],
) -> Array[ProjectDisassemblyBlock] {
  let seen : Map[(UInt64, Int32), Unit] = Map([])
  let result : Array[ProjectDisassemblyBlock] = []
  for block in blocks {
    let key = (block.addr(), block.memory_value.length())
    if !seen.contains(key) {
      seen[key] = ()
      result.push(block)
    }
  }
  result.sort_by((left, right) => left.compare(right))
  result
}

///|
fn project_disassembly_function_contains_block(
  blocks : Array[ProjectDisassemblyBlock],
  block : ProjectDisassemblyBlock,
) -> Bool {
  blocks.any(existing => existing.same(block))
}

///|
fn project_disassembly_function_cmp(
  left : ProjectDisassemblyFunction,
  right : ProjectDisassemblyFunction,
) -> Int32 {
  let addr_order = left.addr().compare(right.addr())
  if addr_order != 0 {
    addr_order
  } else {
    left.name().compare(right.name())
  }
}

///|
fn project_disassembly_symtab_unique_functions(
  functions : Array[ProjectDisassemblyFunction],
) -> Array[ProjectDisassemblyFunction] {
  let seen : Map[(String, UInt64), Unit] = Map([])
  let result : Array[ProjectDisassemblyFunction] = []
  for function in functions {
    let key = (function.name(), function.addr())
    if !seen.contains(key) {
      seen[key] = ()
      result.push(function)
    }
  }
  result.sort_by(project_disassembly_function_cmp)
  result
}

///|
fn project_disassembly_symtab_set_call(
  calls : Array[(UInt64, String)],
  addr : UInt64,
  callee : String,
) -> Array[(UInt64, String)] {
  let result : Array[(UInt64, String)] = []
  let mut replaced = false
  for call in calls {
    if call.0 == addr {
      if !replaced {
        result.push((addr, callee))
        replaced = true
      }
    } else {
      result.push(call)
    }
  }
  if !replaced {
    result.push((addr, callee))
  }
  result.sort_by((left, right) => left.0.compare(right.0))
  result
}

///|
fn project_disassembly_symtab_find_call(
  calls : Array[(UInt64, String)],
  addr : UInt64,
) -> String? {
  // the calls are sorted by their (distinct) addresses
  match calls.binary_search_by(call => call.0.compare(addr)) {
    Ok(i) => Some(calls[i].1)
    Err(_) => None
  }
}

///|
fn project_disassembly_symtab_find_block_containing(
  blocks : Array[ProjectDisassemblyBlock],
  addr : UInt64,
) -> ProjectDisassemblyBlock? {
  for block in blocks {
    if block.memory().contains(addr) {
      return Some(block)
    }
  }
  None
}

///|
fn project_disassembly_symtab_block_belongs_to(
  calls : ProjectDisassemblyCalls,
  entry : UInt64,
  block : ProjectDisassemblyBlock,
) -> Bool {
  calls.belongs(entry~, block.addr())
}

///|
fn project_disassembly_symtab_function_blocks(
  blocks : Array[ProjectDisassemblyBlock],
  calls : ProjectDisassemblyCalls,
  entry : UInt64,
) -> Array[ProjectDisassemblyBlock] {
  blocks.filter(block => {
    project_disassembly_symtab_block_belongs_to(calls, entry, block)
  })
}

///|
pub fn ProjectDisassemblyFunction::create(
  name~ : String,
  entry~ : ProjectDisassemblyBlock,
  blocks? : Array[ProjectDisassemblyBlock],
) -> ProjectDisassemblyFunction {
  let all_blocks = match blocks {
    Some(items) => items.copy()
    None => []
  }
  if !project_disassembly_function_contains_block(all_blocks, entry) {
    all_blocks.push(entry)
  }
  {
    name_value: name,
    entry_value: entry,
    blocks_value: project_disassembly_function_sort(all_blocks),
  }
}

///|
pub fn ProjectDisassemblyFunction::name(
  self : ProjectDisassemblyFunction,
) -> String {
  self.name_value
}

///|
pub fn ProjectDisassemblyFunction::entry(
  self : ProjectDisassemblyFunction,
) -> ProjectDisassemblyBlock {
  self.entry_value
}

///|
pub fn ProjectDisassemblyFunction::addr(
  self : ProjectDisassemblyFunction,
) -> UInt64 {
  self.entry_value.addr()
}

///|
pub fn ProjectDisassemblyFunction::blocks(
  self : ProjectDisassemblyFunction,
) -> Array[ProjectDisassemblyBlock] {
  self.blocks_value.copy()
}

///|
pub fn ProjectDisassemblyFunction::block_count(
  self : ProjectDisassemblyFunction,
) -> Int32 {
  self.blocks_value.length()
}

///|
pub fn ProjectDisassemblyFunction::contains_addr(
  self : ProjectDisassemblyFunction,
  addr : UInt64,
) -> Bool {
  self.blocks_value.any(block => block.memory().contains(addr))
}

///|
pub fn ProjectDisassemblyFunction::dominates(
  self : ProjectDisassemblyFunction,
  memory : @memory.Memory,
) -> Bool {
  self.blocks_value.any(block => block.memory().dominates(memory))
}

///|
pub fn ProjectDisassemblyFunction::intersects(
  self : ProjectDisassemblyFunction,
  memory : @memory.Memory,
) -> Bool {
  self.blocks_value.any(block => block.memory().intersects(memory))
}

///|
pub fn ProjectDisassemblyFunction::span(
  self : ProjectDisassemblyFunction,
) -> @memory.MemMap[Unit] {
  let mut span = @memory.MemMap::empty()
  for block in self.blocks_value {
    span = span.add(block.memory(), ())
  }
  span
}

///|
pub fn ProjectDisassemblySymtab::empty() -> ProjectDisassemblySymtab {
  {
    functions_value: [],
    explicit_calls_value: [],
    implicit_calls_value: [],
    externals_value: [],
  }
}

///|
pub fn ProjectDisassemblySymtab::create(
  functions? : Array[ProjectDisassemblyFunction],
) -> ProjectDisassemblySymtab {
  {
    functions_value: match functions {
      Some(items) => project_disassembly_symtab_unique_functions(items)
      None => []
    },
    explicit_calls_value: [],
    implicit_calls_value: [],
    externals_value: [],
  }
}

///|
pub fn ProjectDisassemblySymtab::add_symbol(
  self : ProjectDisassemblySymtab,
  function : ProjectDisassemblyFunction,
) -> ProjectDisassemblySymtab {
  let functions = self.functions_value.filter(existing => {
    existing.name() != function.name() && existing.addr() != function.addr()
  })
  functions.push(function)
  {
    ..self,
    functions_value: project_disassembly_symtab_unique_functions(functions),
  }
}

///|
pub fn ProjectDisassemblySymtab::remove(
  self : ProjectDisassemblySymtab,
  function : ProjectDisassemblyFunction,
) -> ProjectDisassemblySymtab {
  {
    functions_value: self.functions_value.filter(existing => {
      existing.name() != function.name() && existing.addr() != function.addr()
    }),
    explicit_calls_value: self.explicit_calls_value.filter(call => {
      call.1 != function.name() && !function.contains_addr(call.0)
    }),
    implicit_calls_value: self.implicit_calls_value.filter(call => {
      call.1 != function.name() && !function.contains_addr(call.0)
    }),
    externals_value: self.externals_value,
  }
}

///|
pub fn ProjectDisassemblySymtab::find_by_name(
  self : ProjectDisassemblySymtab,
  name : String,
) -> ProjectDisassemblyFunction? {
  for function in self.functions_value {
    if function.name() == name {
      return Some(function)
    }
  }
  None
}

///|
pub fn ProjectDisassemblySymtab::find_by_start(
  self : ProjectDisassemblySymtab,
  addr : UInt64,
) -> ProjectDisassemblyFunction? {
  for function in self.functions_value {
    if function.addr() == addr {
      return Some(function)
    }
  }
  None
}

///|
pub fn ProjectDisassemblySymtab::owners(
  self : ProjectDisassemblySymtab,
  addr : UInt64,
) -> Array[ProjectDisassemblyFunction] {
  self.functions_value.filter(function => function.contains_addr(addr))
}

///|
pub fn ProjectDisassemblySymtab::dominators(
  self : ProjectDisassemblySymtab,
  memory : @memory.Memory,
) -> Array[ProjectDisassemblyFunction] {
  self.functions_value.filter(function => function.dominates(memory))
}

///|
pub fn ProjectDisassemblySymtab::intersecting(
  self : ProjectDisassemblySymtab,
  memory : @memory.Memory,
) -> Array[ProjectDisassemblyFunction] {
  self.functions_value.filter(function => function.intersects(memory))
}

///|
pub fn ProjectDisassemblySymtab::to_sequence(
  self : ProjectDisassemblySymtab,
) -> Array[ProjectDisassemblyFunction] {
  self.functions_value.copy()
}

///|
pub fn ProjectDisassemblySymtab::insert_call(
  self : ProjectDisassemblySymtab,
  callsite : ProjectDisassemblyBlock,
  callee : String,
  implicit~ : Bool = false,
) -> ProjectDisassemblySymtab {
  let addr = callsite.addr()
  if implicit {
    {
      ..self,
      implicit_calls_value: project_disassembly_symtab_set_call(
        self.implicit_calls_value,
        addr,
        callee,
      ),
    }
  } else {
    {
      ..self,
      explicit_calls_value: project_disassembly_symtab_set_call(
        self.explicit_calls_value,
        addr,
        callee,
      ),
    }
  }
}

///|
pub fn ProjectDisassemblySymtab::explicit_callee(
  self : ProjectDisassemblySymtab,
  addr : UInt64,
) -> String? {
  project_disassembly_symtab_find_call(self.explicit_calls_value, addr)
}

///|
pub fn ProjectDisassemblySymtab::implicit_callee(
  self : ProjectDisassemblySymtab,
  addr : UInt64,
) -> String? {
  project_disassembly_symtab_find_call(self.implicit_calls_value, addr)
}

///|
pub fn ProjectDisassemblySymtab::callee(
  self : ProjectDisassemblySymtab,
  addr : UInt64,
) -> String? {
  match self.explicit_callee(addr) {
    Some(name) => Some(name)
    None => self.implicit_callee(addr)
  }
}

///|
pub fn ProjectDisassemblySymtab::of_project(
  project : Project,
) -> ProjectDisassemblySymtab {
  match project.disassembly_driver_state() {
    Some(driver) => {
      let kb = project.knowledge()
      project.with_disasm_providers(() => {
        let calls = ProjectDisassemblyCalls::empty().update(driver, kb)
        ProjectDisassemblySymtab::create_from_driver(driver, calls, kb)
      }) catch {
        _ => project_disassembly_symtab_of_state(project)
      }
    }
    None => project_disassembly_symtab_of_state(project)
  }
}

///|
/// The symbol table of the disassembly state of the project: the functions
/// are the subroutines of the partition of the blocks (see
/// `Project::disassembly_calls`), named by the project symbolizer, and the
/// edges between different functions are calls.
fn project_disassembly_symtab_of_state(
  project : Project,
) -> ProjectDisassemblySymtab {
  let blocks = project.disassembly().blocks_with_instructions()
  let calls = project.disassembly_calls()
  let symbolizer = project.symbolizer()
  let mut symtab = ProjectDisassemblySymtab::empty()
  for entry in calls.entries() {
    let function_blocks = project_disassembly_symtab_function_blocks(
      blocks, calls, entry,
    )
    match project_disassembly_symtab_find_block_containing(blocks, entry) {
      Some(entry_block) =>
        symtab = symtab.add_symbol(
          ProjectDisassemblyFunction::create(
            name=symbolizer.resolve(entry),
            entry=entry_block,
            blocks=function_blocks,
          ),
        )
      None => ()
    }
  }
  for edge in project.disassembly().edges() {
    match edge.target() {
      Some(target) => {
        let source = match
          project_disassembly_symtab_find_block_containing(
            blocks,
            edge.source(),
          ) {
          Some(block) => block
          None => continue
        }
        let destination = match
          project_disassembly_symtab_find_block_containing(blocks, target) {
          Some(block) => block
          None => continue
        }
        if !calls.siblings(source.addr(), destination.addr()) {
          let next_addr = source.memory().max_addr() + 1UL
          symtab = symtab.insert_call(
            source,
            symbolizer.resolve(destination.addr()),
            implicit=next_addr == destination.addr(),
          )
        }
      }
      None => ()
    }
  }
  symtab
}

///|
pub fn Project::disassembly_symtab(self : Project) -> ProjectDisassemblySymtab {
  ProjectDisassemblySymtab::of_project(self)
}
