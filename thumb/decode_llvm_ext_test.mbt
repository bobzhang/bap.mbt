// LLVM samples of the Thumb-2 instructions decoded by the tables of the
// `arm` package (`@arm.decode_t32_ext`: VFP, NEON, coprocessor, bit field,
// saturation, multiply, parallel arithmetic, unprivileged loads and stores):
// one word per opcode and printed form, with the output of LLVM 22's
// disassembler (`-triple=thumbv7-linux-gnueabi`), in the format of
// `render_llvm`.

///|
let llvm_ext_samples : String =
  #|0xec32c5a3	t2LDC_POST Imm:5 Imm:12 Reg:R2 Imm:163 Imm:14 Reg:Nil | ldc p5, c12, [r2], #-652 | may_load
  #|0xec4f0059	t2MCRR Imm:0 Imm:5 Reg:R0 Reg:PC Imm:9 Imm:14 Reg:Nil | mcrr p0, #5, r0, pc, c9 | may_load,may_store
  #|0xec5373df	t2MRRC Reg:R7 Reg:R3 Imm:3 Imm:13 Imm:15 Imm:14 Reg:Nil | mrrc p3, #13, r7, r3, c15
  #|0xec549a10	VMOVRRS Reg:R9 Reg:R4 Reg:S0 Reg:S1 Imm:14 Reg:Nil | vmov r9, r4, s0, s1
  #|0xec67e22f	t2STCL_POST Imm:2 Imm:14 Reg:R7 Imm:47 Imm:14 Reg:Nil | stcl p2, c14, [r7], #-188 | may_store
  #|0xec879a00	VSTMSIA Reg:R7 Imm:14 Reg:Nil Reg:S18 | vstmia r7, {s18} | may_store
  #|0xec87b15d	t2STC_OPTION Imm:1 Imm:11 Reg:R7 Imm:93 Imm:14 Reg:Nil | stc p1, c11, [r7], {93} | may_store
  #|0xec8e1baa	VSTMDIA Reg:LR Imm:14 Reg:Nil Reg:D1 Reg:D2 Reg:D3 Reg:D4 Reg:D5 Reg:D6 Reg:D7 Reg:D8 Reg:D9 Reg:D10 Reg:D11 Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vstmia lr, {d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31} | may_store
  #|0xec927a90	VLDMSIA Reg:R2 Imm:14 Reg:Nil Reg:S14 Reg:S15 Reg:S16 Reg:S17 Reg:S18 Reg:S19 Reg:S20 Reg:S21 Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmia r2, {s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_load
  #|0xec940003	t2LDC_OPTION Imm:0 Imm:0 Reg:R4 Imm:3 Imm:14 Reg:Nil | ldc p0, c0, [r4], {3} | may_load
  #|0xec952b63	FLDMXIA Reg:R5 Imm:14 Reg:Nil Reg:D2 Reg:D3 Reg:D4 Reg:D5 Reg:D6 Reg:D7 Reg:D8 Reg:D9 Reg:D10 Reg:D11 Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | fldmiax r5, {d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31}
  #|0xec95ea90	VLDMSIA Reg:R5 Imm:14 Reg:Nil Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmia r5, {s28, s29, s30, s31} | may_load
  #|0xec98db90	VLDMDIA Reg:R8 Imm:14 Reg:Nil Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vldmia r8, {d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31} | may_load
  #|0xec9c1b03	FLDMXIA Reg:R12 Imm:14 Reg:Nil Reg:D1 | fldmiax r12, {d1}
  #|0xeca21a0b	VSTMSIA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:S2 Reg:S3 Reg:S4 Reg:S5 Reg:S6 Reg:S7 Reg:S8 Reg:S9 Reg:S10 Reg:S11 Reg:S12 | vstmia r2!, {s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12} | may_store
  #|0xeca8cb95	FSTMXIA_UPD Reg:R8 Reg:R8 Imm:14 Reg:Nil Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | fstmiax r8!, {d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31}
  #|0xecaa6b68	VSTMDIA_UPD Reg:R10 Reg:R10 Imm:14 Reg:Nil Reg:D6 Reg:D7 Reg:D8 Reg:D9 Reg:D10 Reg:D11 Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vstmia r10!, {d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31} | may_store
  #|0xecab152b	t2STC_POST Imm:5 Imm:1 Reg:R11 Imm:299 Imm:14 Reg:Nil | stc p5, c1, [r11], #172 | may_store
  #|0xecab4a02	VSTMSIA_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:S8 Reg:S9 | vstmia r11!, {s8, s9} | may_store
  #|0xecc0dbaa	VSTMDIA Reg:R0 Imm:14 Reg:Nil Reg:D29 Reg:D30 Reg:D31 | vstmia r0, {d29, d30, d31} | may_store
  #|0xecc60a60	VSTMSIA Reg:R6 Imm:14 Reg:Nil Reg:S1 Reg:S2 Reg:S3 Reg:S4 Reg:S5 Reg:S6 Reg:S7 Reg:S8 Reg:S9 Reg:S10 Reg:S11 Reg:S12 Reg:S13 Reg:S14 Reg:S15 Reg:S16 Reg:S17 Reg:S18 Reg:S19 Reg:S20 Reg:S21 Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vstmia r6, {s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_store
  #|0xecc61b00	VSTMDIA Reg:R6 Imm:14 Reg:Nil Reg:D17 | vstmia r6, {d17} | may_store
  #|0xecc9cab8	VSTMSIA Reg:R9 Imm:14 Reg:Nil Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vstmia r9, {s25, s26, s27, s28, s29, s30, s31} | may_store
  #|0xeccc7ba4	VSTMDIA Reg:R12 Imm:14 Reg:Nil Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vstmia r12, {d23, d24, d25, d26, d27, d28, d29, d30, d31} | may_store
  #|0xeccd9fb9	t2STCL_OPTION Imm:15 Imm:9 Reg:SP Imm:185 Imm:14 Reg:Nil | stcl p15, c9, [sp], {185} | may_store
  #|0xeccdcb10	VSTMDIA Reg:SP Imm:14 Reg:Nil Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vstmia sp, {d28, d29, d30, d31} | may_store
  #|0xecd09b3e	VLDMDIA Reg:R0 Imm:14 Reg:Nil Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vldmia r0, {d25, d26, d27, d28, d29, d30, d31} | may_load
  #|0xecd3cc00	t2LDCL_OPTION Imm:12 Imm:12 Reg:R3 Imm:0 Imm:14 Reg:Nil | ldcl p12, c12, [r3], {0} | may_load
  #|0xece2fb96	VSTMDIA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:D31 | vstmia r2!, {d31} | may_store
  #|0xecf86b00	VLDMDIA_UPD Reg:R8 Reg:R8 Imm:14 Reg:Nil Reg:D22 | vldmia r8!, {d22} | may_load
  #|0xecfb4aae	VLDMSIA_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:S9 Reg:S10 Reg:S11 Reg:S12 Reg:S13 Reg:S14 Reg:S15 Reg:S16 Reg:S17 Reg:S18 Reg:S19 Reg:S20 Reg:S21 Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmia r11!, {s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_load
  #|0xecff8eb6	t2LDCL_POST Imm:14 Imm:8 Reg:PC Imm:438 Imm:14 Reg:Nil | ldcl p14, c8, [pc], #728 | may_load
  #|0xed14aaf5	VLDRS Reg:S20 Reg:R4 Imm:501 Imm:14 Reg:Nil | vldr s20, [r4, #-980] | may_load
  #|0xed156ff6	t2LDC_OFFSET Imm:15 Imm:6 Reg:R5 Imm:502 Imm:14 Reg:Nil | ldc p15, c6, [r5, #-984] | may_load,may_store
  #|0xed24d400	t2STC_PRE Imm:4 Imm:13 Reg:R4 Imm:256 Imm:14 Reg:Nil | stc p4, c13, [r4, #-0]! | may_store
  #|0xed2e4b75	FSTMXDB_UPD Reg:LR Reg:LR Imm:14 Reg:Nil Reg:D4 Reg:D5 Reg:D6 Reg:D7 Reg:D8 Reg:D9 Reg:D10 Reg:D11 Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | fstmdbx lr!, {d4, d5, d6, d7, d8, d9, d10, d11, d12, d13, d14, d15, d16, d17, d18, d19, d20, d21, d22, d23, d24, d25, d26, d27, d28, d29, d30, d31}
  #|0xed32ba17	VLDMSDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmdb r2!, {s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_load
  #|0xed45747a	t2STCL_OFFSET Imm:4 Imm:7 Reg:R5 Imm:378 Imm:14 Reg:Nil | stcl p4, c7, [r5, #-488] | may_load,may_store
  #|0xed47ea00	VSTRS Reg:S29 Reg:R7 Imm:256 Imm:14 Reg:Nil | vstr s29, [r7, #-0] | may_store
  #|0xed47fb35	VSTRD Reg:D31 Reg:R7 Imm:309 Imm:14 Reg:Nil | vstr d31, [r7, #-212] | may_store
  #|0xed61bb10	VSTMDDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vstmdb r1!, {d27, d28, d29, d30, d31} | may_store
  #|0xed64cab9	VSTMSDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vstmdb r4!, {s25, s26, s27, s28, s29, s30, s31} | may_store
  #|0xed69eb00	VSTMDDB_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:D30 | vstmdb r9!, {d30} | may_store
  #|0xed70d9cc	t2LDCL_PRE Imm:9 Imm:13 Reg:R0 Imm:460 Imm:14 Reg:Nil | ldcl p9, c13, [r0, #-816]! | may_load
  #|0xed721a95	VLDMSDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:S3 Reg:S4 Reg:S5 Reg:S6 Reg:S7 Reg:S8 Reg:S9 Reg:S10 Reg:S11 Reg:S12 Reg:S13 Reg:S14 Reg:S15 Reg:S16 Reg:S17 Reg:S18 Reg:S19 Reg:S20 Reg:S21 Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmdb r2!, {s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_load
  #|0xed746a3a	VLDMSDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:S13 Reg:S14 Reg:S15 Reg:S16 Reg:S17 Reg:S18 Reg:S19 Reg:S20 Reg:S21 Reg:S22 Reg:S23 Reg:S24 Reg:S25 Reg:S26 Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmdb r4!, {s13, s14, s15, s16, s17, s18, s19, s20, s21, s22, s23, s24, s25, s26, s27, s28, s29, s30, s31} | may_load
  #|0xed74faa0	VLDMSDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:S31 | vldmdb r4!, {s31} | may_load
  #|0xed7a9b40	VLDMDDB_UPD Reg:R10 Reg:R10 Imm:14 Reg:Nil Reg:D25 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:D30 Reg:D31 | vldmdb r10!, {d25, d26, d27, d28, d29, d30, d31} | may_load
  #|0xed7fda7c	VLDMSDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:S27 Reg:S28 Reg:S29 Reg:S30 Reg:S31 | vldmdb pc!, {s27, s28, s29, s30, s31} | affect_cf,may_load
  #|0xed890000	t2STC_OFFSET Imm:0 Imm:0 Reg:R9 Imm:0 Imm:14 Reg:Nil | stc p0, c0, [r9] | may_load,may_store
  #|0xed8af9aa	t2STC_OFFSET Imm:9 Imm:15 Reg:R10 Imm:170 Imm:14 Reg:Nil | stc p9, c15, [r10, #680] | may_load,may_store
  #|0xed99ce00	t2LDC_OFFSET Imm:14 Imm:12 Reg:R9 Imm:0 Imm:14 Reg:Nil | ldc p14, c12, [r9] | may_load,may_store
  #|0xed9a2bc4	VLDRD Reg:D2 Reg:R10 Imm:196 Imm:14 Reg:Nil | vldr d2, [r10, #784] | may_load
  #|0xedba00e2	t2LDC_PRE Imm:0 Imm:0 Reg:R10 Imm:226 Imm:14 Reg:Nil | ldc p0, c0, [r10, #904]! | may_load
  #|0xedc18700	t2STCL_OFFSET Imm:7 Imm:8 Reg:R1 Imm:0 Imm:14 Reg:Nil | stcl p7, c8, [r1] | may_load,may_store
  #|0xeddcaf8f	t2LDCL_OFFSET Imm:15 Imm:10 Reg:R12 Imm:143 Imm:14 Reg:Nil | ldcl p15, c10, [r12, #572] | may_load,may_store
  #|0xeddd4000	t2LDCL_OFFSET Imm:0 Imm:4 Reg:SP Imm:0 Imm:14 Reg:Nil | ldcl p0, c4, [sp] | may_load,may_store
  #|0xedec2d0d	t2STCL_PRE Imm:13 Imm:2 Reg:R12 Imm:13 Imm:14 Reg:Nil | stcl p13, c2, [r12, #52]! | may_store
  #|0xee144ede	t2MRC Reg:R4 Imm:14 Imm:0 Imm:4 Imm:14 Imm:6 Imm:14 Reg:Nil | mrc p14, #0, r4, c4, c14, #6 | may_load,may_store
  #|0xee1babf0	VGETLNs16 Reg:R10 Reg:D27 Imm:1 Imm:14 Reg:Nil | vmov.s16 r10, d27[1]
  #|0xee256b00	VMULD Reg:D6 Reg:D5 Reg:D0 Imm:14 Reg:Nil | vmul.f64 d6, d5, d0
  #|0xee3f3a04	VADDS Reg:S6 Reg:S30 Reg:S8 Imm:14 Reg:Nil | vadd.f32 s6, s30, s8
  #|0xee492b87	VMLAD Reg:D18 Reg:D18 Reg:D25 Reg:D7 Imm:14 Reg:Nil | vmla.f64 d18, d25, d7
  #|0xee4c7ac7	VMLSS Reg:S15 Reg:S15 Reg:S25 Reg:S14 Imm:14 Reg:Nil | vmls.f32 s15, s25, s14
  #|0xee60bbc0	VNMULD Reg:D27 Reg:D16 Reg:D0 Imm:14 Reg:Nil | vnmul.f64 d27, d16, d0
  #|0xee63fac0	VNMULS Reg:S31 Reg:S7 Reg:S0 Imm:14 Reg:Nil | vnmul.f32 s31, s7, s0
  #|0xee6eaa07	VMULS Reg:S21 Reg:S28 Reg:S14 Imm:14 Reg:Nil | vmul.f32 s21, s28, s14
  #|0xee709b50	VGETLNs8 Reg:R9 Reg:D0 Imm:6 Imm:14 Reg:Nil | vmov.s8 r9, d0[6]
  #|0xee775b6c	VSUBD Reg:D21 Reg:D7 Reg:D28 Imm:14 Reg:Nil | vsub.f64 d21, d7, d28
  #|0xee788660	t2CDP Imm:6 Imm:7 Imm:8 Imm:8 Imm:0 Imm:3 Imm:14 Reg:Nil | cdp p6, #7, c8, c8, c0, #3 | may_load,may_store
  #|0xee7efba0	VADDD Reg:D31 Reg:D30 Reg:D16 Imm:14 Reg:Nil | vadd.f64 d31, d30, d16
  #|0xee843154	t2MCR Imm:1 Imm:4 Reg:R3 Imm:4 Imm:4 Imm:2 Imm:14 Reg:Nil | mcr p1, #4, r3, c4, c4, #2 | may_load,may_store
  #|0xeecb4b07	VDIVD Reg:D20 Reg:D11 Reg:D7 Imm:14 Reg:Nil | vdiv.f64 d20, d11, d7
  #|0xeece8b90	VDUP8d Reg:D30 Reg:R8 Imm:14 Reg:Nil | vdup.8 d30, r8
  #|0xeed2f3b2	t2MRC Reg:APSR_NZCV Imm:3 Imm:6 Imm:2 Imm:2 Imm:5 Imm:14 Reg:Nil | mrc p3, #6, apsr_nzcv, c2, c2, #5 | may_load,may_store
  #|0xeef93a1a	VMRS_FPINST Reg:R3 Imm:14 Reg:Nil | vmrs r3, fpinst
  #|0xef00000f	VHADDsv8i8 Reg:D0 Reg:D0 Reg:D15 Imm:14 Reg:Nil | vhadd.s8 d0, d0, d15
  #|0xef0000b6	VQADDsv8i8 Reg:D0 Reg:D16 Reg:D22 Imm:14 Reg:Nil | vqadd.s8 d0, d16, d22
  #|0xef0000e8	VHADDsv16i8 Reg:Q0 Reg:Q8 Reg:Q12 Imm:14 Reg:Nil | vhadd.s8 q0, q8, q12
  #|0xef0000f0	VQADDsv16i8 Reg:Q0 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vqadd.s8 q0, q8, q8
  #|0xef000310	VCGEsv8i8 Reg:D0 Reg:D0 Reg:D0 Imm:14 Reg:Nil | vcge.s8 d0, d0, d0
  #|0xef000740	VABDsv16i8 Reg:Q0 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vabd.s8 q0, q0, q0
  #|0xef000d60	VADDfq Reg:Q0 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vadd.f32 q0, q0, q8
  #|0xef0021c4	VRHADDsv16i8 Reg:Q1 Reg:Q8 Reg:Q2 Imm:14 Reg:Nil | vrhadd.s8 q1, q8, q2
  #|0xef002660	VMAXsv16i8 Reg:Q1 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vmax.s8 q1, q0, q8
  #|0xef00281d	VTSTv8i8 Reg:D2 Reg:D0 Reg:D13 Imm:14 Reg:Nil | vtst.8 d2, d0, d13
  #|0xef002f04	VMAXfd Reg:D2 Reg:D0 Reg:D4 Imm:14 Reg:Nil | vmax.f32 d2, d0, d4
  #|0xef002ff0	VRECPSfq Reg:Q1 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vrecps.f32 q1, q8, q8
  #|0xef003205	VHSUBsv8i8 Reg:D3 Reg:D0 Reg:D5 Imm:14 Reg:Nil | vhsub.s8 d3, d0, d5
  #|0xef003992	VMULv8i8 Reg:D3 Reg:D16 Reg:D2 Imm:14 Reg:Nil | vmul.i8 d3, d16, d2
  #|0xef00429c	VQSUBsv8i8 Reg:D4 Reg:D16 Reg:D12 Imm:14 Reg:Nil | vqsub.s8 d4, d16, d12
  #|0xef0049f0	VMULv16i8 Reg:Q2 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vmul.i8 q2, q8, q8
  #|0xef004e60	VCEQfq Reg:Q2 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vceq.f32 q2, q0, q8
  #|0xef005d3a	VMLAfd Reg:D5 Reg:D5 Reg:D0 Reg:D26 Imm:14 Reg:Nil | vmla.f32 d5, d0, d26
  #|0xef0065a4	VRSHLsv8i8 Reg:D6 Reg:D20 Reg:D16 Imm:14 Reg:Nil | vrshl.s8 d6, d20, d16
  #|0xef006613	VMINsv8i8 Reg:D6 Reg:D0 Reg:D3 Imm:14 Reg:Nil | vmin.s8 d6, d0, d3
  #|0xef0069c0	VMLAv16i8 Reg:Q3 Reg:Q3 Reg:Q8 Reg:Q0 Imm:14 Reg:Nil | vmla.i8 q3, q8, q0
  #|0xef00711d	VANDd Reg:D7 Reg:D0 Reg:D13 Imm:14 Reg:Nil | vand d7, d0, d13
  #|0xef007f3f	VRECPSfd Reg:D7 Reg:D0 Reg:D31 Imm:14 Reg:Nil | vrecps.f32 d7, d0, d31
  #|0xef008240	VHSUBsv16i8 Reg:Q4 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vhsub.s8 q4, q0, q0
  #|0xef0086d8	VMINsv16i8 Reg:Q4 Reg:Q8 Reg:Q4 Imm:14 Reg:Nil | vmin.s8 q4, q8, q4
  #|0xef008701	VABDsv8i8 Reg:D8 Reg:D0 Reg:D1 Imm:14 Reg:Nil | vabd.s8 d8, d0, d1
  #|0xef008d50	VMLAfq Reg:Q4 Reg:Q4 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vmla.f32 q4, q0, q0
  #|0xef008f4e	VMAXfq Reg:Q4 Reg:Q0 Reg:Q7 Imm:14 Reg:Nil | vmax.f32 q4, q0, q7
  #|0xef00968c	VMAXsv8i8 Reg:D9 Reg:D16 Reg:D12 Imm:14 Reg:Nil | vmax.s8 d9, d16, d12
  #|0xef00a4f0	VQSHLsv16i8 Reg:Q5 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vqshl.s8 q5, q8, q8
  #|0xef00a5c0	VRSHLsv16i8 Reg:Q5 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vrshl.s8 q5, q0, q8
  #|0xef00c1d2	VANDq Reg:Q6 Reg:Q8 Reg:Q1 Imm:14 Reg:Nil | vand q6, q8, q1
  #|0xef00c3f6	VCGEsv16i8 Reg:Q6 Reg:Q8 Reg:Q11 Imm:14 Reg:Nil | vcge.s8 q6, q8, q11
  #|0xef00c593	VQRSHLsv8i8 Reg:D12 Reg:D3 Reg:D16 Imm:14 Reg:Nil | vqrshl.s8 d12, d3, d16
  #|0xef00ce06	VCEQfd Reg:D12 Reg:D0 Reg:D6 Imm:14 Reg:Nil | vceq.f32 d12, d0, d6
  #|0xef00db13	VPADDi8 Reg:D13 Reg:D0 Reg:D3 Imm:14 Reg:Nil | vpadd.i8 d13, d0, d3
  #|0xef00dd00	VADDfd Reg:D13 Reg:D0 Reg:D0 Imm:14 Reg:Nil | vadd.f32 d13, d0, d0
  #|0xef00e3c8	VCGTsv16i8 Reg:Q7 Reg:Q8 Reg:Q4 Imm:14 Reg:Nil | vcgt.s8 q7, q8, q4
  #|0xef00e5da	VQRSHLsv16i8 Reg:Q7 Reg:Q5 Reg:Q8 Imm:14 Reg:Nil | vqrshl.s8 q7, q5, q8
  #|0xef00ea30	VPMINs8 Reg:D14 Reg:D0 Reg:D16 Imm:14 Reg:Nil | vpmin.s8 d14, d0, d16
  #|0xef0104a5	VSHLsv8i8 Reg:D0 Reg:D21 Reg:D17 Imm:14 Reg:Nil | vshl.s8 d0, d21, d17
  #|0xef0297bb	VABAsv8i8 Reg:D9 Reg:D9 Reg:D18 Reg:D27 Imm:14 Reg:Nil | vaba.s8 d9, d18, d27
  #|0xef07198e	VMLAv8i8 Reg:D1 Reg:D1 Reg:D23 Reg:D14 Imm:14 Reg:Nil | vmla.i8 d1, d23, d14
  #|0xef09b100	VRHADDsv8i8 Reg:D11 Reg:D9 Reg:D0 Imm:14 Reg:Nil | vrhadd.s8 d11, d9, d0
  #|0xef0a580a	VADDv8i8 Reg:D5 Reg:D10 Reg:D10 Imm:14 Reg:Nil | vadd.i8 d5, d10, d10
  #|0xef0c2468	VSHLsv16i8 Reg:Q1 Reg:Q12 Reg:Q6 Imm:14 Reg:Nil | vshl.s8 q1, q12, q6
  #|0xef0e2a07	VPMAXs8 Reg:D2 Reg:D14 Reg:D7 Imm:14 Reg:Nil | vpmax.s8 d2, d14, d7
  #|0xef0e68f0	VTSTv16i8 Reg:Q3 Reg:Q15 Reg:Q8 Imm:14 Reg:Nil | vtst.8 q3, q15, q8
  #|0xef110214	VQSUBsv4i16 Reg:D0 Reg:D1 Reg:D4 Imm:14 Reg:Nil | vqsub.s16 d0, d1, d4
  #|0xef111792	VABAsv4i16 Reg:D1 Reg:D1 Reg:D17 Reg:D2 Imm:14 Reg:Nil | vaba.s16 d1, d17, d2
  #|0xef12035e	VCGEsv8i16 Reg:Q0 Reg:Q1 Reg:Q7 Imm:14 Reg:Nil | vcge.s16 q0, q1, q7
  #|0xef132800	VADDv4i16 Reg:D2 Reg:D3 Reg:D0 Imm:14 Reg:Nil | vadd.i16 d2, d3, d0
  #|0xef140460	VSHLsv8i16 Reg:Q0 Reg:Q8 Reg:Q2 Imm:14 Reg:Nil | vshl.s16 q0, q8, q2
  #|0xef149410	VQSHLsv4i16 Reg:D9 Reg:D0 Reg:D4 Imm:14 Reg:Nil | vqshl.s16 d9, d0, d4
  #|0xef14a896	VTSTv4i16 Reg:D10 Reg:D20 Reg:D6 Imm:14 Reg:Nil | vtst.16 d10, d20, d6
  #|0xef156320	VCGTsv4i16 Reg:D6 Reg:D5 Reg:D16 Imm:14 Reg:Nil | vcgt.s16 d6, d5, d16
  #|0xef16a270	VQSUBsv8i16 Reg:Q5 Reg:Q3 Reg:Q8 Imm:14 Reg:Nil | vqsub.s16 q5, q3, q8
  #|0xef18f206	VHSUBsv4i16 Reg:D15 Reg:D8 Reg:D6 Imm:14 Reg:Nil | vhsub.s16 d15, d8, d6
  #|0xef197705	VABDsv4i16 Reg:D7 Reg:D9 Reg:D5 Imm:14 Reg:Nil | vabd.s16 d7, d9, d5
  #|0xef19e5a2	VRSHLsv4i16 Reg:D14 Reg:D18 Reg:D25 Imm:14 Reg:Nil | vrshl.s16 d14, d18, d25
  #|0xef1a2a98	VPMINs16 Reg:D2 Reg:D26 Reg:D8 Imm:14 Reg:Nil | vpmin.s16 d2, d26, d8
  #|0xef1bd900	VMLAv4i16 Reg:D13 Reg:D13 Reg:D11 Reg:D0 Imm:14 Reg:Nil | vmla.i16 d13, d11, d0
  #|0xef1cebb0	VPADDi16 Reg:D14 Reg:D28 Reg:D16 Imm:14 Reg:Nil | vpadd.i16 d14, d28, d16
  #|0xef1e2007	VHADDsv4i16 Reg:D2 Reg:D14 Reg:D7 Imm:14 Reg:Nil | vhadd.s16 d2, d14, d7
  #|0xef20823b	VQSUBsv2i32 Reg:D8 Reg:D0 Reg:D27 Imm:14 Reg:Nil | vqsub.s32 d8, d0, d27
  #|0xef21fd0c	VSUBfd Reg:D15 Reg:D1 Reg:D12 Imm:14 Reg:Nil | vsub.f32 d15, d1, d12
  #|0xef222170	VORRq Reg:Q1 Reg:Q1 Reg:Q8 Imm:14 Reg:Nil | vorr q1, q1, q8
  #|0xef22691c	VMULv2i32 Reg:D6 Reg:D2 Reg:D12 Imm:14 Reg:Nil | vmul.i32 d6, d2, d12
  #|0xef23f603	VMAXsv2i32 Reg:D15 Reg:D3 Reg:D3 Imm:14 Reg:Nil | vmax.s32 d15, d3, d3
  #|0xef25eb90	VPADDi32 Reg:D14 Reg:D21 Reg:D0 Imm:14 Reg:Nil | vpadd.i32 d14, d21, d0
  #|0xef2609ec	VMLAv4i32 Reg:Q0 Reg:Q0 Reg:Q11 Reg:Q14 Imm:14 Reg:Nil | vmla.i32 q0, q11, q14
  #|0xef271f03	VMINfd Reg:D1 Reg:D7 Reg:D3 Imm:14 Reg:Nil | vmin.f32 d1, d7, d3
  #|0xef273101	VRHADDsv2i32 Reg:D3 Reg:D7 Reg:D1 Imm:14 Reg:Nil | vrhadd.s32 d3, d7, d1
  #|0xef281530	VQRSHLsv2i32 Reg:D1 Reg:D16 Reg:D8 Imm:14 Reg:Nil | vqrshl.s32 d1, d16, d8
  #|0xef282737	VABAsv2i32 Reg:D2 Reg:D2 Reg:D8 Reg:D23 Imm:14 Reg:Nil | vaba.s32 d2, d8, d23
  #|0xef284b21	VQDMULHv2i32 Reg:D4 Reg:D8 Reg:D17 Imm:14 Reg:Nil | vqdmulh.s32 d4, d8, d17
  #|0xef2a9d30	VMLSfd Reg:D9 Reg:D9 Reg:D10 Reg:D16 Imm:14 Reg:Nil | vmls.f32 d9, d10, d16
  #|0xef2c28fa	VTSTv4i32 Reg:Q1 Reg:Q14 Reg:Q13 Imm:14 Reg:Nil | vtst.32 q1, q14, q13
  #|0xef2dea10	VPMINs32 Reg:D14 Reg:D13 Reg:D0 Imm:14 Reg:Nil | vpmin.s32 d14, d13, d0
  #|0xef2ed783	VABDsv2i32 Reg:D13 Reg:D30 Reg:D3 Imm:14 Reg:Nil | vabd.s32 d13, d30, d3
  #|0xef353234	VQSUBsv1i64 Reg:D3 Reg:D5 Reg:D20 Imm:14 Reg:Nil | vqsub.s64 d3, d5, d20
  #|0xef37459f	VQRSHLsv1i64 Reg:D4 Reg:D15 Reg:D23 Imm:14 Reg:Nil | vqrshl.s64 d4, d15, d23
  #|0xef38003f	VQADDsv1i64 Reg:D0 Reg:D8 Reg:D31 Imm:14 Reg:Nil | vqadd.s64 d0, d8, d31
  #|0xef3b441f	VQSHLsv1i64 Reg:D4 Reg:D15 Reg:D11 Imm:14 Reg:Nil | vqshl.s64 d4, d15, d11
  #|0xef4253a0	VCGTsv8i8 Reg:D21 Reg:D18 Reg:D16 Imm:14 Reg:Nil | vcgt.s8 d21, d18, d16
  #|0xef42d43c	VQSHLsv8i8 Reg:D29 Reg:D28 Reg:D2 Imm:14 Reg:Nil | vqshl.s8 d29, d28, d2
  #|0xef505698	VMINsv4i16 Reg:D21 Reg:D16 Reg:D8 Imm:14 Reg:Nil | vmin.s16 d21, d16, d8
  #|0xef5400e0	VHADDsv8i16 Reg:Q8 Reg:Q10 Reg:Q8 Imm:14 Reg:Nil | vhadd.s16 q8, q10, q8
  #|0xef54e51c	VQRSHLsv4i16 Reg:D30 Reg:D12 Reg:D4 Imm:14 Reg:Nil | vqrshl.s16 d30, d12, d4
  #|0xef559b0d	VQDMULHv4i16 Reg:D25 Reg:D5 Reg:D13 Imm:14 Reg:Nil | vqdmulh.s16 d25, d5, d13
  #|0xef569400	VSHLsv4i16 Reg:D25 Reg:D0 Reg:D6 Imm:14 Reg:Nil | vshl.s16 d25, d0, d6
  #|0xef5700b4	VQADDsv4i16 Reg:D16 Reg:D23 Reg:D20 Imm:14 Reg:Nil | vqadd.s16 d16, d23, d20
  #|0xef5a9a00	VPMAXs16 Reg:D25 Reg:D10 Reg:D0 Imm:14 Reg:Nil | vpmax.s16 d25, d10, d0
  #|0xef5b8112	VBICd Reg:D24 Reg:D11 Reg:D2 Imm:14 Reg:Nil | vbic d24, d11, d2
  #|0xef5c3330	VCGEsv4i16 Reg:D19 Reg:D12 Reg:D16 Imm:14 Reg:Nil | vcge.s16 d19, d12, d16
  #|0xef5c46f0	VMINsv8i16 Reg:Q10 Reg:Q14 Reg:Q8 Imm:14 Reg:Nil | vmin.s16 q10, q14, q8
  #|0xef5cc101	VRHADDsv4i16 Reg:D28 Reg:D12 Reg:D1 Imm:14 Reg:Nil | vrhadd.s16 d28, d12, d1
  #|0xef5d89bd	VMULv4i16 Reg:D24 Reg:D29 Reg:D29 Imm:14 Reg:Nil | vmul.i16 d24, d29, d29
  #|0xef5d9603	VMAXsv4i16 Reg:D25 Reg:D13 Reg:D3 Imm:14 Reg:Nil | vmax.s16 d25, d13, d3
  #|0xef5e005c	VQADDsv8i16 Reg:Q8 Reg:Q7 Reg:Q6 Imm:14 Reg:Nil | vqadd.s16 q8, q7, q6
  #|0xef61889c	VTSTv2i32 Reg:D24 Reg:D17 Reg:D12 Imm:14 Reg:Nil | vtst.32 d24, d17, d12
  #|0xef620022	VHADDsv2i32 Reg:D16 Reg:D2 Reg:D18 Imm:14 Reg:Nil | vhadd.s32 d16, d2, d18
  #|0xef64a90c	VMLAv2i32 Reg:D26 Reg:D26 Reg:D4 Reg:D12 Imm:14 Reg:Nil | vmla.i32 d26, d4, d12
  #|0xef64df90	VRSQRTSfd Reg:D29 Reg:D20 Reg:D0 Imm:14 Reg:Nil | vrsqrts.f32 d29, d20, d0
  #|0xef6700b8	VQADDsv2i32 Reg:D16 Reg:D23 Reg:D24 Imm:14 Reg:Nil | vqadd.s32 d16, d23, d24
  #|0xef67069e	VMINsv2i32 Reg:D16 Reg:D23 Reg:D14 Imm:14 Reg:Nil | vmin.s32 d16, d23, d14
  #|0xef68b804	VADDv2i32 Reg:D27 Reg:D8 Reg:D4 Imm:14 Reg:Nil | vadd.i32 d27, d8, d4
  #|0xef6a2050	VQADDsv4i32 Reg:Q9 Reg:Q5 Reg:Q0 Imm:14 Reg:Nil | vqadd.s32 q9, q5, q0
  #|0xef6a9402	VSHLsv2i32 Reg:D25 Reg:D2 Reg:D10 Imm:14 Reg:Nil | vshl.s32 d25, d2, d10
  #|0xef6bfa0b	VPMAXs32 Reg:D31 Reg:D11 Reg:D11 Imm:14 Reg:Nil | vpmax.s32 d31, d11, d11
  #|0xef6c67c2	VABDsv4i32 Reg:Q11 Reg:Q14 Reg:Q1 Imm:14 Reg:Nil | vabd.s32 q11, q14, q1
  #|0xef6ce307	VCGTsv2i32 Reg:D30 Reg:D12 Reg:D7 Imm:14 Reg:Nil | vcgt.s32 d30, d12, d7
  #|0xef6ce558	VQRSHLsv4i32 Reg:Q15 Reg:Q4 Reg:Q6 Imm:14 Reg:Nil | vqrshl.s32 q15, q4, q6
  #|0xef6d0437	VQSHLsv2i32 Reg:D16 Reg:D23 Reg:D13 Imm:14 Reg:Nil | vqshl.s32 d16, d23, d13
  #|0xef6d1509	VRSHLsv2i32 Reg:D17 Reg:D9 Reg:D13 Imm:14 Reg:Nil | vrshl.s32 d17, d9, d13
  #|0xef6e0068	VHADDsv4i32 Reg:Q8 Reg:Q7 Reg:Q12 Imm:14 Reg:Nil | vhadd.s32 q8, q7, q12
  #|0xef6eb11c	VORRd Reg:D27 Reg:D14 Reg:D12 Imm:14 Reg:Nil | vorr d27, d14, d12
  #|0xef6ed280	VHSUBsv2i32 Reg:D29 Reg:D30 Reg:D0 Imm:14 Reg:Nil | vhsub.s32 d29, d30, d0
  #|0xef70e5a8	VRSHLsv1i64 Reg:D30 Reg:D24 Reg:D16 Imm:14 Reg:Nil | vrshl.s64 d30, d24, d16
  #|0xef723800	VADDv1i64 Reg:D19 Reg:D2 Reg:D0 Imm:14 Reg:Nil | vadd.i64 d19, d2, d0
  #|0xef740072	VQADDsv2i64 Reg:Q8 Reg:Q2 Reg:Q9 Imm:14 Reg:Nil | vqadd.s64 q8, q2, q9
  #|0xef7cc40f	VSHLsv1i64 Reg:D28 Reg:D15 Reg:D12 Imm:14 Reg:Nil | vshl.s64 d28, d15, d12
  #|0xef7da115	VORNd Reg:D26 Reg:D13 Reg:D5 Imm:14 Reg:Nil | vorn d26, d13, d5
  #|0xef8131b0	VSRAsv1i64 Reg:D3 Reg:D3 Reg:D16 Imm:63 Imm:14 Reg:Nil | vsra.s64 d3, d16, #63
  #|0xef820024	VADDLsv8i16 Reg:Q0 Reg:D2 Reg:D20 Imm:14 Reg:Nil | vaddl.s8 q0, d2, d20
  #|0xef830575	VBICiv4i32 Reg:Q0 Imm:5429 Reg:Q0 Imm:14 Reg:Nil | vbic.i32 q0, #0x350000
  #|0xef836a10	VMOVv4i16 Reg:D6 Imm:2608 Imm:14 Reg:Nil | vmov.i16 d6, #0x3000
  #|0xef83c51a	VORRiv2i32 Reg:D12 Imm:1338 Reg:D12 Imm:14 Reg:Nil | vorr.i32 d12, #0x3a0000
  #|0xef843b3d	VBICiv4i16 Reg:D3 Imm:6989 Reg:D3 Imm:14 Reg:Nil | vbic.i16 d3, #0x4d00
  #|0xef844751	VORRiv4i32 Reg:Q2 Imm:1857 Reg:Q2 Imm:14 Reg:Nil | vorr.i32 q2, #0x41000000
  #|0xef845c34	VMVNv2i32 Reg:D5 Imm:7236 Imm:14 Reg:Nil | vmvn.i32 d5, #0x44ff
  #|0xef85e134	VBICiv2i32 Reg:D14 Imm:4436 Reg:D14 Imm:14 Reg:Nil | vbic.i32 d14, #0x54
  #|0xef864507	VABALsv8i16 Reg:Q2 Reg:Q2 Reg:D6 Reg:D7 Imm:14 Reg:Nil | vabal.s8 q2, d6, d7
  #|0xef87001a	VMOVv2i32 Reg:D0 Imm:122 Imm:14 Reg:Nil | vmov.i32 d0, #0x7a
  #|0xef872d70	VMVNv4i32 Reg:Q1 Imm:7536 Imm:14 Reg:Nil | vmvn.i32 q1, #0x70ffff
  #|0xef87cf54	VMOVv4f32 Reg:Q6 Imm:3956 Imm:14 Reg:Nil | vmov.f32 q6, #1.250000e+00
  #|0xef884050	VSHRsv16i8 Reg:Q2 Reg:Q0 Imm:8 Imm:14 Reg:Nil | vshr.s8 q2, q0, #8
  #|0xef88e4aa	VADDHNv8i8 Reg:D14 Reg:Q12 Reg:Q13 Imm:14 Reg:Nil | vaddhn.i16 d14, q12, q13
  #|0xef890010	VSHRsv8i8 Reg:D0 Reg:D0 Imm:7 Imm:14 Reg:Nil | vshr.s8 d0, d0, #7
  #|0xef8a0100	VADDWsv8i16 Reg:Q0 Reg:Q5 Reg:D0 Imm:14 Reg:Nil | vaddw.s8 q0, q5, d0
  #|0xef8ac8a0	VMLALsv8i16 Reg:Q6 Reg:Q6 Reg:D26 Reg:D16 Imm:14 Reg:Nil | vmlal.s8 q6, d26, d16
  #|0xef8af620	VSUBHNv8i8 Reg:D15 Reg:Q5 Reg:Q8 Imm:14 Reg:Nil | vsubhn.i16 d15, q5, q8
  #|0xef8e00d4	VSHRsv2i64 Reg:Q0 Reg:Q2 Imm:50 Imm:14 Reg:Nil | vshr.s64 q0, q2, #50
  #|0xef8e0e00	VMULLp8 Reg:Q0 Reg:D14 Reg:D0 Imm:14 Reg:Nil | vmull.p8 q0, d14, d0
  #|0xef8ee70c	VABDLsv8i16 Reg:Q7 Reg:D14 Reg:D12 Imm:14 Reg:Nil | vabdl.s8 q7, d14, d12
  #|0xef8f4270	VRSHRsv16i8 Reg:Q2 Reg:Q8 Imm:1 Imm:14 Reg:Nil | vrshr.s8 q2, q8, #1
  #|0xef9047d6	VQSHLsiv2i64 Reg:Q2 Reg:Q3 Imm:16 Imm:14 Reg:Nil | vqshl.s64 q2, q3, #16
  #|0xef91628a	VSUBLsv4i32 Reg:Q3 Reg:D17 Reg:D10 Imm:14 Reg:Nil | vsubl.s16 q3, d17, d10
  #|0xef920009	VADDLsv4i32 Reg:Q0 Reg:D2 Reg:D9 Imm:14 Reg:Nil | vaddl.s16 q0, d2, d9
  #|0xef922989	VQDMLALv4i32 Reg:Q1 Reg:Q1 Reg:D18 Reg:D9 Imm:14 Reg:Nil | vqdmlal.s16 q1, d18, d9
  #|0xef959870	VRSHRNv4i16 Reg:D9 Reg:Q8 Imm:11 Imm:14 Reg:Nil | vrshrn.i32 d9, q8, #11
  #|0xef9604a0	VADDHNv4i16 Reg:D0 Reg:Q11 Reg:Q8 Imm:14 Reg:Nil | vaddhn.i32 d0, q11, q8
  #|0xef97d816	VSHRNv4i16 Reg:D13 Reg:Q3 Imm:9 Imm:14 Reg:Nil | vshrn.i32 d13, q3, #9
  #|0xef97f339	VRSRAsv4i16 Reg:D15 Reg:D15 Reg:D25 Imm:9 Imm:14 Reg:Nil | vrsra.s16 d15, d25, #9
  #|0xef98a578	VSHLiv8i16 Reg:Q5 Reg:Q12 Imm:8 Imm:14 Reg:Nil | vshl.i16 q5, q12, #8
  #|0xef98c7af	VABDLsv4i32 Reg:Q6 Reg:D24 Reg:D31 Imm:14 Reg:Nil | vabdl.s16 q6, d24, d31
  #|0xef9b2c8c	VMULLsv4i32 Reg:Q1 Reg:D27 Reg:D12 Imm:14 Reg:Nil | vmull.s16 q1, d27, d12
  #|0xef9c2b0f	VQDMLSLv4i32 Reg:Q1 Reg:Q1 Reg:D12 Reg:D15 Imm:14 Reg:Nil | vqdmlsl.s16 q1, d12, d15
  #|0xef9e00e8	VMLAslv4i16 Reg:D0 Reg:D0 Reg:D30 Reg:D0 Imm:3 Imm:14 Reg:Nil | vmla.i16 d0, d30, d0[3]
  #|0xef9e0dc8	VQRDMULHslv4i16 Reg:D0 Reg:D30 Reg:D0 Imm:1 Imm:14 Reg:Nil | vqrdmulh.s16 d0, d30, d0[1]
  #|0xef9f1860	VMULslv4i16 Reg:D1 Reg:D15 Reg:D0 Imm:2 Imm:14 Reg:Nil | vmul.i16 d1, d15, d0[2]
  #|0xefa30052	VSHRsv4i32 Reg:Q0 Reg:Q1 Imm:29 Imm:14 Reg:Nil | vshr.s32 q0, q1, #29
  #|0xefa38236	VRSHRsv2i32 Reg:D8 Reg:D22 Imm:29 Imm:14 Reg:Nil | vrshr.s32 d8, d22, #29
  #|0xefa4a84d	VMULslv2i32 Reg:D10 Reg:D4 Reg:D13 Imm:0 Imm:14 Reg:Nil | vmul.i32 d10, d4, d13[0]
  #|0xefa6000e	VADDLsv2i64 Reg:Q0 Reg:D6 Reg:D14 Imm:14 Reg:Nil | vaddl.s32 q0, d6, d14
  #|0xefa6e260	VMLALslsv2i32 Reg:Q7 Reg:Q7 Reg:D6 Reg:D0 Imm:1 Imm:14 Reg:Nil | vmlal.s32 q7, d6, d0[1]
  #|0xefa74130	VSRAsv2i32 Reg:D4 Reg:D4 Reg:D16 Imm:25 Imm:14 Reg:Nil | vsra.s32 d4, d16, #25
  #|0xefa769e0	VMULslfd Reg:D6 Reg:D23 Reg:D0 Imm:1 Imm:14 Reg:Nil | vmul.f32 d6, d23, d0[1]
  #|0xefab44c9	VMLSslv2i32 Reg:D4 Reg:D4 Reg:D27 Reg:D9 Imm:0 Imm:14 Reg:Nil | vmls.i32 d4, d27, d9[0]
  #|0xefad664e	VMLSLslsv2i32 Reg:Q3 Reg:Q3 Reg:D13 Reg:D14 Imm:0 Imm:14 Reg:Nil | vmlsl.s32 q3, d13, d14[0]
  #|0xefae1938	VQSHRNsv2i32 Reg:D1 Reg:Q12 Imm:18 Imm:14 Reg:Nil | vqshrn.s64 d1, q12, #18
  #|0xefae4303	VSUBWsv2i64 Reg:Q2 Reg:Q7 Reg:D3 Imm:14 Reg:Nil | vsubw.s32 q2, q7, d3
  #|0xefae7e3e	VCVTxs2fd Reg:D7 Reg:D30 Imm:18 Imm:14 Reg:Nil | vcvt.f32.s32 d7, d30, #18
  #|0xefaf45c0	VMLSslfd Reg:D4 Reg:D4 Reg:D31 Reg:D0 Imm:0 Imm:14 Reg:Nil | vmls.f32 d4, d31, d0[0]
  #|0xefaf4b00	VQDMLSLv2i64 Reg:Q2 Reg:Q2 Reg:D15 Reg:D0 Imm:14 Reg:Nil | vqdmlsl.s32 q2, d15, d0
  #|0xefaf5850	VRSHRNv2i32 Reg:D5 Reg:Q0 Imm:17 Imm:14 Reg:Nil | vrshrn.i64 d5, q0, #17
  #|0xefb006c0	VEXTq16 Reg:Q0 Reg:Q8 Reg:Q0 Imm:3 Imm:14 Reg:Nil | vext.16 q0, q8, q0, #3
  #|0xefb047ea	VEXTq8 Reg:Q2 Reg:Q8 Reg:Q13 Imm:7 Imm:14 Reg:Nil | vext.8 q2, q8, q13, #7
  #|0xefb42e50	VCVTxs2fq Reg:Q1 Reg:Q0 Imm:12 Imm:14 Reg:Nil | vcvt.f32.s32 q1, q0, #12
  #|0xefb5328a	VEXTd16 Reg:D3 Reg:D21 Reg:D10 Imm:1 Imm:14 Reg:Nil | vext.16 d3, d21, d10, #1
  #|0xefba0060	VEXTq64 Reg:Q0 Reg:Q5 Reg:Q8 Imm:0 Imm:14 Reg:Nil | vext.64 q0, q5, q8, #0
  #|0xefba3f10	VCVTf2xsd Reg:D3 Reg:D0 Imm:6 Imm:14 Reg:Nil | vcvt.s32.f32 d3, d0, #6
  #|0xefbcf702	VEXTd8 Reg:D15 Reg:D12 Reg:D2 Imm:7 Imm:14 Reg:Nil | vext.8 d15, d12, d2, #7
  #|0xefbf97b4	VQSHLsiv1i64 Reg:D9 Reg:D20 Imm:63 Imm:14 Reg:Nil | vqshl.s64 d9, d20, #63
  #|0xefc2c3d4	VRSRAsv2i64 Reg:Q14 Reg:Q14 Reg:Q2 Imm:62 Imm:14 Reg:Nil | vrsra.s64 q14, q2, #62
  #|0xefc3005e	VMOVv4i32 Reg:Q8 Imm:62 Imm:14 Reg:Nil | vmov.i32 q8, #0x3e
  #|0xefc52c86	VMULLsv8i16 Reg:Q9 Reg:D21 Reg:D6 Imm:14 Reg:Nil | vmull.s8 q9, d21, d6
  #|0xefc593b1	VRSRAsv1i64 Reg:D25 Reg:D25 Reg:D17 Imm:59 Imm:14 Reg:Nil | vrsra.s64 d25, d17, #59
  #|0xefc70b59	VORRiv8i16 Reg:Q8 Imm:2937 Reg:Q8 Imm:14 Reg:Nil | vorr.i16 q8, #0x7900
  #|0xefca8a1c	VSHLLsv8i16 Reg:Q12 Reg:D12 Imm:2 Imm:14 Reg:Nil | vshll.s8 q12, d12, #2
  #|0xefcaea00	VMLSLsv8i16 Reg:Q15 Reg:Q15 Reg:D10 Reg:D0 Imm:14 Reg:Nil | vmlsl.s8 q15, d10, d0
  #|0xefcc2310	VRSRAsv8i8 Reg:D18 Reg:D18 Reg:D0 Imm:4 Imm:14 Reg:Nil | vrsra.s8 d18, d0, #4
  #|0xefcc823e	VRSHRsv8i8 Reg:D24 Reg:D30 Imm:4 Imm:14 Reg:Nil | vrshr.s8 d24, d30, #4
  #|0xefd3121a	VRSHRsv4i16 Reg:D17 Reg:D10 Imm:13 Imm:14 Reg:Nil | vrshr.s16 d17, d10, #13
  #|0xefd32131	VSRAsv4i16 Reg:D18 Reg:D18 Reg:D17 Imm:13 Imm:14 Reg:Nil | vsra.s16 d18, d17, #13
  #|0xefd374cd	VMLSslv4i16 Reg:D23 Reg:D23 Reg:D19 Reg:D5 Imm:1 Imm:14 Reg:Nil | vmls.i16 d23, d19, d5[1]
  #|0xefd48a09	VMLSLsv4i32 Reg:Q12 Reg:Q12 Reg:D4 Reg:D9 Imm:14 Reg:Nil | vmlsl.s16 q12, d4, d9
  #|0xefd51974	VQRSHRNsv4i16 Reg:D17 Reg:Q10 Imm:11 Imm:14 Reg:Nil | vqrshrn.s32 d17, q10, #11
  #|0xefd5a532	VSHLiv4i16 Reg:D26 Reg:D18 Imm:5 Imm:14 Reg:Nil | vshl.i16 d26, d18, #5
  #|0xefd5c800	VMLALsv4i32 Reg:Q14 Reg:Q14 Reg:D5 Reg:D0 Imm:14 Reg:Nil | vmlal.s16 q14, d5, d0
  #|0xefd6001d	VSHRsv4i16 Reg:D16 Reg:D13 Imm:10 Imm:14 Reg:Nil | vshr.s16 d16, d13, #10
  #|0xefd60327	VSUBWsv4i32 Reg:Q8 Reg:Q3 Reg:D23 Imm:14 Reg:Nil | vsubw.s16 q8, q3, d23
  #|0xefd745be	VSHLiv1i64 Reg:D20 Reg:D30 Imm:23 Imm:14 Reg:Nil | vshl.i64 d20, d30, #23
  #|0xefdae626	VSUBHNv4i16 Reg:D30 Reg:Q5 Reg:Q11 Imm:14 Reg:Nil | vsubhn.i32 d30, q5, q11
  #|0xefdb21da	VSRAsv2i64 Reg:Q9 Reg:Q9 Reg:Q5 Imm:37 Imm:14 Reg:Nil | vsra.s64 q9, q5, #37
  #|0xefdc0054	VSHRsv8i16 Reg:Q8 Reg:Q2 Imm:4 Imm:14 Reg:Nil | vshr.s16 q8, q2, #4
  #|0xefdc8a11	VSHLLsv4i32 Reg:Q12 Reg:D1 Imm:12 Imm:14 Reg:Nil | vshll.s16 q12, d1, #12
  #|0xefdd0346	VQDMLALslv4i16 Reg:Q8 Reg:Q8 Reg:D13 Reg:D6 Imm:0 Imm:14 Reg:Nil | vqdmlal.s16 q8, d13, d6[0]
  #|0xefdd0350	VRSRAsv8i16 Reg:Q8 Reg:Q8 Reg:Q0 Imm:3 Imm:14 Reg:Nil | vrsra.s16 q8, q0, #3
  #|0xefdda664	VMLSLslsv4i16 Reg:Q13 Reg:Q13 Reg:D13 Reg:D4 Imm:2 Imm:14 Reg:Nil | vmlsl.s16 q13, d13, d4[2]
  #|0xefde8c6c	VQDMULHslv4i16 Reg:D24 Reg:D14 Reg:D4 Imm:3 Imm:14 Reg:Nil | vqdmulh.s16 d24, d14, d4[3]
  #|0xefdfada0	VQDMULLv4i32 Reg:Q13 Reg:D31 Reg:D16 Imm:14 Reg:Nil | vqdmull.s16 q13, d31, d16
  #|0xefe0080a	VMLALsv2i64 Reg:Q8 Reg:Q8 Reg:D0 Reg:D10 Imm:14 Reg:Nil | vmlal.s32 q8, d0, d10
  #|0xefe0c0ec	VMLAslv2i32 Reg:D28 Reg:D28 Reg:D16 Reg:D12 Imm:1 Imm:14 Reg:Nil | vmla.i32 d28, d16, d12[1]
  #|0xefe26717	VQSHLsiv2i32 Reg:D22 Reg:D7 Imm:2 Imm:14 Reg:Nil | vqshl.s32 d22, d7, #2
  #|0xefe2c50a	VABALsv2i64 Reg:Q14 Reg:Q14 Reg:D2 Reg:D10 Imm:14 Reg:Nil | vabal.s32 q14, d2, d10
  #|0xefe36350	VRSRAsv4i32 Reg:Q11 Reg:Q11 Reg:Q0 Imm:29 Imm:14 Reg:Nil | vrsra.s32 q11, q0, #29
  #|0xefe38200	VSUBLsv2i64 Reg:Q12 Reg:D3 Reg:D0 Imm:14 Reg:Nil | vsubl.s32 q12, d3, d0
  #|0xefe3ea16	VSHLLsv2i64 Reg:Q15 Reg:D6 Imm:3 Imm:14 Reg:Nil | vshll.s32 q15, d6, #3
  #|0xefe49d4d	VQRDMULHslv2i32 Reg:D25 Reg:D4 Reg:D13 Imm:0 Imm:14 Reg:Nil | vqrdmulh.s32 d25, d4, d13[0]
  #|0xefe54a88	VMLSLsv2i64 Reg:Q10 Reg:Q10 Reg:D21 Reg:D8 Imm:14 Reg:Nil | vmlsl.s32 q10, d21, d8
  #|0xefe64c25	VMULLsv2i64 Reg:Q10 Reg:D6 Reg:D21 Imm:14 Reg:Nil | vmull.s32 q10, d6, d21
  #|0xefe6c340	VQDMLALslv2i32 Reg:Q14 Reg:Q14 Reg:D6 Reg:D0 Imm:0 Imm:14 Reg:Nil | vqdmlal.s32 q14, d6, d0[0]
  #|0xefe6ecc0	VQDMULHslv2i32 Reg:D30 Reg:D22 Reg:D0 Imm:0 Imm:14 Reg:Nil | vqdmulh.s32 d30, d22, d0[0]
  #|0xefe8c90a	VQDMLALv2i64 Reg:Q14 Reg:Q14 Reg:D8 Reg:D10 Imm:14 Reg:Nil | vqdmlal.s32 q14, d8, d10
  #|0xefe92d0b	VQDMULLv2i64 Reg:Q9 Reg:D9 Reg:D11 Imm:14 Reg:Nil | vqdmull.s32 q9, d9, d11
  #|0xefeb009e	VSHRsv1i64 Reg:D16 Reg:D14 Imm:21 Imm:14 Reg:Nil | vshr.s64 d16, d14, #21
  #|0xefebe5d2	VSHLiv2i64 Reg:Q15 Reg:Q1 Imm:43 Imm:14 Reg:Nil | vshl.i64 q15, q1, #43
  #|0xefec0420	VADDHNv2i32 Reg:D16 Reg:Q6 Reg:Q8 Imm:14 Reg:Nil | vaddhn.i64 d16, q6, q8
  #|0xefec1530	VSHLiv2i32 Reg:D17 Reg:D16 Imm:12 Imm:14 Reg:Nil | vshl.i32 d17, d16, #12
  #|0xefed0031	VSHRsv2i32 Reg:D16 Reg:D17 Imm:19 Imm:14 Reg:Nil | vshr.s32 d16, d17, #19
  #|0xefef91e0	VMLAslfd Reg:D25 Reg:D25 Reg:D31 Reg:D0 Imm:1 Imm:14 Reg:Nil | vmla.f32 d25, d31, d0[1]
  #|0xeff100a0	VEXTd32 Reg:D16 Reg:D17 Reg:D16 Imm:0 Imm:14 Reg:Nil | vext.32 d16, d17, d16, #0
  #|0xeff62836	VSHRNv2i32 Reg:D18 Reg:Q11 Imm:10 Imm:14 Reg:Nil | vshrn.i64 d18, q11, #10
  #|0xeff80f54	VCVTf2xsq Reg:Q8 Reg:Q2 Imm:8 Imm:14 Reg:Nil | vcvt.s32.f32 q8, q2, #8
  #|0xeff8b972	VQRSHRNsv2i32 Reg:D27 Reg:Q9 Imm:8 Imm:14 Reg:Nil | vqrshrn.s64 d27, q9, #8
  #|0xeffaa550	VSHLiv4i32 Reg:Q13 Reg:Q0 Imm:26 Imm:14 Reg:Nil | vshl.i32 q13, q0, #26
  #|0xefff42bb	VRSHRsv1i64 Reg:D20 Reg:D27 Imm:1 Imm:14 Reg:Nil | vrshr.s64 d20, d27, #1
  #|0xf3030000	t2SSAT Reg:R0 Imm:0 Reg:R3 Imm:0 Imm:14 Reg:Nil | ssat r0, #1, r3
  #|0xf306109f	t2SSAT Reg:R0 Imm:31 Reg:R6 Imm:6 Imm:14 Reg:Nil | ssat r0, #32, r6, lsl #6
  #|0xf32700c0	t2SSAT Reg:R0 Imm:0 Reg:R7 Imm:35 Imm:14 Reg:Nil | ssat r0, #1, r7, asr #3
  #|0xf32e0709	t2SSAT16 Reg:R7 Imm:9 Reg:LR Imm:14 Reg:Nil | ssat16 r7, #10, lr
  #|0xf3400d20	t2SBFX Reg:SP Reg:R0 Imm:0 Imm:0 Imm:14 Reg:Nil | sbfx sp, r0, #0, #1
  #|0xf3800f1a	t2USAT Reg:PC Imm:26 Reg:R0 Imm:0 Imm:14 Reg:Nil | usat pc, #26, r0 | affect_cf
  #|0xf3880282	t2USAT Reg:R2 Imm:2 Reg:R8 Imm:2 Imm:14 Reg:Nil | usat r2, #2, r8, lsl #2
  #|0xf3a10bc3	t2USAT Reg:R11 Imm:3 Reg:R1 Imm:35 Imm:14 Reg:Nil | usat r11, #3, r1, asr #3
  #|0xf3a90500	t2USAT16 Reg:R5 Imm:0 Reg:R9 Imm:14 Reg:Nil | usat16 r5, #0, r9
  #|0xf3c20332	t2UBFX Reg:R3 Reg:R2 Imm:0 Imm:18 Imm:14 Reg:Nil | ubfx r3, r2, #0, #19
  #|0xf7f0a4a2	t2UDF Imm:1186 | udf.w #1186 | may_load,may_store
  #|0xf800ce00	t2STRBT Reg:R12 Reg:R0 Imm:0 Imm:14 Reg:Nil | strbt r12, [r0] | may_store
  #|0xf8043e17	t2STRBT Reg:R3 Reg:R4 Imm:23 Imm:14 Reg:Nil | strbt r3, [r4, #23] | may_store
  #|0xf8160e00	t2LDRBT Reg:R0 Reg:R6 Imm:0 Imm:14 Reg:Nil | ldrbt r0, [r6]
  #|0xf81b2e82	t2LDRBT Reg:R2 Reg:R11 Imm:130 Imm:14 Reg:Nil | ldrbt r2, [r11, #130]
  #|0xf8207e58	t2STRHT Reg:R7 Reg:R0 Imm:88 Imm:14 Reg:Nil | strht r7, [r0, #88] | may_store
  #|0xf8267e00	t2STRHT Reg:R7 Reg:R6 Imm:0 Imm:14 Reg:Nil | strht r7, [r6] | may_store
  #|0xf8307eee	t2LDRHT Reg:R7 Reg:R0 Imm:238 Imm:14 Reg:Nil | ldrht r7, [r0, #238]
  #|0xf832ee00	t2LDRHT Reg:LR Reg:R2 Imm:0 Imm:14 Reg:Nil | ldrht lr, [r2]
  #|0xf840ce69	t2STRT Reg:R12 Reg:R0 Imm:105 Imm:14 Reg:Nil | strt r12, [r0, #105] | may_store
  #|0xf84afe00	t2STRT Reg:PC Reg:R10 Imm:0 Imm:14 Reg:Nil | strt pc, [r10] | may_store
  #|0xf8535e32	t2LDRT Reg:R5 Reg:R3 Imm:50 Imm:14 Reg:Nil | ldrt r5, [r3, #50]
  #|0xf8580e00	t2LDRT Reg:R0 Reg:R8 Imm:0 Imm:14 Reg:Nil | ldrt r0, [r8]
  #|0xf900000d	VST4d8_UPD Reg:R0 Reg:R0 Imm:0 Reg:Nil Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.8 {d0, d1, d2, d3}, [r0]! | may_store
  #|0xf900000f	VST4d8 Reg:R0 Imm:0 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.8 {d0, d1, d2, d3}, [r0] | may_store
  #|0xf900003d	VST4d8_UPD Reg:R0 Reg:R0 Imm:32 Reg:Nil Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.8 {d0, d1, d2, d3}, [r0:256]! | may_store
  #|0xf9000040	VST4d16_UPD Reg:R0 Reg:R0 Imm:0 Reg:R0 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.16 {d0, d1, d2, d3}, [r0], r0 | may_store
  #|0xf900004f	VST4d16 Reg:R0 Imm:0 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.16 {d0, d1, d2, d3}, [r0] | may_store
  #|0xf900005f	VST4d16 Reg:R0 Imm:8 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.16 {d0, d1, d2, d3}, [r0:64] | may_store
  #|0xf900007e	VST4d16_UPD Reg:R0 Reg:R0 Imm:32 Reg:LR Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.16 {d0, d1, d2, d3}, [r0:256], lr | may_store
  #|0xf900009c	VST4d32_UPD Reg:R0 Reg:R0 Imm:8 Reg:R12 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.32 {d0, d1, d2, d3}, [r0:64], r12 | may_store
  #|0xf900009d	VST4d32_UPD Reg:R0 Reg:R0 Imm:8 Reg:Nil Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.32 {d0, d1, d2, d3}, [r0:64]! | may_store
  #|0xf90000bf	VST4d32 Reg:R0 Imm:32 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.32 {d0, d1, d2, d3}, [r0:256] | may_store
  #|0xf900064e	VST1d16Twb_register Imm:0 Reg:R0 Imm:0 Reg:LR Reg:D0 Imm:14 Reg:Nil | vst1.16 {d0, d1, d2}, [r0], lr | may_store
  #|0xf90006c0	VST1d64Twb_register Imm:0 Reg:R0 Imm:0 Reg:R0 Reg:D0 Imm:14 Reg:Nil | vst1.64 {d0, d1, d2}, [r0], r0 | may_store
  #|0xf900090d	VST2b8wb_fixed Imm:0 Reg:R0 Imm:0 Reg:D0_D2 Imm:14 Reg:Nil | vst2.8 {d0, d2}, [r0]! | may_store
  #|0xf9001380	VST2q32wb_register Imm:0 Reg:R0 Imm:0 Reg:R0 Reg:D1 Imm:14 Reg:Nil | vst2.32 {d1, d2, d3, d4}, [r0], r0 | may_store
  #|0xf900148f	VST3d32 Reg:R0 Imm:0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst3.32 {d1, d2, d3}, [r0] | may_store
  #|0xf900161b	VST1d8Twb_register Imm:0 Reg:R0 Imm:8 Reg:R11 Reg:D1 Imm:14 Reg:Nil | vst1.8 {d1, d2, d3}, [r0:64], r11 | may_store
  #|0xf900186f	VST2d16 Reg:R0 Imm:16 Reg:D1_D2 Imm:14 Reg:Nil | vst2.16 {d1, d2}, [r0:128] | may_store
  #|0xf9001944	VST2b16wb_register Imm:0 Reg:R0 Imm:0 Reg:R4 Reg:D1_D3 Imm:14 Reg:Nil | vst2.16 {d1, d3}, [r0], r4 | may_store
  #|0xf9001a23	VST1q8wb_register Imm:0 Reg:R0 Imm:16 Reg:R3 Reg:D1_D2 Imm:14 Reg:Nil | vst1.8 {d1, d2}, [r0:128], r3 | may_store
  #|0xf9002124	VST4q8_UPD Reg:R0 Reg:R0 Imm:16 Reg:R4 Reg:D2 Reg:D4 Reg:D6 Reg:D8 Imm:14 Reg:Nil | vst4.8 {d2, d4, d6, d8}, [r0:128], r4 | may_store
  #|0xf900228b	VST1d32Qwb_register Imm:0 Reg:R0 Imm:0 Reg:R11 Reg:D2 Imm:14 Reg:Nil | vst1.32 {d2, d3, d4, d5}, [r0], r11 | may_store
  #|0xf9002410	VST3d8_UPD Reg:R0 Reg:R0 Imm:8 Reg:R0 Reg:D2 Reg:D3 Reg:D4 Imm:14 Reg:Nil | vst3.8 {d2, d3, d4}, [r0:64], r0 | may_store
  #|0xf900269f	VST1d32T Reg:R0 Imm:8 Reg:D2 Imm:14 Reg:Nil | vst1.32 {d2, d3, d4}, [r0:64] | may_store
  #|0xf9002850	VST2d16wb_register Imm:0 Reg:R0 Imm:8 Reg:R0 Reg:Q1 Imm:14 Reg:Nil | vst2.16 {d2, d3}, [r0:64], r0 | may_store
  #|0xf9002905	VST2b8wb_register Imm:0 Reg:R0 Imm:0 Reg:R5 Reg:D2_D4 Imm:14 Reg:Nil | vst2.8 {d2, d4}, [r0], r5 | may_store
  #|0xf9002a5e	VST1q16wb_register Imm:0 Reg:R0 Imm:8 Reg:LR Reg:Q1 Imm:14 Reg:Nil | vst1.16 {d2, d3}, [r0:64], lr | may_store
  #|0xf900301a	VST4d8_UPD Reg:R0 Reg:R0 Imm:8 Reg:R10 Reg:D3 Reg:D4 Reg:D5 Reg:D6 Imm:14 Reg:Nil | vst4.8 {d3, d4, d5, d6}, [r0:64], r10 | may_store
  #|0xf9003890	VST2d32wb_register Imm:0 Reg:R0 Imm:8 Reg:R0 Reg:D3_D4 Imm:14 Reg:Nil | vst2.32 {d3, d4}, [r0:64], r0 | may_store
  #|0xf90042cf	VST1d64Q Reg:R0 Imm:0 Reg:D4 Imm:14 Reg:Nil | vst1.64 {d4, d5, d6, d7}, [r0] | may_store
  #|0xf900439f	VST2q32 Reg:R0 Imm:8 Reg:D4 Imm:14 Reg:Nil | vst2.32 {d4, d5, d6, d7}, [r0:64] | may_store
  #|0xf9004999	VST2b32wb_register Imm:0 Reg:R0 Imm:8 Reg:R9 Reg:D4_D6 Imm:14 Reg:Nil | vst2.32 {d4, d6}, [r0:64], r9 | may_store
  #|0xf9005141	VST4q16_UPD Reg:R0 Reg:R0 Imm:0 Reg:R1 Reg:D5 Reg:D7 Reg:D9 Reg:D11 Imm:14 Reg:Nil | vst4.16 {d5, d7, d9, d11}, [r0], r1 | may_store
  #|0xf9005509	VST3q8_UPD Reg:R0 Reg:R0 Imm:0 Reg:R9 Reg:D5 Reg:D7 Reg:D9 Imm:14 Reg:Nil | vst3.8 {d5, d7, d9}, [r0], r9 | may_store
  #|0xf9005a0e	VST1q8wb_register Imm:0 Reg:R0 Imm:0 Reg:LR Reg:D5_D6 Imm:14 Reg:Nil | vst1.8 {d5, d6}, [r0], lr | may_store
  #|0xf900674a	VST1d16wb_register Imm:0 Reg:R0 Imm:0 Reg:R10 Reg:D6 Imm:14 Reg:Nil | vst1.16 {d6}, [r0], r10 | may_store
  #|0xf9006820	VST2d8wb_register Imm:0 Reg:R0 Imm:16 Reg:R0 Reg:Q3 Imm:14 Reg:Nil | vst2.8 {d6, d7}, [r0:128], r0 | may_store
  #|0xf900689f	VST2d32 Reg:R0 Imm:8 Reg:Q3 Imm:14 Reg:Nil | vst2.32 {d6, d7}, [r0:64] | may_store
  #|0xf900690f	VST2b8 Reg:R0 Imm:0 Reg:D6_D8 Imm:14 Reg:Nil | vst2.8 {d6, d8}, [r0] | may_store
  #|0xf9007220	VST1d8Qwb_register Imm:0 Reg:R0 Imm:16 Reg:R0 Reg:D7 Imm:14 Reg:Nil | vst1.8 {d7, d8, d9, d10}, [r0:128], r0 | may_store
  #|0xf900738f	VST2q32 Reg:R0 Imm:0 Reg:D7 Imm:14 Reg:Nil | vst2.32 {d7, d8, d9, d10}, [r0] | may_store
  #|0xf900754f	VST3q16 Reg:R0 Imm:0 Reg:D7 Reg:D9 Reg:D11 Imm:14 Reg:Nil | vst3.16 {d7, d9, d11}, [r0] | may_store
  #|0xf9007790	VST1d32wb_register Imm:0 Reg:R0 Imm:8 Reg:R0 Reg:D7 Imm:14 Reg:Nil | vst1.32 {d7}, [r0:64], r0 | may_store
  #|0xf9007a0f	VST1q8 Reg:R0 Imm:0 Reg:D7_D8 Imm:14 Reg:Nil | vst1.8 {d7, d8}, [r0] | may_store
  #|0xf900810a	VST4q8_UPD Reg:R0 Reg:R0 Imm:0 Reg:R10 Reg:D8 Reg:D10 Reg:D12 Reg:D14 Imm:14 Reg:Nil | vst4.8 {d8, d10, d12, d14}, [r0], r10 | may_store
  #|0xf9008559	VST3q16_UPD Reg:R0 Reg:R0 Imm:8 Reg:R9 Reg:D8 Reg:D10 Reg:D12 Imm:14 Reg:Nil | vst3.16 {d8, d10, d12}, [r0:64], r9 | may_store
  #|0xf900858d	VST3q32_UPD Reg:R0 Reg:R0 Imm:0 Reg:Nil Reg:D8 Reg:D10 Reg:D12 Imm:14 Reg:Nil | vst3.32 {d8, d10, d12}, [r0]! | may_store
  #|0xf900868b	VST1d32Twb_register Imm:0 Reg:R0 Imm:0 Reg:R11 Reg:D8 Imm:14 Reg:Nil | vst1.32 {d8, d9, d10}, [r0], r11 | may_store
  #|0xf9009202	VST1d8Qwb_register Imm:0 Reg:R0 Imm:0 Reg:R2 Reg:D9 Imm:14 Reg:Nil | vst1.8 {d9, d10, d11, d12}, [r0], r2 | may_store
  #|0xf900948d	VST3d32_UPD Reg:R0 Reg:R0 Imm:0 Reg:Nil Reg:D9 Reg:D10 Reg:D11 Imm:14 Reg:Nil | vst3.32 {d9, d10, d11}, [r0]! | may_store
  #|0xf900960f	VST1d8T Reg:R0 Imm:0 Reg:D9 Imm:14 Reg:Nil | vst1.8 {d9, d10, d11}, [r0] | may_store
  #|0xf9009652	VST1d16Twb_register Imm:0 Reg:R0 Imm:8 Reg:R2 Reg:D9 Imm:14 Reg:Nil | vst1.16 {d9, d10, d11}, [r0:64], r2 | may_store
  #|0xf9009911	VST2b8wb_register Imm:0 Reg:R0 Imm:8 Reg:R1 Reg:D9_D11 Imm:14 Reg:Nil | vst2.8 {d9, d11}, [r0:64], r1 | may_store
  #|0xf900992d	VST2b8wb_fixed Imm:0 Reg:R0 Imm:16 Reg:D9_D11 Imm:14 Reg:Nil | vst2.8 {d9, d11}, [r0:128]! | may_store
  #|0xf9009ad2	VST1q64wb_register Imm:0 Reg:R0 Imm:8 Reg:R2 Reg:D9_D10 Imm:14 Reg:Nil | vst1.64 {d9, d10}, [r0:64], r2 | may_store
  #|0xf900a05d	VST4d16_UPD Reg:R0 Reg:R0 Imm:8 Reg:Nil Reg:D10 Reg:D11 Reg:D12 Reg:D13 Imm:14 Reg:Nil | vst4.16 {d10, d11, d12, d13}, [r0:64]! | may_store
  #|0xf900a13d	VST4q8_UPD Reg:R0 Reg:R0 Imm:32 Reg:Nil Reg:D10 Reg:D12 Reg:D14 Reg:D16 Imm:14 Reg:Nil | vst4.8 {d10, d12, d14, d16}, [r0:256]! | may_store
  #|0xf900a190	VST4q32_UPD Reg:R0 Reg:R0 Imm:8 Reg:R0 Reg:D10 Reg:D12 Reg:D14 Reg:D16 Imm:14 Reg:Nil | vst4.32 {d10, d12, d14, d16}, [r0:64], r0 | may_store
  #|0xf900a65f	VST1d16T Reg:R0 Imm:8 Reg:D10 Imm:14 Reg:Nil | vst1.16 {d10, d11, d12}, [r0:64] | may_store
  #|0xf900a781	VST1d32wb_register Imm:0 Reg:R0 Imm:0 Reg:R1 Reg:D10 Imm:14 Reg:Nil | vst1.32 {d10}, [r0], r1 | may_store
  #|0xf900a7c0	VST1d64wb_register Imm:0 Reg:R0 Imm:0 Reg:R0 Reg:D10 Imm:14 Reg:Nil | vst1.64 {d10}, [r0], r0 | may_store
  #|0xf900b541	VST3q16_UPD Reg:R0 Reg:R0 Imm:0 Reg:R1 Reg:D11 Reg:D13 Reg:D15 Imm:14 Reg:Nil | vst3.16 {d11, d13, d15}, [r0], r1 | may_store
  #|0xf900b58c	VST3q32_UPD Reg:R0 Reg:R0 Imm:0 Reg:R12 Reg:D11 Reg:D13 Reg:D15 Imm:14 Reg:Nil | vst3.32 {d11, d13, d15}, [r0], r12 | may_store
  #|0xf900b70f	VST1d8 Reg:R0 Imm:0 Reg:D11 Imm:14 Reg:Nil | vst1.8 {d11}, [r0] | may_store
  #|0xf900d189	VST4q32_UPD Reg:R0 Reg:R0 Imm:0 Reg:R9 Reg:D13 Reg:D15 Reg:D17 Reg:D19 Imm:14 Reg:Nil | vst4.32 {d13, d15, d17, d19}, [r0], r9 | may_store
  #|0xf900d2c0	VST1d64Qwb_register Imm:0 Reg:R0 Imm:0 Reg:R0 Reg:D13 Imm:14 Reg:Nil | vst1.64 {d13, d14, d15, d16}, [r0], r0 | may_store
  #|0xf900d31d	VST2q8wb_fixed Imm:0 Reg:R0 Imm:8 Reg:D13 Imm:14 Reg:Nil | vst2.8 {d13, d14, d15, d16}, [r0:64]! | may_store
  #|0xf900d347	VST2q16wb_register Imm:0 Reg:R0 Imm:0 Reg:R7 Reg:D13 Imm:14 Reg:Nil | vst2.16 {d13, d14, d15, d16}, [r0], r7 | may_store
  #|0xf900d498	VST3d32_UPD Reg:R0 Reg:R0 Imm:8 Reg:R8 Reg:D13 Reg:D14 Reg:D15 Imm:14 Reg:Nil | vst3.32 {d13, d14, d15}, [r0:64], r8 | may_store
  #|0xf900da0d	VST1q8wb_fixed Imm:0 Reg:R0 Imm:0 Reg:D13_D14 Imm:14 Reg:Nil | vst1.8 {d13, d14}, [r0]! | may_store
  #|0xf900e304	VST2q8wb_register Imm:0 Reg:R0 Imm:0 Reg:R4 Reg:D14 Imm:14 Reg:Nil | vst2.8 {d14, d15, d16, d17}, [r0], r4 | may_store
  #|0xf900f21d	VST1d8Qwb_fixed Imm:0 Reg:R0 Imm:8 Reg:D15 Imm:14 Reg:Nil | vst1.8 {d15, d16, d17, d18}, [r0:64]! | may_store
  #|0xf900f270	VST1d16Qwb_register Imm:0 Reg:R0 Imm:32 Reg:R0 Reg:D15 Imm:14 Reg:Nil | vst1.16 {d15, d16, d17, d18}, [r0:256], r0 | may_store
  #|0xf900f34f	VST2q16 Reg:R0 Imm:0 Reg:D15 Imm:14 Reg:Nil | vst2.16 {d15, d16, d17, d18}, [r0] | may_store
  #|0xf900f590	VST3q32_UPD Reg:R0 Reg:R0 Imm:8 Reg:R0 Reg:D15 Reg:D17 Reg:D19 Imm:14 Reg:Nil | vst3.32 {d15, d17, d19}, [r0:64], r0 | may_store
  #|0xf900f96f	VST2b16 Reg:R0 Imm:16 Reg:D15_D17 Imm:14 Reg:Nil | vst2.16 {d15, d17}, [r0:128] | may_store
  #|0xf900fa8e	VST1q32wb_register Imm:0 Reg:R0 Imm:0 Reg:LR Reg:D15_D16 Imm:14 Reg:Nil | vst1.32 {d15, d16}, [r0], lr | may_store
  #|0xf90132ea	VST1d64Qwb_register Imm:0 Reg:R1 Imm:16 Reg:R10 Reg:D3 Imm:14 Reg:Nil | vst1.64 {d3, d4, d5, d6}, [r1:128], r10 | may_store
  #|0xf90179af	VST2b32 Reg:R1 Imm:16 Reg:D7_D9 Imm:14 Reg:Nil | vst2.32 {d7, d9}, [r1:128] | may_store
  #|0xf902008d	VST4d32_UPD Reg:R2 Reg:R2 Imm:0 Reg:Nil Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vst4.32 {d0, d1, d2, d3}, [r2]! | may_store
  #|0xf9038240	VST1d16Qwb_register Imm:0 Reg:R3 Imm:0 Reg:R0 Reg:D8 Imm:14 Reg:Nil | vst1.16 {d8, d9, d10, d11}, [r3], r0 | may_store
  #|0xf903d10f	VST4q8 Reg:R3 Imm:0 Reg:D13 Reg:D15 Reg:D17 Reg:D19 Imm:14 Reg:Nil | vst4.8 {d13, d15, d17, d19}, [r3] | may_store
  #|0xf9045a40	VST1q16wb_register Imm:0 Reg:R4 Imm:0 Reg:R0 Reg:D5_D6 Imm:14 Reg:Nil | vst1.16 {d5, d6}, [r4], r0 | may_store
  #|0xf90596dd	VST1d64Twb_fixed Imm:0 Reg:R5 Imm:8 Reg:D9 Imm:14 Reg:Nil | vst1.64 {d9, d10, d11}, [r5:64]! | may_store
  #|0xf908648e	VST3d32_UPD Reg:R8 Reg:R8 Imm:0 Reg:LR Reg:D6 Reg:D7 Reg:D8 Imm:14 Reg:Nil | vst3.32 {d6, d7, d8}, [r8], lr | may_store
  #|0xf908b756	VST1d16wb_register Imm:0 Reg:R8 Imm:8 Reg:R6 Reg:D11 Imm:14 Reg:Nil | vst1.16 {d11}, [r8:64], r6 | may_store
  #|0xf909240d	VST3d8_UPD Reg:R9 Reg:R9 Imm:0 Reg:Nil Reg:D2 Reg:D3 Reg:D4 Imm:14 Reg:Nil | vst3.8 {d2, d3, d4}, [r9]! | may_store
  #|0xf909c7d1	VST1d64wb_register Imm:0 Reg:R9 Imm:8 Reg:R1 Reg:D12 Imm:14 Reg:Nil | vst1.64 {d12}, [r9:64], r1 | may_store
  #|0xf90ab440	VST3d16_UPD Reg:R10 Reg:R10 Imm:0 Reg:R0 Reg:D11 Reg:D12 Reg:D13 Imm:14 Reg:Nil | vst3.16 {d11, d12, d13}, [r10], r0 | may_store
  #|0xf90b42ff	VST1d64Q Reg:R11 Imm:32 Reg:D4 Imm:14 Reg:Nil | vst1.64 {d4, d5, d6, d7}, [r11:256] | may_store
  #|0xf90e2690	VST1d32Twb_register Imm:0 Reg:LR Imm:8 Reg:R0 Reg:D2 Imm:14 Reg:Nil | vst1.32 {d2, d3, d4}, [lr:64], r0 | may_store
  #|0xf90e345b	VST3d16_UPD Reg:LR Reg:LR Imm:8 Reg:R11 Reg:D3 Reg:D4 Reg:D5 Imm:14 Reg:Nil | vst3.16 {d3, d4, d5}, [lr:64], r11 | may_store
  #|0xf90f7a90	VST1q32wb_register Imm:0 Reg:PC Imm:8 Reg:R0 Reg:D7_D8 Imm:14 Reg:Nil | vst1.32 {d7, d8}, [pc:64], r0 | may_store
  #|0xf90fd70d	VST1d8wb_fixed Imm:0 Reg:PC Imm:0 Reg:D13 Imm:14 Reg:Nil | vst1.8 {d13}, [pc]! | may_store
  #|0xf910bede	t2LDRSBT Reg:R11 Reg:R0 Imm:222 Imm:14 Reg:Nil | ldrsbt r11, [r0, #222]
  #|0xf9154e00	t2LDRSBT Reg:R4 Reg:R5 Imm:0 Imm:14 Reg:Nil | ldrsbt r4, [r5]
  #|0xf9206aec	VLD1q64wb_register Reg:Q3 Imm:0 Reg:R0 Imm:16 Reg:R12 Imm:14 Reg:Nil | vld1.64 {d6, d7}, [r0:128], r12 | may_load
  #|0xf921186e	VLD2d16wb_register Reg:D1_D2 Imm:0 Reg:R1 Imm:16 Reg:LR Imm:14 Reg:Nil | vld2.16 {d1, d2}, [r1:128], lr | may_load
  #|0xf921327c	VLD1d16Qwb_register Reg:D3 Imm:0 Reg:R1 Imm:32 Reg:R12 Imm:14 Reg:Nil | vld1.16 {d3, d4, d5, d6}, [r1:256], r12 | may_load
  #|0xf9215a83	VLD1q32wb_register Reg:D5_D6 Imm:0 Reg:R1 Imm:0 Reg:R3 Imm:14 Reg:Nil | vld1.32 {d5, d6}, [r1], r3 | may_load
  #|0xf922000f	VLD4d8 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R2 Imm:0 Imm:14 Reg:Nil | vld4.8 {d0, d1, d2, d3}, [r2] | may_load
  #|0xf922010e	VLD4q8_UPD Reg:D0 Reg:D2 Reg:D4 Reg:D6 Reg:R2 Reg:R2 Imm:0 Reg:LR Imm:14 Reg:Nil | vld4.8 {d0, d2, d4, d6}, [r2], lr | may_load
  #|0xf922988e	VLD2d32wb_register Reg:D9_D10 Imm:0 Reg:R2 Imm:0 Reg:LR Imm:14 Reg:Nil | vld2.32 {d9, d10}, [r2], lr | may_load
  #|0xf923002b	VLD4d8_UPD Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R3 Reg:R3 Imm:16 Reg:R11 Imm:14 Reg:Nil | vld4.8 {d0, d1, d2, d3}, [r3:128], r11 | may_load
  #|0xf923002d	VLD4d8_UPD Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R3 Reg:R3 Imm:16 Reg:Nil Imm:14 Reg:Nil | vld4.8 {d0, d1, d2, d3}, [r3:128]! | may_load
  #|0xf9234310	VLD2q8wb_register Reg:D4 Imm:0 Reg:R3 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld2.8 {d4, d5, d6, d7}, [r3:64], r0 | may_load
  #|0xf923e08d	VLD4d32_UPD Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:R3 Reg:R3 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld4.32 {d14, d15, d16, d17}, [r3]! | may_load
  #|0xf923e20d	VLD1d8Qwb_fixed Reg:D14 Imm:0 Reg:R3 Imm:0 Imm:14 Reg:Nil | vld1.8 {d14, d15, d16, d17}, [r3]! | may_load
  #|0xf923fa41	VLD1q16wb_register Reg:D15_D16 Imm:0 Reg:R3 Imm:0 Reg:R1 Imm:14 Reg:Nil | vld1.16 {d15, d16}, [r3], r1 | may_load
  #|0xf9240005	VLD4d8_UPD Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R4 Reg:R4 Imm:0 Reg:R5 Imm:14 Reg:Nil | vld4.8 {d0, d1, d2, d3}, [r4], r5 | may_load
  #|0xf9249546	VLD3q16_UPD Reg:D9 Reg:D11 Reg:D13 Reg:R4 Reg:R4 Imm:0 Reg:R6 Imm:14 Reg:Nil | vld3.16 {d9, d11, d13}, [r4], r6 | may_load
  #|0xf924f90a	VLD2b8wb_register Reg:D15_D17 Imm:0 Reg:R4 Imm:0 Reg:R10 Imm:14 Reg:Nil | vld2.8 {d15, d17}, [r4], r10 | may_load
  #|0xf92612f0	VLD1d64Qwb_register Reg:D1 Imm:0 Reg:R6 Imm:32 Reg:R0 Imm:14 Reg:Nil | vld1.64 {d1, d2, d3, d4}, [r6:256], r0 | may_load
  #|0xf9261380	VLD2q32wb_register Reg:D1 Imm:0 Reg:R6 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld2.32 {d1, d2, d3, d4}, [r6], r0 | may_load
  #|0xf9265702	VLD1d8wb_register Reg:D5 Imm:0 Reg:R6 Imm:0 Reg:R2 Imm:14 Reg:Nil | vld1.8 {d5}, [r6], r2 | may_load
  #|0xf926b0ad	VLD4d32_UPD Reg:D11 Reg:D12 Reg:D13 Reg:D14 Reg:R6 Reg:R6 Imm:16 Reg:Nil Imm:14 Reg:Nil | vld4.32 {d11, d12, d13, d14}, [r6:128]! | may_load
  #|0xf9272a00	VLD1q8wb_register Reg:Q1 Imm:0 Reg:R7 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d2, d3}, [r7], r0 | may_load
  #|0xf927a480	VLD3d32_UPD Reg:D10 Reg:D11 Reg:D12 Reg:R7 Reg:R7 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld3.32 {d10, d11, d12}, [r7], r0 | may_load
  #|0xf927b90d	VLD2b8wb_fixed Reg:D11_D13 Imm:0 Reg:R7 Imm:0 Imm:14 Reg:Nil | vld2.8 {d11, d13}, [r7]! | may_load
  #|0xf928014f	VLD4q16 Reg:D0 Reg:D2 Reg:D4 Reg:D6 Reg:R8 Imm:0 Imm:14 Reg:Nil | vld4.16 {d0, d2, d4, d6}, [r8] | may_load
  #|0xf928584e	VLD2d16wb_register Reg:D5_D6 Imm:0 Reg:R8 Imm:0 Reg:LR Imm:14 Reg:Nil | vld2.16 {d5, d6}, [r8], lr | may_load
  #|0xf928c640	VLD1d16Twb_register Reg:D12 Imm:0 Reg:R8 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.16 {d12, d13, d14}, [r8], r0 | may_load
  #|0xf929004f	VLD4d16 Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R9 Imm:0 Imm:14 Reg:Nil | vld4.16 {d0, d1, d2, d3}, [r9] | may_load
  #|0xf92909ad	VLD2b32wb_fixed Reg:D0_D2 Imm:0 Reg:R9 Imm:16 Imm:14 Reg:Nil | vld2.32 {d0, d2}, [r9:128]! | may_load
  #|0xf9291280	VLD1d32Qwb_register Reg:D1 Imm:0 Reg:R9 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.32 {d1, d2, d3, d4}, [r9], r0 | may_load
  #|0xf9299344	VLD2q16wb_register Reg:D9 Imm:0 Reg:R9 Imm:0 Reg:R4 Imm:14 Reg:Nil | vld2.16 {d9, d10, d11, d12}, [r9], r4 | may_load
  #|0xf929a507	VLD3q8_UPD Reg:D10 Reg:D12 Reg:D14 Reg:R9 Reg:R9 Imm:0 Reg:R7 Imm:14 Reg:Nil | vld3.8 {d10, d12, d14}, [r9], r7 | may_load
  #|0xf92a0308	VLD2q8wb_register Reg:D0 Imm:0 Reg:R10 Imm:0 Reg:R8 Imm:14 Reg:Nil | vld2.8 {d0, d1, d2, d3}, [r10], r8 | may_load
  #|0xf92a7aed	VLD1q64wb_fixed Reg:D7_D8 Imm:0 Reg:R10 Imm:16 Imm:14 Reg:Nil | vld1.64 {d7, d8}, [r10:128]! | may_load
  #|0xf92b5595	VLD3q32_UPD Reg:D5 Reg:D7 Reg:D9 Reg:R11 Reg:R11 Imm:8 Reg:R5 Imm:14 Reg:Nil | vld3.32 {d5, d7, d9}, [r11:64], r5 | may_load
  #|0xf92b948d	VLD3d32_UPD Reg:D9 Reg:D10 Reg:D11 Reg:R11 Reg:R11 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld3.32 {d9, d10, d11}, [r11]! | may_load
  #|0xf92b9824	VLD2d8wb_register Reg:D9_D10 Imm:0 Reg:R11 Imm:16 Reg:R4 Imm:14 Reg:Nil | vld2.8 {d9, d10}, [r11:128], r4 | may_load
  #|0xf92bd3b3	VLD2q32wb_register Reg:D13 Imm:0 Reg:R11 Imm:32 Reg:R3 Imm:14 Reg:Nil | vld2.32 {d13, d14, d15, d16}, [r11:256], r3 | may_load
  #|0xf92c1800	VLD2d8wb_register Reg:D1_D2 Imm:0 Reg:R12 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld2.8 {d1, d2}, [r12], r0 | may_load
  #|0xf92ca910	VLD2b8wb_register Reg:D10_D12 Imm:0 Reg:R12 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld2.8 {d10, d12}, [r12:64], r0 | may_load
  #|0xf92da580	VLD3q32_UPD Reg:D10 Reg:D12 Reg:D14 Reg:SP Reg:SP Imm:0 Reg:R0 Imm:14 Reg:Nil | vld3.32 {d10, d12, d14}, [sp], r0 | may_load
  #|0xf92ee610	VLD1d8Twb_register Reg:D14 Imm:0 Reg:LR Imm:8 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d14, d15, d16}, [lr:64], r0 | may_load
  #|0xf92eea4f	VLD1q16 Reg:Q7 Reg:LR Imm:0 Imm:14 Reg:Nil | vld1.16 {d14, d15}, [lr] | may_load
  #|0xf92ef6ca	VLD1d64Twb_register Reg:D15 Imm:0 Reg:LR Imm:0 Reg:R10 Imm:14 Reg:Nil | vld1.64 {d15, d16, d17}, [lr], r10 | may_load
  #|0xf92f8710	VLD1d8wb_register Reg:D8 Imm:0 Reg:PC Imm:8 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d8}, [pc:64], r0 | may_load
  #|0xf92fb1a7	VLD4q32_UPD Reg:D11 Reg:D13 Reg:D15 Reg:D17 Reg:PC Reg:PC Imm:16 Reg:R7 Imm:14 Reg:Nil | vld4.32 {d11, d13, d15, d17}, [pc:128], r7 | affect_cf,may_load
  #|0xf9306e00	t2LDRSHT Reg:R6 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrsht r6, [r0]
  #|0xf9380e98	t2LDRSHT Reg:R0 Reg:R8 Imm:152 Imm:14 Reg:Nil | ldrsht r0, [r8, #152]
  #|0xf94076df	VST1d64T Reg:R0 Imm:8 Reg:D23 Imm:14 Reg:Nil | vst1.64 {d23, d24, d25}, [r0:64] | may_store
  #|0xf94216d0	VST1d64Twb_register Imm:0 Reg:R2 Imm:8 Reg:R0 Reg:D17 Imm:14 Reg:Nil | vst1.64 {d17, d18, d19}, [r2:64], r0 | may_store
  #|0xf942244f	VST3d16 Reg:R2 Imm:0 Reg:D18 Reg:D19 Reg:D20 Imm:14 Reg:Nil | vst3.16 {d18, d19, d20}, [r2] | may_store
  #|0xf942320d	VST1d8Qwb_fixed Imm:0 Reg:R2 Imm:0 Reg:D19 Imm:14 Reg:Nil | vst1.8 {d19, d20, d21, d22}, [r2]! | may_store
  #|0xf942e236	VST1d8Qwb_register Imm:0 Reg:R2 Imm:32 Reg:R6 Reg:D30 Imm:14 Reg:Nil | vst1.8 {d30, d31, fpinst2, mvfr0}, [r2:256], r6 | may_store
  #|0xf9439606	VST1d8Twb_register Imm:0 Reg:R3 Imm:0 Reg:R6 Reg:D25 Imm:14 Reg:Nil | vst1.8 {d25, d26, d27}, [r3], r6 | may_store
  #|0xf943f3a4	VST2q32wb_register Imm:0 Reg:R3 Imm:16 Reg:R4 Reg:D31 Imm:14 Reg:Nil | vst2.32 {d31, fpinst2, mvfr0, mvfr1}, [r3:128], r4 | may_store
  #|0xf9440008	VST4d8_UPD Reg:R4 Reg:R4 Imm:0 Reg:R8 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Imm:14 Reg:Nil | vst4.8 {d16, d17, d18, d19}, [r4], r8 | may_store
  #|0xf94431bf	VST4q32 Reg:R4 Imm:32 Reg:D19 Reg:D21 Reg:D23 Reg:D25 Imm:14 Reg:Nil | vst4.32 {d19, d21, d23, d25}, [r4:256] | may_store
  #|0xf944331f	VST2q8 Reg:R4 Imm:8 Reg:D19 Imm:14 Reg:Nil | vst2.8 {d19, d20, d21, d22}, [r4:64] | may_store
  #|0xf94492ba	VST1d32Qwb_register Imm:0 Reg:R4 Imm:32 Reg:R10 Reg:D25 Imm:14 Reg:Nil | vst1.32 {d25, d26, d27, d28}, [r4:256], r10 | may_store
  #|0xf944a40f	VST3d8 Reg:R4 Imm:0 Reg:D26 Reg:D27 Reg:D28 Imm:14 Reg:Nil | vst3.8 {d26, d27, d28}, [r4] | may_store
  #|0xf944e303	VST2q8wb_register Imm:0 Reg:R4 Imm:0 Reg:R3 Reg:D30 Imm:14 Reg:Nil | vst2.8 {d30, d31, fpinst2, mvfr0}, [r4], r3 | may_store
  #|0xf944e68f	VST1d32T Reg:R4 Imm:0 Reg:D30 Imm:14 Reg:Nil | vst1.32 {d30, d31, fpinst2}, [r4] | may_store
  #|0xf9456a5f	VST1q16 Reg:R5 Imm:8 Reg:Q11 Imm:14 Reg:Nil | vst1.16 {d22, d23}, [r5:64] | may_store
  #|0xf9463700	VST1d8wb_register Imm:0 Reg:R6 Imm:0 Reg:R0 Reg:D19 Imm:14 Reg:Nil | vst1.8 {d19}, [r6], r0 | may_store
  #|0xf946d518	VST3q8_UPD Reg:R6 Reg:R6 Imm:8 Reg:R8 Reg:D29 Reg:D31 Reg:D1 Imm:14 Reg:Nil | vst3.8 {d29, d31, d1}, [r6:64], r8 | may_store
  #|0xf947250f	VST3q8 Reg:R7 Imm:0 Reg:D18 Reg:D20 Reg:D22 Imm:14 Reg:Nil | vst3.8 {d18, d20, d22}, [r7] | may_store
  #|0xf947288d	VST2d32wb_fixed Imm:0 Reg:R7 Imm:0 Reg:Q9 Imm:14 Reg:Nil | vst2.32 {d18, d19}, [r7]! | may_store
  #|0xf9474888	VST2d32wb_register Imm:0 Reg:R7 Imm:0 Reg:R8 Reg:Q10 Imm:14 Reg:Nil | vst2.32 {d20, d21}, [r7], r8 | may_store
  #|0xf9475330	VST2q8wb_register Imm:0 Reg:R7 Imm:32 Reg:R0 Reg:D21 Imm:14 Reg:Nil | vst2.8 {d21, d22, d23, d24}, [r7:256], r0 | may_store
  #|0xf947c959	VST2b16wb_register Imm:0 Reg:R7 Imm:8 Reg:R9 Reg:D28_D30 Imm:14 Reg:Nil | vst2.16 {d28, d30}, [r7:64], r9 | may_store
  #|0xf9480080	VST4d32_UPD Reg:R8 Reg:R8 Imm:0 Reg:R0 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Imm:14 Reg:Nil | vst4.32 {d16, d17, d18, d19}, [r8], r0 | may_store
  #|0xf948d2dd	VST1d64Qwb_fixed Imm:0 Reg:R8 Imm:8 Reg:D29 Imm:14 Reg:Nil | vst1.64 {d29, d30, d31, fpinst2}, [r8:64]! | may_store
  #|0xf949001f	VST4d8 Reg:R9 Imm:8 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Imm:14 Reg:Nil | vst4.8 {d16, d17, d18, d19}, [r9:64] | may_store
  #|0xf949380b	VST2d8wb_register Imm:0 Reg:R9 Imm:0 Reg:R11 Reg:D19_D20 Imm:14 Reg:Nil | vst2.8 {d19, d20}, [r9], r11 | may_store
  #|0xf949ba4d	VST1q16wb_fixed Imm:0 Reg:R9 Imm:0 Reg:D27_D28 Imm:14 Reg:Nil | vst1.16 {d27, d28}, [r9]! | may_store
  #|0xf949e6c0	VST1d64Twb_register Imm:0 Reg:R9 Imm:0 Reg:R0 Reg:D30 Imm:14 Reg:Nil | vst1.64 {d30, d31, fpinst2}, [r9], r0 | may_store
  #|0xf94a971e	VST1d8wb_register Imm:0 Reg:R10 Imm:8 Reg:LR Reg:D25 Imm:14 Reg:Nil | vst1.8 {d25}, [r10:64], lr | may_store
  #|0xf94ad209	VST1d8Qwb_register Imm:0 Reg:R10 Imm:0 Reg:R9 Reg:D29 Imm:14 Reg:Nil | vst1.8 {d29, d30, d31, fpinst2}, [r10], r9 | may_store
  #|0xf94b6166	VST4q16_UPD Reg:R11 Reg:R11 Imm:16 Reg:R6 Reg:D22 Reg:D24 Reg:D26 Reg:D28 Imm:14 Reg:Nil | vst4.16 {d22, d24, d26, d28}, [r11:128], r6 | may_store
  #|0xf94b7366	VST2q16wb_register Imm:0 Reg:R11 Imm:16 Reg:R6 Reg:D23 Imm:14 Reg:Nil | vst2.16 {d23, d24, d25, d26}, [r11:128], r6 | may_store
  #|0xf94c1981	VST2b32wb_register Imm:0 Reg:R12 Imm:0 Reg:R1 Reg:D17_D19 Imm:14 Reg:Nil | vst2.32 {d17, d19}, [r12], r1 | may_store
  #|0xf94c7acb	VST1q64wb_register Imm:0 Reg:R12 Imm:0 Reg:R11 Reg:D23_D24 Imm:14 Reg:Nil | vst1.64 {d23, d24}, [r12], r11 | may_store
  #|0xf94cf400	VST3d8_UPD Reg:R12 Reg:R12 Imm:0 Reg:R0 Reg:D31 Reg:D0 Reg:D1 Imm:14 Reg:Nil | vst3.8 {d31, d0, d1}, [r12], r0 | may_store
  #|0xf94d230d	VST2q8wb_fixed Imm:0 Reg:SP Imm:0 Reg:D18 Imm:14 Reg:Nil | vst2.8 {d18, d19, d20, d21}, [sp]! | may_store
  #|0xf94e354d	VST3q16_UPD Reg:LR Reg:LR Imm:0 Reg:Nil Reg:D19 Reg:D21 Reg:D23 Imm:14 Reg:Nil | vst3.16 {d19, d21, d23}, [lr]! | may_store
  #|0xf94f294d	VST2b16wb_fixed Imm:0 Reg:PC Imm:0 Reg:D18_D20 Imm:14 Reg:Nil | vst2.16 {d18, d20}, [pc]! | may_store
  #|0xf94f73bb	VST2q32wb_register Imm:0 Reg:PC Imm:32 Reg:R11 Reg:D23 Imm:14 Reg:Nil | vst2.32 {d23, d24, d25, d26}, [pc:256], r11 | may_store
  #|0xf94fa7dd	VST1d64wb_fixed Imm:0 Reg:PC Imm:8 Reg:D26 Imm:14 Reg:Nil | vst1.64 {d26}, [pc:64]! | may_store
  #|0xf94ff71d	VST1d8wb_fixed Imm:0 Reg:PC Imm:8 Reg:D31 Imm:14 Reg:Nil | vst1.8 {d31}, [pc:64]! | may_store
  #|0xf9600050	VLD4d16_UPD Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:R0 Reg:R0 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld4.16 {d16, d17, d18, d19}, [r0:64], r0 | may_load
  #|0xf9609a63	VLD1q16wb_register Reg:D25_D26 Imm:0 Reg:R0 Imm:16 Reg:R3 Imm:14 Reg:Nil | vld1.16 {d25, d26}, [r0:128], r3 | may_load
  #|0xf960b494	VLD3d32_UPD Reg:D27 Reg:D28 Reg:D29 Reg:R0 Reg:R0 Imm:8 Reg:R4 Imm:14 Reg:Nil | vld3.32 {d27, d28, d29}, [r0:64], r4 | may_load
  #|0xf960d961	VLD2b16wb_register Reg:D29_D31 Imm:0 Reg:R0 Imm:16 Reg:R1 Imm:14 Reg:Nil | vld2.16 {d29, d31}, [r0:128], r1 | may_load
  #|0xf961179c	VLD1d32wb_register Reg:D17 Imm:0 Reg:R1 Imm:8 Reg:R12 Imm:14 Reg:Nil | vld1.32 {d17}, [r1:64], r12 | may_load
  #|0xf961414b	VLD4q16_UPD Reg:D20 Reg:D22 Reg:D24 Reg:D26 Reg:R1 Reg:R1 Imm:0 Reg:R11 Imm:14 Reg:Nil | vld4.16 {d20, d22, d24, d26}, [r1], r11 | may_load
  #|0xf962d329	VLD2q8wb_register Reg:D29 Imm:0 Reg:R2 Imm:16 Reg:R9 Imm:14 Reg:Nil | vld2.8 {d29, d30, d31, fpinst2}, [r2:128], r9 | may_load
  #|0xf9634a11	VLD1q8wb_register Reg:Q10 Imm:0 Reg:R3 Imm:8 Reg:R1 Imm:14 Reg:Nil | vld1.8 {d20, d21}, [r3:64], r1 | may_load
  #|0xf9640041	VLD4d16_UPD Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:R4 Reg:R4 Imm:0 Reg:R1 Imm:14 Reg:Nil | vld4.16 {d16, d17, d18, d19}, [r4], r1 | may_load
  #|0xf964160f	VLD1d8T Reg:D17 Reg:R4 Imm:0 Imm:14 Reg:Nil | vld1.8 {d17, d18, d19}, [r4] | may_load
  #|0xf964f20a	VLD1d8Qwb_register Reg:D31 Imm:0 Reg:R4 Imm:0 Reg:R10 Imm:14 Reg:Nil | vld1.8 {d31, fpinst2, mvfr0, mvfr1}, [r4], r10 | may_load
  #|0xf964f600	VLD1d8Twb_register Reg:D31 Imm:0 Reg:R4 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d31, fpinst2, mvfr0}, [r4], r0 | may_load
  #|0xf9650080	VLD4d32_UPD Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:R5 Reg:R5 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld4.32 {d16, d17, d18, d19}, [r5], r0 | may_load
  #|0xf9660a0d	VLD1q8wb_fixed Reg:Q8 Imm:0 Reg:R6 Imm:0 Imm:14 Reg:Nil | vld1.8 {d16, d17}, [r6]! | may_load
  #|0xf96612c0	VLD1d64Qwb_register Reg:D17 Imm:0 Reg:R6 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.64 {d17, d18, d19, d20}, [r6], r0 | may_load
  #|0xf966979d	VLD1d32wb_fixed Reg:D25 Imm:0 Reg:R6 Imm:8 Imm:14 Reg:Nil | vld1.32 {d25}, [r6:64]! | may_load
  #|0xf966c82d	VLD2d8wb_fixed Reg:Q14 Imm:0 Reg:R6 Imm:16 Imm:14 Reg:Nil | vld2.8 {d28, d29}, [r6:128]! | may_load
  #|0xf967000d	VLD4d8_UPD Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:R7 Reg:R7 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld4.8 {d16, d17, d18, d19}, [r7]! | may_load
  #|0xf9676409	VLD3d8_UPD Reg:D22 Reg:D23 Reg:D24 Reg:R7 Reg:R7 Imm:0 Reg:R9 Imm:14 Reg:Nil | vld3.8 {d22, d23, d24}, [r7], r9 | may_load
  #|0xf967ca1d	VLD1q8wb_fixed Reg:Q14 Imm:0 Reg:R7 Imm:8 Imm:14 Reg:Nil | vld1.8 {d28, d29}, [r7:64]! | may_load
  #|0xf9681ac7	VLD1q64wb_register Reg:D17_D18 Imm:0 Reg:R8 Imm:0 Reg:R7 Imm:14 Reg:Nil | vld1.64 {d17, d18}, [r8], r7 | may_load
  #|0xf968478b	VLD1d32wb_register Reg:D20 Imm:0 Reg:R8 Imm:0 Reg:R11 Imm:14 Reg:Nil | vld1.32 {d20}, [r8], r11 | may_load
  #|0xf9687940	VLD2b16wb_register Reg:D23_D25 Imm:0 Reg:R8 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld2.16 {d23, d25}, [r8], r0 | may_load
  #|0xf968a02f	VLD4d8 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Reg:R8 Imm:16 Imm:14 Reg:Nil | vld4.8 {d26, d27, d28, d29}, [r8:128] | may_load
  #|0xf968b6d0	VLD1d64Twb_register Reg:D27 Imm:0 Reg:R8 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld1.64 {d27, d28, d29}, [r8:64], r0 | may_load
  #|0xf968c996	VLD2b32wb_register Reg:D28_D30 Imm:0 Reg:R8 Imm:8 Reg:R6 Imm:14 Reg:Nil | vld2.32 {d28, d30}, [r8:64], r6 | may_load
  #|0xf969054d	VLD3q16_UPD Reg:D16 Reg:D18 Reg:D20 Reg:R9 Reg:R9 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld3.16 {d16, d18, d20}, [r9]! | may_load
  #|0xf969945e	VLD3d16_UPD Reg:D25 Reg:D26 Reg:D27 Reg:R9 Reg:R9 Imm:8 Reg:LR Imm:14 Reg:Nil | vld3.16 {d25, d26, d27}, [r9:64], lr | may_load
  #|0xf969c60b	VLD1d8Twb_register Reg:D28 Imm:0 Reg:R9 Imm:0 Reg:R11 Imm:14 Reg:Nil | vld1.8 {d28, d29, d30}, [r9], r11 | may_load
  #|0xf969d110	VLD4q8_UPD Reg:D29 Reg:D31 Reg:D1 Reg:D3 Reg:R9 Reg:R9 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld4.8 {d29, d31, d1, d3}, [r9:64], r0 | may_load
  #|0xf96a007f	VLD4d16 Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:R10 Imm:32 Imm:14 Reg:Nil | vld4.16 {d16, d17, d18, d19}, [r10:256] | may_load
  #|0xf96a32aa	VLD1d32Qwb_register Reg:D19 Imm:0 Reg:R10 Imm:16 Reg:R10 Imm:14 Reg:Nil | vld1.32 {d19, d20, d21, d22}, [r10:128], r10 | may_load
  #|0xf96a5188	VLD4q32_UPD Reg:D21 Reg:D23 Reg:D25 Reg:D27 Reg:R10 Reg:R10 Imm:0 Reg:R8 Imm:14 Reg:Nil | vld4.32 {d21, d23, d25, d27}, [r10], r8 | may_load
  #|0xf96a744b	VLD3d16_UPD Reg:D23 Reg:D24 Reg:D25 Reg:R10 Reg:R10 Imm:0 Reg:R11 Imm:14 Reg:Nil | vld3.16 {d23, d24, d25}, [r10], r11 | may_load
  #|0xf96aba9c	VLD1q32wb_register Reg:D27_D28 Imm:0 Reg:R10 Imm:8 Reg:R12 Imm:14 Reg:Nil | vld1.32 {d27, d28}, [r10:64], r12 | may_load
  #|0xf96b0161	VLD4q16_UPD Reg:D16 Reg:D18 Reg:D20 Reg:D22 Reg:R11 Reg:R11 Imm:16 Reg:R1 Imm:14 Reg:Nil | vld4.16 {d16, d18, d20, d22}, [r11:128], r1 | may_load
  #|0xf96b0680	VLD1d32Twb_register Reg:D16 Imm:0 Reg:R11 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.32 {d16, d17, d18}, [r11], r0 | may_load
  #|0xf96b6362	VLD2q16wb_register Reg:D22 Imm:0 Reg:R11 Imm:16 Reg:R2 Imm:14 Reg:Nil | vld2.16 {d22, d23, d24, d25}, [r11:128], r2 | may_load
  #|0xf96ba410	VLD3d8_UPD Reg:D26 Reg:D27 Reg:D28 Reg:R11 Reg:R11 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld3.8 {d26, d27, d28}, [r11:64], r0 | may_load
  #|0xf96c2230	VLD1d8Qwb_register Reg:D18 Imm:0 Reg:R12 Imm:32 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d18, d19, d20, d21}, [r12:256], r0 | may_load
  #|0xf96caa9f	VLD1q32 Reg:Q13 Reg:R12 Imm:8 Imm:14 Reg:Nil | vld1.32 {d26, d27}, [r12:64] | may_load
  #|0xf96cd200	VLD1d8Qwb_register Reg:D29 Imm:0 Reg:R12 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d29, d30, d31, fpinst2}, [r12], r0 | may_load
  #|0xf96d5551	VLD3q16_UPD Reg:D21 Reg:D23 Reg:D25 Reg:SP Reg:SP Imm:8 Reg:R1 Imm:14 Reg:Nil | vld3.16 {d21, d23, d25}, [sp:64], r1 | may_load
  #|0xf96dd652	VLD1d16Twb_register Reg:D29 Imm:0 Reg:SP Imm:8 Reg:R2 Imm:14 Reg:Nil | vld1.16 {d29, d30, d31}, [sp:64], r2 | may_load
  #|0xf96e00b0	VLD4d32_UPD Reg:D16 Reg:D17 Reg:D18 Reg:D19 Reg:LR Reg:LR Imm:32 Reg:R0 Imm:14 Reg:Nil | vld4.32 {d16, d17, d18, d19}, [lr:256], r0 | may_load
  #|0xf96e540d	VLD3d8_UPD Reg:D21 Reg:D22 Reg:D23 Reg:LR Reg:LR Imm:0 Reg:Nil Imm:14 Reg:Nil | vld3.8 {d21, d22, d23}, [lr]! | may_load
  #|0xf96e750d	VLD3q8_UPD Reg:D23 Reg:D25 Reg:D27 Reg:LR Reg:LR Imm:0 Reg:Nil Imm:14 Reg:Nil | vld3.8 {d23, d25, d27}, [lr]! | may_load
  #|0xf96e77d9	VLD1d64wb_register Reg:D23 Imm:0 Reg:LR Imm:8 Reg:R9 Imm:14 Reg:Nil | vld1.64 {d23}, [lr:64], r9 | may_load
  #|0xf96e980d	VLD2d8wb_fixed Reg:D25_D26 Imm:0 Reg:LR Imm:0 Imm:14 Reg:Nil | vld2.8 {d25, d26}, [lr]! | may_load
  #|0xf96eb744	VLD1d16wb_register Reg:D27 Imm:0 Reg:LR Imm:0 Reg:R4 Imm:14 Reg:Nil | vld1.16 {d27}, [lr], r4 | may_load
  #|0xf96ee05d	VLD4d16_UPD Reg:D30 Reg:D31 Reg:D0 Reg:D1 Reg:LR Reg:LR Imm:8 Reg:Nil Imm:14 Reg:Nil | vld4.16 {d30, d31, d0, d1}, [lr:64]! | may_load
  #|0xf96ee3a9	VLD2q32wb_register Reg:D30 Imm:0 Reg:LR Imm:16 Reg:R9 Imm:14 Reg:Nil | vld2.32 {d30, d31, fpinst2, mvfr0}, [lr:128], r9 | may_load
  #|0xf96f3200	VLD1d8Qwb_register Reg:D19 Imm:0 Reg:PC Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d19, d20, d21, d22}, [pc], r0 | may_load
  #|0xf96f56dd	VLD1d64Twb_fixed Reg:D21 Imm:0 Reg:PC Imm:8 Imm:14 Reg:Nil | vld1.64 {d21, d22, d23}, [pc:64]! | may_load
  #|0xf96f9899	VLD2d32wb_register Reg:D25_D26 Imm:0 Reg:PC Imm:8 Reg:R9 Imm:14 Reg:Nil | vld2.32 {d25, d26}, [pc:64], r9 | may_load
  #|0xf96fe2ad	VLD1d32Qwb_fixed Reg:D30 Imm:0 Reg:PC Imm:16 Imm:14 Reg:Nil | vld1.32 {d30, d31, fpinst2, mvfr0}, [pc:128]! | may_load
  #|0xf9800b0d	VST4LNd32_UPD Reg:R0 Reg:R0 Imm:0 Reg:Nil Reg:D0 Reg:D1 Reg:D2 Reg:D3 Imm:0 Imm:14 Reg:Nil | vst4.32 {d0[0], d1[0], d2[0], d3[0]}, [r0]! | may_store
  #|0xf980295e	VST2LNq32_UPD Reg:R0 Reg:R0 Imm:8 Reg:LR Reg:D2 Reg:D4 Imm:0 Imm:14 Reg:Nil | vst2.32 {d2[0], d4[0]}, [r0:64], lr | may_store
  #|0xf980616d	VST2LNd8_UPD Reg:R0 Reg:R0 Imm:0 Reg:Nil Reg:D6 Reg:D7 Imm:3 Imm:14 Reg:Nil | vst2.8 {d6[3], d7[3]}, [r0]! | may_store
  #|0xf980c99e	VST2LNd32_UPD Reg:R0 Reg:R0 Imm:8 Reg:LR Reg:D12 Reg:D13 Imm:1 Imm:14 Reg:Nil | vst2.32 {d12[1], d13[1]}, [r0:64], lr | may_store
  #|0xf981380f	VST1LNd32 Reg:R1 Imm:0 Reg:D3 Imm:0 Imm:14 Reg:Nil | vst1.32 {d3[0]}, [r1] | may_store
  #|0xf982000f	VST1LNd8 Reg:R2 Imm:0 Reg:D0 Imm:0 Imm:14 Reg:Nil | vst1.8 {d0[0]}, [r2] | may_store
  #|0xf9832a8f	VST3LNd32 Reg:R3 Imm:0 Reg:D2 Reg:D3 Reg:D4 Imm:1 Imm:14 Reg:Nil | vst3.32 {d2[1], d3[1], d4[1]}, [r3] | may_store
  #|0xf9838bc3	VST4LNq32_UPD Reg:R3 Reg:R3 Imm:0 Reg:R3 Reg:D8 Reg:D10 Reg:D12 Reg:D14 Imm:1 Imm:14 Reg:Nil | vst4.32 {d8[1], d10[1], d12[1], d14[1]}, [r3], r3 | may_store
  #|0xf9841700	VST4LNd16_UPD Reg:R4 Reg:R4 Imm:0 Reg:R0 Reg:D1 Reg:D2 Reg:D3 Reg:D4 Imm:0 Imm:14 Reg:Nil | vst4.16 {d1[0], d2[0], d3[0], d4[0]}, [r4], r0 | may_store
  #|0xf984419f	VST2LNd8 Reg:R4 Imm:2 Reg:D4 Reg:D5 Imm:4 Imm:14 Reg:Nil | vst2.8 {d4[4], d5[4]}, [r4:16] | may_store
  #|0xf9859b80	VST4LNd32_UPD Reg:R5 Reg:R5 Imm:0 Reg:R0 Reg:D9 Reg:D10 Reg:D11 Reg:D12 Imm:1 Imm:14 Reg:Nil | vst4.32 {d9[1], d10[1], d11[1], d12[1]}, [r5], r0 | may_store
  #|0xf9863a40	VST3LNq32_UPD Reg:R6 Reg:R6 Imm:0 Reg:R0 Reg:D3 Reg:D5 Reg:D7 Imm:0 Imm:14 Reg:Nil | vst3.32 {d3[0], d5[0], d7[0]}, [r6], r0 | may_store
  #|0xf986c58c	VST2LNd16_UPD Reg:R6 Reg:R6 Imm:0 Reg:R12 Reg:D12 Reg:D13 Imm:2 Imm:14 Reg:Nil | vst2.16 {d12[2], d13[2]}, [r6], r12 | may_store
  #|0xf987864f	VST3LNd16 Reg:R7 Imm:0 Reg:D8 Reg:D9 Reg:D10 Imm:1 Imm:14 Reg:Nil | vst3.16 {d8[1], d9[1], d10[1]}, [r7] | may_store
  #|0xf987f70d	VST4LNd16_UPD Reg:R7 Reg:R7 Imm:0 Reg:Nil Reg:D15 Reg:D16 Reg:D17 Reg:D18 Imm:0 Imm:14 Reg:Nil | vst4.16 {d15[0], d16[0], d17[0], d18[0]}, [r7]! | may_store
  #|0xf988290a	VST2LNd32_UPD Reg:R8 Reg:R8 Imm:0 Reg:R10 Reg:D2 Reg:D3 Imm:0 Imm:14 Reg:Nil | vst2.32 {d2[0], d3[0]}, [r8], r10 | may_store
  #|0xf9885600	VST3LNd16_UPD Reg:R8 Reg:R8 Imm:0 Reg:R0 Reg:D5 Reg:D6 Reg:D7 Imm:0 Imm:14 Reg:Nil | vst3.16 {d5[0], d6[0], d7[0]}, [r8], r0 | may_store
  #|0xf988b801	VST1LNd32_UPD Reg:R8 Reg:R8 Imm:0 Reg:R1 Reg:D11 Imm:0 Imm:14 Reg:Nil | vst1.32 {d11[0]}, [r8], r1 | may_store
  #|0xf988b90f	VST2LNd32 Reg:R8 Imm:0 Reg:D11 Reg:D12 Imm:0 Imm:14 Reg:Nil | vst2.32 {d11[0], d12[0]}, [r8] | may_store
  #|0xf98905af	VST2LNq16 Reg:R9 Imm:0 Reg:D0 Reg:D2 Imm:2 Imm:14 Reg:Nil | vst2.16 {d0[2], d2[2]}, [r9] | may_store
  #|0xf98916a4	VST3LNq16_UPD Reg:R9 Reg:R9 Imm:0 Reg:R4 Reg:D1 Reg:D3 Reg:D5 Imm:2 Imm:14 Reg:Nil | vst3.16 {d1[2], d3[2], d5[2]}, [r9], r4 | may_store
  #|0xf98a000d	VST1LNd8_UPD Reg:R10 Reg:R10 Imm:0 Reg:Nil Reg:D0 Imm:0 Imm:14 Reg:Nil | vst1.8 {d0[0]}, [r10]! | may_store
  #|0xf98a130d	VST4LNd8_UPD Reg:R10 Reg:R10 Imm:0 Reg:Nil Reg:D1 Reg:D2 Reg:D3 Reg:D4 Imm:0 Imm:14 Reg:Nil | vst4.8 {d1[0], d2[0], d3[0], d4[0]}, [r10]! | may_store
  #|0xf98a7942	VST2LNq32_UPD Reg:R10 Reg:R10 Imm:0 Reg:R2 Reg:D7 Reg:D9 Imm:0 Imm:14 Reg:Nil | vst2.32 {d7[0], d9[0]}, [r10], r2 | may_store
  #|0xf98c950d	VST2LNd16_UPD Reg:R12 Reg:R12 Imm:0 Reg:Nil Reg:D9 Reg:D10 Imm:0 Imm:14 Reg:Nil | vst2.16 {d9[0], d10[0]}, [r12]! | may_store
  #|0xf98d4140	VST2LNd8_UPD Reg:SP Reg:SP Imm:0 Reg:R0 Reg:D4 Reg:D5 Imm:2 Imm:14 Reg:Nil | vst2.8 {d4[2], d5[2]}, [sp], r0 | may_store
  #|0xf98d5bcd	VST4LNq32_UPD Reg:SP Reg:SP Imm:0 Reg:Nil Reg:D5 Reg:D7 Reg:D9 Reg:D11 Imm:1 Imm:14 Reg:Nil | vst4.32 {d5[1], d7[1], d9[1], d11[1]}, [sp]! | may_store
  #|0xf98eb520	VST2LNq16_UPD Reg:LR Reg:LR Imm:0 Reg:R0 Reg:D11 Reg:D13 Imm:0 Imm:14 Reg:Nil | vst2.16 {d11[0], d13[0]}, [lr], r0 | may_store
  #|0xf98ed229	VST3LNd8_UPD Reg:LR Reg:LR Imm:0 Reg:R9 Reg:D13 Reg:D14 Reg:D15 Imm:1 Imm:14 Reg:Nil | vst3.8 {d13[1], d14[1], d15[1]}, [lr], r9 | may_store
  #|0xf98f6360	VST4LNd8_UPD Reg:PC Reg:PC Imm:0 Reg:R0 Reg:D6 Reg:D7 Reg:D8 Reg:D9 Imm:3 Imm:14 Reg:Nil | vst4.8 {d6[3], d7[3], d8[3], d9[3]}, [pc], r0 | affect_cf,may_store
  #|0xf98fa3d8	VST4LNd8_UPD Reg:PC Reg:PC Imm:4 Reg:R8 Reg:D10 Reg:D11 Reg:D12 Reg:D13 Imm:6 Imm:14 Reg:Nil | vst4.8 {d10[6], d11[6], d12[6], d13[6]}, [pc:32], r8 | affect_cf,may_store
  #|0xf9a01d16	VLD2DUPd8wb_register Reg:D1_D2 Imm:0 Reg:R0 Imm:2 Reg:R6 Imm:14 Reg:Nil | vld2.8 {d1[], d2[]}, [r0:16], r6 | may_load
  #|0xf9a076ef	VLD3LNq16 Reg:D7 Reg:D9 Reg:D11 Reg:R0 Imm:0 Reg:D7 Reg:D9 Reg:D11 Imm:3 Imm:14 Reg:Nil | vld3.16 {d7[3], d9[3], d11[3]}, [r0] | may_load
  #|0xf9a08c5d	VLD1DUPd16wb_fixed Reg:D8 Reg:R0 Reg:R0 Imm:2 Imm:14 Reg:Nil | vld1.16 {d8[]}, [r0:16]! | may_load
  #|0xf9a08c78	VLD1DUPq16wb_register Reg:Q4 Reg:R0 Reg:R0 Imm:2 Reg:R8 Imm:14 Reg:Nil | vld1.16 {d8[], d9[]}, [r0:16], r8 | may_load
  #|0xf9a0ad2e	VLD2DUPd8x2wb_register Reg:D10_D12 Imm:0 Reg:R0 Imm:0 Reg:LR Imm:14 Reg:Nil | vld2.8 {d10[], d12[]}, [r0], lr | may_load
  #|0xf9a0f40a	VLD1LNd16_UPD Reg:D15 Reg:R0 Reg:R0 Imm:0 Reg:R10 Reg:D15 Imm:0 Imm:14 Reg:Nil | vld1.16 {d15[0]}, [r0], r10 | may_load
  #|0xf9a11607	VLD3LNd16_UPD Reg:D1 Reg:D2 Reg:D3 Reg:R1 Reg:R1 Imm:0 Reg:R7 Reg:D1 Reg:D2 Reg:D3 Imm:0 Imm:14 Reg:Nil | vld3.16 {d1[0], d2[0], d3[0]}, [r1], r7 | may_load
  #|0xf9a149dd	VLD2LNq32_UPD Reg:D4 Reg:D6 Reg:R1 Reg:R1 Imm:8 Reg:Nil Reg:D4 Reg:D6 Imm:1 Imm:14 Reg:Nil | vld2.32 {d4[1], d6[1]}, [r1:64]! | may_load
  #|0xf9a1690d	VLD2LNd32_UPD Reg:D6 Reg:D7 Reg:R1 Reg:R1 Imm:0 Reg:Nil Reg:D6 Reg:D7 Imm:0 Imm:14 Reg:Nil | vld2.32 {d6[0], d7[0]}, [r1]! | may_load
  #|0xf9a30990	VLD2LNd32_UPD Reg:D0 Reg:D1 Reg:R3 Reg:R3 Imm:8 Reg:R0 Reg:D0 Reg:D1 Imm:1 Imm:14 Reg:Nil | vld2.32 {d0[1], d1[1]}, [r3:64], r0 | may_load
  #|0xf9a31e4f	VLD3DUPd16 Reg:D1 Reg:D2 Reg:D3 Reg:R3 Imm:0 Imm:14 Reg:Nil | vld3.16 {d1[], d2[], d3[]}, [r3] | may_load
  #|0xf9a37701	VLD4LNd16_UPD Reg:D7 Reg:D8 Reg:D9 Reg:D10 Reg:R3 Reg:R3 Imm:0 Reg:R1 Reg:D7 Reg:D8 Reg:D9 Reg:D10 Imm:0 Imm:14 Reg:Nil | vld4.16 {d7[0], d8[0], d9[0], d10[0]}, [r3], r1 | may_load
  #|0xf9a39c87	VLD1DUPd32wb_register Reg:D9 Reg:R3 Reg:R3 Imm:0 Reg:R7 Imm:14 Reg:Nil | vld1.32 {d9[]}, [r3], r7 | may_load
  #|0xf9a3fd3f	VLD2DUPd8x2 Reg:D15_D17 Reg:R3 Imm:2 Imm:14 Reg:Nil | vld2.8 {d15[], d17[]}, [r3:16] | may_load
  #|0xf9a43f10	VLD4DUPd8_UPD Reg:D3 Reg:D4 Reg:D5 Reg:D6 Reg:R4 Reg:R4 Imm:4 Reg:R0 Imm:14 Reg:Nil | vld4.8 {d3[], d4[], d5[], d6[]}, [r4:32], r0 | may_load
  #|0xf9a447bd	VLD4LNq16_UPD Reg:D4 Reg:D6 Reg:D8 Reg:D10 Reg:R4 Reg:R4 Imm:8 Reg:Nil Reg:D4 Reg:D6 Reg:D8 Reg:D10 Imm:2 Imm:14 Reg:Nil | vld4.16 {d4[2], d6[2], d8[2], d10[2]}, [r4:64]! | may_load
  #|0xf9a4b7a3	VLD4LNq16_UPD Reg:D11 Reg:D13 Reg:D15 Reg:D17 Reg:R4 Reg:R4 Imm:0 Reg:R3 Reg:D11 Reg:D13 Reg:D15 Reg:D17 Imm:2 Imm:14 Reg:Nil | vld4.16 {d11[2], d13[2], d15[2], d17[2]}, [r4], r3 | may_load
  #|0xf9a4ce00	VLD3DUPd8_UPD Reg:D12 Reg:D13 Reg:D14 Reg:R4 Reg:R4 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld3.8 {d12[], d13[], d14[]}, [r4], r0 | may_load
  #|0xf9a5d6ac	VLD3LNq16_UPD Reg:D13 Reg:D15 Reg:D17 Reg:R5 Reg:R5 Imm:0 Reg:R12 Reg:D13 Reg:D15 Reg:D17 Imm:2 Imm:14 Reg:Nil | vld3.16 {d13[2], d15[2], d17[2]}, [r5], r12 | may_load
  #|0xf9a6670d	VLD4LNd16_UPD Reg:D6 Reg:D7 Reg:D8 Reg:D9 Reg:R6 Reg:R6 Imm:0 Reg:Nil Reg:D6 Reg:D7 Reg:D8 Reg:D9 Imm:0 Imm:14 Reg:Nil | vld4.16 {d6[0], d7[0], d8[0], d9[0]}, [r6]! | may_load
  #|0xf9a6a806	VLD1LNd32_UPD Reg:D10 Reg:R6 Reg:R6 Imm:0 Reg:R6 Reg:D10 Imm:0 Imm:14 Reg:Nil | vld1.32 {d10[0]}, [r6], r6 | may_load
  #|0xf9a6eb09	VLD4LNd32_UPD Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:R6 Reg:R6 Imm:0 Reg:R9 Reg:D14 Reg:D15 Reg:D16 Reg:D17 Imm:0 Imm:14 Reg:Nil | vld4.32 {d14[0], d15[0], d16[0], d17[0]}, [r6], r9 | may_load
  #|0xf9a74f70	VLD4DUPq16_UPD Reg:D4 Reg:D6 Reg:D8 Reg:D10 Reg:R7 Reg:R7 Imm:8 Reg:R0 Imm:14 Reg:Nil | vld4.16 {d4[], d6[], d8[], d10[]}, [r7:64], r0 | may_load
  #|0xf9a7753d	VLD2LNq16_UPD Reg:D7 Reg:D9 Reg:R7 Reg:R7 Imm:4 Reg:Nil Reg:D7 Reg:D9 Imm:0 Imm:14 Reg:Nil | vld2.16 {d7[0], d9[0]}, [r7:32]! | may_load
  #|0xf9a77c45	VLD1DUPd16wb_register Reg:D7 Reg:R7 Reg:R7 Imm:0 Reg:R5 Imm:14 Reg:Nil | vld1.16 {d7[]}, [r7], r5 | may_load
  #|0xf9a7bd55	VLD2DUPd16wb_register Reg:D11_D12 Imm:0 Reg:R7 Imm:4 Reg:R5 Imm:14 Reg:Nil | vld2.16 {d11[], d12[]}, [r7:32], r5 | may_load
  #|0xf9a7ed34	VLD2DUPd8x2wb_register Reg:D14_D16 Imm:0 Reg:R7 Imm:2 Reg:R4 Imm:14 Reg:Nil | vld2.8 {d14[], d16[]}, [r7:16], r4 | may_load
  #|0xf9a7ef04	VLD4DUPd8_UPD Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:R7 Reg:R7 Imm:0 Reg:R4 Imm:14 Reg:Nil | vld4.8 {d14[], d15[], d16[], d17[]}, [r7], r4 | may_load
  #|0xf9a7fa40	VLD3LNq32_UPD Reg:D15 Reg:D17 Reg:D19 Reg:R7 Reg:R7 Imm:0 Reg:R0 Reg:D15 Reg:D17 Reg:D19 Imm:0 Imm:14 Reg:Nil | vld3.32 {d15[0], d17[0], d19[0]}, [r7], r0 | may_load
  #|0xf9a82d0d	VLD2DUPd8wb_fixed Reg:Q1 Imm:0 Reg:R8 Imm:0 Imm:14 Reg:Nil | vld2.8 {d2[], d3[]}, [r8]! | may_load
  #|0xf9a85c51	VLD1DUPd16wb_register Reg:D5 Reg:R8 Reg:R8 Imm:2 Reg:R1 Imm:14 Reg:Nil | vld1.16 {d5[]}, [r8:16], r1 | may_load
  #|0xf9a878b0	VLD1LNd32_UPD Reg:D7 Reg:R8 Reg:R8 Imm:4 Reg:R0 Reg:D7 Imm:1 Imm:14 Reg:Nil | vld1.32 {d7[1]}, [r8:32], r0 | may_load
  #|0xf9a8cf61	VLD4DUPq16_UPD Reg:D12 Reg:D14 Reg:D16 Reg:D18 Reg:R8 Reg:R8 Imm:0 Reg:R1 Imm:14 Reg:Nil | vld4.16 {d12[], d14[], d16[], d18[]}, [r8], r1 | may_load
  #|0xf9ab5c20	VLD1DUPq8wb_register Reg:D5_D6 Reg:R11 Reg:R11 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d5[], d6[]}, [r11], r0 | may_load
  #|0xf9ab620d	VLD3LNd8_UPD Reg:D6 Reg:D7 Reg:D8 Reg:R11 Reg:R11 Imm:0 Reg:Nil Reg:D6 Reg:D7 Reg:D8 Imm:0 Imm:14 Reg:Nil | vld3.8 {d6[0], d7[0], d8[0]}, [r11]! | may_load
  #|0xf9ab683f	VLD1LNd32 Reg:D6 Reg:R11 Imm:4 Reg:D6 Imm:0 Imm:14 Reg:Nil | vld1.32 {d6[0]}, [r11:32] | may_load
  #|0xf9ab8dae	VLD2DUPd32x2wb_register Reg:D8_D10 Imm:0 Reg:R11 Imm:0 Reg:LR Imm:14 Reg:Nil | vld2.32 {d8[], d10[]}, [r11], lr | may_load
  #|0xf9abef0d	VLD4DUPd8_UPD Reg:D14 Reg:D15 Reg:D16 Reg:D17 Reg:R11 Reg:R11 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld4.8 {d14[], d15[], d16[], d17[]}, [r11]! | may_load
  #|0xf9abf35d	VLD4LNd8_UPD Reg:D15 Reg:D16 Reg:D17 Reg:D18 Reg:R11 Reg:R11 Imm:4 Reg:Nil Reg:D15 Reg:D16 Reg:D17 Reg:D18 Imm:2 Imm:14 Reg:Nil | vld4.8 {d15[2], d16[2], d17[2], d18[2]}, [r11:32]! | may_load
  #|0xf9ac0f91	VLD4DUPd32_UPD Reg:D0 Reg:D1 Reg:D2 Reg:D3 Reg:R12 Reg:R12 Imm:8 Reg:R1 Imm:14 Reg:Nil | vld4.32 {d0[], d1[], d2[], d3[]}, [r12:64], r1 | may_load
  #|0xf9ac612b	VLD2LNd8_UPD Reg:D6 Reg:D7 Reg:R12 Reg:R12 Imm:0 Reg:R11 Reg:D6 Reg:D7 Imm:1 Imm:14 Reg:Nil | vld2.8 {d6[1], d7[1]}, [r12], r11 | may_load
  #|0xf9ac9b0d	VLD4LNd32_UPD Reg:D9 Reg:D10 Reg:D11 Reg:D12 Reg:R12 Reg:R12 Imm:0 Reg:Nil Reg:D9 Reg:D10 Reg:D11 Reg:D12 Imm:0 Imm:14 Reg:Nil | vld4.32 {d9[0], d10[0], d11[0], d12[0]}, [r12]! | may_load
  #|0xf9ae2954	VLD2LNq32_UPD Reg:D2 Reg:D4 Reg:LR Reg:LR Imm:8 Reg:R4 Reg:D2 Reg:D4 Imm:0 Imm:14 Reg:Nil | vld2.32 {d2[0], d4[0]}, [lr:64], r4 | may_load
  #|0xf9aec76d	VLD4LNq16_UPD Reg:D12 Reg:D14 Reg:D16 Reg:D18 Reg:LR Reg:LR Imm:0 Reg:Nil Reg:D12 Reg:D14 Reg:D16 Reg:D18 Imm:1 Imm:14 Reg:Nil | vld4.16 {d12[1], d14[1], d16[1], d18[1]}, [lr]! | may_load
  #|0xf9aecdbc	VLD2DUPd32x2wb_register Reg:D12_D14 Imm:0 Reg:LR Imm:8 Reg:R12 Imm:14 Reg:Nil | vld2.32 {d12[], d14[]}, [lr:64], r12 | may_load
  #|0xf9afc750	VLD4LNd16_UPD Reg:D12 Reg:D13 Reg:D14 Reg:D15 Reg:PC Reg:PC Imm:8 Reg:R0 Reg:D12 Reg:D13 Reg:D14 Reg:D15 Imm:1 Imm:14 Reg:Nil | vld4.16 {d12[1], d13[1], d14[1], d15[1]}, [pc:64], r0 | affect_cf,may_load
  #|0xf9c007dd	VST4LNd16_UPD Reg:R0 Reg:R0 Imm:8 Reg:Nil Reg:D16 Reg:D17 Reg:D18 Reg:D19 Imm:3 Imm:14 Reg:Nil | vst4.16 {d16[3], d17[3], d18[3], d19[3]}, [r0:64]! | may_store
  #|0xf9c025b8	VST2LNq16_UPD Reg:R0 Reg:R0 Imm:4 Reg:R8 Reg:D18 Reg:D20 Imm:2 Imm:14 Reg:Nil | vst2.16 {d18[2], d20[2]}, [r0:32], r8 | may_store
  #|0xf9c0771e	VST4LNd16_UPD Reg:R0 Reg:R0 Imm:8 Reg:LR Reg:D23 Reg:D24 Reg:D25 Reg:D26 Imm:0 Imm:14 Reg:Nil | vst4.16 {d23[0], d24[0], d25[0], d26[0]}, [r0:64], lr | may_store
  #|0xf9c0a3cf	VST4LNd8 Reg:R0 Imm:0 Reg:D26 Reg:D27 Reg:D28 Reg:D29 Imm:6 Imm:14 Reg:Nil | vst4.8 {d26[6], d27[6], d28[6], d29[6]}, [r0] | may_store
  #|0xf9c0a40a	VST1LNd16_UPD Reg:R0 Reg:R0 Imm:0 Reg:R10 Reg:D26 Imm:0 Imm:14 Reg:Nil | vst1.16 {d26[0]}, [r0], r10 | may_store
  #|0xf9c1291f	VST2LNd32 Reg:R1 Imm:8 Reg:D18 Reg:D19 Imm:0 Imm:14 Reg:Nil | vst2.32 {d18[0], d19[0]}, [r1:64] | may_store
  #|0xf9c1710f	VST2LNd8 Reg:R1 Imm:0 Reg:D23 Reg:D24 Imm:0 Imm:14 Reg:Nil | vst2.8 {d23[0], d24[0]}, [r1] | may_store
  #|0xf9c2994d	VST2LNq32_UPD Reg:R2 Reg:R2 Imm:0 Reg:Nil Reg:D25 Reg:D27 Imm:0 Imm:14 Reg:Nil | vst2.32 {d25[0], d27[0]}, [r2]! | may_store
  #|0xf9c2e4cd	VST1LNd16_UPD Reg:R2 Reg:R2 Imm:0 Reg:Nil Reg:D30 Imm:3 Imm:14 Reg:Nil | vst1.16 {d30[3]}, [r2]! | may_store
  #|0xf9c41597	VST2LNd16_UPD Reg:R4 Reg:R4 Imm:4 Reg:R7 Reg:D17 Reg:D18 Imm:2 Imm:14 Reg:Nil | vst2.16 {d17[2], d18[2]}, [r4:32], r7 | may_store
  #|0xf9c48b64	VST4LNq32_UPD Reg:R4 Reg:R4 Imm:16 Reg:R4 Reg:D24 Reg:D26 Reg:D28 Reg:D30 Imm:0 Imm:14 Reg:Nil | vst4.32 {d24[0], d26[0], d28[0], d30[0]}, [r4:128], r4 | may_store
  #|0xf9c5072e	VST4LNq16_UPD Reg:R5 Reg:R5 Imm:0 Reg:LR Reg:D16 Reg:D18 Reg:D20 Reg:D22 Imm:0 Imm:14 Reg:Nil | vst4.16 {d16[0], d18[0], d20[0], d22[0]}, [r5], lr | may_store
  #|0xf9c54831	VST1LNd32_UPD Reg:R5 Reg:R5 Imm:4 Reg:R1 Reg:D20 Imm:0 Imm:14 Reg:Nil | vst1.32 {d20[0]}, [r5:32], r1 | may_store
  #|0xf9c593dd	VST4LNd8_UPD Reg:R5 Reg:R5 Imm:4 Reg:Nil Reg:D25 Reg:D26 Reg:D27 Reg:D28 Imm:6 Imm:14 Reg:Nil | vst4.8 {d25[6], d26[6], d27[6], d28[6]}, [r5:32]! | may_store
  #|0xf9c6977d	VST4LNq16_UPD Reg:R6 Reg:R6 Imm:8 Reg:Nil Reg:D25 Reg:D27 Reg:D29 Reg:D31 Imm:1 Imm:14 Reg:Nil | vst4.16 {d25[1], d27[1], d29[1], d31[1]}, [r6:64]! | may_store
  #|0xf9c74b20	VST4LNd32_UPD Reg:R7 Reg:R7 Imm:16 Reg:R0 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Imm:0 Imm:14 Reg:Nil | vst4.32 {d20[0], d21[0], d22[0], d23[0]}, [r7:128], r0 | may_store
  #|0xf9c761fa	VST2LNd8_UPD Reg:R7 Reg:R7 Imm:2 Reg:R10 Reg:D22 Reg:D23 Imm:7 Imm:14 Reg:Nil | vst2.8 {d22[7], d23[7]}, [r7:16], r10 | may_store
  #|0xf9c843ff	VST4LNd8 Reg:R8 Imm:4 Reg:D20 Reg:D21 Reg:D22 Reg:D23 Imm:7 Imm:14 Reg:Nil | vst4.8 {d20[7], d21[7], d22[7], d23[7]}, [r8:32] | may_store
  #|0xf9c8720d	VST3LNd8_UPD Reg:R8 Reg:R8 Imm:0 Reg:Nil Reg:D23 Reg:D24 Reg:D25 Imm:0 Imm:14 Reg:Nil | vst3.8 {d23[0], d24[0], d25[0]}, [r8]! | may_store
  #|0xf9c900e2	VST1LNd8_UPD Reg:R9 Reg:R9 Imm:0 Reg:R2 Reg:D16 Imm:7 Imm:14 Reg:Nil | vst1.8 {d16[7]}, [r9], r2 | may_store
  #|0xf9c90a00	VST3LNd32_UPD Reg:R9 Reg:R9 Imm:0 Reg:R0 Reg:D16 Reg:D17 Reg:D18 Imm:0 Imm:14 Reg:Nil | vst3.32 {d16[0], d17[0], d18[0]}, [r9], r0 | may_store
  #|0xf9c9770f	VST4LNd16 Reg:R9 Imm:0 Reg:D23 Reg:D24 Reg:D25 Reg:D26 Imm:0 Imm:14 Reg:Nil | vst4.16 {d23[0], d24[0], d25[0], d26[0]}, [r9] | may_store
  #|0xf9cb45cf	VST2LNd16 Reg:R11 Imm:0 Reg:D20 Reg:D21 Imm:3 Imm:14 Reg:Nil | vst2.16 {d20[3], d21[3]}, [r11] | may_store
  #|0xf9cc37b0	VST4LNq16_UPD Reg:R12 Reg:R12 Imm:8 Reg:R0 Reg:D19 Reg:D21 Reg:D23 Reg:D25 Imm:2 Imm:14 Reg:Nil | vst4.16 {d19[2], d21[2], d23[2], d25[2]}, [r12:64], r0 | may_store
  #|0xf9cf3412	VST1LNd16_UPD Reg:PC Reg:PC Imm:2 Reg:R2 Reg:D19 Imm:0 Imm:14 Reg:Nil | vst1.16 {d19[0]}, [pc:16], r2 | affect_cf,may_store
  #|0xf9e05178	VLD2LNd8_UPD Reg:D21 Reg:D22 Reg:R0 Reg:R0 Imm:2 Reg:R8 Reg:D21 Reg:D22 Imm:3 Imm:14 Reg:Nil | vld2.8 {d21[3], d22[3]}, [r0:16], r8 | may_load
  #|0xf9e05ff2	VLD4DUPq32_UPD Reg:D21 Reg:D23 Reg:D25 Reg:D27 Reg:R0 Reg:R0 Imm:16 Reg:R2 Imm:14 Reg:Nil | vld4.32 {d21[], d23[], d25[], d27[]}, [r0:128], r2 | may_load
  #|0xf9e0c300	VLD4LNd8_UPD Reg:D28 Reg:D29 Reg:D30 Reg:D31 Reg:R0 Reg:R0 Imm:0 Reg:R0 Reg:D28 Reg:D29 Reg:D30 Reg:D31 Imm:0 Imm:14 Reg:Nil | vld4.8 {d28[0], d29[0], d30[0], d31[0]}, [r0], r0 | may_load
  #|0xf9e0cc00	VLD1DUPd8wb_register Reg:D28 Reg:R0 Reg:R0 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld1.8 {d28[]}, [r0], r0 | may_load
  #|0xf9e1299d	VLD2LNd32_UPD Reg:D18 Reg:D19 Reg:R1 Reg:R1 Imm:8 Reg:Nil Reg:D18 Reg:D19 Imm:1 Imm:14 Reg:Nil | vld2.32 {d18[1], d19[1]}, [r1:64]! | may_load
  #|0xf9e1350d	VLD2LNd16_UPD Reg:D19 Reg:D20 Reg:R1 Reg:R1 Imm:0 Reg:Nil Reg:D19 Reg:D20 Imm:0 Imm:14 Reg:Nil | vld2.16 {d19[0], d20[0]}, [r1]! | may_load
  #|0xf9e1b5ea	VLD2LNq16_UPD Reg:D27 Reg:D29 Reg:R1 Reg:R1 Imm:0 Reg:R10 Reg:D27 Reg:D29 Imm:3 Imm:14 Reg:Nil | vld2.16 {d27[3], d29[3]}, [r1], r10 | may_load
  #|0xf9e25c6b	VLD1DUPq16wb_register Reg:D21_D22 Reg:R2 Reg:R2 Imm:0 Reg:R11 Imm:14 Reg:Nil | vld1.16 {d21[], d22[]}, [r2], r11 | may_load
  #|0xf9e27f23	VLD4DUPq8_UPD Reg:D23 Reg:D25 Reg:D27 Reg:D29 Reg:R2 Reg:R2 Imm:0 Reg:R3 Imm:14 Reg:Nil | vld4.8 {d23[], d25[], d27[], d29[]}, [r2], r3 | may_load
  #|0xf9e2a5ba	VLD2LNq16_UPD Reg:D26 Reg:D28 Reg:R2 Reg:R2 Imm:4 Reg:R10 Reg:D26 Reg:D28 Imm:2 Imm:14 Reg:Nil | vld2.16 {d26[2], d28[2]}, [r2:32], r10 | may_load
  #|0xf9e31d7b	VLD2DUPd16x2wb_register Reg:D17_D19 Imm:0 Reg:R3 Imm:4 Reg:R11 Imm:14 Reg:Nil | vld2.16 {d17[], d19[]}, [r3:32], r11 | may_load
  #|0xf9e32a00	VLD3LNd32_UPD Reg:D18 Reg:D19 Reg:D20 Reg:R3 Reg:R3 Imm:0 Reg:R0 Reg:D18 Reg:D19 Reg:D20 Imm:0 Imm:14 Reg:Nil | vld3.32 {d18[0], d19[0], d20[0]}, [r3], r0 | may_load
  #|0xf9e415c7	VLD2LNd16_UPD Reg:D17 Reg:D18 Reg:R4 Reg:R4 Imm:0 Reg:R7 Reg:D17 Reg:D18 Imm:3 Imm:14 Reg:Nil | vld2.16 {d17[3], d18[3]}, [r4], r7 | may_load
  #|0xf9e4460d	VLD3LNd16_UPD Reg:D20 Reg:D21 Reg:D22 Reg:R4 Reg:R4 Imm:0 Reg:Nil Reg:D20 Reg:D21 Reg:D22 Imm:0 Imm:14 Reg:Nil | vld3.16 {d20[0], d21[0], d22[0]}, [r4]! | may_load
  #|0xf9e44c7f	VLD1DUPq16 Reg:Q10 Reg:R4 Imm:2 Imm:14 Reg:Nil | vld1.16 {d20[], d21[]}, [r4:16] | may_load
  #|0xf9e4694a	VLD2LNq32_UPD Reg:D22 Reg:D24 Reg:R4 Reg:R4 Imm:0 Reg:R10 Reg:D22 Reg:D24 Imm:0 Imm:14 Reg:Nil | vld2.32 {d22[0], d24[0]}, [r4], r10 | may_load
  #|0xf9e4be85	VLD3DUPd32_UPD Reg:D27 Reg:D28 Reg:D29 Reg:R4 Reg:R4 Imm:0 Reg:R5 Imm:14 Reg:Nil | vld3.32 {d27[], d28[], d29[]}, [r4], r5 | may_load
  #|0xf9e4d558	VLD2LNd16_UPD Reg:D29 Reg:D30 Reg:R4 Reg:R4 Imm:4 Reg:R8 Reg:D29 Reg:D30 Imm:1 Imm:14 Reg:Nil | vld2.16 {d29[1], d30[1]}, [r4:32], r8 | may_load
  #|0xf9e70003	VLD1LNd8_UPD Reg:D16 Reg:R7 Reg:R7 Imm:0 Reg:R3 Reg:D16 Imm:0 Imm:14 Reg:Nil | vld1.8 {d16[0]}, [r7], r3 | may_load
  #|0xf9e74900	VLD2LNd32_UPD Reg:D20 Reg:D21 Reg:R7 Reg:R7 Imm:0 Reg:R0 Reg:D20 Reg:D21 Imm:0 Imm:14 Reg:Nil | vld2.32 {d20[0], d21[0]}, [r7], r0 | may_load
  #|0xf9e76b2c	VLD4LNd32_UPD Reg:D22 Reg:D23 Reg:D24 Reg:D25 Reg:R7 Reg:R7 Imm:16 Reg:R12 Reg:D22 Reg:D23 Reg:D24 Reg:D25 Imm:0 Imm:14 Reg:Nil | vld4.32 {d22[0], d23[0], d24[0], d25[0]}, [r7:128], r12 | may_load
  #|0xf9e7ad4c	VLD2DUPd16wb_register Reg:Q13 Imm:0 Reg:R7 Imm:0 Reg:R12 Imm:14 Reg:Nil | vld2.16 {d26[], d27[]}, [r7], r12 | may_load
  #|0xf9e7ad83	VLD2DUPd32wb_register Reg:Q13 Imm:0 Reg:R7 Imm:0 Reg:R3 Imm:14 Reg:Nil | vld2.32 {d26[], d27[]}, [r7], r3 | may_load
  #|0xf9e82e0d	VLD3DUPd8_UPD Reg:D18 Reg:D19 Reg:D20 Reg:R8 Reg:R8 Imm:0 Reg:Nil Imm:14 Reg:Nil | vld3.8 {d18[], d19[], d20[]}, [r8]! | may_load
  #|0xf9e84fa5	VLD4DUPq32_UPD Reg:D20 Reg:D22 Reg:D24 Reg:D26 Reg:R8 Reg:R8 Imm:0 Reg:R5 Imm:14 Reg:Nil | vld4.32 {d20[], d22[], d24[], d26[]}, [r8], r5 | may_load
  #|0xf9e8c80f	VLD1LNd32 Reg:D28 Reg:R8 Imm:0 Reg:D28 Imm:0 Imm:14 Reg:Nil | vld1.32 {d28[0]}, [r8] | may_load
  #|0xf9e8ef40	VLD4DUPd16_UPD Reg:D30 Reg:D31 Reg:D0 Reg:D1 Reg:R8 Reg:R8 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld4.16 {d30[], d31[], d0[], d1[]}, [r8], r0 | may_load
  #|0xf9e97450	VLD1LNd16_UPD Reg:D23 Reg:R9 Reg:R9 Imm:2 Reg:R0 Reg:D23 Imm:1 Imm:14 Reg:Nil | vld1.16 {d23[1]}, [r9:16], r0 | may_load
  #|0xf9e9913d	VLD2LNd8_UPD Reg:D25 Reg:D26 Reg:R9 Reg:R9 Imm:2 Reg:Nil Reg:D25 Reg:D26 Imm:1 Imm:14 Reg:Nil | vld2.8 {d25[1], d26[1]}, [r9:16]! | may_load
  #|0xf9e9ad9a	VLD2DUPd32wb_register Reg:Q13 Imm:0 Reg:R9 Imm:8 Reg:R10 Imm:14 Reg:Nil | vld2.32 {d26[], d27[]}, [r9:64], r10 | may_load
  #|0xf9e9ed08	VLD2DUPd8wb_register Reg:Q15 Imm:0 Reg:R9 Imm:0 Reg:R8 Imm:14 Reg:Nil | vld2.8 {d30[], d31[]}, [r9], r8 | may_load
  #|0xf9ea6774	VLD4LNq16_UPD Reg:D22 Reg:D24 Reg:D26 Reg:D28 Reg:R10 Reg:R10 Imm:8 Reg:R4 Reg:D22 Reg:D24 Reg:D26 Reg:D28 Imm:1 Imm:14 Reg:Nil | vld4.16 {d22[1], d24[1], d26[1], d28[1]}, [r10:64], r4 | may_load
  #|0xf9eade40	VLD3DUPd16_UPD Reg:D29 Reg:D30 Reg:D31 Reg:R10 Reg:R10 Imm:0 Reg:R0 Imm:14 Reg:Nil | vld3.16 {d29[], d30[], d31[]}, [r10], r0 | may_load
  #|0xf9eb6b62	VLD4LNq32_UPD Reg:D22 Reg:D24 Reg:D26 Reg:D28 Reg:R11 Reg:R11 Imm:16 Reg:R2 Reg:D22 Reg:D24 Reg:D26 Reg:D28 Imm:0 Imm:14 Reg:Nil | vld4.32 {d22[0], d24[0], d26[0], d28[0]}, [r11:128], r2 | may_load
  #|0xf9eb8bc0	VLD4LNq32_UPD Reg:D24 Reg:D26 Reg:D28 Reg:D30 Reg:R11 Reg:R11 Imm:0 Reg:R0 Reg:D24 Reg:D26 Reg:D28 Reg:D30 Imm:1 Imm:14 Reg:Nil | vld4.32 {d24[1], d26[1], d28[1], d30[1]}, [r11], r0 | may_load
  #|0xf9ec00af	VLD1LNd8 Reg:D16 Reg:R12 Imm:0 Reg:D16 Imm:5 Imm:14 Reg:Nil | vld1.8 {d16[5]}, [r12] | may_load
  #|0xf9ec00cd	VLD1LNd8_UPD Reg:D16 Reg:R12 Reg:R12 Imm:0 Reg:Nil Reg:D16 Imm:6 Imm:14 Reg:Nil | vld1.8 {d16[6]}, [r12]! | may_load
  #|0xf9ec17cf	VLD4LNd16 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Reg:R12 Imm:0 Reg:D17 Reg:D18 Reg:D19 Reg:D20 Imm:3 Imm:14 Reg:Nil | vld4.16 {d17[3], d18[3], d19[3], d20[3]}, [r12] | may_load
  #|0xf9ec4f2f	VLD4DUPq8 Reg:D20 Reg:D22 Reg:D24 Reg:D26 Reg:R12 Imm:0 Imm:14 Reg:Nil | vld4.8 {d20[], d22[], d24[], d26[]}, [r12] | may_load
  #|0xf9ed831b	VLD4LNd8_UPD Reg:D24 Reg:D25 Reg:D26 Reg:D27 Reg:SP Reg:SP Imm:4 Reg:R11 Reg:D24 Reg:D25 Reg:D26 Reg:D27 Imm:0 Imm:14 Reg:Nil | vld4.8 {d24[0], d25[0], d26[0], d27[0]}, [sp:32], r11 | may_load
  #|0xf9ee1204	VLD3LNd8_UPD Reg:D17 Reg:D18 Reg:D19 Reg:LR Reg:LR Imm:0 Reg:R4 Reg:D17 Reg:D18 Reg:D19 Imm:0 Imm:14 Reg:Nil | vld3.8 {d17[0], d18[0], d19[0]}, [lr], r4 | may_load
  #|0xf9eeca0d	VLD3LNd32_UPD Reg:D28 Reg:D29 Reg:D30 Reg:LR Reg:LR Imm:0 Reg:Nil Reg:D28 Reg:D29 Reg:D30 Imm:0 Imm:14 Reg:Nil | vld3.32 {d28[0], d29[0], d30[0]}, [lr]! | may_load
  #|0xfa20f0c8	t2SXTAB16 Reg:R0 Reg:R0 Reg:R8 Imm:0 Imm:14 Reg:Nil | sxtab16 r0, r0, r8
  #|0xfa20fad0	t2SXTAB16 Reg:R10 Reg:R0 Reg:R0 Imm:1 Imm:14 Reg:Nil | sxtab16 r10, r0, r0, ror #8
  #|0xfa2ff0e0	t2SXTB16 Reg:R0 Reg:R0 Imm:2 Imm:14 Reg:Nil | sxtb16 r0, r0, ror #16
  #|0xfa2ff785	t2SXTB16 Reg:R7 Reg:R5 Imm:0 Imm:14 Reg:Nil | sxtb16 r7, r5
  #|0xfa30f1a0	t2UXTAB16 Reg:R1 Reg:R0 Reg:R0 Imm:2 Imm:14 Reg:Nil | uxtab16 r1, r0, r0, ror #16
  #|0xfa38f081	t2UXTAB16 Reg:R0 Reg:R8 Reg:R1 Imm:0 Imm:14 Reg:Nil | uxtab16 r0, r8, r1
  #|0xfa3fffd0	t2UXTB16 Reg:PC Reg:R0 Imm:1 Imm:14 Reg:Nil | uxtb16 pc, r0, ror #8 | affect_cf
  #|0xfa82fe94	t2QDADD Reg:LR Reg:R4 Reg:R2 Imm:14 Reg:Nil | qdadd lr, r4, r2
  #|0xfa84fa80	t2QADD Reg:R10 Reg:R0 Reg:R4 Imm:14 Reg:Nil | qadd r10, r0, r4
  #|0xfa85fa4e	t2UADD8 Reg:R10 Reg:R5 Reg:LR Imm:14 Reg:Nil | uadd8 r10, r5, lr | may_load,may_store
  #|0xfa86f526	t2SHADD8 Reg:R5 Reg:R6 Reg:R6 Imm:14 Reg:Nil | shadd8 r5, r6, r6
  #|0xfa87f2a0	t2QSUB Reg:R2 Reg:R0 Reg:R7 Imm:14 Reg:Nil | qsub r2, r0, r7
  #|0xfa8afc50	t2UQADD8 Reg:R12 Reg:R10 Reg:R0 Imm:14 Reg:Nil | uqadd8 r12, r10, r0
  #|0xfa8aff1a	t2QADD8 Reg:PC Reg:R10 Reg:R10 Imm:14 Reg:Nil | qadd8 pc, r10, r10 | affect_cf
  #|0xfa8bf009	t2SADD8 Reg:R0 Reg:R11 Reg:R9 Imm:14 Reg:Nil | sadd8 r0, r11, r9 | may_load,may_store
  #|0xfa8efd60	t2UHADD8 Reg:SP Reg:LR Reg:R0 Imm:14 Reg:Nil | uhadd8 sp, lr, r0
  #|0xfa8ff5b0	t2QDSUB Reg:R5 Reg:R0 Reg:PC Imm:14 Reg:Nil | qdsub r5, r0, pc
  #|0xfa90f047	t2UADD16 Reg:R0 Reg:R0 Reg:R7 Imm:14 Reg:Nil | uadd16 r0, r0, r7 | may_load,may_store
  #|0xfa90f1ae	t2RBIT Reg:R1 Reg:LR Imm:14 Reg:Nil | rbit r1, lr
  #|0xfa90f593	t2REV16 Reg:R5 Reg:R3 Imm:14 Reg:Nil | rev16.w r5, r3
  #|0xfa90f851	t2UQADD16 Reg:R8 Reg:R0 Reg:R1 Imm:14 Reg:Nil | uqadd16 r8, r0, r1
  #|0xfa90fd16	t2QADD16 Reg:SP Reg:R0 Reg:R6 Imm:14 Reg:Nil | qadd16 sp, r0, r6
  #|0xfa92f6b0	t2REVSH Reg:R6 Reg:R2 Imm:14 Reg:Nil | revsh.w r6, r2
  #|0xfa96f060	t2UHADD16 Reg:R0 Reg:R6 Reg:R0 Imm:14 Reg:Nil | uhadd16 r0, r6, r0
  #|0xfa96fb05	t2SADD16 Reg:R11 Reg:R6 Reg:R5 Imm:14 Reg:Nil | sadd16 r11, r6, r5 | may_load,may_store
  #|0xfa9efc20	t2SHADD16 Reg:R12 Reg:LR Reg:R0 Imm:14 Reg:Nil | shadd16 r12, lr, r0
  #|0xfa9ff780	t2REV Reg:R7 Reg:PC Imm:14 Reg:Nil | rev.w r7, pc
  #|0xfaa0f523	t2SHASX Reg:R5 Reg:R0 Reg:R3 Imm:14 Reg:Nil | shasx r5, r0, r3
  #|0xfaa0f860	t2UHASX Reg:R8 Reg:R0 Reg:R0 Imm:14 Reg:Nil | uhasx r8, r0, r0
  #|0xfaa0fd02	t2SASX Reg:SP Reg:R0 Reg:R2 Imm:14 Reg:Nil | sasx sp, r0, r2 | may_load,may_store
  #|0xfaa1f58a	t2SEL Reg:R5 Reg:R1 Reg:R10 Imm:14 Reg:Nil | sel r5, r1, r10 | may_load
  #|0xfaa4f010	t2QASX Reg:R0 Reg:R4 Reg:R0 Imm:14 Reg:Nil | qasx r0, r4, r0
  #|0xfaa4ff53	t2UQASX Reg:PC Reg:R4 Reg:R3 Imm:14 Reg:Nil | uqasx pc, r4, r3 | affect_cf
  #|0xfaa5f348	t2UASX Reg:R3 Reg:R5 Reg:R8 Imm:14 Reg:Nil | uasx r3, r5, r8 | may_load,may_store
  #|0xfabef889	t2CLZ Reg:R8 Reg:PC Imm:14 Reg:Nil | clz r8, pc
  #|0xfac0f00a	t2SSUB8 Reg:R0 Reg:R0 Reg:R10 Imm:14 Reg:Nil | ssub8 r0, r0, r10 | may_load,may_store
  #|0xfac0f027	t2SHSUB8 Reg:R0 Reg:R0 Reg:R7 Imm:14 Reg:Nil | shsub8 r0, r0, r7
  #|0xfac2f916	t2QSUB8 Reg:R9 Reg:R2 Reg:R6 Imm:14 Reg:Nil | qsub8 r9, r2, r6
  #|0xfac3f04b	t2USUB8 Reg:R0 Reg:R3 Reg:R11 Imm:14 Reg:Nil | usub8 r0, r3, r11 | may_load,may_store
  #|0xfac8f660	t2UHSUB8 Reg:R6 Reg:R8 Reg:R0 Imm:14 Reg:Nil | uhsub8 r6, r8, r0
  #|0xfac8fa50	t2UQSUB8 Reg:R10 Reg:R8 Reg:R0 Imm:14 Reg:Nil | uqsub8 r10, r8, r0
  #|0xfad0f019	t2QSUB16 Reg:R0 Reg:R0 Reg:R9 Imm:14 Reg:Nil | qsub16 r0, r0, r9
  #|0xfad0f022	t2SHSUB16 Reg:R0 Reg:R0 Reg:R2 Imm:14 Reg:Nil | shsub16 r0, r0, r2
  #|0xfad5f050	t2UQSUB16 Reg:R0 Reg:R5 Reg:R0 Imm:14 Reg:Nil | uqsub16 r0, r5, r0
  #|0xfadaf240	t2USUB16 Reg:R2 Reg:R10 Reg:R0 Imm:14 Reg:Nil | usub16 r2, r10, r0 | may_load,may_store
  #|0xfaddf26e	t2UHSUB16 Reg:R2 Reg:SP Reg:LR Imm:14 Reg:Nil | uhsub16 r2, sp, lr
  #|0xfadff800	t2SSUB16 Reg:R8 Reg:PC Reg:R0 Imm:14 Reg:Nil | ssub16 r8, pc, r0 | may_load,may_store
  #|0xfae0fd1f	t2QSAX Reg:SP Reg:R0 Reg:PC Imm:14 Reg:Nil | qsax sp, r0, pc
  #|0xfae0fe50	t2UQSAX Reg:LR Reg:R0 Reg:R0 Imm:14 Reg:Nil | uqsax lr, r0, r0
  #|0xfae2fb60	t2UHSAX Reg:R11 Reg:R2 Reg:R0 Imm:14 Reg:Nil | uhsax r11, r2, r0
  #|0xfae8f343	t2USAX Reg:R3 Reg:R8 Reg:R3 Imm:14 Reg:Nil | usax r3, r8, r3 | may_load,may_store
  #|0xfaeaf027	t2SHSAX Reg:R0 Reg:R10 Reg:R7 Imm:14 Reg:Nil | shsax r0, r10, r7
  #|0xfaeff000	t2SSAX Reg:R0 Reg:PC Reg:R0 Imm:14 Reg:Nil | ssax r0, pc, r0 | may_load,may_store
  #|0xfb42d716	t2SMLSDX Reg:R7 Reg:R2 Reg:R6 Reg:SP Imm:14 Reg:Nil | smlsdx r7, r2, r6, sp
  #|0xfb44fb00	t2SMUSD Reg:R11 Reg:R4 Reg:R0 Imm:14 Reg:Nil | smusd r11, r4, r0
  #|0xfb4af219	t2SMUSDX Reg:R2 Reg:R10 Reg:R9 Imm:14 Reg:Nil | smusdx r2, r10, r9
  #|0xfb4dd70a	t2SMLSD Reg:R7 Reg:SP Reg:R10 Reg:SP Imm:14 Reg:Nil | smlsd r7, sp, r10, sp
  #|0xfb500907	t2SMMLA Reg:R9 Reg:R0 Reg:R7 Reg:R0 Imm:14 Reg:Nil | smmla r9, r0, r7, r0
  #|0xfb50f408	t2SMMUL Reg:R4 Reg:R0 Reg:R8 Imm:14 Reg:Nil | smmul r4, r0, r8
  #|0xfb50f71c	t2SMMULR Reg:R7 Reg:R0 Reg:R12 Imm:14 Reg:Nil | smmulr r7, r0, r12
  #|0xfb5fa01b	t2SMMLAR Reg:R0 Reg:PC Reg:R11 Reg:R10 Imm:14 Reg:Nil | smmlar r0, pc, r11, r10
  #|0xfb600d1f	t2SMMLSR Reg:SP Reg:R0 Reg:PC Reg:R0 Imm:14 Reg:Nil | smmlsr sp, r0, pc, r0
  #|0xfb6fdb04	t2SMMLS Reg:R11 Reg:PC Reg:R4 Reg:SP Imm:14 Reg:Nil | smmls r11, pc, r4, sp
  #|0xfb781004	t2USADA8 Reg:R0 Reg:R8 Reg:R4 Reg:R1 Imm:14 Reg:Nil | usada8 r0, r8, r4, r1
  #|0xfb7cfc0f	t2USAD8 Reg:R12 Reg:R12 Reg:PC Imm:14 Reg:Nil | usad8 r12, r12, pc
  #|0xfbc13185	t2SMLALBB Reg:R3 Reg:R1 Reg:R1 Reg:R5 Reg:R3 Reg:R1 Imm:14 Reg:Nil | smlalbb r3, r1, r1, r5
  #|0xfbc206a7	t2SMLALTB Reg:R0 Reg:R6 Reg:R2 Reg:R7 Reg:R0 Reg:R6 Imm:14 Reg:Nil | smlaltb r0, r6, r2, r7
  #|0xfbc708b0	t2SMLALTT Reg:R0 Reg:R8 Reg:R7 Reg:R0 Reg:R0 Reg:R8 Imm:14 Reg:Nil | smlaltt r0, r8, r7, r0
  #|0xfbc860c9	t2SMLALD Reg:R6 Reg:R0 Reg:R8 Reg:R9 Reg:R6 Reg:R0 Imm:14 Reg:Nil | smlald r6, r0, r8, r9
  #|0xfbce0090	t2SMLALBT Reg:R0 Reg:R0 Reg:LR Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | smlalbt r0, r0, lr, r0
  #|0xfbce05d0	t2SMLALDX Reg:R0 Reg:R5 Reg:LR Reg:R0 Reg:R0 Reg:R5 Imm:14 Reg:Nil | smlaldx r0, r5, lr, r0
  #|0xfbd5a6d3	t2SMLSLDX Reg:R10 Reg:R6 Reg:R5 Reg:R3 Reg:R10 Reg:R6 Imm:14 Reg:Nil | smlsldx r10, r6, r5, r3
  #|0xfbddf0c4	t2SMLSLD Reg:PC Reg:R0 Reg:SP Reg:R4 Reg:PC Reg:R0 Imm:14 Reg:Nil | smlsld pc, r0, sp, r4 | affect_cf
  #|0xfbe28063	t2UMAAL Reg:R8 Reg:R0 Reg:R2 Reg:R3 Reg:R8 Reg:R0 Imm:14 Reg:Nil | umaal r8, r0, r2, r3
  #|0xfc23e834	t2STC2_POST Imm:8 Imm:14 Reg:R3 Imm:52 Imm:14 Reg:Nil | stc2 p8, c14, [r3], #-208 | may_store
  #|0xfc480045	t2MCRR2 Imm:0 Imm:4 Reg:R0 Reg:R8 Imm:5 Imm:14 Reg:Nil | mcrr2 p0, #4, r0, r8, c5 | may_load,may_store
  #|0xfc524cfc	t2MRRC2 Reg:R4 Reg:R2 Imm:12 Imm:15 Imm:12 Imm:14 Reg:Nil | mrrc2 p12, #15, r4, r2, c12
  #|0xfc86710f	t2STC2_OPTION Imm:1 Imm:7 Reg:R6 Imm:15 Imm:14 Reg:Nil | stc2 p1, c7, [r6], {15} | may_store
  #|0xfc9a0074	t2LDC2_OPTION Imm:0 Imm:0 Reg:R10 Imm:116 Imm:14 Reg:Nil | ldc2 p0, c0, [r10], {116} | may_load
  #|0xfcb9ce0f	t2LDC2_POST Imm:14 Imm:12 Reg:R9 Imm:271 Imm:14 Reg:Nil | ldc2 p14, c12, [r9], #60 | may_load
  #|0xfcc700ad	t2STC2L_OPTION Imm:0 Imm:0 Reg:R7 Imm:173 Imm:14 Reg:Nil | stc2l p0, c0, [r7], {173} | may_store
  #|0xfcd100d7	t2LDC2L_OPTION Imm:0 Imm:0 Reg:R1 Imm:215 Imm:14 Reg:Nil | ldc2l p0, c0, [r1], {215} | may_load
  #|0xfce5119a	t2STC2L_POST Imm:1 Imm:1 Reg:R5 Imm:410 Imm:14 Reg:Nil | stc2l p1, c1, [r5], #616 | may_store
  #|0xfcf56f03	t2LDC2L_POST Imm:15 Imm:6 Reg:R5 Imm:259 Imm:14 Reg:Nil | ldc2l p15, c6, [r5], #12 | may_load
  #|0xfd3ae505	t2LDC2_PRE Imm:5 Imm:14 Reg:R10 Imm:261 Imm:14 Reg:Nil | ldc2 p5, c14, [r10, #-20]! | may_load
  #|0xfd55a4eb	t2LDC2L_OFFSET Imm:4 Imm:10 Reg:R5 Imm:491 Imm:14 Reg:Nil | ldc2l p4, c10, [r5, #-940] | may_load,may_store
  #|0xfd631018	t2STC2L_PRE Imm:0 Imm:1 Reg:R3 Imm:280 Imm:14 Reg:Nil | stc2l p0, c1, [r3, #-96]! | may_store
  #|0xfd8c0000	t2STC2_OFFSET Imm:0 Imm:0 Reg:R12 Imm:0 Imm:14 Reg:Nil | stc2 p0, c0, [r12] | may_load,may_store
  #|0xfd8e0043	t2STC2_OFFSET Imm:0 Imm:0 Reg:LR Imm:67 Imm:14 Reg:Nil | stc2 p0, c0, [lr, #268] | may_load,may_store
  #|0xfd923c45	t2LDC2_OFFSET Imm:12 Imm:3 Reg:R2 Imm:69 Imm:14 Reg:Nil | ldc2 p12, c3, [r2, #276] | may_load,may_store
  #|0xfd948200	t2LDC2_OFFSET Imm:2 Imm:8 Reg:R4 Imm:0 Imm:14 Reg:Nil | ldc2 p2, c8, [r4] | may_load,may_store
  #|0xfdad5770	t2STC2_PRE Imm:7 Imm:5 Reg:SP Imm:112 Imm:14 Reg:Nil | stc2 p7, c5, [sp, #448]! | may_store
  #|0xfdc68900	t2STC2L_OFFSET Imm:9 Imm:8 Reg:R6 Imm:0 Imm:14 Reg:Nil | stc2l p9, c8, [r6] | may_load,may_store
  #|0xfdccf620	t2STC2L_OFFSET Imm:6 Imm:15 Reg:R12 Imm:32 Imm:14 Reg:Nil | stc2l p6, c15, [r12, #128] | may_load,may_store
  #|0xfddfa300	t2LDC2L_OFFSET Imm:3 Imm:10 Reg:PC Imm:0 Imm:14 Reg:Nil | ldc2l p3, c10, [pc] | may_load,may_store
  #|0xfdf9000e	t2LDC2L_PRE Imm:0 Imm:0 Reg:R9 Imm:14 Imm:14 Reg:Nil | ldc2l p0, c0, [r9, #56]! | may_load
  #|0xfe3b2779	t2MRC2 Reg:R2 Imm:7 Imm:1 Imm:11 Imm:9 Imm:3 Imm:14 Reg:Nil | mrc2 p7, #1, r2, c11, c9, #3 | may_load,may_store
  #|0xfe6aafb9	t2MCR2 Imm:15 Imm:3 Reg:R10 Imm:10 Imm:9 Imm:5 Imm:14 Reg:Nil | mcr2 p15, #3, r10, c10, c9, #5 | may_load,may_store
  #|0xfe8dd702	t2CDP2 Imm:7 Imm:8 Imm:13 Imm:13 Imm:2 Imm:0 Imm:14 Reg:Nil | cdp2 p7, #8, c13, c13, c2, #0 | may_load,may_store
  #|0xfebbf575	t2MRC2 Reg:APSR_NZCV Imm:5 Imm:5 Imm:11 Imm:5 Imm:3 Imm:14 Reg:Nil | mrc2 p5, #5, apsr_nzcv, c11, c5, #3 | may_load,may_store
  #|0xff0000ba	VQADDuv8i8 Reg:D0 Reg:D16 Reg:D26 Imm:14 Reg:Nil | vqadd.u8 d0, d16, d26
  #|0xff0000ce	VHADDuv16i8 Reg:Q0 Reg:Q8 Reg:Q7 Imm:14 Reg:Nil | vhadd.u8 q0, q8, q7
  #|0xff000312	VCGEuv8i8 Reg:D0 Reg:D0 Reg:D2 Imm:14 Reg:Nil | vcge.u8 d0, d0, d2
  #|0xff0007f0	VABAuv16i8 Reg:Q0 Reg:Q0 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vaba.u8 q0, q8, q8
  #|0xff000850	VCEQv16i8 Reg:Q0 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vceq.i8 q0, q0, q0
  #|0xff00199e	VMULpd Reg:D1 Reg:D16 Reg:D14 Imm:14 Reg:Nil | vmul.p8 d1, d16, d14
  #|0xff001e00	VCGEfd Reg:D1 Reg:D0 Reg:D0 Imm:14 Reg:Nil | vcge.f32 d1, d0, d0
  #|0xff002356	VCGEuv16i8 Reg:Q1 Reg:Q0 Reg:Q3 Imm:14 Reg:Nil | vcge.u8 q1, q0, q3
  #|0xff00261f	VMINuv8i8 Reg:D2 Reg:D0 Reg:D15 Imm:14 Reg:Nil | vmin.u8 d2, d0, d15
  #|0xff0027c8	VABDuv16i8 Reg:Q1 Reg:Q8 Reg:Q4 Imm:14 Reg:Nil | vabd.u8 q1, q8, q4
  #|0xff004160	VRHADDuv16i8 Reg:Q2 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vrhadd.u8 q2, q0, q8
  #|0xff0046a0	VMAXuv8i8 Reg:D4 Reg:D16 Reg:D16 Imm:14 Reg:Nil | vmax.u8 d4, d16, d16
  #|0xff0049ea	VMLSv16i8 Reg:Q2 Reg:Q2 Reg:Q8 Reg:Q13 Imm:14 Reg:Nil | vmls.i8 q2, q8, q13
  #|0xff004e1d	VACGEfd Reg:D4 Reg:D0 Reg:D13 Imm:14 Reg:Nil | vacge.f32 d4, d0, d13
  #|0xff004ef0	VACGEfq Reg:Q2 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vacge.f32 q2, q8, q8
  #|0xff00559a	VQRSHLuv8i8 Reg:D5 Reg:D10 Reg:D16 Imm:14 Reg:Nil | vqrshl.u8 d5, d10, d16
  #|0xff005d0a	VPADDf Reg:D5 Reg:D0 Reg:D10 Imm:14 Reg:Nil | vpadd.f32 d5, d0, d10
  #|0xff00617c	VEORq Reg:Q3 Reg:Q0 Reg:Q14 Imm:14 Reg:Nil | veor q3, q0, q14
  #|0xff0061a0	VRHADDuv8i8 Reg:D6 Reg:D16 Reg:D16 Imm:14 Reg:Nil | vrhadd.u8 d6, d16, d16
  #|0xff008130	VEORd Reg:D8 Reg:D0 Reg:D16 Imm:14 Reg:Nil | veor d8, d0, d16
  #|0xff008340	VCGTuv16i8 Reg:Q4 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vcgt.u8 q4, q0, q0
  #|0xff0085dc	VQRSHLuv16i8 Reg:Q4 Reg:Q6 Reg:Q8 Imm:14 Reg:Nil | vqrshl.u8 q4, q6, q8
  #|0xff00870f	VABDuv8i8 Reg:D8 Reg:D0 Reg:D15 Imm:14 Reg:Nil | vabd.u8 d8, d0, d15
  #|0xff0089f0	VMULpq Reg:Q4 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vmul.p8 q4, q8, q8
  #|0xff00a25a	VQSUBuv16i8 Reg:Q5 Reg:Q0 Reg:Q5 Imm:14 Reg:Nil | vqsub.u8 q5, q0, q5
  #|0xff00a43b	VQSHLuv8i8 Reg:D10 Reg:D27 Reg:D0 Imm:14 Reg:Nil | vqshl.u8 d10, d27, d0
  #|0xff00a50c	VRSHLuv8i8 Reg:D10 Reg:D12 Reg:D0 Imm:14 Reg:Nil | vrshl.u8 d10, d12, d0
  #|0xff00a83f	VCEQv8i8 Reg:D10 Reg:D0 Reg:D31 Imm:14 Reg:Nil | vceq.i8 d10, d0, d31
  #|0xff00c46e	VSHLuv16i8 Reg:Q6 Reg:Q15 Reg:Q0 Imm:14 Reg:Nil | vshl.u8 q6, q15, q0
  #|0xff00c5ca	VRSHLuv16i8 Reg:Q6 Reg:Q5 Reg:Q8 Imm:14 Reg:Nil | vrshl.u8 q6, q5, q8
  #|0xff00c905	VMLSv8i8 Reg:D12 Reg:D12 Reg:D0 Reg:D5 Imm:14 Reg:Nil | vmls.i8 d12, d0, d5
  #|0xff00cdd0	VMULfq Reg:Q6 Reg:Q8 Reg:Q0 Imm:14 Reg:Nil | vmul.f32 q6, q8, q0
  #|0xff00d290	VQSUBuv8i8 Reg:D13 Reg:D16 Reg:D0 Imm:14 Reg:Nil | vqsub.u8 d13, d16, d0
  #|0xff00d400	VSHLuv8i8 Reg:D13 Reg:D0 Reg:D0 Imm:14 Reg:Nil | vshl.u8 d13, d0, d0
  #|0xff00e088	VHADDuv8i8 Reg:D14 Reg:D16 Reg:D8 Imm:14 Reg:Nil | vhadd.u8 d14, d16, d8
  #|0xff00e2ea	VHSUBuv16i8 Reg:Q7 Reg:Q8 Reg:Q13 Imm:14 Reg:Nil | vhsub.u8 q7, q8, q13
  #|0xff00e454	VQSHLuv16i8 Reg:Q7 Reg:Q2 Reg:Q0 Imm:14 Reg:Nil | vqshl.u8 q7, q2, q0
  #|0xff00e6f0	VMINuv16i8 Reg:Q7 Reg:Q8 Reg:Q8 Imm:14 Reg:Nil | vmin.u8 q7, q8, q8
  #|0xff00ffa3	VPMAXf Reg:D15 Reg:D16 Reg:D19 Imm:14 Reg:Nil | vpmax.f32 d15, d16, d19
  #|0xff02b306	VCGTuv8i8 Reg:D11 Reg:D2 Reg:D6 Imm:14 Reg:Nil | vcgt.u8 d11, d2, d6
  #|0xff0600f6	VQADDuv16i8 Reg:Q0 Reg:Q11 Reg:Q11 Imm:14 Reg:Nil | vqadd.u8 q0, q11, q11
  #|0xff062e44	VCGEfq Reg:Q1 Reg:Q3 Reg:Q2 Imm:14 Reg:Nil | vcge.f32 q1, q3, q2
  #|0xff0cda30	VPMINu8 Reg:D13 Reg:D12 Reg:D16 Imm:14 Reg:Nil | vpmin.u8 d13, d12, d16
  #|0xff10084a	VSUBv8i16 Reg:Q0 Reg:Q0 Reg:Q5 Imm:14 Reg:Nil | vsub.i16 q0, q0, q5
  #|0xff103100	VRHADDuv4i16 Reg:D3 Reg:D0 Reg:D0 Imm:14 Reg:Nil | vrhadd.u16 d3, d0, d0
  #|0xff1051b0	VBSLd Reg:D5 Reg:D5 Reg:D16 Reg:D16 Imm:14 Reg:Nil | vbsl d5, d16, d16
  #|0xff129920	VMLSv4i16 Reg:D9 Reg:D9 Reg:D2 Reg:D16 Imm:14 Reg:Nil | vmls.i16 d9, d2, d16
  #|0xff140770	VABAuv8i16 Reg:Q0 Reg:Q0 Reg:Q2 Reg:Q8 Imm:14 Reg:Nil | vaba.u16 q0, q2, q8
  #|0xff1473bb	VCGEuv4i16 Reg:D7 Reg:D20 Reg:D27 Imm:14 Reg:Nil | vcge.u16 d7, d20, d27
  #|0xff15ea83	VPMAXu16 Reg:D14 Reg:D21 Reg:D3 Imm:14 Reg:Nil | vpmax.u16 d14, d21, d3
  #|0xff17449c	VQSHLuv4i16 Reg:D4 Reg:D12 Reg:D23 Imm:14 Reg:Nil | vqshl.u16 d4, d12, d23
  #|0xff17e8a1	VSUBv4i16 Reg:D14 Reg:D23 Reg:D17 Imm:14 Reg:Nil | vsub.i16 d14, d23, d17
  #|0xff188300	VCGTuv4i16 Reg:D8 Reg:D8 Reg:D0 Imm:14 Reg:Nil | vcgt.u16 d8, d8, d0
  #|0xff190090	VQADDuv4i16 Reg:D0 Reg:D25 Reg:D0 Imm:14 Reg:Nil | vqadd.u16 d0, d25, d0
  #|0xff19b59a	VQRSHLuv4i16 Reg:D11 Reg:D10 Reg:D25 Imm:14 Reg:Nil | vqrshl.u16 d11, d10, d25
  #|0xff19e810	VCEQv4i16 Reg:D14 Reg:D9 Reg:D0 Imm:14 Reg:Nil | vceq.i16 d14, d9, d0
  #|0xff1a021a	VQSUBuv4i16 Reg:D0 Reg:D10 Reg:D10 Imm:14 Reg:Nil | vqsub.u16 d0, d10, d10
  #|0xff1a8350	VCGEuv8i16 Reg:Q4 Reg:Q5 Reg:Q0 Imm:14 Reg:Nil | vcge.u16 q4, q5, q0
  #|0xff1bbb08	VQRDMULHv4i16 Reg:D11 Reg:D11 Reg:D8 Imm:14 Reg:Nil | vqrdmulh.s16 d11, d11, d8
  #|0xff1ff480	VSHLuv4i16 Reg:D15 Reg:D0 Reg:D31 Imm:14 Reg:Nil | vshl.u16 d15, d0, d31
  #|0xff21009c	VQADDuv2i32 Reg:D0 Reg:D17 Reg:D12 Imm:14 Reg:Nil | vqadd.u32 d0, d17, d12
  #|0xff226a10	VPMINu32 Reg:D6 Reg:D2 Reg:D0 Imm:14 Reg:Nil | vpmin.u32 d6, d2, d0
  #|0xff22a68c	VMAXuv2i32 Reg:D10 Reg:D18 Reg:D12 Imm:14 Reg:Nil | vmax.u32 d10, d18, d12
  #|0xff22ce85	VCGTfd Reg:D12 Reg:D18 Reg:D5 Imm:14 Reg:Nil | vcgt.f32 d12, d18, d5
  #|0xff232297	VQSUBuv2i32 Reg:D2 Reg:D19 Reg:D7 Imm:14 Reg:Nil | vqsub.u32 d2, d19, d7
  #|0xff255432	VQSHLuv2i32 Reg:D5 Reg:D18 Reg:D5 Imm:14 Reg:Nil | vqshl.u32 d5, d18, d5
  #|0xff25d800	VSUBv2i32 Reg:D13 Reg:D5 Reg:D0 Imm:14 Reg:Nil | vsub.i32 d13, d5, d0
  #|0xff268550	VQRSHLuv4i32 Reg:Q4 Reg:Q0 Reg:Q3 Imm:14 Reg:Nil | vqrshl.u32 q4, q0, q3
  #|0xff27cf88	VPMINf Reg:D12 Reg:D23 Reg:D8 Imm:14 Reg:Nil | vpmin.f32 d12, d23, d8
  #|0xff2800f6	VQADDuv4i32 Reg:Q0 Reg:Q12 Reg:Q11 Imm:14 Reg:Nil | vqadd.u32 q0, q12, q11
  #|0xff28a850	VCEQv4i32 Reg:Q5 Reg:Q4 Reg:Q0 Imm:14 Reg:Nil | vceq.i32 q5, q4, q0
  #|0xff29db00	VQRDMULHv2i32 Reg:D13 Reg:D9 Reg:D0 Imm:14 Reg:Nil | vqrdmulh.s32 d13, d9, d0
  #|0xff2a00e0	VHADDuv4i32 Reg:Q0 Reg:Q13 Reg:Q8 Imm:14 Reg:Nil | vhadd.u32 q0, q13, q8
  #|0xff2a43ab	VCGTuv2i32 Reg:D4 Reg:D26 Reg:D27 Imm:14 Reg:Nil | vcgt.u32 d4, d26, d27
  #|0xff2ae508	VRSHLuv2i32 Reg:D14 Reg:D8 Reg:D10 Imm:14 Reg:Nil | vrshl.u32 d14, d8, d10
  #|0xff2cae33	VACGTfd Reg:D10 Reg:D12 Reg:D19 Imm:14 Reg:Nil | vacgt.f32 d10, d12, d19
  #|0xff2ea40d	VSHLuv2i32 Reg:D10 Reg:D13 Reg:D14 Imm:14 Reg:Nil | vshl.u32 d10, d13, d14
  #|0xff2f498f	VMLSv2i32 Reg:D4 Reg:D4 Reg:D31 Reg:D15 Imm:14 Reg:Nil | vmls.i32 d4, d31, d15
  #|0xff30d4bd	VQSHLuv1i64 Reg:D13 Reg:D29 Reg:D16 Imm:14 Reg:Nil | vqshl.u64 d13, d29, d16
  #|0xff34f2b1	VQSUBuv1i64 Reg:D15 Reg:D20 Reg:D17 Imm:14 Reg:Nil | vqsub.u64 d15, d20, d17
  #|0xff385506	VRSHLuv1i64 Reg:D5 Reg:D6 Reg:D8 Imm:14 Reg:Nil | vrshl.u64 d5, d6, d8
  #|0xff387409	VSHLuv1i64 Reg:D7 Reg:D9 Reg:D8 Imm:14 Reg:Nil | vshl.u64 d7, d9, d8
  #|0xff3a05c4	VRSHLuv2i64 Reg:Q0 Reg:Q2 Reg:Q13 Imm:14 Reg:Nil | vrshl.u64 q0, q2, q13
  #|0xff3b003b	VQADDuv1i64 Reg:D0 Reg:D11 Reg:D27 Imm:14 Reg:Nil | vqadd.u64 d0, d11, d27
  #|0xff3e44f2	VQSHLuv2i64 Reg:Q2 Reg:Q9 Reg:Q15 Imm:14 Reg:Nil | vqshl.u64 q2, q9, q15
  #|0xff428a0c	VPMAXu8 Reg:D24 Reg:D2 Reg:D12 Imm:14 Reg:Nil | vpmax.u8 d24, d2, d12
  #|0xff428d12	VMULfd Reg:D24 Reg:D2 Reg:D2 Imm:14 Reg:Nil | vmul.f32 d24, d2, d2
  #|0xff457829	VSUBv8i8 Reg:D23 Reg:D5 Reg:D25 Imm:14 Reg:Nil | vsub.i8 d23, d5, d25
  #|0xff4b471c	VABAuv8i8 Reg:D20 Reg:D20 Reg:D11 Reg:D12 Imm:14 Reg:Nil | vaba.u8 d20, d11, d12
  #|0xff4c2840	VSUBv16i8 Reg:Q9 Reg:Q6 Reg:Q0 Imm:14 Reg:Nil | vsub.i8 q9, q6, q0
  #|0xff4c5203	VHSUBuv8i8 Reg:D21 Reg:D12 Reg:D3 Imm:14 Reg:Nil | vhsub.u8 d21, d12, d3
  #|0xff50f220	VHSUBuv4i16 Reg:D31 Reg:D0 Reg:D16 Imm:14 Reg:Nil | vhsub.u16 d31, d0, d16
  #|0xff52007e	VQADDuv8i16 Reg:Q8 Reg:Q1 Reg:Q15 Imm:14 Reg:Nil | vqadd.u16 q8, q1, q15
  #|0xff52400a	VHADDuv4i16 Reg:D20 Reg:D2 Reg:D10 Imm:14 Reg:Nil | vhadd.u16 d20, d2, d10
  #|0xff526690	VMINuv4i16 Reg:D22 Reg:D18 Reg:D0 Imm:14 Reg:Nil | vmin.u16 d22, d18, d0
  #|0xff56006e	VHADDuv8i16 Reg:Q8 Reg:Q3 Reg:Q15 Imm:14 Reg:Nil | vhadd.u16 q8, q3, q15
  #|0xff57ca10	VPMINu16 Reg:D28 Reg:D7 Reg:D0 Imm:14 Reg:Nil | vpmin.u16 d28, d7, d0
  #|0xff5a1711	VABAuv4i16 Reg:D17 Reg:D17 Reg:D10 Reg:D1 Imm:14 Reg:Nil | vaba.u16 d17, d10, d1
  #|0xff5a8700	VABDuv4i16 Reg:D24 Reg:D10 Reg:D0 Imm:14 Reg:Nil | vabd.u16 d24, d10, d0
  #|0xff5f768c	VMAXuv4i16 Reg:D23 Reg:D31 Reg:D12 Imm:14 Reg:Nil | vmax.u16 d23, d31, d12
  #|0xff5f95a8	VRSHLuv4i16 Reg:D25 Reg:D24 Reg:D31 Imm:14 Reg:Nil | vrshl.u16 d25, d24, d31
  #|0xff6405bb	VQRSHLuv2i32 Reg:D16 Reg:D27 Reg:D20 Imm:14 Reg:Nil | vqrshl.u32 d16, d27, d20
  #|0xff643392	VCGEuv2i32 Reg:D19 Reg:D20 Reg:D2 Imm:14 Reg:Nil | vcge.u32 d19, d20, d2
  #|0xff65000d	VHADDuv2i32 Reg:D16 Reg:D5 Reg:D13 Imm:14 Reg:Nil | vhadd.u32 d16, d5, d13
  #|0xff655103	VRHADDuv2i32 Reg:D21 Reg:D5 Reg:D3 Imm:14 Reg:Nil | vrhadd.u32 d21, d5, d3
  #|0xff668b40	VQRDMULHv4i32 Reg:Q12 Reg:Q3 Reg:Q0 Imm:14 Reg:Nil | vqrdmulh.s32 q12, q3, q0
  #|0xff66a14a	VRHADDuv4i32 Reg:Q13 Reg:Q3 Reg:Q5 Imm:14 Reg:Nil | vrhadd.u32 q13, q3, q5
  #|0xff671a0b	VPMAXu32 Reg:D17 Reg:D7 Reg:D11 Imm:14 Reg:Nil | vpmax.u32 d17, d7, d11
  #|0xff678790	VABAuv2i32 Reg:D24 Reg:D24 Reg:D23 Reg:D0 Imm:14 Reg:Nil | vaba.u32 d24, d23, d0
  #|0xff68bd01	VABDfd Reg:D27 Reg:D8 Reg:D1 Imm:14 Reg:Nil | vabd.f32 d27, d8, d1
  #|0xff6b7810	VCEQv2i32 Reg:D23 Reg:D11 Reg:D0 Imm:14 Reg:Nil | vceq.i32 d23, d11, d0
  #|0xff6c0ef0	VACGTfq Reg:Q8 Reg:Q14 Reg:Q8 Imm:14 Reg:Nil | vacgt.f32 q8, q14, q8
  #|0xff6d3206	VHSUBuv2i32 Reg:D19 Reg:D13 Reg:D6 Imm:14 Reg:Nil | vhsub.u32 d19, d13, d6
  #|0xff6d3700	VABDuv2i32 Reg:D19 Reg:D13 Reg:D0 Imm:14 Reg:Nil | vabd.u32 d19, d13, d0
  #|0xff708530	VQRSHLuv1i64 Reg:D24 Reg:D16 Reg:D0 Imm:14 Reg:Nil | vqrshl.u64 d24, d16, d0
  #|0xff71e13e	VBIFd Reg:D30 Reg:D30 Reg:D1 Reg:D30 Imm:14 Reg:Nil | vbif d30, d1, d30
  #|0xff7958a7	VSUBv1i64 Reg:D21 Reg:D25 Reg:D23 Imm:14 Reg:Nil | vsub.i64 d21, d25, d23
  #|0xff7c00f0	VQADDuv2i64 Reg:Q8 Reg:Q14 Reg:Q8 Imm:14 Reg:Nil | vqadd.u64 q8, q14, q8
  #|0xff7ee1d0	VBIFq Reg:Q15 Reg:Q15 Reg:Q15 Reg:Q0 Imm:14 Reg:Nil | vbif q15, q15, q0
  #|0xff800024	VADDLuv8i16 Reg:Q0 Reg:D0 Reg:D20 Imm:14 Reg:Nil | vaddl.u8 q0, d0, d20
  #|0xff802a55	VMOVv8i16 Reg:Q1 Imm:2693 Imm:14 Reg:Nil | vmov.i16 q1, #0x8500
  #|0xff8042a0	VSUBLuv8i16 Reg:Q2 Reg:D16 Reg:D16 Imm:14 Reg:Nil | vsubl.u8 q2, d16, d16
  #|0xff821600	VRSUBHNv8i8 Reg:D1 Reg:Q1 Reg:Q0 Imm:14 Reg:Nil | vrsubhn.i16 d1, q1, q0
  #|0xff842a02	VMLSLuv8i16 Reg:Q1 Reg:Q1 Reg:D4 Reg:D2 Imm:14 Reg:Nil | vmlsl.u8 q1, d4, d2
  #|0xff84c5aa	VABALuv8i16 Reg:Q6 Reg:Q6 Reg:D20 Reg:D26 Imm:14 Reg:Nil | vabal.u8 q6, d20, d26
  #|0xff86ac27	VMULLuv8i16 Reg:Q5 Reg:D6 Reg:D23 Imm:14 Reg:Nil | vmull.u8 q5, d6, d23
  #|0xff87a708	VABDLuv8i16 Reg:Q5 Reg:D7 Reg:D8 Imm:14 Reg:Nil | vabdl.u8 q5, d7, d8
  #|0xff88281c	VQSHRUNv8i8 Reg:D2 Reg:Q6 Imm:8 Imm:14 Reg:Nil | vqshrun.s16 d2, q6, #8
  #|0xff89c11e	VSRAuv8i8 Reg:D12 Reg:D12 Reg:D14 Imm:7 Imm:14 Reg:Nil | vsra.u8 d12, d14, #7
  #|0xff8a85b0	VSLIv1i64 Reg:D8 Reg:D8 Reg:D16 Imm:10 Imm:14 Reg:Nil | vsli.64 d8, d16, #10
  #|0xff8bb214	VRSHRuv8i8 Reg:D11 Reg:D4 Imm:5 Imm:14 Reg:Nil | vrshr.u8 d11, d4, #5
  #|0xff8c2306	VSUBWuv8i16 Reg:Q1 Reg:Q6 Reg:D6 Imm:14 Reg:Nil | vsubw.u8 q1, q6, d6
  #|0xff8d4450	VSRIv16i8 Reg:Q2 Reg:Q2 Reg:Q0 Imm:3 Imm:14 Reg:Nil | vsri.8 q2, q0, #3
  #|0xff90031e	VRSRAuv4i16 Reg:D0 Reg:D0 Reg:D14 Imm:16 Imm:14 Reg:Nil | vrsra.u16 d0, d14, #16
  #|0xff90d510	VSLIv4i16 Reg:D13 Reg:D13 Reg:D0 Imm:0 Imm:14 Reg:Nil | vsli.16 d13, d0, #0
  #|0xff912710	VQSHLuiv4i16 Reg:D2 Reg:D0 Imm:1 Imm:14 Reg:Nil | vqshl.u16 d2, d0, #1
  #|0xff9466f0	VQSHLsuv2i64 Reg:Q3 Reg:Q8 Imm:20 Imm:14 Reg:Nil | vqshlu.s64 q3, q8, #20
  #|0xff958778	VQSHLuiv8i16 Reg:Q4 Reg:Q12 Imm:5 Imm:14 Reg:Nil | vqshl.u16 q4, q12, #5
  #|0xff9685a0	VABALuv4i32 Reg:Q4 Reg:Q4 Reg:D22 Reg:D16 Imm:14 Reg:Nil | vabal.u16 q4, d22, d16
  #|0xff970031	VSHRuv4i16 Reg:D0 Reg:D17 Imm:9 Imm:14 Reg:Nil | vshr.u16 d0, d17, #9
  #|0xff97e24a	VMLALsluv4i16 Reg:Q7 Reg:Q7 Reg:D7 Reg:D2 Imm:1 Imm:14 Reg:Nil | vmlal.u16 q7, d7, d2[1]
  #|0xff988450	VSRIv8i16 Reg:Q4 Reg:Q4 Reg:Q0 Imm:8 Imm:14 Reg:Nil | vsri.16 q4, q0, #8
  #|0xff98c301	VSUBWuv4i32 Reg:Q6 Reg:Q4 Reg:D1 Imm:14 Reg:Nil | vsubw.u16 q6, q4, d1
  #|0xff9a2630	VQSHLsuv4i16 Reg:D2 Reg:D16 Imm:10 Imm:14 Reg:Nil | vqshlu.s16 d2, d16, #10
  #|0xff9c0060	VMLAslv8i16 Reg:Q0 Reg:Q0 Reg:Q6 Reg:D0 Imm:2 Imm:14 Reg:Nil | vmla.i16 q0, q6, d0[2]
  #|0xff9c0074	VSHRuv8i16 Reg:Q0 Reg:Q10 Imm:4 Imm:14 Reg:Nil | vshr.u16 q0, q10, #4
  #|0xff9d8c80	VMULLuv4i32 Reg:Q4 Reg:D29 Reg:D0 Imm:14 Reg:Nil | vmull.u16 q4, d29, d0
  #|0xff9dd97e	VQRSHRNuv4i16 Reg:D13 Reg:Q15 Imm:3 Imm:14 Reg:Nil | vqrshrn.u32 d13, q15, #3
  #|0xff9e223c	VRSHRuv4i16 Reg:D2 Reg:D28 Imm:2 Imm:14 Reg:Nil | vrshr.u16 d2, d28, #2
  #|0xff9e2870	VQRSHRUNv4i16 Reg:D2 Reg:Q8 Imm:2 Imm:14 Reg:Nil | vqrshrun.s32 d2, q8, #2
  #|0xff9e7131	VSRAuv4i16 Reg:D7 Reg:D7 Reg:D17 Imm:2 Imm:14 Reg:Nil | vsra.u16 d7, d17, #2
  #|0xffa56501	VABALuv2i64 Reg:Q3 Reg:Q3 Reg:D5 Reg:D1 Imm:14 Reg:Nil | vabal.u32 q3, d5, d1
  #|0xffa86d4e	VQRDMULHslv4i32 Reg:Q3 Reg:Q4 Reg:D14 Imm:0 Imm:14 Reg:Nil | vqrdmulh.s32 q3, q4, d14[0]
  #|0xffaca543	VMLSslfq Reg:Q5 Reg:Q5 Reg:Q6 Reg:D3 Imm:0 Imm:14 Reg:Nil | vmls.f32 q5, q6, d3[0]
  #|0xffad0f70	VCVTf2xuq Reg:Q0 Reg:Q8 Imm:19 Imm:14 Reg:Nil | vcvt.u32.f32 q0, q8, #19
  #|0xffad2e30	VCVTxu2fd Reg:D2 Reg:D16 Imm:19 Imm:14 Reg:Nil | vcvt.f32.u32 d2, d16, #19
  #|0xffada936	VQSHRNuv2i32 Reg:D10 Reg:Q11 Imm:19 Imm:14 Reg:Nil | vqshrn.u64 d10, q11, #19
  #|0xffb1c21f	VRSHRuv2i32 Reg:D12 Reg:D15 Imm:15 Imm:14 Reg:Nil | vrshr.u32 d12, d15, #15
  #|0xffb1c415	VSRIv2i32 Reg:D12 Reg:D12 Reg:D5 Imm:15 Imm:14 Reg:Nil | vsri.32 d12, d5, #15
  #|0xffb34b00	VTBL4 Reg:D4 Reg:D3 Reg:D0 Imm:14 Reg:Nil | vtbl.8 d4, {d3, d4, d5, d6}, d0
  #|0xffb3bc24	VDUPLN8d Reg:D11 Reg:D20 Imm:1 Imm:14 Reg:Nil | vdup.8 d11, d20[1]
  #|0xffb4009e	VSHRuv1i64 Reg:D0 Reg:D14 Imm:12 Imm:14 Reg:Nil | vshr.u64 d0, d14, #12
  #|0xffb49800	VTBL1 Reg:D9 Reg:D4 Reg:D0 Imm:14 Reg:Nil | vtbl.8 d9, {d4}, d0
  #|0xffb4c602	VPADALsv4i16 Reg:D12 Reg:D12 Reg:D2 Imm:14 Reg:Nil | vpadal.s16 d12, d2
  #|0xffb500e0	VCGEzv8i16 Reg:Q0 Reg:Q8 Imm:14 Reg:Nil | vcge.s16 q0, q8, #0
  #|0xffb77a05	VTBL3 Reg:D7 Reg:D7 Reg:D5 Imm:14 Reg:Nil | vtbl.8 d7, {d7, d8, d9}, d5
  #|0xffb7b3b8	VRSRAuv1i64 Reg:D11 Reg:D11 Reg:D24 Imm:9 Imm:14 Reg:Nil | vrsra.u64 d11, d24, #9
  #|0xffb8425c	VRSHRuv4i32 Reg:Q2 Reg:Q6 Imm:8 Imm:14 Reg:Nil | vrshr.u32 q2, q6, #8
  #|0xffb88330	VRSRAuv2i32 Reg:D8 Reg:D8 Reg:D16 Imm:8 Imm:14 Reg:Nil | vrsra.u32 d8, d16, #8
  #|0xffb9a3c6	VNEGs32q Reg:Q5 Reg:Q3 Imm:14 Reg:Nil | vneg.s32 q5, q3
  #|0xffb9e701	VABSfd Reg:D14 Reg:D1 Imm:14 Reg:Nil | vabs.f32 d14, d1
  #|0xffba00c0	VTRNq32 Reg:Q0 Reg:Q0 Reg:Q0 Reg:Q0 Imm:14 Reg:Nil | vtrn.32 q0, q0
  #|0xffba2200	VMOVNv2i32 Reg:D2 Reg:Q0 Imm:14 Reg:Nil | vmovn.i64 d2, q0
  #|0xffba82c4	VQMOVNuv2i32 Reg:D8 Reg:Q2 Imm:14 Reg:Nil | vqmovn.u64 d8, q2
  #|0xffbb46e2	VCVTu2fq Reg:Q2 Reg:Q9 Imm:14 Reg:Nil | vcvt.f32.u32 q2, q9
  #|0xffbe513b	VSRAuv2i32 Reg:D5 Reg:D5 Reg:D27 Imm:2 Imm:14 Reg:Nil | vsra.u32 d5, d27, #2
  #|0xffbeec00	VDUPLN16d Reg:D14 Reg:D0 Imm:3 Imm:14 Reg:Nil | vdup.16 d14, d0[3]
  #|0xffbf0033	VSHRuv2i32 Reg:D0 Reg:D19 Imm:1 Imm:14 Reg:Nil | vshr.u32 d0, d19, #1
  #|0xffc08196	VSRAuv1i64 Reg:D24 Reg:D24 Reg:D6 Imm:64 Imm:14 Reg:Nil | vsra.u64 d24, d6, #64
  #|0xffc304d6	VSRIv2i64 Reg:Q8 Reg:Q8 Reg:Q3 Imm:61 Imm:14 Reg:Nil | vsri.64 q8, q3, #61
  #|0xffc8b310	VRSRAuv8i8 Reg:D27 Reg:D27 Reg:D0 Imm:8 Imm:14 Reg:Nil | vrsra.u8 d27, d0, #8
  #|0xffca41d4	VSRAuv2i64 Reg:Q10 Reg:Q10 Reg:Q2 Imm:54 Imm:14 Reg:Nil | vsra.u64 q10, q2, #54
  #|0xffca7400	VRADDHNv8i8 Reg:D23 Reg:Q5 Reg:Q0 Imm:14 Reg:Nil | vraddhn.i16 d23, q5, q0
  #|0xffcb05f0	VSLIv2i64 Reg:Q8 Reg:Q8 Reg:Q8 Imm:11 Imm:14 Reg:Nil | vsli.64 q8, q8, #11
  #|0xffcd8418	VSRIv8i8 Reg:D24 Reg:D24 Reg:D8 Imm:3 Imm:14 Reg:Nil | vsri.8 d24, d8, #3
  #|0xffce280f	VMLALuv8i16 Reg:Q9 Reg:Q9 Reg:D14 Reg:D15 Imm:14 Reg:Nil | vmlal.u8 q9, d14, d15
  #|0xffcf0010	VSHRuv8i8 Reg:D16 Reg:D0 Imm:1 Imm:14 Reg:Nil | vshr.u8 d16, d0, #1
  #|0xffcfe772	VQSHLuiv16i8 Reg:Q15 Reg:Q9 Imm:7 Imm:14 Reg:Nil | vqshl.u8 q15, q9, #7
  #|0xffd2002e	VADDLuv4i32 Reg:Q8 Reg:D2 Reg:D30 Imm:14 Reg:Nil | vaddl.u16 q8, d2, d30
  #|0xffd2b6ae	VRSUBHNv4i16 Reg:D27 Reg:Q9 Reg:Q15 Imm:14 Reg:Nil | vrsubhn.i32 d27, q9, q15
  #|0xffd4c696	VQSHLsuv1i64 Reg:D28 Reg:D6 Imm:20 Imm:14 Reg:Nil | vqshlu.s64 d28, d6, #20
  #|0xffd80785	VABDLuv4i32 Reg:Q8 Reg:D24 Reg:D5 Imm:14 Reg:Nil | vabdl.u16 q8, d24, d5
  #|0xffd84828	VMLALuv4i32 Reg:Q10 Reg:Q10 Reg:D8 Reg:D24 Imm:14 Reg:Nil | vmlal.u16 q10, d8, d24
  #|0xffd84a0c	VMLSLuv4i32 Reg:Q10 Reg:Q10 Reg:D8 Reg:D12 Imm:14 Reg:Nil | vmlsl.u16 q10, d8, d12
  #|0xffd8a2a0	VSUBLuv4i32 Reg:Q13 Reg:D24 Reg:D16 Imm:14 Reg:Nil | vsubl.u16 q13, d24, d16
  #|0xffd96654	VQSHLsuv8i16 Reg:Q11 Reg:Q2 Imm:9 Imm:14 Reg:Nil | vqshlu.s16 q11, q2, #9
  #|0xffd992bf	VRSHRuv1i64 Reg:D25 Reg:D31 Imm:39 Imm:14 Reg:Nil | vrshr.u64 d25, d31, #39
  #|0xffdc9912	VQSHRNuv4i16 Reg:D25 Reg:Q1 Imm:4 Imm:14 Reg:Nil | vqshrn.u32 d25, q1, #4
  #|0xffdca660	VMLSLsluv4i16 Reg:Q13 Reg:Q13 Reg:D12 Reg:D0 Imm:2 Imm:14 Reg:Nil | vmlsl.u16 q13, d12, d0[2]
  #|0xffdcc400	VRADDHNv4i16 Reg:D28 Reg:Q6 Reg:Q0 Imm:14 Reg:Nil | vraddhn.i32 d28, q6, q0
  #|0xffde2181	VADDWuv4i32 Reg:Q9 Reg:Q15 Reg:D1 Imm:14 Reg:Nil | vaddw.u16 q9, q15, d1
  #|0xffdf3437	VSRIv4i16 Reg:D19 Reg:D19 Reg:D23 Imm:1 Imm:14 Reg:Nil | vsri.16 d19, d23, #1
  #|0xffdfb791	VQSHLuiv1i64 Reg:D27 Reg:D1 Imm:31 Imm:14 Reg:Nil | vqshl.u64 d27, d1, #31
  #|0xffe02684	VRSUBHNv2i32 Reg:D18 Reg:Q8 Reg:Q2 Imm:14 Reg:Nil | vrsubhn.i64 d18, q8, q2
  #|0xffe0c37e	VRSRAuv4i32 Reg:Q14 Reg:Q14 Reg:Q15 Imm:32 Imm:14 Reg:Nil | vrsra.u32 q14, q15, #32
  #|0xffe2ea03	VMLSLuv2i64 Reg:Q15 Reg:Q15 Reg:D2 Reg:D3 Imm:14 Reg:Nil | vmlsl.u32 q15, d2, d3
  #|0xffe46c02	VMULLuv2i64 Reg:Q11 Reg:D4 Reg:D2 Imm:14 Reg:Nil | vmull.u32 q11, d4, d2
  #|0xffe50072	VSHRuv4i32 Reg:Q8 Reg:Q9 Imm:27 Imm:14 Reg:Nil | vshr.u32 q8, q9, #27
  #|0xffe502de	VRSHRuv2i64 Reg:Q8 Reg:Q7 Imm:27 Imm:14 Reg:Nil | vrshr.u64 q8, q7, #27
  #|0xffe66208	VSUBLuv2i64 Reg:Q11 Reg:D6 Reg:D8 Imm:14 Reg:Nil | vsubl.u32 q11, d6, d8
  #|0xffe8a320	VSUBWuv2i64 Reg:Q13 Reg:Q4 Reg:D16 Imm:14 Reg:Nil | vsubw.u32 q13, q4, d16
  #|0xffe90000	VADDLuv2i64 Reg:Q8 Reg:D9 Reg:D0 Imm:14 Reg:Nil | vaddl.u32 q8, d9, d0
  #|0xffe9e800	VMLALuv2i64 Reg:Q15 Reg:Q15 Reg:D9 Reg:D0 Imm:14 Reg:Nil | vmlal.u32 q15, d9, d0
  #|0xffec8ce0	VQDMULHslv4i32 Reg:Q12 Reg:Q14 Reg:D0 Imm:1 Imm:14 Reg:Nil | vqdmulh.s32 q12, q14, d0[1]
  #|0xffed3737	VQSHLuiv2i32 Reg:D19 Reg:D23 Imm:13 Imm:14 Reg:Nil | vqshl.u32 d19, d23, #13
  #|0xffee8040	VMLAslv4i32 Reg:Q12 Reg:Q12 Reg:Q7 Reg:D0 Imm:0 Imm:14 Reg:Nil | vmla.i32 q12, q7, d0[0]
  #|0xffeea2e8	VMLALsluv2i32 Reg:Q13 Reg:Q13 Reg:D30 Reg:D8 Imm:1 Imm:14 Reg:Nil | vmlal.u32 q13, d30, d8[1]
  #|0xffefc705	VABDLuv2i64 Reg:Q14 Reg:D15 Reg:D5 Imm:14 Reg:Nil | vabdl.u32 q14, d15, d5
  #|0xffeff490	VSRIv1i64 Reg:D31 Reg:D31 Reg:D0 Imm:17 Imm:14 Reg:Nil | vsri.64 d31, d0, #17
  #|0xfff00040	VREV64q8 Reg:Q8 Reg:Q0 Imm:14 Reg:Nil | vrev64.8 q8, q0
  #|0xfff005a8	VMVNd Reg:D16 Reg:D24 Imm:14 Reg:Nil | vmvn d16, d24
  #|0xfff020c2	VREV32q8 Reg:Q9 Reg:Q1 Imm:14 Reg:Nil | vrev32.8 q9, q1
  #|0xfff059e0	VTBX2 Reg:D21 Reg:D21 Reg:Q8 Reg:D16 Imm:14 Reg:Nil | vtbx.8 d21, {d16, d17}, d16
  #|0xfff09538	VSLIv2i32 Reg:D25 Reg:D25 Reg:D24 Imm:16 Imm:14 Reg:Nil | vsli.32 d25, d24, #16
  #|0xfff0b000	VREV64d8 Reg:D27 Reg:D0 Imm:14 Reg:Nil | vrev64.8 d27, d0
  #|0xfff0e409	VCLSv8i8 Reg:D30 Reg:D9 Imm:14 Reg:Nil | vcls.s8 d30, d9
  #|0xfff1002c	VCGTzv8i8 Reg:D16 Reg:D28 Imm:14 Reg:Nil | vcgt.s8 d16, d28, #0
  #|0xfff1ae5c	VCVTxu2fq Reg:Q13 Reg:Q6 Imm:15 Imm:14 Reg:Nil | vcvt.f32.u32 q13, q6, #15
  #|0xfff20044	VSWPq Reg:Q8 Reg:Q2 Reg:Q8 Reg:Q2 Imm:14 Reg:Nil | vswp q8, q2
  #|0xfff200e6	VTRNq8 Reg:Q8 Reg:Q11 Reg:Q8 Reg:Q11 Imm:14 Reg:Nil | vtrn.8 q8, q11
  #|0xfff27028	VSWPd Reg:D23 Reg:D24 Reg:D23 Reg:D24 Imm:14 Reg:Nil | vswp d23, d24
  #|0xfff27866	VTBX1 Reg:D23 Reg:D23 Reg:D2 Reg:D22 Imm:14 Reg:Nil | vtbx.8 d23, {d2}, d22
  #|0xfff28950	VQRSHRNuv2i32 Reg:D24 Reg:Q0 Imm:14 Imm:14 Reg:Nil | vqrshrn.u64 d24, q0, #14
  #|0xfff4000b	VREV64d16 Reg:D16 Reg:D11 Imm:14 Reg:Nil | vrev64.16 d16, d11
  #|0xfff400c6	VREV32q16 Reg:Q8 Reg:Q3 Imm:14 Reg:Nil | vrev32.16 q8, q3
  #|0xfff47f1b	VCVTf2xud Reg:D23 Reg:D11 Imm:12 Imm:14 Reg:Nil | vcvt.u32.f32 d23, d11, #12
  #|0xfff4a400	VCLSv4i16 Reg:D26 Reg:D0 Imm:14 Reg:Nil | vcls.s16 d26, d0
  #|0xfff4b200	VPADDLsv4i16 Reg:D27 Reg:D0 Imm:14 Reg:Nil | vpaddl.s16 d27, d0
  #|0xfff50029	VCGTzv4i16 Reg:D16 Reg:D25 Imm:14 Reg:Nil | vcgt.s16 d16, d25, #0
  #|0xfff50578	VSLIv4i32 Reg:Q8 Reg:Q8 Reg:Q12 Imm:21 Imm:14 Reg:Nil | vsli.32 q8, q12, #21
  #|0xfff57320	VABSv4i16 Reg:D23 Reg:D16 Imm:14 Reg:Nil | vabs.s16 d23, d16
  #|0xfff5a0d0	VSHRuv2i64 Reg:Q13 Reg:Q0 Imm:11 Imm:14 Reg:Nil | vshr.u64 q13, q0, #11
  #|0xfff5c366	VABSv8i16 Reg:Q14 Reg:Q11 Imm:14 Reg:Nil | vabs.s16 q14, q11
  #|0xfff5f874	VQRSHRUNv2i32 Reg:D31 Reg:Q10 Imm:11 Imm:14 Reg:Nil | vqrshrun.s64 d31, q10, #11
  #|0xfff8470d	VQABSv2i32 Reg:D20 Reg:D13 Imm:14 Reg:Nil | vqabs.s32 d20, d13
  #|0xfff9002f	VCGTzv2i32 Reg:D16 Reg:D31 Imm:14 Reg:Nil | vcgt.s32 d16, d31, #0
  #|0xfff9290e	VTBL2 Reg:D18 Reg:D9_D10 Reg:D14 Imm:14 Reg:Nil | vtbl.8 d18, {d9, d10}, d14
  #|0xfff96c60	VDUPLN8q Reg:Q11 Reg:D16 Imm:4 Imm:14 Reg:Nil | vdup.8 q11, d16[4]
  #|0xfff9c603	VCLTzv2f32 Reg:D28 Reg:D3 Imm:14 Reg:Nil | vclt.f32 d28, d3, #0
  #|0xfffb17a6	VCVTf2ud Reg:D17 Reg:D22 Imm:14 Reg:Nil | vcvt.u32.f32 d17, d22
  #|0xfffb4470	VSRIv4i32 Reg:Q10 Reg:Q10 Reg:Q8 Imm:5 Imm:14 Reg:Nil | vsri.32 q10, q8, #5
  #|0xfffb4705	VCVTf2sd Reg:D20 Reg:D5 Imm:14 Reg:Nil | vcvt.s32.f32 d20, d5
  #|0xfffc1c00	VDUPLN32d Reg:D17 Reg:D0 Imm:1 Imm:14 Reg:Nil | vdup.32 d17, d0[1]
  #|0xffffaa62	VTBX3 Reg:D26 Reg:D26 Reg:D15 Reg:D18 Imm:14 Reg:Nil | vtbx.8 d26, {d15, d16, d17}, d18

