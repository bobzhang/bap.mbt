// Per-opcode decoder tests: hand-assembled encodings (fields from the
// Power ISA 3.0 B) of every opcode supported by the lifter.

///|
/// D form `opcode rt, ra, imm`.
fn d_form(opcode : Int, rt : Int, ra : Int, imm : Int) -> UInt {
  enc([(opcode, 6), (rt, 5), (ra, 5), (imm, 16)])
}

///|
/// DS form `opcode rt, ds(ra)` with the extended opcode `xo`.
fn ds_form(opcode : Int, rt : Int, ra : Int, ds : Int, xo : Int) -> UInt {
  enc([(opcode, 6), (rt, 5), (ra, 5), (ds, 14), (xo, 2)])
}

///|
/// X form (primary opcode 31).
fn x_form(rt : Int, ra : Int, rb : Int, xo : Int, rc? : Int = 0) -> UInt {
  enc([(31, 6), (rt, 5), (ra, 5), (rb, 5), (xo, 10), (rc, 1)])
}

///|
/// XO form (primary opcode 31) with `OE = oe`.
fn xo_form(
  rt : Int,
  ra : Int,
  rb : Int,
  xo : Int,
  rc? : Int = 0,
  oe? : Int = 0,
) -> UInt {
  enc([(31, 6), (rt, 5), (ra, 5), (rb, 5), (oe, 1), (xo, 9), (rc, 1)])
}

///|
/// M form rotates.
fn m_form(
  opcode : Int,
  rs : Int,
  ra : Int,
  sh : Int,
  mb : Int,
  me : Int,
  rc? : Int = 0,
) -> UInt {
  enc([(opcode, 6), (rs, 5), (ra, 5), (sh, 5), (mb, 5), (me, 5), (rc, 1)])
}

///|
/// MD form rotates: the 6-bit `sh` and `mb` fields are split.
fn md_form(
  xo : Int,
  rs : Int,
  ra : Int,
  sh : Int,
  mb : Int,
  rc? : Int = 0,
) -> UInt {
  enc([
    (30, 6),
    (rs, 5),
    (ra, 5),
    (sh & 31, 5),
    (((mb & 31) << 1) | (mb >> 5), 6),
    (xo, 3),
    (sh >> 5, 1),
    (rc, 1),
  ])
}

///|
/// MDS form rotates.
fn mds_form(
  xo : Int,
  rs : Int,
  ra : Int,
  rb : Int,
  mb : Int,
  rc? : Int = 0,
) -> UInt {
  enc([
    (30, 6),
    (rs, 5),
    (ra, 5),
    (rb, 5),
    (((mb & 31) << 1) | (mb >> 5), 6),
    (xo, 4),
    (rc, 1),
  ])
}

///|
/// XL form branches `bo, bi, bh`.
fn xl_branch(bo : Int, bi : Int, bh : Int, xo : Int, lk : Int) -> UInt {
  enc([(19, 6), (bo, 5), (bi, 5), (0, 3), (bh, 2), (xo, 10), (lk, 1)])
}

///|
/// XL form CR logical instructions `bt, ba, bb`.
fn xl_cr(bt : Int, ba : Int, bb : Int, xo : Int) -> UInt {
  enc([(19, 6), (bt, 5), (ba, 5), (bb, 5), (xo, 10), (0, 1)])
}

///|
/// B form `bc bo, bi, bd`.
fn b_form(bo : Int, bi : Int, bd : Int, aa : Int, lk : Int) -> UInt {
  enc([(16, 6), (bo, 5), (bi, 5), (bd, 14), (aa, 1), (lk, 1)])
}

///|
/// I form `b li`.
fn i_form(li : Int, aa : Int, lk : Int) -> UInt {
  enc([(18, 6), (li, 24), (aa, 1), (lk, 1)])
}

///|
/// XFX form `mtspr`/`mfspr` of the SPR number `spr` (the halves of the
/// 10-bit field are swapped).
fn spr_form(rt : Int, spr : Int, xo : Int) -> UInt {
  enc([(31, 6), (rt, 5), (spr & 31, 5), (spr >> 5, 5), (xo, 10), (0, 1)])
}

