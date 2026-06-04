///|
let ir_address_attr = "address"

///|
pub fn Attr::address(addr : Word) -> Attr {
  Attr::new(key=ir_address_attr, value=addr.to_string())
}

///|
fn parse_ir_address_text(width : Int, text : String) -> Word? {
  if text == "true" || text == "false" || text.split_once(":") is Some(_) {
    try Word::from_string(text) catch {
      _ => None
    } noraise {
      word => Some(word)
    }
  } else {
    let value : Int64 = try @string.from_str(text) catch {
      _ => return None
    } noraise {
      value => value
    }
    try Word::of_int64(value, width~) catch {
      _ => None
    } noraise {
      word => Some(word)
    }
  }
}

///|
pub fn IrTerm::has_address(self : IrTerm, addr : Word) -> Bool {
  match self.get_attr(ir_address_attr) {
    Some(text) =>
      match parse_ir_address_text(addr.bitwidth(), text) {
        Some(actual) => actual == addr
        None => false
      }
    None => false
  }
}

///|
pub fn IrTerm::has_address_text(self : IrTerm, text : String) -> Bool {
  match self.get_attr(ir_address_attr) {
    Some(actual_text) =>
      match parse_ir_address_text(64, actual_text) {
        Some(actual) =>
          match parse_ir_address_text(actual.bitwidth(), text) {
            Some(expected) => actual == expected
            None => false
          }
        None => false
      }
    None => false
  }
}

///|
pub fn IrTerm::same_term(self : IrTerm, other : IrTerm) -> Bool {
  self.class() == other.class() && self.tid() == other.tid()
}

///|
pub fn IrTerm::same(self : IrTerm, other : IrTerm) -> Bool {
  self.same_term(other)
}

///|
pub fn IrTerm::has_class(self : IrTerm, cls : IrTermClass) -> Bool {
  self.class() == cls
}

///|
pub fn IrTerm::has_name(self : IrTerm, name : String) -> Bool {
  self.name() == name
}

///|
pub fn IrTerm::has_tid(self : IrTerm, tid : Tid) -> Bool {
  self.tid() == tid
}

///|
pub fn IrTerm::has_tid_text(self : IrTerm, text : String) -> Bool {
  self.tid().to_string() == text
}

///|
pub fn IrTerm::has_attr_value(
  self : IrTerm,
  key : String,
  value : String,
) -> Bool {
  self.get_attr(key) == Some(value)
}

///|
fn ir_term_color(term : IrTerm, key : String) -> IrColor? {
  match term.get_attr(key) {
    Some(text) => IrColor::of_string(text)
    None => None
  }
}

///|
pub fn IrTerm::color(self : IrTerm) -> IrColor? {
  ir_term_color(self, term_color_attr)
}

///|
pub fn IrTerm::has_color(self : IrTerm, color : IrColor) -> Bool {
  self.color() == Some(color)
}

///|
pub fn IrTerm::set_color(self : IrTerm, color : IrColor) -> IrTerm {
  self.set_attr(Attr::color(color))
}

///|
pub fn IrTerm::del_color(self : IrTerm) -> IrTerm {
  self.del_attr(term_color_attr)
}

///|
pub fn IrTerm::foreground(self : IrTerm) -> IrColor? {
  ir_term_color(self, term_foreground_attr)
}

///|
pub fn IrTerm::has_foreground(self : IrTerm, color : IrColor) -> Bool {
  self.foreground() == Some(color)
}

///|
pub fn IrTerm::set_foreground(self : IrTerm, color : IrColor) -> IrTerm {
  self.set_attr(Attr::foreground(color))
}

///|
pub fn IrTerm::del_foreground(self : IrTerm) -> IrTerm {
  self.del_attr(term_foreground_attr)
}

///|
pub fn IrTerm::background(self : IrTerm) -> IrColor? {
  ir_term_color(self, term_background_attr)
}

///|
pub fn IrTerm::has_background(self : IrTerm, color : IrColor) -> Bool {
  self.background() == Some(color)
}

///|
pub fn IrTerm::set_background(self : IrTerm, color : IrColor) -> IrTerm {
  self.set_attr(Attr::background(color))
}

///|
pub fn IrTerm::del_background(self : IrTerm) -> IrTerm {
  self.del_attr(term_background_attr)
}

///|
pub fn IrTerm::is_synthetic(self : IrTerm) -> Bool {
  self.has_attr(term_synthetic_attr)
}

