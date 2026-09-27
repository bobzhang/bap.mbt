///|
test "documentation index" {
  let loader = @primus_lisp.Loader::of_files([
    (
      "doc.lisp",
      (
        #|(defconstant answer 42 "the answer")
        #|(defmacro twice (x) "(twice X) evaluates X twice" (prog x x))
        #|(defun inc (x) "(inc X) is X + 1" (+ x 1))
        #|(defparameter *limit* 10 "the limit")
      ),
    ),
  ])
  let prog = @primus_lisp.load_program(loader, ["doc"])
  let index = @primus_lisp.documentation(prog)
  inspect(
    index
    .map(c => {
      "\{c.0}: \{c.1.map(e => "\{e.0.show()} - \{e.1.desc}").join("; ")}"
    })
    .join("\n"),
    content=(
      #|Macros: twice - (twice X) evaluates X twice
      #|Constants: answer - the answer
      #|Functions: inc - (inc X) is X + 1
      #|Parameters: *limit* - the limit
    ),
  )
  let inc = index[2].1[0].1
  inspect(
    inc.code.unwrap(),
    content="(defun inc (x) \"(inc X) is X + 1\" (+ x 1))",
  )
  inspect(
    inc.loc.unwrap(),
    content=(
      #|File "doc.lisp", line 3, characters 0-42
    ),
  )
}
