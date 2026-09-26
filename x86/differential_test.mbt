// Differential testing against the project's Basic x86 lifter: for a corpus
// of instructions supported by both lifters, the semantics are executed on
// the same concrete initial states and the resulting registers, flags,
// memory, jump targets and CPU exceptions are compared. Values left
// undefined by either lifter are not compared. The Basic lifter's
// sub-register variables (EAX, AL, XMM0, ...) are mapped onto the full
// registers first (`normalize_basic`).
//
// The lifters agree on every instruction both of them lift: the upstream
// deviations from the Intel SDM this test used to report (ROL/ROR flags,
// the missing zero-extension of BTS/BTR/BTC with 32-bit registers, the
// legacy decoding of `0f ba /5 /6 /7` as BT, the swapped CMPXCHG8B halves
// and XADD operands, the one-operand IMUL flags and the IDIV overflow
// check) are fixed, see the README and `x86/semantics` (the differential
// test of all the x86 lifters against Unicorn).
//
// CALL/RET agree: like upstream, the Basic lifter pushes the return address
// on calls and pops it (and the immediate byte count) on returns, jumping to
// it.

///|
/// The sub-register variables of the Basic lifter, which models `EAX`,
/// `AL`, `XMM0`, ... as separate variables: name -> (full register, lo,
/// hi), following the Core Theory alias table of the target.
fn subregisters(mode : @x86.Mode) -> Map[String, (@types.Var, Int, Int)] {
  let table : Map[String, (@types.Var, Int, Int)] = Map([])
  let gprs = @x86.gprs(mode)
  let names : Array[(String, String, String, String)] = [
    ("EAX", "AX", "AL", "AH"),
    ("ECX", "CX", "CL", "CH"),
    ("EDX", "DX", "DL", "DH"),
    ("EBX", "BX", "BL", "BH"),
    ("ESP", "SP", "SPL", ""),
    ("EBP", "BP", "BPL", ""),
    ("ESI", "SI", "SIL", ""),
    ("EDI", "DI", "DIL", ""),
  ]
  for i, base in gprs {
    let (d, w, b, h) = if i < 8 {
      names[i]
    } else {
      ("R\{i}D", "R\{i}W", "R\{i}B", "")
    }
    if mode == X8664 {
      table[d] = (base, 0, 31)
    }
    table[w] = (base, 0, 15)
    if mode == X8664 || i < 4 {
      table[b] = (base, 0, 7)
    }
    if h != "" {
      table[h] = (base, 8, 15)
    }
  }
  for i, v in @x86.vector_registers(mode) {
    table["XMM\{i}"] = (v, 0, 127)
  }
  table
}

///|
fn norm_exp(
  table : Map[String, (@types.Var, Int, Int)],
  e : @types.Exp,
) -> @types.Exp {
  let n = x => norm_exp(table, x)
  match e {
    Var(v) =>
      match table.get(v.name) {
        Some((base, lo, hi)) => Extract(hi~, lo~, exp=Var(base))
        None => e
      }
    Int(_) | Unknown(_) => e
    Load(mem~, addr~, endian~, typ~) =>
      Load(mem=n(mem), addr=n(addr), endian~, typ~)
    Store(mem~, addr~, value~, endian~) =>
      Store(mem=n(mem), addr=n(addr), value=n(value), endian~)
    Let(v, x, y) => Let(v, n(x), n(y))
    Cast(kind~, width~, exp~) => Cast(kind~, width~, exp=n(exp))
    Extract(hi~, lo~, exp~) => Extract(hi~, lo~, exp=n(exp))
    Concat(high~, low~) => Concat(high=n(high), low=n(low))
    UnOp(op, x) => UnOp(op, n(x))
    BinOp(op, x, y) => BinOp(op, n(x), n(y))
    Ite(cond~, yes~, no~) => Ite(cond=n(cond), yes=n(yes), no=n(no))
  }
}

