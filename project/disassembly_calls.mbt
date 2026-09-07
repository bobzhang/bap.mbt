///|
struct ProjectDisassemblyCalls {
  entries_value : Array[UInt64]
  memberships_value : Array[(UInt64, UInt64, Array[UInt64])]
}

///|
fn project_disassembly_calls_contains_addr(
  addrs : Array[UInt64],
  addr : UInt64,
) -> Bool {
  addrs.contains(addr)
}

///|
fn project_disassembly_calls_find_block_containing(
  blocks : Array[@memory.Memory],
  addr : UInt64,
) -> @memory.Memory? {
  for block in blocks {
    if block.contains(addr) {
      return Some(block)
    }
  }
  None
}

///|
fn project_disassembly_calls_find_membership(
  memberships : Array[(UInt64, UInt64, Array[UInt64])],
  block_start : UInt64,
) -> Int? {
  for i in 0..<memberships.length() {
    if memberships[i].0 == block_start {
      return Some(i)
    }
  }
  None
}

///|
fn project_disassembly_calls_add_membership(
  memberships : Array[(UInt64, UInt64, Array[UInt64])],
  block : @memory.Memory,
  entry : UInt64,
) -> Unit {
  let block_start = block.min_addr()
  match project_disassembly_calls_find_membership(memberships, block_start) {
    Some(index) => {
      let entries = memberships[index].2.copy()
      if !entries.contains(entry) {
        entries.push(entry)
        memberships[index] = (block_start, block.max_addr(), entries)
      }
    }
    None => memberships.push((block_start, block.max_addr(), [entry]))
  }
}

///|
fn project_disassembly_calls_sorted_blocks(
  blocks : Array[@memory.Memory],
) -> Array[@memory.Memory] {
  let sorted = blocks.copy()
  sorted.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  sorted
}

///|
fn project_disassembly_calls_entry_blocks(
  blocks : Array[@memory.Memory],
  roots : Array[UInt64],
) -> Array[@memory.Memory] {
  let entries : Array[@memory.Memory] = []
  for root in roots {
    for block in blocks {
      if block.min_addr() == root &&
        !entries.any(entry => entry.min_addr() == root) {
        entries.push(block)
      }
    }
  }
  entries.sort_by((left, right) => left.min_addr().compare(right.min_addr()))
  entries
}

///|
fn project_disassembly_calls_add_reachable(
  memberships : Array[(UInt64, UInt64, Array[UInt64])],
  blocks : Array[@memory.Memory],
  edges : Array[ProjectDisassemblyEdge],
  entries : Array[UInt64],
  start : @memory.Memory,
) -> Unit {
  let entry = start.min_addr()
  let visited : Array[UInt64] = []
  let stack = [start]
  while stack.length() > 0 {
    match stack.pop() {
      Some(block) => {
        let block_start = block.min_addr()
        if !visited.contains(block_start) {
          visited.push(block_start)
          project_disassembly_calls_add_membership(memberships, block, entry)
          for edge in edges {
            if block.contains(edge.source()) {
              match edge.target() {
                Some(target) =>
                  match
                    project_disassembly_calls_find_block_containing(
                      blocks, target,
                    ) {
                    Some(target_block) => {
                      let target_start = target_block.min_addr()
                      if target_start == entry ||
                        !project_disassembly_calls_contains_addr(
                          entries, target_start,
                        ) {
                        stack.push(target_block)
                      }
                    }
                    None => ()
                  }
                None => ()
              }
            }
          }
        }
      }
      None => ()
    }
  }
}

///|
fn project_disassembly_calls_entries_for_block(
  calls : ProjectDisassemblyCalls,
  addr : UInt64,
) -> Array[UInt64] {
  for membership in calls.memberships_value {
    if addr >= membership.0 && addr <= membership.1 {
      return membership.2.copy()
    }
  }
  []
}

///|
pub fn ProjectDisassemblyCalls::empty() -> ProjectDisassemblyCalls {
  { entries_value: [], memberships_value: [], }
}

///|
pub fn ProjectDisassemblyCalls::of_disassembly(
  disassembly : ProjectDisassemblyState,
  roots : Array[UInt64],
) -> ProjectDisassemblyCalls {
  let blocks = project_disassembly_calls_sorted_blocks(disassembly.blocks())
  let entry_blocks = project_disassembly_calls_entry_blocks(blocks, roots)
  let entries = entry_blocks.map(block => block.min_addr())
  let memberships : Array[(UInt64, UInt64, Array[UInt64])] = []
  let edges = disassembly.edges()
  for entry_block in entry_blocks {
    project_disassembly_calls_add_reachable(
      memberships, blocks, edges, entries, entry_block,
    )
  }
  { entries_value: entries, memberships_value: memberships, }
}

///|
pub fn ProjectDisassemblyCalls::entries(
  self : ProjectDisassemblyCalls,
) -> Array[UInt64] {
  self.entries_value.copy()
}

///|
pub fn ProjectDisassemblyCalls::belongs(
  self : ProjectDisassemblyCalls,
  entry~ : UInt64,
  addr : UInt64,
) -> Bool {
  if entry == addr {
    return true
  }
  project_disassembly_calls_entries_for_block(self, addr).contains(entry)
}

///|
pub fn ProjectDisassemblyCalls::entry(
  self : ProjectDisassemblyCalls,
  addr : UInt64,
) -> UInt64 {
  let matching_entries = project_disassembly_calls_entries_for_block(self, addr)
  if matching_entries.length() == 1 {
    matching_entries[0]
  } else {
    addr
  }
}

///|
pub fn ProjectDisassemblyCalls::siblings(
  self : ProjectDisassemblyCalls,
  left : UInt64,
  right : UInt64,
) -> Bool {
  if left == right {
    return true
  }
  let left_entries = project_disassembly_calls_entries_for_block(self, left)
  let right_entries = project_disassembly_calls_entries_for_block(self, right)
  left_entries.any(entry => right_entries.contains(entry))
}

///|
pub fn Project::disassembly_calls(self : Project) -> ProjectDisassemblyCalls {
  ProjectDisassemblyCalls::of_disassembly(
    self.disassembly(),
    self.rooter().roots(),
  )
}
