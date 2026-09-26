// Port of BAP `plugins/x86/x86_utils.ml`: register selection, effective
// addresses, flag lists and other helpers of the legacy decoder and lifter.

///|
fn Imm::new(bits : UInt64, width : Int, signed? : Bool = false) -> Imm {
  { bits: bits & mask64(width), width, signed, }
}

///|
/// Upstream `Word.signed`.
fn Imm::as_signed(self : Imm) -> Imm {
  { ..self, signed: true, }
}

///|
/// The value as a (sign- or zero-extended) 64-bit integer.
fn Imm::to_int64(self : Imm) -> Int64 {
  if self.signed && self.width < 64 && self.width > 0 {
    let shift = 64 - self.width
    self.bits.reinterpret_as_int64() << shift >> shift
  } else {
    self.bits.reinterpret_as_int64()
  }
}

///|
/// Upstream `resize_word v width` (`Word.extract_exn ~hi:(width - 1)`):
/// signed words are sign-extended, unsigned ones zero-extended; the result
/// is unsigned. Only widths up to 64 bits are represented.
fn Imm::resize(self : Imm, width : Int) -> Imm {
  Imm::new(self.to_int64().reinterpret_as_uint64(), width)
}

///|
/// `Bil.Int (resize_word i width)` for any width.
fn Imm::to_exp(self : Imm, width : Int) -> @types.Exp {
  if width <= 64 {
    Int(word_of_uint64(self.resize(width).bits, width))
  } else {
    int64_exp(self.to_int64(), width)
  }
}

///|
let general_protection : @types.Stmt = CpuExn(0xd)

///|
let divide_by_zero : @types.Stmt = CpuExn(0x0)

///|
/// Upstream `compute_segment_bases` (never enabled by the plugin): when set,
/// moves into FS and GS also recompute FS_BASE and GS_BASE from the
/// descriptor tables.
let compute_segment_bases : Ref[Bool] = Ref(false)

///|
/// Upstream `df_to_offset`: `1` or `-1` depending on the direction flag.
fn df_to_offset(mode : Mode, e : @types.Exp) -> @types.Exp {
  let t = mode.width()
  e_ite(e_eq(e, exp_false), int_exp(1, t), int_exp(-1, t))
}

///|
/// Upstream `bap_to_rflags`: the expressions of the RFLAGS bits, from bit
/// 63 down to bit 0.
let bap_to_rflags : ReadOnlyArray[@types.Exp] = {
  let undefined = (d : Int) => e_unknown("Undefined RFLAGS bit \{d}", 1)
  let unmodeled = (s : String) => e_unknown("Unmodeled RFLAGS bit " + s, 1)
  let bits : Array[@types.Exp] = []
  for d = 63; d >= 22; d = d - 1 {
    bits.push(undefined(d))
  }
  bits.push(unmodeled("ID")) // 21
  bits.push(unmodeled("VIP")) // 20
  bits.push(unmodeled("VIF")) // 19
  bits.push(unmodeled("AC")) // 18
  bits.push(unmodeled("VM")) // 17
  bits.push(unmodeled("RF")) // 16
  bits.push(undefined(15))
  bits.push(unmodeled("NT")) // 14
  bits.push(unmodeled("IOPL1")) // 13
  bits.push(unmodeled("IOPL2")) // 12
  bits.push(ev(of_)) // 11
  bits.push(ev(df)) // 10
  bits.push(unmodeled("IF")) // 9
  bits.push(unmodeled("TF")) // 8
  bits.push(ev(sf)) // 7
  bits.push(ev(zf)) // 6
  bits.push(undefined(5))
  bits.push(ev(af)) // 4
  bits.push(undefined(3))
  bits.push(ev(pf)) // 2
  bits.push(undefined(1))
  bits.push(ev(cf)) // 0
  ReadOnlyArray::from_array(bits)
}

///|
/// Upstream `rflags_to_bap`: the flag variable assigned from each RFLAGS
/// bit, from bit 63 down to bit 0.
let rflags_to_bap : ReadOnlyArray[@types.Var?] = [
  for i in 0..<64 => {
    match 63 - i {
      11 => Some(of_)
      10 => Some(df)
      7 => Some(sf)
      6 => Some(zf)
      4 => Some(af)
      2 => Some(pf)
      0 => Some(cf)
      _ => None
    }
  }
]

///|
/// The concatenation of the low `width` bits of RFLAGS (upstream
/// `rflags_e`, `eflags_e`, `flags_e` and `lflags_e`).
fn flags_exp(width : Int) -> @types.Exp raise X86Error {
  concat_explist(bap_to_rflags[64 - width:])
}

