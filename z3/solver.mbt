///|
/// The result of a satisfiability check.
pub(all) enum CheckResult {
  Sat
  Unsat
  Unknown
} derive(Eq, Debug)

///|
/// An incremental Z3 solver with a stack of assertion scopes.
pub struct Solver {
  priv ctx : Context
  priv raw : RawSolver
}

///|
/// Creates a solver. With `simple=true` it is the plain incremental SMT
/// solver (`Z3_mk_simple_solver`, used by the symbolic executor),
/// otherwise the default combined solver.
pub fn Solver::new(
  ctx : Context,
  simple~ : Bool = false,
) -> Solver raise Z3Error {
  let raw = raw_mk_solver(ctx.raw, if simple { 1 } else { 0 })
  ctx.check()
  if raw_solver_is_null(raw) {
    raise Failure("unable to create a solver")
  }
  { ctx, raw, }
}

///|
/// Limits each check to `ms` milliseconds (0 disables the limit); a check
/// that times out returns `Unknown`.
pub fn Solver::set_timeout(self : Solver, ms : Int32) -> Unit raise Z3Error {
  raw_solver_set_uint(self.ctx.raw, self.raw, c_string("timeout"), ms)
  self.ctx.check()
}

///|
/// Opens a new assertion scope.
pub fn Solver::push(self : Solver) -> Unit raise Z3Error {
  raw_solver_push(self.ctx.raw, self.raw)
  self.ctx.check()
}

///|
/// Closes the `n` innermost scopes, removing their assertions.
pub fn Solver::pop(self : Solver, n~ : Int32 = 1) -> Unit raise Z3Error {
  raw_solver_pop(self.ctx.raw, self.raw, n)
  self.ctx.check()
}

///|
/// Removes all assertions and scopes.
pub fn Solver::reset(self : Solver) -> Unit raise Z3Error {
  raw_solver_reset(self.ctx.raw, self.raw)
  self.ctx.check()
}

///|
/// The number of open scopes.
pub fn Solver::num_scopes(self : Solver) -> Int32 {
  raw_solver_num_scopes(self.ctx.raw, self.raw)
}

///|
/// Asserts a boolean formula in the current scope.
pub fn Solver::add(self : Solver, formula : Expr) -> Unit raise Z3Error {
  raw_solver_assert(self.ctx.raw, self.raw, formula.raw)
  self.ctx.check()
}

///|
/// Checks the satisfiability of the assertions.
pub fn Solver::check(self : Solver) -> CheckResult {
  let r = raw_solver_check(self.ctx.raw, self.raw)
  // a canceled or timed out check is reported as unknown
  if raw_error_code(self.ctx.raw) != 0 {
    return Unknown
  }
  match r {
    1 => Sat
    -1 => Unsat
    _ => Unknown
  }
}

///|
/// Why the last check returned `Unknown`.
pub fn Solver::reason_unknown(self : Solver) -> String {
  bytes_to_string(raw_solver_reason_unknown(self.ctx.raw, self.raw))
}

///|
/// The model of the last satisfiable check.
pub fn Solver::model(self : Solver) -> Model raise Z3Error {
  let raw = raw_solver_model(self.ctx.raw, self.raw)
  self.ctx.check()
  if raw_model_is_null(raw) {
    raise Failure("no model is available")
  }
  { ctx: self.ctx, raw, }
}

///|
/// The assertions of the solver in the SMT-LIB format.
pub fn Solver::to_string(self : Solver) -> String {
  bytes_to_string(raw_solver_to_string(self.ctx.raw, self.raw))
}

///|
/// Checks the conjunction of the formulas in a fresh scope and returns
/// the model if it is satisfiable (the upstream `SMT.check`: unsatisfiable
/// and unknown results give `None`).
pub fn Solver::check_formulas(
  self : Solver,
  formulas : Array[Expr],
) -> Model? raise Z3Error {
  self.push()
  defer (self.pop() catch { _ => () })
  for f in formulas {
    self.add(f)
  }
  match self.check() {
    Sat => Some(self.model())
    Unsat | Unknown => None
  }
}

///|
/// A model: an assignment of values to the constants of a formula.
pub struct Model {
  priv ctx : Context
  priv raw : RawModel
}

///|
/// Evaluates a term in the model. With `completion=true` the constants
/// that the model does not assign get default values.
pub fn Model::eval(
  self : Model,
  x : Expr,
  completion~ : Bool = false,
) -> Expr? raise Z3Error {
  let raw = raw_model_eval(self.ctx.raw, self.raw, x.raw, completion)
  self.ctx.check()
  if raw_ast_is_null(raw) {
    None
  } else {
    Some({ ctx: self.ctx, raw, })
  }
}

///|
/// The value of a bitvector term in the model as a word, if the model
/// assigns it a numeral.
pub fn Model::eval_word(
  self : Model,
  x : Expr,
  completion~ : Bool = false,
) -> @types.Word? raise Z3Error {
  match self.eval(x, completion~) {
    Some(v) => v.to_word()
    None => None
  }
}

///|
/// The model in the Z3 textual format.
pub fn Model::to_string(self : Model) -> String {
  bytes_to_string(raw_model_to_string(self.ctx.raw, self.raw))
}
