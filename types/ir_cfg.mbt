///|
struct IrCfg {
  sub_value : Term[Sub]
}

///|
pub fn IrCfg::create(tid? : Tid, name? : String) -> IrCfg {
  IrCfg::of_sub(Sub::create(name?, tid?))
}

///|
pub fn IrCfg::of_sub(sub : Term[Sub]) -> IrCfg {
  { sub_value: sub }
}

///|
pub fn Term::to_ir_cfg(self : Term[Sub]) -> IrCfg {
  IrCfg::of_sub(self)
}

///|
pub fn Term::to_cfg(self : Term[Sub]) -> IrCfg {
  self.to_ir_cfg()
}

///|
pub fn Sub::to_cfg(sub : Term[Sub]) -> IrCfg {
  sub.to_ir_cfg()
}

///|
pub fn IrCfg::to_sub(self : IrCfg) -> Term[Sub] {
  self.sub_value
}

///|
pub fn Sub::of_cfg(cfg : IrCfg) -> Term[Sub] {
  cfg.to_sub()
}

///|
pub fn IrCfg::is_directed() -> Bool {
  true
}

///|
pub fn IrCfg::is_empty(self : IrCfg) -> Bool {
  self.sub_value.blks().is_empty()
}

///|
pub fn IrCfg::nodes(self : IrCfg) -> Array[Term[Blk]] {
  self.sub_value.blks()
}

///|
fn IrCfg::with_nodes(self : IrCfg, nodes : Array[Term[Blk]]) -> IrCfg {
  IrCfg::of_sub(
    self.sub_value.with_payload({ ..self.sub_value.payload_value, blks: nodes }),
  )
}

///|
fn ir_cfg_dummy_jmp() -> Term[Jmp] {
  let null = Int(Word::b0())
  Jmp::create_goto(Label::indirect(null), cond=null)
}

///|
fn ir_cfg_is_zero_exp(exp : Exp) -> Bool {
  match exp {
    Int(word) => word.is_zero()
    _ => false
  }
}

///|
fn ir_cfg_is_dummy_jmp(jmp : Term[Jmp]) -> Bool {
  ir_cfg_is_zero_exp(jmp.cond()) &&
  (match jmp.kind() {
    Goto(Indirect(exp)) => ir_cfg_is_zero_exp(exp)
    _ => false
  })
}

///|
fn Term::with_cfg_jmps(self : Term[Blk], jmps : Array[Term[Jmp]]) -> Term[Blk] {
  self.with_payload({ ..self.payload_value, jmps, })
}

///|
fn Term::replace_cfg_jmp(
  self : Term[Blk],
  pos : Int,
  jmp : Term[Jmp],
) -> Term[Blk] {
  let jmps = self.jmps()
  if pos >= 0 && pos < jmps.length() {
    jmps[pos] = jmp
    self.with_cfg_jmps(jmps)
  } else {
    self
  }
}

///|
fn Term::append_cfg_jmps(
  self : Term[Blk],
  jmps : Array[Term[Jmp]],
) -> Term[Blk] {
  let next = self.jmps()
  for jmp in jmps {
    next.push(jmp)
  }
  self.with_cfg_jmps(next)
}

///|
fn Term::cfg_edge_source_at(
  self : Term[Blk],
  dst : Term[Blk],
  pos : Int,
) -> Term[Blk] {
  let target = Jmp::create_goto(Label::direct(dst.tid()))
  let jmps = self.jmps()
  let actual_pos = Int::max(0, pos)
  if actual_pos < jmps.length() {
    match jmps[actual_pos].succ_tid_of_jmp() {
      Some(tid) if tid == dst.tid() => self
      _ => self.replace_cfg_jmp(actual_pos, target)
    }
  } else {
    let padding = []
    for _ in jmps.length()..<actual_pos {
      padding.push(ir_cfg_dummy_jmp())
    }
    padding.push(target)
    self.append_cfg_jmps(padding)
  }
}

///|
fn Term::remove_cfg_jmp_at(self : Term[Blk], pos : Int) -> Term[Blk] {
  let jmps = self.jmps()
  if pos < 0 || pos >= jmps.length() {
    self
  } else {
    jmps[pos] = ir_cfg_dummy_jmp()
    let mut stop = jmps.length()
    while stop > 0 && ir_cfg_is_dummy_jmp(jmps[stop - 1]) {
      stop = stop - 1
    }
    self.with_cfg_jmps(jmps[0:stop].to_owned())
  }
}

