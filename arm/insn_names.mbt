// Typed ARM instruction opcodes (port of the polymorphic variants in
// `Arm_types`). Constructor names are the LLVM MC opcode names that upstream
// BAP decodes with `Arm_insn.of_name`. Generated from upstream arm_types.ml.

///|
/// Data-processing (move/arithmetic/logic/compare) instructions.
pub(all) enum MoveInsn {
  ADCri
  ADCrr
  ADCrsi
  ADCrsr
  ADDri
  ADDrr
  ADDrsi
  ADDrsr
  ANDri
  ANDrr
  ANDrsi
  ANDrsr
  BICri
  BICrr
  BICrsi
  BICrsr
  CMNri
  CMNzrr
  CMNzrsi
  CMNzrsr
  CMPri
  CMPrr
  CMPrsi
  CMPrsr
  EORri
  EORrr
  EORrsi
  EORrsr
  MOVTi16
  MOVi
  MOVi16
  MOVr
  MOVsi
  MOVsr
  MOVPCLR
  MVNi
  MVNr
  MVNsi
  MVNsr
  ORRri
  ORRrr
  ORRrsi
  ORRrsr
  RSBri
  RSBrr
  RSBrsi
  RSBrsr
  RSCri
  RSCrr
  RSCrsi
  RSCrsr
  SBCri
  SBCrr
  SBCrsi
  SBCrsr
  SUBri
  SUBrr
  SUBrsi
  SUBrsr
  TEQri
  TEQrr
  TEQrsi
  TEQrsr
  TSTri
  TSTrr
  TSTrsi
  TSTrsr
} derive(Eq, Debug)

///|
pub extend MoveInsn with Eq::{equal, not_equal}

