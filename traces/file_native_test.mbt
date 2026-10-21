///|
test "native BAP trace binprot file provider saves and loads snapshots" {
  let uri = "file://_build/bap-trace-native.binprot"
  let trace = new_trace().set_meta(test_meta())
  @traces.Trace::save(uri, trace) catch {
    _ => fail("native trace file save failed")
  }
  let loaded = @traces.Trace::load(uri) catch {
    _ => fail("native trace file load failed")
  }
  assert_true(loaded.protocol() == Some("trace.binprot"))
  assert_true(loaded.tool() == test_tool())
  assert_true(loaded.meta() == test_meta())
  assert_true(unwrap_events(loaded.read_events()) == test_events())
}
