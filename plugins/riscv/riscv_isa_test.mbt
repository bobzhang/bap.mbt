// Regression tests of the deliberate fixes of upstream's `riscv.lisp`:
// real encodings (assembled by LLVM 22's `llvm-mc`, see the comments) are
// decoded, lifted with the Lisp semantics and executed with
// `@types.exec_stmts` (via `step`), and the results are checked against
// the ISA, with the expected values computed independently.

///|
/// Run the little-endian `code` loaded at `base` until control leaves it,
/// from the registers `regs` and the memory `data` at `data_addr`; returns
/// the state and the exit address. `X0` is left unbound, so that reading it
/// as a variable fails.
fn run_rv(
  code : Bytes,
  regs : Array[(String, Int64)],
  base? : UInt64 = 0x10000,
  xlen? : @rv.Xlen = RV64,
  data_addr? : UInt64 = 0x7fff0000,
  data? : Bytes = Bytes::make(16, b'\x00'),
) -> (@types.BilState, UInt64) raise {
  let registry = semantics()
  let (target, width) = match xlen {
    RV64 => (@core_theory.Target::riscv64(), 64)
    RV32 => (@core_theory.Target::riscv32(), 32)
  }
  let ctx = @mc.Context::create(target)
  let insns = decode_all(code, base, xlen~)
  let by_addr : Map[UInt64, @mc.Insn] = Map::from_array(
    insns.map(insn => (insn.addr, insn)),
  )
  let mem = @types.BilMemory::from_bytes(
    addr_width=width,
    start=data_addr,
    data,
  )
  let mut state = @types.BilState::new().set("mem", BilMem(mem))
  for reg in regs {
    state = state.set(reg.0, BilWord(@types.Word::of_int64(reg.1, width~)))
  }
  let mut pc = base
  let mut steps = 0
  while by_addr.get(pc) is Some(insn) {
    steps += 1
    if steps > 100 {
      fail("too many steps")
    }
    let (next, target) = step(registry.lift(ctx, insn).bil(), state)
    state = next
    pc = target.unwrap_or(insn.next_addr())
  }
  (state, pc)
}

///|
/// The little-endian encoding of the `(value, size)` instructions.
fn encode(insns : Array[(UInt, Int)]) -> Bytes {
  let out = []
  for insn in insns {
    let (value, size) = insn
    for i in 0..<size {
      out.push((value >> (8 * i)).to_byte())
    }
  }
  Bytes::from_array(out)
}

///|
fn rv_hex(state : @types.BilState, names : Array[String]) -> String {
  names
  .map(n => {
    match state.get_word(n) {
      Some(w) => "\{n}=0x" + (try! w.to_uint64()).to_string(radix=16)
      None => "\{n}=<unset>"
    }
  })
  .join(" ")
}

///|
test "rv64: upper immediates, comparisons, M extension and word shifts" {
  let code = encode([
    (0x800005b7, 4), // 0x10000: lui a1, 524288
    (0x00001617, 4), // 0x10004: auipc a2, 1
    (0xfffff697, 4), // 0x10008: auipc a3, 1048575
    (0x00052713, 4), // slti a4, a0, 0
    (0x00153793, 4), // sltiu a5, a0, 1
    (0x00052833, 4), // slt a6, a0, zero
    (0x00a038b3, 4), // sltu a7, zero, a0
    (0x0255093b, 4), // mulw s2, a0, t0
    (0x025519b3, 4), // mulh s3, a0, t0
    (0x02553a33, 4), // mulhu s4, a0, t0
    (0x02552ab3, 4), // mulhsu s5, a0, t0
    (0x02054b33, 4), // div s6, a0, zero
    (0x02056bb3, 4), // rem s7, a0, zero
    (0x02554c3b, 4), // divw s8, a0, t0
    (0x02557cbb, 4), // remuw s9, a0, t0
    (0x00551d3b, 4), // sllw s10, a0, t0
    (0x00555dbb, 4), // srlw s11, a0, t0
    (0x40555e3b, 4), // sraw t3, a0, t0
    (0x40455e9b, 4), // sraiw t4, a0, 4
    (0x00629f33, 4), // sll t5, t0, t1 (by 0x44 & 63 = 4)
  ])
  let (s, _) = run_rv(code, [
    ("X10", 0xFFFFFFFF80000001L),
    ("X5", 0x21L),
    ("X6", 0x44L),
  ])
  assert_eq(
    rv_hex(s, ["X11", "X12", "X13", "X14", "X15", "X16", "X17"]),
    "X11=0xffffffff80000000 X12=0x11004 X13=0xf008 X14=0x1 X15=0x0 X16=0x1 X17=0x1",
  )
  assert_eq(
    rv_hex(s, ["X18", "X19", "X20", "X21", "X22", "X23"]),
    "X18=0xffffffff80000021 X19=0xffffffffffffffff X20=0x20 X21=0xffffffffffffffff X22=0xffffffffffffffff X23=0xffffffff80000001",
  )
  assert_eq(
    rv_hex(s, ["X24", "X25", "X26", "X27", "X28", "X29", "X30"]),
    "X24=0xfffffffffc1f07c2 X25=0x3 X26=0x2 X27=0x40000000 X28=0xffffffffc0000000 X29=0xfffffffff8000000 X30=0x210",
  )
}

