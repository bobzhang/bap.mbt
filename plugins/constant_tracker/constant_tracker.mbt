///|
/// The plugin name.
pub let name : String = "constant-tracker"

///|
let doc : String =
  #|a constant tracking analysis based on Primus
  #|
  #|Tracks constants, using the following policy. A value is a static
  #|constant if it was initialized from a constant value or computed from
  #|static constant values.

///|
/// The per-machine state of the tracker (`state`): the identifiers of the
/// values that are static constants.
///
/// The tracker is independent of the Primus machine: an interpreter reports
/// its observations (`const`, `binop`, `unop`, `cast`, `extract`, `concat`)
/// with the identifiers of the involved values.
pub struct ConstantTracker {
  priv consts : @hashset.HashSet[Int64]
}

///|
pub fn ConstantTracker::new() -> ConstantTracker {
  { consts: @hashset.HashSet([]), }
}

///|
/// `true` if the value is a static constant.
pub fn ConstantTracker::is_const(self : ConstantTracker, id : Int64) -> Bool {
  self.consts.contains(id)
}

///|
/// `true` if all values are static constants.
pub fn ConstantTracker::all_consts(
  self : ConstantTracker,
  ids : ArrayView[Int64],
) -> Bool {
  ids.iter().all(id => self.is_const(id))
}

///|
/// Declares a value a static constant (`declare_const`, the `const`
/// observation).
pub fn ConstantTracker::intro(self : ConstantTracker, id : Int64) -> Unit {
  self.consts.add(id)
}

///|
/// Declares `output` a static constant if all `inputs` are (`propagate`).
pub fn ConstantTracker::propagate(
  self : ConstantTracker,
  inputs : ArrayView[Int64],
  output : Int64,
) -> Unit {
  if self.all_consts(inputs) {
    self.intro(output)
  }
}

///|
/// The `binop` observation: `z = x <op> y`.
pub fn ConstantTracker::on_binop(
  self : ConstantTracker,
  x : Int64,
  y : Int64,
  z : Int64,
) -> Unit {
  self.propagate([x, y], z)
}

///|
/// The `unop` observation: `z = <op> x`.
pub fn ConstantTracker::on_unop(
  self : ConstantTracker,
  x : Int64,
  z : Int64,
) -> Unit {
  self.propagate([x], z)
}

///|
/// The `cast` observation: `z = cast x`.
pub fn ConstantTracker::on_cast(
  self : ConstantTracker,
  x : Int64,
  z : Int64,
) -> Unit {
  self.propagate([x], z)
}

///|
/// The `extract` observation: `z = extract x`.
pub fn ConstantTracker::on_extract(
  self : ConstantTracker,
  x : Int64,
  z : Int64,
) -> Unit {
  self.propagate([x], z)
}

///|
/// The `concat` observation: `z = x.y`.
pub fn ConstantTracker::on_concat(
  self : ConstantTracker,
  x : Int64,
  y : Int64,
  z : Int64,
) -> Unit {
  self.propagate([x, y], z)
}

///|
/// The `(all-static-constant X Y ...)` primitive.
pub fn ConstantTracker::all_static_constant(
  self : ConstantTracker,
  ids : ArrayView[Int64],
) -> Bool {
  self.all_consts(ids)
}

///|
/// The `(points-to-static-data PTR LEN)` primitive: `true` iff all `len`
/// bytes starting at `ptr` hold static constants. `load` returns the value
/// identifier stored at an address (`None` for unmapped memory).
pub fn ConstantTracker::points_to_static_data(
  self : ConstantTracker,
  ptr : UInt64,
  len : UInt64,
  load : (UInt64) -> Int64?,
) -> Bool {
  for p = ptr, n = len; n != 0; p = p + 1, n = n - 1 {
    match load(p) {
      Some(id) if self.is_const(id) => continue
      _ => return false
    }
  }
  true
}

///|
/// A Primus Lisp primitive exposed by the plugin.
pub(all) struct LispPrimitive {
  name : String
  types : String
  docs : String
} derive(Eq, Debug)

///|
pub extend LispPrimitive with Eq::{not_equal, equal}

///|
pub extend LispPrimitive with Debug::{to_repr}

///|
/// The primitives defined by the `constant-tracker-primitives` component.
pub fn lisp_primitives() -> Array[LispPrimitive] {
  [
    {
      name: "all-static-constant",
      types: "(all any) -> bool",
      docs: "(all-static-constant X Y ..) is true if X,Y,... are static constants. A value is a static constant if it was initialized from a constant value or computed from static constant values.",
    },
    {
      name: "points-to-static-data",
      types: "(int int) -> bool",
      docs: "(points-to-static-data PTR LEN) is true iff (all-static-constant *PTR .. *(PTR+LEN-1))",
    },
  ]
}

///|
/// A Primus component declared by the plugin.
pub(all) struct Component {
  name : String
  pkg : String
  desc : String
} derive(Eq, Debug)

///|
pub extend Component with Eq::{not_equal, equal}

///|
pub extend Component with Debug::{to_repr}

///|
/// The generic components declared by the plugin.
pub fn components() -> Array[Component] {
  [
    {
      name: "constant-tracker-primitives",
      pkg: "bap",
      desc: "Exposes the constant tracker primitives to Primus Lisp.",
    },
    {
      name: "constant-tracker",
      pkg: "bap",
      desc: "Tracks constants, using the following policy. A value is a static constant if it was initialized from a constant value or computed from static constant values. ",
    },
  ]
}

///|
let enabled : Ref[Bool] = Ref(false)

///|
let registered : Ref[Bool] = Ref(false)

///|
/// Records the plugin configuration: the `constant-tracker` component is
/// registered in the Primus component registry, the primitives are always
/// available (see `primitives`), and the tracker component is added to the
/// legacy main Primus system when `enable` is set (upstream `--enable`).
/// Returns `false` if the plugin was already registered.
pub fn register(enable? : Bool = false) -> Bool {
  if registered.val {
    return false
  }
  registered.val = true
  enabled.val = enable
  register_components()
  if enable {
    @primus.Machine::add_component(m => tracker_component(m))
  }
  true
}

///|
/// `true` if the tracker component should be added to Primus machines.
pub fn is_enabled() -> Bool {
  enabled.val
}

///|
/// Declares the `constant-tracker` plugin to `bap_main` with its `enable`
/// flag. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "lisp", "analysis"],
    doc~,
    () => {
      let enable = @bap_main.Configuration::flag(
        doc="Add the constant tracker to Primus machines.",
        "enable",
      )
      @bap_main.Extension::register(ctxt => {
        ignore(register(enable=ctxt.get(enable)))
      })
    },
  )
}
