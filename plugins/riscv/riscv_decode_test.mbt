// End-to-end tests: RISC-V machine code decoded by the native decoder
// (`@rv.decode`), lifted by the Primus Lisp semantics of `riscv.lisp` and
// executed by the BIL interpreter.

///|
/// A registry with the RISC-V semantics.
fn semantics() -> @mc.Registry raise {
  let registry = @mc.Registry::new()
  guard @riscv.enable(registry~) is Ok(_) else { fail("not enabled") }
  registry
}

///|
/// Decode the little-endian `code` loaded at `base` into instructions.
fn decode_all(
  code : Bytes,
  base : UInt64,
  xlen? : @rv.Xlen = RV64,
) -> Array[@mc.Insn] raise {
  let insns = []
  let mut offset = 0
  while offset < code.length() {
    guard @rv.decode(code[offset:], base + offset.to_uint64(), xlen~)
      is Some(insn) else {
      fail("invalid instruction at offset \{offset}")
    }
    insns.push(insn)
    offset += insn.size
  }
  insns
}

///|
test "decoded instructions lift with the Lisp semantics" {
  let registry = semantics()
  let target = @core_theory.Target::riscv64()
  let ctx = @mc.Context::create(target)
  // a function prologue/epilogue mixing compressed and 32-bit forms
  let code = b"\x41\x11\x06\xe4\x13\x05\x15\x00\x3b\x05\xb5\x00\xa2\x60\x41\x01\x82\x80"
  let lines = decode_all(code, 0x10000UL).map(insn => {
    let bil = registry.lift(ctx, insn).bil()
    "\{insn.name} (\{insn.assembly}): \{bil.map(s => s.to_string()).join("; ")}"
  })
  inspect(
    lines.join("\n"),
    content=(
      #|C_ADDI (addi sp, sp, -16): X2:imm64 := (X2:imm64 + 0xFFFFFFFFFFFFFFF0:64u)
      #|C_SDSP (sd ra, 8(sp)): mem:mem64x8 := store(mem:mem64x8, (X2:imm64 + 8:64u), X1:imm64)
      #|ADDI (addi a0, a0, 1): X10:imm64 := (X10:imm64 + 1:64u)
      #|ADDW (addw a0, a0, a1): X10:imm64 := extend:64[low:32[(X10:imm64 + X11:imm64)]]
      #|C_LDSP (ld ra, 8(sp)): X1:imm64 := load(mem:mem64x8, (X2:imm64 + 8:64u)):imm64
      #|C_ADDI (addi sp, sp, 16): X2:imm64 := (X2:imm64 + 0x10:64u)
      #|C_JR (ret): jmp X1:imm64
    ),
  )
}

///|
/// Execute the statements of one instruction; returns the new state and
/// the jump target, if a jump was taken.
fn step(
  stmts : Array[@types.Stmt],
  state : @types.BilState,
) -> (@types.BilState, UInt64?) raise {
  let mut state = state
  let mut target : UInt64? = None
  for stmt in stmts {
    match stmt {
      Jmp(dst) =>
        match dst.eval_value(state.values()) {
          Ok(BilWord(w)) => target = Some(w.to_uint64())
          _ => fail("bad jump target")
        }
      If(cond~, yes~, no~) =>
        match cond.eval_value(state.values()) {
          Ok(BilWord(w)) => {
            let (next, taken) = step(if w.is_zero() { no } else { yes }, state)
            state = next
            if taken is Some(_) {
              target = taken
            }
          }
          _ => fail("bad condition")
        }
      _ =>
        match @types.exec_stmts([stmt], state~) {
          Ok(next) => state = next
          Err(msg) => fail(msg)
        }
    }
  }
  (state, target)
}

///|
test "decode, lift and run a loop summing an array" {
  let registry = semantics()
  let ctx = @mc.Context::create(@core_theory.Target::riscv64())
  // 0x10000: li a2, 0        (c.li)
  // 0x10002: beqz a1, 16     (c.beqz, to 0x10012)
  // 0x10004: ld a3, 0(a0)    (c.ld)
  // 0x10006: add a2, a2, a3  (c.add)
  // 0x10008: addi a0, a0, 8  (c.addi)
  // 0x1000a: addi a1, a1, -1 (c.addi)
  // 0x1000c: bnez a1, -8     (bne, to 0x10004)
  // 0x10010: mv a0, a2       (c.mv)
  // 0x10012: ret             (c.jr)
  let code = b"\x01\x46\x81\xc9\x14\x61\x36\x96\x21\x05\xfd\x15\xe3\x9c\x05\xfe\x32\x85\x82\x80"
  let base = 0x10000UL
  let insns = decode_all(code, base)
  inspect(
    insns.map(insn => insn.assembly).join("; "),
    content=(
      #|li a2, 0; beqz a1, 16; ld a3, 0(a0); add a2, a2, a3; addi a0, a0, 8; addi a1, a1, -1; bnez a1, -8; mv a0, a2; ret
    ),
  )
  let word = (v : Int64) => {
    @types.BilValue::BilWord(@types.Word::of_int64(v, width=64))
  }
  // three doublewords at 0x20000: 5, 7 and 30
  let data : Bytes = b"\x05\x00\x00\x00\x00\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x1e\x00\x00\x00\x00\x00\x00\x00"
  let mem = @types.BilMemory::from_bytes(addr_width=64, start=0x20000UL, data)
  let mut state = @types.BilState::new()
    .set("X0", word(0L))
    .set("X1", word(0x40000L))
    .set("X10", word(0x20000L))
    .set("X11", word(3L))
    .set("mem", BilMem(mem))
  let by_addr : Map[UInt64, @mc.Insn] = Map::from_array(
    insns.map(insn => (insn.addr, insn)),
  )
  let mut pc = base
  let mut steps = 0
  while by_addr.get(pc) is Some(insn) {
    steps += 1
    if steps > 100 {
      fail("too many steps")
    }
    let bil = registry.lift(ctx, insn).bil()
    let (next, target) = step(bil, state)
    state = next
    pc = target.unwrap_or(insn.next_addr())
  }
  assert_eq(pc, 0x40000UL)
  let result = state
    .get_word("X10")
    .map(w => w.to_string())
    .unwrap_or("<unset>")
  inspect(
    result,
    content=(
      #|0x2A:64u
    ),
  )
}
