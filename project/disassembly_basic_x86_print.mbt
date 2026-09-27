// AT&T assembly printing of the instructions decoded by the LLVM-compatible
// x86 decoder, reproducing LLVM 22's X86ATTInstPrinter as normalised by
// `llvm-mc -disassemble` (leading blanks removed, tabs turned into
// spaces). The per-opcode templates of `disassembly_basic_x86_tables.mbt`
// were inferred from LLVM's printer output: literal text with the
// placeholders `{rN}` (register operand N), `{iN}` (immediate), `{uN}`
// (immediate printed as an unsigned byte), `{pN}` (PC-relative immediate),
// `{mN}` (memory reference of five operands starting at N), `{oN}`
// (absolute memory offset), `{sN}`/`{dN}` (string source/destination
// index), `{cN}` (condition code), optionally preceded by `*`.

///|
let x86_llvm_condition_codes : Array[String] = [
  "o", "no", "b", "ae", "e", "ne", "be", "a", "s", "ns", "p", "np", "l", "ge", "le",
  "g",
]

///|
let x86_llvm_compare_predicates : Array[String] = [
  "eq", "lt", "le", "unord", "neq", "nlt", "nle", "ord", "eq_uq", "nge", "ngt", "false",
  "neq_oq", "ge", "gt", "true", "eq_os", "lt_oq", "le_oq", "unord_s", "neq_us", "nlt_uq",
  "nle_uq", "ord_s", "eq_us", "nge_uq", "ngt_uq", "false_os", "neq_os", "ge_oq",
  "gt_oq", "true_us",
]

///|
let x86_llvm_vpcom_predicates : Array[String] = [
  "lt", "le", "gt", "ge", "eq", "neq", "false", "true",
]

///|
/// The register name of an operand ("" for none).
fn x86_llvm_operand_register(operand : ProjectInstructionOperand?) -> String {
  match operand {
    Some(ProjectRegisterOperand(_, name)) if name != "Nil" => name
    _ => ""
  }
}

///|
fn x86_llvm_operand_immediate(operand : ProjectInstructionOperand?) -> Int64 {
  match operand {
    Some(ProjectImmediateOperand(value)) => value
    _ => 0L
  }
}

///|
/// The AT&T name of a register: lower case, `st(i)` for the x87 stack.
fn x86_llvm_register_asm(name : String) -> String {
  if name.length() == 3 && name.has_prefix("ST") {
    "st(" + name.view(start_offset=2).to_owned() + ")"
  } else {
    name.to_lower()
  }
}

///|
fn x86_llvm_render_operand(
  kind : Char,
  index : Int,
  operands : Array[ProjectInstructionOperand],
) -> String {
  let register = (k : Int) => x86_llvm_operand_register(operands.get(k))
  let immediate = (k : Int) => x86_llvm_operand_immediate(operands.get(k))
  let segment_prefix = (name : String) => {
    if name == "" {
      ""
    } else {
      "%" + name.to_lower() + ":"
    }
  }
  match kind {
    'r' => "%" + x86_llvm_register_asm(register(index))
    'i' => "$" + immediate(index).to_string()
    'u' => "$" + (immediate(index) & 0xFFL).to_string()
    'p' => immediate(index).to_string()
    'm' => {
      let base = register(index)
      let scale = immediate(index + 1)
      let index_reg = register(index + 2)
      let disp = immediate(index + 3)
      let text = StringBuilder()
      text.write_string(segment_prefix(register(index + 4)))
      if disp != 0L || (base == "" && index_reg == "") {
        text.write_string(disp.to_string())
      }
      if base != "" || index_reg != "" {
        text.write_char('(')
        if base != "" {
          text.write_string("%" + base.to_lower())
        }
        if index_reg != "" {
          text.write_string(",%" + index_reg.to_lower())
          if scale != 1L {
            text.write_string("," + scale.to_string())
          }
        }
        text.write_char(')')
      }
      text.to_string()
    }
    'o' => segment_prefix(register(index + 1)) + immediate(index).to_string()
    's' =>
      segment_prefix(register(index + 1)) +
      "(%" +
      register(index).to_lower() +
      ")"
    'd' => "%es:(%" + register(index).to_lower() + ")"
    'c' => {
      let cc = immediate(index).to_int()
      if cc >= 0 && cc < 16 {
        x86_llvm_condition_codes[cc]
      } else {
        ""
      }
    }
    _ => ""
  }
}

///|
/// Expands the placeholders of a template.
fn x86_llvm_expand_template(
  template : String,
  operands : Array[ProjectInstructionOperand],
) -> String {
  let out = StringBuilder()
  let n = template.length()
  for i = 0; i < n; {
    let c = template[i]
    if c == '{' && i + 2 < n {
      let kind = template[i + 1].to_int().unsafe_to_char()
      let mut j = i + 2
      let mut index = 0
      while j < n && template[j] >= '0' && template[j] <= '9' {
        index = index * 10 + (template[j].to_int() - '0'.to_int())
        j += 1
      }
      if j < n && template[j] == '}' && j > i + 2 {
        out.write_string(x86_llvm_render_operand(kind, index, operands))
        continue j + 1
      }
    }
    out.write_char(c.to_int().unsafe_to_char())
    continue i + 1
  }
  out.to_string()
}

