///|
/// # The PowerPC Primus support package (upstream `plugins/primus_powerpc`)
///
/// The `bap:powerpc-init` component initializes to zero the `CTR` register
/// and the flags (`SO`, `CA`, `OV`, `CR0LT`, `CR0GT`, `CR0EQ`, `CA32`,
/// `OV32`) of 32-bit PowerPC targets (upstream `Project.arch = ppc`).
pub let component_name : String = "powerpc-init"

///|
/// The registers initialized by the component and their widths.
pub let registers : Array[(String, Int)] = [
  ("CTR", 32),
  ("SO", 1),
  ("CA", 1),
  ("OV", 1),
  ("CR0LT", 1),
  ("CR0GT", 1),
  ("CR0EQ", 1),
  ("CA32", 1),
  ("OV32", 1),
]

///|
/// Whether the target is a 32-bit PowerPC (upstream `ppc`, the 32-bit
/// big-endian PowerPC).
pub fn is_ppc(t : @core_theory.Target) -> Bool {
  t.belongs(@core_theory.Target::powerpc_family()) &&
  t.bits() == 32 &&
  t.endianness() == @core_theory.Endianness::eb()
}

///|
/// Initializes the registers (the `bap:powerpc-init` component body).
pub fn install(m : @primus.Machine) -> Unit {
  guard is_ppc(m.target()) else { return }
  let zero = @primus.Generator::static_value(0)
  for reg in registers {
    let (name, width) = reg
    @primus.Env::add(m, @types.Var::create(name, Imm(width)), zero)
  }
}

///|
/// Registers the `bap:powerpc-init` component. Idempotent: returns `false`
/// if it was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Initializes PPC registers.",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the component and adds it to the legacy main system, as the
/// upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  register() |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-powerpc"

///|
/// Declares the `primus-powerpc` plugin to `bap_main`. Does nothing if
/// already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "powerpc", "ppc"],
    doc="provides PPC Primus support package\n\nPerforms the PowerPC target specific setup. So far it just initializes all flags and CTR register to zero.",
    () => @bap_main.Extension::register(_ => enable()),
  )
}
