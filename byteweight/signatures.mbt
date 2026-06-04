///|
pub(all) enum ByteweightSignatureError {
  ByteweightSignatureCorrupted(String)
  ByteweightSignatureNoSignatures
  ByteweightSignatureNoEntry(String)
  ByteweightSignatureSysError(String)
} derive(Eq, Debug)

///|
struct ByteweightSignatureData[T] {
  name_value : String
  load_fn : (Bytes) -> Result[T, String]
  save_fn : (T) -> Bytes
}

///|
priv struct ByteweightSignatureEntry {
  target_name : String
  compiler_name : String
  data_name : String
  payload : Bytes
}

///|
let byteweight_signature_data_registry : Map[String, Bool] = {}

///|
pub fn ByteweightSignatureError::to_string(
  self : ByteweightSignatureError,
) -> String {
  match self {
    ByteweightSignatureCorrupted(reason) =>
      "signature database is corrupted: \{reason}"
    ByteweightSignatureNoSignatures => "signature database doesn't exist"
    ByteweightSignatureNoEntry(name) => "can't access given entry: \{name}"
    ByteweightSignatureSysError(reason) => "system error: \{reason}"
  }
}

///|
pub fn byteweight_signature_default_path() -> String {
  "byteweight.signatures"
}

///|
pub fn byteweight_signature_system_path() -> String {
  "/usr/share/bap/byteweight.signatures"
}

///|
pub fn[T] ByteweightSignatureData::register(
  name : String,
  load~ : (Bytes) -> Result[T, String],
  save~ : (T) -> Bytes,
) -> Result[ByteweightSignatureData[T], String] {
  if byteweight_signature_data_registry.contains(name) {
    Err("data entry already exists: \{name}")
  } else {
    byteweight_signature_data_registry[name] = true
    Ok({ name_value: name, load_fn: load, save_fn: save })
  }
}

///|
pub fn[T] ByteweightSignatureData::name(
  self : ByteweightSignatureData[T],
) -> String {
  self.name_value
}

///|
fn byteweight_signature_paths(paths : Array[String]) -> Array[String] {
  let out = paths.copy()
  out.push(byteweight_signature_default_path())
  out.push(byteweight_signature_system_path())
  out
}

///|
fn byteweight_signature_compiler_name(
  compiler : @core_theory.Compiler?,
) -> String {
  match compiler {
    Some(compiler) => compiler.name()
    None => "default"
  }
}

///|
fn byteweight_signature_target_name(target : @core_theory.Target) -> String {
  target.name().unqualified()
}

///|
fn byteweight_signature_matches_target(
  target : @core_theory.Target,
  name : String,
) -> Bool {
  match target.matching(name) {
    Some(matched) => matched.bits() == target.bits()
    None => false
  }
}

///|
fn byteweight_signature_entry_matches(
  entry : ByteweightSignatureEntry,
  target : @core_theory.Target,
  compiler_name : String,
  data_name : String,
) -> Bool {
  entry.compiler_name == compiler_name &&
  entry.data_name == data_name &&
  byteweight_signature_matches_target(target, entry.target_name)
}

///|
fn byteweight_signature_string_to_field(text : String) -> String {
  @regular.bytes_to_hex(@utf8.encode(text))
}

///|
fn byteweight_signature_bytes_to_field(bytes : BytesView) -> String {
  @regular.bytes_to_hex(bytes)
}

///|
fn byteweight_signature_field_to_bytes(
  field : StringView,
) -> Result[Bytes, ByteweightSignatureError] {
  match @regular.bytes_from_hex(field) {
    Ok(bytes) => Ok(bytes)
    Err(reason) => Err(ByteweightSignatureCorrupted(reason))
  }
}

///|
fn byteweight_signature_field_to_string(
  field : StringView,
) -> Result[String, ByteweightSignatureError] {
  match byteweight_signature_field_to_bytes(field) {
    Ok(bytes) =>
      try @utf8.decode(bytes) catch {
        _ => Err(ByteweightSignatureCorrupted("entry field is not valid UTF-8"))
      } noraise {
        text => Ok(text)
      }
    Err(err) => Err(err)
  }
}

///|
fn byteweight_signature_parse_line(
  line : String,
) -> Result[ByteweightSignatureEntry, ByteweightSignatureError] {
  match line.split(" ").to_array() {
    [target_field, compiler_field, data_field, payload_field] => {
      let target_name = match
        byteweight_signature_field_to_string(target_field) {
        Ok(text) => text
        Err(err) => return Err(err)
      }
      let compiler_name = match
        byteweight_signature_field_to_string(compiler_field) {
        Ok(text) => text
        Err(err) => return Err(err)
      }
      let data_name = match byteweight_signature_field_to_string(data_field) {
        Ok(text) => text
        Err(err) => return Err(err)
      }
      let payload = match byteweight_signature_field_to_bytes(payload_field) {
        Ok(bytes) => bytes
        Err(err) => return Err(err)
      }
      Ok({ target_name, compiler_name, data_name, payload })
    }
    _ => Err(ByteweightSignatureCorrupted("entry doesn't have four fields"))
  }
}

