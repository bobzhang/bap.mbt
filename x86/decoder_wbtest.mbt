// White-box tests of the legacy decoder: prefixes, REX/VEX and operands.

///|
test "decoder: prefixes and operand sizes" {
  // 66 41 89 c1: mov r9w, ax
  let d = parse_instr(X8664, b"\x66\x41\x89\xc1", 0)
  debug_inspect(
    d.op,
    content=(
      #|Mov(16, Oreg(9), Oreg(0), None)
    ),
  )
  assert_eq(d.prefix.opsize, 16)
  assert_eq(d.prefix.rm_extend, 8)
  assert_eq(d.next, 4)
  // f3 48 a5: rep movsq; the remaining prefixes keep only f3
  let d = parse_instr(X8664, b"\xf3\x48\xa5", 0)
  debug_inspect(d.op, content="Movs(64)")
  let (seg, pref) = parse_prefixes(X8664, d.pref)
  assert_true(seg is None)
  debug_inspect(pref, content="[243]")
  // 64 f0 66 ...: fs, lock and operand size are removed from the prefixes
  let (seg, pref) = parse_prefixes(X8664, [0x66, 0xf0, 0x64])
  assert_true(seg is Some({ name: "FS_BASE", .. }))
  debug_inspect(pref, content="[]")
  // 67 prefix in 32-bit mode selects 16-bit addressing
  let d = parse_instr(X86, b"\x67\x8b\x07", 0)
  assert_eq(d.prefix.addrsize, 16)
}

///|
test "decoder: vex prefixes" {
  // c5 f9 ef c1: vpxor xmm0, xmm0, xmm1
  let d = parse_instr(X8664, b"\xc5\xf9\xef\xc1", 0)
  debug_inspect(
    d.op,
    content=(
      #|Pbinop(128, PBin(Xor), "pxor", Ovec(0), Ovec(1), Some(Ovec(0)))
    ),
  )
  debug_inspect(d.pref, content="[102]")
  assert_true(d.prefix.vex is Some({ l: false, pp: 1, .. }))
  // c4 e2 79 00 c1: vpshufb xmm0, xmm0, xmm1 (map 0f 38)
  let d = parse_instr(X8664, b"\xc4\xe2\x79\x00\xc1", 0)
  debug_inspect(
    d.op,
    content=(
      #|Pshufb(128, Ovec(0), Ovec(1), Some(Ovec(0)))
    ),
  )
  // VEX is not decoded in 32-bit mode (c5 is LDS there)
  let failure = legacy_failure(X86, b"\xc5\xf9\xef\xc1", addr=0)
  assert_eq(failure, Some("no semantics: unsupported single opcode: c5"))
}

///|
test "decoder: immediates and jump targets" {
  // 83 c0 ff: add eax, -1 (the immediate is sign-extended to the opsize)
  let d = parse_instr(X86, b"\x83\xc0\xff", 0)
  debug_inspect(
    d.op,
    content=(
      #|Add(32, Oreg(0), Oimm({ bits: 4294967295, width: 32, signed: false }))
    ),
  )
  // 6a ff: push -1 keeps an 8-bit immediate (sign-extended by the lifter)
  let d = parse_instr(X8664, b"\x6a\xff", 0)
  debug_inspect(
    d.op,
    content=(
      #|Push(64, Oimm({ bits: 255, width: 8, signed: false }))
    ),
  )
  // 75 fe at 0x1000: the target wraps in the address width
  let d = parse_instr(X86, b"\x75\xfe", 0xfffffffe)
  match d.op {
    Jcc(Jabs(Oimm(target)), _) => assert_eq(target.bits, 0xfffffffe)
    _ => fail("expected a jcc")
  }
  // e8 with a negative displacement in 32-bit mode
  let d = parse_instr(X86, b"\xe8\xfb\xff\xff\xff", 0x1000)
  match d.op {
    Call(Oimm(target), ra) => {
      assert_eq(target.bits, 0x1000)
      assert_eq(ra.bits, 0x1005)
    }
    _ => fail("expected a call")
  }
}

///|
test "imm resize follows the signedness" {
  let i = Imm::new(0xff, 8)
  assert_eq(i.resize(32).bits, 0xff)
  assert_eq(i.as_signed().resize(32).bits, 0xffffffff)
  assert_eq(i.as_signed().to_int64(), -1)
  assert_eq(Imm::new(0x1234, 16).resize(8).bits, 0x34)
  // wide constants of vector operations
  debug_inspect(
    i.as_signed().to_exp(128),
    content=(
      #|Int(
      #|  {
      #|    bits_value: { width: 128, limbs: [18446744073709551615, 18446744073709551615] },
      #|    signed_value: false,
      #|  },
      #|)
    ),
  )
}

///|
test "segment bases from descriptor tables" {
  compute_segment_bases.val = true
  let bil = legacy_lift_exn(X86, b"\x8e\xe0", 0).0
  compute_segment_bases.val = false
  assert_eq(bil.length(), 2)
  assert_true(bil[1] is Move({ name: "FS_BASE", .. }, _))
}
