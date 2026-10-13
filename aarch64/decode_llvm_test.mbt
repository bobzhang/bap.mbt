// Per-opcode decoding tests of the native A64 decoder. Every expected
// line (the LLVM opcode name, the operands and the assembly) is the output
// of LLVM 22's `llvm-mc -disassemble -show-inst -triple=aarch64-linux-gnu
// -mattr=+v8.1a,+v8.2a,+v8.3a` (the target features of upstream BAP) for
// the word; the kinds are the `MCInstrDesc` flags upstream BAP reads
// (`isBranch` has no BAP kind). One sample per opcode and printed form,
// selected from random words, encoding-space sweeps, compiler output and
// macOS system binaries.

///|
let llvm_samples : Array[(UInt32, String, String)] = [
  (0x00000100U, "UDF Imm:256 | udf #256", ""),
  (
    0x080bfc2aU, "STLXRB Reg:W11 Reg:W10 Reg:X1 | stlxrb w11, w10, [x1]", "may_load,may_store",
  ),
  (
    0x0815035aU, "STXRB Reg:W21 Reg:W26 Reg:X26 | stxrb w21, w26, [x26]", "may_load,may_store",
  ),
  (
    0x08247c9eU, "CASPW Reg:W4_W5 Reg:W4_W5 Reg:W30_WZR Reg:X4 | casp w4, w5, w30, wzr, [x4]",
    "may_load,may_store",
  ),
  (
    0x083aff5aU, "CASPLW Reg:W26_W27 Reg:W26_W27 Reg:W26_W27 Reg:X26 | caspl w26, w27, w26, w27, [x26]",
    "may_load,may_store",
  ),
  (0x085f6ff4U, "LDXRB Reg:W20 Reg:SP | ldxrb w20, [sp]", "may_load,may_store"),
  (0x085ffc29U, "LDAXRB Reg:W9 Reg:X1 | ldaxrb w9, [x1]", "may_load,may_store"),
  (
    0x08727f8eU, "CASPAW Reg:W18_W19 Reg:W18_W19 Reg:W14_W15 Reg:X28 | caspa w18, w19, w14, w15, [x28]",
    "may_load,may_store",
  ),
  (
    0x087efe3eU, "CASPALW Reg:W30_WZR Reg:W30_WZR Reg:W30_WZR Reg:X17 | caspal w30, wzr, w30, wzr, [x17]",
    "may_load,may_store",
  ),
  (0x088383ffU, "STLRB Reg:WZR Reg:SP | stlrb wzr, [sp]", "may_store"),
  (0x088e01dfU, "STLLRB Reg:WZR Reg:X14 | stllrb wzr, [x14]", "may_store"),
  (
    0x08a0ffb2U, "CASLB Reg:W0 Reg:W0 Reg:W18 Reg:FP | caslb w0, w18, [x29]", "may_load,may_store",
  ),
  (
    0x08ba7ffaU, "CASB Reg:W26 Reg:W26 Reg:W26 Reg:SP | casb w26, w26, [sp]", "may_load,may_store",
  ),
  (0x08d6d8f6U, "LDARB Reg:W22 Reg:X7 | ldarb w22, [x7]", "may_load"),
  (0x08df63e9U, "LDLARB Reg:W9 Reg:SP | ldlarb w9, [sp]", "may_load"),
  (
    0x08fefdfeU, "CASALB Reg:W30 Reg:W30 Reg:W30 Reg:X15 | casalb w30, w30, [x15]",
    "may_load,may_store",
  ),
  (
    0x08ff7d08U, "CASAB Reg:WZR Reg:WZR Reg:W8 Reg:X8 | casab wzr, w8, [x8]", "may_load,may_store",
  ),
  (0x0a09010cU, "ANDWrs Reg:W12 Reg:W8 Reg:W9 Imm:0 | and w12, w8, w9", ""),
  (
    0x0a732d00U, "BICWrs Reg:W0 Reg:W8 Reg:W19 Imm:75 | bic w0, w8, w19, lsr #11",
    "",
  ),
  (
    0x0b20a14aU, "ADDWrx Reg:W10 Reg:W10 Reg:W0 Imm:40 | add w10, w10, w0, sxth",
    "",
  ),
  (
    0x0b20c411U, "ADDWrx Reg:W17 Reg:W0 Reg:W0 Imm:49 | add w17, w0, w0, sxtw #1",
    "",
  ),
  (
    0x0b20effaU, "ADDWrx Reg:W26 Reg:WSP Reg:W0 Imm:59 | add w26, wsp, w0, sxtx #3",
    "",
  ),
  (
    0x0b22214aU, "ADDWrx Reg:W10 Reg:W10 Reg:W2 Imm:8 | add w10, w10, w2, uxth",
    "",
  ),
  (
    0x0b224e7fU, "ADDWrx Reg:WSP Reg:W19 Reg:W2 Imm:19 | add wsp, w19, w2, lsl #3",
    "",
  ),
  (0x0b290108U, "ADDWrx Reg:W8 Reg:W8 Reg:W9 Imm:0 | add w8, w8, w9, uxtb", ""),
  (0x0b298108U, "ADDWrx Reg:W8 Reg:W8 Reg:W9 Imm:32 | add w8, w8, w9, sxtb", ""),
  (
    0x0b2b734fU, "ADDWrx Reg:W15 Reg:W26 Reg:W11 Imm:28 | add w15, w26, w11, uxtx #4",
    "",
  ),
  (
    0x0b3f4010U, "ADDWrx Reg:W16 Reg:W0 Reg:WZR Imm:16 | add w16, w0, wzr, uxtw",
    "",
  ),
  (
    0x0b421508U, "ADDWrs Reg:W8 Reg:W8 Reg:W2 Imm:69 | add w8, w8, w2, lsr #5", "",
  ),
  (0x10000011U, "ADR Reg:X17 Imm:0 | adr x17, #0", ""),
  (0x11000420U, "ADDWri Reg:W0 Reg:W1 Imm:1 Imm:0 | add w0, w1, #1", ""),
  (0x121e0420U, "ANDWri Reg:W0 Reg:W1 Imm:1921 | and w0, w1, #0xc", ""),
  (0x12800000U, "MOVNWi Reg:W0 Imm:0 Imm:0 | mov w0, #-1", ""),
  (0x129fffedU, "MOVNWi Reg:W13 Imm:65535 Imm:0 | movn w13, #65535", ""),
  (0x13000100U, "SBFMWri Reg:W0 Reg:W8 Imm:0 Imm:0 | sbfx w0, w8, #0, #1", ""),
  (0x13001c2aU, "SBFMWri Reg:W10 Reg:W1 Imm:0 Imm:7 | sxtb w10, w1", ""),
  (0x13003e68U, "SBFMWri Reg:W8 Reg:W19 Imm:0 Imm:15 | sxth w8, w19", ""),
  (0x13107c00U, "SBFMWri Reg:W0 Reg:W0 Imm:16 Imm:31 | asr w0, w0, #16", ""),
  (
    0x131c3c11U, "SBFMWri Reg:W17 Reg:W0 Imm:28 Imm:15 | sbfiz w17, w0, #4, #16",
    "",
  ),
  (
    0x13887529U, "EXTRWrri Reg:W9 Reg:W9 Reg:W8 Imm:29 | extr w9, w9, w8, #29", "",
  ),
  (0x13901e04U, "EXTRWrri Reg:W4 Reg:W16 Reg:W16 Imm:7 | ror w4, w16, #7", ""),
  (0x14000006U, "B Imm:6 | b #24", "uncond,barrier,terminator,affect_cf"),
  (0x180a0231U, "LDRWl Reg:W17 Imm:20497 | ldr w17, #81988", "may_load"),
  (0x1a060318U, "ADCWr Reg:W24 Reg:W24 Reg:W6 | adc w24, w24, w6", ""),
  (0x1a880128U, "CSELWr Reg:W8 Reg:W9 Reg:W8 Imm:0 | csel w8, w9, w8, eq", ""),
  (0x1a88a508U, "CSINCWr Reg:W8 Reg:W8 Reg:W8 Imm:10 | cinc w8, w8, lt", ""),
  (
    0x1a9f0529U, "CSINCWr Reg:W9 Reg:W9 Reg:WZR Imm:0 | csinc w9, w9, wzr, eq", "",
  ),
  (0x1a9f17e8U, "CSINCWr Reg:W8 Reg:WZR Reg:WZR Imm:1 | cset w8, eq", ""),
  (0x1ac02dadU, "RORVWr Reg:W13 Reg:W13 Reg:W0 | ror w13, w13, w0", ""),
  (0x1ac12508U, "LSRVWr Reg:W8 Reg:W8 Reg:W1 | lsr w8, w8, w1", ""),
  (0x1ac44bffU, "CRC32Wrr Reg:WZR Reg:WZR Reg:W4 | crc32w wzr, wzr, w4", ""),
  (0x1ac82008U, "LSLVWr Reg:W8 Reg:W0 Reg:W8 | lsl w8, w0, w8", ""),
  (0x1ac92908U, "ASRVWr Reg:W8 Reg:W8 Reg:W9 | asr w8, w8, w9", ""),
  (0x1ac9450eU, "CRC32Hrr Reg:W14 Reg:W8 Reg:W9 | crc32h w14, w8, w9", ""),
  (0x1aca0d08U, "SDIVWr Reg:W8 Reg:W8 Reg:W10 | sdiv w8, w8, w10", ""),
  (0x1acb092aU, "UDIVWr Reg:W10 Reg:W9 Reg:W11 | udiv w10, w9, w11", ""),
  (0x1acd53ddU, "CRC32CBrr Reg:W29 Reg:W30 Reg:W13 | crc32cb w29, w30, w13", ""),
  (0x1acf4177U, "CRC32Brr Reg:W23 Reg:W11 Reg:W15 | crc32b w23, w11, w15", ""),
  (0x1ad15946U, "CRC32CWrr Reg:W6 Reg:W10 Reg:W17 | crc32cw w6, w10, w17", ""),
  (0x1adf57a6U, "CRC32CHrr Reg:W6 Reg:W29 Reg:WZR | crc32ch w6, w29, wzr", ""),
  (0x1b007c28U, "MADDWrrr Reg:W8 Reg:W1 Reg:W0 Reg:WZR | mul w8, w1, w0", ""),
  (
    0x1b098108U, "MSUBWrrr Reg:W8 Reg:W8 Reg:W9 Reg:W0 | msub w8, w8, w9, w0", "",
  ),
  (0x1b0afd08U, "MSUBWrrr Reg:W8 Reg:W8 Reg:W10 Reg:WZR | mneg w8, w8, w10", ""),
  (
    0x1b190300U, "MADDWrrr Reg:W0 Reg:W24 Reg:W25 Reg:W0 | madd w0, w24, w25, w0",
    "",
  ),
  (
    0x280003e0U, "STNPWi Reg:W0 Reg:W0 Reg:SP Imm:0 | stnp w0, w0, [sp]", "may_store",
  ),
  (
    0x281483ffU, "STNPWi Reg:WZR Reg:W0 Reg:SP Imm:41 | stnp wzr, w0, [sp, #164]",
    "may_store",
  ),
  (
    0x284003e7U, "LDNPWi Reg:W7 Reg:W0 Reg:SP Imm:0 | ldnp w7, w0, [sp]", "may_load",
  ),
  (
    0x284f7ee1U, "LDNPWi Reg:W1 Reg:WZR Reg:X23 Imm:30 | ldnp w1, wzr, [x23, #120]",
    "may_load",
  ),
  (
    0x2898e3e2U, "STPWpost Reg:SP Reg:W2 Reg:W24 Reg:SP Imm:49 | stp w2, w24, [sp], #196",
    "may_store",
  ),
  (
    0x28c22b49U, "LDPWpost Reg:X26 Reg:W9 Reg:W10 Reg:X26 Imm:4 | ldp w9, w10, [x26], #16",
    "may_load",
  ),
  (
    0x29003002U, "STPWi Reg:W2 Reg:W12 Reg:X0 Imm:0 | stp w2, w12, [x0]", "may_store",
  ),
  (
    0x29032900U, "STPWi Reg:W0 Reg:W10 Reg:X8 Imm:6 | stp w0, w10, [x8, #24]", "may_store",
  ),
  (
    0x29400901U, "LDPWi Reg:W1 Reg:W2 Reg:X8 Imm:0 | ldp w1, w2, [x8]", "may_load",
  ),
  (
    0x29408500U, "LDPWi Reg:W0 Reg:W1 Reg:X8 Imm:1 | ldp w0, w1, [x8, #4]", "may_load",
  ),
  (
    0x29812b0bU, "STPWpre Reg:X24 Reg:W11 Reg:W10 Reg:X24 Imm:2 | stp w11, w10, [x24, #8]!",
    "may_store",
  ),
  (
    0x29feeb9bU, "LDPWpre Reg:X28 Reg:W27 Reg:W26 Reg:X28 Imm:-3 | ldp w27, w26, [x28, #-12]!",
    "may_load",
  ),
  (0x2a0303ecU, "ORRWrs Reg:W12 Reg:WZR Reg:W3 Imm:0 | mov w12, w3", ""),
  (0x2a09010cU, "ORRWrs Reg:W12 Reg:W8 Reg:W9 Imm:0 | orr w12, w8, w9", ""),
  (0x2a2803e8U, "ORNWrs Reg:W8 Reg:WZR Reg:W8 Imm:0 | mvn w8, w8", ""),
  (0x2a330108U, "ORNWrs Reg:W8 Reg:W8 Reg:W19 Imm:0 | orn w8, w8, w19", ""),
  (0x2b090108U, "ADDSWrs Reg:W8 Reg:W8 Reg:W9 Imm:0 | adds w8, w8, w9", ""),
  (0x2b09011fU, "ADDSWrs Reg:WZR Reg:W8 Reg:W9 Imm:0 | cmn w8, w9", ""),
  (
    0x2b21901fU, "ADDSWrx Reg:WZR Reg:W0 Reg:W1 Imm:36 | cmn w0, w1, sxtb #4", "",
  ),
  (
    0x2b246c42U, "ADDSWrx Reg:W2 Reg:W2 Reg:W4 Imm:27 | adds w2, w2, w4, uxtx #3",
    "",
  ),
  (
    0x2b2925e0U, "ADDSWrx Reg:W0 Reg:W15 Reg:W9 Imm:9 | adds w0, w15, w9, uxth #1",
    "",
  ),
  (
    0x2b34d0fdU, "ADDSWrx Reg:W29 Reg:W7 Reg:W20 Imm:52 | adds w29, w7, w20, sxtw #4",
    "",
  ),
  (
    0x2b39ac0cU, "ADDSWrx Reg:W12 Reg:W0 Reg:W25 Imm:43 | adds w12, w0, w25, sxth #3",
    "",
  ),
  (
    0x2b3db0dfU, "ADDSWrx Reg:WZR Reg:W6 Reg:W29 Imm:44 | cmn w6, w29, sxth #4",
    "",
  ),
  (
    0x2b3f02b2U, "ADDSWrx Reg:W18 Reg:W21 Reg:WZR Imm:0 | adds w18, w21, wzr, uxtb",
    "",
  ),
  (
    0x2b3f03ffU, "ADDSWrx Reg:WZR Reg:WSP Reg:WZR Imm:0 | cmn wsp, wzr, uxtb", "",
  ),
  (
    0x2b3f5280U, "ADDSWrx Reg:W0 Reg:W20 Reg:WZR Imm:20 | adds w0, w20, wzr, uxtw #4",
    "",
  ),
  (
    0x2b3f6f9fU, "ADDSWrx Reg:WZR Reg:W28 Reg:WZR Imm:27 | cmn w28, wzr, uxtx #3",
    "",
  ),
  (
    0x2b3f83edU, "ADDSWrx Reg:W13 Reg:WSP Reg:WZR Imm:32 | adds w13, wsp, wzr, sxtb",
    "",
  ),
  (
    0x2b3fcbffU, "ADDSWrx Reg:WZR Reg:WSP Reg:WZR Imm:50 | cmn wsp, wzr, sxtw #2",
    "",
  ),
  (
    0x2b3fee10U, "ADDSWrx Reg:W16 Reg:W16 Reg:WZR Imm:59 | adds w16, w16, wzr, sxtx #3",
    "",
  ),
  (
    0x2b3ff3ffU, "ADDSWrx Reg:WZR Reg:WSP Reg:WZR Imm:60 | cmn wsp, wzr, sxtx #4",
    "",
  ),
  (0x31000408U, "ADDSWri Reg:W8 Reg:W0 Imm:1 Imm:0 | adds w8, w0, #1", ""),
  (0x31401d1fU, "ADDSWri Reg:WZR Reg:W8 Imm:7 Imm:12 | cmn w8, #7, lsl #12", ""),
  (0x3200002aU, "ORRWri Reg:W10 Reg:W1 Imm:0 | orr w10, w1, #0x1", ""),
  (0x32009fecU, "ORRWri Reg:W12 Reg:WZR Imm:39 | mov w12, #16711935", ""),
  (
    0x33083901U, "BFMWri Reg:W1 Reg:W1 Reg:W8 Imm:8 Imm:14 | bfxil w1, w8, #8, #7",
    "",
  ),
  (
    0x331503f5U, "BFMWri Reg:W21 Reg:W21 Reg:WZR Imm:21 Imm:0 | bfc w21, #11, #1",
    "",
  ),
  (
    0x33180c01U, "BFMWri Reg:W1 Reg:W1 Reg:W0 Imm:24 Imm:3 | bfi w1, w0, #8, #4",
    "",
  ),
  (0x340002a0U, "CBZW Reg:W0 Imm:21 | cbz w0, #84", "cond,terminator,affect_cf"),
  (
    0x35ffffaaU, "CBNZW Reg:W10 Imm:-3 | cbnz w10, #-12", "cond,terminator,affect_cf",
  ),
  (
    0x36f800e8U, "TBZW Reg:W8 Imm:31 Imm:7 | tbz w8, #31, #28", "cond,terminator,affect_cf",
  ),
  (
    0x37f80240U, "TBNZW Reg:W0 Imm:31 Imm:18 | tbnz w0, #31, #72", "cond,terminator,affect_cf",
  ),
  (0x38000018U, "STURBBi Reg:W24 Reg:X0 Imm:0 | sturb w24, [x0]", "may_store"),
  (0x38000aa0U, "STTRBi Reg:W0 Reg:X21 Imm:0 | sttrb w0, [x21]", "may_store"),
  (
    0x38001700U, "STRBBpost Reg:X24 Reg:W0 Reg:X24 Imm:1 | strb w0, [x24], #1", "may_store",
  ),
  (
    0x38001c08U, "STRBBpre Reg:X0 Reg:W8 Reg:X0 Imm:1 | strb w8, [x0, #1]!", "may_store",
  ),
  (
    0x381a8b56U, "STTRBi Reg:W22 Reg:X26 Imm:-88 | sttrb w22, [x26, #-88]", "may_store",
  ),
  (
    0x381ff3a0U, "STURBBi Reg:W0 Reg:FP Imm:-1 | sturb w0, [x29, #-1]", "may_store",
  ),
  (
    0x38200178U, "LDADDB Reg:W24 Reg:W0 Reg:X11 | ldaddb w0, w24, [x11]", "may_load,may_store",
  ),
  (
    0x382003ffU, "LDADDB Reg:WZR Reg:W0 Reg:SP | staddb w0, [sp]", "may_load,may_store",
  ),
  (
    0x382132b2U, "LDSETB Reg:W18 Reg:W1 Reg:X21 | ldsetb w1, w18, [x21]", "may_load,may_store",
  ),
  (
    0x38214808U, "STRBBroW Reg:W8 Reg:X0 Reg:W1 Imm:0 Imm:0 | strb w8, [x0, w1, uxtw]",
    "may_store",
  ),
  (
    0x382262dfU, "LDUMAXB Reg:WZR Reg:W2 Reg:X22 | stumaxb w2, [x22]", "may_load,may_store",
  ),
  (
    0x3824427fU, "LDSMAXB Reg:WZR Reg:W4 Reg:X19 | stsmaxb w4, [x19]", "may_load,may_store",
  ),
  (
    0x3825d8a5U, "STRBBroW Reg:W5 Reg:X5 Reg:W5 Imm:1 Imm:1 | strb w5, [x5, w5, sxtw #0]",
    "may_store",
  ),
  (
    0x3827733fU, "LDUMINB Reg:WZR Reg:W7 Reg:X25 | stuminb w7, [x25]", "may_load,may_store",
  ),
  (
    0x3828434cU, "LDSMAXB Reg:W12 Reg:W8 Reg:X26 | ldsmaxb w8, w12, [x26]", "may_load,may_store",
  ),
  (
    0x3828cb00U, "STRBBroW Reg:W0 Reg:X24 Reg:W8 Imm:1 Imm:0 | strb w0, [x24, w8, sxtw]",
    "may_store",
  ),
  (
    0x382951f7U, "LDSMINB Reg:W23 Reg:W9 Reg:X15 | ldsminb w9, w23, [x15]", "may_load,may_store",
  ),
  (
    0x3829680cU, "STRBBroX Reg:W12 Reg:X0 Reg:X9 Imm:0 Imm:0 | strb w12, [x0, x9]",
    "may_store",
  ),
  (
    0x382b1096U, "LDCLRB Reg:W22 Reg:W11 Reg:X4 | ldclrb w11, w22, [x4]", "may_load,may_store",
  ),
  (
    0x382e23d4U, "LDEORB Reg:W20 Reg:W14 Reg:LR | ldeorb w14, w20, [x30]", "may_load,may_store",
  ),
  (
    0x3832217fU, "LDEORB Reg:WZR Reg:W18 Reg:X11 | steorb w18, [x11]", "may_load,may_store",
  ),
  (
    0x3834529fU, "LDSMINB Reg:WZR Reg:W20 Reg:X20 | stsminb w20, [x20]", "may_load,may_store",
  ),
  (
    0x3835317fU, "LDSETB Reg:WZR Reg:W21 Reg:X11 | stsetb w21, [x11]", "may_load,may_store",
  ),
  (
    0x3836105fU, "LDCLRB Reg:WZR Reg:W22 Reg:X2 | stclrb w22, [x2]", "may_load,may_store",
  ),
  (
    0x383762e5U, "LDUMAXB Reg:W5 Reg:W23 Reg:X23 | ldumaxb w23, w5, [x23]", "may_load,may_store",
  ),
  (
    0x383b73e0U, "LDUMINB Reg:W0 Reg:W27 Reg:SP | lduminb w27, w0, [sp]", "may_load,may_store",
  ),
  (
    0x383cfbc4U, "STRBBroX Reg:W4 Reg:LR Reg:X28 Imm:1 Imm:1 | strb w4, [x30, x28, sxtx #0]",
    "may_store",
  ),
  (
    0x383f58a0U, "STRBBroW Reg:W0 Reg:X5 Reg:WZR Imm:0 Imm:1 | strb w0, [x5, wzr, uxtw #0]",
    "may_store",
  ),
  (
    0x383f79acU, "STRBBroX Reg:W12 Reg:X13 Reg:XZR Imm:0 Imm:1 | strb w12, [x13, xzr, lsl #0]",
    "may_store",
  ),
  (
    0x383f824cU, "SWPB Reg:W12 Reg:WZR Reg:X18 | swpb wzr, w12, [x18]", "may_load,may_store",
  ),
  (
    0x383febfcU, "STRBBroX Reg:W28 Reg:SP Reg:XZR Imm:1 Imm:0 | strb w28, [sp, xzr, sxtx]",
    "may_store",
  ),
  (0x3840001fU, "LDURBBi Reg:WZR Reg:X0 Imm:0 | ldurb wzr, [x0]", "may_load"),
  (
    0x38401500U, "LDRBBpost Reg:X8 Reg:W0 Reg:X8 Imm:1 | ldrb w0, [x8], #1", "may_load",
  ),
  (
    0x38401d00U, "LDRBBpre Reg:X8 Reg:W0 Reg:X8 Imm:1 | ldrb w0, [x8, #1]!", "may_load",
  ),
  (
    0x385ae81fU, "LDTRBi Reg:WZR Reg:X0 Imm:-82 | ldtrb wzr, [x0, #-82]", "may_load",
  ),
  (
    0x385ff3a8U, "LDURBBi Reg:W8 Reg:FP Imm:-1 | ldurb w8, [x29, #-1]", "may_load",
  ),
  (
    0x38604900U, "LDRBBroW Reg:W0 Reg:X8 Reg:W0 Imm:0 Imm:0 | ldrb w0, [x8, w0, uxtw]",
    "may_load",
  ),
  (
    0x3861001fU, "LDADDLB Reg:WZR Reg:W1 Reg:X0 | staddlb w1, [x0]", "may_load,may_store",
  ),
  (
    0x38628013U, "SWPLB Reg:W19 Reg:W2 Reg:X0 | swplb w2, w19, [x0]", "may_load,may_store",
  ),
  (
    0x386303e0U, "LDADDLB Reg:W0 Reg:W3 Reg:SP | ldaddlb w3, w0, [sp]", "may_load,may_store",
  ),
  (
    0x386662ffU, "LDUMAXLB Reg:WZR Reg:W6 Reg:X23 | stumaxlb w6, [x23]", "may_load,may_store",
  ),
  (
    0x386722ffU, "LDEORLB Reg:WZR Reg:W7 Reg:X23 | steorlb w7, [x23]", "may_load,may_store",
  ),
  (
    0x386823e8U, "LDEORLB Reg:W8 Reg:W8 Reg:SP | ldeorlb w8, w8, [sp]", "may_load,may_store",
  ),
  (
    0x386830efU, "LDSETLB Reg:W15 Reg:W8 Reg:X7 | ldsetlb w8, w15, [x7]", "may_load,may_store",
  ),
  (
    0x3869c908U, "LDRBBroW Reg:W8 Reg:X8 Reg:W9 Imm:1 Imm:0 | ldrb w8, [x8, w9, sxtw]",
    "may_load",
  ),
  (
    0x386b694cU, "LDRBBroX Reg:W12 Reg:X10 Reg:X11 Imm:0 Imm:0 | ldrb w12, [x10, x11]",
    "may_load",
  ),
  (
    0x386bebefU, "LDRBBroX Reg:W15 Reg:SP Reg:X11 Imm:1 Imm:0 | ldrb w15, [sp, x11, sxtx]",
    "may_load",
  ),
  (
    0x386c11ffU, "LDCLRLB Reg:WZR Reg:W12 Reg:X15 | stclrlb w12, [x15]", "may_load,may_store",
  ),
  (
    0x386f6077U, "LDUMAXLB Reg:W23 Reg:W15 Reg:X3 | ldumaxlb w15, w23, [x3]", "may_load,may_store",
  ),
  (
    0x3870d94aU, "LDRBBroW Reg:W10 Reg:X10 Reg:W16 Imm:1 Imm:1 | ldrb w10, [x10, w16, sxtw #0]",
    "may_load",
  ),
  (
    0x387179acU, "LDRBBroX Reg:W12 Reg:X13 Reg:X17 Imm:0 Imm:1 | ldrb w12, [x13, x17, lsl #0]",
    "may_load",
  ),
  (
    0x387258c1U, "LDRBBroW Reg:W1 Reg:X6 Reg:W18 Imm:0 Imm:1 | ldrb w1, [x6, w18, uxtw #0]",
    "may_load",
  ),
  (
    0x38745325U, "LDSMINLB Reg:W5 Reg:W20 Reg:X25 | ldsminlb w20, w5, [x25]", "may_load,may_store",
  ),
  (
    0x3876fbeeU, "LDRBBroX Reg:W14 Reg:SP Reg:X22 Imm:1 Imm:1 | ldrb w14, [sp, x22, sxtx #0]",
    "may_load",
  ),
  (
    0x387a7111U, "LDUMINLB Reg:W17 Reg:W26 Reg:X8 | lduminlb w26, w17, [x8]", "may_load,may_store",
  ),
  (
    0x387b71dfU, "LDUMINLB Reg:WZR Reg:W27 Reg:X14 | stuminlb w27, [x14]", "may_load,may_store",
  ),
  (
    0x387d12fdU, "LDCLRLB Reg:W29 Reg:W29 Reg:X23 | ldclrlb w29, w29, [x23]", "may_load,may_store",
  ),
  (
    0x387d307fU, "LDSETLB Reg:WZR Reg:W29 Reg:X3 | stsetlb w29, [x3]", "may_load,may_store",
  ),
  (
    0x387d4052U, "LDSMAXLB Reg:W18 Reg:W29 Reg:X2 | ldsmaxlb w29, w18, [x2]", "may_load,may_store",
  ),
  (
    0x387d42bfU, "LDSMAXLB Reg:WZR Reg:W29 Reg:X21 | stsmaxlb w29, [x21]", "may_load,may_store",
  ),
  (
    0x387f52dfU, "LDSMINLB Reg:WZR Reg:WZR Reg:X22 | stsminlb wzr, [x22]", "may_load,may_store",
  ),
  (0x38800084U, "LDURSBXi Reg:X4 Reg:X4 Imm:0 | ldursb x4, [x4]", "may_load"),
  (
    0x38803e88U, "LDRSBXpre Reg:X20 Reg:X8 Reg:X20 Imm:3 | ldrsb x8, [x20, #3]!",
    "may_load",
  ),
  (
    0x38808680U, "LDRSBXpost Reg:X20 Reg:X0 Reg:X20 Imm:8 | ldrsb x0, [x20], #8",
    "may_load",
  ),
  (
    0x388138dfU, "LDTRSBXi Reg:XZR Reg:X6 Imm:19 | ldtrsb xzr, [x6, #19]", "may_load",
  ),
  (
    0x389ff108U, "LDURSBXi Reg:X8 Reg:X8 Imm:-1 | ldursb x8, [x8, #-1]", "may_load",
  ),
  (
    0x38a003eaU, "LDADDAB Reg:W10 Reg:W0 Reg:SP | ldaddab w0, w10, [sp]", "may_load,may_store",
  ),
  (
    0x38a040d6U, "LDSMAXAB Reg:W22 Reg:W0 Reg:X6 | ldsmaxab w0, w22, [x6]", "may_load,may_store",
  ),
  (
    0x38a043ffU, "LDSMAXAB Reg:WZR Reg:W0 Reg:SP | ldsmaxab w0, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38a0813fU, "SWPAB Reg:WZR Reg:W0 Reg:X9 | swpab w0, wzr, [x9] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38a1731aU, "LDUMINAB Reg:W26 Reg:W1 Reg:X24 | lduminab w1, w26, [x24]", "may_load,may_store",
  ),
  (
    0x38a1c908U, "LDRSBXroW Reg:X8 Reg:X8 Reg:W1 Imm:1 Imm:0 | ldrsb x8, [x8, w1, sxtw]",
    "may_load",
  ),
  (
    0x38a302dfU, "LDADDAB Reg:WZR Reg:W3 Reg:X22 | ldaddab w3, wzr, [x22] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38a553e2U, "LDSMINAB Reg:W2 Reg:W5 Reg:SP | ldsminab w5, w2, [sp]", "may_load,may_store",
  ),
  (
    0x38a610c7U, "LDCLRAB Reg:W7 Reg:W6 Reg:X6 | ldclrab w6, w7, [x6]", "may_load,may_store",
  ),
  (
    0x38a8107fU, "LDCLRAB Reg:WZR Reg:W8 Reg:X3 | ldclrab w8, wzr, [x3] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38a9205fU, "LDEORAB Reg:WZR Reg:W9 Reg:X2 | ldeorab w9, wzr, [x2] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38a9301bU, "LDSETAB Reg:W27 Reg:W9 Reg:X0 | ldsetab w9, w27, [x0]", "may_load,may_store",
  ),
  (
    0x38b3527fU, "LDSMINAB Reg:WZR Reg:W19 Reg:X19 | ldsminab w19, wzr, [x19] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38b36908U, "LDRSBXroX Reg:X8 Reg:X8 Reg:X19 Imm:0 Imm:0 | ldrsb x8, [x8, x19]",
    "may_load",
  ),
  (
    0x38b54908U, "LDRSBXroW Reg:X8 Reg:X8 Reg:W21 Imm:0 Imm:0 | ldrsb x8, [x8, w21, uxtw]",
    "may_load",
  ),
  (
    0x38b86227U, "LDUMAXAB Reg:W7 Reg:W24 Reg:X17 | ldumaxab w24, w7, [x17]", "may_load,may_store",
  ),
  (
    0x38b921f7U, "LDEORAB Reg:W23 Reg:W25 Reg:X15 | ldeorab w25, w23, [x15]", "may_load,may_store",
  ),
  (
    0x38bb61bfU, "LDUMAXAB Reg:WZR Reg:W27 Reg:X13 | ldumaxab w27, wzr, [x13] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38bd72bfU, "LDUMINAB Reg:WZR Reg:W29 Reg:X21 | lduminab w29, wzr, [x21] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38bf33ffU, "LDSETAB Reg:WZR Reg:WZR Reg:SP | ldsetab wzr, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38bf59afU, "LDRSBXroW Reg:X15 Reg:X13 Reg:WZR Imm:0 Imm:1 | ldrsb x15, [x13, wzr, uxtw #0]",
    "may_load",
  ),
  (
    0x38bf7b9fU, "LDRSBXroX Reg:XZR Reg:X28 Reg:XZR Imm:0 Imm:1 | ldrsb xzr, [x28, xzr, lsl #0]",
    "may_load",
  ),
  (
    0x38bf83e0U, "SWPAB Reg:W0 Reg:WZR Reg:SP | swpab wzr, w0, [sp]", "may_load,may_store",
  ),
  (0x38bfc39fU, "LDAPRB Reg:WZR Reg:X28 | ldaprb wzr, [x28]", "may_load"),
  (
    0x38bfdbffU, "LDRSBXroW Reg:XZR Reg:SP Reg:WZR Imm:1 Imm:1 | ldrsb xzr, [sp, wzr, sxtw #0]",
    "may_load",
  ),
  (
    0x38bfebf9U, "LDRSBXroX Reg:X25 Reg:SP Reg:XZR Imm:1 Imm:0 | ldrsb x25, [sp, xzr, sxtx]",
    "may_load",
  ),
  (
    0x38bffbbeU, "LDRSBXroX Reg:LR Reg:FP Reg:XZR Imm:1 Imm:1 | ldrsb x30, [x29, xzr, sxtx #0]",
    "may_load",
  ),
  (0x38c003edU, "LDURSBWi Reg:W13 Reg:SP Imm:0 | ldursb w13, [sp]", "may_load"),
  (
    0x38c00afaU, "LDTRSBWi Reg:W26 Reg:X23 Imm:0 | ldtrsb w26, [x23]", "may_load",
  ),
  (
    0x38c01708U, "LDRSBWpost Reg:X24 Reg:W8 Reg:X24 Imm:1 | ldrsb w8, [x24], #1",
    "may_load",
  ),
  (
    0x38c01d0cU, "LDRSBWpre Reg:X8 Reg:W12 Reg:X8 Imm:1 | ldrsb w12, [x8, #1]!",
    "may_load",
  ),
  (
    0x38c0bbc0U, "LDTRSBWi Reg:W0 Reg:LR Imm:11 | ldtrsb w0, [x30, #11]", "may_load",
  ),
  (
    0x38dff100U, "LDURSBWi Reg:W0 Reg:X8 Imm:-1 | ldursb w0, [x8, #-1]", "may_load",
  ),
  (
    0x38e02000U, "LDEORALB Reg:W0 Reg:W0 Reg:X0 | ldeoralb w0, w0, [x0]", "may_load,may_store",
  ),
  (
    0x38e0c900U, "LDRSBWroW Reg:W0 Reg:X8 Reg:W0 Imm:1 Imm:0 | ldrsb w0, [x8, w0, sxtw]",
    "may_load",
  ),
  (
    0x38e142a0U, "LDSMAXALB Reg:W0 Reg:W1 Reg:X21 | ldsmaxalb w1, w0, [x21]", "may_load,may_store",
  ),
  (
    0x38e14908U, "LDRSBWroW Reg:W8 Reg:X8 Reg:W1 Imm:0 Imm:0 | ldrsb w8, [x8, w1, uxtw]",
    "may_load",
  ),
  (
    0x38e1713fU, "LDUMINALB Reg:WZR Reg:W1 Reg:X9 | lduminalb w1, wzr, [x9] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38e1f884U, "LDRSBWroX Reg:W4 Reg:X4 Reg:X1 Imm:1 Imm:1 | ldrsb w4, [x4, x1, sxtx #0]",
    "may_load",
  ),
  (
    0x38e35108U, "LDSMINALB Reg:W8 Reg:W3 Reg:X8 | ldsminalb w3, w8, [x8]", "may_load,may_store",
  ),
  (
    0x38e4003fU, "LDADDALB Reg:WZR Reg:W4 Reg:X1 | ldaddalb w4, wzr, [x1] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38e4794fU, "LDRSBWroX Reg:W15 Reg:X10 Reg:X4 Imm:0 Imm:1 | ldrsb w15, [x10, x4, lsl #0]",
    "may_load",
  ),
  (
    0x38e57205U, "LDUMINALB Reg:W5 Reg:W5 Reg:X16 | lduminalb w5, w5, [x16]", "may_load,may_store",
  ),
  (
    0x38e71283U, "LDCLRALB Reg:W3 Reg:W7 Reg:X20 | ldclralb w7, w3, [x20]", "may_load,may_store",
  ),
  (
    0x38e922ffU, "LDEORALB Reg:WZR Reg:W9 Reg:X23 | ldeoralb w9, wzr, [x23] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38e95850U, "LDRSBWroW Reg:W16 Reg:X2 Reg:W9 Imm:0 Imm:1 | ldrsb w16, [x2, w9, uxtw #0]",
    "may_load",
  ),
  (
    0x38eb002aU, "LDADDALB Reg:W10 Reg:W11 Reg:X1 | ldaddalb w11, w10, [x1]", "may_load,may_store",
  ),
  (
    0x38ec3013U, "LDSETALB Reg:W19 Reg:W12 Reg:X0 | ldsetalb w12, w19, [x0]", "may_load,may_store",
  ),
  (
    0x38ef61c4U, "LDUMAXALB Reg:W4 Reg:W15 Reg:X14 | ldumaxalb w15, w4, [x14]", "may_load,may_store",
  ),
  (
    0x38efe903U, "LDRSBWroX Reg:W3 Reg:X8 Reg:X15 Imm:1 Imm:0 | ldrsb w3, [x8, x15, sxtx]",
    "may_load",
  ),
  (
    0x38f2113fU, "LDCLRALB Reg:WZR Reg:W18 Reg:X9 | ldclralb w18, wzr, [x9] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38f46901U, "LDRSBWroX Reg:W1 Reg:X8 Reg:X20 Imm:0 Imm:0 | ldrsb w1, [x8, x20]",
    "may_load",
  ),
  (
    0x38f6d857U, "LDRSBWroW Reg:W23 Reg:X2 Reg:W22 Imm:1 Imm:1 | ldrsb w23, [x2, w22, sxtw #0]",
    "may_load",
  ),
  (
    0x38fa62bfU, "LDUMAXALB Reg:WZR Reg:W26 Reg:X21 | ldumaxalb w26, wzr, [x21] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38ff319fU, "LDSETALB Reg:WZR Reg:WZR Reg:X12 | ldsetalb wzr, wzr, [x12] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38ff437fU, "LDSMAXALB Reg:WZR Reg:WZR Reg:X27 | ldsmaxalb wzr, wzr, [x27] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38ff529fU, "LDSMINALB Reg:WZR Reg:WZR Reg:X20 | ldsminalb wzr, wzr, [x20] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x38ff83f6U, "SWPALB Reg:W22 Reg:WZR Reg:SP | swpalb wzr, w22, [sp]", "may_load,may_store",
  ),
  (
    0x38ff83ffU, "SWPALB Reg:WZR Reg:WZR Reg:SP | swpalb wzr, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (0x39000008U, "STRBBui Reg:W8 Reg:X0 Imm:0 | strb w8, [x0]", "may_store"),
  (
    0x3900811fU, "STRBBui Reg:WZR Reg:X8 Imm:32 | strb wzr, [x8, #32]", "may_store",
  ),
  (0x39400108U, "LDRBBui Reg:W8 Reg:X8 Imm:0 | ldrb w8, [x8]", "may_load"),
  (
    0x39428fe9U, "LDRBBui Reg:W9 Reg:SP Imm:163 | ldrb w9, [sp, #163]", "may_load",
  ),
  (0x39800100U, "LDRSBXui Reg:X0 Reg:X8 Imm:0 | ldrsb x0, [x8]", "may_load"),
  (
    0x39804101U, "LDRSBXui Reg:X1 Reg:X8 Imm:16 | ldrsb x1, [x8, #16]", "may_load",
  ),
  (0x39c00000U, "LDRSBWui Reg:W0 Reg:X0 Imm:0 | ldrsb w0, [x0]", "may_load"),
  (0x39c00500U, "LDRSBWui Reg:W0 Reg:X8 Imm:1 | ldrsb w0, [x8, #1]", "may_load"),
  (0x3a1f03ffU, "ADCSWr Reg:WZR Reg:WZR Reg:WZR | adcs wzr, wzr, wzr", ""),
  (0x3a410800U, "CCMNWi Reg:W0 Imm:1 Imm:0 Imm:0 | ccmn w0, #1, #0, eq", ""),
  (
    0x3a4c02ccU, "CCMNWr Reg:W22 Reg:W12 Imm:12 Imm:0 | ccmn w22, w12, #12, eq",
    "",
  ),
  (
    0x48069fe6U, "STLXRH Reg:W6 Reg:W6 Reg:SP | stlxrh w6, w6, [sp]", "may_load,may_store",
  ),
  (
    0x481603f0U, "STXRH Reg:W22 Reg:W16 Reg:SP | stxrh w22, w16, [sp]", "may_load,may_store",
  ),
  (
    0x48267cdaU, "CASPX Reg:X6_X7 Reg:X6_X7 Reg:X26_X27 Reg:X6 | casp x6, x7, x26, x27, [x6]",
    "may_load,may_store",
  ),
  (
    0x483cff86U, "CASPLX Reg:X28_FP Reg:X28_FP Reg:X6_X7 Reg:X28 | caspl x28, x29, x6, x7, [x28]",
    "may_load,may_store",
  ),
  (0x484b7febU, "LDXRH Reg:W11 Reg:SP | ldxrh w11, [sp]", "may_load,may_store"),
  (
    0x485ff1c3U, "LDAXRH Reg:W3 Reg:X14 | ldaxrh w3, [x14]", "may_load,may_store",
  ),
  (
    0x487a7c18U, "CASPAX Reg:X26_X27 Reg:X26_X27 Reg:X24_X25 Reg:X0 | caspa x26, x27, x24, x25, [x0]",
    "may_load,may_store",
  ),
  (
    0x487afffaU, "CASPALX Reg:X26_X27 Reg:X26_X27 Reg:X26_X27 Reg:SP | caspal x26, x27, x26, x27, [sp]",
    "may_load,may_store",
  ),
  (0x4892881fU, "STLRH Reg:WZR Reg:X0 | stlrh wzr, [x0]", "may_store"),
  (0x489f2beaU, "STLLRH Reg:W10 Reg:SP | stllrh w10, [sp]", "may_store"),
  (
    0x48a07fe0U, "CASH Reg:W0 Reg:W0 Reg:W0 Reg:SP | cash w0, w0, [sp]", "may_load,may_store",
  ),
  (
    0x48bfffbdU, "CASLH Reg:WZR Reg:WZR Reg:W29 Reg:FP | caslh wzr, w29, [x29]",
    "may_load,may_store",
  ),
  (0x48da03ffU, "LDLARH Reg:WZR Reg:SP | ldlarh wzr, [sp]", "may_load"),
  (0x48dfc3e0U, "LDARH Reg:W0 Reg:SP | ldarh w0, [sp]", "may_load"),
  (
    0x48f5fc15U, "CASALH Reg:W21 Reg:W21 Reg:W21 Reg:X0 | casalh w21, w21, [x0]",
    "may_load,may_store",
  ),
  (
    0x48ff7ffdU, "CASAH Reg:WZR Reg:WZR Reg:W29 Reg:SP | casah wzr, w29, [sp]", "may_load,may_store",
  ),
  (0x4a080020U, "EORWrs Reg:W0 Reg:W1 Reg:W8 Imm:0 | eor w0, w1, w8", ""),
  (0x4a3f00ffU, "EONWrs Reg:WZR Reg:W7 Reg:WZR Imm:0 | eon wzr, w7, wzr", ""),
  (0x4b0803ecU, "SUBWrs Reg:W12 Reg:WZR Reg:W8 Imm:0 | neg w12, w8", ""),
  (
    0x4b20a631U, "SUBWrx Reg:W17 Reg:W17 Reg:W0 Imm:41 | sub w17, w17, w0, sxth #1",
    "",
  ),
  (
    0x4b280188U, "SUBWrx Reg:W8 Reg:W12 Reg:W8 Imm:0 | sub w8, w12, w8, uxtb", "",
  ),
  (
    0x4b2821b3U, "SUBWrx Reg:W19 Reg:W13 Reg:W8 Imm:8 | sub w19, w13, w8, uxth",
    "",
  ),
  (0x4b28411fU, "SUBWrx Reg:WSP Reg:W8 Reg:W8 Imm:16 | sub wsp, w8, w8", ""),
  (
    0x4b286739U, "SUBWrx Reg:W25 Reg:W25 Reg:W8 Imm:25 | sub w25, w25, w8, uxtx #1",
    "",
  ),
  (
    0x4b2bc33dU, "SUBWrx Reg:W29 Reg:W25 Reg:W11 Imm:48 | sub w29, w25, w11, sxtw",
    "",
  ),
  (
    0x4b2c8100U, "SUBWrx Reg:W0 Reg:W8 Reg:W12 Imm:32 | sub w0, w8, w12, sxtb", "",
  ),
  (
    0x4b3f5284U, "SUBWrx Reg:W4 Reg:W20 Reg:WZR Imm:20 | sub w4, w20, wzr, uxtw #4",
    "",
  ),
  (
    0x4b3feb5dU, "SUBWrx Reg:W29 Reg:W26 Reg:WZR Imm:58 | sub w29, w26, wzr, sxtx #2",
    "",
  ),
  (
    0x4b800d08U, "SUBWrs Reg:W8 Reg:W8 Reg:W0 Imm:131 | sub w8, w8, w0, asr #3",
    "",
  ),
  (0x51001c20U, "SUBWri Reg:W0 Reg:W1 Imm:7 Imm:0 | sub w0, w1, #7", ""),
  (0x52000000U, "EORWri Reg:W0 Reg:W0 Imm:0 | eor w0, w0, #0x1", ""),
  (0x528924a9U, "MOVZWi Reg:W9 Imm:18725 Imm:0 | mov w9, #18725", ""),
  (0x52a00000U, "MOVZWi Reg:W0 Imm:0 Imm:16 | movz w0, #0, lsl #16", ""),
  (0x53027d29U, "UBFMWri Reg:W9 Reg:W9 Imm:2 Imm:31 | lsr w9, w9, #2", ""),
  (0x53080400U, "UBFMWri Reg:W0 Reg:W0 Imm:8 Imm:1 | ubfiz w0, w0, #24, #2", ""),
  (
    0x53082e76U, "UBFMWri Reg:W22 Reg:W19 Imm:8 Imm:11 | ubfx w22, w19, #8, #4",
    "",
  ),
  (0x531e7420U, "UBFMWri Reg:W0 Reg:W1 Imm:30 Imm:29 | lsl w0, w1, #2", ""),
  (0x540000aaU, "Bcc Imm:10 Imm:5 | b.ge #20", "cond,terminator,affect_cf"),
  (0x540000abU, "Bcc Imm:11 Imm:5 | b.lt #20", "cond,terminator,affect_cf"),
  (0x540000ccU, "Bcc Imm:12 Imm:6 | b.gt #24", "cond,terminator,affect_cf"),
  (0x540000e3U, "Bcc Imm:3 Imm:7 | b.lo #28", "cond,terminator,affect_cf"),
  (0x54000125U, "Bcc Imm:5 Imm:9 | b.pl #36", "cond,terminator,affect_cf"),
  (0x54000169U, "Bcc Imm:9 Imm:11 | b.ls #44", "cond,terminator,affect_cf"),
  (0x5400016dU, "Bcc Imm:13 Imm:11 | b.le #44", "cond,terminator,affect_cf"),
  (0x54000204U, "Bcc Imm:4 Imm:16 | b.mi #64", "cond,terminator,affect_cf"),
  (0x54000282U, "Bcc Imm:2 Imm:20 | b.hs #80", "cond,terminator,affect_cf"),
  (0x54000440U, "Bcc Imm:0 Imm:34 | b.eq #136", "cond,terminator,affect_cf"),
  (0x54000541U, "Bcc Imm:1 Imm:42 | b.ne #168", "cond,terminator,affect_cf"),
  (0x54000626U, "Bcc Imm:6 Imm:49 | b.vs #196", "cond,terminator,affect_cf"),
  (0x540013a7U, "Bcc Imm:7 Imm:157 | b.vc #628", "cond,terminator,affect_cf"),
  (
    0x540f03afU, "Bcc Imm:15 Imm:30749 | b.nv #122996", "cond,terminator,affect_cf",
  ),
  (
    0x541f7c0eU, "Bcc Imm:14 Imm:64480 | b.al #257920", "cond,terminator,affect_cf",
  ),
  (0x54ffffa8U, "Bcc Imm:8 Imm:-3 | b.hi #-12", "cond,terminator,affect_cf"),
  (0x581f02a1U, "LDRXl Reg:X1 Imm:63509 | ldr x1, #254036", "may_load"),
  (0x5a0d03fcU, "SBCWr Reg:W28 Reg:WZR Reg:W13 | ngc w28, w13", ""),
  (0x5a1801c0U, "SBCWr Reg:W0 Reg:W14 Reg:W24 | sbc w0, w14, w24", ""),
  (0x5a80100aU, "CSINVWr Reg:W10 Reg:W0 Reg:W0 Imm:1 | cinv w10, w0, eq", ""),
  (0x5a82544bU, "CSNEGWr Reg:W11 Reg:W2 Reg:W2 Imm:5 | cneg w11, w2, mi", ""),
  (
    0x5a885188U, "CSINVWr Reg:W8 Reg:W12 Reg:W8 Imm:5 | csinv w8, w12, w8, pl", "",
  ),
  (
    0x5a930508U, "CSNEGWr Reg:W8 Reg:W8 Reg:W19 Imm:0 | csneg w8, w8, w19, eq", "",
  ),
  (0x5a9f03e0U, "CSINVWr Reg:W0 Reg:WZR Reg:WZR Imm:0 | csetm w0, ne", ""),
  (0x5ac00176U, "RBITWr Reg:W22 Reg:W11 | rbit w22, w11", ""),
  (0x5ac00500U, "REV16Wr Reg:W0 Reg:W8 | rev16 w0, w8", ""),
  (0x5ac00849U, "REVWr Reg:W9 Reg:W2 | rev w9, w2", ""),
  (0x5ac01109U, "CLZWr Reg:W9 Reg:W8 | clz w9, w8", ""),
  (0x5ac01573U, "CLSWr Reg:W19 Reg:W11 | cls w19, w11", ""),
  (
    0x68ce03e5U, "LDPSWpost Reg:SP Reg:X5 Reg:X0 Reg:SP Imm:28 | ldpsw x5, x0, [sp], #112",
    "may_load",
  ),
  (
    0x69401005U, "LDPSWi Reg:X5 Reg:X4 Reg:X0 Imm:0 | ldpsw x5, x4, [x0]", "may_load",
  ),
  (
    0x69410403U, "LDPSWi Reg:X3 Reg:X1 Reg:X0 Imm:2 | ldpsw x3, x1, [x0, #8]", "may_load",
  ),
  (
    0x69d303ffU, "LDPSWpre Reg:SP Reg:XZR Reg:X0 Reg:SP Imm:38 | ldpsw xzr, x0, [sp, #152]!",
    "may_load",
  ),
  (0x6a08001fU, "ANDSWrs Reg:WZR Reg:W0 Reg:W8 Imm:0 | tst w0, w8", ""),
  (0x6a0b0100U, "ANDSWrs Reg:W0 Reg:W8 Reg:W11 Imm:0 | ands w0, w8, w11", ""),
  (0x6a28001fU, "BICSWrs Reg:WZR Reg:W0 Reg:W8 Imm:0 | bics wzr, w0, w8", ""),
  (0x6b01001fU, "SUBSWrs Reg:WZR Reg:W0 Reg:W1 Imm:0 | cmp w0, w1", ""),
  (0x6b090108U, "SUBSWrs Reg:W8 Reg:W8 Reg:W9 Imm:0 | subs w8, w8, w9", ""),
  (0x6b0903e8U, "SUBSWrs Reg:W8 Reg:WZR Reg:W9 Imm:0 | negs w8, w9", ""),
  (0x6b20a11fU, "SUBSWrx Reg:WZR Reg:W8 Reg:W0 Imm:40 | cmp w8, w0, sxth", ""),
  (
    0x6b20c81fU, "SUBSWrx Reg:WZR Reg:W0 Reg:W0 Imm:50 | cmp w0, w0, sxtw #2", "",
  ),
  (
    0x6b20ef7fU, "SUBSWrx Reg:WZR Reg:W27 Reg:W0 Imm:59 | cmp w27, w0, sxtx #3",
    "",
  ),
  (
    0x6b29010cU, "SUBSWrx Reg:W12 Reg:W8 Reg:W9 Imm:0 | subs w12, w8, w9, uxtb",
    "",
  ),
  (0x6b29211fU, "SUBSWrx Reg:WZR Reg:W8 Reg:W9 Imm:8 | cmp w8, w9, uxth", ""),
  (0x6b2a013fU, "SUBSWrx Reg:WZR Reg:W9 Reg:W10 Imm:0 | cmp w9, w10, uxtb", ""),
  (
    0x6b2c81b1U, "SUBSWrx Reg:W17 Reg:W13 Reg:W12 Imm:32 | subs w17, w13, w12, sxtb",
    "",
  ),
  (
    0x6b32469cU, "SUBSWrx Reg:W28 Reg:W20 Reg:W18 Imm:17 | subs w28, w20, w18, uxtw #1",
    "",
  ),
  (
    0x6b3573fcU, "SUBSWrx Reg:W28 Reg:WSP Reg:W21 Imm:28 | subs w28, wsp, w21, uxtx #4",
    "",
  ),
  (0x6b35801fU, "SUBSWrx Reg:WZR Reg:W0 Reg:W21 Imm:32 | cmp w0, w21, sxtb", ""),
  (
    0x6b3f23e7U, "SUBSWrx Reg:W7 Reg:WSP Reg:WZR Imm:8 | subs w7, wsp, wzr, uxth",
    "",
  ),
  (
    0x6b3f501fU, "SUBSWrx Reg:WZR Reg:W0 Reg:WZR Imm:20 | cmp w0, wzr, uxtw #4",
    "",
  ),
  (
    0x6b3fb3ecU, "SUBSWrx Reg:W12 Reg:WSP Reg:WZR Imm:44 | subs w12, wsp, wzr, sxth #4",
    "",
  ),
  (
    0x6b3fcfefU, "SUBSWrx Reg:W15 Reg:WSP Reg:WZR Imm:51 | subs w15, wsp, wzr, sxtw #3",
    "",
  ),
  (
    0x6b3ff139U, "SUBSWrx Reg:W25 Reg:W9 Reg:WZR Imm:60 | subs w25, w9, wzr, sxtx #4",
    "",
  ),
  (0x7100005fU, "SUBSWri Reg:WZR Reg:W2 Imm:0 Imm:0 | cmp w2, #0", ""),
  (0x71000508U, "SUBSWri Reg:W8 Reg:W8 Imm:1 Imm:0 | subs w8, w8, #1", ""),
  (0x72001901U, "ANDSWri Reg:W1 Reg:W8 Imm:6 | ands w1, w8, #0x7f", ""),
  (0x7201001fU, "ANDSWri Reg:WZR Reg:W0 Imm:64 | tst w0, #0x80000000", ""),
  (
    0x72a49249U, "MOVKWi Reg:W9 Reg:W9 Imm:9362 Imm:16 | movk w9, #9362, lsl #16",
    "",
  ),
  (0x780003ffU, "STURHHi Reg:WZR Reg:SP Imm:0 | sturh wzr, [sp]", "may_store"),
  (
    0x78001408U, "STRHHpost Reg:X0 Reg:W8 Reg:X0 Imm:1 | strh w8, [x0], #1", "may_store",
  ),
  (
    0x78003c0cU, "STRHHpre Reg:X0 Reg:W12 Reg:X0 Imm:3 | strh w12, [x0, #3]!", "may_store",
  ),
  (
    0x781aeb5fU, "STTRHi Reg:WZR Reg:X26 Imm:-82 | sttrh wzr, [x26, #-82]", "may_store",
  ),
  (
    0x781dc3bfU, "STURHHi Reg:WZR Reg:FP Imm:-36 | sturh wzr, [x29, #-36]", "may_store",
  ),
  (
    0x78205909U, "STRHHroW Reg:W9 Reg:X8 Reg:W0 Imm:0 Imm:1 | strh w9, [x8, w0, uxtw #1]",
    "may_store",
  ),
  (
    0x78206b08U, "STRHHroX Reg:W8 Reg:X24 Reg:X0 Imm:0 Imm:0 | strh w8, [x24, x0]",
    "may_store",
  ),
  (
    0x782070e7U, "LDUMINH Reg:W7 Reg:W0 Reg:X7 | lduminh w0, w7, [x7]", "may_load,may_store",
  ),
  (
    0x7821111fU, "LDCLRH Reg:WZR Reg:W1 Reg:X8 | stclrh w1, [x8]", "may_load,may_store",
  ),
  (
    0x78214b54U, "STRHHroW Reg:W20 Reg:X26 Reg:W1 Imm:0 Imm:0 | strh w20, [x26, w1, uxtw]",
    "may_store",
  ),
  (
    0x7824531fU, "LDSMINH Reg:WZR Reg:W4 Reg:X24 | stsminh w4, [x24]", "may_load,may_store",
  ),
  (
    0x782551beU, "LDSMINH Reg:W30 Reg:W5 Reg:X13 | ldsminh w5, w30, [x13]", "may_load,may_store",
  ),
  (
    0x782843f3U, "LDSMAXH Reg:W19 Reg:W8 Reg:SP | ldsmaxh w8, w19, [sp]", "may_load,may_store",
  ),
  (
    0x782862ffU, "LDUMAXH Reg:WZR Reg:W8 Reg:X23 | stumaxh w8, [x23]", "may_load,may_store",
  ),
  (
    0x78297900U, "STRHHroX Reg:W0 Reg:X8 Reg:X9 Imm:0 Imm:1 | strh w0, [x8, x9, lsl #1]",
    "may_store",
  ),
  (
    0x782a237fU, "LDEORH Reg:WZR Reg:W10 Reg:X27 | steorh w10, [x27]", "may_load,may_store",
  ),
  (
    0x782b73bfU, "LDUMINH Reg:WZR Reg:W11 Reg:FP | stuminh w11, [x29]", "may_load,may_store",
  ),
  (
    0x782bfb28U, "STRHHroX Reg:W8 Reg:X25 Reg:X11 Imm:1 Imm:1 | strh w8, [x25, x11, sxtx #1]",
    "may_store",
  ),
  (
    0x783011d4U, "LDCLRH Reg:W20 Reg:W16 Reg:X14 | ldclrh w16, w20, [x14]", "may_load,may_store",
  ),
  (
    0x783022eeU, "LDEORH Reg:W14 Reg:W16 Reg:X23 | ldeorh w16, w14, [x23]", "may_load,may_store",
  ),
  (
    0x783283e0U, "SWPH Reg:W0 Reg:W18 Reg:SP | swph w18, w0, [sp]", "may_load,may_store",
  ),
  (
    0x7833c808U, "STRHHroW Reg:W8 Reg:X0 Reg:W19 Imm:1 Imm:0 | strh w8, [x0, w19, sxtw]",
    "may_store",
  ),
  (
    0x7835d900U, "STRHHroW Reg:W0 Reg:X8 Reg:W21 Imm:1 Imm:1 | strh w0, [x8, w21, sxtw #1]",
    "may_store",
  ),
  (
    0x7838303aU, "LDSETH Reg:W26 Reg:W24 Reg:X1 | ldseth w24, w26, [x1]", "may_load,may_store",
  ),
  (
    0x783840bfU, "LDSMAXH Reg:WZR Reg:W24 Reg:X5 | stsmaxh w24, [x5]", "may_load,may_store",
  ),
  (
    0x783c635cU, "LDUMAXH Reg:W28 Reg:W28 Reg:X26 | ldumaxh w28, w28, [x26]", "may_load,may_store",
  ),
  (
    0x783ee813U, "STRHHroX Reg:W19 Reg:X0 Reg:LR Imm:1 Imm:0 | strh w19, [x0, x30, sxtx]",
    "may_store",
  ),
  (
    0x783f03f0U, "LDADDH Reg:W16 Reg:WZR Reg:SP | ldaddh wzr, w16, [sp]", "may_load,may_store",
  ),
  (
    0x783f03ffU, "LDADDH Reg:WZR Reg:WZR Reg:SP | staddh wzr, [sp]", "may_load,may_store",
  ),
  (
    0x783f33ffU, "LDSETH Reg:WZR Reg:WZR Reg:SP | stseth wzr, [sp]", "may_load,may_store",
  ),
  (0x7840005fU, "LDURHHi Reg:WZR Reg:X2 Imm:0 | ldurh wzr, [x2]", "may_load"),
  (
    0x78402509U, "LDRHHpost Reg:X8 Reg:W9 Reg:X8 Imm:2 | ldrh w9, [x8], #2", "may_load",
  ),
  (
    0x78410c08U, "LDRHHpre Reg:X0 Reg:W8 Reg:X0 Imm:16 | ldrh w8, [x0, #16]!", "may_load",
  ),
  (
    0x784c4a1fU, "LDTRHi Reg:WZR Reg:X16 Imm:196 | ldtrh wzr, [x16, #196]", "may_load",
  ),
  (
    0x785dc3a8U, "LDURHHi Reg:W8 Reg:FP Imm:-36 | ldurh w8, [x29, #-36]", "may_load",
  ),
  (
    0x78605295U, "LDSMINLH Reg:W21 Reg:W0 Reg:X20 | ldsminlh w0, w21, [x20]", "may_load,may_store",
  ),
  (
    0x7860c95fU, "LDRHHroW Reg:WZR Reg:X10 Reg:W0 Imm:1 Imm:0 | ldrh wzr, [x10, w0, sxtw]",
    "may_load",
  ),
  (
    0x7862303fU, "LDSETLH Reg:WZR Reg:W2 Reg:X1 | stsetlh w2, [x1]", "may_load,may_store",
  ),
  (
    0x78626803U, "LDRHHroX Reg:W3 Reg:X0 Reg:X2 Imm:0 Imm:0 | ldrh w3, [x0, x2]",
    "may_load",
  ),
  (
    0x7867123fU, "LDCLRLH Reg:WZR Reg:W7 Reg:X17 | stclrlh w7, [x17]", "may_load,may_store",
  ),
  (
    0x786842f0U, "LDSMAXLH Reg:W16 Reg:W8 Reg:X23 | ldsmaxlh w8, w16, [x23]", "may_load,may_store",
  ),
  (
    0x7868529fU, "LDSMINLH Reg:WZR Reg:W8 Reg:X20 | stsminlh w8, [x20]", "may_load,may_store",
  ),
  (
    0x78695908U, "LDRHHroW Reg:W8 Reg:X8 Reg:W9 Imm:0 Imm:1 | ldrh w8, [x8, w9, uxtw #1]",
    "may_load",
  ),
  (
    0x7869ebffU, "LDRHHroX Reg:WZR Reg:SP Reg:X9 Imm:1 Imm:0 | ldrh wzr, [sp, x9, sxtx]",
    "may_load",
  ),
  (
    0x786a205fU, "LDEORLH Reg:WZR Reg:W10 Reg:X2 | steorlh w10, [x2]", "may_load,may_store",
  ),
  (
    0x786c23ecU, "LDEORLH Reg:W12 Reg:W12 Reg:SP | ldeorlh w12, w12, [sp]", "may_load,may_store",
  ),
  (
    0x786d70bfU, "LDUMINLH Reg:WZR Reg:W13 Reg:X5 | stuminlh w13, [x5]", "may_load,may_store",
  ),
  (
    0x786f4960U, "LDRHHroW Reg:W0 Reg:X11 Reg:W15 Imm:0 Imm:0 | ldrh w0, [x11, w15, uxtw]",
    "may_load",
  ),
  (
    0x787163ffU, "LDUMAXLH Reg:WZR Reg:W17 Reg:SP | stumaxlh w17, [sp]", "may_load,may_store",
  ),
  (
    0x78736238U, "LDUMAXLH Reg:W24 Reg:W19 Reg:X17 | ldumaxlh w19, w24, [x17]", "may_load,may_store",
  ),
  (
    0x78747308U, "LDUMINLH Reg:W8 Reg:W20 Reg:X24 | lduminlh w20, w8, [x24]", "may_load,may_store",
  ),
  (
    0x78787900U, "LDRHHroX Reg:W0 Reg:X8 Reg:X24 Imm:0 Imm:1 | ldrh w0, [x8, x24, lsl #1]",
    "may_load",
  ),
  (
    0x787903ffU, "LDADDLH Reg:WZR Reg:W25 Reg:SP | staddlh w25, [sp]", "may_load,may_store",
  ),
  (
    0x7879d900U, "LDRHHroW Reg:W0 Reg:X8 Reg:W25 Imm:1 Imm:1 | ldrh w0, [x8, w25, sxtw #1]",
    "may_load",
  ),
  (
    0x787b1382U, "LDCLRLH Reg:W2 Reg:W27 Reg:X28 | ldclrlh w27, w2, [x28]", "may_load,may_store",
  ),
  (
    0x787d336aU, "LDSETLH Reg:W10 Reg:W29 Reg:X27 | ldsetlh w29, w10, [x27]", "may_load,may_store",
  ),
  (
    0x787efbc0U, "LDRHHroX Reg:W0 Reg:LR Reg:LR Imm:1 Imm:1 | ldrh w0, [x30, x30, sxtx #1]",
    "may_load",
  ),
  (
    0x787f03e0U, "LDADDLH Reg:W0 Reg:WZR Reg:SP | ldaddlh wzr, w0, [sp]", "may_load,may_store",
  ),
  (
    0x787f429fU, "LDSMAXLH Reg:WZR Reg:WZR Reg:X20 | stsmaxlh wzr, [x20]", "may_load,may_store",
  ),
  (
    0x787f82b5U, "SWPLH Reg:W21 Reg:WZR Reg:X21 | swplh wzr, w21, [x21]", "may_load,may_store",
  ),
  (0x788003ffU, "LDURSHXi Reg:XZR Reg:SP Imm:0 | ldursh xzr, [sp]", "may_load"),
  (
    0x7898c847U, "LDTRSHXi Reg:X7 Reg:X2 Imm:-116 | ldtrsh x7, [x2, #-116]", "may_load",
  ),
  (
    0x789f47f1U, "LDRSHXpost Reg:SP Reg:X17 Reg:SP Imm:-12 | ldrsh x17, [sp], #-12",
    "may_load",
  ),
  (
    0x789fe108U, "LDURSHXi Reg:X8 Reg:X8 Imm:-2 | ldursh x8, [x8, #-2]", "may_load",
  ),
  (
    0x789fee88U, "LDRSHXpre Reg:X20 Reg:X8 Reg:X20 Imm:-2 | ldrsh x8, [x20, #-2]!",
    "may_load",
  ),
  (
    0x78a0401fU, "LDSMAXAH Reg:WZR Reg:W0 Reg:X0 | ldsmaxah w0, wzr, [x0] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78a08000U, "SWPAH Reg:W0 Reg:W0 Reg:X0 | swpah w0, w0, [x0]", "may_load,may_store",
  ),
  (
    0x78a0831fU, "SWPAH Reg:WZR Reg:W0 Reg:X24 | swpah w0, wzr, [x24] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78a0c9dfU, "LDRSHXroW Reg:XZR Reg:X14 Reg:W0 Imm:1 Imm:0 | ldrsh xzr, [x14, w0, sxtw]",
    "may_load",
  ),
  (
    0x78a0ebe7U, "LDRSHXroX Reg:X7 Reg:SP Reg:X0 Imm:1 Imm:0 | ldrsh x7, [sp, x0, sxtx]",
    "may_load",
  ),
  (
    0x78a3fb04U, "LDRSHXroX Reg:X4 Reg:X24 Reg:X3 Imm:1 Imm:1 | ldrsh x4, [x24, x3, sxtx #1]",
    "may_load",
  ),
  (
    0x78a5229fU, "LDEORAH Reg:WZR Reg:W5 Reg:X20 | ldeorah w5, wzr, [x20] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78a7da41U, "LDRSHXroW Reg:X1 Reg:X18 Reg:W7 Imm:1 Imm:1 | ldrsh x1, [x18, w7, sxtw #1]",
    "may_load",
  ),
  (
    0x78a822d6U, "LDEORAH Reg:W22 Reg:W8 Reg:X22 | ldeorah w8, w22, [x22]", "may_load,may_store",
  ),
  (
    0x78a8594aU, "LDRSHXroW Reg:X10 Reg:X10 Reg:W8 Imm:0 Imm:1 | ldrsh x10, [x10, w8, uxtw #1]",
    "may_load",
  ),
  (
    0x78a87b4fU, "LDRSHXroX Reg:X15 Reg:X26 Reg:X8 Imm:0 Imm:1 | ldrsh x15, [x26, x8, lsl #1]",
    "may_load",
  ),
  (
    0x78a9507fU, "LDSMINAH Reg:WZR Reg:W9 Reg:X3 | ldsminah w9, wzr, [x3] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78af41a3U, "LDSMAXAH Reg:W3 Reg:W15 Reg:X13 | ldsmaxah w15, w3, [x13]", "may_load,may_store",
  ),
  (
    0x78b1638fU, "LDUMAXAH Reg:W15 Reg:W17 Reg:X28 | ldumaxah w17, w15, [x28]", "may_load,may_store",
  ),
  (
    0x78b36b2aU, "LDRSHXroX Reg:X10 Reg:X25 Reg:X19 Imm:0 Imm:0 | ldrsh x10, [x25, x19]",
    "may_load",
  ),
  (
    0x78b372bfU, "LDUMINAH Reg:WZR Reg:W19 Reg:X21 | lduminah w19, wzr, [x21] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78b45280U, "LDSMINAH Reg:W0 Reg:W20 Reg:X20 | ldsminah w20, w0, [x20]", "may_load,may_store",
  ),
  (
    0x78b5115fU, "LDCLRAH Reg:WZR Reg:W21 Reg:X10 | ldclrah w21, wzr, [x10] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78b6623fU, "LDUMAXAH Reg:WZR Reg:W22 Reg:X17 | ldumaxah w22, wzr, [x17] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78bc10e6U, "LDCLRAH Reg:W6 Reg:W28 Reg:X7 | ldclrah w28, w6, [x7]", "may_load,may_store",
  ),
  (
    0x78bd33dfU, "LDSETAH Reg:WZR Reg:W29 Reg:LR | ldsetah w29, wzr, [x30] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78be4a0aU, "LDRSHXroW Reg:X10 Reg:X16 Reg:W30 Imm:0 Imm:0 | ldrsh x10, [x16, w30, uxtw]",
    "may_load",
  ),
  (
    0x78bf005fU, "LDADDAH Reg:WZR Reg:WZR Reg:X2 | ldaddah wzr, wzr, [x2] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78bf00d2U, "LDADDAH Reg:W18 Reg:WZR Reg:X6 | ldaddah wzr, w18, [x6]", "may_load,may_store",
  ),
  (
    0x78bf33f0U, "LDSETAH Reg:W16 Reg:WZR Reg:SP | ldsetah wzr, w16, [sp]", "may_load,may_store",
  ),
  (
    0x78bf73e1U, "LDUMINAH Reg:W1 Reg:WZR Reg:SP | lduminah wzr, w1, [sp]", "may_load,may_store",
  ),
  (0x78bfc165U, "LDAPRH Reg:W5 Reg:X11 | ldaprh w5, [x11]", "may_load"),
  (0x78c00265U, "LDURSHWi Reg:W5 Reg:X19 Imm:0 | ldursh w5, [x19]", "may_load"),
  (
    0x78c47fffU, "LDRSHWpre Reg:SP Reg:WZR Reg:SP Imm:71 | ldrsh wzr, [sp, #71]!",
    "may_load",
  ),
  (
    0x78d3493eU, "LDTRSHWi Reg:W30 Reg:X9 Imm:-204 | ldtrsh w30, [x9, #-204]", "may_load",
  ),
  (
    0x78d9052bU, "LDRSHWpost Reg:X9 Reg:W11 Reg:X9 Imm:-112 | ldrsh w11, [x9], #-112",
    "may_load",
  ),
  (
    0x78dfe109U, "LDURSHWi Reg:W9 Reg:X8 Imm:-2 | ldursh w9, [x8, #-2]", "may_load",
  ),
  (
    0x78e07015U, "LDUMINALH Reg:W21 Reg:W0 Reg:X0 | lduminalh w0, w21, [x0]", "may_load,may_store",
  ),
  (
    0x78e0801fU, "SWPALH Reg:WZR Reg:W0 Reg:X0 | swpalh w0, wzr, [x0] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78e261dfU, "LDUMAXALH Reg:WZR Reg:W2 Reg:X14 | ldumaxalh w2, wzr, [x14] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78e3719fU, "LDUMINALH Reg:WZR Reg:W3 Reg:X12 | lduminalh w3, wzr, [x12] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78e43305U, "LDSETALH Reg:W5 Reg:W4 Reg:X24 | ldsetalh w4, w5, [x24]", "may_load,may_store",
  ),
  (
    0x78e86920U, "LDRSHWroX Reg:W0 Reg:X9 Reg:X8 Imm:0 Imm:0 | ldrsh w0, [x9, x8]",
    "may_load",
  ),
  (
    0x78e8d928U, "LDRSHWroW Reg:W8 Reg:X9 Reg:W8 Imm:1 Imm:1 | ldrsh w8, [x9, w8, sxtw #1]",
    "may_load",
  ),
  (
    0x78e97908U, "LDRSHWroX Reg:W8 Reg:X8 Reg:X9 Imm:0 Imm:1 | ldrsh w8, [x8, x9, lsl #1]",
    "may_load",
  ),
  (
    0x78ea5900U, "LDRSHWroW Reg:W0 Reg:X8 Reg:W10 Imm:0 Imm:1 | ldrsh w0, [x8, w10, uxtw #1]",
    "may_load",
  ),
  (
    0x78ed03bfU, "LDADDALH Reg:WZR Reg:W13 Reg:FP | ldaddalh w13, wzr, [x29] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78f433bfU, "LDSETALH Reg:WZR Reg:W20 Reg:FP | ldsetalh w20, wzr, [x29] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78f46107U, "LDUMAXALH Reg:W7 Reg:W20 Reg:X8 | ldumaxalh w20, w7, [x8]", "may_load,may_store",
  ),
  (
    0x78f6eb5eU, "LDRSHWroX Reg:W30 Reg:X26 Reg:X22 Imm:1 Imm:0 | ldrsh w30, [x26, x22, sxtx]",
    "may_load",
  ),
  (
    0x78f78033U, "SWPALH Reg:W19 Reg:W23 Reg:X1 | swpalh w23, w19, [x1]", "may_load,may_store",
  ),
  (
    0x78f7fa66U, "LDRSHWroX Reg:W6 Reg:X19 Reg:X23 Imm:1 Imm:1 | ldrsh w6, [x19, x23, sxtx #1]",
    "may_load",
  ),
  (
    0x78f822dfU, "LDEORALH Reg:WZR Reg:W24 Reg:X22 | ldeoralh w24, wzr, [x22] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78f8431fU, "LDSMAXALH Reg:WZR Reg:W24 Reg:X24 | ldsmaxalh w24, wzr, [x24] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78f850aeU, "LDSMINALH Reg:W14 Reg:W24 Reg:X5 | ldsminalh w24, w14, [x5]", "may_load,may_store",
  ),
  (
    0x78fd23c7U, "LDEORALH Reg:W7 Reg:W29 Reg:LR | ldeoralh w29, w7, [x30]", "may_load,may_store",
  ),
  (
    0x78ff0349U, "LDADDALH Reg:W9 Reg:WZR Reg:X26 | ldaddalh wzr, w9, [x26]", "may_load,may_store",
  ),
  (
    0x78ff13baU, "LDCLRALH Reg:W26 Reg:WZR Reg:FP | ldclralh wzr, w26, [x29]", "may_load,may_store",
  ),
  (
    0x78ff13ffU, "LDCLRALH Reg:WZR Reg:WZR Reg:SP | ldclralh wzr, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78ff43fcU, "LDSMAXALH Reg:W28 Reg:WZR Reg:SP | ldsmaxalh wzr, w28, [sp]", "may_load,may_store",
  ),
  (
    0x78ff4a9dU, "LDRSHWroW Reg:W29 Reg:X20 Reg:WZR Imm:0 Imm:0 | ldrsh w29, [x20, wzr, uxtw]",
    "may_load",
  ),
  (
    0x78ff509fU, "LDSMINALH Reg:WZR Reg:WZR Reg:X4 | ldsminalh wzr, wzr, [x4] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0x78ffcbffU, "LDRSHWroW Reg:WZR Reg:SP Reg:WZR Imm:1 Imm:0 | ldrsh wzr, [sp, wzr, sxtw]",
    "may_load",
  ),
  (0x79000100U, "STRHHui Reg:W0 Reg:X8 Imm:0 | strh w0, [x8]", "may_store"),
  (
    0x79004008U, "STRHHui Reg:W8 Reg:X0 Imm:16 | strh w8, [x0, #32]", "may_store",
  ),
  (0x79400100U, "LDRHHui Reg:W0 Reg:X8 Imm:0 | ldrh w0, [x8]", "may_load"),
  (0x79400c0bU, "LDRHHui Reg:W11 Reg:X0 Imm:3 | ldrh w11, [x0, #6]", "may_load"),
  (0x79800119U, "LDRSHXui Reg:X25 Reg:X8 Imm:0 | ldrsh x25, [x8]", "may_load"),
  (
    0x79805108U, "LDRSHXui Reg:X8 Reg:X8 Imm:20 | ldrsh x8, [x8, #40]", "may_load",
  ),
  (0x79c00008U, "LDRSHWui Reg:W8 Reg:X0 Imm:0 | ldrsh w8, [x0]", "may_load"),
  (
    0x79c34900U, "LDRSHWui Reg:W0 Reg:X8 Imm:210 | ldrsh w0, [x8, #420]", "may_load",
  ),
  (0x7a1d0010U, "SBCSWr Reg:W16 Reg:W0 Reg:W29 | sbcs w16, w0, w29", ""),
  (0x7a1d03ffU, "SBCSWr Reg:WZR Reg:WZR Reg:W29 | ngcs wzr, w29", ""),
  (0x7a43b804U, "CCMPWi Reg:W0 Imm:3 Imm:4 Imm:11 | ccmp w0, #3, #4, lt", ""),
  (0x7a480000U, "CCMPWr Reg:W0 Reg:W8 Imm:0 Imm:0 | ccmp w0, w8, #0, eq", ""),
  (
    0x880b7c2aU, "STXRW Reg:W11 Reg:W10 Reg:X1 | stxr w11, w10, [x1]", "may_load,may_store",
  ),
  (
    0x880bfc2aU, "STLXRW Reg:W11 Reg:W10 Reg:X1 | stlxr w11, w10, [x1]", "may_load,may_store",
  ),
  (
    0x88220b18U, "STXPW Reg:W2 Reg:W24 Reg:W2 Reg:X24 | stxp w2, w24, w2, [x24]",
    "may_load,may_store",
  ),
  (
    0x883cf31fU, "STLXPW Reg:W28 Reg:WZR Reg:W28 Reg:X24 | stlxp w28, wzr, w28, [x24]",
    "may_load,may_store",
  ),
  (0x885f7c2aU, "LDXRW Reg:W10 Reg:X1 | ldxr w10, [x1]", "may_load,may_store"),
  (0x885ffd69U, "LDAXRW Reg:W9 Reg:X11 | ldaxr w9, [x11]", "may_load,may_store"),
  (
    0x8865791fU, "LDXPW Reg:WZR Reg:W30 Reg:X8 | ldxp wzr, w30, [x8]", "may_load,may_store",
  ),
  (
    0x8872ca55U, "LDAXPW Reg:W21 Reg:W18 Reg:X18 | ldaxp w21, w18, [x18]", "may_load,may_store",
  ),
  (0x88930261U, "STLLRW Reg:W1 Reg:X19 | stllr w1, [x19]", "may_store"),
  (0x889ffc2aU, "STLRW Reg:W10 Reg:X1 | stlr w10, [x1]", "may_store"),
  (
    0x88a97ea4U, "CASW Reg:W9 Reg:W9 Reg:W4 Reg:X21 | cas w9, w4, [x21]", "may_load,may_store",
  ),
  (
    0x88aeffffU, "CASLW Reg:W14 Reg:W14 Reg:WZR Reg:SP | casl w14, wzr, [sp]", "may_load,may_store",
  ),
  (0x88ce44e7U, "LDLARW Reg:W7 Reg:X7 | ldlar w7, [x7]", "may_load"),
  (0x88dffc2aU, "LDARW Reg:W10 Reg:X1 | ldar w10, [x1]", "may_load"),
  (
    0x88ff7d00U, "CASAW Reg:WZR Reg:WZR Reg:W0 Reg:X8 | casa wzr, w0, [x8]", "may_load,may_store",
  ),
  (
    0x88ffff1fU, "CASALW Reg:WZR Reg:WZR Reg:WZR Reg:X24 | casal wzr, wzr, [x24]",
    "may_load,may_store",
  ),
  (
    0x8a40358cU, "ANDXrs Reg:X12 Reg:X12 Reg:X0 Imm:77 | and x12, x12, x0, lsr #13",
    "",
  ),
  (
    0x8aa0fc00U, "BICXrs Reg:X0 Reg:X0 Reg:X0 Imm:191 | bic x0, x0, x0, asr #63",
    "",
  ),
  (0x8b080128U, "ADDXrs Reg:X8 Reg:X9 Reg:X8 Imm:0 | add x8, x9, x8", ""),
  (
    0x8b20ec1fU, "ADDXrx64 Reg:SP Reg:X0 Reg:X0 Imm:59 | add sp, x0, x0, sxtx #3",
    "",
  ),
  (
    0x8b21454cU, "ADDXrx Reg:X12 Reg:X10 Reg:W1 Imm:17 | add x12, x10, w1, uxtw #1",
    "",
  ),
  (
    0x8b226762U, "ADDXrx64 Reg:X2 Reg:X27 Reg:X2 Imm:25 | add x2, x27, x2, uxtx #1",
    "",
  ),
  (
    0x8b22c189U, "ADDXrx Reg:X9 Reg:X12 Reg:W2 Imm:48 | add x9, x12, w2, sxtw", "",
  ),
  (
    0x8b276affU, "ADDXrx64 Reg:SP Reg:X23 Reg:X7 Imm:26 | add sp, x23, x7, lsl #2",
    "",
  ),
  (
    0x8b292d00U, "ADDXrx Reg:X0 Reg:X8 Reg:W9 Imm:11 | add x0, x8, w9, uxth #3",
    "",
  ),
  (
    0x8b29a156U, "ADDXrx Reg:X22 Reg:X10 Reg:W9 Imm:40 | add x22, x10, w9, sxth",
    "",
  ),
  (
    0x8b2a800bU, "ADDXrx Reg:X11 Reg:X0 Reg:W10 Imm:32 | add x11, x0, w10, sxtb",
    "",
  ),
  (
    0x8b390908U, "ADDXrx Reg:X8 Reg:X8 Reg:W25 Imm:2 | add x8, x8, w25, uxtb #2",
    "",
  ),
  (0x9000000bU, "ADRP Reg:X11 Imm:0 | adrp x11, #0", ""),
  (0x910003fdU, "ADDXri Reg:FP Reg:SP Imm:0 Imm:0 | mov x29, sp", ""),
  (0x91000529U, "ADDXri Reg:X9 Reg:X9 Imm:1 Imm:0 | add x9, x9, #1", ""),
  (0x9240094dU, "ANDXri Reg:X13 Reg:X10 Imm:4098 | and x13, x10, #0x7", ""),
  (0x92800003U, "MOVNXi Reg:X3 Imm:0 Imm:0 | mov x3, #-1", ""),
  (0x92a0001fU, "MOVNXi Reg:XZR Imm:0 Imm:16 | movn xzr, #0, lsl #16", ""),
  (0x93401d00U, "SBFMXri Reg:X0 Reg:X8 Imm:0 Imm:7 | sxtb x0, w8", ""),
  (0x93403d08U, "SBFMXri Reg:X8 Reg:X8 Imm:0 Imm:15 | sxth x8, w8", ""),
  (0x93407c0bU, "SBFMXri Reg:X11 Reg:X0 Imm:0 Imm:31 | sxtw x11, w0", ""),
  (0x93437d01U, "SBFMXri Reg:X1 Reg:X8 Imm:3 Imm:31 | sbfx x1, x8, #3, #29", ""),
  (
    0x937d7c00U, "SBFMXri Reg:X0 Reg:X0 Imm:61 Imm:31 | sbfiz x0, x0, #3, #32", "",
  ),
  (0x937ffd28U, "SBFMXri Reg:X8 Reg:X9 Imm:63 Imm:63 | asr x8, x9, #63", ""),
  (0x93c80908U, "EXTRXrri Reg:X8 Reg:X8 Reg:X8 Imm:2 | ror x8, x8, #2", ""),
  (
    0x93d7fc09U, "EXTRXrri Reg:X9 Reg:X0 Reg:X23 Imm:63 | extr x9, x0, x23, #63",
    "",
  ),
  (0x94000000U, "BL Imm:0 | bl #0", "call,affect_cf"),
  (0x98194407U, "LDRSWl Reg:X7 Imm:51744 | ldrsw x7, #206976", "may_load"),
  (0x9a090149U, "ADCXr Reg:X9 Reg:X10 Reg:X9 | adc x9, x10, x9", ""),
  (0x9a890108U, "CSELXr Reg:X8 Reg:X8 Reg:X9 Imm:0 | csel x8, x8, x9, eq", ""),
  (0x9a890528U, "CSINCXr Reg:X8 Reg:X9 Reg:X9 Imm:0 | cinc x8, x9, ne", ""),
  (
    0x9a9f0500U, "CSINCXr Reg:X0 Reg:X8 Reg:XZR Imm:0 | csinc x0, x8, xzr, eq", "",
  ),
  (0x9ac14fefU, "CRC32Xrr Reg:W15 Reg:WZR Reg:X1 | crc32x w15, wzr, x1", ""),
  (0x9ac80809U, "UDIVXr Reg:X9 Reg:X0 Reg:X8 | udiv x9, x0, x8", ""),
  (0x9ac85d58U, "CRC32CXrr Reg:W24 Reg:W10 Reg:X8 | crc32cx w24, w10, x8", ""),
  (0x9ac92101U, "LSLVXr Reg:X1 Reg:X8 Reg:X9 | lsl x1, x8, x9", ""),
  (0x9ac92508U, "LSRVXr Reg:X8 Reg:X8 Reg:X9 | lsr x8, x8, x9", ""),
  (0x9ac92d00U, "RORVXr Reg:X0 Reg:X8 Reg:X9 | ror x0, x8, x9", ""),
  (0x9aca0c0bU, "SDIVXr Reg:X11 Reg:X0 Reg:X10 | sdiv x11, x0, x10", ""),
  (0x9ad42808U, "ASRVXr Reg:X8 Reg:X0 Reg:X20 | asr x8, x0, x20", ""),
  (0x9ad631e9U, "PACGA Reg:X9 Reg:X15 Reg:X22 | pacga x9, x15, x22", ""),
  (0x9b007c2cU, "MADDXrrr Reg:X12 Reg:X1 Reg:X0 Reg:XZR | mul x12, x1, x0", ""),
  (
    0x9b088128U, "MSUBXrrr Reg:X8 Reg:X9 Reg:X8 Reg:X0 | msub x8, x9, x8, x0", "",
  ),
  (0x9b08fc09U, "MSUBXrrr Reg:X9 Reg:X0 Reg:X8 Reg:XZR | mneg x9, x0, x8", ""),
  (
    0x9b0d2500U, "MADDXrrr Reg:X0 Reg:X8 Reg:X13 Reg:X9 | madd x0, x8, x13, x9",
    "",
  ),
  (0x9b287c28U, "SMADDLrrr Reg:X8 Reg:W1 Reg:W8 Reg:XZR | smull x8, w1, w8", ""),
  (
    0x9b28d121U, "SMSUBLrrr Reg:X1 Reg:W9 Reg:W8 Reg:X20 | smsubl x1, w9, w8, x20",
    "",
  ),
  (
    0x9b30ffdeU, "SMSUBLrrr Reg:LR Reg:W30 Reg:W16 Reg:XZR | smnegl x30, w30, w16",
    "",
  ),
  (
    0x9b3b0500U, "SMADDLrrr Reg:X0 Reg:W8 Reg:W27 Reg:X1 | smaddl x0, w8, w27, x1",
    "",
  ),
  (0x9b407c21U, "SMULHrr Reg:X1 Reg:X1 Reg:X0 | smulh x1, x1, x0", ""),
  (
    0x9ba92000U, "UMADDLrrr Reg:X0 Reg:W0 Reg:W9 Reg:X8 | umaddl x0, w0, w9, x8",
    "",
  ),
  (0x9ba97c49U, "UMADDLrrr Reg:X9 Reg:W2 Reg:W9 Reg:XZR | umull x9, w2, w9", ""),
  (
    0x9babfff4U, "UMSUBLrrr Reg:X20 Reg:WZR Reg:W11 Reg:XZR | umnegl x20, wzr, w11",
    "",
  ),
  (
    0x9bada96aU, "UMSUBLrrr Reg:X10 Reg:W11 Reg:W13 Reg:X10 | umsubl x10, w11, w13, x10",
    "",
  ),
  (0x9bc07c21U, "UMULHrr Reg:X1 Reg:X1 Reg:X0 | umulh x1, x1, x0", ""),
  (
    0xa800733fU, "STNPXi Reg:XZR Reg:X28 Reg:X25 Imm:0 | stnp xzr, x28, [x25]", "may_store",
  ),
  (
    0xa81ffddfU, "STNPXi Reg:XZR Reg:XZR Reg:X14 Imm:63 | stnp xzr, xzr, [x14, #504]",
    "may_store",
  ),
  (
    0xa8407c0dU, "LDNPXi Reg:X13 Reg:XZR Reg:X0 Imm:0 | ldnp x13, xzr, [x0]", "may_load",
  ),
  (
    0xa85ffea5U, "LDNPXi Reg:X5 Reg:XZR Reg:X21 Imm:63 | ldnp x5, xzr, [x21, #504]",
    "may_load",
  ),
  (
    0xa8812408U, "STPXpost Reg:X0 Reg:X8 Reg:X9 Reg:X0 Imm:2 | stp x8, x9, [x0], #16",
    "may_store",
  ),
  (
    0xa8c17bfdU, "LDPXpost Reg:SP Reg:FP Reg:LR Reg:SP Imm:2 | ldp x29, x30, [sp], #16",
    "may_load",
  ),
  (
    0xa90053e8U, "STPXi Reg:X8 Reg:X20 Reg:SP Imm:0 | stp x8, x20, [sp]", "may_store",
  ),
  (
    0xa9024ff4U, "STPXi Reg:X20 Reg:X19 Reg:SP Imm:4 | stp x20, x19, [sp, #32]",
    "may_store",
  ),
  (
    0xa9400500U, "LDPXi Reg:X0 Reg:X1 Reg:X8 Imm:0 | ldp x0, x1, [x8]", "may_load",
  ),
  (
    0xa9424ff4U, "LDPXi Reg:X20 Reg:X19 Reg:SP Imm:4 | ldp x20, x19, [sp, #32]",
    "may_load",
  ),
  (
    0xa9bf7bfdU, "STPXpre Reg:SP Reg:FP Reg:LR Reg:SP Imm:-2 | stp x29, x30, [sp, #-16]!",
    "may_store",
  ),
  (
    0xa9c72909U, "LDPXpre Reg:X8 Reg:X9 Reg:X10 Reg:X8 Imm:14 | ldp x9, x10, [x8, #112]!",
    "may_load",
  ),
  (0xaa0003e8U, "ORRXrs Reg:X8 Reg:XZR Reg:X0 Imm:0 | mov x8, x0", ""),
  (0xaa0c0108U, "ORRXrs Reg:X8 Reg:X8 Reg:X12 Imm:0 | orr x8, x8, x12", ""),
  (0xaa2c012cU, "ORNXrs Reg:X12 Reg:X9 Reg:X12 Imm:0 | orn x12, x9, x12", ""),
  (0xaa3a03e0U, "ORNXrs Reg:X0 Reg:XZR Reg:X26 Imm:0 | mvn x0, x26", ""),
  (0xab01011fU, "ADDSXrs Reg:XZR Reg:X8 Reg:X1 Imm:0 | cmn x8, x1", ""),
  (0xab090100U, "ADDSXrs Reg:X0 Reg:X8 Reg:X9 Imm:0 | adds x0, x8, x9", ""),
  (0xab21003fU, "ADDSXrx Reg:XZR Reg:X1 Reg:W1 Imm:0 | cmn x1, w1, uxtb", ""),
  (
    0xab23b01fU, "ADDSXrx Reg:XZR Reg:X0 Reg:W3 Imm:44 | cmn x0, w3, sxth #4", "",
  ),
  (
    0xab2422afU, "ADDSXrx Reg:X15 Reg:X21 Reg:W4 Imm:8 | adds x15, x21, w4, uxth",
    "",
  ),
  (
    0xab278155U, "ADDSXrx Reg:X21 Reg:X10 Reg:W7 Imm:32 | adds x21, x10, w7, sxtb",
    "",
  ),
  (
    0xab278effU, "ADDSXrx Reg:XZR Reg:X23 Reg:W7 Imm:35 | cmn x23, w7, sxtb #3",
    "",
  ),
  (
    0xab27d17fU, "ADDSXrx Reg:XZR Reg:X11 Reg:W7 Imm:52 | cmn x11, w7, sxtw #4",
    "",
  ),
  (
    0xab2803f9U, "ADDSXrx Reg:X25 Reg:SP Reg:W8 Imm:0 | adds x25, sp, w8, uxtb",
    "",
  ),
  (
    0xab2a287fU, "ADDSXrx Reg:XZR Reg:X3 Reg:W10 Imm:10 | cmn x3, w10, uxth #2",
    "",
  ),
  (
    0xab314635U, "ADDSXrx Reg:X21 Reg:X17 Reg:W17 Imm:17 | adds x21, x17, w17, uxtw #1",
    "",
  ),
  (
    0xab35c015U, "ADDSXrx Reg:X21 Reg:X0 Reg:W21 Imm:48 | adds x21, x0, w21, sxtw",
    "",
  ),
  (
    0xab376bf7U, "ADDSXrx64 Reg:X23 Reg:SP Reg:X23 Imm:26 | adds x23, sp, x23, lsl #2",
    "",
  ),
  (
    0xab37e11fU, "ADDSXrx64 Reg:XZR Reg:X8 Reg:X23 Imm:56 | cmn x8, x23, sxtx", "",
  ),
  (
    0xab3bec13U, "ADDSXrx64 Reg:X19 Reg:X0 Reg:X27 Imm:59 | adds x19, x0, x27, sxtx #3",
    "",
  ),
  (
    0xab3d67ffU, "ADDSXrx64 Reg:XZR Reg:SP Reg:FP Imm:25 | cmn sp, x29, lsl #1",
    "",
  ),
  (
    0xab3f64e1U, "ADDSXrx64 Reg:X1 Reg:X7 Reg:XZR Imm:25 | adds x1, x7, xzr, uxtx #1",
    "",
  ),
  (
    0xab3fb3ecU, "ADDSXrx Reg:X12 Reg:SP Reg:WZR Imm:44 | adds x12, sp, wzr, sxth #4",
    "",
  ),
  (0xb100214aU, "ADDSXri Reg:X10 Reg:X10 Imm:8 Imm:0 | adds x10, x10, #8", ""),
  (0xb102011fU, "ADDSXri Reg:XZR Reg:X8 Imm:128 Imm:0 | cmn x8, #128", ""),
  (0xb2400428U, "ORRXri Reg:X8 Reg:X1 Imm:4097 | orr x8, x1, #0x3", ""),
  (0xb27f77e9U, "ORRXri Reg:X9 Reg:XZR Imm:8157 | mov x9, #2147483646", ""),
  (
    0xb3400949U, "BFMXri Reg:X9 Reg:X9 Reg:X10 Imm:0 Imm:2 | bfxil x9, x10, #0, #3",
    "",
  ),
  (
    0xb35f03f2U, "BFMXri Reg:X18 Reg:X18 Reg:XZR Imm:31 Imm:0 | bfc x18, #33, #1",
    "",
  ),
  (
    0xb371818bU, "BFMXri Reg:X11 Reg:X11 Reg:X12 Imm:49 Imm:32 | bfi x11, x12, #15, #33",
    "",
  ),
  (0xb4000261U, "CBZX Reg:X1 Imm:19 | cbz x1, #76", "cond,terminator,affect_cf"),
  (
    0xb5fffe6dU, "CBNZX Reg:X13 Imm:-13 | cbnz x13, #-52", "cond,terminator,affect_cf",
  ),
  (
    0xb6f80248U, "TBZX Reg:X8 Imm:63 Imm:18 | tbz x8, #63, #72", "cond,terminator,affect_cf",
  ),
  (
    0xb7fff700U, "TBNZX Reg:X0 Imm:63 Imm:-72 | tbnz x0, #63, #-288", "cond,terminator,affect_cf",
  ),
  (0xb8000000U, "STURWi Reg:W0 Reg:X0 Imm:0 | stur w0, [x0]", "may_store"),
  (
    0xb8004500U, "STRWpost Reg:X8 Reg:W0 Reg:X8 Imm:4 | str w0, [x8], #4", "may_store",
  ),
  (
    0xb8004f00U, "STRWpre Reg:X24 Reg:W0 Reg:X24 Imm:4 | str w0, [x24, #4]!", "may_store",
  ),
  (
    0xb816db3fU, "STTRWi Reg:WZR Reg:X25 Imm:-147 | sttr wzr, [x25, #-147]", "may_store",
  ),
  (
    0xb81fc3a8U, "STURWi Reg:W8 Reg:FP Imm:-4 | stur w8, [x29, #-4]", "may_store",
  ),
  (
    0xb820401fU, "LDSMAXW Reg:WZR Reg:W0 Reg:X0 | stsmax w0, [x0]", "may_load,may_store",
  ),
  (
    0xb820537fU, "LDSMINW Reg:WZR Reg:W0 Reg:X27 | stsmin w0, [x27]", "may_load,may_store",
  ),
  (
    0xb820f81fU, "STRWroX Reg:WZR Reg:X0 Reg:X0 Imm:1 Imm:1 | str wzr, [x0, x0, sxtx #2]",
    "may_store",
  ),
  (
    0xb8248084U, "SWPW Reg:W4 Reg:W4 Reg:X4 | swp w4, w4, [x4]", "may_load,may_store",
  ),
  (
    0xb8265286U, "LDSMINW Reg:W6 Reg:W6 Reg:X20 | ldsmin w6, w6, [x20]", "may_load,may_store",
  ),
  (
    0xb82823b6U, "LDEORW Reg:W22 Reg:W8 Reg:FP | ldeor w8, w22, [x29]", "may_load,may_store",
  ),
  (
    0xb8284849U, "STRWroW Reg:W9 Reg:X2 Reg:W8 Imm:0 Imm:0 | str w9, [x2, w8, uxtw]",
    "may_store",
  ),
  (
    0xb8296900U, "STRWroX Reg:W0 Reg:X8 Reg:X9 Imm:0 Imm:0 | str w0, [x8, x9]", "may_store",
  ),
  (
    0xb8297900U, "STRWroX Reg:W0 Reg:X8 Reg:X9 Imm:0 Imm:1 | str w0, [x8, x9, lsl #2]",
    "may_store",
  ),
  (
    0xb829cb48U, "STRWroW Reg:W8 Reg:X26 Reg:W9 Imm:1 Imm:0 | str w8, [x26, w9, sxtw]",
    "may_store",
  ),
  (
    0xb82b102bU, "LDCLRW Reg:W11 Reg:W11 Reg:X1 | ldclr w11, w11, [x1]", "may_load,may_store",
  ),
  (
    0xb82e330dU, "LDSETW Reg:W13 Reg:W14 Reg:X24 | ldset w14, w13, [x24]", "may_load,may_store",
  ),
  (
    0xb82e60bfU, "LDUMAXW Reg:WZR Reg:W14 Reg:X5 | stumax w14, [x5]", "may_load,may_store",
  ),
  (
    0xb8317023U, "LDUMINW Reg:W3 Reg:W17 Reg:X1 | ldumin w17, w3, [x1]", "may_load,may_store",
  ),
  (
    0xb834d900U, "STRWroW Reg:W0 Reg:X8 Reg:W20 Imm:1 Imm:1 | str w0, [x8, w20, sxtw #2]",
    "may_store",
  ),
  (
    0xb83603ffU, "LDADDW Reg:WZR Reg:W22 Reg:SP | stadd w22, [sp]", "may_load,may_store",
  ),
  (
    0xb836eb5dU, "STRWroX Reg:W29 Reg:X26 Reg:X22 Imm:1 Imm:0 | str w29, [x26, x22, sxtx]",
    "may_store",
  ),
  (
    0xb8385900U, "STRWroW Reg:W0 Reg:X8 Reg:W24 Imm:0 Imm:1 | str w0, [x8, w24, uxtw #2]",
    "may_store",
  ),
  (
    0xb839715fU, "LDUMINW Reg:WZR Reg:W25 Reg:X10 | stumin w25, [x10]", "may_load,may_store",
  ),
  (
    0xb83b03e1U, "LDADDW Reg:W1 Reg:W27 Reg:SP | ldadd w27, w1, [sp]", "may_load,may_store",
  ),
  (
    0xb83b404aU, "LDSMAXW Reg:W10 Reg:W27 Reg:X2 | ldsmax w27, w10, [x2]", "may_load,may_store",
  ),
  (
    0xb83c303fU, "LDSETW Reg:WZR Reg:W28 Reg:X1 | stset w28, [x1]", "may_load,may_store",
  ),
  (
    0xb83c6318U, "LDUMAXW Reg:W24 Reg:W28 Reg:X24 | ldumax w28, w24, [x24]", "may_load,may_store",
  ),
  (
    0xb83e107fU, "LDCLRW Reg:WZR Reg:W30 Reg:X3 | stclr w30, [x3]", "may_load,may_store",
  ),
  (
    0xb83f23ffU, "LDEORW Reg:WZR Reg:WZR Reg:SP | steor wzr, [sp]", "may_load,may_store",
  ),
  (0xb84003e0U, "LDURWi Reg:W0 Reg:SP Imm:0 | ldur w0, [sp]", "may_load"),
  (
    0xb8404500U, "LDRWpost Reg:X8 Reg:W0 Reg:X8 Imm:4 | ldr w0, [x8], #4", "may_load",
  ),
  (
    0xb8410c08U, "LDRWpre Reg:X0 Reg:W8 Reg:X0 Imm:16 | ldr w8, [x0, #16]!", "may_load",
  ),
  (
    0xb849ba3fU, "LDTRWi Reg:WZR Reg:X17 Imm:155 | ldtr wzr, [x17, #155]", "may_load",
  ),
  (0xb85fc3a0U, "LDURWi Reg:W0 Reg:FP Imm:-4 | ldur w0, [x29, #-4]", "may_load"),
  (
    0xb8605900U, "LDRWroW Reg:W0 Reg:X8 Reg:W0 Imm:0 Imm:1 | ldr w0, [x8, w0, uxtw #2]",
    "may_load",
  ),
  (
    0xb860d900U, "LDRWroW Reg:W0 Reg:X8 Reg:W0 Imm:1 Imm:1 | ldr w0, [x8, w0, sxtw #2]",
    "may_load",
  ),
  (
    0xb861233fU, "LDEORLW Reg:WZR Reg:W1 Reg:X25 | steorl w1, [x25]", "may_load,may_store",
  ),
  (
    0xb86413d9U, "LDCLRLW Reg:W25 Reg:W4 Reg:LR | ldclrl w4, w25, [x30]", "may_load,may_store",
  ),
  (
    0xb864433fU, "LDSMAXLW Reg:WZR Reg:W4 Reg:X25 | stsmaxl w4, [x25]", "may_load,may_store",
  ),
  (
    0xb86471ffU, "LDUMINLW Reg:WZR Reg:W4 Reg:X15 | stuminl w4, [x15]", "may_load,may_store",
  ),
  (
    0xb86661dcU, "LDUMAXLW Reg:W28 Reg:W6 Reg:X14 | ldumaxl w6, w28, [x14]", "may_load,may_store",
  ),
  (
    0xb86740e7U, "LDSMAXLW Reg:W7 Reg:W7 Reg:X7 | ldsmaxl w7, w7, [x7]", "may_load,may_store",
  ),
  (
    0xb868203aU, "LDEORLW Reg:W26 Reg:W8 Reg:X1 | ldeorl w8, w26, [x1]", "may_load,may_store",
  ),
  (
    0xb8686800U, "LDRWroX Reg:W0 Reg:X0 Reg:X8 Imm:0 Imm:0 | ldr w0, [x0, x8]", "may_load",
  ),
  (
    0xb868e9efU, "LDRWroX Reg:W15 Reg:X15 Reg:X8 Imm:1 Imm:0 | ldr w15, [x15, x8, sxtx]",
    "may_load",
  ),
  (
    0xb8697900U, "LDRWroX Reg:W0 Reg:X8 Reg:X9 Imm:0 Imm:1 | ldr w0, [x8, x9, lsl #2]",
    "may_load",
  ),
  (
    0xb86b302bU, "LDSETLW Reg:W11 Reg:W11 Reg:X1 | ldsetl w11, w11, [x1]", "may_load,may_store",
  ),
  (
    0xb86b48e8U, "LDRWroW Reg:W8 Reg:X7 Reg:W11 Imm:0 Imm:0 | ldr w8, [x7, w11, uxtw]",
    "may_load",
  ),
  (
    0xb873121fU, "LDCLRLW Reg:WZR Reg:W19 Reg:X16 | stclrl w19, [x16]", "may_load,may_store",
  ),
  (
    0xb87603ecU, "LDADDLW Reg:W12 Reg:W22 Reg:SP | ldaddl w22, w12, [sp]", "may_load,may_store",
  ),
  (
    0xb87661ffU, "LDUMAXLW Reg:WZR Reg:W22 Reg:X15 | stumaxl w22, [x15]", "may_load,may_store",
  ),
  (
    0xb8787385U, "LDUMINLW Reg:W5 Reg:W24 Reg:X28 | lduminl w24, w5, [x28]", "may_load,may_store",
  ),
  (
    0xb87c501fU, "LDSMINLW Reg:WZR Reg:W28 Reg:X0 | stsminl w28, [x0]", "may_load,may_store",
  ),
  (
    0xb87df9beU, "LDRWroX Reg:W30 Reg:X13 Reg:FP Imm:1 Imm:1 | ldr w30, [x13, x29, sxtx #2]",
    "may_load",
  ),
  (
    0xb87f009fU, "LDADDLW Reg:WZR Reg:WZR Reg:X4 | staddl wzr, [x4]", "may_load,may_store",
  ),
  (
    0xb87f309fU, "LDSETLW Reg:WZR Reg:WZR Reg:X4 | stsetl wzr, [x4]", "may_load,may_store",
  ),
  (
    0xb87f51ceU, "LDSMINLW Reg:W14 Reg:WZR Reg:X14 | ldsminl wzr, w14, [x14]", "may_load,may_store",
  ),
  (
    0xb87f83ffU, "SWPLW Reg:WZR Reg:WZR Reg:SP | swpl wzr, wzr, [sp]", "may_load,may_store",
  ),
  (
    0xb87fcbffU, "LDRWroW Reg:WZR Reg:SP Reg:WZR Imm:1 Imm:0 | ldr wzr, [sp, wzr, sxtw]",
    "may_load",
  ),
  (0xb8800240U, "LDURSWi Reg:X0 Reg:X18 Imm:0 | ldursw x0, [x18]", "may_load"),
  (
    0xb8804bffU, "LDTRSWi Reg:XZR Reg:SP Imm:4 | ldtrsw xzr, [sp, #4]", "may_load",
  ),
  (
    0xb8804d2aU, "LDRSWpre Reg:X9 Reg:X10 Reg:X9 Imm:4 | ldrsw x10, [x9, #4]!", "may_load",
  ),
  (
    0xb89d43a2U, "LDURSWi Reg:X2 Reg:FP Imm:-44 | ldursw x2, [x29, #-44]", "may_load",
  ),
  (
    0xb89fc602U, "LDRSWpost Reg:X16 Reg:X2 Reg:X16 Imm:-4 | ldrsw x2, [x16], #-4",
    "may_load",
  ),
  (
    0xb8a003fbU, "LDADDAW Reg:W27 Reg:W0 Reg:SP | ldadda w0, w27, [sp]", "may_load,may_store",
  ),
  (
    0xb8a01045U, "LDCLRAW Reg:W5 Reg:W0 Reg:X2 | ldclra w0, w5, [x2]", "may_load,may_store",
  ),
  (
    0xb8a1001fU, "LDADDAW Reg:WZR Reg:W1 Reg:X0 | ldadda w1, wzr, [x0] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8a2605fU, "LDUMAXAW Reg:WZR Reg:W2 Reg:X2 | ldumaxa w2, wzr, [x2] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8a270ffU, "LDUMINAW Reg:WZR Reg:W2 Reg:X7 | ldumina w2, wzr, [x7] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8a343eeU, "LDSMAXAW Reg:W14 Reg:W3 Reg:SP | ldsmaxa w3, w14, [sp]", "may_load,may_store",
  ),
  (
    0xb8a4109fU, "LDCLRAW Reg:WZR Reg:W4 Reg:X4 | ldclra w4, wzr, [x4] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8a5529dU, "LDSMINAW Reg:W29 Reg:W5 Reg:X20 | ldsmina w5, w29, [x20]", "may_load,may_store",
  ),
  (
    0xb8a6832eU, "SWPAW Reg:W14 Reg:W6 Reg:X25 | swpa w6, w14, [x25]", "may_load,may_store",
  ),
  (
    0xb8a732b8U, "LDSETAW Reg:W24 Reg:W7 Reg:X21 | ldseta w7, w24, [x21]", "may_load,may_store",
  ),
  (
    0xb8aed902U, "LDRSWroW Reg:X2 Reg:X8 Reg:W14 Imm:1 Imm:1 | ldrsw x2, [x8, w14, sxtw #2]",
    "may_load",
  ),
  (
    0xb8af727dU, "LDUMINAW Reg:W29 Reg:W15 Reg:X19 | ldumina w15, w29, [x19]", "may_load,may_store",
  ),
  (
    0xb8af801fU, "SWPAW Reg:WZR Reg:W15 Reg:X0 | swpa w15, wzr, [x0] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8b2201fU, "LDEORAW Reg:WZR Reg:W18 Reg:X0 | ldeora w18, wzr, [x0] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8b531bfU, "LDSETAW Reg:WZR Reg:W21 Reg:X13 | ldseta w21, wzr, [x13] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8b5cb74U, "LDRSWroW Reg:X20 Reg:X27 Reg:W21 Imm:1 Imm:0 | ldrsw x20, [x27, w21, sxtw]",
    "may_load",
  ),
  (
    0xb8ba491bU, "LDRSWroW Reg:X27 Reg:X8 Reg:W26 Imm:0 Imm:0 | ldrsw x27, [x8, w26, uxtw]",
    "may_load",
  ),
  (
    0xb8ba51bfU, "LDSMINAW Reg:WZR Reg:W26 Reg:X13 | ldsmina w26, wzr, [x13] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8ba6909U, "LDRSWroX Reg:X9 Reg:X8 Reg:X26 Imm:0 Imm:0 | ldrsw x9, [x8, x26]",
    "may_load",
  ),
  (
    0xb8bae848U, "LDRSWroX Reg:X8 Reg:X2 Reg:X26 Imm:1 Imm:0 | ldrsw x8, [x2, x26, sxtx]",
    "may_load",
  ),
  (
    0xb8bb5808U, "LDRSWroW Reg:X8 Reg:X0 Reg:W27 Imm:0 Imm:1 | ldrsw x8, [x0, w27, uxtw #2]",
    "may_load",
  ),
  (
    0xb8bc7901U, "LDRSWroX Reg:X1 Reg:X8 Reg:X28 Imm:0 Imm:1 | ldrsw x1, [x8, x28, lsl #2]",
    "may_load",
  ),
  (
    0xb8bd200cU, "LDEORAW Reg:W12 Reg:W29 Reg:X0 | ldeora w29, w12, [x0]", "may_load,may_store",
  ),
  (
    0xb8bf43ffU, "LDSMAXAW Reg:WZR Reg:WZR Reg:SP | ldsmaxa wzr, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8bf63eeU, "LDUMAXAW Reg:W14 Reg:WZR Reg:SP | ldumaxa wzr, w14, [sp]", "may_load,may_store",
  ),
  (0xb8bfc029U, "LDAPRW Reg:W9 Reg:X1 | ldapr w9, [x1]", "may_load"),
  (
    0xb8bffbeeU, "LDRSWroX Reg:X14 Reg:SP Reg:XZR Imm:1 Imm:1 | ldrsw x14, [sp, xzr, sxtx #2]",
    "may_load",
  ),
  (
    0xb8e012dfU, "LDCLRALW Reg:WZR Reg:W0 Reg:X22 | ldclral w0, wzr, [x22] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8e22112U, "LDEORALW Reg:W18 Reg:W2 Reg:X8 | ldeoral w2, w18, [x8]", "may_load,may_store",
  ),
  (
    0xb8e2823fU, "SWPALW Reg:WZR Reg:W2 Reg:X17 | swpal w2, wzr, [x17] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8e341dfU, "LDSMAXALW Reg:WZR Reg:W3 Reg:X14 | ldsmaxal w3, wzr, [x14] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8e453bfU, "LDSMINALW Reg:WZR Reg:W4 Reg:FP | ldsminal w4, wzr, [x29] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8e5801cU, "SWPALW Reg:W28 Reg:W5 Reg:X0 | swpal w5, w28, [x0]", "may_load,may_store",
  ),
  (
    0xb8e612dcU, "LDCLRALW Reg:W28 Reg:W6 Reg:X22 | ldclral w6, w28, [x22]", "may_load,may_store",
  ),
  (
    0xb8e7319dU, "LDSETALW Reg:W29 Reg:W7 Reg:X12 | ldsetal w7, w29, [x12]", "may_load,may_store",
  ),
  (
    0xb8ec23dfU, "LDEORALW Reg:WZR Reg:W12 Reg:LR | ldeoral w12, wzr, [x30] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8ed31ffU, "LDSETALW Reg:WZR Reg:W13 Reg:X15 | ldsetal w13, wzr, [x15] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8ed721cU, "LDUMINALW Reg:W28 Reg:W13 Reg:X16 | lduminal w13, w28, [x16]",
    "may_load,may_store",
  ),
  (
    0xb8ee51e3U, "LDSMINALW Reg:W3 Reg:W14 Reg:X15 | ldsminal w14, w3, [x15]", "may_load,may_store",
  ),
  (
    0xb8ee60c5U, "LDUMAXALW Reg:W5 Reg:W14 Reg:X6 | ldumaxal w14, w5, [x6]", "may_load,may_store",
  ),
  (
    0xb8f361dfU, "LDUMAXALW Reg:WZR Reg:W19 Reg:X14 | ldumaxal w19, wzr, [x14] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8f3731fU, "LDUMINALW Reg:WZR Reg:W19 Reg:X24 | lduminal w19, wzr, [x24] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8f603ffU, "LDADDALW Reg:WZR Reg:W22 Reg:SP | ldaddal w22, wzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xb8ff0020U, "LDADDALW Reg:W0 Reg:WZR Reg:X1 | ldaddal wzr, w0, [x1]", "may_load,may_store",
  ),
  (
    0xb8ff421aU, "LDSMAXALW Reg:W26 Reg:WZR Reg:X16 | ldsmaxal wzr, w26, [x16]",
    "may_load,may_store",
  ),
  (0xb90003e8U, "STRWui Reg:W8 Reg:SP Imm:0 | str w8, [sp]", "may_store"),
  (0xb9001fe2U, "STRWui Reg:W2 Reg:SP Imm:7 | str w2, [sp, #28]", "may_store"),
  (0xb94003e8U, "LDRWui Reg:W8 Reg:SP Imm:0 | ldr w8, [sp]", "may_load"),
  (0xb9401be8U, "LDRWui Reg:W8 Reg:SP Imm:6 | ldr w8, [sp, #24]", "may_load"),
  (0xb9800000U, "LDRSWui Reg:X0 Reg:X0 Imm:0 | ldrsw x0, [x0]", "may_load"),
  (0xb9801fe9U, "LDRSWui Reg:X9 Reg:SP Imm:7 | ldrsw x9, [sp, #28]", "may_load"),
  (0xba000129U, "ADCSXr Reg:X9 Reg:X9 Reg:X0 | adcs x9, x9, x0", ""),
  (0xba410800U, "CCMNXi Reg:X0 Imm:1 Imm:0 Imm:0 | ccmn x0, #1, #0, eq", ""),
  (0xba41f285U, "CCMNXr Reg:X20 Reg:X1 Imm:5 Imm:15 | ccmn x20, x1, #5, nv", ""),
  (
    0xc80afc08U, "STLXRX Reg:W10 Reg:X8 Reg:X0 | stlxr w10, x8, [x0]", "may_load,may_store",
  ),
  (
    0xc80b7c08U, "STXRX Reg:W11 Reg:X8 Reg:X0 | stxr w11, x8, [x0]", "may_load,may_store",
  ),
  (
    0xc839189fU, "STXPX Reg:W25 Reg:XZR Reg:X6 Reg:X4 | stxp w25, xzr, x6, [x4]",
    "may_load,may_store",
  ),
  (
    0xc83ffa5fU, "STLXPX Reg:WZR Reg:XZR Reg:LR Reg:X18 | stlxp wzr, xzr, x30, [x18]",
    "may_load,may_store",
  ),
  (0xc85201b2U, "LDXRX Reg:X18 Reg:X13 | ldxr x18, [x13]", "may_load,may_store"),
  (0xc85ffc09U, "LDAXRX Reg:X9 Reg:X0 | ldaxr x9, [x0]", "may_load,may_store"),
  (
    0xc8615ad6U, "LDXPX Reg:X22 Reg:X22 Reg:X22 | ldxp x22, x22, [x22]", "may_load,may_store",
  ),
  (
    0xc87fe407U, "LDAXPX Reg:X7 Reg:X25 Reg:X0 | ldaxp x7, x25, [x0]", "may_load,may_store",
  ),
  (0xc894ffefU, "STLRX Reg:X15 Reg:SP | stlr x15, [sp]", "may_store"),
  (0xc89f037fU, "STLLRX Reg:XZR Reg:X27 | stllr xzr, [x27]", "may_store"),
  (
    0xc8bf7fffU, "CASX Reg:XZR Reg:XZR Reg:XZR Reg:SP | cas xzr, xzr, [sp]", "may_load,may_store",
  ),
  (
    0xc8bffc09U, "CASLX Reg:XZR Reg:XZR Reg:X9 Reg:X0 | casl xzr, x9, [x0]", "may_load,may_store",
  ),
  (0xc8c07ff5U, "LDLARX Reg:X21 Reg:SP | ldlar x21, [sp]", "may_load"),
  (0xc8c0e41fU, "LDARX Reg:XZR Reg:X0 | ldar xzr, [x0]", "may_load"),
  (
    0xc8eafc02U, "CASALX Reg:X10 Reg:X10 Reg:X2 Reg:X0 | casal x10, x2, [x0]", "may_load,may_store",
  ),
  (
    0xc8ff7c8cU, "CASAX Reg:XZR Reg:XZR Reg:X12 Reg:X4 | casa xzr, x12, [x4]", "may_load,may_store",
  ),
  (
    0xca0c1d29U, "EORXrs Reg:X9 Reg:X9 Reg:X12 Imm:7 | eor x9, x9, x12, lsl #7",
    "",
  ),
  (
    0xca26c002U, "EONXrs Reg:X2 Reg:X0 Reg:X6 Imm:48 | eon x2, x0, x6, lsl #48",
    "",
  ),
  (0xcb0003e0U, "SUBXrs Reg:X0 Reg:XZR Reg:X0 Imm:0 | neg x0, x0", ""),
  (0xcb0b0129U, "SUBXrs Reg:X9 Reg:X9 Reg:X11 Imm:0 | sub x9, x9, x11", ""),
  (0xcb204100U, "SUBXrx Reg:X0 Reg:X8 Reg:W0 Imm:16 | sub x0, x8, w0, uxtw", ""),
  (
    0xcb20643fU, "SUBXrx64 Reg:SP Reg:X1 Reg:X0 Imm:25 | sub sp, x1, x0, lsl #1",
    "",
  ),
  (0xcb20c100U, "SUBXrx Reg:X0 Reg:X8 Reg:W0 Imm:48 | sub x0, x8, w0, sxtw", ""),
  (
    0xcb2227e2U, "SUBXrx Reg:X2 Reg:SP Reg:W2 Imm:9 | sub x2, sp, w2, uxth #1", "",
  ),
  (
    0xcb2c03e0U, "SUBXrx Reg:X0 Reg:SP Reg:W12 Imm:0 | sub x0, sp, w12, uxtb", "",
  ),
  (
    0xcb30630fU, "SUBXrx64 Reg:X15 Reg:X24 Reg:X16 Imm:24 | sub x15, x24, x16, uxtx",
    "",
  ),
  (0xcb3f63e4U, "SUBXrx64 Reg:X4 Reg:SP Reg:XZR Imm:24 | sub x4, sp, xzr", ""),
  (
    0xcb3f82dcU, "SUBXrx Reg:X28 Reg:X22 Reg:WZR Imm:32 | sub x28, x22, wzr, sxtb",
    "",
  ),
  (
    0xcb3fad64U, "SUBXrx Reg:X4 Reg:X11 Reg:WZR Imm:43 | sub x4, x11, wzr, sxth #3",
    "",
  ),
  (
    0xcb3fe3f6U, "SUBXrx64 Reg:X22 Reg:SP Reg:XZR Imm:56 | sub x22, sp, xzr, sxtx",
    "",
  ),
  (0xd100042aU, "SUBXri Reg:X10 Reg:X1 Imm:1 Imm:0 | sub x10, x1, #1", ""),
  (0xd2400102U, "EORXri Reg:X2 Reg:X8 Imm:4096 | eor x2, x8, #0x1", ""),
  (0xd28cf12dU, "MOVZXi Reg:X13 Imm:26505 Imm:0 | mov x13, #26505", ""),
  (0xd2a0001fU, "MOVZXi Reg:XZR Imm:0 Imm:16 | movz xzr, #0, lsl #16", ""),
  (0xd3441101U, "UBFMXri Reg:X1 Reg:X8 Imm:4 Imm:4 | ubfx x1, x8, #4, #1", ""),
  (0xd360fd29U, "UBFMXri Reg:X9 Reg:X9 Imm:32 Imm:63 | lsr x9, x9, #32", ""),
  (0xd371c18fU, "UBFMXri Reg:X15 Reg:X12 Imm:49 Imm:48 | lsl x15, x12, #15", ""),
  (
    0xd37f7c2aU, "UBFMXri Reg:X10 Reg:X1 Imm:63 Imm:31 | ubfiz x10, x1, #1, #32",
    "",
  ),
  (0xd41a0003U, "SMC Imm:53248 | smc #0xd000", ""),
  (0xd41f03e2U, "HVC Imm:63519 | hvc #0xf81f", ""),
  (0xd41ffd21U, "SVC Imm:65513 | svc #0xffe9", ""),
  (0xd4200020U, "BRK Imm:1 | brk #0x1", ""),
  (0xd4408240U, "HLT Imm:1042 | hlt #0x412", ""),
  (0xd4a003e3U, "DCPS3 Imm:31 | dcps3 #0x1f", ""),
  (0xd4a01781U, "DCPS1 Imm:188 | dcps1 #0xbc", ""),
  (0xd4a23042U, "DCPS2 Imm:4482 | dcps2 #0x1182", ""),
  (0xd5004c9fU, "MSRpstateImm4 Imm:4 Imm:12 | msr PAN, #12", ""),
  (0xd501421fU, "MSRpstateImm1 Imm:72 Imm:0 | msr PM, #0", ""),
  (0xd503201fU, "NOP | nop", ""),
  (0xd503203fU, "HINT Imm:1 | yield", "may_load,may_store"),
  (0xd503205fU, "HINT Imm:2 | wfe", "may_load,may_store"),
  (0xd503207fU, "HINT Imm:3 | wfi", "may_load,may_store"),
  (0xd503209fU, "HINT Imm:4 | sev", "may_load,may_store"),
  (0xd50320bfU, "HINT Imm:5 | sevl", "may_load,may_store"),
  (0xd50320dfU, "HINT Imm:6 | dgh", "may_load,may_store"),
  (0xd50320ffU, "XPACLRI | xpaclri", ""),
  (0xd503211fU, "PACIA1716 | pacia1716", ""),
  (0xd503215fU, "PACIB1716 | pacib1716", ""),
  (0xd503219fU, "AUTIA1716 | autia1716", ""),
  (0xd50321dfU, "AUTIB1716 | autib1716", ""),
  (0xd503221fU, "HINT Imm:16 | esb", "may_load,may_store"),
  (0xd503229fU, "HINT Imm:20 | csdb", "may_load,may_store"),
  (0xd503231fU, "PACIAZ | paciaz", ""),
  (0xd503233fU, "PACIASP | paciasp", ""),
  (0xd503235fU, "PACIBZ | pacibz", ""),
  (0xd503237fU, "PACIBSP | pacibsp", ""),
  (0xd503239fU, "AUTIAZ | autiaz", ""),
  (0xd50323bfU, "AUTIASP | autiasp", ""),
  (0xd50323dfU, "AUTIBZ | autibz", ""),
  (0xd50323ffU, "AUTIBSP | autibsp", ""),
  (0xd503245fU, "HINT Imm:34 | hint #34", "may_load,may_store"),
  (0xd50324ffU, "PACM | hint #39", ""),
  (0xd503251fU, "CHKFEAT | hint #40", ""),
  (0xd503309fU, "DSB Imm:0 | ssbb", "may_load,may_store"),
  (0xd50330bfU, "DMB Imm:0 | dmb #0", "may_load,may_store"),
  (0xd50330dfU, "ISB Imm:0 | isb #0", "may_load,may_store"),
  (0xd503349fU, "DSB Imm:4 | pssbb", "may_load,may_store"),
  (0xd5033b9fU, "DSB Imm:11 | dsb ish", "may_load,may_store"),
  (0xd5033f5fU, "CLREX Imm:15 | clrex", "may_load,may_store"),
  (0xd503427fU, "MSRpstatesvcrImm1 Imm:1 Imm:0 | smstop sm", ""),
  (0xd503437fU, "MSRpstatesvcrImm1 Imm:1 Imm:1 | smstart sm", ""),
  (
    0xd50837f3U, "SYSxt Imm:0 Imm:3 Imm:7 Imm:7 Reg:X19 | sys #0, c3, c7, #7, x19",
    "",
  ),
  (0xd508764eU, "SYSxt Imm:0 Imm:7 Imm:6 Imm:2 Reg:X14 | dc isw, x14", ""),
  (0xd50b752bU, "SYSxt Imm:3 Imm:7 Imm:5 Imm:1 Reg:X11 | ic ivau, x11", ""),
  (0xd50c8332U, "SYSxt Imm:4 Imm:8 Imm:3 Imm:1 Reg:X18 | tlbi vae2is, x18", ""),
  (0xd50e7019U, "APAS Reg:X25 | apas x25", ""),
  (0xd50e795bU, "SYSxt Imm:6 Imm:7 Imm:9 Imm:2 Reg:X27 | at s1e3a, x27", ""),
  (0xd515fbffU, "MSR Imm:45023 Reg:XZR | msr S2_5_C15_C11_7, xzr", ""),
  (0xd51b420aU, "MSR Imm:55824 Reg:X10 | msr NZCV, x10", ""),
  (
    0xd52a7d5fU, "SYSLxt Reg:XZR Imm:2 Imm:7 Imm:13 Imm:2 | sysl xzr, #2, c7, c13, #2",
    "",
  ),
  (0xd53b420aU, "MRS Reg:X10 Imm:55824 | mrs x10, NZCV", ""),
  (0xd53f03f5U, "MRS Reg:X21 Imm:63519 | mrs x21, S3_7_C0_C3_7", ""),
  (0xd61f0200U, "BR Reg:X16 | br x16", "indirect,barrier,terminator,affect_cf"),
  (
    0xd61f081fU, "BRAAZ Reg:X0 | braaz x0", "indirect,barrier,terminator,affect_cf",
  ),
  (
    0xd61f0c5fU, "BRABZ Reg:X2 | brabz x2", "indirect,barrier,terminator,affect_cf",
  ),
  (0xd63f0280U, "BLR Reg:X20 | blr x20", "call,affect_cf"),
  (0xd63f081fU, "BLRAAZ Reg:X0 | blraaz x0", "call,affect_cf"),
  (0xd63f0e3fU, "BLRABZ Reg:X17 | blrabz x17", "call,affect_cf"),
  (0xd65f03c0U, "RET Reg:LR | ret", "return,barrier,terminator,affect_cf"),
  (0xd65f0bffU, "RETAA | retaa", "return,barrier,terminator,affect_cf"),
  (0xd65f0fffU, "RETAB | retab", "return,barrier,terminator,affect_cf"),
  (
    0xd71f0911U, "BRAA Reg:X8 Reg:X17 | braa x8, x17", "indirect,barrier,terminator,affect_cf",
  ),
  (
    0xd71f0e1bU, "BRAB Reg:X16 Reg:X27 | brab x16, x27", "indirect,barrier,terminator,affect_cf",
  ),
  (0xd73f0a11U, "BLRAA Reg:X16 Reg:X17 | blraa x16, x17", "call,affect_cf"),
  (0xd73f0faaU, "BLRAB Reg:FP Reg:X10 | blrab x29, x10", "call,affect_cf"),
  (0xd80e0240U, "PRFMl Imm:0 Imm:28690 | prfm pldl1keep, #114760", ""),
  (0xda0603f4U, "SBCXr Reg:X20 Reg:XZR Reg:X6 | ngc x20, x6", ""),
  (0xda1f023cU, "SBCXr Reg:X28 Reg:X17 Reg:XZR | sbc x28, x17, xzr", ""),
  (0xda880500U, "CSNEGXr Reg:X0 Reg:X8 Reg:X8 Imm:0 | cneg x0, x8, ne", ""),
  (0xda88c100U, "CSINVXr Reg:X0 Reg:X8 Reg:X8 Imm:12 | cinv x0, x8, le", ""),
  (
    0xda950508U, "CSNEGXr Reg:X8 Reg:X8 Reg:X21 Imm:0 | csneg x8, x8, x21, eq", "",
  ),
  (
    0xda9f0100U, "CSINVXr Reg:X0 Reg:X8 Reg:XZR Imm:0 | csinv x0, x8, xzr, eq", "",
  ),
  (0xda9f03e8U, "CSINVXr Reg:X8 Reg:XZR Reg:XZR Imm:0 | csetm x8, ne", ""),
  (0xdac001a9U, "RBITXr Reg:X9 Reg:X13 | rbit x9, x13", ""),
  (0xdac00529U, "REV16Xr Reg:X9 Reg:X9 | rev16 x9, x9", ""),
  (0xdac00b77U, "REV32Xr Reg:X23 Reg:X27 | rev32 x23, x27", ""),
  (0xdac00d6bU, "REVXr Reg:X11 Reg:X11 | rev x11, x11", ""),
  (0xdac0114aU, "CLZXr Reg:X10 Reg:X10 | clz x10, x10", ""),
  (0xdac016f2U, "CLSXr Reg:X18 Reg:X23 | cls x18, x23", ""),
  (0xdac101b0U, "PACIA Reg:X16 Reg:X16 Reg:X13 | pacia x16, x13", ""),
  (0xdac10621U, "PACIB Reg:X1 Reg:X1 Reg:X17 | pacib x1, x17", ""),
  (0xdac10a30U, "PACDA Reg:X16 Reg:X16 Reg:X17 | pacda x16, x17", ""),
  (0xdac10e9dU, "PACDB Reg:FP Reg:FP Reg:X20 | pacdb x29, x20", ""),
  (0xdac112aaU, "AUTIA Reg:X10 Reg:X10 Reg:X21 | autia x10, x21", ""),
  (0xdac1144cU, "AUTIB Reg:X12 Reg:X12 Reg:X2 | autib x12, x2", ""),
  (0xdac11b56U, "AUTDA Reg:X22 Reg:X22 Reg:X26 | autda x22, x26", ""),
  (0xdac11e84U, "AUTDB Reg:X4 Reg:X4 Reg:X20 | autdb x4, x20", ""),
  (0xdac123f0U, "PACIZA Reg:X16 Reg:X16 | paciza x16", ""),
  (0xdac127f8U, "PACIZB Reg:X24 Reg:X24 | pacizb x24", ""),
  (0xdac12bfaU, "PACDZA Reg:X26 Reg:X26 | pacdza x26", ""),
  (0xdac12feaU, "PACDZB Reg:X10 Reg:X10 | pacdzb x10", ""),
  (0xdac133f0U, "AUTIZA Reg:X16 Reg:X16 | autiza x16", ""),
  (0xdac137e8U, "AUTIZB Reg:X8 Reg:X8 | autizb x8", ""),
  (0xdac13be4U, "AUTDZA Reg:X4 Reg:X4 | autdza x4", ""),
  (0xdac13fe5U, "AUTDZB Reg:X5 Reg:X5 | autdzb x5", ""),
  (0xdac143fdU, "XPACI Reg:FP Reg:FP | xpaci x29", ""),
  (0xdac147efU, "XPACD Reg:X15 Reg:X15 | xpacd x15", ""),
  (0xea08001fU, "ANDSXrs Reg:XZR Reg:X0 Reg:X8 Imm:0 | tst x0, x8", ""),
  (
    0xea1fff38U, "ANDSXrs Reg:X24 Reg:X25 Reg:XZR Imm:63 | ands x24, x25, xzr, lsl #63",
    "",
  ),
  (0xea28013fU, "BICSXrs Reg:XZR Reg:X9 Reg:X8 Imm:0 | bics xzr, x9, x8", ""),
  (0xeb09003fU, "SUBSXrs Reg:XZR Reg:X1 Reg:X9 Imm:0 | cmp x1, x9", ""),
  (0xeb090108U, "SUBSXrs Reg:X8 Reg:X8 Reg:X9 Imm:0 | subs x8, x8, x9", ""),
  (0xeb1003ebU, "SUBSXrs Reg:X11 Reg:XZR Reg:X16 Imm:0 | negs x11, x16", ""),
  (
    0xeb204415U, "SUBSXrx Reg:X21 Reg:X0 Reg:W0 Imm:17 | subs x21, x0, w0, uxtw #1",
    "",
  ),
  (0xeb20c01fU, "SUBSXrx Reg:XZR Reg:X0 Reg:W0 Imm:48 | cmp x0, w0, sxtw", ""),
  (
    0xeb20e7ebU, "SUBSXrx64 Reg:X11 Reg:SP Reg:X0 Imm:57 | subs x11, sp, x0, sxtx #1",
    "",
  ),
  (
    0xeb23c0a3U, "SUBSXrx Reg:X3 Reg:X5 Reg:W3 Imm:48 | subs x3, x5, w3, sxtw", "",
  ),
  (0xeb28833fU, "SUBSXrx Reg:XZR Reg:X25 Reg:W8 Imm:32 | cmp x25, w8, sxtb", ""),
  (0xeb29011fU, "SUBSXrx Reg:XZR Reg:X8 Reg:W9 Imm:0 | cmp x8, w9, uxtb", ""),
  (0xeb2a401fU, "SUBSXrx Reg:XZR Reg:X0 Reg:W10 Imm:16 | cmp x0, w10, uxtw", ""),
  (
    0xeb30335fU, "SUBSXrx Reg:XZR Reg:X26 Reg:W16 Imm:12 | cmp x26, w16, uxth #4",
    "",
  ),
  (
    0xeb352b6aU, "SUBSXrx Reg:X10 Reg:X27 Reg:W21 Imm:10 | subs x10, x27, w21, uxth #2",
    "",
  ),
  (
    0xeb38800fU, "SUBSXrx Reg:X15 Reg:X0 Reg:W24 Imm:32 | subs x15, x0, w24, sxtb",
    "",
  ),
  (
    0xeb3a03f2U, "SUBSXrx Reg:X18 Reg:SP Reg:W26 Imm:0 | subs x18, sp, w26, uxtb",
    "",
  ),
  (
    0xeb3a69dfU, "SUBSXrx64 Reg:XZR Reg:X14 Reg:X26 Imm:26 | cmp x14, x26, uxtx #2",
    "",
  ),
  (
    0xeb3aafe7U, "SUBSXrx Reg:X7 Reg:SP Reg:W26 Imm:43 | subs x7, sp, w26, sxth #3",
    "",
  ),
  (
    0xeb3c73b1U, "SUBSXrx64 Reg:X17 Reg:FP Reg:X28 Imm:28 | subs x17, x29, x28, uxtx #4",
    "",
  ),
  (0xf100056bU, "SUBSXri Reg:X11 Reg:X11 Imm:1 Imm:0 | subs x11, x11, #1", ""),
  (0xf100151fU, "SUBSXri Reg:XZR Reg:X8 Imm:5 Imm:0 | cmp x8, #5", ""),
  (0xf2403c08U, "ANDSXri Reg:X8 Reg:X0 Imm:4111 | ands x8, x0, #0xffff", ""),
  (
    0xf2440d1fU, "ANDSXri Reg:XZR Reg:X8 Imm:4355 | tst x8, #0xf000000000000000",
    "",
  ),
  (
    0xf2a468adU, "MOVKXi Reg:X13 Reg:X13 Imm:9029 Imm:16 | movk x13, #9029, lsl #16",
    "",
  ),
  (0xf8000016U, "STURXi Reg:X22 Reg:X0 Imm:0 | stur x22, [x0]", "may_store"),
  (
    0xf8008500U, "STRXpost Reg:X8 Reg:X0 Reg:X8 Imm:8 | str x0, [x8], #8", "may_store",
  ),
  (
    0xf8008f08U, "STRXpre Reg:X24 Reg:X8 Reg:X24 Imm:8 | str x8, [x24, #8]!", "may_store",
  ),
  (
    0xf8160aceU, "STTRXi Reg:X14 Reg:X22 Imm:-160 | sttr x14, [x22, #-160]", "may_store",
  ),
  (
    0xf81f83a0U, "STURXi Reg:X0 Reg:FP Imm:-8 | stur x0, [x29, #-8]", "may_store",
  ),
  (
    0xf820001fU, "LDADDX Reg:XZR Reg:X0 Reg:X0 | stadd x0, [x0]", "may_load,may_store",
  ),
  (
    0xf82006a1U, "LDRAAindexed Reg:X1 Reg:X21 Imm:0 | ldraa x1, [x21]", "may_load",
  ),
  (
    0xf82061e3U, "LDUMAXX Reg:X3 Reg:X0 Reg:X15 | ldumax x0, x3, [x15]", "may_load,may_store",
  ),
  (
    0xf82202e6U, "LDADDX Reg:X6 Reg:X2 Reg:X23 | ldadd x2, x6, [x23]", "may_load,may_store",
  ),
  (
    0xf8237374U, "LDUMINX Reg:X20 Reg:X3 Reg:X27 | ldumin x3, x20, [x27]", "may_load,may_store",
  ),
  (
    0xf8240524U, "LDRAAindexed Reg:X4 Reg:X9 Imm:64 | ldraa x4, [x9, #512]", "may_load",
  ),
  (
    0xf82542dfU, "LDSMAXX Reg:XZR Reg:X5 Reg:X22 | stsmax x5, [x22]", "may_load,may_store",
  ),
  (
    0xf82823e8U, "LDEORX Reg:X8 Reg:X8 Reg:SP | ldeor x8, x8, [sp]", "may_load,may_store",
  ),
  (
    0xf8284aa9U, "STRXroW Reg:X9 Reg:X21 Reg:W8 Imm:0 Imm:0 | str x9, [x21, w8, uxtw]",
    "may_store",
  ),
  (
    0xf8295900U, "STRXroW Reg:X0 Reg:X8 Reg:W9 Imm:0 Imm:1 | str x0, [x8, w9, uxtw #3]",
    "may_store",
  ),
  (
    0xf8296900U, "STRXroX Reg:X0 Reg:X8 Reg:X9 Imm:0 Imm:0 | str x0, [x8, x9]", "may_store",
  ),
  (
    0xf8297900U, "STRXroX Reg:X0 Reg:X8 Reg:X9 Imm:0 Imm:1 | str x0, [x8, x9, lsl #3]",
    "may_store",
  ),
  (
    0xf829d900U, "STRXroW Reg:X0 Reg:X8 Reg:W9 Imm:1 Imm:1 | str x0, [x8, w9, sxtw #3]",
    "may_store",
  ),
  (
    0xf82af94bU, "STRXroX Reg:X11 Reg:X10 Reg:X10 Imm:1 Imm:1 | str x11, [x10, x10, sxtx #3]",
    "may_store",
  ),
  (
    0xf82b43ebU, "LDSMAXX Reg:X11 Reg:X11 Reg:SP | ldsmax x11, x11, [sp]", "may_load,may_store",
  ),
  (
    0xf82bea12U, "STRXroX Reg:X18 Reg:X16 Reg:X11 Imm:1 Imm:0 | str x18, [x16, x11, sxtx]",
    "may_store",
  ),
  (
    0xf82e501fU, "LDSMINX Reg:XZR Reg:X14 Reg:X0 | stsmin x14, [x0]", "may_load,may_store",
  ),
  (
    0xf82f207fU, "LDEORX Reg:XZR Reg:X15 Reg:X3 | steor x15, [x3]", "may_load,may_store",
  ),
  (
    0xf834707fU, "LDUMINX Reg:XZR Reg:X20 Reg:X3 | stumin x20, [x3]", "may_load,may_store",
  ),
  (
    0xf83630ffU, "LDSETX Reg:XZR Reg:X22 Reg:X7 | stset x22, [x7]", "may_load,may_store",
  ),
  (
    0xf83883ffU, "SWPX Reg:XZR Reg:X24 Reg:SP | swp x24, xzr, [sp]", "may_load,may_store",
  ),
  (
    0xf839cae8U, "STRXroW Reg:X8 Reg:X23 Reg:W25 Imm:1 Imm:0 | str x8, [x23, w25, sxtw]",
    "may_store",
  ),
  (
    0xf83b502aU, "LDSMINX Reg:X10 Reg:X27 Reg:X1 | ldsmin x27, x10, [x1]", "may_load,may_store",
  ),
  (
    0xf83c117fU, "LDCLRX Reg:XZR Reg:X28 Reg:X11 | stclr x28, [x11]", "may_load,may_store",
  ),
  (
    0xf83d11e0U, "LDCLRX Reg:X0 Reg:FP Reg:X15 | ldclr x29, x0, [x15]", "may_load,may_store",
  ),
  (
    0xf83e62bfU, "LDUMAXX Reg:XZR Reg:LR Reg:X21 | stumax x30, [x21]", "may_load,may_store",
  ),
  (
    0xf83f3340U, "LDSETX Reg:X0 Reg:XZR Reg:X26 | ldset xzr, x0, [x26]", "may_load,may_store",
  ),
  (
    0xf83ffde6U, "LDRAAwriteback Reg:X15 Reg:X6 Reg:X15 Imm:511 | ldraa x6, [x15, #4088]!",
    "may_load",
  ),
  (0xf84001b4U, "LDURXi Reg:X20 Reg:X13 Imm:0 | ldur x20, [x13]", "may_load"),
  (
    0xf8408d00U, "LDRXpre Reg:X8 Reg:X0 Reg:X8 Imm:8 | ldr x0, [x8, #8]!", "may_load",
  ),
  (
    0xf8410700U, "LDRXpost Reg:X24 Reg:X0 Reg:X24 Imm:16 | ldr x0, [x24], #16", "may_load",
  ),
  (
    0xf84c7bdfU, "LDTRXi Reg:XZR Reg:LR Imm:199 | ldtr xzr, [x30, #199]", "may_load",
  ),
  (0xf85f83a8U, "LDURXi Reg:X8 Reg:FP Imm:-8 | ldur x8, [x29, #-8]", "may_load"),
  (
    0xf8600002U, "LDADDLX Reg:X2 Reg:X0 Reg:X0 | ldaddl x0, x2, [x0]", "may_load,may_store",
  ),
  (
    0xf8605900U, "LDRXroW Reg:X0 Reg:X8 Reg:W0 Imm:0 Imm:1 | ldr x0, [x8, w0, uxtw #3]",
    "may_load",
  ),
  (
    0xf860d900U, "LDRXroW Reg:X0 Reg:X8 Reg:W0 Imm:1 Imm:1 | ldr x0, [x8, w0, sxtw #3]",
    "may_load",
  ),
  (
    0xf861233fU, "LDEORLX Reg:XZR Reg:X1 Reg:X25 | steorl x1, [x25]", "may_load,may_store",
  ),
  (
    0xf86373e7U, "LDUMINLX Reg:X7 Reg:X3 Reg:SP | lduminl x3, x7, [sp]", "may_load,may_store",
  ),
  (
    0xf864319fU, "LDSETLX Reg:XZR Reg:X4 Reg:X12 | stsetl x4, [x12]", "may_load,may_store",
  ),
  (
    0xf86483ebU, "SWPLX Reg:X11 Reg:X4 Reg:SP | swpl x4, x11, [sp]", "may_load,may_store",
  ),
  (
    0xf865627eU, "LDUMAXLX Reg:LR Reg:X5 Reg:X19 | ldumaxl x5, x30, [x19]", "may_load,may_store",
  ),
  (
    0xf8661076U, "LDCLRLX Reg:X22 Reg:X6 Reg:X3 | ldclrl x6, x22, [x3]", "may_load,may_store",
  ),
  (
    0xf866635fU, "LDUMAXLX Reg:XZR Reg:X6 Reg:X26 | stumaxl x6, [x26]", "may_load,may_store",
  ),
  (
    0xf86743ffU, "LDSMAXLX Reg:XZR Reg:X7 Reg:SP | stsmaxl x7, [sp]", "may_load,may_store",
  ),
  (
    0xf86813bfU, "LDCLRLX Reg:XZR Reg:X8 Reg:FP | stclrl x8, [x29]", "may_load,may_store",
  ),
  (
    0xf86821abU, "LDEORLX Reg:X11 Reg:X8 Reg:X13 | ldeorl x8, x11, [x13]", "may_load,may_store",
  ),
  (
    0xf8694893U, "LDRXroW Reg:X19 Reg:X4 Reg:W9 Imm:0 Imm:0 | ldr x19, [x4, w9, uxtw]",
    "may_load",
  ),
  (
    0xf869790aU, "LDRXroX Reg:X10 Reg:X8 Reg:X9 Imm:0 Imm:1 | ldr x10, [x8, x9, lsl #3]",
    "may_load",
  ),
  (
    0xf86a41c3U, "LDSMAXLX Reg:X3 Reg:X10 Reg:X14 | ldsmaxl x10, x3, [x14]", "may_load,may_store",
  ),
  (
    0xf86afa92U, "LDRXroX Reg:X18 Reg:X20 Reg:X10 Imm:1 Imm:1 | ldr x18, [x20, x10, sxtx #3]",
    "may_load",
  ),
  (
    0xf86c505fU, "LDSMINLX Reg:XZR Reg:X12 Reg:X2 | stsminl x12, [x2]", "may_load,may_store",
  ),
  (
    0xf86f5129U, "LDSMINLX Reg:X9 Reg:X15 Reg:X9 | ldsminl x15, x9, [x9]", "may_load,may_store",
  ),
  (
    0xf87130fbU, "LDSETLX Reg:X27 Reg:X17 Reg:X7 | ldsetl x17, x27, [x7]", "may_load,may_store",
  ),
  (
    0xf8756800U, "LDRXroX Reg:X0 Reg:X0 Reg:X21 Imm:0 Imm:0 | ldr x0, [x0, x21]",
    "may_load",
  ),
  (
    0xf878ebe6U, "LDRXroX Reg:X6 Reg:SP Reg:X24 Imm:1 Imm:0 | ldr x6, [sp, x24, sxtx]",
    "may_load",
  ),
  (
    0xf879cae8U, "LDRXroW Reg:X8 Reg:X23 Reg:W25 Imm:1 Imm:0 | ldr x8, [x23, w25, sxtw]",
    "may_load",
  ),
  (
    0xf87d737fU, "LDUMINLX Reg:XZR Reg:FP Reg:X27 | stuminl x29, [x27]", "may_load,may_store",
  ),
  (
    0xf87f001fU, "LDADDLX Reg:XZR Reg:XZR Reg:X0 | staddl xzr, [x0]", "may_load,may_store",
  ),
  (0xf88003e0U, "PRFUMi Imm:0 Reg:SP Imm:0 | prfum pldl1keep, [sp]", ""),
  (
    0xf88a03f2U, "PRFUMi Imm:18 Reg:SP Imm:160 | prfum pstl2keep, [sp, #160]", "",
  ),
  (
    0xf8a0225fU, "LDEORAX Reg:XZR Reg:X0 Reg:X18 | ldeora x0, xzr, [x18] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8a0e925U, "PRFMroX Imm:5 Reg:X9 Reg:X0 Imm:1 Imm:0 | prfm pldl3strm, [x9, x0, sxtx]",
    "",
  ),
  (
    0xf8a25b93U, "PRFMroW Imm:19 Reg:X28 Reg:W2 Imm:0 Imm:1 | prfm pstl2strm, [x28, w2, uxtw #3]",
    "",
  ),
  (
    0xf8a4015fU, "LDADDAX Reg:XZR Reg:X4 Reg:X10 | ldadda x4, xzr, [x10] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8a4733fU, "LDUMINAX Reg:XZR Reg:X4 Reg:X25 | ldumina x4, xzr, [x25] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8a51223U, "LDCLRAX Reg:X3 Reg:X5 Reg:X17 | ldclra x5, x3, [x17]", "may_load,may_store",
  ),
  (
    0xf8a6603fU, "LDUMAXAX Reg:XZR Reg:X6 Reg:X1 | ldumaxa x6, xzr, [x1] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8a74a70U, "PRFMroW Imm:16 Reg:X19 Reg:W7 Imm:0 Imm:0 | prfm pstl1keep, [x19, w7, uxtw]",
    "",
  ),
  (
    0xf8a753b1U, "LDSMINAX Reg:X17 Reg:X7 Reg:FP | ldsmina x7, x17, [x29]", "may_load,may_store",
  ),
  (
    0xf8a7c805U, "PRFMroW Imm:5 Reg:X0 Reg:W7 Imm:1 Imm:0 | prfm pldl3strm, [x0, w7, sxtw]",
    "",
  ),
  (
    0xf8a821aeU, "LDEORAX Reg:X14 Reg:X8 Reg:X13 | ldeora x8, x14, [x13]", "may_load,may_store",
  ),
  (
    0xf8a98009U, "SWPAX Reg:X9 Reg:X9 Reg:X0 | swpa x9, x9, [x0]", "may_load,may_store",
  ),
  (
    0xf8aa338fU, "LDSETAX Reg:X15 Reg:X10 Reg:X28 | ldseta x10, x15, [x28]", "may_load,may_store",
  ),
  (
    0xf8aa4183U, "LDSMAXAX Reg:X3 Reg:X10 Reg:X12 | ldsmaxa x10, x3, [x12]", "may_load,may_store",
  ),
  (
    0xf8ac33ffU, "LDSETAX Reg:XZR Reg:X12 Reg:SP | ldseta x12, xzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8ac608dU, "LDUMAXAX Reg:X13 Reg:X12 Reg:X4 | ldumaxa x12, x13, [x4]", "may_load,may_store",
  ),
  (
    0xf8addb60U, "PRFMroW Imm:0 Reg:X27 Reg:W13 Imm:1 Imm:1 | prfm pldl1keep, [x27, w13, sxtw #3]",
    "",
  ),
  (
    0xf8ae7a08U, "PRFMroX Imm:8 Reg:X16 Reg:X14 Imm:0 Imm:1 | prfm plil1keep, [x16, x14, lsl #3]",
    "",
  ),
  (
    0xf8af517fU, "LDSMINAX Reg:XZR Reg:X15 Reg:X11 | ldsmina x15, xzr, [x11] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8b1fb87U, "PRFMroX Imm:7 Reg:X28 Reg:X17 Imm:1 Imm:1 | prfm #7, [x28, x17, sxtx #3]",
    "",
  ),
  (
    0xf8b4131fU, "LDCLRAX Reg:XZR Reg:X20 Reg:X24 | ldclra x20, xzr, [x24] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8b47178U, "LDUMINAX Reg:X24 Reg:X20 Reg:X11 | ldumina x20, x24, [x11]", "may_load,may_store",
  ),
  (
    0xf8b57e86U, "LDRABwriteback Reg:X20 Reg:X6 Reg:X20 Imm:343 | ldrab x6, [x20, #2744]!",
    "may_load",
  ),
  (
    0xf8bb43ffU, "LDSMAXAX Reg:XZR Reg:X27 Reg:SP | ldsmaxa x27, xzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (0xf8bc4bffU, "RPRFM Imm:7 Reg:X28 Reg:SP | rprfm #7, x28, [sp]", ""),
  (
    0xf8bc6be6U, "PRFMroX Imm:6 Reg:SP Reg:X28 Imm:0 Imm:0 | prfm #6, [sp, x28]",
    "",
  ),
  (
    0xf8bf03feU, "LDADDAX Reg:LR Reg:XZR Reg:SP | ldadda xzr, x30, [sp]", "may_load,may_store",
  ),
  (
    0xf8bf833fU, "SWPAX Reg:XZR Reg:XZR Reg:X25 | swpa xzr, xzr, [x25] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8bf97ecU, "LDRABindexed Reg:X12 Reg:SP Imm:505 | ldrab x12, [sp, #4040]",
    "may_load",
  ),
  (0xf8bfc1cdU, "LDAPRX Reg:X13 Reg:X14 | ldapr x13, [x14]", "may_load"),
  (
    0xf8e002dfU, "LDADDALX Reg:XZR Reg:X0 Reg:X22 | ldaddal x0, xzr, [x22] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8e20008U, "LDADDALX Reg:X8 Reg:X2 Reg:X0 | ldaddal x2, x8, [x0]", "may_load,may_store",
  ),
  (
    0xf8e280eaU, "SWPALX Reg:X10 Reg:X2 Reg:X7 | swpal x2, x10, [x7]", "may_load,may_store",
  ),
  (
    0xf8e4635fU, "LDUMAXALX Reg:XZR Reg:X4 Reg:X26 | ldumaxal x4, xzr, [x26] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8e760e0U, "LDUMAXALX Reg:X0 Reg:X7 Reg:X7 | ldumaxal x7, x0, [x7]", "may_load,may_store",
  ),
  (
    0xf8e77339U, "LDUMINALX Reg:X25 Reg:X7 Reg:X25 | lduminal x7, x25, [x25]", "may_load,may_store",
  ),
  (
    0xf8e82388U, "LDEORALX Reg:X8 Reg:X8 Reg:X28 | ldeoral x8, x8, [x28]", "may_load,may_store",
  ),
  (
    0xf8ea40ffU, "LDSMAXALX Reg:XZR Reg:X10 Reg:X7 | ldsmaxal x10, xzr, [x7] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8ea53ffU, "LDSMINALX Reg:XZR Reg:X10 Reg:SP | ldsminal x10, xzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8eb21ffU, "LDEORALX Reg:XZR Reg:X11 Reg:X15 | ldeoral x11, xzr, [x15] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8ee11efU, "LDCLRALX Reg:X15 Reg:X14 Reg:X15 | ldclral x14, x15, [x15]", "may_load,may_store",
  ),
  (
    0xf8f2137fU, "LDCLRALX Reg:XZR Reg:X18 Reg:X27 | ldclral x18, xzr, [x27] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8f23299U, "LDSETALX Reg:X25 Reg:X18 Reg:X20 | ldsetal x18, x25, [x20]", "may_load,may_store",
  ),
  (
    0xf8f24315U, "LDSMAXALX Reg:X21 Reg:X18 Reg:X24 | ldsmaxal x18, x21, [x24]",
    "may_load,may_store",
  ),
  (
    0xf8f6335fU, "LDSETALX Reg:XZR Reg:X22 Reg:X26 | ldsetal x22, xzr, [x26] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8fb500dU, "LDSMINALX Reg:X13 Reg:X27 Reg:X0 | ldsminal x27, x13, [x0]", "may_load,may_store",
  ),
  (
    0xf8ff73ffU, "LDUMINALX Reg:XZR Reg:XZR Reg:SP | lduminal xzr, xzr, [sp] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (
    0xf8ff80dfU, "SWPALX Reg:XZR Reg:XZR Reg:X6 | swpal xzr, xzr, [x6] // acquire semantics dropped since destination is zero",
    "may_load,may_store",
  ),
  (0xf9000109U, "STRXui Reg:X9 Reg:X8 Imm:0 | str x9, [x8]", "may_store"),
  (0xf9000bf5U, "STRXui Reg:X21 Reg:SP Imm:2 | str x21, [sp, #16]", "may_store"),
  (0xf9400128U, "LDRXui Reg:X8 Reg:X9 Imm:0 | ldr x8, [x9]", "may_load"),
  (0xf9400bf5U, "LDRXui Reg:X21 Reg:SP Imm:2 | ldr x21, [sp, #16]", "may_load"),
  (0xf98002a0U, "PRFMui Imm:0 Reg:X21 Imm:0 | prfm pldl1keep, [x21]", ""),
  (0xf999673fU, "PRFMui Imm:31 Reg:X25 Imm:1625 | prfm #31, [x25, #13000]", ""),
  (0xfa1303ebU, "SBCSXr Reg:X11 Reg:XZR Reg:X19 | ngcs x11, x19", ""),
  (0xfa1f01b8U, "SBCSXr Reg:X24 Reg:X13 Reg:XZR | sbcs x24, x13, xzr", ""),
  (0xfa400800U, "CCMPXi Reg:X0 Imm:0 Imm:0 Imm:0 | ccmp x0, #0, #0, eq", ""),
  (0xfa480000U, "CCMPXr Reg:X0 Reg:X8 Imm:0 Imm:0 | ccmp x0, x8, #0, eq", ""),
]
