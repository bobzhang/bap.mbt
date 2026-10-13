// Printing of floating-point literals as C99 hexadecimal floats (`%a`).
//
// The mangling holds the bits of the value as big-endian hex digits; the
// value is printed like `printf("%a")` of the reference host: normal and
// subnormal values alike as `0x1.<hex>p<exp>`, trailing zeros dropped.

///|
fn hex_value(c : UInt16) -> UInt64 {
  if is_digit(c) {
    (c - '0').to_uint64()
  } else {
    (c - 'a').to_uint64() + 10
  }
}

///|
/// Formats a double given by its fields.
fn format_hex_double(
  sign : Bool,
  exponent : Int32,
  fraction : UInt64,
) -> String {
  let sb = StringBuilder()
  if sign {
    sb.write_string("-")
  }
  if exponent == 0x7ff {
    sb.write_string(if fraction == 0 { "inf" } else { "nan" })
    return sb.to_string()
  }
  if exponent == 0 && fraction == 0 {
    sb.write_string("0x0p+0")
    return sb.to_string()
  }
  let mut e = exponent - 1023
  let mut m = fraction
  if exponent == 0 {
    // Normalize a subnormal value.
    e = -1022
    while (m & (1UL << 52)) == 0 {
      m = m << 1
      e -= 1
    }
    m = m & ((1UL << 52) - 1)
  }
  sb.write_string("0x1")
  if m != 0 {
    let digits = "0123456789abcdef"
    let mut n = 13
    while ((m >> ((13 - n) * 4)) & 15) == 0 {
      n -= 1
    }
    sb.write_string(".")
    for i in 0..<n {
      let d = ((m >> ((12 - i) * 4)) & 15).to_int()
      sb.write_char(digits.get_char(d).unwrap())
    }
  }
  sb.write_string("p")
  if e >= 0 {
    sb.write_string("+")
  }
  sb.write_string(e.to_string())
  sb.to_string()
}

///|
fn print_float_literal(
  contents : StringView,
  kind : Int32,
  ob : Output,
) -> Unit {
  let n = float_mangled_size(kind)
  if contents.length() < n {
    return
  }
  let mut bits = 0UL
  for i in 0..<n {
    bits = (bits << 4) | hex_value(contents.at(i))
  }
  match kind {
    FLOAT_FLOAT => {
      // Printed as the `double` it is promoted to, with an `f` suffix.
      let sign = bits >> 31 != 0
      let exp = ((bits >> 23) & 0xff).to_int()
      let frac = bits & 0x7fffff
      let text = if exp == 0xff {
        format_hex_double(sign, 0x7ff, frac)
      } else if exp == 0 && frac == 0 {
        format_hex_double(sign, 0, 0)
      } else if exp == 0 {
        // A subnormal float is a normal double.
        let mut e = -126
        let mut m = frac
        while (m & (1UL << 23)) == 0 {
          m = m << 1
          e -= 1
        }
        format_hex_double(sign, e + 1023, (m & 0x7fffff) << 29)
      } else {
        format_hex_double(sign, exp - 127 + 1023, frac << 29)
      }
      ob.add(text)
      ob.add("f")
    }
    _ => {
      let sign = bits >> 63 != 0
      let exp = ((bits >> 52) & 0x7ff).to_int()
      let frac = bits & ((1UL << 52) - 1)
      ob.add(format_hex_double(sign, exp, frac))
      if kind == FLOAT_LONG_DOUBLE {
        ob.add("L")
      }
    }
  }
}
