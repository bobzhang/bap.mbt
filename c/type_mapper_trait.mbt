// Port of BAP `lib/bap_c/bap_c_type_mapper.ml` and
// `bap_c_type_mapper_intf.ml` (type mapper, visitor, iterator, and finder).
//
// Upstream parameterizes a class over a monad to obtain a plain mapper
// (`C.Type.Mapper.base`), a state-passing visitor (`State.base`), and a
// search with an early exit (`Finder.base`). In MoonBit the effects are
// native:
//
// - a plain mapper is a type that implements `TypeMapper` and overrides some
//   methods (`IdentityMapper` uses only the defaults);
// - state is kept in mutable fields of the implementing type;
// - an early exit is an error; `Search` packages this pattern.
//
// Each syntactic element `T` has three methods: `enter_T`, `map_T`, and
// `leave_T`. The default `map_T x` calls `enter_T x`, deeply maps `x` to
// `x'`, then calls `leave_T x'` and returns `x'`. Override `enter_T` /
// `leave_T` to visit, and `map_T` to transform (for composite elements, call
// the free function `default_map_T` to reuse the default deep mapping).
//
// Run a mapper with `@c.TypeMapper::run(mapper, t)` (or add an `extend`
// declaration for the implementing type to call `mapper.run(t)`).
//
// Deviation: upstream's `do_map_structure` calls `map_structure` again,
// which diverges; here structures are mapped like unions (fields, then the
// name).