///|
pub fn IrCfg::edges(self : IrCfg) -> Array[IrCfgEdge] {
  self.sub_value.sub_edges()
}

///|
pub fn IrCfg::node_count(self : IrCfg) -> Int {
  self.sub_value.blks().length()
}

///|
pub fn IrCfg::number_of_nodes(self : IrCfg) -> Int {
  self.node_count()
}

///|
fn ir_cfg_contains_pair(
  pairs : ArrayView[(Tid, Tid)],
  pair : (Tid, Tid),
) -> Bool {
  pairs.any(item => item.0 == pair.0 && item.1 == pair.1)
}

///|
pub fn IrCfg::edge_count(self : IrCfg) -> Int {
  let pairs : Array[(Tid, Tid)] = []
  for edge in self.edges() {
    let pair = (edge.src().tid(), edge.dst().tid())
    if !ir_cfg_contains_pair(pairs, pair) {
      pairs.push(pair)
    }
  }
  pairs.length()
}

///|
pub fn IrCfg::number_of_edges(self : IrCfg) -> Int {
  self.edge_count()
}

///|
pub fn IrCfg::has_node(self : IrCfg, blk : Term[Blk]) -> Bool {
  self.sub_value.find_blk(blk.tid()) is Some(_)
}

///|
pub fn IrCfg::insert_node(self : IrCfg, blk : Term[Blk]) -> IrCfg {
  if self.has_node(blk) {
    self
  } else {
    IrCfg::of_sub(self.sub_value.append_blk(blk))
  }
}

///|
pub fn IrCfg::remove_node(self : IrCfg, blk : Term[Blk]) -> IrCfg {
  if self.has_node(blk) {
    self.with_nodes(
      self.sub_value.blks().filter(node => node.tid() != blk.tid()),
    )
  } else {
    self
  }
}

///|
pub fn IrCfg::update_node(
  self : IrCfg,
  old : Term[Blk],
  replacement : Term[Blk],
) -> IrCfg {
  if old.tid() != replacement.tid() || !self.has_node(old) {
    self
  } else {
    IrCfg::of_sub(self.sub_value.update_blk(replacement))
  }
}

///|
pub fn IrCfg::has_edge(self : IrCfg, src : Term[Blk], dst : Term[Blk]) -> Bool {
  self.edge(src, dst) is Some(_)
}

///|
pub fn IrCfg::insert_edge(
  self : IrCfg,
  src : Term[Blk],
  dst : Term[Blk],
  position? : Int = -1,
) -> IrCfg {
  let current_src = match self.sub_value.find_blk(src.tid()) {
    Some(block) => block
    None => src
  }
  let actual_position = if position < 0 {
    current_src.jmps().length()
  } else {
    position
  }
  let updated_src = current_src.cfg_edge_source_at(dst, actual_position)
  self
  .insert_node(dst)
  .insert_node(updated_src)
  .update_node(updated_src, updated_src)
}

///|
pub fn IrCfg::edge(
  self : IrCfg,
  src : Term[Blk],
  dst : Term[Blk],
) -> IrCfgEdge? {
  self.sub_value.sub_edge(src, dst)
}

///|
pub fn IrCfg::remove_edge(self : IrCfg, edge : IrCfgEdge) -> IrCfg {
  match self.sub_value.find_blk(edge.src().tid()) {
    Some(src) => {
      let updated_src = src.remove_cfg_jmp_at(edge.position())
      self.update_node(src, updated_src)
    }
    None => self
  }
}

///|
pub fn IrCfg::update_edge(
  self : IrCfg,
  edge : IrCfgEdge,
  position~ : Int,
) -> IrCfg {
  if !edge.mem(self) {
    self
  } else {
    match self.sub_value.find_blk(edge.src().tid()) {
      Some(src) => {
        let updated_src = src.cfg_edge_source_at(edge.dst(), position)
        self
        .insert_node(edge.dst())
        .insert_node(updated_src)
        .update_node(updated_src, updated_src)
      }
      None => self
    }
  }
}

///|
pub fn IrCfg::successors(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.out_edges(blk).map(edge => edge.dst())
}

///|
pub fn IrCfg::succs(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.successors(blk)
}

///|
pub fn IrCfg::predecessors(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.sub_value.sub_predecessor_blocks(blk)
}

///|
pub fn IrCfg::preds(self : IrCfg, blk : Term[Blk]) -> Array[Term[Blk]] {
  self.predecessors(blk)
}

