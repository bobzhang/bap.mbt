// The legacy (term attribute based) representation of taints (upstream
// `Bap.Std.Taint` from `bap_sema_taint.ml`): taints are term identifiers
// (seeds), terms that introduce taints are marked with the `tainted-reg`
// and `tainted-ptr` attributes and the results of a propagation are
// stored in the `tainted-regs` and `tainted-ptrs` attributes, that map
// variables to sets of taints.
//
// Attributes are textual in this port. A taint map is rendered as the
// upstream s-expression `((x (%00000001 %00000002)) (y (%00000003)))`,
// which is also what the BML `has-tainted-reg`/`has-tainted-ptr`
// predicates parse. Variables are identified by their names.

///|
/// The attribute of a definition that introduces a register taint
/// (upstream `Taint.reg`).
pub let tainted_reg_attr : String = "tainted-reg"

///|
/// The attribute of a definition that introduces a pointer taint
/// (upstream `Taint.ptr`).
pub let tainted_ptr_attr : String = "tainted-ptr"

///|
/// The attribute that maps variables used by a term to the taints of
/// their values (upstream `Taint.regs`).
pub let tainted_regs_attr : String = "tainted-regs"

///|
/// The attribute that maps variables used by a term to the taints of the
/// memory they point to (upstream `Taint.ptrs`).
pub let tainted_ptrs_attr : String = "tainted-ptrs"

///|
priv struct TidKey(@types.Tid) derive(Eq)

///|
impl Compare for TidKey with fn compare(self, other) {
  let c = self.0.id().compare(other.0.id())
  if c != 0 {
    c
  } else {
    self.0.to_string().compare(other.0.to_string())
  }
}

///|
/// A persistent map from variables (names) to sets of taints (upstream
/// `Taint.map`).
pub struct TaintMap {
  priv map : @sorted_map.SortedMap[String, @sorted_set.SortedSet[TidKey]]
} derive(Eq)

///|
pub extend TaintMap with Eq::{not_equal, equal}

///|
/// The empty map.
pub fn TaintMap::empty() -> TaintMap {
  { map: @sorted_map.SortedMap::new(), }
}

///|
pub fn TaintMap::is_empty(self : TaintMap) -> Bool {
  self.map.is_empty()
}

///|
/// Adds the taints to the set of taints of the variable. Adding an empty
/// set of taints doesn't create a binding.
pub fn TaintMap::add(
  self : TaintMap,
  name : String,
  taints : ArrayView[@types.Tid],
) -> TaintMap {
  if taints.is_empty() {
    return self
  }
  let set = @sorted_set.SortedSet::from_iter(taints.iter().map(t => TidKey(t)))
  let set = match self.map.get(name) {
    None => set
    Some(old) => old.union(set)
  }
  { map: self.map.add(name, set), }
}

///|
/// The union of two maps (upstream `Taint.merge`).
pub fn TaintMap::union(self : TaintMap, other : TaintMap) -> TaintMap {
  other.map.fold(
    (acc, name, set) => acc.add(name, set.to_array().map(k => k.0)),
    init=self,
  )
}

///|
/// The taints of the variable, in ascending order.
pub fn TaintMap::get(self : TaintMap, name : String) -> Array[@types.Tid] {
  match self.map.get(name) {
    None => []
    Some(set) => set.to_array().map(k => k.0)
  }
}

///|
/// All bindings, sorted by variable name.
pub fn TaintMap::bindings(
  self : TaintMap,
) -> Array[(String, Array[@types.Tid])] {
  self.map.to_array().map(p => (p.0, p.1.to_array().map(k => k.0)))
}

///|
/// All taints of the map, in ascending order.
pub fn TaintMap::taints(self : TaintMap) -> Array[@types.Tid] {
  let all : @sorted_set.SortedSet[TidKey] = self.map.fold(
    (acc, _, set) => acc.union(set),
    init=@sorted_set.SortedSet::new(),
  )
  all.to_array().map(k => k.0)
}

///|
/// Renders the map as an s-expression, e.g. `((x (%00000001)))`.
pub fn TaintMap::to_string(self : TaintMap) -> String {
  let bindings = self
    .bindings()
    .map(p => {
      let (name, tids) = p
      @primus.Sexp::List([Atom(name), List(tids.map(t => Atom(t.to_string())))])
    })
  @primus.Sexp::List(bindings).to_string()
}

///|
pub impl Show for TaintMap with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub extend TaintMap with Show::{output}

///|
/// Parses a map rendered by `TaintMap::to_string`. Tokens that are not
/// term identifiers are ignored.
pub fn TaintMap::parse(text : String) -> TaintMap raise {
  let mut map = TaintMap::empty()
  match @primus.Sexp::parse(text) {
    List(bindings) =>
      for binding in bindings {
        match binding {
          List([Atom(name), List(taints)]) => {
            let tids = []
            for t in taints {
              if t is Atom(s) && @types.Tid::from_string(s) is Ok(tid) {
                tids.push(tid)
              }
            }
            map = map.add(name, tids)
          }
          _ => fail("taint map: malformed binding \{binding}")
        }
      }
    Atom(s) => fail("taint map: expected a list, got \{s}")
  }
  map
}

///|
/// The taint map stored in the attribute `key` of the term; empty if the
/// attribute is absent or malformed.
pub fn[T] term_taint_map(term : @types.Term[T], key : String) -> TaintMap {
  match term.get_attr(key) {
    None => TaintMap::empty()
    Some(text) => TaintMap::parse(text) catch { _ => TaintMap::empty() }
  }
}

///|
/// Stores the taint map in the attribute `key` of the term.
pub fn[T] set_term_taint_map(
  term : @types.Term[T],
  key : String,
  map : TaintMap,
) -> @types.Term[T] {
  term.set_attr(@types.Attr::new(key~, value=map.to_string()))
}

///|
/// Merges the taint map into the attribute `key` of the term.
pub fn[T] merge_term_taint_map(
  term : @types.Term[T],
  key : String,
  map : TaintMap,
) -> @types.Term[T] {
  match term.get_attr(key) {
    None => set_term_taint_map(term, key, map)
    Some(_) =>
      set_term_taint_map(term, key, term_taint_map(term, key).union(map))
  }
}
