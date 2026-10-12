// The knowledge-base side of the BIL plugin (upstream `bil_lifter.ml`,
// `bil_ir.ml` and the declarations of `bil_main.ml`): the `bap:bir` and
// `bap:jump-dests` theories, the slots of the lifted code, and the rules
// `bil-lifter`, `machine-code`, `bil-semantics` and `reify-ir`.

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="bil",
)

///|
fn bap_name(name : String) -> @knowledge.Name {
  @knowledge.Name::create(name, pkg="bap")
}

// The graph of IR blocks of an effect.

///|
fn tids_of_blks(blks : Array[@types.Term[@types.Blk]]) -> Array[Int32] {
  blks.map(b => b.tid().id())
}

///|
/// The `bap:ir-graph` property of effects: the graphical representation
/// of the program (upstream `Bil_ir.slot`). Graphs are equal when their
/// entries are.
let ir_graph : @knowledge.Slot[@core_theory.EffectCls, Cfg] = @core_theory.Semantics::cls().property(
  name=bap_name("ir-graph"),
  domain=@knowledge.Domain::custom(
    bap_name("graph"),
    cfg => cfg.reify().map(b => @types.Blk::to_string(b)).join("\n"),
    empty=Cfg::empty(),
    order=(x, y) => {
      match (x.entry, y.entry) {
        (None, None) => Equal
        (None, _) => Less
        (_, None) => Greater
        (Some(a), Some(b)) => if a == b { Equal } else { Incomparable }
      }
    },
  ),
  desc="the graphical representation of the program",
  public=true,
)

///|
/// The property that holds the IR graph of an effect.
pub fn ir_graph_slot() -> @knowledge.Slot[@core_theory.EffectCls, Cfg] {
  ir_graph
}

///|
/// The `bap:bir` property of semantics: its IR blocks, the entry first
/// (upstream `Term.slot`).
let bir : @knowledge.Slot[
  @core_theory.EffectCls,
  Array[@types.Term[@types.Blk]],
] = @core_theory.Semantics::cls().property(
  name=bap_name("bir"),
  domain=@knowledge.Domain::custom(
    bap_name("bir"),
    blks => blks.map(b => @types.Blk::to_string(b)).join("\n"),
    empty=[],
    order=(x, y) => {
      match (x, y) {
        ([], []) => Equal
        ([], _) => Less
        (_, []) => Greater
        _ =>
          if tids_of_blks(x) == tids_of_blks(y) {
            Equal
          } else {
            Incomparable
          }
      }
    },
  ),
  desc="the IR of the program",
  public=true,
)

///|
/// The property that holds the IR blocks of a semantics.
pub fn bir_slot() -> @knowledge.Slot[
  @core_theory.EffectCls,
  Array[@types.Term[@types.Blk]],
] {
  bir
}

///|
fn graph_of(e : @core_theory.Effect) -> Cfg {
  e.get(ir_graph)
}

///|
fn graph_eff(cfg : Cfg) -> @core_theory.Effect {
  @core_theory.Effect::empty(@core_theory.EffectSort::bot()).put(ir_graph, cfg)
}

///|
fn exp_of(v : @core_theory.Value) -> @types.Exp {
  match v.bil() {
    Some(e) => e
    None => Unknown("empty", v.sort().bil_type())
  }
}

///|
/// The term identifier of a program label: the identifiers of address,
/// interrupt and name labels are those of `@types.Tid::for_addr`,
/// `for_ivec` and `for_name`.
pub fn label_tid(l : @core_theory.Label) -> @types.Tid {
  match l.addr() {
    Some(w) => @types.Tid::for_addr(w)
    None =>
      match l.ivec() {
        Some(n) => @types.Tid::for_ivec(n)
        None =>
          match l.name() {
            Some(n) => @types.Tid::for_name(n)
            None => @types.Tid::restore(id=l.id())
          }
      }
  }
}

