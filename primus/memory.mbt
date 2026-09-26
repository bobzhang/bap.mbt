///|
/// Describes a memory bank (upstream `Primus.Memory.Descriptor.t`).
/// Descriptors are compared by name only, as upstream.
pub struct Descriptor {
  name : String
  addr_size : Int
  data_size : Int
} derive(Debug)

///|
pub impl Eq for Descriptor with fn equal(self, other) {
  self.name == other.name
}

///|
pub impl Compare for Descriptor with fn compare(self, other) {
  self.name.compare(other.name)
}

///|
pub fn Descriptor::create(
  addr_size~ : Int,
  data_size~ : Int,
  name : String,
) -> Descriptor {
  { name, addr_size, data_size, }
}

///|
pub fn Descriptor::unknown(addr_size~ : Int, data_size~ : Int) -> Descriptor {
  Descriptor::create(addr_size~, data_size~, "unknown")
}

///|
pub fn Descriptor::name(self : Descriptor) -> String {
  self.name
}

///|
pub fn Descriptor::addr_size(self : Descriptor) -> Int {
  self.addr_size
}

///|
pub fn Descriptor::data_size(self : Descriptor) -> Int {
  self.data_size
}

///|
pub fn Descriptor::to_sexp(self : Descriptor) -> Sexp {
  Sexp::atoms([
    self.name,
    self.addr_size.to_string(),
    self.data_size.to_string(),
  ])
}

///|
priv enum Region {
  Dynamic(@types.Word, @types.Word, Generator)
  Static(@memory.Memory)
}

///|
priv struct Layer {
  mem : Region
  read_only : Bool
  executable : Bool
}

///|
priv struct Bank {
  values : @sorted_map.SortedMap[AddrKey, Value]
  layers : @list.List[Layer]
}

///|
/// The memory state of a machine: the current bank and all banks
/// (upstream `Primus.Memory` state). All operations are static functions
/// taking the machine.
pub struct Memory {
  priv curr : Descriptor
  priv mems : @sorted_map.SortedMap[String, Bank]
}

///|
fn empty_bank() -> Bank {
  { values: @sorted_map.SortedMap::new(), layers: @list.List::new(), }
}

///|
/// The descriptor of the target's main memory (upstream `virtual_memory`).
fn virtual_memory(target : @core_theory.Target) -> Descriptor {
  let mem = target.data()
  let sort = mem.sort()
  let ks = match sort.mem_keys() {
    Some(k) => k.bitv_size().unwrap_or(0)
    None => 0
  }
  let vs = match sort.mem_values() {
    Some(v) => v.bitv_size().unwrap_or(0)
    None => 0
  }
  let ks = if ks <= 0 { target_bits(target) } else { ks }
  let vs = if vs <= 0 { 8 } else { vs }
  Descriptor::create(addr_size=ks, data_size=vs, mem.name())
}

///|
fn layer_to_sexp(l : Layer) -> Sexp {
  let flags = "R" +
    (if l.read_only { "" } else { "W" }) +
    (if l.executable { "X" } else { "" })
  let mem = match l.mem {
    Dynamic(lo, hi, g) =>
      List([Atom("dynamic"), Atom(lo.to_hex()), Atom(hi.to_hex()), g.to_sexp()])
    Static(m) =>
      Sexp::atoms(["static", m.min_addr().to_string(), m.length().to_string()])
  }
  List([mem, Atom(flags)])
}

///|
fn memory_to_sexp(t : Memory) -> Sexp {
  let banks = []
  t.mems.each((name, bank) => {
    let values = []
    bank.values.each((k, v) => {
      values.push(List([Atom(k.0.to_hex()), v.to_sexp()]))
    })
    banks.push(
      List([
        Atom(name),
        List([Atom("values"), List(values)]),
        List([Atom("layers"), List(bank.layers.map(layer_to_sexp).to_array())]),
      ]),
    )
  })
  List([Atom(t.curr.name), List(banks)])
}

///|
let memory_state : State[Memory] = State::declare_(
  uuid="4b94186d-3ae9-48e0-8a93-8c83c747bdbb",
  inspect=memory_to_sexp,
  name="memory",
  p => { curr: virtual_memory(p.target()), mems: @sorted_map.SortedMap::new(), },
)

