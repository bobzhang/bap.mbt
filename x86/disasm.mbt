// Port of BAP `plugins/x86/x86_disasm.ml` (part 2): prefixes and the
// opcode tables of the legacy byte-level decoder.

///|
let o_rax : Operand = Oreg(0)

///|
let o_rcx : Operand = Oreg(1)

///|
let o_rdx : Operand = Oreg(2)

///|
let o_rbx : Operand = Oreg(3)

///|
let o_rsp : Operand = Oreg(4)

///|
let o_rbp : Operand = Oreg(5)

///|
let o_fs : Operand = Oseg(4)

///|
let o_gs : Operand = Oseg(5)

///|
let repnz : Int = 0xf2

///|
let repz : Int = 0xf3

///|
let pref_opsize : Int = 0x66

///|
let pref_addrsize : Int = 0x67

///|
fn is_legacy_prefix(i : Int) -> Bool {
  match i {
    0xf0
    | 0xf2
    | 0xf3
    | 0x2e
    | 0x36
    | 0x3e
    | 0x26
    | 0x64
    | 0x65
    | 0x66
    | 0x67 => true
    _ => false
  }
}

///|
/// The result of the legacy decoder (upstream `parse_instr`): the legacy
/// prefix bytes (in reverse order, with the VEX implied prefixes first), the
/// decoded prefix information, the opcode and the position after the
/// instruction.
priv struct Decoded {
  pref : Array[Int]
  prefix : Prefix
  op : Opcode
  next : Int
}

///|
/// Upstream `parse_instr`.
fn parse_instr(
  mode : Mode,
  bytes : BytesView,
  addr : UInt64,
) -> Decoded raise X86Error {
  let d : Decoder = { mode, bytes, base: addr, }
  // legacy prefixes
  let pref : Array[Int] = []
  let mut a = 0
  while a < bytes.length() && is_legacy_prefix(d.g(a)) {
    pref.insert(0, d.g(a))
    a = a + 1
  }
  // REX
  let rex_byte = match mode {
    X86 => None
    X8664 => {
      let i = d.g(a)
      if i >= 0x40 && i <= 0x4f {
        a = a + 1
        Some(i)
      } else {
        None
      }
    }
  }
  // VEX
  let vex = match mode {
    X86 => None
    X8664 =>
      match d.g(a) {
        0xc4 | 0x8f => {
          let b1 = d.g(a + 1)
          let b2 = d.g(a + 2)
          a = a + 3
          Some({
            nr: (b1 & 0x80) == 0x80,
            nx: (b1 & 0x40) == 0x40,
            nb: (b1 & 0x20) == 0x20,
            map_select: b1 & 0x1f,
            we: (b2 & 0x80) == 0x80,
            v: (b2 & 0x78) >> 3,
            l: (b2 & 0x4) == 0x4,
            pp: b2 & 0x3,
          })
        }
        0xc5 => {
          let b1 = d.g(a + 1)
          a = a + 2
          Some({
            nr: (b1 & 0x80) == 0x80,
            nx: true,
            nb: true,
            map_select: 1,
            we: false,
            v: (b1 & 0x78) >> 3,
            l: (b1 & 0x4) == 0x4,
            pp: b1 & 0x3,
          })
        }
        _ => None
      }
  }
  // VEX implied mandatory prefixes
  match vex {
    Some({ pp: 1, .. }) => pref.insert(0, 0x66)
    Some({ pp: 2, .. }) => pref.insert(0, 0xf3)
    Some({ pp: 3, .. }) => pref.insert(0, 0xf2)
    _ => ()
  }
  let rex : Rex? = match rex_byte {
    Some(i) =>
      Some({
        w: (i & 0x8) == 0x8,
        r: (i & 0x4) == 0x4,
        x: (i & 0x2) == 0x2,
        b: (i & 0x1) == 0x1,
      })
    None => None
  }
  let modesize = mode.width()
  let (opsize, bopsize, mopsize) = if pref.contains(pref_opsize) {
    (16, 16, 128)
  } else {
    (32, modesize, 64)
  }
  let opsize = match rex {
    Some({ w: true, .. }) => 64
    _ => opsize
  }
  let opsize = match vex {
    Some({ we: true, .. }) => 64
    _ => opsize
  }
  let mopsize = match vex {
    Some({ l: false, .. }) => 128
    Some({ l: true, .. }) => 256
    None => mopsize
  }
  let addrsize = match mode {
    X86 => if pref.contains(pref_addrsize) { 16 } else { 32 }
    X8664 => if pref.contains(pref_addrsize) { 32 } else { 64 }
  }
  let (r_extend, rm_extend, sib_extend) = match rex {
    Some(r) => (ext_bit(r.r), ext_bit(r.b), ext_bit(r.x))
    None =>
      match vex {
        Some(v) => (ext_bit(!v.nr), ext_bit(!v.nb), ext_bit(!v.nx))
        None => (0, 0, 0)
      }
  }
  let prefix : Prefix = {
    addrsize,
    opsize,
    bopsize,
    mopsize,
    repeat: pref.contains(repz),
    nrepeat: pref.contains(repnz),
    addrsize_override: pref.contains(pref_addrsize),
    opsize_override: pref.contains(pref_opsize),
    rex,
    vex,
    r_extend,
    rm_extend,
    sib_extend,
  }
  let (op, next) = d.get_opcode(prefix, a)
  { pref, prefix, op, next, }
}

