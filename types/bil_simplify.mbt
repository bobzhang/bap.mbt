///|
fn fold_unop(op : UnOp, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match eval_unop(op, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn word_is_one(word : Word) -> Bool {
  try word.to_uint64() catch {
    _ => false
  } noraise {
    value => value == 1UL
  }
}

///|
fn fold_binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp? {
  match (lhs, rhs) {
    (Int(left), Int(right)) =>
      match eval_binop(op, left, right) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    (exp, Int(word)) if word.is_zero() =>
      match op {
        Plus | Minus | Or | Xor | LShift | RShift | ARShift => Some(exp)
        _ => None
      }
    (Int(word), exp) if word.is_zero() =>
      match op {
        Plus | Or | Xor => Some(exp)
        _ => None
      }
    (exp, Int(word)) if word_is_one(word) =>
      match op {
        Times => Some(exp)
        _ => None
      }
    (Int(word), exp) if word_is_one(word) =>
      match op {
        Times => Some(exp)
        _ => None
      }
    _ => None
  }
}

///|
fn fold_cast(typ : ValueType, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match cast_word(typ, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn fold_store_chain(
  mem : Exp,
  memory : BilMemory,
) -> Result[(BilMemory, Bool), String] {
  match mem {
    Store(mem=base, addr=Int(addr), value=Int(value), endian~) =>
      match fold_store_chain(base, memory) {
        Ok((base_memory, _)) =>
          match base_memory.store(addr, value, endian~) {
            Ok(stored) => Ok((stored, true))
            Err(reason) => Err(reason)
          }
        Err(reason) => Err(reason)
      }
    _ => Ok((memory, false))
  }
}

///|
fn fold_load(
  mem : Exp,
  addr : Exp,
  endian : @bitvec.Endian,
  typ : ValueType,
) -> Exp? {
  match (addr, typ) {
    (Int(load_addr), Imm(width)) => {
      let memory = BilMemory::empty(addr_width=load_addr.width())
      match fold_store_chain(mem, memory) {
        Ok((stored, true)) =>
          match stored.load(load_addr, endian~, width~) {
            Ok(word) => Some(Int(word))
            Err(_) => None
          }
        Ok((_, false)) | Err(_) => None
      }
    }
    _ => None
  }
}

///|
fn is_constant_exp(exp : Exp) -> Bool {
  match exp {
    Int(_) | Unknown(_) => true
    _ => false
  }
}

///|
fn Exp::normalize_negative_binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp {
  match (op, rhs) {
    (Plus, Int(word)) if word.signed().is_negative() =>
      BinOp(Minus, lhs, Int(word.signed().abs()))
    _ => BinOp(op, lhs, rhs)
  }
}

///|
pub fn Exp::normalize_negatives(self : Exp) -> Exp {
  match self {
    Int(_) | Var(_) | Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) =>
      Load(
        mem=mem.normalize_negatives(),
        addr=addr.normalize_negatives(),
        endian~,
        typ~,
      )
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.normalize_negatives(),
        addr=addr.normalize_negatives(),
        value=value.normalize_negatives(),
        endian~,
      )
    Let(variable, value, body) =>
      Let(variable, value.normalize_negatives(), body.normalize_negatives())
    Cast(typ, exp) => Cast(typ, exp.normalize_negatives())
    UnOp(op, exp) => UnOp(op, exp.normalize_negatives())
    BinOp(op, lhs, rhs) =>
      Exp::normalize_negative_binop(
        op,
        lhs.normalize_negatives(),
        rhs.normalize_negatives(),
      )
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=cond.normalize_negatives(),
        yes=yes.normalize_negatives(),
        no=no.normalize_negatives(),
      )
  }
}

///|
pub fn Exp::fold_consts(self : Exp) -> Exp {
  self.simplify()
}

///|
pub fn Exp::normalize(self : Exp) -> Exp {
  self.normalize_negatives()
}

///|
fn Exp::first_ite_cond(self : Exp) -> Exp? {
  match self {
    Ite(cond~, ..) => Some(cond)
    Load(mem~, addr~, ..) =>
      match mem.first_ite_cond() {
        Some(cond) => Some(cond)
        None => addr.first_ite_cond()
      }
    Store(mem~, addr~, value~, ..) =>
      match mem.first_ite_cond() {
        Some(cond) => Some(cond)
        None =>
          match addr.first_ite_cond() {
            Some(cond) => Some(cond)
            None => value.first_ite_cond()
          }
      }
    Let(_, value, body) =>
      match value.first_ite_cond() {
        Some(cond) => Some(cond)
        None => body.first_ite_cond()
      }
    Cast(_, exp) | UnOp(_, exp) => exp.first_ite_cond()
    BinOp(_, lhs, rhs) =>
      match lhs.first_ite_cond() {
        Some(cond) => Some(cond)
        None => rhs.first_ite_cond()
      }
    Int(_) | Var(_) | Unknown(_) => None
  }
}

///|
fn Exp::assume_ite(self : Exp, target : Exp, take_yes : Bool) -> Exp {
  match self {
    Ite(cond~, yes~, no~) if cond == target =>
      if take_yes {
        yes.assume_ite(target, take_yes)
      } else {
        no.assume_ite(target, take_yes)
      }
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=cond.assume_ite(target, take_yes),
        yes=yes.assume_ite(target, take_yes),
        no=no.assume_ite(target, take_yes),
      )
    Load(mem~, addr~, endian~, typ~) =>
      Load(
        mem=mem.assume_ite(target, take_yes),
        addr=addr.assume_ite(target, take_yes),
        endian~,
        typ~,
      )
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.assume_ite(target, take_yes),
        addr=addr.assume_ite(target, take_yes),
        value=value.assume_ite(target, take_yes),
        endian~,
      )
    Let(variable, value, body) =>
      Let(
        variable,
        value.assume_ite(target, take_yes),
        body.assume_ite(target, take_yes),
      )
    Cast(typ, exp) => Cast(typ, exp.assume_ite(target, take_yes))
    UnOp(op, exp) => UnOp(op, exp.assume_ite(target, take_yes))
    BinOp(op, lhs, rhs) =>
      BinOp(
        op,
        lhs.assume_ite(target, take_yes),
        rhs.assume_ite(target, take_yes),
      )
    Int(_) | Var(_) | Unknown(_) => self
  }
}

