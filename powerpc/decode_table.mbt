// Instruction tables of the native PowerPC decoder: the encodings of the
// instructions supported by the lifter (and of the few LLVM instructions
// carved out of their encodings, e.g. `BDZL` or `BDNZLRL`), mapped to the
// opcode names and operand lists produced by the LLVM PowerPC disassembler.
//
// As in LLVM, instructions whose 64-bit variant shares the encoding of a
// 32-bit one decode as the 32-bit variant (`ADDI`, `ADD4`, `OR`, `MTCTR`,
// ...; the `ADDI8`-style variants are code-generation only); 64-bit only
// instructions (`LD`, `STD`, `RLDICL`, `MULLD`, `EXTSW`, `CMPD`, ...) use
// `X` registers. Record (`Rc=1`) forms are named with the `_rec` suffix of
// LLVM 10 and later. Reserved fields must be zero. `addi`/`addis` with
// `ra = 0` decode as `LI`/`LIS` (as LLVM 22 does), and the assembly uses
// the extended mnemonics chosen by the LLVM instruction printer (`bt`,
// `slwi`, `clrldi`, `sub`, `mfxer`, `crnot`, ...). LLVM has no `bctar`.

///|
/// Bits `from..to` (inclusive, numbered from the most significant bit as in
/// the Power ISA) of the instruction word.
fn field(w : UInt, from : Int, to : Int) -> Int {
  let width = to - from + 1
  ((w >> (31 - to)) & ((1U << width) - 1)).reinterpret_as_int()
}

///|
/// Sign-extend the low `bits` bits of `v`.
fn sext(v : Int, bits : Int) -> Int64 {
  let shift = 64 - bits
  v.to_int64() << shift >> shift
}

///|
let branch_kinds : Array[@mc.Kind] = [
  UnconditionalBranch,
  Barrier,
  Terminator,
  MayAffectControlFlow,
]

///|
let call_kinds : Array[@mc.Kind] = [Call, MayAffectControlFlow]

///|
let cond_kinds : Array[@mc.Kind] = [ConditionalBranch, MayAffectControlFlow]

///|
let cond_term_kinds : Array[@mc.Kind] = [
  ConditionalBranch,
  Terminator,
  MayAffectControlFlow,
]

///|
let load_kinds : Array[@mc.Kind] = [MayLoad]

///|
let store_kinds : Array[@mc.Kind] = [MayStore]

///|
/// Register class of a register operand.
priv enum Cls {
  W
  D
}

///|
fn reg_arg(cls : Cls, n : Int) -> Arg {
  match cls {
    W => Gpr(n)
    D => G8(n)
  }
}

///|
/// A form with an optional record variant: `name_rec`/`mnemonic.` when the
/// `Rc` bit is set.
fn record(
  name : String,
  mnemonic : String,
  rc : Bool,
  args : Array[Arg],
) -> Spec {
  if rc {
    spec(name + "_rec", mnemonic + ".", args)
  } else {
    spec(name, mnemonic, args)
  }
}

///|
/// A form without a record variant: invalid when the `Rc` bit is set.
fn plain(
  name : String,
  mnemonic : String,
  rc : Bool,
  args : Array[Arg],
  kinds? : Array[@mc.Kind] = [],
) -> Spec? {
  if rc {
    None
  } else {
    Some(spec(name, mnemonic, args, kinds~))
  }
}

