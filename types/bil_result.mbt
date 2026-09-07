///|
struct BilResultId {
  value : UInt64
} derive(Eq, Debug)

///|
pub extend BilResultId with Eq::{not_equal, equal}

///|
pub extend BilResultId with Debug::{to_repr}

///|
struct BilResultStorage {
  sparse : Bool
  entries : Array[(Word, Word)]
} derive(Eq, Debug)

///|
pub extend BilResultStorage with Eq::{not_equal, equal}

///|
pub extend BilResultStorage with Debug::{to_repr}

///|
pub(all) enum BilResultValue {
  BilResultImm(Word)
  BilResultMem(BilResultStorage)
  BilResultBot
} derive(Eq, Debug)

///|
pub extend BilResultValue with Eq::{not_equal, equal}

///|
pub extend BilResultValue with Debug::{to_repr}

///|
struct BilResult {
  id_value : BilResultId
  value_value : BilResultValue
} derive(Eq, Debug)

///|
pub extend BilResult with Eq::{not_equal, equal}

///|
pub extend BilResult with Debug::{to_repr}

///|
pub fn BilResultId::zero() -> BilResultId {
  { value: 0UL, }
}

///|
pub fn BilResultId::of_uint64(value : UInt64) -> BilResultId {
  { value, }
}

///|
pub fn BilResultId::to_uint64(self : BilResultId) -> UInt64 {
  self.value
}

///|
pub fn BilResultId::succ(self : BilResultId) -> BilResultId {
  { value: self.value + 1UL, }
}

///|
pub fn BilResultId::to_string(self : BilResultId) -> String {
  "0x" + self.value.to_string(radix=16).to_upper()
}

///|
pub fn BilResultStorage::linear() -> BilResultStorage {
  { sparse: false, entries: [], }
}

///|
pub fn BilResultStorage::sparse() -> BilResultStorage {
  { sparse: true, entries: [], }
}

///|
pub fn BilResultStorage::is_sparse(self : BilResultStorage) -> Bool {
  self.sparse
}

///|
pub fn BilResultStorage::load(self : BilResultStorage, addr : Word) -> Word? {
  for entry in self.entries {
    let key = entry.0
    let value = entry.1
    if key == addr {
      return Some(value)
    }
  }
  None
}

///|
pub fn BilResultStorage::save(
  self : BilResultStorage,
  addr : Word,
  value : Word,
) -> BilResultStorage {
  let entries = self.entries.copy()
  if self.sparse {
    for i in 0..<entries.length() {
      if entries[i].0 == addr {
        entries[i] = (addr, value)
        return { ..self, entries, }
      }
    }
    entries.push((addr, value))
  } else {
    entries.insert(0, (addr, value))
  }
  { ..self, entries, }
}

///|
pub fn BilResultValue::to_string(self : BilResultValue) -> String {
  match self {
    BilResultImm(word) => word.to_string()
    BilResultMem(_) => "<storage>"
    BilResultBot => "bot"
  }
}

///|
pub fn BilResult::undefined(id : BilResultId) -> BilResult {
  { id_value: id, value_value: BilResultBot, }
}

///|
pub fn BilResult::storage(
  storage : BilResultStorage,
  id : BilResultId,
) -> BilResult {
  { id_value: id, value_value: BilResultMem(storage), }
}

///|
pub fn BilResult::word(word : Word, id : BilResultId) -> BilResult {
  { id_value: id, value_value: BilResultImm(word), }
}

///|
pub fn BilResult::id(self : BilResult) -> BilResultId {
  self.id_value
}

///|
pub fn BilResult::value(self : BilResult) -> BilResultValue {
  self.value_value
}

///|
pub fn BilResult::to_string(self : BilResult) -> String {
  "[\{self.id_value.to_string()}] \{self.value_value.to_string()}"
}
