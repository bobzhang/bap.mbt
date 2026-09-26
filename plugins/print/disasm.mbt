// Symbol table and disassembly printers (upstream `print_symbols`,
// `print_disasm`, `pp_insn`, and `pp_bil`).

///|
/// What to print for each symbol (upstream `--print-symbol-format`).
pub(all) enum SymbolFormat {
  WithName
  WithAddr
  WithSize
} derive(Eq, Debug)

///|
pub extend SymbolFormat with Eq::{not_equal, equal}

///|
pub extend SymbolFormat with Debug::{to_repr}

///|
/// Parses a symbol format name (`name`, `addr`, or `size`).
pub fn SymbolFormat::parse(s : String) -> SymbolFormat? {
  match s {
    "name" => Some(WithName)
    "addr" => Some(WithAddr)
    "size" => Some(WithSize)
    _ => None
  }
}

///|
/// Resolves a demangler by name (upstream `create_demangler`); no name
/// means the identity.
pub fn create_demangler(name : String?) -> Result[(String) -> String, String] {
  match name {
    None => Ok(s => s)
    Some(name) =>
      match @demangle.Demanglers::lookup(name) {
        Some(d) => Ok(s => d.run(s))
        None => {
          let names = @demangle.Demanglers::available().map(d => d.name())
          Err(
            "Unknown demangler \{name}. Available demanglers are: \{names.join(", ")}",
          )
        }
      }
  }
}

///|
/// Prints an address like `Addr.pp_generic ~prefix:`none ~case:`lower`.
fn addr_lower(addr : UInt64) -> String {
  addr.to_string(radix=16)
}

///|
fn function_size(f : @project.ProjectDisassemblyFunction) -> Int {
  f.span().to_sequence().fold(init=0, (acc, entry) => acc + entry.0.length())
}

///|
/// Prints the symbol table (upstream `print_symbols`).
pub fn pp_symbols(
  fmt : @text_tags.Formatter,
  project : @project.Project,
  patterns? : Array[Pattern] = [],
  demangle? : (String) -> String = s => s,
  formats? : Array[SymbolFormat] = [WithName],
  symtab? : @project.ProjectDisassemblySymtab,
) -> Unit {
  let symtab = match symtab {
    Some(s) => s
    None => project.disassembly_symtab()
  }
  for f in symtab.to_sequence() {
    if !matches(patterns, project, Some(f.addr())) {
      continue
    }
    for format in formats {
      match format {
        WithName => fmt.print_string(demangle(f.name()) + " ")
        WithAddr => fmt.print_string(addr_lower(f.addr()) + " ")
        WithSize => {
          let size = function_size(f).to_string()
          let padded = if size.length() < 2 { " " + size } else { size }
          fmt.print_string(padded + " ")
        }
      }
    }
    fmt.print_format("@\n")
  }
}

// Instruction printers

///|
/// Prints a memory chunk like upstream `Memory.pp`: a short
/// `addr: bb bb ` listing for chunks under 16 bytes and a hexdump
/// otherwise.
pub fn memory_to_string(mem : @memory.Memory) -> String {
  let bytes = mem.to_bytes()
  let buf = StringBuilder()
  if bytes.length() < 16 {
    buf.write_string(addr_lower(mem.min_addr()) + ": ")
    for b in bytes {
      let hex = b.to_int().to_string(radix=16)
      buf.write_string(if hex.length() < 2 { "0" + hex } else { hex })
      buf.write_char(' ')
    }
  } else {
    let chars : Array[Byte] = []
    let print_chars = (off : Int) => {
      if !chars.is_empty() {
        buf.write_string(String::make(3 * off, ' ') + "|")
        for c in chars {
          let code = c.to_int()
          buf.write_char(
            if code >= 0x20 && code < 0x7f {
              code.unsafe_to_char()
            } else {
              '.'
            },
          )
        }
        buf.write_string(String::make(off, ' ') + "|\n")
      }
    }
    for i, b in bytes {
      if chars.is_empty() || chars.length() == 16 {
        print_chars(0)
        chars.clear()
        let addr = (mem.min_addr() + i.to_uint64())
          .to_string(radix=16)
          .to_upper()
        buf.write_string(
          (if addr.length() < 8 {
            String::make(8 - addr.length(), '0')
          } else {
            ""
          }) +
          addr +
          "  ",
        )
      }
      let hex = b.to_int().to_string(radix=16).to_upper()
      buf.write_string((if hex.length() < 2 { "0" + hex } else { hex }) + " ")
      chars.push(b)
    }
    print_chars(16 - chars.length())
  }
  buf.to_string()
}