///|
test "decode: every table-decoded Thumb-2 sample decodes like llvm-mc" {
  let names : Map[String, Unit] = Map([])
  let mut count = 0
  for line in llvm_ext_samples.split("\n") {
    guard !line.is_empty() else { continue }
    let fields = line.split("\t").collect()
    let value = fields[0][2:].fold(init=0U, (v, c) => {
      let d = if c >= 'a' {
        c.to_int() - 'a'.to_int() + 10
      } else {
        c.to_int() - '0'.to_int()
      }
      (v << 4) | d.reinterpret_as_uint()
    })
    guard @thumb.decode_t32(sample_bytes(4, value), addr=0x1000UL)
      is Decoded(insn) else {
      fail("\{fields[0]}: not decoded, expected \{fields[1]}")
    }
    assert_eq(render_llvm(insn), fields[1].to_owned(), msg=fields[0].to_owned())
    names[insn.name] = ()
    count += 1
  }
  inspect(count, content="1074")
  // the number of distinct LLVM opcodes covered by the samples
  inspect(names.length(), content="856")
}

///|
test "table-decoded Thumb-2 instructions lift without errors" {
  let registry = @mc.Registry::new()
  @thumb.register(registry~)
  @arm.register(registry~)
  let target = @core_theory.Target::lookup("armv7+le").unwrap()
  let ctx = @mc.Context::create(
    target,
    encoding=@core_theory.Language::llvm_t32(),
  )
  let failed = []
  for line in llvm_ext_samples.split("\n") {
    guard !line.is_empty() else { continue }
    let value = line[2:10].fold(init=0U, (v, c) => {
      let d = if c >= 'a' {
        c.to_int() - 'a'.to_int() + 10
      } else {
        c.to_int() - '0'.to_int()
      }
      (v << 4) | d.reinterpret_as_uint()
    })
    guard @thumb.decode_t32(sample_bytes(4, value), addr=0x1000UL)
      is Decoded(insn) else {
      fail("not decoded")
    }
    try registry.lift(ctx, insn) catch {
      Unsupported(..) => ()
      err => failed.push("\{insn.name}: \{err.message()}")
    } noraise {
      _ => ()
    }
  }
  inspect(failed.join("\n"), content="")
}

