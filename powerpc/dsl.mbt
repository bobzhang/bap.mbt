// Port of BAP `plugins/powerpc/powerpc_dsl.ml`: convenience constructors
// and bit-slicing helpers on top of RTL. Bit positions in the helpers below
// are numbered from the most significant bit, as in the Power ISA.

///|
pub let bit : Int32 = 1

///|
pub let byte : Int32 = 8

///|
pub let halfword : Int32 = 16

///|
pub let word : Int32 = 32

///|
pub let doubleword : Int32 = 64

///|
pub let quadword : Int32 = 128

///|
/// One-bit zero.
pub let zero : RtlExp = RtlExp::of_word(@types.Word::b0())

///|
/// One-bit one.
pub let one : RtlExp = RtlExp::of_word(@types.Word::b1())

///|
/// Expression of `width` bits, all set to one.
pub fn ones(width : Int32) -> RtlExp {
  RtlExp::of_word(make_word(width, -1))
}

///|
/// Fresh temporary of `width` bits with the given sign.
pub fn var_(width : Int32, sign : Sign) -> RtlExp {
  RtlExp::tmp(width).with_sign(sign)
}

///|
/// Fresh signed temporary of `width` bits.
pub fn svar(width : Int32) -> RtlExp {
  var_(width, Signed)
}

///|
/// Fresh unsigned temporary of `width` bits.
pub fn uvar(width : Int32) -> RtlExp {
  var_(width, Unsigned)
}

///|
/// Constant `value` of `width` bits with the given sign.
pub fn const_(width : Int32, value : Int32, sign : Sign) -> RtlExp {
  RtlExp::of_word(make_word(width, value.to_int64())).with_sign(sign)
}

///|
/// Signed constant.
pub fn sconst(width : Int32, value : Int32) -> RtlExp {
  const_(width, value, Signed)
}

///|
/// Unsigned constant.
pub fn uconst(width : Int32, value : Int32) -> RtlExp {
  const_(width, value, Unsigned)
}