///|
/// Assignments of the flags from the bits of `e` (a `width`-bit value, bits
/// from `width - 1` down to 0), upstream `assns_*flags_to_bap`.
fn flags_assignments(width : Int, e : @types.Exp) -> Array[@types.Stmt] {
  let assns = rflags_to_bap[64 - width:]
  let result : Array[@types.Stmt] = []
  for k, flag in assns {
    if flag is Some(v) {
      let bit = width - 1 - k
      result.push(assign(v, e_extract(bit, bit, e)))
    }
  }
  result
}

///|
/// Upstream `load_s`.
fn load_s(
  mode : Mode,
  seg : @types.Var?,
  width : Int,
  addr : @types.Exp,
) -> @types.Exp raise X86Error {
  let mem = vars_of_mode(mode).mem
  match seg {
    None => e_load(mem, addr, width)
    Some(v) => e_load(mem, e_plus(ev(v), addr), width)
  }
}

///|
/// Upstream `store_s`.
fn store_s(
  mode : Mode,
  seg : @types.Var?,
  width : Int,
  addr : @types.Exp,
  e : @types.Exp,
) -> @types.Stmt raise X86Error {
  let mem = vars_of_mode(mode).mem
  match seg {
    None => store_stmt(mem, addr, width, e)
    Some(v) => store_stmt(mem, e_plus(ev(v), addr), width, e)
  }
}

///|
/// Upstream `lowbits2elemt`: element size from the low opcode bits.
fn lowbits2elemt(b : Int) -> Int {
  match b & 3 {
    0 => 8
    1 => 16
    2 => 32
    _ => 64
  }
}

///|
/// Upstream `bits2genreg`: the register variable of a register number.
fn bits2genreg(mode : Mode, b : Int) -> @types.Var raise X86Error {
  let r = vars_of_mode(mode)
  match b {
    0 => r.rax
    1 => r.rcx
    2 => r.rdx
    3 => r.rbx
    4 => r.rsp
    5 => r.rbp
    6 => r.rsi
    7 => r.rdi
    _ =>
      match r.r.get(b - 8) {
        Some(v) if b >= 8 => v
        _ => raise ArchException("bits2genreg takes 4 bits")
      }
  }
}

///|
fn bits2segreg(b : Int) -> @types.Var raise X86Error {
  match b {
    0 => seg_es
    1 => seg_cs
    2 => seg_ss
    3 => seg_ds
    4 => seg_fs
    5 => seg_gs
    6 | 7 => raise ArchException("bits2segreg: reserved")
    _ => raise ArchException("bits2regseg: invalid")
  }
}

///|
fn bits2ymm(mode : Mode, b : Int) -> @types.Var raise X86Error {
  match vars_of_mode(mode).ymms.get(b) {
    Some(v) => v
    None => raise ArchException("invalid vector register \{b}")
  }
}

///|
fn bits2reg64e(mode : Mode, b : Int) -> @types.Exp raise X86Error {
  ev(bits2genreg(mode, b))
}

///|
fn bits2reg32e(mode : Mode, b : Int) -> @types.Exp raise X86Error {
  e_low(32, ev(bits2genreg(mode, b)))
}

///|
fn bits2reg16e(mode : Mode, b : Int) -> @types.Exp raise X86Error {
  e_low(16, bits2reg32e(mode, b))
}

///|
fn bits2reg8e(
  mode : Mode,
  b : Int,
  has_rex? : Bool = false,
) -> @types.Exp raise X86Error {
  if b < 4 || has_rex {
    e_low(8, bits2reg32e(mode, b))
  } else {
    e_high(8, e_low(16, bits2reg32e(mode, b & 3)))
  }
}

///|
/// Upstream `eaddr16`: effective addresses of the 16-bit addressing mode.
fn eaddr16(mode : Mode, rm : Int) -> @types.Exp raise X86Error {
  let r = vars_of_mode(mode)
  let e = (v : @types.Var) => e_low(16, ev(v))
  match rm {
    0 => e_plus(e(r.rbx), e(r.rsi))
    1 => e_plus(e(r.rbx), e(r.rdi))
    2 => e_plus(e(r.rbp), e(r.rsi))
    3 => e_plus(e(r.rbp), e(r.rdi))
    4 => e(r.rsi)
    5 => e(r.rdi)
    6 => e(r.rbp)
    7 => e(r.rbx)
    _ => raise ArchException("eaddr16 takes only 0-7")
  }
}