///|
fn byteweight_signature_parse_entries(
  bytes : Bytes,
) -> Result[Array[ByteweightSignatureEntry], ByteweightSignatureError] {
  let text = try @utf8.decode(bytes) catch {
    _ => return Err(ByteweightSignatureCorrupted("database is not valid UTF-8"))
  } noraise {
    value => value
  }
  let entries : Array[ByteweightSignatureEntry] = []
  for line_view in text.split("\n") {
    let line = line_view.to_owned()
    if line.length() > 0 {
      match byteweight_signature_parse_line(line) {
        Ok(entry) => entries.push(entry)
        Err(err) => return Err(err)
      }
    }
  }
  Ok(entries)
}

///|
fn byteweight_signature_entry_to_line(
  entry : ByteweightSignatureEntry,
) -> String {
  byteweight_signature_string_to_field(entry.target_name) +
  " " +
  byteweight_signature_string_to_field(entry.compiler_name) +
  " " +
  byteweight_signature_string_to_field(entry.data_name) +
  " " +
  byteweight_signature_bytes_to_field(entry.payload)
}

///|
fn byteweight_signature_entries_to_bytes(
  entries : Array[ByteweightSignatureEntry],
) -> Bytes {
  let out = StringBuilder()
  for entry in entries {
    out.write_string(byteweight_signature_entry_to_line(entry))
    out.write_char('\n')
  }
  @utf8.encode(out.to_string())
}

///|
fn byteweight_signature_try_read_entries(
  path : String,
) -> Result[Array[ByteweightSignatureEntry]?, ByteweightSignatureError] {
  match @native_io.read_file(path) {
    Ok(bytes) =>
      match byteweight_signature_parse_entries(bytes) {
        Ok(entries) => Ok(Some(entries))
        Err(err) => Err(err)
      }
    Err(_) => Ok(None)
  }
}

///|
fn byteweight_signature_update_raw(
  path : String,
  target_name : String,
  compiler_name : String,
  data_name : String,
  payload : BytesView,
) -> Result[Unit, ByteweightSignatureError] {
  let entries = match @native_io.read_file(path) {
    Ok(bytes) =>
      match byteweight_signature_parse_entries(bytes) {
        Ok(entries) => entries
        Err(err) => return Err(err)
      }
    Err(_) => []
  }
  let out : Array[ByteweightSignatureEntry] = []
  for entry in entries {
    if entry.target_name != target_name ||
      entry.compiler_name != compiler_name ||
      entry.data_name != data_name {
      out.push(entry)
    }
  }
  out.push({
    target_name,
    compiler_name,
    data_name,
    payload: payload.to_owned(),
  })
  let encoded = byteweight_signature_entries_to_bytes(out)
  match @native_io.write_file(path, encoded) {
    Ok(_) => Ok(())
    Err(reason) => Err(ByteweightSignatureSysError(reason))
  }
}

///|
pub fn[T] ByteweightSignatureData::lookup(
  self : ByteweightSignatureData[T],
  target : @core_theory.Target,
  paths? : Array[String] = [],
  compiler? : @core_theory.Compiler,
) -> Result[T, ByteweightSignatureError] {
  let compiler_name = byteweight_signature_compiler_name(compiler)
  for path in byteweight_signature_paths(paths) {
    match byteweight_signature_try_read_entries(path) {
      Ok(Some(entries)) =>
        for entry in entries {
          if byteweight_signature_entry_matches(
              entry,
              target,
              compiler_name,
              self.name_value,
            ) {
            match (self.load_fn)(entry.payload) {
              Ok(value) => return Ok(value)
              Err(reason) =>
                return Err(
                  ByteweightSignatureCorrupted(
                    "can't load entry \{entry.target_name}/\{entry.compiler_name}/\{entry.data_name}: \{reason}",
                  ),
                )
            }
          }
        }
      Ok(None) => ()
      Err(err) => return Err(err)
    }
  }
  Err(ByteweightSignatureNoEntry(byteweight_signature_target_name(target)))
}

///|
pub fn[T] ByteweightSignatureData::update(
  self : ByteweightSignatureData[T],
  path : String,
  target : @core_theory.Target,
  value : T,
  compiler? : @core_theory.Compiler,
) -> Result[Unit, ByteweightSignatureError] {
  byteweight_signature_update_raw(
    path,
    byteweight_signature_target_name(target),
    byteweight_signature_compiler_name(compiler),
    self.name_value,
    (self.save_fn)(value),
  )
}

///|
pub fn byteweight_signature_save(
  path : String,
  arch~ : String,
  mode~ : String,
  payload : BytesView,
  compiler? : String = "default",
) -> Result[Unit, ByteweightSignatureError] {
  byteweight_signature_update_raw(path, arch, compiler, mode, payload)
}

///|
pub fn byteweight_signature_load(
  paths? : Array[String] = [],
  arch~ : String,
  mode~ : String,
  compiler? : String = "default",
) -> Result[Bytes, ByteweightSignatureError] {
  for path in byteweight_signature_paths(paths) {
    match byteweight_signature_try_read_entries(path) {
      Ok(Some(entries)) => {
        for entry in entries {
          if entry.target_name == arch &&
            entry.compiler_name == compiler &&
            entry.data_name == mode {
            return Ok(entry.payload)
          }
        }
        return Err(ByteweightSignatureNoEntry("\{arch}/\{compiler}/\{mode}"))
      }
      Ok(None) => ()
      Err(err) => return Err(err)
    }
  }
  Err(ByteweightSignatureNoSignatures)
}
