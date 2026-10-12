///|
fn project(subs : Array[@types.Term[@types.Sub]]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs~),
  )
}

///|
fn int64(n : Int32) -> @types.Exp {
  Int(try! @types.Word::of_int(width=64, n))
}

///|
fn load8(addr : Int32) -> @types.Exp {
  Load(
    mem=Var(@types.Var::create("mem", Mem(addr_width=64, value_width=8))),
    addr=int64(addr),
    endian=LittleEndian,
    typ=Imm(8),
  )
}

///|
fn store8(addr : Int32, x : Int32) -> @types.Term[@types.Def] {
  let mem = @types.Var::create("mem", Mem(addr_width=64, value_width=8))
  @types.Def::create(
    mem,
    Store(
      mem=Var(mem),
      addr=int64(addr),
      value=Int(try! @types.Word::of_int(width=8, x)),
      endian=LittleEndian,
    ),
  )
}

///|
fn word(v : @primus.Value) -> String {
  (try! v.to_word().to_uint64()).to_string()
}

///|
/// Runs `main` with the given component initializers and reports the
/// values of the variables at the end (or the exception).
fn run(
  subs : Array[@types.Term[@types.Sub]],
  vars : Array[@types.Var],
  init : (@primus.Machine) -> Unit raise,
) -> String {
  let out = []
  let (status, _) = @primus.Machine::run(
    project(subs),
    init=m => {
      @primus.Interpreter::link_program(m)
      init(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      for v in vars {
        out.push(
          if @primus.Env::is_set(m, v) {
            "\{v.name()}=\{word(@primus.Env::get(m, v))}"
          } else {
            "\{v.name()}=unset"
          },
        )
      }
    },
  )
  match status {
    Normal => out.join(" ")
    Exn(e) => @primus.exn_to_string(e)
  }
}

///|
test "generator specifications" {
  let specs = @primus_random.Spec::parse_many(
    (
      #|random static (random 10) (static 1 2 3)
      #|((var RAX RDI) random -5 5) ; comment
      #|((var _) static 56)
      #|((mem 0xC0000000 0xFFFFFFFF) static 0xA5A5A5A5)
      #|((mem :heap) random) ((mem RSP) static 0) ((mem _) static 0x5A)
      #|(_ random 1 2 3)
    ),
  )
  debug_inspect(
    specs.map(s => s.to_string()),
    content=(
      #|[
      #|  "(_ Random )",
      #|  "(_ Static )",
      #|  "(_ Random 10)",
      #|  "(_ Static 1 2 3)",
      #|  "((var RAX RDI) Random -5 5)",
      #|  "((var _) Static 56)",
      #|  "((mem 0xC0000000 0xFFFFFFFF) Static 0xA5A5A5A5)",
      #|  "((mem :heap) Random )",
      #|  "((mem RSP) Static 0)",
      #|  "((mem _) Static 0x5A)",
      #|  "(_ Random 1 2 3)",
      #|]
    ),
  )
  let errors = ["(foo)", "((var (x)) static)", "((var x) uniform)", "(("].map(s => {
    try @primus_random.Spec::parse(s) catch {
      e => e.to_string()
    } noraise {
      _ => "ok"
    }
  })
  debug_inspect(
    errors,
    content=(
      #|[
      #|  "expected a generator specification, got (foo)",
      #|  "Expected a flat list of atoms, got (x)",
      #|  "expected static or random, got uniform",
      #|  "unexpected end of input",
      #|]
    ),
  )
}

///|
test "static and random generators" {
  let values = []
  let (_, _) = @primus.Machine::run(project([]), start=m => {
    let gen = @primus_random.Spec::parse("(static 1 2 3)").create(width=8)
    for _ in 0..<4 {
      values.push(@primus.Generator::next(m, gen))
    }
    let gen = @primus_random.Spec::parse("(random 5 7)").create(width=8)
    for _ in 0..<20 {
      let x = @primus.Generator::next(m, gen)
      assert_true(x >= 5 && x <= 7)
    }
    let gen = @primus_random.Spec::parse("static").create(width=8)
    values.push(@primus.Generator::next(m, gen))
  })
  debug_inspect(
    values,
    content=(
      #|[1, 2, 3, 1, 0]
    ),
  )
}

///|
test "the variable randomizer gives generators to unset variables" {
  let x = @types.Var::create("x", Imm(64))
  let y = @types.Var::create("y", Imm(64))
  let r = @types.Var::create("r", Imm(64))
  let main = @types.Sub::create(name="main", blks=[
    @types.Blk::create(defs=[@types.Def::create(r, BinOp(Plus, Var(x), Var(y)))]),
  ])
  inspect(
    run([main], [r], _ => ()),
    content=(
      #|undefined variable `x'
    ),
  )
  let specs = [
    @primus_random.Spec::parse("((var x) static 40)"),
    @primus_random.Spec::parse("((var _) random 2 2)"),
  ]
  inspect(
    run([main], [x, y, r], m => @primus_random.install_var_randomizer(m, specs~)),
    content=(
      #|x=40 y=2 r=42
    ),
  )
}

///|
test "the memory randomizer maps pages and regions" {
  let r = @types.Var::create("r", Imm(8))
  let s = @types.Var::create("s", Imm(8))
  let main = @types.Sub::create(name="main", blks=[
    @types.Blk::create(defs=[
      @types.Def::create(r, load8(0x2000)),
      @types.Def::create(s, load8(0x10010)),
    ]),
  ])
  inspect(
    run([main], [r, s], _ => ()),
    content=(
      #|Segmentation fault at 0x0000000000002000
    ),
  )
  let specs = [
    @primus_random.Spec::parse("((mem 0x10000 0x100ff) static 7)"),
    @primus_random.Spec::parse("((mem _) static 0xA5)"),
  ]
  inspect(
    run([main], [r, s], m => @primus_random.install_mem_randomizer(m, specs~)),
    content=(
      #|r=165 s=7
    ),
  )
}

///|
test "read-only pages are remapped unless the protection is preserved" {
  let main = @types.Sub::create(name="main", blks=[
    @types.Blk::create(defs=[store8(0x3000, 1)]),
  ])
  let init = (keep_protected : Bool) => {
    (m : @primus.Machine) => {
      @primus.Memory::allocate(
        m,
        @types.Word::of_int(width=64, 0x3000),
        16,
        read_only=true,
      )
      @primus_random.install_mem_randomizer(m, keep_protected~)
    }
  }
  inspect(run([main], [], init(false)), content="")
  inspect(
    run([main], [], init(true)),
    content=(
      #|Segmentation fault at 0x0000000000003000
    ),
  )
}

///|
test "the argument randomizer handles unresolved calls" {
  let rax = @types.Var::create("RAX", Imm(64))
  let res = @types.Var::create("foo_result", Imm(64))
  let foo = @types.Sub::create(
    name="foo",
    args=[@types.Arg::create(res, Var(rax), intent=Out)],
    blks=[
      @types.Blk::create(jmps=[@types.Jmp::create_goto(Indirect(int64(0xdead)))]),
    ],
  )
  let after = @types.Blk::create()
  let main = @types.Sub::create(name="main", blks=[
    @types.Blk::create(jmps=[
      @types.Jmp::create_call(
        @types.Call::create(
          target=Direct(foo.tid()),
          return_label=Direct(after.tid()),
        ),
      ),
    ]),
    after,
  ])
  inspect(
    run([main, foo], [rax, res], _ => ()),
    content=(
      #|unbound function 0x000000000000dead
    ),
  )
  let specs = [@primus_random.Spec::parse("((var foo_result) static 77)")]
  let msgs = []
  inspect(
    run([main, foo], [rax, res], m => {
      m.observe(@primus_random.debug_msg, s => msgs.push(s))
      @primus_random.install_arg_randomizer(m, specs~)
    }),
    content=(
      #|RAX=77 foo_result=77
    ),
  )
  debug_inspect(
    msgs,
    content=(
      #|[
      #|  "the unresolved handler is called",
      #|  "pertubing argument foo_result :: out imm64 = RAX:imm64",
      #|]
    ),
  )
}

///|
test "the components are registered once" {
  assert_true(@primus_random.register(seed=1))
  assert_false(@primus_random.register())
}
