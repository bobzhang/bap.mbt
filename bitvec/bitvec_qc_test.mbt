// Property-based tests for `bitvec`: every operation is checked against a
// reference model on `@bigint.BigInt` (an unsigned value in [0, 2^width)).

///|
fn pow2(n : Int) -> @bigint.BigInt {
  (1N : @bigint.BigInt) << n
}

///|
fn modw(v : @bigint.BigInt, width : Int) -> @bigint.BigInt {
  let m = pow2(width)
  let r = v % m
  if r < 0N {
    r + m
  } else {
    r
  }
}

///|
/// The two's complement reading of an unsigned model value.
fn signed_of(v : @bigint.BigInt, width : Int) -> @bigint.BigInt {
  if v >= pow2(width - 1) {
    v - pow2(width)
  } else {
    v
  }
}

///|
fn big_abs(v : @bigint.BigInt) -> @bigint.BigInt {
  if v < 0N {
    -v
  } else {
    v
  }
}

///|
fn to_big(v : @bitvec.BitVec) -> @bigint.BigInt {
  @bigint.BigInt::from_string(v.to_hex(prefix=false), radix=16)
}

///|
fn of_big(width : Int, v : @bigint.BigInt) -> @bitvec.BitVec {
  try! @bitvec.from_hex(width~, modw(v, width).to_string(radix=16))
}

///|
fn[T] raises(f : () -> T raise) -> Bool {
  try f() catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
fn sign(x : Int) -> Int {
  if x < 0 {
    -1
  } else if x > 0 {
    1
  } else {
    0
  }
}

///|
/// Widths around every limb boundary plus small ones.
let interesting_widths : Array[Int] = [
  1, 2, 3, 7, 8, 16, 31, 32, 33, 63, 64, 65, 100, 127, 128, 129, 191, 192, 200,
]

///|
fn gen_width(size : Int, rs : @splitmix.RandomState) -> Int {
  if rs.next_uint(limit=4) == 0 {
    // any width up to 260
    1 + rs.next_uint(limit=260).reinterpret_as_int()
  } else {
    ignore(size)
    interesting_widths[rs
    .next_uint(limit=interesting_widths.length().reinterpret_as_uint())
    .reinterpret_as_int()]
  }
}

///|
/// A value of the given width biased towards edge cases.
fn gen_value(width : Int, rs : @splitmix.RandomState) -> @bigint.BigInt {
  match rs.next_uint(limit=10) {
    0 => 0N
    1 => 1N
    2 => pow2(width) - 1N // all ones
    3 => pow2(width - 1) // min signed
    4 => pow2(width - 1) - 1N // max signed
    5 => modw(@bigint.BigInt::from_uint64(rs.next_uint64()), width)
    _ => {
      let mut acc = 0N
      let limbs = (width + 63) / 64
      for _ in 0..<limbs {
        acc = (acc << 64) + @bigint.BigInt::from_uint64(rs.next_uint64())
      }
      modw(acc, width)
    }
  }
}

///|
struct BvCase {
  width : Int
  a : @bigint.BigInt
  b : @bigint.BigInt
  k : Int
} derive(Debug)

///|
impl @quickcheck.Arbitrary for BvCase with fn arbitrary(size, rs) {
  let width = gen_width(size, rs)
  let a = gen_value(width, rs)
  let b = gen_value(width, rs)
  let k = rs
    .next_uint(limit=(width + 8).reinterpret_as_uint())
    .reinterpret_as_int() -
    2
  { width, a, b, k, }
}

///|
impl @quickcheck.Shrink for BvCase with fn shrink(c) {
  let out : Array[BvCase] = []
  if c.a != 0N {
    out.push({ ..c, a: c.a >> 1, })
  }
  if c.b != 0N {
    out.push({ ..c, b: c.b >> 1, })
  }
  if c.k > 0 {
    out.push({ ..c, k: c.k / 2, })
  }
  out.iter()
}

///|
fn BvCase::x(self : BvCase) -> @bitvec.BitVec {
  of_big(self.width, self.a)
}

///|
fn BvCase::y(self : BvCase) -> @bitvec.BitVec {
  of_big(self.width, self.b)
}

///|
test "qc: generated cases cover limb boundaries and edge values" {
  @quickcheck.check(
    (c : BvCase) => to_big(c.x()) == c.a && c.x().width() == c.width,
    observe=c => {
      [
        @quickcheck.classify(c.width <= 64, "single limb"),
        @quickcheck.classify(c.width > 64, "multi limb"),
        @quickcheck.classify(c.width % 64 == 0, "width multiple of 64"),
        @quickcheck.classify(c.a == 0N, "a = 0"),
        @quickcheck.classify(c.a == pow2(c.width) - 1N, "a = all ones"),
        @quickcheck.classify(c.a >= pow2(c.width - 1), "a negative (signed)"),
      ]
    },
    count=500,
    seed=1,
  )
}

///|
test "qc: hex and string forms round trip" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let hex_ok = @bitvec.from_hex(width=c.width, x.to_hex()) == x
      let str_ok = @bitvec.from_string(x.to_string()) == x
      // `to_hex` prints exactly ceil(width / 4) digits
      let digits_ok = x.to_hex(prefix=false).length() == (c.width + 3) / 4
      hex_ok && str_ok && digits_ok
    },
    count=500,
    seed=2,
  )
}