///|
pub fn IrTerm::is_visited(self : IrTerm) -> Bool {
  self.has_attr(term_visited_attr)
}

///|
pub fn IrTerm::is_live(self : IrTerm) -> Bool {
  self.has_attr(term_live_attr)
}

///|
pub fn IrTerm::is_dead(self : IrTerm) -> Bool {
  self.has_attr(term_dead_attr)
}

///|
pub fn IrTerm::has_mark(self : IrTerm) -> Bool {
  self.has_attr(term_mark_attr)
}

///|
pub fn IrTerm::mark_value(self : IrTerm) -> String? {
  self.get_attr(term_mark_attr)
}

///|
pub fn IrTerm::set_mark(self : IrTerm, value? : String = "true") -> IrTerm {
  self.set_attr(Attr::mark(value~))
}

///|
pub fn IrTerm::del_mark(self : IrTerm) -> IrTerm {
  self.del_attr(term_mark_attr)
}

///|
pub fn IrTerm::children(self : IrTerm) -> Array[IrTerm] {
  match self {
    ProgramTerm(term) => [ for sub in term.subs() => SubTerm(sub) ]
    SubTerm(term) => {
      let result = []
      for arg in term.args() {
        result.push(ArgTerm(arg))
      }
      for blk in term.blks() {
        result.push(BlkTerm(blk))
      }
      result
    }
    BlkTerm(term) => {
      let result = []
      for phi in term.phis() {
        result.push(PhiTerm(phi))
      }
      for def in term.defs() {
        result.push(DefTerm(def))
      }
      for jmp in term.jmps() {
        result.push(JmpTerm(jmp))
      }
      result
    }
    ArgTerm(_) | PhiTerm(_) | DefTerm(_) | JmpTerm(_) => []
  }
}

///|
pub fn IrTerm::has_child_tid(self : IrTerm, tid : Tid) -> Bool {
  self.children().any(child => child.tid() == tid)
}

///|
pub fn IrTerm::children_of_class(
  self : IrTerm,
  cls : IrTermClass,
  rev? : Bool = false,
) -> Array[IrTerm] {
  let children = self.children().filter(child => child.class() == cls)
  if rev {
    children.rev()
  } else {
    children
  }
}

///|
pub fn IrTerm::find_child(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  for child in self.children_of_class(cls) {
    if child.tid() == tid {
      return Some(child)
    }
  }
  None
}

///|
pub fn IrTerm::child_count(self : IrTerm, cls : IrTermClass) -> Int {
  self.children_of_class(cls).length()
}

///|
pub fn IrTerm::nth_child(
  self : IrTerm,
  cls : IrTermClass,
  index : Int,
) -> IrTerm? {
  let children = self.children_of_class(cls)
  if index >= 0 && index < children.length() {
    Some(children[index])
  } else {
    None
  }
}

///|
pub fn IrTerm::first_child(self : IrTerm, cls : IrTermClass) -> IrTerm? {
  self.nth_child(cls, 0)
}

///|
pub fn IrTerm::last_child(self : IrTerm, cls : IrTermClass) -> IrTerm? {
  self.nth_child(cls, self.child_count(cls) - 1)
}

///|
fn ir_child_index(children : Array[IrTerm], tid : Tid) -> Int? {
  children.search_by(child => child.tid() == tid)
}

///|
pub fn IrTerm::next_child(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  let children = self.children_of_class(cls)
  match ir_child_index(children, tid) {
    Some(i) if i + 1 < children.length() => Some(children[i + 1])
    _ => None
  }
}

