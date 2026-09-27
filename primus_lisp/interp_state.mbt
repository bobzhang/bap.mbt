// The state of the Primus Lisp interpreter (upstream `Bap_primus_lisp`
// state, observations, and the runtime errors).

///|
/// Runtime errors of the Lisp interpreter.
pub(all) suberror LispRuntimeError {
  /// upstream `Runtime_error`, the message includes the location
  RuntimeError(String)
  /// upstream `Unresolved`: a name could not be resolved to a definition
  UnresolvedName(String, String)
}

///|
pub impl Show for LispRuntimeError with fn output(self, logger) {
  match self {
    RuntimeError(msg) =>
      logger.write_string("Primus Lisp runtime error - \{msg}")
    UnresolvedName(name, why) =>
      logger.write_string("unable to resolve function \{name}, because \{why}")
  }
}

///|
fn install_error_printer() -> Unit {
  @primus.exn_add_printer(e => {
    match e {
      RuntimeError(msg) => Some(RuntimeError(msg).to_string())
      UnresolvedName(n, why) => Some(UnresolvedName(n, why).to_string())
      _ => None
    }
  })
}

///|
/// The advisors of a function: the functions called before and after it.
priv struct Advisors {
  before : Array[@knowledge.Name]
  after : Array[@knowledge.Name]
}

///|
/// The per-machine (per-fork) state of the Lisp interpreter. All fields are
/// persistent values, so forking a machine is O(1).
priv struct LState {
  program : Program
  typed : TypedProgram?
  advices : @sorted_map.SortedMap[(String, String), Advisors]
  places : @sorted_map.SortedMap[(String, String), @types.Var]
  width : Int
  /// local (dynamically scoped) bindings: variable name -> value
  env : @sorted_map.SortedMap[String, @primus.Value]
  /// the identifier of the expression being evaluated
  cur : Int
  /// the value that is passed through cleanup frames
  ret : @primus.Value?
  /// the error message that is passed through handler frames
  failure : String?
}

///|
fn width_of_project(proj : @project.Project) -> Int {
  let b = proj.target().bits()
  if b <= 0 {
    32
  } else {
    b
  }
}

///|
let lisp_state : @primus.State[LState] = {
  install_error_printer()
  @primus.State::declare_(
    uuid="0360697d-febe-4982-a528-152ada72bf4a",
    name="lisp-env",
    inspect=s => {
      let bs = s.env
        .iter()
        .map(kv => @primus.Sexp::List([Atom(kv.0), Atom(kv.1.to_string())]))
        .collect()
      List(bs)
    },
    proj => {
      program: Program::empty(),
      typed: None,
      advices: @sorted_map.SortedMap::new(),
      places: @sorted_map.SortedMap::new(),
      width: width_of_project(proj),
      env: @sorted_map.SortedMap::new(),
      cur: 0,
      ret: None,
      failure: None,
    },
  )
}

///|
fn get_state(m : @primus.Machine) -> LState {
  m.get_local(lisp_state)
}

///|
fn put_state(m : @primus.Machine, s : LState) -> Unit {
  m.put_local(lisp_state, s)
}

///|
fn update_state(m : @primus.Machine, f : (LState) -> LState) -> Unit {
  m.update_local(lisp_state, f)
}

///|
let message_obs : (@primus.Observation[String], @primus.Statement[String]) = @primus.Observation::provide(
  "lisp-message",
  desc="Occurs with X when (msg x) is evaluated.",
  inspect=s => Atom(s),
)

///|
/// Occurs with the message `X` when `(msg x)` is evaluated (upstream
/// `Lisp.message`).
pub let message : @primus.Observation[String] = message_obs.0

///|
let primitive_obs : (
  @primus.Observation[(String, Array[@primus.Value])],
  @primus.Statement[(String, Array[@primus.Value])],
) = @primus.Observation::provide(
  "lisp-primitive",
  desc="Occurs when the Lisp primitive is invoked.",
  inspect=call => {
    List(
      [@primus.Sexp::Atom(call.0)] +
      call.1.map(v => @primus.Sexp::Atom(v.to_string())),
    )
  },
)

///|
/// Occurs when a Lisp primitive is invoked, with the name, the arguments,
/// and the result (the last element) of the call (upstream
/// `Lisp.primitive`).
pub let primitive_called : @primus.Observation[(String, Array[@primus.Value])] = primitive_obs.0

///|
let type_error_obs : (
  @primus.Observation[TypeError],
  @primus.Statement[TypeError],
) = @primus.Observation::provide(
  "lisp-type-error",
  desc="Occurs when the Lisp type error is detected by the type checker",
  inspect=err => Atom(err.to_string()),
)

///|
/// Occurs when the type checker detects a type error (upstream
/// `Lisp.Type.error`).
pub let type_error : @primus.Observation[TypeError] = type_error_obs.0

///|
/// The Lisp program of the machine.
pub fn program(m : @primus.Machine) -> Program {
  get_state(m).program
}

///|
/// The typed program of the machine (after `typecheck`).
pub fn types(m : @primus.Machine) -> TypedProgram? {
  get_state(m).typed
}

///|
/// Refines the context of the program of the machine (upstream
/// `Lisp.refine`).
pub fn refine(m : @primus.Machine, ctxt : Context) -> Unit {
  update_state(m, s => {
    ..s,
    program: s.program.with_context(ctxt.merge(s.program.context)),
  })
}

///|
/// Raises a runtime error that is annotated with the location of the
/// expression being evaluated (upstream `failf`).
pub fn failf(m : @primus.Machine, msg : String) -> Unit raise {
  let s = get_state(m)
  let loc = s.program.sources.loc(s.cur)
  m.raise_exn(RuntimeError("\{loc}\n\{msg}"))
}
