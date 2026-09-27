// Per-opcode decoding tests of the native A32 decoder. Every expected
// line (the LLVM opcode name, the operands, the assembly and the kinds) is
// the output of LLVM 22's disassembler for the word (`llvm-mc
// -disassemble -show-inst -triple=armv7-linux-gnueabi`, the kinds from the
// opcode's `MCInstrDesc`, as upstream BAP reads them). `Reg:Nil` is LLVM's
// `NoRegister`. The samples were selected from compiler output and from
// random words of every encoding class on which the decoder and LLVM agree.

///|
let llvm_samples : Array[(UInt, String)] = [
  (
    0xe2a6160fU, "ADCri Reg:R1 Reg:R6 Imm:1551 Imm:14 Reg:Nil Reg:Nil | adc r1, r6, #15728640",
  ),
  (
    0xe2aff102U, "ADCri Reg:PC Reg:PC Imm:258 Imm:14 Reg:Nil Reg:Nil | adc pc, pc, #-2147483648 | affect_cf",
  ),
  (
    0xe2b1e202U, "ADCri Reg:LR Reg:R1 Imm:514 Imm:14 Reg:Nil Reg:CPSR | adcs lr, r1, #536870912",
  ),
  (
    0x12bcf408U, "ADCri Reg:PC Reg:R12 Imm:1032 Imm:1 Reg:CPSR Reg:CPSR | adcsne pc, r12, #8, #8 | affect_cf",
  ),
  (
    0xe0a31001U, "ADCrr Reg:R1 Reg:R3 Reg:R1 Imm:14 Reg:Nil Reg:Nil | adc r1, r3, r1",
  ),
  (
    0x10a4f007U, "ADCrr Reg:PC Reg:R4 Reg:R7 Imm:1 Reg:CPSR Reg:Nil | adcne pc, r4, r7 | affect_cf",
  ),
  (
    0x50b47004U, "ADCrr Reg:R7 Reg:R4 Reg:R4 Imm:5 Reg:CPSR Reg:CPSR | adcspl r7, r4, r4",
  ),
  (
    0x10b2f00eU, "ADCrr Reg:PC Reg:R2 Reg:LR Imm:1 Reg:CPSR Reg:CPSR | adcsne pc, r2, lr | affect_cf",
  ),
  (
    0xe0a013c1U, "ADCrsi Reg:R1 Reg:R0 Reg:R1 Imm:57 Imm:14 Reg:Nil Reg:Nil | adc r1, r0, r1, asr #7",
  ),
  (
    0x20afff07U, "ADCrsi Reg:PC Reg:PC Reg:R7 Imm:242 Imm:2 Reg:CPSR Reg:Nil | adchs pc, pc, r7, lsl #30 | affect_cf",
  ),
  (
    0xe0bb7e0fU, "ADCrsi Reg:R7 Reg:R11 Reg:PC Imm:226 Imm:14 Reg:Nil Reg:CPSR | adcs r7, r11, pc, lsl #28",
  ),
  (
    0xe0b0f30eU, "ADCrsi Reg:PC Reg:R0 Reg:LR Imm:50 Imm:14 Reg:Nil Reg:CPSR | adcs pc, r0, lr, lsl #6 | affect_cf",
  ),
  (
    0xe0a84519U, "ADCrsr Reg:R4 Reg:R8 Reg:R9 Reg:R5 Imm:2 Imm:14 Reg:Nil Reg:Nil | adc r4, r8, r9, lsl r5",
  ),
  (
    0x40a9fe1bU, "ADCrsr Reg:PC Reg:R9 Reg:R11 Reg:LR Imm:2 Imm:4 Reg:CPSR Reg:Nil | adcmi pc, r9, r11, lsl lr | affect_cf",
  ),
  (
    0xe0b2e91cU, "ADCrsr Reg:LR Reg:R2 Reg:R12 Reg:R9 Imm:2 Imm:14 Reg:Nil Reg:CPSR | adcs lr, r2, r12, lsl r9",
  ),
  (
    0x90b7f919U, "ADCrsr Reg:PC Reg:R7 Reg:R9 Reg:R9 Imm:2 Imm:9 Reg:CPSR Reg:CPSR | adcsls pc, r7, r9, lsl r9 | affect_cf",
  ),
  (
    0x02800001U, "ADDri Reg:R0 Reg:R0 Imm:1 Imm:0 Reg:CPSR Reg:Nil | addeq r0, r0, #1",
  ),
  (
    0x228bf20eU, "ADDri Reg:PC Reg:R11 Imm:526 Imm:2 Reg:CPSR Reg:Nil | addhs pc, r11, #-536870912 | affect_cf",
  ),
  (
    0xe2995f03U, "ADDri Reg:R5 Reg:R9 Imm:3843 Imm:14 Reg:Nil Reg:CPSR | adds r5, r9, #3, #30",
  ),
  (
    0x1291f40aU, "ADDri Reg:PC Reg:R1 Imm:1034 Imm:1 Reg:CPSR Reg:CPSR | addsne pc, r1, #167772160 | affect_cf",
  ),
  (
    0xe0810000U, "ADDrr Reg:R0 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | add r0, r1, r0",
  ),
  (
    0xe080f001U, "ADDrr Reg:PC Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | add pc, r0, r1 | affect_cf",
  ),
  (
    0xe0920000U, "ADDrr Reg:R0 Reg:R2 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | adds r0, r2, r0",
  ),
  (
    0x309df002U, "ADDrr Reg:PC Reg:SP Reg:R2 Imm:3 Reg:CPSR Reg:CPSR | addslo pc, sp, r2 | affect_cf",
  ),
  (
    0xe0832100U, "ADDrsi Reg:R2 Reg:R3 Reg:R0 Imm:18 Imm:14 Reg:Nil Reg:Nil | add r2, r3, r0, lsl #2",
  ),
  (
    0x1084f800U, "ADDrsi Reg:PC Reg:R4 Reg:R0 Imm:130 Imm:1 Reg:CPSR Reg:Nil | addne pc, r4, r0, lsl #16 | affect_cf",
  ),
  (
    0xe09bd90aU, "ADDrsi Reg:SP Reg:R11 Reg:R10 Imm:146 Imm:14 Reg:Nil Reg:CPSR | adds sp, r11, r10, lsl #18",
  ),
  (
    0xb095f20dU, "ADDrsi Reg:PC Reg:R5 Reg:SP Imm:34 Imm:11 Reg:CPSR Reg:CPSR | addslt pc, r5, sp, lsl #4 | affect_cf",
  ),
  (
    0xe081dd14U, "ADDrsr Reg:SP Reg:R1 Reg:R4 Reg:SP Imm:2 Imm:14 Reg:Nil Reg:Nil | add sp, r1, r4, lsl sp",
  ),
  (
    0xe08ff310U, "ADDrsr Reg:PC Reg:PC Reg:R0 Reg:R3 Imm:2 Imm:14 Reg:Nil Reg:Nil | add pc, pc, r0, lsl r3 | affect_cf",
  ),
  (
    0xe09d9719U, "ADDrsr Reg:R9 Reg:SP Reg:R9 Reg:R7 Imm:2 Imm:14 Reg:Nil Reg:CPSR | adds r9, sp, r9, lsl r7",
  ),
  (
    0x809cf51aU, "ADDrsr Reg:PC Reg:R12 Reg:R10 Reg:R5 Imm:2 Imm:8 Reg:CPSR Reg:CPSR | addshi pc, r12, r10, lsl r5 | affect_cf",
  ),
  (
    0xe2000001U, "ANDri Reg:R0 Reg:R0 Imm:1 Imm:14 Reg:Nil Reg:Nil | and r0, r0, #1",
  ),
  (
    0xe20ff201U, "ANDri Reg:PC Reg:PC Imm:513 Imm:14 Reg:Nil Reg:Nil | and pc, pc, #268435456 | affect_cf",
  ),
  (
    0xe21a6d0dU, "ANDri Reg:R6 Reg:R10 Imm:3341 Imm:14 Reg:Nil Reg:CPSR | ands r6, r10, #832",
  ),
  (
    0x8211fc0fU, "ANDri Reg:PC Reg:R1 Imm:3087 Imm:8 Reg:CPSR Reg:CPSR | andshi pc, r1, #3840 | affect_cf",
  ),
  (
    0x00000000U, "ANDrr Reg:R0 Reg:R0 Reg:R0 Imm:0 Reg:CPSR Reg:Nil | andeq r0, r0, r0",
  ),
  (
    0x900ff009U, "ANDrr Reg:PC Reg:PC Reg:R9 Imm:9 Reg:CPSR Reg:Nil | andls pc, pc, r9 | affect_cf",
  ),
  (
    0xe0138003U, "ANDrr Reg:R8 Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:CPSR | ands r8, r3, r3",
  ),
  (
    0xd01ff006U, "ANDrr Reg:PC Reg:PC Reg:R6 Imm:13 Reg:CPSR Reg:CPSR | andsle pc, pc, r6 | affect_cf",
  ),
  (
    0x00001505U, "ANDrsi Reg:R1 Reg:R0 Reg:R5 Imm:82 Imm:0 Reg:CPSR Reg:Nil | andeq r1, r0, r5, lsl #10",
  ),
  (
    0x700df805U, "ANDrsi Reg:PC Reg:SP Reg:R5 Imm:130 Imm:7 Reg:CPSR Reg:Nil | andvc pc, sp, r5, lsl #16 | affect_cf",
  ),
  (
    0xe0151108U, "ANDrsi Reg:R1 Reg:R5 Reg:R8 Imm:18 Imm:14 Reg:Nil Reg:CPSR | ands r1, r5, r8, lsl #2",
  ),
  (
    0x1011fc05U, "ANDrsi Reg:PC Reg:R1 Reg:R5 Imm:194 Imm:1 Reg:CPSR Reg:CPSR | andsne pc, r1, r5, lsl #24 | affect_cf",
  ),
  (
    0x00000010U, "ANDrsr Reg:R0 Reg:R0 Reg:R0 Reg:R0 Imm:2 Imm:0 Reg:CPSR Reg:Nil | andeq r0, r0, r0, lsl r0",
  ),
  (
    0xe004fd1fU, "ANDrsr Reg:PC Reg:R4 Reg:PC Reg:SP Imm:2 Imm:14 Reg:Nil Reg:Nil | and pc, r4, pc, lsl sp | affect_cf",
  ),
  (
    0xe01d6a18U, "ANDrsr Reg:R6 Reg:SP Reg:R8 Reg:R10 Imm:2 Imm:14 Reg:Nil Reg:CPSR | ands r6, sp, r8, lsl r10",
  ),
  (
    0x901ffc13U, "ANDrsr Reg:PC Reg:PC Reg:R3 Reg:R12 Imm:2 Imm:9 Reg:CPSR Reg:CPSR | andsls pc, pc, r3, lsl r12 | affect_cf",
  ),
  (
    0xe7cc7d1fU, "BFC Reg:R7 Reg:R7 Imm:4294963199 Imm:14 Reg:Nil | bfc r7, #12, #1",
  ),
  (
    0xe7c92191U, "BFI Reg:R2 Reg:R2 Reg:R1 Imm:4294966279 Imm:14 Reg:Nil | bfi r2, r1, #3, #7",
  ),
  (
    0xa7c4fe13U, "BFI Reg:PC Reg:PC Reg:R3 Imm:4294967279 Imm:10 Reg:CPSR | bfige pc, r3, #4, #1 | affect_cf",
  ),
  (
    0xe3ce1003U, "BICri Reg:R1 Reg:LR Imm:3 Imm:14 Reg:Nil Reg:Nil | bic r1, lr, #3",
  ),
  (
    0x53c8f000U, "BICri Reg:PC Reg:R8 Imm:0 Imm:5 Reg:CPSR Reg:Nil | bicpl pc, r8, #0 | affect_cf",
  ),
  (
    0xe3d31802U, "BICri Reg:R1 Reg:R3 Imm:2050 Imm:14 Reg:Nil Reg:CPSR | bics r1, r3, #131072",
  ),
  (
    0x43daf30fU, "BICri Reg:PC Reg:R10 Imm:783 Imm:4 Reg:CPSR Reg:CPSR | bicsmi pc, r10, #1006632960 | affect_cf",
  ),
  (
    0xe1c10000U, "BICrr Reg:R0 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | bic r0, r1, r0",
  ),
  (
    0x81cdf005U, "BICrr Reg:PC Reg:SP Reg:R5 Imm:8 Reg:CPSR Reg:Nil | bichi pc, sp, r5 | affect_cf",
  ),
  (
    0xe1dab001U, "BICrr Reg:R11 Reg:R10 Reg:R1 Imm:14 Reg:Nil Reg:CPSR | bics r11, r10, r1",
  ),
  (
    0xd1d7f003U, "BICrr Reg:PC Reg:R7 Reg:R3 Imm:13 Reg:CPSR Reg:CPSR | bicsle pc, r7, r3 | affect_cf",
  ),
  (
    0xe1c02fc0U, "BICrsi Reg:R2 Reg:R0 Reg:R0 Imm:249 Imm:14 Reg:Nil Reg:Nil | bic r2, r0, r0, asr #31",
  ),
  (
    0x71c6f305U, "BICrsi Reg:PC Reg:R6 Reg:R5 Imm:50 Imm:7 Reg:CPSR Reg:Nil | bicvc pc, r6, r5, lsl #6 | affect_cf",
  ),
  (
    0xe1db5f0dU, "BICrsi Reg:R5 Reg:R11 Reg:SP Imm:242 Imm:14 Reg:Nil Reg:CPSR | bics r5, r11, sp, lsl #30",
  ),
  (
    0x71d8fa04U, "BICrsi Reg:PC Reg:R8 Reg:R4 Imm:162 Imm:7 Reg:CPSR Reg:CPSR | bicsvc pc, r8, r4, lsl #20 | affect_cf",
  ),
  (
    0xe1cd051fU, "BICrsr Reg:R0 Reg:SP Reg:PC Reg:R5 Imm:2 Imm:14 Reg:Nil Reg:Nil | bic r0, sp, pc, lsl r5",
  ),
  (
    0xb1c0f211U, "BICrsr Reg:PC Reg:R0 Reg:R1 Reg:R2 Imm:2 Imm:11 Reg:CPSR Reg:Nil | biclt pc, r0, r1, lsl r2 | affect_cf",
  ),
  (
    0xe1d0961dU, "BICrsr Reg:R9 Reg:R0 Reg:SP Reg:R6 Imm:2 Imm:14 Reg:Nil Reg:CPSR | bics r9, r0, sp, lsl r6",
  ),
  (
    0x41dcff19U, "BICrsr Reg:PC Reg:R12 Reg:R9 Reg:PC Imm:2 Imm:4 Reg:CPSR Reg:CPSR | bicsmi pc, r12, r9, lsl pc | affect_cf",
  ),
  (0xebfffffeU, "BL Imm:-8 | bl #-8 | call,affect_cf"),
  (0xe12fff31U, "BLX Reg:R1 | blx r1 | call,affect_cf"),
  (0xfa0e7000U, "BLXi Imm:3784704 | blx #3784704 | call,affect_cf"),
  (
    0x3b6e20c8U, "BL_pred Imm:28869408 Imm:3 Reg:CPSR | bllo #28869408 | call,affect_cf",
  ),
  (0xe12fff11U, "BX Reg:R1 | bx r1 | indirect,barrier,terminator,affect_cf"),
  (
    0x012fff1eU, "BX_RET Imm:0 Reg:CPSR | bxeq lr | return,barrier,terminator,affect_cf",
  ),
  (0xea000000U, "Bcc Imm:0 Imm:14 Reg:Nil | b #0 | cond,terminator,affect_cf"),
  (0xe16f0f10U, "CLZ Reg:R0 Reg:R0 Imm:14 Reg:Nil | clz r0, r0"),
  (0xe3720009U, "CMNri Reg:R2 Imm:9 Imm:14 Reg:Nil | cmn r2, #9"),
  (0xe171f00cU, "CMNzrr Reg:R1 Reg:R12 Imm:14 Reg:Nil | cmn r1, r12"),
  (
    0xe17f5909U, "CMNzrsi Reg:PC Reg:R9 Imm:146 Imm:14 Reg:Nil | cmn pc, r9, lsl #18",
  ),
  (
    0xe1776b13U, "CMNzrsr Reg:R7 Reg:R3 Reg:R11 Imm:2 Imm:14 Reg:Nil | cmn r7, r3, lsl r11",
  ),
  (0xe3500000U, "CMPri Reg:R0 Imm:0 Imm:14 Reg:Nil | cmp r0, #0"),
  (0xe1530000U, "CMPrr Reg:R3 Reg:R0 Imm:14 Reg:Nil | cmp r3, r0"),
  (
    0xe1562d05U, "CMPrsi Reg:R6 Reg:R5 Imm:210 Imm:14 Reg:Nil | cmp r6, r5, lsl #26",
  ),
  (
    0xe15ac615U, "CMPrsr Reg:R10 Reg:R5 Reg:R6 Imm:2 Imm:14 Reg:Nil | cmp r10, r5, lsl r6",
  ),
  (0xf1020152U, "CPS1p Imm:18 | cps #18"),
  (0xf10e0058U, "CPS3p Imm:3 Imm:1 Imm:24 | cpsid f, #24"),
  (0xf57ff05bU, "DMB Imm:11 | dmb ish | may_load,may_store"),
  (0xf57ff041U, "DSB Imm:1 | dsb #0x1 | may_load,may_store"),
  (0xf57ff044U, "DSB Imm:4 | pssbb | may_load,may_store"),
  (0xf57ff040U, "DSB Imm:0 | ssbb | may_load,may_store"),
  (
    0xe224370dU, "EORri Reg:R3 Reg:R4 Imm:1805 Imm:14 Reg:Nil Reg:Nil | eor r3, r4, #3407872",
  ),
  (
    0xa222f803U, "EORri Reg:PC Reg:R2 Imm:2051 Imm:10 Reg:CPSR Reg:Nil | eorge pc, r2, #196608 | affect_cf",
  ),
  (
    0x12345678U, "EORri Reg:R5 Reg:R4 Imm:1656 Imm:1 Reg:CPSR Reg:CPSR | eorsne r5, r4, #120, #12",
  ),
  (
    0x423bf205U, "EORri Reg:PC Reg:R11 Imm:517 Imm:4 Reg:CPSR Reg:CPSR | eorsmi pc, r11, #1342177280 | affect_cf",
  ),
  (
    0xe0270000U, "EORrr Reg:R0 Reg:R7 Reg:R0 Imm:14 Reg:Nil Reg:Nil | eor r0, r7, r0",
  ),
  (
    0xd022f006U, "EORrr Reg:PC Reg:R2 Reg:R6 Imm:13 Reg:CPSR Reg:Nil | eorle pc, r2, r6 | affect_cf",
  ),
  (
    0xa03fe003U, "EORrr Reg:LR Reg:PC Reg:R3 Imm:10 Reg:CPSR Reg:CPSR | eorsge lr, pc, r3",
  ),
  (
    0x7038f00dU, "EORrr Reg:PC Reg:R8 Reg:SP Imm:7 Reg:CPSR Reg:CPSR | eorsvc pc, r8, sp | affect_cf",
  ),
  (
    0xe02c6324U, "EORrsi Reg:R6 Reg:R12 Reg:R4 Imm:51 Imm:14 Reg:Nil Reg:Nil | eor r6, r12, r4, lsr #6",
  ),
  (
    0x8025f608U, "EORrsi Reg:PC Reg:R5 Reg:R8 Imm:98 Imm:8 Reg:CPSR Reg:Nil | eorhi pc, r5, r8, lsl #12 | affect_cf",
  ),
  (
    0xe031b902U, "EORrsi Reg:R11 Reg:R1 Reg:R2 Imm:146 Imm:14 Reg:Nil Reg:CPSR | eors r11, r1, r2, lsl #18",
  ),
  (
    0x303bf50aU, "EORrsi Reg:PC Reg:R11 Reg:R10 Imm:82 Imm:3 Reg:CPSR Reg:CPSR | eorslo pc, r11, r10, lsl #10 | affect_cf",
  ),
  (
    0xe020d41aU, "EORrsr Reg:SP Reg:R0 Reg:R10 Reg:R4 Imm:2 Imm:14 Reg:Nil Reg:Nil | eor sp, r0, r10, lsl r4",
  ),
  (
    0x9020fd12U, "EORrsr Reg:PC Reg:R0 Reg:R2 Reg:SP Imm:2 Imm:9 Reg:CPSR Reg:Nil | eorls pc, r0, r2, lsl sp | affect_cf",
  ),
  (
    0xe03eca1fU, "EORrsr Reg:R12 Reg:LR Reg:PC Reg:R10 Imm:2 Imm:14 Reg:Nil Reg:CPSR | eors r12, lr, pc, lsl r10",
  ),
  (
    0x9031fa1cU, "EORrsr Reg:PC Reg:R1 Reg:R12 Reg:R10 Imm:2 Imm:9 Reg:CPSR Reg:CPSR | eorsls pc, r1, r12, lsl r10 | affect_cf",
  ),
  (0xe320f000U, "HINT Imm:0 Imm:14 Reg:Nil | nop | may_load,may_store"),
  (0xf57ff060U, "ISB Imm:0 | isb #0x0 | may_load,may_store"),
  (
    0xe8199000U, "LDMDA Reg:R9 Imm:14 Reg:Nil Reg:R12 Reg:PC | ldmda r9, {r12, pc} | affect_cf,may_load",
  ),
  (
    0x981d8060U, "LDMDA Reg:SP Imm:9 Reg:CPSR Reg:R5 Reg:R6 Reg:PC | ldmdals sp, {r5, r6, pc} | affect_cf,may_load",
  ),
  (
    0x8816d001U, "LDMDA Reg:R6 Imm:8 Reg:CPSR Reg:R0 Reg:R12 Reg:LR Reg:PC | ldmdahi r6, {r0, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe81ad00cU, "LDMDA Reg:R10 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R12 Reg:LR Reg:PC | ldmda r10, {r2, r3, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe817f003U, "LDMDA Reg:R7 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmda r7, {r0, r1, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe814aa0eU, "LDMDA Reg:R4 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R9 Reg:R11 Reg:SP Reg:PC | ldmda r4, {r1, r2, r3, r9, r11, sp, pc} | affect_cf,may_load",
  ),
  (
    0x4810fe08U, "LDMDA Reg:R0 Imm:4 Reg:CPSR Reg:R3 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdami r0, {r3, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x4815f417U, "LDMDA Reg:R5 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdami r5, {r0, r1, r2, r4, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe81ff30fU, "LDMDA Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R8 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmda pc, {r0, r1, r2, r3, r8, r9, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x8813f65dU, "LDMDA Reg:R3 Imm:8 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdahi r3, {r0, r2, r3, r4, r6, r9, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x7811ff74U, "LDMDA Reg:R1 Imm:7 Reg:CPSR Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdavc r1, {r2, r4, r5, r6, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xc813fdcfU, "LDMDA Reg:R3 Imm:12 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdagt r3, {r0, r1, r2, r3, r6, r7, r8, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xd81dff3fU, "LDMDA Reg:SP Imm:13 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdale sp, {r0, r1, r2, r3, r4, r5, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x381d4000U, "LDMDA Reg:SP Imm:3 Reg:CPSR Reg:LR | ldmdalo sp, {lr} | may_load",
  ),
  (
    0xe8135000U, "LDMDA Reg:R3 Imm:14 Reg:Nil Reg:R12 Reg:LR | ldmda r3, {r12, lr} | may_load",
  ),
  (
    0xe81c001aU, "LDMDA Reg:R12 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 | ldmda r12, {r1, r3, r4} | may_load",
  ),
  (
    0x98123900U, "LDMDA Reg:R2 Imm:9 Reg:CPSR Reg:R8 Reg:R11 Reg:R12 Reg:SP | ldmdals r2, {r8, r11, r12, sp} | may_load",
  ),
  (
    0xc811401bU, "LDMDA Reg:R1 Imm:12 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:LR | ldmdagt r1, {r0, r1, r3, r4, lr} | may_load",
  ),
  (
    0xd81d2b0aU, "LDMDA Reg:SP Imm:13 Reg:CPSR Reg:R1 Reg:R3 Reg:R8 Reg:R9 Reg:R11 Reg:SP | ldmdale sp, {r1, r3, r8, r9, r11, sp} | may_load",
  ),
  (
    0xe81f161eU, "LDMDA Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R9 Reg:R10 Reg:R12 | ldmda pc, {r1, r2, r3, r4, r9, r10, r12} | may_load",
  ),
  (
    0xe81e1d65U, "LDMDA Reg:LR Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R5 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 | ldmda lr, {r0, r2, r5, r6, r8, r10, r11, r12} | may_load",
  ),
  (
    0x58104f3cU, "LDMDA Reg:R0 Imm:5 Reg:CPSR Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | ldmdapl r0, {r2, r3, r4, r5, r8, r9, r10, r11, lr} | may_load",
  ),
  (
    0xe8147f52U, "LDMDA Reg:R4 Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmda r4, {r1, r4, r6, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0x381d6bedU, "LDMDA Reg:SP Imm:3 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:SP Reg:LR | ldmdalo sp, {r0, r2, r3, r5, r6, r7, r8, r9, r11, sp, lr} | may_load",
  ),
  (
    0x681d7d3fU, "LDMDA Reg:SP Imm:6 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmdavs sp, {r0, r1, r2, r3, r4, r5, r8, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0xd83da000U, "LDMDA_UPD Reg:SP Reg:SP Imm:13 Reg:CPSR Reg:SP Reg:PC | ldmdale sp!, {sp, pc} | affect_cf,may_load",
  ),
  (
    0xe83ba010U, "LDMDA_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:R4 Reg:SP Reg:PC | ldmda r11!, {r4, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe83fa202U, "LDMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R9 Reg:SP Reg:PC | ldmda pc!, {r1, r9, sp, pc} | affect_cf,may_load",
  ),
  (
    0xd83df002U, "LDMDA_UPD Reg:SP Reg:SP Imm:13 Reg:CPSR Reg:R1 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdale sp!, {r1, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe83d803bU, "LDMDA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:PC | ldmda sp!, {r0, r1, r3, r4, r5, pc} | affect_cf,may_load",
  ),
  (
    0x1838f016U, "LDMDA_UPD Reg:R8 Reg:R8 Imm:1 Reg:CPSR Reg:R1 Reg:R2 Reg:R4 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdane r8!, {r1, r2, r4, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x383ef90aU, "LDMDA_UPD Reg:LR Reg:LR Imm:3 Reg:CPSR Reg:R1 Reg:R3 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdalo lr!, {r1, r3, r8, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe832c93eU, "LDMDA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R11 Reg:LR Reg:PC | ldmda r2!, {r1, r2, r3, r4, r5, r8, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe835af1eU, "LDMDA_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:PC | ldmda r5!, {r1, r2, r3, r4, r8, r9, r10, r11, sp, pc} | affect_cf,may_load",
  ),
  (
    0xd83efe9cU, "LDMDA_UPD Reg:LR Reg:LR Imm:13 Reg:CPSR Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdale lr!, {r2, r3, r4, r7, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe83fed7bU, "LDMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:SP Reg:LR Reg:PC | ldmda pc!, {r0, r1, r3, r4, r5, r6, r8, r10, r11, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x383cfd77U, "LDMDA_UPD Reg:R12 Reg:R12 Imm:3 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdalo r12!, {r0, r1, r2, r4, r5, r6, r8, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8304000U, "LDMDA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:LR | ldmda r0!, {lr} | may_load",
  ),
  (
    0xe83d00a0U, "LDMDA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R5 Reg:R7 | ldmda sp!, {r5, r7} | may_load",
  ),
  (
    0x88316008U, "LDMDA_UPD Reg:R1 Reg:R1 Imm:8 Reg:CPSR Reg:R3 Reg:SP Reg:LR | ldmdahi r1!, {r3, sp, lr} | may_load",
  ),
  (
    0xe83e1105U, "LDMDA_UPD Reg:LR Reg:LR Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R8 Reg:R12 | ldmda lr!, {r0, r2, r8, r12} | may_load",
  ),
  (
    0xe83e6228U, "LDMDA_UPD Reg:LR Reg:LR Imm:14 Reg:Nil Reg:R3 Reg:R5 Reg:R9 Reg:SP Reg:LR | ldmda lr!, {r3, r5, r9, sp, lr} | may_load",
  ),
  (
    0x483d6509U, "LDMDA_UPD Reg:SP Reg:SP Imm:4 Reg:CPSR Reg:R0 Reg:R3 Reg:R8 Reg:R10 Reg:SP Reg:LR | ldmdami sp!, {r0, r3, r8, r10, sp, lr} | may_load",
  ),
  (
    0x383d704eU, "LDMDA_UPD Reg:SP Reg:SP Imm:3 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R12 Reg:SP Reg:LR | ldmdalo sp!, {r1, r2, r3, r6, r12, sp, lr} | may_load",
  ),
  (
    0x783d2973U, "LDMDA_UPD Reg:SP Reg:SP Imm:7 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R11 Reg:SP | ldmdavc sp!, {r0, r1, r4, r5, r6, r8, r11, sp} | may_load",
  ),
  (
    0xd8337553U, "LDMDA_UPD Reg:R3 Reg:R3 Imm:13 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R6 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmdale r3!, {r0, r1, r4, r6, r8, r10, r12, sp, lr} | may_load",
  ),
  (
    0x483d1fd3U, "LDMDA_UPD Reg:SP Reg:SP Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | ldmdami sp!, {r0, r1, r4, r6, r7, r8, r9, r10, r11, r12} | may_load",
  ),
  (
    0xe83675feU, "LDMDA_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmda r6!, {r1, r2, r3, r4, r5, r6, r7, r8, r10, r12, sp, lr} | may_load",
  ),
  (
    0x191d8080U, "LDMDB Reg:SP Imm:1 Reg:CPSR Reg:R7 Reg:PC | ldmdbne sp, {r7, pc} | affect_cf,may_load",
  ),
  (
    0xe91de000U, "LDMDB Reg:SP Imm:14 Reg:Nil Reg:SP Reg:LR Reg:PC | ldmdb sp, {sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xb91db020U, "LDMDB Reg:SP Imm:11 Reg:CPSR Reg:R5 Reg:R12 Reg:SP Reg:PC | ldmdblt sp, {r5, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe912e006U, "LDMDB Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:SP Reg:LR Reg:PC | ldmdb r2, {r1, r2, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x491bf005U, "LDMDB Reg:R11 Imm:4 Reg:CPSR Reg:R0 Reg:R2 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbmi r11, {r0, r2, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xb91cf00eU, "LDMDB Reg:R12 Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdblt r12, {r1, r2, r3, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x191ff511U, "LDMDB Reg:PC Imm:1 Reg:CPSR Reg:R0 Reg:R4 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbne pc, {r0, r4, r8, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x6916fc31U, "LDMDB Reg:R6 Imm:6 Reg:CPSR Reg:R0 Reg:R4 Reg:R5 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbvs r6, {r0, r4, r5, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x191edd4eU, "LDMDB Reg:LR Imm:1 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldmdbne lr, {r1, r2, r3, r6, r8, r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe915cb7bU, "LDMDB Reg:R5 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:LR Reg:PC | ldmdb r5, {r0, r1, r3, r4, r5, r6, r8, r9, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe919fb6dU, "LDMDB Reg:R9 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r9, {r0, r2, r3, r5, r6, r8, r9, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xa91dbddfU, "LDMDB Reg:SP Imm:10 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:PC | ldmdbge sp, {r0, r1, r2, r3, r4, r6, r7, r8, r10, r11, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe91d1000U, "LDMDB Reg:SP Imm:14 Reg:Nil Reg:R12 | ldmdb sp, {r12} | may_load",
  ),
  (
    0xe91d2010U, "LDMDB Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:SP | ldmdb sp, {r4, sp} | may_load",
  ),
  (
    0x09132011U, "LDMDB Reg:R3 Imm:0 Reg:CPSR Reg:R0 Reg:R4 Reg:SP | ldmdbeq r3, {r0, r4, sp} | may_load",
  ),
  (
    0xe9142206U, "LDMDB Reg:R4 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R9 Reg:SP | ldmdb r4, {r1, r2, r9, sp} | may_load",
  ),
  (
    0xe91f3222U, "LDMDB Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R5 Reg:R9 Reg:R12 Reg:SP | ldmdb pc, {r1, r5, r9, r12, sp} | may_load",
  ),
  (
    0x591d2307U, "LDMDB Reg:SP Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R8 Reg:R9 Reg:SP | ldmdbpl sp, {r0, r1, r2, r8, r9, sp} | may_load",
  ),
  (
    0x691e3718U, "LDMDB Reg:LR Imm:6 Reg:CPSR Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP | ldmdbvs lr, {r3, r4, r8, r9, r10, r12, sp} | may_load",
  ),
  (
    0xe9123b31U, "LDMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP | ldmdb r2, {r0, r4, r5, r8, r9, r11, r12, sp} | may_load",
  ),
  (
    0xe91f6c5dU, "LDMDB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldmdb pc, {r0, r2, r3, r4, r6, r10, r11, sp, lr} | may_load",
  ),
  (
    0xe91f37bbU, "LDMDB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP | ldmdb pc, {r0, r1, r3, r4, r5, r7, r8, r9, r10, r12, sp} | may_load",
  ),
  (
    0xe91c7fb7U, "LDMDB Reg:R12 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmdb r12, {r0, r1, r2, r4, r5, r7, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0x793da040U, "LDMDB_UPD Reg:SP Reg:SP Imm:7 Reg:CPSR Reg:R6 Reg:SP Reg:PC | ldmdbvc sp!, {r6, sp, pc} | affect_cf,may_load",
  ),
  (
    0x0937a011U, "LDMDB_UPD Reg:R7 Reg:R7 Imm:0 Reg:CPSR Reg:R0 Reg:R4 Reg:SP Reg:PC | ldmdbeq r7!, {r0, r4, sp, pc} | affect_cf,may_load",
  ),
  (
    0x39399301U, "LDMDB_UPD Reg:R9 Reg:R9 Imm:3 Reg:CPSR Reg:R0 Reg:R8 Reg:R9 Reg:R12 Reg:PC | ldmdblo r9!, {r0, r8, r9, r12, pc} | affect_cf,may_load",
  ),
  (
    0xe93f1e0aU, "LDMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | ldmdb pc!, {r1, r3, r9, r10, r11, r12} | affect_cf,may_load",
  ),
  (
    0xc93dc613U, "LDMDB_UPD Reg:SP Reg:SP Imm:12 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R9 Reg:R10 Reg:LR Reg:PC | ldmdbgt sp!, {r0, r1, r4, r9, r10, lr, pc} | affect_cf,may_load",
  ),
  (
    0x993ff823U, "LDMDB_UPD Reg:PC Reg:PC Imm:9 Reg:CPSR Reg:R0 Reg:R1 Reg:R5 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbls pc!, {r0, r1, r5, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x693afe06U, "LDMDB_UPD Reg:R10 Reg:R10 Imm:6 Reg:CPSR Reg:R1 Reg:R2 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbvs r10!, {r1, r2, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe93ff05fU, "LDMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb pc!, {r0, r1, r2, r3, r4, r6, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x2932fd33U, "LDMDB_UPD Reg:R2 Reg:R2 Imm:2 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbhs r2!, {r0, r1, r4, r5, r8, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x693ff2fdU, "LDMDB_UPD Reg:PC Reg:PC Imm:6 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdbvs pc!, {r0, r2, r3, r4, r5, r6, r7, r9, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x593d2000U, "LDMDB_UPD Reg:SP Reg:SP Imm:5 Reg:CPSR Reg:SP | ldmdbpl sp!, {sp} | may_load",
  ),
  (
    0xa93d4020U, "LDMDB_UPD Reg:SP Reg:SP Imm:10 Reg:CPSR Reg:R5 Reg:LR | ldmdbge sp!, {r5, lr} | may_load",
  ),
  (
    0xe93a6010U, "LDMDB_UPD Reg:R10 Reg:R10 Imm:14 Reg:Nil Reg:R4 Reg:SP Reg:LR | ldmdb r10!, {r4, sp, lr} | may_load",
  ),
  (
    0xa935400eU, "LDMDB_UPD Reg:R5 Reg:R5 Imm:10 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:LR | ldmdbge r5!, {r1, r2, r3, lr} | may_load",
  ),
  (
    0x29335450U, "LDMDB_UPD Reg:R3 Reg:R3 Imm:2 Reg:CPSR Reg:R4 Reg:R6 Reg:R10 Reg:R12 Reg:LR | ldmdbhs r3!, {r4, r6, r10, r12, lr} | may_load",
  ),
  (
    0x093d322aU, "LDMDB_UPD Reg:SP Reg:SP Imm:0 Reg:CPSR Reg:R1 Reg:R3 Reg:R5 Reg:R9 Reg:R12 Reg:SP | ldmdbeq sp!, {r1, r3, r5, r9, r12, sp} | may_load",
  ),
  (
    0xe93d1d26U, "LDMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:R12 | ldmdb sp!, {r1, r2, r5, r8, r10, r11, r12} | may_load",
  ),
  (
    0xe9347f08U, "LDMDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmdb r4!, {r3, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0x993d7539U, "LDMDB_UPD Reg:SP Reg:SP Imm:9 Reg:CPSR Reg:R0 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmdbls sp!, {r0, r3, r4, r5, r8, r10, r12, sp, lr} | may_load",
  ),
  (
    0xe9315b6dU, "LDMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:LR | ldmdb r1!, {r0, r2, r3, r5, r6, r8, r9, r11, r12, lr} | may_load",
  ),
  (
    0x59346e7eU, "LDMDB_UPD Reg:R4 Reg:R4 Imm:5 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldmdbpl r4!, {r1, r2, r3, r4, r5, r6, r9, r10, r11, sp, lr} | may_load",
  ),
  (
    0xe89fa000U, "LDMIA Reg:PC Imm:14 Reg:Nil Reg:SP Reg:PC | ldm pc, {sp, pc} | affect_cf,may_load",
  ),
  (
    0x789d9010U, "LDMIA Reg:SP Imm:7 Reg:CPSR Reg:R4 Reg:R12 Reg:PC | ldmvc sp, {r4, r12, pc} | affect_cf,may_load",
  ),
  (
    0xe8928212U, "LDMIA Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:R9 Reg:PC | ldm r2, {r1, r4, r9, pc} | affect_cf,may_load",
  ),
  (
    0xa897b00cU, "LDMIA Reg:R7 Imm:10 Reg:CPSR Reg:R2 Reg:R3 Reg:R12 Reg:SP Reg:PC | ldmge r7, {r2, r3, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe89f860eU, "LDMIA Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R9 Reg:R10 Reg:PC | ldm pc, {r1, r2, r3, r9, r10, pc} | affect_cf,may_load",
  ),
  (
    0xe896e704U, "LDMIA Reg:R6 Imm:14 Reg:Nil Reg:R2 Reg:R8 Reg:R9 Reg:R10 Reg:SP Reg:LR Reg:PC | ldm r6, {r2, r8, r9, r10, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe89fcf28U, "LDMIA Reg:PC Imm:14 Reg:Nil Reg:R3 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR Reg:PC | ldm pc, {r3, r5, r8, r9, r10, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    0x489cfa23U, "LDMIA Reg:R12 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R5 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmmi r12, {r0, r1, r5, r9, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xb896fc56U, "LDMIA Reg:R6 Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R4 Reg:R6 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmlt r6, {r1, r2, r4, r6, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe89e9dafU, "LDMIA Reg:LR Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:PC | ldm lr, {r0, r1, r2, r3, r5, r7, r8, r10, r11, r12, pc} | affect_cf,may_load",
  ),
  (
    0xe89fdf3eU, "LDMIA Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldm pc, {r1, r2, r3, r4, r5, r8, r9, r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    0x589cf9fbU, "LDMIA Reg:R12 Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmpl r12, {r0, r1, r3, r4, r5, r6, r7, r8, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe891000cU, "LDMIA Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:R3 | ldm r1, {r2, r3} | may_load",
  ),
  (
    0x38930d00U, "LDMIA Reg:R3 Imm:3 Reg:CPSR Reg:R8 Reg:R10 Reg:R11 | ldmlo r3, {r8, r10, r11} | may_load",
  ),
  (
    0x389d5030U, "LDMIA Reg:SP Imm:3 Reg:CPSR Reg:R4 Reg:R5 Reg:R12 Reg:LR | ldmlo sp, {r4, r5, r12, lr} | may_load",
  ),
  (
    0xc89d021eU, "LDMIA Reg:SP Imm:12 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R9 | ldmgt sp, {r1, r2, r3, r4, r9} | may_load",
  ),
  (
    0x4895042fU, "LDMIA Reg:R5 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R10 | ldmmi r5, {r0, r1, r2, r3, r5, r10} | may_load",
  ),
  (
    0xe89d702dU, "LDMIA Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R12 Reg:SP Reg:LR | ldm sp, {r0, r2, r3, r5, r12, sp, lr} | may_load",
  ),
  (
    0x289d7934U, "LDMIA Reg:SP Imm:2 Reg:CPSR Reg:R2 Reg:R4 Reg:R5 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmhs sp, {r2, r4, r5, r8, r11, r12, sp, lr} | may_load",
  ),
  (
    0x389d7a2dU, "LDMIA Reg:SP Imm:3 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmlo sp, {r0, r2, r3, r5, r9, r11, r12, sp, lr} | may_load",
  ),
  (
    0xd89d3b4fU, "LDMIA Reg:SP Imm:13 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP | ldmle sp, {r0, r1, r2, r3, r6, r8, r9, r11, r12, sp} | may_load",
  ),
  (
    0xe89a7decU, "LDMIA Reg:R10 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldm r10, {r2, r3, r5, r6, r7, r8, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0xd89e6ffeU, "LDMIA Reg:LR Imm:13 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldmle lr, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, sp, lr} | may_load",
  ),
  (
    0xe8b68010U, "LDMIA_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:R4 Reg:PC | ldm r6!, {r4, pc} | affect_cf,may_load",
  ),
  (
    0xe8bf101cU, "LDMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R4 Reg:R12 | ldm pc!, {r2, r3, r4, r12} | affect_cf,may_load",
  ),
  (
    0xe8b5a308U, "LDMIA_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R3 Reg:R8 Reg:R9 Reg:SP Reg:PC | ldm r5!, {r3, r8, r9, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe8bf852aU, "LDMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R5 Reg:R8 Reg:R10 Reg:PC | ldm pc!, {r1, r3, r5, r8, r10, pc} | affect_cf,may_load",
  ),
  (
    0xe8bfcd06U, "LDMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R8 Reg:R10 Reg:R11 Reg:LR Reg:PC | ldm pc!, {r1, r2, r8, r10, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    0x98b4fe08U, "LDMIA_UPD Reg:R4 Reg:R4 Imm:9 Reg:CPSR Reg:R3 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmls r4!, {r3, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xd8bff03eU, "LDMIA_UPD Reg:PC Reg:PC Imm:13 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmle pc!, {r1, r2, r3, r4, r5, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8bf6a3fU, "LDMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R9 Reg:R11 Reg:SP Reg:LR | ldm pc!, {r0, r1, r2, r3, r4, r5, r9, r11, sp, lr} | affect_cf,may_load",
  ),
  (
    0x78b1f667U, "LDMIA_UPD Reg:R1 Reg:R1 Imm:7 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmvc r1!, {r0, r1, r2, r5, r6, r9, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8bfde7dU, "LDMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldm pc!, {r0, r2, r3, r4, r5, r6, r9, r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    0x08b4ffd9U, "LDMIA_UPD Reg:R4 Reg:R4 Imm:0 Reg:CPSR Reg:R0 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmeq r4!, {r0, r3, r4, r6, r7, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd4000U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:LR | ldm sp!, {lr} | may_load",
  ),
  (
    0xe8b91020U, "LDMIA_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R5 Reg:R12 | ldm r9!, {r5, r12} | may_load",
  ),
  (
    0x78b23008U, "LDMIA_UPD Reg:R2 Reg:R2 Imm:7 Reg:CPSR Reg:R3 Reg:R12 Reg:SP | ldmvc r2!, {r3, r12, sp} | may_load",
  ),
  (
    0xe8b95009U, "LDMIA_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R12 Reg:LR | ldm r9!, {r0, r3, r12, lr} | may_load",
  ),
  (
    0xc8bc6026U, "LDMIA_UPD Reg:R12 Reg:R12 Imm:12 Reg:CPSR Reg:R1 Reg:R2 Reg:R5 Reg:SP Reg:LR | ldmgt r12!, {r1, r2, r5, sp, lr} | may_load",
  ),
  (
    0xe8b47070U, "LDMIA_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R12 Reg:SP Reg:LR | ldm r4!, {r4, r5, r6, r12, sp, lr} | may_load",
  ),
  (
    0x68b3485bU, "LDMIA_UPD Reg:R3 Reg:R3 Imm:6 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R11 Reg:LR | ldmvs r3!, {r0, r1, r3, r4, r6, r11, lr} | may_load",
  ),
  (
    0xe8b5307eU, "LDMIA_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R12 Reg:SP | ldm r5!, {r1, r2, r3, r4, r5, r6, r12, sp} | may_load",
  ),
  (
    0xe8be7f14U, "LDMIA_UPD Reg:LR Reg:LR Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldm lr!, {r2, r4, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0x08b2473fU, "LDMIA_UPD Reg:R2 Reg:R2 Imm:0 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:LR | ldmeq r2!, {r0, r1, r2, r3, r4, r5, r8, r9, r10, lr} | may_load",
  ),
  (
    0xe8bd8800U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R11 Reg:PC | pop {r11, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd8830U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R11 Reg:PC | pop {r4, r5, r11, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd81f0U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:PC | pop {r4, r5, r6, r7, r8, pc} | affect_cf,may_load",
  ),
  (
    0x68bdca68U, "LDMIA_UPD Reg:SP Reg:SP Imm:6 Reg:CPSR Reg:R3 Reg:R5 Reg:R6 Reg:R9 Reg:R11 Reg:LR Reg:PC | popvs {r3, r5, r6, r9, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd8bf0U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:PC | pop {r4, r5, r6, r7, r8, r9, r11, pc} | affect_cf,may_load",
  ),
  (
    0x78bdaa75U, "LDMIA_UPD Reg:SP Reg:SP Imm:7 Reg:CPSR Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R11 Reg:SP Reg:PC | popvc {r0, r2, r4, r5, r6, r9, r11, sp, pc} | affect_cf,may_load",
  ),
  (
    0x48bdc2fbU, "LDMIA_UPD Reg:SP Reg:SP Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:LR Reg:PC | popmi {r0, r1, r3, r4, r5, r6, r7, r9, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd8ffcU, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:PC | pop {r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, pc} | affect_cf,may_load",
  ),
  (
    0xe8bd4800U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R11 Reg:LR | pop {r11, lr} | may_load",
  ),
  (
    0x98bd4030U, "LDMIA_UPD Reg:SP Reg:SP Imm:9 Reg:CPSR Reg:R4 Reg:R5 Reg:LR | popls {r4, r5, lr} | may_load",
  ),
  (
    0xe8bd4830U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R11 Reg:LR | pop {r4, r5, r11, lr} | may_load",
  ),
  (
    0xb8bd510cU, "LDMIA_UPD Reg:SP Reg:SP Imm:11 Reg:CPSR Reg:R2 Reg:R3 Reg:R8 Reg:R12 Reg:LR | poplt {r2, r3, r8, r12, lr} | may_load",
  ),
  (
    0xe8bd48f0U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R11 Reg:LR | pop {r4, r5, r6, r7, r11, lr} | may_load",
  ),
  (
    0xd8bd16abU, "LDMIA_UPD Reg:SP Reg:SP Imm:13 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R7 Reg:R9 Reg:R10 Reg:R12 | pople {r0, r1, r3, r5, r7, r9, r10, r12} | may_load",
  ),
  (
    0xe8bd4ff0U, "LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | pop {r4, r5, r6, r7, r8, r9, r10, r11, lr} | may_load",
  ),
  (
    0xe99c9000U, "LDMIB Reg:R12 Imm:14 Reg:Nil Reg:R12 Reg:PC | ldmib r12, {r12, pc} | affect_cf,may_load",
  ),
  (
    0x099db000U, "LDMIB Reg:SP Imm:0 Reg:CPSR Reg:R12 Reg:SP Reg:PC | ldmibeq sp, {r12, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe995e010U, "LDMIB Reg:R5 Imm:14 Reg:Nil Reg:R4 Reg:SP Reg:LR Reg:PC | ldmib r5, {r4, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xc994890aU, "LDMIB Reg:R4 Imm:12 Reg:CPSR Reg:R1 Reg:R3 Reg:R8 Reg:R11 Reg:PC | ldmibgt r4, {r1, r3, r8, r11, pc} | affect_cf,may_load",
  ),
  (
    0xb996f006U, "LDMIB Reg:R6 Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmiblt r6, {r1, r2, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x099ff601U, "LDMIB Reg:PC Imm:0 Reg:CPSR Reg:R0 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibeq pc, {r0, r9, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x7994f930U, "LDMIB Reg:R4 Imm:7 Reg:CPSR Reg:R4 Reg:R5 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibvc r4, {r4, r5, r8, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe99ff70aU, "LDMIB Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmib pc, {r1, r3, r8, r9, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x9994f44fU, "LDMIB Reg:R4 Imm:9 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibls r4, {r0, r1, r2, r3, r6, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xa992fba5U, "LDMIB Reg:R2 Imm:10 Reg:CPSR Reg:R0 Reg:R2 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibge r2, {r0, r2, r5, r7, r8, r9, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x3990ff1dU, "LDMIB Reg:R0 Imm:3 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmiblo r0, {r0, r2, r3, r4, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x1992fe7eU, "LDMIB Reg:R2 Imm:1 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibne r2, {r1, r2, r3, r4, r5, r6, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x59944040U, "LDMIB Reg:R4 Imm:5 Reg:CPSR Reg:R6 Reg:LR | ldmibpl r4, {r6, lr} | may_load",
  ),
  (
    0x7990200aU, "LDMIB Reg:R0 Imm:7 Reg:CPSR Reg:R1 Reg:R3 Reg:SP | ldmibvc r0, {r1, r3, sp} | may_load",
  ),
  (
    0xe9924214U, "LDMIB Reg:R2 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R9 Reg:LR | ldmib r2, {r2, r4, r9, lr} | may_load",
  ),
  (
    0xe992290aU, "LDMIB Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R8 Reg:R11 Reg:SP | ldmib r2, {r1, r3, r8, r11, sp} | may_load",
  ),
  (
    0xe99f4a1aU, "LDMIB Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R9 Reg:R11 Reg:LR | ldmib pc, {r1, r3, r4, r9, r11, lr} | may_load",
  ),
  (
    0xe99d1f11U, "LDMIB Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | ldmib sp, {r0, r4, r8, r9, r10, r11, r12} | may_load",
  ),
  (
    0xe99f7135U, "LDMIB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R8 Reg:R12 Reg:SP Reg:LR | ldmib pc, {r0, r2, r4, r5, r8, r12, sp, lr} | may_load",
  ),
  (
    0x499d575cU, "LDMIB Reg:SP Imm:4 Reg:CPSR Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:LR | ldmibmi sp, {r2, r3, r4, r6, r8, r9, r10, r12, lr} | may_load",
  ),
  (
    0xc99d367eU, "LDMIB Reg:SP Imm:12 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R12 Reg:SP | ldmibgt sp, {r1, r2, r3, r4, r5, r6, r9, r10, r12, sp} | may_load",
  ),
  (
    0xe99f7e57U, "LDMIB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmib pc, {r0, r1, r2, r4, r6, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    0xa9bdc000U, "LDMIB_UPD Reg:SP Reg:SP Imm:10 Reg:CPSR Reg:LR Reg:PC | ldmibge sp!, {lr, pc} | affect_cf,may_load",
  ),
  (
    0x09bf5200U, "LDMIB_UPD Reg:PC Reg:PC Imm:0 Reg:CPSR Reg:R9 Reg:R12 Reg:LR | ldmibeq pc!, {r9, r12, lr} | affect_cf,may_load",
  ),
  (
    0xb9b09005U, "LDMIB_UPD Reg:R0 Reg:R0 Imm:11 Reg:CPSR Reg:R0 Reg:R2 Reg:R12 Reg:PC | ldmiblt r0!, {r0, r2, r12, pc} | affect_cf,may_load",
  ),
  (
    0xe9b9f100U, "LDMIB_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R8 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmib r9!, {r8, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe9b2901eU, "LDMIB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R12 Reg:PC | ldmib r2!, {r1, r2, r3, r4, r12, pc} | affect_cf,may_load",
  ),
  (
    0xe9bf7609U, "LDMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmib pc!, {r0, r3, r9, r10, r12, sp, lr} | affect_cf,may_load",
  ),
  (
    0x99b1f415U, "LDMIB_UPD Reg:R1 Reg:R1 Imm:9 Reg:CPSR Reg:R0 Reg:R2 Reg:R4 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibls r1!, {r0, r2, r4, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xb9b7fb24U, "LDMIB_UPD Reg:R7 Reg:R7 Imm:11 Reg:CPSR Reg:R2 Reg:R5 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmiblt r7!, {r2, r5, r8, r9, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x99b4f13eU, "LDMIB_UPD Reg:R4 Reg:R4 Imm:9 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibls r4!, {r1, r2, r3, r4, r5, r8, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0xe9bfaf5bU, "LDMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:PC | ldmib pc!, {r0, r1, r3, r4, r6, r8, r9, r10, r11, sp, pc} | affect_cf,may_load",
  ),
  (
    0xe9bff37eU, "LDMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmib pc!, {r1, r2, r3, r4, r5, r6, r8, r9, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x19bbfeedU, "LDMIB_UPD Reg:R11 Reg:R11 Imm:1 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmibne r11!, {r0, r2, r3, r5, r6, r7, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    0x39bd4010U, "LDMIB_UPD Reg:SP Reg:SP Imm:3 Reg:CPSR Reg:R4 Reg:LR | ldmiblo sp!, {r4, lr} | may_load",
  ),
  (
    0xe9bc3010U, "LDMIB_UPD Reg:R12 Reg:R12 Imm:14 Reg:Nil Reg:R4 Reg:R12 Reg:SP | ldmib r12!, {r4, r12, sp} | may_load",
  ),
  (
    0x29b73022U, "LDMIB_UPD Reg:R7 Reg:R7 Imm:2 Reg:CPSR Reg:R1 Reg:R5 Reg:R12 Reg:SP | ldmibhs r7!, {r1, r5, r12, sp} | may_load",
  ),
  (
    0xe9b50d06U, "LDMIB_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R8 Reg:R10 Reg:R11 | ldmib r5!, {r1, r2, r8, r10, r11} | may_load",
  ),
  (
    0x79bd4750U, "LDMIB_UPD Reg:SP Reg:SP Imm:7 Reg:CPSR Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:LR | ldmibvc sp!, {r4, r6, r8, r9, r10, lr} | may_load",
  ),
  (
    0x39b9308fU, "LDMIB_UPD Reg:R9 Reg:R9 Imm:3 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R7 Reg:R12 Reg:SP | ldmiblo r9!, {r0, r1, r2, r3, r7, r12, sp} | may_load",
  ),
  (
    0xa9bb711bU, "LDMIB_UPD Reg:R11 Reg:R11 Imm:10 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R8 Reg:R12 Reg:SP Reg:LR | ldmibge r11!, {r0, r1, r3, r4, r8, r12, sp, lr} | may_load",
  ),
  (
    0x79ba7726U, "LDMIB_UPD Reg:R10 Reg:R10 Imm:7 Reg:CPSR Reg:R1 Reg:R2 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmibvc r10!, {r1, r2, r5, r8, r9, r10, r12, sp, lr} | may_load",
  ),
  (
    0x39be7adaU, "LDMIB_UPD Reg:LR Reg:LR Imm:3 Reg:CPSR Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmiblo lr!, {r1, r3, r4, r6, r7, r9, r11, r12, sp, lr} | may_load",
  ),
  (
    0xe47fba05U, "LDRBT_POST_IMM Reg:R11 Reg:PC Reg:PC Reg:Nil Imm:154117 Imm:14 Reg:Nil | ldrbt r11, [pc], #-2565 | affect_cf,may_load",
  ),
  (
    0xd4700004U, "LDRBT_POST_IMM Reg:R0 Reg:R0 Reg:R0 Reg:Nil Imm:151556 Imm:13 Reg:CPSR | ldrbtle r0, [r0], #-4 | may_load",
  ),
  (
    0xe672f80bU, "LDRBT_POST_REG Reg:PC Reg:R2 Reg:R2 Reg:R11 Imm:151568 Imm:14 Reg:Nil | ldrbt pc, [r2], -r11, lsl #16 | affect_cf,may_load",
  ),
  (
    0x067b7009U, "LDRBT_POST_REG Reg:R7 Reg:R11 Reg:R11 Reg:R9 Imm:151552 Imm:0 Reg:CPSR | ldrbteq r7, [r11], -r9 | may_load",
  ),
  (
    0xe45fe20dU, "LDRB_POST_IMM Reg:LR Reg:PC Reg:PC Reg:Nil Imm:152077 Imm:14 Reg:Nil | ldrb lr, [pc], #-525 | affect_cf,may_load",
  ),
  (
    0xe4de0001U, "LDRB_POST_IMM Reg:R0 Reg:LR Reg:LR Reg:Nil Imm:147457 Imm:14 Reg:Nil | ldrb r0, [lr], #1 | may_load",
  ),
  (
    0x7652f000U, "LDRB_POST_REG Reg:PC Reg:R2 Reg:R2 Reg:R0 Imm:151552 Imm:7 Reg:CPSR | ldrbvc pc, [r2], -r0 | affect_cf,may_load",
  ),
  (
    0xe65c3d04U, "LDRB_POST_REG Reg:R3 Reg:R12 Reg:R12 Reg:R4 Imm:151578 Imm:14 Reg:Nil | ldrb r3, [r12], -r4, lsl #26 | may_load",
  ),
  (
    0xe57ffe00U, "LDRB_PRE_IMM Reg:PC Reg:PC Reg:PC Imm:4294963712 Imm:14 Reg:Nil | ldrb pc, [pc, #-3584]! | affect_cf,may_load",
  ),
  (
    0xe5762101U, "LDRB_PRE_IMM Reg:R2 Reg:R6 Reg:R6 Imm:4294967039 Imm:14 Reg:Nil | ldrb r2, [r6, #-257]! | may_load",
  ),
  (
    0xe77f9708U, "LDRB_PRE_REG Reg:R9 Reg:PC Reg:PC Reg:R8 Imm:20494 Imm:14 Reg:Nil | ldrb r9, [pc, -r8, lsl #14]! | affect_cf,may_load",
  ),
  (
    0xe770b102U, "LDRB_PRE_REG Reg:R11 Reg:R0 Reg:R0 Reg:R2 Imm:20482 Imm:14 Reg:Nil | ldrb r11, [r0, -r2, lsl #2]! | may_load",
  ),
  (
    0x755efb07U, "LDRBi12 Reg:PC Reg:LR Imm:4294964473 Imm:7 Reg:CPSR | ldrbvc pc, [lr, #-2823] | affect_cf,may_load",
  ),
  (
    0xe5d00000U, "LDRBi12 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrb r0, [r0] | may_load",
  ),
  (
    0xc75efc03U, "LDRBrs Reg:PC Reg:LR Reg:R3 Imm:20504 Imm:12 Reg:CPSR | ldrbgt pc, [lr, -r3, lsl #24] | affect_cf,may_load",
  ),
  (
    0xe7d02001U, "LDRBrs Reg:R2 Reg:R0 Reg:R1 Imm:16384 Imm:14 Reg:Nil | ldrb r2, [r0, r1] | may_load",
  ),
  (
    0xb102e0d4U, "LDRD Reg:LR Reg:PC Reg:R2 Reg:R4 Imm:256 Imm:11 Reg:CPSR | ldrdlt lr, pc, [r2, -r4] | affect_cf,may_load",
  ),
  (
    0xe1c420d0U, "LDRD Reg:R2 Reg:R3 Reg:R4 Reg:Nil Imm:0 Imm:14 Reg:Nil | ldrd r2, r3, [r4] | may_load",
  ),
  (
    0xe00f40d8U, "LDRD_POST Reg:R4 Reg:R5 Reg:PC Reg:PC Reg:R8 Imm:1280 Imm:14 Reg:Nil | ldrd r4, r5, [pc], -r8 | affect_cf,may_load",
  ),
  (
    0xe00d7dd4U, "LDRD_POST Reg:R7 Reg:R8 Reg:SP Reg:SP Reg:R4 Imm:1280 Imm:14 Reg:Nil | ldrd r7, r8, [sp], -r4 | may_load",
  ),
  (
    0xd122e0dcU, "LDRD_PRE Reg:LR Reg:PC Reg:R2 Reg:R2 Reg:R12 Imm:768 Imm:13 Reg:CPSR | ldrdle lr, pc, [r2, -r12]! | affect_cf,may_load",
  ),
  (
    0xe12286dbU, "LDRD_PRE Reg:R8 Reg:R9 Reg:R2 Reg:R2 Reg:R11 Imm:768 Imm:14 Reg:Nil | ldrd r8, r9, [r2, -r11]! | may_load",
  ),
  (
    0xe1930f9fU, "LDREX Reg:R0 Reg:R3 Imm:14 Reg:Nil | ldrex r0, [r3] | may_load,may_store",
  ),
  (
    0xe1b00f9fU, "LDREXD Reg:R0_R1 Reg:R0 Imm:14 Reg:Nil | ldrexd r0, r1, [r0] | may_load",
  ),
  (
    0xe110ffbcU, "LDRH Reg:PC Reg:R0 Reg:R12 Imm:256 Imm:14 Reg:Nil | ldrh pc, [r0, -r12] | affect_cf,may_load",
  ),
  (
    0xe1d020b0U, "LDRH Reg:R2 Reg:R0 Reg:Nil Imm:0 Imm:14 Reg:Nil | ldrh r2, [r0] | may_load",
  ),
  (
    0xe07f45bfU, "LDRHTi Reg:R4 Reg:PC Reg:PC Imm:95 Imm:14 Reg:Nil | ldrht r4, [pc], #-95 | affect_cf,may_load",
  ),
  (
    0xe077c6b0U, "LDRHTi Reg:R12 Reg:R7 Reg:R7 Imm:96 Imm:14 Reg:Nil | ldrht r12, [r7], #-96 | may_load",
  ),
  (
    0xe03fcfbcU, "LDRHTr Reg:R12 Reg:PC Reg:PC Reg:R12 Imm:0 Imm:14 Reg:Nil | ldrht r12, [pc], -r12 | affect_cf,may_load",
  ),
  (
    0xe03c49bcU, "LDRHTr Reg:R4 Reg:R12 Reg:R12 Reg:R12 Imm:0 Imm:14 Reg:Nil | ldrht r4, [r12], -r12 | may_load",
  ),
  (
    0xe01f83b7U, "LDRH_POST Reg:R8 Reg:PC Reg:PC Reg:R7 Imm:1280 Imm:14 Reg:Nil | ldrh r8, [pc], -r7 | affect_cf,may_load",
  ),
  (
    0xe0d130b2U, "LDRH_POST Reg:R3 Reg:R1 Reg:R1 Reg:Nil Imm:1026 Imm:14 Reg:Nil | ldrh r3, [r1], #2 | may_load",
  ),
  (
    0xe13ff6b3U, "LDRH_PRE Reg:PC Reg:PC Reg:PC Reg:R3 Imm:768 Imm:14 Reg:Nil | ldrh pc, [pc, -r3]! | affect_cf,may_load",
  ),
  (
    0xe13936bbU, "LDRH_PRE Reg:R3 Reg:R9 Reg:R9 Reg:R11 Imm:768 Imm:14 Reg:Nil | ldrh r3, [r9, -r11]! | may_load",
  ),
  (
    0x5111f4d1U, "LDRSB Reg:PC Reg:R1 Reg:R1 Imm:256 Imm:5 Reg:CPSR | ldrsbpl pc, [r1, -r1] | affect_cf,may_load",
  ),
  (
    0xe1d000d0U, "LDRSB Reg:R0 Reg:R0 Reg:Nil Imm:0 Imm:14 Reg:Nil | ldrsb r0, [r0] | may_load",
  ),
  (
    0x207af0daU, "LDRSBTi Reg:PC Reg:R10 Reg:R10 Imm:10 Imm:2 Reg:CPSR | ldrsbths pc, [r10], #-10 | affect_cf,may_load",
  ),
  (
    0xe07708d2U, "LDRSBTi Reg:R0 Reg:R7 Reg:R7 Imm:130 Imm:14 Reg:Nil | ldrsbt r0, [r7], #-130 | may_load",
  ),
  (
    0xe03f45daU, "LDRSBTr Reg:R4 Reg:PC Reg:PC Reg:R10 Imm:0 Imm:14 Reg:Nil | ldrsbt r4, [pc], -r10 | affect_cf,may_load",
  ),
  (
    0xe0302ddeU, "LDRSBTr Reg:R2 Reg:R0 Reg:R0 Reg:LR Imm:0 Imm:14 Reg:Nil | ldrsbt r2, [r0], -lr | may_load",
  ),
  (
    0xe015fcdbU, "LDRSB_POST Reg:PC Reg:R5 Reg:R5 Reg:R11 Imm:1280 Imm:14 Reg:Nil | ldrsb pc, [r5], -r11 | affect_cf,may_load",
  ),
  (
    0xe01100dbU, "LDRSB_POST Reg:R0 Reg:R1 Reg:R1 Reg:R11 Imm:1280 Imm:14 Reg:Nil | ldrsb r0, [r1], -r11 | may_load",
  ),
  (
    0xe13fb4d5U, "LDRSB_PRE Reg:R11 Reg:PC Reg:PC Reg:R5 Imm:768 Imm:14 Reg:Nil | ldrsb r11, [pc, -r5]! | affect_cf,may_load",
  ),
  (
    0xe13750dfU, "LDRSB_PRE Reg:R5 Reg:R7 Reg:R7 Reg:PC Imm:768 Imm:14 Reg:Nil | ldrsb r5, [r7, -pc]! | may_load",
  ),
  (
    0xe113fafaU, "LDRSH Reg:PC Reg:R3 Reg:R10 Imm:256 Imm:14 Reg:Nil | ldrsh pc, [r3, -r10] | affect_cf,may_load",
  ),
  (
    0xe1dd10f0U, "LDRSH Reg:R1 Reg:SP Reg:Nil Imm:0 Imm:14 Reg:Nil | ldrsh r1, [sp] | may_load",
  ),
  (
    0x00ff00ffU, "LDRSHTi Reg:R0 Reg:PC Reg:PC Imm:271 Imm:0 Reg:CPSR | ldrshteq r0, [pc], #15 | affect_cf,may_load",
  ),
  (
    0xe07a2ef2U, "LDRSHTi Reg:R2 Reg:R10 Reg:R10 Imm:226 Imm:14 Reg:Nil | ldrsht r2, [r10], #-226 | may_load",
  ),
  (
    0xe03f95fcU, "LDRSHTr Reg:R9 Reg:PC Reg:PC Reg:R12 Imm:0 Imm:14 Reg:Nil | ldrsht r9, [pc], -r12 | affect_cf,may_load",
  ),
  (
    0xe03100f9U, "LDRSHTr Reg:R0 Reg:R1 Reg:R1 Reg:R9 Imm:0 Imm:14 Reg:Nil | ldrsht r0, [r1], -r9 | may_load",
  ),
  (
    0xe01ff4f1U, "LDRSH_POST Reg:PC Reg:PC Reg:PC Reg:R1 Imm:1280 Imm:14 Reg:Nil | ldrsh pc, [pc], -r1 | affect_cf,may_load",
  ),
  (
    0xe01b92f4U, "LDRSH_POST Reg:R9 Reg:R11 Reg:R11 Reg:R4 Imm:1280 Imm:14 Reg:Nil | ldrsh r9, [r11], -r4 | may_load",
  ),
  (
    0x913df0f8U, "LDRSH_PRE Reg:PC Reg:SP Reg:SP Reg:R8 Imm:768 Imm:9 Reg:CPSR | ldrshls pc, [sp, -r8]! | affect_cf,may_load",
  ),
  (
    0xe1b100f0U, "LDRSH_PRE Reg:R0 Reg:R1 Reg:R1 Reg:R0 Imm:512 Imm:14 Reg:Nil | ldrsh r0, [r1, r0]! | may_load",
  ),
  (
    0xe43f0403U, "LDRT_POST_IMM Reg:R0 Reg:PC Reg:PC Reg:Nil Imm:152579 Imm:14 Reg:Nil | ldrt r0, [pc], #-1027 | affect_cf,may_load",
  ),
  (
    0xe4369b0dU, "LDRT_POST_IMM Reg:R9 Reg:R6 Reg:R6 Reg:Nil Imm:154381 Imm:14 Reg:Nil | ldrt r9, [r6], #-2829 | may_load",
  ),
  (
    0xe63fff0bU, "LDRT_POST_REG Reg:PC Reg:PC Reg:PC Reg:R11 Imm:151582 Imm:14 Reg:Nil | ldrt pc, [pc], -r11, lsl #30 | affect_cf,may_load",
  ),
  (
    0xe63ead02U, "LDRT_POST_REG Reg:R10 Reg:LR Reg:LR Reg:R2 Imm:151578 Imm:14 Reg:Nil | ldrt r10, [lr], -r2, lsl #26 | may_load",
  ),
  (
    0xe41fa002U, "LDR_POST_IMM Reg:R10 Reg:PC Reg:PC Reg:Nil Imm:151554 Imm:14 Reg:Nil | ldr r10, [pc], #-2 | affect_cf,may_load",
  ),
  (
    0xe4902004U, "LDR_POST_IMM Reg:R2 Reg:R0 Reg:R0 Reg:Nil Imm:147460 Imm:14 Reg:Nil | ldr r2, [r0], #4 | may_load",
  ),
  (
    0xd61ef009U, "LDR_POST_REG Reg:PC Reg:LR Reg:LR Reg:R9 Imm:151552 Imm:13 Reg:CPSR | ldrle pc, [lr], -r9 | affect_cf,may_load",
  ),
  (
    0xe695600cU, "LDR_POST_REG Reg:R6 Reg:R5 Reg:R5 Reg:R12 Imm:147456 Imm:14 Reg:Nil | ldr r6, [r5], r12 | may_load",
  ),
  (
    0x253f7003U, "LDR_PRE_IMM Reg:R7 Reg:PC Reg:PC Imm:4294967293 Imm:2 Reg:CPSR | ldrhs r7, [pc, #-3]! | affect_cf,may_load",
  ),
  (
    0xe5339304U, "LDR_PRE_IMM Reg:R9 Reg:R3 Reg:R3 Imm:4294966524 Imm:14 Reg:Nil | ldr r9, [r3, #-772]! | may_load",
  ),
  (
    0xe73fb70aU, "LDR_PRE_REG Reg:R11 Reg:PC Reg:PC Reg:R10 Imm:20494 Imm:14 Reg:Nil | ldr r11, [pc, -r10, lsl #14]! | affect_cf,may_load",
  ),
  (
    0xe7b02181U, "LDR_PRE_REG Reg:R2 Reg:R0 Reg:R0 Reg:R1 Imm:16387 Imm:14 Reg:Nil | ldr r2, [r0, r1, lsl #3]! | may_load",
  ),
  (
    0xe516ff09U, "LDRi12 Reg:PC Reg:R6 Imm:4294963447 Imm:14 Reg:Nil | ldr pc, [r6, #-3849] | affect_cf,may_load",
  ),
  (
    0xe5900000U, "LDRi12 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldr r0, [r0] | may_load",
  ),
  (
    0x3712fa0bU, "LDRrs Reg:PC Reg:R2 Reg:R11 Imm:20500 Imm:3 Reg:CPSR | ldrlo pc, [r2, -r11, lsl #20] | affect_cf,may_load",
  ),
  (
    0xe79f0000U, "LDRrs Reg:R0 Reg:PC Reg:R0 Imm:16384 Imm:14 Reg:Nil | ldr r0, [pc, r0] | may_load",
  ),
  (
    0xe0233490U, "MLA Reg:R3 Reg:R0 Reg:R4 Reg:R3 Imm:14 Reg:Nil Reg:Nil | mla r3, r0, r4, r3",
  ),
  (
    0xd02fb090U, "MLA Reg:PC Reg:R0 Reg:R0 Reg:R11 Imm:13 Reg:CPSR Reg:Nil | mlale pc, r0, r0, r11 | affect_cf",
  ),
  (
    0xe03a1595U, "MLA Reg:R10 Reg:R5 Reg:R5 Reg:R1 Imm:14 Reg:Nil Reg:CPSR | mlas r10, r5, r5, r1",
  ),
  (
    0xe03f7d94U, "MLA Reg:PC Reg:R4 Reg:SP Reg:R7 Imm:14 Reg:Nil Reg:CPSR | mlas pc, r4, sp, r7 | affect_cf",
  ),
  (
    0xe0614590U, "MLS Reg:R1 Reg:R0 Reg:R5 Reg:R4 Imm:14 Reg:Nil | mls r1, r0, r5, r4",
  ),
  (
    0xe06fb59aU, "MLS Reg:PC Reg:R10 Reg:R5 Reg:R11 Imm:14 Reg:Nil | mls pc, r10, r5, r11 | affect_cf",
  ),
  (
    0xc06a809bU, "MLS Reg:R10 Reg:R11 Reg:R0 Reg:R8 Imm:12 Reg:CPSR | mlsgt r10, r11, r0, r8",
  ),
  (0xe3401101U, "MOVTi16 Reg:R1 Reg:R1 Imm:257 Imm:14 Reg:Nil | movt r1, #257"),
  (
    0xb343f804U, "MOVTi16 Reg:PC Reg:PC Imm:14340 Imm:11 Reg:CPSR | movtlt pc, #14340 | affect_cf",
  ),
  (0xe3b08c1aU, "MOVi Reg:R8 Imm:3098 Imm:14 Reg:Nil Reg:CPSR | movs r8, #6656"),
  (
    0xe3b0f040U, "MOVi Reg:PC Imm:64 Imm:14 Reg:Nil Reg:CPSR | movs pc, #64 | affect_cf",
  ),
  (0x03a00000U, "MOVi Reg:R0 Imm:0 Imm:0 Reg:CPSR Reg:Nil | moveq r0, #0"),
  (
    0x33a0f04dU, "MOVi Reg:PC Imm:77 Imm:3 Reg:CPSR Reg:Nil | movlo pc, #77 | affect_cf",
  ),
  (0x53b04096U, "MOVi Reg:R4 Imm:150 Imm:5 Reg:CPSR Reg:CPSR | movspl r4, #150"),
  (
    0x83b0fa27U, "MOVi Reg:PC Imm:2599 Imm:8 Reg:CPSR Reg:CPSR | movshi pc, #159744 | affect_cf",
  ),
  (0x53000000U, "MOVi16 Reg:R0 Imm:0 Imm:5 Reg:CPSR | movwpl r0, #0"),
  (
    0xe30ff50aU, "MOVi16 Reg:PC Imm:62730 Imm:14 Reg:Nil | movw pc, #62730 | affect_cf",
  ),
  (0xe1a00000U, "MOVr Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | mov r0, r0"),
  (0x61b0d00cU, "MOVr Reg:SP Reg:R12 Imm:6 Reg:CPSR Reg:CPSR | movsvs sp, r12"),
  (0xb1ad0000U, "MOVr_TC Reg:R0 Reg:R0 Imm:11 Reg:CPSR Reg:Nil | movlt r0, r0"),
  (
    0xe1a02140U, "MOVsi Reg:R2 Reg:R0 Imm:17 Imm:14 Reg:Nil Reg:Nil | asr r2, r0, #2",
  ),
  (
    0x01a0f04dU, "MOVsi Reg:PC Reg:SP Imm:1 Imm:0 Reg:CPSR Reg:Nil | asreq pc, sp, #32 | affect_cf",
  ),
  (
    0xe1a0c100U, "MOVsi Reg:R12 Reg:R0 Imm:18 Imm:14 Reg:Nil Reg:Nil | lsl r12, r0, #2",
  ),
  (
    0x31b0ff82U, "MOVsi Reg:PC Reg:R2 Imm:250 Imm:3 Reg:CPSR Reg:CPSR | lslslo pc, r2, #31 | affect_cf",
  ),
  (
    0xe1a00820U, "MOVsi Reg:R0 Reg:R0 Imm:131 Imm:14 Reg:Nil Reg:Nil | lsr r0, r0, #16",
  ),
  (
    0xe1b003aeU, "MOVsi Reg:R0 Reg:LR Imm:59 Imm:14 Reg:Nil Reg:CPSR | lsrs r0, lr, #7",
  ),
  (
    0xe1b0e061U, "MOVsi Reg:LR Reg:R1 Imm:5 Imm:14 Reg:Nil Reg:CPSR | rrxs lr, r1",
  ),
  (
    0xe1a03251U, "MOVsr Reg:R3 Reg:R1 Reg:R2 Imm:1 Imm:14 Reg:Nil Reg:Nil | asr r3, r1, r2",
  ),
  (
    0x51b01052U, "MOVsr Reg:R1 Reg:R2 Reg:R0 Imm:1 Imm:5 Reg:CPSR Reg:CPSR | asrspl r1, r2, r0",
  ),
  (
    0xe1a00110U, "MOVsr Reg:R0 Reg:R0 Reg:R1 Imm:2 Imm:14 Reg:Nil Reg:Nil | lsl r0, r0, r1",
  ),
  (
    0xe1a00530U, "MOVsr Reg:R0 Reg:R0 Reg:R5 Imm:3 Imm:14 Reg:Nil Reg:Nil | lsr r0, r0, r5",
  ),
  (
    0xe1a00170U, "MOVsr Reg:R0 Reg:R0 Reg:R1 Imm:4 Imm:14 Reg:Nil Reg:Nil | ror r0, r0, r1",
  ),
  (0x01010101U, "MRS Reg:R0 Imm:0 Reg:CPSR | mrseq r0, apsr"),
  (0x7103f50fU, "MRS Reg:PC Imm:7 Reg:CPSR | mrsvc pc, apsr | affect_cf"),
  (0x514f4009U, "MRSsys Reg:R4 Imm:5 Reg:CPSR | mrspl r4, spsr"),
  (0x1141f009U, "MRSsys Reg:PC Imm:1 Reg:CPSR | mrsne pc, spsr | affect_cf"),
  (0x2125f00bU, "MSR Imm:5 Reg:R11 Imm:2 Reg:CPSR | msrhs CPSR_sc, r11"),
  (
    0xe0120393U, "MUL Reg:R2 Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:CPSR | muls r2, r3, r3",
  ),
  (
    0xe01f6d91U, "MUL Reg:PC Reg:R1 Reg:SP Imm:14 Reg:Nil Reg:CPSR | muls pc, r1, sp | affect_cf",
  ),
  (
    0x00000090U, "MUL Reg:R0 Reg:R0 Reg:R0 Imm:0 Reg:CPSR Reg:Nil | muleq r0, r0, r0",
  ),
  (
    0xe00f1b9bU, "MUL Reg:PC Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:Nil | mul pc, r11, r11 | affect_cf",
  ),
  (
    0xa015b090U, "MUL Reg:R5 Reg:R0 Reg:R0 Imm:10 Reg:CPSR Reg:CPSR | mulsge r5, r0, r0",
  ),
  (0x03e00000U, "MVNi Reg:R0 Imm:0 Imm:0 Reg:CPSR Reg:Nil | mvneq r0, #0"),
  (
    0x23e0f03cU, "MVNi Reg:PC Imm:60 Imm:2 Reg:CPSR Reg:Nil | mvnhs pc, #60 | affect_cf",
  ),
  (0xe3f02010U, "MVNi Reg:R2 Imm:16 Imm:14 Reg:Nil Reg:CPSR | mvns r2, #16"),
  (
    0xc3f0f0bdU, "MVNi Reg:PC Imm:189 Imm:12 Reg:CPSR Reg:CPSR | mvnsgt pc, #189 | affect_cf",
  ),
  (0xe1e01000U, "MVNr Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | mvn r1, r0"),
  (
    0x21eef00cU, "MVNr Reg:PC Reg:R12 Imm:2 Reg:CPSR Reg:Nil | mvnhs pc, r12 | affect_cf",
  ),
  (0x01f59001U, "MVNr Reg:R9 Reg:R1 Imm:0 Reg:CPSR Reg:CPSR | mvnseq r9, r1"),
  (
    0x01f1f00aU, "MVNr Reg:PC Reg:R10 Imm:0 Reg:CPSR Reg:CPSR | mvnseq pc, r10 | affect_cf",
  ),
  (
    0xe1e8ec09U, "MVNsi Reg:LR Reg:R9 Imm:194 Imm:14 Reg:Nil Reg:Nil | mvn lr, r9, lsl #24",
  ),
  (
    0x41eff304U, "MVNsi Reg:PC Reg:R4 Imm:50 Imm:4 Reg:CPSR Reg:Nil | mvnmi pc, r4, lsl #6 | affect_cf",
  ),
  (
    0xe1f03d0fU, "MVNsi Reg:R3 Reg:PC Imm:210 Imm:14 Reg:Nil Reg:CPSR | mvns r3, pc, lsl #26",
  ),
  (
    0x31fff209U, "MVNsi Reg:PC Reg:R9 Imm:34 Imm:3 Reg:CPSR Reg:CPSR | mvnslo pc, r9, lsl #4 | affect_cf",
  ),
  (
    0xe1ef4113U, "MVNsr Reg:R4 Reg:R3 Reg:R1 Imm:2 Imm:14 Reg:Nil Reg:Nil | mvn r4, r3, lsl r1",
  ),
  (
    0xe1e4f219U, "MVNsr Reg:PC Reg:R9 Reg:R2 Imm:2 Imm:14 Reg:Nil Reg:Nil | mvn pc, r9, lsl r2 | affect_cf",
  ),
  (
    0xe1f5b71bU, "MVNsr Reg:R11 Reg:R11 Reg:R7 Imm:2 Imm:14 Reg:Nil Reg:CPSR | mvns r11, r11, lsl r7",
  ),
  (
    0xd1fcf612U, "MVNsr Reg:PC Reg:R2 Reg:R6 Imm:2 Imm:13 Reg:CPSR Reg:CPSR | mvnsle pc, r2, lsl r6 | affect_cf",
  ),
  (
    0xe3801001U, "ORRri Reg:R1 Reg:R0 Imm:1 Imm:14 Reg:Nil Reg:Nil | orr r1, r0, #1",
  ),
  (
    0xe388f50eU, "ORRri Reg:PC Reg:R8 Imm:1294 Imm:14 Reg:Nil Reg:Nil | orr pc, r8, #58720256 | affect_cf",
  ),
  (
    0xe39e8e04U, "ORRri Reg:R8 Reg:LR Imm:3588 Imm:14 Reg:Nil Reg:CPSR | orrs r8, lr, #4, #28",
  ),
  (
    0x239cf00cU, "ORRri Reg:PC Reg:R12 Imm:12 Imm:2 Reg:CPSR Reg:CPSR | orrshs pc, r12, #12 | affect_cf",
  ),
  (
    0xe1800001U, "ORRrr Reg:R0 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | orr r0, r0, r1",
  ),
  (
    0x9185f00aU, "ORRrr Reg:PC Reg:R5 Reg:R10 Imm:9 Reg:CPSR Reg:Nil | orrls pc, r5, r10 | affect_cf",
  ),
  (
    0xe192c003U, "ORRrr Reg:R12 Reg:R2 Reg:R3 Imm:14 Reg:Nil Reg:CPSR | orrs r12, r2, r3",
  ),
  (
    0x8195f005U, "ORRrr Reg:PC Reg:R5 Reg:R5 Imm:8 Reg:CPSR Reg:CPSR | orrshi pc, r5, r5 | affect_cf",
  ),
  (
    0xe1821401U, "ORRrsi Reg:R1 Reg:R2 Reg:R1 Imm:66 Imm:14 Reg:Nil Reg:Nil | orr r1, r2, r1, lsl #8",
  ),
  (
    0xc188f802U, "ORRrsi Reg:PC Reg:R8 Reg:R2 Imm:130 Imm:12 Reg:CPSR Reg:Nil | orrgt pc, r8, r2, lsl #16 | affect_cf",
  ),
  (
    0xe19f820fU, "ORRrsi Reg:R8 Reg:PC Reg:PC Imm:34 Imm:14 Reg:Nil Reg:CPSR | orrs r8, pc, pc, lsl #4",
  ),
  (
    0x419bfc02U, "ORRrsi Reg:PC Reg:R11 Reg:R2 Imm:194 Imm:4 Reg:CPSR Reg:CPSR | orrsmi pc, r11, r2, lsl #24 | affect_cf",
  ),
  (
    0xe1800611U, "ORRrsr Reg:R0 Reg:R0 Reg:R1 Reg:R6 Imm:2 Imm:14 Reg:Nil Reg:Nil | orr r0, r0, r1, lsl r6",
  ),
  (
    0x518ff010U, "ORRrsr Reg:PC Reg:PC Reg:R0 Reg:R0 Imm:2 Imm:5 Reg:CPSR Reg:Nil | orrpl pc, pc, r0, lsl r0 | affect_cf",
  ),
  (
    0xe198ce18U, "ORRrsr Reg:R12 Reg:R8 Reg:R8 Reg:LR Imm:2 Imm:14 Reg:Nil Reg:CPSR | orrs r12, r8, r8, lsl lr",
  ),
  (
    0xc198f81eU, "ORRrsr Reg:PC Reg:R8 Reg:LR Reg:R8 Imm:2 Imm:12 Reg:CPSR Reg:CPSR | orrsgt pc, r8, lr, lsl r8 | affect_cf",
  ),
  (
    0xe6853517U, "PKHBT Reg:R3 Reg:R5 Reg:R7 Imm:10 Imm:14 Reg:Nil | pkhbt r3, r5, r7, lsl #10",
  ),
  (
    0x4684f01dU, "PKHBT Reg:PC Reg:R4 Reg:SP Imm:0 Imm:4 Reg:CPSR | pkhbtmi pc, r4, sp | affect_cf",
  ),
  (
    0xe68e0451U, "PKHTB Reg:R0 Reg:LR Reg:R1 Imm:8 Imm:14 Reg:Nil | pkhtb r0, lr, r1, asr #8",
  ),
  (
    0x368cf65fU, "PKHTB Reg:PC Reg:R12 Reg:PC Imm:12 Imm:3 Reg:CPSR | pkhtblo pc, r12, pc, asr #12 | affect_cf",
  ),
  (
    0xf553f010U, "PLDi12 Reg:R3 Imm:4294967280 | pld [r3, #-16] | may_load,may_store",
  ),
  (0xe6ff0f30U, "RBIT Reg:R0 Reg:R0 Imm:14 Reg:Nil | rbit r0, r0"),
  (0x46ffff39U, "RBIT Reg:PC Reg:R9 Imm:4 Reg:CPSR | rbitmi pc, r9 | affect_cf"),
  (0xe6bf0f30U, "REV Reg:R0 Reg:R0 Imm:14 Reg:Nil | rev r0, r0"),
  (0xe6bf0fb0U, "REV16 Reg:R0 Reg:R0 Imm:14 Reg:Nil | rev16 r0, r0"),
  (
    0xe2611000U, "RSBri Reg:R1 Reg:R1 Imm:0 Imm:14 Reg:Nil Reg:Nil | rsb r1, r1, #0",
  ),
  (
    0x1261f208U, "RSBri Reg:PC Reg:R1 Imm:520 Imm:1 Reg:CPSR Reg:Nil | rsbne pc, r1, #8, #4 | affect_cf",
  ),
  (
    0xe27d1b0bU, "RSBri Reg:R1 Reg:SP Imm:2827 Imm:14 Reg:Nil Reg:CPSR | rsbs r1, sp, #11264",
  ),
  (
    0xc274f50bU, "RSBri Reg:PC Reg:R4 Imm:1291 Imm:12 Reg:CPSR Reg:CPSR | rsbsgt pc, r4, #46137344 | affect_cf",
  ),
  (
    0x606dc000U, "RSBrr Reg:R12 Reg:SP Reg:R0 Imm:6 Reg:CPSR Reg:Nil | rsbvs r12, sp, r0",
  ),
  (
    0x906df006U, "RSBrr Reg:PC Reg:SP Reg:R6 Imm:9 Reg:CPSR Reg:Nil | rsbls pc, sp, r6 | affect_cf",
  ),
  (
    0x907d7000U, "RSBrr Reg:R7 Reg:SP Reg:R0 Imm:9 Reg:CPSR Reg:CPSR | rsbsls r7, sp, r0",
  ),
  (
    0x0076f007U, "RSBrr Reg:PC Reg:R6 Reg:R7 Imm:0 Reg:CPSR Reg:CPSR | rsbseq pc, r6, r7 | affect_cf",
  ),
  (
    0xe061c181U, "RSBrsi Reg:R12 Reg:R1 Reg:R1 Imm:26 Imm:14 Reg:Nil Reg:Nil | rsb r12, r1, r1, lsl #3",
  ),
  (
    0x9066f90aU, "RSBrsi Reg:PC Reg:R6 Reg:R10 Imm:146 Imm:9 Reg:CPSR Reg:Nil | rsbls pc, r6, r10, lsl #18 | affect_cf",
  ),
  (
    0xe071e508U, "RSBrsi Reg:LR Reg:R1 Reg:R8 Imm:82 Imm:14 Reg:Nil Reg:CPSR | rsbs lr, r1, r8, lsl #10",
  ),
  (
    0xb079fc05U, "RSBrsi Reg:PC Reg:R9 Reg:R5 Imm:194 Imm:11 Reg:CPSR Reg:CPSR | rsbslt pc, r9, r5, lsl #24 | affect_cf",
  ),
  (
    0xe06ac11dU, "RSBrsr Reg:R12 Reg:R10 Reg:SP Reg:R1 Imm:2 Imm:14 Reg:Nil Reg:Nil | rsb r12, r10, sp, lsl r1",
  ),
  (
    0x806ef417U, "RSBrsr Reg:PC Reg:LR Reg:R7 Reg:R4 Imm:2 Imm:8 Reg:CPSR Reg:Nil | rsbhi pc, lr, r7, lsl r4 | affect_cf",
  ),
  (
    0xe0745419U, "RSBrsr Reg:R5 Reg:R4 Reg:R9 Reg:R4 Imm:2 Imm:14 Reg:Nil Reg:CPSR | rsbs r5, r4, r9, lsl r4",
  ),
  (
    0xc07efd17U, "RSBrsr Reg:PC Reg:LR Reg:R7 Reg:SP Imm:2 Imm:12 Reg:CPSR Reg:CPSR | rsbsgt pc, lr, r7, lsl sp | affect_cf",
  ),
  (
    0xe2e05709U, "RSCri Reg:R5 Reg:R0 Imm:1801 Imm:14 Reg:Nil Reg:Nil | rsc r5, r0, #2359296",
  ),
  (
    0x92eef604U, "RSCri Reg:PC Reg:LR Imm:1540 Imm:9 Reg:CPSR Reg:Nil | rscls pc, lr, #4, #12 | affect_cf",
  ),
  (
    0xe2fb5909U, "RSCri Reg:R5 Reg:R11 Imm:2313 Imm:14 Reg:Nil Reg:CPSR | rscs r5, r11, #147456",
  ),
  (
    0x62f3f804U, "RSCri Reg:PC Reg:R3 Imm:2052 Imm:6 Reg:CPSR Reg:CPSR | rscsvs pc, r3, #4, #16 | affect_cf",
  ),
  (
    0x70e88005U, "RSCrr Reg:R8 Reg:R8 Reg:R5 Imm:7 Reg:CPSR Reg:Nil | rscvc r8, r8, r5",
  ),
  (
    0xe0ebf007U, "RSCrr Reg:PC Reg:R11 Reg:R7 Imm:14 Reg:Nil Reg:Nil | rsc pc, r11, r7 | affect_cf",
  ),
  (
    0xc0f63001U, "RSCrr Reg:R3 Reg:R6 Reg:R1 Imm:12 Reg:CPSR Reg:CPSR | rscsgt r3, r6, r1",
  ),
  (
    0x40fff00cU, "RSCrr Reg:PC Reg:PC Reg:R12 Imm:4 Reg:CPSR Reg:CPSR | rscsmi pc, pc, r12 | affect_cf",
  ),
  (
    0xe0ea620bU, "RSCrsi Reg:R6 Reg:R10 Reg:R11 Imm:34 Imm:14 Reg:Nil Reg:Nil | rsc r6, r10, r11, lsl #4",
  ),
  (
    0xa0e2ff26U, "RSCrsi Reg:PC Reg:R2 Reg:R6 Imm:243 Imm:10 Reg:CPSR Reg:Nil | rscge pc, r2, r6, lsr #30 | affect_cf",
  ),
  (
    0xe0f52905U, "RSCrsi Reg:R2 Reg:R5 Reg:R5 Imm:146 Imm:14 Reg:Nil Reg:CPSR | rscs r2, r5, r5, lsl #18",
  ),
  (
    0x00f1f106U, "RSCrsi Reg:PC Reg:R1 Reg:R6 Imm:18 Imm:0 Reg:CPSR Reg:CPSR | rscseq pc, r1, r6, lsl #2 | affect_cf",
  ),
  (
    0xe0e2c510U, "RSCrsr Reg:R12 Reg:R2 Reg:R0 Reg:R5 Imm:2 Imm:14 Reg:Nil Reg:Nil | rsc r12, r2, r0, lsl r5",
  ),
  (
    0xb0e9ff11U, "RSCrsr Reg:PC Reg:R9 Reg:R1 Reg:PC Imm:2 Imm:11 Reg:CPSR Reg:Nil | rsclt pc, r9, r1, lsl pc | affect_cf",
  ),
  (
    0xe0f6371eU, "RSCrsr Reg:R3 Reg:R6 Reg:LR Reg:R7 Imm:2 Imm:14 Reg:Nil Reg:CPSR | rscs r3, r6, lr, lsl r7",
  ),
  (
    0x90f9f415U, "RSCrsr Reg:PC Reg:R9 Reg:R5 Reg:R4 Imm:2 Imm:9 Reg:CPSR Reg:CPSR | rscsls pc, r9, r5, lsl r4 | affect_cf",
  ),
  (
    0xe2c0a608U, "SBCri Reg:R10 Reg:R0 Imm:1544 Imm:14 Reg:Nil Reg:Nil | sbc r10, r0, #8, #12",
  ),
  (
    0xe2cff20fU, "SBCri Reg:PC Reg:PC Imm:527 Imm:14 Reg:Nil Reg:Nil | sbc pc, pc, #-268435456 | affect_cf",
  ),
  (
    0xe2d8bc08U, "SBCri Reg:R11 Reg:R8 Imm:3080 Imm:14 Reg:Nil Reg:CPSR | sbcs r11, r8, #8, #24",
  ),
  (
    0x32dbf604U, "SBCri Reg:PC Reg:R11 Imm:1540 Imm:3 Reg:CPSR Reg:CPSR | sbcslo pc, r11, #4, #12 | affect_cf",
  ),
  (
    0xe0c11002U, "SBCrr Reg:R1 Reg:R1 Reg:R2 Imm:14 Reg:Nil Reg:Nil | sbc r1, r1, r2",
  ),
  (
    0x60c5f006U, "SBCrr Reg:PC Reg:R5 Reg:R6 Imm:6 Reg:CPSR Reg:Nil | sbcvs pc, r5, r6 | affect_cf",
  ),
  (
    0xc0de400fU, "SBCrr Reg:R4 Reg:LR Reg:PC Imm:12 Reg:CPSR Reg:CPSR | sbcsgt r4, lr, pc",
  ),
  (
    0xe0d0f000U, "SBCrr Reg:PC Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | sbcs pc, r0, r0 | affect_cf",
  ),
  (
    0xe0ceee03U, "SBCrsi Reg:LR Reg:LR Reg:R3 Imm:226 Imm:14 Reg:Nil Reg:Nil | sbc lr, lr, r3, lsl #28",
  ),
  (
    0x60c3fa08U, "SBCrsi Reg:PC Reg:R3 Reg:R8 Imm:162 Imm:6 Reg:CPSR Reg:Nil | sbcvs pc, r3, r8, lsl #20 | affect_cf",
  ),
  (
    0xe0d97b07U, "SBCrsi Reg:R7 Reg:R9 Reg:R7 Imm:178 Imm:14 Reg:Nil Reg:CPSR | sbcs r7, r9, r7, lsl #22",
  ),
  (
    0xe0d9ff04U, "SBCrsi Reg:PC Reg:R9 Reg:R4 Imm:242 Imm:14 Reg:Nil Reg:CPSR | sbcs pc, r9, r4, lsl #30 | affect_cf",
  ),
  (
    0xe0c0021cU, "SBCrsr Reg:R0 Reg:R0 Reg:R12 Reg:R2 Imm:2 Imm:14 Reg:Nil Reg:Nil | sbc r0, r0, r12, lsl r2",
  ),
  (
    0x90c0fa18U, "SBCrsr Reg:PC Reg:R0 Reg:R8 Reg:R10 Imm:2 Imm:9 Reg:CPSR Reg:Nil | sbcls pc, r0, r8, lsl r10 | affect_cf",
  ),
  (
    0xe0dfc413U, "SBCrsr Reg:R12 Reg:PC Reg:R3 Reg:R4 Imm:2 Imm:14 Reg:Nil Reg:CPSR | sbcs r12, pc, r3, lsl r4",
  ),
  (
    0xc0d4fb1dU, "SBCrsr Reg:PC Reg:R4 Reg:SP Reg:R11 Imm:2 Imm:12 Reg:CPSR Reg:CPSR | sbcsgt pc, r4, sp, lsl r11 | affect_cf",
  ),
  (
    0xe7a42550U, "SBFX Reg:R2 Reg:R0 Imm:10 Imm:4 Imm:14 Reg:Nil | sbfx r2, r0, #10, #5",
  ),
  (
    0xe7a9f454U, "SBFX Reg:PC Reg:R4 Imm:8 Imm:9 Imm:14 Reg:Nil | sbfx pc, r4, #8, #10 | affect_cf",
  ),
  (
    0xe1001280U, "SMLABB Reg:R0 Reg:R0 Reg:R2 Reg:R1 Imm:14 Reg:Nil | smlabb r0, r0, r2, r1",
  ),
  (
    0xe10fce86U, "SMLABB Reg:PC Reg:R6 Reg:LR Reg:R12 Imm:14 Reg:Nil | smlabb pc, r6, lr, r12 | affect_cf",
  ),
  (
    0xe10690cbU, "SMLABT Reg:R6 Reg:R11 Reg:R0 Reg:R9 Imm:14 Reg:Nil | smlabt r6, r11, r0, r9",
  ),
  (
    0xe10ffac3U, "SMLABT Reg:PC Reg:R3 Reg:R10 Reg:PC Imm:14 Reg:Nil | smlabt pc, r3, r10, pc | affect_cf",
  ),
  (
    0xe7084f12U, "SMLAD Reg:R8 Reg:R2 Reg:PC Reg:R4 Imm:14 Reg:Nil | smlad r8, r2, pc, r4",
  ),
  (
    0xe70f6a15U, "SMLAD Reg:PC Reg:R5 Reg:R10 Reg:R6 Imm:14 Reg:Nil | smlad pc, r5, r10, r6 | affect_cf",
  ),
  (
    0xe700843dU, "SMLADX Reg:R0 Reg:SP Reg:R4 Reg:R8 Imm:14 Reg:Nil | smladx r0, sp, r4, r8",
  ),
  (
    0xe70f383bU, "SMLADX Reg:PC Reg:R11 Reg:R8 Reg:R3 Imm:14 Reg:Nil | smladx pc, r11, r8, r3 | affect_cf",
  ),
  (
    0xe0f9e395U, "SMLAL Reg:LR Reg:R9 Reg:R5 Reg:R3 Reg:LR Reg:R9 Imm:14 Reg:Nil Reg:CPSR | smlals lr, r9, r5, r3",
  ),
  (
    0xe0ff3b9fU, "SMLAL Reg:R3 Reg:PC Reg:PC Reg:R11 Reg:R3 Reg:PC Imm:14 Reg:Nil Reg:CPSR | smlals r3, pc, pc, r11 | affect_cf",
  ),
  (
    0xe0e10292U, "SMLAL Reg:R0 Reg:R1 Reg:R2 Reg:R2 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | smlal r0, r1, r2, r2",
  ),
  (
    0xe0ef449bU, "SMLAL Reg:R4 Reg:PC Reg:R11 Reg:R4 Reg:R4 Reg:PC Imm:14 Reg:Nil Reg:Nil | smlal r4, pc, r11, r4 | affect_cf",
  ),
  (
    0x70fdc09cU, "SMLAL Reg:R12 Reg:SP Reg:R12 Reg:R0 Reg:R12 Reg:SP Imm:7 Reg:CPSR Reg:CPSR | smlalsvc r12, sp, r12, r0",
  ),
  (
    0xd0f6f492U, "SMLAL Reg:PC Reg:R6 Reg:R2 Reg:R4 Reg:PC Reg:R6 Imm:13 Reg:CPSR Reg:CPSR | smlalsle pc, r6, r2, r4 | affect_cf",
  ),
  (
    0xe1426488U, "SMLALBB Reg:R6 Reg:R2 Reg:R8 Reg:R4 Reg:R6 Reg:R2 Imm:14 Reg:Nil | smlalbb r6, r2, r8, r4",
  ),
  (
    0xe14f2484U, "SMLALBB Reg:R2 Reg:PC Reg:R4 Reg:R4 Reg:R2 Reg:PC Imm:14 Reg:Nil | smlalbb r2, pc, r4, r4 | affect_cf",
  ),
  (
    0xe1492dceU, "SMLALBT Reg:R2 Reg:R9 Reg:LR Reg:SP Reg:R2 Reg:R9 Imm:14 Reg:Nil | smlalbt r2, r9, lr, sp",
  ),
  (
    0xe14f86cdU, "SMLALBT Reg:R8 Reg:PC Reg:SP Reg:R6 Reg:R8 Reg:PC Imm:14 Reg:Nil | smlalbt r8, pc, sp, r6 | affect_cf",
  ),
  (
    0xe14acea4U, "SMLALTB Reg:R12 Reg:R10 Reg:R4 Reg:LR Reg:R12 Reg:R10 Imm:14 Reg:Nil | smlaltb r12, r10, r4, lr",
  ),
  (
    0xe14fb8acU, "SMLALTB Reg:R11 Reg:PC Reg:R12 Reg:R8 Reg:R11 Reg:PC Imm:14 Reg:Nil | smlaltb r11, pc, r12, r8 | affect_cf",
  ),
  (
    0xe14b1eeaU, "SMLALTT Reg:R1 Reg:R11 Reg:R10 Reg:LR Reg:R1 Reg:R11 Imm:14 Reg:Nil | smlaltt r1, r11, r10, lr",
  ),
  (
    0xe14f9ceeU, "SMLALTT Reg:R9 Reg:PC Reg:LR Reg:R12 Reg:R9 Reg:PC Imm:14 Reg:Nil | smlaltt r9, pc, lr, r12 | affect_cf",
  ),
  (
    0xe10ad6aeU, "SMLATB Reg:R10 Reg:LR Reg:R6 Reg:SP Imm:14 Reg:Nil | smlatb r10, lr, r6, sp",
  ),
  (
    0xe10f7ba3U, "SMLATB Reg:PC Reg:R3 Reg:R11 Reg:R7 Imm:14 Reg:Nil | smlatb pc, r3, r11, r7 | affect_cf",
  ),
  (
    0xe109b2ebU, "SMLATT Reg:R9 Reg:R11 Reg:R2 Reg:R11 Imm:14 Reg:Nil | smlatt r9, r11, r2, r11",
  ),
  (
    0xe10f86e5U, "SMLATT Reg:PC Reg:R5 Reg:R6 Reg:R8 Imm:14 Reg:Nil | smlatt pc, r5, r6, r8 | affect_cf",
  ),
  (
    0xe124f08eU, "SMLAWB Reg:R4 Reg:LR Reg:R0 Reg:PC Imm:14 Reg:Nil | smlawb r4, lr, r0, pc",
  ),
  (
    0xe12fae89U, "SMLAWB Reg:PC Reg:R9 Reg:LR Reg:R10 Imm:14 Reg:Nil | smlawb pc, r9, lr, r10 | affect_cf",
  ),
  (
    0xe1228fc1U, "SMLAWT Reg:R2 Reg:R1 Reg:PC Reg:R8 Imm:14 Reg:Nil | smlawt r2, r1, pc, r8",
  ),
  (
    0xe12f8cc0U, "SMLAWT Reg:PC Reg:R0 Reg:R12 Reg:R8 Imm:14 Reg:Nil | smlawt pc, r0, r12, r8 | affect_cf",
  ),
  (
    0x0704f816U, "SMUAD Reg:R4 Reg:R6 Reg:R8 Imm:0 Reg:CPSR | smuadeq r4, r6, r8",
  ),
  (
    0xd70ff016U, "SMUAD Reg:PC Reg:R6 Reg:R0 Imm:13 Reg:CPSR | smuadle pc, r6, r0 | affect_cf",
  ),
  (
    0x070bf837U, "SMUADX Reg:R11 Reg:R7 Reg:R8 Imm:0 Reg:CPSR | smuadxeq r11, r7, r8",
  ),
  (
    0xe1600081U, "SMULBB Reg:R0 Reg:R1 Reg:R0 Imm:14 Reg:Nil | smulbb r0, r1, r0",
  ),
  (
    0xe16f5e89U, "SMULBB Reg:PC Reg:R9 Reg:LR Imm:14 Reg:Nil | smulbb pc, r9, lr | affect_cf",
  ),
  (
    0xe1699cc6U, "SMULBT Reg:R9 Reg:R6 Reg:R12 Imm:14 Reg:Nil | smulbt r9, r6, r12",
  ),
  (
    0xe16f21ccU, "SMULBT Reg:PC Reg:R12 Reg:R1 Imm:14 Reg:Nil | smulbt pc, r12, r1 | affect_cf",
  ),
  (
    0xe0debf92U, "SMULL Reg:R11 Reg:LR Reg:R2 Reg:PC Imm:14 Reg:Nil Reg:CPSR | smulls r11, lr, r2, pc",
  ),
  (
    0xe0df9a92U, "SMULL Reg:R9 Reg:PC Reg:R2 Reg:R10 Imm:14 Reg:Nil Reg:CPSR | smulls r9, pc, r2, r10 | affect_cf",
  ),
  (
    0xe0c10190U, "SMULL Reg:R0 Reg:R1 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | smull r0, r1, r0, r1",
  ),
  (
    0xe0c1fe92U, "SMULL Reg:PC Reg:R1 Reg:R2 Reg:LR Imm:14 Reg:Nil Reg:Nil | smull pc, r1, r2, lr | affect_cf",
  ),
  (
    0xa0dd7090U, "SMULL Reg:R7 Reg:SP Reg:R0 Reg:R0 Imm:10 Reg:CPSR Reg:CPSR | smullsge r7, sp, r0, r0",
  ),
  (
    0xb0dfef94U, "SMULL Reg:LR Reg:PC Reg:R4 Reg:PC Imm:11 Reg:CPSR Reg:CPSR | smullslt lr, pc, r4, pc | affect_cf",
  ),
  (
    0xe16baca9U, "SMULTB Reg:R11 Reg:R9 Reg:R12 Imm:14 Reg:Nil | smultb r11, r9, r12",
  ),
  (
    0xe16f84aaU, "SMULTB Reg:PC Reg:R10 Reg:R4 Imm:14 Reg:Nil | smultb pc, r10, r4 | affect_cf",
  ),
  (
    0xe16c47eeU, "SMULTT Reg:R12 Reg:LR Reg:R7 Imm:14 Reg:Nil | smultt r12, lr, r7",
  ),
  (
    0x316f00e2U, "SMULTT Reg:PC Reg:R2 Reg:R0 Imm:3 Reg:CPSR | smulttlo pc, r2, r0 | affect_cf",
  ),
  (
    0xe126bcafU, "SMULWB Reg:R6 Reg:PC Reg:R12 Imm:14 Reg:Nil | smulwb r6, pc, r12",
  ),
  (
    0xe12ffea7U, "SMULWB Reg:PC Reg:R7 Reg:LR Imm:14 Reg:Nil | smulwb pc, r7, lr | affect_cf",
  ),
  (
    0xe12072efU, "SMULWT Reg:R0 Reg:PC Reg:R2 Imm:14 Reg:Nil | smulwt r0, pc, r2",
  ),
  (
    0xe12f8eefU, "SMULWT Reg:PC Reg:PC Reg:LR Imm:14 Reg:Nil | smulwt pc, pc, lr | affect_cf",
  ),
  (
    0x680d4000U, "STMDA Reg:SP Imm:6 Reg:CPSR Reg:LR | stmdavs sp, {lr} | may_store",
  ),
  (
    0xe80d2040U, "STMDA Reg:SP Imm:14 Reg:Nil Reg:R6 Reg:SP | stmda sp, {r6, sp} | may_store",
  ),
  (
    0xb80d3010U, "STMDA Reg:SP Imm:11 Reg:CPSR Reg:R4 Reg:R12 Reg:SP | stmdalt sp, {r4, r12, sp} | may_store",
  ),
  (
    0xe808120cU, "STMDA Reg:R8 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R9 Reg:R12 | stmda r8, {r2, r3, r9, r12} | may_store",
  ),
  (
    0xe80ef004U, "STMDA Reg:LR Imm:14 Reg:Nil Reg:R2 Reg:R12 Reg:SP Reg:LR Reg:PC | stmda lr, {r2, r12, sp, lr, pc} | may_store",
  ),
  (
    0x980dae04U, "STMDA Reg:SP Imm:9 Reg:CPSR Reg:R2 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:PC | stmdals sp, {r2, r9, r10, r11, sp, pc} | may_store",
  ),
  (
    0xe80f7905U, "STMDA Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR | stmda pc, {r0, r2, r8, r11, r12, sp, lr} | may_store",
  ),
  (
    0x4802f82aU, "STMDA Reg:R2 Imm:4 Reg:CPSR Reg:R1 Reg:R3 Reg:R5 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdami r2, {r1, r3, r5, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe8078f2dU, "STMDA Reg:R7 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:PC | stmda r7, {r0, r2, r3, r5, r8, r9, r10, r11, pc} | may_store",
  ),
  (
    0x4808fc0fU, "STMDA Reg:R8 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdami r8, {r0, r1, r2, r3, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x2802fc3dU, "STMDA Reg:R2 Imm:2 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdahs r2, {r0, r2, r3, r4, r5, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x1803df5dU, "STMDA Reg:R3 Imm:1 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | stmdane r3, {r0, r2, r3, r4, r6, r8, r9, r10, r11, r12, lr, pc} | may_store",
  ),
  (
    0xb80aff73U, "STMDA Reg:R10 Imm:11 Reg:CPSR Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdalt r10, {r0, r1, r4, r5, r6, r8, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe82f1060U, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R5 Reg:R6 Reg:R12 | stmda pc!, {r5, r6, r12} | affect_cf,may_store",
  ),
  (
    0xe82f3042U, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R6 Reg:R12 Reg:SP | stmda pc!, {r1, r6, r12, sp} | affect_cf,may_store",
  ),
  (
    0xe82f8708U, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:PC | stmda pc!, {r3, r8, r9, r10, pc} | affect_cf,may_store",
  ),
  (
    0xe82f891aU, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R8 Reg:R11 Reg:PC | stmda pc!, {r1, r3, r4, r8, r11, pc} | affect_cf,may_store",
  ),
  (
    0xe82f648eU, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R7 Reg:R10 Reg:SP Reg:LR | stmda pc!, {r1, r2, r3, r7, r10, sp, lr} | affect_cf,may_store",
  ),
  (
    0xe82fbd50U, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R4 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:PC | stmda pc!, {r4, r6, r8, r10, r11, r12, sp, pc} | affect_cf,may_store",
  ),
  (
    0xe82fd527U, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R8 Reg:R10 Reg:R12 Reg:LR Reg:PC | stmda pc!, {r0, r1, r2, r5, r8, r10, r12, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe82f553fU, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R12 Reg:LR | stmda pc!, {r0, r1, r2, r3, r4, r5, r8, r10, r12, lr} | affect_cf,may_store",
  ),
  (
    0x082ff0f7U, "STMDA_UPD Reg:PC Reg:PC Imm:0 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdaeq pc!, {r0, r1, r2, r4, r5, r6, r7, r12, sp, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe82f9b7fU, "STMDA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:PC | stmda pc!, {r0, r1, r2, r3, r4, r5, r6, r8, r9, r11, r12, pc} | affect_cf,may_store",
  ),
  (
    0x382d2000U, "STMDA_UPD Reg:SP Reg:SP Imm:3 Reg:CPSR Reg:SP | stmdalo sp!, {sp} | may_store",
  ),
  (
    0xe8221008U, "STMDA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R3 Reg:R12 | stmda r2!, {r3, r12} | may_store",
  ),
  (
    0x68266002U, "STMDA_UPD Reg:R6 Reg:R6 Imm:6 Reg:CPSR Reg:R1 Reg:SP Reg:LR | stmdavs r6!, {r1, sp, lr} | may_store",
  ),
  (
    0xe827f000U, "STMDA_UPD Reg:R7 Reg:R7 Imm:14 Reg:Nil Reg:R12 Reg:SP Reg:LR Reg:PC | stmda r7!, {r12, sp, lr, pc} | may_store",
  ),
  (
    0xe8242123U, "STMDA_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R5 Reg:R8 Reg:SP | stmda r4!, {r0, r1, r5, r8, sp} | may_store",
  ),
  (
    0x982cf009U, "STMDA_UPD Reg:R12 Reg:R12 Imm:9 Reg:CPSR Reg:R0 Reg:R3 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdals r12!, {r0, r3, r12, sp, lr, pc} | may_store",
  ),
  (
    0x18211e38U, "STMDA_UPD Reg:R1 Reg:R1 Imm:1 Reg:CPSR Reg:R3 Reg:R4 Reg:R5 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | stmdane r1!, {r3, r4, r5, r9, r10, r11, r12} | may_store",
  ),
  (
    0xd825fc0aU, "STMDA_UPD Reg:R5 Reg:R5 Imm:13 Reg:CPSR Reg:R1 Reg:R3 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdale r5!, {r1, r3, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xb82cfd12U, "STMDA_UPD Reg:R12 Reg:R12 Imm:11 Reg:CPSR Reg:R1 Reg:R4 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdalt r12!, {r1, r4, r8, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x2823fa65U, "STMDA_UPD Reg:R3 Reg:R3 Imm:2 Reg:CPSR Reg:R0 Reg:R2 Reg:R5 Reg:R6 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdahs r3!, {r0, r2, r5, r6, r9, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x9821f63dU, "STMDA_UPD Reg:R1 Reg:R1 Imm:9 Reg:CPSR Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdals r1!, {r0, r2, r3, r4, r5, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0x382cfdcbU, "STMDA_UPD Reg:R12 Reg:R12 Imm:3 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdalo r12!, {r0, r1, r3, r6, r7, r8, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xa82cf9feU, "STMDA_UPD Reg:R12 Reg:R12 Imm:10 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdage r12!, {r1, r2, r3, r4, r5, r6, r7, r8, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x790d8000U, "STMDB Reg:SP Imm:7 Reg:CPSR Reg:PC | stmdbvc sp, {pc} | may_store",
  ),
  (
    0xd9078004U, "STMDB Reg:R7 Imm:13 Reg:CPSR Reg:R2 Reg:PC | stmdble r7, {r2, pc} | may_store",
  ),
  (
    0xe904a008U, "STMDB Reg:R4 Imm:14 Reg:Nil Reg:R3 Reg:SP Reg:PC | stmdb r4, {r3, sp, pc} | may_store",
  ),
  (
    0xe90f8043U, "STMDB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R6 Reg:PC | stmdb pc, {r0, r1, r6, pc} | may_store",
  ),
  (
    0xe9046c04U, "STMDB Reg:R4 Imm:14 Reg:Nil Reg:R2 Reg:R10 Reg:R11 Reg:SP Reg:LR | stmdb r4, {r2, r10, r11, sp, lr} | may_store",
  ),
  (
    0xc90bf006U, "STMDB Reg:R11 Imm:12 Reg:CPSR Reg:R1 Reg:R2 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbgt r11, {r1, r2, r12, sp, lr, pc} | may_store",
  ),
  (
    0x0909f409U, "STMDB Reg:R9 Imm:0 Reg:CPSR Reg:R0 Reg:R3 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbeq r9, {r0, r3, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe90fe80fU, "STMDB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R11 Reg:SP Reg:LR Reg:PC | stmdb pc, {r0, r1, r2, r3, r11, sp, lr, pc} | may_store",
  ),
  (
    0xe903f02fU, "STMDB Reg:R3 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdb r3, {r0, r1, r2, r3, r5, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe9056f1eU, "STMDB Reg:R5 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | stmdb r5, {r1, r2, r3, r4, r8, r9, r10, r11, sp, lr} | may_store",
  ),
  (
    0x4903f61fU, "STMDB Reg:R3 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbmi r3, {r0, r1, r2, r3, r4, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0xb907fd3eU, "STMDB Reg:R7 Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdblt r7, {r1, r2, r3, r4, r5, r8, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xb901fff2U, "STMDB Reg:R1 Imm:11 Reg:CPSR Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdblt r1, {r1, r4, r5, r6, r7, r8, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x590cfbbfU, "STMDB Reg:R12 Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbpl r12, {r0, r1, r2, r3, r4, r5, r7, r8, r9, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe92d4800U, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R11 Reg:LR | push {r11, lr} | may_store",
  ),
  (
    0x192d5010U, "STMDB_UPD Reg:SP Reg:SP Imm:1 Reg:CPSR Reg:R4 Reg:R12 Reg:LR | pushne {r4, r12, lr} | may_store",
  ),
  (
    0xe92d4830U, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R11 Reg:LR | push {r4, r5, r11, lr} | may_store",
  ),
  (
    0xb92d0a0eU, "STMDB_UPD Reg:SP Reg:SP Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R9 Reg:R11 | pushlt {r1, r2, r3, r9, r11} | may_store",
  ),
  (
    0xe92d41f0U, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:LR | push {r4, r5, r6, r7, r8, lr} | may_store",
  ),
  (
    0xc92d3d21U, "STMDB_UPD Reg:SP Reg:SP Imm:12 Reg:CPSR Reg:R0 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP | pushgt {r0, r5, r8, r10, r11, r12, sp} | may_store",
  ),
  (
    0xe92d4bf0U, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:LR | push {r4, r5, r6, r7, r8, r9, r11, lr} | may_store",
  ),
  (
    0xe92d4ff0U, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | push {r4, r5, r6, r7, r8, r9, r10, r11, lr} | may_store",
  ),
  (
    0x392d3e3eU, "STMDB_UPD Reg:SP Reg:SP Imm:3 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP | pushlo {r1, r2, r3, r4, r5, r9, r10, r11, r12, sp} | may_store",
  ),
  (
    0xe92d4ffcU, "STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | push {r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, lr} | may_store",
  ),
  (
    0xe92f0030U, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R4 Reg:R5 | stmdb pc!, {r4, r5} | affect_cf,may_store",
  ),
  (
    0xe92f1810U, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R4 Reg:R11 Reg:R12 | stmdb pc!, {r4, r11, r12} | affect_cf,may_store",
  ),
  (
    0xe92f8409U, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R10 Reg:PC | stmdb pc!, {r0, r3, r10, pc} | affect_cf,may_store",
  ),
  (
    0xe92f2321U, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R5 Reg:R8 Reg:R9 Reg:SP | stmdb pc!, {r0, r5, r8, r9, sp} | affect_cf,may_store",
  ),
  (
    0xe92fc14aU, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R6 Reg:R8 Reg:LR Reg:PC | stmdb pc!, {r1, r3, r6, r8, lr, pc} | affect_cf,may_store",
  ),
  (
    0x292f961aU, "STMDB_UPD Reg:PC Reg:PC Imm:2 Reg:CPSR Reg:R1 Reg:R3 Reg:R4 Reg:R9 Reg:R10 Reg:R12 Reg:PC | stmdbhs pc!, {r1, r3, r4, r9, r10, r12, pc} | affect_cf,may_store",
  ),
  (
    0xe92f583dU, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R11 Reg:R12 Reg:LR | stmdb pc!, {r0, r2, r3, r4, r5, r11, r12, lr} | affect_cf,may_store",
  ),
  (
    0xe92ff931U, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R5 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdb pc!, {r0, r4, r5, r8, r11, r12, sp, lr, pc} | affect_cf,may_store",
  ),
  (
    0xc92f735bU, "STMDB_UPD Reg:PC Reg:PC Imm:12 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R12 Reg:SP Reg:LR | stmdbgt pc!, {r0, r1, r3, r4, r6, r8, r9, r12, sp, lr} | affect_cf,may_store",
  ),
  (
    0xe92ff49fU, "STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdb pc!, {r0, r1, r2, r3, r4, r7, r10, r12, sp, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe9262000U, "STMDB_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:SP | stmdb r6!, {sp} | may_store",
  ),
  (
    0xe9210015U, "STMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 | stmdb r1!, {r0, r2, r4} | may_store",
  ),
  (
    0xe9281222U, "STMDB_UPD Reg:R8 Reg:R8 Imm:14 Reg:Nil Reg:R1 Reg:R5 Reg:R9 Reg:R12 | stmdb r8!, {r1, r5, r9, r12} | may_store",
  ),
  (
    0xb929a00eU, "STMDB_UPD Reg:R9 Reg:R9 Imm:11 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:SP Reg:PC | stmdblt r9!, {r1, r2, r3, sp, pc} | may_store",
  ),
  (
    0xe9245c0cU, "STMDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stmdb r4!, {r2, r3, r10, r11, r12, lr} | may_store",
  ),
  (
    0x3922301fU, "STMDB_UPD Reg:R2 Reg:R2 Imm:3 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R12 Reg:SP | stmdblo r2!, {r0, r1, r2, r3, r4, r12, sp} | may_store",
  ),
  (
    0xe921f00fU, "STMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdb r1!, {r0, r1, r2, r3, r12, sp, lr, pc} | may_store",
  ),
  (
    0x0928f50eU, "STMDB_UPD Reg:R8 Reg:R8 Imm:0 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbeq r8!, {r1, r2, r3, r8, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0x2927fa6cU, "STMDB_UPD Reg:R7 Reg:R7 Imm:2 Reg:CPSR Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbhs r7!, {r2, r3, r5, r6, r9, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe920f5abU, "STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdb r0!, {r0, r1, r3, r5, r7, r8, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0x4927f9dbU, "STMDB_UPD Reg:R7 Reg:R7 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmdbmi r7!, {r0, r1, r3, r4, r6, r7, r8, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe8800006U, "STMIA Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R2 | stm r0, {r1, r2} | may_store",
  ),
  (
    0xe88c000eU, "STMIA Reg:R12 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 | stm r12, {r1, r2, r3} | may_store",
  ),
  (
    0xd882f000U, "STMIA Reg:R2 Imm:13 Reg:CPSR Reg:R12 Reg:SP Reg:LR Reg:PC | stmle r2, {r12, sp, lr, pc} | may_store",
  ),
  (
    0xe88e800fU, "STMIA Reg:LR Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:PC | stm lr, {r0, r1, r2, r3, pc} | may_store",
  ),
  (
    0x1888b007U, "STMIA Reg:R8 Imm:1 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R12 Reg:SP Reg:PC | stmne r8, {r0, r1, r2, r12, sp, pc} | may_store",
  ),
  (
    0xe889b50cU, "STMIA Reg:R9 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:PC | stm r9, {r2, r3, r8, r10, r12, sp, pc} | may_store",
  ),
  (
    0xe88feb06U, "STMIA Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R8 Reg:R9 Reg:R11 Reg:SP Reg:LR Reg:PC | stm pc, {r1, r2, r8, r9, r11, sp, lr, pc} | may_store",
  ),
  (
    0x1881f90eU, "STMIA Reg:R1 Imm:1 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R8 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmne r1, {r1, r2, r3, r8, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe88fda5bU, "STMIA Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R9 Reg:R11 Reg:R12 Reg:LR Reg:PC | stm pc, {r0, r1, r3, r4, r6, r9, r11, r12, lr, pc} | may_store",
  ),
  (
    0xe886de3dU, "STMIA Reg:R6 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | stm r6, {r0, r2, r3, r4, r5, r9, r10, r11, r12, lr, pc} | may_store",
  ),
  (
    0x988ffe5eU, "STMIA Reg:PC Imm:9 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmls pc, {r1, r2, r3, r4, r6, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x6881f7dfU, "STMIA Reg:R1 Imm:6 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmvs r1, {r0, r1, r2, r3, r4, r6, r7, r8, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe8af3060U, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R5 Reg:R6 Reg:R12 Reg:SP | stm pc!, {r5, r6, r12, sp} | affect_cf,may_store",
  ),
  (
    0xe8afa884U, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R2 Reg:R7 Reg:R11 Reg:SP Reg:PC | stm pc!, {r2, r7, r11, sp, pc} | affect_cf,may_store",
  ),
  (
    0xe8afa909U, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R8 Reg:R11 Reg:SP Reg:PC | stm pc!, {r0, r3, r8, r11, sp, pc} | affect_cf,may_store",
  ),
  (
    0x28af9516U, "STMIA_UPD Reg:PC Reg:PC Imm:2 Reg:CPSR Reg:R1 Reg:R2 Reg:R4 Reg:R8 Reg:R10 Reg:R12 Reg:PC | stmhs pc!, {r1, r2, r4, r8, r10, r12, pc} | affect_cf,may_store",
  ),
  (
    0xe8af4b5aU, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:LR | stm pc!, {r1, r3, r4, r6, r8, r9, r11, lr} | affect_cf,may_store",
  ),
  (
    0xe8afbc2dU, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:PC | stm pc!, {r0, r2, r3, r5, r10, r11, r12, sp, pc} | affect_cf,may_store",
  ),
  (
    0xe8af696fU, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R11 Reg:SP Reg:LR | stm pc!, {r0, r1, r2, r3, r5, r6, r8, r11, sp, lr} | affect_cf,may_store",
  ),
  (
    0xe8affd4bU, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stm pc!, {r0, r1, r3, r6, r8, r10, r11, r12, sp, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe8afaf7eU, "STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:PC | stm pc!, {r1, r2, r3, r4, r5, r6, r8, r9, r10, r11, sp, pc} | affect_cf,may_store",
  ),
  (
    0x78ad1000U, "STMIA_UPD Reg:SP Reg:SP Imm:7 Reg:CPSR Reg:R12 | stmvc sp!, {r12} | may_store",
  ),
  (
    0xe8a00006U, "STMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R2 | stm r0!, {r1, r2} | may_store",
  ),
  (
    0xe8a1c004U, "STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:LR Reg:PC | stm r1!, {r2, lr, pc} | may_store",
  ),
  (
    0xe8a67020U, "STMIA_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:R5 Reg:R12 Reg:SP Reg:LR | stm r6!, {r5, r12, sp, lr} | may_store",
  ),
  (
    0xe8a06814U, "STMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R11 Reg:SP Reg:LR | stm r0!, {r2, r4, r11, sp, lr} | may_store",
  ),
  (
    0xe8a1f024U, "STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:R5 Reg:R12 Reg:SP Reg:LR Reg:PC | stm r1!, {r2, r5, r12, sp, lr, pc} | may_store",
  ),
  (
    0xc8adf00eU, "STMIA_UPD Reg:SP Reg:SP Imm:12 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R12 Reg:SP Reg:LR Reg:PC | stmgt sp!, {r1, r2, r3, r12, sp, lr, pc} | may_store",
  ),
  (
    0x18a7c70bU, "STMIA_UPD Reg:R7 Reg:R7 Imm:1 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:LR Reg:PC | stmne r7!, {r0, r1, r3, r8, r9, r10, lr, pc} | may_store",
  ),
  (
    0xc8ad7a0fU, "STMIA_UPD Reg:SP Reg:SP Imm:12 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR | stmgt sp!, {r0, r1, r2, r3, r9, r11, r12, sp, lr} | may_store",
  ),
  (
    0x48abf707U, "STMIA_UPD Reg:R11 Reg:R11 Imm:4 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmmi r11!, {r0, r1, r2, r8, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0x38adcf6bU, "STMIA_UPD Reg:SP Reg:SP Imm:3 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR Reg:PC | stmlo sp!, {r0, r1, r3, r5, r6, r8, r9, r10, r11, lr, pc} | may_store",
  ),
  (
    0x88a0fe57U, "STMIA_UPD Reg:R0 Reg:R0 Imm:8 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmhi r0!, {r0, r1, r2, r4, r6, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x58a4f7e7U, "STMIA_UPD Reg:R4 Reg:R4 Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmpl r4!, {r0, r1, r2, r5, r6, r7, r8, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0x798d0010U, "STMIB Reg:SP Imm:7 Reg:CPSR Reg:R4 | stmibvc sp, {r4} | may_store",
  ),
  (
    0xe9800022U, "STMIB Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R5 | stmib r0, {r1, r5} | may_store",
  ),
  (
    0xe98d000eU, "STMIB Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 | stmib sp, {r1, r2, r3} | may_store",
  ),
  (
    0xe98f2304U, "STMIB Reg:PC Imm:14 Reg:Nil Reg:R2 Reg:R8 Reg:R9 Reg:SP | stmib pc, {r2, r8, r9, sp} | may_store",
  ),
  (
    0x598e100fU, "STMIB Reg:LR Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R12 | stmibpl lr, {r0, r1, r2, r3, r12} | may_store",
  ),
  (
    0xe98cd508U, "STMIB Reg:R12 Imm:14 Reg:Nil Reg:R3 Reg:R8 Reg:R10 Reg:R12 Reg:LR Reg:PC | stmib r12, {r3, r8, r10, r12, lr, pc} | may_store",
  ),
  (
    0x598f501fU, "STMIB Reg:PC Imm:5 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R12 Reg:LR | stmibpl pc, {r0, r1, r2, r3, r4, r12, lr} | may_store",
  ),
  (
    0xa98a741eU, "STMIB Reg:R10 Imm:10 Reg:CPSR Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R10 Reg:R12 Reg:SP Reg:LR | stmibge r10, {r1, r2, r3, r4, r10, r12, sp, lr} | may_store",
  ),
  (
    0xa98dff08U, "STMIB Reg:SP Imm:10 Reg:CPSR Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibge sp, {r3, r8, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x698af457U, "STMIB Reg:R10 Imm:6 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R6 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibvs r10, {r0, r1, r2, r4, r6, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0xd98f7f0fU, "STMIB Reg:PC Imm:13 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | stmible pc, {r0, r1, r2, r3, r8, r9, r10, r11, r12, sp, lr} | may_store",
  ),
  (
    0xe98fbeafU, "STMIB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:PC | stmib pc, {r0, r1, r2, r3, r5, r7, r9, r10, r11, r12, sp, pc} | may_store",
  ),
  (
    0x8988feefU, "STMIB Reg:R8 Imm:8 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibhi r8, {r0, r1, r2, r3, r5, r6, r7, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x19af3014U, "STMIB_UPD Reg:PC Reg:PC Imm:1 Reg:CPSR Reg:R2 Reg:R4 Reg:R12 Reg:SP | stmibne pc!, {r2, r4, r12, sp} | affect_cf,may_store",
  ),
  (
    0xe9af7006U, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R12 Reg:SP Reg:LR | stmib pc!, {r1, r2, r12, sp, lr} | affect_cf,may_store",
  ),
  (
    0xe9af7406U, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R10 Reg:R12 Reg:SP Reg:LR | stmib pc!, {r1, r2, r10, r12, sp, lr} | affect_cf,may_store",
  ),
  (
    0xe9afb149U, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R6 Reg:R8 Reg:R12 Reg:SP Reg:PC | stmib pc!, {r0, r3, r6, r8, r12, sp, pc} | affect_cf,may_store",
  ),
  (
    0xe9afe06bU, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R6 Reg:SP Reg:LR Reg:PC | stmib pc!, {r0, r1, r3, r5, r6, sp, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe9afaa5eU, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R9 Reg:R11 Reg:SP Reg:PC | stmib pc!, {r1, r2, r3, r4, r6, r9, r11, sp, pc} | affect_cf,may_store",
  ),
  (
    0xe9af50ffU, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R12 Reg:LR | stmib pc!, {r0, r1, r2, r3, r4, r5, r6, r7, r12, lr} | affect_cf,may_store",
  ),
  (
    0xe9afdfaaU, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | stmib pc!, {r1, r3, r5, r7, r8, r9, r10, r11, r12, lr, pc} | affect_cf,may_store",
  ),
  (
    0xe9af1dffU, "STMIB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 | stmib pc!, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r10, r11, r12} | affect_cf,may_store",
  ),
  (
    0xe9a00010U, "STMIB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R4 | stmib r0!, {r4} | may_store",
  ),
  (
    0xe9ad3000U, "STMIB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R12 Reg:SP | stmib sp!, {r12, sp} | may_store",
  ),
  (
    0xe9abb000U, "STMIB_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:R12 Reg:SP Reg:PC | stmib r11!, {r12, sp, pc} | may_store",
  ),
  (
    0xe9aba404U, "STMIB_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:R2 Reg:R10 Reg:SP Reg:PC | stmib r11!, {r2, r10, sp, pc} | may_store",
  ),
  (
    0xc9a1a805U, "STMIB_UPD Reg:R1 Reg:R1 Imm:12 Reg:CPSR Reg:R0 Reg:R2 Reg:R11 Reg:SP Reg:PC | stmibgt r1!, {r0, r2, r11, sp, pc} | may_store",
  ),
  (
    0x29a5f009U, "STMIB_UPD Reg:R5 Reg:R5 Imm:2 Reg:CPSR Reg:R0 Reg:R3 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibhs r5!, {r0, r3, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe9a82b15U, "STMIB_UPD Reg:R8 Reg:R8 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R8 Reg:R9 Reg:R11 Reg:SP | stmib r8!, {r0, r2, r4, r8, r9, r11, sp} | may_store",
  ),
  (
    0x09adf807U, "STMIB_UPD Reg:SP Reg:SP Imm:0 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibeq sp!, {r0, r1, r2, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe9a2f227U, "STMIB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | stmib r2!, {r0, r1, r2, r5, r9, r12, sp, lr, pc} | may_store",
  ),
  (
    0x79a7f83bU, "STMIB_UPD Reg:R7 Reg:R7 Imm:7 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibvc r7!, {r0, r1, r3, r4, r5, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0x89acfe1bU, "STMIB_UPD Reg:R12 Reg:R12 Imm:8 Reg:CPSR Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibhi r12!, {r0, r1, r3, r4, r9, r10, r11, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe9a9d7afU, "STMIB_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:LR Reg:PC | stmib r9!, {r0, r1, r2, r3, r5, r7, r8, r9, r10, r12, lr, pc} | may_store",
  ),
  (
    0xa9a0f77fU, "STMIB_UPD Reg:R0 Reg:R0 Imm:10 Reg:CPSR Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | stmibge r0!, {r0, r1, r2, r3, r4, r5, r6, r8, r9, r10, r12, sp, lr, pc} | may_store",
  ),
  (
    0xe46fd008U, "STRBT_POST_IMM Reg:PC Reg:SP Reg:PC Reg:Nil Imm:151560 Imm:14 Reg:Nil | strbt sp, [pc], #-8 | affect_cf,may_store",
  ),
  (
    0xe4683705U, "STRBT_POST_IMM Reg:R8 Reg:R3 Reg:R8 Reg:Nil Imm:153349 Imm:14 Reg:Nil | strbt r3, [r8], #-1797 | may_store",
  ),
  (
    0xe66f430eU, "STRBT_POST_REG Reg:PC Reg:R4 Reg:PC Reg:LR Imm:151558 Imm:14 Reg:Nil | strbt r4, [pc], -lr, lsl #6 | affect_cf,may_store",
  ),
  (
    0xe66a6a08U, "STRBT_POST_REG Reg:R10 Reg:R6 Reg:R10 Reg:R8 Imm:151572 Imm:14 Reg:Nil | strbt r6, [r10], -r8, lsl #20 | may_store",
  ),
  (
    0xe44f8504U, "STRB_POST_IMM Reg:PC Reg:R8 Reg:PC Reg:Nil Imm:152836 Imm:14 Reg:Nil | strb r8, [pc], #-1284 | affect_cf,may_store",
  ),
  (
    0xe4c30001U, "STRB_POST_IMM Reg:R3 Reg:R0 Reg:R3 Reg:Nil Imm:147457 Imm:14 Reg:Nil | strb r0, [r3], #1 | may_store",
  ),
  (
    0xe64f2005U, "STRB_POST_REG Reg:PC Reg:R2 Reg:PC Reg:R5 Imm:151552 Imm:14 Reg:Nil | strb r2, [pc], -r5 | affect_cf,may_store",
  ),
  (
    0xa641f208U, "STRB_POST_REG Reg:R1 Reg:PC Reg:R1 Reg:R8 Imm:151556 Imm:10 Reg:CPSR | strbge pc, [r1], -r8, lsl #4 | may_store",
  ),
  (
    0xe56fb901U, "STRB_PRE_IMM Reg:PC Reg:R11 Reg:PC Imm:4294964991 Imm:14 Reg:Nil | strb r11, [pc, #-2305]! | affect_cf,may_store",
  ),
  (
    0xe563bb02U, "STRB_PRE_IMM Reg:R3 Reg:R11 Reg:R3 Imm:4294964478 Imm:14 Reg:Nil | strb r11, [r3, #-2818]! | may_store",
  ),
  (
    0xe76f8a05U, "STRB_PRE_REG Reg:PC Reg:R8 Reg:PC Reg:R5 Imm:20500 Imm:14 Reg:Nil | strb r8, [pc, -r5, lsl #20]! | affect_cf,may_store",
  ),
  (
    0xe76ab600U, "STRB_PRE_REG Reg:R10 Reg:R11 Reg:R10 Reg:R0 Imm:20492 Imm:14 Reg:Nil | strb r11, [r10, -r0, lsl #12]! | may_store",
  ),
  (
    0xe5c10000U, "STRBi12 Reg:R0 Reg:R1 Imm:0 Imm:14 Reg:Nil | strb r0, [r1] | may_store",
  ),
  (
    0xe7c0c001U, "STRBrs Reg:R12 Reg:R0 Reg:R1 Imm:16384 Imm:14 Reg:Nil | strb r12, [r0, r1] | may_store",
  ),
  (
    0xe1c040f0U, "STRD Reg:R4 Reg:R5 Reg:R0 Reg:Nil Imm:0 Imm:14 Reg:Nil | strd r4, r5, [r0] | may_store",
  ),
  (
    0xe00fa4f4U, "STRD_POST Reg:PC Reg:R10 Reg:R11 Reg:PC Reg:R4 Imm:1280 Imm:14 Reg:Nil | strd r10, r11, [pc], -r4 | affect_cf,may_store",
  ),
  (
    0x000000ffU, "STRD_POST Reg:R0 Reg:R0 Reg:R1 Reg:R0 Reg:PC Imm:1280 Imm:0 Reg:CPSR | strdeq r0, r1, [r0], -pc | may_store",
  ),
  (
    0xe12f28f6U, "STRD_PRE Reg:PC Reg:R2 Reg:R3 Reg:PC Reg:R6 Imm:768 Imm:14 Reg:Nil | strd r2, r3, [pc, -r6]! | affect_cf,may_store",
  ),
  (
    0xe121a5f6U, "STRD_PRE Reg:R1 Reg:R10 Reg:R11 Reg:R1 Reg:R6 Imm:768 Imm:14 Reg:Nil | strd r10, r11, [r1, -r6]! | may_store",
  ),
  (
    0xe1803f92U, "STREX Reg:R3 Reg:R2 Reg:R0 Imm:14 Reg:Nil | strex r3, r2, [r0] | may_load,may_store",
  ),
  (
    0xb1a8ff92U, "STREXD Reg:PC Reg:R2_R3 Reg:R8 Imm:11 Reg:CPSR | strexdlt pc, r2, r3, [r8] | affect_cf,may_store",
  ),
  (
    0xe1a15f92U, "STREXD Reg:R5 Reg:R2_R3 Reg:R1 Imm:14 Reg:Nil | strexd r5, r2, r3, [r1] | may_store",
  ),
  (
    0xe1c100b0U, "STRH Reg:R0 Reg:R1 Reg:Nil Imm:0 Imm:14 Reg:Nil | strh r0, [r1] | may_store",
  ),
  (
    0xe06fb8b3U, "STRHTi Reg:PC Reg:R11 Reg:PC Imm:131 Imm:14 Reg:Nil | strht r11, [pc], #-131 | affect_cf,may_store",
  ),
  (
    0xe06277b0U, "STRHTi Reg:R2 Reg:R7 Reg:R2 Imm:112 Imm:14 Reg:Nil | strht r7, [r2], #-112 | may_store",
  ),
  (
    0x202ba0b9U, "STRHTr Reg:R11 Reg:R10 Reg:R11 Reg:R9 Imm:0 Imm:2 Reg:CPSR | strhths r10, [r11], -r9 | may_store",
  ),
  (
    0xe00f9eb7U, "STRH_POST Reg:PC Reg:R9 Reg:PC Reg:R7 Imm:1280 Imm:14 Reg:Nil | strh r9, [pc], -r7 | affect_cf,may_store",
  ),
  (
    0x000000b0U, "STRH_POST Reg:R0 Reg:R0 Reg:R0 Reg:R0 Imm:1280 Imm:0 Reg:CPSR | strheq r0, [r0], -r0 | may_store",
  ),
  (
    0xe12f7ab7U, "STRH_PRE Reg:PC Reg:R7 Reg:PC Reg:R7 Imm:768 Imm:14 Reg:Nil | strh r7, [pc, -r7]! | affect_cf,may_store",
  ),
  (
    0xe12e10bdU, "STRH_PRE Reg:LR Reg:R1 Reg:LR Reg:SP Imm:768 Imm:14 Reg:Nil | strh r1, [lr, -sp]! | may_store",
  ),
  (
    0xe42f7c09U, "STRT_POST_IMM Reg:PC Reg:R7 Reg:PC Reg:Nil Imm:154633 Imm:14 Reg:Nil | strt r7, [pc], #-3081 | affect_cf,may_store",
  ),
  (
    0xe427a402U, "STRT_POST_IMM Reg:R7 Reg:R10 Reg:R7 Reg:Nil Imm:152578 Imm:14 Reg:Nil | strt r10, [r7], #-1026 | may_store",
  ),
  (
    0xe62f6807U, "STRT_POST_REG Reg:PC Reg:R6 Reg:PC Reg:R7 Imm:151568 Imm:14 Reg:Nil | strt r6, [pc], -r7, lsl #16 | affect_cf,may_store",
  ),
  (
    0x1625500fU, "STRT_POST_REG Reg:R5 Reg:R5 Reg:R5 Reg:PC Imm:151552 Imm:1 Reg:CPSR | strtne r5, [r5], -pc | may_store",
  ),
  (
    0xe40f6608U, "STR_POST_IMM Reg:PC Reg:R6 Reg:PC Reg:Nil Imm:153096 Imm:14 Reg:Nil | str r6, [pc], #-1544 | affect_cf,may_store",
  ),
  (
    0xe4802004U, "STR_POST_IMM Reg:R0 Reg:R2 Reg:R0 Reg:Nil Imm:147460 Imm:14 Reg:Nil | str r2, [r0], #4 | may_store",
  ),
  (
    0xe60f4f04U, "STR_POST_REG Reg:PC Reg:R4 Reg:PC Reg:R4 Imm:151582 Imm:14 Reg:Nil | str r4, [pc], -r4, lsl #30 | affect_cf,may_store",
  ),
  (
    0xe6023404U, "STR_POST_REG Reg:R2 Reg:R3 Reg:R2 Reg:R4 Imm:151560 Imm:14 Reg:Nil | str r3, [r2], -r4, lsl #8 | may_store",
  ),
  (
    0xe52f7a04U, "STR_PRE_IMM Reg:PC Reg:R7 Reg:PC Imm:4294964732 Imm:14 Reg:Nil | str r7, [pc, #-2564]! | affect_cf,may_store",
  ),
  (
    0xe523350eU, "STR_PRE_IMM Reg:R3 Reg:R3 Reg:R3 Imm:4294966002 Imm:14 Reg:Nil | str r3, [r3, #-1294]! | may_store",
  ),
  (
    0xe72f2e06U, "STR_PRE_REG Reg:PC Reg:R2 Reg:PC Reg:R6 Imm:20508 Imm:14 Reg:Nil | str r2, [pc, -r6, lsl #28]! | affect_cf,may_store",
  ),
  (
    0xe72dc608U, "STR_PRE_REG Reg:SP Reg:R12 Reg:SP Reg:R8 Imm:20492 Imm:14 Reg:Nil | str r12, [sp, -r8, lsl #12]! | may_store",
  ),
  (
    0xe5810000U, "STRi12 Reg:R0 Reg:R1 Imm:0 Imm:14 Reg:Nil | str r0, [r1] | may_store",
  ),
  (
    0xe7040102U, "STRrs Reg:R0 Reg:R4 Reg:R2 Imm:20482 Imm:14 Reg:Nil | str r0, [r4, -r2, lsl #2] | may_store",
  ),
  (
    0xe2400001U, "SUBri Reg:R0 Reg:R0 Imm:1 Imm:14 Reg:Nil Reg:Nil | sub r0, r0, #1",
  ),
  (
    0x3244ff05U, "SUBri Reg:PC Reg:R4 Imm:3845 Imm:3 Reg:CPSR Reg:Nil | sublo pc, r4, #5, #30 | affect_cf",
  ),
  (
    0xe2500001U, "SUBri Reg:R0 Reg:R0 Imm:1 Imm:14 Reg:Nil Reg:CPSR | subs r0, r0, #1",
  ),
  (
    0xc25cf603U, "SUBri Reg:PC Reg:R12 Imm:1539 Imm:12 Reg:CPSR Reg:CPSR | subsgt pc, r12, #3145728 | affect_cf",
  ),
  (
    0xe0410000U, "SUBrr Reg:R0 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | sub r0, r1, r0",
  ),
  (
    0x4042f002U, "SUBrr Reg:PC Reg:R2 Reg:R2 Imm:4 Reg:CPSR Reg:Nil | submi pc, r2, r2 | affect_cf",
  ),
  (
    0xe0500001U, "SUBrr Reg:R0 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:CPSR | subs r0, r0, r1",
  ),
  (
    0x8057f008U, "SUBrr Reg:PC Reg:R7 Reg:R8 Imm:8 Reg:CPSR Reg:CPSR | subshi pc, r7, r8 | affect_cf",
  ),
  (
    0xe04307a0U, "SUBrsi Reg:R0 Reg:R3 Reg:R0 Imm:123 Imm:14 Reg:Nil Reg:Nil | sub r0, r3, r0, lsr #15",
  ),
  (
    0x504cf20cU, "SUBrsi Reg:PC Reg:R12 Reg:R12 Imm:34 Imm:5 Reg:CPSR Reg:Nil | subpl pc, r12, r12, lsl #4 | affect_cf",
  ),
  (
    0xe0500682U, "SUBrsi Reg:R0 Reg:R0 Reg:R2 Imm:106 Imm:14 Reg:Nil Reg:CPSR | subs r0, r0, r2, lsl #13",
  ),
  (
    0x7052f72cU, "SUBrsi Reg:PC Reg:R2 Reg:R12 Imm:115 Imm:7 Reg:CPSR Reg:CPSR | subsvc pc, r2, r12, lsr #14 | affect_cf",
  ),
  (
    0xe04bab15U, "SUBrsr Reg:R10 Reg:R11 Reg:R5 Reg:R11 Imm:2 Imm:14 Reg:Nil Reg:Nil | sub r10, r11, r5, lsl r11",
  ),
  (
    0xe04bf417U, "SUBrsr Reg:PC Reg:R11 Reg:R7 Reg:R4 Imm:2 Imm:14 Reg:Nil Reg:Nil | sub pc, r11, r7, lsl r4 | affect_cf",
  ),
  (
    0xe0527115U, "SUBrsr Reg:R7 Reg:R2 Reg:R5 Reg:R1 Imm:2 Imm:14 Reg:Nil Reg:CPSR | subs r7, r2, r5, lsl r1",
  ),
  (
    0x5059fe13U, "SUBrsr Reg:PC Reg:R9 Reg:R3 Reg:LR Imm:2 Imm:5 Reg:CPSR Reg:CPSR | subspl pc, r9, r3, lsl lr | affect_cf",
  ),
  (0xef027c0aU, "SVC Imm:162826 Imm:14 Reg:Nil | svc #162826 | call,affect_cf"),
  (0x3f000000U, "SVC Imm:0 Imm:3 Reg:CPSR | svclo #0 | call,affect_cf"),
  (
    0x7102f793U, "SWP Reg:PC Reg:R3 Reg:R2 Imm:7 Reg:CPSR | swpvc pc, r3, [r2] | affect_cf,may_load,may_store",
  ),
  (
    0xe104489eU, "SWP Reg:R4 Reg:LR Reg:R4 Imm:14 Reg:Nil | swp r4, lr, [r4] | may_load,may_store",
  ),
  (
    0x1144fb9bU, "SWPB Reg:PC Reg:R11 Reg:R4 Imm:1 Reg:CPSR | swpbne pc, r11, [r4] | affect_cf,may_load,may_store",
  ),
  (
    0xe1497294U, "SWPB Reg:R7 Reg:R4 Reg:R9 Imm:14 Reg:Nil | swpb r7, r4, [r9] | may_load,may_store",
  ),
  (
    0x56a6a070U, "SXTAB Reg:R10 Reg:R6 Reg:R0 Imm:0 Imm:5 Reg:CPSR | sxtabpl r10, r6, r0",
  ),
  (
    0x46abfb72U, "SXTAB Reg:PC Reg:R11 Reg:R2 Imm:2 Imm:4 Reg:CPSR | sxtabmi pc, r11, r2, ror #16 | affect_cf",
  ),
  (
    0xe6b8487aU, "SXTAH Reg:R4 Reg:R8 Reg:R10 Imm:2 Imm:14 Reg:Nil | sxtah r4, r8, r10, ror #16",
  ),
  (
    0xd6b4f57cU, "SXTAH Reg:PC Reg:R4 Reg:R12 Imm:1 Imm:13 Reg:CPSR | sxtahle pc, r4, r12, ror #8 | affect_cf",
  ),
  (0xe6af0070U, "SXTB Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | sxtb r0, r0"),
  (0xe6bf0070U, "SXTH Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | sxth r0, r0"),
  (0xe337d406U, "TEQri Reg:R7 Imm:1030 Imm:14 Reg:Nil | teq r7, #100663296"),
  (0x33333333U, "TEQri Reg:R3 Imm:819 Imm:3 Reg:CPSR | teqlo r3, #-872415232"),
  (0xe131100cU, "TEQrr Reg:R1 Reg:R12 Imm:14 Reg:Nil | teq r1, r12"),
  (0x213d2001U, "TEQrr Reg:SP Reg:R1 Imm:2 Reg:CPSR | teqhs sp, r1"),
  (
    0xe13b8609U, "TEQrsi Reg:R11 Reg:R9 Imm:98 Imm:14 Reg:Nil | teq r11, r9, lsl #12",
  ),
  (
    0x613afe00U, "TEQrsi Reg:R10 Reg:R0 Imm:226 Imm:6 Reg:CPSR | teqvs r10, r0, lsl #28",
  ),
  (
    0xe1350913U, "TEQrsr Reg:R5 Reg:R3 Reg:R9 Imm:2 Imm:14 Reg:Nil | teq r5, r3, lsl r9",
  ),
  (
    0x113f9015U, "TEQrsr Reg:PC Reg:R5 Reg:R0 Imm:2 Imm:1 Reg:CPSR | teqne pc, r5, lsl r0",
  ),
  (0xe3100001U, "TSTri Reg:R0 Imm:1 Imm:14 Reg:Nil | tst r0, #1"),
  (0xd112f003U, "TSTrr Reg:R2 Reg:R3 Imm:13 Reg:CPSR | tstle r2, r3"),
  (
    0xe1168b0fU, "TSTrsi Reg:R6 Reg:PC Imm:178 Imm:14 Reg:Nil | tst r6, pc, lsl #22",
  ),
  (
    0xe119b11eU, "TSTrsr Reg:R9 Reg:LR Reg:R1 Imm:2 Imm:14 Reg:Nil | tst r9, lr, lsl r1",
  ),
  (
    0xe7e601d0U, "UBFX Reg:R0 Reg:R0 Imm:3 Imm:6 Imm:14 Reg:Nil | ubfx r0, r0, #3, #7",
  ),
  (
    0x27e8f251U, "UBFX Reg:PC Reg:R1 Imm:4 Imm:8 Imm:2 Reg:CPSR | ubfxhs pc, r1, #4, #9 | affect_cf",
  ),
  (
    0xe0b2c891U, "UMLAL Reg:R12 Reg:R2 Reg:R1 Reg:R8 Reg:R12 Reg:R2 Imm:14 Reg:Nil Reg:CPSR | umlals r12, r2, r1, r8",
  ),
  (
    0xe0bf0c9bU, "UMLAL Reg:R0 Reg:PC Reg:R11 Reg:R12 Reg:R0 Reg:PC Imm:14 Reg:Nil Reg:CPSR | umlals r0, pc, r11, r12 | affect_cf",
  ),
  (
    0xe0a32091U, "UMLAL Reg:R2 Reg:R3 Reg:R1 Reg:R0 Reg:R2 Reg:R3 Imm:14 Reg:Nil Reg:Nil | umlal r2, r3, r1, r0",
  ),
  (
    0xe0afbb90U, "UMLAL Reg:R11 Reg:PC Reg:R0 Reg:R11 Reg:R11 Reg:PC Imm:14 Reg:Nil Reg:Nil | umlal r11, pc, r0, r11 | affect_cf",
  ),
  (
    0x50bd409cU, "UMLAL Reg:R4 Reg:SP Reg:R12 Reg:R0 Reg:R4 Reg:SP Imm:5 Reg:CPSR Reg:CPSR | umlalspl r4, sp, r12, r0",
  ),
  (
    0xb0baf392U, "UMLAL Reg:PC Reg:R10 Reg:R2 Reg:R3 Reg:PC Reg:R10 Imm:11 Reg:CPSR Reg:CPSR | umlalslt pc, r10, r2, r3 | affect_cf",
  ),
  (
    0xe09a419cU, "UMULL Reg:R4 Reg:R10 Reg:R12 Reg:R1 Imm:14 Reg:Nil Reg:CPSR | umulls r4, r10, r12, r1",
  ),
  (
    0xe09fa99fU, "UMULL Reg:R10 Reg:PC Reg:PC Reg:R9 Imm:14 Reg:Nil Reg:CPSR | umulls r10, pc, pc, r9 | affect_cf",
  ),
  (
    0xe0830190U, "UMULL Reg:R0 Reg:R3 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | umull r0, r3, r0, r1",
  ),
  (
    0xe08f4a9bU, "UMULL Reg:R4 Reg:PC Reg:R11 Reg:R10 Imm:14 Reg:Nil Reg:Nil | umull r4, pc, r11, r10 | affect_cf",
  ),
  (
    0x30959091U, "UMULL Reg:R9 Reg:R5 Reg:R1 Reg:R0 Imm:3 Reg:CPSR Reg:CPSR | umullslo r9, r5, r1, r0",
  ),
  (
    0x3099f89bU, "UMULL Reg:PC Reg:R9 Reg:R11 Reg:R8 Imm:3 Reg:CPSR Reg:CPSR | umullslo pc, r9, r11, r8 | affect_cf",
  ),
  (
    0xe6e10070U, "UXTAB Reg:R0 Reg:R1 Reg:R0 Imm:0 Imm:14 Reg:Nil | uxtab r0, r1, r0",
  ),
  (
    0x86e5f179U, "UXTAB Reg:PC Reg:R5 Reg:R9 Imm:0 Imm:8 Reg:CPSR | uxtabhi pc, r5, r9 | affect_cf",
  ),
  (
    0xe6f4187bU, "UXTAH Reg:R1 Reg:R4 Reg:R11 Imm:2 Imm:14 Reg:Nil | uxtah r1, r4, r11, ror #16",
  ),
  (
    0x06f0fe7dU, "UXTAH Reg:PC Reg:R0 Reg:SP Imm:3 Imm:0 Reg:CPSR | uxtaheq pc, r0, sp, ror #24 | affect_cf",
  ),
  (0xe6ef4576U, "UXTB Reg:R4 Reg:R6 Imm:1 Imm:14 Reg:Nil | uxtb r4, r6, ror #8"),
  (0xe6ff0070U, "UXTH Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | uxth r0, r0"),
]

///|
/// `NAME op op | assembly | kinds`, in the format of the samples (the
/// kinds as LLVM's `MCInstrDesc` names them, omitted when there are none).
fn render_llvm(insn : @mc.Insn) -> String {
  let ops = insn.ops
    .iter()
    .map(op => {
      match op {
        Reg(name~, ..) => "Reg:" + name
        Imm(v) => "Imm:" + v.to_string()
        Fmm(v) => "Fmm:" + v.to_string()
      }
    })
    .collect()
  let kinds = insn.kinds
    .iter()
    .map(kind => {
      match kind {
        ConditionalBranch => "cond"
        UnconditionalBranch => "uncond"
        IndirectBranch => "indirect"
        Return => "return"
        Call => "call"
        Barrier => "barrier"
        Terminator => "terminator"
        MayAffectControlFlow => "affect_cf"
        MayLoad => "may_load"
        MayStore => "may_store"
      }
    })
    .collect()
  let head = if ops.is_empty() {
    insn.name
  } else {
    "\{insn.name} \{ops.join(" ")}"
  }
  let tail = if kinds.is_empty() { "" } else { " | " + kinds.join(",") }
  "\{head} | \{insn.assembly}\{tail}"
}

///|
test "decode: every sample decodes like llvm-mc, in both byte orders" {
  let names : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (word, expected) = sample
    guard @arm.decode_a32_word(word, addr=0x1000UL) is Some(insn) else {
      fail("0x\{word.to_string(radix=16)}: not decoded, expected \{expected}")
    }
    assert_eq(render_llvm(insn), expected)
    assert_eq(insn.size, 4)
    let be : Bytes = [
      (word >> 24).to_byte(),
      (word >> 16).to_byte(),
      (word >> 8).to_byte(),
      word.to_byte(),
    ]
    guard @arm.decode_a32(be, addr=0x1000UL, big_endian=true)
      is Decoded(insn_be) else {
      fail("0x\{word.to_string(radix=16)}: not decoded (big endian)")
    }
    assert_eq(render_llvm(insn_be), expected)
    names[insn.name] = ()
  }
  // the number of samples and of distinct LLVM opcodes they cover
  inspect(llvm_samples.length(), content="809")
  inspect(names.length(), content="210")
}
