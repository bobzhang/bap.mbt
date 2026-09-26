// Port of BAP `plugins/powerpc/powerpc_model.ml`: the register file of the
// 32- and 64-bit PowerPC models.

///|
/// Address size of a PowerPC model.
pub(all) enum AddrSize {
  R32
  R64
} derive(Eq, Debug)

///|
pub extend AddrSize with Eq::{equal, not_equal}

///|
pub extend AddrSize with Debug::{to_repr}

///|
pub fn AddrSize::in_bits(self : AddrSize) -> Int {
  match self {
    R32 => 32
    R64 => 64
  }
}

///|
/// Registers of a PowerPC model (the `PowerPC` module type of upstream).
pub struct Model {
  addr_size : AddrSize
  gpr_bitwidth : Int
  fpr_bitwidth : Int
  lr_bitwidth : Int
  ctr_bitwidth : Int
  tar_bitwidth : Int
  cr_bitwidth : Int
  vr_bitwidth : Int
  /// general purpose registers by name (`R0`..`R31`, aliased as `X0`..`X31`)
  gpr : Map[String, @types.Var]
  /// general purpose registers by number
  gpri : Array[@types.Var]
  /// floating point registers by name (`F0`..`F31`)
  fpr : Map[String, @types.Var]
  fpri : Array[@types.Var]
  /// vector registers by name (`VR0`..`VR31`)
  vr : Map[String, @types.Var]
  vri : Array[@types.Var]
  /// count register
  ctr : @types.Var
  /// link register
  lr : @types.Var
  /// target register
  tar : @types.Var
  /// condition register bits, starting from the most significant one:
  /// `cri[0]` is `CR0LT`, `cri[31]` is `CR7UN`
  cri : Array[@types.Var]
  /// condition register bits by name (`CR0LT`, `CR0GT`, ...)
  crn : Map[String, @types.Var]
  /// condition register fields (`CR0`..`CR7`), each as the bits
  /// `[LT, GT, EQ, UN]` (most significant first)
  cr_fields : Map[String, Array[@types.Var]]
  cri_fields : Array[Array[@types.Var]]
  /// summary overflow
  so : @types.Var
  /// carry
  ca : @types.Var
  /// overflow
  ov : @types.Var
  /// carry out of the low-order 32 bits
  ca32 : @types.Var
  /// overflow of the low-order 32 bits
  ov32 : @types.Var
  /// FPRF result class descriptor
  float_c : @types.Var
  /// FPRF less than or negative
  float_less : @types.Var
  /// FPRF equal or zero
  float_equal : @types.Var
  /// FPRF greater than or positive
  float_greater : @types.Var
  /// FPRF unordered or NaN
  float_unordered : @types.Var
  mem : @types.Var
  /// `so`, `ca`, `ca32`, `ov`, `ov32` and the first three CR bits
  flags : Array[@types.Var]
}

///|
fn flag(name : String) -> @types.Var {
  @types.Var::new(name~, typ=Imm(1))
}

///|
fn make_model(addr_size : AddrSize) -> Model {
  let gpr_bitwidth = addr_size.in_bits()
  let fpr_bitwidth = 64
  let vr_bitwidth = 128
  let reg = (prefix : String, width : Int, i : Int) => {
    @types.Var::new(name="\{prefix}\{i}", typ=Imm(width))
  }
  let gpri = Array::makei(32, i => reg("R", gpr_bitwidth, i))
  let gpr : Map[String, @types.Var] = Map([])
  for i, v in gpri {
    gpr[v.name] = v
    gpr["X\{i}"] = v
  }
  let fpri = Array::makei(32, i => reg("F", fpr_bitwidth, i))
  let fpr : Map[String, @types.Var] = Map([])
  for v in fpri {
    fpr[v.name] = v
  }
  let vri = Array::makei(32, i => reg("VR", vr_bitwidth, i))
  let vr : Map[String, @types.Var] = Map([])
  for v in vri {
    vr[v.name] = v
  }
  // condition register bits: field n occupies bits 4n..4n+3 (msb first)
  let suffixes = ["LT", "GT", "EQ", "UN"]
  let cri = Array::makei(32, i => flag("CR\{i / 4}\{suffixes[i % 4]}"))
  let crn : Map[String, @types.Var] = Map([])
  for v in cri {
    crn[v.name] = v
  }
  let cri_fields = Array::makei(8, n => Array::makei(4, k => cri[4 * n + k]))
  let cr_fields : Map[String, Array[@types.Var]] = Map([])
  for n, field in cri_fields {
    cr_fields["CR\{n}"] = field
  }
  let so = flag("SO")
  let ca = flag("CA")
  let ov = flag("OV")
  let ca32 = flag("CA32")
  let ov32 = flag("OV32")
  {
    addr_size,
    gpr_bitwidth,
    fpr_bitwidth,
    lr_bitwidth: gpr_bitwidth,
    ctr_bitwidth: gpr_bitwidth,
    tar_bitwidth: gpr_bitwidth,
    cr_bitwidth: 32,
    vr_bitwidth,
    gpr,
    gpri,
    fpr,
    fpri,
    vr,
    vri,
    ctr: @types.Var::new(name="CTR", typ=Imm(gpr_bitwidth)),
    lr: @types.Var::new(name="LR", typ=Imm(gpr_bitwidth)),
    tar: @types.Var::new(name="TAR", typ=Imm(gpr_bitwidth)),
    cri,
    crn,
    cr_fields,
    cri_fields,
    so,
    ca,
    ov,
    ca32,
    ov32,
    float_c: flag("C"),
    float_less: flag("FL"),
    float_equal: flag("FE"),
    float_greater: flag("FG"),
    float_unordered: flag("FU"),
    mem: @types.Var::new(
      name="mem",
      typ=Mem(addr_width=gpr_bitwidth, value_width=8),
    ),
    flags: [so, ca, ca32, ov, ov32, cri[0], cri[1], cri[2]],
  }
}

