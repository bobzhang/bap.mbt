///|
/// Per-block liveness transfer function (the upstream `Live.tran`
/// record): the KILL set `defs` and the GEN set `uses` of a block.
priv struct LiveTransfer {
  defs : Array[Var]
  uses : Array[Var]
}

///|
/// Subroutine liveness information, a port of upstream `Bap_sema_free_vars.Live`.
///
/// The analysis runs backwards over the subroutine tid graph
/// (`Term::sub_tid_graph`, i.e. the CFG plus the pseudo `start`/`exit`
/// nodes). The `exit` pseudo node is seeded with the `keep` variables and
/// with the free variables of every `Out`/`Both` subroutine argument, so
/// output arguments are kept alive at the exit from the subroutine.
///
/// Phi-nodes follow upstream semantics: for `x0 := phi([b1,x1];...;[bN,xN])`
/// the variable `x0` is treated as defined at the end of each predecessor
/// `bi` and `xi` as used by `bi` (unless `bi` defines it). Consequently
/// `x0` may be live-in at the phi block and live-out of the predecessors.
struct Live {
  order : Array[Tid]
  blks : Map[Tid, LiveTransfer]
  outs : @graphlib.Fixpoint[Tid, Array[Var]]
}

///|
fn live_union(lhs : Array[Var], rhs : Array[Var]) -> Array[Var] {
  let out = lhs.copy()
  add_vars(out, rhs)
  out
}

///|
fn live_lookup(blks : Map[Tid, LiveTransfer], tid : Tid) -> LiveTransfer {
  match blks.get(tid) {
    Some(tran) => tran
    None => { defs: [], uses: [], }
  }
}

///|
fn live_apply(tran : LiveTransfer, vars : Array[Var]) -> Array[Var] {
  let out = vars_without(vars, tran.defs)
  add_vars(out, tran.uses)
  out
}

///|
fn live_is_pseudo(tid : Tid) -> Bool {
  tid == tid_graph_start_node || tid == tid_graph_exit_node
}

///|
fn live_transfer(
  blks : Map[Tid, LiveTransfer],
  tid : Tid,
  vars : Array[Var],
) -> Array[Var] {
  if live_is_pseudo(tid) {
    vars
  } else {
    live_apply(live_lookup(blks, tid), vars)
  }
}

///|
/// Upstream `block_transitions`: the KILL set of a block is the set of its
/// def left-hand sides and the GEN set is `Blk.free_vars`. Then every
/// phi-node operand `(src, e)` adds the phi left-hand side to the KILL set
/// of `src` and `free_vars(e) - defs(src)` to its GEN set (a transition is
/// created for `src` when it is not a block of the subroutine).
fn Term::live_block_transitions(
  self : Term[Sub],
) -> (Array[Tid], Map[Tid, LiveTransfer]) {
  let order = []
  let blks : Map[Tid, LiveTransfer] = Map([])
  for blk in self.payload_value.blks {
    if !blks.contains(blk.tid()) {
      order.push(blk.tid())
    }
    blks[blk.tid()] = {
      defs: blk.blk_def_lhs_vars(),
      uses: blk.blk_free_vars(),
    }
  }
  for blk in self.payload_value.blks {
    for phi in blk.payload_value.phis {
      for pair in phi.values() {
        let (src, exp) = pair
        let had = match blks.get(src) {
          Some(tran) => tran
          None => {
            order.push(src)
            { defs: [], uses: [], }
          }
        }
        let defs = had.defs.copy()
        add_var(defs, phi.phi_lhs())
        let uses = had.uses.copy()
        add_vars(uses, vars_without(exp.free_vars(), had.defs))
        blks[src] = { defs, uses, }
      }
    }
  }
  (order, blks)
}

///|
/// Upstream `Live.initialize`: the variables that are live at the exit
/// pseudo node, i.e. `keep` plus the free variables of the right-hand sides
/// of `Out` and `Both` arguments.
fn Term::live_exit_vars(self : Term[Sub], keep : Array[Var]) -> Array[Var] {
  let vars = []
  add_vars(vars, keep)
  for arg in self.payload_value.args {
    match arg.intent() {
      Some(Out) | Some(Both) => add_vars(vars, arg.arg_rhs().free_vars())
      None | Some(In) => ()
    }
  }
  vars
}

