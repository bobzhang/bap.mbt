///|
/// Variable classes that decide which optimization level may touch a
/// variable (`Optimization_main.cls`).
pub(all) enum VarClass {
  Phys
  Virt
  Flag
} derive(Eq, Debug)

///|
/// Classifies a variable as a processor flag, a physical register, or a
/// virtual (lifter-generated) variable.
pub fn classify(is_flag : (@types.Var) -> Bool, v : @types.Var) -> VarClass {
  if is_flag(v) {
    Flag
  } else if v.is_physical() {
    Phys
  } else {
    Virt
  }
}

///|
/// `true` if a variable may be optimized at the given level: level 1 touches
/// virtual variables, level 2 also flags, and level 3 all variables.
pub fn is_optimization_allowed(
  is_flag : (@types.Var) -> Bool,
  level : Int32,
  v : @types.Var,
) -> Bool {
  match classify(is_flag, v) {
    Virt => level > 0
    Flag => level > 1
    Phys => level > 2
  }
}

///|
let flag_roles : Array[@core_theory.Role] = [
  Status,
  ZeroFlag,
  CarryFlag,
  SignFlag,
  OverflowFlag,
  ParityFlag,
]

///|
/// The flag predicate of a target (`CPU.is_flag`): a variable is a flag if its
/// base name is a target register with a status or flag role.
pub fn target_is_flag(target : @core_theory.Target) -> (@types.Var) -> Bool {
  let names : @hashset.HashSet[String] = @hashset.HashSet([])
  for role in flag_roles {
    for reg in target.regs(roles=[role]) {
      names.add(reg.name())
    }
  }
  v => names.contains(v.base().name())
}

///|
fn var_key(v : @types.Var) -> String {
  v.to_string()
}

///|
priv struct VarSet {
  items : @hashset.HashSet[String]
}

///|
fn VarSet::new() -> VarSet {
  { items: @hashset.HashSet([]), }
}

///|
fn VarSet::add(self : VarSet, v : @types.Var) -> Unit {
  self.items.add(var_key(v))
}

///|
fn VarSet::add_all(self : VarSet, vs : Array[@types.Var]) -> Unit {
  for v in vs {
    self.add(v)
  }
}

///|
fn VarSet::mem(self : VarSet, v : @types.Var) -> Bool {
  self.items.contains(var_key(v))
}

///|
fn VarSet::copy(self : VarSet) -> VarSet {
  { items: self.items.copy(), }
}

///|
fn VarSet::remove(self : VarSet, v : @types.Var) -> Unit {
  self.items.remove(var_key(v))
}

///|
/// Collects defined and used variables of a subroutine (`def_use_collector`).
fn computed_def_use(sub : @types.Term[@types.Sub]) -> (VarSet, VarSet) {
  let defs = VarSet::new()
  let uses = VarSet::new()
  for blk in sub.blks() {
    for phi in blk.phis() {
      defs.add(phi.phi_lhs())
      uses.add_all(phi.phi_free_vars())
    }
    for def in blk.defs() {
      defs.add(def.lhs())
      uses.add_all(def.def_free_vars())
    }
    for jmp in blk.jmps() {
      uses.add_all(jmp.jmp_free_vars())
    }
  }
  (defs, uses)
}

///|
/// Computes the definitions that define a never used variable. The last
/// definition (in each block) of a keep variable is kept alive.
fn compute_dead(
  can_touch : (@types.Var) -> Bool,
  keep : VarSet,
  sub : @types.Term[@types.Sub],
) -> Array[@types.Tid] {
  let (defs, uses) = computed_def_use(sub)
  let live = v => !(defs.mem(v) && !uses.mem(v))
  let dead = []
  for blk in sub.blks() {
    let keep = keep.copy()
    for def in blk.defs().rev() {
      let v = def.lhs()
      if !can_touch(v) || live(v) {
        continue
      } else if keep.mem(v.base()) {
        keep.remove(v.base())
      } else {
        dead.push(def.tid())
      }
    }
  }
  dead
}

///|
fn clean(
  can_touch : (@types.Var) -> Bool,
  dead : @hashset.HashSet[@types.Tid],
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  sub.map_blks(blk => {
    blk
    .filter_defs(def => !can_touch(def.lhs()) || !dead.contains(def.tid()))
    .filter_phis(phi => !dead.contains(phi.tid()))
  })
}

///|
/// Substitutes variables with expressions (respecting `let` shadowing) and
/// folds constants.
pub fn substitute_exp(
  vars : Map[String, @types.Exp],
  exp : @types.Exp,
) -> @types.Exp {
  substitute_vars(vars, exp).fold_consts()
}

///|
fn substitute_vars(
  vars : Map[String, @types.Exp],
  exp : @types.Exp,
) -> @types.Exp {
  let go = e => substitute_vars(vars, e)
  match exp {
    Int(_) | Unknown(_, _) => exp
    Var(v) =>
      match vars.get(var_key(v)) {
        Some(e) => e
        None => exp
      }
    Let(v, value, body) => {
      let inner = vars.copy()
      inner.remove(var_key(v))
      Let(v, go(value), substitute_exp(inner, body))
    }
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=go(mem), addr=go(addr), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=go(mem), addr=go(addr), value=go(value), endian~)
    Cast(kind~, width~, exp=inner) => Cast(kind~, width~, exp=go(inner))
    Extract(hi~, lo~, exp=inner) => Extract(hi~, lo~, exp=go(inner))
    Concat(high~, low~) => Concat(high=go(high), low=go(low))
    UnOp(op, inner) => UnOp(op, go(inner))
    BinOp(op, lhs, rhs) => BinOp(op, go(lhs), go(rhs))
    Ite(cond~, yes~, no~) => Ite(cond=go(cond), yes=go(yes), no=go(no))
  }
}

