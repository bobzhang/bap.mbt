// The `mc` machine-code playground and the `objdump` command (upstream
// `Mc_main`).

///|
/// The kinds of information that `mc` and `objdump` print.
pub(all) enum Show {
  Insn
  Bil
  Bir
  Sema
  Kinds
  Size
  Invalid
  Addr
  Memory
  Knowledge
} derive(Eq, Debug)

///|
/// All kinds of outputs, in the order of their declaration.
pub let all_outputs : Array[Show] = [
  Insn,
  Bil,
  Bir,
  Sema,
  Kinds,
  Size,
  Invalid,
  Addr,
  Memory,
  Knowledge,
]

///|
pub fn Show::name(self : Show) -> String {
  match self {
    Insn => "insn"
    Bil => "bil"
    Bir => "bir"
    Sema => "sema"
    Kinds => "kinds"
    Size => "size"
    Addr => "addr"
    Memory => "memory"
    Knowledge => "knowledge"
    Invalid => "invalid"
  }
}

///|
let enabled : String = "enabled"

///|
/// The requested outputs: the formats for each kind of output (an empty
/// list if the output is not requested).
pub type Outputs = Array[(Show, Array[String])]

///|
fn formats(outputs : Outputs, kind : Show) -> Array[String] {
  for entry in outputs {
    if entry.0 == kind {
      return entry.1
    }
  }
  []
}

///|
fn is_enabled(fmts : Array[String]) -> Bool {
  fmts is [opt] && opt == enabled
}

///|
/// The printers of the instruction, BIL, and IR (the writers of the
/// `Bap.Std.Insn`, `Bap.Std.Bil`, and `Bap.Std.Blk` modules).
fn module_printers(kind : Show) -> (String, Array[String]) {
  match kind {
    Insn => ("Bap.Std.Insn", ["asm", "adt", "pretty", "sexp"])
    Bil => ("Bap.Std.Bil", ["adt", "pretty", "sexp"])
    _ => ("Bap.Std.Blk", ["adt", "pretty"])
  }
}

///|
/// Checks the requested formats (upstream `validate_formats`).
pub fn validate_formats(outputs : Outputs) -> Unit raise McError {
  for entry in outputs {
    let (kind, fmts) = entry
    match kind {
      Insn | Bil | Bir => {
        let (name, known) = module_printers(kind)
        for fmt in fmts {
          if !known.contains(fmt) {
            raise McFail(UnknownFormat(name, fmt, known))
          }
        }
      }
      Sema => ()
      _ =>
        match fmts {
          [] => ()
          [opt] if opt == enabled => ()
          _ => raise McFail(NoFormatsExpected(kind.name()))
        }
    }
  }
}

///|
/// The target of the disassembler (upstream `target`): either a known
/// target with an encoding, or an explicit triple for the backend.
pub(all) enum McTarget {
  Target(@core_theory.Target, @core_theory.Language)
  Triple(
    name~ : String,
    backend~ : String?,
    cpu~ : String?,
    order~ : @bitvec.Endian,
    bits~ : Int32
  )
}

///|
fn McTarget::endian(self : McTarget) -> @bitvec.Endian {
  match self {
    Triple(order~, ..) => order
    Target(t, _) =>
      match t.endianness() {
        LittleEndian => LittleEndian
        _ => BigEndian
      }
  }
}

///|
fn McTarget::bits(self : McTarget) -> Int32 {
  match self {
    Target(t, _) => t.bits()
    Triple(bits~, ..) => bits
  }
}

///|
/// The target for the architecture name, with optional hints on the
/// address size and the byte order (upstream `target_of_arch`).
pub fn target_of_arch(
  arch : String,
  bits? : Int32,
  order? : @bitvec.Endian,
) -> McTarget {
  let normalized = arch.replace_all(old="-", new="_")
  let target = match @core_theory.find_target(arch) {
    Some(t) => t
    None =>
      match @core_theory.find_target(normalized) {
        Some(t) => t
        None => @core_theory.Target::unknown()
      }
  }
  let target = match bits {
    Some(bits) if bits != target.bits() => target.with_bits(bits)
    _ => target
  }
  let target = match order {
    Some(LittleEndian) => target.with_endianness(LittleEndian)
    Some(BigEndian) => target.with_endianness(BigEndian)
    None => target
  }
  Target(target, @mc_lib.default_encoding(target))
}

