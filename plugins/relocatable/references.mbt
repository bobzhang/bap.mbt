///|
/// A reference extracted from relocations: either an address or an external
/// symbol name.
pub(all) enum RelRef {
  Addr(UInt64)
  Name(String)
} derive(Eq, Debug)

///|
pub extend RelRef with Eq::{not_equal, equal}

///|
pub extend RelRef with Debug::{to_repr}

///|
/// A reference or a conflict between references at the same address.
pub(all) enum RefValue {
  Ref(RelRef)
  Bad
} derive(Eq, Debug)

///|
pub extend RefValue with Eq::{not_equal, equal}

///|
pub extend RefValue with Debug::{to_repr}

///|
/// External references of a unit keyed by (fixup) address
/// (`References.t`).
pub struct References {
  refs : Map[UInt64, RefValue]
}

///|
/// Drops the symbol version suffix (`name@VERSION`).
pub fn chop_version(s : String) -> String {
  match s.find("@") {
    None | Some(0) => s
    Some(len) => s.unsafe_substring(start=0, end=len)
  }
}

///|
fn modulo(addr : Int64, width : Int) -> UInt64 {
  let value = addr.reinterpret_as_uint64()
  if width <= 0 || width >= 64 {
    value
  } else {
    value & ((1UL << width) - 1UL)
  }
}

///|
fn merge_name(x : RefValue, name : String) -> RefValue {
  let y = Ref(Name(chop_version(name)))
  match x {
    Bad => Bad
    Ref(Addr(_)) => x
    Ref(Name(_)) => if x == y { y } else { Bad }
  }
}

///|
fn merge_addr(x : RefValue, addr : UInt64) -> RefValue {
  let y = Ref(Addr(addr))
  match x {
    Bad => Bad
    Ref(Addr(_)) if x != y => Bad
    _ => y
  }
}

///|
/// Extracts the references from a specification: external references give
/// names and relocations give addresses (a relocation overrides a name at the
/// same address). Addresses are taken modulo the target code address size.
pub fn References::create(
  target : @core_theory.Target,
  doc : @ogre.Doc,
) -> References {
  let size = target.code_addr_size()
  let width = if size > 0 { size } else { 64 }
  let refs : Map[UInt64, RefValue] = Map([])
  for entry in doc.get(@image.Scheme::external_reference()) {
    let key = modulo(entry.0, width)
    refs[key] = match refs.get(key) {
      None => Ref(Name(chop_version(entry.1)))
      Some(old) => merge_name(old, entry.1)
    }
  }
  for entry in doc.get(@image.Scheme::relocation()) {
    let key = modulo(entry.0, width)
    let addr = modulo(entry.1, width)
    refs[key] = match refs.get(key) {
      None => Ref(Addr(addr))
      Some(old) => merge_addr(old, addr)
    }
  }
  { refs, }
}

///|
/// The references of a project specification.
pub fn References::of_project(project : @project.Project) -> References {
  References::create(project.target(), project.specification())
}

///|
/// The references as an association list sorted by address.
pub fn References::to_array(self : References) -> Array[(UInt64, RefValue)] {
  let entries = self.refs.to_array()
  entries.sort_by((x, y) => x.0.compare(y.0))
  entries
}

///|
/// Looks up the reference at an address; conflicting references are pruned
/// with a warning.
pub fn References::lookup(self : References, addr : UInt64) -> RelRef? {
  match self.refs.get(addr) {
    Some(Bad) => {
      @main_event.message(
        MainLogWarning,
        section="relocatable",
        message="pruning a reference at 0x\{addr.to_string(radix=16)} for it being a bad reference",
      )
      None
    }
    Some(Ref(x)) => Some(x)
    None => None
  }
}

///|
/// Looks up the reference at an address word.
pub fn References::search(self : References, addr : @types.Word) -> RelRef? {
  try addr.to_uint64() catch {
    _ => None
  } noraise {
    a => self.lookup(a)
  }
}
