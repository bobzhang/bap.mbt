///|
/// The environment: values of variables and generators for uninitialized
/// variables (upstream `Primus.Env`). The environment is a local (per-fork)
/// state; all operations are static functions taking the machine.
pub struct Env {
  priv values : @sorted_map.SortedMap[VarKey, Value]
  priv random : @sorted_map.SortedMap[VarKey, Generator]
}

///|
fn env_to_sexp(env : Env) -> Sexp {
  let values = []
  env.values.each((k, v) => {
    values.push(
      Sexp::atoms([
        "set-var",
        k.0.name(),
        k.0.typ().to_string(),
        v.value.to_hex(),
      ]),
    )
  })
  let random = []
  env.random.each((k, g) => {
    random.push(List([Atom("gen-var"), Atom(k.0.name()), g.to_sexp()]))
  })
  List([List(values), List(random)])
}

///|
let env_state : State[Env] = State::declare_(
  inspect=env_to_sexp,
  uuid="44b24ea4-48fa-47e8-927e-f7ba65202743",
  name="environment",
  _ => {
    values: @sorted_map.SortedMap::new(),
    random: @sorted_map.SortedMap::new(),
  },
)

///|
let var_generated_stmt : Statement[(@types.Var, Value)] = Statement::provide(
  "var-generated",
  inspect=p => List([Atom(p.0.name()), p.1.to_sexp()]),
  pkg="bap",
  desc="Occurs when a new value is generated during the read operation",
)

///|
/// Occurs when a value of an uninitialized variable is generated
/// (upstream `Env.generated`).
pub let var_generated : Observation[(@types.Var, Value)] = var_generated_stmt.obs

///|
/// Registers a generator for the variable: reading it while it is unset
/// produces a fresh value from the generator (`Env.add`).
pub fn Env::add(m : Machine, v : @types.Var, gen : Generator) -> Unit {
  m.update_local(env_state, s => { ..s, random: s.random.add(VarKey(v), gen), })
}

///|
/// Sets the value of a variable (`Env.set`).
pub fn Env::set(m : Machine, v : @types.Var, x : Value) -> Unit {
  m.update_local(env_state, s => { ..s, values: s.values.add(VarKey(v), x), })
}

///|
/// Removes the value of a variable (`Env.del`).
pub fn Env::del(m : Machine, v : @types.Var) -> Unit {
  m.update_local(env_state, s => { ..s, values: s.values.remove(VarKey(v)), })
}

///|
/// Reads a variable (`Env.get`). Memory-typed variables evaluate to zero
/// of the target width; an unset immediate variable with a registered
/// generator gets a fresh generated value (posting `var_generated`);
/// otherwise `UndefinedVar` is raised.
pub fn Env::get(m : Machine, v : @types.Var) -> Value raise {
  let t = m.get_local(env_state)
  match t.values.get(VarKey(v)) {
    Some(x) => x
    None =>
      match v.typ() {
        Mem(_) => Value::zero(m, target_bits(m.target()))
        Imm(width) =>
          match t.random.get(VarKey(v)) {
            None => m.raise_exn(UndefinedVar(v))
            Some(gen) => {
              let x = Value::of_word(m, Generator::word(m, gen, width))
              Env::set(m, v, x)
              m.make(var_generated_stmt, (v, x))
              x
            }
          }
      }
  }
}

///|
/// Whether the variable has a value (`Env.is_set`).
pub fn Env::is_set(m : Machine, v : @types.Var) -> Bool {
  m.get_local(env_state).values.contains(VarKey(v))
}

///|
/// Whether the variable has a value or a generator (`Env.has`).
pub fn Env::has(m : Machine, v : @types.Var) -> Bool {
  let t = m.get_local(env_state)
  t.values.contains(VarKey(v)) || t.random.contains(VarKey(v))
}

///|
/// All variables with a value or a generator (`Env.all`).
pub fn Env::all(m : Machine) -> Array[@types.Var] {
  let t = m.get_local(env_state)
  let out = []
  t.values.each((k, _) => out.push(k.0))
  t.random.each((k, _) => if !t.values.contains(k) { out.push(k.0) })
  out
}

///|
/// Renders the environment of the current machine.
pub fn Env::inspect(m : Machine) -> Sexp {
  env_to_sexp(m.get_local(env_state))
}
