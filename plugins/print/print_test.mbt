///|
fn tid(n : Int32, name? : String) -> @types.Tid {
  { id: n, pkg_value: "user", name, ivec_value: None, }
}

///|
fn word(width : Int32, n : Int32) -> @types.Word raise {
  @types.Word::of_int(width~, n)
}

///|
fn reg(name : String, width~ : Int32 = 64) -> @types.Var {
  @types.Var::new(name~, typ=Imm(width))
}

///|
/// A small program:
///
/// ```
/// main(argc):
///   blk 0x20: RSP := RSP - 8; mem := mem with [RSP, el]:u64 <- RBP;
///             call @foo with return %0x30
///   blk 0x30: when ZF goto %0x20; return RAX-target
/// foo():
///   blk 0x50: RAX := 1; x <- phi(...); return
/// ```
fn sample_program() -> @types.Term[@types.Program] raise {
  let rsp = reg("RSP")
  let rbp = reg("RBP")
  let rax = reg("RAX")
  let zf = reg("ZF", width=1)
  let mem = @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8))
  let argc = @types.Arg::create(
    reg("main_argc", width=32),
    Cast(kind=Low, width=32, exp=Var(reg("RDI"))),
    intent=In,
    tid=tid(0x11),
  )
  let entry = @types.Blk::create(
    defs=[
      @types.Def::create(
        rsp,
        BinOp(Plus, Var(rsp), Int(word(64, -8))),
        tid=tid(0x21),
      ).set_attr(@types.Attr::address(word(64, 0x400000))),
      @types.Def::create(
        mem,
        Store(mem=Var(mem), addr=Var(rsp), value=Var(rbp), endian=LittleEndian),
        tid=tid(0x22),
      ),
    ],
    jmps=[
      @types.Jmp::create_call(
        @types.Call::create(
          target=Direct(tid(0x40, name="foo")),
          return_label=Direct(tid(0x30)),
        ),
        tid=tid(0x23),
      ),
    ],
    tid=tid(0x20),
  )
  let exit = @types.Blk::create(
    jmps=[
      @types.Jmp::create_goto(Direct(tid(0x20)), cond=Var(zf), tid=tid(0x31)),
      @types.Jmp::create_ret(Indirect(Var(rax)), tid=tid(0x32)),
    ],
    tid=tid(0x30),
  )
  let main = @types.Sub::create(
    name="main",
    args=[argc],
    blks=[entry, exit],
    tid=tid(0x10, name="main"),
  ).set_attr(@types.Attr::address(word(64, 0x400000)))
  let foo_blk = @types.Blk::create(
    phis=[
      @types.Phi::of_list(
        reg("x", width=32),
        [(tid(0x20), Int(word(32, 1))), (tid(0x30), Int(word(32, 16)))],
        tid=tid(0x51),
      ),
    ],
    defs=[@types.Def::create(rax, Int(word(64, 1)), tid=tid(0x52))],
    jmps=[@types.Jmp::create_ret(Indirect(Var(reg("LR"))), tid=tid(0x53))],
    tid=tid(0x50),
  )
  let foo = @types.Sub::create(
    name="foo",
    blks=[foo_blk],
    tid=tid(0x40, name="foo"),
  ).set_attr(@types.Attr::address(word(64, 0x400100)))
  @types.Program::create(subs=[main, foo], tid=tid(1))
}

///|
test "bir printer reproduces the upstream IR syntax" {
  // attributes are printed only when enabled (see the attr mode test)
  @text_tags.attr_hide("address")
  let program = sample_program()
  inspect(
    @print.program_to_string(program),
    content=(
      #|00000001: program
      #|00000010: sub main(main_argc)
      #|00000011: main_argc :: in u32 = low:32[RDI]
      #|
      #|00000020:
      #|00000021: RSP := RSP - 8
      #|00000022: mem := mem with [RSP, el]:u64 <- RBP
      #|00000023: call @foo with return %00000030
      #|
      #|00000030:
      #|00000031: when ZF goto %00000020
      #|00000032: return RAX
      #|
      #|00000040: sub foo()
      #|
      #|
      #|00000050:
      #|00000051: x <- phi([1, %00000020], [0x10, %00000030])
      #|00000052: RAX := 1
      #|00000053: return LR
      #|
    ),
  )
}

