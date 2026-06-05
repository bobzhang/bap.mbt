///|
pub(all) enum ImageBackendPerm {
  ImageBackendR
  ImageBackendW
  ImageBackendX
  ImageBackendOr(ImageBackendPerm, ImageBackendPerm)
} derive(Eq, Debug)

///|
pub(all) struct ImageBackendLocation {
  addr : UInt64
  len : Int
} derive(Eq, Debug)

///|
pub(all) struct ImageBackendSegment {
  name : String
  perm : ImageBackendPerm
  off : Int
  location : ImageBackendLocation
} derive(Eq, Debug)

///|
pub(all) struct ImageBackendSymbol {
  name : String
  is_function : Bool
  is_debug : Bool
  location : ImageBackendLocation
  extra_locations : Array[ImageBackendLocation]
} derive(Eq, Debug)

///|
pub(all) struct ImageBackendSection {
  name : String
  location : ImageBackendLocation
} derive(Eq, Debug)

///|
pub(all) struct ImageBackendImage {
  target : @core_theory.Target
  entry : UInt64
  segments : Array[ImageBackendSegment]
  symbols : Array[ImageBackendSymbol]
  sections : Array[ImageBackendSection]
}

///|
struct LegacyImageBackend {
  load_fn : (Bytes) -> ImageBackendImage?
}

///|
pub fn ImageBackendPerm::r() -> ImageBackendPerm {
  ImageBackendR
}

///|
pub fn ImageBackendPerm::w() -> ImageBackendPerm {
  ImageBackendW
}

///|
pub fn ImageBackendPerm::x() -> ImageBackendPerm {
  ImageBackendX
}

///|
pub fn ImageBackendPerm::union(
  self : ImageBackendPerm,
  other : ImageBackendPerm,
) -> ImageBackendPerm {
  ImageBackendOr(self, other)
}

///|
fn ImageBackendPerm::readable(self : ImageBackendPerm) -> Bool {
  match self {
    ImageBackendR => true
    ImageBackendW | ImageBackendX => false
    ImageBackendOr(left, right) => left.readable() || right.readable()
  }
}

///|
fn ImageBackendPerm::writable(self : ImageBackendPerm) -> Bool {
  match self {
    ImageBackendW => true
    ImageBackendR | ImageBackendX => false
    ImageBackendOr(left, right) => left.writable() || right.writable()
  }
}

///|
fn ImageBackendPerm::executable(self : ImageBackendPerm) -> Bool {
  match self {
    ImageBackendX => true
    ImageBackendR | ImageBackendW => false
    ImageBackendOr(left, right) => left.executable() || right.executable()
  }
}

///|
pub fn ImageBackendLocation::create(
  addr~ : UInt64,
  len~ : Int,
) -> ImageBackendLocation {
  { addr, len }
}

///|
pub fn ImageBackendSegment::create(
  name~ : String,
  perm~ : ImageBackendPerm,
  off~ : Int,
  location~ : ImageBackendLocation,
) -> ImageBackendSegment {
  { name, perm, off, location }
}

///|
pub fn ImageBackendSymbol::create(
  name~ : String,
  location~ : ImageBackendLocation,
  is_function? : Bool = false,
  is_debug? : Bool = false,
  extra_locations? : Array[ImageBackendLocation] = [],
) -> ImageBackendSymbol {
  {
    name,
    is_function,
    is_debug,
    location,
    extra_locations: extra_locations.copy(),
  }
}

///|
pub fn ImageBackendSymbol::locations(
  self : ImageBackendSymbol,
) -> Array[ImageBackendLocation] {
  let locations = [self.location]
  for location in self.extra_locations {
    locations.push(location)
  }
  locations
}

///|
pub fn ImageBackendSection::create(
  name~ : String,
  location~ : ImageBackendLocation,
) -> ImageBackendSection {
  { name, location }
}

///|
pub fn ImageBackendImage::create(
  target~ : @core_theory.Target,
  entry~ : UInt64,
  segments : Array[ImageBackendSegment],
  symbols? : Array[ImageBackendSymbol] = [],
  sections? : Array[ImageBackendSection] = [],
) -> ImageBackendImage {
  {
    target,
    entry,
    segments: segments.copy(),
    symbols: symbols.copy(),
    sections: sections.copy(),
  }
}

