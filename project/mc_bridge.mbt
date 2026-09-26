// Bridge between project disassembly instructions and the architecture
// lifters (providers) registered in an `@mc.Registry`.

///|
/// The `@mc.Kind` corresponding to a project instruction kind.
pub fn ProjectInstructionKind::to_mc_kind(
  self : ProjectInstructionKind,
) -> @mc.Kind {
  match self {
    ProjectConditionalBranch => ConditionalBranch
    ProjectUnconditionalBranch => UnconditionalBranch
    ProjectIndirectBranch => IndirectBranch
    ProjectReturn => Return
    ProjectCall => Call
    ProjectBarrier => Barrier
    ProjectTerminator => Terminator
    ProjectMayAffectControlFlow => MayAffectControlFlow
    ProjectMayLoad => MayLoad
    ProjectMayStore => MayStore
  }
}

///|
/// The project instruction kind corresponding to an `@mc.Kind`.
pub fn ProjectInstructionKind::of_mc_kind(
  kind : @mc.Kind,
) -> ProjectInstructionKind {
  match kind {
    ConditionalBranch => ProjectConditionalBranch
    UnconditionalBranch => ProjectUnconditionalBranch
    IndirectBranch => ProjectIndirectBranch
    Return => ProjectReturn
    Call => ProjectCall
    Barrier => ProjectBarrier
    Terminator => ProjectTerminator
    MayAffectControlFlow => ProjectMayAffectControlFlow
    MayLoad => ProjectMayLoad
    MayStore => ProjectMayStore
  }
}

///|
/// The encoding of the instruction as a Core Theory language: the
/// instruction's `encoding()` when it names a known encoding (e.g.
/// `llvm-thumb`, `llvm-mips32`), `Language::unknown()` for generic decoder
/// tags such as `llvm`, `raw` or the empty string.
pub fn ProjectDisassemblyInstruction::encoding_language(
  self : ProjectDisassemblyInstruction,
) -> @core_theory.Language {
  let language = @core_theory.Language::of_string(self.encoding())
  if @core_theory.Language::members().contains(language) {
    language
  } else {
    @core_theory.Language::unknown()
  }
}

///|
/// Convert a decoded project instruction into the shared `@mc.Insn`
/// representation consumed by architecture lifters, keeping its opcode
/// code, kinds and raw bytes. The encoding defaults to
/// `encoding_language()`.
pub fn ProjectDisassemblyInstruction::to_mc_insn(
  self : ProjectDisassemblyInstruction,
  encoding? : @core_theory.Language = self.encoding_language(),
) -> @mc.Insn {
  let ops = self
    .operands()
    .map(op => {
      match op {
        ProjectRegisterOperand(code, name) => @mc.Reg(name~, code~)
        ProjectImmediateOperand(value) => @mc.Imm(value)
        ProjectFloatingOperand(value) => @mc.Fmm(value)
      }
    })
  @mc.Insn::create(
    self.name(),
    ops,
    addr=self.addr(),
    size=self.memory().length(),
    assembly=self.assembly(),
    code=self.code(),
    encoding~,
    kinds=self.kinds().map(kind => kind.to_mc_kind()),
    raw=self.memory().to_bytes(),
  )
}

///|
/// The lifting context of the instruction on `target`: the instruction's
/// own encoding when it names one, the target's default encoding
/// (`@mc.default_encoding`) otherwise.
pub fn ProjectDisassemblyInstruction::lift_context(
  self : ProjectDisassemblyInstruction,
  target : @core_theory.Target,
) -> @mc.Context {
  @mc.Context::create(target, encoding=self.encoding_language())
}

///|
/// Lift the instruction on `target`: the providers of `registry` (the
/// global registry with the built-in lifters, see `register_builtin_lifters`,
/// by default) accepting the instruction's context are tried in order, and
/// the result is type-checked. When no provider accepts the context or all
/// of them report `Unsupported`, the built-in Basic lifter
/// (`lift_basic_bil`) is used instead. Other lifter errors (bad operands,
/// ill-typed semantics, failures) are returned as `Err`.
pub fn ProjectDisassemblyInstruction::lift(
  self : ProjectDisassemblyInstruction,
  target~ : @core_theory.Target,
  registry? : @mc.Registry = project_lift_registry(),
) -> Result[@mc.Lifted, String] {
  let ctx = self.lift_context(target)
  let insn = self.to_mc_insn(encoding=ctx.encoding())
  try registry.lift(ctx, insn) catch {
    Unsupported(..) =>
      match self.lift_basic_bil() {
        Ok(bil) => Ok(@mc.Lifted::of_bil(bil))
        Err(reason) => Err(reason)
      }
    err => Err(err.message())
  } noraise {
    lifted => Ok(lifted)
  }
}
