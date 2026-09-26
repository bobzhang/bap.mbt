// The symbolic computer (upstream `Executor`) and the symbolic context
// of assertions (upstream `Context`).

///|
/// The per-machine symbolic state: the formula of every symbolic Primus
/// value (by value identifier) and the inputs met so far.
priv struct ExecutorState {
  values : @sorted_map.SortedMap[Int64, @z3.Expr]
  inputs : @sorted_set.SortedSet[Input]
}

///|
let executor : @primus.State[ExecutorState] = @primus.State::declare_(
  uuid="e21aa0fe-bc37-48e3-b398-ce7e764843c8",
  name="symbolic-executor-formulae",
  _ => { values: @sorted_map.new(), inputs: @sorted_set.new(), },
)

///|
/// The debugging observation of the executor (`executor-debug`).
let debug_pair : (@primus.Observation[String], @primus.Statement[String]) = @primus.Observation::provide(
  "executor-debug",
  inspect=s => Atom(s),
  desc="debugging messages of the symbolic executor",
)

///|
/// `executor-debug MSG` is posted with the debugging messages of the
/// symbolic executor, prefixed with the machine identifier.
pub let executor_debug : @primus.Observation[String] = debug_pair.0

///|
fn debug(m : @primus.Machine, msg : String) -> Unit raise {
  let id = m.current()
  m.post(debug_pair.1, () => "\{id}: \{msg}")
}

///|
/// The symbolic formula of the value in the current machine (`None` for
/// concrete values).
pub fn value_formula(m : @primus.Machine, v : @primus.Value) -> @z3.Expr? {
  m.get_local(executor).values.get(v.id())
}

///|
/// The inputs met by the current machine.
pub fn inputs(m : @primus.Machine) -> Array[Input] {
  m.get_local(executor).inputs.to_array()
}

///|
fn to_formula(v : @primus.Value, f : @z3.Expr?) -> @z3.Expr raise @z3.Z3Error {
  match f {
    Some(x) => x
    None => smt_word(v.to_word())
  }
}

///|
/// Records the formula of `r`. Failures of the solver (e.g., sort
/// mismatches of ill-typed computations) leave `r` concrete.
fn put_value(
  m : @primus.Machine,
  r : @primus.Value,
  f : () -> @z3.Expr raise @z3.Z3Error,
) -> Unit {
  let x = f() catch { _ => return }
  m.update_local(executor, s => { ..s, values: s.values.add(r.id(), x), })
}

///|
fn lift1(
  m : @primus.Machine,
  x : @primus.Value,
  r : @primus.Value,
  f : (@z3.Expr) -> @z3.Expr raise @z3.Z3Error,
) -> Unit {
  guard value_formula(m, x) is Some(fx) else { return }
  put_value(m, r, () => f(fx))
}

///|
fn lift2(
  m : @primus.Machine,
  x : @primus.Value,
  y : @primus.Value,
  r : @primus.Value,
  f : (@z3.Expr, @z3.Expr) -> @z3.Expr raise @z3.Z3Error,
) -> Unit {
  let fx = value_formula(m, x)
  let fy = value_formula(m, y)
  if fx is None && fy is None {
    return
  }
  put_value(m, r, () => f(to_formula(x, fx), to_formula(y, fy)))
}

///|
fn lift3(
  m : @primus.Machine,
  x : @primus.Value,
  y : @primus.Value,
  z : @primus.Value,
  r : @primus.Value,
  f : (@z3.Expr, @z3.Expr, @z3.Expr) -> @z3.Expr raise @z3.Z3Error,
) -> Unit {
  let fx = value_formula(m, x)
  let fy = value_formula(m, y)
  let fz = value_formula(m, z)
  if fx is None && fy is None && fz is None {
    return
  }
  put_value(m, r, () => {
    f(to_formula(x, fx), to_formula(y, fy), to_formula(z, fz))
  })
}

