// Port of BAP `plugins/x86/x86_backend.ml` and the registrations of the
// per-opcode modules: a provider keyed by the LLVM MC opcode name that
// overrides the legacy lifter for specific opcodes.

///|
/// The per-opcode lifter of `name` in `mode` (upstream: the opcode table of
/// the `IA32` or `AMD64` backend), `None` when the opcode is not registered.
fn modern_lifter(
  mode : Mode,
  name : String,
  cet_enabled~ : Bool,
) -> ((Tools) -> Array[@types.Stmt] raise @mc.LiftError)? {
  // IA32 registers the 16- and 32-bit variants only
  let amd64_only = name.contains("64")
  if mode == X86 && amd64_only && !(name is ("ENDBR64" | "CDQE" | "CQO")) {
    return None
  }
  if btx_lifter(name) is Some(f) {
    return Some(f)
  }
  if mov_lifter(name) is Some(f) {
    return Some(f)
  }
  if mov_offset_spec(mode, name) is Some((reg, load)) {
    return Some(t => t.mov_offset(reg, load))
  }
  match name {
    "CMPXCHG8rr" => Some(t => t.cmpxchg_rr(8))
    "CMPXCHG16rr" => Some(t => t.cmpxchg_rr(16))
    "CMPXCHG32rr" => Some(t => t.cmpxchg_rr(32))
    "CMPXCHG64rr" => Some(t => t.cmpxchg_rr(64))
    "CMPXCHG8rm" => Some(t => t.cmpxchg_rm(8))
    "CMPXCHG16rm" => Some(t => t.cmpxchg_rm(16))
    "CMPXCHG32rm" => Some(t => t.cmpxchg_rm(32))
    "CMPXCHG64rm" => Some(t => t.cmpxchg_rm(64))
    "CDQ" => Some(t => t.cdq("EAX", "EDX"))
    "CDQE" => Some(t => t.cdq("EAX", "RAX"))
    "CQO" => Some(t => t.cdq("RAX", "RDX"))
    "CWD" => Some(t => t.cdq("AX", "DX"))
    "CWDE" => Some(t => t.cdq("AX", "EAX"))
    "CBW" => Some(t => t.cdq("AL", "AX"))
    "ENDBR32" | "ENDBR64" =>
      Some(_ => if cet_enabled { [intrinsic("endbr")] } else { [] })
    _ => None
  }
}

///|
/// Whether the per-opcode lifters model the LLVM opcode `name` in `mode`.
pub fn is_modern_opcode(mode : Mode, name : String) -> Bool {
  modern_lifter(mode, name, cet_enabled=false) is Some(_)
}

///|
/// Lift `insn` with the per-opcode lifters (upstream `X86_backend`): the
/// opcode is selected by `insn.name()` and the semantics is computed from
/// the LLVM MC operands (`insn.ops()`), the raw bytes being only consulted
/// for the lock prefix. Opcodes without a per-opcode lifter raise
/// `Unsupported`; malformed operands raise `BadOperands`, other failures
/// `Failure` and ill-typed programs `IllTyped`.
///
/// With `cet_enabled`, `ENDBR32`/`ENDBR64` lift to the `endbr` intrinsic,
/// otherwise to an empty program (upstream `--x86-cet-enabled`).
pub fn lift_modern(
  mode : Mode,
  insn : @mc.Insn,
  cet_enabled~ : Bool = false,
) -> Array[@types.Stmt] raise @mc.LiftError {
  guard modern_lifter(mode, insn.name, cet_enabled~) is Some(lift) else {
    raise Unsupported(opcode=insn.name, target=target_name(mode))
  }
  reset_tmps()
  let bil = lift({ mode, insn, })
  match @types.check_stmt_types(bil) {
    Ok(_) => bil
    Err(err) => raise IllTyped(opcode=insn.name, detail=err.to_string())
  }
}

///|
/// Name of the per-opcode lifter provider.
pub let provider_name : String = "x86"

///|
/// The per-opcode x86/x86-64 lifter provider (see `lift_modern`).
pub fn modern_provider(cet_enabled~ : Bool = false) -> @mc.Provider {
  @mc.Provider::create(provider_name, accepts~, lift=(ctx, insn) => {
    guard mode_of_context(ctx) is Some(mode) else {
      raise Unsupported(opcode=insn.name, target=ctx.target.to_string())
    }
    @mc.Lifted::of_bil(lift_modern(mode, insn, cet_enabled~))
  })
}

///|
/// Register the x86 providers with `registry` (the global `@mc` registry by
/// default): the per-opcode provider (`provider_name`) first, then the
/// legacy byte-level provider (`legacy_provider_name`), so that the
/// per-opcode lifters override the legacy lifter as in the upstream `merge`
/// lifter kind. Idempotent: providers are replaced by name.
///
/// This is not part of the project's built-in registration, where the
/// Basic lifter remains the default for x86; register explicitly to opt in
/// (providers registered in the registry are tried before the Basic
/// fallback of `@project`).
pub fn register(
  registry~ : @mc.Registry = @mc.Registry::global(),
  cet_enabled~ : Bool = false,
) -> Unit {
  registry.register(modern_provider(cet_enabled~))
  registry.register(legacy_provider())
}

///|
/// Target names covered by the providers, as in upstream `x86_main.ml`.
pub let targets : ReadOnlyArray[String] = ["x86", "x86_64"]
