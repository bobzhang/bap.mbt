// Port of BAP `plugins/mips/mips_model.ml`: the MIPS register model.

///|
/// MIPS register-file flavour: 32-bit (`mips`/`mipsel`) or 64-bit
/// (`mips64`/`mips64el`) general purpose registers.
pub(all) enum Arch {
  Mips32
  Mips64
} derive(Eq, Debug)

///|
pub extend Arch with Eq::{equal, not_equal}

///|
pub extend Arch with Debug::{to_repr}

///|
let gpr_names : ReadOnlyArray[String] = [
  "ZERO", "AT", "V0", "V1", "A0", "A1", "A2", "A3", "T0", "T1", "T2", "T3", "T4",
  "T5", "T6", "T7", "S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7", "T8", "T9", "K0",
  "K1", "GP", "SP", "FP", "RA",
]

///|
/// Width of general purpose registers (and of `HI`/`LO`).
pub fn Arch::gpr_bitwidth(self : Arch) -> Int {
  match self {
    Mips32 => 32
    Mips64 => 64
  }
}

///|
/// Width of floating point registers (always 64 upstream).
pub fn Arch::fpr_bitwidth(_ : Arch) -> Int {
  64
}

///|
/// Address width of the memory variable.
pub fn Arch::addr_bitwidth(self : Arch) -> Int {
  self.gpr_bitwidth()
}

///|
/// General purpose register number `index` (0..31), e.g. `gpr(29)` is `SP`.
pub fn Arch::gpr(self : Arch, index : Int) -> @types.Var? {
  match gpr_names.get(index) {
    Some(name) => Some(@types.Var::new(name~, typ=Imm(self.gpr_bitwidth())))
    None => None
  }
}

///|
/// Look up a general purpose register by an LLVM-style name: the ABI name
/// (`T0`), the numeric alias (`R8`), and on MIPS64 also the `_64` suffixed
/// name (`T0_64`).
pub fn Arch::find_gpr(self : Arch, name : String) -> @types.Var? {
  for i, reg in gpr_names {
    if name == reg || name == "R\{i}" || (self is Mips64 && name == reg + "_64") {
      return self.gpr(i)
    }
  }
  None
}

///|
/// Floating point register number `index` (0..31), named `F<index>`.
pub fn Arch::fpr(self : Arch, index : Int) -> @types.Var? {
  if index >= 0 && index < 32 {
    Some(@types.Var::new(name="F\{index}", typ=Imm(self.fpr_bitwidth())))
  } else {
    None
  }
}

///|
/// Look up a floating point register by name (`F0`..`F31`).
pub fn Arch::find_fpr(self : Arch, name : String) -> @types.Var? {
  for i in 0..<32 {
    if name == "F\{i}" {
      return self.fpr(i)
    }
  }
  None
}

///|
pub fn Arch::hi(self : Arch) -> @types.Var {
  @types.Var::new(name="HI", typ=Imm(self.gpr_bitwidth()))
}

///|
pub fn Arch::lo(self : Arch) -> @types.Var {
  @types.Var::new(name="LO", typ=Imm(self.gpr_bitwidth()))
}

///|
/// The byte-addressed memory variable `mem`.
pub fn Arch::mem(self : Arch) -> @types.Var {
  @types.Var::new(
    name="mem",
    typ=Mem(addr_width=self.addr_bitwidth(), value_width=8),
  )
}

///|
/// All general purpose registers, in register-number order.
pub fn Arch::gprs(self : Arch) -> Array[@types.Var] {
  Array::makei(32, i => {
    @types.Var::new(name=gpr_names[i], typ=Imm(self.gpr_bitwidth()))
  })
}

///|
/// Stack pointer (`SP`, register 29).
pub fn Arch::sp(self : Arch) -> @types.Var {
  @types.Var::new(name="SP", typ=Imm(self.gpr_bitwidth()))
}

///|
/// Frame pointer (`FP`, register 30).
pub fn Arch::fp(self : Arch) -> @types.Var {
  @types.Var::new(name="FP", typ=Imm(self.gpr_bitwidth()))
}

///|
/// `CPU.is_reg`: whether `v` is one of the general purpose registers.
pub fn Arch::is_reg(self : Arch, v : @types.Var) -> Bool {
  self.gprs().contains(v.base())
}

///|
/// `CPU.is_sp`.
pub fn Arch::is_sp(self : Arch, v : @types.Var) -> Bool {
  v.same(self.sp())
}

///|
/// `CPU.is_bp`: the frame pointer.
pub fn Arch::is_bp(self : Arch, v : @types.Var) -> Bool {
  v.same(self.fp())
}

///|
/// `CPU.is_mem`.
pub fn Arch::is_mem(self : Arch, v : @types.Var) -> Bool {
  v.same(self.mem())
}

///|
/// `CPU.is_flag`: MIPS has no flags, so this is always false.
pub fn Arch::is_flag(_ : Arch, _ : @types.Var) -> Bool {
  false
}