///|
fn imm_to_string(x : Int64) -> String {
  if x < 0L {
    "-0x" + (-x).reinterpret_as_uint64().to_string(radix=16)
  } else {
    "0x" + x.reinterpret_as_uint64().to_string(radix=16)
  }
}

///|
fn operand_to_string(op : @project.ProjectInstructionOperand) -> String {
  match op {
    ProjectRegisterOperand(_, name) => name
    ProjectImmediateOperand(x) => imm_to_string(x)
    ProjectFloatingOperand(x) => x.to_string()
  }
}

///|
fn operand_to_adt(op : @project.ProjectInstructionOperand) -> String {
  match op {
    ProjectRegisterOperand(_, name) => "Reg(\"\{name}\")"
    ProjectImmediateOperand(x) =>
      "Imm(0x\{x.reinterpret_as_uint64().to_string(radix=16)})"
    ProjectFloatingOperand(x) => "Fmm(\{x.to_string()})"
  }
}

///|
fn capitalize(s : String) -> String {
  match s.get_char(0) {
    Some(c) if c >= 'a' && c <= 'z' =>
      (c.to_int() - 32).unsafe_to_char().to_string() +
      s.unsafe_substring(start=1, end=s.length())
    _ => s
  }
}

///|
fn insn_props(insn : @project.ProjectDisassemblyInstruction) -> String {
  let props = []
  if insn.has_kind(ProjectConditionalBranch) ||
    insn.has_kind(ProjectUnconditionalBranch) ||
    insn.has_kind(ProjectIndirectBranch) {
    props.push(":jump")
  }
  if insn.has_kind(ProjectConditionalBranch) {
    props.push(":cond")
  }
  if insn.has_kind(ProjectIndirectBranch) {
    props.push(":indirect")
  }
  if insn.has_kind(ProjectCall) {
    props.push(":call")
  }
  if insn.has_kind(ProjectReturn) {
    props.push(":return")
  }
  if insn.has_kind(ProjectBarrier) {
    props.push(":barrier")
  }
  if insn.has_kind(ProjectMayAffectControlFlow) {
    props.push(":affect-control-flow")
  }
  if insn.has_kind(ProjectMayLoad) {
    props.push(":load")
  }
  if insn.has_kind(ProjectMayStore) {
    props.push(":store")
  }
  props.join(", ")
}

///|
/// Renders an instruction in one of the upstream instruction formats:
/// `asm`, `pretty` (the decoded form `NAME(op,...)`), `adt`, or `sexp`.
pub fn insn_to_string(
  insn : @project.ProjectDisassemblyInstruction,
  format : String,
) -> String {
  let name = insn.name()
  let ops = insn.operands()
  match format {
    "asm" => insn.assembly()
    "adt" =>
      if name == "" {
        "Undefined()"
      } else {
        "\{capitalize(name)}(\{ops.map(operand_to_adt).join(", ")}, Props(\{insn_props(insn)}))"
      }
    "sexp" => {
      let ops = ops.map(operand_to_string).map(sexp_atom)
      "(\{sexp_atom(name)} (\{ops.join(" ")}))"
    }
    _ =>
      if name == "" {
        name
      } else {
        "\{name}(\{ops.map(operand_to_string).join(",")})"
      }
  }
}

///|
fn insn_bil(
  insn : @project.ProjectDisassemblyInstruction,
) -> Array[@types.Stmt] {
  match insn.lift_basic_bil() {
    Ok(bil) => bil
    Err(_) => []
  }
}

///|
/// The destination of the first direct jump of an instruction (upstream
/// `jmp_dst`).
fn jmp_dst(bil : ArrayView[@types.Stmt]) -> @types.Word? {
  for stmt in bil {
    match stmt {
      Jmp(Int(dst)) => return Some(dst)
      If(yes~, no~, ..) =>
        match jmp_dst(yes) {
          Some(dst) => return Some(dst)
          None =>
            match jmp_dst(no) {
              Some(dst) => return Some(dst)
              None => ()
            }
        }
      _ => ()
    }
  }
  None
}

///|
/// The tab stop used by the disassembly listing (upstream `setup_tabs`).
let disasm_tab_stop = 50

