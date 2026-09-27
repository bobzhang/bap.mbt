///|
test "the site is stored on disk" {
  let (project, env) = sample_env()
  ignore(env)
  let b1 = block(0x1000UL, [(b"\x55", "push rbp", "PUSH64r", [])])
  let symtab = @project.ProjectDisassemblySymtab::empty().add_symbol(
    @project.ProjectDisassemblyFunction::create(name="main", entry=b1),
  )
  let root = "_build/phoenix-store-test"
  match @phoenix.store(project, symtab~, root~) {
    Ok(dest) => assert_eq(dest, root)
    Err(e) => fail(e)
  }
  match @native_io.read_file(root + "/cfg/main.cfg") {
    Ok(data) => assert_true(@utf8.decode(data).has_prefix("digraph G {"))
    Err(e) => fail(e)
  }
  match @native_io.read_file(root + "/phoenix.functionlist") {
    Ok(data) => assert_true(@utf8.decode(data).contains("\"name\": \"main\""))
    Err(e) => fail(e)
  }
}
