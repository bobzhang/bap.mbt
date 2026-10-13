// The Lisp interpreter with memory, binary programs, advice, signals and
// forks.

///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn reg64(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn store_string(m : @primus.Machine, addr : Int32, s : String) -> Unit raise {
  @primus.Memory::allocate(m, w64(addr), 64)
  for i, c in s {
    @primus.Memory::store(
      m,
      w64(addr + i),
      try! @types.Word::of_int(width=8, c.to_int()),
    )
  }
  @primus.Memory::store(
    m,
    w64(addr + s.length()),
    try! @types.Word::of_int(width=8, 0),
  )
}

///|
let strlen_src : String =
  #|(defun my-strlen (p)
  #|  (let ((n 0))
  #|    (while (not (points-to-null p))
  #|      (incr n p))
  #|    n))

///|
test "strlen over the machine memory" {
  let prog = lisp_program(strlen_src)
  let result = Ref(0)
  let (status, _) = @primus.Machine::run(
    empty_project(),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
      store_string(m, 0x1000, "hello, world")
    },
    start=m => {
      @primus_lisp.eval_fun(
        m,
        "my-strlen",
        [@primus.Value::of_word(m, w64(0x1000))],
        then=(_, r) => result.val = r.to_word().to_int(),
      )
    },
  )
  inspect(status, content="Normal")
  inspect(result.val, content="12")
}

///|
/// A program whose `main` calls `strlen(0x1000)` and saves the result in
/// `res`; the binary `strlen` always returns 99.
fn strlen_program() -> @project.Project {
  let rdi = reg64("RDI")
  let rax = reg64("RAX")
  let res = reg64("res")
  let strlen = @types.Sub::create(
    name="strlen",
    args=[
      @types.Arg::create(reg64("strlen_p"), Var(rdi), intent=In),
      @types.Arg::create(reg64("strlen_r"), Var(rax), intent=Out),
    ],
    blks=[@types.Blk::create(defs=[@types.Def::create(rax, Int(w64(99)))])],
  )
  let after = @types.Blk::create(defs=[@types.Def::create(res, Var(rax))])
  let entry = @types.Blk::create(
    defs=[@types.Def::create(rdi, Int(w64(0x1000)))],
    jmps=[
      @types.Jmp::create_call(
        @types.Call::create(
          target=Direct(strlen.tid()),
          return_label=Direct(after.tid()),
        ),
      ),
    ],
  )
  let main = @types.Sub::create(name="main", blks=[entry, after])
  let prog = @types.Program::create(subs=[main, strlen])
  @project.Project::empty(@core_theory.Target::x86_64()).with_program(prog)
}

///|
fn run_program(
  src : String,
  typecheck~ : Bool = false,
) -> (String, Array[String]) raise {
  let prog = lisp_program(strlen_src + src)
  let log : Array[String] = []
  let result = Ref("<unset>")
  let (status, _) = @primus.Machine::run(
    strlen_program(),
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
      if typecheck {
        log.push("type errors: \{@primus_lisp.typecheck(m)}")
      }
      store_string(m, 0x1000, "hello")
      m.observe(@primus_lisp.message, s => log.push(s))
      m.observe(@primus.call, c => {
        log.push(
          "call \{c.0}(\{c.1.map(v => v.to_word().to_int()).map(x => x.to_string()).join(",")})",
        )
      })
      m.observe(@primus.call_return, c => {
        log.push(
          "return \{c.0}(\{c.1.map(v => v.to_word().to_int()).map(x => x.to_string()).join(",")})",
        )
      })
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini=m => {
      if @primus.Env::is_set(m, reg64("res")) {
        result.val = @primus.Env::get(m, reg64("res"))
          .to_word()
          .to_int()
          .to_string()
      }
    },
  )
  match status {
    Normal => ()
    Exn(e) => log.push("error: " + @primus.exn_to_string(e))
  }
  (result.val, log)
}

