// LLVM samples of the table-decoded PowerPC instructions (`decode_ext.mbt`):
// one word per opcode and printed form (preferring words of compiled C
// code), with the output of LLVM 22's disassembler (`llvm-mc
// -disassemble -show-inst -triple=powerpc64-linux-gnu`): the big-endian
// word, `NAME op op | assembly` and the kinds, separated by tabs.

///|
let llvm_ext_samples : String =
  #|0x0835d7ed	TDI Imm:1 Reg:X21 Imm:-10259 | tdlgti 21, -10259	
  #|0x085a0000	TDI Imm:2 Reg:X26 Imm:0 | tdllti 26, 0	
  #|0x08808e9b	TDI Imm:4 Reg:X0 Imm:-29029 | tdeqi 0, -29029	
  #|0x09162427	TDI Imm:8 Reg:X22 Imm:9255 | tdgti 22, 9255	
  #|0x0a1b0000	TDI Imm:16 Reg:X27 Imm:0 | tdlti 27, 0	
  #|0x0a645fa9	TDI Imm:19 Reg:X4 Imm:24489 | tdi 19, 4, 24489	
  #|0x0b116d4c	TDI Imm:24 Reg:X17 Imm:27980 | tdnei 17, 27980	
  #|0x0be00000	TDI Imm:31 Reg:X0 Imm:0 | tdui 0, 0	
  #|0x0c2045f9	TWI Imm:1 Reg:R0 Imm:17913 | twlgti 0, 17913	
  #|0x0c40a7d2	TWI Imm:2 Reg:R0 Imm:-22574 | twllti 0, -22574	
  #|0x0c800000	TWI Imm:4 Reg:R0 Imm:0 | tweqi 0, 0	
  #|0x0d000000	TWI Imm:8 Reg:R0 Imm:0 | twgti 0, 0	
  #|0x0e150f34	TWI Imm:16 Reg:R21 Imm:3892 | twlti 21, 3892	
  #|0x0ed0d097	TWI Imm:22 Reg:R16 Imm:-12137 | twi 22, 16, -12137	
  #|0x0f000000	TWI Imm:24 Reg:R0 Imm:0 | twnei 0, 0	
  #|0x0ff961cd	TWI Imm:31 Reg:R25 Imm:25037 | twui 25, 25037	
  #|0x100000c3	VUCMPRLB Reg:V0 Reg:V0 Reg:V0 | vucmprlb 0, 0, 0	
  #|0x1000010c	VMRGLB Reg:V0 Reg:V0 Reg:V0 | vmrglb 0, 0, 0	
  #|0x100004c4	VXOR Reg:V0 Reg:V0 Reg:V0 | vxor 0, 0, 0	
  #|0x10000504	VNOR Reg:V0 Reg:V0 Reg:V0 | vnot 0, 0	
  #|0x10000547	VCMPNEZH_rec Reg:V0 Reg:V0 Reg:V0 | vcmpnezh. 0, 0, 0	
  #|0x1000060d	VEXTUBLX Reg:X0 Reg:X0 Reg:V0 | vextublx 0, 0, 0	
  #|0x10000625	VMSUMMBM Reg:V0 Reg:V0 Reg:V0 Reg:V24 | vmsummbm 0, 0, 0, 24	
  #|0x10000642	VEXPANDBM Reg:V0 Reg:V0 | vexpandbm 0, 0	
  #|0x10000644	MTVSCR Reg:V0 | mtvscr 0	
  #|0x1000064d	VEXTUHLX Reg:X0 Reg:X0 Reg:V0 | vextuhlx 0, 0, 0	
  #|0x10000702	VCLZB Reg:V0 Reg:V0 | vclzb 0, 0	
  #|0x100007c7	VCMPGTSD_rec Reg:V0 Reg:V0 Reg:V0 | vcmpgtsd. 0, 0, 0	
  #|0x10000e8c	VMRGOW Reg:V0 Reg:V0 Reg:V1 | vmrgow 0, 0, 1	
  #|0x10001402	VAVGUB Reg:V0 Reg:V0 Reg:V2 | vavgub 0, 0, 2	
  #|0x100017c6	VCMPBFP_rec Reg:V0 Reg:V0 Reg:V2 | vcmpbfp. 0, 0, 2	
  #|0x1000190a	VREFP Reg:V0 Reg:V3 | vrefp 0, 3	
  #|0x10001984	VSLW Reg:V0 Reg:V0 Reg:V3 | vslw 0, 0, 3	
  #|0x1000198e	VPKSHSS Reg:V0 Reg:V0 Reg:V3 | vpkshss 0, 0, 3	
  #|0x10001bc2	VMINSD Reg:V0 Reg:V0 Reg:V3 | vminsd 0, 0, 3	
  #|0x1000224d	VEXTRACTUH Reg:V0 Imm:0 Reg:V4 | vextractuh 0, 4, 0	
  #|0x10002541	BCDUTRUNC_rec Reg:V0 Reg:V0 Reg:V4 | bcdutrunc. 0, 0, 4	
  #|0x10002b41	BCDCPSGN_rec Reg:V0 Reg:V0 Reg:V5 | bcdcpsgn. 0, 0, 5	
  #|0x10002ece	VUPKLSW Reg:V0 Reg:V5 | vupklsw 0, 5	
  #|0x10004acf	VINSDLX Reg:V0 Reg:V0 Reg:X0 Reg:X9 | vinsdlx 0, 0, 9	
  #|0x100051cb	VDIVSD Reg:V0 Reg:V0 Reg:V10 | vdivsd 0, 0, 10	
  #|0x100052c4	VSR Reg:V0 Reg:V0 Reg:V10 | vsr 0, 0, 10	
  #|0x10005c07	VCMPNEB_rec Reg:V0 Reg:V0 Reg:V11 | vcmpneb. 0, 0, 11	
  #|0x10006080	VADDUWM Reg:V0 Reg:V0 Reg:V12 | vadduwm 0, 0, 12	
  #|0x100060c0	VADDUDM Reg:V0 Reg:V0 Reg:V12 | vaddudm 0, 0, 12	
  #|0x10006101	VCMPUQ Reg:CR0 Reg:V0 Reg:V12 | vcmpuq 0, 0, 12	
  #|0x10006340	VADDSHS Reg:V0 Reg:V0 Reg:V12 | vaddshs 0, 0, 12	
  #|0x1000640d	VSTRIBL_rec Reg:V0 Reg:V12 | vstribl. 0, 12	
  #|0x10006ace	VUPKLSH Reg:V0 Reg:V13 | vupklsh 0, 13	
  #|0x1000734e	VUPKHPX Reg:V0 Reg:V14 | vupkhpx 0, 14	
  #|0x10007a0e	VUPKHSB Reg:V0 Reg:V15 | vupkhsb 0, 15	
  #|0x10009608	VSUM4UBS Reg:V0 Reg:V0 Reg:V18 | vsum4ubs 0, 0, 18	
  #|0x10009af0	MADDHD Reg:X0 Reg:X0 Reg:X19 Reg:X11 | maddhd 0, 0, 19, 11	
  #|0x1000b145	VRLQNM Reg:V0 Reg:V0 Reg:V22 | vrlqnm 0, 0, 22	
  #|0x1000bd0c	VGBBD Reg:V0 Reg:V23 | vgbbd 0, 23	
  #|0x1000c35b	VEXTDUHVRX Reg:V0 Reg:V0 Reg:V24 Reg:R13 | vextduhvrx 0, 0, 24, 13	
  #|0x1000c782	VCLZW Reg:V0 Reg:V24 | vclzw 0, 24	
  #|0x1000d743	VPOPCNTH Reg:V0 Reg:V26 | vpopcnth 0, 26	
  #|0x1000ef4d	VEXTUHRX Reg:X0 Reg:X0 Reg:V29 | vextuhrx 0, 0, 29	
  #|0x10010482	VAVGUW Reg:V0 Reg:V1 Reg:V0 | vavguw 0, 1, 0	
  #|0x1001b00d	VSTRIBR Reg:V0 Reg:V22 | vstribr 0, 22	
  #|0x10022c0d	VSTRIHL_rec Reg:V0 Reg:V5 | vstrihl. 0, 5	
  #|0x10024b0f	VINSBRX Reg:V0 Reg:V0 Reg:R2 Reg:R9 | vinsbrx 0, 2, 9	
  #|0x10024baa	VSEL Reg:V0 Reg:V2 Reg:V9 Reg:V14 | vsel 0, 2, 9, 14	
  #|0x10025ec6	VCMPGTFP_rec Reg:V0 Reg:V2 Reg:V11 | vcmpgtfp. 0, 2, 11	
  #|0x1003030c	VSPLTISB Reg:V0 Imm:3 | vspltisb 0, 3	
  #|0x1003040d	VSTRIHR_rec Reg:V0 Reg:V0 | vstrihr. 0, 0	
  #|0x10033208	VMULEUB Reg:V0 Reg:V3 Reg:V6 | vmuleub 0, 3, 6	
  #|0x1003f00d	VSTRIHR Reg:V0 Reg:V30 | vstrihr 0, 30	
  #|0x10042ed9	VEXTDUBVRX Reg:V0 Reg:V4 Reg:V5 Reg:R27 | vextdubvrx 0, 4, 5, 27	
  #|0x100440ce	VPKUWUS Reg:V0 Reg:V4 Reg:V8 | vpkuwus 0, 4, 8	
  #|0x1004c581	BCDCTZ_rec Reg:V0 Reg:V24 Imm:0 | bcdctz. 0, 24, 0	
  #|0x1004ccc6	VCMPEQFP_rec Reg:V0 Reg:V4 Reg:V25 | vcmpeqfp. 0, 4, 25	
  #|0x10050408	VPMSUMB Reg:V0 Reg:V5 Reg:V0 | vpmsumb 0, 5, 0	
  #|0x1006006b	VPERM Reg:V0 Reg:V6 Reg:V0 Reg:V1 | vperm 0, 6, 0, 1	
  #|0x1006f104	VSLB Reg:V0 Reg:V6 Reg:V30 | vslb 0, 6, 30	
  #|0x1007014c	VMRGLH Reg:V0 Reg:V7 Reg:V0 | vmrglh 0, 7, 0	
  #|0x10075848	VMULOUH Reg:V0 Reg:V7 Reg:V11 | vmulouh 0, 7, 11	
  #|0x10077e02	VNEGD Reg:V0 Reg:V15 | vnegd 0, 15	
  #|0x10079f88	VSUMSWS Reg:V0 Reg:V7 Reg:V19 | vsumsws 0, 7, 19	
  #|0x1007a342	VMINSH Reg:V0 Reg:V7 Reg:V20 | vminsh 0, 7, 20	
  #|0x1007b93e	VSUBEUQM Reg:V0 Reg:V7 Reg:V23 Reg:V4 | vsubeuqm 0, 7, 23, 4	
  #|0x10080602	VPRTYBW Reg:V0 Reg:V0 | vprtybw 0, 0	
  #|0x100819c7	VCMPEQUQ Reg:V0 Reg:V8 Reg:V3 | vcmpequq 0, 8, 3	
  #|0x10082a02	VMINUB Reg:V0 Reg:V8 Reg:V5 | vminub 0, 8, 5	
  #|0x10083907	VCMPNEZB Reg:V0 Reg:V8 Reg:V7 | vcmpnezb 0, 8, 7	
  #|0x1008f940	VADDCUQ Reg:V0 Reg:V8 Reg:V31 | vaddcuq 0, 8, 31	
  #|0x10090148	VMULOSH Reg:V0 Reg:V9 Reg:V0 | vmulosh 0, 9, 0	
  #|0x100a0cc8	VPMSUMD Reg:V0 Reg:V10 Reg:V1 | vpmsumd 0, 10, 1	
  #|0x100a7f0b	VMODSQ Reg:V0 Reg:V10 Reg:V15 | vmodsq 0, 10, 15	
  #|0x100a9c43	VABSDUH Reg:V0 Reg:V10 Reg:V19 | vabsduh 0, 10, 19	
  #|0x100ae84f	VINSHVLX Reg:V0 Reg:V0 Reg:R10 Reg:V29 | vinshvlx 0, 10, 29	
  #|0x100b0795	MTVSRBMI Reg:V0 Imm:1943 | mtvsrbmi 0, 1943	
  #|0x100b0e42	VEXTRACTDM Reg:R0 Reg:V1 | vextractdm 0, 1	
  #|0x100b8384	VSRAW Reg:V0 Reg:V11 Reg:V16 | vsraw 0, 11, 16	
  #|0x100c0000	VADDUBM Reg:V0 Reg:V12 Reg:V0 | vaddubm 0, 12, 0	
  #|0x100c0082	VMAXUW Reg:V0 Reg:V12 Reg:V0 | vmaxuw 0, 12, 0	
  #|0x100c3e42	VEXTRACTQM Reg:R0 Reg:V7 | vextractqm 0, 7	
  #|0x100c9102	VMAXSB Reg:V0 Reg:V12 Reg:V18 | vmaxsb 0, 12, 18	
  #|0x100cbc88	VPMSUMW Reg:V0 Reg:V12 Reg:V23 | vpmsumw 0, 12, 23	
  #|0x100d4147	VCMPNEZH Reg:V0 Reg:V13 Reg:V8 | vcmpnezh 0, 13, 8	
  #|0x100d6e06	VCMPGTUB_rec Reg:V0 Reg:V13 Reg:V13 | vcmpgtub. 0, 13, 13	
  #|0x100df708	VSUM4SBS Reg:V0 Reg:V13 Reg:V30 | vsum4sbs 0, 13, 30	
  #|0x100e0007	VCMPNEB Reg:V0 Reg:V14 Reg:V0 | vcmpneb 0, 14, 0	
  #|0x100fae00	VSUBUBS Reg:V0 Reg:V15 Reg:V21 | vsububs 0, 15, 21	
  #|0x10109d8d	VPEXTD Reg:V0 Reg:V16 Reg:V19 | vpextd 0, 16, 19	
  #|0x1010f18f	VINSWVRX Reg:V0 Reg:V0 Reg:R16 Reg:V30 | vinswvrx 0, 16, 30	
  #|0x10110642	MTVSRHM Reg:V0 Reg:X0 | mtvsrhm 0, 0	
  #|0x10111680	VSUBUWS Reg:V0 Reg:V17 Reg:V2 | vsubuws 0, 17, 2	
  #|0x1011d602	VEXTSH2W Reg:V0 Reg:V26 | vextsh2w 0, 26	
  #|0x10120441	BCDSUB_rec Reg:V0 Reg:V18 Reg:V0 Imm:0 | bcdsub. 0, 18, 0, 0	
  #|0x10124a05	VSRQ Reg:V0 Reg:V18 Reg:V9 | vsrq 0, 18, 9	
  #|0x10127e42	MTVSRWM Reg:V0 Reg:X15 | mtvsrwm 0, 15	
  #|0x1012c648	VSUM4SHS Reg:V0 Reg:V18 Reg:V24 | vsum4shs 0, 18, 24	
  #|0x1012f684	VEQV Reg:V0 Reg:V18 Reg:V30 | veqv 0, 18, 30	
  #|0x1013f11d	VEXTDUWVRX Reg:V0 Reg:V19 Reg:V30 Reg:R4 | vextduwvrx 0, 19, 30, 4	
  #|0x10140642	MTVSRQM Reg:V0 Reg:X0 | mtvsrqm 0, 0	
  #|0x10160746	VCMPGTSH_rec Reg:V0 Reg:V22 Reg:V0 | vcmpgtsh. 0, 22, 0	
  #|0x101651c8	VMULOSD Reg:V0 Reg:V22 Reg:V10 | vmulosd 0, 22, 10	
  #|0x1016d6bc	VADDEUQM Reg:V0 Reg:V22 Reg:V26 Reg:V26 | vaddeuqm 0, 22, 26, 26	
  #|0x1016db08	VMULESB Reg:V0 Reg:V22 Reg:V27 | vmulesb 0, 22, 27	
  #|0x10170085	VRLWMI Reg:V0 Reg:V23 Reg:V0 Reg:V0 | vrlwmi 0, 23, 0	
  #|0x10170182	VMAXSW Reg:V0 Reg:V23 Reg:V0 | vmaxsw 0, 23, 0	
  #|0x1017e40a	VMAXFP Reg:V0 Reg:V23 Reg:V28 | vmaxfp 0, 23, 28	
  #|0x1017f10b	VDIVSQ Reg:V0 Reg:V23 Reg:V30 | vdivsq 0, 23, 30	
  #|0x10182401	BCDADD_rec Reg:V0 Reg:V24 Reg:V4 Imm:0 | bcdadd. 0, 24, 4, 0	
  #|0x1018c60b	VMODUQ Reg:V0 Reg:V24 Reg:V24 | vmoduq 0, 24, 24	
  #|0x1018e4df	VEXTDDVRX Reg:V0 Reg:V24 Reg:V28 Reg:R19 | vextddvrx 0, 24, 28, 19	
  #|0x101a0088	VMULOUW Reg:V0 Reg:V26 Reg:V0 | vmulouw 0, 26, 0	
  #|0x101a03c9	VMULHSD Reg:V0 Reg:V26 Reg:V0 | vmulhsd 0, 26, 0	
  #|0x101a03ed	VPERMXOR Reg:V0 Reg:V26 Reg:V0 Reg:V15 | vpermxor 0, 26, 0, 15	
  #|0x101a5108	VMULOSB Reg:V0 Reg:V26 Reg:V10 | vmulosb 0, 26, 10	
  #|0x101b0047	VCMPNEH Reg:V0 Reg:V27 Reg:V0 | vcmpneh 0, 27, 0	
  #|0x101b0286	VCMPGTUW Reg:V0 Reg:V27 Reg:V0 | vcmpgtuw 0, 27, 0	
  #|0x101ba9ce	VPKSWSS Reg:V0 Reg:V27 Reg:V21 | vpkswss 0, 27, 21	
  #|0x101bbe42	VCNTMBH Reg:X0 Reg:V23 Imm:1 | vcntmbh 0, 23, 1	
  #|0x101bfa48	VMULEUH Reg:V0 Reg:V27 Reg:V31 | vmuleuh 0, 27, 31	
  #|0x101d05c7	VCMPEQUQ_rec Reg:V0 Reg:V29 Reg:V0 | vcmpequq. 0, 29, 0	
  #|0x101d4816	VSLDBI Reg:V0 Reg:V29 Reg:V9 Imm:0 | vsldbi 0, 29, 9, 0	
  #|0x101e0218	VEXTDUBVLX Reg:V0 Reg:V30 Reg:V0 Reg:R8 | vextdubvlx 0, 30, 0, 8	
  #|0x101e3d42	VAVGSH Reg:V0 Reg:V30 Reg:V7 | vavgsh 0, 30, 7	
  #|0x101e7086	VCMPEQUW Reg:V0 Reg:V30 Reg:V14 | vcmpequw 0, 30, 14	
  #|0x101ecac7	VCMPGTUD Reg:V0 Reg:V30 Reg:V25 | vcmpgtud 0, 30, 25	
  #|0x101eeacb	VDIVEUD Reg:V0 Reg:V30 Reg:V29 | vdiveud 0, 30, 29	
  #|0x101f000f	VINSBVLX Reg:V0 Reg:V0 Reg:R31 Reg:V0 | vinsbvlx 0, 31, 0	
  #|0x1020020d	VEXTRACTUB Reg:V1 Imm:0 Reg:V0 | vextractub 1, 0, 0	
  #|0x102006c4	VSRD Reg:V1 Reg:V0 Reg:V0 | vsrd 1, 0, 0	
  #|0x102007c2	VCLZD Reg:V1 Reg:V0 | vclzd 1, 0	
  #|0x10200a8e	VUPKLSB Reg:V1 Reg:V1 | vupklsb 1, 1	
  #|0x10200f42	VCLZH Reg:V1 Reg:V1 | vclzh 1, 1	
  #|0x10201284	VSRW Reg:V1 Reg:V0 Reg:V2 | vsrw 1, 0, 2	
  #|0x1020a4c7	VCMPEQUD_rec Reg:V1 Reg:V0 Reg:V20 | vcmpequd. 1, 0, 20	
  #|0x1020c20b	VDIVEUQ Reg:V1 Reg:V0 Reg:V24 | vdiveuq 1, 0, 24	
  #|0x1020ea00	VADDUBS Reg:V1 Reg:V0 Reg:V29 | vaddubs 1, 0, 29	
  #|0x1020f142	VMAXSH Reg:V1 Reg:V0 Reg:V30 | vmaxsh 1, 0, 30	
  #|0x10214022	VMLADDUHM Reg:V1 Reg:V1 Reg:V8 Reg:V0 | vmladduhm 1, 1, 8, 0	
  #|0x1022210f	VINSBVRX Reg:V1 Reg:V1 Reg:R2 Reg:V4 | vinsbvrx 1, 2, 4	
  #|0x10241c40	VSUBUHM Reg:V1 Reg:V4 Reg:V3 | vsubuhm 1, 4, 3	
  #|0x102a0584	VNAND Reg:V1 Reg:V10 Reg:V0 | vnand 1, 10, 0	
  #|0x102a0642	VEXTRACTWM Reg:R1 Reg:V0 | vextractwm 1, 0	
  #|0x102bd043	VUCMPRLN Reg:V1 Reg:V11 Reg:V26 | vucmprln 1, 11, 26	
  #|0x10340103	VUCMPRHH Reg:V1 Reg:V20 Reg:V0 | vucmprhh 1, 20, 0	
  #|0x103f0682	VSHASIGMAW Reg:V1 Reg:V31 Imm:0 Imm:0 | vshasigmaw 1, 31, 0, 0	
  #|0x1040018a	VEXPTEFP Reg:V2 Reg:V0 | vexptefp 2, 0	
  #|0x1040112e	VMADDFP Reg:V2 Reg:V0 Reg:V4 Reg:V2 | vmaddfp 2, 0, 4, 2	
  #|0x1040128c	VSPLTW Reg:V2 Imm:0 Reg:V2 | vspltw 2, 2, 0	
  #|0x10406768	VMSUMSHM Reg:V2 Reg:V0 Reg:V12 Reg:V29 | vmsumshm 2, 0, 12, 29	
  #|0x104071bf	VSUBECUQ Reg:V2 Reg:V0 Reg:V14 Reg:V6 | vsubecuq 2, 0, 14, 6	
  #|0x1040794a	VRSQRTEFP Reg:V2 Reg:V15 | vrsqrtefp 2, 15	
  #|0x1041038c	VSPLTISW Reg:V2 Imm:1 | vspltisw 2, 1	
  #|0x1042180a	VADDFP Reg:V2 Reg:V2 Reg:V3 | vaddfp 2, 2, 3	
  #|0x10421f8c	VMRGEW Reg:V2 Reg:V2 Reg:V3 | vmrgew 2, 2, 3	
  #|0x10463484	VOR Reg:V2 Reg:V6 Reg:V6 | vmr 2, 6	
  #|0x1048034c	VSPLTISH Reg:V2 Imm:8 | vspltish 2, 8	
  #|0x1055db46	VCMPGTSH Reg:V2 Reg:V21 Reg:V27 | vcmpgtsh 2, 21, 27	
  #|0x1060024e	VUPKHSH Reg:V3 Reg:V0 | vupkhsh 3, 0	
  #|0x10601b4a	VCFSX Reg:V3 Imm:0 Reg:V3 | vcfsx 3, 3, 0	
  #|0x10606703	VPOPCNTB Reg:V3 Reg:V12 | vpopcntb 3, 12	
  #|0x1060738b	VDIVESW Reg:V3 Reg:V0 Reg:V14 | vdivesw 3, 0, 14	
  #|0x1062122c	VSLDOI Reg:V3 Reg:V2 Reg:V2 Imm:8 | vsldoi 3, 2, 2, 8	
  #|0x10625045	VRLQMI Reg:V3 Reg:V2 Reg:V10 Reg:V3 | vrlqmi 3, 2, 10	
  #|0x10671a0c	VSPLTB Reg:V3 Imm:7 Reg:V3 | vspltb 3, 3, 7	
  #|0x10684e42	VEXTRACTBM Reg:R3 Reg:V9 | vextractbm 3, 9	
  #|0x1071f20f	VINSBLX Reg:V3 Reg:V3 Reg:R17 Reg:R30 | vinsblx 3, 17, 30	
  #|0x10728a88	VMULEUW Reg:V3 Reg:V18 Reg:V17 | vmuleuw 3, 18, 17	
  #|0x10740f06	VCMPGTSB_rec Reg:V3 Reg:V20 Reg:V1 | vcmpgtsb. 3, 20, 1	
  #|0x10791e02	VEXTSH2D Reg:V3 Reg:V3 | vextsh2d 3, 3	
  #|0x107a0602	VEXTSW2D Reg:V3 Reg:V0 | vextsw2d 3, 0	
  #|0x10841244	VSRH Reg:V4 Reg:V4 Reg:V2 | vsrh 4, 4, 2	
  #|0x1084168d	VEXTUWLX Reg:X4 Reg:X4 Reg:V2 | vextuwlx 4, 4, 2	
  #|0x1084200e	VPKUHUM Reg:V4 Reg:V4 Reg:V4 | vpkuhum 4, 4, 4	
  #|0x10863084	VRLW Reg:V4 Reg:V6 Reg:V6 | vrlw 4, 6, 6	
  #|0x109a4487	VCMPNEW_rec Reg:V4 Reg:V26 Reg:V8 | vcmpnew. 4, 26, 8	
  #|0x109b4cb1	MADDHDU Reg:X4 Reg:X27 Reg:X9 Reg:X18 | maddhdu 4, 27, 9, 18	
  #|0x109d7dce	VPKSDSS Reg:V4 Reg:V29 Reg:V15 | vpksdss 4, 29, 15	
  #|0x10a002cd	VEXTRACTD Reg:V5 Imm:0 Reg:V0 | vextractd 5, 0, 0	
  #|0x10a00604	MFVSCR Reg:V5 | mfvscr 5	
  #|0x10a03f04	VSRV Reg:V5 Reg:V0 Reg:V7 | vsrv 5, 0, 7	
  #|0x10a06480	VSUBUWM Reg:V5 Reg:V0 Reg:V12 | vsubuwm 5, 0, 12	
  #|0x10a10144	VSLH Reg:V5 Reg:V1 Reg:V0 | vslh 5, 1, 0	
  #|0x10a51806	VCMPEQUB Reg:V5 Reg:V5 Reg:V3 | vcmpequb 5, 5, 3	
  #|0x10b20041	VMUL10ECUQ Reg:V5 Reg:V18 Reg:V0 | vmul10ecuq 5, 18, 0	
  #|0x10b399c6	VCMPGEFP Reg:V5 Reg:V19 Reg:V19 | vcmpgefp 5, 19, 19	
  #|0x10b98bc6	VCMPBFP Reg:V5 Reg:V25 Reg:V17 | vcmpbfp 5, 25, 17	
  #|0x10c00403	VABSDUB Reg:V6 Reg:V0 Reg:V0 | vabsdub 6, 0, 0	
  #|0x10c00f8b	VMODSW Reg:V6 Reg:V0 Reg:V1 | vmodsw 6, 0, 1	
  #|0x10c03f5c	VEXTDUWVLX Reg:V6 Reg:V0 Reg:V7 Reg:R29 | vextduwvlx 6, 0, 7, 29	
  #|0x10c05a87	VCMPGTUQ Reg:V6 Reg:V0 Reg:V11 | vcmpgtuq 6, 0, 11	
  #|0x10c30700	VSUBSBS Reg:V6 Reg:V3 Reg:V0 | vsubsbs 6, 3, 0	
  #|0x10c4c642	VEXPANDQM Reg:V6 Reg:V24 | vexpandqm 6, 24	
  #|0x10c8388c	VMRGHW Reg:V6 Reg:V8 Reg:V7 | vmrghw 6, 8, 7	
  #|0x10ca3ee0	VMHADDSHS Reg:V6 Reg:V10 Reg:V7 Reg:V27 | vmhaddshs 6, 10, 7, 27	
  #|0x10d1ce87	VCMPGTUQ_rec Reg:V6 Reg:V17 Reg:V25 | vcmpgtuq. 6, 17, 25	
  #|0x10d5cec1	BCDS_rec Reg:V6 Reg:V21 Reg:V25 Imm:1 | bcds. 6, 21, 25, 1	
  #|0x10dbfc84	VOR Reg:V6 Reg:V27 Reg:V31 | vor 6, 27, 31	
  #|0x10de2b89	VMULHSW Reg:V6 Reg:V30 Reg:V5 | vmulhsw 6, 30, 5	
  #|0x10e009cf	VINSD Reg:V7 Reg:V7 Imm:0 Reg:X1 | vinsd 7, 1, 0	
  #|0x10e038c2	VMAXUD Reg:V7 Reg:V0 Reg:V7 | vmaxud 7, 0, 7	
  #|0x10e55980	VADDCUW Reg:V7 Reg:V5 Reg:V11 | vaddcuw 7, 5, 11	
  #|0x10e70305	VSRAQ Reg:V7 Reg:V7 Reg:V0 | vsraq 7, 7, 0	
  #|0x10ebaec7	VCMPGTUD_rec Reg:V7 Reg:V11 Reg:V21 | vcmpgtud. 7, 11, 21	
  #|0x10ed480b	VDIVUQ Reg:V7 Reg:V13 Reg:V9 | vdivuq 7, 13, 9	
  #|0x10f61400	VSUBUBM Reg:V7 Reg:V22 Reg:V2 | vsububm 7, 22, 2	
  #|0x10f902d6	VSRDBI Reg:V7 Reg:V25 Reg:V0 Imm:3 | vsrdbi 7, 25, 0, 3	
  #|0x10fafd87	VCMPNEZW_rec Reg:V7 Reg:V26 Reg:V31 | vcmpnezw. 7, 26, 31	
  #|0x11005640	VSUBUHS Reg:V8 Reg:V0 Reg:V10 | vsubuhs 8, 0, 10	
  #|0x1100fd9e	VEXTDDVLX Reg:V8 Reg:V0 Reg:V31 Reg:R22 | vextddvlx 8, 0, 31, 22	
  #|0x110703cf	VINSDRX Reg:V8 Reg:V8 Reg:X7 Reg:X0 | vinsdrx 8, 7, 0	
  #|0x111102c2	VMINUD Reg:V8 Reg:V17 Reg:V0 | vminud 8, 17, 0	
  #|0x11180d01	BCDTRUNC_rec Reg:V8 Reg:V24 Reg:V1 Imm:0 | bcdtrunc. 8, 24, 1, 0	
  #|0x1118f8c8	VMULOUD Reg:V8 Reg:V24 Reg:V31 | vmuloud 8, 24, 31	
  #|0x11190e42	VCNTMBB Reg:X8 Reg:V1 Imm:1 | vcntmbb 8, 1, 1	
  #|0x1120480c	VMRGHB Reg:V9 Reg:V0 Reg:V9 | vmrghb 9, 0, 9	
  #|0x11209348	VMULESH Reg:V9 Reg:V0 Reg:V18 | vmulesh 9, 0, 18	
  #|0x1120d1ca	VLOGEFP Reg:V9 Reg:V26 | vlogefp 9, 26	
  #|0x11222642	VEXPANDWM Reg:V9 Reg:V4 | vexpandwm 9, 4	
  #|0x1123124f	VINSHLX Reg:V9 Reg:V9 Reg:R3 Reg:R2 | vinshlx 9, 3, 2	
  #|0x11270446	VCMPEQUH_rec Reg:V9 Reg:V7 Reg:V0 | vcmpequh. 9, 7, 0	
  #|0x11270c48	VPMSUMH Reg:V9 Reg:V7 Reg:V1 | vpmsumh 9, 7, 1	
  #|0x112a0580	VSUBCUW Reg:V9 Reg:V10 Reg:V0 | vsubcuw 9, 10, 0	
  #|0x11339642	MTVSRDM Reg:V9 Reg:X18 | mtvsrdm 9, 18	
  #|0x113e0602	VCTZW Reg:V9 Reg:V0 | vctzw 9, 0	
  #|0x1142534d	VINSERTH Reg:V10 Reg:V10 Imm:2 Reg:V10 | vinserth 10, 10, 2	
  #|0x11495602	VPRTYBD Reg:V10 Reg:V10 | vprtybd 10, 10	
  #|0x115f008b	VDIVUW Reg:V10 Reg:V31 Reg:V0 | vdivuw 10, 31, 0	
  #|0x1160024a	VRFIZ Reg:V11 Reg:V0 | vrfiz 11, 0	
  #|0x1160b00d	VSTRIBL Reg:V11 Reg:V22 | vstribl 11, 22	
  #|0x11629d81	BCDCFSQ_rec Reg:V11 Reg:V19 Imm:0 | bcdcfsq. 11, 19, 0	
  #|0x11640744	VSLV Reg:V11 Reg:V4 Reg:V0 | vslv 11, 4, 0	
  #|0x11685406	VCMPEQUB_rec Reg:V11 Reg:V8 Reg:V10 | vcmpequb. 11, 8, 10	
  #|0x11711486	VCMPEQUW_rec Reg:V11 Reg:V17 Reg:V2 | vcmpequw. 11, 17, 2	
  #|0x11720388	VMULESW Reg:V11 Reg:V18 Reg:V0 | vmulesw 11, 18, 0	
  #|0x117a6447	VCMPNEH_rec Reg:V11 Reg:V26 Reg:V12 | vcmpneh. 11, 26, 12	
  #|0x117d4988	VMULOSW Reg:V11 Reg:V29 Reg:V9 | vmulosw 11, 29, 9	
  #|0x117e0642	VCNTMBD Reg:X11 Reg:V0 Imm:0 | vcntmbd 11, 0, 0	
  #|0x11800444	VANDC Reg:V12 Reg:V0 Reg:V0 | vandc 12, 0, 0	
  #|0x11809ac6	VCMPGTFP Reg:V12 Reg:V0 Reg:V19 | vcmpgtfp 12, 0, 19	
  #|0x1181408f	VINSWVLX Reg:V12 Reg:V12 Reg:R1 Reg:V8 | vinswvlx 12, 1, 8	
  #|0x118400c4	VRLD Reg:V12 Reg:V4 Reg:V0 | vrld 12, 4, 0	
  #|0x11842d00	VSUBUQM Reg:V12 Reg:V4 Reg:V5 | vsubuqm 12, 4, 5	
  #|0x11944a89	VMULHUW Reg:V12 Reg:V20 Reg:V9 | vmulhuw 12, 20, 9	
  #|0x1195054d	VCFUGED Reg:V12 Reg:V21 Reg:V0 | vcfuged 12, 21, 0	
  #|0x11a0008e	VPKUHUS Reg:V13 Reg:V0 Reg:V0 | vpkuhus 13, 0, 0	
  #|0x11a02008	VMULOUB Reg:V13 Reg:V0 Reg:V4 | vmuloub 13, 0, 4	
  #|0x11a04a8d	VEXTRACTUW Reg:V13 Imm:0 Reg:V9 | vextractuw 13, 9, 0	
  #|0x11a0640c	VSLO Reg:V13 Reg:V0 Reg:V12 | vslo 13, 0, 12	
  #|0x11a08f83	VPOPCNTW Reg:V13 Reg:V17 | vpopcntw 13, 17	
  #|0x11a0f9c9	VMULLD Reg:V13 Reg:V0 Reg:V31 | vmulld 13, 0, 31	
  #|0x11a40046	VCMPEQUH Reg:V13 Reg:V4 Reg:V0 | vcmpequh 13, 4, 0	
  #|0x11a6854e	VPKSDUS Reg:V13 Reg:V6 Reg:V16 | vpksdus 13, 6, 16	
  #|0x11a74c83	VABSDUW Reg:V13 Reg:V7 Reg:V9 | vabsduw 13, 7, 9	
  #|0x11bb0602	VEXTSD2Q Reg:V13 Reg:V0 | vextsd2q 13, 0	
  #|0x11c00780	VSUBSWS Reg:V14 Reg:V0 Reg:V0 | vsubsws 14, 0, 0	
  #|0x11c0564e	VUPKHSW Reg:V14 Reg:V10 | vupkhsw 14, 10	
  #|0x11c05fc4	VCTZDM Reg:V14 Reg:V0 Reg:V11 | vctzdm 14, 0, 11	
  #|0x11dd05cd	VPDEPD Reg:V14 Reg:V29 Reg:V0 | vpdepd 14, 29, 0	
  #|0x11ddb84e	VPKUWUM Reg:V14 Reg:V29 Reg:V23 | vpkuwum 14, 29, 23	
  #|0x11e00161	VMHRADDSHS Reg:V15 Reg:V0 Reg:V0 Reg:V5 | vmhraddshs 15, 0, 0, 5	
  #|0x11e005c8	VSBOX Reg:V15 Reg:V0 | vsbox 15, 0	
  #|0x11e051c2	VMAXSD Reg:V15 Reg:V0 Reg:V10 | vmaxsd 15, 0, 10	
  #|0x11e50105	VSLQ Reg:V15 Reg:V5 Reg:V0 | vslq 15, 5, 0	
  #|0x11e64d81	BCDCFZ_rec Reg:V15 Reg:V9 Imm:0 | bcdcfz. 15, 9, 0	
  #|0x11e72d81	BCDCFN_rec Reg:V15 Reg:V5 Imm:0 | bcdcfn. 15, 5, 0	
  #|0x11ea0602	VPRTYBQ Reg:V15 Reg:V0 | vprtybq 15, 0	
  #|0x11ed0300	VADDSBS Reg:V15 Reg:V13 Reg:V0 | vaddsbs 15, 13, 0	
  #|0x11ed3100	VADDUQM Reg:V15 Reg:V13 Reg:V6 | vadduqm 15, 13, 6	
  #|0x11ed3ec2	VSHASIGMAD Reg:V15 Reg:V13 Imm:0 Imm:7 | vshasigmad 15, 13, 0, 7	
  #|0x11f07642	MTVSRBM Reg:V15 Reg:X14 | mtvsrbm 15, 14	
  #|0x11f22ac8	VMULEUD Reg:V15 Reg:V18 Reg:V5 | vmuleud 15, 18, 5	
  #|0x11f50185	VRLWNM Reg:V15 Reg:V21 Reg:V0 | vrlwnm 15, 21, 0	
  #|0x11f5c509	VCIPHERLAST Reg:V15 Reg:V21 Reg:V24 | vcipherlast 15, 21, 24	
  #|0x11f6018b	VDIVSW Reg:V15 Reg:V22 Reg:V0 | vdivsw 15, 22, 0	
  #|0x11f60502	VAVGSB Reg:V15 Reg:V22 Reg:V0 | vavgsb 15, 22, 0	
  #|0x11f80602	VEXTSB2D Reg:V15 Reg:V0 | vextsb2d 15, 0	
  #|0x11f9c6cb	VMODUD Reg:V15 Reg:V25 Reg:V24 | vmodud 15, 25, 24	
  #|0x11fb9508	VCIPHER Reg:V15 Reg:V27 Reg:V18 | vcipher 15, 27, 18	
  #|0x11fc10c6	VCMPEQFP Reg:V15 Reg:V28 Reg:V2 | vcmpeqfp 15, 28, 2	
  #|0x11ff0581	BCDSETSGN_rec Reg:V15 Reg:V0 Imm:0 | bcdsetsgn. 15, 0, 0	
  #|0x120047cb	VMODSD Reg:V16 Reg:V0 Reg:V8 | vmodsd 16, 0, 8	
  #|0x1203044a	VMINFP Reg:V16 Reg:V3 Reg:V0 | vminfp 16, 3, 0	
  #|0x1219f141	VCMPSQ Reg:CR4 Reg:V25 Reg:V30 | vcmpsq 4, 25, 30	
  #|0x12200044	VRLH Reg:V17 Reg:V0 Reg:V0 | vrlh 17, 0, 0	
  #|0x122002ca	VRFIM Reg:V17 Reg:V0 | vrfim 17, 0	
  #|0x1220b8c5	VRLDMI Reg:V17 Reg:V0 Reg:V23 Reg:V17 | vrldmi 17, 0, 23	
  #|0x12227442	VAVGUH Reg:V17 Reg:V2 Reg:V14 | vavguh 17, 2, 14	
  #|0x12250581	BCDCTN_rec Reg:V17 Reg:V0 | bcdctn. 17, 0	
  #|0x1228d3c7	VCMPGTSD Reg:V17 Reg:V8 Reg:V26 | vcmpgtsd 17, 8, 26	
  #|0x12340267	VMSUMUHS Reg:V17 Reg:V20 Reg:V0 Reg:V9 | vmsumuhs 17, 20, 0, 9	
  #|0x123c04ce	VPKUDUS Reg:V17 Reg:V28 Reg:V0 | vpkudus 17, 28, 0	
  #|0x123f044c	VSRO Reg:V17 Reg:V31 Reg:V0 | vsro 17, 31, 0	
  #|0x12400282	VMINUW Reg:V18 Reg:V0 Reg:V0 | vminuw 18, 0, 0	
  #|0x12401840	VADDUHM Reg:V18 Reg:V0 Reg:V3 | vadduhm 18, 0, 3	
  #|0x12412e42	VEXPANDHM Reg:V18 Reg:V5 | vexpandhm 18, 5	
  #|0x124224cc	VGNB Reg:X18 Reg:V4 Imm:2 | vgnb 18, 4, 2	
  #|0x1243cbcb	VDIVESD Reg:V18 Reg:V3 Reg:V25 | vdivesd 18, 3, 25	
  #|0x1252010e	VPKSHUS Reg:V18 Reg:V18 Reg:V0 | vpkshus 18, 18, 0	
  #|0x12544404	VAND Reg:V18 Reg:V20 Reg:V8 | vand 18, 20, 8	
  #|0x1254ad44	VORC Reg:V18 Reg:V20 Reg:V21 | vorc 18, 20, 21	
  #|0x1259bf84	VCLZDM Reg:V18 Reg:V25 Reg:V23 | vclzdm 18, 25, 23	
  #|0x1260038d	VINSERTW Reg:V19 Imm:0 Reg:V0 | vinsertw 19, 0, 0	
  #|0x126020c7	VCMPEQUD Reg:V19 Reg:V0 Reg:V4 | vcmpequd 19, 0, 4	
  #|0x12602504	VNOR Reg:V19 Reg:V0 Reg:V4 | vnor 19, 0, 4	
  #|0x1260a24c	VSPLTH Reg:V19 Imm:0 Reg:V20 | vsplth 19, 20, 0	
  #|0x1260ba42	VMINUH Reg:V19 Reg:V0 Reg:V23 | vminuh 19, 0, 23	
  #|0x1260d097	VMSUMCUD Reg:V19 Reg:V0 Reg:V26 Reg:V2 | vmsumcud 19, 0, 26, 2	
  #|0x1260d382	VMINSW Reg:V19 Reg:V0 Reg:V26 | vminsw 19, 0, 26	
  #|0x12690642	VEXTRACTHM Reg:R19 Reg:V0 | vextracthm 19, 0	
  #|0x126c3b87	VCMPGTSQ Reg:V19 Reg:V12 Reg:V7 | vcmpgtsq 19, 12, 7	
  #|0x126dfa8b	VDIVEUW Reg:V19 Reg:V13 Reg:V31 | vdiveuw 19, 13, 31	
  #|0x12700602	VEXTSB2W Reg:V19 Reg:V0 | vextsb2w 19, 0	
  #|0x1270444e	VPKUDUM Reg:V19 Reg:V16 Reg:V8 | vpkudum 19, 16, 8	
  #|0x12720b8f	VINSWRX Reg:V19 Reg:V19 Reg:R18 Reg:R1 | vinswrx 19, 18, 1	
  #|0x12780563	VMSUMUDM Reg:V19 Reg:V24 Reg:V0 Reg:V21 | vmsumudm 19, 24, 0, 21	
  #|0x127f0602	VCTZD Reg:V19 Reg:V0 | vctzd 19, 0	
  #|0x1280030b	VDIVESQ Reg:V20 Reg:V0 Reg:V0 | vdivesq 20, 0, 0	
  #|0x12805e02	VCLZLSBB Reg:R20 Reg:V11 | vclzlsbb 20, 11	
  #|0x1280da8a	VRFIP Reg:V20 Reg:V27 | vrfip 20, 27	
  #|0x1280ecaf	VNMSUBFP Reg:V20 Reg:V0 Reg:V18 Reg:V29 | vnmsubfp 20, 0, 18, 29	
  #|0x12810602	VCTZLSBB Reg:R20 Reg:V0 | vctzlsbb 20, 0	
  #|0x128b0dcc	VBPERMD Reg:V20 Reg:V11 Reg:V1 | vbpermd 20, 11, 1	
  #|0x128d8e86	VCMPGTUW_rec Reg:V20 Reg:V13 Reg:V17 | vcmpgtuw. 20, 13, 17	
  #|0x129297c1	BCDSR_rec Reg:V20 Reg:V18 Reg:V18 Imm:1 | bcdsr. 20, 18, 18, 1	
  #|0x129e9cc0	VSUBUDM Reg:V20 Reg:V30 Reg:V19 | vsubudm 20, 30, 19	
  #|0x12a00204	VSRB Reg:V21 Reg:V0 Reg:V0 | vsrb 21, 0, 0	
  #|0x12a069c4	VSL Reg:V21 Reg:V0 Reg:V13 | vsl 21, 0, 13	
  #|0x12a0ed07	VCMPNEZB_rec Reg:V21 Reg:V0 Reg:V29 | vcmpnezb. 21, 0, 29	
  #|0x12a798cb	VDIVUD Reg:V21 Reg:V7 Reg:V19 | vdivud 21, 7, 19	
  #|0x12b66003	VUCMPRHN Reg:V21 Reg:V22 Reg:V12 | vucmprhn 21, 22, 12	
  #|0x12c003c4	VSRAD Reg:V22 Reg:V0 Reg:V0 | vsrad 22, 0, 0	
  #|0x12c005bb	VPERMR Reg:V22 Reg:V0 Reg:V0 Reg:V22 | vpermr 22, 0, 0, 22	
  #|0x12c0db86	VCMPGTSW Reg:V22 Reg:V0 Reg:V27 | vcmpgtsw 22, 0, 27	
  #|0x12c3dc81	BCDUS_rec Reg:V22 Reg:V3 Reg:V27 | bcdus. 22, 3, 27	
  #|0x12c60602	VNEGW Reg:V22 Reg:V0 | vnegw 22, 0	
  #|0x12cdc18d	VCLRLB Reg:V22 Reg:V13 Reg:R24 | vclrlb 22, 13, 24	
  #|0x12d7d1a4	VMSUMUBM Reg:V22 Reg:V23 Reg:V26 Reg:V6 | vmsumubm 22, 23, 26, 6	
  #|0x12e006f3	MADDLD Reg:R23 Reg:R0 Reg:R0 Reg:R27 | maddld 23, 0, 0, 27	
  #|0x12e0cdc6	VCMPGEFP_rec Reg:V23 Reg:V0 Reg:V25 | vcmpgefp. 23, 0, 25	
  #|0x12e201cd	VCLRRB Reg:V23 Reg:V2 Reg:R0 | vclrrb 23, 2, 0	
  #|0x12e31642	VEXPANDDM Reg:V23 Reg:V2 | vexpanddm 23, 2	
  #|0x12eb7b06	VCMPGTSB Reg:V23 Reg:V11 Reg:V15 | vcmpgtsb 23, 11, 15	
  #|0x12ee4bc8	VMULESD Reg:V23 Reg:V14 Reg:V9 | vmulesd 23, 14, 9	
  #|0x12f2eb04	VSRAB Reg:V23 Reg:V18 Reg:V29 | vsrab 23, 18, 29	
  #|0x1300071a	VEXTDUHVLX Reg:V24 Reg:V0 Reg:V0 Reg:R28 | vextduhvlx 24, 0, 0, 28	
  #|0x1300a143	VUCMPRLH Reg:V24 Reg:V0 Reg:V20 | vucmprlh 24, 0, 20	
  #|0x13077b0a	VCFUX Reg:V24 Imm:7 Reg:V15 | vcfux 24, 15, 7	
  #|0x13120688	VSUM2SWS Reg:V24 Reg:V18 Reg:V0 | vsum2sws 24, 18, 0	
  #|0x131761c5	VRLDNM Reg:V24 Reg:V23 Reg:V12 | vrldnm 24, 23, 12	
  #|0x1318b67d	VADDECUQ Reg:V24 Reg:V24 Reg:V22 Reg:V25 | vaddecuq 24, 24, 22, 25	
  #|0x131a7b80	VADDSWS Reg:V24 Reg:V26 Reg:V15 | vaddsws 24, 26, 15	
  #|0x1320078d	VEXTUWRX Reg:X25 Reg:X0 Reg:V0 | vextuwrx 25, 0, 0	
  #|0x13202581	BCDCTSQ_rec Reg:V25 Reg:V4 | bcdctsq. 25, 4	
  #|0x1320cf86	VCMPGTSW_rec Reg:V25 Reg:V0 Reg:V25 | vcmpgtsw. 25, 0, 25	
  #|0x132d0549	VNCIPHERLAST Reg:V25 Reg:V13 Reg:V0 | vncipherlast 25, 13, 0	
  #|0x13300087	VCMPNEW Reg:V25 Reg:V16 Reg:V0 | vcmpnew 25, 16, 0	
  #|0x133c0dc4	VSLD Reg:V25 Reg:V28 Reg:V1 | vsld 25, 28, 1	
  #|0x133efb02	VMINSB Reg:V25 Reg:V30 Reg:V31 | vminsb 25, 30, 31	
  #|0x13400241	VMUL10EUQ Reg:V26 Reg:V0 Reg:V0 | vmul10euq 26, 0, 0	
  #|0x13406fc3	VPOPCNTD Reg:V26 Reg:V13 | vpopcntd 26, 13	
  #|0x1343b089	VMULUWM Reg:V26 Reg:V3 Reg:V22 | vmuluwm 26, 3, 22	
  #|0x134c7b8a	VCTUXS Reg:V26 Imm:12 Reg:V15 | vctuxs 26, 15, 12	
  #|0x1354ea06	VCMPGTUB Reg:V26 Reg:V20 Reg:V29 | vcmpgtub 26, 20, 29	
  #|0x1360aac9	VMULHUD Reg:V27 Reg:V0 Reg:V21 | vmulhud 27, 0, 21	
  #|0x13620740	VSUBSHS Reg:V27 Reg:V2 Reg:V0 | vsubshs 27, 2, 0	
  #|0x13634a8f	VINSWLX Reg:V27 Reg:V27 Reg:R3 Reg:R9 | vinswlx 27, 3, 9	
  #|0x136b004c	VMRGHH Reg:V27 Reg:V11 Reg:V0 | vmrghh 27, 11, 0	
  #|0x13780646	VCMPGTUH_rec Reg:V27 Reg:V24 Reg:V0 | vcmpgtuh. 27, 24, 0	
  #|0x1378dd40	VSUBCUQ Reg:V27 Reg:V24 Reg:V27 | vsubcuq 27, 24, 27	
  #|0x137dae42	VCNTMBW Reg:X27 Reg:V21 Imm:1 | vcntmbw 27, 21, 1	
  #|0x13800280	VADDUWS Reg:V28 Reg:V0 Reg:V0 | vadduws 28, 0, 0	
  #|0x13801083	VUCMPRHB Reg:V28 Reg:V0 Reg:V2 | vucmprhb 28, 0, 2	
  #|0x13801f0d	VEXTUBRX Reg:X28 Reg:X0 Reg:V3 | vextubrx 28, 0, 3	
  #|0x1380968b	VMODUW Reg:V28 Reg:V0 Reg:V18 | vmoduw 28, 0, 18	
  #|0x1380f805	VRLQ Reg:V28 Reg:V0 Reg:V31 | vrlq 28, 0, 31	
  #|0x1380f8cf	VINSW Reg:V28 Reg:V28 Imm:0 Reg:R31 | vinsw 28, 31, 0	
  #|0x1385004a	VSUBFP Reg:V28 Reg:V5 Reg:V0 | vsubfp 28, 5, 0	
  #|0x138b0042	VMAXUH Reg:V28 Reg:V11 Reg:V0 | vmaxuh 28, 11, 0	
  #|0x13910344	VSRAH Reg:V28 Reg:V17 Reg:V0 | vsrah 28, 17, 0	
  #|0x13942246	VCMPGTUH Reg:V28 Reg:V20 Reg:V4 | vcmpgtuh 28, 20, 4	
  #|0x13990002	VMAXUB Reg:V28 Reg:V25 Reg:V0 | vmaxub 28, 25, 0	
  #|0x1399a94f	VINSHVRX Reg:V28 Reg:V28 Reg:R25 Reg:V21 | vinshvrx 28, 25, 21	
  #|0x13a0030e	VPKPX Reg:V29 Reg:V0 Reg:V0 | vpkpx 29, 0, 0	
  #|0x13a003cd	VINSERTD Reg:V29 Imm:0 Reg:V0 | vinsertd 29, 0, 0	
  #|0x13a30326	VMSUMUHM Reg:V29 Reg:V3 Reg:V0 Reg:V12 | vmsumuhm 29, 3, 0, 12	
  #|0x13a6030d	VINSERTB Reg:V29 Reg:V29 Imm:6 Reg:V0 | vinsertb 29, 0, 6	
  #|0x13aa014e	VPKSWUS Reg:V29 Reg:V10 Reg:V0 | vpkswus 29, 10, 0	
  #|0x13b19bca	VCTSXS Reg:V29 Imm:17 Reg:V19 | vctsxs 29, 19, 17	
  #|0x13bd6e02	VCTZH Reg:V29 Reg:V13 | vctzh 29, 13	
  #|0x13bf0201	VMUL10UQ Reg:V29 Reg:V31 | vmul10uq 29, 31	
  #|0x13c00001	VMUL10CUQ Reg:V30 Reg:V0 | vmul10cuq 30, 0	
  #|0x13c03804	VRLB Reg:V30 Reg:V0 Reg:V7 | vrlb 30, 0, 7	
  #|0x13c04d82	VAVGSW Reg:V30 Reg:V0 Reg:V9 | vavgsw 30, 0, 9	
  #|0x13c1440d	VSTRIBR_rec Reg:V30 Reg:V8 | vstribr. 30, 8	
  #|0x13c20240	VADDUHS Reg:V30 Reg:V2 Reg:V0 | vadduhs 30, 2, 0	
  #|0x13c2580d	VSTRIHL Reg:V30 Reg:V11 | vstrihl 30, 11	
  #|0x13d50187	VCMPNEZW Reg:V30 Reg:V21 Reg:V0 | vcmpnezw 30, 21, 0	
  #|0x13dc018c	VMRGLW Reg:V30 Reg:V28 Reg:V0 | vmrglw 30, 28, 0	
  #|0x13dce602	VCTZB Reg:V30 Reg:V28 | vctzb 30, 28	
  #|0x13e00548	VNCIPHER Reg:V31 Reg:V0 Reg:V0 | vncipher 31, 0, 0	
  #|0x13e08a0a	VRFIN Reg:V31 Reg:V17 | vrfin 31, 17	
  #|0x13e0f3ce	VUPKLPX Reg:V31 Reg:V30 | vupklpx 31, 30	
  #|0x13e71787	VCMPGTSQ_rec Reg:V31 Reg:V7 Reg:V2 | vcmpgtsq. 31, 7, 2	
  #|0x13e7ece9	VMSUMSHS Reg:V31 Reg:V7 Reg:V29 Reg:V19 | vmsumshs 31, 7, 29, 19	
  #|0x13ef034f	VINSHRX Reg:V31 Reg:V31 Reg:R15 Reg:R0 | vinshrx 31, 15, 0	
  #|0x13fb054c	VBPERMQ Reg:V31 Reg:V27 Reg:V0 | vbpermq 31, 27, 0	
  #|0x1af30000	LXVP Reg:VSRp27 Imm:0 Reg:R19 | lxvp 54, 0(19)	may_load
  #|0x1bc10001	STXVP Reg:VSRp15 Imm:0 Reg:R1 | stxvp 30, 0(1)	may_store
  #|0x44000002	SC Imm:0 | sc	
  #|0x44000841	SCV Imm:66 | scv 66	
  #|0x44000922	SC Imm:73 | sc 73	
  #|0x448bd001	SCV Imm:0 | scv 0	
  #|0x4c000024	RFID | rfid	
  #|0x4c00004c	RFMCI | rfmci	
  #|0x4c00004e	RFDI | rfdi	
  #|0x4c000064	RFI | rfi	
  #|0x4c000066	RFCI | rfci	
  #|0x4c00012c	ISYNC | isync	may_load,may_store
  #|0x4c000224	HRFID | hrfid	
  #|0x4c000244	ADDPCIS Reg:X0 Imm:576 | addpcis 0, 576	
  #|0x4c0002e4	STOP | stop	
  #|0x4c000364	NAP | nap	
  #|0x4e000004	ADDPCIS Reg:X16 Imm:0 | lnia 16	
  #|0x7c000088	TD Imm:0 Reg:X0 Reg:X0 | td 0, 0, 0	
  #|0x7c000090	SUBFUS Reg:X0 Reg:X0 Reg:X0 Imm:0 | subfus 0, 0, 0, 0	
  #|0x7c00012d	STWCX Reg:R0 Reg:ZERO Reg:R0 | stwcx. 0, 0, 0	may_store
  #|0x7c000136	BRW Reg:R0 Reg:R0 | brw 0, 0	
  #|0x7c0001fe	DCBTSTEP Reg:ZERO Reg:R0 Imm:0 | dcbtstep 0, 0, 0	
  #|0x7c000224	TLBIEL Reg:R0 | tlbiel 0	
  #|0x7c0002a4	SLBSYNC | slbsync	
  #|0x7c0002e4	TLBIA | tlbia	
  #|0x7c00035c	CLRBHRB | clrbhrb	
  #|0x7c000364	SLBIE Reg:R0 | slbie 0	
  #|0x7c0003ce	STVXL Reg:V0 Reg:ZERO Reg:R0 | stvxl 0, 0, 0	may_store
  #|0x7c0003e4	SLBIA | slbia	
  #|0x7c00046c	TLBSYNC | tlbsync	
  #|0x7c000480	MCRXRX Reg:CR0 | mcrxrx 0	
  #|0x7c0004ac	SYNC Imm:0 | sync	may_load,may_store
  #|0x7c00051d	TBEGIN Imm:0 | tbegin. 0	
  #|0x7c0005d5	ADDMEO_rec Reg:R0 Reg:R0 | addmeo. 0, 0	
  #|0x7c0005da	STXVPRLL Reg:VSRp0 Reg:ZERO Reg:X0 | stxvprll 0, 0, 0	may_store
  #|0x7c00068c	CP_ABORT | cpabort	
  #|0x7c0006ac	EnforceIEIO | eieio	
  #|0x7c0006ec	MSGSYNC | msgsync	
  #|0x7c0007d8	STXVB16X Reg:VSL0 Reg:ZERO Reg:R0 | stxvb16x 0, 0, 0	may_store
  #|0x7c0007dd	TRECHKPT | trechkpt.	may_load,may_store
  #|0x7c0007ec	DCBZ Reg:ZERO Reg:R0 | dcbz 0, 0	may_load,may_store
  #|0x7c0007fe	DCBZEP Reg:ZERO Reg:R0 | dcbzep 0, 0	
  #|0x7c0012e6	MFTB Reg:R0 Imm:64 | mftb 0, 64	
  #|0x7c001fae	STFIWX Reg:F0 Reg:ZERO Reg:R3 | stfiwx 0, 0, 3	may_store
  #|0x7c00206c	DCBST Reg:ZERO Reg:R4 | dcbst 0, 4	may_load,may_store
  #|0x7c0025ad	STHCX Reg:R0 Reg:ZERO Reg:R4 | sthcx. 0, 0, 4	may_store
  #|0x7c0028ac	DCBF Imm:0 Reg:ZERO Reg:R5 | dcbf 0, 5	may_load,may_store
  #|0x7c0028ce	LVX Reg:V0 Reg:ZERO Reg:R5 | lvx 0, 0, 5	may_load
  #|0x7c00319a	STXVRWX Reg:VSL0 Reg:ZERO Reg:R6 | stxvrwx 0, 0, 6	may_store
  #|0x7c003d6e	STFSUX Reg:ZERO Reg:F0 Reg:ZERO Reg:R7 | stfsux 0, 0, 7	may_store
  #|0x7c00400c	LVSL Reg:V0 Reg:ZERO Reg:R8 | lvsl 0, 0, 8	
  #|0x7c0043ac	DCBI Reg:ZERO Reg:R8 | dcbi 0, 8	may_load,may_store
  #|0x7c00596d	STQCX Reg:X0 Reg:ZERO Reg:R11 | stqcx. 0, 0, 11	may_store
  #|0x7c006008	TW Imm:0 Reg:R0 Reg:R12 | tw 0, 0, 12	
  #|0x7c006799	STXVD2X Reg:V0 Reg:ZERO Reg:R12 | stxvd2x 32, 0, 12	may_store
  #|0x7c006b9a	STXVPX Reg:VSRp0 Reg:ZERO Reg:R13 | stxvpx 0, 0, 13	may_store
  #|0x7c0071ec	DCBTST Imm:0 Reg:ZERO Reg:R14 | dcbtst 0, 14	may_load,may_store
  #|0x7c008752	DIVDEO Reg:X0 Reg:X0 Reg:X16 | divdeo 0, 0, 16	
  #|0x7c00afe4	TLBLI Reg:R21 | tlbli 21	
  #|0x7c00c0e9	LHARXL Reg:R0 Reg:ZERO Reg:R24 | lharx 0, 0, 24, 1	may_load
  #|0x7c00c15b	STXVRHX Reg:V0 Reg:ZERO Reg:R24 | stxvrhx 32, 0, 24	may_store
  #|0x7c00c27e	DCBTEP Reg:ZERO Reg:R24 Imm:0 | dcbtep 0, 0, 24	
  #|0x7c00c35a	STXVLL Reg:VSL0 Reg:ZERO Reg:X24 | stxvll 0, 0, 24	may_store
  #|0x7c00c5ec	DCBA Reg:ZERO Reg:R24 | dcba 0, 24	may_load,may_store
  #|0x7c00cef6	EXTSWSLI Reg:X0 Reg:X0 Imm:57 | extswsli 0, 0, 57	
  #|0x7c00d147	WRTEEI Imm:1 | wrteei 1	
  #|0x7c00daac	DST Imm:0 Reg:R0 Reg:R27 | dst 0, 27, 0	may_load,may_store
  #|0x7c00ea26	MTLPL Reg:R29 Reg:R0 | mtlpl 29, 0	
  #|0x7c00ecaa	LSWI Reg:R0 Reg:R0 Imm:29 | lswi 0, 0, 29	
  #|0x7c00f1c0	CMPEQB Reg:CR0 Reg:X0 Reg:X30 | cmpeqb 0, 0, 30	
  #|0x7c01018c	ICBLQ Imm:0 Reg:R1 Reg:R0 | icblq. 0, 1, 0	
  #|0x7c016a1a	LXVL Reg:VSL0 Reg:R1 Reg:X13 | lxvl 0, 1, 13	may_load
  #|0x7c020119	STXSIWX Reg:VF0 Reg:R2 Reg:R0 | stxsiwx 32, 2, 0	may_store
  #|0x7c0204ac	SYNCP10 Imm:0 Imm:2 | stcisync	
  #|0x7c0207be	ICBIEP Reg:R2 Reg:R0 | icbiep 2, 0	
  #|0x7c030066	MFVSRD Reg:X3 Reg:F0 | mffprd 3, 0	
  #|0x7c0300e6	MFVSRWZ Reg:R3 Reg:F0 | mffprwz 3, 0	
  #|0x7c030166	MTVSRD Reg:F0 Reg:X3 | mtfprd 0, 3	
  #|0x7c030180	CMPRB Reg:CR0 Imm:0 Reg:R3 Reg:R0 | cmprb 0, 0, 3, 0	
  #|0x7c0301a6	MTVSRWA Reg:F0 Reg:R3 | mtfprwa 0, 3	
  #|0x7c03069d	TABORTWCI Imm:0 Reg:R3 Imm:0 | tabortwci. 0, 3, 0	may_load,may_store
  #|0x7c03242e	LFSX Reg:F0 Reg:R3 Reg:R4 | lfsx 0, 3, 4	may_load
  #|0x7c0324ae	LFDX Reg:F0 Reg:R3 Reg:R4 | lfdx 0, 3, 4	may_load
  #|0x7c0324ee	LFDUX Reg:F0 Reg:R3 Reg:R3 Reg:R4 | lfdux 0, 3, 4	may_load
  #|0x7c0325ae	STFDX Reg:F0 Reg:R3 Reg:R4 | stfdx 0, 3, 4	may_store
  #|0x7c033a18	LXVX Reg:VSL0 Reg:R3 Reg:R7 | lxvx 0, 3, 7	may_load
  #|0x7c042c19	LXSSPX Reg:VF0 Reg:R4 Reg:R5 | lxsspx 32, 4, 5	may_load
  #|0x7c050524	HASHSTP Reg:R0 Imm:-512 Reg:R5 | hashstp 0, -512(5)	may_store
  #|0x7c068d99	STXSDX Reg:VF0 Reg:R6 Reg:R17 | stxsdx 32, 6, 17	may_store
  #|0x7c06f85a	LXVRHX Reg:VSL0 Reg:R6 Reg:R31 | lxvrhx 0, 6, 31	may_load
  #|0x7c0745ee	STFDUX Reg:R7 Reg:F0 Reg:R7 Reg:R8 | stfdux 0, 7, 8	may_store
  #|0x7c07aaec	DSTST Imm:0 Reg:R7 Reg:R21 | dstst 7, 21, 0	may_load,may_store
  #|0x7c080100	SETB Reg:R0 Reg:CR2 | setb 0, 2	
  #|0x7c090594	ADDZEO Reg:R0 Reg:R9 | addzeo 0, 9	
  #|0x7c0905d1	SUBFMEO_rec Reg:R0 Reg:R9 | subfmeo. 0, 9	
  #|0x7c090698	LXVD2X Reg:VSL0 Reg:R9 Reg:R0 | lxvd2x 0, 9, 0	may_load
  #|0x7c091f57	DIVWEO_rec Reg:R0 Reg:R9 Reg:R3 | divweo. 0, 9, 3	
  #|0x7c0a052e	STFSX Reg:F0 Reg:R10 Reg:R0 | stfsx 0, 10, 0	may_store
  #|0x7c0ae5d6	MULLWO Reg:R0 Reg:R10 Reg:R28 | mullwo 0, 10, 28	
  #|0x7c0c0299	LXVDSX Reg:V0 Reg:R12 Reg:R0 | lxvdsx 32, 12, 0	may_load
  #|0x7c0c0793	DIVDUO_rec Reg:X0 Reg:X12 Reg:X0 | divduo. 0, 12, 0	
  #|0x7c0c307e	DCBSTEP Reg:R12 Reg:R6 | dcbstep 12, 6	
  #|0x7c0d0234	CDTBCD Reg:R13 Reg:R0 | cdtbcd 13, 0	
  #|0x7c0d9ef5	EXTSWSLI_rec Reg:X13 Reg:X0 Imm:19 | extswsli. 13, 0, 19	
  #|0x7c0db0be	LBEPX Reg:R0 Reg:R13 Reg:R22 | lbepx 0, 13, 22	
  #|0x7c0e045a	LXVRLL Reg:VSL0 Reg:R14 Reg:X0 | lxvrll 0, 14, 0	may_load
  #|0x7c0ef5a5	HASHST Reg:R30 Imm:-256 Reg:R14 | hashst 30, -256(14)	may_store
  #|0x7c0ef624	TLBIVAX Reg:R14 Reg:R30 | tlbivax 14, 30	
  #|0x7c10075d	TRECLAIM Reg:R16 | treclaim. 16	may_load,may_store
  #|0x7c1024da	LXVPRLL Reg:VSRp0 Reg:R16 Reg:X4 | lxvprll 0, 16, 4	may_load
  #|0x7c103fd2	DIVDO Reg:X0 Reg:X16 Reg:X7 | divdo 0, 16, 7	
  #|0x7c106753	DIVDEO_rec Reg:X0 Reg:X16 Reg:X12 | divdeo. 0, 16, 12	
  #|0x7c10cf0d	CP_PASTE_rec Reg:R16 Reg:R25 Imm:0 | paste. 16, 25, 0	may_store
  #|0x7c12bb1a	STXVL Reg:VSL0 Reg:R18 Reg:X23 | stxvl 0, 18, 23	may_store
  #|0x7c12e964	MTMSRD Reg:R0 Imm:0 | mtmsrd 0	
  #|0x7c130659	LXVH8X Reg:V0 Reg:R19 Reg:R0 | lxvh8x 32, 19, 0	may_load
  #|0x7c131a2c	DCBT Imm:0 Reg:R19 Reg:R3 | dcbt 19, 3	may_load,may_store
  #|0x7c145106	WRTEE Reg:R0 | wrtee 0	
  #|0x7c150354	ADDEX Reg:R0 Reg:R21 Reg:R0 Imm:1 | addex 0, 21, 0, 1	
  #|0x7c1606ad	MBAR Imm:0 | mbar	
  #|0x7c16e792	DIVDUO Reg:X0 Reg:X22 Reg:X28 | divduo 0, 22, 28	
  #|0x7c170069	LBARXL Reg:R0 Reg:R23 Reg:R0 | lbarx 0, 23, 0, 1	may_load
  #|0x7c170098	LXSIWAX Reg:F0 Reg:R23 Reg:R0 | lxsiwax 0, 23, 0	may_load
  #|0x7c17a35b	STXVLL Reg:V0 Reg:R23 Reg:X20 | stxvll 32, 23, 20	may_store
  #|0x7c1851db	STXVRDX Reg:V0 Reg:R24 Reg:R10 | stxvrdx 32, 24, 10	may_store
  #|0x7c186ed9	LXVB16X Reg:V0 Reg:R24 Reg:R13 | lxvb16x 32, 24, 13	may_load
  #|0x7c18df8c	ICCCI Reg:R24 Reg:R27 | iccci 24, 27	
  #|0x7c19005b	LXVRHX Reg:V0 Reg:R25 Reg:R0 | lxvrhx 32, 25, 0	may_load
  #|0x7c19071d	TABORT Reg:R25 | tabort. 25	may_load,may_store
  #|0x7c1a538c	DCCCI Reg:R26 Reg:R10 | dccci 26, 10	
  #|0x7c1b05d4	ADDMEO Reg:R0 Reg:R27 | addmeo 0, 27	
  #|0x7c1b0759	STXVH8X Reg:V0 Reg:R27 Reg:R0 | stxvh8x 32, 27, 0	may_store
  #|0x7c1bffac	ICBI Reg:R27 Reg:R31 | icbi 27, 31	
  #|0x7c1c00e7	MFVSRWZ Reg:R28 Reg:VF0 | mfvsrwz 28, 32	
  #|0x7c1c00fe	DCBFEP Reg:R28 Reg:R0 | dcbfep 28, 0	
  #|0x7c1c05d0	SUBFMEO Reg:R0 Reg:R28 | subfmeo 0, 28	
  #|0x7c1ca614	ADD4O Reg:R0 Reg:R28 Reg:R20 | addo 0, 28, 20	
  #|0x7c1d421b	LXVL Reg:V0 Reg:R29 Reg:X8 | lxvl 32, 29, 8	may_load
  #|0x7c1e281a	LXVRBX Reg:VSL0 Reg:R30 Reg:R5 | lxvrbx 0, 30, 5	may_load
  #|0x7c1e605e	ISEL Reg:R0 Reg:R30 Reg:R12 Reg:CR0GT | iselgt 0, 30, 12	
  #|0x7c1eab3e	STHEPX Reg:R0 Reg:R30 Reg:R21 | sthepx 0, 30, 21	
  #|0x7c1f05d2	MULLDO Reg:X0 Reg:X31 Reg:X0 | mulldo 0, 31, 0	
  #|0x7c1f799b	STXVRWX Reg:V0 Reg:R31 Reg:R15 | stxvrwx 32, 31, 15	may_store
  #|0x7c1fa964	MTMSRD Reg:R0 Imm:1 | mtmsrd 0, 1	
  #|0x7c200008	TW Imm:1 Reg:R0 Reg:R0 | twlgt 0, 0	
  #|0x7c200088	TD Imm:1 Reg:X0 Reg:X0 | tdlgt 0, 0	
  #|0x7c2004ac	SYNC Imm:1 | lwsync	may_load,may_store
  #|0x7c2004d0	NEGO Reg:R1 Reg:R0 | nego 1, 0	
  #|0x7c20070d	CP_PASTE_rec Reg:R0 Reg:R0 Imm:1 | paste. 0, 0	may_store
  #|0x7c200c6e	LFSUX Reg:F1 Reg:ZERO Reg:ZERO Reg:R1 | lfsux 1, 0, 1	may_load
  #|0x7c2026ae	LFIWAX Reg:F1 Reg:ZERO Reg:R4 | lfiwax 1, 0, 4	may_load
  #|0x7c2026ee	LFIWZX Reg:F1 Reg:ZERO Reg:R4 | lfiwzx 1, 0, 4	may_load
  #|0x7c207fa7	SLBFEE_rec Reg:R1 Reg:R15 | slbfee. 1, 15	
  #|0x7c232b18	STXVX Reg:VSL1 Reg:R3 Reg:R5 | stxvx 1, 3, 5	may_store
  #|0x7c287808	TW Imm:1 Reg:R8 Reg:R15 | twlgt 8, 15	
  #|0x7c292888	TD Imm:1 Reg:X9 Reg:X5 | tdlgt 9, 5	
  #|0x7c2aa29a	LXVPX Reg:VSRp16 Reg:R10 Reg:R20 | lxvpx 32, 10, 20	may_load
  #|0x7c2e00ac	DCBF Imm:1 Reg:R14 Reg:R0 | dcbfl 14, 0	may_load,may_store
  #|0x7c360366	MTVSRDD Reg:VSL1 Reg:X22 Reg:X0 | mtvsrdd 1, 22, 0	
  #|0x7c3d07fe	DCBZLEP Reg:R29 Reg:R0 | dcbzlep 29, 0	
  #|0x7c3f07ec	DCBZL Reg:R31 Reg:R0 | dcbzl 31, 0	may_load,may_store
  #|0x7c400008	TW Imm:2 Reg:R0 Reg:R0 | twllt 0, 0	
  #|0x7c400088	TD Imm:2 Reg:X0 Reg:X0 | tdllt 0, 0	
  #|0x7c4004ac	SYNC Imm:2 | ptesync	may_load,may_store
  #|0x7c4029ce	STVX Reg:V2 Reg:ZERO Reg:R5 | stvx 2, 0, 5	may_store
  #|0x7c404f1b	STXSIBX Reg:VF2 Reg:ZERO Reg:R9 | stxsibx 34, 0, 9	may_store
  #|0x7c40b94e	STVEHX Reg:V2 Reg:ZERO Reg:R23 | stvehx 2, 0, 23	may_store
  #|0x7c450067	MFVSRD Reg:X5 Reg:VF2 | mfvsrd 5, 34	
  #|0x7c454367	MTVSRDD Reg:V2 Reg:X5 Reg:X8 | mtvsrdd 34, 5, 8	
  #|0x7c460327	MTVSRWS Reg:V2 Reg:R6 | mtvsrws 34, 6	
  #|0x7c49a008	TW Imm:2 Reg:R9 Reg:R20 | twllt 9, 20	
  #|0x7c4b0088	TD Imm:2 Reg:X11 Reg:X0 | tdllt 11, 0	
  #|0x7c4f0415	ADDCO_rec Reg:R2 Reg:R15 Reg:R0 | addco. 2, 15, 0	
  #|0x7c6004ac	SYNC Imm:3 | sync 3	may_load,may_store
  #|0x7c602019	LXSIWZX Reg:VF3 Reg:ZERO Reg:R4 | lxsiwzx 35, 0, 4	may_load
  #|0x7c630bcc	ICBTLS Imm:3 Reg:R3 Reg:R1 | icbtls 3, 3, 1	
  #|0x7c642c99	LXSDX Reg:VF3 Reg:R4 Reg:R5 | lxsdx 35, 4, 5	may_load
  #|0x7c6501e7	MTVSRWZ Reg:VF3 Reg:R5 | mtvsrwz 35, 5	
  #|0x7c6907d7	DIVWO_rec Reg:R3 Reg:R9 Reg:R0 | divwo. 3, 9, 0	
  #|0x7c6b04d1	NEGO_rec Reg:R3 Reg:R11 | nego. 3, 11	
  #|0x7c701026	MFOCRF Reg:R3 Reg:CR7 | mfocrf 3, 1	
  #|0x7c704120	MTOCRF Reg:CR5 Reg:R3 | mtocrf 4, 3	
  #|0x7c7090ac	DCBF Imm:3 Reg:R16 Reg:R18 | dcbflp 16, 18	may_load,may_store
  #|0x7c791068	LBARX Reg:R3 Reg:R25 Reg:R2 | lbarx 3, 25, 2	may_load
  #|0x7c800008	TW Imm:4 Reg:R0 Reg:R0 | tweq 0, 0	
  #|0x7c800088	TD Imm:4 Reg:X0 Reg:X0 | tdeq 0, 0	
  #|0x7c8000a9	LDARXL Reg:X4 Reg:ZERO Reg:R0 | ldarx 4, 0, 0, 1	may_load
  #|0x7c8004a8	PTESYNCIO Reg:X4 | ptesyncio 4	
  #|0x7c8004ac	SYNCP10 Imm:4 Imm:0 | phwsync	
  #|0x7c801c8c	LWAT Reg:X4 Reg:X4 Reg:ZERO Imm:3 | lwat 4, 0, 3	may_load,may_store
  #|0x7c80219e	ISEL Reg:R4 Reg:ZERO Reg:R4 Reg:CR1EQ | isel 4, 0, 4, 6	
  #|0x7c80e82c	ICBT Imm:4 Reg:ZERO Reg:R29 | icbt 4, 0, 29	may_load,may_store
  #|0x7c8200ac	DCBF Imm:4 Reg:R2 Reg:R0 | dcbfps 2, 0	may_load,may_store
  #|0x7c8be888	TD Imm:4 Reg:X11 Reg:X29 | tdeq 11, 29	
  #|0x7c94055a	STXVRLL Reg:VSL4 Reg:R20 Reg:X0 | stxvrll 4, 20, 0	may_store
  #|0x7c9a0008	TW Imm:4 Reg:R26 Reg:R0 | tweq 26, 0	
  #|0x7c9e5d26	MFSRIN Reg:R4 Reg:R11 | mfsrin 4, 11	
  #|0x7ca02ba4	SLBIEG Reg:R5 Reg:R5 | slbieg 5, 5	
  #|0x7ca0b23e	LHEPX Reg:R5 Reg:ZERO Reg:R22 | lhepx 5, 0, 22	
  #|0x7cac0274	CBCDTD Reg:R12 Reg:R5 | cbcdtd 12, 5	
  #|0x7cb8dca6	MFSR Reg:R5 Imm:8 | mfsr 5, 8	
  #|0x7cbba55b	STXVRLL Reg:V5 Reg:R27 Reg:X20 | stxvrll 37, 27, 20	may_store
  #|0x7cc104ac	SYNCP10 Imm:6 Imm:1 | sync 6, 1	
  #|0x7cc1d0ac	DCBF Imm:6 Reg:R1 Reg:R26 | dcbstps 1, 26	may_load,may_store
  #|0x7ce004ac	SYNCP10 Imm:7 Imm:0 | sync 7	
  #|0x7ce0129c	MFPMR Reg:R7 Imm:64 | mfpmr 7, 64	
  #|0x7ce078e8	LHARX Reg:R7 Reg:ZERO Reg:R15 | lharx 7, 0, 15	may_load
  #|0x7ce2a8ac	DCBF Imm:7 Reg:R2 Reg:R21 | dcbf 2, 21, 7	may_load,may_store
  #|0x7ce605be	STFDEPX Reg:F7 Reg:R6 Reg:R0 | stfdepx 7, 6, 0	
  #|0x7ce7281e	ISEL Reg:R7 Reg:R7 Reg:R5 Reg:CR0LT | isellt 7, 7, 5	
  #|0x7cec42e6	MFTB Reg:R7 Imm:268 | mftb 7, 268	
  #|0x7ceddd1a	STXVRL Reg:VSL7 Reg:R13 Reg:X27 | stxvrl 7, 13, 27	may_store
  #|0x7cfaff19	STXVW4X Reg:V7 Reg:R26 Reg:R31 | stxvw4x 39, 26, 31	may_store
  #|0x7cff06d8	LXVB16X Reg:VSL7 Reg:R31 Reg:R0 | lxvb16x 7, 31, 0	may_load
  #|0x7d000008	TW Imm:8 Reg:R0 Reg:R0 | twgt 0, 0	
  #|0x7d000088	TD Imm:8 Reg:X0 Reg:X0 | tdgt 0, 0	
  #|0x7d040176	BRD Reg:X4 Reg:X8 | brd 4, 8	
  #|0x7d0a0028	LWARX Reg:R8 Reg:R10 Reg:R0 | lwarx 8, 10, 0	may_load
  #|0x7d0c065b	LXSIHZX Reg:VF8 Reg:R12 Reg:R0 | lxsihzx 40, 12, 0	may_load
  #|0x7d0e031b	STXVL Reg:V8 Reg:R14 Reg:X0 | stxvl 40, 14, 0	may_store
  #|0x7d10e808	TW Imm:8 Reg:R16 Reg:R29 | twgt 16, 29	
  #|0x7d11c888	TD Imm:8 Reg:X17 Reg:X25 | tdgt 17, 25	
  #|0x7d13cde4	HASHCHK Reg:R25 Imm:-448 Reg:R19 | hashchk 25, -448(19)	may_load
  #|0x7d1606aa	LBZCIX Reg:R8 Reg:R22 Reg:R0 | lbzcix 8, 22, 0	
  #|0x7d1b3fda	STXVPB32X Reg:VSRp4 Reg:R27 Reg:X7 | stxvpb32x 8, 27, 7	may_store
  #|0x7d20bf97	DIVWUO_rec Reg:R9 Reg:R0 Reg:R23 | divwuo. 9, 0, 23	
  #|0x7d251410	SUBFCO Reg:R9 Reg:R5 Reg:R2 | subfco 9, 5, 2	
  #|0x7d2ccc76	CNTTZDM Reg:X12 Reg:X9 Reg:X25 | cnttzdm 12, 9, 25	
  #|0x7d3186dd	TABORTDCI Imm:9 Reg:R17 Imm:16 | tabortdci. 9, 17, 16	may_load,may_store
  #|0x7d3a49be	STBEPX Reg:R9 Reg:R26 Reg:R9 | stbepx 9, 26, 9	
  #|0x7d3c0326	MTVSRWS Reg:VSL9 Reg:R28 | mtvsrws 9, 28	
  #|0x7d400178	PEXTD Reg:X0 Reg:X10 Reg:X0 | pextd 0, 10, 0	
  #|0x7d40061b	LXSIBZX Reg:VF10 Reg:ZERO Reg:R0 | lxsibzx 42, 0, 0	may_load
  #|0x7d4019e4	MTSRIN Reg:R10 Reg:R3 | mtsrin 10, 3	
  #|0x7d42e899	LXSIWAX Reg:VF10 Reg:R2 Reg:R29 | lxsiwax 42, 2, 29	may_load
  #|0x7d496029	LWARXL Reg:R10 Reg:R9 Reg:R12 | lwarx 10, 9, 12, 1	may_load
  #|0x7d5506ac	MBAR Imm:10 | mbar 10	
  #|0x7d5f5319	STXVX Reg:V10 Reg:R31 Reg:R10 | stxvx 42, 31, 10	may_store
  #|0x7d600380	SETNBC Reg:R11 Reg:CR0LT | setnbc 11, 0	
  #|0x7d656138	PDEPD Reg:X5 Reg:X11 Reg:X12 | pdepd 5, 11, 12	
  #|0x7d6601a4	MTSR Reg:R11 Imm:6 | mtsr 6, 11	
  #|0x7d6b0c1a	LXVRL Reg:VSL11 Reg:R11 Reg:X1 | lxvrl 11, 11, 1	may_load
  #|0x7d6c7565	HASHCHKP Reg:R14 Imm:-168 Reg:R12 | hashchkp 14, -168(12)	may_load
  #|0x7d6cbfea	STDCIX Reg:R11 Reg:R12 Reg:R23 | stdcix 11, 12, 23	
  #|0x7d7b03c0	SETNBCR Reg:R11 Reg:CR6UN | setnbcr 11, 27	
  #|0x7d800595	ADDZEO_rec Reg:R12 Reg:R0 | addzeo. 12, 0	
  #|0x7d803498	LXSDX Reg:F12 Reg:ZERO Reg:R6 | lxsdx 12, 0, 6	may_load
  #|0x7d803d10	SUBFEO Reg:R12 Reg:R0 Reg:R7 | subfeo 12, 0, 7	
  #|0x7d8059cc	ICBLC Imm:12 Reg:ZERO Reg:R11 | icblc 12, 0, 11	
  #|0x7d882818	LXSIWZX Reg:F12 Reg:R8 Reg:R5 | lxsiwzx 12, 8, 5	may_load
  #|0x7d89061a	LXSIBZX Reg:F12 Reg:R9 Reg:R0 | lxsibzx 12, 9, 0	may_load
  #|0x7d8c12ce	LVXL Reg:V12 Reg:R12 Reg:R2 | lvxl 12, 12, 2	may_load
  #|0x7d92009e	ISEL Reg:R12 Reg:R18 Reg:R0 Reg:CR0EQ | iseleq 12, 18, 0	
  #|0x7d94061d	TABORTWC Imm:12 Reg:R20 Reg:R0 | tabortwc. 12, 20, 0	may_load,may_store
  #|0x7da0011b	STXVRBX Reg:V13 Reg:ZERO Reg:R0 | stxvrbx 45, 0, 0	may_store
  #|0x7da0a84e	LVEHX Reg:V13 Reg:ZERO Reg:R21 | lvehx 13, 0, 21	may_load
  #|0x7da356f7	EXTSWSLI_rec Reg:X3 Reg:X13 Imm:42 | extswsli. 3, 13, 42	
  #|0x7db1075b	STXSIHX Reg:VF13 Reg:R17 Reg:R0 | stxsihx 45, 17, 0	may_store
  #|0x7db4cad8	LXVWSX Reg:VSL13 Reg:R20 Reg:R25 | lxvwsx 13, 20, 25	may_load
  #|0x7db5065d	TABORTDC Imm:13 Reg:R21 Reg:R0 | tabortdc. 13, 21, 0	may_load,may_store
  #|0x7db65124	MTMSR Reg:R13 Imm:0 | mtmsr 13	may_load,may_store
  #|0x7db7ecbe	LFDEPX Reg:F13 Reg:R23 Reg:R29 | lfdepx 13, 23, 29	
  #|0x7dbc0167	MTVSRD Reg:VF13 Reg:X28 | mtvsrd 45, 28	
  #|0x7dc4380e	LVEBX Reg:V14 Reg:R4 Reg:R7 | lvebx 14, 4, 7	may_load
  #|0x7dd7051b	STXVRL Reg:V14 Reg:R23 Reg:X0 | stxvrl 46, 23, 0	may_store
  #|0x7de02e15	ADD4O_rec Reg:R15 Reg:R0 Reg:R5 | addo. 15, 0, 5	
  #|0x7de0a091	SUBFUS_rec Reg:X15 Reg:X0 Reg:X20 Imm:0 | subfus. 15, 0, 0, 20	
  #|0x7de0d088	TD Imm:15 Reg:X0 Reg:X26 | td 15, 0, 26	
  #|0x7de7eb9c	MTPMR Imm:935 Reg:R15 | mtpmr 935, 15	
  #|0x7de95fd6	DIVWO Reg:R15 Reg:R9 Reg:R11 | divwo 15, 9, 11	
  #|0x7df365aa	STSWI Reg:R15 Reg:R19 Imm:12 | stswi 15, 19, 12	
  #|0x7dfae713	DIVDEUO_rec Reg:X15 Reg:X26 Reg:X28 | divdeuo. 15, 26, 28	
  #|0x7dfd0124	MTMSR Reg:R15 Imm:1 | mtmsr 15, 1	may_load,may_store
  #|0x7e000008	TW Imm:16 Reg:R0 Reg:R0 | twlt 0, 0	
  #|0x7e000088	TD Imm:16 Reg:X0 Reg:X0 | tdlt 0, 0	
  #|0x7e0000f4	POPCNTB Reg:R0 Reg:R16 | popcntb 0, 16	
  #|0x7e00062a	LWZCIX Reg:R16 Reg:R0 Reg:R0 | lwzcix 16, 0, 0	
  #|0x7e0089ec	DCBTST Imm:16 Reg:ZERO Reg:R17 | dcbtstt 0, 17	may_load,may_store
  #|0x7e00b088	TD Imm:16 Reg:X0 Reg:X22 | tdlt 0, 22	
  #|0x7e0f022c	DCBT Imm:16 Reg:R15 Reg:R0 | dcbtt 15, 0	may_load,may_store
  #|0x7e100340	SETBCR Reg:R16 Reg:CR4LT | setbcr 16, 16	
  #|0x7e190008	TW Imm:16 Reg:R25 Reg:R0 | twlt 25, 0	
  #|0x7e209c11	SUBFCO_rec Reg:R17 Reg:R0 Reg:R19 | subfco. 17, 0, 19	
  #|0x7e24ff58	STXVH8X Reg:VSL17 Reg:R4 Reg:R31 | stxvh8x 17, 4, 31	may_store
  #|0x7e2502ac	DSTT Imm:1 Reg:R5 Reg:R0 | dstt 5, 0, 1	may_load,may_store
  #|0x7e2b0094	ADDG6S Reg:R17 Reg:R11 Reg:R0 | addg6s 17, 11, 0	
  #|0x7e2bc1ec	DCBTST Imm:17 Reg:R11 Reg:R24 | dcbtst 11, 24, 17	may_load,may_store
  #|0x7e2c0798	STXVD2X Reg:VSL17 Reg:R12 Reg:R0 | stxvd2x 17, 12, 0	may_store
  #|0x7e345796	DIVWUO Reg:R17 Reg:R20 Reg:R10 | divwuo 17, 20, 10	
  #|0x7e370300	SETBC Reg:R17 Reg:CR5UN | setbc 17, 23	
  #|0x7e4002ec	DSTSTT Imm:2 Reg:R0 Reg:R0 | dststt 0, 0, 2	may_load,may_store
  #|0x7e5ca90e	STVEBX Reg:V18 Reg:R28 Reg:R21 | stvebx 18, 28, 21	may_store
  #|0x7e600298	LXVDSX Reg:VSL19 Reg:ZERO Reg:R0 | lxvdsx 19, 0, 0	may_load
  #|0x7e600598	STXSDX Reg:F19 Reg:ZERO Reg:R0 | stxsdx 19, 0, 0	may_store
  #|0x7e606d11	SUBFEO_rec Reg:R19 Reg:R0 Reg:R13 | subfeo. 19, 0, 13	
  #|0x7e750451	SUBFO_rec Reg:R19 Reg:R21 Reg:R0 | subfo. 19, 21, 0	
  #|0x7e780590	SUBFZEO Reg:R19 Reg:R24 | subfzeo 19, 24	
  #|0x7e80059c	TCHECK Reg:CR5 | tcheck 5	
  #|0x7e8065cc	STDAT Reg:X20 Reg:X0 Imm:12 | stdat 20, 0, 12	may_store
  #|0x7e80cf18	STXVW4X Reg:VSL20 Reg:ZERO Reg:R25 | stxvw4x 20, 0, 25	may_store
  #|0x7e85541b	LXVRL Reg:V20 Reg:R5 Reg:X10 | lxvrl 52, 5, 10	may_load
  #|0x7e97913e	STWEPX Reg:R20 Reg:R23 Reg:R18 | stwepx 20, 23, 18	
  #|0x7e9c0591	SUBFZEO_rec Reg:R20 Reg:R28 | subfzeo. 20, 28	
  #|0x7ea00266	MFVSRLD Reg:X0 Reg:VSL21 | mfvsrld 0, 21	
  #|0x7ea005e6	DARN Reg:X21 Imm:0 | darn 21, 0	may_load,may_store
  #|0x7ea0425b	LXVLL Reg:V21 Reg:ZERO Reg:X8 | lxvll 53, 0, 8	may_load
  #|0x7ea20518	STXSSPX Reg:F21 Reg:R2 Reg:R0 | stxsspx 21, 2, 0	may_store
  #|0x7eb10717	DIVWEUO_rec Reg:R21 Reg:R17 Reg:R0 | divweuo. 21, 17, 0	
  #|0x7ec00008	TW Imm:22 Reg:R0 Reg:R0 | tw 22, 0, 0	
  #|0x7ec0015a	STXVRHX Reg:VSL22 Reg:ZERO Reg:R0 | stxvrhx 22, 0, 0	may_store
  #|0x7ec00876	CNTLZDM Reg:X0 Reg:X22 Reg:X1 | cntlzdm 0, 22, 1	
  #|0x7ec0172a	STWCIX Reg:R22 Reg:R0 Reg:R2 | stwcix 22, 0, 2	
  #|0x7ec09658	LXVH8X Reg:VSL22 Reg:ZERO Reg:R18 | lxvh8x 22, 0, 18	may_load
  #|0x7ec80414	ADDCO Reg:R22 Reg:R8 Reg:R0 | addco 22, 8, 0	
  #|0x7ecd056d	STBCX Reg:R22 Reg:R13 Reg:R0 | stbcx. 22, 13, 0	may_store
  #|0x7ecf804c	LVSR Reg:V22 Reg:R15 Reg:R16 | lvsr 22, 15, 16	
  #|0x7edc36da	LXVPB32X Reg:VSRp11 Reg:R28 Reg:X6 | lxvpb32x 22, 28, 6	may_load
  #|0x7ee0003e	LWEPX Reg:R23 Reg:ZERO Reg:R0 | lwepx 23, 0, 0	
  #|0x7ee000a6	MFMSR Reg:R23 | mfmsr 23	
  #|0x7ee0018e	STVEWX Reg:V23 Reg:ZERO Reg:R0 | stvewx 23, 0, 0	may_store
  #|0x7ee012d9	LXVWSX Reg:V23 Reg:ZERO Reg:R2 | lxvwsx 55, 0, 2	may_load
  #|0x7ee07f56	DIVWEO Reg:R23 Reg:R0 Reg:R15 | divweo 23, 0, 15	
  #|0x7ee0c45b	LXVRLL Reg:V23 Reg:ZERO Reg:X24 | lxvrll 55, 0, 24	may_load
  #|0x7ef90219	LXVX Reg:V23 Reg:R25 Reg:R0 | lxvx 55, 25, 0	may_load
  #|0x7efbba28	LQARX Reg:X23 Reg:R27 Reg:R23 | lqarx 23, 27, 23	may_load
  #|0x7efc01b8	CFUGED Reg:X28 Reg:X23 Reg:X0 | cfuged 28, 23, 0	
  #|0x7f000008	TW Imm:24 Reg:R0 Reg:R0 | twne 0, 0	
  #|0x7f000088	TD Imm:24 Reg:X0 Reg:X0 | tdne 0, 0	
  #|0x7f000468	TLBSYNCIO Reg:X24 | tlbsyncio 24	
  #|0x7f0007d3	DIVDO_rec Reg:X24 Reg:X0 Reg:X0 | divdo. 24, 0, 0	
  #|0x7f0048a8	LDARX Reg:X24 Reg:ZERO Reg:R9 | ldarx 24, 0, 9	may_load
  #|0x7f007088	TD Imm:24 Reg:X0 Reg:X14 | tdne 0, 14	
  #|0x7f00ae6a	LHZCIX Reg:R24 Reg:R0 Reg:R21 | lhzcix 24, 0, 21	
  #|0x7f00e324	SLBMTE Reg:R24 Reg:R28 | slbmte 24, 28	
  #|0x7f00ea5c	MFBHRBE Reg:R24 Imm:29 | mfbhrbe 24, 29	
  #|0x7f0c6808	TW Imm:24 Reg:R12 Reg:R13 | twne 12, 13	
  #|0x7f12465a	LXSIHZX Reg:F24 Reg:R18 Reg:R8 | lxsihzx 24, 18, 8	may_load
  #|0x7f14008e	LVEWX Reg:V24 Reg:R20 Reg:R0 | lvewx 24, 20, 0	may_load
  #|0x7f1f07aa	STBCIX Reg:R24 Reg:R31 Reg:R0 | stbcix 24, 31, 0	
  #|0x7f200726	SLBMFEE Reg:R25 Reg:R0 | slbmfee 25, 0	
  #|0x7f20d6a6	SLBMFEV Reg:R25 Reg:R26 | slbmfev 25, 26	
  #|0x7f20eccc	LDAT Reg:X25 Reg:X25 Reg:ZERO Imm:29 | ldat 25, 0, 29	may_load,may_store
  #|0x7f25309b	LXVRWX Reg:V25 Reg:R5 Reg:R6 | lxvrwx 57, 5, 6	may_load
  #|0x7f290418	LXSSPX Reg:F25 Reg:R9 Reg:R0 | lxsspx 25, 9, 0	may_load
  #|0x7f2f871a	STXSIBX Reg:F25 Reg:R15 Reg:R16 | stxsibx 25, 15, 16	may_store
  #|0x7f37001b	LXVRBX Reg:V25 Reg:R23 Reg:R0 | lxvrbx 57, 23, 0	may_load
  #|0x7f4000da	LXVRDX Reg:VSL26 Reg:ZERO Reg:R0 | lxvrdx 26, 0, 0	may_load
  #|0x7f4078db	LXVRDX Reg:V26 Reg:ZERO Reg:R15 | lxvrdx 58, 0, 15	may_load
  #|0x7f4a058c	STWAT Reg:R26 Reg:R10 Imm:0 | stwat 26, 10, 0	may_store
  #|0x7f4e4d14	ADDEO Reg:R26 Reg:R14 Reg:R9 | addeo 26, 14, 9	
  #|0x7f600d9a	STXVPRL Reg:VSRp29 Reg:ZERO Reg:X1 | stxvprl 58, 0, 1	may_store
  #|0x7f6027d9	STXVB16X Reg:V27 Reg:ZERO Reg:R4 | stxvb16x 59, 0, 4	may_store
  #|0x7f607dd3	MULLDO_rec Reg:X27 Reg:X0 Reg:X15 | mulldo. 27, 0, 15	
  #|0x7f60d76a	STHCIX Reg:R27 Reg:R0 Reg:R26 | sthcix 27, 0, 26	
  #|0x7f6101b6	BRH Reg:R1 Reg:R27 | brh 1, 27	
  #|0x7f6c0699	LXVD2X Reg:V27 Reg:R12 Reg:R0 | lxvd2x 59, 12, 0	may_load
  #|0x7f6f99da	STXVRDX Reg:VSL27 Reg:R15 Reg:R19 | stxvrdx 27, 15, 19	may_store
  #|0x7f787f12	DIVDEUO Reg:X27 Reg:X24 Reg:X15 | divdeuo 27, 24, 15	
  #|0x7f7d0618	LXVW4X Reg:VSL27 Reg:R29 Reg:R0 | lxvw4x 27, 29, 0	may_load
  #|0x7f7d8d15	ADDEO_rec Reg:R27 Reg:R29 Reg:R17 | addeo. 27, 29, 17	
  #|0x7f800450	SUBFO Reg:R28 Reg:R0 Reg:R0 | subfo 28, 0, 0	
  #|0x7f802e19	LXVW4X Reg:V28 Reg:ZERO Reg:R5 | lxvw4x 60, 0, 5	may_load
  #|0x7f840118	STXSIWX Reg:F28 Reg:R4 Reg:R0 | stxsiwx 28, 4, 0	may_store
  #|0x7f8d06f4	EXTSWSLI Reg:X13 Reg:X28 Imm:0 | extswsli 13, 28, 0	
  #|0x7fa001e6	MTVSRWZ Reg:F29 Reg:R0 | mtfprwz 29, 0	
  #|0x7fa24725	TLBSX2D Reg:R29 Reg:R2 Reg:R8 | tlbsx. 29, 2, 8	
  #|0x7fb4991a	STXVRBX Reg:VSL29 Reg:R20 Reg:R19 | stxvrbx 29, 20, 19	may_store
  #|0x7fba022c	DCBT Imm:29 Reg:R26 Reg:R0 | dcbt 26, 0, 29	may_load,may_store
  #|0x7fc001a7	MTVSRWA Reg:VF30 Reg:R0 | mtvsrwa 62, 0	
  #|0x7fc2075a	STXSIHX Reg:F30 Reg:R2 Reg:R0 | stxsihx 30, 2, 0	may_store
  #|0x7fc7a1ad	STDCX Reg:X30 Reg:R7 Reg:R20 | stdcx. 30, 7, 20	may_store
  #|0x7fd37519	STXSSPX Reg:VF30 Reg:R19 Reg:R14 | stxsspx 62, 19, 14	may_store
  #|0x7fdb8dd7	MULLWO_rec Reg:R30 Reg:R27 Reg:R17 | mullwo. 30, 27, 17	
  #|0x7fe00008	TRAP | trap	
  #|0x7fe00088	TD Imm:31 Reg:X0 Reg:X0 | tdu 0, 0	
  #|0x7fe00267	MFVSRLD Reg:X0 Reg:V31 | mfvsrld 0, 63	
  #|0x7fe05f16	DIVWEUO Reg:R31 Reg:R0 Reg:R11 | divweuo 31, 0, 11	
  #|0x7fe0aa29	LQARXL Reg:X31 Reg:ZERO Reg:R21 | lqarx 31, 0, 21, 1	may_load
  #|0x7fe5c008	TW Imm:31 Reg:R5 Reg:R24 | twu 5, 24	
  #|0x7ff006ea	LDCIX Reg:R31 Reg:R16 Reg:R0 | ldcix 31, 16, 0	
  #|0x7ff10088	TD Imm:31 Reg:X17 Reg:X0 | tdu 17, 0	
  #|0x7ff5009a	LXVRWX Reg:VSL31 Reg:R21 Reg:R0 | lxvrwx 31, 21, 0	may_load
  #|0x7ff5049a	LXVPRL Reg:VSRp31 Reg:R21 Reg:X0 | lxvprl 62, 21, 0	may_load
  #|0x7ffe825a	LXVLL Reg:VSL31 Reg:R30 Reg:X16 | lxvll 31, 30, 16	may_load
  #|0xb8e03ffd	LMW Reg:R7 Imm:16381 Reg:ZERO | lmw 7, 16381(0)	may_load
  #|0xbd400000	STMW Reg:R10 Imm:0 Reg:ZERO | stmw 10, 0(0)	may_store
  #|0xc0010084	LFS Reg:F0 Imm:132 Reg:R1 | lfs 0, 132(1)	may_load
  #|0xc4030004	LFSU Reg:F0 Reg:R3 Imm:4 Reg:R3 | lfsu 0, 4(3)	may_load
  #|0xc8010010	LFD Reg:F0 Imm:16 Reg:R1 | lfd 0, 16(1)	may_load
  #|0xcc030008	LFDU Reg:F0 Reg:R3 Imm:8 Reg:R3 | lfdu 0, 8(3)	may_load
  #|0xd0010078	STFS Reg:F0 Imm:120 Reg:R1 | stfs 0, 120(1)	may_store
  #|0xd4030004	STFSU Reg:R3 Reg:F0 Imm:4 Reg:R3 | stfsu 0, 4(3)	may_store
  #|0xd8010008	STFD Reg:F0 Imm:8 Reg:R1 | stfd 0, 8(1)	may_store
  #|0xdc030008	STFDU Reg:R3 Reg:F0 Imm:8 Reg:R3 | stfdu 0, 8(3)	may_store
  #|0xe1606140	LQ Reg:X11 Imm:24896 Reg:ZERO | lq 11, 24896(0)	may_load
  #|0xe4480002	LXSD Reg:VF2 Imm:0 Reg:R8 | lxsd 2, 0(8)	may_load
  #|0xe5c142af	LXSSP Reg:VF14 Imm:17068 Reg:R1 | lxssp 14, 17068(1)	may_load
  #|0xec000010	XVI8GER4PP Reg:ACC0 Reg:ACC0 Reg:VSL0 Reg:VSL0 | xvi8ger4pp 0, 0, 0	
  #|0xec000028	FSUBS Reg:F0 Reg:F0 Reg:F0 | fsubs 0, 0, 0	
  #|0xec000032	FMULS Reg:F0 Reg:F0 Reg:F0 | fmuls 0, 0, 0	
  #|0xec000154	XVI16GER2SPP Reg:ACC0 Reg:ACC0 Reg:V0 Reg:VSL0 | xvi16ger2spp 0, 32, 0	
  #|0xec00019a	XVBF16GER2 Reg:ACC0 Reg:VSL0 Reg:V0 | xvbf16ger2 0, 0, 32	
  #|0xec00019e	XVBF16GER2 Reg:ACC0 Reg:V0 Reg:V0 | xvbf16ger2 0, 32, 32	
  #|0xec00028b	XXMULMULLOADD Reg:V0 Reg:VSL0 Reg:V0 Imm:1 Imm:0 | xxmulmulloadd 32, 0, 32, 1, 0	
  #|0xec00028f	XXMULMULLOADD Reg:V0 Reg:V0 Reg:V0 Imm:1 Imm:0 | xxmulmulloadd 32, 32, 32, 1, 0	
  #|0xec0002c4	DXEX Reg:F0 Reg:F0 | dxex 0, 0	
  #|0xec0002d0	XVF32GERNP Reg:ACC0 Reg:ACC0 Reg:VSL0 Reg:VSL0 | xvf32gernp 0, 0, 0	
  #|0xec000396	XVBF16GER2NP Reg:ACC0 Reg:ACC0 Reg:V0 Reg:V0 | xvbf16ger2np 0, 32, 32	
  #|0xec00048e	XSREBASE2T1UQM Reg:VSL0 Reg:V0 Reg:V0 | xsrebase2t1uqm 0, 32, 32	
  #|0xec000546	DTSTSFI Reg:CR0 Imm:0 Reg:F0 | dtstsfi 0, 0, 0	
  #|0xec0005cc	XXSSUMUDMC Reg:VSL0 Reg:V0 Reg:VSL0 Imm:1 | xxssumudmc 0, 32, 0, 1	
  #|0xec000741	XSMERGE2T1UQM Reg:V0 Reg:VSL0 Reg:VSL0 | xsmerge2t1uqm 32, 0, 0	
  #|0xec000781	XSMERGE2T2UQM Reg:V0 Reg:VSL0 Reg:VSL0 | xsmerge2t2uqm 32, 0, 0	
  #|0xec000824	FDIVS Reg:F0 Reg:F0 Reg:F1 | fdivs 0, 0, 1	
  #|0xec00082a	FADDS Reg:F0 Reg:F0 Reg:F1 | fadds 0, 0, 1	
  #|0xec000dc6	DRINTN Reg:F0 Imm:0 Reg:F1 Imm:2 | drintn 0, 0, 1, 2	
  #|0xec00107a	FMADDS Reg:F0 Reg:F0 Reg:F1 Reg:F2 | fmadds 0, 0, 1, 2	
  #|0xec002604	DRSP Reg:F0 Reg:F4 | drsp 0, 4	
  #|0xec002a44	DCTFIX Reg:F0 Reg:F5 | dctfix 0, 5	
  #|0xec002d8d	XSREBASE2T2UQM Reg:V0 Reg:V0 Reg:VSL5 | xsrebase2t2uqm 32, 32, 5	
  #|0xec002f05	XSADDSUBSUQM Reg:V0 Reg:V0 Reg:VSL5 | xsaddsubsuqm 32, 32, 5	
  #|0xec003190	XVBF16GER2PP Reg:ACC0 Reg:ACC0 Reg:VSL0 Reg:VSL6 | xvbf16ger2pp 0, 0, 6	
  #|0xec00378b	XSREBASE3T1UQM Reg:V0 Reg:VSL0 Reg:V6 | xsrebase3t1uqm 32, 0, 38	
  #|0xec00458f	XSREBASE2T2UQM Reg:V0 Reg:V0 Reg:V8 | xsrebase2t2uqm 32, 32, 40	
  #|0xec004984	DTSTDC Reg:CR0 Reg:F0 Imm:18 | dtstdc 0, 0, 18	
  #|0xec0049cd	XXSSUMUDMC Reg:V0 Reg:V0 Reg:VSL9 Imm:0 | xxssumudmc 32, 32, 9, 0	
  #|0xec00531e	XVI8GER4SPP Reg:ACC0 Reg:ACC0 Reg:V0 Reg:V10 | xvi8ger4spp 0, 32, 42	
  #|0xec005e9d	FCFIDS_rec Reg:F0 Reg:F11 | fcfids. 0, 11	
  #|0xec006644	DCFFIX Reg:F0 Reg:F12 | dcffix 0, 12	
  #|0xec006a05	DCTDP_rec Reg:F0 Reg:F13 | dctdp. 0, 13	
  #|0xec006b5e	XVI16GER2PP Reg:ACC0 Reg:ACC0 Reg:V0 Reg:V13 | xvi16ger2pp 0, 32, 45	
  #|0xec007d44	DTSTSF Reg:CR0 Reg:F0 Reg:F15 | dtstsf 0, 0, 15	
  #|0xec008034	FRSQRTES Reg:F0 Reg:F16 | frsqrtes 0, 16	
  #|0xec008790	XVBF16GER2NN Reg:ACC0 Reg:ACC0 Reg:VSL0 Reg:VSL16 | xvbf16ger2nn 0, 0, 16	
  #|0xec0088cc	XXSSUMUDM Reg:VSL0 Reg:V0 Reg:VSL17 Imm:0 | xxssumudm 0, 32, 17, 0	
  #|0xec00aa04	DCTDP Reg:F0 Reg:F21 | dctdp 0, 21	
  #|0xec00abca	XSMERGE3T1UQM Reg:VSL0 Reg:VSL0 Reg:V21 | xsmerge3t1uqm 0, 0, 53	
  #|0xec00b11a	XVI4GER8 Reg:ACC0 Reg:VSL0 Reg:V22 | xvi4ger8 0, 0, 54	
  #|0xec00b7cb	XSREBASE3T2UQM Reg:V0 Reg:VSL0 Reg:V22 | xsrebase3t2uqm 32, 0, 54	
  #|0xec00b904	DCMPO Reg:CR0 Reg:F0 Reg:F23 | dcmpo 0, 0, 23	
  #|0xec00c944	DTSTEX Reg:CR0 Reg:F0 Reg:F25 | dtstex 0, 0, 25	
  #|0xec00cf0e	XXMULMUL Reg:VSL0 Reg:V0 Reg:V25 Imm:7 | xxmulmul 0, 32, 57, 7	
  #|0xec00cf9c	FCFIDUS Reg:F0 Reg:F25 | fcfidus 0, 25	
  #|0xec00d156	XVI16GER2SPP Reg:ACC0 Reg:ACC0 Reg:V0 Reg:V26 | xvi16ger2spp 0, 32, 58	
  #|0xec00e68a	XSREBASE2T3UQM Reg:VSL0 Reg:VSL0 Reg:V28 | xsrebase2t3uqm 0, 0, 60	
  #|0xec00f030	FRES Reg:F0 Reg:F30 | fres 0, 30	
  #|0xec00f04a	XXMULMULHIADD Reg:VSL0 Reg:VSL0 Reg:V30 Imm:0 Imm:0 Imm:0 | xxmulmulhiadd 0, 0, 62, 0, 0, 0	
  #|0xec0104d0	XVF32GERPN Reg:ACC0 Reg:ACC0 Reg:VSL1 Reg:VSL0 | xvf32gerpn 0, 1, 0	
  #|0xec017029	FSUBS_rec Reg:F0 Reg:F1 Reg:F14 | fsubs. 0, 1, 14	
  #|0xec019818	XVI8GER4 Reg:ACC0 Reg:VSL1 Reg:VSL19 | xvi8ger4 0, 1, 19	
  #|0xec01acd2	XVF32GERPN Reg:ACC0 Reg:ACC0 Reg:VSL1 Reg:V21 | xvf32gerpn 0, 1, 53	
  #|0xec01d686	DQUAI Reg:F0 Imm:1 Reg:F26 Imm:3 | dquai 1, 0, 26, 3	
  #|0xec01f81c	XVI8GER4 Reg:ACC0 Reg:V1 Reg:VSL31 | xvi8ger4 0, 33, 31	
  #|0xec02007c	FNMSUBS Reg:F0 Reg:F2 Reg:F1 Reg:F0 | fnmsubs 0, 2, 1, 0	
  #|0xec020794	XVBF16GER2NN Reg:ACC0 Reg:ACC0 Reg:V2 Reg:VSL0 | xvbf16ger2nn 0, 34, 0	
  #|0xec023194	XVBF16GER2PP Reg:ACC0 Reg:ACC0 Reg:V2 Reg:VSL6 | xvbf16ger2pp 0, 34, 6	
  #|0xec02cb1a	XVI8GER4SPP Reg:ACC0 Reg:ACC0 Reg:VSL2 Reg:V25 | xvi8ger4spp 0, 2, 57	
  #|0xec0304d4	XVF32GERPN Reg:ACC0 Reg:ACC0 Reg:V3 Reg:VSL0 | xvf32gerpn 0, 35, 0	
  #|0xec0468d8	XVF32GER Reg:ACC0 Reg:VSL4 Reg:VSL13 | xvf32ger 0, 4, 13	
  #|0xec04cb81	XSADDSUBUQM Reg:V0 Reg:VSL4 Reg:VSL25 | xsaddsubuqm 32, 4, 25	
  #|0xec050490	XVF16GER2PN Reg:ACC0 Reg:ACC0 Reg:VSL5 Reg:VSL0 | xvf16ger2pn 0, 5, 0	
  #|0xec0505cf	XXSSUMUDMC Reg:V0 Reg:V5 Reg:V0 Imm:1 | xxssumudmc 32, 37, 32, 1	
  #|0xec055294	XVF16GER2NP Reg:ACC0 Reg:ACC0 Reg:V5 Reg:VSL10 | xvf16ger2np 0, 37, 10	
  #|0xec0618dc	XVF32GER Reg:ACC0 Reg:V6 Reg:VSL3 | xvf32ger 0, 38, 3	
  #|0xec0630da	XVF32GER Reg:ACC0 Reg:VSL6 Reg:V6 | xvf32ger 0, 6, 38	
  #|0xec06398d	XXMULMULLOADD Reg:V0 Reg:V6 Reg:VSL7 Imm:0 Imm:1 | xxmulmulloadd 32, 38, 7, 0, 1	
  #|0xec06b696	XVF16GER2NN Reg:ACC0 Reg:ACC0 Reg:V6 Reg:V22 | xvf16ger2nn 0, 38, 54	
  #|0xec06e1c4	DTSTDG Reg:CR0 Reg:F6 Imm:56 | dtstdg 0, 6, 56	
  #|0xec0706cd	XSREBASE2T4UQM Reg:V0 Reg:V7 Reg:VSL0 | xsrebase2t4uqm 32, 39, 0	
  #|0xec070ed4	XVF32GERNN Reg:ACC0 Reg:ACC0 Reg:V7 Reg:VSL1 | xvf32gernn 0, 39, 1	
  #|0xec0770d4	XVF32GERPP Reg:ACC0 Reg:ACC0 Reg:V7 Reg:VSL14 | xvf32gerpp 0, 39, 14	
  #|0xec079918	XVI4GER8 Reg:ACC0 Reg:VSL7 Reg:VSL19 | xvi4ger8 0, 7, 19	
  #|0xec07bd94	XVBF16GER2PN Reg:ACC0 Reg:ACC0 Reg:V7 Reg:VSL23 | xvbf16ger2pn 0, 39, 23	
  #|0xec07fb1c	XVI8GER4SPP Reg:ACC0 Reg:ACC0 Reg:V7 Reg:VSL31 | xvi8ger4spp 0, 39, 31	
  #|0xec08025a	XVI16GER2 Reg:ACC0 Reg:VSL8 Reg:V0 | xvi16ger2 0, 8, 32	
  #|0xec08068e	XSREBASE2T3UQM Reg:VSL0 Reg:V8 Reg:V0 | xsrebase2t3uqm 0, 40, 32	
  #|0xec08795e	XVI16GER2S Reg:ACC0 Reg:V8 Reg:V15 | xvi16ger2s 0, 40, 47	
  #|0xec08881e	XVI8GER4 Reg:ACC0 Reg:V8 Reg:V17 | xvi8ger4 0, 40, 49	
  #|0xec096318	XVI8GER4SPP Reg:ACC0 Reg:ACC0 Reg:VSL9 Reg:VSL12 | xvi8ger4spp 0, 9, 12	
  #|0xec0a0343	XSADDADDSUQM Reg:V0 Reg:VSL10 Reg:V0 | xsaddaddsuqm 32, 10, 32	
  #|0xec0a6116	XVI4GER8PP Reg:ACC0 Reg:ACC0 Reg:V10 Reg:V12 | xvi4ger8pp 0, 42, 44	
  #|0xec0b38cf	XXSSUMUDM Reg:V0 Reg:V11 Reg:V7 Imm:0 | xxssumudm 32, 43, 39, 0	
  #|0xec0b8f80	XSMERGE2T2UQM Reg:VSL0 Reg:VSL11 Reg:VSL17 | xsmerge2t2uqm 0, 11, 17	
  #|0xec0c31ce	XXSSUMUDMC Reg:VSL0 Reg:V12 Reg:V6 Imm:0 | xxssumudmc 0, 44, 38, 0	
  #|0xec0c595c	XVI16GER2S Reg:ACC0 Reg:V12 Reg:VSL11 | xvi16ger2s 0, 44, 11	
  #|0xec0c7590	XVBF16GER2PN Reg:ACC0 Reg:ACC0 Reg:VSL12 Reg:VSL14 | xvbf16ger2pn 0, 12, 14	
  #|0xec0df812	XVI8GER4PP Reg:ACC0 Reg:ACC0 Reg:VSL13 Reg:V31 | xvi8ger4pp 0, 13, 63	
  #|0xec0e0384	XSADDSUBUQM Reg:VSL0 Reg:V14 Reg:VSL0 | xsaddsubuqm 0, 46, 0	
  #|0xec0e1405	DSUB_rec Reg:F0 Reg:F14 Reg:F2 | dsub. 0, 14, 2	
  #|0xec0e6b42	XSADDADDSUQM Reg:VSL0 Reg:VSL14 Reg:V13 | xsaddaddsuqm 0, 14, 45	
  #|0xec0efdc8	XXSSUMUDMC Reg:VSL0 Reg:VSL14 Reg:VSL31 Imm:1 | xxssumudmc 0, 14, 31, 1	
  #|0xec0f0004	DADD Reg:F0 Reg:F15 Reg:F0 | dadd 0, 15, 0	
  #|0xec0f01f3	FMULS_rec Reg:F0 Reg:F15 Reg:F7 | fmuls. 0, 15, 7	
  #|0xec0fc8de	XVF32GER Reg:ACC0 Reg:V15 Reg:V25 | xvf32ger 0, 47, 57	
  #|0xec0fcd92	XVBF16GER2PN Reg:ACC0 Reg:ACC0 Reg:VSL15 Reg:V25 | xvbf16ger2pn 0, 15, 57	
  #|0xec100110	XVI4GER8PP Reg:ACC0 Reg:ACC0 Reg:VSL16 Reg:VSL0 | xvi4ger8pp 0, 16, 0	
  #|0xec100386	XSADDSUBUQM Reg:VSL0 Reg:V16 Reg:V0 | xsaddsubuqm 0, 48, 32	
  #|0xec11009e	XVF16GER2 Reg:ACC0 Reg:V17 Reg:V0 | xvf16ger2 0, 49, 32	
  #|0xec117e19	XSREBASE3T3UQM Reg:V0 Reg:VSL17 Reg:VSL15 | xsrebase3t3uqm 32, 17, 15	
  #|0xec11d80f	XXMULMUL Reg:V0 Reg:V17 Reg:V27 Imm:0 | xxmulmul 32, 49, 59, 0	
  #|0xec12899c	XVBF16GER2 Reg:ACC0 Reg:V18 Reg:VSL17 | xvbf16ger2 0, 50, 17	
  #|0xec12af01	XSADDSUBSUQM Reg:V0 Reg:VSL18 Reg:VSL21 | xsaddsubsuqm 32, 18, 21	
  #|0xec12ef96	XVBF16GER2NN Reg:ACC0 Reg:ACC0 Reg:V18 Reg:V29 | xvbf16ger2nn 0, 50, 61	
  #|0xec131cd6	XVF32GERPN Reg:ACC0 Reg:ACC0 Reg:V19 Reg:V3 | xvf32gerpn 0, 51, 35	
  #|0xec13510c	XXMULMUL Reg:VSL0 Reg:V19 Reg:VSL10 Imm:1 | xxmulmul 0, 51, 10, 1	
  #|0xec14068c	XSREBASE2T3UQM Reg:VSL0 Reg:V20 Reg:VSL0 | xsrebase2t3uqm 0, 52, 0	
  #|0xec148744	XSMERGE2T1UQM Reg:VSL0 Reg:V20 Reg:VSL16 | xsmerge2t1uqm 0, 52, 16	
  #|0xec14db5a	XVI16GER2PP Reg:ACC0 Reg:ACC0 Reg:VSL20 Reg:V27 | xvi16ger2pp 0, 20, 59	
  #|0xec156114	XVI4GER8PP Reg:ACC0 Reg:ACC0 Reg:V21 Reg:VSL12 | xvi4ger8pp 0, 53, 12	
  #|0xec1580ca	XXSSUMUDM Reg:VSL0 Reg:VSL21 Reg:V16 Imm:0 | xxssumudm 0, 21, 48, 0	
  #|0xec15c3cb	XSMERGE3T1UQM Reg:V0 Reg:VSL21 Reg:V24 | xsmerge3t1uqm 32, 21, 56	
  #|0xec163098	XVF16GER2 Reg:ACC0 Reg:VSL22 Reg:VSL6 | xvf16ger2 0, 22, 6	
  #|0xec165e94	XVF16GER2NN Reg:ACC0 Reg:ACC0 Reg:V22 Reg:VSL11 | xvf16ger2nn 0, 54, 11	
  #|0xec167b07	XSADDADDUQM Reg:V0 Reg:V22 Reg:V15 | xsaddadduqm 32, 54, 47	
  #|0xec16a78a	XSREBASE3T1UQM Reg:VSL0 Reg:VSL22 Reg:V20 | xsrebase3t1uqm 0, 22, 52	
  #|0xec16b89a	XVF16GER2 Reg:ACC0 Reg:VSL22 Reg:V23 | xvf16ger2 0, 22, 55	
  #|0xec170690	XVF16GER2NN Reg:ACC0 Reg:ACC0 Reg:VSL23 Reg:VSL0 | xvf16ger2nn 0, 23, 0	
  #|0xec179e92	XVF16GER2NN Reg:ACC0 Reg:ACC0 Reg:VSL23 Reg:V19 | xvf16ger2nn 0, 23, 51	
  #|0xec18001a	XVI8GER4 Reg:ACC0 Reg:VSL24 Reg:V0 | xvi8ger4 0, 24, 32	
  #|0xec18783e	FNMADDS Reg:F0 Reg:F24 Reg:F0 Reg:F15 | fnmadds 0, 24, 0, 15	
  #|0xec18d358	XVI16GER2PP Reg:ACC0 Reg:ACC0 Reg:VSL24 Reg:VSL26 | xvi16ger2pp 0, 24, 26	
  #|0xec1902d2	XVF32GERNP Reg:ACC0 Reg:ACC0 Reg:VSL25 Reg:V0 | xvf32gernp 0, 25, 32	
  #|0xec195e18	XSREBASE3T3UQM Reg:VSL0 Reg:VSL25 Reg:VSL11 | xsrebase3t3uqm 0, 25, 11	
  #|0xec1b015a	XVI16GER2S Reg:ACC0 Reg:VSL27 Reg:V0 | xvi16ger2s 0, 27, 32	
  #|0xec1bf806	DQUA Reg:F0 Reg:F27 Reg:F31 Imm:0 | dqua 0, 27, 31, 0	
  #|0xec1d0346	XSADDADDSUQM Reg:VSL0 Reg:V29 Reg:V0 | xsaddaddsuqm 0, 61, 32	
  #|0xec1d035c	XVI16GER2PP Reg:ACC0 Reg:ACC0 Reg:V29 Reg:VSL0 | xvi16ger2pp 0, 61, 0	
  #|0xec1d0700	XSADDSUBSUQM Reg:VSL0 Reg:VSL29 Reg:VSL0 | xsaddsubsuqm 0, 29, 0	
  #|0xec1d8192	XVBF16GER2PP Reg:ACC0 Reg:ACC0 Reg:VSL29 Reg:V16 | xvbf16ger2pp 0, 29, 48	
  #|0xec1e0109	XXMULMUL Reg:V0 Reg:VSL30 Reg:VSL0 Imm:1 | xxmulmul 32, 30, 0, 1	
  #|0xec1ea784	XSMERGE2T2UQM Reg:VSL0 Reg:V30 Reg:VSL20 | xsmerge2t2uqm 0, 62, 20	
  #|0xec1f3158	XVI16GER2S Reg:ACC0 Reg:VSL31 Reg:VSL6 | xvi16ger2s 0, 31, 6	
  #|0xec1f5a96	XVF16GER2NP Reg:ACC0 Reg:ACC0 Reg:V31 Reg:V11 | xvf16ger2np 0, 63, 43	
  #|0xec1f70d0	XVF32GERPP Reg:ACC0 Reg:ACC0 Reg:VSL31 Reg:VSL14 | xvf32gerpp 0, 31, 14	
  #|0xec1f9e88	XSREBASE2T3UQM Reg:VSL0 Reg:VSL31 Reg:VSL19 | xsrebase2t3uqm 0, 31, 19	
  #|0xec200344	XSADDADDSUQM Reg:VSL1 Reg:V0 Reg:VSL0 | xsaddaddsuqm 1, 32, 0	
  #|0xec200f03	XSADDSUBSUQM Reg:V1 Reg:VSL0 Reg:V1 | xsaddsubsuqm 33, 0, 33	
  #|0xec204089	XXMULMULLOADD Reg:V1 Reg:VSL0 Reg:VSL8 Imm:0 Imm:0 | xxmulmulloadd 33, 0, 8, 0, 0	
  #|0xec2906b9	FMSUBS_rec Reg:F1 Reg:F9 Reg:F26 Reg:F0 | fmsubs. 1, 9, 26, 0	
  #|0xec311c89	XSREBASE2T1UQM Reg:V1 Reg:VSL17 Reg:VSL3 | xsrebase2t1uqm 33, 17, 3	
  #|0xec40028a	XXMULMULLOADD Reg:VSL2 Reg:VSL0 Reg:V0 Imm:1 Imm:0 | xxmulmulloadd 2, 0, 32, 1, 0	
  #|0xec534b40	XSADDADDSUQM Reg:VSL2 Reg:VSL19 Reg:VSL9 | xsaddaddsuqm 2, 19, 9	
  #|0xec601c07	DQUA_rec Reg:F3 Reg:F0 Reg:F3 Imm:2 | dqua. 3, 0, 3, 2	
  #|0xec609bc7	DRINTN_rec Reg:F3 Imm:0 Reg:F19 Imm:1 | drintn. 0, 3, 19, 1	
  #|0xec6fd588	XSREBASE2T2UQM Reg:VSL3 Reg:VSL15 Reg:VSL26 | xsrebase2t2uqm 3, 15, 26	
  #|0xec800383	XSADDSUBUQM Reg:V4 Reg:VSL0 Reg:V0 | xsaddsubuqm 36, 0, 32	
  #|0xec802047	DRRND_rec Reg:F4 Reg:F0 Reg:F4 Imm:0 | drrnd. 4, 0, 4, 0	
  #|0xec80ab82	XSADDSUBUQM Reg:VSL4 Reg:VSL0 Reg:V21 | xsaddsubuqm 4, 0, 53	
  #|0xec80afcc	XSREBASE3T2UQM Reg:VSL4 Reg:V0 Reg:VSL21 | xsrebase3t2uqm 4, 32, 21	
  #|0xec80c885	DSCLI_rec Reg:F4 Reg:F0 Imm:50 | dscli. 4, 0, 50	
  #|0xec83b341	XSADDADDSUQM Reg:V4 Reg:VSL3 Reg:VSL22 | xsaddaddsuqm 36, 3, 22	
  #|0xec88a2cd	XSMERGE2T3UQM Reg:V4 Reg:V8 Reg:VSL20 | xsmerge2t3uqm 36, 40, 20	
  #|0xec8b4c96	XVF16GER2PN Reg:ACC1 Reg:ACC1 Reg:V11 Reg:V9 | xvf16ger2pn 1, 43, 41	
  #|0xec9b0005	DADD_rec Reg:F4 Reg:F27 Reg:F0 | dadd. 4, 27, 0	
  #|0xec9b06ce	XSREBASE2T4UQM Reg:VSL4 Reg:V27 Reg:V0 | xsrebase2t4uqm 4, 59, 32	
  #|0xec9dc792	XVBF16GER2NN Reg:ACC1 Reg:ACC1 Reg:VSL29 Reg:V24 | xvbf16ger2nn 1, 29, 56	
  #|0xec9fda58	XVI16GER2 Reg:ACC1 Reg:VSL31 Reg:VSL27 | xvi16ger2 1, 31, 27	
  #|0xeca005ca	XXSSUMUDMC Reg:VSL5 Reg:VSL0 Reg:V0 Imm:1 | xxssumudmc 5, 0, 32, 1	
  #|0xeca006c4	DIEX Reg:F5 Reg:F0 Reg:F0 | diex 5, 0, 0	
  #|0xeca00e8f	XSREBASE2T3UQM Reg:V5 Reg:V0 Reg:V1 | xsrebase2t3uqm 37, 32, 33	
  #|0xeca09b00	XSADDADDUQM Reg:VSL5 Reg:VSL0 Reg:VSL19 | xsaddadduqm 5, 0, 19	
  #|0xecb15ecb	XSREBASE2T4UQM Reg:V5 Reg:VSL17 Reg:V11 | xsrebase2t4uqm 37, 17, 43	
  #|0xecb48f88	XSREBASE3T1UQM Reg:VSL5 Reg:VSL20 Reg:VSL17 | xsrebase3t1uqm 5, 20, 17	
  #|0xecc0bb45	XSADDADDSUQM Reg:V6 Reg:V0 Reg:VSL23 | xsaddaddsuqm 38, 32, 23	
  #|0xece0010b	XXMULMUL Reg:V7 Reg:VSL0 Reg:V0 Imm:1 | xxmulmul 39, 0, 32, 1	
  #|0xece7f2ca	XSMERGE2T3UQM Reg:VSL7 Reg:VSL7 Reg:V30 | xsmerge2t3uqm 7, 7, 62	
  #|0xecf60246	DRRND Reg:F7 Reg:F22 Reg:F0 Imm:1 | drrnd 7, 22, 0, 1	
  #|0xecf6258b	XSREBASE2T2UQM Reg:V7 Reg:VSL22 Reg:V4 | xsrebase2t2uqm 39, 22, 36	
  #|0xecffde8d	XSREBASE2T3UQM Reg:V7 Reg:V31 Reg:VSL27 | xsrebase2t3uqm 39, 63, 27	
  #|0xed001fc8	XSREBASE3T2UQM Reg:VSL8 Reg:VSL0 Reg:VSL3 | xsrebase3t2uqm 8, 0, 3	
  #|0xed00425c	XVI16GER2 Reg:ACC2 Reg:V0 Reg:VSL8 | xvi16ger2 2, 32, 8	
  #|0xed004392	XVBF16GER2NP Reg:ACC2 Reg:ACC2 Reg:VSL0 Reg:V8 | xvbf16ger2np 2, 0, 40	
  #|0xed004ed0	XVF32GERNN Reg:ACC2 Reg:ACC2 Reg:VSL0 Reg:VSL9 | xvf32gernn 2, 0, 9	
  #|0xed00ed96	XVBF16GER2PN Reg:ACC2 Reg:ACC2 Reg:V0 Reg:V29 | xvbf16ger2pn 2, 32, 61	
  #|0xed03e0ce	XXSSUMUDM Reg:VSL8 Reg:V3 Reg:V28 Imm:0 | xxssumudm 8, 35, 60, 0	
  #|0xed07d54c	XXMULMULHIADD Reg:VSL8 Reg:V7 Reg:VSL26 Imm:1 Imm:0 Imm:1 | xxmulmulhiadd 8, 39, 26, 1, 0, 1	
  #|0xed157090	XVF16GER2PP Reg:ACC2 Reg:ACC2 Reg:VSL21 Reg:VSL14 | xvf16ger2pp 2, 21, 14	
  #|0xed19dc04	DSUB Reg:F8 Reg:F25 Reg:F27 | dsub 8, 25, 27	
  #|0xed1f9290	XVF16GER2NP Reg:ACC2 Reg:ACC2 Reg:VSL31 Reg:VSL18 | xvf16ger2np 2, 31, 18	
  #|0xed2001cb	XXSSUMUDMC Reg:V9 Reg:VSL0 Reg:V0 Imm:0 | xxssumudmc 41, 0, 32, 0	
  #|0xed2263c9	XSMERGE3T1UQM Reg:V9 Reg:VSL2 Reg:VSL12 | xsmerge3t1uqm 41, 2, 12	
  #|0xed2e5f86	XSMERGE2T2UQM Reg:VSL9 Reg:V14 Reg:V11 | xsmerge2t2uqm 9, 46, 43	
  #|0xed3b768b	XSREBASE2T3UQM Reg:V9 Reg:VSL27 Reg:V14 | xsrebase2t3uqm 41, 27, 46	
  #|0xed4004c9	XXSSUMUDM Reg:V10 Reg:VSL0 Reg:VSL0 Imm:1 | xxssumudm 42, 0, 0, 1	
  #|0xed4028c7	DRINTX_rec Reg:F10 Imm:0 Reg:F5 Imm:0 | drintx. 0, 10, 5, 0	
  #|0xed40444d	XXMULMULHIADD Reg:V10 Reg:V0 Reg:VSL8 Imm:1 Imm:0 Imm:0 | xxmulmulhiadd 42, 32, 8, 1, 0, 0	
  #|0xed40d245	DCTFIX_rec Reg:F10 Reg:F26 | dctfix. 10, 26	
  #|0xed45b6c9	XSREBASE2T4UQM Reg:V10 Reg:VSL5 Reg:VSL22 | xsrebase2t4uqm 42, 5, 22	
  #|0xed490782	XSMERGE2T2UQM Reg:VSL10 Reg:VSL9 Reg:V0 | xsmerge2t2uqm 10, 9, 32	
  #|0xed554f04	XSADDSUBSUQM Reg:VSL10 Reg:V21 Reg:VSL9 | xsaddsubsuqm 10, 53, 9	
  #|0xed601f8c	XSREBASE3T1UQM Reg:VSL11 Reg:V0 Reg:VSL3 | xsrebase3t1uqm 11, 32, 3	
  #|0xed602ecc	XSREBASE2T4UQM Reg:VSL11 Reg:V0 Reg:VSL5 | xsrebase2t4uqm 11, 32, 5	
  #|0xed606f83	XSMERGE2T2UQM Reg:V11 Reg:VSL0 Reg:V13 | xsmerge2t2uqm 43, 0, 45	
  #|0xed60ef42	XSMERGE2T1UQM Reg:VSL11 Reg:VSL0 Reg:V29 | xsmerge2t1uqm 11, 0, 61	
  #|0xed7542cb	XSMERGE2T3UQM Reg:V11 Reg:VSL21 Reg:V8 | xsmerge2t3uqm 43, 21, 40	
  #|0xed802394	XVBF16GER2NP Reg:ACC3 Reg:ACC3 Reg:V0 Reg:VSL4 | xvbf16ger2np 3, 32, 4	
  #|0xed80d0d2	XVF32GERPP Reg:ACC3 Reg:ACC3 Reg:VSL0 Reg:V26 | xvf32gerpp 3, 0, 58	
  #|0xed80d152	XVI16GER2SPP Reg:ACC3 Reg:ACC3 Reg:VSL0 Reg:V26 | xvi16ger2spp 3, 0, 58	
  #|0xed80d689	XSREBASE2T3UQM Reg:V12 Reg:VSL0 Reg:VSL26 | xsrebase2t3uqm 44, 0, 26	
  #|0xed82d64f	XXMULMULHIADD Reg:V12 Reg:V2 Reg:V26 Imm:1 Imm:1 Imm:0 | xxmulmulhiadd 44, 34, 58, 1, 1, 0	
  #|0xed8a1f46	XSMERGE2T1UQM Reg:VSL12 Reg:V10 Reg:V3 | xsmerge2t1uqm 12, 42, 35	
  #|0xed90e892	XVF16GER2PP Reg:ACC3 Reg:ACC3 Reg:VSL16 Reg:V29 | xvf16ger2pp 3, 16, 61	
  #|0xeda03e05	DRSP_rec Reg:F13 Reg:F7 | drsp. 13, 7	
  #|0xeda05c4e	XXMULMULHIADD Reg:VSL13 Reg:V0 Reg:V11 Imm:1 Imm:0 Imm:0 | xxmulmulhiadd 13, 32, 43, 1, 0, 0	
  #|0xeda74f85	XSMERGE2T2UQM Reg:V13 Reg:V7 Reg:VSL9 | xsmerge2t2uqm 45, 39, 9	
  #|0xedb10304	XSADDADDUQM Reg:VSL13 Reg:V17 Reg:VSL0 | xsaddadduqm 13, 49, 0	
  #|0xedb18dc9	XXSSUMUDMC Reg:V13 Reg:VSL17 Reg:VSL17 Imm:1 | xxssumudmc 45, 17, 17, 1	
  #|0xedb83d89	XSREBASE2T2UQM Reg:V13 Reg:VSL24 Reg:VSL7 | xsrebase2t2uqm 45, 24, 7	
  #|0xedb852cc	XSMERGE2T3UQM Reg:VSL13 Reg:V24 Reg:VSL10 | xsmerge2t3uqm 13, 56, 10	
  #|0xedc0069c	FCFIDS Reg:F14 Reg:F0 | fcfids 14, 0	
  #|0xedc0102b	FADDS_rec Reg:F14 Reg:F0 Reg:F2 | fadds. 14, 0, 2	
  #|0xedc0982c	FSQRTS Reg:F14 Reg:F19 | fsqrts 14, 19	
  #|0xede00706	XSADDSUBSUQM Reg:VSL15 Reg:V0 Reg:V0 | xsaddsubsuqm 15, 32, 32	
  #|0xede05302	XSADDADDUQM Reg:VSL15 Reg:VSL0 Reg:V10 | xsaddadduqm 15, 0, 42	
  #|0xede10740	XSMERGE2T1UQM Reg:VSL15 Reg:VSL1 Reg:VSL0 | xsmerge2t1uqm 15, 1, 0	
  #|0xede7063b	FMADDS_rec Reg:F15 Reg:F7 Reg:F24 Reg:F0 | fmadds. 15, 7, 24, 0	
  #|0xedfee7ce	XSREBASE3T2UQM Reg:VSL15 Reg:V30 Reg:V28 | xsrebase3t2uqm 15, 62, 60	
  #|0xee004887	DQUAI_rec Reg:F16 Imm:0 Reg:F9 Imm:0 | dquai. 0, 16, 9, 0	
  #|0xee006c8b	XSREBASE2T1UQM Reg:V16 Reg:VSL0 Reg:V13 | xsrebase2t1uqm 48, 0, 45	
  #|0xee00a2d6	XVF32GERNP Reg:ACC4 Reg:ACC4 Reg:V0 Reg:V20 | xvf32gernp 4, 32, 52	
  #|0xee00a6d2	XVF32GERNN Reg:ACC4 Reg:ACC4 Reg:VSL0 Reg:V20 | xvf32gernn 4, 0, 52	
  #|0xee00fc94	XVF16GER2PN Reg:ACC4 Reg:ACC4 Reg:V0 Reg:VSL31 | xvf16ger2pn 4, 32, 31	
  #|0xee015b90	XVBF16GER2NP Reg:ACC4 Reg:ACC4 Reg:VSL1 Reg:VSL11 | xvbf16ger2np 4, 1, 11	
  #|0xee04425e	XVI16GER2 Reg:ACC4 Reg:V4 Reg:V8 | xvi16ger2 4, 36, 40	
  #|0xee06db06	XSADDADDUQM Reg:VSL16 Reg:V6 Reg:V27 | xsaddadduqm 16, 38, 59	
  #|0xee097504	DCMPU Reg:CR4 Reg:F9 Reg:F14 | dcmpu 4, 9, 14	
  #|0xee0b06d6	XVF32GERNN Reg:ACC4 Reg:ACC4 Reg:V11 Reg:V0 | xvf32gernn 4, 43, 32	
  #|0xee13cac9	XSMERGE2T3UQM Reg:V16 Reg:VSL19 Reg:VSL25 | xsmerge2t3uqm 48, 19, 25	
  #|0xee140b03	XSADDADDUQM Reg:V16 Reg:VSL20 Reg:V1 | xsaddadduqm 48, 20, 33	
  #|0xee16c8c4	DSCRI Reg:F16 Reg:F22 Imm:50 | dscri 16, 22, 50	
  #|0xee1e0896	XVF16GER2PP Reg:ACC4 Reg:ACC4 Reg:V30 Reg:V1 | xvf16ger2pp 4, 62, 33	
  #|0xee20058e	XSREBASE2T2UQM Reg:VSL17 Reg:V0 Reg:V0 | xsrebase2t2uqm 17, 32, 32	
  #|0xee28d58a	XSREBASE2T2UQM Reg:VSL17 Reg:VSL8 Reg:V26 | xsrebase2t2uqm 17, 8, 58	
  #|0xee2f6380	XSADDSUBUQM Reg:VSL17 Reg:VSL15 Reg:VSL12 | xsaddsubuqm 17, 15, 12	
  #|0xee3247cf	XSREBASE3T2UQM Reg:V17 Reg:V18 Reg:V8 | xsrebase3t2uqm 49, 50, 40	
  #|0xee37f445	DDIV_rec Reg:F17 Reg:F23 Reg:F30 | ddiv. 17, 23, 30	
  #|0xee406fca	XSREBASE3T2UQM Reg:VSL18 Reg:VSL0 Reg:V13 | xsrebase3t2uqm 18, 0, 45	
  #|0xee456c8d	XSREBASE2T1UQM Reg:V18 Reg:V5 Reg:VSL13 | xsrebase2t1uqm 50, 37, 13	
  #|0xee51418e	XXMULMULLOADD Reg:VSL18 Reg:V17 Reg:V8 Imm:0 Imm:1 | xxmulmulloadd 18, 49, 40, 0, 1	
  #|0xee57348c	XSREBASE2T1UQM Reg:VSL18 Reg:V23 Reg:VSL6 | xsrebase2t1uqm 18, 55, 6	
  #|0xee620707	XSADDSUBSUQM Reg:V19 Reg:V2 Reg:V0 | xsaddsubsuqm 51, 34, 32	
  #|0xee66df8f	XSREBASE3T1UQM Reg:V19 Reg:V6 Reg:V27 | xsrebase3t1uqm 51, 38, 59	
  #|0xee6aff0a	XXMULMUL Reg:VSL19 Reg:VSL10 Reg:V31 Imm:7 | xxmulmul 19, 10, 63, 7	
  #|0xee6b261b	XSREBASE3T3UQM Reg:V19 Reg:VSL11 Reg:V4 | xsrebase3t3uqm 51, 11, 36	
  #|0xee6e0385	XSADDSUBUQM Reg:V19 Reg:V14 Reg:VSL0 | xsaddsubuqm 51, 46, 0	
  #|0xee6e048f	XSREBASE2T1UQM Reg:V19 Reg:V14 Reg:V0 | xsrebase2t1uqm 51, 46, 32	
  #|0xee73b61a	XSREBASE3T3UQM Reg:VSL19 Reg:VSL19 Reg:V22 | xsrebase3t3uqm 19, 19, 54	
  #|0xee7d0702	XSADDSUBSUQM Reg:VSL19 Reg:VSL29 Reg:V0 | xsaddsubsuqm 19, 29, 32	
  #|0xee7ebbcc	XSMERGE3T1UQM Reg:VSL19 Reg:V30 Reg:VSL23 | xsmerge3t1uqm 19, 62, 23	
  #|0xee800198	XVBF16GER2 Reg:ACC5 Reg:VSL0 Reg:VSL0 | xvbf16ger2 5, 0, 0	
  #|0xee8a6016	XVI8GER4PP Reg:ACC5 Reg:ACC5 Reg:V10 Reg:V12 | xvi8ger4pp 5, 42, 44	
  #|0xee8ffbc8	XSMERGE3T1UQM Reg:VSL20 Reg:VSL15 Reg:VSL31 | xsmerge3t1uqm 20, 15, 31	
  #|0xee9a02c8	XSMERGE2T3UQM Reg:VSL20 Reg:VSL26 Reg:VSL0 | xsmerge2t3uqm 20, 26, 0	
  #|0xeea003cd	XSMERGE3T1UQM Reg:V21 Reg:V0 Reg:VSL0 | xsmerge3t1uqm 53, 32, 0	
  #|0xeea0dac5	DXEX_rec Reg:F21 Reg:F27 | dxex. 21, 27	
  #|0xeeb98ecf	XSREBASE2T4UQM Reg:V21 Reg:V25 Reg:V17 | xsrebase2t4uqm 53, 57, 49	
  #|0xeebb00cd	XXSSUMUDM Reg:V21 Reg:V27 Reg:VSL0 Imm:0 | xxssumudm 53, 59, 0, 0	
  #|0xeebe061c	XSREBASE3T3UQM Reg:VSL21 Reg:V30 Reg:VSL0 | xsrebase3t3uqm 21, 62, 0	
  #|0xeec0002d	FSQRTS_rec Reg:F22 Reg:F0 | fsqrts. 22, 0	
  #|0xeec0048a	XSREBASE2T1UQM Reg:VSL22 Reg:VSL0 Reg:V0 | xsrebase2t1uqm 22, 0, 32	
  #|0xeec6bb01	XSADDADDUQM Reg:V22 Reg:VSL6 Reg:VSL23 | xsaddadduqm 54, 6, 23	
  #|0xeec7cb87	XSADDSUBUQM Reg:V22 Reg:V7 Reg:V25 | xsaddsubuqm 54, 39, 57	
  #|0xeecf058c	XSREBASE2T2UQM Reg:VSL22 Reg:V15 Reg:VSL0 | xsrebase2t2uqm 22, 47, 0	
  #|0xeed764cb	XXSSUMUDM Reg:V22 Reg:VSL23 Reg:V12 Imm:1 | xxssumudm 54, 23, 44, 1	
  #|0xeedfc1b8	FMSUBS Reg:F22 Reg:F31 Reg:F6 Reg:F24 | fmsubs 22, 31, 6, 24	
  #|0xeee0074b	XXMULMULHIADD Reg:V23 Reg:VSL0 Reg:V0 Imm:1 Imm:1 Imm:1 | xxmulmulhiadd 55, 0, 32, 1, 1, 1	
  #|0xeee08488	XSREBASE2T1UQM Reg:VSL23 Reg:VSL0 Reg:VSL16 | xsrebase2t1uqm 23, 0, 16	
  #|0xeee096c8	XSREBASE2T4UQM Reg:VSL23 Reg:VSL0 Reg:VSL18 | xsrebase2t4uqm 23, 0, 18	
  #|0xeee73e08	XXMULMUL Reg:VSL23 Reg:VSL7 Reg:VSL7 Imm:6 | xxmulmul 23, 7, 7, 6	
  #|0xeee7e025	FDIVS_rec Reg:F23 Reg:F7 Reg:F28 | fdivs. 23, 7, 28	
  #|0xeee80045	DMUL_rec Reg:F23 Reg:F8 Reg:F0 | dmul. 23, 8, 0	
  #|0xeeeed78e	XSREBASE3T1UQM Reg:VSL23 Reg:V14 Reg:V26 | xsrebase3t1uqm 23, 46, 58	
  #|0xeefa06c5	DIEX_rec Reg:F23 Reg:F26 Reg:F0 | diex. 23, 26, 0	
  #|0xef005112	XVI4GER8PP Reg:ACC6 Reg:ACC6 Reg:VSL0 Reg:V10 | xvi4ger8pp 6, 0, 42	
  #|0xef00a09c	XVF16GER2 Reg:ACC6 Reg:V0 Reg:VSL20 | xvf16ger2 6, 32, 20	
  #|0xef00ffcd	XSREBASE3T2UQM Reg:V24 Reg:V0 Reg:VSL31 | xsrebase3t2uqm 56, 32, 31	
  #|0xef01040d	XXMULMUL Reg:V24 Reg:V1 Reg:VSL0 Imm:4 | xxmulmul 56, 33, 0, 4	
  #|0xef02111e	XVI4GER8 Reg:ACC6 Reg:V2 Reg:V2 | xvi4ger8 6, 34, 34	
  #|0xef04078d	XSREBASE3T1UQM Reg:V24 Reg:V4 Reg:VSL0 | xsrebase3t1uqm 56, 36, 0	
  #|0xef049bcf	XSMERGE3T1UQM Reg:V24 Reg:V4 Reg:V19 | xsmerge3t1uqm 56, 36, 51	
  #|0xef1d6e1e	XSREBASE3T3UQM Reg:VSL24 Reg:V29 Reg:V13 | xsrebase3t3uqm 24, 61, 45	
  #|0xef1dff47	XSMERGE2T1UQM Reg:V24 Reg:V29 Reg:V31 | xsmerge2t1uqm 56, 61, 63	
  #|0xef1e9292	XVF16GER2NP Reg:ACC6 Reg:ACC6 Reg:VSL30 Reg:V18 | xvf16ger2np 6, 30, 50	
  #|0xef1ee91c	XVI4GER8 Reg:ACC6 Reg:V30 Reg:VSL29 | xvi4ger8 6, 62, 29	
  #|0xef200035	FRSQRTES_rec Reg:F25 Reg:F0 | frsqrtes. 25, 0	
  #|0xef2006c6	DRINTX Reg:F25 Imm:0 Reg:F0 Imm:3 | drintx 0, 25, 0, 3	
  #|0xef205b47	XSADDADDSUQM Reg:V25 Reg:V0 Reg:V11 | xsaddaddsuqm 57, 32, 43	
  #|0xef20de1d	XSREBASE3T3UQM Reg:V25 Reg:V0 Reg:VSL27 | xsrebase3t3uqm 57, 32, 27	
  #|0xef277888	XXMULMULLOADD Reg:VSL25 Reg:VSL7 Reg:VSL15 Imm:0 Imm:0 | xxmulmulloadd 25, 7, 15, 0, 0	
  #|0xef32dacf	XSMERGE2T3UQM Reg:V25 Reg:V18 Reg:V27 | xsmerge2t3uqm 57, 50, 59	
  #|0xef3e04c5	DSCRI_rec Reg:F25 Reg:F30 Imm:1 | dscri. 25, 30, 1	
  #|0xef400448	XXMULMULHIADD Reg:VSL26 Reg:VSL0 Reg:VSL0 Imm:1 Imm:0 Imm:0 | xxmulmulhiadd 26, 0, 0, 1, 0, 0	
  #|0xef4017c9	XSREBASE3T2UQM Reg:V26 Reg:VSL0 Reg:VSL2 | xsrebase3t2uqm 58, 0, 2	
  #|0xef40cb05	XSADDADDUQM Reg:V26 Reg:V0 Reg:VSL25 | xsaddadduqm 58, 32, 25	
  #|0xef52728c	XXMULMULLOADD Reg:VSL26 Reg:V18 Reg:VSL14 Imm:1 Imm:0 | xxmulmulloadd 26, 50, 14, 1, 0	
  #|0xef60aeca	XSREBASE2T4UQM Reg:VSL27 Reg:VSL0 Reg:V21 | xsrebase2t4uqm 27, 0, 53	
  #|0xef70e444	DDIV Reg:F27 Reg:F16 Reg:F28 | ddiv 27, 16, 28	
  #|0xef799787	XSMERGE2T2UQM Reg:V27 Reg:V25 Reg:V18 | xsmerge2t2uqm 59, 57, 50	
  #|0xef8000c8	XXSSUMUDM Reg:VSL28 Reg:VSL0 Reg:VSL0 Imm:0 | xxssumudm 28, 0, 0, 0	
  #|0xef800492	XVF16GER2PN Reg:ACC7 Reg:ACC7 Reg:VSL0 Reg:V0 | xvf16ger2pn 7, 0, 32	
  #|0xef8004fd	FNMSUBS_rec Reg:F28 Reg:F0 Reg:F19 Reg:F0 | fnmsubs. 28, 0, 19, 0	
  #|0xef80079d	FCFIDUS_rec Reg:F28 Reg:F0 | fcfidus. 28, 0	
  #|0xef807196	XVBF16GER2PP Reg:ACC7 Reg:ACC7 Reg:V0 Reg:V14 | xvbf16ger2pp 7, 32, 46	
  #|0xef808e45	DCFFIX_rec Reg:F28 Reg:F17 | dcffix. 28, 17	
  #|0xef80a894	XVF16GER2PP Reg:ACC7 Reg:ACC7 Reg:V0 Reg:VSL21 | xvf16ger2pp 7, 32, 21	
  #|0xef821814	XVI8GER4PP Reg:ACC7 Reg:ACC7 Reg:V2 Reg:VSL3 | xvi8ger4pp 7, 34, 3	
  #|0xef830745	XSMERGE2T1UQM Reg:V28 Reg:V3 Reg:VSL0 | xsmerge2t1uqm 60, 35, 0	
  #|0xef8db950	XVI16GER2SPP Reg:ACC7 Reg:ACC7 Reg:VSL13 Reg:VSL23 | xvi16ger2spp 7, 13, 23	
  #|0xef9300d6	XVF32GERPP Reg:ACC7 Reg:ACC7 Reg:V19 Reg:V0 | xvf32gerpp 7, 51, 32	
  #|0xef939ad4	XVF32GERNP Reg:ACC7 Reg:ACC7 Reg:V19 Reg:VSL19 | xvf32gernp 7, 51, 19	
  #|0xefa002ce	XSMERGE2T3UQM Reg:VSL29 Reg:V0 Reg:V0 | xsmerge2t3uqm 29, 32, 32	
  #|0xefa01449	XXMULMULHIADD Reg:V29 Reg:VSL0 Reg:VSL2 Imm:1 Imm:0 Imm:0 | xxmulmulhiadd 61, 0, 2, 1, 0, 0	
  #|0xefa70743	XSMERGE2T1UQM Reg:V29 Reg:VSL7 Reg:V0 | xsmerge2t1uqm 61, 7, 32	
  #|0xefad0044	DMUL Reg:F29 Reg:F13 Reg:F0 | dmul 29, 13, 0	
  #|0xefaf03ce	XSMERGE3T1UQM Reg:VSL29 Reg:V15 Reg:V0 | xsmerge3t1uqm 29, 47, 32	
  #|0xefbcfe1f	XSREBASE3T3UQM Reg:V29 Reg:V28 Reg:V31 | xsrebase3t3uqm 61, 60, 63	
  #|0xefc00484	DSCLI Reg:F30 Reg:F0 Imm:1 | dscli 30, 0, 1	
  #|0xefe00031	FRES_rec Reg:F31 Reg:F0 | fres. 31, 0	
  #|0xefe0c789	XSREBASE3T1UQM Reg:V31 Reg:VSL0 Reg:VSL24 | xsrebase3t1uqm 63, 0, 24	
  #|0xefe0faff	FNMADDS_rec Reg:F31 Reg:F0 Reg:F11 Reg:F31 | fnmadds. 31, 0, 11, 31	
  #|0xf0000050	XXPERMDI Reg:VSL0 Reg:VSL0 Reg:VSL0 Imm:0 | xxspltd 0, 0, 0	
  #|0xf0000090	XXMRGHW Reg:VSL0 Reg:VSL0 Reg:VSL0 | xxmrghw 0, 0, 0	
  #|0xf0000118	XSCMPUDP Reg:CR0 Reg:F0 Reg:F0 | xscmpudp 0, 0, 0	
  #|0xf00001c8	XSMSUBMDP Reg:F0 Reg:F0 Reg:F0 Reg:F0 | xsmsubmdp 0, 0, 0	
  #|0xf0000228	XVRSQRTESP Reg:VSL0 Reg:VSL0 | xvrsqrtesp 0, 0	
  #|0xf0000250	XXPERMDI Reg:VSL0 Reg:VSL0 Reg:VSL0 Imm:2 | xxswapd 0, 0	
  #|0xf0000290	XXSPLTW Reg:VSL0 Reg:VSL0 Imm:0 | xxspltw 0, 0, 0	
  #|0xf00002a0	XVCVUXWSP Reg:VSL0 Reg:VSL0 | xvcvuxwsp 0, 0	
  #|0xf00002aa	XVTSQRTSP Reg:CR0 Reg:V0 | xvtsqrtsp 0, 32	
  #|0xf00003e8	XVTDIVDP Reg:CR0 Reg:VSL0 Reg:VSL0 | xvtdivdp 0, 0, 0	
  #|0xf0000426	XSCVDPSP Reg:F0 Reg:VF0 | xscvdpsp 0, 32	
  #|0xf000042d	XSCVDPSPN Reg:V0 Reg:F0 | xscvdpspn 32, 0	
  #|0xf0000464	XSRSP Reg:F0 Reg:F0 | xsrsp 0, 0	
  #|0xf00004d0	XXLXOR Reg:VSL0 Reg:VSL0 Reg:VSL0 | xxlxor 0, 0, 0	
  #|0xf00004d7	XXLXOR Reg:V0 Reg:V0 Reg:V0 | xxlxor 32, 32, 32	
  #|0xf000059d	XVMULHSW Reg:V0 Reg:V0 Reg:VSL0 | xvmulhsw 32, 32, 0	
  #|0xf00005e0	XSCVSXDDP Reg:F0 Reg:F0 | xscvsxddp 0, 0	
  #|0xf00005e4	XSNEGDP Reg:F0 Reg:F0 | xsnegdp 0, 0	
  #|0xf00006e4	XVNEGSP Reg:VSL0 Reg:VSL0 | xvnegsp 0, 0	
  #|0xf0000724	XVCVSPDP Reg:VSL0 Reg:VSL0 | xvcvspdp 0, 0	
  #|0xf0000800	XSADDSP Reg:F0 Reg:F0 Reg:F1 | xsaddsp 0, 0, 1	
  #|0xf0000850	XXPERMDI Reg:VSL0 Reg:VSL0 Reg:VSL1 Imm:0 | xxmrghd 0, 0, 1	
  #|0xf0000900	XSADDDP Reg:F0 Reg:F0 Reg:F1 | xsadddp 0, 0, 1	
  #|0xf0000924	XSRDPI Reg:F0 Reg:F1 | xsrdpi 0, 1	
  #|0xf0000928	XSRSQRTEDP Reg:F0 Reg:F1 | xsrsqrtedp 0, 1	
  #|0xf000092c	XSSQRTDP Reg:F0 Reg:F1 | xssqrtdp 0, 1	
  #|0xf0000960	XSCVDPSXWS Reg:F0 Reg:F1 | xscvdpsxws 0, 1	
  #|0xf0000990	XXMRGLW Reg:VSL0 Reg:VSL0 Reg:VSL1 | xxmrglw 0, 0, 1	
  #|0xf00009a8	XSTSQRTDP Reg:CR0 Reg:F1 | xstsqrtdp 0, 1	
  #|0xf0000a00	XVADDSP Reg:VSL0 Reg:VSL0 Reg:VSL1 | xvaddsp 0, 0, 1	
  #|0xf0000b00	XVADDDP Reg:VSL0 Reg:VSL0 Reg:VSL1 | xvadddp 0, 0, 1	
  #|0xf0000bac	XVRDPIC Reg:VSL0 Reg:VSL1 | xvrdpic 0, 1	
  #|0xf0000d20	XSCVDPUXDS Reg:F0 Reg:F1 | xscvdpuxds 0, 1	
  #|0xf0000d60	XSCVDPSXDS Reg:F0 Reg:F1 | xscvdpsxds 0, 1	
  #|0xf0000d64	XSABSDP Reg:F0 Reg:F1 | xsabsdp 0, 1	
  #|0xf0001180	XSMULDP Reg:F0 Reg:F0 Reg:F2 | xsmuldp 0, 0, 2	
  #|0xf00013e2	XVCVSXWDP Reg:VSL0 Reg:V2 | xvcvsxwdp 0, 34	
  #|0xf00016d7	XXGFMUL128 Reg:V0 Reg:V0 Reg:V2 Imm:0 | xxgfmul128gcm 32, 32, 34	
  #|0xf0001c8b	XSNMSUBASP Reg:VF0 Reg:VF0 Reg:F0 Reg:VF3 | xsnmsubasp 32, 0, 35	
  #|0xf00023c0	XVDIVDP Reg:VSL0 Reg:VSL0 Reg:VSL4 | xvdivdp 0, 0, 4	
  #|0xf0003c40	XSMINCDP Reg:F0 Reg:F0 Reg:F7 | xsmincdp 0, 0, 7	
  #|0xf0005e40	XVMINSP Reg:VSL0 Reg:VSL0 Reg:VSL11 | xvminsp 0, 0, 11	
  #|0xf00069ea	XSTDIVDP Reg:CR0 Reg:F0 Reg:VF13 | xstdivdp 0, 0, 45	
  #|0xf0007e87	XVCPSGNSP Reg:V0 Reg:V0 Reg:V15 | xvcpsgnsp 32, 32, 47	
  #|0xf00087a0	XVCVUXDDP Reg:VSL0 Reg:VSL16 | xvcvuxddp 0, 16	
  #|0xf0008ea1	XVCVUXDSP Reg:V0 Reg:VSL17 | xvcvuxdsp 32, 17	
  #|0xf00093ec	XVTDIVDP Reg:CR0 Reg:V0 Reg:VSL18 | xvtdivdp 0, 32, 18	
  #|0xf000982d	XSSQRTSP Reg:VF0 Reg:F19 | xssqrtsp 32, 19	
  #|0xf000a11e	XSCMPUDP Reg:CR0 Reg:VF0 Reg:VF20 | xscmpudp 0, 32, 52	
  #|0xf000a269	XVRESP Reg:V0 Reg:VSL20 | xvresp 32, 20	
  #|0xf000a56c	XSXEXPDP Reg:X0 Reg:F20 | xsxexpdp 0, 20	
  #|0xf000a868	XSRESP Reg:F0 Reg:F21 | xsresp 0, 21	
  #|0xf000ac84	XSMAXJDP Reg:VSL0 Reg:VF0 Reg:F21 | xsmaxjdp 0, 32, 21	
  #|0xf000afd1	XXGFMUL128 Reg:V0 Reg:VSL0 Reg:VSL21 Imm:1 | xxgfmul128xts 32, 0, 21	
  #|0xf000b266	XVRSPIZ Reg:VSL0 Reg:V22 | xvrspiz 0, 54	
  #|0xf000b2d5	XXINSERTW Reg:V0 Reg:V0 Reg:VSL22 Imm:0 | xxinsertw 32, 22, 0	
  #|0xf000b34b	XVMADDMDP Reg:V0 Reg:V0 Reg:VSL0 Reg:V22 | xvmaddmdp 32, 0, 54	
  #|0xf000b364	XVRDPIZ Reg:VSL0 Reg:VSL22 | xvrdpiz 0, 22	
  #|0xf000b51b	XVMULUWM Reg:V0 Reg:VSL0 Reg:V22 | xvmuluwm 32, 0, 54	
  #|0xf000dae5	XVRSPIM Reg:V0 Reg:VSL27 | xvrspim 32, 27	
  #|0xf000db2f	XVSQRTDP Reg:V0 Reg:V27 | xvsqrtdp 32, 59	
  #|0xf000f31d	XVCMPEQDP Reg:V0 Reg:V0 Reg:VSL30 | xvcmpeqdp 32, 32, 30	
  #|0xf000fa4e	XVMADDMSP Reg:VSL0 Reg:VSL0 Reg:V0 Reg:V31 | xvmaddmsp 0, 32, 63	
  #|0xf0010080	XSMULSP Reg:F0 Reg:F1 Reg:F0 | xsmulsp 0, 1, 0	
  #|0xf0010908	XSMADDADP Reg:F0 Reg:F0 Reg:F1 Reg:F1 | xsmaddadp 0, 1, 1	
  #|0xf0010988	XSMSUBADP Reg:F0 Reg:F0 Reg:F1 Reg:F1 | xsmsubadp 0, 1, 1	
  #|0xf0010b08	XVMADDADP Reg:VSL0 Reg:VSL0 Reg:VSL1 Reg:VSL1 | xvmaddadp 0, 1, 1	
  #|0xf0011008	XSMADDASP Reg:F0 Reg:F0 Reg:F1 Reg:F2 | xsmaddasp 0, 1, 2	
  #|0xf001756e	XSXSIGDP Reg:X0 Reg:VF14 | xsxsigdp 0, 46	
  #|0xf002076c	XVTLSBB Reg:CR0 Reg:VSL0 | xvtlsbb 0, 0	
  #|0xf0020840	XSSUBSP Reg:F0 Reg:F2 Reg:F1 | xssubsp 0, 2, 1	
  #|0xf0020d88	XSNMSUBADP Reg:F0 Reg:F0 Reg:F2 Reg:F1 | xsnmsubadp 0, 2, 1	
  #|0xf0021a06	XVADDSP Reg:VSL0 Reg:V2 Reg:V3 | xvaddsp 0, 34, 35	
  #|0xf0024a5a	XVCMPGTSP Reg:VSL0 Reg:VSL2 Reg:V9 | xvcmpgtsp 0, 2, 41	
  #|0xf0025209	XVMADDASP Reg:V0 Reg:V0 Reg:VSL2 Reg:VSL10 | xvmaddasp 32, 2, 10	
  #|0xf0027ac8	XVMSUBMSP Reg:VSL0 Reg:VSL0 Reg:VSL2 Reg:VSL15 | xvmsubmsp 0, 2, 15	
  #|0xf003044f	XSNMADDMSP Reg:VF0 Reg:VF0 Reg:VF3 Reg:VF0 | xsnmaddmsp 32, 35, 32	
  #|0xf0031dd2	XXLEQV Reg:VSL0 Reg:VSL3 Reg:V3 | xxleqv 0, 3, 35	
  #|0xf003d906	XSADDDP Reg:F0 Reg:VF3 Reg:VF27 | xsadddp 0, 35, 59	
  #|0xf004008b	XSMSUBASP Reg:VF0 Reg:VF0 Reg:F4 Reg:VF0 | xsmsubasp 32, 4, 32	
  #|0xf004420c	XVMADDASP Reg:VSL0 Reg:VSL0 Reg:V4 Reg:VSL8 | xvmaddasp 0, 36, 8	
  #|0xf004430c	XVMADDADP Reg:VSL0 Reg:VSL0 Reg:V4 Reg:VSL8 | xvmaddadp 0, 36, 8	
  #|0xf005065f	XVCMPGTSP_rec Reg:V0 Reg:V5 Reg:V0 | xvcmpgtsp. 32, 37, 32	
  #|0xf00507a9	XVTSTDCDP Reg:V0 Imm:5 Reg:VSL0 | xvtstdcdp 32, 0, 5	
  #|0xf005eb8b	XVMSUBADP Reg:V0 Reg:V0 Reg:VSL5 Reg:V29 | xvmsubadp 32, 5, 61	
  #|0xf006072d	XSIEXPDP Reg:V0 Reg:X6 Reg:X0 | xsiexpdp 32, 6, 0	
  #|0xf0075fd7	XXGFMUL128 Reg:V0 Reg:V7 Reg:V11 Imm:1 | xxgfmul128xts 32, 39, 43	
  #|0xf0076f6d	XXBRH Reg:V0 Reg:VSL13 | xxbrh 32, 13	
  #|0xf0078048	XSMADDMSP Reg:F0 Reg:F0 Reg:F7 Reg:F16 | xsmaddmsp 0, 7, 16	
  #|0xf0093c1f	XVADDUWM Reg:V0 Reg:V9 Reg:V7 | xvadduwm 32, 41, 39	
  #|0xf009776c	XVXSIGSP Reg:VSL0 Reg:VSL14 | xvxsigsp 0, 14	
  #|0xf00a3307	XVADDDP Reg:V0 Reg:V10 Reg:V6 | xvadddp 32, 42, 38	
  #|0xf00adc9f	XVSUBUWM Reg:V0 Reg:V10 Reg:V27 | xvsubuwm 32, 42, 59	
  #|0xf00b014d	XSMADDMDP Reg:VF0 Reg:VF0 Reg:VF11 Reg:F0 | xsmaddmdp 32, 43, 0	
  #|0xf00c0095	XXMRGHW Reg:V0 Reg:V12 Reg:VSL0 | xxmrghw 32, 44, 0	
  #|0xf00c02cd	XVMSUBMSP Reg:V0 Reg:V0 Reg:V12 Reg:VSL0 | xvmsubmsp 32, 44, 0	
  #|0xf00c8158	XSCMPODP Reg:CR0 Reg:F12 Reg:F16 | xscmpodp 0, 12, 16	
  #|0xf00ced09	XSNMADDADP Reg:VF0 Reg:VF0 Reg:F12 Reg:F29 | xsnmaddadp 32, 12, 29	
  #|0xf00d0d4c	XSNMADDMDP Reg:F0 Reg:F0 Reg:VF13 Reg:F1 | xsnmaddmdp 0, 45, 1	
  #|0xf00dd0c5	XSDIVSP Reg:VF0 Reg:VF13 Reg:F26 | xsdivsp 32, 45, 26	
  #|0xf00e0345	XVSUBDP Reg:V0 Reg:V14 Reg:VSL0 | xvsubdp 32, 46, 0	
  #|0xf00f06a9	XVTSTDCSP Reg:V0 Imm:15 Reg:VSL0 | xvtstdcsp 32, 0, 15	
  #|0xf00f2a1a	XVCMPEQSP Reg:VSL0 Reg:VSL15 Reg:V5 | xvcmpeqsp 0, 15, 37	
  #|0xf00f4f5d	XVCMPGTDP_rec Reg:V0 Reg:V15 Reg:VSL9 | xvcmpgtdp. 32, 47, 9	
  #|0xf00faac7	XVDIVSP Reg:V0 Reg:V15 Reg:V21 | xvdivsp 32, 47, 53	
  #|0xf00fb76e	XXBRW Reg:VSL0 Reg:V22 | xxbrw 0, 54	
  #|0xf0105f6d	XVCVBF16SPN Reg:V0 Reg:VSL11 | xvcvbf16spn 32, 11	
  #|0xf010b3cb	XVMSUBMDP Reg:V0 Reg:V0 Reg:VSL16 Reg:V22 | xvmsubmdp 32, 16, 54	
  #|0xf010e90c	XSMADDADP Reg:F0 Reg:F0 Reg:VF16 Reg:F29 | xsmaddadp 0, 48, 29	
  #|0xf0115c8f	XSNMSUBASP Reg:VF0 Reg:VF0 Reg:VF17 Reg:VF11 | xsnmsubasp 32, 49, 43	
  #|0xf01301dc	XSCMPEXPDP Reg:CR0 Reg:VF19 Reg:F0 | xscmpexpdp 0, 51, 0	
  #|0xf014058d	XSNMSUBADP Reg:VF0 Reg:VF0 Reg:VF20 Reg:F0 | xsnmsubadp 32, 52, 0	
  #|0xf0144949	XSMADDMDP Reg:VF0 Reg:VF0 Reg:F20 Reg:F9 | xsmaddmdp 32, 20, 9	
  #|0xf014924a	XVMADDMSP Reg:VSL0 Reg:VSL0 Reg:VSL20 Reg:V18 | xvmaddmsp 0, 20, 50	
  #|0xf014f6ef	XVTSTDCSP Reg:V0 Imm:116 Reg:V30 | xvtstdcsp 32, 62, 116	
  #|0xf015044b	XSNMADDMSP Reg:VF0 Reg:VF0 Reg:F21 Reg:VF0 | xsnmaddmsp 32, 21, 32	
  #|0xf015061d	XVCMPEQSP_rec Reg:V0 Reg:V21 Reg:VSL0 | xvcmpeqsp. 32, 53, 0	
  #|0xf015074e	XVNMADDMDP Reg:VSL0 Reg:VSL0 Reg:V21 Reg:V0 | xvnmaddmdp 0, 53, 32	
  #|0xf01806c2	XVIEXPSP Reg:VSL0 Reg:VSL24 Reg:V0 | xviexpsp 0, 24, 32	
  #|0xf018976e	XVCVHPSP Reg:VSL0 Reg:V18 | xvcvhpsp 0, 50	
  #|0xf019068e	XVNMSUBASP Reg:VSL0 Reg:VSL0 Reg:V25 Reg:V0 | xvnmsubasp 0, 57, 32	
  #|0xf0193284	XVMULSP Reg:VSL0 Reg:V25 Reg:VSL6 | xvmulsp 0, 57, 6	
  #|0xf019af6d	XVCVSPHP Reg:V0 Reg:VSL21 | xvcvsphp 32, 21	
  #|0xf01c31ee	XSTDIVDP Reg:CR0 Reg:VF28 Reg:VF6 | xstdivdp 0, 60, 38	
  #|0xf01c78cd	XSMSUBMSP Reg:VF0 Reg:VF0 Reg:VF28 Reg:F15 | xsmsubmsp 32, 60, 15	
  #|0xf01d2ccd	XSNMSUBMSP Reg:VF0 Reg:VF0 Reg:VF29 Reg:F5 | xsnmsubmsp 32, 61, 5	
  #|0xf01da3d1	XVMULHUH Reg:V0 Reg:VSL29 Reg:VSL20 | xvmulhuh 32, 29, 20	
  #|0xf01e02ee	XVTDIVSP Reg:CR0 Reg:V30 Reg:V0 | xvtdivsp 0, 62, 32	
  #|0xf01e8d0c	XSNMADDADP Reg:F0 Reg:F0 Reg:VF30 Reg:F17 | xsnmaddadp 0, 62, 17	
  #|0xf01f8ece	XVNMSUBMSP Reg:VSL0 Reg:VSL0 Reg:V31 Reg:V17 | xvnmsubmsp 0, 63, 49	
  #|0xf02004a0	XSCVUXDSP Reg:F1 Reg:F0 | xscvuxdsp 1, 0	
  #|0xf020052c	XSCVSPDPN Reg:F1 Reg:VSL0 | xscvspdpn 1, 0	
  #|0xf02006a7	XVNABSSP Reg:V1 Reg:V0 | xvnabssp 33, 32	
  #|0xf0200940	XSSUBDP Reg:F1 Reg:F0 Reg:F1 | xssubdp 1, 0, 1	
  #|0xf0200964	XSRDPIZ Reg:F1 Reg:F1 | xsrdpiz 1, 1	
  #|0xf02009c0	XSDIVDP Reg:F1 Reg:F0 Reg:F1 | xsdivdp 1, 0, 1	
  #|0xf0200ae0	XVCVSXWSP Reg:VSL1 Reg:VSL1 | xvcvsxwsp 1, 1	
  #|0xf0200ce0	XSCVSXDSP Reg:F1 Reg:F1 | xscvsxdsp 1, 1	
  #|0xf0200d40	XSMINDP Reg:F1 Reg:F0 Reg:F1 | xsmindp 1, 0, 1	
  #|0xf020f6c4	XVIEXPSP Reg:VSL1 Reg:V0 Reg:VSL30 | xviexpsp 1, 32, 30	
  #|0xf0210280	XVMULSP Reg:VSL1 Reg:VSL1 Reg:VSL0 | xvmulsp 1, 1, 0	
  #|0xf0211500	XSMAXDP Reg:F1 Reg:F1 Reg:F2 | xsmaxdp 1, 1, 2	
  #|0xf0220c14	XXLAND Reg:VSL1 Reg:V2 Reg:VSL1 | xxland 1, 34, 1	
  #|0xf0226ad1	XXSPLTIB Reg:V1 Imm:77 | xxspltib 33, 77	
  #|0xf02c2a8c	XVMSUBASP Reg:VSL1 Reg:VSL1 Reg:V12 Reg:VSL5 | xvmsubasp 1, 44, 5	
  #|0xf034bd1c	XVMULUWM Reg:VSL1 Reg:V20 Reg:VSL23 | xvmuluwm 1, 52, 23	
  #|0xf0400340	XVSUBDP Reg:VSL2 Reg:VSL0 Reg:VSL0 | xvsubdp 2, 0, 0	
  #|0xf0400857	XXPERMDI Reg:V2 Reg:V0 Reg:V1 Imm:0 | xxmrghd 34, 32, 33	
  #|0xf04009a4	XSRDPIP Reg:F2 Reg:F1 | xsrdpip 2, 1	
  #|0xf04009ac	XSRDPIC Reg:F2 Reg:F1 | xsrdpic 2, 1	
  #|0xf04009e4	XSRDPIM Reg:F2 Reg:F1 | xsrdpim 2, 1	
  #|0xf0400e25	XVCVDPSP Reg:V2 Reg:VSL1 | xvcvdpsp 34, 1	
  #|0xf0400f64	XVABSDP Reg:VSL2 Reg:VSL1 | xvabsdp 2, 1	
  #|0xf0401359	XVCMPGTDP Reg:V2 Reg:VSL0 Reg:VSL2 | xvcmpgtdp 34, 0, 2	
  #|0xf0405596	XXLNAND Reg:VSL2 Reg:V0 Reg:V10 | xxlnand 2, 32, 42	
  #|0xf0420399	XVCMPGEDP Reg:V2 Reg:VSL2 Reg:VSL0 | xvcmpgedp 34, 2, 0	
  #|0xf042039d	XVCMPGEDP Reg:V2 Reg:V2 Reg:VSL0 | xvcmpgedp 34, 34, 0	
  #|0xf0421517	XXLNOR Reg:V2 Reg:V2 Reg:V2 | xxlnor 34, 34, 34	
  #|0xf0442257	XXPERMDI Reg:V2 Reg:V4 Reg:V4 Imm:2 | xxswapd 34, 36	
  #|0xf04c5c07	XSMAXCDP Reg:VF2 Reg:VF12 Reg:VF11 | xsmaxcdp 34, 44, 43	
  #|0xf04e61ce	XSMSUBMDP Reg:F2 Reg:F2 Reg:VF14 Reg:VF12 | xsmsubmdp 2, 46, 44	
  #|0xf05305ce	XSNMSUBMDP Reg:F2 Reg:F2 Reg:VF19 Reg:VF0 | xsnmsubmdp 2, 51, 32	
  #|0xf0566452	XXLANDC Reg:VSL2 Reg:VSL22 Reg:V12 | xxlandc 2, 22, 44	
  #|0xf05798c2	XSDIVSP Reg:F2 Reg:F23 Reg:VF19 | xsdivsp 2, 23, 51	
  #|0xf05fe555	XXLORC Reg:V2 Reg:V31 Reg:VSL28 | xxlorc 34, 63, 28	
  #|0xf0600718	XVCMPEQDP_rec Reg:VSL3 Reg:VSL0 Reg:VSL0 | xvcmpeqdp. 3, 0, 0	
  #|0xf0601168	XSREDP Reg:F3 Reg:F2 | xsredp 3, 2	
  #|0xf0601ba6	XVRDPIP Reg:VSL3 Reg:V3 | xvrdpip 3, 35	
  #|0xf0609d80	XSCPSGNDP Reg:F3 Reg:F0 Reg:F19 | xscpsgndp 3, 0, 19	
  #|0xf06300d5	XXPERM Reg:V3 Reg:V3 Reg:V3 Reg:VSL0 | xxperm 35, 35, 0	
  #|0xf06554aa	XSTSTDCSP Reg:CR0 Imm:101 Reg:VF10 | xststdcsp 0, 42, 101	
  #|0xf06b070c	XVNMADDADP Reg:VSL3 Reg:VSL3 Reg:V11 Reg:VSL0 | xvnmaddadp 3, 43, 0	
  #|0xf06bb593	XXLNAND Reg:V3 Reg:VSL11 Reg:V22 | xxlnand 35, 11, 54	
  #|0xf0703c1a	XVADDUWM Reg:VSL3 Reg:VSL16 Reg:V7 | xvadduwm 3, 16, 39	
  #|0xf0807384	XVMULDP Reg:VSL4 Reg:V0 Reg:VSL14 | xvmuldp 4, 32, 14	
  #|0xf08087e4	XVNEGDP Reg:VSL4 Reg:VSL16 | xvnegdp 4, 16	
  #|0xf080bdaa	XSTSTDCDP Reg:CR1 Imm:0 Reg:VF23 | xststdcdp 1, 55, 0	
  #|0xf080c122	XSCVDPUXWS Reg:F4 Reg:VF24 | xscvdpuxws 4, 56	
  #|0xf0844f0b	XVNMADDADP Reg:V4 Reg:V4 Reg:VSL4 Reg:V9 | xvnmaddadp 36, 4, 41	
  #|0xf08f009b	XSCMPGEDP Reg:V4 Reg:F15 Reg:VF0 | xscmpgedp 36, 15, 32	
  #|0xf0a00666	XVABSSP Reg:VSL5 Reg:V0 | xvabssp 5, 32	
  #|0xf0a10911	XXSLDWI Reg:V5 Reg:VSL1 Reg:VSL1 Imm:1 | xxsldwi 37, 1, 1, 1	
  #|0xf0a3aa5f	XVCMPGTSP Reg:V5 Reg:V3 Reg:V21 | xvcmpgtsp 37, 35, 53	
  #|0xf0a4b00c	XSMADDASP Reg:F5 Reg:F5 Reg:VF4 Reg:F22 | xsmaddasp 5, 36, 22	
  #|0xf0a7bb54	XXPERMDI Reg:VSL5 Reg:V7 Reg:VSL23 Imm:3 | xxmrgld 5, 39, 23	
  #|0xf0ad5600	XVMAXSP Reg:VSL5 Reg:VSL13 Reg:VSL10 | xvmaxsp 5, 13, 10	
  #|0xf0c00289	XVMSUBASP Reg:V6 Reg:V6 Reg:VSL0 Reg:VSL0 | xvmsubasp 38, 0, 0	
  #|0xf0c0338d	XVMSUBADP Reg:V6 Reg:V6 Reg:V0 Reg:VSL6 | xvmsubadp 38, 32, 6	
  #|0xf0c0f7c3	XVIEXPDP Reg:V6 Reg:VSL0 Reg:V30 | xviexpdp 38, 0, 62	
  #|0xf0c305d7	XXLEQV Reg:V6 Reg:V3 Reg:V0 | xxleqv 38, 35, 32	
  #|0xf0c500d2	XXPERM Reg:VSL6 Reg:VSL5 Reg:VSL6 Reg:V0 | xxperm 6, 5, 32	
  #|0xf0cc0400	XSMAXCDP Reg:F6 Reg:F12 Reg:F0 | xsmaxcdp 6, 12, 0	
  #|0xf0e007a6	XVNABSDP Reg:VSL7 Reg:V0 | xvnabsdp 7, 32	
  #|0xf0e01492	XXLOR Reg:VSL7 Reg:VSL0 Reg:V2 | xxlor 7, 0, 34	
  #|0xf0e0365b	XVCMPGTSP_rec Reg:V7 Reg:VSL0 Reg:V6 | xvcmpgtsp. 39, 0, 38	
  #|0xf0e0498f	XSMSUBADP Reg:VF7 Reg:VF7 Reg:VF0 Reg:VF9 | xsmsubadp 39, 32, 41	
  #|0xf0e08805	XSADDSP Reg:VF7 Reg:VF0 Reg:F17 | xsaddsp 39, 32, 17	
  #|0xf0f40584	XSCPSGNDP Reg:F7 Reg:VF20 Reg:F0 | xscpsgndp 7, 52, 0	
  #|0xf0ff076c	XXBRQ Reg:VSL7 Reg:VSL0 | xxbrq 7, 0	
  #|0xf100004e	XSMADDMSP Reg:F8 Reg:F8 Reg:VF0 Reg:VF0 | xsmaddmsp 8, 32, 32	
  #|0xf1000780	XVCPSGNDP Reg:VSL8 Reg:VSL0 Reg:VSL0 | xvmovdp 8, 0	
  #|0xf1003324	XVRDPI Reg:VSL8 Reg:VSL6 | xvrdpi 8, 6	
  #|0xf117bdd8	XVMULHSH Reg:VSL8 Reg:VSL23 Reg:VSL23 | xvmulhsh 8, 23, 23	
  #|0xf1207c09	XSNMADDASP Reg:VF9 Reg:VF9 Reg:F0 Reg:F15 | xsnmaddasp 41, 0, 15	
  #|0xf1208526	XSCVSPDP Reg:F9 Reg:VF16 | xscvspdp 9, 48	
  #|0xf12494c3	XSMINJDP Reg:V9 Reg:F4 Reg:VF18 | xsminjdp 41, 4, 50	
  #|0xf132e6af	XVTSTDCSP Reg:V9 Imm:50 Reg:V28 | xvtstdcsp 41, 60, 50	
  #|0xf1375e9f	XVCMPGESP_rec Reg:V9 Reg:V23 Reg:V11 | xvcmpgesp. 41, 55, 43	
  #|0xf14000cb	XSMSUBMSP Reg:VF10 Reg:VF10 Reg:F0 Reg:VF0 | xsmsubmsp 42, 0, 32	
  #|0xf1404261	XVCVSPSXWS Reg:V10 Reg:VSL8 | xvcvspsxws 42, 8	
  #|0xf1407ee0	XVCVSXDSP Reg:VSL10 Reg:VSL15 | xvcvsxdsp 10, 15	
  #|0xf140d321	XVCVDPUXWS Reg:V10 Reg:VSL26 | xvcvdpuxws 42, 26	
  #|0xf147e5c6	XVRLW Reg:VSL10 Reg:V7 Reg:V28 | xvrlw 10, 39, 60	
  #|0xf14c5682	XVCPSGNSP Reg:VSL10 Reg:VSL12 Reg:V10 | xvcpsgnsp 10, 12, 42	
  #|0xf1536887	XSMULSP Reg:VF10 Reg:VF19 Reg:VF13 | xsmulsp 42, 51, 45	
  #|0xf1560987	XSMULDP Reg:VF10 Reg:VF22 Reg:VF1 | xsmuldp 42, 54, 33	
  #|0xf1584d5f	XVMULUHM Reg:V10 Reg:V24 Reg:V9 | xvmuluhm 42, 56, 41	
  #|0xf15a0550	XXLORC Reg:VSL10 Reg:VSL26 Reg:VSL0 | xxlorc 10, 26, 0	
  #|0xf1605e8b	XVNMSUBASP Reg:V11 Reg:V11 Reg:VSL0 Reg:V11 | xvnmsubasp 43, 0, 43	
  #|0xf160864e	XVNMADDMSP Reg:VSL11 Reg:VSL11 Reg:V0 Reg:V16 | xvnmaddmsp 11, 32, 48	
  #|0xf165c019	XSCMPEQDP Reg:V11 Reg:F5 Reg:F24 | xscmpeqdp 43, 5, 24	
  #|0xf18006d3	XXGFMUL128 Reg:V12 Reg:VSL0 Reg:V0 Imm:0 | xxgfmul128gcm 44, 0, 32	
  #|0xf184809f	XSCMPGEDP Reg:V12 Reg:VF4 Reg:VF16 | xscmpgedp 44, 36, 48	
  #|0xf1898a98	XVCMPGESP Reg:VSL12 Reg:VSL9 Reg:VSL17 | xvcmpgesp 12, 9, 17	
  #|0xf190056d	XSCVHPDP Reg:VF12 Reg:F0 | xscvhpdp 44, 0	
  #|0xf1a69c98	XVSUBUWM Reg:VSL13 Reg:VSL6 Reg:VSL19 | xvsubuwm 13, 6, 19	
  #|0xf1b4b604	XVMAXSP Reg:VSL13 Reg:V20 Reg:VSL22 | xvmaxsp 13, 52, 22	
  #|0xf1c0a740	XVMINDP Reg:VSL14 Reg:VSL0 Reg:VSL20 | xvmindp 14, 0, 20	
  #|0xf1c0f02b	XSRSQRTESP Reg:VF14 Reg:VF30 | xsrsqrtesp 46, 62	
  #|0xf1ca5357	XXPERMDI Reg:V14 Reg:V10 Reg:V10 Imm:3 | xxspltd 46, 42, 1	
  #|0xf1d207c5	XVIEXPDP Reg:V14 Reg:V18 Reg:VSL0 | xviexpdp 46, 50, 0	
  #|0xf1d29686	XVCPSGNSP Reg:VSL14 Reg:V18 Reg:V18 | xvmovsp 14, 50	
  #|0xf1d3fddc	XVMULHSH Reg:VSL14 Reg:V19 Reg:VSL31 | xvmulhsh 14, 51, 31	
  #|0xf1d45545	XSMINDP Reg:VF14 Reg:VF20 Reg:F10 | xsmindp 46, 52, 10	
  #|0xf1da41d1	XXPERMR Reg:V14 Reg:VSL26 Reg:V14 Reg:VSL8 | xxpermr 46, 26, 8	
  #|0xf1dc031a	XVCMPEQDP Reg:VSL14 Reg:VSL28 Reg:V0 | xvcmpeqdp 14, 28, 32	
  #|0xf1e00786	XVCPSGNDP Reg:VSL15 Reg:V0 Reg:V0 | xvmovdp 15, 32	
  #|0xf1e04e62	XVCVSPSXDS Reg:VSL15 Reg:V9 | xvcvspsxds 15, 41	
  #|0xf1e0c704	XVMAXDP Reg:VSL15 Reg:V0 Reg:VSL24 | xvmaxdp 15, 32, 24	
  #|0xf1e0cb62	XVCVDPSXWS Reg:VSL15 Reg:V25 | xvcvdpsxws 15, 57	
  #|0xf1f2a599	XVMULHSW Reg:V15 Reg:VSL18 Reg:VSL20 | xvmulhsw 47, 18, 20	
  #|0xf1f404c8	XSNMSUBMSP Reg:F15 Reg:F15 Reg:F20 Reg:F0 | xsnmsubmsp 15, 20, 0	
  #|0xf2000baa	XVTSQRTDP Reg:CR4 Reg:V1 | xvtsqrtdp 4, 33	
  #|0xf204d1d8	XSCMPEXPDP Reg:CR4 Reg:F4 Reg:F26 | xscmpexpdp 4, 4, 26	
  #|0xf204dd48	XSNMADDMDP Reg:F16 Reg:F16 Reg:F4 Reg:F27 | xsnmaddmdp 16, 4, 27	
  #|0xf20c079d	XVCMPGEDP_rec Reg:V16 Reg:V12 Reg:VSL0 | xvcmpgedp. 48, 44, 0	
  #|0xf20c5618	XVCMPEQSP_rec Reg:VSL16 Reg:VSL12 Reg:VSL10 | xvcmpeqsp. 16, 12, 10	
  #|0xf20f2700	XVMAXDP Reg:VSL16 Reg:VSL15 Reg:VSL4 | xvmaxdp 16, 15, 4	
  #|0xf220ab69	XVREDP Reg:V17 Reg:VSL21 | xvredp 49, 21	
  #|0xf232df59	XVCMPGTDP_rec Reg:V17 Reg:VSL18 Reg:VSL27 | xvcmpgtdp. 49, 18, 27	
  #|0xf238b88e	XSMSUBASP Reg:F17 Reg:F17 Reg:VF24 Reg:VF23 | xsmsubasp 17, 56, 55	
  #|0xf23e6745	XVMINDP Reg:V17 Reg:V30 Reg:VSL12 | xvmindp 49, 62, 12	
  #|0xf24005c2	XVRLW Reg:VSL18 Reg:VSL0 Reg:V0 | xvrlw 18, 0, 32	
  #|0xf24803cc	XVMSUBMDP Reg:VSL18 Reg:VSL18 Reg:V8 Reg:VSL0 | xvmsubmdp 18, 40, 0	
  #|0xf24ba296	XXEXTRACTUW Reg:F18 Reg:V20 Imm:11 | xxextractuw 18, 52, 11	
  #|0xf24fa1d6	XXPERMR Reg:VSL18 Reg:V15 Reg:VSL18 Reg:V20 | xxpermr 18, 47, 52	
  #|0xf251d699	XVCMPGESP_rec Reg:V18 Reg:VSL17 Reg:VSL26 | xvcmpgesp. 50, 17, 26	
  #|0xf256e79a	XVCMPGEDP_rec Reg:VSL18 Reg:VSL22 Reg:V28 | xvcmpgedp. 18, 22, 60	
  #|0xf257ef6d	XXBRD Reg:V18 Reg:VSL29 | xxbrd 50, 29	
  #|0xf2604621	XVCVSPUXDS Reg:V19 Reg:VSL8 | xvcvspuxds 51, 8	
  #|0xf260a3a3	XVCVUXWDP Reg:V19 Reg:V20 | xvcvuxwdp 51, 52	
  #|0xf26fb481	XSMAXJDP Reg:V19 Reg:F15 Reg:F22 | xsmaxjdp 51, 15, 22	
  #|0xf27a53d6	XVMULHUH Reg:VSL19 Reg:V26 Reg:V10 | xvmulhuh 19, 58, 42	
  #|0xf27d4647	XVMINSP Reg:V19 Reg:V29 Reg:V8 | xvminsp 51, 61, 40	
  #|0xf2800723	XVCVDPUXDS Reg:V20 Reg:V0 | xvcvdpuxds 52, 32	
  #|0xf2808956	XXPERMDI Reg:VSL20 Reg:V0 Reg:V17 Imm:1 | xxpermdi 20, 32, 49, 1	
  #|0xf289995c	XSCMPODP Reg:CR5 Reg:VF9 Reg:F19 | xscmpodp 5, 41, 19	
  #|0xf291005d	XSCMPGTDP Reg:V20 Reg:VF17 Reg:F0 | xscmpgtdp 52, 49, 0	
  #|0xf2960c95	XXLOR Reg:V20 Reg:V22 Reg:VSL1 | xxlor 52, 54, 1	
  #|0xf29dbc5b	XVADDUHM Reg:V20 Reg:VSL29 Reg:V23 | xvadduhm 52, 29, 55	
  #|0xf29fd846	XSSUBSP Reg:F20 Reg:VF31 Reg:VF27 | xssubsp 20, 63, 59	
  #|0xf2a00681	XVCPSGNSP Reg:V21 Reg:VSL0 Reg:VSL0 | xvmovsp 53, 0	
  #|0xf2a0255a	XVMULUHM Reg:VSL21 Reg:VSL0 Reg:V4 | xvmuluhm 21, 0, 36	
  #|0xf2a0978c	XVNMSUBADP Reg:VSL21 Reg:VSL21 Reg:V0 Reg:VSL18 | xvnmsubadp 21, 32, 18	
  #|0xf2a0da22	XVCVSPUXWS Reg:VSL21 Reg:V27 | xvcvspuxws 21, 59	
  #|0xf2a6d780	XVCPSGNDP Reg:VSL21 Reg:VSL6 Reg:VSL26 | xvcpsgndp 21, 6, 26	
  #|0xf2a87788	XVNMSUBADP Reg:VSL21 Reg:VSL21 Reg:VSL8 Reg:VSL14 | xvnmsubadp 21, 8, 14	
  #|0xf2b094d8	XVSUBUHM Reg:VSL21 Reg:VSL16 Reg:VSL18 | xvsubuhm 21, 16, 18	
  #|0xf2b30350	XXPERMDI Reg:VSL21 Reg:VSL19 Reg:VSL0 Imm:3 | xxmrgld 21, 19, 0	
  #|0xf2c007ae	XVTSTDCDP Reg:VSL22 Imm:32 Reg:V0 | xvtstdcdp 22, 32, 32	
  #|0xf2c05da1	XSCVUXDDP Reg:VF22 Reg:F11 | xscvuxddp 54, 11	
  #|0xf2c0afe0	XVCVSXDDP Reg:VSL22 Reg:VSL21 | xvcvsxddp 22, 21	
  #|0xf2d18b97	XVMULHUW Reg:V22 Reg:V17 Reg:V17 | xvmulhuw 54, 49, 49	
  #|0xf2d3a952	XXPERMDI Reg:VSL22 Reg:VSL19 Reg:V21 Imm:1 | xxpermdi 22, 19, 53, 1	
  #|0xf2d9d45f	XVADDUHM Reg:V22 Reg:V25 Reg:V26 | xvadduhm 54, 57, 58	
  #|0xf2df4b91	XVMULHUW Reg:V22 Reg:VSL31 Reg:VSL9 | xvmulhuw 54, 31, 9	
  #|0xf2e00151	XXPERMDI Reg:V23 Reg:VSL0 Reg:VSL0 Imm:1 | xxpermdi 55, 0, 0, 1	
  #|0xf2e04f63	XVCVDPSXDS Reg:V23 Reg:V9 | xvcvdpsxds 55, 41	
  #|0xf2e0f32a	XVRSQRTEDP Reg:VSL23 Reg:V30 | xvrsqrtedp 23, 62	
  #|0xf2e1d2c2	XVDIVSP Reg:VSL23 Reg:VSL1 Reg:V26 | xvdivsp 23, 1, 58	
  #|0xf2ec735c	XVCMPGTDP Reg:VSL23 Reg:V12 Reg:VSL14 | xvcmpgtdp 23, 44, 14	
  #|0xf2f1234d	XVMADDMDP Reg:V23 Reg:V23 Reg:V17 Reg:VSL4 | xvmaddmdp 55, 49, 4	
  #|0xf2fce017	XXSLDWI Reg:V23 Reg:V28 Reg:V28 Imm:0 | xxsldwi 55, 60, 60, 0	
  #|0xf3000157	XXPERMDI Reg:V24 Reg:V0 Reg:V0 Imm:1 | xxpermdi 56, 32, 32, 1	
  #|0xf300060c	XVNMADDASP Reg:VSL24 Reg:VSL24 Reg:V0 Reg:VSL0 | xvnmaddasp 24, 32, 0	
  #|0xf300305a	XSCMPGTDP Reg:VSL24 Reg:F0 Reg:VF6 | xscmpgtdp 24, 0, 38	
  #|0xf3009fce	XVNMSUBMDP Reg:VSL24 Reg:VSL24 Reg:V0 Reg:V19 | xvnmsubmdp 24, 32, 51	
  #|0xf3026bc5	XVDIVDP Reg:V24 Reg:V2 Reg:VSL13 | xvdivdp 56, 34, 13	
  #|0xf3054c12	XXLAND Reg:VSL24 Reg:VSL5 Reg:V9 | xxland 24, 5, 41	
  #|0xf308076c	XVXEXPSP Reg:VSL24 Reg:VSL0 | xvxexpsp 24, 0	
  #|0xf30b271f	XVCMPEQDP_rec Reg:V24 Reg:V11 Reg:V4 | xvcmpeqdp. 56, 43, 36	
  #|0xf311076d	XVCVSPBF16 Reg:V24 Reg:VSL0 | xvcvspbf16 56, 0	
  #|0xf312c2e8	XVTDIVSP Reg:CR6 Reg:VSL18 Reg:VSL24 | xvtdivsp 6, 18, 24	
  #|0xf319bd06	XSMAXDP Reg:F24 Reg:VF25 Reg:VF23 | xsmaxdp 24, 57, 55	
  #|0xf3207227	XVRSPI Reg:V25 Reg:V14 | xvrspi 57, 46	
  #|0xf3210f6c	XVXSIGDP Reg:VSL25 Reg:VSL1 | xvxsigdp 25, 1	
  #|0xf33301c4	XSDIVDP Reg:F25 Reg:VF19 Reg:F0 | xsdivdp 25, 51, 0	
  #|0xf3400195	XXMRGLW Reg:V26 Reg:V0 Reg:VSL0 | xxmrglw 58, 32, 0	
  #|0xf340040d	XSNMADDASP Reg:VF26 Reg:VF26 Reg:VF0 Reg:F0 | xsnmaddasp 58, 32, 0	
  #|0xf340229f	XVCMPGESP Reg:V26 Reg:V0 Reg:V4 | xvcmpgesp 58, 32, 36	
  #|0xf3407c54	XXLANDC Reg:VSL26 Reg:V0 Reg:VSL15 | xxlandc 26, 32, 15	
  #|0xf340aaa6	XVRSPIP Reg:VSL26 Reg:V21 | xvrspip 26, 53	
  #|0xf346d7cb	XVNMSUBMDP Reg:V26 Reg:V26 Reg:VSL6 Reg:V26 | xvnmsubmdp 58, 6, 58	
  #|0xf34a3784	XVCPSGNDP Reg:VSL26 Reg:V10 Reg:VSL6 | xvcpsgndp 26, 42, 6	
  #|0xf34be241	XVSUBSP Reg:V26 Reg:VSL11 Reg:VSL28 | xvsubsp 58, 11, 28	
  #|0xf36002ad	XVRSPIC Reg:V27 Reg:VSL0 | xvrspic 59, 0	
  #|0xf360bd12	XXLNOR Reg:VSL27 Reg:VSL0 Reg:V23 | xxlnor 27, 0, 55	
  #|0xf360ca2c	XVSQRTSP Reg:VSL27 Reg:VSL25 | xvsqrtsp 27, 25	
  #|0xf37607ea	XVTSTDCDP Reg:VSL27 Imm:86 Reg:V0 | xvtstdcdp 27, 32, 86	
  #|0xf37e4e49	XVNMADDMSP Reg:V27 Reg:V27 Reg:VSL30 Reg:VSL9 | xvnmaddmsp 59, 30, 9	
  #|0xf3802f6f	XVXEXPDP Reg:V28 Reg:V5 | xvxexpdp 60, 37	
  #|0xf3812a1e	XVCMPEQSP Reg:VSL28 Reg:V1 Reg:V5 | xvcmpeqsp 28, 33, 37	
  #|0xf38e7749	XVNMADDMDP Reg:V28 Reg:V28 Reg:VSL14 Reg:VSL14 | xvnmaddmdp 60, 14, 14	
  #|0xf391c56f	XSCVDPHP Reg:VF28 Reg:VF24 | xscvdphp 60, 56	
  #|0xf3a06a47	XVSUBSP Reg:V29 Reg:V0 Reg:V13 | xvsubsp 61, 32, 45	
  #|0xf3a0e609	XVNMADDASP Reg:V29 Reg:V29 Reg:VSL0 Reg:VSL28 | xvnmaddasp 61, 0, 28	
  #|0xf3adf4b5	XXSEL Reg:V29 Reg:V13 Reg:VSL30 Reg:VSL18 | xxsel 61, 45, 30, 18	
  #|0xf3af4946	XSSUBDP Reg:F29 Reg:VF15 Reg:VF9 | xssubdp 29, 47, 41	
  #|0xf3b62447	XSMINCDP Reg:VF29 Reg:VF22 Reg:VF4 | xsmincdp 61, 54, 36	
  #|0xf3c6c382	XVMULDP Reg:VSL30 Reg:VSL6 Reg:V24 | xvmuldp 30, 6, 56	
  #|0xf3d3d5c8	XSNMSUBMDP Reg:F30 Reg:F30 Reg:F19 Reg:F26 | xsnmsubmdp 30, 19, 26	
  #|0xf3df04c7	XSMINJDP Reg:V30 Reg:VF31 Reg:VF0 | xsminjdp 62, 63, 32	
  #|0xf3e003e6	XVRDPIM Reg:VSL31 Reg:V0 | xvrdpim 31, 32	
  #|0xf3e00da6	XSNABSDP Reg:F31 Reg:VF1 | xsnabsdp 31, 33	
  #|0xf3e02ecb	XVNMSUBMSP Reg:V31 Reg:V31 Reg:VSL0 Reg:V5 | xvnmsubmsp 63, 0, 37	
  #|0xf3f7781d	XSCMPEQDP Reg:V31 Reg:VF23 Reg:F15 | xscmpeqdp 63, 55, 15	
  #|0xf3fcd4dc	XVSUBUHM Reg:VSL31 Reg:V28 Reg:VSL26 | xvsubuhm 31, 60, 26	
  #|0xf4000007	STXSSP Reg:VF0 Imm:4 Reg:ZERO | stxssp 0, 4(0)	may_store
  #|0xf4030005	STXV Reg:VSL0 Imm:0 Reg:R3 | stxv 0, 0(3)	may_store
  #|0xf4040001	LXV Reg:VSL0 Imm:0 Reg:R4 | lxv 0, 0(4)	may_load
  #|0xf404ffd9	LXV Reg:V0 Imm:-48 Reg:R4 | lxv 32, -48(4)	may_load
  #|0xf405000d	STXV Reg:V0 Imm:0 Reg:R5 | stxv 32, 0(5)	may_store
  #|0xf4149c06	STXSD Reg:VF0 Imm:-25596 Reg:R20 | stxsd 0, -25596(20)	may_store
  #|0xf4450002	STXSD Reg:VF2 Imm:0 Reg:R5 | stxsd 2, 0(5)	may_store
  #|0xf46d69e3	STXSSP Reg:VF3 Imm:27104 Reg:R13 | stxssp 3, 27104(13)	may_store
  #|0xf883d4ce	STQ Reg:X4 Imm:-11060 Reg:R3 | stq 4, -11060(3)	may_store
  #|0xfc000000	FCMPUS Reg:CR0 Reg:F0 Reg:F0 | fcmpu 0, 0, 0	
  #|0xfc000004	DADDQ Reg:Fpair0 Reg:Fpair0 Reg:Fpair0 | daddq 0, 0, 0	
  #|0xfc000007	DQUAQ_rec Reg:Fpair0 Reg:Fpair0 Reg:Fpair0 Imm:0 | dquaq. 0, 0, 0, 0	
  #|0xfc000018	FRSP Reg:F0 Reg:F0 | frsp 0, 0	
  #|0xfc000019	FRSP_rec Reg:F0 Reg:F0 | frsp. 0, 0	
  #|0xfc00001e	FCTIWZ Reg:F0 Reg:F0 | fctiwz 0, 0	
  #|0xfc000028	FSUB Reg:F0 Reg:F0 Reg:F0 | fsub 0, 0, 0	
  #|0xfc000050	FNEGS Reg:F0 Reg:F0 | fneg 0, 0	
  #|0xfc000072	FMUL Reg:F0 Reg:F0 Reg:F1 | fmul 0, 0, 1	
  #|0xfc000080	MCRFS Reg:CR0 Reg:CR0 | mcrfs 0, 0	
  #|0xfc000100	FTDIV Reg:CR0 Reg:F0 Reg:F0 | ftdiv 0, 0, 0	
  #|0xfc00010c	MTFSFI Imm:0 Imm:0 Imm:0 | mtfsfi 0, 0	
  #|0xfc0002c5	DXEXQ_rec Reg:F0 Reg:Fpair0 | dxexq. 0, 0	
  #|0xfc000390	FRIPS Reg:F0 Reg:F0 | frip 0, 0	
  #|0xfc000405	DSUBQ_rec Reg:Fpair0 Reg:Fpair0 Reg:Fpair0 | dsubq. 0, 0, 0	
  #|0xfc000504	DCMPUQ Reg:CR0 Reg:Fpair0 Reg:Fpair0 | dcmpuq 0, 0, 0	
  #|0xfc0005c6	DRINTNQ Reg:Fpair0 Imm:0 Reg:Fpair0 Imm:2 | drintnq 0, 0, 0, 2	
  #|0xfc00069c	FCFID Reg:F0 Reg:F0 | fcfid 0, 0	
  #|0xfc0006c8	XSIEXPQP Reg:V0 Reg:V0 Reg:F0 | xsiexpqp 0, 0, 0	
  #|0xfc00080a	XSRQPI Reg:V0 Imm:0 Reg:V1 Imm:0 | xsrqpi 0, 0, 1, 0	
  #|0xfc000824	FDIV Reg:F0 Reg:F0 Reg:F1 | fdiv 0, 0, 1	
  #|0xfc00082a	FADD Reg:F0 Reg:F0 Reg:F1 | fadd 0, 0, 1	
  #|0xfc00082c	FSQRT Reg:F0 Reg:F1 | fsqrt 0, 1	
  #|0xfc000834	FRSQRTE Reg:F0 Reg:F1 | frsqrte 0, 1	
  #|0xfc00083a	FMADD Reg:F0 Reg:F0 Reg:F0 Reg:F1 | fmadd 0, 0, 0, 1	
  #|0xfc000890	FMR Reg:F0 Reg:F1 | fmr 0, 1	
  #|0xfc000940	FTSQRT Reg:CR0 Reg:F1 | ftsqrt 0, 1	
  #|0xfc000a10	FABSS Reg:F0 Reg:F1 | fabs 0, 1	
  #|0xfc000e5e	FCTIDZ Reg:F0 Reg:F1 | fctidz 0, 1	
  #|0xfc00106e	FSELS Reg:F0 Reg:F0 Reg:F1 Reg:F2 | fsel 0, 0, 1, 2	
  #|0xfc001110	FNABSS Reg:F0 Reg:F2 | fnabs 0, 2	
  #|0xfc00113c	FNMSUB Reg:F0 Reg:F0 Reg:F4 Reg:F2 | fnmsub 0, 0, 4, 2	
  #|0xfc003404	DSUBQ Reg:Fpair0 Reg:Fpair0 Reg:Fpair6 | dsubq 0, 0, 6	
  #|0xfc006205	DCTQPQ_rec Reg:Fpair0 Reg:F12 | dctqpq. 0, 12	
  #|0xfc006604	DRDPQ Reg:Fpair0 Reg:Fpair12 | drdpq 0, 12	
  #|0xfc00665c	FCTID Reg:F0 Reg:F12 | fctid 0, 12	
  #|0xfc006984	DTSTDCQ Reg:CR0 Reg:Fpair0 Imm:26 | dtstdcq 0, 0, 26	
  #|0xfc006cc4	DSCRIQ Reg:Fpair0 Reg:Fpair0 Imm:27 | dscriq 0, 0, 27	
  #|0xfc007108	XSCMPOQP Reg:CR0 Reg:V0 Reg:V14 | xscmpoqp 0, 0, 14	
  #|0xfc008085	DSCLIQ_rec Reg:Fpair0 Reg:Fpair0 Imm:32 | dscliq. 0, 0, 32	
  #|0xfc0093d0	FRIMS Reg:F0 Reg:F18 | frim 0, 18	
  #|0xfc00ab51	FRIZS_rec Reg:F0 Reg:F21 | friz. 0, 21	
  #|0xfc00b010	FCPSGNS Reg:F0 Reg:F0 Reg:F22 | fcpsgn 0, 0, 22	
  #|0xfc00b01c	FCTIW Reg:F0 Reg:F22 | fctiw 0, 22	
  #|0xfc00b086	DQUAIQ Reg:Fpair0 Imm:0 Reg:Fpair22 Imm:0 | dquaiq 0, 0, 22, 0	
  #|0xfc00b6c4	DIEXQ Reg:Fpair0 Reg:F0 Reg:Fpair22 | diexq 0, 0, 22	
  #|0xfc00c447	DRRNDQ_rec Reg:Fpair0 Reg:F0 Reg:Fpair24 Imm:2 | drrndq. 0, 0, 24, 2	
  #|0xfc00c831	FRE_rec Reg:F0 Reg:F25 | fre. 0, 25	
  #|0xfc00d005	DADDQ_rec Reg:Fpair0 Reg:Fpair0 Reg:Fpair26 | daddq. 0, 0, 26	
  #|0xfc010029	FSUB_rec Reg:F0 Reg:F1 Reg:F0 | fsub. 0, 1, 0	
  #|0xfc010078	FMSUB Reg:F0 Reg:F1 Reg:F1 Reg:F0 | fmsub 0, 1, 1, 0	
  #|0xfc0b5d8f	MTFSF_rec Imm:5 Reg:F11 Imm:0 Imm:1 | mtfsf. 5, 11, 0, 1	
  #|0xfc0c0546	DTSTSFIQ Reg:CR0 Imm:12 Reg:Fpair0 | dtstsfiq 0, 12, 0	
  #|0xfc0c8c84	DSCLIQ Reg:Fpair0 Reg:Fpair12 Imm:35 | dscliq 0, 12, 35	
  #|0xfc1030c5	DSCRIQ_rec Reg:Fpair0 Reg:Fpair16 Imm:12 | dscriq. 0, 16, 12	
  #|0xfc160044	DMULQ Reg:Fpair0 Reg:Fpair22 Reg:Fpair0 | dmulq 0, 22, 0	
  #|0xfc160287	DQUAIQ_rec Reg:Fpair0 Imm:-10 Reg:Fpair0 Imm:1 | dquaiq. -10, 0, 0, 1	
  #|0xfc1a6144	DTSTEXQ Reg:CR0 Reg:Fpair26 Reg:Fpair12 | dtstexq 0, 26, 12	
  #|0xfc20011f	FCTIWUZ_rec Reg:F1 Reg:F0 | fctiwuz. 1, 0	
  #|0xfc20279c	FCFIDU Reg:F1 Reg:F4 | fcfidu 1, 4	
  #|0xfc203a11	FABSS_rec Reg:F1 Reg:F7 | fabs. 1, 7	
  #|0xfc20458e	MTFSF Imm:16 Reg:F8 Imm:0 Imm:0 | mtfsf 16, 8	
  #|0xfc407a04	DCTQPQ Reg:Fpair2 Reg:F15 | dctqpq 2, 15	
  #|0xfc4091c7	DRINTNQ_rec Reg:Fpair2 Imm:0 Reg:Fpair18 Imm:0 | drintnq. 0, 2, 18, 0	
  #|0xfc40f849	XSMULQPO Reg:V2 Reg:V0 Reg:V31 | xsmulqpo 2, 0, 31	
  #|0xfc4c0308	XSMADDQP Reg:V2 Reg:V2 Reg:V12 Reg:V0 | xsmaddqp 2, 12, 0	
  #|0xfc800840	FCMPOS Reg:CR1 Reg:F0 Reg:F1 | fcmpo 1, 0, 1	
  #|0xfc80c81f	FCTIWZ_rec Reg:F4 Reg:F25 | fctiwz. 4, 25	
  #|0xfc9e7544	DTSTSFQ Reg:CR1 Reg:F30 Reg:Fpair14 | dtstsfq 1, 30, 14	
  #|0xfcc00111	FNABSS_rec Reg:F6 Reg:F0 | fnabs. 6, 0	
  #|0xfcc08008	XSADDQP Reg:V6 Reg:V0 Reg:V16 | xsaddqp 6, 0, 16	
  #|0xfcc0fe45	DCFFIXQ_rec Reg:Fpair6 Reg:F31 | dcffixq. 6, 31	
  #|0xfcd003bb	FMADD_rec Reg:F6 Reg:F16 Reg:F14 Reg:F0 | fmadd. 6, 16, 14, 0	
  #|0xfcdb0348	XSMSUBQP Reg:V6 Reg:V6 Reg:V27 Reg:V0 | xsmsubqp 6, 27, 0	
  #|0xfcdc258f	MTFSF_rec Imm:110 Reg:F4 Imm:0 Imm:0 | mtfsf. 110, 4	
  #|0xfce00b09	XSMADDQPO Reg:V7 Reg:V7 Reg:V0 Reg:V1 | xsmaddqpo 7, 0, 1	
  #|0xfce05548	XSMAXCQP Reg:V7 Reg:V0 Reg:V10 | xsmaxcqp 7, 0, 10	
  #|0xfd00010d	MTFSFI_rec Imm:2 Imm:0 Imm:0 | mtfsfi. 2, 0	
  #|0xfd009bd1	FRIMS_rec Reg:F8 Reg:F19 | frim. 8, 19	
  #|0xfd00c75f	FCTIDUZ_rec Reg:F8 Reg:F24 | fctiduz. 8, 24	
  #|0xfd00f891	FMR_rec Reg:F8 Reg:F31 | fmr. 8, 31	
  #|0xfd0500c8	XSCPSGNQP Reg:V8 Reg:V5 Reg:V0 | xscpsgnqp 8, 5, 0	
  #|0xfd160409	XSSUBQPO Reg:V8 Reg:V22 Reg:V0 | xssubqpo 8, 22, 0	
  #|0xfd20b6f9	FMSUB_rec Reg:F9 Reg:F0 Reg:F27 Reg:F22 | fmsub. 9, 0, 27, 22	
  #|0xfd210349	XSMSUBQPO Reg:V9 Reg:V9 Reg:V1 Reg:V0 | xsmsubqpo 9, 1, 0	
  #|0xfd26a5c8	XSMINCQP Reg:V9 Reg:V6 Reg:V20 | xsmincqp 9, 6, 20	
  #|0xfd3b0188	XSCMPGEQP Reg:V9 Reg:V27 Reg:V0 | xscmpgeqp 9, 27, 0	
  #|0xfd4062be	FNMADD Reg:F10 Reg:F0 Reg:F10 Reg:F12 | fnmadd 10, 0, 10, 12	
  #|0xfd40d644	DCFFIXQ Reg:Fpair10 Reg:F26 | dcffixq 10, 26	
  #|0xfd49e3c9	XSNMSUBQPO Reg:V10 Reg:V10 Reg:V9 Reg:V28 | xsnmsubqpo 10, 9, 28	
  #|0xfd800508	XSCMPUQP Reg:CR3 Reg:V0 Reg:V0 | xscmpuqp 3, 0, 0	
  #|0xfd8021c4	DTSTDGQ Reg:CR3 Reg:Fpair0 Imm:8 | dtstdgq 3, 0, 8	
  #|0xfd80d448	XSDIVQP Reg:V12 Reg:V0 Reg:V26 | xsdivqp 12, 0, 26	
  #|0xfda0681d	FCTIW_rec Reg:F13 Reg:F13 | fctiw. 13, 13	
  #|0xfdc002c6	DRINTXQ Reg:Fpair14 Imm:0 Reg:Fpair0 Imm:1 | drintxq 0, 14, 0, 1	
  #|0xfdc10011	FCPSGNS_rec Reg:F14 Reg:F1 Reg:F0 | fcpsgn. 14, 1, 0	
  #|0xfddb0246	DRRNDQ Reg:Fpair14 Reg:F27 Reg:Fpair0 Imm:1 | drrndq 14, 27, 0, 1	
  #|0xfdfb01c8	XSCMPGTQP Reg:V15 Reg:V27 Reg:V0 | xscmpgtqp 15, 27, 0	
  #|0xfe174148	XSCMPEXPQP Reg:CR4 Reg:V23 Reg:V8 | xscmpexpqp 4, 23, 8	
  #|0xfe200030	FRE Reg:F17 Reg:F0 | fre 17, 0	
  #|0xfe200245	DCTFIXQ_rec Reg:F17 Reg:Fpair0 | dctfixq. 17, 0	
  #|0xfe20e91d	FCTIWU_rec Reg:F17 Reg:F29 | fctiwu. 17, 29	
  #|0xfe400206	DQUAQ Reg:Fpair18 Reg:Fpair0 Reg:Fpair0 Imm:1 | dquaq 18, 0, 0, 1	
  #|0xfe60de5d	FCTID_rec Reg:F19 Reg:F27 | fctid. 19, 27	
  #|0xfe800051	FNEGS_rec Reg:F20 Reg:F0 | fneg. 20, 0	
  #|0xfe8002c7	DRINTXQ_rec Reg:Fpair20 Imm:0 Reg:Fpair0 Imm:1 | drintxq. 0, 20, 0, 1	
  #|0xfe800445	DDIVQ_rec Reg:Fpair20 Reg:Fpair0 Reg:Fpair0 | ddivq. 20, 0, 0	
  #|0xfe80065f	FCTIDZ_rec Reg:F20 Reg:F0 | fctidz. 20, 0	
  #|0xfe80069d	FCFID_rec Reg:F20 Reg:F0 | fcfid. 20, 0	
  #|0xfe805835	FRSQRTE_rec Reg:F20 Reg:F11 | frsqrte. 20, 11	
  #|0xfea00f5c	FCTIDU Reg:F21 Reg:F1 | fctidu 21, 1	
  #|0xfea0bb11	FRINS_rec Reg:F21 Reg:F23 | frin. 21, 23	
  #|0xfec0a605	DRDPQ_rec Reg:Fpair22 Reg:Fpair20 | drdpq. 22, 20	
  #|0xfec38b7f	FNMADD_rec Reg:F22 Reg:F3 Reg:F13 Reg:F17 | fnmadd. 22, 3, 13, 17	
  #|0xfed63d88	XSTSTDCQP Reg:CR5 Imm:86 Reg:V7 | xststdcqp 5, 7, 86	
  #|0xfeff058e	MTFSF Imm:127 Reg:F0 Imm:1 Imm:1 | mtfsf 127, 0, 1, 1	
  #|0xff00691c	FCTIWU Reg:F24 Reg:F13 | fctiwu 24, 13	
  #|0xff006f9d	FCFIDU_rec Reg:F24 Reg:F13 | fcfidu. 24, 13	
  #|0xff009045	DMULQ_rec Reg:Fpair24 Reg:Fpair0 Reg:Fpair18 | dmulq. 24, 0, 18	
  #|0xff00d350	FRIZS Reg:F24 Reg:F26 | friz 24, 26	
  #|0xff1615bd	FNMSUB_rec Reg:F24 Reg:F22 Reg:F22 Reg:F2 | fnmsub. 24, 22, 22, 2	
  #|0xff20075e	FCTIDUZ Reg:F25 Reg:F0 | fctiduz 25, 0	
  #|0xff202f5d	FCTIDU_rec Reg:F25 Reg:F5 | fctidu. 25, 5	
  #|0xff20402b	FADD_rec Reg:F25 Reg:F0 Reg:F8 | fadd. 25, 0, 8	
  #|0xff3e0025	FDIV_rec Reg:F25 Reg:F30 Reg:F0 | fdiv. 25, 30, 0	
  #|0xff3f7048	XSMULQP Reg:V25 Reg:V31 Reg:V14 | xsmulqp 25, 31, 14	
  #|0xff40591e	FCTIWUZ Reg:F26 Reg:F11 | fctiwuz 26, 11	
  #|0xff40d64a	XSRQPXP Reg:V26 Imm:0 Reg:V26 Imm:3 | xsrqpxp 0, 26, 26, 3	
  #|0xff40e82d	FSQRT_rec Reg:F26 Reg:F29 | fsqrt. 26, 29	
  #|0xff4e02f3	FMUL_rec Reg:F26 Reg:F14 Reg:F11 | fmul. 26, 14, 11	
  #|0xff53f6c5	DIEXQ_rec Reg:Fpair26 Reg:F19 Reg:Fpair30 | diexq. 26, 19, 30	
  #|0xff60008c	MTFSB0 Imm:27 | mtfsb0 27	
  #|0xff6002c4	DXEXQ Reg:F27 Reg:Fpair0 | dxexq 27, 0	
  #|0xff600391	FRIPS_rec Reg:F27 Reg:F0 | frip. 27, 0	
  #|0xff80004c	MTFSB1 Imm:28 | mtfsb1 28	
  #|0xff800104	DCMPOQ Reg:CR7 Reg:Fpair0 Reg:Fpair0 | dcmpoq 7, 0, 0	
  #|0xff80048f	MFFS_rec Reg:F28 | mffs. 28	
  #|0xff805244	DCTFIXQ Reg:F28 Reg:Fpair10 | dctfixq 28, 10	
  #|0xff9aa444	DDIVQ Reg:Fpair28 Reg:Fpair26 Reg:Fpair20 | ddivq 28, 26, 20	
  #|0xff9cfc49	XSDIVQPO Reg:V28 Reg:V28 Reg:V31 | xsdivqpo 28, 28, 31	
  #|0xff9d3b89	XSNMADDQPO Reg:V28 Reg:V28 Reg:V29 Reg:V7 | xsnmaddqpo 28, 29, 7	
  #|0xffa00009	XSADDQPO Reg:V29 Reg:V0 Reg:V0 | xsaddqpo 29, 0, 0	
  #|0xffa30408	XSSUBQP Reg:V29 Reg:V3 Reg:V0 | xssubqp 29, 3, 0	
  #|0xffadabc8	XSNMSUBQP Reg:V29 Reg:V29 Reg:V13 Reg:V21 | xsnmsubqp 29, 13, 21	
  #|0xffb7cb88	XSNMADDQP Reg:V29 Reg:V29 Reg:V23 Reg:V25 | xsnmaddqp 29, 23, 25	
  #|0xffc05e0b	XSRQPIX Reg:V30 Imm:0 Reg:V11 Imm:3 | xsrqpix 0, 30, 11, 3	
  #|0xffc3cb2f	FSELS_rec Reg:F30 Reg:F3 Reg:F12 Reg:F25 | fsel. 30, 3, 12, 25	
  #|0xffe00310	FRINS Reg:F31 Reg:F0 | frin 31, 0	
  #|0xffff3888	XSCMPEQQP Reg:V31 Reg:V31 Reg:V7 | xscmpeqqp 31, 31, 7

