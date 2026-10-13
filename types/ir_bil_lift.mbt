// Lowering of BIL statements into the graphical IR (BIR).
//
// This is a port of the path that upstream BAP takes from the BIL code of an
// instruction to its IR: the BIL statements are parsed into Core Theory terms
// (`Bap_core_theory_parser.stmts`) which are denotated by the `bap:bir`
// theory (`plugins/bil/bil_ir.ml`), whose graph is then reified into a list
// of IR blocks (`Bil_ir.BIR.reify`). Since the BIR theory is the only
// interpretation involved, the port evaluates the BIL statements directly
// with the same combinators (`seq`, `branch`, `repeat`, `goto`, `jmp`,
// `fall`), preserving the upstream shape of the produced blocks: structured
// conditionals and loops become several blocks, and blocks are then
// contracted and ordered exactly as `BIR.normalize` and `BIR.reify` do.

///|
/// A block of the BIR graph (upstream `Bil_ir.blk`). Definitions and jumps
/// are kept in program order (upstream keeps them reversed).
priv struct BirBlk {
  name : Tid
  keep : Bool
  weak : Bool
  defs : Array[Term[Def]]
  jmps : Array[Term[Jmp]]
}

///|
/// A BIR graph (upstream `Bil_ir.cfg`): `blks[0]` is the exit block and
/// `entry` is `None` for the empty denotation.
priv struct BirCfg {
  entry : Tid?
  blks : Array[BirBlk]
}

///|
/// The parameters of the lowering that upstream takes from the knowledge
/// base: the package of the created labels, the width of code addresses (the
/// labels of addresses are width-independent upstream, as
/// `Theory.Label.for_addr` takes an unsized bitvector) and the
/// `Theory.Label.is_subroutine` property of labels.
priv struct BirContext {
  pkg : String?
  addr_width : Int32?
  is_subroutine : (Tid) -> Bool
}

///|
fn bir_empty() -> BirCfg {
  { entry: None, blks: [], }
}

///|
fn BirCfg::is_empty(self : BirCfg) -> Bool {
  self.entry is None && self.blks.is_empty()
}

///|
fn bir_blk(name : Tid, keep~ : Bool = false, weak~ : Bool = false) -> BirBlk {
  { name, keep, weak, defs: [], jmps: [], }
}

///|
fn[T] bir_snoc(xs : Array[T], x : T) -> Array[T] {
  let result = xs.copy()
  result.push(x)
  result
}

///|
/// `List.rev_append xs ys`.
fn[T] bir_rev_append(xs : ArrayView[T], ys : ArrayView[T]) -> Array[T] {
  let result : Array[T] = []
  for i = xs.length() - 1; i >= 0; i = i - 1 {
    result.push(xs[i])
  }
  for y in ys {
    result.push(y)
  }
  result
}

///|
/// Whether the jump is taken unconditionally (upstream `Bil_ir.is_unconditional`,
/// the guard is the literal `1:1`).
fn bir_is_unconditional(jmp : Term[Jmp]) -> Bool {
  jmp.jmp_guard() is None
}

///|
/// `blk ++ jmp`: a jump pushed after an unguarded jump is unreachable and
/// is dropped (upstream `IR.jmp` field setter).
fn BirBlk::push_jmp(self : BirBlk, jmp : Term[Jmp]) -> BirBlk {
  match self.jmps.last() {
    Some(last) if last.jmp_guard() is None => self
    _ => { ..self, jmps: bir_snoc(self.jmps, jmp), }
  }
}

///|
/// Upstream `IR.goto`: a jump to `dst`, which is a call (the destination is
/// the alternate route) when `dst` is a subroutine.
fn bir_goto_jmp(dst : Tid, is_call~ : Bool = false, cond? : Exp) -> Term[Jmp] {
  if is_call {
    Jmp::create_call(Call::create(target=Label::direct(dst)), cond?)
  } else {
    Jmp::create_goto(Label::direct(dst), cond?)
  }
}

///|
/// Upstream `IR.do_goto`.
fn bir_goto(dst : Tid, is_call~ : Bool) -> BirCfg {
  let entry = Tid::fresh()
  {
    entry: Some(entry),
    blks: [bir_blk(entry).push_jmp(bir_goto_jmp(dst, is_call~))],
  }
}