///|
pub fn Exp::fixpoint(self : Exp, step : (Exp) -> Exp) -> Exp {
  let mut current = self
  let mut next = step(current)
  while next != current {
    current = next
    next = step(current)
  }
  current
}

///|
pub fn Exp::simplify(self : Exp) -> Exp {
  match self {
    Int(_) | Var(_) | Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) => {
      let simple_mem = mem.simplify()
      let simple_addr = addr.simplify()
      match fold_load(simple_mem, simple_addr, endian, typ) {
        Some(exp) => exp
        None => Load(mem=simple_mem, addr=simple_addr, endian~, typ~)
      }
    }
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.simplify(),
        addr=addr.simplify(),
        value=value.simplify(),
        endian~,
      )
    Let(variable, value, body) => {
      let simple_value = value.simplify()
      let simple_body = body.simplify()
      if is_constant_exp(simple_value) {
        simple_body.substitute_var(variable, simple_value).simplify()
      } else {
        Let(variable, simple_value, simple_body)
      }
    }
    Cast(typ, exp) => {
      let simple = exp.simplify()
      match fold_cast(typ, simple) {
        Some(result) => result
        None => Cast(typ, simple)
      }
    }
    UnOp(op, exp) => {
      let simple = exp.simplify()
      match fold_unop(op, simple) {
        Some(result) => result
        None => UnOp(op, simple)
      }
    }
    BinOp(op, lhs, rhs) => {
      let left = lhs.simplify()
      let right = rhs.simplify()
      match fold_binop(op, left, right) {
        Some(result) => result
        None => BinOp(op, left, right)
      }
    }
    Ite(cond~, yes~, no~) => {
      let simple_cond = cond.simplify()
      let simple_yes = yes.simplify()
      let simple_no = no.simplify()
      match simple_cond {
        Int(word) => if word.is_zero() { simple_no } else { simple_yes }
        _ =>
          if simple_yes == simple_no {
            simple_yes
          } else {
            Ite(cond=simple_cond, yes=simple_yes, no=simple_no)
          }
      }
    }
  }
}

