// `--print-missing` (upstream `Missing` module): the instructions whose
// semantics is not known.

///|
fn hex_bytes(bytes : Bytes) -> String {
  let parts = []
  for b in bytes {
    let hex = b.to_int().to_string(radix=16)
    parts.push(if hex.length() < 2 { "0" + hex } else { hex })
  }
  parts.join(" ")
}

///|
fn operand_text(op : @project.ProjectInstructionOperand) -> String {
  match op {
    ProjectRegisterOperand(_, name) => name
    ProjectImmediateOperand(value) => value.to_string()
    ProjectFloatingOperand(value) => value.to_string()
  }
}

///|
/// `(<encoding>:<name> <ops>)` (upstream `pp_basic`).
fn basic_text(insn : @project.ProjectDisassemblyInstruction) -> String {
  let ops = insn.operands().map(operand_text)
  let ops = if ops.is_empty() { "" } else { " " + ops.join(" ") }
  "(\{insn.encoding()}:\{insn.name()}\{ops})"
}

///|
/// Renders the list of the instructions that could not be lifted,
/// followed by the histogram of the missed opcodes and the counters of
/// lifted, failed, and missed instructions.
pub fn missing_report(project : @project.Project) -> String {
  let target = project.target()
  let sb = StringBuilder()
  let stats : Map[String, Int] = Map([])
  let mut lifted = 0
  let mut missed = 0
  let failed = 0
  for insn in project.disassembly().instructions() {
    match insn.lift(target~) {
      Ok(_) => lifted += 1
      Err(_) => {
        missed += 1
        let addr = insn.addr().to_string(radix=16)
        let code = hex_bytes(insn.memory().to_bytes())
        sb.write_string(
          "\{addr}: \{code} ; \{insn.assembly()} ; \{basic_text(insn)}\n",
        )
        stats[insn.name()] = stats.get(insn.name()).unwrap_or(0) + 1
      }
    }
  }
  // group opcodes by their counts, in the increasing order of counts
  let histo : Map[Int, Array[String]] = Map([])
  let names = stats.keys().collect()
  names.sort()
  for name in names {
    let count = stats[name]
    match histo.get(count) {
      Some(xs) => xs.insert(0, name)
      None => histo[count] = [name]
    }
  }
  let counts = histo.keys().collect()
  counts.sort()
  sb.write_string("\nHistogram:\n")
  for count in counts {
    for name in histo[count] {
      sb.write_string(pad_right(count.to_string(), 4) + " " + name + "\n")
    }
  }
  sb.write_string("\n")
  sb.write_string(pad_right("Lifted:", 8) + " \{lifted}\n")
  sb.write_string(pad_right("Failed:", 8) + " \{failed}\n")
  sb.write_string(pad_right("Missed:", 8) + " \{missed}\n")
  sb.to_string()
}

///|
fn pad_right(s : String, width : Int) -> String {
  if s.length() >= width {
    s
  } else {
    s + " ".repeat(width - s.length())
  }
}
