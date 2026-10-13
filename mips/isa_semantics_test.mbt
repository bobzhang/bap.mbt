// Regression tests of the deliberate fixes of upstream's MIPS semantics:
// real encodings (assembled by LLVM 22's `llvm-mc`, see the comments) are
// decoded, lifted and executed with `@types.exec_stmts` (via
// `run_program`), and the results are checked against the ISA, with the
// expected values computed independently.

///|
/// The big-endian bytes of `program`.
fn code_bytes(program : Array[UInt32]) -> Bytes {
  Bytes::makei(program.length() * 4, i => {
    (program[i / 4] >> (24 - 8 * (i % 4))).to_byte()
  })
}

///|
/// Run `program` at `base` from the registers `regs` (with the program
/// itself loaded in memory) and return the state and the exit address.
fn exec(
  program : Array[UInt32],
  regs : Array[(String, Int64)],
  base~ : UInt64 = 0x400000,
  arch~ : @mips.Arch = Mips32,
  r6~ : Bool = false,
  data? : (UInt64, Bytes),
) -> (@types.BilState, UInt64) raise {
  let width = match arch {
    Mips32 => 32
    Mips64 => 64
  }
  let mem = match data {
    Some((addr, bytes)) =>
      @types.BilMemory::from_bytes(addr_width=width, start=addr, bytes)
    None =>
      @types.BilMemory::from_bytes(
        addr_width=width,
        start=base,
        code_bytes(program),
      )
  }
  let mut state = @types.BilState::new().set("mem", BilMem(mem))
  for reg in regs {
    state = state.set(reg.0, BilWord(@types.Word::of_int64(reg.1, width~)))
  }
  run_program(program, base, state, arch~, r6~)
}

///|
/// The value of `name` in hexadecimal (without the width).
fn hex(state : @types.BilState, name : String) -> String {
  match state.get_word(name) {
    Some(w) => "0x" + (try! w.to_uint64()).to_string(radix=16)
    None => "<unset>"
  }
}

///|
fn hexes(state : @types.BilState, names : Array[String]) -> String {
  names.map(n => "\{n}=\{hex(state, n)}").join(" ")
}

///|
/// `A0 = 0xFFFF8123` (negative) and `A1 = 0x24`.
let operands32 : Array[(String, Int64)] = [("A0", 0xFFFF8123L), ("A1", 0x24L)]

///|
test "mips32: counting, sign-extension and set-on-less-than" {
  let (s, _) = exec(
    [
      0x70821020, // clz $2, $4
       0x70831821, // clo $3, $4
       0x7c042c20, // seb $5, $4
       0x7c043620, // seh $6, $4
       0x2887ffff, // slti $7, $4, -1
       0x28880005, // slti $8, $4, 5
       0x2c89ffff, // sltiu $9, $4, -1
    ],
    [("A0", 0xFFFF8123L)],
  )
  // clz/clo count from the most significant bit; seb/seh extend the low
  // byte/halfword; slti compares signed
  assert_eq(
    hexes(s, ["V0", "V1", "A1", "A2", "A3", "T0", "T1"]),
    "V0=0x0 V1=0x11 A1=0x23 A2=0xffff8123 A3=0x1 T0=0x1 T1=0x1",
  )
}

///|
test "mips32: multiplication and division produce the true high halves" {
  let (s, _) = exec(
    [
      0x00850018, // mult $4, $5
       0x00005010, // mfhi $10
       0x00005812, // mflo $11
       0x00850019, // multu $4, $5
       0x00006010, // mfhi $12
       0x70856802, // mul $13, $4, $5
       0x0085001a, // div $zero, $4, $5
       0x00007010, // mfhi $14
       0x00007812, // mflo $15
    ],
    operands32,
  )
  assert_eq(
    hexes(s, ["T2", "T3", "T4", "T5", "T6", "T7"]),
    "T2=0xffffffff T3=0xffee28ec T4=0x23 T5=0xffee28ec T6=0xfffffffb T7=0xfffffc7a",
  )
  // madd accumulates into HI:LO = 0x1:0x2
  let (s, _) = exec(
    [0x70850000], // madd $4, $5
    [..operands32, ("HI", 1L), ("LO", 2L)],
  )
  assert_eq(hexes(s, ["HI", "LO"]), "HI=0x0 LO=0xffee28ee")
}

