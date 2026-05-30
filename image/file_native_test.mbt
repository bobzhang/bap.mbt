///|
test "image reads files on native target" {
  match @image.Image::of_file("moon.mod") {
    Ok((image, warnings)) => {
      assert_true(warnings.is_empty())
      assert_true(image.data().length() > 0)
      assert_true(image.data()[0] == (47).to_byte())
    }
    Err(reason) => fail(reason)
  }
}
