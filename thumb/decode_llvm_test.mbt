// Per-opcode decoding tests of the native T32 decoder. Every expected
// line (the LLVM opcode name, the operands, the assembly and the kinds) is
// the output of LLVM 22's disassembler for the instruction outside of an
// IT block (`llvm-mc -disassemble -show-inst -triple=thumbv7-linux-gnueabi
// -mattr=+hwdiv`, the kinds from the opcode's `MCInstrDesc`, as upstream
// BAP reads them). `Reg:Nil` is LLVM's `NoRegister`. A sample is the size
// and the instruction as halfwords (the first one in the high bits of a
// 32-bit instruction). The samples were selected from every 16-bit
// encoding and from random 32-bit encodings on which the decoder and LLVM
// agree.

///|
let llvm_samples : Array[(Int, UInt, String)] = [
  (
    4, 0xf1406400U, "t2ADCri Reg:R4 Reg:R0 Imm:134217728 Imm:14 Reg:Nil Reg:Nil | adc r4, r0, #134217728",
  ),
  (
    4, 0xf1404f00U, "t2ADCri Reg:PC Reg:R0 Imm:2147483648 Imm:14 Reg:Nil Reg:Nil | adc pc, r0, #2147483648 | affect_cf",
  ),
  (
    4, 0xf15000acU, "t2ADCri Reg:R0 Reg:R0 Imm:172 Imm:14 Reg:Nil Reg:CPSR | adcs r0, r0, #172",
  ),
  (
    4, 0xf1501f86U, "t2ADCri Reg:PC Reg:R0 Imm:8781958 Imm:14 Reg:Nil Reg:CPSR | adcs pc, r0, #8781958 | affect_cf",
  ),
  (
    4, 0xeb448b01U, "t2ADCrr Reg:R11 Reg:R4 Reg:R1 Imm:14 Reg:Nil Reg:Nil | adc.w r11, r4, r1",
  ),
  (
    4, 0xeb588d00U, "t2ADCrr Reg:SP Reg:R8 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | adcs.w sp, r8, r0",
  ),
  (
    4, 0xeb403a78U, "t2ADCrs Reg:R10 Reg:R0 Reg:R8 Imm:108 Imm:14 Reg:Nil Reg:Nil | adc.w r10, r0, r8, ror #13",
  ),
  (
    4, 0xeb40dfc1U, "t2ADCrs Reg:PC Reg:R0 Reg:R1 Imm:186 Imm:14 Reg:Nil Reg:Nil | adc.w pc, r0, r1, lsl #23 | affect_cf",
  ),
  (
    4, 0xeb505886U, "t2ADCrs Reg:R8 Reg:R0 Reg:R6 Imm:178 Imm:14 Reg:Nil Reg:CPSR | adcs.w r8, r0, r6, lsl #22",
  ),
  (
    4, 0xeb50bfe6U, "t2ADCrs Reg:PC Reg:R0 Reg:R6 Imm:121 Imm:14 Reg:Nil Reg:CPSR | adcs.w pc, r0, r6, asr #15 | affect_cf",
  ),
  (
    4, 0xf100594bU, "t2ADDri Reg:R9 Reg:R0 Imm:851443712 Imm:14 Reg:Nil Reg:Nil | add.w r9, r0, #851443712",
  ),
  (
    4, 0xf1002f01U, "t2ADDri Reg:PC Reg:R0 Imm:16777472 Imm:14 Reg:Nil Reg:Nil | add.w pc, r0, #16777472 | affect_cf",
  ),
  (
    4, 0xf110197fU, "t2ADDri Reg:R9 Reg:R0 Imm:8323199 Imm:14 Reg:Nil Reg:CPSR | adds.w r9, r0, #8323199",
  ),
  (
    4, 0xf2002016U, "t2ADDri12 Reg:R0 Reg:R0 Imm:534 Imm:14 Reg:Nil | addw r0, r0, #534",
  ),
  (
    4, 0xf2000f05U, "t2ADDri12 Reg:PC Reg:R0 Imm:5 Imm:14 Reg:Nil | addw pc, r0, #5 | affect_cf",
  ),
  (
    4, 0xeb028200U, "t2ADDrr Reg:R2 Reg:R2 Reg:R0 Imm:14 Reg:Nil Reg:Nil | add.w r2, r2, r0",
  ),
  (
    4, 0xeb188100U, "t2ADDrr Reg:R1 Reg:R8 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | adds.w r1, r8, r0",
  ),
  (
    4, 0xeb000d4eU, "t2ADDrs Reg:SP Reg:R0 Reg:LR Imm:10 Imm:14 Reg:Nil Reg:Nil | add.w sp, r0, lr, lsl #1",
  ),
  (
    4, 0xeb007f89U, "t2ADDrs Reg:PC Reg:R0 Reg:R9 Imm:242 Imm:14 Reg:Nil Reg:Nil | add.w pc, r0, r9, lsl #30 | affect_cf",
  ),
  (
    4, 0xeb103547U, "t2ADDrs Reg:R5 Reg:R0 Reg:R7 Imm:106 Imm:14 Reg:Nil Reg:CPSR | adds.w r5, r0, r7, lsl #13",
  ),
  (
    4, 0xf10d0d04U, "t2ADDspImm Reg:SP Reg:SP Imm:4 Imm:14 Reg:Nil Reg:Nil | add.w sp, sp, #4",
  ),
  (
    4, 0xf11d1d00U, "t2ADDspImm Reg:SP Reg:SP Imm:0 Imm:14 Reg:Nil Reg:CPSR | adds.w sp, sp, #0",
  ),
  (4, 0xf20f6489U, "t2ADR Reg:R4 Imm:1673 Imm:14 Reg:Nil | adr.w r4, #1673"),
  (
    4, 0xf20f5ff2U, "t2ADR Reg:PC Imm:1522 Imm:14 Reg:Nil | adr.w pc, #1522 | affect_cf",
  ),
  (
    4, 0xf00053efU, "t2ANDri Reg:R3 Reg:R0 Imm:501219328 Imm:14 Reg:Nil Reg:Nil | and r3, r0, #501219328",
  ),
  (
    4, 0xf0006f24U, "t2ANDri Reg:PC Reg:R0 Imm:171966464 Imm:14 Reg:Nil Reg:Nil | and pc, r0, #171966464 | affect_cf",
  ),
  (
    4, 0xf0106b3bU, "t2ANDri Reg:R11 Reg:R0 Imm:196083712 Imm:14 Reg:Nil Reg:CPSR | ands r11, r0, #196083712",
  ),
  (
    4, 0xea048a00U, "t2ANDrr Reg:R10 Reg:R4 Reg:R0 Imm:14 Reg:Nil Reg:Nil | and.w r10, r4, r0",
  ),
  (
    4, 0xea108001U, "t2ANDrr Reg:R0 Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:CPSR | ands.w r0, r0, r1",
  ),
  (
    4, 0xea006870U, "t2ANDrs Reg:R8 Reg:R0 Reg:R0 Imm:204 Imm:14 Reg:Nil Reg:Nil | and.w r8, r0, r0, ror #25",
  ),
  (
    4, 0xea00cf3cU, "t2ANDrs Reg:PC Reg:R0 Reg:R12 Imm:132 Imm:14 Reg:Nil Reg:Nil | and.w pc, r0, r12, ror #16 | affect_cf",
  ),
  (
    4, 0xea100912U, "t2ANDrs Reg:R9 Reg:R0 Reg:R2 Imm:3 Imm:14 Reg:Nil Reg:CPSR | ands.w r9, r0, r2, lsr #32",
  ),
  (
    4, 0xea4f3021U, "t2ASRri Reg:R0 Reg:R1 Imm:12 Imm:14 Reg:Nil Reg:Nil | asr.w r0, r1, #12",
  ),
  (
    4, 0xfa40fa00U, "t2ASRrr Reg:R10 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | asr.w r10, r0, r0",
  ),
  (
    4, 0xfa50f600U, "t2ASRrr Reg:R6 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | asrs.w r6, r0, r0",
  ),
  (
    4, 0xfa53ff00U, "t2ASRrr Reg:PC Reg:R3 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | asrs.w pc, r3, r0 | affect_cf",
  ),
  (
    4, 0xf0019a00U, "t2B Imm:8393728 Imm:14 Reg:Nil | b.w #8393728 | uncond,barrier,terminator,affect_cf",
  ),
  (4, 0xf36f0e9fU, "t2BFC Reg:LR Reg:LR Imm:3 Imm:14 Reg:Nil | bfc lr, #2, #30"),
  (
    4, 0xf3606800U, "t2BFI Reg:R8 Reg:R8 Reg:R0 Imm:4294967294 Imm:14 Reg:Nil | bfi r8, r0, #0, #1",
  ),
  (
    4, 0xf3602f94U, "t2BFI Reg:PC Reg:PC Reg:R0 Imm:4292871167 Imm:14 Reg:Nil | bfi pc, r0, #10, #11 | affect_cf",
  ),
  (
    4, 0xf0206e00U, "t2BICri Reg:LR Reg:R0 Imm:134217728 Imm:14 Reg:Nil Reg:Nil | bic lr, r0, #134217728",
  ),
  (
    4, 0xf0207f4cU, "t2BICri Reg:PC Reg:R0 Imm:53477376 Imm:14 Reg:Nil Reg:Nil | bic pc, r0, #53477376 | affect_cf",
  ),
  (
    4, 0xf03053f7U, "t2BICri Reg:R3 Reg:R0 Imm:517996544 Imm:14 Reg:Nil Reg:CPSR | bics r3, r0, #517996544",
  ),
  (
    4, 0xf0300f40U, "t2BICri Reg:PC Reg:R0 Imm:64 Imm:14 Reg:Nil Reg:CPSR | bics pc, r0, #64 | affect_cf",
  ),
  (
    4, 0xea260500U, "t2BICrr Reg:R5 Reg:R6 Reg:R0 Imm:14 Reg:Nil Reg:Nil | bic.w r5, r6, r0",
  ),
  (
    4, 0xea308a00U, "t2BICrr Reg:R10 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | bics.w r10, r0, r0",
  ),
  (
    4, 0xea308f00U, "t2BICrr Reg:PC Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | bics.w pc, r0, r0 | affect_cf",
  ),
  (
    4, 0xea20084cU, "t2BICrs Reg:R8 Reg:R0 Reg:R12 Imm:10 Imm:14 Reg:Nil Reg:Nil | bic.w r8, r0, r12, lsl #1",
  ),
  (
    4, 0xea203f7bU, "t2BICrs Reg:PC Reg:R0 Reg:R11 Imm:108 Imm:14 Reg:Nil Reg:Nil | bic.w pc, r0, r11, ror #13 | affect_cf",
  ),
  (
    4, 0xea301a11U, "t2BICrs Reg:R10 Reg:R0 Reg:R1 Imm:35 Imm:14 Reg:Nil Reg:CPSR | bics.w r10, r0, r1, lsr #4",
  ),
  (
    4, 0xea30cfb9U, "t2BICrs Reg:PC Reg:R0 Reg:R9 Imm:148 Imm:14 Reg:Nil Reg:CPSR | bics.w pc, r0, r9, ror #18 | affect_cf",
  ),
  (
    4, 0xf000841bU, "t2Bcc Imm:2102 Imm:0 Reg:CPSR | beq.w #2102 | cond,terminator,affect_cf",
  ),
  (
    4, 0xf1103f1eU, "t2CMNri Reg:R0 Imm:505290270 Imm:14 Reg:Nil | cmn.w r0, #505290270",
  ),
  (4, 0xeb130f00U, "t2CMNzrr Reg:R3 Reg:R0 Imm:14 Reg:Nil | cmn.w r3, r0"),
  (
    4, 0xeb10af3dU, "t2CMNzrs Reg:R0 Reg:SP Imm:68 Imm:14 Reg:Nil | cmn.w r0, sp, ror #8",
  ),
  (
    4, 0xf1b06f67U, "t2CMPri Reg:R0 Imm:242221056 Imm:14 Reg:Nil | cmp.w r0, #242221056",
  ),
  (4, 0xebb00f01U, "t2CMPrr Reg:R0 Reg:R1 Imm:14 Reg:Nil | cmp.w r0, r1"),
  (
    4, 0xebb01fc8U, "t2CMPrs Reg:R0 Reg:R8 Imm:58 Imm:14 Reg:Nil | cmp.w r0, r8, lsl #7",
  ),
  (4, 0xf3bf8f5fU, "t2DMB Imm:15 Imm:14 Reg:Nil | dmb sy | may_load,may_store"),
  (4, 0xf3bf8f4fU, "t2DSB Imm:15 Imm:14 Reg:Nil | dsb sy | may_load,may_store"),
  (
    4, 0xf0804c00U, "t2EORri Reg:R12 Reg:R0 Imm:2147483648 Imm:14 Reg:Nil Reg:Nil | eor r12, r0, #2147483648",
  ),
  (
    4, 0xf0812faeU, "t2EORri Reg:PC Reg:R1 Imm:2919280128 Imm:14 Reg:Nil Reg:Nil | eor pc, r1, #2919280128 | affect_cf",
  ),
  (
    4, 0xf0904061U, "t2EORri Reg:R0 Reg:R0 Imm:3774873600 Imm:14 Reg:Nil Reg:CPSR | eors r0, r0, #3774873600",
  ),
  (
    4, 0xea818600U, "t2EORrr Reg:R6 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | eor.w r6, r1, r0",
  ),
  (
    4, 0xea900700U, "t2EORrr Reg:R7 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | eors.w r7, r0, r0",
  ),
  (
    4, 0xea800e52U, "t2EORrs Reg:LR Reg:R0 Reg:R2 Imm:11 Imm:14 Reg:Nil Reg:Nil | eor.w lr, r0, r2, lsr #1",
  ),
  (
    4, 0xea802fc6U, "t2EORrs Reg:PC Reg:R0 Reg:R6 Imm:90 Imm:14 Reg:Nil Reg:Nil | eor.w pc, r0, r6, lsl #11 | affect_cf",
  ),
  (
    4, 0xea906500U, "t2EORrs Reg:R5 Reg:R0 Reg:R0 Imm:194 Imm:14 Reg:Nil Reg:CPSR | eors.w r5, r0, r0, lsl #24",
  ),
  (
    4, 0xf3af8005U, "t2HINT Imm:5 Imm:14 Reg:Nil | hint.w #5 | may_load,may_store",
  ),
  (4, 0xf3af8000U, "t2HINT Imm:0 Imm:14 Reg:Nil | nop.w | may_load,may_store"),
  (4, 0xf3af8001U, "t2HINT Imm:1 Imm:14 Reg:Nil | yield.w | may_load,may_store"),
  (4, 0xf3bf8f6fU, "t2ISB Imm:15 Imm:14 Reg:Nil | isb sy | may_load,may_store"),
  (2, 0xbf08U, "t2IT Imm:0 Imm:8 | it eq"),
  (2, 0xbf0cU, "t2IT Imm:0 Imm:12 | ite eq"),
  (2, 0xbf0eU, "t2IT Imm:0 Imm:14 | itee eq"),
  (2, 0xbf0fU, "t2IT Imm:0 Imm:15 | iteee eq"),
  (2, 0xbf0dU, "t2IT Imm:0 Imm:13 | iteet eq"),
  (2, 0xbf0aU, "t2IT Imm:0 Imm:10 | itet eq"),
  (2, 0xbf0bU, "t2IT Imm:0 Imm:11 | itete eq"),
  (2, 0xbf09U, "t2IT Imm:0 Imm:9 | itett eq"),
  (2, 0xbf04U, "t2IT Imm:0 Imm:4 | itt eq"),
  (2, 0xbf06U, "t2IT Imm:0 Imm:6 | itte eq"),
  (2, 0xbf07U, "t2IT Imm:0 Imm:7 | ittee eq"),
  (2, 0xbf05U, "t2IT Imm:0 Imm:5 | ittet eq"),
  (2, 0xbf02U, "t2IT Imm:0 Imm:2 | ittt eq"),
  (2, 0xbf03U, "t2IT Imm:0 Imm:3 | ittte eq"),
  (2, 0xbf01U, "t2IT Imm:0 Imm:1 | itttt eq"),
  (
    4, 0xe9198000U, "t2LDMDB Reg:R9 Imm:14 Reg:Nil Reg:PC | ldmdb r9, {pc} | affect_cf,may_load",
  ),
  (
    4, 0xe9168400U, "t2LDMDB Reg:R6 Imm:14 Reg:Nil Reg:R10 Reg:PC | ldmdb r6, {r10, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe9108600U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:R10 Reg:PC | ldmdb r0, {r9, r10, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe9109280U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R7 Reg:R9 Reg:R12 Reg:PC | ldmdb r0, {r7, r9, r12, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910dc00U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldmdb r0, {r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910c078U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:LR Reg:PC | ldmdb r0, {r3, r4, r5, r6, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910fd00U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0, {r8, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910ff00U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0, {r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe912e693U, "t2LDMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R4 Reg:R7 Reg:R9 Reg:R10 Reg:SP Reg:LR Reg:PC | ldmdb r2, {r0, r1, r4, r7, r9, r10, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe911fc65U, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R5 Reg:R6 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r1, {r0, r2, r5, r6, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe911ef27U, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR Reg:PC | ldmdb r1, {r0, r1, r2, r5, r8, r9, r10, r11, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910ff9cU, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0, {r2, r3, r4, r7, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe911fef3U, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r1, {r0, r1, r4, r5, r6, r7, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe910f3ffU, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe91a0200U, "t2LDMDB Reg:R10 Imm:14 Reg:Nil Reg:R9 | ldmdb r10, {r9} | may_load",
  ),
  (
    4, 0xe9134200U, "t2LDMDB Reg:R3 Imm:14 Reg:Nil Reg:R9 Reg:LR | ldmdb r3, {r9, lr} | may_load",
  ),
  (
    4, 0xe9101014U, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R12 | ldmdb r0, {r2, r4, r12} | may_load",
  ),
  (
    4, 0xe9114700U, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R8 Reg:R9 Reg:R10 Reg:LR | ldmdb r1, {r8, r9, r10, lr} | may_load",
  ),
  (
    4, 0xe9117044U, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:R6 Reg:R12 Reg:SP Reg:LR | ldmdb r1, {r2, r6, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe910528cU, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R7 Reg:R9 Reg:R12 Reg:LR | ldmdb r0, {r2, r3, r7, r9, r12, lr} | may_load",
  ),
  (
    4, 0xe9125685U, "t2LDMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R7 Reg:R9 Reg:R10 Reg:R12 Reg:LR | ldmdb r2, {r0, r2, r7, r9, r10, r12, lr} | may_load",
  ),
  (
    4, 0xe91020fbU, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:SP | ldmdb r0, {r0, r1, r3, r4, r5, r6, r7, sp} | may_load",
  ),
  (
    4, 0xe9124f8dU, "t2LDMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | ldmdb r2, {r0, r2, r3, r7, r8, r9, r10, r11, lr} | may_load",
  ),
  (
    4, 0xe9103c9fU, "t2LDMDB Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R10 Reg:R11 Reg:R12 Reg:SP | ldmdb r0, {r0, r1, r2, r3, r4, r7, r10, r11, r12, sp} | may_load",
  ),
  (
    4, 0xe9116f6bU, "t2LDMDB Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldmdb r1, {r0, r1, r3, r5, r6, r8, r9, r10, r11, sp, lr} | may_load",
  ),
  (
    4, 0xe91f5ff3U, "t2LDMDB Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR | ldmdb pc, {r0, r1, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr} | may_load",
  ),
  (
    4, 0xe93f4100U, "t2LDMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R8 Reg:LR | ldmdb pc!, {r8, lr} | affect_cf,may_load",
  ),
  (
    4, 0xe93880a0U, "t2LDMDB_UPD Reg:R8 Reg:R8 Imm:14 Reg:Nil Reg:R5 Reg:R7 Reg:PC | ldmdb r8!, {r5, r7, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe931e400U, "t2LDMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R10 Reg:SP Reg:LR Reg:PC | ldmdb r1!, {r10, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe9308027U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:PC | ldmdb r0!, {r0, r1, r2, r5, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe930c988U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R3 Reg:R7 Reg:R8 Reg:R11 Reg:LR Reg:PC | ldmdb r0!, {r3, r7, r8, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe932d0e4U, "t2LDMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R2 Reg:R5 Reg:R6 Reg:R7 Reg:R12 Reg:LR Reg:PC | ldmdb r2!, {r2, r5, r6, r7, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe930f708U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R3 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0!, {r3, r8, r9, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe932f54cU, "t2LDMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r2!, {r2, r3, r6, r8, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe935df4cU, "t2LDMDB_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldmdb r5!, {r2, r3, r6, r8, r9, r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe930f2e7U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r0!, {r0, r1, r2, r5, r6, r7, r9, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe930bf4fU, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:PC | ldmdb r0!, {r0, r1, r2, r3, r6, r8, r9, r10, r11, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe932f5feU, "t2LDMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R12 Reg:SP Reg:LR Reg:PC | ldmdb r2!, {r1, r2, r3, r4, r5, r6, r7, r8, r10, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe9302200U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:SP | ldmdb r0!, {r9, sp} | may_load",
  ),
  (
    4, 0xe9300083U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R7 | ldmdb r0!, {r0, r1, r7} | may_load",
  ),
  (
    4, 0xe9357100U, "t2LDMDB_UPD Reg:R5 Reg:R5 Imm:14 Reg:Nil Reg:R8 Reg:R12 Reg:SP Reg:LR | ldmdb r5!, {r8, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe931406cU, "t2LDMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:LR | ldmdb r1!, {r2, r3, r5, r6, lr} | may_load",
  ),
  (
    4, 0xe9321c91U, "t2LDMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R7 Reg:R10 Reg:R11 Reg:R12 | ldmdb r2!, {r0, r4, r7, r10, r11, r12} | may_load",
  ),
  (
    4, 0xe93010edU, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R12 | ldmdb r0!, {r0, r2, r3, r5, r6, r7, r12} | may_load",
  ),
  (
    4, 0xe931172dU, "t2LDMDB_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R8 Reg:R9 Reg:R10 Reg:R12 | ldmdb r1!, {r0, r2, r3, r5, r8, r9, r10, r12} | may_load",
  ),
  (
    4, 0xe9334f74U, "t2LDMDB_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | ldmdb r3!, {r2, r4, r5, r6, r8, r9, r10, r11, lr} | may_load",
  ),
  (
    4, 0xe9306babU, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:SP Reg:LR | ldmdb r0!, {r0, r1, r3, r5, r7, r8, r9, r11, sp, lr} | may_load",
  ),
  (
    4, 0xe93077b5U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP Reg:LR | ldmdb r0!, {r0, r2, r4, r5, r7, r8, r9, r10, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe9307ff2U, "t2LDMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldmdb r0!, {r1, r4, r5, r6, r7, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8918000U, "t2LDMIA Reg:R1 Imm:14 Reg:Nil Reg:PC | ldm.w r1, {pc} | affect_cf,may_load",
  ),
  (
    4, 0xe89b9000U, "t2LDMIA Reg:R11 Imm:14 Reg:Nil Reg:R12 Reg:PC | ldm.w r11, {r12, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8968500U, "t2LDMIA Reg:R6 Imm:14 Reg:Nil Reg:R8 Reg:R10 Reg:PC | ldm.w r6, {r8, r10, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890b800U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R11 Reg:R12 Reg:SP Reg:PC | ldm.w r0, {r11, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890d012U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:R12 Reg:LR Reg:PC | ldm.w r0, {r1, r4, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890db00U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldm.w r0, {r8, r9, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890fe00U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r0, {r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890b8a9U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R5 Reg:R7 Reg:R11 Reg:R12 Reg:SP Reg:PC | ldm.w r0, {r0, r3, r5, r7, r11, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890b0edU, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:PC | ldm.w r0, {r0, r2, r3, r5, r6, r7, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890db87U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldm.w r0, {r0, r1, r2, r7, r8, r9, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe891ed9dU, "t2LDMIA Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:SP Reg:LR Reg:PC | ldm.w r1, {r0, r2, r3, r4, r7, r8, r10, r11, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe890fecdU, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r0, {r0, r2, r3, r6, r7, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8949ffeU, "t2LDMIA Reg:R4 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:PC | ldm.w r4, {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe89bfff5U, "t2LDMIA Reg:R11 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r11, {r0, r2, r4, r5, r6, r7, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8960400U, "t2LDMIA Reg:R6 Imm:14 Reg:Nil Reg:R10 | ldm.w r6, {r10} | may_load",
  ),
  (
    4, 0xe8934800U, "t2LDMIA Reg:R3 Imm:14 Reg:Nil Reg:R11 Reg:LR | ldm.w r3, {r11, lr} | may_load",
  ),
  (
    4, 0xe8900054U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R6 | ldm.w r0, {r2, r4, r6} | may_load",
  ),
  (
    4, 0xe8907200U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:R12 Reg:SP Reg:LR | ldm.w r0, {r9, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8912f00U, "t2LDMIA Reg:R1 Imm:14 Reg:Nil Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP | ldm.w r1, {r8, r9, r10, r11, sp} | may_load",
  ),
  (
    4, 0xe89031a4U, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R5 Reg:R7 Reg:R8 Reg:R12 Reg:SP | ldm.w r0, {r2, r5, r7, r8, r12, sp} | may_load",
  ),
  (
    4, 0xe8913750U, "t2LDMIA Reg:R1 Imm:14 Reg:Nil Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:SP | ldm.w r1, {r4, r6, r8, r9, r10, r12, sp} | may_load",
  ),
  (
    4, 0xe89270aeU, "t2LDMIA Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R7 Reg:R12 Reg:SP Reg:LR | ldm.w r2, {r1, r2, r3, r5, r7, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8920f97U, "t2LDMIA Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 | ldm.w r2, {r0, r1, r2, r4, r7, r8, r9, r10, r11} | may_load",
  ),
  (
    4, 0xe8903f1dU, "t2LDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP | ldm.w r0, {r0, r2, r3, r4, r8, r9, r10, r11, r12, sp} | may_load",
  ),
  (
    4, 0xe8916fabU, "t2LDMIA Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldm.w r1, {r0, r1, r3, r5, r7, r8, r9, r10, r11, sp, lr} | may_load",
  ),
  (
    4, 0xe8967d7bU, "t2LDMIA Reg:R6 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldm.w r6, {r0, r1, r3, r4, r5, r6, r8, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe89c6ff7U, "t2LDMIA Reg:R12 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:SP Reg:LR | ldm.w r12, {r0, r1, r2, r4, r5, r6, r7, r8, r9, r10, r11, sp, lr} | may_load",
  ),
  (
    4, 0xe8993fffU, "t2LDMIA Reg:R9 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP | ldm.w r9, {r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, sp} | may_load",
  ),
  (
    4, 0xe8b38200U, "t2LDMIA_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R9 Reg:PC | ldm.w r3!, {r9, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b9c400U, "t2LDMIA_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R10 Reg:LR Reg:PC | ldm.w r9!, {r10, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b1d100U, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R8 Reg:R12 Reg:LR Reg:PC | ldm.w r1!, {r8, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b0b060U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R5 Reg:R6 Reg:R12 Reg:SP Reg:PC | ldm.w r0!, {r5, r6, r12, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b1902eU, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R12 Reg:PC | ldm.w r1!, {r1, r2, r3, r5, r12, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b1cd42U, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R1 Reg:R6 Reg:R8 Reg:R10 Reg:R11 Reg:LR Reg:PC | ldm.w r1!, {r1, r6, r8, r10, r11, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b0a0dbU, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:SP Reg:PC | ldm.w r0!, {r0, r1, r3, r4, r6, r7, sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b1f0d5U, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r1!, {r0, r2, r4, r6, r7, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b3dabaU, "t2LDMIA_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R7 Reg:R9 Reg:R11 Reg:R12 Reg:LR Reg:PC | ldm.w r3!, {r1, r3, r4, r5, r7, r9, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b0ff1aU, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r0!, {r1, r3, r4, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b0fe79U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r0!, {r0, r3, r4, r5, r6, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b6fef9U, "t2LDMIA_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:R0 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r6!, {r0, r3, r4, r5, r6, r7, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b6ff7bU, "t2LDMIA_UPD Reg:R6 Reg:R6 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR Reg:PC | ldm.w r6!, {r0, r1, r3, r4, r5, r6, r8, r9, r10, r11, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8b00500U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R8 Reg:R10 | ldm.w r0!, {r8, r10} | may_load",
  ),
  (
    4, 0xe8b00e00U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:R10 Reg:R11 | ldm.w r0!, {r9, r10, r11} | may_load",
  ),
  (
    4, 0xe8b14015U, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:LR | ldm.w r1!, {r0, r2, r4, lr} | may_load",
  ),
  (
    4, 0xe8b07a00U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldm.w r0!, {r9, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8b20b38U, "t2LDMIA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R9 Reg:R11 | ldm.w r2!, {r3, r4, r5, r8, r9, r11} | may_load",
  ),
  (
    4, 0xe8b0703aU, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R12 Reg:SP Reg:LR | ldm.w r0!, {r1, r3, r4, r5, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8b002f7U, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 | ldm.w r0!, {r0, r1, r2, r4, r5, r6, r7, r9} | may_load",
  ),
  (
    4, 0xe8b04bdcU, "t2LDMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R11 Reg:LR | ldm.w r0!, {r2, r3, r4, r6, r7, r8, r9, r11, lr} | may_load",
  ),
  (
    4, 0xe8b170feU, "t2LDMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:LR | ldm.w r1!, {r1, r2, r3, r4, r5, r6, r7, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8b457e7U, "t2LDMIA_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:LR | ldm.w r4!, {r0, r1, r2, r5, r6, r7, r8, r9, r10, r12, lr} | may_load",
  ),
  (
    4, 0xe8b37ef3U, "t2LDMIA_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | ldm.w r3!, {r0, r1, r4, r5, r6, r7, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8bda000U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:SP Reg:PC | pop.w {sp, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bd8392U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:R7 Reg:R8 Reg:R9 Reg:PC | pop.w {r1, r4, r7, r8, r9, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bdf0c2U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:LR Reg:PC | pop.w {r1, r6, r7, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bdf0cfU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R6 Reg:R7 Reg:R12 Reg:SP Reg:LR Reg:PC | pop.w {r0, r1, r2, r3, r6, r7, r12, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bded9dU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:SP Reg:LR Reg:PC | pop.w {r0, r2, r3, r4, r7, r8, r10, r11, sp, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bddf6fU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR Reg:PC | pop.w {r0, r1, r2, r3, r5, r6, r8, r9, r10, r11, r12, lr, pc} | affect_cf,may_load",
  ),
  (
    4, 0xe8bd2800U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R11 Reg:SP | pop.w {r11, sp} | may_load",
  ),
  (
    4, 0xe8bd6012U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R4 Reg:SP Reg:LR | pop.w {r1, r4, sp, lr} | may_load",
  ),
  (
    4, 0xe8bd302eU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R12 Reg:SP | pop.w {r1, r2, r3, r5, r12, sp} | may_load",
  ),
  (
    4, 0xe8bd252bU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R5 Reg:R8 Reg:R10 Reg:SP | pop.w {r0, r1, r3, r5, r8, r10, sp} | may_load",
  ),
  (
    4, 0xe8bd7f62U, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | pop.w {r1, r5, r6, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xe8bd7f6eU, "t2LDMIA_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:SP Reg:LR | pop.w {r1, r2, r3, r5, r6, r8, r9, r10, r11, r12, sp, lr} | may_load",
  ),
  (
    4, 0xf813fb67U, "t2LDRB_POST Reg:PC Reg:R3 Reg:R3 Imm:103 Imm:14 Reg:Nil | ldrb pc, [r3], #103 | affect_cf,may_load",
  ),
  (
    4, 0xf810ab00U, "t2LDRB_POST Reg:R10 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrb r10, [r0], #0 | may_load",
  ),
  (
    4, 0xf811fd00U, "t2LDRB_PRE Reg:PC Reg:R1 Reg:R1 Imm:-2147483648 Imm:14 Reg:Nil | ldrb pc, [r1, #-0]! | affect_cf,may_load",
  ),
  (
    4, 0xf8103fdeU, "t2LDRB_PRE Reg:R3 Reg:R0 Reg:R0 Imm:222 Imm:14 Reg:Nil | ldrb r3, [r0, #222]! | may_load",
  ),
  (
    4, 0xf8907c7cU, "t2LDRBi12 Reg:R7 Reg:R0 Imm:3196 Imm:14 Reg:Nil | ldrb.w r7, [r0, #3196] | may_load",
  ),
  (
    4, 0xf8121cafU, "t2LDRBi8 Reg:R1 Reg:R2 Imm:-175 Imm:14 Reg:Nil | ldrb r1, [r2, #-175] | may_load",
  ),
  (
    4, 0xf81fc93bU, "t2LDRBpci Reg:R12 Imm:-2363 Imm:14 Reg:Nil | ldrb.w r12, [pc, #-2363] | may_load",
  ),
  (
    4, 0xf811c02dU, "t2LDRBs Reg:R12 Reg:R1 Reg:SP Imm:2 Imm:14 Reg:Nil | ldrb.w r12, [r1, sp, lsl #2] | may_load",
  ),
  (
    4, 0xe870fdb5U, "t2LDRD_POST Reg:PC Reg:SP Reg:R0 Reg:R0 Imm:-724 Imm:14 Reg:Nil | ldrd pc, sp, [r0], #-724 | affect_cf,may_load",
  ),
  (
    4, 0xe8709313U, "t2LDRD_POST Reg:R9 Reg:R3 Reg:R0 Reg:R0 Imm:-76 Imm:14 Reg:Nil | ldrd r9, r3, [r0], #-76 | may_load",
  ),
  (
    4, 0xe970f7b0U, "t2LDRD_PRE Reg:PC Reg:R7 Reg:R0 Reg:R0 Imm:-704 Imm:14 Reg:Nil | ldrd pc, r7, [r0, #-704]! | affect_cf,may_load",
  ),
  (
    4, 0xe970de82U, "t2LDRD_PRE Reg:SP Reg:LR Reg:R0 Reg:R0 Imm:-520 Imm:14 Reg:Nil | ldrd sp, lr, [r0, #-520]! | may_load",
  ),
  (
    4, 0xe950f600U, "t2LDRDi8 Reg:PC Reg:R6 Reg:R0 Imm:-2147483648 Imm:14 Reg:Nil | ldrd pc, r6, [r0, #-0] | affect_cf,may_load",
  ),
  (
    4, 0xe9504dc5U, "t2LDRDi8 Reg:R4 Reg:SP Reg:R0 Imm:-788 Imm:14 Reg:Nil | ldrd r4, sp, [r0, #-788] | may_load",
  ),
  (
    4, 0xe853ff00U, "t2LDREX Reg:PC Reg:R3 Imm:0 Imm:14 Reg:Nil | ldrex pc, [r3] | affect_cf,may_load,may_store",
  ),
  (
    4, 0xe8502f9bU, "t2LDREX Reg:R2 Reg:R0 Imm:155 Imm:14 Reg:Nil | ldrex r2, [r0, #620] | may_load,may_store",
  ),
  (
    4, 0xe8ddb07fU, "t2LDREXD Reg:R11 Reg:R0 Reg:SP Imm:14 Reg:Nil | ldrexd r11, r0, [sp] | may_load",
  ),
  (
    4, 0xe8d70f5fU, "t2LDREXH Reg:R0 Reg:R7 Imm:14 Reg:Nil | ldrexh r0, [r7] | may_load,may_store",
  ),
  (
    4, 0xf830fb00U, "t2LDRH_POST Reg:PC Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrh pc, [r0], #0 | affect_cf,may_load",
  ),
  (
    4, 0xf8328bb4U, "t2LDRH_POST Reg:R8 Reg:R2 Reg:R2 Imm:180 Imm:14 Reg:Nil | ldrh r8, [r2], #180 | may_load",
  ),
  (
    4, 0xf830fffdU, "t2LDRH_PRE Reg:PC Reg:R0 Reg:R0 Imm:253 Imm:14 Reg:Nil | ldrh pc, [r0, #253]! | affect_cf,may_load",
  ),
  (
    4, 0xf8307da8U, "t2LDRH_PRE Reg:R7 Reg:R0 Reg:R0 Imm:-168 Imm:14 Reg:Nil | ldrh r7, [r0, #-168]! | may_load",
  ),
  (
    4, 0xf8b018b6U, "t2LDRHi12 Reg:R1 Reg:R0 Imm:2230 Imm:14 Reg:Nil | ldrh.w r1, [r0, #2230] | may_load",
  ),
  (
    4, 0xf8318c00U, "t2LDRHi8 Reg:R8 Reg:R1 Imm:-2147483648 Imm:14 Reg:Nil | ldrh r8, [r1, #-0] | may_load",
  ),
  (
    4, 0xf83f1cfcU, "t2LDRHpci Reg:R1 Imm:-3324 Imm:14 Reg:Nil | ldrh.w r1, [pc, #-3324] | may_load",
  ),
  (
    4, 0xf8303000U, "t2LDRHs Reg:R3 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrh.w r3, [r0, r0] | may_load",
  ),
  (
    4, 0xf912f900U, "t2LDRSB_POST Reg:PC Reg:R2 Reg:R2 Imm:-2147483648 Imm:14 Reg:Nil | ldrsb pc, [r2], #-0 | affect_cf,may_load",
  ),
  (
    4, 0xf910eb1bU, "t2LDRSB_POST Reg:LR Reg:R0 Reg:R0 Imm:27 Imm:14 Reg:Nil | ldrsb lr, [r0], #27 | may_load",
  ),
  (
    4, 0xf911ff5bU, "t2LDRSB_PRE Reg:PC Reg:R1 Reg:R1 Imm:91 Imm:14 Reg:Nil | ldrsb pc, [r1, #91]! | affect_cf,may_load",
  ),
  (
    4, 0xf9102f48U, "t2LDRSB_PRE Reg:R2 Reg:R0 Reg:R0 Imm:72 Imm:14 Reg:Nil | ldrsb r2, [r0, #72]! | may_load",
  ),
  (
    4, 0xf990b1b2U, "t2LDRSBi12 Reg:R11 Reg:R0 Imm:434 Imm:14 Reg:Nil | ldrsb.w r11, [r0, #434] | may_load",
  ),
  (
    4, 0xf9120c00U, "t2LDRSBi8 Reg:R0 Reg:R2 Imm:-2147483648 Imm:14 Reg:Nil | ldrsb r0, [r2, #-0] | may_load",
  ),
  (
    4, 0xf91f4594U, "t2LDRSBpci Reg:R4 Imm:-1428 Imm:14 Reg:Nil | ldrsb.w r4, [pc, #-1428] | may_load",
  ),
  (
    4, 0xf9103000U, "t2LDRSBs Reg:R3 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrsb.w r3, [r0, r0] | may_load",
  ),
  (
    4, 0xf930f9d8U, "t2LDRSH_POST Reg:PC Reg:R0 Reg:R0 Imm:-216 Imm:14 Reg:Nil | ldrsh pc, [r0], #-216 | affect_cf,may_load",
  ),
  (
    4, 0xf9300b00U, "t2LDRSH_POST Reg:R0 Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrsh r0, [r0], #0 | may_load",
  ),
  (
    4, 0xf933fd8cU, "t2LDRSH_PRE Reg:PC Reg:R3 Reg:R3 Imm:-140 Imm:14 Reg:Nil | ldrsh pc, [r3, #-140]! | affect_cf,may_load",
  ),
  (
    4, 0xf9304f73U, "t2LDRSH_PRE Reg:R4 Reg:R0 Reg:R0 Imm:115 Imm:14 Reg:Nil | ldrsh r4, [r0, #115]! | may_load",
  ),
  (
    4, 0xf9b0dd31U, "t2LDRSHi12 Reg:SP Reg:R0 Imm:3377 Imm:14 Reg:Nil | ldrsh.w sp, [r0, #3377] | may_load",
  ),
  (
    4, 0xf931cc31U, "t2LDRSHi8 Reg:R12 Reg:R1 Imm:-49 Imm:14 Reg:Nil | ldrsh r12, [r1, #-49] | may_load",
  ),
  (
    4, 0xf93f8395U, "t2LDRSHpci Reg:R8 Imm:-917 Imm:14 Reg:Nil | ldrsh.w r8, [pc, #-917] | may_load",
  ),
  (
    4, 0xf9329000U, "t2LDRSHs Reg:R9 Reg:R2 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrsh.w r9, [r2, r0] | may_load",
  ),
  (
    4, 0xf851fb5aU, "t2LDR_POST Reg:PC Reg:R1 Reg:R1 Imm:90 Imm:14 Reg:Nil | ldr pc, [r1], #90 | affect_cf,may_load",
  ),
  (
    4, 0xf850db00U, "t2LDR_POST Reg:SP Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldr sp, [r0], #0 | may_load",
  ),
  (
    4, 0xf850ff07U, "t2LDR_PRE Reg:PC Reg:R0 Reg:R0 Imm:7 Imm:14 Reg:Nil | ldr pc, [r0, #7]! | affect_cf,may_load",
  ),
  (
    4, 0xf8516fbdU, "t2LDR_PRE Reg:R6 Reg:R1 Reg:R1 Imm:189 Imm:14 Reg:Nil | ldr r6, [r1, #189]! | may_load",
  ),
  (
    4, 0xf8d0fb23U, "t2LDRi12 Reg:PC Reg:R0 Imm:2851 Imm:14 Reg:Nil | ldr.w pc, [r0, #2851] | affect_cf,may_load",
  ),
  (
    4, 0xf8d04aebU, "t2LDRi12 Reg:R4 Reg:R0 Imm:2795 Imm:14 Reg:Nil | ldr.w r4, [r0, #2795] | may_load",
  ),
  (
    4, 0xf855fc05U, "t2LDRi8 Reg:PC Reg:R5 Imm:-5 Imm:14 Reg:Nil | ldr pc, [r5, #-5] | affect_cf,may_load",
  ),
  (
    4, 0xf8513c00U, "t2LDRi8 Reg:R3 Reg:R1 Imm:-2147483648 Imm:14 Reg:Nil | ldr r3, [r1, #-0] | may_load",
  ),
  (
    4, 0xf85ffa17U, "t2LDRpci Reg:PC Imm:-2583 Imm:14 Reg:Nil | ldr.w pc, [pc, #-2583] | affect_cf,may_load",
  ),
  (
    4, 0xf85f5b0bU, "t2LDRpci Reg:R5 Imm:-2827 Imm:14 Reg:Nil | ldr.w r5, [pc, #-2827] | may_load",
  ),
  (
    4, 0xf855f03dU, "t2LDRs Reg:PC Reg:R5 Reg:SP Imm:3 Imm:14 Reg:Nil | ldr.w pc, [r5, sp, lsl #3] | affect_cf,may_load",
  ),
  (
    4, 0xf8501015U, "t2LDRs Reg:R1 Reg:R0 Reg:R5 Imm:1 Imm:14 Reg:Nil | ldr.w r1, [r0, r5, lsl #1] | may_load",
  ),
  (
    4, 0xea5f4d88U, "t2LSLri Reg:SP Reg:R8 Imm:18 Imm:14 Reg:Nil Reg:CPSR | lsls.w sp, r8, #18",
  ),
  (
    4, 0xea5f2f4eU, "t2LSLri Reg:PC Reg:LR Imm:9 Imm:14 Reg:Nil Reg:CPSR | lsls.w pc, lr, #9 | affect_cf",
  ),
  (
    4, 0xea4f7d00U, "t2LSLri Reg:SP Reg:R0 Imm:28 Imm:14 Reg:Nil Reg:Nil | lsl.w sp, r0, #28",
  ),
  (
    4, 0xfa10f505U, "t2LSLrr Reg:R5 Reg:R0 Reg:R5 Imm:14 Reg:Nil Reg:CPSR | lsls.w r5, r0, r5",
  ),
  (
    4, 0xfa1aff00U, "t2LSLrr Reg:PC Reg:R10 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | lsls.w pc, r10, r0 | affect_cf",
  ),
  (
    4, 0xfa00fa00U, "t2LSLrr Reg:R10 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | lsl.w r10, r0, r0",
  ),
  (
    4, 0xea4f34daU, "t2LSRri Reg:R4 Reg:R10 Imm:15 Imm:14 Reg:Nil Reg:Nil | lsr.w r4, r10, #15",
  ),
  (
    4, 0xea4f4f9cU, "t2LSRri Reg:PC Reg:R12 Imm:18 Imm:14 Reg:Nil Reg:Nil | lsr.w pc, r12, #18 | affect_cf",
  ),
  (
    4, 0xea5f6358U, "t2LSRri Reg:R3 Reg:R8 Imm:25 Imm:14 Reg:Nil Reg:CPSR | lsrs.w r3, r8, #25",
  ),
  (
    4, 0xfa20f800U, "t2LSRrr Reg:R8 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | lsr.w r8, r0, r0",
  ),
  (
    4, 0xfa30fb03U, "t2LSRrr Reg:R11 Reg:R0 Reg:R3 Imm:14 Reg:Nil Reg:CPSR | lsrs.w r11, r0, r3",
  ),
  (
    4, 0xfa30ff00U, "t2LSRrr Reg:PC Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | lsrs.w pc, r0, r0 | affect_cf",
  ),
  (
    4, 0xfb001e00U, "t2MLA Reg:LR Reg:R0 Reg:R0 Reg:R1 Imm:14 Reg:Nil | mla lr, r0, r0, r1",
  ),
  (
    4, 0xfb026f00U, "t2MLA Reg:PC Reg:R2 Reg:R0 Reg:R6 Imm:14 Reg:Nil | mla pc, r2, r0, r6 | affect_cf",
  ),
  (
    4, 0xfb02e91fU, "t2MLS Reg:R9 Reg:R2 Reg:PC Reg:LR Imm:14 Reg:Nil | mls r9, r2, pc, lr",
  ),
  (
    4, 0xfb090f15U, "t2MLS Reg:PC Reg:R9 Reg:R5 Reg:R0 Imm:14 Reg:Nil | mls pc, r9, r5, r0 | affect_cf",
  ),
  (
    4, 0xf2c03300U, "t2MOVTi16 Reg:R3 Reg:R3 Imm:768 Imm:14 Reg:Nil | movt r3, #768",
  ),
  (
    4, 0xf2c00f4aU, "t2MOVTi16 Reg:PC Reg:PC Imm:74 Imm:14 Reg:Nil | movt pc, #74 | affect_cf",
  ),
  (
    4, 0xf05f0019U, "t2MOVi Reg:R0 Imm:25 Imm:14 Reg:Nil Reg:CPSR | movs.w r0, #25",
  ),
  (
    4, 0xf05f6f72U, "t2MOVi Reg:PC Imm:253755392 Imm:14 Reg:Nil Reg:CPSR | movs.w pc, #253755392 | affect_cf",
  ),
  (
    4, 0xf04f3061U, "t2MOVi Reg:R0 Imm:1633771873 Imm:14 Reg:Nil Reg:Nil | mov.w r0, #1633771873",
  ),
  (
    4, 0xf04f6fc9U, "t2MOVi Reg:PC Imm:105381888 Imm:14 Reg:Nil Reg:Nil | mov.w pc, #105381888 | affect_cf",
  ),
  (4, 0xf240703dU, "t2MOVi16 Reg:R0 Imm:1853 Imm:14 Reg:Nil | movw r0, #1853"),
  (
    4, 0xf2403f5eU, "t2MOVi16 Reg:PC Imm:862 Imm:14 Reg:Nil | movw pc, #862 | affect_cf",
  ),
  (4, 0xea4f0001U, "t2MOVr Reg:R0 Reg:R1 Imm:14 Reg:Nil Reg:Nil | mov.w r0, r1"),
  (4, 0xf3858700U, "t2MSR_AR Imm:7 Reg:R5 Imm:14 Reg:Nil | msr CPSR_sxc, r5"),
  (4, 0xfb00f500U, "t2MUL Reg:R5 Reg:R0 Reg:R0 Imm:14 Reg:Nil | mul r5, r0, r0"),
  (
    4, 0xf06f1b37U, "t2MVNi Reg:R11 Imm:3604535 Imm:14 Reg:Nil Reg:Nil | mvn r11, #3604535",
  ),
  (
    4, 0xf06f5fc1U, "t2MVNi Reg:PC Imm:404750336 Imm:14 Reg:Nil Reg:Nil | mvn pc, #404750336 | affect_cf",
  ),
  (
    4, 0xf07f20d1U, "t2MVNi Reg:R0 Imm:3506491648 Imm:14 Reg:Nil Reg:CPSR | mvns r0, #3506491648",
  ),
  (
    4, 0xf07f5f72U, "t2MVNi Reg:PC Imm:1015021568 Imm:14 Reg:Nil Reg:CPSR | mvns pc, #1015021568 | affect_cf",
  ),
  (
    4, 0xea6f8f00U, "t2MVNr Reg:PC Reg:R0 Imm:14 Reg:Nil Reg:Nil | mvn.w pc, r0 | affect_cf",
  ),
  (
    4, 0xea6f97acU, "t2MVNs Reg:R7 Reg:R12 Imm:49 Imm:14 Reg:Nil Reg:Nil | mvn.w r7, r12, asr #6",
  ),
  (
    4, 0xea6f6ffbU, "t2MVNs Reg:PC Reg:R11 Imm:220 Imm:14 Reg:Nil Reg:Nil | mvn.w pc, r11, ror #27 | affect_cf",
  ),
  (
    4, 0xea7fe007U, "t2MVNs Reg:R0 Reg:R7 Imm:194 Imm:14 Reg:Nil Reg:CPSR | mvns.w r0, r7, lsl #24",
  ),
  (
    4, 0xea7f5f5eU, "t2MVNs Reg:PC Reg:LR Imm:171 Imm:14 Reg:Nil Reg:CPSR | mvns.w pc, lr, lsr #21 | affect_cf",
  ),
  (
    4, 0xf06079c0U, "t2ORNri Reg:R9 Reg:R0 Imm:25165824 Imm:14 Reg:Nil Reg:Nil | orn r9, r0, #25165824",
  ),
  (
    4, 0xf0606f11U, "t2ORNri Reg:PC Reg:R0 Imm:152043520 Imm:14 Reg:Nil Reg:Nil | orn pc, r0, #152043520 | affect_cf",
  ),
  (
    4, 0xf0706eceU, "t2ORNri Reg:LR Reg:R0 Imm:108003328 Imm:14 Reg:Nil Reg:CPSR | orns lr, r0, #108003328",
  ),
  (
    4, 0xf0706fd5U, "t2ORNri Reg:PC Reg:R0 Imm:111673344 Imm:14 Reg:Nil Reg:CPSR | orns pc, r0, #111673344 | affect_cf",
  ),
  (
    4, 0xea610000U, "t2ORNrr Reg:R0 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:Nil | orn r0, r1, r0",
  ),
  (
    4, 0xea700d00U, "t2ORNrr Reg:SP Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | orns sp, r0, r0",
  ),
  (
    4, 0xea790f04U, "t2ORNrr Reg:PC Reg:R9 Reg:R4 Imm:14 Reg:Nil Reg:CPSR | orns pc, r9, r4 | affect_cf",
  ),
  (
    4, 0xea60f6d0U, "t2ORNrs Reg:R6 Reg:R0 Reg:R0 Imm:251 Imm:14 Reg:Nil Reg:Nil | orn r6, r0, r0, lsr #31",
  ),
  (
    4, 0xea604fdfU, "t2ORNrs Reg:PC Reg:R0 Reg:PC Imm:155 Imm:14 Reg:Nil Reg:Nil | orn pc, r0, pc, lsr #19 | affect_cf",
  ),
  (
    4, 0xea70ab55U, "t2ORNrs Reg:R11 Reg:R0 Reg:R5 Imm:75 Imm:14 Reg:Nil Reg:CPSR | orns r11, r0, r5, lsr #9",
  ),
  (
    4, 0xea70efd0U, "t2ORNrs Reg:PC Reg:R0 Reg:R0 Imm:219 Imm:14 Reg:Nil Reg:CPSR | orns pc, r0, r0, lsr #27 | affect_cf",
  ),
  (
    4, 0xf04035a6U, "t2ORRri Reg:R5 Reg:R0 Imm:2795939494 Imm:14 Reg:Nil Reg:Nil | orr r5, r0, #2795939494",
  ),
  (
    4, 0xf0404fa4U, "t2ORRri Reg:PC Reg:R0 Imm:1375731712 Imm:14 Reg:Nil Reg:Nil | orr pc, r0, #1375731712 | affect_cf",
  ),
  (
    4, 0xf0506200U, "t2ORRri Reg:R2 Reg:R0 Imm:134217728 Imm:14 Reg:Nil Reg:CPSR | orrs r2, r0, #134217728",
  ),
  (
    4, 0xf0504fc4U, "t2ORRri Reg:PC Reg:R0 Imm:1644167168 Imm:14 Reg:Nil Reg:CPSR | orrs pc, r0, #1644167168 | affect_cf",
  ),
  (
    4, 0xea430500U, "t2ORRrr Reg:R5 Reg:R3 Reg:R0 Imm:14 Reg:Nil Reg:Nil | orr.w r5, r3, r0",
  ),
  (
    4, 0xea500c00U, "t2ORRrr Reg:R12 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | orrs.w r12, r0, r0",
  ),
  (
    4, 0xea570f00U, "t2ORRrr Reg:PC Reg:R7 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | orrs.w pc, r7, r0 | affect_cf",
  ),
  (
    4, 0xea4041a2U, "t2ORRrs Reg:R1 Reg:R0 Reg:R2 Imm:145 Imm:14 Reg:Nil Reg:Nil | orr.w r1, r0, r2, asr #18",
  ),
  (
    4, 0xea400fd6U, "t2ORRrs Reg:PC Reg:R0 Reg:R6 Imm:27 Imm:14 Reg:Nil Reg:Nil | orr.w pc, r0, r6, lsr #3 | affect_cf",
  ),
  (
    4, 0xea502100U, "t2ORRrs Reg:R1 Reg:R0 Reg:R0 Imm:66 Imm:14 Reg:Nil Reg:CPSR | orrs.w r1, r0, r0, lsl #8",
  ),
  (
    4, 0xea507f7cU, "t2ORRrs Reg:PC Reg:R0 Reg:R12 Imm:236 Imm:14 Reg:Nil Reg:CPSR | orrs.w pc, r0, r12, ror #29 | affect_cf",
  ),
  (
    4, 0xeac0884eU, "t2PKHBT Reg:R8 Reg:R0 Reg:LR Imm:1 Imm:14 Reg:Nil | pkhbt r8, r0, lr, lsl #1",
  ),
  (
    4, 0xeac0df00U, "t2PKHBT Reg:PC Reg:R0 Reg:R0 Imm:20 Imm:14 Reg:Nil | pkhbt pc, r0, r0, lsl #20 | affect_cf",
  ),
  (
    4, 0xeac04da3U, "t2PKHTB Reg:SP Reg:R0 Reg:R3 Imm:18 Imm:14 Reg:Nil | pkhtb sp, r0, r3, asr #18",
  ),
  (
    4, 0xeac28f28U, "t2PKHTB Reg:PC Reg:R2 Reg:R8 Imm:0 Imm:14 Reg:Nil | pkhtb pc, r2, r8, asr #32 | affect_cf",
  ),
  (
    4, 0xf890fdcdU, "t2PLDi12 Reg:R0 Imm:3533 Imm:14 Reg:Nil | pld [r0, #3533] | may_load,may_store",
  ),
  (
    4, 0xf816fc8bU, "t2PLDi8 Reg:R6 Imm:-139 Imm:14 Reg:Nil | pld [r6, #-139] | may_load,may_store",
  ),
  (
    4, 0xf81ff82bU, "t2PLDpci Imm:-2091 Imm:14 Reg:Nil | pld [pc, #-2091] | may_load,may_store",
  ),
  (
    4, 0xf811f003U, "t2PLDs Reg:R1 Reg:R3 Imm:0 Imm:14 Reg:Nil | pld [r1, r3] | may_load,may_store",
  ),
  (
    4, 0xf990fbc0U, "t2PLIi12 Reg:R0 Imm:3008 Imm:14 Reg:Nil | pli [r0, #3008] | may_load,may_store",
  ),
  (
    4, 0xf910fc67U, "t2PLIi8 Reg:R0 Imm:-103 Imm:14 Reg:Nil | pli [r0, #-103] | may_load,may_store",
  ),
  (
    4, 0xf91ff100U, "t2PLIpci Imm:-256 Imm:14 Reg:Nil | pli [pc, #-256] | may_load,may_store",
  ),
  (
    4, 0xf910f000U, "t2PLIs Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | pli [r0, r0] | may_load,may_store",
  ),
  (4, 0xfa98fa98U, "t2REV16 Reg:R10 Reg:R8 Imm:14 Reg:Nil | rev16.w r10, r8"),
  (
    4, 0xea4f473fU, "t2RORri Reg:R7 Reg:PC Imm:16 Imm:14 Reg:Nil Reg:Nil | ror.w r7, pc, #16",
  ),
  (
    4, 0xea5f403dU, "t2RORri Reg:R0 Reg:SP Imm:16 Imm:14 Reg:Nil Reg:CPSR | rors.w r0, sp, #16",
  ),
  (
    4, 0xea5f3f79U, "t2RORri Reg:PC Reg:R9 Imm:13 Imm:14 Reg:Nil Reg:CPSR | rors.w pc, r9, #13 | affect_cf",
  ),
  (
    4, 0xfa60f500U, "t2RORrr Reg:R5 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | ror.w r5, r0, r0",
  ),
  (
    4, 0xfa68ff00U, "t2RORrr Reg:PC Reg:R8 Reg:R0 Imm:14 Reg:Nil Reg:Nil | ror.w pc, r8, r0 | affect_cf",
  ),
  (
    4, 0xfa70fd00U, "t2RORrr Reg:SP Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | rors.w sp, r0, r0",
  ),
  (
    4, 0xfa70ff0bU, "t2RORrr Reg:PC Reg:R0 Reg:R11 Imm:14 Reg:Nil Reg:CPSR | rors.w pc, r0, r11 | affect_cf",
  ),
  (
    4, 0xf1c00077U, "t2RSBri Reg:R0 Reg:R0 Imm:119 Imm:14 Reg:Nil Reg:Nil | rsb.w r0, r0, #119",
  ),
  (
    4, 0xf1c04f94U, "t2RSBri Reg:PC Reg:R0 Imm:1241513984 Imm:14 Reg:Nil Reg:Nil | rsb.w pc, r0, #1241513984 | affect_cf",
  ),
  (
    4, 0xf1d07000U, "t2RSBri Reg:R0 Reg:R0 Imm:33554432 Imm:14 Reg:Nil Reg:CPSR | rsbs.w r0, r0, #33554432",
  ),
  (
    4, 0xf1d05f30U, "t2RSBri Reg:PC Reg:R0 Imm:738197504 Imm:14 Reg:Nil Reg:CPSR | rsbs.w pc, r0, #738197504 | affect_cf",
  ),
  (
    4, 0xebc00600U, "t2RSBrr Reg:R6 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | rsb r6, r0, r0",
  ),
  (
    4, 0xebd20e00U, "t2RSBrr Reg:LR Reg:R2 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | rsbs lr, r2, r0",
  ),
  (
    4, 0xebc0b145U, "t2RSBrs Reg:R1 Reg:R0 Reg:R5 Imm:106 Imm:14 Reg:Nil Reg:Nil | rsb r1, r0, r5, lsl #13",
  ),
  (
    4, 0xebc02fabU, "t2RSBrs Reg:PC Reg:R0 Reg:R11 Imm:81 Imm:14 Reg:Nil Reg:Nil | rsb pc, r0, r11, asr #10 | affect_cf",
  ),
  (
    4, 0xebd02b00U, "t2RSBrs Reg:R11 Reg:R0 Reg:R0 Imm:66 Imm:14 Reg:Nil Reg:CPSR | rsbs r11, r0, r0, lsl #8",
  ),
  (
    4, 0xebd0ff84U, "t2RSBrs Reg:PC Reg:R0 Reg:R4 Imm:242 Imm:14 Reg:Nil Reg:CPSR | rsbs pc, r0, r4, lsl #30 | affect_cf",
  ),
  (
    4, 0xf1600486U, "t2SBCri Reg:R4 Reg:R0 Imm:134 Imm:14 Reg:Nil Reg:Nil | sbc r4, r0, #134",
  ),
  (
    4, 0xf1606fb5U, "t2SBCri Reg:PC Reg:R0 Imm:94896128 Imm:14 Reg:Nil Reg:Nil | sbc pc, r0, #94896128 | affect_cf",
  ),
  (
    4, 0xf1704678U, "t2SBCri Reg:R6 Reg:R0 Imm:4160749568 Imm:14 Reg:Nil Reg:CPSR | sbcs r6, r0, #4160749568",
  ),
  (
    4, 0xf1727fa3U, "t2SBCri Reg:PC Reg:R2 Imm:21364736 Imm:14 Reg:Nil Reg:CPSR | sbcs pc, r2, #21364736 | affect_cf",
  ),
  (
    4, 0xeb628c00U, "t2SBCrr Reg:R12 Reg:R2 Reg:R0 Imm:14 Reg:Nil Reg:Nil | sbc.w r12, r2, r0",
  ),
  (
    4, 0xeb700a00U, "t2SBCrr Reg:R10 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | sbcs.w r10, r0, r0",
  ),
  (
    4, 0xeb60a3baU, "t2SBCrs Reg:R3 Reg:R0 Reg:R10 Imm:84 Imm:14 Reg:Nil Reg:Nil | sbc.w r3, r0, r10, ror #10",
  ),
  (
    4, 0xeb60af25U, "t2SBCrs Reg:PC Reg:R0 Reg:R5 Imm:65 Imm:14 Reg:Nil Reg:Nil | sbc.w pc, r0, r5, asr #8 | affect_cf",
  ),
  (
    4, 0xeb70cec5U, "t2SBCrs Reg:LR Reg:R0 Reg:R5 Imm:154 Imm:14 Reg:Nil Reg:CPSR | sbcs.w lr, r0, r5, lsl #19",
  ),
  (
    4, 0xeb703f90U, "t2SBCrs Reg:PC Reg:R0 Reg:R0 Imm:115 Imm:14 Reg:Nil Reg:CPSR | sbcs.w pc, r0, r0, lsr #14 | affect_cf",
  ),
  (
    4, 0xf3405b54U, "t2SBFX Reg:R11 Reg:R0 Imm:21 Imm:20 Imm:14 Reg:Nil | sbfx r11, r0, #21, #21",
  ),
  (
    4, 0xf3421f0aU, "t2SBFX Reg:PC Reg:R2 Imm:4 Imm:10 Imm:14 Reg:Nil | sbfx pc, r2, #4, #11 | affect_cf",
  ),
  (
    4, 0xfb99f3f7U, "t2SDIV Reg:R3 Reg:R9 Reg:R7 Imm:14 Reg:Nil | sdiv r3, r9, r7",
  ),
  (
    4, 0xfb94fffcU, "t2SDIV Reg:PC Reg:R4 Reg:R12 Imm:14 Reg:Nil | sdiv pc, r4, r12 | affect_cf",
  ),
  (
    4, 0xfb102b00U, "t2SMLABB Reg:R11 Reg:R0 Reg:R0 Reg:R2 Imm:14 Reg:Nil | smlabb r11, r0, r0, r2",
  ),
  (
    4, 0xfb168f00U, "t2SMLABB Reg:PC Reg:R6 Reg:R0 Reg:R8 Imm:14 Reg:Nil | smlabb pc, r6, r0, r8 | affect_cf",
  ),
  (
    4, 0xfb11701dU, "t2SMLABT Reg:R0 Reg:R1 Reg:SP Reg:R7 Imm:14 Reg:Nil | smlabt r0, r1, sp, r7",
  ),
  (
    4, 0xfb115f14U, "t2SMLABT Reg:PC Reg:R1 Reg:R4 Reg:R5 Imm:14 Reg:Nil | smlabt pc, r1, r4, r5 | affect_cf",
  ),
  (
    4, 0xfb205a00U, "t2SMLAD Reg:R10 Reg:R0 Reg:R0 Reg:R5 Imm:14 Reg:Nil | smlad r10, r0, r0, r5",
  ),
  (
    4, 0xfb202f06U, "t2SMLAD Reg:PC Reg:R0 Reg:R6 Reg:R2 Imm:14 Reg:Nil | smlad pc, r0, r6, r2 | affect_cf",
  ),
  (
    4, 0xfb204314U, "t2SMLADX Reg:R3 Reg:R0 Reg:R4 Reg:R4 Imm:14 Reg:Nil | smladx r3, r0, r4, r4",
  ),
  (
    4, 0xfb23af19U, "t2SMLADX Reg:PC Reg:R3 Reg:R9 Reg:R10 Imm:14 Reg:Nil | smladx pc, r3, r9, r10 | affect_cf",
  ),
  (
    4, 0xfbc0e800U, "t2SMLAL Reg:LR Reg:R8 Reg:R0 Reg:R0 Reg:LR Reg:R8 Imm:14 Reg:Nil | smlal lr, r8, r0, r0",
  ),
  (
    4, 0xfbc0f803U, "t2SMLAL Reg:PC Reg:R8 Reg:R0 Reg:R3 Reg:PC Reg:R8 Imm:14 Reg:Nil | smlal pc, r8, r0, r3 | affect_cf",
  ),
  (
    4, 0xfb10cb23U, "t2SMLATB Reg:R11 Reg:R0 Reg:R3 Reg:R12 Imm:14 Reg:Nil | smlatb r11, r0, r3, r12",
  ),
  (
    4, 0xfb114f29U, "t2SMLATB Reg:PC Reg:R1 Reg:R9 Reg:R4 Imm:14 Reg:Nil | smlatb pc, r1, r9, r4 | affect_cf",
  ),
  (
    4, 0xfb105c31U, "t2SMLATT Reg:R12 Reg:R0 Reg:R1 Reg:R5 Imm:14 Reg:Nil | smlatt r12, r0, r1, r5",
  ),
  (
    4, 0xfb15df30U, "t2SMLATT Reg:PC Reg:R5 Reg:R0 Reg:SP Imm:14 Reg:Nil | smlatt pc, r5, r0, sp | affect_cf",
  ),
  (
    4, 0xfb300c00U, "t2SMLAWB Reg:R12 Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | smlawb r12, r0, r0, r0",
  ),
  (
    4, 0xfb333f00U, "t2SMLAWB Reg:PC Reg:R3 Reg:R0 Reg:R3 Imm:14 Reg:Nil | smlawb pc, r3, r0, r3 | affect_cf",
  ),
  (
    4, 0xfb30c012U, "t2SMLAWT Reg:R0 Reg:R0 Reg:R2 Reg:R12 Imm:14 Reg:Nil | smlawt r0, r0, r2, r12",
  ),
  (
    4, 0xfb320f1dU, "t2SMLAWT Reg:PC Reg:R2 Reg:SP Reg:R0 Imm:14 Reg:Nil | smlawt pc, r2, sp, r0 | affect_cf",
  ),
  (
    4, 0xfb20fd0bU, "t2SMUAD Reg:SP Reg:R0 Reg:R11 Imm:14 Reg:Nil | smuad sp, r0, r11",
  ),
  (
    4, 0xfb2bf81aU, "t2SMUADX Reg:R8 Reg:R11 Reg:R10 Imm:14 Reg:Nil | smuadx r8, r11, r10",
  ),
  (
    4, 0xfb10f000U, "t2SMULBB Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | smulbb r0, r0, r0",
  ),
  (
    4, 0xfb1eff00U, "t2SMULBB Reg:PC Reg:LR Reg:R0 Imm:14 Reg:Nil | smulbb pc, lr, r0 | affect_cf",
  ),
  (
    4, 0xfb18f61fU, "t2SMULBT Reg:R6 Reg:R8 Reg:PC Imm:14 Reg:Nil | smulbt r6, r8, pc",
  ),
  (
    4, 0xfb804d00U, "t2SMULL Reg:R4 Reg:SP Reg:R0 Reg:R0 Imm:14 Reg:Nil | smull r4, sp, r0, r0",
  ),
  (
    4, 0xfb80f700U, "t2SMULL Reg:PC Reg:R7 Reg:R0 Reg:R0 Imm:14 Reg:Nil | smull pc, r7, r0, r0 | affect_cf",
  ),
  (
    4, 0xfb10fb22U, "t2SMULTB Reg:R11 Reg:R0 Reg:R2 Imm:14 Reg:Nil | smultb r11, r0, r2",
  ),
  (
    4, 0xfb11f830U, "t2SMULTT Reg:R8 Reg:R1 Reg:R0 Imm:14 Reg:Nil | smultt r8, r1, r0",
  ),
  (
    4, 0xfb14ff3aU, "t2SMULTT Reg:PC Reg:R4 Reg:R10 Imm:14 Reg:Nil | smultt pc, r4, r10 | affect_cf",
  ),
  (
    4, 0xfb30f800U, "t2SMULWB Reg:R8 Reg:R0 Reg:R0 Imm:14 Reg:Nil | smulwb r8, r0, r0",
  ),
  (
    4, 0xfb3dff09U, "t2SMULWB Reg:PC Reg:SP Reg:R9 Imm:14 Reg:Nil | smulwb pc, sp, r9 | affect_cf",
  ),
  (
    4, 0xfb3efa12U, "t2SMULWT Reg:R10 Reg:LR Reg:R2 Imm:14 Reg:Nil | smulwt r10, lr, r2",
  ),
  (
    4, 0xe9090400U, "t2STMDB Reg:R9 Imm:14 Reg:Nil Reg:R10 | stmdb r9, {r10} | may_store",
  ),
  (
    4, 0xe9015000U, "t2STMDB Reg:R1 Imm:14 Reg:Nil Reg:R12 Reg:LR | stmdb r1, {r12, lr} | may_store",
  ),
  (
    4, 0xe9014081U, "t2STMDB Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R7 Reg:LR | stmdb r1, {r0, r7, lr} | may_store",
  ),
  (
    4, 0xe9001414U, "t2STMDB Reg:R0 Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R10 Reg:R12 | stmdb r0, {r2, r4, r10, r12} | may_store",
  ),
  (
    4, 0xe90210b1U, "t2STMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R5 Reg:R7 Reg:R12 | stmdb r2, {r0, r4, r5, r7, r12} | may_store",
  ),
  (
    4, 0xe90210cbU, "t2STMDB Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R6 Reg:R7 Reg:R12 | stmdb r2, {r0, r1, r3, r6, r7, r12} | may_store",
  ),
  (
    4, 0xe90040afU, "t2STMDB Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R7 Reg:LR | stmdb r0, {r0, r1, r2, r3, r5, r7, lr} | may_store",
  ),
  (
    4, 0xe90349e5U, "t2STMDB Reg:R3 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R11 Reg:LR | stmdb r3, {r0, r2, r5, r6, r7, r8, r11, lr} | may_store",
  ),
  (
    4, 0xe9004d3bU, "t2STMDB Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R11 Reg:LR | stmdb r0, {r0, r1, r3, r4, r5, r8, r10, r11, lr} | may_store",
  ),
  (
    4, 0xe9074777U, "t2STMDB Reg:R7 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R4 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:LR | stmdb r7, {r0, r1, r2, r4, r5, r6, r8, r9, r10, lr} | may_store",
  ),
  (
    4, 0xe90a1fdfU, "t2STMDB Reg:R10 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | stmdb r10, {r0, r1, r2, r3, r4, r6, r7, r8, r9, r10, r11, r12} | may_store",
  ),
  (
    4, 0xe92d0026U, "t2STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R5 | push.w {r1, r2, r5} | may_store",
  ),
  (
    4, 0xe92d4f54U, "t2STMDB_UPD Reg:SP Reg:SP Imm:14 Reg:Nil Reg:R2 Reg:R4 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | push.w {r2, r4, r6, r8, r9, r10, r11, lr} | may_store",
  ),
  (
    4, 0xe92f1120U, "t2STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R5 Reg:R8 Reg:R12 | stmdb pc!, {r5, r8, r12} | affect_cf,may_store",
  ),
  (
    4, 0xe92f401dU, "t2STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R4 Reg:LR | stmdb pc!, {r0, r2, r3, r4, lr} | affect_cf,may_store",
  ),
  (
    4, 0xe92f4f6fU, "t2STMDB_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | stmdb pc!, {r0, r1, r2, r3, r5, r6, r8, r9, r10, r11, lr} | affect_cf,may_store",
  ),
  (
    4, 0xe9221000U, "t2STMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R12 | stmdb r2!, {r12} | may_store",
  ),
  (
    4, 0xe9201800U, "t2STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R11 Reg:R12 | stmdb r0!, {r11, r12} | may_store",
  ),
  (
    4, 0xe9204b00U, "t2STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R8 Reg:R9 Reg:R11 Reg:LR | stmdb r0!, {r8, r9, r11, lr} | may_store",
  ),
  (
    4, 0xe92040a5U, "t2STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R5 Reg:R7 Reg:LR | stmdb r0!, {r0, r2, r5, r7, lr} | may_store",
  ),
  (
    4, 0xe9204135U, "t2STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R8 Reg:LR | stmdb r0!, {r0, r2, r4, r5, r8, lr} | may_store",
  ),
  (
    4, 0xe9220fb0U, "t2STMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R4 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 | stmdb r2!, {r4, r5, r7, r8, r9, r10, r11} | may_store",
  ),
  (
    4, 0xe920159bU, "t2STMDB_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R3 Reg:R4 Reg:R7 Reg:R8 Reg:R10 Reg:R12 | stmdb r0!, {r0, r1, r3, r4, r7, r8, r10, r12} | may_store",
  ),
  (
    4, 0xe92450dfU, "t2STMDB_UPD Reg:R4 Reg:R4 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R12 Reg:LR | stmdb r4!, {r0, r1, r2, r3, r4, r6, r7, r12, lr} | may_store",
  ),
  (
    4, 0xe92b4ff1U, "t2STMDB_UPD Reg:R11 Reg:R11 Imm:14 Reg:Nil Reg:R0 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | stmdb r11!, {r0, r4, r5, r6, r7, r8, r9, r10, r11, lr} | may_store",
  ),
  (
    4, 0xe9225f6dU, "t2STMDB_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stmdb r2!, {r0, r2, r3, r5, r6, r8, r9, r10, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe88b1000U, "t2STMIA Reg:R11 Imm:14 Reg:Nil Reg:R12 | stm.w r11, {r12} | may_store",
  ),
  (
    4, 0xe88c1800U, "t2STMIA Reg:R12 Imm:14 Reg:Nil Reg:R11 Reg:R12 | stm.w r12, {r11, r12} | may_store",
  ),
  (
    4, 0xe8801088U, "t2STMIA Reg:R0 Imm:14 Reg:Nil Reg:R3 Reg:R7 Reg:R12 | stm.w r0, {r3, r7, r12} | may_store",
  ),
  (
    4, 0xe8814450U, "t2STMIA Reg:R1 Imm:14 Reg:Nil Reg:R4 Reg:R6 Reg:R10 Reg:LR | stm.w r1, {r4, r6, r10, lr} | may_store",
  ),
  (
    4, 0xe8865015U, "t2STMIA Reg:R6 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R12 Reg:LR | stm.w r6, {r0, r2, r4, r12, lr} | may_store",
  ),
  (
    4, 0xe880450eU, "t2STMIA Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R8 Reg:R10 Reg:LR | stm.w r0, {r1, r2, r3, r8, r10, lr} | may_store",
  ),
  (
    4, 0xe8820d33U, "t2STMIA Reg:R2 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R4 Reg:R5 Reg:R8 Reg:R10 Reg:R11 | stm.w r2, {r0, r1, r4, r5, r8, r10, r11} | may_store",
  ),
  (
    4, 0xe8805762U, "t2STMIA Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R12 Reg:LR | stm.w r0, {r1, r5, r6, r8, r9, r10, r12, lr} | may_store",
  ),
  (
    4, 0xe8815f4cU, "t2STMIA Reg:R1 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stm.w r1, {r2, r3, r6, r8, r9, r10, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe8835ddaU, "t2STMIA Reg:R3 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stm.w r3, {r1, r3, r4, r6, r7, r8, r10, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe8895fecU, "t2STMIA Reg:R9 Imm:14 Reg:Nil Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stm.w r9, {r2, r3, r5, r6, r7, r8, r9, r10, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe8845efeU, "t2STMIA Reg:R4 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R9 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stm.w r4, {r1, r2, r3, r4, r5, r6, r7, r9, r10, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe8af1200U, "t2STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R9 Reg:R12 | stm.w pc!, {r9, r12} | affect_cf,may_store",
  ),
  (
    4, 0xe8af0535U, "t2STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R4 Reg:R5 Reg:R8 Reg:R10 | stm.w pc!, {r0, r2, r4, r5, r8, r10} | affect_cf,may_store",
  ),
  (
    4, 0xe8af1f42U, "t2STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R6 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:R12 | stm.w pc!, {r1, r6, r8, r9, r10, r11, r12} | affect_cf,may_store",
  ),
  (
    4, 0xe8af5dc2U, "t2STMIA_UPD Reg:PC Reg:PC Imm:14 Reg:Nil Reg:R1 Reg:R6 Reg:R7 Reg:R8 Reg:R10 Reg:R11 Reg:R12 Reg:LR | stm.w pc!, {r1, r6, r7, r8, r10, r11, r12, lr} | affect_cf,may_store",
  ),
  (
    4, 0xe8a90100U, "t2STMIA_UPD Reg:R9 Reg:R9 Imm:14 Reg:Nil Reg:R8 | stm.w r9!, {r8} | may_store",
  ),
  (
    4, 0xe8a04200U, "t2STMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R9 Reg:LR | stm.w r0!, {r9, lr} | may_store",
  ),
  (
    4, 0xe8a11500U, "t2STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R8 Reg:R10 Reg:R12 | stm.w r1!, {r8, r10, r12} | may_store",
  ),
  (
    4, 0xe8a15500U, "t2STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R8 Reg:R10 Reg:R12 Reg:LR | stm.w r1!, {r8, r10, r12, lr} | may_store",
  ),
  (
    4, 0xe8a340e8U, "t2STMIA_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R3 Reg:R5 Reg:R6 Reg:R7 Reg:LR | stm.w r3!, {r3, r5, r6, r7, lr} | may_store",
  ),
  (
    4, 0xe8a300edU, "t2STMIA_UPD Reg:R3 Reg:R3 Imm:14 Reg:Nil Reg:R0 Reg:R2 Reg:R3 Reg:R5 Reg:R6 Reg:R7 | stm.w r3!, {r0, r2, r3, r5, r6, r7} | may_store",
  ),
  (
    4, 0xe8a1193aU, "t2STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R8 Reg:R11 Reg:R12 | stm.w r1!, {r1, r3, r4, r5, r8, r11, r12} | may_store",
  ),
  (
    4, 0xe8a01b63U, "t2STMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R5 Reg:R6 Reg:R8 Reg:R9 Reg:R11 Reg:R12 | stm.w r0!, {r0, r1, r5, r6, r8, r9, r11, r12} | may_store",
  ),
  (
    4, 0xe8a153a7U, "t2STMIA_UPD Reg:R1 Reg:R1 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R5 Reg:R7 Reg:R8 Reg:R9 Reg:R12 Reg:LR | stm.w r1!, {r0, r1, r2, r5, r7, r8, r9, r12, lr} | may_store",
  ),
  (
    4, 0xe8a058feU, "t2STMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R11 Reg:R12 Reg:LR | stm.w r0!, {r1, r2, r3, r4, r5, r6, r7, r11, r12, lr} | may_store",
  ),
  (
    4, 0xe8a24ffaU, "t2STMIA_UPD Reg:R2 Reg:R2 Imm:14 Reg:Nil Reg:R1 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:R8 Reg:R9 Reg:R10 Reg:R11 Reg:LR | stm.w r2!, {r1, r3, r4, r5, r6, r7, r8, r9, r10, r11, lr} | may_store",
  ),
  (
    4, 0xf8007b00U, "t2STRB_POST Reg:R0 Reg:R7 Reg:R0 Imm:0 Imm:14 Reg:Nil | strb r7, [r0], #0 | may_store",
  ),
  (
    4, 0xf800cf0dU, "t2STRB_PRE Reg:R0 Reg:R12 Reg:R0 Imm:13 Imm:14 Reg:Nil | strb r12, [r0, #13]! | may_store",
  ),
  (
    4, 0xf880c9d8U, "t2STRBi12 Reg:R12 Reg:R0 Imm:2520 Imm:14 Reg:Nil | strb.w r12, [r0, #2520] | may_store",
  ),
  (
    4, 0xf8036c60U, "t2STRBi8 Reg:R6 Reg:R3 Imm:-96 Imm:14 Reg:Nil | strb r6, [r3, #-96] | may_store",
  ),
  (
    4, 0xf800f000U, "t2STRBs Reg:PC Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | strb.w pc, [r0, r0] | may_store",
  ),
  (
    4, 0xe86f509dU, "t2STRD_POST Reg:PC Reg:R5 Reg:R0 Reg:PC Imm:-628 Imm:14 Reg:Nil | strd r5, r0, [pc], #-628 | affect_cf,may_store",
  ),
  (
    4, 0xe860ee51U, "t2STRD_POST Reg:R0 Reg:LR Reg:LR Reg:R0 Imm:-324 Imm:14 Reg:Nil | strd lr, lr, [r0], #-324 | may_store",
  ),
  (
    4, 0xe96fcd10U, "t2STRD_PRE Reg:PC Reg:R12 Reg:SP Reg:PC Imm:-64 Imm:14 Reg:Nil | strd r12, sp, [pc, #-64]! | affect_cf,may_store",
  ),
  (
    4, 0xe9608aa3U, "t2STRD_PRE Reg:R0 Reg:R8 Reg:R10 Reg:R0 Imm:-652 Imm:14 Reg:Nil | strd r8, r10, [r0, #-652]! | may_store",
  ),
  (
    4, 0xe940ce19U, "t2STRDi8 Reg:R12 Reg:LR Reg:R0 Imm:-100 Imm:14 Reg:Nil | strd r12, lr, [r0, #-100] | may_store",
  ),
  (
    4, 0xe840cf1bU, "t2STREX Reg:PC Reg:R12 Reg:R0 Imm:27 Imm:14 Reg:Nil | strex pc, r12, [r0, #108] | affect_cf,may_load,may_store",
  ),
  (
    4, 0xe84033bbU, "t2STREX Reg:R3 Reg:R3 Reg:R0 Imm:187 Imm:14 Reg:Nil | strex r3, r3, [r0, #748] | may_load,may_store",
  ),
  (
    4, 0xe8c0df70U, "t2STREXD Reg:R0 Reg:SP Reg:PC Reg:R0 Imm:14 Reg:Nil | strexd r0, sp, pc, [r0] | may_store",
  ),
  (
    4, 0xe8c26f52U, "t2STREXH Reg:R2 Reg:R6 Reg:R2 Imm:14 Reg:Nil | strexh r2, r6, [r2] | may_load,may_store",
  ),
  (
    4, 0xf820fbf5U, "t2STRH_POST Reg:R0 Reg:PC Reg:R0 Imm:245 Imm:14 Reg:Nil | strh pc, [r0], #245 | may_store",
  ),
  (
    4, 0xf820af12U, "t2STRH_PRE Reg:R0 Reg:R10 Reg:R0 Imm:18 Imm:14 Reg:Nil | strh r10, [r0, #18]! | may_store",
  ),
  (
    4, 0xf8a026d7U, "t2STRHi12 Reg:R2 Reg:R0 Imm:1751 Imm:14 Reg:Nil | strh.w r2, [r0, #1751] | may_store",
  ),
  (
    4, 0xf820fcc3U, "t2STRHi8 Reg:PC Reg:R0 Imm:-195 Imm:14 Reg:Nil | strh pc, [r0, #-195] | may_store",
  ),
  (
    4, 0xf820e02dU, "t2STRHs Reg:LR Reg:R0 Reg:SP Imm:2 Imm:14 Reg:Nil | strh.w lr, [r0, sp, lsl #2] | may_store",
  ),
  (
    4, 0xf8400b4bU, "t2STR_POST Reg:R0 Reg:R0 Reg:R0 Imm:75 Imm:14 Reg:Nil | str r0, [r0], #75 | may_store",
  ),
  (
    4, 0xf8401f5dU, "t2STR_PRE Reg:R0 Reg:R1 Reg:R0 Imm:93 Imm:14 Reg:Nil | str r1, [r0, #93]! | may_store",
  ),
  (
    4, 0xf8c0396fU, "t2STRi12 Reg:R3 Reg:R0 Imm:2415 Imm:14 Reg:Nil | str.w r3, [r0, #2415] | may_store",
  ),
  (
    4, 0xf8406c00U, "t2STRi8 Reg:R6 Reg:R0 Imm:-2147483648 Imm:14 Reg:Nil | str r6, [r0, #-0] | may_store",
  ),
  (
    4, 0xf840a034U, "t2STRs Reg:R10 Reg:R0 Reg:R4 Imm:3 Imm:14 Reg:Nil | str.w r10, [r0, r4, lsl #3] | may_store",
  ),
  (
    4, 0xf1a045dcU, "t2SUBri Reg:R5 Reg:R0 Imm:1845493760 Imm:14 Reg:Nil Reg:Nil | sub.w r5, r0, #1845493760",
  ),
  (
    4, 0xf1a00f6dU, "t2SUBri Reg:PC Reg:R0 Imm:109 Imm:14 Reg:Nil Reg:Nil | sub.w pc, r0, #109 | affect_cf",
  ),
  (
    4, 0xf1b04e00U, "t2SUBri Reg:LR Reg:R0 Imm:2147483648 Imm:14 Reg:Nil Reg:CPSR | subs.w lr, r0, #2147483648",
  ),
  (
    4, 0xf2a06ab7U, "t2SUBri12 Reg:R10 Reg:R0 Imm:1719 Imm:14 Reg:Nil | subw r10, r0, #1719",
  ),
  (
    4, 0xf2a06feeU, "t2SUBri12 Reg:PC Reg:R0 Imm:1774 Imm:14 Reg:Nil | subw pc, r0, #1774 | affect_cf",
  ),
  (
    4, 0xeba00a00U, "t2SUBrr Reg:R10 Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:Nil | sub.w r10, r0, r0",
  ),
  (
    4, 0xebb18c00U, "t2SUBrr Reg:R12 Reg:R1 Reg:R0 Imm:14 Reg:Nil Reg:CPSR | subs.w r12, r1, r0",
  ),
  (
    4, 0xeba01b13U, "t2SUBrs Reg:R11 Reg:R0 Reg:R3 Imm:35 Imm:14 Reg:Nil Reg:Nil | sub.w r11, r0, r3, lsr #4",
  ),
  (
    4, 0xeba01fedU, "t2SUBrs Reg:PC Reg:R0 Reg:SP Imm:57 Imm:14 Reg:Nil Reg:Nil | sub.w pc, r0, sp, asr #7 | affect_cf",
  ),
  (
    4, 0xebb09b28U, "t2SUBrs Reg:R11 Reg:R0 Reg:R8 Imm:33 Imm:14 Reg:Nil Reg:CPSR | subs.w r11, r0, r8, asr #4",
  ),
  (
    4, 0xf6ad6d00U, "t2SUBspImm12 Reg:SP Reg:SP Imm:3584 Imm:14 Reg:Nil | subw sp, sp, #3584",
  ),
  (
    4, 0xfa40fc94U, "t2SXTAB Reg:R12 Reg:R0 Reg:R4 Imm:1 Imm:14 Reg:Nil | sxtab r12, r0, r4, ror #8",
  ),
  (
    4, 0xfa4cff95U, "t2SXTAB Reg:PC Reg:R12 Reg:R5 Imm:1 Imm:14 Reg:Nil | sxtab pc, r12, r5, ror #8 | affect_cf",
  ),
  (
    4, 0xfa00f699U, "t2SXTAH Reg:R6 Reg:R0 Reg:R9 Imm:1 Imm:14 Reg:Nil | sxtah r6, r0, r9, ror #8",
  ),
  (
    4, 0xfa03ffc5U, "t2SXTAH Reg:PC Reg:R3 Reg:R5 Imm:0 Imm:14 Reg:Nil | sxtah pc, r3, r5 | affect_cf",
  ),
  (
    4, 0xfa4ffc9dU, "t2SXTB Reg:R12 Reg:SP Imm:1 Imm:14 Reg:Nil | sxtb.w r12, sp, ror #8",
  ),
  (
    4, 0xfa4fffe2U, "t2SXTB Reg:PC Reg:R2 Imm:2 Imm:14 Reg:Nil | sxtb.w pc, r2, ror #16 | affect_cf",
  ),
  (
    4, 0xfa0ff1b0U, "t2SXTH Reg:R1 Reg:R0 Imm:3 Imm:14 Reg:Nil | sxth.w r1, r0, ror #24",
  ),
  (
    4, 0xe8d4f000U, "t2TBB Reg:R4 Reg:R0 Imm:14 Reg:Nil | tbb [r4, r0] | indirect,barrier,terminator,affect_cf",
  ),
  (
    4, 0xf0913f46U, "t2TEQri Reg:R1 Imm:1179010630 Imm:14 Reg:Nil | teq.w r1, #1179010630",
  ),
  (4, 0xea948f00U, "t2TEQrr Reg:R4 Reg:R0 Imm:14 Reg:Nil | teq.w r4, r0"),
  (
    4, 0xea900ff1U, "t2TEQrs Reg:R0 Reg:R1 Imm:28 Imm:14 Reg:Nil | teq.w r0, r1, ror #3",
  ),
  (4, 0xf0100fdbU, "t2TSTri Reg:R0 Imm:219 Imm:14 Reg:Nil | tst.w r0, #219"),
  (4, 0xea100f01U, "t2TSTrr Reg:R0 Reg:R1 Imm:14 Reg:Nil | tst.w r0, r1"),
  (
    4, 0xea10ff90U, "t2TSTrs Reg:R0 Reg:R0 Imm:243 Imm:14 Reg:Nil | tst.w r0, r0, lsr #30",
  ),
  (
    4, 0xf3c04600U, "t2UBFX Reg:R6 Reg:R0 Imm:16 Imm:0 Imm:14 Reg:Nil | ubfx r6, r0, #16, #1",
  ),
  (
    4, 0xf3c14f00U, "t2UBFX Reg:PC Reg:R1 Imm:16 Imm:0 Imm:14 Reg:Nil | ubfx pc, r1, #16, #1 | affect_cf",
  ),
  (
    4, 0xfbb4fdf6U, "t2UDIV Reg:SP Reg:R4 Reg:R6 Imm:14 Reg:Nil | udiv sp, r4, r6",
  ),
  (
    4, 0xfbe06600U, "t2UMLAL Reg:R6 Reg:R6 Reg:R0 Reg:R0 Reg:R6 Reg:R6 Imm:14 Reg:Nil | umlal r6, r6, r0, r0",
  ),
  (
    4, 0xfbe0f900U, "t2UMLAL Reg:PC Reg:R9 Reg:R0 Reg:R0 Reg:PC Reg:R9 Imm:14 Reg:Nil | umlal pc, r9, r0, r0 | affect_cf",
  ),
  (
    4, 0xfba01200U, "t2UMULL Reg:R1 Reg:R2 Reg:R0 Reg:R0 Imm:14 Reg:Nil | umull r1, r2, r0, r0",
  ),
  (
    4, 0xfba0f700U, "t2UMULL Reg:PC Reg:R7 Reg:R0 Reg:R0 Imm:14 Reg:Nil | umull pc, r7, r0, r0 | affect_cf",
  ),
  (
    4, 0xfa50f6bbU, "t2UXTAB Reg:R6 Reg:R0 Reg:R11 Imm:3 Imm:14 Reg:Nil | uxtab r6, r0, r11, ror #24",
  ),
  (
    4, 0xfa5afff5U, "t2UXTAB Reg:PC Reg:R10 Reg:R5 Imm:3 Imm:14 Reg:Nil | uxtab pc, r10, r5, ror #24 | affect_cf",
  ),
  (
    4, 0xfa10f0bfU, "t2UXTAH Reg:R0 Reg:R0 Reg:PC Imm:3 Imm:14 Reg:Nil | uxtah r0, r0, pc, ror #24",
  ),
  (
    4, 0xfa10ffb5U, "t2UXTAH Reg:PC Reg:R0 Reg:R5 Imm:3 Imm:14 Reg:Nil | uxtah pc, r0, r5, ror #24 | affect_cf",
  ),
  (
    4, 0xfa5ffd90U, "t2UXTB Reg:SP Reg:R0 Imm:1 Imm:14 Reg:Nil | uxtb.w sp, r0, ror #8",
  ),
  (
    4, 0xfa1ffc82U, "t2UXTH Reg:R12 Reg:R2 Imm:0 Imm:14 Reg:Nil | uxth.w r12, r2",
  ),
  (
    2, 0x4140U, "tADC Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | adcs r0, r0",
  ),
  (2, 0x4400U, "tADDhirr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | add r0, r0"),
  (
    2, 0x4487U, "tADDhirr Reg:PC Reg:PC Reg:R0 Imm:14 Reg:Nil | add pc, r0 | affect_cf",
  ),
  (
    2, 0x1c00U, "tADDi3 Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | adds r0, r0, #0",
  ),
  (
    2, 0x3000U, "tADDi8 Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | adds r0, #0",
  ),
  (2, 0x4468U, "tADDrSP Reg:R0 Reg:SP Reg:R0 Imm:14 Reg:Nil | add r0, sp, r0"),
  (
    2, 0x44efU, "tADDrSP Reg:PC Reg:SP Reg:PC Imm:14 Reg:Nil | add pc, sp, pc | affect_cf",
  ),
  (2, 0xa800U, "tADDrSPi Reg:R0 Reg:SP Imm:0 Imm:14 Reg:Nil | add r0, sp, #0"),
  (
    2, 0x1800U, "tADDrr Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | adds r0, r0, r0",
  ),
  (2, 0xb000U, "tADDspi Reg:SP Reg:SP Imm:0 Imm:14 Reg:Nil | add sp, #0"),
  (2, 0x4485U, "tADDspr Reg:SP Reg:SP Reg:R0 Imm:14 Reg:Nil | add sp, r0"),
  (2, 0xa000U, "tADR Reg:R0 Imm:0 Imm:14 Reg:Nil | adr r0, #0"),
  (
    2, 0x4000U, "tAND Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | ands r0, r0",
  ),
  (
    2, 0x1000U, "tASRri Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | asrs r0, r0, #32",
  ),
  (
    2, 0x4100U, "tASRrr Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | asrs r0, r0",
  ),
  (
    2, 0xe000U, "tB Imm:0 Imm:14 Reg:Nil | b #0 | uncond,barrier,terminator,affect_cf",
  ),
  (
    2, 0x4380U, "tBIC Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | bics r0, r0",
  ),
  (2, 0xbe00U, "tBKPT Imm:0 | bkpt #0"),
  (
    4, 0xf000f4b2U, "tBL Imm:14 Reg:Nil Imm:4196708 | bl #4196708 | call,affect_cf",
  ),
  (
    4, 0xf000e0baU, "tBLXi Imm:14 Reg:Nil Imm:4194676 | blx #4194676 | call,affect_cf",
  ),
  (2, 0x4780U, "tBLXr Imm:14 Reg:Nil Reg:R0 | blx r0 | call,affect_cf"),
  (
    2, 0x4700U, "tBX Reg:R0 Imm:14 Reg:Nil | bx r0 | indirect,barrier,terminator,affect_cf",
  ),
  (2, 0xd000U, "tBcc Imm:0 Imm:0 Reg:CPSR | beq #0 | cond,terminator,affect_cf"),
  (2, 0xb900U, "tCBNZ Reg:R0 Imm:0 | cbnz r0, #0 | cond,terminator,affect_cf"),
  (2, 0xb100U, "tCBZ Reg:R0 Imm:0 | cbz r0, #0 | cond,terminator,affect_cf"),
  (2, 0x42c0U, "tCMNz Reg:R0 Reg:R0 Imm:14 Reg:Nil | cmn r0, r0"),
  (2, 0x4500U, "tCMPhir Reg:R0 Reg:R0 Imm:14 Reg:Nil | cmp r0, r0"),
  (2, 0x2800U, "tCMPi8 Reg:R0 Imm:0 Imm:14 Reg:Nil | cmp r0, #0"),
  (2, 0x4280U, "tCMPr Reg:R0 Reg:R0 Imm:14 Reg:Nil | cmp r0, r0"),
  (2, 0xb670U, "tCPS Imm:3 Imm:0 | cpsid none"),
  (2, 0xb660U, "tCPS Imm:2 Imm:0 | cpsie none"),
  (
    2, 0x4040U, "tEOR Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | eors r0, r0",
  ),
  (2, 0xbf50U, "tHINT Imm:5 Imm:14 Reg:Nil | hint #5 | may_load,may_store"),
  (2, 0xbf00U, "tHINT Imm:0 Imm:14 Reg:Nil | nop | may_load,may_store"),
  (2, 0xbf40U, "tHINT Imm:4 Imm:14 Reg:Nil | sev | may_load,may_store"),
  (2, 0xbf20U, "tHINT Imm:2 Imm:14 Reg:Nil | wfe | may_load,may_store"),
  (2, 0xbf30U, "tHINT Imm:3 Imm:14 Reg:Nil | wfi | may_load,may_store"),
  (2, 0xbf10U, "tHINT Imm:1 Imm:14 Reg:Nil | yield | may_load,may_store"),
  (2, 0xc801U, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 | ldm r0, {r0} | may_load"),
  (
    2, 0xc803U, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 | ldm r0, {r0, r1} | may_load",
  ),
  (
    2, 0xc807U, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 | ldm r0, {r0, r1, r2} | may_load",
  ),
  (
    2, 0xc80fU, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 | ldm r0, {r0, r1, r2, r3} | may_load",
  ),
  (
    2, 0xc81fU, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 | ldm r0, {r0, r1, r2, r3, r4} | may_load",
  ),
  (
    2, 0xc83fU, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 | ldm r0, {r0, r1, r2, r3, r4, r5} | may_load",
  ),
  (
    2, 0xc87fU, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 | ldm r0, {r0, r1, r2, r3, r4, r5, r6} | may_load",
  ),
  (
    2, 0xc8ffU, "tLDMIA Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 | ldm r0, {r0, r1, r2, r3, r4, r5, r6, r7} | may_load",
  ),
  (
    2, 0x7800U, "tLDRBi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrb r0, [r0] | may_load",
  ),
  (
    2, 0x5c00U, "tLDRBr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | ldrb r0, [r0, r0] | may_load",
  ),
  (
    2, 0x8800U, "tLDRHi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldrh r0, [r0] | may_load",
  ),
  (
    2, 0x5a00U, "tLDRHr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | ldrh r0, [r0, r0] | may_load",
  ),
  (
    2, 0x5600U, "tLDRSB Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | ldrsb r0, [r0, r0] | may_load",
  ),
  (
    2, 0x5e00U, "tLDRSH Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | ldrsh r0, [r0, r0] | may_load",
  ),
  (
    2, 0x6800U, "tLDRi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | ldr r0, [r0] | may_load",
  ),
  (
    2, 0x4800U, "tLDRpci Reg:R0 Imm:0 Imm:14 Reg:Nil | ldr r0, [pc, #0] | may_load",
  ),
  (
    2, 0x5800U, "tLDRr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | ldr r0, [r0, r0] | may_load",
  ),
  (
    2, 0x9800U, "tLDRspi Reg:R0 Reg:SP Imm:0 Imm:14 Reg:Nil | ldr r0, [sp] | may_load",
  ),
  (
    2, 0x0040U, "tLSLri Reg:R0 Reg:CPSR Reg:R0 Imm:1 Imm:14 Reg:Nil | lsls r0, r0, #1",
  ),
  (
    2, 0x4080U, "tLSLrr Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | lsls r0, r0",
  ),
  (
    2, 0x0800U, "tLSRri Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | lsrs r0, r0, #32",
  ),
  (
    2, 0x40c0U, "tLSRrr Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | lsrs r0, r0",
  ),
  (2, 0x0000U, "tMOVSr Reg:R0 Reg:R0 | movs r0, r0"),
  (2, 0x2000U, "tMOVi8 Reg:R0 Reg:CPSR Imm:0 Imm:14 Reg:Nil | movs r0, #0"),
  (2, 0x4600U, "tMOVr Reg:R0 Reg:R0 Imm:14 Reg:Nil | mov r0, r0"),
  (2, 0x4687U, "tMOVr Reg:PC Reg:R0 Imm:14 Reg:Nil | mov pc, r0 | affect_cf"),
  (
    2, 0x4340U, "tMUL Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | muls r0, r0, r0",
  ),
  (2, 0x43c0U, "tMVN Reg:R0 Reg:CPSR Reg:R0 Imm:14 Reg:Nil | mvns r0, r0"),
  (
    2, 0x4300U, "tORR Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | orrs r0, r0",
  ),
  (2, 0xbd00U, "tPOP Imm:14 Reg:Nil Reg:PC | pop {pc} | affect_cf,may_load"),
  (
    2, 0xbd01U, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:PC | pop {r0, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd03U, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:PC | pop {r0, r1, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd07U, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:PC | pop {r0, r1, r2, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd0fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:PC | pop {r0, r1, r2, r3, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd1fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:PC | pop {r0, r1, r2, r3, r4, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd3fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:PC | pop {r0, r1, r2, r3, r4, r5, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbd7fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:PC | pop {r0, r1, r2, r3, r4, r5, r6, pc} | affect_cf,may_load",
  ),
  (
    2, 0xbdffU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:PC | pop {r0, r1, r2, r3, r4, r5, r6, r7, pc} | affect_cf,may_load",
  ),
  (2, 0xbc01U, "tPOP Imm:14 Reg:Nil Reg:R0 | pop {r0} | may_load"),
  (2, 0xbc03U, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 | pop {r0, r1} | may_load"),
  (
    2, 0xbc07U, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 | pop {r0, r1, r2} | may_load",
  ),
  (
    2, 0xbc0fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 | pop {r0, r1, r2, r3} | may_load",
  ),
  (
    2, 0xbc1fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 | pop {r0, r1, r2, r3, r4} | may_load",
  ),
  (
    2, 0xbc3fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 | pop {r0, r1, r2, r3, r4, r5} | may_load",
  ),
  (
    2, 0xbc7fU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 | pop {r0, r1, r2, r3, r4, r5, r6} | may_load",
  ),
  (
    2, 0xbcffU, "tPOP Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 | pop {r0, r1, r2, r3, r4, r5, r6, r7} | may_load",
  ),
  (2, 0xb401U, "tPUSH Imm:14 Reg:Nil Reg:R0 | push {r0} | may_store"),
  (2, 0xb403U, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 | push {r0, r1} | may_store"),
  (
    2, 0xb407U, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 | push {r0, r1, r2} | may_store",
  ),
  (
    2, 0xb40fU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 | push {r0, r1, r2, r3} | may_store",
  ),
  (
    2, 0xb41fU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 | push {r0, r1, r2, r3, r4} | may_store",
  ),
  (
    2, 0xb43fU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 | push {r0, r1, r2, r3, r4, r5} | may_store",
  ),
  (
    2, 0xb47fU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 | push {r0, r1, r2, r3, r4, r5, r6} | may_store",
  ),
  (
    2, 0xb4ffU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 | push {r0, r1, r2, r3, r4, r5, r6, r7} | may_store",
  ),
  (
    2, 0xb5ffU, "tPUSH Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 Reg:LR | push {r0, r1, r2, r3, r4, r5, r6, r7, lr} | may_store",
  ),
  (2, 0xba00U, "tREV Reg:R0 Reg:R0 Imm:14 Reg:Nil | rev r0, r0"),
  (2, 0xba40U, "tREV16 Reg:R0 Reg:R0 Imm:14 Reg:Nil | rev16 r0, r0"),
  (2, 0xbac0U, "tREVSH Reg:R0 Reg:R0 Imm:14 Reg:Nil | revsh r0, r0"),
  (
    2, 0x41c0U, "tROR Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | rors r0, r0",
  ),
  (2, 0x4240U, "tRSB Reg:R0 Reg:CPSR Reg:R0 Imm:14 Reg:Nil | rsbs r0, r0, #0"),
  (
    2, 0x4180U, "tSBC Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | sbcs r0, r0",
  ),
  (2, 0xb650U, "tSETEND Imm:0 | setend le"),
  (
    2, 0xc001U, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 | stm r0!, {r0} | may_store",
  ),
  (
    2, 0xc003U, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 | stm r0!, {r0, r1} | may_store",
  ),
  (
    2, 0xc007U, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 | stm r0!, {r0, r1, r2} | may_store",
  ),
  (
    2, 0xc00fU, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 | stm r0!, {r0, r1, r2, r3} | may_store",
  ),
  (
    2, 0xc01fU, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 | stm r0!, {r0, r1, r2, r3, r4} | may_store",
  ),
  (
    2, 0xc03fU, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 | stm r0!, {r0, r1, r2, r3, r4, r5} | may_store",
  ),
  (
    2, 0xc07fU, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 | stm r0!, {r0, r1, r2, r3, r4, r5, r6} | may_store",
  ),
  (
    2, 0xc0ffU, "tSTMIA_UPD Reg:R0 Reg:R0 Imm:14 Reg:Nil Reg:R0 Reg:R1 Reg:R2 Reg:R3 Reg:R4 Reg:R5 Reg:R6 Reg:R7 | stm r0!, {r0, r1, r2, r3, r4, r5, r6, r7} | may_store",
  ),
  (
    2, 0x7000U, "tSTRBi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | strb r0, [r0] | may_store",
  ),
  (
    2, 0x5400U, "tSTRBr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | strb r0, [r0, r0] | may_store",
  ),
  (
    2, 0x8000U, "tSTRHi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | strh r0, [r0] | may_store",
  ),
  (
    2, 0x5200U, "tSTRHr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | strh r0, [r0, r0] | may_store",
  ),
  (
    2, 0x6000U, "tSTRi Reg:R0 Reg:R0 Imm:0 Imm:14 Reg:Nil | str r0, [r0] | may_store",
  ),
  (
    2, 0x5000U, "tSTRr Reg:R0 Reg:R0 Reg:R0 Imm:14 Reg:Nil | str r0, [r0, r0] | may_store",
  ),
  (
    2, 0x9000U, "tSTRspi Reg:R0 Reg:SP Imm:0 Imm:14 Reg:Nil | str r0, [sp] | may_store",
  ),
  (
    2, 0x1e00U, "tSUBi3 Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | subs r0, r0, #0",
  ),
  (
    2, 0x3800U, "tSUBi8 Reg:R0 Reg:CPSR Reg:R0 Imm:0 Imm:14 Reg:Nil | subs r0, #0",
  ),
  (
    2, 0x1a00U, "tSUBrr Reg:R0 Reg:CPSR Reg:R0 Reg:R0 Imm:14 Reg:Nil | subs r0, r0, r0",
  ),
  (2, 0xb080U, "tSUBspi Reg:SP Reg:SP Imm:0 Imm:14 Reg:Nil | sub sp, #0"),
  (2, 0xdf00U, "tSVC Imm:0 Imm:14 Reg:Nil | svc #0 | call,affect_cf"),
  (2, 0xb240U, "tSXTB Reg:R0 Reg:R0 Imm:14 Reg:Nil | sxtb r0, r0"),
  (2, 0xb200U, "tSXTH Reg:R0 Reg:R0 Imm:14 Reg:Nil | sxth r0, r0"),
  (2, 0xdefeU, "tTRAP | trap"),
  (2, 0x4200U, "tTST Reg:R0 Reg:R0 Imm:14 Reg:Nil | tst r0, r0"),
  (2, 0xde00U, "tUDF Imm:0 | udf #0 | may_load,may_store"),
  (2, 0xb2c0U, "tUXTB Reg:R0 Reg:R0 Imm:14 Reg:Nil | uxtb r0, r0"),
  (2, 0xb280U, "tUXTH Reg:R0 Reg:R0 Imm:14 Reg:Nil | uxth r0, r0"),
  (2, 0xdef9U, "t__brkdiv0 | __brkdiv0 | terminator,may_load,may_store"),
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
/// The little-endian bytes of a sample.
fn sample_bytes(size : Int, value : UInt) -> Bytes {
  let halves = if size == 2 { [value] } else { [value >> 16, value & 0xFFFF] }
  let bytes = []
  for h in halves {
    bytes.push(h.to_byte())
    bytes.push((h >> 8).to_byte())
  }
  Bytes::from_array(bytes)
}

///|
test "decode: every sample decodes like llvm-mc" {
  let names : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (size, value, expected) = sample
    guard @thumb.decode_t32(sample_bytes(size, value), addr=0x1000UL)
      is Decoded(insn) else {
      fail("0x\{value.to_string(radix=16)}: not decoded, expected \{expected}")
    }
    assert_eq(render_llvm(insn), expected)
    assert_eq(insn.size, size)
    names[insn.name] = ()
  }
  // the number of samples and of distinct LLVM opcodes they cover
  inspect(llvm_samples.length(), content="630")
  inspect(names.length(), content="265")
}

///|
/// An instruction sequence with IT blocks, decoded in order by
/// `t32_decoder` as LLVM does (the expected lines are LLVM 22's).
test "decode: IT blocks predicate the instructions like llvm-mc" {
  let code : Bytes = b"\x1c\xbf\x01\xf1\x01\x00\x08\x68\x70\x47\x00\xbf\x0c\xbf\x01\x20\x02\x20\x70\x47\x1a\xbf\x00\xbf\x01\xb1\x00\xbd"
  let decoder = @thumb.t32_decoder()
  let target = @core_theory.Target::lookup("armv7+le").unwrap()
  let ctx = @mc.Context::create(
    target,
    encoding=@core_theory.Language::llvm_t32(),
  )
  let lines = []
  for off = 0; off < code.length(); {
    guard decoder.decode(ctx, code[off:], off.to_uint64()) is Decoded(insn) else {
      fail("offset \{off}: not decoded")
    }
    lines.push(render_llvm(insn))
    continue off + insn.size
  }
  inspect(
    lines.join("\n"),
    content=(
      #|t2IT Imm:1 Imm:4 | itt ne
      #|t2ADDri Reg:R0 Reg:R1 Imm:1 Imm:1 Reg:CPSR Reg:Nil | addne.w r0, r1, #1
      #|tLDRi Reg:R0 Reg:R1 Imm:0 Imm:1 Reg:CPSR | ldrne r0, [r1] | may_load
      #|tBX Reg:LR Imm:14 Reg:Nil | bx lr | indirect,barrier,terminator,affect_cf
      #|tHINT Imm:0 Imm:14 Reg:Nil | nop | may_load,may_store
      #|t2IT Imm:0 Imm:12 | ite eq
      #|tMOVi8 Reg:R0 Reg:Nil Imm:1 Imm:0 Reg:CPSR | moveq r0, #1
      #|tMOVi8 Reg:R0 Reg:Nil Imm:2 Imm:1 Reg:CPSR | movne r0, #2
      #|tBX Reg:LR Imm:14 Reg:Nil | bx lr | indirect,barrier,terminator,affect_cf
      #|t2IT Imm:1 Imm:6 | itte ne
      #|tHINT Imm:0 Imm:1 Reg:CPSR | nopne | may_load,may_store
      #|tCBZ Reg:R1 Imm:0 | cbz r1, #0 | cond,terminator,affect_cf
      #|tPOP Imm:0 Reg:CPSR Reg:PC | popeq {pc} | affect_cf,may_load
    ),
  )
}

///|
/// Nested IT blocks (the enclosing block resumes after the inner one), the
/// `<und>` "else" condition of an `AL` block and an IT instruction as the
/// last instruction of a block, as LLVM 22 decodes them.
test "decode: nested IT blocks like llvm-mc" {
  let code : Bytes = b"\xbf\xbf\x09\xab\x2b\xbf\x8b\x67\x8b\x3f\x24\x09\x01\xf6\xae\x4e\xcd\x3f\x50\x84\xf9\xbf\x63\x62\x1a\x61\xb4\x10\x08\xbf\x00\x00"
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
      #|t2IT Imm:11 Imm:1 | itttt lt
      #|tADDrSPi Reg:R3 Reg:SP Imm:9 Imm:11 Reg:CPSR | addlt r3, sp, #36
      #|t2IT Imm:2 Imm:11 | itete hs
      #|tSTRi Reg:R3 Reg:R1 Imm:30 Imm:2 Reg:CPSR | strhs r3, [r1, #120] | may_store
      #|tSUBi8 Reg:R7 Reg:Nil Reg:R7 Imm:139 Imm:3 Reg:CPSR | sublo r7, #139
      #|tLSRri Reg:R4 Reg:Nil Reg:R4 Imm:4 Imm:2 Reg:CPSR | lsrhs r4, r4, #4
      #|t2ADDri12 Reg:LR Reg:R1 Imm:3246 Imm:3 Reg:CPSR | addwlo lr, r1, #3246
      #|tSUBi8 Reg:R7 Reg:Nil Reg:R7 Imm:205 Imm:11 Reg:CPSR | sublt r7, #205
      #|tSTRHi Reg:R0 Reg:R2 Imm:17 Imm:11 Reg:CPSR | strhlt r0, [r2, #34] | may_store
      #|t2IT Imm:14 Imm:9 | itett al
      #|tSTRi Reg:R3 Reg:R4 Imm:9 Imm:14 Reg:Nil | str r3, [r4, #36] | may_store
      #|tSTRi Reg:R2 Reg:R3 Imm:4 Imm:15 Reg:CPSR | str<und> r2, [r3, #16] | may_store
      #|tASRri Reg:R4 Reg:Nil Reg:R6 Imm:2 Imm:14 Reg:Nil | asr r4, r6, #2
      #|t2IT Imm:0 Imm:8 | it eq
      #|tMOVSr Reg:R0 Reg:R0 | movs r0, r0
    ),
  )
}
