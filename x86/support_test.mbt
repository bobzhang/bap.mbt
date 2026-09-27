// Test support: a small BIL interpreter that tolerates `unknown`
// expressions (undefined flags) and records jumps and CPU exceptions, and
// helpers to build concrete machine states.

///|
/// The result of executing the semantics of one instruction.
struct Outcome {
  values : Map[String, @types.BilValue]
  /// variables whose value is undefined after the instruction
  undefined : Map[String, Unit]
  /// the jump target, if the instruction jumped
  jump : UInt64?
  /// the CPU exception, if one was raised
  exn : Int?
  /// specials (e.g. intrinsics) executed
  specials : Array[String]
}

///|
suberror Indeterminate {
  Indeterminate(String)
}

///|
fn outcome_new(values : Map[String, @types.BilValue]) -> Outcome {
  { values, undefined: Map([]), jump: None, exn: None, specials: [], }
}

///|
/// Evaluate `e`; `None` when the value is undefined (it depends on an
/// `unknown` expression or on an undefined variable).
fn eval(o : Outcome, e : @types.Exp) -> @types.BilValue? raise {
  match e.eval_value(o.values) {
    Ok(v) => Some(v)
    Err(reason) =>
      if reason.has_prefix("unknown expression") ||
        reason.has_prefix("uninitialized memory") ||
        e.free_vars().iter().any(v => o.undefined.contains(v.name)) {
        None
      } else {
        fail("evaluation failed: \{reason} in \{e.to_string()}")
      }
  }
}

///|
fn eval_word(o : Outcome, e : @types.Exp) -> @types.Word? raise {
  match eval(o, e) {
    Some(BilWord(w)) => Some(w)
    Some(BilMem(_)) => fail("expected a word")
    None => None
  }
}

///|
/// Execute `stmts`; returns `false` when execution stopped (jump or CPU
/// exception).
fn exec_seq(
  o : Outcome,
  stmts : Array[@types.Stmt],
  fuel : Ref[Int],
) -> Bool raise {
  for stmt in stmts {
    fuel.val -= 1
    if fuel.val < 0 {
      fail("fuel exhausted")
    }
    match stmt {
      Move(v, e) =>
        match eval(o, e) {
          Some(value) => {
            o.values[v.name] = value
            o.undefined.remove(v.name)
          }
          None => {
            o.values.remove(v.name)
            o.undefined[v.name] = ()
          }
        }
      Jmp(e) => {
        match eval_word(o, e) {
          Some(w) => {
            let o2 = o
            o2.values["$jump"] = BilWord(w)
          }
          None => raise Indeterminate("jump to an undefined address")
        }
        return false
      }
      CpuExn(n) => {
        o.values["$exn"] = BilWord(
          @types.Word::of_uint64(width=8, n.to_uint64()),
        )
        return false
      }
      Special(s) => o.specials.push(s)
      If(cond~, yes~, no~) =>
        match eval_word(o, cond) {
          Some(w) =>
            if !exec_seq(o, if w.is_zero() { no } else { yes }, fuel) {
              return false
            }
          None => raise Indeterminate("branch on an undefined condition")
        }
      While(cond~, body~) =>
        while true {
          match eval_word(o, cond) {
            Some(w) =>
              if w.is_zero() {
                break
              } else if !exec_seq(o, body, fuel) {
                return false
              }
            None => raise Indeterminate("loop on an undefined condition")
          }
        }
    }
  }
  true
}

///|
fn run(
  stmts : Array[@types.Stmt],
  init : Map[String, @types.BilValue],
) -> Outcome raise {
  let o = outcome_new(init.copy())
  exec_seq(o, stmts, Ref(100000)) |> ignore
  let jump = match o.values.get("$jump") {
    Some(BilWord(w)) => Some(w.to_uint64())
    _ => None
  }
  let exn = match o.values.get("$exn") {
    Some(BilWord(w)) => Some(w.to_uint64().to_int())
    _ => None
  }
  o.values.remove("$jump")
  o.values.remove("$exn")
  { ..o, jump, exn, }
}

///|
fn word(width : Int, value : UInt64) -> @types.BilValue {
  BilWord(try! @types.Word::of_uint64(width~, value))
}

///|
/// Base address of the data memory of the test states.
const DATA : UInt64 = 0x10000

///|
/// Base address of the stack memory of the test states.
const STACK : UInt64 = 0x20000

///|
/// A deterministic machine state: general purpose registers with
/// distinct values, flags from `flag_bits` (CF, PF, AF, ZF, SF, OF, DF in
/// bits 0-6), segment bases, vector registers and two initialized memory
/// regions (1024 bytes each, from 256 bytes below `DATA` and `STACK`).
fn machine(
  mode : @x86.Mode,
  regs? : Array[(String, UInt64)] = [],
  flag_bits? : Int = 0,
  seed? : Int = 1,
) -> Map[String, @types.BilValue] {
  let w = mode.width()
  let values : Map[String, @types.BilValue] = Map([])
  for i, v in @x86.gprs(mode) {
    let x = (0x0123456789ABCDEFUL * (i + seed).to_uint64()) ^
      0x5A5A5A5A5A5A5A5AUL
    values[v.name] = word(w, x)
  }
  for i, v in @x86.flags() {
    values[v.name] = word(1, ((flag_bits >> i) & 1).to_uint64())
  }
  for i, v in @x86.vector_registers(mode) {
    let x = 0x1111111111111111UL * (i + seed).to_uint64()
    let bv = try! @bitvec.of_uint64(width=256, x)
    let bv = bv.lshift(128)
    let bv = try! bv.bit_or(try! @bitvec.of_uint64(width=256, x ^ 0xFFFF0000UL))
    values[v.name] = BilWord(@types.Word::from_bitvec(bv))
  }
  values["FS_BASE"] = word(w, 0)
  values["GS_BASE"] = word(w, 0)
  for s in ["CS", "DS", "ES", "FS", "GS", "SS"] {
    values[s] = word(16, 0x2b)
  }
  values["FPU_CONTROL"] = word(16, 0x37f)
  values["MXCSR"] = word(32, 0x1f80)
  values["mem"] = BilMem(initial_memory(w, seed))
  for r in regs {
    let (name, v) = r
    let width = match values.get(name) {
      Some(BilWord(x)) => x.width()
      _ => if name.length() == 2 { 1 } else { w }
    }
    values[name] = word(width, v)
  }
  values
}