///|
pub fn IrTerm::prev_child(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm? {
  let children = self.children_of_class(cls)
  match ir_child_index(children, tid) {
    Some(i) if i > 0 => Some(children[i - 1])
    _ => None
  }
}

///|
fn ir_child_range(
  children : Array[IrTerm],
  start : Int,
  stop : Int,
  rev : Bool,
) -> Array[IrTerm] {
  let out = []
  let start = if start < 0 { 0 } else { start }
  let stop = if stop > children.length() { children.length() } else { stop }
  if start < stop {
    for i in start..<stop {
      out.push(children[i])
    }
  }
  if rev {
    out.rev()
  } else {
    out
  }
}

///|
pub fn IrTerm::children_after(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  rev? : Bool = false,
) -> Array[IrTerm] {
  let children = self.children_of_class(cls)
  match ir_child_index(children, tid) {
    Some(i) => ir_child_range(children, i + 1, children.length(), rev)
    None => []
  }
}

///|
pub fn IrTerm::children_before(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  rev? : Bool = false,
) -> Array[IrTerm] {
  let children = self.children_of_class(cls)
  match ir_child_index(children, tid) {
    Some(i) => ir_child_range(children, 0, i, rev)
    None => []
  }
}

///|
fn change_sub_child(
  current : Term[Sub]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Sub]? {
  let current_ir = match current {
    Some(term) => Some(SubTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(SubTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
fn change_arg_child(
  current : Term[Arg]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Arg]? {
  let current_ir = match current {
    Some(term) => Some(ArgTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(ArgTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
fn change_blk_child(
  current : Term[Blk]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Blk]? {
  let current_ir = match current {
    Some(term) => Some(BlkTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(BlkTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
fn change_phi_child(
  current : Term[Phi]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Phi]? {
  let current_ir = match current {
    Some(term) => Some(PhiTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(PhiTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
fn change_def_child(
  current : Term[Def]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Def]? {
  let current_ir = match current {
    Some(term) => Some(DefTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(DefTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
fn change_jmp_child(
  current : Term[Jmp]?,
  f : (IrTerm?) -> IrTerm?,
) -> Term[Jmp]? {
  let current_ir = match current {
    Some(term) => Some(JmpTerm(term))
    None => None
  }
  match f(current_ir) {
    Some(JmpTerm(term)) => Some(term)
    Some(_) => current
    None => None
  }
}

///|
pub fn IrTerm::change_child(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  f : (IrTerm?) -> IrTerm?,
) -> IrTerm {
  match (self, cls) {
    (ProgramTerm(term), SubTermClass) =>
      ProgramTerm(term.change_sub(tid, current => change_sub_child(current, f)))
    (SubTerm(term), ArgTermClass) =>
      SubTerm(term.change_arg(tid, current => change_arg_child(current, f)))
    (SubTerm(term), BlkTermClass) =>
      SubTerm(term.change_blk(tid, current => change_blk_child(current, f)))
    (BlkTerm(term), PhiTermClass) =>
      BlkTerm(
        term.change_phi_term(tid, current => change_phi_child(current, f)),
      )
    (BlkTerm(term), DefTermClass) =>
      BlkTerm(term.change_def(tid, current => change_def_child(current, f)))
    (BlkTerm(term), JmpTermClass) =>
      BlkTerm(term.change_jmp(tid, current => change_jmp_child(current, f)))
    _ => self
  }
}

///|
pub fn IrTerm::update_child(self : IrTerm, child : IrTerm) -> IrTerm {
  self.change_child(child.class(), child.tid(), _ => Some(child))
}

///|
pub fn IrTerm::remove_child(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
) -> IrTerm {
  self.change_child(cls, tid, _ => None)
}

///|
pub fn IrTerm::append_child(
  self : IrTerm,
  child : IrTerm,
  after? : Tid,
) -> IrTerm {
  match (self, child) {
    (ProgramTerm(term), SubTerm(child)) =>
      ProgramTerm(term.insert_sub_after(child, after?))
    (SubTerm(term), ArgTerm(child)) =>
      SubTerm(term.insert_arg_after(child, after?))
    (SubTerm(term), BlkTerm(child)) =>
      SubTerm(term.insert_blk_after(child, after?))
    (BlkTerm(term), PhiTerm(child)) =>
      BlkTerm(term.insert_phi_after(child, after?))
    (BlkTerm(term), DefTerm(child)) =>
      BlkTerm(term.insert_def_after(child, after?))
    (BlkTerm(term), JmpTerm(child)) =>
      BlkTerm(term.insert_jmp_after(child, after?))
    _ => self
  }
}

///|
pub fn IrTerm::prepend_child(
  self : IrTerm,
  child : IrTerm,
  before? : Tid,
) -> IrTerm {
  match (self, child) {
    (ProgramTerm(term), SubTerm(child)) =>
      ProgramTerm(term.insert_sub_before(child, before?))
    (SubTerm(term), ArgTerm(child)) =>
      SubTerm(term.insert_arg_before(child, before?))
    (SubTerm(term), BlkTerm(child)) =>
      SubTerm(term.insert_blk_before(child, before?))
    (BlkTerm(term), PhiTerm(child)) =>
      BlkTerm(term.insert_phi_before(child, before?))
    (BlkTerm(term), DefTerm(child)) =>
      BlkTerm(term.insert_def_before(child, before?))
    (BlkTerm(term), JmpTerm(child)) =>
      BlkTerm(term.insert_jmp_before(child, before?))
    _ => self
  }
}

///|
pub fn IrTerm::map_children(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> IrTerm,
) -> IrTerm {
  let mut result = self
  for child in self.children_of_class(cls) {
    result = result.change_child(cls, child.tid(), current => {
      match current {
        Some(term) => Some(f(term))
        None => None
      }
    })
  }
  result
}

///|
pub fn IrTerm::filter_map_children(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> IrTerm?,
) -> IrTerm {
  let mut result = self
  for child in self.children_of_class(cls) {
    result = result.change_child(cls, child.tid(), current => {
      match current {
        Some(term) => f(term)
        None => None
      }
    })
  }
  result
}

///|
pub fn IrTerm::filter_children(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> Bool,
) -> IrTerm {
  self.filter_map_children(cls, child => {
    if f(child) {
      Some(child)
    } else {
      None
    }
  })
}

///|
fn collect_sub_terms(items : Array[IrTerm]) -> Array[Term[Sub]] {
  [
    for item in items if item is SubTerm(term) => term
  ]
}

///|
fn collect_arg_terms(items : Array[IrTerm]) -> Array[Term[Arg]] {
  [
    for item in items if item is ArgTerm(term) => term
  ]
}

///|
fn collect_blk_terms(items : Array[IrTerm]) -> Array[Term[Blk]] {
  [
    for item in items if item is BlkTerm(term) => term
  ]
}

///|
fn collect_phi_terms(items : Array[IrTerm]) -> Array[Term[Phi]] {
  [
    for item in items if item is PhiTerm(term) => term
  ]
}

///|
fn collect_def_terms(items : Array[IrTerm]) -> Array[Term[Def]] {
  [
    for item in items if item is DefTerm(term) => term
  ]
}

///|
fn collect_jmp_terms(items : Array[IrTerm]) -> Array[Term[Jmp]] {
  [
    for item in items if item is JmpTerm(term) => term
  ]
}

///|
pub fn IrTerm::concat_map_children(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> Array[IrTerm],
) -> IrTerm {
  match (self, cls) {
    (ProgramTerm(term), SubTermClass) =>
      ProgramTerm(
        term.concat_map_subs(child => collect_sub_terms(f(SubTerm(child)))),
      )
    (SubTerm(term), ArgTermClass) =>
      SubTerm(
        term.concat_map_args(child => collect_arg_terms(f(ArgTerm(child)))),
      )
    (SubTerm(term), BlkTermClass) =>
      SubTerm(
        term.concat_map_blks(child => collect_blk_terms(f(BlkTerm(child)))),
      )
    (BlkTerm(term), PhiTermClass) =>
      BlkTerm(
        term.concat_map_phis(child => collect_phi_terms(f(PhiTerm(child)))),
      )
    (BlkTerm(term), DefTermClass) =>
      BlkTerm(
        term.concat_map_defs(child => collect_def_terms(f(DefTerm(child)))),
      )
    (BlkTerm(term), JmpTermClass) =>
      BlkTerm(
        term.concat_map_jmps(child => collect_jmp_terms(f(JmpTerm(child)))),
      )
    _ => self
  }
}

///|
pub fn IrTerm::to_sequence(
  self : IrTerm,
  cls : IrTermClass,
  rev? : Bool = false,
) -> Array[IrTerm] {
  self.children_of_class(cls, rev~)
}

///|
pub fn IrTerm::find(self : IrTerm, cls : IrTermClass, tid : Tid) -> IrTerm? {
  self.find_child(cls, tid)
}

///|
pub fn IrTerm::update(self : IrTerm, child : IrTerm) -> IrTerm {
  self.update_child(child)
}

///|
pub fn IrTerm::remove(self : IrTerm, cls : IrTermClass, tid : Tid) -> IrTerm {
  self.remove_child(cls, tid)
}

///|
pub fn IrTerm::change(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  f : (IrTerm?) -> IrTerm?,
) -> IrTerm {
  self.change_child(cls, tid, f)
}

///|
pub fn IrTerm::length(self : IrTerm, cls : IrTermClass) -> Int {
  self.child_count(cls)
}

///|
pub fn IrTerm::nth(self : IrTerm, cls : IrTermClass, index : Int) -> IrTerm? {
  self.nth_child(cls, index)
}

///|
pub fn IrTerm::first(self : IrTerm, cls : IrTermClass) -> IrTerm? {
  self.first_child(cls)
}

///|
pub fn IrTerm::last(self : IrTerm, cls : IrTermClass) -> IrTerm? {
  self.last_child(cls)
}

///|
pub fn IrTerm::next(self : IrTerm, cls : IrTermClass, tid : Tid) -> IrTerm? {
  self.next_child(cls, tid)
}

///|
pub fn IrTerm::prev(self : IrTerm, cls : IrTermClass, tid : Tid) -> IrTerm? {
  self.prev_child(cls, tid)
}

///|
pub fn IrTerm::after(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  rev? : Bool = false,
) -> Array[IrTerm] {
  self.children_after(cls, tid, rev~)
}

///|
pub fn IrTerm::before(
  self : IrTerm,
  cls : IrTermClass,
  tid : Tid,
  rev? : Bool = false,
) -> Array[IrTerm] {
  self.children_before(cls, tid, rev~)
}

///|
pub fn IrTerm::append(self : IrTerm, child : IrTerm, after? : Tid) -> IrTerm {
  self.append_child(child, after?)
}

///|
pub fn IrTerm::prepend(self : IrTerm, child : IrTerm, before? : Tid) -> IrTerm {
  self.prepend_child(child, before?)
}

///|
pub fn IrTerm::filter_map(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> IrTerm?,
) -> IrTerm {
  self.filter_map_children(cls, f)
}

///|
pub fn IrTerm::filter(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> Bool,
) -> IrTerm {
  self.filter_children(cls, f)
}

///|
pub fn IrTerm::concat_map(
  self : IrTerm,
  cls : IrTermClass,
  f : (IrTerm) -> Array[IrTerm],
) -> IrTerm {
  self.concat_map_children(cls, f)
}

///|
pub fn IrTerm::free_vars(self : IrTerm) -> Array[Var] {
  match self {
    ProgramTerm(term) => term.program_free_vars()
    SubTerm(term) => term.sub_free_vars()
    ArgTerm(term) => term.arg_free_vars()
    BlkTerm(term) => term.blk_free_vars()
    PhiTerm(term) => term.phi_free_vars()
    DefTerm(term) => term.def_free_vars()
    JmpTerm(term) => term.jmp_free_vars()
  }
}

///|
pub fn IrTerm::uses_var(self : IrTerm, variable : Var) -> Bool {
  self.free_vars().any(item => item == variable)
}

///|
pub fn IrTerm::uses_var_name(self : IrTerm, name : String) -> Bool {
  self.free_vars().any(item => item.name() == name)
}

///|
pub fn IrTerm::defined_vars(self : IrTerm) -> Array[Var] {
  let vars = []
  match self {
    ProgramTerm(term) =>
      for sub in term.subs() {
        add_vars(vars, SubTerm(sub).defined_vars())
      }
    SubTerm(term) => {
      for arg in term.args() {
        add_var(vars, arg.arg_lhs())
      }
      for blk in term.blks() {
        add_vars(vars, BlkTerm(blk).defined_vars())
      }
    }
    ArgTerm(term) => add_var(vars, term.arg_lhs())
    BlkTerm(term) => add_vars(vars, term.blk_defined_vars())
    PhiTerm(term) => add_var(vars, term.phi_lhs())
    DefTerm(term) => add_var(vars, term.lhs())
    JmpTerm(_) => ()
  }
  vars
}

///|
pub fn IrTerm::defines_var(self : IrTerm, variable : Var) -> Bool {
  self.defined_vars().any(item => item == variable)
}

///|
pub fn IrTerm::defines_var_name(self : IrTerm, name : String) -> Bool {
  self.defined_vars().any(item => item.name() == name)
}

///|
pub fn IrTerm::def_lhs_name(self : IrTerm, name : String) -> Bool {
  match self {
    DefTerm(term) => term.lhs().name() == name
    _ => false
  }
}

///|
pub fn IrTerm::def_uses_name(self : IrTerm, name : String) -> Bool {
  match self {
    DefTerm(term) => term.def_free_vars().any(item => item.name() == name)
    _ => false
  }
}

///|
pub fn Term::sub_parent_is(
  self : Term[Sub],
  parent : IrTerm,
  child : Tid,
) -> Bool {
  match self.sub_parent_term(child) {
    Some(actual) => actual.same_term(parent)
    None => false
  }
}

///|
pub fn Term::program_parent_is(
  self : Term[Program],
  parent : IrTerm,
  child : Tid,
) -> Bool {
  match self.program_parent_term(child) {
    Some(actual) => actual.same_term(parent)
    None => false
  }
}