///|
/// Hand-assembled encodings of every opcode supported by the lifter and
/// decoded by LLVM, with the expected LLVM opcode name.
let opcode_samples : Array[(String, UInt)] = [
  // D form arithmetic and compares
  ("MULLI", d_form(7, 3, 4, 0xFFF9)),
  ("SUBFIC", d_form(8, 3, 4, 100)),
  ("CMPLWI", enc([(10, 6), (5, 3), (0, 1), (0, 1), (4, 5), (0xFFFF, 16)])),
  ("CMPLDI", enc([(10, 6), (5, 3), (0, 1), (1, 1), (4, 5), (7, 16)])),
  ("CMPWI", enc([(11, 6), (0, 3), (0, 1), (0, 1), (4, 5), (0x8000, 16)])),
  ("CMPDI", enc([(11, 6), (1, 3), (0, 1), (1, 1), (4, 5), (1, 16)])),
  ("ADDIC", d_form(12, 3, 4, 0xFFFF)),
  ("ADDIC_rec", d_form(13, 3, 4, 1)),
  ("ADDI", d_form(14, 3, 4, 0x7FFF)),
  ("ADDIS", d_form(15, 3, 4, 0x8000)),
  ("LI", d_form(14, 3, 0, 0xFFF0)),
  ("LIS", d_form(15, 3, 0, 0x1234)),
  // D form logical
  ("NOP", d_form(24, 0, 0, 0)),
  ("ORI", d_form(24, 3, 4, 0xFFFF)),
  ("ORIS", d_form(25, 3, 4, 1)),
  ("XORI", d_form(26, 3, 4, 2)),
  ("XORIS", d_form(27, 3, 4, 3)),
  ("ANDI_rec", d_form(28, 3, 4, 4)),
  ("ANDIS_rec", d_form(29, 3, 4, 5)),
  // D and DS form loads and stores
  ("LWZ", d_form(32, 3, 1, 8)),
  ("LWZU", d_form(33, 3, 1, 0xFFF8)),
  ("LBZ", d_form(34, 3, 0, 8)),
  ("LBZU", d_form(35, 3, 1, 8)),
  ("STW", d_form(36, 3, 1, 8)),
  ("STWU", d_form(37, 1, 1, 0xFFE0)),
  ("STB", d_form(38, 3, 1, 8)),
  ("STBU", d_form(39, 3, 1, 8)),
  ("LHZ", d_form(40, 3, 1, 8)),
  ("LHZU", d_form(41, 3, 1, 8)),
  ("LHA", d_form(42, 3, 1, 8)),
  ("LHAU", d_form(43, 3, 1, 8)),
  ("STH", d_form(44, 3, 1, 8)),
  ("STHU", d_form(45, 3, 1, 8)),
  ("LD", ds_form(58, 3, 1, 0x3FFE, 0)),
  ("LDU", ds_form(58, 3, 1, 2, 1)),
  ("LWA", ds_form(58, 3, 1, 2, 2)),
  ("STD", ds_form(62, 3, 1, 2, 0)),
  ("STDU", ds_form(62, 1, 1, 0x3FF0, 1)),
  // X form loads and stores
  ("LBZX", x_form(3, 4, 5, 87)),
  ("LBZUX", x_form(3, 4, 5, 119)),
  ("LHZX", x_form(3, 4, 5, 279)),
  ("LHZUX", x_form(3, 4, 5, 311)),
  ("LHAX", x_form(3, 4, 5, 343)),
  ("LHAUX", x_form(3, 4, 5, 375)),
  ("LWZX", x_form(3, 0, 5, 23)),
  ("LWZUX", x_form(3, 4, 5, 55)),
  ("LWAX", x_form(3, 4, 5, 341)),
  ("LWAUX", x_form(3, 4, 5, 373)),
  ("LDX", x_form(3, 4, 5, 21)),
  ("LDUX", x_form(3, 4, 5, 53)),
  ("LHBRX", x_form(3, 4, 5, 790)),
  ("LWBRX", x_form(3, 4, 5, 534)),
  ("LDBRX", x_form(3, 4, 5, 532)),
  ("STBX", x_form(3, 4, 5, 215)),
  ("STBUX", x_form(3, 4, 5, 247)),
  ("STHX", x_form(3, 4, 5, 407)),
  ("STHUX", x_form(3, 4, 5, 439)),
  ("STWX", x_form(3, 4, 5, 151)),
  ("STWUX", x_form(3, 4, 5, 183)),
  ("STDX", x_form(3, 4, 5, 149)),
  ("STDUX", x_form(3, 4, 5, 181)),
  ("STHBRX", x_form(3, 4, 5, 918)),
  ("STWBRX", x_form(3, 4, 5, 662)),
  ("STDBRX", x_form(3, 4, 5, 660)),
  // XO form arithmetic
  ("ADD4", xo_form(3, 4, 5, 266)),
  ("ADD4_rec", xo_form(3, 4, 5, 266, rc=1)),
  ("ADDC", xo_form(3, 4, 5, 10)),
  ("ADDC_rec", xo_form(3, 4, 5, 10, rc=1)),
  ("ADDE", xo_form(3, 4, 5, 138)),
  ("ADDE_rec", xo_form(3, 4, 5, 138, rc=1)),
  ("ADDME", xo_form(3, 4, 0, 234)),
  ("ADDME_rec", xo_form(3, 4, 0, 234, rc=1)),
  ("ADDZE", xo_form(3, 4, 0, 202)),
  ("ADDZE_rec", xo_form(3, 4, 0, 202, rc=1)),
  ("SUBF", xo_form(3, 4, 5, 40)),
  ("SUBF_rec", xo_form(3, 4, 5, 40, rc=1)),
  ("SUBFC", xo_form(3, 4, 5, 8)),
  ("SUBFC_rec", xo_form(3, 4, 5, 8, rc=1)),
  ("SUBFE", xo_form(3, 4, 5, 136)),
  ("SUBFE_rec", xo_form(3, 4, 5, 136, rc=1)),
  ("SUBFME", xo_form(3, 4, 0, 232)),
  ("SUBFME_rec", xo_form(3, 4, 0, 232, rc=1)),
  ("SUBFZE", xo_form(3, 4, 0, 200)),
  ("SUBFZE_rec", xo_form(3, 4, 0, 200, rc=1)),
  ("NEG", xo_form(3, 4, 0, 104)),
  ("NEG_rec", xo_form(3, 4, 0, 104, rc=1)),
  ("MULLW", xo_form(3, 4, 5, 235)),
  ("MULLW_rec", xo_form(3, 4, 5, 235, rc=1)),
  ("MULHW", xo_form(3, 4, 5, 75)),
  ("MULHW_rec", xo_form(3, 4, 5, 75, rc=1)),
  ("MULHWU", xo_form(3, 4, 5, 11)),
  ("MULHWU_rec", xo_form(3, 4, 5, 11, rc=1)),
  ("MULLD", xo_form(3, 4, 5, 233)),
  ("MULLD_rec", xo_form(3, 4, 5, 233, rc=1)),
  ("MULHD", xo_form(3, 4, 5, 73)),
  ("MULHD_rec", xo_form(3, 4, 5, 73, rc=1)),
  ("MULHDU", xo_form(3, 4, 5, 9)),
  ("MULHDU_rec", xo_form(3, 4, 5, 9, rc=1)),
  ("DIVW", xo_form(3, 4, 5, 491)),
  ("DIVW_rec", xo_form(3, 4, 5, 491, rc=1)),
  ("DIVWU", xo_form(3, 4, 5, 459)),
  ("DIVWU_rec", xo_form(3, 4, 5, 459, rc=1)),
  ("DIVWE", xo_form(3, 4, 5, 427)),
  ("DIVWE_rec", xo_form(3, 4, 5, 427, rc=1)),
  ("DIVWEU", xo_form(3, 4, 5, 395)),
  ("DIVWEU_rec", xo_form(3, 4, 5, 395, rc=1)),
  ("DIVD", xo_form(3, 4, 5, 489)),
  ("DIVD_rec", xo_form(3, 4, 5, 489, rc=1)),
  ("DIVDU", xo_form(3, 4, 5, 457)),
  ("DIVDU_rec", xo_form(3, 4, 5, 457, rc=1)),
  ("DIVDE", xo_form(3, 4, 5, 425)),
  ("DIVDE_rec", xo_form(3, 4, 5, 425, rc=1)),
  ("DIVDEU", xo_form(3, 4, 5, 393)),
  ("DIVDEU_rec", xo_form(3, 4, 5, 393, rc=1)),
  ("MODSW", x_form(3, 4, 5, 779)),
  ("MODUW", x_form(3, 4, 5, 267)),
  ("MODSD", x_form(3, 4, 5, 777)),
  ("MODUD", x_form(3, 4, 5, 265)),
  // X form compares
  ("CMPW", enc([(31, 6), (6, 3), (0, 2), (4, 5), (5, 5), (0, 10), (0, 1)])),
  (
    "CMPD",
    enc([(31, 6), (6, 3), (0, 1), (1, 1), (4, 5), (5, 5), (0, 10), (0, 1)]),
  ),
  ("CMPLW", enc([(31, 6), (6, 3), (0, 2), (4, 5), (5, 5), (32, 10), (0, 1)])),
  (
    "CMPLD",
    enc([(31, 6), (6, 3), (0, 1), (1, 1), (4, 5), (5, 5), (32, 10), (0, 1)]),
  ),
  // X form logical (`rs, ra, rb` fields)
  ("AND", x_form(4, 3, 5, 28)),
  ("AND_rec", x_form(4, 3, 5, 28, rc=1)),
  ("ANDC", x_form(4, 3, 5, 60)),
  ("ANDC_rec", x_form(4, 3, 5, 60, rc=1)),
  ("OR", x_form(4, 3, 5, 444)),
  ("OR_rec", x_form(4, 3, 4, 444, rc=1)),
  ("ORC", x_form(4, 3, 5, 412)),
  ("ORC_rec", x_form(4, 3, 5, 412, rc=1)),
  ("XOR", x_form(4, 3, 5, 316)),
  ("XOR_rec", x_form(4, 3, 5, 316, rc=1)),
  ("NAND", x_form(4, 3, 5, 476)),
  ("NAND_rec", x_form(4, 3, 5, 476, rc=1)),
  ("NOR", x_form(4, 3, 5, 124)),
  ("NOR_rec", x_form(4, 3, 5, 124, rc=1)),
  ("EQV", x_form(4, 3, 5, 284)),
  ("EQV_rec", x_form(4, 3, 5, 284, rc=1)),
  ("CMPB", x_form(4, 3, 5, 508)),
  ("BPERMD", x_form(4, 3, 5, 252)),
  ("EXTSB", x_form(4, 3, 0, 954)),
  ("EXTSB_rec", x_form(4, 3, 0, 954, rc=1)),
  ("EXTSH", x_form(4, 3, 0, 922)),
  ("EXTSH_rec", x_form(4, 3, 0, 922, rc=1)),
  ("EXTSW", x_form(4, 3, 0, 986)),
  ("EXTSW_rec", x_form(4, 3, 0, 986, rc=1)),
  ("CNTLZW", x_form(4, 3, 0, 26)),
  ("CNTLZW_rec", x_form(4, 3, 0, 26, rc=1)),
  ("CNTLZD", x_form(4, 3, 0, 58)),
  ("CNTLZD_rec", x_form(4, 3, 0, 58, rc=1)),
  ("CNTTZW", x_form(4, 3, 0, 538)),
  ("CNTTZW_rec", x_form(4, 3, 0, 538, rc=1)),
  ("CNTTZD", x_form(4, 3, 0, 570)),
  ("CNTTZD_rec", x_form(4, 3, 0, 570, rc=1)),
  ("POPCNTW", x_form(4, 3, 0, 378)),
  ("POPCNTD", x_form(4, 3, 0, 506)),
  // shifts
  ("SLW", x_form(4, 3, 5, 24)),
  ("SLW_rec", x_form(4, 3, 5, 24, rc=1)),
  ("SRW", x_form(4, 3, 5, 536)),
  ("SRW_rec", x_form(4, 3, 5, 536, rc=1)),
  ("SRAW", x_form(4, 3, 5, 792)),
  ("SRAW_rec", x_form(4, 3, 5, 792, rc=1)),
  ("SRAWI", x_form(4, 3, 31, 824)),
  ("SRAWI_rec", x_form(4, 3, 1, 824, rc=1)),
  ("SLD", x_form(4, 3, 5, 27)),
  ("SLD_rec", x_form(4, 3, 5, 27, rc=1)),
  ("SRD", x_form(4, 3, 5, 539)),
  ("SRD_rec", x_form(4, 3, 5, 539, rc=1)),
  ("SRAD", x_form(4, 3, 5, 794)),
  ("SRAD_rec", x_form(4, 3, 5, 794, rc=1)),
  ("SRADI", enc([(31, 6), (4, 5), (3, 5), (31, 5), (413, 9), (1, 1), (0, 1)])),
  (
    "SRADI_rec",
    enc([(31, 6), (4, 5), (3, 5), (1, 5), (413, 9), (0, 1), (1, 1)]),
  ),
  // rotates
  ("RLWINM", m_form(21, 4, 3, 31, 1, 30)),
  ("RLWINM_rec", m_form(21, 4, 3, 1, 0, 31, rc=1)),
  ("RLWNM", m_form(23, 4, 3, 5, 0, 31)),
  ("RLWNM_rec", m_form(23, 4, 3, 5, 0, 31, rc=1)),
  ("RLWIMI", m_form(20, 4, 3, 8, 16, 23)),
  ("RLWIMI_rec", m_form(20, 4, 3, 8, 16, 23, rc=1)),
  ("RLDICL", md_form(0, 4, 3, 63, 33)),
  ("RLDICL_rec", md_form(0, 4, 3, 1, 0, rc=1)),
  ("RLDICR", md_form(1, 4, 3, 32, 31)),
  ("RLDICR_rec", md_form(1, 4, 3, 1, 62, rc=1)),
  ("RLDIC", md_form(2, 4, 3, 33, 1)),
  ("RLDIC_rec", md_form(2, 4, 3, 1, 1, rc=1)),
  ("RLDIMI", md_form(3, 4, 3, 32, 0)),
  ("RLDIMI_rec", md_form(3, 4, 3, 32, 0, rc=1)),
  ("RLDCL", mds_form(8, 4, 3, 5, 48)),
  ("RLDCL_rec", mds_form(8, 4, 3, 5, 0, rc=1)),
  ("RLDCR", mds_form(9, 4, 3, 5, 15)),
  ("RLDCR_rec", mds_form(9, 4, 3, 5, 63, rc=1)),
  // moves
  ("MTSPR", spr_form(3, 256, 467)),
  ("MFSPR", spr_form(3, 1, 339)),
  ("MTLR", spr_form(3, 8, 467)),
  ("MFLR", spr_form(3, 8, 339)),
  ("MTCTR", spr_form(3, 9, 467)),
  ("MFCTR", spr_form(3, 9, 339)),
  (
    "MTCRF",
    enc([(31, 6), (3, 5), (0, 1), (0x81, 8), (0, 1), (144, 10), (0, 1)]),
  ),
  ("MFCR", enc([(31, 6), (3, 5), (0, 10), (19, 10), (0, 1)])),
  // CR logical
  ("CRAND", xl_cr(1, 2, 3, 257)),
  ("CRNAND", xl_cr(1, 2, 3, 225)),
  ("CROR", xl_cr(1, 2, 3, 449)),
  ("CRXOR", xl_cr(1, 2, 3, 193)),
  ("CRNOR", xl_cr(1, 2, 3, 33)),
  ("CREQV", xl_cr(1, 2, 3, 289)),
  ("CRANDC", xl_cr(1, 2, 3, 129)),
  ("CRORC", xl_cr(1, 2, 3, 417)),
  ("MCRF", enc([(19, 6), (7, 3), (0, 2), (0, 3), (0, 17), (0, 1)])),
  // branches
  ("B", i_form(0x800000, 0, 0)),
  ("BA", i_form(0x100, 1, 0)),
  ("BL", i_form(1, 0, 1)),
  ("BLA", i_form(0x7FFFFF, 1, 1)),
  ("gBC", b_form(12, 2, 0x2000, 0, 0)),
  ("gBCA", b_form(4, 29, 16, 1, 0)),
  ("gBCL", b_form(20, 31, 1, 0, 1)),
  ("gBCLA", b_form(20, 0, 1, 1, 1)),
  ("BDNZ", b_form(16, 0, 0x3FFF, 0, 0)),
  ("BDZ", b_form(18, 0, 3, 0, 0)),
  ("gBCLR", xl_branch(12, 2, 0, 16, 0)),
  ("gBCLRL", xl_branch(4, 2, 0, 16, 1)),
  ("gBCCTR", xl_branch(12, 30, 0, 528, 0)),
  ("gBCCTRL", xl_branch(20, 0, 1, 528, 1)),
  ("BDNZLR", xl_branch(16, 0, 0, 16, 0)),
  ("BLR", xl_branch(20, 0, 0, 16, 0)),
  ("BLRL", xl_branch(20, 0, 0, 16, 1)),
  ("BCTR", xl_branch(20, 0, 0, 528, 0)),
  ("BCTRL", xl_branch(20, 0, 0, 528, 1)),
]