///|
let load_generated_stmt : Statement[(@types.Word, Value)] = Statement::provide(
  "load-generated",
  inspect=p => List([Atom(p.0.to_hex()), p.1.to_sexp()]),
  pkg="bap",
  desc="Occurs when a new value is generated during the load operation",
)

///|
/// Occurs when a value of uninitialized memory is generated (upstream
/// `Memory.generated`).
pub let load_generated : Observation[(@types.Word, Value)] = load_generated_stmt.obs

///|
fn addr_le(x : @types.Word, y : @types.Word) -> Bool {
  x.compare(y) <= 0
}

///|
fn addr_to_u64(a : @types.Word) -> UInt64? {
  if a.bitwidth() > 64 {
    return None
  }
  try a.to_uint64() catch {
    _ => None
  } noraise {
    x => Some(x)
  }
}

///|
fn region_contains(r : Region, addr : @types.Word) -> Bool {
  match r {
    Dynamic(lower, upper, _) =>
      if addr_le(lower, upper) {
        addr_le(lower, addr) && addr_le(addr, upper)
      } else {
        // a region that wraps around the end of the address space:
        // [lower, max] U [0, upper] (upstream tests the reversed
        // endpoints, which makes such a region contain every address)
        addr_le(lower, addr) || addr_le(addr, upper)
      }
    Static(mem) =>
      match addr_to_u64(addr) {
        Some(a) => mem.contains(a)
        None => false
      }
  }
}

///|
fn find_layer(layers : @list.List[Layer], addr : @types.Word) -> Layer? {
  for l in layers {
    if region_contains(l.mem, addr) {
      return Some(l)
    }
  }
  None
}

///|
/// Switches the current memory bank (`Memory.switch`).
pub fn Memory::switch(m : Machine, desc : Descriptor) -> Unit {
  m.update_local(memory_state, s => { ..s, curr: desc, })
}

///|
/// The descriptor of the current memory bank (`Memory.memory`).
pub fn Memory::memory(m : Machine) -> Descriptor {
  m.get_local(memory_state).curr
}

///|
fn Memory::get_curr(m : Machine) -> Bank {
  let s = m.get_local(memory_state)
  s.mems.get(s.curr.name).unwrap_or(empty_bank())
}

///|
fn Memory::put_curr(m : Machine, bank : Bank) -> Unit {
  m.update_local(memory_state, s => {
    ..s,
    mems: s.mems.add(s.curr.name, bank),
  })
}

///|
fn target_endian(m : Machine) -> @bitvec.Endian {
  match m.target().endianness() {
    BigEndian => BigEndian
    _ => LittleEndian
  }
}

///|
fn read_small(
  mem : @memory.Memory,
  addr : UInt64,
  size : Int,
) -> @types.Word raise {
  let off_bits = (addr - mem.min_addr()) * size.to_uint64()
  let full = off_bits / 8UL
  let bit_off = (off_bits % 8UL).to_int()
  let leftover = mem.length() - full.to_int()
  let len = if leftover < 2 { leftover } else { 2 }
  let from = mem.min_addr() + full
  let mut vec = @types.Word::zero(width=len * 8)
  for i in 0..<len {
    let b = mem.get_exn(addr=from + i.to_uint64())
    vec = vec.lshift(8).logor(b.widen(width=len * 8))
  }
  let hi = len * 8 - bit_off - 1
  let lo = hi - size + 1
  vec.extract(hi~, lo~)
}

///|
/// Reads `size` bits of static memory at `base` (upstream `read_word`).
fn read_word(
  mem : @memory.Memory,
  base : @types.Word,
  size : Int,
) -> @types.Word raise {
  let b = addr_to_u64(base).unwrap_or(0UL)
  if size < 8 {
    return read_small(mem, b, size)
  }
  let little = mem.endian() is LittleEndian
  let start = if little { b + (size / 8 - 1).to_uint64() } else { b }
  let mut addr = start
  let mut left = size
  let mut acc : @types.Word? = None
  while left > 0 {
    let data = mem.get_exn(addr~)
    let piece = if left <= 8 { data.extract(hi=7, lo=8 - left) } else { data }
    acc = match acc {
      None => Some(piece)
      Some(hi) => Some(hi.concat(piece))
    }
    left -= 8
    addr = if little { addr - 1UL } else { addr + 1UL }
  }
  acc.unwrap()
}

