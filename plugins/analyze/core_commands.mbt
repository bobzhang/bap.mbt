// The core analysis commands (upstream `Analyze_core_commands`): the
// commands that print the contents of the knowledge base.
//
// The port keeps the knowledge base of a binary as the persisted project
// (see the `--project` option of the `disassemble` command), so the
// commands inspect the loaded project: its unit (the file), its
// subroutines, and its instructions.

///|
/// The knowledge base the commands operate on.
let current : Ref[@project.Project?] = Ref(None)

///|
/// The output of the commands.
let output : Ref[(String) -> Unit] = Ref(_ => ())

///|
fn out(s : String) -> Unit {
  (output.val)(s)
}

///|
fn pad_right(s : String, width : Int32) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}

///|
fn unit_name(proj : @project.Project) -> String {
  match proj.filename() {
    Some(name) => name
    None =>
      match proj.get(@disassemble.unit_path_key) {
        Some(name) => name
        None => "unknown"
      }
  }
}

///|
fn addr_text(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16)
}

///|
/// The representation of an instruction label: `<unit>:<address>`.
fn label_repr(proj : @project.Project, addr : UInt64) -> String {
  "\{unit_name(proj)}:\{addr_text(addr)}"
}

///|
fn parse_addr(s : String) -> UInt64? {
  let s = match s.rev_find(":") {
    Some(i) => s[i + 1:].to_owned()
    None => s
  }
  let (digits, radix) = if s.has_prefix("0x") {
    (s[2:].to_owned(), 16)
  } else {
    (s, 10)
  }
  if digits == "" {
    return None
  }
  let mut v = 0UL
  for c in digits {
    let d = match c {
      '0'..<='9' => c.to_int() - '0'.to_int()
      'a'..<='f' => c.to_int() - 'a'.to_int() + 10
      'A'..<='F' => c.to_int() - 'A'.to_int() + 10
      _ => return None
    }
    if d >= radix {
      return None
    }
    v = v * radix.to_uint64() + d.to_uint64()
  }
  Some(v)
}

///|
/// The semantics of the instruction, restricted to the `slots` (all
/// slots when empty).
fn semantics_text(
  proj : @project.Project,
  insn : @project.ProjectDisassemblyInstruction,
  slots : Array[String],
) -> String {
  let bil = match insn.lift(target=proj.target()) {
    Ok(lifted) => lifted.bil()
    Err(_) => []
  }
  let all = [
    ("bap:insn", "(\{@print.insn_to_string(insn, "pretty")})"),
    ("bap:asm", "\"\{insn.assembly()}\""),
    ("bap:bil", "\"\{@print.bil_to_string(bil)}\""),
    ("bap:insn-code", "\"\{@print.memory_to_string(insn.memory())}\""),
  ]
  let selected = if slots.is_empty() {
    all
  } else {
    all.filter(slot => {
      slots.contains(slot.0) ||
      slots.contains(slot.0.replace(old="bap:", new=""))
    })
  }
  "(" + selected.map(slot => "(\{slot.0} \{slot.1})").join("\n ") + ")\n"
}

///|
fn print_insn(
  proj : @project.Project,
  insn : @project.ProjectDisassemblyInstruction,
  slots : Array[String]?,
) -> Unit {
  out(label_repr(proj, insn.addr()) + "\n")
  match slots {
    None => ()
    Some(slots) => out(semantics_text(proj, insn, slots))
  }
}

///|
fn belongs_to_unit(proj : @project.Project, unit : String?) -> Bool {
  match unit {
    None => true
    Some(u) => u == unit_name(proj)
  }
}

///|
fn with_project(f : (@project.Project) -> Unit) -> Result[Unit, String] {
  match current.val {
    Some(proj) => f(proj)
    None => ()
  }
  Ok(())
}

///|
fn sorted_insns(
  proj : @project.Project,
) -> Array[@project.ProjectDisassemblyInstruction] {
  let insns = proj.disassembly().instructions()
  insns.sort_by((a, b) => a.addr().compare(b.addr()))
  insns
}

///|
fn find_function(
  proj : @project.Project,
  name_or_addr : String,
) -> @project.ProjectDisassemblyFunction? {
  let symtab = proj.disassembly_symtab()
  match symtab.find_by_name(name_or_addr) {
    Some(f) => Some(f)
    None =>
      match parse_addr(name_or_addr) {
        Some(addr) => symtab.find_by_start(addr)
        None => None
      }
  }
}

///|
let core_registered : Ref[Bool] = Ref(false)

