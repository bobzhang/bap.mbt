///|
struct ProjectDisassemblySourceContext {
  path_value : String?
  bias_value : @types.Word?
  size_value : Int
}

///|
fn project_disassembly_source_context_size(
  target : @core_theory.Target,
  addr : @types.Word?,
  bias : @types.Word?,
) -> Int {
  let target_size = target.code_addr_size()
  if target_size > 0 {
    target_size
  } else {
    match addr {
      Some(word) => word.bitwidth()
      None =>
        match bias {
          Some(word) => word.bitwidth()
          None => 64
        }
    }
  }
}

///|
fn project_disassembly_source_context_word(
  size : Int,
  value : UInt64,
) -> Result[@types.Word, String] {
  if size <= 0 {
    return Err(
      "project disassembly source context requires positive address size",
    )
  }
  try @types.Word::of_uint64(width=size, value) catch {
    _ => Err("project disassembly source context address conversion failed")
  } noraise {
    word => Ok(word)
  }
}

///|
fn project_disassembly_source_context_normalize_word(
  word : @types.Word,
  size : Int,
) -> Result[@types.Word, String] {
  if word.bitwidth() == size {
    Ok(word)
  } else {
    try word.to_uint64() catch {
      _ => Err("project disassembly source context address conversion failed")
    } noraise {
      value => project_disassembly_source_context_word(size, value)
    }
  }
}

///|
fn project_disassembly_source_context_sub_bias(
  address : @types.Word,
  bias : @types.Word,
) -> Result[@types.Word, String] {
  try address.sub(bias) catch {
    _ => Err("project disassembly source context bias conversion failed")
  } noraise {
    word => Ok(word)
  }
}

///|
pub fn ProjectDisassemblySourceContext::create(
  size? : Int = 64,
  path? : String,
  bias? : @types.Word,
) -> Result[ProjectDisassemblySourceContext, String] {
  if size <= 0 {
    return Err(
      "project disassembly source context requires positive address size",
    )
  }
  let normalized_bias = match bias {
    Some(word) =>
      match project_disassembly_source_context_normalize_word(word, size) {
        Ok(value) => Some(value)
        Err(reason) => return Err(reason)
      }
    None => None
  }
  Ok({ path_value: path, bias_value: normalized_bias, size_value: size })
}

///|
pub fn ProjectDisassemblySourceContext::for_unit(
  unit : @core_theory.ProgramUnit,
) -> Result[ProjectDisassemblySourceContext, String] {
  let size = project_disassembly_source_context_size(
    unit.target(),
    None,
    unit.bias(),
  )
  ProjectDisassemblySourceContext::create(
    size~,
    path?=unit.path(),
    bias?=unit.bias(),
  )
}

///|
pub fn ProjectDisassemblySourceContext::for_label(
  label : @core_theory.Label,
) -> Result[ProjectDisassemblySourceContext, String] {
  match label.unit() {
    Some(unit) => {
      let size = project_disassembly_source_context_size(
        label.target(),
        label.addr(),
        unit.bias(),
      )
      ProjectDisassemblySourceContext::create(
        size~,
        path?=unit.path(),
        bias?=unit.bias(),
      )
    }
    None => {
      let size = project_disassembly_source_context_size(
        label.target(),
        label.addr(),
        None,
      )
      ProjectDisassemblySourceContext::create(size~)
    }
  }
}

///|
pub fn ProjectDisassemblySourceContext::path(
  self : ProjectDisassemblySourceContext,
) -> String? {
  self.path_value
}

///|
pub fn ProjectDisassemblySourceContext::bias(
  self : ProjectDisassemblySourceContext,
) -> @types.Word? {
  self.bias_value
}

///|
pub fn ProjectDisassemblySourceContext::size(
  self : ProjectDisassemblySourceContext,
) -> Int {
  self.size_value
}

///|
pub fn ProjectDisassemblySourceContext::is_applicable(
  self : ProjectDisassemblySourceContext,
  path? : String,
) -> Bool {
  match path {
    None => true
    Some(requested) =>
      match self.path_value {
        Some(actual) => requested == actual
        None => false
      }
  }
}

///|
pub fn ProjectDisassemblySourceContext::create_addr(
  self : ProjectDisassemblySourceContext,
  value : UInt64,
  unbiased? : Bool = false,
) -> Result[@types.Word, String] {
  match project_disassembly_source_context_word(self.size_value, value) {
    Ok(address) =>
      if unbiased {
        match self.bias_value {
          Some(bias) =>
            project_disassembly_source_context_sub_bias(address, bias)
          None => Ok(address)
        }
      } else {
        Ok(address)
      }
    Err(reason) => Err(reason)
  }
}

///|
pub fn ProjectDisassemblySourceContext::create_word_addr(
  self : ProjectDisassemblySourceContext,
  value : @types.Word,
  unbiased? : Bool = false,
) -> Result[@types.Word, String] {
  try value.to_uint64() catch {
    _ => Err("project disassembly source context address conversion failed")
  } noraise {
    raw => self.create_addr(raw, unbiased~)
  }
}
