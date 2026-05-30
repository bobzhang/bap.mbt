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
  relocations_value : Array[Relocation]
  external_references_value : Array[ExternalReference]
  required_libraries_value : Array[String]
  rpaths_value : Array[String]
  runpaths_value : Array[String]
  symbol_values_value : Array[SymbolValue]
  interpreter_value : String?
  soname_value : String?
  load_bias_value : Int64?
  is_executable_value : Bool?
  base_address_value : UInt64?
  spec_value : OgreDoc?
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
  relocations? : Array[Relocation],
  external_references? : Array[ExternalReference],
  required_libraries? : Array[String],
  rpaths? : Array[String],
  runpaths? : Array[String],
  symbol_values? : Array[SymbolValue],
  interpreter? : String,
  soname? : String,
  load_bias? : Int64,
  is_executable? : Bool,
  base_address? : UInt64,
  spec? : OgreDoc,
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
    relocations_value: match relocations {
      Some(items) => items.copy()
      None => []
    },
    external_references_value: match external_references {
      Some(items) => items.copy()
      None => []
    },
    required_libraries_value: match required_libraries {
      Some(items) => items.copy()
      None => []
    },
    rpaths_value: match rpaths {
      Some(items) => items.copy()
      None => []
    },
    runpaths_value: match runpaths {
      Some(items) => items.copy()
      None => []
    },
    symbol_values_value: match symbol_values {
      Some(items) => items.copy()
      None => []
    },
    interpreter_value: interpreter,
    soname_value: soname,
    load_bias_value: load_bias,
    is_executable_value: is_executable,
    base_address_value: base_address,
    spec_value: spec,
  }
}

