// The Primus side of the constant tracker (upstream `Tracker` and
// `Primitives` components of `constant_tracker_main.ml`).
//
// The machine-level state is a persistent set of value identifiers that
// is local to every fork. The `constant-tracker` component fills it from
// the interpreter observations; the `all-static-constant` and
// `points-to-static-data` primitives query it. The primitives are a table
// of named host functions over `@primus.Machine` and `@primus.Value` that
// a Primus Lisp runtime binds with `install_primitives`.

///|
let state : @primus.State[@sorted_set.SortedSet[Int64]] = @primus.State::declare_(
  uuid="caf680aa-ef54-4468-9a24-4a125de6ace9",
  name="constant-tracker",
  _ => @sorted_set.SortedSet::new(),
)

///|
/// Whether the value is a static constant in the current machine.
pub fn is_static_constant(m : @primus.Machine, v : @primus.Value) -> Bool {
  m.get_local(state).contains(v.id())
}

///|
/// Whether all values are static constants (`all_consts`).
pub fn all_static_constant(
  m : @primus.Machine,
  vs : ArrayView[@primus.Value],
) -> Bool {
  let s = m.get_local(state)
  vs.iter().all(v => s.contains(v.id()))
}

///|
/// Declares the value a static constant (`declare_const`).
pub fn declare_static_constant(m : @primus.Machine, v : @primus.Value) -> Unit {
  m.update_local(state, s => s.add(v.id()))
}

///|
/// Declares `output` a static constant if all `inputs` are (`propagate`).
fn propagate_constant(
  m : @primus.Machine,
  inputs : ArrayView[@primus.Value],
  output : @primus.Value,
) -> Unit {
  if all_static_constant(m, inputs) {
    declare_static_constant(m, output)
  }
}

///|
/// `true` iff the `len` bytes starting at `ptr` hold static constants
/// (upstream `IsConstBuffer.points_to_static_data`). Reading unmapped
/// memory raises, as upstream `Memory.get`.
pub fn points_to_static_data(
  m : @primus.Machine,
  ptr : @primus.Value,
  len : @primus.Value,
) -> Bool raise {
  let s = m.get_local(state)
  let mut p = ptr.to_word()
  let mut n = len.to_word()
  while !n.is_zero() {
    let v = @primus.Memory::get(m, p)
    if !s.contains(v.id()) {
      return false
    }
    p = p.succ()
    n = n.pred()
  }
  true
}

///|
/// The `constant-tracker` component (upstream `Tracker`): a value is a
/// static constant if it was initialized from a constant or computed from
/// static constants.
pub fn tracker_component(m : @primus.Machine) -> Unit {
  m.observe(@primus.const_obs, v => declare_static_constant(m, v))
  m.observe(@primus.binop, p => {
    let ((_, x, y), z) = p
    propagate_constant(m, [x, y], z)
  })
  m.observe(@primus.unop, p => {
    let ((_, x), z) = p
    propagate_constant(m, [x], z)
  })
  m.observe(@primus.cast, p => {
    let ((_, _, x), z) = p
    propagate_constant(m, [x], z)
  })
  m.observe(@primus.extract, p => {
    let ((_, _, x), z) = p
    propagate_constant(m, [x], z)
  })
  m.observe(@primus.concat, p => {
    let ((x, y), z) = p
    propagate_constant(m, [x, y], z)
  })
}

///|
/// A Primus primitive: a named host function over Primus values (upstream
/// `Primus.Lisp.define` closures).
pub struct Primitive {
  /// the name under which the primitive is visible to Lisp programs
  name : String
  /// the Lisp type signature (documentation)
  types : String
  /// the documentation string
  docs : String
  /// the implementation
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
fn bool_value(m : @primus.Machine, b : Bool) -> @primus.Value {
  if b {
    @primus.Value::b1(m)
  } else {
    @primus.Value::b0(m)
  }
}

///|
let primitive_table : Array[Primitive] = {
  let docs = lisp_primitives()
  [
    {
      name: docs[0].name,
      types: docs[0].types,
      docs: docs[0].docs,
      run: (m, args) => bool_value(m, all_static_constant(m, args)),
    },
    {
      name: docs[1].name,
      types: docs[1].types,
      docs: docs[1].docs,
      run: (m, args) => {
        guard args is [ptr, len] else {
          m.raise_exn(
            @primus.PrimusError::RuntimeError(
              "points-to-static-data: expected 2 argument(s), got \{args.length()}",
            ),
          )
        }
        bool_value(m, points_to_static_data(m, ptr, len))
      },
    },
  ]
}

///|
/// The constant tracker primitives (upstream `Primitives` component).
pub fn primitives() -> Array[Primitive] {
  primitive_table.copy()
}

///|
/// Finds a primitive by name.
pub fn find_primitive(name : String) -> Primitive? {
  primitive_table.search_by(p => p.name == name).map(i => primitive_table[i])
}

///|
/// Calls a primitive by name; raises `UnboundName` if there is none.
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
fn is_registered(name : String) -> Bool {
  let full = "bap:\{name}"
  @primus.Components::list().iter().any(info => info.name().to_string() == full)
}

///|
/// Registers the `constant-tracker` component in the Primus component
/// registry (idempotent). The `constant-tracker-primitives` component of
/// upstream only defines Lisp primitives; here they are bound by the Lisp
/// runtime through `install_primitives`.
pub fn register_components() -> Unit {
  let tracker = components()[1]
  if !is_registered(tracker.name) {
    @primus.Components::register_generic(
      tracker.name,
      m => tracker_component(m),
      pkg=tracker.pkg,
      desc=tracker.desc,
    ) catch {
      _ => ()
    }
  }
}
