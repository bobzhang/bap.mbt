// Portable part of upstream `plugins/arm/arm_gnueabi.ml`: the AAPCS32 and
// AAPCS64 argument-passing rules, expressed with the same combinators as
// BAP's C ABI DSL (`Bap_c_abi.Arg`) but computing register/stack locations
// for a prototype instead of BIL argument terms. The installation of the
// ABI into a project (the C-types/Primus pass) is not ported.

///|
/// The classification of a C type that the ARM calling conventions look at.
pub(all) enum CTypeKind {
  /// Integral and enumeration types (`C.Type.is_basic`, not floating).
  Integer
  /// Real and complex floating-point types.
  Floating
  Pointer
  Structure
  Union
  Array
} derive(Eq, Debug)

///|
pub extend CTypeKind with Eq::{equal, not_equal}

///|
pub extend CTypeKind with Debug::{to_repr}

///|
/// A C type reduced to what the calling conventions need: its kind, its
/// size in bits (rounded up to its alignment, as `C.Size.bits` does) and
/// its alignment in bits.
pub(all) struct CType {
  kind : CTypeKind
  bits : Int32
  alignment : Int32
} derive(Eq, Debug)

///|
pub extend CType with Eq::{equal, not_equal}

///|
pub extend CType with Debug::{to_repr}

///|
pub fn CType::new(kind : CTypeKind, bits~ : Int32, alignment? : Int32) -> CType {
  let alignment = match alignment {
    Some(a) => a
    None => bits
  }
  let bits = if alignment > 0 {
    (bits + alignment - 1) / alignment * alignment
  } else {
    bits
  }
  { kind, bits, alignment, }
}

///|
/// A C basic or pointer type of the ARM data models: `ILP32` for AAPCS32
/// and `LP64` for AAPCS64, with `long double` being 64-bit (the ARM
/// `C.Size` override). Recognized names: `char`, `short`, `int`, `long`,
/// `long long`, `enum`, `float`, `double`, `long double`, `pointer`.
pub fn CType::arm_basic(name : String, lp64~ : Bool = false) -> CType? {
  let int = (bits : Int32) => Some(CType::new(Integer, bits~))
  match name {
    "char" | "signed char" | "unsigned char" | "bool" => int(8)
    "short" | "unsigned short" => int(16)
    "int" | "unsigned int" | "enum" => int(32)
    "long" | "unsigned long" => int(if lp64 { 64 } else { 32 })
    "long long" | "unsigned long long" => int(64)
    "float" => Some(CType::new(Floating, bits=32))
    "double" | "long double" => Some(CType::new(Floating, bits=64))
    "pointer" => Some(CType::new(Pointer, bits=if lp64 { 64 } else { 32 }))
    _ => None
  }
}

///|
/// The location of a value passed under the calling convention.
pub(all) enum ArgLocation {
  /// Passed in registers, listed in allocation order.
  Registers(Array[String])
  /// Passed on the stack, `offset` bytes above the stack pointer.
  Stack(offset~ : Int32, bits~ : Int32)
  /// Passed partly in registers and partly on the stack, where the
  /// remaining `bits` start at the stack pointer.
  Split(regs~ : Array[String], bits~ : Int32)
} derive(Eq, Debug)

///|
pub extend ArgLocation with Eq::{equal, not_equal}

///|
pub extend ArgLocation with Debug::{to_repr}

///|
/// The argument layout of a prototype (`C.Abi.args`).
pub(all) struct ArgLayout {
  /// The location of the returned value, `None` for `void` or for values
  /// returned through a hidden reference.
  return_value : ArgLocation?
  /// Parameters in the order computed by the ABI: register (and split)
  /// parameters first, followed by the stack parameters by offset.
  params : Array[ArgLocation]
  /// Hidden arguments, i.e., references to values returned or passed in
  /// memory.
  hidden : Array[ArgLocation]
} derive(Eq, Debug)

///|
pub extend ArgLayout with Eq::{equal, not_equal}

///|
pub extend ArgLayout with Debug::{to_repr}

///|
/// A register file (`Bap_c_abi.File`): registers indexed by their original
/// position, and the width of its registers (`-1` when empty).
priv struct RegFile {
  mut regs : Array[(Int32, String)]
  bits : Int32
}

///|
fn RegFile::create(names : Array[String], bits : Int32) -> RegFile {
  {
    regs: [
      for i, name in names => (i, name)
    ],
    bits: if names.is_empty() {
      -1
    } else {
      bits
    },
  }
}

///|
priv enum Where {
  Return
  Inputs
  Hidden
}

///|
priv struct StackSlot {
  offset : Int32
  bits : Int32
  is_data : Bool
}

///|
priv struct AbiState {
  files : Array[RegFile]
  mut stack : Array[StackSlot]
  mut where_ : Where
  mut ret : ArgLocation?
  mut inputs : Array[ArgLocation]
  mut hidden : Array[ArgLocation]
  min_alignment : Int32
  pointer_bits : Int32
}

