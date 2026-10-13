// Deriving images from Ogre specifications (upstream `Image.Derive`), read
// through the typed `Scheme` attributes.

///|
fn ogre_target_endian(target : @core_theory.Target) -> @bitvec.Endian {
  match target.endianness() {
    LittleEndian => LittleEndian
    _ => BigEndian
  }
}

///|
fn OgreDoc::spec_target(self : OgreDoc) -> @core_theory.Target {
  let mut target = match spec_first(self, Scheme::arch()) {
    Some(name) =>
      match @core_theory.find_target(name) {
        Some(target) => target
        None => @core_theory.Target::unknown()
      }
    None => @core_theory.Target::unknown()
  }
  match spec_first(self, Scheme::bits()) {
    Some(bits) =>
      match spec_int(bits, "bits.size") {
        Ok(bits) => target = target.with_bits(bits)
        Err(_) => ()
      }
    None => ()
  }
  match spec_first(self, Scheme::is_little_endian()) {
    Some(true) => target = target.with_endianness(LittleEndian)
    Some(false) => target = target.with_endianness(BigEndian)
    None => ()
  }
  match spec_first(self, Scheme::system()) {
    Some(name) =>
      match @core_theory.System::of_string(name) {
        Some(system) => target = target.with_system(system)
        None => ()
      }
    None => ()
  }
  match spec_first(self, Scheme::abi()) {
    Some(name) =>
      match @core_theory.Abi::of_string(name) {
        Some(abi) => target = target.with_abi(abi)
        None => ()
      }
    None => ()
  }
  match spec_first(self, Scheme::format()) {
    Some(name) =>
      match @core_theory.Filetype::of_string(name) {
        Some(filetype) => target = target.with_filetype(filetype)
        None => ()
      }
    None => ()
  }
  target
}

///|
fn OgreDoc::image_endian(
  self : OgreDoc,
  target : @core_theory.Target,
) -> @bitvec.Endian {
  match spec_first(self, Scheme::is_little_endian()) {
    Some(true) => LittleEndian
    Some(false) => BigEndian
    None => ogre_target_endian(target)
  }
}

///|
fn ogre_slice_data(
  data : Bytes,
  off : Int32,
  len : Int32,
  description : String,
) -> Result[Bytes, String] {
  if off < 0 || len < 0 || off > data.length() || len > data.length() - off {
    Err("Ogre region \{description} is outside image data")
  } else {
    Ok(data[off:off + len].to_owned())
  }
}

///|
fn region_max_addr(addr : UInt64, size : Int32) -> UInt64 {
  if size <= 0 {
    addr
  } else {
    addr + (size - 1).to_uint64()
  }
}

///|
fn segments_cover_region(
  segments : Array[Segment],
  addr : UInt64,
  size : Int32,
) -> Bool {
  if size <= 0 {
    false
  } else {
    let max_addr = region_max_addr(addr, size)
    segments.any(segment => segment.contains(addr) && segment.contains(max_addr))
  }
}

///|
fn OgreDoc::find_named_region(
  self : OgreDoc,
  addr : UInt64,
  size : Int32,
) -> String? {
  for named in spec_values(self, Scheme::named_region()) {
    if spec_region(named, "named-region") is Ok((a, s)) &&
      a == addr &&
      s == size {
      return Some(named.info)
    }
  }
  None
}

///|
fn OgreDoc::find_named_region_at(self : OgreDoc, addr : UInt64) -> String? {
  for named in spec_values(self, Scheme::named_region()) {
    if spec_uint64(named.addr, "named-region.addr") is Ok(a) && a == addr {
      return Some(named.info)
    }
  }
  None
}

///|
fn OgreDoc::find_mapped_region(
  self : OgreDoc,
  addr : UInt64,
  size : Int32,
) -> (Int32, Int32)? {
  // upstream joins `segment` and `mapped` by the address only: the mapped
  // size is the size of the file image, which is smaller than the segment
  // when its tail is zero filled (e.g. a Mach-O `__DATA` with `__bss`);
  // a mapped region of the same size is preferred
  let mut found = None
  for mapped in spec_values(self, Scheme::mapped()) {
    if spec_region(mapped, "mapped") is Ok((a, s)) &&
      a == addr &&
      spec_int(mapped.info, "mapped.off") is Ok(off) {
      if s == size {
        return Some((off, s))
      } else if found is None {
        found = Some((off, s))
      }
    }
  }
  found
}