///|
/// Decode an instruction word.
fn decode_spec(w : UInt) -> Spec? {
  let rt = field(w, 6, 10)
  let ra = field(w, 11, 15)
  let d = sext(field(w, 16, 31), 16)
  let ui = field(w, 16, 31).to_int64()
  // D-form memory displacement: the raw 16-bit field (see `Arg::Mem`)
  let disp = ui
  match field(w, 0, 5) {
    7 => Some(spec("MULLI", "mulli", [Gpr(rt), Gpr(ra), Imm(d)]))
    8 => Some(spec("SUBFIC", "subfic", [Gpr(rt), Gpr(ra), Imm(d)]))
    10 => decode_cmpi(w, logical=true)
    11 => decode_cmpi(w, logical=false)
    12 => Some(spec("ADDIC", "addic", [Gpr(rt), Gpr(ra), Imm(d)]))
    13 => Some(spec("ADDIC_rec", "addic.", [Gpr(rt), Gpr(ra), Imm(d)]))
    14 =>
      Some(
        if ra == 0 {
          spec("LI", "li", [Gpr(rt), Imm(d)])
        } else {
          spec("ADDI", "addi", [Gpr(rt), Gpr0(ra), Imm(d)])
        },
      )
    15 =>
      Some(
        if ra == 0 {
          spec("LIS", "lis", [Gpr(rt), Imm(d)])
        } else {
          spec("ADDIS", "addis", [Gpr(rt), Gpr0(ra), Imm(d)])
        },
      )
    16 => Some(decode_bform(w))
    18 => Some(decode_iform(w))
    19 => decode_xl(w)
    20 | 21 | 23 => Some(decode_mform(w))
    24 =>
      Some(
        if w == 0x60000000 {
          spec("NOP", "nop", [], kinds=[MayLoad, MayStore])
        } else {
          spec("ORI", "ori", [Gpr(ra), Gpr(rt), Imm(ui)])
        },
      )
    25 => Some(spec("ORIS", "oris", [Gpr(ra), Gpr(rt), Imm(ui)]))
    26 =>
      Some(
        if w == 0x68000000 {
          spec("XORI", "xori", [Gpr(0), Gpr(0), Imm(0)]).printed_as("xnop", [])
        } else {
          spec("XORI", "xori", [Gpr(ra), Gpr(rt), Imm(ui)])
        },
      )
    27 => Some(spec("XORIS", "xoris", [Gpr(ra), Gpr(rt), Imm(ui)]))
    28 => Some(spec("ANDI_rec", "andi.", [Gpr(ra), Gpr(rt), Imm(ui)]))
    29 => Some(spec("ANDIS_rec", "andis.", [Gpr(ra), Gpr(rt), Imm(ui)]))
    30 => decode_md(w)
    31 => decode_x31(w)
    32 => Some(dec_load_d("LWZ", "lwz", false, rt, ra, disp))
    33 => Some(dec_load_d("LWZU", "lwzu", true, rt, ra, disp))
    34 => Some(dec_load_d("LBZ", "lbz", false, rt, ra, disp))
    35 => Some(dec_load_d("LBZU", "lbzu", true, rt, ra, disp))
    36 => Some(dec_store_d("STW", "stw", false, W, rt, ra, disp))
    37 => Some(dec_store_d("STWU", "stwu", true, W, rt, ra, disp))
    38 => Some(dec_store_d("STB", "stb", false, W, rt, ra, disp))
    39 => Some(dec_store_d("STBU", "stbu", true, W, rt, ra, disp))
    40 => Some(dec_load_d("LHZ", "lhz", false, rt, ra, disp))
    41 => Some(dec_load_d("LHZU", "lhzu", true, rt, ra, disp))
    42 => Some(dec_load_d("LHA", "lha", false, rt, ra, disp))
    43 => Some(dec_load_d("LHAU", "lhau", true, rt, ra, disp))
    44 => Some(dec_store_d("STH", "sth", false, W, rt, ra, disp))
    45 => Some(dec_store_d("STHU", "sthu", true, W, rt, ra, disp))
    58 => {
      let ds = sext(field(w, 16, 29) << 2, 16)
      match field(w, 30, 31) {
        0 => Some(spec("LD", "ld", [G8(rt), Mem(ds, ra)], kinds=load_kinds))
        1 =>
          Some(
            spec(
              "LDU",
              "ldu",
              [G8(rt), Silent(Gpr0(ra)), Mem(ds, ra)],
              kinds=load_kinds,
            ),
          )
        2 => Some(spec("LWA", "lwa", [G8(rt), Mem(ds, ra)], kinds=load_kinds))
        _ => None
      }
    }
    62 => {
      let ds = sext(field(w, 16, 29) << 2, 16)
      match field(w, 30, 31) {
        0 => Some(dec_store_d("STD", "std", false, D, rt, ra, ds))
        1 => Some(dec_store_d("STDU", "stdu", true, D, rt, ra, ds))
        _ => None
      }
    }
    _ => None
  }
}

///|
/// D-form load `rt, d(ra)` (with update: the updated base first).
fn dec_load_d(
  name : String,
  mnemonic : String,
  update : Bool,
  rt : Int,
  ra : Int,
  d : Int64,
) -> Spec {
  let args = if update {
    [Gpr(rt), Silent(Gpr0(ra)), Mem(d, ra)]
  } else {
    [Gpr(rt), Mem(d, ra)]
  }
  spec(name, mnemonic, args, kinds=load_kinds)
}