///|
/// Stores a generated word byte-by-byte without overwriting existing cells
/// (upstream `store_word`/`remembered`). Upstream shifts the word *left*
/// between bytes (which makes all but the first byte zero); this port
/// shifts right, spreading the generated bytes over the cells.
fn Memory::remember(
  m : Machine,
  bank : Bank,
  addr : @types.Word,
  word : @types.Word,
) -> Value raise {
  let bytesize = Memory::memory(m).data_size
  let bytes = (word.bitwidth() + bytesize - 1) / bytesize
  let little = target_endian(m) is LittleEndian
  let mut key = if little { addr } else { addr.nsucc(bytes - 1) }
  let mut w = word
  let mut values = bank.values
  for _ in 0..<bytes {
    let chunk = if w.bitwidth() > bytesize {
      w.extract(hi=bytesize - 1, lo=0)
    } else {
      @types.Word::create(w.to_bitvec(), bytesize)
    }
    let data = Value::of_word(m, chunk)
    if !values.contains(AddrKey(key)) {
      m.make(load_generated_stmt, (key, data))
      values = values.add(AddrKey(key), data)
    }
    key = if little { key.succ() } else { key.pred() }
    w = w.rshift(bytesize)
  }
  Memory::put_curr(m, { ..bank, values, })
  values.get(AddrKey(addr)).unwrap()
}

///|
fn raise_pagefault(m : Machine, addr : @types.Word) -> Value raise {
  m.raise_exn(Pagefault(addr))
}

///|
/// Reads a memory cell (`Memory.get`): the stored value if any, otherwise
/// the value of the layer that maps the address (static bytes or a value
/// produced by the region generator). Raises `Pagefault` for unmapped
/// addresses.
pub fn Memory::get(m : Machine, addr : @types.Word) -> Value raise {
  let bank = Memory::get_curr(m)
  match bank.values.get(AddrKey(addr)) {
    Some(v) => v
    None =>
      match find_layer(bank.layers, addr) {
        None => raise_pagefault(m, addr)
        Some(layer) =>
          match layer.mem {
            Static(mem) => {
              let size = Memory::memory(m).data_size
              let w = read_word(mem, addr, size) catch {
                _ => return raise_pagefault(m, addr)
              }
              Value::of_word(m, w)
            }
            Dynamic(_, _, g) => {
              let w = Generator::word(m, g, g.width())
              Memory::remember(m, bank, addr, w)
            }
          }
      }
  }
}

///|
/// Writes a memory cell (`Memory.set`). Raises `Pagefault` if the address
/// is not mapped or belongs to a read-only region. Unlike upstream, a cell
/// that already holds a value (initialized or generated) in a read-only
/// region is still read-only; cells written with `set_never_fail` outside
/// of any region stay writable.
pub fn Memory::set(m : Machine, addr : @types.Word, x : Value) -> Unit raise {
  let bank = Memory::get_curr(m)
  match find_layer(bank.layers, addr) {
    Some(l) if l.read_only => ignore(raise_pagefault(m, addr))
    Some(_) => ()
    None =>
      if !bank.values.contains(AddrKey(addr)) {
        ignore(raise_pagefault(m, addr))
      }
  }
  Memory::put_curr(m, { ..bank, values: bank.values.add(AddrKey(addr), x), })
}

///|
/// Writes a memory cell ignoring permissions (`Memory.set_never_fail`).
pub fn Memory::set_never_fail(
  m : Machine,
  addr : @types.Word,
  x : Value,
) -> Unit {
  let bank = Memory::get_curr(m)
  Memory::put_curr(m, { ..bank, values: bank.values.add(AddrKey(addr), x), })
}

///|
/// Forgets the value of a memory cell (`Memory.del`).
pub fn Memory::del(m : Machine, addr : @types.Word) -> Unit {
  let bank = Memory::get_curr(m)
  Memory::put_curr(m, { ..bank, values: bank.values.remove(AddrKey(addr)), })
}

///|
/// Reads a memory cell as a word (`Memory.load`).
pub fn Memory::load(m : Machine, addr : @types.Word) -> @types.Word raise {
  Memory::get(m, addr).value
}

