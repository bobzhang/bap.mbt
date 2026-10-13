///|
/// A program input: a variable or a memory cell whose value was generated
/// (not computed) during the execution. Every input is represented in
/// the formulas by an SMT constant named after it (`to_symbol`).
pub(all) enum Input {
  Var(@types.Var)
  Ptr(bank~ : @primus.Descriptor, addr~ : @types.Word)
}

///|
/// A symbolic memory declared with `symbolic-memory`: its bank and the
/// bounds of its region.
priv struct SymMemory {
  bank : @primus.Descriptor
  lower : @types.Word
  upper : @types.Word
}

///|
fn SymMemory::same(self : SymMemory, other : SymMemory) -> Bool {
  self.bank == other.bank &&
  self.lower == other.lower &&
  self.upper == other.upper
}

///|
/// The symbolic memories by name (global).
let memories : @primus.State[@sorted_map.SortedMap[String, SymMemory]] = @primus.State::declare_(
  uuid="15dbb89a-3bfb-421c-8b19-16605425c3f5",
  name="symbolic-memories",
  _ => @sorted_map.new(),
)

///|
/// The name of the SMT constant that stands for the input: the variable
/// name, or `bank[addr]` for a memory cell.
pub fn Input::to_symbol(self : Input) -> String {
  match self {
    Var(v) => if v.index() == 0 { v.name() } else { "\{v.name()}.\{v.index()}" }
    Ptr(bank~, addr~) => "\{bank.name()}[\{hex(addr)}]"
  }
}

///|
/// The address in hexadecimal without leading zeros (upstream
/// `Addr.pp_hex`).
fn hex(w : @types.Word) -> String {
  let digits = w.to_hex(prefix=false)
  let mut i = 0
  while i < digits.length() - 1 && digits[i] == '0' {
    i += 1
  }
  "0x" + digits.view(start_offset=i).to_owned()
}

///|
/// The width of the input in bits.
pub fn Input::size(self : Input) -> Int32 {
  match self {
    Ptr(bank~, ..) => bank.data_size()
    Var(v) =>
      match v.typ() {
        Imm(m) => m
        _ => 1
      }
  }
}

///|
pub impl Eq for Input with fn equal(self, other) {
  self.compare(other) == 0
}

///|
pub impl Compare for Input with fn compare(self, other) {
  match (self, other) {
    (Var(x), Var(y)) => x.compare(y)
    (Var(_), Ptr(..)) => -1
    (Ptr(..), Var(_)) => 1
    (Ptr(bank=b1, addr=a1), Ptr(bank=b2, addr=a2)) => {
      let c = b1.compare(b2)
      if c != 0 {
        c
      } else {
        a1.compare(a2)
      }
    }
  }
}

///|
pub impl Show for Input with fn output(self, logger) {
  logger.write_string(self.to_symbol())
}

///|
/// A deterministic hash of a string (the seed of the generator of a
/// symbolic memory, upstream `Hashtbl.hash` of its name).
fn string_seed(s : String) -> Int32 {
  let mut h = 0x811c9dc5U
  for c in s {
    h = (h ^ c.to_int().reinterpret_as_uint()) * 0x01000193U
  }
  (h & 0x3fffffffU).reinterpret_as_int()
}

///|
fn allocate(
  m : @primus.Machine,
  bank : @primus.Descriptor,
  lower : @types.Word,
  upper : @types.Word,
) -> Unit raise {
  let width = bank.data_size()
  let generator = @primus.Generator::random_lcg(
    width~,
    string_seed(bank.name()),
  )
  @primus.Memory::add_region(m, generator~, lower~, upper~)
}

///|
fn allocate_if_not(
  m : @primus.Machine,
  bank : @primus.Descriptor,
  addr : @types.Word,
) -> Unit raise {
  if @primus.Memory::is_writable(m, addr) {
    return
  }
  match m.get_global(memories).get(bank.name()) {
    None => allocate(m, bank, addr, addr)
    Some(mem) => allocate(m, bank, mem.lower, mem.upper)
  }
}

///|
/// Writes the value of the input into the machine: the variable is set,
/// or the cell is stored into its memory bank (allocated if it is not
/// mapped yet).
pub fn Input::set(
  self : Input,
  m : @primus.Machine,
  value : @primus.Value,
) -> Unit raise {
  match self {
    Var(v) => @primus.Env::set(m, v, value)
    Ptr(bank~, addr~) => {
      let current = @primus.Memory::memory(m)
      @primus.Memory::switch(m, bank)
      defer @primus.Memory::switch(m, current)
      allocate_if_not(m, bank, addr)
      @primus.Memory::set(m, addr, value)
    }
  }
}

///|
pub extend Input with Eq::{not_equal, equal}

///|
pub extend Input with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
pub extend Input with Show::{to_string, output}
