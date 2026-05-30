///|
struct BlockLiveness {
  block_value : Term[Blk]
  live_in_value : Array[Var]
  live_out_value : Array[Var]
}

///|
pub fn BlockLiveness::block(self : BlockLiveness) -> Term[Blk] {
  self.block_value
}

///|
pub fn BlockLiveness::live_in(self : BlockLiveness) -> Array[Var] {
  self.live_in_value.copy()
}

///|
pub fn BlockLiveness::live_out(self : BlockLiveness) -> Array[Var] {
  self.live_out_value.copy()
}

///|
fn var_set_equal(lhs : Array[Var], rhs : Array[Var]) -> Bool {
  lhs.length() == rhs.length() && lhs.all(item => rhs.contains(item))
}

///|
fn vars_without(vars : Array[Var], killed : Array[Var]) -> Array[Var] {
  let out = []
  for variable in vars {
    if !killed.contains(variable) {
      add_var(out, variable)
    }
  }
  out
}

///|
fn liveness_map_get(map : Map[Tid, Array[Var]], tid : Tid) -> Array[Var] {
  match map.get(tid) {
    Some(vars) => vars
    None => []
  }
}

///|
fn Term::blk_phi_lhs_vars(self : Term[Blk]) -> Array[Var] {
  let vars = []
  for phi in self.payload_value.phis {
    add_var(vars, phi.phi_lhs())
  }
  vars
}

///|
pub fn Term::blk_defined_vars(self : Term[Blk]) -> Array[Var] {
  let vars = self.blk_phi_lhs_vars()
  for def in self.payload_value.defs {
    add_var(vars, def.lhs())
  }
  vars
}

///|
pub fn Term::phi_edge_free_vars(
  self : Term[Phi],
  predecessor : Tid,
) -> Array[Var] {
  let vars = []
  for pair in self.values() {
    if pair.0 == predecessor {
      add_vars(vars, pair.1.free_vars())
    }
  }
  vars
}

///|
pub fn Term::blk_phi_edge_free_vars(
  self : Term[Blk],
  predecessor : Tid,
) -> Array[Var] {
  let vars = []
  for phi in self.payload_value.phis {
    add_vars(vars, phi.phi_edge_free_vars(predecessor))
  }
  vars
}

///|
fn Term::blk_liveness_uses(self : Term[Blk]) -> Array[Var] {
  vars_without(self.blk_free_vars(), self.blk_phi_lhs_vars())
}

///|
pub fn Term::sub_liveness(
  self : Term[Sub],
  entry? : Tid,
) -> Array[BlockLiveness] {
  let blocks = self.sub_reverse_postorder(entry?)
  let live_in : Map[Tid, Array[Var]] = {}
  let live_out : Map[Tid, Array[Var]] = {}
  for block in blocks {
    live_in[block.tid()] = []
    live_out[block.tid()] = []
  }
  let mut changed = true
  while changed {
    changed = false
    for offset in 0..<blocks.length() {
      let block = blocks[blocks.length() - offset - 1]
      let out_vars = []
      for successor in self.sub_successor_blocks(block) {
        let successor_live_in = liveness_map_get(live_in, successor.tid())
        add_vars(
          out_vars,
          vars_without(successor_live_in, successor.blk_phi_lhs_vars()),
        )
        add_vars(out_vars, successor.blk_phi_edge_free_vars(block.tid()))
      }
      let in_vars = block.blk_liveness_uses()
      add_vars(in_vars, vars_without(out_vars, block.blk_defined_vars()))
      if !var_set_equal(out_vars, liveness_map_get(live_out, block.tid())) {
        live_out[block.tid()] = out_vars
        changed = true
      }
      if !var_set_equal(in_vars, liveness_map_get(live_in, block.tid())) {
        live_in[block.tid()] = in_vars
        changed = true
      }
    }
  }
  [
    for block in blocks => {
      {
        block_value: block,
        live_in_value: liveness_map_get(live_in, block.tid()),
        live_out_value: liveness_map_get(live_out, block.tid()),
      }
    }
  ]
}
