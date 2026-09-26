///|
test "sexp reader handles comments, strings, and lists" {
  debug_inspect(
    @read_symbols.parse_sexps(
      (
        #|;; comment
        #|(main 0x10) "with space" #| block #| nested |# |# atom
        #|#; (ignored datum) ("a\tb" "\065")
      ),
    ),
    content=(
      #|Ok(
      #|  [
      #|    List([Atom("main"), Atom("0x10")]),
      #|    Atom("with space"),
      #|    Atom("atom"),
      #|    List([Atom("a\tb"), Atom("A")]),
      #|  ],
      #|)
    ),
  )
  debug_inspect(
    @read_symbols.parse_sexps("(a (b)"),
    content=(
      #|Err("unclosed parenthesis")
    ),
  )
}

///|
test "entries with and without names" {
  let text =
    #|;; file ls.scm
    #|(main 0x4000100)
    #|(foo 0x400200 0x400300) ; anything past the second element is ignored
    #|0x400500 0x400600
    #|("quoted name" 16)
  debug_inspect(
    @read_symbols.parse_symbols(text),
    content=(
      #|Ok(
      #|  [
      #|    ("main", 67109120),
      #|    ("foo", 4194816),
      #|    ("__anonymous_sub%0x400500", 4195584),
      #|    ("__anonymous_sub%0x400600", 4195840),
      #|    ("quoted name", 16),
      #|  ],
      #|)
    ),
  )
  debug_inspect(
    @read_symbols.parse_symbols("(main)"),
    content=(
      #|Err("failed to read symbols, expects (<name> <addr> ...)")
    ),
  )
  debug_inspect(
    @read_symbols.parse_symbols("zzz"),
    content=(
      #|Err("failed to read symbols, invalid address zzz")
    ),
  )
}

///|
test "inconsistent entries are resolved like upstream" {
  let errors = []
  let functions = @read_symbols.build_functions(
    [
      ("main", 0x100), // same name twice: the minimal address wins
      ("main", 0x80),
      ("a", 0x200), // two names at one address: both skipped
      ("b", 0x200),
      ("c", 0x300),
    ],
    report=message => errors.push(message),
  )
  let entries = functions.to_array()
  entries.sort_by((x, y) => x.0.compare(y.0))
  debug_inspect(
    entries,
    content=(
      #|[(128, "main"), (768, "c")]
    ),
  )
  debug_inspect(
    errors,
    content=(
      #|["skipping names (a, b) that has the same address 0x200"]
    ),
  )
}

///|
test "file selection by unit name" {
  let fs = @bap_main.FileSystem::in_memory(
    files=[
      ("syms/ls.scm", "(main 0x10)"),
      ("syms/mv.scm", "(main 0x20) 0x30"),
      ("one.scm", "(start 0x40)"),
    ],
    dirs=["syms"],
  )
  debug_inspect(
    @read_symbols.select_files("/bin/ls", ["one.scm"], fs~),
    content=(
      #|["one.scm"]
    ),
  )
  debug_inspect(
    @read_symbols.select_files("/bin/ls", ["one.scm"], when_matches=None, fs~),
    content="[]",
  )
  debug_inspect(
    @read_symbols.select_files("/bin/mv", ["syms"], fs~),
    content=(
      #|["syms/ls.scm", "syms/mv.scm"]
    ),
  )
  debug_inspect(
    @read_symbols.select_files(
      "/bin/mv",
      ["syms", "missing.scm"],
      when_matches=Some("ls"),
      fs~,
    ),
    content="[]",
  )
  guard @read_symbols.collect("/usr/bin/mv", ["syms"], fs~) is Ok(functions) else {
    fail("collect failed")
  }
  let rooter = @read_symbols.rooter(functions)
  debug_inspect(
    rooter.roots(),
    content=(
      #|[16, 48]
    ),
  )
  let symbolizer = @read_symbols.symbolizer(functions)
  debug_inspect(
    [symbolizer.run(0x20), symbolizer.run(0x30)],
    content=(
      #|[None, None]
    ),
  )
}

///|
test "registration provides the named sources" {
  let fs = @bap_main.FileSystem::in_memory(files=[("f.scm", "(entry 0x1000)")])
  debug_inspect(@read_symbols.register(files=[], fs~), content="Ok(false)")
  debug_inspect(
    @read_symbols.register(files=["f.scm"], fs~),
    content="Ok(true)",
  )
  guard @project.find_symbolizer_source("read-symbols") is Some(source) else {
    fail("no symbolizer source")
  }
  debug_inspect(
    source.values().map(s => s.run(0x1000)),
    content=(
      #|[Some("entry")]
    ),
  )
  guard @project.find_rooter_source("read-symbols") is Some(roots) else {
    fail("no rooter source")
  }
  debug_inspect(roots.values().map(r => r.roots()), content="[[4096]]")
}

///|
test "plugin declaration reads the from parameter" {
  @bap_main.reset()
  @bap_main.set_file_system(
    @bap_main.FileSystem::in_memory(files=[("g.scm", "(g 0x2000)")]),
  )
  @read_symbols.declare_plugin()
  @bap_main.initialize(
    argv=["bap", "--read-symbols-from=g.scm"],
    name="bap",
    env=_ => None,
    out=_ => (),
    err=_ => (),
  )
  guard @project.find_symbolizer_source("read-symbols") is Some(source) else {
    fail("no symbolizer source")
  }
  debug_inspect(
    source.values().map(s => s.run(0x2000)),
    content=(
      #|[Some("g")]
    ),
  )
  @bap_main.reset()
}