///|
/// Registers the core commands in the `bap` package (upstream
/// `Analyze_core_commands.register`).
pub fn register_core_commands() -> Unit {
  if core_registered.val {
    return
  }
  core_registered.val = true
  let pkg = "bap"
  let label = @project.ProjectAnalysisArg::argument(
    rule="<label>",
    description="a program label",
    parse=s => Ok(s),
  )
  let unit = @project.ProjectAnalysisArg::argument(
    rule="<unit>",
    description="a program unit",
    parse=s => Ok(s),
  )
  let string = @project.ProjectAnalysisArg::string()
  @project.register_project_analysis(
    name="instruction",
    pkg~,
    description="Prints the instruction semantics. Prints the semantics of an instruction with the given label. If no fields are specified, then prints all properties in the semantics object. Otherwise, prints only the specified fields.",
    args=@project.ProjectAnalysisArgs::pair(label, string.rest()),
    run=args => {
      let (label, slots) = args
      with_project(proj => {
        match parse_addr(label) {
          None => ()
          Some(addr) =>
            match proj.disassembly().instruction_at(addr) {
              Some(insn) => out(semantics_text(proj, insn, slots))
              None => ()
            }
        }
      })
    },
  )
  |> ignore
  @project.register_project_analysis(
    name="instructions",
    pkg~,
    description="Prints all instructions. If :unit is specified then prints only instructions that belong to that unit. If :semantics is specified then prints the semantics of each instruction. The :semantics keyword could be followed by one or more field names. If no fields are specified, then all properties of an instruction will be printed, otherwise only those that are specified will be printed.",
    args=@project.ProjectAnalysisArgs::pair(
      @project.ProjectAnalysisArg::keyword("unit", unit),
      @project.ProjectAnalysisArg::keyword("semantics", string.rest()),
    ),
    run=args => {
      let (unit, slots) = args
      with_project(proj => {
        if belongs_to_unit(proj, unit) {
          for insn in sorted_insns(proj) {
            print_insn(proj, insn, slots)
          }
        }
      })
    },
  )
  |> ignore
  @project.register_project_analysis(
    name="units",
    pkg~,
    description="Prints all units. Prints all units stored in the knowledge base.",
    args=@project.ProjectAnalysisArgs::one(@project.ProjectAnalysisArg::empty()),
    run=_ => {
      with_project(proj => {
        out("\{pad_right(unit_name(proj), 40)} \{proj.target().to_string()}\n")
      })
    },
  )
  |> ignore
  @project.register_project_analysis(
    name="subroutines",
    pkg~,
    description="Prints all subroutines. If :unit is specified, then prints only subroutines of that unit. If :matches is specified, then prints only subroutines that match the name.",
    args=@project.ProjectAnalysisArgs::pair(
      @project.ProjectAnalysisArg::keyword("unit", unit),
      @project.ProjectAnalysisArg::keyword("matches", string),
    ),
    run=args => {
      let (unit, filter) = args
      with_project(proj => {
        if belongs_to_unit(proj, unit) {
          let functions = proj.disassembly_symtab().to_sequence()
          functions.sort_by((a, b) => a.addr().compare(b.addr()))
          for f in functions {
            let matches = match filter {
              None => true
              Some(prefix) => f.name().has_prefix(prefix)
            }
            if matches {
              out("\{label_repr(proj, f.addr())}: \{f.name()}\n")
            }
          }
        }
      })
    },
  )
  |> ignore
  @project.register_project_analysis(
    name="subroutine",
    pkg~,
    description="Prints a subroutine. Prints the subroutine in the specified unit with the given name or address. If :semantics is specified, then prints the semantics of each instruction. The :semantics keyword could be followed by one or more field names. If no fields are specified, then all properties of an instruction will be printed, otherwise only those that are specified will be printed.",
    args=@project.ProjectAnalysisArgs::triple(
      unit,
      string,
      @project.ProjectAnalysisArg::keyword("semantics", string.rest()),
    ),
    run=args => {
      let (unit, name, slots) = args
      with_project(proj => {
        if belongs_to_unit(proj, Some(unit)) {
          match find_function(proj, name) {
            None => ()
            Some(f) => {
              let blocks = f.blocks()
              blocks.sort_by((a, b) => a.addr().compare(b.addr()))
              for blk in blocks {
                for insn in blk.instructions() {
                  print_insn(proj, insn, slots)
                }
              }
            }
          }
        }
      })
    },
  )
  |> ignore
}
