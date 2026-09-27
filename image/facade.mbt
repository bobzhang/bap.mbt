///|
pub fn create(
  path : String,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  Image::of_file(path, backend?)
}

///|
pub fn of_string(
  data : String,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  Image::of_string(data, backend?)
}

///|
pub fn of_bigstring(
  data : Bytes,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  Image::of_bigstring(data, backend?)
}

///|
pub fn from_spec(
  data : Bytes,
  doc : OgreDoc,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  Image::from_spec(data, doc, filename?, target?)
}

///|
pub fn entry_point(image : Image) -> UInt64 {
  image.entry_point()
}

///|
pub fn filename(image : Image) -> String? {
  image.filename()
}

///|
pub fn arch(image : Image) -> @core_theory.Target {
  image.arch()
}

///|
pub fn addr_size(image : Image) -> Int {
  image.addr_size()
}

///|
pub fn endian(image : Image) -> @bitvec.Endian {
  image.endian()
}

///|
pub fn spec(image : Image) -> OgreDoc {
  image.spec()
}

///|
pub fn data(image : Image) -> Bytes {
  image.data()
}

///|
pub fn words(image : Image, size : Int) -> @memory.MemMap[@types.Word] {
  image.words(word_size=size)
}

///|
pub fn segments(image : Image) -> Array[Segment] {
  image.segments()
}

///|
pub fn symbols(image : Image) -> Array[Symbol] {
  image.symbols()
}

///|
pub fn memory(image : Image) -> @memory.MemMap[@types.Value] {
  image.memory()
}

///|
pub fn memory_of_segment(image : Image, segment : Segment) -> @memory.Memory {
  image.memory_of_segment(segment)
}

///|
pub fn memory_of_symbol(
  image : Image,
  symbol : Symbol,
) -> (@memory.Memory, Array[@memory.Memory]) raise ImageLookupError {
  image.memory_of_symbol_exn(symbol)
}

///|
pub fn symbols_of_segment(image : Image, segment : Segment) -> Array[Symbol] {
  image.symbols_of_segment(segment)
}

///|
pub fn segment_of_symbol(
  image : Image,
  symbol : Symbol,
) -> Segment raise ImageLookupError {
  image.segment_of_symbol_exn(symbol)
}
