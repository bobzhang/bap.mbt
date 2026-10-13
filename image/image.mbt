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
  loader_facts_value : OgreDoc?
}

///|
pub(all) suberror ImageLookupError {
  MissingImageSegment(String, UInt64)
  MissingImageSymbolMemory(String, UInt64, Int32)
} derive(Eq, Debug)

///|
pub extend ImageLookupError with Eq::{not_equal, equal}

///|
pub extend ImageLookupError with Debug::{to_repr}

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
    loader_facts_value: None,
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
        None =>
          match find_loader(name) {
            Some(loader) => Image::of_bytes_with_loader(data, name, loader)
            None => Err("unknown image backend or loader \{name}")
          }
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
///
/// Images created from an Ogre document return that document. Images built
/// directly from metadata (ELF, raw and legacy backends, `Image::create`)
/// describe themselves with the facts upstream's legacy loaders provide:
/// target, entry point, segments, sections and function symbols.
pub fn Image::spec(self : Image) -> OgreDoc {
  match self.spec_value {
    Some(doc) => doc
    None =>
      match Spec::of_image(self) {
        Ok(doc) =>
          match self.loader_facts_value {
            Some(facts) => doc.merge(facts) catch { _ => doc }
            None => doc
          }
        Err(_) => Spec::from_arch(self.arch())
      }
  }
}

///|
/// Attaches the facts a file loader extracted besides the image metadata
/// (upstream loaders put them in the image specification, e.g. the
/// `llvm:elf-program-header` facts); they are merged into the
/// specification derived from the image.
fn Image::with_loader_facts(self : Image, facts : OgreDoc?) -> Image {
  { ..self, loader_facts_value: facts, }
}