///|
/// Computes the liveness information of a subroutine (upstream
/// `Live.compute ?keep sub`).
///
/// Variables in `keep` are kept live at the exit from the subroutine, in
/// addition to the free variables of `Out`/`Both` arguments.
pub fn Live::compute(sub : Term[Sub], keep? : Array[Var] = []) -> Live {
  let graph = sub.sub_tid_graph()
  let (order, blks) = sub.live_block_transitions()
  let exit_vars = sub.live_exit_vars(keep)
  let constraints : Map[Tid, Array[Var]] = Map([])
  constraints[tid_graph_exit_node] = exit_vars
  let init = @graphlib.Fixpoint::create(constraints, [])
  let outs = graph.fixpoint(
    init~,
    start=Some(tid_graph_exit_node),
    rev=true,
    merge=live_union,
    equal=var_set_equal,
    f=(tid, vars) => live_transfer(blks, tid, vars),
  )
  { order, blks, outs, }
}

///|
/// Method-style alias of `Live::compute`.
pub fn Term::sub_live(self : Term[Sub], keep? : Array[Var] = []) -> Live {
  Live::compute(self, keep~)
}

///|
/// The set of variables live at the exit from the block `blk` (upstream
/// `Live.outs`). Empty when `blk` does not belong to the subroutine graph.
pub fn Live::outs(self : Live, blk : Tid) -> Array[Var] {
  self.outs.get(blk).copy()
}

///|
/// The set of variables live at the entry to the block `blk` (upstream
/// `Live.ins`). Empty when `blk` does not belong to the subroutine graph.
pub fn Live::ins(self : Live, blk : Tid) -> Array[Var] {
  live_transfer(self.blks, blk, self.outs.get(blk))
}

///|
/// The KILL set of the block `blk` (upstream `Live.defs`), including the
/// left-hand sides of the phi-nodes that `blk` feeds.
pub fn Live::defs(self : Live, blk : Tid) -> Array[Var] {
  live_lookup(self.blks, blk).defs.copy()
}

///|
/// The GEN set of the block `blk` (upstream `Live.uses`), including the
/// phi-node operands that flow out of `blk`.
pub fn Live::uses(self : Live, blk : Tid) -> Array[Var] {
  live_lookup(self.blks, blk).uses.copy()
}

///|
/// Folds over the live-in sets of the blocks (upstream `Live.fold`). The
/// pseudo `start` and `exit` nodes are not folded over.
pub fn[A] Live::fold(
  self : Live,
  init~ : A,
  f : (A, Tid, Array[Var]) -> A,
) -> A {
  let mut acc = init
  for tid in self.order {
    acc = f(
      acc,
      tid,
      live_apply(live_lookup(self.blks, tid), self.outs.get(tid)),
    )
  }
  acc
}

///|
/// The blocks at which `variable` is live-in (upstream `Live.blks`).
pub fn Live::blks(self : Live, variable : Var) -> Array[Tid] {
  self.fold(init=[], (blks, blk, ins) => {
    if ins.contains(variable) {
      blks.push(blk)
    }
    blks
  })
}

///|
/// The variables that are live in the subroutine, i.e. live at the pseudo
/// `start` node (upstream `Live.vars`). These are the free (upper-exposed)
/// variables of the subroutine.
pub fn Live::vars(self : Live) -> Array[Var] {
  self.outs(tid_graph_start_node)
}

///|
/// The underlying fixpoint solution mapping nodes to their live-outs
/// (upstream `Live.solution`).
pub fn Live::solution(self : Live) -> @graphlib.Fixpoint[Tid, Array[Var]] {
  self.outs
}

///|
/// Renders the live-in sets of each block, one `tid: (vars)` line per block
/// (upstream `Live.pp`).
pub impl Show for Live with fn output(self, logger) {
  self.fold(init=(), (_, blk, vars) => {
    logger.write_string(blk.to_string())
    logger.write_string(": (")
    logger.write_string(vars.map(v => v.to_string()).join(" "))
    logger.write_string(")\n")
  })
}

///|
pub extend Live with Show::{to_string, output}

///|
/// Upstream `Sub.compute_liveness` (deprecated upstream in favour of
/// `Live.compute`): the live-out solution of the subroutine.
pub fn Sub::compute_liveness(
  sub : Term[Sub],
) -> @graphlib.Fixpoint[Tid, Array[Var]] {
  Live::compute(sub).solution()
}

///|
/// Upstream `Sub.free_vars`: variables that are used before being defined
/// in the subroutine. For SSA subroutines these are the variables with index
/// `0` occurring free in some block; otherwise they are `Live::vars`.
///
/// Note that `Term::sub_free_vars` is a different, purely syntactic union of
/// the free variables of every argument and block.
pub fn Sub::free_vars(sub : Term[Sub]) -> Array[Var] {
  if sub.is_ssa() {
    sub.sub_ssa_free_vars()
  } else {
    Live::compute(sub).vars()
  }
}