///|
pub extend MoveInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn MoveInsn::name(self : MoveInsn) -> String {
  match self {
    ADCri => "ADCri"
    ADCrr => "ADCrr"
    ADCrsi => "ADCrsi"
    ADCrsr => "ADCrsr"
    ADDri => "ADDri"
    ADDrr => "ADDrr"
    ADDrsi => "ADDrsi"
    ADDrsr => "ADDrsr"
    ANDri => "ANDri"
    ANDrr => "ANDrr"
    ANDrsi => "ANDrsi"
    ANDrsr => "ANDrsr"
    BICri => "BICri"
    BICrr => "BICrr"
    BICrsi => "BICrsi"
    BICrsr => "BICrsr"
    CMNri => "CMNri"
    CMNzrr => "CMNzrr"
    CMNzrsi => "CMNzrsi"
    CMNzrsr => "CMNzrsr"
    CMPri => "CMPri"
    CMPrr => "CMPrr"
    CMPrsi => "CMPrsi"
    CMPrsr => "CMPrsr"
    EORri => "EORri"
    EORrr => "EORrr"
    EORrsi => "EORrsi"
    EORrsr => "EORrsr"
    MOVTi16 => "MOVTi16"
    MOVi => "MOVi"
    MOVi16 => "MOVi16"
    MOVr => "MOVr"
    MOVsi => "MOVsi"
    MOVsr => "MOVsr"
    MOVPCLR => "MOVPCLR"
    MVNi => "MVNi"
    MVNr => "MVNr"
    MVNsi => "MVNsi"
    MVNsr => "MVNsr"
    ORRri => "ORRri"
    ORRrr => "ORRrr"
    ORRrsi => "ORRrsi"
    ORRrsr => "ORRrsr"
    RSBri => "RSBri"
    RSBrr => "RSBrr"
    RSBrsi => "RSBrsi"
    RSBrsr => "RSBrsr"
    RSCri => "RSCri"
    RSCrr => "RSCrr"
    RSCrsi => "RSCrsi"
    RSCrsr => "RSCrsr"
    SBCri => "SBCri"
    SBCrr => "SBCrr"
    SBCrsi => "SBCrsi"
    SBCrsr => "SBCrsr"
    SUBri => "SUBri"
    SUBrr => "SUBrr"
    SUBrsi => "SUBrsi"
    SUBrsr => "SUBrsr"
    TEQri => "TEQri"
    TEQrr => "TEQrr"
    TEQrsi => "TEQrsi"
    TEQrsr => "TEQrsr"
    TSTri => "TSTri"
    TSTrr => "TSTrr"
    TSTrsi => "TSTrsi"
    TSTrsr => "TSTrsr"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn MoveInsn::all() -> Array[MoveInsn] {
  [
    ADCri,
    ADCrr,
    ADCrsi,
    ADCrsr,
    ADDri,
    ADDrr,
    ADDrsi,
    ADDrsr,
    ANDri,
    ANDrr,
    ANDrsi,
    ANDrsr,
    BICri,
    BICrr,
    BICrsi,
    BICrsr,
    CMNri,
    CMNzrr,
    CMNzrsi,
    CMNzrsr,
    CMPri,
    CMPrr,
    CMPrsi,
    CMPrsr,
    EORri,
    EORrr,
    EORrsi,
    EORrsr,
    MOVTi16,
    MOVi,
    MOVi16,
    MOVr,
    MOVsi,
    MOVsr,
    MOVPCLR,
    MVNi,
    MVNr,
    MVNsi,
    MVNsr,
    ORRri,
    ORRrr,
    ORRrsi,
    ORRrsr,
    RSBri,
    RSBrr,
    RSBrsi,
    RSBrsr,
    RSCri,
    RSCrr,
    RSCrsi,
    RSCrsr,
    SBCri,
    SBCrr,
    SBCrsi,
    SBCrsr,
    SUBri,
    SUBrr,
    SUBrsi,
    SUBrsr,
    TEQri,
    TEQrr,
    TEQrsi,
    TEQrsr,
    TSTri,
    TSTrr,
    TSTrsi,
    TSTrsr,
  ]
}

///|
/// Bit-manipulation, extension, reversal and byte-swap instructions.
pub(all) enum BitsInsn {
  BFC
  BFI
  PKHTB
  RBIT
  SBFX
  SWPB
  SXTAB
  SXTAH
  SXTB
  SXTH
  UBFX
  UXTAB
  UXTAH
  UXTB
  UXTH
  REV
  REV16
} derive(Eq, Debug)

///|
pub extend BitsInsn with Eq::{equal, not_equal}

///|
pub extend BitsInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn BitsInsn::name(self : BitsInsn) -> String {
  match self {
    BFC => "BFC"
    BFI => "BFI"
    PKHTB => "PKHTB"
    RBIT => "RBIT"
    SBFX => "SBFX"
    SWPB => "SWPB"
    SXTAB => "SXTAB"
    SXTAH => "SXTAH"
    SXTB => "SXTB"
    SXTH => "SXTH"
    UBFX => "UBFX"
    UXTAB => "UXTAB"
    UXTAH => "UXTAH"
    UXTB => "UXTB"
    UXTH => "UXTH"
    REV => "REV"
    REV16 => "REV16"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn BitsInsn::all() -> Array[BitsInsn] {
  [
    BFC,
    BFI,
    PKHTB,
    RBIT,
    SBFX,
    SWPB,
    SXTAB,
    SXTAH,
    SXTB,
    SXTH,
    UBFX,
    UXTAB,
    UXTAH,
    UXTB,
    UXTH,
    REV,
    REV16,
  ]
}

///|
/// Multiply and multiply-accumulate instructions.
pub(all) enum MultInsn {
  MLA
  MLS
  MUL
  SMLABB
  SMLAD
  SMLAL
  SMLALBT
  SMLAWB
  SMUAD
  SMULBB
  SMULL
  SMULTB
  UMLAL
  UMULL
} derive(Eq, Debug)

///|
pub extend MultInsn with Eq::{equal, not_equal}

///|
pub extend MultInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn MultInsn::name(self : MultInsn) -> String {
  match self {
    MLA => "MLA"
    MLS => "MLS"
    MUL => "MUL"
    SMLABB => "SMLABB"
    SMLAD => "SMLAD"
    SMLAL => "SMLAL"
    SMLALBT => "SMLALBT"
    SMLAWB => "SMLAWB"
    SMUAD => "SMUAD"
    SMULBB => "SMULBB"
    SMULL => "SMULL"
    SMULTB => "SMULTB"
    UMLAL => "UMLAL"
    UMULL => "UMULL"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn MultInsn::all() -> Array[MultInsn] {
  [
    MLA,
    MLS,
    MUL,
    SMLABB,
    SMLAD,
    SMLAL,
    SMLALBT,
    SMLAWB,
    SMUAD,
    SMULBB,
    SMULL,
    SMULTB,
    UMLAL,
    UMULL,
  ]
}

///|
/// Load/store multiple instructions (`mem_multi_insn`).
pub(all) enum MemMultiInsn {
  LDMDA
  LDMDA_UPD
  LDMDB
  LDMDB_UPD
  LDMIA
  LDMIA_UPD
  LDMIB
  LDMIB_UPD
  STMDA
  STMDA_UPD
  STMDB
  STMDB_UPD
  STMIA
  STMIA_UPD
  STMIB
  STMIB_UPD
} derive(Eq, Debug)

///|
pub extend MemMultiInsn with Eq::{equal, not_equal}

///|
pub extend MemMultiInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn MemMultiInsn::name(self : MemMultiInsn) -> String {
  match self {
    LDMDA => "LDMDA"
    LDMDA_UPD => "LDMDA_UPD"
    LDMDB => "LDMDB"
    LDMDB_UPD => "LDMDB_UPD"
    LDMIA => "LDMIA"
    LDMIA_UPD => "LDMIA_UPD"
    LDMIB => "LDMIB"
    LDMIB_UPD => "LDMIB_UPD"
    STMDA => "STMDA"
    STMDA_UPD => "STMDA_UPD"
    STMDB => "STMDB"
    STMDB_UPD => "STMDB_UPD"
    STMIA => "STMIA"
    STMIA_UPD => "STMIA_UPD"
    STMIB => "STMIB"
    STMIB_UPD => "STMIB_UPD"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn MemMultiInsn::all() -> Array[MemMultiInsn] {
  [
    LDMDA,
    LDMDA_UPD,
    LDMDB,
    LDMDB_UPD,
    LDMIA,
    LDMIA_UPD,
    LDMIB,
    LDMIB_UPD,
    STMDA,
    STMDA_UPD,
    STMDB,
    STMDB_UPD,
    STMIA,
    STMIA_UPD,
    STMIB,
    STMIB_UPD,
  ]
}

///|
/// Single and dual register load/store instructions, including exclusives.
pub(all) enum MemInsn {
  LDRBT_POST_IMM
  LDRBT_POST_REG
  LDRB_POST_IMM
  LDRB_POST_REG
  LDRB_PRE_IMM
  LDRB_PRE_REG
  LDRBi12
  LDRBrs
  LDRD
  LDRD_POST
  LDRD_PRE
  LDREX
  LDREXB
  LDREXD
  LDREXH
  LDRH
  LDRHTr
  LDRH_POST
  LDRH_PRE
  LDRSB
  LDRSBTr
  LDRSB_POST
  LDRSB_PRE
  LDRSH
  LDRSHTi
  LDRSHTr
  LDRSH_POST
  LDRSH_PRE
  LDRT_POST_REG
  LDR_POST_IMM
  LDR_POST_REG
  LDR_PRE_IMM
  LDR_PRE_REG
  LDRi12
  LDRrs
  STRBT_POST_IMM
  STRBT_POST_REG
  STRB_POST_IMM
  STRB_POST_REG
  STRB_PRE_IMM
  STRB_PRE_REG
  STRBi12
  STRBrs
  STRD
  STRD_POST
  STRD_PRE
  STREX
  STREXB
  STREXD
  STREXH
  STRH
  STRHTr
  STRH_POST
  STRH_PRE
  STRT_POST_REG
  STR_POST_IMM
  STR_POST_REG
  STR_PRE_IMM
  STR_PRE_REG
  STRi12
  STRrs
} derive(Eq, Debug)

///|
pub extend MemInsn with Eq::{equal, not_equal}

///|
pub extend MemInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn MemInsn::name(self : MemInsn) -> String {
  match self {
    LDRBT_POST_IMM => "LDRBT_POST_IMM"
    LDRBT_POST_REG => "LDRBT_POST_REG"
    LDRB_POST_IMM => "LDRB_POST_IMM"
    LDRB_POST_REG => "LDRB_POST_REG"
    LDRB_PRE_IMM => "LDRB_PRE_IMM"
    LDRB_PRE_REG => "LDRB_PRE_REG"
    LDRBi12 => "LDRBi12"
    LDRBrs => "LDRBrs"
    LDRD => "LDRD"
    LDRD_POST => "LDRD_POST"
    LDRD_PRE => "LDRD_PRE"
    LDREX => "LDREX"
    LDREXB => "LDREXB"
    LDREXD => "LDREXD"
    LDREXH => "LDREXH"
    LDRH => "LDRH"
    LDRHTr => "LDRHTr"
    LDRH_POST => "LDRH_POST"
    LDRH_PRE => "LDRH_PRE"
    LDRSB => "LDRSB"
    LDRSBTr => "LDRSBTr"
    LDRSB_POST => "LDRSB_POST"
    LDRSB_PRE => "LDRSB_PRE"
    LDRSH => "LDRSH"
    LDRSHTi => "LDRSHTi"
    LDRSHTr => "LDRSHTr"
    LDRSH_POST => "LDRSH_POST"
    LDRSH_PRE => "LDRSH_PRE"
    LDRT_POST_REG => "LDRT_POST_REG"
    LDR_POST_IMM => "LDR_POST_IMM"
    LDR_POST_REG => "LDR_POST_REG"
    LDR_PRE_IMM => "LDR_PRE_IMM"
    LDR_PRE_REG => "LDR_PRE_REG"
    LDRi12 => "LDRi12"
    LDRrs => "LDRrs"
    STRBT_POST_IMM => "STRBT_POST_IMM"
    STRBT_POST_REG => "STRBT_POST_REG"
    STRB_POST_IMM => "STRB_POST_IMM"
    STRB_POST_REG => "STRB_POST_REG"
    STRB_PRE_IMM => "STRB_PRE_IMM"
    STRB_PRE_REG => "STRB_PRE_REG"
    STRBi12 => "STRBi12"
    STRBrs => "STRBrs"
    STRD => "STRD"
    STRD_POST => "STRD_POST"
    STRD_PRE => "STRD_PRE"
    STREX => "STREX"
    STREXB => "STREXB"
    STREXD => "STREXD"
    STREXH => "STREXH"
    STRH => "STRH"
    STRHTr => "STRHTr"
    STRH_POST => "STRH_POST"
    STRH_PRE => "STRH_PRE"
    STRT_POST_REG => "STRT_POST_REG"
    STR_POST_IMM => "STR_POST_IMM"
    STR_POST_REG => "STR_POST_REG"
    STR_PRE_IMM => "STR_PRE_IMM"
    STR_PRE_REG => "STR_PRE_REG"
    STRi12 => "STRi12"
    STRrs => "STRrs"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn MemInsn::all() -> Array[MemInsn] {
  [
    LDRBT_POST_IMM,
    LDRBT_POST_REG,
    LDRB_POST_IMM,
    LDRB_POST_REG,
    LDRB_PRE_IMM,
    LDRB_PRE_REG,
    LDRBi12,
    LDRBrs,
    LDRD,
    LDRD_POST,
    LDRD_PRE,
    LDREX,
    LDREXB,
    LDREXD,
    LDREXH,
    LDRH,
    LDRHTr,
    LDRH_POST,
    LDRH_PRE,
    LDRSB,
    LDRSBTr,
    LDRSB_POST,
    LDRSB_PRE,
    LDRSH,
    LDRSHTi,
    LDRSHTr,
    LDRSH_POST,
    LDRSH_PRE,
    LDRT_POST_REG,
    LDR_POST_IMM,
    LDR_POST_REG,
    LDR_PRE_IMM,
    LDR_PRE_REG,
    LDRi12,
    LDRrs,
    STRBT_POST_IMM,
    STRBT_POST_REG,
    STRB_POST_IMM,
    STRB_POST_REG,
    STRB_PRE_IMM,
    STRB_PRE_REG,
    STRBi12,
    STRBrs,
    STRD,
    STRD_POST,
    STRD_PRE,
    STREX,
    STREXB,
    STREXD,
    STREXH,
    STRH,
    STRHTr,
    STRH_POST,
    STRH_PRE,
    STRT_POST_REG,
    STR_POST_IMM,
    STR_POST_REG,
    STR_PRE_IMM,
    STR_PRE_REG,
    STRi12,
    STRrs,
  ]
}

///|
/// Branch instructions.
pub(all) enum BranchInsn {
  BL
  BLX
  BLX_pred
  BLXi
  BL_pred
  BX
  BX_RET
  BX_pred
  Bcc
} derive(Eq, Debug)

///|
pub extend BranchInsn with Eq::{equal, not_equal}

///|
pub extend BranchInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn BranchInsn::name(self : BranchInsn) -> String {
  match self {
    BL => "BL"
    BLX => "BLX"
    BLX_pred => "BLX_pred"
    BLXi => "BLXi"
    BL_pred => "BL_pred"
    BX => "BX"
    BX_RET => "BX_RET"
    BX_pred => "BX_pred"
    Bcc => "Bcc"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn BranchInsn::all() -> Array[BranchInsn] {
  [BL, BLX, BLX_pred, BLXi, BL_pred, BX, BX_RET, BX_pred, Bcc]
}

///|
/// System and hint instructions.
pub(all) enum SpecialInsn {
  CPS2p
  DMB
  DSB
  HINT
  MRS
  MSR
  PLDi12
  SVC
} derive(Eq, Debug)

///|
pub extend SpecialInsn with Eq::{equal, not_equal}

///|
pub extend SpecialInsn with Debug::{to_repr}

///|
/// The LLVM MC opcode name.
pub fn SpecialInsn::name(self : SpecialInsn) -> String {
  match self {
    CPS2p => "CPS2p"
    DMB => "DMB"
    DSB => "DSB"
    HINT => "HINT"
    MRS => "MRS"
    MSR => "MSR"
    PLDi12 => "PLDi12"
    SVC => "SVC"
  }
}

///|
/// All opcodes of this group, in upstream declaration order.
pub fn SpecialInsn::all() -> Array[SpecialInsn] {
  [CPS2p, DMB, DSB, HINT, MRS, MSR, PLDi12, SVC]
}