///|
fn check_invariants(
  xs : Array[(Bool, Array[(Bool, McFailure)])],
) -> Unit raise McError {
  for entry in xs {
    if entry.0 {
      for check in entry.1 {
        if !check.0 {
          raise McFail(check.1)
        }
      }
    }
  }
}

///|
/// Selects the target from the command-line options (upstream
/// `parse_arch`); the default target is `x86-64`.
pub fn parse_arch(
  arch? : String,
  target~ : @core_theory.Target = @core_theory.Target::unknown(),
  encoding~ : @core_theory.Language = @core_theory.Language::unknown(),
  triple? : String,
  cpu? : String,
  backend? : String,
  bits? : Int32,
  order? : @bitvec.Endian,
) -> McTarget raise McError {
  let target_unknown = target.is_unknown()
  check_invariants([
    (
      arch is Some(_),
      [
        (target_unknown, TargetMustBeUnknown),
        (triple is None, TripleMustNotBeSet),
      ],
    ),
    (
      !target_unknown,
      [(arch is None, ArchMustNotBeSet), (triple is None, TripleMustNotBeSet)],
    ),
    (
      triple is Some(_),
      [
        (target_unknown, TargetMustBeUnknown),
        (encoding.is_unknown(), EncodingMustBeUnknown),
        (arch is None, ArchMustNotBeSet),
      ],
    ),
    (target_unknown, [(encoding.is_unknown(), EncodingMustBeUnknown)]),
    (
      triple is None,
      [(cpu is None, CpuMustNotBeSet), (backend is None, BackendMustNotBeSet)],
    ),
    (
      triple is None && arch is None,
      [(bits is None, BitsMustNotBeSet), (order is None, OrderMustNotBeSet)],
    ),
  ])
  match (arch, triple) {
    (None, None) =>
      if target_unknown {
        target_of_arch("x86-64")
      } else if encoding.is_unknown() {
        Target(target, @mc_lib.default_encoding(target))
      } else {
        Target(target, encoding)
      }
    (Some(arch), None) => target_of_arch(arch, bits?, order?)
    (None, Some(name)) =>
      Triple(
        name~,
        backend~,
        cpu~,
        bits=bits.unwrap_or(32),
        order=order.unwrap_or(BigEndian),
      )
    (Some(_), Some(_)) => raise McFail(ArchMustNotBeSet)
  }
}

///|
/// Parses the base address (`Bitvec.of_string`: decimal, or hexadecimal,
/// octal, and binary with the `0x`, `0o`, and `0b` prefixes).
pub fn parse_base(base : String) -> UInt64 raise McError {
  let (digits, radix) = if base.has_prefix("0x") || base.has_prefix("0X") {
    (base[2:].to_owned(), 16)
  } else if base.has_prefix("0o") {
    (base[2:].to_owned(), 8)
  } else if base.has_prefix("0b") {
    (base[2:].to_owned(), 2)
  } else {
    (base, 10)
  }
  if digits == "" {
    raise McFail(InvalidBase("Bitvec.of_string: \{base}"))
  }
  let mut v = 0UL
  for c in digits {
    let d = match c {
      '0'..<='9' => c.to_int() - '0'.to_int()
      'a'..<='f' => c.to_int() - 'a'.to_int() + 10
      'A'..<='F' => c.to_int() - 'A'.to_int() + 10
      '_' => continue
      _ => raise McFail(InvalidBase("Bitvec.of_string: \{base}"))
    }
    if d >= radix {
      raise McFail(InvalidBase("Bitvec.of_string: \{base}"))
    }
    v = v * radix.to_uint64() + d.to_uint64()
  }
  v
}

///|
/// Creates the Basic disassembler for the target (upstream
/// `create_disassembler`).
pub fn create_disassembler(
  target : McTarget,
) -> @project.ProjectDisassemblyBasic raise McError {
  let result = match target {
    Target(t, encoding) => @project.ProjectDisassemblyBasic::lookup(t, encoding)
    Triple(name~, backend~, cpu~, ..) =>
      @project.ProjectDisassemblyBasic::create(name, backend?, cpu?)
  }
  match result {
    Ok(dis) => dis
    Err(err) => raise McFail(DisassemblerFailed(err))
  }
}

///|
fn kind_name(kind : @project.ProjectInstructionKind) -> String {
  match kind {
    ProjectConditionalBranch => "Conditional_branch"
    ProjectUnconditionalBranch => "Unconditional_branch"
    ProjectIndirectBranch => "Indirect_branch"
    ProjectReturn => "Return"
    ProjectCall => "Call"
    ProjectBarrier => "Barrier"
    ProjectTerminator => "Terminator"
    ProjectMayAffectControlFlow => "May_affect_control_flow"
    ProjectMayLoad => "May_load"
    ProjectMayStore => "May_store"
  }
}

