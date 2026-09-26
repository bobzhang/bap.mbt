///|
fn fresh_dir(name : String) -> String {
  @native_io.mkdir_p("_build/native-io-tests").unwrap()
  @native_io.make_temp_dir(dir="_build/native-io-tests", prefix=name).unwrap()
}

///|
test "stat reports kinds, sizes and permissions" {
  let dir = fresh_dir("stat")
  let file = dir + "/data.bin"
  @native_io.write_file(file, b"hello").unwrap()
  let st = @native_io.stat(file).unwrap()
  debug_inspect(st.kind, content="RegularFile")
  inspect(st.size, content="5")
  assert_true(st.mtime > 1.0e9)
  @native_io.chmod(file, 0o444).unwrap()
  inspect(@native_io.stat(file).unwrap().perm, content="292")
  debug_inspect(@native_io.file_kind(dir), content="Some(Directory)")
  debug_inspect(@native_io.file_kind(dir + "/nope"), content="None")
  assert_true(@native_io.file_exists(file))
  assert_true(!@native_io.is_directory(file))
  assert_true(@native_io.is_directory(dir))
  assert_true(@native_io.stat(dir + "/nope") is Err(_))
  @native_io.remove_tree(dir).unwrap()
  assert_true(!@native_io.file_exists(dir))
}

///|
test "directories can be created, listed, and removed" {
  let dir = fresh_dir("dirs")
  @native_io.mkdir_p(dir + "/a/b/c").unwrap()
  // mkdir_p is idempotent, mkdir is not
  @native_io.mkdir_p(dir + "/a/b/c").unwrap()
  assert_true(@native_io.mkdir(dir + "/a") is Err(_))
  @native_io.write_file(dir + "/a/z.txt", b"z").unwrap()
  @native_io.write_file(dir + "/a/B.txt", b"b").unwrap()
  debug_inspect(
    @native_io.read_dir(dir + "/a"),
    content=(
      #|Ok(["B.txt", "b", "z.txt"])
    ),
  )
  assert_true(@native_io.read_dir(dir + "/missing") is Err(_))
  // a file in the way
  assert_true(@native_io.mkdir_p(dir + "/a/z.txt/sub") is Err(_))
  // rmdir refuses non-empty directories
  assert_true(@native_io.remove_dir(dir + "/a") is Err(_))
  @native_io.remove_file(dir + "/a/z.txt").unwrap()
  assert_true(@native_io.remove_file(dir + "/a/z.txt") is Err(_))
  @native_io.remove_tree(dir).unwrap()
  // removing a missing tree is fine
  @native_io.remove_tree(dir).unwrap()
}

///|
test "rename and atomic writes replace files" {
  let dir = fresh_dir("rename")
  @native_io.write_file(dir + "/a", b"first").unwrap()
  @native_io.rename(dir + "/a", dir + "/b").unwrap()
  assert_true(!@native_io.file_exists(dir + "/a"))
  @native_io.write_file_atomic(dir + "/b", b"second", perm=0o444).unwrap()
  inspect(@native_io.stat(dir + "/b").unwrap().perm, content="292")
  assert_true(@native_io.read_file(dir + "/b").unwrap() == b"second")
  // no temporary files are left behind
  debug_inspect(
    @native_io.read_dir(dir),
    content=(
      #|Ok(["b"])
    ),
  )
  assert_true(@native_io.rename(dir + "/missing", dir + "/c") is Err(_))
  @native_io.remove_tree(dir).unwrap()
}

///|
test "temporary files, cwd, and locks" {
  let dir = fresh_dir("temp")
  let a = @native_io.make_temp_file(dir~, prefix="x").unwrap()
  let b = @native_io.make_temp_file(dir~, prefix="x").unwrap()
  assert_true(a != b)
  assert_true(a.has_prefix(dir + "/x"))
  inspect(@native_io.stat(a).unwrap().size, content="0")
  let cwd = @native_io.getcwd().unwrap()
  assert_true(cwd.has_prefix("/"))
  assert_true(@native_io.file_exists(cwd + "/moon.mod"))
  let lock = @native_io.lock_file(dir + "/lock").unwrap()
  inspect(lock.path() == dir + "/lock", content="true")
  // a second, non-blocking exclusive lock on another descriptor conflicts
  assert_true(@native_io.lock_file(dir + "/lock", blocking=false) is Err(_))
  lock.unlock().unwrap()
  lock.unlock().unwrap()
  let value = @native_io.with_lock(dir + "/lock", () => 42).unwrap()
  inspect(value, content="42")
  @native_io.remove_tree(dir).unwrap()
}
