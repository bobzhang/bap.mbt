///|
/// A block of the IR graph under construction (upstream `Bil_ir.blk`):
/// its label, whether the label must be kept (`keep`) unless the block is
/// `weak` (the label of a sub-instruction), and its definitions and jumps
/// in the reverse order.
priv struct IrBlk {
  name : @types.Tid
  keep : Bool
  weak : Bool
  defs : @list.List[@types.Term[@types.Def]]
  jmps : @list.List[@types.Term[@types.Jmp]]
}

///|
/// The graphical representation of a program fragment (upstream
/// `Bil_ir.cfg`, the `ir-graph` property of the semantics): the entry
/// label and the blocks, the first block being the exit block.
///
/// Invariants: the graph is empty iff it has no entry; a non-empty graph
/// has a block labeled with the entry; explicitly labeled blocks keep
/// their labels.
pub struct Cfg {
  priv entry : @types.Tid?
  priv blks : @list.List[IrBlk]
}

///|
/// The empty graph.
pub fn Cfg::empty() -> Cfg {
  { entry: None, blks: @list.empty(), }
}

///|
/// `true` for the empty graph.
pub fn Cfg::is_empty(self : Cfg) -> Bool {
  self.entry is None && self.blks.is_empty()
}

///|
/// The entry label.
pub fn Cfg::entry(self : Cfg) -> @types.Tid? {
  self.entry
}

///|
fn fresh() -> @types.Tid {
  @types.Tid::create()
}

///|
fn new_blk(
  tid : @types.Tid,
  keep? : Bool = false,
  weak? : Bool = false,
) -> IrBlk {
  { name: tid, keep, weak, defs: @list.empty(), jmps: @list.empty(), }
}

///|
/// Adds a jump, unless the block already ends with an unconditional one
/// (upstream `(++)`).
fn IrBlk::push_jmp(self : IrBlk, j : @types.Term[@types.Jmp]) -> IrBlk {
  match self.jmps {
    More(t, ..) if @types.Jmp::guard_(t) is None => self
    _ => { ..self, jmps: self.jmps.prepend(j), }
  }
}

///|
fn is_call(j : @types.Term[@types.Jmp]) -> Bool {
  j.alt() is Some(_)
}

///|
fn is_unconditional(j : @types.Term[@types.Jmp]) -> Bool {
  j.cond() is Int(w) && w == @types.Word::b1()
}

///|
/// A direct jump to the label (a call if `is_call`).
fn goto_jmp(
  dst : @types.Tid,
  tid~ : @types.Tid,
  is_call? : Bool = false,
  cond? : @types.Exp,
) -> @types.Term[@types.Jmp] {
  if is_call {
    @types.Jmp::create_call(
      @types.Call::create(target=Direct(dst)),
      cond?,
      tid~,
    )
  } else {
    @types.Jmp::create_goto(Direct(dst), cond?, tid~)
  }
}

///|
fn[A] rev_append(xs : @list.List[A], ys : @list.List[A]) -> @list.List[A] {
  xs.fold(init=ys, (acc, x) => acc.prepend(x))
}

///|
fn[A] list(xs : ArrayView[A]) -> @list.List[A] {
  @list.List(xs)
}

///|
/// Adds a fallthrough to `dst` (upstream `fall`): a call gets `dst` as its
/// return, an unconditional jump is kept as is, otherwise a jump to `dst`
/// is added.
fn fall(tid : @types.Tid, x : IrBlk, dst : @types.Tid) -> IrBlk {
  match x.jmps {
    More(j, tail=Empty) if is_call(j) => {
      let j2 = j.with_dst(Some(@types.Jmp::resolved(dst)))
      if is_unconditional(j) {
        { ..x, jmps: list([j2]), }
      } else {
        { ..x, jmps: list([@types.Jmp::create_goto(Direct(dst)), j2]), }
      }
    }
    More(j, tail=Empty) if is_unconditional(j) => x
    jmps => { ..x, jmps: jmps.prepend(goto_jmp(dst, tid~)), }
  }
}

