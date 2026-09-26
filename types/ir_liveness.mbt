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
fn Term::blk_phi_lhs_vars(self : Term[Blk]) -> Array[Var] {
  let vars = []
  for phi in self.payload_value.phis {
    add_var(vars, phi.phi_lhs())
  }
  vars
}

///|
fn Term::blk_def_lhs_vars(self : Term[Blk]) -> Array[Var] {
  let vars = []
  for def in self.payload_value.defs {
    add_var(vars, def.lhs())
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
  self.blk_free_vars()
}

///|
pub fn Term::blk_value_free_vars(self : Term[Blk]) -> Array[Var] {
  let vars = []
  for phi in self.payload_value.phis {
    add_vars(vars, phi.phi_free_vars())
  }
  add_vars(vars, self.blk_liveness_uses())
  vars
}

///|
/// Per-block liveness over the blocks reachable from `entry` (the first
/// block by default), in reverse postorder.
///
/// This is a wrapper over `Live::compute`: `live_in` is `Live::ins` and
/// `live_out` is `Live::outs`, so the whole subroutine (including
/// disconnected components and `Out`/`Both` argument exit seeding) takes
/// part in the analysis and phi-nodes follow the upstream convention (the
/// phi left-hand side is live-out of the predecessors, the operands are
/// uses of the predecessors).
pub fn Term::sub_liveness(
  self : Term[Sub],
  entry? : Tid,
) -> Array[BlockLiveness] {
  let live = Live::compute(self)
  [
    for block in self.sub_reverse_postorder(entry?) => {
      {
        block_value: block,
        live_in_value: live.ins(block.tid()),
        live_out_value: live.outs(block.tid()),
      }
    }
  ]
}

///|
/// The variables live at the entry to the subroutine. Without `entry` this
/// is upstream `Live.vars` (the live-outs of the pseudo start node); with
/// `entry` it is the live-in set of that block.
pub fn Term::sub_live_in_vars(self : Term[Sub], entry? : Tid) -> Array[Var] {
  let live = Live::compute(self)
  match entry {
    Some(tid) if self.find_blk(tid) is Some(_) => live.ins(tid)
    Some(_) => []
    None => live.vars()
  }
}

///|
pub fn Term::sub_ssa_free_vars(self : Term[Sub]) -> Array[Var] {
  let vars = []
  for blk in self.payload_value.blks {
    for variable in blk.blk_free_vars() {
      if variable.index() == 0 {
        add_var(vars, variable)
      }
    }
  }
  vars
}

///|
/// Upstream `Sub.free_vars` (`free_vars_of_sub`); see `Sub::free_vars`.
pub fn Term::sub_external_vars(self : Term[Sub], entry? : Tid) -> Array[Var] {
  if self.is_ssa() {
    self.sub_ssa_free_vars()
  } else {
    self.sub_live_in_vars(entry?)
  }
}
