// Lifting the cases with each lifter and comparing with the expected state.

///|
fn word_value(v : @types.BilValue?) -> @types.Word? {
  match v {
    Some(BilWord(w)) => Some(w)
    _ => None
  }
}

///|
fn hex(v : UInt64) -> String {
  "0x" + v.to_string(radix=16)
}

///|
/// The differences between the final machine state and the expected one.
fn compare(c : Case, m : Machine) -> Array[String] raise {
  let diffs = []
  if c.exn != m.exn {
    let show = (x : Int32?) => {
      match x {
        Some(n) => n.to_string()
        None => "none"
      }
    }
    diffs.push("exn: \{show(m.exn)} expected \{show(c.exn)}")
  }
  let w = c.mode
  for i, name in gpr_names(w) {
    let expected = match c.exp_regs.get(i) {
      Some(None) => continue
      Some(Some(v)) => v
      None => c.regs.get(i).unwrap_or(default_gpr(i, w))
    }
    match word_value(m.values.get(name)) {
      Some(x) =>
        if x.to_uint64() != expected {
          diffs.push("\{name}=\{hex(x.to_uint64())} expected \{hex(expected)}")
        }
      None => diffs.push("\{name} undefined, expected \{hex(expected)}")
    }
  }
  for f in flag_bits {
    let (name, bit) = f
    if ((c.undef_flags >> bit) & 1) == 1 {
      continue
    }
    let expected = if c.exn is Some(_) {
      (c.flags >> bit) & 1
    } else {
      (c.exp_flags >> bit) & 1
    }
    match word_value(m.values.get(name)) {
      Some(x) =>
        if x.to_uint64().to_int() != expected {
          diffs.push("\{name}=\{x.to_uint64()} expected \{expected}")
        }
      None => diffs.push("\{name} undefined, expected \{expected}")
    }
  }
  for i in 0..<nregs(w) {
    let expected = match c.exp_xmms.get(i) {
      Some(None) => continue
      Some(Some(h)) => xmm_word(h)
      None =>
        match c.xmms.get(i) {
          Some(h) => xmm_word(h)
          None => default_xmm_word(i)
        }
    }
    match word_value(m.values.get("YMM\{i}")) {
      Some(x) => {
        let x = x.extract(hi=127, lo=0)
        if x != expected {
          diffs.push("XMM\{i}=\{x.to_hex()} expected \{expected.to_hex()}")
        }
      }
      None => diffs.push("XMM\{i} undefined")
    }
  }
  match m.values.get("mem") {
    _ if c.mem_dontcare => ()
    Some(BilMem(mem)) =>
      for r in regions(c.mem, more=c.exp_mem) {
        let (base, bytes) = r
        for k, b in bytes {
          let a = base + k.to_uint64()
          match mem.cell(a) {
            Some(x) if x == b => ()
            Some(x) => {
              diffs.push(
                "mem[\{hex(a)}]=\{hex(x.to_uint64())} expected \{hex(b.to_uint64())}",
              )
              break
            }
            None => {
              diffs.push("mem[\{hex(a)}] undefined")
              break
            }
          }
        }
      }
    _ => diffs.push("mem undefined")
  }
  if c.exn is None {
    let next = CODE + c.code.length().to_uint64()
    let expected = c.jump.unwrap_or(next)
    let actual = m.jump.unwrap_or(next)
    if expected != actual {
      diffs.push("jump \{hex(actual)} expected \{hex(expected)}")
    }
  }
  diffs
}

///|
priv enum Lift {
  Lifted(Array[@types.Stmt])
  NotLifted
  Failed(String)
}

///|
let decoders : Map[Int32, @project.ProjectDisassemblyBasic] = Map([])

///|
fn decode(c : Case) -> @project.ProjectDisassemblyInstruction? raise {
  let disasm = match decoders.get(c.mode) {
    Some(d) => d
    None => {
      let triple = if c.mode == 64 { "x86_64" } else { "x86" }
      let d = match
        @project.ProjectDisassemblyBasic::create(triple, backend="llvm") {
        Ok(d) => d
        Err(r) => fail(r)
      }
      decoders[c.mode] = d
      d
    }
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=CODE,
    c.code,
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) => result.instruction()
    Err(r) => fail(r)
  }
}

///|
/// Decode with the Basic decoder, checking the decoded length.
fn decode_case(
  c : Case,
) -> Result[@project.ProjectDisassemblyInstruction, Lift] raise {
  match decode(c) {
    None => Err(NotLifted)
    Some(insn) =>
      if insn.memory().length() != c.code.length() {
        Err(
          Failed(
            "decoded \{insn.memory().length()} of \{c.code.length()} bytes as \{insn.name()}",
          ),
        )
      } else {
        Ok(insn)
      }
  }
}

///|
fn target_of(mode : Int32) -> @core_theory.Target {
  if mode == 64 {
    @core_theory.Target::x86_64()
  } else {
    @core_theory.Target::i386()
  }
}

///|
fn x86_mode(mode : Int32) -> @x86.Mode {
  if mode == 64 {
    X8664
  } else {
    X86
  }
}

///|
fn lift_basic(c : Case) -> Lift raise {
  match decode_case(c) {
    Err(l) => l
    Ok(insn) =>
      match insn.lift_basic_bil() {
        Ok(bil) => Lifted(bil)
        Err(_) => NotLifted
      }
  }
}

