///|
test "arithmetic in a single block" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let b0 = blk(defs=[
    def(x, int64(6)),
    def(y, BinOp(Plus, BinOp(Times, Var(x), int64(7)), int64(1))),
    def(z, BinOp(Minus, Var(y), BinOp(Div, Var(x), int64(4)))),
  ])
  let (status, values) = run_main_sub([sub("main", [b0])], [x, y, z])
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(6), Some(43), Some(42)]
    ),
  )
}

///|
test "expressions: casts, extracts, concat, ite, let and unops" {
  let a = reg("a")
  let b = @types.Var::create("b", Imm(8))
  let c = @types.Var::create("c", Imm(16))
  let d = reg("d")
  let e = reg("e")
  let t = @types.Var::create("t", Imm(64))
  let b0 = blk(defs=[
    def(a, int64(0x1234)),
    def(b, Cast(kind=Low, width=8, exp=Var(a))),
    def(c, Concat(high=Var(b), low=Extract(hi=15, lo=8, exp=Var(a)))),
    def(d, Ite(cond=BinOp(Lt, Var(a), int64(5)), yes=int64(1), no=int64(2))),
    def(e, Let(t, int64(40), BinOp(Plus, Var(t), int64(2)))),
    def(a, UnOp(Neg, int64(1))),
  ])
  let (status, values) = run_main_sub([sub("main", [b0])], [b, c, d, e])
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(52), Some(13330), Some(2), Some(42)]
    ),
  )
}

///|
test "branches pick the first taken jump" {
  let x = reg("x")
  let r = reg("r")
  let b1 = blk(defs=[def(r, int64(1))])
  let b2 = blk(defs=[def(r, int64(2))])
  let prog = (n : Int32) => {
    let b0 = blk(defs=[def(x, int64(n))], jmps=[
      goto(b1, cond=BinOp(Lt, Var(x), int64(5))),
      goto(b2),
    ])
    [sub("main", [b0, b1, b2])]
  }
  let (_, small) = run_main_sub(prog(3), [r])
  let (_, big) = run_main_sub(prog(10), [r])
  debug_inspect(small, content="[Some(1)]")
  debug_inspect(big, content="[Some(2)]")
}

///|
test "loops run until the condition fails" {
  let i = reg("i")
  let acc = reg("acc")
  let exit = blk()
  let body_tid = @types.Tid::create()
  let body = blk(
    tid=body_tid,
    defs=[
      def(acc, BinOp(Plus, Var(acc), Var(i))),
      def(i, BinOp(Plus, Var(i), int64(1))),
    ],
    jmps=[
      @types.Jmp::create_goto(
        Direct(body_tid),
        cond=BinOp(Lt, Var(i), int64(10)),
      ),
      goto(exit),
    ],
  )
  let entry = blk(defs=[def(i, int64(0)), def(acc, int64(0))], jmps=[goto(body)])
  let (status, values) = run_main_sub([sub("main", [entry, body, exit])], [
    i, acc,
  ])
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(10), Some(45)]
    ),
  )
}

///|
test "an infinite loop is stopped by an iteration bound component" {
  let i = reg("i")
  let tid = @types.Tid::create()
  let body = blk(tid~, defs=[def(i, BinOp(Plus, Var(i), int64(1)))], jmps=[
    @types.Jmp::create_goto(Direct(tid)),
  ])
  let entry = blk(defs=[def(i, int64(0))], jmps=[goto(body)])
  let (status, values) = run_main_sub([sub("main", [entry, body])], [i], init=m => {
    let visits : Ref[Int32] = { val: 0, }
    m.observe(@primus.enter_blk, b => {
      if b.tid() == tid {
        visits.val += 1
        if visits.val > 100 {
          @primus.Interpreter::halt(m)
        }
      }
    })
  })
  inspect(status_string(status), content="Exn(Halt)")
  debug_inspect(values, content="[Some(100)]")
}

