// Port of BAP `plugins/x86/x86_disasm.ml` (part 3): the two- and
// three-byte opcode maps (Table A-3).

///|
/// Upstream `parse_imm8cb`: decode the PCMPxSTRx control byte.
fn parse_imm8cb(b : Int) -> Imm8cb {
  {
    words: (b & 1) != 0,
    signed: (b & 2) != 0,
    agg: (b >> 2) & 3,
    negintres1: (b & 0x10) != 0,
    maskintres1: (b & 0x20) != 0,
    msb: (b & 0x40) != 0,
  }
}

///|
fn Decoder::get_opcode_0f(
  self : Decoder,
  prefix : Prefix,
  na : Int,
) -> (Opcode, Int) raise X86Error {
  let mode = self.mode
  // Add in the second implied vex prefix
  let (b2, na) = match prefix.vex {
    Some({ map_select: 2, .. }) => (0x38, na)
    Some({ map_select: 3, .. }) => (0x3a, na)
    Some({ map_select: 1, .. }) | None => (self.g(na), na + 1)
    Some(v) => raise ArchException("reserved mmmmmm vex value: \{v.map_select}")
  }
  let unsupported = () => {
    NoSemantics("unsupported opcode: 0f \{b2.to_string(radix=16)}")
  }
  match b2 {
    0x01 => {
      let b3 = self.g(na)
      match b3 {
        0xd0 => (Xgetbv, na + 1)
        _ =>
          raise ArchException(
            "unsupported opcode 0f 01 \{b3.to_string(radix=16)}",
          )
      }
    }
    0x05 if mode == X8664 => (Syscall, na)
    0x1f => {
      // Even though we don't use the operand to nop, we need to parse it
      // to get the next address
      let (_, _, na) = self.modrm(prefix, None, na)
      (Nop, na)
    }
    0x10 | 0x11 if prefix.repeat || prefix.nrepeat => {
      // MOVSS, MOVSD
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let t = if prefix.repeat { 32 } else { 64 }
      let (d, s, td) = if b2 == 0x10 { (r, rm, 128) } else { (rm, r, t) }
      match (rm, rv) {
        (Ovec(_), Some(rv)) =>
          (
            Movoffset((128, d), [
              {
                offlen: 128 - t,
                offtyp: 128,
                offop: rv,
                offsrcoffset: t,
                offdstoffset: t,
              },
              {
                offlen: t,
                offtyp: 128,
                offop: s,
                offsrcoffset: 0,
                offdstoffset: 0,
              },
            ]),
            na,
          )
        (Ovec(_), None) => (Movdq(t, s, t, d, false), na)
        (Oaddr(_), _) => (Movdq(t, s, td, d, false), na)
        _ => raise ArchException("impossible")
      }
    }
    0x12 | 0x13 | 0x16 | 0x17 => {
      // MOVLPS, MOVLPD, MOVHPS, MOVHPD, MOVHLPS, MOVHLPD, MOVLHPS, MOVLHPD
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let (tdst, dst, telt, tsrc1, src1, off_src1, off_dst1, src2) = match
        (b2, rv) {
        (0x12 | 0x16, Some(rv)) => {
          let (offs1, offs2, offd1, offd2) = match (b2, rm) {
            (0x12, Ovec(_)) => (64, 64, 64, 0)
            (0x12, _) => (64, 0, 64, 0)
            _ => (0, 0, 0, 64)
          }
          let src2 = [
            {
              offlen: 64,
              offtyp: 128,
              offop: rm,
              offsrcoffset: offs2,
              offdstoffset: offd2,
            },
          ]
          (128, r, 64, 128, rv, offs1, offd1, src2)
        }
        _ => {
          let offset = match b2 {
            0x12 | 0x13 => 0
            _ => 64
          }
          let (s, d, offs, offd) = match (b2, rm) {
            (0x12, Ovec(_)) => (rm, r, 64, 0)
            (0x12 | 0x16, _) => (rm, r, 0, offset)
            _ => (r, rm, offset, 0)
          }
          let ts = match s {
            Ovec(_) => 128
            _ => 64
          }
          (128, d, 64, ts, s, offs, offd, [])
        }
      }
      let offsets = [
        {
          offlen: telt,
          offtyp: tsrc1,
          offop: src1,
          offsrcoffset: off_src1,
          offdstoffset: off_dst1,
        },
      ]
      offsets.push_iter(src2.iter())
      (Movoffset((tdst, dst), offsets), na)
    }
    0x10 | 0x11 | 0x28 | 0x29 | 0x6e | 0x7e | 0x6f | 0x7f | 0xd6 => {
      // REGULAR MOVDQ
      let (r, rm, _, na) = self.modrm_vec(prefix, None, na)
      let (src, dst, tsrc, tdst, align) = match b2 {
        0x10 | 0x11 | 0x28 | 0x29 => {
          // MOVUPS, MOVUPD, MOVAPS, MOVAPD
          let (s, d) = match b2 {
            0x10 | 0x28 => (rm, r)
            _ => (r, rm)
          }
          let align = b2 == 0x28 || b2 == 0x29
          let t = if prefix.mopsize == 256 { 256 } else { 128 }
          (s, d, t, t, align)
        }
        0x6e | 0x7e => {
          // MOVD, MOVQ
          let t = if prefix.opsize == 64 { 64 } else { 32 }
          let (s, d, ts, td) = match b2 {
            0x6e => (toreg(rm), r, t, 128)
            _ if prefix.repeat => (rm, r, 64, 128)
            _ => (r, toreg(rm), t, t)
          }
          (s, d, ts, td, false)
        }
        0x6f | 0x7f => {
          // MOVQ, MOVDQA, MOVDQU
          let (s, d) = if b2 == 0x6f { (rm, r) } else { (r, rm) }
          let size = if prefix.repeat && prefix.vex is None {
            128
          } else {
            prefix.mopsize
          }
          (s, d, size, size, prefix.opsize_override)
        }
        // MOVQ xmm2/m64, xmm1: port: a register destination is
        // zero-extended to 128 bits (Intel SDM MOVQ)
        _ => (r, rm, 64, if rm is Ovec(_) { 128 } else { 64 }, false)
      }
      (Movdq(tsrc, src, tdst, dst, align), na)
    }
    0x31 => (Rdtsc, na)
    0x34 => (Sysenter, na)
    0x38 => self.get_opcode_0f38(prefix, na)
    0x3a => {
      let b3 = self.g(na)
      let na = na + 1
      match b3 {
        0x0f => {
          let (r, rm, rv, na) = self.modrm_vec(prefix, Some(8), na)
          let (i, na) = self.parse_immz(8, na)
          (Palignr(prefix.mopsize, r, rm, rv, i), na)
        }
        0x60 | 0x61 | 0x62 | 0x63 => {
          let (r, rm, _, na) = self.modrm_vec(prefix, Some(8), na)
          let (i, na) = self.parse_immz(8, na)
          match i {
            Oimm(imm) => {
              let imm8cb = parse_imm8cb(imm.bits.to_int())
              let pcmp : PcmpInfo = {
                index: (b3 & 0x1) == 0x1,
                implicit: (b3 & 0x2) == 0x2,
              }
              (Pcmpstr(prefix.mopsize, r, rm, i, imm8cb, pcmp), na)
            }
            _ => raise NoSemantics("unsupported non-imm op for pcmpistri")
          }
        }
        _ =>
          raise NoSemantics(
            "unsupported opcode 0f 3a \{b3.to_string(radix=16)}",
          )
      }
    }
    // conditional moves
    0x40
    | 0x41
    | 0x42
    | 0x43
    | 0x44
    | 0x45
    | 0x46
    | 0x47
    | 0x48
    | 0x49
    | 0x4a
    | 0x4b
    | 0x4c
    | 0x4d
    | 0x4e
    | 0x4f => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Mov(prefix.opsize, r, rm, Some(cc_to_exp(b2))), na)
    }
    0x57 => raise NoSemantics("now it is handled by lisp loader")
    0x60 | 0x61 | 0x62 | 0x68 | 0x69 | 0x6a => {
      let order = if b2 < 0x68 { Low } else { High }
      let elemt = match b2 & 0xf {
        0x0 | 0x8 => 8
        0x1 | 0x9 => 16
        _ => 32
      }
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Punpck(prefix.mopsize, elemt, order, r, rm, rv), na)
    }
    0x6c | 0x6d if prefix.opsize_override => {
      let order = if b2 == 0x6c { Low } else { High }
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Punpck(prefix.mopsize, 64, order, r, rm, rv), na)
    }
    0x64 | 0x65 | 0x66 | 0x74 | 0x75 | 0x76 => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let elet = match b2 & 0xf {
        0x4 => 8
        0x5 => 16
        _ => 32
      }
      let (bop, bstr) : (@types.BinOp, String) = if (b2 & 0xf0) == 0x70 {
        (Eq, "pcmpeq")
      } else {
        (SignedLt, "pcmpgt")
      }
      (Pcmp(prefix.mopsize, elet, bop, bstr, r, rm, rv), na)
    }
    0x70 if prefix.opsize == 16 => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, Some(8), na)
      let (i, na) = self.parse_immz(8, na)
      (Pshufd(prefix.mopsize, r, rm, rv, i), na)
    }
    0x71 | 0x72 | 0x73 => {
      let t = prefix.mopsize
      let (r, rm, rv, na) = self.modrm_vec(prefix, Some(8), na)
      let (i, na) = self.parse_immz(8, na)
      let (fbop, str, et, i) : (@types.BinOp, String, Int, Operand) = match
        (b2, r, i) {
        (_, Ovec(2), _) => (RShift, "psrl", lowbits2elemt(b2), i)
        (_, Ovec(6), _) => (LShift, "psll", lowbits2elemt(b2), i)
        (_, Ovec(4), _) => (ARShift, "psra", lowbits2elemt(b2), i)
        // The shift amount of next two elements are multiplied by eight
        (0x73, Ovec(3), Oimm(i)) if prefix.opsize_override =>
          (RShift, "psrldq", t, Oimm(Imm::new(i.bits * 8, 8)))
        (0x73, Ovec(7), Oimm(i)) if prefix.opsize_override =>
          (LShift, "pslldq", t, Oimm(Imm::new(i.bits * 8, 8)))
        _ => raise ArchException("invalid psrl/psll encoding")
      }
      (Ppackedbinop(t, et, PBin(fbop), str, rm, i, rv), na)
    }
    0x80
    | 0x81
    | 0x82
    | 0x83
    | 0x84
    | 0x85
    | 0x86
    | 0x87
    | 0x88
    | 0x89
    | 0x8a
    | 0x8b
    | 0x8c
    | 0x8d
    | 0x8e
    | 0x8f => {
      let t = self.expanded_jump_type(prefix.opsize)
      let (i, na) = self.parse_disp(t, na)
      (Jcc(Jabs(Oimm(add_to_addr(self.addr_of(na), i))), cc_to_exp(b2)), na)
    }
    0x90
    | 0x91
    | 0x92
    | 0x93
    | 0x94
    | 0x95
    | 0x96
    | 0x97
    | 0x98
    | 0x99
    | 0x9a
    | 0x9b
    | 0x9c
    | 0x9d
    | 0x9e
    | 0x9f => {
      let (_, rm, na) = self.modrm(prefix, None, na)
      // unclear what happens otherwise
      if prefix.opsize != 32 {
        raise ArchException("Assert_failure: setcc with a non-32-bit opsize")
      }
      (Setcc(8, rm, cc_to_exp(b2)), na)
    }
    0xa2 => (Cpuid, na)
    // port: BTS/BTR/BTC (`0f ab`, `0f b3`, `0f bb` and `0f ba /5 /6 /7`)
    // are decoded with their kind (upstream lifts `0f ba /5 /6 /7` as BT)
    0xa3 | 0xab | 0xb3 | 0xbb => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      let kind = match b2 {
        0xab => 5
        0xb3 => 6
        0xbb => 7
        _ => 4
      }
      (Bt(kind, prefix.opsize, r, rm), na)
    }
    0xba => {
      let (kind, rm, na) = self.modrm_ext(prefix, Some(8), na)
      if kind < 4 {
        raise NoSemantics("unsupported opcode: 0f ba/\{kind}")
      }
      let (i, na) = self.parse_immz(8, na)
      (Bt(kind, prefix.opsize, i, rm), na)
    }
    0xa4 => {
      // shld
      let (r, rm, na) = self.modrm(prefix, Some(8), na)
      let (i, na) = self.parse_immz(8, na)
      (Shiftd(LShift, prefix.opsize, rm, r, i), na)
    }
    0xa5 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Shiftd(LShift, prefix.opsize, rm, r, o_rcx), na)
    }
    0xac => {
      // shrd
      let (r, rm, na) = self.modrm(prefix, Some(8), na)
      let (i, na) = self.parse_immz(8, na)
      (Shiftd(RShift, prefix.opsize, rm, r, i), na)
    }
    0xad => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Shiftd(RShift, prefix.opsize, rm, r, o_rcx), na)
    }
    0xae => {
      let (r, rm, na) = self.modrm_ext(prefix, None, na)
      match r {
        2 => (Ldmxcsr(rm), na)
        3 => (Stmxcsr(rm), na)
        _ => raise NoSemantics("unsupported opcode: 0f ae/\{r}")
      }
    }
    0xaf => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Imul(prefix.opsize, (false, r), r, rm), na)
    }
    0xb1 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Cmpxchg(prefix.opsize, r, rm), na)
    }
    0xb6 | 0xb7 => {
      let st = if b2 == 0xb6 { 8 } else { 16 }
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Movzx(prefix.opsize, r, st, rm), na)
    }
    0xb8 if prefix.repeat => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Popcnt(prefix.opsize, rm, r), na)
    }
    0xbc | 0xbd => {
      let dir = if b2 == 0xbc { Forward } else { Backward }
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Bs(prefix.opsize, r, rm, dir), na)
    }
    0xbe | 0xbf => {
      let st = if b2 == 0xbe { 8 } else { 16 }
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Movsx(prefix.opsize, r, st, rm), na)
    }
    0xc1 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Xadd(prefix.opsize, r, rm), na)
    }
    0xc7 => {
      let (r, rm, na) = self.modrm_ext(prefix, None, na)
      match r {
        1 => (Cmpxchg8b(if prefix.opsize == 64 { 128 } else { 64 }, rm), na)
        _ => raise NoSemantics("unsupported opcode: 0f c7/\{r}")
      }
    }
    0xc8 | 0xc9 | 0xca | 0xcb | 0xcc | 0xcd | 0xce | 0xcf =>
      (Bswap(prefix.opsize, Oreg(prefix.rm_extend | (b2 & 7))), na)
    0xd1 | 0xd2 | 0xd3 | 0xe1 | 0xe2 | 0xf1 | 0xf2 | 0xf3 => {
      let t = prefix.mopsize
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let et = lowbits2elemt(b2)
      let (fbop, str) : (@types.BinOp, String) = match b2 & 0xf0 {
        0xd0 => (RShift, "psrl")
        0xe0 => (ARShift, "psra")
        _ => (LShift, "psll")
      }
      (Ppackedbinop(t, et, PBin(fbop), str, r, rm, rv), na)
    }
    0xda => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Ppackedbinop(prefix.mopsize, 8, PMin(false), "pminub", r, rm, rv), na)
    }
    0xdb => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pbinop(prefix.mopsize, PBin(And), "pand", r, rm, rv), na)
    }
    0xd7 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Pmovmskb(prefix.mopsize, r, tovec(rm)), na)
    }
    0xde => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Ppackedbinop(prefix.mopsize, 8, PMax(false), "pmaxub", r, rm, rv), na)
    }
    0xdf => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pbinop(prefix.mopsize, PAndN, "pandn", r, rm, rv), na)
    }
    0xe0 | 0xe3 => {
      // pavg
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      // determine whether we're using bytes or words
      let et = if (b2 & 0x0f) == 0 { 8 } else { 16 }
      (Ppackedbinop(prefix.mopsize, et, PAvg(et), "pavg", r, rm, rv), na)
    }
    0xea => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Ppackedbinop(prefix.mopsize, 16, PMin(true), "pminsw", r, rm, rv), na)
    }
    0xeb => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pbinop(prefix.mopsize, PBin(Or), "por", r, rm, rv), na)
    }
    0xee => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Ppackedbinop(prefix.mopsize, 16, PMax(true), "pmaxsw", r, rm, rv), na)
    }
    0xef => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pbinop(prefix.mopsize, PBin(Xor), "pxor", r, rm, rv), na)
    }
    0xf0 => {
      let (r, rm, _, na) = self.modrm_vec(prefix, None, na)
      let t = if prefix.mopsize == 256 { 256 } else { 128 }
      (Movdq(t, rm, t, r, false), na)
    }
    0xf8 | 0xf9 | 0xfa | 0xfb => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let eltsize = 8 << (b2 & 3)
      (
        Ppackedbinop(prefix.mopsize, eltsize, PBin(Minus), "psub", r, rm, rv),
        na,
      )
    }
    0xfc | 0xfd | 0xfe | 0xd4 => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      let eltsize = match b2 {
        0xfc => 8
        0xfd => 16
        0xfe => 32
        _ => 64
      }
      (Ppackedbinop(prefix.mopsize, eltsize, PBin(Plus), "padd", r, rm, rv), na)
    }
    _ => raise unsupported()
  }
}