///|
test "mips32: shifts, rotations, bit fields and byte swaps" {
  let (s, _) = exec(
    [
      0x00041100, // sll $2, $4, 4
       0x00a41807, // srav $3, $4, $5 (by 0x24 & 31 = 4)
       0x00a43004, // sllv $6, $4, $5
       0x00243a02, // rotr $7, $4, 8
       0x7c883900, // ext $8, $4, 4, 8
       0x7c897a04, // ins $9, $4, 8, 8
       0x7c0450a0, // wsbh $10, $4
       0x3c0b8001, // lui $11, 32769
    ],
    [..operands32, ("T1", 0x11223344L)],
  )
  assert_eq(
    hexes(s, ["V0", "V1", "A2", "A3", "T0", "T1", "T2", "T3"]),
    "V0=0xfff81230 V1=0xfffff812 A2=0xfff81230 A3=0x23ffff81 T0=0x12 T1=0x11222344 T2=0xffff2381 T3=0x80010000",
  )
}

///|
test "mips32: conditional moves and the zero register" {
  let (s, _) = exec(
    [
      0x0085600b, // movn $12, $4, $5 (A1 != 0: moves)
       0x0085680a, // movz $13, $4, $5 (A1 != 0: does not move)
       0x24800001, // addiu $zero, $4, 1 (discarded)
       0x00001021, // addu $2, $zero, $zero
    ],
    [..operands32, ("T4", 0x55L), ("T5", 0x66L)],
  )
  assert_eq(hexes(s, ["T4", "T5", "V0"]), "T4=0xffff8123 T5=0x66 V0=0x0")
}

///|
/// Where the branch at `0x400000` followed by a `nop` delay slot goes, and
/// the final state.
fn branch(
  word : UInt32,
  regs : Array[(String, Int64)],
  base~ : UInt64 = 0x400000,
) -> (@types.BilState, String) raise {
  let (s, exit) = exec([word, 0], regs, base~)
  (s, "0x" + exit.to_string(radix=16))
}

///|
test "mips32: branches compare signed values" {
  let outcomes = (word : UInt32, reg : String) => {
    [-5L, 0L, 5L]
    .map(v => {
      let (_, exit) = branch(word, [(reg, v)]) catch { _ => panic() }
      exit
    })
    .join(" ")
  }
  // taken: 0x400014, not taken: 0x400008
  inspect(outcomes(0x04800004, "A0"), content="0x400014 0x400008 0x400008") // bltz
  inspect(outcomes(0x04810004, "A0"), content="0x400008 0x400014 0x400014") // bgez
  inspect(outcomes(0x18a00004, "A1"), content="0x400014 0x400014 0x400008") // blez
  inspect(outcomes(0x1ca00004, "A1"), content="0x400008 0x400008 0x400014") // bgtz
  inspect(outcomes(0x04010004, "A0"), content="0x400014 0x400014 0x400014") // bgez $zero
}

///|
test "mips32: links and jumps" {
  // bgezal links even when the branch is not taken
  let (s, exit) = branch(0x04910004, [("A0", -5L)]) // bgezal $4, 16
  assert_eq(exit, "0x400008")
  assert_eq(hex(s, "RA"), "0x400008")
  // j/jal jump into the 256 MB region of the delay slot
  let (_, exit) = branch(0x08000040, [], base=0x10400000) // j 256
  assert_eq(exit, "0x10000100")
  let (s, exit) = branch(0x0c000040, [], base=0x10400000) // jal 256
  assert_eq(exit, "0x10000100")
  assert_eq(hex(s, "RA"), "0x10400008")
  // jalr $ra, $ra jumps to the old $ra
  let (s, exit) = branch(0x03e0f809, [("RA", 0x400100L)]) // jalr $ra
  assert_eq(exit, "0x400100")
  assert_eq(hex(s, "RA"), "0x400008")
}

///|
test "mips64: word operations sign-extend their results" {
  let (s, _) = exec(
    [
      0x00851021, // addu $2, $4, $5
       0x24830001, // addiu $3, $4, 1
       0x00043040, // sll $6, $4, 1
       0x3c078001, // lui $7, 32769
       0x00854023, // subu $8, $4, $5
       0x00850018, // mult $4, $5
       0x00004810, // mfhi $9
       0x00005012, // mflo $10
       0x7c051c20, // seb $3, $5
       0x28860000, // slti $6, $4, 0
    ],
    [("A0", 0x123456787FFFFFFFL), ("A1", 0x24L)],
    arch=Mips64,
  )
  assert_eq(
    hexes(s, ["V0", "A3", "T0", "T1", "T2", "V1", "A2"]),
    "V0=0xffffffff80000023 A3=0xffffffff80010000 T0=0x7fffffdb T1=0x11 T2=0xffffffffffffffdc V1=0x24 A2=0x0",
  )
}