///|
fn hex_word(s : StringView) -> UInt {
  s.fold(init=0U, (v, c) => {
    let d = if c >= 'a' {
      c.to_int() - 'a'.to_int() + 10
    } else {
      c.to_int() - '0'.to_int()
    }
    (v << 4) | d.reinterpret_as_uint()
  })
}

///|
test "every table-decoded LLVM sample decodes like llvm-mc, in both modes" {
  let names : Map[String, Unit] = Map([])
  let mut count = 0
  for line in llvm_ext_samples.split("\n") {
    guard !line.is_empty() else { continue }
    let fields = line.split("\t").collect()
    let word = hex_word(fields[0][2:])
    for mode in [@powerpc.AddrSize::R64, R32] {
      guard @powerpc.decode_word(word, 0x1000, mode~) is Some(insn) else {
        fail("\{fields[0]}: not decoded, expected \{fields[1]}")
      }
      assert_eq(
        render_llvm(insn),
        fields[1].to_owned(),
        msg=fields[0].to_owned(),
      )
      assert_eq(
        llvm_kinds(insn),
        sorted_kinds(fields.get(2).map(k => k.to_owned()).unwrap_or("")),
        msg=fields[0].to_owned(),
      )
      names[insn.name()] = ()
    }
    count += 1
  }
  inspect(count, content="1639")
  // the number of distinct LLVM opcodes covered by the samples
  inspect(names.length(), content="1171")
}

///|
test "table-decoded instructions lift as unsupported, never as errors" {
  let failed = []
  let mut lifted = 0
  for line in llvm_ext_samples.split("\n") {
    guard !line.is_empty() else { continue }
    let word = hex_word(line[2:10])
    guard @powerpc.decode_word(word, 0x1000, mode=R64) is Some(insn) else {
      fail("not decoded")
    }
    try @powerpc.lift64(insn) catch {
      Unsupported(..) => ()
      err => failed.push("\{insn.name()}: \{err.message()}")
    } noraise {
      _ => lifted += 1
    }
  }
  inspect(failed.join("\n"), content="")
  inspect(lifted, content="0")
}