///|
test "qc: of_uint64 and of_int64 reduce modulo the width" {
  @quickcheck.check(
    (input : (UInt64, Int)) => {
      let (v, wseed) = input
      let width = 1 + (wseed % 130).abs()
      let from_u = @bitvec.of_uint64(width~, v)
      let from_i = @bitvec.of_int64(width~, v.reinterpret_as_int64())
      let expected = modw(@bigint.BigInt::from_uint64(v), width)
      to_big(from_u) == expected && from_i == from_u
    },
    count=500,
    seed=3,
  )
}

///|
test "qc: add sub mul agree with arithmetic modulo 2^width" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      to_big(x.add(y)) == modw(c.a + c.b, c.width) &&
      to_big(x.sub(y)) == modw(c.a - c.b, c.width) &&
      to_big(x.mul(y)) == modw(c.a * c.b, c.width)
    },
    count=500,
    seed=4,
  )
}

///|
test "qc: unary neg lnot succ pred abs_signed agree with the model" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let w = c.width
      to_big(x.neg()) == modw(-c.a, w) &&
      to_big(x.lnot()) == pow2(w) - 1N - c.a &&
      to_big(x.succ()) == modw(c.a + 1N, w) &&
      to_big(x.pred()) == modw(c.a - 1N, w) &&
      to_big(x.abs_signed()) == modw(big_abs(signed_of(c.a, w)), w)
    },
    count=500,
    seed=5,
  )
}

///|
test "qc: bitwise and or xor agree with the model" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      to_big(x.bit_and(y)) == (c.a & c.b) &&
      to_big(x.bit_or(y)) == (c.a | c.b) &&
      to_big(x.bit_xor(y)) == (c.a ^ c.b)
    },
    count=500,
    seed=6,
  )
}

///|
test "qc: shifts agree with the model for every amount" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let w = c.width
      let k = c.k
      let (l, r, ar) = if k <= 0 {
        (c.a, c.a, c.a)
      } else {
        (
          modw(c.a << k, w),
          c.a >> k,
          // arithmetic shift: floor division of the signed value
          modw(signed_of(c.a, w) >> k, w),
        )
      }
      to_big(x.lshift(k)) == l &&
      to_big(x.rshift(k)) == r &&
      to_big(x.arshift(k)) == ar
    },
    observe=c => {
      [
        @quickcheck.classify(c.k <= 0, "k <= 0"),
        @quickcheck.classify(c.k >= c.width, "k >= width"),
        @quickcheck.classify(c.k > 0 && c.k % 64 == 0, "k multiple of 64"),
      ]
    },
    count=500,
    seed=7,
  )
}

///|
test "qc: unsigned div and rem agree with the model" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      let (q, r) = x.div_rem(y)
      if c.b == 0N {
        // documented BAP/SMT convention: x / 0 = all ones, x % 0 = x
        to_big(q) == pow2(c.width) - 1N && r == x
      } else {
        to_big(q) == c.a / c.b &&
        to_big(r) == c.a % c.b &&
        x.div(y) == q &&
        x.rem(y) == r
      }
    },
    count=400,
    seed=8,
  )
}

///|
test "qc: signed div and rem truncate towards zero" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      let w = c.width
      let sa = signed_of(c.a, w)
      let sb = signed_of(c.b, w)
      let q = big_abs(sa) / big_abs(sb)
      let q = if (sa < 0N) != (sb < 0N) { -q } else { q }
      let r = sa - q * sb
      to_big(x.sdiv(y)) == modw(q, w) && to_big(x.srem(y)) == modw(r, w)
    },
    filter=c => c.b != 0N,
    count=400,
    seed=9,
  )
}

///|
test "qc: comparisons agree with unsigned and signed readings" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      let w = c.width
      x.compare_unsigned(y) == sign(c.a.compare(c.b)) &&
      x.compare_signed(y) == sign(signed_of(c.a, w).compare(signed_of(c.b, w))) &&
      sign(x.compare(y)) == sign(c.a.compare(c.b)) &&
      x.equal(y) == (c.a == c.b)
    },
    count=500,
    seed=10,
  )
}