///|
/// Emulates a `pp_print_tab` in a tabulation box with a single tab stop.
fn tab_to(line : String, stop : Int) -> String {
  if line.length() <= stop {
    line + String::make(stop - line.length(), ' ')
  } else {
    line + "\n" + String::make(stop, ' ')
  }
}

///|
/// An instruction printer used by the disassembly listing. It receives
/// the symbol table, the enclosing block, the instruction memory, and the
/// instruction.
pub type InsnPrinter = (
  @text_tags.Formatter,
  @project.ProjectDisassemblySymtab,
  @project.ProjectDisassemblyBlock,
  @memory.Memory,
  @project.ProjectDisassemblyInstruction,
) -> Unit

///|
/// Prints an instruction as `<bytes> <tab> <insn> [# <dst> <callee>]`
/// (upstream `pp_insn`).
pub fn insn_printer(format : String) -> InsnPrinter {
  (fmt, symtab, blk, mem, insn) => {
    let line = tab_to(memory_to_string(mem), disasm_tab_stop) +
      insn_to_string(insn, format)
    fmt.print_string(line)
    if blk.terminator().addr() == insn.addr() {
      let dst = jmp_dst(insn_bil(insn))
      match (dst, symtab.callee(blk.addr())) {
        (Some(dst), Some(name)) =>
          fmt.print_string(" # \{dst.string_of_value()} <\{name}>")
        (Some(dst), None) => fmt.print_string(" # \{dst.string_of_value()}")
        (None, Some(name)) => fmt.print_string(" # <\{name}>")
        (None, None) => ()
      }
    }
    fmt.print_format("@\n")
  }
}

///|
/// Prints an instruction with its BIL code in the `pretty`, `adt`, or
/// `sexp` format (upstream `pp_bil`).
pub fn bil_printer(format : String) -> InsnPrinter {
  (fmt, _, _, mem, insn) => {
    fmt.print_string("\{addr_lower(mem.min_addr())}: \{insn.assembly()}")
    fmt.print_format("@\n")
    let bil = insn_bil(insn)
    match format {
      "adt" => fmt.print_string(bil_to_adt(bil))
      "sexp" => fmt.print_string(bil_to_sexp(bil))
      _ => pp_bil(fmt, bil)
    }
    fmt.print_format("@\n")
  }
}

///|
/// The memory regions that contain code.
fn code_regions(project : @project.Project) -> Array[@memory.Memory] {
  match project.image() {
    Some(image) =>
      image
      .segments()
      .filter(s => s.is_executable())
      .map(s => image.memory_of_segment(s))
    None => project.memory().to_sequence().map(entry => entry.0)
  }
}

///|
fn section_name(project : @project.Project, start : UInt64) -> String {
  for s in project_sections(project) {
    if s.1.min_addr() == start {
      return s.0
    }
  }
  let hex = start.to_string(radix=16).to_upper()
  ".section@" + (if start >= 10UL { "0x" + hex } else { hex })
}

///|
/// Prints the disassembly of every code region, grouped by the functions
/// that intersect it (upstream `print_disasm`).
pub fn pp_disasm(
  fmt : @text_tags.Formatter,
  project : @project.Project,
  pp_insn : InsnPrinter,
  patterns? : Array[Pattern] = [],
  symtab? : @project.ProjectDisassemblySymtab,
) -> Unit {
  let symtab = match symtab {
    Some(s) => s
    None => project.disassembly_symtab()
  }
  for mem in code_regions(project) {
    let sec = section_name(project, mem.min_addr())
    let fns = symtab
      .intersecting(mem)
      .filter(f => matches(patterns, project, Some(f.addr())))
    if fns.is_empty() {
      continue
    }
    fmt.print_format("@\n")
    fmt.print_string("Disassembly of section \{sec}")
    fmt.print_format("@\n")
    let fns = fns.copy()
    fns.sort_by((a, b) => a.addr().compare(b.addr()))
    for f in fns {
      fmt.print_format("@\n")
      fmt.print_string("\{addr_lower(f.addr())}: <\{f.name()}>")
      fmt.print_format("@\n")
      let blocks = f.blocks().copy()
      blocks.sort_by((a, b) => a.compare(b))
      for blk in blocks {
        fmt.print_string("\{addr_lower(blk.memory().min_addr())}:")
        fmt.print_format("@\n")
        for insn in blk.insns() {
          pp_insn(fmt, symtab, blk, insn.0, insn.1)
        }
      }
    }
  }
}