///|
test "memory stores and loads through the interpreter" {
  let mem = mem_var()
  let x = reg("x")
  let lo = reg("lo")
  let hi = reg("hi")
  let b0 = blk(defs=[
    def(
      mem,
      Store(
        mem=Var(mem),
        addr=int64(0x1000),
        value=Int(try! @types.Word::of_int64(0x1122334455667788L, width=64)),
        endian=LittleEndian,
      ),
    ),
    def(
      x,
      Load(mem=Var(mem), addr=int64(0x1000), endian=LittleEndian, typ=Imm(64)),
    ),
    def(
      lo,
      Load(mem=Var(mem), addr=int64(0x1000), endian=LittleEndian, typ=Imm(8)),
    ),
    def(
      hi,
      Load(mem=Var(mem), addr=int64(0x1000), endian=BigEndian, typ=Imm(16)),
    ),
  ])
  let (status, values) = run_main_sub([sub("main", [b0])], [x, lo, hi], init=m => {
    @primus.Memory::allocate(m, w64(0x1000), 16)
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(
    values,
    content=(
      #|[Some(1234605616436508552), Some(136), Some(34935)]
    ),
  )
}

///|
test "loads from unmapped memory segfault" {
  let x = reg("x")
  let b0 = blk(defs=[
    def(
      x,
      Load(
        mem=Var(mem_var()),
        addr=int64(0x2000),
        endian=LittleEndian,
        typ=Imm(8),
      ),
    ),
  ])
  let events = []
  let (status, _) = run_main_sub([sub("main", [b0])], [x], init=m => {
    m.observe(@primus.pagefault, a => events.push("pagefault \{a.to_hex()}"))
    m.observe(@primus.segfault, a => events.push("segfault \{a.to_hex()}"))
  })
  inspect(
    status_string(status),
    content="Exn(Segmentation fault at 0x0000000000002000)",
  )
  debug_inspect(
    events,
    content=(
      #|["pagefault 0x0000000000002000", "segfault 0x0000000000002000"]
    ),
  )
}

///|
test "the pagefault handler can map memory and retry" {
  let x = reg("x")
  let b0 = blk(defs=[
    def(
      x,
      Load(
        mem=Var(mem_var()),
        addr=int64(0x2000),
        endian=LittleEndian,
        typ=Imm(8),
      ),
    ),
  ])
  let (status, values) = run_main_sub([sub("main", [b0])], [x], init=m => {
    @primus.Linker::link(
      m,
      name=@primus.pagefault_handler,
      Host(m => {
        @primus.Memory::allocate(
          m,
          w64(0x2000),
          1,
          generator=@primus.Generator::static_value(7),
        )
      }),
    )
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(7)]")
}

///|
test "read-only memory rejects stores" {
  let b0 = blk(defs=[
    def(
      mem_var(),
      Store(
        mem=Var(mem_var()),
        addr=int64(0x10),
        value=Int(w8(1)),
        endian=LittleEndian,
      ),
    ),
  ])
  let (status, _) = run_main_sub([sub("main", [b0])], [], init=m => {
    @primus.Memory::allocate(m, w64(0x10), 4, read_only=true)
  })
  inspect(
    status_string(status),
    content="Exn(Segmentation fault at 0x0000000000000010)",
  )
}

///|
test "division by zero raises unless a handler is linked" {
  let x = reg("x")
  let b0 = blk(defs=[def(x, BinOp(Div, int64(1), int64(0)))])
  let (status, _) = run_main_sub([sub("main", [b0])], [x])
  inspect(status_string(status), content="Exn(Division by zero)")
  let called : Ref[Int32] = { val: 0, }
  let (status, values) = run_main_sub([sub("main", [b0])], [x], init=m => {
    @primus.Linker::link(
      m,
      name=@primus.division_by_zero_handler,
      Host(_ => called.val += 1),
    )
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(0)]")
  inspect(called.val, content="1")
}

///|
test "unknown expressions produce undefined values" {
  let x = reg("x")
  let undefs = []
  let b0 = blk(defs=[def(x, Unknown("bad", Imm(64)))])
  let (_, values) = run_main_sub([sub("main", [b0])], [x], init=m => {
    m.observe(@primus.undefined, v => undefs.push(v.to_word().bitwidth()))
  })
  debug_inspect(values, content="[Some(0)]")
  debug_inspect(undefs, content="[64]")
}

///|
test "interrupt jumps post the interrupt and continue at the return block" {
  let r = reg("r")
  let after = blk(defs=[def(r, int64(5))])
  let entry = blk(jmps=[@types.Jmp::create_int(0x80, after.tid())])
  let ints = []
  let data = []
  let (status, values) = run_main_sub([sub("main", [entry, after])], [r], init=m => {
    m.observe(@primus.interrupt, n => ints.push(n))
    @primus.interrupt.provider().on_data(s => data.push(s.to_string()))
  })
  inspect(status_string(status), content="Normal")
  debug_inspect(values, content="[Some(5)]")
  debug_inspect(ints, content="[128]")
  debug_inspect(
    data,
    content=(
      #|["128"]
    ),
  )
}

///|
test "phi nodes select the option of the predecessor block" {
  let x = reg("x")
  let x1 = reg("x1")
  let x2 = reg("x2")
  let join_tid = @types.Tid::create()
  let left = blk(defs=[def(x1, int64(10))], jmps=[
    @types.Jmp::create_goto(Direct(join_tid)),
  ])
  let right = blk(defs=[def(x2, int64(20))], jmps=[
    @types.Jmp::create_goto(Direct(join_tid)),
  ])
  let phi = @types.Phi::of_list(x, [
    (left.tid(), Var(x1)),
    (right.tid(), Var(x2)),
  ])
  let join = @types.Blk::create(tid=join_tid, phis=[phi])
  let prog = (flag : Int32) => {
    let entry = blk(jmps=[
      goto(left, cond=BinOp(Eq, int64(flag), int64(1))),
      goto(right),
    ])
    [sub("main", [entry, left, right, join])]
  }
  let (_, l) = run_main_sub(prog(1), [x])
  let (_, r) = run_main_sub(prog(0), [x])
  debug_inspect(l, content="[Some(10)]")
  debug_inspect(r, content="[Some(20)]")
}
