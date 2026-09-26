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
test "legacy sse: well-typed lifting of the decoded forms" {
  let ok : Array[Bytes] = [
    // movlps/movhps/movlhps/movhlps and stores
    b"\x0f\x12\xc1", b"\x0f\x13\x03", b"\x0f\x17\x03", b"\x66\x0f\x12\x03",
    // VEX forms with a vvvv operand
     b"\xc5\xf8\x12\xc1", b"\xc5\xf8\x16\x03", b"\xc5\xfa\x10\xc2", b"\xc5\xf9\x60\xc1",
    b"\xc5\xf9\x74\xc1", b"\xc5\xf9\x70\xc1\x1b", b"\xc5\xfd\xef\xc1",
    // movd/movq/movdqa/lddqu
     b"\x66\x0f\x7e\x03", b"\xf3\x0f\x7e\x03", b"\x66\x0f\xd6\x03", b"\xf2\x0f\xf0\x03",
    b"\x0f\x29\x03", b"\x0f\x6f\xc1", b"\x0f\x7f\x03",
    // packed operations
     b"\x66\x0f\x38\x29\xc1", b"\x66\x0f\x38\x37\xc1", b"\x66\x0f\x38\x38\xc1", b"\x66\x0f\x38\x39\xc1",
    b"\x66\x0f\x38\x3a\xc1", b"\x66\x0f\x38\x3b\xc1", b"\x66\x0f\x38\x3c\xc1", b"\x66\x0f\x38\x3d\xc1",
    b"\x66\x0f\x38\x3e\xc1", b"\x66\x0f\x38\x3f\xc1", b"\x66\x0f\x38\x20\xc1", b"\x66\x0f\x38\x21\xc1",
    b"\x66\x0f\x38\x22\xc1", b"\x66\x0f\x38\x23\xc1", b"\x66\x0f\x38\x24\xc1", b"\x66\x0f\x38\x25\xc1",
    b"\x66\x0f\x38\x35\xc1", b"\x66\x0f\x69\xc1", b"\x66\x0f\x6a\xc1", b"\x66\x0f\x6d\xc1",
    b"\x66\x0f\x65\xc1", b"\x66\x0f\x66\xc1", b"\x66\x0f\x71\xd0\x02", b"\x66\x0f\x71\xf0\x02",
    b"\x66\x0f\x71\xe0\x02", b"\x66\x0f\x73\xd8\x04", b"\x66\x0f\xd1\xc1", b"\x66\x0f\xd2\xc1",
    b"\x66\x0f\xd3\xc1", b"\x66\x0f\xe1\xc1", b"\x66\x0f\xe2\xc1", b"\x66\x0f\xf1\xc1",
    b"\x66\x0f\xf2\xc1", b"\x66\x0f\xf3\xc1", b"\x66\x0f\xe3\xc1", b"\x66\x0f\xf9\xc1",
    b"\x66\x0f\xfb\xc1", b"\x66\x0f\xfd\xc1", b"\x0f\xd7\xc1", b"\x0f\xfc\xc1", b"\x66\x0f\x38\x00\x03",
    b"\x66\x0f\x74\x03", b"\x66\x0f\x3a\x0f\x03\x04",
    // pcmpestri/pcmpistri with every aggregation mode
     b"\x66\x0f\x3a\x61\xc1\x00", b"\x66\x0f\x3a\x61\xc1\x05", b"\x66\x0f\x3a\x61\xc1\x08",
    b"\x66\x0f\x3a\x63\xc1\x4c", b"\x66\x0f\x3a\x63\xc1\x14", b"\x66\x0f\x3a\x63\xc1\x3a",
  ]
  for bytes in ok {
    let bil = @x86.lift_legacy(X8664, bytes, addr=0x400000) catch {
      e => fail("\{hex_bytes(bytes)}: \{e.message()}")
    }
    ignore(bil)
  }
  // explicit-length pcmpestri: upstream folds the element checks in front
  // of the computation of the (clamped) length, so the checks read the
  // temporary before it is assigned
  let bil = lift64(b"\x66\x0f\x3a\x61\xc1\x18")
  inspect(
    bil[0].to_string(),
    content=(
      #|%is_valid_xmm1_ele0_17:imm1 := (0:64u < %sz_1:imm64)
    ),
  )
  // the mask forms (pcmpestrm/pcmpistrm) assign a 128-bit mask to the
  // 256-bit YMM0 upstream ("FIXME: ymms should be used instead of xmms"):
  // the program is ill-typed
  for bytes in [b"\x66\x0f\x3a\x60\xc1\x08", b"\x66\x0f\x3a\x62\xc1\x40"] {
    let r = try @x86.lift_legacy(X8664, bytes, addr=0) catch {
      IllTyped(..) => "ill-typed"
      e => e.message()
    } noraise {
      _ => "lifted"
    }
    assert_eq(r, "ill-typed")
  }
  // forms rejected by the decoder or the lifter
  let rejected : Array[Bytes] = [
    b"\x0f\x38\x29\xc1", b"\x0f\x70\xc1\x00", b"\x66\x0f\x71\xc0\x02", b"\x0f\x38\x10\xc1",
    b"\x0f\x3a\x44\xc1\x00", b"\xc5\xfd\xd7\xc1", b"\x0f\x01\xc8", b"\x0f\xae\x03",
    b"\x0f\xc7\x03",
  ]
  for bytes in rejected {
    let failure = @x86.legacy_failure(X8664, bytes, addr=0)
    if failure is None {
      let rejected = try lift64(bytes) catch {
        _ => true
      } noraise {
        _ => false
      }
      assert_true(rejected, msg=hex_bytes(bytes))
    }
  }
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