///|
pub fn LegacyImageBackend::create(
  load~ : (Bytes) -> ImageBackendImage?,
) -> LegacyImageBackend {
  { load_fn: load }
}

///|
pub fn LegacyImageBackend::load(
  self : LegacyImageBackend,
  data : Bytes,
) -> ImageBackendImage? {
  (self.load_fn)(data)
}

///|
fn image_backend_target_endian(target : @core_theory.Target) -> @bitvec.Endian {
  match target.endianness() {
    LittleEndian => LittleEndian
    _ => BigEndian
  }
}

///|
fn image_backend_slice_data(
  data : Bytes,
  off : Int,
  len : Int,
  description : String,
) -> Result[Bytes, String] {
  if off < 0 || len < 0 || off > data.length() || len > data.length() - off {
    Err("legacy image backend region \{description} is outside image data")
  } else {
    Ok(data[off:off + len].to_owned())
  }
}

///|
fn image_backend_push_fact(
  facts : Array[String],
  attribute : OgreAttribute,
  values : Array[String],
) -> Result[Unit, String] {
  match attribute.fact(values) {
    Ok(fact) => {
      facts.push(fact)
      Ok(())
    }
    Err(reason) => Err(reason)
  }
}

///|
fn ImageBackendLocation::fact_values(
  self : ImageBackendLocation,
) -> Array[String] {
  [self.addr.to_string(), self.len.to_string()]
}

