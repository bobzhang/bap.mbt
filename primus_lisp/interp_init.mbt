// Initialization of the Lisp runtime in a Primus machine: the standard
// signals (upstream `Primus_lisp_main.Signals`), the IO and IEEE754
// primitives, and the components.

///|
fn sym_arg(m : @primus.Machine, s : String) -> @primus.Value raise {
  @primus.Value::symbol_to_value(m, s)
}

///|
/// Reflects the standard observations into signals (upstream
/// `Primus_lisp_main.Signals.init`).
pub fn init_signals(m : @primus.Machine) -> Unit {
  let bits = addr_width(m)
  let int : Typ = Type(bits)
  let byte : Typ = Type(8)
  let bool : Typ = Type(1)
  let sym : Typ = Symbol
  let any : Typ = Any
  let one = (t : Typ) => arrow(Tuple([t]), Any)
  let pair = (a : Typ, b : Typ) => arrow(Tuple([a, b]), Any)
  let unit = arrow(Tuple([]), Any)
  let call_params = arrow(Gen([sym], any), Any)
  ignore(
    signal(
      m,
      @primus.loading,
      sync=true,
      params=one(int),
      docs="(loading A) is emitted before load from A occurs",
      (_, x) => [x],
    ),
  )
  ignore(
    signal(
      m,
      @primus.loaded,
      params=pair(int, byte),
      docs="(loaded A X) is emitted when X is loaded from A",
      (_, x) => [x.0, x.1],
    ),
  )
  ignore(
    signal(
      m,
      @primus.storing,
      sync=true,
      params=one(int),
      docs="(storing A) is emitted before store to A occurs",
      (_, x) => [x],
    ),
  )
  ignore(
    signal(
      m,
      @primus.stored,
      params=pair(int, byte),
      docs="(stored A X) is emitted when X is stored to A",
      (_, x) => [x.0, x.1],
    ),
  )
  ignore(
    signal(
      m,
      @primus.read,
      params=pair(sym, any),
      docs="(read V X) is emitted when X is read from V",
      (m, x) => [sym_arg(m, x.0.name), x.1],
    ),
  )
  ignore(
    signal(
      m,
      @primus.written,
      params=pair(sym, any),
      docs="(written V X) is emitted when X is written to V",
      (m, x) => [sym_arg(m, x.0.name), x.1],
    ),
  )
  ignore(
    signal(
      m,
      @primus.pc_change,
      params=one(int),
      docs="(pc-change PC) is emitted when PC is updated",
      (m, x) => [@primus.Value::of_word(m, x)],
    ),
  )
  ignore(
    signal(
      m,
      @primus.jumping,
      params=pair(bool, int),
      docs="(jumping C D) is emitted before jump to D occurs under the condition C",
      (_, x) => [x.0, x.1],
    ),
  )
  ignore(
    signal(
      m,
      @primus.call,
      params=call_params,
      docs="(call NAME X Y ...) is emitted when a call to a function with the symbolic NAME occurs with the specified list of arguments X,Y,...",
      (m, x) => [sym_arg(m, x.0)] + x.1,
    ),
  )
  ignore(
    signal(
      m,
      @primus.call_return,
      params=call_params,
      docs="(call-return NAME X Y ... R) is emitted when a call to a function with the symbolic NAME returns with the specified list of arguments X,Y,... and return value R.",
      (m, x) => [sym_arg(m, x.0)] + x.1,
    ),
  )
  ignore(
    signal(
      m,
      @primus.interrupt,
      params=one(int),
      docs="(interrupt N) is emitted when the hardware interrupt N occurs",
      (m, x) => [@primus.Value::of_int(m, width=bits, x)],
    ),
  )
  ignore(
    signal(
      m,
      @primus.system_stop,
      params=one(sym),
      docs="(system-stop NAME) occurs when the system with the given name finished its execution",
      (m, x) => [sym_arg(m, x)],
    ),
  )
  ignore(
    signal(
      m,
      @primus.system_init,
      params=unit,
      docs="(init) occurs when the Primus Machine is initialized",
      (_, _) => [],
    ),
  )
  ignore(
    signal(
      m,
      @primus.system_fini,
      params=unit,
      docs="(fini) occurs when the Primus Machine is finished",
      (_, _) => [],
    ),
  )
  ignore(
    signal(
      m,
      @primus.machine_kill,
      params=unit,
      docs="(machine-kill) occurs when Machine is killed",
      (_, _) => [],
    ),
  )
}