///|
test "expressions follow the upstream precedence rules" {
  let x = reg("x", width=32)
  let y = reg("y", width=32)
  let e : @types.Exp = BinOp(
    Times,
    BinOp(Plus, Var(x), Var(y)),
    UnOp(Not, BinOp(Eq, Var(x), Int(word(1, 0)))),
  )
  inspect(
    @print.exp_to_string(e),
    content=(
      #|(x + y) *
      #|~(~x)
    ),
  )
  inspect(
    @print.exp_to_string(
      Ite(
        cond=BinOp(SignedLt, Var(x), Var(y)),
        yes=Extract(hi=7, lo=0, exp=Var(x)),
        no=Concat(high=Var(x), low=Var(y)),
      ),
    ),
    content="if x <$ y then 7:0[x] else x.y",
  )
  inspect(
    @print.exp_to_string(
      Load(
        mem=Var(
          @types.Var::new(name="mem", typ=Mem(addr_width=64, value_width=8)),
        ),
        addr=Var(x),
        endian=BigEndian,
        typ=Imm(32),
      ),
    ),
    content="mem[x, be]:u32",
  )
  inspect(
    @print.exp_to_string(Let(x, Int(word(32, 255)), Unknown("oops", Imm(8)))),
    content="let x = 0xFF in unknown[oops]:u8",
  )
}

///|
test "bil printer uses nested vertical boxes" {
  let x = reg("x", width=32)
  let bil : Array[@types.Stmt] = [
    Move(x, Int(word(32, 3))),
    If(cond=Var(reg("ZF", width=1)), yes=[Jmp(Int(word(64, 0x400010)))], no=[
      Special("halt"),
      CpuExn(3),
    ]),
    While(cond=Var(reg("CF", width=1)), body=[Jmp(Var(x))]),
  ]
  inspect(
    @print.bil_to_string(bil),
    content=(
      #|{
      #|  x := 3
      #|  if (ZF) {
      #|    jmp 0x400010
      #|  }
      #|  else {
      #|    special
      #|    (halt)
      #|    cpuexn (3)
      #|  }
      #|  while (CF) {
      #|    jmp x
      #|  }
      #|}
    ),
  )
  inspect(
    @print.bil_to_adt(bil[:1]),
    content=(
      #|(Move(Var("x",Imm(32)),Int(3,32)))
    ),
  )
  inspect(
    @print.bil_to_sexp(bil[:1]),
    content=(
      #|((Move ((name x)(sort (Imm 32))) (Int 3:32u)))
    ),
  )
}

///|
test "bir attributes are printed in the attr mode" {
  @text_tags.attr_show("address")
  let program = sample_program()
  let foo = program.subs()[1]
  inspect(
    @print.ir_term_to_string(SubTerm(foo)),
    content=(
      #|.address 0x400100:64u
      #|00000040: sub foo()
      #|
      #|
      #|00000050:
      #|00000051: x <- phi([1, %00000020], [0x10, %00000030])
      #|00000052: RAX := 1
      #|00000053: return LR
      #|
    ),
  )
  @text_tags.attr_hide("address")
}

///|
test "adt format of the IR" {
  let program = sample_program()
  let foo = program.subs()[1]
  @print.register_term_writers()
  inspect(
    @print.write_term(BlkTerm(foo.blks()[0]), "adt").unwrap(),
    content=(
      #|Blk(Tid(80, "%00000050"), Attrs([]), Phis([Phi(Tid(81, "%00000051"),
      #| Attrs([]), Var("x",Imm(32)), Values([(Tid(32, "%00000020"),Int(1,32)),
      #|(Tid(48, "%00000030"),Int(16,32))]))]), Defs([Def(Tid(82, "%00000052"),
      #| Attrs([]), Var("RAX",Imm(64)), Int(1,64))]), Jmps([Ret(Tid(83, "%00000053"),
      #| Attrs([]), Int(1,1),
      #|Indirect(Var("LR",Imm(64))))]))
    ),
  )
  assert_true(
    @print.write_term(BlkTerm(foo.blks()[0]), "bogus")
    is Err("unknown output format bogus"),
  )
}

