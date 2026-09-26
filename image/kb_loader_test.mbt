///|
test "image KB loaders run knowledge computations" {
  let state = @knowledge.State::new()
  let seen = []
  match
    @image.KB::register_loader(
      name="unit-kb-failing-loader",
      from_file=(_, _) => None,
      from_data=(kb, data) => {
        seen.push((kb.current_pkg(), data.length()))
        fail("kb loader failed")
      },
      state~,
    ) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @image.Image::of_bytes(b"\x01\x02", backend="unit-kb-failing-loader") {
    Ok(_) => fail("expected the KB loader to fail")
    Err(reason) => assert_true(reason.contains("kb loader failed"))
  }
  debug_inspect(
    seen,
    content=(
      #|[("user", 2)]
    ),
  )
}
