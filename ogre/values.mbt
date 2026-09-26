// Parsing and printing of Ogre scalar values.
//
// Upstream parses field values with sexplib converters (`int64_of_sexp`,
// `bool_of_sexp`, `float_of_sexp`) and prints them with the matching
// `sexp_of_*` functions. The helpers below reproduce those OCaml conversions
// (`Int64.of_string`, `float_of_string`, and sexplib's `%.15G`/`%.17G`
// float printer) so that normalized documents are spelled exactly like BAP.

///|
fn digit_value(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if c >= 'a' && c <= 'z' {
    c.to_int() - 'a'.to_int() + 10
  } else if c >= 'A' && c <= 'Z' {
    c.to_int() - 'A'.to_int() + 10
  } else {
    99
  }
}

///|
/// OCaml `Int64.of_string`: optional sign, `0x`/`0o`/`0b`/`0u` prefixes,
/// `_` separators after the first digit, signed range checks for plain
/// decimals and full 64-bit (wrapping) range for the other bases.
fn parse_ocaml_int64(text : String) -> Int64? {
  let chars = text.to_array()
  let n = chars.length()
  let mut i = 0
  let mut negative = false
  if i < n && chars[i] == '-' {
    negative = true
    i += 1
  } else if i < n && chars[i] == '+' {
    i += 1
  }
  let mut base = 10
  let mut signed_decimal = true
  if i + 1 < n && chars[i] == '0' {
    match chars[i + 1] {
      'x' | 'X' => {
        base = 16
        signed_decimal = false
        i += 2
      }
      'o' | 'O' => {
        base = 8
        signed_decimal = false
        i += 2
      }
      'b' | 'B' => {
        base = 2
        signed_decimal = false
        i += 2
      }
      'u' | 'U' => {
        signed_decimal = false
        i += 2
      }
      _ => ()
    }
  }
  if i >= n || digit_value(chars[i]) >= base {
    return None
  }
  let ubase = base.to_uint64()
  let limit = UInt64::lnot(0) / ubase
  let mut result : UInt64 = 0
  for j in i..<n {
    let c = chars[j]
    if c == '_' {
      continue
    }
    let d = digit_value(c)
    if d >= base {
      return None
    }
    if result > limit {
      return None
    }
    let next = result * ubase + d.to_uint64()
    if next < result * ubase {
      return None
    }
    result = next
  }
  if signed_decimal {
    let bound : UInt64 = 0x8000000000000000
    if (!negative && result >= bound) || (negative && result > bound) {
      return None
    }
  }
  let value = result.reinterpret_as_int64()
  Some(if negative { -value } else { value })
}

///|
fn parse_ocaml_bool(text : String) -> Bool? {
  match text {
    "true" | "True" => Some(true)
    "false" | "False" => Some(false)
    _ => None
  }
}

///|
fn parse_hex_float(body : String) -> Double? {
  // body is the text after the `0x` prefix (sign already removed)
  let chars = body.to_array()
  let n = chars.length()
  let mut i = 0
  let mut mantissa : UInt64 = 0
  let mut exponent = 0
  let mut digits = 0
  let mut seen_point = false
  while i < n && chars[i] != 'p' && chars[i] != 'P' {
    let c = chars[i]
    if c == '.' {
      if seen_point {
        return None
      }
      seen_point = true
    } else {
      let d = digit_value(c)
      if d >= 16 {
        return None
      }
      digits += 1
      if mantissa < 0x0100000000000000 {
        mantissa = mantissa * 16 + d.to_uint64()
        if seen_point {
          exponent -= 4
        }
      } else if !seen_point {
        exponent += 4
      }
    }
    i += 1
  }
  if digits == 0 {
    return None
  }
  if i < n {
    // exponent part
    i += 1
    let mut negative = false
    if i < n && (chars[i] == '-' || chars[i] == '+') {
      negative = chars[i] == '-'
      i += 1
    }
    if i >= n {
      return None
    }
    let mut e = 0
    while i < n {
      let d = digit_value(chars[i])
      if d >= 10 {
        return None
      }
      if e < 100000 {
        e = e * 10 + d
      }
      i += 1
    }
    exponent += if negative { -e } else { e }
  }
  Some(mantissa.to_double() * @math.pow(2.0, exponent.to_double()))
}

///|
/// OCaml `float_of_string`: `_` separators are ignored, `inf`/`infinity`/`nan`
/// are accepted case-insensitively, and hexadecimal floats are supported.
fn parse_ocaml_float(text : String) -> Double? {
  let cleaned = StringBuilder()
  for c in text {
    if c != '_' {
      cleaned.write_char(c)
    }
  }
  let s = cleaned.to_string()
  if s == "" {
    return None
  }
  let (negative, body) = match s.get_char(0) {
    Some('-') => (true, s.view(start_offset=1).to_owned())
    Some('+') => (false, s.view(start_offset=1).to_owned())
    _ => (false, s)
  }
  let lower = body.to_lower()
  let magnitude = match lower {
    "inf" | "infinity" => Some(@double.infinity)
    "nan" => Some(@double.not_a_number)
    _ =>
      if lower.has_prefix("0x") {
        parse_hex_float(lower.view(start_offset=2).to_owned())
      } else if lower.has_prefix("+") ||
        lower.has_prefix("-") ||
        lower.contains("inf") ||
        lower.contains("nan") {
        None
      } else {
        try @string.parse_double(body) catch {
          _ => None
        } noraise {
          value => Some(value)
        }
      }
  }
  magnitude.map(value => if negative { -value } else { value })
}