///|
/// The `bap:bir` theory (upstream `Bil_ir.IR`): effects denote graphs of
/// IR blocks (the `ir-graph` property); the definitions and conditions
/// are the BIL expressions of the values (provided by the `bap:bil`
/// theory in a join). A goto is a call when its label is a subroutine.
pub fn ir_theory() -> @core_theory.Core {
  let alg = ir_algebra()
  {
    ..@core_theory.Core::empty(),
    set: (v, x) => state => graph_eff((alg.set)(v.reify(), exp_of(x(state)))),
    repeat: (c, body) => {
      state => {
        let c = exp_of(c(state))
        graph_eff((alg.repeat)(c, graph_of(body(state))))
      }
    },
    branch: (c, yes, nay) => {
      state => {
        let c = exp_of(c(state))
        let yes = graph_of(yes(state))
        let nay = graph_of(nay(state))
        graph_eff((alg.branch)(c, yes, nay))
      }
    },
    jmp: dst => state => graph_eff((alg.jmp)(exp_of(dst(state)))),
    goto: lbl => {
      _ => graph_eff((alg.goto)(Label(label_tid(lbl)), lbl.is_subroutine()))
    },
    seq: (x, y) => {
      state => {
        let x = graph_of(x(state))
        graph_eff((alg.seq)(x, graph_of(y(state))))
      }
    },
    blk: (lbl, x, y) => {
      state => {
        let x = graph_of(x(state))
        let y = graph_of(y(state))
        let lbl = if lbl.same(@core_theory.Label::null()) {
          None
        } else {
          Some(label_tid(lbl))
        }
        graph_eff((alg.blk)(lbl, x, y))
      }
    },
  }
}

///|
/// The IR blocks of a semantics (upstream `Bil_ir.reify` of its graph).
pub fn reify(sema : @core_theory.Semantics) -> Array[@types.Term[@types.Blk]] {
  sema.get(ir_graph).reify()
}

// The jump destinations (upstream `Bil_lifter.Brancher`).

///|
fn dests_union(
  x : Array[@core_theory.Label]?,
  y : Array[@core_theory.Label]?,
) -> Array[@core_theory.Label]? {
  match (x, y) {
    (None, s) | (s, None) => s
    (Some(x), Some(y)) => {
      let out = x.copy()
      for l in y {
        if !out.iter().any(m => m.same(l)) {
          out.push(l)
        }
      }
      Some(out)
    }
  }
}

///|
let dests : @knowledge.Slot[@core_theory.EffectCls, Array[@core_theory.Label]?] = @core_theory.Semantics::cls().property(
  name=bap_name("insn-dests"),
  domain=@knowledge.Domain::custom(
    bap_name("dests"),
    d => {
      match d {
        None => "unknown"
        Some(ls) => ls.map(l => label_tid(l).to_string()).join(" ")
      }
    },
    empty=None,
    order=(x, y) => {
      match (x, y) {
        (None, None) => Equal
        (None, _) => Less
        (_, None) => Greater
        (Some(a), Some(b)) =>
          if a.length() == b.length() &&
            a.iter().all(l => b.iter().any(m => m.same(l))) {
            Equal
          } else {
            Incomparable
          }
      }
    },
    join=(x, y) => Ok(dests_union(x, y)),
  ),
  desc="the set of possible jump destinations",
  public=true,
)

///|
/// The property that holds the jump destinations of an effect (upstream
/// `Insn.Slot.dests`); `Label::null()` stands for an unknown destination.
pub fn dests_slot() -> @knowledge.Slot[
  @core_theory.EffectCls,
  Array[@core_theory.Label]?,
] {
  dests
}

///|
fn dests_eff(d : Array[@core_theory.Label]?) -> @core_theory.Effect {
  @core_theory.Effect::empty(@core_theory.EffectSort::bot()).put(dests, d)
}

///|
/// The `bap:jump-dests` theory (upstream `Bil_lifter.Brancher`): an
/// approximation of the jump destinations.
pub fn brancher_theory() -> @core_theory.Core {
  let get = (e : @core_theory.Effect) => e.get(dests)
  {
    ..@core_theory.Core::empty(),
    goto: dst => _ => dests_eff(Some([dst])),
    jmp: _ => _ => dests_eff(Some([@core_theory.Label::null()])),
    seq: (x, y) => {
      state => {
        let x = get(x(state))
        dests_eff(dests_union(x, get(y(state))))
      }
    },
    blk: (_, x, y) => {
      state => {
        let x = get(x(state))
        dests_eff(dests_union(x, get(y(state))))
      }
    },
    branch: (_, x, y) => {
      state => {
        let x = get(x(state))
        dests_eff(dests_union(x, get(y(state))))
      }
    },
  }
}

///|
/// Declares the `bap:bir` and `bap:jump-dests` theories (upstream
/// `Bil_ir.init` and `Bil_lifter.init`). Declared theories are left as
/// they are.
pub fn declare_ir_theories() -> Unit raise {
  if !is_declared("bap:bir") {
    @core_theory.declare_theory(
      name="bir",
      pkg="bap",
      desc="Builds the graphical representation of a program.",
      provides=["cfg"],
      _ => ir_theory(),
    )
  }
  if !is_declared("bap:jump-dests") {
    @core_theory.declare_theory(
      name="jump-dests",
      pkg="bap",
      desc="an approximation of jump destinations",
      provides=["brancher", "branch-destinations"],
      _ => brancher_theory(),
    )
  }
}

