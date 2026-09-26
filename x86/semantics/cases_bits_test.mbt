// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let bits64_cases : String =
  #|bt r15w, r13w|66450fa3ef|BT16rr:%R15W,%R13W|r13=c r15=4421df404e8a698c f=8c6|f=8c4/894
  #|bt r15w, r13w|66450fa3ef|BT16rr:%R15W,%R13W|r13=b6a31d24caba78a5 r15=34e9111ace13a41c f=417|f=414/894
  #|bt r15w, r13w|66450fa3ef|BT16rr:%R15W,%R13W|r13=91 r15=b2cb7c9bce94e309 f=443|f=440/894
  #|bt r15w, 11|66410fbae70b|BT16ri8:%R15W,11|r15=7fffffffffffffff f=43|f=41/894
  #|bt r15w, 19|66410fbae713|BT16ri8:%R15W,19|r15=d2c778807a9c7fff f=3|f=1/894
  #|bt r15w, 255|66410fbae7ff|BT16ri8:%R15W,255|r15=9308dd385414ae1d f=cc2|f=cc1/894
  #|bt word ptr [rdi + 0x10], dx|660fa35710|BT16mr:%RDI,1,%,16,%,%DX|rdx=34 f=c02 m10110=265abd8f97a60b8fec09a578c1b537b3|f=c00/894
  #|bt word ptr [rdi + 0x10], dx|660fa35710|BT16mr:%RDI,1,%,16,%,%DX|rdx=28 f=487 m10110=af4bfaa9790579f9fd13a1cd0e3cb1a6|f=485/894
  #|bt word ptr [rdi + 0x10], dx|660fa35710|BT16mr:%RDI,1,%,16,%,%DX|rdx=2f f=4d2 m10110=656aa31c09bd8ab2a576c831b12bb9e6|f=4d1/894
  #|bt word ptr [rdi + 0x10], dx|660fa35710|BT16mr:%RDI,1,%,16,%,%DX|rdx=f f=c97 m10110=d1ec29a6911dcfc4654a02e6e0a1025a|f=c95/894
  #|bt word ptr [rdi + 0x10], 0|660fba671000|BT16mi8:%RDI,1,%,16,%,0|f=802 m10110=3ea785fd4fe49993973d43606813a1d1|f=800/894
  #|bt word ptr [rdi + 0x10], 0|660fba671000|BT16mi8:%RDI,1,%,16,%,0|f=96 m10110=441dddcb946a295c68452b35b313f72c|f=94/894
  #|bt r13d, r15d|450fa3fd|BT32rr:%R13D,%R15D|r13=34a8746a0eb15731 r15=edbbe2063c371880 f=7|f=5/894
  #|bt r13d, r15d|450fa3fd|BT32rr:%R13D,%R15D|r13=de029d5d8aa491ae r15=ff f=407|f=405/894
  #|bt r13d, r15d|450fa3fd|BT32rr:%R13D,%R15D|r13=143b86545cf843b2 r15=ffffffffffffffff f=c52|f=c50/894
  #|bt r13d, 26|410fbae51a|BT32ri8:%R13D,26|r13=80000000 f=882|f=880/894
  #|bt r13d, 35|410fbae523|BT32ri8:%R13D,35|r13=202f1fdd37be8848 f=816|f=815/894
  #|bt r13d, 255|410fbae5ff|BT32ri8:%R13D,255|r13=7e f=d6|f=d4/894
  #|bt dword ptr [rdi + 0x10], r8d|440fa34710|BT32mr:%RDI,1,%,16,%,%R8D|r8=31 f=c53 m10110=0392a95bbfb4fd98ccaab500b21209d4|f=c50/894
  #|bt dword ptr [rdi + 0x10], r8d|440fa34710|BT32mr:%RDI,1,%,16,%,%R8D|r8=1b f=17 m10110=f95c29f2cad30579a78324a2f54e5f2a|f=14/894
  #|bt dword ptr [rdi + 0x10], r8d|440fa34710|BT32mr:%RDI,1,%,16,%,%R8D|r8=23 f=887 m10110=89a46d276a956a8232373469247eb9b1|f=885/894
  #|bt dword ptr [rdi + 0x10], r8d|440fa34710|BT32mr:%RDI,1,%,16,%,%R8D|r8=9 f=47 m10110=950287b0779a8228b2b709d2fd869a36|f=45/894
  #|bt dword ptr [rdi + 0x10], 40|0fba671028|BT32mi8:%RDI,1,%,16,%,40|f=816 m10110=879cbc514f8cd684fca3bd6b3e283d4f|f=814/894
  #|bt dword ptr [rdi + 0x10], 40|0fba671028|BT32mi8:%RDI,1,%,16,%,40|f=6 m10110=dcdf64614a528a37334ba06351c533b2|f=5/894
  #|bt r15, rcx|490fa3cf|BT64rr:%R15,%RCX|rcx=66 r15=87f61265a98f7715 f=d6|f=d5/894
  #|bt r15, rcx|490fa3cf|BT64rr:%R15,%RCX|rcx=b20e8cbe48896934 r15=ffffffff f=12|f=10/894
  #|bt r15, rcx|490fa3cf|BT64rr:%R15,%RCX|rcx=3fcfbeba851f2f00 r15=7f8a f=483|f=480/894
  #|bt r15, 42|490fbae72a|BT64ri8:%R15,42|r15=4059084d240797f7 f=92|f=90/894
  #|bt r15, 67|490fbae743|BT64ri8:%R15,67|r15=e882c0127fffffff f=87|f=85/894
  #|bt r15, 255|490fbae7ff|BT64ri8:%R15,255|r15=45ae56bf6bc82c35 f=8d2|f=8d0/894
  #|bt qword ptr [rdi + 0x10], r8|4c0fa34710|BT64mr:%RDI,1,%,16,%,%R8|r8=d f=82 m10110=8f87c1ba950d5877c5681f30228c3e60|f=80/894
  #|bt qword ptr [rdi + 0x10], r8|4c0fa34710|BT64mr:%RDI,1,%,16,%,%R8|r8=4 f=816 m10110=df1c79d1260f6792f6b0608bfd600eed|f=815/894
  #|bt qword ptr [rdi + 0x10], r8|4c0fa34710|BT64mr:%RDI,1,%,16,%,%R8|r8=20 f=97 m10110=db935bf9638b4fd54c3ec7eb94495a18|f=95/894
  #|bt qword ptr [rdi + 0x10], r8|4c0fa34710|BT64mr:%RDI,1,%,16,%,%R8|r8=1d f=c3 m10110=97486829dbfe6528cd110368a0f30c65|f=c1/894
  #|bt qword ptr [rdi + 0x10], 44|480fba67102c|BT64mi8:%RDI,1,%,16,%,44|f=847 m10110=268bc75bed5de0927c46e8b2daf74932|f=845/894
  #|bt qword ptr [rdi + 0x10], 44|480fba67102c|BT64mi8:%RDI,1,%,16,%,44|f=cc2 m10110=874344df02b7285f83611113169bdd17|f=cc1/894
  #|bts r11w, cx|66410fabcb|BTS16rr:%R11W,%R11W,%CX|rcx=a42b r11=fe2017811553075d f=4d6|r11=fe20178115530f5d f=4d4/894
  #|bts r11w, cx|66410fabcb|BTS16rr:%R11W,%R11W,%CX|rcx=3769508f2b73faae r11=4a4cc18d45c89b98 f=8d2|r11=4a4cc18d45c8db98 f=8d0/894
  #|bts r11w, cx|66410fabcb|BTS16rr:%R11W,%R11W,%CX|rcx=c9bf0a0139fddf8c r11=ff2d4544ffffffff f=852|f=851/894
  #|bts r11w, 3|66410fbaeb03|BTS16ri8:%R11W,%R11W,3|r11=f9d58810ea37ce7f f=13|f=11/894
  #|bts r11w, 19|66410fbaeb13|BTS16ri8:%R11W,%R11W,19|r11=3d43e787b53586f2 f=c2|r11=3d43e787b53586fa f=c0/894
  #|bts r11w, 255|66410fbaebff|BTS16ri8:%R11W,%R11W,255|r11=753dafeb20a7d75c f=cd7|f=cd5/894
  #|bts word ptr [rbp - 0x20], ax|660fab45e0|BTS16mr:%RBP,1,%,-32,%,%AX|rax=ffffffffffffffff f=47 m20160=e4ebc764a4d24f1a4faeb03746fcfb2c|f=45/894
  #|bts word ptr [rbp - 0x20], ax|660fab45e0|BTS16mr:%RBP,1,%,-32,%,%AX|rax=64 f=d3 m20160=e18c63caa9b95c8b98f42eb411746457|f=d1/894
  #|bts word ptr [rbp - 0x20], ax|660fab45e0|BTS16mr:%RBP,1,%,-32,%,%AX|rax=3d f=83 m20160=6c807e4a54c936776ea8c7f0b83b54bd|f=81/894
  #|bts word ptr [rbp - 0x20], ax|660fab45e0|BTS16mr:%RBP,1,%,-32,%,%AX|rax=24 f=8c3 m20160=b95e7f268a58a74c076fae42358aa738|f=8c0/894 m20164=9a
  #|bts word ptr [rbp - 0x20], 7|660fba6de007|BTS16mi8:%RBP,1,%,-32,%,7|f=86 m20160=afc8c457fe0c9b72fa24bcf55253594b|f=85/894
  #|bts word ptr [rbp - 0x20], 7|660fba6de007|BTS16mi8:%RBP,1,%,-32,%,7|f=806 m20160=1c5cde3a87076e10ce1963b6d3e871ee|f=804/894 m20160=9c
  #|bts r10d, r9d|450fabca|BTS32rr:%R10D,%R10D,%R9D|r9=e22b977572050c76 r10=1335981ee7407941 f=807|r10=e7407941 f=805/894
  #|bts r10d, r9d|450fabca|BTS32rr:%R10D,%R10D,%R9D|r9=ff r10=9da4ec7c8876c34f f=7|r10=8876c34f f=5/894
  #|bts r10d, r9d|450fabca|BTS32rr:%R10D,%R10D,%R9D|r9=5d4e4c1b5143a9ee r10=a5583532ef08617f f=416|r10=ef08617f f=415/894
  #|bts r10d, 12|410fbaea0c|BTS32ri8:%R10D,%R10D,12|r10=2c992597952e6533 f=896|r10=952e7533 f=894/894
  #|bts r10d, 35|410fbaea23|BTS32ri8:%R10D,%R10D,35|r10=d1f24edf560ad45b f=12|r10=560ad45b f=11/894
  #|bts r10d, 255|410fbaeaff|BTS32ri8:%R10D,%R10D,255|r10=2 f=896|r10=80000002 f=894/894
  #|bts dword ptr [rbp - 0x20], eax|0fab45e0|BTS32mr:%RBP,1,%,-32,%,%EAX|rax=1e f=6 m20160=a468d7d256008ef742ea24112d850aa5|f=5/894
  #|bts dword ptr [rbp - 0x20], eax|0fab45e0|BTS32mr:%RBP,1,%,-32,%,%EAX|rax=1d f=2 m20160=78aa46412b82b6e15a82caab25a95df5|f=0/894 m20163=61
  #|bts dword ptr [rbp - 0x20], eax|0fab45e0|BTS32mr:%RBP,1,%,-32,%,%EAX|rax=1a f=83 m20160=6bcb4f9b560f3a9f44496cd6062a3d05|f=80/894 m20163=9f
  #|bts dword ptr [rbp - 0x20], eax|0fab45e0|BTS32mr:%RBP,1,%,-32,%,%EAX|rax=f f=2 m20160=561e19fa6d6a84f1227b89834f4ce869|f=0/894 m20161=9e
  #|bts dword ptr [rbp - 0x20], 33|0fba6de021|BTS32mi8:%RBP,1,%,-32,%,33|f=817 m20160=eb15cc55edfb01e112c8879c00cbcf67|f=815/894
  #|bts dword ptr [rbp - 0x20], 33|0fba6de021|BTS32mi8:%RBP,1,%,-32,%,33|f=8d6 m20160=fe670859a2f88310972d0316fab253c5|f=8d5/894
  #|bts r11, r15|4d0fabfb|BTS64rr:%R11,%R11,%R15|r11=3ad0e036bd865c36 r15=26d8e4b8815b27ea f=c13|r11=3ad0e436bd865c36 f=c10/894
  #|bts r11, r15|4d0fabfb|BTS64rr:%R11,%R11,%R15|r11=5561b79815944f66 r15=d3 f=97|r11=5561b798159c4f66 f=94/894
  #|bts r11, r15|4d0fabfb|BTS64rr:%R11,%R11,%R15|r11=2624 r15=c6 f=846|r11=2664 f=844/894
  #|bts r11, 0|490fbaeb00|BTS64ri8:%R11,%R11,0|r11=f2 f=6|r11=f3 f=4/894
  #|bts r11, 67|490fbaeb43|BTS64ri8:%R11,%R11,67|r11=13777490d8b50d23 f=47|r11=13777490d8b50d2b f=44/894
  #|bts r11, 255|490fbaebff|BTS64ri8:%R11,%R11,255|r11=d9630ceeb3d8e296 f=c6|f=c5/894
  #|bts qword ptr [rdi + 0x10], rdx|480fab5710|BTS64mr:%RDI,1,%,16,%,%RDX|rdx=a f=813 m10110=042e5b59c3baa60c957b020461203e5e|f=811/894
  #|bts qword ptr [rdi + 0x10], rdx|480fab5710|BTS64mr:%RDI,1,%,16,%,%RDX|rdx=30 f=4d3 m10110=9572aa9fe3a981c2b8e4acdaf6438ae6|f=4d1/894
  #|bts qword ptr [rdi + 0x10], rdx|480fab5710|BTS64mr:%RDI,1,%,16,%,%RDX|rdx=2 f=806 m10110=18401113ca16eadbc53fa675f38f3679|f=804/894 m10110=1c
  #|bts qword ptr [rdi + 0x10], rdx|480fab5710|BTS64mr:%RDI,1,%,16,%,%RDX|rdx=e f=8d6 m10110=b5273b7220bfa5d2f77ebd4d7b5d0fc0|f=8d4/894 m10111=67
  #|bts qword ptr [rdi + 0x10], 15|480fba6f100f|BTS64mi8:%RDI,1,%,16,%,15|f=8d6 m10110=b040e71c14fc3026f5e0fe705fbdb81c|f=8d4/894 m10111=c0
  #|bts qword ptr [rdi + 0x10], 15|480fba6f100f|BTS64mi8:%RDI,1,%,16,%,15|f=816 m10110=62b60c1196456c76ffc7bd3bb9a64f14|f=815/894
  #|btr r12w, r13w|66450fb3ec|BTR16rr:%R12W,%R12W,%R13W|r12=34cef545414f7fff r13=fffffffffffffffe f=13|r12=34cef545414f3fff f=11/894
  #|btr r12w, r13w|66450fb3ec|BTR16rr:%R12W,%R12W,%R13W|r12=28148df82edeb48b r13=62b02dd64e1a6883 f=53|r12=28148df82edeb483 f=51/894
  #|btr r12w, r13w|66450fb3ec|BTR16rr:%R12W,%R12W,%R13W|r12=739e4c6bff14363b r13=c64b3bd5e4d00f7f f=487|f=484/894
  #|btr r12w, 11|66410fbaf40b|BTR16ri8:%R12W,%R12W,11|r12=d29e8f64bbc2ffff f=817|r12=d29e8f64bbc2f7ff f=815/894
  #|btr r12w, 19|66410fbaf413|BTR16ri8:%R12W,%R12W,19|r12=8f97290c0ef73080 f=56|f=54/894
  #|btr r12w, 255|66410fbaf4ff|BTR16ri8:%R12W,%R12W,255|r12=80000000 f=3|f=0/894
  #|btr word ptr [rdi + 0x10], ax|660fb34710|BTR16mr:%RDI,1,%,16,%,%AX|rax=0 f=c6 m10110=dbc7d27e821fc73ea2c04dff2f353fcc|f=c5/894 m10110=da
  #|btr word ptr [rdi + 0x10], ax|660fb34710|BTR16mr:%RDI,1,%,16,%,%AX|rax=23 f=56 m10110=0aaeb0b03952f6a7014933a6d2aeca17|f=55/894 m10114=31
  #|btr word ptr [rdi + 0x10], ax|660fb34710|BTR16mr:%RDI,1,%,16,%,%AX|rax=28 f=883 m10110=26455e14a2d3a2bfebe43ff25df99add|f=881/894 m10115=d2
  #|btr word ptr [rdi + 0x10], ax|660fb34710|BTR16mr:%RDI,1,%,16,%,%AX|rax=ffffffffffffffff f=802 m10110=cfbd0e2946ce33c7e712cd61127e04ed|f=800/894
  #|btr word ptr [rdi + 0x10], 13|660fba77100d|BTR16mi8:%RDI,1,%,16,%,13|f=8d6 m10110=9d8e1c92bd0cc23ba1c5d6616957de1b|f=8d4/894
  #|btr word ptr [rdi + 0x10], 13|660fba77100d|BTR16mi8:%RDI,1,%,16,%,13|f=883 m10110=01388250f0f0372bf87f310474de1b26|f=881/894 m10111=18
  #|btr r13d, eax|410fb3c5|BTR32rr:%R13D,%R13D,%EAX|rax=c7 r13=6 f=843|f=840/894
  #|btr r13d, eax|410fb3c5|BTR32rr:%R13D,%R13D,%EAX|rax=4db6218a8449d8ec r13=e722f48537b872be f=896|r13=37b862be f=895/894
  #|btr r13d, eax|410fb3c5|BTR32rr:%R13D,%R13D,%EAX|rax=ff r13=89e847b47e018fed f=843|r13=7e018fed f=840/894
  #|btr r13d, 30|410fbaf51e|BTR32ri8:%R13D,%R13D,30|r13=1cdba1eb308523cf f=92|r13=308523cf f=90/894
  #|btr r13d, 35|410fbaf523|BTR32ri8:%R13D,%R13D,35|r13=2010603723782cb0 f=407|r13=23782cb0 f=404/894
  #|btr r13d, 255|410fbaf5ff|BTR32ri8:%R13D,%R13D,255|r13=6b4fdc388d258402 f=c7|r13=d258402 f=c5/894
  #|btr dword ptr [rsi], r8d|440fb306|BTR32mr:%RSI,1,%,0,%,%R8D|r8=22 f=82 m10080=99c902d85e80c98557a79ffb0308aa21|f=81/894 m10084=5a
  #|btr dword ptr [rsi], r8d|440fb306|BTR32mr:%RSI,1,%,0,%,%R8D|r8=28 f=c7 m10080=8810bdeeb4da1f25a881859880e1e33c|f=c4/894
  #|btr dword ptr [rsi], r8d|440fb306|BTR32mr:%RSI,1,%,0,%,%R8D|r8=1c f=42 m10080=0f2bcfb9bd74b4c1da5e06dc4cf5819d|f=41/894 m10083=a9
  #|btr dword ptr [rsi], r8d|440fb306|BTR32mr:%RSI,1,%,0,%,%R8D|r8=11 f=46 m10080=b71c349ecf0562bf6a8b6106c5954276|f=44/894
  #|btr dword ptr [rsi], 37|0fba3625|BTR32mi8:%RSI,1,%,0,%,37|f=53 m10080=f934520b7ef601d15420615e6b5a33b1|f=51/894 m10080=d9
  #|btr dword ptr [rsi], 37|0fba3625|BTR32mi8:%RSI,1,%,0,%,37|f=52 m10080=ec88b800d6538c714b01efb3d25a9bc3|f=51/894 m10080=cc
  #|btr r14, r15|4d0fb3fe|BTR64rr:%R14,%R14,%R15|r14=3 r15=20 f=8c2|f=8c0/894
  #|btr r14, r15|4d0fb3fe|BTR64rr:%R14,%R14,%R15|r14=8d r15=7fffffff f=c97|f=c94/894
  #|btr r14, r15|4d0fb3fe|BTR64rr:%R14,%R14,%R15|r14=b0d85b12c1defa74 r15=51c4361bb3d148d3 f=8d3|r14=b0d85b12c1d6fa74 f=8d1/894
  #|btr r14, 61|490fbaf63d|BTR64ri8:%R14,%R14,61|r14=6a9cd60263b1dd71 f=8c3|r14=4a9cd60263b1dd71 f=8c1/894
  #|btr r14, 67|490fbaf643|BTR64ri8:%R14,%R14,67|r14=27fad9e8bdf14085 f=c7|f=c4/894
  #|btr r14, 255|490fbaf6ff|BTR64ri8:%R14,%R14,255|r14=5e47be04ef3a8000 f=d6|f=d4/894
  #|btr qword ptr [rdi + 0x10], rax|480fb34710|BTR64mr:%RDI,1,%,16,%,%RAX|rax=34 f=c92 m10110=8934632ea6c6690f8655f0cdea661da7|f=c90/894
  #|btr qword ptr [rdi + 0x10], rax|480fb34710|BTR64mr:%RDI,1,%,16,%,%RAX|rax=9 f=2 m10110=73bc7f6a594bfa38b00d0e3e2c9f73db|f=0/894
  #|btr qword ptr [rdi + 0x10], rax|480fb34710|BTR64mr:%RDI,1,%,16,%,%RAX|rax=2d f=8d6 m10110=633893b3507fc8318e6e1ff590dcfae3|f=8d5/894 m10115=5f
  #|btr qword ptr [rdi + 0x10], rax|480fb34710|BTR64mr:%RDI,1,%,16,%,%RAX|rax=27 f=2 m10110=dbb9cbc4cfc64472405ed38bf31f8ec9|f=1/894 m10114=4f
  #|btr qword ptr [rdi + 0x10], 39|480fba771027|BTR64mi8:%RDI,1,%,16,%,39|f=c46 m10110=8c307234d473f04483f7958812d00a33|f=c45/894 m10114=54
  #|btr qword ptr [rdi + 0x10], 39|480fba771027|BTR64mi8:%RDI,1,%,16,%,39|f=42 m10110=766bb03b9ce132cba6d5142be5394743|f=41/894 m10114=1c
  #|btc r13w, ax|66410fbbc5|BTC16rr:%R13W,%R13W,%AX|rax=9904de8fa1879422 r13=3ebfbfd173fdd87a f=4c3|r13=3ebfbfd173fdd87e f=4c0/894
  #|btc r13w, ax|66410fbbc5|BTC16rr:%R13W,%R13W,%AX|rax=e840db23d1a3287b r13=ffffffff f=456|r13=fffff7ff f=455/894
  #|btc r13w, ax|66410fbbc5|BTC16rr:%R13W,%R13W,%AX|rax=bc8173e59d340f55 r13=8df0418b528191d2 f=892|r13=8df0418b528191f2 f=890/894
  #|btc r13w, 0|66410fbafd00|BTC16ri8:%R13W,%R13W,0|r13=3 f=802|r13=2 f=801/894
  #|btc r13w, 19|66410fbafd13|BTC16ri8:%R13W,%R13W,19|r13=ec f=17|r13=e4 f=15/894
  #|btc r13w, 255|66410fbafdff|BTC16ri8:%R13W,%R13W,255|r13=580aa0a2ffffffff f=8c2|r13=580aa0a2ffff7fff f=8c1/894
  #|btc word ptr [rsi], r8w|66440fbb06|BTC16mr:%RSI,1,%,0,%,%R8W|r8=1d f=813 m10080=d057282945aa45989e42d3392ca5966f|f=811/894 m10083=09
  #|btc word ptr [rsi], r8w|66440fbb06|BTC16mr:%RSI,1,%,0,%,%R8W|r8=d f=c6 m10080=0c700e587c496049281bc1911a3fafae|f=c5/894 m10081=50
  #|btc word ptr [rsi], r8w|66440fbb06|BTC16mr:%RSI,1,%,0,%,%R8W|r8=14 f=852 m10080=2082cdd1f2dee7c2d6dad17905a559a3|f=850/894 m10082=dd
  #|btc word ptr [rsi], r8w|66440fbb06|BTC16mr:%RSI,1,%,0,%,%R8W|r8=2c f=893 m10080=ad8a1a19d609d83cf12b1a9384271ed0|f=890/894 m10085=19
  #|btc word ptr [rsi], 5|660fba3e05|BTC16mi8:%RSI,1,%,0,%,5|f=d2 m10080=d68831c6c3a6df0c229c4d61f287e387|f=d0/894 m10080=f6
  #|btc word ptr [rsi], 5|660fba3e05|BTC16mi8:%RSI,1,%,0,%,5|f=896 m10080=c8c3dbae68932405997112040d491edc|f=894/894 m10080=e8
  #|btc r8d, eax|410fbbc0|BTC32rr:%R8D,%R8D,%EAX|rax=27bcace2f2ca5570 r8=d37fcec9364afb8e f=812|r8=364bfb8e f=810/894
  #|btc r8d, eax|410fbbc0|BTC32rr:%R8D,%R8D,%EAX|rax=85 r8=ef2fe36517f31d27 f=842|r8=17f31d07 f=841/894
  #|btc r8d, eax|410fbbc0|BTC32rr:%R8D,%R8D,%EAX|rax=dffd7efb29feedf0 r8=fffffffffffffffe f=c3|r8=fffefffe f=c1/894
  #|btc r8d, 19|410fbaf813|BTC32ri8:%R8D,%R8D,19|r8=ea6fc08f7e6cef3d f=492|r8=7e64ef3d f=491/894
  #|btc r8d, 35|410fbaf823|BTC32ri8:%R8D,%R8D,35|r8=11be559a046fbdcb f=856|r8=46fbdc3 f=855/894
  #|btc r8d, 255|410fbaf8ff|BTC32ri8:%R8D,%R8D,255|r8=80e29a7f8956527d f=12|r8=956527d f=11/894
  #|btc dword ptr [rbp - 0x20], r8d|440fbb45e0|BTC32mr:%RBP,1,%,-32,%,%R8D|r8=17 f=897 m20160=e67d426eb599419328c8002aad3cc01b|f=894/894 m20162=c2
  #|btc dword ptr [rbp - 0x20], r8d|440fbb45e0|BTC32mr:%RBP,1,%,-32,%,%R8D|r8=18 f=896 m20160=6fc4a230fe410fe1a703a8bfcebd6e1e|f=894/894 m20163=31
  #|btc dword ptr [rbp - 0x20], r8d|440fbb45e0|BTC32mr:%RBP,1,%,-32,%,%R8D|r8=3d f=817 m20160=460b03bbc971c32d8071df4c32969186|f=815/894 m20167=0d
  #|btc dword ptr [rbp - 0x20], r8d|440fbb45e0|BTC32mr:%RBP,1,%,-32,%,%R8D|r8=13 f=12 m20160=b8aa90fc3d071f06ce2306ba555c0aeb|f=10/894 m20162=98
  #|btc dword ptr [rbp - 0x20], 31|0fba7de01f|BTC32mi8:%RBP,1,%,-32,%,31|f=8c3 m20160=91fee3df3ec770ae633edef896c3b9f7|f=8c1/894 m20163=5f
  #|btc dword ptr [rbp - 0x20], 31|0fba7de01f|BTC32mi8:%RBP,1,%,-32,%,31|f=443 m20160=001863aae205700852fbc7d804938761|f=441/894 m20163=2a
  #|btc r13, r14|4d0fbbf5|BTC64rr:%R13,%R13,%R14|r13=fffffffffffffffe r14=48 f=807|r13=fffffffffffffefe f=805/894
  #|btc r13, r14|4d0fbbf5|BTC64rr:%R13,%R13,%R14|r13=1 r14=fffffffffffffffe f=92|r13=4000000000000001 f=90/894
  #|btc r13, r14|4d0fbbf5|BTC64rr:%R13,%R13,%R14|r13=7ba05adc447d1816 r14=7f f=442|r13=fba05adc447d1816 f=440/894
  #|btc r13, 46|490fbafd2e|BTC64ri8:%R13,%R13,46|r13=d202c9408aa7611f f=4c7|r13=d20289408aa7611f f=4c5/894
  #|btc r13, 67|490fbafd43|BTC64ri8:%R13,%R13,67|r13=8000000000000000 f=56|r13=8000000000000008 f=54/894
  #|btc r13, 255|490fbafdff|BTC64ri8:%R13,%R13,255|r13=8b89e2ba04957d03 f=857|r13=b89e2ba04957d03 f=855/894
  #|btc qword ptr [rbp - 0x20], r8|4c0fbb45e0|BTC64mr:%RBP,1,%,-32,%,%R8|r8=32 f=93 m20160=362be46668038888608dae223eb11550|f=90/894 m20166=8c
  #|btc qword ptr [rbp - 0x20], r8|4c0fbb45e0|BTC64mr:%RBP,1,%,-32,%,%R8|r8=a f=2 m20160=efe257fe5954ae664de759d0d4b63a55|f=0/894 m20161=e6
  #|btc qword ptr [rbp - 0x20], r8|4c0fbb45e0|BTC64mr:%RBP,1,%,-32,%,%R8|r8=2 f=896 m20160=444c5086e2c0be225f1c5431c423d569|f=895/894 m20160=40
  #|btc qword ptr [rbp - 0x20], r8|4c0fbb45e0|BTC64mr:%RBP,1,%,-32,%,%R8|r8=2f f=892 m20160=22310d3139db7d070473dea23519d5bc|f=891/894 m20165=5b
  #|btc qword ptr [rbp - 0x20], 29|480fba7de01d|BTC64mi8:%RBP,1,%,-32,%,29|f=896 m20160=ac9694422eeefcfb7e32bfda27f62118|f=894/894 m20163=62
  #|btc qword ptr [rbp - 0x20], 29|480fba7de01d|BTC64mi8:%RBP,1,%,-32,%,29|f=82 m20160=ce81b38d98a919bcdde1fa2ea0e18a63|f=80/894 m20163=ad
  #|bsf r8w, r12w|66450fbcc4|BSF16rr:%R8W,%R8W,%R12W|r8=abcae8fac4c6ce95 r12=8000000000000000 f=806|r8=? f=44/895
  #|bsf r8w, r12w|66450fbcc4|BSF16rr:%R8W,%R8W,%R12W|r8=8000000000000000 r12=ffff f=97|f=84/895
  #|bsf r8w, r12w|66450fbcc4|BSF16rr:%R8W,%R8W,%R12W|r8=9e4bea9411eb96ae r12=4579a16d0bb668a0 f=887|r8=9e4bea9411eb0005 f=4/895
  #|bsf r8w, r12w|66450fbcc4|BSF16rr:%R8W,%R8W,%R12W|r8=a4 r12=9a24b7c993aa30e6 f=4d6|r8=1 f=400/895
  #|bsf r8w, word ptr [rsi]|66440fbc06|BSF16rm:%R8W,%R8W,%RSI,1,%,0,%|r8=dd39c2603f787f56 f=857 m10080=271d9ac94b140f022068e2a583339963|r8=dd39c2603f780000 f=4/895
  #|bsf r8w, word ptr [rsi]|66440fbc06|BSF16rm:%R8W,%R8W,%RSI,1,%,0,%|r8=ffd45eab69a70de3 f=806 m10080=65745c558924032fbc16157b3ce5f808|r8=ffd45eab69a70000 f=4/895
  #|bsf r10d, eax|440fbcd0|BSF32rr:%R10D,%R10D,%EAX|rax=7adcdaff00000000 r10=2e f=c7|r10=? f=44/895
  #|bsf r10d, eax|440fbcd0|BSF32rr:%R10D,%R10D,%EAX|rax=49b7156230824d9f r10=7e14007f63eb629b f=802|r10=0 f=4/895
  #|bsf r10d, eax|440fbcd0|BSF32rr:%R10D,%R10D,%EAX|rax=0 r10=5d9b700b83fffcff f=8c2|r10=? f=44/895
  #|bsf r10d, eax|440fbcd0|BSF32rr:%R10D,%R10D,%EAX|rax=ffffffffffffffff r10=57d349ffec796b3d f=887|r10=0 f=84/895
  #|bsf r10d, dword ptr [rdi + 0x10]|440fbc5710|BSF32rm:%R10D,%R10D,%RDI,1,%,16,%|r10=f703c0f96451b6ac f=c2 m10110=ea106f447d97fa64f155073d5bb2d5d9|r10=1 f=0/895
  #|bsf r10d, dword ptr [rdi + 0x10]|440fbc5710|BSF32rm:%R10D,%R10D,%RDI,1,%,16,%|r10=80000000 f=2 m10110=42a0921b064dd2f1652bcf6f49e73d0d|r10=1 f=4/895
  #|bsf rbx, r14|490fbcde|BSF64rr:%RBX,%RBX,%R14|rbx=9f8aea0f3dc68000 r14=a f=86|rbx=1 f=4/895
  #|bsf rbx, r14|490fbcde|BSF64rr:%RBX,%RBX,%R14|rbx=792b3b0840fef091 r14=dccb8877a0e1a01f f=92|rbx=0 f=80/895
  #|bsf rbx, r14|490fbcde|BSF64rr:%RBX,%RBX,%R14|rbx=269a5cbf530ab670 r14=0 f=483|rbx=? f=444/895
  #|bsf rbx, r14|490fbcde|BSF64rr:%RBX,%RBX,%R14|rbx=1aa78141011787ff r14=8090c8226fb85aa4 f=897|rbx=2 f=80/895
  #|bsf rbx, qword ptr [rdi + 0x10]|480fbc5f10|BSF64rm:%RBX,%RBX,%RDI,1,%,16,%|rbx=2079c370fab63de5 f=d2 m10110=4f6c313cae0037803a11de8d1320c2b7|rbx=0 f=80/895
  #|bsf rbx, qword ptr [rdi + 0x10]|480fbc5f10|BSF64rm:%RBX,%RBX,%RDI,1,%,16,%|rbx=297d9381ce14bc6 f=807 m10110=c9c692b05ca397ad423281762c56c001|rbx=0 f=84/895
  #|bsr r8w, cx|66440fbdc1|BSR16rr:%R8W,%R8W,%CX|rcx=b9f79e1f9b120000 r8=dafa11983af2ffff f=8d2|r8=? f=44/895
  #|bsr r8w, cx|66440fbdc1|BSR16rr:%R8W,%R8W,%CX|rcx=8000000000000000 r8=2e729960b211f87f f=843|r8=? f=44/895
  #|bsr r8w, cx|66440fbdc1|BSR16rr:%R8W,%R8W,%CX|rcx=9a4e2c65bff19142 r8=d6619691e88e4cc1 f=92|r8=d6619691e88e000f f=84/895
  #|bsr r8w, cx|66440fbdc1|BSR16rr:%R8W,%R8W,%CX|rcx=db94e20e6f370000 r8=2602165f1d859791 f=443|r8=? f=444/895
  #|bsr r8w, word ptr [rbp - 0x20]|66440fbd45e0|BSR16rm:%R8W,%R8W,%RBP,1,%,-32,%|r8=3ff31a29b7b18bdd f=897 m20160=d213e632aee4e6b2547843c565f8fdb8|r8=3ff31a29b7b1000c f=4/895
  #|bsr r8w, word ptr [rbp - 0x20]|66440fbd45e0|BSR16rm:%R8W,%R8W,%RBP,1,%,-32,%|r8=2a f=853 m20160=a4c05278321afbeccf36324eb48e0db7|r8=f f=80/895
  #|bsr r11d, r14d|450fbdde|BSR32rr:%R11D,%R11D,%R14D|r11=7fff r14=6365650925667165 f=c87|r11=1d f=404/895
  #|bsr r11d, r14d|450fbdde|BSR32rr:%R11D,%R11D,%R14D|r11=23 r14=15603ac359caa895 f=c02|r11=1e f=404/895
  #|bsr r11d, r14d|450fbdde|BSR32rr:%R11D,%R11D,%R14D|r11=363c8dcb352f8fa8 r14=2d f=816|r11=5 f=4/895
  #|bsr r11d, r14d|450fbdde|BSR32rr:%R11D,%R11D,%R14D|r11=8000000000000000 r14=16c1875a00000000 f=8d6|r11=? f=44/895
  #|bsr r11d, dword ptr [rsi]|440fbd1e|BSR32rm:%R11D,%R11D,%RSI,1,%,0,%|r11=ffffffffffffffff f=816 m10080=42f36641df29f1f786acc8fe9b6b2384|r11=1e f=4/895
  #|bsr r11d, dword ptr [rsi]|440fbd1e|BSR32rm:%R11D,%R11D,%RSI,1,%,0,%|r11=d f=812 m10080=39dfded894b0ce78ec2dcd040d174c79|r11=1f f=84/895
  #|bsr r8, r14|4d0fbdc6|BSR64rr:%R8,%R8,%R14|r8=43f38feef3a0150e r14=a65efec20453db54 f=86|r8=3f f=80/895
  #|bsr r8, r14|4d0fbdc6|BSR64rr:%R8,%R8,%R14|r8=1bb2924e4b97947 r14=9884a65159461c55 f=2|r8=3f f=84/895
  #|bsr r8, r14|4d0fbdc6|BSR64rr:%R8,%R8,%R14|r8=b45d052a3ae7bfe0 r14=2 f=8d6|r8=1 f=0/895
  #|bsr r8, r14|4d0fbdc6|BSR64rr:%R8,%R8,%R14|r8=1 r14=645d875d6757d515 f=842|r8=3e f=0/895
  #|bsr r8, qword ptr [rdi + 0x10]|4c0fbd4710|BSR64rm:%R8,%R8,%RDI,1,%,16,%|r8=f f=7 m10110=a518fafbfa4132b7f27a57dca3a1411d|r8=3f f=84/895
  #|bsr r8, qword ptr [rdi + 0x10]|4c0fbd4710|BSR64rm:%R8,%R8,%RDI,1,%,16,%|r8=b18492584c17a710 f=17 m10110=692e38cc20e0f6b8586165f1da005ea3|r8=3f f=84/895
  #|lzcnt r13w, ax|66f3440fbde8|LZCNT16rr:%R13W,%AX|rax=6895b25d73816508 r13=ae5170cf96f1fee9 f=93|r13=ae5170cf96f10001 f=0/894
  #|lzcnt r13w, ax|66f3440fbde8|LZCNT16rr:%R13W,%AX|rax=c7d8d8b96a40f634 r13=ff f=17|r13=0 f=40/894
  #|lzcnt r13w, ax|66f3440fbde8|LZCNT16rr:%R13W,%AX|rax=39625c09e3a88000 r13=1a42503d576bb968 f=96|r13=1a42503d576b0000 f=40/894
  #|lzcnt r13w, word ptr [rbp - 0x20]|66f3440fbd6de0|LZCNT16rm:%R13W,%RBP,1,%,-32,%|r13=3b09ba350d4846f9 f=c12 m20160=e01da698c44b83574f3a2ede79041fce|r13=3b09ba350d480003 f=400/894
  #|lzcnt r13w, word ptr [rbp - 0x20]|66f3440fbd6de0|LZCNT16rm:%R13W,%RBP,1,%,-32,%|r13=1f76a0ba6df19c5d f=c2 m20160=1305d31a24befd93e400bdc0e39c8e49|r13=1f76a0ba6df10005 f=0/894
  #|lzcnt r9d, eax|f3440fbdc8|LZCNT32rr:%R9D,%EAX|rax=7fff r9=fef14458851327e9 f=883|r9=11 f=0/894
  #|lzcnt r9d, eax|f3440fbdc8|LZCNT32rr:%R9D,%EAX|rax=c r9=8e976df527e77fff f=57|r9=1c f=0/894
  #|lzcnt r9d, eax|f3440fbdc8|LZCNT32rr:%R9D,%EAX|rax=ffffffffffffffff r9=d06dd2018e58cc2 f=8d3|r9=0 f=40/894
  #|lzcnt r9d, dword ptr [rdi + 0x10]|f3440fbd4f10|LZCNT32rm:%R9D,%RDI,1,%,16,%|r9=89e0dac9e24984fe f=c97 m10110=fde1ab1e9a3bf1cc19d5ac093e3dbad3|r9=3 f=400/894
  #|lzcnt r9d, dword ptr [rdi + 0x10]|f3440fbd4f10|LZCNT32rm:%R9D,%RDI,1,%,16,%|r9=94cbea292156cb9d f=c42 m10110=0d359dba891429d46679dcb1ff46a420|r9=0 f=440/894
  #|lzcnt rax, r9|f3490fbdc1|LZCNT64rr:%RAX,%R9|rax=33ee83fb0a0e20ff r9=2 f=c07|rax=3e f=400/894
  #|lzcnt rax, r9|f3490fbdc1|LZCNT64rr:%RAX,%R9|rax=b3737af0a5c3cb4 r9=0 f=93|rax=40 f=1/894
  #|lzcnt rax, r9|f3490fbdc1|LZCNT64rr:%RAX,%R9|rax=b r9=3a9576029f8caaa0 f=816|rax=2 f=0/894
  #|lzcnt rax, qword ptr [rsi]|f3480fbd06|LZCNT64rm:%RAX,%RSI,1,%,0,%|rax=5162aae6013b435b f=853 m10080=b778727ca7c36288bfcc6036a2d1497b|rax=0 f=40/894
  #|lzcnt rax, qword ptr [rsi]|f3480fbd06|LZCNT64rm:%RAX,%RSI,1,%,0,%|rax=9e40f60a18408000 f=c42 m10080=7cef31992db0a850106a8c6a37fc8722|rax=1 f=400/894
  #|tzcnt r13w, r14w|66f3450fbcee|TZCNT16rr:%R13W,%R14W|r13=ef322d20ca87464d r14=7fffffffffffffff f=86|r13=ef322d20ca870000 f=40/894
  #|tzcnt r13w, r14w|66f3450fbcee|TZCNT16rr:%R13W,%R14W|r13=4bcb r14=0 f=c7|r13=10 f=1/894
  #|tzcnt r13w, r14w|66f3450fbcee|TZCNT16rr:%R13W,%R14W|r13=6464 r14=b9cf178f307c0000 f=857|r13=10 f=1/894
  #|tzcnt r13w, word ptr [rsi]|66f3440fbc2e|TZCNT16rm:%R13W,%RSI,1,%,0,%|r13=5d3698fa3a947813 f=c86 m10080=611de36e09ce06bfbc491fe1346bcabb|r13=5d3698fa3a940000 f=440/894
  #|tzcnt r13w, word ptr [rsi]|66f3440fbc2e|TZCNT16rm:%R13W,%RSI,1,%,0,%|r13=5aea8caffdd2363e f=c13 m10080=48f71eb9d832144c718c57ab5dd980dd|r13=5aea8caffdd20003 f=400/894
  #|tzcnt r8d, r13d|f3450fbcc5|TZCNT32rr:%R8D,%R13D|r8=a0110e97af455bee r13=603eaa18b3b5f955 f=c46|r8=0 f=440/894
  #|tzcnt r8d, r13d|f3450fbcc5|TZCNT32rr:%R8D,%R13D|r8=2bee16161e69267d r13=3ed1e42900000000 f=883|r8=20 f=1/894
  #|tzcnt r8d, r13d|f3450fbcc5|TZCNT32rr:%R8D,%R13D|r8=5bb862737ec83278 r13=286385f800000000 f=857|r8=20 f=1/894
  #|tzcnt r8d, dword ptr [rsi]|f3440fbc06|TZCNT32rm:%R8D,%RSI,1,%,0,%|r8=4019ce2d33d3ba38 f=853 m10080=9ae84b54683dedac7ea1dbbcd850ebb2|r8=1 f=0/894
  #|tzcnt r8d, dword ptr [rsi]|f3440fbc06|TZCNT32rm:%R8D,%RSI,1,%,0,%|r8=9b2e6c1a90d03193 f=882 m10080=4446cc0847a39100b5b1d7d886651861|r8=2 f=0/894
  #|tzcnt rcx, rax|f3480fbcc8|TZCNT64rr:%RCX,%RAX|rax=0 rcx=d61df884f2eefa3a f=c57|rcx=40 f=401/894
  #|tzcnt rcx, rax|f3480fbcc8|TZCNT64rr:%RCX,%RAX|rax=2039a70e0575815f rcx=8000000000000000 f=812|rcx=0 f=40/894
  #|tzcnt rcx, rax|f3480fbcc8|TZCNT64rr:%RCX,%RAX|rax=605c49f6379d4065 rcx=6936 f=493|rcx=0 f=440/894
  #|tzcnt rcx, qword ptr [rsi]|f3480fbc0e|TZCNT64rm:%RCX,%RSI,1,%,0,%|rcx=6 f=43 m10080=4dee828c6b8c6c9f963c15db446a0ded|rcx=0 f=40/894
  #|tzcnt rcx, qword ptr [rsi]|f3480fbc0e|TZCNT64rm:%RCX,%RSI,1,%,0,%|rcx=7f f=cc2 m10080=692c18853239f0daa1428917ff33f09e|rcx=0 f=440/894
  #|popcnt ax, r9w|66f3410fb8c1|POPCNT16rr:%AX,%R9W|rax=4907b2db999a78e3 r9=7fffffffffff0000 f=446|rax=4907b2db999a0000 f=440/0
  #|popcnt ax, r9w|66f3410fb8c1|POPCNT16rr:%AX,%R9W|rax=59a1b6771ca3a415 r9=4d f=cd6|rax=59a1b6771ca30004 f=400/0
  #|popcnt ax, r9w|66f3410fb8c1|POPCNT16rr:%AX,%R9W|rax=848cb94179374f5b r9=8000000000000000 f=83|rax=848cb94179370000 f=40/0
  #|popcnt ax, word ptr [rbp - 0x20]|66f30fb845e0|POPCNT16rm:%AX,%RBP,1,%,-32,%|rax=cf030f93edd284b1 f=d2 m20160=ff2827a4a2ee42151814acd4eb7fd1d1|rax=cf030f93edd2000a f=0/0
  #|popcnt ax, word ptr [rbp - 0x20]|66f30fb845e0|POPCNT16rm:%AX,%RBP,1,%,-32,%|rax=d54fadbe05a7eed8 f=882 m20160=859b3e82e0f171282c03f75a25df62a8|rax=d54fadbe05a70008 f=0/0
  #|popcnt r10d, ebx|f3440fb8d3|POPCNT32rr:%R10D,%EBX|rbx=96c3e00b95ec0edc r10=2 f=842|r10=11 f=0/0
  #|popcnt r10d, ebx|f3440fb8d3|POPCNT32rr:%R10D,%EBX|rbx=8822bef5ef46842b r10=6afa7984be37713e f=c93|r10=10 f=400/0
  #|popcnt r10d, ebx|f3440fb8d3|POPCNT32rr:%R10D,%EBX|rbx=785e16f2177efd39 r10=9b3a2e48d2413d77 f=d3|r10=15 f=0/0
  #|popcnt r10d, dword ptr [rdi + 0x10]|f3440fb85710|POPCNT32rm:%R10D,%RDI,1,%,16,%|r10=47d898f11aa13a90 f=d7 m10110=7bbd07b477f8fd08f0305a82d4941f8c|r10=13 f=0/0
  #|popcnt r10d, dword ptr [rdi + 0x10]|f3440fb85710|POPCNT32rm:%R10D,%RDI,1,%,16,%|r10=6ba0c51a0cad6080 f=56 m10110=8293111269fcb2df3b8a6628cc5e328a|r10=a f=0/0
  #|popcnt r13, rdx|f34c0fb8ea|POPCNT64rr:%R13,%RDX|rdx=912c9df5c9c43246 r13=6d14b9448fec3717 f=c7|r13=1e f=0/0
  #|popcnt r13, rdx|f34c0fb8ea|POPCNT64rr:%R13,%RDX|rdx=29181ee8ffffffff r13=d799bfeffffffff f=46|r13=2d f=0/0
  #|popcnt r13, rdx|f34c0fb8ea|POPCNT64rr:%R13,%RDX|rdx=596b r13=c998e56882656195 f=496|r13=9 f=400/0
  #|popcnt r13, qword ptr [rdi + 0x10]|f34c0fb86f10|POPCNT64rm:%R13,%RDI,1,%,16,%|r13=b70bbcf0ffffffff f=86 m10110=f8e346591a5a2bbd3e42b5f0b13ad742|r13=22 f=0/0
  #|popcnt r13, qword ptr [rdi + 0x10]|f34c0fb86f10|POPCNT64rm:%R13,%RDI,1,%,16,%|r13=6c3b10f9e627129b f=8d6 m10110=4bf97ac276fbbbb215b7758fcc9cab17|r13=28 f=0/0
  #|bswap eax|0fc8|BSWAP32r:%EAX,%EAX|rax=642885ba867908f7 f=93|rax=f7087986 f=91/0
  #|bswap eax|0fc8|BSWAP32r:%EAX,%EAX|rax=e6cfb5e33a392ed1 f=16|rax=d12e393a f=14/0
  #|bswap ecx|0fc9|BSWAP32r:%ECX,%ECX|rcx=8f5c f=53|rcx=5c8f0000 f=51/0
  #|bswap ecx|0fc9|BSWAP32r:%ECX,%ECX|rcx=f892930080000000 f=4d7|rcx=80 f=4d5/0
  #|bswap edx|0fca|BSWAP32r:%EDX,%EDX|rdx=975702e416e24cd0 f=c42|rdx=d04ce216 f=c40/0
  #|bswap edx|0fca|BSWAP32r:%EDX,%EDX|rdx=20a61f46057cffff f=897|rdx=ffff7c05 f=895/0
  #|bswap rax|480fc8|BSWAP64r:%RAX,%RAX|rax=ffffffff f=813|rax=ffffffff00000000 f=811/0
  #|bswap rax|480fc8|BSWAP64r:%RAX,%RAX|rax=e0aa67e880000000 f=853|rax=80e867aae0 f=851/0
  #|bswap rcx|480fc9|BSWAP64r:%RCX,%RCX|rcx=ffff f=847|rcx=ffff000000000000 f=845/0
  #|bswap rcx|480fc9|BSWAP64r:%RCX,%RCX|rcx=4df2a368e7b6a208 f=7|rcx=8a2b6e768a3f24d f=5/0
  #|bswap rdx|480fca|BSWAP64r:%RDX,%RDX|rdx=8000 f=897|rdx=80000000000000 f=895/0
  #|bswap rdx|480fca|BSWAP64r:%RDX,%RDX|rdx=9da9c3e5014e4c9a f=856|rdx=9a4c4e01e5c3a99d f=854/0

