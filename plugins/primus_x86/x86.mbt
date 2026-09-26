///|
/// # The x86 Primus support package (upstream `plugins/primus_x86`)
///
/// Two components for x86 and x86-64 targets:
///
/// - `bap:x86-registers-initializer` initializes to zero the registers
///   that are not described by the target (the descriptor table registers,
///   the segment bases, the vector registers) and the status flags;
/// - `bap:x86-setup-plt`, when the system is initialized, (1) links the
///   entries of the `.got.plt` table that point into the `.plt` section to
///   code that calls the unresolved handler, so that calls through lazily
///   bound PLT stubs are handled as unresolved calls, and (2) after every
///   return from a Lisp stub (`lisp_call_return`) of a function that is not
///   an intrinsic, pops the return address from the stack by adding the
///   address size to the stack pointer (the stubs return without popping).
pub let registers_component : String = "x86-registers-initializer"

///|
/// The name of the PLT setup component.
pub let plt_component : String = "x86-setup-plt"

///|
/// The x86 mode of a target.
pub(all) enum Mode {
  IA32
  AMD64
} derive(Eq, Debug)

///|
/// The x86 mode of the target, if it is an x86 target (upstream
/// `Project.arch` being `x86` or `x86_64`).
pub fn mode_of_target(t : @core_theory.Target) -> Mode? {
  if t.belongs(@core_theory.Target::x86_64()) {
    Some(AMD64)
  } else if t.belongs(@core_theory.Target::x86()) && t.bits() == 32 {
    Some(IA32)
  } else {
    None
  }
}

///|
fn imm(name : String, width : Int) -> @types.Var {
  @types.Var::create(name, Imm(width))
}

///|
/// The status flags (upstream `X86_cpu.flags`).
pub fn flags() -> Array[@types.Var] {
  ["CF", "PF", "AF", "ZF", "SF", "OF", "DF"].map(n => imm(n, 1))
}

///|
/// The registers initialized by `bap:x86-registers-initializer` besides
/// the flags (upstream `InitializeRegisters.registers`).
pub fn registers(mode : Mode) -> Array[@types.Var] {
  let (width, ymms) = match mode {
    IA32 => (32, 8)
    AMD64 => (64, 16)
  }
  [
    imm("GDTR", width),
    imm("LDTR", width),
    imm("FS_BASE", width),
    imm("GS_BASE", width),
    ..Array::makei(ymms, i => imm("YMM\{i}", 256)),
  ]
}

///|
/// The stack pointer of the mode.
pub fn stack_pointer(mode : Mode) -> @types.Var {
  match mode {
    IA32 => imm("ESP", 32)
    AMD64 => imm("RSP", 64)
  }
}

///|
/// Initializes the registers and flags to zero (the
/// `bap:x86-registers-initializer` component body).
pub fn install_registers(m : @primus.Machine) -> Unit {
  guard mode_of_target(m.target()) is Some(mode) else { return }
  let zero = @primus.Generator::static_value(0)
  for reg in [..registers(mode), ..flags()] {
    @primus.Env::add(m, reg, zero)
  }
}

///|
fn intrinsics(prog : @types.Term[@types.Program]) -> Array[String] {
  prog
  .subs()
  .filter(sub => sub.is_intrinsic())
  .map(sub => @types.Sub::name(sub))
}

///|
fn section_memory(
  proj : @primus.Machine,
  name : String,
) -> Array[@memory.Memory] {
  match proj.project().image() {
    None => []
    Some(image) =>
      image
      .sections()
      .filter(s => s.name() == name)
      .filter_map(s => image.memory_of_section(s))
  }
}

///|
/// The words of the `.got.plt` table (upstream `load_table`; as upstream,
/// only the words of the last `.got.plt` memory chunk are kept, most
/// recent first).
fn load_table(m : @primus.Machine) -> Array[@types.Word] {
  let word_size = m.target().bits()
  let mut table = []
  for mem in section_memory(m, ".got.plt") {
    let words = []
    mem.iter(w => words.push(w), word_size~)
    words.rev_in_place()
    table = words
  }
  table
}

///|
fn filter_plt(
  m : @primus.Machine,
  addrs : Array[@types.Word],
) -> Array[@types.Word] {
  let plt = section_memory(m, ".plt")
  addrs.filter(a => {
    let x = a.to_uint64() catch { _ => return false }
    plt.iter().any(mem => mem.contains(x))
  })
}

///|
/// Links the `.got.plt` entries that point into `.plt` to the unresolved
/// handler (upstream `unresolve`).
pub fn unresolve(m : @primus.Machine) -> Unit {
  for addr in filter_plt(m, load_table(m)) {
    @primus.Linker::link(
      m,
      addr~,
      Host(m => @primus.Linker::exec(m, Symbol(@primus.unresolved_handler))),
    )
  }
}

///|
fn correct_sp(
  m : @primus.Machine,
  ignore : Array[String],
  sp : @types.Var,
  addend : Int,
) -> Unit raise {
  guard sp.typ() is Imm(width) else { return }
  let addend = @primus.Value::of_int(m, width~, addend)
  m.observe(@primus.lisp_call_return, call => {
    if !ignore.contains(call.0) {
      let x = @primus.Interpreter::get(m, sp)
      let y = @primus.Interpreter::binop(m, Plus, x, addend)
      @primus.Interpreter::set(m, sp, y)
    }
  })
}

///|
fn setup_plt(m : @primus.Machine) -> Unit raise {
  let ignore = intrinsics(m.program())
  match mode_of_target(m.target()) {
    Some(IA32) => {
      correct_sp(m, ignore, stack_pointer(IA32), 4)
      unresolve(m)
    }
    Some(AMD64) => {
      correct_sp(m, ignore, stack_pointer(AMD64), 8)
      unresolve(m)
    }
    None => ()
  }
}

///|
/// Initializes the PLT setup (the `bap:x86-setup-plt` component body): the
/// setup runs when the system is initialized.
pub fn install_plt(m : @primus.Machine) -> Unit {
  m.observe(@primus.system_init, _ => setup_plt(m))
}

///|
/// Registers both components. Idempotent: returns `false` if they were
/// already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    registers_component,
    m => install_registers(m),
    pkg="bap",
    desc="Intializes all x86/x86-64 registers to zero.",
  ) catch {
    _ => return false
  }
  @primus.Components::register_generic(
    plt_component,
    m => install_plt(m),
    pkg="bap",
    desc="Sets up PLT entries.",
  ) catch {
    _ => ()
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the components and adds them to the legacy main system, as
/// the upstream plugin does when it is loaded. Idempotent.
pub fn enable() -> Unit {
  register() |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install_registers(m))
    @primus.Machine::add_component(m => install_plt(m))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-x86"

///|
/// Declares the `primus-x86` plugin to `bap_main`. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["abi", "x86", "primus"],
    doc="x86 Primus Support package\n\nPerforms the x86 target specific setup. So far it just initializes all flag registers to zero.",
    () => @bap_main.Extension::register(_ => enable()),
  )
}
