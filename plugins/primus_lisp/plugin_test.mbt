///|
fn project() -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64())
}

///|
test "redirections" {
  debug_inspect(
    @primus_lisp.parse_redirection("<stdout>:out.txt"),
    content=(
      #|Ok(("<stdout>", "out.txt"))
    ),
  )
  debug_inspect(
    @primus_lisp.parse_redirection("<stdfoo>:out.txt"),
    content=(
      #|Err("unknown channel <stdfoo>, expected one of <stdin>, <stdout>, <stderr>")
    ),
  )
  debug_inspect(
    @primus_lisp.parse_redirection("/etc/passwd:passwd"),
    content=(
      #|Ok(("/etc/passwd", "passwd"))
    ),
  )
  debug_inspect(
    @primus_lisp.parse_redirection("foo"),
    content=(
      #|Err("bad redirection, expected <old>:<new> got foo")
    ),
  )
}

///|
test "documentation, typecheck and dump" {
  @primus_lisp.enable(config={
    ..@primus_lisp.Config::default(),
    features: ["posix"],
  })
  let doc = @primus_lisp.documentation(project())
  debug_inspect(doc.contains("* Functions"), content="true")
  debug_inspect(doc.contains("** ~posix:strlen~"), content="true")
  let (summary, errors) = @primus_lisp.typecheck(project())
  // posix:brk and posix:environ are provided by the binary
  inspect(summary, content="Primus Lisp code is ill-typed. Found 10 errors.")
  inspect(errors.length(), content="10")
  let dump = @primus_lisp.dump(project())
  debug_inspect(dump.contains("(defun strlen (p)"), content="true")
}

///|
test "the plugin is declared in the bap_main framework" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @primus_lisp.declare_plugin()
  @bap_main.initialize(argv=[
    "bap", "--primus-lisp-load=posix", "--primus-lisp-semantics=disable",
  ])
  inspect(@bap_main.loaded_plugins().contains("primus-lisp"), content="true")
  @bap_main.reset()
}