///|
/// Lifter opcodes that the LLVM disassembler never produces: extended
/// mnemonics and code generation only instructions (`LA`, `BCC...`), the
/// `bctar` branches (absent from LLVM), and the pre-LLVM 10 spelling of the
/// record forms (`XXXo`, decoded as `XXX_rec`).
fn never_decoded(name : String) -> Bool {
  [
    "LA", "BCC", "BCCL", "BCCLA", "BCCLR", "BCCLRL", "BCCCTR", "BCCCTRL", "gBCTAR",
    "gBCTARL",
  ].contains(name) ||
  (name.has_suffix("o") && name != "NOP")
}

///|
test "every lifter opcode is decoded" {
  let decoded : Map[String, Bool] = Map([])
  let failed32 = []
  for sample in opcode_samples {
    let (name, word) = sample
    for a in archs {
      let insn = decode_at(a, word, addr=0x1000)
      assert_eq(insn.name(), name)
      assert_eq(insn.raw(), word_bytes(word))
      assert_eq(insn.size(), 4)
      // the lifter accepts the decoded operands
      let lifted = @powerpc.lift(a, BigEndian, insn) catch {
        err => {
          match a {
            R32 => failed32.push(name)
            R64 => fail("\{name}: \{err.message()}")
          }
          []
        }
      }
      ignore(lifted)
    }
    decoded[name] = true
  }
  // 64-bit only instructions that the lifter rejects on 32-bit targets
  debug_inspect(
    failed32,
    content=(
      #|["STDU", "STDBRX", "SRAD", "SRAD_rec"]
    ),
  )
  let missing = @powerpc.supported_insns().filter(name => {
    !never_decoded(name) && !decoded.contains(name)
  })
  assert_eq(missing, [])
  // the decoded names are all lifter opcodes
  let supported = @powerpc.supported_insns()
  let unknown = opcode_samples
    .map(sample => sample.0)
    .filter(name => !supported.contains(name))
  assert_eq(unknown, [])
}