///|
test "an external Lisp function replaces a binary subroutine" {
  let (r, log) = run_program("")
  inspect(r, content="99")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "call main()",
      #|  "call strlen(4096)",
      #|  "return strlen(4096,99)",
      #|  "return main()",
      #|]
    ),
  )
  let (r, log) = run_program(
    (
      #|(defun strlen (p)
      #|  (declare (external "strlen"))
      #|  (msg "lisp strlen")
      #|  (my-strlen p))
    ),
    typecheck=true,
  )
  inspect(r, content="5")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "type errors: 0",
      #|  "call main()",
      #|  "call strlen(4096)",
      #|  "lisp strlen",
      #|  "return strlen(4096,5)",
      #|  "return main()",
      #|]
    ),
  )
}

///|
test "advice ordering" {
  let (r, log) = run_program(
    (
      #|(defun strlen (p)
      #|  (declare (external "strlen"))
      #|  (msg "strlen")
      #|  (my-strlen p))
      #|(defun first-before (p)
      #|  (declare (advice :before strlen))
      #|  (msg "first-before $0" p))
      #|(defun second-before (p)
      #|  (declare (advice :before strlen))
      #|  (msg "second-before"))
      #|(defun double-after (p r)
      #|  (declare (advice :after strlen))
      #|  (msg "after $0" r)
      #|  (* r 2))
    ),
  )
  inspect(r, content="10")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "call main()",
      #|  "first-before 0x1000:64u",
      #|  "second-before",
      #|  "call strlen(4096)",
      #|  "strlen",
      #|  "return strlen(4096,5)",
      #|  "after 5:64u",
      #|  "return main()",
      #|]
    ),
  )
}

///|
test "signals are reflected into methods" {
  let (r, log) = run_program(
    (
      #|(defmethod call (name x)
      #|  (when (= name 'strlen)
      #|    (msg "method: calling $0 with $1" name x)))
      #|(defmethod call-return (name x r)
      #|  (msg "method: $0 returned $1" name r))
    ),
  )
  inspect(r, content="99")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "call main()",
      #|  "call strlen(4096)",
      #|  "method: calling #<strlen 2:63u> with 0x1000:64u",
      #|  "return strlen(4096,99)",
      #|  "method: #<strlen 2:63u> returned 0x63:64u",
      #|  "return main()",
      #|]
    ),
  )
}

///|
test "a primitive may fork in the middle of a Lisp function" {
  let prog = lisp_program(
    (
      #|(defun test ()
      #|  (let ((x 10))
      #|    (fork-machine)
      #|    (set x (+ x (machine-id)))
      #|    (msg "machine $0 x=$1" (machine-id) x)
      #|    x))
    ),
  )
  let log : Array[String] = []
  let (status, _) = @primus.Machine::run(
    empty_project(),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.define_primitive(
        m,
        "fork-machine",
        @primus_lisp.Closure::sync((m, _, _) => {
          m.fork()
          @primus.Value::b0(m)
        }),
      )
      @primus_lisp.define_primitive(
        m,
        "machine-id",
        @primus_lisp.Closure::sync((m, _, _) => {
          @primus.Value::of_int(m, width=64, m.current().to_int())
        }),
      )
      @primus_lisp.link_program(m, prog)
      m.observe(@primus_lisp.message, s => log.push(s))
    },
    start=m => {
      @primus_lisp.eval_fun(m, "test", [], then=(m, r) => {
        log.push("result in \{m.current()}: \{r.to_word().to_int()}")
      })
    },
    fini=m => {
      if m.current() != @primus.Id::global() &&
        m.status(@primus.Id::global()) is Live {
        m.kill(m.current())
        m.switch(@primus.Id::global())
      }
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "machine 1:64u x=0xB:64u",
      #|  "result in 1: 11",
      #|  "machine 0:64u x=0xA:64u",
      #|  "result in 0: 10",
      #|]
    ),
  )
}

///|
test "channel output" {
  let prog = lisp_program(
    (
      #|(defun hello ()
      #|  (channel-output 1 ?h ?i ?!)
      #|  (channel-output 1 10:8))
    ),
  )
  let out = Ref("")
  let (status, _) = @primus.Machine::run(
    empty_project(),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
    },
    start=m => @primus_lisp.eval_fun(m, "hello", []),
    fini=m => out.val = @primus_lisp.channel_output(m, 1),
  )
  inspect(status, content="Normal")
  inspect(out.val, content="hi!\n")
}
