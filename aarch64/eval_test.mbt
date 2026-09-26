// End-to-end tests: decode AArch64 machine code, lift it with the AArch64
// Lisp semantics and evaluate the BIL.

///|
fn word64(v : Int64) -> @types.BilValue {
  BilWord(try! @types.Word::of_int64(width=64, v))
}

///|
/// Decode the words at `addr` and lift them with the Lisp semantics.
fn lift_program(
  words : Array[UInt],
  addr : UInt64,
) -> Array[(String, Array[@types.Stmt])] raise {
  let registry = @mc.Registry::new()
  @primus_lisp.register_semantics_providers(registry~)
  let target = @core_theory.Target::aarch64()
  let ctx = @mc.Context::create(target)
  let decoder = @aarch64.a64_decoder()
  assert_true(decoder.accepts(ctx))
  let result = []
  for k, w in words {
    let bytes = Bytes::makei(4, i => (w >> (8 * i)).to_byte())
    guard decoder.decode(ctx, bytes[:], addr + (4 * k).to_uint64())
      is Decoded(insn) else {
      fail("cannot decode \{w}")
    }
    result.push((insn.name, registry.lift(ctx, insn).bil()))
  }
  result
}

///|
test "decode, lift with the Lisp semantics and run an AArch64 sequence" {
  let program = lift_program(
    [
      0xD2800140, // movz x0, #10
       0xD28000E1, // movz x1, #7
       0x8B010002, // add x2, x0, x1
       0xF1000C43, // subs x3, x2, #3
       0x9B017C44, // mul x4, x2, x1
       0x9AC10C45, // sdiv x5, x2, x1
       0x92401C46, // and x6, x2, #0xff
       0xD37DF047, // lsl x7, x2, #3
       0x9A830028, // csel x8, x1, x3, eq
       0xAA0203E9, // mov x9, x2
       0xF90007E2, // str x2, [sp, #8]
       0xF94007EA, // ldr x10, [sp, #8]
       0xA9BF07E0, // stp x0, x1, [sp, #-16]!
       0xA8C133EB, // ldp x11, x12, [sp], #16
    ],
    0x400000,
  )
  inspect(
    program.map(p => p.0).join(" "),
    content="MOVZXi MOVZXi ADDXrs SUBSXri MADDXrrr SDIVXr ANDXri UBFMXri CSELXr ORRXrs STRXui LDRXui STPXpre LDPXpost",
  )
  let mut state = @types.BilState::new()
    .set("SP", word64(0x1000))
    .set("XZR", word64(0))
    .set("mem", BilMem(@types.BilMemory::empty(addr_width=64)))
  for p in program {
    state = match @types.exec_stmts(p.1, state~) {
      Ok(next) => next
      Err(reason) => fail("\{p.0}: \{reason}")
    }
  }
  let get = (name : String) => {
    match state.get_word(name) {
      Some(w) => w.to_uint64().to_string()
      None => "?"
    }
  }
  inspect(
    ["X2", "X3", "X4", "X5", "X6", "X7", "X8", "X9", "X10", "X11", "X12", "SP"]
    .map(r => "\{r}=\{get(r)}")
    .join(" "),
    content="X2=17 X3=14 X4=119 X5=2 X6=17 X7=136 X8=14 X9=17 X10=17 X11=10 X12=7 SP=4096",
  )
  inspect(
    ["NF", "ZF", "CF", "VF"].map(f => "\{f}=\{get(f)}").join(" "),
    content="NF=0 ZF=0 CF=1 VF=0",
  )
}

///|
test "decoded AArch64 branches lift to jumps" {
  let program = lift_program(
    [
      0x14000002, // b #8
       0x94000000, // bl #0
       0x54000041, // b.ne #8
       0xB4000040, // cbz x0, #8
       0xD65F03C0, // ret
    ],
    0x400000,
  )
  for p in program {
    let has_jump = p.1.iter().any(s => s is (Jmp(_) | If(_)))
    assert_true(has_jump, msg="\{p.0} has no jump")
  }
}