///|
/// The type mapper/visitor (upstream class type
/// `C.Type.Mapper.S.base`). All methods have default implementations.
pub(open) trait TypeMapper {
  /// Runs the mapper on a type (by default, `map_type`).
  fn run(Self, CType) -> CType raise = _
  /// Called before a C type is mapped.
  fn enter_type(Self, CType) -> Unit raise = _
  /// Maps a C type.
  fn map_type(Self, CType) -> CType raise = _
  /// Called with the result of mapping a C type.
  fn leave_type(Self, CType) -> Unit raise = _
  /// Called before the `void` type is mapped.
  fn enter_void(Self, CType) -> Unit raise = _
  /// Maps the `void` type.
  fn map_void(Self, CType) -> CType raise = _
  /// Called with the result of mapping the `void` type.
  fn leave_void(Self, CType) -> Unit raise = _
  /// Called before an array body is mapped.
  fn enter_array(Self, ArrayType) -> Unit raise = _
  /// Maps an array body.
  fn map_array(Self, ArrayType) -> ArrayType raise = _
  /// Called with the result of mapping an array body.
  fn leave_array(Self, ArrayType) -> Unit raise = _
  /// Called before the type referenced by a pointer is mapped.
  fn enter_pointer(Self, CType) -> Unit raise = _
  /// Maps the type referenced by a pointer.
  fn map_pointer(Self, CType) -> CType raise = _
  /// Called with the result of mapping the type referenced by a pointer.
  fn leave_pointer(Self, CType) -> Unit raise = _
  /// Called before a function prototype is mapped.
  fn enter_function(Self, Proto) -> Unit raise = _
  /// Maps a function prototype.
  fn map_function(Self, Proto) -> Proto raise = _
  /// Called with the result of mapping a function prototype.
  fn leave_function(Self, Proto) -> Unit raise = _
  /// Called before a union body is mapped.
  fn enter_union(Self, Compound) -> Unit raise = _
  /// Maps a union body.
  fn map_union(Self, Compound) -> Compound raise = _
  /// Called with the result of mapping a union body.
  fn leave_union(Self, Compound) -> Unit raise = _
  /// Called before a structure body is mapped.
  fn enter_structure(Self, Compound) -> Unit raise = _
  /// Maps a structure body.
  fn map_structure(Self, Compound) -> Compound raise = _
  /// Called with the result of mapping a structure body.
  fn leave_structure(Self, Compound) -> Unit raise = _
  /// Called before a `cv` qualifier is mapped.
  fn enter_cv_qualifier(Self, Qualifier[Unit]) -> Unit raise = _
  /// Maps a `cv` qualifier.
  fn map_cv_qualifier(Self, Qualifier[Unit]) -> Qualifier[Unit] raise = _
  /// Called with the result of mapping a `cv` qualifier.
  fn leave_cv_qualifier(Self, Qualifier[Unit]) -> Unit raise = _
  /// Called before a `cvr` qualifier is mapped.
  fn enter_cvr_qualifier(Self, Qualifier[Bool]) -> Unit raise = _
  /// Maps a `cvr` qualifier.
  fn map_cvr_qualifier(Self, Qualifier[Bool]) -> Qualifier[Bool] raise = _
  /// Called with the result of mapping a `cvr` qualifier.
  fn leave_cvr_qualifier(Self, Qualifier[Bool]) -> Unit raise = _
  /// Called before a basic type is mapped.
  fn enter_basic(Self, Basic) -> Unit raise = _
  /// Maps a basic type.
  fn map_basic(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a basic type.
  fn leave_basic(Self, Basic) -> Unit raise = _
  /// Called before an integer type is mapped.
  fn enter_integer(Self, Basic) -> Unit raise = _
  /// Maps an integer type.
  fn map_integer(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping an integer type.
  fn leave_integer(Self, Basic) -> Unit raise = _
  /// Called before a `char` type is mapped.
  fn enter_char(Self, Basic) -> Unit raise = _
  /// Maps a `char` type.
  fn map_char(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a `char` type.
  fn leave_char(Self, Basic) -> Unit raise = _
  /// Called before a signed integer type (not a `char`) is mapped.
  fn enter_signed(Self, Basic) -> Unit raise = _
  /// Maps a signed integer type (not a `char`).
  fn map_signed(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a signed integer type (not a `char`).
  fn leave_signed(Self, Basic) -> Unit raise = _
  /// Called before an unsigned integer type (not a `char`) is mapped.
  fn enter_unsigned(Self, Basic) -> Unit raise = _
  /// Maps an unsigned integer type (not a `char`).
  fn map_unsigned(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping an unsigned integer type (not a `char`).
  fn leave_unsigned(Self, Basic) -> Unit raise = _
  /// Called before an enumeration is mapped.
  fn enter_enum(Self, Array[(String, Int64?)]) -> Unit raise = _
  /// Maps an enumeration.
  fn map_enum(Self, Array[(String, Int64?)]) -> Array[(String, Int64?)] raise = _
  /// Called with the result of mapping an enumeration.
  fn leave_enum(Self, Array[(String, Int64?)]) -> Unit raise = _
  /// Called before a floating-point type is mapped.
  fn enter_floating(Self, Basic) -> Unit raise = _
  /// Maps a floating-point type.
  fn map_floating(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a floating-point type.
  fn leave_floating(Self, Basic) -> Unit raise = _
  /// Called before a real floating-point type is mapped.
  fn enter_real(Self, Basic) -> Unit raise = _
  /// Maps a real floating-point type.
  fn map_real(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a real floating-point type.
  fn leave_real(Self, Basic) -> Unit raise = _
  /// Called before a complex floating-point type is mapped.
  fn enter_complex(Self, Basic) -> Unit raise = _
  /// Maps a complex floating-point type.
  fn map_complex(Self, Basic) -> Basic raise = _
  /// Called with the result of mapping a complex floating-point type.
  fn leave_complex(Self, Basic) -> Unit raise = _
  /// Called before a list of attributes is mapped.
  fn enter_attrs(Self, Array[Attr]) -> Unit raise = _
  /// Maps a list of attributes.
  fn map_attrs(Self, Array[Attr]) -> Array[Attr] raise = _
  /// Called with the result of mapping a list of attributes.
  fn leave_attrs(Self, Array[Attr]) -> Unit raise = _
  /// Called before an attribute is mapped.
  fn enter_attr(Self, Attr) -> Unit raise = _
  /// Maps an attribute.
  fn map_attr(Self, Attr) -> Attr raise = _
  /// Called with the result of mapping an attribute.
  fn leave_attr(Self, Attr) -> Unit raise = _
  /// Called before a name (of a field, argument, or compound) is mapped.
  fn enter_name(Self, String) -> Unit raise = _
  /// Maps a name (of a field, argument, or compound).
  fn map_name(Self, String) -> String raise = _
  /// Called with the result of mapping a name (of a field, argument, or compound).
  fn leave_name(Self, String) -> Unit raise = _
}

///|
impl TypeMapper with fn run(self, t) {
  self.map_type(t)
}

///|
impl TypeMapper with fn enter_type(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_type(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_type(self, x) {
  self.enter_type(x)
  let x = default_map_type(self, x)
  self.leave_type(x)
  x
}

///|
impl TypeMapper with fn enter_void(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_void(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_void(self, x) {
  self.enter_void(x)
  self.leave_void(x)
  x
}

///|
impl TypeMapper with fn enter_array(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_array(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_array(self, x) {
  self.enter_array(x)
  let x = default_map_array(self, x)
  self.leave_array(x)
  x
}

///|
impl TypeMapper with fn enter_pointer(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_pointer(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_pointer(self, x) {
  self.enter_pointer(x)
  let x = default_map_pointer(self, x)
  self.leave_pointer(x)
  x
}

///|
impl TypeMapper with fn enter_function(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_function(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_function(self, x) {
  self.enter_function(x)
  let x = default_map_function(self, x)
  self.leave_function(x)
  x
}

///|
impl TypeMapper with fn enter_union(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_union(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_union(self, x) {
  self.enter_union(x)
  let x = default_map_union(self, x)
  self.leave_union(x)
  x
}

///|
impl TypeMapper with fn enter_structure(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_structure(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_structure(self, x) {
  self.enter_structure(x)
  let x = default_map_structure(self, x)
  self.leave_structure(x)
  x
}

///|
impl TypeMapper with fn enter_cv_qualifier(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_cv_qualifier(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_cv_qualifier(self, x) {
  self.enter_cv_qualifier(x)
  self.leave_cv_qualifier(x)
  x
}

///|
impl TypeMapper with fn enter_cvr_qualifier(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_cvr_qualifier(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_cvr_qualifier(self, x) {
  self.enter_cvr_qualifier(x)
  self.leave_cvr_qualifier(x)
  x
}

///|
impl TypeMapper with fn enter_basic(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_basic(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_basic(self, x) {
  self.enter_basic(x)
  let x = default_map_basic(self, x)
  self.leave_basic(x)
  x
}

///|
impl TypeMapper with fn enter_integer(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_integer(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_integer(self, x) {
  self.enter_integer(x)
  let x = default_map_integer(self, x)
  self.leave_integer(x)
  x
}

///|
impl TypeMapper with fn enter_char(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_char(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_char(self, x) {
  self.enter_char(x)
  self.leave_char(x)
  x
}

///|
impl TypeMapper with fn enter_signed(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_signed(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_signed(self, x) {
  self.enter_signed(x)
  self.leave_signed(x)
  x
}

///|
impl TypeMapper with fn enter_unsigned(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_unsigned(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_unsigned(self, x) {
  self.enter_unsigned(x)
  self.leave_unsigned(x)
  x
}

///|
impl TypeMapper with fn enter_enum(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_enum(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_enum(self, x) {
  self.enter_enum(x)
  self.leave_enum(x)
  x
}

///|
impl TypeMapper with fn enter_floating(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_floating(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_floating(self, x) {
  self.enter_floating(x)
  let x = default_map_floating(self, x)
  self.leave_floating(x)
  x
}

///|
impl TypeMapper with fn enter_real(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_real(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_real(self, x) {
  self.enter_real(x)
  self.leave_real(x)
  x
}

///|
impl TypeMapper with fn enter_complex(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_complex(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_complex(self, x) {
  self.enter_complex(x)
  self.leave_complex(x)
  x
}

///|
impl TypeMapper with fn enter_attrs(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_attrs(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_attrs(self, x) {
  self.enter_attrs(x)
  let x = default_map_attrs(self, x)
  self.leave_attrs(x)
  x
}

///|
impl TypeMapper with fn enter_attr(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_attr(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_attr(self, x) {
  self.enter_attr(x)
  self.leave_attr(x)
  x
}

///|
impl TypeMapper with fn enter_name(_self, _x) {
  ()
}

///|
impl TypeMapper with fn leave_name(_self, _x) {
  ()
}

///|
impl TypeMapper with fn map_name(self, x) {
  self.enter_name(x)
  self.leave_name(x)
  x
}
