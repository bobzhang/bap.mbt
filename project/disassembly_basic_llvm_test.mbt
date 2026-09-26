// Per-opcode decoding tests of the x86 / x86-64 Basic `llvm` decoder.
// Every expected line (the size, the LLVM opcode name, the MCInst
// operands, the AT&T assembly and the MCInstrDesc kinds) is the
// output of LLVM 22's `llvm-mc -disassemble -show-inst` (as printed by
// the MC disassembler and instruction printer for the i386-linux-gnu and
// x86_64-linux-gnu triples) for the instruction bytes. The samples are
// the first instruction of every opcode in compiler output (clang -O0,
// -O2, -Os, -march=x86-64-v3, -msse4.2) and macOS system binaries, the
// byte sequences of the former fixture tests, and samples of the opcodes
// the Basic lifter handles. Operands: `Reg:` is LLVM's NoRegister
// (`Nil` in the port), kinds omit LLVM's `branch` flag.

///|
let x86_llvm_samples : Array[(String, String, String)] = [
  (
    "x86", "8b442408", "4 MOV32rm Reg:EAX Reg:ESP Imm:1 Reg: Imm:8 Reg: | movl 8(%esp), %eax | may_load",
  ),
  (
    "x86", "8d0440", "3 LEA32r Reg:EAX Reg:EAX Imm:2 Reg:EAX Imm:0 Reg: | leal (%eax,%eax,2), %eax | ",
  ),
  (
    "x86", "02442404", "4 ADD8rm Reg:AL Reg:AL Reg:ESP Imm:1 Reg: Imm:4 Reg: | addb 4(%esp), %al | may_load",
  ),
  ("x86", "c3", "1 RET32  | retl | return,barrier,terminator,affect_cf"),
  (
    "x86", "0fbe442404", "5 MOVSX32rm8 Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | movsbl 4(%esp), %eax | may_load",
  ),
  ("x86", "6699", "2 CWD  | cwtd | "),
  ("x86", "66f7f9", "3 IDIV16r Reg:CX | idivw %cx | "),
  (
    "x86", "0fb7442404", "5 MOVZX32rm16 Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | movzwl 4(%esp), %eax | may_load",
  ),
  ("x86", "660fafc8", "4 IMUL16rr Reg:CX Reg:CX Reg:AX | imulw %ax, %cx | "),
  ("x86", "c1e803", "3 SHR32ri Reg:EAX Reg:EAX Imm:3 | shrl $3, %eax | "),
  ("x86", "01c8", "2 ADD32rr Reg:EAX Reg:EAX Reg:ECX | addl %ecx, %eax | "),
  (
    "x86", "0fb64c2408", "5 MOVZX32rm8 Reg:ECX Reg:ESP Imm:1 Reg: Imm:8 Reg: | movzbl 8(%esp), %ecx | may_load",
  ),
  (
    "x86", "0fbf442404", "5 MOVSX32rm16 Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | movswl 4(%esp), %eax | may_load",
  ),
  ("x86", "89c2", "2 MOV32rr Reg:EDX Reg:EAX | movl %eax, %edx | "),
  ("x86", "d3e2", "2 SHL32rCL Reg:EDX Reg:EDX | shll %cl, %edx | "),
  ("x86", "31d0", "2 XOR32rr Reg:EAX Reg:EAX Reg:EDX | xorl %edx, %eax | "),
  ("x86", "d3c0", "2 ROL32rCL Reg:EAX Reg:EAX | roll %cl, %eax | "),
  ("x86", "99", "1 CDQ  | cltd | "),
  (
    "x86", "f77c2408", "4 IDIV32m Reg:ESP Imm:1 Reg: Imm:8 Reg: | idivl 8(%esp) | may_load",
  ),
  (
    "x86", "f7742408", "4 DIV32m Reg:ESP Imm:1 Reg: Imm:8 Reg: | divl 8(%esp) | may_load",
  ),
  ("x86", "56", "1 PUSH32r Reg:ESI | pushl %esi | may_store"),
  ("x86", "f7e6", "2 MUL32r Reg:ESI | mull %esi | "),
  (
    "x86", "0faf4c240c", "5 IMUL32rm Reg:ECX Reg:ECX Reg:ESP Imm:1 Reg: Imm:12 Reg: | imull 12(%esp), %ecx | may_load",
  ),
  ("x86", "5e", "1 POP32r Reg:ESI | popl %esi | may_load"),
  ("x86", "83ec18", "3 SUB32ri8 Reg:ESP Reg:ESP Imm:24 | subl $24, %esp | "),
  ("x86", "e800000000", "5 CALLpcrel32 Imm:0 | calll 0 | call,affect_cf"),
  ("x86", "81c303000000", "6 ADD32ri Reg:EBX Reg:EBX Imm:3 | addl $3, %ebx | "),
  (
    "x86", "0f28442420", "5 MOVAPSrm Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:32 Reg: | movaps 32(%esp), %xmm0 | may_load",
  ),
  (
    "x86", "0f110424", "4 MOVUPSmr Reg:ESP Imm:1 Reg: Imm:0 Reg: Reg:XMM0 | movups %xmm0, (%esp) | may_store",
  ),
  ("x86", "83c418", "3 ADD32ri8 Reg:ESP Reg:ESP Imm:24 | addl $24, %esp | "),
  ("x86", "c1f91f", "3 SAR32ri Reg:ECX Reg:ECX Imm:31 | sarl $31, %ecx | "),
  ("x86", "11da", "2 ADC32rr Reg:EDX Reg:EDX Reg:EBX | adcl %ebx, %edx | "),
  (
    "x86", "0344240c", "4 ADD32rm Reg:EAX Reg:EAX Reg:ESP Imm:1 Reg: Imm:12 Reg: | addl 12(%esp), %eax | may_load",
  ),
  ("x86", "0f92c2", "3 SETCCr Reg:DL Imm:2 | setb %dl | "),
  (
    "x86", "3b44240c", "4 CMP32rm Reg:EAX Reg:ESP Imm:1 Reg: Imm:12 Reg: | cmpl 12(%esp), %eax | may_load",
  ),
  (
    "x86", "1b442410", "4 SBB32rm Reg:EAX Reg:EAX Reg:ESP Imm:1 Reg: Imm:16 Reg: | sbbl 16(%esp), %eax | may_load",
  ),
  ("x86", "0fb6c0", "3 MOVZX32rr8 Reg:EAX Reg:AL | movzbl %al, %eax | "),
  (
    "x86", "837c240400", "5 CMP32mi8 Reg:ESP Imm:1 Reg: Imm:4 Reg: Imm:0 | cmpl $0, 4(%esp) | may_load",
  ),
  (
    "x86", "0f44c8", "3 CMOV32rr Reg:ECX Reg:ECX Reg:EAX Imm:4 | cmovel %eax, %ecx | ",
  ),
  ("x86", "d1e9", "2 SHR32r1 Reg:ECX Reg:ECX | shrl %ecx | "),
  (
    "x86", "81e155555555", "6 AND32ri Reg:ECX Reg:ECX Imm:1431655765 | andl $1431655765, %ecx | ",
  ),
  ("x86", "29c8", "2 SUB32rr Reg:EAX Reg:EAX Reg:ECX | subl %ecx, %eax | "),
  ("x86", "2533333333", "5 AND32i32 Imm:858993459 | andl $858993459, %eax | "),
  (
    "x86", "69c101010101", "6 IMUL32rri Reg:EAX Reg:ECX Imm:16843009 | imull $16843009, %ecx, %eax | ",
  ),
  ("x86", "83c801", "3 OR32ri8 Reg:EAX Reg:EAX Imm:1 | orl $1, %eax | "),
  ("x86", "0fbdc0", "3 BSR32rr Reg:EAX Reg:EAX Reg:EAX | bsrl %eax, %eax | "),
  ("x86", "83f01f", "3 XOR32ri8 Reg:EAX Reg:EAX Imm:31 | xorl $31, %eax | "),
  ("x86", "0fc8", "2 BSWAP32r Reg:EAX Reg:EAX | bswapl %eax | "),
  ("x86", "66c1c008", "4 ROL16ri Reg:AX Reg:AX Imm:8 | rolw $8, %ax | "),
  ("x86", "f7d8", "2 NEG32r Reg:EAX Reg:EAX | negl %eax | "),
  (
    "x86", "2b442404", "4 SUB32rm Reg:EAX Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | subl 4(%esp), %eax | may_load",
  ),
  ("x86", "f7d0", "2 NOT32r Reg:EAX Reg:EAX | notl %eax | "),
  ("x86", "83e107", "3 AND32ri8 Reg:ECX Reg:ECX Imm:7 | andl $7, %ecx | "),
  ("x86", "c1e611", "3 SHL32ri Reg:ESI Reg:ESI Imm:17 | shll $17, %esi | "),
  ("x86", "09fa", "2 OR32rr Reg:EDX Reg:EDX Reg:EDI | orl %edi, %edx | "),
  (
    "x86", "8910", "2 MOV32mr Reg:EAX Imm:1 Reg: Imm:0 Reg: Reg:EDX | movl %edx, (%eax) | may_store",
  ),
  (
    "x86", "b8ffffffff", "5 MOV32ri Reg:EAX Imm:4294967295 | movl $4294967295, %eax | ",
  ),
  ("x86", "83fa07", "3 CMP32ri8 Reg:EDX Imm:7 | cmpl $7, %edx | "),
  ("x86", "7707", "2 JCC_1 Imm:7 Imm:7 | ja 7 | cond,terminator,affect_cf"),
  (
    "x86", "ff10", "2 CALL32m Reg:EAX Imm:1 Reg: Imm:0 Reg: | calll *(%eax) | call,affect_cf,may_load",
  ),
  (
    "x86", "c744241c07000000", "8 MOV32mi Reg:ESP Imm:1 Reg: Imm:28 Reg: Imm:7 | movl $7, 28(%esp) | may_store",
  ),
  ("x86", "40", "1 INC32r_alt Reg:EAX Reg:EAX | incl %eax | "),
  ("x86", "85c9", "2 TEST32rr Reg:ECX Reg:ECX | testl %ecx, %ecx | "),
  (
    "x86", "0f8ec8000000", "6 JCC_4 Imm:200 Imm:14 | jle 200 | cond,terminator,affect_cf",
  ),
  (
    "x86", "660fefc0", "4 PXORrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | pxor %xmm0, %xmm0 | ",
  ),
  (
    "x86", "660f6f8f00000000", "8 MOVDQArm Reg:XMM1 Reg:EDI Imm:1 Reg: Imm:0 Reg: | movdqa (%edi), %xmm1 | may_load",
  ),
  (
    "x86", "0f1f840000000000", "8 NOOPL Reg:EAX Imm:1 Reg:EAX Imm:0 Reg: | nopl (%eax,%eax) | ",
  ),
  (
    "x86", "f30f6f2c82", "5 MOVDQUrm Reg:XMM5 Reg:EDX Imm:4 Reg:EAX Imm:0 Reg: | movdqu (%edx,%eax,4), %xmm5 | may_load",
  ),
  (
    "x86", "660f70f5f5", "5 PSHUFDri Reg:XMM6 Reg:XMM5 Imm:245 | pshufd $245, %xmm5, %xmm6 | ",
  ),
  (
    "x86", "660ff4fe", "4 PMULUDQrr Reg:XMM7 Reg:XMM7 Reg:XMM6 | pmuludq %xmm6, %xmm7 | ",
  ),
  ("x86", "660f6ff1", "4 MOVDQArr Reg:XMM6 Reg:XMM1 | movdqa %xmm1, %xmm6 | "),
  (
    "x86", "660ffef2", "4 PADDDrr Reg:XMM6 Reg:XMM6 Reg:XMM2 | paddd %xmm2, %xmm6 | ",
  ),
  (
    "x86", "660f62ef", "4 PUNPCKLDQrr Reg:XMM5 Reg:XMM5 Reg:XMM7 | punpckldq %xmm7, %xmm5 | ",
  ),
  ("x86", "39c6", "2 CMP32rr Reg:ESI Reg:EAX | cmpl %eax, %esi | "),
  ("x86", "660f7ec0", "4 MOVPDI2DIrr Reg:EAX Reg:XMM0 | movd %xmm0, %eax | "),
  (
    "x86", "eb0d", "2 JMP_1 Imm:13 | jmp 13 | uncond,barrier,terminator,affect_cf",
  ),
  ("x86", "0faffe", "3 IMUL32rr Reg:EDI Reg:EDI Reg:ESI | imull %esi, %edi | "),
  ("x86", "08df", "2 OR8rr Reg:BH Reg:BH Reg:BL | orb %bl, %bh | "),
  (
    "x86", "66662e0f1f840000000000", "11 NOOPW Reg:EAX Imm:1 Reg:EAX Imm:0 Reg:CS | nopw %cs:(%eax,%eax) | ",
  ),
  (
    "x86", "0f10049e", "4 MOVUPSrm Reg:XMM0 Reg:ESI Imm:4 Reg:EBX Imm:0 Reg: | movups (%esi,%ebx,4), %xmm0 | may_load",
  ),
  (
    "x86", "0f58d2", "3 ADDPSrr Reg:XMM2 Reg:XMM2 Reg:XMM2 | addps %xmm2, %xmm2 | ",
  ),
  ("x86", "a801", "2 TEST8i8 Imm:1 | testb $1, %al | "),
  (
    "x86", "f30f1004ba", "5 MOVSSrm Reg:XMM0 Reg:EDX Imm:4 Reg:EDI Imm:0 Reg: | movss (%edx,%edi,4), %xmm0 | may_load",
  ),
  (
    "x86", "f30f58c0", "4 ADDSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | addss %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f30f5804be", "5 ADDSSrm_Int Reg:XMM0 Reg:XMM0 Reg:ESI Imm:4 Reg:EDI Imm:0 Reg: | addss (%esi,%edi,4), %xmm0 | may_load",
  ),
  (
    "x86", "f30f1104b9", "5 MOVSSmr Reg:ECX Imm:4 Reg:EDI Imm:0 Reg: Reg:XMM0 | movss %xmm0, (%ecx,%edi,4) | may_store",
  ),
  (
    "x86", "660f57c0", "4 XORPDrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | xorpd %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f20f1014da", "5 MOVSDrm Reg:XMM2 Reg:EDX Imm:8 Reg:EBX Imm:0 Reg: | movsd (%edx,%ebx,8), %xmm2 | may_load",
  ),
  (
    "x86", "f20f5914de", "5 MULSDrm_Int Reg:XMM2 Reg:XMM2 Reg:ESI Imm:8 Reg:EBX Imm:0 Reg: | mulsd (%esi,%ebx,8), %xmm2 | may_load",
  ),
  (
    "x86", "f20f58d0", "4 ADDSDrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 | addsd %xmm0, %xmm2 | ",
  ),
  ("x86", "90", "1 NOOP  | nop | "),
  (
    "x86", "f20f110424", "5 MOVSDmr Reg:ESP Imm:1 Reg: Imm:0 Reg: Reg:XMM0 | movsd %xmm0, (%esp) | may_store",
  ),
  (
    "x86", "dd0424", "3 LD_F64m Reg:ESP Imm:1 Reg: Imm:0 Reg: | fldl (%esp) | may_load",
  ),
  ("x86", "0f28d1", "3 MOVAPSrr Reg:XMM2 Reg:XMM1 | movaps %xmm1, %xmm2 | "),
  (
    "x86", "f30f5ed0", "4 DIVSSrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 | divss %xmm0, %xmm2 | ",
  ),
  (
    "x86", "f30f5dc8", "4 MINSSrr_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 | minss %xmm0, %xmm1 | ",
  ),
  (
    "x86", "f30f5cd1", "4 SUBSSrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM1 | subss %xmm1, %xmm2 | ",
  ),
  (
    "x86", "d90424", "3 LD_F32m Reg:ESP Imm:1 Reg: Imm:0 Reg: | flds (%esp) | may_load",
  ),
  ("x86", "660f2ec1", "4 UCOMISDrr Reg:XMM0 Reg:XMM1 | ucomisd %xmm1, %xmm0 | "),
  ("x86", "660f28d0", "4 MOVAPDrr Reg:XMM2 Reg:XMM0 | movapd %xmm0, %xmm2 | "),
  (
    "x86", "f20f5cd1", "4 SUBSDrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM1 | subsd %xmm1, %xmm2 | ",
  ),
  (
    "x86", "f20f5ed0", "4 DIVSDrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 | divsd %xmm0, %xmm2 | ",
  ),
  (
    "x86", "f20f59c1", "4 MULSDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | mulsd %xmm1, %xmm0 | ",
  ),
  (
    "x86", "f30f2c442404", "6 CVTTSS2SIrm_Int Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | cvttss2si 4(%esp), %eax | may_load",
  ),
  (
    "x86", "df6c2410", "4 ILD_F64m Reg:ESP Imm:1 Reg: Imm:16 Reg: | fildll 16(%esp) | may_load",
  ),
  (
    "x86", "dd1c24", "3 ST_FP64m Reg:ESP Imm:1 Reg: Imm:0 Reg: | fstpl (%esp) | may_store",
  ),
  (
    "x86", "f20f5ac0", "4 CVTSD2SSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | cvtsd2ss %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f20f2cc8", "4 CVTTSD2SIrr_Int Reg:ECX Reg:XMM0 | cvttsd2si %xmm0, %ecx | ",
  ),
  (
    "x86", "f20f5c8000000000", "8 SUBSDrm_Int Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | subsd (%eax), %xmm0 | may_load",
  ),
  ("x86", "21d0", "2 AND32rr Reg:EAX Reg:EAX Reg:EDX | andl %edx, %eax | "),
  (
    "x86", "db6c2410", "4 LD_F80m Reg:ESP Imm:1 Reg: Imm:16 Reg: | fldt 16(%esp) | may_load",
  ),
  ("x86", "dcc9", "2 MUL_FrST0 Reg:ST1 | fmul %st, %st(1) | "),
  ("x86", "dec1", "2 ADD_FPrST0 Reg:ST1 | faddp %st, %st(1) | "),
  (
    "x86", "c20400", "3 RETI32 Imm:4 | retl $4 | return,barrier,terminator,affect_cf",
  ),
  (
    "x86", "807c010100", "5 CMP8mi Reg:ECX Imm:1 Reg:EAX Imm:1 Reg: Imm:0 | cmpb $0, 1(%ecx,%eax) | may_load",
  ),
  (
    "x86", "e97c000000", "5 JMP_4 Imm:124 | jmp 124 | uncond,barrier,terminator,affect_cf",
  ),
  ("x86", "660f6ec7", "4 MOVDI2PDIrr Reg:XMM0 Reg:EDI | movd %edi, %xmm0 | "),
  (
    "x86", "660f60c0", "4 PUNPCKLBWrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | punpcklbw %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f20f70c000", "5 PSHUFLWri Reg:XMM0 Reg:XMM0 Imm:0 | pshuflw $0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f30f7f0410", "5 MOVDQUmr Reg:EAX Imm:1 Reg:EDX Imm:0 Reg: Reg:XMM0 | movdqu %xmm0, (%eax,%edx) | may_store",
  ),
  ("x86", "f6c21c", "3 TEST8ri Reg:DL Imm:28 | testb $28, %dl | "),
  (
    "x86", "660f7e0430", "5 MOVPDI2DImr Reg:EAX Imm:1 Reg:ESI Imm:0 Reg: Reg:XMM0 | movd %xmm0, (%eax,%esi) | may_store",
  ),
  (
    "x86", "3954241c", "4 CMP32mr Reg:ESP Imm:1 Reg: Imm:28 Reg: Reg:EDX | cmpl %edx, 28(%esp) | may_load",
  ),
  (
    "x86", "880c13", "3 MOV8mr Reg:EBX Imm:1 Reg:EDX Imm:0 Reg: Reg:CL | movb %cl, (%ebx,%edx) | may_store",
  ),
  ("x86", "84c0", "2 TEST8rr Reg:AL Reg:AL | testb %al, %al | "),
  (
    "x86", "3a01", "2 CMP8rm Reg:AL Reg:ECX Imm:1 Reg: Imm:0 Reg: | cmpb (%ecx), %al | may_load",
  ),
  ("x86", "f0", "1 LOCK_PREFIX  | lock | "),
  (
    "x86", "830103", "3 ADD32mi8 Reg:ECX Imm:1 Reg: Imm:0 Reg: Imm:3 | addl $3, (%ecx) | may_load,may_store",
  ),
  (
    "x86", "8701", "2 XCHG32rm Reg:EAX Reg:EAX Reg:ECX Imm:1 Reg: Imm:0 Reg: | xchgl %eax, (%ecx) | may_load,may_store",
  ),
  (
    "x86", "0fb111", "3 CMPXCHG32rm Reg:ECX Imm:1 Reg: Imm:0 Reg: Reg:EDX | cmpxchgl %edx, (%ecx) | may_load,may_store",
  ),
  ("x86", "6a05", "2 PUSH32i8 Imm:5 | pushl $5 | may_store"),
  ("x86", "0fa3d1", "3 BT32rr Reg:ECX Reg:EDX | btl %edx, %ecx | "),
  ("x86", "0fabc8", "3 BTS32rr Reg:EAX Reg:EAX Reg:ECX | btsl %ecx, %eax | "),
  (
    "x86", "0fa5d6", "3 SHLD32rrCL Reg:ESI Reg:ESI Reg:EDX | shldl %cl, %edx, %esi | ",
  ),
  ("x86", "80e13f", "3 AND8ri Reg:CL Reg:CL Imm:63 | andb $63, %cl | "),
  ("x86", "b540", "2 MOV8ri Reg:CH Imm:64 | movb $64, %ch | "),
  ("x86", "28cd", "2 SUB8rr Reg:CH Reg:CH Reg:CL | subb %cl, %ch | "),
  ("x86", "88e9", "2 MOV8rr Reg:CL Reg:CH | movb %ch, %cl | "),
  ("x86", "d3ea", "2 SHR32rCL Reg:EDX Reg:EDX | shrl %cl, %edx | "),
  (
    "x86", "0fade8", "3 SHRD32rrCL Reg:EAX Reg:EAX Reg:EBP | shrdl %cl, %ebp, %eax | ",
  ),
  (
    "x86", "c644240101", "5 MOV8mi Reg:ESP Imm:1 Reg: Imm:1 Reg: Imm:1 | movb $1, 1(%esp) | may_store",
  ),
  (
    "x86", "660fdbd0", "4 PANDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | pand %xmm0, %xmm2 | ",
  ),
  (
    "x86", "660f76d0", "4 PCMPEQDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | pcmpeqd %xmm0, %xmm2 | ",
  ),
  ("x86", "4a", "1 DEC32r_alt Reg:EDX Reg:EDX | decl %edx | "),
  (
    "x86", "f6042401", "4 TEST8mi Reg:ESP Imm:1 Reg: Imm:0 Reg: Imm:1 | testb $1, (%esp) | may_load",
  ),
  (
    "x86", "66331c56", "4 XOR16rm Reg:BX Reg:BX Reg:ESI Imm:2 Reg:EDX Imm:0 Reg: | xorw (%esi,%edx,2), %bx | may_load",
  ),
  ("x86", "f7fe", "2 IDIV32r Reg:ESI | idivl %esi | "),
  ("x86", "66f7d8", "3 NEG16r Reg:AX Reg:AX | negw %ax | "),
  (
    "x86", "660f49c1", "4 CMOV16rr Reg:AX Reg:AX Reg:CX Imm:9 | cmovnsw %cx, %ax | ",
  ),
  ("x86", "f6e2", "2 MUL8r Reg:DL | mulb %dl | "),
  ("x86", "d0ec", "2 SHR8r1 Reg:AH Reg:AH | shrb %ah | "),
  ("x86", "30e0", "2 XOR8rr Reg:AL Reg:AL Reg:AH | xorb %ah, %al | "),
  ("x86", "38ca", "2 CMP8rr Reg:DL Reg:CL | cmpb %cl, %dl | "),
  ("x86", "1400", "2 ADC8i8 Imm:0 | adcb $0, %al | "),
  (
    "x86", "0f59c8", "3 MULPSrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | mulps %xmm0, %xmm1 | ",
  ),
  (
    "x86", "0f5cc8", "3 SUBPSrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | subps %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f5ec1", "4 DIVPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | divpd %xmm1, %xmm0 | ",
  ),
  (
    "x86", "660f71f003", "5 PSLLWri Reg:XMM0 Reg:XMM0 Imm:3 | psllw $3, %xmm0 | ",
  ),
  (
    "x86", "660ffdc1", "4 PADDWrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | paddw %xmm1, %xmm0 | ",
  ),
  (
    "x86", "660fdac8", "4 PMINUBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminub %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f74c8", "4 PCMPEQBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pcmpeqb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fdfc8", "4 PANDNrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pandn %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ffe4c2410", "6 PADDDrm Reg:XMM1 Reg:XMM1 Reg:ESP Imm:1 Reg: Imm:16 Reg: | paddd 16(%esp), %xmm1 | may_load",
  ),
  (
    "x86", "0f594c2410", "5 MULPSrm Reg:XMM1 Reg:XMM1 Reg:ESP Imm:1 Reg: Imm:16 Reg: | mulps 16(%esp), %xmm1 | may_load",
  ),
  (
    "x86", "f75c9efc", "4 NEG32m Reg:ESI Imm:4 Reg:EBX Imm:-4 Reg: | negl -4(%esi,%ebx,4) | may_load,may_store",
  ),
  (
    "x86", "ffe2", "2 JMP32r Reg:EDX | jmpl *%edx | indirect,barrier,terminator,affect_cf",
  ),
  (
    "x86", "29449ef8", "4 SUB32mr Reg:ESI Imm:4 Reg:EBX Imm:-8 Reg: Reg:EAX | subl %eax, -8(%esi,%ebx,4) | may_load,may_store",
  ),
  (
    "x86", "01449ef8", "4 ADD32mr Reg:ESI Imm:4 Reg:EBX Imm:-8 Reg: Reg:EAX | addl %eax, -8(%esi,%ebx,4) | may_load,may_store",
  ),
  (
    "x86", "f20f584cc8f8", "6 ADDSDrm_Int Reg:XMM1 Reg:XMM1 Reg:EAX Imm:8 Reg:ECX Imm:-8 Reg: | addsd -8(%eax,%ecx,8), %xmm1 | may_load",
  ),
  (
    "x86", "f30f5f44240c", "6 MAXSSrm_Int Reg:XMM0 Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:12 Reg: | maxss 12(%esp), %xmm0 | may_load",
  ),
  (
    "x86", "660f288800000000", "8 MOVAPDrm Reg:XMM1 Reg:EAX Imm:1 Reg: Imm:0 Reg: | movapd (%eax), %xmm1 | may_load",
  ),
  (
    "x86", "f20f5fc8", "4 MAXSDrr_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 | maxsd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "d97c2404", "4 FNSTCW16m Reg:ESP Imm:1 Reg: Imm:4 Reg: | fnstcw 4(%esp) | may_store",
  ),
  (
    "x86", "81c9000c0000", "6 OR32ri Reg:ECX Reg:ECX Imm:3072 | orl $3072, %ecx | ",
  ),
  (
    "x86", "66894c2406", "5 MOV16mr Reg:ESP Imm:1 Reg: Imm:6 Reg: Reg:CX | movw %cx, 6(%esp) | may_store",
  ),
  (
    "x86", "d96c2406", "4 FLDCW16m Reg:ESP Imm:1 Reg: Imm:6 Reg: | fldcw 6(%esp) | may_load",
  ),
  (
    "x86", "df7c2408", "4 IST_FP64m Reg:ESP Imm:1 Reg: Imm:8 Reg: | fistpll 8(%esp) | may_store",
  ),
  (
    "x86", "3354240c", "4 XOR32rm Reg:EDX Reg:EDX Reg:ESP Imm:1 Reg: Imm:12 Reg: | xorl 12(%esp), %edx | may_load",
  ),
  (
    "x86", "0f148000000000", "7 UNPCKLPSrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | unpcklps (%eax), %xmm0 | may_load",
  ),
  (
    "x86", "660f5c8000000000", "8 SUBPDrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | subpd (%eax), %xmm0 | may_load",
  ),
  (
    "x86", "660f15c8", "4 UNPCKHPDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | unpckhpd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f56c8", "4 ORPDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | orpd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "0f57c0", "3 XORPSrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | xorps %xmm0, %xmm0 | ",
  ),
  (
    "x86", "f20fc2d000", "5 CMPSDrri_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 Imm:0 | cmpeqsd %xmm0, %xmm2 | ",
  ),
  (
    "x86", "8a3c01", "3 MOV8rm Reg:BH Reg:ECX Imm:1 Reg:EAX Imm:0 Reg: | movb (%ecx,%eax), %bh | may_load",
  ),
  (
    "x86", "f30f2ac0", "4 CVTSI2SSrr_Int Reg:XMM0 Reg:XMM0 Reg:EAX | cvtsi2ss %eax, %xmm0 | ",
  ),
  (
    "x86", "f30f5ac0", "4 CVTSS2SDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | cvtss2sd %xmm0, %xmm0 | ",
  ),
  ("x86", "0f31", "2 RDTSC  | rdtsc | "),
  ("x86", "f390", "2 PAUSE  | pause | may_load,may_store"),
  (
    "x86", "6bc903", "3 IMUL32rri8 Reg:ECX Reg:ECX Imm:3 | imull $3, %ecx, %ecx | ",
  ),
  (
    "x86", "668b450c", "4 MOV16rm Reg:AX Reg:EBP Imm:1 Reg: Imm:12 Reg: | movw 12(%ebp), %ax | may_load",
  ),
  ("x86", "19c8", "2 SBB32rr Reg:EAX Reg:EAX Reg:ECX | sbbl %ecx, %eax | "),
  ("x86", "2401", "2 AND8i8 Imm:1 | andb $1, %al | "),
  (
    "x86", "6b550c03", "4 IMUL32rmi8 Reg:EDX Reg:EBP Imm:1 Reg: Imm:12 Reg: Imm:3 | imull $3, 12(%ebp), %edx | may_load",
  ),
  ("x86", "ffd0", "2 CALL32r Reg:EAX | calll *%eax | call,affect_cf"),
  (
    "x86", "f30f5e450c", "5 DIVSSrm_Int Reg:XMM0 Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:12 Reg: | divss 12(%ebp), %xmm0 | may_load",
  ),
  ("x86", "0f2ec1", "3 UCOMISSrr Reg:XMM0 Reg:XMM1 | ucomiss %xmm1, %xmm0 | "),
  (
    "x86", "660f2e4510", "5 UCOMISDrm Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:16 Reg: | ucomisd 16(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "f20f5e4508", "5 DIVSDrm_Int Reg:XMM0 Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:8 Reg: | divsd 8(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "db7df4", "3 ST_FP80m Reg:EBP Imm:1 Reg: Imm:-12 Reg: | fstpt -12(%ebp) | may_store",
  ),
  ("x86", "d8c9", "2 MUL_FST0r Reg:ST1 | fmul %st(1), %st | "),
  (
    "x86", "0fc101", "3 XADD32rm Reg:EAX Reg:EAX Reg:ECX Imm:1 Reg: Imm:0 Reg: | xaddl %eax, (%ecx) | may_load,may_store",
  ),
  (
    "x86", "81ec8c000000", "6 SUB32ri Reg:ESP Reg:ESP Imm:140 | subl $140, %esp | ",
  ),
  ("x86", "d1e1", "2 SHL32r1 Reg:ECX Reg:ECX | shll %ecx | "),
  (
    "x86", "66c745fe0000", "6 MOV16mi Reg:EBP Imm:1 Reg: Imm:-2 Reg: Imm:0 | movw $0, -2(%ebp) | may_store",
  ),
  ("x86", "0fb7c0", "3 MOVZX32rr16 Reg:EAX Reg:AX | movzwl %ax, %eax | "),
  ("x86", "0fbfc8", "3 MOVSX32rr16 Reg:ECX Reg:AX | movswl %ax, %ecx | "),
  ("x86", "d1f9", "2 SAR32r1 Reg:ECX Reg:ECX | sarl %ecx | "),
  (
    "x86", "0f2945e8", "4 MOVAPSmr Reg:EBP Imm:1 Reg: Imm:-24 Reg: Reg:XMM0 | movaps %xmm0, -24(%ebp) | may_store",
  ),
  (
    "x86", "660f2945e8", "5 MOVAPDmr Reg:EBP Imm:1 Reg: Imm:-24 Reg: Reg:XMM0 | movapd %xmm0, -24(%ebp) | may_store",
  ),
  (
    "x86", "660f5e45d8", "5 DIVPDrm Reg:XMM0 Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:-40 Reg: | divpd -40(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "660ffd45d8", "5 PADDWrm Reg:XMM0 Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:-40 Reg: | paddw -40(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "660fdb45e8", "5 PANDrm Reg:XMM0 Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:-24 Reg: | pand -24(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "0f2e450c", "4 UCOMISSrm Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:12 Reg: | ucomiss 12(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "dd55f0", "3 ST_F64m Reg:EBP Imm:1 Reg: Imm:-16 Reg: | fstl -16(%ebp) | may_store",
  ),
  (
    "x86", "d955f8", "3 ST_F32m Reg:EBP Imm:1 Reg: Imm:-8 Reg: | fsts -8(%ebp) | may_store",
  ),
  (
    "x86", "f30f7e4508", "5 MOVQI2PQIrm Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:8 Reg: | movq 8(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "660f5cc1", "4 SUBPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | subpd %xmm1, %xmm0 | ",
  ),
  (
    "x86", "660f6e4508", "5 MOVDI2PDIrm Reg:XMM0 Reg:EBP Imm:1 Reg: Imm:8 Reg: | movd 8(%ebp), %xmm0 | may_load",
  ),
  (
    "x86", "660febc2", "4 PORrr Reg:XMM0 Reg:XMM0 Reg:XMM2 | por %xmm2, %xmm0 | ",
  ),
  ("x86", "20c8", "2 AND8rr Reg:AL Reg:AL Reg:CL | andb %cl, %al | "),
  ("x86", "0f0b", "2 TRAP  | ud2 | may_load"),
  (
    "x86", "660f54d4", "4 ANDPDrr Reg:XMM2 Reg:XMM2 Reg:XMM4 | andpd %xmm4, %xmm2 | ",
  ),
  (
    "x86", "660f55e3", "4 ANDNPDrr Reg:XMM4 Reg:XMM4 Reg:XMM3 | andnpd %xmm3, %xmm4 | ",
  ),
  (
    "x86", "f20f5a442408", "6 CVTSD2SSrm_Int Reg:XMM0 Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:8 Reg: | cvtsd2ss 8(%esp), %xmm0 | may_load",
  ),
  (
    "x86", "f3a5", "2 MOVSL Reg:EDI Reg:ESI Reg: | rep  movsl (%esi), %es:(%edi) | ",
  ),
  (
    "x86", "c4e271f7c8", "5 SHLX32rr Reg:ECX Reg:EAX Reg:ECX | shlxl %ecx, %eax, %ecx | ",
  ),
  (
    "x86", "c4e27bf6f1", "5 MULX32rr Reg:ESI Reg:EAX Reg:ECX | mulxl %ecx, %eax, %esi | ",
  ),
  (
    "x86", "c5f828442420", "6 VMOVAPSrm Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:32 Reg: | vmovaps 32(%esp), %xmm0 | may_load",
  ),
  (
    "x86", "c5f8110424", "5 VMOVUPSmr Reg:ESP Imm:1 Reg: Imm:0 Reg: Reg:XMM0 | vmovups %xmm0, (%esp) | may_store",
  ),
  (
    "x86", "f30fb8442404", "6 POPCNT32rm Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | popcntl 4(%esp), %eax | may_load",
  ),
  ("x86", "f30fbdc0", "4 LZCNT32rr Reg:EAX Reg:EAX | lzcntl %eax, %eax | "),
  (
    "x86", "0f38f0442404", "6 MOVBE32rm Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | movbel 4(%esp), %eax | may_load",
  ),
  (
    "x86", "660f38f0442404", "7 MOVBE16rm Reg:AX Reg:ESP Imm:1 Reg: Imm:4 Reg: | movbew 4(%esp), %ax | may_load",
  ),
  (
    "x86", "c5f9efc0", "4 VPXORrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vpxor %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5fd6f8f00000000", "8 VMOVDQAYrm Reg:YMM1 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vmovdqa (%edi), %ymm1 | may_load",
  ),
  (
    "x86", "c4e27d589700000000", "9 VPBROADCASTDYrm Reg:YMM2 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vpbroadcastd (%edi), %ymm2 | may_load",
  ),
  (
    "x86", "c5f5feea", "4 VPADDDYrr Reg:YMM5 Reg:YMM1 Reg:YMM2 | vpaddd %ymm2, %ymm1, %ymm5 | ",
  ),
  (
    "x86", "c4e275403482", "6 VPMULLDYrm Reg:YMM6 Reg:YMM1 Reg:EDX Imm:4 Reg:EAX Imm:0 Reg: | vpmulld (%edx,%eax,4), %ymm1, %ymm6 | may_load",
  ),
  (
    "x86", "c4e37d39c101", "6 VEXTRACTI128rri Reg:XMM1 Reg:YMM0 Imm:1 | vextracti128 $1, %ymm0, %xmm1 | ",
  ),
  (
    "x86", "c5f9fec1", "4 VPADDDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vpaddd %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5f970c8ee", "5 VPSHUFDri Reg:XMM1 Reg:XMM0 Imm:238 | vpshufd $238, %xmm0, %xmm1 | ",
  ),
  ("x86", "c5f97ec0", "4 VMOVPDI2DIrr Reg:EAX Reg:XMM0 | vmovd %xmm0, %eax | "),
  ("x86", "c5f96ec0", "4 VMOVDI2PDIrr Reg:XMM0 Reg:EAX | vmovd %eax, %xmm0 | "),
  (
    "x86", "c4e27958c9", "5 VPBROADCASTDrr Reg:XMM1 Reg:XMM1 | vpbroadcastd %xmm1, %xmm1 | ",
  ),
  (
    "x86", "c5f1eb8f00000000", "8 VPORrm Reg:XMM1 Reg:XMM1 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vpor (%edi), %xmm1, %xmm1 | may_load",
  ),
  (
    "x86", "c4e279589700000000", "9 VPBROADCASTDrm Reg:XMM2 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vpbroadcastd (%edi), %xmm2 | may_load",
  ),
  (
    "x86", "c4e271401c9a", "6 VPMULLDrm Reg:XMM3 Reg:XMM1 Reg:EDX Imm:4 Reg:EBX Imm:0 Reg: | vpmulld (%edx,%ebx,4), %xmm1, %xmm3 | may_load",
  ),
  ("x86", "c5f877", "3 VZEROUPPER  | vzeroupper | "),
  (
    "x86", "c4e27d188700000000", "9 VBROADCASTSSYrm Reg:YMM0 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vbroadcastss (%edi), %ymm0 | may_load",
  ),
  (
    "x86", "c5fc100c82", "5 VMOVUPSYrm Reg:YMM1 Reg:EDX Imm:4 Reg:EAX Imm:0 Reg: | vmovups (%edx,%eax,4), %ymm1 | may_load",
  ),
  (
    "x86", "c4e27da80c86", "6 VFMADD213PSYm Reg:YMM1 Reg:YMM1 Reg:YMM0 Reg:ESI Imm:4 Reg:EAX Imm:0 Reg: | vfmadd213ps (%esi,%eax,4), %ymm0, %ymm1 | may_load",
  ),
  (
    "x86", "c5fc110c81", "5 VMOVUPSYmr Reg:ECX Imm:4 Reg:EAX Imm:0 Reg: Reg:YMM1 | vmovups %ymm1, (%ecx,%eax,4) | may_store",
  ),
  (
    "x86", "c4e279188700000000", "9 VBROADCASTSSrm Reg:XMM0 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vbroadcastss (%edi), %xmm0 | may_load",
  ),
  (
    "x86", "c5f8100c82", "5 VMOVUPSrm Reg:XMM1 Reg:EDX Imm:4 Reg:EAX Imm:0 Reg: | vmovups (%edx,%eax,4), %xmm1 | may_load",
  ),
  (
    "x86", "c4e279a80c86", "6 VFMADD213PSm Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:ESI Imm:4 Reg:EAX Imm:0 Reg: | vfmadd213ps (%esi,%eax,4), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86", "c5fa108700000000", "8 VMOVSSrm Reg:XMM0 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vmovss (%edi), %xmm0 | may_load",
  ),
  (
    "x86", "c4e279a90cae", "6 VFMADD213SSm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:ESI Imm:4 Reg:EBP Imm:0 Reg: | vfmadd213ss (%esi,%ebp,4), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86", "c5fa110ca9", "5 VMOVSSmr Reg:ECX Imm:4 Reg:EBP Imm:0 Reg: Reg:XMM1 | vmovss %xmm1, (%ecx,%ebp,4) | may_store",
  ),
  (
    "x86", "c5f957c0", "4 VXORPDrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vxorpd %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5fb100cda", "5 VMOVSDrm Reg:XMM1 Reg:EDX Imm:8 Reg:EBX Imm:0 Reg: | vmovsd (%edx,%ebx,8), %xmm1 | may_load",
  ),
  (
    "x86", "c4e2f9990cde", "6 VFMADD132SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:ESI Imm:8 Reg:EBX Imm:0 Reg: | vfmadd132sd (%esi,%ebx,8), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86", "c4e2e9b94cde08", "7 VFMADD231SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM2 Reg:ESI Imm:8 Reg:EBX Imm:8 Reg: | vfmadd231sd 8(%esi,%ebx,8), %xmm2, %xmm1 | may_load",
  ),
  (
    "x86", "c5fb110424", "5 VMOVSDmr Reg:ESP Imm:1 Reg: Imm:0 Reg: Reg:XMM0 | vmovsd %xmm0, (%esp) | may_store",
  ),
  (
    "x86", "c5f25ed0", "4 VDIVSSrr_Int Reg:XMM2 Reg:XMM1 Reg:XMM0 | vdivss %xmm0, %xmm1, %xmm2 | ",
  ),
  (
    "x86", "c5f25dc0", "4 VMINSSrr_Int Reg:XMM0 Reg:XMM1 Reg:XMM0 | vminss %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c5ea5cc0", "4 VSUBSSrr_Int Reg:XMM0 Reg:XMM2 Reg:XMM0 | vsubss %xmm0, %xmm2, %xmm0 | ",
  ),
  (
    "x86", "c5f92ec8", "4 VUCOMISDrr Reg:XMM1 Reg:XMM0 | vucomisd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "c5f35cd0", "4 VSUBSDrr_Int Reg:XMM2 Reg:XMM1 Reg:XMM0 | vsubsd %xmm0, %xmm1, %xmm2 | ",
  ),
  (
    "x86", "c5fb5ed1", "4 VDIVSDrr_Int Reg:XMM2 Reg:XMM0 Reg:XMM1 | vdivsd %xmm1, %xmm0, %xmm2 | ",
  ),
  (
    "x86", "c4e2f1a9c2", "5 VFMADD213SDr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 Reg:XMM2 | vfmadd213sd %xmm2, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c5fa2c442404", "6 VCVTTSS2SIrm_Int Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: | vcvttss2si 4(%esp), %eax | may_load",
  ),
  (
    "x86", "c5fb5ac0", "4 VCVTSD2SSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | vcvtsd2ss %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5fb2cc8", "4 VCVTTSD2SIrr_Int Reg:ECX Reg:XMM0 | vcvttsd2si %xmm0, %ecx | ",
  ),
  (
    "x86", "c5fb5c8000000000", "8 VSUBSDrm_Int Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vsubsd (%eax), %xmm0, %xmm0 | may_load",
  ),
  ("x86", "81fb80000000", "6 CMP32ri Reg:EBX Imm:128 | cmpl $128, %ebx | "),
  (
    "x86", "c4e27d78c0", "5 VPBROADCASTBYrr Reg:YMM0 Reg:XMM0 | vpbroadcastb %xmm0, %ymm0 | ",
  ),
  (
    "x86", "c5fe7f0410", "5 VMOVDQUYmr Reg:EAX Imm:1 Reg:EDX Imm:0 Reg: Reg:YMM0 | vmovdqu %ymm0, (%eax,%edx) | may_store",
  ),
  (
    "x86", "c4e27978c0", "5 VPBROADCASTBrr Reg:XMM0 Reg:XMM0 | vpbroadcastb %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5f9d60430", "5 VMOVPQI2QImr Reg:EAX Imm:1 Reg:ESI Imm:0 Reg: Reg:XMM0 | vmovq %xmm0, (%eax,%esi) | may_store",
  ),
  (
    "x86", "c4e27bf7442404", "7 SHRX32rm Reg:EAX Reg:ESP Imm:1 Reg: Imm:4 Reg: Reg:EAX | shrxl %eax, 4(%esp), %eax | may_load",
  ),
  (
    "x86", "c4e263f7d2", "5 SHRX32rr Reg:EDX Reg:EDX Reg:EBX | shrxl %ebx, %edx, %edx | ",
  ),
  (
    "x86", "c5f96f8700000000", "8 VMOVDQArm Reg:XMM0 Reg:EDI Imm:1 Reg: Imm:0 Reg: | vmovdqa (%edi), %xmm0 | may_load",
  ),
  (
    "x86", "c4e26947d0", "5 VPSLLVDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | vpsllvd %xmm0, %xmm2, %xmm2 | ",
  ),
  (
    "x86", "c5e972e21f", "5 VPSRADri Reg:XMM2 Reg:XMM2 Imm:31 | vpsrad $31, %xmm2, %xmm2 | ",
  ),
  (
    "x86", "c5e9dbd1", "4 VPANDrr Reg:XMM2 Reg:XMM2 Reg:XMM1 | vpand %xmm1, %xmm2, %xmm2 | ",
  ),
  (
    "x86", "c4e27140c9", "5 VPMULLDrr Reg:XMM1 Reg:XMM1 Reg:XMM1 | vpmulld %xmm1, %xmm1, %xmm1 | ",
  ),
  (
    "x86", "c4e271aac0", "5 VFMSUB213PSr Reg:XMM0 Reg:XMM0 Reg:XMM1 Reg:XMM0 | vfmsub213ps %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c5f95ec1", "4 VDIVPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vdivpd %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5f971f003", "5 VPSLLWri Reg:XMM0 Reg:XMM0 Imm:3 | vpsllw $3, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5f9fdc1", "4 VPADDWrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vpaddw %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5f9dac9", "4 VPMINUBrr Reg:XMM1 Reg:XMM0 Reg:XMM1 | vpminub %xmm1, %xmm0, %xmm1 | ",
  ),
  (
    "x86", "c5f974c9", "4 VPCMPEQBrr Reg:XMM1 Reg:XMM0 Reg:XMM1 | vpcmpeqb %xmm1, %xmm0, %xmm1 | ",
  ),
  (
    "x86", "c5f1dfc0", "4 VPANDNrr Reg:XMM0 Reg:XMM1 Reg:XMM0 | vpandn %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c5fc59c1", "4 VMULPSYrr Reg:YMM0 Reg:YMM0 Reg:YMM1 | vmulps %ymm1, %ymm0, %ymm0 | ",
  ),
  (
    "x86", "c4e2f9a94cc8f8", "7 VFMADD213SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:EAX Imm:8 Reg:ECX Imm:-8 Reg: | vfmadd213sd -8(%eax,%ecx,8), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86", "c5fa5f44240c", "6 VMAXSSrm_Int Reg:XMM0 Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:12 Reg: | vmaxss 12(%esp), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "c5f9578800000000", "8 VXORPDrm Reg:XMM1 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vxorpd (%eax), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86", "c5f35fc0", "4 VMAXSDrr_Int Reg:XMM0 Reg:XMM1 Reg:XMM0 | vmaxsd %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c4e3790bc009", "6 VROUNDSDri_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 Imm:9 | vroundsd $9, %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5fb588000000000", "8 VADDSDrm_Int Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vaddsd (%eax), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "dd0c24", "3 ISTT_FP64m Reg:ESP Imm:1 Reg: Imm:0 Reg: | fisttpll (%esp) | may_store",
  ),
  (
    "x86", "c5f8148000000000", "8 VUNPCKLPSrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vunpcklps (%eax), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "c5f95c8000000000", "8 VSUBPDrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vsubpd (%eax), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "c5f9c6c801", "5 VSHUFPDrri Reg:XMM1 Reg:XMM0 Reg:XMM0 Imm:1 | vshufpd $1, %xmm0, %xmm0, %xmm1 | ",
  ),
  (
    "x86", "c5f358c0", "4 VADDSDrr_Int Reg:XMM0 Reg:XMM1 Reg:XMM0 | vaddsd %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "c5f156c8", "4 VORPDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | vorpd %xmm0, %xmm1, %xmm1 | ",
  ),
  (
    "x86", "c5f3c2d000", "5 VCMPSDrri_Int Reg:XMM2 Reg:XMM1 Reg:XMM0 Imm:0 | vcmpeqsd %xmm0, %xmm1, %xmm2 | ",
  ),
  ("x86", "3d80000000", "5 CMP32i32 Imm:128 | cmpl $128, %eax | "),
  (
    "x86", "c5f857c0", "4 VXORPSrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vxorps %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5c22ac2", "4 VCVTSI2SSrr_Int Reg:XMM0 Reg:XMM7 Reg:EDX | vcvtsi2ss %edx, %xmm7, %xmm0 | ",
  ),
  (
    "x86", "c5fa58442420", "6 VADDSSrm_Int Reg:XMM0 Reg:XMM0 Reg:ESP Imm:1 Reg: Imm:32 Reg: | vaddss 32(%esp), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "c5fa5ac0", "4 VCVTSS2SDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | vcvtss2sd %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86", "c5fdfe00", "4 VPADDDYrm Reg:YMM0 Reg:YMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vpaddd (%eax), %ymm0, %ymm0 | may_load",
  ),
  (
    "x86", "c5f9fe00", "4 VPADDDrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | vpaddd (%eax), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86", "660f3840fd", "5 PMULLDrr Reg:XMM7 Reg:XMM7 Reg:XMM5 | pmulld %xmm5, %xmm7 | ",
  ),
  (
    "x86", "660f3800c1", "5 PSHUFBrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | pshufb %xmm1, %xmm0 | ",
  ),
  (
    "x86", "660f3a0bc009", "6 ROUNDSDri_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 Imm:9 | roundsd $9, %xmm0, %xmm0 | ",
  ),
  ("x86", "00d8", "2 ADD8rr Reg:AL Reg:AL Reg:BL | addb %bl, %al | "),
  ("x86", "04ff", "2 ADD8i8 Imm:-1 | addb $-1, %al | "),
  (
    "x86", "0a4dfc", "3 OR8rm Reg:CL Reg:CL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | orb -4(%ebp), %cl | may_load",
  ),
  ("x86", "0f01c8", "3 MONITOR32rrr  | monitor | "),
  ("x86", "0f01c9", "3 MWAITrr  | mwait | may_load,may_store"),
  ("x86", "0f01d0", "3 XGETBV  | xgetbv | "),
  ("x86", "0f01f9", "3 RDTSCP  | rdtscp | "),
  ("x86", "0f01fb", "3 MWAITXrrr  | mwaitx | "),
  ("x86", "0f05", "2 SYSCALL  | syscall | "),
  ("x86", "0f08", "2 INVD  | invd | "),
  ("x86", "0f09", "2 WBINVD  | wbinvd | may_load,may_store"),
  (
    "x86", "0f0d45fc", "4 PREFETCH Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetch -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0f0d4dfc", "4 PREFETCHW Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetchw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0f0d55fc", "4 PREFETCHWT1 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetchwt1 -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0f10c1", "3 MOVUPSrr Reg:XMM0 Reg:XMM1 | movups %xmm1, %xmm0 | "),
  ("x86", "0f11c8", "3 MOVUPSrr_REV Reg:XMM0 Reg:XMM1 | movups %xmm1, %xmm0 | "),
  (
    "x86", "0f1845fc", "4 PREFETCHNTA Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetchnta -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0f184dfc", "4 PREFETCHT0 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetcht0 -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0f1855fc", "4 PREFETCHT1 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetcht1 -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0f185dfc", "4 PREFETCHT2 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | prefetcht2 -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0f29c8", "3 MOVAPSrr_REV Reg:XMM0 Reg:XMM1 | movaps %xmm1, %xmm0 | "),
  ("x86", "0f30", "2 WRMSR  | wrmsr | "),
  ("x86", "0f32", "2 RDMSR  | rdmsr | "),
  ("x86", "0f33", "2 RDPMC  | rdpmc | "),
  ("x86", "0f34", "2 SYSENTER  | sysenter | "),
  (
    "x86", "0f38f14dfc", "5 MOVBE32mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:ECX | movbel %ecx, -4(%ebp) | may_store",
  ),
  (
    "x86", "0f4545fc", "4 CMOV32rm Reg:EAX Reg:EAX Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | cmovnel -4(%ebp), %eax | may_load",
  ),
  (
    "x86", "0f9f45f8", "4 SETCCm Reg:EBP Imm:1 Reg: Imm:-8 Reg: Imm:15 | setg -8(%ebp) | may_store",
  ),
  ("x86", "0fa2", "2 CPUID  | cpuid | "),
  (
    "x86", "0fa4c804", "4 SHLD32rri8 Reg:EAX Reg:EAX Reg:ECX Imm:4 | shldl $4, %ecx, %eax | ",
  ),
  (
    "x86", "0fa54dfc", "4 SHLD32mrCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:ECX | shldl %cl, %ecx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0fae55fc", "4 LDMXCSR Reg:EBP Imm:1 Reg: Imm:-4 Reg: | ldmxcsr -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "0fae5df8", "4 STMXCSR Reg:EBP Imm:1 Reg: Imm:-8 Reg: | stmxcsr -8(%ebp) | may_store",
  ),
  (
    "x86", "0fae7dfc", "4 CLFLUSH Reg:EBP Imm:1 Reg: Imm:-4 Reg: | clflush -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0faee8", "3 LFENCE  | lfence | may_load,may_store"),
  ("x86", "0faef0", "3 MFENCE  | mfence | may_load,may_store"),
  ("x86", "0faef8", "3 SFENCE  | sfence | may_load,may_store"),
  (
    "x86", "0fb04dfc", "4 CMPXCHG8rm Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CL | cmpxchgb %cl, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0fb0cb", "3 CMPXCHG8rr Reg:BL Reg:CL | cmpxchgb %cl, %bl | "),
  ("x86", "0fb1cb", "3 CMPXCHG32rr Reg:EBX Reg:ECX | cmpxchgl %ecx, %ebx | "),
  (
    "x86", "0fba65fc05", "5 BT32mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btl $5, -4(%ebp) | may_load",
  ),
  (
    "x86", "0fba75fc05", "5 BTR32mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btrl $5, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0fbcc1", "3 BSF32rr Reg:EAX Reg:EAX Reg:ECX | bsfl %ecx, %eax | "),
  (
    "x86", "0fbd45fc", "4 BSR32rm Reg:EAX Reg:EAX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | bsrl -4(%ebp), %eax | may_load",
  ),
  ("x86", "0fbec4", "3 MOVSX32rr8 Reg:EAX Reg:AH | movsbl %ah, %eax | "),
  (
    "x86", "0fc04dfc", "4 XADD8rm Reg:CL Reg:CL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | xaddb %cl, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "0fc0cb", "3 XADD8rr Reg:BL Reg:CL Reg:BL Reg:CL | xaddb %cl, %bl | "),
  (
    "x86", "0fc1cb", "3 XADD32rr Reg:EBX Reg:ECX Reg:EBX Reg:ECX | xaddl %ecx, %ebx | ",
  ),
  (
    "x86", "0fc74df8", "4 CMPXCHG8B Reg:EBP Imm:1 Reg: Imm:-8 Reg: | cmpxchg8b -8(%ebp) | may_load,may_store",
  ),
  ("x86", "0fc7f1", "3 RDRAND32r Reg:ECX | rdrandl %ecx | "),
  ("x86", "0fc7f8", "3 RDSEED32r Reg:EAX | rdseedl %eax | "),
  (
    "x86", "104dfc", "3 ADC8mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CL | adcb %cl, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "10d8", "2 ADC8rr Reg:AL Reg:AL Reg:BL | adcb %bl, %al | "),
  ("x86", "1ac8", "2 SBB8rr_REV Reg:CL Reg:CL Reg:AL | sbbb %al, %cl | "),
  ("x86", "1bc8", "2 SBB32rr_REV Reg:ECX Reg:ECX Reg:EAX | sbbl %eax, %ecx | "),
  ("x86", "1dffffffff", "5 SBB32i32 Imm:4294967295 | sbbl $4294967295, %eax | "),
  ("x86", "23c8", "2 AND32rr_REV Reg:ECX Reg:ECX Reg:EAX | andl %eax, %ecx | "),
  (
    "x86", "2a4dfc", "3 SUB8rm Reg:CL Reg:CL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | subb -4(%ebp), %cl | may_load",
  ),
  ("x86", "2ac8", "2 SUB8rr_REV Reg:CL Reg:CL Reg:AL | subb %al, %cl | "),
  ("x86", "2bc8", "2 SUB32rr_REV Reg:ECX Reg:ECX Reg:EAX | subl %eax, %ecx | "),
  ("x86", "2dffffffff", "5 SUB32i32 Imm:4294967295 | subl $4294967295, %eax | "),
  (
    "x86", "314dfc", "3 XOR32mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:ECX | xorl %ecx, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "32c8", "2 XOR8rr_REV Reg:CL Reg:CL Reg:AL | xorb %al, %cl | "),
  ("x86", "3480", "2 XOR8i8 Imm:-128 | xorb $-128, %al | "),
  ("x86", "3ac8", "2 CMP8rr_REV Reg:CL Reg:AL | cmpb %al, %cl | "),
  ("x86", "3cff", "2 CMP8i8 Imm:-1 | cmpb $-1, %al | "),
  ("x86", "63c1", "2 ARPL16rr Reg:CX Reg:AX | arpl %ax, %cx | "),
  ("x86", "6601d8", "3 ADD16rr Reg:AX Reg:AX Reg:BX | addw %bx, %ax | "),
  (
    "x86", "660345fc", "4 ADD16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | addw -4(%ebp), %ax | may_load",
  ),
  ("x86", "66053412", "4 ADD16i16 Imm:4660 | addw $4660, %ax | "),
  (
    "x86", "660b45fc", "4 OR16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | orw -4(%ebp), %ax | may_load",
  ),
  (
    "x86", "660f380000", "5 PSHUFBrm Reg:XMM0 Reg:XMM0 Reg:EAX Imm:1 Reg: Imm:0 Reg: | pshufb (%eax), %xmm0 | may_load",
  ),
  (
    "x86", "660f3838c8", "5 PMINSBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f3839c8", "5 PMINSDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383ac8", "5 PMINUWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminuw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383bc8", "5 PMINUDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminud %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383cc8", "5 PMAXSBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383dc8", "5 PMAXSDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383ec8", "5 PMAXUWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxuw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f383fc8", "5 PMAXUDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxud %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f3a0fc104", "6 PALIGNRrri Reg:XMM0 Reg:XMM0 Reg:XMM1 Imm:4 | palignr $4, %xmm1, %xmm0 | ",
  ),
  (
    "x86", "660f4545fc", "5 CMOV16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | cmovnew -4(%ebp), %ax | may_load",
  ),
  (
    "x86", "660f64c8", "4 PCMPGTBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pcmpgtb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660f71d004", "5 PSRLWri Reg:XMM0 Reg:XMM0 Imm:4 | psrlw $4, %xmm0 | ",
  ),
  (
    "x86", "660f71e004", "5 PSRAWri Reg:XMM0 Reg:XMM0 Imm:4 | psraw $4, %xmm0 | ",
  ),
  (
    "x86", "660f72d004", "5 PSRLDri Reg:XMM0 Reg:XMM0 Imm:4 | psrld $4, %xmm0 | ",
  ),
  (
    "x86", "660f72e004", "5 PSRADri Reg:XMM0 Reg:XMM0 Imm:4 | psrad $4, %xmm0 | ",
  ),
  (
    "x86", "660f72f004", "5 PSLLDri Reg:XMM0 Reg:XMM0 Imm:4 | pslld $4, %xmm0 | ",
  ),
  (
    "x86", "660f73d004", "5 PSRLQri Reg:XMM0 Reg:XMM0 Imm:4 | psrlq $4, %xmm0 | ",
  ),
  (
    "x86", "660f73d803", "5 PSRLDQri Reg:XMM0 Reg:XMM0 Imm:3 | psrldq $3, %xmm0 | ",
  ),
  (
    "x86", "660f73f004", "5 PSLLQri Reg:XMM0 Reg:XMM0 Imm:4 | psllq $4, %xmm0 | ",
  ),
  (
    "x86", "660f73f803", "5 PSLLDQri Reg:XMM0 Reg:XMM0 Imm:3 | pslldq $3, %xmm0 | ",
  ),
  (
    "x86", "660f7fc8", "4 MOVDQArr_REV Reg:XMM0 Reg:XMM1 | movdqa %xmm1, %xmm0 | ",
  ),
  ("x86", "660fa3c8", "4 BT16rr Reg:AX Reg:CX | btw %cx, %ax | "),
  (
    "x86", "660fa4c804", "5 SHLD16rri8 Reg:AX Reg:AX Reg:CX Imm:4 | shldw $4, %cx, %ax | ",
  ),
  (
    "x86", "660fa54dfc", "5 SHLD16mrCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | shldw %cl, %cx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660fac55fc05", "6 SHRD16mri8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:DX Imm:5 | shrdw $5, %dx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660facd003", "5 SHRD16rri8 Reg:AX Reg:AX Reg:DX Imm:3 | shrdw $3, %dx, %ax | ",
  ),
  (
    "x86", "660fadd0", "4 SHRD16rrCL Reg:AX Reg:AX Reg:DX | shrdw %cl, %dx, %ax | ",
  ),
  (
    "x86", "660fae75fc", "5 CLWB Reg:EBP Imm:1 Reg: Imm:-4 Reg: | clwb -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660fae7dfc", "5 CLFLUSHOPT Reg:EBP Imm:1 Reg: Imm:-4 Reg: | clflushopt -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660faf45fc", "5 IMUL16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | imulw -4(%ebp), %ax | may_load",
  ),
  (
    "x86", "660fb14dfc", "5 CMPXCHG16rm Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | cmpxchgw %cx, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "660fb1cb", "4 CMPXCHG16rr Reg:BX Reg:CX | cmpxchgw %cx, %bx | "),
  ("x86", "660fb6c1", "4 MOVZX16rr8 Reg:AX Reg:CL | movzbw %cl, %ax | "),
  (
    "x86", "660fba65fc05", "6 BT16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btw $5, -4(%ebp) | may_load",
  ),
  (
    "x86", "660fba75fc05", "6 BTR16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btrw $5, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "660fbae803", "5 BTS16ri8 Reg:AX Reg:AX Imm:3 | btsw $3, %ax | "),
  (
    "x86", "660fbb4dfc", "5 BTC16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | btcw %cx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660fbc45fc", "5 BSF16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | bsfw -4(%ebp), %ax | may_load",
  ),
  ("x86", "660fbcc1", "4 BSF16rr Reg:AX Reg:AX Reg:CX | bsfw %cx, %ax | "),
  ("x86", "660fbdc1", "4 BSR16rr Reg:AX Reg:AX Reg:CX | bsrw %cx, %ax | "),
  (
    "x86", "660fbe45fc", "5 MOVSX16rm8 Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | movsbw -4(%ebp), %ax | may_load",
  ),
  ("x86", "660fbec4", "4 MOVSX16rr8 Reg:AX Reg:AH | movsbw %ah, %ax | "),
  (
    "x86", "660fc14dfc", "5 XADD16rm Reg:CX Reg:CX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | xaddw %cx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "660fc1cb", "4 XADD16rr Reg:BX Reg:CX Reg:BX Reg:CX | xaddw %cx, %bx | ",
  ),
  ("x86", "660fc7f1", "4 RDRAND16r Reg:CX | rdrandw %cx | "),
  (
    "x86", "660fd1c8", "4 PSRLWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrlw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fd2c8", "4 PSRLDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrld %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fd3c8", "4 PSRLQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrlq %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fd4c8", "4 PADDQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | paddq %xmm0, %xmm1 | ",
  ),
  ("x86", "660fd7c8", "4 PMOVMSKBrr Reg:ECX Reg:XMM0 | pmovmskb %xmm0, %ecx | "),
  (
    "x86", "660fdec8", "4 PMAXUBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxub %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fe0c8", "4 PAVGBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pavgb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fe1c8", "4 PSRAWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psraw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fe2c8", "4 PSRADrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrad %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660fe3c8", "4 PAVGWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pavgw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660feac8", "4 PMINSWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660feec8", "4 PMAXSWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ff1c8", "4 PSLLWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psllw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ff2c8", "4 PSLLDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pslld %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ff3c8", "4 PSLLQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psllq %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ff8c8", "4 PSUBBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ff9c8", "4 PSUBWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubw %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ffac8", "4 PSUBDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubd %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ffbc8", "4 PSUBQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubq %xmm0, %xmm1 | ",
  ),
  (
    "x86", "660ffcc8", "4 PADDBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | paddb %xmm0, %xmm1 | ",
  ),
  (
    "x86", "66114dfc", "4 ADC16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | adcw %cx, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "6611d8", "3 ADC16rr Reg:AX Reg:AX Reg:BX | adcw %bx, %ax | "),
  ("x86", "66153412", "4 ADC16i16 Imm:4660 | adcw $4660, %ax | "),
  (
    "x86", "661b45fc", "4 SBB16rm Reg:AX Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | sbbw -4(%ebp), %ax | may_load",
  ),
  ("x86", "661bc8", "3 SBB16rr_REV Reg:CX Reg:CX Reg:AX | sbbw %ax, %cx | "),
  ("x86", "6623c8", "3 AND16rr_REV Reg:CX Reg:CX Reg:AX | andw %ax, %cx | "),
  ("x86", "6625ff00", "4 AND16i16 Imm:255 | andw $255, %ax | "),
  (
    "x86", "66294dfc", "4 SUB16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | subw %cx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66314dfc", "4 XOR16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | xorw %cx, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "6631c0", "3 XOR16rr Reg:AX Reg:AX Reg:AX | xorw %ax, %ax | "),
  (
    "x86", "66394dfc", "4 CMP16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | cmpw %cx, -4(%ebp) | may_load",
  ),
  ("x86", "6639d8", "3 CMP16rr Reg:AX Reg:BX | cmpw %bx, %ax | "),
  ("x86", "663dffff", "4 CMP16i16 Imm:65535 | cmpw $65535, %ax | "),
  ("x86", "6640", "2 INC16r_alt Reg:AX Reg:AX | incw %ax | "),
  ("x86", "6648", "2 DEC16r_alt Reg:AX Reg:AX | decw %ax | "),
  ("x86", "6655", "2 PUSH16r Reg:BP | pushw %bp | may_store"),
  ("x86", "665d", "2 POP16r Reg:BP | popw %bp | may_load"),
  ("x86", "66683412", "4 PUSH16i Imm:4660 | pushw $4660 | may_store"),
  (
    "x86", "666945fc3412", "6 IMUL16rmi Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4660 | imulw $4660, -4(%ebp), %ax | may_load",
  ),
  ("x86", "666aff", "3 PUSH16i8 Imm:-1 | pushw $-1 | may_store"),
  (
    "x86", "666bc102", "4 IMUL16rri8 Reg:AX Reg:CX Imm:2 | imulw $2, %cx, %ax | ",
  ),
  (
    "x86", "66815dfc3412", "6 SBB16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4660 | sbbw $4660, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "668165fcff00", "6 AND16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:255 | andw $255, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66816dfc3412", "6 SUB16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4660 | subw $4660, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "6681d83412", "5 SBB16ri Reg:AX Reg:AX Imm:4660 | sbbw $4660, %ax | "),
  (
    "x86", "668345fc01", "5 ADD16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | addw $1, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "668355fc01", "5 ADC16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | adcw $1, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "668375fcff", "5 XOR16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:-1 | xorw $-1, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66837dfc01", "5 CMP16mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | cmpw $1, -4(%ebp) | may_load",
  ),
  ("x86", "6683c001", "4 ADD16ri8 Reg:AX Reg:AX Imm:1 | addw $1, %ax | "),
  ("x86", "6683c80f", "4 OR16ri8 Reg:AX Reg:AX Imm:15 | orw $15, %ax | "),
  ("x86", "6683d8ff", "4 SBB16ri8 Reg:AX Reg:AX Imm:-1 | sbbw $-1, %ax | "),
  ("x86", "6683f900", "4 CMP16ri8 Reg:CX Imm:0 | cmpw $0, %cx | "),
  (
    "x86", "66854dfc", "4 TEST16mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | testw %cx, -4(%ebp) | may_load",
  ),
  ("x86", "6685c0", "3 TEST16rr Reg:AX Reg:AX | testw %ax, %ax | "),
  (
    "x86", "66874dfc", "4 XCHG16rm Reg:CX Reg:CX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | xchgw %cx, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "6687c8", "3 XCHG16rr Reg:CX Reg:AX Reg:CX Reg:AX | xchgw %ax, %cx | ",
  ),
  ("x86", "6689d8", "3 MOV16rr Reg:AX Reg:BX | movw %bx, %ax | "),
  ("x86", "668bc1", "3 MOV16rr_REV Reg:AX Reg:CX | movw %cx, %ax | "),
  (
    "x86", "668d45fc", "4 LEA16r Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | leaw -4(%ebp), %ax | ",
  ),
  ("x86", "6691", "2 XCHG16ar Reg:CX Reg:CX | xchgw %cx, %ax | "),
  ("x86", "6698", "2 CBW  | cbtw | "),
  ("x86", "669c", "2 PUSHF16  | pushfw | may_store"),
  ("x86", "669d", "2 POPF16  | popfw | may_load"),
  (
    "x86", "66a178563412", "6 MOV16ao32 Imm:305419896 Reg: | movw 305419896, %ax | may_load",
  ),
  (
    "x86", "66a378563412", "6 MOV16o32a Imm:305419896 Reg: | movw %ax, 305419896 | may_store",
  ),
  ("x86", "66a5", "2 MOVSW Reg:EDI Reg:ESI Reg: | movsw (%esi), %es:(%edi) | "),
  ("x86", "66a7", "2 CMPSW Reg:EDI Reg:ESI Reg: | cmpsw %es:(%edi), (%esi) | "),
  ("x86", "66a9ff00", "4 TEST16i16 Imm:255 | testw $255, %ax | "),
  ("x86", "66ab", "2 STOSW Reg:EDI | stosw %ax, %es:(%edi) | "),
  ("x86", "66af", "2 SCASW Reg:EDI | scasw %es:(%edi), %ax | "),
  ("x86", "66b83412", "4 MOV16ri Reg:AX Imm:4660 | movw $4660, %ax | "),
  (
    "x86", "66c145fc04", "5 ROL16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | rolw $4, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66c155fc04", "5 RCL16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | rclw $4, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66c17dfc04", "5 SAR16mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | sarw $4, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "66c1d003", "4 RCL16ri Reg:AX Reg:AX Imm:3 | rclw $3, %ax | "),
  ("x86", "66c1f803", "4 SAR16ri Reg:AX Reg:AX Imm:3 | sarw $3, %ax | "),
  ("x86", "66c7c03412", "5 MOV16ri_alt Reg:AX Imm:4660 | movw $4660, %ax | "),
  ("x86", "66c9", "2 LEAVE  | leave | may_load"),
  (
    "x86", "66d145fc", "4 ROL16m1 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rolw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66d155fc", "4 RCL16m1 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rclw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66d165fc", "4 SHL16m1 Reg:EBP Imm:1 Reg: Imm:-4 Reg: | shlw -4(%ebp) | may_load,may_store",
  ),
  ("x86", "66d1c0", "3 ROL16r1 Reg:AX Reg:AX | rolw %ax | "),
  ("x86", "66d1d0", "3 RCL16r1 Reg:AX Reg:AX | rclw %ax | "),
  ("x86", "66d1e0", "3 SHL16r1 Reg:AX Reg:AX | shlw %ax | "),
  (
    "x86", "66d34dfc", "4 ROR16mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rorw %cl, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66d35dfc", "4 RCR16mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rcrw %cl, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66d36dfc", "4 SHR16mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | shrw %cl, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "66d3c8", "3 ROR16rCL Reg:AX Reg:AX | rorw %cl, %ax | "),
  ("x86", "66d3d8", "3 RCR16rCL Reg:AX Reg:AX | rcrw %cl, %ax | "),
  ("x86", "66d3e8", "3 SHR16rCL Reg:AX Reg:AX | shrw %cl, %ax | "),
  ("x86", "66e582", "3 IN16ri Imm:130 | inw $130, %ax | "),
  ("x86", "66e785", "3 OUT16ir Imm:133 | outw %ax, $133 | "),
  ("x86", "66ed", "2 IN16rr  | inw %dx, %ax | "),
  ("x86", "66ef", "2 OUT16rr  | outw %ax, %dx | "),
  (
    "x86", "66f30fb845fc", "6 POPCNT16rm Reg:AX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | popcntw -4(%ebp), %ax | may_load",
  ),
  ("x86", "66f30fb8c1", "5 POPCNT16rr Reg:AX Reg:CX | popcntw %cx, %ax | "),
  ("x86", "66f30fbdc1", "5 LZCNT16rr Reg:AX Reg:CX | lzcntw %cx, %ax | "),
  (
    "x86", "66f755fc", "4 NOT16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | notw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66f75dfc", "4 NEG16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | negw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66f765fc", "4 MUL16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | mulw -4(%ebp) | may_load",
  ),
  (
    "x86", "66f76dfc", "4 IMUL16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | imulw -4(%ebp) | may_load",
  ),
  (
    "x86", "66f775fc", "4 DIV16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | divw -4(%ebp) | may_load",
  ),
  (
    "x86", "66f77dfc", "4 IDIV16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | idivw -4(%ebp) | may_load",
  ),
  ("x86", "66f7d0", "3 NOT16r Reg:AX Reg:AX | notw %ax | "),
  ("x86", "66f7e1", "3 MUL16r Reg:CX | mulw %cx | "),
  ("x86", "66f7e9", "3 IMUL16r Reg:CX | imulw %cx | "),
  ("x86", "66f7f1", "3 DIV16r Reg:CX | divw %cx | "),
  (
    "x86", "66ff45fc", "4 INC16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | incw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66ff4dfc", "4 DEC16m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | decw -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66ff7010", "4 PUSH16rmm Reg:EAX Imm:1 Reg: Imm:16 Reg: | pushw 16(%eax) | may_load,may_store",
  ),
  ("x86", "66ffc1", "3 INC16r Reg:CX Reg:CX | incw %cx | "),
  ("x86", "66ffc8", "3 DEC16r Reg:AX Reg:AX | decw %ax | "),
  ("x86", "66fff0", "3 PUSH16rmr Reg:AX | pushw %ax | may_store"),
  (
    "x86", "6878563412", "5 PUSH32i Imm:305419896 | pushl $305419896 | may_store",
  ),
  ("x86", "80c80f", "3 OR8ri Reg:AL Reg:AL Imm:15 | orb $15, %al | "),
  ("x86", "80d880", "3 SBB8ri Reg:AL Reg:AL Imm:-128 | sbbb $-128, %al | "),
  ("x86", "80e880", "3 SUB8ri Reg:AL Reg:AL Imm:-128 | subb $-128, %al | "),
  ("x86", "80f880", "3 CMP8ri Reg:AL Imm:-128 | cmpb $-128, %al | "),
  (
    "x86", "816dfc78563412", "7 SUB32mi Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:305419896 | subl $305419896, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "835dfc01", "4 SBB32mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | sbbl $1, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "8375fcff", "4 XOR32mi8 Reg:EBP Imm:1 Reg: Imm:-4 Reg: Imm:-1 | xorl $-1, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "83d001", "3 ADC32ri8 Reg:EAX Reg:EAX Imm:1 | adcl $1, %eax | "),
  ("x86", "83d801", "3 SBB32ri8 Reg:EAX Reg:EAX Imm:1 | sbbl $1, %eax | "),
  (
    "x86", "844dfc", "3 TEST8mr Reg:EBP Imm:1 Reg: Imm:-4 Reg: Reg:CL | testb %cl, -4(%ebp) | may_load",
  ),
  (
    "x86", "8645fc", "3 XCHG8rm Reg:AL Reg:AL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | xchgb %al, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "86e0", "2 XCHG8rr Reg:AH Reg:AL Reg:AH Reg:AL | xchgb %al, %ah | "),
  (
    "x86", "87d8", "2 XCHG32rr Reg:EBX Reg:EAX Reg:EBX Reg:EAX | xchgl %eax, %ebx | ",
  ),
  ("x86", "8ae0", "2 MOV8rr_REV Reg:AH Reg:AL | movb %al, %ah | "),
  ("x86", "8bec", "2 MOV32rr_REV Reg:EBP Reg:ESP | movl %esp, %ebp | "),
  ("x86", "91", "1 XCHG32ar Reg:ECX Reg:ECX | xchgl %ecx, %eax | "),
  ("x86", "98", "1 CWDE  | cwtl | "),
  ("x86", "9b", "1 WAIT  | wait | "),
  ("x86", "9c", "1 PUSHF32  | pushfl | may_store"),
  ("x86", "9d", "1 POPF32  | popfl | may_load"),
  ("x86", "9e", "1 SAHF  | sahf | "),
  ("x86", "9f", "1 LAHF  | lahf | "),
  (
    "x86", "a004030201", "5 MOV8ao32 Imm:16909060 Reg: | movb 16909060, %al | may_load",
  ),
  (
    "x86", "a178563412", "5 MOV32ao32 Imm:305419896 Reg: | movl 305419896, %eax | may_load",
  ),
  (
    "x86", "a378563412", "5 MOV32o32a Imm:305419896 Reg: | movl %eax, 305419896 | may_store",
  ),
  ("x86", "a4", "1 MOVSB Reg:EDI Reg:ESI Reg: | movsb (%esi), %es:(%edi) | "),
  ("x86", "a6", "1 CMPSB Reg:EDI Reg:ESI Reg: | cmpsb %es:(%edi), (%esi) | "),
  ("x86", "a7", "1 CMPSL Reg:EDI Reg:ESI Reg: | cmpsl %es:(%edi), (%esi) | "),
  ("x86", "a9ff000000", "5 TEST32i32 Imm:255 | testl $255, %eax | "),
  ("x86", "aa", "1 STOSB Reg:EDI | stosb %al, %es:(%edi) | "),
  ("x86", "ab", "1 STOSL Reg:EDI | stosl %eax, %es:(%edi) | "),
  ("x86", "ae", "1 SCASB Reg:EDI | scasb %es:(%edi), %al | "),
  ("x86", "af", "1 SCASL Reg:EDI | scasl %es:(%edi), %eax | "),
  ("x86", "c0c403", "3 ROL8ri Reg:AH Reg:AH Imm:3 | rolb $3, %ah | "),
  ("x86", "c0d403", "3 RCL8ri Reg:AH Reg:AH Imm:3 | rclb $3, %ah | "),
  ("x86", "c0e403", "3 SHL8ri Reg:AH Reg:AH Imm:3 | shlb $3, %ah | "),
  ("x86", "c6c480", "3 MOV8ri_alt Reg:AH Imm:-128 | movb $-128, %ah | "),
  (
    "x86", "c7c0ffffffff", "6 MOV32ri_alt Reg:EAX Imm:4294967295 | movl $4294967295, %eax | ",
  ),
  (
    "x86", "ca1000", "3 LRETI32 Imm:16 | lretl $16 | return,barrier,terminator,affect_cf",
  ),
  ("x86", "cb", "1 LRET32  | lretl | return,barrier,terminator,affect_cf"),
  ("x86", "cc", "1 INT3  | int3 | may_load,may_store"),
  ("x86", "cd03", "2 INT Imm:3 | int $3 | may_load,may_store"),
  ("x86", "d0c0", "2 ROL8r1 Reg:AL Reg:AL | rolb %al | "),
  ("x86", "d0d0", "2 RCL8r1 Reg:AL Reg:AL | rclb %al | "),
  ("x86", "d0e0", "2 SHL8r1 Reg:AL Reg:AL | shlb %al | "),
  ("x86", "d1c8", "2 ROR32r1 Reg:EAX Reg:EAX | rorl %eax | "),
  ("x86", "d1d8", "2 RCR32r1 Reg:EAX Reg:EAX | rcrl %eax | "),
  (
    "x86", "d34dfc", "3 ROR32mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rorl %cl, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "d35dfc", "3 RCR32mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | rcrl %cl, -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "d36dfc", "3 SHR32mCL Reg:EBP Imm:1 Reg: Imm:-4 Reg: | shrl %cl, -4(%ebp) | may_load,may_store",
  ),
  ("x86", "d3c8", "2 ROR32rCL Reg:EAX Reg:EAX | rorl %cl, %eax | "),
  ("x86", "d3d8", "2 RCR32rCL Reg:EAX Reg:EAX | rcrl %cl, %eax | "),
  ("x86", "d3f8", "2 SAR32rCL Reg:EAX Reg:EAX | sarl %cl, %eax | "),
  ("x86", "e303", "2 JECXZ Imm:3 | jecxz 3 | cond,terminator,affect_cf"),
  ("x86", "e480", "2 IN8ri Imm:128 | inb $128, %al | "),
  ("x86", "e581", "2 IN32ri Imm:129 | inl $129, %eax | "),
  ("x86", "e683", "2 OUT8ir Imm:131 | outb %al, $131 | "),
  ("x86", "e784", "2 OUT32ir Imm:132 | outl %eax, $132 | "),
  ("x86", "ec", "1 IN8rr  | inb %dx, %al | "),
  ("x86", "ed", "1 IN32rr  | inl %dx, %eax | "),
  ("x86", "ee", "1 OUT8rr  | outb %al, %dx | "),
  ("x86", "ef", "1 OUT32rr  | outl %eax, %dx | "),
  ("x86", "f30f1efa", "4 ENDBR64  | endbr64 | "),
  ("x86", "f30f1efb", "4 ENDBR32  | endbr32 | "),
  ("x86", "f30f6fc1", "4 MOVDQUrr Reg:XMM0 Reg:XMM1 | movdqu %xmm1, %xmm0 | "),
  (
    "x86", "f30f7fc8", "4 MOVDQUrr_REV Reg:XMM0 Reg:XMM1 | movdqu %xmm1, %xmm0 | ",
  ),
  ("x86", "f30fb8c1", "4 POPCNT32rr Reg:EAX Reg:ECX | popcntl %ecx, %eax | "),
  ("x86", "f30fbcc1", "4 TZCNT32rr Reg:EAX Reg:ECX | tzcntl %ecx, %eax | "),
  (
    "x86", "f30fbd45fc", "5 LZCNT32rm Reg:EAX Reg:EBP Imm:1 Reg: Imm:-4 Reg: | lzcntl -4(%ebp), %eax | may_load",
  ),
  ("x86", "f4", "1 HLT  | hlt | terminator"),
  ("x86", "f5", "1 CMC  | cmc | "),
  ("x86", "f6d0", "2 NOT8r Reg:AL Reg:AL | notb %al | "),
  ("x86", "f6dc", "2 NEG8r Reg:AH Reg:AH | negb %ah | "),
  ("x86", "f6e9", "2 IMUL8r Reg:CL | imulb %cl | "),
  ("x86", "f6f1", "2 DIV8r Reg:CL | divb %cl | "),
  ("x86", "f6f9", "2 IDIV8r Reg:CL | idivb %cl | "),
  (
    "x86", "f765fc", "3 MUL32m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | mull -4(%ebp) | may_load",
  ),
  (
    "x86", "f76dfc", "3 IMUL32m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | imull -4(%ebp) | may_load",
  ),
  (
    "x86", "f7c100000080", "6 TEST32ri Reg:ECX Imm:2147483648 | testl $2147483648, %ecx | ",
  ),
  ("x86", "f7e9", "2 IMUL32r Reg:ECX | imull %ecx | "),
  ("x86", "f7f1", "2 DIV32r Reg:ECX | divl %ecx | "),
  ("x86", "f8", "1 CLC  | clc | "),
  ("x86", "f9", "1 STC  | stc | "),
  ("x86", "fc", "1 CLD  | cld | "),
  ("x86", "fd", "1 STD  | std | "),
  ("x86", "fec0", "2 INC8r Reg:AL Reg:AL | incb %al | "),
  ("x86", "fec9", "2 DEC8r Reg:CL Reg:CL | decb %cl | "),
  (
    "x86", "ff4dfc", "3 DEC32m Reg:EBP Imm:1 Reg: Imm:-4 Reg: | decl -4(%ebp) | may_load,may_store",
  ),
  (
    "x86", "ff6010", "3 JMP32m Reg:EAX Imm:1 Reg: Imm:16 Reg: | jmpl *16(%eax) | indirect,barrier,terminator,affect_cf,may_load",
  ),
  (
    "x86", "ff7010", "3 PUSH32rmm Reg:EAX Imm:1 Reg: Imm:16 Reg: | pushl 16(%eax) | may_load,may_store",
  ),
  ("x86", "ffc0", "2 INC32r Reg:EAX Reg:EAX | incl %eax | "),
  ("x86", "ffc9", "2 DEC32r Reg:ECX Reg:ECX | decl %ecx | "),
  ("x86", "fff0", "2 PUSH32rmr Reg:EAX | pushl %eax | may_store"),
  (
    "x86", "66672683d26e", "6 ADC16ri8 Reg:DX Reg:DX Imm:110 | addr16  adcw $110, %dx | ",
  ),
  (
    "x86", "66261300", "4 ADC16rm Reg:AX Reg:AX Reg:EAX Imm:1 Reg: Imm:0 Reg:ES | adcw %es:(%eax), %ax | may_load",
  ),
  ("x86", "662613d5", "4 ADC16rr_REV Reg:DX Reg:DX Reg:BP | adcw %bp, %dx | "),
  (
    "x86", "f326831346", "5 ADC32mi8 Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Imm:70 | rep  adcl $70, %es:(%ebx) | may_load,may_store",
  ),
  (
    "x86", "261133", "3 ADC32mr Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Reg:ESI | adcl %esi, %es:(%ebx) | may_load,may_store",
  ),
  (
    "x86", "f326137235", "5 ADC32rm Reg:ESI Reg:ESI Reg:EDX Imm:1 Reg: Imm:53 Reg:ES | rep  adcl %es:53(%edx), %esi | may_load",
  ),
  (
    "x86", "672613e2", "4 ADC32rr_REV Reg:ESP Reg:ESP Reg:EDX | addr16  adcl %edx, %esp | ",
  ),
  (
    "x86", "2682506db4", "5 ADC8mi8 Reg:EAX Imm:1 Reg: Imm:109 Reg:ES Imm:-76 | adcb $-76, %es:109(%eax) | may_load,may_store",
  ),
  ("x86", "2682d11e", "4 ADC8ri8 Reg:CL Reg:CL Imm:30 | adcb $30, %cl | "),
  (
    "x86", "f3261265d8", "5 ADC8rm Reg:AH Reg:AH Reg:EBP Imm:1 Reg: Imm:-40 Reg:ES | rep  adcb %es:-40(%ebp), %ah | may_load",
  ),
  ("x86", "662612c1", "4 ADC8rr_REV Reg:AL Reg:AL Reg:CL | adcb %cl, %al | "),
  (
    "x86", "6667260167dd", "6 ADD16mr Reg:BX Imm:1 Reg: Imm:-35 Reg:ES Reg:SP | addw %sp, %es:-35(%bx) | may_load,may_store",
  ),
  (
    "x86", "66f32603c7", "5 ADD16rr_REV Reg:AX Reg:AX Reg:DI | rep  addw %di, %ax | ",
  ),
  (
    "x86", "f22603e6", "4 ADD32rr_REV Reg:ESP Reg:ESP Reg:ESI | repne  addl %esi, %esp | ",
  ),
  (
    "x86", "268247f7da", "5 ADD8mi8 Reg:EDI Imm:1 Reg: Imm:-9 Reg:ES Imm:-38 | addb $-38, %es:-9(%edi) | may_load,may_store",
  ),
  (
    "x86", "f2260013", "4 ADD8mr Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Reg:DL | repne  addb %dl, %es:(%ebx) | may_load,may_store",
  ),
  ("x86", "f32682c706", "5 ADD8ri8 Reg:BH Reg:BH Imm:6 | rep  addb $6, %bh | "),
  (
    "x86", "f32602c0", "4 ADD8rr_REV Reg:AL Reg:AL Reg:AL | rep  addb %al, %al | ",
  ),
  (
    "x86", "66f32683271e", "6 AND16mi8 Reg:EDI Imm:1 Reg: Imm:0 Reg:ES Imm:30 | rep  andw $30, %es:(%edi) | may_load,may_store",
  ),
  (
    "x86", "662621ad153c6f97", "8 AND16mr Reg:EBP Imm:1 Reg: Imm:-1754317803 Reg:ES Reg:BP | andw %bp, %es:-1754317803(%ebp) | may_load,may_store",
  ),
  (
    "x86", "66672683e4e5", "6 AND16ri8 Reg:SP Reg:SP Imm:-27 | addr16  andw $-27, %sp | ",
  ),
  (
    "x86", "66f326235e13", "6 AND16rm Reg:BX Reg:BX Reg:ESI Imm:1 Reg: Imm:19 Reg:ES | rep  andw %es:19(%esi), %bx | may_load",
  ),
  (
    "x86", "66672621cc", "5 AND16rr Reg:SP Reg:SP Reg:CX | addr16  andw %cx, %sp | ",
  ),
  (
    "x86", "f32683a6c2d7ca6f8b", "9 AND32mi8 Reg:ESI Imm:1 Reg: Imm:1875564482 Reg:ES Imm:-117 | rep  andl $-117, %es:1875564482(%esi) | may_load,may_store",
  ),
  (
    "x86", "f32621251ac29737", "8 AND32mr Reg: Imm:1 Reg: Imm:932692506 Reg:ES Reg:ESP | rep  andl %esp, %es:932692506 | may_load,may_store",
  ),
  (
    "x86", "262367a3", "4 AND32rm Reg:ESP Reg:ESP Reg:EDI Imm:1 Reg: Imm:-93 Reg:ES | andl %es:-93(%edi), %esp | may_load",
  ),
  (
    "x86", "f326822090", "5 AND8mi8 Reg:EAX Imm:1 Reg: Imm:0 Reg:ES Imm:-112 | rep  andb $-112, %es:(%eax) | may_load,may_store",
  ),
  (
    "x86", "662620a75ed7e485", "8 AND8mr Reg:EDI Imm:1 Reg: Imm:-2048600226 Reg:ES Reg:AH | andb %ah, %es:-2048600226(%edi) | may_load,may_store",
  ),
  (
    "x86", "f32682e2b9", "5 AND8ri8 Reg:DL Reg:DL Imm:-71 | rep  andb $-71, %dl | ",
  ),
  (
    "x86", "67262238", "4 AND8rm Reg:BH Reg:BH Reg:BX Imm:1 Reg:SI Imm:0 Reg:ES | andb %es:(%bx,%si), %bh | may_load",
  ),
  (
    "x86", "f32622d3", "4 AND8rr_REV Reg:DL Reg:DL Reg:BL | rep  andb %bl, %dl | ",
  ),
  (
    "x86", "66f20fbc39", "5 BSF32rm Reg:DI Reg:DI Reg:ECX Imm:1 Reg: Imm:0 Reg: | bsfl (%ecx), %di | may_load",
  ),
  (
    "x86", "660fbd4aac", "5 BSR16rm Reg:CX Reg:CX Reg:EDX Imm:1 Reg: Imm:-84 Reg: | bsrw -84(%edx), %cx | may_load",
  ),
  (
    "x86", "67660fa36a39", "6 BT16mr Reg:BP Imm:1 Reg:SI Imm:57 Reg: Reg:BP | btw %bp, 57(%bp,%si) | may_load",
  ),
  ("x86", "66260fbae394", "6 BT16ri8 Reg:BX Imm:148 | btw $148, %bx | "),
  (
    "x86", "67260fa34301", "6 BT32mr Reg:BP Imm:1 Reg:DI Imm:1 Reg:ES Reg:EAX | btl %eax, %es:1(%bp,%di) | may_load",
  ),
  ("x86", "f30fbae180", "5 BT32ri8 Reg:ECX Imm:128 | btl $128, %ecx | "),
  (
    "x86", "67660fbabf8f94c6", "8 BTC16mi8 Reg:BX Imm:1 Reg: Imm:-27505 Reg: Imm:198 | btcw $198, -27505(%bx) | may_load,may_store",
  ),
  (
    "x86", "67660fbaf860", "6 BTC16ri8 Reg:AX Reg:AX Imm:96 | addr16  btcw $96, %ax | ",
  ),
  (
    "x86", "67660fbbde", "5 BTC16rr Reg:SI Reg:SI Reg:BX | addr16  btcw %bx, %si | ",
  ),
  (
    "x86", "f3260fba3926", "6 BTC32mi8 Reg:ECX Imm:1 Reg: Imm:0 Reg:ES Imm:38 | rep  btcl $38, %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86", "f3260fbb52f0", "6 BTC32mr Reg:EDX Imm:1 Reg: Imm:-16 Reg:ES Reg:EDX | rep  btcl %edx, %es:-16(%edx) | may_load,may_store",
  ),
  (
    "x86", "67f30fbaf8b7", "6 BTC32ri8 Reg:EAX Reg:EAX Imm:183 | addr16  btcl $183, %eax | ",
  ),
  ("x86", "260fbbf0", "4 BTC32rr Reg:EAX Reg:EAX Reg:ESI | btcl %esi, %eax | "),
  (
    "x86", "67660fb33effe3", "7 BTR16mr Reg: Imm:1 Reg: Imm:-7169 Reg: Reg:DI | addr16  btrw %di, -7169 | may_load,may_store",
  ),
  ("x86", "66260fbaf048", "6 BTR16ri8 Reg:AX Reg:AX Imm:72 | btrw $72, %ax | "),
  (
    "x86", "67660fb3cd", "5 BTR16rr Reg:BP Reg:BP Reg:CX | addr16  btrw %cx, %bp | ",
  ),
  (
    "x86", "f20fb33e", "4 BTR32mr Reg:ESI Imm:1 Reg: Imm:0 Reg: Reg:EDI | btrl %edi, (%esi) | may_load,may_store",
  ),
  (
    "x86", "f30fbaf2c3", "5 BTR32ri8 Reg:EDX Reg:EDX Imm:195 | btrl $195, %edx | ",
  ),
  ("x86", "f30fb3e4", "4 BTR32rr Reg:ESP Reg:ESP Reg:ESP | btrl %esp, %esp | "),
  (
    "x86", "660fba2e0a", "5 BTS16mi8 Reg:ESI Imm:1 Reg: Imm:0 Reg: Imm:10 | btsw $10, (%esi) | may_load,may_store",
  ),
  (
    "x86", "66260fab0b", "5 BTS16mr Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Reg:CX | btsw %cx, %es:(%ebx) | may_load,may_store",
  ),
  (
    "x86", "67660fabea", "5 BTS16rr Reg:DX Reg:DX Reg:BP | addr16  btsw %bp, %dx | ",
  ),
  (
    "x86", "f2260fba2c9f00", "7 BTS32mi8 Reg:EDI Imm:4 Reg:EBX Imm:0 Reg:ES Imm:0 | repne  btsl $0, %es:(%edi,%ebx,4) | may_load,may_store",
  ),
  (
    "x86", "67f30fab4d04", "6 BTS32mr Reg:DI Imm:1 Reg: Imm:4 Reg: Reg:ECX | btsl %ecx, 4(%di) | may_load,may_store",
  ),
  (
    "x86", "260fbaeed6", "5 BTS32ri8 Reg:ESI Reg:ESI Imm:214 | btsl $214, %esi | ",
  ),
  ("x86", "6626dad5", "4 CMOVBE_F Reg:ST5 | fcmovbe %st(5), %st | "),
  ("x86", "f326dac1", "4 CMOVB_F Reg:ST1 | rep  fcmovb %st(1), %st | "),
  ("x86", "26dacf", "3 CMOVE_F Reg:ST7 | fcmove %st(7), %st | "),
  ("x86", "6626dbd0", "4 CMOVNBE_F Reg:ST0 | fcmovnbe %st(0), %st | "),
  ("x86", "6626dbc2", "4 CMOVNB_F Reg:ST2 | fcmovnb %st(2), %st | "),
  ("x86", "f326dbc9", "4 CMOVNE_F Reg:ST1 | rep  fcmovne %st(1), %st | "),
  ("x86", "26dbdc", "3 CMOVNP_F Reg:ST4 | fcmovnu %st(4), %st | "),
  ("x86", "6626dadb", "4 CMOVP_F Reg:ST3 | fcmovu %st(3), %st | "),
  (
    "x86", "6667263b3b", "5 CMP16rm Reg:DI Reg:BP Imm:1 Reg:DI Imm:0 Reg:ES | cmpw %es:(%bp,%di), %di | may_load",
  ),
  ("x86", "66f2263bfc", "5 CMP16rr_REV Reg:DI Reg:SP | repne  cmpw %sp, %di | "),
  ("x86", "263bdd", "3 CMP32rr_REV Reg:EBX Reg:EBP | cmpl %ebp, %ebx | "),
  (
    "x86", "662682bf8e1bb6ee87", "9 CMP8mi8 Reg:EDI Imm:1 Reg: Imm:-290055282 Reg:ES Imm:-121 | cmpb $-121, %es:-290055282(%edi) | may_load",
  ),
  (
    "x86", "f326386f7a", "5 CMP8mr Reg:EDI Imm:1 Reg: Imm:122 Reg:ES Reg:CH | rep  cmpb %ch, %es:122(%edi) | may_load",
  ),
  ("x86", "f22682fabb", "5 CMP8ri8 Reg:DL Imm:-69 | repne  cmpb $-69, %dl | "),
  (
    "x86", "6626fe09", "4 DEC8m Reg:ECX Imm:1 Reg: Imm:0 Reg:ES | decb %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86", "f326f6b4720c2d2a35", "9 DIV8m Reg:EDX Imm:2 Reg:ESI Imm:891956492 Reg:ES | rep  divb %es:891956492(%edx,%esi,2) | may_load",
  ),
  (
    "x86", "6626f6b966b42328", "8 IDIV8m Reg:ECX Imm:1 Reg: Imm:673428582 Reg:ES | idivb %es:673428582(%ecx) | may_load",
  ),
  (
    "x86", "66266b26ad", "5 IMUL16rmi8 Reg:SP Reg:ESI Imm:1 Reg: Imm:0 Reg:ES Imm:-83 | imulw $-83, %es:(%esi), %sp | may_load",
  ),
  (
    "x86", "26f66bc1", "4 IMUL8m Reg:EBX Imm:1 Reg: Imm:-63 Reg:ES | imulb %es:-63(%ebx) | may_load",
  ),
  (
    "x86", "f326ff82a2f1371d", "8 INC32m Reg:EDX Imm:1 Reg: Imm:490205602 Reg:ES | rep  incl %es:490205602(%edx) | may_load,may_store",
  ),
  (
    "x86", "f326fe4323", "5 INC8m Reg:EBX Imm:1 Reg: Imm:35 Reg:ES | rep  incb %es:35(%ebx) | may_load,may_store",
  ),
  (
    "x86", "66260f8517a5", "6 JCC_2 Imm:-23273 Imm:5 | jne -23273 | cond,terminator,affect_cf",
  ),
  (
    "x86", "66f30fbd9ab5b83dfa", "9 LZCNT16rm Reg:BX Reg:EDX Imm:1 Reg: Imm:-96618315 Reg: | lzcntw -96618315(%edx), %bx | may_load",
  ),
  (
    "x86", "67660f38f1b1e87e", "8 MOVBE16mr Reg:BX Imm:1 Reg:DI Imm:32488 Reg: Reg:SI | movbew %si, 32488(%bx,%di) | may_store",
  ),
  (
    "x86", "660fb609", "4 MOVZX16rm8 Reg:CX Reg:ECX Imm:1 Reg: Imm:0 Reg: | movzbw (%ecx), %cx | may_load",
  ),
  (
    "x86", "6626f66432bf", "6 MUL8m Reg:EDX Imm:1 Reg:ESI Imm:-65 Reg:ES | mulb %es:-65(%edx,%esi) | may_load",
  ),
  (
    "x86", "f226f699b59a97d7", "8 NEG8m Reg:ECX Imm:1 Reg: Imm:-677930315 Reg:ES | repne  negb %es:-677930315(%ecx) | may_load,may_store",
  ),
  (
    "x86", "6726f710", "4 NOT32m Reg:BX Imm:1 Reg:SI Imm:0 Reg:ES | notl %es:(%bx,%si) | may_load,may_store",
  ),
  (
    "x86", "f226f61519c95e46", "8 NOT8m Reg: Imm:1 Reg: Imm:1180616985 Reg:ES | repne  notb %es:1180616985 | may_load,may_store",
  ),
  (
    "x86", "666726834cdd4c", "7 OR16mi8 Reg:SI Imm:1 Reg: Imm:-35 Reg:ES Imm:76 | orw $76, %es:-35(%si) | may_load,may_store",
  ),
  (
    "x86", "66f326090f", "5 OR16mr Reg:EDI Imm:1 Reg: Imm:0 Reg:ES Reg:CX | rep  orw %cx, %es:(%edi) | may_load,may_store",
  ),
  (
    "x86", "66672609e6", "5 OR16rr Reg:SI Reg:SI Reg:SP | addr16  orw %sp, %si | ",
  ),
  (
    "x86", "6667260bce", "5 OR16rr_REV Reg:CX Reg:CX Reg:SI | addr16  orw %si, %cx | ",
  ),
  (
    "x86", "268389558d86107c", "8 OR32mi8 Reg:ECX Imm:1 Reg: Imm:277253461 Reg:ES Imm:124 | orl $124, %es:277253461(%ecx) | may_load,may_store",
  ),
  (
    "x86", "672609986252", "6 OR32mr Reg:BX Imm:1 Reg:SI Imm:21090 Reg:ES Reg:EBX | orl %ebx, %es:21090(%bx,%si) | may_load,may_store",
  ),
  (
    "x86", "67260b7283", "5 OR32rm Reg:ESI Reg:ESI Reg:BP Imm:1 Reg:SI Imm:-125 Reg:ES | orl %es:-125(%bp,%si), %esi | may_load",
  ),
  (
    "x86", "f3260bcf", "4 OR32rr_REV Reg:ECX Reg:ECX Reg:EDI | rep  orl %edi, %ecx | ",
  ),
  (
    "x86", "66268208b6", "5 OR8mi8 Reg:EAX Imm:1 Reg: Imm:0 Reg:ES Imm:-74 | orb $-74, %es:(%eax) | may_load,may_store",
  ),
  (
    "x86", "2608491e", "4 OR8mr Reg:ECX Imm:1 Reg: Imm:30 Reg:ES Reg:CL | orb %cl, %es:30(%ecx) | may_load,may_store",
  ),
  (
    "x86", "672682cd35", "5 OR8ri8 Reg:CH Reg:CH Imm:53 | addr16  orb $53, %ch | ",
  ),
  ("x86", "260ae1", "3 OR8rr_REV Reg:AH Reg:AH Reg:CL | orb %cl, %ah | "),
  (
    "x86", "66f326d397ecc28158", "9 RCL16mCL Reg:EDI Imm:1 Reg: Imm:1484899052 Reg:ES | rep  rclw %cl, %es:1484899052(%edi) | may_load,may_store",
  ),
  ("x86", "66f226d3d2", "5 RCL16rCL Reg:DX Reg:DX | repne  rclw %cl, %dx | "),
  (
    "x86", "6726d15790", "5 RCL32m1 Reg:BX Imm:1 Reg: Imm:-112 Reg:ES | rcll %es:-112(%bx) | may_load,may_store",
  ),
  (
    "x86", "6726d310", "4 RCL32mCL Reg:BX Imm:1 Reg:SI Imm:0 Reg:ES | rcll %cl, %es:(%bx,%si) | may_load,may_store",
  ),
  ("x86", "f326d1d0", "4 RCL32r1 Reg:EAX Reg:EAX | rep  rcll %eax | "),
  ("x86", "6726d3d4", "4 RCL32rCL Reg:ESP Reg:ESP | addr16  rcll %cl, %esp | "),
  (
    "x86", "26d011", "3 RCL8m1 Reg:ECX Imm:1 Reg: Imm:0 Reg:ES | rclb %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86", "6626d2956c8b5be2", "8 RCL8mCL Reg:EBP Imm:1 Reg: Imm:-497317012 Reg:ES | rclb %cl, %es:-497317012(%ebp) | may_load,may_store",
  ),
  ("x86", "6726d2d1", "4 RCL8rCL Reg:CL Reg:CL | addr16  rclb %cl, %cl | "),
  (
    "x86", "66f326d11dd62068f1", "9 RCR16m1 Reg: Imm:1 Reg: Imm:-244834090 Reg:ES | rep  rcrw %es:-244834090 | may_load,may_store",
  ),
  ("x86", "66f326d1da", "5 RCR16r1 Reg:DX Reg:DX | rep  rcrw %dx | "),
  (
    "x86", "6726d11f", "4 RCR32m1 Reg:BX Imm:1 Reg: Imm:0 Reg:ES | rcrl %es:(%bx) | may_load,may_store",
  ),
  (
    "x86", "f326d01d5855c69e", "8 RCR8m1 Reg: Imm:1 Reg: Imm:-1631169192 Reg:ES | rep  rcrb %es:-1631169192 | may_load,may_store",
  ),
  (
    "x86", "f226d25e4d", "5 RCR8mCL Reg:ESI Imm:1 Reg: Imm:77 Reg:ES | repne  rcrb %cl, %es:77(%esi) | may_load,may_store",
  ),
  ("x86", "6726d0dc", "4 RCR8r1 Reg:AH Reg:AH | addr16  rcrb %ah | "),
  ("x86", "f226d2df", "4 RCR8rCL Reg:BH Reg:BH | repne  rcrb %cl, %bh | "),
  ("x86", "66260fc7fd", "5 RDSEED16r Reg:BP | rdseedw %bp | "),
  (
    "x86", "6626d307", "4 ROL16mCL Reg:EDI Imm:1 Reg: Imm:0 Reg:ES | rolw %cl, %es:(%edi) | may_load,may_store",
  ),
  ("x86", "6626d3c4", "4 ROL16rCL Reg:SP Reg:SP | rolw %cl, %sp | "),
  (
    "x86", "f326d182ff7a66b5", "8 ROL32m1 Reg:EDX Imm:1 Reg: Imm:-1251575041 Reg:ES | rep  roll %es:-1251575041(%edx) | may_load,may_store",
  ),
  (
    "x86", "6726d300", "4 ROL32mCL Reg:BX Imm:1 Reg:SI Imm:0 Reg:ES | roll %cl, %es:(%bx,%si) | may_load,may_store",
  ),
  ("x86", "f326d1c0", "4 ROL32r1 Reg:EAX Reg:EAX | rep  roll %eax | "),
  (
    "x86", "f326d08056cf53f5", "8 ROL8m1 Reg:EAX Imm:1 Reg: Imm:-179056810 Reg:ES | rep  rolb %es:-179056810(%eax) | may_load,may_store",
  ),
  (
    "x86", "f326d243ae", "5 ROL8mCL Reg:EBX Imm:1 Reg: Imm:-82 Reg:ES | rep  rolb %cl, %es:-82(%ebx) | may_load,may_store",
  ),
  ("x86", "f226d2c0", "4 ROL8rCL Reg:AL Reg:AL | repne  rolb %cl, %al | "),
  (
    "x86", "66f326d18847db444d", "9 ROR16m1 Reg:EAX Imm:1 Reg: Imm:1296358215 Reg:ES | rep  rorw %es:1296358215(%eax) | may_load,may_store",
  ),
  ("x86", "6626d1cf", "4 ROR16r1 Reg:DI Reg:DI | rorw %di | "),
  (
    "x86", "6726d10d", "4 ROR32m1 Reg:DI Imm:1 Reg: Imm:0 Reg:ES | rorl %es:(%di) | may_load,may_store",
  ),
  (
    "x86", "26d008", "3 ROR8m1 Reg:EAX Imm:1 Reg: Imm:0 Reg:ES | rorb %es:(%eax) | may_load,may_store",
  ),
  (
    "x86", "f326d24bc1", "5 ROR8mCL Reg:EBX Imm:1 Reg: Imm:-63 Reg:ES | rep  rorb %cl, %es:-63(%ebx) | may_load,may_store",
  ),
  ("x86", "6726d0cd", "4 ROR8r1 Reg:CH Reg:CH | addr16  rorb %ch | "),
  ("x86", "6726d2cb", "4 ROR8rCL Reg:BL Reg:BL | addr16  rorb %cl, %bl | "),
  (
    "x86", "666726d17b04", "6 SAR16m1 Reg:BP Imm:1 Reg:DI Imm:4 Reg:ES | sarw %es:4(%bp,%di) | may_load,may_store",
  ),
  (
    "x86", "666726d379d4", "6 SAR16mCL Reg:BX Imm:1 Reg:DI Imm:-44 Reg:ES | sarw %cl, %es:-44(%bx,%di) | may_load,may_store",
  ),
  ("x86", "666726d1fe", "5 SAR16r1 Reg:SI Reg:SI | addr16  sarw %si | "),
  ("x86", "666726d3fb", "5 SAR16rCL Reg:BX Reg:BX | addr16  sarw %cl, %bx | "),
  (
    "x86", "f226d139", "4 SAR32m1 Reg:ECX Imm:1 Reg: Imm:0 Reg:ES | repne  sarl %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86", "6726d3bb347f", "6 SAR32mCL Reg:BP Imm:1 Reg:DI Imm:32564 Reg:ES | sarl %cl, %es:32564(%bp,%di) | may_load,may_store",
  ),
  (
    "x86", "f326d07ca642", "6 SAR8m1 Reg:ESI Imm:4 Reg:EIZ Imm:66 Reg:ES | rep  sarb %es:66(%esi,%eiz,4) | may_load,may_store",
  ),
  (
    "x86", "6626d238", "4 SAR8mCL Reg:EAX Imm:1 Reg: Imm:0 Reg:ES | sarb %cl, %es:(%eax) | may_load,may_store",
  ),
  ("x86", "26d0f8", "3 SAR8r1 Reg:AL Reg:AL | sarb %al | "),
  ("x86", "26d2f8", "3 SAR8rCL Reg:AL Reg:AL | sarb %cl, %al | "),
  (
    "x86", "666726835b1a71", "7 SBB16mi8 Reg:BP Imm:1 Reg:DI Imm:26 Reg:ES Imm:113 | sbbw $113, %es:26(%bp,%di) | may_load,may_store",
  ),
  (
    "x86", "66f226192ce8", "6 SBB16mr Reg:EAX Imm:8 Reg:EBP Imm:0 Reg:ES Reg:BP | repne  sbbw %bp, %es:(%eax,%ebp,8) | may_load,may_store",
  ),
  (
    "x86", "66f22619f8", "5 SBB16rr Reg:AX Reg:AX Reg:DI | repne  sbbw %di, %ax | ",
  ),
  (
    "x86", "672619164f8e", "6 SBB32mr Reg: Imm:1 Reg: Imm:-29105 Reg:ES Reg:EDX | addr16  sbbl %edx, %es:-29105 | may_load,may_store",
  ),
  (
    "x86", "f326825c55e2d5", "7 SBB8mi8 Reg:EBP Imm:2 Reg:EDX Imm:-30 Reg:ES Imm:-43 | rep  sbbb $-43, %es:-30(%ebp,%edx,2) | may_load,may_store",
  ),
  (
    "x86", "f226183b", "4 SBB8mr Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Reg:BH | repne  sbbb %bh, %es:(%ebx) | may_load,may_store",
  ),
  ("x86", "662682dc0b", "5 SBB8ri8 Reg:AH Reg:AH Imm:11 | sbbb $11, %ah | "),
  (
    "x86", "f3261a8de2f26482", "8 SBB8rm Reg:CL Reg:CL Reg:EBP Imm:1 Reg: Imm:-2107313438 Reg:ES | rep  sbbb %es:-2107313438(%ebp), %cl | may_load",
  ),
  ("x86", "f22618d9", "4 SBB8rr Reg:CL Reg:CL Reg:BL | repne  sbbb %bl, %cl | "),
  (
    "x86", "666726d325", "5 SHL16mCL Reg:DI Imm:1 Reg: Imm:0 Reg:ES | shlw %cl, %es:(%di) | may_load,may_store",
  ),
  ("x86", "66f226d3e4", "5 SHL16rCL Reg:SP Reg:SP | repne  shlw %cl, %sp | "),
  (
    "x86", "f326d12483", "5 SHL32m1 Reg:EBX Imm:4 Reg:EAX Imm:0 Reg:ES | rep  shll %es:(%ebx,%eax,4) | may_load,may_store",
  ),
  (
    "x86", "f226d36004", "5 SHL32mCL Reg:EAX Imm:1 Reg: Imm:4 Reg:ES | repne  shll %cl, %es:4(%eax) | may_load,may_store",
  ),
  (
    "x86", "f326d0a5ef59771d", "8 SHL8m1 Reg:EBP Imm:1 Reg: Imm:494361071 Reg:ES | rep  shlb %es:494361071(%ebp) | may_load,may_store",
  ),
  (
    "x86", "26d222", "3 SHL8mCL Reg:EDX Imm:1 Reg: Imm:0 Reg:ES | shlb %cl, %es:(%edx) | may_load,may_store",
  ),
  ("x86", "6626d2e5", "4 SHL8rCL Reg:CH Reg:CH | shlb %cl, %ch | "),
  (
    "x86", "66260fa47fd430", "7 SHLD16mri8 Reg:EDI Imm:1 Reg: Imm:-44 Reg:ES Reg:DI Imm:48 | shldw $48, %di, %es:-44(%edi) | may_load,may_store",
  ),
  (
    "x86", "660fa5f0", "4 SHLD16rrCL Reg:AX Reg:AX Reg:SI | shldw %cl, %si, %ax | ",
  ),
  (
    "x86", "260fa41cc8ba", "6 SHLD32mri8 Reg:EAX Imm:8 Reg:ECX Imm:0 Reg:ES Reg:EBX Imm:186 | shldl $186, %ebx, %es:(%eax,%ecx,8) | may_load,may_store",
  ),
  (
    "x86", "66f226d12b", "5 SHR16m1 Reg:EBX Imm:1 Reg: Imm:0 Reg:ES | repne  shrw %es:(%ebx) | may_load,may_store",
  ),
  ("x86", "66f226d1ec", "5 SHR16r1 Reg:SP Reg:SP | repne  shrw %sp | "),
  (
    "x86", "f326d16d9f", "5 SHR32m1 Reg:EBP Imm:1 Reg: Imm:-97 Reg:ES | rep  shrl %es:-97(%ebp) | may_load,may_store",
  ),
  (
    "x86", "f326d0abecbcb1d0", "8 SHR8m1 Reg:EBX Imm:1 Reg: Imm:-793658132 Reg:ES | rep  shrb %es:-793658132(%ebx) | may_load,may_store",
  ),
  (
    "x86", "26d2ab0172c837", "7 SHR8mCL Reg:EBX Imm:1 Reg: Imm:935883265 Reg:ES | shrb %cl, %es:935883265(%ebx) | may_load,may_store",
  ),
  ("x86", "f226d2ec", "4 SHR8rCL Reg:AH Reg:AH | repne  shrb %cl, %ah | "),
  (
    "x86", "660fad6e39", "5 SHRD16mrCL Reg:ESI Imm:1 Reg: Imm:57 Reg: Reg:BP | shrdw %cl, %bp, 57(%esi) | may_load,may_store",
  ),
  (
    "x86", "f20fad30", "4 SHRD32mrCL Reg:EAX Imm:1 Reg: Imm:0 Reg: Reg:ESI | shrdl %cl, %esi, (%eax) | may_load,may_store",
  ),
  (
    "x86", "67f30fac9f88e0bb", "8 SHRD32mri8 Reg:BX Imm:1 Reg: Imm:-8056 Reg: Reg:EBX Imm:187 | shrdl $187, %ebx, -8056(%bx) | may_load,may_store",
  ),
  (
    "x86", "f20facd11f", "5 SHRD32rri8 Reg:ECX Reg:ECX Reg:EDX Imm:31 | shrdl $31, %edx, %ecx | ",
  ),
  (
    "x86", "6626832980", "5 SUB16mi8 Reg:ECX Imm:1 Reg: Imm:0 Reg:ES Imm:-128 | subw $-128, %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86", "66f32683ee04", "6 SUB16ri8 Reg:SI Reg:SI Imm:4 | rep  subw $4, %si | ",
  ),
  (
    "x86", "66262bb04f47e1a2", "8 SUB16rm Reg:SI Reg:SI Reg:EAX Imm:1 Reg: Imm:-1562294449 Reg:ES | subw %es:-1562294449(%eax), %si | may_load",
  ),
  (
    "x86", "66f22629ce", "5 SUB16rr Reg:SI Reg:SI Reg:CX | repne  subw %cx, %si | ",
  ),
  (
    "x86", "66f2262bce", "5 SUB16rr_REV Reg:CX Reg:CX Reg:SI | repne  subw %si, %cx | ",
  ),
  (
    "x86", "26832f6d", "4 SUB32mi8 Reg:EDI Imm:1 Reg: Imm:0 Reg:ES Imm:109 | subl $109, %es:(%edi) | may_load,may_store",
  ),
  (
    "x86", "672682a92facf0", "7 SUB8mi8 Reg:BX Imm:1 Reg:DI Imm:-21457 Reg:ES Imm:-16 | subb $-16, %es:-21457(%bx,%di) | may_load,may_store",
  ),
  (
    "x86", "262833", "3 SUB8mr Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Reg:DH | subb %dh, %es:(%ebx) | may_load,may_store",
  ),
  (
    "x86", "f32682e88a", "5 SUB8ri8 Reg:AL Reg:AL Imm:-118 | rep  subb $-118, %al | ",
  ),
  (
    "x86", "f3268506", "4 TEST32mr Reg:ESI Imm:1 Reg: Imm:0 Reg:ES Reg:EAX | rep  testl %eax, %es:(%esi) | may_load",
  ),
  (
    "x86", "66f30fbc9333376360", "9 TZCNT16rm Reg:DX Reg:EBX Imm:1 Reg: Imm:1617114931 Reg: | tzcntw 1617114931(%ebx), %dx | may_load",
  ),
  (
    "x86", "6766f30fbcdb", "6 TZCNT16rr Reg:BX Reg:BX | addr16  tzcntw %bx, %bx | ",
  ),
  (
    "x86", "f30fbc9cc12b137bef", "9 TZCNT32rm Reg:EBX Reg:ECX Imm:8 Reg:EAX Imm:-277146837 Reg: | tzcntl -277146837(%ecx,%eax,8), %ebx | may_load",
  ),
  (
    "x86", "66f32683f49b", "6 XOR16ri8 Reg:SP Reg:SP Imm:-101 | rep  xorw $-101, %sp | ",
  ),
  (
    "x86", "66f22633cf", "5 XOR16rr_REV Reg:CX Reg:CX Reg:DI | repne  xorw %di, %cx | ",
  ),
  (
    "x86", "f32633dd", "4 XOR32rr_REV Reg:EBX Reg:EBX Reg:EBP | rep  xorl %ebp, %ebx | ",
  ),
  (
    "x86", "67268274e43f", "6 XOR8mi8 Reg:SI Imm:1 Reg: Imm:-28 Reg:ES Imm:63 | xorb $63, %es:-28(%si) | may_load,may_store",
  ),
  (
    "x86", "67263072ba", "5 XOR8mr Reg:BP Imm:1 Reg:SI Imm:-70 Reg:ES Reg:DH | xorb %dh, %es:-70(%bp,%si) | may_load,may_store",
  ),
  (
    "x86", "f22682f50e", "5 XOR8ri8 Reg:CH Reg:CH Imm:14 | repne  xorb $14, %ch | ",
  ),
  (
    "x86", "f326326c1978", "6 XOR8rm Reg:CH Reg:CH Reg:ECX Imm:1 Reg:EBX Imm:120 Reg:ES | rep  xorb %es:120(%ecx,%ebx), %ch | may_load",
  ),
  (
    "x86_64", "8d0476", "3 LEA64_32r Reg:EAX Reg:RSI Imm:2 Reg:RSI Imm:0 Reg: | leal (%rsi,%rsi,2), %eax | ",
  ),
  ("x86_64", "4000f8", "3 ADD8rr Reg:AL Reg:AL Reg:DIL | addb %dil, %al | "),
  ("x86_64", "c3", "1 RET64  | retq | return,barrier,terminator,affect_cf"),
  ("x86_64", "89f8", "2 MOV32rr Reg:EAX Reg:EDI | movl %edi, %eax | "),
  ("x86_64", "6699", "2 CWD  | cwtd | "),
  ("x86_64", "66f7fe", "3 IDIV16r Reg:SI | idivw %si | "),
  (
    "x86_64", "0faff7", "3 IMUL32rr Reg:ESI Reg:ESI Reg:EDI | imull %edi, %esi | ",
  ),
  ("x86_64", "c1ef03", "3 SHR32ri Reg:EDI Reg:EDI Imm:3 | shrl $3, %edi | "),
  ("x86_64", "d3e0", "2 SHL32rCL Reg:EAX Reg:EAX | shll %cl, %eax | "),
  ("x86_64", "31f8", "2 XOR32rr Reg:EAX Reg:EAX Reg:EDI | xorl %edi, %eax | "),
  ("x86_64", "d3c0", "2 ROL32rCL Reg:EAX Reg:EAX | roll %cl, %eax | "),
  ("x86_64", "99", "1 CDQ  | cltd | "),
  ("x86_64", "f7fe", "2 IDIV32r Reg:ESI | idivl %esi | "),
  ("x86_64", "01d0", "2 ADD32rr Reg:EAX Reg:EAX Reg:EDX | addl %edx, %eax | "),
  ("x86_64", "f7f6", "2 DIV32r Reg:ESI | divl %esi | "),
  ("x86_64", "4889f8", "3 MOV64rr Reg:RAX Reg:RDI | movq %rdi, %rax | "),
  (
    "x86_64", "480fafc6", "4 IMUL64rr Reg:RAX Reg:RAX Reg:RSI | imulq %rsi, %rax | ",
  ),
  ("x86_64", "4809f1", "3 OR64rr Reg:RCX Reg:RCX Reg:RSI | orq %rsi, %rcx | "),
  ("x86_64", "48c1e920", "4 SHR64ri Reg:RCX Reg:RCX Imm:32 | shrq $32, %rcx | "),
  ("x86_64", "7406", "2 JCC_1 Imm:6 Imm:4 | je 6 | cond,terminator,affect_cf"),
  ("x86_64", "4899", "2 CQO  | cqto | "),
  ("x86_64", "48f7fe", "3 IDIV64r Reg:RSI | idivq %rsi | "),
  ("x86_64", "48f7f6", "3 DIV64r Reg:RSI | divq %rsi | "),
  ("x86_64", "4863c7", "3 MOVSX64rr32 Reg:RAX Reg:EDI | movslq %edi, %rax | "),
  ("x86_64", "4801c1", "3 ADD64rr Reg:RCX Reg:RCX Reg:RAX | addq %rax, %rcx | "),
  ("x86_64", "4839f7", "3 CMP64rr Reg:RDI Reg:RSI | cmpq %rsi, %rdi | "),
  ("x86_64", "0f9cc0", "3 SETCCr Reg:AL Imm:12 | setl %al | "),
  ("x86_64", "85ff", "2 TEST32rr Reg:EDI Reg:EDI | testl %edi, %edi | "),
  (
    "x86_64", "0f44c2", "3 CMOV32rr Reg:EAX Reg:EAX Reg:EDX Imm:4 | cmovel %edx, %eax | ",
  ),
  ("x86_64", "d1e8", "2 SHR32r1 Reg:EAX Reg:EAX | shrl %eax | "),
  (
    "x86_64", "2555555555", "5 AND32i32 Imm:1431655765 | andl $1431655765, %eax | ",
  ),
  ("x86_64", "29c7", "2 SUB32rr Reg:EDI Reg:EDI Reg:EAX | subl %eax, %edi | "),
  (
    "x86_64", "81e733333333", "6 AND32ri Reg:EDI Reg:EDI Imm:858993459 | andl $858993459, %edi | ",
  ),
  (
    "x86_64", "69c001010101", "6 IMUL32rri Reg:EAX Reg:EAX Imm:16843009 | imull $16843009, %eax, %eax | ",
  ),
  ("x86_64", "83cf01", "3 OR32ri8 Reg:EDI Reg:EDI Imm:1 | orl $1, %edi | "),
  ("x86_64", "0fbdc7", "3 BSR32rr Reg:EAX Reg:EAX Reg:EDI | bsrl %edi, %eax | "),
  ("x86_64", "83f01f", "3 XOR32ri8 Reg:EAX Reg:EAX Imm:31 | xorl $31, %eax | "),
  ("x86_64", "0fc8", "2 BSWAP32r Reg:EAX Reg:EAX | bswapl %eax | "),
  ("x86_64", "480fc8", "3 BSWAP64r Reg:RAX Reg:RAX | bswapq %rax | "),
  ("x86_64", "66c1c008", "4 ROL16ri Reg:AX Reg:AX Imm:8 | rolw $8, %ax | "),
  ("x86_64", "f7d8", "2 NEG32r Reg:EAX Reg:EAX | negl %eax | "),
  ("x86_64", "48f7d8", "3 NEG64r Reg:RAX Reg:RAX | negq %rax | "),
  ("x86_64", "f7d0", "2 NOT32r Reg:EAX Reg:EAX | notl %eax | "),
  (
    "x86_64", "8b07", "2 MOV32rm Reg:EAX Reg:RDI Imm:1 Reg: Imm:0 Reg: | movl (%rdi), %eax | may_load",
  ),
  ("x86_64", "83e107", "3 AND32ri8 Reg:ECX Reg:ECX Imm:7 | andl $7, %ecx | "),
  ("x86_64", "c1e611", "3 SHL32ri Reg:ESI Reg:ESI Imm:17 | shll $17, %esi | "),
  ("x86_64", "c1fe1b", "3 SAR32ri Reg:ESI Reg:ESI Imm:27 | sarl $27, %esi | "),
  ("x86_64", "09d1", "2 OR32rr Reg:ECX Reg:ECX Reg:EDX | orl %edx, %ecx | "),
  (
    "x86_64", "890f", "2 MOV32mr Reg:RDI Imm:1 Reg: Imm:0 Reg: Reg:ECX | movl %ecx, (%rdi) | may_store",
  ),
  (
    "x86_64", "b8ffffffff", "5 MOV32ri Reg:EAX Imm:4294967295 | movl $4294967295, %eax | ",
  ),
  ("x86_64", "83ff07", "3 CMP32ri8 Reg:EDI Imm:7 | cmpl $7, %edi | "),
  (
    "x86_64", "488d0d00000000", "7 LEA64r Reg:RCX Reg:RIP Imm:1 Reg: Imm:0 Reg: | leaq (%rip), %rcx | ",
  ),
  ("x86_64", "53", "1 PUSH64r Reg:RBX | pushq %rbx | may_store"),
  (
    "x86_64", "488b0500000000", "7 MOV64rm Reg:RAX Reg:RIP Imm:1 Reg: Imm:0 Reg: | movq (%rip), %rax | may_load",
  ),
  (
    "x86_64", "ff10", "2 CALL64m Reg:RAX Imm:1 Reg: Imm:0 Reg: | callq *(%rax) | call,affect_cf,may_load",
  ),
  ("x86_64", "6a07", "2 PUSH64i8 Imm:7 | pushq $7 | may_store"),
  ("x86_64", "e800000000", "5 CALL64pcrel32 Imm:0 | callq 0 | call,affect_cf"),
  (
    "x86_64", "4883c410", "4 ADD64ri8 Reg:RSP Reg:RSP Imm:16 | addq $16, %rsp | ",
  ),
  ("x86_64", "ffc0", "2 INC32r Reg:EAX Reg:EAX | incl %eax | "),
  ("x86_64", "5b", "1 POP64r Reg:RBX | popq %rbx | may_load"),
  (
    "x86_64", "e9cc000000", "5 JMP_4 Imm:204 | jmp 204 | uncond,barrier,terminator,affect_cf",
  ),
  ("x86_64", "48c1e005", "4 SHL64ri Reg:RAX Reg:RAX Imm:5 | shlq $5, %rax | "),
  (
    "x86_64", "660f6f0d00000000", "8 MOVDQArm Reg:XMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | movdqa (%rip), %xmm1 | may_load",
  ),
  (
    "x86_64", "660fefc0", "4 PXORrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | pxor %xmm0, %xmm0 | ",
  ),
  ("x86_64", "90", "1 NOOP  | nop | "),
  (
    "x86_64", "660f6fe9", "4 MOVDQArr Reg:XMM5 Reg:XMM1 | movdqa %xmm1, %xmm5 | ",
  ),
  (
    "x86_64", "660ffeea", "4 PADDDrr Reg:XMM5 Reg:XMM5 Reg:XMM2 | paddd %xmm2, %xmm5 | ",
  ),
  (
    "x86_64", "f30f6f3437", "5 MOVDQUrm Reg:XMM6 Reg:RDI Imm:1 Reg:RSI Imm:0 Reg: | movdqu (%rdi,%rsi), %xmm6 | may_load",
  ),
  (
    "x86_64", "66440f70c6f5", "6 PSHUFDri Reg:XMM8 Reg:XMM6 Imm:245 | pshufd $245, %xmm6, %xmm8 | ",
  ),
  (
    "x86_64", "660ff4f1", "4 PMULUDQrr Reg:XMM6 Reg:XMM6 Reg:XMM1 | pmuludq %xmm1, %xmm6 | ",
  ),
  (
    "x86_64", "66410f62f0", "5 PUNPCKLDQrr Reg:XMM6 Reg:XMM6 Reg:XMM8 | punpckldq %xmm8, %xmm6 | ",
  ),
  ("x86_64", "660f7ec0", "4 MOVPDI2DIrr Reg:EAX Reg:XMM0 | movd %xmm0, %eax | "),
  ("x86_64", "39ca", "2 CMP32rr Reg:EDX Reg:ECX | cmpl %ecx, %edx | "),
  (
    "x86_64", "0f1f440000", "5 NOOPL Reg:RAX Imm:1 Reg:RAX Imm:0 Reg: | nopl (%rax,%rax) | ",
  ),
  ("x86_64", "48ffc2", "3 INC64r Reg:RDX Reg:RDX | incq %rdx | "),
  (
    "x86_64", "0f8ef6000000", "6 JCC_4 Imm:246 Imm:14 | jle 246 | cond,terminator,affect_cf",
  ),
  ("x86_64", "4829f9", "3 SUB64rr Reg:RCX Reg:RCX Reg:RDI | subq %rdi, %rcx | "),
  ("x86_64", "4883f920", "4 CMP64ri8 Reg:RCX Imm:32 | cmpq $32, %rcx | "),
  ("x86_64", "4108c8", "3 OR8rr Reg:R8B Reg:R8B Reg:CL | orb %cl, %r8b | "),
  ("x86_64", "a801", "2 TEST8i8 Imm:1 | testb $1, %al | "),
  (
    "x86_64", "f30f10048e", "5 MOVSSrm Reg:XMM0 Reg:RSI Imm:4 Reg:RCX Imm:0 Reg: | movss (%rsi,%rcx,4), %xmm0 | may_load",
  ),
  (
    "x86_64", "f30f58c0", "4 ADDSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | addss %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f30f58048f", "5 ADDSSrm_Int Reg:XMM0 Reg:XMM0 Reg:RDI Imm:4 Reg:RCX Imm:0 Reg: | addss (%rdi,%rcx,4), %xmm0 | may_load",
  ),
  (
    "x86_64", "f30f11048a", "5 MOVSSmr Reg:RDX Imm:4 Reg:RCX Imm:0 Reg: Reg:XMM0 | movss %xmm0, (%rdx,%rcx,4) | may_store",
  ),
  ("x86_64", "4983c801", "4 OR64ri8 Reg:R8 Reg:R8 Imm:1 | orq $1, %r8 | "),
  (
    "x86_64", "eb64", "2 JMP_1 Imm:100 | jmp 100 | uncond,barrier,terminator,affect_cf",
  ),
  (
    "x86_64", "660f1f840000000000", "9 NOOPW Reg:RAX Imm:1 Reg:RAX Imm:0 Reg: | nopw (%rax,%rax) | ",
  ),
  (
    "x86_64", "420f10040f", "5 MOVUPSrm Reg:XMM0 Reg:RDI Imm:1 Reg:R9 Imm:0 Reg: | movups (%rdi,%r9), %xmm0 | may_load",
  ),
  (
    "x86_64", "0f58d2", "3 ADDPSrr Reg:XMM2 Reg:XMM2 Reg:XMM2 | addps %xmm2, %xmm2 | ",
  ),
  (
    "x86_64", "420f11140a", "5 MOVUPSmr Reg:RDX Imm:1 Reg:R9 Imm:0 Reg: Reg:XMM2 | movups %xmm2, (%rdx,%r9) | may_store",
  ),
  (
    "x86_64", "660f57c0", "4 XORPDrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | xorpd %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "0f57c0", "3 XORPSrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | xorps %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f20f100ccf", "5 MOVSDrm Reg:XMM1 Reg:RDI Imm:8 Reg:RCX Imm:0 Reg: | movsd (%rdi,%rcx,8), %xmm1 | may_load",
  ),
  (
    "x86_64", "f20f590cce", "5 MULSDrm_Int Reg:XMM1 Reg:XMM1 Reg:RSI Imm:8 Reg:RCX Imm:0 Reg: | mulsd (%rsi,%rcx,8), %xmm1 | may_load",
  ),
  (
    "x86_64", "f20f58c8", "4 ADDSDrr_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 | addsd %xmm0, %xmm1 | ",
  ),
  ("x86_64", "4885c0", "3 TEST64rr Reg:RAX Reg:RAX | testq %rax, %rax | "),
  ("x86_64", "0f28d0", "3 MOVAPSrr Reg:XMM2 Reg:XMM0 | movaps %xmm0, %xmm2 | "),
  (
    "x86_64", "f30f5ed1", "4 DIVSSrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM1 | divss %xmm1, %xmm2 | ",
  ),
  (
    "x86_64", "f30f5dc1", "4 MINSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | minss %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "f30f5cd0", "4 SUBSSrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 | subss %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "660f2ec1", "4 UCOMISDrr Reg:XMM0 Reg:XMM1 | ucomisd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f28d0", "4 MOVAPDrr Reg:XMM2 Reg:XMM0 | movapd %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "f20f5cd1", "4 SUBSDrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM1 | subsd %xmm1, %xmm2 | ",
  ),
  (
    "x86_64", "f20f5ed0", "4 DIVSDrr_Int Reg:XMM2 Reg:XMM2 Reg:XMM0 | divsd %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "f20f59c1", "4 MULSDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | mulsd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "f30f2cc0", "4 CVTTSS2SIrr_Int Reg:EAX Reg:XMM0 | cvttss2si %xmm0, %eax | ",
  ),
  (
    "x86_64", "f2480f2ac7", "5 CVTSI642SDrr_Int Reg:XMM0 Reg:XMM0 Reg:RDI | cvtsi2sd %rdi, %xmm0 | ",
  ),
  (
    "x86_64", "f20f5ac0", "4 CVTSD2SSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | cvtsd2ss %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f2480f2cc0", "5 CVTTSD2SI64rr_Int Reg:RAX Reg:XMM0 | cvttsd2si %xmm0, %rax | ",
  ),
  (
    "x86_64", "db6c2418", "4 LD_F80m Reg:RSP Imm:1 Reg: Imm:24 Reg: | fldt 24(%rsp) | may_load",
  ),
  ("x86_64", "dcc9", "2 MUL_FrST0 Reg:ST1 | fmul %st, %st(1) | "),
  ("x86_64", "dec1", "2 ADD_FPrST0 Reg:ST1 | faddp %st, %st(1) | "),
  ("x86_64", "48c7c0ffffffff", "7 MOV64ri32 Reg:RAX Imm:-1 | movq $-1, %rax | "),
  (
    "x86_64", "807c070100", "5 CMP8mi Reg:RDI Imm:1 Reg:RAX Imm:1 Reg: Imm:0 | cmpb $0, 1(%rdi,%rax) | may_load",
  ),
  ("x86_64", "400fb6fe", "4 MOVZX32rr8 Reg:EDI Reg:SIL | movzbl %sil, %edi | "),
  (
    "x86_64", "4883e1e0", "4 AND64ri8 Reg:RCX Reg:RCX Imm:-32 | andq $-32, %rcx | ",
  ),
  ("x86_64", "660f6ec7", "4 MOVDI2PDIrr Reg:XMM0 Reg:EDI | movd %edi, %xmm0 | "),
  (
    "x86_64", "660f60c0", "4 PUNPCKLBWrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | punpcklbw %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f20f70c000", "5 PSHUFLWri Reg:XMM0 Reg:XMM0 Imm:0 | pshuflw $0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f3420f7f0400", "6 MOVDQUmr Reg:RAX Imm:1 Reg:R8 Imm:0 Reg: Reg:XMM0 | movdqu %xmm0, (%rax,%r8) | may_store",
  ),
  ("x86_64", "f6c21c", "3 TEST8ri Reg:DL Imm:28 | testb $28, %dl | "),
  (
    "x86_64", "660f7e0408", "5 MOVPDI2DImr Reg:RAX Imm:1 Reg:RCX Imm:0 Reg: Reg:XMM0 | movd %xmm0, (%rax,%rcx) | may_store",
  ),
  (
    "x86_64", "41883408", "4 MOV8mr Reg:R8 Imm:1 Reg:RCX Imm:0 Reg: Reg:SIL | movb %sil, (%r8,%rcx) | may_store",
  ),
  (
    "x86_64", "0fb607", "3 MOVZX32rm8 Reg:EAX Reg:RDI Imm:1 Reg: Imm:0 Reg: | movzbl (%rdi), %eax | may_load",
  ),
  ("x86_64", "84c0", "2 TEST8rr Reg:AL Reg:AL | testb %al, %al | "),
  (
    "x86_64", "3a06", "2 CMP8rm Reg:AL Reg:RSI Imm:1 Reg: Imm:0 Reg: | cmpb (%rsi), %al | may_load",
  ),
  ("x86_64", "f0", "1 LOCK_PREFIX  | lock | "),
  (
    "x86_64", "830703", "3 ADD32mi8 Reg:RDI Imm:1 Reg: Imm:0 Reg: Imm:3 | addl $3, (%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "8707", "2 XCHG32rm Reg:EAX Reg:EAX Reg:RDI Imm:1 Reg: Imm:0 Reg: | xchgl %eax, (%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "0fb10f", "3 CMPXCHG32rm Reg:RDI Imm:1 Reg: Imm:0 Reg: Reg:ECX | cmpxchgl %ecx, (%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "480fb10f", "4 CMPXCHG64rm Reg:RDI Imm:1 Reg: Imm:0 Reg: Reg:RCX | cmpxchgq %rcx, (%rdi) | may_load,may_store",
  ),
  ("x86_64", "0fa3f7", "3 BT32rr Reg:EDI Reg:ESI | btl %esi, %edi | "),
  ("x86_64", "0fabf0", "3 BTS32rr Reg:EAX Reg:EAX Reg:ESI | btsl %esi, %eax | "),
  ("x86_64", "48f7e7", "3 MUL64r Reg:RDI | mulq %rdi | "),
  ("x86_64", "48f7ef", "3 IMUL64r Reg:RDI | imulq %rdi | "),
  (
    "x86_64", "480fa5f0", "4 SHLD64rrCL Reg:RAX Reg:RAX Reg:RSI | shldq %cl, %rsi, %rax | ",
  ),
  ("x86_64", "83c002", "3 ADD32ri8 Reg:EAX Reg:EAX Imm:2 | addl $2, %eax | "),
  (
    "x86_64", "c64424f801", "5 MOV8mi Reg:RSP Imm:1 Reg: Imm:-8 Reg: Imm:1 | movb $1, -8(%rsp) | may_store",
  ),
  (
    "x86_64", "660fdbd0", "4 PANDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | pand %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "660f76d0", "4 PCMPEQDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | pcmpeqd %xmm0, %xmm2 | ",
  ),
  ("x86_64", "48ffce", "3 DEC64r Reg:RSI Reg:RSI | decq %rsi | "),
  (
    "x86_64", "66333457", "4 XOR16rm Reg:SI Reg:SI Reg:RDI Imm:2 Reg:RDX Imm:0 Reg: | xorw (%rdi,%rdx,2), %si | may_load",
  ),
  ("x86_64", "66f7d8", "3 NEG16r Reg:AX Reg:AX | negw %ax | "),
  (
    "x86_64", "660f49c1", "4 CMOV16rr Reg:AX Reg:AX Reg:CX Imm:9 | cmovnsw %cx, %ax | ",
  ),
  ("x86_64", "40f6e7", "3 MUL8r Reg:DIL | mulb %dil | "),
  ("x86_64", "d0e9", "2 SHR8r1 Reg:CL Reg:CL | shrb %cl | "),
  ("x86_64", "30c8", "2 XOR8rr Reg:AL Reg:AL Reg:CL | xorb %cl, %al | "),
  ("x86_64", "4038f7", "3 CMP8rr Reg:DIL Reg:SIL | cmpb %sil, %dil | "),
  ("x86_64", "1400", "2 ADC8i8 Imm:0 | adcb $0, %al | "),
  (
    "x86_64", "0f59c8", "3 MULPSrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | mulps %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "0f5cc8", "3 SUBPSrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | subps %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f5ec1", "4 DIVPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | divpd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f71f003", "5 PSLLWri Reg:XMM0 Reg:XMM0 Imm:3 | psllw $3, %xmm0 | ",
  ),
  (
    "x86_64", "660ffdc1", "4 PADDWrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | paddw %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660fdac8", "4 PMINUBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminub %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f74c8", "4 PCMPEQBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pcmpeqb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fdfc8", "4 PANDNrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pandn %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "4883ec20", "4 SUB64ri8 Reg:RSP Reg:RSP Imm:32 | subq $32, %rsp | ",
  ),
  (
    "x86_64", "660ffe4510", "5 PADDDrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:16 Reg: | paddd 16(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "0f284510", "4 MOVAPSrm Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:16 Reg: | movaps 16(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "0f594530", "4 MULPSrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:48 Reg: | mulps 48(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "f75c86fc", "4 NEG32m Reg:RSI Imm:4 Reg:RAX Imm:-4 Reg: | negl -4(%rsi,%rax,4) | may_load,may_store",
  ),
  (
    "x86_64", "49631490", "4 MOVSX64rm32 Reg:RDX Reg:R8 Imm:4 Reg:RDX Imm:0 Reg: | movslq (%r8,%rdx,4), %rdx | may_load",
  ),
  (
    "x86_64", "ffe2", "2 JMP64r Reg:RDX | jmpq *%rdx | indirect,barrier,terminator,affect_cf",
  ),
  ("x86_64", "ffc9", "2 DEC32r Reg:ECX Reg:ECX | decl %ecx | "),
  (
    "x86_64", "295486f8", "4 SUB32mr Reg:RSI Imm:4 Reg:RAX Imm:-8 Reg: Reg:EDX | subl %edx, -8(%rsi,%rax,4) | may_load,may_store",
  ),
  (
    "x86_64", "0faf5486fc", "5 IMUL32rm Reg:EDX Reg:EDX Reg:RSI Imm:4 Reg:RAX Imm:-4 Reg: | imull -4(%rsi,%rax,4), %edx | may_load",
  ),
  (
    "x86_64", "015486f8", "4 ADD32mr Reg:RSI Imm:4 Reg:RAX Imm:-8 Reg: Reg:EDX | addl %edx, -8(%rsi,%rax,4) | may_load,may_store",
  ),
  (
    "x86_64", "837c96fc00", "5 CMP32mi8 Reg:RSI Imm:4 Reg:RDX Imm:-4 Reg: Imm:0 | cmpl $0, -4(%rsi,%rdx,4) | may_load",
  ),
  (
    "x86_64", "3b5486fc", "4 CMP32rm Reg:EDX Reg:RSI Imm:4 Reg:RAX Imm:-4 Reg: | cmpl -4(%rsi,%rax,4), %edx | may_load",
  ),
  (
    "x86_64", "42f77c96fc", "5 IDIV32m Reg:RSI Imm:4 Reg:R10 Imm:-4 Reg: | idivl -4(%rsi,%r10,4) | may_load",
  ),
  (
    "x86_64", "f20f584cc7f8", "6 ADDSDrm_Int Reg:XMM1 Reg:XMM1 Reg:RDI Imm:8 Reg:RAX Imm:-8 Reg: | addsd -8(%rdi,%rax,8), %xmm1 | may_load",
  ),
  (
    "x86_64", "f30f5fc1", "4 MAXSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | maxss %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f280d00000000", "8 MOVAPDrm Reg:XMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | movapd (%rip), %xmm1 | may_load",
  ),
  (
    "x86_64", "f20f5fc8", "4 MAXSDrr_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 | maxsd %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "f20f5c0500000000", "8 SUBSDrm_Int Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | subsd (%rip), %xmm0 | may_load",
  ),
  ("x86_64", "48c1fa3f", "4 SAR64ri Reg:RDX Reg:RDX Imm:63 | sarq $63, %rdx | "),
  ("x86_64", "4821d0", "3 AND64rr Reg:RAX Reg:RAX Reg:RDX | andq %rdx, %rax | "),
  (
    "x86_64", "66480f6ecf", "5 MOV64toPQIrr Reg:XMM1 Reg:RDI | movq %rdi, %xmm1 | ",
  ),
  (
    "x86_64", "660f620d00000000", "8 PUNPCKLDQrm Reg:XMM1 Reg:XMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | punpckldq (%rip), %xmm1 | may_load",
  ),
  (
    "x86_64", "660f5c0d00000000", "8 SUBPDrm Reg:XMM1 Reg:XMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | subpd (%rip), %xmm1 | may_load",
  ),
  (
    "x86_64", "660f15c1", "4 UNPCKHPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | unpckhpd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "f3480f2ac0", "5 CVTSI642SSrr_Int Reg:XMM0 Reg:XMM0 Reg:RAX | cvtsi2ss %rax, %xmm0 | ",
  ),
  (
    "x86_64", "f20fc2c100", "5 CMPSDrri_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 Imm:0 | cmpeqsd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "66480f7ec2", "5 MOVPQIto64rr Reg:RDX Reg:XMM0 | movq %xmm0, %rdx | ",
  ),
  (
    "x86_64", "0fbf4f0c", "4 MOVSX32rm16 Reg:ECX Reg:RDI Imm:1 Reg: Imm:12 Reg: | movswl 12(%rdi), %ecx | may_load",
  ),
  (
    "x86_64", "0fbe570e", "4 MOVSX32rm8 Reg:EDX Reg:RDI Imm:1 Reg: Imm:14 Reg: | movsbl 14(%rdi), %edx | may_load",
  ),
  (
    "x86_64", "034708", "3 ADD32rm Reg:EAX Reg:EAX Reg:RDI Imm:1 Reg: Imm:8 Reg: | addl 8(%rdi), %eax | may_load",
  ),
  (
    "x86_64", "48c7041700000000", "8 MOV64mi32 Reg:RDI Imm:1 Reg:RDX Imm:0 Reg: Imm:0 | movq $0, (%rdi,%rdx) | may_store",
  ),
  ("x86_64", "4831f8", "3 XOR64rr Reg:RAX Reg:RAX Reg:RDI | xorq %rdi, %rax | "),
  (
    "x86_64", "48b9cd8c55edd7af51ff", "10 MOV64ri Reg:RCX Imm:-49064778989728563 | movabsq $-49064778989728563, %rcx | ",
  ),
  (
    "x86_64", "f30f5ac2", "4 CVTSS2SDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM2 | cvtss2sd %xmm2, %xmm0 | ",
  ),
  (
    "x86_64", "f20f2cc1", "4 CVTTSD2SIrr_Int Reg:EAX Reg:XMM1 | cvttsd2si %xmm1, %eax | ",
  ),
  (
    "x86_64", "48897424a8", "5 MOV64mr Reg:RSP Imm:1 Reg: Imm:-88 Reg: Reg:RSI | movq %rsi, -88(%rsp) | may_store",
  ),
  (
    "x86_64", "0f294424d0", "5 MOVAPSmr Reg:RSP Imm:1 Reg: Imm:-48 Reg: Reg:XMM0 | movaps %xmm0, -48(%rsp) | may_store",
  ),
  ("x86_64", "0f31", "2 RDTSC  | rdtsc | "),
  ("x86_64", "f390", "2 PAUSE  | pause | may_load,may_store"),
  ("x86_64", "4088f0", "3 MOV8rr Reg:AL Reg:SIL | movb %sil, %al | "),
  (
    "x86_64", "6bc903", "3 IMUL32rri8 Reg:ECX Reg:ECX Imm:3 | imull $3, %ecx, %ecx | ",
  ),
  ("x86_64", "6689f0", "3 MOV16rr Reg:AX Reg:SI | movw %si, %ax | "),
  (
    "x86_64", "66894dfe", "4 MOV16mr Reg:RBP Imm:1 Reg: Imm:-2 Reg: Reg:CX | movw %cx, -2(%rbp) | may_store",
  ),
  (
    "x86_64", "0fb745fe", "4 MOVZX32rm16 Reg:EAX Reg:RBP Imm:1 Reg: Imm:-2 Reg: | movzwl -2(%rbp), %eax | may_load",
  ),
  (
    "x86_64", "2b4df8", "3 SUB32rm Reg:ECX Reg:ECX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | subl -8(%rbp), %ecx | may_load",
  ),
  ("x86_64", "d3ea", "2 SHR32rCL Reg:EDX Reg:EDX | shrl %cl, %edx | "),
  (
    "x86_64", "f775f8", "3 DIV32m Reg:RBP Imm:1 Reg: Imm:-8 Reg: | divl -8(%rbp) | may_load",
  ),
  (
    "x86_64", "480faf45f0", "5 IMUL64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-16 Reg: | imulq -16(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "48f77df0", "4 IDIV64m Reg:RBP Imm:1 Reg: Imm:-16 Reg: | idivq -16(%rbp) | may_load",
  ),
  (
    "x86_64", "48f775f0", "4 DIV64m Reg:RBP Imm:1 Reg: Imm:-16 Reg: | divq -16(%rbp) | may_load",
  ),
  (
    "x86_64", "480fbe45ff", "5 MOVSX64rm8 Reg:RAX Reg:RBP Imm:1 Reg: Imm:-1 Reg: | movsbq -1(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "480fbf4dfc", "5 MOVSX64rm16 Reg:RCX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | movswq -4(%rbp), %rcx | may_load",
  ),
  (
    "x86_64", "483b45f0", "4 CMP64rm Reg:RAX Reg:RBP Imm:1 Reg: Imm:-16 Reg: | cmpq -16(%rbp), %rax | may_load",
  ),
  ("x86_64", "2401", "2 AND8i8 Imm:1 | andb $1, %al | "),
  ("x86_64", "f3480fbcc1", "5 TZCNT64rr Reg:RAX Reg:RCX | tzcntq %rcx, %rax | "),
  (
    "x86_64", "668b45fe", "4 MOV16rm Reg:AX Reg:RBP Imm:1 Reg: Imm:-2 Reg: | movw -2(%rbp), %ax | may_load",
  ),
  (
    "x86_64", "482b45f8", "4 SUB64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | subq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "6b55f403", "4 IMUL32rmi8 Reg:EDX Reg:RBP Imm:1 Reg: Imm:-12 Reg: Imm:3 | imull $3, -12(%rbp), %edx | may_load",
  ),
  (
    "x86_64", "c745fc0b000000", "7 MOV32mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:11 | movl $11, -4(%rbp) | may_store",
  ),
  ("x86_64", "ffd0", "2 CALL64r Reg:RAX | callq *%rax | call,affect_cf"),
  (
    "x86_64", "f20f1145e0", "5 MOVSDmr Reg:RBP Imm:1 Reg: Imm:-32 Reg: Reg:XMM0 | movsd %xmm0, -32(%rbp) | may_store",
  ),
  (
    "x86_64", "f30f5e45f8", "5 DIVSSrm_Int Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | divss -8(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "0f2ec1", "3 UCOMISSrr Reg:XMM0 Reg:XMM1 | ucomiss %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f2e45f0", "5 UCOMISDrm Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-16 Reg: | ucomisd -16(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "f20f5e45f8", "5 DIVSDrm_Int Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | divsd -8(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "f30f2c45fc", "5 CVTTSS2SIrm_Int Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | cvttss2si -4(%rbp), %eax | may_load",
  ),
  (
    "x86_64", "f2480f2a45f8", "6 CVTSI642SDrm_Int Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | cvtsi2sdq -8(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "f2480f2c45f8", "6 CVTTSD2SI64rm_Int Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | cvttsd2si -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "db7df0", "3 ST_FP80m Reg:RBP Imm:1 Reg: Imm:-16 Reg: | fstpt -16(%rbp) | may_store",
  ),
  ("x86_64", "d8c9", "2 MUL_FST0r Reg:ST1 | fmul %st(1), %st | "),
  (
    "x86_64", "8a45ef", "3 MOV8rm Reg:AL Reg:RBP Imm:1 Reg: Imm:-17 Reg: | movb -17(%rbp), %al | may_load",
  ),
  (
    "x86_64", "0fc101", "3 XADD32rm Reg:EAX Reg:EAX Reg:RCX Imm:1 Reg: Imm:0 Reg: | xaddl %eax, (%rcx) | may_load,may_store",
  ),
  ("x86_64", "48d3e0", "3 SHL64rCL Reg:RAX Reg:RAX | shlq %cl, %rax | "),
  ("x86_64", "48d3ea", "3 SHR64rCL Reg:RDX Reg:RDX | shrq %cl, %rdx | "),
  ("x86_64", "80e101", "3 AND8ri Reg:CL Reg:CL Imm:1 | andb $1, %cl | "),
  ("x86_64", "d1e1", "2 SHL32r1 Reg:ECX Reg:ECX | shll %ecx | "),
  (
    "x86_64", "4881ec10130000", "7 SUB64ri32 Reg:RSP Reg:RSP Imm:4880 | subq $4880, %rsp | ",
  ),
  (
    "x86_64", "4881c410130000", "7 ADD64ri32 Reg:RSP Reg:RSP Imm:4880 | addq $4880, %rsp | ",
  ),
  (
    "x86_64", "3345f0", "3 XOR32rm Reg:EAX Reg:EAX Reg:RBP Imm:1 Reg: Imm:-16 Reg: | xorl -16(%rbp), %eax | may_load",
  ),
  ("x86_64", "83e801", "3 SUB32ri8 Reg:EAX Reg:EAX Imm:1 | subl $1, %eax | "),
  (
    "x86_64", "66c745f20000", "6 MOV16mi Reg:RBP Imm:1 Reg: Imm:-14 Reg: Imm:0 | movw $0, -14(%rbp) | may_store",
  ),
  ("x86_64", "0fb7c0", "3 MOVZX32rr16 Reg:EAX Reg:AX | movzwl %ax, %eax | "),
  ("x86_64", "0fbfc8", "3 MOVSX32rr16 Reg:ECX Reg:AX | movswl %ax, %ecx | "),
  ("x86_64", "d1f9", "2 SAR32r1 Reg:ECX Reg:ECX | sarl %ecx | "),
  (
    "x86_64", "660f2945f0", "5 MOVAPDmr Reg:RBP Imm:1 Reg: Imm:-16 Reg: Reg:XMM0 | movapd %xmm0, -16(%rbp) | may_store",
  ),
  (
    "x86_64", "660f5e45e0", "5 DIVPDrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-32 Reg: | divpd -32(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "660ffd45e0", "5 PADDWrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-32 Reg: | paddw -32(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "660fdb45f0", "5 PANDrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-16 Reg: | pand -16(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "0f2e45f8", "4 UCOMISSrm Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | ucomiss -8(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "f30f7e45f8", "5 MOVQI2PQIrm Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | movq -8(%rbp), %xmm0 | may_load",
  ),
  (
    "x86_64", "660f5cc1", "4 SUBPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | subpd %xmm1, %xmm0 | ",
  ),
  ("x86_64", "20c8", "2 AND8rr Reg:AL Reg:AL Reg:CL | andb %cl, %al | "),
  (
    "x86_64", "48837df800", "5 CMP64mi8 Reg:RBP Imm:1 Reg: Imm:-8 Reg: Imm:0 | cmpq $0, -8(%rbp) | may_load",
  ),
  (
    "x86_64", "483345f8", "4 XOR64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | xorq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "480345f0", "4 ADD64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-16 Reg: | addq -16(%rbp), %rax | may_load",
  ),
  ("x86_64", "0f0b", "2 TRAP  | ud2 | may_load"),
  ("x86_64", "21c1", "2 AND32rr Reg:ECX Reg:ECX Reg:EAX | andl %eax, %ecx | "),
  (
    "x86_64", "660f54d4", "4 ANDPDrr Reg:XMM2 Reg:XMM2 Reg:XMM4 | andpd %xmm4, %xmm2 | ",
  ),
  (
    "x86_64", "660f55e3", "4 ANDNPDrr Reg:XMM4 Reg:XMM4 Reg:XMM3 | andnpd %xmm3, %xmm4 | ",
  ),
  (
    "x86_64", "660f56e2", "4 ORPDrr Reg:XMM4 Reg:XMM4 Reg:XMM2 | orpd %xmm2, %xmm4 | ",
  ),
  (
    "x86_64", "f3a5", "2 MOVSL Reg:RDI Reg:RSI Reg: | rep  movsl (%rsi), %es:(%rdi) | ",
  ),
  (
    "x86_64", "c4e249f7c7", "5 SHLX32rr Reg:EAX Reg:EDI Reg:ESI | shlxl %esi, %edi, %eax | ",
  ),
  ("x86_64", "f30fb8c7", "4 POPCNT32rr Reg:EAX Reg:EDI | popcntl %edi, %eax | "),
  ("x86_64", "f30fbdc7", "4 LZCNT32rr Reg:EAX Reg:EDI | lzcntl %edi, %eax | "),
  (
    "x86_64", "c5fd6f0d00000000", "8 VMOVDQAYrm Reg:YMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vmovdqa (%rip), %ymm1 | may_load",
  ),
  (
    "x86_64", "c5f9efc0", "4 VPXORrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vpxor %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c4e27d581500000000", "9 VPBROADCASTDYrm Reg:YMM2 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vpbroadcastd (%rip), %ymm2 | may_load",
  ),
  (
    "x86_64", "c575feca", "4 VPADDDYrr Reg:YMM9 Reg:YMM1 Reg:YMM2 | vpaddd %ymm2, %ymm1, %ymm9 | ",
  ),
  (
    "x86_64", "c46275402437", "6 VPMULLDYrm Reg:YMM12 Reg:YMM1 Reg:RDI Imm:1 Reg:RSI Imm:0 Reg: | vpmulld (%rdi,%rsi), %ymm1, %ymm12 | may_load",
  ),
  (
    "x86_64", "c4e37d39c101", "6 VEXTRACTI128rri Reg:XMM1 Reg:YMM0 Imm:1 | vextracti128 $1, %ymm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f9fec1", "4 VPADDDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vpaddd %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f970c8ee", "5 VPSHUFDri Reg:XMM1 Reg:XMM0 Imm:238 | vpshufd $238, %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f97ec0", "4 VMOVPDI2DIrr Reg:EAX Reg:XMM0 | vmovd %xmm0, %eax | ",
  ),
  (
    "x86_64", "c5f96ec0", "4 VMOVDI2PDIrr Reg:XMM0 Reg:EAX | vmovd %eax, %xmm0 | ",
  ),
  (
    "x86_64", "c4e27958c9", "5 VPBROADCASTDrr Reg:XMM1 Reg:XMM1 | vpbroadcastd %xmm1, %xmm1 | ",
  ),
  (
    "x86_64", "c5f1eb0d00000000", "8 VPORrm Reg:XMM1 Reg:XMM1 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vpor (%rip), %xmm1, %xmm1 | may_load",
  ),
  (
    "x86_64", "c4e279581500000000", "9 VPBROADCASTDrm Reg:XMM2 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vpbroadcastd (%rip), %xmm2 | may_load",
  ),
  (
    "x86_64", "c4e271401cb7", "6 VPMULLDrm Reg:XMM3 Reg:XMM1 Reg:RDI Imm:4 Reg:RSI Imm:0 Reg: | vpmulld (%rdi,%rsi,4), %xmm1, %xmm3 | may_load",
  ),
  ("x86_64", "c5f877", "3 VZEROUPPER  | vzeroupper | "),
  ("x86_64", "4981f880000000", "7 CMP64ri32 Reg:R8 Imm:128 | cmpq $128, %r8 | "),
  (
    "x86_64", "c5fa100500000000", "8 VMOVSSrm Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vmovss (%rip), %xmm0 | may_load",
  ),
  (
    "x86_64", "c4a279a90c87", "6 VFMADD213SSm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:RDI Imm:4 Reg:R8 Imm:0 Reg: | vfmadd213ss (%rdi,%r8,4), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86_64", "c4a17a110c82", "6 VMOVSSmr Reg:RDX Imm:4 Reg:R8 Imm:0 Reg: Reg:XMM1 | vmovss %xmm1, (%rdx,%r8,4) | may_store",
  ),
  (
    "x86_64", "c4e27d180500000000", "9 VBROADCASTSSYrm Reg:YMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vbroadcastss (%rip), %ymm0 | may_load",
  ),
  (
    "x86_64", "c4a17c100c0e", "6 VMOVUPSYrm Reg:YMM1 Reg:RSI Imm:1 Reg:R9 Imm:0 Reg: | vmovups (%rsi,%r9), %ymm1 | may_load",
  ),
  (
    "x86_64", "c4a27da80c0f", "6 VFMADD213PSYm Reg:YMM1 Reg:YMM1 Reg:YMM0 Reg:RDI Imm:1 Reg:R9 Imm:0 Reg: | vfmadd213ps (%rdi,%r9), %ymm0, %ymm1 | may_load",
  ),
  (
    "x86_64", "c4a17c110c0a", "6 VMOVUPSYmr Reg:RDX Imm:1 Reg:R9 Imm:0 Reg: Reg:YMM1 | vmovups %ymm1, (%rdx,%r9) | may_store",
  ),
  (
    "x86_64", "c4e279180500000000", "9 VBROADCASTSSrm Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vbroadcastss (%rip), %xmm0 | may_load",
  ),
  (
    "x86_64", "c4a178100c86", "6 VMOVUPSrm Reg:XMM1 Reg:RSI Imm:4 Reg:R8 Imm:0 Reg: | vmovups (%rsi,%r8,4), %xmm1 | may_load",
  ),
  (
    "x86_64", "c4a279a80c87", "6 VFMADD213PSm Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:RDI Imm:4 Reg:R8 Imm:0 Reg: | vfmadd213ps (%rdi,%r8,4), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86_64", "c4a178110c82", "6 VMOVUPSmr Reg:RDX Imm:4 Reg:R8 Imm:0 Reg: Reg:XMM1 | vmovups %xmm1, (%rdx,%r8,4) | may_store",
  ),
  (
    "x86_64", "c5f957c0", "4 VXORPDrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vxorpd %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f857c0", "4 VXORPSrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | vxorps %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5fb100ccf", "5 VMOVSDrm Reg:XMM1 Reg:RDI Imm:8 Reg:RCX Imm:0 Reg: | vmovsd (%rdi,%rcx,8), %xmm1 | may_load",
  ),
  (
    "x86_64", "c4e2f9990cce", "6 VFMADD132SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:RSI Imm:8 Reg:RCX Imm:0 Reg: | vfmadd132sd (%rsi,%rcx,8), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86_64", "c4e2e9b94cce08", "7 VFMADD231SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM2 Reg:RSI Imm:8 Reg:RCX Imm:8 Reg: | vfmadd231sd 8(%rsi,%rcx,8), %xmm2, %xmm1 | may_load",
  ),
  (
    "x86_64", "c5fa5ed1", "4 VDIVSSrr_Int Reg:XMM2 Reg:XMM0 Reg:XMM1 | vdivss %xmm1, %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "c5fa5dc1", "4 VMINSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | vminss %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5ea5cc0", "4 VSUBSSrr_Int Reg:XMM0 Reg:XMM2 Reg:XMM0 | vsubss %xmm0, %xmm2, %xmm0 | ",
  ),
  (
    "x86_64", "c5f92ec1", "4 VUCOMISDrr Reg:XMM0 Reg:XMM1 | vucomisd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c5fb5cd1", "4 VSUBSDrr_Int Reg:XMM2 Reg:XMM0 Reg:XMM1 | vsubsd %xmm1, %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "c5f35ed0", "4 VDIVSDrr_Int Reg:XMM2 Reg:XMM1 Reg:XMM0 | vdivsd %xmm0, %xmm1, %xmm2 | ",
  ),
  (
    "x86_64", "c4e2f9a9ca", "5 VFMADD213SDr_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:XMM2 | vfmadd213sd %xmm2, %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f928c1", "4 VMOVAPDrr Reg:XMM0 Reg:XMM1 | vmovapd %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c5fa2cc0", "4 VCVTTSS2SIrr_Int Reg:EAX Reg:XMM0 | vcvttss2si %xmm0, %eax | ",
  ),
  (
    "x86_64", "c4e1832ac7", "5 VCVTSI642SDrr_Int Reg:XMM0 Reg:XMM15 Reg:RDI | vcvtsi2sd %rdi, %xmm15, %xmm0 | ",
  ),
  (
    "x86_64", "c5fb5ac0", "4 VCVTSD2SSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | vcvtsd2ss %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c4e1fb2cc0", "5 VCVTTSD2SI64rr_Int Reg:RAX Reg:XMM0 | vcvttsd2si %xmm0, %rax | ",
  ),
  (
    "x86_64", "c4e27d78c0", "5 VPBROADCASTBYrr Reg:YMM0 Reg:XMM0 | vpbroadcastb %xmm0, %ymm0 | ",
  ),
  (
    "x86_64", "c5fe7f0438", "5 VMOVDQUYmr Reg:RAX Imm:1 Reg:RDI Imm:0 Reg: Reg:YMM0 | vmovdqu %ymm0, (%rax,%rdi) | may_store",
  ),
  (
    "x86_64", "c4e27978c0", "5 VPBROADCASTBrr Reg:XMM0 Reg:XMM0 | vpbroadcastb %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f9d60408", "5 VMOVPQI2QImr Reg:RAX Imm:1 Reg:RCX Imm:0 Reg: Reg:XMM0 | vmovq %xmm0, (%rax,%rcx) | may_store",
  ),
  (
    "x86_64", "c4e24bf7c7", "5 SHRX32rr Reg:EAX Reg:EDI Reg:ESI | shrxl %esi, %edi, %eax | ",
  ),
  (
    "x86_64", "c4e2fbf6c7", "5 MULX64rr Reg:RAX Reg:RAX Reg:RDI | mulxq %rdi, %rax, %rax | ",
  ),
  (
    "x86_64", "c5f96f0500000000", "8 VMOVDQArm Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vmovdqa (%rip), %xmm0 | may_load",
  ),
  (
    "x86_64", "c4e26947d0", "5 VPSLLVDrr Reg:XMM2 Reg:XMM2 Reg:XMM0 | vpsllvd %xmm0, %xmm2, %xmm2 | ",
  ),
  (
    "x86_64", "c5e972e21f", "5 VPSRADri Reg:XMM2 Reg:XMM2 Imm:31 | vpsrad $31, %xmm2, %xmm2 | ",
  ),
  (
    "x86_64", "c5e9dbd1", "4 VPANDrr Reg:XMM2 Reg:XMM2 Reg:XMM1 | vpand %xmm1, %xmm2, %xmm2 | ",
  ),
  ("x86_64", "4898", "2 CDQE  | cltq | "),
  (
    "x86_64", "c4e27140c9", "5 VPMULLDrr Reg:XMM1 Reg:XMM1 Reg:XMM1 | vpmulld %xmm1, %xmm1, %xmm1 | ",
  ),
  (
    "x86_64", "c4e271aac0", "5 VFMSUB213PSr Reg:XMM0 Reg:XMM0 Reg:XMM1 Reg:XMM0 | vfmsub213ps %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c5f95ec1", "4 VDIVPDrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vdivpd %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f971f003", "5 VPSLLWri Reg:XMM0 Reg:XMM0 Imm:3 | vpsllw $3, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f9fdc1", "4 VPADDWrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | vpaddw %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f9dac9", "4 VPMINUBrr Reg:XMM1 Reg:XMM0 Reg:XMM1 | vpminub %xmm1, %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f974c9", "4 VPCMPEQBrr Reg:XMM1 Reg:XMM0 Reg:XMM1 | vpcmpeqb %xmm1, %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f1dfc0", "4 VPANDNrr Reg:XMM0 Reg:XMM1 Reg:XMM0 | vpandn %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c5fc59c1", "4 VMULPSYrr Reg:YMM0 Reg:YMM0 Reg:YMM1 | vmulps %ymm1, %ymm0, %ymm0 | ",
  ),
  (
    "x86_64", "c4e2f9a94cc7f8", "7 VFMADD213SDm_Int Reg:XMM1 Reg:XMM1 Reg:XMM0 Reg:RDI Imm:8 Reg:RAX Imm:-8 Reg: | vfmadd213sd -8(%rdi,%rax,8), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86_64", "c5fa5fc1", "4 VMAXSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM1 | vmaxss %xmm1, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5f9570d00000000", "8 VXORPDrm Reg:XMM1 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vxorpd (%rip), %xmm0, %xmm1 | may_load",
  ),
  (
    "x86_64", "c5f35fc0", "4 VMAXSDrr_Int Reg:XMM0 Reg:XMM1 Reg:XMM0 | vmaxsd %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c4e3790bc009", "6 VROUNDSDri_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 Imm:9 | vroundsd $9, %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5fb580500000000", "8 VADDSDrm_Int Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vaddsd (%rip), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86_64", "c5fb5c0500000000", "8 VSUBSDrm_Int Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vsubsd (%rip), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86_64", "c4e1f96ec7", "5 VMOV64toPQIrr Reg:XMM0 Reg:RDI | vmovq %rdi, %xmm0 | ",
  ),
  (
    "x86_64", "c5f9620500000000", "8 VPUNPCKLDQrm Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vpunpckldq (%rip), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86_64", "c5f95c0500000000", "8 VSUBPDrm Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:0 Reg: | vsubpd (%rip), %xmm0, %xmm0 | may_load",
  ),
  (
    "x86_64", "c5f9c6c801", "5 VSHUFPDrri Reg:XMM1 Reg:XMM0 Reg:XMM0 Imm:1 | vshufpd $1, %xmm0, %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "c5f358c0", "4 VADDSDrr_Int Reg:XMM0 Reg:XMM1 Reg:XMM0 | vaddsd %xmm0, %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "c4e1822ac0", "5 VCVTSI642SSrr_Int Reg:XMM0 Reg:XMM15 Reg:RAX | vcvtsi2ss %rax, %xmm15, %xmm0 | ",
  ),
  (
    "x86_64", "c5fbc2d100", "5 VCMPSDrri_Int Reg:XMM2 Reg:XMM0 Reg:XMM1 Imm:0 | vcmpeqsd %xmm1, %xmm0, %xmm2 | ",
  ),
  (
    "x86_64", "c4e1f97ed0", "5 VMOVPQIto64rr Reg:RAX Reg:XMM2 | vmovq %xmm2, %rax | ",
  ),
  ("x86_64", "81fe80000000", "6 CMP32ri Reg:ESI Imm:128 | cmpl $128, %esi | "),
  (
    "x86_64", "c5fa58c2", "4 VADDSSrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM2 | vaddss %xmm2, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5fa5ac0", "4 VCVTSS2SDrr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | vcvtss2sd %xmm0, %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "c5fb2cc0", "4 VCVTTSD2SIrr_Int Reg:EAX Reg:XMM0 | vcvttsd2si %xmm0, %eax | ",
  ),
  (
    "x86_64", "c5f8294424d0", "6 VMOVAPSmr Reg:RSP Imm:1 Reg: Imm:-48 Reg: Reg:XMM0 | vmovaps %xmm0, -48(%rsp) | may_store",
  ),
  (
    "x86_64", "660f3840fd", "5 PMULLDrr Reg:XMM7 Reg:XMM7 Reg:XMM5 | pmulld %xmm5, %xmm7 | ",
  ),
  (
    "x86_64", "660f3800c1", "5 PSHUFBrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | pshufb %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f3a0bc009", "6 ROUNDSDri_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 Imm:9 | roundsd $9, %xmm0, %xmm0 | ",
  ),
  ("x86_64", "cf", "1 IRET32  | iretl | return,barrier,terminator,affect_cf"),
  ("x86_64", "fa", "1 CLI  | cli | "),
  ("x86_64", "ed", "1 IN32rr  | inl %dx, %eax | "),
  (
    "x86_64", "fe07", "2 INC8m Reg:RDI Imm:1 Reg: Imm:0 Reg: | incb (%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "0000", "2 ADD8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | addb %al, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "1900", "2 SBB32mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:EAX | sbbl %eax, (%rax) | may_load,may_store",
  ),
  ("x86_64", "98", "1 CWDE  | cwtl | "),
  ("x86_64", "0500000005", "5 ADD32i32 Imm:83886080 | addl $83886080, %eax | "),
  (
    "x86_64", "0200", "2 ADD8rm Reg:AL Reg:AL Reg:RAX Imm:1 Reg: Imm:0 Reg: | addb (%rax), %al | may_load",
  ),
  (
    "x86_64", "800000", "3 ADD8mi Reg:RAX Imm:1 Reg: Imm:0 Reg: Imm:0 | addb $0, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "1000", "2 ADC8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | adcb %al, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "3001", "2 XOR8mr Reg:RCX Imm:1 Reg: Imm:0 Reg: Reg:AL | xorb %al, (%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "2000", "2 AND8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | andb %al, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "1800", "2 SBB8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | sbbb %al, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "1200", "2 ADC8rm Reg:AL Reg:AL Reg:RAX Imm:1 Reg: Imm:0 Reg: | adcb (%rax), %al | may_load",
  ),
  ("x86_64", "c8000000", "4 ENTER Imm:0 Imm:0 | enter $0, $0 | "),
  (
    "x86_64", "0b00", "2 OR32rm Reg:EAX Reg:EAX Reg:RAX Imm:1 Reg: Imm:0 Reg: | orl (%rax), %eax | may_load",
  ),
  ("x86_64", "6c", "1 INSB Reg:RDI | insb %dx, %es:(%rdi) | "),
  (
    "x86_64", "69622f64796c64", "7 IMUL32rmi Reg:ESP Reg:RDX Imm:1 Reg: Imm:47 Reg: Imm:1684830564 | imull $1684830564, 47(%rdx), %esp | may_load",
  ),
  ("x86_64", "3ec9", "2 LEAVE64  | leave | may_load"),
  ("x86_64", "e7a1", "2 OUT32ir Imm:161 | outl %eax, $161 | "),
  (
    "x86_64", "3200", "2 XOR8rm Reg:AL Reg:AL Reg:RAX Imm:1 Reg: Imm:0 Reg: | xorb (%rax), %al | may_load",
  ),
  ("x86_64", "041a", "2 ADD8i8 Imm:26 | addb $26, %al | "),
  (
    "x86_64", "490100", "3 ADD64mr Reg:R8 Imm:1 Reg: Imm:0 Reg: Reg:RAX | addq %rax, (%r8) | may_load,may_store",
  ),
  (
    "x86_64", "2800", "2 SUB8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | subb %al, (%rax) | may_load,may_store",
  ),
  ("x86_64", "0c00", "2 OR8i8 Imm:0 | orb $0, %al | "),
  (
    "x86_64", "3800", "2 CMP8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | cmpb %al, (%rax) | may_load",
  ),
  ("x86_64", "4c0500000100", "6 ADD64i32 Imm:65536 | addq $65536, %rax | "),
  ("x86_64", "6d", "1 INSL Reg:RDI | insl %dx, %es:(%rdi) | "),
  (
    "x86_64", "6811000008", "5 PUSH64i32 Imm:134217745 | pushq $134217745 | may_store",
  ),
  (
    "x86_64", "1300", "2 ADC32rm Reg:EAX Reg:EAX Reg:RAX Imm:1 Reg: Imm:0 Reg: | adcl (%rax), %eax | may_load",
  ),
  (
    "x86_64", "480f44c8", "4 CMOV64rr Reg:RCX Reg:RCX Reg:RAX Imm:4 | cmoveq %rax, %rcx | ",
  ),
  ("x86_64", "3401", "2 XOR8i8 Imm:1 | xorb $1, %al | "),
  ("x86_64", "d7", "1 XLAT  | xlatb | may_load"),
  ("x86_64", "fd", "1 STD  | std | "),
  (
    "x86_64", "a0fdffffe9fdffff25", "9 MOV8ao64 Imm:2738188564482228221 Reg: | movabsb 2738188564482228221, %al | may_load",
  ),
  ("x86_64", "80c2f7", "3 ADD8ri Reg:DL Reg:DL Imm:-9 | addb $-9, %dl | "),
  ("x86_64", "80fa01", "3 CMP8ri Reg:DL Imm:1 | cmpb $1, %dl | "),
  ("x86_64", "92", "1 XCHG32ar Reg:EDX Reg:EDX | xchgl %edx, %eax | "),
  (
    "x86_64", "636b5f", "3 MOVSX32rm32 Reg:EBP Reg:RBX Imm:1 Reg: Imm:95 Reg: | movslq 95(%rbx), %ebp | may_load",
  ),
  ("x86_64", "646f", "2 OUTSL Reg:RSI Reg:FS | outsl %fs:(%rsi), %dx | "),
  ("x86_64", "6e", "1 OUTSB Reg:RSI Reg: | outsb (%rsi), %dx | "),
  (
    "x86_64", "1b00", "2 SBB32rm Reg:EAX Reg:EAX Reg:RAX Imm:1 Reg: Imm:0 Reg: | sbbl (%rax), %eax | may_load",
  ),
  ("x86_64", "b200", "2 MOV8ri Reg:DL Imm:0 | movb $0, %dl | "),
  ("x86_64", "3c00", "2 CMP8i8 Imm:0 | cmpb $0, %al | "),
  (
    "x86_64", "3900", "2 CMP32mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:EAX | cmpl %eax, (%rax) | may_load",
  ),
  ("x86_64", "0d0000000f", "5 OR32i32 Imm:251658240 | orl $251658240, %eax | "),
  (
    "x86_64", "3536313435", "5 XOR32i32 Imm:892612918 | xorl $892612918, %eax | ",
  ),
  (
    "x86_64", "de0cc0", "3 MUL_FI16m Reg:RAX Imm:8 Reg:RAX Imm:0 Reg: | fimuls (%rax,%rax,8) | may_load",
  ),
  (
    "x86_64", "13d0", "2 ADC32rr_REV Reg:EDX Reg:EDX Reg:EAX | adcl %eax, %edx | ",
  ),
  ("x86_64", "f9", "1 STC  | stc | "),
  (
    "x86_64", "df6180", "3 FBLDm Reg:RCX Imm:1 Reg: Imm:-128 Reg: | fbld -128(%rcx) | may_load",
  ),
  ("x86_64", "28d6", "2 SUB8rr Reg:DH Reg:DH Reg:DL | subb %dl, %dh | "),
  ("x86_64", "9f", "1 LAHF  | lahf | "),
  ("x86_64", "ef", "1 OUT32rr  | outl %eax, %dx | "),
  ("x86_64", "f5", "1 CMC  | cmc | "),
  ("x86_64", "1cd4", "2 SBB8i8 Imm:-44 | sbbb $-44, %al | "),
  ("x86_64", "3bf9", "2 CMP32rr_REV Reg:EDI Reg:ECX | cmpl %ecx, %edi | "),
  (
    "x86_64", "11a74999aefc", "6 ADC32mr Reg:RDI Imm:1 Reg: Imm:-55666359 Reg: Reg:ESP | adcl %esp, -55666359(%rdi) | may_load,may_store",
  ),
  ("x86_64", "489e", "2 SAHF  | sahf | "),
  (
    "x86_64", "1a8e3a951697", "6 SBB8rm Reg:CL Reg:CL Reg:RSI Imm:1 Reg: Imm:-1760127686 Reg: | sbbb -1760127686(%rsi), %cl | may_load",
  ),
  (
    "x86_64", "0aa6e4766397", "6 OR8rm Reg:AH Reg:AH Reg:RSI Imm:1 Reg: Imm:-1755089180 Reg: | orb -1755089180(%rsi), %ah | may_load",
  ),
  (
    "x86_64", "801000", "3 ADC8mi Reg:RAX Imm:1 Reg: Imm:0 Reg: Imm:0 | adcb $0, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "c044000020", "5 ROL8mi Reg:RAX Imm:1 Reg:RAX Imm:0 Reg: Imm:32 | rolb $32, (%rax,%rax) | may_load,may_store",
  ),
  (
    "x86_64", "8e00", "2 MOV16sm Reg:ES Reg:RAX Imm:1 Reg: Imm:0 Reg: | movw (%rax), %es | may_load",
  ),
  (
    "x86_64", "c2ce49", "3 RETI64 Imm:18894 | retq $18894 | return,barrier,terminator,affect_cf",
  ),
  ("x86_64", "e4a1", "2 IN8ri Imm:161 | inb $161, %al | "),
  (
    "x86_64", "801800", "3 SBB8mi Reg:RAX Imm:1 Reg: Imm:0 Reg: Imm:0 | sbbb $0, (%rax) | may_load,may_store",
  ),
  ("x86_64", "f4", "1 HLT  | hlt | terminator"),
  (
    "x86_64", "0800", "2 OR8mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AL | orb %al, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "2e312e", "3 XOR32mr Reg:RSI Imm:1 Reg: Imm:0 Reg:CS Reg:EBP | xorl %ebp, %cs:(%rsi) | may_load,may_store",
  ),
  (
    "x86_64", "483905cc490000", "7 CMP64mr Reg:RIP Imm:1 Reg: Imm:18892 Reg: Reg:RAX | cmpq %rax, 18892(%rip) | may_load",
  ),
  (
    "x86_64", "4c292511470000", "7 SUB64mr Reg:RIP Imm:1 Reg: Imm:18193 Reg: Reg:R12 | subq %r12, 18193(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "3d0090ffff", "5 CMP32i32 Imm:4294938624 | cmpl $4294938624, %eax | ",
  ),
  (
    "x86_64", "ff33", "2 PUSH64rmm Reg:RBX Imm:1 Reg: Imm:0 Reg: | pushq (%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "ff4dff", "3 DEC32m Reg:RBP Imm:1 Reg: Imm:-1 Reg: | decl -1(%rbp) | may_load,may_store",
  ),
  ("x86_64", "48", "1 REX64_PREFIX  | rex64 | "),
  ("x86_64", "41f6d6", "3 NOT8r Reg:R14B Reg:R14B | notb %r14b | "),
  (
    "x86_64", "800d7e3f000002", "7 OR8mi Reg:RIP Imm:1 Reg: Imm:16254 Reg: Imm:2 | orb $2, 16254(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "8025da380000fb", "7 AND8mi Reg:RIP Imm:1 Reg: Imm:14554 Reg: Imm:-5 | andb $-5, 14554(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "090594360000", "6 OR32mr Reg:RIP Imm:1 Reg: Imm:13972 Reg: Reg:EAX | orl %eax, 13972(%rip) | may_load,may_store",
  ),
  ("x86_64", "80f301", "3 XOR8ri Reg:BL Reg:BL Imm:1 | xorb $1, %bl | "),
  ("x86_64", "fc", "1 CLD  | cld | "),
  ("x86_64", "1af4", "2 SBB8rr_REV Reg:DH Reg:DH Reg:AH | sbbb %ah, %dh | "),
  (
    "x86_64", "ff41f7", "3 INC32m Reg:RCX Imm:1 Reg: Imm:-9 Reg: | incl -9(%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "ff9af8ffffea", "6 FARCALL32m Reg:RDX Imm:1 Reg: Imm:-352321544 Reg: | lcalll *-352321544(%rdx) | call,affect_cf,may_load",
  ),
  ("x86_64", "f6ff", "2 IDIV8r Reg:BH | idivb %bh | "),
  ("x86_64", "f8", "1 CLC  | clc | "),
  (
    "x86_64", "03f9", "2 ADD32rr_REV Reg:EDI Reg:EDI Reg:ECX | addl %ecx, %edi | ",
  ),
  (
    "x86_64", "ffa9f8ffff8f", "6 FARJMP32m Reg:RCX Imm:1 Reg: Imm:-1879048200 Reg: | ljmpl *-1879048200(%rcx) | indirect,barrier,terminator,affect_cf,may_load",
  ),
  (
    "x86_64", "ffa7f6ffff08", "6 JMP64m Reg:RDI Imm:1 Reg: Imm:150994934 Reg: | jmpq *150994934(%rdi) | indirect,barrier,terminator,affect_cf,may_load",
  ),
  ("x86_64", "aa", "1 STOSB Reg:RDI | stosb %al, %es:(%rdi) | "),
  ("x86_64", "18f7", "2 SBB8rr Reg:BH Reg:BH Reg:DH | sbbb %dh, %bh | "),
  ("x86_64", "9b", "1 WAIT  | wait | "),
  ("x86_64", "e1f5", "2 LOOPE Imm:-11 | loope -11 | cond,terminator,affect_cf"),
  (
    "x86_64", "0f9545d7", "4 SETCCm Reg:RBP Imm:1 Reg: Imm:-41 Reg: Imm:5 | setne -41(%rbp) | may_store",
  ),
  (
    "x86_64", "6641837d5600", "6 CMP16mi8 Reg:R13 Imm:1 Reg: Imm:86 Reg: Imm:0 | cmpw $0, 86(%r13) | may_load",
  ),
  (
    "x86_64", "480b08", "3 OR64rm Reg:RCX Reg:RCX Reg:RAX Imm:1 Reg: Imm:0 Reg: | orq (%rax), %rcx | may_load",
  ),
  (
    "x86_64", "2201", "2 AND8rm Reg:AL Reg:AL Reg:RCX Imm:1 Reg: Imm:0 Reg: | andb (%rcx), %al | may_load",
  ),
  (
    "x86_64", "48ff0b", "3 DEC64m Reg:RBX Imm:1 Reg: Imm:0 Reg: | decq (%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "48ff45b0", "4 INC64m Reg:RBP Imm:1 Reg: Imm:-80 Reg: | incq -80(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "f68578ffffff01", "7 TEST8mi Reg:RBP Imm:1 Reg: Imm:-136 Reg: Imm:1 | testb $1, -136(%rbp) | may_load",
  ),
  (
    "x86_64", "66636c6f73", "5 MOVSX16rm32 Reg:BP Reg:RDI Imm:2 Reg:RBP Imm:115 Reg: | movslq 115(%rdi,%rbp,2), %bp | may_load",
  ),
  (
    "x86_64", "dc20", "2 SUB_F64m Reg:RAX Imm:1 Reg: Imm:0 Reg: | fsubl (%rax) | may_load",
  ),
  (
    "x86_64", "d001", "2 ROL8m1 Reg:RCX Imm:1 Reg: Imm:0 Reg: | rolb (%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "15a9039a0b", "5 ADC32i32 Imm:194642857 | adcl $194642857, %eax | ",
  ),
  (
    "x86_64", "df01", "2 ILD_F16m Reg:RCX Imm:1 Reg: Imm:0 Reg: | filds (%rcx) | may_load",
  ),
  (
    "x86_64", "232d15151523", "6 AND32rm Reg:EBP Reg:EBP Reg:RIP Imm:1 Reg: Imm:588584213 Reg: | andl 588584213(%rip), %ebp | may_load",
  ),
  (
    "x86_64", "a30000000f01100000", "9 MOV32o64a Imm:17596732669952 Reg: | movabsl %eax, 17596732669952 | may_store",
  ),
  ("x86_64", "e001", "2 LOOPNE Imm:1 | loopne 1 | cond,terminator,affect_cf"),
  (
    "x86_64", "1d0000001e", "5 SBB32i32 Imm:503316480 | sbbl $503316480, %eax | ",
  ),
  (
    "x86_64", "2d0000002e", "5 SUB32i32 Imm:771751936 | subl $771751936, %eax | ",
  ),
  ("x86_64", "2c00", "2 SUB8i8 Imm:0 | subb $0, %al | "),
  (
    "x86_64", "66696c656e6f00", "7 IMUL16rmi Reg:BP Reg:RBP Imm:2 Reg:RIZ Imm:110 Reg: Imm:111 | imulw $111, 110(%rbp,%riz,2), %bp | may_load",
  ),
  ("x86_64", "666d", "2 INSW Reg:RDI | insw %dx, %es:(%rdi) | "),
  ("x86_64", "a7", "1 CMPSL Reg:RDI Reg:RSI Reg: | cmpsl %es:(%rdi), (%rsi) | "),
  ("x86_64", "fb", "1 STI  | sti | "),
  ("x86_64", "e206", "2 LOOP Imm:6 | loop 6 | cond,terminator,affect_cf"),
  (
    "x86_64", "81edb80e1de7", "6 SUB32ri Reg:EBP Reg:EBP Imm:3877441208 | subl $3877441208, %ebp | ",
  ),
  ("x86_64", "a6", "1 CMPSB Reg:RDI Reg:RSI Reg: | cmpsb %es:(%rdi), (%rsi) | "),
  (
    "x86_64", "2a2f", "2 SUB8rm Reg:CH Reg:CH Reg:RDI Imm:1 Reg: Imm:0 Reg: | subb (%rdi), %ch | may_load",
  ),
  ("x86_64", "c1d893", "3 RCR32ri Reg:EAX Reg:EAX Imm:147 | rcrl $147, %eax | "),
  ("x86_64", "af", "1 SCASL Reg:RDI | scasl %es:(%rdi), %eax | "),
  (
    "x86_64", "df0c14", "3 ISTT_FP16m Reg:RSP Imm:1 Reg:RDX Imm:0 Reg: | fisttps (%rsp,%rdx) | may_store",
  ),
  (
    "x86_64", "ca91a9", "3 LRETI32 Imm:-22127 | lretl $-22127 | return,barrier,terminator,affect_cf",
  ),
  (
    "x86_64", "86d5", "2 XCHG8rr Reg:DL Reg:CH Reg:DL Reg:CH | xchgb %ch, %dl | ",
  ),
  (
    "x86_64", "d80400", "3 ADD_F32m Reg:RAX Imm:1 Reg:RAX Imm:0 Reg: | fadds (%rax,%rax) | may_load",
  ),
  ("x86_64", "483d10010000", "6 CMP64i32 Imm:272 | cmpq $272, %rax | "),
  ("x86_64", "e6ff", "2 OUT8ir Imm:255 | outb %al, $255 | "),
  (
    "x86_64", "81f105010000", "6 XOR32ri Reg:ECX Reg:ECX Imm:261 | xorl $261, %ecx | ",
  ),
  (
    "x86_64", "8455d7", "3 TEST8mr Reg:RBP Imm:1 Reg: Imm:-41 Reg: Reg:DL | testb %dl, -41(%rbp) | may_load",
  ),
  ("x86_64", "cb", "1 LRET32  | lretl | return,barrier,terminator,affect_cf"),
  ("x86_64", "e3ff", "2 JRCXZ Imm:-1 | jrcxz -1 | cond,terminator,affect_cf"),
  ("x86_64", "d2ff", "2 SAR8rCL Reg:BH Reg:BH | sarb %cl, %bh | "),
  (
    "x86_64", "817f140d010000", "7 CMP32mi Reg:RDI Imm:1 Reg: Imm:20 Reg: Imm:269 | cmpl $269, 20(%rdi) | may_load",
  ),
  ("x86_64", "02ff", "2 ADD8rr_REV Reg:BH Reg:BH Reg:BH | addb %bh, %bh | "),
  ("x86_64", "fff1", "2 PUSH64rmr Reg:RCX | pushq %rcx | may_store"),
  ("x86_64", "83d9ff", "3 SBB32ri8 Reg:ECX Reg:ECX Imm:-1 | sbbl $-1, %ecx | "),
  (
    "x86_64", "81cb10010000", "6 OR32ri Reg:EBX Reg:EBX Imm:272 | orl $272, %ebx | ",
  ),
  ("x86_64", "cc", "1 INT3  | int3 | may_load,may_store"),
  ("x86_64", "dcf8", "2 DIV_FrST0 Reg:ST0 | fdivr %st, %st(0) | "),
  ("x86_64", "2afa", "2 SUB8rr_REV Reg:BH Reg:BH Reg:DL | subb %dl, %bh | "),
  (
    "x86_64", "f744883c00050000", "8 TEST32mi Reg:RAX Imm:4 Reg:RCX Imm:60 Reg: Imm:1280 | testl $1280, 60(%rax,%rcx,4) | may_load",
  ),
  ("x86_64", "480fa3c1", "4 BT64rr Reg:RCX Reg:RAX | btq %rax, %rcx | "),
  (
    "x86_64", "f20f2ac3", "4 CVTSI2SDrr_Int Reg:XMM0 Reg:XMM0 Reg:EBX | cvtsi2sd %ebx, %xmm0 | ",
  ),
  (
    "x86_64", "f20f2c10", "4 CVTTSD2SIrm_Int Reg:EDX Reg:RAX Imm:1 Reg: Imm:0 Reg: | cvttsd2si (%rax), %edx | may_load",
  ),
  ("x86_64", "49d1fe", "3 SAR64r1 Reg:R14 Reg:R14 | sarq %r14 | "),
  ("x86_64", "6683fb08", "4 CMP16ri8 Reg:BX Imm:8 | cmpw $8, %bx | "),
  ("x86_64", "6685db", "3 TEST16rr Reg:BX Reg:BX | testw %bx, %bx | "),
  (
    "x86_64", "490fbfc4", "4 MOVSX64rr16 Reg:RAX Reg:R12W | movswq %r12w, %rax | ",
  ),
  (
    "x86_64", "6641390c50", "5 CMP16mr Reg:R8 Imm:2 Reg:RDX Imm:0 Reg: Reg:CX | cmpw %cx, (%r8,%rdx,2) | may_load",
  ),
  ("x86_64", "ddef", "2 UCOM_FPr Reg:ST7 | fucomp %st(7) | "),
  ("x86_64", "cdf6", "2 INT Imm:246 | int $246 | may_load,may_store"),
  ("x86_64", "ee", "1 OUT8rr  | outb %al, %dx | "),
  (
    "x86_64", "a1fbffff6efaffff5d", "9 MOV32ao64 Imm:6773413815657693179 Reg: | movabsl 6773413815657693179, %eax | may_load",
  ),
  ("x86_64", "12fb", "2 ADC8rr_REV Reg:BH Reg:BH Reg:BL | adcb %bl, %bh | "),
  ("x86_64", "a4", "1 MOVSB Reg:RDI Reg:RSI Reg: | movsb (%rsi), %es:(%rdi) | "),
  ("x86_64", "d9f9", "2 FYL2XP1  | fyl2xp1 | "),
  (
    "x86_64", "81c1e4feffff", "6 ADD32ri Reg:ECX Reg:ECX Imm:4294967012 | addl $4294967012, %ecx | ",
  ),
  ("x86_64", "ec", "1 IN8rr  | inb %dx, %al | "),
  ("x86_64", "83d000", "3 ADC32ri8 Reg:EAX Reg:EAX Imm:0 | adcl $0, %eax | "),
  (
    "x86_64", "4883d2ff", "4 ADC64ri8 Reg:RDX Reg:RDX Imm:-1 | adcq $-1, %rdx | ",
  ),
  (
    "x86_64", "f20f2a03", "4 CVTSI2SDrm_Int Reg:XMM0 Reg:XMM0 Reg:RBX Imm:1 Reg: Imm:0 Reg: | cvtsi2sdl (%rbx), %xmm0 | may_load",
  ),
  (
    "x86_64", "4983dfff", "4 SBB64ri8 Reg:R15 Reg:R15 Imm:-1 | sbbq $-1, %r15 | ",
  ),
  (
    "x86_64", "2bfa", "2 SUB32rr_REV Reg:EDI Reg:EDI Reg:EDX | subl %edx, %edi | ",
  ),
  (
    "x86_64", "660f57051a980000", "8 XORPDrm Reg:XMM0 Reg:XMM0 Reg:RIP Imm:1 Reg: Imm:38938 Reg: | xorpd 38938(%rip), %xmm0 | may_load",
  ),
  (
    "x86_64", "660f7cc0", "4 HADDPDrr Reg:XMM0 Reg:XMM0 Reg:XMM0 | haddpd %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "f20f51c0", "4 SQRTSDr_Int Reg:XMM0 Reg:XMM0 Reg:XMM0 | sqrtsd %xmm0, %xmm0 | ",
  ),
  (
    "x86_64", "87fc", "2 XCHG32rr Reg:EDI Reg:ESP Reg:EDI Reg:ESP | xchgl %esp, %edi | ",
  ),
  ("x86_64", "10e8", "2 ADC8rr Reg:AL Reg:AL Reg:CH | adcb %ch, %al | "),
  ("x86_64", "0fbed2", "3 MOVSX32rr8 Reg:EDX Reg:DL | movsbl %dl, %edx | "),
  (
    "x86_64", "660f5545d0", "5 ANDNPDrm Reg:XMM0 Reg:XMM0 Reg:RBP Imm:1 Reg: Imm:-48 Reg: | andnpd -48(%rbp), %xmm0 | may_load",
  ),
  ("x86_64", "410fbae109", "5 BT32ri8 Reg:R9D Imm:9 | btl $9, %r9d | "),
  ("x86_64", "c0e103", "3 SHL8ri Reg:CL Reg:CL Imm:3 | shlb $3, %cl | "),
  (
    "x86_64", "43855c2cf8", "5 TEST32mr Reg:R12 Imm:1 Reg:R13 Imm:-8 Reg: Reg:EBX | testl %ebx, -8(%r12,%r13) | may_load",
  ),
  (
    "x86_64", "488325c1a8000000", "8 AND64mi8 Reg:RIP Imm:1 Reg: Imm:43201 Reg: Imm:0 | andq $0, 43201(%rip) | may_load,may_store",
  ),
  ("x86_64", "666f", "2 OUTSW Reg:RSI Reg: | outsw (%rsi), %dx | "),
  (
    "x86_64", "a9044b5287", "5 TEST32i32 Imm:2270317316 | testl $2270317316, %eax | ",
  ),
  (
    "x86_64", "81010937a001", "6 ADD32mi Reg:RCX Imm:1 Reg: Imm:0 Reg: Imm:27277065 | addl $27277065, (%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "8f01", "2 POP64rmm Reg:RCX Imm:1 Reg: Imm:0 Reg: | popq (%rcx) | may_load,may_store",
  ),
  ("x86_64", "4b6658", "3 POP16r Reg:AX | popw %ax | may_load"),
  ("x86_64", "ae", "1 SCASB Reg:RDI | scasb %es:(%rdi), %al | "),
  (
    "x86_64", "23d2", "2 AND32rr_REV Reg:EDX Reg:EDX Reg:EDX | andl %edx, %edx | ",
  ),
  (
    "x86_64", "8c1a", "2 MOV16ms Reg:RDX Imm:1 Reg: Imm:0 Reg: Reg:DS | movw %ds, (%rdx) | may_store",
  ),
  ("x86_64", "9d", "1 POPF64  | popfq | may_load"),
  ("x86_64", "ab", "1 STOSL Reg:RDI | stosl %eax, %es:(%rdi) | "),
  ("x86_64", "11e0", "2 ADC32rr Reg:EAX Reg:EAX Reg:ESP | adcl %esp, %eax | "),
  ("x86_64", "dde5", "2 UCOM_Fr Reg:ST5 | fucom %st(5) | "),
  (
    "x86_64", "814df334af636e", "7 OR32mi Reg:RBP Imm:1 Reg: Imm:-13 Reg: Imm:1852026676 | orl $1852026676, -13(%rbp) | may_load,may_store",
  ),
  ("x86_64", "9c", "1 PUSHF64  | pushfq | may_store"),
  (
    "x86_64", "2189ec941138", "6 AND32mr Reg:RCX Imm:1 Reg: Imm:940676332 Reg: Reg:ECX | andl %ecx, 940676332(%rcx) | may_load,may_store",
  ),
  ("x86_64", "8ac5", "2 MOV8rr_REV Reg:AL Reg:CH | movb %ch, %al | "),
  (
    "x86_64", "867a41", "3 XCHG8rm Reg:BH Reg:BH Reg:RDX Imm:1 Reg: Imm:65 Reg: | xchgb %bh, 65(%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "d15c3f3a", "4 RCR32m1 Reg:RDI Imm:1 Reg:RDI Imm:58 Reg: | rcrl 58(%rdi,%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "d84f79", "3 MUL_F32m Reg:RDI Imm:1 Reg: Imm:121 Reg: | fmuls 121(%rdi) | may_load",
  ),
  (
    "x86_64", "d1af45450862", "6 SHR32m1 Reg:RDI Imm:1 Reg: Imm:1644709189 Reg: | shrl 1644709189(%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "fe0e", "2 DEC8m Reg:RSI Imm:1 Reg: Imm:0 Reg: | decb (%rsi) | may_load,may_store",
  ),
  (
    "x86_64", "c54b11dd", "4 VMOVSDrr_REV Reg:XMM5 Reg:XMM6 Reg:XMM11 | vmovsd %xmm11, %xmm6, %xmm5 | ",
  ),
  (
    "x86_64", "db924c8f0c28", "6 IST_F32m Reg:RDX Imm:1 Reg: Imm:671911756 Reg: | fistl 671911756(%rdx) | may_store",
  ),
  ("x86_64", "40e554", "3 IN32ri Imm:84 | inl $84, %eax | "),
  ("x86_64", "c0d945", "3 RCR8ri Reg:CL Reg:CL Imm:69 | rcrb $69, %cl | "),
  ("x86_64", "fec2", "2 INC8r Reg:DL Reg:DL | incb %dl | "),
  (
    "x86_64", "0fdeb38af10e51", "7 MMX_PMAXUBrm Reg:MM6 Reg:MM6 Reg:RBX Imm:1 Reg: Imm:1359933834 Reg: | pmaxub 1359933834(%rbx), %mm6 | may_load",
  ),
  ("x86_64", "0f30", "2 WRMSR  | wrmsr | "),
  ("x86_64", "64ac", "2 LODSB Reg:RSI Reg:FS | lodsb %fs:(%rsi), %al | "),
  (
    "x86_64", "806a0000", "4 SUB8mi Reg:RDX Imm:1 Reg: Imm:0 Reg: Imm:0 | subb $0, (%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "660ffcc1", "4 PADDBrr Reg:XMM0 Reg:XMM0 Reg:XMM1 | paddb %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f7f85a0efffff", "8 MOVDQAmr Reg:RBP Imm:1 Reg: Imm:-4192 Reg: Reg:XMM0 | movdqa %xmm0, -4192(%rbp) | may_store",
  ),
  ("x86_64", "4883f001", "4 XOR64ri8 Reg:RAX Reg:RAX Imm:1 | xorq $1, %rax | "),
  ("x86_64", "63ee", "2 MOVSX32rr32 Reg:EBP Reg:ESI | movslq %esi, %ebp | "),
  ("x86_64", "482d00100000", "6 SUB64i32 Imm:4096 | subq $4096, %rax | "),
  (
    "x86_64", "6681bd34ffffff0090", "9 CMP16mi Reg:RBP Imm:1 Reg: Imm:-204 Reg: Imm:36864 | cmpw $36864, -204(%rbp) | may_load",
  ),
  ("x86_64", "32fe", "2 XOR8rr_REV Reg:BH Reg:BH Reg:DH | xorb %dh, %bh | "),
  ("x86_64", "d8f1", "2 DIV_FST0r Reg:ST1 | fdiv %st(1), %st | "),
  (
    "x86_64", "dc03", "2 ADD_F64m Reg:RBX Imm:1 Reg: Imm:0 Reg: | faddl (%rbx) | may_load",
  ),
  (
    "x86_64", "d00c9c", "3 ROR8m1 Reg:RSP Imm:4 Reg:RBX Imm:0 Reg: | rorb (%rsp,%rbx,4) | may_load,may_store",
  ),
  (
    "x86_64", "de00", "2 ADD_FI16m Reg:RAX Imm:1 Reg: Imm:0 Reg: | fiadds (%rax) | may_load",
  ),
  (
    "x86_64", "da01", "2 ADD_FI32m Reg:RCX Imm:1 Reg: Imm:0 Reg: | fiaddl (%rcx) | may_load",
  ),
  (
    "x86_64", "c11822", "3 RCR32mi Reg:RAX Imm:1 Reg: Imm:0 Reg: Imm:34 | rcrl $34, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "da1e", "2 FICOMP32m Reg:RSI Imm:1 Reg: Imm:0 Reg: | ficompl (%rsi) | may_load",
  ),
  (
    "x86_64", "8130600e4794", "6 XOR32mi Reg:RAX Imm:1 Reg: Imm:0 Reg: Imm:2487684704 | xorl $2487684704, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "a200b57dd6d527702f", "9 MOV8o64a Imm:3418275916554286336 Reg: | movabsb %al, 3418275916554286336 | may_store",
  ),
  (
    "x86_64", "df6e58", "3 ILD_F64m Reg:RSI Imm:1 Reg: Imm:88 Reg: | fildll 88(%rsi) | may_load",
  ),
  (
    "x86_64", "2681198c839629", "7 SBB32mi Reg:RCX Imm:1 Reg: Imm:0 Reg:ES Imm:697729932 | sbbl $697729932, %es:(%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "831b25", "3 SBB32mi8 Reg:RBX Imm:1 Reg: Imm:0 Reg: Imm:37 | sbbl $37, (%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "ddb4704125427f", "7 FSAVEm Reg:RAX Imm:2 Reg:RSI Imm:2135041345 Reg: | fnsave 2135041345(%rax,%rsi,2) | may_store",
  ),
  (
    "x86_64", "d228", "2 SHR8mCL Reg:RAX Imm:1 Reg: Imm:0 Reg: | shrb %cl, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "d06500", "3 SHL8m1 Reg:RBP Imm:1 Reg: Imm:0 Reg: | shlb (%rbp) | may_load,may_store",
  ),
  ("x86_64", "d9ff", "2 FCOS  | fcos | "),
  (
    "x86_64", "486bc03c", "4 IMUL64rri8 Reg:RAX Reg:RAX Imm:60 | imulq $60, %rax, %rax | ",
  ),
  (
    "x86_64", "4869c0100e0000", "7 IMUL64rri32 Reg:RAX Reg:RAX Imm:3600 | imulq $3600, %rax, %rax | ",
  ),
  (
    "x86_64", "663b4718", "4 CMP16rm Reg:AX Reg:RDI Imm:1 Reg: Imm:24 Reg: | cmpw 24(%rdi), %ax | may_load",
  ),
  ("x86_64", "48f7d1", "3 NOT64r Reg:RCX Reg:RCX | notq %rcx | "),
  (
    "x86_64", "48854f18", "4 TEST64mr Reg:RDI Imm:1 Reg: Imm:24 Reg: Reg:RCX | testq %rcx, 24(%rdi) | may_load",
  ),
  (
    "x86_64", "663100", "3 XOR16mr Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:AX | xorw %ax, (%rax) | may_load,may_store",
  ),
  ("x86_64", "6639c1", "3 CMP16rr Reg:CX Reg:AX | cmpw %ax, %cx | "),
  (
    "x86_64", "66854f18", "4 TEST16mr Reg:RDI Imm:1 Reg: Imm:24 Reg: Reg:CX | testw %cx, 24(%rdi) | may_load",
  ),
  (
    "x86_64", "0fba631810", "5 BT32mi8 Reg:RBX Imm:1 Reg: Imm:24 Reg: Imm:16 | btl $16, 24(%rbx) | may_load",
  ),
  (
    "x86_64", "480fbcca", "4 BSF64rr Reg:RCX Reg:RCX Reg:RDX | bsfq %rdx, %rcx | ",
  ),
  ("x86_64", "66bb0040", "4 MOV16ri Reg:BX Imm:16384 | movw $16384, %bx | "),
  ("x86_64", "d8ff", "2 DIVR_FST0r Reg:ST7 | fdivr %st(7), %st | "),
  ("x86_64", "480fbef6", "4 MOVSX64rr8 Reg:RSI Reg:SIL | movsbq %sil, %rsi | "),
  (
    "x86_64", "81d30b010000", "6 ADC32ri Reg:EBX Reg:EBX Imm:267 | adcl $267, %ebx | ",
  ),
  (
    "x86_64", "48f71d8e510000", "7 NEG64m Reg:RIP Imm:1 Reg: Imm:20878 Reg: | negq 20878(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "486b033c", "4 IMUL64rmi8 Reg:RAX Reg:RBX Imm:1 Reg: Imm:0 Reg: Imm:60 | imulq $60, (%rbx), %rax | may_load",
  ),
  (
    "x86_64", "48f72b", "3 IMUL64m Reg:RBX Imm:1 Reg: Imm:0 Reg: | imulq (%rbx) | may_load",
  ),
  ("x86_64", "dff7", "2 COM_FIPr Reg:ST7 | fcompi %st(7), %st | "),
  ("x86_64", "ad", "1 LODSL Reg:RSI Reg: | lodsl (%rsi), %eax | "),
  ("x86_64", "49c1cb02", "4 ROR64ri Reg:R11 Reg:R11 Imm:2 | rorq $2, %r11 | "),
  (
    "x86_64", "660f38241d250a0000", "9 PMOVSXWQrm Reg:XMM3 Reg:RIP Imm:1 Reg: Imm:2597 Reg: | pmovsxwq 2597(%rip), %xmm3 | may_load",
  ),
  (
    "x86_64", "660f382225270a0000", "9 PMOVSXBQrm Reg:XMM4 Reg:RIP Imm:1 Reg: Imm:2599 Reg: | pmovsxbq 2599(%rip), %xmm4 | may_load",
  ),
  (
    "x86_64", "66440f3829c5", "6 PCMPEQQrr Reg:XMM8 Reg:XMM8 Reg:XMM5 | pcmpeqq %xmm5, %xmm8 | ",
  ),
  (
    "x86_64", "66410ffbc8", "5 PSUBQrr Reg:XMM1 Reg:XMM1 Reg:XMM8 | psubq %xmm8, %xmm1 | ",
  ),
  (
    "x86_64", "660fd4ce", "4 PADDQrr Reg:XMM1 Reg:XMM1 Reg:XMM6 | paddq %xmm6, %xmm1 | ",
  ),
  (
    "x86_64", "660feb1d99090000", "8 PORrm Reg:XMM3 Reg:XMM3 Reg:RIP Imm:1 Reg: Imm:2457 Reg: | por 2457(%rip), %xmm3 | may_load",
  ),
  (
    "x86_64", "660f66d8", "4 PCMPGTDrr Reg:XMM3 Reg:XMM3 Reg:XMM0 | pcmpgtd %xmm0, %xmm3 | ",
  ),
  (
    "x86_64", "660febc3", "4 PORrr Reg:XMM0 Reg:XMM0 Reg:XMM3 | por %xmm3, %xmm0 | ",
  ),
  (
    "x86_64", "660f3815ca", "5 BLENDVPDrr0 Reg:XMM1 Reg:XMM1 Reg:XMM2 | blendvpd %xmm0, %xmm2, %xmm1 | ",
  ),
  (
    "x86_64", "0f0110", "3 LGDT64m Reg:RAX Imm:1 Reg: Imm:0 Reg: | lgdtq (%rax) | ",
  ),
  (
    "x86_64", "db02", "2 ILD_F32m Reg:RDX Imm:1 Reg: Imm:0 Reg: | fildl (%rdx) | may_load",
  ),
  (
    "x86_64", "d301", "2 ROL32mCL Reg:RCX Imm:1 Reg: Imm:0 Reg: | roll %cl, (%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "48131e", "3 ADC64rm Reg:RBX Reg:RBX Reg:RSI Imm:1 Reg: Imm:0 Reg: | adcq (%rsi), %rbx | may_load",
  ),
  (
    "x86_64", "4acaf373", "4 LRETI64 Imm:29683 | lretq $29683 | return,barrier,terminator,affect_cf",
  ),
  ("x86_64", "d2c7", "2 ROL8rCL Reg:BH Reg:BH | rolb %cl, %bh | "),
  (
    "x86_64", "0fdb20", "3 MMX_PANDrm Reg:MM4 Reg:MM4 Reg:RAX Imm:1 Reg: Imm:0 Reg: | pand (%rax), %mm4 | may_load",
  ),
  (
    "x86_64", "d9a087e2e94c", "6 FLDENVm Reg:RAX Imm:1 Reg: Imm:1290396295 Reg: | fldenv 1290396295(%rax) | may_load",
  ),
  (
    "x86_64", "36d8bceae08503e4", "8 DIVR_F32m Reg:RDX Imm:8 Reg:RBP Imm:-469531168 Reg:SS | fdivrs %ss:-469531168(%rdx,%rbp,8) | may_load",
  ),
  ("x86_64", "67", "1 ADDR32_PREFIX  | addr32  addr32 | "),
  ("x86_64", "3ad0", "2 CMP8rr_REV Reg:DL Reg:AL | cmpb %al, %dl | "),
  (
    "x86_64", "c07d0100", "4 SAR8mi Reg:RBP Imm:1 Reg: Imm:1 Reg: Imm:0 | sarb $0, 1(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "4c6962726172792f", "8 IMUL64rmi32 Reg:R12 Reg:RDX Imm:1 Reg: Imm:114 Reg: Imm:796488289 | imulq $796488289, 114(%rdx), %r12 | may_load",
  ),
  (
    "x86_64", "0f14c2", "3 UNPCKLPSrr Reg:XMM0 Reg:XMM0 Reg:XMM2 | unpcklps %xmm2, %xmm0 | ",
  ),
  (
    "x86_64", "4c0f444dc0", "5 CMOV64rm Reg:R9 Reg:R9 Reg:RBP Imm:1 Reg: Imm:-64 Reg: Imm:4 | cmoveq -64(%rbp), %r9 | may_load",
  ),
  ("x86_64", "19c0", "2 SBB32rr Reg:EAX Reg:EAX Reg:EAX | sbbl %eax, %eax | "),
  (
    "x86_64", "488185b8fefffff8120000", "11 ADD64mi32 Reg:RBP Imm:1 Reg: Imm:-328 Reg: Imm:4856 | addq $4856, -328(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0f01c8", "3 MONITOR64rrr  | monitor | "),
  ("x86_64", "0f01c9", "3 MWAITrr  | mwait | may_load,may_store"),
  ("x86_64", "0f01d0", "3 XGETBV  | xgetbv | "),
  ("x86_64", "0f01f9", "3 RDTSCP  | rdtscp | "),
  ("x86_64", "0f01fb", "3 MWAITXrrr  | mwaitx | "),
  ("x86_64", "0f05", "2 SYSCALL  | syscall | "),
  ("x86_64", "0f08", "2 INVD  | invd | "),
  ("x86_64", "0f09", "2 WBINVD  | wbinvd | may_load,may_store"),
  (
    "x86_64", "0f0d45fc", "4 PREFETCH Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetch -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f0d4dfc", "4 PREFETCHW Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetchw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f0d55fc", "4 PREFETCHWT1 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetchwt1 -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0f10c1", "3 MOVUPSrr Reg:XMM0 Reg:XMM1 | movups %xmm1, %xmm0 | "),
  (
    "x86_64", "0f11c8", "3 MOVUPSrr_REV Reg:XMM0 Reg:XMM1 | movups %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "0f1845fc", "4 PREFETCHNTA Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetchnta -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f184dfc", "4 PREFETCHT0 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetcht0 -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f1855fc", "4 PREFETCHT1 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetcht1 -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f185dfc", "4 PREFETCHT2 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | prefetcht2 -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0f29c8", "3 MOVAPSrr_REV Reg:XMM0 Reg:XMM1 | movaps %xmm1, %xmm0 | ",
  ),
  ("x86_64", "0f32", "2 RDMSR  | rdmsr | "),
  ("x86_64", "0f33", "2 RDPMC  | rdpmc | "),
  ("x86_64", "0f34", "2 SYSENTER  | sysenter | "),
  (
    "x86_64", "0f38f045fc", "5 MOVBE32rm Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | movbel -4(%rbp), %eax | may_load",
  ),
  (
    "x86_64", "0f38f14dfc", "5 MOVBE32mr Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:ECX | movbel %ecx, -4(%rbp) | may_store",
  ),
  (
    "x86_64", "0f4545fc", "4 CMOV32rm Reg:EAX Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | cmovnel -4(%rbp), %eax | may_load",
  ),
  ("x86_64", "0fa2", "2 CPUID  | cpuid | "),
  (
    "x86_64", "0fa4c804", "4 SHLD32rri8 Reg:EAX Reg:EAX Reg:ECX Imm:4 | shldl $4, %ecx, %eax | ",
  ),
  (
    "x86_64", "0fa54dfc", "4 SHLD32mrCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:ECX | shldl %cl, %ecx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0fadd0", "3 SHRD32rrCL Reg:EAX Reg:EAX Reg:EDX | shrdl %cl, %edx, %eax | ",
  ),
  (
    "x86_64", "0fae55fc", "4 LDMXCSR Reg:RBP Imm:1 Reg: Imm:-4 Reg: | ldmxcsr -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0fae5df8", "4 STMXCSR Reg:RBP Imm:1 Reg: Imm:-8 Reg: | stmxcsr -8(%rbp) | may_store",
  ),
  (
    "x86_64", "0fae7dfc", "4 CLFLUSH Reg:RBP Imm:1 Reg: Imm:-4 Reg: | clflush -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0faee8", "3 LFENCE  | lfence | may_load,may_store"),
  ("x86_64", "0faef0", "3 MFENCE  | mfence | may_load,may_store"),
  ("x86_64", "0faef8", "3 SFENCE  | sfence | may_load,may_store"),
  (
    "x86_64", "0fb04dfc", "4 CMPXCHG8rm Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CL | cmpxchgb %cl, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0fb0cb", "3 CMPXCHG8rr Reg:BL Reg:CL | cmpxchgb %cl, %bl | "),
  ("x86_64", "0fb1cb", "3 CMPXCHG32rr Reg:EBX Reg:ECX | cmpxchgl %ecx, %ebx | "),
  (
    "x86_64", "0fba75fc05", "5 BTR32mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btrl $5, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0fbcc1", "3 BSF32rr Reg:EAX Reg:EAX Reg:ECX | bsfl %ecx, %eax | "),
  (
    "x86_64", "0fbd45fc", "4 BSR32rm Reg:EAX Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | bsrl -4(%rbp), %eax | may_load",
  ),
  (
    "x86_64", "0fc04dfc", "4 XADD8rm Reg:CL Reg:CL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | xaddb %cl, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "0fc0cb", "3 XADD8rr Reg:BL Reg:CL Reg:BL Reg:CL | xaddb %cl, %bl | ",
  ),
  (
    "x86_64", "0fc1cb", "3 XADD32rr Reg:EBX Reg:ECX Reg:EBX Reg:ECX | xaddl %ecx, %ebx | ",
  ),
  (
    "x86_64", "0fc74df8", "4 CMPXCHG8B Reg:RBP Imm:1 Reg: Imm:-8 Reg: | cmpxchg8b -8(%rbp) | may_load,may_store",
  ),
  ("x86_64", "0fc7f1", "3 RDRAND32r Reg:ECX | rdrandl %ecx | "),
  ("x86_64", "0fc7f8", "3 RDSEED32r Reg:EAX | rdseedl %eax | "),
  (
    "x86_64", "1bc8", "2 SBB32rr_REV Reg:ECX Reg:ECX Reg:EAX | sbbl %eax, %ecx | ",
  ),
  ("x86_64", "40c6c401", "4 MOV8ri_alt Reg:SPL Imm:1 | movb $1, %spl | "),
  ("x86_64", "40d0c4", "3 ROL8r1 Reg:SPL Reg:SPL | rolb %spl | "),
  ("x86_64", "40d0d4", "3 RCL8r1 Reg:SPL Reg:SPL | rclb %spl | "),
  ("x86_64", "40d0e4", "3 SHL8r1 Reg:SPL Reg:SPL | shlb %spl | "),
  (
    "x86_64", "41c0500104", "5 RCL8mi Reg:R8 Imm:1 Reg: Imm:1 Reg: Imm:4 | rclb $4, 1(%r8) | may_load,may_store",
  ),
  ("x86_64", "41c0c804", "4 ROR8ri Reg:R8B Reg:R8B Imm:4 | rorb $4, %r8b | "),
  ("x86_64", "41c0f804", "4 SAR8ri Reg:R8B Reg:R8B Imm:4 | sarb $4, %r8b | "),
  (
    "x86_64", "41d96810", "4 FLDCW16m Reg:R8 Imm:1 Reg: Imm:16 Reg: | fldcw 16(%r8) | may_load",
  ),
  (
    "x86_64", "41f65801", "4 NEG8m Reg:R8 Imm:1 Reg: Imm:1 Reg: | negb 1(%r8) | may_load,may_store",
  ),
  ("x86_64", "41f6d8", "3 NEG8r Reg:R8B Reg:R8B | negb %r8b | "),
  (
    "x86_64", "4803c8", "3 ADD64rr_REV Reg:RCX Reg:RCX Reg:RAX | addq %rax, %rcx | ",
  ),
  (
    "x86_64", "48094df8", "4 OR64mr Reg:RBP Imm:1 Reg: Imm:-8 Reg: Reg:RCX | orq %rcx, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "480d78563412", "6 OR64i32 Imm:305419896 | orq $305419896, %rax | ",
  ),
  (
    "x86_64", "480f1f840000000000", "9 NOOPQ Reg:RAX Imm:1 Reg:RAX Imm:0 Reg: | nopq (%rax,%rax) | ",
  ),
  (
    "x86_64", "480f38f045f8", "6 MOVBE64rm Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | movbeq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "480fa4c804", "5 SHLD64rri8 Reg:RAX Reg:RAX Reg:RCX Imm:4 | shldq $4, %rcx, %rax | ",
  ),
  (
    "x86_64", "480fac55f805", "6 SHRD64mri8 Reg:RBP Imm:1 Reg: Imm:-8 Reg: Reg:RDX Imm:5 | shrdq $5, %rdx, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "480fb1cb", "4 CMPXCHG64rr Reg:RBX Reg:RCX | cmpxchgq %rcx, %rbx | ",
  ),
  ("x86_64", "480fb6c1", "4 MOVZX64rr8 Reg:RAX Reg:CL | movzbq %cl, %rax | "),
  ("x86_64", "480fbae03f", "5 BT64ri8 Reg:RAX Imm:63 | btq $63, %rax | "),
  (
    "x86_64", "480fbb4df8", "5 BTC64mr Reg:RBP Imm:1 Reg: Imm:-8 Reg: Reg:RCX | btcq %rcx, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "480fbc45f8", "5 BSF64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | bsfq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "480fc14df8", "5 XADD64rm Reg:RCX Reg:RCX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | xaddq %rcx, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "480fc1cb", "4 XADD64rr Reg:RBX Reg:RCX Reg:RBX Reg:RCX | xaddq %rcx, %rbx | ",
  ),
  (
    "x86_64", "48114df8", "4 ADC64mr Reg:RBP Imm:1 Reg: Imm:-8 Reg: Reg:RCX | adcq %rcx, -8(%rbp) | may_load,may_store",
  ),
  ("x86_64", "4811d8", "3 ADC64rr Reg:RAX Reg:RAX Reg:RBX | adcq %rbx, %rax | "),
  (
    "x86_64", "4813c8", "3 ADC64rr_REV Reg:RCX Reg:RCX Reg:RAX | adcq %rax, %rcx | ",
  ),
  (
    "x86_64", "481578563412", "6 ADC64i32 Imm:305419896 | adcq $305419896, %rax | ",
  ),
  ("x86_64", "4819d8", "3 SBB64rr Reg:RAX Reg:RAX Reg:RBX | sbbq %rbx, %rax | "),
  (
    "x86_64", "481b45f8", "4 SBB64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | sbbq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "481bc8", "3 SBB64rr_REV Reg:RCX Reg:RCX Reg:RAX | sbbq %rax, %rcx | ",
  ),
  (
    "x86_64", "482345f8", "4 AND64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | andq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "4823c8", "3 AND64rr_REV Reg:RCX Reg:RCX Reg:RAX | andq %rax, %rcx | ",
  ),
  (
    "x86_64", "482bc8", "3 SUB64rr_REV Reg:RCX Reg:RCX Reg:RAX | subq %rax, %rcx | ",
  ),
  (
    "x86_64", "4833c8", "3 XOR64rr_REV Reg:RCX Reg:RCX Reg:RAX | xorq %rax, %rcx | ",
  ),
  ("x86_64", "483500010000", "6 XOR64i32 Imm:256 | xorq $256, %rax | "),
  ("x86_64", "483bc8", "3 CMP64rr_REV Reg:RCX Reg:RAX | cmpq %rax, %rcx | "),
  (
    "x86_64", "4881c878563412", "7 OR64ri32 Reg:RAX Reg:RAX Imm:305419896 | orq $305419896, %rax | ",
  ),
  (
    "x86_64", "488345f801", "5 ADD64mi8 Reg:RBP Imm:1 Reg: Imm:-8 Reg: Imm:1 | addq $1, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "488355f801", "5 ADC64mi8 Reg:RBP Imm:1 Reg: Imm:-8 Reg: Imm:1 | adcq $1, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "488745f8", "4 XCHG64rm Reg:RAX Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | xchgq %rax, -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "4887d8", "3 XCHG64rr Reg:RBX Reg:RAX Reg:RBX Reg:RAX | xchgq %rax, %rbx | ",
  ),
  ("x86_64", "488bec", "3 MOV64rr_REV Reg:RBP Reg:RSP | movq %rsp, %rbp | "),
  ("x86_64", "4891", "2 XCHG64ar Reg:RCX Reg:RCX | xchgq %rcx, %rax | "),
  (
    "x86_64", "48a18877665544332211", "10 MOV64ao64 Imm:1234605616436508552 Reg: | movabsq 1234605616436508552, %rax | may_load",
  ),
  (
    "x86_64", "48a38877665544332211", "10 MOV64o64a Imm:1234605616436508552 Reg: | movabsq %rax, 1234605616436508552 | may_store",
  ),
  (
    "x86_64", "48a5", "2 MOVSQ Reg:RDI Reg:RSI Reg: | movsq (%rsi), %es:(%rdi) | ",
  ),
  (
    "x86_64", "48a7", "2 CMPSQ Reg:RDI Reg:RSI Reg: | cmpsq %es:(%rdi), (%rsi) | ",
  ),
  (
    "x86_64", "48a978563412", "6 TEST64i32 Imm:305419896 | testq $305419896, %rax | ",
  ),
  ("x86_64", "48ab", "2 STOSQ Reg:RDI | stosq %rax, %es:(%rdi) | "),
  ("x86_64", "48af", "2 SCASQ Reg:RDI | scasq %es:(%rdi), %rax | "),
  (
    "x86_64", "48d145f8", "4 ROL64m1 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | rolq -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "48d155f8", "4 RCL64m1 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | rclq -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "48d165f8", "4 SHL64m1 Reg:RBP Imm:1 Reg: Imm:-8 Reg: | shlq -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "48f755f8", "4 NOT64m Reg:RBP Imm:1 Reg: Imm:-8 Reg: | notq -8(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "48f765f8", "4 MUL64m Reg:RBP Imm:1 Reg: Imm:-8 Reg: | mulq -8(%rbp) | may_load",
  ),
  ("x86_64", "490fc7f1", "4 RDRAND64r Reg:R9 | rdrandq %r9 | "),
  (
    "x86_64", "4981f000010000", "7 XOR64ri32 Reg:R8 Reg:R8 Imm:256 | xorq $256, %r8 | ",
  ),
  ("x86_64", "49d3c8", "3 ROR64rCL Reg:R8 Reg:R8 | rorq %cl, %r8 | "),
  ("x86_64", "49d3d8", "3 RCR64rCL Reg:R8 Reg:R8 | rcrq %cl, %r8 | "),
  ("x86_64", "49f7c0ffffffff", "7 TEST64ri32 Reg:R8 Imm:-1 | testq $-1, %r8 | "),
  (
    "x86_64", "4c0f38f145f8", "6 MOVBE64mr Reg:RBP Imm:1 Reg: Imm:-8 Reg: Reg:R8 | movbeq %r8, -8(%rbp) | may_store",
  ),
  ("x86_64", "4d0fabc8", "4 BTS64rr Reg:R8 Reg:R8 Reg:R9 | btsq %r9, %r8 | "),
  (
    "x86_64", "4d0fadc8", "4 SHRD64rrCL Reg:R8 Reg:R8 Reg:R9 | shrdq %cl, %r9, %r8 | ",
  ),
  ("x86_64", "4d0fb7c1", "4 MOVZX64rr16 Reg:R8 Reg:R9W | movzwq %r9w, %r8 | "),
  ("x86_64", "4d0fbdc8", "4 BSR64rr Reg:R9 Reg:R9 Reg:R8 | bsrq %r8, %r9 | "),
  ("x86_64", "6601d8", "3 ADD16rr Reg:AX Reg:AX Reg:BX | addw %bx, %ax | "),
  (
    "x86_64", "660345fc", "4 ADD16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | addw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "66053412", "4 ADD16i16 Imm:4660 | addw $4660, %ax | "),
  (
    "x86_64", "660b45fc", "4 OR16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | orw -4(%rbp), %ax | may_load",
  ),
  (
    "x86_64", "660f380000", "5 PSHUFBrm Reg:XMM0 Reg:XMM0 Reg:RAX Imm:1 Reg: Imm:0 Reg: | pshufb (%rax), %xmm0 | may_load",
  ),
  (
    "x86_64", "660f3838c8", "5 PMINSBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f3839c8", "5 PMINSDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsd %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383ac8", "5 PMINUWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminuw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383bc8", "5 PMINUDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminud %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383cc8", "5 PMAXSBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383dc8", "5 PMAXSDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsd %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383ec8", "5 PMAXUWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxuw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f383fc8", "5 PMAXUDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxud %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f38f045fc", "6 MOVBE16rm Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | movbew -4(%rbp), %ax | may_load",
  ),
  (
    "x86_64", "660f3a0fc104", "6 PALIGNRrri Reg:XMM0 Reg:XMM0 Reg:XMM1 Imm:4 | palignr $4, %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "660f4545fc", "5 CMOV16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | cmovnew -4(%rbp), %ax | may_load",
  ),
  (
    "x86_64", "660f64c8", "4 PCMPGTBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pcmpgtb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660f71d004", "5 PSRLWri Reg:XMM0 Reg:XMM0 Imm:4 | psrlw $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f71e004", "5 PSRAWri Reg:XMM0 Reg:XMM0 Imm:4 | psraw $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f72d004", "5 PSRLDri Reg:XMM0 Reg:XMM0 Imm:4 | psrld $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f72e004", "5 PSRADri Reg:XMM0 Reg:XMM0 Imm:4 | psrad $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f72f004", "5 PSLLDri Reg:XMM0 Reg:XMM0 Imm:4 | pslld $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f73d004", "5 PSRLQri Reg:XMM0 Reg:XMM0 Imm:4 | psrlq $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f73d803", "5 PSRLDQri Reg:XMM0 Reg:XMM0 Imm:3 | psrldq $3, %xmm0 | ",
  ),
  (
    "x86_64", "660f73f004", "5 PSLLQri Reg:XMM0 Reg:XMM0 Imm:4 | psllq $4, %xmm0 | ",
  ),
  (
    "x86_64", "660f73f803", "5 PSLLDQri Reg:XMM0 Reg:XMM0 Imm:3 | pslldq $3, %xmm0 | ",
  ),
  (
    "x86_64", "660f7fc8", "4 MOVDQArr_REV Reg:XMM0 Reg:XMM1 | movdqa %xmm1, %xmm0 | ",
  ),
  ("x86_64", "660fa3c8", "4 BT16rr Reg:AX Reg:CX | btw %cx, %ax | "),
  (
    "x86_64", "660fa4c804", "5 SHLD16rri8 Reg:AX Reg:AX Reg:CX Imm:4 | shldw $4, %cx, %ax | ",
  ),
  (
    "x86_64", "660fa54dfc", "5 SHLD16mrCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | shldw %cl, %cx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660fac55fc05", "6 SHRD16mri8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:DX Imm:5 | shrdw $5, %dx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660facd003", "5 SHRD16rri8 Reg:AX Reg:AX Reg:DX Imm:3 | shrdw $3, %dx, %ax | ",
  ),
  (
    "x86_64", "660fadd0", "4 SHRD16rrCL Reg:AX Reg:AX Reg:DX | shrdw %cl, %dx, %ax | ",
  ),
  (
    "x86_64", "660fae75fc", "5 CLWB Reg:RBP Imm:1 Reg: Imm:-4 Reg: | clwb -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660fae7dfc", "5 CLFLUSHOPT Reg:RBP Imm:1 Reg: Imm:-4 Reg: | clflushopt -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660faf45fc", "5 IMUL16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | imulw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "660fafc1", "4 IMUL16rr Reg:AX Reg:AX Reg:CX | imulw %cx, %ax | "),
  (
    "x86_64", "660fb14dfc", "5 CMPXCHG16rm Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | cmpxchgw %cx, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "660fb1cb", "4 CMPXCHG16rr Reg:BX Reg:CX | cmpxchgw %cx, %bx | "),
  ("x86_64", "660fb6c1", "4 MOVZX16rr8 Reg:AX Reg:CL | movzbw %cl, %ax | "),
  (
    "x86_64", "660fba65fc05", "6 BT16mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btw $5, -4(%rbp) | may_load",
  ),
  (
    "x86_64", "660fba75fc05", "6 BTR16mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:5 | btrw $5, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "660fbae803", "5 BTS16ri8 Reg:AX Reg:AX Imm:3 | btsw $3, %ax | "),
  (
    "x86_64", "660fbb4dfc", "5 BTC16mr Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | btcw %cx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660fbc45fc", "5 BSF16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | bsfw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "660fbcc1", "4 BSF16rr Reg:AX Reg:AX Reg:CX | bsfw %cx, %ax | "),
  ("x86_64", "660fbdc1", "4 BSR16rr Reg:AX Reg:AX Reg:CX | bsrw %cx, %ax | "),
  (
    "x86_64", "660fbe45fc", "5 MOVSX16rm8 Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | movsbw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "660fbec4", "4 MOVSX16rr8 Reg:AX Reg:AH | movsbw %ah, %ax | "),
  (
    "x86_64", "660fc14dfc", "5 XADD16rm Reg:CX Reg:CX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | xaddw %cx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "660fc1cb", "4 XADD16rr Reg:BX Reg:CX Reg:BX Reg:CX | xaddw %cx, %bx | ",
  ),
  ("x86_64", "660fc7f1", "4 RDRAND16r Reg:CX | rdrandw %cx | "),
  (
    "x86_64", "660fd1c8", "4 PSRLWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrlw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fd2c8", "4 PSRLDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrld %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fd3c8", "4 PSRLQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrlq %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fd7c8", "4 PMOVMSKBrr Reg:ECX Reg:XMM0 | pmovmskb %xmm0, %ecx | ",
  ),
  (
    "x86_64", "660fdec8", "4 PMAXUBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxub %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fe0c8", "4 PAVGBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pavgb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fe1c8", "4 PSRAWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psraw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fe2c8", "4 PSRADrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psrad %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660fe3c8", "4 PAVGWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pavgw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660feac8", "4 PMINSWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pminsw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660feec8", "4 PMAXSWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pmaxsw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ff1c8", "4 PSLLWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psllw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ff2c8", "4 PSLLDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | pslld %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ff3c8", "4 PSLLQrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psllq %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ff8c8", "4 PSUBBrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubb %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ff9c8", "4 PSUBWrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubw %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "660ffac8", "4 PSUBDrr Reg:XMM1 Reg:XMM1 Reg:XMM0 | psubd %xmm0, %xmm1 | ",
  ),
  (
    "x86_64", "66114dfc", "4 ADC16mr Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | adcw %cx, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "6611d8", "3 ADC16rr Reg:AX Reg:AX Reg:BX | adcw %bx, %ax | "),
  ("x86_64", "66153412", "4 ADC16i16 Imm:4660 | adcw $4660, %ax | "),
  (
    "x86_64", "661b45fc", "4 SBB16rm Reg:AX Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | sbbw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "661bc8", "3 SBB16rr_REV Reg:CX Reg:CX Reg:AX | sbbw %ax, %cx | "),
  ("x86_64", "6623c8", "3 AND16rr_REV Reg:CX Reg:CX Reg:AX | andw %ax, %cx | "),
  ("x86_64", "6625ff00", "4 AND16i16 Imm:255 | andw $255, %ax | "),
  (
    "x86_64", "66294dfc", "4 SUB16mr Reg:RBP Imm:1 Reg: Imm:-4 Reg: Reg:CX | subw %cx, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "6631c0", "3 XOR16rr Reg:AX Reg:AX Reg:AX | xorw %ax, %ax | "),
  ("x86_64", "663dffff", "4 CMP16i16 Imm:65535 | cmpw $65535, %ax | "),
  ("x86_64", "6640ed", "3 IN16rr  | inw %dx, %ax | "),
  ("x86_64", "66410fc7f8", "5 RDSEED16r Reg:R8W | rdseedw %r8w | "),
  ("x86_64", "664150", "3 PUSH16r Reg:R8W | pushw %r8w | may_store"),
  (
    "x86_64", "664183d001", "5 ADC16ri8 Reg:R8W Reg:R8W Imm:1 | adcw $1, %r8w | ",
  ),
  ("x86_64", "66418bc0", "4 MOV16rr_REV Reg:AX Reg:R8W | movw %r8w, %ax | "),
  (
    "x86_64", "6641c7c03412", "6 MOV16ri_alt Reg:R8W Imm:4660 | movw $4660, %r8w | ",
  ),
  ("x86_64", "6641fff0", "4 PUSH16rmr Reg:R8W | pushw %r8w | may_store"),
  ("x86_64", "66683412", "4 PUSH16i Imm:4660 | pushw $4660 | may_store"),
  ("x86_64", "666aff", "3 PUSH16i8 Imm:-1 | pushw $-1 | may_store"),
  (
    "x86_64", "666bc102", "4 IMUL16rri8 Reg:AX Reg:CX Imm:2 | imulw $2, %cx, %ax | ",
  ),
  (
    "x86_64", "66815dfc3412", "6 SBB16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:4660 | sbbw $4660, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "668165fcff00", "6 AND16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:255 | andw $255, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66816dfc3412", "6 SUB16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:4660 | subw $4660, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "6681d83412", "5 SBB16ri Reg:AX Reg:AX Imm:4660 | sbbw $4660, %ax | ",
  ),
  (
    "x86_64", "668345fc01", "5 ADD16mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | addw $1, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "668355fc01", "5 ADC16mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:1 | adcw $1, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "668375fcff", "5 XOR16mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:-1 | xorw $-1, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "6683c001", "4 ADD16ri8 Reg:AX Reg:AX Imm:1 | addw $1, %ax | "),
  ("x86_64", "6683c80f", "4 OR16ri8 Reg:AX Reg:AX Imm:15 | orw $15, %ax | "),
  ("x86_64", "6683d8ff", "4 SBB16ri8 Reg:AX Reg:AX Imm:-1 | sbbw $-1, %ax | "),
  (
    "x86_64", "66874dfc", "4 XCHG16rm Reg:CX Reg:CX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | xchgw %cx, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "6687c8", "3 XCHG16rr Reg:CX Reg:AX Reg:CX Reg:AX | xchgw %ax, %cx | ",
  ),
  (
    "x86_64", "668d45fc", "4 LEA16r Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | leaw -4(%rbp), %ax | ",
  ),
  ("x86_64", "6691", "2 XCHG16ar Reg:CX Reg:CX | xchgw %cx, %ax | "),
  ("x86_64", "6698", "2 CBW  | cbtw | "),
  ("x86_64", "669c", "2 PUSHF16  | pushfw | may_store"),
  ("x86_64", "669d", "2 POPF16  | popfw | may_load"),
  (
    "x86_64", "66a18877665544332211", "10 MOV16ao64 Imm:1234605616436508552 Reg: | movabsw 1234605616436508552, %ax | may_load",
  ),
  (
    "x86_64", "66a38877665544332211", "10 MOV16o64a Imm:1234605616436508552 Reg: | movabsw %ax, 1234605616436508552 | may_store",
  ),
  (
    "x86_64", "66a5", "2 MOVSW Reg:RDI Reg:RSI Reg: | movsw (%rsi), %es:(%rdi) | ",
  ),
  (
    "x86_64", "66a7", "2 CMPSW Reg:RDI Reg:RSI Reg: | cmpsw %es:(%rdi), (%rsi) | ",
  ),
  ("x86_64", "66a9ff00", "4 TEST16i16 Imm:255 | testw $255, %ax | "),
  ("x86_64", "66ab", "2 STOSW Reg:RDI | stosw %ax, %es:(%rdi) | "),
  ("x86_64", "66af", "2 SCASW Reg:RDI | scasw %es:(%rdi), %ax | "),
  (
    "x86_64", "66c145fc04", "5 ROL16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | rolw $4, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66c155fc04", "5 RCL16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | rclw $4, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66c17dfc04", "5 SAR16mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:4 | sarw $4, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "66c1d003", "4 RCL16ri Reg:AX Reg:AX Imm:3 | rclw $3, %ax | "),
  ("x86_64", "66c1f803", "4 SAR16ri Reg:AX Reg:AX Imm:3 | sarw $3, %ax | "),
  (
    "x86_64", "66d145fc", "4 ROL16m1 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rolw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66d155fc", "4 RCL16m1 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rclw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66d165fc", "4 SHL16m1 Reg:RBP Imm:1 Reg: Imm:-4 Reg: | shlw -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "66d1c0", "3 ROL16r1 Reg:AX Reg:AX | rolw %ax | "),
  ("x86_64", "66d1d0", "3 RCL16r1 Reg:AX Reg:AX | rclw %ax | "),
  ("x86_64", "66d1e0", "3 SHL16r1 Reg:AX Reg:AX | shlw %ax | "),
  (
    "x86_64", "66d34dfc", "4 ROR16mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rorw %cl, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66d35dfc", "4 RCR16mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rcrw %cl, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66d36dfc", "4 SHR16mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | shrw %cl, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "66d3c8", "3 ROR16rCL Reg:AX Reg:AX | rorw %cl, %ax | "),
  ("x86_64", "66d3d8", "3 RCR16rCL Reg:AX Reg:AX | rcrw %cl, %ax | "),
  ("x86_64", "66d3e8", "3 SHR16rCL Reg:AX Reg:AX | shrw %cl, %ax | "),
  ("x86_64", "66e582", "3 IN16ri Imm:130 | inw $130, %ax | "),
  ("x86_64", "66e785", "3 OUT16ir Imm:133 | outw %ax, $133 | "),
  ("x86_64", "66ef", "2 OUT16rr  | outw %ax, %dx | "),
  (
    "x86_64", "66f30fb845fc", "6 POPCNT16rm Reg:AX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | popcntw -4(%rbp), %ax | may_load",
  ),
  ("x86_64", "66f30fb8c1", "5 POPCNT16rr Reg:AX Reg:CX | popcntw %cx, %ax | "),
  ("x86_64", "66f30fbdc1", "5 LZCNT16rr Reg:AX Reg:CX | lzcntw %cx, %ax | "),
  (
    "x86_64", "66f3450fbcc1", "6 TZCNT16rr Reg:R8W Reg:R9W | tzcntw %r9w, %r8w | ",
  ),
  (
    "x86_64", "66f755fc", "4 NOT16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | notw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66f75dfc", "4 NEG16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | negw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66f765fc", "4 MUL16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | mulw -4(%rbp) | may_load",
  ),
  (
    "x86_64", "66f76dfc", "4 IMUL16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | imulw -4(%rbp) | may_load",
  ),
  (
    "x86_64", "66f775fc", "4 DIV16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | divw -4(%rbp) | may_load",
  ),
  (
    "x86_64", "66f77dfc", "4 IDIV16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | idivw -4(%rbp) | may_load",
  ),
  ("x86_64", "66f7d0", "3 NOT16r Reg:AX Reg:AX | notw %ax | "),
  ("x86_64", "66f7e1", "3 MUL16r Reg:CX | mulw %cx | "),
  ("x86_64", "66f7e9", "3 IMUL16r Reg:CX | imulw %cx | "),
  ("x86_64", "66f7f1", "3 DIV16r Reg:CX | divw %cx | "),
  (
    "x86_64", "66ff45fc", "4 INC16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | incw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66ff4dfc", "4 DEC16m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | decw -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "66ff7010", "4 PUSH16rmm Reg:RAX Imm:1 Reg: Imm:16 Reg: | pushw 16(%rax) | may_load,may_store",
  ),
  ("x86_64", "66ffc1", "3 INC16r Reg:CX Reg:CX | incw %cx | "),
  ("x86_64", "66ffc8", "3 DEC16r Reg:AX Reg:AX | decw %ax | "),
  ("x86_64", "80c80f", "3 OR8ri Reg:AL Reg:AL Imm:15 | orb $15, %al | "),
  ("x86_64", "80d880", "3 SBB8ri Reg:AL Reg:AL Imm:-128 | sbbb $-128, %al | "),
  ("x86_64", "80e880", "3 SUB8ri Reg:AL Reg:AL Imm:-128 | subb $-128, %al | "),
  (
    "x86_64", "816dfc78563412", "7 SUB32mi Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:305419896 | subl $305419896, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "8375fcff", "4 XOR32mi8 Reg:RBP Imm:1 Reg: Imm:-4 Reg: Imm:-1 | xorl $-1, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "8bec", "2 MOV32rr_REV Reg:EBP Reg:ESP | movl %esp, %ebp | "),
  ("x86_64", "c0c403", "3 ROL8ri Reg:AH Reg:AH Imm:3 | rolb $3, %ah | "),
  ("x86_64", "c0d403", "3 RCL8ri Reg:AH Reg:AH Imm:3 | rclb $3, %ah | "),
  (
    "x86_64", "c7c0ffffffff", "6 MOV32ri_alt Reg:EAX Imm:4294967295 | movl $4294967295, %eax | ",
  ),
  ("x86_64", "d1c8", "2 ROR32r1 Reg:EAX Reg:EAX | rorl %eax | "),
  ("x86_64", "d1d8", "2 RCR32r1 Reg:EAX Reg:EAX | rcrl %eax | "),
  (
    "x86_64", "d34dfc", "3 ROR32mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rorl %cl, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "d35dfc", "3 RCR32mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | rcrl %cl, -4(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "d36dfc", "3 SHR32mCL Reg:RBP Imm:1 Reg: Imm:-4 Reg: | shrl %cl, -4(%rbp) | may_load,may_store",
  ),
  ("x86_64", "d3c8", "2 ROR32rCL Reg:EAX Reg:EAX | rorl %cl, %eax | "),
  ("x86_64", "d3d8", "2 RCR32rCL Reg:EAX Reg:EAX | rcrl %cl, %eax | "),
  ("x86_64", "d3f8", "2 SAR32rCL Reg:EAX Reg:EAX | sarl %cl, %eax | "),
  (
    "x86_64", "d97df8", "3 FNSTCW16m Reg:RBP Imm:1 Reg: Imm:-8 Reg: | fnstcw -8(%rbp) | may_store",
  ),
  ("x86_64", "f30f1efa", "4 ENDBR64  | endbr64 | "),
  ("x86_64", "f30f1efb", "4 ENDBR32  | endbr32 | "),
  (
    "x86_64", "f30f6fc1", "4 MOVDQUrr Reg:XMM0 Reg:XMM1 | movdqu %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "f30f7fc8", "4 MOVDQUrr_REV Reg:XMM0 Reg:XMM1 | movdqu %xmm1, %xmm0 | ",
  ),
  (
    "x86_64", "f30fb845fc", "5 POPCNT32rm Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | popcntl -4(%rbp), %eax | may_load",
  ),
  ("x86_64", "f30fbcc1", "4 TZCNT32rr Reg:EAX Reg:ECX | tzcntl %ecx, %eax | "),
  (
    "x86_64", "f30fbd45fc", "5 LZCNT32rm Reg:EAX Reg:RBP Imm:1 Reg: Imm:-4 Reg: | lzcntl -4(%rbp), %eax | may_load",
  ),
  (
    "x86_64", "f3480fb845f8", "6 POPCNT64rm Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | popcntq -8(%rbp), %rax | may_load",
  ),
  (
    "x86_64", "f3480fb8c1", "5 POPCNT64rr Reg:RAX Reg:RCX | popcntq %rcx, %rax | ",
  ),
  (
    "x86_64", "f3480fbd45f8", "6 LZCNT64rm Reg:RAX Reg:RBP Imm:1 Reg: Imm:-8 Reg: | lzcntq -8(%rbp), %rax | may_load",
  ),
  ("x86_64", "f34d0fbdc8", "5 LZCNT64rr Reg:R9 Reg:R8 | lzcntq %r8, %r9 | "),
  ("x86_64", "f6e9", "2 IMUL8r Reg:CL | imulb %cl | "),
  ("x86_64", "f6f1", "2 DIV8r Reg:CL | divb %cl | "),
  (
    "x86_64", "f765fc", "3 MUL32m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | mull -4(%rbp) | may_load",
  ),
  (
    "x86_64", "f76dfc", "3 IMUL32m Reg:RBP Imm:1 Reg: Imm:-4 Reg: | imull -4(%rbp) | may_load",
  ),
  (
    "x86_64", "f7c100000080", "6 TEST32ri Reg:ECX Imm:2147483648 | testl $2147483648, %ecx | ",
  ),
  ("x86_64", "f7e1", "2 MUL32r Reg:ECX | mull %ecx | "),
  ("x86_64", "f7e9", "2 IMUL32r Reg:ECX | imull %ecx | "),
  ("x86_64", "fec9", "2 DEC8r Reg:CL Reg:CL | decb %cl | "),
  (
    "x86_64", "66f326461329", "6 ADC16rm Reg:R13W Reg:R13W Reg:RCX Imm:1 Reg: Imm:0 Reg:ES | rep  adcw %es:(%rcx), %r13w | may_load",
  ),
  (
    "x86_64", "66264213c8", "5 ADC16rr_REV Reg:CX Reg:CX Reg:AX | adcw %ax, %cx | ",
  ),
  (
    "x86_64", "67264683906f557b667d", "10 ADC32mi8 Reg:EAX Imm:1 Reg: Imm:1719358831 Reg:ES Imm:125 | adcl $125, %es:1719358831(%eax) | may_load,may_store",
  ),
  (
    "x86_64", "67264a8194c4142f69a21a9c14d4", "14 ADC64mi32 Reg:ESP Imm:8 Reg:R8D Imm:-1570164972 Reg:ES Imm:-736846822 | adcq $-736846822, %es:-1570164972(%esp,%r8d,8) | may_load,may_store",
  ),
  (
    "x86_64", "67264e81d49d589970", "9 ADC64ri32 Reg:RSP Reg:RSP Imm:1889097885 | addr32  adcq $1889097885, %rsp | ",
  ),
  (
    "x86_64", "66f32641011da2ac4584", "10 ADD16mr Reg:RIP Imm:1 Reg: Imm:-2075808606 Reg:ES Reg:BX | rep  addw %bx, %es:-2075808606(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "662603c7", "4 ADD16rr_REV Reg:AX Reg:AX Reg:DI | addw %di, %ax | ",
  ),
  (
    "x86_64", "66f326428367e660", "8 AND16mi8 Reg:RDI Imm:1 Reg: Imm:-26 Reg:ES Imm:96 | rep  andw $96, %es:-26(%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "66f32644218bccd813c6", "10 AND16mr Reg:RBX Imm:1 Reg: Imm:-971777844 Reg:ES Reg:R9W | rep  andw %r9w, %es:-971777844(%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "66f2264783e222", "7 AND16ri8 Reg:R10W Reg:R10W Imm:34 | repne  andw $34, %r10w | ",
  ),
  (
    "x86_64", "66f22640239a2a8a6d1f", "10 AND16rm Reg:BX Reg:BX Reg:RDX Imm:1 Reg: Imm:527272490 Reg:ES | repne  andw %es:527272490(%rdx), %bx | may_load",
  ),
  (
    "x86_64", "66f32621e0", "5 AND16rr Reg:AX Reg:AX Reg:SP | rep  andw %sp, %ax | ",
  ),
  (
    "x86_64", "67264483a1530c22cd63", "10 AND32mi8 Reg:ECX Imm:1 Reg: Imm:-853406637 Reg:ES Imm:99 | andl $99, %es:-853406637(%ecx) | may_load,may_store",
  ),
  (
    "x86_64", "f2264b81239b305887", "9 AND64mi32 Reg:R11 Imm:1 Reg: Imm:0 Reg:ES Imm:-2024263525 | repne  andq $-2024263525, %es:(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "f3264c2102", "5 AND64mr Reg:RDX Imm:1 Reg: Imm:0 Reg:ES Reg:R8 | rep  andq %r8, %es:(%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "66264981e3e2c082aa", "9 AND64ri32 Reg:R11 Reg:R11 Imm:-1434271518 | andq $-1434271518, %r11 | ",
  ),
  (
    "x86_64", "264122c4", "4 AND8rr_REV Reg:AL Reg:AL Reg:R12B | andb %r12b, %al | ",
  ),
  (
    "x86_64", "26430fbc4b3e", "6 BSF32rm Reg:ECX Reg:ECX Reg:R11 Imm:1 Reg: Imm:62 Reg:ES | bsfl %es:62(%r11), %ecx | may_load",
  ),
  (
    "x86_64", "66420fbd673f", "6 BSR16rm Reg:SP Reg:SP Reg:RDI Imm:1 Reg: Imm:63 Reg: | bsrw 63(%rdi), %sp | may_load",
  ),
  (
    "x86_64", "66264f0fbd619f", "7 BSR64rm Reg:R12 Reg:R12 Reg:R9 Imm:1 Reg: Imm:-97 Reg:ES | bsrq %es:-97(%r9), %r12 | may_load",
  ),
  (
    "x86_64", "6766400fa3b17b74b382", "10 BT16mr Reg:ECX Imm:1 Reg: Imm:-2102168453 Reg: Reg:SI | btw %si, -2102168453(%ecx) | may_load",
  ),
  ("x86_64", "6626470fbae544", "7 BT16ri8 Reg:R13W Imm:68 | btw $68, %r13w | "),
  (
    "x86_64", "f326460fa37f86", "7 BT32mr Reg:RDI Imm:1 Reg: Imm:-122 Reg:ES Reg:R15D | rep  btl %r15d, %es:-122(%rdi) | may_load",
  ),
  (
    "x86_64", "6766480fbaa412acd10ae348", "12 BT64mi8 Reg:EDX Imm:1 Reg:EDX Imm:-485830228 Reg: Imm:72 | btq $72, -485830228(%edx,%edx) | may_load",
  ),
  (
    "x86_64", "66f24e0fa39c5e7a9a6638", "11 BT64mr Reg:RSI Imm:2 Reg:R11 Imm:946248314 Reg: Reg:R11 | btq %r11, 946248314(%rsi,%r11,2) | may_load",
  ),
  (
    "x86_64", "67660fbaba5602d15516", "10 BTC16mi8 Reg:EDX Imm:1 Reg: Imm:1439760982 Reg: Imm:22 | btcw $22, 1439760982(%edx) | may_load,may_store",
  ),
  (
    "x86_64", "6626450fbaf8d7", "7 BTC16ri8 Reg:R8W Reg:R8W Imm:215 | btcw $215, %r8w | ",
  ),
  (
    "x86_64", "66460fbbc3", "5 BTC16rr Reg:BX Reg:BX Reg:R8W | btcw %r8w, %bx | ",
  ),
  (
    "x86_64", "67f2460fba3a0a", "7 BTC32mi8 Reg:EDX Imm:1 Reg: Imm:0 Reg: Imm:10 | btcl $10, (%edx) | may_load,may_store",
  ),
  (
    "x86_64", "67f3450fbbbf30cd496c", "10 BTC32mr Reg:R15D Imm:1 Reg: Imm:1816775984 Reg: Reg:R15D | btcl %r15d, 1816775984(%r15d) | may_load,may_store",
  ),
  (
    "x86_64", "67f2470fbafb82", "7 BTC32ri8 Reg:R11D Reg:R11D Imm:130 | addr32  btcl $130, %r11d | ",
  ),
  (
    "x86_64", "66f3440fbbf0", "6 BTC32rr Reg:AX Reg:AX Reg:R14W | btcl %r14w, %ax | ",
  ),
  (
    "x86_64", "66f2490fba3b4a", "7 BTC64mi8 Reg:R11 Imm:1 Reg: Imm:0 Reg: Imm:74 | btcq $74, (%r11) | may_load,may_store",
  ),
  (
    "x86_64", "f2264a0fbaffdc", "7 BTC64ri8 Reg:RDI Reg:RDI Imm:220 | repne  btcq $220, %rdi | ",
  ),
  (
    "x86_64", "66f34c0fbbef", "6 BTC64rr Reg:RDI Reg:RDI Reg:R13 | btcq %r13, %rdi | ",
  ),
  (
    "x86_64", "66420fb352de", "6 BTR16mr Reg:RDX Imm:1 Reg: Imm:-34 Reg: Reg:DX | btrw %dx, -34(%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "6626470fbaf76e", "7 BTR16ri8 Reg:R15W Reg:R15W Imm:110 | btrw $110, %r15w | ",
  ),
  (
    "x86_64", "6626400fb3c8", "6 BTR16rr Reg:AX Reg:AX Reg:CX | btrw %cx, %ax | ",
  ),
  (
    "x86_64", "67f3430fb3496a", "7 BTR32mr Reg:R9D Imm:1 Reg: Imm:106 Reg: Reg:ECX | btrl %ecx, 106(%r9d) | may_load,may_store",
  ),
  (
    "x86_64", "6726450fbaf1be", "7 BTR32ri8 Reg:R9D Reg:R9D Imm:190 | addr32  btrl $190, %r9d | ",
  ),
  (
    "x86_64", "26460fb3e7", "5 BTR32rr Reg:EDI Reg:EDI Reg:R12D | btrl %r12d, %edi | ",
  ),
  (
    "x86_64", "66264e0fba34678c", "8 BTR64mi8 Reg:RDI Imm:2 Reg:R12 Imm:0 Reg:ES Imm:140 | btrq $140, %es:(%rdi,%r12,2) | may_load,may_store",
  ),
  (
    "x86_64", "f24d0fb330", "5 BTR64mr Reg:R8 Imm:1 Reg: Imm:0 Reg: Reg:R14 | btrq %r14, (%r8) | may_load,may_store",
  ),
  (
    "x86_64", "66f34e0fbaf783", "7 BTR64ri8 Reg:RDI Reg:RDI Imm:131 | btrq $131, %rdi | ",
  ),
  (
    "x86_64", "f2480fb3fc", "5 BTR64rr Reg:RSP Reg:RSP Reg:RDI | btrq %rdi, %rsp | ",
  ),
  (
    "x86_64", "6626410fba6fb35b", "8 BTS16mi8 Reg:R15 Imm:1 Reg: Imm:-77 Reg:ES Imm:91 | btsw $91, %es:-77(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "6766420fab9c382583b502", "11 BTS16mr Reg:EAX Imm:1 Reg:R15D Imm:45450021 Reg: Reg:BX | btsw %bx, 45450021(%eax,%r15d) | may_load,may_store",
  ),
  (
    "x86_64", "6766450fabf1", "6 BTS16rr Reg:R9W Reg:R9W Reg:R14W | addr32  btsw %r14w, %r9w | ",
  ),
  (
    "x86_64", "26440fbaae5bd9056ec1", "10 BTS32mi8 Reg:RSI Imm:1 Reg: Imm:1845877083 Reg:ES Imm:193 | btsl $193, %es:1845877083(%rsi) | may_load,may_store",
  ),
  (
    "x86_64", "f326420fab5bbd", "7 BTS32mr Reg:RBX Imm:1 Reg: Imm:-67 Reg:ES Reg:EBX | rep  btsl %ebx, %es:-67(%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "26420fbaeff7", "6 BTS32ri8 Reg:EDI Reg:EDI Imm:247 | btsl $247, %edi | ",
  ),
  (
    "x86_64", "264f0fba284a", "6 BTS64mi8 Reg:R8 Imm:1 Reg: Imm:0 Reg:ES Imm:74 | btsq $74, %es:(%r8) | may_load,may_store",
  ),
  (
    "x86_64", "f24e0fab750e", "6 BTS64mr Reg:RBP Imm:1 Reg: Imm:14 Reg: Reg:R14 | btsq %r14, 14(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "f24e0fbaec68", "6 BTS64ri8 Reg:RSP Reg:RSP Imm:104 | btsq $104, %rsp | ",
  ),
  (
    "x86_64", "672642dad7", "5 CMOVBE_F Reg:ST7 | addr32  fcmovbe %st(7), %st | ",
  ),
  ("x86_64", "2642dac0", "4 CMOVB_F Reg:ST0 | fcmovb %st(0), %st | "),
  ("x86_64", "264fdacc", "4 CMOVE_F Reg:ST4 | fcmove %st(4), %st | "),
  ("x86_64", "662647dbd3", "5 CMOVNBE_F Reg:ST3 | fcmovnbe %st(3), %st | "),
  ("x86_64", "662645dbc6", "5 CMOVNB_F Reg:ST6 | fcmovnb %st(6), %st | "),
  ("x86_64", "f22647dbce", "5 CMOVNE_F Reg:ST6 | repne  fcmovne %st(6), %st | "),
  ("x86_64", "264cdbdb", "4 CMOVNP_F Reg:ST3 | fcmovnu %st(3), %st | "),
  ("x86_64", "f22644dadf", "5 CMOVP_F Reg:ST7 | repne  fcmovu %st(7), %st | "),
  ("x86_64", "6626413bf3", "5 CMP16rr_REV Reg:SI Reg:R11W | cmpw %r11w, %si | "),
  (
    "x86_64", "f3264d817cc5b9052c2e14", "11 CMP64mi32 Reg:R13 Imm:8 Reg:RAX Imm:-71 Reg:ES Imm:338570245 | rep  cmpq $338570245, %es:-71(%r13,%rax,8) | may_load",
  ),
  (
    "x86_64", "662647f67750", "6 DIV8m Reg:R15 Imm:1 Reg: Imm:80 Reg:ES | divb %es:80(%r15) | may_load",
  ),
  (
    "x86_64", "672646f67cc979", "7 IDIV8m Reg:ECX Imm:8 Reg:R9D Imm:121 Reg:ES | idivb %es:121(%ecx,%r9d,8) | may_load",
  ),
  (
    "x86_64", "666726426b327a", "7 IMUL16rmi8 Reg:SI Reg:EDX Imm:1 Reg: Imm:0 Reg:ES Imm:122 | imulw $122, %es:(%edx), %si | may_load",
  ),
  (
    "x86_64", "264af62b", "4 IMUL8m Reg:RBX Imm:1 Reg: Imm:0 Reg:ES | imulb %es:(%rbx) | may_load",
  ),
  (
    "x86_64", "66460f83b6c0", "6 JCC_2 Imm:-16202 Imm:3 | jae -16202 | cond,terminator,affect_cf",
  ),
  (
    "x86_64", "67f22644e3de", "6 JECXZ Imm:-34 | repne  jecxz -34 | cond,terminator,affect_cf",
  ),
  (
    "x86_64", "264ecb", "3 LRET64  | lretq | return,barrier,terminator,affect_cf",
  ),
  (
    "x86_64", "6766f3470fbd740221", "9 LZCNT16rm Reg:R14W Reg:R10D Imm:1 Reg:R8D Imm:33 Reg: | lzcntw 33(%r10d,%r8d), %r14w | may_load",
  ),
  (
    "x86_64", "66410f38f15b66", "7 MOVBE16mr Reg:R11 Imm:1 Reg: Imm:102 Reg: Reg:BX | movbew %bx, 102(%r11) | may_store",
  ),
  (
    "x86_64", "6766470fb63599abf128", "10 MOVZX16rm8 Reg:R14W Reg:EIP Imm:1 Reg: Imm:686926745 Reg: | movzbw 686926745(%eip), %r14w | may_load",
  ),
  (
    "x86_64", "67f24e0fb763a9", "7 MOVZX64rm16 Reg:R12 Reg:EBX Imm:1 Reg: Imm:-87 Reg: | movzwq -87(%ebx), %r12 | may_load",
  ),
  (
    "x86_64", "664c0fb661fe", "6 MOVZX64rm8 Reg:R12 Reg:RCX Imm:1 Reg: Imm:-2 Reg: | movzbq -2(%rcx), %r12 | may_load",
  ),
  (
    "x86_64", "662645f623", "5 MUL8m Reg:R11 Imm:1 Reg: Imm:0 Reg:ES | mulb %es:(%r11) | may_load",
  ),
  (
    "x86_64", "2645f751c8", "5 NOT32m Reg:R9 Imm:1 Reg: Imm:-56 Reg:ES | notl %es:-56(%r9) | may_load,may_store",
  ),
  (
    "x86_64", "2649f69319514004", "8 NOT8m Reg:R11 Imm:1 Reg: Imm:71323929 Reg:ES | notb %es:71323929(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "666726838a6dcfab7f35", "10 OR16mi8 Reg:EDX Imm:1 Reg: Imm:2141966189 Reg:ES Imm:53 | orw $53, %es:2141966189(%edx) | may_load,may_store",
  ),
  (
    "x86_64", "66f22645091b", "6 OR16mr Reg:R11 Imm:1 Reg: Imm:0 Reg:ES Reg:R11W | repne  orw %r11w, %es:(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "66f2264509f2", "6 OR16rr Reg:R10W Reg:R10W Reg:R14W | repne  orw %r14w, %r10w | ",
  ),
  (
    "x86_64", "66f326410bf2", "6 OR16rr_REV Reg:SI Reg:SI Reg:R10W | rep  orw %r10w, %si | ",
  ),
  (
    "x86_64", "f22643838f6108448c30", "10 OR32mi8 Reg:R15 Imm:1 Reg: Imm:-1941698463 Reg:ES Imm:48 | repne  orl $48, %es:-1941698463(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "6726470bcb", "5 OR32rr_REV Reg:R9D Reg:R9D Reg:R11D | addr32  orl %r11d, %r9d | ",
  ),
  (
    "x86_64", "264b8108a95b8c35", "8 OR64mi32 Reg:R8 Imm:1 Reg: Imm:0 Reg:ES Imm:898390953 | orq $898390953, %es:(%r8) | may_load,may_store",
  ),
  (
    "x86_64", "f3264c838db13d996b2c", "10 OR64mi8 Reg:RBP Imm:1 Reg: Imm:1805204913 Reg:ES Imm:44 | rep  orq $44, %es:1805204913(%rbp) | may_load,may_store",
  ),
  (
    "x86_64", "f2264f0be2", "5 OR64rr_REV Reg:R12 Reg:R12 Reg:R10 | repne  orq %r10, %r12 | ",
  ),
  (
    "x86_64", "264b0ae8", "4 OR8rr_REV Reg:BPL Reg:BPL Reg:R8B | orb %r8b, %bpl | ",
  ),
  (
    "x86_64", "662645d357a0", "6 RCL16mCL Reg:R15 Imm:1 Reg: Imm:-96 Reg:ES | rclw %cl, %es:-96(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "66f22642d3d6", "6 RCL16rCL Reg:SI Reg:SI | repne  rclw %cl, %si | ",
  ),
  (
    "x86_64", "2642d115d70eca03", "8 RCL32m1 Reg:RIP Imm:1 Reg: Imm:63573719 Reg:ES | rcll %es:63573719(%rip) | may_load,may_store",
  ),
  (
    "x86_64", "2645d317", "4 RCL32mCL Reg:R15 Imm:1 Reg: Imm:0 Reg:ES | rcll %cl, %es:(%r15) | may_load,may_store",
  ),
  ("x86_64", "f22642d1d1", "5 RCL32r1 Reg:ECX Reg:ECX | repne  rcll %ecx | "),
  ("x86_64", "2646d3d2", "4 RCL32rCL Reg:EDX Reg:EDX | rcll %cl, %edx | "),
  (
    "x86_64", "66264bd310", "5 RCL64mCL Reg:R8 Imm:1 Reg: Imm:0 Reg:ES | rclq %cl, %es:(%r8) | may_load,may_store",
  ),
  ("x86_64", "67264dd1d0", "5 RCL64r1 Reg:R8 Reg:R8 | addr32  rclq %r8 | "),
  (
    "x86_64", "f3264ed3d0", "5 RCL64rCL Reg:RAX Reg:RAX | rep  rclq %cl, %rax | ",
  ),
  (
    "x86_64", "662646d0510f", "6 RCL8m1 Reg:RCX Imm:1 Reg: Imm:15 Reg:ES | rclb %es:15(%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "f32641d253aa", "6 RCL8mCL Reg:R11 Imm:1 Reg: Imm:-86 Reg:ES | rep  rclb %cl, %es:-86(%r11) | may_load,may_store",
  ),
  ("x86_64", "662642d2d6", "5 RCL8rCL Reg:SIL Reg:SIL | rclb %cl, %sil | "),
  (
    "x86_64", "662640d19ab122eed5", "9 RCR16m1 Reg:RDX Imm:1 Reg: Imm:-705813839 Reg:ES | rcrw %es:-705813839(%rdx) | may_load,may_store",
  ),
  ("x86_64", "662646d1dc", "5 RCR16r1 Reg:SP Reg:SP | rcrw %sp | "),
  (
    "x86_64", "67264cd199524b4ab7", "9 RCR64m1 Reg:ECX Imm:1 Reg: Imm:-1219867822 Reg:ES | rcrq %es:-1219867822(%ecx) | may_load,may_store",
  ),
  (
    "x86_64", "f2264ed31cd6", "6 RCR64mCL Reg:RSI Imm:8 Reg:R10 Imm:0 Reg:ES | repne  rcrq %cl, %es:(%rsi,%r10,8) | may_load,may_store",
  ),
  ("x86_64", "f2264ad1de", "5 RCR64r1 Reg:RSI Reg:RSI | repne  rcrq %rsi | "),
  (
    "x86_64", "2643d05b60", "5 RCR8m1 Reg:R11 Imm:1 Reg: Imm:96 Reg:ES | rcrb %es:96(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "2649d29b7b5151ad", "8 RCR8mCL Reg:R11 Imm:1 Reg: Imm:-1387179653 Reg:ES | rcrb %cl, %es:-1387179653(%r11) | may_load,may_store",
  ),
  ("x86_64", "672643d0dc", "5 RCR8r1 Reg:R12B Reg:R12B | addr32  rcrb %r12b | "),
  ("x86_64", "26d2dc", "3 RCR8rCL Reg:AH Reg:AH | rcrb %cl, %ah | "),
  ("x86_64", "264b0fc7f8", "5 RDSEED64r Reg:R8 | rdseedq %r8 | "),
  (
    "x86_64", "66672646d380a71db229", "10 ROL16mCL Reg:EAX Imm:1 Reg: Imm:699538855 Reg:ES | rolw %cl, %es:699538855(%eax) | may_load,may_store",
  ),
  ("x86_64", "662640d3c7", "5 ROL16rCL Reg:DI Reg:DI | rolw %cl, %di | "),
  (
    "x86_64", "f32643d10548832254", "9 ROL32m1 Reg:RIP Imm:1 Reg: Imm:1411547976 Reg:ES | rep  roll %es:1411547976(%rip) | may_load,may_store",
  ),
  ("x86_64", "f22646d1c4", "5 ROL32r1 Reg:ESP Reg:ESP | repne  roll %esp | "),
  (
    "x86_64", "66264bd385cf4e545f", "9 ROL64mCL Reg:R13 Imm:1 Reg: Imm:1599360719 Reg:ES | rolq %cl, %es:1599360719(%r13) | may_load,may_store",
  ),
  ("x86_64", "264bd1c3", "4 ROL64r1 Reg:R11 Reg:R11 | rolq %r11 | "),
  (
    "x86_64", "f3264ed3c6", "5 ROL64rCL Reg:RSI Reg:RSI | rep  rolq %cl, %rsi | ",
  ),
  (
    "x86_64", "672641d203", "5 ROL8mCL Reg:R11D Imm:1 Reg: Imm:0 Reg:ES | rolb %cl, %es:(%r11d) | may_load,may_store",
  ),
  (
    "x86_64", "66672645d14bf8", "7 ROR16m1 Reg:R11D Imm:1 Reg: Imm:-8 Reg:ES | rorw %es:-8(%r11d) | may_load,may_store",
  ),
  ("x86_64", "66f32644d1cb", "6 ROR16r1 Reg:BX Reg:BX | rep  rorw %bx | "),
  (
    "x86_64", "672645d18c875fd84429", "10 ROR32m1 Reg:R15D Imm:4 Reg:EAX Imm:692377695 Reg:ES | rorl %es:692377695(%r15d,%eax,4) | may_load,may_store",
  ),
  (
    "x86_64", "f32649d18f3790d90b", "9 ROR64m1 Reg:R15 Imm:1 Reg: Imm:198807607 Reg:ES | rep  rorq %es:198807607(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "f22649d34b34", "6 ROR64mCL Reg:R11 Imm:1 Reg: Imm:52 Reg:ES | repne  rorq %cl, %es:52(%r11) | may_load,may_store",
  ),
  ("x86_64", "264bd1cd", "4 ROR64r1 Reg:R13 Reg:R13 | rorq %r13 | "),
  (
    "x86_64", "f32642d20e", "5 ROR8mCL Reg:RSI Imm:1 Reg: Imm:0 Reg:ES | rep  rorb %cl, %es:(%rsi) | may_load,may_store",
  ),
  ("x86_64", "f22644d0cd", "5 ROR8r1 Reg:BPL Reg:BPL | repne  rorb %bpl | "),
  (
    "x86_64", "672641d2c9", "5 ROR8rCL Reg:R9B Reg:R9B | addr32  rorb %cl, %r9b | ",
  ),
  (
    "x86_64", "662646d138", "5 SAR16m1 Reg:RAX Imm:1 Reg: Imm:0 Reg:ES | sarw %es:(%rax) | may_load,may_store",
  ),
  (
    "x86_64", "66f32646d33b", "6 SAR16mCL Reg:RBX Imm:1 Reg: Imm:0 Reg:ES | rep  sarw %cl, %es:(%rbx) | may_load,may_store",
  ),
  ("x86_64", "66f32642d1f9", "6 SAR16r1 Reg:CX Reg:CX | rep  sarw %cx | "),
  (
    "x86_64", "666726d3fc", "5 SAR16rCL Reg:SP Reg:SP | addr32  sarw %cl, %sp | ",
  ),
  (
    "x86_64", "f22643d1b8949ff1d4", "9 SAR32m1 Reg:R8 Imm:1 Reg: Imm:-722362476 Reg:ES | repne  sarl %es:-722362476(%r8) | may_load,may_store",
  ),
  (
    "x86_64", "f32645d33a", "5 SAR32mCL Reg:R10 Imm:1 Reg: Imm:0 Reg:ES | rep  sarl %cl, %es:(%r10) | may_load,may_store",
  ),
  (
    "x86_64", "67264ad139", "5 SAR64m1 Reg:ECX Imm:1 Reg: Imm:0 Reg:ES | sarq %es:(%ecx) | may_load,may_store",
  ),
  (
    "x86_64", "66264fd3bca0127b5b64", "10 SAR64mCL Reg:R8 Imm:4 Reg:R12 Imm:1683716882 Reg:ES | sarq %cl, %es:1683716882(%r8,%r12,4) | may_load,may_store",
  ),
  (
    "x86_64", "f3264fd3ff", "5 SAR64rCL Reg:R15 Reg:R15 | rep  sarq %cl, %r15 | ",
  ),
  (
    "x86_64", "672647d038", "5 SAR8m1 Reg:R8D Imm:1 Reg: Imm:0 Reg:ES | sarb %es:(%r8d) | may_load,may_store",
  ),
  (
    "x86_64", "f32641d239", "5 SAR8mCL Reg:R9 Imm:1 Reg: Imm:0 Reg:ES | rep  sarb %cl, %es:(%r9) | may_load,may_store",
  ),
  ("x86_64", "f32642d0f8", "5 SAR8r1 Reg:AL Reg:AL | rep  sarb %al | "),
  (
    "x86_64", "66672645831b27", "7 SBB16mi8 Reg:R11D Imm:1 Reg: Imm:0 Reg:ES Imm:39 | sbbw $39, %es:(%r11d) | may_load,may_store",
  ),
  (
    "x86_64", "66f22641195cb0c9", "8 SBB16mr Reg:R8 Imm:4 Reg:RSI Imm:-55 Reg:ES Reg:BX | repne  sbbw %bx, %es:-55(%r8,%rsi,4) | may_load,may_store",
  ),
  (
    "x86_64", "66f3264119de", "6 SBB16rr Reg:R14W Reg:R14W Reg:BX | rep  sbbw %bx, %r14w | ",
  ),
  (
    "x86_64", "66264c81985f4e37ce02c53480", "13 SBB64mi32 Reg:RAX Imm:1 Reg: Imm:-835236257 Reg:ES Imm:-2144025342 | sbbq $-2144025342, %es:-835236257(%rax) | may_load,may_store",
  ),
  (
    "x86_64", "f3264d839fc9ee496937", "10 SBB64mi8 Reg:R15 Imm:1 Reg: Imm:1766452937 Reg:ES Imm:55 | rep  sbbq $55, %es:1766452937(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "67264e19aab116f695", "9 SBB64mr Reg:EDX Imm:1 Reg: Imm:-1779034447 Reg:ES Reg:R13 | sbbq %r13, %es:-1779034447(%edx) | may_load,may_store",
  ),
  (
    "x86_64", "66264c81df84121e5a", "9 SBB64ri32 Reg:RDI Reg:RDI Imm:1511920260 | sbbq $1511920260, %rdi | ",
  ),
  (
    "x86_64", "66672646d364baf0", "8 SHL16mCL Reg:EDX Imm:4 Reg:R15D Imm:-16 Reg:ES | shlw %cl, %es:-16(%edx,%r15d,4) | may_load,may_store",
  ),
  (
    "x86_64", "66f22644d3e0", "6 SHL16rCL Reg:AX Reg:AX | repne  shlw %cl, %ax | ",
  ),
  (
    "x86_64", "f32643d1645a39", "7 SHL32m1 Reg:R10 Imm:2 Reg:R11 Imm:57 Reg:ES | rep  shll %es:57(%r10,%r11,2) | may_load,may_store",
  ),
  (
    "x86_64", "f22641d36102", "6 SHL32mCL Reg:R9 Imm:1 Reg: Imm:2 Reg:ES | repne  shll %cl, %es:2(%r9) | may_load,may_store",
  ),
  (
    "x86_64", "f22648d327", "5 SHL64mCL Reg:RDI Imm:1 Reg: Imm:0 Reg:ES | repne  shlq %cl, %es:(%rdi) | may_load,may_store",
  ),
  ("x86_64", "67264fd1e2", "5 SHL64r1 Reg:R10 Reg:R10 | addr32  shlq %r10 | "),
  (
    "x86_64", "662641d2604e", "6 SHL8mCL Reg:R8 Imm:1 Reg: Imm:78 Reg:ES | shlb %cl, %es:78(%r8) | may_load,may_store",
  ),
  ("x86_64", "2644d2e3", "4 SHL8rCL Reg:BL Reg:BL | shlb %cl, %bl | "),
  (
    "x86_64", "6626440fa41c454c5fd90ac3", "12 SHLD16mri8 Reg: Imm:2 Reg:RAX Imm:182017868 Reg:ES Reg:R11W Imm:195 | shldw $195, %r11w, %es:182017868(,%rax,2) | may_load,may_store",
  ),
  (
    "x86_64", "6626420fa5ff", "6 SHLD16rrCL Reg:DI Reg:DI Reg:DI | shldw %cl, %di, %di | ",
  ),
  (
    "x86_64", "f2440fa420a1", "6 SHLD32mri8 Reg:RAX Imm:1 Reg: Imm:0 Reg: Reg:R12D Imm:161 | shldl $161, %r12d, (%rax) | may_load,may_store",
  ),
  (
    "x86_64", "26440fa5f3", "5 SHLD32rrCL Reg:EBX Reg:EBX Reg:R14D | shldl %cl, %r14d, %ebx | ",
  ),
  (
    "x86_64", "66264e0fa503", "6 SHLD64mrCL Reg:RBX Imm:1 Reg: Imm:0 Reg:ES Reg:R8 | shldq %cl, %r8, %es:(%rbx) | may_load,may_store",
  ),
  (
    "x86_64", "f3264c0fa45164aa", "8 SHLD64mri8 Reg:RCX Imm:1 Reg: Imm:100 Reg:ES Reg:R10 Imm:170 | rep  shldq $170, %r10, %es:100(%rcx) | may_load,may_store",
  ),
  (
    "x86_64", "66f22647d16ccfc1", "8 SHR16m1 Reg:R15 Imm:8 Reg:R9 Imm:-63 Reg:ES | repne  shrw %es:-63(%r15,%r9,8) | may_load,may_store",
  ),
  ("x86_64", "662641d1ea", "5 SHR16r1 Reg:R10W Reg:R10W | shrw %r10w | "),
  (
    "x86_64", "264dd16b13", "5 SHR64m1 Reg:R11 Imm:1 Reg: Imm:19 Reg:ES | shrq %es:19(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "67264cd32f", "5 SHR64mCL Reg:EDI Imm:1 Reg: Imm:0 Reg:ES | shrq %cl, %es:(%edi) | may_load,may_store",
  ),
  ("x86_64", "f3264dd1eb", "5 SHR64r1 Reg:R11 Reg:R11 | rep  shrq %r11 | "),
  (
    "x86_64", "264ed02c2b", "5 SHR8m1 Reg:RBX Imm:1 Reg:R13 Imm:0 Reg:ES | shrb %es:(%rbx,%r13) | may_load,may_store",
  ),
  ("x86_64", "f326d2e8", "4 SHR8rCL Reg:AL Reg:AL | rep  shrb %cl, %al | "),
  (
    "x86_64", "66450fad1b", "5 SHRD16mrCL Reg:R11 Imm:1 Reg: Imm:0 Reg: Reg:R11W | shrdw %cl, %r11w, (%r11) | may_load,may_store",
  ),
  (
    "x86_64", "f326430fad777a", "7 SHRD32mrCL Reg:R15 Imm:1 Reg: Imm:122 Reg:ES Reg:ESI | rep  shrdl %cl, %esi, %es:122(%r15) | may_load,may_store",
  ),
  (
    "x86_64", "f326470fac3302", "7 SHRD32mri8 Reg:R11 Imm:1 Reg: Imm:0 Reg:ES Reg:R14D Imm:2 | rep  shrdl $2, %r14d, %es:(%r11) | may_load,may_store",
  ),
  (
    "x86_64", "66f3420facc17e", "7 SHRD32rri8 Reg:CX Reg:CX Reg:AX Imm:126 | shrdl $126, %ax, %cx | ",
  ),
  (
    "x86_64", "264e0fad789a", "6 SHRD64mrCL Reg:RAX Imm:1 Reg: Imm:-102 Reg:ES Reg:R15 | shrdq %cl, %r15, %es:-102(%rax) | may_load,may_store",
  ),
  (
    "x86_64", "664d0faced40", "6 SHRD64rri8 Reg:R13 Reg:R13 Reg:R13 Imm:64 | shrdq $64, %r13, %r13 | ",
  ),
  (
    "x86_64", "662644836a6323", "7 SUB16mi8 Reg:RDX Imm:1 Reg: Imm:99 Reg:ES Imm:35 | subw $35, %es:99(%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "66f22683ec8d", "6 SUB16ri8 Reg:SP Reg:SP Imm:-115 | repne  subw $-115, %sp | ",
  ),
  (
    "x86_64", "6667262b81634e11da", "9 SUB16rm Reg:AX Reg:AX Reg:ECX Imm:1 Reg: Imm:-636400029 Reg:ES | subw %es:-636400029(%ecx), %ax | may_load",
  ),
  (
    "x86_64", "66f3264029fc", "6 SUB16rr Reg:SP Reg:SP Reg:DI | rep  subw %di, %sp | ",
  ),
  (
    "x86_64", "66f226412bfa", "6 SUB16rr_REV Reg:DI Reg:DI Reg:R10W | repne  subw %r10w, %di | ",
  ),
  (
    "x86_64", "f226836f8379", "6 SUB32mi8 Reg:RDI Imm:1 Reg: Imm:-125 Reg:ES Imm:121 | repne  subl $121, %es:-125(%rdi) | may_load,may_store",
  ),
  (
    "x86_64", "f2264a812a660ab29b", "9 SUB64mi32 Reg:RDX Imm:1 Reg: Imm:0 Reg:ES Imm:-1682830746 | repne  subq $-1682830746, %es:(%rdx) | may_load,may_store",
  ),
  (
    "x86_64", "264d8369bbb3", "6 SUB64mi8 Reg:R9 Imm:1 Reg: Imm:-69 Reg:ES Imm:-77 | subq $-77, %es:-69(%r9) | may_load,may_store",
  ),
  (
    "x86_64", "66f326430fbc456a", "8 TZCNT16rm Reg:AX Reg:R13 Imm:1 Reg: Imm:106 Reg:ES | rep  tzcntw %es:106(%r13), %ax | may_load",
  ),
  (
    "x86_64", "f3470fbc13", "5 TZCNT32rm Reg:R10D Reg:R11 Imm:1 Reg: Imm:0 Reg: | tzcntl (%r11), %r10d | may_load",
  ),
  (
    "x86_64", "f34a0fbc32", "5 TZCNT64rm Reg:RSI Reg:RDX Imm:1 Reg: Imm:0 Reg: | tzcntq (%rdx), %rsi | may_load",
  ),
  (
    "x86_64", "66f3264283f0b9", "7 XOR16ri8 Reg:AX Reg:AX Imm:-71 | rep  xorw $-71, %ax | ",
  ),
  (
    "x86_64", "66f3264233d0", "6 XOR16rr_REV Reg:DX Reg:DX Reg:AX | rep  xorw %ax, %dx | ",
  ),
  (
    "x86_64", "67264633e5", "5 XOR32rr_REV Reg:R12D Reg:R12D Reg:EBP | addr32  xorl %ebp, %r12d | ",
  ),
  (
    "x86_64", "67264c8133c964597c", "9 XOR64mi32 Reg:EBX Imm:1 Reg: Imm:0 Reg:ES Imm:2086233289 | xorq $2086233289, %es:(%ebx) | may_load,may_store",
  ),
  (
    "x86_64", "67264c83763bb6", "7 XOR64mi8 Reg:ESI Imm:1 Reg: Imm:59 Reg:ES Imm:-74 | xorq $-74, %es:59(%esi) | may_load,may_store",
  ),
]

///|
fn x86_llvm_hex_digit(c : Char) -> Int {
  if c >= '0' && c <= '9' {
    c.to_int() - '0'.to_int()
  } else {
    c.to_int() - 'a'.to_int() + 10
  }
}

///|
fn x86_llvm_hex_bytes(hex : String) -> Bytes {
  let chars = hex.to_array()
  Bytes::makei(hex.length() / 2, i => {
    ((x86_llvm_hex_digit(chars[2 * i]) << 4) |
    x86_llvm_hex_digit(chars[2 * i + 1])).to_byte()
  })
}

///|
/// The instruction in the format of the samples: size, name, MCInst
/// operands, assembly and kinds.
fn x86_llvm_render(insn : @project.ProjectDisassemblyInstruction) -> String {
  let ops = insn
    .operands()
    .map(op => {
      match op {
        ProjectRegisterOperand(_, name) =>
          "Reg:" + (if name == "Nil" { "" } else { name })
        ProjectImmediateOperand(value) => "Imm:" + value.to_string()
        ProjectFloatingOperand(value) => "Fmm:" + value.to_string()
      }
    })
  let order : Array[(@project.ProjectInstructionKind, String)] = [
    (ProjectConditionalBranch, "cond"),
    (ProjectUnconditionalBranch, "uncond"),
    (ProjectIndirectBranch, "indirect"),
    (ProjectReturn, "return"),
    (ProjectCall, "call"),
    (ProjectBarrier, "barrier"),
    (ProjectTerminator, "terminator"),
    (ProjectMayAffectControlFlow, "affect_cf"),
    (ProjectMayLoad, "may_load"),
    (ProjectMayStore, "may_store"),
  ]
  let kinds = order.filter(k => insn.has_kind(k.0)).map(k => k.1)
  "\{insn.memory().length()} \{insn.name()} \{ops.join(" ")} | \{insn.assembly()} | \{kinds.join(",")}"
}

///|
test "x86 Basic llvm decoder decodes every sample like llvm-mc" {
  let decoders : Map[String, @project.ProjectDisassemblyBasic] = Map([])
  let failures = []
  for sample in x86_llvm_samples {
    let (triple, hex, expected) = sample
    let disasm = match decoders.get(triple) {
      Some(disasm) => disasm
      None => {
        let disasm = @project.ProjectDisassemblyBasic::create(
          triple,
          backend="llvm",
        ).unwrap()
        decoders[triple] = disasm
        disasm
      }
    }
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0UL,
      x86_llvm_hex_bytes(hex),
    )
    let actual = match disasm.insn_of_mem(memory) {
      Ok(result) =>
        match result.instruction() {
          Some(insn) => x86_llvm_render(insn)
          None => "invalid \{result.memory().length()}"
        }
      Err(reason) => "error " + reason
    }
    if actual != expected {
      failures.push("\{triple} \{hex}: \{actual} (llvm: \{expected})")
    }
  }
  assert_eq(failures, [])
  assert_true(x86_llvm_samples.length() > 1000)
}

///|
test "x86 Basic llvm decoder reports invalid encodings with LLVM's sizes" {
  // (triple, bytes, size LLVM consumed before rejecting them)
  let samples : Array[(String, String, Int)] = [
    ("x86_64", "06", 1), // push %es is not valid in 64-bit mode
    ("x86_64", "0f0b01", 2), // ud2 is valid: two bytes
    ("x86_64", "c4e2780f", 4), // VEX with no instruction in the map
    ("x86_64", "4801", 2), // truncated ModR/M
    ("x86_64", "f348", 2), // repeat prefix followed by a lone REX
    ("x86_64", "40", 1), // a lone REX without W
    ("x86", "8fe87885c1", 5), // XOP opcode without an instruction
    ("x86", "0f", 1), // lone escape byte
  ]
  for sample in samples {
    let (triple, hex, size) = sample
    let disasm = @project.ProjectDisassemblyBasic::create(
      triple,
      backend="llvm",
    ).unwrap()
    let memory = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=0UL,
      x86_llvm_hex_bytes(hex),
    )
    match disasm.insn_of_mem(memory) {
      Ok(result) =>
        match result.instruction() {
          Some(insn) =>
            if hex == "0f0b01" {
              assert_eq(insn.name(), "TRAP")
              assert_eq(result.memory().length(), size)
            } else {
              fail("\{triple} \{hex} decoded as \{insn.name()}")
            }
          None => assert_eq((hex, result.memory().length()), (hex, size))
        }
      Err(reason) => fail(reason)
    }
  }
}
