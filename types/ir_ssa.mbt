///|
let ssa_form_attr = "ssa_form"

///|
fn ssa_var_key(variable : Var) -> String {
  variable.base().to_string()
}

///|
fn ssa_add_base_var(vars : Array[Var], variable : Var) -> Unit {
  let base = variable.base()
  let key = ssa_var_key(base)
  if !vars.any(item => ssa_var_key(item) == key) {
    vars.push(base)
  }
}

///|
fn Term::ssa_candidate_vars(self : Term[Sub]) -> Array[Var] {
  let vars = []
  for blk in self.payload_value.blks {
    for variable in blk.blk_free_vars() {
      ssa_add_base_var(vars, variable)
    }
  }
  vars
}

///|
fn Term::ssa_defines_var(self : Term[Blk], variable : Var) -> Bool {
  let key = ssa_var_key(variable)
  self.payload_value.phis.any(phi => ssa_var_key(phi.phi_lhs()) == key) ||
  self.payload_value.defs.any(def => ssa_var_key(def.lhs()) == key)
}

///|
fn Term::ssa_has_phi_for_var(self : Term[Blk], variable : Var) -> Bool {
  let key = ssa_var_key(variable)
  self.payload_value.phis.any(phi => ssa_var_key(phi.phi_lhs()) == key)
}

///|
fn Term::ssa_with_phis(self : Term[Blk], phis : Array[Term[Phi]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, phis, })
}

///|
fn Term::ssa_with_defs(self : Term[Blk], defs : Array[Term[Def]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, defs, })
}

///|
fn Term::ssa_with_jmps(self : Term[Blk], jmps : Array[Term[Jmp]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, jmps, })
}

///|
fn ssa_blocks_that_define_var(
  sub : Term[Sub],
  variable : Var,
) -> Array[Term[Blk]] {
  [
    for blk in sub.payload_value.blks => {
      if blk.ssa_defines_var(variable) {
        Some(blk)
      } else {
        None
      }
    }
  ].filter_map(item => item)
}

///|
fn ssa_iterated_frontier(
  frontiers : Map[Tid, Set[Tid]],
  seeds : Array[Tid],
) -> Set[Tid] {
  let seed_set : Set[Tid] = Set::from_array(seeds)
  let mut idf : Set[Tid] = Set([])
  let mut changed = true
  while changed {
    let next : Set[Tid] = Set([])
    for seed in seed_set {
      match frontiers.get(seed) {
        Some(frontier) =>
          for tid in frontier {
            next.add(tid)
          }
        None => ()
      }
    }
    for tid in idf {
      match frontiers.get(tid) {
        Some(frontier) =>
          for item in frontier {
            next.add(item)
          }
        None => ()
      }
    }
    changed = next != idf
    idf = next
  }
  idf
}

///|
fn ssa_insert_phi_for_var(
  sub : Term[Sub],
  graph : @graphlib.Graph[Tid, Tid],
  tid : Tid,
  variable : Var,
) -> Term[Sub] {
  match sub.find_blk(tid) {
    Some(blk) if !blk.ssa_has_phi_for_var(variable) => {
      let values = [
        for pred in graph.predecessors(tid) => {
          if sub.find_blk(pred) is Some(_) {
            Some((pred, Var(variable)))
          } else {
            None
          }
        }
      ].filter_map(item => item)
      let phi = Phi::of_list(variable, values)
      sub.update_blk(blk.append_phi(phi))
    }
    _ => sub
  }
}

///|
fn Term::ssa_insert_phi_nodes(self : Term[Sub], entry : Tid) -> Term[Sub] {
  let graph = self.sub_cfg()
  let frontiers = graph.dominance_frontiers(entry)
  let mut sub = self
  for variable in self.ssa_candidate_vars() {
    let seeds = [entry]
    for blk in ssa_blocks_that_define_var(sub, variable) {
      if !seeds.contains(blk.tid()) {
        seeds.push(blk.tid())
      }
    }
    for tid in ssa_iterated_frontier(frontiers, seeds) {
      sub = ssa_insert_phi_for_var(sub, graph, tid, variable)
    }
  }
  sub
}