///|
fn AbiState::snapshot(self : AbiState) -> AbiState {
  {
    files: [
      for f in self.files => { regs: f.regs.copy(), bits: f.bits, }
    ],
    stack: self.stack.copy(),
    where_: self.where_,
    ret: self.ret,
    inputs: self.inputs.copy(),
    hidden: self.hidden.copy(),
    min_alignment: self.min_alignment,
    pointer_bits: self.pointer_bits,
  }
}

///|
fn AbiState::restore(self : AbiState, saved : AbiState) -> Unit {
  for i, f in saved.files {
    self.files[i].regs = f.regs
  }
  self.stack = saved.stack
  self.where_ = saved.where_
  self.ret = saved.ret
  self.inputs = saved.inputs
  self.hidden = saved.hidden
}

///|
fn AbiState::push_arg(self : AbiState, loc : ArgLocation) -> Unit {
  match self.where_ {
    Return => self.ret = Some(loc)
    Hidden => self.hidden.push(loc)
    Inputs => self.inputs.push(loc)
  }
}

///|
/// `File.popn`: take `n` registers starting at the lowest index.
fn AbiState::popn(self : AbiState, file : Int32, n : Int32) -> Array[String]? {
  let f = self.files[file]
  guard f.regs is [(k, _), ..] else { return None }
  let last = k + n - 1
  guard f.regs.iter().any(r => r.0 == last) else { return None }
  let taken = f.regs.filter(r => r.0 <= last).map(r => r.1)
  f.regs = f.regs.filter(r => r.0 > last)
  Some(taken)
}

///|
fn registers_for_bits(f : RegFile, bits : Int32) -> Int32? {
  if f.bits > 0 {
    Some((bits - 1) / f.bits + 1)
  } else {
    None
  }
}

///|
/// `Arg.register`: a single register wide enough for the value.
fn AbiState::register(self : AbiState, file : Int32, bits : Int32) -> Bool {
  if self.files[file].bits < bits {
    return false
  }
  match self.popn(file, 1) {
    Some(regs) => {
      self.push_arg(Registers(regs))
      true
    }
    None => false
  }
}

///|
/// `Arg.registers`: as many registers as the value needs.
fn AbiState::registers(self : AbiState, file : Int32, t : CType) -> Bool {
  guard registers_for_bits(self.files[file], t.bits) is Some(n) else {
    return false
  }
  match self.popn(file, n) {
    Some(regs) => {
      self.push_arg(Registers(regs))
      true
    }
    None => false
  }
}

///|
/// `Arg.reference`: pass a pointer to the value in a register, as a
/// hidden argument.
fn AbiState::reference(self : AbiState, file : Int32) -> Bool {
  let was = self.where_
  self.where_ = Hidden
  let ok = self.register(file, self.pointer_bits)
  self.where_ = was
  ok
}

///|
/// `File.align`: skip registers so that the next one has an index that is
/// a multiple of `n`.
fn AbiState::align(self : AbiState, file : Int32, n : Int32) -> Bool {
  let f = self.files[file]
  guard f.regs is [(k, _), ..] else { return false }
  let k1 = (k + n - 1) / n * n
  if k == k1 {
    return true
  }
  guard f.regs.iter().any(r => r.0 == k1) && f.regs.iter().any(r => r.0 > k1) else {
    return false
  }
  f.regs = f.regs.filter(r => r.0 >= k1)
  true
}

///|
fn AbiState::deplet(self : AbiState, file : Int32) -> Bool {
  self.files[file].regs = []
  true
}

///|
/// `Stack.append`: allocate a stack slot after the last one.
fn AbiState::append_slot(
  self : AbiState,
  bits : Int32,
  alignment : Int32?,
  is_data : Bool,
) -> Int32 {
  let offset = match self.stack.last() {
    None => 0
    Some(last) => {
      let n = match alignment {
        None => self.min_alignment
        Some(a) if a / 8 > self.min_alignment => a / 8
        Some(_) => self.min_alignment
      }
      let next = last.offset + (last.bits - 1) / 8 + 1
      (next + n - 1) / n * n
    }
  }
  self.stack.push({ offset, bits, is_data, })
  offset
}

///|
/// `Arg.memory`: pass the value on the stack.
fn AbiState::memory(self : AbiState, t : CType) -> Bool {
  // stack parameters are collected from the slots at the end
  self.append_slot(t.bits, Some(t.alignment), true) |> ignore
  true
}

///|
/// `Arg.split_with_memory`: pass the value in the remaining registers and,
/// if they are not enough, the rest at the bottom of the (empty) stack.
fn AbiState::split_with_memory(
  self : AbiState,
  file : Int32,
  t : CType,
) -> Bool {
  let f = self.files[file]
  guard registers_for_bits(f, t.bits) is Some(needed) else { return false }
  let available = f.regs.length()
  if available >= needed {
    match self.popn(file, needed) {
      Some(regs) => {
        self.push_arg(Registers(regs))
        true
      }
      None => false
    }
  } else {
    if !(self.stack.is_empty() && available > 0) {
      return false
    }
    let mbits = t.bits - available * f.bits
    guard self.popn(file, available) is Some(regs) else { return false }
    self.append_slot(mbits, None, false) |> ignore
    self.push_arg(Split(regs~, bits=mbits))
    true
  }
}

