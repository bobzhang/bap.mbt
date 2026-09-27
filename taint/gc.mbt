// Taint garbage collection (upstream `Taint.Gc`).
//
// A tainted object is live if it is reachable either directly (attached
// to a value held by a variable) or indirectly (attached to an address).
// Indirect references die when their addresses are overwritten; direct
// references use value identifiers, so the collector keeps only those
// that are held by the environment. The set of live objects computed at
// the previous collection is compared with the current one and every
// object that died since is finalized.

///|
fn finalize_sexp(x : (Object, Bool)) -> @primus.Sexp {
  List([x.0.inspect(), Atom(x.1.to_string())])
}

///|
let finalize_obs : (
  @primus.Observation[(Object, Bool)],
  @primus.Statement[(Object, Bool)],
) = @primus.Observation::provide(
  "taint-finalize",
  inspect=finalize_sexp,
  desc="Occurs when the taint becomes unreachable.",
)

///|
/// `(taint-finalize (t live))` occurs when the taint object `t` is
/// collected (`Taint.Gc.taint_finalize`). `live` is `true` if the object
/// is still reachable in some other machine and `false` if it is dead in
/// all machines. If every machine denotes an execution path, then `live`
/// distinguishes "may" (still alive on another path) from "must" (dead
/// everywhere) unreachability.
pub let taint_finalize : @primus.Observation[(Object, Bool)] = finalize_obs.0

///|
let finish_stmt : @primus.Statement[(Object, Bool)] = finalize_obs.1

///|
priv struct GcLocal {
  old : Tainter
}

///|
let gc_state : @primus.State[GcLocal] = @primus.State::declare_(
  name="primus-taint-gc",
  uuid="2357826e-d5b7-40a3-8f90-0cfd7b48eadc",
  _ => { old: empty_tainter(), },
)

///|
/// The conservative garbage collector (upstream `Taint.Gc.Conservative`).
#warnings("-struct_never_constructed")
pub struct Gc {}

///|
/// Removes the direct relations of values that are no longer held by any
/// variable of the environment.
fn collect_direct(m : @primus.Machine) -> Unit raise {
  let s = m.get_local(tainter)
  let mut live : @sorted_set.SortedSet[Int64] = @sorted_set.SortedSet::new()
  for v in @primus.Env::all(m) {
    if @primus.Env::is_set(m, v) {
      live = live.add(@primus.Env::get(m, v).id())
    }
  }
  m.put_local(tainter, {
    ..s,
    direct: s.direct.filter((k, _) => live.contains(k)),
  })
}

///|
/// Runs one collection cycle: drops unreachable direct relations and
/// posts `taint_finalize` for every object that died since the previous
/// cycle (`live=false` for objects that are dead in all machines,
/// `live=true` for objects still tracked by another machine).
pub fn Gc::collect(m : @primus.Machine) -> Unit raise {
  let old = m.get_local(gc_state).old
  collect_direct(m)
  let cur = m.get_local(tainter)
  let dying = tainter_objects(old).difference(tainter_objects(cur))
  let mut dead = dying
  for id in m.forks() {
    let objs = Tracker::objects_of(m, id) catch {
      _ => @sorted_set.SortedSet::new()
    }
    dead = dead.difference(objs)
  }
  let live = dying.difference(dead)
  m.put_local(gc_state, { old: cur, })
  for t in dead {
    m.make(finish_stmt, (t, false))
  }
  for t in live {
    m.make(finish_stmt, (t, true))
  }
}

///|
/// The conservative garbage collector component (upstream
/// `Taint.Gc.Conservative`).
///
/// It may treat dead taints as live but never collects a reachable
/// taint: a taint is live if it is attached to the value of a variable
/// (`Env::all`) or to any address. Once a taint is attached to an
/// address, it is killed only when the address is overwritten. The
/// collection runs every time the program counter changes.
pub fn Gc::conservative(m : @primus.Machine) -> Unit {
  m.observe(@primus.pc_change, _ => Gc::collect(m))
}