///|
pub fn Stmt::simplify(self : Stmt) -> Stmt {
  match self {
    Move(variable, exp) => Move(variable, exp.simplify())
    Jmp(exp) => Jmp(exp.simplify())
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(cond=cond.simplify(), yes=simplify_stmts(yes), no=simplify_stmts(no))
    While(cond~, body~) =>
      While(cond=cond.simplify(), body=simplify_stmts(body))
  }
}

///|
pub fn Stmt::normalize_negatives(self : Stmt) -> Stmt {
  match self {
    Move(variable, exp) => Move(variable, exp.normalize_negatives())
    Jmp(exp) => Jmp(exp.normalize_negatives())
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(
        cond=cond.normalize_negatives(),
        yes=normalize_negatives(yes),
        no=normalize_negatives(no),
      )
    While(cond~, body~) =>
      While(cond=cond.normalize_negatives(), body=normalize_negatives(body))
  }
}

///|
pub fn Stmt::fold_consts(self : Stmt) -> Stmt {
  self.simplify()
}

///|
fn normalize_exp_if(exp : Exp, normalize_exp : Bool) -> Exp {
  if normalize_exp {
    exp.normalize()
  } else {
    exp
  }
}

///|
fn Stmt::first_ite_cond(self : Stmt) -> Exp? {
  match self {
    Move(_, exp) | Jmp(exp) => exp.first_ite_cond()
    Special(_) | CpuExn(_) | If(_) | While(_) => None
  }
}

///|
fn Stmt::assume_ite(self : Stmt, target : Exp, take_yes : Bool) -> Stmt {
  match self {
    Move(variable, exp) => Move(variable, exp.assume_ite(target, take_yes))
    Jmp(exp) => Jmp(exp.assume_ite(target, take_yes))
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(
        cond=cond.assume_ite(target, take_yes),
        yes=yes.map(stmt => stmt.assume_ite(target, take_yes)),
        no=no.map(stmt => stmt.assume_ite(target, take_yes)),
      )
    While(cond~, body~) =>
      While(
        cond=cond.assume_ite(target, take_yes),
        body=body.map(stmt => stmt.assume_ite(target, take_yes)),
      )
  }
}

///|
fn Stmt::split_ite(self : Stmt, normalize_exp : Bool) -> Array[Stmt] {
  match self.first_ite_cond() {
    Some(cond) =>
      normalize(
        [
          If(cond~, yes=[self.assume_ite(cond, true)], no=[
            self.assume_ite(cond, false),
          ]),
        ],
        normalize_exp~,
      )
    None => [self]
  }
}

///|
fn Exp::find_non_var_load_mem(self : Exp) -> Exp? {
  match self {
    Load(mem=Var(_), addr~, ..) => addr.find_non_var_load_mem()
    Load(mem~, ..) => Some(mem)
    Store(mem~, addr~, value~, ..) =>
      match mem.find_non_var_load_mem() {
        Some(exp) => Some(exp)
        None =>
          match addr.find_non_var_load_mem() {
            Some(exp) => Some(exp)
            None => value.find_non_var_load_mem()
          }
      }
    Let(_, value, body) =>
      match value.find_non_var_load_mem() {
        Some(exp) => Some(exp)
        None => body.find_non_var_load_mem()
      }
    Cast(_, exp) | UnOp(_, exp) => exp.find_non_var_load_mem()
    BinOp(_, lhs, rhs) =>
      match lhs.find_non_var_load_mem() {
        Some(exp) => Some(exp)
        None => rhs.find_non_var_load_mem()
      }
    Ite(cond~, yes~, no~) =>
      match cond.find_non_var_load_mem() {
        Some(exp) => Some(exp)
        None =>
          match yes.find_non_var_load_mem() {
            Some(exp) => Some(exp)
            None => no.find_non_var_load_mem()
          }
      }
    Int(_) | Var(_) | Unknown(_) => None
  }
}

