// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let sse64_cases : String =
  #|pxor xmm5, xmm3|660fefeb|PXORrr:%XMM5,%XMM5,%XMM3|xmm3=8c6fd81407da6de936def9c919e3bf7c xmm5=436b250388d22e7f875de902379b2c75 f=842|xmm5=cf04fd178f084396b18310cb2e789309 f=840/0
  #|pxor xmm5, xmm3|660fefeb|PXORrr:%XMM5,%XMM5,%XMM3|xmm3=0 xmm5=84d1b7324fbc2f916c5e7eb8a02c45e1 f=c6|f=c4/0
  #|pxor xmm5, xmmword ptr [rsi]|660fef2e|PXORrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=e r9=1 xmm5=9db0be468a668c2830e1568e2191d4b4 f=857 m10080=48c68ae1b38533c69826fcdb4c6bf894|xmm5=948d50a519aaab0f6d2d33dc01b12fc f=855/0
  #|pand xmm4, xmm1|660fdbe1|PANDrr:%XMM4,%XMM4,%XMM1|xmm1=ffffffffffffffffffffffffffffffff xmm4=0 f=8c3|f=8c1/0
  #|pand xmm4, xmm1|660fdbe1|PANDrr:%XMM4,%XMM4,%XMM1|xmm1=7f5052aaca2e03a5d3b40d7603234752 xmm4=ad79c173845b7e2a42318c089108b5b8 f=d2|xmm4=2d504022800a022042300c0001000510 f=d0/0
  #|pand xmm4, xmmword ptr [rsi]|660fdb26|PANDrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=b r9=7 xmm4=562a695be01e089f6faf89003a5a13fb f=c43 m10080=eccd905fdcdf0673125c6f58574701b3|xmm4=12004153400e0812630689001a1001e8 f=c41/0
  #|por xmm6, xmm7|660febf7|PORrr:%XMM6,%XMM6,%XMM7|xmm6=ec447f83ed02c104f0342775c9e8b2c7 xmm7=db7c3e1f7e21e8a1fce5cf5fbaa327c7 f=857|xmm6=ff7c7f9fff23e9a5fcf5ef7ffbebb7c7 f=855/0
  #|por xmm6, xmm7|660febf7|PORrr:%XMM6,%XMM6,%XMM7|xmm6=80008000800080008000800080008000 xmm7=e02cf4e6ba20b7674e926fd4d5a960d5 f=c42|xmm6=e02cf4e6ba20b767ce92efd4d5a9e0d5 f=c40/0
  #|por xmm6, xmmword ptr [rsi]|660feb36|PORrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=2 r9=0 xmm6=80008000800080008000800080008000 f=cc3 m10080=70a04a7029e4747e1478532fc9991a7f|xmm6=ff1a99c9af53f814fe74e429f04aa070 f=cc1/0
  #|pandn xmm5, xmm6|660fdfee|PANDNrr:%XMM5,%XMM5,%XMM6|xmm5=5a71e51ebe395fb4ef57758e9f233371 xmm6=c571afee797f174fe0c7471510259ceb f=82|xmm5=85000ae04146004b0080021100048c8a f=80/0
  #|pandn xmm5, xmm6|660fdfee|PANDNrr:%XMM5,%XMM5,%XMM6|xmm5=0 xmm6=d3ad29d699e4588d8a9476342703db9a f=c53|xmm5=d3ad29d699e4588d8a9476342703db9a f=c51/0
  #|pandn xmm5, xmmword ptr [rsi]|660fdf2e|PANDNrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=8 r9=0 xmm5=300151d1483b11b8a420e1712b52b7bf f=c86 m10080=42ef4cc3a65d07eb02d7938a402e006b|xmm5=4b002e008280c6024b071c86c00c4840 f=c84/0
  #|paddb xmm4, xmm0|660ffce0|PADDBrr:%XMM4,%XMM4,%XMM0|xmm0=e739ade84019c50a962af7d71a82b0c7 xmm4=56a923418f5874603ca03a1a877dcc43 f=846|xmm4=3de2d029cf71396ad2ca31f1a1ff7c0a f=844/0
  #|paddb xmm4, xmm0|660ffce0|PADDBrr:%XMM4,%XMM4,%XMM0|xmm0=c34745447230274c2ef6c48f8f1eedc xmm4=887e26e8f0e5e0921dfea6073ff064aa f=853|xmm4=94b29a3c3708e206dfed124f37e15286 f=851/0
  #|paddb xmm4, xmmword ptr [rsi]|660ffc26|PADDBrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=1 r9=c xmm4=9e4fe5bbca1a665dcb13cede02bbc871 f=52 m10080=37d2b964199b74993a3e30639297ac68|xmm4=6fb7c4d2d4aa497648769f766749aa8 f=50/0
  #|paddw xmm10, xmm3|66440ffdd3|PADDWrr:%XMM10,%XMM10,%XMM3|xmm3=4003909d539a012db519e0d3f5f347bd xmm10=b031c9ef9fbee802cded7acb075c8c5c f=c97|xmm10=f0345a8cf358e92f83065b9efd4fd419 f=c95/0
  #|paddw xmm10, xmm3|66440ffdd3|PADDWrr:%XMM10,%XMM10,%XMM3|xmm3=9290158a11ff1c782c8b17a61f57940a xmm10=c1999795c55d93c02a4d7a5df597ccb4 f=4c6|xmm10=5429ad1fd75cb03856d8920314ee60be f=4c4/0
  #|paddw xmm10, xmmword ptr [rsi]|66440ffd16|PADDWrm:%XMM10,%XMM10,%RSI,1,%,0,%|rbx=6 r9=8 xmm10=e360c9cbd41879185d91d86a38a566a1 f=887 m10080=9dedc07d9981e59af5c210c76663acd1|xmm10=b50c2d319b283c0df8765a03b665543e f=885/0
  #|paddd xmm7, xmm2|660ffefa|PADDDrr:%XMM7,%XMM7,%XMM2|xmm2=7d32f2b0f9c3110d63bbeec8ba8410ca xmm7=44d5faae97936682e1186fada60d1567 f=16|xmm7=c208ed5e9156778f44d45e7560912631 f=14/0
  #|paddd xmm7, xmm2|660ffefa|PADDDrr:%XMM7,%XMM7,%XMM2|xmm2=889faf6f8907d0b5201aef30d2eedcd5 xmm7=0 f=cc2|xmm7=889faf6f8907d0b5201aef30d2eedcd5 f=cc0/0
  #|paddd xmm7, xmmword ptr [rsi]|660ffe3e|PADDDrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=0 r9=3 xmm7=458ad765fcfcdc68ef5919d6e9d460e0 f=3 m10080=73a3842bd8fa2b32985d3ba15d1d4974|xmm7=b9d3f4c29e383a00218514ae15590453 f=1/0
  #|paddq xmm4, xmm0|660fd4e0|PADDQrr:%XMM4,%XMM4,%XMM0|xmm0=36ec1f83c9a3c69b624ba8c3993968ed xmm4=80008000800080008000800080008000 f=2|xmm4=b6ec9f8449a4469be24c28c41939e8ed f=0/0
  #|paddq xmm4, xmm0|660fd4e0|PADDQrr:%XMM4,%XMM4,%XMM0|xmm0=f72397b013b452808c6b88bc90ff2e6f xmm4=8ff66382f70331fd0d60eaeef02b9a4 f=c07|xmm4=22fde84324859f5d41976b8001e813 f=c05/0
  #|paddq xmm4, xmmword ptr [rsi]|660fd426|PADDQrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=a r9=3 xmm4=bbb0ad5aa07f0dd6210a23d19b481392 f=c6 m10080=8d2b03799bd43cb18904aa5d2e1f073b|xmm4=f6b7cc88fe29125fd246f86d144b3f1f f=c4/0
  #|psubb xmm2, xmm1|660ff8d1|PSUBBrr:%XMM2,%XMM2,%XMM1|xmm1=f83bf78ba4c108d208f9416a72bc49d1 xmm2=5b344394c4c100349cffc86246bb603a f=847|xmm2=63f94c092000f862940687f8d4ff1769 f=845/0
  #|psubb xmm2, xmm1|660ff8d1|PSUBBrr:%XMM2,%XMM2,%XMM1|xmm1=5fe53a7571734c35bd2c5181a2df6c35 xmm2=1792c8113ec07971749aba088a7d9674 f=92|xmm2=b8ad8e9ccd4d2d3cb76e6987e89e2a3f f=90/0
  #|psubb xmm2, xmmword ptr [rsi]|660ff816|PSUBBrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=7 r9=3 xmm2=a783b3e3cec37575bbf6249a8ab92cec f=87 m10080=d3fe46f82983ba21183f2a296bd2d619|xmm2=8eade178a599365d9a3ca17192732e19 f=85/0
  #|psubw xmm9, xmm6|66440ff9ce|PSUBWrr:%XMM9,%XMM9,%XMM6|xmm6=b7b02bf97d11cfd9ef02c5302348b439 xmm9=80008000800080008000800080008000 f=56|xmm9=c850540702efb02790febad05cb8cbc7 f=54/0
  #|psubw xmm9, xmm6|66440ff9ce|PSUBWrr:%XMM9,%XMM9,%XMM6|xmm6=173e5927d6fc96cf640bcaf54027a775 xmm9=d9c104e4189f0f91358313e947561ed3 f=cd6|xmm9=c283abbd41a378c2d17848f4072f775e f=cd4/0
  #|psubw xmm9, xmmword ptr [rsi]|66440ff90e|PSUBWrm:%XMM9,%XMM9,%RSI,1,%,0,%|rbx=e r9=f xmm9=0 f=406 m10080=5590eee2ac8983c2c3dc4c4b69cfc2cc|xmm9=333e3097b4b4233d3d7d76541d126fab f=404/0
  #|psubd xmm2, xmm7|660ffad7|PSUBDrr:%XMM2,%XMM2,%XMM7|xmm2=46ca56f8ebad886f674fe3137e1cfb40 xmm7=3d79dac2979a8a70fc4a160721e29193 f=82|xmm2=9507c365412fdff6b05cd0c5c3a69ad f=80/0
  #|psubd xmm2, xmm7|660ffad7|PSUBDrr:%XMM2,%XMM2,%XMM7|xmm2=a97784d32d05f1772fad9eb023b80ca6 xmm7=d3dcfbbbef4a2b5a7cd5eb76b91f2592 f=c2|xmm2=d59a89183dbbc61db2d7b33a6a98e714 f=c0/0
  #|psubd xmm2, xmmword ptr [rsi]|660ffa16|PSUBDrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=f r9=0 xmm2=1517e7939a7f83b6d986e250be5589c8 f=8c6 m10080=701349dd684c0cb52ff787144657e90f|xmm2=52e904d85f78c87247a95e8e10c7658 f=8c4/0
  #|psubq xmm7, xmm2|660ffbfa|PSUBQrr:%XMM7,%XMM7,%XMM2|xmm2=165cdaf933cb45abb439390884ef0f9b xmm7=f56b57a947c3f45e3149961bc5e6c460 f=83|xmm7=df0e7cb013f8aeb37d105d1340f7b4c5 f=81/0
  #|psubq xmm7, xmm2|660ffbfa|PSUBQrr:%XMM7,%XMM7,%XMM2|xmm2=4993bef37f856bdbf9366546943a838c xmm7=80008000800080008000800080008000 f=853|xmm7=366cc10d007b142586ca1ab9ebc5fc74 f=851/0
  #|psubq xmm7, xmmword ptr [rsi]|660ffb3e|PSUBQrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=d r9=2 xmm7=9a1df447c5d62e1ec722c8ce7e8393fd f=882 m10080=33077bccf58d99ab993994d6a5f3e5c2|xmm7=d73800a1ef41f4851b893ad8b2088cca f=880/0
  #|paddsb xmm0, xmm7|660fecc7|PADDSBrr:%XMM0,%XMM0,%XMM7|xmm0=0 xmm7=1ed4586c9b4637c7a6318917fc874228 f=92|xmm0=1ed4586c9b4637c7a6318917fc874228 f=90/0
  #|paddsb xmm0, xmm7|660fecc7|PADDSBrr:%XMM0,%XMM0,%XMM7|xmm0=cf49f047bb39cb61ffec6566b1b6106f xmm7=53d0ce457c22c2e98172691710abeeb2 f=897|xmm0=2219be7f375b8d4a805e7f7dc180fe21 f=895/0
  #|paddsb xmm0, xmmword ptr [rsi]|660fec06|PADDSBrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=1 r9=1 xmm0=31f03becdaacd3da8206910d0f89c228 f=8c6 m10080=c4efbc25aacbe82e90bf4824ba68f223|xmm0=54e27fa6fef49280b0ee80b73480b1ec f=8c4/0
  #|paddsw xmm5, xmm7|660fedef|PADDSWrr:%XMM5,%XMM5,%XMM7|xmm5=bc44232bab962b000029bf2e29151edc xmm7=1a2d847679825442a7e01e9c83f7f708 f=853|xmm5=d671a7a125187f42a809ddcaad0c15e4 f=851/0
  #|paddsw xmm5, xmm7|660fedef|PADDSWrr:%XMM5,%XMM5,%XMM7|xmm5=a9fdc8c4ec4572edd56eb245009761b7 xmm7=8394402737ea3c08d42bf4adb5ad5415 f=8c6|xmm5=800008eb242f7fffa999a6f2b6447fff f=8c4/0
  #|paddsw xmm5, xmmword ptr [rsi]|660fed2e|PADDSWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=1 r9=3 xmm5=a56f80d608cde6544657bf407b466441 f=53 m10080=dca60bb893fe52fe34a4e60d78ba5407|xmm5=acc3800016b38a8844a9bdd333510b1d f=51/0
  #|paddusb xmm9, xmm3|66440fdccb|PADDUSBrr:%XMM9,%XMM9,%XMM3|xmm3=f0c0e855ebe72dc320cfcf1ffabf6a85 xmm9=102fedddd2e2ad04236532adfe02a5b3 f=52|xmm9=ffefffffffffdac743ffffccffc1ffff f=50/0
  #|paddusb xmm9, xmm3|66440fdccb|PADDUSBrr:%XMM9,%XMM9,%XMM3|xmm3=6dca9fcfbcfcb782c77b369d88e27be2 xmm9=1bc42029cfc8f93a932ccbe5281ee90b f=57|xmm9=88ffbff8ffffffbcffa7ffffb0ffffed f=55/0
  #|paddusb xmm9, xmmword ptr [rsi]|66440fdc0e|PADDUSBrm:%XMM9,%XMM9,%RSI,1,%,0,%|rbx=3 r9=8 xmm9=d60b70748f9acfbc582fec84bc64f552 f=83 m10080=1cd6ddae5af08833f68ed93b49560ba9|xmm9=ff16c6bdcaffffff8bb7ffdeffffff6e f=81/0
  #|paddusw xmm1, xmm6|660fddce|PADDUSWrr:%XMM1,%XMM1,%XMM6|xmm1=9d36c26c281d59ab26e7ac3deea74b7b xmm6=80008000800080008000800080008000 f=57|xmm1=ffffffffa81dd9aba6e7ffffffffcb7b f=55/0
  #|paddusw xmm1, xmm6|660fddce|PADDUSWrr:%XMM1,%XMM1,%XMM6|xmm1=794345aa14a5440f7ebf7ef7c11bd6b8 xmm6=c48990cd15f5bf8e9604051bbd871eff f=c6|xmm1=ffffd6772a9affffffff8412fffff5b7 f=c4/0
  #|paddusw xmm1, xmmword ptr [rsi]|660fdd0e|PADDUSWrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=4 r9=f xmm1=c715218e82dc8ea953aec664e11e1fbf f=4c7 m10080=30d6eafd2033f28bd34fac79a57d07a3|xmm1=ffff9f33fc88de7cdfa0f984fffff5ef f=4c5/0
  #|psubsb xmm5, xmm3|660fe8eb|PSUBSBrr:%XMM5,%XMM5,%XMM3|xmm3=96f259e4c7e30caab13446c885ef17fb xmm5=61967a2158d014daf976701cc7f97f4c f=c06|xmm5=7fa4213d7fed083048422a54420a6851 f=c04/0
  #|psubsb xmm5, xmm3|660fe8eb|PSUBSBrr:%XMM5,%XMM5,%XMM3|xmm3=b57097070256f44ea2a2e078ad875b68 xmm5=aa325c9d5b6d526f575aa05ed7cd8d87 f=882|xmm5=f5c27f9659175e217f7fc0e62a468080 f=880/0
  #|psubsb xmm5, xmmword ptr [rsi]|660fe82e|PSUBSBrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=3 r9=4 xmm5=89d555d21ac521b7406646c94b6baefd f=92 m10080=dbd794da6e9b9cabc5c4e9b2421e90ea|xmm5=9f45379068dc5df27f7f7f80717fd722 f=90/0
  #|psubsw xmm3, xmm7|660fe9df|PSUBSWrr:%XMM3,%XMM3,%XMM7|xmm3=80008000800080008000800080008000 xmm7=6e5259f51d4a100130061a16dc3c4fb2 f=843|xmm3=800080008000800080008000a3c48000 f=841/0
  #|psubsw xmm3, xmm7|660fe9df|PSUBSWrr:%XMM3,%XMM3,%XMM7|xmm3=0 xmm7=0 f=53|f=51/0
  #|psubsw xmm3, xmmword ptr [rsi]|660fe91e|PSUBSWrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=9 r9=9 xmm3=4876a8bf24030b9a68d889f7c6af8e79 f=886 m10080=58b91858bf27229f1361bad20db31f7a|xmm3=ce57f5b25149aa877fff80008000d521 f=884/0
  #|psubusb xmm2, xmm4|660fd8d4|PSUBUSBrr:%XMM2,%XMM2,%XMM4|xmm2=136dbbec1ce6692ef786c8fa02948c2 xmm4=89dfae6031017c213087e42fb2211041 f=802|xmm2=2d5e90cd0071bf00006000083881 f=800/0
  #|psubusb xmm2, xmm4|660fd8d4|PSUBUSBrr:%XMM2,%XMM2,%XMM4|xmm2=d260818c0e1f7630f85012d56b4c4efc xmm4=40efafde53504d378b5485f02c0c810c f=92|xmm2=92000000000029006d0000003f4000f0 f=90/0
  #|psubusb xmm2, xmmword ptr [rsi]|660fd816|PSUBUSBrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=c r9=5 xmm2=146191a162725dd60a32d65a425450fa f=846 m10080=5e72dff46b6880ba398de9d859c877fe|xmm2=480000009d00006e000000009c f=844/0
  #|psubusw xmm2, xmm5|660fd9d5|PSUBUSWrr:%XMM2,%XMM2,%XMM5|xmm2=4189b95f82049cb940bda4d5debe7d7e xmm5=558702e91389c99bc878cce412fd615b f=847|xmm2=b6766e7b000000000000cbc11c23 f=845/0
  #|psubusw xmm2, xmm5|660fd9d5|PSUBUSWrr:%XMM2,%XMM2,%XMM5|xmm2=80008000800080008000800080008000 xmm5=a60caf639f7c7d30492f01c45cb1bdd1 f=c2|xmm2=2d036d17e3c234f0000 f=c0/0
  #|psubusw xmm2, xmmword ptr [rsi]|660fd916|PSUBUSWrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=b r9=1 xmm2=766e55d9f843c20fb56e2c6a1e6f9794 f=83 m10080=f828f5ef8b5dae0232bd4fd912e0d0e4|xmm2=1ef404ddb2c0000000006e9c f=81/0
  #|pcmpeqb xmm2, xmm0|660f74d0|PCMPEQBrr:%XMM2,%XMM2,%XMM0|xmm0=dbe70f7c4ba7ba2de4b27f4e49930b93 xmm2=da2ef2eaea08f7cf37afc1e163e2b2f0 f=c3|xmm2=0 f=c1/0
  #|pcmpeqb xmm2, xmm0|660f74d0|PCMPEQBrr:%XMM2,%XMM2,%XMM0|xmm0=4de67c896cdaef2ecca37603bab8741b xmm2=7f300e4ae9d0ba82268eff29598cb3e4 f=817|xmm2=0 f=815/0
  #|pcmpeqb xmm2, xmmword ptr [rsi]|660f7416|PCMPEQBrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=a r9=4 xmm2=efa00333e49bdaf0b203c87f4db36ee4 f=816 m10080=14ccfa77e25de53582d5128b04a3fdba|xmm2=0 f=814/0
  #|pcmpeqw xmm11, xmm14|66450f75de|PCMPEQWrr:%XMM11,%XMM11,%XMM14|xmm11=d644069fc947819f0d0cbc9b3d5a64dd xmm14=8a6be51f880cac92108a3fa21751d6a9 f=812|xmm11=0 f=810/0
  #|pcmpeqw xmm11, xmm14|66450f75de|PCMPEQWrr:%XMM11,%XMM11,%XMM14|xmm11=db30f2f6a9bf524c94b648d135fbb026 xmm14=d43eae6cc1fb7c1e8dc0e54178d5a25c f=813|xmm11=0 f=811/0
  #|pcmpeqw xmm11, xmmword ptr [rsi]|66440f751e|PCMPEQWrm:%XMM11,%XMM11,%RSI,1,%,0,%|rbx=b r9=1 xmm11=e346c39e2ff3a70cd459517ec26b944 f=53 m10080=e1192af63ca8d12c27ce91bd9aa7116c|xmm11=0 f=51/0
  #|pcmpeqd xmm12, xmm6|66440f76e6|PCMPEQDrr:%XMM12,%XMM12,%XMM6|xmm6=54b6b9c8d8e6cde93ebd37f7b65afa2c xmm12=476093f69201303b363ebe9b2bac6e1b f=c06|xmm12=0 f=c04/0
  #|pcmpeqd xmm12, xmm6|66440f76e6|PCMPEQDrr:%XMM12,%XMM12,%XMM6|xmm6=fd7c46ba2a941ffe4bd40e5978c4e540 xmm12=5fce316fa22c46346cc3ca6475ec98b2 f=893|xmm12=0 f=891/0
  #|pcmpeqd xmm12, xmmword ptr [rsi]|66440f7626|PCMPEQDrm:%XMM12,%XMM12,%RSI,1,%,0,%|rbx=3 r9=8 xmm12=8438c0df94de6889eee2bde7091ee6cc f=c12 m10080=e64a24fd8265ee74cb8920ac9175a385|xmm12=0 f=c10/0
  #|pcmpeqq xmm6, xmm1|660f3829f1|PCMPEQQrr:%XMM6,%XMM6,%XMM1|xmm1=cebc21dd27ce3870904905f1cdf43db xmm6=98d2c5a38468c3963393bf077af3745a f=17|xmm6=0 f=15/0
  #|pcmpeqq xmm6, xmm1|660f3829f1|PCMPEQQrr:%XMM6,%XMM6,%XMM1|xmm1=9316b4ad27be6133db06bc143290d78b xmm6=cd725705f5c409ba1345d07a405361a2 f=cd2|xmm6=0 f=cd0/0
  #|pcmpeqq xmm6, xmmword ptr [rsi]|660f382936|PCMPEQQrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=3 r9=5 xmm6=8c2d40686ad241cb3eb34833a6bf1236 f=843 m10080=652a1730c40de61c2bab3bd9a432798e|xmm6=0 f=841/0
  #|pcmpgtb xmm11, xmm5|66440f64dd|PCMPGTBrr:%XMM11,%XMM11,%XMM5|xmm5=23fe099e93a8719386b7f2f2f7f6cf24 xmm11=f2be9662f6e76e8950771b41de9f9383 f=d2|xmm11=ffffff0000ffffffff00000000 f=d0/0
  #|pcmpgtb xmm11, xmm5|66440f64dd|PCMPGTBrr:%XMM11,%XMM11,%XMM5|xmm5=b1c77e58fe65f8cdaaa35ae254736727 xmm11=80008000800080008000800080008000 f=803|xmm11=ff0000000000ff00ff00ff00000000 f=801/0
  #|pcmpgtb xmm11, xmmword ptr [rsi]|66440f641e|PCMPGTBrm:%XMM11,%XMM11,%RSI,1,%,0,%|rbx=f r9=7 xmm11=f4e7dd461dc834317add0704c397daec f=42 m10080=39f453eaf887e48948961453e495313c|xmm11=ffff0000ff00ff00ffff00000000 f=40/0
  #|pcmpgtw xmm1, xmm7|660f65cf|PCMPGTWrr:%XMM1,%XMM1,%XMM7|xmm1=10d5ab5ab1100fdb36e4c503455413e2 xmm7=ffffffffffffffffffffffffffffffff f=846|xmm1=ffff00000000ffffffff0000ffffffff f=844/0
  #|pcmpgtw xmm1, xmm7|660f65cf|PCMPGTWrr:%XMM1,%XMM1,%XMM7|xmm1=6a89a4f2c141d3708831893d211f2bad xmm7=7889356f77cfaebfdd29c023c3fe66c2 f=83|xmm1=ffff00000000ffff0000 f=81/0
  #|pcmpgtw xmm1, xmmword ptr [rsi]|660f650e|PCMPGTWrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=8 r9=1 xmm1=4c0fd78b7199b178d69ac317a18f4bf3 f=8d2 m10080=4756569ab1d506410b61da960aa37b27|xmm1=ffffffffffff000000000000ffff0000 f=8d0/0
  #|pcmpgtd xmm7, xmm6|660f66fe|PCMPGTDrr:%XMM7,%XMM7,%XMM6|xmm6=7113a2caaa0f77022cd89c5e923329c5 xmm7=ea9cbec16b6582f779c51a4c730556ed f=8c3|xmm7=ffffffffffffffffffffffff f=8c1/0
  #|pcmpgtd xmm7, xmm6|660f66fe|PCMPGTDrr:%XMM7,%XMM7,%XMM6|xmm6=b62fa3cf8493ad26286444c6161b44ae xmm7=45b92f0bef178ed46f6c2ddcd8159c68 f=883|xmm7=ffffffffffffffffffffffff00000000 f=881/0
  #|pcmpgtd xmm7, xmmword ptr [rsi]|660f663e|PCMPGTDrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=5 r9=3 xmm7=aacaa70cfb76ccc6e287f30c1ecc2fe6 f=453 m10080=2033a9cbeaae0624295b1f6625b016ba|xmm7=ffffffff f=451/0
  #|pcmpgtq xmm1, xmm5|660f3837cd|PCMPGTQrr:%XMM1,%XMM1,%XMM5|xmm1=39edfa7106062f42a050677fe365ca9a xmm5=0 f=d2|xmm1=ffffffffffffffff0000000000000000 f=d0/0
  #|pcmpgtq xmm1, xmm5|660f3837cd|PCMPGTQrr:%XMM1,%XMM1,%XMM5|xmm1=7921f6befd9af408d5a4fb6816d75694 xmm5=d608badee2cbb84d6f0b093196614915 f=43|xmm1=ffffffffffffffff0000000000000000 f=41/0
  #|pcmpgtq xmm1, xmmword ptr [rsi]|660f38370e|PCMPGTQrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=5 r9=1 xmm1=c1557ff927f409923471e6859c137839 f=896 m10080=6e803fa3af2163261a0bd09030a4e079|xmm1=ffffffffffffffff f=894/0
  #|pminub xmm5, xmm4|660fdaec|PMINUBrr:%XMM5,%XMM5,%XMM4|xmm4=ffffffffffffffffffffffffffffffff xmm5=af18847dd000c2c5f7ddfb5cd5123bc8 f=883|f=881/0
  #|pminub xmm5, xmm4|660fdaec|PMINUBrr:%XMM5,%XMM5,%XMM4|xmm4=3037cb06253a1a7f0fed41bca3551de3 xmm5=5483c59c9fb3d3a3ecce97f5e0a83fe9 f=8d6|xmm5=3037c506253a1a7f0fce41bca3551de3 f=8d4/0
  #|pminub xmm5, xmmword ptr [rsi]|660fda2e|PMINUBrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=7 r9=1 xmm5=80008000800080008000800080008000 f=7 m10080=c97af52d92b7ed48be23cd65696e215e|xmm5=5e006e0065002300480080002d007a00 f=5/0
  #|pmaxub xmm1, xmm2|660fdeca|PMAXUBrr:%XMM1,%XMM1,%XMM2|xmm1=0 xmm2=818d3917421c420777395b6d734d9207 f=852|xmm1=818d3917421c420777395b6d734d9207 f=850/0
  #|pmaxub xmm1, xmm2|660fdeca|PMAXUBrr:%XMM1,%XMM1,%XMM2|xmm1=b82751fa0ead4fea4468bdfb9ca7fcf1 xmm2=1d9d20832d09400a08e7aba7a4c7fbec f=493|xmm1=b89d51fa2dad4fea44e7bdfba4c7fcf1 f=491/0
  #|pmaxub xmm1, xmmword ptr [rsi]|660fde0e|PMAXUBrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=9 r9=c xmm1=73b29a63f629bb585ea533bde417f04e f=c96 m10080=7b5373f69acffa30c7069cfe02930637|xmm1=73b29a63fe9cbbc75efacfbdf673f07b f=c94/0
  #|pminsw xmm6, xmm3|660feaf3|PMINSWrr:%XMM6,%XMM6,%XMM3|xmm3=19495ead0b3b53318282b8363e3381bd xmm6=80008000800080008000800080008000 f=847|f=845/0
  #|pminsw xmm6, xmm3|660feaf3|PMINSWrr:%XMM6,%XMM6,%XMM3|xmm3=ffffffffffffffffffffffffffffffff xmm6=80008000800080008000800080008000 f=c06|f=c04/0
  #|pminsw xmm6, xmmword ptr [rsi]|660fea36|PMINSWrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=9 r9=2 xmm6=d258532ff23154fd9340df12911a584a f=893 m10080=1aabafd3c32d2619261e800bd5c107b8|xmm6=b807c1d5f2311e269340df12911aab1a f=891/0
  #|pmaxsw xmm5, xmm0|660feee8|PMAXSWrr:%XMM5,%XMM5,%XMM0|xmm0=39649e43beae1c8a17c3e32e4c95e280 xmm5=ffffffffffffffffffffffffffffffff f=883|xmm5=3964ffffffff1c8a17c3ffff4c95ffff f=881/0
  #|pmaxsw xmm5, xmm0|660feee8|PMAXSWrr:%XMM5,%XMM5,%XMM0|xmm0=19e918abb2041eab4f58e26cc18263bd xmm5=f9e12e668078e00c1133254c61b55cc1 f=853|xmm5=19e92e66b2041eab4f58254c61b563bd f=851/0
  #|pmaxsw xmm5, xmmword ptr [rsi]|660fee2e|PMAXSWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=f r9=7 xmm5=d8d2ca1ea45745c5c8cacdae1351473 f=93 m10080=99f3523e6d49cc9bb0a44f4e99dd74d4|xmm5=d8d2ca14e4f745c5c8c496d3e521473 f=91/0
  #|pminsb xmm3, xmm1|660f3838d9|PMINSBrr:%XMM3,%XMM3,%XMM1|xmm1=503e5b4f6fb765672469686d318189f6 xmm3=814297f08a7c3db1632f0450823dfcc1 f=893|xmm3=813e97f08ab73db1242f0450828189c1 f=891/0
  #|pminsb xmm3, xmm1|660f3838d9|PMINSBrr:%XMM3,%XMM3,%XMM1|xmm1=72e1b970d0774d829891adc0c05b7bb5 xmm3=91a54968f63fd6fe37a01fbe044c5ec5 f=417|xmm3=91a5b968d03fd6829891adbec04c5eb5 f=415/0
  #|pminsb xmm3, xmmword ptr [rsi]|660f38381e|PMINSBrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=a r9=f xmm3=db06b6fedcb4a87fd15438ae141643cd f=406 m10080=c3315fa03c20f08e4b6f3c178717349f|xmm3=9f06b687dcb4a84b8ef020aea01631c3 f=404/0
  #|pmaxsb xmm1, xmm15|66410f383ccf|PMAXSBrr:%XMM1,%XMM1,%XMM15|xmm1=6044ac9e06561f739b0747fc0a236e7e xmm15=1c0a0f11ba039094ce0c802412306997 f=813|xmm1=60440f1106561f73ce0c472412306e7e f=811/0
  #|pmaxsb xmm1, xmm15|66410f383ccf|PMAXSBrr:%XMM1,%XMM1,%XMM15|xmm1=80008000800080008000800080008000 xmm15=1c4ad4d94878ff1ca76a099b79d49eae f=8d2|xmm1=1c4ad4004878ff1ca76a090079009e00 f=8d0/0
  #|pmaxsb xmm1, xmmword ptr [rsi]|660f383c0e|PMAXSBrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=a r9=c xmm1=0 f=856 m10080=18314a30d91e591f82246d7e773e26cc|xmm1=263e777e6d24001f591e00304a3118 f=854/0
  #|pminsd xmm5, xmm4|660f3839ec|PMINSDrr:%XMM5,%XMM5,%XMM4|xmm4=58706b28678aaaa78e4064e6c3ca2347 xmm5=2a93154b1c643f77f4347ab3bec99828 f=883|xmm5=2a93154b1c643f778e4064e6bec99828 f=881/0
  #|pminsd xmm5, xmm4|660f3839ec|PMINSDrr:%XMM5,%XMM5,%XMM4|xmm4=3ab2da7edc43a00740e642a4f23bd3d4 xmm5=ffffffffffffffffffffffffffffffff f=c97|xmm5=ffffffffdc43a007fffffffff23bd3d4 f=c95/0
  #|pminsd xmm5, xmmword ptr [rsi]|660f38392e|PMINSDrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=0 r9=9 xmm5=cf6d16da427ee035c2a155bd29c252f0 f=857 m10080=6ca86bf7ec06f2843e8c58d101d1e110|xmm5=cf6d16dad1588c3e84f206ecf76ba86c f=855/0
  #|pmaxsd xmm5, xmm2|660f383dea|PMAXSDrr:%XMM5,%XMM5,%XMM2|xmm2=c82c113c5040a13b8adeb335b630c655 xmm5=175601abaa1437195663415923e401 f=53|xmm5=1756015040a13b195663415923e401 f=51/0
  #|pmaxsd xmm5, xmm2|660f383dea|PMAXSDrr:%XMM5,%XMM5,%XMM2|xmm2=ffffffffffffffffffffffffffffffff xmm5=12374c4a84809e4a05a5d48eee10ccbc f=413|xmm5=12374c4affffffff05a5d48effffffff f=411/0
  #|pmaxsd xmm5, xmmword ptr [rsi]|660f383d2e|PMAXSDrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=c r9=8 xmm5=4ac1e32c6232ed707bc01189173f7399 f=892 m10080=39924430d22133772fd8260b651be572|xmm5=72e51b656232ed707bc0118930449239 f=890/0
  #|pminuw xmm6, xmm0|660f383af0|PMINUWrr:%XMM6,%XMM6,%XMM0|xmm0=2236d7ed62832e8a68eaedd070692468 xmm6=86d86002f6fc8490a5fa1fd544bb9f24 f=8d2|xmm6=2236600262832e8a68ea1fd544bb2468 f=8d0/0
  #|pminuw xmm6, xmm0|660f383af0|PMINUWrr:%XMM6,%XMM6,%XMM0|xmm0=0 xmm6=5dd2b53f2afbe77a517f32c76659e6fa f=8c7|xmm6=0 f=8c5/0
  #|pminuw xmm6, xmmword ptr [rsi]|660f383a36|PMINUWrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=b r9=0 xmm6=8f58c2d774a0b1e4d48c9ec7b46a3ed f=8d6 m10080=a52ece4ad1a91e3d8e64a95b98960175|xmm6=8f58c2d5ba90b1e3d1ea9d14ace2ea5 f=8d4/0
  #|pmaxuw xmm5, xmm2|660f383eea|PMAXUWrr:%XMM5,%XMM5,%XMM2|xmm2=bd8e2e1e7288a48f547ebecc4602f7d1 xmm5=7f0f2f591dbb922d2eade97dc16415ee f=883|xmm5=bd8e2f597288a48f547ee97dc164f7d1 f=881/0
  #|pmaxuw xmm5, xmm2|660f383eea|PMAXUWrr:%XMM5,%XMM5,%XMM2|xmm2=ffffffffffffffffffffffffffffffff xmm5=80008000800080008000800080008000 f=cc2|xmm5=ffffffffffffffffffffffffffffffff f=cc0/0
  #|pmaxuw xmm5, xmmword ptr [rsi]|660f383e2e|PMAXUWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=8 r9=c xmm5=0 f=897 m10080=8474804670f56eea29418161611f38fc|xmm5=fc381f6161814129ea6ef57046807484 f=895/0
  #|pminud xmm1, xmm6|660f383bce|PMINUDrr:%XMM1,%XMM1,%XMM6|xmm1=80008000800080008000800080008000 xmm6=62eb78aa260c1e6d6aa432c4a763f07a f=853|xmm1=62eb78aa260c1e6d6aa432c480008000 f=851/0
  #|pminud xmm1, xmm6|660f383bce|PMINUDrr:%XMM1,%XMM1,%XMM6|xmm1=6f364a747b5429408fe422d61cd42b67 xmm6=7be94cb16557100333914b9ef6a2e444 f=8d7|xmm1=6f364a746557100333914b9e1cd42b67 f=8d5/0
  #|pminud xmm1, xmmword ptr [rsi]|660f383b0e|PMINUDrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=1 r9=0 xmm1=b5e2584821773fa26ea5af97b0989900 f=12 m10080=776ef88b6b776d1938a27e37313ff13b|xmm1=3bf13f3121773fa2196d776b8bf86e77 f=10/0
  #|pmaxud xmm3, xmm0|660f383fd8|PMAXUDrr:%XMM3,%XMM3,%XMM0|xmm0=0 xmm3=644dac86914cb892252eea9bb935746 f=807|f=805/0
  #|pmaxud xmm3, xmm0|660f383fd8|PMAXUDrr:%XMM3,%XMM3,%XMM0|xmm0=ffffffffffffffffffffffffffffffff xmm3=5535ff87c3b34b576ed0bdf794d2c8a1 f=8c7|xmm3=ffffffffffffffffffffffffffffffff f=8c5/0
  #|pmaxud xmm3, xmmword ptr [rsi]|660f383f1e|PMAXUDrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=5 r9=6 xmm3=9f447b40dfa26658329bccf05fa6407b f=93 m10080=71811df420eafdbe074d0abe2641aec6|xmm3=c6ae4126dfa26658befdea20f41d8171 f=91/0
  #|pavgb xmm1, xmm10|66410fe0ca|PAVGBrr:%XMM1,%XMM1,%XMM10|xmm1=22cd9c2172df8c84f9aae58a25ffcff4 xmm10=0 f=853|xmm1=11674e11397046427d5573451380687a f=851/0
  #|pavgb xmm1, xmm10|66410fe0ca|PAVGBrr:%XMM1,%XMM1,%XMM10|xmm1=80008000800080008000800080008000 xmm10=fa04741766d7bd9eb77c377c6f4ac223 f=8c7|xmm1=bd027a0c736c9f4f9c3e5c3e7825a112 f=8c5/0
  #|pavgb xmm1, xmmword ptr [rsi]|660fe00e|PAVGBrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=d r9=7 xmm1=ea58749dd176efdc023acb81fda173e5 f=4c6 m10080=a7972e7acfcba65dd7d9a75606114b36|xmm1=90524352948fe4da3070cba8bc6885c6 f=4c4/0
  #|pavgw xmm7, xmm6|660fe3fe|PAVGWrr:%XMM7,%XMM7,%XMM6|xmm6=80008000800080008000800080008000 xmm7=b60134448880f3c596053894d636f1af f=cd3|xmm7=9b015a228440b9e38b035c4aab1bb8d8 f=cd1/0
  #|pavgw xmm7, xmm6|660fe3fe|PAVGWrr:%XMM7,%XMM7,%XMM6|xmm6=68e22dad4eb69c9f820326a3aaaf8ef9 xmm7=f4f487cffdefa60da8733e887d7ba6db f=402|xmm7=aeeb5abea653a156953b329694159aea f=400/0
  #|pavgw xmm7, xmmword ptr [rsi]|660fe33e|PAVGWrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=7 r9=f xmm7=c78ddb77b05560bd5a247e2f876265ed f=897 m10080=9bf5ebb85d743d8802e0dbbaa76d30ad|xmm7=ba5fa48fb598a06071317946a027adc4 f=895/0
  #|pmullw xmm4, xmm1|660fd5e1|PMULLWrr:%XMM4,%XMM4,%XMM1|xmm1=36c8b87de4eacd44b662133aaee71bdd xmm4=0 f=3|f=1/0
  #|pmullw xmm4, xmm1|660fd5e1|PMULLWrr:%XMM4,%XMM4,%XMM1|xmm1=d55c60f4a4a52231babf6051a0111bcc xmm4=99023e1518839f23c10fdd9b15543195 f=896|xmm4=a6b80c04b86f1bb3f0313e0bea9439bc f=894/0
  #|pmullw xmm4, xmmword ptr [rsi]|660fd526|PMULLWrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=5 r9=c xmm4=b0fe6e21fd9f5535730ce36faeaddb60 f=c42 m10080=d562a9afe6dc96ec780baf0624b02ba6|xmm4=6eaa2ca419b137d87908b9ba933546e0 f=c40/0
  #|pmulhw xmm5, xmm0|660fe5e8|PMULHWrr:%XMM5,%XMM5,%XMM0|xmm0=801ad05426435e3e25e59fc59db696a6 xmm5=2f4040664aa5b736b7b96fa7d4e98ff9 f=8c2|xmm5=e864f4020b28e534f54dd607108b2e1a f=8c0/0
  #|pmulhw xmm5, xmm0|660fe5e8|PMULHWrr:%XMM5,%XMM5,%XMM0|xmm0=3d25dfb69fd0678d74f675c06f0b5c79 xmm5=ae90b475474fc67c97a4a92e5bd14647 f=c46|xmm5=ec8c0987e535e8bcd052d81027d31962 f=c44/0
  #|pmulhw xmm5, xmmword ptr [rsi]|660fe52e|PMULHWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=6 r9=4 xmm5=e0f94e59ae50df7e9fef37d39502c1be f=8d7 m10080=0d871ef1a935522fc0abd035e026a62a|xmm5=fad40be5eed40ab2ee3e0bb306381d6a f=8d5/0
  #|pmulhuw xmm3, xmm4|660fe4dc|PMULHUWrr:%XMM3,%XMM3,%XMM4|xmm3=11d5f526e965b37ef5aaa947cb0248c xmm4=1c313f4f4d7cf8e2bb67f05061a44738 f=4d2|xmm3=1f1792217858adaf37a0202f8e0a2a f=4d0/0
  #|pmulhuw xmm3, xmm4|660fe4dc|PMULHUWrr:%XMM3,%XMM3,%XMM4|xmm3=b538c92c8330f9f200b8545c68ea6305 xmm4=bc6b0e0a00f5d19c85a6bf75874a3a24 f=812|xmm3=85600b08007dcca600603f173771167d f=810/0
  #|pmulhuw xmm3, xmmword ptr [rsi]|660fe41e|PMULHUWrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=3 r9=4 xmm3=80008000800080008000800080008000 f=817 m10080=786666f064dc7489e2d22468902884db|xmm3=6dc214483412697144ba6e327833333c f=815/0
  #|pmuludq xmm11, xmm4|66440ff4dc|PMULUDQrr:%XMM11,%XMM11,%XMM4|xmm4=ffffffffffffffffffffffffffffffff xmm11=389de78f8d980707d2ec925e9eb1e468 f=8c6|xmm11=8d9807067267f8f99eb1e467614e1b98 f=8c4/0
  #|pmuludq xmm11, xmm4|66440ff4dc|PMULUDQrr:%XMM11,%XMM11,%XMM4|xmm4=b9346e284ab67a182ba1d55d8873c3db xmm11=8d917a63f11d72374d5cdb35778fd407 f=d6|xmm11=465e60f1bc4aeb283fba79b8cdb0b6fd f=d4/0
  #|pmuludq xmm11, xmmword ptr [rsi]|66440ff41e|PMULUDQrm:%XMM11,%XMM11,%RSI,1,%,0,%|rbx=e r9=2 xmm11=87ed0ffdb63fcece281be8ad85f40998 f=817 m10080=50d47fb492a052a752269364eb1afba5|xmm11=4799aeb4116cd1fc5e7279e7969cdf80 f=815/0
  #|pmuldq xmm12, xmm11|66450f3828e3|PMULDQrr:%XMM12,%XMM12,%XMM11|xmm11=3026f29d52ced0b2f35faa3a124eef55 xmm12=0 f=813|f=811/0
  #|pmuldq xmm12, xmm11|66450f3828e3|PMULDQrr:%XMM12,%XMM12,%XMM11|xmm11=5644bc638993025dd6bd69e4b12e06d6 xmm12=2a32a721f18ddc6c537bf1a291fc91a7 f=46|xmm12=6aec2dd3a45eb3c21df477f978dab9a f=44/0
  #|pmuldq xmm12, xmmword ptr [rsi]|66440f382826|PMULDQrm:%XMM12,%XMM12,%RSI,1,%,0,%|rbx=2 r9=b xmm12=35bbcc770018a8832b658d34f72c3fe3 f=842 m10080=5e3ea939e4c3837515e2750da33e17fd|xmm12=14be971a878bffe03044931936f5a f=840/0
  #|pmulld xmm0, xmm4|660f3840c4|PMULLDrr:%XMM0,%XMM0,%XMM4|xmm0=9a44f11ac47b68f4cd1c388cf17c95f5 xmm4=9d3362910c1304cb9dea3536c26a0392 f=887|xmm0=bf8683baf59c097ca7a0e988f04164ba f=885/0
  #|pmulld xmm0, xmm4|660f3840c4|PMULLDrr:%XMM0,%XMM0,%XMM4|xmm0=f6fe8b759ae025cbd177f5e4449c2f9d xmm4=e734a925875f1c506147a22f438066fa f=813|xmm0=a39e64e9fd830370f4dc6cdc20ff0d52 f=811/0
  #|pmulld xmm0, xmmword ptr [rsi]|660f384006|PMULLDrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=d r9=d xmm0=17a1058def948675aef794a0d703dfd7 f=8c3 m10080=9d68a42abb357870c95fa85dc98c3d4a|xmm0=b10f77b5f74afcddbb9eb0e01c0b9edb f=8c1/0
  #|pmaddwd xmm2, xmm4|660ff5d4|PMADDWDrr:%XMM2,%XMM2,%XMM4|xmm2=8a0f055bc69adc59c4c7b85120bbc1c4 xmm4=f601a338b59d2ab9d91a24342a56c85d f=886|xmm2=2aa10f70aba84c3fedc7faa12f03106 f=884/0
  #|pmaddwd xmm2, xmm4|660ff5d4|PMADDWDrr:%XMM2,%XMM2,%XMM4|xmm2=d65d134a52ea9200a673440d1b0a26c0 xmm4=50e95117cb84c7f6ff028b71dffad37f f=53|xmm2=f8f3504b07149aa8e15cf2a3f5e19704 f=51/0
  #|pmaddwd xmm2, xmmword ptr [rsi]|660ff516|PMADDWDrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=c r9=6 xmm2=b785c64f0bf479dfae2ac6bfa7487484 f=cd7 m10080=d91c0680d010068f529d0b1f94b1b1e6|xmm2=18d6a5a1d278dbea205af62c397b1f94 f=cd5/0
  #|psadbw xmm1, xmm6|660ff6ce|PSADBWrr:%XMM1,%XMM1,%XMM6|xmm1=b28b7e602318263adc7c538fa0b0fda9 xmm6=d3c66412bbf4320b6a684727ff3c3c3a f=12|xmm1=27300000000000002fd f=10/0
  #|psadbw xmm1, xmm6|660ff6ce|PSADBWrr:%XMM1,%XMM1,%XMM6|xmm1=ac71e6f8d17f4af65b8036109443acf2 xmm6=bebde7dbc8da222759bf17d8fc8157c f=856|xmm1=2ed00000000000002f4 f=854/0
  #|psadbw xmm1, xmmword ptr [rsi]|660ff60e|PSADBWrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=c r9=0 xmm1=70b71a0f02b5ffd89d9acc20cb2b8f81 f=97 m10080=f584822bae564ac106a4791138e5d534|xmm1=2c600000000000002ee f=95/0
  #|psllw xmm4, xmm0|660ff1e0|PSLLWrr:%XMM4,%XMM4,%XMM0|xmm0=8901706f4c272bddd2bf80bee8d154ba xmm4=bdf1f27718e8acd13dc3ba39c4a4d9d f=8d6|xmm4=0 f=8d4/0
  #|psllw xmm4, xmm0|660ff1e0|PSLLWrr:%XMM4,%XMM4,%XMM0|xmm0=8423624a129971061ad24b42081ded7c xmm4=ffffffffffffffffffffffffffffffff f=8d6|xmm4=0 f=8d4/0
  #|psllw xmm4, xmmword ptr [rsi]|660ff126|PSLLWrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=4 r9=5 xmm4=2239410fc1b627e1afc118a1a6932e0a f=46 m10080=18f314e3b10184657d89d9a7c9275dbd|xmm4=0 f=44/0
  #|pslld xmm0, xmm4|660ff2c4|PSLLDrr:%XMM0,%XMM0,%XMM4|xmm0=5207feb596c2fa58b19e4a68b6d7e943 xmm4=0 f=92|f=90/0
  #|pslld xmm0, xmm4|660ff2c4|PSLLDrr:%XMM0,%XMM0,%XMM4|xmm0=d885908dcd8f60942180960e8dd361a8 xmm4=aaa647836a6d5290c88020b995551f f=7|xmm0=0 f=5/0
  #|pslld xmm0, xmmword ptr [rsi]|660ff206|PSLLDrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=b r9=3 xmm0=51c213a79aa43af725efa520bef4c1ac f=8c7 m10080=a637622c5b5aa6a095d9e840a1c1bfad|xmm0=0 f=8c5/0
  #|psllq xmm1, xmm3|660ff3cb|PSLLQrr:%XMM1,%XMM1,%XMM3|xmm1=231bab9f0cf80f684dfcb153dd086f60 xmm3=41c99d05e6d7f187fa8e9ac0da5e0549 f=52|xmm1=0 f=50/0
  #|psllq xmm1, xmm3|660ff3cb|PSLLQrr:%XMM1,%XMM1,%XMM3|xmm1=8afd51dc64b72b1294be4db6da515300 xmm3=73387ae867147273df965a7731e5cff3 f=46|xmm1=0 f=44/0
  #|psllq xmm1, xmmword ptr [rsi]|660ff30e|PSLLQrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=d r9=7 xmm1=ffffffffffffffffffffffffffffffff f=53 m10080=ecdc8d1287e057c52342b8c8b4ff96f3|xmm1=0 f=51/0
  #|psrlw xmm0, xmm4|660fd1c4|PSRLWrr:%XMM0,%XMM0,%XMM4|xmm0=7b351cbf95d3f2d02b01397ec93d1443 xmm4=0 f=83|f=81/0
  #|psrlw xmm0, xmm4|660fd1c4|PSRLWrr:%XMM0,%XMM0,%XMM4|xmm0=4126d980f5211836b1d42b31bd94b70b xmm4=ae928b4b1e8f0c849237dafd49e147f6 f=52|xmm0=0 f=50/0
  #|psrlw xmm0, xmmword ptr [rsi]|660fd106|PSRLWrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=f r9=b xmm0=ffffffffffffffffffffffffffffffff f=57 m10080=e20b7d0298764e5d2d3de410425ef206|xmm0=0 f=55/0
  #|psrld xmm6, xmm0|660fd2f0|PSRLDrr:%XMM6,%XMM6,%XMM0|xmm0=1ade2f7948c5bc8aee7ae953487f0cf1 xmm6=80008000800080008000800080008000 f=2|xmm6=0 f=0/0
  #|psrld xmm6, xmm0|660fd2f0|PSRLDrr:%XMM6,%XMM6,%XMM0|xmm0=1f75dba2b0e341334feefadc1dea908f xmm6=ffffffffffffffffffffffffffffffff f=47|xmm6=0 f=45/0
  #|psrld xmm6, xmmword ptr [rsi]|660fd236|PSRLDrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=0 r9=e xmm6=c42a9056ff9bad85a3ab04e34d595d90 f=cc3 m10080=543402e167e2a5e3ff6ef0ce07b96e52|xmm6=0 f=cc1/0
  #|psrlq xmm2, xmm7|660fd3d7|PSRLQrr:%XMM2,%XMM2,%XMM7|xmm2=ffffffffffffffffffffffffffffffff xmm7=80008000800080008000800080008000 f=17|xmm2=0 f=15/0
  #|psrlq xmm2, xmm7|660fd3d7|PSRLQrr:%XMM2,%XMM2,%XMM7|xmm2=7d3ae2d3fcd539cf857ce5d5697898f xmm7=1ae1b54a78d7a03dd248ea747c64d0a5 f=882|xmm2=0 f=880/0
  #|psrlq xmm2, xmmword ptr [rsi]|660fd316|PSRLQrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=b r9=3 xmm2=bbf03bb8aaaba084a1c35c00fefda6d4 f=c2 m10080=9031c7eb1826261ce297c15a8851a6c4|xmm2=0 f=c0/0
  #|psraw xmm3, xmm6|660fe1de|PSRAWrr:%XMM3,%XMM3,%XMM6|xmm3=f793c99b41dde010211537bc1816aced xmm6=0 f=c46|f=c44/0
  #|psraw xmm3, xmm6|660fe1de|PSRAWrr:%XMM3,%XMM3,%XMM6|xmm3=0 xmm6=c9f516270725dc071c1b2699ecbe996c f=886|f=884/0
  #|psraw xmm3, xmmword ptr [rsi]|660fe11e|PSRAWrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=8 r9=1 xmm3=a416fa24e8de502a06741d6e2de866e1 f=802 m10080=aafe535bd03215c02504bf5512b6cbf7|xmm3=ffffffffffff00000000000000000000 f=800/0
  #|psrad xmm1, xmm6|660fe2ce|PSRADrr:%XMM1,%XMM1,%XMM6|xmm1=d9c6ceb8e29327e3eb6e79e33abc9721 xmm6=0 f=4d2|f=4d0/0
  #|psrad xmm1, xmm6|660fe2ce|PSRADrr:%XMM1,%XMM1,%XMM6|xmm1=80008000800080008000800080008000 xmm6=f718424d928e954dddb72381ce00f626 f=857|xmm1=ffffffffffffffffffffffffffffffff f=855/0
  #|psrad xmm1, xmmword ptr [rsi]|660fe20e|PSRADrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=b r9=0 xmm1=26e6a8dc8c022a5aa48d2b8605851939 f=883 m10080=f4b4466434b31fd68dcb38c29e68938a|xmm1=ffffffffffffffff00000000 f=881/0
  #|punpcklbw xmm4, xmm7|660f60e7|PUNPCKLBWrr:%XMM4,%XMM4,%XMM7|xmm4=dc0be9861536eef0e4924f0f43a09fa5 xmm7=bd9fb072298bf857b7eef3404e553b81 f=17|xmm4=b7e4ee92f34f400f4e4355a03b9f81a5 f=15/0
  #|punpcklbw xmm4, xmm7|660f60e7|PUNPCKLBWrr:%XMM4,%XMM4,%XMM7|xmm4=a914cb647e7fb02360481d3290d4cb61 xmm7=ffffffffffffffffffffffffffffffff f=13|xmm4=ff60ff48ff1dff32ff90ffd4ffcbff61 f=11/0
  #|punpcklbw xmm4, xmmword ptr [rsi]|660f6026|PUNPCKLBWrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=7 r9=8 xmm4=241217516601e719d9f6654b6abdfc42 f=802 m10080=8fe9fbe49a1f5787dfd101d5d99cb4dc|xmm4=87d957f61f659a4be46afbbde9fc8f42 f=800/0
  #|punpcklwd xmm5, xmm4|660f61ec|PUNPCKLWDrr:%XMM5,%XMM5,%XMM4|xmm4=ffffffffffffffffffffffffffffffff xmm5=35061e7984591787602296a3e8ec3256 f=496|xmm5=ffff6022ffff96a3ffffe8ecffff3256 f=494/0
  #|punpcklwd xmm5, xmm4|660f61ec|PUNPCKLWDrr:%XMM5,%XMM5,%XMM4|xmm4=8d9177e18601a66694e1e453087bbf5a xmm5=0 f=87|xmm5=94e10000e4530000087b0000bf5a0000 f=85/0
  #|punpcklwd xmm5, xmmword ptr [rsi]|660f612e|PUNPCKLWDrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=0 r9=8 xmm5=ffffffffffffffffffffffffffffffff f=886 m10080=03e35fa437e55678f30873a7a074adbf|xmm5=7856ffffe537ffffa45fffffe303ffff f=884/0
  #|punpckldq xmm5, xmm7|660f62ef|PUNPCKLDQrr:%XMM5,%XMM5,%XMM7|xmm5=3bed989cbe716b9c2b0e2447c3a70c8c xmm7=16df76c8de5d0d6e88b156287266b467 f=857|xmm5=88b156282b0e24477266b467c3a70c8c f=855/0
  #|punpckldq xmm5, xmm7|660f62ef|PUNPCKLDQrr:%XMM5,%XMM5,%XMM7|xmm5=647c13504dab8ca20b91e8160ee81c2 xmm7=fac07ace9a309352a070ea5b8961ae9e f=92|xmm5=a070ea5b20b91e818961ae9e60ee81c2 f=90/0
  #|punpckldq xmm5, xmmword ptr [rsi]|660f622e|PUNPCKLDQrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=9 r9=c xmm5=4d35f36030f4c9057d86d63c63d37ad0 f=c3 m10080=dd5c211b36388594b75e50ef02b5239c|xmm5=948538367d86d63c1b215cdd63d37ad0 f=c1/0
  #|punpcklqdq xmm6, xmm3|660f6cf3|PUNPCKLQDQrr:%XMM6,%XMM6,%XMM3|xmm3=93618f62280a3d18b4b55830530b2e38 xmm6=80008000800080008000800080008000 f=d7|xmm6=b4b55830530b2e388000800080008000 f=d5/0
  #|punpcklqdq xmm6, xmm3|660f6cf3|PUNPCKLQDQrr:%XMM6,%XMM6,%XMM3|xmm3=f8c6f2a49442c5dcc2151d7bcaca2e03 xmm6=8ad71c27b5bcf4af1f4abe32ef3f9c8e f=53|xmm6=c2151d7bcaca2e031f4abe32ef3f9c8e f=51/0
  #|punpcklqdq xmm6, xmmword ptr [rsi]|660f6c36|PUNPCKLQDQrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=e r9=d xmm6=ffffffffffffffffffffffffffffffff f=847 m10080=dd8ad4879a7e652d3667d83c8595304d|xmm6=2d657e9a87d48addffffffffffffffff f=845/0
  #|punpckhbw xmm0, xmm6|660f68c6|PUNPCKHBWrr:%XMM0,%XMM0,%XMM6|xmm0=898eb1dbe48404ab0df54509b4e7362c xmm6=e01a34195d9147a7c2e41c5054341982 f=842|xmm0=e0891a8e34b119db5de491844704a7ab f=840/0
  #|punpckhbw xmm0, xmm6|660f68c6|PUNPCKHBWrr:%XMM0,%XMM0,%XMM6|xmm0=576d32a348f29b528d62a297278c6631 xmm6=0 f=c3|xmm0=57006d003200a3004800f2009b0052 f=c1/0
  #|punpckhbw xmm0, xmmword ptr [rsi]|660f6806|PUNPCKHBWrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=6 r9=c xmm0=128c516bc4f19b8f1ca299b3a969fbf6 f=812 m10080=8ad2a441a8c8e20e21de8f93692ff675|xmm0=7512f68c2f51696b93c48ff1de9b218f f=810/0
  #|punpckhwd xmm6, xmm7|660f69f7|PUNPCKHWDrr:%XMM6,%XMM6,%XMM7|xmm6=7af410f51bb352aa8a4e1beb7034722a xmm7=f2fe3a4b5b75feea2d2b7f23e9cae39d f=4d6|xmm6=f2fe7af43a4b10f55b751bb3feea52aa f=4d4/0
  #|punpckhwd xmm6, xmm7|660f69f7|PUNPCKHWDrr:%XMM6,%XMM6,%XMM7|xmm6=dd56fee7ce7e6973628fbf642f46075a xmm7=80008000800080008000800080008000 f=812|xmm6=8000dd568000fee78000ce7e80006973 f=810/0
  #|punpckhwd xmm6, xmmword ptr [rsi]|660f6936|PUNPCKHWDrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=5 r9=9 xmm6=e3f99d3b2e5c205aa30a98c80f18896a f=cc3 m10080=c9ded91d22c05bfb89693c8721a6d93d|xmm6=3dd9e3f9a6219d3b873c2e5c6989205a f=cc1/0
  #|punpckhdq xmm6, xmm3|660f6af3|PUNPCKHDQrr:%XMM6,%XMM6,%XMM3|xmm3=d3a56c81f401760d49b35dbe4af6c8ae xmm6=9ee3ca59d66dafd526058e4fe469bd51 f=c43|xmm6=d3a56c819ee3ca59f401760dd66dafd5 f=c41/0
  #|punpckhdq xmm6, xmm3|660f6af3|PUNPCKHDQrr:%XMM6,%XMM6,%XMM3|xmm3=8dc7560315cf3b8c8369e4c078680467 xmm6=dcbe89f660cd80ab4f31e9b9d35a8e66 f=47|xmm6=8dc75603dcbe89f615cf3b8c60cd80ab f=45/0
  #|punpckhdq xmm6, xmmword ptr [rsi]|660f6a36|PUNPCKHDQrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=1 r9=b xmm6=b6d4955bca92fcc201b4561d5105eea4 f=8d3 m10080=0b1b533bc1f23ef7ffcbbab2499505ff|xmm6=ff059549b6d4955bb2bacbffca92fcc2 f=8d1/0
  #|punpckhqdq xmm10, xmm6|66440f6dd6|PUNPCKHQDQrr:%XMM10,%XMM10,%XMM6|xmm6=88cc67ffdc69d17b62a2fb1c264220b0 xmm10=ac75ceb1ad6f9bb98327b25b52653267 f=c3|xmm10=88cc67ffdc69d17bac75ceb1ad6f9bb9 f=c1/0
  #|punpckhqdq xmm10, xmm6|66440f6dd6|PUNPCKHQDQrr:%XMM10,%XMM10,%XMM6|xmm6=59da5e1a5aeb61283ae8286353d02b00 xmm10=1e777c331daedf587aa4f67537b445a2 f=847|xmm10=59da5e1a5aeb61281e777c331daedf58 f=845/0
  #|punpckhqdq xmm10, xmmword ptr [rsi]|66440f6d16|PUNPCKHQDQrm:%XMM10,%XMM10,%RSI,1,%,0,%|rbx=6 r9=c xmm10=7d617820765cfe126a5b72d2cd239328 f=c02 m10080=4b813c5097c6b90633a5861b024cffbc|xmm10=bcff4c021b86a5337d617820765cfe12 f=c00/0
  #|packsswb xmm5, xmm1|660f63e9|PACKSSWBrr:%XMM5,%XMM5,%XMM1|xmm1=8224218275eea5195b05af1f4a21dba6 xmm5=1cc366bc7b4e34051ce265abf57dc60f f=847|xmm5=807f7f807f807f807f7f7f7f7f7f8080 f=845/0
  #|packsswb xmm5, xmm1|660f63e9|PACKSSWBrr:%XMM5,%XMM5,%XMM1|xmm1=da7b3652ff4d3be9383888c06d9be64b xmm5=dde1f00c3d3e3fbf8b40c93a8daeb1f8 f=816|xmm5=807f807f7f807f8080807f7f80808080 f=814/0
  #|packsswb xmm5, xmmword ptr [rsi]|660f632e|PACKSSWBrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=d r9=1 xmm5=3c863ff1bafda4b467f276c38805c4a5 f=46 m10080=8c32c9804579a9ead82c704c60eacf71|xmm5=7f807f7f807f807f7f7f80807f7f8080 f=44/0
  #|packssdw xmm7, xmm2|660f6bfa|PACKSSDWrr:%XMM7,%XMM7,%XMM2|xmm2=a9ee0b897c80ab57291d9d4b1d5f8883 xmm7=b88c08ef1ab6911c68a2090e4c5e76bf f=817|xmm7=80007fff7fff7fff80007fff7fff7fff f=815/0
  #|packssdw xmm7, xmm2|660f6bfa|PACKSSDWrr:%XMM7,%XMM7,%XMM2|xmm2=95469e6c90363d1475eaec07556de2b9 xmm7=80008000800080008000800080008000 f=496|xmm7=800080007fff7fff8000800080008000 f=494/0
  #|packssdw xmm7, xmmword ptr [rsi]|660f6b3e|PACKSSDWrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=3 r9=5 xmm7=0 f=6 m10080=b7f0ba7b6debbc8b99ba92aa2abe859e|xmm7=8000800080007fff0000000000000000 f=4/0
  #|packuswb xmm7, xmm3|660f67fb|PACKUSWBrr:%XMM7,%XMM7,%XMM3|xmm3=652c6fd3fa96a4fbb0397cf2c714c455 xmm7=6fab97b6c33433481f075c7ddb75d615 f=c42|xmm7=ffff000000ff0000ff0000ffffff0000 f=c40/0
  #|packuswb xmm7, xmm3|660f67fb|PACKUSWBrr:%XMM7,%XMM7,%XMM3|xmm3=d1f5b1313f95ce7f8a539923f46e9cd9 xmm7=fd9dd05c06e6d81d67858d8522fcca6e f=492|xmm7=ff00000000000000ff00ff00ff00 f=490/0
  #|packuswb xmm7, xmmword ptr [rsi]|660f673e|PACKUSWBrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=f r9=a xmm7=c719299b1838aa86d7a97a80d7bbc307 f=442 m10080=719fb85c7ef5d423a5dde4f0997248a0|xmm7=ff0000ff00ff0000ffff0000ff0000 f=440/0
  #|packusdw xmm5, xmm2|660f382bea|PACKUSDWrr:%XMM5,%XMM5,%XMM2|xmm2=e3d69d073b998eb8a30948f3478f3162 xmm5=ffffffffffffffffffffffffffffffff f=96|xmm5=ffff0000ffff0000000000000000 f=94/0
  #|packusdw xmm5, xmm2|660f382bea|PACKUSDWrr:%XMM5,%XMM5,%XMM2|xmm2=0 xmm5=73c3f7442f1b2ffb08919139e1caaa62 f=7|xmm5=ffffffffffff0000 f=5/0
  #|packusdw xmm5, xmmword ptr [rsi]|660f382b2e|PACKUSDWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=e r9=d xmm5=c8a030d05d429efc821ef01374997909 f=c57 m10080=a50542948098b4bc88ba3c6159191c67|xmm5=ffffffff000000000000ffff0000ffff f=c55/0
  #|pshufb xmm7, xmm4|660f3800fc|PSHUFBrr:%XMM7,%XMM7,%XMM4|xmm4=da1466c8b7dfaa294cea7543d7eb32b7 xmm7=edc45d652c74f3aacab14bdda1bd16cb f=806|xmm7=ddb100000000f365004ba10000bd00 f=804/0
  #|pshufb xmm7, xmm4|660f3800fc|PSHUFBrr:%XMM7,%XMM7,%XMM4|xmm4=7e3a1b2172c6055c44c4beff9fdb0557 xmm7=abe559b6d7ac5089f8349ab0e69ea793 f=492|xmm7=e5acd7a79e009ab6b000000000009af8 f=490/0
  #|pshufb xmm7, xmmword ptr [rsi]|660f38003e|PSHUFBrm:%XMM7,%XMM7,%RSI,1,%,0,%|rbx=6 r9=0 xmm7=36f386c6ee252059c5a9e57b954470ea f=497 m10080=2fc5f5df52748f7630014ebbbe8473b8|xmm7=95000000f370eaa9007b4400000036 f=495/0
  #|pabsb xmm6, xmm3|660f381cf3|PABSBrr:%XMM6,%XMM3|xmm3=cc2a3628f3ea399b5a9cfac4bb870435 xmm6=6df667d3890f319dae78df54a9c79202 f=852|xmm6=342a36280d1639655a64063c45790435 f=850/0
  #|pabsb xmm6, xmm3|660f381cf3|PABSBrr:%XMM6,%XMM3|xmm3=ffffffffffffffffffffffffffffffff xmm6=80008000800080008000800080008000 f=452|xmm6=1010101010101010101010101010101 f=450/0
  #|pabsb xmm6, xmmword ptr [rsi]|660f381c36|PABSBrm:%XMM6,%RSI,1,%,0,%|rbx=3 r9=b xmm6=8c8ba84973225f54148a17d7d520b03a f=6 m10080=b4b3a5033d11e2f08d2b8509f8ffb695|xmm6=6b4a0108097b2b73101e113d035b4d4c f=4/0
  #|pabsw xmm4, xmm6|660f381de6|PABSWrr:%XMM4,%XMM6|xmm4=32c9797f476845894c4735b40edaa694 xmm6=70230c75728f314aa8df90ddd1c2fd31 f=43|xmm4=70230c75728f314a57216f232e3e02cf f=41/0
  #|pabsw xmm4, xmm6|660f381de6|PABSWrr:%XMM4,%XMM6|xmm4=a61fc4914ed3daf76700e8b21378b716 xmm6=a9f20b628588f37e71ea6eee595d4d36 f=c47|xmm4=560e0b627a780c8271ea6eee595d4d36 f=c45/0
  #|pabsw xmm4, xmmword ptr [rsi]|660f381d26|PABSWrm:%XMM4,%RSI,1,%,0,%|rbx=6 r9=0 xmm4=b5d55bdb9f5da1bcee41dc5e8b320d73 f=802 m10080=3711f3b10aadc5df2620acbaf08fc190|xmm4=6f3f701045542026203b52f64e0d1137 f=800/0
  #|pabsd xmm6, xmm3|660f381ef3|PABSDrr:%XMM6,%XMM3|xmm3=403799538db3ab187f052b50b29cba9c xmm6=1eaac59d2731f236740a1a9a5c6787b8 f=483|xmm6=40379953724c54e87f052b504d634564 f=481/0
  #|pabsd xmm6, xmm3|660f381ef3|PABSDrr:%XMM6,%XMM3|xmm3=80008000800080008000800080008000 xmm6=597b17b4495fa198e4f235d61d259056 f=856|xmm6=7fff80007fff80007fff80007fff8000 f=854/0
  #|pabsd xmm6, xmmword ptr [rsi]|660f381e36|PABSDrm:%XMM6,%RSI,1,%,0,%|rbx=f r9=8 xmm6=7c7cb48030f315b298149731c51de597 f=8c7 m10080=2b5bebc42dea1d8b19d84d34e70f88a8|xmm6=5777f019344dd81974e215d33b14a4d5 f=8c5/0
  #|psignb xmm0, xmm2|660f3808c2|PSIGNBrr:%XMM0,%XMM0,%XMM2|xmm0=e0a271fcbed790f2f0eee473ba2cfe6f xmm2=c7ad3e2ce6f959c9a0943c074cf083c8 f=cc6|xmm0=205e71fc4229900e1012e473bad40291 f=cc4/0
  #|psignb xmm0, xmm2|660f3808c2|PSIGNBrr:%XMM0,%XMM0,%XMM2|xmm0=f37d74e075ec46e925532afa23ce0e3a xmm2=2dcb166ba0d6f0be93dd0d9ed8ad33f8 f=c7|xmm0=f38374e08b14ba17dbad2a06dd320ec6 f=c5/0
  #|psignb xmm0, xmmword ptr [rsi]|660f380806|PSIGNBrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=3 r9=a xmm0=8d946a3ca1599ed09ef072896bfa6357 f=802 m10080=3c23a32f365017e7bd63e6c9f1400fcc|xmm0=73946ac45fa79e3062f072896b066357 f=800/0
  #|psignw xmm6, xmm3|660f3809f3|PSIGNWrr:%XMM6,%XMM6,%XMM3|xmm3=f5901109b7c99b37c09cea6346cf3d0b xmm6=84b6dc32bb09d367b4092e29c62045c1 f=806|xmm6=7b4adc3244f72c994bf7d1d7c62045c1 f=804/0
  #|psignw xmm6, xmm3|660f3809f3|PSIGNWrr:%XMM6,%XMM6,%XMM3|xmm3=c5a700a3e80354c44f226c6f9ac9a9de xmm6=ee201c98a384b1670d4bfb5fe5b3e5e f=853|xmm6=f11e01c975c84b1670d4bfb501a5c1a2 f=851/0
  #|psignw xmm6, xmmword ptr [rsi]|660f380936|PSIGNWrm:%XMM6,%XMM6,%RSI,1,%,0,%|rbx=d r9=8 xmm6=5b384962ef92e0501fc829e35ddb4f8c f=97 m10080=37726927043565786fbabf152c97dfa8|xmm6=a4c8b69eef921fb01fc829e35ddb4f8c f=95/0
  #|psignd xmm0, xmm4|660f380ac4|PSIGNDrr:%XMM0,%XMM0,%XMM4|xmm0=ff5d45b22f1ccd796b73e6fe44f2292a xmm4=3038fe387bea66e5e11dba712e352c4b f=cd3|xmm0=ff5d45b22f1ccd79948c190244f2292a f=cd1/0
  #|psignd xmm0, xmm4|660f380ac4|PSIGNDrr:%XMM0,%XMM0,%XMM4|xmm0=d2a1162365f19d7bc99d0bf45f805d31 xmm4=d513f70ea9d38e8a20844c5706aca719 f=96|xmm0=2d5ee9dd9a0e6285c99d0bf45f805d31 f=94/0
  #|psignd xmm0, xmmword ptr [rsi]|660f380a06|PSIGNDrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=4 r9=f xmm0=1cb1ab82f8811441cfa1e3f6ee262fd6 f=2 m10080=de69a62de9c1f01be04793a85cdb56fa|xmm0=e34e547e077eebbfcfa1e3f6ee262fd6 f=0/0
  #|phaddw xmm1, xmm5|660f3801cd|PHADDWrr:%XMM1,%XMM1,%XMM5|xmm1=1de2cc20148b8ec3fa135c40be7214b7 xmm5=21ec328e5cf062c372ff1acdc450af1e f=4c6|xmm1=547abfb38dcc736eea02a34e5653d329 f=4c4/0
  #|phaddw xmm1, xmm5|660f3801cd|PHADDWrr:%XMM1,%XMM1,%XMM5|xmm1=45948a913117ecbc83f34d89ea946fad xmm5=80008000800080008000800080008000 f=8c7|xmm1=d0251dd3d17c5a41 f=8c5/0
  #|phaddw xmm1, xmmword ptr [rsi]|660f38010e|PHADDWrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=3 r9=6 xmm1=8b5943bc63f3b77203e3ec2ae1bfd51b f=97 m10080=4e04cd890ccf7a3cd668c6ba26d7ab1a|xmm1=f1d1239c0b868e1bcf151b65f00db6da f=95/0
  #|phaddd xmm15, xmm7|66440f3802ff|PHADDDrr:%XMM15,%XMM15,%XMM7|xmm7=0 xmm15=a1136a22edb8d754d1d4dc0bb5b98c9a f=892|xmm15=8ecc4176878e68a5 f=890/0
  #|phaddd xmm15, xmm7|66440f3802ff|PHADDDrr:%XMM15,%XMM15,%XMM7|xmm7=ffffffffffffffffffffffffffffffff xmm15=0 f=52|xmm15=fffffffefffffffe0000000000000000 f=50/0
  #|phaddd xmm15, xmmword ptr [rsi]|66440f38023e|PHADDDrm:%XMM15,%XMM15,%RSI,1,%,0,%|rbx=3 r9=8 xmm15=c9deb9e54ae6b4ed6aadc8f8be6febcd f=892 m10080=7363edac8ed38e25b5f8243a998e15dc|xmm15=163a874ed27c370114c56ed2291db4c5 f=890/0
  #|pmaddubsw xmm3, xmm10|66410f3804da|PMADDUBSWrr:%XMM3,%XMM3,%XMM10|xmm3=c8d1fb49ae66489594092810c615a018 xmm10=83c0a933c2463f776d9875f6d730a066 f=896|xmm3=8000b93ef1c056fb3b5c11a8e43acd90 f=894/0
  #|pmaddubsw xmm3, xmm10|66410f3804da|PMADDUBSWrr:%XMM3,%XMM3,%XMM10|xmm3=373fcaee0c91c652045c78413f747ee2 xmm10=d6f371dfb75158398c1c1bea995ef820 f=d7|xmm3=f3c73a7c2a75565208400712113f1850 f=d5/0
  #|pmaddubsw xmm3, xmmword ptr [rsi]|660f38041e|PMADDUBSWrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=5 r9=e xmm3=522971a59de4562dbb0d4d4d492c5a5 f=4d2 m10080=2f4de974663b427ba2135b5279fbce50|xmm3=faec09576b6ce1237fff7fff52f2598c f=4d0/0
  #|pmulhrsw xmm5, xmm2|660f380bea|PMULHRSWrr:%XMM5,%XMM5,%XMM2|xmm2=a3e56c743a1e64fefaeb192ed65f0325 xmm5=6c8678718ccad18194fd32cd47964ced f=8d2|xmm5=b1e9660ccbb1db51044009fee8b801e4 f=8d0/0
  #|pmulhrsw xmm5, xmm2|660f380bea|PMULHRSWrr:%XMM5,%XMM5,%XMM2|xmm2=28e3b0f9253461466c2c7f8081e635ee xmm5=d0243c83ba9ce078736c6de420d0dbfe f=893|xmm5=f0b6daa4ebd5e80a618b6d76dfadf0d4 f=891/0
  #|pmulhrsw xmm5, xmmword ptr [rsi]|660f380b2e|PMULHRSWrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=2 r9=1 xmm5=52a0842032281bbb58c41a89dfd7cdd0 f=8c2 m10080=ad723372dbfa3765e2af1d68bdab67ac|xmm5=ca09518c28cceea54631feefe34fd309 f=8c0/0
  #|movdqa xmm1, xmm4|660f6fcc|MOVDQArr:%XMM1,%XMM4|xmm1=59ce902943a73633d94df16fb57dd892 xmm4=fd417cfb19dc482f7b400aa0080ed074 f=47|xmm1=fd417cfb19dc482f7b400aa0080ed074 f=45/0
  #|movdqa xmm1, xmm4|660f6fcc|MOVDQArr:%XMM1,%XMM4|xmm1=89b9d12748e4fb451035511d14629058 xmm4=2b32e50c3f83e333229799aa116c93ab f=846|xmm1=2b32e50c3f83e333229799aa116c93ab f=844/0
  #|movdqa xmm1, xmmword ptr [rsi]|660f6f0e|MOVDQArm:%XMM1,%RSI,1,%,0,%|rbx=e r9=9 xmm1=c8d392aeab5d950561f5257f3c831814 f=802 m10080=f4f41f4445e5b0cec89a15d8b1501b80|xmm1=801b50b1d8159ac8ceb0e545441ff4f4 f=800/0
  #|movdqu xmm5, xmm3|f30f6feb|MOVDQUrr:%XMM5,%XMM3|xmm3=14feaf089e947303640ce0749c92b57e xmm5=605b351cce5f52e264e0ed2dfe05d34b f=892|xmm5=14feaf089e947303640ce0749c92b57e f=890/0
  #|movdqu xmm5, xmm3|f30f6feb|MOVDQUrr:%XMM5,%XMM3|xmm3=157e083379d1af70396ba9db994b7490 xmm5=166952e1eafc632cea27c9709c7534d2 f=42|xmm5=157e083379d1af70396ba9db994b7490 f=40/0
  #|movdqu xmm5, xmmword ptr [rbp - 0x20]|f30f6f6de0|MOVDQUrm:%XMM5,%RBP,1,%,-32,%|rbx=b r9=d xmm5=0 f=887 m20160=a8c0a3d74840bd08e6ec7a7e5a49f0ff|xmm5=fff0495a7e7aece608bd4048d7a3c0a8 f=885/0
  #|movaps xmm1, xmm7|0f28cf|MOVAPSrr:%XMM1,%XMM7|xmm1=fb685ede9ce0b608fd67e87ca1c05097 xmm7=ea4d7edf4c51852a68ab42bee9f1cf5d f=42|xmm1=ea4d7edf4c51852a68ab42bee9f1cf5d f=40/0
  #|movaps xmm1, xmm7|0f28cf|MOVAPSrr:%XMM1,%XMM7|xmm1=eac98e945734e007a57297f9e359beee xmm7=327501d2b03ebd62dd9639f52179bb02 f=17|xmm1=327501d2b03ebd62dd9639f52179bb02 f=15/0
  #|movaps xmm1, xmmword ptr [rsi]|0f280e|MOVAPSrm:%XMM1,%RSI,1,%,0,%|rbx=7 r9=2 xmm1=fe3fa7e49cf7d8e2424ffc07ac1a6bc5 f=c06 m10080=64bd48574be18030ff8380777b1c99ce|xmm1=ce991c7b778083ff3080e14b5748bd64 f=c04/0
  #|movups xmm1, xmm3|0f10cb|MOVUPSrr:%XMM1,%XMM3|xmm1=42b94d2a96b13e2d4a0cf2babbcd1183 xmm3=80008000800080008000800080008000 f=47|xmm1=80008000800080008000800080008000 f=45/0
  #|movups xmm1, xmm3|0f10cb|MOVUPSrr:%XMM1,%XMM3|xmm1=80008000800080008000800080008000 xmm3=462dd16895aca4426f6d7c457d2efc4 f=892|xmm1=462dd16895aca4426f6d7c457d2efc4 f=890/0
  #|movups xmm1, xmmword ptr [rbp - 0x20]|0f104de0|MOVUPSrm:%XMM1,%RBP,1,%,-32,%|rbx=6 r9=e xmm1=a47d1a146f9329ae7aaa44b92d819411 f=8d7 m20160=4d40414aacaa5fdf2640c8b9b3ca041a|xmm1=1a04cab3b9c84026df5faaac4a41404d f=8d5/0
  #|movapd xmm0, xmm5|660f28c5|MOVAPDrr:%XMM0,%XMM5|xmm0=0 xmm5=71ccd4eb802f9c01371fae0ad3b3ef50 f=482|xmm0=71ccd4eb802f9c01371fae0ad3b3ef50 f=480/0
  #|movapd xmm0, xmm5|660f28c5|MOVAPDrr:%XMM0,%XMM5|xmm0=c9e0c12a09739cf0896539c555cf7dd5 xmm5=bc5024fc01a2122509a557e9273c76a9 f=8d6|xmm0=bc5024fc01a2122509a557e9273c76a9 f=8d4/0
  #|movapd xmm0, xmmword ptr [rsi]|660f2806|MOVAPDrm:%XMM0,%RSI,1,%,0,%|rbx=c r9=2 xmm0=fe527da7f806d76277555153985f4a62 f=802 m10080=b39147d057e593505191f73040cf4f60|xmm0=604fcf4030f791515093e557d04791b3 f=800/0
  #|andps xmm3, xmm1|0f54d9|ANDPSrr:%XMM3,%XMM3,%XMM1|xmm1=80008000800080008000800080008000 xmm3=ebe38a3a8a12f05949efe68917f7a88a f=47|xmm3=80008000800080000000800000008000 f=45/0
  #|andps xmm3, xmm1|0f54d9|ANDPSrr:%XMM3,%XMM3,%XMM1|xmm1=ffffffffffffffffffffffffffffffff xmm3=486bc3b0ab4436104cc650e3a362b347 f=56|f=54/0
  #|andps xmm3, xmmword ptr [rsi]|0f541e|ANDPSrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=b r9=b xmm3=12340f8c307b1b2dc31c4e3f640897b1 f=16 m10080=3a4d12d9ea927236633004a1d1f2977f|xmm3=12140280200010210210022a40000530 f=14/0
  #|andpd xmm4, xmm0|660f54e0|ANDPDrr:%XMM4,%XMM4,%XMM0|xmm0=fc9a6d4864927b6583dfdc228793edda xmm4=af538256e8f6a3ffb724e14e857f944e f=8c6|xmm4=ac120040609223658304c0028513844a f=8c4/0
  #|andpd xmm4, xmm0|660f54e0|ANDPDrr:%XMM4,%XMM4,%XMM0|xmm0=73f71b1d28a5c74ce04fafa9b8118bc3 xmm4=5f6b595c03a5dd7bf19755a5c637a29a f=857|xmm4=5363191c00a5c548e00705a180118282 f=855/0
  #|andpd xmm4, xmmword ptr [rsi]|660f5426|ANDPDrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=7 r9=9 xmm4=a2f5bfdd619c5d2dbf98dc9e7891129 f=c7 m10080=c44b3f3eabd4af3c4ee088a599e7edb3|xmm4=22d43998408c04218a9848926090100 f=c5/0
  #|orps xmm0, xmm5|0f56c5|ORPSrr:%XMM0,%XMM0,%XMM5|xmm0=5c943fd026df3123aa6993bd9e0c93ab xmm5=0 f=c53|f=c51/0
  #|orps xmm0, xmm5|0f56c5|ORPSrr:%XMM0,%XMM0,%XMM5|xmm0=817baf990ba8f24a41a94d9967f7bf2 xmm5=0 f=8c7|f=8c5/0
  #|orps xmm0, xmmword ptr [rsi]|0f5606|ORPSrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=1 r9=1 xmm0=a534c7e7a77cc58c6e7b899b435c089c f=82 m10080=ff1a6b30a3f232123dcb472e2fa64b59|xmm0=fd7fe7efaf7fcfbd7e7bfbbb737f1aff f=80/0
  #|orpd xmm3, xmm0|660f56d8|ORPDrr:%XMM3,%XMM3,%XMM0|xmm0=6e581e44f937b130feb5d9d2939bbb87 xmm3=5757edee7adeaf53b1b5914ef7dcadf f=97|xmm3=6f7d7edeffbffbf5ffbfd9d6fffffbdf f=95/0
  #|orpd xmm3, xmm0|660f56d8|ORPDrr:%XMM3,%XMM3,%XMM0|xmm0=80008000800080008000800080008000 xmm3=570e4e1488d1b8bb0187a5544258bc4a f=803|xmm3=d70ece1488d1b8bb8187a554c258bc4a f=801/0
  #|orpd xmm3, xmmword ptr [rsi]|660f561e|ORPDrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=8 r9=e xmm3=61db41bbf3f92b67c2863e58bf132f49 f=7 m10080=28a1b5a649b9e3c78744c7c657f64fa3|xmm3=e3dff7fff7ff6fe7c7e7bf59bfb7af69 f=5/0
  #|xorps xmm5, xmm2|0f57ea|XORPSrr:%XMM5,%XMM5,%XMM2|xmm2=24482dbb191bf343768f40be5285d321 xmm5=d6f7fe1b7e7294b21ec4a36f6eb3d72c f=487|xmm5=f2bfd3a0676967f1684be3d13c36040d f=485/0
  #|xorps xmm5, xmm2|0f57ea|XORPSrr:%XMM5,%XMM5,%XMM2|xmm2=d0f730763fccfa2badd8570848dc435b xmm5=c9f49d0650d283bdda2157526a9f076f f=806|xmm5=1903ad706f1e799677f9005a22434434 f=804/0
  #|xorps xmm5, xmmword ptr [rsi]|0f572e|XORPSrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=2 r9=e xmm5=0 f=8d3 m10080=a28f31124af831c27b41cd57c7a8567d|xmm5=7d56a8c757cd417bc231f84a12318fa2 f=8d1/0
  #|xorpd xmm2, xmm0|660f57d0|XORPDrr:%XMM2,%XMM2,%XMM0|xmm0=496cada462c24af2fa49c8d2841270e3 xmm2=eab66f02ea0c674441b910ec97d85fed f=42|xmm2=a3dac2a688ce2db6bbf0d83e13ca2f0e f=40/0
  #|xorpd xmm2, xmm0|660f57d0|XORPDrr:%XMM2,%XMM2,%XMM0|xmm0=80008000800080008000800080008000 xmm2=161cb6020fb9fd809928c4eb3505179a f=43|xmm2=961c36028fb97d80192844ebb505979a f=41/0
  #|xorpd xmm2, xmmword ptr [rsi]|660f5716|XORPDrm:%XMM2,%XMM2,%RSI,1,%,0,%|rbx=f r9=f xmm2=c0bb20b9257743408f93819d0870fefa f=406 m10080=e3798f0b9c3c8cb338c4ea945b7b0869|xmm2=a9b35be2b19d87783c1fbd0103ff8719 f=404/0
  #|andnps xmm4, xmm0|0f55e0|ANDNPSrr:%XMM4,%XMM4,%XMM0|xmm0=ffffffffffffffffffffffffffffffff xmm4=d40af94e68f148f5b6fecd0ab9084ea9 f=843|xmm4=2bf506b1970eb70a490132f546f7b156 f=841/0
  #|andnps xmm4, xmm0|0f55e0|ANDNPSrr:%XMM4,%XMM4,%XMM0|xmm0=39bf9bc7a4f6064e2a35fe7880d2553e xmm4=85a2e78ee94a5ff08891778fa38765da f=86|xmm4=381d184104b4000e2224887000501024 f=84/0
  #|andnps xmm4, xmmword ptr [rsi]|0f5526|ANDNPSrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=9 r9=0 xmm4=b86e7f7743d385fec05e71d33a7df495 f=887 m10080=17b60b9656cd956f1acb5b2080c6636b|xmm4=4301808020084a002f818c0484020202 f=885/0
  #|andnpd xmm3, xmm7|660f55df|ANDNPDrr:%XMM3,%XMM3,%XMM7|xmm3=5b2578133a1e08c641a9f3d16b211e6 xmm7=c6a838039bcfab7e81d2840f13a0a34c f=483|xmm3=c2082802884e0b7281c000020100a208 f=481/0
  #|andnpd xmm3, xmm7|660f55df|ANDNPDrr:%XMM3,%XMM3,%XMM7|xmm3=6c1a1029c22c9d11d90a37aae8e71823 xmm7=b87e76a125fafd96a9a2ac22312fc7f4 f=893|xmm3=9064668025d2608620a088001108c7d4 f=891/0
  #|andnpd xmm3, xmmword ptr [rsi]|660f551e|ANDNPDrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=8 r9=0 xmm3=1516ac05108cec861a797156a230ee75 f=6 m10080=8fa2244a4edbcaf69cfd6452a9dbe7fc|xmm3=e8e153a842601118e4828a084804008a f=4/0
  #|unpcklps xmm3, xmm8|410f14d8|UNPCKLPSrr:%XMM3,%XMM3,%XMM8|xmm3=4baf2bfdaf601589f6387dec4da1b0f1 xmm8=fcd7a0e4833fed7b53ed444246adb541 f=807|xmm3=53ed4442f6387dec46adb5414da1b0f1 f=805/0
  #|unpcklps xmm3, xmm8|410f14d8|UNPCKLPSrr:%XMM3,%XMM3,%XMM8|xmm3=341c939cff9ad8b982e9d0f9e57e0770 xmm8=80008000800080008000800080008000 f=2|xmm3=8000800082e9d0f980008000e57e0770 f=0/0
  #|unpcklps xmm3, xmmword ptr [rsi]|0f141e|UNPCKLPSrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=e r9=3 xmm3=9a8a03f3c2bc884f05ebbc19fa80584d f=57 m10080=1e90e525ab6e12cd369f2023cd840b1c|xmm3=cd126eab05ebbc1925e5901efa80584d f=55/0
  #|unpckhps xmm4, xmm7|0f15e7|UNPCKHPSrr:%XMM4,%XMM4,%XMM7|xmm4=e5b7bec3b4a20510983f14ea088e5ce7 xmm7=e78b9f33d7c07c8c272c77cd59261131 f=6|xmm4=e78b9f33e5b7bec3d7c07c8cb4a20510 f=4/0
  #|unpckhps xmm4, xmm7|0f15e7|UNPCKHPSrr:%XMM4,%XMM4,%XMM7|xmm4=4c82eccafce85fd7f847ba63ad70e26d xmm7=d69ffeaca47e07ea671101eb238783df f=4c2|xmm4=d69ffeac4c82eccaa47e07eafce85fd7 f=4c0/0
  #|unpckhps xmm4, xmmword ptr [rsi]|0f1526|UNPCKHPSrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=c r9=d xmm4=94c2a03b5e815f446f63f64126e28c7f f=c2 m10080=202b02298b4de7132c37be46ddd14907|xmm4=749d1dd94c2a03b46be372c5e815f44 f=c0/0
  #|movhlps xmm4, xmm5|0f12e5|MOVHLPSrr:%XMM4,%XMM4,%XMM5|xmm4=2792c4c751b00d7c09bde2a126d5410d xmm5=441a73650bc3e15e68e614f3bae0b508 f=887|xmm4=2792c4c751b00d7c441a73650bc3e15e f=885/0
  #|movhlps xmm4, xmm5|0f12e5|MOVHLPSrr:%XMM4,%XMM4,%XMM5|xmm4=66da1d781d35ed092f9a8db78631d4cd xmm5=5aeaec3c580cc9ba36cac367da06223c f=806|xmm4=66da1d781d35ed095aeaec3c580cc9ba f=804/0
  #|movlhps xmm5, xmm4|0f16ec|MOVLHPSrr:%XMM5,%XMM5,%XMM4|xmm4=f252f4fe492a0e220999947cfc57c16 xmm5=0 f=847|xmm5=20999947cfc57c160000000000000000 f=845/0
  #|movlhps xmm5, xmm4|0f16ec|MOVLHPSrr:%XMM5,%XMM5,%XMM4|xmm4=954854b4f652cdbd5c4f88c025a8a933 xmm5=a9c4c0b5fa2ee1f4abc35f0002947336 f=893|xmm5=5c4f88c025a8a933abc35f0002947336 f=891/0
  #|pmovzxbw xmm3, xmm7|660f3830df|PMOVZXBWrr:%XMM3,%XMM7|xmm3=12a47d0638c171667ae9762ce1ffb508 xmm7=97a9e8fab11ffa251bcac1fd007755a0 f=8c3|xmm3=1b00ca00c100fd00000077005500a0 f=8c1/0
  #|pmovzxbw xmm3, xmm7|660f3830df|PMOVZXBWrr:%XMM3,%XMM7|xmm3=b3425d9239e9f11e1702540de46f9167 xmm7=e50d794c26929f07e81c68d732b84b63 f=d6|xmm3=e8001c006800d7003200b8004b0063 f=d4/0
  #|pmovzxbw xmm3, qword ptr [rdi + 0x10]|660f38305f10|PMOVZXBWrm:%XMM3,%RDI,1,%,16,%|rbx=b r9=a xmm3=621879144e30e2852a1d56cb9081649c f=886 m10110=8bd9cea1d95ea1a5e1753825654dd546|xmm3=a500a1005e00d900a100ce00d9008b f=884/0
  #|pmovzxbd xmm6, xmm7|660f3831f7|PMOVZXBDrr:%XMM6,%XMM7|xmm6=ffffffffffffffffffffffffffffffff xmm7=8330672314b137a4305f5044342c5b01 f=4c6|xmm6=340000002c0000005b00000001 f=4c4/0
  #|pmovzxbd xmm6, xmm7|660f3831f7|PMOVZXBDrr:%XMM6,%XMM7|xmm6=b27807711775e05b858fe0e6d78fb7ac xmm7=0 f=d3|xmm6=0 f=d1/0
  #|pmovzxbd xmm6, dword ptr [rsi]|660f383136|PMOVZXBDrm:%XMM6,%RSI,1,%,0,%|rbx=d r9=1 xmm6=61cfe637ac086e7a789bb3e7669419c5 f=d6 m10080=2fdc34e6d7eb8fc2e3ddc8ce5be6c315|xmm6=e600000034000000dc0000002f f=d4/0
  #|pmovzxwd xmm4, xmm0|660f3833e0|PMOVZXWDrr:%XMM4,%XMM0|xmm0=871457abfd3e34da726636f10bdbc90e xmm4=107e9b4e40833451ad097efff158a53b f=8d7|xmm4=7266000036f100000bdb0000c90e f=8d5/0
  #|pmovzxwd xmm4, xmm0|660f3833e0|PMOVZXWDrr:%XMM4,%XMM0|xmm0=ffffffffffffffffffffffffffffffff xmm4=4693bd5a488b64bc8d1ef9d76ba92780 f=c6|xmm4=ffff0000ffff0000ffff0000ffff f=c4/0
  #|pmovzxwd xmm4, qword ptr [rbp - 0x20]|660f383365e0|PMOVZXWDrm:%XMM4,%RBP,1,%,-32,%|rbx=1 r9=1 xmm4=ffffffffffffffffffffffffffffffff f=842 m20160=e5fec441bd3c48b7cc1c6bb0b647fd5e|xmm4=b74800003cbd000041c40000fee5 f=840/0
  #|pmovzxdq xmm6, xmm4|660f3835f4|PMOVZXDQrr:%XMM6,%XMM4|xmm4=ffffffffffffffffffffffffffffffff xmm6=d4750380739d8b7b757167a80c005a73 f=43|xmm6=ffffffff00000000ffffffff f=41/0
  #|pmovzxdq xmm6, xmm4|660f3835f4|PMOVZXDQrr:%XMM6,%XMM4|xmm4=17dc302a0d4d1d55e93391d3d71a7f40 xmm6=5d7a0881f3e504689cae191577b7f668 f=c16|xmm6=e93391d300000000d71a7f40 f=c14/0
  #|pmovzxdq xmm6, qword ptr [rbp - 0x20]|660f383575e0|PMOVZXDQrm:%XMM6,%RBP,1,%,-32,%|rbx=d r9=d xmm6=b23892907dcb0bcf2d6165affc3b09c8 f=8d3 m20160=432e82063d0a554b246fbece4cb9f40b|xmm6=4b550a3d0000000006822e43 f=8d1/0
  #|pmovsxbw xmm7, xmm3|660f3820fb|PMOVSXBWrr:%XMM7,%XMM3|xmm3=8940e4bf098ab5ae65c536409fb5c991 xmm7=5136f0a583e25d3a8cf24811749ea4f2 f=8d6|xmm7=65ffc500360040ff9fffb5ffc9ff91 f=8d4/0
  #|pmovsxbw xmm7, xmm3|660f3820fb|PMOVSXBWrr:%XMM7,%XMM3|xmm3=0 xmm7=1b0e47903dab49fe449b6fc53f5289cf f=413|xmm7=0 f=411/0
  #|pmovsxbw xmm7, qword ptr [rbp - 0x20]|660f38207de0|PMOVSXBWrm:%XMM7,%RBP,1,%,-32,%|rbx=9 r9=a xmm7=dbd647242e84021ff35fcd0a01d415ec f=c97 m20160=fd58b425f04718f38fcd7d011abd4615|xmm7=fff300180047fff00025ffb40058fffd f=c95/0
  #|pmovsxwd xmm4, xmm1|660f3823e1|PMOVSXWDrr:%XMM4,%XMM1|xmm1=1ac56fe0cf73e601a48497d46ad08f16 xmm4=bb98a7030eae722bfbebb8ae4bbc757a f=452|xmm4=ffffa484ffff97d400006ad0ffff8f16 f=450/0
  #|pmovsxwd xmm4, xmm1|660f3823e1|PMOVSXWDrr:%XMM4,%XMM1|xmm1=8ae1cc9381c4d10708c7372d8d3cafe6 xmm4=80008000800080008000800080008000 f=486|xmm4=8c70000372dffff8d3cffffafe6 f=484/0
  #|pmovsxwd xmm4, qword ptr [rsi]|660f382326|PMOVSXWDrm:%XMM4,%RSI,1,%,0,%|rbx=9 r9=7 xmm4=55537f88c1e1645028d996baee7f93fd f=8d2 m10080=d0d0e4986f5d5097ae1d191a21596d51|xmm4=ffff975000005d6fffff98e4ffffd0d0 f=8d0/0
  #|pmovsxdq xmm4, xmm2|660f3825e2|PMOVSXDQrr:%XMM4,%XMM2|xmm2=f5eae6e9d47dd0b356386d709ac74728 xmm4=44c0258ab1ec3842ae6c44c1c224006a f=86|xmm4=56386d70ffffffff9ac74728 f=84/0
  #|pmovsxdq xmm4, xmm2|660f3825e2|PMOVSXDQrr:%XMM4,%XMM2|xmm2=bf9796c910e27edc2a93f938513cf347 xmm4=a5f42ae2ed0f252e81150a9701748d6d f=52|xmm4=2a93f93800000000513cf347 f=50/0
  #|pmovsxdq xmm4, qword ptr [rdi + 0x10]|660f38256710|PMOVSXDQrm:%XMM4,%RDI,1,%,16,%|rbx=6 r9=f xmm4=eaadb7be28613aa36a92f310160d69a5 f=886 m10110=078e706e4f6b443e7f5e9dce080b6373|xmm4=3e446b4f000000006e708e07 f=884/0
  #|psllw xmm5, 0|660f71f500|PSLLWri:%XMM5,%XMM5,0|xmm5=b4b6f7e4199e8c7358a4dbf7a3e9e8fa f=17|f=15/0
  #|psllw xmm5, 1|660f71f501|PSLLWri:%XMM5,%XMM5,1|xmm5=77a5b93f01b7ffd189e47e27e21294ac f=c82|xmm5=ef4a727e036effa213c8fc4ec4242958 f=c80/0
  #|psllw xmm5, 15|660f71f50f|PSLLWri:%XMM5,%XMM5,15|xmm5=ffffffffffffffffffffffffffffffff f=892|xmm5=80008000800080008000800080008000 f=890/0
  #|psllw xmm5, 16|660f71f510|PSLLWri:%XMM5,%XMM5,16|xmm5=c63f3107badee1d10fe42f09a12952b6 f=447|xmm5=0 f=445/0
  #|psllw xmm5, 31|660f71f51f|PSLLWri:%XMM5,%XMM5,31|xmm5=fa561c20cbd5a75ba3e4f1fc0f063c59 f=d2|xmm5=0 f=d0/0
  #|psllw xmm5, 32|660f71f520|PSLLWri:%XMM5,%XMM5,32|xmm5=74b286702c10d6a30cb13cc409cb9bd8 f=856|xmm5=0 f=854/0
  #|psllw xmm5, 63|660f71f53f|PSLLWri:%XMM5,%XMM5,63|xmm5=88a5f3e7b8e755e22c6cf81ba52a15ff f=416|xmm5=0 f=414/0
  #|psllw xmm5, 64|660f71f540|PSLLWri:%XMM5,%XMM5,64|xmm5=ffffffffffffffffffffffffffffffff f=816|xmm5=0 f=814/0
  #|psllw xmm5, 255|660f71f5ff|PSLLWri:%XMM5,%XMM5,255|xmm5=95408448fd4c470e804905abceeb9f8f f=407|xmm5=0 f=405/0
  #|psllw xmm5, xmm6|660ff1ee|PSLLWrr:%XMM5,%XMM5,%XMM6|xmm5=317267d536d06aaaa4f8ad6a879ce8c8 xmm6=3f f=52|xmm5=0 f=50/0
  #|psllw xmm5, xmm6|660ff1ee|PSLLWrr:%XMM5,%XMM5,%XMM6|xmm5=8bd574e0ab87b0afea142bf4b5058204 xmm6=5cf3b6769bd02ea89602b2f0ffbe9ca5 f=416|xmm5=0 f=414/0
  #|psllw xmm5, xmm6|660ff1ee|PSLLWrr:%XMM5,%XMM5,%XMM6|xmm5=ad4c6791ead6e775ff825a2ab0cf373c xmm6=10 f=c86|xmm5=0 f=c84/0
  #|pslld xmm5, 0|660f72f500|PSLLDri:%XMM5,%XMM5,0|xmm5=ff53a052e4d211ec2db6b73c9e0afe35 f=802|f=800/0
  #|pslld xmm5, 1|660f72f501|PSLLDri:%XMM5,%XMM5,1|xmm5=5e689fdd15b5490484224bf67105f93a f=812|xmm5=bcd13fba2b6a9208084497ece20bf274 f=810/0
  #|pslld xmm5, 2|660f72f502|PSLLDri:%XMM5,%XMM5,2|xmm5=5e53ac70d3ecb0712926e5e00d7cc9b5 f=4c7|xmm5=794eb1c04fb2c1c4a49b978035f326d4 f=4c5/0
  #|pslld xmm5, 16|660f72f510|PSLLDri:%XMM5,%XMM5,16|xmm5=e049cb593fa4ffce1f93c84910c8e652 f=d7|xmm5=cb590000ffce0000c8490000e6520000 f=d5/0
  #|pslld xmm5, 31|660f72f51f|PSLLDri:%XMM5,%XMM5,31|xmm5=5da5a44001258e2c352367e74f78455a f=d3|xmm5=8000000000000000 f=d1/0
  #|pslld xmm5, 32|660f72f520|PSLLDri:%XMM5,%XMM5,32|xmm5=d944b41285f35e79625f727243875490 f=c52|xmm5=0 f=c50/0
  #|pslld xmm5, 63|660f72f53f|PSLLDri:%XMM5,%XMM5,63|xmm5=15ca24373bb64cb08c3a2c760ce8683d f=c6|xmm5=0 f=c4/0
  #|pslld xmm5, 64|660f72f540|PSLLDri:%XMM5,%XMM5,64|xmm5=76c63941015b874213788a67b7d07599 f=83|xmm5=0 f=81/0
  #|pslld xmm5, 255|660f72f5ff|PSLLDri:%XMM5,%XMM5,255|xmm5=5c88f504933016ec6f673b7961d0b0bf f=842|xmm5=0 f=840/0
  #|pslld xmm5, xmm6|660ff2ee|PSLLDrr:%XMM5,%XMM5,%XMM6|xmm5=a5a6a04c243fa10f596d2abf28ca78a0 xmm6=20 f=cc2|xmm5=0 f=cc0/0
  #|pslld xmm5, xmm6|660ff2ee|PSLLDrr:%XMM5,%XMM5,%XMM6|xmm5=5bd2c6cbff1b98d3dd896c84931a7c65 xmm6=11 f=7|xmm5=8d96000031a60000d9080000f8ca0000 f=5/0
  #|pslld xmm5, xmm6|660ff2ee|PSLLDrr:%XMM5,%XMM5,%XMM6|xmm5=c9711c30f603d31a75fd6df7ae9b1eea xmm6=10000000000 f=53|xmm5=0 f=51/0
  #|psllq xmm3, 0|660f73f300|PSLLQri:%XMM3,%XMM3,0|xmm3=be8d124c5da5913975850cc5ede07fc1 f=43|f=41/0
  #|psllq xmm3, 1|660f73f301|PSLLQri:%XMM3,%XMM3,1|xmm3=34016fddf4991ab9a5691050a17dceec f=842|xmm3=6802dfbbe93235724ad220a142fb9dd8 f=840/0
  #|psllq xmm3, 13|660f73f30d|PSLLQri:%XMM3,%XMM3,13|xmm3=ffffffffffffffffffffffffffffffff f=856|xmm3=ffffffffffffe000ffffffffffffe000 f=854/0
  #|psllq xmm3, 16|660f73f310|PSLLQri:%XMM3,%XMM3,16|xmm3=ae51483c4e653490b732ad537ec9064 f=c42|xmm3=1483c4e6534900002ad537ec90640000 f=c40/0
  #|psllq xmm3, 31|660f73f31f|PSLLQri:%XMM3,%XMM3,31|xmm3=7a02876f0aecca8b5bdedd75cfcca6a4 f=2|xmm3=8576654580000000e7e6535200000000 f=0/0
  #|psllq xmm3, 32|660f73f320|PSLLQri:%XMM3,%XMM3,32|xmm3=9f6f7c8daa4d5b7fa32947574c5e792f f=887|xmm3=aa4d5b7f000000004c5e792f00000000 f=885/0
  #|psllq xmm3, 63|660f73f33f|PSLLQri:%XMM3,%XMM3,63|xmm3=aa8662df44787271a5cb52d5b929417a f=c92|xmm3=80000000000000000000000000000000 f=c90/0
  #|psllq xmm3, 64|660f73f340|PSLLQri:%XMM3,%XMM3,64|xmm3=ebe59bfc937fb44cea25af189533a1b6 f=8c6|xmm3=0 f=8c4/0
  #|psllq xmm3, 255|660f73f3ff|PSLLQri:%XMM3,%XMM3,255|xmm3=0 f=2|f=0/0
  #|psllq xmm3, xmm4|660ff3dc|PSLLQrr:%XMM3,%XMM3,%XMM4|xmm3=4d7598a311f98a7f40352875459c74e4 xmm4=20 f=57|xmm3=11f98a7f00000000459c74e400000000 f=55/0
  #|psllq xmm3, xmm4|660ff3dc|PSLLQrr:%XMM3,%XMM3,%XMM4|xmm3=9ca49307bf39592c54389e436fe53924 xmm4=10000000000 f=c83|xmm3=0 f=c81/0
  #|psllq xmm3, xmm4|660ff3dc|PSLLQrr:%XMM3,%XMM3,%XMM4|xmm3=ffffffffffffffffffffffffffffffff xmm4=41 f=443|xmm3=0 f=441/0
  #|psrlw xmm1, 0|660f71d100|PSRLWri:%XMM1,%XMM1,0|xmm1=e8690ebda44b075709e030e33198fca6 f=97|f=95/0
  #|psrlw xmm1, 1|660f71d101|PSRLWri:%XMM1,%XMM1,1|xmm1=f2bf17840ddcbdbc4737841b64516d4c f=cd6|xmm1=795f0bc206ee5ede239b420d322836a6 f=cd4/0
  #|psrlw xmm1, 8|660f71d108|PSRLWri:%XMM1,%XMM1,8|xmm1=0 f=882|f=880/0
  #|psrlw xmm1, 16|660f71d110|PSRLWri:%XMM1,%XMM1,16|xmm1=6ee1ce0d759a05e9f743d01a0b8759b3 f=857|xmm1=0 f=855/0
  #|psrlw xmm1, 31|660f71d11f|PSRLWri:%XMM1,%XMM1,31|xmm1=9b50f95e69521c0eb8bb460eb443f89 f=807|xmm1=0 f=805/0
  #|psrlw xmm1, 32|660f71d120|PSRLWri:%XMM1,%XMM1,32|xmm1=d7fc28aa5da727503ffd041a93cda8f6 f=4d2|xmm1=0 f=4d0/0
  #|psrlw xmm1, 63|660f71d13f|PSRLWri:%XMM1,%XMM1,63|xmm1=55e430c959209086919f0aead57c1a1e f=d6|xmm1=0 f=d4/0
  #|psrlw xmm1, 64|660f71d140|PSRLWri:%XMM1,%XMM1,64|xmm1=c005becde00648d52bbe41a49ab8d68f f=806|xmm1=0 f=804/0
  #|psrlw xmm1, 255|660f71d1ff|PSRLWri:%XMM1,%XMM1,255|xmm1=200584e6373657dabe7966f234c0caaf f=8c6|xmm1=0 f=8c4/0
  #|psrlw xmm1, xmm2|660fd1ca|PSRLWrr:%XMM1,%XMM1,%XMM2|xmm1=80008000800080008000800080008000 xmm2=21 f=7|xmm1=0 f=5/0
  #|psrlw xmm1, xmm2|660fd1ca|PSRLWrr:%XMM1,%XMM1,%XMM2|xmm1=9544935b22d451cd1d5b3ec61502a8e1 xmm2=40 f=92|xmm1=0 f=90/0
  #|psrlw xmm1, xmm2|660fd1ca|PSRLWrr:%XMM1,%XMM1,%XMM2|xmm1=a67473d9eed6e4a25157edfc98ac308b xmm2=10 f=8c2|xmm1=0 f=8c0/0
  #|psrld xmm7, 0|660f72d700|PSRLDri:%XMM7,%XMM7,0|xmm7=27b6d46921abfeaa60b81530e7044782 f=cc7|f=cc5/0
  #|psrld xmm7, 1|660f72d701|PSRLDri:%XMM7,%XMM7,1|xmm7=fefddc72afc10d9e7bd7f4f5fea3edc2 f=4c2|xmm7=7f7eee3957e086cf3debfa7a7f51f6e1 f=4c0/0
  #|psrld xmm7, 15|660f72d70f|PSRLDri:%XMM7,%XMM7,15|xmm7=c360f11ae5744b67f1488be11aba925e f=43|xmm7=186c10001cae80001e29100003575 f=41/0
  #|psrld xmm7, 16|660f72d710|PSRLDri:%XMM7,%XMM7,16|xmm7=c97504791d6a774c967c1ceda2f6dc8 f=cd6|xmm7=c97000091d60000c9670000da2f f=cd4/0
  #|psrld xmm7, 31|660f72d71f|PSRLDri:%XMM7,%XMM7,31|xmm7=c2a4fbc8d952a7ef6d7a6bef40112aa1 f=d2|xmm7=1000000010000000000000000 f=d0/0
  #|psrld xmm7, 32|660f72d720|PSRLDri:%XMM7,%XMM7,32|xmm7=7e9d5a35a7a08b33d6c63fff24e8d6ae f=442|xmm7=0 f=440/0
  #|psrld xmm7, 63|660f72d73f|PSRLDri:%XMM7,%XMM7,63|xmm7=b8eded4bd0042b0129614b9c0651a04e f=853|xmm7=0 f=851/0
  #|psrld xmm7, 64|660f72d740|PSRLDri:%XMM7,%XMM7,64|xmm7=ffffffffffffffffffffffffffffffff f=407|xmm7=0 f=405/0
  #|psrld xmm7, 255|660f72d7ff|PSRLDri:%XMM7,%XMM7,255|xmm7=63f07bac91cb07c9b6c09a742113935 f=853|xmm7=0 f=851/0
  #|psrld xmm7, xmm8|66410fd2f8|PSRLDrr:%XMM7,%XMM7,%XMM8|xmm7=e2dbdbda73121ae8eb75a2d4fb1da362 xmm8=3f f=56|xmm7=0 f=54/0
  #|psrld xmm7, xmm8|66410fd2f8|PSRLDrr:%XMM7,%XMM7,%XMM8|xmm7=95c57d3433197d15144297195538c7dd xmm8=41 f=4c3|xmm7=0 f=4c1/0
  #|psrld xmm7, xmm8|66410fd2f8|PSRLDrr:%XMM7,%XMM7,%XMM8|xmm7=d3e1ffc318ce9db6269ed5b858d7a870 xmm8=21 f=4c6|xmm7=0 f=4c4/0
  #|psrlq xmm5, 0|660f73d500|PSRLQri:%XMM5,%XMM5,0|xmm5=ffffffffffffffffffffffffffffffff f=843|f=841/0
  #|psrlq xmm5, 1|660f73d501|PSRLQri:%XMM5,%XMM5,1|xmm5=c9066f1fb38532625401c7765ebd1e74 f=4c3|xmm5=6483378fd9c299312a00e3bb2f5e8f3a f=4c1/0
  #|psrlq xmm5, 3|660f73d503|PSRLQri:%XMM5,%XMM5,3|xmm5=481facd545a1aa4edae87d905fd6e6a3 f=cd2|xmm5=903f59aa8b435491b5d0fb20bfadcd4 f=cd0/0
  #|psrlq xmm5, 16|660f73d510|PSRLQri:%XMM5,%XMM5,16|xmm5=ffffffffffffffffffffffffffffffff f=93|xmm5=ffffffffffff0000ffffffffffff f=91/0
  #|psrlq xmm5, 31|660f73d51f|PSRLQri:%XMM5,%XMM5,31|xmm5=7acee10d353ca99f2667ad76034d171f f=16|xmm5=f59dc21a000000004ccf5aec f=14/0
  #|psrlq xmm5, 32|660f73d520|PSRLQri:%XMM5,%XMM5,32|xmm5=585c80a166043c2769838694e56f2044 f=847|xmm5=585c80a10000000069838694 f=845/0
  #|psrlq xmm5, 63|660f73d53f|PSRLQri:%XMM5,%XMM5,63|xmm5=80008000800080008000800080008000 f=97|xmm5=10000000000000001 f=95/0
  #|psrlq xmm5, 64|660f73d540|PSRLQri:%XMM5,%XMM5,64|xmm5=e0a079b0a9e02387d789731ee1ae77af f=cc2|xmm5=0 f=cc0/0
  #|psrlq xmm5, 255|660f73d5ff|PSRLQri:%XMM5,%XMM5,255|xmm5=1b01622bf433d5b1a4bd87d65c848449 f=8d7|xmm5=0 f=8d5/0
  #|psrlq xmm5, xmm6|660fd3ee|PSRLQrr:%XMM5,%XMM5,%XMM6|xmm5=6702b4e9ad0dd99027d99ac433adb43d xmm6=f f=c3|xmm5=ce0569d35a1b00004fb33588675b f=c1/0
  #|psrlq xmm5, xmm6|660fd3ee|PSRLQrr:%XMM5,%XMM5,%XMM6|xmm5=e4d13ef110ce8d33576d758b0214b9ec xmm6=1 f=897|xmm5=72689f78886746992bb6bac5810a5cf6 f=895/0
  #|psrlq xmm5, xmm6|660fd3ee|PSRLQrr:%XMM5,%XMM5,%XMM6|xmm5=330cd29e78e3e44996e10df506c43616 xmm6=8 f=883|xmm5=330cd29e78e3e40096e10df506c436 f=881/0
  #|psraw xmm5, 0|660f71e500|PSRAWri:%XMM5,%XMM5,0|xmm5=267b6b6638795872826eaba06a4f2609 f=896|f=894/0
  #|psraw xmm5, 1|660f71e501|PSRAWri:%XMM5,%XMM5,1|xmm5=4e200fb4bce8f21d1b2aa8a58d40c1e5 f=886|xmm5=271007dade74f90e0d95d452c6a0e0f2 f=884/0
  #|psraw xmm5, 8|660f71e508|PSRAWri:%XMM5,%XMM5,8|xmm5=79c1ce60e450d7cb6a157721412bdd6b f=83|xmm5=79ffceffe4ffd7006a00770041ffdd f=81/0
  #|psraw xmm5, 16|660f71e510|PSRAWri:%XMM5,%XMM5,16|xmm5=c5fa27390bec9a25a86e63eaab4d1d5f f=897|xmm5=ffff00000000ffffffff0000ffff0000 f=895/0
  #|psraw xmm5, 31|660f71e51f|PSRAWri:%XMM5,%XMM5,31|xmm5=943156df9ace326ce5181e31b35ac8d1 f=d2|xmm5=ffff0000ffff0000ffff0000ffffffff f=d0/0
  #|psraw xmm5, 32|660f71e520|PSRAWri:%XMM5,%XMM5,32|xmm5=5888c769574f1517c71328e9f16d8400 f=c52|xmm5=ffff00000000ffff0000ffffffff f=c50/0
  #|psraw xmm5, 63|660f71e53f|PSRAWri:%XMM5,%XMM5,63|xmm5=67f35fdff2bd29fcc4ac8c195db5c36b f=92|xmm5=ffff0000ffffffff0000ffff f=90/0
  #|psraw xmm5, 64|660f71e540|PSRAWri:%XMM5,%XMM5,64|xmm5=581c5405214bcbb5f2f09559df135178 f=c2|xmm5=ffffffffffffffff0000 f=c0/0
  #|psraw xmm5, 255|660f71e5ff|PSRAWri:%XMM5,%XMM5,255|xmm5=1ba2b13408e4cc81a47fe8ad6de5080f f=892|xmm5=ffff0000ffffffffffff00000000 f=890/0
  #|psraw xmm5, xmm6|660fe1ee|PSRAWrr:%XMM5,%XMM5,%XMM6|xmm5=63667196915826bba4ae0addaf4a646e xmm6=41 f=c7|xmm5=ffff0000ffff0000ffff0000 f=c5/0
  #|psraw xmm5, xmm6|660fe1ee|PSRAWrr:%XMM5,%XMM5,%XMM6|xmm5=8bbea1448597ae2784ae334dfef89033 xmm6=8 f=46|xmm5=ff8bffa1ff85ffaeff840033fffeff90 f=44/0
  #|psraw xmm5, xmm6|660fe1ee|PSRAWrr:%XMM5,%XMM5,%XMM6|xmm5=118a1210ff993c9de53fec3355254f68 xmm6=1f f=8d2|xmm5=ffff0000ffffffff00000000 f=8d0/0
  #|psrad xmm1, 0|660f72e100|PSRADri:%XMM1,%XMM1,0|xmm1=5ad5e0ff622570ba883fb65ca4134a7f f=7|f=5/0
  #|psrad xmm1, 1|660f72e101|PSRADri:%XMM1,%XMM1,1|xmm1=3be9b557fc4d493c490fed5ce6c0a0e4 f=853|xmm1=1df4daabfe26a49e2487f6aef3605072 f=851/0
  #|psrad xmm1, 4|660f72e104|PSRADri:%XMM1,%XMM1,4|xmm1=dd55f5cabdb994fab60be870a656afc3 f=8c6|xmm1=fdd55f5cfbdb994ffb60be87fa656afc f=8c4/0
  #|psrad xmm1, 16|660f72e110|PSRADri:%XMM1,%XMM1,16|xmm1=614b1149c44a1434784c4ec067e15fa3 f=812|xmm1=614bffffc44a0000784c000067e1 f=810/0
  #|psrad xmm1, 31|660f72e11f|PSRADri:%XMM1,%XMM1,31|xmm1=270a09720fe5d9a3fb272f2dc9cb1e9a f=87|xmm1=ffffffffffffffff f=85/0
  #|psrad xmm1, 32|660f72e120|PSRADri:%XMM1,%XMM1,32|xmm1=89b6aeac0a4322a75d1fc21764000cd5 f=13|xmm1=ffffffff000000000000000000000000 f=11/0
  #|psrad xmm1, 63|660f72e13f|PSRADri:%XMM1,%XMM1,63|xmm1=9c47ceedf69bdbcb57a08c8a2a6cca4e f=806|xmm1=ffffffffffffffff0000000000000000 f=804/0
  #|psrad xmm1, 64|660f72e140|PSRADri:%XMM1,%XMM1,64|xmm1=3cc5ae0a65a4ee3ef233ffc35b5c23f1 f=843|xmm1=ffffffff00000000 f=841/0
  #|psrad xmm1, 255|660f72e1ff|PSRADri:%XMM1,%XMM1,255|xmm1=637bf6c14fdbfe3d4f02770984d4d9e2 f=d7|xmm1=ffffffff f=d5/0
  #|psrad xmm1, xmm2|660fe2ca|PSRADrr:%XMM1,%XMM1,%XMM2|xmm1=6598bc95110b9c78655b736a379a57d2 xmm2=1f f=47|xmm1=0 f=45/0
  #|psrad xmm1, xmm2|660fe2ca|PSRADrr:%XMM1,%XMM1,%XMM2|xmm1=c3bcaee7ecd963eaef06101c5e204bd2 xmm2=8 f=cc7|xmm1=ffc3bcaeffecd963ffef0610005e204b f=cc5/0
  #|psrad xmm1, xmm2|660fe2ca|PSRADrr:%XMM1,%XMM1,%XMM2|xmm1=8ed5ab1caaef731f62a0f99b95078340 xmm2=21 f=8c6|xmm1=ffffffffffffffff00000000ffffffff f=8c4/0
  #|pslldq xmm0, 0|660f73f800|PSLLDQri:%XMM0,%XMM0,0|xmm0=29bd6a92d96343626d5c38a2acfb3f5c f=882|f=880/0
  #|pslldq xmm1, 1|660f73f901|PSLLDQri:%XMM1,%XMM1,1|xmm1=e00f9eeb619c9000bda16d6a90e59cad f=806|xmm1=f9eeb619c9000bda16d6a90e59cad00 f=804/0
  #|pslldq xmm6, 4|660f73fe04|PSLLDQri:%XMM6,%XMM6,4|xmm6=23b0d31fdd3698c56a13cb2f688a9ca2 f=857|xmm6=dd3698c56a13cb2f688a9ca200000000 f=855/0
  #|pslldq xmm2, 8|660f73fa08|PSLLDQri:%XMM2,%XMM2,8|xmm2=80008000800080008000800080008000 f=8c3|xmm2=80008000800080000000000000000000 f=8c1/0
  #|pslldq xmm0, 15|660f73f80f|PSLLDQri:%XMM0,%XMM0,15|xmm0=c5b48e9ccaf03f15e44f7827ef092337 f=856|xmm0=37000000000000000000000000000000 f=854/0
  #|pslldq xmm0, 16|660f73f810|PSLLDQri:%XMM0,%XMM0,16|xmm0=a4b68323775b73ec7bfc44dacfac73c5 f=2|xmm0=0 f=0/0
  #|pslldq xmm5, 255|660f73fdff|PSLLDQri:%XMM5,%XMM5,255|xmm5=1fa7ca4cb3bd79d7d04bcf6e57e27aef f=82|xmm5=0 f=80/0
  #|psrldq xmm2, 0|660f73da00|PSRLDQri:%XMM2,%XMM2,0|xmm2=931569b3da7b36e42bbf5405e1ecf178 f=852|f=850/0
  #|psrldq xmm2, 1|660f73da01|PSRLDQri:%XMM2,%XMM2,1|xmm2=25364b6981b2cef2061305694ce085c8 f=56|xmm2=25364b6981b2cef2061305694ce085 f=54/0
  #|psrldq xmm5, 4|660f73dd04|PSRLDQri:%XMM5,%XMM5,4|xmm5=80008000800080008000800080008000 f=447|xmm5=800080008000800080008000 f=445/0
  #|psrldq xmm3, 8|660f73db08|PSRLDQri:%XMM3,%XMM3,8|xmm3=f23dcb239976cc1dc39d5c55aabffee2 f=c03|xmm3=f23dcb239976cc1d f=c01/0
  #|psrldq xmm5, 15|660f73dd0f|PSRLDQri:%XMM5,%XMM5,15|xmm5=e16a7b6c33d630eb600041f1bbcad73a f=47|xmm5=e1 f=45/0
  #|psrldq xmm5, 16|660f73dd10|PSRLDQri:%XMM5,%XMM5,16|xmm5=d26856e876c3d4d251e8a35d6990c985 f=882|xmm5=0 f=880/0
  #|psrldq xmm6, 255|660f73deff|PSRLDQri:%XMM6,%XMM6,255|xmm6=fa633e0bb2426b7df650541af359956b f=47|xmm6=0 f=45/0
  #|pshufd xmm6, xmm7, 249|660f70f7f9|PSHUFDri:%XMM6,%XMM7,249|xmm6=34d0323eabf8ef1858de02f204fe66ec xmm7=76d0a059f290d0380e5c7dcc16412871 f=d7|xmm6=76d0a05976d0a059f290d0380e5c7dcc f=d5/0
  #|pshufd xmm6, xmm0, 27|660f70f01b|PSHUFDri:%XMM6,%XMM0,27|xmm0=1c7d15b4e6f9bbd3211212db71ada6a4 xmm6=3975c69a91ddd2b293ffa6f7a2ec132a f=17|xmm6=71ada6a4211212dbe6f9bbd31c7d15b4 f=15/0
  #|pshufd xmm0, xmm1, 0|660f70c100|PSHUFDri:%XMM0,%XMM1,0|xmm0=ee69a3e6f3be5c71d5c4dcac84433b98 xmm1=ffffffffffffffffffffffffffffffff f=d2|xmm0=ffffffffffffffffffffffffffffffff f=d0/0
  #|pshuflw xmm1, xmm7, 186|f20f70cfba|PSHUFLWri:%XMM1,%XMM7,186|xmm1=edf933c05a43ffdf946f46087432b00 xmm7=e807ad37fa90c093a0d1476fabd4912a f=816|xmm1=e807ad37fa90c093476fa0d1476f476f f=814/0
  #|pshuflw xmm1, xmm3, 27|f20f70cb1b|PSHUFLWri:%XMM1,%XMM3,27|xmm1=0 xmm3=967f3f80f1e3ac7ad1ee49a74e979079 f=847|xmm1=967f3f80f1e3ac7a90794e9749a7d1ee f=845/0
  #|pshuflw xmm7, xmm1, 0|f20f70f900|PSHUFLWri:%XMM7,%XMM1,0|xmm1=33714c5aca3e895a50f3d00083bc4185 xmm7=80008000800080008000800080008000 f=857|xmm7=33714c5aca3e895a4185418541854185 f=855/0
  #|pshufhw xmm7, xmm1, 151|f30f70f997|PSHUFHWri:%XMM7,%XMM1,151|xmm1=6478e0eb840b38d868329f0df924e3b3 xmm7=8a7428333bfab7697fde9ba6b2e6c6b6 f=817|xmm7=e0eb840b840b647868329f0df924e3b3 f=815/0
  #|pshufhw xmm7, xmm3, 27|f30f70fb1b|PSHUFHWri:%XMM7,%XMM3,27|xmm3=80008000800080008000800080008000 xmm7=9e2b012c8c8fac24757e1c96669c9a0d f=cd7|xmm7=80008000800080008000800080008000 f=cd5/0
  #|pshufhw xmm4, xmm2, 0|f30f70e200|PSHUFHWri:%XMM4,%XMM2,0|xmm2=8a27ba666333af9fa44f06eadb4ca9c5 xmm4=8d13fd98ee4805dc658ace4719f92398 f=c03|xmm4=af9faf9faf9faf9fa44f06eadb4ca9c5 f=c01/0
  #|shufps xmm3, xmm6, 50|0fc6de32|SHUFPSrri:%XMM3,%XMM3,%XMM6,50|xmm3=7b7cfee678a9fb4a000402a1070f5ba7 xmm6=277cd3efa47334024521d17b974bf600 f=d2|xmm3=974bf600277cd3ef070f5ba778a9fb4a f=d0/0
  #|shufps xmm1, xmm0, 27|0fc6c81b|SHUFPSrri:%XMM1,%XMM1,%XMM0,27|xmm0=e46424310ac92f54e0301a9f8429706b xmm1=555dedabe10baf9edad6b53a262005d3 f=852|xmm1=8429706be0301a9fe10baf9e555dedab f=850/0
  #|shufps xmm4, xmm2, 0|0fc6e200|SHUFPSrri:%XMM4,%XMM4,%XMM2,0|xmm2=732919eb0f7bae66c17604b7cae79d51 xmm4=ffffffffffffffffffffffffffffffff f=886|xmm4=cae79d51cae79d51ffffffffffffffff f=884/0
  #|shufpd xmm1, xmm4, 131|660fc6cc83|SHUFPDrri:%XMM1,%XMM1,%XMM4,131|xmm1=663c6493773b9f1573b987e95799f814 xmm4=deeb81f133c79277689ea9816eb3b732 f=13|xmm1=deeb81f133c79277663c6493773b9f15 f=11/0
  #|shufpd xmm4, xmm3, 27|660fc6e31b|SHUFPDrri:%XMM4,%XMM4,%XMM3,27|xmm3=80008000800080008000800080008000 xmm4=59d4c012382b651f8942d7f3f98d9d68 f=4d3|xmm4=800080008000800059d4c012382b651f f=4d1/0
  #|shufpd xmm6, xmm5, 0|660fc6f500|SHUFPDrri:%XMM6,%XMM6,%XMM5,0|xmm5=80008000800080008000800080008000 xmm6=ffffffffffffffffffffffffffffffff f=c6|xmm6=8000800080008000ffffffffffffffff f=c4/0
  #|palignr xmm2, xmm0, 31|660f3a0fd01f|PALIGNRrri:%XMM2,%XMM2,%XMM0,31|xmm0=12a6f0f2c4a896fce5843e591079fd0e xmm2=b59a86bae33a501f5bf55fd7bbb170ff f=83|xmm2=b5 f=81/0
  #|palignr xmm1, xmm0, 15|660f3a0fc80f|PALIGNRrri:%XMM1,%XMM1,%XMM0,15|xmm0=0 xmm1=6b5004453c500b5a401cc94c27c6ef68 f=c02|xmm1=5004453c500b5a401cc94c27c6ef6800 f=c00/0
  #|palignr xmm1, xmm2, 32|660f3a0fca20|PALIGNRrri:%XMM1,%XMM1,%XMM2,32|xmm1=19708b79803821874425257ee0ecc161 xmm2=80008000800080008000800080008000 f=847|xmm1=0 f=845/0
  #|pblendw xmm5, xmm1, 223|660f3a0ee9df|PBLENDWrri:%XMM5,%XMM5,%XMM1,223|xmm1=d1b084ef00f157a43a28faed2a21826d xmm5=b4ff3cc94180a4cbf06ca0feeda8f84f f=c6|xmm5=d1b084ef418057a43a28faed2a21826d f=c4/0
  #|pblendw xmm4, xmm5, 27|660f3a0ee51b|PBLENDWrri:%XMM4,%XMM4,%XMM5,27|xmm4=88d3aa40531ef5b2ffdbe6b0e16d3274 xmm5=0 f=8d6|xmm4=88d3aa40531e00000000e6b000000000 f=8d4/0
  #|pblendw xmm2, xmm4, 0|660f3a0ed400|PBLENDWrri:%XMM2,%XMM2,%XMM4,0|xmm2=eb4c271da7f04580cfeabbcc480a6ff8 xmm4=ec093c665941178e60186f759301e594 f=c17|f=c15/0
  #|pinsrw xmm3, r10d, 0|66410fc4da00|PINSRWrri:%XMM3,%XMM3,%R10D,0|r10=1f0041a92a3ff87f xmm3=0 f=802|xmm3=f87f f=800/0
  #|pinsrw xmm3, ebx, 3|660fc4db03|PINSRWrri:%XMM3,%XMM3,%EBX,3|rbx=0 xmm3=90ca42804777d0ef921bc869828ac2d9 f=892|xmm3=90ca42804777d0ef0000c869828ac2d9 f=890/0
  #|pinsrw xmm4, ecx, 0|660fc4e100|PINSRWrri:%XMM4,%XMM4,%ECX,0|rcx=f1aed1734a99327f xmm4=0 f=3|xmm4=327f f=1/0
  #|pextrw r12d, xmm4, 6|66440fc5e406|PEXTRWrri:%R12D,%XMM4,6|r12=ca21b3c9c25c18a0 xmm4=36b654cf0659e8534605acc13eaf8dd3 f=843|r12=54cf f=841/0
  #|pextrw r9d, xmm3, 11|66440fc5cb0b|PEXTRWrri:%R9D,%XMM3,11|r9=3478 xmm3=45401502e36a69358c391ded956081b0 f=886|r9=8c39 f=884/0
  #|pextrw eax, xmm4, 0|660fc5c400|PEXTRWrri:%EAX,%XMM4,0|rax=89b0e841318dd7be xmm4=47b077a5496b2e986a829de4df1eda23 f=c6|rax=da23 f=c4/0
  #|pextrb r15d, xmm6, 12|66410f3a14f70c|PEXTRBrri:%R15D,%XMM6,12|r15=6482cd98ffffffff xmm6=b5d504579426b96a945bc092f2c51288 f=853|r15=57 f=851/0
  #|pextrb r15d, xmm5, 11|66410f3a14ef0b|PEXTRBrri:%R15D,%XMM5,11|r15=99a27b6e4a5ae681 xmm5=61931d5c41860ecab90fdadac10ea96d f=57|r15=41 f=55/0
  #|pextrb r9d, xmm2, 0|66410f3a14d100|PEXTRBrri:%R9D,%XMM2,0|r9=722ecec27450c800 xmm2=8c2a5941f1f9af7d39cda5d9dd06c829 f=442|r9=29 f=440/0
  #|pextrd r8d, xmm1, 5|66410f3a16c805|PEXTRDrri:%R8D,%XMM1,5|r8=8a8fe3b373ce040f xmm1=bf56bfc0e448d06db3f2ea1b8d35ac3f f=846|r8=b3f2ea1b f=844/0
  #|pextrd ebx, xmm6, 11|660f3a16f30b|PEXTRDrri:%EBX,%XMM6,11|rbx=4ee8ad92da8d4efa xmm6=80008000800080008000800080008000 f=882|rbx=80008000 f=880/0
  #|pextrd ebx, xmm4, 0|660f3a16e300|PEXTRDrri:%EBX,%XMM4,0|rbx=d8fc xmm4=f6fd271763603e52b04cbfb1084636f6 f=2|rbx=84636f6 f=0/0
  #|pinsrb xmm7, r15d, 4|66410f3a20ff04|PINSRBrri:%XMM7,%XMM7,%R15D,4|r15=d xmm7=933f51022f872c2e091547ca6de26874 f=53|xmm7=933f51022f872c2e0915470d6de26874 f=51/0
  #|pinsrb xmm5, eax, 3|660f3a20e803|PINSRBrri:%XMM5,%XMM5,%EAX,3|rax=b xmm5=b4b8faf443cd16a7db97d0422e7fb7ef f=8d7|xmm5=b4b8faf443cd16a7db97d0420b7fb7ef f=8d5/0
  #|pinsrb xmm0, r12d, 0|66410f3a20c400|PINSRBrri:%XMM0,%XMM0,%R12D,0|r12=cf39fa7f679db149 xmm0=e3bb38a7a37eb9b808bb20ed5ae8ee3c f=486|xmm0=e3bb38a7a37eb9b808bb20ed5ae8ee49 f=484/0
  #|pinsrd xmm1, ecx, 6|660f3a22c906|PINSRDrri:%XMM1,%XMM1,%ECX,6|rcx=2 xmm1=ffffffffffffffffffffffffffffffff f=8c3|xmm1=ffffffff00000002ffffffffffffffff f=8c1/0
  #|pinsrd xmm1, r14d, 3|66410f3a22ce03|PINSRDrri:%XMM1,%XMM1,%R14D,3|r14=1cda64cc27e984e4 xmm1=f05031fd60ddd18a62a6d4e71c7012d5 f=857|xmm1=27e984e460ddd18a62a6d4e71c7012d5 f=855/0
  #|pinsrd xmm6, ecx, 0|660f3a22f100|PINSRDrri:%XMM6,%XMM6,%ECX,0|rcx=4 xmm6=8eb8c8403abfc4c5e405754552a8c5d2 f=443|xmm6=8eb8c8403abfc4c5e405754500000004 f=441/0
  #|pshufd xmm1, xmmword ptr [rsi], 0x4e|660f700e4e|PSHUFDmi:%XMM1,%RSI,1,%,0,%,78|xmm1=2bca3353f5710879e6a745daf2fda86a f=d2 m10080=9d659864086827703f80b6281624279d|xmm1=702768086498659d9d27241628b6803f f=d0/0
  #|movd xmm1, ebx|660f6ecb|MOVDI2PDIrr:%XMM1,%EBX|rbx=fffffffffffffffe xmm1=0 f=883|xmm1=fffffffe f=881/0
  #|movd xmm1, ebx|660f6ecb|MOVDI2PDIrr:%XMM1,%EBX|rbx=48f5e3e11a91cca3 xmm1=18b7c8453c04d1c21f60df3de53d94e0 f=17|xmm1=1a91cca3 f=15/0
  #|movd ebx, xmm2|660f7ed3|MOVPDI2DIrr:%EBX,%XMM2|rbx=3b80729a9e641c7b xmm2=360c8ab61232962970ab94d2207ce981 f=843|rbx=207ce981 f=841/0
  #|movd ebx, xmm2|660f7ed3|MOVPDI2DIrr:%EBX,%XMM2|rbx=7a6e75842a731e55 xmm2=86a8076fd8c33f55a63c80dca4365374 f=87|rbx=a4365374 f=85/0
  #|movd xmm3, dword ptr [rdi + 0x10]|660f6e5f10|MOVDI2PDIrm:%XMM3,%RDI,1,%,16,%|xmm3=30566f17b8b40eb28ae458fd515bfd40 f=846 m10110=76b90e743b9d7ccfe542fc4e1095c164|xmm3=740eb976 f=844/0
  #|movd xmm3, dword ptr [rdi + 0x10]|660f6e5f10|MOVDI2PDIrm:%XMM3,%RDI,1,%,16,%|xmm3=f11604e90bf0c472185fb0d157288f4e f=853 m10110=a0059db572889ef5b1736469b0ae183f|xmm3=b59d05a0 f=851/0
  #|movd dword ptr [rdi + 0x10], xmm4|660f7e6710|MOVPDI2DImr:%RDI,1,%,16,%,%XMM4|xmm4=ffffffffffffffffffffffffffffffff f=8c6 m10110=8a35763562bf331a3e2383cfa450af67|f=8c4/0 m10110=ffffffff
  #|movd dword ptr [rdi + 0x10], xmm4|660f7e6710|MOVPDI2DImr:%RDI,1,%,16,%,%XMM4|xmm4=80008000800080008000800080008000 f=853 m10110=2dcada5c072b8b4f39c6df428847e30a|f=851/0 m10110=00800080
  #|movq xmm1, xmm2|f30f7eca|MOVZPQILo2PQIrr:%XMM1,%XMM2|xmm1=247f3fce19185344570af5c3681cf5ca xmm2=66a20527e82c07185c90b720e6bdb22c f=893|xmm1=5c90b720e6bdb22c f=891/0
  #|movq xmm1, xmm2|f30f7eca|MOVZPQILo2PQIrr:%XMM1,%XMM2|xmm1=cf692850cbe4c7d008c3261294771c6c xmm2=e2be8cf6e28cbe73278e38a388b5e176 f=7|xmm1=278e38a388b5e176 f=5/0
  #|movq xmm3, qword ptr [rdi + 0x10]|f30f7e5f10|MOVQI2PQIrm:%XMM3,%RDI,1,%,16,%|xmm3=960c890d46d979d5fec3aa6b3a9d18e8 f=46 m10110=67dceccfe8f9274e06c400ddb3c41c0c|xmm3=4e27f9e8cfecdc67 f=44/0
  #|movq xmm3, qword ptr [rdi + 0x10]|f30f7e5f10|MOVQI2PQIrm:%XMM3,%RDI,1,%,16,%|xmm3=7d38bed9664d849d4147e0904f5dba8d f=d3 m10110=140752db064e7944c9f0dccd15f12ed6|xmm3=44794e06db520714 f=d1/0
  #|movq qword ptr [rdi + 0x10], xmm4|660fd66710|MOVPQI2QImr:%RDI,1,%,16,%,%XMM4|xmm4=8608178fd728edc7a3d853751f481761 f=93 m10110=aada3a2cd2dbeef4fdec8695dac3ee58|f=91/0 m10110=6117481f7553d8a3
  #|movq qword ptr [rdi + 0x10], xmm4|660fd66710|MOVPQI2QImr:%RDI,1,%,16,%,%XMM4|xmm4=d79142a1dfc7c1aae3c1e92fe3cd81e8 f=46 m10110=312d7752b993b8f09c563b7aaa867d9d|f=44/0 m10110=e881cde32fe9c1e3
  #|pmovmskb ebx, xmm5|660fd7dd|PMOVMSKBrr:%EBX,%XMM5|rbx=aa35cb891e210762 xmm5=938152f361ba1b6fe21aa0299c79711c f=c86|rbx=d4a8 f=c84/0
  #|pmovmskb ebx, xmm5|660fd7dd|PMOVMSKBrr:%EBX,%XMM5|rbx=15163af8b7962536 xmm5=c9b685622e8f2f180f619bd04eb7d86f f=856|rbx=e436 f=854/0
  #|movmskps ebx, xmm5|0f50dd|MOVMSKPSrr:%EBX,%XMM5|rbx=f60ebb8700688e9e xmm5=ffffffffffffffffffffffffffffffff f=846|rbx=f f=844/0
  #|movmskps ebx, xmm5|0f50dd|MOVMSKPSrr:%EBX,%XMM5|rbx=8dd9b2f57496ef40 xmm5=80008000800080008000800080008000 f=8c7|rbx=f f=8c5/0
  #|movmskpd ebx, xmm5|660f50dd|MOVMSKPDrr:%EBX,%XMM5|rbx=4a7b41e836f5f574 xmm5=80008000800080008000800080008000 f=cc3|rbx=3 f=cc1/0
  #|movmskpd ebx, xmm5|660f50dd|MOVMSKPDrr:%EBX,%XMM5|rbx=6f2ebe1e45cc7fff xmm5=225fdeebcb546a538099f569ae089e6 f=8c7|rbx=0 f=8c5/0
  #|movhps xmm1, qword ptr [rdi + 0x10]|0f164f10|MOVHPSrm:%XMM1,%XMM1,%RDI,1,%,16,%|xmm1=80008000800080008000800080008000 f=403 m10110=2a2d9d66bc65a3853a68883233abef17|xmm1=85a365bc669d2d2a8000800080008000 f=401/0
  #|movhps xmm1, qword ptr [rdi + 0x10]|0f164f10|MOVHPSrm:%XMM1,%XMM1,%RDI,1,%,16,%|xmm1=853ec811701b285237ecd7322b3f4127 f=46 m10110=8a240627e628af34cee1352cd1fa642c|xmm1=34af28e62706248a37ecd7322b3f4127 f=44/0
  #|movlps xmm1, qword ptr [rdi + 0x10]|0f124f10|MOVLPSrm:%XMM1,%XMM1,%RDI,1,%,16,%|xmm1=295a05814eb906fa0240ce4a6bbdae43 f=857 m10110=d080ae853aa341b871a5b026e14f6a79|xmm1=295a05814eb906fab841a33a85ae80d0 f=855/0
  #|movlps xmm1, qword ptr [rdi + 0x10]|0f124f10|MOVLPSrm:%XMM1,%XMM1,%RDI,1,%,16,%|xmm1=49279613341ba3cdf5e17d79787f7629 f=d2 m10110=eadfea7512f0ee0bfb3f8fb57e34ca1e|xmm1=49279613341ba3cd0beef01275eadfea f=d0/0
  #|movhps qword ptr [rdi + 0x10], xmm2|0f175710|MOVHPSmr:%RDI,1,%,16,%,%XMM2|xmm2=b1bdf3c52efd368ec8fb0d353c5fdef3 f=52 m10110=8c69c41b3c37d01986ad049773c63412|f=50/0 m10110=8e36fd2ec5f3bdb1
  #|movhps qword ptr [rdi + 0x10], xmm2|0f175710|MOVHPSmr:%RDI,1,%,16,%,%XMM2|xmm2=5ad5b9f0e242d1dd0e75d8b025b36c6a f=817 m10110=67a03a8139aa560eacdd5b33e40faea7|f=815/0 m10110=ddd142e2f0b9d55a
  #|movlps qword ptr [rdi + 0x10], xmm2|0f135710|MOVLPSmr:%RDI,1,%,16,%,%XMM2|xmm2=18ca2715e126b30dbec1c6b4847a0424 f=17 m10110=91f985c3efedfeb95c51a73a2c9e7cb6|f=15/0 m10110=24047a84b4c6c1be
  #|movlps qword ptr [rdi + 0x10], xmm2|0f135710|MOVLPSmr:%RDI,1,%,16,%,%XMM2|xmm2=80008000800080008000800080008000 f=7 m10110=aeace460474c1a740232c4be3e6d5699|f=5/0 m10110=0080008000800080
  #|movdqa xmmword ptr [rsi], xmm3|660f7f1e|MOVDQAmr:%RSI,1,%,0,%,%XMM3|xmm3=80008000800080008000800080008000 f=cc6 m10080=24d65fcbed0731af3da335bccd8a5b88|f=cc4/0 m10080=00800080008000800080008000800080
  #|movdqa xmmword ptr [rsi], xmm3|660f7f1e|MOVDQAmr:%RSI,1,%,0,%,%XMM3|xmm3=ffffffffffffffffffffffffffffffff f=812 m10080=e24c3306c9aae6113be2b925e7be1d8b|f=810/0 m10080=ffffffffffffffffffffffffffffffff
  #|movdqu xmmword ptr [rdi + 0x10], xmm3|f30f7f5f10|MOVDQUmr:%RDI,1,%,16,%,%XMM3|xmm3=5ff840813e3a1491c4819544bd72c533 f=13 m10110=dbc4d6638c5021a4c57403b406f2945a|f=11/0 m10110=33c572bd449581c491143a3e8140f85f
  #|movdqu xmmword ptr [rdi + 0x10], xmm3|f30f7f5f10|MOVDQUmr:%RDI,1,%,16,%,%XMM3|xmm3=38880c81439c8552c2fac6f25171cb16 f=2 m10110=95291203f44c7c8158746dd1837b9851|f=0/0 m10110=16cb7151f2c6fac252859c43810c8838
  #|movaps xmmword ptr [rsi], xmm3|0f291e|MOVAPSmr:%RSI,1,%,0,%,%XMM3|xmm3=0 f=887 m10080=0255a91c8ecf1515330f6fc8ae166ee4|f=885/0 m10080=00000000000000000000000000000000
  #|movaps xmmword ptr [rsi], xmm3|0f291e|MOVAPSmr:%RSI,1,%,0,%,%XMM3|xmm3=5d7fb8d7122b4c3c73302b639ba3bf19 f=52 m10080=722a3396c14f37f7fa9f539310dcafd2|f=50/0 m10080=19bfa39b632b30733c4c2b12d7b87f5d
  #|movups xmmword ptr [rdi + 0x10], xmm3|0f115f10|MOVUPSmr:%RDI,1,%,16,%,%XMM3|xmm3=ccea57b58f166f0a6af627d5a9b6bfb1 f=816 m10110=22f9401217db10773e4aa284f9361853|f=814/0 m10110=b1bfb6a9d527f66a0a6f168fb557eacc
  #|movups xmmword ptr [rdi + 0x10], xmm3|0f115f10|MOVUPSmr:%RDI,1,%,16,%,%XMM3|xmm3=becbbc4a3e63eb02e143c4422bbaa380 f=c53 m10110=917ab83bea937b5e1e5ab063cc88b154|f=c51/0 m10110=80a3ba2b42c443e102eb633e4abccbbe
  #|movntdq xmmword ptr [rsi], xmm2|660fe716|MOVNTDQmr:%RSI,1,%,0,%,%XMM2|xmm2=80008000800080008000800080008000 f=43 m10080=bd3fd5f35b9c184d55cf24419e89ef91|f=41/0 m10080=00800080008000800080008000800080
  #|movntdq xmmword ptr [rsi], xmm2|660fe716|MOVNTDQmr:%RSI,1,%,0,%,%XMM2|xmm2=7b36f2e99ad25cb4c1d229ea6f053353 f=c43 m10080=08a2f20569c1af930a2ca2b48d793238|f=c41/0 m10080=5333056fea29d2c1b45cd29ae9f2367b
  #|ptest xmm1, xmm2|660f3817ca|PTESTrr:%XMM1,%XMM2|xmm1=48980ee7ba6a69675b3ae7847a2d0c3f xmm2=ef832a7cc9f72dc4adac6821f6e8e0fb f=56|f=0/894
  #|ptest xmm1, xmm2|660f3817ca|PTESTrr:%XMM1,%XMM2|xmm1=2331eefbcf05c84fab75be24d0b2e23c xmm2=21118602cb0080068111282000b06038 f=807|f=1/894
  #|movss xmm1, xmm2|f30f10ca|MOVSSrr:%XMM1,%XMM1,%XMM2|rax=a48a0732527a2dd4 rcx=d rdx=8000000000000000 xmm1=ffffffffffffffffffffffffffffffff xmm2=ffffffffffffffffffffffffffffffff f=d6|f=d4/0
  #|movss xmm1, xmm2|f30f10ca|MOVSSrr:%XMM1,%XMM1,%XMM2|rax=18e729ae9a71040e rcx=71fa597949042198 xmm1=80008000800080008000800080008000 xmm2=dd944d70a73e55218b942514c0670d78 f=c03|xmm1=800080008000800080008000c0670d78 f=c01/0
  #|movsd xmm1, xmm2|f20f10ca|MOVSDrr:%XMM1,%XMM1,%XMM2|rcx=28b2f6982ea7424 rdx=87decebbc7e89cd7 xmm1=c4165f8ae5ad287dbdf097fa6537ed54 xmm2=c9e92be9d41346a0bf9bba047d7fc9eb f=817|xmm1=c4165f8ae5ad287dbf9bba047d7fc9eb f=815/0
  #|movsd xmm1, xmm2|f20f10ca|MOVSDrr:%XMM1,%XMM1,%XMM2|rax=9fd1c028ae1f5d29 rcx=10581fec0d9c9a4 xmm1=360b2ab9997a2123c1a4c59c6eef2ad2 xmm2=82717d15bf18043feb8a0e8b1c8cdfcc f=c7|xmm1=360b2ab9997a2123eb8a0e8b1c8cdfcc f=c5/0
  #|movss xmm1, dword ptr [rdi + 0x10]|f30f104f10|MOVSSrm:%XMM1,%RDI,1,%,16,%|rax=3ef313186f5f2968 rdx=6c23dd45e4d6c171 xmm1=de52e593d215a231fb95e77c67c012a4 f=8d2 m10110=4d1262ed5c85224feb2551924b8d73c3|xmm1=ed62124d f=8d0/0
  #|movss xmm1, dword ptr [rdi + 0x10]|f30f104f10|MOVSSrm:%XMM1,%RDI,1,%,16,%|rcx=ee18095b23f139da xmm1=87cab16d3b3196fdd1b87b7b4e3d55fc f=8c7 m10110=b71030d536df5bb530fb56f17a05c419|xmm1=d53010b7 f=8c5/0
  #|movsd xmm1, qword ptr [rdi + 0x10]|f20f104f10|MOVSDrm:%XMM1,%RDI,1,%,16,%|rax=6 rdx=6a3a6f44d506efc3 xmm1=a9d617cf230b94a5f742495c7de6b8fd f=4c6 m10110=7a01f9cf8debad0e68efe879849e59a9|xmm1=eadeb8dcff9017a f=4c4/0
  #|movsd xmm1, qword ptr [rdi + 0x10]|f20f104f10|MOVSDrm:%XMM1,%RDI,1,%,16,%|rax=99a6c2a0cf5fb0c7 xmm1=624fc639fe671fb4c784d2630a60f8a2 f=7 m10110=1225a53ca5c15509ccb71dd12c3d249c|xmm1=955c1a53ca52512 f=5/0
  #|movss dword ptr [rdi + 0x10], xmm1|f30f114f10|MOVSSmr:%RDI,1,%,16,%,%XMM1|rax=9c198cb4a04e532d rcx=c87ba3d5f0064889 xmm1=80008000800080008000800080008000 f=8c3 m10110=37ce61f4dce0e5fb9f21d22153de4756|f=8c1/0 m10110=00800080
  #|movss dword ptr [rdi + 0x10], xmm1|f30f114f10|MOVSSmr:%RDI,1,%,16,%,%XMM1|rax=5a xmm1=8a9c3af441f3ccd6f0cc4d9e7da7f919 f=4c2 m10110=9cc0cf3934ab4e2d5cfe15799b7e0a0d|f=4c0/0 m10110=19f9a77d
  #|movsd qword ptr [rdi + 0x10], xmm1|f20f114f10|MOVSDmr:%RDI,1,%,16,%,%XMM1|rax=c rcx=19ce14d1e90f1c80 rdx=1 xmm1=bd0ffd97f27049cad79bfa4d34824fcd f=cd6 m10110=67181c02e77333537accb4750555bd11|f=cd4/0 m10110=cd4f82344dfa9bd7
  #|movsd qword ptr [rdi + 0x10], xmm1|f20f114f10|MOVSDmr:%RDI,1,%,16,%,%XMM1|rcx=537bdd1956d73261 rdx=ffffffffffffffff xmm1=f96c83d2ce4c7aa3707007090c04134 f=d6 m10110=d8562966430d1e87c7ce7bc5ece92ea9|f=d4/0 m10110=3441c09070000737
  #|movq xmm1, rbx|66480f6ecb|MOV64toPQIrr:%XMM1,%RBX|rbx=7fffffffffffffff xmm1=3117346475b8054e7173ecd6ce823586 f=52|xmm1=7fffffffffffffff f=50/0
  #|movq xmm1, rbx|66480f6ecb|MOV64toPQIrr:%XMM1,%RBX|rbx=95c605f796cfb535 xmm1=a07fd2b689f9bb42b7ef6699db837742 f=806|xmm1=95c605f796cfb535 f=804/0
  #|movq rbx, xmm2|66480f7ed3|MOVPQIto64rr:%RBX,%XMM2|rbx=26 xmm2=e38731f2e39d11187fc26a8b39683d1d f=56|rbx=7fc26a8b39683d1d f=54/0
  #|movq rbx, xmm2|66480f7ed3|MOVPQIto64rr:%RBX,%XMM2|rbx=9e xmm2=4ecbfd2ee9a9724700e45f47eb2448bf f=cc7|rbx=e45f47eb2448bf f=cc5/0
  #|pextrq rax, xmm3, 1|66480f3a16d801|PEXTRQrri:%RAX,%XMM3,1|rax=7f xmm3=c67371bf68a010ffb05593f52d39073e f=47|rax=c67371bf68a010ff f=45/0
  #|pextrq rax, xmm3, 1|66480f3a16d801|PEXTRQrri:%RAX,%XMM3,1|rax=742a84f887d21555 xmm3=9c7785d9a1df3ba16efdfd7ce1630da1 f=882|rax=9c7785d9a1df3ba1 f=880/0
  #|pinsrq xmm3, rax, 1|66480f3a22d801|PINSRQrri:%XMM3,%XMM3,%RAX,1|rax=dd1cb9ca396ad68f xmm3=ffffffffffffffffffffffffffffffff f=7|xmm3=dd1cb9ca396ad68fffffffffffffffff f=5/0
  #|pinsrq xmm3, rax, 1|66480f3a22d801|PINSRQrri:%XMM3,%XMM3,%RAX,1|rax=d67ab5c1ea88000 xmm3=80008000800080008000800080008000 f=807|xmm3=d67ab5c1ea880008000800080008000 f=805/0
  #|movd xmm9, r10d|66450f6eca|MOVDI2PDIrr:%XMM9,%R10D|r10=b9c9835f03472503 xmm9=396932306daa49e3190501b934bcd88d f=8c3|xmm9=3472503 f=8c1/0
  #|movd xmm9, r10d|66450f6eca|MOVDI2PDIrr:%XMM9,%R10D|r10=659f xmm9=74362a6145e0780a6bbdd751ccac68a f=892|xmm9=659f f=890/0
  #|movq r11, xmm12|664d0f7ee3|MOVPQIto64rr:%R11,%XMM12|r11=8000 xmm12=45b48013223ba0194740499850c77135 f=817|r11=4740499850c77135 f=815/0
  #|movq r11, xmm12|664d0f7ee3|MOVPQIto64rr:%R11,%XMM12|r11=ffffffffffffffff xmm12=a631236e90f3fe550afa1329ec30c230 f=93|r11=afa1329ec30c230 f=91/0

