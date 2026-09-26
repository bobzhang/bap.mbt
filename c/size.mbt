// Port of BAP `lib/bap_c/bap_c_size.ml` (an abstraction of `sizeof`).
//
// Upstream implements the algorithm as the class `C.Size.base` so that a
// particular target can override individual methods. The MoonBit port uses
// the open trait `Ruler` whose methods (except `model`) have default
// implementations; `SizeBase` is the stock implementation (`new base model`).
// A target-specific data model implements `Ruler` for its own type and
// overrides only the methods it needs; the defaults dispatch through `self`,
// so overrides are observed by `bits`/`alignment` (open recursion).
//
// The deprecated `padding` method is not ported (it is ignored upstream since
// 2021-05); use the `padding` function instead.

///|
/// `next_multitude_of(n~, x)` returns `y >= x` such that `y` is a multiple
/// of `n` (`n` must be a power of two).
pub fn next_multitude_of(n~ : Int, x : Int) -> Int {
  (x + (n - 1)) & (n - 1).lnot()
}

///|
/// `padding(alignment, offset)` computes the padding (in bits) required at
/// `offset` (in bits) to ensure the `alignment`.
pub fn padding(alignment : @types.Size, offset : Int) -> Int {
  let align = alignment.in_bits()
  (align - offset % align) % align
}

///|
/// `max_enum_elt(enum)` returns the maximum element in the enumeration.
pub fn max_enum_elt(xs : ArrayView[(String, Int64?)]) -> Int64 {
  let mut m : Int64? = None
  for item in xs {
    let (_, x) = item
    m = match (m, x) {
      (None, None) => Some(0L)
      (Some(m), None) => Some(m + 1L)
      (Some(m), Some(x)) => Some(if m > x { m } else { x })
      (None, x) => x
    }
  }
  match m {
    None => 0L
    Some(x) => x
  }
}

///|
fn max_size(x : @types.Size, y : @types.Size) -> @types.Size {
  if x.in_bits() >= y.in_bits() {
    x
  } else {
    y
  }
}

///|
fn double_size(s : @types.Size) -> @types.Size {
  match s {
    R8 => R16
    R16 => R32
    R32 => R64
    R64 => R128
    R128 | R256 => R256
  }
}

///|
/// The sizes and alignments of C data types (upstream class
/// `C.Size.base`). All sizes returned by `bits` are in bits.
///
/// The entry methods are `bits` and `alignment`.
pub(open) trait Ruler {
  /// The data model that defines the default sizes of integral types.
  fn model(Self) -> Model
  /// The size of the data type representation in bits, or `None` for
  /// incomplete types. The size is always a multiple of the alignment and
  /// includes the paddings necessary for preserving the alignment.
  fn bits(Self, CType) -> Int? = _
  /// The alignment of a data type: `void` or an incomplete type is 8 bits; a
  /// scalar is `sizeof(t)`; an array is the alignment of its element; a
  /// function is the pointer size; a structure or union is the largest of
  /// its elements' alignments.
  fn alignment(Self, CType) -> @types.Size = _
  /// The size of a complete array (element count times element size).
  fn array(Self, Spec[Qualifier[Bool], ArrayType]) -> Int? = _
  /// The size of the biggest union element, excluding trailing padding.
  fn union(Self, Spec[Unit, Compound]) -> Int? = _
  /// The total size of a structure including the padding between fields,
  /// but excluding the trailing padding.
  fn structure(Self, Spec[Unit, Compound]) -> Int? = _
  /// The size of an integral type.
  fn integer(Self, Basic) -> @types.Size = _
  /// The size of a pointer.
  fn pointer(Self) -> @types.AddrSize = _
  /// The size of an enumeration.
  fn enum_(Self, Array[(String, Int64?)]) -> @types.Size = _
  /// The size of a real floating-point type (`R32`, `R64`, or `R128`).
  fn real(Self, Basic) -> @types.Size = _
  /// The size of a complex floating-point type.
  fn complex(Self, Basic) -> @types.Size = _
  /// The size of a floating-point type.
  fn floating(Self, Basic) -> @types.Size = _
  /// The size of a basic type.
  fn basic(Self, Basic) -> @types.Size = _
  /// The size of a scalar (basic or pointer) type. Non-scalar types are
  /// given the pointer size.
  fn scalar(Self, CType) -> @types.Size = _
}

