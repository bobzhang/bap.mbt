// Test harness: lifts an instruction and evaluates the BIL on a machine
// state where every PowerPC register starts at zero, recording the target
// of the first executed jump (as BAP's `Bili` context `pc`).

///|
/// Result of evaluating lifted code.
struct Run {
  env : Map[String, @types.BilValue]
  mut jumped : UInt64?
}

///|
fn reg(name : String) -> @mc.Op {
  @mc.Op::reg(name)
}

///|
fn imm(value : Int64) -> @mc.Op {
  Imm(value)
}

///|
fn bits(a : @powerpc.AddrSize) -> Int {
  a.in_bits()
}

///|
/// `value` truncated to the register width of `a`.
fn trunc(a : @powerpc.AddrSize, value : UInt64) -> UInt64 {
  match a {
    R32 => value & 0xFFFF_FFFFUL
    R64 => value
  }
}

///|
fn word_of(width : Int, value : UInt64) -> @types.Word raise {
  @types.Word::of_uint64(width~, value)
}

///|
fn initial_env(a : @powerpc.AddrSize) -> Map[String, @types.BilValue] raise {
  let model = @powerpc.Model::of_addr_size(a)
  let env : Map[String, @types.BilValue] = Map([])
  let vars = [
    ..model.gpri,
    ..model.fpri,
    ..model.vri,
    ..model.cri,
    model.ctr,
    model.lr,
    model.tar,
    model.so,
    model.ca,
    model.ov,
    model.ca32,
    model.ov32,
  ]
  for v in vars {
    guard v.typ is Imm(width) else { fail("unexpected memory register") }
    env[v.name] = BilWord(word_of(width, 0))
  }
  env["mem"] = BilMem(@types.BilMemory::empty(addr_width=bits(a)))
  env
}

///|
fn eval_exp(
  env : Map[String, @types.BilValue],
  e : @types.Exp,
) -> @types.BilValue raise {
  match e.eval_value(env) {
    Ok(value) => value
    Err(reason) => fail("evaluation failed: \{reason} in \{e.to_string()}")
  }
}

///|
/// Execute `stmts`; returns `false` once a jump has been taken.
fn exec(run : Run, stmts : Array[@types.Stmt]) -> Bool raise {
  for stmt in stmts {
    match stmt {
      Move(v, e) => run.env[v.name] = eval_exp(run.env, e)
      Jmp(e) => {
        guard eval_exp(run.env, e) is BilWord(target) else {
          fail("jump to memory")
        }
        run.jumped = Some(target.to_uint64())
        return false
      }
      If(cond~, yes~, no~) => {
        guard eval_exp(run.env, cond) is BilWord(c) else {
          fail("condition is memory")
        }
        if !exec(run, if c.is_zero() { no } else { yes }) {
          return false
        }
      }
      Special(_) => ()
      CpuExn(_) | While(..) => fail("unexpected statement \{stmt.to_string()}")
    }
  }
  true
}

///|
/// Lift `name ops` for `a` (big endian) at `addr` and run it after the
/// initial register values `init` and memory contents `mem`
/// (`(address, value, size in bytes)`, stored big endian).
fn run(
  a : @powerpc.AddrSize,
  name : String,
  ops : Array[@mc.Op],
  init? : Array[(String, UInt64)] = [],
  mem? : Array[(UInt64, UInt64, Int)] = [],
  addr? : UInt64 = 0,
  word? : UInt,
) -> Run raise {
  let insn = match word {
    None => @mc.Insn::create(name, ops, addr~, size=4)
    Some(word) => decode_as(a, word, name, ops, addr~)
  }
  run_insn(a, insn, init~, mem~)
}

///|
/// Record forms are named `XXXo` by LLVM before version 10 and `XXX_rec`
/// since; the lifter accepts both.
fn canonical_name(name : String) -> String {
  match name.strip_suffix("o") {
    Some(base) if base.length() > 0 => base.to_owned() + "_rec"
    _ => name
  }
}

///|
fn show_op(op : @mc.Op) -> String {
  match op {
    Reg(name~, ..) => name
    Imm(v) => v.to_string()
    Fmm(v) => v.to_string()
  }
}

///|
/// `NAME op1, op2, ...` (immediates in decimal).
fn show_insn(name : String, ops : ArrayView[@mc.Op]) -> String {
  if ops.is_empty() {
    name
  } else {
    "\{name} \{ops.iter().map(show_op).collect().join(", ")}"
  }
}

///|
/// Big-endian encoding of an instruction word.
fn word_bytes(word : UInt) -> Bytes {
  [
    (word >> 24).to_byte(),
    (word >> 16).to_byte(),
    (word >> 8).to_byte(),
    word.to_byte(),
  ]
}

