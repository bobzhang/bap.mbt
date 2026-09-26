///|
test "the polynomial approximations" {
  let close = (x : Double, y : Double) => (x - y).abs() < 1.0e-6
  for x in [0.0, 0.5, 1.0, 2.0, 3.0, 4.0, 10.0, -1.0, -7.5] {
    assert_true(close(@primus_approximation.approx_sin(x), @math.sin(x)))
    assert_true(close(@primus_approximation.approx_cos(x), @math.cos(x)))
  }
}

///|
test "the approximate primitive and math.lisp" {
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([
      (
        "test.lisp",
        (
          #|(require math)
          #|(defun test (x) (msg "$0 $1" (sin x) (cos x)))
        ),
      ),
    ]),
    @primus_lisp.Loader::embedded(["lisp", "approximation"]),
  ])
  let prog = @primus_lisp.load_program(loader, ["core", "test"])
  let log : Array[String] = []
  let (status, _) = @primus.Machine::run(
    @project.Project::empty(@core_theory.Target::x86_64()),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_approximation.install(m)
      @primus_lisp.link_program(m, prog)
      m.observe(@primus_lisp.message, s => log.push(s))
    },
    start=m => @primus_lisp.eval_fun(m, "test", [
      @primus.Value::of_word(m, @types.Word::of_int64(0.0.reinterpret_as_int64(), width=64)),
    ]),
  )
  inspect(status, content="Normal")
  debug_inspect(log, content=(
    #|["0xBDEE0FB43EF080F5:64u 0x3FEFFFFFFFE1F06E:64u"]
  ))
}