///|
/// Lifts the instruction; an instruction without semantics has the empty
/// BIL (upstream `lift`).
fn lift(
  target : McTarget,
  insn : @project.ProjectDisassemblyInstruction,
) -> Array[@types.Stmt] {
  match target {
    Triple(..) => []
    Target(t, _) =>
      match insn.lift(target=t) {
        Ok(lifted) => lifted.bil()
        Err(_) => []
      }
  }
}

///|
fn render(pp : (@text_tags.Formatter) -> Unit) -> String {
  let fmt = @text_tags.Formatter::new()
  pp(fmt)
  fmt.flush_str()
}

///|
fn insn_text(
  insn : @project.ProjectDisassemblyInstruction,
  format : String,
) -> String {
  match format {
    "pretty" => {
      let name = insn.name()
      let ops = insn
        .operands()
        .map(op => {
          match op {
            ProjectRegisterOperand(_, name) => name
            ProjectImmediateOperand(v) =>
              "0x" + v.reinterpret_as_uint64().to_string(radix=16)
            ProjectFloatingOperand(v) => v.to_string()
          }
        })
      "\{name}(\{ops.join(",")})"
    }
    fmt => @print.insn_to_string(insn, fmt)
  }
}

///|
fn bil_text(bil : Array[@types.Stmt], format : String) -> String {
  match format {
    "adt" => @print.bil_to_adt(bil)
    "sexp" => @print.bil_to_sexp(bil)
    _ => @print.bil_to_string(bil)
  }
}

///|
fn blk_text(blk : @types.Term[@types.Blk], format : String) -> String {
  match format {
    "adt" => render(fmt => @print.adt_blk(fmt, blk))
    _ => render(fmt => @print.pp_blk(fmt, blk))
  }
}

///|
fn addr_text(target : McTarget, addr : UInt64) -> String {
  let width = target.bits()
  let width = if width <= 0 { 64 } else { width }
  @types.Word::of_uint64(width~, addr).to_string() catch {
    _ => "0x" + addr.to_string(radix=16)
  }
}

///|
/// The semantics of the instruction as a list of slots (a stand-in for
/// the knowledge value printed by upstream `print_sema`).
fn sema_text(
  insn : @project.ProjectDisassemblyInstruction,
  bil : Array[@types.Stmt],
  slots : Array[String],
) -> String {
  let all = [
    ("bap:insn", "(\{insn_text(insn, "pretty")})"),
    ("bap:asm", "\"\{insn.assembly()}\""),
    ("bap:bil", "\"\{@print.bil_to_string(bil)}\""),
    (
      "bap:insn-properties",
      "(\{insn.kinds().map(kind_name).map(s => ":" + s.to_lower()).join(" ")})",
    ),
  ]
  let selected = match slots {
    [] | ["all-slots"] => all
    slots =>
      all.filter(slot => {
        slots.contains(slot.0) ||
        slots.contains(slot.0.replace(old="bap:", new=""))
      })
  }
  "(" + selected.map(slot => "(\{slot.0} \{slot.1})").join("\n ") + ")"
}

///|
/// Prints the decoded instruction in the requested formats (upstream
/// `print`).
fn print_insn(
  target : McTarget,
  mem : @memory.Memory,
  insn : @project.ProjectDisassemblyInstruction,
  outputs : Outputs,
  out : (String) -> Unit,
) -> Unit {
  let bil = lift(target, insn)
  for _ in formats(outputs, Memory) {
    out(@print.memory_to_string(mem) + "\n")
  }
  for _ in formats(outputs, Addr) {
    out(addr_text(target, mem.min_addr()) + ":\n")
  }
  for _ in formats(outputs, Size) {
    out("0x" + mem.length().to_string(radix=16) + "\n")
  }
  for fmt in formats(outputs, Insn) {
    out(insn_text(insn, fmt) + "\n")
  }
  for fmt in formats(outputs, Bil) {
    out(bil_text(bil, fmt) + "\n")
  }
  let bir = formats(outputs, Bir)
  if !bir.is_empty() {
    let blks = blks_of_bil(bil)
    for fmt in bir {
      for blk in blks {
        out(blk_text(blk, fmt) + "\n")
      }
    }
  }
  let sema = formats(outputs, Sema)
  if !sema.is_empty() {
    out(sema_text(insn, bil, sema) + "\n")
  }
  for _ in formats(outputs, Kinds) {
    for kind in insn.kinds() {
      out(kind_name(kind) + "\n")
    }
  }
}

