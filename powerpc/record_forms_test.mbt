// Record (`Rc=1`) forms not covered by the per-group tests.

///|
test "slw. and srw. set CR0" {
  let ops = [reg("R10"), reg("R9"), reg("R11")]
  let r = run(R32, "SLWo", ops, init=[("R9", 1), ("R11", 31)])
  r.check("R10", 0x8000_0000)
  r.check_cr0(1, 0, 0)
  // on 64-bit targets the word result is zero-extended, hence positive
  run(R64, "SLWo", ops, init=[("R9", 1), ("R11", 31)]).check_cr0(0, 1, 0)
  let r = run(R32, "SRWo", ops, init=[("R9", 0x8000_0000), ("R11", 31)])
  r.check("R10", 1)
  r.check_cr0(0, 1, 0)
  run(R32, "SRWo", ops, init=[("R9", 1), ("R11", 32)]).check_cr0(0, 0, 1)
}

///|
test "mulhwu." {
  for a in archs {
    let r = run(a, "MULHWUo", [reg("R1"), reg("R2"), reg("R3")], init=[
      ("R2", 0x4242),
      ("R3", 0xABCD_EFAA),
    ])
    r.check("R1", (0x4242UL * 0xABCD_EFAA) >> 32)
    r.check_cr0(0, 1, 0)
  }
}
