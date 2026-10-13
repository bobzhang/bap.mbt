// Lifting instructions and basic blocks into IR (upstream
// `lib/bap_sema/bap_sema_lift.ml`, the `IrBuilder` module and the
// program-level relinking of calls).
//
// Upstream works on lists of blocks whose first element is the exit block
// (the reverse of the program order); the port keeps the same convention for
// its intermediate arrays, `blks[0]` being the current exit block.

///|
/// An instruction prepared for lifting into IR (the parts of an upstream
/// `insn` value that `Bap_sema_lift` uses): its BIL semantics, the
/// `address` and `insn` attributes of the terms lifted from it, and whether
/// it is a call or a barrier (`Insn.is call`, `Insn.is barrier`).
pub(all) struct IrInsn {
  bil : Array[Stmt]
  addr : Word?
  insn : String?
  is_call : Bool
  is_barrier : Bool
} derive(Debug)

///|
pub extend IrInsn with Debug::{to_repr}

///|
pub fn IrInsn::new(
  bil : Array[Stmt],
  addr? : Word,
  insn? : String,
  is_call~ : Bool = false,
  is_barrier~ : Bool = false,
) -> IrInsn {
  { bil, addr, insn, is_call, is_barrier, }
}

///|
/// The fallthrough of a basic block (upstream
/// ``[`Intra of dst | `Inter of dst]``): to a block of the same subroutine,
/// or into another subroutine (an implicit call).
pub(all) enum IrFall {
  IntraFall(JmpDst)
  InterFall(JmpDst)
} derive(Eq, Debug)

///|
pub extend IrFall with Eq::{equal, not_equal}

///|
pub extend IrFall with Debug::{to_repr}

///|
/// The key of the attribute holding the instruction a term was lifted from
/// (upstream `Disasm.insn`).
pub let ir_insn_attr : String = "insn"

///|
/// The instruction a term was lifted from (upstream `Disasm.insn`), in the
/// upstream `Insn.pp` form `name(op1,op2)`.
pub fn Attr::insn(insn : String) -> Attr {
  Attr::new(key=ir_insn_attr, value=insn)
}

///|
/// Upstream `update_jmp`: rebuilds `jmp` from its destinations, keeping its
/// tid, guard and attributes.
fn ir_update_jmp(
  jmp : Term[Jmp],
  f : (JmpDst?, JmpDst?) -> (JmpDst?, JmpDst?),
) -> Term[Jmp] {
  let (dst, alt) = f(jmp.dst(), jmp.alt())
  jmp.with_kind(jmp_kind_of_dst_alt(dst, alt))
}

///|
/// Upstream `IrBuilder.is_unconditional`: the guard is a constant.
fn ir_is_unconditional(jmp : Term[Jmp]) -> Bool {
  jmp.cond() is Int(_)
}

///|
fn ir_def_only(blk : Term[Blk]) -> Bool {
  blk.jmps().is_empty()
}

///|
/// Upstream `IrBuilder.append`: appends the blocks `ys` (entry first, exit
/// last) after the exit block `xs[0]` of `xs` (exit first). A def-only exit
/// block absorbs the entry of `ys`; otherwise it gets a jump to it.
fn ir_append(xs : Array[Term[Blk]], ys : Array[Term[Blk]]) -> Array[Term[Blk]] {
  match (xs, ys) {
    ([], ys) => ys
    (xs, []) => xs
    ([x, .. xs], [y, .. rest]) if ir_def_only(x) => {
      let merged = Blk::create(
        tid=x.tid(),
        defs=x.defs() + y.defs(),
        jmps=y.jmps(),
      )
      let result = bir_rev_append(rest, [merged])
      result.push_iter(xs.iter())
      result
    }
    ([x, .. xs], [y, ..]) => {
      let x = x.append_jmp(Jmp::create_goto(Label::direct(y.tid())))
      let result = bir_rev_append(ys, [x])
      result.push_iter(xs.iter())
      result
    }
  }
}

///|
fn[T] ir_mark(addr : Word?, insn : String?, term : Term[T]) -> Term[T] {
  let term = match insn {
    Some(insn) => term.set_attr(Attr::insn(insn))
    None => term
  }
  match addr {
    Some(addr) => term.set_attr(Attr::address(addr))
    None => term
  }
}

///|
/// Upstream `IrBuilder.set_attributes`.
fn ir_set_attributes(
  addr : Word?,
  insn : String?,
  blks : Array[Term[Blk]],
) -> Array[Term[Blk]] {
  blks.map(blk => {
    blk
    .map_jmps(jmp => ir_mark(addr, insn, jmp))
    .map_defs(def => ir_mark(addr, insn, def))
  })
}