///|
/// Makes the value `x` the symbolic input `origin` (upstream
/// `Executor.set_input`).
pub fn set_input(
  m : @primus.Machine,
  origin : Input,
  x : @primus.Value,
) -> Unit {
  let f = smt_var(origin.to_symbol(), origin.size()) catch { _ => return }
  m.update_local(executor, s => {
    inputs: s.inputs.add(origin),
    values: s.values.add(x.id(), f),
  })
}

///|
/// Installs the symbolic computer in the machine (the
/// `bap:symbolic-computer` component): computes a symbolic formula for
/// every Primus value that depends on an input, and makes every generated
/// variable and memory cell an input.
pub fn install_computer(m : @primus.Machine) -> Unit raise {
  // fail early and clearly when there is no solver
  ignore(smt()) catch {
    e => raise @primus.PrimusError::RuntimeError("symbolic executor: \{e}")
  }
  m.observe(@primus.binop, p => {
    let ((op, x, y), r) = p
    lift2(m, x, y, r, (a, b) => smt_binop(op, a, b))
  })
  m.observe(@primus.unop, p => {
    let ((op, x), r) = p
    lift1(m, x, r, a => smt_unop(op, a))
  })
  m.observe(@primus.extract, p => {
    let ((hi, lo, x), r) = p
    lift1(m, x, r, a => smt_extract(hi, lo, a))
  })
  m.observe(@primus.concat, p => {
    let ((x, y), r) = p
    lift2(m, x, y, r, smt_concat)
  })
  m.observe(@primus.ite, p => {
    let ((c, x, y), r) = p
    lift3(m, c, x, y, r, smt_ite)
  })
  m.observe(@primus.cast, p => {
    let ((c, w, x), r) = p
    lift1(m, x, r, a => smt_cast(c, w, a))
  })
  m.observe(@primus.load_generated, p => {
    let (addr, x) = p
    set_input(m, Ptr(bank=@primus.Memory::memory(m), addr~), x)
  })
  m.observe(@primus.var_generated, p => set_input(m, Var(p.0), p.1))
}

// ---------------------------------------------------------------------------
// The symbolic context: sets of assertions by scope

///|
/// The scope of an assertion: the `user` scope holds the assumptions made
/// with `symbolic-assume`, the `path` scope the branch conditions of the
/// current path.
pub(all) enum Scope {
  User
  Path
} derive(Eq, Debug)

///|
fn Scope::name(self : Scope) -> String {
  match self {
    User => "user"
    Path => "path"
  }
}

///|
let context : @primus.State[
  @sorted_map.SortedMap[String, @sorted_set.SortedSet[@z3.Expr]],
] = @primus.State::declare_(
  uuid="9538b1fa-b6c0-464a-b11e-22377a10b0b6",
  name="symbolic-context",
  _ => @sorted_map.new(),
)

///|
fn add_constraint(m : @primus.Machine, scope : Scope, x : @z3.Expr) -> Unit {
  m.update_local(context, s => {
    let xs = s.get(scope.name()).unwrap_or(@sorted_set.new())
    s.add(scope.name(), xs.add(x))
  })
}

///|
fn get_constraints(
  m : @primus.Machine,
  scope : Scope,
) -> @sorted_set.SortedSet[@z3.Expr] {
  m.get_local(context).get(scope.name()).unwrap_or(@sorted_set.new())
}

///|
/// The assertions of the scope in the current machine.
pub fn constraints(m : @primus.Machine, scope : Scope) -> Array[@z3.Expr] {
  get_constraints(m, scope).to_array()
}

///|
/// Installs the path constraint tracker (the
/// `bap:symbolic-path-constraints` component): the condition of every
/// evaluated symbolic branch is recorded in the `path` scope, as taken
/// (`c != 0`) or not taken (`c = 0`).
pub fn install_path_constraints(m : @primus.Machine) -> Unit {
  m.observe(@primus.eval_cond, x => {
    guard value_formula(m, x) is Some(v) else { return }
    let f = smt_formula(v, refute=x.is_zero()) catch { _ => return }
    add_constraint(m, Path, f)
  })
}

///|
pub extend Scope with Eq::{not_equal, equal}

///|
pub extend Scope with Debug::{to_repr}