///|
/// Upstream `IR.jmp`: an indirect jump (or, for a call hint of the Basic
/// lifter, an indirect call).
fn bir_jmp(dst : Exp, is_call~ : Bool) -> BirCfg {
  let entry = Tid::fresh()
  let jmp = if is_call {
    Jmp::create_call(Call::create(target=Label::indirect(dst)))
  } else {
    Jmp::create_goto(Label::indirect(dst))
  }
  { entry: Some(entry), blks: [bir_blk(entry).push_jmp(jmp)], }
}

///|
/// Upstream `IR.set`.
fn bir_set(lhs : Var, rhs : Exp) -> BirCfg {
  let entry = Tid::fresh()
  {
    entry: Some(entry),
    blks: [{ ..bir_blk(entry, weak=true), defs: [Def::create(lhs, rhs)], }],
  }
}

///|
/// Upstream `IR.repeat`: reifies `while (cnd) body` into
///
/// ```text
/// head:
///   goto tail
/// loop:
///   <body>
///   goto tail
/// tail:
///   when <cnd> goto loop
/// ```
///
/// or, for an empty body, to `head: when <cnd> goto head`.
fn bir_repeat(cnd : Exp, body : BirCfg) -> BirCfg {
  match (body.entry, body.blks) {
    (Some(loop_), [b, .. blks]) => {
      let head = Tid::fresh()
      let tail = Tid::fresh()
      let result : Array[BirBlk] = [
        bir_blk(tail, keep=true).push_jmp(bir_goto_jmp(loop_, cond=cnd)),
        bir_blk(head, keep=true).push_jmp(bir_goto_jmp(tail)),
        b.push_jmp(bir_goto_jmp(tail)),
      ]
      result.push_iter(blks.iter())
      { entry: Some(head), blks: result, }
    }
    _ => {
      let head = Tid::fresh()
      {
        entry: Some(head),
        blks: [bir_blk(head, keep=true).push_jmp(bir_goto_jmp(head, cond=cnd))],
      }
    }
  }
}

///|
/// The guard `cnd` of a jump moved under a branch on `cnd`. Upstream
/// replaces the guard of the jump; the port conjoins it with an existing
/// guard, so that a jump nested in two conditionals keeps both conditions.
fn bir_guard(jmp : Term[Jmp], cnd : Exp) -> Term[Jmp] {
  match jmp.jmp_guard() {
    None => jmp.with_guard(Some(cnd))
    Some(inner) => jmp.with_guard(Some(BinOp(And, cnd, inner)))
  }
}

///|
/// Upstream `IR.branch`.
fn bir_branch(cnd : Exp, yes : BirCfg, nay : BirCfg) -> BirCfg {
  let jump = (dst : Tid) => bir_goto_jmp(dst, cond=cnd)
  let goto = (dst : Tid) => bir_goto_jmp(dst)
  match (yes, nay) {
    ({ entry, blks: [blk], }, { blks: [], .. }) if blk.defs.is_empty() &&
      blk.jmps.length() == 1 =>
      {
        entry,
        blks: [{ ..blk, defs: [], jmps: [bir_guard(blk.jmps[0], cnd)], }],
      }
    ({ entry: Some(lhs), blks: [b, .. blks], }, { blks: [], .. }) => {
      let head = Tid::fresh()
      let tail = Tid::fresh()
      let result = [
        bir_blk(tail, keep=true),
        bir_blk(head, keep=true).push_jmp(jump(lhs)).push_jmp(goto(tail)),
        b.push_jmp(goto(tail)),
      ]
      result.push_iter(blks.iter())
      { entry: Some(head), blks: result, }
    }
    ({ blks: [], .. }, { entry: Some(rhs), blks: [b, .. blks], }) => {
      let head = Tid::fresh()
      let tail = Tid::fresh()
      let result = [
        bir_blk(tail, keep=true),
        bir_blk(head, keep=true).push_jmp(jump(tail)).push_jmp(goto(rhs)),
        b.push_jmp(goto(tail)),
      ]
      result.push_iter(blks.iter())
      { entry: Some(head), blks: result, }
    }
    (
      { entry: Some(lhs), blks: [y, .. ayes], },
      { entry: Some(rhs), blks: [n, .. nays], },
    ) => {
      let head = Tid::fresh()
      let tail = Tid::fresh()
      let result = [
        bir_blk(tail, keep=true),
        bir_blk(head, keep=true).push_jmp(jump(lhs)).push_jmp(goto(rhs)),
        y.push_jmp(goto(tail)),
        n.push_jmp(goto(tail)),
      ]
      result.push_iter(bir_rev_append(ayes, nays).iter())
      { entry: Some(head), blks: result, }
    }
    _ => {
      let head = Tid::fresh()
      let tail = Tid::fresh()
      {
        entry: Some(head),
        blks: [
          bir_blk(tail, keep=true),
          bir_blk(head, keep=true).push_jmp(jump(tail)).push_jmp(goto(tail)),
        ],
      }
    }
  }
}

