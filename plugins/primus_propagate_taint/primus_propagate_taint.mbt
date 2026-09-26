// Port of `plugins/primus_propagate_taint`: a compatibility layer between
// the Primus Taint Analysis Framework (the `taint` package) and the
// legacy, term attribute based, taint propagation framework (the
// `propagate_taint` plugin).
//
// The translation maps the `tainted-reg`/`tainted-ptr` attributes to taint
// introductions of the framework (the `taint-intro` component) and
// reflects the state of the framework into the `tainted-regs` and
// `tainted-ptrs` attributes (the `taint-mapper` and `taint-marker`
// components). Since an attribute is attached to a whole term and not to
// a value, the translation is lossy:
//
// - a term marked as a taint source taints the value of its left-hand
//   side (directly for `tainted-reg`, indirectly for `tainted-ptr`);
// - if the right-hand side is a load or a store, then for `tainted-reg`
//   the address is tainted as a pointer to the object, and for
//   `tainted-ptr` the address is dereferenced and the loaded value is
//   tainted as a pointer;
// - otherwise all variables used in the right-hand side are assumed to
//   reference the tainted object.

///|
/// The kind of a legacy seed attribute.
priv enum Seed {
  Reg
  Ptr
}

///|
/// The mapping between the objects of the framework and the legacy
/// taints (term identifiers of seeds) and the reflected state: for every
/// term, the taints of the variables it uses.
priv struct Mapper {
  regs : @immut_hashmap.HashMap[@types.Tid, @taint.TaintMap]
  ptrs : @immut_hashmap.HashMap[@types.Tid, @taint.TaintMap]
  tids : @sorted_map.SortedMap[@taint.Object, @types.Tid]
}

///|
let mapper : @primus.State[Mapper] = @primus.State::declare_(
  name="primus-taint-mapper",
  uuid="12511d75-e626-4b0d-8dcd-2a3b597992cf",
  _ => {
    regs: @immut_hashmap.HashMap::new(),
    ptrs: @immut_hashmap.HashMap::new(),
    tids: @sorted_map.SortedMap::new(),
  },
)

///|
fn is_mem(v : @types.Var) -> Bool {
  v.typ() is Mem(_)
}

///|
/// The legacy seed of the object, if the object was introduced by the
/// `taint-intro` component.
pub fn seed_of(m : @primus.Machine, obj : @taint.Object) -> @types.Tid? {
  m.get_local(mapper).tids.get(obj)
}

///|
/// The `tainted-regs` map of the term: the taints of the values of the
/// variables used by the term, as reflected by the `taint-mapper`.
pub fn tainted_regs(m : @primus.Machine, tid : @types.Tid) -> @taint.TaintMap {
  m.get_local(mapper).regs.get(tid).unwrap_or(@taint.TaintMap::empty())
}

///|
/// The `tainted-ptrs` map of the term: the taints of the memory pointed
/// by the variables used by the term, as reflected by the `taint-mapper`.
pub fn tainted_ptrs(m : @primus.Machine, tid : @types.Tid) -> @taint.TaintMap {
  m.get_local(mapper).ptrs.get(tid).unwrap_or(@taint.TaintMap::empty())
}

// ---------------------------------------------------------------------------
// Intro

///|
/// The kind of the objects introduced for the seed `t`: `user-<t>`.
fn seed_kind(m : @primus.Machine, t : @types.Tid) -> @taint.Kind raise {
  @taint.Kind::create(m, "user-\{t.to_string()}")
}

///|
fn gentaint(
  m : @primus.Machine,
  t : @types.Tid,
) -> @sorted_set.SortedSet[@taint.Object] raise {
  let taint = @taint.Object::create(m, seed_kind(m, t))
  m.update_local(mapper, s => { ..s, tids: s.tids.add(taint, t), })
  @sorted_set.SortedSet::singleton(taint)
}

///|
/// The seed introduced by the definition: the `tainted-reg` attribute is
/// looked up first (upstream `translation`).
fn introduces(def : @types.Term[@types.Def]) -> (@types.Tid, Seed, @taint.Rel)? {
  match def.tainted_reg() {
    Some(t) => Some((t, Reg, Direct))
    None =>
      match def.tainted_ptr() {
        Some(t) => Some((t, Ptr, Indirect))
        None => None
      }
  }
}

///|
fn taint_var(
  m : @primus.Machine,
  rel : @taint.Rel,
  taints : @sorted_set.SortedSet[@taint.Object],
  v : @types.Var,
) -> Unit raise {
  if !is_mem(v) {
    @taint.Tracker::attach(m, @primus.Env::get(m, v), rel, taints)
  }
}

///|
fn size_of(typ : @types.ValueType) -> @types.Size? {
  match typ {
    Imm(n) => @types.Size::of_int_opt(n)
    Mem(_) => None
  }
}

