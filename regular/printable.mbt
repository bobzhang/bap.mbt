///|
pub(open) trait Printable {
  fn to_string(Self) -> String
}

///|
pub fn[T : Printable] render(value : T) -> String {
  value.to_string()
}

///|
pub fn[T : Printable] render_array(
  values : ArrayView[T],
  sep~ : String = ", ",
) -> String {
  let out = StringBuilder()
  for i, value in values {
    if i > 0 {
      out.write_string(sep)
    }
    out.write_string(value.to_string())
  }
  out.to_string()
}

///|
pub impl Printable for String with fn to_string(self) {
  self
}

///|
pub impl Printable for Int32 with fn to_string(self) {
  self.to_string()
}

///|
pub impl Printable for UInt64 with fn to_string(self) {
  self.to_string()
}