///|
/// Upstream `IR.fall`: makes the exit block `x` fall to `dst`. A call gets
/// `dst` as its return; other blocks get a jump to `dst` unless they end
/// with an unconditional jump.
fn bir_fall(x : BirBlk, dst : Tid) -> BirBlk {
  match x.jmps {
    [jmp] if jmp.alt() is Some(_) => {
      let returning = jmp.with_dst(Some(Jmp::resolved(dst)))
      if bir_is_unconditional(jmp) {
        { ..x, jmps: [returning], }
      } else {
        { ..x, jmps: [returning, Jmp::create_goto(Label::direct(dst))], }
      }
    }
    [jmp] if bir_is_unconditional(jmp) => x
    jmps => { ..x, jmps: bir_snoc(jmps, bir_goto_jmp(dst)), }
  }
}

///|
/// Upstream `IR.appgraphs`, the sequential composition of two graphs.
fn bir_seq(fst : BirCfg, snd : BirCfg) -> BirCfg {
  if fst.is_empty() {
    return snd
  }
  if snd.is_empty() {
    return fst
  }
  match (fst.blks, snd.blks, snd.entry) {
    ([x, .. xs], [y], _) if x.jmps.is_empty() && !y.keep => {
      let merged = { ..x, defs: x.defs + y.defs, jmps: y.jmps, }
      let result = [merged]
      result.push_iter(xs.iter())
      { entry: fst.entry, blks: result, }
    }
    ([x, .. xs], [y, .. ys], Some(esnd)) => {
      let result = [y, bir_fall(x, esnd)]
      result.push_iter(bir_rev_append(xs, ys).iter())
      { entry: fst.entry, blks: result, }
    }
    _ => fst
  }
}

///|
/// The address label of `word` (upstream `Theory.Label.for_addr`),
/// normalized to the width of code addresses.
fn BirContext::label_for_addr(self : BirContext, word : Word) -> Tid {
  let word = match self.addr_width {
    Some(width) if width > 0 && width != word.width() =>
      word.extract(hi=width - 1, lo=0) catch {
        _ => word
      }
    _ => word
  }
  Tid::for_addr(word, pkg?=self.pkg)
}

///|
/// Upstream `S.goto`/`S.cpuexn`: a jump to `dst`, a call if `dst` is a
/// subroutine.
fn BirContext::goto(self : BirContext, dst : Tid) -> BirCfg {
  bir_goto(dst, is_call=(self.is_subroutine)(dst))
}

///|
/// Upstream `S.call`: a call of the subroutine `name`.
fn BirContext::call(self : BirContext, name : String) -> BirCfg {
  bir_goto(Tid::for_name(name, pkg?=self.pkg), is_call=true)
}

///|
/// The destination of a `Jmp` statement: a direct jump for a constant
/// (upstream `S.goto`), an indirect one otherwise (upstream `S.jmp`). The
/// destination is constant-folded first, as upstream simplifies the BIL
/// (the `Bil_semantics` optimizer) before denotating it, so that
/// pc-relative targets such as `addr + off` become direct.
fn BirContext::jump(self : BirContext, dst : Exp, is_call~ : Bool) -> BirCfg {
  match dst.fold_consts() {
    Int(word) => {
      let label = self.label_for_addr(word)
      bir_goto(label, is_call=is_call || (self.is_subroutine)(label))
    }
    folded => bir_jmp(folded, is_call~)
  }
}

