// Port of BAP `plugins/mips/mips.ml` and `mips_main.ml`: the opcode
// registry, the lifting entry points and target registration.

///|
/// Semantics of one opcode: RTL for the instruction in the given context.
type Semantics = (Cpu) -> Array[Rtl] raise @mc.LiftError

///|
priv struct Entry {
  semantics : Semantics
  delay : Int?
}

///|
let semantics_table : Map[String, Entry] = {
  let table : Map[String, Entry] = Map([])
  let groups : Array[(ReadOnlyArray[(String, Semantics)], Int?)] = [
    (arithmetic_semantics, None),
    (branch_semantics, Some(1)),
    (conditional_semantics, None),
    (divide_semantics, None),
    (load_semantics, None),
    (logic_semantics, None),
    (multiply_semantics, None),
    (shift_and_rot_semantics, None),
    (store_semantics, None),
  ]
  for group in groups {
    let (entries, delay) = group
    for entry in entries {
      let (name, semantics) = entry
      table[name] = { semantics, delay, }
    }
  }
  table
}

///|
/// Whether the lifter models the LLVM MC opcode `name`.
pub fn is_supported(name : String) -> Bool {
  semantics_table.contains(name)
}

///|
/// All modeled opcode names, sorted.
pub fn opcodes() -> Array[String] {
  let names = semantics_table.keys().collect()
  names.sort()
  names
}

///|
/// Number of delay slots of the opcode `name` (upstream `delayed_opcodes`,
/// the source of the `mips:delay-slot` knowledge rule): `Some(1)` for the
/// branch and jump group, `None` otherwise.
pub fn delay_slot(name : String) -> Int? {
  match semantics_table.get(name) {
    Some(entry) => entry.delay
    None => None
  }
}

///|
/// Lift one instruction to BIL (upstream `Mips.Std.lift`). The address of
/// the instruction (`insn.addr`) is the current instruction address used by
/// PC-relative semantics. Opcodes that are not modeled lift to an empty
/// program, like upstream.
pub fn lift(
  insn : @mc.Insn,
  arch~ : Arch,
  endian~ : @bitvec.Endian,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match semantics_table.get(insn.name) {
    None => []
    Some(entry) => {
      let cpu = Cpu::new(arch, endian, insn)
      rtl_to_bil((entry.semantics)(cpu))
    }
  }
}

///|
/// Lift and type-check, as the registered BAP target lifters do
/// (`mips_main.ml`): ill-typed BIL is rejected with a `type error` failure.
pub fn lift_checked(
  insn : @mc.Insn,
  arch~ : Arch,
  endian~ : @bitvec.Endian,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let bil = lift(insn, arch~, endian~)
  for stmt in bil {
    if stmt.check_type() is Err(_) {
      raise Failure("type error")
    }
  }
  bil
}

///|
/// 32-bit big-endian lifter (target `mips`).
pub fn lift_mips(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift_checked(insn, arch=Mips32, endian=BigEndian)
}

///|
/// 32-bit little-endian lifter (target `mipsel`).
pub fn lift_mipsel(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift_checked(insn, arch=Mips32, endian=LittleEndian)
}

///|
/// 64-bit big-endian lifter (target `mips64`).
pub fn lift_mips64(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift_checked(insn, arch=Mips64, endian=BigEndian)
}

///|
/// 64-bit little-endian lifter (target `mips64el`).
pub fn lift_mips64el(insn : @mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  lift_checked(insn, arch=Mips64, endian=LittleEndian)
}

///|
/// Target names registered by `register`, as in upstream `mips_main.ml`.
pub let targets : ReadOnlyArray[String] = [
  "mips", "mipsel", "mips64", "mips64el",
]

///|
/// Register the MIPS lifters with the shared `@mc` lifter registry for the
/// targets `mips`, `mipsel`, `mips64` and `mips64el`. Idempotent.
pub fn register() -> Unit {
  @mc.register_lifter("mips", lift_mips)
  @mc.register_lifter("mipsel", lift_mipsel)
  @mc.register_lifter("mips64", lift_mips64)
  @mc.register_lifter("mips64el", lift_mips64el)
}
