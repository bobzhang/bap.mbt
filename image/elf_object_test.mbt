///|
fn elf_object_image(data : Bytes) -> @image.Image raise {
  @image.register_builtin_backends().unwrap()
  match @image.Image::of_bytes(data, backend="elf") {
    Ok((image, _)) => image
    Err(reason) => fail(reason)
  }
}

///|
fn elf_object_relocations(image : @image.Image) -> String {
  let lines = []
  for r in image.relocations() {
    let target = match r.target() {
      Some(t) => "0x" + t.to_string(radix=16)
      None => "none"
    }
    lines.push("rel 0x\{r.fixup().to_string(radix=16)} -> \{target}")
  }
  for x in image.external_references() {
    lines.push("ext 0x\{x.addr().to_string(radix=16)} \{x.name()}")
  }
  lines.join("\n")
}

///|
test "ELF objects: the relocations of the code, without aliases" {
  let image = elf_object_image(@objects.x86_64_elf_object())
  // the relocation of `.eh_frame` at offset 7 is not a relocation of the
  // call at 6 (all sections of the object are at address 0)
  inspect(
    elf_object_relocations(image),
    content=(
      #|rel 0x7 -> 0x0
      #|rel 0x11 -> 0x6
      #|ext 0x18 ext
    ),
  )
  // the temporary label and the section symbol name nothing
  assert_eq(image.symbols().map(s => s.name()), ["sq", "g", "f"])
  // the specification has the relocations
  let spec = image.spec()
  let rels = spec.get(@image.Scheme::relocation())
  rels.sort_by((x, y) => x.0.compare(y.0))
  assert_eq(rels, [(7L, 0L), (17, 6)])
  assert_eq(spec.get(@image.Scheme::external_reference()), [(24L, "ext")])
}

///|
test "ELF objects: RISC-V call relocations cover the auipc/jalr pair" {
  let image = elf_object_image(@objects.riscv64_elf_object())
  inspect(
    elf_object_relocations(image),
    content=(
      #|rel 0x10 -> 0x0
      #|rel 0x14 -> 0x0
    ),
  )
  assert_eq(image.symbols().map(s => s.name()), ["sq", "g"])
}
