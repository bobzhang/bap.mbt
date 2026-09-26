// SSE/AVX moves and packed integer instructions of the legacy lifter.

///|
fn ymm(o : Outcome, n : Int) -> @types.Word raise {
  match o.values.get("YMM\{n}") {
    Some(BilWord(w)) => w
    _ => fail("YMM\{n} is undefined")
  }
}

///|
/// Bits `lo`..`lo + 63` of a vector register.
fn ymm_q(o : Outcome, n : Int, q : Int) -> UInt64 raise {
  ymm(o, n).extract(hi=q * 64 + 63, lo=q * 64).to_uint64()
}

///|
/// Run `setup` then `bytes` in 64-bit mode.
fn exec64_seq(
  setup : Array[Bytes],
  bytes : Bytes,
  regs? : Array[(String, UInt64)] = [],
) -> Outcome raise {
  let stmts : Array[@types.Stmt] = []
  for s in setup {
    stmts.push_iter(lift64(s).iter())
  }
  stmts.push_iter(lift64(bytes).iter())
  run(stmts, machine(X8664, regs~))
}

///|
test "legacy sse moves" {
  // movdqu xmm0, [rbx]
  let o = exec64(b"\xf3\x0f\x6f\x03", regs=[("RBX", DATA)])
  assert_eq(ymm_q(o, 0, 0), load_mem(o, DATA, 8))
  assert_eq(ymm_q(o, 0, 1), load_mem(o, DATA + 8, 8))
  // the upper half of YMM0 is preserved (no VEX)
  let before = exec64(b"\x90")
  assert_eq(ymm_q(o, 0, 2), ymm_q(before, 0, 2))
  // movdqa [rbx], xmm1 checks the alignment
  let o = exec64(b"\x66\x0f\x7f\x0b", regs=[("RBX", DATA)])
  assert_eq(load_mem(o, DATA, 8), ymm_q(o, 1, 0))
  let o = exec64(b"\x66\x0f\x7f\x0b", regs=[("RBX", DATA + 4)])
  assert_eq(o.exn, Some(13))
  // movd xmm0, eax zero-extends to 128 bits
  let o = exec64(b"\x66\x0f\x6e\xc0", regs=[("RAX", 0x1122334455667788)])
  assert_eq((ymm_q(o, 0, 0), ymm_q(o, 0, 1)), (0x55667788, 0))
  // movq rax, xmm1 (66 48 0f 7e c8)
  let o = exec64(b"\x66\x48\x0f\x7e\xc8")
  assert_eq(get_word(o, "RAX"), ymm_q(o, 1, 0))
  // movss xmm0, xmm1 merges the low 32 bits
  let o = exec64(b"\xf3\x0f\x10\xc1")
  let before = exec64(b"\x90")
  assert_eq(ymm_q(o, 0, 0) & 0xffffffff, ymm_q(before, 1, 0) & 0xffffffff)
  assert_eq(ymm_q(o, 0, 0) >> 32, ymm_q(before, 0, 0) >> 32)
  // movsd xmm0, [rbx] zero-extends the loaded 64 bits to 128 bits
  let o = exec64(b"\xf2\x0f\x10\x03", regs=[("RBX", DATA)])
  assert_eq((ymm_q(o, 0, 0), ymm_q(o, 0, 1)), (load_mem(o, DATA, 8), 0))
  // movhps xmm0, [rbx]
  let o = exec64(b"\x0f\x16\x03", regs=[("RBX", DATA)])
  assert_eq(ymm_q(o, 0, 1), load_mem(o, DATA, 8))
  assert_eq(ymm_q(o, 0, 0), ymm_q(before, 0, 0))
  // vmovdqu ymm0, [rbx] (VEX.256)
  let o = exec64(b"\xc5\xfe\x6f\x03", regs=[("RBX", DATA)])
  assert_eq(ymm_q(o, 0, 3), load_mem(o, DATA + 24, 8))
  // vmovdqa xmm0, xmm1 (VEX.128) zeroes the upper half
  let o = exec64(b"\xc5\xf9\x6f\xc1")
  assert_eq((ymm_q(o, 0, 2), ymm_q(o, 0, 3)), (0, 0))
}

