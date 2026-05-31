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

///|
test "native file IO writes and reads byte payloads" {
  let path = "_build/native-io-write-test.bin"
  let data = b"\x00native-io\xff"
  match @native_io.write_file(path, data) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @native_io.read_file(path) {
    Ok(read_back) => assert_true(read_back == data)
    Err(reason) => fail(reason)
  }
}