///|
/// Sequences two graphs (upstream `appgraphs`): a single unlabeled block
/// is merged into the exit block of the first graph when it has no jumps,
/// otherwise the exit of the first graph falls through to the entry of the
/// second.
fn appgraphs(fst : Cfg, snd : Cfg) -> Cfg {
  if fst.is_empty() {
    return snd
  }
  if snd.is_empty() {
    return fst
  }
  match (fst.blks, snd.blks) {
    (More(x, tail=xs), More(y, tail=Empty)) if x.jmps.is_empty() && !y.keep =>
      {
        entry: fst.entry,
        blks: xs.prepend({ ..x, defs: y.defs.concat(x.defs), jmps: y.jmps, }),
      }
    (More(x, tail=xs), More(y, tail=ys)) => {
      let tid = fresh()
      let esnd = snd.entry.unwrap_or(y.name)
      {
        entry: fst.entry,
        blks: rev_append(xs, ys).prepend(fall(tid, x, esnd)).prepend(y),
      }
    }
    _ => abort("IR invariant violation: a non-empty graph without blocks")
  }
}

///|
/// Relabels the entry of the graph with `label` (upstream `relink`): the
/// entry block is renamed, unless its label must be kept, in which case a
/// new block labeled `label` jumping to it is added.
fn relink(label : @types.Tid, weak : Bool, cfg : Cfg) -> Cfg {
  match cfg.entry {
    None =>
      {
        entry: Some(label),
        blks: list([{ ..new_blk(label, keep=true, weak~), }]),
      }
    Some(entry) => {
      let mut relink_to : @types.Tid? = None
      let mut relinked = false
      let blks = cfg.blks.map(b => {
        if b.name == entry {
          if b.keep {
            relink_to = Some(b.name)
            b
          } else {
            relinked = true
            { ..b, name: label, keep: true, weak, }
          }
        } else {
          b
        }
      })
      let blks = match relink_to {
        Some(dst) if !relinked => {
          let tid = fresh()
          blks.concat(
            list([new_blk(label, weak~).push_jmp(goto_jmp(dst, tid~))]),
          )
        }
        _ => blks
      }
      { entry: Some(label), blks, }
    }
  }
}

