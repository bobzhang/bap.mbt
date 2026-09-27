// Agreement of the Basic lifter (project Basic decoder) with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "basic: alu" {
  inspect(
    family_report(lift_basic, "alu"),
    content=(
      #|x86-64: cases=664 lifted=664 agree=664 mismatch=0 failed=0
      #|x86: cases=254 lifted=254 agree=254 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: muldiv" {
  inspect(
    family_report(lift_basic, "muldiv"),
    content=(
      #|x86-64: cases=173 lifted=173 agree=173 mismatch=0 failed=0
      #|x86: cases=126 lifted=126 agree=126 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: shift" {
  inspect(
    family_report(lift_basic, "shift"),
    content=(
      #|x86-64: cases=763 lifted=760 agree=760 mismatch=0 failed=0
      #|x86: cases=317 lifted=314 agree=314 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: bits" {
  inspect(
    family_report(lift_basic, "bits"),
    content=(
      #|x86-64: cases=237 lifted=237 agree=237 mismatch=0 failed=0
      #|x86: cases=99 lifted=99 agree=99 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: move" {
  inspect(
    family_report(lift_basic, "move"),
    content=(
      #|x86-64: cases=405 lifted=405 agree=405 mismatch=0 failed=0
      #|x86: cases=174 lifted=174 agree=174 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: control" {
  inspect(
    family_report(lift_basic, "control"),
    content=(
      #|x86-64: cases=201 lifted=201 agree=201 mismatch=0 failed=0
      #|x86: cases=197 lifted=197 agree=197 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: string" {
  inspect(
    family_report(lift_basic, "string"),
    content=(
      #|x86-64: cases=132 lifted=132 agree=132 mismatch=0 failed=0
      #|x86: cases=99 lifted=99 agree=99 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: sse" {
  inspect(
    family_report(lift_basic, "sse"),
    content=(
      #|x86-64: cases=527 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=249 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: ssebasic" {
  inspect(
    family_report(lift_basic, "ssebasic"),
    content=(
      #|x86-64: cases=192 lifted=0 agree=0 mismatch=0 failed=0
      #|x86: cases=96 lifted=0 agree=0 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: lisp" {
  inspect(
    family_report(lift_basic, "lisp"),
    content=(
      #|x86-64: cases=131 lifted=30 agree=30 mismatch=0 failed=0
      #|x86: cases=19 lifted=16 agree=16 mismatch=0 failed=0
    ),
  )
}
