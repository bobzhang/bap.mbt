///|
pub(all) enum Endianness {
  LittleEndian
  BigEndian
  BiEndian
} derive(Eq, Debug)

///|
pub(all) enum System {
  UnknownSystem
  Linux
  Darwin
  Windows
} derive(Eq, Debug)

///|
pub(all) enum Abi {
  UnknownAbi
  SysV
  GNU
  EABI
  MSVC
} derive(Eq, Debug)

///|
pub(all) enum Fabi {
  UnknownFabi
  Soft
  Hard
} derive(Eq, Debug)

///|
pub(all) enum Filetype {
  UnknownFiletype
  Elf
  MachO
  PE
  Raw
} derive(Eq, Debug)

///|
pub(all) enum Role {
  General
  StackPointer
  FramePointer
  ProgramCounter
  Status
  Argument
  ResultRegister
} derive(Eq, Debug)

///|
struct Target {
  name_value : @knowledge.Name
  parent_value : Target?
  nicknames_value : Array[String]
  bits_value : Int
  byte_value : Int
  endianness_value : Endianness
  system_value : System
  abi_value : Abi
  fabi_value : Fabi
  filetype_value : Filetype
  vars_value : Array[Var]
}

///|
pub fn Target::unknown() -> Target {
  {
    name_value: @knowledge.Name::create("unknown", pkg="target"),
    parent_value: None,
    nicknames_value: [],
    bits_value: 0,
    byte_value: 8,
    endianness_value: BiEndian,
    system_value: UnknownSystem,
    abi_value: UnknownAbi,
    fabi_value: UnknownFabi,
    filetype_value: UnknownFiletype,
    vars_value: [],
  }
}

///|
pub fn Target::create(
  name~ : @knowledge.Name,
  parent? : Target,
  nicknames? : Array[String],
  bits? : Int,
  byte? : Int,
  endianness? : Endianness,
  system? : System,
  abi? : Abi,
  fabi? : Fabi,
  filetype? : Filetype,
  vars? : Array[Var],
) -> Target {
  {
    name_value: name,
    parent_value: parent,
    nicknames_value: match nicknames {
      Some(items) => items.copy()
      None => []
    },
    bits_value: match bits {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.bits()
          None => 0
        }
    },
    byte_value: match byte {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.byte()
          None => 8
        }
    },
    endianness_value: match endianness {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.endianness()
          None => BiEndian
        }
    },
    system_value: match system {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.system()
          None => UnknownSystem
        }
    },
    abi_value: match abi {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.abi()
          None => UnknownAbi
        }
    },
    fabi_value: match fabi {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.fabi()
          None => UnknownFabi
        }
    },
    filetype_value: match filetype {
      Some(value) => value
      None =>
        match parent {
          Some(target) => target.filetype()
          None => UnknownFiletype
        }
    },
    vars_value: match vars {
      Some(items) => items.copy()
      None =>
        match parent {
          Some(target) => target.vars()
          None => []
        }
    },
  }
}

///|
pub fn Target::name(self : Target) -> @knowledge.Name {
  self.name_value
}

///|
pub fn Target::parent(self : Target) -> Target? {
  self.parent_value
}

///|
pub fn Target::nicknames(self : Target) -> Array[String] {
  self.nicknames_value.copy()
}

///|
pub fn Target::bits(self : Target) -> Int {
  self.bits_value
}

///|
pub fn Target::byte(self : Target) -> Int {
  self.byte_value
}

///|
pub fn Target::endianness(self : Target) -> Endianness {
  self.endianness_value
}

///|
pub fn Target::system(self : Target) -> System {
  self.system_value
}

///|
pub fn Target::abi(self : Target) -> Abi {
  self.abi_value
}

///|
pub fn Target::fabi(self : Target) -> Fabi {
  self.fabi_value
}

///|
pub fn Target::filetype(self : Target) -> Filetype {
  self.filetype_value
}

///|
pub fn Target::vars(self : Target) -> Array[Var] {
  self.vars_value.copy()
}

///|
pub fn Target::find_var(self : Target, name : String) -> Var? {
  self.vars_value
  .search_by(item => item.ident() == name || item.name() == name)
  .map(i => self.vars_value[i])
}

///|
pub fn Target::is_unknown(self : Target) -> Bool {
  self.name_value == @knowledge.Name::create("unknown", pkg="target")
}

///|
pub fn Target::matches(self : Target, query : String) -> Bool {
  self.name_value.unqualified() == query ||
  self.name_value.show() == query ||
  self.nicknames_value.any(nick => nick == query)
}

///|
pub fn Target::belongs(self : Target, parent : Target) -> Bool {
  if self.name_value == parent.name() {
    true
  } else {
    match self.parent_value {
      Some(next) => next.belongs(parent)
      None => false
    }
  }
}

///|
pub fn Target::order(self : Target, other : Target) -> @knowledge.PartialOrder {
  if self.name_value == other.name() {
    Equal
  } else if self.belongs(other) {
    Less
  } else if other.belongs(self) {
    Greater
  } else {
    Incomparable
  }
}
