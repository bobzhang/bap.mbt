// Port of BAP `plugins/x86/x86_disasm.ml` (part 1): byte access, prefixes,
// immediates and ModR/M / SIB operand decoding.

///|
/// The legacy decoder state: the instruction bytes starting at `base`.
/// Positions are offsets into `bytes`; addresses are `base + position`
/// truncated to the mode width.
priv struct Decoder {
  mode : Mode
  bytes : BytesView
  base : UInt64
}

///|
/// Upstream `g a`: the byte at position `a`.
fn Decoder::g(self : Decoder, a : Int32) -> Int32 raise X86Error {
  match self.bytes.get(a) {
    Some(b) => b.to_int()
    None => raise ArchException("truncated instruction")
  }
}

///|
/// The address of position `a` as a word of the mode width.
fn Decoder::addr_of(self : Decoder, a : Int32) -> Imm {
  Imm::new(self.base + a.to_uint64(), self.mode.width())
}

///|
/// Upstream `parse_int scale a`: an unsigned little-endian integer.
fn Decoder::parse_int(
  self : Decoder,
  width : Int32,
  a : Int32,
) -> (Imm, Int32) raise X86Error {
  let n = width / 8
  let mut bits = 0UL
  for k in 0..<n {
    bits = bits | (self.g(a + k).to_uint64() << (8 * k))
  }
  (Imm::new(bits, width), a + n)
}

///|
/// Upstream `parse_sint scale a`: a signed little-endian integer.
fn Decoder::parse_sint(
  self : Decoder,
  width : Int32,
  a : Int32,
) -> (Imm, Int32) raise X86Error {
  let (i, na) = self.parse_int(width, a)
  (i.as_signed(), na)
}

///|
/// Upstream `parse_disp`.
fn Decoder::parse_disp(
  self : Decoder,
  width : Int32,
  a : Int32,
) -> (Imm, Int32) raise X86Error {
  match width {
    8 | 16 | 32 | 64 => self.parse_sint(width, a)
    _ => raise ArchException("unsupported displacement size")
  }
}

///|
/// Upstream `parse_immz`: an unsigned immediate operand.
fn Decoder::parse_immz(
  self : Decoder,
  width : Int32,
  a : Int32,
) -> (Operand, Int32) raise X86Error {
  match width {
    8 | 16 | 32 | 64 => {
      let (i, na) = self.parse_int(width, a)
      (Oimm(i), na)
    }
    _ => raise ArchException("parse_immz unsupported size: \{width}")
  }
}

///|
/// Upstream `parse_simm`: a signed immediate operand.
fn Decoder::parse_simm(
  self : Decoder,
  width : Int32,
  a : Int32,
) -> (Operand, Int32) raise X86Error {
  match width {
    8 | 16 | 32 | 64 => {
      let (i, na) = self.parse_sint(width, a)
      (Oimm(i), na)
    }
    _ => raise ArchException("parse_simm unsupported size: \{width}")
  }
}

///|
/// Upstream `big_int_of_mode`: a word extended to the mode width, as an
/// expression.
fn Decoder::bm(self : Decoder, i : Imm) -> @types.Exp {
  i.to_exp(self.mode.width())
}

///|
/// Upstream `add_to_addr`: `addr + value` in the address width, with
/// `value` sign- or zero-extended.
fn add_to_addr(addr : Imm, value : Imm) -> Imm {
  Imm::new(addr.bits + value.to_int64().reinterpret_as_uint64(), addr.width)
}

///|
/// Upstream `oimm_resize`: sign-extend (or truncate) an immediate operand.
fn oimm_resize(op : Operand, size : Int32) -> Operand raise X86Error {
  match op {
    Oimm(d) => Oimm(d.as_signed().resize(size))
    _ => raise ArchException("oimm_resize only handles Oimm")
  }
}

///|
/// Upstream `cc_to_exp`: the condition of a `Jcc`/`SETcc`/`CMOVcc` from
/// the low opcode bits.
fn cc_to_exp(i : Int32) -> @types.Exp {
  let cc = match i & 0xe {
    0x0 => ev(of_)
    0x2 => ev(cf)
    0x4 => ev(zf)
    0x6 => e_or(ev(cf), ev(zf))
    0x8 => ev(sf)
    0xa => ev(pf)
    0xc => e_xor(ev(sf), ev(of_))
    _ => e_or(ev(zf), e_xor(ev(sf), ev(of_)))
  }
  if (i & 1) == 0 {
    cc
  } else {
    e_not(cc)
  }
}