///|
fn OgreDoc::add_code_region_segments(
  self : OgreDoc,
  data : Bytes,
  endian : @bitvec.Endian,
  segments : Array[Segment],
  warnings : Array[String],
) -> Result[Unit, String] {
  for code in spec_values(self, Scheme::code_region()) {
    let (addr, size) = match
      spec_region(region(code.0, code.1, ()), "code-region") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    if segments_cover_region(segments, addr, size) {
      continue
    }
    let off = match spec_int(code.2, "code-region.off") {
      Ok(off) => off
      Err(reason) => return Err(reason)
    }
    match self.find_named_region_at(addr) {
      Some(name) =>
        match ogre_slice_data(data, off, size, "\{name}@\{addr}") {
          Ok(bytes) =>
            segments.push(
              Segment::create(
                name~,
                endian~,
                addr~,
                bytes,
                offset=off,
                readable=true,
                writable=false,
                executable=true,
              ),
            )
          Err(reason) => warnings.push(reason)
        }
      None => warnings.push("Ogre code region at \{addr}+\{size} is unnamed")
    }
  }
  Ok(())
}

///|
fn OgreDoc::image_segments(
  self : OgreDoc,
  data : Bytes,
  endian : @bitvec.Endian,
  warnings : Array[String],
) -> Result[Array[Segment], String] {
  let segments = []
  for segment in spec_values(self, Scheme::segment()) {
    let (addr, size) = match spec_region(segment, "segment") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let (r, w, x) = segment.info
    match
      (self.find_mapped_region(addr, size), self.find_named_region(addr, size)) {
      (Some((off, len)), Some(name)) =>
        match ogre_slice_data(data, off, len, "\{name}@\{addr}") {
          Ok(bytes) =>
            segments.push(
              Segment::create(
                name~,
                endian~,
                addr~,
                bytes,
                offset=off,
                readable=r,
                writable=w,
                executable=x,
              ),
            )
          Err(reason) => warnings.push(reason)
        }
      _ => warnings.push("Ogre segment at \{addr}+\{size} is not mapped")
    }
  }
  match self.add_code_region_segments(data, endian, segments, warnings) {
    Ok(_) => Ok(segments)
    Err(reason) => Err(reason)
  }
}

///|
fn OgreDoc::image_sections(
  self : OgreDoc,
  warnings : Array[String],
) -> Result[Array[Section], String] {
  let sections = []
  for section in spec_values(self, Scheme::section()) {
    match spec_region(section, "section") {
      Err(reason) => return Err(reason)
      Ok((addr, size)) =>
        match self.find_named_region(addr, size) {
          Some(name) => sections.push(Section::create(name~, addr~, size~))
          None => warnings.push("Ogre section at \{addr}+\{size} is unnamed")
        }
    }
  }
  Ok(sections)
}

///|
/// The longest name of the symbol that starts at `addr` (upstream
/// `Derive.symbol_name`).
fn OgreDoc::symbol_name(self : OgreDoc, addr : UInt64) -> String? {
  let mut name : String? = None
  for symbol in spec_values(self, Scheme::named_symbol()) {
    if spec_uint64(symbol.0, "named-symbol.addr") is Ok(a) && a == addr {
      match name {
        Some(existing) if existing.length() > symbol.1.length() => ()
        _ => name = Some(symbol.1)
      }
    }
  }
  name
}

///|
fn OgreDoc::symbol_locations(
  self : OgreDoc,
  root : UInt64,
) -> Result[(Int32, Array[(UInt64, Int32)]), String] {
  let mut root_size = 1
  let extra_locations = []
  for chunk in spec_values(self, Scheme::symbol_chunk()) {
    if spec_uint64(chunk.info, "symbol-chunk.root") is Ok(r) && r == root {
      let (addr, size) = match spec_region(chunk, "symbol-chunk") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if addr == root {
        root_size = size
      } else {
        extra_locations.push((addr, size))
      }
    }
  }
  Ok((root_size, extra_locations))
}