///|
/// Rewrite the Basic lifter's BIL onto the full registers: sub-register
/// reads extract the bits of the full register; writes merge into it,
/// except that 32-bit writes zero-extend into the 64-bit register in
/// 64-bit mode (Intel SDM 3.4.1.1).
fn normalize_basic(
  mode : @x86.Mode,
  stmts : Array[@types.Stmt],
) -> Array[@types.Stmt] {
  let table = subregisters(mode)
  let n = x => norm_exp(table, x)
  stmts.map(s => {
    match s {
      Move(v, e) =>
        match table.get(v.name) {
          None => Move(v, n(e))
          Some((base, lo, hi)) => {
            let width = match base.typ {
              Imm(w) => w
              Mem(..) => 0
            }
            let e = n(e)
            if mode == X8664 && lo == 0 && hi == 31 && width == 64 {
              Move(base, Cast(kind=Unsigned, width=64, exp=e))
            } else {
              let mut value = e
              if lo > 0 {
                value = Concat(
                  high=value,
                  low=Extract(hi=lo - 1, lo=0, exp=Var(base)),
                )
              }
              if hi < width - 1 {
                value = Concat(
                  high=Extract(hi=width - 1, lo=hi + 1, exp=Var(base)),
                  low=value,
                )
              }
              Move(base, value)
            }
          }
        }
      Jmp(e) => Jmp(n(e))
      If(cond~, yes~, no~) =>
        If(
          cond=n(cond),
          yes=normalize_basic(mode, yes),
          no=normalize_basic(mode, no),
        )
      While(cond~, body~) =>
        While(cond=n(cond), body=normalize_basic(mode, body))
      s => s
    }
  })
}

///|
/// Initial states of the differential test: pointer registers point into
/// the initialized memory regions, the other registers and the flags vary.
fn diff_states(mode : @x86.Mode) -> Array[Map[String, @types.BilValue]] {
  let w = mode.width()
  let wide = (x : UInt64) => if w == 32 { x & 0xffffffff } else { x }
  let values : Array[(UInt64, UInt64, Int)] = [
    // (RAX, RDX, flags)
    (0, 0, 0),
    (0xffffffffffffffff, 0xffffffffffffffff, 0b0111111),
    (0x80000000, 0x7fffffff, 0b0000001),
    (0x7fffffffffffffff, 0x8000000000000000, 0b0011000),
    (0x00000000000000ff, 0x0000000000000080, 0b0100100),
    (0x123456789abcdef0, 0x0fedcba987654321, 0b1000010),
  ]
  let states = []
  for i, v in values {
    let (rax, rdx, flag_bits) = v
    let regs = [
      (if w == 32 { "EAX" } else { "RAX" }, wide(rax)),
      (if w == 32 { "EDX" } else { "RDX" }, wide(rdx)),
      (if w == 32 { "ECX" } else { "RCX" }, (i + 1).to_uint64()),
      (if w == 32 { "EBX" } else { "RBX" }, DATA + 0x40),
      (if w == 32 { "ESI" } else { "RSI" }, DATA + 0x80),
      (if w == 32 { "EDI" } else { "RDI" }, DATA + 0x100),
      (if w == 32 { "ESP" } else { "RSP" }, STACK + 0x100),
      (if w == 32 { "EBP" } else { "RBP" }, STACK + 0x180),
    ]
    states.push(machine(mode, regs~, flag_bits~, seed=i + 1))
  }
  states
}

///|
fn opt_text(x : String?) -> String {
  match x {
    Some(s) => s
    None => "none"
  }
}

///|
fn value_text(v : @types.BilValue) -> String {
  match v {
    BilWord(w) => "0x" + w.to_bitvec().to_hex()
    BilMem(_) => "<mem>"
  }
}

///|
/// Compare two outcomes of the same initial state; the differences.
fn compare_outcomes(
  init : Map[String, @types.BilValue],
  ours : Outcome,
  basic : Outcome,
) -> Array[String] {
  let diffs = []
  for name, _ in init {
    if name == "mem" {
      continue
    }
    match (ours.values.get(name), basic.values.get(name)) {
      (Some(a), Some(b)) =>
        if a != b {
          diffs.push("\{name}: ours \{value_text(a)} basic \{value_text(b)}")
        }
      _ => ()
    }
  }
  match (ours.values.get("mem"), basic.values.get("mem")) {
    (Some(BilMem(a)), Some(BilMem(b))) if a != b => {
      let mut found = false
      for base in [DATA, STACK] {
        for i in 0..<1024 {
          let addr = base - 256 + i.to_uint64()
          if a.cell(addr) != b.cell(addr) {
            diffs.push("mem[0x\{addr.to_string(radix=16)}] differs")
            found = true
            break
          }
        }
      }
      if !found {
        diffs.push("mem differs outside the test regions")
      }
    }
    _ => ()
  }
  if ours.jump != basic.jump {
    diffs.push(
      "jump: ours \{opt_text(ours.jump.map(x => x.to_string(radix=16)))} basic \{opt_text(basic.jump.map(x => x.to_string(radix=16)))}",
    )
  }
  if ours.exn != basic.exn {
    diffs.push(
      "exn: ours \{opt_text(ours.exn.map(x => x.to_string()))} basic \{opt_text(basic.exn.map(x => x.to_string()))}",
    )
  }
  diffs
}

