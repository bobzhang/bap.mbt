///|
struct Image {
  filename_value : String?
  target_value : @core_theory.Target?
  entry_value : UInt64
  endian_value : @bitvec.Endian
  data_value : Bytes
  segments_value : Array[Segment]
  symbols_value : Array[Symbol]
}

///|
fn empty_bytes() -> Bytes {
  Bytes::new(0)
}

///|
pub fn Image::create(
  entry~ : UInt64,
  endian~ : @bitvec.Endian,
  filename? : String,
  target? : @core_theory.Target,
  data? : Bytes,
  segments? : Array[Segment],
  symbols? : Array[Symbol],
) -> Image {
  {
    filename_value: filename,
    target_value: target,
    entry_value: entry,
    endian_value: endian,
    data_value: match data {
      Some(bytes) => bytes
      None => empty_bytes()
    },
    segments_value: match segments {
      Some(items) => items.copy()
      None => []
    },
    symbols_value: match symbols {
      Some(items) => items.copy()
      None => []
    },
  }
}

///|
pub fn Image::from_segments(
  entry~ : UInt64,
  endian~ : @bitvec.Endian,
  segments : Array[Segment],
  symbols? : Array[Symbol],
  filename? : String,
  target? : @core_theory.Target,
) -> Image {
  Image::create(entry~, endian~, segments~, symbols?, filename?, target?)
}

///|
pub fn Image::entry_point(self : Image) -> UInt64 {
  self.entry_value
}

///|
pub fn Image::filename(self : Image) -> String? {
  self.filename_value
}

///|
pub fn Image::target(self : Image) -> @core_theory.Target? {
  self.target_value
}

///|
pub fn Image::endian(self : Image) -> @bitvec.Endian {
  self.endian_value
}

///|
pub fn Image::data(self : Image) -> Bytes {
  self.data_value
}

///|
pub fn Image::segments(self : Image) -> Array[Segment] {
  self.segments_value.copy()
}

///|
pub fn Image::symbols(self : Image) -> Array[Symbol] {
  self.symbols_value.copy()
}

///|
pub fn Image::memory(self : Image) -> @memory.MemMap[String] {
  let mut map = @memory.MemMap::empty()
  for segment in self.segments_value {
    map = map.add(segment.memory(), segment.name())
  }
  map
}

///|
pub fn Image::memory_of_segment(
  _self : Image,
  segment : Segment,
) -> @memory.Memory {
  segment.memory()
}

///|
pub fn Image::segment_of_symbol(self : Image, symbol : Symbol) -> Segment? {
  self.segments_value
  .search_by(segment => segment.contains(symbol.addr()))
  .map(i => self.segments_value[i])
}

///|
pub fn Image::symbols_of_segment(
  self : Image,
  segment : Segment,
) -> Array[Symbol] {
  self.symbols_value.filter(symbol => segment.contains(symbol.addr()))
}

///|
pub fn Image::memory_of_symbol(
  self : Image,
  symbol : Symbol,
) -> (@memory.Memory, Array[@memory.Memory])? {
  match self.segment_of_symbol(symbol) {
    Some(segment) => {
      let size = if symbol.size() <= 0 { 1 } else { symbol.size() }
      match segment.memory().view(from=symbol.addr(), words=size) {
        Ok(mem) => Some((mem, []))
        Err(_) => None
      }
    }
    None => None
  }
}

///|
pub fn Image::words(
  self : Image,
  word_size~ : Int,
) -> @memory.MemMap[@types.Word] {
  let bytes_per_word = word_size / 8
  let mut map = @memory.MemMap::empty()
  if word_size > 0 && word_size % 8 == 0 {
    for segment in self.segments_value {
      let memory = segment.memory()
      let count = memory.length() / bytes_per_word
      for i in 0..<count {
        let addr = memory.min_addr() + (i * bytes_per_word).to_uint64()
        match memory.view(from=addr, words=1, word_size=bytes_per_word) {
          Ok(chunk) =>
            match memory.load(addr, width=word_size) {
              Ok(word) => map = map.add(chunk, word)
              Err(_) => ()
            }
          Err(_) => ()
        }
      }
    }
  }
  map
}

///|
pub fn Image::add_segment(self : Image, segment : Segment) -> Image {
  let segments = self.segments_value.copy()
  segments.push(segment)
  { ..self, segments_value: segments }
}

///|
pub fn Image::add_symbol(self : Image, symbol : Symbol) -> Image {
  let symbols = self.symbols_value.copy()
  symbols.push(symbol)
  { ..self, symbols_value: symbols }
}