///|
fn get_word(o : Outcome, name : String) -> UInt64 raise {
  match o.values.get(name) {
    Some(BilWord(w)) => w.to_uint64()
    _ => fail("\{name} is undefined or not a word")
  }
}

///|
fn get_flag(o : Outcome, name : String) -> Int raise {
  get_word(o, name).to_int()
}

///|
fn load_mem(o : Outcome, addr : UInt64, bytes : Int) -> UInt64 raise {
  match o.values.get("mem") {
    Some(BilMem(m)) => {
      let mut v = 0UL
      for i in 0..<bytes {
        match m.cell(addr + i.to_uint64()) {
          Some(b) => v = v | (b.to_uint64() << (8 * i))
          None => fail("uninitialized memory")
        }
      }
      v
    }
    _ => fail("no memory")
  }
}

///|
fn lift64(bytes : Bytes, addr? : UInt64 = 0x400000) -> Array[@types.Stmt] raise {
  @x86.lift_legacy(X8664, bytes, addr~)
}

///|
fn lift32(
  bytes : Bytes,
  addr? : UInt64 = 0x8048000,
) -> Array[@types.Stmt] raise {
  @x86.lift_legacy(X86, bytes, addr~)
}

///|
/// Lift with the legacy lifter and run on a machine state.
fn exec64(
  bytes : Bytes,
  regs? : Array[(String, UInt64)] = [],
  flag_bits? : Int = 0,
  addr? : UInt64 = 0x400000,
) -> Outcome raise {
  run(lift64(bytes, addr~), machine(X8664, regs~, flag_bits~))
}

///|
fn exec32(
  bytes : Bytes,
  regs? : Array[(String, UInt64)] = [],
  flag_bits? : Int = 0,
  addr? : UInt64 = 0x8048000,
) -> Outcome raise {
  run(lift32(bytes, addr~), machine(X86, regs~, flag_bits~))
}

///|
/// Decode one instruction with the project's Basic decoder (`x86` or
/// `x86_64` triple): `None` when the decoder reports an invalid
/// instruction.
fn basic_decode_opt(
  triple : String,
  bytes : Bytes,
  addr? : UInt64 = 0x400000,
) -> @project.ProjectDisassemblyInstruction? raise {
  let disasm = match
    @project.ProjectDisassemblyBasic::create(triple, backend="llvm") {
    Ok(d) => d
    Err(r) => fail(r)
  }
  let memory = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=addr,
    bytes,
  )
  match disasm.insn_of_mem(memory) {
    Ok(result) => result.instruction()
    Err(r) => fail(r)
  }
}

///|
/// Decode one instruction with the project's Basic decoder (`x86` or
/// `x86_64` triple).
fn basic_decode(
  triple : String,
  bytes : Bytes,
  addr? : UInt64 = 0x400000,
) -> @project.ProjectDisassemblyInstruction raise {
  match basic_decode_opt(triple, bytes, addr~) {
    Some(i) => i
    None => fail("no instruction decoded")
  }
}

///|
/// Decode with the Basic decoder and convert to an `@mc.Insn`.
fn mc_insn(
  triple : String,
  bytes : Bytes,
  addr? : UInt64 = 0x400000,
) -> @mc.Insn raise {
  basic_decode(triple, bytes, addr~).to_mc_insn()
}

///|
fn ops_text(insn : @mc.Insn) -> String {
  "\{insn.name} [\{insn.ops.map(o => o.to_string()).join(", ")}]"
}

///|
fn bil_text(stmts : Array[@types.Stmt]) -> String {
  stmts.map(s => s.to_string()).join("\n")
}

///|
fn flags_text(o : Outcome) -> String {
  let parts = []
  for f in ["CF", "PF", "AF", "ZF", "SF", "OF", "DF"] {
    match o.values.get(f) {
      Some(BilWord(w)) => parts.push("\{f}=\{try! w.to_uint64()}")
      _ => parts.push("\{f}=?")
    }
  }
  parts.join(" ")
}

///|
let memory_cache : Map[(Int, Int), @types.BilMemory] = Map([])

///|
/// The initial memory of the test states: two 1024-byte regions starting
/// 256 bytes below `DATA` and `STACK`, cached per address width and seed.
fn initial_memory(w : Int, seed : Int) -> @types.BilMemory {
  match memory_cache.get((w, seed)) {
    Some(m) => m
    None => {
      let data = Bytes::makei(1024, i => ((i * 37 + seed * 11) & 0xff).to_byte())
      let stack = Bytes::makei(1024, i => ((i * 91 + seed * 7) & 0xff).to_byte())
      let mem = @types.BilMemory::from_bytes(
        addr_width=w,
        start=DATA - 256,
        data,
      )
      let word = try! @types.Word::from_bytes(stack, endian=LittleEndian)
      let mem = match
        mem.store(
          try! @types.Word::of_uint64(width=w, STACK - 256),
          word,
          endian=LittleEndian,
        ) {
        Ok(m) => m
        Err(e) => abort(e)
      }
      memory_cache[(w, seed)] = mem
      mem
    }
  }
}