///|
pub fn Image::addr_size(self : Image) -> Int32 {
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
/// The memory of the image annotated with typed values (upstream
/// `Image.memory`).
///
/// Following upstream `from_spec`, the map contains, in this order:
/// - every segment, tagged with `segment()`;
/// - every mapped location of every symbol, tagged with its name
///   (`symbol()`) and the symbol itself (`symbol_info()`); a symbol with an
///   unmapped location is skipped entirely;
/// - every mapped section, tagged with its name (`section()`);
/// - every code region of the image specification, tagged with
///   `code_region()`.
///
/// Values are projected back with `Value::get`, e.g.
/// `value.get(@image.section())`. `Image::segment_names` keeps the former
/// segment-name view.
pub fn Image::memory(self : Image) -> @memory.MemMap[@types.Value] {
  let mut map = @memory.MemMap::empty()
  for segment in self.segments_value {
    map = map.add(segment.memory(), @types.Value::create(segment_tag, segment))
  }
  for symbol in self.symbols_value {
    match self.symbol_memory_chunks(symbol) {
      Some(chunks) =>
        for chunk in chunks {
          map = map
            .add(chunk, @types.Value::create(symbol_tag, symbol.name()))
            .add(chunk, @types.Value::create(symbol_info_tag, symbol))
        }
      None => ()
    }
  }
  for section in self.sections_value {
    match self.memory_of_section(section) {
      Some(memory) =>
        map = map.add(memory, @types.Value::create(section_tag, section.name()))
      None => ()
    }
  }
  match self.spec_value {
    Some(doc) =>
      for code in spec_values(doc, Scheme::code_region()) {
        match self.code_region_memory(code) {
          Some(memory) =>
            map = map.add(memory, @types.Value::create(code_region_tag, ()))
          None => ()
        }
      }
    None => ()
  }
  map
}

///|
/// The memory of a code region `(addr, size, off)` of the specification
/// (upstream `map_region`): a view of the segment that maps it, or the
/// region's file bytes when no segment covers it.
fn Image::code_region_memory(
  self : Image,
  code : (Int64, Int64, Int64),
) -> @memory.Memory? {
  let (addr, size, off) = code
  if addr < 0L || size <= 0L || size > 0x7fffffffL {
    return None
  }
  let addr = addr.reinterpret_as_uint64()
  let size = size.to_int()
  match
    self.segments_value.search_by(segment => {
      segment.contains(addr) && segment.contains(addr + size.to_uint64() - 1UL)
    }) {
    Some(i) =>
      self.segments_value[i].memory().view(from=addr, words=size).to_option()
    None => {
      if off < 0L || off + size.to_int64() > self.data_value.length().to_int64() {
        return None
      }
      @memory.Memory::create(
        endian=self.endian_value,
        start=addr,
        self.data_value,
        pos=off.to_int(),
        len=size,
      ).to_option()
    }
  }
}

///|
/// The memory of the image annotated with segment names (the former
/// string-valued `Image.memory` projection, kept for string-tagged memory
/// maps such as the project memory).
pub fn Image::segment_names(self : Image) -> @memory.MemMap[String] {
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
pub fn Image::segment_of_symbol_exn(
  self : Image,
  symbol : Symbol,
) -> Segment raise ImageLookupError {
  match self.segment_of_symbol(symbol) {
    Some(segment) => segment
    None => raise MissingImageSegment(symbol.name(), symbol.addr())
  }
}

///|
pub fn Image::symbols_of_segment(
  self : Image,
  segment : Segment,
) -> Array[Symbol] {
  self.symbols_value.filter(symbol => {
    symbol.locations().any(location => segment.contains(location.0))
  })
}

///|
fn min_int(lhs : Int32, rhs : Int32) -> Int32 {
  if lhs < rhs {
    lhs
  } else {
    rhs
  }
}

///|
fn Image::memory_chunks_at(
  self : Image,
  addr : UInt64,
  size : Int32,
) -> Array[@memory.Memory]? {
  let size = if size <= 0 { 1 } else { size }
  let chunks = []
  let mut current = addr
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
fn Image::symbol_memory_chunks(
  self : Image,
  symbol : Symbol,
) -> Array[@memory.Memory]? {
  let chunks = []
  for location in symbol.locations() {
    match self.memory_chunks_at(location.0, location.1) {
      Some(items) =>
        for item in items {
          chunks.push(item)
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
pub fn Image::memories_of_symbol_exn(
  self : Image,
  symbol : Symbol,
) -> Array[@memory.Memory] raise ImageLookupError {
  match self.memories_of_symbol(symbol) {
    Some(memories) => memories
    None =>
      raise MissingImageSymbolMemory(
        symbol.name(),
        symbol.addr(),
        symbol.size(),
      )
  }
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
pub fn Image::memory_of_symbol_exn(
  self : Image,
  symbol : Symbol,
) -> (@memory.Memory, Array[@memory.Memory]) raise ImageLookupError {
  match self.memory_of_symbol(symbol) {
    Some(memory) => memory
    None =>
      raise MissingImageSymbolMemory(
        symbol.name(),
        symbol.addr(),
        symbol.size(),
      )
  }
}

///|
fn image_relocation_word(
  width : Int32,
  value : UInt64,
) -> Result[@types.Word, String] {
  try @types.Word::of_uint64(width~, value) catch {
    _ => Err("failed to build relocation word")
  } noraise {
    word => Ok(word)
  }
}

///|
fn image_relocation_word_value(word : @types.Word) -> Result[UInt64, String] {
  try word.to_uint64() catch {
    _ => Err("failed to read relocation word")
  } noraise {
    value => Ok(value)
  }
}

///|
fn image_memory_covers_word(
  memory : @memory.Memory,
  addr : UInt64,
  width : Int32,
) -> Bool {
  let bytes = width / 8
  bytes > 0 &&
  memory.contains(addr) &&
  memory.contains(addr + (bytes - 1).to_uint64())
}

///|
fn image_relocation_memory_addend(
  relocation : Relocation,
  width : Int32,
  memory : @memory.Memory,
) -> Result[UInt64, String] {
  match memory.load(relocation.fixup(), width~) {
    Ok(word) => image_relocation_word_value(word)
    Err(reason) => Err(reason)
  }
}

///|
fn image_relocation_addend_value(
  relocation : Relocation,
  width : Int32,
  memory : @memory.Memory,
  fallback_to_memory~ : Bool,
) -> Result[UInt64, String] {
  match relocation.addend() {
    Some(addend) => Ok(addend.reinterpret_as_uint64())
    None =>
      if relocation.uses_memory_addend() || fallback_to_memory {
        image_relocation_memory_addend(relocation, width, memory)
      } else {
        Ok(0UL)
      }
  }
}

///|
fn Image::relocation_value(
  self : Image,
  relocation : Relocation,
  width : Int32,
  memory : @memory.Memory,
) -> Result[@types.Word?, String] {
  if relocation.is_relative() {
    match self.base_address_value {
      Some(base) => {
        let addend = match
          image_relocation_addend_value(
            relocation,
            width,
            memory,
            fallback_to_memory=true,
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        match image_relocation_word(width, base + addend) {
          Ok(word) => Ok(Some(word))
          Err(reason) => Err(reason)
        }
      }
      None => Err("relative relocation requires a base address")
    }
  } else {
    match relocation.target() {
      Some(target) => {
        let addend = match
          image_relocation_addend_value(
            relocation,
            width,
            memory,
            fallback_to_memory=false,
          ) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        match image_relocation_word(width, target + addend) {
          Ok(word) => Ok(Some(word))
          Err(reason) => Err(reason)
        }
      }
      None => Ok(None)
    }
  }
}

///|
fn Image::apply_relocation_to_segments(
  self : Image,
  segments : Array[Segment],
  relocation : Relocation,
  width : Int32,
) -> Result[Unit, String] {
  for i in 0..<segments.length() {
    let memory = segments[i].memory()
    if image_memory_covers_word(memory, relocation.fixup(), width) {
      match self.relocation_value(relocation, width, memory) {
        Ok(Some(word)) =>
          match memory.store(relocation.fixup(), word) {
            Ok(updated) => {
              segments[i] = segments[i].with_memory(updated)
              return Ok(())
            }
            Err(reason) => return Err(reason)
          }
        Ok(None) => return Ok(())
        Err(reason) => return Err(reason)
      }
    }
  }
  Err("relocation fixup is outside image memory")
}

///|
pub fn Image::with_applied_relocations(self : Image) -> Result[Image, String] {
  let width = self.addr_size()
  if width <= 0 || width % 8 != 0 {
    return Err("image address size must be a positive multiple of 8")
  }
  let segments = self.segments_value.copy()
  for relocation in self.relocations_value {
    match self.apply_relocation_to_segments(segments, relocation, width) {
      Ok(_) => ()
      Err(reason) => return Err(reason)
    }
  }
  Ok({ ..self, segments_value: segments, })
}

///|
pub fn Image::words(
  self : Image,
  word_size~ : Int32,
) -> @memory.MemMap[@types.Word] {
  let bytes_per_word = word_size / 8
  let mut map = @memory.MemMap::empty()
  if word_size > 0 && word_size % 8 == 0 {
    for segment in self.segments_value {
      let memory = segment.memory()
      let count = memory.length() / bytes_per_word
      for i in 0..<count {
        let addr = memory.min_addr() + (i * bytes_per_word).to_uint64()
        match memory.view(from=addr, words=1, word_size~) {
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
  { ..self, segments_value: segments, }
}

///|
pub fn Image::add_section(self : Image, section : Section) -> Image {
  let sections = self.sections_value.copy()
  sections.push(section)
  { ..self, sections_value: sections, }
}

///|
pub fn Image::add_symbol(self : Image, symbol : Symbol) -> Image {
  let symbols = self.symbols_value.copy()
  symbols.push(symbol)
  { ..self, symbols_value: symbols, }
}

///|
pub fn Image::add_relocation(self : Image, relocation : Relocation) -> Image {
  let relocations = self.relocations_value.copy()
  relocations.push(relocation)
  { ..self, relocations_value: relocations, }
}

///|
pub fn Image::add_external_reference(
  self : Image,
  reference : ExternalReference,
) -> Image {
  let references = self.external_references_value.copy()
  references.push(reference)
  { ..self, external_references_value: references, }
}

///|
pub fn Image::add_required_library(self : Image, name : String) -> Image {
  let libraries = self.required_libraries_value.copy()
  libraries.push(name)
  { ..self, required_libraries_value: libraries, }
}

///|
pub fn Image::add_rpath(self : Image, path : String) -> Image {
  let paths = self.rpaths_value.copy()
  paths.push(path)
  { ..self, rpaths_value: paths, }
}

///|
pub fn Image::add_runpath(self : Image, path : String) -> Image {
  let paths = self.runpaths_value.copy()
  paths.push(path)
  { ..self, runpaths_value: paths, }
}

///|
pub fn Image::add_symbol_value(
  self : Image,
  symbol_value : SymbolValue,
) -> Image {
  let values = self.symbol_values_value.copy()
  values.push(symbol_value)
  { ..self, symbol_values_value: values, }
}

///|
pub fn Image::with_load_bias(self : Image, load_bias : Int64) -> Image {
  { ..self, load_bias_value: Some(load_bias), }
}

///|
pub fn Image::with_interpreter(self : Image, interpreter : String) -> Image {
  { ..self, interpreter_value: Some(interpreter), }
}

///|
pub fn Image::with_soname(self : Image, soname : String) -> Image {
  { ..self, soname_value: Some(soname), }
}

///|
pub fn Image::with_is_executable(self : Image, is_executable : Bool) -> Image {
  { ..self, is_executable_value: Some(is_executable), }
}

///|
pub fn Image::with_base_address(self : Image, base_address : UInt64) -> Image {
  { ..self, base_address_value: Some(base_address), }
}
