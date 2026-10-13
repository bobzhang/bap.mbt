// Port of `plugins/primus_taint/primus_taint_main.ml`: the Primus Taint
// Analysis Framework control module.
//
// Upstream exposes the taint engine to Primus Lisp programs by defining
// Lisp primitives (the `taint-primitives` component) and by reflecting
// the `taint-finalize` observation into a Lisp signal (the
// `taint-signals` component). The Lisp interpreter is not a dependency of
// this package: the primitives are provided as a table of named host
// functions over `@primus.Machine` and `@primus.Value` that a Lisp
// runtime binds with `install_primitives`, and the signal is exposed
// through `install_signals`. The Lisp library files of the upstream
// plugin (`taint.lisp`, `taint-sources.lisp`, `sensitive-sinks.lisp`)
// belong to the Lisp runtime and are not part of this package.

///|
/// A Primus primitive: a named host function that takes and returns
/// Primus values (upstream `Primus.Lisp.define` closures).
pub struct Primitive {
  /// The name under which the primitive is visible to Lisp programs.
  name : String
  /// The Lisp type signature of the primitive (documentation).
  types : String
  /// The documentation string of the primitive.
  docs : String
  /// The implementation.
  run : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise
}

///|
/// Applies the primitive to the arguments.
pub fn Primitive::call(
  self : Primitive,
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  (self.run)(m, args)
}

///|
fn arity_error(
  m : @primus.Machine,
  name : String,
  expected : Int32,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  m.raise_exn(
    @primus.PrimusError::RuntimeError(
      "\{name}: expected \{expected} argument(s), got \{args.length()}",
    ),
  )
}

///|
fn nil(m : @primus.Machine) -> @primus.Value {
  @primus.Value::b0(m)
}

///|
/// The first object of the set that has the given kind.
fn first_of_kind(
  m : @primus.Machine,
  kind : @taint.Kind,
  taints : Array[@taint.Object],
) -> @taint.Object? raise {
  for t in taints {
    if t.kind(m) == kind {
      return Some(t)
    }
  }
  None
}

///|
fn get_taint(name : String, rel : @taint.Rel) -> Primitive {
  let (docs, types) = match rel {
    Direct =>
      (
        "(taint-get-direct K X) returns the direct taint of the kind K associated with the value X, or nil if there is no such taint",
        "(a b) -> c",
      )
    Indirect =>
      (
        "(taint-get-indirect K X) returns the indirect taint of the kind K associated with the value X, or nil if there is no such taint",
        "(a b) -> c",
      )
  }
  {
    name,
    types,
    docs,
    run: (m, args) => {
      guard args is [k, v] else { arity_error(m, name, 2, args) }
      let kind = @taint.Kind::of_value(k)
      let taints = @taint.Tracker::lookup(m, v, rel).to_array()
      match first_of_kind(m, kind, taints) {
        None => nil(m)
        Some(t) => t.to_value()
      }
    },
  }
}

///|
fn sanitize(name : String, rel : @taint.Rel) -> Primitive {
  let docs = match rel {
    Direct =>
      "(taint-sanitize-direct K X) removes any direct taint of the kind K that is directly associated with the value X"
    Indirect =>
      "(taint-sanitize-indirect K X) removes any direct taint of the kind K that is indirectly associated with the value X"
  }
  {
    name,
    types: "(a b) -> c",
    docs,
    run: (m, args) => {
      guard args is [k, v] else { arity_error(m, name, 2, args) }
      @taint.Tracker::sanitize(m, v, rel, @taint.Kind::of_value(k))
      v
    },
  }
}