///|
test "rv64: loads extend by their width" {
  let code = encode([
    (0x00012f83, 4), // lw t6, 0(sp)
    (0x00411403, 4), // lh s0, 4(sp)
    (0x00415483, 4), // lhu s1, 4(sp)
    (0x4202, 2), // c.lwsp tp, 0(sp)
  ])
  let (s, _) = run_rv(
    code,
    [("X2", 0x7fff0000L)],
    data=b"\x01\x00\x00\x80\x01\x80\x00\x00",
  )
  assert_eq(
    rv_hex(s, ["X31", "X8", "X9", "X4"]),
    "X31=0xffffffff80000001 X8=0xffffffffffff8001 X9=0x8001 X4=0xffffffff80000001",
  )
}

///|
test "rv64: signed and unsigned branches" {
  let exit = (word : UInt) => {
    let (_, pc) = run_rv(encode([(word, 4)]), [("X10", -1L), ("X11", 1L)]) catch {
      _ => panic()
    }
    "0x" + pc.to_string(radix=16)
  }
  // taken: 0x10008, not taken: 0x10004
  inspect(exit(0x00b54463), content="0x10008") // blt a0, a1, 8
  inspect(exit(0x00b55463), content="0x10004") // bge a0, a1, 8
  inspect(exit(0x00b56463), content="0x10004") // bltu a0, a1, 8
  inspect(exit(0x00b57463), content="0x10008") // bgeu a0, a1, 8
}

///|
test "rv64: indirect jumps and the zero register" {
  // jalr ra, 0(ra): the target is the old ra (with bit 0 cleared)
  let (s, pc) = run_rv(encode([(0x000080e7, 4)]), [("X1", 0x20001L)])
  assert_eq(pc, 0x20000UL)
  assert_eq(rv_hex(s, ["X1"]), "X1=0x10004")
  // jalr ra, 3(a0) jumps to (a0 + 3) & ~1
  let (_, pc) = run_rv(encode([(0x003500e7, 4)]), [("X10", 0x20000L)])
  assert_eq(pc, 0x20002UL)
  // c.jalr ra
  let (s, pc) = run_rv(encode([(0x9082, 2)]), [("X1", 0x20000L)])
  assert_eq(pc, 0x20000UL)
  assert_eq(rv_hex(s, ["X1"]), "X1=0x10002")
  // `j 8` (jal zero, 8) does not write the zero register, and `li a0, 5`
  // (addi a0, zero, 5) reads it as zero
  let code = encode([
    (0x0080006f, 4), // jal zero, 8
    (0x00000013, 4), // nop
    (0x00500513, 4), // addi a0, zero, 5
  ])
  let (s, _) = run_rv(code, [])
  assert_eq(rv_hex(s, ["X10", "X0"]), "X10=0x5 X0=<unset>")
}

///|
test "rv32: loads and stores move 32 and 16 bits" {
  let code = encode([
    (0x00012583, 4), // lw a1, 0(sp)
    (0x00411603, 4), // lh a2, 4(sp)
    (0x00a12423, 4), // sw a0, 8(sp)
    (0x00a11623, 4), // sh a0, 12(sp)
    (0x800006b7, 4), // lui a3, 524288
    (0x4398, 2), // c.lw a4, 0(a5)
  ])
  let (s, _) = run_rv(
    code,
    [("X2", 0x7fff0000L), ("X15", 0x7fff0000L), ("X10", 0x12345678L)],
    xlen=RV32,
    data=b"\x01\x00\x00\x80\x01\x80\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00",
  )
  assert_eq(
    rv_hex(s, ["X11", "X12", "X13", "X14"]),
    "X11=0x80000001 X12=0xffff8001 X13=0x80000000 X14=0x80000001",
  )
  guard s.get_memory("mem") is Some(mem) else { fail("no memory") }
  let load = (addr : UInt64) => {
    let a = @types.Word::of_uint64(width=32, addr) catch { _ => panic() }
    match mem.load(a, endian=LittleEndian, width=32) {
      Ok(w) => "0x" + (try! w.to_uint64()).to_string(radix=16)
      Err(e) => e
    }
  }
  assert_eq(load(0x7fff0008UL), "0x12345678")
  assert_eq(load(0x7fff000cUL), "0x5678")
}