///|
/// The vector compare families whose predicate immediate LLVM prints as
/// part of the mnemonic (`printVecCompareInstr`): "cmp", "vcmp", "vpcom".
fn x86_llvm_vector_compare_family(name : String) -> String {
  if name.has_prefix("VCMP") {
    "vcmp"
  } else if name.has_prefix("VPCOM") {
    "vpcom"
  } else if name.has_prefix("CMPPS") ||
    name.has_prefix("CMPPD") ||
    name.has_prefix("CMPSSr") ||
    name.has_prefix("CMPSDr") {
    "cmp"
  } else {
    ""
  }
}

///|
/// Whether a memory reference uses 32-bit (in 64-bit mode) or 16-bit (in
/// 32-bit mode) address registers, that is whether the address-size prefix
/// is needed by the operand (`X86_MC::needsAddressSizeOverride`).
fn x86_llvm_memory_needs_adsize(
  operands : Array[ProjectInstructionOperand],
  index : Int,
  mode64 : Bool,
) -> Bool {
  let base = x86_llvm_operand_register(operands.get(index))
  let index_reg = x86_llvm_operand_register(operands.get(index + 2))
  let in_file = (name : String, file : Array[String]) => {
    name != "" && file.contains(name)
  }
  if mode64 {
    in_file(base, x86_llvm_gpr32) ||
    in_file(index_reg, x86_llvm_gpr32) ||
    base == "EIP" ||
    index_reg == "EIZ"
  } else {
    in_file(base, x86_llvm_gpr16) || in_file(index_reg, x86_llvm_gpr16)
  }
}

///|
/// The AT&T assembly of a decoded instruction.
fn x86_llvm_print(
  tables : X86LlvmTables,
  insn : X86LlvmInsn,
  _addr : UInt64,
) -> String {
  let name = tables.names[insn.id]
  let template = tables.templates[insn.id]
  let operands = insn.operands
  let spec = tables.specs[insn.id]
  let tsinfo = tables.tsinfo[insn.id]
  // the MCInst index of the first memory reference, and string operands
  let mut memory_index = -1
  let mut has_src = false
  let mut has_dst = false
  let mut position = 0
  let items = spec.length() / 2
  let widths : Array[Int] = []
  for k in 0..<items {
    let tag = spec[2 * k].to_int().unsafe_to_char()
    let width = match tag {
      'M' => 5
      'S' | 'O' => 2
      _ => 1
    }
    widths.push(width)
  }
  for k in 0..<items {
    let tag = spec[2 * k].to_int().unsafe_to_char()
    let (tag, width) = match tag {
      'd' | 'D' => {
        let target = spec[2 * k + 1].to_int() -
          '0'.to_int() +
          (if tag == 'D' { 10 } else { 0 })
        (spec[2 * target].to_int().unsafe_to_char(), widths[target])
      }
      _ => (tag, widths[k])
    }
    match tag {
      'M' => if memory_index < 0 { memory_index = position }
      'S' => has_src = true
      'T' => has_dst = true
      _ => ()
    }
    position += width
  }
  let out = StringBuilder()
  // printInstFlags
  if (tsinfo & 4) != 0 || (insn.mandatory == 0 && insn.lock) {
    out.write_string("lock  ")
  }
  if insn.mandatory == 0 {
    if insn.rep == 0xF2 {
      out.write_string("repne  ")
    } else if insn.rep == 0xF3 && insn.opcode != 0x90 {
      out.write_string("rep  ")
    }
  }
  if insn.adsize {
    let adsize_field = tsinfo & 3
    let needs = if (insn.mode64 && adsize_field == 2) ||
      (!insn.mode64 && adsize_field == 1) {
      true
    } else if has_src || has_dst {
      let register = x86_llvm_operand_register(
        operands.get(if has_src && has_dst { 1 } else { 0 }),
      )
      if insn.mode64 {
        register == "ESI" || register == "EDI"
      } else {
        register == "SI" || register == "DI"
      }
    } else if memory_index >= 0 {
      x86_llvm_memory_needs_adsize(operands, memory_index, insn.mode64)
    } else {
      false
    }
    if !needs {
      out.write_string(if insn.mode64 { "addr32  " } else { "addr16  " })
    }
  }
  // printVecCompareInstr
  let family = x86_llvm_vector_compare_family(name)
  if family != "" {
    let predicate = x86_llvm_operand_immediate(
      operands.get(operands.length() - 1),
    )
    let limit = if family == "vcmp" { 31L } else { 7L }
    if predicate >= 0L && predicate <= limit {
      let mnemonic = match template.find(" ") {
        Some(space) => template.view(end_offset=space).to_owned()
        None => template
      }
      let rest = mnemonic.view(start_offset=family.length()).to_owned()
      let names = if family == "vpcom" {
        x86_llvm_vpcom_predicates
      } else {
        x86_llvm_compare_predicates
      }
      out.write_string(family + names[predicate.to_int()] + rest + " ")
      out.write_string(
        x86_llvm_render_operand(
          if memory_index >= 0 {
            'm'
          } else {
            'r'
          },
          2,
          operands,
        ),
      )
      if family != "cmp" {
        out.write_string(", " + x86_llvm_render_operand('r', 1, operands))
      }
      out.write_string(", " + x86_llvm_render_operand('r', 0, operands))
      return out.to_string()
    }
  }
  out.write_string(x86_llvm_expand_template(template, operands))
  out.to_string()
}