///|
fn ext_bit(b : Bool) -> Int32 {
  if b {
    8
  } else {
    0
  }
}

///|
/// Upstream `convert_vex`: the REX form of the VEX register extensions.
fn convert_vex(rex : Rex?, vex : Vex?) -> Rex? raise X86Error {
  match (rex, vex) {
    (Some(_), Some(_)) => raise ArchException("both rex and vex specified")
    (Some(_), None) => rex
    (None, Some(v)) => Some({ r: !v.nr, x: !v.nx, b: !v.nb, w: v.we, })
    (None, None) => None
  }
}

///|
/// Upstream `parse_sib`.
fn Decoder::parse_sib(
  self : Decoder,
  rex : Rex?,
  modb : Int32,
  a : Int32,
) -> (@types.Exp, Int32) raise X86Error {
  let (rex_b, rex_x) = match rex {
    Some(r) => (r.b, r.x)
    None => (false, false)
  }
  let b = self.g(a)
  let mode = self.mode
  let bits2rege = (n : Int32) => {
    match mode {
      X86 => bits2reg32e(mode, n)
      X8664 => bits2reg64e(mode, n)
    }
  }
  let ss = b >> 6
  let idx = ((b >> 3) & 7) | ext_bit(rex_x)
  let (base, na) = match (b & 7, modb & 7) {
    (5, 0) => {
      let (i, na) = self.parse_disp(32, a + 1)
      (self.bm(i), na)
    }
    (_, 0 | 1 | 2) => (bits2rege((b & 7) | ext_bit(rex_b)), a + 1)
    _ =>
      raise ArchException("impossible opcode: sib b=\{b.to_string(radix=16)}")
  }
  if idx == 4 {
    (base, na)
  } else {
    let idx = bits2rege(idx)
    if ss == 0 {
      (e_plus(base, idx), na)
    } else {
      (e_plus(base, e_lsl(idx, int_exp(ss, mode.width()))), na)
    }
  }
}

///|
/// Upstream `parse_modrmbits64`: (reg field, mod, r/m field, next) with
/// the REX extensions applied.
fn Decoder::parse_modrmbits64(
  self : Decoder,
  rex : Rex?,
  a : Int32,
) -> (Int32, Int32, Int32, Int32) raise X86Error {
  let b = self.g(a)
  let (rex_r, rex_b) = match rex {
    Some(r) => (r.r, r.b)
    None => (false, false)
  }
  let r = ext_bit(rex_r) | ((b >> 3) & 7)
  let rm = ext_bit(rex_b) | (b & 7)
  (r, b >> 6, rm, a + 1)
}

///|
/// Upstream `parse_modrm16int`.
fn Decoder::parse_modrm16int(
  self : Decoder,
  r : Int32,
  modb : Int32,
  rm : Int32,
  na : Int32,
) -> (Int32, Operand, Int32) raise X86Error {
  let mode = self.mode
  let tm = mode.width()
  match modb & 7 {
    0 =>
      match rm & 7 {
        6 => {
          let (disp, na) = self.parse_disp(16, na)
          (r, Oaddr(self.bm(disp)), na)
        }
        _ => (r, Oaddr(e_unsigned(tm, eaddr16(mode, rm))), na)
      }
    1 | 2 => {
      let base = eaddr16(mode, rm)
      let (disp, na) = if (modb & 7) == 1 {
        self.parse_disp(8, na)
      } else {
        self.parse_disp(16, na)
      }
      (r, Oaddr(e_unsigned(tm, e_plus(base, disp.to_exp(16)))), na)
    }
    3 => (r, Oreg(rm), na)
    _ => raise ArchException("Impossible")
  }
}