///|
let model32 : Model = make_model(R32)

///|
let model64 : Model = make_model(R64)

///|
/// The 32-bit PowerPC model (`PowerPC_32`).
pub fn Model::ppc32() -> Model {
  model32
}

///|
/// The 64-bit PowerPC model (`PowerPC_64`).
pub fn Model::ppc64() -> Model {
  model64
}

///|
/// Model for the given address size.
pub fn Model::of_addr_size(addr_size : AddrSize) -> Model {
  match addr_size {
    R32 => model32
    R64 => model64
  }
}

///|
/// Condition register as the concatenation of all its bits.
pub fn Model::cr(self : Model) -> RtlExp {
  RtlExp::of_vars(self.cri)
}

///|
/// Condition register field `n` (0..7) as an expression.
pub fn Model::cr_field(self : Model, n : Int) -> RtlExp {
  RtlExp::of_vars(self.cri_fields[n])
}

// CPU predicates (`PowerPC_32_cpu` / `PowerPC_64_cpu`).

///|
/// Stack pointer (`R1`).
pub fn Model::sp(self : Model) -> @types.Var {
  self.gpri[1]
}

///|
/// Zero flag of the generic CPU interface (upstream uses `cri[1]`).
pub fn Model::zf(self : Model) -> @types.Var {
  self.cri[1]
}

///|
/// Negative flag of the generic CPU interface (`cri[0]`).
pub fn Model::nf(self : Model) -> @types.Var {
  self.cri[0]
}

///|
/// Carry flag of the generic CPU interface (`CA`).
pub fn Model::cf(self : Model) -> @types.Var {
  self.ca
}

///|
/// Overflow flag of the generic CPU interface (`OV`).
pub fn Model::vf(self : Model) -> @types.Var {
  self.ov
}

///|
/// Flags of the generic CPU interface.
pub fn Model::cpu_flags(self : Model) -> Array[@types.Var] {
  [self.so, self.ca, self.ov, self.nf(), self.zf(), self.ca32, self.ov32]
}

///|
pub fn Model::is_reg(self : Model, v : @types.Var) -> Bool {
  self.gpri.contains(v.base())
}

///|
pub fn Model::is_flag(self : Model, v : @types.Var) -> Bool {
  self.cpu_flags().contains(v.base())
}

///|
pub fn Model::is_zf(self : Model, v : @types.Var) -> Bool {
  v.same(self.zf())
}

///|
pub fn Model::is_cf(self : Model, v : @types.Var) -> Bool {
  v.same(self.ca)
}

///|
pub fn Model::is_vf(self : Model, v : @types.Var) -> Bool {
  v.same(self.ov)
}

///|
pub fn Model::is_nf(self : Model, v : @types.Var) -> Bool {
  v.same(self.nf())
}

///|
pub fn Model::is_mem(self : Model, v : @types.Var) -> Bool {
  v.same(self.mem)
}

///|
pub fn Model::is_sp(self : Model, v : @types.Var) -> Bool {
  v.same(self.sp())
}

///|
/// PowerPC has no dedicated base pointer.
pub fn Model::is_bp(_self : Model, _v : @types.Var) -> Bool {
  false
}