///|
fn digit_value(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    'a'..<='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..<='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
fn parse_digits(
  digits : String,
  base : Int32,
  width : Int32,
) -> @types.Word raise @mc.LiftError {
  let fail_parse = () => {
    @mc.LiftError::Failure("PowerPC lifter fail: bad numeral \{digits}")
  }
  if digits.is_empty() {
    raise fail_parse()
  }
  let base_w = make_word(width, base.to_int64())
  let mut acc = make_word(width, 0)
  for c in digits {
    match digit_value(c) {
      Some(d) if d < base =>
        acc = acc.mul(base_w).add(make_word(width, d.to_int64())) catch {
            _ => raise fail_parse()
          }
      _ => raise fail_parse()
    }
  }
  acc
}

///|
/// Constant from a textual numeral. `0x`, `0o` and `0b` prefixes select the
/// base and the width is the number of listed bits; decimal numerals get the
/// number of significant bits. Underscores are ignored.
pub fn of_string(s : String, sign : Sign) -> RtlExp raise @mc.LiftError {
  let s = s.replace_all(old="_", new="")
  let prefixed : Array[(String, Int32, Int32)] = [
    ("0x", 16, 4),
    ("0o", 8, 3),
    ("0b", 2, 1),
  ]
  let word = for entry in prefixed {
    let (prefix, base, bits) = entry
    if s.has_prefix(prefix) {
      let digits = s[prefix.length():].to_owned()
      break parse_digits(digits, base, digits.length() * bits)
    }
  } nobreak {
    // enough room for any decimal numeral: log2(10) < 4
    let wide = parse_digits(s, 10, Int32::max(1, s.length() * 4))
    let mut numbits = 0
    for i in 0..<wide.width() {
      let bit_set = wide.extract(hi=i, lo=i) catch {
        _ => raise Failure("PowerPC lifter fail: bad numeral \{s}")
      }
      if bit_set.is_one() {
        numbits = i + 1
      }
    }
    wide.extract(hi=Int32::max(numbits, 1) - 1, lo=0) catch {
      _ => raise Failure("PowerPC lifter fail: bad numeral \{s}")
    }
  }
  RtlExp::of_word(word).with_sign(sign)
}

///|
/// First (most significant) `bits` bits.
pub fn RtlExp::first(self : RtlExp, bits : Int32) -> RtlExp {
  self.extract(self.width - 1, self.width - bits)
}

///|
/// Last (least significant) `bits` bits.
pub fn RtlExp::last(self : RtlExp, bits : Int32) -> RtlExp {
  self.extract(bits - 1, 0)
}

///|
/// High `width` bits.
pub fn RtlExp::high(self : RtlExp, width : Int32) -> RtlExp {
  self.first(width)
}

///|
/// Low `width` bits.
pub fn RtlExp::low(self : RtlExp, width : Int32) -> RtlExp {
  self.last(width)
}

///|
/// Most significant bit.
pub fn RtlExp::msb(self : RtlExp) -> RtlExp {
  let h = self.width - 1
  self.extract(h, h)
}

///|
/// Least significant bit.
pub fn RtlExp::lsb(self : RtlExp) -> RtlExp {
  self.extract(0, 0)
}

///|
/// `e.nth(width, index)` extracts the `index`-th `width`-sized portion,
/// counting from the most significant portion. When `width` does not divide
/// the expression width, the leftover high bits are skipped.
pub fn RtlExp::nth(self : RtlExp, width : Int32, index : Int32) -> RtlExp {
  let total = self.width
  let n = total / width
  let x = n - index - 1
  let hi = (x + 1) * width - 1
  let lo = x * width
  let sh = total - n * width
  if sh > 0 {
    self.extract(hi + sh, lo + sh)
  } else {
    self.extract(hi, lo)
  }
}

///|
/// `e.bits(left, right)` extracts bits `left..right` inclusive, numbered from
/// the most significant bit (upstream DSL `extract`). If the expression is
/// narrower than the requested range, it is zero-extended instead.
pub fn RtlExp::bits(self : RtlExp, left : Int32, right : Int32) -> RtlExp {
  let width = self.width
  let target_width = right - left + 1
  if width >= target_width {
    self.extract(width - left - 1, width - right - 1)
  } else {
    self.extract(target_width - 1, 0)
  }
}

///|
/// Width of the expression as a constant of the same width.
pub fn RtlExp::width_exp(self : RtlExp) -> RtlExp {
  RtlExp::of_word(make_word(self.width, self.width.to_int64()))
}

///|
/// `when_(cond, code)` = `if_(cond, code, [])`
pub fn when_(cond : RtlExp, then_ : Array[Rtl]) -> Rtl {
  If(cond, then_, [])
}

///|
/// `ifnot(cond, code)` = `if_(cond, [], code)`
pub fn ifnot(cond : RtlExp, else_ : Array[Rtl]) -> Rtl {
  If(cond, [], else_)
}

///|
/// A `switch` clause.
pub(all) enum Clause {
  Case(RtlExp, Array[Rtl])
  Default(Array[Rtl])
}

///|
pub fn case(x : RtlExp, code : Array[Rtl]) -> Clause {
  Case(x, code)
}

///|
pub fn default(code : Array[Rtl]) -> Clause {
  Default(code)
}

///|
/// Chain of `if`s comparing `exp` against each case; the first `default`
/// clause (if any) handles the remaining values.
pub fn switch_(
  exp : RtlExp,
  clauses : Array[Clause],
) -> Rtl raise @mc.LiftError {
  let default_code = for clause in clauses {
    if clause is Default(code) {
      break code
    }
  } nobreak {
    []
  }
  let cases = []
  for clause in clauses {
    if clause is Case(x, code) {
      cases.push((x, code))
    }
  }
  match cases {
    [] => raise Failure("PowerPC lifter fail: empty switch")
    [(x, code), .. rest] => {
      let else_ = rest.rev_fold(init=default_code, (acc, case_) => {
        let (x, code) = case_
        [If(exp.eq(x), code, acc)]
      })
      If(exp.eq(x), code, else_)
    }
  }
}
