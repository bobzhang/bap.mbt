// Explicit method promotion for derived and implemented traits (MoonBit
// deprecates the implicit promotion of trait methods to regular methods).

///|
pub extend AbiError with Debug::{to_repr}

///|
pub extend AbiError with Eq::{not_equal, equal}

///|
pub extend Arena with Debug::{to_repr}

///|
pub extend Arena with Eq::{not_equal, equal}

///|
pub extend ArrayType with @json.FromJson::{from_json}

///|
pub extend ArrayType with Debug::{to_repr}

///|
pub extend ArrayType with Eq::{not_equal, equal}

///|
pub extend ArrayType with ToJson::{to_json}

///|
pub extend Attr with @json.FromJson::{from_json}

///|
pub extend Attr with Debug::{to_repr}

///|
pub extend Attr with Eq::{not_equal, equal}

///|
pub extend Attr with Show::{output}

///|
pub extend Attr with ToJson::{to_json}

///|
pub extend Basic with @json.FromJson::{from_json}

///|
pub extend Basic with Debug::{to_repr}

///|
pub extend Basic with Eq::{not_equal, equal}

///|
pub extend Basic with Show::{output}

///|
pub extend Basic with ToJson::{to_json}

///|
pub extend CType with @json.FromJson::{from_json}

///|
pub extend CType with Debug::{to_repr}

///|
pub extend CType with Eq::{not_equal, equal}

///|
pub extend CType with Show::{output}

///|
pub extend CType with ToJson::{to_json}

///|
pub extend Compound with @json.FromJson::{from_json}

///|
pub extend Compound with Debug::{to_repr}

///|
pub extend Compound with Eq::{not_equal, equal}

///|
pub extend Compound with ToJson::{to_json}

///|
pub extend Datum with Debug::{to_repr}

///|
pub extend Datum with Eq::{not_equal, equal}

///|
pub extend IdentityMapper with TypeMapper::{
  enter_enum,
  leave_floating,
  enter_structure,
  leave_unsigned,
  enter_complex,
  enter_name,
  map_cvr_qualifier,
  map_floating,
  map_attrs,
  enter_type,
  leave_pointer,
  enter_union,
  enter_cvr_qualifier,
  leave_cvr_qualifier,
  enter_char,
  leave_union,
  map_integer,
  leave_complex,
  leave_attrs,
  run,
  map_union,
  enter_integer,
  leave_signed,
  leave_cv_qualifier,
  enter_attrs,
  leave_char,
  leave_type,
  leave_function,
  map_attr,
  enter_unsigned,
  enter_floating,
  map_real,
  enter_function,
  enter_cv_qualifier,
  enter_real,
  map_void,
  leave_structure,
  leave_integer,
  leave_name,
  leave_void,
  enter_basic,
  enter_void,
  map_cv_qualifier,
  map_complex,
  map_array,
  enter_pointer,
  enter_signed,
  leave_attr,
  map_signed,
  enter_array,
  map_pointer,
  map_structure,
  map_char,
  map_enum,
  map_function,
  enter_attr,
  map_type,
  leave_real,
  map_name,
  leave_array,
  map_basic,
  leave_enum,
  leave_basic,
  map_unsigned,
}

///|
pub extend Layout with Debug::{to_repr}

///|
pub extend Layout with Eq::{not_equal, equal}

///|
pub extend Layout with Show::{output}

///|
pub extend Model with Debug::{to_repr}

///|
pub extend Model with Eq::{not_equal, equal}

///|
pub extend Obj with Debug::{to_repr}

///|
pub extend Obj with Eq::{not_equal, equal}

///|
pub extend Proto with @json.FromJson::{from_json}

///|
pub extend Proto with Debug::{to_repr}

///|
pub extend Proto with Eq::{not_equal, equal}

///|
pub extend Proto with Show::{output}

///|
pub extend Proto with ToJson::{to_json}

///|
pub extend Qualifier with @json.FromJson::{from_json}

///|
pub extend Qualifier with Debug::{to_repr}

///|
pub extend Qualifier with Eq::{not_equal, equal}

///|
pub extend Qualifier with ToJson::{to_json}

///|
pub extend SearchFinished with Debug::{to_repr}

///|
pub extend SizeBase with Debug::{to_repr}

///|
pub extend SizeBase with Eq::{not_equal, equal}

///|
pub extend Spec with @json.FromJson::{from_json}

///|
pub extend Spec with Debug::{to_repr}

///|
pub extend Spec with Eq::{not_equal, equal}

///|
pub extend Spec with ToJson::{to_json}

///|
pub extend Value with Debug::{to_repr}

///|
pub extend Value with Eq::{not_equal, equal}

///|
pub extend SizeBase with Ruler::{
  model,
  pointer,
  complex,
  scalar,
  array,
  alignment,
  union,
  basic,
  bits,
  structure,
  integer,
  real,
  enum_,
  floating,
}
