///|
/// An instruction specification of `--bil-enable-intrinsics` (upstream
/// `Bil_lifter.ispec`).
pub(all) enum ISpec {
  /// `:any` - every instruction
  Any
  /// `:unknown` - instructions with unknown semantics
  Unk
  /// `:special` - instructions whose semantics has a special statement
  Special
  /// `tag:<str>` (or `kind:<str>`) - instructions with a kind starting
  /// with the string
  Tag(String)
  /// `asm:<str>` - instructions whose assembly starts with the string
  Asm(String)
  /// `<s1>:<s2>` - instructions with an opcode starting with `s2` in an
  /// encoding starting with `s1`
  Insn(String, String)
} derive(Eq, Debug)

///|
pub extend ISpec with Eq::{not_equal, equal}

///|
pub extend ISpec with Debug::{to_repr}

///|
/// Parses a specification (case-insensitive predicates are uppercased).
pub fn ISpec::parse(s : String) -> ISpec raise Failure {
  let parts = s.split(":").map(p => p.to_owned()).collect()
  match parts {
    ["", "any"] => Any
    ["", "unknown"] => Unk
    ["", "special"] => Special
    ["tag" | "kind", name] => Tag(name.to_upper())
    ["asm", str] => Asm(str.to_upper())
    ["", kw] =>
      raise Failure("unknown keyword `\{kw}', expects any | unknown | special")
    [pref, code] => Insn(pref.to_upper(), code.to_upper())
    _ => raise Failure("ill-formed specification: \{s}")
  }
}

///|
/// Prints a specification.
pub fn ISpec::to_string(self : ISpec) -> String {
  match self {
    Any => ":any"
    Unk => ":unknown"
    Special => ":special"
    Tag(name) => "tag:" + name
    Asm(str) => "asm:" + str
    Insn(pref, code) => "\{pref}:\{code}"
  }
}

///|
/// The name of an instruction kind as printed by upstream (the
/// S-expression of the polymorphic variant).
pub fn kind_name(k : @mc.Kind) -> String {
  match k {
    ConditionalBranch => "Conditional_branch"
    UnconditionalBranch => "Unconditional_branch"
    IndirectBranch => "Indirect_branch"
    Return => "Return"
    Call => "Call"
    Barrier => "Barrier"
    Terminator => "Terminator"
    MayAffectControlFlow => "May_affect_control_flow"
    MayLoad => "May_load"
    MayStore => "May_store"
  }
}

///|
/// The encoding of an instruction (the package of its name upstream).
pub fn insn_encoding(insn : @mc.Insn) -> String {
  insn.encoding().name().unqualified()
}

///|
fn matches_pat(pat : String, str : String) -> Bool {
  str.trim().to_owned().to_upper().has_prefix(pat)
}

///|
/// `true` if the instruction satisfies one of the predicates (upstream
/// `matches_spec`; the keywords are ignored).
pub fn matches_spec(specs : ArrayView[ISpec], insn : @mc.Insn) -> Bool {
  specs
  .iter()
  .any(spec => {
    match spec {
      Tag(t) => insn.kinds().iter().any(k => matches_pat(t, kind_name(k)))
      Asm(t) => matches_pat(t, insn.assembly())
      Insn(ns, opcode) =>
        matches_pat(ns, insn_encoding(insn)) && matches_pat(opcode, insn.name())
      Any | Unk | Special => false
    }
  })
}

///|
fn word(width : Int, n : Int64) -> @types.Word {
  @types.Word::of_int64(n, width~) catch {
    _ => @types.Word::zero(width~) catch { _ => @types.Word::b0() }
  }
}

///|
/// The intrinsic call that stands for an instruction (upstream
/// `create_intrinsic`): each operand is assigned to `insn:op<n>`, the
/// address of the next instruction to `insn:next_address`, followed by the
/// `intrinsic` special `<encoding>:<opcode>`.
pub fn create_intrinsic(
  target : @core_theory.Target,
  insn : @mc.Insn,
) -> Array[@types.Stmt] {
  let width = target.bits()
  let out : Array[@types.Stmt] = []
  for p, op in insn.ops() {
    let v = @types.Var::create("insn:op\{p + 1}", Imm(width))
    let x : @types.Word = match op {
      Imm(x) => word(width, x)
      Fmm(x) => word(64, x.reinterpret_as_int64())
      Reg(code~, ..) => word(width, code.to_int64())
    }
    out.push(Move(v, Int(x)))
  }
  out.push(
    Move(
      @types.Var::create("insn:next_address", Imm(width)),
      Int(word(width, insn.next_addr().reinterpret_as_int64())),
    ),
  )
  out.push(
    @types.Stmt::encode(
      @types.Stmt::intrinsic(),
      "\{insn_encoding(insn)}:\{insn.name()}",
    ),
  )
  out
}

