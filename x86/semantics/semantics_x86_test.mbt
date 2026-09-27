// Agreement of the `x86` providers (per-opcode, then legacy) on LLVM's MCInst with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "x86: alu" {
  inspect(
    family_report(lift_x86, "alu"),
    content=(
      #|x86-64: cases=664 lifted=664 agree=664 mismatch=0 failed=0
      #|x86: cases=254 lifted=254 agree=254 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: muldiv" {
  inspect(
    family_report(lift_x86, "muldiv"),
    content=(
      #|x86-64: cases=173 lifted=173 agree=173 mismatch=0 failed=0
      #|x86: cases=126 lifted=126 agree=126 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: shift" {
  inspect(
    family_report(lift_x86, "shift"),
    content=(
      #|x86-64: cases=763 lifted=574 agree=574 mismatch=0 failed=0
      #|x86: cases=317 lifted=235 agree=235 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: bits" {
  inspect(
    family_report(lift_x86, "bits"),
    content=(
      #|x86-64: cases=237 lifted=237 agree=237 mismatch=0 failed=0
      #|x86: cases=99 lifted=99 agree=99 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: move" {
  inspect(
    family_report(lift_x86, "move"),
    content=(
      #|x86-64: cases=405 lifted=383 agree=383 mismatch=0 failed=0
      #|x86: cases=174 lifted=167 agree=167 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: control" {
  inspect(
    family_report(lift_x86, "control"),
    content=(
      #|x86-64: cases=201 lifted=188 agree=188 mismatch=0 failed=0
      #|x86: cases=197 lifted=184 agree=184 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: string" {
  inspect(
    family_report(lift_x86, "string"),
    content=(
      #|x86-64: cases=132 lifted=120 agree=120 mismatch=0 failed=0
      #|x86: cases=99 lifted=90 agree=90 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: sse" {
  inspect(
    family_report(lift_x86, "sse"),
    content=(
      #|x86-64: cases=527 lifted=364 agree=364 mismatch=0 failed=0
      #|x86: cases=249 lifted=165 agree=165 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: ssebasic" {
  inspect(
    family_report(lift_x86, "ssebasic"),
    content=(
      #|x86-64: cases=192 lifted=190 agree=190 mismatch=0 failed=0
      #|x86: cases=96 lifted=95 agree=95 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: lisp" {
  inspect(
    family_report(lift_x86, "lisp"),
    content=(
      #|x86-64: cases=131 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=19 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}
