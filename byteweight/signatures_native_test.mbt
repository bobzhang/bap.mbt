///|
fn bw_signature_bytes_data(
  name : String,
) -> @byteweight.ByteweightSignatureData[Bytes] raise {
  match
    @byteweight.ByteweightSignatureData::register(
      name,
      load=(bytes : Bytes) => Ok(bytes),
      save=(bytes : Bytes) => bytes,
    ) {
    Ok(data) => data
    Err(reason) => fail(reason)
  }
}

///|
test "translated BAP byteweight signatures update and lookup typed entries" {
  let data = bw_signature_bytes_data("unit-signatures-update")
  let path = "_build/byteweight-signatures-update.db"
  let target = @core_theory.Target::x86_64()
  match data.update(path, target, b"first") {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(data.lookup(target, paths=[path]) == Ok(b"first"))
  match data.update(path, target, b"second") {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(data.lookup(target, paths=[path]) == Ok(b"second"))
}

///|
test "translated BAP byteweight exposes typed signature data" {
  let data = @byteweight.Byteweight::signature_data()
  let path = "_build/byteweight-signatures-byteweight.db"
  let target = @core_theory.Target::x86_64()
  let corpus = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x100UL,
    b"\xaa\xbb\xaa\xbb",
  )
  let decider = @byteweight.Byteweight::create().train(
    max_length=2,
    mem => mem.min_addr() == 0x100UL,
    corpus,
  )
  assert_true(data.name() == "byteweight")
  match data.update(path, target, decider) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  match data.lookup(target, paths=[path]) {
    Ok(loaded) => {
      assert_true(loaded.to_string() == decider.to_string())
      match loaded.find(b"\xaa\xbb") {
        Some(stats) => {
          assert_true(stats.h1() == 1)
          assert_true(stats.h0() == 1)
        }
        None => fail("missing loaded byteweight signature")
      }
    }
    Err(err) => fail(err.to_string())
  }
}

///|
test "translated BAP byteweight signatures preserve compiler-specific entries" {
  let data = bw_signature_bytes_data("unit-signatures-compiler")
  let path = "_build/byteweight-signatures-compiler.db"
  let target = @core_theory.Target::x86_64()
  let gcc = @core_theory.Compiler::create("gcc")
  let clang = @core_theory.Compiler::create("clang")
  match data.update(path, target, b"gcc", compiler=gcc) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  match data.update(path, target, b"clang", compiler=clang) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(data.lookup(target, paths=[path], compiler=gcc) == Ok(b"gcc"))
  assert_true(data.lookup(target, paths=[path], compiler=clang) == Ok(b"clang"))
  assert_true(
    data.lookup(target, paths=[path]) is Err(ByteweightSignatureNoEntry(_)),
  )
}

///|
test "translated BAP byteweight signatures match target aliases modulo bits" {
  let data = bw_signature_bytes_data("unit-signatures-alias")
  let path = "_build/byteweight-signatures-alias.db"
  match
    @byteweight.byteweight_signature_save(
      path,
      arch="amd64",
      mode=data.name(),
      b"alias-payload",
    ) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(
    data.lookup(@core_theory.Target::x86_64(), paths=[path]) ==
    Ok(b"alias-payload"),
  )
  assert_true(
    data.lookup(@core_theory.Target::x86(), paths=[path])
    is Err(ByteweightSignatureNoEntry(_)),
  )
}

///|
test "translated BAP byteweight typed update replaces target aliases" {
  let data = bw_signature_bytes_data("unit-signatures-alias-update")
  let path = "_build/byteweight-signatures-alias-update.db"
  let target = @core_theory.Target::x86_64()
  match
    @byteweight.byteweight_signature_save(
      path,
      arch="amd64",
      mode=data.name(),
      b"old-alias-payload",
    ) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  match data.update(path, target, b"new-target-payload") {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(data.lookup(target, paths=[path]) == Ok(b"new-target-payload"))
}

///|
test "translated BAP byteweight signatures report corrupted databases" {
  let data = bw_signature_bytes_data("unit-signatures-corrupt")
  let path = "_build/byteweight-signatures-corrupt.db"
  match @native_io.write_file(path, @utf8.encode("not four fields\n")) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(
    data.lookup(@core_theory.Target::x86_64(), paths=[path])
    is Err(ByteweightSignatureCorrupted(_)),
  )
}

///|
test "translated BAP byteweight legacy signature load and save" {
  let path = "_build/byteweight-signatures-legacy.db"
  match
    @byteweight.byteweight_signature_save(
      path,
      arch="x86_64",
      mode="legacy",
      b"legacy-payload",
    ) {
    Ok(_) => ()
    Err(err) => fail(err.to_string())
  }
  assert_true(
    @byteweight.byteweight_signature_load(
      paths=[path],
      arch="x86_64",
      mode="legacy",
    ) ==
    Ok(b"legacy-payload"),
  )
  assert_true(
    @byteweight.byteweight_signature_load(
      paths=["_build/byteweight-signatures-missing.db"],
      arch="x86_64",
      mode="legacy",
    )
    is Err(ByteweightSignatureNoSignatures),
  )
}
