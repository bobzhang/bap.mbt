// Registration of the Lisp semantics as `mc` lifter providers (upstream
// `Primus_lisp_main.Semantics.enable_lifter`).

///|
/// The embedded directories with the target semantics. As upstream, the
/// Lisp lifter loads all of them for every target; the definitions are
/// selected by their context declarations (e.g., `(declare (context
/// (target arm-family) (bits 64)))` for AArch64).
pub let semantic_dirs : Array[String] = [
  "semantics/riscv", "semantics/arm", "semantics/powerpc", "semantics/x86",
]

///|
/// The Lisp semantics providers and the target families they accept.
fn semantic_families() -> Array[(String, @core_theory.Target)] {
  [
    ("primus-lisp-riscv", @core_theory.Target::riscv()),
    ("primus-lisp-arm", @core_theory.Target::arm_family()),
    ("primus-lisp-powerpc", @core_theory.Target::powerpc_family()),
    ("primus-lisp-x86", @core_theory.Target::i86()),
  ]
}

///|
/// Lifters prepared for concrete targets, indexed by the target name.
let lifter_cache : Map[String, Result[Lifter, String]] = Map([])

///|
fn cached_lifter(
  target : @core_theory.Target,
  dirs : Array[String],
) -> Lifter raise @mc.LiftError {
  let key = target.to_string()
  let r = match lifter_cache.get(key) {
    Some(r) => r
    None => {
      let r : Result[Lifter, String] = try
        load_semantics(target, dirs, strict=false)
      catch {
        e => Err(e.to_string())
      } noraise {
        l => Ok(l)
      }
      lifter_cache[key] = r
      r
    }
  }
  match r {
    Ok(l) => l
    Err(msg) => raise @mc.LiftError::Failure("primus-lisp: \{msg}")
  }
}

///|
/// Creates a lifter provider for all targets of the family, the Lisp
/// program is loaded (and type checked) lazily for each concrete target.
/// Instructions without a Lisp definition raise `Unsupported`, so the
/// provider only fills the gaps of the providers registered before it.
pub fn semantics_provider(
  name : String,
  family : @core_theory.Target,
  dirs : Array[String],
) -> @mc.Provider {
  @mc.Provider::create(name, accepts=ctx => ctx.target().belongs(family), lift=(
    ctx,
    insn,
  ) => {
    let lifter = cached_lifter(ctx.target(), dirs)
    (lifter.provider(name~).lift)(ctx, insn)
  })
}

///|
/// Registers the Lisp semantics providers (for RISC-V, ARM/Thumb/AArch64,
/// PowerPC and x86) in the registry (the global one by default). The
/// providers are appended, so they are tried after the providers that are
/// already registered (e.g., the native lifters). The function is
/// idempotent.
pub fn register_semantics_providers(
  registry? : @mc.Registry = @mc.Registry::global(),
) -> Unit {
  for f in semantic_families() {
    let (name, family) = f
    if registry.find(name) is None {
      registry.register(semantics_provider(name, family, semantic_dirs))
    }
  }
}
