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
fn fold_cast(kind : CastKind, width : Int, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match cast_word(kind, width, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn fold_extract(hi : Int, lo : Int, exp : Exp) -> Exp? {
  match exp {
    Int(word) =>
      match extract_word(hi, lo, word) {
        Ok(result) => Some(Int(result))
        Err(_) => None
      }
    _ => None
  }
}

///|
fn simplify_cast(kind : CastKind, width : Int, exp : Exp) -> Exp {
  match fold_cast(kind, width, exp) {
    Some(result) => result
    None =>
      match exp {
        Cast(width=inner_width, ..) if width == inner_width => exp
        Cast(kind=inner_kind, width=inner_width, exp=inner_exp) if kind ==
          inner_kind &&
          inner_width >= width => Cast(kind~, width~, exp=inner_exp)
        Cast(kind=Unsigned, width=inner_width, exp=inner_exp) if kind ==
          Unsigned &&
          inner_width <= width => Cast(kind~, width~, exp=inner_exp)
        Cast(kind=Signed, width=inner_width, exp=inner_exp) if kind == Signed &&
          inner_width <= width => Cast(kind~, width~, exp=inner_exp)
        Extract(hi~, exp=inner_exp, ..) if kind == High && width > 0 =>
          Extract(hi~, lo=hi - width + 1, exp=inner_exp)
        _ =>
          match exp.infer_type() {
            Ok(Imm(exp_width)) if exp_width == width => exp
            _ => Cast(kind~, width~, exp~)
          }
      }
  }
}

///|
fn fold_concat(high : Exp, low : Exp) -> Exp? {
  match (high, low) {
    (Int(high_word), Int(low_word)) =>
      try high_word.concat(low_word) catch {
        _ => None
      } noraise {
        result => Some(Int(result))
      }
    _ => None
  }
}

///|
fn zero_or(exp : Exp, fallback : Exp) -> Exp {
  match exp.infer_type() {
    Ok(Imm(width)) =>
      try Word::zero(width~) catch {
        _ => fallback
      } noraise {
        word => Int(word)
      }
    _ => fallback
  }
}

///|
fn word_is_all_ones(word : Word) -> Bool {
  word.lnot().is_zero()
}

///|
fn int_word(exp : Exp) -> Word? {
  match exp {
    Int(word) => Some(word)
    _ => None
  }
}

///|
fn exp_is_zero(exp : Exp) -> Bool {
  match int_word(exp) {
    Some(word) => word.is_zero()
    None => false
  }
}

///|
fn exp_is_one(exp : Exp) -> Bool {
  match int_word(exp) {
    Some(word) => word.is_one()
    None => false
  }
}

///|
fn exp_is_all_ones(exp : Exp) -> Bool {
  match int_word(exp) {
    Some(word) => word_is_all_ones(word)
    None => false
  }
}

///|
fn fold_apply_binop(op : BinOp, lhs : Word, rhs : Word) -> Exp? {
  match op.apply(lhs, rhs) {
    Ok(word) => Some(Int(word))
    Err(_) => None
  }
}

///|
fn smart_raw_binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp {
  BinOp(op, lhs, rhs)
}

///|
pub fn Exp::smart_binop(op : BinOp, lhs : Exp, rhs : Exp) -> Exp {
  let raw = smart_raw_binop(op, lhs, rhs)
  match (op, lhs, rhs) {
    (_, Int(left), Int(right)) =>
      match fold_apply_binop(op, left, right) {
        Some(result) => result
        None => raw
      }
    (Plus, BinOp(Plus, left, Int(y)), Int(z)) =>
      match fold_apply_binop(Plus, y, z) {
        Some(Int(sum)) => BinOp(Plus, left, Int(sum))
        _ => raw
      }
    (Plus, BinOp(Plus, Int(y), right), Int(z)) =>
      match fold_apply_binop(Plus, y, z) {
        Some(Int(sum)) => BinOp(Plus, right, Int(sum))
        _ => raw
      }
    (Plus, left, right) if exp_is_zero(left) => right
    (Plus, left, right) if exp_is_zero(right) => left
    (Minus, left, right) if exp_is_zero(left) => UnOp(Neg, right)
    (Minus, left, right) if exp_is_zero(right) => left
    (Minus, left, right) if left == right => zero_or(raw, raw)
    (Minus, BinOp(Minus, left, Int(y)), Int(z)) =>
      match fold_apply_binop(Plus, y, z) {
        Some(Int(sum)) => BinOp(Minus, left, Int(sum))
        _ => raw
      }
    (Minus, BinOp(Plus, left, Int(c1)), Int(c2)) =>
      match fold_apply_binop(Minus, c1, c2) {
        Some(Int(diff)) => BinOp(Plus, left, Int(diff))
        _ => raw
      }
    (Minus, BinOp(Plus, Int(c1), right), Int(c2)) =>
      match fold_apply_binop(Minus, c1, c2) {
        Some(Int(diff)) => BinOp(Plus, right, Int(diff))
        _ => raw
      }
    (Times, left, _) if exp_is_zero(left) => left
    (Times, _, right) if exp_is_zero(right) => right
    (Times, left, right) if exp_is_one(left) => right
    (Times, left, right) if exp_is_one(right) => left
    (Div | SignedDiv, left, right) if exp_is_one(right) => left
    (Mod | SignedMod, _, right) if exp_is_one(right) => zero_or(raw, raw)
    (LShift | RShift | ARShift, left, right) if exp_is_zero(right) => left
    (LShift | RShift | ARShift, left, _) if exp_is_zero(left) => left
    (ARShift, left, _) if exp_is_all_ones(left) => left
    (And, left, _) if exp_is_zero(left) => left
    (And, _, right) if exp_is_zero(right) => right
    (And, left, right) if exp_is_all_ones(left) => right
    (And, left, right) if exp_is_all_ones(right) => left
    (And, left, right) if left == right => left
    (Or, left, right) if exp_is_zero(left) => right
    (Or, left, right) if exp_is_zero(right) => left
    (Or, left, _) if exp_is_all_ones(left) => left
    (Or, _, right) if exp_is_all_ones(right) => right
    (Or, left, right) if left == right => left
    (Xor, left, right) if left == right => zero_or(raw, raw)
    (Xor, left, right) if exp_is_zero(left) => right
    (Xor, left, right) if exp_is_zero(right) => left
    (Eq, left, right) if left == right => Int(Word::b1())
    (Neq, left, right) if left == right => Int(Word::b0())
    (Lt | SignedLt, left, right) if left == right => Int(Word::b0())
    _ => raw
  }
}

///|
pub fn Exp::smart_unop(op : UnOp, exp : Exp) -> Exp {
  let raw = UnOp(op, exp)
  match (op, exp) {
    (_, Int(word)) =>
      match op.apply(word) {
        Ok(result) => Int(result)
        Err(_) => raw
      }
    (_, UnOp(inner, inner_exp)) if op == inner => inner_exp
    (Not, BinOp(Lt, left, right)) => Exp::smart_binop(Le, right, left)
    (Not, BinOp(Le, left, right)) => Exp::smart_binop(Lt, right, left)
    (Not, BinOp(SignedLt, left, right)) =>
      Exp::smart_binop(SignedLe, right, left)
    (Not, BinOp(SignedLe, left, right)) =>
      Exp::smart_binop(SignedLt, right, left)
    (Not, BinOp(Eq, left, right)) => Exp::smart_binop(Neq, left, right)
    (Not, BinOp(Neq, left, right)) => Exp::smart_binop(Eq, left, right)
    _ => raw
  }
}

///|
fn exp_has_width(width : Int, exp : Exp) -> Bool {
  match exp.infer_type() {
    Ok(Imm(actual)) => actual == width
    _ => false
  }
}

///|
pub fn Exp::smart_cast(kind : CastKind, width : Int, exp : Exp) -> Exp {
  match exp {
    Int(word) =>
      match kind.apply(width, word) {
        Ok(result) => Int(result)
        Err(_) => Cast(kind~, width~, exp~)
      }
    Cast(width=inner_width, ..) if width == inner_width => exp
    Cast(kind=inner_kind, width=inner_width, exp=inner_exp) if kind ==
      inner_kind &&
      inner_width >= width => Cast(kind~, width~, exp=inner_exp)
    Cast(kind=Unsigned, width=inner_width, exp=inner_exp) if kind == Unsigned &&
      inner_width <= width => Cast(kind~, width~, exp=inner_exp)
    Cast(kind=Signed, width=inner_width, exp=inner_exp) if kind == Signed &&
      inner_width <= width => Cast(kind~, width~, exp=inner_exp)
    Extract(hi~, exp=inner_exp, ..) if kind == High && width > 0 =>
      Extract(hi~, lo=hi - width + 1, exp=inner_exp)
    _ => if exp_has_width(width, exp) { exp } else { Cast(kind~, width~, exp~) }
  }
}

///|
pub fn Exp::smart_ite(if_~ : Exp, then_~ : Exp, else_~ : Exp) -> Exp {
  match if_ {
    Int(word) => if word == Word::b1() { then_ } else { else_ }
    _ => Ite(cond=if_, yes=then_, no=else_)
  }
}

///|
pub fn Exp::smart_extract(exp : Exp, hi~ : Int, lo~ : Int) -> Exp {
  match exp {
    Int(word) =>
      match extract_word(hi, lo, word) {
        Ok(result) => Int(result)
        Err(_) => Extract(hi~, lo~, exp~)
      }
    Extract(hi=inner_hi, lo=inner_lo, exp=inner_exp) if hi <= inner_hi &&
      lo >= inner_lo => Extract(hi~, lo~, exp=inner_exp)
    _ =>
      if lo == 0 && exp_has_width(hi + 1, exp) {
        exp
      } else {
        Extract(hi~, lo~, exp~)
      }
  }
}

///|
pub fn Exp::smart_concat(high : Exp, low : Exp) -> Exp {
  match (fold_concat(high, low), high, low) {
    (Some(result), _, _) => result
    (
      _,
      Cast(kind=High, width=cast_width, exp=Var(variable) as source),
      Extract(hi~, lo~, exp=Var(other)),
    ) if variable == other && exp_has_width(hi + cast_width + 1, source) =>
      Exp::smart_cast(High, cast_width + hi - lo + 1, source)
    (
      _,
      Cast(kind=High, width=cast_width, exp=Var(variable) as source),
      Concat(high=Extract(hi~, lo~, exp=Var(other)), low=tail),
    ) if variable == other && exp_has_width(hi + cast_width + 1, source) =>
      Concat(
        high=Exp::smart_cast(High, cast_width + hi - lo + 1, source),
        low=tail,
      )
    _ => Concat(high~, low~)
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
    Cast(kind~, width~, exp~) =>
      Cast(kind~, width~, exp=exp.normalize_negatives())
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=exp.normalize_negatives())
    Concat(high~, low~) =>
      Concat(high=high.normalize_negatives(), low=low.normalize_negatives())
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
  self.normalize_negatives().expand_memory()
}

///|
fn memory_addr_offset(mem : Exp, addr : Exp, offset : Int) -> Exp {
  if offset == 0 {
    addr
  } else {
    match mem.type_of() {
      Mem(addr_width~, ..) if addr_width > 0 =>
        BinOp(Plus, addr, Int(try! Word::of_int(width=addr_width, offset)))
      _ => addr
    }
  }
}

///|
fn memory_cell_count(total_width : Int, cell_width : Int) -> Int? {
  if cell_width <= 0 || total_width <= cell_width {
    None
  } else if total_width % cell_width == 0 {
    Some(total_width / cell_width)
  } else {
    None
  }
}

///|
fn expand_load_memory(
  mem : Exp,
  addr : Exp,
  endian : @bitvec.Endian,
  cell_width : Int,
  count : Int,
  index : Int,
) -> Exp {
  let current = Load(
    mem~,
    addr=memory_addr_offset(mem, addr, index),
    endian~,
    typ=Imm(cell_width),
  )
  if index + 1 >= count {
    current
  } else {
    let rest = expand_load_memory(
      mem,
      addr,
      endian,
      cell_width,
      count,
      index + 1,
    )
    if endian == LittleEndian {
      Concat(high=rest, low=current)
    } else {
      Concat(high=current, low=rest)
    }
  }
}

///|
fn expand_store_memory(
  mem : Exp,
  addr : Exp,
  value : Exp,
  endian : @bitvec.Endian,
  cell_width : Int,
  count : Int,
) -> Exp {
  let mut result = mem
  for index in 0..<count {
    let piece_index = if endian == BigEndian {
      count - index - 1
    } else {
      index
    }
    let lo = piece_index * cell_width
    let hi = lo + cell_width - 1
    result = Store(
      mem=result,
      addr=memory_addr_offset(mem, addr, index),
      value=Extract(hi~, lo~, exp=value),
      endian=LittleEndian,
    )
  }
  result
}

///|
fn Exp::expand_memory(self : Exp) -> Exp {
  match self {
    Int(_) | Var(_) | Unknown(_) => self
    Load(mem~, addr~, endian~, typ~) => {
      let expanded_mem = mem.expand_memory()
      let expanded_addr = addr.expand_memory()
      match (expanded_mem.type_of(), typ) {
        (Mem(value_width~, ..), Imm(load_width)) =>
          match memory_cell_count(load_width, value_width) {
            Some(count) =>
              expand_load_memory(
                expanded_mem, expanded_addr, endian, value_width, count, 0,
              )
            None => Load(mem=expanded_mem, addr=expanded_addr, endian~, typ~)
          }
        _ => Load(mem=expanded_mem, addr=expanded_addr, endian~, typ~)
      }
    }
    Store(mem~, addr~, value~, endian~) => {
      let expanded_mem = mem.expand_memory()
      let expanded_addr = addr.expand_memory()
      let expanded_value = value.expand_memory()
      match (expanded_mem.type_of(), expanded_value.type_of()) {
        (Mem(value_width~, ..), Imm(store_width)) =>
          match memory_cell_count(store_width, value_width) {
            Some(count) =>
              expand_store_memory(
                expanded_mem, expanded_addr, expanded_value, endian, value_width,
                count,
              )
            None =>
              Store(
                mem=expanded_mem,
                addr=expanded_addr,
                value=expanded_value,
                endian~,
              )
          }
        _ =>
          Store(
            mem=expanded_mem,
            addr=expanded_addr,
            value=expanded_value,
            endian~,
          )
      }
    }
    Let(variable, value, body) =>
      Let(variable, value.expand_memory(), body.expand_memory())
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=exp.expand_memory())
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=exp.expand_memory())
    Concat(high~, low~) =>
      Concat(high=high.expand_memory(), low=low.expand_memory())
    UnOp(op, exp) => UnOp(op, exp.expand_memory())
    BinOp(op, lhs, rhs) => BinOp(op, lhs.expand_memory(), rhs.expand_memory())
    Ite(cond~, yes~, no~) =>
      Ite(
        cond=cond.expand_memory(),
        yes=yes.expand_memory(),
        no=no.expand_memory(),
      )
  }
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
    Cast(exp~, ..) | UnOp(_, exp) => exp.first_ite_cond()
    Extract(exp~, ..) => exp.first_ite_cond()
    Concat(high~, low~) =>
      match high.first_ite_cond() {
        Some(cond) => Some(cond)
        None => low.first_ite_cond()
      }
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
    Cast(kind~, width~, exp~) =>
      Cast(kind~, width~, exp=exp.assume_ite(target, take_yes))
    UnOp(op, exp) => UnOp(op, exp.assume_ite(target, take_yes))
    Extract(hi~, lo~, exp~) =>
      Extract(hi~, lo~, exp=exp.assume_ite(target, take_yes))
    Concat(high~, low~) =>
      Concat(
        high=high.assume_ite(target, take_yes),
        low=low.assume_ite(target, take_yes),
      )
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
    Cast(kind~, width~, exp~) => {
      let simple = exp.simplify()
      simplify_cast(kind, width, simple)
    }
    Extract(hi~, lo~, exp~) => {
      let simple = exp.simplify()
      match fold_extract(hi, lo, simple) {
        Some(result) => result
        None => Extract(hi~, lo~, exp=simple)
      }
    }
    Concat(high~, low~) => {
      let simple_high = high.simplify()
      let simple_low = low.simplify()
      match fold_concat(simple_high, simple_low) {
        Some(result) => result
        None => Concat(high=simple_high, low=simple_low)
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
    Cast(exp~, ..) | UnOp(_, exp) => exp.find_non_var_load_mem()
    Extract(exp~, ..) => exp.find_non_var_load_mem()
    Concat(high~, low~) =>
      match high.find_non_var_load_mem() {
        Some(exp) => Some(exp)
        None => low.find_non_var_load_mem()
      }
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
let normalize_tmp_counter : Ref[Int] = Ref(0)

///|
fn normalize_fresh_var(typ : ValueType) -> Var {
  normalize_tmp_counter.val = normalize_tmp_counter.val + 1
  Var::new(name="tmp#\{normalize_tmp_counter.val}", typ~, is_virtual=true)
}

///|
fn append_stmts(lhs : Array[Stmt], rhs : Array[Stmt]) -> Array[Stmt] {
  let result = lhs.copy()
  for stmt in rhs {
    result.push(stmt)
  }
  result
}

///|
fn embed_hoisted_moves(stmts : Array[Stmt], body : Exp) -> Exp {
  let mut result = body
  let mut i = stmts.length()
  while i > 0 {
    i = i - 1
    match stmts[i] {
      Move(variable, exp) => result = Let(variable, exp, result)
      _ => ()
    }
  }
  result
}

///|
fn Exp::needs_condition_hoist(self : Exp) -> Bool {
  self.first_ite_cond() is Some(_) ||
  self.find_non_var_load_mem() is Some(_) ||
  self.has_memory_effects()
}

///|
fn normalize_condition_setup(
  variable : Var,
  cond : Exp,
  normalize_exp : Bool,
) -> Array[Stmt] {
  Move(variable, cond).normalize(normalize_exp~)
}

///|
fn Exp::has_memory_effects(self : Exp) -> Bool {
  let effect = self.effect()
  effect.loads() || effect.stores()
}

///|
fn Exp::hoist_if_memory_effect(self : Exp) -> (Array[Stmt], Exp) {
  if self.has_memory_effects() {
    let variable = normalize_fresh_var(self.type_of())
    ([Move(variable, self)], Var(variable))
  } else {
    ([], self)
  }
}

///|
fn Exp::hoist_non_generative(self : Exp) -> (Array[Stmt], Exp) {
  match self {
    Int(_) | Var(_) | Unknown(_) => ([], self)
    Load(mem~, addr~, endian~, typ~) => {
      let (mem_stmts, normalized_mem) = mem.hoist_if_memory_effect()
      let (addr_stmts, normalized_addr) = addr.hoist_if_memory_effect()
      (
        append_stmts(mem_stmts, addr_stmts),
        Load(mem=normalized_mem, addr=normalized_addr, endian~, typ~),
      )
    }
    Store(mem~, addr~, value~, endian~) => {
      let (mem_stmts, normalized_mem) = mem.hoist_non_generative()
      let (addr_stmts, normalized_addr) = addr.hoist_non_generative()
      let (value_stmts, normalized_value) = value.hoist_non_generative()
      let (addr_hoists, hoisted_addr) = normalized_addr.hoist_if_memory_effect()
      let (value_hoists, hoisted_value) = normalized_value.hoist_if_memory_effect()
      (
        append_stmts(
          append_stmts(
            append_stmts(append_stmts(mem_stmts, addr_stmts), value_stmts),
            addr_hoists,
          ),
          value_hoists,
        ),
        Store(
          mem=normalized_mem,
          addr=hoisted_addr,
          value=hoisted_value,
          endian~,
        ),
      )
    }
    Let(variable, value, body) => {
      let (value_stmts, normalized_value) = value.hoist_non_generative()
      let (body_stmts, normalized_body) = body.hoist_non_generative()
      let (value_hoists, hoisted_value) = normalized_value.hoist_if_memory_effect()
      (
        append_stmts(value_stmts, value_hoists),
        Let(
          variable,
          hoisted_value,
          embed_hoisted_moves(body_stmts, normalized_body),
        ),
      )
    }
    Cast(kind~, width~, exp~) => {
      let (stmts, normalized) = exp.hoist_non_generative()
      (stmts, Cast(kind~, width~, exp=normalized))
    }
    Extract(hi~, lo~, exp~) => {
      let (stmts, normalized) = exp.hoist_non_generative()
      (stmts, Extract(hi~, lo~, exp=normalized))
    }
    Concat(high~, low~) => {
      let (high_stmts, normalized_high) = high.hoist_non_generative()
      let (low_stmts, normalized_low) = low.hoist_non_generative()
      (
        append_stmts(high_stmts, low_stmts),
        Concat(high=normalized_high, low=normalized_low),
      )
    }
    UnOp(op, exp) => {
      let (stmts, normalized) = exp.hoist_non_generative()
      (stmts, UnOp(op, normalized))
    }
    BinOp(op, lhs, rhs) => {
      let (lhs_stmts, normalized_lhs) = lhs.hoist_non_generative()
      let (rhs_stmts, normalized_rhs) = rhs.hoist_non_generative()
      (
        append_stmts(lhs_stmts, rhs_stmts),
        BinOp(op, normalized_lhs, normalized_rhs),
      )
    }
    Ite(cond~, yes~, no~) => {
      let (cond_stmts, normalized_cond) = cond.hoist_non_generative()
      let (yes_stmts, normalized_yes) = yes.hoist_non_generative()
      let (no_stmts, normalized_no) = no.hoist_non_generative()
      let (cond_hoists, hoisted_cond) = normalized_cond.hoist_if_memory_effect()
      (
        append_stmts(
          append_stmts(append_stmts(cond_stmts, yes_stmts), no_stmts),
          cond_hoists,
        ),
        Ite(cond=hoisted_cond, yes=normalized_yes, no=normalized_no),
      )
    }
  }
}

///|
fn Stmt::hoist_non_generative(self : Stmt) -> Array[Stmt] {
  match self {
    Move(variable, exp) => {
      let (stmts, normalized) = exp.hoist_non_generative()
      append_stmts(stmts, [Move(variable, normalized)])
    }
    Jmp(exp) => {
      let (stmts, normalized) = exp.hoist_non_generative()
      append_stmts(stmts, [Jmp(normalized)])
    }
    If(cond~, yes~, no~) => {
      let (cond_stmts, normalized_cond) = cond.hoist_non_generative()
      append_stmts(cond_stmts, [
        If(
          cond=normalized_cond,
          yes=hoist_non_generative(yes),
          no=hoist_non_generative(no),
        ),
      ])
    }
    While(cond~, body~) => {
      let (cond_stmts, normalized_cond) = cond.hoist_non_generative()
      append_stmts(cond_stmts, [
        While(cond=normalized_cond, body=hoist_non_generative(body)),
      ])
    }
    Special(_) | CpuExn(_) => [self]
  }
}

///|
fn hoist_non_generative(stmts : Array[Stmt]) -> Array[Stmt] {
  let result = []
  for stmt in stmts {
    for hoisted in stmt.hoist_non_generative() {
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
    If(cond~, yes~, no~) => {
      let normalized_cond = normalize_exp_if(cond, normalize_exp)
      let normalized_yes = normalize(yes, normalize_exp~)
      let normalized_no = normalize(no, normalize_exp~)
      if normalized_cond.needs_condition_hoist() {
        let variable = normalize_fresh_var(normalized_cond.type_of())
        append_stmts(
          normalize_condition_setup(variable, normalized_cond, normalize_exp),
          [If(cond=Var(variable), yes=normalized_yes, no=normalized_no)],
        )
      } else {
        [If(cond=normalized_cond, yes=normalized_yes, no=normalized_no)]
      }
    }
    While(cond~, body~) => {
      let normalized_cond = normalize_exp_if(cond, normalize_exp)
      let normalized_body = normalize(body, normalize_exp~)
      if normalized_cond.needs_condition_hoist() {
        let variable = normalize_fresh_var(normalized_cond.type_of())
        let setup = normalize_condition_setup(
          variable, normalized_cond, normalize_exp,
        )
        let body_with_update = append_stmts(normalized_body, setup)
        append_stmts(setup, [While(cond=Var(variable), body=body_with_update)])
      } else {
        [While(cond=normalized_cond, body=normalized_body)]
      }
    }
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
  let stmts = hoist_non_generative(stmts)
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
    Cast(kind~, width~, exp~) =>
      Cast(kind~, width~, exp=exp.normalize_trie_values(variables))
    Extract(hi~, lo~, exp~) =>
      Extract(hi~, lo~, exp=exp.normalize_trie_values(variables))
    Concat(high~, low~) =>
      Concat(
        high=high.normalize_trie_values(variables),
        low=low.normalize_trie_values(variables),
      )
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
fn stmt_can_fallthrough(stmt : Stmt) -> Bool {
  match stmt {
    Jmp(_) => false
    If(yes~, no~, ..) => stmts_can_fallthrough(yes) || stmts_can_fallthrough(no)
    Move(_, _) | Special(_) | CpuExn(_) | While(_) => true
  }
}

///|
fn stmts_can_fallthrough(stmts : Array[Stmt]) -> Bool {
  let mut can_reach = true
  for stmt in stmts {
    if can_reach {
      can_reach = stmt_can_fallthrough(stmt)
    }
  }
  can_reach
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
    Cast(kind~, width~, exp~) =>
      Cast(kind~, width~, exp=exp.propagate_consts(ctx)).simplify()
    Extract(hi~, lo~, exp~) =>
      Extract(hi~, lo~, exp=exp.propagate_consts(ctx)).simplify()
    Concat(high~, low~) =>
      Concat(high=high.propagate_consts(ctx), low=low.propagate_consts(ctx)).simplify()
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
            let (selected_stmts, selected_ctx, other_stmts) = if word.is_zero() {
              (no_result.0, no_result.1, yes_result.0)
            } else {
              (yes_result.0, yes_result.1, no_result.0)
            }
            if stmts_may_jump(selected_stmts) {
              remove_context_vars(ctx, defined_vars_in_stmts(selected_stmts))
            } else if stmts_may_jump(other_stmts) {
              selected_ctx
            } else {
              join_const_contexts(yes_result.1, no_result.1)
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
          Int(word) if word.is_zero() =>
            if stmts_can_fallthrough(body_result.0) {
              join_const_contexts(ctx, body_result.1)
            } else {
              ctx
            }
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
pub fn propagate_consts(stmts : Array[Stmt]) -> Array[Stmt] {
  propagate_const_stmts(stmts)
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
pub fn prune_dead_virtuals(stmts : Array[Stmt]) -> Array[Stmt] {
  prune_dead_virtual_stmts(stmts)
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
