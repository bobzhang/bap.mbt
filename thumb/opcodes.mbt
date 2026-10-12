// Port of `plugins/thumb/thumb_opcodes.ml`.
//
// Upstream models the opcode families as polymorphic-variant subsets
// (`opmov`, `opmem_multi`, `opmem`, `opbranch`, `opbit`). MoonBit has no
// polymorphic variants, so the port uses one closed `Opcode` enum plus
// `OpcodeKind` classification predicates. Constructor names are the LLVM MC
// names with the leading `t`/`t2` capitalised (`tADDi3` -> `TADDi3`,
// `t2LDRpci` -> `T2LDRpci`); `Opcode::name` recovers the LLVM spelling.

///|
/// Thumb opcodes understood by the lifter (upstream `Thumb_opcodes.opcode`).
pub(all) enum Opcode {
  // opmov: all the `mov` series
  TADC
  TADDi3
  TADDi8
  TADDrSPi
  TADDrr
  TADDspi
  TASRri
  TCMPi8
  TCMPr
  TLSLri
  TLSRri
  TMOVSr
  TMOVi8
  TORR
  TSUBi3
  TSUBi8
  TSUBrr
  TSUBspi
  // opmem_multi: Rd [reglist]
  TSTMIA
  TSTMIA_UPD
  TLDMIA
  TLDMIA_UPD
  TPOP
  TPUSH
  // opmem
  T2LDRpci
  TLDRBi
  TLDRBr
  TLDRHi
  TLDRHr
  TLDRSB
  TLDRSH
  TLDRi
  TLDRpci
  TLDRr
  TLDRspi
  TSTRBi
  TSTRBr
  TSTRHi
  TSTRHr
  TSTRi
  TSTRr
  TSTRspi
  // opbranch
  TB
  TBL
  TBLXi
  TBLXr
  TBX
  TBcc
  TCBNZ
  TCBZ
  // opbit
  TSXTB
  TSXTH
  TUXTB
  TUXTH
} derive(Eq, Debug)

///|
pub extend Opcode with Eq::{equal, not_equal}

///|
pub extend Opcode with Debug::{to_repr}

///|
/// Opcode family, mirroring upstream's polymorphic-variant subsets.
/// `MemMulti` opcodes also belong to upstream's `opmem`.
pub(all) enum OpcodeKind {
  Mov
  MemMulti
  Mem
  Branch
  Bit
} derive(Eq, Debug)

///|
pub extend OpcodeKind with Eq::{equal, not_equal}

///|
pub extend OpcodeKind with Debug::{to_repr}

///|
let all_opcodes : ReadOnlyArray[Opcode] = [
  TADC,
  TADDi3,
  TADDi8,
  TADDrSPi,
  TADDrr,
  TADDspi,
  TASRri,
  TCMPi8,
  TCMPr,
  TLSLri,
  TLSRri,
  TMOVSr,
  TMOVi8,
  TORR,
  TSUBi3,
  TSUBi8,
  TSUBrr,
  TSUBspi,
  TSTMIA,
  TSTMIA_UPD,
  TLDMIA,
  TLDMIA_UPD,
  TPOP,
  TPUSH,
  T2LDRpci,
  TLDRBi,
  TLDRBr,
  TLDRHi,
  TLDRHr,
  TLDRSB,
  TLDRSH,
  TLDRi,
  TLDRpci,
  TLDRr,
  TLDRspi,
  TSTRBi,
  TSTRBr,
  TSTRHi,
  TSTRHr,
  TSTRi,
  TSTRr,
  TSTRspi,
  TB,
  TBL,
  TBLXi,
  TBLXr,
  TBX,
  TBcc,
  TCBNZ,
  TCBZ,
  TSXTB,
  TSXTH,
  TUXTB,
  TUXTH,
]

///|
/// All opcodes in upstream declaration order (`Thumb_opcodes.all_of_opcode`).
pub fn Opcode::all() -> Array[Opcode] {
  [..all_opcodes]
}