///|
fn hex_bytes(bytes : Bytes) -> String {
  bytes
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
  .join(" ")
}

///|
/// Statistics and findings of a differential run.
struct DiffReport {
  mut both : Int
  mut only_ours : Int
  mut only_basic : Int
  mut neither : Int
  mut basic_undecoded : Int
  mut agree : Int
  findings : Array[String]
}

///|
/// Run the differential test of one instruction with `lift` as "our"
/// lifter.
fn diff_one(
  report : DiffReport,
  mode : @x86.Mode,
  bytes : Bytes,
  lift : (@mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError,
) -> Unit {
  let triple = match mode {
    X86 => "x86"
    X8664 => "x86_64"
  }
  let addr = 0x400000UL
  let insn = basic_decode_opt(triple, bytes, addr~) catch {
    _ => {
      report.findings.push("\{hex_bytes(bytes)}: Basic decoder failed")
      return
    }
  }
  guard insn is Some(insn) else {
    // an invalid instruction for the Basic decoder: not decoded, so neither
    // lifter has an instruction to lift
    report.basic_undecoded += 1
    report.neither += 1
  }
  let label = "\{hex_bytes(bytes)} (\{insn.name()})"
  let decoded_len = insn.memory().length()
  let basic_bil = match insn.lift_basic_bil() {
    Ok(bil) if decoded_len == bytes.length() => Some(normalize_basic(mode, bil))
    _ => None
  }
  let ours = try lift(insn.to_mc_insn()) catch {
    _ => None
  } noraise {
    b => Some(b)
  }
  if decoded_len != bytes.length() {
    report.findings.push(
      "\{label}: Basic decodes \{decoded_len} of \{bytes.length()} bytes",
    )
  }
  match (ours, basic_bil) {
    (None, None) => report.neither += 1
    (Some(_), None) => {
      report.only_ours += 1
      if decoded_len == bytes.length() {
        report.findings.push("\{label}: only ours lifts")
      }
    }
    (None, Some(_)) => {
      report.only_basic += 1
      report.findings.push("\{label}: only Basic lifts")
    }
    (Some(ours), Some(basic)) => {
      report.both += 1
      let diffs : Map[String, Unit] = Map([])
      for init in diff_states(mode) {
        let a = run(ours, init) catch {
          e => {
            diffs["ours: \{e}"] = ()
            continue
          }
        }
        let b = run(basic, init) catch {
          e => {
            diffs["basic: \{e}"] = ()
            continue
          }
        }
        for d in compare_outcomes(init, a, b) {
          diffs[d] = ()
        }
      }
      if diffs.is_empty() {
        report.agree += 1
      } else {
        let first = diffs.keys().take(3).collect().join("; ")
        report.findings.push("\{label}: \{first}")
      }
    }
  }
}

///|
fn report_text(report : DiffReport) -> String {
  let lines = [
    "both=\{report.both} agree=\{report.agree} only_ours=\{report.only_ours} only_basic=\{report.only_basic} neither=\{report.neither} basic_undecoded=\{report.basic_undecoded}",
  ]
  lines.push_iter(report.findings.iter())
  lines.join("\n")
}

///|
fn combined_lifter(
  mode : @x86.Mode,
) -> (@mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  let registry = @mc.Registry::new()
  @x86.register(registry~)
  let target = match mode {
    X86 => @core_theory.Target::x86()
    X8664 => @core_theory.Target::x86_64()
  }
  insn => registry.lift(@mc.Context::create(target), insn).bil
}

///|
fn legacy_lifter(
  mode : @x86.Mode,
) -> (@mc.Insn) -> Array[@types.Stmt] raise @mc.LiftError {
  insn => @x86.lift_legacy(mode, insn.raw, addr=insn.addr, opcode=insn.name)
}

///|
let corpus64 : Array[Bytes] = [
  // moves
  b"\x48\x89\xd8", b"\x89\xd8", b"\x88\xdc", b"\x66\x89\xd8", b"\x4c\x89\xc0", b"\x8b\x03",
  b"\x48\x8b\x43\x08", b"\x89\x03", b"\x88\x23", b"\xc6\x03\x5a", b"\xc7\x03\x01\x00\x00\x00",
  b"\x48\xc7\xc0\xff\xff\xff\xff", b"\xb8\x78\x56\x34\x12", b"\x48\xb8\x88\x77\x66\x55\x44\x33\x22\x11",
  b"\xb0\x7f", b"\xb4\x7f", b"\x0f\xb6\xc3", b"\x0f\xb7\xc3", b"\x48\x0f\xbe\xc3",
  b"\x48\x63\xc3", b"\x0f\xbe\x03", b"\x48\x8d\x44\xcb\x10", b"\x8d\x43\xff", b"\x48\x8d\x04\x24",
  b"\x48\x93", b"\x87\xd8", b"\x48\x87\x03", b"\x86\xd8", b"\x0f\x44\xc3", b"\x48\x0f\x4f\xc3",
  b"\x0f\x42\x03", b"\x0f\xc8", b"\x48\x0f\xcb",
  // arithmetic and logic
   b"\x01\xd8", b"\x48\x01\xd8", b"\x00\xd8", b"\x66\x01\xd8", b"\x04\x7f", b"\x05\xff\xff\xff\x7f",
  b"\x48\x05\x00\x00\x00\x80", b"\x83\xc0\xff", b"\x48\x83\xc0\x01", b"\x80\xc3\x80",
  b"\x81\xc3\x78\x56\x34\x12", b"\x03\x03", b"\x01\x03", b"\x29\xd8", b"\x48\x29\xd8",
  b"\x2c\x01", b"\x83\xe8\x01", b"\x11\xd8", b"\x48\x11\xd8", b"\x19\xd8", b"\x48\x19\xd8",
  b"\x83\xd8\xff", b"\x39\xd8", b"\x48\x39\xd8", b"\x3c\x80", b"\x83\xf8\x00", b"\x38\xd8",
  b"\x21\xd8", b"\x48\x21\xd8", b"\x25\xf0\xf0\x00\x00", b"\x83\xe0\xf0", b"\x09\xd8",
  b"\x48\x83\xc8\xff", b"\x0c\x01", b"\x31\xd8", b"\x31\xc0", b"\x30\xe4", b"\x85\xc0",
  b"\x48\x85\xd8", b"\xa8\x80", b"\xf6\xc3\x01", b"\xf7\xc3\x00\x00\x01\x00", b"\x84\xc0",
  b"\xff\xc0", b"\x48\xff\xc0", b"\xfe\xc0", b"\xff\xc8", b"\x48\xff\xc9", b"\xf7\xd8",
  b"\x48\xf7\xd8", b"\xf6\xd8", b"\xf7\xd0", b"\x48\xf7\xd1", b"\xf6\xd0", b"\xfe\x03",
  b"\xff\x0b", b"\xf7\xe3", b"\x48\xf7\xe3", b"\xf6\xe3", b"\xf7\xeb", b"\x48\xf7\xeb",
  b"\x0f\xaf\xc3", b"\x48\x0f\xaf\xc3", b"\x6b\xc3\x03", b"\x69\xc3\x00\x01\x00\x00",
  b"\xf7\xf3", b"\x48\xf7\xf3", b"\xf6\xf3", b"\xf7\xfb", b"\x48\xf7\xfb",
  // shifts and rotates
   b"\xd1\xe0", b"\xc1\xe0\x04", b"\xd3\xe0", b"\x48\xd3\xe0", b"\xd1\xe8", b"\xc1\xe8\x1f",
  b"\xd3\xe8", b"\xd1\xf8", b"\xc1\xf8\x04", b"\xd3\xf8", b"\xd0\xe0", b"\xc0\xe8\x03",
  b"\x66\xd1\xe0", b"\x0f\xa4\xd8\x08", b"\x0f\xa5\xd8", b"\x0f\xac\xd8\x08", b"\x0f\xad\xd8",
  b"\x48\x0f\xa4\xd8\x08", b"\xd1\xc0", b"\xc1\xc0\x04", b"\xd3\xc0", b"\xd1\xc8",
  b"\xc1\xc8\x04", b"\xd0\xc0", b"\x48\xd1\xc0", b"\xd1\xd0", b"\xd1\xd8",
  // bit operations
   b"\x0f\xa3\xd8", b"\x48\x0f\xa3\xd8", b"\x0f\xba\xe0\x03", b"\x0f\xab\xd8", b"\x0f\xb3\xd8",
  b"\x0f\xbb\xd8", b"\x0f\xba\xe8\x03", b"\x0f\xba\xf0\x03", b"\x0f\xba\xf8\x03",
  b"\x0f\xa3\x03", b"\x0f\xab\x03", b"\x0f\xbc\xc3", b"\x0f\xbd\xc3", b"\x48\x0f\xbc\xc3",
  b"\xf3\x0f\xbc\xc3", b"\xf3\x0f\xbd\xc3", b"\xf3\x0f\xb8\xc3", b"\xf3\x48\x0f\xb8\xc3",
  // conditionals
   b"\x0f\x94\xc0", b"\x0f\x95\xc0", b"\x0f\x9c\xc0", b"\x0f\x9f\xc0", b"\x0f\x92\x03",
  b"\x0f\x96\xc1",
  // stack and control flow
   b"\x50", b"\x53", b"\x41\x50", b"\x6a\xff", b"\x68\x78\x56\x34\x12", b"\xff\x33",
  b"\x58", b"\x5b", b"\x41\x58", b"\x9c", b"\x9d", b"\xc9", b"\x55", b"\x5d", b"\xe8\x00\x01\x00\x00",
  b"\xff\xd0", b"\xff\x13", b"\xc3", b"\xc2\x10\x00", b"\xeb\xfe", b"\xe9\x00\x01\x00\x00",
  b"\xff\xe0", b"\xff\x23", b"\x74\x10", b"\x75\x10", b"\x0f\x84\x00\x01\x00\x00",
  b"\x7c\x05", b"\x7f\x05", b"\x76\x05", b"\x77\x05", b"\x78\x05", b"\x7a\x05", b"\x70\x05",
  b"\xe3\x05",
  // flags
   b"\xf8", b"\xf9", b"\xf5", b"\xfc", b"\xfd", b"\x9e", b"\x9f",
  // strings
   b"\xa4", b"\xa5", b"\x48\xa5", b"\xf3\xa4", b"\xf3\x48\xa5", b"\xaa", b"\xab",
  b"\xf3\xab", b"\xf3\x48\xab", b"\xa6", b"\xf3\xa6", b"\xf2\xa6", b"\xae", b"\xf2\xae",
  b"\xf3\xae", b"\xa7", b"\xac",
  // atomics and conversions
   b"\x0f\xb1\xd8", b"\x48\x0f\xb1\xd8", b"\x0f\xb1\x03", b"\x0f\xc7\x0b", b"\x0f\xc1\xd8",
  b"\x0f\xc1\x03", b"\x48\x0f\xc1\xd8", b"\x99", b"\x48\x99", b"\x98", b"\x48\x98",
  b"\x66\x98", b"\x66\x99",
  // misc
   b"\x90", b"\x0f\x1f\x44\x00\x00", b"\xf4", b"\xcc", b"\xcd\x80", b"\x0f\x05",
  b"\x0f\xa2", b"\x0f\x31", b"\xf3\x90", b"\xf3\x0f\x1e\xfa",
  // SSE and AVX
   b"\x66\x0f\xef\xc0", b"\x66\x0f\xef\xc1", b"\x66\x0f\x74\xc1", b"\x66\x0f\x75\xc1",
  b"\x66\x0f\x76\xc1", b"\x66\x0f\x64\xc1", b"\x66\x0f\xfe\xc1", b"\x66\x0f\xfc\xc1",
  b"\x66\x0f\xd4\xc1", b"\x66\x0f\xfa\xc1", b"\x66\x0f\xf8\xc1", b"\x66\x0f\xdb\xc1",
  b"\x66\x0f\xeb\xc1", b"\x66\x0f\xdf\xc1", b"\x66\x0f\xd7\xc1", b"\x66\x0f\x70\xc1\x1b",
  b"\xf3\x0f\x6f\x03", b"\x66\x0f\x6f\x03", b"\x66\x0f\x7f\x03", b"\xf3\x0f\x7f\x03",
  b"\x0f\x10\x03", b"\x0f\x11\x03", b"\x0f\x28\xc1", b"\x66\x0f\x6e\xc0", b"\x66\x48\x0f\x6e\xc0",
  b"\x66\x0f\x7e\xc0", b"\x66\x48\x0f\x7e\xc0", b"\xf3\x0f\x7e\xc1", b"\x66\x0f\xd6\xc1",
  b"\x0f\x16\x03", b"\x0f\x12\x03", b"\x66\x0f\x60\xc1", b"\x66\x0f\x61\xc1", b"\x66\x0f\x62\xc1",
  b"\x66\x0f\x6c\xc1", b"\x66\x0f\x68\xc1", b"\x66\x0f\x73\xf8\x08", b"\x66\x0f\x73\xd8\x08",
  b"\x66\x0f\x73\xd0\x04", b"\x66\x0f\x72\xe0\x04", b"\x66\x0f\x38\x00\xc1", b"\x66\x0f\x38\x17\xc1",
  b"\x66\x0f\xda\xc1", b"\x66\x0f\xde\xc1", b"\x66\x0f\xea\xc1", b"\x66\x0f\xee\xc1",
  b"\x66\x0f\xe0\xc1", b"\x66\x0f\x3a\x0f\xc1\x04", b"\x66\x0f\x3a\x63\xc1\x0c",
  b"\xf3\x0f\x10\xc1", b"\xf2\x0f\x10\xc1", b"\xf3\x0f\x10\x03", b"\x0f\x57\xc0",
  b"\xc5\xf9\xef\xc1", b"\xc5\xfe\x6f\x03", b"\xc5\xf9\x6f\xc1",
]

///|
let corpus32 : Array[Bytes] = [
  b"\x89\xd8", b"\x66\x89\xd8", b"\x88\xdc", b"\x8b\x4c\x24\x04", b"\x8d\x44\x24\x04",
  b"\xa1\x40\x00\x01\x00", b"\xa3\x40\x00\x01\x00", b"\xb8\x78\x56\x34\x12", b"\x0f\xb6\xc3",
  b"\x01\xd8", b"\x66\x01\xd8", b"\x11\xd8", b"\x19\xd8", b"\x29\xd8", b"\x39\xd8",
  b"\x21\xd8", b"\x09\xd8", b"\x31\xd8", b"\x85\xc0", b"\x40", b"\x48", b"\x43",
  b"\x4b", b"\xf7\xd8", b"\xf7\xe3", b"\xf7\xeb", b"\x0f\xaf\xc3", b"\xf7\xf3", b"\xf7\xfb",
  b"\xd1\xe0", b"\xd3\xe8", b"\xc1\xf8\x04", b"\xd1\xc0", b"\x0f\xa3\xd8", b"\x0f\xbc\xc3",
  b"\x0f\x94\xc0", b"\x50", b"\x58", b"\x6a\xff", b"\x68\x78\x56\x34\x12", b"\x9c",
  b"\x9d", b"\xc9", b"\xe8\x00\x01\x00\x00", b"\xff\xd0", b"\xff\x54\x24\x04", b"\xc3",
  b"\xc2\x08\x00", b"\x74\x10", b"\xe3\x05", b"\xeb\xfe", b"\xa5", b"\xf3\xa5", b"\xf3\xab",
  b"\xf2\xae", b"\x0f\xb1\xd9", b"\x0f\xc7\x0b", b"\x0f\xc1\xd8", b"\x99", b"\x98",
  b"\x66\x98", b"\x9e", b"\x9f", b"\xcd\x80", b"\x0f\xa2", b"\x0f\x34", b"\x60",
  b"\x61",
]

///|
test "differential: Basic decoder does not decode REX bytes as inc/dec" {
  // found by the differential test: in 64-bit mode the Basic decoder fell
  // back to its 32-bit decoder and decoded REX prefixes (40-4f) of
  // instructions it does not know as the one-byte INC/DEC forms
  let insn = basic_decode_opt("x86_64", b"\x41\x89\xc0")
  assert_true(!(insn is Some(insn) && insn.name() == "INC32r"))
  let insn = basic_decode_opt("x86_64", b"\x66\x48\x0f\x6e\xc0")
  assert_true(!(insn is Some(insn) && insn.name() == "DEC16r"))
  // the 32-bit forms are unchanged
  inspect(basic_decode("x86", b"\x41").name(), content="INC32r")
  inspect(basic_decode("x86", b"\x66\x48").name(), content="DEC16r")
  // the legacy lifter decodes them in 64-bit mode
  inspect(
    bil_text(lift64(b"\x41\x89\xc0")),
    content="R8:imm64 := pad:64[low:32[RAX:imm64]]",
  )
}

///|
test "differential: x86-64, combined providers vs Basic" {
  let report : DiffReport = {
    both: 0,
    only_ours: 0,
    only_basic: 0,
    neither: 0,
    basic_undecoded: 0,
    agree: 0,
    findings: [],
  }
  for bytes in corpus64 {
    diff_one(report, X8664, bytes, combined_lifter(X8664))
  }
  inspect(
    report_text(report),
    content=(
      #|both=227 agree=227 only_ours=5 only_basic=7 neither=52 basic_undecoded=52
      #|86 d8 (XCHG8rr): only Basic lifts
      #|d1 d0 (RCL32r1): only Basic lifts
      #|d1 d8 (RCR32r1): only Basic lifts
      #|f8 (CLC): only Basic lifts
      #|f9 (STC): only Basic lifts
      #|f5 (CMC): only Basic lifts
      #|fd (STD): only Basic lifts
      #|0f 28 c1 (MOVAPS): only ours lifts
      #|66 0f 73 d0 04 (PSRLQ): only ours lifts
      #|66 0f 72 e0 04 (PSRAD): only ours lifts
      #|66 0f 38 00 c1 (PSHUFB): only ours lifts
      #|66 0f 3a 0f c1 04 (PALIGNR): only ours lifts
    ),
  )
}

///|
test "differential: x86-64, legacy lifter vs Basic" {
  let report : DiffReport = {
    both: 0,
    only_ours: 0,
    only_basic: 0,
    neither: 0,
    basic_undecoded: 0,
    agree: 0,
    findings: [],
  }
  for bytes in corpus64 {
    diff_one(report, X8664, bytes, legacy_lifter(X8664))
  }
  inspect(
    report_text(report),
    content=(
      #|both=223 agree=223 only_ours=5 only_basic=11 neither=52 basic_undecoded=52
      #|86 d8 (XCHG8rr): only Basic lifts
      #|d1 d0 (RCL32r1): only Basic lifts
      #|d1 d8 (RCR32r1): only Basic lifts
      #|f8 (CLC): only Basic lifts
      #|f9 (STC): only Basic lifts
      #|f5 (CMC): only Basic lifts
      #|fd (STD): only Basic lifts
      #|99 (CDQ): only Basic lifts
      #|48 99 (CQO): only Basic lifts
      #|66 99 (CWD): only Basic lifts
      #|f3 0f 1e fa (ENDBR64): only Basic lifts
      #|0f 28 c1 (MOVAPS): only ours lifts
      #|66 0f 73 d0 04 (PSRLQ): only ours lifts
      #|66 0f 72 e0 04 (PSRAD): only ours lifts
      #|66 0f 38 00 c1 (PSHUFB): only ours lifts
      #|66 0f 3a 0f c1 04 (PALIGNR): only ours lifts
    ),
  )
}

///|
test "differential: x86, combined providers vs Basic" {
  let report : DiffReport = {
    both: 0,
    only_ours: 0,
    only_basic: 0,
    neither: 0,
    basic_undecoded: 0,
    agree: 0,
    findings: [],
  }
  for bytes in corpus32 {
    diff_one(report, X86, bytes, combined_lifter(X86))
  }
  inspect(
    report_text(report),
    content=(
      #|both=66 agree=66 only_ours=0 only_basic=0 neither=2 basic_undecoded=2
    ),
  )
}