///|
/// LLVM's MCInst of the case (`None` when LLVM does not decode it).
fn mc_insn(c : Case) -> @mc.Insn? raise {
  guard c.mc.find(":") is Some(colon) else { return None }
  let name = c.mc.view(end_offset=colon).to_owned()
  let ops : Array[@mc.Op] = []
  let rest = c.mc.view(start_offset=colon + 1)
  if !rest.is_empty() {
    for op in rest.split(",") {
      if op.has_prefix("%") {
        ops.push(@mc.Op::reg(op.view(start_offset=1).to_owned()))
      } else if op.has_prefix("-") {
        ops.push(Imm(-parse_dec(op.view(start_offset=1))))
      } else {
        ops.push(Imm(parse_dec(op)))
      }
    }
  }
  let target = target_of(c.mode)
  Some(
    @mc.Insn::create(
      name,
      ops,
      addr=CODE,
      size=c.code.length(),
      encoding=@mc.default_encoding(target),
      raw=c.code,
    ),
  )
}

///|
/// Lift LLVM's MCInst of the case with the providers of `registry`.
fn lift_registry(c : Case, registry : @mc.Registry) -> Lift raise {
  guard mc_insn(c) is Some(insn) else { return NotLifted }
  let ctx = @mc.Context::create(target_of(c.mode))
  try registry.lift(ctx, insn) catch {
    e => if e.is_unsupported() { NotLifted } else { Failed(e.message()) }
  } noraise {
    l => Lifted(l.bil())
  }
}

///|
let x86_registry : @mc.Registry = {
  let r = @mc.Registry::new()
  @x86.register(registry=r)
  r
}

///|
let lisp_registry : @mc.Registry = {
  let r = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry=r)
  r
}

///|
fn lift_x86(c : Case) -> Lift raise {
  lift_registry(c, x86_registry)
}

///|
fn lift_lisp(c : Case) -> Lift raise {
  lift_registry(c, lisp_registry)
}

///|
fn lift_legacy(c : Case) -> Lift {
  let mode = x86_mode(c.mode)
  match @x86.legacy_length(mode, c.code, addr=CODE) {
    Some(n) if n != c.code.length() =>
      return Failed("legacy decodes \{n} of \{c.code.length()} bytes")
    _ => ()
  }
  try @x86.lift_legacy(mode, c.code, addr=CODE) catch {
    e => if e.is_unsupported() { NotLifted } else { Failed(e.message()) }
  } noraise {
    bil => Lifted(bil)
  }
}

///|
/// Agreement statistics of one lifter on one table.
priv struct Report {
  mut cases : Int32
  mut lifted : Int32
  mut agree : Int32
  mut failed : Int32
  findings : Map[String, String]
}

///|
fn run_table(
  mode : Int32,
  table : String,
  lift : (Case) -> Lift raise,
) -> Report raise {
  let report : Report = {
    cases: 0,
    lifted: 0,
    agree: 0,
    failed: 0,
    findings: Map([]),
  }
  for c in parse_cases(mode, table) {
    report.cases += 1
    let key = "\{c.text} [\{hex_code(c.code)}]"
    match lift(c) {
      NotLifted => ()
      Failed(r) => {
        report.failed += 1
        if !report.findings.contains(key) {
          report.findings[key] = "lift failed: \{r}"
        }
      }
      Lifted(bil) => {
        report.lifted += 1
        let diffs = try run_case(c, bil) catch {
          ExecError(r) => ["execution failed: \{r}"]
          e => ["execution failed: \{e}"]
        } noraise {
          m => compare(c, m)
        }
        if diffs.is_empty() {
          report.agree += 1
        } else if !report.findings.contains(key) {
          report.findings[key] = diffs.iter().take(3).collect().join("; ")
        }
      }
    }
  }
  report
}

///|
fn hex_code(code : Bytes) -> String {
  code
  .iter()
  .map(b => {
    let s = b.to_int().to_string(radix=16)
    if s.length() == 1 {
      "0" + s
    } else {
      s
    }
  })
  .collect()
  .join("")
}

///|
fn report_text(r : Report) -> String {
  let lines = [
    "cases=\{r.cases} lifted=\{r.lifted} agree=\{r.agree} mismatch=\{r.lifted - r.agree} failed=\{r.failed}",
  ]
  for k, v in r.findings {
    lines.push("\{k}: \{v}")
  }
  lines.join("\n")
}

///|
/// The case tables of the families: (family, 64-bit table, 32-bit table).
let families : Array[(String, String, String)] = [
  ("alu", alu64_cases, alu32_cases),
  ("muldiv", muldiv64_cases, muldiv32_cases),
  ("shift", shift64_cases, shift32_cases),
  ("bits", bits64_cases, bits32_cases),
  ("move", move64_cases, move32_cases),
  ("control", control64_cases, control32_cases),
  ("string", string64_cases, string32_cases),
  ("sse", sse64_cases, sse32_cases),
  ("ssebasic", ssebasic64_cases, ssebasic32_cases),
  ("lisp", lisp64_cases, lisp32_cases),
]

///|
/// The reports of `lift` on the 64- and 32-bit tables of `family`.
fn family_report(lift : (Case) -> Lift raise, family : String) -> String raise {
  guard families.search_by(f => f.0 == family) is Some(i) else {
    fail("no family \{family}")
  }
  let (_, t64, t32) = families[i]
  "x86-64: " +
  report_text(run_table(64, t64, lift)) +
  "\nx86: " +
  report_text(run_table(32, t32, lift))
}
