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
      #|x86: cases=174 lifted=0 agree=0 mismatch=0 failed=0
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
      #|x86-64: cases=527 lifted=47 agree=39 mismatch=8 failed=0
      #|andnps xmm4, xmm0 [0f55e0]: XMM4=0xfe5d7c795fbdf9bff7ee89f77f7dbae5 expected 0x381d184104b4000e2224887000501024
      #|andnps xmm4, xmmword ptr [rsi] [0f5526]: XMM4=0xd79db9ffffac7ee5bfebbeadedf64bea expected 0x4301808020084a002f818c0484020202
      #|andnpd xmm3, xmm7 [660f55df]: XMM3=0xfb5feffeec7e5ff3ffed7bf2ed5ffebb expected 0xc2082802884e0b7281c000020100a208
      #|andnpd xmm3, xmmword ptr [rsi] [660f551e]: XMM3=0xebf977feeffb137bedb7aeb9fddf5dfa expected 0xe8e153a842601118e4828a084804008a
      #|shufps xmm3, xmm6, 50 [0fc6de32]: XMM3=0x974bf600277cd3ef974bf600a4733402 expected 0x974bf600277cd3ef070f5ba778a9fb4a
      #|shufps xmm1, xmm0, 27 [0fc6c81b]: XMM1=0x8429706be0301a9f0ac92f54e4642431 expected 0x8429706be0301a9fe10baf9e555dedab
      #|shufps xmm4, xmm2, 0 [0fc6e200]: XMM4=0xcae79d51cae79d51cae79d51cae79d51 expected 0xcae79d51cae79d51ffffffffffffffff
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
