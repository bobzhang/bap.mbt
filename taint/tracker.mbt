// The taint tracker (upstream `Taint.Tracker`).
//
// The state of the tracker is a set of ternary relations T(v,r,x)
// between values v, relations r and objects x. Direct relations are
// indexed by value identifiers (so two equal words computed separately
// are different values), indirect relations are indexed by addresses
// (words). The state is local to every machine and persistent, so forked
// machines track taints independently.

///|
/// An address: the key of the indirect relation.
priv struct Addr(@types.Word) derive(Eq)

///|
impl Compare for Addr with fn compare(self, other) {
  self.0.compare(other.0)
}

///|
priv struct Tainter {
  direct : @sorted_map.SortedMap[Int64, @sorted_set.SortedSet[Object]]
  indirect : @sorted_map.SortedMap[Addr, @sorted_set.SortedSet[Object]]
}

///|
fn empty_tainter() -> Tainter {
  {
    direct: @sorted_map.SortedMap::new(),
    indirect: @sorted_map.SortedMap::new(),
  }
}

///|
fn objects_sexp(objs : @sorted_set.SortedSet[Object]) -> @primus.Sexp {
  List(objs.to_array().map(o => o.inspect()))
}

///|
fn tainter_sexp(t : Tainter) -> @primus.Sexp {
  let direct = t.direct
    .to_array()
    .map(p => @primus.Sexp::List([Atom("#\{p.0}"), objects_sexp(p.1)]))
  let indirect = t.indirect
    .to_array()
    .map(p => @primus.Sexp::List([Atom(p.0.0.to_string()), objects_sexp(p.1)]))
  List([
    List([Atom("direct"), List(direct)]),
    List([Atom("indirect"), List(indirect)]),
  ])
}

///|
let tainter : @primus.State[Tainter] = @primus.State::declare_(
  name="primus-tainter",
  uuid="2d4a4208-f918-4cf7-8e1b-5d8400a106d3",
  inspect=tainter_sexp,
  _ => empty_tainter(),
)

///|
fn[K] union_all(
  m : @sorted_map.SortedMap[K, @sorted_set.SortedSet[Object]],
) -> @sorted_set.SortedSet[Object] {
  m.fold((acc, _, s) => acc.union(s), init=@sorted_set.SortedSet::new())
}

///|
/// The set of live tainted objects of a tracker state.
fn tainter_objects(t : Tainter) -> @sorted_set.SortedSet[Object] {
  union_all(t.direct).union(union_all(t.indirect))
}

///|
fn[K : Compare] change_map(
  m : @sorted_map.SortedMap[K, @sorted_set.SortedSet[Object]],
  key : K,
  f : (@sorted_set.SortedSet[Object]?) -> @sorted_set.SortedSet[Object]?,
) -> @sorted_map.SortedMap[K, @sorted_set.SortedSet[Object]] {
  match f(m.get(key)) {
    None => m.remove(key)
    Some(s) => m.add(key, s)
  }
}

///|
fn change(
  t : Tainter,
  v : @primus.Value,
  rel : Rel,
  f : (@sorted_set.SortedSet[Object]?) -> @sorted_set.SortedSet[Object]?,
) -> Tainter {
  match rel {
    Direct => { ..t, direct: change_map(t.direct, v.id(), f), }
    Indirect => { ..t, indirect: change_map(t.indirect, Addr(v.to_word()), f), }
  }
}

///|
fn find(
  t : Tainter,
  v : @primus.Value,
  rel : Rel,
) -> @sorted_set.SortedSet[Object]? {
  match rel {
    Direct => t.direct.get(v.id())
    Indirect => t.indirect.get(Addr(v.to_word()))
  }
}

///|
fn attached_sexp(x : (Rel, Object, @primus.Value)) -> @primus.Sexp {
  let (r, o, v) = x
  List([Atom(r.to_string()), o.inspect(), v.to_sexp()])
}

///|
let attached_obs : (
  @primus.Observation[(Rel, Object, @primus.Value)],
  @primus.Statement[(Rel, Object, @primus.Value)],
) = @primus.Observation::provide(
  "taint-attached",
  inspect=attached_sexp,
  desc="Occurs when a taint is attached to the value.",
)

///|
/// `(taint-attached (r o v))` occurs when the relation `r` is established
/// between the object `o` and the value `v` (`Taint.attached`).
pub let attached : @primus.Observation[(Rel, Object, @primus.Value)] = attached_obs.0

///|
let attach_stmt : @primus.Statement[(Rel, Object, @primus.Value)] = attached_obs.1

///|
/// The taint tracker control interface (upstream `Taint.Tracker.Make`).
#warnings("-struct_never_constructed")
pub struct Tracker {}

///|
/// [attach(m, v, r, xs)] establishes the relation `r` between the value
/// `v` and every object of `xs`; all other relations are unaffected. The
/// `attached` observation is posted for every object.
pub fn Tracker::attach(
  m : @primus.Machine,
  v : @primus.Value,
  rel : Rel,
  objs : @sorted_set.SortedSet[Object],
) -> Unit raise {
  // Upstream stores an empty set when there is nothing to attach; an
  // absent binding is observationally equivalent and keeps the state
  // small.
  if !objs.is_empty() {
    m.update_local(tainter, t => {
      change(t, v, rel, old => {
        match old {
          None => Some(objs)
          Some(old) => Some(old.union(objs))
        }
      })
    })
  }
  for o in objs {
    m.post(attach_stmt, () => (rel, o, v))
  }
}