///|
test "callgraph and cfg are printed in the DOT format" {
  let program = sample_program()
  let fmt = @text_tags.Formatter::new()
  @print.pp_callgraph(fmt, program)
  inspect(
    fmt.flush_str(),
    content=(
      #|
      #|digraph  {
      #|  "@main"
      #|  "@foo"
      #|  "@main" -> "@foo"
      #|}
    ),
  )
  @print.pp_bir_graph(fmt, program)
  inspect(
    fmt.flush_str(),
    content=(
      #|digraph {
      #|node[shape=box];
      #|
      #|subgraph "cluster_main" {
      #|  label="main"
      #|  
      #|  "\%00000020"[label="\%00000020
      #|00000021: RSP := RSP - 8\l00000022: mem := mem with [RSP, el]:u64 <- RBP\l00000023: call @foo with return %00000030"]
      #|  "\%00000030"[label="\%00000030
      #|00000032: return RAX"]
      #|  "\%00000020" -> "\%00000030"
      #|  "\%00000030" -> "\%00000020"[label="ZF"]
      #|}
      #|"\%00000020" -> "\%00000050";
      #|
      #|subgraph "cluster_foo" {
      #|  label="foo"
      #|  
      #|  "\%00000050"[label="\%00000050
      #|00000051: x <- phi([1, %00000020], [0x10, %00000030])\l00000052: RAX := 1\l00000053: return LR"]
      #|}
      #|}
    ),
  )
}

///|
test "patterns select subroutines by their properties" {
  let program = sample_program()
  let project = @project.Project::empty(@core_theory.Target::unknown())
    .with_program(program)
    .with_symbols([
      @image.Symbol::create(name="main", addr=0x400000UL, size=0x10),
      @image.Symbol::create(name="foo", addr=0x400100UL, size=0x10),
    ])
  let patterns = @print.compile_patterns(symbols=["^fo"]).unwrap()
  debug_inspect(
    patterns.map(p => "\{p.property()}:\{p.regexp()}"),
    content=(
      #|["symbol:^fo"]
    ),
  )
  let selected = @print.extract_program(patterns, project)
  debug_inspect(
    selected.subs().map(s => s.sub_name()),
    content=(
      #|["foo"]
    ),
  )
  let all = @print.extract_program(
    @print.compile_patterns(patterns=["symbol:ma|fo+$"]).unwrap(),
    project,
  )
  debug_inspect(
    all.subs().map(s => s.sub_name()),
    content=(
      #|["main", "foo"]
    ),
  )
  guard @print.compile_patterns(patterns=["symbol"]) is Err(e1) else {
    fail("expected an error")
  }
  inspect(
    e1,
    content=(
      #|wrong pattern "symbol", expected `:`, none found
    ),
  )
  guard @print.compile_patterns(patterns=["color:red"]) is Err(e2) else {
    fail("expected an error")
  }
  inspect(
    e2,
    content=(
      #|unknown property "color"
    ),
  )
  inspect(@print.compile_patterns(sections=["(text"]) is Err(_), content="true")
  let select = (pattern : String) => {
    @print.extract_program(
      @print.compile_patterns(patterns=[pattern]).unwrap(),
      project,
    )
    .subs()
    .map(s => s.sub_name())
  }
  assert_eq(select("symbol:^m[a-z]{2}n$"), ["main"])
  assert_eq(select("symbol:^[^m]\\w+"), ["foo"])
  assert_eq(select("symbol:(?:ma|f)(in|oo)?$"), ["main", "foo"])
  assert_eq(select("symbol:x*?z"), [])
  assert_eq(select("segment:.*"), [])
}
