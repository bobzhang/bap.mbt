// The Lisp interface: symbolic values and memories, assumptions and
// assertions.

///|
fn run_lisp(src : String, fname : String) -> Array[String] {
  @primus_symbolic_executor.set_timeout(10000)
  let log = []
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([("test.lisp", src)]),
    @primus_lisp.Loader::embedded(["lisp", "site-lisp"]),
  ])
  let (status, _) = @primus.Machine::run(
    project([]),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_symbolic_executor.install_computer(m)
      @primus_symbolic_executor.install_path_constraints(m)
      @primus_symbolic_executor.install_lisp_primitives(m)
      @primus_lisp.load_library(m, features=["core", "test"], loader~)
      m.observe(@primus_symbolic_executor.assert_failure, f => {
        log.push("\{f.name}: \{f.values().map(p => p.0 + "=" + p.1).join(" ")}")
      })
    },
    start=m => {
      @primus_lisp.eval_fun(m, fname, [], then=(_, v) => {
        log.push("result: \{v.to_word().to_string()}")
      })
    },
  )
  match status {
    Normal => ()
    Exn(e) => log.push("error: " + @primus.exn_to_string(e))
  }
  log
}

///|
let lisp_src : String =
  #|(require types)
  #|
  #|(defun values-test ()
  #|  (let ((x (symbolic-value 'x)))
  #|    (symbolic-assume (> x 100) (< x 250))
  #|    (symbolic-assert 'positive (> x 50))
  #|    (symbolic-assert 'fits (< x 250))
  #|    (symbolic-assert 'small (< x 200))
  #|    x))
  #|
  #|(defun branch-test ()
  #|  (let ((x (symbolic-value 'y 64 7)))
  #|    (if (= x 7)
  #|        (symbolic-assert 'seven (= x 8))
  #|      (symbolic-assert 'other (= x 8)))))
  #|
  #|(defun memory-test ()
  #|  (let ((m (symbolic-memory 'buf 0 15)))
  #|    (symbolic-memory-write m 0 1)
  #|    (symbolic-assert 'first (= (cast int (symbolic-memory-read m 0)) 1))
  #|    (symbolic-assert 'third (not (= (cast int (symbolic-memory-read m 3)) 42)))
  #|    (symbolic-memory-read m 0)))

///|
test "symbolic values, assumptions and assertions" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  // `positive` and `fits` hold under the assumptions; `small` fails for
  // some input in [200, 250)
  let log = run_lisp(lisp_src, "values-test")
  guard log is [failure, result] else {
    fail("unexpected log: \{log.join("; ")}")
  }
  guard failure is [.. "small: x=#x", .. hex] else {
    fail("unexpected failure: \{failure}")
  }
  let v = @types.Word::from_hex(width=64, hex.to_owned())
  let n = v.to_uint64()
  assert_true(n >= 200UL && n < 250UL)
  // the concrete value is the initial one (0 by default)
  inspect(
    result,
    content=(
      #|result: 0:64u
    ),
  )
}

///|
test "assertions are checked under the path constraints" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  // on the path where y = 7 the assertion y = 8 fails for y = 7
  debug_inspect(
    run_lisp(lisp_src, "branch-test"),
    content=(
      #|["seven: y=#x0000000000000007", "result: 1:1u"]
    ),
  )
}

///|
test "symbolic memories" {
  if !@primus_symbolic_executor.is_solver_available() {
    return
  }
  // the written cell is concrete, the unwritten one is an input
  debug_inspect(
    run_lisp(lisp_src, "memory-test"),
    content=(
      #|["third: buf[0x3]=#x2a", "result: 1:64u"]
    ),
  )
}
