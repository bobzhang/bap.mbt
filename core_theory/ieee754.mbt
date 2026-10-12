///|
pub(all) struct Ieee754Parameters {
  base : Int32
  bias : Int32
  k : Int32
  p : Int32
  w : Int32
  t : Int32
} derive(Eq, Hash, Debug)

///|
pub extend Ieee754Parameters with Eq::{not_equal, equal}

///|
pub extend Ieee754Parameters with Hash::{hash, hash_combine}

///|
pub extend Ieee754Parameters with Debug::{to_repr}

///|
fn ieee754_parameters(
  base~ : Int32,
  bias~ : Int32,
  k~ : Int32,
  p~ : Int32,
  w~ : Int32,
  t~ : Int32,
) -> Ieee754Parameters {
  { base, bias, k, p, w, t, }
}

///|
fn ieee754_pow(base : Int32, exponent : Int32) -> Int32 {
  let mut result = 1
  for _ in 0..<exponent {
    result = result * base
  }
  result
}

///|
fn ieee754_binary_generic(width : Int32) -> Ieee754Parameters {
  let rounded = @math.round(4.0 * @math.log2(width.to_double())).to_int()
  let precision = width - rounded + 13
  let exponent_width = rounded - 13
  let trailing = width - exponent_width - 1
  ieee754_parameters(
    base=2,
    bias=ieee754_pow(2, width - precision - 1) - 1,
    k=width,
    p=precision,
    w=exponent_width,
    t=trailing,
  )
}

///|
fn ieee754_decimal_generic(width : Int32) -> Ieee754Parameters {
  let precision = 9 * width / 32 - 2
  let exponent = width / 16 + 3
  let emax = 3 * ieee754_pow(2, exponent)
  ieee754_parameters(
    base=10,
    bias=emax + precision - 2,
    k=width,
    p=precision,
    w=width / 16 + 9,
    t=15 * width / 16 - 10,
  )
}

///|
pub fn Ieee754Parameters::binary16() -> Ieee754Parameters {
  ieee754_parameters(base=2, bias=15, k=16, p=11, w=5, t=10)
}

///|
pub fn Ieee754Parameters::binary32() -> Ieee754Parameters {
  ieee754_parameters(base=2, bias=127, k=32, p=24, w=8, t=23)
}

///|
pub fn Ieee754Parameters::binary64() -> Ieee754Parameters {
  ieee754_binary_generic(64)
}

///|
pub fn Ieee754Parameters::binary80() -> Ieee754Parameters {
  ieee754_parameters(base=2, bias=16383, k=80, p=64, w=15, t=64)
}

///|
pub fn Ieee754Parameters::binary128() -> Ieee754Parameters {
  ieee754_binary_generic(128)
}

///|
pub fn Ieee754Parameters::decimal32() -> Ieee754Parameters {
  ieee754_decimal_generic(32)
}

///|
pub fn Ieee754Parameters::decimal64() -> Ieee754Parameters {
  ieee754_decimal_generic(64)
}

///|
pub fn Ieee754Parameters::decimal128() -> Ieee754Parameters {
  ieee754_decimal_generic(128)
}

///|
pub fn Ieee754Parameters::binary(width : Int32) -> Ieee754Parameters? {
  match width {
    16 => Some(Ieee754Parameters::binary16())
    32 => Some(Ieee754Parameters::binary32())
    80 => Some(Ieee754Parameters::binary80())
    _ if width > 0 && width % 32 == 0 => Some(ieee754_binary_generic(width))
    _ => None
  }
}

///|
pub fn Ieee754Parameters::decimal(width : Int32) -> Ieee754Parameters? {
  if width > 0 && width % 32 == 0 {
    Some(ieee754_decimal_generic(width))
  } else {
    None
  }
}

///|
fn ieee754_sort_name() -> @knowledge.Name {
  @knowledge.Name::create("IEEE754", pkg="core")
}

///|
pub fn Sort::ieee754(parameters : Ieee754Parameters) -> Sort {
  let repr = Sort::app(
    Sort::app(
      Sort::app(Sort::sym(ieee754_sort_name()), Sort::int(parameters.base)),
      Sort::int(parameters.w),
    ),
    Sort::int(parameters.t),
  )
  Sort::float_with_format(Sort::float_format(repr, Sort::bitv(parameters.k)))
}

///|
pub fn Sort::ieee754_spec(self : Sort) -> Ieee754Parameters? {
  let format = match self.float_format_of() {
    Some(format) => format
    None => return None
  }
  let width = match format.float_format_bits() {
    Some(bits) =>
      match bits.bitv_size() {
        Some(width) => width
        None => return None
      }
    None => return None
  }
  let repr = match format.float_format_exp() {
    Some(repr) => repr
    None => return None
  }
  if repr.refine(ieee754_sort_name()) is None {
    return None
  }
  let base = match repr.hd() {
    Some(base_sort) => base_sort.value()
    None => return None
  }
  match base {
    Some(2) => Ieee754Parameters::binary(width)
    Some(10) => Ieee754Parameters::decimal(width)
    _ => None
  }
}

///|
pub fn Sort::ieee754_exps(self : Sort) -> Sort? {
  match self.ieee754_spec() {
    Some(parameters) => Some(Sort::bitv(parameters.w))
    None => None
  }
}

///|
pub fn Sort::ieee754_sigs(self : Sort) -> Sort? {
  match self.ieee754_spec() {
    Some(parameters) => Some(Sort::bitv(parameters.p))
    None => None
  }
}

///|
pub fn Sort::ieee754_bits(self : Sort) -> Sort? {
  match self.ieee754_spec() {
    Some(parameters) => Some(Sort::bitv(parameters.k))
    None => None
  }
}
