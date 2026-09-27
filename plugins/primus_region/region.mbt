///|
/// # Primus regions (upstream `plugins/primus_region`)
///
/// A set of operations to store and manipulate interval sets. Intervals
/// are called *regions*, since they often represent memory regions. Each
/// set of regions is denoted with a symbol (any value, compared by its
/// numeric value); it is possible to create an arbitrary number of sets
/// and to move regions from one set to another. The sets are persistent
/// and local to each machine (forks inherit the sets of their parent).
///
/// Upstream exposes the operations as Primus Lisp primitives
/// (`region-create`, `region-contains`, `region-move`, `region-lower`,
/// `region-upper`, `region-count`). Primus Lisp is ported separately, so
/// this package provides the primitives as host functions (`primitives`)
/// together with their Lisp signatures and documentation, and the
/// `bap:lisp-regions` component links them into the machine under their
/// names (as `Host` code that reads `call_args` and sets the result), so
/// they can be called with `Machine::call` or bound by a Lisp interpreter.
///
/// Points are compared by their numeric (unsigned) values irrespective of
/// their widths, as upstream compares Primus values.
pub let component_name : String = "lisp-regions"

///|
/// A primitive: its name, Lisp type signature, documentation and the host
/// implementation applied to the arguments.
pub struct Primitive {
  name : String
  types : String
  docs : String
  run : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise
}

///|
/// The numeric order of words (upstream `Primus.Value.compare`, i.e.,
/// `Word.Signed_value_order.compare` on unsigned words): the values are
/// compared ignoring their widths.
fn value_order(a : @types.Word, b : @types.Word) -> Int {
  let w = if a.bitwidth() > b.bitwidth() { a.bitwidth() } else { b.bitwidth() }
  let widen = (x : @types.Word) => {
    if x.bitwidth() == w {
      x
    } else {
      x.extract(hi=w - 1, lo=0) catch {
        _ => x
      }
    }
  }
  widen(a).compare_unsigned(widen(b)) catch {
    _ => a.compare(b)
  }
}

///|
/// A set key: a word ordered numerically.
priv struct Key(@types.Word)

///|
impl Eq for Key with fn equal(self, other) {
  value_order(self.0, other.0) == 0
}

///|
impl Compare for Key with fn compare(self, other) {
  value_order(self.0, other.0)
}

///|
/// A region `[lower, upper]` (both bounds included).
priv struct Region {
  lower : @primus.Value
  upper : @primus.Value
}

///|
fn Region::compare(self : Region, other : Region) -> Int {
  match value_order(self.lower.to_word(), other.lower.to_word()) {
    0 => value_order(self.upper.to_word(), other.upper.to_word())
    c => c
  }
}

///|
fn Region::contains(self : Region, p : @primus.Value) -> Bool {
  value_order(self.lower.to_word(), p.to_word()) <= 0 &&
  value_order(p.to_word(), self.upper.to_word()) <= 0
}

///|
fn Region::same(self : Region, other : Region) -> Bool {
  self.compare(other) == 0
}

///|
/// A set of regions (upstream `Interval_tree`): regions sorted by their
/// bounds, duplicates allowed (a new region goes after the equal ones).
/// The array is never mutated in place, so the set is persistent.
priv struct Regions(Array[Region])

///|
fn Regions::add(self : Regions, r : Region) -> Regions {
  let xs = self.0
  let mut i = 0
  while i < xs.length() && xs[i].compare(r) <= 0 {
    i += 1
  }
  let out = xs.copy()
  out.insert(i, r)
  Regions(out)
}

///|
fn Regions::lookup(self : Regions, p : @primus.Value) -> Array[Region] {
  self.0.iter().filter(r => r.contains(p)).collect()
}

///|
/// Removes all regions equal to `r` (upstream `remove` removes the exact
/// matches).
fn Regions::remove(self : Regions, r : Region) -> Regions {
  Regions(self.0.iter().filter(x => !x.same(r)).collect())
}

///|
fn Regions::length(self : Regions) -> Int {
  self.0.length()
}

///|
let state : @primus.State[@sorted_map.SortedMap[Key, Regions]] = @primus.State::declare_(
  uuid="0FC4AF7F-7237-4CE1-874A-4971801C6D67",
  name="region",
  _ => @sorted_map.new(),
)

///|
fn nil(m : @primus.Machine) -> @primus.Value raise {
  @primus.Value::zero(m, 1)
}

///|
fn arity(name : String, args : Array[@primus.Value], n : Int) -> Unit raise {
  if args.length() != n {
    raise @primus.RuntimeError(
      "\{name}: expects \{n} arguments, got \{args.length()}",
    )
  }
}

///|
/// `(region-create ID LOWER UPPER)`: adds `[LOWER, UPPER]` to the set `ID`
/// (creating the set if needed). Returns `ID`.
pub fn create(
  m : @primus.Machine,
  reg : @primus.Value,
  lower : @primus.Value,
  upper : @primus.Value,
) -> @primus.Value {
  let key = Key(reg.to_word())
  m.update_local(state, regions => {
    let set = regions.get(key).unwrap_or(Regions([]))
    regions.add(key, set.add({ lower, upper, }))
  })
  reg
}

///|
/// `(region-contains ID X)` (also `region-lower`): the lower bound of the
/// first region of `ID` that contains `X`, or nil.
pub fn lower(
  m : @primus.Machine,
  reg : @primus.Value,
  addr : @primus.Value,
) -> @primus.Value raise {
  match m.get_local(state).get(Key(reg.to_word())) {
    None => nil(m)
    Some(set) =>
      match set.lookup(addr) {
        [r, ..] => r.lower
        [] => nil(m)
      }
  }
}