///|
fn taint_access(
  m : @primus.Machine,
  seed : Seed,
  taints : @sorted_set.SortedSet[@taint.Object],
  addr : @types.Exp,
  endian : @bitvec.Endian,
  size : @types.Size?,
) -> Unit raise {
  let ptr = @primus.Interpreter::exp(m, addr)
  match seed {
    Reg => @taint.Tracker::attach(m, ptr, Indirect, taints)
    Ptr =>
      match size {
        None => ()
        Some(sz) => {
          let v = @primus.Interpreter::load(m, ptr, endian, sz)
          @taint.Tracker::attach(m, v, Indirect, taints)
        }
      }
  }
}

///|
/// Introduces the taint of a definition marked with `tainted-reg` or
/// `tainted-ptr` (upstream `Intro.intro`).
fn intro(m : @primus.Machine, def : @types.Term[@types.Def]) -> Unit raise {
  guard introduces(def) is Some((seed_tid, seed, rel)) else { return }
  let t = gentaint(m, seed_tid)
  taint_var(m, rel, t, def.lhs())
  match def.rhs() {
    Load(addr~, endian~, typ~, ..) =>
      taint_access(m, seed, t, addr, endian, size_of(typ))
    Store(addr~, endian~, value~, ..) => {
      let size = match value.infer_type() {
        Ok(typ) => size_of(typ)
        Err(_) => None
      }
      taint_access(m, seed, t, addr, endian, size)
    }
    exp =>
      for v in exp.free_vars() {
        taint_var(m, rel, t, v)
      }
  }
}

///|
/// The `taint-intro` component: introduces a taint when a term marked
/// with `tainted-reg` or `tainted-ptr` is evaluated (upstream `Intro`).
pub fn intro_component(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_def, def => intro(m, def))
}

// ---------------------------------------------------------------------------
// Mapper

///|
fn remap(
  tids : @sorted_map.SortedMap[@taint.Object, @types.Tid],
  objs : @sorted_set.SortedSet[@taint.Object],
) -> Array[@types.Tid] {
  let out = []
  for o in objs {
    if tids.get(o) is Some(t) {
      out.push(t)
    }
  }
  out
}

///|
fn update_field(
  s : Mapper,
  rel : @taint.Rel,
  tid : @types.Tid,
  v : @types.Var,
  taints : Array[@types.Tid],
) -> Mapper {
  let field = match rel {
    Direct => s.regs
    Indirect => s.ptrs
  }
  let map = field.get(tid).unwrap_or(@taint.TaintMap::empty())
  let field = field.add(tid, map.add(v.name(), taints))
  match rel {
    Direct => { ..s, regs: field, }
    Indirect => { ..s, ptrs: field, }
  }
}

///|
/// Records the taints of the variables used by the term (upstream
/// `Mapper.update`).
fn update(
  m : @primus.Machine,
  vars : Array[@types.Var],
  tid : @types.Tid,
) -> Unit raise {
  for rel in [@taint.Rel::Indirect, Direct] {
    let mut s = m.get_local(mapper)
    for v in vars {
      if is_mem(v) || !@primus.Env::has(m, v) {
        continue
      }
      let value = @primus.Env::get(m, v)
      let taints = remap(s.tids, @taint.Tracker::lookup(m, value, rel))
      if !taints.is_empty() {
        s = update_field(s, rel, tid, v, taints)
      }
    }
    m.put_local(mapper, s)
  }
}

///|
/// The `taint-mapper` component: maintains the mapping between the
/// objects of the framework and the variables of the terms (upstream
/// `Mapper`).
pub fn mapper_component(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_def, def => update(m, def.def_free_vars(), def.tid()))
  m.observe(@primus.leave_jmp, jmp => update(m, jmp.jmp_free_vars(), jmp.tid()))
}

// ---------------------------------------------------------------------------
// Marker

///|
fn[T] mark_term(s : Mapper, t : @types.Term[T]) -> @types.Term[T] {
  let mark = (
    t : @types.Term[T],
    key : String,
    field : @immut_hashmap.HashMap[@types.Tid, @taint.TaintMap],
  ) => {
    match field.get(t.tid()) {
      Some(map) if !map.is_empty() => @taint.merge_term_taint_map(t, key, map)
      _ => t
    }
  }
  let t = mark(t, @taint.tainted_regs_attr, s.regs)
  mark(t, @taint.tainted_ptrs_attr, s.ptrs)
}

///|
/// Reflects the taints recorded by the mapper into the `tainted-regs` and
/// `tainted-ptrs` attributes of the program terms, merging them with the
/// existing attributes (upstream `Marker.mark_terms`).
fn mark_program(
  s : Mapper,
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    mark_term(s, sub)
    .map_args(arg => mark_term(s, arg))
    .map_blks(blk => {
      mark_term(s, blk)
      .map_phis(t => mark_term(s, t))
      .map_defs(t => mark_term(s, t))
      .map_jmps(t => mark_term(s, t))
    })
  })
}

///|
/// The `taint-marker` component: translates the tainted values of the
/// framework into the `tainted-regs` and `tainted-ptrs` attributes after
/// every block (upstream `Marker`).
pub fn marker_component(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_blk, _ => {
    let s = m.get_local(mapper)
    m.update_project(proj => proj.map_program(prog => mark_program(s, prog)))
  })
}
