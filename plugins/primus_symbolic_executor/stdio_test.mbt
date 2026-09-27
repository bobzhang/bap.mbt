// The `symbolic-stdio` Lisp library: symbolic standard input and files.

///|
/// Switches to the newest other live machine, killing the finished one
/// (the greedy scheduler, driven by `fini` since `Machine::run` does not
/// post `system-fini`).
fn resume_newest(m : @primus.Machine) -> Unit raise {
  let others = m.forks().filter(id => id != m.current())
  if others.last() is Some(id) {
    m.kill(m.current())
    m.switch(id)
  }
}

///|
fn run_stdio(
  src : String,
  fname : String,
  features? : Array[String] = ["core", "symbolic-stdio", "test"],
) -> (Array[String], Array[String], String) {
  @primus_symbolic_executor.set_timeout(10000)
  let log = []
  let errors = []
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([("test.lisp", src)]),
    @primus_lisp.Loader::embedded(@primus_lisp.library_dirs),
  ])
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      @primus_lisp.init_runtime(m)
      // the definitions of symbolic-stdio are in the context of the
      // symbolic computer component
      @primus_lisp.refine(
        m,
        @primus_lisp.Context::create([("component", ["bap:symbolic-computer"])]),
      )
      @primus_track_visited.install(m)
      @primus_dictionary.install(m)
      @primus_symbolic_executor.install_computer(m)
      @primus_symbolic_executor.install_path_constraints(m)
      @primus_symbolic_executor.install_path_explorer(m)
      @primus_symbolic_executor.install_lisp_primitives(m)
      @primus_lisp.load_library(m, features~, loader~)
      for v in ["brk", "environ"] {
        @primus.Env::set(
          m,
          @types.Var::create(v, Imm(64)),
          @primus.Value::of_word(m, w64(0x40000)),
        )
      }
      m.observe(@primus_lisp.type_error, e => errors.push(e.summary()))
      ignore(@primus_lisp.typecheck(m))
    },
    start=m => {
      @primus_lisp.eval_method(m, "init", [], then=m => {
        @primus_lisp.eval_fun(m, fname, [], then=(m, v) => {
          log.push("\{m.current()}: \{v.to_word().to_string()}")
        })
      })
    },
    fini=resume_newest,
  )
  let status = match status {
    Normal => "normal"
    Exn(e) => @primus.exn_to_string(e)
  }
  (log, errors, status)
}

///|
test "reading the symbolic standard input explores both branches" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  let src =
    #|(in-package posix)
    #|(defun stdin-test ()
    #|  (let ((c (getchar)))
    #|    (if (= c 65) 1 2)))
  let (log, errors, _) = run_stdio(src, "posix:stdin-test")
  debug_inspect(
    errors,
    content=(
      #|[]
    ),
  )
  // the second machine reads the character generated from the model of
  // `c = 65`
  debug_inspect(
    log,
    content=(
      #|["1: 2:64u", "2: 1:64u"]
    ),
  )
}

///|
test "symbolic-stdio type checks together with the posix library" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  let src =
    #|(defun noop () 0)
  let (_, errors, _) = run_stdio(src, "noop", features=[
    "core", "posix", "symbolic-stdio", "symbolic-stdlib", "test",
  ])
  debug_inspect(
    errors,
    content=(
      #|[]
    ),
  )
}
