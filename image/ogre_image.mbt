///|
fn ogre_fact_string(fact : OgreFact, field : String) -> Result[String, String] {
  match fact.value(field) {
    Some(value) => Ok(value)
    None => Err("Ogre fact \{fact.attribute()} is missing field \{field}")
  }
}

///|
fn ogre_fact_int64(fact : OgreFact, field : String) -> Result[Int64, String] {
  match ogre_fact_string(fact, field) {
    Err(reason) => Err(reason)
    Ok(text) => {
      let value : Int64 = try @string.from_str(text) catch {
        _ =>
          return Err(
            "Ogre field \{fact.attribute()}.\{field} is not an integer: \{text}",
          )
      } noraise {
        value => value
      }
      Ok(value)
    }
  }
}

///|
fn ogre_int64_as_uint64(
  value : Int64,
  field : String,
) -> Result[UInt64, String] {
  if value < 0L {
    Err("Ogre field \{field} must be non-negative")
  } else {
    Ok(value.reinterpret_as_uint64())
  }
}

///|
fn ogre_int64_as_int(value : Int64, field : String) -> Result[Int, String] {
  if value < 0L || value > 2147483647L {
    Err("Ogre field \{field} is out of Int range")
  } else {
    Ok(value.to_int())
  }
}

///|
fn ogre_fact_uint64(fact : OgreFact, field : String) -> Result[UInt64, String] {
  match ogre_fact_int64(fact, field) {
    Ok(value) => ogre_int64_as_uint64(value, "\{fact.attribute()}.\{field}")
    Err(reason) => Err(reason)
  }
}

///|
fn ogre_fact_int(fact : OgreFact, field : String) -> Result[Int, String] {
  match ogre_fact_int64(fact, field) {
    Ok(value) => ogre_int64_as_int(value, "\{fact.attribute()}.\{field}")
    Err(reason) => Err(reason)
  }
}

///|
fn ogre_fact_bool(fact : OgreFact, field : String) -> Result[Bool, String] {
  match ogre_fact_string(fact, field) {
    Ok("true") => Ok(true)
    Ok("false") => Ok(false)
    Ok(text) =>
      Err("Ogre field \{fact.attribute()}.\{field} is not a bool: \{text}")
    Err(reason) => Err(reason)
  }
}

///|
fn ogre_fact_region(fact : OgreFact) -> Result[(UInt64, Int), String] {
  match ogre_fact_uint64(fact, "addr") {
    Err(reason) => Err(reason)
    Ok(addr) =>
      match ogre_fact_int(fact, "size") {
        Ok(size) => Ok((addr, size))
        Err(reason) => Err(reason)
      }
  }
}

///|
fn ogre_fact_has_region(fact : OgreFact, addr : UInt64, size : Int) -> Bool {
  match ogre_fact_region(fact) {
    Ok((other_addr, other_size)) => other_addr == addr && other_size == size
    Err(_) => false
  }
}

///|
fn OgreDoc::find_named_region(
  self : OgreDoc,
  addr : UInt64,
  size : Int,
) -> String? {
  for fact in self.facts("named-region") {
    if ogre_fact_has_region(fact, addr, size) {
      match fact.value("name") {
        Some(name) => return Some(name)
        None => ()
      }
    }
  }
  None
}

///|
fn OgreDoc::find_named_region_at(self : OgreDoc, addr : UInt64) -> String? {
  for fact in self.facts("named-region") {
    match ogre_fact_uint64(fact, "addr") {
      Ok(other_addr) if other_addr == addr =>
        match fact.value("name") {
          Some(name) => return Some(name)
          None => ()
        }
      _ => ()
    }
  }
  None
}

///|
fn OgreDoc::find_mapped_region(
  self : OgreDoc,
  addr : UInt64,
  size : Int,
) -> (Int, Int)? {
  for fact in self.facts("mapped") {
    if ogre_fact_has_region(fact, addr, size) {
      match ogre_fact_int(fact, "off") {
        Ok(off) => return Some((off, size))
        Err(_) => ()
      }
    }
  }
  None
}

///|
fn OgreDoc::request_bool(
  self : OgreDoc,
  attribute : String,
  field : String,
) -> Bool? {
  match self.facts(attribute) {
    [fact, ..] =>
      match ogre_fact_bool(fact, field) {
        Ok(value) => Some(value)
        Err(_) => None
      }
    [] => None
  }
}

///|
fn OgreDoc::request_uint64(
  self : OgreDoc,
  attribute : String,
  field : String,
) -> Result[UInt64, String] {
  match self.facts(attribute) {
    [fact, ..] => ogre_fact_uint64(fact, field)
    [] => Err("Ogre image spec is missing required attribute \{attribute}")
  }
}