///|
/// D/DS-form store `rs, d(ra)` (with update: the updated base first).
fn dec_store_d(
  name : String,
  mnemonic : String,
  update : Bool,
  cls : Cls,
  rs : Int,
  ra : Int,
  d : Int64,
) -> Spec {
  let args = if update {
    [Silent(Gpr0(ra)), reg_arg(cls, rs), Mem(d, ra)]
  } else {
    [reg_arg(cls, rs), Mem(d, ra)]
  }
  spec(name, mnemonic, args, kinds=store_kinds)
}

///|
/// `cmp[l]wi`/`cmp[l]di bf, ra, imm` (primary opcodes 10 and 11).
fn decode_cmpi(w : UInt, logical~ : Bool) -> Spec? {
  guard field(w, 9, 9) == 0 else { None }
  let bf = field(w, 6, 8)
  let wide = field(w, 10, 10) == 1
  let ra = field(w, 11, 15)
  let imm = if logical {
    field(w, 16, 31).to_int64()
  } else {
    sext(field(w, 16, 31), 16)
  }
  let (name, mnemonic, cls) = match (logical, wide) {
    (false, false) => ("CMPWI", "cmpwi", W)
    (false, true) => ("CMPDI", "cmpdi", D)
    (true, false) => ("CMPLWI", "cmplwi", W)
    (true, true) => ("CMPLDI", "cmpldi", D)
  }
  Some(omit_cr0(spec(name, mnemonic, [Crf(bf), reg_arg(cls, ra), Imm(imm)])))
}

///|
/// Compares into `cr0` are printed without the field (`cmpwi 3, 0`).
fn omit_cr0(spec : Spec) -> Spec {
  if spec.args is [Crf(0), .. rest] {
    spec.printed_as(spec.mnemonic, rest.to_owned())
  } else {
    spec
  }
}

///|
/// I-form branches: `b`, `ba`, `bl`, `bla`.
fn decode_iform(w : UInt) -> Spec {
  let li = sext(field(w, 6, 29), 24)
  let absolute = field(w, 30, 30) == 1
  let link = field(w, 31, 31) == 1
  let args = [Target(li, absolute~)]
  match (absolute, link) {
    (false, false) => spec("B", "b", args, kinds=branch_kinds)
    (true, false) => spec("BA", "ba", args, kinds=branch_kinds)
    (false, true) => spec("BL", "bl", args, kinds=call_kinds)
    (true, true) => spec("BLA", "bla", args, kinds=call_kinds)
  }
}

///|
/// The name suffix and mnemonic of the CTR-decrementing forms (`BDNZ`,
/// `BDZ` and their `+`/`-` hinted variants) selected by `bo`, when `bo` is
/// one of them.
fn ctr_branch(bo : Int) -> (String, String, String, String)? {
  match bo {
    16 => Some(("BDNZ", "", "bdnz", ""))
    24 => Some(("BDNZ", "m", "bdnz", "-"))
    25 => Some(("BDNZ", "p", "bdnz", "+"))
    18 => Some(("BDZ", "", "bdz", ""))
    26 => Some(("BDZ", "m", "bdz", "-"))
    27 => Some(("BDZ", "p", "bdz", "+"))
    _ => None
  }
}

///|
/// The extended mnemonic (and branch prediction hint) of `bc` with the
/// branch options `bo` testing a condition register bit, as printed by LLVM:
/// `bt`/`bf` (with the `-`/`+` hints) and the CTR-decrementing `bdnzt`,
/// `bdnzf`, `bdzt`, `bdzf`.
fn bc_mnemonic(bo : Int) -> (String, String)? {
  match bo {
    0 => Some(("bdnzf", ""))
    2 => Some(("bdzf", ""))
    4 => Some(("bf", ""))
    6 => Some(("bf", "-"))
    7 => Some(("bf", "+"))
    8 => Some(("bdnzt", ""))
    10 => Some(("bdzt", ""))
    12 => Some(("bt", ""))
    14 => Some(("bt", "-"))
    15 => Some(("bt", "+"))
    _ => None
  }
}

