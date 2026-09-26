///|
test "the plugin Lisp libraries load and type check" {
  let errors : Array[String] = []
  let features = ["core", "posix", "taint", "taint-sources", "sensitive-sinks"] +
    @primus_lisp.embedded_features(["constant-tracker"]) +
    @primus_test.features()
  let (status, _) = @primus.Machine::run(
    @project.Project::empty(@core_theory.Target::x86_64()),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_taint.install_lisp_primitives(m)
      @primus_taint.install_lisp_signals(m)
      @constant_tracker.install_lisp_primitives(m)
      @primus_dictionary.install(m)
      @primus_region.install(m)
      @primus_test.install_lisp(m)
      @primus_lisp.load_library(
        m,
        features~,
        loader=@primus_lisp.Loader::embedded([
          "lisp", "site-lisp", "taint", "constant-tracker", "primus-test",
        ]),
      )
      @primus.Env::set(m, reg("brk"), @primus.Value::of_word(m, w64(0x40000)))
      @primus.Env::set(m, reg("environ"), @primus.Value::of_word(m, w64(0)))
      m.observe(@primus_lisp.type_error, e => errors.push(e.summary()))
      ignore(@primus_lisp.typecheck(m))
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    features,
    content=(
      #|[
      #|  "core",
      #|  "posix",
      #|  "taint",
      #|  "taint-sources",
      #|  "sensitive-sinks",
      #|  "check-hardcoded-values",
      #|  "check-null-pointers",
      #|  "check-value",
      #|  "incident",
      #|  "memcheck-malloc",
      #|  "memcheck",
      #|  "warn-unused",
      #|]
    ),
  )
  debug_inspect(
    errors,
    content=(
      #|[]
    ),
  )
}

///|
test "regions and dictionaries in Lisp" {
  let prog = @primus_lisp.load_program(
    @primus_lisp.Loader::chain([
      @primus_lisp.Loader::of_files([
        (
          "test.lisp",
          (
            #|(defun test ()
            #|  (dict-add 'd 1 10)
            #|  (dict-add 'd 2 20)
            #|  (region-create 'r 0x100 0x1ff)
            #|  (msg "dict: $0 $1 regions: $2 $3"
            #|    (dict-get 'd 2) (dict-length 'd)
            #|    (region-contains 'r 0x150) (region-lower 'r 0x150)))
          ),
        ),
      ]),
      @primus_lisp.Loader::embedded(["lisp"]),
    ]),
    ["core", "test"],
  )
  let log : Array[String] = []
  let (status, _) = @primus.Machine::run(
    @project.Project::empty(@core_theory.Target::x86_64()),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_dictionary.install(m)
      @primus_region.install(m)
      @primus_lisp.link_program(m, prog)
      m.observe(@primus_lisp.message, s => log.push(s))
    },
    start=m => @primus_lisp.eval_fun(m, "test", []),
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|["dict: 0x14:64u #<r 2:64u> regions: 0x100:64u 0x100:64u"]
    ),
  )
}