///|
/// Upstream `IrBuilder.lift_insn`: appends the IR of `insn` to the blocks
/// `blks` (exit first).
fn BirContext::lift_insn(
  self : BirContext,
  insn : IrInsn,
  blks : Array[Term[Blk]],
) -> Array[Term[Blk]] {
  let ir = bir_reify(self.stmts(insn.bil))
  ir_append(blks, ir_set_attributes(insn.addr, insn.insn, ir))
}

///|
/// Upstream `IrBuilder.turn_into_call`: the jumps of `blk` become calls,
/// returning to `ret` when unconditional.
fn ir_turn_into_call(ret : JmpDst?, blk : Term[Blk]) -> Term[Blk] {
  blk.map_jmps(jmp => {
    ir_update_jmp(jmp, (dst, alt) => {
      let dst2 = if ir_is_unconditional(jmp) { ret } else { None }
      let alt2 = match alt {
        Some(_) => alt
        None => dst
      }
      (dst2, alt2)
    })
  })
}

///|
/// Upstream `IrBuilder.landing_pad`: an interrupt returns to a new block
/// named after its return label, which continues to the fallthrough.
fn ir_landing_pad(fall : IrFall?, jmp : Term[Jmp]) -> Term[Blk]? {
  match jmp.kind() {
    Interrupt(_, pad) => {
      let blk = Blk::create(tid=pad)
      match fall {
        Some(IntraFall(dst)) =>
          Some(
            blk.append_jmp(Jmp::create(jmp_kind_of_dst_alt(Some(dst), None))),
          )
        _ => Some(blk)
      }
    }
    _ => None
  }
}

///|
/// Upstream `IrBuilder.with_landing_pads`.
fn ir_with_landing_pads(
  fall : IrFall?,
  blks : Array[Term[Blk]],
) -> Array[Term[Blk]] {
  match blks {
    [] => []
    [b, .. bs] => {
      let pads : Array[Term[Blk]] = []
      for blk in blks {
        for jmp in blk.jmps() {
          if ir_landing_pad(fall, jmp) is Some(pad) {
            pads.push(pad)
          }
        }
      }
      let result = [b]
      result.push_iter(pads.iter())
      result.push_iter(bs.iter())
      result
    }
  }
}

///|
/// Upstream `IrBuilder.is_last_jump_unconditional`.
fn ir_is_last_jump_unconditional(blk : Term[Blk]) -> Bool {
  match blk.jmps().last() {
    Some(jmp) => ir_is_unconditional(jmp)
    None => false
  }
}

///|
/// Upstream `IrBuilder.has_call`.
fn ir_has_call(blk : Term[Blk]) -> Bool {
  blk.jmps().any(jmp => jmp.alt() is Some(_))
}

///|
/// Upstream `IrBuilder.fall_if_possible`.
fn ir_fall_if_possible(dst : JmpDst, blk : Term[Blk]) -> Term[Blk] {
  if ir_is_last_jump_unconditional(blk) {
    blk
  } else {
    blk.append_jmp(Jmp::create(jmp_kind_of_dst_alt(Some(dst), None)))
  }
}

///|
/// Upstream `IrBuilder.insert_inter_fall`: a call of `alt` (a fallthrough
/// into another subroutine).
fn ir_insert_inter_fall(alt : JmpDst, blk : Term[Blk]) -> Term[Blk] {
  blk.append_jmp(Jmp::create(jmp_kind_of_dst_alt(None, Some(alt))))
}

///|
/// Upstream `IrBuilder.maximize`: the blocks replacing the exit block `x`
/// (exit first).
fn ir_maximize(
  is_call : Bool,
  is_barrier : Bool,
  fall : IrFall?,
  x : Term[Blk],
) -> Array[Term[Blk]] {
  if is_barrier {
    return [x]
  }
  let calls = is_call || ir_has_call(x)
  match fall {
    None => [if calls { ir_turn_into_call(None, x) } else { x }]
    Some(IntraFall(dst)) => {
      let blk = if calls { ir_turn_into_call(Some(dst), x) } else { x }
      [ir_fall_if_possible(dst, blk)]
    }
    Some(InterFall(dst)) =>
      if calls {
        let tid = Tid::fresh()
        let next = ir_insert_inter_fall(dst, Blk::create(tid~))
        let fall = Jmp::resolved(tid)
        [next, ir_fall_if_possible(fall, ir_turn_into_call(Some(fall), x))]
      } else {
        [ir_insert_inter_fall(dst, x)]
      }
  }
}

