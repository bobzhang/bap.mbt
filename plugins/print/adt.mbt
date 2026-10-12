// The Abstract Data Type format of the IR and of the whole project
// (upstream `Print_main.Adt`).

///|
/// Formats an integer like OCaml's `%#d` (digits grouped with `_`).
fn ocaml_alt_dec(n : Int32) -> String {
  let digits = n.abs().to_string()
  let buf = StringBuilder()
  if n < 0 {
    buf.write_char('-')
  }
  let len = digits.length()
  for i, c in digits.to_array() {
    if i > 0 && (len - i) % 3 == 0 {
      buf.write_char('_')
    }
    buf.write_char(c)
  }
  buf.to_string()
}

///|
fn adt_tid(tid : @types.Tid) -> String {
  "Tid(\{ocaml_alt_dec(tid.id())}, \{escape_ocaml_string(tid_name(tid))})"
}

///|
/// Prints `[x1,@ x2,@ ...]`.
fn[T] adt_seq(
  fmt : @text_tags.Formatter,
  xs : ArrayView[T],
  pp : (@text_tags.Formatter, T) -> Unit,
) -> Unit {
  fmt.print_string("[")
  for i, x in xs {
    if i > 0 {
      fmt.print_format(",@ ")
    }
    pp(fmt, x)
  }
  fmt.print_string("]")
}

///|
fn adt_attr(fmt : @text_tags.Formatter, attr : (String, String)) -> Unit {
  fmt.print_string(
    "Attr(\{escape_ocaml_string(attr.0)},\{escape_ocaml_string(attr.1)})",
  )
}

///|
fn adt_attrs(fmt : @text_tags.Formatter, attrs : Map[String, String]) -> Unit {
  fmt.print_string("Attrs(")
  adt_seq(fmt, attrs.to_array(), adt_attr)
  fmt.print_string(")")
}

///|
fn[T] adt_term(
  fmt : @text_tags.Formatter,
  name : String,
  term : @types.Term[T],
  pp_self : () -> Unit,
) -> Unit {
  fmt.print_string("\{name}(\{adt_tid(term.tid())},")
  fmt.print_format("@, ")
  adt_attrs(fmt, term.attrs())
  fmt.print_format(",@, ")
  pp_self()
  fmt.print_string(")")
}

///|
/// Prints a definition in the ADT format.
pub fn adt_def(
  fmt : @text_tags.Formatter,
  def : @types.Term[@types.Def],
) -> Unit {
  adt_term(fmt, "Def", def, () => {
    fmt.print_string(var_to_adt(def.lhs()))
    fmt.print_format(",@ ")
    fmt.print_string(exp_to_adt(def.rhs()))
  })
}

///|
/// Prints a phi-node in the ADT format.
pub fn adt_phi(
  fmt : @text_tags.Formatter,
  phi : @types.Term[@types.Phi],
) -> Unit {
  adt_term(fmt, "Phi", phi, () => {
    fmt.print_string(var_to_adt(phi.phi_lhs()))
    fmt.print_format(",@ Values(")
    adt_seq(fmt, phi.values(), (fmt, v) => {
      fmt.print_string("(\{adt_tid(v.0)},\{exp_to_adt(v.1)})")
    })
    fmt.print_string(")")
  })
}

///|
fn adt_label(label : @types.Label) -> String {
  match label {
    Direct(tid) => "Direct(\{adt_tid(tid)})"
    Indirect(exp) => "Indirect(\{exp_to_adt(exp)})"
  }
}

///|
/// Prints a jump in the ADT format.
pub fn adt_jmp(
  fmt : @text_tags.Formatter,
  jmp : @types.Term[@types.Jmp],
) -> Unit {
  let kind = jmp.kind()
  let name = match kind {
    JmpCall(_) => "Call"
    Goto(_) => "Goto"
    Ret(_) => "Ret"
    Interrupt(_, _) => "Exn"
  }
  adt_term(fmt, name, jmp, () => {
    fmt.print_string(exp_to_adt(jmp.cond()))
    fmt.print_format(",@ ")
    let body = match kind {
      Goto(l) | Ret(l) => adt_label(l)
      Interrupt(n, r) => "(\{n},\{adt_tid(r)})"
      JmpCall(c) => {
        let ret = match c.return_label() {
          Some(l) => adt_label(l)
          None => ""
        }
        "(\{adt_label(c.target())},\{ret})"
      }
    }
    fmt.print_string(body)
  })
}

///|
/// Prints a block in the ADT format.
pub fn adt_blk(
  fmt : @text_tags.Formatter,
  blk : @types.Term[@types.Blk],
) -> Unit {
  adt_term(fmt, "Blk", blk, () => {
    fmt.print_string("Phis(")
    adt_seq(fmt, blk.phis(), adt_phi)
    fmt.print_format("),@ Defs(")
    adt_seq(fmt, blk.defs(), adt_def)
    fmt.print_format("),@ Jmps(")
    adt_seq(fmt, blk.jmps(), adt_jmp)
    fmt.print_string(")")
  })
}

