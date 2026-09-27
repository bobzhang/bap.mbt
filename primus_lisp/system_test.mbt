///|
test "the Lisp runtime as components of a system" {
  @primus_lisp.register_components()
  @primus_lisp.register_components()
  let sys = @primus.System::define_("lisp-test-system", pkg="test", components=[
    @primus.System::component("lisp-core", pkg="bap"),
    @primus.System::component("load-lisp-library", pkg="bap"),
  ])
  let result = Ref("<none>")
  let finis = Ref(0)
  let (status, _) = sys.run(
    empty_project(),
    init=m => {
      store_string(m, 0x1000, "abc")
      @primus.Env::set(
        m,
        reg64("posix:brk"),
        @primus.Value::of_word(m, w64(0x40000)),
      )
    },
    start=m => {
      // the context of the program is refined with the system name
      let ctxt = @primus_lisp.program(m).context
      result.val = ctxt.features("system").join(",")
      @primus_lisp.eval_fun(
        m,
        "posix:strlen",
        [@primus.Value::of_word(m, w64(0x1000))],
        then=(_, r) => result.val = result.val + " " + r.to_word().to_string(),
      )
    },
    fini=_ => finis.val += 1,
  )
  inspect(
    status,
    content=(
      #|Normal
    ),
  )
  inspect(result.val, content="test:lisp-test-system 3:64u")
  inspect(finis.val, content="1")
}

///|
test "fini methods run once" {
  let prog = lisp_program(
    (
      #|(defmethod fini ()
      #|  (msg "finished"))
    ),
  )
  let log : Array[String] = []
  let (status, _) = @primus.System::define_("lisp-fini-system", pkg="test").run(
    empty_project(),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
      m.observe(@primus_lisp.message, s => log.push(s))
    },
    fini=_ => log.push("fini"),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["fini", "finished"]
    ),
  )
}
