// End-to-end tests of the Lisp interpreter on the Primus machine.

///|
fn lisp_program(src : String) -> @primus_lisp.Program raise {
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([("test.lisp", src)]),
    @primus_lisp.Loader::embedded(["lisp"]),
  ])
  @primus_lisp.load_program(
    loader,
    ["core", "test"],
    context=@primus_lisp.Context::of_target(@core_theory.Target::x86_64()),
  )
}

///|
fn empty_project() -> @project.Project {
  @project.Project::empty(@core_theory.Target::x86_64())
}

///|
/// Runs `name` with the integer arguments (64-bit) and returns the result
/// as an unsigned integer, together with the messages.
fn run_lisp(
  src : String,
  name : String,
  args : Array[Int32],
  proj~ : @project.Project = empty_project(),
) -> (String, Array[String]) raise {
  let prog = lisp_program(src)
  let result : Ref[String] = Ref("<none>")
  let messages : Array[String] = []
  let (status, _) = @primus.Machine::run(
    proj,
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
      m.observe(@primus_lisp.message, msg => messages.push(msg))
    },
    start=m => {
      @primus_lisp.eval_fun(
        m,
        name,
        args.map(x => @primus.Value::of_int(m, width=64, x)),
        then=(_, r) => result.val = r.to_word().to_string(),
      )
    },
  )
  match status {
    Normal => ()
    Exn(e) => result.val = "error: " + @primus.exn_to_string(e)
  }
  (result.val, messages)
}

///|
test "factorial" {
  let src =
    #|(defun fact (n)
    #|  (if (= n 0) 1 (* n (fact (- n 1)))))
    #|(defun fact-iter (n)
    #|  (let ((r 1))
    #|    (while (> n 0)
    #|      (set r (* r n))
    #|      (decr n))
    #|    r))
  inspect(run_lisp(src, "fact", [5]).0, content="0x78:64u")
  inspect(run_lisp(src, "fact-iter", [10]).0, content="0x375F00:64u")
}

///|
test "messages and errors" {
  let src =
    #|(defun greet (x)
    #|  (msg "hello $0, symbol $1" x 'world)
    #|  (+ x 1))
    #|(defun fail () (error "boom"))
    #|(defun unknown () (no-such-function 1))
  let (r, msgs) = run_lisp(src, "greet", [41])
  inspect(r, content="0x2A:64u")
  debug_inspect(
    msgs,
    content=(
      #|["hello 0x29:64u, symbol #<world 1:63u>"]
    ),
  )
  inspect(
    run_lisp(src, "fail", []).0,
    content=(
      #|error: Primus Lisp runtime error - File "test.lisp", line 4, characters 15-29
      #|boom
    ),
  )
  inspect(
    run_lisp(src, "unknown", []).0,
    content=(
      #|error: Primus Lisp runtime error - File "test.lisp", line 5, characters 0-39
      #|unresolved primitive no-such-function
    ),
  )
}
