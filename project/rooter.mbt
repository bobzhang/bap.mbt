///|
struct ProjectRooter {
  path_value : String?
  roots_value : Array[UInt64]
  biased_flag : Bool
}

///|
fn project_rooter_dedup_roots(roots : Array[UInt64]) -> Array[UInt64] {
  let result = []
  for root in roots {
    if !result.contains(root) {
      result.push(root)
    }
  }
  result
}

///|
fn project_rooter_find_name(names : Array[String], name : String) -> Int? {
  for i in 0..<names.length() {
    if names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
pub fn ProjectRooter::create(
  roots : Array[UInt64],
  path? : String,
  biased? : Bool = false,
) -> ProjectRooter {
  {
    path_value: path,
    roots_value: project_rooter_dedup_roots(roots),
    biased_flag: biased,
  }
}

///|
pub fn ProjectRooter::empty() -> ProjectRooter {
  ProjectRooter::create([])
}

///|
pub fn ProjectRooter::roots(self : ProjectRooter) -> Array[UInt64] {
  self.roots_value.copy()
}

///|
pub fn ProjectRooter::path(self : ProjectRooter) -> String? {
  self.path_value
}

///|
pub fn ProjectRooter::is_biased(self : ProjectRooter) -> Bool {
  self.biased_flag
}

///|
pub fn ProjectRooter::set_path(
  self : ProjectRooter,
  path : String,
) -> ProjectRooter {
  { ..self, path_value: Some(path) }
}

///|
pub fn ProjectRooter::contains(self : ProjectRooter, root : UInt64) -> Bool {
  self.roots_value.contains(root)
}

///|
pub fn ProjectRooter::union(
  self : ProjectRooter,
  other : ProjectRooter,
) -> ProjectRooter {
  let roots = self.roots_value.copy()
  for root in other.roots_value {
    if !roots.contains(root) {
      roots.push(root)
    }
  }
  {
    path_value: match self.path_value {
      Some(_) => self.path_value
      None => other.path_value
    },
    roots_value: roots,
    biased_flag: self.biased_flag || other.biased_flag,
  }
}

///|
pub fn ProjectRooter::of_symbols(
  symbols : Array[@image.Symbol],
  entry? : UInt64,
  path? : String,
  biased? : Bool = false,
) -> ProjectRooter {
  let roots : Array[UInt64] = []
  match entry {
    Some(addr) => roots.push(addr)
    None => ()
  }
  for symbol in symbols {
    roots.push(symbol.addr())
  }
  ProjectRooter::create(roots, path?, biased~)
}

///|
pub fn ProjectRooter::of_image(image : @image.Image) -> ProjectRooter {
  ProjectRooter::of_symbols(
    image.symbols(),
    entry=image.entry_point(),
    path?=image.filename(),
    biased=true,
  )
}

///|
pub fn ProjectRooter::of_blocks(
  blocks : Array[(String, UInt64, UInt64)],
) -> ProjectRooter {
  let names : Array[String] = []
  let starts : Array[UInt64] = []
  for block in blocks {
    let name = block.0
    let start = block.1
    match project_rooter_find_name(names, name) {
      Some(index) => if start < starts[index] { starts[index] = start }
      None => {
        names.push(name)
        starts.push(start)
      }
    }
  }
  ProjectRooter::create(starts)
}

///|
pub fn ProjectRooter::image_blocks(
  self : ProjectRooter,
  image : @image.Image,
) -> Result[Array[@memory.Memory], String] {
  let blocks : Array[@memory.Memory] = []
  for root in self.roots_value {
    let mut matched = false
    for segment in image.segments() {
      if !matched && segment.contains(root) {
        match segment.memory().view(from=root) {
          Ok(block) => {
            if block.length() > 0 {
              blocks.push(block)
            }
            matched = true
          }
          Err(reason) => return Err(reason)
        }
      }
    }
  }
  Ok(blocks)
}

///|
pub fn Project::rooter(self : Project) -> ProjectRooter {
  let biased = match self.image_value {
    Some(_) => true
    None => false
  }
  match self.image_value {
    Some(image) =>
      ProjectRooter::of_symbols(
        self.symbols_value,
        entry=image.entry_point(),
        path?=self.filename_value,
        biased~,
      )
    None =>
      ProjectRooter::of_symbols(
        self.symbols_value,
        path?=self.filename_value,
        biased~,
      )
  }
}
