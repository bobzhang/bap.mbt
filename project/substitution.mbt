///|
fn project_subst_is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn project_subst_is_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn project_subst_is_ident(c : Char) -> Bool {
  project_subst_is_alpha(c) || project_subst_is_digit(c) || c == '_'
}

///|
fn project_subst_addr(addr : UInt64) -> String {
  "0x" + addr.to_string(radix=16)
}

///|
fn project_subst_memory_addr(memory : @memory.Memory, bound : String) -> String {
  match bound {
    "max" => project_subst_addr(memory.max_addr())
    _ => project_subst_addr(memory.min_addr())
  }
}

///|
fn Project::subst_find_section(
  self : Project,
  memory : @memory.Memory,
) -> (@memory.Memory, String)? {
  match self.image_value {
    Some(image) =>
      for section in image.sections() {
        match image.memory_of_section(section) {
          Some(section_memory) if section_memory.dominates(memory) =>
            return Some((section_memory, section.name()))
          _ => ()
        }
      }
    None => ()
  }
  match self.memory_value.dominators(memory) {
    [(section_memory, name), ..] => Some((section_memory, name))
    _ => None
  }
}

///|
fn Project::subst_find_symbol(
  self : Project,
  memory : @memory.Memory,
) -> @image.Symbol? {
  for symbol in self.symbols_value {
    if symbol.contains(memory.min_addr()) {
      return Some(symbol)
    }
  }
  None
}

///|
fn project_subst_symbol_addr(symbol : @image.Symbol, bound : String) -> String {
  let max_addr = if symbol.size() <= 0 {
    symbol.addr()
  } else {
    symbol.addr() + (symbol.size() - 1).to_uint64()
  }
  match bound {
    "max" => project_subst_addr(max_addr)
    _ => project_subst_addr(symbol.addr())
  }
}

///|
fn Project::subst_find_block(
  self : Project,
  memory : @memory.Memory,
) -> @memory.Memory? {
  for block in self.state_value.disassembly().blocks() {
    if block.dominates(memory) {
      return Some(block)
    }
  }
  None
}

///|
fn Project::subst_find_instruction(
  self : Project,
  memory : @memory.Memory,
) -> ProjectDisassemblyInstruction? {
  for instruction in self.state_value.disassembly().instructions() {
    if instruction.memory().dominates(memory) {
      return Some(instruction)
    }
  }
  None
}

///|
fn Project::subst_disassembly_text(
  self : Project,
  memory : @memory.Memory,
  name : String,
) -> String {
  match self.subst_find_instruction(memory) {
    Some(instruction) =>
      match name {
        "asm" => instruction.assembly()
        "bil" => instruction.bil()
        _ => name
      }
    None => "<disassembly unavailable>"
  }
}

///|
fn Project::subst_value(
  self : Project,
  memory : @memory.Memory,
  name : String,
) -> String {
  match name {
    "filename" =>
      match self.filename_value {
        Some(filename) => filename
        None => name
      }
    "section" | "section_name" =>
      match self.subst_find_section(memory) {
        Some((_, section_name)) => section_name
        None => name
      }
    "section_addr" | "section_min_addr" =>
      match self.subst_find_section(memory) {
        Some((section_memory, _)) =>
          project_subst_memory_addr(section_memory, "min")
        None => name
      }
    "section_max_addr" =>
      match self.subst_find_section(memory) {
        Some((section_memory, _)) =>
          project_subst_memory_addr(section_memory, "max")
        None => name
      }
    "symbol" | "symbol_name" =>
      match self.subst_find_symbol(memory) {
        Some(symbol) => symbol.name()
        None => name
      }
    "symbol_addr" | "symbol_min_addr" =>
      match self.subst_find_symbol(memory) {
        Some(symbol) => project_subst_symbol_addr(symbol, "min")
        None => name
      }
    "symbol_max_addr" =>
      match self.subst_find_symbol(memory) {
        Some(symbol) => project_subst_symbol_addr(symbol, "max")
        None => name
      }
    "block" | "block_name" =>
      match self.subst_find_block(memory) {
        Some(block) => "blk_" + project_subst_addr(block.min_addr())
        None => name
      }
    "block_addr" | "block_min_addr" =>
      match self.subst_find_block(memory) {
        Some(block) => project_subst_memory_addr(block, "min")
        None => name
      }
    "block_max_addr" =>
      match self.subst_find_block(memory) {
        Some(block) => project_subst_memory_addr(block, "max")
        None => name
      }
    "min_addr" | "addr" => project_subst_memory_addr(memory, "min")
    "max_addr" => project_subst_memory_addr(memory, "max")
    "asm" | "bil" => self.subst_disassembly_text(memory, name)
    _ => name
  }
}

///|
fn Project::substitute_text(
  self : Project,
  memory : @memory.Memory,
  value : String,
) -> String {
  let out = StringBuilder()
  let pos = Ref(0)
  while pos.val < value.length() {
    let c = match value.get_char(pos.val) {
      Some(c) => c
      None => return out.to_string()
    }
    let next = pos.val + c.utf16_len()
    if c == '$' {
      let start = next
      let end = Ref(start)
      while end.val < value.length() {
        let item = match value.get_char(end.val) {
          Some(item) => item
          None => break
        }
        if project_subst_is_ident(item) {
          end.val = end.val + item.utf16_len()
        } else {
          break
        }
      }
      if end.val == start {
        out.write_char(c)
        pos.val = next
      } else {
        let name = value[start:end.val].to_owned()
        out.write_string(self.subst_value(memory, name))
        pos.val = end.val
      }
    } else {
      out.write_char(c)
      pos.val = next
    }
  }
  out.to_string()
}

///|
pub fn Project::substitute(
  self : Project,
  memory : @memory.Memory,
  tag : String,
  value : String,
) -> Project {
  self.tag_memory(memory, tag + "=" + self.substitute_text(memory, value))
}