// ---------------------------------------------------------------------------
// IEEE754 primitives (upstream `Primus_lisp_ieee754`), implemented with the
// host floating-point arithmetic for the binary32 and binary64 formats.

///|
fn float_of_value(v : @primus.Value) -> Double {
  let w = v.to_word()
  if w.bitwidth() == 32 {
    let bits = (try! resize(w, 32).to_uint64()).to_uint()
    Float::reinterpret_from_uint(bits).to_double()
  } else {
    double_of_word(w)
  }
}

///|
fn value_of_float(
  m : @primus.Machine,
  width : Int,
  x : Double,
) -> @primus.Value {
  if width == 32 {
    let bits = Float::from_double(x).reinterpret_as_uint()
    @primus.Value::of_word(
      m,
      try! @types.Word::of_uint64(width=32, bits.to_uint64()),
    )
  } else {
    @primus.Value::of_word(m, word_of_double(x, 64))
  }
}

///|
priv enum FloatOp {
  Inf((Double, Double) -> Double)
  Pre((Double) -> Double)
  Cti((Double) -> Int64)
  Ord((Double, Double) -> Bool)
  Cnd((Double) -> Bool)
}

///|
fn ieee754_primitive(name : String, op : FloatOp) -> Closure {
  Closure::sync((m, _, args) => {
    match args {
      [] | [_] => {
        failf(m, "\{name}: type error - expects 2 or more arguments")
        @primus.Value::b0(m)
      }
      [sz, x, .. ops] => {
        let width = match word_to_int(sz.to_word()) {
          Some(32) => 32
          Some(64) => 64
          _ => {
            failf(m, "\{name}: only 32 or 64 bit binary formats are supported")
            64
          }
        }
        let x = float_of_value(x)
        match op {
          Inf(f) =>
            value_of_float(
              m,
              width,
              ops.fold(init=x, (acc, y) => f(acc, float_of_value(y))),
            )
          Pre(f) => value_of_float(m, width, f(x))
          Cti(f) => @primus.Value::of_int64(m, width~, f(x))
          Ord(f) => {
            let xs = [x] + ops.map(float_of_value)
            let mut r = true
            for i in 1..<xs.length() {
              r = r && f(xs[i - 1], xs[i])
            }
            @primus.Value::of_bool(m, r)
          }
          Cnd(f) => @primus.Value::of_bool(m, f(x))
        }
      }
    }
  })
}