// The slots of program objects.

///|
let insn : @knowledge.Slot[Unit, @mc.Insn?] = @core_theory.Program::cls().property(
  name=bap_name("insn"),
  domain=@knowledge.Domain::optional(
    @knowledge.Domain::flat(bap_name("insn"), i => i.name()),
  ),
  desc="the machine instruction",
  public=true,
)

///|
/// The decoded machine instruction of a program object (upstream
/// `Disasm_expert.Basic.Insn.slot`).
pub fn insn_slot() -> @knowledge.Slot[Unit, @mc.Insn?] {
  insn
}

///|
let bil_code : @knowledge.Slot[Unit, Array[@types.Stmt]] = @core_theory.Program::cls().property(
  name=bap_name("bil-code"),
  domain=@knowledge.Domain::flat(
    bap_name("bil"),
    bil => bil.map(s => s.to_string()).join("; "),
    empty=[],
  ),
  desc="the BIL code of the instruction",
  public=true,
)

///|
/// The BIL code of a program object (upstream `Bil.code`), provided by
/// the `bil-lifter` rule.
pub fn code_slot() -> @knowledge.Slot[Unit, Array[@types.Stmt]] {
  bil_code
}

///|
/// The relocation information of the units, by unit name (upstream the
/// `bil-relocations` property of units).
let unit_relocations : @knowledge.Var[Map[String, Relocations]] = @knowledge.Var::new(
  "bil-relocations",
  _ => Map([]),
  pkg="bap",
)

///|
/// Provides the relocation information of a unit (upstream the
/// `bil-relocations` promise: the external names are resolved in the
/// knowledge base, see `Relocations::resolve_externals`).
pub fn provide_relocations(
  state : @knowledge.State,
  unit_ : @core_theory.ProgramUnit,
  rels : Relocations,
) -> Unit raise {
  let rels = rels.resolve_externals(state)
  unit_relocations.update(state, m => {
    let m = m.copy()
    m[unit_.name()] = rels
    m
  })
}

///|
/// The agent that suggests the names of external symbols (upstream
/// `bil-fixup-relocator`).
let fixup_agent : @knowledge.Agent = match
  @knowledge.Agent::register(
    "bil-fixup-relocator",
    pkg="bap",
    desc="names the external references of relocated instructions",
  ) {
  Ok(agent) => agent
  Err(_) => @knowledge.Agent::read("bil-fixup-relocator", pkg="bap")
}

///|
/// Resolves the names of the external references in the knowledge base
/// (upstream `Relocations.resolve_externals`): each name is suggested (by
/// the `bap:bil-fixup-relocator` agent) as a possible name of a fresh
/// program object, and the name of that object, as resolved by the
/// knowledge base from all opinions, replaces it.
pub fn Relocations::resolve_externals(
  self : Relocations,
  state : @knowledge.State,
) -> Relocations raise {
  let exts : Map[UInt64, String] = Map([])
  for k, n in self.exts {
    let name = state.scoped(@core_theory.Program::cls(), obj => {
      state.suggest(
        fixup_agent,
        @core_theory.Label::possible_name_slot(),
        obj,
        Some(n),
      )
      state.collect(@core_theory.Label::name_slot(), obj)
    })
    exts[k] = name.unwrap_or(n)
  }
  { rels: self.rels, exts, }
}

///|
/// The BIL code of an instruction as upstream's `bil-lifter` rule computes
/// it: lifted with the lifters of `registry` (intrinsics and passes, see
/// `lift`), re-denoted with the desugared BIL theory (`optimize`) and with
/// the relocations of the unit applied (`Relocations::fixup`). Lifter
/// errors are logged and give no code.
pub fn lift_code(
  state : @knowledge.State,
  obj : @knowledge.Object[Unit],
  registry : @mc.Registry,
) -> Array[@types.Stmt] raise {
  let i = match state.collect(insn, obj) {
    None => return []
    Some(i) => i
  }
  let target = state.collect(@core_theory.Label::target_slot(), obj)
  let ctx = @mc.Context::create(target, encoding=i.encoding())
  let lifted = lift(registry, ctx, i) catch {
    e => {
      log.warning(message="BIL: the BIL lifter failed with \{e.message()}")
      return []
    }
  }
  let bil = lifted.bil()
  if bil.is_empty() {
    return []
  }
  let bil = optimize(state, bil)
  match state.collect(@core_theory.Label::unit_slot(), obj) {
    None => bil
    Some(u) =>
      match unit_relocations.get(state).get(u.name()) {
        None => bil
        Some(rels) => {
          let width = target.code_addr_size()
          rels.fixup(
            bil,
            addr=i.addr(),
            size=i.size(),
            width=if width > 0 { width } else { target.bits() },
          )
        }
      }
  }
}