///|
/// [detach(m, v, r, xs)] removes all relations `r` between the value `v`
/// and the objects of `xs`.
pub fn Tracker::detach(
  m : @primus.Machine,
  v : @primus.Value,
  rel : Rel,
  objs : @sorted_set.SortedSet[Object],
) -> Unit {
  m.update_local(tainter, t => {
    change(t, v, rel, old => {
      match old {
        None => None
        Some(old) => {
          let rest = old.difference(objs)
          if rest.is_empty() {
            None
          } else {
            Some(rest)
          }
        }
      }
    })
  })
}

///|
/// [lookup(m, v, r)] is the set of objects related to the value `v` by
/// the relation `r`.
pub fn Tracker::lookup(
  m : @primus.Machine,
  v : @primus.Value,
  rel : Rel,
) -> @sorted_set.SortedSet[Object] {
  match find(m.get_local(tainter), v, rel) {
    None => @sorted_set.SortedSet::new()
    Some(s) => s
  }
}

///|
/// [new_direct(m, v, k)] establishes a direct relation between the value
/// `v` and a fresh object of kind `k`, which is returned.
pub fn Tracker::new_direct(
  m : @primus.Machine,
  v : @primus.Value,
  kind : Kind,
) -> Object raise {
  let taint = Object::create(m, kind)
  m.update_local(tainter, t => {
    change(t, v, Direct, old => {
      match old {
        None => Some(@sorted_set.SortedSet::singleton(taint))
        Some(old) => Some(old.add(taint))
      }
    })
  })
  m.make(attach_stmt, (Direct, taint, v))
  taint
}

///|
/// [new_indirect(m, addr~, len~, k)] establishes an indirect relation
/// between every address of the interval `[addr, addr + len - 1]` and a
/// fresh object of kind `k`, which is returned. Raises `BadCast` if `len`
/// is not a representable integer.
pub fn Tracker::new_indirect(
  m : @primus.Machine,
  addr~ : @primus.Value,
  len~ : @primus.Value,
  kind : Kind,
) -> Object raise {
  let taint = Object::create(m, kind)
  let n = len.to_word().to_int() catch { _ => m.raise_exn(BadCast(len)) }
  let s = m.get_local(tainter)
  let mut indirect = s.indirect
  for off in 0..<n {
    let a = @primus.Value::nsucc(m, addr, off)
    m.make(attach_stmt, (Indirect, taint, a))
    indirect = change_map(indirect, Addr(a.to_word()), old => {
      match old {
        None => Some(@sorted_set.SortedSet::singleton(taint))
        Some(old) => Some(old.add(taint))
      }
    })
  }
  m.put_local(tainter, { ..s, indirect, })
  taint
}

///|
fn[K : Compare] kill_objects(
  kill : @sorted_set.SortedSet[Object],
  m : @sorted_map.SortedMap[K, @sorted_set.SortedSet[Object]],
) -> @sorted_map.SortedMap[K, @sorted_set.SortedSet[Object]] {
  m.fold(
    (acc, k, objs) => {
      let rest = objs.difference(kill)
      if rest.is_empty() {
        acc
      } else {
        acc.add(k, rest)
      }
    },
    init=@sorted_map.SortedMap::new(),
  )
}

///|
/// [sanitize(m, v, r, k)] detaches all objects of kind `k` that are
/// related to the value `v` by the relation `r` from *all* values tracked
/// by the engine (upstream semantics since 2.2.0).
///
/// Note: the upstream implementation filters the objects with
/// `Kind.(k <> k')`, i.e., it kills the objects of all kinds *but* `k`,
/// contradicting its documentation and the documentation of the
/// `taint-sanitize-*` primitives. This port follows the documented
/// semantics.
pub fn Tracker::sanitize(
  m : @primus.Machine,
  v : @primus.Value,
  rel : Rel,
  kind : Kind,
) -> Unit {
  let kill = Tracker::lookup(m, v, rel).filter(t => {
    match kind_of(m, t) {
      None => false
      Some(k) => k == kind
    }
  })
  m.update_local(tainter, t => {
    direct: kill_objects(kill, t.direct),
    indirect: kill_objects(kill, t.indirect),
  })
}

///|
/// The set of taint objects that are currently tracked by the machine.
pub fn Tracker::objects(m : @primus.Machine) -> @sorted_set.SortedSet[Object] {
  tainter_objects(m.get_local(tainter))
}

///|
/// The objects tracked by another (live) machine.
pub fn Tracker::objects_of(
  m : @primus.Machine,
  id : @primus.Id,
) -> @sorted_set.SortedSet[Object] raise {
  tainter_objects(m.get_other(id, tainter))
}

///|
/// Renders the state of the tracker of the current machine.
pub fn Tracker::inspect(m : @primus.Machine) -> @primus.Sexp {
  tainter_sexp(m.get_local(tainter))
}
