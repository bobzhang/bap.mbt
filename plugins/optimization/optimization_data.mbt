///|
/// A recorded update of a jump term (`Optimization_data.jmp_update`).
pub(all) struct JmpUpdate {
  cond : @types.Exp
  kind : @types.JmpKind
} derive(Eq, Debug)

///|
/// A recorded update of a term (`Optimization_data.update`).
pub(all) enum TermUpdate {
  Rhs(@types.Exp)
  Jmp(JmpUpdate)
} derive(Eq, Debug)

///|
pub extend JmpUpdate with Eq::{not_equal, equal}

///|
pub extend JmpUpdate with Debug::{to_repr}

///|
pub extend TermUpdate with Eq::{not_equal, equal}

///|
pub extend TermUpdate with Debug::{to_repr}

///|
/// The result of optimizing a subroutine (`Optimization_data.t`): the set of
/// dead terms and the rewritten right-hand sides/jump conditions, keyed by
/// term identifiers of the original (non-SSA) subroutine.
pub struct OptimizationData {
  deads : Array[@types.Tid]
  updates : Map[@types.Tid, TermUpdate]
}

///|
let updated_term_attr = "updated-term"

///|
/// Marks a term as updated by the optimizer (`Optimization_data.mark_updated`).
pub fn[T] mark_updated(term : @types.Term[T]) -> @types.Term[T] {
  term.set_attr(@types.Attr::new(key=updated_term_attr, value="()"))
}

///|
/// `true` if the term was marked with `mark_updated`.
pub fn[T] is_updated(term : @types.Term[T]) -> Bool {
  term.has_attr(updated_term_attr)
}

///|
/// Replaces SSA variables with their base variables (`drop_index`).
fn drop_index(exp : @types.Exp) -> @types.Exp {
  match exp {
    Int(_) | Unknown(_, _) => exp
    Var(v) => Var(v.base())
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=drop_index(mem), addr=drop_index(addr), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(
        mem=drop_index(mem),
        addr=drop_index(addr),
        value=drop_index(value),
        endian~,
      )
    Let(v, value, body) => Let(v.base(), drop_index(value), drop_index(body))
    Cast(kind~, width~, exp=inner) => Cast(kind~, width~, exp=drop_index(inner))
    Extract(hi~, lo~, exp=inner) => Extract(hi~, lo~, exp=drop_index(inner))
    Concat(high~, low~) => Concat(high=drop_index(high), low=drop_index(low))
    UnOp(op, inner) => UnOp(op, drop_index(inner))
    BinOp(op, lhs, rhs) => BinOp(op, drop_index(lhs), drop_index(rhs))
    Ite(cond~, yes~, no~) =>
      Ite(cond=drop_index(cond), yes=drop_index(yes), no=drop_index(no))
  }
}

///|
fn updates_of_sub(sub : @types.Term[@types.Sub]) -> Map[@types.Tid, TermUpdate] {
  let updates : Map[@types.Tid, TermUpdate] = Map([])
  for blk in sub.blks() {
    for def in blk.defs() {
      if is_updated(def) {
        updates[def.tid()] = Rhs(drop_index(def.rhs()))
      }
    }
    for jmp in blk.jmps() {
      if is_updated(jmp) {
        let jmp = jmp.map_jmp_exp(drop_index)
        updates[jmp.tid()] = Jmp({ cond: jmp.cond(), kind: jmp.kind(), })
      }
    }
  }
  updates
}

///|
/// Creates the optimization data from the set of dead terms and the (SSA)
/// subroutine whose updated terms are recorded (`Optimization_data.create`).
pub fn OptimizationData::create(
  deads~ : Array[@types.Tid],
  sub : @types.Term[@types.Sub],
) -> OptimizationData {
  { deads: dedup_tids(deads), updates: updates_of_sub(sub), }
}

///|
/// The dead term identifiers.
pub fn OptimizationData::deads(self : OptimizationData) -> Array[@types.Tid] {
  self.deads.copy()
}

///|
/// The recorded term updates, in recording order.
pub fn OptimizationData::updates(
  self : OptimizationData,
) -> Array[(@types.Tid, TermUpdate)] {
  self.updates.to_array()
}

///|
fn dedup_tids(tids : Array[@types.Tid]) -> Array[@types.Tid] {
  let seen : @hashset.HashSet[@types.Tid] = @hashset.HashSet([])
  let result = []
  for tid in tids {
    if !seen.contains(tid) {
      seen.add(tid)
      result.push(tid)
    }
  }
  result
}