///|
fn OgreDoc::request_string(
  self : OgreDoc,
  attribute : String,
  field : String,
) -> String? {
  match self.facts(attribute) {
    [fact, ..] => fact.value(field)
    [] => None
  }
}

///|
fn ogre_target_endian(target : @core_theory.Target) -> @bitvec.Endian {
  match target.endianness() {
    LittleEndian => LittleEndian
    _ => BigEndian
  }
}

///|
fn OgreDoc::target(self : OgreDoc) -> @core_theory.Target {
  let mut target = match self.request_string("arch", "name") {
    Some(name) =>
      match @core_theory.find_target(name) {
        Some(target) => target
        None => @core_theory.Target::unknown()
      }
    None => @core_theory.Target::unknown()
  }
  match self.facts("bits") {
    [fact, ..] =>
      match ogre_fact_int(fact, "size") {
        Ok(bits) => target = target.with_bits(bits)
        Err(_) => ()
      }
    [] => ()
  }
  match self.request_bool("is-little-endian", "flag") {
    Some(true) => target = target.with_endianness(LittleEndian)
    Some(false) => target = target.with_endianness(BigEndian)
    None => ()
  }
  match self.request_string("system", "name") {
    Some(name) =>
      match @core_theory.System::of_string(name) {
        Some(system) => target = target.with_system(system)
        None => ()
      }
    None => ()
  }
  match self.request_string("abi", "name") {
    Some(name) =>
      match @core_theory.Abi::of_string(name) {
        Some(abi) => target = target.with_abi(abi)
        None => ()
      }
    None => ()
  }
  match self.request_string("format", "name") {
    Some(name) =>
      match @core_theory.Filetype::of_string(name) {
        Some(filetype) => target = target.with_filetype(filetype)
        None => ()
      }
    None => ()
  }
  target
}

///|
fn OgreDoc::image_endian(
  self : OgreDoc,
  target : @core_theory.Target,
) -> @bitvec.Endian {
  match self.request_bool("is-little-endian", "flag") {
    Some(true) => LittleEndian
    Some(false) => BigEndian
    None => ogre_target_endian(target)
  }
}

///|
fn ogre_slice_data(
  data : Bytes,
  off : Int,
  len : Int,
  description : String,
) -> Result[Bytes, String] {
  if off < 0 || len < 0 || off > data.length() || len > data.length() - off {
    Err("Ogre region \{description} is outside image data")
  } else {
    Ok(data[off:off + len].to_owned())
  }
}

///|
fn region_max_addr(addr : UInt64, size : Int) -> UInt64 {
  if size <= 0 {
    addr
  } else {
    addr + (size - 1).to_uint64()
  }
}

///|
fn segments_cover_region(
  segments : Array[Segment],
  addr : UInt64,
  size : Int,
) -> Bool {
  if size <= 0 {
    false
  } else {
    let max_addr = region_max_addr(addr, size)
    segments.any(segment => segment.contains(addr) && segment.contains(max_addr))
  }
}

///|
fn OgreDoc::add_code_region_segments(
  self : OgreDoc,
  data : Bytes,
  endian : @bitvec.Endian,
  segments : Array[Segment],
  warnings : Array[String],
) -> Result[Unit, String] {
  for fact in self.facts("code-region") {
    match ogre_fact_region(fact) {
      Err(reason) => return Err(reason)
      Ok((addr, size)) =>
        if !segments_cover_region(segments, addr, size) {
          let off = match ogre_fact_int(fact, "off") {
            Ok(off) => off
            Err(reason) => return Err(reason)
          }
          match self.find_named_region_at(addr) {
            Some(name) =>
              match ogre_slice_data(data, off, size, "\{name}@\{addr}") {
                Ok(bytes) =>
                  segments.push(
                    Segment::create(
                      name~,
                      endian~,
                      addr~,
                      bytes,
                      offset=off,
                      readable=true,
                      writable=false,
                      executable=true,
                    ),
                  )
                Err(reason) => warnings.push(reason)
              }
            None =>
              warnings.push("Ogre code region at \{addr}+\{size} is unnamed")
          }
        }
    }
  }
  Ok(())
}

