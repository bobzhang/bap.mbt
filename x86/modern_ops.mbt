// Port of BAP `plugins/x86/x86_btx.ml`, `x86_mov.ml`, `x86_mov_offset.ml`,
// `x86_cmpxchg.ml`, `x86_cdq.ml` and `x86_endbr.ml`: the per-opcode lifters
// over LLVM MC opcode names and operands.

///|
/// The kind of a BTx instruction.
priv enum BtKind {
  Bt
  Btc
  Btr
  Bts
} derive(Eq)

///|
fn BtKind::name(self : BtKind) -> String {
  match self {
    Bt => "bt"
    Btc => "btc"
    Btr => "btr"
    Bts => "bts"
  }
}

///|
/// Upstream `Btx.set_flags`.
///
/// port: ZF is unaffected (Intel SDM BT; upstream makes it undefined).
fn btx_set_flags(
  op : BtKind,
  base : @types.Exp,
  off : @types.Exp,
) -> Array[@types.Stmt] {
  [
    assign(cf, e_low(1, e_lsr(base, off))),
    set_unknown(of_, op.name()),
    set_unknown(sf, op.name()),
    set_unknown(af, op.name()),
    set_unknown(pf, op.name()),
  ]
}

///|
fn offset_width(size : Int32) -> Int32 raise @mc.LiftError {
  match size {
    16 => 4
    32 => 5
    64 => 6
    _ => raise Failure("Btx: offset width")
  }
}

///|
/// Upstream `Btx.side_effect`.
fn btx_side_effect(
  op : BtKind,
  data : @types.Exp,
  mask : @types.Exp,
  stmt : (@types.Exp) -> @types.Stmt raise @mc.LiftError,
) -> Array[@types.Stmt] raise @mc.LiftError {
  match op {
    Bt => []
    Btc => [stmt(e_xor(data, mask))]
    Btr => [stmt(e_and(data, e_not(mask)))]
    Bts => [stmt(e_or(data, mask))]
  }
}

///|
/// `Word.lshift (one size) o`: the mask of an immediate bit offset.
fn mask_imm(size : Int32, o : Int64) -> @types.Exp {
  let o = o.to_int()
  if o >= size {
    int_exp(0, size)
  } else if size <= 64 {
    uint64_exp(1UL << o, size)
  } else {
    Int(@types.Word::from_bitvec((try! @bitvec.one(width=size)).lshift(o)))
  }
}

///|
/// The immediate truncated to `width` bits (upstream `Imm.to_word`).
fn imm_word_value(value : Int64, width : Int32) -> Int64 {
  (value.reinterpret_as_uint64() & mask64(width)).reinterpret_as_int64()
}

///|
/// port: the register is written with `set`, so that 32-bit registers are
/// zero-extended in 64-bit mode (upstream assigns the whole register).
fn Tools::btx_rr(
  self : Tools,
  op : BtKind,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (base, offset) = self.rr()
  let base = self.reg(base)
  let offset = self.reg(offset)
  let size = self.width(base)
  let w = offset_width(size)
  let o = new_tmp(w, name="o")
  let d = new_tmp(size, name="d")
  let mask = e_lsl(int_exp(1, size), ev(o))
  cat([
    [assign(o, e_low(w, ev(self.reg_var(offset)))), assign(d, self.get(base))],
    btx_set_flags(op, ev(d), ev(o)),
    btx_side_effect(op, ev(d), mask, e => self.set(base, e)),
  ])
}

///|
fn Tools::btx_ri(
  self : Tools,
  op : BtKind,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (base, offset) = self.ri()
  let base = self.reg(base)
  let size = self.width(base)
  let w = offset_width(size)
  let o = imm_word_value(offset, w)
  let d = new_tmp(size, name="d")
  cat([
    [assign(d, self.get(base))],
    btx_set_flags(op, ev(d), int64_exp(o, w)),
    btx_side_effect(op, ev(d), mask_imm(size, o), e => self.set(base, e)),
  ])
}

///|
fn Tools::btx_mi(
  self : Tools,
  op : BtKind,
  size : Int32,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (base_mem, offset) = self.mi()
  let a = new_tmp(self.addr_size(), name="a")
  let d = new_tmp(size, name="d")
  let o = imm_word_value(offset, offset_width(size))
  cat([
    [assign(a, self.addr(base_mem)), assign(d, self.load_from(ev(a), size))],
    btx_set_flags(op, ev(d), int64_exp(o, offset_width(size))),
    btx_side_effect(op, ev(d), mask_imm(size, o), e => {
      self.store_to(ev(a), size, e)
    }),
  ])
}