///|
/// B-form conditional branches: `gBC`, `gBCA`, `gBCL`, `gBCLA` with the
/// operands `bo, bi, target`; the CTR forms with `bi = 0` decode as
/// `BDNZ`, `BDZ`, ... with the target only.
fn decode_bform(w : UInt) -> Spec {
  let bo = field(w, 6, 10)
  let bi = field(w, 11, 15)
  let bd = sext(field(w, 16, 29), 14)
  let absolute = field(w, 30, 30) == 1
  let link = field(w, 31, 31) == 1
  let a = if absolute { "A" } else { "" }
  let l = if link { "L" } else { "" }
  let suffix = l.to_lower() + a.to_lower()
  let target = Target(bd, absolute~)
  if bi == 0 && ctr_branch(bo) is Some((base, hint, mnemonic, sign)) {
    spec(
      base + l + a + hint,
      mnemonic + suffix + sign,
      [target],
      kinds=if link { call_kinds } else { cond_term_kinds },
    )
  } else {
    let generic = spec(
      "gBC" + l + a,
      "bc" + suffix,
      [Imm(bo.to_int64()), Crb(bi), target],
      kinds=cond_kinds,
    )
    match bc_mnemonic(bo) {
      Some((mnemonic, hint)) =>
        generic.printed_as(mnemonic + suffix + hint, [Crb(bi), target])
      None => generic
    }
  }
}

///|
/// XL-form (primary opcode 19): branches to LR, CTR and TAR, `mcrf` and the
/// condition register logical instructions.
fn decode_xl(w : UInt) -> Spec? {
  let bt = field(w, 6, 10)
  let ba = field(w, 11, 15)
  let bb = field(w, 16, 20)
  let link = field(w, 31, 31) == 1
  let crlogic = (name : String, mnemonic : String) => {
    plain(name, mnemonic, link, [Crb(bt), Crb(ba), Crb(bb)]).map(spec => {
      match (name, bt == ba && ba == bb, ba == bb) {
        ("CREQV", true, _) => spec.printed_as("crset", [Crb(bt)])
        ("CRXOR", true, _) => spec.printed_as("crclr", [Crb(bt)])
        ("CROR", _, true) => spec.printed_as("crmove", [Crb(bt), Crb(ba)])
        ("CRNOR", _, true) => spec.printed_as("crnot", [Crb(bt), Crb(ba)])
        _ => spec
      }
    })
  }
  match field(w, 21, 30) {
    0 =>
      if field(w, 9, 10) == 0 && field(w, 14, 20) == 0 && !link {
        Some(spec("MCRF", "mcrf", [Crf(field(w, 6, 8)), Crf(field(w, 11, 13))]))
      } else {
        None
      }
    16 | 528 as xo => {
      guard field(w, 16, 18) == 0 else { None }
      Some(decode_branch_to_reg(xo, bt, ba, field(w, 19, 20), link))
    }
    257 => crlogic("CRAND", "crand")
    225 => crlogic("CRNAND", "crnand")
    449 => crlogic("CROR", "cror")
    193 => crlogic("CRXOR", "crxor")
    33 => crlogic("CRNOR", "crnor")
    289 => crlogic("CREQV", "creqv")
    129 => crlogic("CRANDC", "crandc")
    417 => crlogic("CRORC", "crorc")
    _ => None
  }
}

///|
/// `bclr` (xo 16) and `bcctr` (528) with their link forms (LLVM has no
/// `bctar`).
fn decode_branch_to_reg(
  xo : Int,
  bo : Int,
  bi : Int,
  bh : Int,
  link : Bool,
) -> Spec {
  let l = if link { "L" } else { "" }
  let (reg, mnemonic_reg) = if xo == 16 { ("LR", "lr") } else { ("CTR", "ctr") }
  let simple = bi == 0 && bh == 0
  if simple && bo == 20 {
    // blr, blrl, bctr, bctrl
    let kinds = match (link, xo) {
      (true, _) => call_kinds
      (false, 16) => [Return, Barrier, Terminator, MayAffectControlFlow]
      (false, _) => [IndirectBranch, Barrier, Terminator, MayAffectControlFlow]
    }
    spec("B" + reg + l, "b" + mnemonic_reg + l.to_lower(), [], kinds~)
  } else if simple &&
    xo == 16 &&
    ctr_branch(bo) is Some((base, hint, mnemonic, sign)) {
    spec(
      base + "LR" + l + hint,
      mnemonic + "lr" + l.to_lower() + sign,
      [],
      kinds=if link {
        call_kinds
      } else {
        [ConditionalBranch, Return, Terminator, MayAffectControlFlow]
      },
    )
  } else {
    let generic = spec(
      "gBC" + reg + l,
      "bc" + mnemonic_reg + l.to_lower(),
      [Imm(bo.to_int64()), Crb(bi), Imm(bh.to_int64())],
      kinds=cond_kinds,
    )
    // the branch hint is printed only when not zero
    if bh == 0 {
      generic.printed_as(generic.mnemonic, [Imm(bo.to_int64()), Crb(bi)])
    } else {
      generic
    }
  }
}

