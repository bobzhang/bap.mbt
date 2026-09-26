///|
/// Whether the lines appear in the text in this order.
fn contains_in_order(text : String, lines : Array[String]) -> Bool {
  let mut from = 0
  for line in lines {
    match text[from:].find(line) {
      None => return false
      Some(i) => from = from + i + line.length()
    }
  }
  true
}

///|
/// Decodes ASCII text.
fn ascii_text(bytes : Bytes) -> String {
  let buf = StringBuilder()
  for b in bytes {
    buf.write_char(b.to_int().unsafe_to_char())
  }
  buf.to_string()
}

///|
/// The primus-print plugin starts monitoring once per process (like the
/// upstream extension), so every run of this test shares one output file:
/// the printed observations accumulate and each run checks the new part.
test "bap --run leaves x86 callees and runs the executor systems" {
  let dir = @fixtures.host_temp_dir_with_elf()
  let file = dir + "/true.elf"
  let log = dir + "/observations.txt"
  let mut seen = 0
  for
    system in [
      "bap:legacy-main", "bap:promiscuous-executor", "bap:symbolic-executor",
    ] {
    let buf = StringBuilder()
    let code = @frontend.run(
      [
        "bap",
        file,
        "--run",
        "--run-entry-points=main",
        "--run-system=\{system}",
        "--primus-print-observations=enter-sub,leave-sub",
        "--primus-print-output=\{log}",
        "--cache-dir=" + dir + "/cache",
      ],
      out=s => buf.write_string(s),
      err=s => buf.write_string("[err] " + s),
    )
    let text = ascii_text(@fixtures.host_read_file(log))
    let fresh = text[seen:].to_owned().replace_all(old=dir, new="<tmp>")
    seen = text.length()
    inspect(code, content="0")
    // `foo` returns with `ret` (`call v_1 with noreturn` on the return
    // address pushed by `call foo`): the address resolves to the return
    // block of the call in `main`, the prompt of the call, so `foo` is left
    assert_true(
      contains_in_order(fresh, [
        "(enter-sub @<tmp>/true.elf:main)", "(enter-sub @<tmp>/true.elf:foo)", "(leave-sub @<tmp>/true.elf:foo)",
      ]),
      msg="\{system}: \{fresh} \{buf}",
    )
  }
  @fixtures.host_remove_dir(dir)
}
