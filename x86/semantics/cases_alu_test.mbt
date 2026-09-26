// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let alu64_cases : String =
  #|add r10b, al|4100c2|ADD8rr:%R10B,%R10B,%AL|rax=9f4fae87317ce496 r10=93 f=816|r10=29 f=801/0
  #|add r10b, al|4100c2|ADD8rr:%R10B,%R10B,%AL|rax=9 r10=b0f90ceaffffffff f=c83|r10=b0f90ceaffffff08 f=411/0
  #|add bl, r8b|4400c3|ADD8rr:%BL,%BL,%R8B|rbx=4e1bb4fe80000000 r8=39bc414088e4954c f=852|rbx=4e1bb4fe8000004c f=0/0
  #|add bl, r8b|4400c3|ADD8rr:%BL,%BL,%R8B|rbx=ffffffff r8=c8b41ec3f7dc4ea f=6|rbx=ffffffe9 f=91/0
  #|add byte ptr [rsi + rbx*4 + 0x8], r9b|44004c9e08|ADD8mr:%RSI,4,%RBX,8,%,%R9B|rbx=5 r9=6 f=843 m1009c=1e078dc8d4070edc40394f2b842ef1f5|f=14/0 m1009c=24
  #|add byte ptr [rsi + rbx*4 + 0x8], r9b|44004c9e08|ADD8mr:%RSI,4,%RBX,8,%,%R9B|rbx=e r9=3 f=83 m100c0=75f803c203eef170491c12a3a4fe928e|f=4/0 m100c0=78
  #|add r9b, byte ptr [rsi]|44020e|ADD8rm:%R9B,%R9B,%RSI,1,%,0,%|rbx=0 r9=5 f=847 m10080=92225861e4afba6b26bcca39369fae49|r9=97 f=80/0
  #|add r9b, byte ptr [rsi]|44020e|ADD8rm:%R9B,%R9B,%RSI,1,%,0,%|rbx=c r9=d f=46 m10080=094cb39013eb81bd6894bf280def6454|r9=16 f=10/0
  #|add cl, -0x80|80c180|ADD8ri:%CL,%CL,-128|rcx=3c2b198080000000 f=817|rcx=3c2b198080000080 f=80/0
  #|add cl, -0x80|80c180|ADD8ri:%CL,%CL,-128|rcx=e4e824b07577d621 f=846|rcx=e4e824b07577d6a1 f=80/0
  #|add cl, 0x1|80c101|ADD8ri:%CL,%CL,1|rcx=1a7e9fd275d40cbd f=452|rcx=1a7e9fd275d40cbe f=484/0
  #|add cl, 0x1|80c101|ADD8ri:%CL,%CL,1|rcx=a1ac58ed764a587a f=13|rcx=a1ac58ed764a587b f=4/0
  #|add al, 0x1|0401|ADD8i8:1|rax=27 f=57|rax=28 f=4/0
  #|add al, 0x1|0401|ADD8i8:1|rax=bceb787679a1d89f f=813|rax=bceb787679a1d8a0 f=94/0
  #|add byte ptr [rdi + r9*2 - 0x4], -0x80|4280444ffc80|ADD8mi:%RDI,2,%R9,-4,%,-128|rbx=9 r9=f f=c86 m1011a=da0edb1c53dca53835ff1d562d1b0126|f=c05/0 m1011a=5a
  #|add byte ptr [rdi + r9*2 - 0x4], -0x80|4280444ffc80|ADD8mi:%RDI,2,%R9,-4,%,-128|rbx=7 r9=7 f=4d6 m1010a=72fd0fec15da5041741daf467cffa7ba|f=480/0 m1010a=f2
  #|add bx, ax|6601c3|ADD16rr:%BX,%BX,%AX|rax=adba0c1e7fffffff rbx=4a287dcb1bc7406 f=842|rbx=4a287dcb1bc7405 f=15/0
  #|add bx, ax|6601c3|ADD16rr:%BX,%BX,%AX|rax=97cf14f0ee43e701 rbx=8f f=892|rbx=e790 f=94/0
  #|add r8w, r12w|664501e0|ADD16rr:%R8W,%R8W,%R12W|r8=3eb07581e3368d12 r12=fffffffffffffffe f=cd3|r8=3eb07581e3368d10 f=491/0
  #|add r8w, r12w|664501e0|ADD16rr:%R8W,%R8W,%R12W|r8=2d52c93d0c96d62a r12=7fffffffffffffff f=483|r8=2d52c93d0c96d629 f=491/0
  #|add word ptr [rsi], r9w|6644010e|ADD16mr:%RSI,1,%,0,%,%R9W|rbx=b r9=f f=d2 m10080=ae0fd629f31782f5295591cff6cdc147|f=14/0 m10080=bd
  #|add word ptr [rsi], r9w|6644010e|ADD16mr:%RSI,1,%,0,%,%R9W|rbx=c r9=7 f=d3 m10080=d749887a062f1ed15d5989c69132ba93|f=4/0 m10080=de
  #|add r9w, word ptr [rdi + 0x10]|6644034f10|ADD16rm:%R9W,%R9W,%RDI,1,%,16,%|rbx=2 r9=2 f=6 m10110=260c1b69a4c09b73c6f44f399779797f|r9=c28 f=4/0
  #|add r9w, word ptr [rdi + 0x10]|6644034f10|ADD16rm:%R9W,%R9W,%RDI,1,%,16,%|rbx=c r9=f f=93 m10110=0ad4933b372f2a5390bdfa17338273e6|r9=d419 f=90/0
  #|add dx, -0x80|6683c280|ADD16ri8:%DX,%DX,-128|rdx=d0c4770f8e6d451b f=403|rdx=d0c4770f8e6d449b f=401/0
  #|add dx, -0x80|6683c280|ADD16ri8:%DX,%DX,-128|rdx=8000000000000000 f=7|rdx=800000000000ff80 f=80/0
  #|add dx, 0x100|6681c20001|ADD16ri:%DX,%DX,256|rdx=100 f=887|rdx=200 f=4/0
  #|add dx, 0x100|6681c20001|ADD16ri:%DX,%DX,256|rdx=f395fdf1de2e25d6 f=47|rdx=f395fdf1de2e26d6 f=0/0
  #|add ax, 0x1234|66053412|ADD16i16:4660|rax=8000000000000000 f=843|rax=8000000000001234 f=0/0
  #|add ax, 0x1234|66053412|ADD16i16:4660|rax=2f0015891d12480 f=c2|rax=2f0015891d136b4 f=4/0
  #|add word ptr [rdi + r9*2 - 0x4], 0x1|664283444ffc01|ADD16mi8:%RDI,2,%R9,-4,%,1|rbx=1 r9=4 f=7 m10104=f5ecfa0c2a2cee8cfc68b177aeb8dd79|f=84/0 m10104=f6
  #|add word ptr [rdi + r9*2 - 0x4], 0x1|664283444ffc01|ADD16mi8:%RDI,2,%R9,-4,%,1|rbx=9 r9=5 f=843 m10106=bb6a6b2f7382d918f77ecbbf5424200e|f=0/0 m10106=bc
  #|add r11d, r13d|4501eb|ADD32rr:%R11D,%R11D,%R13D|r11=e81371dacdcd7096 r13=89f74d98e39e92be f=857|r11=b16c0354 f=91/0
  #|add r11d, r13d|4501eb|ADD32rr:%R11D,%R11D,%R13D|r11=5c792672e649327f r13=ffffffffffffffff f=402|r11=e649327e f=495/0
  #|add ecx, r8d|4401c1|ADD32rr:%ECX,%ECX,%R8D|rcx=823953807057e679 r8=4d3fb1ec6a8f85e2 f=6|rcx=dae76c5b f=880/0
  #|add ecx, r8d|4401c1|ADD32rr:%ECX,%ECX,%R8D|rcx=8000000000000000 r8=e f=886|rcx=e f=0/0
  #|add dword ptr [rsi], r8d|440106|ADD32mr:%RSI,1,%,0,%,%R8D|rbx=7 r8=242407cf2aef6ae9 r9=9 f=893 m10080=a0cee8c5cbca8e3765f6d25a596ba016|f=80/0 m10080=8939d8f0
  #|add dword ptr [rsi], r8d|440106|ADD32mr:%RSI,1,%,0,%,%R8D|rbx=7 r8=437aec9b8603036f r9=8 f=8c3 m10080=6afe14b2e43514bba558f0e3565ab95b|f=811/0 m10080=d9011838
  #|add r8d, dword ptr [rsi]|440306|ADD32rm:%R8D,%R8D,%RSI,1,%,0,%|rbx=f r8=3e3cae54a238557f r9=6 f=2 m10080=d7f977ce6519301bddd4daa08d2df650|r8=70b04f56 f=815/0
  #|add r8d, dword ptr [rsi]|440306|ADD32rm:%R8D,%R8D,%RSI,1,%,0,%|rbx=f r8=b r9=8 f=4c2 m10080=1acc151f131e5ca62289ab67c8415db5|r8=1f15cc25 f=410/0
  #|add r11d, 0x5|4183c305|ADD32ri8:%R11D,%R11D,5|r11=4 f=896|r11=9 f=4/0
  #|add r11d, 0x5|4183c305|ADD32ri8:%R11D,%R11D,5|r11=79b9bfc7b54e28b5 f=846|r11=b54e28ba f=80/0
  #|add r11d, 0x100|4181c300010000|ADD32ri:%R11D,%R11D,256|r11=65d8e3b825f58832 f=802|r11=25f58932 f=0/0
  #|add r11d, 0x100|4181c300010000|ADD32ri:%R11D,%R11D,256|r11=ffffffff f=c16|r11=ff f=405/0
  #|add eax, 0x80|0580000000|ADD32i32:128|rax=1 f=c6|rax=81 f=4/0
  #|add eax, 0x80|0580000000|ADD32i32:128|rax=58cf6906dc7a212a f=43|rax=dc7a21aa f=84/0
  #|add dword ptr [rbp - 0x20], 0x5|8345e005|ADD32mi8:%RBP,1,%,-32,%,5|rbx=c r9=3 f=803 m20160=7bfa2946431a93bc21ab6d655714e20c|f=10/0 m20160=80
  #|add dword ptr [rbp - 0x20], 0x5|8345e005|ADD32mi8:%RBP,1,%,-32,%,5|rbx=3 r9=2 f=52 m20160=9230a3d5526eca0b7287e545798efc9b|f=80/0 m20160=97
  #|add r14, rbx|4901de|ADD64rr:%R14,%R14,%RBX|rbx=e5f4354922ea9426 r14=7fffffff f=57|r14=e5f43549a2ea9425 f=90/0
  #|add r14, rbx|4901de|ADD64rr:%R14,%R14,%RBX|rbx=d26d71eb669790e0 r14=32 f=87|r14=d26d71eb66979112 f=84/0
  #|add r12, r9|4d01cc|ADD64rr:%R12,%R12,%R9|r9=b958 r12=f4edee6b01552d58 f=d6|r12=f4edee6b0155e6b0 f=90/0
  #|add r12, r9|4d01cc|ADD64rr:%R12,%R12,%R9|r9=bdc73e0afefd8c2e r12=9 f=93|r12=bdc73e0afefd8c37 f=90/0
  #|add qword ptr [rsi + rbx*4 + 0x8], r15|4c017c9e08|ADD64mr:%RSI,4,%RBX,8,%,%R15|rbx=5 r9=c r15=9 f=c7 m1009c=d375858c3acc5d8bbc54baa026f256a7|f=80/0 m1009c=dc
  #|add qword ptr [rsi + rbx*4 + 0x8], r15|4c017c9e08|ADD64mr:%RSI,4,%RBX,8,%,%R15|rbx=a r9=f r15=8284cc5fe0eb961 f=883 m100b0=e009e0d7c52e818ac8c17a844f316c69|f=84/0 m100b0=41c3eed58b7ba992
  #|add r15, qword ptr [rdi + r9*2 - 0x4]|4e037c4ffc|ADD64rm:%R15,%R15,%RDI,2,%R9,-4,%|rbx=3 r9=e r15=fda8993ec163bfe0 f=d6 m10118=267bbf07a4a1ff74fe94343f45d1c212|r15=72a83ae2c9233b06 f=5/0
  #|add r15, qword ptr [rdi + r9*2 - 0x4]|4e037c4ffc|ADD64rm:%R15,%R15,%RDI,2,%R9,-4,%|rbx=7 r9=d r15=7fff f=c3 m10116=d7b12e4883da192f38b2d05168f0c4c1|r15=2f19da83482f31d6 f=10/0
  #|add rcx, 0x5|4883c105|ADD64ri8:%RCX,%RCX,5|rcx=ff f=7|rcx=104 f=10/0
  #|add rcx, 0x5|4883c105|ADD64ri8:%RCX,%RCX,5|rcx=5 f=93|rcx=a f=4/0
  #|add rcx, 0x100|4881c100010000|ADD64ri32:%RCX,%RCX,256|rcx=f68fd7b975cb045b f=816|rcx=f68fd7b975cb055b f=80/0
  #|add rcx, 0x100|4881c100010000|ADD64ri32:%RCX,%RCX,256|rcx=5e0049fbbcca7fff f=97|rcx=5e0049fbbcca80ff f=4/0
  #|add rax, -0x80000000|480500000080|ADD64i32:-2147483648|rax=acf1dcb63a02b479 f=847|rax=acf1dcb5ba02b479 f=81/0
  #|add rax, -0x80000000|480500000080|ADD64i32:-2147483648|rax=3f2b576f17161500 f=8c7|rax=3f2b576e97161500 f=5/0
  #|add qword ptr [rsi + rbx*4 + 0x8], 0x1|4883449e0801|ADD64mi8:%RSI,4,%RBX,8,%,1|rbx=0 r9=5 f=843 m10088=b8e67c014d947b52f833a98288524ef2|f=0/0 m10088=b9
  #|add qword ptr [rsi + rbx*4 + 0x8], 0x1|4883449e0801|ADD64mi8:%RSI,4,%RBX,8,%,1|rbx=c r9=1 f=886 m100b8=cb5d757c78d2c8f20764816dea2e19e8|f=84/0 m100b8=cc
  #|or r8b, bl|4108d8|OR8rr:%R8B,%R8B,%BL|rbx=d7eb0056bb16949 r8=7fffffffffffffff f=d6|f=84/10
  #|or r8b, bl|4108d8|OR8rr:%R8B,%R8B,%BL|rbx=cd3118a01c49cf06 r8=287b562736a73f54 f=447|r8=287b562736a73f56 f=404/10
  #|or r15b, dl|4108d7|OR8rr:%R15B,%R15B,%DL|rdx=f13b6c998dd7dc11 r15=7d7985fa0b594b47 f=56|r15=7d7985fa0b594b57 f=0/10
  #|or r15b, dl|4108d7|OR8rr:%R15B,%R15B,%DL|rdx=cb9a r15=9b72bfbf2b067c41 f=883|r15=9b72bfbf2b067cdb f=84/10
  #|or byte ptr [rdi + 0x10], r15b|44087f10|OR8mr:%RDI,1,%,16,%,%R15B|rbx=b r9=c r15=1595c90e15ab8be2 f=cd6 m10110=9ad4ee0995d7d32f33688ce47d3a0e2a|f=484/10 m10110=fa
  #|or byte ptr [rdi + 0x10], r15b|44087f10|OR8mr:%RDI,1,%,16,%,%R15B|rbx=d r9=a r15=e0128197a659fa03 f=c56 m10110=a514b302dfcf451273f781dc82f8a48c|f=480/10 m10110=a7
  #|or r15b, byte ptr [rdi + 0x10]|440a7f10|OR8rm:%R15B,%R15B,%RDI,1,%,16,%|rbx=2 r9=6 r15=d53344dbdfd5ad7a f=92 m10110=af3e95e473b99b32fab7200c06f0ace2|r15=d53344dbdfd5adff f=84/10
  #|or r15b, byte ptr [rdi + 0x10]|440a7f10|OR8rm:%R15B,%R15B,%RDI,1,%,16,%|rbx=b r9=3 r15=aee41f87864e32b9 f=4d6 m10110=f57d44378cebc576b1168e1c72c64d04|r15=aee41f87864e32fd f=480/10
  #|or r13b, -0x1|4180cdff|OR8ri:%R13B,%R13B,-1|r13=2 f=16|r13=ff f=84/10
  #|or r13b, -0x1|4180cdff|OR8ri:%R13B,%R13B,-1|r13=7f f=812|r13=ff f=84/10
  #|or r13b, 0x7f|4180cd7f|OR8ri:%R13B,%R13B,127|r13=b4989ebe0e6e6831 f=8d6|r13=b4989ebe0e6e687f f=0/10
  #|or r13b, 0x7f|4180cd7f|OR8ri:%R13B,%R13B,127|r13=7fffffff f=803|f=84/10
  #|or al, 0x5a|0c5a|OR8i8:90|rax=21b84384e8a8dd64 f=47|rax=21b84384e8a8dd7e f=4/10
  #|or al, 0x5a|0c5a|OR8i8:90|rax=dcbc90ec938e4b7a f=12|f=0/10
  #|or byte ptr [rbp - 0x20], 0x1|804de001|OR8mi:%RBP,1,%,-32,%,1|rbx=3 r9=d f=816 m20160=b57d52bffdec14a3b35896737e6907c4|f=80/10
  #|or byte ptr [rbp - 0x20], 0x1|804de001|OR8mi:%RBP,1,%,-32,%,1|rbx=9 r9=e f=406 m20160=011242430434e5dcb30dd31a73f1d75f|f=400/10
  #|or r13w, r12w|664509e5|OR16rr:%R13W,%R13W,%R12W|r12=4d77406e977e9db4 r13=8000000000000000 f=882|r13=8000000000009db4 f=84/10
  #|or r13w, r12w|664509e5|OR16rr:%R13W,%R13W,%R12W|r12=100 r13=c2d5a296ff8978a8 f=57|r13=c2d5a296ff8979a8 f=0/10
  #|or cx, r14w|664409f1|OR16rr:%CX,%CX,%R14W|rcx=a16e59f185001db2 r14=d6 f=8d2|rcx=a16e59f185001df6 f=4/10
  #|or cx, r14w|664409f1|OR16rr:%CX,%CX,%R14W|rcx=7ac10ceda61cacd8 r14=ffffffffffffffff f=c2|rcx=7ac10ceda61cffff f=84/10
  #|or word ptr [rsi + rbx*4 + 0x8], r13w|6644096c9e08|OR16mr:%RSI,4,%RBX,8,%,%R13W|rbx=f r9=c r13=51693c4d97c667c1 f=842 m100c4=d404f1ceae9de0f68685ca74b44fd9b2|f=0/10 m100c4=d567
  #|or word ptr [rsi + rbx*4 + 0x8], r13w|6644096c9e08|OR16mr:%RSI,4,%RBX,8,%,%R13W|rbx=d r9=8 r13=49a17adb3649c482 f=892 m100bc=6b38a6489ead3fa557d97e6226cfe83b|f=84/10 m100bc=ebfc
  #|or r13w, word ptr [rsp + 0x8]|66440b6c2408|OR16rm:%R13W,%R13W,%RSP,1,%,8,%|rbx=8 r9=e r13=ffffffff f=843 m20108=b3d10aab60032b854ab2d3ccbccf968f|f=84/10
  #|or r13w, word ptr [rsp + 0x8]|66440b6c2408|OR16rm:%R13W,%R13W,%RSP,1,%,8,%|rbx=e r9=7 r13=fde57b9d8d86d4c9 f=8d6 m20108=eb81f877fe1b35c6e20bd57387cc9462|r13=fde57b9d8d86d5eb f=84/10
  #|or r8w, -0x80|664183c880|OR16ri8:%R8W,%R8W,-128|r8=86fd20d4e26964b0 f=83|r8=86fd20d4e269ffb0 f=80/10
  #|or r8w, -0x80|664183c880|OR16ri8:%R8W,%R8W,-128|r8=c2e31c48796ae680 f=842|r8=c2e31c48796aff80 f=80/10
  #|or r8w, 0x8000|664181c80080|OR16ri:%R8W,%R8W,32768|r8=4 f=853|r8=8004 f=80/10
  #|or r8w, 0x8000|664181c80080|OR16ri:%R8W,%R8W,32768|r8=ae f=7|r8=80ae f=80/10
  #|or ax, 0x8000|660d0080|OR16i16:32768|rax=33501f0241548b13 f=d3|f=80/10
  #|or ax, 0x8000|660d0080|OR16i16:32768|rax=ffff f=d7|f=84/10
  #|or word ptr [rsi], 0x7f|66830e7f|OR16mi8:%RSI,1,%,0,%,127|rbx=e r9=8 f=443 m10080=ff21e6071cef97ec122b55dbf58f4f90|f=404/10
  #|or word ptr [rsi], 0x7f|66830e7f|OR16mi8:%RSI,1,%,0,%,127|rbx=b r9=d f=42 m10080=91d5f9d0f3fb677b1b488ef02452d5ed|f=84/10 m10080=ff
  #|or r13d, ecx|4109cd|OR32rr:%R13D,%R13D,%ECX|rcx=f3b6793066a28060 r13=b1e9d0dcffffffff f=52|r13=ffffffff f=84/10
  #|or r13d, ecx|4109cd|OR32rr:%R13D,%R13D,%ECX|rcx=f8dd155e4503160f r13=25 f=812|r13=4503162f f=0/10
  #|or r8d, r13d|4509e8|OR32rr:%R8D,%R8D,%R13D|r8=972ead9ee8d32e29 r13=54ab1643c96572a6 f=897|r8=e9f77eaf f=84/10
  #|or r8d, r13d|4509e8|OR32rr:%R8D,%R8D,%R13D|r8=40480e2da67587c8 r13=1 f=c46|r8=a67587c9 f=484/10
  #|or dword ptr [rbp - 0x20], r9d|44094de0|OR32mr:%RBP,1,%,-32,%,%R9D|rbx=1 r9=b f=17 m20160=3bf331c250537662fdd748710eda679e|f=80/10
  #|or dword ptr [rbp - 0x20], r9d|44094de0|OR32mr:%RBP,1,%,-32,%,%R9D|rbx=f r9=7 f=d6 m20160=0c2ca63afb71f0d82ae0492f17f4c572|f=4/10 m20160=0f
  #|or r9d, dword ptr [rdi + r9*2 - 0x4]|460b4c4ffc|OR32rm:%R9D,%R9D,%RDI,2,%R9,-4,%|rbx=e r9=9 f=d3 m1010e=eb409a36fc3ac36ad7082c41450a9fea|r9=369a40eb f=4/10
  #|or r9d, dword ptr [rdi + r9*2 - 0x4]|460b4c4ffc|OR32rm:%R9D,%R9D,%RDI,2,%R9,-4,%|rbx=b r9=c f=842 m10114=19e935f34d5fcba64357ffdbb137f5dd|r9=f335e91d f=84/10
  #|or r8d, 0x5|4183c805|OR32ri8:%R8D,%R8D,5|r8=d4857ee214c9527e f=cc7|r8=14c9527f f=400/10
  #|or r8d, 0x5|4183c805|OR32ri8:%R8D,%R8D,5|r8=229c35532f9d0e10 f=8d7|r8=2f9d0e15 f=0/10
  #|or r8d, 0x7fffffff|4181c8ffffff7f|OR32ri:%R8D,%R8D,2147483647|r8=8a7c968b9905b2e9 f=c42|r8=ffffffff f=484/10
  #|or r8d, 0x7fffffff|4181c8ffffff7f|OR32ri:%R8D,%R8D,2147483647|r8=29629aff8ae68162 f=882|r8=ffffffff f=84/10
  #|or eax, -0x100|0d00ffffff|OR32i32:4294967040|rax=9581f58b5b0bba6b f=882|rax=ffffff6b f=80/10
  #|or eax, -0x100|0d00ffffff|OR32i32:4294967040|rax=cc6f4626a2653773 f=497|rax=ffffff73 f=480/10
  #|or dword ptr [rsi], 0x7f|830e7f|OR32mi8:%RSI,1,%,0,%,127|rbx=a r9=6 f=803 m10080=05643096931185bd3e141b23291a7152|f=80/10 m10080=7f
  #|or dword ptr [rsi], 0x7f|830e7f|OR32mi8:%RSI,1,%,0,%,127|rbx=6 r9=9 f=896 m10080=f81a5d45fa9485b95e61baed9f139ce5|f=4/10 m10080=ff
  #|or r12, rax|4909c4|OR64rr:%R12,%R12,%RAX|rax=7fffffff r12=cddf573602cda65e f=43|r12=cddf57367fffffff f=84/10
  #|or r12, rax|4909c4|OR64rr:%R12,%R12,%RAX|rax=e53917ffdbcfd192 r12=100 f=57|r12=e53917ffdbcfd192 f=80/10
  #|or rcx, r13|4c09e9|OR64rr:%RCX,%RCX,%R13|rcx=8c8650e97a7a6c10 r13=6fdaa30b9a7dd25a f=c6|rcx=efdef3ebfa7ffe5a f=84/10
  #|or rcx, r13|4c09e9|OR64rr:%RCX,%RCX,%R13|rcx=5b36 r13=7160adc9d9caffff f=83|rcx=7160adc9d9caffff f=4/10
  #|or qword ptr [rsi + rbx*4 + 0x8], r12|4c09649e08|OR64mr:%RSI,4,%RBX,8,%,%R12|rbx=d r9=6 r12=edf9945c221d7fff f=c53 m100bc=f30261b2b4a4c1a8a32a6d0dcfb42a8b|f=484/10 m100bc=ff7f7d m100c0=fcb4f9ed
  #|or qword ptr [rsi + rbx*4 + 0x8], r12|4c09649e08|OR64mr:%RSI,4,%RBX,8,%,%R12|rbx=7 r9=d r12=a1bafce663c22555 f=802 m100a4=144b698ff76f2ce1857426838080578a|f=84/10 m100a4=556febef m100a9=ffbe
  #|or r12, qword ptr [rdi + 0x10]|4c0b6710|OR64rm:%R12,%R12,%RDI,1,%,16,%|rbx=b r9=2 r12=d98fd42c75b0ce65 f=483 m10110=b550cc2c97bb58bb3915eb52f756e434|r12=fbdfffbf7dfcdef5 f=484/10
  #|or r12, qword ptr [rdi + 0x10]|4c0b6710|OR64rm:%R12,%R12,%RDI,1,%,16,%|rbx=3 r9=1 r12=f7f836291c7b69f6 f=813 m10110=97d3ed834e52c6ba3804620eb77011cc|r12=fffe766f9ffffbf7 f=80/10
  #|or r13, 0x1|4983cd01|OR64ri8:%R13,%R13,1|r13=7fffffff f=3|f=4/10
  #|or r13, 0x1|4983cd01|OR64ri8:%R13,%R13,1|r13=ffffffff f=8d3|f=4/10
  #|or r13, 0x12345678|4981cd78563412|OR64ri32:%R13,%R13,305419896|r13=2c4e14d4973c520f f=97|r13=2c4e14d4973c567f f=0/10
  #|or r13, 0x12345678|4981cd78563412|OR64ri32:%R13,%R13,305419896|r13=2ee51c8efc559850 f=4d6|r13=2ee51c8efe75de78 f=404/10
  #|or rax, 0x100|480d00010000|OR64i32:256|rax=99f8780e4c07f717 f=87|f=84/10
  #|or rax, 0x100|480d00010000|OR64i32:256|rax=1 f=893|rax=101 f=0/10
  #|or qword ptr [rdi + r9*2 - 0x4], 0x1|4a834c4ffc01|OR64mi8:%RDI,2,%R9,-4,%,1|rbx=8 r9=a f=c43 m10110=c983c918d4e866dcdeda252bfba111ad|f=484/10
  #|or qword ptr [rdi + r9*2 - 0x4], 0x1|4a834c4ffc01|OR64mi8:%RDI,2,%R9,-4,%,1|rbx=0 r9=5 f=82 m10106=8491a1ec62ec09b89cd9d4dd7e23a075|f=80/10 m10106=85
  #|adc r10b, r9b|4510ca|ADC8rr:%R10B,%R10B,%R9B|r9=c9 r10=c f=886|r10=d5 f=90/0
  #|adc r10b, r9b|4510ca|ADC8rr:%R10B,%R10B,%R9B|r9=63ca35ee4b888000 r10=8abb67d9ce4d3e55 f=c3|r10=8abb67d9ce4d3e56 f=4/0
  #|adc al, r15b|4410f8|ADC8rr:%AL,%AL,%R15B|rax=ffff r15=e580092ee4db4f03 f=87|rax=ff03 f=15/0
  #|adc al, r15b|4410f8|ADC8rr:%AL,%AL,%R15B|rax=80deff567fffffff r15=b17c7f0fc96e1598 f=c3|rax=80deff567fffff98 f=91/0
  #|adc byte ptr [rsi + rbx*4 + 0x8], dl|10549e08|ADC8mr:%RSI,4,%RBX,8,%,%DL|rdx=7108b353c5fc30a rbx=c r9=8 f=cd2 m100b8=954433f8a83c8100c0fff191b6a402a8|f=484/0 m100b8=9f
  #|adc byte ptr [rsi + rbx*4 + 0x8], dl|10549e08|ADC8mr:%RSI,4,%RBX,8,%,%DL|rdx=4389120df4d4981e rbx=d r9=f f=c6 m100bc=9a35eb0a6ccabd63e1ebc9417105d066|f=94/0 m100bc=b8
  #|adc dl, byte ptr [rbp - 0x20]|1255e0|ADC8rm:%DL,%DL,%RBP,1,%,-32,%|rdx=b rbx=f r9=e f=92 m20160=3989f063d4ace73c1307ec3387fe22ea|rdx=44 f=14/0
  #|adc dl, byte ptr [rbp - 0x20]|1255e0|ADC8rm:%DL,%DL,%RBP,1,%,-32,%|rdx=91fcf6d40e0a0372 rbx=0 r9=d f=7 m20160=1383f833ebc72ec932d9ef0a9801ff7d|rdx=91fcf6d40e0a0386 f=880/0
  #|adc dl, 0x7f|80d27f|ADC8ri:%DL,%DL,127|rdx=b0fa f=893|rdx=b07a f=11/0
  #|adc dl, 0x7f|80d27f|ADC8ri:%DL,%DL,127|rdx=5f f=8d7|rdx=df f=890/0
  #|adc dl, 0x1|80d201|ADC8ri:%DL,%DL,1|rdx=7503098ad7cbaed0 f=d3|rdx=7503098ad7cbaed2 f=84/0
  #|adc dl, 0x1|80d201|ADC8ri:%DL,%DL,1|rdx=3 f=442|rdx=4 f=400/0
  #|adc al, 0xff|14ff|ADC8i8:-1|rax=decea617f025b34b f=403|f=415/0
  #|adc al, 0xff|14ff|ADC8i8:-1|rax=8000000000000000 f=3|f=55/0
  #|adc byte ptr [rbp - 0x20], -0x3|8055e0fd|ADC8mi:%RBP,1,%,-32,%,-3|rbx=b r9=6 f=96 m20160=c9766458a65075d736c3b78614878393|f=95/0 m20160=c6
  #|adc byte ptr [rbp - 0x20], -0x3|8055e0fd|ADC8mi:%RBP,1,%,-32,%,-3|rbx=4 r9=0 f=892 m20160=64a497eda91116f0af74604816e830ad|f=11/0 m20160=61
  #|adc dx, ax|6611c2|ADC16rr:%DX,%DX,%AX|rax=1d85e92e56edfa86 rdx=d95046def67476b6 f=cd3|rdx=d95046def674713d f=401/0
  #|adc dx, ax|6611c2|ADC16rr:%DX,%DX,%AX|rax=52babac8c76c5e8c rdx=12ea9e87d9064277 f=807|rdx=12ea9e87d906a104 f=890/0
  #|adc r9w, bx|664111d9|ADC16rr:%R9W,%R9W,%BX|rbx=514c04d5fd62efa0 r9=4ad995e037eec96f f=843|r9=4ad995e037eeb910 f=91/0
  #|adc r9w, bx|664111d9|ADC16rr:%R9W,%R9W,%BX|rbx=8000 r9=7fffffff f=86|r9=7fff7fff f=805/0
  #|adc word ptr [rsi + rbx*4 + 0x8], r11w|6644115c9e08|ADC16mr:%RSI,4,%RBX,8,%,%R11W|rbx=4 r9=7 r11=80000000 f=97 m10098=7990a2c9da5f041c96808171077c151d|f=80/0 m10098=7a
  #|adc word ptr [rsi + rbx*4 + 0x8], r11w|6644115c9e08|ADC16mr:%RSI,4,%RBX,8,%,%R11W|rbx=7 r9=1 r11=d616b53404f73a5f f=c92 m100a4=6987ad704b6b0a2a07f537ad7c281686|f=490/0 m100a4=c8c1
  #|adc r11w, word ptr [rbp - 0x20]|6644135de0|ADC16rm:%R11W,%R11W,%RBP,1,%,-32,%|rbx=a r9=6 r11=9101895d77c50d7d f=8c3 m20160=a8d6efc94a9f9e4fde07dfadbd38d10d|r11=9101895d77c5e426 f=90/0
  #|adc r11w, word ptr [rbp - 0x20]|6644135de0|ADC16rm:%R11W,%R11W,%RBP,1,%,-32,%|rbx=1 r9=7 r11=73b69d8aeee50b50 f=4c6 m20160=025b84892cdfe6019051141b954dcd0f|r11=73b69d8aeee56652 f=400/0
  #|adc r8w, 0x1|664183d001|ADC16ri8:%R8W,%R8W,1|r8=7fffffffffffffff f=d2|r8=7fffffffffff0000 f=55/0
  #|adc r8w, 0x1|664183d001|ADC16ri8:%R8W,%R8W,1|r8=9866fa246807ee2e f=87|r8=9866fa246807ee30 f=94/0
  #|adc r8w, 0x1234|664181d03412|ADC16ri:%R8W,%R8W,4660|r8=e808c974ac32801d f=857|r8=e808c974ac329252 f=90/0
  #|adc r8w, 0x1234|664181d03412|ADC16ri:%R8W,%R8W,4660|r8=debff62cb61aa4b6 f=802|r8=debff62cb61ab6ea f=80/0
  #|adc ax, 0x100|66150001|ADC16i16:256|rax=8e19978a9ac293f1 f=8d7|rax=8e19978a9ac294f2 f=80/0
  #|adc ax, 0x100|66150001|ADC16i16:256|rax=8b561909ded1fb39 f=4d6|rax=8b561909ded1fc39 f=484/0
  #|adc word ptr [rsi + rbx*4 + 0x8], 0x7f|6683549e087f|ADC16mi8:%RSI,4,%RBX,8,%,127|rbx=b r9=1 f=13 m100b4=1a3908e69940786f9b430c4ea6954edc|f=14/0 m100b4=9a
  #|adc word ptr [rsi + rbx*4 + 0x8], 0x7f|6683549e087f|ADC16mi8:%RSI,4,%RBX,8,%,127|rbx=6 r9=5 f=d2 m100a0=35c2d55a2d95e508f3dc870cd53760d9|f=94/0 m100a0=b4
  #|adc ebx, edx|11d3|ADC32rr:%EBX,%EBX,%EDX|rdx=72b5d762ff3728de rbx=9f56 f=807|rbx=ff37c835 f=94/0
  #|adc ebx, edx|11d3|ADC32rr:%EBX,%EBX,%EDX|rdx=49a6254f5daefed2 rbx=ddaf4ee987ed7437 f=897|rbx=e59c730a f=84/0
  #|adc r14d, edx|4111d6|ADC32rr:%R14D,%R14D,%EDX|rdx=aad521c8ffffffff r14=11e336cae1b8900 f=43|r14=ae1b8900 f=95/0
  #|adc r14d, edx|4111d6|ADC32rr:%R14D,%R14D,%EDX|rdx=43bcf9c71771dd1 r14=8000000000000000 f=812|r14=71771dd1 f=4/0
  #|adc dword ptr [rbp - 0x20], r13d|44116de0|ADC32mr:%RBP,1,%,-32,%,%R13D|rbx=4 r9=d r13=372310286efc79a5 f=c42 m20160=25a46e0418ed5b3db00074be9d704729|f=404/0 m20160=ca1d6b73
  #|adc dword ptr [rbp - 0x20], r13d|44116de0|ADC32mr:%RBP,1,%,-32,%,%R13D|rbx=a r9=4 r13=ca f=897 m20160=a51a1abcac6b81c96999e2334f433827|f=90/0 m20160=701b
  #|adc r13d, dword ptr [rsp + 0x8]|44136c2408|ADC32rm:%R13D,%R13D,%RSP,1,%,8,%|rbx=2 r9=d r13=73 f=93 m20108=6169aceff695ecae089724d1b75229b9|r13=efac69d5 f=80/0
  #|adc r13d, dword ptr [rsp + 0x8]|44136c2408|ADC32rm:%R13D,%R13D,%RSP,1,%,8,%|rbx=4 r9=e r13=c f=97 m20108=c37723be46a8f18b8561f7b7f39f93bb|r13=be2377d0 f=90/0
  #|adc edx, 0x0|83d200|ADC32ri8:%EDX,%EDX,0|rdx=923769a2f19aa39b f=8c3|rdx=f19aa39c f=84/0
  #|adc edx, 0x0|83d200|ADC32ri8:%EDX,%EDX,0|rdx=ed30b8a9b94f331c f=8d3|rdx=b94f331d f=84/0
  #|adc edx, 0x80|81d280000000|ADC32ri:%EDX,%EDX,128|rdx=1233f030002d1961 f=d7|rdx=2d19e2 f=4/0
  #|adc edx, 0x80|81d280000000|ADC32ri:%EDX,%EDX,128|rdx=cc f=93|rdx=14d f=4/0
  #|adc eax, 0x80|1580000000|ADC32i32:128|rax=c3 f=493|rax=144 f=404/0
  #|adc eax, 0x80|1580000000|ADC32i32:128|rax=83216e948b9d1b79 f=92|rax=8b9d1bf9 f=84/0
  #|adc dword ptr [rbp - 0x20], -0x80|8355e080|ADC32mi8:%RBP,1,%,-32,%,-128|rbx=6 r9=6 f=443 m20160=ad8bd53c31c9354030ddfcb98da70713|f=405/0 m20160=2e
  #|adc dword ptr [rbp - 0x20], -0x80|8355e080|ADC32mi8:%RBP,1,%,-32,%,-128|rbx=d r9=0 f=846 m20160=613308e1e91b2577fbb23d9009d8c0a7|f=85/0 m20160=e132
  #|adc r11, r14|4d11f3|ADC64rr:%R11,%R11,%R14|r11=9654e420f98ed63b r14=558d21d35ceb8133 f=7|r11=ebe205f4567a576f f=84/0
  #|adc r11, r14|4d11f3|ADC64rr:%R11,%R11,%R14|r11=8 r14=b05b78aa53e054b3 f=cc7|r11=b05b78aa53e054bc f=480/0
  #|adc r15, rbx|4911df|ADC64rr:%R15,%R15,%RBX|rbx=5 r15=d900dcbc13ad1d77 f=82|r15=d900dcbc13ad1d7c f=80/0
  #|adc r15, rbx|4911df|ADC64rr:%R15,%R15,%RBX|rbx=6 r15=be f=d2|r15=c4 f=10/0
  #|adc qword ptr [rsi + rbx*4 + 0x8], r9|4c114c9e08|ADC64mr:%RSI,4,%RBX,8,%,%R9|rbx=2 r9=0 f=87 m10090=36d61eccbff397a80f687675f0b2a8d9|f=80/0 m10090=37
  #|adc qword ptr [rsi + rbx*4 + 0x8], r9|4c114c9e08|ADC64mr:%RSI,4,%RBX,8,%,%R9|rbx=0 r9=9 f=13 m10088=e4fbcf5af6596e9335073cc1cb73e67a|f=84/0 m10088=ee
  #|adc r9, qword ptr [rbp - 0x20]|4c134de0|ADC64rm:%R9,%R9,%RBP,1,%,-32,%|rbx=a r9=3 f=883 m20160=a95c1c114d3f32cb9aafe935be09e26b|r9=cb323f4d111c5cad f=80/0
  #|adc r9, qword ptr [rbp - 0x20]|4c134de0|ADC64rm:%R9,%R9,%RBP,1,%,-32,%|rbx=b r9=d f=12 m20160=6964fbaa1de3980e7db18911959d8476|r9=e98e31daafb6476 f=10/0
  #|adc r12, 0x7f|4983d47f|ADC64ri8:%R12,%R12,127|r12=6bc1a271631e3e11 f=c6|r12=6bc1a271631e3e90 f=14/0
  #|adc r12, 0x7f|4983d47f|ADC64ri8:%R12,%R12,127|r12=94e24295879e34cd f=93|r12=94e24295879e354d f=94/0
  #|adc r12, -0x80000000|4981d400000080|ADC64ri32:%R12,%R12,-2147483648|r12=9ce8e75f68708dc8 f=802|r12=9ce8e75ee8708dc8 f=81/0
  #|adc r12, -0x80000000|4981d400000080|ADC64ri32:%R12,%R12,-2147483648|r12=5ee6 f=cd2|r12=ffffffff80005ee6 f=480/0
  #|adc rax, 0x7fffffff|4815ffffff7f|ADC64i32:2147483647|rax=9b17492007ef2f1a f=96|rax=9b17492087ef2f19 f=90/0
  #|adc rax, 0x7fffffff|4815ffffff7f|ADC64i32:2147483647|rax=e989d9e103abee62 f=406|rax=e989d9e183abee61 f=490/0
  #|adc qword ptr [rdi + r9*2 - 0x4], 0x0|4a83544ffc00|ADC64mi8:%RDI,2,%R9,-4,%,0|rbx=8 r9=b f=43 m10112=6a74b930e3e27951b77d9020265bc43d|f=0/0 m10112=6b
  #|adc qword ptr [rdi + r9*2 - 0x4], 0x0|4a83544ffc00|ADC64mi8:%RDI,2,%R9,-4,%,0|rbx=4 r9=4 f=c7 m10104=a9d81736386e6138e7ed5c45a7d8ea67|f=4/0 m10104=aa
  #|sbb r9b, dl|4118d1|SBB8rr:%R9B,%R9B,%DL|rdx=588809f62f8f0668 r9=f8de f=8c6|r9=f876 f=800/0
  #|sbb r9b, dl|4118d1|SBB8rr:%R9B,%R9B,%DL|rdx=412f45fb02ed1e98 r9=3c57a58376f44db7 f=47|r9=3c57a58376f44d1e f=14/0
  #|sbb r13b, r15b|4518fd|SBB8rr:%R13B,%R13B,%R15B|r13=4df2451307ac8e49 r15=bccf525d43147732 f=47|r13=4df2451307ac8e16 f=0/0
  #|sbb r13b, r15b|4518fd|SBB8rr:%R13B,%R13B,%R15B|r13=5e32537a9f99e7b9 r15=67bb35b0ad388a58 f=486|r13=5e32537a9f99e761 f=c00/0
  #|sbb byte ptr [rdi + r9*2 - 0x4], r10b|4618544ffc|SBB8mr:%RDI,2,%R9,-4,%,%R10B|rbx=f r9=3 r10=327f60cba60cd723 f=8d7 m10102=124627bd5734499e1d26259bf3a1277f|f=95/0 m10102=ee
  #|sbb byte ptr [rdi + r9*2 - 0x4], r10b|4618544ffc|SBB8mr:%RDI,2,%R9,-4,%,%R10B|rbx=5 r9=8 r10=2ce07442a2f8ec9d f=c6 m1010c=6a894a17113698dee5b35a15e6af06ce|f=891/0 m1010c=cd
  #|sbb r10b, byte ptr [rbp - 0x20]|441a55e0|SBB8rm:%R10B,%R10B,%RBP,1,%,-32,%|rbx=e r9=1 r10=55263e5bb3dd898 f=896 m20160=abd27285da8411f2066e08acb93bcf35|r10=55263e5bb3dd8ed f=95/0
  #|sbb r10b, byte ptr [rbp - 0x20]|441a55e0|SBB8rm:%R10B,%R10B,%RBP,1,%,-32,%|rbx=0 r9=8 r10=3472f061c4070580 f=96 m20160=29523dd34744a2ad1f0ee2bc4b252c47|r10=3472f061c4070557 f=810/0
  #|sbb r8b, 0x0|4180d800|SBB8ri:%R8B,%R8B,0|r8=3ac6 f=842|f=84/0
  #|sbb r8b, 0x0|4180d800|SBB8ri:%R8B,%R8B,0|r8=f7448e9b1bd7f82c f=cd3|r8=f7448e9b1bd7f82b f=404/0
  #|sbb r8b, 0x1|4180d801|SBB8ri:%R8B,%R8B,1|r8=d8e64bdaffffffff f=816|r8=d8e64bdafffffffe f=80/0
  #|sbb r8b, 0x1|4180d801|SBB8ri:%R8B,%R8B,1|r8=9df49572404ec74b f=886|r8=9df49572404ec74a f=0/0
  #|sbb al, 0x7f|1c7f|SBB8i8:127|rax=100 f=813|rax=180 f=91/0
  #|sbb al, 0x7f|1c7f|SBB8i8:127|rax=ffffffff f=83|rax=ffffff7f f=810/0
  #|sbb byte ptr [rsi + rbx*4 + 0x8], 0x7f|805c9e087f|SBB8mi:%RSI,4,%RBX,8,%,127|rbx=7 r9=8 f=803 m100a4=055870cbda3efb1063c7d4106c829793|f=91/0 m100a4=85
  #|sbb byte ptr [rsi + rbx*4 + 0x8], 0x7f|805c9e087f|SBB8mi:%RSI,4,%RBX,8,%,127|rbx=8 r9=b f=c3 m100a8=9c90997dd7b8930e1f87f333c8172dde|f=810/0 m100a8=1c
  #|sbb r8w, r12w|664519e0|SBB16rr:%R8W,%R8W,%R12W|r8=ffffffffffffffff r12=b8967452aa46ff15 f=8d6|r8=ffffffffffff00ea f=0/0
  #|sbb r8w, r12w|664519e0|SBB16rr:%R8W,%R8W,%R12W|r8=34f6a1ab01dc188e r12=ce311f2a8c1678b1 f=803|r8=34f6a1ab01dc9fdc f=81/0
  #|sbb dx, r9w|664419ca|SBB16rr:%DX,%DX,%R9W|rdx=f9 r9=91fb8270353b2b4 f=86|rdx=4e45 f=1/0
  #|sbb dx, r9w|664419ca|SBB16rr:%DX,%DX,%R9W|rdx=b80c r9=75211e42aca79fc5 f=d2|rdx=1847 f=4/0
  #|sbb word ptr [rsi], r8w|66441906|SBB16mr:%RSI,1,%,0,%,%R8W|rbx=a r8=faeab3eb7fffffff r9=0 f=83 m10080=cf8f4c00d08ff5551f98b0fde1e3101d|f=95/0
  #|sbb word ptr [rsi], r8w|66441906|SBB16mr:%RSI,1,%,0,%,%R8W|rbx=2 r8=fd660736ca524be r9=8 f=53 m10080=5f1acb287f97a0bc03b2ca0870724286|f=85/0 m10080=a0f5
  #|sbb r8w, word ptr [rdi + r9*2 - 0x4]|66461b444ffc|SBB16rm:%R8W,%R8W,%RDI,2,%R9,-4,%|rbx=f r8=de9452f7eb49d101 r9=4 f=d7 m10104=62972517fd158542e48663b545a9ae65|r8=de9452f7eb49399e f=10/0
  #|sbb r8w, word ptr [rdi + r9*2 - 0x4]|66461b444ffc|SBB16rm:%R8W,%R8W,%RDI,2,%R9,-4,%|rbx=f r8=8666a28dfd1c271b r9=e f=8d3 m10118=40e890690ac464f1d3a8595a7c7adc66|r8=8666a28dfd1c3eda f=1/0
  #|sbb r10w, 0x1|664183da01|SBB16ri8:%R10W,%R10W,1|r10=e f=453|r10=c f=404/0
  #|sbb r10w, 0x1|664183da01|SBB16ri8:%R10W,%R10W,1|r10=16074e1bb2ccffff f=8d6|r10=16074e1bb2ccfffe f=80/0
  #|sbb r10w, 0xffff|664183daff|SBB16ri8:%R10W,%R10W,-1|r10=1d45da3a4ffc7c81 f=883|f=15/0
  #|sbb r10w, 0xffff|664183daff|SBB16ri8:%R10W,%R10W,-1|r10=10504604d33e2dc5 f=92|r10=10504604d33e2dc6 f=15/0
  #|sbb ax, 0x8000|661d0080|SBB16i16:32768|rax=fb2760e9e4a3953c f=87|rax=fb2760e9e4a3153b f=0/0
  #|sbb ax, 0x8000|661d0080|SBB16i16:32768|rax=803777ee06f8257 f=86|rax=803777ee06f0257 f=0/0
  #|sbb word ptr [rsi], 0x5|66831e05|SBB16mi8:%RSI,1,%,0,%,5|rbx=e r9=e f=86 m10080=4a77ed9511264ca4b6cdd580c3e075d4|f=0/0 m10080=45
  #|sbb word ptr [rsi], 0x5|66831e05|SBB16mi8:%RSI,1,%,0,%,5|rbx=8 r9=b f=8c7 m10080=f8c02312f11314d7c45a6934eeeffe90|f=80/0 m10080=f2
  #|sbb ebx, r11d|4419db|SBB32rr:%EBX,%EBX,%R11D|rbx=ad r11=4b40604f9f21c98d f=d3|rbx=60de371f f=11/0
  #|sbb ebx, r11d|4419db|SBB32rr:%EBX,%EBX,%R11D|rbx=32e61f0880000000 r11=b762 f=43|rbx=7fff489d f=810/0
  #|sbb eax, edx|19d0|SBB32rr:%EAX,%EAX,%EDX|rax=699d7b2342832742 rdx=38aa9e7ea8c24a80 f=847|rax=99c0dcc1 f=881/0
  #|sbb eax, edx|19d0|SBB32rr:%EAX,%EAX,%EDX|rax=1 rdx=1 f=c12|rax=0 f=444/0
  #|sbb dword ptr [rbp - 0x20], edx|1955e0|SBB32mr:%RBP,1,%,-32,%,%EDX|rdx=55cb02aff7edac7e rbx=f r9=9 f=47 m20160=dccafa61dae9cbcdc712c133f3708566|f=11/0 m20160=5d1e0d6a
  #|sbb dword ptr [rbp - 0x20], edx|1955e0|SBB32mr:%RBP,1,%,-32,%,%EDX|rdx=af98f9ba8140a1a rbx=c r9=4 f=d6 m20160=0f04071cec31fa879b66d647dae6394e|f=5/0 m20160=f5f9f273
  #|sbb edx, dword ptr [rsi + rbx*4 + 0x8]|1b549e08|SBB32rm:%EDX,%EDX,%RSI,4,%RBX,8,%|rdx=60caf755a632823 rbx=a r9=a f=c7 m100b0=0c6b67bacf6a8ca434a8b56602863627|rdx=9ffbbd16 f=891/0
  #|sbb edx, dword ptr [rsi + rbx*4 + 0x8]|1b549e08|SBB32rm:%EDX,%EDX,%RSI,4,%RBX,8,%|rdx=dfcd2cad6c45454 rbx=2 r9=3 f=86 m10090=b6cf1ec4cbb6b2a35094615931b4bbd1|rdx=12a5849e f=10/0
  #|sbb r9d, 0x1|4183d901|SBB32ri8:%R9D,%R9D,1|r9=7fff f=417|r9=7ffd f=400/0
  #|sbb r9d, 0x1|4183d901|SBB32ri8:%R9D,%R9D,1|r9=bc2f4ba85fa08680 f=812|r9=5fa0867f f=10/0
  #|sbb r9d, 0x80|4181d980000000|SBB32ri:%R9D,%R9D,128|r9=bd77493b0e646954 f=16|r9=e6468d4 f=4/0
  #|sbb r9d, 0x80|4181d980000000|SBB32ri:%R9D,%R9D,128|r9=e f=8c3|r9=ffffff8d f=85/0
  #|sbb eax, -0x80000000|1d00000080|SBB32i32:2147483648|rax=b1e6efa280000000 f=86|rax=0 f=44/0
  #|sbb eax, -0x80000000|1d00000080|SBB32i32:2147483648|rax=8000000000000000 f=802|rax=80000000 f=885/0
  #|sbb dword ptr [rsi], -0x1|831eff|SBB32mi8:%RSI,1,%,0,%,-1|rbx=b r9=d f=893 m10080=dc7b28177cb82f823055847455c5c733|f=11/0
  #|sbb dword ptr [rsi], -0x1|831eff|SBB32mi8:%RSI,1,%,0,%,-1|rbx=b r9=2 f=d6 m10080=d44b012bf979e7117f62fceb383bd6a6|f=11/0 m10080=d5
  #|sbb rax, rdx|4819d0|SBB64rr:%RAX,%RAX,%RDX|rax=80000000 rdx=d28b0253ef30f030 f=8d3|rax=2d74fdac90cf0fcf f=15/0
  #|sbb rax, rdx|4819d0|SBB64rr:%RAX,%RAX,%RDX|rax=a9680577d0a69807 rdx=451b6e449717870e f=16|rax=644c9733398f10f9 f=814/0
  #|sbb rbx, r15|4c19fb|SBB64rr:%RBX,%RBX,%R15|rbx=ce92226c56829ab0 r15=2e60ea1e6a9f6e11 f=93|rbx=a031384debe32c9e f=90/0
  #|sbb rbx, r15|4c19fb|SBB64rr:%RBX,%RBX,%R15|rbx=72592e7303a31bda r15=39d77c6f1d2bfde0 f=8c6|rbx=3881b203e6771dfa f=4/0
  #|sbb qword ptr [rsi], r9|4c190e|SBB64mr:%RSI,1,%,0,%,%R9|rbx=6 r9=6 f=483 m10080=aa283ea6c084d402ba8071b4fcf6d132|f=404/0 m10080=a3
  #|sbb qword ptr [rsi], r9|4c190e|SBB64mr:%RSI,1,%,0,%,%R9|rbx=7 r9=6 f=d2 m10080=51a2b2282cab1870780e37c565da4148|f=14/0 m10080=4b
  #|sbb r9, qword ptr [rdi + r9*2 - 0x4]|4e1b4c4ffc|SBB64rm:%R9,%R9,%RDI,2,%R9,-4,%|rbx=3 r9=1 f=93 m100fe=22c1d4eed8e23acfd9773a94e2fcfc31|r9=30c51d27112b3ede f=15/0
  #|sbb r9, qword ptr [rdi + r9*2 - 0x4]|4e1b4c4ffc|SBB64rm:%R9,%R9,%RDI,2,%R9,-4,%|rbx=8 r9=1 f=2 m100fe=46c7c4d926d714a641406e5fa8440656|r9=59eb28d9263b38bb f=15/0
  #|sbb rcx, -0x80|4883d980|SBB64ri8:%RCX,%RCX,-128|rcx=e7a3e181a4fb5cdd f=cd7|rcx=e7a3e181a4fb5d5c f=485/0
  #|sbb rcx, -0x80|4883d980|SBB64ri8:%RCX,%RCX,-128|rcx=e16e0b6440bc7d f=57|rcx=e16e0b6440bcfc f=5/0
  #|sbb rcx, -0x100|4881d900ffffff|SBB64ri32:%RCX,%RCX,-256|rcx=f f=46|rcx=10f f=5/0
  #|sbb rcx, -0x100|4881d900ffffff|SBB64ri32:%RCX,%RCX,-256|rcx=1 f=8c6|rcx=101 f=1/0
  #|sbb rax, -0x100|481d00ffffff|SBB64i32:-256|rax=fffffffffffffffe f=6|rax=fe f=0/0
  #|sbb rax, -0x100|481d00ffffff|SBB64i32:-256|rax=ca09138bdf567fff f=8d7|rax=ca09138bdf5680fe f=81/0
  #|sbb qword ptr [rdi + r9*2 - 0x4], 0x7f|4a835c4ffc7f|SBB64mi8:%RDI,2,%R9,-4,%,127|rbx=0 r9=e f=8c7 m10118=ae5e1ef44b5ad0b83f58baaa97ae6c79|f=94/0 m10118=2e
  #|sbb qword ptr [rdi + r9*2 - 0x4], 0x7f|4a835c4ffc7f|SBB64mi8:%RDI,2,%R9,-4,%,127|rbx=0 r9=c f=453 m10114=ac970a9d115e5040c14cfb70ae4bc8cb|f=410/0 m10114=2c
  #|and al, cl|20c8|AND8rr:%AL,%AL,%CL|rax=100 rcx=f09264ec9e1707e8 f=8d2|f=44/10
  #|and al, cl|20c8|AND8rr:%AL,%AL,%CL|rax=3d88450b4c3523d6 rcx=6ef4ddc88f3eb05b f=807|rax=3d88450b4c352352 f=0/10
  #|and dl, bl|20da|AND8rr:%DL,%DL,%BL|rdx=7fff rbx=612a77c4b4a9b459 f=492|rdx=7f59 f=404/10
  #|and dl, bl|20da|AND8rr:%DL,%DL,%BL|rdx=cd45970872c1ebf0 rbx=ce6385a7fda323de f=816|rdx=cd45970872c1ebd0 f=80/10
  #|and byte ptr [rsi], r13b|44202e|AND8mr:%RSI,1,%,0,%,%R13B|rbx=9 r9=8 r13=2b8bcd06686c91f3 f=86 m10080=6380858c451a2305382704b3b63ce7c4|f=4/10
  #|and byte ptr [rsi], r13b|44202e|AND8mr:%RSI,1,%,0,%,%R13B|rbx=2 r9=b r13=7fffffffffffffff f=97 m10080=7b7fef8a62c1a26c79bc8e37e902f005|f=4/10
  #|and r13b, byte ptr [rsi + rbx*4 + 0x8]|44226c9e08|AND8rm:%R13B,%R13B,%RSI,4,%RBX,8,%|rbx=4 r9=1 r13=aa f=97 m10098=afaab0a94bcd5d48ff59c5b58497dc4c|f=84/10
  #|and r13b, byte ptr [rsi + rbx*4 + 0x8]|44226c9e08|AND8rm:%R13B,%R13B,%RSI,4,%RBX,8,%|rbx=2 r9=8 r13=9e4df6cb65c4d912 f=8c2 m10090=b94df1e63249fc91e710878786c4886b|r13=9e4df6cb65c4d910 f=0/10
  #|and r10b, 0x1|4180e201|AND8ri:%R10B,%R10B,1|r10=80000000 f=843|f=44/10
  #|and r10b, 0x1|4180e201|AND8ri:%R10B,%R10B,1|r10=38d8 f=807|r10=3800 f=44/10
  #|and r10b, 0x7f|4180e27f|AND8ri:%R10B,%R10B,127|r10=6863049fcb95b947 f=46|f=4/10
  #|and r10b, 0x7f|4180e27f|AND8ri:%R10B,%R10B,127|r10=9e f=97|r10=1e f=4/10
  #|and al, 0x5a|245a|AND8i8:90|rax=58e986b43b1a9d48 f=cc3|f=404/10
  #|and al, 0x5a|245a|AND8i8:90|rax=c04c8327e3175f38 f=806|rax=c04c8327e3175f18 f=4/10
  #|and byte ptr [rbp - 0x20], 0x5|8065e005|AND8mi:%RBP,1,%,-32,%,5|rbx=a r9=e f=806 m20160=fa5f0d5ecd8d86dcbe190dfa4622a242|f=44/10 m20160=00
  #|and byte ptr [rbp - 0x20], 0x5|8065e005|AND8mi:%RBP,1,%,-32,%,5|rbx=b r9=1 f=53 m20160=a26b024b025958be8b6d493c325f72b0|f=44/10 m20160=00
  #|and dx, bx|6621da|AND16rr:%DX,%DX,%BX|rdx=ffffffffffffffff rbx=780ec224c3a329b3 f=17|rdx=ffffffffffff29b3 f=0/10
  #|and dx, bx|6621da|AND16rr:%DX,%DX,%BX|rdx=d7ce001b6a9dd7e4 rbx=ffff f=8c7|f=84/10
  #|and r9w, r12w|664521e1|AND16rr:%R9W,%R9W,%R12W|r9=142969f3ebd3c190 r12=10afabba9eac523a f=812|r9=142969f3ebd34010 f=0/10
  #|and r9w, r12w|664521e1|AND16rr:%R9W,%R9W,%R12W|r9=1 r12=69c1 f=87|f=0/10
  #|and word ptr [rsi], r10w|66442116|AND16mr:%RSI,1,%,0,%,%R10W|rbx=4 r9=e r10=92b5e03c8a399e80 f=c02 m10080=d527654c6e053e4e3f765f55859b9355|f=400/10 m10080=8006
  #|and word ptr [rsi], r10w|66442116|AND16mr:%RSI,1,%,0,%,%R10W|rbx=9 r9=6 r10=a776373ed506d986 f=3 m10080=382e5b262912b8a12181cd5cc041ce66|f=4/10 m10080=0008
  #|and r10w, word ptr [rdi + r9*2 - 0x4]|664623544ffc|AND16rm:%R10W,%R10W,%RDI,2,%R9,-4,%|rbx=5 r9=b r10=771f1cd9f2cdf52 f=46 m10112=59c8284eb0b1aad0408cb7b5333386d6|r10=771f1cd9f2cc850 f=84/10
  #|and r10w, word ptr [rdi + r9*2 - 0x4]|664623544ffc|AND16rm:%R10W,%R10W,%RDI,2,%R9,-4,%|rbx=3 r9=0 r10=c143042639c76c23 f=8c2 m100fc=361acb6851a4893139e17545f85aa42c|r10=c143042639c70822 f=4/10
  #|and r11w, 0x7f|664183e37f|AND16ri8:%R11W,%R11W,127|r11=1 f=8c2|f=0/10
  #|and r11w, 0x7f|664183e37f|AND16ri8:%R11W,%R11W,127|r11=aae79e25d05ef93d f=7|r11=aae79e25d05e003d f=0/10
  #|and r11w, 0x8000|664181e30080|AND16ri:%R11W,%R11W,32768|r11=c9e9cc7df90499a6 f=8c7|r11=c9e9cc7df9048000 f=84/10
  #|and r11w, 0x8000|664181e30080|AND16ri:%R11W,%R11W,32768|r11=a79932fb68127fff f=13|r11=a79932fb68120000 f=44/10
  #|and ax, 0x8000|66250080|AND16i16:32768|rax=101a71de17b1c4f f=53|rax=101a71de17b0000 f=44/10
  #|and ax, 0x8000|66250080|AND16i16:32768|rax=97c f=882|rax=0 f=44/10
  #|and word ptr [rdi + 0x10], 0x7f|668367107f|AND16mi8:%RDI,1,%,16,%,127|rbx=e r9=9 f=16 m10110=7e67bf5ee51e64ccbf70b98f481d1c6e|f=4/10 m10111=00
  #|and word ptr [rdi + 0x10], 0x7f|668367107f|AND16mi8:%RDI,1,%,16,%,127|rbx=9 r9=c f=12 m10110=72da5348ced5e85fdafa673c89ffd50c|f=4/10 m10111=00
  #|and r9d, r11d|4521d9|AND32rr:%R9D,%R9D,%R11D|r9=4373f86b3cf81bb5 r11=3cf3f24277258268 f=43|r9=34200220 f=0/10
  #|and r9d, r11d|4521d9|AND32rr:%R9D,%R9D,%R11D|r9=ae184acf801ced25 r11=a161f99c9e581543 f=97|r9=80180501 f=80/10
  #|and r13d, r11d|4521dd|AND32rr:%R13D,%R13D,%R11D|r11=ffffffffffffffff r13=f84e1ed152efb3f2 f=882|r13=52efb3f2 f=0/10
  #|and r13d, r11d|4521dd|AND32rr:%R13D,%R13D,%R11D|r11=cbf54877243d9ea5 r13=ffffffff f=c92|r13=243d9ea5 f=404/10
  #|and dword ptr [rdi + 0x10], r9d|44214f10|AND32mr:%RDI,1,%,16,%,%R9D|rbx=a r9=7 f=8c3 m10110=e5422a5d9b2432b1c7cccb1f08d5d6b6|f=4/10 m10110=05000000
  #|and dword ptr [rdi + 0x10], r9d|44214f10|AND32mr:%RDI,1,%,16,%,%R9D|rbx=0 r9=3 f=86 m10110=1cb2f5da313d5b9ec5c297c6a69cb5fa|f=44/10 m10110=00000000
  #|and r9d, dword ptr [rdi + 0x10]|44234f10|AND32rm:%R9D,%R9D,%RDI,1,%,16,%|rbx=0 r9=a f=403 m10110=ac76a7b4b13edaafff25160bd4dc795e|r9=8 f=400/10
  #|and r9d, dword ptr [rdi + 0x10]|44234f10|AND32rm:%R9D,%R9D,%RDI,1,%,16,%|rbx=7 r9=e f=c17 m10110=b87704753f86427c74d151f8dfb1384b|r9=8 f=400/10
  #|and r13d, -0x80|4183e580|AND32ri8:%R13D,%R13D,-128|r13=74be2ba42d4268d9 f=8d7|r13=2d426880 f=0/10
  #|and r13d, -0x80|4183e580|AND32ri8:%R13D,%R13D,-128|r13=100 f=42|f=4/10
  #|and r13d, 0x7fffffff|4181e5ffffff7f|AND32ri:%R13D,%R13D,2147483647|r13=b2 f=93|f=4/10
  #|and r13d, 0x7fffffff|4181e5ffffff7f|AND32ri:%R13D,%R13D,2147483647|r13=38a5781a7f797fff f=8c3|r13=7f797fff f=4/10
  #|and eax, -0x100|2500ffffff|AND32i32:4294967040|rax=d16eceafbddf7fff f=8c6|rax=bddf7f00 f=84/10
  #|and eax, -0x100|2500ffffff|AND32i32:4294967040|rax=100 f=16|f=4/10
  #|and dword ptr [rdi + r9*2 - 0x4], -0x80|4283644ffc80|AND32mi8:%RDI,2,%R9,-4,%,-128|rbx=8 r9=7 f=487 m1010a=c4ab02501811a98b5cbebf1baff08448|f=400/10 m1010a=80
  #|and dword ptr [rdi + r9*2 - 0x4], -0x80|4283644ffc80|AND32mi8:%RDI,2,%R9,-4,%,-128|rbx=1 r9=6 f=56 m10108=5bc9ec631b9df734dc0c1cd8bee8e59c|f=4/10 m10108=00
  #|and rax, r8|4c21c0|AND64rr:%RAX,%RAX,%R8|rax=f88e1a1b1b9e31ab r8=579793ea575aa96c f=897|rax=5086120a131a2128 f=4/10
  #|and rax, r8|4c21c0|AND64rr:%RAX,%RAX,%R8|rax=40dba10b374e6a21 r8=7fffffffffffffff f=893|f=4/10
  #|and rbx, r13|4c21eb|AND64rr:%RBX,%RBX,%R13|rbx=1cd5db1e2cb974c1 r13=7fff f=93|rbx=74c1 f=0/10
  #|and rbx, r13|4c21eb|AND64rr:%RBX,%RBX,%R13|rbx=720800a94754b20a r13=8f45e2b1ae1a8000 f=817|rbx=20000a106108000 f=4/10
  #|and qword ptr [rsp + 0x8], r12|4c21642408|AND64mr:%RSP,1,%,8,%,%R12|rbx=0 r9=e r12=1a93245323f7fc95 f=16 m20108=6a7a1f69bd12977c27d487decc236ace|f=4/10 m20108=0078172111009318
  #|and qword ptr [rsp + 0x8], r12|4c21642408|AND64mr:%RSP,1,%,8,%,%R12|rbx=8 r9=5 r12=ffca f=842 m20108=26a48c6726469d19f52bdf11dd4426be|f=0/10 m20108=02 m2010a=000000000000
  #|and r12, qword ptr [rsi + rbx*4 + 0x8]|4c23649e08|AND64rm:%R12,%R12,%RSI,4,%RBX,8,%|rbx=b r9=9 r12=1 f=486 m100b4=117f595a75e67976d6449a95338b268b|f=400/10
  #|and r12, qword ptr [rsi + rbx*4 + 0x8]|4c23649e08|AND64rm:%R12,%R12,%RSI,4,%RBX,8,%|rbx=e r9=1 r12=846 f=857 m100c0=f42fbd92ba242997a928952f0184da53|r12=844 f=4/10
  #|and r8, -0x80|4983e080|AND64ri8:%R8,%R8,-128|r8=7f f=887|r8=0 f=44/10
  #|and r8, -0x80|4983e080|AND64ri8:%R8,%R8,-128|r8=ec3e2ce22d380921 f=47|r8=ec3e2ce22d380900 f=84/10
  #|and r8, 0x7fffffff|4981e0ffffff7f|AND64ri32:%R8,%R8,2147483647|r8=860025f9b9e777b1 f=92|r8=39e777b1 f=4/10
  #|and r8, 0x7fffffff|4981e0ffffff7f|AND64ri32:%R8,%R8,2147483647|r8=95eda6d01da0a2ff f=4d7|r8=1da0a2ff f=404/10
  #|and rax, 0x100|482500010000|AND64i32:256|rax=9d6c266f9cee1821 f=86|rax=0 f=44/10
  #|and rax, 0x100|482500010000|AND64i32:256|rax=cf31b599a6c4285c f=887|rax=0 f=44/10
  #|and qword ptr [rdi + 0x10], 0x0|4883671000|AND64mi8:%RDI,1,%,16,%,0|rbx=d r9=6 f=c57 m10110=9bb105a2c23c68ce58aef780a4628385|f=444/10 m10110=0000000000000000
  #|and qword ptr [rdi + 0x10], 0x0|4883671000|AND64mi8:%RDI,1,%,16,%,0|rbx=9 r9=9 f=d7 m10110=ba76d5da10e83d12a4213340b69d7830|f=44/10 m10110=0000000000000000
  #|sub r11b, dl|4128d3|SUB8rr:%R11B,%R11B,%DL|rdx=84f1837ca0e18e46 r11=1 f=807|r11=bb f=95/0
  #|sub r11b, dl|4128d3|SUB8rr:%R11B,%R11B,%DL|rdx=100 r11=3d f=c16|f=400/0
  #|sub bl, r8b|4428c3|SUB8rr:%BL,%BL,%R8B|rbx=25ac021190f1232c r8=ef6a3e693efc9d0e f=d7|rbx=25ac021190f1231e f=14/0
  #|sub bl, r8b|4428c3|SUB8rr:%BL,%BL,%R8B|rbx=ba07d8d8b87e4ba3 r8=ecb6 f=852|rbx=ba07d8d8b87e4bed f=95/0
  #|sub byte ptr [rsp + 0x8], bl|285c2408|SUB8mr:%RSP,1,%,8,%,%BL|rbx=0 r9=e f=886 m20108=5fc7e276f1ea7c208bad45397363c2b4|f=4/0
  #|sub byte ptr [rsp + 0x8], bl|285c2408|SUB8mr:%RSP,1,%,8,%,%BL|rbx=d r9=2 f=d2 m20108=3e6b2e9a91620749e576bd1d55225b96|f=0/0 m20108=31
  #|sub bl, byte ptr [rsi + rbx*4 + 0x8]|2a5c9e08|SUB8rm:%BL,%BL,%RSI,4,%RBX,8,%|rbx=a r9=b f=87 m100b0=e5ef63e92bf15801d624f7f1f66c220c|rbx=25 f=1/0
  #|sub bl, byte ptr [rsi + rbx*4 + 0x8]|2a5c9e08|SUB8rm:%BL,%BL,%RSI,4,%RBX,8,%|rbx=7 r9=3 f=8d6 m100a4=9b8f620bda27f0067abc03a7640cbc89|rbx=6c f=15/0
  #|sub r8b, 0x5|4180e805|SUB8ri:%R8B,%R8B,5|r8=e1 f=c03|r8=dc f=490/0
  #|sub r8b, 0x5|4180e805|SUB8ri:%R8B,%R8B,5|r8=d62666410d4df94b f=d7|r8=d62666410d4df946 f=0/0
  #|sub r8b, 0x80|4180e880|SUB8ri:%R8B,%R8B,-128|r8=6366881da9fd699e f=86|r8=6366881da9fd691e f=4/0
  #|sub r8b, 0x80|4180e880|SUB8ri:%R8B,%R8B,-128|r8=fbfca66b9ab58fdb f=8d2|r8=fbfca66b9ab58f5b f=0/0
  #|sub al, 0x80|2c80|SUB8i8:-128|rax=7f f=8c3|rax=ff f=885/0
  #|sub al, 0x80|2c80|SUB8i8:-128|rax=7 f=52|rax=87 f=885/0
  #|sub byte ptr [rsi + rbx*4 + 0x8], -0x3|806c9e08fd|SUB8mi:%RSI,4,%RBX,8,%,-3|rbx=0 r9=7 f=d6 m10088=9f9a3ca45964e6969ed325bfae3e515a|f=81/0 m10088=a2
  #|sub byte ptr [rsi + rbx*4 + 0x8], -0x3|806c9e08fd|SUB8mi:%RSI,4,%RBX,8,%,-3|rbx=5 r9=9 f=d6 m1009c=9f0c3dd657d899a4ebd4c9d4b69e46c8|f=81/0 m1009c=a2
  #|sub cx, r14w|664429f1|SUB16rr:%CX,%CX,%R14W|rcx=60a9c315e6e47fb2 r14=f67c9d1e80000000 f=87|f=4/0
  #|sub cx, r14w|664429f1|SUB16rr:%CX,%CX,%R14W|rcx=b260a02e6b24a790 r14=1f39be0aedcfc033 f=416|rcx=b260a02e6b24e75d f=491/0
  #|sub ax, r11w|664429d8|SUB16rr:%AX,%AX,%R11W|rax=3f38ae938991e550 r11=eae7d5a54bbf6aca f=cd6|rax=3f38ae9389917a86 f=c10/0
  #|sub ax, r11w|664429d8|SUB16rr:%AX,%AX,%R11W|rax=8000000000000000 r11=189dde403ab8be00 f=c7|rax=8000000000004200 f=5/0
  #|sub word ptr [rbp - 0x20], dx|662955e0|SUB16mr:%RBP,1,%,-32,%,%DX|rdx=ca3900dd1408a2ff rbx=6 r9=a f=12 m20160=ac444bd516db0bdeb1fb297882415e6f|f=891/0 m20160=ada1
  #|sub word ptr [rbp - 0x20], dx|662955e0|SUB16mr:%RBP,1,%,-32,%,%DX|rdx=69a40c90d994d569 rbx=7 r9=5 f=43 m20160=ab4ceb70f7173b76fc559084ed996ec6|f=5/0 m20160=4277
  #|sub dx, word ptr [rsp + 0x8]|662b542408|SUB16rm:%DX,%DX,%RSP,1,%,8,%|rdx=8000000000000000 rbx=2 r9=3 f=816 m20108=61efaa565406b5fb5ec615b994d29140|rdx=800000000000109f f=15/0
  #|sub dx, word ptr [rsp + 0x8]|662b542408|SUB16rm:%DX,%DX,%RSP,1,%,8,%|rdx=e5141868777f77f9 rbx=1 r9=4 f=842 m20108=0df4898385c8534ce62e5788260c681b|rdx=e5141868777f83ec f=891/0
  #|sub r10w, -0x80|664183ea80|SUB16ri8:%R10W,%R10W,-128|r10=baec f=886|r10=bb6c f=85/0
  #|sub r10w, -0x80|664183ea80|SUB16ri8:%R10W,%R10W,-128|r10=befdaab974dd41fb f=82|r10=befdaab974dd427b f=5/0
  #|sub r10w, 0x1234|664181ea3412|SUB16ri:%R10W,%R10W,4660|r10=9c0cbaa0931596c7 f=43|r10=9c0cbaa093158493 f=84/0
  #|sub r10w, 0x1234|664181ea3412|SUB16ri:%R10W,%R10W,4660|r10=ffff f=856|r10=edcb f=80/0
  #|sub ax, 0x1234|662d3412|SUB16i16:4660|rax=7c053fd6cbcb502a f=416|rax=7c053fd6cbcb3df6 f=404/0
  #|sub ax, 0x1234|662d3412|SUB16i16:4660|rax=9480e759e083ed48 f=842|rax=9480e759e083db14 f=84/0
  #|sub word ptr [rsi + rbx*4 + 0x8], 0x0|66836c9e0800|SUB16mi8:%RSI,4,%RBX,8,%,0|rbx=c r9=b f=12 m100b8=cb9d1c56c312a863387624d93dcfa526|f=80/0
  #|sub word ptr [rsi + rbx*4 + 0x8], 0x0|66836c9e0800|SUB16mi8:%RSI,4,%RBX,8,%,0|rbx=4 r9=3 f=8d3 m10098=7b958d450c29f69a2f87002d4ccd5e21|f=84/0
  #|sub r11d, r13d|4529eb|SUB32rr:%R11D,%R11D,%R13D|r11=7fffffffffffffff r13=f8a3bd879c6344bb f=843|r11=639cbb44 f=4/0
  #|sub r11d, r13d|4529eb|SUB32rr:%R11D,%R11D,%R13D|r11=6392e90a20e124e0 r13=80000000 f=c96|r11=a0e124e0 f=c81/0
  #|sub edx, r14d|4429f2|SUB32rr:%EDX,%EDX,%R14D|rdx=c8b5 r14=41ad510a22be4510 f=887|rdx=dd4283a5 f=85/0
  #|sub edx, r14d|4429f2|SUB32rr:%EDX,%EDX,%R14D|rdx=20d7a5cf45fa74af r14=cdd0dd382be77173 f=12|rdx=1a13033c f=4/0
  #|sub dword ptr [rsp + 0x8], edx|29542408|SUB32mr:%RSP,1,%,8,%,%EDX|rdx=7fffffffffffffff rbx=6 r9=b f=812 m20108=33c11bfac1babf8e1298f6cecf4ea39f|f=91/0 m20108=34
  #|sub dword ptr [rsp + 0x8], edx|29542408|SUB32mr:%RSP,1,%,8,%,%EDX|rdx=6d8c57464ac2c12a rbx=d r9=c f=2 m20108=f0484b8517cf281e3f0826389dfa69ed|f=814/0 m20108=c687883a
  #|sub edx, dword ptr [rbp - 0x20]|2b55e0|SUB32rm:%EDX,%EDX,%RBP,1,%,-32,%|rdx=8000 rbx=6 r9=3 f=412 m20160=5808a5bf34db8054e51ae5e6a5503374|rdx=405b77a8 f=411/0
  #|sub edx, dword ptr [rbp - 0x20]|2b55e0|SUB32rm:%EDX,%EDX,%RBP,1,%,-32,%|rdx=87bac44a80000000 rbx=5 r9=6 f=47 m20160=5c4729d8bec52f6d4774f4fd37a7e5f3|rdx=a7d6b8a4 f=91/0
  #|sub r9d, 0x0|4183e900|SUB32ri8:%R9D,%R9D,0|r9=68701a7754f25c0e f=c82|r9=54f25c0e f=400/0
  #|sub r9d, 0x0|4183e900|SUB32ri8:%R9D,%R9D,0|r9=1f6d98d585ec088c f=806|r9=85ec088c f=80/0
  #|sub r9d, -0x80000000|4181e900000080|SUB32ri:%R9D,%R9D,2147483648|r9=c9fec5b7be5953eb f=d3|r9=3e5953eb f=4/0
  #|sub r9d, -0x80000000|4181e900000080|SUB32ri:%R9D,%R9D,2147483648|r9=33dee1cdd6b2e86c f=8d2|r9=56b2e86c f=4/0
  #|sub eax, -0x100|2d00ffffff|SUB32i32:4294967040|rax=d2 f=857|rax=1d2 f=5/0
  #|sub eax, -0x100|2d00ffffff|SUB32i32:4294967040|rax=8000 f=7|rax=8100 f=5/0
  #|sub dword ptr [rdi + 0x10], 0x1|836f1001|SUB32mi8:%RDI,1,%,16,%,1|rbx=a r9=b f=97 m10110=0ae42abf55356a545e505b3c7d56522d|f=84/0 m10110=09
  #|sub dword ptr [rdi + 0x10], 0x1|836f1001|SUB32mi8:%RDI,1,%,16,%,1|rbx=d r9=a f=816 m10110=2851f8ea490a80bb07ab2fd5e74c4006|f=84/0 m10110=27
  #|sub r13, r14|4d29f5|SUB64rr:%R13,%R13,%R14|r13=c37634d8e743eae2 r14=fd12cd2f36892503 f=c56|r13=c66367a9b0bac5df f=491/0
  #|sub r13, r14|4d29f5|SUB64rr:%R13,%R13,%R14|r13=ff r14=2d1ec8e4cac58a24 f=897|r13=d2e1371b353a76db f=85/0
  #|sub r9, r10|4d29d1|SUB64rr:%R9,%R9,%R10|r9=ffffffff r10=6c f=8c3|r9=ffffff93 f=4/0
  #|sub r9, r10|4d29d1|SUB64rr:%R9,%R9,%R10|r9=f760ac304275105b r10=58 f=93|r9=f760ac3042751003 f=84/0
  #|sub qword ptr [rsi], r10|4c2916|SUB64mr:%RSI,1,%,0,%,%R10|rbx=6 r9=9 r10=bd096862608b8a39 f=413 m10080=781bbe24d84c2f96ec6fbec1458f7b54|f=495/0 m10080=3f9132c475e425d9
  #|sub qword ptr [rsi], r10|4c2916|SUB64mr:%RSI,1,%,0,%,%R10|rbx=6 r9=3 r10=af7f985480000000 f=412 m10080=191ce898a5f655d40e9c1ea60d131ecf|f=400/0 m10083=18515ed624
  #|sub r10, qword ptr [rsp + 0x8]|4c2b542408|SUB64rm:%R10,%R10,%RSP,1,%,8,%|rbx=a r9=3 r10=152b56bd519b1fe4 f=86 m20108=ed928acbdf45ed1c535396251576f10b|r10=f83e10dd86108cf7 f=91/0
  #|sub r10, qword ptr [rsp + 0x8]|4c2b542408|SUB64rm:%R10,%R10,%RSP,1,%,8,%|rbx=b r9=7 r10=dd f=803 m20108=fef4e3ea4beae26577841a75dd1e9638|r10=9a1d15b4151c0bdf f=91/0
  #|sub r8, 0x0|4983e800|SUB64ri8:%R8,%R8,0|r8=509cfcc04d32f5e5 f=892|f=0/0
  #|sub r8, 0x0|4983e800|SUB64ri8:%R8,%R8,0|r8=232a72cd99966eda f=43|f=0/0
  #|sub r8, 0x100|4981e800010000|SUB64ri32:%R8,%R8,256|r8=9d3a10e94bdc0240 f=82|r8=9d3a10e94bdc0140 f=80/0
  #|sub r8, 0x100|4981e800010000|SUB64ri32:%R8,%R8,256|r8=ff f=893|r8=ffffffffffffffff f=85/0
  #|sub rax, 0x100|482d00010000|SUB64i32:256|rax=0 f=886|rax=ffffffffffffff00 f=85/0
  #|sub rax, 0x100|482d00010000|SUB64i32:256|rax=a273f4d1cde3b222 f=12|rax=a273f4d1cde3b122 f=84/0
  #|sub qword ptr [rsp + 0x8], 0x1|48836c240801|SUB64mi8:%RSP,1,%,8,%,1|rbx=f r9=9 f=d7 m20108=7b306ec2375ab716c47bfb4c3463de19|f=0/0 m20108=7a
  #|sub qword ptr [rsp + 0x8], 0x1|48836c240801|SUB64mi8:%RSP,1,%,8,%,1|rbx=c r9=e f=c02 m20108=b50681dda8dc9587ae1c5a5ebb24c3da|f=484/0 m20108=b4
  #|xor r11b, dl|4130d3|XOR8rr:%R11B,%R11B,%DL|rdx=fa91c312f04dc651 r11=5ba6fb6e23bd36c3 f=803|r11=5ba6fb6e23bd3692 f=80/10
  #|xor r11b, dl|4130d3|XOR8rr:%R11B,%R11B,%DL|rdx=3 r11=351ab01b94bb448c f=8c3|r11=351ab01b94bb448f f=80/10
  #|xor r11b, r9b|4530cb|XOR8rr:%R11B,%R11B,%R9B|r9=61b651c459f5d110 r11=73f0 f=c17|r11=73e0 f=480/10
  #|xor r11b, r9b|4530cb|XOR8rr:%R11B,%R11B,%R9B|r9=403480d2f2ec57e2 r11=2fd8caf3a08bacd1 f=56|r11=2fd8caf3a08bac33 f=4/10
  #|xor byte ptr [rdi + r9*2 - 0x4], r12b|4630644ffc|XOR8mr:%RDI,2,%R9,-4,%,%R12B|rbx=e r9=8 r12=42ae f=887 m1010c=a72f70a1ba949f59b44b11f86aa6572d|f=4/10 m1010c=09
  #|xor byte ptr [rdi + r9*2 - 0x4], r12b|4630644ffc|XOR8mr:%RDI,2,%R9,-4,%,%R12B|rbx=9 r9=2 r12=8000000000000000 f=d2 m10100=371161e221c30e71ad08a247b23f0702|f=0/10
  #|xor r12b, byte ptr [rdi + 0x10]|44326710|XOR8rm:%R12B,%R12B,%RDI,1,%,16,%|rbx=3 r9=d r12=dae462fb29aa026c f=97 m10110=1de4e36594791c9682f66d9e7f0e581a|r12=dae462fb29aa0271 f=4/10
  #|xor r12b, byte ptr [rdi + 0x10]|44326710|XOR8rm:%R12B,%R12B,%RDI,1,%,16,%|rbx=a r9=9 r12=1270cd17e4f006de f=442 m10110=97bc8d9e8a7d365866891555f50c2e94|r12=1270cd17e4f00649 f=400/10
  #|xor dl, -0x3|80f2fd|XOR8ri:%DL,%DL,-3|rdx=f80af35e748e10e2 f=802|rdx=f80af35e748e101f f=0/10
  #|xor dl, -0x3|80f2fd|XOR8ri:%DL,%DL,-3|rdx=6 f=4d7|rdx=fb f=480/10
  #|xor dl, 0x5a|80f25a|XOR8ri:%DL,%DL,90|rdx=3f97adf2746aa60 f=c02|rdx=3f97adf2746aa3a f=404/10
  #|xor dl, 0x5a|80f25a|XOR8ri:%DL,%DL,90|rdx=b f=46|rdx=51 f=0/10
  #|xor al, 0x80|3480|XOR8i8:-128|rax=328310aa14662a2a f=96|rax=328310aa14662aaa f=84/10
  #|xor al, 0x80|3480|XOR8i8:-128|rax=2b190d7994340f75 f=43|rax=2b190d7994340ff5 f=84/10
  #|xor byte ptr [rbp - 0x20], 0x7f|8075e07f|XOR8mi:%RBP,1,%,-32,%,127|rbx=b r9=3 f=56 m20160=bb6254f3284924db7bd7fc0092ec5b4e|f=80/10 m20160=c4
  #|xor byte ptr [rbp - 0x20], 0x7f|8075e07f|XOR8mi:%RBP,1,%,-32,%,127|rbx=8 r9=0 f=802 m20160=c718652cdc7faf576c19faa67097dcef|f=84/10 m20160=b8
  #|xor bx, r9w|664431cb|XOR16rr:%BX,%BX,%R9W|rbx=2 r9=80 f=c7|rbx=82 f=4/10
  #|xor bx, r9w|664431cb|XOR16rr:%BX,%BX,%R9W|rbx=a764 r9=2062cba39cad0307 f=812|rbx=a463 f=84/10
  #|xor ax, r14w|664431f0|XOR16rr:%AX,%AX,%R14W|rax=b5264daf4740146a r14=1 f=83|rax=b5264daf4740146b f=0/10
  #|xor ax, r14w|664431f0|XOR16rr:%AX,%AX,%R14W|rax=fffffffffffffffe r14=7fffffffffffffff f=c2|rax=ffffffffffff0001 f=0/10
  #|xor word ptr [rsp + 0x8], ax|6631442408|XOR16mr:%RSP,1,%,8,%,%AX|rax=8000000000000000 rbx=b r9=f f=856 m20108=6340bd4f9620eeed625510c49955d80c|f=4/10
  #|xor word ptr [rsp + 0x8], ax|6631442408|XOR16mr:%RSP,1,%,8,%,%AX|rax=ffffffffffffffff rbx=f r9=4 f=97 m20108=8df38a33c162f983c1b9d9cc517b6dec|f=4/10 m20108=720c
  #|xor ax, word ptr [rsi]|663306|XOR16rm:%AX,%AX,%RSI,1,%,0,%|rax=3401a0d36dc04535 rbx=d r9=6 f=96 m10080=18eec6409dc9d369aeaca8aa2792396e|rax=3401a0d36dc0ab2d f=84/10
  #|xor ax, word ptr [rsi]|663306|XOR16rm:%AX,%AX,%RSI,1,%,0,%|rax=c6f209c66175d64f rbx=4 r9=a f=4c6 m10080=942cb68c0e18fd6d3ea4a4fef0960f93|rax=c6f209c66175fadb f=484/10
  #|xor r14w, 0x0|664183f600|XOR16ri8:%R14W,%R14W,0|r14=fffffffffffffffe f=3|f=80/10
  #|xor r14w, 0x0|664183f600|XOR16ri8:%R14W,%R14W,0|r14=7fffffffffffffff f=c02|f=484/10
  #|xor r14w, 0x1234|664181f63412|XOR16ri:%R14W,%R14W,4660|r14=c732e15243222d4d f=842|r14=c732e15243223f79 f=0/10
  #|xor r14w, 0x1234|664181f63412|XOR16ri:%R14W,%R14W,4660|r14=e1e2964d1f54e77a f=16|r14=e1e2964d1f54f54e f=84/10
  #|xor ax, 0xffff|6683f0ff|XOR16ri8:%AX,%AX,-1|rax=100 f=57|rax=feff f=84/10
  #|xor ax, 0xffff|6683f0ff|XOR16ri8:%AX,%AX,-1|rax=dde852ea7427c204 f=c53|rax=dde852ea74273dfb f=400/10
  #|xor word ptr [rsi], 0x7f|6683367f|XOR16mi8:%RSI,1,%,0,%,127|rbx=0 r9=6 f=46 m10080=21c74d848e2ac25a2a626c0766d25b12|f=80/10 m10080=5e
  #|xor word ptr [rsi], 0x7f|6683367f|XOR16mi8:%RSI,1,%,0,%,127|rbx=7 r9=5 f=8d2 m10080=cff89a4478d17be46a6fa0fbd185a8d4|f=80/10 m10080=b0
  #|xor r8d, r15d|4531f8|XOR32rr:%R8D,%R8D,%R15D|r8=ccff7367c6d06a67 r15=9017e5e9cd5963ea f=802|r8=b89098d f=4/10
  #|xor r8d, r15d|4531f8|XOR32rr:%R8D,%R8D,%R15D|r8=da9a4c3e9eabd419 r15=7fffffff f=853|r8=e1542be6 f=80/10
  #|xor ecx, r9d|4431c9|XOR32rr:%ECX,%ECX,%R9D|rcx=5a43f9b7940f560c r9=d18a f=c17|rcx=940f8786 f=480/10
  #|xor ecx, r9d|4431c9|XOR32rr:%ECX,%ECX,%R9D|rcx=ffffffffffffffff r9=a f=57|rcx=fffffff5 f=84/10
  #|xor dword ptr [rsp + 0x8], ecx|314c2408|XOR32mr:%RSP,1,%,8,%,%ECX|rcx=a7c7732ab85bc2b2 rbx=2 r9=d f=803 m20108=db49d4cfbb40b1559bcedf3be314434f|f=4/10 m20108=698b8f77
  #|xor dword ptr [rsp + 0x8], ecx|314c2408|XOR32mr:%RSP,1,%,8,%,%ECX|rcx=13a062d259ae984 rbx=f r9=b f=413 m20108=e5d44639f7e5a718de1df6b64efd5c24|f=400/10 m20108=613ddc1c
  #|xor ecx, dword ptr [rbp - 0x20]|334de0|XOR32rm:%ECX,%ECX,%RBP,1,%,-32,%|rcx=74f5f1b57fffffff rbx=3 r9=c f=816 m20160=cfe0dfcd5c9bba36083d48800907b1be|rcx=b2201f30 f=84/10
  #|xor ecx, dword ptr [rbp - 0x20]|334de0|XOR32rm:%ECX,%ECX,%RBP,1,%,-32,%|rcx=9600be5398adc99e rbx=6 r9=a f=4c2 m20160=ea9c1ac666336fea43f5e52ac2e1609f|rcx=5eb75574 f=404/10
  #|xor r13d, -0x80|4183f580|XOR32ri8:%R13D,%R13D,-128|r13=fffffffffffffffe f=887|r13=7e f=4/10
  #|xor r13d, -0x80|4183f580|XOR32ri8:%R13D,%R13D,-128|r13=d07ec65a9f32751d f=887|r13=60cd8a9d f=0/10
  #|xor r13d, 0x7fffffff|4181f5ffffff7f|XOR32ri:%R13D,%R13D,2147483647|r13=b0ed2a3cd9951ae9 f=402|r13=a66ae516 f=480/10
  #|xor r13d, 0x7fffffff|4181f5ffffff7f|XOR32ri:%R13D,%R13D,2147483647|r13=56acaf27fcc6fb7e f=43|r13=83390481 f=84/10
  #|xor eax, -0x100|3500ffffff|XOR32i32:4294967040|rax=9dd679d80c9b9411 f=896|rax=f3646b11 f=84/10
  #|xor eax, -0x100|3500ffffff|XOR32i32:4294967040|rax=80000000 f=17|rax=7fffff00 f=4/10
  #|xor dword ptr [rsi], 0x1|833601|XOR32mi8:%RSI,1,%,0,%,1|rbx=3 r9=9 f=c53 m10080=403417ad39c2fbc49191621cfaac61d3|f=484/10 m10080=41
  #|xor dword ptr [rsi], 0x1|833601|XOR32mi8:%RSI,1,%,0,%,1|rbx=b r9=b f=813 m10080=668e5a247e1419bc785d5e4d7dd7baa5|f=0/10 m10080=67
  #|xor r13, rdx|4931d5|XOR64rr:%R13,%R13,%RDX|rdx=8977034f2cbb3c7a r13=88c505ee7ee5e492 f=847|r13=1b206a1525ed8e8 f=4/10
  #|xor r13, rdx|4931d5|XOR64rr:%R13,%R13,%RDX|rdx=ba824749c300bfbb r13=3ca789e80000000 f=56|r13=b9483fd74300bfbb f=84/10
  #|xor rax, r14|4c31f0|XOR64rr:%RAX,%RAX,%R14|rax=8f9317457fffffff r14=72c4 f=8d3|rax=8f9317457fff8d3b f=80/10
  #|xor rax, r14|4c31f0|XOR64rr:%RAX,%RAX,%R14|rax=38898e8e01f890e4 r14=57a1f1884e8c89bf f=12|rax=6f287f064f74195b f=0/10
  #|xor qword ptr [rsp + 0x8], r8|4c31442408|XOR64mr:%RSP,1,%,8,%,%R8|rbx=8 r8=5836e57030283a37 r9=b f=806 m20108=cdf69278fe81d1a490a62fcca887605c|f=84/10 m20108=faccba488e64e7fc
  #|xor qword ptr [rsp + 0x8], r8|4c31442408|XOR64mr:%RSP,1,%,8,%,%R8|rbx=a r8=fffffffffffffffe r9=3 f=56 m20108=c3d41841e05241fedb7ae80a311fb606|f=0/10 m20108=3d2be7be1fadbe01
  #|xor r8, qword ptr [rbp - 0x20]|4c3345e0|XOR64rm:%R8,%R8,%RBP,1,%,-32,%|rbx=4 r8=de66021eab45f1d r9=1 f=893 m20160=9410a053cdadc06d87ed4423165f7eae|r8=6026cdecb9144f89 f=0/10
  #|xor r8, qword ptr [rbp - 0x20]|4c3345e0|XOR64rm:%R8,%R8,%RBP,1,%,-32,%|rbx=a r8=80d1f40a4e666c69 r9=a f=892 m20160=90665a5ee986e913ae845fb0e82feffd|r8=933872e3103c0af9 f=84/10
  #|xor r13, -0x3|4983f5fd|XOR64ri8:%R13,%R13,-3|r13=286f370e2a6acb53 f=7|r13=d790c8f1d59534ae f=80/10
  #|xor r13, -0x3|4983f5fd|XOR64ri8:%R13,%R13,-3|r13=a f=807|r13=fffffffffffffff7 f=80/10
  #|xor r13, -0x100|4981f500ffffff|XOR64ri32:%R13,%R13,-256|r13=4 f=412|r13=ffffffffffffff04 f=480/10
  #|xor r13, -0x100|4981f500ffffff|XOR64ri32:%R13,%R13,-256|r13=7c7619012ec20193 f=482|r13=8389e6fed13dfe93 f=484/10
  #|xor rax, -0x100|483500ffffff|XOR64i32:-256|rax=982c21e210b81013 f=d7|rax=67d3de1def47ef13 f=0/10
  #|xor rax, -0x100|483500ffffff|XOR64i32:-256|rax=4db61ee0af14f5c6 f=812|rax=b249e11f50eb0ac6 f=84/10
  #|xor qword ptr [rsi], -0x3|488336fd|XOR64mi8:%RSI,1,%,0,%,-3|rbx=b r9=4 f=886 m10080=3f3f6b55cdec957a0087dd3c6d266da5|f=80/10 m10080=c2c094aa32136a85
  #|xor qword ptr [rsi], -0x3|488336fd|XOR64mi8:%RSI,1,%,0,%,-3|rbx=6 r9=d f=893 m10080=1a22f2176f69c88e4d45b219e1db3584|f=4/10 m10080=e7dd0de890963771
  #|cmp r15b, r9b|4538cf|CMP8rr:%R15B,%R9B|r9=cf4703707bbb6d20 r15=7fffffff f=8d6|f=80/0
  #|cmp r15b, r9b|4538cf|CMP8rr:%R15B,%R9B|r9=fffffffffffffffe r15=741b9e6f002453f8 f=42|f=95/0
  #|cmp r13b, r9b|4538cd|CMP8rr:%R13B,%R9B|r9=634887041b93706b r13=bdf6e3c1fb95d693 f=c03|f=c14/0
  #|cmp r13b, r9b|4538cd|CMP8rr:%R13B,%R9B|r9=70de397a94579e7a r13=d89fbfaae8c6186c f=c2|f=81/0
  #|cmp byte ptr [rdi + r9*2 - 0x4], dl|4238544ffc|CMP8mr:%RDI,2,%R9,-4,%,%DL|rdx=29b3ba68aca9754 rbx=b r9=c f=86 m10114=486feb08a65b9bac3982e70344055b51|f=81/0
  #|cmp byte ptr [rdi + r9*2 - 0x4], dl|4238544ffc|CMP8mr:%RDI,2,%R9,-4,%,%DL|rdx=ef8fddc5ec7a8000 rbx=f r9=7 f=857 m1010a=d5446776d6457b363fb29ae248c897ed|f=80/0
  #|cmp dl, byte ptr [rbp - 0x20]|3a55e0|CMP8rm:%DL,%RBP,1,%,-32,%|rdx=1 rbx=7 r9=f f=892 m20160=28fd39e481d918607c75bbac5a52ca19|f=91/0
  #|cmp dl, byte ptr [rbp - 0x20]|3a55e0|CMP8rm:%DL,%RBP,1,%,-32,%|rdx=7f rbx=5 r9=9 f=846 m20160=2f62c9181c4bcceca795da5c7a7e94eb|f=4/0
  #|cmp cl, -0x3|80f9fd|CMP8ri:%CL,-3|rcx=c88eed647ff1770b f=52|f=11/0
  #|cmp cl, -0x3|80f9fd|CMP8ri:%CL,-3|rcx=78ec322af642013a f=c57|f=411/0
  #|cmp cl, 0x1|80f901|CMP8ri:%CL,1|rcx=b2383da1fb0d8a76 f=46|f=0/0
  #|cmp cl, 0x1|80f901|CMP8ri:%CL,1|rcx=100 f=56|f=95/0
  #|cmp al, 0x80|3c80|CMP8i8:-128|rax=7fff f=16|f=0/0
  #|cmp al, 0x80|3c80|CMP8i8:-128|rax=ffffffffffffffff f=d6|f=0/0
  #|cmp byte ptr [rdi + 0x10], -0x3|807f10fd|CMP8mi:%RDI,1,%,16,%,-3|rbx=f r9=5 f=83 m10110=5fef23001788cb80d0128c60d124b70f|f=1/0
  #|cmp byte ptr [rdi + 0x10], -0x3|807f10fd|CMP8mi:%RDI,1,%,16,%,-3|rbx=4 r9=7 f=52 m10110=054fb75753a8a06559ec525212cf3387|f=11/0
  #|cmp r11w, r12w|664539e3|CMP16rr:%R11W,%R12W|r11=fc02a6f930e9b261 r12=1 f=486|f=484/0
  #|cmp r11w, r12w|664539e3|CMP16rr:%R11W,%R12W|r11=64e557319a36f7f r12=697fa8bb8251e100 f=806|f=881/0
  #|cmp r14w, r13w|664539ee|CMP16rr:%R14W,%R13W|r13=f40117330c9db154 r14=10ed39b06e7966eb f=802|f=881/0
  #|cmp r14w, r13w|664539ee|CMP16rr:%R14W,%R13W|r13=ffff r14=d f=c47|f=411/0
  #|cmp word ptr [rsi], ax|663906|CMP16mr:%RSI,1,%,0,%,%AX|rax=d63b5dbb3f42f2db rbx=3 r9=5 f=86 m10080=3a24dc2095f14c99ab91cd6462b37c79|f=15/0
  #|cmp word ptr [rsi], ax|663906|CMP16mr:%RSI,1,%,0,%,%AX|rax=d3cc rbx=3 r9=1 f=857 m10080=65d494bf09af75356e7c6f54a879b7c6|f=14/0
  #|cmp ax, word ptr [rdi + 0x10]|663b4710|CMP16rm:%AX,%RDI,1,%,16,%|rax=938d66af2e823a87 rbx=8 r9=6 f=17 m10110=03cc277ad2cea43bf4409b73b1411762|f=5/0
  #|cmp ax, word ptr [rdi + 0x10]|663b4710|CMP16rm:%AX,%RDI,1,%,16,%|rax=a1fffff82318c5db rbx=9 r9=e f=d6 m10110=45fbb47e2e68740bdb2d1a3fa95a1c9c|f=85/0
  #|cmp r11w, -0x1|664183fbff|CMP16ri8:%R11W,-1|r11=2 f=42|f=15/0
  #|cmp r11w, -0x1|664183fbff|CMP16ri8:%R11W,-1|r11=46827d3cd7c8ede2 f=d7|f=91/0
  #|cmp r11w, 0x100|664181fb0001|CMP16ri:%R11W,256|r11=e91f8c93250481a3 f=c6|f=84/0
  #|cmp r11w, 0x100|664181fb0001|CMP16ri:%R11W,256|r11=5b0f39dc2089083e f=57|f=0/0
  #|cmp ax, 0xffff|6683f8ff|CMP16ri8:%AX,-1|rax=1 f=842|f=11/0
  #|cmp ax, 0xffff|6683f8ff|CMP16ri8:%AX,-1|rax=50d935eecc7ab2e2 f=c3|f=91/0
  #|cmp word ptr [rdi + 0x10], 0x1|66837f1001|CMP16mi8:%RDI,1,%,16,%,1|rbx=1 r9=b f=403 m10110=78e69c800022950e335c26e19b837360|f=484/0
  #|cmp word ptr [rdi + 0x10], 0x1|66837f1001|CMP16mi8:%RDI,1,%,16,%,1|rbx=5 r9=f f=53 m10110=8021752078967a298a2cbbbcc646ddc7|f=10/0
  #|cmp r15d, eax|4139c7|CMP32rr:%R15D,%EAX|rax=b4bc43bc9109484b r15=8520cbf19f42356e f=886|f=0/0
  #|cmp r15d, eax|4139c7|CMP32rr:%R15D,%EAX|rax=bf892a098ede1b11 r15=1461a1e1ba927fd1 f=d7|f=4/0
  #|cmp edx, eax|39c2|CMP32rr:%EDX,%EAX|rax=98d45be8f3a789c4 rdx=bb7b0bd781ecdadb f=43|f=85/0
  #|cmp edx, eax|39c2|CMP32rr:%EDX,%EAX|rax=dc rdx=81f77707eef195a8 f=d3|f=94/0
  #|cmp dword ptr [rbp - 0x20], r8d|443945e0|CMP32mr:%RBP,1,%,-32,%,%R8D|rbx=2 r8=f r9=0 f=8c7 m20160=a5de32f938d90f649aa46c70522fcf2f|f=94/0
  #|cmp dword ptr [rbp - 0x20], r8d|443945e0|CMP32mr:%RBP,1,%,-32,%,%R8D|rbx=6 r8=9 r9=1 f=812 m20160=2513055008578964c7ca6ff9ab7851db|f=10/0
  #|cmp r8d, dword ptr [rdi + r9*2 - 0x4]|463b444ffc|CMP32rm:%R8D,%RDI,2,%R9,-4,%|rbx=7 r8=e10732bce4413e80 r9=5 f=812 m10106=fcc48b52563a3c665cff4b1ba2117a85|f=94/0
  #|cmp r8d, dword ptr [rdi + r9*2 - 0x4]|463b444ffc|CMP32rm:%R8D,%RDI,2,%R9,-4,%|rbx=4 r8=64a1b58bf06aa192 r9=e f=882 m10118=23e814c183dcf1aea4105da0b25a4367|f=14/0
  #|cmp edx, 0x0|83fa00|CMP32ri8:%EDX,0|rdx=943c4a8a5bbbf900 f=c2|f=4/0
  #|cmp edx, 0x0|83fa00|CMP32ri8:%EDX,0|rdx=6 f=12|f=4/0
  #|cmp edx, 0x100|81fa00010000|CMP32ri:%EDX,256|rdx=ca9fb98e02b5978 f=846|f=84/0
  #|cmp edx, 0x100|81fa00010000|CMP32ri:%EDX,256|rdx=1a79a8618f9a5d28 f=47|f=84/0
  #|cmp eax, 0x12345678|3d78563412|CMP32i32:305419896|rax=a22d66abe277c912 f=c07|f=494/0
  #|cmp eax, 0x12345678|3d78563412|CMP32i32:305419896|rax=55510ef186028f3a f=8d6|f=800/0
  #|cmp dword ptr [rdi + 0x10], -0x80|837f1080|CMP32mi8:%RDI,1,%,16,%,-128|rbx=b r9=e f=93 m10110=1ff77f1881afd8e9415caf03be899ce4|f=5/0
  #|cmp dword ptr [rdi + 0x10], -0x80|837f1080|CMP32mi8:%RDI,1,%,16,%,-128|rbx=7 r9=c f=42 m10110=23a00f429247cf3d837b59b296fc6730|f=5/0
  #|cmp rax, r10|4c39d0|CMP64rr:%RAX,%R10|rax=24 r10=7fffffff f=8c7|f=91/0
  #|cmp rax, r10|4c39d0|CMP64rr:%RAX,%R10|rax=7fff r10=8a69 f=17|f=85/0
  #|cmp rbx, r10|4c39d3|CMP64rr:%RBX,%R10|rbx=5acc1d065c700bd5 r10=23939398f79db3a2 f=47|f=4/0
  #|cmp rbx, r10|4c39d3|CMP64rr:%RBX,%R10|rbx=5dba24ffe71508eb r10=584d24fae1c446eb f=4d2|f=404/0
  #|cmp qword ptr [rsi], rax|483906|CMP64mr:%RSI,1,%,0,%,%RAX|rax=18388f2499b4b1f4 rbx=4 r9=e f=93 m10080=024ee46b650c0f0b283515bacba093dd|f=91/0
  #|cmp qword ptr [rsi], rax|483906|CMP64mr:%RSI,1,%,0,%,%RAX|rax=b29f8e25a468f1b rbx=d r9=7 f=c92 m10080=74b849976e3371739545fd2d6553851f|f=414/0
  #|cmp rax, qword ptr [rdi + 0x10]|483b4710|CMP64rm:%RAX,%RDI,1,%,16,%|rax=80 rbx=f r9=1 f=86 m10110=8882cc3cc30d5a7de398818077ceda01|f=91/0
  #|cmp rax, qword ptr [rdi + 0x10]|483b4710|CMP64rm:%RAX,%RDI,1,%,16,%|rax=2b rbx=9 r9=f f=8c2 m10110=f46c368a89fca26e6a113e1d7feb720e|f=81/0
  #|cmp r11, -0x1|4983fbff|CMP64ri8:%R11,-1|r11=98aabda9e64eb11d f=887|f=95/0
  #|cmp r11, -0x1|4983fbff|CMP64ri8:%R11,-1|r11=1d630caa988ac351 f=6|f=11/0
  #|cmp r11, 0x100|4981fb00010000|CMP64ri32:%R11,256|r11=ff f=857|f=85/0
  #|cmp r11, 0x100|4981fb00010000|CMP64ri32:%R11,256|r11=5af5da5189636e5a f=817|f=4/0
  #|cmp rax, -0x100|483d00ffffff|CMP64i32:-256|rax=67ac5537d07e696e f=c6|f=1/0
  #|cmp rax, -0x100|483d00ffffff|CMP64i32:-256|rax=759c f=47|f=5/0
  #|cmp qword ptr [rdi + r9*2 - 0x4], 0x5|4a837c4ffc05|CMP64mi8:%RDI,2,%R9,-4,%,5|rbx=0 r9=b f=d7 m10112=1c80345b9a422cc237c69079886dd2b5|f=84/0
  #|cmp qword ptr [rdi + r9*2 - 0x4], 0x5|4a837c4ffc05|CMP64mi8:%RDI,2,%R9,-4,%,5|rbx=e r9=e f=8d7 m10118=fb477c72c2dc22e4093c8a2ac10e2a27|f=84/0
  #|test r9b, r10b|4584d1|TEST8rr:%R9B,%R10B|r9=1f8a9f1570ad9ea r10=85c6009a5b4c29b7 f=7|f=80/10
  #|test r9b, r10b|4584d1|TEST8rr:%R9B,%R10B|r9=9d4277aa78bf7d5c r10=68eb15296bfb3b8f f=8d7|f=4/10
  #|test bl, r10b|4484d3|TEST8rr:%BL,%R10B|rbx=7fffffffffffffff r10=6ebeca91f780a92d f=82|f=4/10
  #|test bl, r10b|4484d3|TEST8rr:%BL,%R10B|rbx=6153d03b60e72e5e r10=545f68135046d476 f=8d3|f=4/10
  #|test byte ptr [rsp + 0x8], bl|845c2408|TEST8mr:%RSP,1,%,8,%,%BL|rbx=4 r9=f f=8c7 m20108=0a5b11daea98f29ff5a2459628dcb3d2|f=44/10
  #|test byte ptr [rsp + 0x8], bl|845c2408|TEST8mr:%RSP,1,%,8,%,%BL|rbx=3 r9=b f=883 m20108=2f488730f16eeb04e0ad40e058badfef|f=4/10
  #|test r9b, 0xff|41f6c1ff|TEST8ri:%R9B,-1|r9=8000 f=847|f=44/10
  #|test r9b, 0xff|41f6c1ff|TEST8ri:%R9B,-1|r9=309b f=cc7|f=480/10
  #|test al, 0x80|a880|TEST8i8:-128|rax=988414b108feaaa f=3|f=80/10
  #|test al, 0x80|a880|TEST8i8:-128|rax=fa1d73d15c9b2986 f=892|f=80/10
  #|test byte ptr [rsi + rbx*4 + 0x8], 0x7f|f6449e087f|TEST8mi:%RSI,4,%RBX,8,%,127|rbx=a r9=9 f=3 m100b0=0cd6119f9b26dc7c5c2fa2cb543b56b0|f=4/10
  #|test byte ptr [rsi + rbx*4 + 0x8], 0x7f|f6449e087f|TEST8mi:%RSI,4,%RBX,8,%,127|rbx=4 r9=a f=6 m10098=177eca466588ae8289c7eded59f77853|f=4/10
  #|test r8w, ax|664185c0|TEST16rr:%R8W,%AX|rax=91 r8=d54032d0400a81d f=412|f=404/10
  #|test r8w, ax|664185c0|TEST16rr:%R8W,%AX|rax=483df8ecfbd2f714 r8=715c f=857|f=4/10
  #|test r15w, r14w|664585f7|TEST16rr:%R15W,%R14W|r14=d67f9fd86ea91c7f r15=7fa5 f=13|f=0/10
  #|test r15w, r14w|664585f7|TEST16rr:%R15W,%R14W|r14=82a1eef6f505a8c1 r15=a6 f=7|f=0/10
  #|test word ptr [rsi + rbx*4 + 0x8], r8w|664485449e08|TEST16mr:%RSI,4,%RBX,8,%,%R8W|rbx=d r8=d1a3117280000000 r9=a f=4c2 m100bc=31de9b741500f52ac2a5c39948417ab7|f=444/10
  #|test word ptr [rsi + rbx*4 + 0x8], r8w|664485449e08|TEST16mr:%RSI,4,%RBX,8,%,%R8W|rbx=2 r8=89a0f740ffffffff r9=3 f=856 m10090=9a6f9de0a9a37f105701b55e7f21a140|f=4/10
  #|test r9w, 0xffff|6641f7c1ffff|TEST16ri:%R9W,65535|r9=80 f=8c2|f=0/10
  #|test r9w, 0xffff|6641f7c1ffff|TEST16ri:%R9W,65535|r9=8000000000000000 f=882|f=44/10
  #|test ax, 0x100|66a90001|TEST16i16:256|rax=13a2e415b1a68000 f=813|f=44/10
  #|test ax, 0x100|66a90001|TEST16i16:256|rax=8df66f767008a25a f=807|f=44/10
  #|test word ptr [rdi + 0x10], 0x7fff|66f74710ff7f|TEST16mi:%RDI,1,%,16,%,32767|rbx=6 r9=5 f=852 m10110=c1574dee3c5f2d1b622f0b76eea018db|f=0/10
  #|test word ptr [rdi + 0x10], 0x7fff|66f74710ff7f|TEST16mi:%RDI,1,%,16,%,32767|rbx=d r9=c f=c2 m10110=285f00a74d0a462fce089fce2fa06a2d|f=4/10
  #|test eax, r15d|4485f8|TEST32rr:%EAX,%R15D|rax=b89b9d6110c009a2 r15=c1757441e59fb7c4 f=8d7|f=0/10
  #|test eax, r15d|4485f8|TEST32rr:%EAX,%R15D|rax=bb9496f4bc3450db r15=ffffffffffffffff f=52|f=84/10
  #|test r9d, r13d|4585e9|TEST32rr:%R9D,%R13D|r9=56e3add44002ea52 r13=2023 f=43|f=0/10
  #|test r9d, r13d|4585e9|TEST32rr:%R9D,%R13D|r9=8000000000000000 r13=901b f=87|f=44/10
  #|test dword ptr [rsp + 0x8], r8d|4485442408|TEST32mr:%RSP,1,%,8,%,%R8D|rbx=4 r8=fd623fb0ffffffff r9=c f=c6 m20108=0559e19ceabb87e1478e931376616ceb|f=84/10
  #|test dword ptr [rsp + 0x8], r8d|4485442408|TEST32mr:%RSP,1,%,8,%,%R8D|rbx=8 r8=c958 r9=4 f=8d2 m20108=90e281330c154f94cda859900e4a3981|f=0/10
  #|test r15d, 0x12345678|41f7c778563412|TEST32ri:%R15D,305419896|r15=c3e742b880000000 f=446|f=444/10
  #|test r15d, 0x12345678|41f7c778563412|TEST32ri:%R15D,305419896|r15=80 f=8c2|f=44/10
  #|test eax, -0x80000000|a900000080|TEST32i32:2147483648|rax=1 f=93|f=44/10
  #|test eax, -0x80000000|a900000080|TEST32i32:2147483648|rax=e3b6510d9e855bd2 f=6|f=84/10
  #|test dword ptr [rsi], 0x100|f70600010000|TEST32mi:%RSI,1,%,0,%,256|rbx=9 r9=b f=97 m10080=73f87c01905034dca25be3478bd3ce51|f=44/10
  #|test dword ptr [rsi], 0x100|f70600010000|TEST32mi:%RSI,1,%,0,%,256|rbx=e r9=c f=4c3 m10080=eb192f882dfd48679f5a0cbcb637c4fb|f=404/10
  #|test r14, r10|4d85d6|TEST64rr:%R14,%R10|r10=80000000 r14=b547e3b332c17fff f=86|f=44/10
  #|test r14, r10|4d85d6|TEST64rr:%R14,%R10|r10=ffffffffffffffff r14=ff f=856|f=4/10
  #|test r9, rbx|4985d9|TEST64rr:%R9,%RBX|rbx=9e30e28f7de9ad8a r9=7c3e823402c793bb f=482|f=400/10
  #|test r9, rbx|4985d9|TEST64rr:%R9,%RBX|rbx=b2266bd6b6b9ab4b r9=4 f=c13|f=444/10
  #|test qword ptr [rdi + 0x10], r15|4c857f10|TEST64mr:%RDI,1,%,16,%,%R15|rbx=6 r9=9 r15=74c00ffd3f3457c9 f=8c6 m10110=b01c664190895fb44fea91ad18dd5ac8|f=0/10
  #|test qword ptr [rdi + 0x10], r15|4c857f10|TEST64mr:%RDI,1,%,16,%,%R15|rbx=4 r9=d r15=a6 f=4d2 m10110=2a8606488c2a2c06ca8d57009355ab37|f=404/10
  #|test r14, 0x100|49f7c600010000|TEST64ri32:%R14,256|r14=44c911b4e009e0fa f=83|f=44/10
  #|test r14, 0x100|49f7c600010000|TEST64ri32:%R14,256|r14=51434cd684328b54 f=7|f=4/10
  #|test rax, -0x80000000|48a900000080|TEST64i32:-2147483648|rax=5d2308244cbecfe4 f=92|f=4/10
  #|test rax, -0x80000000|48a900000080|TEST64i32:-2147483648|rax=fffffffffffffffe f=83|f=84/10
  #|test qword ptr [rbp - 0x20], 0x12345678|48f745e078563412|TEST64mi32:%RBP,1,%,-32,%,305419896|rbx=7 r9=c f=456 m20160=10cc87da52898194ab79513c96e1181e|f=400/10
  #|test qword ptr [rbp - 0x20], 0x12345678|48f745e078563412|TEST64mi32:%RBP,1,%,-32,%,305419896|rbx=3 r9=3 f=8d3 m20160=1b1f80ecb112e9c896b831e41d419053|f=4/10
  #|add eax, ebx (03)|03c3|ADD32rr_REV:%EAX,%EAX,%EBX|rax=7c4ca8d46c58fab0 rbx=7fffffff f=57|rax=ec58faaf f=884/0
  #|add eax, ebx (03)|03c3|ADD32rr_REV:%EAX,%EAX,%EBX|rax=221e21f352255c06 rbx=79f5b9af23410eff f=53|rax=75666b05 f=14/0
  #|add eax, ebx (03)|03c3|ADD32rr_REV:%EAX,%EAX,%EBX|rax=ccc2ca97b31e3a5b rbx=51e23fa0d5daa7d9 f=47|rax=88f8e234 f=91/0
  #|sub ecx, edx (2b)|2bca|SUB32rr_REV:%ECX,%ECX,%EDX|rcx=c12e4a2e534664be rdx=ac4c26afc35d1dc6 f=847|rcx=8fe946f8 f=881/0
  #|sub ecx, edx (2b)|2bca|SUB32rr_REV:%ECX,%ECX,%EDX|rcx=13b2fb9b0f653896 rdx=a158f10b87cdb232 f=c6|rcx=87978664 f=881/0
  #|sub ecx, edx (2b)|2bca|SUB32rr_REV:%ECX,%ECX,%EDX|rcx=da2521f1a4f745 rdx=a6d7a07475fb653d f=42|rcx=7ba99208 f=810/0
  #|xor al, bl (32)|32c3|XOR8rr_REV:%AL,%AL,%BL|rax=3fa8d65fbbd59382 rbx=ff3e81b3e470f53b f=802|rax=3fa8d65fbbd593b9 f=80/10
  #|xor al, bl (32)|32c3|XOR8rr_REV:%AL,%AL,%BL|rax=c347c37df4ca05 rbx=d6 f=4d6|rax=c347c37df4cad3 f=480/10
  #|xor al, bl (32)|32c3|XOR8rr_REV:%AL,%AL,%BL|rax=b50fe5af700360f2 rbx=8000000000000000 f=443|f=480/10
  #|cmp edx, eax (3b)|3bd0|CMP32rr_REV:%EDX,%EAX|rax=40932ec802628000 rdx=7fff f=4c2|f=485/0
  #|cmp edx, eax (3b)|3bd0|CMP32rr_REV:%EDX,%EAX|rax=d8b7a195cb48b238 rdx=7b73faabe14c9aa f=d6|f=85/0
  #|cmp edx, eax (3b)|3bd0|CMP32rr_REV:%EDX,%EAX|rax=dcc4bd95a527dd61 rdx=35a4d886715df5c3 f=806|f=881/0
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|rax=7fffffffffffffff rcx=721dbfd3909d5138 f=d7|rax=909d5138 f=91/0
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|rax=f rcx=e1d3937a1cc17d74 f=8d7|rax=1cc17d84 f=14/0
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|rax=80 rcx=0 f=8d7|rax=81 f=4/0
  #|sbb eax, ecx (1b)|1bc1|SBB32rr_REV:%EAX,%EAX,%ECX|rax=70e03026955ccf3f rcx=1da9d82972ca38c4 f=817|rax=2292967a f=800/0
  #|sbb eax, ecx (1b)|1bc1|SBB32rr_REV:%EAX,%EAX,%ECX|rax=30016b7ed05ff902 rcx=4d f=17|rax=d05ff8b4 f=94/0
  #|sbb eax, ecx (1b)|1bc1|SBB32rr_REV:%EAX,%EAX,%ECX|rax=7e147b7b259a4ed5 rcx=6866e10d40d5a7c1 f=456|rax=e4c4a714 f=485/0
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|rax=231066699e427664 rcx=29ac f=c7|rax=2024 f=4/10
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|rax=566fff70d664bbf7 rcx=7e5db54edb28ade9 f=8c7|rax=d220a9e1 f=84/10
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|rax=a3ab95c4e05561fc rcx=2b06f7f096fef382 f=882|rax=80546180 f=80/10
  #|or eax, ecx (0b)|0bc1|OR32rr_REV:%EAX,%EAX,%ECX|rax=df8449e8a1ec89ca rcx=f005364c6fe66210 f=846|rax=efeeebda f=80/10
  #|or eax, ecx (0b)|0bc1|OR32rr_REV:%EAX,%EAX,%ECX|rax=e41fee20fe613139 rcx=9370ae14d6257fff f=97|rax=fe657fff f=84/10
  #|or eax, ecx (0b)|0bc1|OR32rr_REV:%EAX,%EAX,%ECX|rax=11770e199c3026ff rcx=25e6a71af72bb6a f=d3|rax=bf72bfff f=84/10
  #|inc cl|fec1|INC8r:%CL,%CL|rcx=0 f=52|rcx=1 f=0/0
  #|inc cl|fec1|INC8r:%CL,%CL|rcx=1fab7b0945ac32ff f=8c7|rcx=1fab7b0945ac3200 f=55/0
  #|inc cl|fec1|INC8r:%CL,%CL|rcx=b8ab1e1a2e6e0b5c f=cc6|rcx=b8ab1e1a2e6e0b5d f=400/0
  #|inc byte ptr [rsp + 0x8]|fe442408|INC8m:%RSP,1,%,8,%|rbx=0 r9=9 f=803 m20108=fa419aa09d10f833e696034bf5f07904|f=81/0 m20108=fb
  #|inc byte ptr [rsp + 0x8]|fe442408|INC8m:%RSP,1,%,8,%|rbx=2 r9=0 f=c16 m20108=4e81d2298f640ba8d7a452f8b2f82c89|f=400/0 m20108=4f
  #|inc dx|66ffc2|INC16r:%DX,%DX|rdx=fd482ae2a144d6c3 f=c97|rdx=fd482ae2a144d6c4 f=481/0
  #|inc dx|66ffc2|INC16r:%DX,%DX|rdx=2 f=13|rdx=3 f=5/0
  #|inc dx|66ffc2|INC16r:%DX,%DX|rdx=14501a5ec6985382 f=847|rdx=14501a5ec6985383 f=1/0
  #|inc word ptr [rdi + 0x10]|66ff4710|INC16m:%RDI,1,%,16,%|rbx=b r9=d f=82 m10110=0ddc56fc891baf1b2d93865cf26b2454|f=80/0 m10110=0e
  #|inc word ptr [rdi + 0x10]|66ff4710|INC16m:%RDI,1,%,16,%|rbx=a r9=e f=c46 m10110=baa601c422cfb8f763c1518b8175d64e|f=484/0 m10110=bb
  #|inc r15d|41ffc7|INC32r:%R15D,%R15D|r15=ed f=82|r15=ee f=4/0
  #|inc r15d|41ffc7|INC32r:%R15D,%R15D|r15=582bbb156f205094 f=852|r15=6f205095 f=4/0
  #|inc r15d|41ffc7|INC32r:%R15D,%R15D|r15=c25627e17e2b5623 f=82|r15=7e2b5624 f=4/0
  #|inc dword ptr [rdi + r9*2 - 0x4]|42ff444ffc|INC32m:%RDI,2,%R9,-4,%|rbx=f r9=5 f=857 m10106=93b0cb669176a216d80820f2ceaf47d6|f=1/0 m10106=94
  #|inc dword ptr [rdi + r9*2 - 0x4]|42ff444ffc|INC32m:%RDI,2,%R9,-4,%|rbx=4 r9=b f=803 m10112=189afb97a978b100d778cb757f2b4fa0|f=81/0 m10112=19
  #|inc r9|49ffc1|INC64r:%R9,%R9|r9=46f47b70aab07c1d f=842|r9=46f47b70aab07c1e f=4/0
  #|inc r9|49ffc1|INC64r:%R9,%R9|r9=5e27628231e34445 f=c82|r9=5e27628231e34446 f=400/0
  #|inc r9|49ffc1|INC64r:%R9,%R9|r9=7eb7d4ef614fb7cc f=857|r9=7eb7d4ef614fb7cd f=1/0
  #|inc qword ptr [rdi + r9*2 - 0x4]|4aff444ffc|INC64m:%RDI,2,%R9,-4,%|rbx=e r9=9 f=802 m1010e=17af0388be7fbd7231c13ae3bfab5c06|f=4/0 m1010e=18
  #|inc qword ptr [rdi + r9*2 - 0x4]|4aff444ffc|INC64m:%RDI,2,%R9,-4,%|rbx=0 r9=b f=856 m10112=9b48a21db3a414d799d6ae8da39dc2e6|f=84/0 m10112=9c
  #|dec r10b|41feca|DEC8r:%R10B,%R10B|r10=1a448c7d1f93ee12 f=842|r10=1a448c7d1f93ee11 f=4/0
  #|dec r10b|41feca|DEC8r:%R10B,%R10B|r10=4 f=43|r10=3 f=5/0
  #|dec r10b|41feca|DEC8r:%R10B,%R10B|r10=aad47663fe953eda f=13|r10=aad47663fe953ed9 f=81/0
  #|dec byte ptr [rsp + 0x8]|fe4c2408|DEC8m:%RSP,1,%,8,%|rbx=1 r9=7 f=17 m20108=dcfd42bd2973eb153c0df13bb50eaf70|f=85/0 m20108=db
  #|dec byte ptr [rsp + 0x8]|fe4c2408|DEC8m:%RSP,1,%,8,%|rbx=e r9=5 f=407 m20108=82e98ae3b93361638769f742d1fc87a7|f=485/0 m20108=81
  #|dec dx|66ffca|DEC16r:%DX,%DX|rdx=7fbb27bcfeba5280 f=c83|rdx=7fbb27bcfeba527f f=411/0
  #|dec dx|66ffca|DEC16r:%DX,%DX|rdx=a7185df0eae4991 f=c03|rdx=a7185df0eae4990 f=405/0
  #|dec dx|66ffca|DEC16r:%DX,%DX|rdx=f93afef6c76e7f00 f=4c7|rdx=f93afef6c76e7eff f=415/0
  #|dec word ptr [rdi + 0x10]|66ff4f10|DEC16m:%RDI,1,%,16,%|rbx=e r9=c f=c13 m10110=629e8c0729e44ce922cd0dee75a46686|f=481/0 m10110=61
  #|dec word ptr [rdi + 0x10]|66ff4f10|DEC16m:%RDI,1,%,16,%|rbx=c r9=e f=47 m10110=120bb268e0b6ae97d3f08963ecb50853|f=5/0 m10110=11
  #|dec r14d|41ffce|DEC32r:%R14D,%R14D|r14=dd42e8a8340f1f2a f=887|r14=340f1f29 f=1/0
  #|dec r14d|41ffce|DEC32r:%R14D,%R14D|r14=e1d91a5ed12b4fee f=497|r14=d12b4fed f=485/0
  #|dec r14d|41ffce|DEC32r:%R14D,%R14D|r14=69b15b54046ea8bc f=806|r14=46ea8bb f=4/0
  #|dec dword ptr [rsi + rbx*4 + 0x8]|ff4c9e08|DEC32m:%RSI,4,%RBX,8,%|rbx=6 r9=8 f=8d7 m100a0=75b6d8d113a0e9a931709599b3d2a9c9|f=85/0 m100a0=74
  #|dec dword ptr [rsi + rbx*4 + 0x8]|ff4c9e08|DEC32m:%RSI,4,%RBX,8,%|rbx=a r9=a f=13 m100b0=4c6687d468057bc1c3eace0998453494|f=85/0 m100b0=4b
  #|dec r14|49ffce|DEC64r:%R14,%R14|r14=2d73bceaee3b1015 f=8d6|r14=2d73bceaee3b1014 f=4/0
  #|dec r14|49ffce|DEC64r:%R14,%R14|r14=6c775608f21ce7fc f=407|r14=6c775608f21ce7fb f=401/0
  #|dec r14|49ffce|DEC64r:%R14,%R14|r14=6b93a6fae7036db4 f=483|r14=6b93a6fae7036db3 f=401/0
  #|dec qword ptr [rsi + rbx*4 + 0x8]|48ff4c9e08|DEC64m:%RSI,4,%RBX,8,%|rbx=5 r9=1 f=c02 m1009c=8efec70e20e9fc417940900e78fe5935|f=404/0 m1009c=8d
  #|dec qword ptr [rsi + rbx*4 + 0x8]|48ff4c9e08|DEC64m:%RSI,4,%RBX,8,%|rbx=1 r9=9 f=853 m1008c=9f005909f27f0953249c7dd6c2ca16b6|f=1/0 m1008c=9e
  #|neg al|f6d8|NEG8r:%AL,%AL|rax=f4dfef3b090559e5 f=42|rax=f4dfef3b0905591b f=15/0
  #|neg al|f6d8|NEG8r:%AL,%AL|rax=408c3180cbd9ad51 f=87|rax=408c3180cbd9adaf f=95/0
  #|neg al|f6d8|NEG8r:%AL,%AL|rax=1c7cba9527cee7b f=42|rax=1c7cba9527cee85 f=91/0
  #|neg byte ptr [rdi + r9*2 - 0x4]|42f65c4ffc|NEG8m:%RDI,2,%R9,-4,%|rbx=2 r9=7 f=897 m1010a=7d2efc3bbc9851b8a2fd73136bd78ee0|f=91/0 m1010a=83
  #|neg byte ptr [rdi + r9*2 - 0x4]|42f65c4ffc|NEG8m:%RDI,2,%R9,-4,%|rbx=5 r9=5 f=46 m10106=9494eacfbe0a46e6a4e85c3a7f1f75b3|f=15/0 m10106=6c
  #|neg dx|66f7da|NEG16r:%DX,%DX|rdx=5862df0d0fd74aff f=853|rdx=5862df0d0fd7b501 f=91/0
  #|neg dx|66f7da|NEG16r:%DX,%DX|rdx=ef2c76e4da1bac11 f=487|rdx=ef2c76e4da1b53ef f=411/0
  #|neg dx|66f7da|NEG16r:%DX,%DX|rdx=178a7349a05a7b8a f=4c7|rdx=178a7349a05a8476 f=491/0
  #|neg word ptr [rsi]|66f71e|NEG16m:%RSI,1,%,0,%|rbx=b r9=a f=42 m10080=f81dd6d4932a964f841b1d12ba9cb4f8|f=91/0 m10080=08e2
  #|neg word ptr [rsi]|66f71e|NEG16m:%RSI,1,%,0,%|rbx=6 r9=b f=803 m10080=9fa885cd81a9cf71728b70d2f4dd39ef|f=11/0 m10080=6157
  #|neg r15d|41f7df|NEG32r:%R15D,%R15D|r15=26a4f14a714c7d0c f=c06|r15=8eb382f4 f=491/0
  #|neg r15d|41f7df|NEG32r:%R15D,%R15D|r15=70533bf9e38e6148 f=882|r15=1c719eb8 f=15/0
  #|neg r15d|41f7df|NEG32r:%R15D,%R15D|r15=1627de3ea8889412 f=46|r15=57776bee f=15/0
  #|neg dword ptr [rdi + 0x10]|f75f10|NEG32m:%RDI,1,%,16,%|rbx=c r9=3 f=807 m10110=2e35521f77728512e019d74d051d3181|f=95/0 m10110=d2caade0
  #|neg dword ptr [rdi + 0x10]|f75f10|NEG32m:%RDI,1,%,16,%|rbx=d r9=5 f=d6 m10110=aaf169b6676a21aea68a9ffe3220e760|f=15/0 m10110=560e9649
  #|neg rax|48f7d8|NEG64r:%RAX,%RAX|rax=2aa164cf284058ec f=2|rax=d55e9b30d7bfa714 f=95/0
  #|neg rax|48f7d8|NEG64r:%RAX,%RAX|rax=49db2d2b2a7c3eb3 f=6|rax=b624d2d4d583c14d f=95/0
  #|neg rax|48f7d8|NEG64r:%RAX,%RAX|rax=3c7a7f9d3d4a6f2e f=802|rax=c3858062c2b590d2 f=95/0
  #|neg qword ptr [rbp - 0x20]|48f75de0|NEG64m:%RBP,1,%,-32,%|rbx=a r9=2 f=57 m20160=748ab016f563f9bb67cabb75766e8e6e|f=11/0 m20160=8c754fe90a9c0644
  #|neg qword ptr [rbp - 0x20]|48f75de0|NEG64m:%RBP,1,%,-32,%|rbx=a r9=2 f=82 m20160=521c52065a83a9937626e5b8545149dd|f=11/0 m20160=aee3adf9a57c566c
  #|not r8b|41f6d0|NOT8r:%R8B,%R8B|r8=cfb651cc5f651051 f=c12|r8=cfb651cc5f6510ae f=c10/0
  #|not r8b|41f6d0|NOT8r:%R8B,%R8B|r8=b3c04db728f3b7be f=803|r8=b3c04db728f3b741 f=801/0
  #|not r8b|41f6d0|NOT8r:%R8B,%R8B|r8=1bc650d893a87a38 f=897|r8=1bc650d893a87ac7 f=895/0
  #|not byte ptr [rdi + 0x10]|f65710|NOT8m:%RDI,1,%,16,%|rbx=5 r9=5 f=457 m10110=bf18fa558fe929f9b1efb06274105049|f=455/0 m10110=40
  #|not byte ptr [rdi + 0x10]|f65710|NOT8m:%RDI,1,%,16,%|rbx=8 r9=1 f=42 m10110=818077645df1e482fa864ab32649a979|f=40/0 m10110=7e
  #|not r13w|6641f7d5|NOT16r:%R13W,%R13W|r13=7632fad9c9c70d95 f=8c7|r13=7632fad9c9c7f26a f=8c5/0
  #|not r13w|6641f7d5|NOT16r:%R13W,%R13W|r13=6c9d4a4c8fe789b5 f=c52|r13=6c9d4a4c8fe7764a f=c50/0
  #|not r13w|6641f7d5|NOT16r:%R13W,%R13W|r13=0 f=d6|r13=ffff f=d4/0
  #|not word ptr [rbp - 0x20]|66f755e0|NOT16m:%RBP,1,%,-32,%|rbx=7 r9=c f=856 m20160=2ed19e642a727fb9c4a16258343bd16f|f=854/0 m20160=d12e
  #|not word ptr [rbp - 0x20]|66f755e0|NOT16m:%RBP,1,%,-32,%|rbx=8 r9=c f=407 m20160=57e5d3384a5bffe31d351d562773b9d2|f=405/0 m20160=a81a
  #|not r10d|41f7d2|NOT32r:%R10D,%R10D|r10=80af137806d5ef44 f=893|r10=f92a10bb f=891/0
  #|not r10d|41f7d2|NOT32r:%R10D,%R10D|r10=f64e f=46|r10=ffff09b1 f=44/0
  #|not r10d|41f7d2|NOT32r:%R10D,%R10D|r10=e0d938cc56ce7472 f=457|r10=a9318b8d f=455/0
  #|not dword ptr [rsi]|f716|NOT32m:%RSI,1,%,0,%|rbx=0 r9=e f=857 m10080=3991fda2846fd5b5496d2a3de61be350|f=855/0 m10080=c66e025d
  #|not dword ptr [rsi]|f716|NOT32m:%RSI,1,%,0,%|rbx=a r9=a f=846 m10080=fb74f4ab8bd51447f64c95632b7615e2|f=844/0 m10080=048b0b54
  #|not rbx|48f7d3|NOT64r:%RBX,%RBX|rbx=1f5cb880dd888000 f=82|rbx=e0a3477f22777fff f=80/0
  #|not rbx|48f7d3|NOT64r:%RBX,%RBX|rbx=960668fa53c88000 f=406|rbx=69f99705ac377fff f=404/0
  #|not rbx|48f7d3|NOT64r:%RBX,%RBX|rbx=875a7b9e8361927f f=82|rbx=78a584617c9e6d80 f=80/0
  #|not qword ptr [rsi]|48f716|NOT64m:%RSI,1,%,0,%|rbx=e r9=6 f=487 m10080=efd7c0aa1548dbf4d77cfe4cfcf34fb2|f=485/0 m10080=10283f55eab7240b
  #|not qword ptr [rsi]|48f716|NOT64m:%RSI,1,%,0,%|rbx=9 r9=5 f=8c3 m10080=25ab421840bd702303de4a6ddea50568|f=8c1/0 m10080=da54bde7bf428fdc