///|
/// `(region-upper ID X)`: the upper bound of the last region of `ID` that
/// contains `X`, or nil.
pub fn upper(
  m : @primus.Machine,
  reg : @primus.Value,
  addr : @primus.Value,
) -> @primus.Value raise {
  match m.get_local(state).get(Key(reg.to_word())) {
    None => nil(m)
    Some(set) =>
      match set.lookup(addr) {
        [.., r] => r.upper
        [] => nil(m)
      }
  }
}

///|
/// `(region-count ID)`: the number of regions (including intersecting
/// ones) in the set `ID`, or nil if there is no such set.
pub fn count(m : @primus.Machine, reg : @primus.Value) -> @primus.Value raise {
  match m.get_local(state).get(Key(reg.to_word())) {
    None => nil(m)
    Some(set) => @primus.Value::of_int(m, width=m.target().bits(), set.length())
  }
}

///|
/// `(region-move DST SRC P)`: moves all regions of `SRC` that contain `P`
/// to `DST`. Returns true if some region was moved.
pub fn move_regions(
  m : @primus.Machine,
  dst : @primus.Value,
  src : @primus.Value,
  addr : @primus.Value,
) -> @primus.Value raise {
  let regions = m.get_local(state)
  let skey = Key(src.to_word())
  let dkey = Key(dst.to_word())
  guard regions.get(skey) is Some(set) else { return nil(m) }
  let mut src_set = set
  let mut dst_set = regions.get(dkey).unwrap_or(Regions([]))
  let mut n = 0
  for r in set.lookup(addr) {
    src_set = src_set.remove(r)
    dst_set = dst_set.add(r)
    n += 1
  }
  m.put_local(state, regions.add(skey, src_set).add(dkey, dst_set))
  @primus.Value::of_bool(m, n > 0)
}

///|
/// The Lisp primitives of the library.
pub fn primitives() -> Array[Primitive] {
  [
    {
      name: "region-create",
      types: "(sym int int) -> sym",
      docs: "(region-create ID LOWER UPPER) adds [LOWER,UPPER] to the set ID. Adds a region denoted with the interval [LOWER,UPPER] to the set of regions denoted by the symbol ID. Values LOWER and UPPER are included into the interval. If the set of regions ID doesn't exist, then it is created.",
      run: (m, args) => {
        arity("region-create", args, 3)
        create(m, args[0], args[1], args[2])
      },
    },
    {
      name: "region-contains",
      types: "(sym int) -> int",
      docs: "(region-contains ID X) return the region in ID that has X. Returns the lower bound of the first region that contains value X in the set of regions with the given ID. Returns nil otherwise. Returns nil if a set with the given ID doesn't exist.",
      run: (m, args) => {
        arity("region-contains", args, 2)
        lower(m, args[0], args[1])
      },
    },
    {
      name: "region-move",
      types: "(sym sym int) -> bool",
      docs: "(region-move DST SRC P) moves all regions that contain the point P from the set SRC to the set DST. Returns nil if SRC didn't contain any such region, otherwise returns t.",
      run: (m, args) => {
        arity("region-move", args, 3)
        move_regions(m, args[0], args[1], args[2])
      },
    },
    {
      name: "region-lower",
      types: "(sym int) -> int",
      docs: "(region-lower ID X) the lower bound of region that contains X. Returns nil if ID doesn't exist or if it doesn't have a region that includes X. This fucntion is an alias for REGION-CONTAINS. See also, REGION-UPPER.",
      run: (m, args) => {
        arity("region-lower", args, 2)
        lower(m, args[0], args[1])
      },
    },
    {
      name: "region-upper",
      types: "(sym int) -> int",
      docs: "(region-upper ID X) the upper bound of the region that contains X. Returns the upper bound of the region that contains point X or nil if there is no such region or such set of regions. See also, REGION-LOWER.",
      run: (m, args) => {
        arity("region-upper", args, 2)
        upper(m, args[0], args[1])
      },
    },
    {
      name: "region-count",
      types: "(sym) -> int",
      docs: "(region-count ID) the total number of regions in the set ID. Counts the number of regions (including intersecting) stored in the set of regions referenced by the symbol ID. Returns nil if there is no set with the given ID, otherwise returns the number of regions in that set.",
      run: (m, args) => {
        arity("region-count", args, 1)
        count(m, args[0])
      },
    },
  ]
}

///|
/// Links the primitives into the machine (the `bap:lisp-regions`
/// component body).
///
/// The primitives are linked under their names and defined as Primus Lisp
/// primitives (in the `core` package), as the upstream component does.
pub fn install(m : @primus.Machine) -> Unit {
  for p in primitives() {
    let run = p.run
    @primus.Linker::link(
      m,
      name=p.name,
      Host(m => m.set_result(Some(run(m, m.call_args())))),
    )
    @primus_lisp.define_host_primitive(
      m,
      p.name,
      types=p.types,
      docs=p.docs,
      run,
    )
  }
}

///|
let desc : String = "Provides a set of operations to store and manipulate interval trees. The module provides a persistent storage for intervals, denoted in the module as regions, since these intervals often represent memory regions. Intervals are stored in interval sets, that are implemented as efficient interval tree data structures (using AVL trees underneath the hood). Each interval set is denoted with a symbol, and it is possible to create arbitrary number of sets, as well as move regions from one set to another."

///|
/// Registers the `bap:lisp-regions` component. Idempotent: returns
/// `false` if it was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc~,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the component and adds it to the legacy main system, as the
/// upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  register() |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-region"

///|
/// Declares the `primus-region` plugin to `bap_main`. Does nothing if
/// already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "primus-library", "regions", "interval-trees"],
    doc="provides Primus Lisp library for manipulating program regions\n\n" +
      desc,
    () => @bap_main.Extension::register(_ => enable()),
  )
}
