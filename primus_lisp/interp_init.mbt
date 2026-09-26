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
// IO channels (upstream `Primus_lisp_io`). Channels are virtual: the
// output of a channel is accumulated in the per-fork state, the input is
// provided by the host (see `set_channel_input`).

///|
priv struct Channel {
  input : Bytes?
  pos : Int
  output : @list.List[String]
}

///|
let io_state : @primus.State[@sorted_map.SortedMap[Int, Channel]] = @primus.State::declare_(
  uuid="f326a07d-16ed-42ec-958d-76ef584cb341",
  name="io-channels",
  _ => {
    @sorted_map.SortedMap::from_iter(
      [
        (0, { input: Some(b""), pos: 0, output: @list.empty(), }),
        (1, { input: None, pos: 0, output: @list.empty(), }),
        (2, { input: None, pos: 0, output: @list.empty(), }),
      ].iter(),
    )
  },
)

///|
/// The contents written to the channel with the descriptor `fd` (e.g.,
/// `1` for the standard output).
pub fn channel_output(m : @primus.Machine, fd : Int) -> String {
  match m.get_local(io_state).get(fd) {
    None => ""
    Some(c) => c.output.rev().to_array().join("")
  }
}

///|
/// Sets the input of the channel `fd` (e.g., `0` for the standard input).
pub fn set_channel_input(m : @primus.Machine, fd : Int, input : Bytes) -> Unit {
  m.update_local(io_state, cs => {
    cs.add(
      fd,
      match cs.get(fd) {
        Some(c) => { ..c, input: Some(input), pos: 0, }
        None => { input: Some(input), pos: 0, output: @list.empty(), }
      },
    )
  })
}

///|
fn io_error(m : @primus.Machine) -> @primus.Value raise {
  @primus.Value::of_word(m, @types.Word::ones(width=addr_width(m)))
}

///|
fn io_ok(m : @primus.Machine) -> @primus.Value raise {
  @primus.Value::zero(m, addr_width(m))
}

///|
fn io_primitives(bits : Int) -> Array[(String, Signature, String, Closure)] {
  let int : Typ = Type(bits)
  let byte : Typ = Type(8)
  let fd_of = (_ : @primus.Machine, v : @primus.Value) => {
    word_to_int(v.to_word())
  }
  [
    (
      "channel-open",
      arrow(Gen([int], int), int),
      "(channel-open PTR) creates a new channel that is associated with a null-terminated path pointed by PTR. Returns a negative value, since the host file system is not accessible.",
      Closure::sync((m, _, _) => io_error(m)),
    ),
    (
      "channel-close",
      arrow(Tuple([int]), int),
      "(channel-close DESCR) closes a channel that has the specified descriptor DESCR.",
      Closure::sync((m, _, args) => {
        match args {
          [fd] =>
            match fd_of(m, fd) {
              Some(n) if m.get_local(io_state).contains(n) => {
                m.update_local(io_state, cs => cs.remove(n))
                io_ok(m)
              }
              _ => io_error(m)
            }
          _ => io_error(m)
        }
      }),
    ),
    (
      "channel-flush",
      arrow(Tuple([int]), int),
      "(channel-flush DESCR) forces data that were written to a channel to be outputted.",
      Closure::sync((m, _, args) => {
        match args {
          [fd] =>
            match fd_of(m, fd) {
              Some(n) if m.get_local(io_state).contains(n) => io_ok(m)
              _ => io_error(m)
            }
          _ => io_error(m)
        }
      }),
    ),
    (
      "channel-input",
      arrow(Tuple([int]), int),
      "(channel-input DESC) reads one byte from a channel that has the descriptor DESC. Returns -1 on error or at the end of file.",
      Closure::sync((m, _, args) => {
        match args {
          [fd] =>
            match fd_of(m, fd) {
              Some(n) =>
                match m.get_local(io_state).get(n) {
                  Some({ input: Some(bytes), pos, output, }) if pos <
                    bytes.length() => {
                    m.update_local(io_state, cs => {
                      cs.add(n, { input: Some(bytes), pos: pos + 1, output, })
                    })
                    @primus.Value::of_int(
                      m,
                      width=addr_width(m),
                      bytes[pos].to_int(),
                    )
                  }
                  _ => io_error(m)
                }
              None => io_error(m)
            }
          _ => io_error(m)
        }
      }),
    ),
    (
      "channel-output",
      arrow(Gen([int], byte), int),
      "(channel-output DESCR CHAR ...) outputs one or more characters to a channel that has the descriptor DESCR.",
      Closure::sync((m, _, args) => {
        match args {
          [fd, .. chars] =>
            match fd_of(m, fd) {
              Some(n) =>
                match m.get_local(io_state).get(n) {
                  Some(c) => {
                    let buf = StringBuilder()
                    for ch in chars {
                      let w = ch.to_word()
                      let byte = match word_to_int(resize(w, 8)) {
                        Some(b) => b
                        None => 0
                      }
                      buf.write_char(byte.unsafe_to_char())
                    }
                    m.update_local(io_state, cs => {
                      cs.add(n, { ..c, output: c.output.add(buf.to_string()), })
                    })
                    io_ok(m)
                  }
                  None => io_error(m)
                }
              None => io_error(m)
            }
          _ => io_error(m)
        }
      }),
    ),
  ]
}

///|
/// Defines the IO primitives and the standard channel variables (upstream
/// `Primus_lisp_io`).
pub fn init_io(m : @primus.Machine) -> Unit raise {
  let width = addr_width(m)
  let set = (name : String, fd : Int) => {
    let v = @types.Var::create(name, Imm(width))
    @primus.Env::set(m, v, @primus.Value::of_int(m, width~, fd))
  }
  set("posix:*standard-input*", 0)
  set("posix:*standard-output*", 1)
  set("posix:*error-output*", 2)
  set("posix:*standard-error*", 2)
  for p in io_primitives(width) {
    define_primitive(m, p.0, types=p.1, docs=p.2, p.3)
  }
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
  init_primitives(m)
  init_io(m)
  init_ieee754(m)
  init_signals(m)
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
/// Loads the features from the embedded library (by default the standard
/// library `core` and `posix`, searched in the `lisp` and `site-lisp`
/// directories) in the context of the machine target, and links them into
/// the machine (upstream component `load-lisp-library`).
pub fn load_library(
  m : @primus.Machine,
  features? : Array[String] = ["core", "posix"],
  loader? : Loader = Loader::embedded(["lisp", "site-lisp"]),
) -> Unit raise {
  let ctxt = Context::of_target(m.target())
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
  @primus.Components::register_generic(
    "lisp-type-checker",
    pkg="bap",
    desc="Typechecks the Primus Lisp program and posts the type errors.",
    m => ignore(typecheck(m)),
  )
}