///|
fn OgreDoc::image_symbols(self : OgreDoc) -> Result[Array[Symbol], String] {
  let symbols = []
  for start in spec_values(self, Scheme::code_start()) {
    let addr = match spec_uint64(start, "code-start.addr") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    match self.symbol_name(addr) {
      Some(name) => {
        let (size, extra_locations) = match self.symbol_locations(addr) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        symbols.push(
          Symbol::create(
            name~,
            addr~,
            size~,
            extra_locations~,
            is_function=true,
          ),
        )
      }
      None => ()
    }
  }
  Ok(symbols)
}

///|
fn OgreDoc::image_relocations(
  self : OgreDoc,
) -> Result[Array[Relocation], String] {
  let relocations = []
  for relocation in spec_values(self, Scheme::relocation()) {
    let fixup = match spec_uint64(relocation.0, "relocation.fixup") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let target = match spec_uint64(relocation.1, "relocation.addr") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    relocations.push(Relocation::create(fixup~, target~))
  }
  for fixup in spec_values(self, Scheme::relative_relocation()) {
    match spec_uint64(fixup, "relative-relocation.fixup") {
      Ok(fixup) => relocations.push(Relocation::create(fixup~, relative=true))
      Err(reason) => return Err(reason)
    }
  }
  Ok(relocations)
}

///|
fn OgreDoc::image_external_references(
  self : OgreDoc,
) -> Result[Array[ExternalReference], String] {
  let references = []
  for reference in spec_values(self, Scheme::external_reference()) {
    match spec_uint64(reference.0, "external-reference.addr") {
      Ok(addr) =>
        references.push(ExternalReference::create(addr~, name=reference.1))
      Err(reason) => return Err(reason)
    }
  }
  Ok(references)
}

///|
fn OgreDoc::image_symbol_values(
  self : OgreDoc,
) -> Result[Array[SymbolValue], String] {
  let values = []
  for symbol_value in spec_values(self, Scheme::symbol_value()) {
    let addr = match spec_uint64(symbol_value.0, "symbol-value.addr") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    let value = match spec_uint64(symbol_value.1, "symbol-value.value") {
      Ok(value) => value
      Err(reason) => return Err(reason)
    }
    values.push(SymbolValue::create(addr~, value~))
  }
  Ok(values)
}

///|
fn OgreDoc::image_base_address(self : OgreDoc) -> Result[UInt64?, String] {
  match spec_first(self, Scheme::base_address()) {
    None => Ok(None)
    Some(addr) =>
      match spec_uint64(addr, "base-address.addr") {
        Ok(value) => Ok(Some(value))
        Err(reason) => Err(reason)
      }
  }
}

///|
pub fn Image::from_ogre(
  data : Bytes,
  doc : OgreDoc,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  let entry = match spec_first(doc, Scheme::entry_point()) {
    Some(value) =>
      match spec_uint64(value, "entry-point.addr") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
    None =>
      return Err("Ogre image spec is missing required attribute entry-point")
  }
  let selected_target = match target {
    Some(value) => value
    None => doc.spec_target()
  }
  let endian = doc.image_endian(selected_target)
  let warnings = []
  let segments = match doc.image_segments(data, endian, warnings) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let sections = match doc.image_sections(warnings) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let symbols = match doc.image_symbols() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let relocations = match doc.image_relocations() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let external_references = match doc.image_external_references() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let symbol_values = match doc.image_symbol_values() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let base_address = match doc.image_base_address() {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok(
    (
      Image::from_segments(
        entry~,
        endian~,
        segments,
        sections~,
        symbols~,
        relocations~,
        external_references~,
        required_libraries=spec_values(doc, Scheme::require()),
        symbol_values~,
        load_bias?=spec_first(doc, Scheme::bias()),
        is_executable?=spec_first(doc, Scheme::is_executable()),
        base_address?,
        filename?,
        target=selected_target,
        spec=doc,
      ),
      warnings,
    ),
  )
}

///|
pub fn Image::from_spec(
  data : Bytes,
  doc : OgreDoc,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  Image::from_ogre(data, doc, filename?, target?)
}

///|
pub fn Image::of_ogre_string(
  data : Bytes,
  spec : String,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  let doc = @ogre.Doc::from_string(spec) catch {
    error => return Err(error.message())
  }
  Image::from_ogre(data, doc, filename?, target?)
}