///|
/// Upstream `IrBuilder.pack`: finalizes the blocks lifted from the
/// instructions of a basic block (exit first) into maximal blocks in program
/// order: the exit gets the fallthrough, calls get their returns, interrupts
/// get their landing pads and the entry gets the address `addr`.
fn ir_pack(
  blks : Array[Term[Blk]],
  is_call : Bool,
  is_barrier : Bool,
  fall : IrFall?,
  addr : Word?,
) -> Array[Term[Blk]] {
  let blks = ir_with_landing_pads(fall, blks)
  let result = match blks {
    [] => []
    [x, .. xs] => {
      let replaced = ir_maximize(is_call, is_barrier, fall, x)
      replaced.push_iter(xs.iter())
      replaced.rev()
    }
  }
  match (addr, result) {
    (Some(addr), [first, ..]) => {
      result[0] = first.set_attr(Attr::address(addr))
      result
    }
    _ => result
  }
}

///|
/// The IR of one instruction (upstream `Bap_sema_lift.insn`): its blocks in
/// program order, the first named `tid` (by default the label of the
/// instruction address, or a fresh label). Its terms get the `insn` and
/// `address` attributes of `insn`. See `Blk::of_bil` for the lowering of the
/// semantics and the meaning of `pkg`, `addr_width` and `is_subroutine`.
pub fn Blk::lift_insn(
  insn : IrInsn,
  tid? : Tid,
  pkg? : String,
  addr_width? : Int32,
  is_subroutine? : (Tid) -> Bool,
) -> Array[Term[Blk]] {
  let context = bir_context(pkg, addr_width, is_subroutine)
  let tid = match (tid, insn.addr) {
    (Some(tid), _) => tid
    (None, Some(addr)) => context.label_for_addr(addr)
    (None, None) => Tid::fresh()
  }
  context.lift_insn(insn, [Blk::create(tid~)]).rev()
}

///|
/// The IR of a basic block (upstream `IrBuilder.blk`, once the fallthrough
/// and the call status of the block are resolved from the CFG and the
/// symbol table): the instructions are lifted in order into blocks starting
/// with a block named `tid`, which gets the `address` attribute `addr`. The
/// exit block falls to `fall`; its jumps become calls (returning to the
/// fallthrough) when the block ends with a call (`is_call`, by default the
/// kind of the last instruction) or already contains a call, and it gets no
/// fallthrough when the block ends with a barrier (`is_barrier`, by default
/// the kind of the last instruction). The result is in program order.
pub fn Blk::lift_block(
  tid : Tid,
  insns : Array[IrInsn],
  addr? : Word,
  fall? : IrFall,
  is_call? : Bool,
  is_barrier? : Bool,
  pkg? : String,
  addr_width? : Int32,
  is_subroutine? : (Tid) -> Bool,
) -> Array[Term[Blk]] {
  let context = bir_context(pkg, addr_width, is_subroutine)
  let mut blks = [Blk::create(tid~)]
  for insn in insns {
    blks = context.lift_insn(insn, blks)
  }
  let last = insns.last()
  let is_call = match (is_call, last) {
    (Some(value), _) => value
    (None, Some(insn)) => insn.is_call
    (None, None) => false
  }
  let is_barrier = match (is_barrier, last) {
    (Some(value), _) => value
    (None, Some(insn)) => insn.is_barrier
    (None, None) => false
  }
  ir_pack(blks, is_call, is_barrier, fall, addr)
}

///|
/// The IR of a sequence of instructions (upstream `Bap_sema_lift.insns`):
/// like `Blk::lift_block` for a block named after `addr` (or fresh) that
/// ends with the last instruction, except that the terms get only the
/// `insn` attribute. Without instructions it is a single empty block.
pub fn Blk::lift_insns(
  insns : Array[IrInsn],
  fall? : IrFall,
  addr? : Word,
  pkg? : String,
  addr_width? : Int32,
  is_subroutine? : (Tid) -> Bool,
) -> Array[Term[Blk]] {
  let context = bir_context(pkg, addr_width, is_subroutine)
  let tid = match addr {
    Some(addr) => context.label_for_addr(addr)
    None => Tid::fresh()
  }
  let mut blks = [Blk::create(tid~)]
  for insn in insns {
    blks = context.lift_insn({ ..insn, addr: None, }, blks)
  }
  match insns.last() {
    None => blks
    Some(last) => ir_pack(blks, last.is_call, last.is_barrier, fall, addr)
  }
}

