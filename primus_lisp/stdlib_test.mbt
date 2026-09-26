// The standard library (core and posix) in the Primus machine.

///|
test "type check the standard library in the machine" {
  let errors : Array[String] = []
  let count = Ref(-1)
  let (status, _) = @primus.Machine::run(empty_project(), init=m => {
    @primus_lisp.init_runtime(m)
    @primus_lisp.load_library(m)
    m.observe(@primus_lisp.type_error, e => errors.push(e.summary()))
    count.val = @primus_lisp.typecheck(m)
  })
  inspect(status, content="Normal")
  inspect(
    count.val,
    content=(
      #|10
    ),
  )
  debug_inspect(
    errors,
    content=(
      #|[
      #|  "errno.lisp:11: unresolved variable posix:brk",
      #|  "locale.lisp:11: unresolved variable posix:brk",
      #|  "stdlib.lisp:12: unresolved variable posix:environ",
      #|  "simple-memory-allocator.lisp:141: unresolved variable posix:brk",
      #|  "simple-memory-allocator.lisp:76: unresolved variable posix:brk",
      #|  "errno.lisp:10: unresolved variable posix:brk",
      #|  "locale.lisp:10: unresolved variable posix:brk",
      #|  "simple-memory-allocator.lisp:71: unresolved variable posix:brk",
      #|  "simple-memory-allocator.lisp:140: unresolved variable posix:brk",
      #|  "simple-memory-allocator.lisp:142: unresolved variable posix:brk",
      #|]
    ),
  )
  // `brk` and `environ` are provided by the binary (the loader), with them
  // the library is well-typed
  let count = Ref(-1)
  let (status, _) = @primus.Machine::run(empty_project(), init=m => {
    @primus_lisp.init_runtime(m)
    @primus_lisp.load_library(m)
    @primus.Env::set(m, reg64("brk"), @primus.Value::of_word(m, w64(0x4000)))
    @primus.Env::set(m, reg64("environ"), @primus.Value::of_word(m, w64(0)))
    count.val = @primus_lisp.typecheck(m)
  })
  inspect(status, content="Normal")
  inspect(count.val, content="0")
}

///|
test "the standard library strlen and memory allocator" {
  let src =
    #|(in-package posix)
    #|(defun test (s)
    #|  (let ((p (malloc 16)))
    #|    (memcpy p s 6)
    #|    (strlen p)))
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([("test.lisp", src)]),
    @primus_lisp.Loader::embedded(["lisp", "site-lisp"]),
  ])
  let run = (name : String) => {
    let result = Ref("<none>")
    let (status, _) = @primus.Machine::run(
      empty_project(),
      init=m => {
        @primus_lisp.init_runtime(m)
        @primus_lisp.load_library(
          m,
          features=["core", "posix", "test"],
          loader~,
        )
        @primus.Env::set(
          m,
          reg64("brk"),
          @primus.Value::of_word(m, w64(0x40000)),
        )
        @primus.Env::set(m, reg64("environ"), @primus.Value::of_word(m, w64(0)))
        ignore(@primus_lisp.typecheck(m))
        store_string(m, 0x1000, "hello")
      },
      start=m => {
        @primus_lisp.eval_fun(
          m,
          name,
          [@primus.Value::of_word(m, w64(0x1000))],
          then=(_, r) => result.val = r.to_word().to_string(),
        )
      },
    )
    match status {
      Normal => result.val
      Exn(e) => "error: " + @primus.exn_to_string(e)
    }
  }
  inspect(run("posix:strlen"), content="5:64u")
  inspect(run("posix:test"), content="5:64u")
}
