// Primary opcode 31 of the native PowerPC decoder: X, XO, XS and XFX forms
// selected by the extended opcode in bits 21-30 (for XO forms bit 21 is
// the `OE` bit; the `OE=1` forms are not supported and decode as invalid).

///|
/// SPR number of the split 10-bit field of `mtspr`/`mfspr`
/// (`spr[5:9] || spr[0:4]`).
fn spr_field(w : UInt) -> Int {
  (field(w, 16, 20) << 5) | field(w, 11, 15)
}

///|
fn decode_x31(w : UInt) -> Spec? {
  let rt = field(w, 6, 10)
  let ra = field(w, 11, 15)
  let rb = field(w, 16, 20)
  let rc = field(w, 31, 31) == 1
  // XO-form `rt, ra, rb`
  let arith = (name : String, mnemonic : String, cls : Cls) => {
    Some(
      record(name, mnemonic, rc, [
        reg_arg(cls, rt),
        reg_arg(cls, ra),
        reg_arg(cls, rb),
      ]),
    )
  }
  // XO-form `rt, ra` (rb must be zero)
  let arith2 = (name : String, mnemonic : String) => {
    if rb == 0 {
      Some(record(name, mnemonic, rc, [Gpr(rt), Gpr(ra)]))
    } else {
      None
    }
  }
  // X-form `rt, ra, rb` without a record form
  let modulo = (name : String, mnemonic : String, cls : Cls) => {
    plain(name, mnemonic, rc, [
      reg_arg(cls, rt),
      reg_arg(cls, ra),
      reg_arg(cls, rb),
    ])
  }
  // X-form logical `ra, rs, rb` (`rb` is a word register for the 64-bit
  // shifts)
  let logical = (name : String, mnemonic : String, cls : Cls, rb_cls : Cls) => {
    Some(
      record(name, mnemonic, rc, [
        reg_arg(cls, ra),
        reg_arg(cls, rt),
        reg_arg(rb_cls, rb),
      ]),
    )
  }
  let logical_plain = (name : String, mnemonic : String, cls : Cls) => {
    plain(name, mnemonic, rc, [
      reg_arg(cls, ra),
      reg_arg(cls, rt),
      reg_arg(cls, rb),
    ])
  }
  // X-form unary `ra, rs` (rb must be zero)
  let unary = (name : String, mnemonic : String, cls : Cls, has_rec : Bool) => {
    if rb != 0 || (rc && !has_rec) {
      None
    } else {
      Some(record(name, mnemonic, rc, [reg_arg(cls, ra), reg_arg(cls, rt)]))
    }
  }
  // X-form compares `bf, ra, rb`
  let compare = (logical : Bool) => {
    if field(w, 9, 9) != 0 || rc {
      None
    } else {
      let wide = field(w, 10, 10) == 1
      let (name, mnemonic, cls) = match (logical, wide) {
        (false, false) => ("CMPW", "cmpw", W)
        (false, true) => ("CMPD", "cmpd", D)
        (true, false) => ("CMPLW", "cmplw", W)
        (true, true) => ("CMPLD", "cmpld", D)
      }
      Some(
        spec(name, mnemonic, [
          Crf(field(w, 6, 8)),
          reg_arg(cls, ra),
          reg_arg(cls, rb),
        ]),
      )
    }
  }
  // X-form indexed loads `rt, ra, rb`; the update forms have the updated
  // base register after `rt`
  let load = (name : String, mnemonic : String, cls : Cls, update : Bool) => {
    let args = if update {
      [reg_arg(cls, rt), Silent(Gpr0(ra)), Gpr0(ra), Gpr(rb)]
    } else {
      [reg_arg(cls, rt), Gpr0(ra), Gpr(rb)]
    }
    plain(name, mnemonic, rc, args, kinds=load_kinds)
  }
  // X-form indexed stores `rs, ra, rb`; the update forms have the updated
  // base register first
  let store = (name : String, mnemonic : String, cls : Cls, update : Bool) => {
    let args = if update {
      [Silent(Gpr0(ra)), reg_arg(cls, rt), Gpr0(ra), Gpr(rb)]
    } else {
      [reg_arg(cls, rt), Gpr0(ra), Gpr(rb)]
    }
    plain(name, mnemonic, rc, args, kinds=store_kinds)
  }
  match field(w, 21, 30) {
    // compares
    0 => compare(false)
    32 => compare(true)
    // additions and subtractions
    266 => arith("ADD4", "add", W)
    10 => arith("ADDC", "addc", W)
    138 => arith("ADDE", "adde", W)
    234 => arith2("ADDME", "addme")
    202 => arith2("ADDZE", "addze")
    40 => arith("SUBF", "subf", W)
    8 => arith("SUBFC", "subfc", W)
    136 => arith("SUBFE", "subfe", W)
    232 => arith2("SUBFME", "subfme")
    200 => arith2("SUBFZE", "subfze")
    104 => arith2("NEG", "neg")
    // multiplications and divisions
    235 => arith("MULLW", "mullw", W)
    75 => arith("MULHW", "mulhw", W)
    11 => arith("MULHWU", "mulhwu", W)
    233 => arith("MULLD", "mulld", D)
    73 => arith("MULHD", "mulhd", D)
    9 => arith("MULHDU", "mulhdu", D)
    491 => arith("DIVW", "divw", W)
    459 => arith("DIVWU", "divwu", W)
    427 => arith("DIVWE", "divwe", W)
    395 => arith("DIVWEU", "divweu", W)
    489 => arith("DIVD", "divd", D)
    457 => arith("DIVDU", "divdu", D)
    425 => arith("DIVDE", "divde", D)
    393 => arith("DIVDEU", "divdeu", D)
    779 => modulo("MODSW", "modsw", W)
    267 => modulo("MODUW", "moduw", W)
    777 => modulo("MODSD", "modsd", D)
    265 => modulo("MODUD", "modud", D)
    // logical
    28 => logical("AND", "and", W, W)
    60 => logical("ANDC", "andc", W, W)
    444 =>
      if rt == rb {
        // `or ra, rs, rs` is printed as `mr ra, rs`
        Some(record("OR", "mr", rc, [Gpr(ra), Gpr(rt), Silent(Gpr(rb))]))
      } else {
        logical("OR", "or", W, W)
      }
    412 => logical("ORC", "orc", W, W)
    316 => logical("XOR", "xor", W, W)
    476 => logical("NAND", "nand", W, W)
    124 => logical("NOR", "nor", W, W)
    284 => logical("EQV", "eqv", W, W)
    508 => logical_plain("CMPB", "cmpb", W)
    252 => logical_plain("BPERMD", "bpermd", D)
    954 => unary("EXTSB", "extsb", W, true)
    922 => unary("EXTSH", "extsh", W, true)
    986 => unary("EXTSW", "extsw", D, true)
    26 => unary("CNTLZW", "cntlzw", W, true)
    58 => unary("CNTLZD", "cntlzd", D, true)
    538 => unary("CNTTZW", "cnttzw", W, true)
    570 => unary("CNTTZD", "cnttzd", D, true)
    378 => unary("POPCNTW", "popcntw", W, false)
    506 => unary("POPCNTD", "popcntd", D, false)
    // shifts
    24 => logical("SLW", "slw", W, W)
    536 => logical("SRW", "srw", W, W)
    792 => logical("SRAW", "sraw", W, W)
    27 => logical("SLD", "sld", D, W)
    539 => logical("SRD", "srd", D, W)
    794 => logical("SRAD", "srad", D, W)
    824 =>
      Some(record("SRAWI", "srawi", rc, [Gpr(ra), Gpr(rt), Imm(rb.to_int64())]))
    826 | 827 => {
      let sh = rb | (field(w, 30, 30) << 5)
      Some(record("SRADI", "sradi", rc, [G8(ra), G8(rt), Imm(sh.to_int64())]))
    }
    // loads
    87 => load("LBZX", "lbzx", W, false)
    119 => load("LBZUX", "lbzux", W, true)
    279 => load("LHZX", "lhzx", W, false)
    311 => load("LHZUX", "lhzux", W, true)
    343 => load("LHAX", "lhax", W, false)
    375 => load("LHAUX", "lhaux", W, true)
    23 => load("LWZX", "lwzx", W, false)
    55 => load("LWZUX", "lwzux", W, true)
    341 => load("LWAX", "lwax", D, false)
    373 => load("LWAUX", "lwaux", D, true)
    21 => load("LDX", "ldx", D, false)
    53 => load("LDUX", "ldux", D, true)
    790 => load("LHBRX", "lhbrx", W, false)
    534 => load("LWBRX", "lwbrx", W, false)
    532 => load("LDBRX", "ldbrx", D, false)
    // stores
    215 => store("STBX", "stbx", W, false)
    247 => store("STBUX", "stbux", W, true)
    407 => store("STHX", "sthx", W, false)
    439 => store("STHUX", "sthux", W, true)
    151 => store("STWX", "stwx", W, false)
    183 => store("STWUX", "stwux", W, true)
    149 => store("STDX", "stdx", D, false)
    181 => store("STDUX", "stdux", D, true)
    918 => store("STHBRX", "sthbrx", W, false)
    662 => store("STWBRX", "stwbrx", W, false)
    660 => store("STDBRX", "stdbrx", D, false)
    // moves to and from special purpose and condition registers
    339 =>
      match spr_field(w) {
        8 => plain("MFLR", "mflr", rc, [Gpr(rt)])
        9 => plain("MFCTR", "mfctr", rc, [Gpr(rt)])
        spr => plain("MFSPR", "mfspr", rc, [Gpr(rt), Imm(spr.to_int64())])
      }
    467 =>
      match spr_field(w) {
        8 => plain("MTLR", "mtlr", rc, [Gpr(rt)])
        9 => plain("MTCTR", "mtctr", rc, [Gpr(rt)])
        spr => plain("MTSPR", "mtspr", rc, [Imm(spr.to_int64()), Gpr(rt)])
      }
    144 =>
      if field(w, 11, 11) == 0 && field(w, 20, 20) == 0 {
        plain("MTCRF", "mtcrf", rc, [Imm(field(w, 12, 19).to_int64()), Gpr(rt)])
      } else {
        None
      }
    19 =>
      if field(w, 11, 20) == 0 {
        plain("MFCR", "mfcr", rc, [Gpr(rt)])
      } else {
        None
      }
    _ => None
  }
}