///|
fn store_memory_var(exp : Exp) -> Var? {
  match exp {
    Store(mem=Var(variable), ..) => Some(variable)
    Store(mem~, ..) => store_memory_var(mem)
    _ => None
  }
}

///|
fn Stmt::rewrite_non_var_load_mem(self : Stmt, exp : Exp) -> Array[Stmt] {
  match exp.find_non_var_load_mem() {
    Some(store) =>
      match store_memory_var(store) {
        Some(variable) =>
          hoist_load_stores([
            Move(variable, store),
            self.substitute(store, Var(variable)),
          ])
        None => [self]
      }
    None => [self]
  }
}

///|
fn Stmt::hoist_load_stores(self : Stmt) -> Array[Stmt] {
  match self {
    Move(_, exp) | Jmp(exp) => self.rewrite_non_var_load_mem(exp)
    If(cond~, yes~, no~) =>
      [If(cond~, yes=hoist_load_stores(yes), no=hoist_load_stores(no))]
    While(cond~, body~) => [While(cond~, body=hoist_load_stores(body))]
    Special(_) | CpuExn(_) => [self]
  }
}

///|
fn hoist_load_stores(stmts : Array[Stmt]) -> Array[Stmt] {
  let result = []
  for stmt in stmts {
    for hoisted in stmt.hoist_load_stores() {
      result.push(hoisted)
    }
  }
  result
}

///|
pub fn Stmt::normalize(
  self : Stmt,
  normalize_exp? : Bool = false,
) -> Array[Stmt] {
  match self {
    Move(variable, exp) => {
      let stmt = Move(variable, normalize_exp_if(exp, normalize_exp))
      stmt.split_ite(normalize_exp)
    }
    Jmp(exp) => {
      let stmt = Jmp(normalize_exp_if(exp, normalize_exp))
      stmt.split_ite(normalize_exp)
    }
    Special(_) | CpuExn(_) => [self]
    If(cond~, yes~, no~) =>
      [
        If(
          cond=normalize_exp_if(cond, normalize_exp),
          yes=normalize(yes, normalize_exp~),
          no=normalize(no, normalize_exp~),
        ),
      ]
    While(cond~, body~) =>
      [
        While(
          cond=normalize_exp_if(cond, normalize_exp),
          body=normalize(body, normalize_exp~),
        ),
      ]
  }
}

///|
pub fn Stmt::fixpoint(self : Stmt, step : (Stmt) -> Stmt) -> Stmt {
  let mut current = self
  let mut next = step(current)
  while next != current {
    current = next
    next = step(current)
  }
  current
}

///|
pub fn Stmt::simplify_to_list(self : Stmt) -> Array[Stmt] {
  match self.simplify() {
    If(cond=Int(word), yes~, no~) => if word.is_zero() { no } else { yes }
    While(cond=Int(word), ..) if word.is_zero() => []
    stmt => [stmt]
  }
}

///|
pub fn simplify_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  let result = []
  for stmt in stmts {
    for simple in stmt.simplify_to_list() {
      result.push(simple)
    }
  }
  result
}

///|
pub fn normalize_negatives(stmts : Array[Stmt]) -> Array[Stmt] {
  stmts.map(stmt => stmt.normalize_negatives())
}

///|
pub fn normalize(
  stmts : Array[Stmt],
  normalize_exp? : Bool = false,
) -> Array[Stmt] {
  let result = []
  for stmt in stmts {
    for normalized in stmt.normalize(normalize_exp~) {
      result.push(normalized)
    }
  }
  hoist_load_stores(result)
}

///|
pub fn fold_consts(stmts : Array[Stmt]) -> Array[Stmt] {
  simplify_stmts(stmts)
}

///|
fn normalize_trie_var(variable : Var, variables : Array[Var]) -> Var {
  match variables.search_by(item => item.name() == variable.name()) {
    Some(index) => variables[index]
    None => {
      let canonical = Var::new(name=variable.name(), typ=variable.typ())
      variables.push(canonical)
      canonical
    }
  }
}