///|
/// Defines the IEEE754 primitives `ieee754-add`, `ieee754-sqrt`, ...
pub fn init_ieee754(m : @primus.Machine) -> Unit {
  let int : Typ = Type(addr_width(m))
  let a : Typ = Name("a")
  let b : Typ = Name("b")
  let ops : Array[(String, FloatOp)] = [
    ("add", Inf((x, y) => x + y)),
    ("sub", Inf((x, y) => x - y)),
    ("div", Inf((x, y) => x / y)),
    ("mul", Inf((x, y) => x * y)),
    ("pow", Inf((x, y) => @math.pow(x, y))),
    ("sqrt", Pre(x => x.sqrt())),
    ("neg", Pre(x => -x)),
    ("pos", Pre(x => x)),
    ("exp", Pre(x => @math.exp(x))),
    ("expm1", Pre(x => @math.expm1(x))),
    ("log", Pre(x => @math.ln(x))),
    ("log10", Pre(x => @math.log10(x))),
    ("log1p", Pre(x => @math.ln_1p(x))),
    ("cos", Pre(x => @math.cos(x))),
    ("sin", Pre(x => @math.sin(x))),
    ("tan", Pre(x => @math.tan(x))),
    ("cosh", Pre(x => @math.cosh(x))),
    ("sinh", Pre(x => @math.sinh(x))),
    ("tanh", Pre(x => @math.tanh(x))),
    ("acos", Pre(x => @math.acos(x))),
    ("asin", Pre(x => @math.asin(x))),
    ("atan", Pre(x => @math.atan(x))),
    ("atan2", Inf((x, y) => @math.atan2(x, y))),
    ("hypot", Inf((x, y) => @math.hypot(x, y))),
    ("ceil", Pre(x => x.ceil())),
    ("floor", Pre(x => x.floor())),
    ("abs", Pre(x => x.abs())),
    ("mod", Inf((x, y) => x % y)),
    ("cti", Cti(x => x.to_int64())),
    ("lt", Ord((x, y) => x < y)),
    ("le", Ord((x, y) => x <= y)),
    ("eq", Ord((x, y) => x == y)),
    ("ne", Ord((x, y) => x != y)),
    ("gt", Ord((x, y) => x > y)),
    ("ge", Ord((x, y) => x >= y)),
    ("is-nan", Cnd(x => x.is_nan())),
  ]
  for op in ops {
    let (types, docs) = match op.1 {
      Inf(_) =>
        (
          arrow(Gen([int, a], a), a),
          "reduces the list of operands with \{op.0}",
        )
      Pre(_) => (arrow(Tuple([int, a, a]), a), "applies \{op.0} to the operand")
      Cti(_) => (arrow(Tuple([int, a]), b), "truncates to the nearest integer")
      Ord(_) =>
        (
          arrow(Tuple([int, a, a]), Type(1)),
          "returns true if all operands are ordered with the \{op.0} order",
        )
      Cnd(_) => (arrow(Tuple([int, a]), Type(1)), "checks if \{op.0} holds")
    }
    define_primitive(
      m,
      "ieee754-" + op.0,
      types~,
      docs~,
      ieee754_primitive("ieee754-" + op.0, op.1),
    )
  }
}

// ---------------------------------------------------------------------------
// The runtime

///|
/// Initializes the Lisp runtime in the machine: defines the standard, IO,
/// and IEEE754 primitives and reflects the standard observations into
/// signals (upstream components `lisp-primitives`, `lisp-basic-io`,
/// `lisp-ieee754`, and `lisp-core`).
pub fn init_runtime(m : @primus.Machine) -> Unit raise {
  refine_from_system(m)
  init_part(m, "primitives", m => init_primitives(m))
  init_part(m, "io", init_io)
  init_part(m, "ieee754", m => init_ieee754(m))
  init_signals(m)
}

///|
/// The parts of the runtime installed in the machine.
let runtime_parts : @primus.State[Array[String]] = @primus.State::declare_(
  uuid="3f6c2a1e-8d4b-4c7a-9e2f-5b1d0a7c6e34",
  name="lisp-runtime-parts",
  clone=xs => xs.copy(),
  _ => [],
)

///|
/// Installs a part of the runtime unless it is already installed.
fn init_part(
  m : @primus.Machine,
  part : String,
  init : (@primus.Machine) -> Unit raise,
) -> Unit raise {
  let parts = m.get_local(runtime_parts)
  if parts.contains(part) {
    return
  }
  m.put_local(runtime_parts, [..parts, part])
  init(m)
}