///|
test "decoded operands and assembly" {
  inspect(
    listing(R64, opcode_samples.map(sample => sample.1)),
    content=(
      #|1c64fff9  MULLI R3, R4, -7  | mulli 3, 4, -7
      #|20640064  SUBFIC R3, R4, 100  | subfic 3, 4, 100
      #|2a84ffff  CMPLWI CR5, R4, 65535  | cmplwi 5, 4, 65535
      #|2aa40007  CMPLDI CR5, X4, 7  | cmpldi 5, 4, 7
      #|2c048000  CMPWI CR0, R4, -32768  | cmpwi 4, -32768
      #|2ca40001  CMPDI CR1, X4, 1  | cmpdi 1, 4, 1
      #|3064ffff  ADDIC R3, R4, -1  | addic 3, 4, -1
      #|34640001  ADDIC_rec R3, R4, 1  | addic. 3, 4, 1
      #|38647fff  ADDI R3, R4, 32767  | addi 3, 4, 32767
      #|3c648000  ADDIS R3, R4, -32768  | addis 3, 4, -32768
      #|3860fff0  LI R3, -16  | li 3, -16
      #|3c601234  LIS R3, 4660  | lis 3, 4660
      #|60000000  NOP  | nop  | load,store
      #|6064ffff  ORI R4, R3, 65535  | ori 4, 3, 65535
      #|64640001  ORIS R4, R3, 1  | oris 4, 3, 1
      #|68640002  XORI R4, R3, 2  | xori 4, 3, 2
      #|6c640003  XORIS R4, R3, 3  | xoris 4, 3, 3
      #|70640004  ANDI_rec R4, R3, 4  | andi. 4, 3, 4
      #|74640005  ANDIS_rec R4, R3, 5  | andis. 4, 3, 5
      #|80610008  LWZ R3, 8, R1  | lwz 3, 8(1)  | load
      #|8461fff8  LWZU R3, R1, 65528, R1  | lwzu 3, -8(1)  | load
      #|88600008  LBZ R3, 8, ZERO  | lbz 3, 8(0)  | load
      #|8c610008  LBZU R3, R1, 8, R1  | lbzu 3, 8(1)  | load
      #|90610008  STW R3, 8, R1  | stw 3, 8(1)  | store
      #|9421ffe0  STWU R1, R1, 65504, R1  | stwu 1, -32(1)  | store
      #|98610008  STB R3, 8, R1  | stb 3, 8(1)  | store
      #|9c610008  STBU R1, R3, 8, R1  | stbu 3, 8(1)  | store
      #|a0610008  LHZ R3, 8, R1  | lhz 3, 8(1)  | load
      #|a4610008  LHZU R3, R1, 8, R1  | lhzu 3, 8(1)  | load
      #|a8610008  LHA R3, 8, R1  | lha 3, 8(1)  | load
      #|ac610008  LHAU R3, R1, 8, R1  | lhau 3, 8(1)  | load
      #|b0610008  STH R3, 8, R1  | sth 3, 8(1)  | store
      #|b4610008  STHU R1, R3, 8, R1  | sthu 3, 8(1)  | store
      #|e861fff8  LD X3, -8, R1  | ld 3, -8(1)  | load
      #|e8610009  LDU X3, R1, 8, R1  | ldu 3, 8(1)  | load
      #|e861000a  LWA X3, 8, R1  | lwa 3, 8(1)  | load
      #|f8610008  STD X3, 8, R1  | std 3, 8(1)  | store
      #|f821ffc1  STDU R1, X1, -64, R1  | stdu 1, -64(1)  | store
      #|7c6428ae  LBZX R3, R4, R5  | lbzx 3, 4, 5  | load
      #|7c6428ee  LBZUX R3, R4, R4, R5  | lbzux 3, 4, 5  | load
      #|7c642a2e  LHZX R3, R4, R5  | lhzx 3, 4, 5  | load
      #|7c642a6e  LHZUX R3, R4, R4, R5  | lhzux 3, 4, 5  | load
      #|7c642aae  LHAX R3, R4, R5  | lhax 3, 4, 5  | load
      #|7c642aee  LHAUX R3, R4, R4, R5  | lhaux 3, 4, 5  | load
      #|7c60282e  LWZX R3, ZERO, R5  | lwzx 3, 0, 5  | load
      #|7c64286e  LWZUX R3, R4, R4, R5  | lwzux 3, 4, 5  | load
      #|7c642aaa  LWAX X3, R4, R5  | lwax 3, 4, 5  | load
      #|7c642aea  LWAUX X3, R4, R4, R5  | lwaux 3, 4, 5  | load
      #|7c64282a  LDX X3, R4, R5  | ldx 3, 4, 5  | load
      #|7c64286a  LDUX X3, R4, R4, R5  | ldux 3, 4, 5  | load
      #|7c642e2c  LHBRX R3, R4, R5  | lhbrx 3, 4, 5  | load
      #|7c642c2c  LWBRX R3, R4, R5  | lwbrx 3, 4, 5  | load
      #|7c642c28  LDBRX X3, R4, R5  | ldbrx 3, 4, 5  | load
      #|7c6429ae  STBX R3, R4, R5  | stbx 3, 4, 5  | store
      #|7c6429ee  STBUX R4, R3, R4, R5  | stbux 3, 4, 5  | store
      #|7c642b2e  STHX R3, R4, R5  | sthx 3, 4, 5  | store
      #|7c642b6e  STHUX R4, R3, R4, R5  | sthux 3, 4, 5  | store
      #|7c64292e  STWX R3, R4, R5  | stwx 3, 4, 5  | store
      #|7c64296e  STWUX R4, R3, R4, R5  | stwux 3, 4, 5  | store
      #|7c64292a  STDX X3, R4, R5  | stdx 3, 4, 5  | store
      #|7c64296a  STDUX R4, X3, R4, R5  | stdux 3, 4, 5  | store
      #|7c642f2c  STHBRX R3, R4, R5  | sthbrx 3, 4, 5  | store
      #|7c642d2c  STWBRX R3, R4, R5  | stwbrx 3, 4, 5  | store
      #|7c642d28  STDBRX X3, R4, R5  | stdbrx 3, 4, 5  | store
      #|7c642a14  ADD4 R3, R4, R5  | add 3, 4, 5
      #|7c642a15  ADD4_rec R3, R4, R5  | add. 3, 4, 5
      #|7c642814  ADDC R3, R4, R5  | addc 3, 4, 5
      #|7c642815  ADDC_rec R3, R4, R5  | addc. 3, 4, 5
      #|7c642914  ADDE R3, R4, R5  | adde 3, 4, 5
      #|7c642915  ADDE_rec R3, R4, R5  | adde. 3, 4, 5
      #|7c6401d4  ADDME R3, R4  | addme 3, 4
      #|7c6401d5  ADDME_rec R3, R4  | addme. 3, 4
      #|7c640194  ADDZE R3, R4  | addze 3, 4
      #|7c640195  ADDZE_rec R3, R4  | addze. 3, 4
      #|7c642850  SUBF R3, R4, R5  | sub 3, 5, 4
      #|7c642851  SUBF_rec R3, R4, R5  | sub. 3, 5, 4
      #|7c642810  SUBFC R3, R4, R5  | subc 3, 5, 4
      #|7c642811  SUBFC_rec R3, R4, R5  | subc. 3, 5, 4
      #|7c642910  SUBFE R3, R4, R5  | subfe 3, 4, 5
      #|7c642911  SUBFE_rec R3, R4, R5  | subfe. 3, 4, 5
      #|7c6401d0  SUBFME R3, R4  | subfme 3, 4
      #|7c6401d1  SUBFME_rec R3, R4  | subfme. 3, 4
      #|7c640190  SUBFZE R3, R4  | subfze 3, 4
      #|7c640191  SUBFZE_rec R3, R4  | subfze. 3, 4
      #|7c6400d0  NEG R3, R4  | neg 3, 4
      #|7c6400d1  NEG_rec R3, R4  | neg. 3, 4
      #|7c6429d6  MULLW R3, R4, R5  | mullw 3, 4, 5
      #|7c6429d7  MULLW_rec R3, R4, R5  | mullw. 3, 4, 5
      #|7c642896  MULHW R3, R4, R5  | mulhw 3, 4, 5
      #|7c642897  MULHW_rec R3, R4, R5  | mulhw. 3, 4, 5
      #|7c642816  MULHWU R3, R4, R5  | mulhwu 3, 4, 5
      #|7c642817  MULHWU_rec R3, R4, R5  | mulhwu. 3, 4, 5
      #|7c6429d2  MULLD X3, X4, X5  | mulld 3, 4, 5
      #|7c6429d3  MULLD_rec X3, X4, X5  | mulld. 3, 4, 5
      #|7c642892  MULHD X3, X4, X5  | mulhd 3, 4, 5
      #|7c642893  MULHD_rec X3, X4, X5  | mulhd. 3, 4, 5
      #|7c642812  MULHDU X3, X4, X5  | mulhdu 3, 4, 5
      #|7c642813  MULHDU_rec X3, X4, X5  | mulhdu. 3, 4, 5
      #|7c642bd6  DIVW R3, R4, R5  | divw 3, 4, 5
      #|7c642bd7  DIVW_rec R3, R4, R5  | divw. 3, 4, 5
      #|7c642b96  DIVWU R3, R4, R5  | divwu 3, 4, 5
      #|7c642b97  DIVWU_rec R3, R4, R5  | divwu. 3, 4, 5
      #|7c642b56  DIVWE R3, R4, R5  | divwe 3, 4, 5
      #|7c642b57  DIVWE_rec R3, R4, R5  | divwe. 3, 4, 5
      #|7c642b16  DIVWEU R3, R4, R5  | divweu 3, 4, 5
      #|7c642b17  DIVWEU_rec R3, R4, R5  | divweu. 3, 4, 5
      #|7c642bd2  DIVD X3, X4, X5  | divd 3, 4, 5
      #|7c642bd3  DIVD_rec X3, X4, X5  | divd. 3, 4, 5
      #|7c642b92  DIVDU X3, X4, X5  | divdu 3, 4, 5
      #|7c642b93  DIVDU_rec X3, X4, X5  | divdu. 3, 4, 5
      #|7c642b52  DIVDE X3, X4, X5  | divde 3, 4, 5
      #|7c642b53  DIVDE_rec X3, X4, X5  | divde. 3, 4, 5
      #|7c642b12  DIVDEU X3, X4, X5  | divdeu 3, 4, 5
      #|7c642b13  DIVDEU_rec X3, X4, X5  | divdeu. 3, 4, 5
      #|7c642e16  MODSW R3, R4, R5  | modsw 3, 4, 5
      #|7c642a16  MODUW R3, R4, R5  | moduw 3, 4, 5
      #|7c642e12  MODSD X3, X4, X5  | modsd 3, 4, 5
      #|7c642a12  MODUD X3, X4, X5  | modud 3, 4, 5
      #|7f042800  CMPW CR6, R4, R5  | cmpw 6, 4, 5
      #|7f242800  CMPD CR6, X4, X5  | cmpd 6, 4, 5
      #|7f042840  CMPLW CR6, R4, R5  | cmplw 6, 4, 5
      #|7f242840  CMPLD CR6, X4, X5  | cmpld 6, 4, 5
      #|7c832838  AND R3, R4, R5  | and 3, 4, 5
      #|7c832839  AND_rec R3, R4, R5  | and. 3, 4, 5
      #|7c832878  ANDC R3, R4, R5  | andc 3, 4, 5
      #|7c832879  ANDC_rec R3, R4, R5  | andc. 3, 4, 5
      #|7c832b78  OR R3, R4, R5  | or 3, 4, 5
      #|7c832379  OR_rec R3, R4, R4  | mr. 3, 4
      #|7c832b38  ORC R3, R4, R5  | orc 3, 4, 5
      #|7c832b39  ORC_rec R3, R4, R5  | orc. 3, 4, 5
      #|7c832a78  XOR R3, R4, R5  | xor 3, 4, 5
      #|7c832a79  XOR_rec R3, R4, R5  | xor. 3, 4, 5
      #|7c832bb8  NAND R3, R4, R5  | nand 3, 4, 5
      #|7c832bb9  NAND_rec R3, R4, R5  | nand. 3, 4, 5
      #|7c8328f8  NOR R3, R4, R5  | nor 3, 4, 5
      #|7c8328f9  NOR_rec R3, R4, R5  | nor. 3, 4, 5
      #|7c832a38  EQV R3, R4, R5  | eqv 3, 4, 5
      #|7c832a39  EQV_rec R3, R4, R5  | eqv. 3, 4, 5
      #|7c832bf8  CMPB R3, R4, R5  | cmpb 3, 4, 5
      #|7c8329f8  BPERMD X3, X4, X5  | bpermd 3, 4, 5
      #|7c830774  EXTSB R3, R4  | extsb 3, 4
      #|7c830775  EXTSB_rec R3, R4  | extsb. 3, 4
      #|7c830734  EXTSH R3, R4  | extsh 3, 4
      #|7c830735  EXTSH_rec R3, R4  | extsh. 3, 4
      #|7c8307b4  EXTSW X3, X4  | extsw 3, 4
      #|7c8307b5  EXTSW_rec X3, X4  | extsw. 3, 4
      #|7c830034  CNTLZW R3, R4  | cntlzw 3, 4
      #|7c830035  CNTLZW_rec R3, R4  | cntlzw. 3, 4
      #|7c830074  CNTLZD X3, X4  | cntlzd 3, 4
      #|7c830075  CNTLZD_rec X3, X4  | cntlzd. 3, 4
      #|7c830434  CNTTZW R3, R4  | cnttzw 3, 4
      #|7c830435  CNTTZW_rec R3, R4  | cnttzw. 3, 4
      #|7c830474  CNTTZD X3, X4  | cnttzd 3, 4
      #|7c830475  CNTTZD_rec X3, X4  | cnttzd. 3, 4
      #|7c8302f4  POPCNTW R3, R4  | popcntw 3, 4
      #|7c8303f4  POPCNTD X3, X4  | popcntd 3, 4
      #|7c832830  SLW R3, R4, R5  | slw 3, 4, 5
      #|7c832831  SLW_rec R3, R4, R5  | slw. 3, 4, 5
      #|7c832c30  SRW R3, R4, R5  | srw 3, 4, 5
      #|7c832c31  SRW_rec R3, R4, R5  | srw. 3, 4, 5
      #|7c832e30  SRAW R3, R4, R5  | sraw 3, 4, 5
      #|7c832e31  SRAW_rec R3, R4, R5  | sraw. 3, 4, 5
      #|7c83fe70  SRAWI R3, R4, 31  | srawi 3, 4, 31
      #|7c830e71  SRAWI_rec R3, R4, 1  | srawi. 3, 4, 1
      #|7c832836  SLD X3, X4, R5  | sld 3, 4, 5
      #|7c832837  SLD_rec X3, X4, R5  | sld. 3, 4, 5
      #|7c832c36  SRD X3, X4, R5  | srd 3, 4, 5
      #|7c832c37  SRD_rec X3, X4, R5  | srd. 3, 4, 5
      #|7c832e34  SRAD X3, X4, R5  | srad 3, 4, 5
      #|7c832e35  SRAD_rec X3, X4, R5  | srad. 3, 4, 5
      #|7c83fe76  SRADI X3, X4, 63  | sradi 3, 4, 63
      #|7c830e75  SRADI_rec X3, X4, 1  | sradi. 3, 4, 1
      #|5483f87c  RLWINM R3, R4, 31, 1, 30  | rlwinm 3, 4, 31, 1, 30
      #|5483083f  RLWINM_rec R3, R4, 1, 0, 31  | rotlwi. 3, 4, 1
      #|5c83283e  RLWNM R3, R4, R5, 0, 31  | rotlw 3, 4, 5
      #|5c83283f  RLWNM_rec R3, R4, R5, 0, 31  | rotlw. 3, 4, 5
      #|5083442e  RLWIMI R3, R3, R4, 8, 16, 23  | rlwimi 3, 4, 8, 16, 23
      #|5083442f  RLWIMI_rec R3, R3, R4, 8, 16, 23  | rlwimi. 3, 4, 8, 16, 23
      #|7883f862  RLDICL X3, X4, 63, 33  | rldicl 3, 4, 63, 33
      #|78830801  RLDICL_rec X3, X4, 1, 0  | rotldi. 3, 4, 1
      #|788307c6  RLDICR X3, X4, 32, 31  | sldi 3, 4, 32
      #|78830fa5  RLDICR_rec X3, X4, 1, 62  | rldicr. 3, 4, 1, 62
      #|7883084a  RLDIC X3, X4, 33, 1  | rldic 3, 4, 33, 1
      #|78830849  RLDIC_rec X3, X4, 1, 1  | rldic. 3, 4, 1, 1
      #|7883000e  RLDIMI X3, X3, X4, 32, 0  | rldimi 3, 4, 32, 0
      #|7883000f  RLDIMI_rec X3, X3, X4, 32, 0  | rldimi. 3, 4, 32, 0
      #|78832c30  RLDCL X3, X4, R5, 48  | rldcl 3, 4, 5, 48
      #|78832811  RLDCL_rec X3, X4, R5, 0  | rotld. 3, 4, 5
      #|78832bd2  RLDCR X3, X4, R5, 15  | rldcr 3, 4, 5, 15
      #|78832ff3  RLDCR_rec X3, X4, R5, 63  | rldcr. 3, 4, 5, 63
      #|7c6043a6  MTSPR 256, R3  | mtspr 256, 3  | load,store
      #|7c6102a6  MFSPR R3, 1  | mfxer 3  | load,store
      #|7c6803a6  MTLR R3  | mtlr 3
      #|7c6802a6  MFLR R3  | mflr 3
      #|7c6903a6  MTCTR R3  | mtctr 3
      #|7c6902a6  MFCTR R3  | mfctr 3
      #|7c681120  MTCRF 129, R3  | mtcrf 129, 3
      #|7c600026  MFCR R3  | mfcr 3
      #|4c221a02  CRAND CR0GT, CR0EQ, CR0UN  | crand 1, 2, 3
      #|4c2219c2  CRNAND CR0GT, CR0EQ, CR0UN  | crnand 1, 2, 3
      #|4c221b82  CROR CR0GT, CR0EQ, CR0UN  | cror 1, 2, 3
      #|4c221982  CRXOR CR0GT, CR0EQ, CR0UN  | crxor 1, 2, 3
      #|4c221842  CRNOR CR0GT, CR0EQ, CR0UN  | crnor 1, 2, 3
      #|4c221a42  CREQV CR0GT, CR0EQ, CR0UN  | creqv 1, 2, 3
      #|4c221902  CRANDC CR0GT, CR0EQ, CR0UN  | crandc 1, 2, 3
      #|4c221b42  CRORC CR0GT, CR0EQ, CR0UN  | crorc 1, 2, 3
      #|4f800000  MCRF CR7, CR0  | mcrf 7, 0
      #|4a000000  B -8388608  | b .-33554432  | jump,barrier,term,flow
      #|48000402  BA 256  | ba 0x400  | jump,barrier,term,flow
      #|48000005  BL 1  | bl .+4  | call,flow
      #|49ffffff  BLA 8388607  | bla 0x1fffffc  | call,flow
      #|41828000  gBC 12, CR0EQ, -8192  | bt 2, .-32768  | cond,flow
      #|409d0042  gBCA 4, CR7GT, 16  | bfa 29, 0x40  | cond,flow
      #|429f0005  gBCL 20, CR7UN, 1  | bcl 20, 31, .+4  | cond,flow
      #|42800007  gBCLA 20, CR0LT, 1  | bcla 20, 0, 0x4  | cond,flow
      #|4200fffc  BDNZ -1  | bdnz .-4  | cond,term,flow
      #|4240000c  BDZ 3  | bdz .+12  | cond,term,flow
      #|4d820020  gBCLR 12, CR0EQ, 0  | bclr 12, 2  | cond,flow
      #|4c820021  gBCLRL 4, CR0EQ, 0  | bclrl 4, 2  | cond,flow
      #|4d9e0420  gBCCTR 12, CR7EQ, 0  | bcctr 12, 30  | cond,flow
      #|4e800c21  gBCCTRL 20, CR0LT, 1  | bcctrl 20, 0, 1  | cond,flow
      #|4e000020  BDNZLR  | bdnzlr  | cond,return,term,flow
      #|4e800020  BLR  | blr  | return,barrier,term,flow
      #|4e800021  BLRL  | blrl  | call,flow
      #|4e800420  BCTR  | bctr  | indirect,barrier,term,flow
      #|4e800421  BCTRL  | bctrl  | call,flow
    ),
  )
}