///|
/// The control hint of the Basic lifter: a `call`/`goto` special statement
/// that immediately precedes the `Jmp` it classifies (`Some(true)` for a
/// call). Upstream lifters express calls as `Jmp`s whose destinations are
/// subroutines; the Basic lifter of the port marks them instead.
fn bir_control_hint(stmt : Stmt) -> Bool? {
  if Stmt::decode(Stmt::call(), stmt) is Some(_) {
    Some(true)
  } else if Stmt::decode(Stmt::goto(), stmt) is Some(_) {
    Some(false)
  } else {
    None
  }
}

///|
/// The denotation of one statement (upstream `Theory.Parser.stmts`
/// instantiated with the BIR theory).
fn BirContext::stmt(self : BirContext, stmt : Stmt) -> BirCfg {
  match stmt {
    Move(lhs, rhs) => bir_set(lhs, rhs)
    Jmp(dst) => self.jump(dst, is_call=false)
    CpuExn(ivec) => self.goto(Tid::for_ivec(ivec))
    While(cond~, body~) => bir_repeat(cond, self.stmts(body))
    If(cond~, yes~, no~) => bir_branch(cond, self.stmts(yes), self.stmts(no))
    Special(_) =>
      match Stmt::decode(Stmt::call(), stmt) {
        Some(name) => self.call(name)
        None =>
          match Stmt::decode(Stmt::intrinsic(), stmt) {
            Some(data) =>
              self.call(
                if data.has_prefix("intrinsic:") {
                  data
                } else {
                  "intrinsic:" + data
                },
              )
            None => bir_empty()
          }
      }
  }
}

///|
/// The denotation of a sequence of statements.
fn BirContext::stmts(self : BirContext, stmts : Array[Stmt]) -> BirCfg {
  // split into units, pairing the Basic control hints with their jumps
  let units : Array[BirCfg] = []
  let mut i = 0
  while i < stmts.length() {
    match (stmts[i], stmts.get(i + 1)) {
      (Special(_) as hint, Some(Jmp(dst))) if bir_control_hint(hint)
        is Some(is_call) => {
        units.push(self.jump(dst, is_call~))
        i += 2
      }
      (stmt, _) => {
        units.push(self.stmt(stmt))
        i += 1
      }
    }
  }
  let mut result = bir_empty()
  for j = units.length() - 1; j >= 0; j = j - 1 {
    result = bir_seq(units[j], result)
  }
  result
}

///|
/// Upstream `BIR.single_dst`: the destination of the only jump of a block,
/// when it is an unconditional goto to a resolved label.
fn bir_single_dst(jmps : Array[Term[Jmp]]) -> Tid? {
  match jmps {
    [jmp] if jmp.alt() is None && bir_is_unconditional(jmp) =>
      match jmp.dst() {
        Some(ResolvedDst(tid)) => Some(tid)
        _ => None
      }
    _ => None
  }
}

///|
/// Upstream `BIR.dsts`, in the order of the upstream (reversed) jump list.
fn bir_dsts(blk : BirBlk) -> Array[Tid] {
  let result : Array[Tid] = []
  for i = blk.jmps.length() - 1; i >= 0; i = i - 1 {
    if blk.jmps[i].dst() is Some(ResolvedDst(tid)) {
      result.push(tid)
    }
  }
  result
}

