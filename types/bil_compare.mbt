///|
fn[A] compare_array(
  left : Array[A],
  right : Array[A],
  compare_item : (A, A) -> Int32,
) -> Int32 {
  let length_order = left.length().compare(right.length())
  if length_order != 0 {
    return length_order
  }
  for i in 0..<left.length() {
    let item_order = compare_item(left[i], right[i])
    if item_order != 0 {
      return item_order
    }
  }
  0
}

///|
fn compare_endian(left : @bitvec.Endian, right : @bitvec.Endian) -> Int32 {
  fn rank(value : @bitvec.Endian) -> Int32 {
    match value {
      LittleEndian => 0
      BigEndian => 1
    }
  }
  rank(left).compare(rank(right))
}

///|
fn UnOp::rank(self : UnOp) -> Int32 {
  match self {
    Not => 0
    Neg => 1
  }
}

///|
pub fn UnOp::equal(self : UnOp, other : UnOp) -> Bool {
  self == other
}

///|
pub fn UnOp::compare(self : UnOp, other : UnOp) -> Int32 {
  self.rank().compare(other.rank())
}

///|
fn BinOp::rank(self : BinOp) -> Int32 {
  match self {
    Plus => 0
    Minus => 1
    Times => 2
    Div => 3
    SignedDiv => 4
    Mod => 5
    SignedMod => 6
    And => 7
    Or => 8
    Xor => 9
    LShift => 10
    RShift => 11
    ARShift => 12
    Eq => 13
    Neq => 14
    Lt => 15
    Le => 16
    SignedLt => 17
    SignedLe => 18
  }
}

///|
pub fn BinOp::equal(self : BinOp, other : BinOp) -> Bool {
  self == other
}

///|
pub fn BinOp::compare(self : BinOp, other : BinOp) -> Int32 {
  self.rank().compare(other.rank())
}

///|
fn CastKind::rank(self : CastKind) -> Int32 {
  match self {
    Unsigned => 0
    Signed => 1
    High => 2
    Low => 3
  }
}

///|
pub fn CastKind::equal(self : CastKind, other : CastKind) -> Bool {
  self == other
}

///|
pub fn CastKind::compare(self : CastKind, other : CastKind) -> Int32 {
  self.rank().compare(other.rank())
}

///|
fn Exp::rank(self : Exp) -> Int32 {
  match self {
    Int(_) => 0
    Var(_) => 1
    Unknown(_) => 2
    Load(_) => 3
    Store(_) => 4
    Let(_) => 5
    Cast(_) => 6
    Extract(_) => 7
    Concat(_) => 8
    UnOp(_) => 9
    BinOp(_) => 10
    Ite(_) => 11
  }
}

///|
fn compare_exp_pair(
  left_first : Exp,
  left_second : Exp,
  right_first : Exp,
  right_second : Exp,
) -> Int32 {
  let first_order = left_first.compare(right_first)
  if first_order != 0 {
    return first_order
  }
  left_second.compare(right_second)
}

///|
pub fn Exp::equal(self : Exp, other : Exp) -> Bool {
  self == other
}