///|
/// Decode the big-endian `word` at `addr` in the mode of `a`.
fn decode_at(
  a : @powerpc.AddrSize,
  word : UInt,
  addr? : UInt64 = 0,
) -> @mc.Insn raise {
  match @powerpc.decode(word_bytes(word), addr, mode=a) {
    Some(insn) => insn
    None => fail("0x\{word.to_string(radix=16)} is not decoded")
  }
}

///|
/// Decode `word` (an encoding from the upstream tests) and check that the
/// decoder yields the instruction `name ops` constructed by hand.
fn decode_as(
  a : @powerpc.AddrSize,
  word : UInt,
  name : String,
  ops : Array[@mc.Op],
  addr? : UInt64 = 0,
) -> @mc.Insn raise {
  let insn = decode_at(a, word, addr~)
  assert_eq(
    show_insn(canonical_name(insn.name()), insn.ops()[:]),
    show_insn(canonical_name(name), ops[:]),
  )
  assert_eq(insn.size(), 4)
  assert_eq(insn.addr(), addr)
  insn
}

///|
/// Concatenate `(value, width)` fields, the most significant first, into an
/// instruction word (upstream `make_insn`/`make_bytes`).
fn enc(fields : Array[(Int, Int)]) -> UInt {
  let mut word = 0U
  let mut total = 0
  for f in fields {
    let (value, width) = f
    word = (word << width) | (value.reinterpret_as_uint() & ((1U << width) - 1))
    total += width
  }
  guard total == 32 else { abort("enc: \{total} bits") }
  word
}

///|
/// Lift the decoded `insn` for `a` (big endian) and run it after the
/// initial register values `init` and memory contents `mem` (see `run`).
fn run_insn(
  a : @powerpc.AddrSize,
  insn : @mc.Insn,
  init? : Array[(String, UInt64)] = [],
  mem? : Array[(UInt64, UInt64, Int)] = [],
) -> Run raise {
  let bil = @powerpc.lift(a, BigEndian, insn)
  let env = initial_env(a)
  for entry in init {
    let (name, value) = entry
    guard env.get(name) is Some(BilWord(old)) else {
      fail("unknown register \{name}")
    }
    env[name] = BilWord(word_of(old.width(), value))
  }
  for entry in mem {
    let (at, value, size) = entry
    guard env.get("mem") is Some(BilMem(memory)) else { fail("no memory") }
    let stored = memory.store(
      word_of(bits(a), at),
      word_of(size * 8, value),
      endian=BigEndian,
    )
    guard stored is Ok(memory) else { fail("store failed") }
    env["mem"] = BilMem(memory)
  }
  let result = { env, jumped: None, }
  ignore(exec(result, bil))
  result
}

///|
fn Run::word(self : Run, name : String) -> @types.Word raise {
  guard self.env.get(name) is Some(BilWord(w)) else {
    fail("register \{name} is not bound")
  }
  w
}

///|
/// Value of register `name`.
fn Run::get(self : Run, name : String) -> UInt64 raise {
  self.word(name).to_uint64()
}

///|
/// Assert that `name` holds `expected`.
fn Run::check(self : Run, name : String, expected : UInt64) -> Unit raise {
  let actual = self.get(name)
  if actual != expected {
    fail(
      "\{name}: expected 0x\{expected.to_string(radix=16)}, got 0x\{actual.to_string(radix=16)}",
    )
  }
}

///|
/// Assert the `CR0` LT/GT/EQ bits.
fn Run::check_cr0(
  self : Run,
  lt : UInt64,
  gt : UInt64,
  eq : UInt64,
) -> Unit raise {
  self.check("CR0LT", lt)
  self.check("CR0GT", gt)
  self.check("CR0EQ", eq)
}

///|
/// Load `size` bytes (big endian) from memory at `at`.
fn Run::load(
  self : Run,
  a : @powerpc.AddrSize,
  at : UInt64,
  size : Int,
) -> UInt64 raise {
  guard self.env.get("mem") is Some(BilMem(memory)) else { fail("no memory") }
  match memory.load(word_of(bits(a), at), endian=BigEndian, width=size * 8) {
    Ok(w) => w.to_uint64()
    Err(reason) => fail("load failed: \{reason}")
  }
}

///|
/// Assert that `size` bytes at `at` hold `expected`.
fn Run::check_mem(
  self : Run,
  a : @powerpc.AddrSize,
  at : UInt64,
  size : Int,
  expected : UInt64,
) -> Unit raise {
  let actual = self.load(a, at, size)
  if actual != expected {
    fail(
      "mem[0x\{at.to_string(radix=16)}]: expected 0x\{expected.to_string(radix=16)}, got 0x\{actual.to_string(radix=16)}",
    )
  }
}

///|
/// Assert the jump target (or its absence).
fn Run::check_jump(self : Run, expected : UInt64?) -> Unit raise {
  if self.jumped != expected {
    fail("jump: expected \{Repr(expected)}, got \{Repr(self.jumped)}")
  }
}

///|
let archs : Array[@powerpc.AddrSize] = [R32, R64]