///|
/// Upstream `BIR.normalize`: contracts chains of blocks linked by single
/// unconditional jumps (unless the target is a kept block referenced more
/// than once) and puts the exit block first. Graphs that are not
/// well-formed (duplicate names, unreachable blocks) are left as they are.
fn bir_normalize(entry : Tid, blks : Array[BirBlk]) -> Array[BirBlk] {
  if blks.length() <= 1 {
    return blks
  }
  let exit0 = blks[0].name
  let graph : Map[Tid, BirBlk] = Map([])
  for blk in blks {
    if graph.contains(blk.name) {
      return blks
    }
    graph[blk.name] = blk
  }
  let refs : Map[Tid, Int32] = Map([])
  for blk in blks {
    for jmp in blk.jmps {
      if jmp.dst() is Some(ResolvedDst(tid)) && graph.contains(tid) {
        refs[tid] = refs.get(tid).unwrap_or(0) + 1
      }
    }
  }
  guard graph.get(entry) is Some(start) else { return blks }
  let can_contract = (b1 : BirBlk, b2 : BirBlk) => {
    b1.name != b2.name &&
    (!b2.keep || b2.weak) &&
    bir_single_dst(b1.jmps) is Some(dst) &&
    dst == b2.name &&
    refs.get(dst) is Some(1)
  }
  // upstream threads `output`, `graph` and `exit` through the traversal
  let output : Array[BirBlk] = []
  let mut exit = exit0
  letrec contract = (node : BirBlk) => {
    match bir_single_dst(node.jmps).bind(dst => graph.get(dst)) {
      Some(dst) if can_contract(node, dst) => {
        let joined = { ..node, defs: node.defs + dst.defs, jmps: dst.jmps, }
        graph.remove(dst.name)
        if exit == dst.name {
          exit = joined.name
        }
        contract(joined)
      }
      _ => follow(node)
    }
  }
  and follow = (node : BirBlk) => {
    output.push(node)
    graph.remove(node.name)
    for name in bir_dsts(node) {
      match graph.get(name) {
        Some(next) => contract(next)
        None => ()
      }
    }
  }

  contract(start)
  if !graph.is_empty() {
    return blks
  }
  // upstream accumulates the output by prepending
  let ordered = output.rev()
  if ordered[0].name == exit {
    return ordered
  }
  guard ordered.search_by(blk => blk.name == exit) is Some(index) else {
    return blks
  }
  let result = [ordered[index]]
  for blk in ordered {
    if blk.name != exit {
      result.push(blk)
    }
  }
  result
}

///|
/// Upstream `BIR.reify`: the blocks of a graph, the entry first and the exit
/// last.
fn bir_reify(cfg : BirCfg) -> Array[Term[Blk]] {
  guard cfg.entry is Some(entry) else { return [] }
  let mut first : Term[Blk]? = None
  let rest : Array[Term[Blk]] = []
  for blk in bir_normalize(entry, cfg.blks) {
    let term = Blk::create(tid=blk.name, defs=blk.defs, jmps=blk.jmps)
    if blk.name == entry {
      first = Some(term)
    } else {
      rest.push(term)
    }
  }
  rest.rev_in_place()
  match first {
    Some(term) => [term] + rest
    None => rest
  }
}

///|
fn bir_context(
  pkg : String?,
  addr_width : Int32?,
  is_subroutine : ((Tid) -> Bool)?,
) -> BirContext {
  {
    pkg,
    addr_width,
    is_subroutine: match is_subroutine {
      Some(f) => f
      None => _ => false
    },
  }
}

///|
/// The IR of the BIL semantics `bil` of an instruction (upstream the
/// `Term.slot` of the instruction semantics, computed by the `bap:bir`
/// theory): a list of blocks with the entry first and the exit last, empty
/// for semantics without effects.
///
/// Assignments become definitions; `If` statements become branches (a
/// conditional jump when a branch is a single jump, a head/arms/tail
/// diamond otherwise); `While` loops become a head, the body and a tail with
/// the conditional back edge; `Jmp`s to constants become gotos to the labels
/// of their addresses, other `Jmp`s indirect gotos; jumps to subroutines
/// (`is_subroutine`) and `call` specials become calls; `CpuExn n` becomes a
/// jump to the interrupt label `n`; other specials are ignored. The `call`
/// and `goto` specials the Basic lifter places before a `Jmp` classify that
/// jump. Address labels are created in `pkg` with the width `addr_width`.
pub fn Blk::of_bil(
  bil : Array[Stmt],
  pkg? : String,
  addr_width? : Int32,
  is_subroutine? : (Tid) -> Bool,
) -> Array[Term[Blk]] {
  bir_reify(bir_context(pkg, addr_width, is_subroutine).stmts(bil))
}
