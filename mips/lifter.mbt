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
    (delayed_branch_semantics, Some(1)),
    (compact_branch_semantics, None),
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
/// LLVM MC opcode names (as produced by LLVM's disassembler and by the
/// native decoder, see `decode`) of instructions that upstream registers
/// under a different spelling: mostly MIPS32 Release 6 opcodes, whose
/// LLVM definitions carry an `_R6` suffix or upper-case `U`/`PC`
/// suffixes, their MIPS64 `GPR64` variants (`*64`), and `SELNEZ`,
/// registered upstream as `SELNEQ`.
let llvm_aliases : Map[String, String] = {
  "ADDIUPC": "ADDiupc",
  "ALUIPC": "ALUipc",
  "LWUPC": "LWupc",
  "MUL_R6": "MUL",
  "MULU": "MULu",
  "MUHU": "MUHu",
  "MODU": "MODu",
  "DMUL_R6": "DMUL",
  "DMULU": "DMULu",
  "DMUHU": "DMUHu",
  "DDIVU": "DDIVu",
  "DMODU": "DMODu",
  "SELNEZ": "SELNEQ",
  "LSA_R6": "LSA",
  "DLSA_R6": "DLSA",
  "CLO_R6": "CLO",
  "CLZ_R6": "CLZ",
  "LL_R6": "LL",
  "LLD_R6": "LLD",
  "SC_R6": "SC",
  "SCD_R6": "SCD",
  "JALR_HB": "JALR.HB",
  "JALR_HB64": "JALR.HB",
  "JR_HB": "JR",
  "JR_HB64": "JR",
  "JR_HB_R6": "JR",
  "JR_HB64_R6": "JR",
  "SELEQZ64": "SELEQZ",
  "SELNEZ64": "SELNEQ",
  "BEQZC64": "BEQZC",
  "BNEZC64": "BNEZC",
  "JIC64": "JIC",
  "JIALC64": "JIALC",
}

///|
/// The opcode modeled under `name`, or under the upstream spelling of the
/// LLVM name `name` (`llvm_aliases`).
fn find_entry(name : String) -> Entry? {
  match semantics_table.get(name) {
    Some(entry) => Some(entry)
    None =>
      match llvm_aliases.get(name) {
        Some(upstream) => semantics_table.get(upstream)
        None => None
      }
  }
}

///|
/// The LLVM MC names accepted as aliases of modeled opcodes, with the
/// modeled opcode each one denotes, sorted by the LLVM name.
pub fn opcode_aliases() -> Array[(String, String)] {
  let pairs = llvm_aliases.iter().collect()
  pairs.sort_by((a, b) => a.0.compare(b.0))
  pairs
}

///|
/// Whether the lifter models the LLVM MC opcode `name` (either a modeled
/// opcode or one of its `opcode_aliases`).
pub fn is_supported(name : String) -> Bool {
  find_entry(name) is Some(_)
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
  match find_entry(name) {
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
  match find_entry(insn.name) {
    None => []
    Some(entry) => {
      let cpu = Cpu::new(arch, endian, insn)
      rtl_to_bil((entry.semantics)(cpu))
    }
  }
}

///|
/// Lift and type-check, as the registered BAP target lifters do
/// (`mips_main.ml`): ill-typed BIL is rejected with `IllTyped`.
pub fn lift_checked(
  insn : @mc.Insn,
  arch~ : Arch,
  endian~ : @bitvec.Endian,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let bil = lift(insn, arch~, endian~)
  match @types.check_stmt_types(bil) {
    Ok(_) => bil
    Err(err) => raise IllTyped(opcode=insn.name, detail=err.to_string())
  }
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
/// Name of the provider installed by `register`.
pub let provider_name : String = "mips"

///|
/// MIPS encodings accepted by the provider (an unknown encoding is
/// accepted too: `@mc.Context::create` only leaves it unknown when the
/// target has no default).
let mips_encodings : ReadOnlyArray[@core_theory.Language] = [
  @core_theory.Language::llvm_mips32(),
  @core_theory.Language::llvm_mips32le(),
  @core_theory.Language::llvm_mips64(),
  @core_theory.Language::llvm_mips64le(),
]

///|
/// Whether the provider applies to `ctx`: targets of the MIPS family
/// decoded with one of the LLVM MIPS encodings.
pub fn accepts(ctx : @mc.Context) -> Bool {
  ctx.belongs(@core_theory.Target::mips_family()) &&
  (ctx.encoding.is_unknown() || mips_encodings.contains(ctx.encoding))
}

///|
/// The architecture and endianness implied by `ctx`: 64-bit targets use
/// `Mips64`, other `Mips32`; the byte order is the target endianness, and
/// for bi-endian or unknown targets the one implied by the encoding
/// (`*le` encodings are little-endian), big-endian by default.
pub fn mode_of_context(ctx : @mc.Context) -> (Arch, @bitvec.Endian) {
  let arch = if ctx.target.bits() == 64 { Mips64 } else { Mips32 }
  let endian : @bitvec.Endian = match ctx.target.endianness() {
    LittleEndian => LittleEndian
    BigEndian => BigEndian
    _ =>
      if ctx.encoding == @core_theory.Language::llvm_mips32le() ||
        ctx.encoding == @core_theory.Language::llvm_mips64le() {
        LittleEndian
      } else {
        BigEndian
      }
  }
  (arch, endian)
}

///|
/// Lift in a context: like `lift`, but opcodes that are not modeled raise
/// `Unsupported` (instead of lifting to an empty program), and the result
/// records the delay slot of branches (`delay_slot`).
pub fn lift_in_context(
  ctx : @mc.Context,
  insn : @mc.Insn,
) -> @mc.Lifted raise @mc.LiftError {
  guard find_entry(insn.name) is Some(entry) else {
    raise Unsupported(opcode=insn.name, target=ctx.target.to_string())
  }
  let (arch, endian) = mode_of_context(ctx)
  let cpu = Cpu::new(arch, endian, insn)
  let bil = rtl_to_bil((entry.semantics)(cpu))
  @mc.Lifted::create(bil, delay=entry.delay.unwrap_or(0))
}

///|
/// The MIPS lifter provider (see `accepts` and `lift_in_context`).
pub fn provider() -> @mc.Provider {
  @mc.Provider::create(provider_name, accepts~, lift=lift_in_context)
}

///|
/// Target names covered by the provider, as in upstream `mips_main.ml`.
pub let targets : ReadOnlyArray[String] = [
  "mips", "mipsel", "mips64", "mips64el",
]

///|
/// Register the MIPS provider with `registry` (the global `@mc` registry by
/// default). Idempotent: the provider is replaced by name.
pub fn register(registry? : @mc.Registry = @mc.Registry::global()) -> Unit {
  registry.register(provider())
}
