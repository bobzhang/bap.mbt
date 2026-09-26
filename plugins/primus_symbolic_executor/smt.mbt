// The SMT layer of the executor (upstream module `SMT`): translation of
// Primus computations into Z3 bitvector terms, path formulas and
// satisfiability checks.
//
// As upstream, all symbolic values are bitvectors: boolean results of
// comparisons are coerced to 1-bit vectors, and every term is
// simplified after construction. A single global context and solver are
// shared by all machines.

///|
priv struct Smt {
  ctx : @z3.Context
  solver : @z3.Solver
  bit0 : @z3.Expr
  bit1 : @z3.Expr
}

///|
let smt_state : Ref[Smt?] = Ref(None)

///|
let smt_timeout : Ref[Int] = Ref(16)

///|
/// The global SMT context, created on first use. Raises
/// `@z3.Z3Error::Unavailable` when the solver cannot be loaded.
fn smt() -> Smt raise @z3.Z3Error {
  match smt_state.val {
    Some(s) => s
    None => {
      let ctx = @z3.Context::new(params=[("model", "true")])
      let solver = @z3.Solver::new(ctx, simple=true)
      solver.set_timeout(smt_timeout.val)
      let s = { ctx, solver, bit0: ctx.bv_int(0L, 1), bit1: ctx.bv_int(1L, 1), }
      smt_state.val = Some(s)
      s
    }
  }
}

///|
/// Sets the number of milliseconds allotted to the SMT solver to find a
/// model (the `timeout` option, 16 by default).
pub fn set_timeout(ms : Int) -> Unit {
  smt_timeout.val = ms
  if smt_state.val is Some(s) {
    s.solver.set_timeout(ms) catch {
      _ => ()
    }
  }
}

///|
/// Whether the SMT solver is available.
pub fn is_solver_available() -> Bool {
  @z3.is_available()
}

///|
fn coerce_to_bit(x : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  if x.is_bool() {
    let s = smt()
    s.ctx.ite(x, s.bit1, s.bit0).simplify()
  } else {
    x
  }
}

///|
fn coerce_to_bool(x : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  if x.is_bool() {
    x
  } else {
    x.eq(smt().bit1).simplify()
  }
}

///|
fn simpl(x : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  coerce_to_bit(x.simplify())
}

///|
/// Applies a shift whose operands may have different widths: the result
/// has the width of `x` (upstream zero-extends the shift amount; a wider
/// shift amount is handled by shifting in the wider width).
fn shift(
  op : @z3.BinOp,
  x : @z3.Expr,
  y : @z3.Expr,
) -> @z3.Expr raise @z3.Z3Error {
  let sx = x.bitwidth()
  let sy = y.bitwidth()
  if sx == sy {
    x.binop(op, y)
  } else if sy < sx {
    x.binop(op, y.zero_ext(sx - sy))
  } else {
    let wide = if op is Ashr {
      x.sign_ext(sy - sx)
    } else {
      x.zero_ext(sy - sx)
    }
    wide.binop(op, y).extract(sx - 1, 0)
  }
}

///|
fn z3_binop(
  op : @types.BinOp,
  x : @z3.Expr,
  y : @z3.Expr,
) -> @z3.Expr raise @z3.Z3Error {
  match op {
    Plus => x.add(y)
    Minus => x.sub(y)
    Times => x.mul(y)
    Div => x.udiv(y)
    SignedDiv => x.sdiv(y)
    // port: upstream maps MOD to `bvsrem` and SMOD to `bvurem`; BIL's MOD
    // is the unsigned and SMOD the signed remainder
    Mod => x.urem(y)
    SignedMod => x.srem(y)
    LShift => shift(Shl, x, y)
    RShift => shift(Lshr, x, y)
    ARShift => shift(Ashr, x, y)
    And => x.logand(y)
    Or => x.logor(y)
    Xor => x.logxor(y)
    Lt => x.ult(y)
    Le => x.ule(y)
    SignedLt => x.slt(y)
    SignedLe => x.sle(y)
    Eq => x.logxor(y).redor().lnot()
    Neq => x.logxor(y).redor()
  }
}

///|
fn smt_binop(
  op : @types.BinOp,
  x : @z3.Expr,
  y : @z3.Expr,
) -> @z3.Expr raise @z3.Z3Error {
  simpl(z3_binop(op, x, y))
}

///|
fn smt_unop(op : @types.UnOp, x : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  simpl(
    match op {
      Neg => x.neg()
      Not => x.lnot()
    },
  )
}

///|
fn smt_word(w : @types.Word) -> @z3.Expr raise @z3.Z3Error {
  smt().ctx.word(w)
}

///|
fn smt_var(name : String, size : Int) -> @z3.Expr raise @z3.Z3Error {
  smt().ctx.bv_const(name, size)
}

///|
fn smt_extract(hi : Int, lo : Int, x : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  let xs = x.bitwidth()
  let ns = hi - lo + 1
  simpl(
    if ns > xs {
      if lo == 0 {
        x.zero_ext(ns - xs)
      } else {
        x.zero_ext(ns - xs).extract(hi, lo)
      }
    } else {
      x.extract(hi, lo)
    },
  )
}

///|
fn smt_concat(x : @z3.Expr, y : @z3.Expr) -> @z3.Expr raise @z3.Z3Error {
  simpl(x.concat(y))
}

///|
fn smt_ite(
  c : @z3.Expr,
  x : @z3.Expr,
  y : @z3.Expr,
) -> @z3.Expr raise @z3.Z3Error {
  simpl(smt().ctx.ite(coerce_to_bool(c), x, y))
}

///|
fn smt_cast(
  c : @types.CastKind,
  s : Int,
  x : @z3.Expr,
) -> @z3.Expr raise @z3.Z3Error {
  let old = x.bitwidth()
  simpl(
    match c {
      Signed =>
        if old < s {
          x.sign_ext(s - old)
        } else {
          smt_extract(s - 1, 0, x)
        }
      Unsigned =>
        if old < s {
          x.zero_ext(s - old)
        } else {
          smt_extract(s - 1, 0, x)
        }
      High => smt_extract(old - 1, old - s, x)
      Low => smt_extract(s - 1, 0, x)
    },
  )
}

///|
/// The formula `x != 0`, or `x = 0` if `refute` (upstream
/// `SMT.formula`).
fn smt_formula(
  x : @z3.Expr,
  refute? : Bool = false,
) -> @z3.Expr raise @z3.Z3Error {
  let zero = smt().ctx.bv_int(0L, x.bitwidth())
  let f = zero.eq(x)
  if refute {
    f.simplify()
  } else {
    f.not().simplify()
  }
}

///|
/// Checks the conjunction of the formulas; unsatisfiable, unknown (e.g.,
/// timed out) and failed checks give `None`.
fn smt_check(formulas : Array[@z3.Expr]) -> @z3.Model? {
  smt().solver.check_formulas(formulas) catch {
    _ => None
  }
}

///|
/// The value that the model assigns to the input (a numeral).
fn model_get(model : @z3.Model, input : Input) -> @z3.Expr? {
  let v = smt_var(input.to_symbol(), input.size()) catch { _ => return None }
  let x = model.eval(v) catch { _ => return None }
  match x {
    Some(x) if x.is_numeral() => Some(x)
    _ => None
  }
}
