///|
struct ProjectDisassemblySourceContext {
  path_value : String?
  bias_value : @types.Word?
  size_value : Int32
}

///|
struct ProjectDisassemblySource[T] {
  items_value : Array[Result[T, String]]
}

///|
let project_rooter_source_registry : Map[
  String,
  ProjectDisassemblySource[ProjectRooter],
] = Map([])

///|
let project_brancher_source_registry : Map[
  String,
  ProjectDisassemblySource[ProjectBrancher],
] = Map([])

///|
let project_symbolizer_source_registry : Map[
  String,
  ProjectDisassemblySource[ProjectSymbolizer],
] = Map([])

///|
let project_disassembly_driver_source_registry : Map[
  String,
  ProjectDisassemblySource[ProjectDisassemblyDriver],
] = Map([])

///|
let project_reconstructor_source_registry : Map[
  String,
  ProjectDisassemblySource[ProjectReconstructor],
] = Map([])

///|
fn[T] project_disassembly_source_registry_names(
  registry : Map[String, ProjectDisassemblySource[T]],
) -> Array[String] {
  let names = []
  registry.each((name, _) => names.push(name))
  names.sort_by((left, right) => left.compare(right))
  names
}

///|
fn project_disassembly_source_context_size(
  target : @core_theory.Target,
  addr : @types.Word?,
  bias : @types.Word?,
) -> Int32 {
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
  size : Int32,
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
  size : Int32,
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
pub fn[T] ProjectDisassemblySource::create(
  items : Array[Result[T, String]],
) -> ProjectDisassemblySource[T] {
  { items_value: items.copy(), }
}

///|
pub fn[T] ProjectDisassemblySource::single(
  item : T,
) -> ProjectDisassemblySource[T] {
  ProjectDisassemblySource::create([Ok(item)])
}

///|
pub fn[T] ProjectDisassemblySource::error(
  reason : String,
) -> ProjectDisassemblySource[T] {
  ProjectDisassemblySource::create([Err(reason)])
}

///|
pub fn[T] ProjectDisassemblySource::items(
  self : ProjectDisassemblySource[T],
) -> Array[Result[T, String]] {
  self.items_value.copy()
}

///|
pub fn[T] ProjectDisassemblySource::values(
  self : ProjectDisassemblySource[T],
) -> Array[T] {
  let values = []
  for item in self.items_value {
    match item {
      Ok(value) => values.push(value)
      Err(_) => ()
    }
  }
  values
}

///|
pub fn[T] ProjectDisassemblySource::errors(
  self : ProjectDisassemblySource[T],
) -> Array[String] {
  let errors = []
  for item in self.items_value {
    match item {
      Ok(_) => ()
      Err(reason) => errors.push(reason)
    }
  }
  errors
}

///|
pub fn[T] ProjectDisassemblySource::is_empty(
  self : ProjectDisassemblySource[T],
) -> Bool {
  self.items_value.is_empty()
}

///|
pub fn[T] ProjectDisassemblySource::length(
  self : ProjectDisassemblySource[T],
) -> Int32 {
  self.items_value.length()
}

///|
pub fn ProjectDisassemblySourceContext::create(
  size~ : Int32 = 64,
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
  Ok({ path_value: path, bias_value: normalized_bias, size_value: size, })
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
) -> Int32 {
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
  unbiased~ : Bool = false,
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
  unbiased~ : Bool = false,
) -> Result[@types.Word, String] {
  try value.to_uint64() catch {
    _ => Err("project disassembly source context address conversion failed")
  } noraise {
    raw => self.create_addr(raw, unbiased~)
  }
}

///|
pub fn register_rooter_source(
  name~ : String,
  source : ProjectDisassemblySource[ProjectRooter],
) -> Unit {
  project_rooter_source_registry[name] = source
}

///|
pub fn register_rooter_source_value(
  name~ : String,
  rooter : ProjectRooter,
) -> Unit {
  register_rooter_source(name~, ProjectDisassemblySource::single(rooter))
}

///|
pub fn find_rooter_source(
  name : String,
) -> ProjectDisassemblySource[ProjectRooter]? {
  project_rooter_source_registry.get(name)
}

///|
pub fn rooter_source_names() -> Array[String] {
  project_disassembly_source_registry_names(project_rooter_source_registry)
}

///|
pub fn register_brancher_source(
  name~ : String,
  source : ProjectDisassemblySource[ProjectBrancher],
) -> Unit {
  project_brancher_source_registry[name] = source
}

///|
pub fn register_brancher_source_value(
  name~ : String,
  brancher : ProjectBrancher,
) -> Unit {
  register_brancher_source(name~, ProjectDisassemblySource::single(brancher))
}

///|
pub fn find_brancher_source(
  name : String,
) -> ProjectDisassemblySource[ProjectBrancher]? {
  project_brancher_source_registry.get(name)
}

///|
pub fn brancher_source_names() -> Array[String] {
  project_disassembly_source_registry_names(project_brancher_source_registry)
}

///|
pub fn register_symbolizer_source(
  name~ : String,
  source : ProjectDisassemblySource[ProjectSymbolizer],
) -> Unit {
  project_symbolizer_source_registry[name] = source
}

///|
pub fn register_symbolizer_source_value(
  name~ : String,
  symbolizer : ProjectSymbolizer,
) -> Unit {
  register_symbolizer_source(
    name~,
    ProjectDisassemblySource::single(symbolizer),
  )
}

///|
pub fn find_symbolizer_source(
  name : String,
) -> ProjectDisassemblySource[ProjectSymbolizer]? {
  project_symbolizer_source_registry.get(name)
}

///|
pub fn symbolizer_source_names() -> Array[String] {
  project_disassembly_source_registry_names(project_symbolizer_source_registry)
}

///|
pub fn register_disassembly_driver_source(
  name~ : String,
  source : ProjectDisassemblySource[ProjectDisassemblyDriver],
) -> Unit {
  project_disassembly_driver_source_registry[name] = source
}

///|
pub fn register_disassembly_driver_source_value(
  name~ : String,
  driver : ProjectDisassemblyDriver,
) -> Unit {
  register_disassembly_driver_source(
    name~,
    ProjectDisassemblySource::single(driver),
  )
}

///|
pub fn find_disassembly_driver_source(
  name : String,
) -> ProjectDisassemblySource[ProjectDisassemblyDriver]? {
  project_disassembly_driver_source_registry.get(name)
}

///|
pub fn disassembly_driver_source_names() -> Array[String] {
  project_disassembly_source_registry_names(
    project_disassembly_driver_source_registry,
  )
}

///|
pub fn register_reconstructor_source(
  name~ : String,
  source : ProjectDisassemblySource[ProjectReconstructor],
) -> Unit {
  project_reconstructor_source_registry[name] = source
}

///|
pub fn register_reconstructor_source_value(
  name~ : String,
  reconstructor : ProjectReconstructor,
) -> Unit {
  register_reconstructor_source(
    name~,
    ProjectDisassemblySource::single(reconstructor),
  )
}

///|
pub fn find_reconstructor_source(
  name : String,
) -> ProjectDisassemblySource[ProjectReconstructor]? {
  project_reconstructor_source_registry.get(name)
}

///|
pub fn reconstructor_source_names() -> Array[String] {
  project_disassembly_source_registry_names(
    project_reconstructor_source_registry,
  )
}