///|
fn is_special(s : @types.Stmt) -> Bool {
  match s {
    Special(_) => true
    Move(_) | CpuExn(_) | Jmp(_) => false
    While(body~, ..) => has_special(body)
    If(yes~, no~, ..) => has_special(yes) || has_special(no)
  }
}

///|
/// `true` if the program has a special statement (at any depth).
pub fn has_special(bil : ArrayView[@types.Stmt]) -> Bool {
  bil.iter().any(is_special)
}

///|
/// The configuration of the BIL lifter.
pub(all) struct Config {
  /// emulate floating-point operations (`--bil-floating-point-emulation`)
  with_fp : Bool
  /// the instructions translated into intrinsic calls
  /// (`--bil-enable-intrinsics`)
  enable_intrinsics : Array[ISpec]
}

///|
/// The default configuration.
pub fn Config::default() -> Config {
  { with_fp: true, enable_intrinsics: [], }
}

///|
let config : Ref[Config] = { val: Config::default(), }

///|
/// The configuration set by the plugin.
pub fn current_config() -> Config {
  config.val
}

///|
/// Sets the configuration of the lifter.
pub fn configure(c : Config) -> Unit {
  config.val = c
}

///|
/// Lifts an instruction with the lifters of the registry (upstream
/// `Bil_lifter.lift` and the lifters factory): the instructions selected
/// by the intrinsics specification are translated into intrinsic calls,
/// otherwise the lifted code goes through the selected BIL passes
/// (`apply_passes`); instructions with unknown semantics (unsupported or
/// lifted to nothing) with `:unknown`, and instructions with special
/// statements with `:special`, are also translated into intrinsic calls.
pub fn lift(
  registry : @mc.Registry,
  ctx : @mc.Context,
  insn : @mc.Insn,
  cfg? : Config = config.val,
) -> @mc.Lifted raise @mc.LiftError {
  let specs = cfg.enable_intrinsics
  let for_all = specs.contains(Any)
  let for_unk = specs.contains(Unk)
  let for_special = specs.contains(Special)
  let intrinsic = () => @mc.Lifted::of_bil(create_intrinsic(ctx.target(), insn))
  if for_all || matches_spec(specs, insn) {
    return intrinsic()
  }
  let lifted = registry.lift(ctx, insn) catch {
    Unsupported(..) as e => if for_unk { return intrinsic() } else { raise e }
    e => raise e
  }
  let bil = match apply_passes(lifted.bil()) {
    Ok(bil) => bil
    Err(detail) => raise IllTyped(opcode=insn.name(), detail~)
  }
  if bil.is_empty() && for_unk {
    intrinsic()
  } else if for_special && has_special(bil) {
    intrinsic()
  } else {
    @mc.Lifted::create(
      bil,
      delay=lifted.delay(),
      dest_encoding?=lifted.dest_encoding(),
    )
  }
}

///|
/// A lifter provider (named `bil`) that lifts with the given registry
/// through `lift`, with the relocation fixups of `relocations`.
pub fn provider(
  registry : @mc.Registry,
  relocations? : Relocations = Relocations::empty(),
) -> @mc.Provider {
  @mc.Provider::create(
    "bil",
    accepts=ctx => !registry.accepting(ctx).is_empty(),
    lift=(ctx, insn) => {
      let lifted = lift(registry, ctx, insn)
      let bil = relocations.fixup(
        lifted.bil(),
        addr=insn.addr(),
        size=insn.size(),
        width=ctx.target().bits(),
      )
      @mc.Lifted::create(
        bil,
        delay=lifted.delay(),
        dest_encoding?=lifted.dest_encoding(),
      )
    },
  )
}
