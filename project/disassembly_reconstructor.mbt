///|
struct ProjectDisassemblyReconstructor {
  run_fn : (ProjectDisassemblyCfg) -> ProjectDisassemblySymtab
}

///|
fn project_disassembly_reconstructor_contains_block(
  blocks : Array[ProjectDisassemblyBlock],
  block : ProjectDisassemblyBlock,
) -> Bool {
  blocks.any(existing => existing.same(block))
}

///|
fn project_disassembly_reconstructor_add_block(
  blocks : Array[ProjectDisassemblyBlock],
  block : ProjectDisassemblyBlock,
) -> Unit {
  if !project_disassembly_reconstructor_contains_block(blocks, block) {
    blocks.push(block)
  }
}

///|
fn project_disassembly_reconstructor_sort_blocks(
  blocks : Array[ProjectDisassemblyBlock],
) -> Array[ProjectDisassemblyBlock] {
  let result : Array[ProjectDisassemblyBlock] = []
  for block in blocks {
    project_disassembly_reconstructor_add_block(result, block)
  }
  result.sort_by((left, right) => left.compare(right))
  result
}

///|
fn project_disassembly_reconstructor_contains_edge(
  edges : Array[ProjectDisassemblyCfgEdge],
  edge : ProjectDisassemblyCfgEdge,
) -> Bool {
  edges.any(existing => existing.same(edge))
}

///|
fn project_disassembly_reconstructor_add_edge(
  edges : Array[ProjectDisassemblyCfgEdge],
  edge : ProjectDisassemblyCfgEdge,
) -> Unit {
  if !project_disassembly_reconstructor_contains_edge(edges, edge) {
    edges.push(edge)
  }
}

///|
fn project_disassembly_reconstructor_edge_diff(
  left : Array[ProjectDisassemblyCfgEdge],
  right : Array[ProjectDisassemblyCfgEdge],
) -> Array[ProjectDisassemblyCfgEdge] {
  left.filter(edge => {
    !project_disassembly_reconstructor_contains_edge(right, edge)
  })
}

///|
fn project_disassembly_reconstructor_roots_contain(
  roots : Array[UInt64],
  block : ProjectDisassemblyBlock,
) -> Bool {
  roots.contains(block.addr())
}

///|
fn project_disassembly_reconstructor_is_start(
  cfg : ProjectDisassemblyCfg,
  roots : Array[UInt64],
  block : ProjectDisassemblyBlock,
) -> Bool {
  project_disassembly_reconstructor_roots_contain(roots, block) ||
  cfg.in_degree(block) == 0
}

///|
fn project_disassembly_reconstructor_is_call(
  block : ProjectDisassemblyBlock,
) -> Bool {
  block.terminator().has_kind(ProjectCall)
}

///|
fn project_disassembly_reconstructor_entries_of_block(
  cfg : ProjectDisassemblyCfg,
  roots : Array[UInt64],
  block : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  let entries : Array[ProjectDisassemblyBlock] = []
  if project_disassembly_reconstructor_is_start(cfg, roots, block) {
    project_disassembly_reconstructor_add_block(entries, block)
  }
  if project_disassembly_reconstructor_is_call(block) {
    for edge in cfg.out_edges(block) {
      if edge.kind() != FallEdge {
        project_disassembly_reconstructor_add_block(entries, edge.dst())
      }
    }
  }
  project_disassembly_reconstructor_sort_blocks(entries)
}

///|
fn project_disassembly_reconstructor_is_unresolved(
  cfg : ProjectDisassemblyCfg,
  block : ProjectDisassemblyBlock,
) -> Bool {
  let outputs = cfg.out_edges(block)
  outputs.is_empty() || (outputs.length() == 1 && outputs[0].kind() == FallEdge)
}

///|
fn project_disassembly_reconstructor_add_unresolved(
  symtab : ProjectDisassemblySymtab,
  name : (UInt64) -> String,
  cfg : ProjectDisassemblyCfg,
  block : ProjectDisassemblyBlock,
) -> ProjectDisassemblySymtab {
  if project_disassembly_reconstructor_is_unresolved(cfg, block) {
    symtab.insert_call(block, name(block.terminator().addr()))
  } else {
    symtab
  }
}