///|
pub fn IrCfg::out_edges(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.sub_value.sub_out_edges(blk)
}

///|
pub fn IrCfg::outputs(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.out_edges(blk)
}

///|
pub fn IrCfg::in_edges(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.sub_value.sub_in_edges(blk)
}

///|
pub fn IrCfg::inputs(self : IrCfg, blk : Term[Blk]) -> Array[IrCfgEdge] {
  self.in_edges(blk)
}

///|
pub fn IrCfg::out_degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.out_edges(blk).length()
}

///|
pub fn IrCfg::in_degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.in_edges(blk).length()
}

///|
pub fn IrCfg::degree(self : IrCfg, blk : Term[Blk]) -> Int {
  self.in_degree(blk) + self.out_degree(blk)
}

///|
fn ir_cfg_dot_escape(text : String) -> String {
  let builder = StringBuilder()
  for i in 0..<text.char_length() {
    match text.get_char(i) {
      Some(char) =>
        match char.to_int() {
          10 => builder.write_string("\\l")
          34 => builder.write_string("\\\"")
          92 => builder.write_string("\\\\")
          _ => builder.write_char(char)
        }
      None => ()
    }
  }
  builder.to_string()
}

///|
fn ir_cfg_dot_quote(text : String) -> String {
  "\"\{ir_cfg_dot_escape(text)}\""
}

///|
fn ir_cfg_dot_join_lines(lines : Array[String]) -> String {
  let builder = StringBuilder()
  for i, line in lines {
    if i > 0 {
      builder.write_string("\n")
    }
    builder.write_string(line)
  }
  builder.to_string()
}

///|
fn ir_cfg_dot_def_label(def : Term[Def]) -> String {
  def.def_to_string()
}

///|
fn ir_cfg_dot_phi_label(phi : Term[Phi]) -> String {
  phi.phi_to_string()
}

///|
fn ir_cfg_dot_jmp_label(jmp : Term[Jmp]) -> String {
  jmp.jmp_to_string()
}

///|
fn ir_cfg_dot_show_jmp(jmp : Term[Jmp]) -> Bool {
  match jmp.kind() {
    Goto(_) => jmp.succ_tid_of_jmp() is None
    JmpCall(_) | Ret(_) | Interrupt(_) => true
  }
}

///|
fn ir_cfg_dot_node_label(blk : Term[Blk]) -> String {
  let lines : Array[String] = [blk.name()]
  for phi in blk.phis() {
    lines.push(ir_cfg_dot_phi_label(phi))
  }
  for def in blk.defs() {
    lines.push(ir_cfg_dot_def_label(def))
  }
  for jmp in blk.jmps() {
    if ir_cfg_dot_show_jmp(jmp) {
      lines.push(ir_cfg_dot_jmp_label(jmp))
    }
  }
  ir_cfg_dot_join_lines(lines)
}

///|
fn ir_cfg_dot_edge_label(edge : IrCfgEdge, sub : Term[Sub]) -> String {
  match edge.cond(sub) {
    Int(word) if word.is_one() => ""
    exp => exp.to_string()
  }
}

///|
pub fn IrCfg::to_dot(self : IrCfg) -> String {
  let sub = self.sub_value
  let builder = StringBuilder()
  builder.write_string("digraph ")
  builder.write_string(ir_cfg_dot_quote(sub.sub_name()))
  builder.write_string(" {\n")
  builder.write_string("  node[shape=box];\n")
  for blk in self.nodes() {
    builder.write_string("  ")
    builder.write_string(ir_cfg_dot_quote(blk.name()))
    builder.write_string(" [label=")
    builder.write_string(ir_cfg_dot_quote(ir_cfg_dot_node_label(blk)))
    builder.write_string("];\n")
  }
  for edge in self.edges() {
    builder.write_string("  ")
    builder.write_string(ir_cfg_dot_quote(edge.src().name()))
    builder.write_string(" -> ")
    builder.write_string(ir_cfg_dot_quote(edge.dst().name()))
    let label = ir_cfg_dot_edge_label(edge, sub)
    if label == "" {
      builder.write_string(";\n")
    } else {
      builder.write_string(" [label=")
      builder.write_string(ir_cfg_dot_quote(label))
      builder.write_string("];\n")
    }
  }
  builder.write_string("}\n")
  builder.to_string()
}

///|
pub fn IrCfg::to_string(self : IrCfg) -> String {
  self.to_dot()
}