///|
test "legacy sse packed integer operations" {
  // pxor xmm0, xmm0 zeroes the low 128 bits
  let o = exec64(b"\x66\x0f\xef\xc0")
  assert_eq((ymm_q(o, 0, 0), ymm_q(o, 0, 1)), (0, 0))
  // pcmpeqb xmm0, xmm0 sets all bytes
  let o = exec64(b"\x66\x0f\x74\xc0")
  assert_eq(
    (ymm_q(o, 0, 0), ymm_q(o, 0, 1)),
    (0xffffffffffffffff, 0xffffffffffffffff),
  )
  // pmovmskb eax, xmm0 after that
  let o = exec64_seq([b"\x66\x0f\x74\xc0"], b"\x66\x0f\xd7\xc0")
  assert_eq(get_word(o, "RAX"), 0xffff)
  // paddd xmm0, xmm1 on known values: load both from memory first
  let o = exec64_seq(
    [b"\xf3\x0f\x6f\x03", b"\xf3\x0f\x6f\x4b\x10"],
    b"\x66\x0f\xfe\xc1",
    regs=[("RBX", DATA)],
  )
  let a = load_mem(o, DATA, 4)
  let b = load_mem(o, DATA + 16, 4)
  assert_eq(ymm_q(o, 0, 0) & 0xffffffff, (a + b) & 0xffffffff)
  // psubb and pminub on the same data
  let o = exec64_seq(
    [b"\xf3\x0f\x6f\x03", b"\xf3\x0f\x6f\x4b\x10"],
    b"\x66\x0f\xda\xc1",
    regs=[("RBX", DATA)],
  )
  let a = load_mem(o, DATA, 1)
  let b = load_mem(o, DATA + 16, 1)
  assert_eq(ymm_q(o, 0, 0) & 0xff, if a < b { a } else { b })
  // pslldq xmm0, 8 shifts by bytes
  let o = exec64_seq([b"\xf3\x0f\x6f\x03"], b"\x66\x0f\x73\xf8\x08", regs=[
    ("RBX", DATA),
  ])
  assert_eq((ymm_q(o, 0, 0), ymm_q(o, 0, 1)), (0, load_mem(o, DATA, 8)))
  // psrlq xmm0, 4
  let o = exec64_seq([b"\xf3\x0f\x6f\x03"], b"\x66\x0f\x73\xd0\x04", regs=[
    ("RBX", DATA),
  ])
  assert_eq(ymm_q(o, 0, 1), load_mem(o, DATA + 8, 8) >> 4)
  // punpcklbw xmm0, xmm1
  let o = exec64_seq(
    [b"\xf3\x0f\x6f\x03", b"\xf3\x0f\x6f\x4b\x10"],
    b"\x66\x0f\x60\xc1",
    regs=[("RBX", DATA)],
  )
  let lo = ymm_q(o, 0, 0)
  assert_eq(lo & 0xff, load_mem(o, DATA, 1))
  assert_eq((lo >> 8) & 0xff, load_mem(o, DATA + 16, 1))
  // pshufd xmm0, xmm1, 0x1b reverses the dwords
  let o = exec64_seq([b"\xf3\x0f\x6f\x0b"], b"\x66\x0f\x70\xc1\x1b", regs=[
    ("RBX", DATA),
  ])
  assert_eq(ymm_q(o, 0, 0) & 0xffffffff, load_mem(o, DATA + 12, 4))
  // pshufb xmm0, xmm1 with a zero mask broadcasts byte 0
  let o = exec64_seq([b"\x66\x0f\xef\xc9"], b"\x66\x0f\x38\x00\xc1")
  let before = exec64(b"\x90")
  let b0 = ymm_q(before, 0, 0) & 0xff
  assert_eq(ymm_q(o, 0, 0), b0 * 0x0101010101010101)
  // ptest xmm0, xmm0 after pxor sets ZF and CF
  let o = exec64_seq([b"\x66\x0f\xef\xc0"], b"\x66\x0f\x38\x17\xc0")
  assert_eq((get_flag(o, "ZF"), get_flag(o, "CF")), (1, 1))
  // pmovzxbw xmm0, xmm1
  let o = exec64_seq([b"\xf3\x0f\x6f\x0b"], b"\x66\x0f\x38\x30\xc1", regs=[
    ("RBX", DATA),
  ])
  assert_eq(ymm_q(o, 0, 0) & 0xffff, load_mem(o, DATA, 1))
  // palignr xmm0, xmm1, 4
  let o = exec64_seq(
    [b"\xf3\x0f\x6f\x03", b"\xf3\x0f\x6f\x4b\x10"],
    b"\x66\x0f\x3a\x0f\xc1\x04",
    regs=[("RBX", DATA)],
  )
  assert_eq(ymm_q(o, 0, 0) & 0xffffffff, load_mem(o, DATA + 20, 4))
  // pcmpistri xmm0, xmm1, 0x0c (equal ordered, unsigned bytes) finds the
  // position of a substring: both registers hold the same data, so the
  // match is at index 0
  let o = exec64_seq(
    [b"\xf3\x0f\x6f\x03", b"\xf3\x0f\x6f\x0b"],
    b"\x66\x0f\x3a\x63\xc1\x0c",
    regs=[("RBX", DATA)],
  )
  assert_eq(get_word(o, "RCX"), 0)
  // xorps is handled by the Lisp semantics upstream
  assert_eq(
    @x86.legacy_failure(X8664, b"\x0f\x57\xc0", addr=0),
    Some("no semantics: now it is handled by lisp loader"),
  )
}
