// Property-based robustness tests for the `image` loaders: executables and
// objects are untrusted input, so truncated or corrupted files must load or
// be rejected, never abort, and loaded segments must describe their bytes.

///|
fn image_fixture(which : Int32) -> Bytes {
  match which {
    0 => @objects.x86_64_elf_object()
    1 => @objects.aarch64_elf_object()
    2 => @objects.riscv64_elf_object()
    3 => @objects.x86_64_macho()
    4 => @objects.arm64_macho()
    5 => @objects.fat_macho()
    6 => @objects.i386_coff_object()
    _ => @objects.x86_64_pe()
  }
}

///|
let image_fixture_count : Int32 = 8

///|
/// A fixture with a few bytes changed or its tail cut off.
struct ImageMutant {
  which : Int32
  edits : Array[(Int32, Int32, Int32)] // (kind, position seed, byte)
} derive(Debug)

///|
impl @quickcheck.Arbitrary for ImageMutant with fn arbitrary(_size, rs) {
  let which = rs
    .next_uint(limit=image_fixture_count.reinterpret_as_uint())
    .reinterpret_as_int()
  let edits = Array::makei(1 + rs.next_uint(limit=6).reinterpret_as_int(), _ => {
    (
      rs.next_uint(limit=5).reinterpret_as_int(),
      rs.next_positive_int(),
      rs.next_uint(limit=256).reinterpret_as_int(),
    )
  })
  { which, edits, }
}

///|
impl @quickcheck.Shrink for ImageMutant with fn shrink(m) {
  Array::makei(m.edits.length(), i => {
    let edits = m.edits.copy()
    edits.remove(i) |> ignore
    { ..m, edits, }
  }).iter()
}

///|
fn ImageMutant::bytes(self : ImageMutant) -> Bytes {
  let data = image_fixture(self.which).to_array()
  for edit in self.edits {
    let (kind, seed, byte) = edit
    let len = data.length()
    if len == 0 {
      break
    }
    // headers and load commands live at the start: bias edits towards them
    let pos = if seed % 2 == 0 { seed % len.min(256) } else { seed % len }
    match kind {
      0 => data.truncate(pos)
      1 => data[pos] = b'\xff'
      2 => data[pos] = b'\x00'
      3 => data[pos] = (data[pos].to_int() ^ 0x80).to_byte()
      _ => data[pos] = byte.to_byte()
    }
  }
  Bytes::from_array(data)
}

///|
fn check_image(img : @image.Image) -> Bool {
  let mut ok = true
  for seg in img.segments() {
    let mem = img.memory_of_segment(seg)
    ok = ok &&
      mem.min_addr() == seg.addr() &&
      mem.length() == seg.size() &&
      seg.contains(seg.addr()) == (seg.size() > 0)
    ignore(img.sections_of_segment(seg))
    ignore(img.symbols_of_segment(seg))
  }
  for sec in img.sections() {
    ignore(img.memory_of_section(sec))
  }
  for sym in img.symbols() {
    ignore(img.memory_of_symbol(sym))
    ignore(img.segment_of_symbol(sym))
  }
  ignore(img.memory().length())
  ok
}

///|
test "qc: the unmutated fixtures load" {
  for which in 0..<image_fixture_count {
    guard @image.Image::of_object(image_fixture(which)) is Ok((img, _)) else {
      fail("fixture \{which} does not load")
    }
    assert_true(check_image(img))
    assert_true(!img.segments().is_empty() || !img.sections().is_empty())
  }
}

///|
test "qc: corrupted executables and objects load or are rejected" {
  @quickcheck.check(
    (m : ImageMutant) => {
      let bytes = m.bytes()
      // the loader of the upstream default `llvm` backend, which selects
      // the ELF, Mach-O or PE/COFF reader by the contents
      match @image.Image::of_object(bytes) {
        Ok((img, _)) => check_image(img)
        Err(_) => true
      }
    },
    observe=m => {
      [
        @quickcheck.collect(m.which),
        @quickcheck.classify(
          @image.Image::of_object(m.bytes()) is Ok(_),
          "still loads",
        ),
      ]
    },
    count=400,
    seed=101,
  )
}