///|
/// The three-byte opcode map `0f 38`.
fn Decoder::get_opcode_0f38(
  self : Decoder,
  prefix : Prefix,
  na : Int,
) -> (Opcode, Int) raise X86Error {
  let b3 = self.g(na)
  let na = na + 1
  let o = prefix.opsize_override
  let packed = (et : Int, pop : PackedOp, name : String) => {
    let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
    (Ppackedbinop(prefix.mopsize, et, pop, name, r, rm, rv), na)
  }
  match b3 {
    0x00 => {
      let (d, s, rv, na) = self.modrm_vec(prefix, None, na)
      (Pshufb(prefix.mopsize, d, s, rv), na)
    }
    0x17 if o => {
      let (d, s, _, na) = self.modrm_vec(prefix, None, na)
      (Ptest(prefix.mopsize, d, s), na)
    }
    0x29 if o => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pcmp(prefix.mopsize, 64, Eq, "pcmpeq", r, rm, rv), na)
    }
    0x20
    | 0x21
    | 0x22
    | 0x23
    | 0x24
    | 0x25
    | 0x30
    | 0x31
    | 0x32
    | 0x33
    | 0x34
    | 0x35 if o => {
      // pmovsx and pmovzx
      let (r, rm, _, na) = self.modrm_vec(prefix, None, na)
      let (signed, name) = if (b3 & 0xf0) == 0x20 {
        (true, "pmovsx")
      } else {
        (false, "pmovzx")
      }
      let (dstet, srcet, suffix) = match b3 & 0x0f {
        0x00 => (16, 8, "bw")
        0x01 => (32, 8, "bd")
        0x02 => (64, 8, "bq")
        0x03 => (32, 16, "wd")
        0x04 => (64, 16, "wq")
        _ => (64, 32, "dq")
      }
      (Pmov(prefix.mopsize, dstet, srcet, r, rm, signed, name + suffix), na)
    }
    0x37 if o => {
      let (r, rm, rv, na) = self.modrm_vec(prefix, None, na)
      (Pcmp(prefix.mopsize, 64, SignedLt, "pcmpgt", r, rm, rv), na)
    }
    0x38 if o => packed(8, PMin(true), "pminsb")
    0x39 if o => packed(32, PMin(true), "pminsd")
    0x3a if o => packed(16, PMin(false), "pminuw")
    0x3b if o => packed(32, PMin(false), "pminud")
    0x3c if o => packed(8, PMax(true), "pmaxsb")
    0x3d if o => packed(32, PMax(true), "pmaxsd")
    0x3e if o => packed(16, PMax(false), "pmaxuw")
    0x3f if o => packed(32, PMax(false), "pmaxud")
    _ =>
      raise ArchException("opcode unsupported: 0f 38 \{b3.to_string(radix=16)}")
  }
}