///|
let bits32_cases : String =
  #|bt ax, 255|660fbae0ff|BT16ri8:%AX,255|eax=2b7e5680 f=56|f=54/894
  #|bt word ptr [esi], dx|660fa316|BT16mr:%ESI,1,%,0,%,%DX|edx=2 f=806 m10080=52faf35512994243ac2272e89474ad44|f=804/894
  #|bt word ptr [esi], dx|660fa316|BT16mr:%ESI,1,%,0,%,%DX|edx=28 f=92 m10080=11f0b6640cc894c75a4703b678cc1064|f=90/894
  #|bt word ptr [esi], dx|660fa316|BT16mr:%ESI,1,%,0,%,%DX|edx=3c f=6 m10080=0e44f0f50ff70ca91b58ae98b6b52c17|f=4/894
  #|bt word ptr [esi], dx|660fa316|BT16mr:%ESI,1,%,0,%,%DX|edx=fffffff8 f=806 m10080=ac84eb9a23a59e4b85c3cfef50cbf09b|f=804/894
  #|bt word ptr [esi], 26|660fba261a|BT16mi8:%ESI,1,%,0,%,26|f=883 m10080=cc8c78abf3bdb66e5745318f48ced555|f=881/894
  #|bt word ptr [esi], 26|660fba261a|BT16mi8:%ESI,1,%,0,%,26|f=c52 m10080=d73489db237b380cb7249c43c40841d8|f=c51/894
  #|bt eax, 12|0fbae00c|BT32ri8:%EAX,12|eax=1 f=c3|f=c0/894
  #|bt eax, 35|0fbae023|BT32ri8:%EAX,35|eax=ffffffff f=7|f=5/894
  #|bts bx, 9|660fbaeb09|BTS16ri8:%BX,%BX,9|ebx=28 f=852|ebx=228 f=850/894
  #|bts bx, 19|660fbaeb13|BTS16ri8:%BX,%BX,19|ebx=606ec769 f=d2|f=d1/894
  #|bts bx, 255|660fbaebff|BTS16ri8:%BX,%BX,255|ebx=ee f=c96|ebx=80ee f=c94/894
  #|bts ecx, ebx|0fabd9|BTS32rr:%ECX,%ECX,%EBX|ecx=19f74fef ebx=607ef19c f=6|f=5/894
  #|bts ecx, ebx|0fabd9|BTS32rr:%ECX,%ECX,%EBX|ecx=ffff ebx=14ed9780 f=8d6|f=8d5/894
  #|bts ecx, ebx|0fabd9|BTS32rr:%ECX,%ECX,%EBX|ecx=84 ebx=ecc80633 f=892|ecx=80084 f=890/894
  #|bts ecx, 35|0fbae923|BTS32ri8:%ECX,%ECX,35|ecx=2517960d f=842|f=841/894
  #|bts ecx, 255|0fbae9ff|BTS32ri8:%ECX,%ECX,255|ecx=b21cf9e8 f=8d3|f=8d1/894
  #|bts dword ptr [edi + 0x10], eax|0fab4710|BTS32mr:%EDI,1,%,16,%,%EAX|eax=b f=83 m10110=bac84cd7de008470949ebc182766c379|f=81/894
  #|bts dword ptr [edi + 0x10], eax|0fab4710|BTS32mr:%EDI,1,%,16,%,%EAX|eax=3 f=97 m10110=9744a79499ba802f910516a04b95ed2a|f=94/894 m10110=9f
  #|bts dword ptr [edi + 0x10], eax|0fab4710|BTS32mr:%EDI,1,%,16,%,%EAX|eax=7 f=856 m10110=c8e6bbccc5f7460327f25200fa8ad990|f=855/894
  #|bts dword ptr [edi + 0x10], eax|0fab4710|BTS32mr:%EDI,1,%,16,%,%EAX|eax=35 f=43 m10110=27933281e66f0b08a37c1d6edd402bb9|f=40/894 m10116=2b
  #|btr dx, bx|660fb3da|BTR16rr:%DX,%DX,%BX|edx=58b25b16 ebx=e1d6 f=57|f=54/894
  #|btr dx, bx|660fb3da|BTR16rr:%DX,%DX,%BX|edx=7ccf0ed1 ebx=7fffffff f=c07|f=c04/894
  #|btr dx, bx|660fb3da|BTR16rr:%DX,%DX,%BX|edx=7fffffff ebx=8 f=8d7|edx=7ffffeff f=8d5/894
  #|btr dx, 4|660fbaf204|BTR16ri8:%DX,%DX,4|edx=cf182be1 f=856|f=854/894
  #|btr dx, 19|660fbaf213|BTR16ri8:%DX,%DX,19|edx=c f=493|edx=4 f=491/894
  #|btr dx, 255|660fbaf2ff|BTR16ri8:%DX,%DX,255|edx=ffffffff f=883|edx=ffff7fff f=881/894
  #|btr word ptr [esi], dx|660fb316|BTR16mr:%ESI,1,%,0,%,%DX|edx=c f=c53 m10080=109c84e55c80d5f4fa058a9811e936d3|f=c51/894 m10081=8c
  #|btr word ptr [esi], dx|660fb316|BTR16mr:%ESI,1,%,0,%,%DX|edx=38 f=cc7 m10080=513a43d4d1c2613b144f50e310d13054|f=cc5/894 m10087=3a
  #|btr word ptr [esi], dx|660fb316|BTR16mr:%ESI,1,%,0,%,%DX|edx=39 f=3 m10080=42346540e28206c93539c2eb653fbc82|f=0/894
  #|btr word ptr [esi], dx|660fb316|BTR16mr:%ESI,1,%,0,%,%DX|edx=34 f=406 m10080=43724a3389fa635face04b019b09907b|f=404/894
  #|btr ecx, eax|0fb3c1|BTR32rr:%ECX,%ECX,%EAX|eax=eb862d78 ecx=76359ea8 f=56|f=54/894
  #|btr ecx, eax|0fb3c1|BTR32rr:%ECX,%ECX,%EAX|eax=6ae150a0 ecx=b2c76f2f f=97|ecx=b2c76f2e f=95/894
  #|btr ecx, eax|0fb3c1|BTR32rr:%ECX,%ECX,%EAX|eax=7f ecx=7d37caa8 f=807|f=804/894
  #|btr ecx, 6|0fbaf106|BTR32ri8:%ECX,%ECX,6|ecx=fffffffe f=42|ecx=ffffffbe f=41/894
  #|btr ecx, 35|0fbaf123|BTR32ri8:%ECX,%ECX,35|ecx=fbd5 f=17|f=14/894
  #|btr ecx, 255|0fbaf1ff|BTR32ri8:%ECX,%ECX,255|ecx=7 f=d6|f=d4/894
  #|btr dword ptr [esi], eax|0fb306|BTR32mr:%ESI,1,%,0,%,%EAX|eax=19 f=416 m10080=8d04d1886a5a45491839f20afce935ba|f=414/894
  #|btr dword ptr [esi], eax|0fb306|BTR32mr:%ESI,1,%,0,%,%EAX|eax=ffffffff f=816 m10080=c7918a0e5678d78c74d8d41eb4e7509a|f=814/894
  #|btr dword ptr [esi], eax|0fb306|BTR32mr:%ESI,1,%,0,%,%EAX|eax=8 f=56 m10080=7bae8d7259a51368aac9b77be27f9099|f=54/894
  #|btr dword ptr [esi], eax|0fb306|BTR32mr:%ESI,1,%,0,%,%EAX|eax=16 f=8c2 m10080=c7387b7895b64fc5409d1f64f4756a7d|f=8c1/894 m10082=3b
  #|btr dword ptr [esi], 15|0fba360f|BTR32mi8:%ESI,1,%,0,%,15|f=47 m10080=84c6de35633c409b7cf8fb58ee0f1464|f=45/894 m10081=46
  #|btr dword ptr [esi], 15|0fba360f|BTR32mi8:%ESI,1,%,0,%,15|f=847 m10080=5f6046750d3d79bf56e9ad543c55e0e9|f=844/894
  #|btc dx, 255|660fbafaff|BTC16ri8:%DX,%DX,255|edx=b6d1037 f=4d6|edx=b6d9037 f=4d4/894
  #|btc word ptr [edi + 0x10], 8|660fba7f1008|BTC16mi8:%EDI,1,%,16,%,8|f=c83 m10110=ee1cb7b1981dbbc2a4cad143bd22e4e9|f=c80/894 m10111=1d
  #|btc word ptr [edi + 0x10], 8|660fba7f1008|BTC16mi8:%EDI,1,%,16,%,8|f=882 m10110=f0176d950626d55b9ae08c03b547f599|f=881/894 m10111=16
  #|btc edx, ebx|0fbbda|BTC32rr:%EDX,%EDX,%EBX|edx=a8b04dac ebx=f53da45d f=443|edx=88b04dac f=441/894
  #|btc edx, ebx|0fbbda|BTC32rr:%EDX,%EDX,%EBX|edx=38cc8b38 ebx=b f=8d3|edx=38cc8338 f=8d1/894
  #|btc edx, ebx|0fbbda|BTC32rr:%EDX,%EDX,%EBX|edx=d67a84d3 ebx=61b717af f=96|edx=d67a04d3 f=95/894
  #|btc edx, 35|0fbafa23|BTC32ri8:%EDX,%EDX,35|edx=ffff f=8d2|edx=fff7 f=8d1/894
  #|btc edx, 255|0fbafaff|BTC32ri8:%EDX,%EDX,255|edx=84ee54d1 f=93|edx=4ee54d1 f=91/894
  #|btc dword ptr [edi + 0x10], edx|0fbb5710|BTC32mr:%EDI,1,%,16,%,%EDX|edx=1f f=c82 m10110=42567d3e5a52b51280b36fdcdaf4af41|f=c80/894 m10113=be
  #|btc dword ptr [edi + 0x10], edx|0fbb5710|BTC32mr:%EDI,1,%,16,%,%EDX|edx=fffffff8 f=82 m10110=747708162766091c21091df6ea8366f1|f=80/894 m1010f=37
  #|btc dword ptr [edi + 0x10], edx|0fbb5710|BTC32mr:%EDI,1,%,16,%,%EDX|edx=22 f=893 m10110=a9567c389cb138071dbed9a801ddffb9|f=891/894 m10114=98
  #|btc dword ptr [edi + 0x10], edx|0fbb5710|BTC32mr:%EDI,1,%,16,%,%EDX|edx=34 f=96 m10110=c7794154512067241c82dc1458cf1981|f=94/894 m10116=77
  #|bsf dx, ax|660fbcd0|BSF16rr:%DX,%DX,%AX|eax=fe5085d edx=80 f=857|edx=0 f=0/895
  #|bsf dx, ax|660fbcd0|BSF16rr:%DX,%DX,%AX|eax=5323c005 edx=c1 f=97|edx=0 f=84/895
  #|bsf dx, ax|660fbcd0|BSF16rr:%DX,%DX,%AX|eax=3ed57c8d edx=abaa9c37 f=d6|edx=abaa0000 f=4/895
  #|bsf dx, ax|660fbcd0|BSF16rr:%DX,%DX,%AX|eax=dd1b edx=eb1fa97f f=8d6|edx=eb1f0000 f=84/895
  #|bsf dx, word ptr [edi + 0x10]|660fbc5710|BSF16rm:%DX,%DX,%EDI,1,%,16,%|edx=721f6ef8 f=896 m10110=49cc653e2e8173c1b3e93303cff95c2a|edx=721f0000 f=80/895
  #|bsf dx, word ptr [edi + 0x10]|660fbc5710|BSF16rm:%DX,%DX,%EDI,1,%,16,%|edx=b2283e65 f=52 m10110=824a876b4ccadd65202201ae86d7ff11|edx=b2280001 f=4/895
  #|bsf edx, eax|0fbcd0|BSF32rr:%EDX,%EDX,%EAX|eax=bc edx=ffffffff f=893|edx=2 f=0/895
  #|bsf edx, eax|0fbcd0|BSF32rr:%EDX,%EDX,%EAX|eax=0 edx=21c187fa f=857|edx=? f=44/895
  #|bsf edx, eax|0fbcd0|BSF32rr:%EDX,%EDX,%EAX|eax=0 edx=a98fc80f f=8c7|edx=? f=44/895
  #|bsf edx, eax|0fbcd0|BSF32rr:%EDX,%EDX,%EAX|eax=0 edx=d0719133 f=12|edx=? f=44/895
  #|bsf edx, dword ptr [esi]|0fbc16|BSF32rm:%EDX,%EDX,%ESI,1,%,0,%|edx=86a06c12 f=cc2 m10080=c4e350e106859bcf95c357460e648e5a|edx=2 f=480/895
  #|bsf edx, dword ptr [esi]|0fbc16|BSF32rm:%EDX,%EDX,%ESI,1,%,0,%|edx=2 f=8c7 m10080=732c78fc69397277317cbb14d4a9ccaa|edx=0 f=80/895
  #|bsr ax, dx|660fbdc2|BSR16rr:%AX,%AX,%DX|eax=1864ffff edx=d0b50000 f=cd6|eax=? f=444/895
  #|bsr ax, dx|660fbdc2|BSR16rr:%AX,%AX,%DX|eax=f2f9f8fd edx=a f=cd7|eax=f2f90003 f=404/895
  #|bsr ax, dx|660fbdc2|BSR16rr:%AX,%AX,%DX|eax=fd9b edx=951f2371 f=17|eax=d f=4/895
  #|bsr ax, dx|660fbdc2|BSR16rr:%AX,%AX,%DX|eax=9c15c10a edx=7f f=96|eax=9c150006 f=0/895
  #|bsr ax, word ptr [edi + 0x10]|660fbd4710|BSR16rm:%AX,%AX,%EDI,1,%,16,%|eax=ffffffff f=d2 m10110=4d8704c46df01a7f122b6511c983cc78|eax=ffff000f f=84/895
  #|bsr ax, word ptr [edi + 0x10]|660fbd4710|BSR16rm:%AX,%AX,%EDI,1,%,16,%|eax=2569251d f=817 m10110=58e25bb3c69f7bac713444800f47b4af|eax=2569000f f=80/895
  #|bsr ebx, ecx|0fbdd9|BSR32rr:%EBX,%EBX,%ECX|ecx=ded2b3b9 ebx=79c5874d f=807|ebx=1f f=80/895
  #|bsr ebx, ecx|0fbdd9|BSR32rr:%EBX,%EBX,%ECX|ecx=b6b79a81 ebx=5e68dba7 f=806|ebx=1f f=84/895
  #|bsr ebx, ecx|0fbdd9|BSR32rr:%EBX,%EBX,%ECX|ecx=7b82d5a7 ebx=f6d8ec0a f=8d7|ebx=1e f=0/895
  #|bsr ebx, ecx|0fbdd9|BSR32rr:%EBX,%EBX,%ECX|ecx=100 ebx=5cdcffff f=13|ebx=8 f=4/895
  #|lzcnt bx, cx|66f30fbdd9|LZCNT16rr:%BX,%CX|ecx=7cc00000 ebx=b1334221 f=d6|ebx=b1330010 f=1/894
  #|lzcnt bx, cx|66f30fbdd9|LZCNT16rr:%BX,%CX|ecx=cc240000 ebx=4914ff42 f=46|ebx=49140010 f=1/894
  #|lzcnt bx, cx|66f30fbdd9|LZCNT16rr:%BX,%CX|ecx=0 ebx=d2b6 f=43|ebx=10 f=1/894
  #|lzcnt bx, word ptr [edi + 0x10]|66f30fbd5f10|LZCNT16rm:%BX,%EDI,1,%,16,%|ebx=1c8f47d2 f=c83 m10110=a9397da5b57f7a7b906dd6975fbf39fe|ebx=1c8f0002 f=400/894
  #|lzcnt bx, word ptr [edi + 0x10]|66f30fbd5f10|LZCNT16rm:%BX,%EDI,1,%,16,%|ebx=f009f847 f=46 m10110=29262c770833362a62725080e2c89189|ebx=f0090002 f=0/894
  #|tzcnt dx, cx|66f30fbcd1|TZCNT16rr:%DX,%CX|ecx=7cf7b436 edx=7fff f=446|edx=1 f=400/894
  #|tzcnt dx, cx|66f30fbcd1|TZCNT16rr:%DX,%CX|ecx=afe20000 edx=b1b6291d f=886|edx=b1b60010 f=1/894
  #|tzcnt dx, cx|66f30fbcd1|TZCNT16rr:%DX,%CX|ecx=a0020186 edx=63 f=8d2|edx=1 f=0/894
  #|tzcnt dx, word ptr [esi]|66f30fbc16|TZCNT16rm:%DX,%ESI,1,%,0,%|edx=0 f=d2 m10080=8b86bd4278e825e8567dacbba4c5e48e|f=40/894
  #|tzcnt dx, word ptr [esi]|66f30fbc16|TZCNT16rm:%DX,%ESI,1,%,0,%|edx=7fffffff f=47 m10080=70fa34d63db9391560999affd410af45|edx=7fff0004 f=0/894
  #|tzcnt edx, ebx|f30fbcd3|TZCNT32rr:%EDX,%EBX|edx=35746a36 ebx=6a3cd6c9 f=856|edx=0 f=40/894
  #|tzcnt edx, ebx|f30fbcd3|TZCNT32rr:%EDX,%EBX|edx=e59a8000 ebx=4 f=93|edx=2 f=0/894
  #|tzcnt edx, ebx|f30fbcd3|TZCNT32rr:%EDX,%EBX|edx=589257f ebx=0 f=46|edx=20 f=1/894
  #|popcnt dx, word ptr [ebp - 0x20]|66f30fb855e0|POPCNT16rm:%DX,%EBP,1,%,-32,%|edx=d33fa855 f=897 m20160=b7d0e468ed2448a822539cda06365aa6|edx=d33f0009 f=0/0
  #|popcnt dx, word ptr [ebp - 0x20]|66f30fb855e0|POPCNT16rm:%DX,%EBP,1,%,-32,%|edx=ffffffff f=87 m20160=03234e7a0ebdc13b9aab6bf90fae3579|edx=ffff0005 f=0/0
  #|popcnt ebx, edx|f30fb8da|POPCNT32rr:%EBX,%EDX|edx=0 ebx=9642adf1 f=93|ebx=0 f=40/0
  #|popcnt ebx, edx|f30fb8da|POPCNT32rr:%EBX,%EDX|edx=d8a2f47f ebx=be8b367b f=807|ebx=13 f=0/0
  #|popcnt ebx, edx|f30fb8da|POPCNT32rr:%EBX,%EDX|edx=5be47237 ebx=af05de3f f=c07|ebx=12 f=400/0
  #|popcnt ebx, dword ptr [ebp - 0x20]|f30fb85de0|POPCNT32rm:%EBX,%EBP,1,%,-32,%|ebx=6848136 f=807 m20160=d67bb0b39608c5f7e29375412ed93fe6|ebx=13 f=0/0
  #|popcnt ebx, dword ptr [ebp - 0x20]|f30fb85de0|POPCNT32rm:%EBX,%EBP,1,%,-32,%|ebx=1d f=847 m20160=6ddfa9290db44c9313b2d6828cc66d30|ebx=13 f=0/0
  #|bswap edx|0fca|BSWAP32r:%EDX,%EDX|edx=80000000 f=3|edx=80 f=1/0
  #|bswap edx|0fca|BSWAP32r:%EDX,%EDX|edx=b71e88e9 f=893|edx=e9881eb7 f=891/0
