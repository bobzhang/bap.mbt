///|
test "regular expressions search anywhere in the input" {
  let matches = (pattern : String, input : String) => {
    match @callgraph_collator.Regex::compile(pattern) {
      Ok(regex) => regex.execp(input)
      Err(_) => false
    }
  }
  debug_inspect(
    [
      matches("mem", "__memcpy"),
      matches("^mem", "__memcpy"),
      matches("^_+mem", "__memcpy"),
      matches("cpy$", "__memcpy"),
      matches("^(str|mem)cpy$", "strcpy"),
      matches("^(str|mem)cpy$", "wcscpy"),
      matches("[a-c]{3}", "xxabcxx"),
      matches("[^a-z]", "abc"),
      matches("\\d+_\\w", "sub_12_a"),
      matches("a.c", "abc"),
      matches("a.c", "ac"),
      matches("x*", ""),
      matches("\\bfoo\\b", "a foo b"),
      matches("\\bfoo\\b", "afoob"),
      matches("colou?r", "color"),
      matches("(?:ab)+c", "ababc"),
    ],
    content=(
      #|[
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|]
    ),
  )
  debug_inspect(
    @callgraph_collator.Regex::compile("(ab").map(_ => ()),
    content=(
      #|Err("invalid regular expression (ab: unexpected end of regular expression")
    ),
  )
  debug_inspect(
    @callgraph_collator.Regex::compile("*a").map(_ => ()),
    content=(
      #|Err("invalid regular expression *a: nothing to repeat")
    ),
  )
}

///|
fn call(dst : String) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_call(
    @types.Call::create(target=@types.Label::direct(@types.Tid::for_name(dst))),
  )
}

///|
fn program(
  calls : Array[(String, Array[String])],
) -> @types.Term[@types.Program] {
  @types.Program::create(
    subs=calls.map(entry => {
      @types.Sub::create(name=entry.0, blks=[
        @types.Blk::create(jmps=entry.1.map(call)),
      ])
    }),
  )
}

///|
fn project(calls : Array[(String, Array[String])]) -> @project.Project {
  @project.Project::empty(@core_theory.Target::unknown()).with_program(
    program(calls),
  )
}

///|
test "calls are filtered" {
  let prog = program([
    ("main", ["puts", "_init", "sub_400", "puts", "abort"]),
    ("_start", ["main"]),
  ])
  let all = @callgraph_collator.CallgraphFilter::new().unwrap()
  debug_inspect(
    @callgraph_collator.calls_of_program(prog, all).to_array(),
    content=(
      #|[
      #|  ("main", ["_init", "abort", "puts", "sub_400"]),
      #|  ("_start", ["main"]),
      #|]
    ),
  )
  let strict = @callgraph_collator.CallgraphFilter::new(
    ignore_reserved=true,
    ignore_unresolved=true,
    ignore_matching="^ab",
  ).unwrap()
  debug_inspect(
    @callgraph_collator.calls_of_program(prog, strict).to_array(),
    content=(
      #|[("main", ["puts"])]
    ),
  )
}

///|
test "the collator prints unified-diff style differences" {
  let out = StringBuilder()
  debug_inspect(
    @callgraph_collator.register(out=s => out.write_string(s)),
    content="Ok(true)",
  )
  debug_inspect(@callgraph_collator.register(), content="Ok(false)")
  guard @project.find_collator("callgraph", pkg="bap") is Some(collator) else {
    fail("the collator is not registered")
  }
  inspect(collator.desc(), content="compares binaries by their callgraphs")
  let base = project([("main", ["puts", "exit"]), ("helper", ["free"])])
  let same = project([("main", ["exit", "puts"]), ("helper", ["free"])])
  let changed = project([("main", ["puts", "malloc"]), ("init", ["main"])])
  collator.apply([base, same, changed])
  inspect(
    out.to_string(),
    content=(
      #|Version 0 is not different
      #|Version 1 differs:
      #|- helper -> free
      #|+ init -> main
      #|- main -> exit
      #|+ main -> malloc
      #|Found one version that is different
      #|
    ),
  )
}

///|
test "summary lines" {
  debug_inspect(
    [0, 1, 3].map(@callgraph_collator.summary_text),
    content=(
      #|[
      #|  "All versions have the same callgraph as the base version\n",
      #|  "Found one version that is different\n",
      #|  "Found 3 versions that are different\n",
      #|]
    ),
  )
}
