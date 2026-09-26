///|
test "link_program: an address shared by a sub and its entry block resolves to the block" {
  let entry = blk().set_attr(@types.Attr::address(w64(0x1000)))
  let f = sub("f", [entry]).set_attr(@types.Attr::address(w64(0x1000)))
  let (_, _) = @primus.Machine::run(project([f]), start=m => {
    @primus.Interpreter::link_program(m)
    assert_true(
      @primus.Linker::resolve_tid(m, Addr(w64(0x1000))) == Some(entry.tid()),
    )
    assert_true(@primus.Linker::resolve_tid(m, Symbol("f")) == Some(f.tid()))
  })
}

///|
test "system errors are rendered" {
  let e : Error = @primus.UnknownComponent(component="bap:x", system="bap:y")
  inspect(
    @primus.exn_to_string(e),
    content="failed to find a component bap:x required for system bap:y",
  )
  let broken = @primus.System::define_("broken-validate", components=[
    @primus.System::component("missing-component"),
  ])
  let msg = try broken.validate() catch {
    err => err.to_string()
  } noraise {
    _ => "ok"
  }
  inspect(
    msg,
    content="failed to find a component missing-component required for system broken-validate",
  )
}
