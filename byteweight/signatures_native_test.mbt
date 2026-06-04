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
