// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let move64_cases : String =
  #|mov cl, r9b|4488c9|MOV8rr:%CL,%R9B|rcx=b988a2e2c729edae r9=ffff f=812|rcx=b988a2e2c729edff f=810/0
  #|mov cl, r9b|4488c9|MOV8rr:%CL,%R9B|rcx=c73e10a6115e63ea r9=288600ee1bbe9d4f f=4d2|rcx=c73e10a6115e634f f=4d0/0
  #|mov cl, byte ptr [rdi + 0x10]|8a4f10|MOV8rm:%CL,%RDI,1,%,16,%|rcx=be705bc6d2cc87de rbx=0 r9=0 f=c13 m10110=914925decfd03e0c3d08132fab3f0939|rcx=be705bc6d2cc8791 f=c11/0
  #|mov cl, byte ptr [rdi + 0x10]|8a4f10|MOV8rm:%CL,%RDI,1,%,16,%|rcx=ca1d86ca8b0e8279 rbx=6 r9=d f=897 m10110=efda484a89db90cf2e54661289e0f1d0|rcx=ca1d86ca8b0e82ef f=895/0
  #|mov byte ptr [rdi + 0x10], r9b|44884f10|MOV8mr:%RDI,1,%,16,%,%R9B|rbx=1 r9=e f=886 m10110=e5451cf11124e07b3678449d8931f4ad|f=884/0 m10110=0e
  #|mov byte ptr [rdi + 0x10], r9b|44884f10|MOV8mr:%RDI,1,%,16,%,%R9B|rbx=c r9=d f=852 m10110=7f04564386edcbcf658c1340a45de201|f=850/0 m10110=0d
  #|mov cl, 0x1|b101|MOV8ri:%CL,1|rcx=166b17a47c3d75b9 f=812|rcx=166b17a47c3d7501 f=810/0
  #|mov byte ptr [rdi + 0x10], 0x0|c6471000|MOV8mi:%RDI,1,%,16,%,0|rbx=f r9=1 f=d3 m10110=fe7423a2fe34521f1fb57caf804c2822|f=d1/0 m10110=00
  #|mov r8w, r15w|664589f8|MOV16rr:%R8W,%R15W|r8=fb04e97ab655575f r15=d90f f=8d3|r8=fb04e97ab655d90f f=8d1/0
  #|mov r8w, r15w|664589f8|MOV16rr:%R8W,%R15W|r8=a748cd893d11f50d r15=ffffffff f=c47|r8=a748cd893d11ffff f=c45/0
  #|mov r8w, word ptr [rsi + rbx*4 + 0x8]|66448b449e08|MOV16rm:%R8W,%RSI,4,%RBX,8,%|rbx=e r8=2a3ee6f963b53c24 r9=0 f=447 m100c0=7c1c08533fcaf7c38dddae857089cb61|r8=2a3ee6f963b51c7c f=445/0
  #|mov r8w, word ptr [rsi + rbx*4 + 0x8]|66448b449e08|MOV16rm:%R8W,%RSI,4,%RBX,8,%|rbx=2 r8=d921ad1e0d1df992 r9=c f=c86 m10090=72c4b71bb269202714cd7bd3ac906796|r8=d921ad1e0d1dc472 f=c84/0
  #|mov word ptr [rsi + rbx*4 + 0x8], r15w|6644897c9e08|MOV16mr:%RSI,4,%RBX,8,%,%R15W|rbx=8 r9=4 r15=27 f=c2 m100a8=d9232c95df2f34f35e4cd19b03126579|f=c0/0 m100a8=2700
  #|mov word ptr [rsi + rbx*4 + 0x8], r15w|6644897c9e08|MOV16mr:%RSI,4,%RBX,8,%,%R15W|rbx=7 r9=3 r15=677badbc3a301592 f=c12 m100a4=f313316dc034aa7f5367dabd558c5ef4|f=c10/0 m100a4=9215
  #|mov r8w, 0x100|6641b80001|MOV16ri:%R8W,256|r8=ae475720b1f67680 f=8d2|r8=ae475720b1f60100 f=8d0/0
  #|mov word ptr [rsi + rbx*4 + 0x8], 0x1234|66c7449e083412|MOV16mi:%RSI,4,%RBX,8,%,4660|rbx=7 r9=1 f=412 m100a4=bfcc38e7622d4f20a134a00522141940|f=410/0 m100a4=3412
  #|mov r14d, r11d|4589de|MOV32rr:%R14D,%R11D|r11=4c21 r14=7fff f=892|r14=4c21 f=890/0
  #|mov r14d, r11d|4589de|MOV32rr:%R14D,%R11D|r11=4721fabbe6e818f6 r14=ed67d1d47c1cd125 f=d3|r14=e6e818f6 f=d1/0
  #|mov r14d, dword ptr [rdi + r9*2 - 0x4]|468b744ffc|MOV32rm:%R14D,%RDI,2,%R9,-4,%|rbx=a r9=1 r14=8d7c6f036f55016e f=802 m100fe=5aff8acf7d871605c384a0cd434dd3c1|r14=cf8aff5a f=800/0
  #|mov r14d, dword ptr [rdi + r9*2 - 0x4]|468b744ffc|MOV32rm:%R14D,%RDI,2,%R9,-4,%|rbx=4 r9=8 r14=7fffffff f=c2 m1010c=2d326b0ad15b1cfd543ede4b73da3ebd|r14=a6b322d f=c0/0
  #|mov dword ptr [rdi + r9*2 - 0x4], r11d|46895c4ffc|MOV32mr:%RDI,2,%R9,-4,%,%R11D|rbx=0 r9=a r11=3273b147583e87bd f=413 m10110=bc6755277c642c7c3cd7befa3c390cf4|f=411/0 m10110=bd873e58
  #|mov dword ptr [rdi + r9*2 - 0x4], r11d|46895c4ffc|MOV32mr:%RDI,2,%R9,-4,%,%R11D|rbx=7 r9=1 r11=d f=8c3 m100fe=59d6e5a7cd11c5e444bc830cf5ed344c|f=8c1/0 m100fe=0d000000
  #|mov r14d, -0x80000000|41be00000080|MOV32ri:%R14D,2147483648|r14=bf2d981f2ecb7f13 f=896|r14=80000000 f=894/0
  #|mov dword ptr [rdi + r9*2 - 0x4], 0x100|42c7444ffc00010000|MOV32mi:%RDI,2,%R9,-4,%,256|rbx=a r9=e f=52 m10118=1aa8b33d5699cff46688f0885549a76a|f=50/0 m10118=00010000
  #|mov r15, r9|4d89cf|MOV64rr:%R15,%R9|r9=a16b9f39d7c9ce80 r15=adcfa49eeefa98c5 f=812|r15=a16b9f39d7c9ce80 f=810/0
  #|mov r15, r9|4d89cf|MOV64rr:%R15,%R9|r9=e7ab0a126179f91a r15=ffffffff f=8d6|r15=e7ab0a126179f91a f=8d4/0
  #|mov r15, qword ptr [rbp - 0x20]|4c8b7de0|MOV64rm:%R15,%RBP,1,%,-32,%|rbx=e r9=a r15=665d59763f60a101 f=852 m20160=ab0daf7e742f20712ed2d3f3e9dff7fa|r15=71202f747eaf0dab f=850/0
  #|mov r15, qword ptr [rbp - 0x20]|4c8b7de0|MOV64rm:%R15,%RBP,1,%,-32,%|rbx=7 r9=d r15=fa7c0fe9858ebbeb f=d7 m20160=e0d2ba4e3f6b3a0f4860824036753bba|r15=f3a6b3f4ebad2e0 f=d5/0
  #|mov qword ptr [rbp - 0x20], r9|4c894de0|MOV64mr:%RBP,1,%,-32,%,%R9|rbx=6 r9=0 f=97 m20160=fbd947373b0e98861f4627582ee3a986|f=95/0 m20160=0000000000000000
  #|mov qword ptr [rbp - 0x20], r9|4c894de0|MOV64mr:%RBP,1,%,-32,%,%R9|rbx=1 r9=3 f=8c2 m20160=1c81a3090947b043014293607062da69|f=8c0/0 m20160=0300000000000000
  #|mov r15, 0x7fffffff|49c7c7ffffff7f|MOV64ri32:%R15,2147483647|r15=1e9bc6a4d2da9dfb f=93|r15=7fffffff f=91/0
  #|mov qword ptr [rbp - 0x20], 0x12345678|48c745e078563412|MOV64mi32:%RBP,1,%,-32,%,305419896|rbx=e r9=f f=13 m20160=f96f1e9d62cdc62d88c3c09574bab9ac|f=11/0 m20160=7856341200000000
  #|movabs rax, 0x123456789abcdef0|48b8f0debc9a78563412|MOV64ri:%RAX,1311768467463790320|rax=7 f=cd7|rax=123456789abcdef0 f=cd5/0
  #|mov r9, -0x2|49c7c1feffffff|MOV64ri32:%R9,-2|r9=bf83b717bea158f6 f=52|r9=fffffffffffffffe f=50/0
  #|movsxd rax, ebx|4863c3|MOVSX64rr32:%RAX,%EBX|rax=c rcx=c997 rdx=ff8ed107e06973e7 rbx=3785378def9e7d01 f=82|rax=ffffffffef9e7d01 f=80/0
  #|movsxd rax, ebx|4863c3|MOVSX64rr32:%RAX,%EBX|rax=d88e36405a41492a rdx=cc rbx=b97ff7124e448550 f=852|rax=4e448550 f=850/0
  #|movsxd rax, ebx|4863c3|MOVSX64rr32:%RAX,%EBX|rax=80000000 rdx=2a012c446baf2f5a rbx=f9bc1d8c38e03449 f=7|rax=38e03449 f=5/0
  #|movsxd r10, dword ptr [rsi]|4c6316|MOVSX64rm32:%R10,%RSI,1,%,0,%|rax=a6a0509882f6e01e rcx=7472 rdx=aa3946099f755cb r10=8000 f=3 m10080=72fd0e2ce8ced5916d8ee8e3edc9a29b|r10=2c0efd72 f=1/0
  #|movsxd r10, dword ptr [rsi]|4c6316|MOVSX64rm32:%R10,%RSI,1,%,0,%|rax=5b2bd99c44c69037 rcx=6411bf1b054217dd rdx=a3a14a9cdbf09c49 r10=4bbcbb96d298da59 f=802 m10080=9f34b0feddfd51d4ab118fcad8ea81d6|r10=fffffffffeb0349f f=800/0
  #|movsxd r10, dword ptr [rsi]|4c6316|MOVSX64rm32:%R10,%RSI,1,%,0,%|rax=2b9 rcx=cb94 rdx=f4 r10=c9e19dab766a09f3 f=17 m10080=608a556053fd1e04b82fe596ba06de9b|r10=60558a60 f=15/0
  #|movzx r10w, r14b|66450fb6d6|MOVZX16rr8:%R10W,%R14B|r10=ab22a64d37054624 r14=e25d511d62115e4d f=8d3|r10=ab22a64d3705004d f=8d1/0
  #|movzx r10w, r14b|66450fb6d6|MOVZX16rr8:%R10W,%R14B|r10=916d2283cadaf889 r14=466d5e203191884c f=3|r10=916d2283cada004c f=1/0
  #|movzx r10w, r14b|66450fb6d6|MOVZX16rr8:%R10W,%R14B|r10=b3bb5b559eb3136c r14=64f8e267d0fc6760 f=846|r10=b3bb5b559eb30060 f=844/0
  #|movzx r10w, byte ptr [rsp + 0x8]|66440fb6542408|MOVZX16rm8:%R10W,%RSP,1,%,8,%|rbx=f r9=7 r10=1 f=892 m20108=569d008be837d55a84c73c3c783ca804|r10=56 f=890/0
  #|movzx r10w, byte ptr [rsp + 0x8]|66440fb6542408|MOVZX16rm8:%R10W,%RSP,1,%,8,%|rbx=7 r9=5 r10=74adfa2b7973e57f f=c12 m20108=2c7f1c8331c95b5f9580db4e7f84c60c|r10=74adfa2b7973002c f=c10/0
  #|movzx ebx, r8b|410fb6d8|MOVZX32rr8:%EBX,%R8B|rbx=e21b0c07c1373997 r8=ffffffffffffffff f=c06|rbx=ff f=c04/0
  #|movzx ebx, r8b|410fb6d8|MOVZX32rr8:%EBX,%R8B|rbx=7fffffffffffffff r8=f507d9eb7fffffff f=897|rbx=ff f=895/0
  #|movzx ebx, r8b|410fb6d8|MOVZX32rr8:%EBX,%R8B|rbx=bf1fa8b04711ccff r8=4e57 f=853|rbx=57 f=851/0
  #|movzx ebx, byte ptr [rsi]|0fb61e|MOVZX32rm8:%EBX,%RSI,1,%,0,%|rbx=8 r9=c f=486 m10080=37f70bd5c22b68c7f25135f2cea039e7|rbx=37 f=484/0
  #|movzx ebx, byte ptr [rsi]|0fb61e|MOVZX32rm8:%EBX,%RSI,1,%,0,%|rbx=6 r9=6 f=412 m10080=940e1e78e33ec935bedc5959b1773745|rbx=94 f=410/0
  #|movzx r11d, r9w|450fb7d9|MOVZX32rr16:%R11D,%R9W|r9=90dc5e2093a6579e r11=16addef72309dad7 f=817|r11=579e f=815/0
  #|movzx r11d, r9w|450fb7d9|MOVZX32rr16:%R11D,%R9W|r9=624b8f79a354efd4 r11=a9769f1acfd77fff f=46|r11=efd4 f=44/0
  #|movzx r11d, r9w|450fb7d9|MOVZX32rr16:%R11D,%R9W|r9=28 r11=f4 f=817|r11=28 f=815/0
  #|movzx r11d, word ptr [rdi + 0x10]|440fb75f10|MOVZX32rm16:%R11D,%RDI,1,%,16,%|rbx=0 r9=7 r11=badffec8e39e4987 f=46 m10110=41cb9aa936a2385807cb85438ba2fa6a|r11=cb41 f=44/0
  #|movzx r11d, word ptr [rdi + 0x10]|440fb75f10|MOVZX32rm16:%R11D,%RDI,1,%,16,%|rbx=2 r9=d r11=eb9f99f098618a52 f=d3 m10110=3084972477f1c1aa923088cd56ea2d5b|r11=8430 f=d1/0
  #|movzx rcx, r8b|490fb6c8|MOVZX64rr8:%RCX,%R8B|rcx=7565e9d0b2b9ea46 r8=ffffffff f=813|rcx=ff f=811/0
  #|movzx rcx, r8b|490fb6c8|MOVZX64rr8:%RCX,%R8B|rcx=9c04f5cb53b72210 r8=186b5df08a849045 f=842|rcx=45 f=840/0
  #|movzx rcx, r8b|490fb6c8|MOVZX64rr8:%RCX,%R8B|rcx=874023fbca470b78 r8=3faa56e57c9b38ba f=57|rcx=ba f=55/0
  #|movzx rcx, byte ptr [rdi + 0x10]|480fb64f10|MOVZX64rm8:%RCX,%RDI,1,%,16,%|rcx=44227a328da400cf rbx=1 r9=e f=4c3 m10110=f7bbe42f0ac4eaf96bede600133a7e59|rcx=f7 f=4c1/0
  #|movzx rcx, byte ptr [rdi + 0x10]|480fb64f10|MOVZX64rm8:%RCX,%RDI,1,%,16,%|rcx=62f16a66ffffffff rbx=9 r9=d f=8d3 m10110=8e7f42b01b66ede081ce87b6613b98c0|rcx=8e f=8d1/0
  #|movzx r8, dx|4c0fb7c2|MOVZX64rr16:%R8,%DX|rdx=876a r8=4 f=842|r8=876a f=840/0
  #|movzx r8, dx|4c0fb7c2|MOVZX64rr16:%R8,%DX|rdx=9a712312c00e25df r8=3a6936ed9144824a f=52|r8=25df f=50/0
  #|movzx r8, dx|4c0fb7c2|MOVZX64rr16:%R8,%DX|rdx=ff7c54ba40c2d00f r8=e1f2d8c666b92dbf f=d2|r8=d00f f=d0/0
  #|movzx r8, word ptr [rsi]|4c0fb706|MOVZX64rm16:%R8,%RSI,1,%,0,%|rbx=b r8=e0c917db5b881bc5 r9=0 f=c3 m10080=bea982468c497895f4db2295c161222d|r8=a9be f=c1/0
  #|movzx r8, word ptr [rsi]|4c0fb706|MOVZX64rm16:%R8,%RSI,1,%,0,%|rbx=c r8=34bda1bea56e86e3 r9=7 f=452 m10080=6160a85dd0ceaeb219dc6b155a81d1fa|r8=6061 f=450/0
  #|movsx r11w, bl|66440fbedb|MOVSX16rr8:%R11W,%BL|rcx=b00da8710af7b7fc rdx=2 rbx=f4dbc7e7ae4e0edc r11=80562d1f07257447 f=812|r11=80562d1f0725ffdc f=810/0
  #|movsx r11w, bl|66440fbedb|MOVSX16rr8:%R11W,%BL|rax=44363860410ce40a rcx=800da994694148c7 rdx=2a92dc180bbebf47 rbx=3c862515b2020a67 r11=14b3 f=892|r11=67 f=890/0
  #|movsx r11w, bl|66440fbedb|MOVSX16rr8:%R11W,%BL|rax=973ec4edcbf106d0 rbx=7023ccb4d45cf2a2 r11=c960d465656679d1 f=82|r11=c960d4656566ffa2 f=80/0
  #|movsx r11w, byte ptr [rdi + r9*2 - 0x4]|66460fbe5c4ffc|MOVSX16rm8:%R11W,%RDI,2,%R9,-4,%|rax=e6f836fc4a789560 rcx=a71dda935f2eadf5 rdx=1 rbx=4 r9=c r11=a72841a680000000 f=92 m10114=9f7d02410eb7c188f7cd6ddf72211e92|r11=a72841a68000ff9f f=90/0
  #|movsx r11w, byte ptr [rdi + r9*2 - 0x4]|66460fbe5c4ffc|MOVSX16rm8:%R11W,%RDI,2,%R9,-4,%|rax=f29669767361da0f rcx=be43eee65c50a1af rdx=a64ed80be8ea4c6b rbx=1 r9=2 r11=80000000 f=46 m10100=ef213adaebc85d88770da27e9d1d42f1|r11=8000ffef f=44/0
  #|movsx r13d, cl|440fbee9|MOVSX32rr8:%R13D,%CL|rcx=c8ecef1303bf80f8 rdx=7eaae6d73b736d53 r13=2 f=c2|r13=fffffff8 f=c0/0
  #|movsx r13d, cl|440fbee9|MOVSX32rr8:%R13D,%CL|rax=0 rcx=d5913412314b6060 rdx=da8e7cfb97999603 r13=8000000000000000 f=892|r13=60 f=890/0
  #|movsx r13d, cl|440fbee9|MOVSX32rr8:%R13D,%CL|rax=7d709d7beb9b2b05 rcx=2 rdx=cb02647b8b018147 r13=97e01e44c58538c5 f=8c7|r13=2 f=8c5/0
  #|movsx r13d, byte ptr [rsp + 0x8]|440fbe6c2408|MOVSX32rm8:%R13D,%RSP,1,%,8,%|rcx=f rdx=424 rbx=d r9=e r13=c8 f=882 m20108=6667b6d2d5ee15dba9dc83371c008592|r13=66 f=880/0
  #|movsx r13d, byte ptr [rsp + 0x8]|440fbe6c2408|MOVSX32rm8:%R13D,%RSP,1,%,8,%|rax=f1af76a2f4373e04 rcx=43 rbx=2 r9=b r13=7a740ebaff53a20b f=852 m20108=010c370b865a8f7509e2a3ff3c00f159|r13=1 f=850/0
  #|movsx ecx, ax|0fbfc8|MOVSX32rr16:%ECX,%AX|rax=6745b2c5a222fc15 rcx=6729545b76fd6a80 rdx=be f=897|rcx=fffffc15 f=895/0
  #|movsx ecx, ax|0fbfc8|MOVSX32rr16:%ECX,%AX|rax=fc217ea2e3c25855 rcx=7e72c3b82929d479 rdx=8000000000000000 f=847|rcx=5855 f=845/0
  #|movsx ecx, ax|0fbfc8|MOVSX32rr16:%ECX,%AX|rax=59bdeddcbeee1f98 rcx=78255018f59e4c90 f=82|rcx=1f98 f=80/0
  #|movsx ecx, word ptr [rsp + 0x8]|0fbf4c2408|MOVSX32rm16:%ECX,%RSP,1,%,8,%|rcx=50 rdx=542f98cd753d6e9 rbx=c r9=3 f=92 m20108=9a1f31ef0235c690480ceda8114ea17f|rcx=1f9a f=90/0
  #|movsx ecx, word ptr [rsp + 0x8]|0fbf4c2408|MOVSX32rm16:%ECX,%RSP,1,%,8,%|rax=f177c52c9ce7193b rcx=457b0ae69000c7db rdx=8000000000000000 rbx=4 r9=f f=483 m20108=8a760a873c9fd4a3d55c81c54890e321|rcx=768a f=481/0
  #|movsx r15, r8b|4d0fbef8|MOVSX64rr8:%R15,%R8B|rax=5fc81389c405b6cc rcx=60f279ca465f7fff r8=62bac00b3276ddc r15=80 f=816|r15=ffffffffffffffdc f=814/0
  #|movsx r15, r8b|4d0fbef8|MOVSX64rr8:%R15,%R8B|rax=352ad71374962c73 rcx=8e3db78b97760922 rdx=5b0c9985cc1f9bfe r8=80000000 r15=96b3ac015175dde3 f=52|r15=0 f=50/0
  #|movsx r15, r8b|4d0fbef8|MOVSX64rr8:%R15,%R8B|rax=9adec6fa6b9a0c85 r8=9da712afd1396837 r15=2faac93b4697b077 f=897|r15=37 f=895/0
  #|movsx r15, byte ptr [rbp - 0x20]|4c0fbe7de0|MOVSX64rm8:%R15,%RBP,1,%,-32,%|rax=dcf09fd5344f820b rcx=ffffffffffffffff rdx=7879bf4210c370f rbx=3 r9=c r15=8a13ff287fffffff f=53 m20160=c2c8bc4384261a9feef3d05ebeddc59e|r15=ffffffffffffffc2 f=51/0
  #|movsx r15, byte ptr [rbp - 0x20]|4c0fbe7de0|MOVSX64rm8:%R15,%RBP,1,%,-32,%|rax=ff rdx=55b4 rbx=7 r9=9 r15=165f86304e85ad10 f=16 m20160=08463e306e19a63cb8e02a9d8a571841|r15=8 f=14/0
  #|movsx r8, r14w|4d0fbfc6|MOVSX64rr16:%R8,%R14W|rax=4f60b95447f7122 rcx=2e01faa978fa177c r8=32b043fc283daab1 r14=8bc9b9c03923b6fc f=812|r8=ffffffffffffb6fc f=810/0
  #|movsx r8, r14w|4d0fbfc6|MOVSX64rr16:%R8,%R14W|rax=7fffffffffffffff rcx=7 rdx=f0bac983834d3e80 r8=af4ba3b109c2a6ff r14=5880b4c88eaadf62 f=7|r8=ffffffffffffdf62 f=5/0
  #|movsx r8, r14w|4d0fbfc6|MOVSX64rr16:%R8,%R14W|rax=d3bec9adb1110413 rcx=100 r8=5f8aedb18314fe5b r14=b9ef f=53|r8=ffffffffffffb9ef f=51/0
  #|movsx r8, word ptr [rdi + r9*2 - 0x4]|4e0fbf444ffc|MOVSX64rm16:%R8,%RDI,2,%R9,-4,%|rdx=2eca1b832246452 rbx=d r8=6ed429a2f89476ca r9=9 f=4d7 m1010e=483961ac448446026bfe4221002576ff|r8=3948 f=4d5/0
  #|movsx r8, word ptr [rdi + r9*2 - 0x4]|4e0fbf444ffc|MOVSX64rm16:%R8,%RDI,2,%R9,-4,%|rax=eec6e6ed5ad60e8c rcx=ff rdx=3019176fd6b4e27 rbx=e r8=142ecbe8792b3b03 r9=9 f=53 m1010e=3a125052caaf328e43569260a49e125d|r8=123a f=51/0
  #|cmovo r11w, r15w|66450f40df|CMOV16rr:%R11W,%R11W,%R15W,0|r11=26eeea4458dabd85 r15=26f150bfff892ac3 f=857|r11=26eeea4458da2ac3 f=855/0
  #|cmovo ecx, eax|0f40c8|CMOV32rr:%ECX,%ECX,%EAX,0|rax=69c6f1d65e269938 rcx=bfb3c06528a5957a f=2|rcx=28a5957a f=0/0
  #|cmovo ecx, eax|0f40c8|CMOV32rr:%ECX,%ECX,%EAX,0|rax=88f1861d9bd6459a rcx=17de35f308de4280 f=52|rcx=8de4280 f=50/0
  #|cmovo ecx, eax|0f40c8|CMOV32rr:%ECX,%ECX,%EAX,0|rax=5b7f40006172b100 rcx=8123eae784e49547 f=883|rcx=6172b100 f=881/0
  #|cmovo rcx, r8|490f40c8|CMOV64rr:%RCX,%RCX,%R8,0|rcx=94df27e77d38fbcb r8=a f=497|f=495/0
  #|cmovo ebx, dword ptr [rdi + r9*2 - 0x4]|420f405c4ffc|CMOV32rm:%EBX,%EBX,%RDI,2,%R9,-4,%,0|rbx=d r9=7 f=57 m1010a=0e0a174a014110b9254db84eaaffc601|f=55/0
  #|cmovo ebx, dword ptr [rdi + r9*2 - 0x4]|420f405c4ffc|CMOV32rm:%EBX,%EBX,%RDI,2,%R9,-4,%,0|rbx=f r9=d f=8c6 m10116=527aa9a2be57868b79a201e560c55f5d|rbx=a2a97a52 f=8c4/0
  #|seto r13b|410f90c5|SETCCr:%R13B,0|r13=a17439bb7614ea7f f=82|r13=a17439bb7614ea00 f=80/0
  #|seto r13b|410f90c5|SETCCr:%R13B,0|r13=19b852c4dbf865e7 f=8d3|r13=19b852c4dbf86501 f=8d1/0
  #|seto r13b|410f90c5|SETCCr:%R13B,0|r13=2d9c14a5e763e7ed f=87|r13=2d9c14a5e763e700 f=85/0
  #|seto byte ptr [rbp - 0x20]|0f9045e0|SETCCm:%RBP,1,%,-32,%,0|rbx=9 r9=b f=d3 m20160=db8dcc86cb292ec0020e9e7f4fd18a21|f=d1/0 m20160=00
  #|cmovno r13w, r9w|66450f41e9|CMOV16rr:%R13W,%R13W,%R9W,1|r9=f7b37575f2b57182 r13=4611a97b5034e04c f=43|r13=4611a97b50347182 f=41/0
  #|cmovno r13d, r8d|450f41e8|CMOV32rr:%R13D,%R13D,%R8D,1|r8=3 r13=c8 f=897|f=895/0
  #|cmovno r13d, r8d|450f41e8|CMOV32rr:%R13D,%R13D,%R8D,1|r8=1 r13=26b73f1b6a8c2a59 f=812|r13=6a8c2a59 f=810/0
  #|cmovno r13d, r8d|450f41e8|CMOV32rr:%R13D,%R13D,%R8D,1|r8=cf7f4bf1fa9527a5 r13=43b3 f=53|r13=fa9527a5 f=51/0
  #|cmovno r13, r12|4d0f41ec|CMOV64rr:%R13,%R13,%R12,1|r12=a617 r13=91a969220186e940 f=843|f=841/0
  #|cmovno ecx, dword ptr [rsi]|0f410e|CMOV32rm:%ECX,%ECX,%RSI,1,%,0,%,1|rcx=79c08d1a4cada0d8 rbx=7 r9=d f=97 m10080=f1217315aecdd0e7ce333292c5db04bd|rcx=157321f1 f=95/0
  #|cmovno ecx, dword ptr [rsi]|0f410e|CMOV32rm:%ECX,%ECX,%RSI,1,%,0,%,1|rcx=da0d20657fffffff rbx=8 r9=a f=8d3 m10080=d321b5a9b48d9e5c661843a1ebc0eb10|rcx=7fffffff f=8d1/0
  #|setno r11b|410f91c3|SETCCr:%R11B,1|r11=14ed60c9064a3480 f=c52|r11=14ed60c9064a3400 f=c50/0
  #|setno r11b|410f91c3|SETCCr:%R11B,1|r11=e0e0686b25227e0f f=893|r11=e0e0686b25227e00 f=891/0
  #|setno r11b|410f91c3|SETCCr:%R11B,1|r11=a917f01d71315bf3 f=887|r11=a917f01d71315b00 f=885/0
  #|setno byte ptr [rdi + r9*2 - 0x4]|420f91444ffc|SETCCm:%RDI,2,%R9,-4,%,1|rbx=0 r9=7 f=d3 m1010a=ae0fe950a8958686761e114c7ea1a5dc|f=d1/0 m1010a=01
  #|cmovb r14w, r10w|66450f42f2|CMOV16rr:%R14W,%R14W,%R10W,2|r10=842e9d77cd7a31a r14=6 f=412|f=410/0
  #|cmovb r12d, r15d|450f42e7|CMOV32rr:%R12D,%R12D,%R15D,2|r12=6343b0fad1e61100 r15=9b13384d2fe338be f=8c2|r12=d1e61100 f=8c0/0
  #|cmovb r12d, r15d|450f42e7|CMOV32rr:%R12D,%R12D,%R15D,2|r12=d35fd805efa5a61d r15=8cbc537eb5b74831 f=c56|r12=efa5a61d f=c54/0
  #|cmovb r12d, r15d|450f42e7|CMOV32rr:%R12D,%R12D,%R15D,2|r12=184fa0e46ab5fd0d r15=dd f=53|r12=dd f=51/0
  #|cmovb r8, r15|4d0f42c7|CMOV64rr:%R8,%R8,%R15,2|r8=c9d3269c2719d28c r15=80000000 f=812|f=810/0
  #|cmovb eax, dword ptr [rbp - 0x20]|0f4245e0|CMOV32rm:%EAX,%EAX,%RBP,1,%,-32,%,2|rax=300965567353c2eb rbx=5 r9=1 f=453 m20160=192ba6cb798f1d50c2a2949a40d10085|rax=cba62b19 f=451/0
  #|cmovb eax, dword ptr [rbp - 0x20]|0f4245e0|CMOV32rm:%EAX,%EAX,%RBP,1,%,-32,%,2|rax=6df57a8d031acde2 rbx=6 r9=0 f=802 m20160=794db4afc1da3df5b5ca9033889b1816|rax=31acde2 f=800/0
  #|setb al|0f92c0|SETCCr:%AL,2|rax=8000000000000000 f=882|f=880/0
  #|setb al|0f92c0|SETCCr:%AL,2|rax=5d75bafe8f2b0e5f f=8d7|rax=5d75bafe8f2b0e01 f=8d5/0
  #|setb al|0f92c0|SETCCr:%AL,2|rax=49903bbd174cc7f2 f=883|rax=49903bbd174cc701 f=881/0
  #|setb byte ptr [rsi + rbx*4 + 0x8]|0f92449e08|SETCCm:%RSI,4,%RBX,8,%,2|rbx=f r9=b f=847 m100c4=e3d5f9fe1f7983d287e92abef019b42b|f=845/0 m100c4=01
  #|cmovae r15w, r14w|66450f43fe|CMOV16rr:%R15W,%R15W,%R14W,3|r14=3d r15=b421 f=c52|r15=3d f=c50/0
  #|cmovae eax, ebx|0f43c3|CMOV32rr:%EAX,%EAX,%EBX,3|rax=3be8307fa6bfb26f rbx=c6 f=13|rax=a6bfb26f f=11/0
  #|cmovae eax, ebx|0f43c3|CMOV32rr:%EAX,%EAX,%EBX,3|rax=6c52586b1a2cd798 rbx=4e7cd4327eab65dd f=482|rax=7eab65dd f=480/0
  #|cmovae eax, ebx|0f43c3|CMOV32rr:%EAX,%EAX,%EBX,3|rax=ff rbx=c0e8 f=802|rax=c0e8 f=800/0
  #|cmovae r10, r14|4d0f43d6|CMOV64rr:%R10,%R10,%R14,3|r10=4c3bf7612fcb77fc r14=f1c575b435cd265b f=17|f=15/0
  #|cmovae ecx, dword ptr [rsp + 0x8]|0f434c2408|CMOV32rm:%ECX,%ECX,%RSP,1,%,8,%,3|rcx=77820fcc156ddcee rbx=9 r9=3 f=c2 m20108=493cd04cece244d23d435dc2fba123c7|rcx=4cd03c49 f=c0/0
  #|cmovae ecx, dword ptr [rsp + 0x8]|0f434c2408|CMOV32rm:%ECX,%ECX,%RSP,1,%,8,%,3|rcx=a1f4fca9e30efb85 rbx=d r9=f f=12 m20108=419c36fce1b7f5576c8b179b70f871d4|rcx=fc369c41 f=10/0
  #|setae r9b|410f93c1|SETCCr:%R9B,3|r9=f7367d6f9398c3af f=cc6|r9=f7367d6f9398c301 f=cc4/0
  #|setae r9b|410f93c1|SETCCr:%R9B,3|r9=d8bcb8f96df7107f f=13|r9=d8bcb8f96df71000 f=11/0
  #|setae r9b|410f93c1|SETCCr:%R9B,3|r9=707cba4708039e3d f=57|r9=707cba4708039e00 f=55/0
  #|setae byte ptr [rsp + 0x8]|0f93442408|SETCCm:%RSP,1,%,8,%,3|rbx=6 r9=2 f=57 m20108=812e65a4e97f1fe79a7c9edad4df81e3|f=55/0 m20108=00
  #|cmove r13w, dx|66440f44ea|CMOV16rr:%R13W,%R13W,%DX,4|rdx=f r13=16472761646a6c89 f=43|r13=16472761646a000f f=41/0
  #|cmove r11d, ebx|440f44db|CMOV32rr:%R11D,%R11D,%EBX,4|rbx=c29f8d4e8f1ec55e r11=5b19b0068fac69c1 f=816|r11=8fac69c1 f=814/0
  #|cmove r11d, ebx|440f44db|CMOV32rr:%R11D,%R11D,%EBX,4|rbx=55b5c5f6f03f9495 r11=ef533160642c81ee f=97|r11=642c81ee f=95/0
  #|cmove r11d, ebx|440f44db|CMOV32rr:%R11D,%R11D,%EBX,4|rbx=4425 r11=7fff f=882|f=880/0
  #|cmove rax, r15|490f44c7|CMOV64rr:%RAX,%RAX,%R15,4|rax=a06e3b5edb37ab34 r15=820fc7cce9993a02 f=813|f=811/0
  #|cmove r9d, dword ptr [rdi + r9*2 - 0x4]|460f444c4ffc|CMOV32rm:%R9D,%R9D,%RDI,2,%R9,-4,%,4|rbx=7 r9=a f=842 m10110=407caaa80f874d7ce89bcb24d05b7dec|r9=a8aa7c40 f=840/0
  #|cmove r9d, dword ptr [rdi + r9*2 - 0x4]|460f444c4ffc|CMOV32rm:%R9D,%R9D,%RDI,2,%R9,-4,%,4|rbx=0 r9=9 f=c52 m1010e=ad5dac3d0c7cf347ba6c0847fa435c9b|r9=3dac5dad f=c50/0
  #|sete r9b|410f94c1|SETCCr:%R9B,4|r9=53779856ef1752e3 f=4d2|r9=53779856ef175201 f=4d0/0
  #|sete r9b|410f94c1|SETCCr:%R9B,4|r9=f61e2e8a0689822b f=8c7|r9=f61e2e8a06898201 f=8c5/0
  #|sete r9b|410f94c1|SETCCr:%R9B,4|r9=4a f=c2|r9=1 f=c0/0
  #|sete byte ptr [rsp + 0x8]|0f94442408|SETCCm:%RSP,1,%,8,%,4|rbx=e r9=c f=c16 m20108=f0535e1c2af814691d02f1f9bcaa5198|f=c14/0 m20108=00
  #|cmovne r9w, r15w|66450f45cf|CMOV16rr:%R9W,%R9W,%R15W,5|r9=5820e1d65da9730f r15=d96de4f7ef1a4bd6 f=413|r9=5820e1d65da94bd6 f=411/0
  #|cmovne r12d, r9d|450f45e1|CMOV32rr:%R12D,%R12D,%R9D,5|r9=2a95 r12=1ceabeced56f620 f=4c6|r12=ed56f620 f=4c4/0
  #|cmovne r12d, r9d|450f45e1|CMOV32rr:%R12D,%R12D,%R9D,5|r9=8000000000000000 r12=dcdf78033b83036f f=8c7|r12=3b83036f f=8c5/0
  #|cmovne r12d, r9d|450f45e1|CMOV32rr:%R12D,%R12D,%R9D,5|r9=e770f44b733efdc9 r12=5d8911942bb42599 f=cd6|r12=2bb42599 f=cd4/0
  #|cmovne r12, rbx|4c0f45e3|CMOV64rr:%R12,%R12,%RBX,5|rbx=7fffffffffffffff r12=3eeb0926ffb48000 f=8c2|f=8c0/0
  #|cmovne r15d, dword ptr [rdi + r9*2 - 0x4]|460f457c4ffc|CMOV32rm:%R15D,%R15D,%RDI,2,%R9,-4,%,5|rbx=8 r9=b r15=769938cf0000d752 f=c7 m10112=a97be86c984d7978823ba4393a5abd4d|r15=d752 f=c5/0
  #|cmovne r15d, dword ptr [rdi + r9*2 - 0x4]|460f457c4ffc|CMOV32rm:%R15D,%R15D,%RDI,2,%R9,-4,%,5|rbx=f r9=2 r15=e75476e0c5b8f01f f=c17 m10100=8a0d1b8be121e3bad1a767bfa9ea9746|r15=8b1b0d8a f=c15/0
  #|setne r13b|410f95c5|SETCCr:%R13B,5|r13=89d1f2f3206e42e0 f=16|r13=89d1f2f3206e4201 f=14/0
  #|setne r13b|410f95c5|SETCCr:%R13B,5|r13=4ae572f31a4a83e f=12|r13=4ae572f31a4a801 f=10/0
  #|setne r13b|410f95c5|SETCCr:%R13B,5|r13=f959 f=843|r13=f900 f=841/0
  #|setne byte ptr [rdi + 0x10]|0f954710|SETCCm:%RDI,1,%,16,%,5|rbx=0 r9=4 f=43 m10110=3fd47edfb43cc8c5e5f1fdcfe673a3dd|f=41/0 m10110=00
  #|cmovbe ax, r14w|66410f46c6|CMOV16rr:%AX,%AX,%R14W,6|rax=1 r14=c5272c4f6011ca45 f=17|rax=ca45 f=15/0
  #|cmovbe edx, r11d|410f46d3|CMOV32rr:%EDX,%EDX,%R11D,6|rdx=e8 r11=7a38849368bbd91 f=52|rdx=368bbd91 f=50/0
  #|cmovbe edx, r11d|410f46d3|CMOV32rr:%EDX,%EDX,%R11D,6|rdx=fcf44788ffffffff r11=bc4d8602ab6e12b5 f=c53|rdx=ab6e12b5 f=c51/0
  #|cmovbe edx, r11d|410f46d3|CMOV32rr:%EDX,%EDX,%R11D,6|rdx=8cb79cfcc847edec r11=40 f=87|rdx=40 f=85/0
  #|cmovbe r9, r10|4d0f46ca|CMOV64rr:%R9,%R9,%R10,6|r9=2 r10=250b5a447e1380f9 f=846|r9=250b5a447e1380f9 f=844/0
  #|cmovbe r10d, dword ptr [rsi + rbx*4 + 0x8]|440f46549e08|CMOV32rm:%R10D,%R10D,%RSI,4,%RBX,8,%,6|rbx=1 r9=c r10=facb0c2c63cd3dd2 f=c6 m1008c=2e9dd4e255c6c747f4172018864b7a80|r10=e2d49d2e f=c4/0
  #|cmovbe r10d, dword ptr [rsi + rbx*4 + 0x8]|440f46549e08|CMOV32rm:%R10D,%R10D,%RSI,4,%RBX,8,%,6|rbx=0 r9=9 r10=989d f=8d3 m10088=8cdc1d4bdccf391d6e5f8dd97dee1f76|r10=4b1ddc8c f=8d1/0
  #|setbe r14b|410f96c6|SETCCr:%R14B,6|r14=e06e5192b5977872 f=56|r14=e06e5192b5977801 f=54/0
  #|setbe r14b|410f96c6|SETCCr:%R14B,6|r14=4e74567a88120485 f=c52|r14=4e74567a88120401 f=c50/0
  #|setbe r14b|410f96c6|SETCCr:%R14B,6|r14=ffff f=c7|r14=ff01 f=c5/0
  #|setbe byte ptr [rsp + 0x8]|0f96442408|SETCCm:%RSP,1,%,8,%,6|rbx=1 r9=7 f=807 m20108=c7985617e366079fe829b39bc11c001b|f=805/0 m20108=01
  #|cmova ax, r8w|66410f47c0|CMOV16rr:%AX,%AX,%R8W,7|rax=ffff r8=7 f=817|f=815/0
  #|cmova ebx, edx|0f47da|CMOV32rr:%EBX,%EBX,%EDX,7|rdx=6384687e09215280 rbx=8a f=47|f=45/0
  #|cmova ebx, edx|0f47da|CMOV32rr:%EBX,%EBX,%EDX,7|rdx=5635 rbx=31fbcfa57ef99f14 f=857|rbx=7ef99f14 f=855/0
  #|cmova ebx, edx|0f47da|CMOV32rr:%EBX,%EBX,%EDX,7|rdx=337a8b6e00732c44 rbx=29d2ed2b184cbe0d f=56|rbx=184cbe0d f=54/0
  #|cmova r8, r14|4d0f47c6|CMOV64rr:%R8,%R8,%R14,7|r8=c2ef7b13dca2b085 r14=2284ad556617d00 f=3|f=1/0
  #|cmova r9d, dword ptr [rsi + rbx*4 + 0x8]|440f474c9e08|CMOV32rm:%R9D,%R9D,%RSI,4,%RBX,8,%,7|rbx=9 r9=9 f=843 m100ac=751496189648e1563a97b6da2075f81f|f=841/0
  #|cmova r9d, dword ptr [rsi + rbx*4 + 0x8]|440f474c9e08|CMOV32rm:%R9D,%R9D,%RSI,4,%RBX,8,%,7|rbx=4 r9=d f=43 m10098=32fc460e1e9060009ce0d656e74afbe5|f=41/0
  #|seta r15b|410f97c7|SETCCr:%R15B,7|r15=1938 f=56|r15=1900 f=54/0
  #|seta r15b|410f97c7|SETCCr:%R15B,7|r15=b5e407949bb900d6 f=86|r15=b5e407949bb90001 f=84/0
  #|seta r15b|410f97c7|SETCCr:%R15B,7|r15=3bf216001c279e50 f=442|r15=3bf216001c279e00 f=440/0
  #|seta byte ptr [rsp + 0x8]|0f97442408|SETCCm:%RSP,1,%,8,%,7|rbx=d r9=6 f=c83 m20108=b4bb5f5c315f93f910421f6da2a3c91d|f=c81/0 m20108=00
  #|cmovs r9w, r8w|66450f48c8|CMOV16rr:%R9W,%R9W,%R8W,8|r8=7764a4ab510d882c r9=177e5b544ae9906d f=896|r9=177e5b544ae9882c f=894/0
  #|cmovs r11d, r10d|450f48da|CMOV32rr:%R11D,%R11D,%R10D,8|r10=d450812f0a2d591d r11=e874693ebd541901 f=57|r11=bd541901 f=55/0
  #|cmovs r11d, r10d|450f48da|CMOV32rr:%R11D,%R11D,%R10D,8|r10=b4eff1fdaf4f0dee r11=23 f=803|f=801/0
  #|cmovs r11d, r10d|450f48da|CMOV32rr:%R11D,%R11D,%R10D,8|r10=ed2e60d2994b3507 r11=95e0ed3aca82646d f=887|r11=994b3507 f=885/0
  #|cmovs r15, r14|4d0f48fe|CMOV64rr:%R15,%R15,%R14,8|r14=1029e2a9f7bc8000 r15=9ab956ef84001993 f=42|f=40/0
  #|cmovs eax, dword ptr [rsi]|0f4806|CMOV32rm:%EAX,%EAX,%RSI,1,%,0,%,8|rax=320c462a031ef78e rbx=2 r9=4 f=c7 m10080=94961970ab07473e88919d7899e9c598|rax=70199694 f=c5/0
  #|cmovs eax, dword ptr [rsi]|0f4806|CMOV32rm:%EAX,%EAX,%RSI,1,%,0,%,8|rax=d20a6d28a58ff500 rbx=1 r9=7 f=42 m10080=4d5464714d2412bd60c840a4bf6eb6bf|rax=a58ff500 f=40/0
  #|sets cl|0f98c1|SETCCr:%CL,8|rcx=32627131ff5f9d63 f=8c3|rcx=32627131ff5f9d01 f=8c1/0
  #|sets cl|0f98c1|SETCCr:%CL,8|rcx=8000000000000000 f=c3|rcx=8000000000000001 f=c1/0
  #|sets cl|0f98c1|SETCCr:%CL,8|rcx=68356ffa7666cbed f=886|rcx=68356ffa7666cb01 f=884/0
  #|sets byte ptr [rdi + r9*2 - 0x4]|420f98444ffc|SETCCm:%RDI,2,%R9,-4,%,8|rbx=4 r9=c f=807 m10114=a0aa98a83eb7bc94c8089f7e3a349474|f=805/0 m10114=00
  #|cmovns r13w, dx|66440f49ea|CMOV16rr:%R13W,%R13W,%DX,9|rdx=d7cfec5680000000 r13=5bb5c2ab9be3f8c5 f=92|f=90/0
  #|cmovns ecx, r10d|410f49ca|CMOV32rr:%ECX,%ECX,%R10D,9|rcx=af1b68ca936816cf r10=f f=892|rcx=936816cf f=890/0
  #|cmovns ecx, r10d|410f49ca|CMOV32rr:%ECX,%ECX,%R10D,9|rcx=e33ba6318d949724 r10=2627d7f97a98e49a f=d6|rcx=8d949724 f=d4/0
  #|cmovns ecx, r10d|410f49ca|CMOV32rr:%ECX,%ECX,%R10D,9|rcx=5f2a809b2befabbc r10=4bb638ec1cd2ffff f=47|rcx=1cd2ffff f=45/0
  #|cmovns r15, rax|4c0f49f8|CMOV64rr:%R15,%R15,%RAX,9|rax=17624a5fc6949c18 r15=2 f=86|f=84/0
  #|cmovns r14d, dword ptr [rdi + 0x10]|440f497710|CMOV32rm:%R14D,%R14D,%RDI,1,%,16,%,9|rbx=8 r9=f r14=46044e5b79d3f1f2 f=c12 m10110=a3c40433321c39ce436ed94f1bf0aa4e|r14=3304c4a3 f=c10/0
  #|cmovns r14d, dword ptr [rdi + 0x10]|440f497710|CMOV32rm:%R14D,%R14D,%RDI,1,%,16,%,9|rbx=7 r9=f r14=65f9fc6763157ee9 f=8d2 m10110=110eaa9a6b64e576c47f9fccca085ad0|r14=63157ee9 f=8d0/0
  #|setns al|0f99c0|SETCCr:%AL,9|rax=8000000000000000 f=93|f=91/0
  #|setns al|0f99c0|SETCCr:%AL,9|rax=90436847dcf1c36c f=12|rax=90436847dcf1c301 f=10/0
  #|setns al|0f99c0|SETCCr:%AL,9|rax=120a37b1af57e1c9 f=4d2|rax=120a37b1af57e100 f=4d0/0
  #|setns byte ptr [rbp - 0x20]|0f9945e0|SETCCm:%RBP,1,%,-32,%,9|rbx=d r9=2 f=2 m20160=a99bc384fb58ef20a3fdc54213b78729|f=0/0 m20160=01
  #|cmovp r9w, r12w|66450f4acc|CMOV16rr:%R9W,%R9W,%R12W,10|r9=4cc4b83b25920379 r12=e0566e5c1b1eb3ed f=c87|r9=4cc4b83b2592b3ed f=c85/0
  #|cmovp r11d, r14d|450f4ade|CMOV32rr:%R11D,%R11D,%R14D,10|r11=6bf4a5ec298634b8 r14=b6e3698a05d09df4 f=13|r11=298634b8 f=11/0
  #|cmovp r11d, r14d|450f4ade|CMOV32rr:%R11D,%R11D,%R14D,10|r11=cb25c8defedd6eef r14=f3a735632eec0869 f=86|r11=2eec0869 f=84/0
  #|cmovp r11d, r14d|450f4ade|CMOV32rr:%R11D,%R11D,%R14D,10|r11=1aba2c670806177 r14=100 f=406|r11=100 f=404/0
  #|cmovp r13, rbx|4c0f4aeb|CMOV64rr:%R13,%R13,%RBX,10|rbx=78 r13=589be4ba2d1f6687 f=813|f=811/0
  #|cmovp edx, dword ptr [rdi + 0x10]|0f4a5710|CMOV32rm:%EDX,%EDX,%RDI,1,%,16,%,10|rdx=30061761b9f9d7bc rbx=d r9=3 f=47 m10110=39f1c04a8f7ea7855e42618593869cae|rdx=4ac0f139 f=45/0
  #|cmovp edx, dword ptr [rdi + 0x10]|0f4a5710|CMOV32rm:%EDX,%EDX,%RDI,1,%,16,%,10|rdx=bbbf5e3c29122705 rbx=1 r9=6 f=813 m10110=38f1c105c33598c2ffc8aab90ab4626e|rdx=29122705 f=811/0
  #|setp r9b|410f9ac1|SETCCr:%R9B,10|r9=d73bbe216885901b f=42|r9=d73bbe2168859000 f=40/0
  #|setp r9b|410f9ac1|SETCCr:%R9B,10|r9=100 f=c06|r9=101 f=c04/0
  #|setp r9b|410f9ac1|SETCCr:%R9B,10|r9=bf0c2a06075d70e1 f=8d2|r9=bf0c2a06075d7000 f=8d0/0
  #|setp byte ptr [rbp - 0x20]|0f9a45e0|SETCCm:%RBP,1,%,-32,%,10|rbx=1 r9=f f=12 m20160=02b88faa0c80bd3ad20dc8d1898b7ca4|f=10/0 m20160=00
  #|cmovnp ax, r13w|66410f4bc5|CMOV16rr:%AX,%AX,%R13W,11|rax=961c6e51d7d45e43 r13=76747423aebae0ea f=812|rax=961c6e51d7d4e0ea f=810/0
  #|cmovnp ecx, r8d|410f4bc8|CMOV32rr:%ECX,%ECX,%R8D,11|rcx=c76fe828ca6945fa r8=80000000 f=82|rcx=80000000 f=80/0
  #|cmovnp ecx, r8d|410f4bc8|CMOV32rr:%ECX,%ECX,%R8D,11|rcx=68085069c136ddea r8=6e f=893|rcx=6e f=891/0
  #|cmovnp ecx, r8d|410f4bc8|CMOV32rr:%ECX,%ECX,%R8D,11|rcx=21bbbd6dc98665bb r8=ae51bd055d4137d9 f=93|rcx=5d4137d9 f=91/0
  #|cmovnp r10, rcx|4c0f4bd1|CMOV64rr:%R10,%R10,%RCX,11|rcx=b r10=ffffffffffffffff f=c6|f=c4/0
  #|cmovnp r8d, dword ptr [rbp - 0x20]|440f4b45e0|CMOV32rm:%R8D,%R8D,%RBP,1,%,-32,%,11|rbx=1 r8=1 r9=4 f=816 m20160=671b82ebbd3703917fcf928f86c69fa5|f=814/0
  #|cmovnp r8d, dword ptr [rbp - 0x20]|440f4b45e0|CMOV32rm:%R8D,%R8D,%RBP,1,%,-32,%,11|rbx=d r8=345dd3fbd68caeb r9=d f=92 m20160=c6a121c8827ef0761c4bc2cd5d634c98|r8=c821a1c6 f=90/0
  #|setnp r15b|410f9bc7|SETCCr:%R15B,11|r15=b46658d533427384 f=c6|r15=b46658d533427300 f=c4/0
  #|setnp r15b|410f9bc7|SETCCr:%R15B,11|r15=f3921962ffffffff f=492|r15=f3921962ffffff01 f=490/0
  #|setnp r15b|410f9bc7|SETCCr:%R15B,11|r15=21d0486be6ec8a07 f=43|r15=21d0486be6ec8a01 f=41/0
  #|setnp byte ptr [rdi + r9*2 - 0x4]|420f9b444ffc|SETCCm:%RDI,2,%R9,-4,%,11|rbx=7 r9=7 f=d2 m1010a=420e93a3cbd6e07e44074dbe495e29b5|f=d0/0 m1010a=01
  #|cmovl r8w, r14w|66450f4cc6|CMOV16rr:%R8W,%R8W,%R14W,12|r8=b6ef21e7d773f442 r14=50d50c85db869f8a f=406|f=404/0
  #|cmovl r12d, ecx|440f4ce1|CMOV32rr:%R12D,%R12D,%ECX,12|rcx=2a63fcda6fe8000 r12=6a7506261b9c3abb f=802|r12=a6fe8000 f=800/0
  #|cmovl r12d, ecx|440f4ce1|CMOV32rr:%R12D,%R12D,%ECX,12|rcx=7d r12=9 f=83|r12=7d f=81/0
  #|cmovl r12d, ecx|440f4ce1|CMOV32rr:%R12D,%R12D,%ECX,12|rcx=b6d8 r12=c410de6fc9418e7f f=8c6|r12=c9418e7f f=8c4/0
  #|cmovl r15, rax|4c0f4cf8|CMOV64rr:%R15,%R15,%RAX,12|rax=557c9c17faf62e09 r15=40b83c41c56c6a9f f=882|f=880/0
  #|cmovl r10d, dword ptr [rbp - 0x20]|440f4c55e0|CMOV32rm:%R10D,%R10D,%RBP,1,%,-32,%,12|rbx=b r9=e r10=aa6c0e26aacd23aa f=c6 m20160=83068230bfe9d7494f825861a4c6102c|r10=30820683 f=c4/0
  #|cmovl r10d, dword ptr [rbp - 0x20]|440f4c55e0|CMOV32rm:%R10D,%R10D,%RBP,1,%,-32,%,12|rbx=2 r9=9 r10=5aa9d061ddef1992 f=c7 m20160=23bebddc7cdfa1993bc9f6727364a341|r10=dcbdbe23 f=c5/0
  #|setl r11b|410f9cc3|SETCCr:%R11B,12|r11=e9015ce3731ca878 f=493|r11=e9015ce3731ca801 f=491/0
  #|setl r11b|410f9cc3|SETCCr:%R11B,12|r11=10b267bda2e2b8c8 f=852|r11=10b267bda2e2b801 f=850/0
  #|setl r11b|410f9cc3|SETCCr:%R11B,12|r11=f41309307bf4aa5e f=c93|r11=f41309307bf4aa00 f=c91/0
  #|setl byte ptr [rsi + rbx*4 + 0x8]|0f9c449e08|SETCCm:%RSI,4,%RBX,8,%,12|rbx=c r9=4 f=57 m100b8=44d3be4bf1a0f4f0ef91278f7b39a1bf|f=55/0 m100b8=00
  #|cmovge dx, r10w|66410f4dd2|CMOV16rr:%DX,%DX,%R10W,13|rdx=ef17880c96b8951e r10=f32edf3265b3c40e f=886|rdx=ef17880c96b8c40e f=884/0
  #|cmovge r15d, edx|440f4dfa|CMOV32rr:%R15D,%R15D,%EDX,13|rdx=8000 r15=1edf9dc7e991def1 f=442|r15=8000 f=440/0
  #|cmovge r15d, edx|440f4dfa|CMOV32rr:%R15D,%R15D,%EDX,13|rdx=ffffffffffffffff r15=73fbfa2ce29bf885 f=806|r15=e29bf885 f=804/0
  #|cmovge r15d, edx|440f4dfa|CMOV32rr:%R15D,%R15D,%EDX,13|rdx=8c3153b05f4b723c r15=2b f=c6|f=c4/0
  #|cmovge r13, rcx|4c0f4de9|CMOV64rr:%R13,%R13,%RCX,13|rcx=aba6930fc219b68c r13=de3a0b9be457d1df f=13|r13=aba6930fc219b68c f=11/0
  #|cmovge r13d, dword ptr [rsi + rbx*4 + 0x8]|440f4d6c9e08|CMOV32rm:%R13D,%R13D,%RSI,4,%RBX,8,%,13|rbx=d r9=0 r13=e541320c314b6628 f=2 m100bc=5fe8fcd56617046afa80345e6f84b12d|r13=d5fce85f f=0/0
  #|cmovge r13d, dword ptr [rsi + rbx*4 + 0x8]|440f4d6c9e08|CMOV32rm:%R13D,%R13D,%RSI,4,%RBX,8,%,13|rbx=e r9=3 r13=1ea96e6dfe78aee2 f=c56 m100c0=efeaf3c999a5e0f29941644ec2a040e6|r13=fe78aee2 f=c54/0
  #|setge r14b|410f9dc6|SETCCr:%R14B,13|r14=ffffffffffffffff f=53|r14=ffffffffffffff01 f=51/0
  #|setge r14b|410f9dc6|SETCCr:%R14B,13|r14=56808f4056e4c05 f=886|r14=56808f4056e4c01 f=884/0
  #|setge r14b|410f9dc6|SETCCr:%R14B,13|r14=e f=843|r14=0 f=841/0
  #|setge byte ptr [rdi + 0x10]|0f9d4710|SETCCm:%RDI,1,%,16,%,13|rbx=2 r9=f f=416 m10110=32d866c9c6e47d245574a0143b2f565c|f=414/0 m10110=01
  #|cmovle r9w, r10w|66450f4eca|CMOV16rr:%R9W,%R9W,%R10W,14|r9=8000000000000000 r10=f85c81bf36ca5685 f=453|r9=8000000000005685 f=451/0
  #|cmovle r11d, r10d|450f4eda|CMOV32rr:%R11D,%R11D,%R10D,14|r10=7a30b97280330777 r11=478175f53ba105c6 f=7|r11=3ba105c6 f=5/0
  #|cmovle r11d, r10d|450f4eda|CMOV32rr:%R11D,%R11D,%R10D,14|r10=7db0ddc9b0ff7fff r11=7fffffffffffffff f=c6|r11=b0ff7fff f=c4/0
  #|cmovle r11d, r10d|450f4eda|CMOV32rr:%R11D,%R11D,%R10D,14|r10=fe3c31cb41e31def r11=7a f=13|f=11/0
  #|cmovle rcx, rax|480f4ec8|CMOV64rr:%RCX,%RCX,%RAX,14|rax=8000 rcx=f77a65254832a74a f=c87|f=c85/0
  #|cmovle eax, dword ptr [rdi + r9*2 - 0x4]|420f4e444ffc|CMOV32rm:%EAX,%EAX,%RDI,2,%R9,-4,%,14|rax=fffffffffffffffe rbx=0 r9=d f=82 m10116=0c8c6b4a20499f6d958061a0308de85c|rax=4a6b8c0c f=80/0
  #|cmovle eax, dword ptr [rdi + r9*2 - 0x4]|420f4e444ffc|CMOV32rm:%EAX,%EAX,%RDI,2,%R9,-4,%,14|rax=7f rbx=c r9=2 f=883 m10100=65cb5e2604f5445a4ca3afd07cb87712|f=881/0
  #|setle r15b|410f9ec7|SETCCr:%R15B,14|r15=24eeeee590480a7b f=43|r15=24eeeee590480a01 f=41/0
  #|setle r15b|410f9ec7|SETCCr:%R15B,14|r15=5af2bb3837da0d0b f=c7|r15=5af2bb3837da0d01 f=c5/0
  #|setle r15b|410f9ec7|SETCCr:%R15B,14|r15=4714cf0b3a56427a f=c2|r15=4714cf0b3a564201 f=c0/0
  #|setle byte ptr [rdi + r9*2 - 0x4]|420f9e444ffc|SETCCm:%RDI,2,%R9,-4,%,14|rbx=b r9=6 f=c07 m10108=8c4f82ef974de74227f3483ff1ffc463|f=c05/0 m10108=01
  #|cmovg r9w, bx|66440f4fcb|CMOV16rr:%R9W,%R9W,%BX,15|rbx=938eef0a159ba165 r9=8ab f=c13|f=c11/0
  #|cmovg ecx, r9d|410f4fc9|CMOV32rr:%ECX,%ECX,%R9D,15|rcx=ebfd84d8d931d3ed r9=fffffffffffffffe f=2|rcx=fffffffe f=0/0
  #|cmovg ecx, r9d|410f4fc9|CMOV32rr:%ECX,%ECX,%R9D,15|rcx=782d555ed3456878 r9=7c2f02109a7436f2 f=17|rcx=9a7436f2 f=15/0
  #|cmovg ecx, r9d|410f4fc9|CMOV32rr:%ECX,%ECX,%R9D,15|rcx=35150ff7403cf59b r9=ffffffff f=d7|rcx=403cf59b f=d5/0
  #|cmovg r14, r9|4d0f4ff1|CMOV64rr:%R14,%R14,%R9,15|r9=b0 r14=bb1d9f17ac57c1c1 f=4c6|f=4c4/0
  #|cmovg r10d, dword ptr [rsi]|440f4f16|CMOV32rm:%R10D,%R10D,%RSI,1,%,0,%,15|rbx=5 r9=1 r10=f94b7d375d02231e f=857 m10080=579406a2acc23ed7c6729e2747700534|r10=5d02231e f=855/0
  #|cmovg r10d, dword ptr [rsi]|440f4f16|CMOV32rm:%R10D,%R10D,%RSI,1,%,0,%,15|rbx=2 r9=d r10=7652f997fffffff f=93 m10080=c83f7c1840400d16565e8f786a8b1472|r10=7fffffff f=91/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|rcx=5718 f=c06|rcx=5700 f=c04/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|rcx=8b354c3c8eafe5f7 f=8d7|rcx=8b354c3c8eafe500 f=8d5/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|rcx=a4eadb78ced0373c f=c93|rcx=a4eadb78ced03701 f=c91/0
  #|setg byte ptr [rdi + 0x10]|0f9f4710|SETCCm:%RDI,1,%,16,%,15|rbx=b r9=b f=13 m10110=4ee7865200e84b513c74691a6013819c|f=11/0 m10110=01
  #|xchg r15b, r9b|4586f9|XCHG8rr:%R15B,%R9B,%R15B,%R9B|rax=e25e2f109a3490d8 rcx=9f57ae5efef951ab rdx=e0b62cb5a50717fd r9=75b46a20f63e395 r15=7f f=4c6|r9=75b46a20f63e37f r15=95 f=4c4/0
  #|xchg r15b, r9b|4586f9|XCHG8rr:%R15B,%R9B,%R15B,%R9B|rax=eedf6b65a38f787f rcx=d r9=b11a9fb15bc7737b r15=ffff f=8c7|r9=b11a9fb15bc773ff r15=ff7b f=8c5/0
  #|xchg byte ptr [rsp + 0x8], r9b|44864c2408|XCHG8rm:%R9B,%R9B,%RSP,1,%,8,%|rax=41fb rcx=f3cc78fdb4c26370 rbx=f r9=6 f=93 m20108=1d9d6efea734ecbff5b5954666730983|r9=1d f=91/0 m20108=06
  #|xchg byte ptr [rsp + 0x8], r9b|44864c2408|XCHG8rm:%R9B,%R9B,%RSP,1,%,8,%|rax=2ff591b80470a329 rcx=55645f04a4306811 rbx=5 r9=f f=c07 m20108=6b0f04d1fe969b69532b9fe9ca9b535a|r9=6b f=c05/0 m20108=0f
  #|cmpxchg r15b, r13b|450fb0ef|CMPXCHG8rr:%R15B,%R13B|rax=bdd5ae12a63b2e6d r13=35b660b122e300a7 r15=ac7e4d30dcd56087 f=807|rax=bdd5ae12a63b2e87 f=881/0
  #|cmpxchg r15b, r13b|450fb0ef|CMPXCHG8rr:%R15B,%R13B|rax=2 rcx=8 rdx=d766a0d47805cde9 r13=89242abb3bdb0bfa r15=7e20b56d607b8b74 f=cd3|rax=74 f=495/0
  #|cmpxchg r15b, r13b|450fb0ef|CMPXCHG8rr:%R15B,%R13B|rcx=d80799a9dbf338fb r13=9676b8d8274ff563 r15=81a8aa4d3d1ff992 f=883|rax=5b791f3dd3f19792 f=0/0
  #|cmpxchg r15b, r13b|450fb0ef|CMPXCHG8rr:%R15B,%R13B|rax=95c6967dac95210a r13=f4a5446181e76f7e r15=7f f=883|rax=95c6967dac95217f f=95/0
  #|cmpxchg byte ptr [rsp + 0x8], r13b|440fb06c2408|CMPXCHG8rm:%RSP,1,%,8,%,%R13B|rax=fd10af294f1284 rdx=84d9e548b1e8221f rbx=7 r9=3 r13=aa f=c93 m20108=848ec670ba4e1637a7ef023f39b45c81|f=444/0 m20108=aa
  #|cmpxchg byte ptr [rsp + 0x8], r13b|440fb06c2408|CMPXCHG8rm:%RSP,1,%,8,%,%R13B|rax=fffffffffffffffe rcx=a5b08edd6b2bf8ee rdx=2465 rbx=9 r9=7 r13=94f08121aa6a4cc9 f=812 m20108=fe9dcf5e57d405135401ab5d1d01d5f2|f=44/0 m20108=c9
  #|cmpxchg byte ptr [rsp + 0x8], r13b|440fb06c2408|CMPXCHG8rm:%RSP,1,%,8,%,%R13B|rax=7 rdx=c53de66d058856a5 rbx=6 r9=3 r13=d9439ace995a75bc f=846 m20108=0720c3febf49870b6e7e780ded487692|f=44/0 m20108=bc
  #|cmpxchg byte ptr [rsp + 0x8], r13b|440fb06c2408|CMPXCHG8rm:%RSP,1,%,8,%,%R13B|rax=e55403105498a3b2 rcx=32725e9f11048100 rdx=4cf8142eef98a142 rbx=3 r9=0 r13=13992abfe6cc46e4 f=93 m20108=4fa408265e8dadc215321967bed24c19|rax=e55403105498a34f f=814/0
  #|xadd r15b, r13b|450fc0ef|XADD8rr:%R15B,%R13B,%R15B,%R13B|rcx=708494e0b4780c68 rdx=ddb4b017886f8a3f r13=8000 r15=175044336e24b8f3 f=883|r13=80f3 f=84/0
  #|xadd r15b, r13b|450fc0ef|XADD8rr:%R15B,%R13B,%R15B,%R13B|rcx=ecd129e7679fc5e rdx=6 r13=879a34920a100cd2 r15=4a08c78452057395 f=cd7|r13=879a34920a100c95 r15=4a08c78452057367 f=c01/0
  #|xadd r15b, r13b|450fc0ef|XADD8rr:%R15B,%R13B,%R15B,%R13B|r13=d5eeae9a28fe93ed r15=6c8c196ac87146b7 f=816|r13=d5eeae9a28fe93b7 r15=6c8c196ac87146a4 f=91/0
  #|xadd byte ptr [rsp + 0x8], r13b|440fc06c2408|XADD8rm:%R13B,%R13B,%RSP,1,%,8,%|rax=5ef4fef02b60a6a1 rcx=15ee238bf5b2708c rdx=d rbx=1 r9=f r13=563a488196377512 f=812 m20108=cf2b5d3f86194cceaaae077e62a2b965|r13=563a4881963775cf f=94/0 m20108=e1
  #|xadd byte ptr [rsp + 0x8], r13b|440fc06c2408|XADD8rm:%R13B,%R13B,%RSP,1,%,8,%|rax=72 rdx=fc945abe1a9543f8 rbx=9 r9=d r13=ceb93ae388706aca f=cd3 m20108=a38ac7d15dcf1b57aae5e9b3d28e996c|r13=ceb93ae388706aa3 f=c01/0 m20108=6d
  #|xadd byte ptr [rsp + 0x8], r13b|440fc06c2408|XADD8rm:%R13B,%R13B,%RSP,1,%,8,%|rax=fffffffffffffffe rcx=5403ea838ea27e80 rdx=33d318f850f7447d rbx=7 r9=5 r13=5db0e37c32c7713a f=52 m20108=cc2eecb8c14cd3946b56184239a5de95|r13=5db0e37c32c771cc f=15/0 m20108=06
  #|xchg r9w, r13w|664587cd|XCHG16rr:%R9W,%R13W,%R9W,%R13W|rcx=56c850dec0a8fe54 rdx=badb9e72ffffffff r9=e4fd418468a2f9d8 r13=434ae9cab545a85f f=6|r9=e4fd418468a2a85f r13=434ae9cab545f9d8 f=4/0
  #|xchg r9w, r13w|664587cd|XCHG16rr:%R9W,%R13W,%R9W,%R13W|rax=7111cfe388488a0b rcx=e0635907c9c4d980 rdx=9fd49a70896f84c6 r9=8238f3bdbb4fc74 r13=2ec156bb629c5328 f=812|r9=8238f3bdbb45328 r13=2ec156bb629cfc74 f=810/0
  #|xchg word ptr [rsi], r13w|6644872e|XCHG16rm:%R13W,%R13W,%RSI,1,%,0,%|rax=69efea57a2126fe1 rbx=d r9=2 r13=912e108841e948d9 f=42 m10080=73ed7379c6d413545d3f5e5b504c3f4f|r13=912e108841e9ed73 f=40/0 m10080=d948
  #|xchg word ptr [rsi], r13w|6644872e|XCHG16rm:%R13W,%R13W,%RSI,1,%,0,%|rax=0 rcx=f0b0722b7907c75c rdx=5d rbx=6 r9=3 r13=9696d1189a7c7e81 f=807 m10080=cf9c1f46cc231f1c7069ab94bff7fc64|r13=9696d1189a7c9ccf f=805/0 m10080=817e
  #|xchg ax, bx|6693|XCHG16ar:%BX,%BX|rax=c80b1d1c75cadb05 rcx=8eb7 rdx=ba65d9883e04fb53 rbx=475b1a1dc53c56dd f=403|rax=c80b1d1c75ca56dd rbx=475b1a1dc53cdb05 f=401/0
  #|cmpxchg r14w, r9w|66450fb1ce|CMPXCHG16rr:%R14W,%R9W|rax=bc0c7039784b000a rcx=eedeefce023b8306 rdx=7fffffff r9=7fffffff r14=a f=883|r14=ffff f=44/0
  #|cmpxchg r14w, r9w|66450fb1ce|CMPXCHG16rr:%R14W,%R9W|rax=0 rcx=7fffffffffffffff rdx=52904bf966bf436e r9=8890ecd45e927aad r14=5312c13953d2c849 f=6|rax=c849 f=15/0
  #|cmpxchg r14w, r9w|66450fb1ce|CMPXCHG16rr:%R14W,%R9W|rax=54eeb7ef36ed662b rcx=fa3ce6e6fdd90df9 r9=80000000 r14=5a6bd6011b1cc7e6 f=d2|rax=54eeb7ef36edc7e6 f=881/0
  #|cmpxchg r14w, r9w|66450fb1ce|CMPXCHG16rr:%R14W,%R9W|rax=7a2abfbdbb4fc043 rcx=76 rdx=cd3fedb1a87a4f49 r9=4358c6e949f326e0 r14=c043 f=2|r14=26e0 f=44/0
  #|cmpxchg word ptr [rsi], r9w|66440fb10e|CMPXCHG16rm:%RSI,1,%,0,%,%R9W|rax=ffffffffffffffff rdx=cefa1daffe8d0791 rbx=8 r9=0 f=817 m10080=45bb88fc621b00781e18c88cfb9ac35f|rax=ffffffffffffbb45 f=0/0
  #|cmpxchg word ptr [rsi], r9w|66440fb10e|CMPXCHG16rm:%RSI,1,%,0,%,%R9W|rax=7f rcx=fffffffffffffffe rdx=3a059a3fb1bed2c3 rbx=3 r9=6 f=803 m10080=7f00094c1707f5fe5e60b48393051cb0|f=44/0 m10080=06
  #|cmpxchg word ptr [rsi], r9w|66440fb10e|CMPXCHG16rm:%RSI,1,%,0,%,%R9W|rax=ffffffffffffffff rdx=a8dc59988224afd4 rbx=e r9=b f=8d6 m10080=ffffccaea9aae1675d4992869539a8aa|f=44/0 m10080=0b00
  #|cmpxchg word ptr [rsi], r9w|66440fb10e|CMPXCHG16rm:%RSI,1,%,0,%,%R9W|rax=7f rdx=1029086a347a152c rbx=e r9=9 f=d7 m10080=6040871269cc92a77ac723b0a161b23b|rax=4060 f=81/0
  #|xadd r14w, r9w|66450fc1ce|XADD16rr:%R14W,%R9W,%R14W,%R9W|rax=29ad93f2c1d03d9f rcx=4571f0176a8be3d4 r9=7f r14=e2e28f0c80000000 f=457|r9=0 r14=e2e28f0c8000007f f=400/0
  #|xadd r14w, r9w|66450fc1ce|XADD16rr:%R14W,%R9W,%R14W,%R9W|rax=29 rcx=dc6a6ed33bb8cec1 rdx=1 r9=63a6 r14=f1b2 f=c12|r9=f1b2 r14=5558 f=401/0
  #|xadd r14w, r9w|66450fc1ce|XADD16rr:%R14W,%R9W,%R14W,%R9W|rax=fffffffffffffffe rcx=b20d93290cecfaa3 rdx=c1ee15aea16c6cf r9=d1c919f2140720c6 r14=ba6116a1ca7a8f88 f=887|r9=d1c919f214078f88 r14=ba6116a1ca7ab04e f=84/0
  #|xadd word ptr [rsi], r9w|66440fc10e|XADD16rm:%R9W,%R9W,%RSI,1,%,0,%|rax=ffff rdx=ff rbx=a r9=8 f=896 m10080=5a386ea49535ad5d01d1eb59b085d897|r9=385a f=10/0 m10080=62
  #|xadd word ptr [rsi], r9w|66440fc10e|XADD16rm:%R9W,%R9W,%RSI,1,%,0,%|rax=a712a5bcb3275736 rcx=39058917b757a5fa rbx=1 r9=1 f=8d7 m10080=a9f99ee7db881669463c4c748fe3a690|r9=f9a9 f=84/0 m10080=aa
  #|xadd word ptr [rsi], r9w|66440fc10e|XADD16rm:%R9W,%R9W,%RSI,1,%,0,%|rax=4 rcx=7c40ea9417878bf rdx=51f330986f034155 rbx=d r9=7 f=4c7 m10080=6062f37182ee9aa0d0dd5a58e64c573c|r9=6260 f=400/0 m10080=67
  #|xchg r15d, eax|4197|XCHG32ar:%R15D,%R15D|rax=df rcx=7fff r15=4e8db39ef15c0e82 f=c82|rax=f15c0e82 r15=df f=c80/0
  #|xchg r15d, eax|4197|XCHG32ar:%R15D,%R15D|rax=a4c12f80c949fc8c r15=550336b7d5dee714 f=7|rax=d5dee714 r15=c949fc8c f=5/0
  #|xchg dword ptr [rdi + r9*2 - 0x4], eax|4287444ffc|XCHG32rm:%EAX,%EAX,%RDI,2,%R9,-4,%|rax=c112cebd2e967e12 rbx=9 r9=c f=482 m10114=e85b782f8cb28b26c9081507145b8d00|rax=2f785be8 f=480/0 m10114=127e962e
  #|xchg dword ptr [rdi + r9*2 - 0x4], eax|4287444ffc|XCHG32rm:%EAX,%EAX,%RDI,2,%R9,-4,%|rax=f4da474458359688 rcx=6817c2f45a15b304 rbx=e r9=b f=813 m10112=570db682797a1d1c9821cb77c061b09a|rax=82b60d57 f=811/0 m10112=88963558
  #|xchg eax, ebx|93|XCHG32ar:%EBX,%EBX|rax=d1d77ca333450e80 rcx=48e8a3816bd1c361 rdx=811b925e34e58c29 rbx=ffff f=8d7|rax=ffff rbx=33450e80 f=8d5/0
  #|cmpxchg r15d, r8d|450fb1c7|CMPXCHG32rr:%R15D,%R8D|rax=39257fff rcx=cc9c3fdece4c8d0e r8=8000 r15=a351785b39257fff f=96|r15=8000 f=44/0
  #|cmpxchg r15d, r8d|450fb1c7|CMPXCHG32rr:%R15D,%R8D|rax=43be383d rcx=d24461397a262d00 rdx=635287986f777f6d r8=e9d8a8dcbc19b377 r15=2de74eea43be383d f=43|r15=bc19b377 f=44/0
  #|cmpxchg r15d, r8d|450fb1c7|CMPXCHG32rr:%R15D,%R8D|rax=6af4467f00000000 rdx=b6eade1578a7794f r8=b6ff855c19bae179 r15=8000000000000000 f=92|r15=19bae179 f=44/0
  #|cmpxchg r15d, r8d|450fb1c7|CMPXCHG32rr:%R15D,%R8D|rax=b45e5660eb28dfe3 rcx=7fb77e4a46398136 rdx=e r8=fffffffffffffffe r15=fee2b5823ad6e178 f=846|rax=3ad6e178 r15=3ad6e178 f=90/0
  #|cmpxchg dword ptr [rdi + r9*2 - 0x4], r8d|460fb1444ffc|CMPXCHG32rm:%RDI,2,%R9,-4,%,%R8D|rax=76b48f4d168f114c rcx=6d21fb0922e4b370 rbx=7 r8=ede4d30d95fe1843 r9=f f=47 m1011a=4c118f1680483a487e88d64d797c6a54|f=44/0 m1011a=4318fe95
  #|cmpxchg dword ptr [rdi + r9*2 - 0x4], r8d|460fb1444ffc|CMPXCHG32rm:%RDI,2,%R9,-4,%,%R8D|rcx=8000000000000000 rbx=0 r8=5175760ec77e4b46 r9=5 f=3 m10106=00000000848d6d3494b3b20a876ce087|rax=0 f=80/0
  #|cmpxchg dword ptr [rdi + r9*2 - 0x4], r8d|460fb1444ffc|CMPXCHG32rm:%RDI,2,%R9,-4,%,%R8D|rax=fb12 rcx=a44f503b850e1298 rdx=2eb2cad43189da3d rbx=f r8=32d1db127980dbba r9=8 f=52 m1010c=e581030fb03c81690b8e0fcebebcbb97|rax=f0381e5 f=95/0
  #|cmpxchg dword ptr [rdi + r9*2 - 0x4], r8d|460fb1444ffc|CMPXCHG32rm:%RDI,2,%R9,-4,%,%R8D|rax=af060b7a08bd3e46 rcx=e rdx=6a438221baa0db7f rbx=7 r8=67af8a99603576c7 r9=5 f=13 m10106=e7af02f0eef0afe75bc77b61c9326ae6|rax=f002afe7 f=15/0
  #|xadd r15d, r8d|450fc1c7|XADD32rr:%R15D,%R8D,%R15D,%R8D|rax=d70e2194952fa258 r8=ffff r15=fffffffffffffffe f=c7|r8=fffffffe r15=fffd f=11/0
  #|xadd r15d, r8d|450fc1c7|XADD32rr:%R15D,%R8D,%R15D,%R8D|rax=64683048130195a5 rdx=9e4fce294843b393 r8=406aec3c82c7f880 r15=3a442b5b18f97fff f=cc6|r8=18f97fff r15=9bc1787f f=480/0
  #|xadd r15d, r8d|450fc1c7|XADD32rr:%R15D,%R8D,%R15D,%R8D|rax=9dbe96c875e19aa9 rcx=77718028ed6db39d rdx=ffff r8=ec6e18c22227ca6f r15=111a8bad6a489aee f=8c3|r8=6a489aee r15=8c70655d f=890/0
  #|xadd dword ptr [rdi + r9*2 - 0x4], r8d|460fc1444ffc|XADD32rm:%R8D,%R8D,%RDI,2,%R9,-4,%|rax=c146e89b8c58e679 rdx=7d rbx=a r8=d r9=4 f=c2 m10104=03b96c96d50f603d312154be0e9e6016|r8=966cb903 f=90/0 m10104=10
  #|xadd dword ptr [rdi + r9*2 - 0x4], r8d|460fc1444ffc|XADD32rm:%R8D,%R8D,%RDI,2,%R9,-4,%|rax=ed9f rcx=ca49469a15a74af2 rdx=d86e2c87a7bd1786 rbx=2 r8=538149214209fc7f r9=e f=c6 m10118=d6c6866b6b145050aa6fabe4dc0b4ef7|r8=6b86c6d6 f=894/0 m10118=55c390ad
  #|xadd dword ptr [rdi + r9*2 - 0x4], r8d|460fc1444ffc|XADD32rm:%R8D,%R8D,%RDI,2,%R9,-4,%|rax=d015fae355b47621 rcx=f54418bc88db381b rdx=15c28f2ae8e92a12 rbx=2 r8=f02d718012c238ff r9=4 f=c6 m10104=1f98875bbc765f852ce9f202a8de5273|r8=5b87981f f=14/0 m10104=1ed1496e
  #|xchg rax, r12|4994|XCHG64ar:%R12,%R12|rax=3dc16ec3411af8d3 rcx=f98ae522a56fe36a rdx=e7b6340fa1be3d95 r12=6a49b94ba68efa74 f=47|rax=6a49b94ba68efa74 r12=3dc16ec3411af8d3 f=45/0
  #|xchg rax, r12|4994|XCHG64ar:%R12,%R12|rax=a2a65745567ff73a rcx=eb47 rdx=4c093b385a183189 r12=37e94d4fb506c261 f=452|rax=37e94d4fb506c261 r12=a2a65745567ff73a f=450/0
  #|xchg qword ptr [rdi + r9*2 - 0x4], r12|4e87644ffc|XCHG64rm:%R12,%R12,%RDI,2,%R9,-4,%|rax=645828288864a267 rcx=7fffffffffffffff rdx=4a rbx=6 r9=5 r12=b f=c47 m10106=eb24940759e4494b9e1e75126a9a8a0b|r12=4b49e459079424eb f=c45/0 m10106=0b00000000000000
  #|xchg qword ptr [rdi + r9*2 - 0x4], r12|4e87644ffc|XCHG64rm:%R12,%R12,%RDI,2,%R9,-4,%|rax=cdb3 rcx=fffffffffffffffe rbx=e r9=e r12=4 f=812 m10118=3c5c54311581902e7e8d60bf17de107a|r12=2e90811531545c3c f=810/0 m10118=0400000000000000
  #|xchg rax, rbx|4893|XCHG64ar:%RBX,%RBX|rax=30a1a35dfb6c057f rcx=11d69040c3fac54e rdx=8b6420276d07e904 rbx=a5c4b279df40b15c f=817|rax=a5c4b279df40b15c rbx=30a1a35dfb6c057f f=815/0
  #|cmpxchg r15, r11|4d0fb1df|CMPXCHG64rr:%R15,%R11|rcx=f6b1d42c678f4715 rdx=2f8b71135b995964 r11=1562 r15=36799cab20e471f9 f=452|rax=36799cab20e471f9 f=410/0
  #|cmpxchg r15, r11|4d0fb1df|CMPXCHG64rr:%R15,%R11|rax=9affacbf9a2d7b5a rcx=172f r11=a06e330379008155 r15=749bb8069dcf4a7d f=16|rax=749bb8069dcf4a7d f=814/0
  #|cmpxchg r15, r11|4d0fb1df|CMPXCHG64rr:%R15,%R11|rax=aad138c905e769dd rdx=9e2bbe8d70737da1 r11=26ba48bebe48bb06 r15=aad138c905e769dd f=802|r15=26ba48bebe48bb06 f=44/0
  #|cmpxchg r15, r11|4d0fb1df|CMPXCHG64rr:%R15,%R11|rax=4886 r11=fffffffffffffffe r15=4886 f=456|r15=fffffffffffffffe f=444/0
  #|cmpxchg qword ptr [rdi + r9*2 - 0x4], r11|4e0fb15c4ffc|CMPXCHG64rm:%RDI,2,%R9,-4,%,%R11|rax=9796 rcx=d2dbb55ceb3c09e9 rdx=c75819a0db21a528 rbx=b r9=2 r11=ad1a21eecec5064a f=8d7 m10100=96970000000000007ca794cfdb02719c|f=44/0 m10100=4a06c5ceee211aad
  #|cmpxchg qword ptr [rdi + r9*2 - 0x4], r11|4e0fb15c4ffc|CMPXCHG64rm:%RDI,2,%R9,-4,%,%R11|rax=8b0a3eb7a43dcc51 rcx=8 rdx=1a52617819aa43fb rbx=1 r9=1 r11=7b3315a34d6fffb9 f=46 m100fe=51cc3da4b73e0a8b289439617adc54de|f=44/0 m100fe=b9ff6f4da315337b
  #|cmpxchg qword ptr [rdi + r9*2 - 0x4], r11|4e0fb15c4ffc|CMPXCHG64rm:%RDI,2,%R9,-4,%,%R11|rax=7e rcx=dd0a83df1a6c23a7 rbx=2 r9=7 r11=5 f=807 m1010a=64be3985a958de7443fddcdbede1a1e9|rax=74de58a98539be64 f=81/0
  #|cmpxchg qword ptr [rdi + r9*2 - 0x4], r11|4e0fb15c4ffc|CMPXCHG64rm:%RDI,2,%R9,-4,%,%R11|rax=8cd16ac23c89d74b rcx=8000000000000000 rbx=e r9=9 r11=52fdefc733723b55 f=47 m1010e=4bd7893cc26ad18c0362cd2db04afc82|f=44/0 m1010e=553b7233c7effd52
  #|xadd r15, r11|4d0fc1df|XADD64rr:%R15,%R11,%R15,%R11|rax=4a5af9c228f13edb rdx=8000000000000000 r11=8bae8dbb6b1c89a5 r15=f14faad772117eff f=496|r11=f14faad772117eff r15=7cfe3892dd2e08a4 f=c11/0
  #|xadd r15, r11|4d0fc1df|XADD64rr:%R15,%R11,%R15,%R11|rcx=2 rdx=1 r11=8aa8b56dfb8203d2 r15=48836da480c62203 f=c7|r11=48836da480c62203 r15=d32c23127c4825d5 f=80/0
  #|xadd r15, r11|4d0fc1df|XADD64rr:%R15,%R11,%R15,%R11|rcx=800181d439d12d95 rdx=dfd201e3d1371a4 r11=ffff r15=7410cd5186d66a9b f=c6|r11=7410cd5186d66a9b r15=7410cd5186d76a9a f=14/0
  #|xadd qword ptr [rdi + r9*2 - 0x4], r11|4e0fc15c4ffc|XADD64rm:%R11,%R11,%RDI,2,%R9,-4,%|rbx=3 r9=5 r11=72e1c07b97450bd0 f=443 m10106=f84a456781705b6165754cf9080dcf16|r11=615b708167454af8 f=c80/0 m10106=c8568afefc303dd4
  #|xadd qword ptr [rdi + r9*2 - 0x4], r11|4e0fc15c4ffc|XADD64rm:%R11,%R11,%RDI,2,%R9,-4,%|rdx=b322703e046bf055 rbx=5 r9=b r11=dd f=82 m10112=50dd46f3947a1124b50bec6550966276|r11=24117a94f346dd50 f=4/0 m10112=2dde
  #|xadd qword ptr [rdi + r9*2 - 0x4], r11|4e0fc15c4ffc|XADD64rm:%R11,%R11,%RDI,2,%R9,-4,%|rax=ac5c43b03b29930 rcx=a17e4ea456c55216 rdx=7ef6edff16a497e0 rbx=c r9=f r11=8988 f=cd2 m1011a=c7a0b6a9a17a4114cf53b162b58b69e4|r11=14417aa1a9b6a0c7 f=400/0 m1011a=4f2ab7
  #|xchg eax, eax (87 c0)|87c0|XCHG32rr:%EAX,%EAX,%EAX,%EAX|rax=aa02360fddf76c24 rcx=338e976af1a63876 f=8d3|rax=ddf76c24 f=8d1/0
  #|xchg eax, eax (87 c0)|87c0|XCHG32rr:%EAX,%EAX,%EAX,%EAX|rax=7804 rcx=ffffffff rdx=9e9c0bb65e81ce85 f=13|f=11/0
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=e5555cedc45811a8 rcx=d04bab92e8cac367 rdx=4b20c1ddf66c6d5b rbx=730a5c2221ec5567 f=c57 m10080=a81158c45b6d6cf6|f=c55/0 m10080=6755ec2167c3cae8
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=b8e149a0817ac97b rcx=2140f459efa72bdc rdx=57b3e89165569fc rbx=ad7f00f86a7eb567 f=887 m10080=1807e49661c67676|rax=96e40718 rdx=7676c661 f=885/0
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=91f99bbce976e4d1 rcx=e2f4a23ba6acad90 rdx=9e69bc4c277a2753 rbx=676f88f6ebb84e7 f=cc2 m10080=b5d1fbcfbf3ab5d3|rax=cffbd1b5 rdx=d3b53abf f=c80/0
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=66b68e3b95a8c98e rcx=8ff1c36c830f635a rdx=a9ed4332e29eadb9 rbx=2fc5269824570d1d f=c87 m10080=00099f94b144aa9c|rax=949f0900 rdx=9caa44b1 f=c85/0
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=ed9b83dcce173862 rcx=210cb1f2010a4fe2 rdx=e30e2ff20d6c910a rbx=2ffab3f7406b859f f=857 m10080=623817ce0a916c0d|f=855/0 m10080=9f856b40e24f0a01
  #|cmpxchg8b qword ptr [rsi]|0fc70e|CMPXCHG8B:%RSI,1,%,0,%|rax=2a9cb9d32f7926e rcx=506d8ce09c776b0a rdx=d884d4f65becff3b rbx=fb6a65751dd4775b f=42 m10080=cb67df68f773abf3|rax=68df67cb rdx=f3ab73f7 f=0/0
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=3adfa941b8e8b042 rcx=9b139e3bd253b19e rdx=8b4685d361d396f5 rbx=c2518f6946a15db2 f=6 m10080=4d7a9ef2ffe13df71cf343ae22246c8d|rax=f73de1fff29e7a4d rdx=8d6c2422ae43f31c f=4/0
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=3fc01a1932f32a54 rcx=be5450419d82de2b rdx=c6698b4d3bac82f6 rbx=2782f171fc383bcd f=6 m10080=542af332191ac03ff682ac3b4d8b69c6|f=44/0 m10080=cd3b38fc71f182272bde829d415054be
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=c4c944c38c678999 rcx=c2bba03c6324dab7 rdx=6798f3377166c12b rbx=a86ce4950fee4a28 f=882 m10080=9989678cc344c9c42bc1667137f39867|f=8c0/0 m10080=284aee0f95e46ca8b7da24633ca0bbc2
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=8d57dc8a39c66e31 rcx=1890170f603c2980 rdx=d8b81a9220315265 rbx=5448072ce12b7c1c f=c2 m10080=316ec6398adc578d65523120921ab8d8|f=c0/0 m10080=1c7c2be12c07485480293c600f179018
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=678388d25bd415d2 rcx=f41101c78c79ca43 rdx=21c103d35f641a54 rbx=4a1816d89bb70bcb f=846 m10080=d215d45bd2888367541a645fd303c121|f=844/0 m10080=cb0bb79bd816184a43ca798cc70111f4
  #|cmpxchg16b xmmword ptr [rsi]|480fc70e|CMPXCHG16B:%RSI,1,%,0,%|rax=f83f588fbb385240 rcx=3d568f1cc2c8ee9b rdx=faeae1a33cf8a7e4 rbx=3fa3f955dbb85555 f=457 m10080=1cbe8338265ec87b624dc602ae8b97c1|rax=7bc85e263883be1c rdx=c1978bae02c64d62 f=415/0
  #|lea rax, [rbx + rcx*4 + 0x10]|488d448b10|LEA64r:%RAX,%RBX,4,%RCX,16,%|rax=f941ecd69f976555 rcx=8ebd81e7fa12046b rbx=0 f=92|rax=3af6079fe84811bc f=90/0
  #|lea rax, [rbx + rcx*4 + 0x10]|488d448b10|LEA64r:%RAX,%RBX,4,%RCX,16,%|rax=f739bfde6fc6f51e rcx=d6e706d38fa944d0 rbx=6c513bac80000000 f=c57|rax=c7ed56fabea51350 f=c55/0
  #|lea eax, [rbx + rcx*8 - 0x1]|8d44cbff|LEA64_32r:%EAX,%RBX,8,%RCX,-1,%|rax=8000000000000000 rcx=22fcb93f81add0c8 rbx=c f=852|rax=d6e864b f=850/0
  #|lea eax, [rbx + rcx*8 - 0x1]|8d44cbff|LEA64_32r:%EAX,%RBX,8,%RCX,-1,%|rax=8b0c357a6ff27f0c rcx=811f2dbe2ba9de95 rbx=7d7d19607fffffff f=6|rax=dd4ef4a6 f=4/0
  #|lea ax, [rbx + rcx]|668d040b|LEA16r:%AX,%RBX,1,%RCX,0,%|rax=f4d6963c9552a114 rcx=1d0b42d6e6fa437a rbx=8af940440e85d548 f=816|rax=f4d6963c955218c2 f=814/0
  #|lea ax, [rbx + rcx]|668d040b|LEA16r:%AX,%RBX,1,%RCX,0,%|rax=b393832cdd28000 rcx=7b4b21d8e640403f rbx=ee54a203e8722cff f=846|rax=b393832cdd26d3e f=844/0
  #|lea r10, [r11 + r12*2 + 0x7fffffff]|4f8d9463ffffff7f|LEA64r:%R10,%R11,2,%R12,2147483647,%|r10=f2c60eb0903793c9 r11=3d13 r12=fa9905651b77cfb4 f=52|r10=f5320acab6efdc7a f=50/0
  #|lea r10, [r11 + r12*2 + 0x7fffffff]|4f8d9463ffffff7f|LEA64r:%R10,%R11,2,%R12,2147483647,%|r10=66e7c7fd286eb19f r11=ef6a482c3c6d84f2 r12=f1be2be32d25a10d f=812|r10=d2e69ff316b8c70b f=810/0
  #|lea rax, [rip + 0x100]|488d0500010000|LEA64r:%RAX,%RIP,1,%,256,%|rax=ffffffffffffffff f=87|rax=400107 f=85/0
  #|lea rax, [rip + 0x100]|488d0500010000|LEA64r:%RAX,%RIP,1,%,256,%|rax=80 f=d6|rax=400107 f=d4/0
  #|lea eax, [ebx + ecx]|678d040b|LEA64_32r:%EAX,%EBX,1,%ECX,0,%|rax=6e547448cc39e26a rcx=eddd2a82aded1962 rbx=f89ae6de16363d8f f=4d6|rax=c42356f1 f=4d4/0
  #|lea eax, [ebx + ecx]|678d040b|LEA64_32r:%EAX,%EBX,1,%ECX,0,%|rax=80000000 rcx=8000000000000000 rbx=e47b9919159e3b8f f=812|rax=159e3b8f f=810/0
  #|lea rcx, [rcx + rcx*2]|488d0c49|LEA64r:%RCX,%RCX,2,%RCX,0,%|rcx=d0afe47d8bbce3aa f=807|rcx=720fad78a336aafe f=805/0
  #|lea rcx, [rcx + rcx*2]|488d0c49|LEA64r:%RCX,%RCX,2,%RCX,0,%|rcx=2868 f=412|rcx=7938 f=410/0
  #|lea rdx, [0x12345678]|488d142578563412|LEA64r:%RDX,%,1,%,305419896,%|rdx=82661c4e78cb0870 f=803|rdx=12345678 f=801/0
  #|lea rdx, [0x12345678]|488d142578563412|LEA64r:%RDX,%,1,%,305419896,%|rdx=7349ce8dd9648000 f=13|rdx=12345678 f=11/0
  #|lea r8d, [r9d + 0x10]|67458d4110|LEA64_32r:%R8D,%R9D,1,%,16,%|r8=1 r9=8 f=42|r8=18 f=40/0
  #|lea r8d, [r9d + 0x10]|67458d4110|LEA64_32r:%R8D,%R9D,1,%,16,%|r8=57bfe5b9f4ea687a r9=44c0784d52437fff f=897|r8=5243800f f=895/0
  #|cbw|6698|CBW:|rax=5cb714a7e68053a4 rdx=b5ece4d2a6499c6b f=803|rax=5cb714a7e680ffa4 f=801/0
  #|cbw|6698|CBW:|rax=5807039abdfffff rdx=3193a3f2ba04c3a1 f=8d6|f=8d4/0
  #|cbw|6698|CBW:|rax=11a7956752292232 rcx=55a70d84570c13d6 f=8c7|rax=11a7956752290032 f=8c5/0
  #|cwde|98|CWDE:|rax=80000000 rcx=aaf6b4bc89298bfa rdx=826c6f5589b96c09 f=c3|rax=0 f=c1/0
  #|cwde|98|CWDE:|rax=be35db680d3c46f1 rdx=20b714a247fbb600 f=456|rax=46f1 f=454/0
  #|cwde|98|CWDE:|rax=4dab19ca0bda87cb rcx=1beb8af1f1cbc1ad rdx=45404f721279ce0e f=c43|rax=ffff87cb f=c41/0
  #|cwd|6699|CWD:|rax=8000000000000000 rcx=755a rdx=80000000 f=d2|f=d0/0
  #|cwd|6699|CWD:|rax=8000000000000000 f=843|rdx=59338a6cc7590000 f=841/0
  #|cwd|6699|CWD:|rax=468f2e59c20cd974 rcx=20f26d3e207f66d3 f=97|rdx=59338a6cc759ffff f=95/0
  #|cdq|99|CDQ:|rax=0 rcx=1a71a948c1dcbe7 rdx=30 f=846|rdx=0 f=844/0
  #|cdq|99|CDQ:|rax=7ffffffffffffffe rcx=dc4e634c01699af3 rdx=9f8c4e73cf71d361 f=817|rdx=ffffffff f=815/0
  #|cdq|99|CDQ:|rax=81c86e07e2aa7e7f rcx=3563 f=892|rdx=ffffffff f=890/0
  #|cdqe|4898|CDQE:|rax=8000000000000002 rcx=2bc513989267edc7 f=d6|rax=2 f=d4/0
  #|cdqe|4898|CDQE:|rax=43a9dedf7fff7fff f=407|rax=7fff7fff f=405/0
  #|cdqe|4898|CDQE:|rax=0 rcx=bb1bd080d1c37b7f rdx=56bd6eb519946ffb f=8c3|f=8c1/0
  #|cqo|4899|CQO:|rax=5d143c3d7e627248 rcx=17d5969286e96490 rdx=28ee7db090d35b29 f=852|rdx=0 f=850/0
  #|cqo|4899|CQO:|rax=9be08395b81d76ab rdx=e4 f=c16|rdx=ffffffffffffffff f=c14/0
  #|cqo|4899|CQO:|rax=10fee6f1cf03297a rdx=eddc f=d7|rdx=0 f=d5/0
  #|clc|f8|CLC:|f=892|f=890/0
  #|clc|f8|CLC:|f=c86|f=c84/0
  #|stc|f9|STC:|f=7|f=5/0
  #|stc|f9|STC:|f=896|f=895/0
  #|cmc|f5|CMC:|f=843|f=840/0
  #|cmc|f5|CMC:|f=812|f=811/0
  #|cld|fc|CLD:|f=882|f=880/0
  #|cld|fc|CLD:|f=8d3|f=8d1/0
  #|std|fd|STD:|f=8c6|f=cc4/0
  #|std|fd|STD:|f=82|f=480/0
  #|sahf|9e|SAHF:|rax=98aed2cb441dcbd1 rcx=488a3f5e0d7abfdf f=cd7|f=cc1/0
  #|sahf|9e|SAHF:|rax=7f rdx=4dc3617cce20a53e f=802|f=800/0
  #|lahf|9f|LAHF:|rax=f rcx=1 f=87|rax=870f f=85/0
  #|lahf|9f|LAHF:|rax=60365868df61fc77 rcx=fffffffffffffffe f=893|rax=60365868df619377 f=891/0

