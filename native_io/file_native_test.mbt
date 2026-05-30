///|
test "native file IO reads repository files" {
  match @native_io.read_file("moon.mod") {
    Ok(data) => {
      assert_true(data.length() > 0)
      assert_true(data[0] == (47).to_byte())
    }
    Err(reason) => fail(reason)
  }
}