///|
/// LLVM MC opcode name (`string_of_opcode` upstream).
pub fn Opcode::name(self : Opcode) -> String {
  match self {
    TADC => "tADC"
    TADDi3 => "tADDi3"
    TADDi8 => "tADDi8"
    TADDrSPi => "tADDrSPi"
    TADDrr => "tADDrr"
    TADDspi => "tADDspi"
    TASRri => "tASRri"
    TCMPi8 => "tCMPi8"
    TCMPr => "tCMPr"
    TLSLri => "tLSLri"
    TLSRri => "tLSRri"
    TMOVSr => "tMOVSr"
    TMOVi8 => "tMOVi8"
    TORR => "tORR"
    TSUBi3 => "tSUBi3"
    TSUBi8 => "tSUBi8"
    TSUBrr => "tSUBrr"
    TSUBspi => "tSUBspi"
    TSTMIA => "tSTMIA"
    TSTMIA_UPD => "tSTMIA_UPD"
    TLDMIA => "tLDMIA"
    TLDMIA_UPD => "tLDMIA_UPD"
    TPOP => "tPOP"
    TPUSH => "tPUSH"
    T2LDRpci => "t2LDRpci"
    TLDRBi => "tLDRBi"
    TLDRBr => "tLDRBr"
    TLDRHi => "tLDRHi"
    TLDRHr => "tLDRHr"
    TLDRSB => "tLDRSB"
    TLDRSH => "tLDRSH"
    TLDRi => "tLDRi"
    TLDRpci => "tLDRpci"
    TLDRr => "tLDRr"
    TLDRspi => "tLDRspi"
    TSTRBi => "tSTRBi"
    TSTRBr => "tSTRBr"
    TSTRHi => "tSTRHi"
    TSTRHr => "tSTRHr"
    TSTRi => "tSTRi"
    TSTRr => "tSTRr"
    TSTRspi => "tSTRspi"
    TB => "tB"
    TBL => "tBL"
    TBLXi => "tBLXi"
    TBLXr => "tBLXr"
    TBX => "tBX"
    TBcc => "tBcc"
    TCBNZ => "tCBNZ"
    TCBZ => "tCBZ"
    TSXTB => "tSXTB"
    TSXTH => "tSXTH"
    TUXTB => "tUXTB"
    TUXTH => "tUXTH"
  }
}

///|
pub fn Opcode::to_string(self : Opcode) -> String {
  self.name()
}

///|
pub extend Opcode with Show::{output}

///|
pub impl Show for Opcode with fn output(self, logger) {
  logger.write_string(self.name())
}

///|
/// Decode an LLVM MC opcode name (`decode_opcode` upstream). The match is
/// exact and case-sensitive, as with upstream's sexp decoding.
pub fn Opcode::of_name(name : String) -> Opcode? {
  for op in all_opcodes {
    if op.name() == name {
      return Some(op)
    }
  }
  None
}

///|
pub fn Opcode::kind(self : Opcode) -> OpcodeKind {
  match self {
    TADC
    | TADDi3
    | TADDi8
    | TADDrSPi
    | TADDrr
    | TADDspi
    | TASRri
    | TCMPi8
    | TCMPr
    | TLSLri
    | TLSRri
    | TMOVSr
    | TMOVi8
    | TORR
    | TSUBi3
    | TSUBi8
    | TSUBrr
    | TSUBspi => Mov
    TSTMIA | TSTMIA_UPD | TLDMIA | TLDMIA_UPD | TPOP | TPUSH => MemMulti
    T2LDRpci
    | TLDRBi
    | TLDRBr
    | TLDRHi
    | TLDRHr
    | TLDRSB
    | TLDRSH
    | TLDRi
    | TLDRpci
    | TLDRr
    | TLDRspi
    | TSTRBi
    | TSTRBr
    | TSTRHi
    | TSTRHr
    | TSTRi
    | TSTRr
    | TSTRspi => Mem
    TB | TBL | TBLXi | TBLXr | TBX | TBcc | TCBNZ | TCBZ => Branch
    TSXTB | TSXTH | TUXTB | TUXTH => Bit
  }
}

///|
/// Whether the opcode belongs to upstream's `opmem` (single or multi).
pub fn Opcode::is_mem(self : Opcode) -> Bool {
  self.kind() is (Mem | MemMulti)
}

///|
/// ARM condition codes (upstream `Thumb_opcodes.cond`).
pub(all) enum Cond {
  EQ
  NE
  CS
  CC
  MI
  PL
  VS
  VC
  HI
  LS
  GE
  LT
  GT
  LE
  AL
} derive(Eq, Debug)

///|
pub extend Cond with Eq::{equal, not_equal}

///|
pub extend Cond with Debug::{to_repr}

///|
let all_conds : ReadOnlyArray[Cond] = [
  EQ,
  NE,
  CS,
  CC,
  MI,
  PL,
  VS,
  VC,
  HI,
  LS,
  GE,
  LT,
  GT,
  LE,
  AL,
]

///|
pub fn Cond::all() -> Array[Cond] {
  [..all_conds]
}

///|
/// Decode the LLVM predicate immediate (`0..14`) into a condition code,
/// as upstream `Thumb_main.cnd` does.
pub fn Cond::of_int(code : Int32) -> Cond? {
  if code >= 0 && code < all_conds.length() {
    Some(all_conds[code])
  } else {
    None
  }
}

///|
pub fn Cond::to_int(self : Cond) -> Int32 {
  match self {
    EQ => 0
    NE => 1
    CS => 2
    CC => 3
    MI => 4
    PL => 5
    VS => 6
    VC => 7
    HI => 8
    LS => 9
    GE => 10
    LT => 11
    GT => 12
    LE => 13
    AL => 14
  }
}
