// The counterpart of the upstream `llvm` loader: it recognizes the file
// format by its contents (as LLVM's `createBinary` does) and loads ELF,
// Mach-O (thin or universal) and PE/COFF files.

///|
/// The format of an object file by its magic number: `elf`, `macho` (thin
/// or universal) or `coff` (PE images and COFF objects).
pub fn detect_format(data : BytesView) -> String? {
  if data.length() >= 4 &&
    data[0] == b'\x7f' &&
    data[1] == b'E' &&
    data[2] == b'L' &&
    data[3] == b'F' {
    Some("elf")
  } else if @macho.is_macho(data) || @macho.is_fat(data) {
    Some("macho")
  } else if @coff.is_coff(data) {
    Some("coff")
  } else {
    None
  }
}

///|
/// Loads an ELF, Mach-O or PE/COFF file, selected by its contents; the
/// `target` selects the architecture of a universal binary.
pub fn Image::of_object(
  data : Bytes,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  match detect_format(data) {
    Some("elf") => image_elf_load(data)
    Some("macho") => image_macho_load(data, target?)
    Some("coff") => image_coff_load(data)
    _ => Err("File format is not supported")
  }
}

///|
/// The image backend of the upstream default loader `llvm`: it selects
/// the ELF, Mach-O or PE/COFF loader by the file contents.
pub fn ImageBackend::llvm() -> ImageBackend {
  ImageBackend::create(
    name="llvm",
    description="ELF, Mach-O or PE/COFF image, selected by the file contents",
    priority=10,
    load=data => Image::of_object(data),
  )
}
