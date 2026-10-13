///|
pub fn register_builtin_services() -> Result[Unit, String] {
  register_builtin_lifters()
  match register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_branchers() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_reconstructors() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_ir_transform_passes() {
    Ok(_) => Ok(())
    Err(reason) => Err(reason)
  }
}

///|
let builtin_lifters_registered : Ref[Bool] = Ref(false)

///|
/// Register the built-in architecture lifters (providers) with `registry`,
/// in a deterministic order: `thumb` before `arm` (so that Thumb-1 opcodes
/// are lifted by the Thumb lifter and Thumb-2 ones fall through to the ARM
/// lifter), then `mips`, `powerpc` and `systemz`.
///
/// Registration replaces providers by name, so it is idempotent. For the
/// global registry (the default) it happens only once per process, so that
/// providers registered later under the same names are not overridden.
pub fn register_builtin_lifters(
  registry~ : @mc.Registry = @mc.Registry::global(),
) -> Unit {
  let global = physical_equal(registry, @mc.Registry::global())
  if global && builtin_lifters_registered.val {
    return
  }
  @thumb.register(registry~)
  @arm.register(registry~)
  @mips.register(registry~)
  @powerpc.register(registry~)
  @systemz.register(registry~)
  if global {
    builtin_lifters_registered.val = true
  }
}