///|
fn Exp::normalize_trie_values(self : Exp, variables : Array[Var]) -> Exp {
  match self {
    Int(word) => Unknown("<pruned>", Imm(word.width()))
    Var(variable) => Var(normalize_trie_var(variable, variables))
    Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) =>
      Load(
        mem=mem.normalize_trie_values(variables),
        addr=addr.normalize_trie_values(variables),
        endian~,
        typ~,
      )
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.normalize_trie_values(variables),
        addr=addr.normalize_trie_values(variables),
        value=value.normalize_trie_values(variables),
        endian~,
      )
    Let(variable, value, body) =>
      Let(
        normalize_trie_var(variable, variables),
        value.normalize_trie_values(variables),
        body.normalize_trie_values(variables),
      )
    Cast(typ, exp) => Cast(typ, exp.normalize_trie_values(variables))
    UnOp(op, exp) => UnOp(op, exp.normalize_trie_values(variables))
    BinOp(op, lhs, rhs) =>
      BinOp(
        op,
        lhs.normalize_trie_values(variables),
        rhs.normalize_trie_values(variables),
      )
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=cond.normalize_trie_values(variables),
        yes=yes.normalize_trie_values(variables),
        no=no.normalize_trie_values(variables),
      )
  }
}

///|
fn Stmt::normalize_trie_values(self : Stmt, variables : Array[Var]) -> Stmt {
  match self {
    Move(variable, exp) =>
      Move(
        normalize_trie_var(variable, variables),
        exp.normalize_trie_values(variables),
      )
    Jmp(exp) => Jmp(exp.normalize_trie_values(variables))
    Special(_) | CpuExn(_) => self
    If(cond~, yes~, no~) =>
      If(
        cond=cond.normalize_trie_values(variables),
        yes=[ for stmt in yes => stmt.normalize_trie_values(variables) ],
        no=[ for stmt in no => stmt.normalize_trie_values(variables) ],
      )
    While(cond~, body~) =>
      While(
        cond=cond.normalize_trie_values(variables),
        body=[ for stmt in body => stmt.normalize_trie_values(variables) ],
      )
  }
}

///|
pub fn normalize_for_trie(
  stmts : Array[Stmt],
  subst? : Array[(Exp, Exp)],
) -> Array[Stmt] {
  let mut current = stmts
  match subst {
    Some(pairs) =>
      for pair in pairs {
        current = substitute(current, pair.0, pair.1)
      }
    None => ()
  }
  current = prune_unreferenced(current, virtuals=true)
  current = normalize_negatives(current)
  current = simplify_stmts(current)
  let variables = []
  [
    for stmt in current => stmt.normalize_trie_values(variables)
  ]
}

///|
pub fn fixpoint(
  stmts : Array[Stmt],
  step : (Array[Stmt]) -> Array[Stmt],
) -> Array[Stmt] {
  let mut current = stmts
  let mut next = step(current)
  while next != current {
    current = next
    next = step(current)
  }
  current
}

///|
fn const_lookup(ctx : Array[(Var, Exp)], variable : Var) -> Exp? {
  match ctx.search_by(pair => pair.0 == variable) {
    Some(i) => Some(ctx[i].1)
    None => None
  }
}

///|
fn const_set(
  ctx : Array[(Var, Exp)],
  variable : Var,
  value : Exp?,
) -> Array[(Var, Exp)] {
  let next = ctx.filter(pair => pair.0 != variable)
  match value {
    Some(exp) => next.push((variable, exp))
    None => ()
  }
  next
}

///|
fn const_value(exp : Exp) -> Exp? {
  if is_constant_exp(exp) {
    Some(exp)
  } else {
    None
  }
}

///|
fn join_const_contexts(
  left : Array[(Var, Exp)],
  right : Array[(Var, Exp)],
) -> Array[(Var, Exp)] {
  let joined = []
  for pair in left {
    match const_lookup(right, pair.0) {
      Some(exp) if exp == pair.1 => joined.push(pair)
      _ => ()
    }
  }
  joined
}

///|
fn stmt_may_jump(stmt : Stmt) -> Bool {
  match stmt {
    Jmp(_) => true
    If(yes~, no~, ..) => stmts_may_jump(yes) || stmts_may_jump(no)
    While(body~, ..) => stmts_may_jump(body)
    Move(_, _) | Special(_) | CpuExn(_) => false
  }
}

