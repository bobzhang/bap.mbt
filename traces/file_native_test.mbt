///|
test "native BAP trace binprot file provider saves and loads snapshots" {
  let uri = "file://_build/bap-trace-native.binprot"
  let trace = new_trace().set_meta(test_meta())
  match @traces.Trace::save(uri, trace) {
    Ok(_) => ()
    Err(_) => fail("native trace file save failed")
  }
  match @traces.Trace::load(uri) {
    Ok(loaded) => {
      assert_true(loaded.protocol() == Some("trace.binprot"))
      assert_true(loaded.tool() == test_tool())
      assert_true(loaded.meta() == test_meta())
      assert_true(unwrap_events(loaded.read_events()) == test_events())
    }
    Err(_) => fail("native trace file load failed")
  }
}
