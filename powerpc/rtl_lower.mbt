// Lowering of RTL programs to BIL (`Powerpc_rtl.Translate`).

///|
fn bil_exp(body : RtlBody) -> @types.Exp {
  match body {
    Vars(v, vars) =>
      vars.fold(init=Var(v), (e, v) => Concat(high=e, low=Var(v)))
    Word(w) => Int(w)
    Load(mem, addr, endian, size) =>
      Load(mem=Var(mem), addr=bil_exp(addr), endian~, typ=Imm(size.in_bits()))
    Concat(x, y) => Concat(high=bil_exp(x), low=bil_exp(y))
    Binop(op, x, y) => BinOp(op, bil_exp(x), bil_exp(y))
    Extract(hi, lo, x) => Extract(hi~, lo~, exp=bil_exp(x))
    Cast(_, 1, x) => Cast(kind=Low, width=1, exp=bil_exp(x))
    Cast(Signed, width, x) => Cast(kind=Signed, width~, exp=bil_exp(x))
    Cast(Unsigned, width, x) => Cast(kind=Unsigned, width~, exp=bil_exp(x))
    Unop(op, x) => UnOp(op, bil_exp(x))
  }
}

///|
/// Lower an RTL expression to a BIL expression.
pub fn RtlExp::to_bil(self : RtlExp) -> @types.Exp {
  bil_exp(self.body)
}

///|
fn lower_fail(message : String) -> @mc.LiftError {
  Failure("PowerPC lifter fail: " + message)
}

///|
fn expand_vars(body : RtlBody) -> Array[@types.Var] {
  match body {
    Vars(v, vs) => [v, ..vs]
    Concat(x, y) => expand_vars(x) + expand_vars(y)
    _ => []
  }
}

///|
fn partial_assign(
  v : @types.Var,
  hi_var : Int32,
  lo_var : Int32,
  rhs : RtlExp,
  hi_exp : Int32,
  lo_exp : Int32,
) -> @types.Stmt {
  let width = var_bitwidth(v)
  let rhs = if hi_exp - lo_exp + 1 == rhs.width {
    rhs
  } else {
    rhs.extract(hi_exp, lo_exp)
  }
  let var_e : @types.Exp = Var(v)
  let left : @types.Exp? = if width - hi_var - 1 == 0 {
    None
  } else {
    Some(Extract(hi=width - 1, lo=hi_var + 1, exp=var_e))
  }
  let middle = bil_exp(rhs.body)
  let right : @types.Exp? = if lo_var == 0 {
    None
  } else {
    Some(Extract(hi=lo_var - 1, lo=0, exp=var_e))
  }
  let value : @types.Exp = match (left, right) {
    (None, None) => middle
    (Some(left), None) => Concat(high=left, low=middle)
    (None, Some(right)) => Concat(high=middle, low=right)
    (Some(left), Some(right)) =>
      Concat(high=left, low=Concat(high=middle, low=right))
  }
  Move(v, value)
}

///|
/// Assign `rhs` to bits `hi..lo` of the concatenation of `vars` (most
/// significant first).
fn assign_vars(
  vars : Array[@types.Var],
  hi? : Int32,
  lo~ : Int32 = 0,
  rhs : RtlExp,
) -> Array[@types.Stmt] {
  let vars = vars.rev()
  let full = width_of_vars(vars)
  let hi = hi.unwrap_or(full - 1)
  let rhs = rhs.cast(hi - lo + 1, rhs.sign)
  let rhs_width = rhs.width
  let in_bounds = (x : Int32) => x <= hi && x >= lo
  let mut es : Array[@types.Stmt] = []
  let mut assigned = 0
  let mut vars_lo = 0
  for v in vars {
    let width = var_bitwidth(v)
    let vars_hi = width + vars_lo - 1
    if hi < width || in_bounds(vars_lo) || in_bounds(vars_hi) {
      let lo_var = Int32::max(lo, vars_lo) - vars_lo
      let hi_var = Int32::min(rhs_width + lo - 1, vars_hi) - vars_lo
      let bits_to_assign = hi_var - lo_var + 1
      let hi_exp = assigned + bits_to_assign - 1
      let lo_exp = assigned
      es = [partial_assign(v, hi_var, lo_var, rhs, hi_exp, lo_exp), ..es]
      assigned += bits_to_assign
    }
    vars_lo += width
  }
  es
}

///|
/// Valid forms of assignment:
/// 1. `var := exp`
/// 2. `var1 ^ var2 ... varN := exp`
/// 3. `extract hi lo var := exp` - change only certain bits of `var`
/// 4. `extract hi lo (var1 ^ var2 ... varN) := exp`
fn lower_move(
  lhs : RtlExp,
  rhs : RtlExp,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match lhs.body {
    Vars(v, []) => {
      let rhs = rhs.cast(lhs.width, lhs.sign)
      [Move(v, bil_exp(rhs.body))]
    }
    Vars(v, vars) => assign_vars([v, ..vars], rhs)
    Concat(x, y) => {
      let vars = expand_vars(x) + expand_vars(y)
      let rhs = rhs.cast(width_of_vars(vars), rhs.sign)
      assign_vars(vars, rhs)
    }
    Extract(hi, lo, x) => assign_vars(expand_vars(x), hi~, lo~, rhs)
    _ => raise lower_fail("unexpected left side of :=")
  }
}

///|
fn has_assignments(
  v : @types.Var,
  code : Array[Rtl],
) -> Bool raise @mc.LiftError {
  @types.exists_stmt(bil_of_rtl(code), stmt => stmt is Move(w, _) && w == v)
}

///|
fn lower_stmt(rtl : Rtl, out : Array[@types.Stmt]) -> Unit raise @mc.LiftError {
  match rtl {
    Move(x, y) => out.append(lower_move(x, y))
    Jmp(a) => out.push(Jmp(bil_exp(a.body)))
    If(cond, then_, else_) =>
      out.push(
        If(cond=bil_exp(cond.body), yes=bil_of_rtl(then_), no=bil_of_rtl(else_)),
      )
    Message(m) => out.push(Special(m))
    Store(mem, addr, data, endian, size) => {
      let bits = size.in_bits()
      let data = if bits == data.width {
        data
      } else {
        data.extract(bits - 1, 0)
      }
      out.push(
        Move(
          mem,
          Store(
            mem=Var(mem),
            addr=bil_exp(addr.body),
            value=bil_exp(data.body),
            endian~,
          ),
        ),
      )
    }
    Foreach(inverse, step, e, code) => {
      let stepw = step.width
      let iters = e.width / stepw
      let step_var = match step.body {
        Vars(v, _) => v
        _ => raise lower_fail("variable expected")
      }
      let write_back = has_assignments(step_var, code)
      let unrolled : Array[Rtl] = []
      for k in 0..<iters {
        let i = if inverse { iters - k - 1 } else { k }
        let hi = (i + 1) * stepw - 1
        let lo = i * stepw
        unrolled.push(step.set(e.extract(hi, lo)))
        unrolled.append(code)
        if write_back {
          unrolled.push(e.extract(hi, lo).set(step))
        }
      }
      out.append(bil_of_rtl(unrolled))
    }
  }
}

///|
/// Lower an RTL program to BIL.
pub fn bil_of_rtl(
  rtl : ArrayView[Rtl],
) -> Array[@types.Stmt] raise @mc.LiftError {
  let out = []
  for stmt in rtl {
    lower_stmt(stmt, out)
  }
  out
}
