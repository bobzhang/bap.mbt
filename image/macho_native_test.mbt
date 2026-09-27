///|
/// Loads the host `/usr/bin/true` if it is a Mach-O file (thin or
/// universal); `None` on other hosts.
fn host_true(target? : @core_theory.Target) -> @image.Image? raise {
  let data = match @native_io.read_file("/usr/bin/true") {
    Ok(data) => data
    Err(_) => return None
  }
  if !@macho.is_macho(data) && !@macho.is_fat(data) {
    return None
  }
  let thin = match @image.thin_binary(data, target?) {
    Ok(thin) => thin
    Err(e) => fail(e)
  }
  match @image.ImageBackend::macho().load(thin) {
    Ok((image, _)) => Some(image)
    Err(e) => fail(e)
  }
}

///|
test "the host /usr/bin/true: the host architecture" {
  guard host_true() is Some(image) else { return }
  let host = @native_io.host_architecture()
  let arch = image.arch()
  if host == "aarch64" {
    assert_true(arch.belongs(@core_theory.Target::aarch64()))
  } else if host == "x86_64" {
    assert_true(arch.belongs(@core_theory.Target::x86_64()))
  }
  // the entry point is in the code of `__TEXT,__text`
  let text = image.sections().filter(s => s.name() == "__text")
  assert_eq(text.length(), 1)
  assert_true(text[0].contains(image.entry_point()))
  assert_true(
    image
    .segments()
    .any(s => {
      s.name() == "__TEXT" &&
      s.is_executable() &&
      s.contains(image.entry_point())
    }),
  )
  // the function starts are functions
  assert_true(image.symbols().any(s => s.addr() == image.entry_point()))
  assert_true(image.required_libraries().any(l => l.contains("libSystem")))
}

///|
test "the host /usr/bin/true: a requested architecture" {
  guard host_true(target=@core_theory.Target::x86_64()) is Some(image) else {
    return
  }
  // `true` is universal on Apple silicon hosts and thin (x86-64) on Intel
  // ones
  assert_true(
    image.arch().belongs(@core_theory.Target::x86_64()) ||
    image.arch().belongs(@core_theory.Target::aarch64()),
  )
  assert_true(
    image
    .sections()
    .any(s => s.name() == "__text" && s.contains(image.entry_point())),
  )
}