///|
let primitive_table : Array[Primitive] = [
  {
    name: "taint-introduce-directly",
    types: "(a b) -> c",
    docs: "(taint-introduce-directly K X) introduces a new taint of the kind K that is directly associated with the value X",
    run: (m, args) => {
      guard args is [k, v] else {
        arity_error(m, "taint-introduce-directly", 2, args)
      }
      @taint.Tracker::new_direct(m, v, @taint.Kind::of_value(k)).to_value()
    },
  },
  {
    name: "taint-introduce-indirectly",
    types: "(a int int) -> c",
    docs: "(taint-introduce-indirectly K X N) introduces a new taint of the kind K that is indirectly associated with X pointing to an object of the size N",
    run: (m, args) => {
      guard args is [k, v, n] else {
        arity_error(m, "taint-introduce-indirectly", 3, args)
      }
      @taint.Tracker::new_indirect(m, addr=v, len=n, @taint.Kind::of_value(k)).to_value()
    },
  },
  get_taint("taint-get-direct", Direct),
  get_taint("taint-get-indirect", Indirect),
  sanitize("taint-sanitize-direct", Direct),
  sanitize("taint-sanitize-indirect", Indirect),
  {
    name: "taint-policy-select",
    types: "(a b) -> bool",
    docs: "(taint-policy-select K P) selects the taint propagation policy P for the taints of the kind K",
    run: (m, args) => {
      guard args is [k, p] else {
        arity_error(m, "taint-policy-select", 2, args)
      }
      @taint.Policy::select(
        m,
        @taint.Policy::of_value(p),
        @taint.Kind::of_value(k),
      )
      nil(m)
    },
  },
  {
    name: "taint-policy-set-default",
    types: "(a) -> bool",
    docs: "(taint-policy-set-default P) makes P the default taint propagation policy.",
    run: (m, args) => {
      guard args is [p] else {
        arity_error(m, "taint-policy-set-default", 1, args)
      }
      @taint.Policy::set_default(m, @taint.Policy::of_value(p))
      nil(m)
    },
  },
  {
    name: "taint-kind",
    types: "(a) -> b",
    docs: "(taint-kind t) returns the kind of the taint T.",
    run: (m, args) => {
      guard args is [t] else { arity_error(m, "taint-kind", 1, args) }
      @taint.Object::of_value(t).kind(m).to_value()
    },
  },
]

///|
/// The taint primitives (upstream `taint-primitives` component), in the
/// upstream definition order.
pub fn primitives() -> Array[Primitive] {
  primitive_table.copy()
}

///|
/// Finds a primitive by name.
pub fn find_primitive(name : String) -> Primitive? {
  primitive_table.search_by(p => p.name == name).map(i => primitive_table[i])
}

///|
/// Calls a primitive by name. Raises `UnboundName` if there is no such
/// primitive.
pub fn call_primitive(
  m : @primus.Machine,
  name : String,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  match find_primitive(name) {
    Some(p) => p.call(m, args)
    None => m.raise_exn(@primus.PrimusError::UnboundName(Symbol(name)))
  }
}

///|
/// Defines every primitive with the given definer (e.g. the `define`
/// function of a Primus Lisp runtime).
pub fn install_primitives(definer : (Primitive) -> Unit raise) -> Unit raise {
  for p in primitive_table {
    definer(p)
  }
}

///|
/// The name of the Lisp signal that reflects `taint-finalize`.
pub let finalize_signal : String = "taint-finalize"

///|
/// The documentation of the `taint-finalize` signal.
pub let finalize_signal_doc : String = "(taint-finalize T L) is emitted when the taint T is finilized while still live if L is true or dead if T is false."

///|
/// The arguments of the `taint-finalize` signal: the taint object and the
/// liveness flag as a bit.
pub fn finalize_signal_args(
  m : @primus.Machine,
  obj : @taint.Object,
  live : Bool,
) -> Array[@primus.Value] {
  [obj.to_value(), @primus.Value::of_bool(m, live)]
}

///|
/// Reflects the `taint-finalize` observation to a signal (upstream
/// `taint-signals` component): `signal(name, args)` is called with
/// `finalize_signal` and `finalize_signal_args` every time a taint is
/// finalized in the machine.
pub fn install_signals(
  m : @primus.Machine,
  signal : (String, Array[@primus.Value]) -> Unit raise,
) -> Unit {
  m.observe(@taint.taint_finalize, p => {
    signal(finalize_signal, finalize_signal_args(m, p.0, p.1))
  })
}