///|
fn ImageBackendImage::push_target_facts(
  self : ImageBackendImage,
  facts : Array[String],
) -> Result[Unit, String] {
  match
    image_backend_push_fact(facts, Scheme::arch(), [
      self.target.name().unqualified(),
    ]) {
    Err(reason) => return Err(reason)
    Ok(_) => ()
  }
  if self.target.bits() > 0 {
    match
      image_backend_push_fact(facts, Scheme::bits(), [
        self.target.bits().to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  match self.target.endianness() {
    LittleEndian =>
      match
        image_backend_push_fact(facts, Scheme::is_little_endian(), ["true"]) {
        Err(reason) => return Err(reason)
        Ok(_) => ()
      }
    BigEndian =>
      match
        image_backend_push_fact(facts, Scheme::is_little_endian(), ["false"]) {
        Err(reason) => return Err(reason)
        Ok(_) => ()
      }
    BiEndian | UnknownEndianness => ()
  }
  if self.target.system() != UnknownSystem {
    match
      image_backend_push_fact(facts, Scheme::system(), [
        self.target.system().to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  if self.target.abi() != UnknownAbi {
    match
      image_backend_push_fact(facts, Scheme::abi(), [
        self.target.abi().to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  if self.target.filetype() != UnknownFiletype {
    match
      image_backend_push_fact(facts, Scheme::format(), [
        self.target.filetype().to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  Ok(())
}

///|
fn ImageBackendImage::to_spec(
  self : ImageBackendImage,
) -> Result[OgreDoc, String] {
  let attributes = [
    Scheme::arch(),
    Scheme::bits(),
    Scheme::is_little_endian(),
    Scheme::system(),
    Scheme::abi(),
    Scheme::format(),
    Scheme::entry_point(),
    Scheme::mapped(),
    Scheme::named_region(),
    Scheme::segment(),
    Scheme::section(),
    Scheme::code_start(),
    Scheme::named_symbol(),
    Scheme::symbol_chunk(),
  ]
  let facts = []
  match self.push_target_facts(facts) {
    Err(reason) => return Err(reason)
    Ok(_) => ()
  }
  match
    image_backend_push_fact(facts, Scheme::entry_point(), [
      self.entry.to_string(),
    ]) {
    Err(reason) => return Err(reason)
    Ok(_) => ()
  }
  for segment in self.segments {
    let values = segment.location.fact_values()
    match
      image_backend_push_fact(facts, Scheme::mapped(), [
        values[0],
        values[1],
        segment.off.to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
    match
      image_backend_push_fact(facts, Scheme::named_region(), [
        values[0],
        values[1],
        segment.name,
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
    match
      image_backend_push_fact(facts, Scheme::segment(), [
        values[0],
        values[1],
        segment.perm.readable().to_string(),
        segment.perm.writable().to_string(),
        segment.perm.executable().to_string(),
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  for section in self.sections {
    let values = section.location.fact_values()
    match
      image_backend_push_fact(facts, Scheme::named_region(), [
        values[0],
        values[1],
        section.name,
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
    match image_backend_push_fact(facts, Scheme::section(), values) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
  }
  for symbol in self.symbols {
    if symbol.is_function {
      match
        image_backend_push_fact(facts, Scheme::code_start(), [
          symbol.location.addr.to_string(),
        ]) {
        Err(reason) => return Err(reason)
        Ok(_) => ()
      }
    }
    match
      image_backend_push_fact(facts, Scheme::named_symbol(), [
        symbol.location.addr.to_string(),
        symbol.name,
      ]) {
      Err(reason) => return Err(reason)
      Ok(_) => ()
    }
    for location in symbol.locations() {
      let values = location.fact_values()
      match
        image_backend_push_fact(facts, Scheme::symbol_chunk(), [
          values[0],
          values[1],
          symbol.location.addr.to_string(),
        ]) {
        Err(reason) => return Err(reason)
        Ok(_) => ()
      }
    }
  }
  OgreDoc::from_scheme(attributes, facts~)
}

///|
fn ImageBackendImage::to_image(
  self : ImageBackendImage,
  data : Bytes,
  backend_name : String,
) -> Result[(Image, Array[String]), String] {
  if self.segments.is_empty() {
    return Err("legacy image backend \{backend_name} didn't provide segments")
  }
  let endian = image_backend_target_endian(self.target)
  let segments = []
  for segment in self.segments {
    match
      image_backend_slice_data(
        data,
        segment.off,
        segment.location.len,
        segment.name,
      ) {
      Ok(bytes) =>
        segments.push(
          Segment::create(
            name=segment.name,
            endian~,
            addr=segment.location.addr,
            bytes,
            offset=segment.off,
            readable=segment.perm.readable(),
            writable=segment.perm.writable(),
            executable=segment.perm.executable(),
          ),
        )
      Err(reason) => return Err(reason)
    }
  }
  let sections = self.sections.map(section => {
    Section::create(
      name=section.name,
      addr=section.location.addr,
      size=section.location.len,
    )
  })
  let symbols = []
  let warnings = []
  for symbol in self.symbols {
    let extra_locations = symbol.extra_locations.map(location => {
      (location.addr, location.len)
    })
    symbols.push(
      Symbol::create(
        name=symbol.name,
        addr=symbol.location.addr,
        size=symbol.location.len,
        extra_locations~,
        is_function=symbol.is_function,
        is_debug=symbol.is_debug,
      ),
    )
  }
  let spec = match self.to_spec() {
    Ok(doc) => doc
    Err(reason) => return Err(reason)
  }
  Ok(
    (
      Image::create(
        entry=self.entry,
        endian~,
        data~,
        segments~,
        sections~,
        symbols~,
        filename=backend_name,
        target=self.target,
        spec~,
      ),
      warnings,
    ),
  )
}

///|
pub fn ImageBackend::from_legacy(
  name~ : String,
  backend : LegacyImageBackend,
  description? : String,
  extensions? : Array[String],
  priority? : Int,
) -> ImageBackend {
  ImageBackend::create(name~, description?, extensions?, priority?, load=data => {
    match backend.load(data) {
      Some(image) => image.to_image(data, name)
      None => Err("legacy image backend \{name} was unable to process input")
    }
  })
}

///|
pub fn register_legacy_backend(
  name~ : String,
  backend : LegacyImageBackend,
  description? : String,
  extensions? : Array[String],
  priority? : Int,
) -> Result[Unit, String] {
  register_backend(
    name~,
    ImageBackend::from_legacy(
      name~,
      backend,
      description?,
      extensions?,
      priority?,
    ),
  )
}
