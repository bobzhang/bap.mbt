///|
test "normalization wraps values to width" {
  inspect(@bitvec.of_int(width=7, 13 + 1024).to_hex(), content="0x0d")
  inspect(@bitvec.of_int(width=7, 13 - 1024).to_hex(), content="0x0d")
  inspect(@bitvec.of_int(width=2, 3 + 4).to_hex(), content="0x3")
  inspect(@bitvec.of_int(width=2, 3 - 4).to_hex(), content="0x3")
  inspect(@bitvec.of_int(width=3, -1).to_hex(), content="0x7")
}

///|
test "basic predicates and string formatting" {
  let zero = @bitvec.b0()
  let one = @bitvec.b1()
  inspect(zero.to_hex(), content="0x0")
  inspect(one.to_hex(), content="0x1")
  inspect(@bitvec.of_int(width=4, 7).to_string(), content="0x7:4u")
  assert_true(zero.is_zero())
  assert_true(!one.is_zero())
  assert_true(one.lsb())
  assert_true(one.msb())
}

///|
test "byte conversion preserves endian order" {
  let deadbeef = @bitvec.of_uint64(width=32, 0xdeadbeef)
  assert_true(
    deadbeef.to_bytes(endian=LittleEndian).to_array().map(b => b.to_int()) ==
    [0xef, 0xbe, 0xad, 0xde],
  )
  assert_true(
    deadbeef.to_bytes(endian=BigEndian).to_array().map(b => b.to_int()) ==
    [0xde, 0xad, 0xbe, 0xef],
  )
  inspect(
    @bitvec.of_bytes(b"\xef\xbe\xad\xde", endian=LittleEndian).to_hex(),
    content="0xdeadbeef",
  )
  inspect(
    @bitvec.of_bytes(b"\xde\xad\xbe\xef", endian=BigEndian).to_hex(),
    content="0xdeadbeef",
  )
}

///|
test "concat and extract match BAP bit numbering cases" {
  let high = @bitvec.of_int(width=16, 0xdead)
  let low = @bitvec.of_int(width=16, 0xbeef)
  inspect(high.concat(low).to_hex(), content="0xdeadbeef")
  inspect(@bitvec.append(16, 16, high, low).to_hex(), content="0xdeadbeef")
  inspect(
    @bitvec.append(
      12,
      20,
      @bitvec.of_int(width=24, 0xbadadd),
      @bitvec.of_int(width=24, 0xbadbeef),
    ).to_hex(),
    content="0xadddbeef",
  )
  let nybble = @bitvec.of_int(width=8, 0xba)
  let repeated = @bitvec.repeat(4, times=3, nybble)
  inspect(repeated.to_hex(), content="0xaaa")
  assert_true(repeated.width() == 12)
  let byte_values = [
    @bitvec.of_int(width=16, 0x1de),
    @bitvec.of_int(width=8, 0xad),
    @bitvec.of_int(width=8, 0xbe),
    @bitvec.of_int(width=8, 0xef),
  ]
  inspect(@bitvec.concat(8, byte_values).to_hex(), content="0xdeadbeef")
  assert_true(@bitvec.repeat(4, times=0, nybble) == @bitvec.b0())
  let empty_values : Array[@bitvec.BitVec] = []
  assert_true(@bitvec.concat(8, empty_values) == @bitvec.b0())
  let selected = @bitvec.select([3, 0, 1, 2], @bitvec.of_int(width=4, 0xd))
  inspect(selected.to_hex(), content="0xb")
  assert_true(selected.width() == 4)
  inspect(
    @bitvec.select([0, 0, 2, 1], @bitvec.of_int(width=4, 0x5)).to_hex(),
    content="0x7",
  )
  assert_true(
    @bitvec.select([8], @bitvec.of_int(width=8, 0xff)) == @bitvec.b0(),
  )
  let empty_bits : Array[Int] = []
  assert_true(@bitvec.select(empty_bits, high) == @bitvec.b0())
  let word = @bitvec.of_int(width=16, 0xdad5)
  inspect(word.extract(lo=0xC).to_hex(), content="0xd")
  inspect(word.extract(lo=0x8).to_hex(), content="0xda")
  inspect(word.extract(hi=0x7).to_hex(), content="0xd5")
  inspect(word.extract(hi=0x3).to_hex(), content="0x5")
  inspect(word.extract(hi=0xB, lo=0x4).to_hex(), content="0xad")
}