///|
fn stmts_may_jump(stmts : Array[Stmt]) -> Bool {
  stmts.any(stmt_may_jump)
}

///|
fn stmt_defined_vars(stmt : Stmt, vars : Array[Var]) -> Unit {
  match stmt {
    Move(variable, _) => add_var(vars, variable)
    If(yes~, no~, ..) => {
      for item in yes {
        stmt_defined_vars(item, vars)
      }
      for item in no {
        stmt_defined_vars(item, vars)
      }
    }
    While(body~, ..) =>
      for item in body {
        stmt_defined_vars(item, vars)
      }
    Jmp(_) | Special(_) | CpuExn(_) => ()
  }
}

///|
fn defined_vars_in_stmts(stmts : Array[Stmt]) -> Array[Var] {
  let vars = []
  for stmt in stmts {
    stmt_defined_vars(stmt, vars)
  }
  vars
}

///|
fn remove_context_vars(
  ctx : Array[(Var, Exp)],
  vars : Array[Var],
) -> Array[(Var, Exp)] {
  ctx.filter(pair => !vars.any(variable => variable == pair.0))
}

///|
fn Exp::propagate_consts(self : Exp, ctx : Array[(Var, Exp)]) -> Exp {
  match self {
    Int(_) | Unknown(_) => self
    Var(variable) =>
      match const_lookup(ctx, variable) {
        Some(exp) => exp
        None => self
      }
    Load(mem~, addr~, endian~, typ~) =>
      Load(
        mem=mem.propagate_consts(ctx),
        addr=addr.propagate_consts(ctx),
        endian~,
        typ~,
      ).simplify()
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=mem.propagate_consts(ctx),
        addr=addr.propagate_consts(ctx),
        value=value.propagate_consts(ctx),
        endian~,
      ).simplify()
    Let(variable, value, body) => {
      let next_value = value.propagate_consts(ctx).simplify()
      let inner = const_set(ctx, variable, const_value(next_value))
      Let(variable, next_value, body.propagate_consts(inner)).simplify()
    }
    Cast(typ, exp) => Cast(typ, exp.propagate_consts(ctx)).simplify()
    UnOp(op, exp) => UnOp(op, exp.propagate_consts(ctx)).simplify()
    BinOp(op, lhs, rhs) =>
      BinOp(op, lhs.propagate_consts(ctx), rhs.propagate_consts(ctx)).simplify()
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=cond.propagate_consts(ctx),
        yes=yes.propagate_consts(ctx),
        no=no.propagate_consts(ctx),
      ).simplify()
  }
}

///|
fn propagate_const_loop(
  stmts : Array[Stmt],
  ctx_in : Array[(Var, Exp)],
) -> (Array[Stmt], Array[(Var, Exp)]) {
  let mut ctx = ctx_in.copy()
  let result = []
  for stmt in stmts {
    match stmt {
      Move(variable, exp) => {
        let next_exp = exp.propagate_consts(ctx).simplify()
        ctx = const_set(ctx, variable, const_value(next_exp))
        result.push(Move(variable, next_exp))
      }
      Jmp(exp) => result.push(Jmp(exp.propagate_consts(ctx).simplify()))
      Special(_) | CpuExn(_) => result.push(stmt)
      If(cond~, yes~, no~) => {
        let next_cond = cond.propagate_consts(ctx).simplify()
        let yes_result = propagate_const_loop(yes, ctx)
        let no_result = propagate_const_loop(no, ctx)
        ctx = match next_cond {
          Int(word) => {
            let (selected_stmts, selected_ctx) = if word.is_zero() {
              (no_result.0, no_result.1)
            } else {
              (yes_result.0, yes_result.1)
            }
            if stmts_may_jump(selected_stmts) {
              remove_context_vars(ctx, defined_vars_in_stmts(selected_stmts))
            } else {
              selected_ctx
            }
          }
          _ => join_const_contexts(yes_result.1, no_result.1)
        }
        result.push(If(cond=next_cond, yes=yes_result.0, no=no_result.0))
      }
      While(cond~, body~) => {
        let killed = defined_vars_in_stmts(body)
        let loop_ctx = remove_context_vars(ctx, killed)
        let next_cond = cond.propagate_consts(loop_ctx).simplify()
        let body_result = propagate_const_loop(body, loop_ctx)
        ctx = match next_cond {
          Int(word) if word.is_zero() => ctx
          _ => join_const_contexts(loop_ctx, body_result.1)
        }
        result.push(While(cond=next_cond, body=body_result.0))
      }
    }
  }
  (result, ctx)
}

