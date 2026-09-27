///|
test "the llvm loader: the loader of the contents" {
  debug_inspect(
    @image.Image::of_object(b"\x00\x01\x02\x03").map(_ => ()),
    content=(
      #|Err("File format is not supported")
    ),
  )
  let (image, _) = macho_ok(
    @image.Image::of_object(
      @objects.fat_macho(),
      target=@core_theory.Target::aarch64(),
    ),
  )
  inspect(image.arch().to_string(), content="bap:aarch64")
  let (image, _) = macho_ok(@image.Image::of_object(@objects.x86_64_pe()))
  inspect(image.arch().to_string(), content="bap:x86_64")
}

///|
test "the llvm backend selects the loader by the contents" {
  inspect(
    [
      @image.detect_format(@objects.x86_64_macho()),
      @image.detect_format(@objects.fat_macho()),
      @image.detect_format(@objects.x86_64_pe()),
      @image.detect_format(@objects.i386_coff_object()),
      @image.detect_format(b"\x7fELF\x02\x01\x01"),
      @image.detect_format(b"junk"),
    ]
    .map(x => x.unwrap_or("-"))
    .join(" "),
    content=(
      #|macho macho coff coff elf -
    ),
  )
  @image.register_builtin_backends() |> ignore
  let names = @image.available_backends()
  assert_true(
    names.contains("llvm") && names.contains("macho") && names.contains("coff"),
  )
  let (image, _) = macho_ok(
    @image.Image::of_bytes(@objects.x86_64_macho(), backend="llvm"),
  )
  assert_eq(image.entry_point(), 0x100000400)
  let (image, _) = macho_ok(
    @image.Image::of_bytes(@objects.x86_64_pe(), backend="llvm"),
  )
  assert_eq(image.entry_point(), 0x140001000)
  inspect(
    @image.backend_names_for_extension("dylib").join(","),
    content=(
      #|macho
    ),
  )
  inspect(
    @image.backend_names_for_extension("exe").join(","),
    content=(
      #|coff
    ),
  )
}