///|
pub fn Exp::compare(self : Exp, other : Exp) -> Int32 {
  let rank_order = self.rank().compare(other.rank())
  if rank_order != 0 {
    return rank_order
  }
  match (self, other) {
    (Int(left), Int(right)) => left.compare(right)
    (Var(left), Var(right)) => left.compare(right)
    (Unknown(left_name, left_type), Unknown(right_name, right_type)) => {
      let name_order = left_name.compare(right_name)
      if name_order != 0 {
        return name_order
      }
      left_type.compare(right_type)
    }
    (
      Load(mem=left_mem, addr=left_addr, endian=left_endian, typ=left_type),
      Load(mem=right_mem, addr=right_addr, endian=right_endian, typ=right_type),
    ) => {
      let mem_order = left_mem.compare(right_mem)
      if mem_order != 0 {
        return mem_order
      }
      let addr_order = left_addr.compare(right_addr)
      if addr_order != 0 {
        return addr_order
      }
      let endian_order = compare_endian(left_endian, right_endian)
      if endian_order != 0 {
        return endian_order
      }
      left_type.compare(right_type)
    }
    (
      Store(mem=left_mem, addr=left_addr, value=left_value, endian=left_endian),
      Store(
        mem=right_mem,
        addr=right_addr,
        value=right_value,
        endian=right_endian
      ),
    ) => {
      let mem_order = left_mem.compare(right_mem)
      if mem_order != 0 {
        return mem_order
      }
      let addr_order = left_addr.compare(right_addr)
      if addr_order != 0 {
        return addr_order
      }
      let value_order = left_value.compare(right_value)
      if value_order != 0 {
        return value_order
      }
      compare_endian(left_endian, right_endian)
    }
    (
      Let(left_var, left_value, left_body),
      Let(right_var, right_value, right_body),
    ) => {
      let var_order = left_var.compare(right_var)
      if var_order != 0 {
        return var_order
      }
      let value_order = left_value.compare(right_value)
      if value_order != 0 {
        return value_order
      }
      left_body.compare(right_body)
    }
    (
      Cast(kind=left_kind, width=left_width, exp=left_exp),
      Cast(kind=right_kind, width=right_width, exp=right_exp),
    ) => {
      let kind_order = left_kind.compare(right_kind)
      if kind_order != 0 {
        return kind_order
      }
      let width_order = left_width.compare(right_width)
      if width_order != 0 {
        return width_order
      }
      left_exp.compare(right_exp)
    }
    (
      Extract(hi=left_hi, lo=left_lo, exp=left_exp),
      Extract(hi=right_hi, lo=right_lo, exp=right_exp),
    ) => {
      let hi_order = left_hi.compare(right_hi)
      if hi_order != 0 {
        return hi_order
      }
      let lo_order = left_lo.compare(right_lo)
      if lo_order != 0 {
        return lo_order
      }
      left_exp.compare(right_exp)
    }
    (
      Concat(high=left_high, low=left_low),
      Concat(high=right_high, low=right_low),
    ) => compare_exp_pair(left_high, left_low, right_high, right_low)
    (UnOp(left_op, left_exp), UnOp(right_op, right_exp)) => {
      let op_order = left_op.compare(right_op)
      if op_order != 0 {
        return op_order
      }
      left_exp.compare(right_exp)
    }
    (BinOp(left_op, left_lhs, left_rhs), BinOp(right_op, right_lhs, right_rhs)) => {
      let op_order = left_op.compare(right_op)
      if op_order != 0 {
        return op_order
      }
      compare_exp_pair(left_lhs, left_rhs, right_lhs, right_rhs)
    }
    (
      Ite(cond=left_cond, yes=left_yes, no=left_no),
      Ite(cond=right_cond, yes=right_yes, no=right_no),
    ) => {
      let cond_order = left_cond.compare(right_cond)
      if cond_order != 0 {
        return cond_order
      }
      let yes_order = left_yes.compare(right_yes)
      if yes_order != 0 {
        return yes_order
      }
      left_no.compare(right_no)
    }
    _ => 0
  }
}

///|
fn Stmt::rank(self : Stmt) -> Int32 {
  match self {
    Move(_) => 0
    Jmp(_) => 1
    Special(_) => 2
    CpuExn(_) => 3
    If(_) => 4
    While(_) => 5
  }
}

///|
pub fn Stmt::equal(self : Stmt, other : Stmt) -> Bool {
  self == other
}

///|
pub fn Stmt::compare(self : Stmt, other : Stmt) -> Int32 {
  let rank_order = self.rank().compare(other.rank())
  if rank_order != 0 {
    return rank_order
  }
  match (self, other) {
    (Move(left_var, left_exp), Move(right_var, right_exp)) => {
      let var_order = left_var.compare(right_var)
      if var_order != 0 {
        return var_order
      }
      left_exp.compare(right_exp)
    }
    (Jmp(left), Jmp(right)) => left.compare(right)
    (Special(left), Special(right)) => left.compare(right)
    (CpuExn(left), CpuExn(right)) => left.compare(right)
    (
      If(cond=left_cond, yes=left_yes, no=left_no),
      If(cond=right_cond, yes=right_yes, no=right_no),
    ) => {
      let cond_order = left_cond.compare(right_cond)
      if cond_order != 0 {
        return cond_order
      }
      let yes_order = compare_array(left_yes, right_yes, Stmt::compare)
      if yes_order != 0 {
        return yes_order
      }
      compare_array(left_no, right_no, Stmt::compare)
    }
    (
      While(cond=left_cond, body=left_body),
      While(cond=right_cond, body=right_body),
    ) => {
      let cond_order = left_cond.compare(right_cond)
      if cond_order != 0 {
        return cond_order
      }
      compare_array(left_body, right_body, Stmt::compare)
    }
    _ => 0
  }
}