///|
/// The IR denotation of the effects (upstream `Bil_ir.IR`, the `bap:bir`
/// theory). `is_subroutine` tells whether a goto destination is a
/// subroutine (gotos to named labels always are, as the BIL parser marks
/// them), in which case the goto is a call; `is_subinstruction` tells
/// whether a block label is the label of a sub-instruction (such blocks
/// are weak and may be merged).
pub fn ir_algebra(
  is_subroutine? : (Dst) -> Bool = _ => false,
  is_subinstruction? : (@types.Tid) -> Bool = _ => false,
) -> EffAlgebra[Cfg] {
  {
    empty: Cfg::empty(),
    set: (v, x) => {
      let entry = fresh()
      let tid = fresh()
      {
        entry: Some(entry),
        blks: list([
          {
            ..new_blk(entry, weak=true),
            defs: list([@types.Def::create(v, x, tid~)]),
          },
        ]),
      }
    },
    repeat: (cnd, body) => {
      let keep = true
      match body.blks {
        Empty => {
          let head = fresh()
          let tid = fresh()
          {
            entry: Some(head),
            blks: list([
              new_blk(head, keep~).push_jmp(goto_jmp(head, tid~, cond=cnd)),
            ]),
          }
        }
        More(b, tail=blks) => {
          let loop_ = body.entry.unwrap_or(b.name)
          let head = fresh()
          let tail = fresh()
          let jmp1 = fresh()
          let jmp2 = fresh()
          let jmp3 = fresh()
          {
            entry: Some(head),
            blks: blks
            .prepend(b.push_jmp(goto_jmp(tail, tid=jmp3)))
            .prepend(new_blk(head, keep~).push_jmp(goto_jmp(tail, tid=jmp2)))
            .prepend(
              new_blk(tail, keep~).push_jmp(goto_jmp(loop_, tid=jmp1, cond=cnd)),
            ),
          }
        }
      }
    },
    branch: (cnd, yes, nay) => {
      let keep = true
      let head = fresh()
      let tail = fresh()
      let jump = (dst, tid) => goto_jmp(dst, tid~, cond=cnd)
      match (yes.blks, nay.blks) {
        (More(blk, tail=Empty), Empty) if blk.defs.is_empty() &&
          blk.jmps is More(j, tail=Empty) =>
          {
            entry: yes.entry,
            blks: list([{ ..blk, jmps: list([j.with_guard(Some(cnd))]), }]),
          }
        (More(b, tail=blks), Empty) => {
          let lhs = yes.entry.unwrap_or(b.name)
          let jmp1 = fresh()
          let jmp2 = fresh()
          let jmp3 = fresh()
          {
            entry: Some(head),
            blks: blks
            .prepend(b.push_jmp(goto_jmp(tail, tid=jmp3)))
            .prepend(
              new_blk(head, keep~)
              .push_jmp(jump(lhs, jmp1))
              .push_jmp(goto_jmp(tail, tid=jmp2)),
            )
            .prepend(new_blk(tail, keep~)),
          }
        }
        (Empty, More(b, tail=blks)) => {
          let rhs = nay.entry.unwrap_or(b.name)
          let jmp1 = fresh()
          let jmp2 = fresh()
          let jmp3 = fresh()
          {
            entry: Some(head),
            blks: blks
            .prepend(b.push_jmp(goto_jmp(tail, tid=jmp3)))
            .prepend(
              new_blk(head, keep~)
              .push_jmp(jump(tail, jmp1))
              .push_jmp(goto_jmp(rhs, tid=jmp2)),
            )
            .prepend(new_blk(tail, keep~)),
          }
        }
        (More(y, tail=ayes), More(n, tail=nays)) => {
          let lhs = yes.entry.unwrap_or(y.name)
          let rhs = nay.entry.unwrap_or(n.name)
          let jmp1 = fresh()
          let jmp2 = fresh()
          let jmp3 = fresh()
          let jmp4 = fresh()
          {
            entry: Some(head),
            blks: rev_append(ayes, nays)
            .prepend(n.push_jmp(goto_jmp(tail, tid=jmp4)))
            .prepend(y.push_jmp(goto_jmp(tail, tid=jmp3)))
            .prepend(
              new_blk(head, keep~)
              .push_jmp(jump(lhs, jmp1))
              .push_jmp(goto_jmp(rhs, tid=jmp2)),
            )
            .prepend(new_blk(tail, keep~)),
          }
        }
        (Empty, Empty) => {
          let jmp1 = fresh()
          let jmp2 = fresh()
          {
            entry: Some(head),
            blks: list([
              new_blk(tail, keep~),
              new_blk(head, keep~)
              .push_jmp(jump(tail, jmp1))
              .push_jmp(goto_jmp(tail, tid=jmp2)),
            ]),
          }
        }
      }
    },
    jmp: dst => {
      let entry = fresh()
      let tid = fresh()
      {
        entry: Some(entry),
        blks: list([
          new_blk(entry).push_jmp(@types.Jmp::create_goto(Indirect(dst), tid~)),
        ]),
      }
    },
    goto: (dst, call) => {
      let entry = fresh()
      let tid = fresh()
      let is_call = call || is_subroutine(dst)
      {
        entry: Some(entry),
        blks: list([
          new_blk(entry).push_jmp(goto_jmp(dst.tid(), tid~, is_call~)),
        ]),
      }
    },
    seq: appgraphs,
    blk: (label, defs, jmps) => {
      let res = appgraphs(defs, jmps)
      match label {
        None => res
        Some(l) => relink(l, is_subinstruction(l), res)
      }
    },
  }
}

// Reification (upstream `BIR`).

///|
fn jmp_dst(j : @types.Term[@types.Jmp]) -> @types.Tid? {
  match j.dst() {
    Some(d) =>
      match @types.Jmp::resolve(d) {
        ResolvedTarget(tid) => Some(tid)
        IndirectTarget(_) => None
      }
    None => None
  }
}

///|
fn single_dst(jmps : @list.List[@types.Term[@types.Jmp]]) -> @types.Tid? {
  match jmps {
    More(x, tail=Empty) =>
      match jmp_dst(x) {
        Some(tid) if !is_call(x) && is_unconditional(x) => Some(tid)
        _ => None
      }
    _ => None
  }
}

///|
fn can_contract(refs : Map[@types.Tid, Int], b1 : IrBlk, b2 : IrBlk) -> Bool {
  b1.name != b2.name &&
  (!b2.keep || b2.weak) &&
  (match single_dst(b1.jmps) {
    Some(dst) => dst == b2.name && refs.get(dst) == Some(1)
    None => false
  })
}