///|
/// Upstream `parse_modrm3264int`.
fn Decoder::parse_modrm3264int(
  self : Decoder,
  rex : Rex?,
  at : Int32,
  r : Int32,
  modb : Int32,
  rm : Int32,
  naoffset : Int32?,
  na : Int32,
) -> (Int32, Operand, Int32) raise X86Error {
  let mode = self.mode
  let bits2rege = match at {
    32 => (b : Int32) => e_unsigned(mode.width(), bits2reg32e(mode, b))
    64 => (b : Int32) => bits2reg64e(mode, b)
    _ => raise ArchException("parse_modrm3264int: invalid address type")
  }
  match modb & 7 {
    0 =>
      match rm & 7 {
        4 => {
          let (sib, na) = self.parse_sib(rex, modb, na)
          (r, Oaddr(sib), na)
        }
        5 =>
          match mode {
            X86 => {
              let (disp, na) = self.parse_disp(32, na)
              (r, Oaddr(disp.to_exp(32)), na)
            }
            X8664 => {
              let immoff = match naoffset {
                Some(nbits) => int_exp(nbits / 8, 64)
                None => int_exp(0, 64)
              }
              let (disp, na) = self.parse_disp(32, na)
              let next = self.addr_of(na)
              (
                r,
                Oaddr(e_plus(e_plus(disp.to_exp(64), next.to_exp(64)), immoff)),
                na,
              )
            }
          }
        _ => (r, Oaddr(bits2rege(rm)), na)
      }
    1 | 2 => {
      let (base, na) = if (rm & 7) == 4 {
        self.parse_sib(rex, modb, na)
      } else {
        (bits2rege(rm), na)
      }
      let (disp, na) = if modb == 1 {
        self.parse_disp(8, na)
      } else {
        self.parse_disp(32, na)
      }
      (r, Oaddr(e_plus(base, self.bm(disp))), na)
    }
    3 => (r, Oreg(rm), na)
    _ => raise ArchException("Impossible")
  }
}

///|
/// Upstream `parse_modrm*ext_addr`: decode a ModR/M operand in the address
/// size of the instruction, returning the raw reg field, the r/m operand and
/// the next position. `immoff` is the width of an immediate that follows
/// (for RIP-relative addressing).
fn Decoder::modrm_ext(
  self : Decoder,
  prefix : Prefix,
  immoff : Int32?,
  a : Int32,
) -> (Int32, Operand, Int32) raise X86Error {
  match prefix.addrsize {
    16 => {
      let (r, modb, rm, na) = self.parse_modrmbits64(prefix.rex, a)
      self.parse_modrm16int(r, modb, rm, na)
    }
    32 | 64 => self.modrm3264_ext(prefix, immoff, a)
    _ => raise ArchException("Bad address type")
  }
}

///|
/// Upstream `parse_modrm3264ext` (always in the 32/64-bit form).
fn Decoder::modrm3264_ext(
  self : Decoder,
  prefix : Prefix,
  immoff : Int32?,
  a : Int32,
) -> (Int32, Operand, Int32) raise X86Error {
  let rex = convert_vex(prefix.rex, prefix.vex)
  let (r, modb, rm, na) = self.parse_modrmbits64(rex, a)
  self.parse_modrm3264int(rex, prefix.addrsize, r, modb, rm, immoff, na)
}

///|
/// Upstream `parse_modrm_addr`: the reg field as a general register.
fn Decoder::modrm(
  self : Decoder,
  prefix : Prefix,
  immoff : Int32?,
  a : Int32,
) -> (Operand, Operand, Int32) raise X86Error {
  let (r, rm, na) = self.modrm_ext(prefix, immoff, a)
  (Oreg(r), rm, na)
}

///|
/// Upstream `parse_modrmseg_addr`: the reg field as a segment register.
fn Decoder::modrm_seg(
  self : Decoder,
  prefix : Prefix,
  immoff : Int32?,
  a : Int32,
) -> (Operand, Operand, Int32) raise X86Error {
  let (r, rm, na) = self.modrm_ext(prefix, immoff, a)
  match prefix.addrsize {
    16 => (Oseg(r), rm, na)
    // Ignore bits from REX prefix for segment selectors
    _ => (Oseg(r & 7), rm, na)
  }
}

///|
fn tovec(op : Operand) -> Operand {
  match op {
    Oreg(r) => Ovec(r)
    _ => op
  }
}

///|
fn toreg(op : Operand) -> Operand {
  match op {
    Ovec(r) => Oreg(r)
    _ => op
  }
}

///|
/// Upstream `parse_modrm3264_vec`: reg, r/m and the optional VEX `vvvv`
/// operand as vector registers.
fn Decoder::modrm_vec(
  self : Decoder,
  prefix : Prefix,
  immoff : Int32?,
  a : Int32,
) -> (Operand, Operand, Operand?, Int32) raise X86Error {
  let (r, rm, na) = self.modrm3264_ext(prefix, immoff, a)
  let rv = match prefix.vex {
    None => None
    Some(v) => Some(Ovec(v.v.lnot() & 0xf))
  }
  (Ovec(r), tovec(rm), rv, na)
}