///|
test "arithmetic and shifts are modulo bit width" {
  let x = @bitvec.of_int(width=8, 0xff)
  let one = @bitvec.of_int(width=8, 1)
  inspect(x.add(one).to_hex(), content="0x00")
  inspect(@bitvec.of_int(width=8, 0).sub(one).to_hex(), content="0xff")
  inspect(
    @bitvec.of_int(width=8, 0x11).mul(@bitvec.of_int(width=8, 0x0f)).to_hex(),
    content="0xff",
  )
  inspect(one.lshift(10).to_hex(), content="0x00")
  inspect(x.rshift(2).to_hex(), content="0x3f")
  inspect(x.arshift(2).to_hex(), content="0xff")
}

///|
test "division gcd and lcm use unsigned semantics" {
  let x = @bitvec.of_int(width=8, 0x10)
  let y = @bitvec.of_int(width=8, 0x0c)
  inspect(x.gcd(y).to_hex(), content="0x04")
  inspect(x.lcm(y).to_hex(), content="0x30")
  inspect(
    @bitvec.of_int(width=8, 0x1c).lcm(@bitvec.of_int(width=8, 0x23)).to_hex(),
    content="0x8c",
  )
  let (q, r) = @bitvec.of_int(width=8, 20).div_rem(@bitvec.of_int(width=8, 6))
  inspect(q.to_hex(), content="0x03")
  inspect(r.to_hex(), content="0x02")
  let (g, a, b) = x.gcd_ext(y)
  inspect(g.to_hex(), content="0x04")
  inspect(a.to_hex(), content="0x01")
  inspect(b.to_hex(), content="0xff")
  assert_true(a.mul(x).add(b.mul(y)) == g)
}

///|
test "translated BAP monomorphic bitvector comparisons reject mixed widths" {
  let zero32 = @bitvec.of_int(width=32, 0)
  let zero1 = @bitvec.b0()
  try zero32.compare_unsigned(zero1) catch {
    IncompatibleWidths(lhs~, rhs~) => {
      assert_true(lhs == 32)
      assert_true(rhs == 1)
    }
    _ => fail("expected IncompatibleWidths")
  } noraise {
    _ => fail("expected IncompatibleWidths")
  }
  try zero32.compare_signed(zero1) catch {
    IncompatibleWidths(lhs~, rhs~) => {
      assert_true(lhs == 32)
      assert_true(rhs == 1)
    }
    _ => fail("expected IncompatibleWidths")
  } noraise {
    _ => fail("expected IncompatibleWidths")
  }
}

///|
test "hex parsing truncates to the requested width" {
  inspect(@bitvec.from_hex(width=16, "0xdeadbeef").to_hex(), content="0xbeef")
  inspect(@bitvec.from_hex(width=4, "f").lnot().to_hex(), content="0x0")
  try @bitvec.from_hex(width=8, "xz") catch {
    InvalidHexDigit(c) => inspect(c, content="x")
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected invalid hex digit")
  }
}

///|
test "string parsing accepts BAP boolean suffixed and unsuffixed width forms" {
  assert_true(@bitvec.from_string("false") == @bitvec.b0())
  assert_true(@bitvec.from_string("true") == @bitvec.b1())
  assert_true(@bitvec.from_string("0:1u") == @bitvec.b0())
  assert_true(@bitvec.from_string("0:1") == @bitvec.b0())
  assert_true(@bitvec.from_string("1:1") == @bitvec.b1())
  inspect(@bitvec.from_string("7:4u").to_hex(), content="0x7")
  inspect(@bitvec.from_string("7:4").to_hex(), content="0x7")
  inspect(@bitvec.from_string("7:3").to_hex(), content="0x7")
  inspect(@bitvec.from_string("7:3s").to_hex(), content="0x7")
  inspect(@bitvec.from_string("7:2").to_hex(), content="0x3")
  inspect(@bitvec.from_string("-1:3").to_hex(), content="0x7")
  inspect(@bitvec.from_string("0xdeadbeef:16").to_hex(), content="0xbeef")
  try @bitvec.from_string("7") catch {
    InvalidLiteral(text) => inspect(text, content="7")
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected invalid bitvector literal")
  }
}
