///|
test "the native file system knows about directories" {
  let fs = @bap_main.FileSystem::native()
  debug_inspect((fs.kind)("native_io"), content="Some(Directory)")
  debug_inspect((fs.kind)("moon.mod"), content="Some(RegularFile)")
  debug_inspect((fs.kind)("no/such/file"), content="None")
  let entries = (fs.read_dir)("native_io").unwrap()
  assert_true(entries.contains("moon.pkg"))
  assert_true((fs.read_dir)("moon.mod") is None)
  @bap_main.set_file_system(fs)
  assert_true(@bap_main.Type::dir().parse("native_io") == "native_io")
  let dir_digest = @bap_main.Type::dir().digest("native_io")
  inspect(
    dir_digest == @bap_main.Type::dir().digest("native_io"),
    content="true",
  )
  try @bap_main.Type::dir().parse("moon.mod") catch {
    _ => ()
  } noraise {
    _ => fail("a regular file is not a directory")
  }
}