///|
fn join(x : IrBlk, y : IrBlk) -> IrBlk {
  { ..x, defs: y.defs.concat(x.defs), jmps: y.jmps, }
}

///|
priv suberror NormalizeError

///|
fn contract(
  refs : Map[@types.Tid, Int],
  graph : Map[@types.Tid, IrBlk],
  output : Array[IrBlk],
  exit : @types.Tid,
  node : IrBlk,
) -> @types.Tid {
  match single_dst(node.jmps) {
    Some(d) =>
      match graph.get(d) {
        Some(dst) if can_contract(refs, node, dst) => {
          let node = join(node, dst)
          graph.remove(dst.name)
          let exit = if exit == dst.name { node.name } else { exit }
          return contract(refs, graph, output, exit, node)
        }
        _ => ()
      }
    None => ()
  }
  // follow
  output.push(node)
  graph.remove(node.name)
  let mut exit = exit
  for j in node.jmps {
    match jmp_dst(j) {
      Some(name) =>
        match graph.get(name) {
          Some(n) => exit = contract(refs, graph, output, exit, n)
          None => ()
        }
      None => ()
    }
  }
  exit
}

///|
/// Contracts the chains of blocks connected with single unconditional
/// jumps (upstream `normalize`); the exit block stays first.
fn normalize_blks(
  entry : @types.Tid,
  blks : @list.List[IrBlk],
) -> @list.List[IrBlk] raise NormalizeError {
  let exit = match blks.head() {
    Some(b) => b.name
    None => raise NormalizeError
  }
  let graph : Map[@types.Tid, IrBlk] = Map([])
  for b in blks {
    if graph.contains(b.name) {
      raise NormalizeError
    }
    graph[b.name] = b
  }
  let refs : Map[@types.Tid, Int] = Map([])
  for b in blks {
    for j in b.jmps {
      match jmp_dst(j) {
        Some(tid) if graph.contains(tid) =>
          refs[tid] = refs.get(tid).unwrap_or(0) + 1
        _ => ()
      }
    }
  }
  let start = match graph.get(entry) {
    Some(b) => b
    None => raise NormalizeError
  }
  let output = []
  let exit = contract(refs, graph, output, exit, start)
  if !graph.is_empty() {
    raise NormalizeError
  }
  let out = list(output.rev())
  match out {
    More(b, ..) if b.name == exit => out
    _ =>
      match out.find(b => b.name == exit) {
        Some(e) => out.filter(b => b.name != exit).prepend(e)
        None => raise NormalizeError
      }
  }
}

///|
fn IrBlk::to_blk(self : IrBlk) -> @types.Term[@types.Blk] {
  @types.Blk::create(
    tid=self.name,
    defs=self.defs.rev().to_array(),
    jmps=self.jmps.rev().to_array(),
  )
}

///|
/// The IR blocks of the graph (upstream `Bil_ir.reify`): the chains of
/// blocks are contracted, the entry block is first.
pub fn Cfg::reify(self : Cfg) -> Array[@types.Term[@types.Blk]] {
  let entry = match self.entry {
    None => return []
    Some(e) => e
  }
  let blks = match self.blks {
    Empty | More(_, tail=Empty) => self.blks
    blks =>
      normalize_blks(entry, blks) catch {
        _ => {
          log.warning(
            message="can't normalize invalid IR: \{entry.to_string()}",
          )
          blks
        }
      }
  }
  let mut first : @types.Term[@types.Blk]? = None
  let mut rest : @list.List[@types.Term[@types.Blk]] = @list.empty()
  for b in blks {
    let blk = b.to_blk()
    if blk.tid() == entry {
      first = Some(blk)
    } else {
      rest = rest.prepend(blk)
    }
  }
  match first {
    Some(x) => [x, ..rest.to_array()]
    None => {
      log.warning(message="No entry in IR builder")
      rest.to_array()
    }
  }
}

///|
/// Builds the IR of a BIL program (the IR construction of the BIL
/// lifter: the program is reflected into the IR theory and reified).
pub fn lift_bir(
  bil : ArrayView[@types.Stmt],
  is_subroutine? : (Dst) -> Bool = _ => false,
) -> Array[@types.Term[@types.Blk]] raise ReflectError {
  reflect(ir_algebra(is_subroutine~), bil).reify()
}
