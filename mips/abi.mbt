// Portable part of BAP `plugins/mips/mips_abi.ml`: the GNU C calling
// convention parameters. Upstream installs them through the `Bap_c`
// argument-passing DSL (not ported); here they are exposed as data.

///|
/// C data model used by the MIPS GNU ABI.
pub(all) enum DataModel {
  ILP32
  ILP64
} derive(Eq, Debug)

///|
pub extend DataModel with Eq::{equal, not_equal}

///|
pub extend DataModel with Debug::{to_repr}

///|
/// GNU C calling convention of a MIPS target.
pub(all) struct CallingConvention {
  /// `ILP32` on 32-bit targets, `ILP64` on 64-bit ones.
  data_model : DataModel
  /// Integer argument registers: GPRs 4..7 (`A0..A3`) or 4..11
  /// (`A0..T3`), upstream's `R4..`.
  int_args : Array[@types.Var]
  /// Floating point argument registers: `F1..F4` (4) or `F1..F8` (8).
  float_args : Array[@types.Var]
  /// On 32-bit (o32) targets integer arguments also deplete the floating
  /// point arena, floating point arguments are aligned to an even register
  /// and consume `size / 32` integer registers.
  float_args_shadow_int_args : Bool
  /// Bit widths of C `float`, `double` and `long double`.
  float_bits : Int
  double_bits : Int
  long_double_bits : Int
} derive(Eq, Debug)

///|
pub extend CallingConvention with Eq::{equal, not_equal}

///|
pub extend CallingConvention with Debug::{to_repr}

///|
/// The GNU C calling convention (`Mips_abi.define`) for `self`.
pub fn Arch::gnu_calling_convention(self : Arch) -> CallingConvention {
  let is_old = self is Mips32
  let regs = if is_old { 4 } else { 8 }
  let int_args : Array[@types.Var] = []
  let float_args : Array[@types.Var] = []
  for i in 0..<regs {
    if self.gpr(4 + i) is Some(v) {
      int_args.push(v)
    }
    if self.fpr(1 + i) is Some(v) {
      float_args.push(v)
    }
  }
  {
    data_model: if is_old {
      ILP32
    } else {
      ILP64
    },
    int_args,
    float_args,
    float_args_shadow_int_args: is_old,
    float_bits: 32,
    double_bits: 64,
    long_double_bits: 64,
  }
}
