///|
struct ProjectSymbolizer {
  path_value : String?
  biased_flag : Bool
  find_fn : (UInt64) -> String?
}

///|
fn project_symbolizer_addr(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16)
}

///|
fn project_symbolizer_find_name(names : Array[String], name : String) -> Int? {
  for i in 0..<names.length() {
    if names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
fn project_symbolizer_is_ambiguous(
  pairs : Array[(UInt64, String)],
  addr : UInt64,
  name : String,
) -> Bool {
  pairs.any(item => item.0 == addr && item.1 != name) ||
  pairs.any(item => item.1 == name && item.0 != addr)
}

///|
fn project_symbolizer_saturated_pairs(
  pairs : Array[(UInt64, String)],
) -> Array[(UInt64, String)] {
  let result : Array[(UInt64, String)] = []
  for pair in pairs {
    if !ProjectSymbolizer::name_is_empty(pair.1) &&
      !project_symbolizer_is_ambiguous(pairs, pair.0, pair.1) &&
      !result.any(item => item.0 == pair.0 && item.1 == pair.1) {
      result.push(pair)
    }
  }
  result
}

///|
fn project_symbolizer_find_pair(
  pairs : Array[(UInt64, String)],
  addr : UInt64,
) -> String? {
  for pair in pairs {
    if pair.0 == addr {
      return Some(pair.1)
    }
  }
  None
}

///|
pub fn ProjectSymbolizer::create(
  find : (UInt64) -> String?,
  path? : String,
  biased? : Bool = false,
) -> ProjectSymbolizer {
  { path_value: path, biased_flag: biased, find_fn: find }
}

///|
pub fn ProjectSymbolizer::empty() -> ProjectSymbolizer {
  ProjectSymbolizer::create(_ => None)
}

///|
pub fn ProjectSymbolizer::name_of_addr(addr : UInt64) -> String {
  "sub_" + project_symbolizer_addr(addr)
}

///|
pub fn ProjectSymbolizer::name_is_empty(name : String) -> Bool {
  name.has_prefix("sub_")
}

///|
pub fn ProjectSymbolizer::path(self : ProjectSymbolizer) -> String? {
  self.path_value
}

///|
pub fn ProjectSymbolizer::is_biased(self : ProjectSymbolizer) -> Bool {
  self.biased_flag
}

///|
pub fn ProjectSymbolizer::set_path(
  self : ProjectSymbolizer,
  path : String,
) -> ProjectSymbolizer {
  { ..self, path_value: Some(path) }
}

///|
pub fn ProjectSymbolizer::run(
  self : ProjectSymbolizer,
  addr : UInt64,
) -> String? {
  (self.find_fn)(addr)
}

///|
pub fn ProjectSymbolizer::resolve(
  self : ProjectSymbolizer,
  addr : UInt64,
) -> String {
  match self.run(addr) {
    Some(name) => name
    None => ProjectSymbolizer::name_of_addr(addr)
  }
}

///|
pub fn ProjectSymbolizer::chain(
  symbolizers : Array[ProjectSymbolizer],
) -> ProjectSymbolizer {
  ProjectSymbolizer::create(addr => {
    for symbolizer in symbolizers {
      match symbolizer.run(addr) {
        Some(name) => return Some(name)
        None => ()
      }
    }
    None
  })
}

///|
pub fn ProjectSymbolizer::of_image(image : @image.Image) -> ProjectSymbolizer {
  let pairs : Array[(UInt64, String)] = [
    for symbol in image.symbols() => (symbol.addr(), symbol.name())
  ]
  let saturated = project_symbolizer_saturated_pairs(pairs)
  ProjectSymbolizer::create(
    addr => project_symbolizer_find_pair(saturated, addr),
    path?=image.filename(),
    biased=true,
  )
}

///|
pub fn ProjectSymbolizer::of_blocks(
  blocks : Array[(String, UInt64, UInt64)],
) -> ProjectSymbolizer {
  let names : Array[String] = []
  let starts : Array[UInt64] = []
  for block in blocks {
    let name = block.0
    let start = block.1
    match project_symbolizer_find_name(names, name) {
      Some(index) => if start < starts[index] { starts[index] = start }
      None => {
        names.push(name)
        starts.push(start)
      }
    }
  }
  let pairs : Array[(UInt64, String)] = []
  for i in 0..<names.length() {
    pairs.push((starts[i], names[i]))
  }
  let saturated = project_symbolizer_saturated_pairs(pairs)
  ProjectSymbolizer::create(addr => {
    project_symbolizer_find_pair(saturated, addr)
  })
}