///|
/// Writes a word to a memory cell (`Memory.store`).
pub fn Memory::store(
  m : Machine,
  addr : @types.Word,
  w : @types.Word,
) -> Unit raise {
  Memory::set(m, addr, Value::of_word(m, w))
}

///|
/// Writes a word ignoring permissions (`Memory.store_never_fail`).
pub fn Memory::store_never_fail(
  m : Machine,
  addr : @types.Word,
  w : @types.Word,
) -> Unit {
  Memory::set_never_fail(m, addr, Value::of_word(m, w))
}

///|
fn Memory::add_layer(m : Machine, layer : Layer) -> Bank {
  let bank = Memory::get_curr(m)
  { ..bank, layers: bank.layers.prepend(layer), }
}

///|
/// Maps a dynamic region `[lower, upper]` (`Memory.add_region`). Reads of
/// unset cells produce values from `generator` (by default a seeded
/// pseudorandom generator of the target width); `init`, when given,
/// initializes every cell of `[lower, upper]` (upstream initializes
/// `[lower, upper)`, so a one-cell allocation was never initialized).
pub fn Memory::add_region(
  m : Machine,
  read_only? : Bool = false,
  executable? : Bool = false,
  init? : (@types.Word) -> @types.Word raise,
  generator? : Generator,
  lower~ : @types.Word,
  upper~ : @types.Word,
) -> Unit raise {
  let width = target_bits(m.target())
  let gen = match generator {
    Some(g) => g
    None => Generator::seeded_lcg(width~)
  }
  let bank = Memory::add_layer(m, {
    mem: Dynamic(lower, upper, gen),
    read_only,
    executable,
  })
  match init {
    None => Memory::put_curr(m, bank)
    Some(f) => {
      let mut values = bank.values
      let mut addr = lower
      for ;; {
        values = values.add(AddrKey(addr), Value::of_word(m, f(addr)))
        if addr.compare(upper) == 0 {
          break
        }
        addr = addr.succ()
      }
      Memory::put_curr(m, { ..bank, values, })
    }
  }
}

///|
/// Allocates `len` cells starting at `base` (`Memory.allocate`).
pub fn Memory::allocate(
  m : Machine,
  read_only? : Bool = false,
  executable? : Bool = false,
  init? : (@types.Word) -> @types.Word raise,
  generator? : Generator,
  base : @types.Word,
  len : Int,
) -> Unit raise {
  Memory::add_region(
    m,
    read_only~,
    executable~,
    init?,
    generator?,
    lower=base,
    upper=base.nsucc(len - 1),
  )
}

///|
/// Maps a static memory chunk (`Memory.map`).
pub fn Memory::map(
  m : Machine,
  read_only? : Bool = false,
  executable? : Bool = false,
  mem : @memory.Memory,
) -> Unit {
  Memory::put_curr(
    m,
    Memory::add_layer(m, { mem: Static(mem), read_only, executable, }),
  )
}

///|
/// Maps a read-only executable chunk (`Memory.add_text`).
pub fn Memory::add_text(m : Machine, mem : @memory.Memory) -> Unit {
  Memory::map(m, read_only=true, executable=true, mem)
}

///|
/// Maps a writable data chunk (`Memory.add_data`).
pub fn Memory::add_data(m : Machine, mem : @memory.Memory) -> Unit {
  Memory::map(m, read_only=false, executable=false, mem)
}

///|
/// Whether the address is mapped (`Memory.is_mapped`).
pub fn Memory::is_mapped(m : Machine, addr : @types.Word) -> Bool {
  let bank = Memory::get_curr(m)
  bank.values.contains(AddrKey(addr)) ||
  find_layer(bank.layers, addr) is Some(_)
}

///|
/// Whether the address is writable (`Memory.is_writable`).
pub fn Memory::is_writable(m : Machine, addr : @types.Word) -> Bool {
  let bank = Memory::get_curr(m)
  match find_layer(bank.layers, addr) {
    Some(l) => !l.read_only
    None => bank.values.contains(AddrKey(addr))
  }
}

///|
/// Renders the memory state of the current machine.
pub fn Memory::inspect(m : Machine) -> Sexp {
  memory_to_sexp(m.get_local(memory_state))
}
