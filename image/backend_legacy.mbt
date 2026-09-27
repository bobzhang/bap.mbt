///|
pub(all) enum ImageBackendPerm {
  ImageBackendR
  ImageBackendW
  ImageBackendX
  ImageBackendOr(ImageBackendPerm, ImageBackendPerm)
} derive(Eq, Debug)

///|
pub extend ImageBackendPerm with Eq::{not_equal, equal}

///|
pub extend ImageBackendPerm with Debug::{to_repr}

///|
pub(all) struct ImageBackendLocation {
  addr : UInt64
  len : Int
} derive(Eq, Debug)

///|
pub extend ImageBackendLocation with Eq::{not_equal, equal}

///|
pub extend ImageBackendLocation with Debug::{to_repr}

///|
pub(all) struct ImageBackendSegment {
  name : String
  perm : ImageBackendPerm
  off : Int
  location : ImageBackendLocation
} derive(Eq, Debug)

///|
pub extend ImageBackendSegment with Eq::{not_equal, equal}

///|
pub extend ImageBackendSegment with Debug::{to_repr}

///|
pub(all) struct ImageBackendSymbol {
  name : String
  is_function : Bool
  is_debug : Bool
  location : ImageBackendLocation
  extra_locations : Array[ImageBackendLocation]
} derive(Eq, Debug)

///|
pub extend ImageBackendSymbol with Eq::{not_equal, equal}

///|
pub extend ImageBackendSymbol with Debug::{to_repr}

///|
pub(all) struct ImageBackendSection {
  name : String
  location : ImageBackendLocation
} derive(Eq, Debug)

///|
pub extend ImageBackendSection with Eq::{not_equal, equal}

///|
pub extend ImageBackendSection with Debug::{to_repr}

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
  { addr, len, }
}

///|
pub fn ImageBackendSegment::create(
  name~ : String,
  perm~ : ImageBackendPerm,
  off~ : Int,
  location~ : ImageBackendLocation,
) -> ImageBackendSegment {
  { name, perm, off, location, }
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
  { name, location, }
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
  { load_fn: load, }
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
