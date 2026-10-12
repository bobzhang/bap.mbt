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
  paths : Array[String],
) -> Lifter raise @mc.LiftError {
  let key = target.to_string() +
    "|" +
    paths.join("|") +
    "|" +
    semantics_context.val.map(c => c.0 + "=" + c.1.join(",")).join(";")
  let r = match lifter_cache.get(key) {
    Some(r) => r
    None => {
      let r : Result[Lifter, String] = try
        load_semantics(target, dirs, paths~, strict=false)
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
  paths~ : Array[String] = [],
) -> @mc.Provider {
  @mc.Provider::create(name, accepts=ctx => ctx.target().belongs(family), lift=(
    ctx,
    insn,
  ) => {
    let target = ctx.target()
    let lifter = cached_lifter(target, dirs, paths)
    let lifted = (lifter.provider(name~).lift)(ctx, insn)
    // the x86 semantics write sub-registers (`AL`, `XMM0`, ...); resolve
    // them onto the full registers like upstream's x86 lifters (32-bit
    // writes zero-extend in 64-bit mode), instead of relying on
    // `Core::desugar`, which merges them
    if target.belongs(@core_theory.Target::i86()) &&
      (target.bits() == 32 || target.bits() == 64) {
      @mc.Lifted::create(
        @mc.resolve_x86_subregisters(lifted.bil(), bits=target.bits()),
        delay=lifted.delay(),
        dest_encoding?=lifted.dest_encoding,
      )
    } else if target.belongs(@core_theory.Target::arm_family()) &&
      target.bits() == 64 {
      // the AArch64 semantics name registers by their aliases (`W0`, `LR`,
      // `FP`, ...); resolve them onto `X0`..`X30` and `SP`
      @mc.Lifted::create(
        @mc.resolve_aarch64_registers(lifted.bil()),
        delay=lifted.delay(),
        dest_encoding?=lifted.dest_encoding,
      )
    } else {
      lifted
    }
  })
}

///|
/// Registers the Lisp semantics providers (for RISC-V, ARM/Thumb/AArch64,
/// PowerPC and x86) in the registry. All `*.lisp` files of the user
/// folders `paths` (native backend only) are loaded too, before the
/// embedded definitions, so they may override them (the global one by default). The
/// providers are appended, so they are tried after the providers that are
/// already registered (e.g., the native lifters). The function is
/// idempotent.
pub fn register_semantics_providers(
  registry~ : @mc.Registry = @mc.Registry::global(),
  paths~ : Array[String] = [],
) -> Unit {
  for f in semantic_families() {
    let (name, family) = f
    if registry.find(name) is None {
      registry.register(semantics_provider(name, family, semantic_dirs, paths~))
    }
  }
}
