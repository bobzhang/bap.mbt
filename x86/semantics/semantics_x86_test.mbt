// Agreement of the `x86` providers (per-opcode, then legacy) on LLVM's MCInst with Unicorn
// (see semantics_harness_test.mbt); the findings list the first
// differences of each disagreeing instruction.

///|
test "x86: alu" {
  inspect(
    family_report(lift_x86, "alu"),
    content=(
      #|x86-64: cases=664 lifted=664 agree=664 mismatch=0 failed=0
      #|x86: cases=254 lifted=254 agree=254 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: muldiv" {
  inspect(
    family_report(lift_x86, "muldiv"),
    content=(
      #|x86-64: cases=173 lifted=173 agree=162 mismatch=11 failed=0
      #|idiv r8b [41f6f8]: exn: none expected 0; RAX=0xefedfdf0db3a0924 expected 0xefedfdf0db3a6805
      #|idiv byte ptr [rbp - 0x20] [f67de0]: exn: none expected 0; RAX=0xb74884f451bf187a expected 0xb74884f451bf662a
      #|idiv r8w [6641f7f8]: exn: none expected 0; RDX=0x7becd69ce4ad0000 expected 0x7becd69ce4ad0001
      #|imul r13d [41f7ed]: CF=0 expected 1; OF=0 expected 1
      #|idiv dword ptr [rdi + 0x10] [f77f10]: exn: none expected 0; RAX=0x4ba4359e expected 0x522a5ca2d98cb759; RDX=0x361495fb expected 0xe6659ba946799b5c
      #|imul qword ptr [rbp - 0x20] [48f76de0]: CF=0 expected 1; OF=0 expected 1
      #|idiv r8 [49f7f8]: exn: none expected 0; RAX=0xb38741e0379ee777 expected 0x5b791f3dd3f197b5; RDX=0xf284698cd12f5eb0 expected 0xba1aed21f2de819f
      #|idiv qword ptr [rsi] [48f73e]: exn: none expected 0; RAX=0x5048a285a4713cfc expected 0x59791c1e76d52070; RDX=0xeddc41c222df2060 expected 0xbea79bd518d034ae
      #|x86: cases=126 lifted=126 agree=120 mismatch=6 failed=0
      #|imul bl [f6eb]: CF=1 expected 0; OF=1 expected 0
      #|imul byte ptr [esi] [f62e]: CF=1 expected 0; OF=1 expected 0
      #|idiv cl [f6f9]: exn: none expected 0
      #|idiv ecx [f7f9]: exn: none expected 0
    ),
  )
}

///|
test "x86: shift" {
  inspect(
    family_report(lift_x86, "shift"),
    content=(
      #|x86-64: cases=763 lifted=574 agree=436 mismatch=138 failed=0
      #|shl dl, 8 [c0e208]: RDX=0xffffffff expected 0xffffff00; PF=0 expected 1; ZF=0 expected 1
      #|shl dl, 9 [c0e209]: RDX=0xa0 expected 0x0; ZF=0 expected 1; SF=1 expected 0
      #|shl dl, 31 [c0e21f]: RDX=0x683d958d4f079480 expected 0x683d958d4f079400; PF=0 expected 1; ZF=0 expected 1
      #|shl byte ptr [rsi + rbx*4 + 0x8], cl [d2649e08]: PF=0 expected 1; ZF=0 expected 1; mem[0x100c0]=0x4c expected 0x0
      #|shl r8w, 16 [6641c1e010]: R8=0x9efeed6b54ba027f expected 0x9efeed6b54ba0000; PF=0 expected 1
      #|shl r8w, 17 [6641c1e011]: R8=0x15d0d199c57c69f2 expected 0x15d0d199c57c0000; PF=0 expected 1; ZF=0 expected 1
      #|shl word ptr [rbp - 0x20], cl [66d365e0]: ZF=0 expected 1; mem[0x20160]=0xd5 expected 0x0
      #|shr al, 8 [c0e808]: RAX=0x67a8 expected 0x6700; PF=0 expected 1
      #|shr al, 9 [c0e809]: RAX=0xc731fd9e36dcdf0e expected 0xc731fd9e36dcdf00; PF=0 expected 1; ZF=0 expected 1
      #|shr byte ptr [rdi + r9*2 - 0x4], cl [42d26c4ffc]: PF=0 expected 1; ZF=0 expected 1; mem[0x10108]=0x1 expected 0x0
      #|shr ax, cl [66d3e8]: RAX=0xffffffffffff0001 expected 0xffffffffffff0000; PF=0 expected 1; ZF=0 expected 1
      #|shr ax, 16 [66c1e810]: RAX=0x7790e499df4d3f2a expected 0x7790e499df4d0000
      #|shr ax, 17 [66c1e811]: RAX=0xffff7fff expected 0xffff0000; ZF=0 expected 1
      #|shr word ptr [rdi + 0x10], cl [66d36f10]: PF=0 expected 1; ZF=0 expected 1; mem[0x10110]=0xba expected 0x0
      #|sar r12b, cl [41d2fc]: CF=0 expected 1; PF=0 expected 1
      #|sar r12b, 8 [41c0fc08]: R12=0xde63a2b8be68e266 expected 0xde63a2b8be68e200
      #|sar r12b, 9 [41c0fc09]: R12=0x28a806af4623bd8 expected 0x28a806af4623bff
      #|sar byte ptr [rdi + r9*2 - 0x4], cl [42d27c4ffc]: CF=0 expected 1; PF=0 expected 1; mem[0x10114]=0xfd expected 0xff
      #|sar bx, cl [66d3fb]: RBX=0xcbe1cd726dafbaf7 expected 0xcbe1cd726dafffff; CF=0 expected 1; PF=0 expected 1
      #|sar bx, 16 [66c1fb10]: ZF=1 expected 0
      #|sar bx, 17 [66c1fb11]: RBX=0xa4832b0190650921 expected 0xa4832b0190650000; ZF=0 expected 1
      #|sar word ptr [rdi + 0x10], cl [66d37f10]: PF=0 expected 1; ZF=0 expected 1; mem[0x10110]=0x1a expected 0x0
      #|rol r8b, 1 [41d0c0]: CF=1 expected 0; OF=1 expected 0
      #|rol r8b, cl [41d2c0]: CF=1 expected 0; OF=1 expected 0
      #|rol r8b, 9 [41c0c009]: CF=1 expected 0
      #|rol byte ptr [rsi], 1 [d006]: CF=0 expected 1; OF=1 expected 0
      #|rol byte ptr [rsi], 6 [c00606]: CF=1 expected 0
      #|rol bx, cl [66d3c3]: CF=1 expected 0
      #|rol bx, 0 [66c1c300]: CF=1 expected 0
      #|rol bx, 8 [66c1c308]: CF=0 expected 1
      #|rol bx, 15 [66c1c30f]: CF=0 expected 1
      #|rol bx, 17 [66c1c311]: CF=0 expected 1
      #|rol bx, 64 [66c1c340]: CF=1 expected 0
      #|rol word ptr [rsi + rbx*4 + 0x8], 1 [66d1449e08]: CF=0 expected 1; OF=0 expected 1
      #|rol word ptr [rsi + rbx*4 + 0x8], cl [66d3449e08]: CF=1 expected 0
      #|rol word ptr [rsi + rbx*4 + 0x8], 9 [66c1449e0809]: CF=0 expected 1
      #|rol r12d, 1 [41d1c4]: CF=1 expected 0; OF=1 expected 0
      #|rol r12d, cl [41d3c4]: CF=1 expected 0; OF=1 expected 0
      #|rol r12d, 28 [41c1c41c]: CF=0 expected 1
      #|rol r12d, 31 [41c1c41f]: CF=1 expected 0
      #|rol r12d, 32 [41c1c420]: CF=0 expected 1
      #|rol r12d, 63 [41c1c43f]: CF=1 expected 0
      #|rol dword ptr [rsp + 0x8], 1 [d1442408]: CF=1 expected 0; OF=1 expected 0
      #|rol dword ptr [rsp + 0x8], cl [d3442408]: CF=1 expected 0
      #|rol dword ptr [rsp + 0x8], 6 [c144240806]: CF=0 expected 1
      #|rol rdx, 1 [48d1c2]: CF=1 expected 0; OF=0 expected 1
      #|rol rdx, cl [48d3c2]: CF=1 expected 0; OF=1 expected 0
      #|rol rdx, 0 [48c1c200]: CF=0 expected 1
      #|rol rdx, 48 [48c1c230]: CF=1 expected 0
      #|rol rdx, 63 [48c1c23f]: CF=0 expected 1
      #|rol rdx, 65 [48c1c241]: CF=0 expected 1; OF=1 expected 0
      #|rol qword ptr [rdi + 0x10], cl [48d34710]: CF=0 expected 1
      #|ror al, 1 [d0c8]: CF=0 expected 1
      #|ror al, cl [d2c8]: CF=0 expected 1
      #|ror al, 3 [c0c803]: CF=0 expected 1
      #|ror al, 7 [c0c807]: CF=0 expected 1
      #|ror al, 9 [c0c809]: CF=0 expected 1
      #|ror al, 255 [c0c8ff]: CF=1 expected 0
      #|ror byte ptr [rbp - 0x20], 1 [d04de0]: CF=0 expected 1
      #|ror byte ptr [rbp - 0x20], cl [d24de0]: CF=1 expected 0
      #|ror byte ptr [rbp - 0x20], 3 [c04de003]: CF=0 expected 1
      #|ror dx, 1 [66d1ca]: CF=0 expected 1
      #|ror dx, cl [66d3ca]: CF=1 expected 0
      #|ror dx, 0 [66c1ca00]: CF=0 expected 1
      #|ror dx, 7 [66c1ca07]: CF=1 expected 0
      #|ror dx, 17 [66c1ca11]: CF=0 expected 1
      #|ror word ptr [rsi], 1 [66d10e]: CF=0 expected 1
      #|ror word ptr [rsi], 12 [66c10e0c]: CF=1 expected 0
      #|ror edx, cl [d3ca]: CF=1 expected 0
      #|ror edx, 0 [c1ca00]: CF=1 expected 0
      #|ror edx, 20 [c1ca14]: CF=1 expected 0
      #|ror edx, 31 [c1ca1f]: CF=1 expected 0
      #|ror edx, 33 [c1ca21]: CF=1 expected 0
      #|ror dword ptr [rsp + 0x8], 1 [d14c2408]: CF=0 expected 1
      #|ror dword ptr [rsp + 0x8], 17 [c14c240811]: CF=0 expected 1
      #|ror r12, 1 [49d1cc]: CF=0 expected 1
      #|ror r12, cl [49d3cc]: CF=1 expected 0
      #|ror r12, 21 [49c1cc15]: CF=1 expected 0
      #|ror r12, 64 [49c1cc40]: CF=1 expected 0
      #|ror r12, 65 [49c1cc41]: CF=1 expected 0
      #|ror qword ptr [rdi + r9*2 - 0x4], 1 [4ad14c4ffc]: CF=1 expected 0
      #|ror qword ptr [rdi + r9*2 - 0x4], cl [4ad34c4ffc]: CF=0 expected 1
      #|ror qword ptr [rdi + r9*2 - 0x4], 46 [4ac14c4ffc2e]: CF=1 expected 0
      #|x86: cases=317 lifted=235 agree=181 mismatch=54 failed=0
      #|shl bl, cl [d2e3]: EBX=0xff8b513c expected 0xff8b5100; ZF=0 expected 1
      #|shl bl, 8 [c0e308]: EBX=0x31f9c4eb expected 0x31f9c400; SF=1 expected 0
      #|shl byte ptr [esi + ebx*4 + 0x8], cl [d2649e08]: PF=0 expected 1; ZF=0 expected 1; SF=1 expected 0
      #|shl dx, 16 [66c1e210]: EDX=0xb4affff expected 0xb4a0000; ZF=0 expected 1
      #|shl word ptr [esp + 0x8], cl [66d3642408]: ZF=0 expected 1; mem[0x20109]=0x6a expected 0x0
      #|shr bl, cl [d2eb]: EBX=0x1f6f9b30 expected 0x1f6f9b00; ZF=0 expected 1
      #|shr byte ptr [ebp - 0x20], cl [d26de0]: PF=0 expected 1; ZF=0 expected 1; mem[0x20160]=0x1 expected 0x0
      #|shr ax, cl [66d3e8]: EAX=0x2 expected 0x0; SF=1 expected 0
      #|sar al, 8 [c0f808]: EAX=0xb4817501 expected 0xb4817500; PF=0 expected 1; ZF=0 expected 1
      #|sar byte ptr [esp + 0x8], cl [d27c2408]: CF=0 expected 1
      #|sar ax, 16 [66c1f810]: PF=0 expected 1
      #|sar ax, 31 [66c1f81f]: CF=0 expected 1
      #|rol dl, cl [d2c2]: CF=1 expected 0
      #|rol dl, 4 [c0c204]: CF=0 expected 1
      #|rol dl, 7 [c0c207]: CF=1 expected 0
      #|rol byte ptr [esi + ebx*4 + 0x8], 1 [d0449e08]: CF=1 expected 0; OF=0 expected 1
      #|rol byte ptr [esi + ebx*4 + 0x8], cl [d2449e08]: CF=1 expected 0; OF=1 expected 0
      #|rol ax, 1 [66d1c0]: CF=0 expected 1; OF=1 expected 0
      #|rol ax, 15 [66c1c00f]: CF=0 expected 1
      #|rol ax, 17 [66c1c011]: CF=1 expected 0
      #|rol ax, 65 [66c1c041]: CF=1 expected 0; OF=0 expected 1
      #|rol word ptr [esp + 0x8], cl [66d3442408]: CF=1 expected 0
      #|rol edx, 1 [d1c2]: CF=1 expected 0; OF=1 expected 0
      #|rol edx, 0 [c1c200]: CF=1 expected 0
      #|rol edx, 33 [c1c221]: CF=1 expected 0; OF=1 expected 0
      #|ror al, 1 [d0c8]: CF=1 expected 0
      #|ror al, cl [d2c8]: CF=1 expected 0
      #|ror byte ptr [edi + 0x10], cl [d24f10]: CF=1 expected 0
      #|ror bx, 0 [66c1cb00]: CF=0 expected 1
      #|ror bx, 17 [66c1cb11]: CF=0 expected 1
      #|ror word ptr [edi + 0x10], cl [66d34f10]: CF=0 expected 1
      #|ror word ptr [edi + 0x10], 4 [66c14f1004]: CF=1 expected 0
      #|ror ebx, 16 [c1cb10]: CF=1 expected 0
      #|ror dword ptr [esi + ebx*4 + 0x8], 1 [d14c9e08]: CF=1 expected 0
      #|ror dword ptr [esi + ebx*4 + 0x8], cl [d34c9e08]: CF=0 expected 1
    ),
  )
}

///|
test "x86: bits" {
  inspect(
    family_report(lift_x86, "bits"),
    content=(
      #|x86-64: cases=237 lifted=237 agree=93 mismatch=144 failed=0
      #|bt r15w, r13w [66450fa3ef]: ZF undefined, expected 1
      #|bt r15w, 11 [66410fbae70b]: ZF undefined, expected 1
      #|bt r15w, 19 [66410fbae713]: ZF undefined, expected 0
      #|bt r15w, 255 [66410fbae7ff]: ZF undefined, expected 1
      #|bt word ptr [rdi + 0x10], dx [660fa35710]: ZF undefined, expected 0
      #|bt word ptr [rdi + 0x10], 0 [660fba671000]: ZF undefined, expected 0
      #|bt r13d, r15d [450fa3fd]: ZF undefined, expected 0
      #|bt r13d, 26 [410fbae51a]: ZF undefined, expected 0
      #|bt r13d, 35 [410fbae523]: ZF undefined, expected 0
      #|bt r13d, 255 [410fbae5ff]: ZF undefined, expected 1
      #|bt dword ptr [rdi + 0x10], r8d [440fa34710]: ZF undefined, expected 1
      #|bt dword ptr [rdi + 0x10], 40 [0fba671028]: ZF undefined, expected 0
      #|bt r15, rcx [490fa3cf]: ZF undefined, expected 1
      #|bt r15, 42 [490fbae72a]: ZF undefined, expected 0
      #|bt r15, 67 [490fbae743]: ZF undefined, expected 0
      #|bt r15, 255 [490fbae7ff]: ZF undefined, expected 1
      #|bt qword ptr [rdi + 0x10], r8 [4c0fa34710]: ZF undefined, expected 0
      #|bt qword ptr [rdi + 0x10], 44 [480fba67102c]: ZF undefined, expected 1
      #|bts r11w, cx [66410fabcb]: ZF undefined, expected 1
      #|bts r11w, 3 [66410fbaeb03]: ZF undefined, expected 0
      #|bts r11w, 19 [66410fbaeb13]: ZF undefined, expected 1
      #|bts r11w, 255 [66410fbaebff]: ZF undefined, expected 1
      #|bts word ptr [rbp - 0x20], ax [660fab45e0]: ZF undefined, expected 1
      #|bts word ptr [rbp - 0x20], 7 [660fba6de007]: ZF undefined, expected 0
      #|bts r10d, r9d [450fabca]: R10=0x1335981ee7407941 expected 0xe7407941; ZF undefined, expected 0
      #|bts r10d, 12 [410fbaea0c]: R10=0x2c992597952e7533 expected 0x952e7533; ZF undefined, expected 0
      #|bts r10d, 35 [410fbaea23]: R10=0xd1f24edf560ad45b expected 0x560ad45b; ZF undefined, expected 0
      #|bts r10d, 255 [410fbaeaff]: ZF undefined, expected 0
      #|bts dword ptr [rbp - 0x20], eax [0fab45e0]: ZF undefined, expected 0
      #|bts dword ptr [rbp - 0x20], 33 [0fba6de021]: ZF undefined, expected 0
      #|bts r11, r15 [4d0fabfb]: ZF undefined, expected 0
      #|bts r11, 0 [490fbaeb00]: ZF undefined, expected 0
      #|bts r11, 67 [490fbaeb43]: ZF undefined, expected 1
      #|bts r11, 255 [490fbaebff]: ZF undefined, expected 1
      #|bts qword ptr [rdi + 0x10], rdx [480fab5710]: ZF undefined, expected 0
      #|bts qword ptr [rdi + 0x10], 15 [480fba6f100f]: ZF undefined, expected 1
      #|btr r12w, r13w [66450fb3ec]: ZF undefined, expected 0
      #|btr r12w, 11 [66410fbaf40b]: ZF undefined, expected 0
      #|btr r12w, 19 [66410fbaf413]: ZF undefined, expected 1
      #|btr r12w, 255 [66410fbaf4ff]: ZF undefined, expected 0
      #|btr word ptr [rdi + 0x10], ax [660fb34710]: ZF undefined, expected 1
      #|btr word ptr [rdi + 0x10], 13 [660fba77100d]: ZF undefined, expected 1
      #|btr r13d, eax [410fb3c5]: ZF undefined, expected 1
      #|btr r13d, 30 [410fbaf51e]: R13=0x1cdba1eb308523cf expected 0x308523cf; ZF undefined, expected 0
      #|btr r13d, 35 [410fbaf523]: R13=0x2010603723782cb0 expected 0x23782cb0; ZF undefined, expected 0
      #|btr r13d, 255 [410fbaf5ff]: R13=0x6b4fdc380d258402 expected 0xd258402; ZF undefined, expected 1
      #|btr dword ptr [rsi], r8d [440fb306]: ZF undefined, expected 0
      #|btr dword ptr [rsi], 37 [0fba3625]: ZF undefined, expected 1
      #|btr r14, r15 [4d0fb3fe]: ZF undefined, expected 1
      #|btr r14, 61 [490fbaf63d]: ZF undefined, expected 1
      #|btr r14, 67 [490fbaf643]: ZF undefined, expected 1
      #|btr r14, 255 [490fbaf6ff]: ZF undefined, expected 1
      #|btr qword ptr [rdi + 0x10], rax [480fb34710]: ZF undefined, expected 0
      #|btr qword ptr [rdi + 0x10], 39 [480fba771027]: ZF undefined, expected 1
      #|btc r13w, ax [66410fbbc5]: ZF undefined, expected 1
      #|btc r13w, 0 [66410fbafd00]: ZF undefined, expected 0
      #|btc r13w, 19 [66410fbafd13]: ZF undefined, expected 0
      #|btc r13w, 255 [66410fbafdff]: ZF undefined, expected 1
      #|btc word ptr [rsi], r8w [66440fbb06]: ZF undefined, expected 0
      #|btc word ptr [rsi], 5 [660fba3e05]: ZF undefined, expected 1
      #|btc r8d, eax [410fbbc0]: R8=0xd37fcec9364bfb8e expected 0x364bfb8e; ZF undefined, expected 0
      #|btc r8d, 19 [410fbaf813]: R8=0xea6fc08f7e64ef3d expected 0x7e64ef3d; ZF undefined, expected 0
      #|btc r8d, 35 [410fbaf823]: R8=0x11be559a046fbdc3 expected 0x46fbdc3; ZF undefined, expected 1
      #|btc r8d, 255 [410fbaf8ff]: R8=0x80e29a7f0956527d expected 0x956527d; ZF undefined, expected 0
      #|btc dword ptr [rbp - 0x20], r8d [440fbb45e0]: ZF undefined, expected 0
      #|btc dword ptr [rbp - 0x20], 31 [0fba7de01f]: ZF undefined, expected 1
      #|btc r13, r14 [4d0fbbf5]: ZF undefined, expected 0
      #|btc r13, 46 [490fbafd2e]: ZF undefined, expected 1
      #|btc r13, 67 [490fbafd43]: ZF undefined, expected 1
      #|btc r13, 255 [490fbafdff]: ZF undefined, expected 1
      #|btc qword ptr [rbp - 0x20], r8 [4c0fbb45e0]: ZF undefined, expected 0
      #|btc qword ptr [rbp - 0x20], 29 [480fba7de01d]: ZF undefined, expected 0
      #|x86: cases=99 lifted=99 agree=44 mismatch=55 failed=0
      #|bt ax, 255 [660fbae0ff]: ZF undefined, expected 1
      #|bt word ptr [esi], dx [660fa316]: ZF undefined, expected 0
      #|bt word ptr [esi], 26 [660fba261a]: ZF undefined, expected 0
      #|bt eax, 12 [0fbae00c]: ZF undefined, expected 1
      #|bt eax, 35 [0fbae023]: ZF undefined, expected 0
      #|bts bx, 9 [660fbaeb09]: ZF undefined, expected 1
      #|bts bx, 19 [660fbaeb13]: ZF undefined, expected 1
      #|bts bx, 255 [660fbaebff]: ZF undefined, expected 0
      #|bts ecx, ebx [0fabd9]: ZF undefined, expected 0
      #|bts ecx, 35 [0fbae923]: ZF undefined, expected 1
      #|bts ecx, 255 [0fbae9ff]: ZF undefined, expected 1
      #|bts dword ptr [edi + 0x10], eax [0fab4710]: ZF undefined, expected 0
      #|btr dx, bx [660fb3da]: ZF undefined, expected 1
      #|btr dx, 4 [660fbaf204]: ZF undefined, expected 1
      #|btr dx, 19 [660fbaf213]: ZF undefined, expected 0
      #|btr dx, 255 [660fbaf2ff]: ZF undefined, expected 0
      #|btr word ptr [esi], dx [660fb316]: ZF undefined, expected 1
      #|btr ecx, eax [0fb3c1]: ZF undefined, expected 1
      #|btr ecx, 6 [0fbaf106]: ZF undefined, expected 1
      #|btr ecx, 35 [0fbaf123]: ZF undefined, expected 0
      #|btr ecx, 255 [0fbaf1ff]: ZF undefined, expected 1
      #|btr dword ptr [esi], eax [0fb306]: ZF undefined, expected 0
      #|btr dword ptr [esi], 15 [0fba360f]: ZF undefined, expected 1
      #|btc dx, 255 [660fbafaff]: ZF undefined, expected 1
      #|btc word ptr [edi + 0x10], 8 [660fba7f1008]: ZF undefined, expected 0
      #|btc edx, ebx [0fbbda]: ZF undefined, expected 1
      #|btc edx, 35 [0fbafa23]: ZF undefined, expected 1
      #|btc edx, 255 [0fbafaff]: ZF undefined, expected 0
      #|btc dword ptr [edi + 0x10], edx [0fbb5710]: ZF undefined, expected 0
    ),
  )
}

///|
test "x86: move" {
  inspect(
    family_report(lift_x86, "move"),
    content=(
      #|x86-64: cases=405 lifted=383 agree=348 mismatch=35 failed=0
      #|xadd r14w, r9w [66450fc1ce]: R9=0x7f expected 0x0
      #|xadd word ptr [rsi], r9w [66440fc10e]: R9=0x3862 expected 0x385a; mem[0x10080]=0x8 expected 0x62
      #|cmpxchg r15d, r8d [450fb1c7]: RAX=0x6af4467f00000000 expected 0x0
      #|cmpxchg dword ptr [rdi + r9*2 - 0x4], r8d [460fb1444ffc]: RAX=0x76b48f4d168f114c expected 0x168f114c
      #|xadd r15d, r8d [450fc1c7]: R8=0xfffd expected 0xfffffffe; R15=0xffff expected 0xfffd
      #|xadd dword ptr [rdi + r9*2 - 0x4], r8d [460fc1444ffc]: R8=0x966cb910 expected 0x966cb903; mem[0x10104]=0xd expected 0x10
      #|xadd r15, r11 [4d0fc1df]: R11=0x7cfe3892dd2e08a4 expected 0xf14faad772117eff; R15=0x8bae8dbb6b1c89a5 expected 0x7cfe3892dd2e08a4
      #|xadd qword ptr [rdi + r9*2 - 0x4], r11 [4e0fc15c4ffc]: R11=0xd43d30fcfe8a56c8 expected 0x615b708167454af8; mem[0x10106]=0xd0 expected 0xc8
      #|cmpxchg8b qword ptr [rsi] [0fc70e]: RAX=0xc45811a8 expected 0xe5555cedc45811a8; RDX=0xf66c6d5b expected 0x4b20c1ddf66c6d5b
      #|cmpxchg16b xmmword ptr [rsi] [480fc70e]: RAX=0xf73de1ff expected 0xf73de1fff29e7a4d; RDX=0xf29e7a4d expected 0x8d6c2422ae43f31c
      #|lahf [9f]: RAX undefined, expected 0x870f
      #|x86: cases=174 lifted=167 agree=155 mismatch=12 failed=0
      #|xadd ax, cx [660fc1c8]: EAX=0x7ee0b922 expected 0x7ee03922; ECX=0xb7703922 expected 0xb7708000
      #|xadd eax, ebx [0fc1d8]: EAX=0xfc34197f expected 0xd0594a2f; EBX=0xd0594a2f expected 0xd42530b0
      #|xadd dword ptr [esi + ebx*4 + 0x8], ebx [0fc15c9e08]: EBX=0x80ecc4ea expected 0x80ecc4e3; mem[0x100a4]=0x7 expected 0xea
      #|cmpxchg8b qword ptr [esi] [0fc70e]: EAX=0x3e39a2ac expected 0x7302ed21; EDX=0x7302ed21 expected 0x3e39a2ac
    ),
  )
}

///|
test "x86: control" {
  inspect(
    family_report(lift_x86, "control"),
    content=(
      #|x86-64: cases=201 lifted=188 agree=188 mismatch=0 failed=0
      #|x86: cases=197 lifted=184 agree=184 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: string" {
  inspect(
    family_report(lift_x86, "string"),
    content=(
      #|x86-64: cases=132 lifted=120 agree=120 mismatch=0 failed=0
      #|x86: cases=99 lifted=90 agree=90 mismatch=0 failed=0
    ),
  )
}

///|
test "x86: sse" {
  inspect(
    family_report(lift_x86, "sse"),
    content=(
      #|x86-64: cases=527 lifted=364 agree=321 mismatch=43 failed=0
      #|pavgb xmm1, xmm10 [66410fe0ca]: XMM1=0x11674e11397046427d5573451300687a expected 0x11674e11397046427d5573451380687a
      #|pavgb xmm1, xmmword ptr [rsi] [660fe00e]: XMM1=0x10524352140f645a30704b283c680546 expected 0x90524352948fe4da3070cba8bc6885c6
      #|pavgw xmm7, xmm6 [660fe3fe]: XMM7=0x1b015a22044039e30b035c4a2b1b38d8 expected 0x9b015a228440b9e38b035c4aab1bb8d8
      #|pavgw xmm7, xmmword ptr [rsi] [660fe33e]: XMM7=0x3a5f248f359820607131794620272dc4 expected 0xba5fa48fb598a06071317946a027adc4
      #|pslld xmm0, xmm4 [660ff2c4]: XMM0=0x00000000cd8f60942180960e8dd361a8 expected 0x00000000000000000000000000000000
      #|pslld xmm0, xmmword ptr [rsi] [660ff206]: XMM0=0x51c213a70000000025efa52000000000 expected 0x00000000000000000000000000000000
      #|psllq xmm1, xmm3 [660ff3cb]: XMM1=0x231bab9f0cf80f684dfcb153dd086f60 expected 0x00000000000000000000000000000000
      #|psllq xmm1, xmmword ptr [rsi] [660ff30e]: XMM1=0xffffffffffffffff0000000000000000 expected 0x00000000000000000000000000000000
      #|psrld xmm6, xmm0 [660fd2f0]: XMM6=0x00000000000000008000800000000000 expected 0x00000000000000000000000000000000
      #|psrld xmm6, xmmword ptr [rsi] [660fd236]: XMM6=0x00000000ff9bad85a3ab04e34d595d90 expected 0x00000000000000000000000000000000
      #|psrlq xmm2, xmm7 [660fd3d7]: XMM2=0xffffffffffffffffffffffffffffffff expected 0x00000000000000000000000000000000
      #|psrlq xmm2, xmmword ptr [rsi] [660fd316]: XMM2=0x0000000000000000a1c35c00fefda6d4 expected 0x00000000000000000000000000000000
      #|psrad xmm1, xmm6 [660fe2ce]: XMM1=0x80008000800080008000800080008000 expected 0xffffffffffffffffffffffffffffffff
      #|psrad xmm1, xmmword ptr [rsi] [660fe20e]: XMM1=0x26e6a8dc8c022a5aa48d2b8600000000 expected 0x00000000ffffffffffffffff00000000
      #|pshufb xmm7, xmm4 [660f3800fc]: XMM7=0x0000b100000000f3650000a100000000 expected 0x00ddb100000000f365004ba10000bd00
      #|pshufb xmm7, xmmword ptr [rsi] [660f38003e]: XMM7=0x0000000000f370000000000000000036 expected 0x0095000000f370eaa9007b4400000036
      #|psllw xmm5, xmm6 [660ff1ee]: XMM5=0x317267d536d06aaaa4f8ad6a879c0000 expected 0x00000000000000000000000000000000
      #|pslld xmm5, xmm6 [660ff2ee]: XMM5=0xa5a6a04c243fa10f596d2abf00000000 expected 0x00000000000000000000000000000000
      #|psllq xmm3, xmm4 [660ff3dc]: XMM3=0x4d7598a311f98a7f459c74e400000000 expected 0x11f98a7f00000000459c74e400000000
      #|psrlw xmm1, xmm2 [660fd1ca]: XMM1=0x80008000800080008000800080000000 expected 0x00000000000000000000000000000000
      #|psrld xmm7, xmm8 [66410fd2f8]: XMM7=0xe2dbdbda73121ae8eb75a2d400000000 expected 0x00000000000000000000000000000000
      #|psrlq xmm5, xmm6 [660fd3ee]: XMM5=0x6702b4e9ad0dd99000004fb33588675b expected 0x0000ce0569d35a1b00004fb33588675b
      #|psraw xmm5, xmm6 [660fe1ee]: XMM5=0x63667196915826bba4ae0addaf4a0000 expected 0x00000000ffff0000ffff0000ffff0000
      #|psrad xmm1, xmm2 [660fe2ca]: XMM1=0x6598bc95110b9c78655b736a00000000 expected 0x00000000000000000000000000000000
      #|x86: cases=249 lifted=165 agree=143 mismatch=22 failed=0
      #|pavgb xmm0, xmm3 [660fe0c3]: XMM0=0x12782b237d2468221e094b303b61605c expected 0x92f8aba3fda4e8a29e89cbb0bbe1e0dc
      #|pavgb xmm0, xmmword ptr [esi] [660fe006]: XMM0=0x7d5d32250d1c034a7e64345e50182324 expected 0x7d5db2258d9c834a7e6434ded098a3a4
      #|pavgw xmm0, xmmword ptr [esi] [660fe306]: XMM0=0x35a920d15b2e6f537c776d4f75885112 expected 0xb5a9a0d15b2e6f537c776d4f75885112
      #|pslld xmm1, xmm4 [660ff2cc]: XMM1=0x00000000ea9cee930000000000000000 expected 0x00000000000000000000000000000000
      #|pslld xmm1, xmmword ptr [esi] [660ff20e]: XMM1=0xffffffff000000000000000000000000 expected 0x00000000000000000000000000000000
      #|psrld xmm7, xmmword ptr [esi] [660fd23e]: XMM7=0x33c89dd4000000006cb291b8253c1cc8 expected 0x00000000000000000000000000000000
      #|psrlq xmm3, xmm2 [660fd3da]: XMM3=0x9d40aa39a113c6600000000000000000 expected 0x00000000000000000000000000000000
      #|psrlq xmm3, xmmword ptr [esi] [660fd31e]: XMM3=0x193af8d60d948e090000000000000000 expected 0x00000000000000000000000000000000
      #|pshufb xmm4, xmmword ptr [esi] [660f380026]: XMM4=0x00b2990000000000db00db0083000000 expected 0x00b2990000db0000dbdbdb0083000078
      #|psllw xmm6, xmm7 [660ff1f7]: XMM6=0x80008000800080008000800080000000 expected 0x00000000000000000000000000000000
      #|pslld xmm7, xmm0 [660ff2f8]: XMM7=0xdb7cb357f5cf06cf5ff5478a811d0000 expected 0xb357000006cf0000478a0000811d0000
      #|psllq xmm7, xmm0 [660ff3f8]: XMM7=0x94720d1c7f818bba0000000000000000 expected 0x00000000000000000000000000000000
      #|psrlw xmm6, xmm7 [660fd1f7]: XMM6=0xe55eedc24b4b778a84c0884494cc0000 expected 0x00000000000000000000000000000000
    ),
  )
}

///|
test "x86: ssebasic" {
  inspect(
    family_report(lift_x86, "ssebasic"),
    content=(
      #|x86-64: cases=192 lifted=190 agree=166 mismatch=24 failed=0
      #|psrlwrr (660fd1c8) [660fd1c8]: XMM1=0x87423487ca697261c4315642ae490000 expected 0x00010000000100000001000000010000
      #|psrldrr (660fd2c8) [660fd2c8]: XMM1=0x83680c238956d0ba629c121e0000a8fb expected 0x00008368000089560000629c0000a8fb
      #|psrlqrr (660fd3c8) [660fd3c8]: XMM1=0x1850a031ed414f8d0000000000000000 expected 0x00000000000000000000000000000000
      #|pavgbrr (660fe0c8) [660fe0c8]: XMM1=0x416c6b6f0b4852505e6d085437531164 expected 0xc16c6b6f8bc8d250deed88d437539164
      #|pavgwrr (660fe3c8) [660fe3c8]: XMM1=0x545177f375c435d52bf1075e67794bcc expected 0xd45177f3f5c4b5d52bf1875e67794bcc
      #|psrawrr (660fe1c8) [660fe1c8]: XMM1=0x308f41b6f10955c2f0d3f209d73bffff expected 0x00000000ffff0000ffffffffffffffff
      #|psradrr (660fe2c8) [660fe2c8]: XMM1=0x6aa922409b258a46aaa9fe5d00000000 expected 0x00000000ffffffffffffffff00000000
      #|psllwrr (660ff1c8) [660ff1c8]: XMM1=0xc305f1005ba4c7509a58bd7494bf0000 expected 0x00000000000000000000000000000000
      #|pslldrr (660ff2c8) [660ff2c8]: XMM1=0xbfde0726afbbed09340bee934391e584 expected 0x7fbc0e4c5f77da126817dd264391e584
      #|psllqrr (660ff3c8) [660ff3c8]: XMM1=0xcf4156d7ada65d883cb4148f80000000 expected 0xd6d32ec4000000003cb4148f80000000
      #|pshufbrr (660f3800c1) [660f3800c1]: XMM0=0xbbb7bbf600000000000000ee0000cb00 expected 0xbbb7bbf600b7bb000000bbee0000cb4a
      #|movpqi2qirr (660fd6c1) [660fd6c1]: XMM1=0xd78dbba88a91674ef54271303cdba4b3 expected 0x0000000000000000f54271303cdba4b3
      #|pavgbrr (660fe0c1) [660fe0c1]: XMM0=0x160069174c34351c6b75023f56104c35 expected 0x968069974c34359c6b75823f5690ccb5
      #|x86: cases=96 lifted=95 agree=82 mismatch=13 failed=0
      #|psrlwrr (660fd1c8) [660fd1c8]: XMM1=0x01cef381ad4499f37de2000015d68ebb expected 0x00000000000000000000000000000000
      #|psrldrr (660fd2c8) [660fd2c8]: XMM1=0xfd4607441131d344c9b9d8390000fccc expected 0x0001fa8c00002263000193730000fccc
      #|psrlqrr (660fd3c8) [660fd3c8]: XMM1=0x0000000000000000283d3ad29a326437 expected 0x00000000000000000000000000000000
      #|pavgbrr (660fe0c8) [660fe0c8]: XMM1=0x465858016b77292a042b36112b5d1c22 expected 0xc65858816b77a9aa84abb691abdd9ca2
      #|pavgwrr (660fe3c8) [660fe3c8]: XMM1=0x351044b26a4a42db3bf81a4857664add expected 0xb51044b26a4a42dbbbf89a48d7664add
      #|psrawrr (660fe1c8) [660fe1c8]: XMM1=0x98e821ac7bd5f02b52a5b5b6b2faffff expected 0xffff00000000ffff0000ffffffffffff
      #|psradrr (660fe2c8) [660fe2c8]: XMM1=0x4d60c65e02e72343fffffffff60ca4f2 expected 0x0000000000000000ffffffffffffffff
      #|psllwrr (660ff1c8) [660ff1c8]: XMM1=0x5cb1e19ceafa7d88205f2b1acb6aef58 expected 0xb962c338d5f4fb1040be563496d4ef58
      #|pslldrr (660ff2c8) [660ff2c8]: XMM1=0x9bd582d1b5fffe2c324c9c93c18f0000 expected 0x82d10000fe2c00009c930000c18f0000
      #|psllqrr (660ff3c8) [660ff3c8]: XMM1=0xe19ac770373e62e84128425c99234998 expected 0x0cd63b81b9f317404128425c99234998
      #|pshufbrr (660f3800c1) [660f3800c1]: XMM0=0x25000007000000000000010000000000 expected 0x25d300070000000000000100004b00d3
      #|movpqi2qirr (660fd6c1) [660fd6c1]: XMM1=0x5960ceb40c7b90bd3ac41f4d0f119a6c expected 0x00000000000000003ac41f4d0f119a6c
      #|pavgbrr (660fe0c1) [660fe0c1]: XMM0=0x36360f3f505d29324266750743402931 expected 0xb6368fbfd05da9324266f587c3c0a9b1
    ),
  )
}