///|
fn ssa_top(variable : Var, stacks : Map[String, Array[Var]]) -> Var {
  match stacks.get(ssa_var_key(variable)) {
    Some(stack) =>
      match stack.last() {
        Some(top) => top
        None => variable
      }
    None => variable
  }
}

///|
fn ssa_push(variable : Var, stacks : Map[String, Array[Var]]) -> Unit {
  let key = ssa_var_key(variable)
  let stack = stacks.get_or_default(key, [])
  stack.push(variable)
  stacks[key] = stack
}

///|
fn ssa_pop(variable : Var, stacks : Map[String, Array[Var]]) -> Unit {
  let key = ssa_var_key(variable)
  match stacks.get(key) {
    Some(stack) => {
      let _ = stack.pop()
      stacks[key] = stack
    }
    None => ()
  }
}

///|
fn ssa_new_name(
  variable : Var,
  stacks : Map[String, Array[Var]],
  counters : Map[String, Int],
) -> Var {
  let base = variable.base()
  let key = ssa_var_key(base)
  let index = counters.get_or_default(key, 0) + 1
  counters[key] = index
  let renamed = base.with_index(index)
  ssa_push(renamed, stacks)
  renamed
}

///|
fn ssa_rename_exp(exp : Exp, stacks : Map[String, Array[Var]]) -> Exp {
  match exp {
    Int(_) | Unknown(_) => exp
    Var(variable) => Var(ssa_top(variable, stacks))
    Load(mem~, addr~, endian~, typ~) =>
      Load(
        mem=ssa_rename_exp(mem, stacks),
        addr=ssa_rename_exp(addr, stacks),
        endian~,
        typ~,
      )
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=ssa_rename_exp(mem, stacks),
        addr=ssa_rename_exp(addr, stacks),
        value=ssa_rename_exp(value, stacks),
        endian~,
      )
    Let(variable, value, body) => {
      let inner_stacks = stacks.copy()
      inner_stacks.remove(ssa_var_key(variable))
      Let(
        variable,
        ssa_rename_exp(value, stacks),
        ssa_rename_exp(body, inner_stacks),
      )
    }
    Cast(typ, inner) => Cast(typ, ssa_rename_exp(inner, stacks))
    UnOp(op, inner) => UnOp(op, ssa_rename_exp(inner, stacks))
    BinOp(op, lhs, rhs) =>
      BinOp(op, ssa_rename_exp(lhs, stacks), ssa_rename_exp(rhs, stacks))
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=ssa_rename_exp(cond, stacks),
        yes=ssa_rename_exp(yes, stacks),
        no=ssa_rename_exp(no, stacks),
      )
  }
}

///|
fn ssa_rename_phi_lhs(
  phi : Term[Phi],
  stacks : Map[String, Array[Var]],
  counters : Map[String, Int],
  pushed : Array[Var],
) -> Term[Phi] {
  let lhs = ssa_new_name(phi.phi_lhs(), stacks, counters)
  pushed.push(lhs)
  phi.with_phi_lhs(lhs)
}

///|
fn ssa_rename_def(
  def : Term[Def],
  stacks : Map[String, Array[Var]],
  counters : Map[String, Int],
  pushed : Array[Var],
) -> Term[Def] {
  let rhs = ssa_rename_exp(def.rhs(), stacks)
  let lhs = ssa_new_name(def.lhs(), stacks, counters)
  pushed.push(lhs)
  def.with_lhs(lhs).with_rhs(rhs)
}

///|
fn ssa_rename_jmp(
  jmp : Term[Jmp],
  stacks : Map[String, Array[Var]],
) -> Term[Jmp] {
  jmp.map_jmp_exp(exp => ssa_rename_exp(exp, stacks))
}