///|
/// Upstream `parse_prefixes`: the segment base selected by the segment
/// override prefixes, and the remaining prefixes (without segment, lock and
/// operand-size prefixes).
fn parse_prefixes(mode : Mode, pref : Array[Int]) -> (@types.Var?, Array[Int]) {
  let r = vars_of_mode(mode)
  let mut s : @types.Var? = None
  let rest : Array[Int] = []
  for p in pref {
    match p {
      0x2e | 0x36 | 0x3e | 0x26 | 0x64 | 0x65 => s = r.seg_base(p)
      0xf0 | 0x66 => ()
      _ => rest.push(p)
    }
  }
  (s, rest)
}

///|
/// Upstream `expanded_jump_type`.
fn Decoder::expanded_jump_type(self : Decoder, opsize : Int) -> Int {
  match self.mode {
    X86 => opsize
    X8664 => 32
  }
}

///|
/// Upstream `get_opcode` (one-byte opcode map, Table A-2).
fn Decoder::get_opcode(
  self : Decoder,
  prefix : Prefix,
  a : Int,
) -> (Opcode, Int) raise X86Error {
  let mode = self.mode
  let mt = mode.width()
  let rm_extend = prefix.rm_extend
  // A VEX prefix always implies the first byte of 0x0f
  let (b1, na) = if prefix.vex is Some(_) {
    (0x0f, a)
  } else {
    (self.g(a), a + 1)
  }
  match b1 {
    0x40 | 0x41 | 0x42 | 0x43 | 0x44 | 0x45 | 0x46 | 0x47 =>
      (Inc(prefix.opsize, Oreg(rm_extend | (b1 & 7))), na)
    0x48 | 0x49 | 0x4a | 0x4b | 0x4c | 0x4d | 0x4e | 0x4f =>
      (Dec(prefix.opsize, Oreg(rm_extend | (b1 & 7))), na)
    0x50 | 0x51 | 0x52 | 0x53 | 0x54 | 0x55 | 0x56 | 0x57 =>
      (Push(prefix.bopsize, Oreg(rm_extend | (b1 & 7))), na)
    0x58 | 0x59 | 0x5a | 0x5b | 0x5c | 0x5d | 0x5e | 0x5f =>
      (Pop(prefix.bopsize, Oreg(rm_extend | (b1 & 7))), na)
    0x63 if mode == X8664 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Movsx(prefix.opsize, r, 32, rm), na)
    }
    0x68 | 0x6a => {
      let (o, na) = if b1 == 0x68 {
        self.parse_immz(prefix.opsize, na)
      } else {
        self.parse_immz(8, na)
      }
      let size = match mode {
        X86 => prefix.opsize
        X8664 => 64
      }
      (Push(size, o), na)
    }
    0x69 | 0x6b => {
      let it = if b1 == 0x6b {
        8
      } else if prefix.opsize == 16 {
        16
      } else {
        32
      }
      let (r, rm, na) = self.modrm(prefix, Some(it), na)
      let (o, na) = self.parse_simm(it, na)
      (Imul(prefix.opsize, (false, r), rm, oimm_resize(o, prefix.opsize)), na)
    }
    0x70
    | 0x71
    | 0x72
    | 0x73
    | 0x74
    | 0x75
    | 0x76
    | 0x77
    | 0x78
    | 0x79
    | 0x7a
    | 0x7b
    | 0x7c
    | 0x7d
    | 0x7e
    | 0x7f => {
      let (i, na) = self.parse_disp(8, na)
      (Jcc(Jabs(Oimm(add_to_addr(self.addr_of(na), i))), cc_to_exp(b1)), na)
    }
    0x80 | 0x81 | 0x82 | 0x83 => {
      let it = match b1 {
        0x81 => if prefix.opsize == 64 { 32 } else { prefix.opsize }
        _ => 8
      }
      let (r, rm, na) = self.modrm_ext(prefix, Some(it), na)
      let (o, na) = self.parse_immz(it, na)
      let o2 = oimm_resize(o, prefix.opsize)
      let opsize = if (b1 & 1) == 0 { 8 } else { prefix.opsize }
      match r {
        0 => (Add(opsize, rm, o2), na)
        1 => (Or(opsize, rm, o2), na)
        2 => (Adc(opsize, rm, o2), na)
        3 => (Sbb(opsize, rm, o2), na)
        4 => (And(opsize, rm, o2), na)
        5 => (Sub(opsize, rm, o2), na)
        6 => (Xor(opsize, rm, o2), na)
        7 => (Cmp(opsize, rm, o2), na)
        _ => raise ArchException("impossible Grp 1 opcode")
      }
    }
    0x84 | 0x85 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      let o = if b1 == 0x84 { 8 } else { prefix.opsize }
      (Test(o, rm, r), na)
    }
    0x87 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Xchg(prefix.opsize, r, rm), na)
    }
    0x88 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Mov(8, rm, r, None), na)
    }
    0x89 => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Mov(prefix.opsize, rm, r, None), na)
    }
    0x8a => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Mov(8, r, rm, None), na)
    }
    0x8b => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      (Mov(prefix.opsize, r, rm, None), na)
    }
    0x8c => {
      let (r, rm, na) = self.modrm_seg(prefix, None, na)
      let ext_size = if prefix.opsize == 64 { 64 } else { 16 }
      (Mov(ext_size, rm, r, None), na)
    }
    0x8d => {
      let (r, rm, na) = self.modrm(prefix, None, na)
      match rm {
        Oaddr(a) => (Lea(prefix.opsize, r, a), na)
        _ => raise ArchException("invalid lea (must be address)")
      }
    }
    0x8e => {
      let (r, rm, na) = self.modrm_seg(prefix, None, na)
      (Mov(16, r, rm, None), na)
    }
    0x90 => (Nop, na)
    0x91 | 0x92 | 0x93 | 0x94 | 0x95 | 0x96 | 0x97 => {
      let reg = Oreg(rm_extend | (b1 & 7))
      (Xchg(prefix.opsize, o_rax, reg), na)
    }
    0x98 => {
      let srct = match prefix.opsize {
        16 => 8
        32 => 16
        64 => 32
        _ => raise ArchException("invalid opsize for CBW/CWDE/CWQE")
      }
      (Movsx(prefix.opsize, o_rax, srct, o_rax), na)
    }
    0x9c => (Pushf(prefix.bopsize), na)
    // Intel says that popfq needs to have a REX.W prefix, but gas and clang
    // both insist that no prefix is needed!
    0x9d => (Popf(prefix.bopsize), na)
    0x9e => (Sahf, na)
    0x9f => (Lahf, na)
    0xa0 | 0xa1 => {
      let t = if b1 == 0xa0 { 8 } else { prefix.opsize }
      let (addr, na) = self.parse_disp(prefix.addrsize, na)
      (Mov(t, o_rax, Oaddr(self.bm(addr)), None), na)
    }
    0xa2 | 0xa3 => {
      let t = if b1 == 0xa2 { 8 } else { prefix.opsize }
      let (addr, na) = self.parse_disp(prefix.addrsize, na)
      (Mov(t, Oaddr(self.bm(addr)), o_rax, None), na)
    }
    0xa4 => (Movs(8), na)
    0xa5 => (Movs(prefix.opsize), na)
    0xa6 => (Cmps(8), na)
    0xa7 => (Cmps(prefix.opsize), na)
    0xae => (Scas(8), na)
    0xaf => (Scas(prefix.opsize), na)
    0xa8 => {
      let (i, na) = self.parse_immz(8, na)
      (Test(8, o_rax, i), na)
    }
    0xa9 => {
      let it = if prefix.opsize == 64 { 32 } else { prefix.opsize }
      let (i, na) = self.parse_immz(it, na)
      (Test(prefix.opsize, o_rax, oimm_resize(i, prefix.opsize)), na)
    }
    0xaa => (Stos(8), na)
    0xab => (Stos(prefix.opsize), na)
    0xb0 | 0xb1 | 0xb2 | 0xb3 | 0xb4 | 0xb5 | 0xb6 | 0xb7 => {
      let (i, na) = self.parse_immz(8, na)
      (Mov(8, Oreg(rm_extend | (b1 & 7)), i, None), na)
    }
    0xb8 | 0xb9 | 0xba | 0xbb | 0xbc | 0xbd | 0xbe | 0xbf => {
      let (i, na) = self.parse_immz(prefix.opsize, na)
      (Mov(prefix.opsize, Oreg(rm_extend | (b1 & 7)), i, None), na)
    }
    0xc2 | 0xc3 | 0xca | 0xcb => {
      let far_ret = !(b1 == 0xc2 || b1 == 0xc3)
      if b1 == 0xc3 || b1 == 0xcb {
        (Retn(None, far_ret), na)
      } else {
        let (imm, na) = self.parse_immz(16, na)
        (Retn(Some((mt, imm)), far_ret), na)
      }
    }
    0xc6 | 0xc7 => {
      let t = if b1 == 0xc6 { 8 } else { prefix.opsize }
      let it = if b1 == 0xc6 {
        8
      } else if prefix.opsize_override {
        16
      } else {
        32
      }
      let (e, rm, na) = self.modrm_ext(prefix, Some(it), na)
      let (i, na) = self.parse_immz(it, na)
      match e {
        0 => (Mov(t, rm, oimm_resize(i, t), None), na)
        _ =>
          raise ArchException("Invalid opcode: \{b1.to_string(radix=16)}/\{e}")
      }
    }
    0xc9 => (Leave(mt), na)
    0xcc => (Interrupt3, na)
    0xcd => {
      let (i, na) = self.parse_immz(8, na)
      (Interrupt(i), na)
    }
    // 0xd8-0xdf can be followed by a secondary opcode, OR a modrm byte. But
    // the secondary opcode is only used when the modrm byte does not
    // specify a memory address.
    0xd8 | 0xd9 | 0xda | 0xdb | 0xdc | 0xdd | 0xde | 0xdf => {
      let (_, _) = self.parse_int(8, na)
      let (r, rm, na) = self.modrm_ext(prefix, None, na)
      let unsupported = () => {
        NoSemantics("unsupported opcode: \{b1.to_string(radix=16)}/\{r}")
      }
      match (r, rm) {
        (2, Oaddr(_)) =>
          match b1 {
            0xd9 | 0xdd => (Fst(rm, false), na)
            _ => raise unsupported()
          }
        (3, Oaddr(_)) =>
          match b1 {
            0xd9 | 0xdd => (Fst(rm, true), na)
            _ => raise unsupported()
          }
        (5, Oaddr(_)) =>
          match b1 {
            0xd9 => (Fldcw(rm), na)
            0xdb => (Fld(rm), na)
            _ => raise unsupported()
          }
        (7, Oaddr(_)) =>
          match b1 {
            0xd9 => (Fnstcw(rm), na)
            0xdb => (Fst(rm, true), na)
            _ => raise unsupported()
          }
        _ => raise unsupported()
      }
    }
    0xe8 => {
      let t = self.expanded_jump_type(prefix.opsize)
      let (i, na) = self.parse_disp(t, na)
      let next = self.addr_of(na)
      (Call(Oimm(add_to_addr(next, i)), next.resize(prefix.addrsize)), na)
    }
    0xe9 => {
      let t = self.expanded_jump_type(prefix.opsize)
      let (i, na) = self.parse_disp(t, na)
      (Jump(Jabs(Oimm(add_to_addr(self.addr_of(na), i)))), na)
    }
    0xeb => {
      let (i, na) = self.parse_disp(8, na)
      (Jump(Jabs(Oimm(add_to_addr(self.addr_of(na), i)))), na)
    }
    0xc0 | 0xc1 | 0xd0 | 0xd1 | 0xd2 | 0xd3 => {
      let immoff = if (b1 & 0xfe) == 0xc0 { Some(8) } else { None }
      let (r, rm, na) = self.modrm_ext(prefix, immoff, na)
      let opsize = if (b1 & 1) == 0 { 8 } else { prefix.opsize }
      let (amt, na) = match b1 & 0xfe {
        0xc0 => self.parse_immz(8, na)
        0xd0 => (Oimm(Imm::new(1, 1)), na)
        0xd2 => (o_rcx, na)
        _ => raise ArchException("impossible opcode")
      }
      match r {
        0 => (Rotate(LShift, opsize, rm, amt, false), na)
        1 => (Rotate(RShift, opsize, rm, amt, false), na)
        // SWXXX Implement these
        2 | 3 =>
          raise NoSemantics(
            "unsupported opcode: \{b1.to_string(radix=16)}/\{r}",
          )
        4 => (Shift(LShift, opsize, rm, amt), na)
        5 => (Shift(RShift, opsize, rm, amt), na)
        7 => (Shift(ARShift, opsize, rm, amt), na)
        _ =>
          raise ArchException(
            "impossible opcode: \{b1.to_string(radix=16)}/\{r}",
          )
      }
    }
    0xe3 => {
      let t = prefix.addrsize
      let rcx_e = ev(vars_of_mode(mode).rcx)
      let (i, na) = self.parse_disp(8, na)
      (
        Jcc(
          Jrel(self.addr_of(na).resize(t), i.resize(t)),
          e_eq(rcx_e, int_exp(0, mt)),
        ),
        na,
      )
    }
    0xf4 => (Hlt, na)
    0xf6 | 0xf7 => {
      let t = if b1 == 0xf6 { 8 } else { prefix.opsize }
      let it = if t == 64 { 32 } else { t }
      let (r, rm, na) = self.modrm_ext(prefix, Some(it), na)
      match r {
        0 => {
          let (imm, na) = self.parse_immz(it, na)
          (Test(t, rm, oimm_resize(imm, t)), na)
        }
        2 => (Not(t, rm), na)
        3 => (Neg(t, rm), na)
        4 => (Mul(t, rm), na)
        5 =>
          if b1 == 0xf6 {
            (Imul(t, (true, o_rax), o_rax, rm), na)
          } else {
            (Imul(t, (true, o_rdx), o_rax, rm), na)
          }
        6 => if b1 == 0xf6 { (Div(8, rm), na) } else { (Div(t, rm), na) }
        7 => if b1 == 0xf6 { (Idiv(8, rm), na) } else { (Idiv(t, rm), na) }
        _ =>
          raise ArchException(
            "impossible opcode: \{b1.to_string(radix=16)}/\{r}",
          )
      }
    }
    0xfc => (Cld, na)
    0xfe => {
      let (r, rm, na) = self.modrm_ext(prefix, None, na)
      match r {
        0 => (Inc(8, rm), na)
        1 => (Dec(8, rm), na)
        _ =>
          raise ArchException(
            "impossible opcode: \{b1.to_string(radix=16)}/\{r}",
          )
      }
    }
    0xff => {
      let (r, rm, na) = self.modrm_ext(prefix, None, na)
      let t = prefix.addrsize
      match r {
        0 => (Inc(prefix.opsize, rm), na)
        1 => (Dec(prefix.opsize, rm), na)
        2 => (Call(rm, self.addr_of(na).resize(t)), na)
        3 | 5 =>
          raise NoSemantics(
            "unsupported opcode: \{b1.to_string(radix=16)}/\{r}",
          )
        4 => (Jump(Jabs(rm)), na)
        6 => {
          let size = match mode {
            X86 => prefix.opsize
            X8664 => 64
          }
          (Push(size, rm), na)
        }
        _ =>
          raise ArchException(
            "impossible opcode: \{b1.to_string(radix=16)}/\{r}",
          )
      }
    }
    b1 if b1 < 0x3e && (b1 & 7) < 6 => {
      let t = if (b1 & 1) == 0 { 8 } else { prefix.opsize }
      // handle sign extended immediate cases
      let it = if t == 64 { 32 } else { t }
      let (o1, o2, na) = match b1 & 7 {
        0 | 1 => {
          let (r, rm, na) = self.modrm(prefix, None, na)
          (rm, r, na)
        }
        2 | 3 => {
          let (r, rm, na) = self.modrm(prefix, None, na)
          (r, rm, na)
        }
        4 => {
          let (i, na) = self.parse_immz(8, na)
          (o_rax, i, na)
        }
        _ => {
          let (i, na) = self.parse_immz(it, na)
          (o_rax, oimm_resize(i, t), na)
        }
      }
      let op = match b1 >> 3 {
        0 => Add(t, o1, o2)
        1 => Or(t, o1, o2)
        2 => Adc(t, o1, o2)
        3 => Sbb(t, o1, o2)
        4 => And(t, o1, o2)
        5 => Sub(t, o1, o2)
        6 => Xor(t, o1, o2)
        _ => Cmp(t, o1, o2)
      }
      (op, na)
    }
    0x0f => self.get_opcode_0f(prefix, na)
    n =>
      raise NoSemantics("unsupported single opcode: \{n.to_string(radix=16)}")
  }
}