///|
/// Prints an argument in the ADT format.
pub fn adt_arg(
  fmt : @text_tags.Formatter,
  arg : @types.Term[@types.Arg],
) -> Unit {
  adt_term(fmt, "Arg", arg, () => {
    fmt.print_string(var_to_adt(arg.arg_lhs()))
    fmt.print_format(",@ ")
    fmt.print_string(exp_to_adt(arg.arg_rhs()))
    fmt.print_format(",@ ")
    let intent = match arg.intent() {
      None => ""
      Some(In) => "In()"
      Some(Out) => "Out()"
      Some(Both) => "Both()"
    }
    fmt.print_string(intent)
  })
}

///|
/// Prints a subroutine in the ADT format.
pub fn adt_sub(
  fmt : @text_tags.Formatter,
  sub : @types.Term[@types.Sub],
) -> Unit {
  adt_term(fmt, "Sub", sub, () => {
    fmt.print_string(escape_ocaml_string(sub.sub_name()))
    fmt.print_format(",@, Args(")
    adt_seq(fmt, sub.args(), adt_arg)
    fmt.print_format("),@ Blks(")
    adt_seq(fmt, sub.blks(), adt_blk)
    fmt.print_string(")")
  })
}

///|
/// Prints a program in the ADT format.
pub fn adt_program(
  fmt : @text_tags.Formatter,
  program : @types.Term[@types.Program],
) -> Unit {
  adt_term(fmt, "Program", program, () => {
    fmt.print_string("Subs(")
    adt_seq(fmt, program.subs(), adt_sub)
    fmt.print_string(")")
  })
}

///|
/// Prints any IR term in the ADT format.
pub fn adt_ir_term(fmt : @text_tags.Formatter, term : @types.IrTerm) -> Unit {
  match term {
    ProgramTerm(t) => adt_program(fmt, t)
    SubTerm(t) => adt_sub(fmt, t)
    ArgTerm(t) => adt_arg(fmt, t)
    BlkTerm(t) => adt_blk(fmt, t)
    PhiTerm(t) => adt_phi(fmt, t)
    DefTerm(t) => adt_def(fmt, t)
    JmpTerm(t) => adt_jmp(fmt, t)
  }
}

///|
/// Renders any IR term in the ADT format.
pub fn ir_term_to_adt(term : @types.IrTerm) -> String {
  let fmt = @text_tags.Formatter::new()
  adt_ir_term(fmt, term)
  fmt.flush_str()
}

///|
/// Prints an address like `Word.pp_generic ~prefix:`base ~format:`hex`.
fn adt_addr(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16).to_upper()
}

///|
/// Splits a memory annotation into a tag name and a value. The port
/// represents memory annotations as strings: either `name=value` (see
/// `Project::substitute`) or a bare segment name.
fn memory_tag(tag : String) -> (String, String) {
  match tag.find("=") {
    Some(i) =>
      (
        tag.unsafe_substring(start=0, end=i),
        tag.unsafe_substring(start=i + 1, end=tag.length()),
      )
    None => ("segment", tag)
  }
}

///|
/// The sections of the project with their memory.
fn project_sections(
  project : @project.Project,
) -> Array[(String, @memory.Memory)] {
  let result = []
  match project.image() {
    Some(image) =>
      for section in image.sections() {
        match image.memory_of_section(section) {
          Some(mem) => result.push((section.name(), mem))
          None => ()
        }
      }
    None =>
      for entry in project.memory().to_sequence() {
        if memory_tag(entry.1) is ("section", name) {
          result.push((name, entry.0))
        }
      }
  }
  result
}

///|
/// Prints the whole project in the ADT format (upstream `Adt.pp_project`).
pub fn adt_project(
  fmt : @text_tags.Formatter,
  project : @project.Project,
) -> Unit {
  fmt.print_string("Project(")
  adt_attrs(fmt, project.storage())
  fmt.print_format(",@ Sections(")
  adt_seq(fmt, project_sections(project), (fmt, s) => {
    let buf = StringBuilder()
    for b in s.1.to_bytes() {
      let hex = b.to_int().to_string(radix=16)
      buf.write_string(
        if hex.length() < 2 {
          "\\x0" + hex
        } else {
          "\\x" + hex
        },
      )
    }
    fmt.print_string(
      "Section(\{escape_ocaml_string(s.0)}, \{adt_addr(s.1.min_addr())}, \"\{buf.to_string()}\")",
    )
  })
  fmt.print_format("),@ Memmap(")
  adt_seq(fmt, project.memory().to_sequence(), (fmt, entry) => {
    let (mem, tag) = entry
    fmt.print_string(
      "Annotation(Region(\{adt_addr(mem.min_addr())},\{adt_addr(mem.max_addr())}),",
    )
    fmt.print_format("@ ")
    adt_attr(fmt, memory_tag(tag))
    fmt.print_string(")")
  })
  fmt.print_format("),@ ")
  adt_program(fmt, project.program())
  fmt.print_string(")")
}
