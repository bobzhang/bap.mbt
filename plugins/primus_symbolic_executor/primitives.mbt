// The Primus Lisp interface of the executor (upstream
// `SymbolicPrimitives` and `Primitives`, the
// `bap:symbolic-lisp-primitives` component).

///|
/// The payload of the `assert-failure` observation: the name of the
/// failed assertion and the model of the inputs that falsify it.
pub struct AssertFailure {
  name : String
  model : @z3.Model
  inputs : Array[Input]
}

///|
/// The values that the model of the failure assigns to the inputs, as
/// `(input symbol, SMT-LIB value)` pairs.
pub fn AssertFailure::values(self : AssertFailure) -> Array[(String, String)] {
  let out = []
  for input in self.inputs {
    if model_get(self.model, input) is Some(v) {
      out.push((input.to_symbol(), v.to_string()))
    }
  }
  out
}

///|
fn AssertFailure::to_sexp(self : AssertFailure) -> @primus.Sexp {
  List(
    [Atom(self.name)] +
    self.values().map(p => @primus.Sexp::List([Atom(p.0), Atom(p.1)])),
  )
}

///|
let assert_failure_pair : (
  @primus.Observation[AssertFailure],
  @primus.Statement[AssertFailure],
) = @primus.Observation::provide(
  "assert-failure",
  inspect=AssertFailure::to_sexp,
  desc="occurs when a symbolic executor assertion doesn't hold",
)

///|
/// `assert-failure (NAME (INPUT VALUE) ...)` occurs when a symbolic
/// executor assertion doesn't hold for some inputs.
pub let assert_failure : @primus.Observation[AssertFailure] = assert_failure_pair.0

///|
fn lisp_fail(m : @primus.Machine, msg : String) -> @primus.Value raise {
  @primus_lisp.failf(m, msg)
  m.raise_exn(@primus.PrimusError::RuntimeError(msg))
}

///|
fn to_int(v : @primus.Value) -> Int raise {
  v.to_word().to_int()
}

///|
fn arch_addr_size(m : @primus.Machine) -> Int {
  m.target().bits()
}

///|
fn with_memory(
  m : @primus.Machine,
  mem : SymMemory,
  f : () -> @primus.Value raise,
) -> @primus.Value raise {
  let current = @primus.Memory::memory(m)
  @primus.Memory::switch(m, mem.bank)
  defer @primus.Memory::switch(m, current)
  f()
}

///|
fn open_bank(m : @primus.Machine, id : @primus.Value) -> SymMemory raise {
  let name = @primus.Value::symbol_of_value(m, id)
  match m.get_global(memories).get(name) {
    Some(mem) => mem
    None => {
      ignore(lisp_fail(m, "unknown memory \{name}"))
      panic()
    }
  }
}

///|
fn register_memory(m : @primus.Machine, mem : SymMemory) -> Unit raise {
  let name = mem.bank.name()
  let mems = m.get_global(memories)
  match mems.get(name) {
    None => m.put_global(memories, mems.add(name, mem))
    Some(old) if old.same(mem) => ()
    Some(_) =>
      m.raise_exn(
        @primus.PrimusError::RuntimeError(
          "symbolic-memory: \{name} was previously defined with different parameters",
        ),
      )
  }
}

///|
/// `(symbolic-value NAME &rest)`
fn create_value(
  m : @primus.Machine,
  id : @primus.Value,
  rest : ArrayView[@primus.Value],
) -> @primus.Value raise {
  let width = match rest {
    [] => arch_addr_size(m)
    [s, ..] => to_int(s)
  }
  let name = @primus.Value::symbol_of_value(m, id)
  let v = @types.Var::create(name, Imm(width))
  if !@primus.Env::has(m, v) {
    let init = match rest {
      [_, x, ..] => to_int(x)
      _ => 0
    }
    @primus.Env::add(m, v, @primus.Generator::static_value(width~, init))
  }
  @primus.Env::get(m, v)
}

///|
/// `(symbolic-memory NAME LOWER UPPER &rest)`
fn create_memory(
  m : @primus.Machine,
  id : @primus.Value,
  lower : @primus.Value,
  upper : @primus.Value,
  rest : ArrayView[@primus.Value],
) -> @primus.Value raise {
  let lower = lower.to_word()
  let upper = upper.to_word()
  let data_size = match rest {
    [_, d] => to_int(d)
    _ => 8
  }
  let name = @primus.Value::symbol_of_value(m, id)
  if m.get_global(memories).get(name) is Some(_) {
    return id
  }
  let addr_size = match rest {
    [a, _] => to_int(a)
    [] | [_] => arch_addr_size(m)
    _ => return lisp_fail(m, "symbolic-memory: expects 3 to 5 arguments")
  }
  let bank = @primus.Descriptor::create(addr_size~, data_size~, name)
  let mem = { bank, lower, upper, }
  register_memory(m, mem)
  with_memory(m, mem, () => {
    allocate(m, bank, lower, upper)
    id
  })
}