///|
let alu32_cases : String =
  #|add dh, al|00c6|ADD8rr:%DH,%DH,%AL|eax=0 edx=7a99 f=806|f=0/0
  #|add dh, al|00c6|ADD8rr:%DH,%DH,%AL|eax=f9 edx=f3917fff f=852|edx=f39178ff f=15/0
  #|add byte ptr [esi], al|0006|ADD8mr:%ESI,1,%,0,%,%AL|eax=ba6404d4 ebx=2 f=93 m10080=8862b76ae3f4d818ed6bcae77d4f3653|f=805/0 m10080=5c
  #|add byte ptr [esi], al|0006|ADD8mr:%ESI,1,%,0,%,%AL|eax=21a80ec ebx=4 f=8d3 m10080=a30b74f37bff662824bfd0bade54fba8|f=81/0 m10080=8f
  #|add dl, 0x1|80c201|ADD8ri:%DL,%DL,1|edx=2b f=42|edx=2c f=0/0
  #|add dl, 0x1|80c201|ADD8ri:%DL,%DL,1|edx=2039d09e f=c83|edx=2039d09f f=484/0
  #|add ax, word ptr [esi]|660306|ADD16rm:%AX,%AX,%ESI,1,%,0,%|eax=c513587b ebx=0 f=807 m10080=7a2ba024e714737288653588f249e93f|eax=c51383f5 f=894/0
  #|add ax, word ptr [esi]|660306|ADD16rm:%AX,%AX,%ESI,1,%,0,%|eax=3a840205 ebx=e f=852 m10080=7c89f47d0921d7ab137c097958be4a7d|eax=3a848b81 f=94/0
  #|add dx, 0x7fff|6681c2ff7f|ADD16ri:%DX,%DX,32767|edx=80c78e50 f=c17|edx=80c70e4f f=401/0
  #|add dx, 0x7fff|6681c2ff7f|ADD16ri:%DX,%DX,32767|edx=c3d4f2c0 f=87|edx=c3d472bf f=1/0
  #|add word ptr [esp + 0x8], -0x3|6683442408fd|ADD16mi8:%ESP,1,%,8,%,-3|ebx=e f=87 m20108=0726a73be5ec1efae4bc6354f81fd4a3|f=11/0 m20108=04
  #|add word ptr [esp + 0x8], -0x3|6683442408fd|ADD16mi8:%ESP,1,%,8,%,-3|ebx=e f=807 m20108=5492bcf63cf6a4665160e348bc1fc7aa|f=91/0 m20108=51
  #|add ecx, ebx|01d9|ADD32rr:%ECX,%ECX,%EBX|ecx=67bf211 ebx=2 f=c43|ecx=67bf213 f=400/0
  #|add ecx, ebx|01d9|ADD32rr:%ECX,%ECX,%EBX|ecx=8ddffc84 ebx=2e f=8c7|ecx=8ddffcb2 f=94/0
  #|add ecx, ebx|01d9|ADD32rr:%ECX,%ECX,%EBX|ecx=a80b25f1 ebx=a865fe72 f=4c2|ecx=50712463 f=c05/0
  #|add ecx, ebx|01d9|ADD32rr:%ECX,%ECX,%EBX|ecx=8fc5d2ce ebx=80000000 f=17|ecx=fc5d2ce f=801/0
  #|add ebx, 0x7f|83c37f|ADD32ri8:%EBX,%EBX,127|ebx=982a87aa f=7|ebx=982a8829 f=90/0
  #|add ebx, 0x7f|83c37f|ADD32ri8:%EBX,%EBX,127|ebx=fffffffe f=8d7|ebx=7d f=15/0
  #|add eax, 0x80|0580000000|ADD32i32:128|eax=7b2d68dc f=cc2|eax=7b2d695c f=404/0
  #|add eax, 0x80|0580000000|ADD32i32:128|eax=b9c3cfc6 f=882|eax=b9c3d046 f=80/0
  #|or ch, al|08c5|OR8rr:%CH,%CH,%AL|eax=fe9c87d7 ecx=2bc7ce99 f=c46|ecx=2bc7df99 f=480/10
  #|or ch, al|08c5|OR8rr:%CH,%CH,%AL|eax=a7746159 ecx=217725b4 f=d3|ecx=21777db4 f=4/10
  #|or ch, dl|08d5|OR8rr:%CH,%CH,%DL|ecx=be0a3cc0 edx=7f f=83|ecx=be0a7fc0 f=0/10
  #|or ch, dl|08d5|OR8rr:%CH,%CH,%DL|ecx=8a5ac399 edx=42105b17 f=803|ecx=8a5ad799 f=84/10
  #|or byte ptr [edi + 0x10], dl|085710|OR8mr:%EDI,1,%,16,%,%DL|edx=2a14e867 ebx=0 f=856 m10110=97f61fdb9eb83bd870d6553a8ec3d6c2|f=80/10 m10110=f7
  #|or byte ptr [edi + 0x10], dl|085710|OR8mr:%EDI,1,%,16,%,%DL|edx=b724d356 ebx=7 f=8d7 m10110=2d60906fa33698fcbc393534968413cf|f=0/10 m10110=7f
  #|or dl, byte ptr [ebp - 0x20]|0a55e0|OR8rm:%DL,%DL,%EBP,1,%,-32,%|edx=1 ebx=e f=92 m20160=28021551ac032099bfda7e4eea452cbe|edx=29 f=0/10
  #|or dl, byte ptr [ebp - 0x20]|0a55e0|OR8rm:%DL,%DL,%EBP,1,%,-32,%|edx=6abfb090 ebx=1 f=886 m20160=406e6ce934d94f4854431f77372c5493|edx=6abfb0d0 f=80/10
  #|or dl, 0xff|80caff|OR8ri:%DL,%DL,-1|edx=6d328a5c f=d6|edx=6d328aff f=84/10
  #|or dl, 0xff|80caff|OR8ri:%DL,%DL,-1|edx=6105407f f=402|edx=610540ff f=484/10
  #|or byte ptr [esi + ebx*4 + 0x8], 0x0|804c9e0800|OR8mi:%ESI,4,%EBX,8,%,0|ebx=9 f=893 m100ac=8ecb82831f851b1eb660a97a3fec7c86|f=84/10
  #|or byte ptr [esi + ebx*4 + 0x8], 0x0|804c9e0800|OR8mi:%ESI,4,%EBX,8,%,0|ebx=a f=12 m100b0=b7f4fbe0ae7ac3fb4f764f4d2f91fb82|f=84/10
  #|or cx, bx|6609d9|OR16rr:%CX,%CX,%BX|ecx=ffffffff ebx=d4158da3 f=856|f=84/10
  #|or cx, bx|6609d9|OR16rr:%CX,%CX,%BX|ecx=0 ebx=8c0935cf f=892|ecx=35cf f=4/10
  #|or ax, 0x7fff|660dff7f|OR16i16:32767|eax=61a884db f=856|eax=61a8ffff f=84/10
  #|or ax, 0x7fff|660dff7f|OR16i16:32767|eax=b28bb964 f=8d6|eax=b28bffff f=84/10
  #|or word ptr [edi + 0x10], -0x1|66834f10ff|OR16mi8:%EDI,1,%,16,%,-1|ebx=7 f=812 m10110=99ea98a8575176b8df4c6943c765779e|f=84/10 m10110=ffff
  #|or word ptr [edi + 0x10], -0x1|66834f10ff|OR16mi8:%EDI,1,%,16,%,-1|ebx=3 f=892 m10110=7bf21743b5e56723a7b63a0fbb0f4846|f=84/10 m10110=ffff
  #|or edx, ecx|09ca|OR32rr:%EDX,%EDX,%ECX|ecx=cbd6cdab edx=7fffffff f=882|edx=ffffffff f=84/10
  #|or edx, ecx|09ca|OR32rr:%EDX,%EDX,%ECX|ecx=ffffffff edx=9e6d9ded f=87|edx=ffffffff f=84/10
  #|or eax, ebx|09d8|OR32rr:%EAX,%EAX,%EBX|eax=bb2a10bd ebx=bce2339c f=2|eax=bfea33bd f=84/10
  #|or eax, ebx|09d8|OR32rr:%EAX,%EAX,%EBX|eax=35a9c ebx=7fffffff f=c03|eax=7fffffff f=404/10
  #|or dword ptr [esp + 0x8], ebx|095c2408|OR32mr:%ESP,1,%,8,%,%EBX|ebx=7 f=cc3 m20108=e8b19dc42554bcdeb291331420a4df1f|f=480/10 m20108=ef
  #|or dword ptr [esp + 0x8], ebx|095c2408|OR32mr:%ESP,1,%,8,%,%EBX|ebx=6 f=16 m20108=cf55629d8fd61c32f3df181f2f31a9a6|f=84/10
  #|or ebx, dword ptr [esi + ebx*4 + 0x8]|0b5c9e08|OR32rm:%EBX,%EBX,%ESI,4,%EBX,8,%|ebx=f f=8d2 m100c4=2cb0598bae03f948eb00745c7a1ac611|ebx=8b59b02f f=80/10
  #|or ebx, dword ptr [esi + ebx*4 + 0x8]|0b5c9e08|OR32rm:%EBX,%EBX,%ESI,4,%EBX,8,%|ebx=b f=c6 m100b4=525c3850e70e44441e44bb0016aa588e|ebx=50385c5b f=0/10
  #|or edx, 0x1|83ca01|OR32ri8:%EDX,%EDX,1|edx=f64e8ff f=c42|f=404/10
  #|or edx, 0x1|83ca01|OR32ri8:%EDX,%EDX,1|edx=4f4edc86 f=d3|edx=4f4edc87 f=4/10
  #|or edx, 0x12345678|81ca78563412|OR32ri:%EDX,%EDX,305419896|edx=e2f5c4e1 f=93|edx=f2f5d6f9 f=84/10
  #|or edx, 0x12345678|81ca78563412|OR32ri:%EDX,%EDX,305419896|edx=96b3f3f8 f=97|edx=96b7f7f8 f=80/10
  #|or eax, 0x7fffffff|0dffffff7f|OR32i32:2147483647|eax=c f=46|eax=7fffffff f=4/10
  #|or eax, 0x7fffffff|0dffffff7f|OR32i32:2147483647|eax=a6398916 f=856|eax=ffffffff f=84/10
  #|or dword ptr [esp + 0x8], 0x1|834c240801|OR32mi8:%ESP,1,%,8,%,1|ebx=f f=3 m20108=40d04cc7271200042432f379ae6f499e|f=84/10 m20108=41
  #|or dword ptr [esp + 0x8], 0x1|834c240801|OR32mi8:%ESP,1,%,8,%,1|ebx=2 f=c6 m20108=ae5b6a0ee5a67b3807f66c0e1171423b|f=4/10 m20108=af
  #|adc ch, bl|10dd|ADC8rr:%CH,%CH,%BL|ecx=d29221b3 ebx=80000000 f=c43|ecx=d29222b3 f=404/0
  #|adc ch, bl|10dd|ADC8rr:%CH,%CH,%BL|ecx=554836f7 ebx=51afc097 f=93|ecx=5548cef7 f=80/0
  #|adc ah, dl|10d4|ADC8rr:%AH,%AH,%DL|eax=c4ba6141 edx=6573d2ca f=8c7|eax=c4ba2c41 f=1/0
  #|adc ah, dl|10d4|ADC8rr:%AH,%AH,%DL|eax=80000000 edx=ffffffff f=86|eax=8000ff00 f=84/0
  #|adc cx, dx|6611d1|ADC16rr:%CX,%CX,%DX|ecx=6b2c8499 edx=430045a6 f=83|ecx=6b2cca40 f=90/0
  #|adc cx, dx|6611d1|ADC16rr:%CX,%CX,%DX|ecx=c5c0c8c edx=8000 f=886|ecx=c5c8c8c f=80/0
  #|adc word ptr [esp + 0x8], ax|6611442408|ADC16mr:%ESP,1,%,8,%,%AX|eax=7c1558cc ebx=4 f=852 m20108=2f645b0f6841e2ba213988c4261ae2e0|f=890/0 m20108=fbbc
  #|adc word ptr [esp + 0x8], ax|6611442408|ADC16mr:%ESP,1,%,8,%,%AX|eax=80000000 ebx=1 f=7 m20108=0dbe4f3ecff505246cdbe3fd3bb1a13d|f=80/0 m20108=0e
  #|adc ax, word ptr [esi + ebx*4 + 0x8]|6613449e08|ADC16rm:%AX,%AX,%ESI,4,%EBX,8,%|eax=f ebx=8 f=d2 m100a8=214bc0605add8a99ee762d2d4a0946b4|eax=4b30 f=14/0
  #|adc ax, word ptr [esi + ebx*4 + 0x8]|6613449e08|ADC16rm:%AX,%AX,%ESI,4,%EBX,8,%|eax=7ffe9eed ebx=1 f=47 m1008c=ec3e4a158b32167ba890141eb00d4db2|eax=7ffeddda f=90/0
  #|adc cx, 0x7f|6683d17f|ADC16ri8:%CX,%CX,127|ecx=2910862d f=87|ecx=291086ad f=90/0
  #|adc cx, 0x7f|6683d17f|ADC16ri8:%CX,%CX,127|ecx=5ebcf50e f=87|ecx=5ebcf58e f=94/0
  #|adc edx, eax|11c2|ADC32rr:%EDX,%EDX,%EAX|eax=ff edx=981990be f=852|edx=981991bd f=94/0
  #|adc edx, eax|11c2|ADC32rr:%EDX,%EDX,%EAX|eax=eace edx=4266c8fa f=87|edx=4267b3c9 f=14/0
  #|adc ecx, edx|11d1|ADC32rr:%ECX,%ECX,%EDX|ecx=d64cbf31 edx=c786e375 f=8c6|ecx=9dd3a2a6 f=85/0
  #|adc ecx, edx|11d1|ADC32rr:%ECX,%ECX,%EDX|ecx=833b5570 edx=202b8882 f=452|ecx=a366ddf2 f=480/0
  #|adc dword ptr [esp + 0x8], eax|11442408|ADC32mr:%ESP,1,%,8,%,%EAX|eax=18514974 ebx=9 f=406 m20108=92ea135121a8450c6736b51988218394|f=404/0 m20108=06346569
  #|adc dword ptr [esp + 0x8], eax|11442408|ADC32mr:%ESP,1,%,8,%,%EAX|eax=d7b70500 ebx=0 f=2 m20108=8970737bc879ce10e0b406f7e8c6dfe6|f=1/0 m20109=752a53
  #|adc eax, dword ptr [edi + 0x10]|134710|ADC32rm:%EAX,%EAX,%EDI,1,%,16,%|eax=44 ebx=b f=487 m10110=15433e3bc9d9522ca3148f7600c8cb97|eax=3b3e435a f=404/0
  #|adc eax, dword ptr [edi + 0x10]|134710|ADC32rm:%EAX,%EAX,%EDI,1,%,16,%|eax=984d3500 ebx=3 f=56 m10110=f9b5e8175df1e1cbf37eaebd5c0c7c3d|eax=b035eaf9 f=84/0
  #|adc edx, -0x80000000|81d200000080|ADC32ri:%EDX,%EDX,2147483648|edx=df179745 f=8d6|edx=5f179745 f=801/0
  #|adc edx, -0x80000000|81d200000080|ADC32ri:%EDX,%EDX,2147483648|edx=924b4aa0 f=882|edx=124b4aa0 f=805/0
  #|adc eax, 0x7fffffff|15ffffff7f|ADC32i32:2147483647|eax=bbe400b6 f=496|eax=3be400b5 f=411/0
  #|adc eax, 0x7fffffff|15ffffff7f|ADC32i32:2147483647|eax=f2d67fff f=806|eax=72d67ffe f=11/0
  #|adc dword ptr [esp + 0x8], -0x1|83542408ff|ADC32mi8:%ESP,1,%,8,%,-1|ebx=a f=13 m20108=fe07f9fe556c9013bc3aba7e2c7df329|f=91/0
  #|adc dword ptr [esp + 0x8], -0x1|83542408ff|ADC32mi8:%ESP,1,%,8,%,-1|ebx=6 f=806 m20108=146889ca143da5c5e647b17ae9b5b7c4|f=91/0 m20108=13
  #|sbb bl, byte ptr [edi + 0x10]|1a5f10|SBB8rm:%BL,%BL,%EDI,1,%,16,%|ebx=f f=47 m10110=d8e3ee83378cc6bf6093a22a7d64723a|ebx=36 f=5/0
  #|sbb bl, byte ptr [edi + 0x10]|1a5f10|SBB8rm:%BL,%BL,%EDI,1,%,16,%|ebx=5 f=846 m10110=aecbcf22c3589ab080d271fec42c990d|ebx=57 f=11/0
  #|sbb al, 0xff|1cff|SBB8i8:-1|eax=43655b84 f=52|eax=43655b85 f=91/0
  #|sbb al, 0xff|1cff|SBB8i8:-1|eax=1ba2 f=2|eax=1ba3 f=95/0
  #|sbb bx, ax|6619c3|SBB16rr:%BX,%BX,%AX|eax=ad00ebe1 ebx=ffffffff f=456|ebx=ffff141e f=404/0
  #|sbb bx, ax|6619c3|SBB16rr:%BX,%BX,%AX|eax=cc98b7d1 ebx=1a7aef60 f=2|ebx=1a7a378f f=10/0
  #|sbb bx, dx|6619d3|SBB16rr:%BX,%BX,%DX|edx=c5 ebx=b5153b84 f=cd2|ebx=b5153abf f=410/0
  #|sbb bx, dx|6619d3|SBB16rr:%BX,%BX,%DX|edx=b2 ebx=d8a41881 f=c83|ebx=d8a417ce f=410/0
  #|sbb word ptr [esi + ebx*4 + 0x8], ax|6619449e08|SBB16mr:%ESI,4,%EBX,8,%,%AX|eax=ad89f4dd ebx=0 f=496 m10088=97453b3c7cd288cbfbac382b1968c4a7|f=411/0 m10088=ba50
  #|sbb word ptr [esi + ebx*4 + 0x8], ax|6619449e08|SBB16mr:%ESI,4,%EBX,8,%,%AX|eax=7fff ebx=c f=42 m100b8=fa2d6dd28cceb4b346161f1a3ed6ffa6|f=91/0 m100b8=fbad
  #|sbb bx, 0x0|6683db00|SBB16ri8:%BX,%BX,0|ebx=37645aa4 f=882|f=0/0
  #|sbb bx, 0x0|6683db00|SBB16ri8:%BX,%BX,0|ebx=eee82d21 f=c7|ebx=eee82d20 f=0/0
  #|sbb bx, 0x7fff|6681dbff7f|SBB16ri:%BX,%BX,32767|ebx=ffffffff f=856|ebx=ffff8000 f=84/0
  #|sbb bx, 0x7fff|6681dbff7f|SBB16ri:%BX,%BX,32767|ebx=f97a f=803|ebx=797a f=810/0
  #|sbb word ptr [esp + 0x8], -0x1|66835c2408ff|SBB16mi8:%ESP,1,%,8,%,-1|ebx=3 f=c7 m20108=ab0ebf40b6cb08eb1b626682f46fb3cd|f=11/0
  #|sbb word ptr [esp + 0x8], -0x1|66835c2408ff|SBB16mi8:%ESP,1,%,8,%,-1|ebx=0 f=453 m20108=f5128f311dc2b2bd3fdce021008a7f8f|f=415/0
  #|sbb edx, ecx|19ca|SBB32rr:%EDX,%EDX,%ECX|ecx=80000000 edx=a f=852|edx=8000000a f=885/0
  #|sbb edx, ecx|19ca|SBB32rr:%EDX,%EDX,%ECX|ecx=96 edx=6c6e5fe2 f=c3|edx=6c6e5f4b f=14/0
  #|sbb eax, ecx|19c8|SBB32rr:%EAX,%EAX,%ECX|eax=75ec4a26 ecx=39068e66 f=c93|eax=3ce5bbbf f=410/0
  #|sbb eax, ecx|19c8|SBB32rr:%EAX,%EAX,%ECX|eax=32a7a90a ecx=5a07f4a6 f=892|eax=d89fb464 f=81/0
  #|sbb dword ptr [esp + 0x8], ebx|195c2408|SBB32mr:%ESP,1,%,8,%,%EBX|ebx=b f=8c2 m20108=f1c9d617e088a30b958c229df13ca2f7|f=10/0 m20108=e6
  #|sbb dword ptr [esp + 0x8], ebx|195c2408|SBB32mr:%ESP,1,%,8,%,%EBX|ebx=9 f=4d7 m20108=ba3ca54b653975011c610f899403b5de|f=400/0 m20108=b0
  #|sbb eax, 0x100|1d00010000|SBB32i32:256|eax=1539cf1 f=16|eax=1539bf1 f=0/0
  #|sbb eax, 0x100|1d00010000|SBB32i32:256|eax=4eb2893e f=c43|eax=4eb2883d f=400/0
  #|sbb dword ptr [esi], 0x7f|831e7f|SBB32mi8:%ESI,1,%,0,%,127|ebx=b f=16 m10080=aac2303eb34e769f5857af7e7c0c86b4|f=14/0 m10080=2b
  #|sbb dword ptr [esi], 0x7f|831e7f|SBB32mi8:%ESI,1,%,0,%,127|ebx=4 f=802 m10080=d9dfce3117cd93d0931f31fa099cd135|f=14/0 m10080=5a
  #|and dh, bl|20de|AND8rr:%DH,%DH,%BL|edx=d85e88e2 ebx=2dc778f f=857|f=84/10
  #|and dh, bl|20de|AND8rr:%DH,%DH,%BL|edx=e8587843 ebx=0 f=842|edx=e8580043 f=44/10
  #|and byte ptr [esi], al|2006|AND8mr:%ESI,1,%,0,%,%AL|eax=13196b02 ebx=8 f=47 m10080=db19cb1d8e6a8ce5f13a7fb892365aa4|f=0/10 m10080=02
  #|and byte ptr [esi], al|2006|AND8mr:%ESI,1,%,0,%,%AL|eax=82d4ee80 ebx=f f=857 m10080=ad9455ca1fee2adfac92d5bd6e12413b|f=80/10 m10080=80
  #|and cx, dx|6621d1|AND16rr:%CX,%CX,%DX|ecx=f111 edx=5b f=96|ecx=11 f=4/10
  #|and cx, dx|6621d1|AND16rr:%CX,%CX,%DX|ecx=e25b7fff edx=18a80b2c f=813|ecx=e25b0b2c f=0/10
  #|and ax, word ptr [esi]|662306|AND16rm:%AX,%AX,%ESI,1,%,0,%|eax=cc98 ebx=2 f=96 m10080=b6440803d09b90ccca0ab5dcf9b909c3|eax=4490 f=4/10
  #|and ax, word ptr [esi]|662306|AND16rm:%AX,%AX,%ESI,1,%,0,%|eax=73c27fb9 ebx=6 f=457 m10080=cb8d5d29d991ae6d42df6c88fb90c3bf|eax=73c20d89 f=400/10
  #|and ax, 0x100|66250001|AND16i16:256|eax=ffffffff f=813|eax=ffff0100 f=4/10
  #|and ax, 0x100|66250001|AND16i16:256|eax=df770e21 f=53|eax=df770000 f=44/10
  #|and ebx, edx|21d3|AND32rr:%EBX,%EBX,%EDX|edx=9 ebx=471139ba f=83|ebx=8 f=0/10
  #|and ebx, edx|21d3|AND32rr:%EBX,%EBX,%EDX|edx=cb0af47f ebx=d032338b f=57|ebx=c002300b f=80/10
  #|and ebx, dword ptr [esp + 0x8]|235c2408|AND32rm:%EBX,%EBX,%ESP,1,%,8,%|ebx=a f=803 m20108=1e2384766f6ebf532672050e44fba1a0|f=4/10
  #|and ebx, dword ptr [esp + 0x8]|235c2408|AND32rm:%EBX,%EBX,%ESP,1,%,8,%|ebx=d f=c2 m20108=7e89db7d2a5497f254d47b40657d6bf1|ebx=c f=4/10
  #|and eax, -0x100|2500ffffff|AND32i32:4294967040|eax=37 f=807|eax=0 f=44/10
  #|and eax, -0x100|2500ffffff|AND32i32:4294967040|eax=28 f=853|eax=0 f=44/10
  #|and dword ptr [esp + 0x8], -0x3|83642408fd|AND32mi8:%ESP,1,%,8,%,-3|ebx=6 f=882 m20108=8f0b4691e770063070396ff328943b87|f=84/10 m20108=8d
  #|and dword ptr [esp + 0x8], -0x3|83642408fd|AND32mi8:%ESP,1,%,8,%,-3|ebx=9 f=cc6 m20108=829d5b90a4483d4e635d03805559a993|f=480/10 m20108=80
  #|sub ch, al|28c5|SUB8rr:%CH,%CH,%AL|eax=a4f74f5d ecx=70696f62 f=56|ecx=70691262 f=4/0
  #|sub ch, al|28c5|SUB8rr:%CH,%CH,%AL|eax=c ecx=bd95a476 f=cd3|ecx=bd959876 f=490/0
  #|sub bl, 0x0|80eb00|SUB8ri:%BL,%BL,0|ebx=d7cc96f1 f=843|f=80/0
  #|sub bl, 0x0|80eb00|SUB8ri:%BL,%BL,0|ebx=70e95f38 f=83|f=0/0
  #|sub bl, 0x7f|80eb7f|SUB8ri:%BL,%BL,127|ebx=fffffffe f=c6|ebx=ffffff7f f=810/0
  #|sub bl, 0x7f|80eb7f|SUB8ri:%BL,%BL,127|ebx=cc67b42a f=cd3|ebx=cc67b4ab f=491/0
  #|sub ax, bx|6629d8|SUB16rr:%AX,%AX,%BX|eax=b0 ebx=80000000 f=86|f=0/0
  #|sub ax, bx|6629d8|SUB16rr:%AX,%AX,%BX|eax=4b945067 ebx=22 f=13|eax=4b945045 f=0/0
  #|sub bx, 0x7f|6683eb7f|SUB16ri8:%BX,%BX,127|ebx=1 f=842|ebx=ff82 f=95/0
  #|sub bx, 0x7f|6683eb7f|SUB16ri8:%BX,%BX,127|ebx=fa873f60 f=883|ebx=fa873ee1 f=14/0
  #|sub bx, 0x8000|6681eb0080|SUB16ri:%BX,%BX,32768|ebx=23ac0655 f=7|ebx=23ac8655 f=885/0
  #|sub bx, 0x8000|6681eb0080|SUB16ri:%BX,%BX,32768|ebx=8c26b05a f=3|ebx=8c26305a f=4/0
  #|sub ax, 0x7fff|662dff7f|SUB16i16:32767|eax=eae62933 f=56|eax=eae6a934 f=91/0
  #|sub ax, 0x7fff|662dff7f|SUB16i16:32767|eax=cba64e62 f=52|eax=cba6ce63 f=95/0
  #|sub dword ptr [esi], edx|2916|SUB32mr:%ESI,1,%,0,%,%EDX|edx=70fd7f3c ebx=8 f=12 m10080=5be81bf91290242bd3c883297ba0f624|f=90/0 m10080=1f691e88
  #|sub dword ptr [esi], edx|2916|SUB32mr:%ESI,1,%,0,%,%EDX|edx=4351def1 ebx=8 f=c03 m10080=f3f497c20f4fdf088da0b59c98595812|f=c00/0 m10080=0216467f
  #|sub edx, 0x1|83ea01|SUB32ri8:%EDX,%EDX,1|edx=b1b53c1f f=8c7|edx=b1b53c1e f=84/0
  #|sub edx, 0x1|83ea01|SUB32ri8:%EDX,%EDX,1|edx=8810 f=96|edx=880f f=14/0
  #|sub eax, 0x7fffffff|2dffffff7f|SUB32i32:2147483647|eax=49a0a64c f=12|eax=c9a0a64d f=95/0
  #|sub eax, 0x7fffffff|2dffffff7f|SUB32i32:2147483647|eax=3db6bdff f=97|eax=bdb6be00 f=85/0
  #|sub dword ptr [esp + 0x8], -0x80|836c240880|SUB32mi8:%ESP,1,%,8,%,-128|ebx=7 f=8c2 m20108=1eff0f98aa3578fea5d6b197d3a509cf|f=81/0 m20108=9e
  #|sub dword ptr [esp + 0x8], -0x80|836c240880|SUB32mi8:%ESP,1,%,8,%,-128|ebx=e f=46 m20108=bc2f626139a5520d2a58522a32967f17|f=5/0 m20108=3c30
  #|xor dl, byte ptr [esi + ebx*4 + 0x8]|32549e08|XOR8rm:%DL,%DL,%ESI,4,%EBX,8,%|edx=cf6a85d0 ebx=c f=c6 m100b8=88ba9fe3f2da293061653b9955323058|edx=cf6a8558 f=0/10
  #|xor dl, byte ptr [esi + ebx*4 + 0x8]|32549e08|XOR8rm:%DL,%DL,%ESI,4,%EBX,8,%|edx=c71cdd97 ebx=3 f=43 m10094=87353851912d5affad21cb28820036f2|edx=c71cdd10 f=0/10
  #|xor dl, 0x0|80f200|XOR8ri:%DL,%DL,0|edx=f0f30a52 f=3|f=0/10
  #|xor dl, 0x0|80f200|XOR8ri:%DL,%DL,0|edx=81aae882 f=4c7|f=484/10
  #|xor dl, 0x0|80f200|XOR8ri:%DL,%DL,0|edx=ebd4ff9b f=846|f=80/10
  #|xor dl, 0x0|80f200|XOR8ri:%DL,%DL,0|edx=1596841d f=442|f=404/10
  #|xor al, 0x7f|347f|XOR8i8:127|eax=374f2fa f=8d2|eax=374f285 f=80/10
  #|xor al, 0x7f|347f|XOR8i8:127|eax=ef4635e7 f=857|eax=ef463598 f=80/10
  #|xor byte ptr [ebp - 0x20], -0x3|8075e0fd|XOR8mi:%EBP,1,%,-32,%,-3|ebx=b f=8d6 m20160=9eba9bb31da31916e5bd0f23b1ef2458|f=4/10 m20160=63
  #|xor byte ptr [ebp - 0x20], -0x3|8075e0fd|XOR8mi:%EBP,1,%,-32,%,-3|ebx=b f=86 m20160=82a28ff6ef5706c09c111577462344ee|f=0/10 m20160=7f
  #|xor cx, bx|6631d9|XOR16rr:%CX,%CX,%BX|ecx=e6907900 ebx=6191f6fa f=93|ecx=e6908ffa f=84/10
  #|xor cx, bx|6631d9|XOR16rr:%CX,%CX,%BX|ecx=40761be8 ebx=2f4ed551 f=8c7|ecx=4076ceb9 f=80/10
  #|xor word ptr [esp + 0x8], ax|6631442408|XOR16mr:%ESP,1,%,8,%,%AX|eax=272b0f1 ebx=8 f=857 m20108=faa58715a5c10248eb5baa198839a9b7|f=0/10 m20108=0b15
  #|xor word ptr [esp + 0x8], ax|6631442408|XOR16mr:%ESP,1,%,8,%,%AX|eax=87d3690 ebx=a f=c43 m20108=cc896307f2b4d9d36271e3b7cc5a3fa1|f=484/10 m20108=5cbf
  #|xor ax, word ptr [ebp - 0x20]|663345e0|XOR16rm:%AX,%AX,%EBP,1,%,-32,%|eax=1 ebx=2 f=cc2 m20160=b15fa184062702fcbc893d8477a2be61|eax=5fb0 f=400/10
  #|xor ax, word ptr [ebp - 0x20]|663345e0|XOR16rm:%AX,%AX,%EBP,1,%,-32,%|eax=83666548 ebx=b f=816 m20160=3712f14498a7f7223ca63cfd2e3dc3a1|eax=8366777f f=0/10
  #|xor edx, ebx|31da|XOR32rr:%EDX,%EDX,%EBX|edx=8fe4b1d5 ebx=69a935f0 f=457|edx=e64d8425 f=480/10
  #|xor edx, ebx|31da|XOR32rr:%EDX,%EDX,%EBX|edx=ed9e892b ebx=8a9f1448 f=87|edx=67019d63 f=4/10
  #|xor dword ptr [esp + 0x8], eax|31442408|XOR32mr:%ESP,1,%,8,%,%EAX|eax=3239cbd6 ebx=c f=893 m20108=16dee81d494f7c0d7d640f8cddac6443|f=4/10 m20108=c015d12f
  #|xor dword ptr [esp + 0x8], eax|31442408|XOR32mr:%ESP,1,%,8,%,%EAX|eax=80 ebx=4 f=2 m20108=e0db7b07cbff8d05194862c1ea6926b6|f=4/10 m20108=60
  #|xor edx, -0x80000000|81f200000080|XOR32ri:%EDX,%EDX,2147483648|edx=8a37489 f=816|edx=88a37489 f=80/10
  #|xor edx, -0x80000000|81f200000080|XOR32ri:%EDX,%EDX,2147483648|edx=9 f=8d3|edx=80000009 f=84/10
  #|xor dword ptr [edi + 0x10], -0x3|837710fd|XOR32mi8:%EDI,1,%,16,%,-3|ebx=c f=446 m10110=61ef828670859ef1bdaef97a670443f3|f=404/10 m10110=9c107d79
  #|xor dword ptr [edi + 0x10], -0x3|837710fd|XOR32mi8:%EDI,1,%,16,%,-3|ebx=a f=53 m10110=0ebd94ef4885ca1efafd41af429aba5f|f=4/10 m10110=f3426b10
  #|cmp dl, al|38c2|CMP8rr:%DL,%AL|eax=ffffffff edx=acf33090 f=892|f=91/0
  #|cmp dl, al|38c2|CMP8rr:%DL,%AL|eax=7443c6ff edx=c f=4d2|f=411/0
  #|cmp dh, al|38c6|CMP8rr:%DH,%AL|eax=a58e3eff edx=74cfc3bc f=92|f=91/0
  #|cmp dh, al|38c6|CMP8rr:%DH,%AL|eax=3f3e9ee edx=642875e2 f=442|f=c95/0
  #|cmp byte ptr [esi + ebx*4 + 0x8], dl|38549e08|CMP8mr:%ESI,4,%EBX,8,%,%DL|edx=a9228952 ebx=8 f=856 m100a8=a2aaffccf040a9fb09c36573b6fe4f91|f=804/0
  #|cmp byte ptr [esi + ebx*4 + 0x8], dl|38549e08|CMP8mr:%ESI,4,%EBX,8,%,%DL|edx=dcd8 ebx=c f=16 m100b8=eb1cc5168aa7c47e8c35b19a56383a4b|f=0/0
  #|cmp dl, byte ptr [ebp - 0x20]|3a55e0|CMP8rm:%DL,%EBP,1,%,-32,%|edx=f22c9999 ebx=9 f=3 m20160=b49c0555c3bf23fe9d4f21d1425898bd|f=81/0
  #|cmp dl, byte ptr [ebp - 0x20]|3a55e0|CMP8rm:%DL,%EBP,1,%,-32,%|edx=2 ebx=c f=806 m20160=da39983ba4dc552464cfd46650ccbccc|f=15/0
  #|cmp bl, -0x1|80fbff|CMP8ri:%BL,-1|ebx=f2f92438 f=cc7|f=415/0
  #|cmp bl, -0x1|80fbff|CMP8ri:%BL,-1|ebx=e26dd3c2 f=8d7|f=95/0
  #|cmp al, 0x7f|3c7f|CMP8i8:127|eax=2 f=803|f=91/0
  #|cmp al, 0x7f|3c7f|CMP8i8:127|eax=48357e1f f=8c7|f=85/0
  #|cmp byte ptr [esi + ebx*4 + 0x8], 0x7f|807c9e087f|CMP8mi:%ESI,4,%EBX,8,%,127|ebx=0 f=406 m10088=86fc9730b90c2ba388f6f99c4a78c982|f=c10/0
  #|cmp byte ptr [esi + ebx*4 + 0x8], 0x7f|807c9e087f|CMP8mi:%ESI,4,%EBX,8,%,127|ebx=4 f=92 m10098=8a71fa30e9f82230c04e2ef3e96fe63e|f=810/0
  #|cmp cx, dx|6639d1|CMP16rr:%CX,%DX|ecx=dad7b8c5 edx=73 f=93|f=80/0
  #|cmp cx, dx|6639d1|CMP16rr:%CX,%DX|ecx=fffffffe edx=b4f3cb1b f=8c6|f=0/0
  #|cmp word ptr [ebp - 0x20], cx|66394de0|CMP16mr:%EBP,1,%,-32,%,%CX|ecx=0 ebx=e f=12 m20160=d71966390140d3b12b7ba12168442b72|f=4/0
  #|cmp word ptr [ebp - 0x20], cx|66394de0|CMP16mr:%EBP,1,%,-32,%,%CX|ecx=ff91 ebx=a f=47 m20160=411b9f6d98f767b05df32abb58fa793f|f=1/0
  #|cmp cx, word ptr [esp + 0x8]|663b4c2408|CMP16rm:%CX,%ESP,1,%,8,%|ecx=95d7fa61 ebx=2 f=882 m20108=c5919c999c07f365542981a5dfdb27e1|f=14/0
  #|cmp cx, word ptr [esp + 0x8]|663b4c2408|CMP16rm:%CX,%ESP,1,%,8,%|ecx=3126ffff ebx=9 f=887 m20108=2f485deac6b8fa75c40c737df777ee39|f=80/0
  #|cmp dx, 0x7fff|6681faff7f|CMP16ri:%DX,32767|edx=e9687fff f=8c3|f=44/0
  #|cmp dx, 0x7fff|6681faff7f|CMP16ri:%DX,32767|edx=8ca0c32f f=93|f=804/0
  #|cmp ebx, eax|39c3|CMP32rr:%EBX,%EAX|eax=ff ebx=2957bbb8 f=802|f=10/0
  #|cmp ebx, eax|39c3|CMP32rr:%EBX,%EAX|eax=62cd7828 ebx=c547c66b f=4c6|f=c00/0
  #|cmp ebx, 0x12345678|81fb78563412|CMP32ri:%EBX,305419896|ebx=d3347ff9 f=802|f=84/0
  #|cmp ebx, 0x12345678|81fb78563412|CMP32ri:%EBX,305419896|ebx=ffffffff f=43|f=84/0
  #|cmp eax, 0x7fffffff|3dffffff7f|CMP32i32:2147483647|eax=33 f=806|f=91/0
  #|cmp eax, 0x7fffffff|3dffffff7f|CMP32i32:2147483647|eax=9 f=c7|f=95/0
  #|test ch, bl|84dd|TEST8rr:%CH,%BL|ecx=2 ebx=f43b61bb f=6|f=44/10
  #|test ch, bl|84dd|TEST8rr:%CH,%BL|ecx=4ca85517 ebx=4 f=c93|f=400/10
  #|test byte ptr [edi + 0x10], dl|845710|TEST8mr:%EDI,1,%,16,%,%DL|edx=bb3c2b91 ebx=0 f=857 m10110=d294a4acecbf16a35a1f3ab8180a7e76|f=84/10
  #|test byte ptr [edi + 0x10], dl|845710|TEST8mr:%EDI,1,%,16,%,%DL|edx=85d42ffa ebx=5 f=897 m10110=3ec72336b1117e924d91a52b6106f284|f=4/10
  #|test cl, 0x0|f6c100|TEST8ri:%CL,0|ecx=f9588ff0 f=46|f=44/10
  #|test cl, 0x0|f6c100|TEST8ri:%CL,0|ecx=7fff f=847|f=44/10
  #|test al, 0x7f|a87f|TEST8i8:127|eax=e1ec65df f=43|f=4/10
  #|test al, 0x7f|a87f|TEST8i8:127|eax=fd99ae89 f=d6|f=4/10
  #|test byte ptr [esp + 0x8], 0x7f|f64424087f|TEST8mi:%ESP,1,%,8,%,127|ebx=f f=846 m20108=de7df40d4c626413cfe71d51f1e16af0|f=0/10
  #|test byte ptr [esp + 0x8], 0x7f|f64424087f|TEST8mi:%ESP,1,%,8,%,127|ebx=1 f=853 m20108=4a69ac1b264a0c632bdc61cdada844a1|f=0/10
  #|test word ptr [esp + 0x8], bx|66855c2408|TEST16mr:%ESP,1,%,8,%,%BX|ebx=5 f=43 m20108=192379e79d5e7ba99d4ac37e905ff662|f=0/10
  #|test word ptr [esp + 0x8], bx|66855c2408|TEST16mr:%ESP,1,%,8,%,%BX|ebx=4 f=56 m20108=8ad7ebf72899a6e696a8edc31693ce86|f=44/10
  #|test cx, 0x7fff|66f7c1ff7f|TEST16ri:%CX,32767|ecx=8000 f=46|f=44/10
  #|test cx, 0x7fff|66f7c1ff7f|TEST16ri:%CX,32767|ecx=3c5d7e6b f=882|f=0/10
  #|test ebx, eax|85c3|TEST32rr:%EBX,%EAX|eax=f33aa268 ebx=b416856a f=883|f=80/10
  #|test ebx, eax|85c3|TEST32rr:%EBX,%EAX|eax=9909bb2a ebx=22e859d f=497|f=400/10
  #|test eax, ebx|85d8|TEST32rr:%EAX,%EBX|eax=ca633a57 ebx=272a220d f=c57|f=404/10
  #|test eax, ebx|85d8|TEST32rr:%EAX,%EBX|eax=c66af7e9 ebx=ffffffff f=c3|f=80/10
  #|test dword ptr [ebp - 0x20], ebx|855de0|TEST32mr:%EBP,1,%,-32,%,%EBX|ebx=d f=817 m20160=46db51661c5093a403f973d60fbad60c|f=0/10
  #|test dword ptr [ebp - 0x20], ebx|855de0|TEST32mr:%EBP,1,%,-32,%,%EBX|ebx=2 f=803 m20160=88d94cc618435890a1df138e3d03e9c1|f=44/10
  #|test eax, 0x12345678|a978563412|TEST32i32:305419896|eax=842ede9a f=cc6|f=404/10
  #|test eax, 0x12345678|a978563412|TEST32i32:305419896|eax=43b56aa0 f=8d2|f=0/10
  #|test dword ptr [esi], 0x7fffffff|f706ffffff7f|TEST32mi:%ESI,1,%,0,%,2147483647|ebx=7 f=447 m10080=1452f02f068c4fff5389c85257cef5e7|f=404/10
  #|test dword ptr [esi], 0x7fffffff|f706ffffff7f|TEST32mi:%ESI,1,%,0,%,2147483647|ebx=4 f=96 m10080=f549cefce036d37e99da3af476d07a18|f=4/10
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|eax=381d63b1 ecx=51c3e497 f=c2|eax=89e14848 f=884/0
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|eax=317b7df2 ecx=1 f=812|eax=317b7df3 f=4/0
  #|adc eax, ecx (13)|13c1|ADC32rr_REV:%EAX,%EAX,%ECX|eax=a172ca54 ecx=6925fd6b f=d7|eax=a98c7c0 f=15/0
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|eax=39869986 ecx=27f5df6e f=c06|eax=21849906 f=404/10
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|eax=4cea36f2 ecx=74 f=82|eax=70 f=0/10
  #|and eax, ecx (23)|23c1|AND32rr_REV:%EAX,%EAX,%ECX|eax=c28cd762 ecx=5 f=d7|eax=0 f=44/10
  #|add al, 5 (82)|82c005|ADD8ri8:%AL,%AL,5|eax=be2da9bf f=8c3|eax=be2da9c4 f=90/0
  #|add al, 5 (82)|82c005|ADD8ri8:%AL,%AL,5|eax=83973198 f=3|eax=8397319d f=80/0
  #|add al, 5 (82)|82c005|ADD8ri8:%AL,%AL,5|eax=c33ddd3c f=92|eax=c33ddd41 f=14/0
  #|sub bl, 0x80 (82)|82eb80|SUB8ri8:%BL,%BL,-128|ebx=6bc3c0b4 f=897|ebx=6bc3c034 f=0/0
  #|sub bl, 0x80 (82)|82eb80|SUB8ri8:%BL,%BL,-128|ebx=89347bc0 f=816|ebx=89347b40 f=0/0
  #|sub bl, 0x80 (82)|82eb80|SUB8ri8:%BL,%BL,-128|ebx=c5ddeba8 f=8c3|ebx=c5ddeb28 f=4/0
  #|inc bx|6643|INC16r_alt:%BX,%BX|ebx=6dc8ffef f=52|ebx=6dc8fff0 f=94/0
  #|inc bx|6643|INC16r_alt:%BX,%BX|ebx=1726 f=c2|ebx=1727 f=4/0
  #|inc bx|6643|INC16r_alt:%BX,%BX|ebx=b f=4d2|ebx=c f=404/0
  #|inc ecx|41|INC32r_alt:%ECX,%ECX|ecx=57 f=c6|ecx=58 f=0/0
  #|inc ecx|41|INC32r_alt:%ECX,%ECX|ecx=fd04dfce f=52|ecx=fd04dfcf f=84/0
  #|inc ecx|41|INC32r_alt:%ECX,%ECX|ecx=1ae28c93 f=887|ecx=1ae28c94 f=1/0
  #|inc dword ptr [edi + 0x10]|ff4710|INC32m:%EDI,1,%,16,%|ebx=b f=12 m10110=53021b283c2f0a821c1854bbbee979a9|f=0/0 m10110=54
  #|inc dword ptr [edi + 0x10]|ff4710|INC32m:%EDI,1,%,16,%|ebx=2 f=483 m10110=24dfcee27af9e7f34869a99e66f636b8|f=481/0 m10110=25
  #|dec al|fec8|DEC8r:%AL,%AL|eax=bea85aca f=92|eax=bea85ac9 f=84/0
  #|dec al|fec8|DEC8r:%AL,%AL|eax=46bd0ad6 f=883|eax=46bd0ad5 f=81/0
  #|dec al|fec8|DEC8r:%AL,%AL|eax=8b5099c0 f=807|eax=8b5099bf f=91/0
  #|neg dword ptr [esi + ebx*4 + 0x8]|f75c9e08|NEG32m:%ESI,4,%EBX,8,%|ebx=f f=8d3 m100c4=45709d0d3a4c3591e5e81f41c825d34d|f=95/0 m100c4=bb8f62f2
  #|neg dword ptr [esi + ebx*4 + 0x8]|f75c9e08|NEG32m:%ESI,4,%EBX,8,%|ebx=5 f=8d2 m1009c=be254b794fe146c07bb005e5d55f5a41|f=95/0 m1009c=42dab486
  #|not byte ptr [esi + ebx*4 + 0x8]|f6549e08|NOT8m:%ESI,4,%EBX,8,%|ebx=1 f=886 m1008c=3aab71da1680342d0671d96c6491e56e|f=884/0 m1008c=c5
  #|not byte ptr [esi + ebx*4 + 0x8]|f6549e08|NOT8m:%ESI,4,%EBX,8,%|ebx=2 f=7 m10090=b4b540c43933166b40723e282da2505b|f=5/0 m10090=4b
  #|not word ptr [esi + ebx*4 + 0x8]|66f7549e08|NOT16m:%ESI,4,%EBX,8,%|ebx=0 f=897 m10088=48ba8548e9da944c6f255632212f2d12|f=895/0 m10088=b745
  #|not word ptr [esi + ebx*4 + 0x8]|66f7549e08|NOT16m:%ESI,4,%EBX,8,%|ebx=8 f=c06 m100a8=a262fb22de98a441afc9f2deb2d2df17|f=c04/0 m100a8=5d9d
  #|not eax|f7d0|NOT32r:%EAX,%EAX|eax=6c37 f=803|eax=ffff93c8 f=801/0
  #|not eax|f7d0|NOT32r:%EAX,%EAX|eax=9545f8f6 f=812|eax=6aba0709 f=810/0
  #|not eax|f7d0|NOT32r:%EAX,%EAX|eax=d67489b5 f=56|eax=298b764a f=54/0