///|
/// Re-denotes lifted BIL with the BIL theory, desugared for the target of
/// the current program (upstream `Optimizer.run Bil.Theory.parser`, with
/// `Optimizer = Theory.Parser.Make(Theory.Pass.Desugar(Bil_semantics.Core))`).
pub fn optimize(
  state : @knowledge.State,
  bil : Array[@types.Stmt],
) -> Array[@types.Stmt] raise {
  bil_theory().desugar().reflect_bil(bil)(state).bil()
}

///|
/// The semantics of the BIL code of an instruction in the theory
/// instantiated for its target (upstream `bil-semantics` rule): the
/// context of the instance is `arch-<target>`, `floating-point` when
/// `with_fp`, and `bil-lifter`.
pub fn denote_code(
  state : @knowledge.State,
  obj : @knowledge.Object[Unit],
  with_fp : Bool,
) -> @core_theory.Semantics raise {
  let bil = state.collect(bil_code, obj)
  if bil.is_empty() {
    return @core_theory.Semantics::empty()
  }
  let target = state.collect(@core_theory.Label::target_slot(), obj)
  let context = ["arch-\{target.to_string()}"]
  if with_fp {
    context.push("floating-point")
  }
  context.push("bil-lifter")
  let theory = @core_theory.instance(state, context~)
  let core = @core_theory.require(state, theory)
  @core_theory.Semantics::of_effect(core.reflect_bil(bil)(state))
}

///|
let rules_installed : Ref[Bool] = { val: false, }

///|
/// The lifters and the floating-point option used by the rules (set by
/// the last `install_rules`).
let rules_config : Ref[(@mc.Registry, Bool)] = {
  val: (@mc.Registry::global(), true),
}

///|
/// Registers the knowledge base rules of the BIL plugin (upstream
/// `Bil_lifter.init` and `Bil_ir.init`), once (later calls only change
/// the lifters and the floating-point option used by the rules):
///
/// - `bil-lifter` provides `code_slot` from `insn_slot` (see `lift_code`);
/// - `machine-code` provides the semantics of instructions with their BIL
///   code;
/// - `bil-semantics` denotes the BIL code in the Core Theory (see
///   `denote_code`);
/// - `reify-ir` adds the IR blocks of the `ir-graph` to the semantics.
///
/// The theories are declared as well (`declare_theories`,
/// `declare_ir_theories`).
pub fn install_rules(
  registry~ : @mc.Registry = @mc.Registry::global(),
  with_fp~ : Bool = true,
) -> Unit raise {
  declare_theories(with_fp~)
  declare_ir_theories()
  rules_config.val = (registry, with_fp)
  if rules_installed.val {
    return
  }
  rules_installed.val = true
  let sema = @core_theory.Semantics::slot()
  @knowledge.Rule::create("bil-lifter", pkg="bap")
  .require(insn)
  .provide(bil_code)
  .comment("uses legacy lifters to provide BIL code.")
  let _ = bil_code.promise((state, obj) => {
    lift_code(state, obj, rules_config.val.0)
  })
  @knowledge.Rule::create("machine-code", pkg="bap")
  .require(insn)
  .provide(sema)
  .comment("translates machine code instructions into CT terms ")
  let _ = sema.promise((state, obj) => {
    match state.collect(insn, obj) {
      None => @core_theory.Semantics::empty()
      Some(_) => {
        let bil = state.collect(bil_code, obj)
        if bil.is_empty() {
          @core_theory.Semantics::empty()
        } else {
          @core_theory.Semantics::empty().put(@core_theory.bil_slot(), bil)
        }
      }
    }
  })
  @knowledge.Rule::create("bil-semantics", pkg="bap")
  .require(bil_code)
  .provide(sema)
  .comment("denotates BIL in the Core Theory terms")
  let _ = sema.promise((state, obj) => {
    denote_code(state, obj, rules_config.val.1)
  })
  @knowledge.Rule::create("reify-ir", pkg="bap")
  .require(sema)
  .require(ir_graph)
  .provide(sema)
  .comment("reifies IR")
  let _ = sema.promise((state, obj) => {
    let s = state.collect(sema, obj)
    if !s.get(bir).is_empty() {
      @core_theory.Semantics::empty()
    } else {
      match reify(s) {
        [] => @core_theory.Semantics::empty()
        blks => s.put(bir, blks)
      }
    }
  })
}