///|
fn assume_(
  m : @primus.Machine,
  args : ArrayView[@primus.Value],
) -> @primus.Value {
  for x in args {
    match value_formula(m, x) {
      Some(f) => add_constraint(m, User, smt_formula(f) catch { _ => continue })
      None =>
        // should we raise on assert false?
        if x.is_zero() {
          let false_ = smt_formula(smt_word(@types.Word::b0())) catch {
            _ => continue
          }
          add_constraint(m, User, false_)
        }
    }
  }
  @primus.Value::b1(m)
}

///|
priv suberror NoFailure

///|
fn assertion(
  m : @primus.Machine,
  x : @primus.Value,
) -> @z3.Expr raise @z3.Z3Error {
  let v = match value_formula(m, x) {
    Some(f) => f
    None => smt_word(x.to_word())
  }
  smt_formula(v, refute=true)
}

///|
fn assert_(
  m : @primus.Machine,
  name : @primus.Value,
  args : ArrayView[@primus.Value],
) -> @primus.Value raise {
  // the report is computed only if the observation is observed; an
  // assertion that holds for all inputs is not reported
  m.post(assert_failure_pair.1, () => {
    let formulas = get_constraints(m, User)
      .union(get_constraints(m, Path))
      .to_array()
    for x in args {
      formulas.push(assertion(m, x) catch { _ => raise NoFailure })
    }
    guard smt_check(formulas) is Some(model) else { raise NoFailure }
    { name: @primus.Value::symbol_of_value(m, name), model, inputs: inputs(m), }
  }) catch {
    NoFailure => ()
    e => raise e
  }
  @primus.Value::b1(m)
}

///|
priv struct Primitive {
  name : String
  types : String
  docs : String
  run : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise
}

///|
fn arity_error(m : @primus.Machine, name : String) -> @primus.Value raise {
  lisp_fail(m, "\{name}: invalid number of arguments")
}

///|
let primitives : Array[Primitive] = [
  {
    name: "symbolic-assume",
    types: "(all bool) -> bool",
    docs: "Assumes the specified list of constraints.",
    run: (m, args) => assume_(m, args),
  },
  {
    name: "symbolic-assert",
    types: "(sym // all bool) -> bool",
    docs: "(assert NAME C1 ... CM) verifies the specified list of assertions C1 and posts the assert-failure observation for each condition that doesn't hold.",
    run: (m, args) => {
      match args {
        [name, .. rest] => assert_(m, name, rest)
        _ => arity_error(m, "symbolic-assert")
      }
    },
  },
  {
    name: "symbolic-value",
    types: "(sym // all int) -> a",
    docs: "(symbolic-value NAME &rest) creates a new symbolic value. Accepts up to two optional arguments. The first argument denotes the bitwidth of the created value and the second is the initial value.",
    run: (m, args) => {
      match args {
        [id, .. rest] => create_value(m, id, rest)
        _ => arity_error(m, "symbolic-value")
      }
    },
  },
  {
    name: "symbolic-memory",
    types: "(sym int int // all int) -> sym",
    docs: "(symbolic-memory NAME LOWER UPPER &rest) creates a new symbolic memory region with the given NAME and LOWER and UPPER bounds. The symbolic memory could be read and written with the SYMBOLIC-MEMORY-READ and SYMBOLIC-MEMORY-WRITE primitives. Optionally accepts one or two more arguments. If two optional arguments are provided, then the first one stands for the address bus size of the symbolic memory and the second for the data bus size, all in bits. If only one is provided then it is interpreted as the data bus size and the address size defaults to the architecture-specific address size (e.g., 64 bits for amd64). If none are provided then the address size is architecture-specific and the data size defaults to 8 bits.",
    run: (m, args) => {
      match args {
        [id, lower, upper, .. rest] => create_memory(m, id, lower, upper, rest)
        _ => arity_error(m, "symbolic-memory")
      }
    },
  },
  {
    name: "symbolic-memory-read",
    types: "(sym int) -> byte",
    docs: "(symbolic-memory-read MEM POS) reads the value of the symbolic memory MEM at the specified position POS.",
    run: (m, args) => {
      match args {
        [id, ptr] => {
          let mem = open_bank(m, id)
          with_memory(m, mem, () => @primus.Memory::get(m, ptr.to_word()))
        }
        _ => arity_error(m, "symbolic-memory-read")
      }
    },
  },
  {
    name: "symbolic-memory-write",
    types: "(sym int byte) -> byte",
    docs: "(symbolic-memory-write MEM POS X) writes X to the symbolic memory MEM at the specified position POS.",
    run: (m, args) => {
      match args {
        [id, ptr, data] => {
          let mem = open_bank(m, id)
          with_memory(m, mem, () => {
            @primus.Memory::set(m, ptr.to_word(), data)
            ptr
          })
        }
        _ => arity_error(m, "symbolic-memory-write")
      }
    },
  },
]

///|
/// The names of the Lisp primitives provided by the executor.
pub fn primitive_names() -> Array[String] {
  primitives.map(p => p.name)
}

///|
/// Defines the executor primitives in the Primus Lisp machine (the
/// `bap:symbolic-lisp-primitives` component).
pub fn install_lisp_primitives(m : @primus.Machine) -> Unit {
  for p in primitives {
    @primus_lisp.define_host_primitive(
      m,
      p.name,
      types=p.types,
      docs=p.docs,
      p.run,
    )
  }
}