///|
let sse32_cases : String =
  #|pxor xmm4, xmm6|660fefe6|PXORrr:%XMM4,%XMM4,%XMM6|xmm4=ffffffffffffffffffffffffffffffff xmm6=f77d53fd17729b5296da6720210cbb36 f=4c6|xmm4=882ac02e88d64ad692598dfdef344c9 f=4c4/0
  #|pxor xmm4, xmm6|660fefe6|PXORrr:%XMM4,%XMM4,%XMM6|xmm4=9eb908404a359ced5f500d3ae2b9c783 xmm6=490d6a5c0c4e24d223ad7d9c2c304b57 f=d7|xmm4=d7b4621c467bb83f7cfd70a6ce898cd4 f=d5/0
  #|pxor xmm4, xmmword ptr [esi]|660fef26|PXORrm:%XMM4,%XMM4,%ESI,1,%,0,%|ebx=a xmm4=b1b3b3efa6aa0cf4be306178fe2648f1 f=52 m10080=d82bb31ac351891b2146d4cf66fc7849|xmm4=f8cb4f89697e4ad5a5b930bbe4956329 f=50/0
  #|pand xmm3, xmm0|660fdbd8|PANDrr:%XMM3,%XMM3,%XMM0|xmm0=f183772382960956da1a7b578c0b791a xmm3=ffffffffffffffffffffffffffffffff f=807|xmm3=f183772382960956da1a7b578c0b791a f=805/0
  #|pand xmm3, xmm0|660fdbd8|PANDrr:%XMM3,%XMM3,%XMM0|xmm0=3d806e3bbcdc7fa00f8f242a0f01676 xmm3=cc68c44a5cababc558d0374a274e8a f=402|xmm3=c800c00a4c83aa0058d00200200602 f=400/0
  #|por xmm6, xmm0|660febf0|PORrr:%XMM6,%XMM6,%XMM0|xmm0=7efb404517b7f33085dd8fadebcb1aa7 xmm6=8d1463dc9b429106661ee182211a5fd1 f=cc6|xmm6=ffff63dd9ff7f336e7dfefafebdb5ff7 f=cc4/0
  #|por xmm6, xmm0|660febf0|PORrr:%XMM6,%XMM6,%XMM0|xmm0=781b971b26a995701faa1fedd3c847e6 xmm6=310da2ce47ccad68b548f24d7a1ee776 f=802|xmm6=791fb7df67edbd78bfeaffedfbdee7f6 f=800/0
  #|pandn xmm7, xmm6|660fdffe|PANDNrr:%XMM7,%XMM7,%XMM6|xmm6=5fb6ebd1851d7194f8ac20c7ab269e49 xmm7=80008000800080008000800080008000 f=817|xmm7=5fb66bd1051d719478ac20c72b261e49 f=815/0
  #|pandn xmm7, xmm6|660fdffe|PANDNrr:%XMM7,%XMM7,%XMM6|xmm6=ffffffffffffffffffffffffffffffff xmm7=e2e623d2a5b3f28fdb4d9c48eb414f49 f=2|xmm7=1d19dc2d5a4c0d7024b263b714beb0b6 f=0/0
  #|paddb xmm3, xmm1|660ffcd9|PADDBrr:%XMM3,%XMM3,%XMM1|xmm1=aba686567e9c5e2c5e5bab611e82a5f6 xmm3=f345e7a38b6fdbf52524ac3b4b5f71ca f=8c2|xmm3=9eeb6df9090b3921837f579c69e116c0 f=8c0/0
  #|paddb xmm3, xmm1|660ffcd9|PADDBrr:%XMM3,%XMM3,%XMM1|xmm1=d4ef1862757c1de1728c063fee5854fa xmm3=cd4503d98261a61dd9ab72ec87c8563f f=92|xmm3=a1341b3bf7ddc3fe4b37782b7520aa39 f=90/0
  #|paddb xmm3, xmmword ptr [esi]|660ffc1e|PADDBrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=1 xmm3=e888a84563c4b2293cee680e910492f8 f=812 m10080=7ef2fe0740c28ef3951f17b2cb7f72d4|xmm3=bcfa271015dbd1be2f7c2a4e98028476 f=810/0
  #|paddw xmm5, xmm6|660ffdee|PADDWrr:%XMM5,%XMM5,%XMM6|xmm5=23a51965de35807f533f9e2baf3f86e3 xmm6=0 f=c7|f=c5/0
  #|paddw xmm5, xmm6|660ffdee|PADDWrr:%XMM5,%XMM5,%XMM6|xmm5=b121ad649c001396bf241a7e4b99bf87 xmm6=ffffffffffffffffffffffffffffffff f=42|xmm5=b120ad639bff1395bf231a7d4b98bf86 f=40/0
  #|paddw xmm5, xmmword ptr [esi]|660ffd2e|PADDWrm:%XMM5,%XMM5,%ESI,1,%,0,%|ebx=f xmm5=fbe51cad5f4bc6cc94fe19e4be83e48c f=8d2 m10080=e8a232ade09ade56dbffaddad4de4bb6|xmm5=b230fb8139f8c6a7ebdcb4c46bb58774 f=8d0/0
  #|paddd xmm3, xmmword ptr [esi]|660ffe1e|PADDDrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=d xmm3=35a1788d69bc2423569b7914b96aad96 f=8c2 m10080=f4058d568f1566b516328a366cbcfd78|xmm3=ae9f34f9a04656390c018ea30ff7b38a f=8c0/0
  #|psubw xmm0, xmm7|660ff9c7|PSUBWrr:%XMM0,%XMM0,%XMM7|xmm0=ffffffffffffffffffffffffffffffff xmm7=7483a5aab6cd05b44a3a24c814f98b04 f=c7|xmm0=8b7c5a554932fa4bb5c5db37eb0674fb f=c5/0
  #|psubw xmm0, xmm7|660ff9c7|PSUBWrr:%XMM0,%XMM0,%XMM7|xmm0=7d8a73bbb63f51698c2854d50f0d268d xmm7=e0a3b06e047b990620206dda76fa09d7 f=7|xmm0=9ce7c34db1c4b8636c08e6fb98131cb6 f=5/0
  #|paddsb xmm7, xmmword ptr [esi]|660fec3e|PADDSBrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=9 xmm7=a639c7d2588bbfdcd001d011f3b236a9 f=8d6 m10080=5d408700d5b6d89bee73e338c26e3159|xmm7=ff6a35947f8032ca80d986e6f3807606 f=8d4/0
  #|paddsw xmm0, xmmword ptr [esi]|660fed06|PADDSWrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=2 xmm0=80008000800080008000800080008000 f=857 m10080=4a69ebd3145272c0216d54448a0efe24|xmm0=a4fe8e8ac454ed218000d2148000e94a f=855/0
  #|paddusb xmm2, xmm4|660fdcd4|PADDUSBrr:%XMM2,%XMM2,%XMM4|xmm2=1c35c700334343932be647373b9a2094 xmm4=80008000800080008000800080008000 f=443|xmm2=9c35ff00b343c393abe6c737bb9aa094 f=441/0
  #|paddusb xmm2, xmm4|660fdcd4|PADDUSBrr:%XMM2,%XMM2,%XMM4|xmm2=6c0ab7fb461db61b2274b53057044561 xmm4=4a765fa71a34552db766178411061132 f=42|xmm2=b680ffff6051ff48d9daccb4680a5693 f=40/0
  #|paddusb xmm2, xmmword ptr [esi]|660fdc16|PADDUSBrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=f xmm2=ffffffffffffffffffffffffffffffff f=43 m10080=86d8b987165aae00fc6e6added04eec2|f=41/0
  #|psubsb xmm3, xmm4|660fe8dc|PSUBSBrr:%XMM3,%XMM3,%XMM4|xmm3=9dbc2f9c821a49e821b80d7f8d1b44f9 xmm4=711f411b2c5349e8de12d4f9afe6356d f=12|xmm3=809dee8180c7000043a6397fde350f8c f=10/0
  #|psubsb xmm3, xmm4|660fe8dc|PSUBSBrr:%XMM3,%XMM3,%XMM4|xmm3=c26baec8758465fe2546ed0115566fb8 xmm4=6117a2d58801b7d373346efaa3c0ba8a f=c06|xmm3=80540cf37f837f2bb2128007727f7f2e f=c04/0
  #|psubsw xmm2, xmm6|660fe9d6|PSUBSWrr:%XMM2,%XMM2,%XMM6|xmm2=2bb45941e9be6813b6071f32990fc5a9 xmm6=9d2aea564556b2af31e9b69d7a657194 f=842|xmm2=7fff6eeba4687fff841e689580008000 f=840/0
  #|psubsw xmm2, xmm6|660fe9d6|PSUBSWrr:%XMM2,%XMM2,%XMM6|xmm2=f80bc51e09edac5081b8a255f9f46f9e xmm6=e6bd4e35d165e9b1b3b4c2cd8a03ec8c f=8c6|xmm2=114e80003888c29fce04df886ff17fff f=8c4/0
  #|psubsw xmm2, xmmword ptr [esi]|660fe916|PSUBSWrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=0 xmm2=2eb592a325aede06af07929cb868d69d f=12 m10080=a087e9d87bdc1b0fb7c6a6f7cebca6b1|xmm2=7d0fd5d52e08174f9fecb621df7f4efd f=10/0
  #|psubusb xmm6, xmmword ptr [esi]|660fd836|PSUBUSBrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=2 xmm6=80008000800080008000800080008000 f=8d7 m10080=372ad9d73068c571ae462b8803f4e3af|xmm6=3a000f00180000005600 f=8d5/0
  #|psubusw xmm0, xmm5|660fd9c5|PSUBUSWrr:%XMM0,%XMM0,%XMM5|xmm0=fbb1070b76db866c6e3839f265c29f3e xmm5=7dd3f0c69e3a99d6790e59ba3f60bf6b f=86|xmm0=7dde0000000000000000000026620000 f=84/0
  #|psubusw xmm0, xmm5|660fd9c5|PSUBUSWrr:%XMM0,%XMM0,%XMM5|xmm0=71951702f669e62e7ac0ad0bc6cc80c4 xmm5=8d2f3d9023438293ee51b64bafd3b756 f=886|xmm0=d326639b0000000016f90000 f=884/0
  #|psubusw xmm0, xmmword ptr [esi]|660fd906|PSUBUSWrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=3 xmm0=38f81a48d65069065b334b111cc70cec f=43 m10080=7780b784ca7c748de7811ea5c3f3b080|xmm0=313200000000000000000000 f=41/0
  #|pcmpeqw xmm3, xmm0|660f75d8|PCMPEQWrr:%XMM3,%XMM3,%XMM0|xmm0=b44860f530828c180aba7b9fc52ba533 xmm3=6b6e4f2bd1b912c9bc8d6d60f5c691f8 f=8c3|xmm3=0 f=8c1/0
  #|pcmpeqw xmm3, xmm0|660f75d8|PCMPEQWrr:%XMM3,%XMM3,%XMM0|xmm0=f2f0353c1b559c07109cc2956c1d341e xmm3=80008000800080008000800080008000 f=817|xmm3=0 f=815/0
  #|pcmpeqd xmm3, xmm6|660f76de|PCMPEQDrr:%XMM3,%XMM3,%XMM6|xmm3=ab949a5fe525ea16a981341e6c6d01fc xmm6=6a089e301aa9f0c57cff04f657cc3749 f=c3|xmm3=0 f=c1/0
  #|pcmpeqd xmm3, xmm6|660f76de|PCMPEQDrr:%XMM3,%XMM3,%XMM6|xmm3=bb7e6a88f52591106a41fd8a575d8e73 xmm6=bb92cf2d46a7e6582147e5e1c0cd5a5a f=17|xmm3=0 f=15/0
  #|pcmpeqd xmm3, xmmword ptr [esi]|660f761e|PCMPEQDrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=c xmm3=80008000800080008000800080008000 f=817 m10080=91e1f49bf8dd32d2cffac0e6393e851a|xmm3=0 f=815/0
  #|pcmpeqq xmm0, xmm6|660f3829c6|PCMPEQQrr:%XMM0,%XMM0,%XMM6|xmm0=6c7431aff5ac5f652ac4261e1323e24e xmm6=12f34f48c1d1feb91ee0ef9288b6d9a7 f=896|xmm0=0 f=894/0
  #|pcmpeqq xmm0, xmm6|660f3829c6|PCMPEQQrr:%XMM0,%XMM0,%XMM6|xmm0=9d74efb8b2143deff642d419d0a34a03 xmm6=462af5e60f964d1d968b8ad127bbd579 f=882|xmm0=0 f=880/0
  #|pcmpeqq xmm0, xmmword ptr [esi]|660f382906|PCMPEQQrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=3 xmm0=3ab67e0cb00449953d78978cd1c532e0 f=8d3 m10080=72b05d91ec06e9799874d4a886c03ab2|xmm0=0 f=8d1/0
  #|pcmpgtw xmm6, xmm0|660f65f0|PCMPGTWrr:%XMM6,%XMM6,%XMM0|xmm0=ae0ae5f2f9d5c9af9d8c6bae415ff5a1 xmm6=d2fb1ec250f395fa7d97aa355f9c1d85 f=d3|xmm6=ffffffffffff0000ffff0000ffffffff f=d1/0
  #|pcmpgtw xmm6, xmm0|660f65f0|PCMPGTWrr:%XMM6,%XMM6,%XMM0|xmm0=78d1523bd8588808050d3e91612967fd xmm6=daf5789f0e9f0bf293f50ecf7e769cbb f=883|xmm6=ffffffffffff00000000ffff0000 f=881/0
  #|pcmpgtw xmm6, xmmword ptr [esi]|660f6536|PCMPGTWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=1 xmm6=d400b30ccac46919b520a35d14c90321 f=803 m10080=4af068cb659796f08e2b661fca07ccf4|xmm6=ffff0000ffffffffffff f=801/0
  #|pcmpgtd xmm3, xmm0|660f66d8|PCMPGTDrr:%XMM3,%XMM3,%XMM0|xmm0=2eccaa193aea3178d9d2b51a252d67ae xmm3=620ac374edad3bfac53a19dd822c0c6d f=c82|xmm3=ffffffff000000000000000000000000 f=c80/0
  #|pcmpgtd xmm3, xmm0|660f66d8|PCMPGTDrr:%XMM3,%XMM3,%XMM0|xmm0=caaca142af4bb769c2c58cac13063849 xmm3=d93bb3cd486c8584794c5acf073d9d47 f=8c6|xmm3=ffffffffffffffffffffffff00000000 f=8c4/0
  #|pcmpgtd xmm3, xmmword ptr [esi]|660f661e|PCMPGTDrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=1 xmm3=4f95a8c118a1757bb096ffda0ef7a5bf f=802 m10080=a48da6bf03e0813e4cf58f2625bb004a|xmm3=ffffffff0000000000000000ffffffff f=800/0
  #|pminub xmm7, xmm2|660fdafa|PMINUBrr:%XMM7,%XMM7,%XMM2|xmm2=47a30094f84aa3cf15d34ea9d9203c2 xmm7=13e8abe50320f67477788a5301d16eed f=407|xmm7=47a30090320aa3c775d3453019203c2 f=405/0
  #|pminub xmm7, xmm2|660fdafa|PMINUBrr:%XMM7,%XMM7,%XMM2|xmm2=b674211d74a6a9c60b57a17fdba6da55 xmm7=0 f=846|f=844/0
  #|pmaxub xmm7, xmm6|660fdefe|PMAXUBrr:%XMM7,%XMM7,%XMM6|xmm6=8787e7ff8907b0da0ab35919f98b8f76 xmm7=c8f359c4868fb6df54a1e7588c604c94 f=886|xmm7=c8f3e7ff898fb6df54b3e758f98b8f94 f=884/0
  #|pmaxub xmm7, xmm6|660fdefe|PMAXUBrr:%XMM7,%XMM7,%XMM6|xmm6=0 xmm7=8371852c41c8834b5e430c27fa0ac07d f=c2|f=c0/0
  #|pminsb xmm2, xmmword ptr [esi]|660f383816|PMINSBrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=d xmm2=b83c6517e2db58bf441b11ac819b19d0 f=56 m10080=a4e13cf5107f660597663a56b438546e|xmm2=b83c38b4e2db5897051b11ac819be1a4 f=54/0
  #|pmaxsb xmm5, xmm1|660f383ce9|PMAXSBrr:%XMM5,%XMM5,%XMM1|xmm1=ffffffffffffffffffffffffffffffff xmm5=0 f=813|f=811/0
  #|pmaxsb xmm5, xmm1|660f383ce9|PMAXSBrr:%XMM5,%XMM5,%XMM1|xmm1=80008000800080008000800080008000 xmm5=a6a42f3f8af9d943480b00ed15410c7e f=16|xmm5=a6002f3f8a00d943480b000015410c7e f=14/0
  #|pmaxuw xmm6, xmmword ptr [esi]|660f383e36|PMAXUWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=d xmm6=fa75f592d3031eda71cd4bea7e20c350 f=4c2 m10080=4905c98499b301d9c13ded0692a9fedb|xmm6=fa75f592d3033dc1d901b39984c9c350 f=4c0/0
  #|pminud xmm7, xmm4|660f383bfc|PMINUDrr:%XMM7,%XMM7,%XMM4|xmm4=0 xmm7=ffffffffffffffffffffffffffffffff f=812|xmm7=0 f=810/0
  #|pminud xmm7, xmm4|660f383bfc|PMINUDrr:%XMM7,%XMM7,%XMM4|xmm4=0 xmm7=1d7d22164a59b1fc56bbc30add244f54 f=842|xmm7=0 f=840/0
  #|pmaxud xmm6, xmmword ptr [esi]|660f383f36|PMAXUDrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=0 xmm6=9a87c09bd2e915947e6be624de880769 f=892 m10080=fbc596d0bfb4f7b0671757605e90bed0|xmm6=d0be905ed2e91594b0f7b4bfde880769 f=890/0
  #|pavgb xmm0, xmm3|660fe0c3|PAVGBrr:%XMM0,%XMM0,%XMM3|xmm0=ffffffffffffffffffffffffffffffff xmm3=25f15646fb49d1453c13966176c2c1b9 f=57|xmm0=92f8aba3fda4e8a29e89cbb0bbe1e0dc f=55/0
  #|pavgb xmm0, xmm3|660fe0c3|PAVGBrr:%XMM0,%XMM0,%XMM3|xmm0=b00859352f576a7506fe1e027e9193ef xmm3=80008000800080008000800080008000 f=8c7|xmm0=98046d1b582c753b437f4f017f498a78 f=8c5/0
  #|pavgb xmm0, xmmword ptr [esi]|660fe006|PAVGBrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=4 xmm0=8210751ad9bea21b3da21ddbf2e4578f f=483 m10080=b8ef4caee14a26bf78647a4030eeaa78|xmm0=7d5db2258d9c834a7e6434ded098a3a4 f=481/0
  #|pavgw xmm0, xmmword ptr [esi]|660fe306|PAVGWrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=2 xmm0=80008000800080008000800080008000 f=802 m10080=23220f6b9e5aee78a65e5b36a1c151eb|xmm0=b5a9a0d15b2e6f537c776d4f75885112 f=800/0
  #|pmullw xmm6, xmm0|660fd5f0|PMULLWrr:%XMM6,%XMM6,%XMM0|xmm0=a8aef5ffce50fb024cfdd638a24d91e0 xmm6=56b7f2b23af2958660a1c99df0b3694b f=806|xmm6=862194e27a08d0c4b1d5858abd79ca0 f=804/0
  #|pmullw xmm6, xmm0|660fd5f0|PMULLWrr:%XMM6,%XMM6,%XMM0|xmm0=80008000800080008000800080008000 xmm6=16d533becc40a8312dbc2218a72f1d9f f=497|xmm6=80000000000080000000000080008000 f=495/0
  #|pmullw xmm6, xmmword ptr [esi]|660fd536|PMULLWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=7 xmm6=4ddd462d6b3e6509bea967a9b1cfdd85 f=3 m10080=6e510f558b8fed107185857de8a5caf3|xmm6=376299c8fd3645f91275afc326214426 f=1/0
  #|pmulhw xmm6, xmmword ptr [esi]|660fe536|PMULHWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=3 xmm6=80008000800080008000800080008000 f=8d2 m10080=bf756d93caa48d87cac5584097649376|xmm6=c4b6cdb4dfd41d1b3c392d9b3649c520 f=8d0/0
  #|pmuludq xmm2, xmmword ptr [esi]|660ff416|PMULUDQrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=e xmm2=ee96eb9bb9f2b625dea1f24011dc31b2 f=d7 m10080=f426f6d19b35a5cc10f28532149ead17|xmm2=24b2b27eea935c500ea5f0e1c84bc9a8 f=d5/0
  #|pmuldq xmm7, xmm3|660f3828fb|PMULDQrr:%XMM7,%XMM7,%XMM3|xmm3=407e4c542573c8d95e0381d3d2100397 xmm7=afd280f2ac5f011d2177addcabc98bf4 f=857|xmm7=f3c3e83a066d99950f1c844497c568ec f=855/0
  #|pmuldq xmm7, xmm3|660f3828fb|PMULDQrr:%XMM7,%XMM7,%XMM3|xmm3=3c2c2f6610ee18da03fc7ce2e28c573c xmm7=e851301aa213821d5f2644fb7b3cbf09 f=c07|xmm7=f9c9dd269fc584b2f1d270d3f214d51c f=c05/0
  #|pmuldq xmm7, xmmword ptr [esi]|660f38283e|PMULDQrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=d xmm7=658f2a0a984c1dbec9b8bf7d8f861453 f=d3 m10080=45b4807458498b6cebdbe2096e97f983|xmm7=fbfec727db0cd76accd0350bbaedd65f f=d1/0
  #|pmulld xmm2, xmmword ptr [esi]|660f384016|PMULLDrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=6 xmm2=ffffffffffffffffffffffffffffffff f=cd6 m10080=c5e12b71de7ae6ab4c349294fa10e344|xmm2=bb1cef066b6dcbb4541985228ed41e3b f=cd4/0
  #|psadbw xmm5, xmm4|660ff6ec|PSADBWrr:%XMM5,%XMM5,%XMM4|xmm4=af0eeaa139eb56d1c62d324a2d602e1b xmm5=9424465c2cd600305510c6fc556a52ca f=57|xmm5=23300000000000002d9 f=55/0
  #|psadbw xmm5, xmm4|660ff6ec|PSADBWrr:%XMM5,%XMM5,%XMM4|xmm4=f62ca7c4ec4b11496a2efa8d72d6da8e xmm5=2fa9720c40f71bbb257338714da5e009 f=882|xmm5=4050000000000000249 f=880/0
  #|psadbw xmm5, xmmword ptr [esi]|660ff62e|PSADBWrm:%XMM5,%XMM5,%ESI,1,%,0,%|ebx=d xmm5=597083587cb778382298b60877872b19 f=83 m10080=6d2fb3af1334f58a1237597fad42271b|xmm5=1e5000000000000020e f=81/0
  #|psllw xmm2, xmm5|660ff1d5|PSLLWrr:%XMM2,%XMM2,%XMM5|xmm2=4be080ca43a109fa24b31d6541190acb xmm5=9038b62a226621b05f793da144e4299 f=52|xmm2=0 f=50/0
  #|psllw xmm2, xmm5|660ff1d5|PSLLWrr:%XMM2,%XMM2,%XMM5|xmm2=88dbafca3c54d80accff52c8293b9a32 xmm5=d2a329acaa4aba01f4aa18c9fe5658a0 f=843|xmm2=0 f=841/0
  #|pslld xmm1, xmm4|660ff2cc|PSLLDrr:%XMM1,%XMM1,%XMM4|xmm1=f7969140ea9cee93b3a0648d38904c79 xmm4=61638b1b852c47627390cd644d23c0a9 f=417|xmm1=0 f=415/0
  #|pslld xmm1, xmm4|660ff2cc|PSLLDrr:%XMM1,%XMM1,%XMM4|xmm1=9e58066a8b6b693d2e3ac5cf9bfcb81b xmm4=fd3d27ef7ec7eb02864de9f9f6680d28 f=87|xmm1=0 f=85/0
  #|pslld xmm1, xmmword ptr [esi]|660ff20e|PSLLDrm:%XMM1,%XMM1,%ESI,1,%,0,%|ebx=9 xmm1=ffffffffffffffffffffffffffffffff f=807 m10080=d949621f96b65e04d5500e43a02752b5|xmm1=0 f=805/0
  #|psrld xmm7, xmmword ptr [esi]|660fd23e|PSRLDrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=f xmm7=33c89dd46250a9e16cb291b8253c1cc8 f=807 m10080=b0bfd3bca862a3f1cf13aa2a77fb12bc|xmm7=0 f=805/0
  #|psrlq xmm3, xmm2|660fd3da|PSRLQrr:%XMM3,%XMM3,%XMM2|xmm2=c621bc47b1c9a8722b3db821550d55d7 xmm3=9d40aa39a113c66026c561cea4e0c3de f=d7|xmm3=0 f=d5/0
  #|psrlq xmm3, xmm2|660fd3da|PSRLQrr:%XMM3,%XMM3,%XMM2|xmm2=c4ef3a633cee0caffe7cbc093f6d1a4b xmm3=2e9bbc0825e90a82a564f482ef5e86b0 f=c52|xmm3=0 f=c50/0
  #|psrlq xmm3, xmmword ptr [esi]|660fd31e|PSRLQrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=6 xmm3=193af8d60d948e091b4f9e69df13ff28 f=8c7 m10080=10f10552cf986e5a6d09d4f3c5b299dc|xmm3=0 f=8c5/0
  #|psrad xmm3, xmmword ptr [esi]|660fe21e|PSRADrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=1 xmm3=0 f=812 m10080=5a58454dddbbe376a57d14dcf637216f|f=810/0
  #|punpcklwd xmm7, xmm6|660f61fe|PUNPCKLWDrr:%XMM7,%XMM7,%XMM6|xmm6=1a8cb9c0010175b820c1ec42412091a xmm7=524813410a76e0a670a4feaa1acc7114 f=13|xmm7=820c70a41ec4feaa24121acc091a7114 f=11/0
  #|punpcklwd xmm7, xmm6|660f61fe|PUNPCKLWDrr:%XMM7,%XMM7,%XMM6|xmm6=aa5f46cc8fbdcf4fe5cc5511c2e787d1 xmm7=0 f=42|xmm7=e5cc000055110000c2e7000087d10000 f=40/0
  #|punpckhbw xmm6, xmm0|660f68f0|PUNPCKHBWrr:%XMM6,%XMM6,%XMM0|xmm0=7c2b7288fc518ffb586cab65959bb162 xmm6=ce1ba8852673e822111203da6152e7b0 f=882|xmm6=7cce2b1b72a88885fc2651738fe8fb22 f=880/0
  #|punpckhbw xmm6, xmm0|660f68f0|PUNPCKHBWrr:%XMM6,%XMM6,%XMM0|xmm0=ae82cfa039d21458ef2abc87a48f8905 xmm6=862bb750dedb919b2ecd1ff61674ff1c f=82|xmm6=ae86822bcfb7a05039ded2db1491589b f=80/0
  #|punpckhbw xmm6, xmmword ptr [esi]|660f6836|PUNPCKHBWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=8 xmm6=27ffd0930eeafd5f6b3b9e3345030e51 f=442 m10080=ba1de31ba2a470785f0b0ca02ec116f7|xmm6=f72716ffc1d02e93a00e0cea0bfd5f5f f=440/0
  #|punpckhwd xmm7, xmm3|660f69fb|PUNPCKHWDrr:%XMM7,%XMM7,%XMM3|xmm3=67265b774f45eaeace6dde8bf0b2d39c xmm7=4f4b2dccf169db5fdc43c8ca9f657973 f=807|xmm7=67264f4b5b772dcc4f45f169eaeadb5f f=805/0
  #|punpckhwd xmm7, xmm3|660f69fb|PUNPCKHWDrr:%XMM7,%XMM7,%XMM3|xmm3=0 xmm7=ab2a0956235786e26220076eb7207ec7 f=8d3|xmm7=ab2a0000095600002357000086e2 f=8d1/0
  #|punpckhwd xmm7, xmmword ptr [esi]|660f693e|PUNPCKHWDrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=5 xmm7=3e06fdb4580408d0a19a168bf2616bf6 f=d6 m10080=bf2fff0f0bc622f9041543f0c65d26d4|xmm7=d4263e065dc6fdb4f0435804150408d0 f=d4/0
  #|punpckhdq xmm2, xmm1|660f6ad1|PUNPCKHDQrr:%XMM2,%XMM2,%XMM1|xmm1=6a6735f7080b98d0bc24feb788796485 xmm2=dfe70e7acc37838addf8c45a67ce94c f=883|xmm2=6a6735f70dfe70e7080b98d0acc37838 f=881/0
  #|punpckhdq xmm2, xmm1|660f6ad1|PUNPCKHDQrr:%XMM2,%XMM2,%XMM1|xmm1=b9d0be33fda027ae6c09dde92b3987fc xmm2=f4190b2a855e2cafda783a53a9eede9e f=813|xmm2=b9d0be33f4190b2afda027ae855e2caf f=811/0
  #|punpckhdq xmm2, xmmword ptr [esi]|660f6a16|PUNPCKHDQrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=5 xmm2=ffffffffffffffffffffffffffffffff f=13 m10080=e08f78d99c73b37c5424198c57959778|xmm2=78979557ffffffff8c192454ffffffff f=11/0
  #|packsswb xmm4, xmmword ptr [esi]|660f6326|PACKSSWBrm:%XMM4,%XMM4,%ESI,1,%,0,%|ebx=1 xmm4=9792e4112b8edb339acd0ccc69c7c86f f=86 m10080=ff5f08a395078874af88ea42527112b4|xmm4=807f7f807f7f807f80807f80807f7f80 f=84/0
  #|packssdw xmm4, xmm5|660f6be5|PACKSSDWrr:%XMM4,%XMM4,%XMM5|xmm4=80008000800080008000800080008000 xmm5=2fdbf262ee3e6a3469fe1352191a5076 f=882|xmm4=7fff80007fff7fff8000800080008000 f=880/0
  #|packssdw xmm4, xmm5|660f6be5|PACKSSDWrr:%XMM4,%XMM4,%XMM5|xmm4=33589046ee0c5c096f42ebd3903e1e83 xmm5=b94f870c7e5019d0fc08a62c00c44d97 f=803|xmm4=80007fff80007fff7fff80007fff8000 f=801/0
  #|packssdw xmm4, xmmword ptr [esi]|660f6b26|PACKSSDWrm:%XMM4,%XMM4,%ESI,1,%,0,%|ebx=6 xmm4=7fb3a4b3223eec0a8a26be89331be98 f=816 m10080=6b93849c846de580dd41fb6800c98435|xmm4=7fff7fff800080007fff7fff80008000 f=814/0
  #|packuswb xmm6, xmmword ptr [esi]|660f6736|PACKUSWBrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=4 xmm6=cab4685487e6e1d2201ea9789c8b23d7 f=83 m10080=22a6e6e138adecff93656d7e02179f40|xmm6=ffffffff0000000000ff0000ff0000ff f=81/0
  #|packusdw xmm1, xmm3|660f382bcb|PACKUSDWrr:%XMM1,%XMM1,%XMM3|xmm1=0 xmm3=8367d09696d7eb557920c026d88791c0 f=c96|xmm1=ffff00000000000000000000 f=c94/0
  #|packusdw xmm1, xmm3|660f382bcb|PACKUSDWrr:%XMM1,%XMM1,%XMM3|xmm1=cc697254a26ee9d0c5ee97c6d3490281 xmm3=40e8542269d396e2ab36e89ab87f04b0 f=16|xmm1=ffffffff000000000000000000000000 f=14/0
  #|packusdw xmm1, xmmword ptr [esi]|660f382b0e|PACKUSDWrm:%XMM1,%XMM1,%ESI,1,%,0,%|ebx=c xmm1=0 f=47 m10080=435416d880c50ba0fc492f609c2b07e6|xmm1=ffff000000000000000000000000 f=45/0
  #|pshufb xmm4, xmmword ptr [esi]|660f380026|PSHUFBrm:%XMM4,%XMM4,%ESI,1,%,0,%|ebx=5 xmm4=6699ecde16a74083ca78dbf206dbb21b f=d7 m10080=76eab948d3025262bbb752c6dc2e21a3|xmm4=b2990000db0000dbdbdb0083000078 f=d5/0
  #|pabsw xmm3, xmm5|660f381ddd|PABSWrr:%XMM3,%XMM5|xmm3=918a8b22528d025d8e2efb438d87fe9c xmm5=ffffffffffffffffffffffffffffffff f=c93|xmm3=10001000100010001000100010001 f=c91/0
  #|pabsw xmm3, xmm5|660f381ddd|PABSWrr:%XMM3,%XMM5|xmm3=0 xmm5=0 f=812|f=810/0
  #|pabsd xmm4, xmm6|660f381ee6|PABSDrr:%XMM4,%XMM6|xmm4=0 xmm6=0 f=8c3|f=8c1/0
  #|pabsd xmm4, xmm6|660f381ee6|PABSDrr:%XMM4,%XMM6|xmm4=ffffffffffffffffffffffffffffffff xmm6=890978b95c3d4f2b8ecc8595eac453a2 f=87|xmm4=76f687475c3d4f2b71337a6b153bac5e f=85/0
  #|psignw xmm6, xmmword ptr [esi]|660f380936|PSIGNWrm:%XMM6,%XMM6,%ESI,1,%,0,%|ebx=1 xmm6=70b2dbe33b77bed1c37a5f0559103f68 f=897 m10080=c8ec1cf5eaccaacb7babebec4610d55c|xmm6=70b2dbe3c489412f3c86a0fba6f0c098 f=895/0
  #|psignd xmm7, xmm2|660f380afa|PSIGNDrr:%XMM7,%XMM7,%XMM2|xmm2=86f96ccba1d86eeed8a8c9afa70947a0 xmm7=52c8c85d957fc69149244aab123c1644 f=812|xmm7=ad3737a36a80396fb6dbb555edc3e9bc f=810/0
  #|psignd xmm7, xmm2|660f380afa|PSIGNDrr:%XMM7,%XMM7,%XMM2|xmm2=fb347691170751aa9e0aaa4d37302c2d xmm7=2a56c2b939a21d75ffee04a6be66c36d f=7|xmm7=d5a93d4739a21d750011fb5abe66c36d f=5/0
  #|phaddw xmm3, xmm1|660f3801d9|PHADDWrr:%XMM3,%XMM3,%XMM1|xmm1=77ad80595ba33e606ab804e5cd1ab903 xmm3=d860635faa48e86eae2111f802659b08 f=843|xmm3=f8069a036f9d861d3bbf92b6c0199d6d f=841/0
  #|phaddw xmm3, xmm1|660f3801d9|PHADDWrr:%XMM3,%XMM3,%XMM1|xmm1=68db9795b20e1df04204f30af29f7939 xmm3=5dff974982b1409f7ab22a4f7b74fe06 f=496|xmm3=70cffe350e6bd8f548c350a501797a f=494/0
  #|phaddd xmm7, xmm1|660f3802f9|PHADDDrr:%XMM7,%XMM7,%XMM1|xmm1=cb025741960afdd04835395ce7830777 xmm7=501b72063dc7d23073b1967782a184f1 f=2|xmm7=610d55112fb840d38de34436f6531b68 f=0/0
  #|phaddd xmm7, xmm1|660f3802f9|PHADDDrr:%XMM7,%XMM7,%XMM1|xmm1=76115ae92f3d32a20d066f76ca24e962 xmm7=0 f=493|xmm7=a54e8d8bd72b58d80000000000000000 f=491/0
  #|pmaddubsw xmm5, xmm6|660f3804ee|PMADDUBSWrr:%XMM5,%XMM5,%XMM6|xmm5=ffffffffffffffffffffffffffffffff xmm6=8855ab15fa19f490a14cc7448268be80 f=896|xmm5=dd23c04012ed847ced130af5ea168000 f=894/0
  #|pmaddubsw xmm5, xmm6|660f3804ee|PMADDUBSWrr:%XMM5,%XMM5,%XMM6|xmm5=cd41b2dfeb24bb75648f9e652629702b xmm6=7b8dde32272305dd60c62e87e4dedf36 f=c16|xmm5=454c13ea28b9f3a8051aeca7f666faa2 f=c14/0
  #|pmulhrsw xmm7, xmm0|660f380bf8|PMULHRSWrr:%XMM7,%XMM7,%XMM0|xmm0=5eccf70ddee402e15fc9f85fdaeea8ff xmm7=0 f=53|f=51/0
  #|pmulhrsw xmm7, xmm0|660f380bf8|PMULHRSWrr:%XMM7,%XMM7,%XMM0|xmm0=6da06da3f886c9f749342efd6d0b4aa2 xmm7=0 f=802|f=800/0
  #|movdqa xmm3, xmm5|660f6fdd|MOVDQArr:%XMM3,%XMM5|xmm3=60fc6bf9d63cbbe67947581df36db7bb xmm5=f4ff36e92bc7e43c036a264c44cfe1f0 f=446|xmm3=f4ff36e92bc7e43c036a264c44cfe1f0 f=444/0
  #|movdqa xmm3, xmm5|660f6fdd|MOVDQArr:%XMM3,%XMM5|xmm3=dbad41c4824b4676ca946437d85ef489 xmm5=a3d32e07f5c3241bf287db32555558b9 f=852|xmm3=a3d32e07f5c3241bf287db32555558b9 f=850/0
  #|movdqu xmm4, xmmword ptr [esi]|f30f6f26|MOVDQUrm:%XMM4,%ESI,1,%,0,%|ebx=8 xmm4=3e9720891b95c1a1daacaf1a36ff06a3 f=8d2 m10080=f01dfa07d6a2dbb39e3c04374926de9d|xmm4=9dde264937043c9eb3dba2d607fa1df0 f=8d0/0
  #|movaps xmm2, xmm6|0f28d6|MOVAPSrr:%XMM2,%XMM6|xmm2=63f2065ce9f7234785adc73551003a95 xmm6=58c9194fbda963e195de62d49af16c78 f=13|xmm2=58c9194fbda963e195de62d49af16c78 f=11/0
  #|movaps xmm2, xmm6|0f28d6|MOVAPSrr:%XMM2,%XMM6|xmm2=12f2ff1cd85f1ebc05fe955313d0209b xmm6=0 f=c12|xmm2=0 f=c10/0
  #|movaps xmm2, xmmword ptr [esi]|0f2816|MOVAPSrm:%XMM2,%ESI,1,%,0,%|ebx=3 xmm2=ea3718101ad918874de367fced679029 f=847 m10080=3dc5edd98a5fa11bf6b35e98c11ac95f|xmm2=5fc91ac1985eb3f61ba15f8ad9edc53d f=845/0
  #|movups xmm7, xmm0|0f10f8|MOVUPSrr:%XMM7,%XMM0|xmm0=48b06564a946ec3d51b9aea391de6695 xmm7=5f504d8e222630f7be34a9324a49a410 f=842|xmm7=48b06564a946ec3d51b9aea391de6695 f=840/0
  #|movups xmm7, xmm0|0f10f8|MOVUPSrr:%XMM7,%XMM0|xmm0=f2d26ae63211d032492096c7250cf221 xmm7=f0b8d2939563ab1cde3e71642a497be3 f=8d2|xmm7=f2d26ae63211d032492096c7250cf221 f=8d0/0
  #|movapd xmm5, xmmword ptr [esi]|660f282e|MOVAPDrm:%XMM5,%ESI,1,%,0,%|ebx=0 xmm5=2f304d88d23bdc8609bdd305dc9f85f4 f=8c2 m10080=829ee2ce2cfbf5c10c190ffde6d1b9e3|xmm5=e3b9d1e6fd0f190cc1f5fb2ccee29e82 f=8c0/0
  #|andps xmm2, xmm4|0f54d4|ANDPSrr:%XMM2,%XMM2,%XMM4|xmm2=5d2b02a71aab954042fa49fdd7eb1b5d xmm4=41f67f23352972f2170ba991547a9503 f=cd7|xmm2=4122022310291040020a0991546a1101 f=cd5/0
  #|andps xmm2, xmm4|0f54d4|ANDPSrr:%XMM2,%XMM2,%XMM4|xmm2=0 xmm4=bb3f33971b36735ecf9ee86b7f2df83a f=406|f=404/0
  #|andpd xmm7, xmmword ptr [esi]|660f543e|ANDPDrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=5 xmm7=7a41b73491c4b28536f456585e780c9e f=46 m10080=8b5cf103f70f9e39a64d2d2c5d39ba75|xmm7=70003114000400843094065002700c8a f=44/0
  #|orps xmm2, xmm4|0f56d4|ORPSrr:%XMM2,%XMM2,%XMM4|xmm2=0 xmm4=0 f=892|f=890/0
  #|orps xmm2, xmm4|0f56d4|ORPSrr:%XMM2,%XMM2,%XMM4|xmm2=cbb5f4e99f3d5712e8369cdde7594885 xmm4=894c5d1f2a053363de4cd4b77a6e74d5 f=c92|xmm2=cbfdfdffbf3d7773fe7edcffff7f7cd5 f=c90/0
  #|orps xmm2, xmmword ptr [esi]|0f5616|ORPSrm:%XMM2,%XMM2,%ESI,1,%,0,%|ebx=b xmm2=b48081987b54688969c0906223944e58 f=487 m10080=195997cf638b87d56abcac6fc34da643|xmm2=f7a6cddb7ffcfcebfdc79b63ef975f59 f=485/0
  #|orpd xmm1, xmmword ptr [esi]|660f560e|ORPDrm:%XMM1,%XMM1,%ESI,1,%,0,%|ebx=8 xmm1=d51c4e051e43610bd218bf96c2c1c9df f=13 m10080=1f4c8eff794a115e5d68382e8af28e5e|xmm1=df9efe8f3e7b695fde19ffffffcfcddf f=11/0
  #|xorpd xmm7, xmm0|660f57f8|XORPDrr:%XMM7,%XMM7,%XMM0|xmm0=0 xmm7=713fc9865c606982eb1a7d60559cfd03 f=12|f=10/0
  #|xorpd xmm7, xmm0|660f57f8|XORPDrr:%XMM7,%XMM7,%XMM0|xmm0=65da9b58b2a026bc1a8e219a697e2842 xmm7=500b77c39bfdecb9572e2977f7e43b9c f=8d2|xmm7=35d1ec9b295dca054da008ed9e9a13de f=8d0/0
  #|xorpd xmm7, xmmword ptr [esi]|660f573e|XORPDrm:%XMM7,%XMM7,%ESI,1,%,0,%|ebx=b xmm7=98abf01a9a05aba4212e7ff3ede2e591 f=c7 m10080=f1a40608ddcaca08315d892f64f2aeb9|xmm7=2105027eb58cf69529e4b52ee5e44160 f=c5/0
  #|andnps xmm3, xmmword ptr [esi]|0f551e|ANDNPSrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=7 xmm3=ef18dfd7b8fca4d5eec74d19c2cdb37b f=56 m10080=7b74a99ce80ef3d5bd772a29a0e913cd|xmm3=3202001025328113002e01c204400 f=54/0
  #|andnpd xmm0, xmmword ptr [esi]|660f5506|ANDNPDrm:%XMM0,%XMM0,%ESI,1,%,0,%|ebx=9 xmm0=0 f=452 m10080=e547d4ff4e56538ebf5bde0afeace4d9|xmm0=d9e4acfe0ade5bbf8e53564effd447e5 f=450/0
  #|unpcklps xmm4, xmmword ptr [esi]|0f1426|UNPCKLPSrm:%XMM4,%XMM4,%ESI,1,%,0,%|ebx=5 xmm4=414c2e829e0335a3e6f499101e142aa8 f=c3 m10080=4023e07ec4f21ba128b1ae5bb8cce8d5|xmm4=a11bf2c4e6f499107ee023401e142aa8 f=c1/0
  #|unpckhps xmm3, xmmword ptr [esi]|0f151e|UNPCKHPSrm:%XMM3,%XMM3,%ESI,1,%,0,%|ebx=2 xmm3=ffffffffffffffffffffffffffffffff f=c43 m10080=f5d9a7af812b50c2083dc9ae00edb2b0|xmm3=b0b2ed00ffffffffaec93d08ffffffff f=c41/0
  #|movlhps xmm6, xmm0|0f16f0|MOVLHPSrr:%XMM6,%XMM6,%XMM0|xmm0=0 xmm6=f1cfdffd47bdc97db7d286678c84d785 f=c52|xmm6=b7d286678c84d785 f=c50/0
  #|movlhps xmm6, xmm0|0f16f0|MOVLHPSrr:%XMM6,%XMM6,%XMM0|xmm0=bc82df4b3e338876fb7f01b213243a0d xmm6=8a427a1cb1085da502c4ecce2de33359 f=47|xmm6=fb7f01b213243a0d02c4ecce2de33359 f=45/0
  #|pmovzxbd xmm2, xmm0|660f3831d0|PMOVZXBDrr:%XMM2,%XMM0|xmm0=80008000800080008000800080008000 xmm2=26d016efd65e22633c81283ff0f8e3c f=d2|xmm2=80000000000000008000000000 f=d0/0
  #|pmovzxbd xmm2, xmm0|660f3831d0|PMOVZXBDrr:%XMM2,%XMM0|xmm0=8af3e742f4401f2f289bad8d89f302e6 xmm2=0 f=c16|xmm2=89000000f300000002000000e6 f=c14/0
  #|pmovzxwd xmm7, xmm0|660f3833f8|PMOVZXWDrr:%XMM7,%XMM0|xmm0=46c4263fae6a35877d52bd34ad84247d xmm7=80008000800080008000800080008000 f=843|xmm7=7d520000bd340000ad840000247d f=841/0
  #|pmovzxwd xmm7, xmm0|660f3833f8|PMOVZXWDrr:%XMM7,%XMM0|xmm0=8db66209f55eeb81054469a1b75a69b0 xmm7=79f2989745c82c3581771561d9d6d3bd f=8d6|xmm7=544000069a10000b75a000069b0 f=8d4/0
  #|pmovzxwd xmm7, qword ptr [edi + 0x10]|660f38337f10|PMOVZXWDrm:%XMM7,%EDI,1,%,16,%|ebx=e xmm7=7d351093f4ce8b9d21d1abdb72e65181 f=816 m10110=e6e32fe11c3e4ad90112b251cd08dee6|xmm7=d94a00003e1c0000e12f0000e3e6 f=814/0
  #|pmovzxdq xmm2, xmm5|660f3835d5|PMOVZXDQrr:%XMM2,%XMM5|xmm2=4ca21329e1aafd26de44831192068704 xmm5=0 f=8d3|xmm2=0 f=8d1/0
  #|pmovzxdq xmm2, xmm5|660f3835d5|PMOVZXDQrr:%XMM2,%XMM5|xmm2=4a8743ee5629a389d70eb86bc984730f xmm5=7aca5fb7d207db242c1c746d7648c690 f=16|xmm2=2c1c746d000000007648c690 f=14/0
  #|pmovsxwd xmm5, qword ptr [edi + 0x10]|660f38236f10|PMOVSXWDrm:%XMM5,%EDI,1,%,16,%|ebx=a xmm5=6bc5582f8909545f8c04c3c9fe76f544 f=896 m10110=3f695fcba23be2c82ec917e41617d7ba|xmm5=ffffc8e200003ba2ffffcb5f0000693f f=894/0
  #|psllw xmm6, 8|660f71f608|PSLLWri:%XMM6,%XMM6,8|xmm6=e63ba2971496f842e2d241e4316c3f01 f=53|xmm6=3b00970096004200d200e4006c000100 f=51/0
  #|psllw xmm6, 16|660f71f610|PSLLWri:%XMM6,%XMM6,16|xmm6=ffffffffffffffffffffffffffffffff f=16|xmm6=0 f=14/0
  #|psllw xmm6, 32|660f71f620|PSLLWri:%XMM6,%XMM6,32|xmm6=e0a17b61453e685d8f483e2b95a8b01b f=c2|xmm6=0 f=c0/0
  #|psllw xmm6, 63|660f71f63f|PSLLWri:%XMM6,%XMM6,63|xmm6=74342a31dcec62cbeab2f04fa87df59f f=892|xmm6=0 f=890/0
  #|psllw xmm6, 255|660f71f6ff|PSLLWri:%XMM6,%XMM6,255|xmm6=32221dd22aaffcde48649eebf79d7453 f=d6|xmm6=0 f=d4/0
  #|psllw xmm6, xmm7|660ff1f7|PSLLWrr:%XMM6,%XMM6,%XMM7|xmm6=80008000800080008000800080008000 xmm7=10 f=cc3|xmm6=0 f=cc1/0
  #|psllw xmm6, xmm7|660ff1f7|PSLLWrr:%XMM6,%XMM6,%XMM7|xmm6=31bceab9e671d037bf1088d93f826128 xmm7=7 f=6|xmm6=de005c8038801b8088006c80c1009400 f=4/0
  #|psllw xmm6, xmm7|660ff1f7|PSLLWrr:%XMM6,%XMM6,%XMM7|xmm6=caf9893c08885609c07417e83100b382 xmm7=f f=842|xmm6=80000000000080000000000000000000 f=840/0
  #|pslld xmm7, 0|660f72f700|PSLLDri:%XMM7,%XMM7,0|xmm7=1f3dad7921a7f360fb14e0b466ffd90f f=c96|f=c94/0
  #|pslld xmm7, 1|660f72f701|PSLLDri:%XMM7,%XMM7,1|xmm7=2084a3fe8e9332e28355e992aecc37a1 f=8c3|xmm7=410947fc1d2665c406abd3245d986f42 f=8c1/0
  #|pslld xmm7, 16|660f72f710|PSLLDri:%XMM7,%XMM7,16|xmm7=445153cee607632a25179118f7e13367 f=52|xmm7=53ce0000632a00009118000033670000 f=50/0
  #|pslld xmm7, 31|660f72f71f|PSLLDri:%XMM7,%XMM7,31|xmm7=80008000800080008000800080008000 f=8c3|xmm7=0 f=8c1/0
  #|pslld xmm7, 255|660f72f7ff|PSLLDri:%XMM7,%XMM7,255|xmm7=ffffffffffffffffffffffffffffffff f=413|xmm7=0 f=411/0
  #|pslld xmm7, xmm0|660ff2f8|PSLLDrr:%XMM7,%XMM7,%XMM0|xmm0=10 xmm7=db7cb357f5cf06cf5ff5478a8f9e811d f=806|xmm7=b357000006cf0000478a0000811d0000 f=804/0
  #|pslld xmm7, xmm0|660ff2f8|PSLLDrr:%XMM7,%XMM7,%XMM0|xmm0=11 xmm7=a9c726347c9d6ad631786cbae3b94bb8 f=d6|xmm7=4c680000d5ac0000d974000097700000 f=d4/0
  #|pslld xmm7, xmm0|660ff2f8|PSLLDrr:%XMM7,%XMM7,%XMM0|xmm0=21 xmm7=4679b9122d9587c233f046f532273f92 f=846|xmm7=0 f=844/0
  #|psllq xmm7, 63|660f73f73f|PSLLQri:%XMM7,%XMM7,63|xmm7=ffffffffffffffffffffffffffffffff f=43|xmm7=80000000000000008000000000000000 f=41/0
  #|psllq xmm7, 64|660f73f740|PSLLQri:%XMM7,%XMM7,64|xmm7=80008000800080008000800080008000 f=c07|xmm7=0 f=c05/0
  #|psllq xmm7, xmm0|660ff3f8|PSLLQrr:%XMM7,%XMM7,%XMM0|xmm0=40 xmm7=94720d1c7f818bba2715f7446c54f443 f=c7|xmm7=0 f=c5/0
  #|psllq xmm7, xmm0|660ff3f8|PSLLQrr:%XMM7,%XMM7,%XMM0|xmm0=7 xmm7=d7dd7a41a66cc6b85cbcd8b001df0386 f=8d6|xmm7=eebd20d336635c005e6c5800ef81c300 f=8d4/0
  #|psllq xmm7, xmm0|660ff3f8|PSLLQrr:%XMM7,%XMM7,%XMM0|xmm0=10 xmm7=bf05fe67e83f95e6f5cc9bb99a4bb951 f=817|xmm7=fe67e83f95e600009bb99a4bb9510000 f=815/0
  #|psrlw xmm6, 0|660f71d600|PSRLWri:%XMM6,%XMM6,0|xmm6=bca007c0221b7e645e7773d450d2a6ff f=803|f=801/0
  #|psrlw xmm6, 31|660f71d61f|PSRLWri:%XMM6,%XMM6,31|xmm6=efe67b841a3a1d1cb7d248398fd5024a f=842|xmm6=0 f=840/0
  #|psrlw xmm6, 63|660f71d63f|PSRLWri:%XMM6,%XMM6,63|xmm6=887f9e8c29577ff446df0087eb2ab40c f=97|xmm6=0 f=95/0
  #|psrlw xmm6, 64|660f71d640|PSRLWri:%XMM6,%XMM6,64|xmm6=94c9c09321c77a8c56ee835041ad0ee5 f=3|xmm6=0 f=1/0
  #|psrlw xmm6, xmm7|660fd1f7|PSRLWrr:%XMM6,%XMM6,%XMM7|xmm6=e55eedc24b4b778a84c0884494cce40c xmm7=10 f=897|xmm6=0 f=895/0
  #|psrlw xmm6, xmm7|660fd1f7|PSRLWrr:%XMM6,%XMM6,%XMM7|xmm6=0 xmm7=f f=92|f=90/0
  #|psrlw xmm6, xmm7|660fd1f7|PSRLWrr:%XMM6,%XMM6,%XMM7|xmm6=579aa733310794ebe980f89213536a4a xmm7=21 f=82|xmm6=0 f=80/0
  #|psrld xmm0, 0|660f72d000|PSRLDri:%XMM0,%XMM0,0|xmm0=8d763662c20b420314bc7e254e403ebe f=c17|f=c15/0
  #|psrld xmm0, 1|660f72d001|PSRLDri:%XMM0,%XMM0,1|xmm0=c861b57f691b2d67439b4beefab9954 f=c93|xmm0=6430dab7b48d96b3a1cda5f77d5ccaa f=c91/0
  #|psrld xmm0, 255|660f72d0ff|PSRLDri:%XMM0,%XMM0,255|xmm0=29e0f20a13e7e92acc2495270387e501 f=806|xmm0=0 f=804/0
  #|psrlq xmm3, 0|660f73d300|PSRLQri:%XMM3,%XMM3,0|xmm3=0 f=802|f=800/0
  #|psrlq xmm3, 1|660f73d301|PSRLQri:%XMM3,%XMM3,1|xmm3=ffffffffffffffffffffffffffffffff f=883|xmm3=7fffffffffffffff7fffffffffffffff f=881/0
  #|psrlq xmm3, 63|660f73d33f|PSRLQri:%XMM3,%XMM3,63|xmm3=0 f=86|f=84/0
  #|psrlq xmm3, 255|660f73d3ff|PSRLQri:%XMM3,%XMM3,255|xmm3=ffffffffffffffffffffffffffffffff f=846|xmm3=0 f=844/0
  #|psraw xmm0, 0|660f71e000|PSRAWri:%XMM0,%XMM0,0|xmm0=bfcc1a257121e08c728a28c92e180f4e f=8d7|f=8d5/0
  #|psraw xmm0, 1|660f71e001|PSRAWri:%XMM0,%XMM0,1|xmm0=ece9fd1ed23663beeabb73ace4fb24e7 f=12|xmm0=f674fe8fe91b31dff55d39d6f27d1273 f=10/0
  #|psraw xmm0, 16|660f71e010|PSRAWri:%XMM0,%XMM0,16|xmm0=ffffffffffffffffffffffffffffffff f=c92|f=c90/0
  #|psraw xmm0, 63|660f71e03f|PSRAWri:%XMM0,%XMM0,63|xmm0=80008000800080008000800080008000 f=806|xmm0=ffffffffffffffffffffffffffffffff f=804/0
  #|psrad xmm0, 0|660f72e000|PSRADri:%XMM0,%XMM0,0|xmm0=37047392cbbeadd89cf937676481b58a f=852|f=850/0
  #|psrad xmm0, 16|660f72e010|PSRADri:%XMM0,%XMM0,16|xmm0=8c39a35e7e939656be0059b55ac6b204 f=803|xmm0=ffff8c3900007e93ffffbe0000005ac6 f=801/0
  #|psrad xmm0, 32|660f72e020|PSRADri:%XMM0,%XMM0,32|xmm0=d2c66e736304c2fa55de57266cd839b5 f=413|xmm0=ffffffff000000000000000000000000 f=411/0
  #|pslldq xmm2, 0|660f73fa00|PSLLDQri:%XMM2,%XMM2,0|xmm2=238ba7cfaa8787b70138ccf6247ffc4 f=46|f=44/0
  #|pslldq xmm0, 1|660f73f801|PSLLDQri:%XMM0,%XMM0,1|xmm0=fa49f01e9d7322049446b954af27dfcc f=842|xmm0=49f01e9d7322049446b954af27dfcc00 f=840/0
  #|pslldq xmm5, 4|660f73fd04|PSLLDQri:%XMM5,%XMM5,4|xmm5=739bd846cfc92fc0e5b8ffbef92e63fe f=857|xmm5=cfc92fc0e5b8ffbef92e63fe00000000 f=855/0
  #|psrldq xmm3, 0|660f73db00|PSRLDQri:%XMM3,%XMM3,0|xmm3=76928f0aa92707d53bbe37086418fa6 f=17|f=15/0
  #|psrldq xmm6, 4|660f73de04|PSRLDQri:%XMM6,%XMM6,4|xmm6=95684f30e64c6bc8e549924d4351bf74 f=896|xmm6=95684f30e64c6bc8e549924d f=894/0
  #|psrldq xmm7, 8|660f73df08|PSRLDQri:%XMM7,%XMM7,8|xmm7=95715608b1c98600161b7da0fb7ccff2 f=6|xmm7=95715608b1c98600 f=4/0
  #|psrldq xmm6, 15|660f73de0f|PSRLDQri:%XMM6,%XMM6,15|xmm6=80008000800080008000800080008000 f=42|xmm6=80 f=40/0
  #|psrldq xmm3, 255|660f73dbff|PSRLDQri:%XMM3,%XMM3,255|xmm3=3e893307575c56ccf98c80a4154fc269 f=c03|xmm3=0 f=c01/0
  #|pshuflw xmm1, xmm5, 79|f20f70cd4f|PSHUFLWri:%XMM1,%XMM5,79|xmm1=0 xmm5=a9a70c17158f25bb6f309403f4449156 f=8d6|xmm1=a9a70c17158f25bbf44491566f306f30 f=8d4/0
  #|pshufhw xmm3, xmm4, 111|f30f70dc6f|PSHUFHWri:%XMM3,%XMM4,111|xmm3=e0938c40aa25bc5187c807b5aac4d586 xmm4=ab4300b5acbce0347eb74945ed747f52 f=883|xmm3=acbc00b5ab43ab437eb74945ed747f52 f=881/0
  #|pshufhw xmm2, xmm6, 0|f30f70d600|PSHUFHWri:%XMM2,%XMM6,0|xmm2=80008000800080008000800080008000 xmm6=ffffffffffffffffffffffffffffffff f=8c6|xmm2=ffffffffffffffffffffffffffffffff f=8c4/0
  #|shufps xmm7, xmm3, 9|0fc6fb09|SHUFPSrri:%XMM7,%XMM7,%XMM3,9|xmm3=80008000800080008000800080008000 xmm7=52b7c179f6b348170c9363ace3e1aef7 f=892|xmm7=8000800080008000f6b348170c9363ac f=890/0
  #|shufps xmm4, xmm5, 27|0fc6e51b|SHUFPSrri:%XMM4,%XMM4,%XMM5,27|xmm4=f67ca7fe9fc688dd5edc903fb589363b xmm5=2a35c0d0b2b80bf87e5175d99cb426f7 f=92|xmm4=9cb426f77e5175d99fc688ddf67ca7fe f=90/0
  #|shufps xmm2, xmm3, 0|0fc6d300|SHUFPSrri:%XMM2,%XMM2,%XMM3,0|xmm2=152e7c514fb0369663b7d804bf2a17f9 xmm3=179900aee433aa1c1905639d0f1549c f=8d6|xmm2=d0f1549cd0f1549cbf2a17f9bf2a17f9 f=8d4/0
  #|shufpd xmm6, xmm4, 22|660fc6f416|SHUFPDrri:%XMM6,%XMM6,%XMM4,22|xmm4=80008000800080008000800080008000 xmm6=56be6f599d1aed742e02572add4b91c4 f=843|xmm6=80008000800080002e02572add4b91c4 f=841/0
  #|shufpd xmm0, xmm6, 27|660fc6c61b|SHUFPDrri:%XMM0,%XMM0,%XMM6,27|xmm0=bdc68435a2061ec39dbfe2b0cbd5dcd0 xmm6=0 f=8d7|xmm0=bdc68435a2061ec3 f=8d5/0
  #|palignr xmm7, xmm4, 1|660f3a0ffc01|PALIGNRrri:%XMM7,%XMM7,%XMM4,1|xmm4=166597387e6c12558e11b5cf3184b1bf xmm7=0 f=c13|xmm7=166597387e6c12558e11b5cf3184b1 f=c11/0
  #|palignr xmm6, xmm1, 4|660f3a0ff104|PALIGNRrri:%XMM6,%XMM6,%XMM1,4|xmm1=a7c31efc1296487d4316dc716d49174f xmm6=31c1e6f18a2402e5f4487cba9e7a11e3 f=8c7|xmm6=9e7a11e3a7c31efc1296487d4316dc71 f=8c5/0
  #|pblendw xmm0, xmm6, 91|660f3a0ec65b|PBLENDWrri:%XMM0,%XMM0,%XMM6,91|xmm0=7018b1455214f7cae431b516957237f3 xmm6=ffffffffffffffffffffffffffffffff f=c92|xmm0=7018ffff5214ffffffffb516ffffffff f=c90/0
  #|pblendw xmm5, xmm7, 0|660f3a0eef00|PBLENDWrri:%XMM5,%XMM5,%XMM7,0|xmm5=a445b6f1e43b7cfedb617c8a94b78079 xmm7=0 f=82|f=80/0
  #|pinsrw xmm6, eax, 7|660fc4f007|PINSRWrri:%XMM6,%XMM6,%EAX,7|eax=80000000 xmm6=954d5b11e1c7e34bf5b09aee88662fdf f=897|xmm6=5b11e1c7e34bf5b09aee88662fdf f=895/0
  #|pinsrw xmm5, ecx, 3|660fc4e903|PINSRWrri:%XMM5,%XMM5,%ECX,3|ecx=e9a40882 xmm5=ffffffffffffffffffffffffffffffff f=d2|xmm5=ffffffffffffffff0882ffffffffffff f=d0/0
  #|pextrw ebx, xmm6, 0|660fc5de00|PEXTRWrri:%EBX,%XMM6,0|ebx=7fffffff xmm6=bf4a77f4b1e6292a985e664ad96c58e9 f=496|ebx=58e9 f=494/0
  #|pextrb edx, xmm2, 7|660f3a14d207|PEXTRBrri:%EDX,%XMM2,7|edx=d5 xmm2=256b873c5b1d467c42996cf9bfeb0ec4 f=96|edx=42 f=94/0
  #|pextrb eax, xmm4, 11|660f3a14e00b|PEXTRBrri:%EAX,%XMM4,11|eax=32ec51ed xmm4=894217b7f377e0b3cd4251daaff10bff f=c46|eax=f3 f=c44/0
  #|pextrd ebx, xmm6, 0|660f3a16f300|PEXTRDrri:%EBX,%XMM6,0|ebx=41 xmm6=dcc4acd6fce9f1e7a7f5edf251fcce10 f=8c3|ebx=51fcce10 f=8c1/0
  #|pinsrb xmm7, ecx, 3|660f3a20f903|PINSRBrri:%XMM7,%XMM7,%ECX,3|ecx=cd5e5db5 xmm7=37f4dbacaf967ec734a8058a4a3bec97 f=897|xmm7=37f4dbacaf967ec734a8058ab53bec97 f=895/0
  #|pinsrb xmm7, ebx, 0|660f3a20fb00|PINSRBrri:%XMM7,%XMM7,%EBX,0|ebx=94 xmm7=83f4b4b8e43ba14bfb4df30719c9a625 f=8d3|xmm7=83f4b4b8e43ba14bfb4df30719c9a694 f=8d1/0
  #|pinsrd xmm0, edx, 0|660f3a22c200|PINSRDrri:%XMM0,%XMM0,%EDX,0|edx=ffffffff xmm0=f624ef40e80cbcf8a7ae5d4f04e0aefd f=97|xmm0=f624ef40e80cbcf8a7ae5d4fffffffff f=95/0
  #|pshufd xmm1, xmmword ptr [esi], 0x4e|660f700e4e|PSHUFDmi:%XMM1,%ESI,1,%,0,%,78|xmm1=c4cc10dc3b53c48370b1a672bf7701e6 f=413 m10080=a622dcd02bdd04a4bd9022d6d784c96f|xmm1=a404dd2bd0dc22a66fc984d7d62290bd f=411/0
  #|movd xmm1, ebx|660f6ecb|MOVDI2PDIrr:%XMM1,%EBX|ebx=91fcdd1 xmm1=81ee425c5beb2f89f0e2483bab833e61 f=93|xmm1=91fcdd1 f=91/0
  #|movd xmm1, ebx|660f6ecb|MOVDI2PDIrr:%XMM1,%EBX|ebx=bd2556a xmm1=14dc2e942d0fb5200eff87bd8b8a39b3 f=483|xmm1=bd2556a f=481/0
  #|movd ebx, xmm2|660f7ed3|MOVPDI2DIrr:%EBX,%XMM2|ebx=7898ffff xmm2=f736c657708ccadc7e35fcb1553dd17b f=803|ebx=553dd17b f=801/0
  #|movd ebx, xmm2|660f7ed3|MOVPDI2DIrr:%EBX,%XMM2|ebx=8c5233ef xmm2=1c14b261a4c58acd486782cd20cbb751 f=847|ebx=20cbb751 f=845/0
  #|movd xmm3, dword ptr [edi + 0x10]|660f6e5f10|MOVDI2PDIrm:%XMM3,%EDI,1,%,16,%|xmm3=5cd8be071579b94f9ba21d835a4fddfe f=47 m10110=2a0d48f418a2c096f8cb831ec6fcb4d0|xmm3=f4480d2a f=45/0
  #|movd xmm3, dword ptr [edi + 0x10]|660f6e5f10|MOVDI2PDIrm:%XMM3,%EDI,1,%,16,%|xmm3=3c5d85eadaa8136d62790520cb255987 f=6 m10110=573c986396957398fb4a351942a74fbe|xmm3=63983c57 f=4/0
  #|movq xmm1, xmm2|f30f7eca|MOVZPQILo2PQIrr:%XMM1,%XMM2|xmm1=6b3de2acfeb9b92038957dc8cfae9a15 xmm2=ddd3367d5a4ede32aaaf71f3ef1db351 f=486|xmm1=aaaf71f3ef1db351 f=484/0
  #|movq xmm1, xmm2|f30f7eca|MOVZPQILo2PQIrr:%XMM1,%XMM2|xmm1=b5498b8f6b245b97810a96af9031ec15 xmm2=ffffffffffffffffffffffffffffffff f=87|xmm1=ffffffffffffffff f=85/0
  #|pmovmskb ebx, xmm5|660fd7dd|PMOVMSKBrr:%EBX,%XMM5|ebx=e779bb0b xmm5=ffffffffffffffffffffffffffffffff f=8d7|ebx=ffff f=8d5/0
  #|pmovmskb ebx, xmm5|660fd7dd|PMOVMSKBrr:%EBX,%XMM5|ebx=2a02 xmm5=b10290276746fa3cff3b516dd3d3f07 f=843|ebx=1e8 f=841/0
  #|movmskps ebx, xmm5|0f50dd|MOVMSKPSrr:%EBX,%XMM5|ebx=ffff xmm5=2253b1f976ba22465fff4951607ac24e f=16|ebx=0 f=14/0
  #|movmskps ebx, xmm5|0f50dd|MOVMSKPSrr:%EBX,%XMM5|ebx=564b500 xmm5=80008000800080008000800080008000 f=8c3|ebx=f f=8c1/0
  #|movhps xmm1, qword ptr [edi + 0x10]|0f164f10|MOVHPSrm:%XMM1,%XMM1,%EDI,1,%,16,%|xmm1=1cd434fde0833aba7687fbd2b29dd5b3 f=2 m10110=10dc4149eeef15a5ab02d3300dd71bba|xmm1=a515efee4941dc107687fbd2b29dd5b3 f=0/0
  #|movhps xmm1, qword ptr [edi + 0x10]|0f164f10|MOVHPSrm:%XMM1,%XMM1,%EDI,1,%,16,%|xmm1=2bc454a718f2f8bba6c1beea45576cb1 f=8d2 m10110=20708ddf91136a15b0c8bee2fd55b590|xmm1=156a1391df8d7020a6c1beea45576cb1 f=8d0/0
  #|movlps xmm1, qword ptr [edi + 0x10]|0f124f10|MOVLPSrm:%XMM1,%XMM1,%EDI,1,%,16,%|xmm1=a491ebfa383b86d565ef47a05588a4 f=93 m10110=bf498af050edcb36c3de0e3ac931b74b|xmm1=a491ebfa383b8636cbed50f08a49bf f=91/0
  #|movlps xmm1, qword ptr [edi + 0x10]|0f124f10|MOVLPSrm:%XMM1,%XMM1,%EDI,1,%,16,%|xmm1=14b1a92186ebde512ee943d1ebf8385f f=47 m10110=899a2781e1458616cc3c11df179548ee|xmm1=14b1a92186ebde51168645e181279a89 f=45/0
  #|movdqa xmmword ptr [esi], xmm3|660f7f1e|MOVDQAmr:%ESI,1,%,0,%,%XMM3|xmm3=ffffffffffffffffffffffffffffffff f=492 m10080=384ec012d29c816f2114fa043b4e0003|f=490/0 m10080=ffffffffffffffffffffffffffffffff
  #|movdqa xmmword ptr [esi], xmm3|660f7f1e|MOVDQAmr:%ESI,1,%,0,%,%XMM3|xmm3=0 f=8d7 m10080=025487ae06ae6f41fdf6cb81999a5abb|f=8d5/0 m10080=00000000000000000000000000000000
  #|movups xmmword ptr [edi + 0x10], xmm3|0f115f10|MOVUPSmr:%EDI,1,%,16,%,%XMM3|xmm3=76f883c5849f649ae86e6109468cdd5c f=856 m10110=0c03cd5708872f92fd17c325b51caddf|f=854/0 m10110=5cdd8c4609616ee89a649f84c583f876
  #|movups xmmword ptr [edi + 0x10], xmm3|0f115f10|MOVUPSmr:%EDI,1,%,16,%,%XMM3|xmm3=5f43a0cae3240b30a37f8787ff8b7dbd f=c2 m10110=af8757f9c4a662deadf2557a36826bf9|f=c0/0 m10110=bd7d8bff87877fa3300b24e3caa0435f
  #|movss xmm1, xmm2|f30f10ca|MOVSSrr:%XMM1,%XMM1,%XMM2|ecx=7fffffff edx=e33b6db xmm1=0 xmm2=6a4f9e68c5ad9c7bbabeee4c53ef125a f=d7|xmm1=53ef125a f=d5/0
  #|movss xmm1, xmm2|f30f10ca|MOVSSrr:%XMM1,%XMM1,%XMM2|eax=6adc4315 ecx=adc7fff2 edx=7d9094ba xmm1=ee9e4c37bf9e87340238212f6ed704ed xmm2=bc6aa345151cb87ebbc4fec37ad19ddc f=c7|xmm1=ee9e4c37bf9e87340238212f7ad19ddc f=c5/0
  #|movsd xmm1, xmm2|f20f10ca|MOVSDrr:%XMM1,%XMM1,%XMM2|eax=291bfcdc edx=80 xmm1=ffffffffffffffffffffffffffffffff xmm2=e2428e28798e01087e9b8fcc7406762c f=816|xmm1=ffffffffffffffff7e9b8fcc7406762c f=814/0
  #|movsd xmm1, xmm2|f20f10ca|MOVSDrr:%XMM1,%XMM1,%XMM2|eax=cd5384f5 ecx=8438c87d edx=80000000 xmm1=3d587f72192cae262ac97e612241f38a xmm2=e1a1aa79d4bb71948543d5afcb856391 f=496|xmm1=3d587f72192cae268543d5afcb856391 f=494/0
  #|movss dword ptr [edi + 0x10], xmm1|f30f114f10|MOVSSmr:%EDI,1,%,16,%,%XMM1|eax=bf7f ecx=d5bdf7ba edx=44105d03 xmm1=e2b8a6f20df5cdf1579305cb9318ec9 f=847 m10110=454be97d23649793f7ccb9b010d1b637|f=845/0 m10110=c98e31b9
  #|movss dword ptr [edi + 0x10], xmm1|f30f114f10|MOVSSmr:%EDI,1,%,16,%,%XMM1|eax=43b5880b edx=b361e500 xmm1=8f8979fc7db78fb3cdf45350b48135b9 f=57 m10110=dae0db2644fd3d64f57c92e1e122a3e7|f=55/0 m10110=b93581b4