///|
fn OptimizationData::dead_set(
  self : OptimizationData,
) -> @hashset.HashSet[@types.Tid] {
  @hashset.from_array(self.deads)
}

///|
/// Jumps that can never be taken: those with a constant false condition and
/// those that follow a jump with a constant true condition.
fn dead_jmps_of_blk(blk : @types.Term[@types.Blk]) -> Array[@types.Tid] {
  let deads = []
  let mut is_unreachable = false
  for jmp in blk.jmps() {
    if is_unreachable {
      deads.push(jmp.tid())
    } else {
      match jmp.cond() {
        Int(x) if x.bitwidth() == 1 && x.is_one() => is_unreachable = true
        Int(x) if x.bitwidth() == 1 && x.is_zero() => deads.push(jmp.tid())
        _ => ()
      }
    }
  }
  deads
}

///|
/// Extends the data with unreachable jumps and blocks of `sub`
/// (`Optimization_data.find_unreachable`).
pub fn OptimizationData::find_unreachable(
  self : OptimizationData,
  sub : @types.Term[@types.Sub],
) -> OptimizationData {
  let dead_jmps : @hashset.HashSet[@types.Tid] = @hashset.HashSet([])
  for blk in sub.blks() {
    for tid in dead_jmps_of_blk(blk) {
      dead_jmps.add(tid)
    }
  }
  let graph = sub
    .to_graph()
    .filtered(skip_edge=edge => dead_jmps.contains(edge.label()))
  let reachable = graph.reachable(@types.tid_graph_start())
  let deads = self.deads.copy()
  for blk in sub.blks() {
    for jmp in blk.jmps() {
      if dead_jmps.contains(jmp.tid()) {
        deads.push(jmp.tid())
      }
    }
  }
  for node in graph.nodes() {
    if !reachable.contains(node) && node != @types.tid_graph_exit() {
      deads.push(node)
    }
  }
  { ..self, deads: dedup_tids(deads), }
}

///|
fn update_def(
  updates : Map[@types.Tid, TermUpdate],
  def : @types.Term[@types.Def],
) -> @types.Term[@types.Def] {
  match updates.get(def.tid()) {
    Some(Rhs(exp)) => def.with_rhs(exp)
    _ => def
  }
}

///|
fn update_jmp(
  updates : Map[@types.Tid, TermUpdate],
  jmp : @types.Term[@types.Jmp],
) -> @types.Term[@types.Jmp] {
  match updates.get(jmp.tid()) {
    Some(Jmp({ cond, kind, })) => jmp.with_cond(cond).with_kind(kind)
    _ => jmp
  }
}

///|
/// Applies the recorded rewrites to `sub` without removing dead code
/// (`Optimization_data.update`).
pub fn OptimizationData::update(
  self : OptimizationData,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  sub.map_blks(blk => {
    blk
    .map_defs(def => update_def(self.updates, def))
    .map_jmps(jmp => update_jmp(self.updates, jmp))
  })
}

///|
/// Removes dead blocks, definitions, and jumps from `sub`
/// (`Optimization_data.remove_dead_code`).
pub fn OptimizationData::remove_dead_code(
  self : OptimizationData,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let deads = self.dead_set()
  sub.filter_map_blks(blk => {
    if deads.contains(blk.tid()) {
      None
    } else {
      Some(
        blk
        .filter_defs(def => !deads.contains(def.tid()))
        .filter_jmps(jmp => !deads.contains(jmp.tid())),
      )
    }
  })
}

///|
/// Applies both the rewrites and the dead code removal to `sub`
/// (`Optimization_data.apply`), used when the data comes from the cache.
pub fn OptimizationData::apply(
  self : OptimizationData,
  sub : @types.Term[@types.Sub],
) -> @types.Term[@types.Sub] {
  let deads = self.dead_set()
  sub.filter_map_blks(blk => {
    if deads.contains(blk.tid()) {
      None
    } else {
      Some(
        blk
        .filter_map_defs(def => {
          if deads.contains(def.tid()) {
            None
          } else {
            Some(update_def(self.updates, def))
          }
        })
        .filter_map_jmps(jmp => {
          if deads.contains(jmp.tid()) {
            None
          } else {
            Some(update_jmp(self.updates, jmp))
          }
        }),
      )
    }
  })
}
