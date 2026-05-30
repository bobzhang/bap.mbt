///|
struct Image {
  filename_value : String?
  target_value : @core_theory.Target?
  entry_value : UInt64
  endian_value : @bitvec.Endian
  data_value : Bytes
  segments_value : Array[Segment]
  sections_value : Array[Section]
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
  sections? : Array[Section],
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
    sections_value: match sections {
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
  sections? : Array[Section],
  symbols? : Array[Symbol],
  filename? : String,
  target? : @core_theory.Target,
) -> Image {
  Image::create(
    entry~,
    endian~,
    segments~,
    sections?,
    symbols?,
    filename?,
    target?,
  )
}

///|
pub fn Image::of_bytes(
  data : Bytes,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  match backend {
    Some(name) =>
      match find_backend(name) {
        Some(loader) => loader.load(data)
        None => Err("unknown image backend \{name}")
      }
    None => Ok((Image::create(entry=0UL, endian=LittleEndian, data~), []))
  }
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
pub fn Image::sections(self : Image) -> Array[Section] {
  self.sections_value.copy()
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
pub fn Image::memory_of_section(
  self : Image,
  section : Section,
) -> @memory.Memory? {
  match
    self.segments_value.search_by(segment => {
      segment.contains(section.addr()) && segment.contains(section.max_addr())
    }) {
    Some(i) =>
      match
        self.segments_value[i]
        .memory()
        .view(from=section.addr(), words=section.size()) {
        Ok(memory) => Some(memory)
        Err(_) => None
      }
    None => None
  }
}

///|
pub fn Image::sections_of_segment(
  self : Image,
  segment : Segment,
) -> Array[Section] {
  self.sections_value.filter(section => {
    segment.contains(section.addr()) && segment.contains(section.max_addr())
  })
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
fn min_int(lhs : Int, rhs : Int) -> Int {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn Image::symbol_memory_chunks(
  self : Image,
  symbol : Symbol,
) -> Array[@memory.Memory]? {
  let size = if symbol.size() <= 0 { 1 } else { symbol.size() }
  let chunks = []
  let mut current = symbol.addr()
  let mut remaining = size
  while remaining > 0 {
    match self.segments_value.search_by(segment => segment.contains(current)) {
      Some(i) => {
        let memory = self.segments_value[i].memory()
        let available = (memory.max_addr() - current).to_int() + 1
        let take = min_int(remaining, available)
        match memory.view(from=current, words=take) {
          Ok(chunk) => {
            chunks.push(chunk)
            remaining = remaining - take
            current = current + take.to_uint64()
          }
          Err(_) => return None
        }
      }
      None => return None
    }
  }
  Some(chunks)
}

///|
pub fn Image::memories_of_symbol(
  self : Image,
  symbol : Symbol,
) -> Array[@memory.Memory]? {
  self.symbol_memory_chunks(symbol)
}

///|
pub fn Image::memory_of_symbol(
  self : Image,
  symbol : Symbol,
) -> (@memory.Memory, Array[@memory.Memory])? {
  match self.symbol_memory_chunks(symbol) {
    Some(chunks) if !chunks.is_empty() =>
      Some((chunks[0], chunks[1:].to_owned()))
    _ => None
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
pub fn Image::add_section(self : Image, section : Section) -> Image {
  let sections = self.sections_value.copy()
  sections.push(section)
  { ..self, sections_value: sections }
}

///|
pub fn Image::add_symbol(self : Image, symbol : Symbol) -> Image {
  let symbols = self.symbols_value.copy()
  symbols.push(symbol)
  { ..self, symbols_value: symbols }
}
