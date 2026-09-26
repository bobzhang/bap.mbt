// Port of BAP `plugins/x86/x86_lifter.ml` (entry points `disasm_instr` and
// `insn`) and of the legacy half of `x86_targets.ml`: the byte-level lifter
// as an `@mc.Provider`.

///|
/// Decode and lift one instruction (upstream `disasm_instr`).
fn legacy_lift_exn(
  mode : Mode,
  bytes : BytesView,
  addr : UInt64,
) -> (Array[@types.Stmt], Int) raise X86Error {
  reset_tmps()
  let decoded = parse_instr(mode, bytes, addr)
  let (ss, pref) = parse_prefixes(mode, decoded.pref)
  let ctx : Ctx = {
    mode,
    ss,
    pref,
    has_rex: decoded.prefix.rex is Some(_),
    has_vex: decoded.prefix.vex is Some(_),
  }
  (ctx.to_ir(decoded.op), decoded.next)
}

///|
fn target_name(mode : Mode) -> String {
  match mode {
    X86 => "x86"
    X8664 => "x86_64"
  }
}

///|
/// Lift the instruction encoded at the start of `bytes` (located at
/// `addr`) with the legacy byte-level lifter (upstream
/// `X86_lifter.IA32.lift`/`AMD64.lift`).
///
/// Instructions that the legacy lifter does not model (upstream
/// `No_semantics`, lifted upstream to an empty program so that other
/// semantics providers may contribute) and invalid or truncated encodings
/// (upstream `Arch_exception`) raise `Unsupported`; ill-typed programs raise
/// `IllTyped`. `opcode` names the instruction in the errors.
pub fn lift_legacy(
  mode : Mode,
  bytes : BytesView,
  addr~ : UInt64,
  opcode? : String = "x86",
) -> Array[@types.Stmt] raise @mc.LiftError {
  let bil = legacy_lift_exn(mode, bytes, addr).0 catch {
      NoSemantics(_) | ArchException(_) =>
        raise Unsupported(opcode~, target=target_name(mode))
    }
  match @types.check_stmt_types(bil) {
    Ok(_) => bil
    Err(err) => raise IllTyped(opcode~, detail=err.to_string())
  }
}

///|
/// The length in bytes of the instruction encoded at the start of `bytes`
/// according to the legacy decoder, `None` when it is not decoded (or not
/// lifted) by the legacy lifter.
pub fn legacy_length(mode : Mode, bytes : BytesView, addr~ : UInt64) -> Int? {
  try legacy_lift_exn(mode, bytes, addr).1 catch {
    _ => None
  } noraise {
    n => Some(n)
  }
}

///|
/// The reason why the legacy lifter does not lift the instruction at the
/// start of `bytes` (`None` when it is lifted): the upstream `No_semantics`
/// or `Arch_exception` message.
pub fn legacy_failure(
  mode : Mode,
  bytes : BytesView,
  addr~ : UInt64,
) -> String? {
  try legacy_lift_exn(mode, bytes, addr) catch {
    NoSemantics(msg) => Some("no semantics: " + msg)
    ArchException(msg) => Some("invalid instruction: " + msg)
  } noraise {
    _ => None
  }
}

///|
/// x86 encodings accepted by the providers (an unknown encoding is accepted
/// too: `@mc.Context::create` only leaves it unknown when the target has no
/// default).
let x86_encodings : ReadOnlyArray[@core_theory.Language] = [
  @core_theory.Language::llvm_x86(),
  @core_theory.Language::llvm_x86_64(),
]

///|
/// The legacy lifter mode of `ctx`: `X8664` for 64-bit targets of the x86
/// family, `X86` for 32-bit ones, `None` for other targets (including
/// 16-bit ones) and non-x86 encodings.
pub fn mode_of_context(ctx : @mc.Context) -> Mode? {
  if !ctx.belongs(@core_theory.Target::x86()) {
    return None
  }
  if !(ctx.encoding.is_unknown() || x86_encodings.contains(ctx.encoding)) {
    return None
  }
  match ctx.target.bits() {
    64 => Some(X8664)
    32 => Some(X86)
    _ => None
  }
}

///|
/// Whether the x86 providers apply to `ctx` (see `mode_of_context`).
pub fn accepts(ctx : @mc.Context) -> Bool {
  mode_of_context(ctx) is Some(_)
}

///|
/// Name of the legacy lifter provider.
pub let legacy_provider_name : String = "x86-legacy"

///|
/// Lift in a context with the legacy lifter: the instruction is decoded
/// from its raw bytes (`insn.raw()`) at `insn.addr()`.
pub fn lift_legacy_in_context(
  ctx : @mc.Context,
  insn : @mc.Insn,
) -> @mc.Lifted raise @mc.LiftError {
  guard mode_of_context(ctx) is Some(mode) else {
    raise Unsupported(opcode=insn.name, target=ctx.target.to_string())
  }
  let bil = lift_legacy(mode, insn.raw, addr=insn.addr, opcode=insn.name)
  @mc.Lifted::of_bil(bil)
}

///|
/// The legacy byte-level x86/x86-64 lifter provider (upstream
/// `X86_lifter`, the fallback of the `merge` lifter kind).
pub fn legacy_provider() -> @mc.Provider {
  @mc.Provider::create(
    legacy_provider_name,
    accepts~,
    lift=lift_legacy_in_context,
  )
}