///|
fn OgreDoc::image_segments(
  self : OgreDoc,
  data : Bytes,
  endian : @bitvec.Endian,
  warnings : Array[String],
) -> Result[Array[Segment], String] {
  let segments = []
  for fact in self.facts("segment") {
    match ogre_fact_region(fact) {
      Err(reason) => return Err(reason)
      Ok((addr, size)) => {
        let r = match ogre_fact_bool(fact, "r") {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        let w = match ogre_fact_bool(fact, "w") {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        let x = match ogre_fact_bool(fact, "x") {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
        match
          (
            self.find_mapped_region(addr, size),
            self.find_named_region(addr, size),
          ) {
          (Some((off, len)), Some(name)) =>
            match ogre_slice_data(data, off, len, "\{name}@\{addr}") {
              Ok(bytes) =>
                segments.push(
                  Segment::create(
                    name~,
                    endian~,
                    addr~,
                    bytes,
                    offset=off,
                    readable=r,
                    writable=w,
                    executable=x,
                  ),
                )
              Err(reason) => warnings.push(reason)
            }
          _ => warnings.push("Ogre segment at \{addr}+\{size} is not mapped")
        }
      }
    }
  }
  match self.add_code_region_segments(data, endian, segments, warnings) {
    Ok(_) => Ok(segments)
    Err(reason) => Err(reason)
  }
}

///|
fn OgreDoc::image_sections(
  self : OgreDoc,
  warnings : Array[String],
) -> Result[Array[Section], String] {
  let sections = []
  for fact in self.facts("section") {
    match ogre_fact_region(fact) {
      Err(reason) => return Err(reason)
      Ok((addr, size)) =>
        match self.find_named_region(addr, size) {
          Some(name) => sections.push(Section::create(name~, addr~, size~))
          None => warnings.push("Ogre section at \{addr}+\{size} is unnamed")
        }
    }
  }
  Ok(sections)
}

///|
fn OgreDoc::symbol_name(self : OgreDoc, addr : UInt64) -> String? {
  let mut name : String? = None
  for fact in self.facts("named-symbol") {
    match ogre_fact_uint64(fact, "addr") {
      Ok(symbol_addr) if symbol_addr == addr =>
        match fact.value("name") {
          Some(candidate) =>
            match name {
              Some(existing) if existing.length() > candidate.length() => ()
              _ => name = Some(candidate)
            }
          None => ()
        }
      _ => ()
    }
  }
  name
}

///|
fn OgreDoc::symbol_size(self : OgreDoc, root : UInt64) -> Int {
  for fact in self.facts("symbol-chunk") {
    match ogre_fact_uint64(fact, "root") {
      Ok(chunk_root) if chunk_root == root =>
        match (ogre_fact_uint64(fact, "addr"), ogre_fact_int(fact, "size")) {
          (Ok(addr), Ok(size)) if addr == root => return size
          _ => ()
        }
      _ => ()
    }
  }
  1
}

///|
fn OgreDoc::image_symbols(self : OgreDoc) -> Result[Array[Symbol], String] {
  let symbols = []
  for fact in self.facts("code-start") {
    match ogre_fact_uint64(fact, "addr") {
      Err(reason) => return Err(reason)
      Ok(addr) =>
        match self.symbol_name(addr) {
          Some(name) =>
            symbols.push(
              Symbol::create(
                name~,
                addr~,
                size=self.symbol_size(addr),
                is_function=true,
              ),
            )
          None => ()
        }
    }
  }
  Ok(symbols)
}

///|
pub fn Image::from_ogre(
  data : Bytes,
  doc : OgreDoc,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  match doc.request_uint64("entry-point", "addr") {
    Err(reason) => Err(reason)
    Ok(entry) => {
      let selected_target = match target {
        Some(value) => value
        None => doc.target()
      }
      let endian = doc.image_endian(selected_target)
      let warnings = []
      match doc.image_segments(data, endian, warnings) {
        Err(reason) => Err(reason)
        Ok(segments) =>
          match doc.image_sections(warnings) {
            Err(reason) => Err(reason)
            Ok(sections) =>
              match doc.image_symbols() {
                Err(reason) => Err(reason)
                Ok(symbols) =>
                  Ok(
                    (
                      Image::from_segments(
                        entry~,
                        endian~,
                        segments,
                        sections~,
                        symbols~,
                        filename?,
                        target=selected_target,
                      ),
                      warnings,
                    ),
                  )
              }
          }
      }
    }
  }
}

///|
pub fn Image::of_ogre_string(
  data : Bytes,
  spec : String,
  filename? : String,
  target? : @core_theory.Target,
) -> Result[(Image, Array[String]), String] {
  match OgreDoc::from_string(spec) {
    Ok(doc) => Image::from_ogre(data, doc, filename?, target?)
    Err(reason) => Err(reason)
  }
}
