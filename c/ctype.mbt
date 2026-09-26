// Port of BAP `lib/bap_c/bap_c_type.ml` (C type system).
//
// The OCaml implementation uses polymorphic variants to describe both the
// type constructors and the overlapping groups of basic types (`char`,
// `signed`, `integer`, ...). MoonBit has no polymorphic variants, so every
// basic type lives in the single `Basic` enum and the groups are exposed as
// predicates (`Basic::is_char`, `Basic::is_signed`, ...) together with
// enumerations (`Basic::all_chars`, ...), which mirror `[@@deriving enumerate]`.

///|
/// A basic (arithmetic) C type.
///
/// Upstream groups: `char = schar|char|uchar`, `short`, `cint`, `long`,
/// `long_long`, `signed`, `unsigned` (which includes `_Bool`), `enum`,
/// `integer = char|signed|unsigned|enum`, `real`, `complex`,
/// `floating = real|complex`.
pub(all) enum Basic {
  SChar
  Char
  UChar
  SShort
  UShort
  SInt
  UInt
  SLong
  ULong
  SLongLong
  ULongLong
  Bool
  /// An enumeration: a list of named constants with optional values.
  Enum(Array[(String, Int64?)])
  Float
  Double
  LongDouble
  CFloat
  CDouble
  CLongDouble
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Basic::is_char(self : Basic) -> Bool {
  self is (SChar | Char | UChar)
}

///|
pub fn Basic::is_short(self : Basic) -> Bool {
  self is (SShort | UShort)
}

///|
pub fn Basic::is_cint(self : Basic) -> Bool {
  self is (SInt | UInt)
}

///|
pub fn Basic::is_long(self : Basic) -> Bool {
  self is (SLong | ULong)
}

///|
pub fn Basic::is_long_long(self : Basic) -> Bool {
  self is (SLongLong | ULongLong)
}

///|
pub fn Basic::is_signed(self : Basic) -> Bool {
  self is (SChar | SShort | SInt | SLong | SLongLong)
}

///|
pub fn Basic::is_unsigned(self : Basic) -> Bool {
  self is (Bool | UChar | UShort | UInt | ULong | ULongLong)
}

///|
pub fn Basic::is_enum(self : Basic) -> Bool {
  self is Enum(_)
}

///|
pub fn Basic::is_integer(self : Basic) -> Bool {
  self.is_char() || self.is_signed() || self.is_unsigned() || self.is_enum()
}

///|
pub fn Basic::is_real(self : Basic) -> Bool {
  self is (Float | Double | LongDouble)
}

///|
pub fn Basic::is_complex(self : Basic) -> Bool {
  self is (CFloat | CDouble | CLongDouble)
}

///|
pub fn Basic::is_floating(self : Basic) -> Bool {
  self.is_real() || self.is_complex()
}

///|
/// All members of the upstream `char` group.
pub fn Basic::all_chars() -> Array[Basic] {
  [SChar, Char, UChar]
}

///|
pub fn Basic::all_shorts() -> Array[Basic] {
  [SShort, UShort]
}

///|
pub fn Basic::all_cints() -> Array[Basic] {
  [UInt, SInt]
}

///|
pub fn Basic::all_longs() -> Array[Basic] {
  [SLong, ULong]
}

///|
pub fn Basic::all_long_longs() -> Array[Basic] {
  [SLongLong, ULongLong]
}

///|
pub fn Basic::all_signed() -> Array[Basic] {
  [SChar, SShort, SInt, SLong, SLongLong]
}

///|
pub fn Basic::all_unsigned() -> Array[Basic] {
  [Bool, UChar, UShort, UInt, ULong, ULongLong]
}

///|
pub fn Basic::all_reals() -> Array[Basic] {
  [Float, Double, LongDouble]
}

///|
pub fn Basic::all_complex() -> Array[Basic] {
  [CFloat, CDouble, CLongDouble]
}

///|
pub fn Basic::all_floating() -> Array[Basic] {
  [Float, Double, LongDouble, CFloat, CDouble, CLongDouble]
}

///|
/// Type qualifiers. The `restrict` component is `Unit` for the `cv`
/// qualifier of basic types and `Bool` for the `cvr` qualifier of pointers
/// and arrays (upstream `'a Qualifier.t`).
///
/// The fields are spelled `const_`/`volatile_` since `const` is a MoonBit
/// keyword and `volatile` is reserved.
pub(all) struct Qualifier[R] {
  const_ : Bool
  volatile_ : Bool
  restrict : R
} derive(Eq, Debug, ToJson, FromJson)

///|
/// A C attribute `name(args)`, e.g., `__attribute__((format(printf,1,2)))`.
pub(all) struct Attr {
  name : String
  args : Array[String]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Attr::new(name : String, args? : Array[String] = []) -> Attr {
  { name, args, }
}

///|
/// A specification of a type: the qualifier, the type payload, and the list
/// of attributes (upstream `('a,'b) Spec.t`). Structures, unions, and
/// functions use `Unit` as the qualifier (upstream `` `no_qualifier ``).
pub(all) struct Spec[Q, T] {
  qualifier : Q
  t : T
  attrs : Array[Attr]
} derive(Eq, Debug, ToJson, FromJson)

///|
/// A function prototype (upstream `Proto.t`).
pub(all) struct Proto {
  return_ : CType
  args : Array[(String, CType)]
  variadic : Bool
} derive(Eq, Debug, ToJson, FromJson)

///|
/// A structure or union body (upstream `Compound.t`).
pub(all) struct Compound {
  name : String
  fields : Array[(String, CType)]
} derive(Eq, Debug, ToJson, FromJson)

///|
/// An array body: the element type and the optional number of elements
/// (upstream `Array.t`).
pub(all) struct ArrayType {
  element : CType
  size : Int?
} derive(Eq, Debug, ToJson, FromJson)

///|
/// A C type (upstream `Bap_c_type.t`).
pub(all) enum CType {
  Void
  Basic(Spec[Qualifier[Unit], Basic])
  Pointer(Spec[Qualifier[Bool], CType])
  Array(Spec[Qualifier[Bool], ArrayType])
  Structure(Spec[Unit, Compound])
  Union(Spec[Unit, Compound])
  Function(Spec[Unit, Proto])
} derive(Eq, Debug, ToJson, FromJson)

///|
/// `attrs t` is the list of attributes associated with the type `t`.
pub fn CType::attrs(self : CType) -> Array[Attr] {
  match self {
    Void => []
    Basic(s) => s.attrs
    Pointer(s) => s.attrs
    Array(s) => s.attrs
    Structure(s) | Union(s) => s.attrs
    Function(s) => s.attrs
  }
}

///|
/// `is_const t` is `true` if the type is const-qualified.
pub fn CType::is_const(self : CType) -> Bool {
  match self {
    Void | Union(_) | Structure(_) | Function(_) => false
    Basic(s) => s.qualifier.const_
    Array(s) => s.qualifier.const_
    Pointer(s) => s.qualifier.const_
  }
}

///|
/// `is_volatile t` is `true` if the type is volatile-qualified.
pub fn CType::is_volatile(self : CType) -> Bool {
  match self {
    Void | Union(_) | Structure(_) | Function(_) => false
    Basic(s) => s.qualifier.volatile_
    Array(s) => s.qualifier.volatile_
    Pointer(s) => s.qualifier.volatile_
  }
}

///|
/// `is_restrict t` is `true` if the type is restrict-qualified.
pub fn CType::is_restrict(self : CType) -> Bool {
  match self {
    Void | Union(_) | Structure(_) | Function(_) | Basic(_) => false
    Array(s) => s.qualifier.restrict
    Pointer(s) => s.qualifier.restrict
  }
}

///|
pub fn CType::is_void(self : CType) -> Bool {
  self is Void
}

///|
/// `basic x` constructs a basic type; all parameters default to `false`
/// or empty.
pub fn CType::basic(
  attrs? : Array[Attr] = [],
  const_? : Bool = false,
  volatile_? : Bool = false,
  t : Basic,
) -> CType {
  Basic({ t, attrs, qualifier: { const_, volatile_, restrict: (), }, })
}

///|
fn CType::basic_holds(self : CType, p : (Basic) -> Bool) -> Bool {
  match self {
    Basic(s) => p(s.t)
    _ => false
  }
}

///|
pub fn CType::is_basic(self : CType) -> Bool {
  self is Basic(_)
}

///|
pub fn CType::is_char(self : CType) -> Bool {
  self.basic_holds(Basic::is_char)
}

///|
pub fn CType::is_short(self : CType) -> Bool {
  self.basic_holds(Basic::is_short)
}

///|
pub fn CType::is_cint(self : CType) -> Bool {
  self.basic_holds(Basic::is_cint)
}

///|
pub fn CType::is_signed(self : CType) -> Bool {
  self.basic_holds(Basic::is_signed)
}

///|
pub fn CType::is_unsigned(self : CType) -> Bool {
  self.basic_holds(Basic::is_unsigned)
}

///|
pub fn CType::is_enum(self : CType) -> Bool {
  self.basic_holds(Basic::is_enum)
}

///|
pub fn CType::is_integer(self : CType) -> Bool {
  self.basic_holds(Basic::is_integer)
}

///|
pub fn CType::is_real(self : CType) -> Bool {
  self.basic_holds(Basic::is_real)
}

///|
pub fn CType::is_complex(self : CType) -> Bool {
  self.basic_holds(Basic::is_complex)
}

///|
pub fn CType::is_floating(self : CType) -> Bool {
  self.basic_holds(Basic::is_floating)
}

///|
/// `pointer t` constructs a pointer to the type `t`.
pub fn CType::pointer(
  attrs? : Array[Attr] = [],
  const_? : Bool = false,
  volatile_? : Bool = false,
  restrict? : Bool = false,
  t : CType,
) -> CType {
  Pointer({ t, attrs, qualifier: { const_, volatile_, restrict, }, })
}

///|
pub fn CType::is_pointer(self : CType) -> Bool {
  self is Pointer(_)
}

///|
/// `array t` constructs an array of `t` elements; `size` is the optional
/// number of elements.
pub fn CType::array(
  attrs? : Array[Attr] = [],
  const_? : Bool = false,
  volatile_? : Bool = false,
  restrict? : Bool = false,
  size? : Int,
  t : CType,
) -> CType {
  Array({
    t: { element: t, size, },
    attrs,
    qualifier: { const_, volatile_, restrict, },
  })
}

///|
pub fn CType::is_array(self : CType) -> Bool {
  self is Array(_)
}

///|
/// `structure name fields` constructs a structure type.
pub fn CType::structure(
  attrs? : Array[Attr] = [],
  name : String,
  fields : Array[(String, CType)],
) -> CType {
  Structure({ t: { name, fields, }, attrs, qualifier: (), })
}

///|
pub fn CType::is_structure(self : CType) -> Bool {
  self is Structure(_)
}

///|
/// `union name fields` constructs a union type.
pub fn CType::union(
  attrs? : Array[Attr] = [],
  name : String,
  fields : Array[(String, CType)],
) -> CType {
  Union({ t: { name, fields, }, attrs, qualifier: (), })
}

///|
pub fn CType::is_union(self : CType) -> Bool {
  self is Union(_)
}

///|
/// `function_ args` constructs a function type; `return_` defaults to
/// `Void`.
pub fn CType::function_(
  attrs? : Array[Attr] = [],
  variadic? : Bool = false,
  return_? : CType = Void,
  args : Array[(String, CType)],
) -> CType {
  Function({ t: { return_, args, variadic, }, attrs, qualifier: (), })
}

///|
pub fn CType::is_function(self : CType) -> Bool {
  self is Function(_)
}
