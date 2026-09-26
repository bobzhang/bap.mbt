///|
/// The magic prefix of a serialized knowledge base (`Io.magic`).
let kb_magic : String = "CMU:KB"

///|
fn write_token(buf : StringBuilder, s : String) -> Unit {
  buf.write_string("\{s.length()}:\{s}")
}

///|
fn write_int(buf : StringBuilder, n : Int) -> Unit {
  buf.write_string("\{n};")
}

///|
priv struct KbReader {
  input : String
  mut pos : Int
}

///|
fn KbReader::int(self : KbReader) -> Int raise Conflict {
  let start = self.pos
  while self.pos < self.input.length() && self.input[self.pos] != ';' {
    self.pos = self.pos + 1
  }
  if self.pos >= self.input.length() {
    raise Failure("invalid knowledge base: truncated integer")
  }
  let text = self.input[start:self.pos].to_owned()
  self.pos = self.pos + 1
  @string.parse_int(text) catch {
    _ => raise Failure("invalid knowledge base: bad integer \{text}")
  }
}

///|
fn KbReader::token(self : KbReader) -> String raise Conflict {
  match persistent_decode_chunk(self.input, self.pos, "knowledge base") {
    Ok((text, next)) => {
      self.pos = next
      text
    }
    Err(reason) => raise Failure(reason)
  }
}

///|
/// `Knowledge.to_bigstring`: serializes the persistent part of the
/// knowledge base.
///
/// For every class, the last object identifier and every object that has
/// a name or a persistent property is stored: its identifier, its name,
/// its persistent properties (through the `Persistent` instances of their
/// slots) and the set of properties that were already computed. Context
/// variables, non-persistent properties and public symbol tables are not
/// stored, as upstream.
pub fn State::serialize(self : State) -> String {
  let buf = StringBuilder()
  buf.write_string(kb_magic)
  write_int(buf, 2)
  let classes = self.env.classes.to_array()
  classes.sort_by((x, y) => x.0.compare(y.0))
  write_int(buf, classes.length())
  let names_of_uids : Map[Int, Name] = Map([])
  for _, slots in class_slots {
    for name, pack in slots {
      names_of_uids[pack.uid] = name
    }
  }
  for cls in classes {
    let (name, objects) = cls
    write_token(buf, name.show())
    write_int(buf, objects.last)
    let entries = []
    for id, info in objects.vals {
      let data = info.data.serialize()
      if data.is_empty() && info.name is None {
        continue
      }
      entries.push((id, info, data))
    }
    write_int(buf, entries.length())
    for entry in entries {
      let (id, info, data) = entry
      write_int(buf, id)
      match info.name {
        Some(sym) => {
          buf.write_string("+")
          write_token(buf, sym.show())
        }
        None => buf.write_string("-")
      }
      write_int(buf, data.length())
      for field in data {
        write_token(buf, field.0.show())
        write_token(buf, field.1)
      }
      let comp = []
      for uid, _ in info.comp {
        match names_of_uids.get(uid) {
          Some(slot) => comp.push(slot.show())
          None => ()
        }
      }
      write_int(buf, comp.length())
      for slot in comp {
        write_token(buf, slot)
      }
    }
  }
  buf.to_string()
}

///|
/// `Knowledge.of_bigstring`: loads a knowledge base serialized with
/// `State::serialize`. Properties of unknown (or non-persistent) slots are
/// ignored; loaded computed properties are marked as done.
pub fn State::deserialize(input : String) -> State raise Conflict {
  if !input.has_prefix(kb_magic) {
    raise Failure("Not a valid knowledge base")
  }
  let r : KbReader = { input, pos: kb_magic.length(), }
  let version = r.int()
  if version != 2 {
    raise Failure("unsupported knowledge base version \{version}")
  }
  let mut classes : @hashmap.HashMap[Name, Objects] = @hashmap.HashMap::new()
  let nclasses = r.int()
  for _ in 0..<nclasses {
    let cls = Name::read(r.token())
    let last = r.int()
    let mut objects = { ..empty_class, last, }
    let nobjs = r.int()
    for _ in 0..<nobjs {
      let id = r.int()
      let sym = if r.pos < input.length() && input[r.pos] == '+' {
        r.pos = r.pos + 1
        Some(Name::read(r.token()))
      } else if r.pos < input.length() && input[r.pos] == '-' {
        r.pos = r.pos + 1
        None
      } else {
        raise Failure("invalid knowledge base: bad symbol tag")
      }
      let mut data = empty_record
      let ndata = r.int()
      for _ in 0..<ndata {
        let slot = Name::read(r.token())
        let payload = r.token()
        match slots_by_name.get(slot) {
          Some({ decode: Some(decode), .. }) =>
            match decode(payload) {
              Ok(entry) => data = data.put_entry(entry)
              Err(reason) => raise Failure(reason)
            }
          _ => ()
        }
      }
      let mut comp = @sorted_map.SortedMap::new()
      let ncomp = r.int()
      for _ in 0..<ncomp {
        match slots_by_name.get(Name::read(r.token())) {
          Some(pack) => comp = comp.add(pack.uid, Done)
          None => ()
        }
      }
      objects = {
        ..objects,
        vals: objects.vals.add(id, { data, comp, name: sym, }),
        objs: match sym {
          Some(s) => objects.objs.add(s, id)
          None => objects.objs
        },
      }
    }
    classes = classes.add(cls, objects)
  }
  { env: { ..empty_env, classes, }, }
}

///|
/// Serializes the knowledge base into UTF-8 bytes.
pub fn State::to_bytes(self : State) -> Bytes {
  @utf8.encode(self.serialize())
}

///|
/// Loads a knowledge base from bytes produced by `State::to_bytes`.
pub fn State::of_bytes(data : Bytes) -> State raise Conflict {
  let text = @utf8.decode(data) catch {
    _ => raise Failure("Not a valid knowledge base")
  }
  State::deserialize(text)
}

///|
fn show_in_package(pkg : String, name : Name) -> String {
  if name.pkg() == pkg {
    name.unqualified()
  } else {
    name.show()
  }
}

///|
/// `Knowledge.pp_state`: prints all known properties of all objects,
///
/// ```text
/// (in-package user)
/// (in-class core:label)
/// (<obj> ((slot value) ...))
/// ```
pub fn State::pp(self : State) -> String {
  let pkg = self.env.pkg
  let lines = ["(in-package \{pkg})"]
  let classes = self.env.classes.to_array()
  classes.sort_by((x, y) => x.0.compare(y.0))
  for cls in classes {
    let (name, objects) = cls
    if objects.vals.is_empty() {
      continue
    }
    lines.push("(in-class \{show_in_package(pkg, name)})")
    for id, info in objects.vals {
      if info.data.is_empty() {
        continue
      }
      let obj = match info.name {
        Some(sym) => show_in_package(pkg, sym)
        None => "#<\{name.show()} \{id}>"
      }
      lines.push("(\{obj} \{info.data.inspect()})")
    }
  }
  lines.join("\n")
}
