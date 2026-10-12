///|
fn bil_var(name : String, width : Int32) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
fn bil_int(width : Int32, n : Int32) -> @types.Exp raise {
  Int(@types.Word::of_int(width~, n))
}

///|
test "parser: reflecting BIL into the BIL theory" {
  let state = @knowledge.State::new()
  let r0 = bil_var("R0", 32)
  let r1 = bil_var("R1", 32)
  let zf = bil_var("ZF", 1)
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
  let t = bil_var("t", 32)
  let program : Array[@types.Stmt] = [
    Move(r0, BinOp(Plus, Var(r0), bil_int(32, 1))),
    Move(zf, BinOp(Eq, Var(r0), bil_int(32, 0))),
    Move(r1, Let(t, Var(r0), BinOp(Times, Var(t), Var(t)))),
    If(cond=Var(zf), yes=[Move(r1, bil_int(32, 1))], no=[]),
    While(cond=BinOp(Lt, Var(r1), bil_int(32, 10)), body=[
      Move(r1, BinOp(Plus, Var(r1), bil_int(32, 1))),
    ]),
    Move(
      mem,
      Store(
        mem=Var(mem),
        addr=Var(r0),
        value=Extract(hi=7, lo=0, exp=Var(r1)),
        endian=LittleEndian,
      ),
    ),
    Move(r1, Load(mem=Var(mem), addr=Var(r0), endian=BigEndian, typ=Imm(32))),
    Move(
      r1,
      Concat(
        high=Cast(kind=Low, width=16, exp=Var(r0)),
        low=Cast(kind=High, width=16, exp=Var(r1)),
      ),
    ),
    CpuExn(3),
    Jmp(bil_int(32, 0x1000)),
    Jmp(Var(r0)),
    @types.Stmt::encode(@types.Stmt::call(), "malloc"),
  ]
  let result = @core_theory.Core::bil().reflect_bil(program)(state)
  inspect(
    result.bil().map(stmt => stmt.to_string()).join("\n"),
    content=(
      #|R0:imm32 := (R0:imm32 + 1:32u)
      #|ZF:imm1 := (R0:imm32 == 0:32u)
      #|R1:imm32 := let %$0:imm32 = R0:imm32 in (%$0:imm32 * %$0:imm32)
      #|if ZF:imm1 then 1 stmts else 0 stmts
      #|while (R1:imm32 < 0xA:32u) do 1 stmts
      #|mem:mem32x8 := store(mem:mem32x8, R0:imm32, extract[7:0](R1:imm32))
      #|R1:imm32 := load(mem:mem32x8, R0:imm32):imm32
      #|R1:imm32 := concat(low:16[R0:imm32], high:16[R1:imm32])
      #|cpuexn 3
      #|jmp 0x1000:32u
      #|jmp R0:imm32
      #|special @attribute:(bap:call malloc)
    ),
  )
}

///|
test "parser: reflecting BIL into another theory" {
  let state = @knowledge.State::new()
  let r0 = bil_var("R0", 32)
  let program : Array[@types.Stmt] = [
    Move(r0, BinOp(Plus, bil_int(32, 40), bil_int(32, 2))),
  ]
  let ct = @core_theory.Core::bil().join(const_theory())
  let result = ct.reflect_bil(program)(state)
  assert_eq(result.get(test_written), Some("R0"))
  inspect(
    result.bil().map(stmt => stmt.to_string()).join("; "),
    content=(
      #|R0:imm32 := (0x28:32u + 2:32u)
    ),
  )
  let value = ct.parse_bitv(
    @core_theory.bil_parser(),
    BinOp(Plus, bil_int(32, 40), bil_int(32, 2)),
  )(state)
  assert_eq(value.get(test_const), Some(42))
}

///|
test "parser: ill-formed terms are rejected" {
  let state = @knowledge.State::new()
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
  let r0 = bil_var("R0", 32)
  // a memory is not a bitvector
  let program : Array[@types.Stmt] = [Move(r0, Var(mem))]
  let failed = try @core_theory.Core::bil().reflect_bil(program)(state) catch {
    _ => true
  } noraise {
    _ => false
  }
  assert_true(failed)
}