///|
test "qc: natural order compares values across widths" {
  @quickcheck.check(
    (input : (BvCase, BvCase)) => {
      let (c, d) = input
      sign(c.x().compare(d.x())) == sign(c.a.compare(d.a)) &&
      c.x().compare(d.x()) == -d.x().compare(c.x())
    },
    count=300,
    seed=11,
  )
}

///|
test "qc: nth msb lsb read single bits" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let w = c.width
      let i = if c.k < 0 { 0 } else if c.k >= w { w - 1 } else { c.k }
      let bit = ((c.a >> i) & 1N) == 1N
      x.nth(i) == bit &&
      x.lsb() == ((c.a & 1N) == 1N) &&
      x.msb() == (c.a >= pow2(w - 1)) &&
      x.is_zero() == (c.a == 0N)
    },
    count=300,
    seed=12,
  )
}

///|
test "qc: extract returns the selected bit slice" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let w = c.width
      let lo = c.k.abs() % w
      let hi = lo + (c.b % pow2(16)).to_int() % (w - lo)
      let slice = x.extract(hi~, lo~)
      slice.width() == hi - lo + 1 &&
      to_big(slice) == modw(c.a >> lo, hi - lo + 1)
    },
    count=500,
    seed=13,
  )
}

///|
test "qc: extract rejects out of range bounds" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      raises(() => x.extract(hi=c.width + c.k.abs())) &&
      raises(() => x.extract(lo=-1 - c.k.abs()))
    },
    count=100,
    seed=14,
  )
}

///|
test "qc: concat widen truncate agree with the model" {
  @quickcheck.check(
    (input : (BvCase, BvCase)) => {
      let (c, d) = input
      let hi = c.x()
      let lo = d.x()
      let cat = hi.concat(lo)
      let wide = hi.widen(width=c.width + d.width)
      let narrow_w = 1 + c.k.abs() % c.width
      cat.width() == c.width + d.width &&
      to_big(cat) == (c.a << d.width) + d.a &&
      cat.extract(hi=d.width - 1) == lo &&
      cat.extract(lo=d.width) == hi &&
      to_big(wide) == c.a &&
      to_big(hi.truncate(width=narrow_w)) == modw(c.a, narrow_w)
    },
    count=300,
    seed=15,
  )
}

///|
test "qc: to_bytes and of_bytes round trip in both byte orders" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let le = x.to_bytes(endian=LittleEndian)
      let be = x.to_bytes(endian=BigEndian)
      let len = (c.width + 7) / 8
      let expected_le = modw(c.a, len * 8).to_octets(length=len)
      le.length() == len &&
      be.to_array() == expected_le.to_array() &&
      le.to_array().rev() == be.to_array() &&
      @bitvec.of_bytes(le, endian=LittleEndian, width=c.width) == x &&
      @bitvec.of_bytes(be, endian=BigEndian, width=c.width) == x
    },
    count=300,
    seed=16,
  )
}

///|
test "qc: gcd and gcd_ext satisfy the Bezout identity" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let y = c.y()
      let g = x.gcd(y)
      let (g2, s, t) = x.gcd_ext(y)
      // reference: Euclid on the unsigned model
      let mut m = c.a
      let mut n = c.b
      while n != 0N {
        let r = m % n
        m = n
        n = r
      }
      to_big(g) == m && g2 == g && s.mul(x).add(t.mul(y)) == g
    },
    count=200,
    seed=17,
  )
}

///|
test "qc: integer conversions agree with the model" {
  @quickcheck.check(
    (c : BvCase) => {
      let x = c.x()
      let fits64 = c.a < pow2(64)
      let u_ok = try x.to_uint64() catch {
        _ => !fits64
      } noraise {
        v => fits64 && @bigint.BigInt::from_uint64(v) == c.a
      }
      let i64_ok = try x.to_int64() catch {
        _ => !fits64
      } noraise {
        v => fits64 && v.reinterpret_as_uint64() == c.a.to_uint64()
      }
      u_ok &&
      i64_ok &&
      x.fits_int64() == (c.a < pow2(63)) &&
      x.fits_int32() == (c.a < pow2(31)) &&
      x.fits_int() == x.fits_int32()
    },
    count=300,
    seed=18,
  )
}

///|
test "qc: select picks the listed bits, zero outside the width" {
  @quickcheck.check(
    (input : (BvCase, Array[Int])) => {
      let (c, raw) = input
      let bits = raw.map(i => i % (c.width + 4))
      let out = @bitvec.select(bits, c.x())
      if bits.is_empty() {
        out == @bitvec.b0()
      } else {
        let mut expected = 0N
        for i, bit in bits {
          if bit >= 0 && bit < c.width && ((c.a >> bit) & 1N) == 1N {
            expected = expected | pow2(i)
          }
        }
        out.width() == bits.length() && to_big(out) == expected
      }
    },
    count=200,
    seed=19,
  )
}