///|
/// `Arg.choose`: the first alternative that succeeds.
fn AbiState::choose(
  self : AbiState,
  options : Array[(AbiState) -> Bool],
) -> Bool {
  for option in options {
    let saved = self.snapshot()
    if option(self) {
      return true
    }
    self.restore(saved)
  }
  false
}

///|
/// Run the return rule and the parameter rule for each parameter
/// (`C.Abi.Language.install`), then collect the layout (`reify`).
fn run_abi(
  files : Array[RegFile],
  min_alignment~ : Int32,
  pointer_bits~ : Int32,
  return_type : CType?,
  params : ArrayView[CType],
  return_rule : (AbiState, CType) -> Bool,
  param_rule : (AbiState, CType) -> Bool,
) -> ArgLayout? {
  let st : AbiState = {
    files,
    stack: [],
    where_: Return,
    ret: None,
    inputs: [],
    hidden: [],
    min_alignment,
    pointer_bits,
  }
  if return_type is Some(t) && !return_rule(st, t) {
    return None
  }
  st.where_ = Inputs
  for t in params {
    if !param_rule(st, t) {
      return None
    }
  }
  let memory = st.stack
    .filter(s => s.is_data)
    .map(s => ArgLocation::Stack(offset=s.offset, bits=s.bits))
  Some({
    return_value: st.ret,
    params: [..st.inputs, ..memory],
    hidden: st.hidden,
  })
}

///|
fn names(prefix : String, n : Int32) -> Array[String] {
  [
    for i in 0..<n => "\{prefix}\{i}"
  ]
}

///|
/// The AAPCS32 (`gnueabi`) layout of a prototype on a 32-bit ARM target.
/// Arguments are passed in `R0`-`R3` (64-bit aligned values start at an
/// even register) and then on the stack; values that do not fit in the
/// remaining registers are split between registers and the stack.
/// Returns `None` when the upstream rules reject the prototype.
pub fn aapcs32_layout(
  return_type : CType?,
  params : ArrayView[CType],
) -> ArgLayout? {
  let iargs = 0
  let irets = 1
  let is_basic = (t : CType) => t.kind is (Integer | Floating)
  run_abi(
    [RegFile::create(names("R", 4), 32), RegFile::create(names("R", 2), 32)],
    min_alignment=4,
    pointer_bits=32,
    return_type,
    params,
    (st, t) => {
      if is_basic(t) {
        if t.bits <= 64 {
          st.registers(irets, t)
        } else {
          st.reference(iargs)
        }
      } else if t.bits <= 32 {
        st.register(irets, t.bits)
      } else {
        st.reference(iargs)
      }
    },
    (st, t) => {
      if t.alignment == 64 && !st.align(iargs, 2) {
        return false
      }
      st.choose([st => st.split_with_memory(iargs, t), st => st.memory(t)])
    },
  )
}

///|
/// The AAPCS64 layout of a prototype on a 64-bit ARM target.
///
/// As upstream, the floating-point argument arena is the set of registers
/// that have both the `function_argument` and `floating` roles in the
/// AArch64 target description, which is empty; floating-point values are
/// therefore passed by reference and returned through `X8`.
pub fn aapcs64_layout(
  return_type : CType?,
  params : ArrayView[CType],
) -> ArgLayout? {
  let iargs = 0
  let irets = 1
  let fargs = 2
  let frets = 3
  let x8 = 4
  let is_composite = (t : CType) => t.kind is (Structure | Union)
  run_abi(
    [
      RegFile::create(names("R", 8), 64),
      RegFile::create(names("R", 8), 64),
      RegFile::create([], 64),
      RegFile::create([], 64),
      RegFile::create(["X8"], 64),
    ],
    min_alignment=8,
    pointer_bits=64,
    return_type,
    params,
    (st, t) => {
      if t.kind is Floating {
        st.choose([st => st.registers(frets, t), st => st.reference(x8)])
      } else {
        if t.alignment >= 128 && !st.align(irets, 2) {
          return false
        }
        if t.bits > 128 {
          st.reference(x8)
        } else {
          st.choose([st => st.registers(irets, t), st => st.reference(x8)])
        }
      }
    },
    (st, t) => {
      if t.kind is Floating {
        st.choose([st => st.registers(fargs, t), st => st.reference(iargs)])
      } else {
        if t.alignment >= 128 && !st.align(iargs, 2) {
          return false
        }
        if t.bits > 128 {
          st.reference(iargs)
        } else if is_composite(t) {
          st.choose([st => st.split_with_memory(iargs, t), st => st.memory(t)])
        } else {
          st.choose([
            st => st.registers(iargs, t),
            st => st.deplet(iargs) && st.memory(t),
          ])
        }
      }
    },
  )
}
