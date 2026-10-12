///|
let int_conversion_min_int64 : Int64 = -0x80000000L

///|
let int_conversion_max_int64 : Int64 = 0x7fffffffL

///|
let int_conversion_max_uint64 : UInt64 = 0x7fffffffUL

///|
fn int_conversion_error(value : String) -> Result[Int32, String] {
  Err("doesn't fit into int: \{value}")
}

///|
pub fn int_of_int32(value : Int32) -> Result[Int32, String] {
  Ok(value)
}

///|
pub fn int_of_int64(value : Int64) -> Result[Int32, String] {
  if value < int_conversion_min_int64 || value > int_conversion_max_int64 {
    int_conversion_error(value.to_string())
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn int_of_uint64(value : UInt64) -> Result[Int32, String] {
  if value > int_conversion_max_uint64 {
    int_conversion_error(value.to_string())
  } else {
    Ok(value.to_int())
  }
}

///|
pub fn int_of_word(word : Word) -> Result[Int32, String] {
  try word.to_int() catch {
    _ => int_conversion_error(word.to_string())
  } noraise {
    value => Ok(value)
  }
}
