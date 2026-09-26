// Type checker tests.

///|
fn type_errors_of(src : String) -> Array[String] raise {
  let loader = @primus_lisp.Loader::of_files([("test.lisp", src)])
  let prog = @primus_lisp.load_program(loader, ["test"])
  prog.type_errors().map(e => e.summary())
}

///|
test "type errors" {
  debug_inspect(
    type_errors_of("(defun f (x:8) (set x 1:16))"),
    content=(
      #|["test.lisp:1: expected i16 got i8"]
    ),
  )
  debug_inspect(
    type_errors_of("(defun g () (undefined-fn 1))"),
    content=(
      #|["test.lisp:1: unresolved function undefined-fn"]
    ),
  )
  debug_inspect(
    type_errors_of("(defun h (x) (+ x y))"),
    content=(
      #|[
      #|  "test.lisp:1: unresolved variable y",
      #|  "test.lisp:1: unresolved function +",
      #|]
    ),
  )
  debug_inspect(
    type_errors_of("(defun k (x:8) x) (defun m () (k 1:16))"),
    content=(
      #|["test.lisp:1: expected i8 got i16"]
    ),
  )
  debug_inspect(
    type_errors_of("(defmethod init () 1)"),
    content=(
      #|["test.lisp:1: unresolved signal init"]
    ),
  )
  debug_inspect(
    type_errors_of("(defun p () (let ((*foo* 1)) *foo*))"),
    content=(
      #|["test.lisp:1: unresolved parameter *foo*"]
    ),
  )
}
