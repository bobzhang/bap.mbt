// Agreement of the x86 Primus Lisp semantics on LLVM's MCInst with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "lisp: alu" {
  inspect(
    family_report(lift_lisp, "alu"),
    content=(
      #|x86-64: cases=664 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=254 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: muldiv" {
  inspect(
    family_report(lift_lisp, "muldiv"),
    content=(
      #|x86-64: cases=173 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=126 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: shift" {
  inspect(
    family_report(lift_lisp, "shift"),
    content=(
      #|x86-64: cases=763 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=317 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: bits" {
  inspect(
    family_report(lift_lisp, "bits"),
    content=(
      #|x86-64: cases=237 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=99 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: move" {
  inspect(
    family_report(lift_lisp, "move"),
    content=(
      #|x86-64: cases=405 lifted=4 agree=4 mismatch=0 failed=0
      #|x86: cases=174 lifted=2 agree=2 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: control" {
  inspect(
    family_report(lift_lisp, "control"),
    content=(
      #|x86-64: cases=201 lifted=2 agree=2 mismatch=0 failed=0
      #|x86: cases=197 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: string" {
  inspect(
    family_report(lift_lisp, "string"),
    content=(
      #|x86-64: cases=132 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=99 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: sse" {
  inspect(
    family_report(lift_lisp, "sse"),
    content=(
      #|x86-64: cases=527 lifted=47 agree=47 mismatch=0 failed=0
      #|x86: cases=249 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: ssebasic" {
  inspect(
    family_report(lift_lisp, "ssebasic"),
    content=(
      #|x86-64: cases=192 lifted=2 agree=2 mismatch=0 failed=0
      #|x86: cases=96 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "lisp: lisp" {
  inspect(
    family_report(lift_lisp, "lisp"),
    content=(
      #|x86-64: cases=131 lifted=131 agree=131 mismatch=0 failed=0
      #|x86: cases=19 lifted=19 agree=19 mismatch=0 failed=0
    ),
  )
}
