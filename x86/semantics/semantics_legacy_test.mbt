// Agreement of the legacy x86 lifter (`x86-legacy`) on the raw bytes with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "legacy: alu" {
  inspect(
    family_report(c => lift_legacy(c), "alu"),
    content=(
      #|x86-64: cases=664 lifted=664 agree=664 mismatch=0 failed=0
      #|x86: cases=254 lifted=254 agree=254 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: muldiv" {
  inspect(
    family_report(c => lift_legacy(c), "muldiv"),
    content=(
      #|x86-64: cases=173 lifted=173 agree=173 mismatch=0 failed=0
      #|x86: cases=126 lifted=126 agree=126 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: shift" {
  inspect(
    family_report(c => lift_legacy(c), "shift"),
    content=(
      #|x86-64: cases=763 lifted=574 agree=574 mismatch=0 failed=0
      #|x86: cases=317 lifted=235 agree=235 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: bits" {
  inspect(
    family_report(c => lift_legacy(c), "bits"),
    content=(
      #|x86-64: cases=237 lifted=237 agree=237 mismatch=0 failed=0
      #|x86: cases=99 lifted=99 agree=99 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: move" {
  inspect(
    family_report(c => lift_legacy(c), "move"),
    content=(
      #|x86-64: cases=405 lifted=366 agree=366 mismatch=0 failed=0
      #|x86: cases=174 lifted=164 agree=164 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: control" {
  inspect(
    family_report(c => lift_legacy(c), "control"),
    content=(
      #|x86-64: cases=201 lifted=188 agree=188 mismatch=0 failed=0
      #|x86: cases=197 lifted=184 agree=184 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: string" {
  inspect(
    family_report(c => lift_legacy(c), "string"),
    content=(
      #|x86-64: cases=132 lifted=120 agree=120 mismatch=0 failed=0
      #|x86: cases=99 lifted=90 agree=90 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: sse" {
  inspect(
    family_report(c => lift_legacy(c), "sse"),
    content=(
      #|x86-64: cases=527 lifted=364 agree=364 mismatch=0 failed=0
      #|x86: cases=249 lifted=165 agree=165 mismatch=0 failed=0
    ),
  )
}

///|
test "legacy: ssebasic" {
  inspect(
    family_report(c => lift_legacy(c), "ssebasic"),
    content=(
      #|x86-64: cases=192 lifted=190 agree=190 mismatch=0 failed=0
      #|x86: cases=96 lifted=95 agree=95 mismatch=0 failed=0
    ),
  )
}