///|
fn pow10(k : Int) -> @bigint.BigInt {
  @bigint.BigInt::from_int(10).pow(@bigint.BigInt::from_int(k))
}

///|
fn pow2(k : Int) -> @bigint.BigInt {
  @bigint.BigInt::from_int(1) << k
}

///|
/// Exact rational `m * 2^e * 10^s` as a `(numerator, denominator)` pair.
fn scaled_fraction(
  m : UInt64,
  e : Int,
  s : Int,
) -> (@bigint.BigInt, @bigint.BigInt) {
  let mut num = @bigint.BigInt::from_uint64(m)
  let mut den = @bigint.BigInt::from_int(1)
  if e >= 0 {
    num = num * pow2(e)
  } else {
    den = den * pow2(-e)
  }
  if s >= 0 {
    num = num * pow10(s)
  } else {
    den = den * pow10(-s)
  }
  (num, den)
}

///|
/// C `printf("%.<precision>G", x)` for a finite, non-zero double.
fn format_g_finite(x : Double, precision : Int) -> String {
  let bits = x.reinterpret_as_uint64()
  let negative = bits >> 63 != 0
  let exp_bits = ((bits >> 52) & 0x7ff).to_int()
  let frac = bits & 0x000fffffffffffff
  let (m, e) = if exp_bits == 0 {
    (frac, -1074)
  } else {
    (frac | 0x0010000000000000, exp_bits - 1075)
  }
  // decimal exponent: 10^exp10 <= |x| < 10^(exp10 + 1)
  let mut exp10 = @math.floor(@math.log10(x.abs())).to_int()
  let one = @bigint.BigInt::from_int(1)
  for _ in 0..<4 {
    let (num, den) = scaled_fraction(m, e, -exp10)
    if num < den {
      exp10 -= 1
    } else {
      let (num1, den1) = scaled_fraction(m, e, -(exp10 + 1))
      if num1 >= den1 {
        exp10 += 1
      } else {
        break
      }
    }
  }
  let (num, den) = scaled_fraction(m, e, precision - 1 - exp10)
  let mut q = num / den
  let r = num % den
  let twice = r * @bigint.BigInt::from_int(2)
  if twice > den || (twice == den && q % @bigint.BigInt::from_int(2) == one) {
    q = q + one
  }
  if q == pow10(precision) {
    q = pow10(precision - 1)
    exp10 += 1
  }
  let digits = q.to_string()
  let out = StringBuilder()
  if negative {
    out.write_char('-')
  }
  if exp10 < -4 || exp10 >= precision {
    out.write_string(digits.view(end_offset=1).to_owned())
    let rest = trim_trailing_zeros(digits.view(start_offset=1).to_owned())
    if rest != "" {
      out.write_char('.')
      out.write_string(rest)
    }
    out.write_char('E')
    out.write_char(if exp10 < 0 { '-' } else { '+' })
    let magnitude = exp10.abs()
    if magnitude < 10 {
      out.write_char('0')
    }
    out.write_string(magnitude.to_string())
  } else if exp10 >= 0 {
    out.write_string(digits.view(end_offset=exp10 + 1).to_owned())
    let rest = trim_trailing_zeros(
      digits.view(start_offset=exp10 + 1).to_owned(),
    )
    if rest != "" {
      out.write_char('.')
      out.write_string(rest)
    }
  } else {
    let rest = trim_trailing_zeros("0".repeat(-exp10 - 1) + digits)
    out.write_char('0')
    if rest != "" {
      out.write_char('.')
      out.write_string(rest)
    }
  }
  out.to_string()
}

///|
fn trim_trailing_zeros(text : String) -> String {
  let mut end = text.length()
  while end > 0 && text[end - 1] == '0' {
    end -= 1
  }
  text.view(end_offset=end).to_owned()
}

///|
/// C `printf("%.<precision>G", x)`.
fn format_g(x : Double, precision : Int) -> String {
  if x.is_nan() {
    "NAN"
  } else if x == @double.infinity {
    "INF"
  } else if x == @double.neg_infinity {
    "-INF"
  } else if x == 0.0 {
    if x.reinterpret_as_uint64() >> 63 != 0 {
      "-0"
    } else {
      "0"
    }
  } else {
    format_g_finite(x, precision)
  }
}

///|
/// sexplib's `default_string_of_float`: `%.15G` when it round-trips,
/// `%.17G` otherwise.
fn sexp_string_of_float(x : Double) -> String {
  let short = format_g(x, 15)
  match parse_ocaml_float(short) {
    Some(y) if y == x => short
    _ => format_g(x, 17)
  }
}
