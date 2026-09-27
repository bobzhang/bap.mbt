///|
fn sample_project() -> @project.Project {
  let data = b"\x01\x02hello, world\x00ab\x00a longer\tstring\n\x00\xff"
  let mem = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    data,
  )
  @project.Project::empty(@core_theory.Target::unknown()).with_memory(
    @memory.MemMap::empty().add(mem, "data"),
  )
}

///|
test "strings collects and prints the strings" {
  let proj = sample_project()
  debug_inspect(
    @strings.collect(min_length=4, proj),
    content=(
      #|[(4098, "hello, world"), (4114, "a longer\tstring\n")]
    ),
  )
  let buf = StringBuilder()
  @strings.register(with_address=true, out=s => buf.write_string(s)).unwrap()
  match proj.run_pass("strings") {
    Ok(_) => ()
    Err(e) => fail(e)
  }
  inspect(
    buf.to_string(),
    content=(
      #|1002: hello, world
      #|1012: a longer\tstring\n
      #|
    ),
  )
}

///|
test "the strings plugin is declared in bap_main" {
  @bap_main.reset()
  let buf = StringBuilder()
  @strings.declare_plugin(out=s => buf.write_string(s))
  @bap_main.initialize(argv=["bap", "--strings-min-len=9"])
  @bap_main.reset()
  match sample_project().run_pass("strings") {
    Ok(_) => ()
    Err(e) => fail(e)
  }
  inspect(
    buf.to_string(),
    content=(
      #|hello, world
      #|a longer\tstring\n
      #|
    ),
  )
}