///|
fn Tools::btx_mr(
  self : Tools,
  op : BtKind,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (base_mem, offset) = self.mr()
  let offset = self.reg(offset)
  let size = self.width(offset)
  let bsize = size
  let bsize_addr = self.addr_size()
  let a = new_tmp(bsize_addr, name="a")
  let b = new_tmp(bsize_addr, name="b")
  let d = new_tmp(bsize, name="d")
  let w = offset_width(size)
  let o = new_tmp(w, name="o")
  let bexp = {
    // port: the word at `floor(offset / size)` (upstream divides, rounding
    // negative offsets towards zero)
    let e = e_times(
      int_exp(size / 8, bsize),
      bop(ARShift, self.get(offset), int_exp(w, bsize)),
    )
    if bsize_addr != bsize {
      e_signed(bsize_addr, e)
    } else {
      e
    }
  }
  let mask = e_lsl(int_exp(1, size), ev(o))
  cat([
    [
      assign(a, self.addr(base_mem)),
      assign(b, bexp),
      assign(d, self.load_from(e_plus(ev(a), ev(b)), size)),
    ],
    [assign(o, e_low(w, ev(self.reg_var(offset))))],
    btx_set_flags(op, ev(d), ev(o)),
    btx_side_effect(op, ev(d), mask, e => {
      self.store_to(e_plus(ev(a), ev(b)), size, e)
    }),
  ])
}

///|
/// Upstream `Btx.btx`: the lifter of a BT/BTC/BTR/BTS opcode, `None` when
/// `name` is not one.
fn btx_lifter(
  name : String,
) -> ((Tools) -> Array[@types.Stmt] raise @mc.LiftError)? {
  let (kind, rest) = if name.has_prefix("BTC") {
    (Btc, name[3:])
  } else if name.has_prefix("BTR") {
    (Btr, name[3:])
  } else if name.has_prefix("BTS") {
    (Bts, name[3:])
  } else if name.has_prefix("BT") {
    (Bt, name[2:])
  } else {
    return None
  }
  let rest = rest.to_owned()
  let (size, form) = if rest.has_prefix("16") {
    (16, rest.view(start_offset=2).to_owned())
  } else if rest.has_prefix("32") {
    (32, rest.view(start_offset=2).to_owned())
  } else if rest.has_prefix("64") {
    (64, rest.view(start_offset=2).to_owned())
  } else {
    return None
  }
  // BTC/BTR/BTS with a memory destination are wrapped into the lock
  // intrinsics when the lock prefix is present (upstream `bt_crs_mem`)
  let locked = (t : Tools, bil : Array[@types.Stmt]) => {
    if kind != Bt && t.has_prefix(0xf0) {
      lock(bil)
    } else {
      bil
    }
  }
  match form {
    "rr" => Some(t => t.btx_rr(kind))
    "ri8" => Some(t => t.btx_ri(kind))
    "mi8" => Some(t => locked(t, t.btx_mi(kind, size)))
    "mr" => Some(t => locked(t, t.btx_mr(kind)))
    _ => None
  }
}

///|
/// Upstream `Mov.mov`.
fn mov_lifter(
  name : String,
) -> ((Tools) -> Array[@types.Stmt] raise @mc.LiftError)? {
  match name {
    "MOV8rr"
    | "MOV8rr_NOREX"
    | "MOV8rr_REV"
    | "MOV16rr"
    | "MOV16rr_REV"
    | "MOV32rr"
    | "MOV32rr_REV"
    | "MOV64rr"
    | "MOV64rr_REV" =>
      Some(t => {
        let (dst, src) = t.rr()
        let dst = t.reg(dst)
        let src = t.reg(src)
        [t.set(dst, t.get(src))]
      })
    "MOV8ri" | "MOV16ri" | "MOV32ri" | "MOV64ri" | "MOV64ri32" =>
      Some(t => {
        let (reg, imm) = t.ri()
        let reg = t.reg(reg)
        [t.set(reg, imm_get(imm, t.width(reg)))]
      })
    "MOV8mi" | "MOV16mi" | "MOV32mi" | "MOV64mi32" => {
      let size = match name {
        "MOV8mi" => 8
        "MOV16mi" => 16
        "MOV32mi" => 32
        _ => 64
      }
      Some(t => {
        let (mem, imm) = t.mi()
        [t.store(mem, size, imm_get(imm, size))]
      })
    }
    "MOV8rm"
    | "MOV8rm_NOREX"
    | "MOV16rm"
    | "MOV32rm"
    | "MOV64rm"
    | "MOV16sm"
    | "MOV32sm"
    | "MOV64sm" =>
      Some(t => {
        let (reg, mem) = t.rm()
        let reg = t.reg(reg)
        [t.set(reg, t.load(mem, t.width(reg)))]
      })
    "MOV8mr"
    | "MOV8mr_NOREX"
    | "MOV16mr"
    | "MOV32mr"
    | "MOV64mr"
    | "MOV16ms"
    | "MOV32ms"
    | "MOV64ms" =>
      Some(t => {
        let (mem, reg) = t.mr()
        let reg = t.reg(reg)
        [t.store(mem, t.width(reg), t.get(reg))]
      })
    "MOV16rs" | "MOV32rs" | "MOV64rs" =>
      Some(t => {
        let (reg, seg) = t.rr()
        let reg = t.reg(reg)
        let seg = t.reg(seg)
        match (name, t.mode) {
          ("MOV16rs", _) | ("MOV32rs", X8664) => [t.set(reg, t.get(seg))]
          _ => [t.set(reg, e_unsigned(t.size(), t.get(seg)))]
        }
      })
    "MOV16sr" | "MOV32sr" | "MOV64sr" =>
      Some(t => {
        let (seg, reg) = t.rr()
        let seg = t.reg(seg)
        let reg = t.reg(reg)
        if name == "MOV16sr" {
          [t.set(seg, t.get(reg))]
        } else {
          [t.set(seg, e_low(t.width(seg), ev(t.reg_var(reg))))]
        }
      })
    _ => None
  }
}