///|
let move32_cases : String =
  #|mov al, bl|88d8|MOV8rr:%AL,%BL|eax=80000000 ebx=730ca930 f=852|eax=80000030 f=850/0
  #|mov al, bl|88d8|MOV8rr:%AL,%BL|eax=ffffffff ebx=83387b30 f=853|eax=ffffff30 f=851/0
  #|mov al, byte ptr [esi]|8a06|MOV8rm:%AL,%ESI,1,%,0,%|eax=e60fa534 ebx=9 f=8c3 m10080=4bc84e663d0dd11c52b5e52d7e8a7b0d|eax=e60fa54b f=8c1/0
  #|mov al, byte ptr [esi]|8a06|MOV8rm:%AL,%ESI,1,%,0,%|eax=b01cd685 ebx=c f=17 m10080=9821d91c1d5a86cb718aed1c00007a3f|eax=b01cd698 f=15/0
  #|mov byte ptr [esi], bl|881e|MOV8mr:%ESI,1,%,0,%,%BL|ebx=e f=856 m10080=ab5ed6e60538c99e682ce198ad32cd77|f=854/0 m10080=0e
  #|mov byte ptr [esi], bl|881e|MOV8mr:%ESI,1,%,0,%,%BL|ebx=0 f=856 m10080=cbafe268cb9173de2663319633a7caea|f=854/0 m10080=00
  #|mov al, 0x1|b001|MOV8ri:%AL,1|eax=2543c462 f=6|eax=2543c401 f=4/0
  #|mov bx, 0x7fff|66bbff7f|MOV16ri:%BX,32767|ebx=7fffffff f=56|ebx=7fff7fff f=54/0
  #|mov word ptr [esi + ebx*4 + 0x8], 0x100|66c7449e080001|MOV16mi:%ESI,4,%EBX,8,%,256|ebx=a f=c3 m100b0=16b92a6b5e607d5fba6ad52b590002b9|f=c1/0 m100b0=0001
  #|mov dword ptr [ebp - 0x20], eax|8945e0|MOV32mr:%EBP,1,%,-32,%,%EAX|eax=567882fc ebx=f f=c3 m20160=e320ca019a669cafeecd44a2345d0e3d|f=c1/0 m20160=fc827856
  #|mov dword ptr [ebp - 0x20], eax|8945e0|MOV32mr:%EBP,1,%,-32,%,%EAX|eax=567fff ebx=8 f=843 m20160=3b0ff8a4fcf84b32ce27c7581da588e2|f=841/0 m20160=ff7f5600
  #|mov dword ptr [ebp - 0x20], 0x80|c745e080000000|MOV32mi:%EBP,1,%,-32,%,128|ebx=6 f=43 m20160=c6b40896719177f0563d1e542c799556|f=41/0 m20160=80000000
  #|movzx bx, ah|660fb6dc|MOVZX16rr8:%BX,%AH|eax=5b270bf8 ebx=8 f=807|ebx=b f=805/0
  #|movzx bx, ah|660fb6dc|MOVZX16rr8:%BX,%AH|eax=125b38ba ebx=80aa f=882|ebx=38 f=880/0
  #|movzx bx, ah|660fb6dc|MOVZX16rr8:%BX,%AH|eax=4c3643cb ebx=ae67fff f=8d6|ebx=ae60043 f=8d4/0
  #|movzx bx, byte ptr [esp + 0x8]|660fb65c2408|MOVZX16rm8:%BX,%ESP,1,%,8,%|ebx=a f=8c6 m20108=45dbb16d6da32150b3d49b7183331bd4|ebx=45 f=8c4/0
  #|movzx bx, byte ptr [esp + 0x8]|660fb65c2408|MOVZX16rm8:%BX,%ESP,1,%,8,%|ebx=5 f=893 m20108=793ab2e266c09c3bd56ad16ca30c832c|ebx=79 f=891/0
  #|movzx ecx, byte ptr [esi + ebx*4 + 0x8]|0fb64c9e08|MOVZX32rm8:%ECX,%ESI,4,%EBX,8,%|ecx=1 ebx=5 f=8c7 m1009c=14da0613167d48748e0ff2adc0e8fdf6|ecx=14 f=8c5/0
  #|movzx ecx, byte ptr [esi + ebx*4 + 0x8]|0fb64c9e08|MOVZX32rm8:%ECX,%ESI,4,%EBX,8,%|ecx=c959 ebx=6 f=817 m100a0=59d83ce9fded510df9d7e09a3d2d94fe|ecx=59 f=815/0
  #|movzx edx, word ptr [esp + 0x8]|0fb7542408|MOVZX32rm16:%EDX,%ESP,1,%,8,%|edx=2633fdd ebx=2 f=816 m20108=6b3f097ab1955812153e91dcd1b7397a|edx=3f6b f=814/0
  #|movzx edx, word ptr [esp + 0x8]|0fb7542408|MOVZX32rm16:%EDX,%ESP,1,%,8,%|edx=0 ebx=d f=c6 m20108=dadb79adc0545dec9d4bd35343de9643|edx=dbda f=c4/0
  #|movsx cx, al|660fbec8|MOVSX16rr8:%CX,%AL|eax=ffffffff ecx=0 f=13|ecx=ffff f=11/0
  #|movsx cx, al|660fbec8|MOVSX16rr8:%CX,%AL|eax=7f ecx=9e edx=7d1e7339 f=8d2|ecx=7f f=8d0/0
  #|movsx cx, al|660fbec8|MOVSX16rr8:%CX,%AL|eax=cc7d351e ecx=f082505d f=d7|ecx=f082001e f=d5/0
  #|movsx ebx, byte ptr [esp + 0x8]|0fbe5c2408|MOVSX32rm8:%EBX,%ESP,1,%,8,%|eax=4b37515f edx=759322a4 ebx=4 f=43 m20108=7165b93ac4b481d6b2dda910295db7d5|ebx=71 f=41/0
  #|movsx ebx, byte ptr [esp + 0x8]|0fbe5c2408|MOVSX32rm8:%EBX,%ESP,1,%,8,%|eax=3042f290 ecx=20966907 ebx=3 f=4d2 m20108=53edbd86a95654164ba24b897a678a47|ebx=53 f=4d0/0
  #|cmovno eax, ebx|0f41c3|CMOV32rr:%EAX,%EAX,%EBX,1|eax=2a519b16 ebx=94ce14f5 f=846|f=844/0
  #|cmovno eax, ebx|0f41c3|CMOV32rr:%EAX,%EAX,%EBX,1|eax=154b3e59 ebx=82d9fbaa f=c16|f=c14/0
  #|cmovno eax, ebx|0f41c3|CMOV32rr:%EAX,%EAX,%EBX,1|eax=bd95f9a3 ebx=4850e42f f=c87|f=c85/0
  #|cmovb bx, dx|660f42da|CMOV16rr:%BX,%BX,%DX,2|edx=d04491f1 ebx=ffffffff f=882|f=880/0
  #|setb dl|0f92c2|SETCCr:%DL,2|edx=0 f=8c3|edx=1 f=8c1/0
  #|setb dl|0f92c2|SETCCr:%DL,2|edx=fffffffe f=852|edx=ffffff00 f=850/0
  #|setb dl|0f92c2|SETCCr:%DL,2|edx=4a462880 f=8c7|edx=4a462801 f=8c5/0
  #|cmovae ecx, ebx|0f43cb|CMOV32rr:%ECX,%ECX,%EBX,3|ecx=e4e73a22 ebx=ca82066e f=c16|ecx=ca82066e f=c14/0
  #|cmovae ecx, ebx|0f43cb|CMOV32rr:%ECX,%ECX,%EBX,3|ecx=7fff ebx=f907552d f=857|f=855/0
  #|cmovae ecx, ebx|0f43cb|CMOV32rr:%ECX,%ECX,%EBX,3|ecx=4241f77 ebx=ea f=8c7|f=8c5/0
  #|cmovae ecx, dword ptr [esp + 0x8]|0f434c2408|CMOV32rm:%ECX,%ECX,%ESP,1,%,8,%,3|ecx=c5e1a5a3 ebx=7 f=c12 m20108=3e4361d74123e9ec04dec8c5b1ed0dd2|ecx=d761433e f=c10/0
  #|cmovae ecx, dword ptr [esp + 0x8]|0f434c2408|CMOV32rm:%ECX,%ECX,%ESP,1,%,8,%,3|ecx=482cffff ebx=f f=883 m20108=f46fa7544f978828cbda15dffec6a51f|f=881/0
  #|cmove dx, cx|660f44d1|CMOV16rr:%DX,%DX,%CX,4|ecx=c5b08a41 edx=d098ffff f=97|f=95/0
  #|sete byte ptr [esi]|0f9406|SETCCm:%ESI,1,%,0,%,4|ebx=7 f=87 m10080=87aff5f75e0613e2ea9a80d4236e9760|f=85/0 m10080=00
  #|cmovne edx, ebx|0f45d3|CMOV32rr:%EDX,%EDX,%EBX,5|edx=ee ebx=2 f=846|f=844/0
  #|cmovne edx, ebx|0f45d3|CMOV32rr:%EDX,%EDX,%EBX,5|edx=cdded8a0 ebx=a78e66ca f=8c6|f=8c4/0
  #|cmovne edx, ebx|0f45d3|CMOV32rr:%EDX,%EDX,%EBX,5|edx=9bb4818b ebx=4d81a63f f=847|f=845/0
  #|cmovne ebx, dword ptr [ebp - 0x20]|0f455de0|CMOV32rm:%EBX,%EBX,%EBP,1,%,-32,%,5|ebx=4 f=4c3 m20160=18eb54b432bde1732bf512a3c1e5a726|f=4c1/0
  #|cmovne ebx, dword ptr [ebp - 0x20]|0f455de0|CMOV32rm:%EBX,%EBX,%EBP,1,%,-32,%,5|ebx=1 f=46 m20160=7066514a0f87a85d53c6dda49e45b170|f=44/0
  #|setne cl|0f95c1|SETCCr:%CL,5|ecx=b1 f=816|ecx=1 f=814/0
  #|setne cl|0f95c1|SETCCr:%CL,5|ecx=2f9eec6d f=d7|ecx=2f9eec00 f=d5/0
  #|setne cl|0f95c1|SETCCr:%CL,5|ecx=8cc377fd f=8d7|ecx=8cc37700 f=8d5/0
  #|setne byte ptr [esi]|0f9506|SETCCm:%ESI,1,%,0,%,5|ebx=5 f=8d6 m10080=8c102e2f3562ab322415649eeb290b25|f=8d4/0 m10080=00
  #|cmovbe dx, bx|660f46d3|CMOV16rr:%DX,%DX,%BX,6|edx=786d8d00 ebx=95 f=47|edx=786d0095 f=45/0
  #|cmovbe edx, ecx|0f46d1|CMOV32rr:%EDX,%EDX,%ECX,6|ecx=2e4d1f6a edx=565980bf f=87|edx=2e4d1f6a f=85/0
  #|cmovbe edx, ecx|0f46d1|CMOV32rr:%EDX,%EDX,%ECX,6|ecx=6215039f edx=c f=96|f=94/0
  #|cmovbe edx, ecx|0f46d1|CMOV32rr:%EDX,%EDX,%ECX,6|ecx=f80ceba8 edx=7913a7d3 f=803|edx=f80ceba8 f=801/0
  #|cmovbe edx, dword ptr [ebp - 0x20]|0f4655e0|CMOV32rm:%EDX,%EDX,%EBP,1,%,-32,%,6|edx=b0c39f9a ebx=8 f=842 m20160=74b9f59a05c427bade2e6c72fd32aabb|edx=9af5b974 f=840/0
  #|cmovbe edx, dword ptr [ebp - 0x20]|0f4655e0|CMOV32rm:%EDX,%EDX,%EBP,1,%,-32,%,6|edx=302d203e ebx=a f=c7 m20160=1bcfa31502ccd9af19e20a365fff9530|edx=15a3cf1b f=c5/0
  #|cmova dx, ax|660f47d0|CMOV16rr:%DX,%DX,%AX,7|eax=0 edx=ffffffff f=853|f=851/0
  #|cmova edx, ebx|0f47d3|CMOV32rr:%EDX,%EDX,%EBX,7|edx=cd112202 ebx=95c95dd2 f=812|edx=95c95dd2 f=810/0
  #|cmova edx, ebx|0f47d3|CMOV32rr:%EDX,%EDX,%EBX,7|edx=0 ebx=a2c18ab f=56|f=54/0
  #|cmova edx, ebx|0f47d3|CMOV32rr:%EDX,%EDX,%EBX,7|edx=c ebx=7f f=856|f=854/0
  #|cmova eax, dword ptr [esp + 0x8]|0f47442408|CMOV32rm:%EAX,%EAX,%ESP,1,%,8,%,7|eax=1ba95c63 ebx=1 f=83 m20108=c42932f42aae17abef41d28ed39f7a0e|f=81/0
  #|cmova eax, dword ptr [esp + 0x8]|0f47442408|CMOV32rm:%EAX,%EAX,%ESP,1,%,8,%,7|eax=47015ffc ebx=f f=892 m20108=b3b1bfcf4b41af0fa8cedb0d9048b2a0|eax=cfbfb1b3 f=890/0
  #|cmovs ebx, ecx|0f48d9|CMOV32rr:%EBX,%EBX,%ECX,8|ecx=38a57cf4 ebx=289ec710 f=457|f=455/0
  #|cmovs ebx, ecx|0f48d9|CMOV32rr:%EBX,%EBX,%ECX,8|ecx=e7132e36 ebx=c4556915 f=43|f=41/0
  #|cmovs ebx, ecx|0f48d9|CMOV32rr:%EBX,%EBX,%ECX,8|ecx=3b ebx=7fffffff f=96|ebx=3b f=94/0
  #|cmovs edx, dword ptr [esi + ebx*4 + 0x8]|0f48549e08|CMOV32rm:%EDX,%EDX,%ESI,4,%EBX,8,%,8|edx=412737bc ebx=d f=8d2 m100bc=4b4cabcfa36cf4a544295a971ce8fd39|edx=cfab4c4b f=8d0/0
  #|cmovs edx, dword ptr [esi + ebx*4 + 0x8]|0f48549e08|CMOV32rm:%EDX,%EDX,%ESI,4,%EBX,8,%,8|edx=1f531a21 ebx=7 f=12 m100a4=d3287fb54ed3373135a921e89ddb17e0|f=10/0
  #|sets al|0f98c0|SETCCr:%AL,8|eax=d12ad6e6 f=43|eax=d12ad600 f=41/0
  #|sets al|0f98c0|SETCCr:%AL,8|eax=17f51223 f=4d2|eax=17f51201 f=4d0/0
  #|sets al|0f98c0|SETCCr:%AL,8|eax=b5 f=d6|eax=1 f=d4/0
  #|sets byte ptr [esi + ebx*4 + 0x8]|0f98449e08|SETCCm:%ESI,4,%EBX,8,%,8|ebx=0 f=46 m10088=272e9776684e41d40fcb15a22c945a17|f=44/0 m10088=00
  #|cmovns ax, bx|660f49c3|CMOV16rr:%AX,%AX,%BX,9|eax=1 ebx=f1 f=893|f=891/0
  #|cmovns eax, edx|0f49c2|CMOV32rr:%EAX,%EAX,%EDX,9|eax=ffff edx=ef9034ab f=87|f=85/0
  #|cmovns eax, edx|0f49c2|CMOV32rr:%EAX,%EAX,%EDX,9|eax=b360809f edx=a f=853|eax=a f=851/0
  #|cmovns eax, edx|0f49c2|CMOV32rr:%EAX,%EAX,%EDX,9|eax=0 edx=ffffffff f=8c7|f=8c5/0
  #|setns bl|0f99c3|SETCCr:%BL,9|ebx=2 f=87|ebx=0 f=85/0
  #|setns bl|0f99c3|SETCCr:%BL,9|ebx=87ec0673 f=cc6|ebx=87ec0600 f=cc4/0
  #|setns bl|0f99c3|SETCCr:%BL,9|ebx=2b8fb64c f=882|ebx=2b8fb600 f=880/0
  #|cmovp dx, bx|660f4ad3|CMOV16rr:%DX,%DX,%BX,10|edx=2116e5fd ebx=ffff f=8d7|edx=2116ffff f=8d5/0
  #|cmovp eax, dword ptr [ebp - 0x20]|0f4a45e0|CMOV32rm:%EAX,%EAX,%EBP,1,%,-32,%,10|eax=ef632379 ebx=9 f=52 m20160=537437ee873a9a9ddbf3457600b45b6e|f=50/0
  #|cmovp eax, dword ptr [ebp - 0x20]|0f4a45e0|CMOV32rm:%EAX,%EAX,%EBP,1,%,-32,%,10|eax=266a9b25 ebx=8 f=57 m20160=bf92f0bfc7b25bd9fafa7ea8466f9e90|eax=bff092bf f=55/0
  #|setp cl|0f9ac1|SETCCr:%CL,10|ecx=d5fc6e74 f=813|ecx=d5fc6e00 f=811/0
  #|setp cl|0f9ac1|SETCCr:%CL,10|ecx=fbc51462 f=882|ecx=fbc51400 f=880/0
  #|setp cl|0f9ac1|SETCCr:%CL,10|ecx=830448e3 f=16|ecx=83044801 f=14/0
  #|setp byte ptr [edi + 0x10]|0f9a4710|SETCCm:%EDI,1,%,16,%,10|ebx=1 f=c86 m10110=8cad1b1adb9e21cdb7f641d3716a6a70|f=c84/0 m10110=01
  #|cmovnp ebx, edx|0f4bda|CMOV32rr:%EBX,%EBX,%EDX,11|edx=70 ebx=b20d43aa f=96|f=94/0
  #|cmovnp ebx, edx|0f4bda|CMOV32rr:%EBX,%EBX,%EDX,11|edx=f2c145fd ebx=3d43d25e f=cd6|f=cd4/0
  #|cmovnp ebx, edx|0f4bda|CMOV32rr:%EBX,%EBX,%EDX,11|edx=fffffffe ebx=c8bc608 f=7|f=5/0
  #|setnp dl|0f9bc2|SETCCr:%DL,11|edx=d f=856|edx=0 f=854/0
  #|setnp dl|0f9bc2|SETCCr:%DL,11|edx=2 f=c82|edx=1 f=c80/0
  #|setnp dl|0f9bc2|SETCCr:%DL,11|edx=aa748000 f=443|edx=aa748001 f=441/0
  #|cmovl eax, ecx|0f4cc1|CMOV32rr:%EAX,%EAX,%ECX,12|eax=809c4a73 ecx=80634795 f=856|eax=80634795 f=854/0
  #|cmovl eax, ecx|0f4cc1|CMOV32rr:%EAX,%EAX,%ECX,12|eax=9797127d ecx=5cd5ad2b f=853|eax=5cd5ad2b f=851/0
  #|cmovl eax, ecx|0f4cc1|CMOV32rr:%EAX,%EAX,%ECX,12|eax=5ce8d197 ecx=3c383f7f f=c43|eax=3c383f7f f=c41/0
  #|cmovl ebx, dword ptr [esi + ebx*4 + 0x8]|0f4c5c9e08|CMOV32rm:%EBX,%EBX,%ESI,4,%EBX,8,%,12|ebx=0 f=812 m10088=c28d51ce77e15b8116522f68b339c0ed|ebx=ce518dc2 f=810/0
  #|cmovl ebx, dword ptr [esi + ebx*4 + 0x8]|0f4c5c9e08|CMOV32rm:%EBX,%EBX,%ESI,4,%EBX,8,%,12|ebx=6 f=8c3 m100a0=89277a7afeefd8c25a6435d455d3c4a9|f=8c1/0
  #|cmovge dx, ax|660f4dd0|CMOV16rr:%DX,%DX,%AX,13|eax=d1ebbbc4 edx=9e f=856|f=854/0
  #|cmovge ecx, dword ptr [edi + 0x10]|0f4d4f10|CMOV32rm:%ECX,%ECX,%EDI,1,%,16,%,13|ecx=a63f ebx=7 f=8c2 m10110=739479a837e43b26059b0d7cdb72e490|ecx=a8799473 f=8c0/0
  #|cmovge ecx, dword ptr [edi + 0x10]|0f4d4f10|CMOV32rm:%ECX,%ECX,%EDI,1,%,16,%,13|ecx=1cb4c2 ebx=9 f=893 m10110=4b02fbba8fb9513d5c2265b3dd9017e5|ecx=bafb024b f=891/0
  #|setge dl|0f9dc2|SETCCr:%DL,13|edx=b9a44480 f=8d2|edx=b9a44401 f=8d0/0
  #|setge dl|0f9dc2|SETCCr:%DL,13|edx=c f=6|edx=1 f=4/0
  #|setge dl|0f9dc2|SETCCr:%DL,13|edx=1010c27f f=843|edx=1010c200 f=841/0
  #|cmovle edx, ecx|0f4ed1|CMOV32rr:%EDX,%EDX,%ECX,14|ecx=73 edx=fdbd f=806|edx=73 f=804/0
  #|cmovle edx, ecx|0f4ed1|CMOV32rr:%EDX,%EDX,%ECX,14|ecx=5ddb667f edx=8000 f=893|f=891/0
  #|cmovle edx, ecx|0f4ed1|CMOV32rr:%EDX,%EDX,%ECX,14|ecx=be721 edx=699 f=846|edx=be721 f=844/0
  #|cmovle ebx, dword ptr [ebp - 0x20]|0f4e5de0|CMOV32rm:%EBX,%EBX,%EBP,1,%,-32,%,14|ebx=0 f=12 m20160=15e63650abefb432073ad93660a883b9|f=10/0
  #|cmovle ebx, dword ptr [ebp - 0x20]|0f4e5de0|CMOV32rm:%EBX,%EBX,%EBP,1,%,-32,%,14|ebx=e f=4c2 m20160=6bf16aedb715ab154024d6639e5e05de|ebx=ed6af16b f=4c0/0
  #|setle byte ptr [edi + 0x10]|0f9e4710|SETCCm:%EDI,1,%,16,%,14|ebx=e f=897 m10110=45015929a7cf7df45c4e7ec7f44689f6|f=895/0 m10110=00
  #|cmovg dx, bx|660f4fd3|CMOV16rr:%DX,%DX,%BX,15|edx=84939fd1 ebx=d88c39f2 f=8d3|f=8d1/0
  #|cmovg eax, ebx|0f4fc3|CMOV32rr:%EAX,%EAX,%EBX,15|eax=cf ebx=5e300e10 f=cd7|f=cd5/0
  #|cmovg eax, ebx|0f4fc3|CMOV32rr:%EAX,%EAX,%EBX,15|eax=80 ebx=80000000 f=46|f=44/0
  #|cmovg eax, ebx|0f4fc3|CMOV32rr:%EAX,%EAX,%EBX,15|eax=f0f703 ebx=f f=4d2|f=4d0/0
  #|cmovg edx, dword ptr [esi + ebx*4 + 0x8]|0f4f549e08|CMOV32rm:%EDX,%EDX,%ESI,4,%EBX,8,%,15|edx=4cd48578 ebx=9 f=443 m100ac=916a6cad23baf349e9a0cb62c09095f4|f=441/0
  #|cmovg edx, dword ptr [esi + ebx*4 + 0x8]|0f4f549e08|CMOV32rm:%EDX,%EDX,%ESI,4,%EBX,8,%,15|edx=1909c472 ebx=4 f=87 m10098=d64fc144f30705017cf73fab4ab89376|f=85/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|ecx=1 f=847|ecx=0 f=845/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|ecx=8 f=897|ecx=1 f=895/0
  #|setg cl|0f9fc1|SETCCr:%CL,15|ecx=51b2 f=93|ecx=5100 f=91/0
  #|setg byte ptr [esp + 0x8]|0f9f442408|SETCCm:%ESP,1,%,8,%,15|ebx=4 f=806 m20108=065fa7cd2e40f1839101e614759fc6e3|f=804/0 m20108=00
  #|xchg byte ptr [esp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%ESP,1,%,8,%|eax=80000000 ecx=fffffffe edx=e0906b6c ebx=a f=8c7 m20108=89f7428c75e2be0ceb81660fcaf1cd74|ecx=ffffff89 f=8c5/0 m20108=fe
  #|xchg byte ptr [esp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%ESP,1,%,8,%|ecx=e240f7d2 edx=2 ebx=9 f=17 m20108=ea02dd6fdd2c27c06a26a6f2a6d0c358|ecx=e240f7ea f=15/0 m20108=d2
  #|xadd cl, bl|0fc0d9|XADD8rr:%CL,%BL,%CL,%BL|ecx=918ecba5 edx=f ebx=8000 f=c13|ebx=80a5 f=484/0
  #|xadd cl, bl|0fc0d9|XADD8rr:%CL,%BL,%CL,%BL|eax=5c22 ecx=8000 edx=a9a756ff ebx=b47bd4a5 f=53|ecx=80a5 ebx=b47bd400 f=84/0
  #|xadd cl, bl|0fc0d9|XADD8rr:%CL,%BL,%CL,%BL|eax=ff5f07df ecx=5309ca40 edx=d8c6b574 ebx=fbbad1a9 f=c2|ecx=5309cae9 ebx=fbbad140 f=80/0
  #|xchg ax, dx|6692|XCHG16ar:%DX,%DX|eax=566afe3a ecx=b3f1f5d4 edx=ad62d468 f=83|eax=566ad468 edx=ad62fe3a f=81/0
  #|xchg ax, dx|6692|XCHG16ar:%DX,%DX|eax=ee2de3e8 ecx=f3c2afdd edx=74c1e20c f=893|eax=ee2de20c edx=74c1e3e8 f=891/0
  #|xchg word ptr [edi + 0x10], dx|66875710|XCHG16rm:%DX,%DX,%EDI,1,%,16,%|eax=f3cc ecx=bcab7fff edx=68feba7f ebx=b f=cc2 m10110=16a496577d5908703b8a63174c7a8c9c|edx=68fea416 f=cc0/0 m10110=7fba
  #|xchg word ptr [edi + 0x10], dx|66875710|XCHG16rm:%DX,%DX,%EDI,1,%,16,%|ecx=ab73e0ba edx=ec0541ae ebx=5 f=c2 m10110=9d71a1b8007c15a803cc31b65772d2f6|edx=ec05719d f=c0/0 m10110=ae41
  #|cmpxchg word ptr [edi + 0x10], cx|660fb14f10|CMPXCHG16rm:%EDI,1,%,16,%,%CX|eax=6484414c ecx=6a81141a edx=90f300e4 ebx=6 f=8d2 m10110=4c4189e2ffc47580f6b4d910ab6687b2|f=44/0 m10110=1a14
  #|cmpxchg word ptr [edi + 0x10], cx|660fb14f10|CMPXCHG16rm:%EDI,1,%,16,%,%CX|eax=1e5bad63 ecx=b0e5f3a6 edx=932e2e1d ebx=8 f=8c7 m10110=63ade2efb1ae396eb14072bdcce1ea90|f=44/0 m10110=a6f3
  #|cmpxchg word ptr [edi + 0x10], cx|660fb14f10|CMPXCHG16rm:%EDI,1,%,16,%,%CX|eax=ffffffff ecx=f097de8e edx=8521101b ebx=3 f=8d7 m10110=be3eb308980015e140ba2a40ac86c01a|eax=ffff3ebe f=84/0
  #|cmpxchg word ptr [edi + 0x10], cx|660fb14f10|CMPXCHG16rm:%EDI,1,%,16,%,%CX|ecx=bdc940d4 edx=33858cc5 ebx=7 f=883 m10110=c8c48913c94ecb7ad94685190f929788|eax=d3f1c4c8 f=95/0
  #|xadd ax, cx|660fc1c8|XADD16rr:%AX,%CX,%AX,%CX|eax=7ee08000 ecx=b770b922 edx=355bc49f f=417|eax=7ee03922 ecx=b7708000 f=c05/0
  #|xadd ax, cx|660fc1c8|XADD16rr:%AX,%CX,%AX,%CX|eax=ffffffff ecx=a735d77f f=896|eax=ffffd77e ecx=a735ffff f=95/0
  #|xadd ax, cx|660fc1c8|XADD16rr:%AX,%CX,%AX,%CX|eax=4 ecx=e8d9ec47 edx=fdf9f840 f=816|eax=ec4b ecx=e8d90004 f=84/0
  #|xchg dword ptr [esi + ebx*4 + 0x8], ecx|874c9e08|XCHG32rm:%ECX,%ECX,%ESI,4,%EBX,8,%|eax=ffffffff ecx=fffffffe edx=80 ebx=f f=c17 m100c4=4d6c55a75de79910a3f91b1bf5961e2d|ecx=a7556c4d f=c15/0 m100c4=feffffff
  #|xchg dword ptr [esi + ebx*4 + 0x8], ecx|874c9e08|XCHG32rm:%ECX,%ECX,%ESI,4,%EBX,8,%|eax=c81b2053 ecx=1c3d edx=2fe4aa8a ebx=0 f=c02 m10088=8e4f59b11b6e837f0e4a1e8c3073b43b|ecx=b1594f8e f=c00/0 m10088=3d1c0000
  #|cmpxchg dword ptr [esi + ebx*4 + 0x8], ebx|0fb15c9e08|CMPXCHG32rm:%ESI,4,%EBX,8,%,%EBX|ecx=cf15e3d6 ebx=6 f=483 m100a0=00000000931810f4621df26a3dd57010|eax=0 f=480/0
  #|cmpxchg dword ptr [esi + ebx*4 + 0x8], ebx|0fb15c9e08|CMPXCHG32rm:%ESI,4,%EBX,8,%,%EBX|eax=e6d3babd ecx=7f edx=14008000 ebx=2 f=12 m10090=f186c6017106928ab31b8e0541dfde42|eax=1c686f1 f=84/0
  #|cmpxchg dword ptr [esi + ebx*4 + 0x8], ebx|0fb15c9e08|CMPXCHG32rm:%ESI,4,%EBX,8,%,%EBX|eax=5512 ecx=fafad371 edx=6cbdd40 ebx=b f=817 m100b4=6f84cd8964348f8a8354db5725ec9d9c|eax=89cd846f f=15/0
  #|cmpxchg dword ptr [esi + ebx*4 + 0x8], ebx|0fb15c9e08|CMPXCHG32rm:%ESI,4,%EBX,8,%,%EBX|eax=5ea7c5ea edx=df5323bd ebx=e f=87 m100c0=eac5a75e2e6f6ea5926fbbeee2a6f3ab|f=44/0 m100c0=0e000000
  #|xadd eax, ebx|0fc1d8|XADD32rr:%EAX,%EBX,%EAX,%EBX|eax=d42530b0 ecx=ffffffff edx=d669c72b ebx=fc34197f f=412|eax=d0594a2f ebx=d42530b0 f=481/0
  #|xadd eax, ebx|0fc1d8|XADD32rr:%EAX,%EBX,%EAX,%EBX|eax=db828000 ecx=e4ce61a8 ebx=defc884f f=803|eax=ba7f084f ebx=db828000 f=81/0
  #|xadd eax, ebx|0fc1d8|XADD32rr:%EAX,%EBX,%EAX,%EBX|eax=9b ecx=e9723f1d edx=2882996b ebx=8a841a3d f=887|eax=8a841ad8 ebx=9b f=94/0
  #|xadd dword ptr [esi + ebx*4 + 0x8], ebx|0fc15c9e08|XADD32rm:%EBX,%EBX,%ESI,4,%EBX,8,%|eax=8aad899b ecx=ffffffff edx=cd80 ebx=7 f=86 m100a4=e3c4ec808ee418439c01ad0fce184e1d|ebx=80ecc4e3 f=80/0 m100a4=ea
  #|xadd dword ptr [esi + ebx*4 + 0x8], ebx|0fc15c9e08|XADD32rm:%EBX,%EBX,%ESI,4,%EBX,8,%|eax=abdf5cf6 ecx=c72577d1 ebx=4 f=8c3 m10098=0d11c1893ed7c2f240be3d85f1c20207|ebx=89c1110d f=94/0 m10098=11
  #|xadd dword ptr [esi + ebx*4 + 0x8], ebx|0fc15c9e08|XADD32rm:%EBX,%EBX,%ESI,4,%EBX,8,%|eax=7fffffff edx=643d0687 ebx=1 f=853 m1008c=7cd885a52d121b140651b492285488ee|ebx=a585d87c f=84/0 m1008c=7d
  #|xchg eax, eax (87 c0)|87c0|XCHG32rr:%EAX,%EAX,%EAX,%EAX|eax=dd ecx=cb368e83 edx=32bc9e f=2|f=0/0
  #|xchg eax, eax (87 c0)|87c0|XCHG32rr:%EAX,%EAX,%EAX,%EAX|eax=fc ecx=a5e7dba3 edx=a775a826 f=456|f=454/0
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=80047209 ecx=d4cbae47 edx=28708ac ebx=5db3c3a6 f=43 m10080=09720480ac088702|f=41/0 m10080=a6c3b35d47aecbd4
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=c3339070 ecx=d4781c09 edx=2c84ab43 ebx=926fbb13 f=92 m10080=21ed0273aca2393e|eax=7302ed21 edx=3e39a2ac f=90/0
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=fad3c2b6 ecx=b31ec82d edx=bc5c0c8e ebx=9c3dd4dc f=896 m10080=bc37e58ebf16ab51|eax=8ee537bc edx=51ab16bf f=894/0
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=84eb78e9 ecx=cdf2fcd edx=1eaccaf3 ebx=6b5cf13b f=c92 m10080=e978eb84f3caac1e|f=cd0/0 m10080=3bf15c6bcd2fdf0c
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=297f3cec ecx=dc3fdc5a edx=79439277 ebx=a27747ba f=6 m10080=6add0f3b4ce3daa0|eax=3b0fdd6a edx=a0dae34c f=4/0
  #|cmpxchg8b qword ptr [esi]|0fc70e|CMPXCHG8B:%ESI,1,%,0,%|eax=3f4afb7a ecx=ee2be77f edx=c0bf135d ebx=4cdc1fc8 f=853 m10080=7afb4a3f5d13bfc0|f=851/0 m10080=c81fdc4c7fe72bee
  #|lea eax, [ebx + ecx*4 + 0x10]|8d448b10|LEA32r:%EAX,%EBX,4,%ECX,16,%|eax=3895fc16 ecx=ce048c4f ebx=36091d87 f=42|eax=6e1b4ed3 f=40/0
  #|lea eax, [ebx + ecx*4 + 0x10]|8d448b10|LEA32r:%EAX,%EBX,4,%ECX,16,%|eax=1e9751fe ecx=813cb53d ebx=49eaad2 f=52|eax=9917fd6 f=50/0
  #|lea ax, [ebx + ecx]|668d040b|LEA16r:%AX,%EBX,1,%ECX,0,%|eax=21c2f9d3 ecx=ad1d ebx=36e83c93 f=8c2|eax=21c2e9b0 f=8c0/0
  #|lea ax, [ebx + ecx]|668d040b|LEA16r:%AX,%EBX,1,%ECX,0,%|eax=f3dfb903 ecx=79a4c537 ebx=77ea66d f=c7|eax=f3df6ba4 f=c5/0
  #|lea ecx, [ecx + ecx*2]|8d0c49|LEA32r:%ECX,%ECX,2,%ECX,0,%|ecx=3dbeed26 f=857|ecx=b93cc772 f=855/0
  #|lea ecx, [ecx + ecx*2]|8d0c49|LEA32r:%ECX,%ECX,2,%ECX,0,%|ecx=ac8b6a0b f=43|ecx=5a23e21 f=41/0
  #|lea edx, [0x12345678]|8d1578563412|LEA32r:%EDX,%,1,%,305419896,%|edx=c60bd7ce f=893|edx=12345678 f=891/0
  #|lea edx, [0x12345678]|8d1578563412|LEA32r:%EDX,%,1,%,305419896,%|edx=60fa9895 f=cd6|edx=12345678 f=cd4/0
  #|cbw|6698|CBW:|eax=6d41876d ecx=ba723a68 edx=da2b8a67 f=83|eax=6d41006d f=81/0
  #|cbw|6698|CBW:|eax=e4e2111 ecx=28340ec1 edx=80000000 f=47|eax=e4e0011 f=45/0
  #|cbw|6698|CBW:|eax=4e9c53cc ecx=fffffffe f=3|eax=4e9cffcc f=1/0
  #|cwde|98|CWDE:|eax=e1d38e6a ecx=64902c95 edx=aa5ec86b f=86|eax=ffff8e6a f=84/0
  #|cwde|98|CWDE:|eax=47c79ac0 ecx=9e37c77e f=812|eax=ffff9ac0 f=810/0
  #|cwde|98|CWDE:|eax=8000 ecx=ede38947 edx=18b35998 f=d7|eax=ffff8000 f=d5/0
  #|cwd|6699|CWD:|eax=0 ecx=3ef05049 edx=7a58690e f=852|edx=7a580000 f=850/0
  #|cwd|6699|CWD:|eax=7ffffffe ecx=74d70104 edx=ffffffff f=47|f=45/0
  #|cwd|6699|CWD:|eax=d9f280b2 ecx=7fffffff edx=7fffffff f=86|f=84/0
  #|stc|f9|STC:|f=13|f=11/0
  #|stc|f9|STC:|f=93|f=91/0
  #|cld|fc|CLD:|f=812|f=810/0
  #|cld|fc|CLD:|f=42|f=40/0