///|
/// M-form rotates: `rlwimi` (20), `rlwinm` (21), `rlwnm` (23), printed with
/// the extended mnemonics chosen by LLVM (`slwi`, `srwi`, `rotlwi`,
/// `clrlwi`, `rotlw`; `slwi` and `srwi` only for the non-record `rlwinm`).
fn decode_mform(w : UInt) -> Spec {
  let rs = field(w, 6, 10)
  let ra = field(w, 11, 15)
  let sh = field(w, 16, 20)
  let mb = field(w, 21, 25)
  let me = field(w, 26, 30)
  let rc = field(w, 31, 31) == 1
  let dot = if rc { "." } else { "" }
  let masks = [Imm(mb.to_int64()), Imm(me.to_int64())]
  match field(w, 0, 5) {
    20 =>
      record(
        "RLWIMI",
        "rlwimi",
        rc,
        [Gpr(ra), Silent(Gpr(ra)), Gpr(rs), Imm(sh.to_int64()), ..masks],
      )
    21 => {
      let generic = record(
        "RLWINM",
        "rlwinm",
        rc,
        [Gpr(ra), Gpr(rs), Imm(sh.to_int64()), ..masks],
      )
      let regs = [Gpr(ra), Gpr(rs)]
      if !rc && mb == 0 && me == 31 - sh {
        generic.printed_as("slwi", [..regs, Imm(sh.to_int64())])
      } else if !rc && sh != 0 && mb == 32 - sh && me == 31 {
        generic.printed_as("srwi", [..regs, Imm(mb.to_int64())])
      } else if mb == 0 && me == 31 {
        generic.printed_as("rotlwi" + dot, [..regs, Imm(sh.to_int64())])
      } else if sh == 0 && me == 31 {
        generic.printed_as("clrlwi" + dot, [..regs, Imm(mb.to_int64())])
      } else {
        generic
      }
    }
    _ => {
      let generic = record(
        "RLWNM",
        "rlwnm",
        rc,
        [Gpr(ra), Gpr(rs), Gpr(sh), ..masks],
      )
      if mb == 0 && me == 31 {
        generic.printed_as("rotlw" + dot, [Gpr(ra), Gpr(rs), Gpr(sh)])
      } else {
        generic
      }
    }
  }
}

///|
/// MD/MDS-form 64-bit rotates (primary opcode 30). The 6-bit shift and mask
/// fields are split: `sh = sh[5] || sh[0:4]`, `mb = mb[5] || mb[0:4]`. The
/// extended mnemonics are those printed by LLVM: `rotldi`, `clrldi`,
/// `rotld` and (non-record only) `sldi`.
fn decode_md(w : UInt) -> Spec? {
  let rs = field(w, 6, 10)
  let ra = field(w, 11, 15)
  let rb = field(w, 16, 20)
  let shv = field(w, 16, 20) | (field(w, 30, 30) << 5)
  let mbv = field(w, 21, 25) | (field(w, 26, 26) << 5)
  let sh = Imm(shv.to_int64())
  let mb = Imm(mbv.to_int64())
  let rc = field(w, 31, 31) == 1
  let dot = if rc { "." } else { "" }
  let regs = [G8(ra), G8(rs)]
  match field(w, 27, 29) {
    0 => {
      let generic = record("RLDICL", "rldicl", rc, [..regs, sh, mb])
      if mbv == 0 {
        Some(generic.printed_as("rotldi" + dot, [..regs, sh]))
      } else if shv == 0 {
        Some(generic.printed_as("clrldi" + dot, [..regs, mb]))
      } else {
        Some(generic)
      }
    }
    1 => {
      let generic = record("RLDICR", "rldicr", rc, [..regs, sh, mb])
      if !rc && mbv == 63 - shv {
        Some(generic.printed_as("sldi", [..regs, sh]))
      } else {
        Some(generic)
      }
    }
    2 => Some(record("RLDIC", "rldic", rc, [..regs, sh, mb]))
    3 =>
      Some(
        record("RLDIMI", "rldimi", rc, [G8(ra), Silent(G8(ra)), G8(rs), sh, mb]),
      )
    4 =>
      match field(w, 30, 30) {
        0 => {
          let generic = record("RLDCL", "rldcl", rc, [..regs, Gpr(rb), mb])
          if mbv == 0 {
            Some(generic.printed_as("rotld" + dot, [..regs, Gpr(rb)]))
          } else {
            Some(generic)
          }
        }
        _ => Some(record("RLDCR", "rldcr", rc, [..regs, Gpr(rb), mb]))
      }
    _ => None
  }
}
