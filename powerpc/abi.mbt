// Portable part of BAP `plugins/powerpc/powerpc_abi.ml`: the System V
// calling convention of 32-bit PowerPC (GNU ABI, ILP32 data model).
//
// Upstream expresses the convention in the `Bap_c` argument-passing
// language; this port keeps the same selection rules over explicit register
// arenas (the register roles of `bap_powerpc_target.ml`).

///|
/// Classification of a C value for argument passing.
pub(all) enum AbiValue {
  /// integers, pointers and aggregates of the given size in bits
  Integral(Int)
  /// floating-point values of the given size in bits
  Floating(Int)
} derive(Eq, Debug)

///|
pub extend AbiValue with Eq::{equal, not_equal}

///|
pub extend AbiValue with Debug::{to_repr}

///|
/// Where a value is passed.
pub(all) enum AbiLocation {
  /// in the given (consecutive) registers
  Registers(Array[String])
  /// by address, the pointer being passed in the given register
  Pointer(String)
  /// returned through a hidden reference passed in the given register
  Reference(String)
  /// on the stack
  Memory
} derive(Eq, Debug)

///|
pub extend AbiLocation with Eq::{equal, not_equal}

///|
pub extend AbiLocation with Debug::{to_repr}

///|
/// Result of applying the calling convention to a function prototype.
pub struct AbiLayout {
  args : Array[AbiLocation]
  ret : AbiLocation?
} derive(Eq, Debug)

///|
pub extend AbiLayout with Eq::{equal, not_equal}

///|
pub extend AbiLayout with Debug::{to_repr}

///|
/// Register arenas of the 32-bit System V convention.
pub struct Sysv32Abi {
  /// integer argument registers (`R3`..`R10`)
  int_args : Array[String]
  /// floating-point argument registers (`F1`..`F8`)
  float_args : Array[String]
  /// integer return registers (`R3`, `R4`)
  int_rets : Array[String]
  /// floating-point return registers (`F0`)
  float_rets : Array[String]
  /// width of general purpose registers
  gpr_bits : Int
  /// width of floating point registers
  fpr_bits : Int
}

///|
/// The System V ABI of 32-bit PowerPC.
pub fn Sysv32Abi::new() -> Sysv32Abi {
  {
    int_args: Array::makei(8, i => "R\{i + 3}"),
    float_args: Array::makei(8, i => "F\{i + 1}"),
    int_rets: ["R3", "R4"],
    float_rets: ["F0"],
    gpr_bits: 32,
    fpr_bits: 64,
  }
}

///|
/// Registers needed to hold `bits` in registers of `reg_bits`.
fn registers_needed(bits : Int, reg_bits : Int) -> Int {
  Int::max(1, (bits + reg_bits - 1) / reg_bits)
}

///|
/// Take `count` consecutive registers from `arena`, or `None` when the arena
/// is exhausted.
fn take_registers(
  arena : Array[String],
  next : Ref[Int],
  count : Int,
) -> Array[String]? {
  if next.val + count > arena.length() {
    None
  } else {
    let regs = arena[next.val:next.val + count].to_owned()
    next.val += count
    Some(regs)
  }
}

///|
/// Apply the convention to a prototype. `little_endian` reverses the order
/// of multi-register return values, as upstream's `~rev` flag.
pub fn Sysv32Abi::layout(
  self : Sysv32Abi,
  args : ArrayView[AbiValue],
  ret? : AbiValue,
  little_endian? : Bool = false,
) -> AbiLayout {
  let next_int = Ref(0)
  let next_float = Ref(0)
  let order = (regs : Array[String]) => {
    if little_endian {
      regs.rev()
    } else {
      regs
    }
  }
  // Return values are decided first: a hidden reference consumes the first
  // integer argument register.
  let ret_loc = match ret {
    None => None
    Some(Floating(bits)) => {
      let n = registers_needed(bits, self.fpr_bits)
      if n <= self.float_rets.length() {
        Some(Registers(order(self.float_rets[:n].to_owned())))
      } else {
        None
      }
    }
    Some(Integral(bits)) => {
      let n = registers_needed(bits, self.gpr_bits)
      if n <= self.int_rets.length() {
        Some(Registers(order(self.int_rets[:n].to_owned())))
      } else {
        match take_registers(self.int_args, next_int, 1) {
          Some(regs) => Some(Reference(regs[0]))
          None => None
        }
      }
    }
  }
  let locs = []
  for arg in args {
    let loc = match arg {
      Floating(bits) if bits <= self.fpr_bits =>
        match take_registers(self.float_args, next_float, 1) {
          Some(regs) => Registers(regs)
          None => Memory
        }
      Floating(_) => Memory
      // both the `size > 32` and the default case pass a pointer
      Integral(_) =>
        match take_registers(self.int_args, next_int, 1) {
          Some(regs) => Pointer(regs[0])
          None => Memory
        }
    }
    locs.push(loc)
  }
  { args: locs, ret: ret_loc, }
}