///|
pub fn propagate_const_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  propagate_const_loop(stmts, []).0
}

///|
fn remove_live_var(live : Array[Var], variable : Var) -> Array[Var] {
  live.filter(item => item != variable)
}

///|
fn add_stmt_live_vars(live : Array[Var], stmt : Stmt) -> Unit {
  add_vars(live, stmt.free_vars())
}

///|
fn prune_dead_virtuals_loop(
  stmts : Array[Stmt],
  live_out : Array[Var],
) -> (Array[Stmt], Array[Var]) {
  let mut live = live_out.copy()
  let kept = []
  for offset in 0..<stmts.length() {
    let stmt = stmts[stmts.length() - offset - 1]
    match stmt {
      Move(variable, exp) =>
        if variable.is_virtual && !live.any(item => item == variable) {
          ()
        } else {
          live = remove_live_var(live, variable)
          add_vars(live, exp.free_vars())
          kept.push(stmt)
        }
      Jmp(exp) => {
        add_vars(live, exp.free_vars())
        kept.push(stmt)
      }
      Special(_) | CpuExn(_) => kept.push(stmt)
      If(cond~, yes~, no~) => {
        let yes_result = prune_dead_virtuals_loop(yes, live)
        let no_result = prune_dead_virtuals_loop(no, live)
        let next_live = []
        add_vars(next_live, cond.free_vars())
        add_vars(next_live, yes_result.1)
        add_vars(next_live, no_result.1)
        live = next_live
        kept.push(If(cond~, yes=yes_result.0, no=no_result.0))
      }
      While(cond~, body~) => {
        add_vars(live, cond.free_vars())
        for body_stmt in body {
          add_stmt_live_vars(live, body_stmt)
        }
        kept.push(stmt)
      }
    }
  }
  (kept.rev(), live)
}

///|
pub fn prune_dead_virtual_stmts(stmts : Array[Stmt]) -> Array[Stmt] {
  prune_dead_virtuals_loop(stmts, []).0
}

///|
fn should_prune_unreferenced(
  variable : Var,
  physicals : Bool,
  virtuals : Bool,
  such_that : ((Var) -> Bool)?,
) -> Bool {
  (physicals && !variable.is_virtual) ||
  (virtuals && variable.is_virtual) ||
  (match such_that {
    Some(predicate) => predicate(variable)
    None => false
  })
}

///|
pub fn prune_unreferenced(
  stmts : Array[Stmt],
  such_that? : (Var) -> Bool,
  physicals? : Bool = false,
  virtuals? : Bool = false,
) -> Array[Stmt] {
  let kept = []
  for i in 0..<stmts.length() {
    let stmt = stmts[i]
    match stmt {
      Move(variable, _) =>
        if should_prune_unreferenced(variable, physicals, virtuals, such_that) &&
          !is_referenced(stmts[i + 1:].to_owned(), variable) {
          ()
        } else {
          kept.push(stmt)
        }
      _ => kept.push(stmt)
    }
  }
  kept
}

///|
fn optimize_stmts_once(stmts : Array[Stmt]) -> Array[Stmt] {
  prune_dead_virtual_stmts(
    simplify_stmts(propagate_const_stmts(simplify_stmts(stmts))),
  )
}

///|
pub fn optimize_stmts(
  stmts : Array[Stmt],
  max_iterations? : Int = 16,
) -> Array[Stmt] {
  let mut current = stmts
  let mut next = optimize_stmts_once(current)
  let mut iterations = 1
  while next != current && iterations < max_iterations {
    current = next
    next = optimize_stmts_once(current)
    iterations = iterations + 1
  }
  next
}
