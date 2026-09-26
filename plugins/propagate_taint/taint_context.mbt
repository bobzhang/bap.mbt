// The legacy BIL-level taint state (upstream `Bap.Std.Taint.context`,
// `lib/bap_sema/bap_sema_taint.ml`): taints are sets of term identifiers
// (seeds) attached to evaluation results (by result identifier) and to
// memory addresses.

///|
/// A set of legacy taints (seeds).
pub type TaintSet = @immut_hashset.HashSet[@types.Tid]

///|
/// An address: the key of tainted memory cells.
priv struct Addr(@types.Word) derive(Eq)

///|
impl Compare for Addr with fn compare(self, other) {
  self.0.compare(other.0)
}

///|
/// The taint state of the BIL propagator (upstream `Taint.context`).
pub struct TaintContext {
  priv tvs : @sorted_map.SortedMap[UInt64, TaintSet]
  priv tas : @sorted_map.SortedMap[Addr, TaintSet]
}

///|
/// The state without taints.
pub fn TaintContext::empty() -> TaintContext {
  { tvs: @sorted_map.SortedMap::new(), tas: @sorted_map.SortedMap::new(), }
}

///|
/// [taint_reg(r, ts)] sets the taints of the result `r` to `ts` (an empty
/// set removes the taints of `r`).
pub fn TaintContext::taint_reg(
  self : TaintContext,
  r : @types.BilResult,
  ts : TaintSet,
) -> TaintContext {
  let key = r.id().to_uint64()
  if ts.is_empty() {
    { ..self, tvs: self.tvs.remove(key), }
  } else {
    { ..self, tvs: self.tvs.add(key, ts), }
  }
}

///|
/// [taint_ptr(a, s, ts)] sets the taints of the `s`-sized memory region
/// starting at `a` to `ts`. An empty set doesn't change the state.
pub fn TaintContext::taint_ptr(
  self : TaintContext,
  a : @types.Word,
  s : @types.Size,
  ts : TaintSet,
) -> TaintContext {
  if ts.is_empty() {
    return self
  }
  let mut tas = self.tas
  for n in 0..<s.in_bytes() {
    tas = tas.add(Addr(a.nsucc(n)), ts)
  }
  { ..self, tas, }
}

///|
/// The taints of the result `r` (T(r) = { t : t |-> r }).
pub fn TaintContext::reg_taints(
  self : TaintContext,
  r : @types.BilResult,
) -> TaintSet {
  self.tvs.get(r.id().to_uint64()).unwrap_or(@immut_hashset.HashSet::new())
}

///|
/// The taints of the memory cell at `a`.
pub fn TaintContext::ptr_taints(
  self : TaintContext,
  a : @types.Word,
) -> TaintSet {
  self.tas.get(Addr(a)).unwrap_or(@immut_hashset.HashSet::new())
}

///|
/// All taints of the state.
pub fn TaintContext::all_taints(self : TaintContext) -> TaintSet {
  let init : TaintSet = @immut_hashset.HashSet::new()
  let acc = self.tvs.fold((acc : TaintSet, _, ts) => acc.union(ts), init~)
  self.tas.fold((acc, _, ts) => acc.union(ts), init=acc)
}

///|
/// Sorts a set of taints by term identifier.
pub fn sorted_taints(ts : TaintSet) -> Array[@types.Tid] {
  let out = ts.iter().collect()
  out.sort_by((x, y) => {
    let c = x.id().compare(y.id())
    if c != 0 {
      c
    } else {
      x.to_string().compare(y.to_string())
    }
  })
  out
}

///|
/// The legacy taint map of results: for every term, the taints of the
/// variables it reads (upstream `Propagator.taints`).
pub type TermTaints = @immut_hashmap.HashMap[@types.Tid, @taint.TaintMap]

///|
/// [propagate(taints, tid, v, ts)] adds the taints `ts` of the variable
/// `v` read by the term `tid` (upstream `Propagator.propagate`).
fn propagate_taints(
  taints : TermTaints,
  tid : @types.Tid,
  v : @types.Var,
  ts : TaintSet,
) -> TermTaints {
  if ts.is_empty() {
    return taints
  }
  let map = taints.get(tid).unwrap_or(@taint.TaintMap::empty())
  taints.add(tid, map.add(v.name(), sorted_taints(ts)))
}
