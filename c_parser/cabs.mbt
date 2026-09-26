// The abstract syntax of C declarations, modeled on FrontC's `Cabs`
// (the representation that upstream `frontc_parser_main.ml` maps to
// `Bap_c_type`). Only the parts that the mapping looks at are kept:
// expressions are reduced to "a constant" or "something else", and
// function bodies and initializers are dropped.

///|
pub(all) enum Sign {
  NoSign
  Signed
  Unsigned
} derive(Eq, Debug)

///|
pub(all) enum IntSize {
  NoSize
  Short
  Long
  LongLong
} derive(Eq, Debug)

///|
/// A literal constant; the payload is its spelling (the decoded contents
/// for characters and strings).
pub(all) enum Constant {
  ConstInt(String)
  ConstFloat(String)
  ConstChar(String)
  ConstString(String)
} derive(Eq, Debug)

///|
/// An expression: only literal constants are distinguished.
pub(all) enum Expression {
  /// No expression (e.g., the size of `a[]`, or an enumerator without a
  /// value).
  Nothing
  Literal(Constant)
  /// Any other expression.
  Other
} derive(Eq, Debug)

///|
/// A GNU attribute (FrontC `gnu_attr`).
pub(all) enum GnuAttr {
  GnuNone
  GnuCall(String, Array[GnuAttr])
  GnuId(String)
  GnuCst(Constant)
  GnuExtension
  GnuInline
  GnuTypeArg
} derive(Eq, Debug)

///|
/// A C type (FrontC `base_type`).
pub(all) enum BaseType {
  /// No type specifier was given.
  NoType
  Void
  Bool
  Char(Sign)
  Int(IntSize, Sign)
  Bitfield(Sign, Expression)
  /// `float` (`true` for the non-standard `long float`).
  Float(Bool)
  /// `double` (`true` for `long double`).
  Double(Bool)
  ComplexFloat
  ComplexDouble
  ComplexLongDouble
  Ptr(BaseType)
  RestrictPtr(BaseType)
  Array(BaseType, Expression)
  Struct(String, Array[NameGroup])
  Union(String, Array[NameGroup])
  /// A prototype: the return type, the parameters, and whether it is
  /// variadic.
  Proto(BaseType, Array[SingleName], Bool)
  /// An old-style (K&R) declaration: the return type and the parameter
  /// names.
  OldProto(BaseType, Array[String], Bool)
  NamedType(String)
  Enum(String, Array[(String, Expression)])
  Const(BaseType)
  Volatile(BaseType)
  GnuType(Array[GnuAttr], BaseType)
  BuiltinType(String)
} derive(Eq, Debug)

///|
pub(all) enum Storage {
  NoStorage
  Auto
  Static
  Extern
  Register
} derive(Eq, Debug)

///|
/// A declarator: the declared name, its type, its attributes, and its
/// initializer.
pub(all) struct Name {
  name : String
  typ : BaseType
  attrs : Array[GnuAttr]
  init : Expression
} derive(Eq, Debug)

///|
/// A declaration with several declarators sharing the same specifiers.
pub(all) struct NameGroup {
  typ : BaseType
  storage : Storage
  names : Array[Name]
} derive(Eq, Debug)

///|
/// A declaration with one declarator (a parameter).
pub(all) struct SingleName {
  typ : BaseType
  storage : Storage
  name : Name
} derive(Eq, Debug)

///|
/// A top-level definition (FrontC `definition`).
pub(all) enum Definition {
  /// A function definition (the body is dropped).
  FunDef(SingleName)
  /// A declaration of variables or functions.
  DecDef(NameGroup)
  /// A `typedef` with its declarators, and the attributes that follow it.
  TypeDef(NameGroup, Array[GnuAttr])
  /// A declaration without declarators (e.g., `struct s {...};`).
  OnlyTypeDef(NameGroup)
} derive(Eq, Debug)

///|
pub extend Sign with Eq::{equal, not_equal}

///|
pub extend Sign with Debug::{to_repr}

///|
pub extend IntSize with Eq::{equal, not_equal}

///|
pub extend IntSize with Debug::{to_repr}

///|
pub extend Constant with Eq::{equal, not_equal}

///|
pub extend Constant with Debug::{to_repr}

///|
pub extend Expression with Eq::{equal, not_equal}

///|
pub extend Expression with Debug::{to_repr}

///|
pub extend GnuAttr with Eq::{equal, not_equal}

///|
pub extend GnuAttr with Debug::{to_repr}

///|
pub extend BaseType with Eq::{equal, not_equal}

///|
pub extend BaseType with Debug::{to_repr}

///|
pub extend Storage with Eq::{equal, not_equal}

///|
pub extend Storage with Debug::{to_repr}

///|
pub extend Name with Eq::{equal, not_equal}

///|
pub extend Name with Debug::{to_repr}

///|
pub extend NameGroup with Eq::{equal, not_equal}

///|
pub extend NameGroup with Debug::{to_repr}

///|
pub extend SingleName with Eq::{equal, not_equal}

///|
pub extend SingleName with Debug::{to_repr}

///|
pub extend Definition with Eq::{equal, not_equal}

///|
pub extend Definition with Debug::{to_repr}