///|
impl Ruler with fn integer(self, t) {
  let m = self.model()
  match t {
    Bool | SChar | Char | UChar => R8
    SShort | UShort => R16
    SInt | UInt =>
      match m {
        LP32 => R16
        ILP32 | LLP64 | LP64 => R32
        ILP64 => R64
      }
    SLong | ULong =>
      match m {
        LP32 | ILP32 | LLP64 => R32
        ILP64 | LP64 => R64
      }
    SLongLong | ULongLong => R64
    Enum(fields) => self.enum_(fields)
    _ => self.basic(t)
  }
}

///|
impl Ruler with fn pointer(self) {
  if self.model().is_model32() {
    Addr32
  } else {
    Addr64
  }
}

///|
impl Ruler with fn enum_(self, _fields) {
  // an approximation, as upstream
  self.integer(UInt)
}

///|
impl Ruler with fn real(self, t) {
  match t {
    Float => R32
    Double => R64
    LongDouble => R128
    _ => self.basic(t)
  }
}

///|
impl Ruler with fn complex(self, t) {
  match t {
    CFloat => double_size(self.real(Float))
    CDouble => double_size(self.real(Double))
    CLongDouble => double_size(self.real(LongDouble))
    _ => self.basic(t)
  }
}

///|
impl Ruler with fn floating(self, t) {
  if t.is_real() {
    self.real(t)
  } else if t.is_complex() {
    self.complex(t)
  } else {
    self.basic(t)
  }
}

///|
impl Ruler with fn basic(self, t) {
  if t.is_integer() {
    self.integer(t)
  } else {
    self.floating(t)
  }
}

///|
impl Ruler with fn scalar(self, t) {
  match t {
    Basic(s) => self.basic(s.t)
    _ => self.pointer().to_size()
  }
}

///|
impl Ruler with fn alignment(self, t) {
  match t {
    Void => R8
    Array(s) => self.alignment(s.t.element)
    Structure(s) | Union(s) =>
      s.t.fields.fold(init=R8, (align, field) => {
        max_size(align, self.alignment(field.1))
      })
    Function(_) => self.pointer().to_size()
    Basic(_) | Pointer(_) => self.scalar(t)
  }
}

///|
impl Ruler with fn bits(self, t) {
  let size = match t {
    Void => None
    Basic(_) | Pointer(_) => Some(self.scalar(t).in_bits())
    Function(_) => None
    Union(s) => self.union(s)
    Array(s) => self.array(s)
    Structure(s) => self.structure(s)
  }
  match size {
    None => None
    Some(size) => Some(next_multitude_of(n=self.alignment(t).in_bits(), size))
  }
}

///|
impl Ruler with fn array(self, s) {
  match s.t.size {
    None => None
    Some(n) =>
      match self.bits(s.t.element) {
        None => None
        Some(x) => Some(n * x)
      }
  }
}

///|
impl Ruler with fn union(self, s) {
  let mut result : Int? = None
  for field in s.t.fields {
    match self.bits(field.1) {
      None => return None
      Some(x) =>
        result = match result {
          None => Some(x)
          Some(m) => Some(if x > m { x } else { m })
        }
    }
  }
  result
}

///|
impl Ruler with fn structure(self, s) {
  let mut total = 0
  for field in s.t.fields {
    match self.bits(field.1) {
      None => return None
      Some(sz) => total = total + sz + padding(self.alignment(field.1), total)
    }
  }
  Some(total)
}

///|
/// The stock data model implementation (upstream `new C.Size.base model`).
///
/// # Example
/// ```mbt check
/// test {
///   let size = @c.SizeBase::new(LP64)
///   let foo = @c.CType::structure("foo", [
///     ("v1", @c.CType::basic(Char)),
///     ("v2", @c.CType::basic(UInt)),
///     ("v3", @c.CType::basic(Char)),
///   ])
///   assert_eq(size.bits(foo), Some(96))
/// }
/// ```
pub(all) struct SizeBase {
  model : Model
} derive(Eq, Debug)

///|
pub fn SizeBase::new(model : Model) -> SizeBase {
  { model, }
}

///|
pub impl Ruler for SizeBase with fn model(self) {
  self.model
}
