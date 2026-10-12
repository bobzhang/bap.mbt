///|
/// Image specifications are Ogre documents (upstream `Image.doc = Ogre.doc`).
///
/// This alias keeps the historical `@image.OgreDoc` name; all operations are
/// those of `@ogre.Doc`.
pub type OgreDoc = @ogre.Doc

///|
/// The values of an attribute in the order the facts were provided.
///
/// Ogre lists facts newest first; upstream image derivation reverses the
/// query results (`Seq.to_list_rev`), so image data follows provision order.
fn[A, K] spec_values(doc : OgreDoc, attr : @ogre.Attribute[A, K]) -> Array[A] {
  doc.get(attr).rev()
}

///|
/// The first provided value of an attribute, if any.
fn[A, K] spec_first(doc : OgreDoc, attr : @ogre.Attribute[A, K]) -> A? {
  spec_values(doc, attr).get(0)
}

///|
fn spec_uint64(value : Int64, what : String) -> Result[UInt64, String] {
  if value < 0L {
    Err("Ogre field \{what} must be non-negative")
  } else {
    Ok(value.reinterpret_as_uint64())
  }
}

///|
fn spec_int(value : Int64, what : String) -> Result[Int32, String] {
  if value < 0L || value > 2147483647L {
    Err("Ogre field \{what} is out of Int range")
  } else {
    Ok(value.to_int())
  }
}

///|
fn[A] spec_region(
  r : Region[A],
  attribute : String,
) -> Result[(UInt64, Int32), String] {
  match spec_uint64(r.addr, "\{attribute}.addr") {
    Err(reason) => Err(reason)
    Ok(addr) =>
      match spec_int(r.size, "\{attribute}.size") {
        Ok(size) => Ok((addr, size))
        Err(reason) => Err(reason)
      }
  }
}

///|
fn provide_target_facts(target : @core_theory.Target) -> @ogre.Ogre[Unit] {
  let facts = [@ogre.provide(Scheme::arch(), target.name().unqualified())]
  if target.bits() > 0 {
    facts.push(@ogre.provide(Scheme::bits(), target.bits().to_int64()))
  }
  match target.endianness() {
    LittleEndian => facts.push(@ogre.provide(Scheme::is_little_endian(), true))
    BigEndian => facts.push(@ogre.provide(Scheme::is_little_endian(), false))
    BiEndian | UnknownEndianness => ()
  }
  if target.system() != UnknownSystem {
    facts.push(@ogre.provide(Scheme::system(), target.system().to_string()))
  }
  if target.abi() != UnknownAbi {
    facts.push(@ogre.provide(Scheme::abi(), target.abi().to_string()))
  }
  if target.filetype() != UnknownFiletype {
    facts.push(@ogre.provide(Scheme::format(), target.filetype().to_string()))
  }
  @ogre.Ogre::all_unit(facts)
}

///|
/// Provides the facts that describe an image (upstream
/// `Legacy.provide_image`): the target, the entry point, segments with their
/// file mappings and names, sections, the relocations and the references to
/// external symbols, and function symbols with their chunks.
fn provide_image(image : Image) -> @ogre.Ogre[Unit] {
  let facts = [
    provide_target_facts(image.arch()),
    @ogre.provide(
      Scheme::entry_point(),
      image.entry_point().reinterpret_as_int64(),
    ),
  ]
  for segment in image.segments() {
    let addr = segment.addr().reinterpret_as_int64()
    let size = segment.size().to_int64()
    facts.push(
      @ogre.provide(
        Scheme::segment(),
        (
          addr,
          size,
          segment.is_readable(),
          segment.is_writable(),
          segment.is_executable(),
        ),
      ),
    )
    facts.push(
      @ogre.provide(Scheme::mapped(), (addr, size, segment.offset().to_int64())),
    )
    facts.push(
      @ogre.provide(Scheme::named_region(), (addr, size, segment.name())),
    )
  }
  for section in image.sections() {
    let addr = section.addr().reinterpret_as_int64()
    let size = section.size().to_int64()
    facts.push(@ogre.provide(Scheme::section(), (addr, size)))
    facts.push(
      @ogre.provide(Scheme::named_region(), (addr, size, section.name())),
    )
  }
  for relocation in image.relocations() {
    let fixup = relocation.fixup().reinterpret_as_int64()
    match relocation.target() {
      Some(target) =>
        facts.push(
          @ogre.provide(
            Scheme::relocation(),
            (fixup, target.reinterpret_as_int64()),
          ),
        )
      None =>
        if relocation.is_relative() {
          facts.push(@ogre.provide(Scheme::relative_relocation(), fixup))
        }
    }
  }
  for reference in image.external_references() {
    facts.push(
      @ogre.provide(
        Scheme::external_reference(),
        (reference.addr().reinterpret_as_int64(), reference.name()),
      ),
    )
  }
  for symbol in image.symbols() {
    if symbol.is_function() {
      let root = symbol.addr().reinterpret_as_int64()
      facts.push(@ogre.provide(Scheme::named_symbol(), (root, symbol.name())))
      facts.push(@ogre.provide(Scheme::code_start(), root))
      facts.push(
        @ogre.provide(
          Scheme::symbol_chunk(),
          (root, symbol.size().to_int64(), root),
        ),
      )
      for location in symbol.extra_locations() {
        facts.push(
          @ogre.provide(
            Scheme::symbol_chunk(),
            (location.0.reinterpret_as_int64(), location.1.to_int64(), root),
          ),
        )
      }
    }
  }
  @ogre.Ogre::all_unit(facts)
}

///|
/// The specification of an image built from its metadata (upstream
/// `Legacy.provide_image`).
pub fn Spec::of_image(image : Image) -> Result[OgreDoc, String] {
  try @ogre.exec(provide_image(image), @ogre.Doc::empty()) catch {
    error => Err(error.message())
  } noraise {
    doc => Ok(doc)
  }
}