///|
fn ssa_update_phi_edge(
  phi : Term[Phi],
  predecessor : Tid,
  stacks : Map[String, Array[Var]],
) -> Term[Phi] {
  let values = [
    for pair in phi.values() => {
      if pair.0 == predecessor {
        (pair.0, ssa_rename_exp(pair.1, stacks))
      } else {
        pair
      }
    }
  ]
  phi.with_payload({ ..phi.payload_value, values, })
}

///|
fn ssa_update_successor_phis(
  sub : Term[Sub],
  graph : @graphlib.Graph[Tid, Tid],
  predecessor : Tid,
  stacks : Map[String, Array[Var]],
) -> Term[Sub] {
  let mut updated = sub
  for succ in graph.successors(predecessor) {
    match updated.find_blk(succ) {
      Some(blk) => {
        let phis = [
          for phi in blk.payload_value.phis => {
            ssa_update_phi_edge(phi, predecessor, stacks)
          }
        ]
        updated = updated.update_blk(blk.ssa_with_phis(phis))
      }
      None => ()
    }
  }
  updated
}

///|
fn ssa_dom_children(
  blocks : Array[Term[Blk]],
  idoms : Map[Tid, Tid],
  parent : Tid,
) -> Array[Tid] {
  [
    for blk in blocks => {
      if idoms.get(blk.tid()) == Some(parent) {
        Some(blk.tid())
      } else {
        None
      }
    }
  ].filter_map(item => item)
}

///|
fn ssa_rename_block(
  sub : Term[Sub],
  graph : @graphlib.Graph[Tid, Tid],
  blocks : Array[Term[Blk]],
  idoms : Map[Tid, Tid],
  tid : Tid,
  stacks : Map[String, Array[Var]],
  counters : Map[String, Int],
) -> Term[Sub] {
  let mut current = sub
  let pushed = []
  match current.find_blk(tid) {
    Some(blk) => {
      let phis = [
        for phi in blk.payload_value.phis => {
          ssa_rename_phi_lhs(phi, stacks, counters, pushed)
        }
      ]
      let defs = [
        for def in blk.payload_value.defs => {
          ssa_rename_def(def, stacks, counters, pushed)
        }
      ]
      let jmps = [
        for jmp in blk.payload_value.jmps => ssa_rename_jmp(jmp, stacks)
      ]
      let renamed = blk
        .ssa_with_phis(phis)
        .ssa_with_defs(defs)
        .ssa_with_jmps(jmps)
      current = current.update_blk(renamed)
      current = ssa_update_successor_phis(current, graph, tid, stacks)
    }
    None => ()
  }
  for child in ssa_dom_children(blocks, idoms, tid) {
    current = ssa_rename_block(
      current, graph, blocks, idoms, child, stacks, counters,
    )
  }
  for offset in 0..<pushed.length() {
    ssa_pop(pushed[pushed.length() - offset - 1], stacks)
  }
  current
}

///|
fn Term::ssa_rename(self : Term[Sub], entry : Tid) -> Term[Sub] {
  let graph = self.sub_cfg()
  let blocks = self.payload_value.blks.copy()
  let idoms = graph.immediate_dominators(entry)
  let stacks : Map[String, Array[Var]] = {}
  let counters : Map[String, Int] = {}
  ssa_rename_block(self, graph, blocks, idoms, entry, stacks, counters)
}

///|
pub fn Term::is_ssa(self : Term[Sub]) -> Bool {
  self.has_attr(ssa_form_attr)
}

///|
pub fn Term::to_ssa(self : Term[Sub], entry? : Tid) -> Term[Sub] {
  if self.is_ssa() {
    self
  } else {
    let start = match entry {
      Some(tid) => Some(tid)
      None => self.entry_blk().map(term => term.tid())
    }
    match start {
      Some(tid) if self.find_blk(tid) is Some(_) =>
        self
        .ssa_insert_phi_nodes(tid)
        .ssa_rename(tid)
        .set_attr(Attr::new(key=ssa_form_attr, value="true"))
      _ => self.set_attr(Attr::new(key=ssa_form_attr, value="true"))
    }
  }
}