///|
/// Refines the context of the Lisp program with the classes `system` and
/// `component` of the system that runs the machine, if any (upstream
/// `System.Generic.do_init` refines the Lisp context).
pub fn refine_from_system(m : @primus.Machine) -> Unit raise {
  match @primus.System::current(m) {
    None => ()
    Some(sys) =>
      refine(
        m,
        Context::create([
          ("system", [sys.name().show()]),
          ("component", sys.all_components().map(n => n.show())),
        ]),
      )
  }
}

///|
/// The embedded directories of the Primus Lisp library: the core library,
/// the site library, and the libraries of the analysis plugins (taint,
/// constant tracker, testing framework, approximations, symbolic
/// executor).
pub let library_dirs : Array[String] = [
  "lisp", "site-lisp", "taint", "constant-tracker", "primus-test", "approximation",
  "symbolic-executor",
]

///|
/// The features and the loader used by `load_library` by default (set by
/// the `primus-lisp` plugin options).
let library_config : Ref[(Array[String], Loader)] = Ref(
  (["core", "posix"], Loader::embedded(library_dirs)),
)

///|
/// Sets the features and the loader that `load_library` (and the
/// `bap:load-lisp-library` component) uses by default.
pub fn configure_library(features? : Array[String], loader? : Loader) -> Unit {
  let (fs, l) = library_config.val
  library_config.val = (
    match features {
      Some(f) => f
      None => fs
    },
    match loader {
      Some(x) => x
      None => l
    },
  )
}

///|
/// Loads the features from the library (by default the standard library
/// `core` and `posix`, searched in the embedded `library_dirs`, see
/// `configure_library`) in the context of the machine, and links them into
/// the machine (upstream component `load-lisp-library`).
pub fn load_library(
  m : @primus.Machine,
  features? : Array[String],
  loader? : Loader,
) -> Unit raise {
  let (default_features, default_loader) = library_config.val
  let features = match features {
    Some(f) => f
    None => default_features
  }
  let loader = match loader {
    Some(l) => l
    None => default_loader
  }
  let ctxt = get_state(m).program.context.merge(Context::of_target(m.target()))
  let prog = load_program(loader, features, context=ctxt)
  link_program(m, prog)
}

///|
let components_registered : Ref[Bool] = Ref(false)

///|
/// Registers the Lisp runtime as generic Primus components:
/// `bap:lisp-core` (primitives and signals), `bap:load-lisp-library` (the
/// standard library), and `bap:lisp-type-checker` (type checks the program
/// and posts the type errors). The function is idempotent.
pub fn register_components() -> Unit raise {
  if components_registered.val {
    return
  }
  components_registered.val = true
  @primus.Components::register_generic(
    "lisp-core",
    pkg="bap",
    desc="Initializes Primus Lisp core: the primitives and the signals.",
    init_runtime,
  )
  @primus.Components::register_generic(
    "load-lisp-library",
    pkg="bap",
    desc="Loads the Primus Lisp library and links external functions.",
    m => load_library(m),
  )
  // upstream splits the runtime into several components that systems list
  // separately (`bap:base-lisp-machine`); `lisp-core` already installs all
  // of them, so these components only complete a runtime that was not
  // initialized by `lisp-core` (each part is installed at most once).
  @primus.Components::register_generic(
    "lisp-primitives",
    pkg="bap",
    desc="Provides the core Primus Lisp primitives.",
    m => init_part(m, "primitives", m => init_primitives(m)),
  )
  @primus.Components::register_generic(
    "lisp-basic-io",
    pkg="bap",
    desc="Provides the basic input/output Primus Lisp primitives.",
    m => init_part(m, "io", init_io),
  )
  @primus.Components::register_generic(
    "lisp-ieee754",
    pkg="bap",
    desc="Provides the IEEE754 floating-point Primus Lisp primitives.",
    m => init_part(m, "ieee754", m => init_ieee754(m)),
  )
  @primus.Components::register_generic(
    "lisp-type-checker",
    pkg="bap",
    desc="Typechecks the Primus Lisp program and posts the type errors.",
    m => ignore(typecheck(m)),
  )
}