///|
/// Disassembles the memory (upstream `run`). Returns the number of the
/// disassembled bytes.
pub fn run(
  only_one~ : Bool = false,
  stop_on_error~ : Bool = false,
  dis : @project.ProjectDisassemblyBasic,
  target : McTarget,
  mem : @memory.Memory,
  outputs : Outputs,
  out~ : (String) -> Unit,
) -> Int32 raise McError {
  let show_invalid = is_enabled(formats(outputs, Invalid))
  let total = mem.length()
  let start = mem.min_addr()
  let mut pos = 0
  let mut bytes = 0
  while pos < total {
    let rest = match mem.view(from=start + pos.to_uint64()) {
      Ok(rest) => rest
      Err(err) => raise McFail(CreateMem(err))
    }
    let decoded = match dis.insn_of_mem(rest) {
      Ok(result) =>
        match result.instruction() {
          // the Basic decoder represents undecodable bytes as `.byte`
          Some(insn) if insn.memory().length() > 0 && insn.name() != ".byte" =>
            Some(insn)
          _ => None
        }
      Err(_) => None
    }
    match decoded {
      Some(insn) => {
        print_insn(target, insn.memory(), insn, outputs, out)
        let len = insn.memory().length()
        bytes += len
        pos += len
        if only_one {
          break
        }
      }
      None => {
        if show_invalid {
          out("<invalid>\n")
        }
        if stop_on_error {
          raise McFail(BadInsn(mem, pos, pos + 1))
        }
        pos += 1
      }
    }
  }
  bytes
}

///|
/// The `mc` command (upstream `mc`): disassembles the bytes given on the
/// command line (or read by `read_line`).
pub fn mc(
  arch? : String,
  target~ : @core_theory.Target = @core_theory.Target::unknown(),
  encoding~ : @core_theory.Language = @core_theory.Language::unknown(),
  triple? : String,
  cpu? : String,
  backend? : String,
  bits? : Int32,
  order? : @bitvec.Endian,
  base~ : String = "0",
  only_one~ : Bool = false,
  stop_on_error~ : Bool = false,
  input~ : Array[String] = [],
  outputs~ : Outputs = [],
  read_line~ : () -> String? = () => None,
  out~ : (String) -> Unit,
) -> Unit raise McError {
  validate_formats(outputs)
  let target = parse_arch(
    arch?,
    target~,
    encoding~,
    triple?,
    cpu?,
    backend?,
    bits?,
    order?,
  )
  let data = read_input(input, read_line~)
  let base = parse_base(base)
  let mem = @memory.Memory::from_bytes(endian=target.endian(), start=base, data)
  let dis = create_disassembler(target)
  let bytes = run(only_one~, stop_on_error~, dis, target, mem, outputs, out~)
  dis.close()
  match data.length() - bytes {
    0 => ()
    _ if only_one => ()
    n => raise McFail(TrailingData(n))
  }
}

///|
/// The `objdump` command (upstream `objdump`): disassembles the code
/// segments of the binary with the linear sweep.
pub fn objdump(
  loader~ : String = "llvm",
  stop_on_error~ : Bool = false,
  file : String,
  outputs~ : Outputs = [],
  out~ : (String) -> Unit,
) -> Unit raise McError {
  validate_formats(outputs)
  let data = match (@bap_main.file_system().read_file)(file) {
    Some(data) => data
    None => raise McFail(LoaderFailed("unable to read the file \{file}"))
  }
  let loaded = if loader == "llvm" {
    match @image.Image::of_bytes_for_filename(data, filename=file) {
      Ok(r) => Ok(r)
      Err(_) => @image.Image::of_bytes(data, backend="llvm")
    }
  } else {
    @image.Image::of_bytes(data, backend=loader)
  }
  let image = match loaded {
    Ok((image, _)) => image
    Err(err) => raise McFail(LoaderFailed(err))
  }
  let t = image.arch()
  let target = Target(t, @mc_lib.default_encoding(t))
  let dis = create_disassembler(target)
  for segment in image.segments() {
    if segment.is_executable() {
      let mem = image.memory_of_segment(segment)
      run(stop_on_error~, dis, target, mem, outputs, out~) |> ignore
    }
  }
}

///|
pub extend Show with Eq::{equal, not_equal}

///|
pub extend Show with Debug::{to_repr}