///|
test "mips64: doubleword operations" {
  let (s, _) = exec(
    [
      0x0085001c, // dmult $4, $5
       0x00005810, // mfhi $11
       0x00006012, // mflo $12
       0x0005693c, // dsll32 $13, $5, 4
       0x00a47017, // dsrav $14, $4, $5
       0x7c8f3902, // dextu $15, $4, 36, 8
       0x7cb80f85, // dinsm $24, $5, 30, 4
    ],
    [("A0", 0x123456787FFFFFFFL), ("A1", 0x24L), ("T8", -1L)],
    arch=Mips64,
  )
  assert_eq(
    hexes(s, ["T3", "T4", "T5", "T6", "T7", "T8"]),
    "T3=0x2 T4=0x8f5c28f1ffffffdc T5=0x24000000000 T6=0x1234567 T7=0x67 T8=0xfffffffd3fffffff",
  )
  // lw sign-extends, lwu zero-extends
  let (s, _) = exec(
    [
      0x8fb90000, // lw $25, 0($sp)
       0x9fa20000, // lwu $2, 0($sp)
    ],
    [("SP", 0x7fff0000L)],
    arch=Mips64,
    data=(0x7fff0000UL, b"\x80\x00\x00\x01"),
  )
  assert_eq(hexes(s, ["T9", "V0"]), "T9=0xffffffff80000001 V0=0x80000001")
}

///|
test "mips32r6: three-operand multiplies and divides, and PC-relative forms" {
  let (s, _) = exec(
    [
      0x00851085, // 0x400000: lsa $2, $4, $5, 3
       0x008518d8, // 0x400004: muh $3, $4, $5
       0x00853099, // 0x400008: mulu $6, $4, $5
       0x008538d9, // 0x40000c: muhu $7, $4, $5
       0x00804050, // 0x400010: clz $8, $4
       0x7c044820, // 0x400014: bitswap $9, $4
       0x3c8a8000, // 0x400018: aui $10, $4, 32768
       0x00855835, // 0x40001c: seleqz $11, $4, $5
       0xed880002, // 0x400020: lwpc $12, 8 (loads the word at 0x400028)
       0xeda00002, // 0x400024: lapc $13, 8
       0xedde0001, // 0x400028: auipc $14, 1
       0xedff0001, // 0x40002c: aluipc $15, 1
       0x0085c09a, // 0x400030: div $24, $4, $5
       0x0085c8da, // 0x400034: mod $25, $4, $5
    ],
    operands32,
    r6=true,
  )
  assert_eq(
    hexes(s, ["V0", "V1", "A2", "A3", "T0", "T1", "T2", "T3"]),
    "V0=0xfffc093c V1=0xffffffff A2=0xffee28ec A3=0x23 T0=0x0 T1=0xffff81c4 T2=0x7fff8123 T3=0x0",
  )
  assert_eq(
    hexes(s, ["T4", "T5", "T6", "T7", "T8", "T9"]),
    "T4=0xedde0001 T5=0x40002c T6=0x410028 T7=0x410000 T8=0xfffffc7a T9=0xfffffffb",
  )
}

///|
test "mips32r6: compact branches have no delay slot and link cia + 4" {
  let run = (program : Array[UInt32], regs : Array[(String, Int64)]) => {
    exec(program, regs, r6=true)
  }
  // bltc $4, $5, 16: A0 < A1 (signed) is taken to 0x400014
  let (_, exit) = run([0x5c850004, 0], operands32)
  assert_eq(exit, 0x400014UL)
  // bgezalc $4, 16: not taken, links 0x400004, continues at 0x400004
  let (s, exit) = run([0x18840004], operands32)
  assert_eq(exit, 0x400004UL)
  assert_eq(hex(s, "RA"), "0x400004")
  // jic $5, -4 and jialc $5, 8 add a signed offset
  let (_, exit) = run([0xd805fffc], [("A1", 0x500000L)])
  assert_eq(exit, 0x4ffffcUL)
  let (s, exit) = run([0xf8050008], [("A1", 0x500000L)])
  assert_eq(exit, 0x500008UL)
  assert_eq(hex(s, "RA"), "0x400004")
  // balc/bc 16
  let (s, exit) = run([0xe8000004], [])
  assert_eq(exit, 0x400014UL)
  assert_eq(hex(s, "RA"), "0x400004")
  let (_, exit) = run([0xc8000004], [])
  assert_eq(exit, 0x400014UL)
  assert_eq(@mips.delay_slot("BLTC"), None)
  assert_eq(@mips.delay_slot("BEQ"), Some(1))
}
