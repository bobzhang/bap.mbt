// Primary opcode 31 of the native PowerPC decoder: X, XO, XS and XFX forms
// selected by the extended opcode in bits 21-30 (for XO forms bit 21 is
// the `OE` bit; the `OE=1` forms are not supported and decode as invalid).

///|
/// SPR number of the split 10-bit field of `mtspr`/`mfspr`
/// (`spr[5:9] || spr[0:4]`).
fn spr_field(w : UInt32) -> Int32 {
  (field(w, 16, 20) << 5) | field(w, 11, 15)
}

///|
/// `mfspr`/`mtspr` access all the special purpose registers: LLVM marks
/// them as loading and storing.
let spr_kinds : Array[@mc.Kind] = [MayLoad, MayStore]

///|
/// The extended `mfspr`/`mtspr` mnemonic suffix printed by LLVM for the
/// special purpose register `spr` (`mfxer`, `mtsrr0`, ...), with the index
/// operand of the BAT registers (`mfibatu 3, 0`). Some registers are
/// only named in reads (`from`, `mfspr`) or only in writes (`mtspr`).
fn spr_mnemonic(spr : Int32, from~ : Bool) -> (String, Int32?)? {
  match spr {
    1 => Some(("xer", None))
    4 if from => Some(("rtcu", None))
    5 if from => Some(("rtcl", None))
    13 => Some(("uamr", None))
    17 => Some(("dscr", None))
    18 => Some(("dsisr", None))
    19 => Some(("dar", None))
    22 => Some(("dec", None))
    25 => Some(("sdr1", None))
    26 => Some(("srr0", None))
    27 => Some(("srr1", None))
    28 => Some(("cfar", None))
    29 => Some(("amr", None))
    280 => Some(("asr", None))
    284 if !from => Some(("tbl", None))
    285 if !from => Some(("tbu", None))
    287 if from => Some(("pvr", None))
    512 => Some(("spefscr", None))
    528..<=543 => {
      let n = spr - 528
      let kind = if n < 8 { "ibat" } else { "dbat" }
      let half = if n % 2 == 0 { "u" } else { "l" }
      Some((kind + half, Some(n % 8 / 2)))
    }
    896 => Some(("ppr", None))
    980 => Some(("esr", None))
    981 => Some(("dear", None))
    986 => Some(("tcr", None))
    988 => Some(("tbhi", None))
    989 => Some(("tblo", None))
    990 => Some(("srr2", None))
    991 => Some(("srr3", None))
    1018 => Some(("dccr", None))
    1019 => Some(("iccr", None))
    _ => None
  }
}

///|
/// `sub`/`subc` print `subf rt, ra, rb` as `sub rt, rb, ra`.
fn sub_alias(spec : Spec, mnemonic : String, rc : Bool) -> Spec {
  guard spec.args is [rt, ra, rb] else { spec }
  spec.printed_as(if rc { mnemonic + "." } else { mnemonic }, [rt, rb, ra])
}

///|
fn decode_x31(w : UInt32) -> Spec? {
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
        omit_cr0(
          spec(name, mnemonic, [
            Crf(field(w, 6, 8)),
            reg_arg(cls, ra),
            reg_arg(cls, rb),
          ]),
        ),
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
    // `subf rt, ra, rb` is printed as `sub rt, rb, ra`
    40 => arith("SUBF", "subf", W).map(s => sub_alias(s, "sub", rc))
    8 => arith("SUBFC", "subfc", W).map(s => sub_alias(s, "subc", rc))
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
    124 =>
      logical("NOR", "nor", W, W).map(spec => {
        if rt == rb {
          // `nor ra, rs, rs` is printed as `not ra, rs`
          spec.printed_as(if rc { "not." } else { "not" }, [Gpr(ra), Gpr(rt)])
        } else {
          spec
        }
      })
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
        3 => plain("MFUDSCR", "mfudscr", rc, [Gpr(rt)])
        8 => plain("MFLR", "mflr", rc, [Gpr(rt)])
        9 => plain("MFCTR", "mfctr", rc, [Gpr(rt)])
        spr =>
          plain(
            "MFSPR",
            "mfspr",
            rc,
            [Gpr(rt), Imm(spr.to_int64())],
            kinds=spr_kinds,
          ).map(spec => {
            match spr_mnemonic(spr, from=true) {
              Some((name, None)) => spec.printed_as("mf" + name, [Gpr(rt)])
              Some((name, Some(n))) =>
                spec.printed_as("mf" + name, [Gpr(rt), Imm(n.to_int64())])
              None => spec
            }
          })
      }
    467 =>
      match spr_field(w) {
        3 => plain("MTUDSCR", "mtudscr", rc, [Gpr(rt)])
        8 => plain("MTLR", "mtlr", rc, [Gpr(rt)])
        9 => plain("MTCTR", "mtctr", rc, [Gpr(rt)])
        spr =>
          plain(
            "MTSPR",
            "mtspr",
            rc,
            [Imm(spr.to_int64()), Gpr(rt)],
            kinds=spr_kinds,
          ).map(spec => {
            match spr_mnemonic(spr, from=false) {
              Some((name, None)) => spec.printed_as("mt" + name, [Gpr(rt)])
              Some((name, Some(n))) =>
                spec.printed_as("mt" + name, [Imm(n.to_int64()), Gpr(rt)])
              None => spec
            }
          })
      }
    144 =>
      if field(w, 11, 11) == 0 && field(w, 20, 20) == 0 {
        plain("MTCRF", "mtcrf", rc, [Imm(field(w, 12, 19).to_int64()), Gpr(rt)]).map(spec => {
            // all fields: `mtcr rs`
            if field(w, 12, 19) == 255 {
              spec.printed_as("mtcr", [Gpr(rt)])
            } else {
              spec
            }
          },
        )
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