///|
pub fn Image::from_segments(
  entry~ : UInt64,
  endian~ : @bitvec.Endian,
  segments : Array[Segment],
  sections? : Array[Section],
  symbols? : Array[Symbol],
  relocations? : Array[Relocation],
  external_references? : Array[ExternalReference],
  required_libraries? : Array[String],
  rpaths? : Array[String],
  runpaths? : Array[String],
  symbol_values? : Array[SymbolValue],
  interpreter? : String,
  soname? : String,
  load_bias? : Int64,
  is_executable? : Bool,
  base_address? : UInt64,
  filename? : String,
  target? : @core_theory.Target,
  spec? : OgreDoc,
) -> Image {
  Image::create(
    entry~,
    endian~,
    segments~,
    sections?,
    symbols?,
    relocations?,
    external_references?,
    required_libraries?,
    rpaths?,
    runpaths?,
    symbol_values?,
    interpreter?,
    soname?,
    load_bias?,
    is_executable?,
    base_address?,
    filename?,
    target?,
    spec?,
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
pub fn Image::of_bigstring(
  data : Bytes,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  Image::of_bytes(data, backend?)
}

///|
pub fn Image::of_string(
  data : String,
  backend? : String,
) -> Result[(Image, Array[String]), String] {
  Image::of_bytes(@utf8.encode(data), backend?)
}

///|
fn image_filename_extension(filename : String) -> String? {
  let parts = filename.split(".").to_array()
  if parts.length() > 1 {
    Some(parts[parts.length() - 1].to_owned().to_lower())
  } else {
    None
  }
}

///|
pub fn Image::of_bytes_for_filename(
  data : Bytes,
  filename~ : String,
) -> Result[(Image, Array[String]), String] {
  match image_filename_extension(filename) {
    Some(extension) => {
      let backends = backends_for_extension(extension)
      if backends.is_empty() {
        Err("no image backend for extension \{extension}")
      } else {
        let mut last_error = ""
        for backend in backends {
          match backend.load(data) {
            Ok(result) => return Ok(result)
            Err(reason) => last_error = reason
          }
        }
        Err(
          "all image backends failed for extension \{extension}: \{last_error}",
        )
      }
    }
    None => Err("can't infer image backend from filename \{filename}")
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
pub fn Image::arch(self : Image) -> @core_theory.Target {
  match self.target_value {
    Some(target) => target
    None => @core_theory.Target::unknown()
  }
}

///|
pub fn Image::spec(self : Image) -> OgreDoc {
  match self.spec_value {
    Some(doc) => doc
    None =>
      match self.target_value {
        Some(target) => OgreDoc::from_target(target)
        None => OgreDoc::from_target(@core_theory.Target::unknown())
      }
  }
}

///|
pub fn Image::addr_size(self : Image) -> Int {
  match self.target_value {
    Some(target) if target.bits() > 0 => target.bits()
    _ => 32
  }
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
pub fn Image::relocations(self : Image) -> Array[Relocation] {
  self.relocations_value.copy()
}

///|
pub fn Image::external_references(self : Image) -> Array[ExternalReference] {
  self.external_references_value.copy()
}

///|
pub fn Image::required_libraries(self : Image) -> Array[String] {
  self.required_libraries_value.copy()
}

///|
pub fn Image::rpaths(self : Image) -> Array[String] {
  self.rpaths_value.copy()
}

///|
pub fn Image::runpaths(self : Image) -> Array[String] {
  self.runpaths_value.copy()
}

///|
pub fn Image::symbol_values(self : Image) -> Array[SymbolValue] {
  self.symbol_values_value.copy()
}

///|
pub fn Image::interpreter(self : Image) -> String? {
  self.interpreter_value
}

///|
pub fn Image::soname(self : Image) -> String? {
  self.soname_value
}

///|
pub fn Image::load_bias(self : Image) -> Int64? {
  self.load_bias_value
}

///|
pub fn Image::is_executable(self : Image) -> Bool? {
  self.is_executable_value
}

///|
pub fn Image::base_address(self : Image) -> UInt64? {
  self.base_address_value
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

///|
pub fn Image::add_relocation(self : Image, relocation : Relocation) -> Image {
  let relocations = self.relocations_value.copy()
  relocations.push(relocation)
  { ..self, relocations_value: relocations }
}

///|
pub fn Image::add_external_reference(
  self : Image,
  reference : ExternalReference,
) -> Image {
  let references = self.external_references_value.copy()
  references.push(reference)
  { ..self, external_references_value: references }
}

///|
pub fn Image::add_required_library(self : Image, name : String) -> Image {
  let libraries = self.required_libraries_value.copy()
  libraries.push(name)
  { ..self, required_libraries_value: libraries }
}

///|
pub fn Image::add_rpath(self : Image, path : String) -> Image {
  let paths = self.rpaths_value.copy()
  paths.push(path)
  { ..self, rpaths_value: paths }
}

///|
pub fn Image::add_runpath(self : Image, path : String) -> Image {
  let paths = self.runpaths_value.copy()
  paths.push(path)
  { ..self, runpaths_value: paths }
}

///|
pub fn Image::add_symbol_value(
  self : Image,
  symbol_value : SymbolValue,
) -> Image {
  let values = self.symbol_values_value.copy()
  values.push(symbol_value)
  { ..self, symbol_values_value: values }
}

///|
pub fn Image::with_load_bias(self : Image, load_bias : Int64) -> Image {
  { ..self, load_bias_value: Some(load_bias) }
}

///|
pub fn Image::with_interpreter(self : Image, interpreter : String) -> Image {
  { ..self, interpreter_value: Some(interpreter) }
}

///|
pub fn Image::with_soname(self : Image, soname : String) -> Image {
  { ..self, soname_value: Some(soname) }
}

///|
pub fn Image::with_is_executable(self : Image, is_executable : Bool) -> Image {
  { ..self, is_executable_value: Some(is_executable) }
}

///|
pub fn Image::with_base_address(self : Image, base_address : UInt64) -> Image {
  { ..self, base_address_value: Some(base_address) }
}