///|
/// Upstream `Mov_offset` (LLVM >= 3.5 opcode names): the register and the
/// direction (`true` for loads) of the moffs moves of `mode`.
fn mov_offset_spec(mode : Mode, name : String) -> (String, Bool)? {
  let (oa, ao) : (Array[(String, String)], Array[(String, String)]) = match
    mode {
    X86 =>
      (
        [
          ("MOV8o16a", "AL"),
          ("MOV8o32a", "AL"),
          ("MOV16o32a", "AX"),
          ("MOV32o32a", "EAX"),
          ("MOV16o16a", "AX"),
          ("MOV32o16a", "EAX"),
        ],
        [
          ("MOV8ao16", "AL"),
          ("MOV8ao32", "AL"),
          ("MOV16ao32", "AX"),
          ("MOV32ao32", "EAX"),
          ("MOV16ao16", "AX"),
          ("MOV32ao16", "EAX"),
        ],
      )
    X8664 =>
      (
        [
          ("MOV8o64a", "AL"),
          ("MOV16o64a", "AX"),
          ("MOV32o64a", "EAX"),
          ("MOV64o32a", "RAX"),
          ("MOV64o64a", "RAX"),
        ],
        [
          ("MOV8ao64", "AL"),
          ("MOV16ao64", "AX"),
          ("MOV32ao64", "EAX"),
          ("MOV64ao32", "RAX"),
          ("MOV64ao64", "RAX"),
        ],
      )
  }
  for entry in oa {
    if entry.0 == name {
      return Some((entry.1, false))
    }
  }
  for entry in ao {
    if entry.0 == name {
      return Some((entry.1, true))
    }
  }
  None
}

///|
/// Upstream `Mov_offset.Insn_semantics.lift` (with `allow_nil`).
fn Tools::mov_offset(
  self : Tools,
  reg : String,
  load : Bool,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let reg = self.reg(reg)
  let (off, seg) = self.ir()
  let mem = self.of_mem(seg~, disp=off)
  if load {
    [self.set(reg, self.load(mem, self.width(reg)))]
  } else {
    [self.store(mem, self.width(reg), self.get(reg))]
  }
}

///|
/// Upstream `Cmpxchg.get_rax`.
fn cmpxchg_rax(size : Int32) -> String {
  match size {
    8 => "AL"
    16 => "AX"
    32 => "EAX"
    _ => "RAX"
  }
}

///|
fn Tools::cmpxchg_rr(
  self : Tools,
  size : Int32,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (fst, snd) = self.rr()
  let fst = self.reg(fst)
  let snd = self.reg(snd)
  let rax = self.reg(cmpxchg_rax(size))
  let size = self.width(rax)
  let v = new_tmp(size, name="v")
  let d = new_tmp(size, name="d")
  cat([
    [assign(d, self.get(fst)), assign(v, e_minus(self.get(rax), ev(d)))],
    after_sub(ev(v), size, self.get(rax), ev(d)),
    [
      // port: when the comparison fails the destination is written back
      // (Intel SDM CMPXCHG: DEST <- TEMP, which zero-extends a 32-bit
      // register in 64-bit mode)
      if_(e_eq(self.get(rax), ev(d)), [self.set(fst, self.get(snd))], [
        self.set(rax, ev(d)),
        self.set(fst, ev(d)),
      ]),
    ],
  ])
}

///|
fn Tools::cmpxchg_rm(
  self : Tools,
  size : Int32,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let (fst, snd) = self.mr()
  let snd = self.reg(snd)
  let rax = self.reg(cmpxchg_rax(size))
  let size = self.width(rax)
  let d = new_tmp(size, name="d")
  let v = new_tmp(size, name="v")
  let bil = cat([
    [assign(d, self.load(fst, size)), assign(v, e_minus(self.get(rax), ev(d)))],
    after_sub(ev(v), size, self.get(rax), ev(d)),
    [
      if_(e_eq(self.get(rax), ev(d)), [self.store(fst, size, self.get(snd))], [
        self.set(rax, ev(d)),
      ]),
    ],
  ])
  if self.has_prefix(0xf0) {
    lock(bil)
  } else {
    bil
  }
}

///|
/// Upstream `Cdq.cdq`: sign-extend `src` into `dst` (or into its high
/// half).
fn Tools::cdq(
  self : Tools,
  src : String,
  dst : String,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let src = self.reg(src)
  let dst = self.reg(dst)
  let src_width = self.width(src)
  let dst_width = self.width(dst)
  let extended_width = 2 * src_width
  let extended_e = e_signed(extended_width, self.get(src))
  if dst_width == extended_width {
    [self.set(dst, extended_e)]
  } else {
    [self.set(dst, e_high(dst_width, extended_e))]
  }
}