///|
fn project_disassembly_reconstructor_collect(
  name : (UInt64) -> String,
  cfg : ProjectDisassemblyCfg,
  roots : Array[UInt64],
) -> (Array[ProjectDisassemblyBlock], ProjectDisassemblySymtab) {
  let entries : Array[ProjectDisassemblyBlock] = []
  let mut symtab = ProjectDisassemblySymtab::empty()
  for block in cfg.nodes() {
    for
      entry in project_disassembly_reconstructor_entries_of_block(
        cfg, roots, block,
      ) {
      project_disassembly_reconstructor_add_block(entries, entry)
    }
    symtab = project_disassembly_reconstructor_add_unresolved(
      symtab, name, cfg, block,
    )
  }
  (project_disassembly_reconstructor_sort_blocks(entries), symtab)
}

///|
fn project_disassembly_reconstructor_sub(
  known_roots : Array[ProjectDisassemblyBlock],
  cfg : ProjectDisassemblyCfg,
  start : ProjectDisassemblyBlock,
) -> (ProjectDisassemblyCfg, Array[ProjectDisassemblyCfgEdge]) {
  let mut sub_cfg = ProjectDisassemblyCfg::empty().insert_node(start)
  let inputs : Array[ProjectDisassemblyCfgEdge] = []
  let stack = [start]
  while !stack.is_empty() {
    match stack.pop() {
      Some(node) => {
        for edge in cfg.in_edges(node) {
          project_disassembly_reconstructor_add_edge(inputs, edge)
        }
        for edge in cfg.out_edges(node) {
          if !project_disassembly_reconstructor_contains_block(
              known_roots,
              edge.dst(),
            ) {
            let seen = sub_cfg.has_node(edge.dst())
            sub_cfg = sub_cfg.insert_edge(edge)
            if !seen {
              stack.push(edge.dst())
            }
          }
        }
      }
      None => ()
    }
  }
  (sub_cfg, inputs)
}

///|
fn project_disassembly_reconstructor_reachable(
  cfg : ProjectDisassemblyCfg,
  start : ProjectDisassemblyBlock,
) -> Array[ProjectDisassemblyBlock] {
  let result : Array[ProjectDisassemblyBlock] = []
  let stack = [start]
  while !stack.is_empty() {
    match stack.pop() {
      Some(node) =>
        if !project_disassembly_reconstructor_contains_block(result, node) {
          result.push(node)
          for next in cfg.successors(node) {
            stack.push(next)
          }
        }
      None => ()
    }
  }
  project_disassembly_reconstructor_sort_blocks(result)
}

///|
fn project_disassembly_reconstructor_remove_reachable(
  cfg : ProjectDisassemblyCfg,
  start : ProjectDisassemblyBlock,
) -> ProjectDisassemblyCfg {
  let mut result = cfg
  for node in project_disassembly_reconstructor_reachable(cfg, start) {
    result = result.remove_node(node)
  }
  result.remove_node(start)
}

///|
fn project_disassembly_reconstructor_collect_destinations(
  edges : Array[ProjectDisassemblyCfgEdge],
) -> Array[ProjectDisassemblyBlock] {
  let result : Array[ProjectDisassemblyBlock] = []
  for edge in edges {
    project_disassembly_reconstructor_add_block(result, edge.dst())
  }
  project_disassembly_reconstructor_sort_blocks(result)
}

///|
fn project_disassembly_reconstructor_update_symtab(
  symtab : ProjectDisassemblySymtab,
  name : (UInt64) -> String,
  cfg : ProjectDisassemblyCfg,
  entry : ProjectDisassemblyBlock,
  inputs : Array[ProjectDisassemblyCfgEdge],
) -> ProjectDisassemblySymtab {
  let function_name = name(entry.addr())
  let mut result = symtab.add_symbol(
    ProjectDisassemblyFunction::create(
      name=function_name,
      entry~,
      blocks=cfg.nodes(),
    ),
  )
  for edge in inputs {
    result = result.insert_call(
      edge.src(),
      function_name,
      implicit=edge.kind() == FallEdge,
    )
  }
  result
}