///|
fn substitute_sub(
  sub : @types.Term[@types.Sub],
  vars : Map[String, @types.Exp],
) -> @types.Term[@types.Sub] {
  sub.map_blks(blk => {
    blk.map_elts(
      def=d => {
        let rhs = substitute_exp(vars, d.rhs())
        if d.rhs() != rhs {
          mark_updated(d.with_rhs(rhs))
        } else {
          d
        }
      },
      jmp=j => {
        let j2 = j.map_jmp_exp(e => substitute_exp(vars, e))
        if j.cond() != j2.cond() || j.kind() != j2.kind() {
          mark_updated(j2)
        } else {
          j
        }
      },
    )
  })
}

///|
/// A simple constant propagation over a subroutine in SSA form: variables
/// defined by integer constants or unknowns are substituted by their values.
fn propagate_consts(
  can_touch : (@types.Var) -> Bool,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let vars : Map[String, @types.Exp] = Map([])
  for blk in sub.blks() {
    for def in blk.defs() {
      let v = def.lhs()
      if can_touch(v) {
        match def.rhs() {
          Unknown(_, _) | Int(_) as exp => vars[var_key(v)] = exp
          _ => ()
        }
      }
    }
  }
  substitute_sub(sub, vars)
}

///|
/// Variables that must be preserved across subroutines: the physical free
/// variables of each subroutine plus the variables of subroutine arguments.
fn free_vars(prog : @types.Term[@types.Program]) -> VarSet {
  let result = VarSet::new()
  for sub in prog.subs() {
    for arg in sub.args() {
      result.add_all(arg.arg_rhs().free_vars())
      result.add(arg.arg_lhs())
    }
    for v in @types.Sub::free_vars(sub) {
      if v.is_physical() {
        result.add(v)
      }
    }
  }
  result
}

///|
/// Runs constant propagation and dead code elimination to a fixed point over
/// the SSA form of `sub` (`process_sub`).
fn process_sub(
  free : VarSet,
  can_touch : (@types.Var) -> Bool,
  sub : @types.Term[@types.Sub],
) -> OptimizationData {
  let dead_all = []
  let mut s = sub.to_ssa()
  for ;; {
    s = propagate_consts(can_touch, s)
    let dead = compute_dead(can_touch, free, s)
    dead_all.append(dead)
    if dead.is_empty() {
      break
    }
    s = clean(can_touch, @hashset.from_array(dead), s)
  }
  OptimizationData::create(deads=dead_all, s)
}

///|
/// The cache key of a subroutine (`digest_of_sub`): the set of term addresses,
/// the subroutine name, and the optimization level.
pub fn digest_of_sub(sub : @types.Term[@types.Sub], level : Int32) -> String {
  let addrs : Array[String] = []
  let add = (attrs : Map[String, String]) => {
    match attrs.get("address") {
      Some(a) => if !addrs.contains(a) { addrs.push(a) }
      None => ()
    }
  }
  for blk in sub.blks() {
    add(blk.attrs())
    for elt in blk.elts() {
      match elt {
        DefElt(d) => add(d.attrs())
        JmpElt(j) => add(j.attrs())
        PhiElt(p) => add(p.attrs())
      }
    }
  }
  addrs.sort()
  "optimization:\{addrs.join(",")}:\{sub.sub_name()}:\{level}"
}

///|
/// An in-memory stand-in for BAP's `Data.Cache` service, keyed by
/// `digest_of_sub`.
pub struct OptimizationCache {
  entries : Map[String, OptimizationData]
}

///|
pub fn OptimizationCache::new() -> OptimizationCache {
  { entries: Map([]), }
}

///|
pub fn OptimizationCache::load(
  self : OptimizationCache,
  digest : String,
) -> OptimizationData? {
  self.entries.get(digest)
}

///|
pub fn OptimizationCache::save(
  self : OptimizationCache,
  digest : String,
  data : OptimizationData,
) -> Unit {
  self.entries[digest] = data
}

///|
pub fn OptimizationCache::length(self : OptimizationCache) -> Int32 {
  self.entries.length()
}

///|
/// Optimizes every subroutine of `prog` at the given `level`.
///
/// Applies constant folding, constant propagation, and dead code elimination
/// in a loop until a fixed point is reached, then removes unreachable jumps and
/// blocks. `is_flag` classifies processor flags (see `target_is_flag`).
pub fn optimize_program(
  prog : @types.Term[@types.Program],
  level~ : Int32,
  is_flag~ : (@types.Var) -> Bool = _ => false,
  cache? : OptimizationCache,
) -> @types.Term[@types.Program] {
  let can_touch = v => is_optimization_allowed(is_flag, level, v)
  let free = free_vars(prog)
  prog.map_subs(sub => {
    let digest = digest_of_sub(sub, level)
    match cache.bind(c => c.load(digest)) {
      Some(data) => data.apply(sub)
      None => {
        let data = process_sub(free, can_touch, sub)
        let sub = data.update(sub)
        let data = data.find_unreachable(sub)
        if cache is Some(c) {
          c.save(digest, data)
        }
        data.remove_dead_code(sub)
      }
    }
  })
}

///|
/// Optimizes the project program (`Optimization_main.run`), classifying flags
/// with the project target unless `is_flag` is given.
pub fn run(
  project : @project.Project,
  level~ : Int32,
  is_flag? : (@types.Var) -> Bool,
  cache? : OptimizationCache,
) -> @project.Project {
  let is_flag = match is_flag {
    Some(f) => f
    None => target_is_flag(project.target())
  }
  project.map_program(prog => optimize_program(prog, level~, is_flag~, cache?))
}

///|
pub extend VarClass with Eq::{not_equal, equal}

///|
pub extend VarClass with Debug::{to_repr}
