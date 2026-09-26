// Agreement of the Basic lifter (project Basic decoder) with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "basic: alu" {
  inspect(
    family_report(lift_basic, "alu"),
    content=(
      #|x86-64: cases=664 lifted=656 agree=656 mismatch=0 failed=0
      #|x86: cases=254 lifted=244 agree=244 mismatch=0 failed=0
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
      #|x86-64: cases=405 lifted=388 agree=388 mismatch=0 failed=0
      #|x86: cases=174 lifted=172 agree=172 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: control" {
  inspect(
    family_report(lift_basic, "control"),
    content=(
      #|x86-64: cases=201 lifted=188 agree=188 mismatch=0 failed=0
      #|x86: cases=197 lifted=184 agree=184 mismatch=0 failed=0
    ),
  )
}

///|
test "basic: string" {
  inspect(
    family_report(lift_basic, "string"),
    content=(
      #|x86-64: cases=132 lifted=120 agree=120 mismatch=0 failed=0
      #|x86: cases=99 lifted=90 agree=90 mismatch=0 failed=0
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
