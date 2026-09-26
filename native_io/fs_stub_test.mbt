///|
test "file-system primitives fail outside the native target" {
  assert_true(@native_io.stat("moon.mod") is Err(_))
  assert_true(@native_io.read_dir(".") is Err(_))
  assert_true(@native_io.mkdir_p("_build/x") is Err(_))
  assert_true(@native_io.getcwd() is Err(_))
  assert_true(@native_io.lock_file("_build/lock") is Err(_))
  debug_inspect(@native_io.file_kind("moon.mod"), content="None")
  inspect(@native_io.file_exists("moon.mod"), content="false")
  // removing a tree that cannot be observed is a no-op
  assert_true(@native_io.remove_tree("_build/x") is Ok(_))
}