///|
/// VFP, NEON, coprocessor and table-decoded Thumb-2 instructions in IT
/// blocks get the predicate of the block, as LLVM decodes them.
test "decode: table-decoded instructions in IT blocks like llvm-mc" {
  let code : Bytes = b"\x0b\xbf\x30\xee\x01\x0a\x22\xef\x44\x08\x07\xee\x15\x0f\x93\xfa\x1c\xf3\x1c\xbf\x91\xed\x02\x0b\x4b\xf3\xd7\x15\x2d\xed\x04\x8b\x21\xf9\x0f\x0a\x9e\xfa\x8e\xf4"
  let it = @thumb.ItBlock::new()
  let lines = []
  for off = 0; off < code.length(); {
    guard @thumb.decode_t32(code[off:], addr=off.to_uint64(), it~)
      is Decoded(insn) else {
      fail("offset \{off}: not decoded")
    }
    lines.push(render_llvm(insn))
    continue off + insn.size
  }
  inspect(
    lines.join("\n"),
    content=(
      #|t2IT Imm:0 Imm:11 | itete eq
      #|VADDS Reg:S0 Reg:S0 Reg:S2 Imm:0 Reg:CPSR | vaddeq.f32 s0, s0, s2
      #|VADDv4i32 Reg:Q0 Reg:Q1 Reg:Q2 Imm:1 Reg:CPSR | vaddne.i32 q0, q1, q2
      #|t2MCR Imm:15 Imm:0 Reg:R0 Imm:7 Imm:5 Imm:0 Imm:0 Reg:CPSR | mcreq p15, #0, r0, c7, c5, #0 | may_load,may_store
      #|t2QADD16 Reg:R3 Reg:R3 Reg:R12 Imm:1 Reg:CPSR | qadd16ne r3, r3, r12
      #|t2IT Imm:1 Imm:4 | itt ne
      #|VLDRD Reg:D0 Reg:R1 Imm:2 Imm:1 Reg:CPSR | vldrne d0, [r1, #8] | may_load
      #|t2SBFX Reg:R5 Reg:R11 Imm:7 Imm:23 Imm:1 Reg:CPSR | sbfxne r5, r11, #7, #24
      #|VSTMDDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:D8 Reg:D9 | vpush {d8, d9} | may_store
      #|VLD1q8 Reg:Q0 Reg:R1 Imm:0 Imm:14 Reg:Nil | vld1.8 {d0, d1}, [r1] | may_load
      #|t2REV Reg:R4 Reg:LR Imm:14 Reg:Nil | rev.w r4, lr
    ),
  )
}