///|
fn project_disassembly_reconstructor_default_run(
  name : (UInt64) -> String,
  roots : Array[UInt64],
  cfg : ProjectDisassemblyCfg,
) -> ProjectDisassemblySymtab {
  let (entries, initial_symtab) = project_disassembly_reconstructor_collect(
    name, cfg, roots,
  )
  let known_roots = entries.copy()
  let processed : Array[ProjectDisassemblyBlock] = []
  let pending = entries.copy()
  let mut symtab = initial_symtab
  let mut index = 0
  while index < pending.length() {
    let root = pending[index]
    index = index + 1
    if !project_disassembly_reconstructor_contains_block(processed, root) {
      processed.push(root)
      let self_inputs = cfg.in_edges(root)
      let (sub_cfg, inputs) = project_disassembly_reconstructor_sub(
        known_roots, cfg, root,
      )
      let body_edges = sub_cfg.edges()
      let call_inputs = project_disassembly_reconstructor_edge_diff(
        project_disassembly_reconstructor_edge_diff(inputs, body_edges),
        self_inputs,
      )
      let calls = project_disassembly_reconstructor_collect_destinations(
        call_inputs,
      )
      let mut function_cfg = sub_cfg
      for call in calls {
        function_cfg = project_disassembly_reconstructor_remove_reachable(
          function_cfg, call,
        )
        if !project_disassembly_reconstructor_contains_block(known_roots, call) {
          known_roots.push(call)
          pending.push(call)
        }
      }
      symtab = project_disassembly_reconstructor_update_symtab(
        symtab, name, function_cfg, root, self_inputs,
      )
    }
  }
  symtab
}

///|
fn project_disassembly_reconstructor_find_node(
  cfg : ProjectDisassemblyCfg,
  addr : UInt64,
) -> ProjectDisassemblyBlock? {
  for node in cfg.nodes() {
    if node.addr() == addr {
      return Some(node)
    }
  }
  None
}

///|
fn project_disassembly_reconstructor_find_group(
  names : Array[String],
  name : String,
) -> Int? {
  for index in 0..<names.length() {
    if names[index] == name {
      return Some(index)
    }
  }
  None
}

///|
pub fn ProjectDisassemblyReconstructor::create(
  run : (ProjectDisassemblyCfg) -> ProjectDisassemblySymtab,
) -> ProjectDisassemblyReconstructor {
  { run_fn: run, }
}

///|
pub fn ProjectDisassemblyReconstructor::run(
  self : ProjectDisassemblyReconstructor,
  cfg : ProjectDisassemblyCfg,
) -> ProjectDisassemblySymtab {
  (self.run_fn)(cfg)
}

///|
pub fn ProjectDisassemblyReconstructor::default(
  name : (UInt64) -> String,
  roots : Array[UInt64],
) -> ProjectDisassemblyReconstructor {
  let root_addrs = roots.copy()
  ProjectDisassemblyReconstructor::create(cfg => {
    project_disassembly_reconstructor_default_run(name, root_addrs, cfg)
  })
}

///|
pub fn ProjectDisassemblyReconstructor::of_blocks(
  blocks : Array[(String, UInt64, UInt64)],
) -> ProjectDisassemblyReconstructor {
  let symbols = blocks.copy()
  ProjectDisassemblyReconstructor::create(cfg => {
    let names : Array[String] = []
    let groups : Array[Array[ProjectDisassemblyBlock]] = []
    for symbol in symbols {
      match project_disassembly_reconstructor_find_node(cfg, symbol.1) {
        Some(block) =>
          match project_disassembly_reconstructor_find_group(names, symbol.0) {
            Some(index) => {
              let group = groups[index].copy()
              project_disassembly_reconstructor_add_block(group, block)
              groups[index] = group
            }
            None => {
              names.push(symbol.0)
              groups.push([block])
            }
          }
        None => ()
      }
    }
    let mut symtab = ProjectDisassemblySymtab::empty()
    for index in 0..<names.length() {
      let function_blocks = project_disassembly_reconstructor_sort_blocks(
        groups[index],
      )
      if !function_blocks.is_empty() {
        symtab = symtab.add_symbol(
          ProjectDisassemblyFunction::create(
            name=names[index],
            entry=function_blocks[0],
            blocks=function_blocks,
          ),
        )
      }
    }
    symtab
  })
}
