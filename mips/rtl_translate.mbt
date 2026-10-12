// Lowering of RTL statements to BIL; port of `Mips_rtl.Translate`.

///|
fn expand_vars(body : Body) -> Array[@types.Var] {
  match body {
    Vars(v, vs) => [v, ..vs]
    Concat(x, y) => expand_vars(x) + expand_vars(y)
    Cast(_) | Extract(_) | Load(_) | Word(_) | Binop(_) | Unop(_) => []
  }
}

///|
fn partial_assign(
  v : @types.Var,
  hi_var : Int32,
  lo_var : Int32,
  rhs : Exp,
  hi_exp : Int32,
  lo_exp : Int32,
) -> @types.Stmt raise @mc.LiftError {
  let width = var_bitwidth(v)
  let rhs = if hi_exp - lo_exp + 1 == rhs.width {
    rhs
  } else {
    rhs.extract(hi_exp, lo_exp)
  }
  let whole = @types.Exp::var_exp(v)
  let middle = bil_exp(rhs.body)
  let left = if width - hi_var - 1 == 0 {
    None
  } else {
    Some(whole.extract(hi=width - 1, lo=hi_var + 1))
  }
  let right = if lo_var == 0 {
    None
  } else {
    Some(whole.extract(hi=lo_var - 1, lo=0))
  }
  let value = match (left, right) {
    (None, None) => middle
    (Some(left), None) => @types.Exp::concat(left, middle)
    (None, Some(right)) => @types.Exp::concat(middle, right)
    (Some(left), Some(right)) =>
      @types.Exp::concat(left, @types.Exp::concat(middle, right))
  }
  Move(v, value)
}

///|
/// Assign `rhs` to bits `hi..lo` of the concatenation `vars` (most
/// significant variable first).
fn assign_vars(
  vars : Array[@types.Var],
  hi? : Int32,
  lo~ : Int32 = 0,
  rhs : Exp,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let vars = vars.rev()
  let full = width_of_vars(vars)
  let hi = hi.unwrap_or(full - 1)
  let rhs = rhs.cast(hi - lo + 1, rhs.sign)
  let rhs_width = rhs.width
  fn in_bounds(x : Int32) {
    x <= hi && x >= lo
  }

  let stmts : Array[@types.Stmt] = []
  let mut assigned = 0
  let mut vars_lo = 0
  for v in vars {
    let width = var_bitwidth(v)
    let vars_hi = width + vars_lo - 1
    if hi < width || in_bounds(vars_lo) || in_bounds(vars_hi) {
      let lo_var = (if lo > vars_lo { lo } else { vars_lo }) - vars_lo
      let hi_var = (if rhs_width + lo - 1 < vars_hi {
          rhs_width + lo - 1
        } else {
          vars_hi
        }) -
        vars_lo
      let bits = hi_var - lo_var + 1
      let hi_exp = assigned + bits - 1
      // upstream prepends each assignment, so the last variable comes first
      stmts.insert(0, partial_assign(v, hi_var, lo_var, rhs, hi_exp, assigned))
      assigned += bits
    }
    vars_lo += width
  }
  stmts
}

///|
/// Valid forms of assignment:
/// 1) `var := exp`
/// 2) `var1 ^ var2 ... varN := exp` (concatenation)
/// 3) `extract hi lo var := exp` - changes only some bits of `var`
/// 4) `extract hi lo (var1 ^ ... varN) := exp`
fn translate_move(
  lhs : Exp,
  rhs : Exp,
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
    // writes to the hardwired zero register (a constant) are discarded
    Word(_) => []
    _ => raise mips_fail("unexpected left side of :=")
  }
}

///|
fn stmt_to_bil(rtl : Rtl) -> Array[@types.Stmt] raise @mc.LiftError {
  match rtl {
    Move(x, y) => translate_move(x, y)
    Jmp(a) => [Jmp(bil_exp(a.body))]
    If(cond, then_, else_) =>
      [
        @types.Stmt::if_(
          bil_exp(cond.body),
          rtl_to_bil(then_),
          rtl_to_bil(else_),
        ),
      ]
    Store(mem, addr, data, endian, size) => {
      let bits = size.in_bits()
      let data = if bits == data.width {
        data
      } else {
        data.extract(bits - 1, 0)
      }
      [
        Move(
          mem,
          @types.Exp::store(
            mem=@types.Exp::var_exp(mem),
            addr=bil_exp(addr.body),
            bil_exp(data.body),
            endian,
            size,
          ),
        ),
      ]
    }
    Foreach(inverse, step, e, code) => {
      let stepw = step.width
      let iters = e.width / stepw
      let has_assignments = has_assignments(var_of_exp(step), code)
      let expanded : Array[Rtl] = []
      for n in 0..<iters {
        let i = if inverse { iters - n - 1 } else { n }
        let hi = (i + 1) * stepw - 1
        let lo = i * stepw
        expanded.push(step.assign(e.extract(hi, lo)))
        expanded.push_iter(code.iter())
        if has_assignments {
          expanded.push(e.extract(hi, lo).assign(step))
        }
      }
      rtl_to_bil(expanded)
    }
  }
}

///|
fn rtl_to_bil(rtl : ArrayView[Rtl]) -> Array[@types.Stmt] raise @mc.LiftError {
  let out : Array[@types.Stmt] = []
  for s in rtl {
    out.push_iter(stmt_to_bil(s).iter())
  }
  out
}

///|
fn bil_assigns(stmts : Array[@types.Stmt], v : @types.Var) -> Bool {
  stmts
  .iter()
  .any(s => {
    match s {
      Move(x, _) => x == v
      If(yes~, no~, ..) => bil_assigns(yes, v) || bil_assigns(no, v)
      While(body~, ..) => bil_assigns(body, v)
      Jmp(_) | Special(_) | CpuExn(_) => false
    }
  })
}

///|
fn has_assignments(
  v : @types.Var,
  code : Array[Rtl],
) -> Bool raise @mc.LiftError {
  bil_assigns(rtl_to_bil(code), v)
}