///|
/// Upstream `alternate_nonlocal`: a jump whose destination is unresolved,
/// or is not a block of `sub`, may leave the subroutine and becomes a call.
/// Jumps that already have an alternate route are kept.
fn ir_alternate_nonlocal(sub : Term[Sub], jmp : Term[Jmp]) -> Term[Jmp] {
  let needs_alternation = jmp.alt() is None &&
    (match jmp.dst() {
      None => false
      Some(IndirectDst(_)) => true
      Some(ResolvedDst(dst)) => sub.find_blk(dst) is None
    })
  if needs_alternation {
    ir_update_jmp(jmp, (dst, _) => (None, dst))
  } else {
    jmp
  }
}

///|
/// Upstream `link_call`: relinks the destinations that are entries of
/// subroutines (`sub_of_blk` maps entry blocks to their subroutines) to the
/// subroutines, turning intraprocedural jumps to entries into tail calls;
/// a resolved call of a block with an explicit callee (`external_callee` of
/// the block) is relinked to the callee.
fn ir_link_call(
  sub_of_blk : Map[Tid, Tid],
  external_callee : Tid?,
  jmp : Term[Jmp],
) -> Term[Jmp] {
  let resolve = (dst : JmpDst?) => {
    match dst {
      Some(ResolvedDst(tid)) => Some(tid)
      _ => None
    }
  }
  let sub_of_dst = (dst : JmpDst?) => {
    resolve(dst).bind(tid => sub_of_blk.get(tid)).map(Jmp::resolved)
  }
  match (sub_of_dst(jmp.dst()), sub_of_dst(jmp.alt())) {
    (_, Some(_) as alt) => ir_update_jmp(jmp, (dst, _) => (dst, alt))
    (Some(_) as alt, None) => ir_update_jmp(jmp, (_, _) => (None, alt))
    (None, None) =>
      match (resolve(jmp.alt()), external_callee) {
        (Some(_), Some(callee)) =>
          ir_update_jmp(jmp, (dst, _) => (dst, Some(Jmp::resolved(callee))))
        _ => jmp
      }
  }
}

///|
/// The program-level relinking of the jumps of a lifted program (the last
/// step of upstream `Bap_sema_lift.program`): jumps that may leave their
/// subroutines become calls (`alternate_nonlocal`), and the destinations
/// that are entry blocks of subroutines (`entries` maps the tids of entry
/// blocks to the tids of their subroutines) are relinked to the subroutines
/// (`link_call`), jumps to entries becoming tail calls. `external_callee`
/// gives the explicit callee of a block (upstream `Symtab.explicit_callee`
/// of the block address), to which its resolved calls are relinked when
/// they call no subroutine of the program.
pub fn Program::relink_calls(
  prog : Term[Program],
  entries : Map[Tid, Tid],
  external_callee? : (Term[Blk]) -> Tid?,
) -> Term[Program] {
  prog.map_subs(sub => {
    sub.map_blks(blk => {
      let callee = match external_callee {
        Some(f) => f(blk)
        None => None
      }
      blk.map_jmps(jmp => {
        ir_link_call(entries, callee, ir_alternate_nonlocal(sub, jmp))
      })
    })
  })
}

///|
/// Upstream `make_name`: the name of the label, or `interrupt:#<n>` for an
/// interrupt vector, or the textual tid.
fn ir_synthetic_name(tid : Tid) -> String {
  match (tid.name(), tid.ivec()) {
    (Some(name), _) => name
    (None, Some(ivec)) => "interrupt:#\{ivec}"
    (None, None) => tid.to_string()
  }
}

///|
/// Upstream `insert_synthetic`: every resolved call destination that is not
/// a subroutine of `prog` gets an empty synthetic subroutine (tagged
/// `synthetic`, and `intrinsic` when its name is in the `intrinsic`
/// package), so that all calls of the program are to its subroutines.
pub fn Program::insert_synthetic(prog : Term[Program]) -> Term[Program] {
  let mut result = prog
  for sub in prog.subs() {
    for blk in sub.blks() {
      for jmp in blk.jmps() {
        match jmp.alt() {
          Some(ResolvedDst(dst)) if result.find_sub(dst) is None => {
            let name = ir_synthetic_name(dst)
            let mut synthetic = Sub::create(name~, tid=dst).set_attr(
              Attr::synthetic(),
            )
            if name.has_prefix("intrinsic:") {
              synthetic = synthetic.set_attr(Attr::sub_intrinsic())
            }
            result = result.append_sub(synthetic)
          }
          _ => ()
        }
      }
    }
  }
  result
}
