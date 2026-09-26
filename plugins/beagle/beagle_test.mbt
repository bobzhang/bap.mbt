///|
fn w64(n : Int) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn mem_var() -> @types.Var {
  @types.Var::create("mem", Mem(addr_width=64, value_width=8))
}

///|
/// A program that stores the bytes of `text` one by one starting at
/// 0x1000.
fn store_text(text : String) -> @project.Project {
  let mem = mem_var()
  let defs = []
  for i in 0..<text.length() {
    defs.push(
      @types.Def::create(
        mem,
        Store(
          mem=Var(mem),
          addr=Int(w64(0x1000 + i)),
          value=Int(try! @types.Word::of_int(width=8, text[i].to_int())),
          endian=LittleEndian,
        ),
      ),
    )
  }
  let main = @types.Sub::create(name="main", blks=[@types.Blk::create(defs~)])
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
}

///|
fn run_hunter(
  text : String,
  words? : Array[String] = [],
) -> (Array[String], Array[(String, Array[String])], Array[String]) {
  let printed = []
  @beagle.configure({
    ..@beagle.Params::default(),
    words,
    print_chars: true,
    print_words: true,
    output: s => printed.push(s),
  })
  let preys = []
  let caught = []
  let (_, _) = @primus.Machine::run(
    store_text(text),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Memory::allocate(m, w64(0x1000), 0x100)
      @beagle.install(m)
      m.observe(@beagle_prey.detected(), p => preys.push(p.text()))
      m.observe(@beagle_prey.caught(), c => {
        caught.push((c.0.text(), c.1.to_array()))
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => @beagle.gohome(m),
  )
  @beagle.configure(@beagle.Params::default())
  (preys, caught, printed)
}

///|
test "the hunter detects text stored to memory and builds words" {
  let (preys, caught, printed) = run_hunter(
    "\u{1}\u{2}hello world, this is a long enough text to be detected by the beagle\u{0}\u{0}",
    words=["hello", "world", "text", "absent"],
  )
  debug_inspect(
    preys,
    content=(
      #|["hello world, this is a long enough text to be detected by the beagle"]
    ),
  )
  debug_inspect(
    caught,
    content=(
      #|[
      #|  (
      #|    "hello world, this is a long enough text to be detected by the beagle",
      #|    ["absent", "hello", "text", "world"],
      #|  ),
      #|]
    ),
  )
  debug_inspect(
    printed,
    content=(
      #|[
      #|  "word: absent",
      #|  "word: hello",
      #|  "word: text",
      #|  "word: world",
      #|  "chars: hello world, this is a long enough text to be detected by the beagle",
      #|]
    ),
  )
}

///|
test "noise between texts splits the prey" {
  let noise = "\u{80}".repeat(100)
  let (preys, _, _) = run_hunter(
    "the first sentence is long enough to be text" +
    noise +
    "and the second one is long enough to be text too",
  )
  debug_inspect(
    preys,
    content=(
      #|[
      #|  "the first sentence is long enough to be text",
      #|  "and the second one is long enough to be text too",
      #|]
    ),
  )
}

///|
test "hunter helpers" {
  let hunt = @beagle.make_hunter({
    ..@beagle.Params::default(),
    words: ["cat", "act", "dog"],
  })
  inspect(hunt(b"tac"), content="act, cat")
  assert_true(@beagle.alphabet_of_name("digits") is Some(_))
  assert_true(@beagle.alphabet_of_name("klingon") is None)
  assert_eq(@beagle.alphabets.length(), 6)
}

///|
test "registration" {
  assert_true(@beagle.register())
  assert_false(@beagle.register())
  assert_true(
    @primus.Components::list()
    .iter()
    .any(i => i.name().show().contains("beagle-hunter")),
  )
  inspect(@beagle.pass().name(), content="beagle")
  debug_inspect(@beagle.pass().deps(), content="[\"strings-collect\"]")
}
