// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let lisp64_cases : String =
  #|xchg al, bl|86c3|XCHG8rr:%AL,%BL,%AL,%BL|rax=7fffffffffffffff rcx=f0 rdx=3 rbx=ef59c54a80992b9a f=812|rax=7fffffffffffff9a rbx=ef59c54a80992bff f=810/0
  #|xchg al, bl|86c3|XCHG8rr:%AL,%BL,%AL,%BL|rax=d7fc955acb2d56d9 rcx=ace8a3b6456d5686 rdx=ee44a23ebcde73df rbx=240f10ee74eeb1e4 f=13|rax=d7fc955acb2d56e4 rbx=240f10ee74eeb1d9 f=11/0
  #|xchg ch, dl|86ea|XCHG8rr:%CH,%DL,%CH,%DL|rax=746451f5391d01fe rcx=367d76be13347281 rdx=6751477772ecd5e7 f=886|rcx=367d76be1334e781 rdx=6751477772ecd572 f=884/0
  #|xchg ch, dl|86ea|XCHG8rr:%CH,%DL,%CH,%DL|rax=8a5452c5e57afcda rcx=bc91f13db7b16300 rdx=74a5ae1ae5b0f7ee f=497|rcx=bc91f13db7b1ee00 rdx=74a5ae1ae5b0f763 f=495/0
  #|xchg ah, bh|86e7|XCHG8rr:%AH,%BH,%AH,%BH|rax=9d47d4f0821b0ebe rcx=de844ffcdd3937b5 rdx=ffffffff rbx=1defb6520a22eb7e f=807|rax=9d47d4f0821bebbe rbx=1defb6520a220e7e f=805/0
  #|xchg ah, bh|86e7|XCHG8rr:%AH,%BH,%AH,%BH|rax=f4dec77c67cef649 rdx=9f2f7a7831ddfe3a rbx=525fdb6896ea6eff f=492|rax=f4dec77c67ce6e49 rbx=525fdb6896eaf6ff f=490/0
  #|xchg r9b, sil|4486ce|XCHG8rr:%R9B,%SIL,%R9B,%SIL|rcx=8ad23f940109bc2 rdx=f3 r9=fd26c5113d0b82e6 f=c02|rsi=100e6 r9=fd26c5113d0b8280 f=c00/0
  #|xchg r9b, sil|4486ce|XCHG8rr:%R9B,%SIL,%R9B,%SIL|rax=356291c77527200 rcx=35958ef730accc8f rdx=f6c9823effffffff r9=447ea2febb1b0430 f=443|rsi=10030 r9=447ea2febb1b0480 f=441/0
  #|xchg byte ptr [rsi], cl|860e|XCHG8rm:%CL,%CL,%RSI,1,%,0,%|rax=992c99e1bed561ea rcx=8af7e5522bdcf47d rdx=ffa8b9510f8882f9 rbx=0 r9=e f=453 m10080=4ddeb0f2b33e5ab975a27847070ec044|rcx=8af7e5522bdcf44d f=451/0 m10080=7d
  #|xchg byte ptr [rsi], cl|860e|XCHG8rm:%CL,%CL,%RSI,1,%,0,%|rcx=7fffffffffffffff rbx=5 r9=f f=883 m10080=7816a8627cdfabdeb2b333033279bd78|rcx=7fffffffffffff78 f=881/0 m10080=ff
  #|xchg byte ptr [rdi + 0x10], cl|864f10|XCHG8rm:%CL,%CL,%RDI,1,%,16,%|rax=8f111b8d734aa5e6 rcx=7a rdx=7fffffffffffffff rbx=b r9=4 f=817 m10110=e0f15d74b1ae7c6a5bbbd2c2b08df7cc|rcx=e0 f=815/0 m10110=7a
  #|xchg byte ptr [rdi + 0x10], cl|864f10|XCHG8rm:%CL,%CL,%RDI,1,%,16,%|rax=21c2ff2bde15ed58 rcx=a48f452142539efb rdx=1 rbx=f r9=8 f=4d2 m10110=8eef39d4830db5c634a897cf2f2c4314|rcx=a48f452142539e8e f=4d0/0 m10110=fb
  #|xchg byte ptr [rbp - 0x20], cl|864de0|XCHG8rm:%CL,%CL,%RBP,1,%,-32,%|rcx=42e52ade05a18910 rbx=7 r9=a f=16 m20160=2ff5cf2edfa5935bf82bfdc86cb6ccaf|rcx=42e52ade05a1892f f=14/0 m20160=10
  #|xchg byte ptr [rbp - 0x20], cl|864de0|XCHG8rm:%CL,%CL,%RBP,1,%,-32,%|rax=8fd44f289808809a rcx=2 rdx=499839ca70d92880 rbx=4 r9=c f=c3 m20160=80f92a8ce291192ba0859706dec1aaad|rcx=80 f=c1/0 m20160=02
  #|xchg byte ptr [rsi + rbx*4 + 0x8], cl|864c9e08|XCHG8rm:%CL,%CL,%RSI,4,%RBX,8,%|rax=5e4ee3d13608fbcf rcx=574b3d750cb753f2 rdx=3c5b9d48b4b5ec7f rbx=c r9=1 f=46 m100b8=7a2e6683d8321aece52e8c3c8a54fc3a|rcx=574b3d750cb7537a f=44/0 m100b8=f2
  #|xchg byte ptr [rsi + rbx*4 + 0x8], cl|864c9e08|XCHG8rm:%CL,%CL,%RSI,4,%RBX,8,%|rax=487a78ef223b90eb rcx=4e7a75c849eaba7f rdx=1eeae9dc1ebf1afd rbx=9 r9=8 f=817 m100ac=5bac5bdd5b8ad17981d54f78370df3d9|rcx=4e7a75c849eaba5b f=815/0 m100ac=7f
  #|xchg byte ptr [rsp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%RSP,1,%,8,%|rax=adcf48efa2eb289 rcx=b87bb8f987cd836 rbx=8 r9=c f=846 m20108=b1b7a6113f67a01dd6ab1ef18f0b50a9|rcx=b87bb8f987cd8b1 f=844/0 m20108=36
  #|xchg byte ptr [rsp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%RSP,1,%,8,%|rcx=aca610ccacb7614f rdx=ea5dbefe5c78d2e8 rbx=b r9=d f=897 m20108=54d61a440b88ccaca8c1f4e18f2e045a|rcx=aca610ccacb76154 f=895/0 m20108=4f
  #|xchg byte ptr [rdi + r9*2 - 0x4], cl|42864c4ffc|XCHG8rm:%CL,%CL,%RDI,2,%R9,-4,%|rcx=7cf0f4fc2bab7e76 rdx=1dd042a4367ba574 rbx=a r9=7 f=853 m1010a=0ff35c4870c06ac3e6cf202356b87495|rcx=7cf0f4fc2bab7e0f f=851/0 m1010a=76
  #|xchg byte ptr [rdi + r9*2 - 0x4], cl|42864c4ffc|XCHG8rm:%CL,%CL,%RDI,2,%R9,-4,%|rax=315971c6cbd20e00 rcx=fda199bebe5a9b25 rdx=1c8ddb3bf424021 rbx=a r9=1 f=897 m100fe=afda55bff34929d347c86937a39f210f|rcx=fda199bebe5a9baf f=895/0 m100fe=25
  #|pop qword ptr [rsi]|8f06|POP64rmm:%RSI,1,%,0,%|rbx=1 r9=2 f=c47 m10080=53046f77b2a10e1115434ecaf324385c|rsp=20108 f=c45/0 m10080=0762bd1873ce2984
  #|pop qword ptr [rsi]|8f06|POP64rmm:%RSI,1,%,0,%|rbx=6 r9=a f=882 m10080=4e1cc36e6a2e1da9a4e06576b68e87eb|rsp=20108 f=880/0 m10080=0762bd1873ce2984
  #|pop qword ptr [rsi + 0x10]|8f4610|POP64rmm:%RSI,1,%,16,%|rbx=3 r9=e f=16 m10090=8e0e959e0a6e1b15c8257f1d1171915a|rsp=20108 f=14/0 m10090=0762bd1873ce2984
  #|pop qword ptr [rsi + 0x10]|8f4610|POP64rmm:%RSI,1,%,16,%|rbx=e r9=3 f=87 m10090=68c0389601bbadc76fd34784c51c9057|rsp=20108 f=85/0 m10090=0762bd1873ce2984
  #|pop qword ptr [rdi + rbx*4 + 0x8]|8f449f08|POP64rmm:%RDI,4,%RBX,8,%|rbx=8 r9=c f=c7 m10128=e8f5c652af0894be9acb9d2ea0155f6e|rsp=20108 f=c5/0 m10128=0762bd1873ce2984
  #|pop qword ptr [rdi + rbx*4 + 0x8]|8f449f08|POP64rmm:%RDI,4,%RBX,8,%|rbx=0 r9=4 f=456 m10108=87e6850374616a2239f795289ceb2fba|rsp=20108 f=454/0 m10108=0762bd1873ce2984
  #|pop qword ptr [rsp + 0x8]|8f442408|POP64rmm:%RSP,1,%,8,%|rbx=d r9=1 f=4d7 m20108=e936c50a938e4fecfa2281788e93addf|rsp=20108 f=4d5/0 m20110=0762bd1873ce2984
  #|pop qword ptr [rsp + 0x8]|8f442408|POP64rmm:%RSP,1,%,8,%|rbx=1 r9=d f=456 m20108=c0a4b500174f02a1d9ffadc941df3347|rsp=20108 f=454/0 m20110=0762bd1873ce2984
  #|pop qword ptr [rsp]|8f0424|POP64rmm:%RSP,1,%,0,%|rbx=2 r9=0 f=c2 m20100=6edf9b3835c0c4acf7407ad22b412ddc|rsp=20108 f=c0/0 m20108=6edf9b3835c0c4ac
  #|pop qword ptr [rsp]|8f0424|POP64rmm:%RSP,1,%,0,%|rbx=a r9=0 f=3 m20100=79ffb35d0b4bf6883ce8af63a6bccf62|rsp=20108 f=1/0 m20108=79ffb35d0b4bf688
  #|pmuludq xmm11, xmm2|66440ff4da|PMULUDQrr:%XMM11,%XMM11,%XMM2|xmm2=392ff420268db314655c327910828b69 xmm11=939f3bfc7d35f57664c03fd5035d2e7 f=97|xmm11=1e17fb5ad51847cc052c4431a8e4edbf f=95/0
  #|pmuludq xmm11, xmm2|66440ff4da|PMULUDQrr:%XMM11,%XMM11,%XMM2|xmm2=ffffffffffffffffffffffffffffffff xmm11=ffffffffffffffffffffffffffffffff f=97|xmm11=fffffffe00000001fffffffe00000001 f=95/0
  #|pmuludq xmm11, xmm2|66440ff4da|PMULUDQrr:%XMM11,%XMM11,%XMM2|xmm2=4110a8be3665bb6ab0c271a8ea8a9484 xmm11=ef373365876ecbab7610686932d3d3d7 f=892|xmm11=1cc730d26f1d3dce2e91234f639786dc f=890/0
  #|pmuludq xmm11, xmmword ptr [rsi]|66440ff41e|PMULUDQrm:%XMM11,%XMM11,%RSI,1,%,0,%|rbx=1 xmm11=95e2fe228f71ac28b3eb284b6c70f3d8 f=2 m10080=1156afa003664a8222d527b199e9e08e|xmm11=6343e9c5836e25504410de12d612c158 f=0/0
  #|pmuludq xmm11, xmmword ptr [rdi + 0x10]|66440ff45f10|PMULUDQrm:%XMM11,%XMM11,%RDI,1,%,16,%|rbx=4 xmm11=30e5bc323d92e7446b522a5d464fd098 f=883 m10110=7df93811a8321a6372cf0ef12ed2ae95|xmm11=39fadba4de22f84804baf2d5b01cb238 f=881/0
  #|pmuludq xmm11, xmmword ptr [rsi + rbx*8 + 0x10]|66440ff45cde10|PMULUDQrm:%XMM11,%XMM11,%RSI,8,%RBX,16,%|rbx=2 xmm11=b6906bb15001326be95fe3111335edf5 f=806 m100a0=f1d77db17cb4b568c9e9e172a5356560|xmm11=23e72290dddef9030d51bb0ff63ec6a5 f=804/0
  #|pmuldq xmm1, xmm15|66410f3828cf|PMULDQrr:%XMM1,%XMM1,%XMM15|xmm1=80008000800080008000800080008000 xmm15=5290eed11065a8937c9f1118588c453d f=c6|xmm1=f7cd33e954498000d3ba09a7a29e8000 f=c4/0
  #|pmuldq xmm1, xmm15|66410f3828cf|PMULDQrr:%XMM1,%XMM1,%XMM15|xmm1=32c71d013061ac8e408475efd5098743 xmm15=97002f9ad37b6251f5f443648687a989 f=817|xmm1=f796262da52ff4ee1462b11cb2b99ddb f=815/0
  #|pmuldq xmm1, xmm15|66410f3828cf|PMULDQrr:%XMM1,%XMM1,%XMM15|xmm1=a8e9b86e837ae1941f23291ce650cf94 xmm15=0 f=893|xmm1=0 f=891/0
  #|pmuldq xmm1, xmmword ptr [rsi]|660f38280e|PMULDQrm:%XMM1,%XMM1,%RSI,1,%,0,%|rbx=1 xmm1=abe427d82ca1032320bde851bf8cd6d7 f=c03 m10080=424211939e85fced20826c4d9e56ed6f|xmm1=d7f588e317c2a601b6cb0326af9d16e f=c01/0
  #|pmuldq xmm1, xmmword ptr [rdi + 0x10]|660f38284f10|PMULDQrm:%XMM1,%XMM1,%RDI,1,%,16,%|rbx=4 xmm1=ffffffffffffffffffffffffffffffff f=8d2 m10110=b7c4b804335cc373f7897f3640ef69cc|xmm1=ffffffffc9807609fffffffffb473b49 f=8d0/0
  #|pmuldq xmm1, xmmword ptr [rsi + rbx*8 + 0x10]|660f38284cde10|PMULDQrm:%XMM1,%XMM1,%RSI,8,%RBX,16,%|rbx=0 xmm1=6674ba3d17af94db00abd7e113c1423d f=c3 m10090=31156d6f6c17be01d817e6e0416f5921|xmm1=fd1f57591f4745c8089936a44965aead f=c1/0
  #|packssdw xmm13, xmm10|66450f6bea|PACKSSDWrr:%XMM13,%XMM13,%XMM10|xmm10=80008000800080008000800080008000 xmm13=c1c1419d16b84d884b0ca3293b958b0f f=56|xmm13=800080008000800080007fff7fff7fff f=54/0
  #|packssdw xmm13, xmm10|66450f6bea|PACKSSDWrr:%XMM13,%XMM13,%XMM10|xmm10=2c1f7d74cd3c2c0a2c58dcaea5a2f152 xmm13=8aba649549903a2fffbb273575966364 f=887|xmm13=7fff80007fff800080007fff80007fff f=885/0
  #|packssdw xmm13, xmm10|66450f6bea|PACKSSDWrr:%XMM13,%XMM13,%XMM10|xmm10=21cbd0be8f6949233ea365c05af73ba0 xmm13=f06bf6b7e16b3d05a5f020442b9b2da f=8d2|xmm13=7fff80007fff7fff7fff7fff7fff7fff f=8d0/0
  #|packssdw xmm13, xmmword ptr [rsi]|66440f6b2e|PACKSSDWrm:%XMM13,%XMM13,%RSI,1,%,0,%|rbx=2 xmm13=4dc4eafe1daa70e66b37c26eec01e88b f=883 m10080=00acc3a22685a9bc1d48a1ca08484158|xmm13=7fff8000800080007fff7fff7fff8000 f=881/0
  #|packssdw xmm13, xmmword ptr [rdi + 0x10]|66440f6b6f10|PACKSSDWrm:%XMM13,%XMM13,%RDI,1,%,16,%|rbx=2 xmm13=ffffffffffffffffffffffffffffffff f=893 m10110=eb2945aa7b09737b14e3f81dd3c1e6d3|xmm13=80007fff7fff8000ffffffffffffffff f=891/0
  #|packssdw xmm13, xmmword ptr [rsi + rbx*8 + 0x10]|66440f6b6cde10|PACKSSDWrm:%XMM13,%XMM13,%RSI,8,%RBX,16,%|rbx=1 xmm13=73d431d7b8e674ae8b82b2f1792248b4 f=c3 m10098=fca213cedb173cb9140296a98516a9fd|xmm13=80008000800080007fff800080007fff f=c1/0
  #|packsswb xmm0, xmm2|660f63c2|PACKSSWBrr:%XMM0,%XMM0,%XMM2|xmm0=cf6c73acbf7439c75e5375988d031d7a xmm2=39e93d61c8d26d394d576813c5db3b49 f=47|xmm0=7f7f807f7f7f807f807f807f7f7f807f f=45/0
  #|packsswb xmm0, xmm2|660f63c2|PACKSSWBrr:%XMM0,%XMM0,%XMM2|xmm0=e1f80b716bc00f148ef5b36954aa703b xmm2=f1ef1d34d9845768e0df6265cb947c98 f=893|xmm0=807f807f807f807f807f7f7f80807f7f f=891/0
  #|packsswb xmm0, xmm2|660f63c2|PACKSSWBrr:%XMM0,%XMM0,%XMM2|xmm0=c57936224a6070baa587b0b6a1f1c5c9 xmm2=8cee406ca5f1cf424a60036d43bbb9ea f=c17|xmm0=807f80807f7f7f80807f7f7f80808080 f=c15/0
  #|packsswb xmm0, xmmword ptr [rsi]|660f6306|PACKSSWBrm:%XMM0,%XMM0,%RSI,1,%,0,%|rbx=1 xmm0=c88955a735e70ca80bcc0a4f7f781285 f=c6 m10080=85ef967be63bea58bdd98676233f694c|xmm0=7f7f7f807f7f7f80807f7f7f7f7f7f7f f=c4/0
  #|packsswb xmm0, xmmword ptr [rdi + 0x10]|660f634710|PACKSSWBrm:%XMM0,%XMM0,%RDI,1,%,16,%|rbx=0 xmm0=b9e4a071bf461662685fe2b9d2fbc3b9 f=882 m10110=df0483f4f69e5435f90431ae27c8a8d2|xmm0=8080807f7f80807f8080807f7f808080 f=880/0
  #|packsswb xmm0, xmmword ptr [rsi + rbx*8 + 0x10]|660f6344de10|PACKSSWBrm:%XMM0,%XMM0,%RSI,8,%RBX,16,%|rbx=0 xmm0=3e5161680e040ee9e7f0679a1f13b173 f=87 m10090=8d785a4cfde0ac94b5ee085b01f29c5e|xmm0=7f807f8080807f7f7f7f7f7f807f7f80 f=85/0
  #|packusdw xmm9, xmm11|66450f382bcb|PACKUSDWrr:%XMM9,%XMM9,%XMM11|xmm9=7ee86f2ba8cd54ce5ff5b75d3be6d55f xmm11=80008000800080008000800080008000 f=886|xmm9=ffff0000ffffffff f=884/0
  #|packusdw xmm9, xmm11|66450f382bcb|PACKUSDWrr:%XMM9,%XMM9,%XMM11|xmm9=3f3c48b3e857a007361e89993d27fc51 xmm11=80008000800080008000800080008000 f=8c7|xmm9=ffff0000ffffffff f=8c5/0
  #|packusdw xmm9, xmm11|66450f382bcb|PACKUSDWrr:%XMM9,%XMM9,%XMM11|xmm9=a94e82abcccc944cdd40a90af4103355 xmm11=4fe5f43900704b7037a4644eee45e2aa f=8c2|xmm9=ffffffffffff00000000000000000000 f=8c0/0
  #|packusdw xmm9, xmmword ptr [rsi]|66440f382b0e|PACKUSDWrm:%XMM9,%XMM9,%RSI,1,%,0,%|rbx=2 xmm9=8774b5a63152a8e71b994f69f0116504 f=816 m10080=1bded175a4b1399caf06f0ff04d11fd8|xmm9=ffff0000ffffffff0000 f=814/0
  #|packusdw xmm9, xmmword ptr [rdi + 0x10]|66440f382b4f10|PACKUSDWrm:%XMM9,%XMM9,%RDI,1,%,16,%|rbx=2 xmm9=f2c2280f6c2865f3b8a4e9a4780e4a11 f=c7 m10110=9247d1bfe5ea80be2412bed7774b9ba7|xmm9=ffff0000ffff f=c5/0
  #|packusdw xmm9, xmmword ptr [rsi + rbx*8 + 0x10]|66440f382b4cde10|PACKUSDWrm:%XMM9,%XMM9,%RSI,8,%RBX,16,%|rbx=1 xmm9=5507f0e04dc9e26997d08797d04ea1f f=c6 m10098=fe7b3d97f8d6ccaeaa6004d8f19f1c81|xmm9=ffffffff0000ffff f=c4/0
  #|packuswb xmm5, xmm2|660f67ea|PACKUSWBrr:%XMM5,%XMM5,%XMM2|xmm2=726c1466e5cfd6629aebbe9669333d46 xmm5=97895a0e48e33ca182776416c2006d9a f=856|xmm5=ffff00000000ffff00ffffff00ff00ff f=854/0
  #|packuswb xmm5, xmm2|660f67ea|PACKUSWBrr:%XMM5,%XMM5,%XMM2|xmm2=3237a10cc076dddf053ee0de43547dd2 xmm5=7e4cd08f0a5ef8df2b56e1452704745e f=896|xmm5=ff000000ff00ffffff00ff00ff00ffff f=894/0
  #|packuswb xmm5, xmm2|660f67ea|PACKUSWBrr:%XMM5,%XMM5,%XMM2|xmm2=0 xmm5=ffffffffffffffffffffffffffffffff f=456|xmm5=0 f=454/0
  #|packuswb xmm5, xmmword ptr [rsi]|660f672e|PACKUSWBrm:%XMM5,%XMM5,%RSI,1,%,0,%|rbx=0 xmm5=c197bd9d9e88dafcfd6ca7351d3a9d06 f=57 m10080=efcecf7ec171b178d777aa5ee545654b|xmm5=ffffffffffffff00000000000000ff00 f=55/0
  #|packuswb xmm5, xmmword ptr [rdi + 0x10]|660f676f10|PACKUSWBrm:%XMM5,%XMM5,%RDI,1,%,16,%|rbx=2 xmm5=e23ae83e33af3b266c0ad000d2bca1ba f=43 m10110=e6717f9b41169e00a0fa2ed602f3f51b|xmm5=ff0000009eff00ff0000ffffff000000 f=41/0
  #|packuswb xmm5, xmmword ptr [rsi + rbx*8 + 0x10]|660f676cde10|PACKUSWBrm:%XMM5,%XMM5,%RSI,8,%RBX,16,%|rbx=2 xmm5=5d5e680d7a183db4b5e6e1158fb6a7e0 f=4d7 m100a0=c3ecdbad8d64950cc0df3f095f0820b5|xmm5=ffff00ffff0000ffffffff00000000 f=4d5/0
  #|andps xmm3, xmm6|0f54de|ANDPSrr:%XMM3,%XMM3,%XMM6|xmm3=9e6aa1ec7da656452aa9ff2fda42168a xmm6=b032aefe0fc68726bdacd5b024ec9eb4 f=56|xmm3=9022a0ec0d86060428a8d52000401680 f=54/0
  #|andps xmm3, xmm6|0f54de|ANDPSrr:%XMM3,%XMM3,%XMM6|xmm3=4ed8aa2618d0877046b9021647a48499 xmm6=3aa969feabc1350acca9ce23fa19c4d1 f=846|xmm3=a88282608c0050044a9020242008491 f=844/0
  #|andps xmm3, xmm6|0f54de|ANDPSrr:%XMM3,%XMM3,%XMM6|xmm3=a86ed4a90bc7c50b2e3ad0a808e05ac2 xmm6=58b1dcfb0d7c7d325e04b2e5e497b737 f=6|xmm3=820d4a9094445020e0090a000801202 f=4/0
  #|andps xmm3, xmmword ptr [rsi]|0f541e|ANDPSrm:%XMM3,%XMM3,%RSI,1,%,0,%|rbx=1 xmm3=cfff06daf4c6e64f924378470274917d f=802 m10080=86afe231457d8453ea00b9d4b8125f8d|xmm3=8d5f0298d480004a1200784500608104 f=800/0
  #|andps xmm3, xmmword ptr [rdi + 0x10]|0f545f10|ANDPSrm:%XMM3,%XMM3,%RDI,1,%,16,%|rbx=4 xmm3=fb86fc39be34a10726d8790572f403a3 f=93 m10110=2b6008f8c7981574178758a8a6f379d2|xmm3=d200f020a81081072410180570000023 f=91/0
  #|andps xmm3, xmmword ptr [rsi + rbx*8 + 0x10]|0f545cde10|ANDPSrm:%XMM3,%XMM3,%RSI,8,%RBX,16,%|rbx=2 xmm3=ca840074b3b7c4140a77bcab1e39983b f=803 m100a0=1194788b9c89b9c74566b49ae49d01d0|xmm3=c000006492b44404023188880a389011 f=801/0
  #|andpd xmm9, xmm10|66450f54ca|ANDPDrr:%XMM9,%XMM9,%XMM10|xmm9=dd3d489e314df6585c9231c146f62328 xmm10=3b1adce0b8016575796da1f9603f8b2 f=846|xmm9=131088e010016505492100106022020 f=844/0
  #|andpd xmm9, xmm10|66450f54ca|ANDPDrr:%XMM9,%XMM9,%XMM10|xmm9=ae3a7d97181eef52044128c5c372d07e xmm10=cf5f1379d5f7ba05f6675794349c0694 f=16|xmm9=8e1a11111016aa000441008400100014 f=14/0
  #|andpd xmm9, xmm10|66450f54ca|ANDPDrr:%XMM9,%XMM9,%XMM10|xmm9=1c7588c5f330c1595aadf14cd8ca2886 xmm10=9a28ded6618ac355f5f2afcac374877c f=8d3|xmm9=182088c46100c15150a0a148c0400004 f=8d1/0
  #|andpd xmm9, xmmword ptr [rsi]|66440f540e|ANDPDrm:%XMM9,%XMM9,%RSI,1,%,0,%|rbx=4 xmm9=f0e0960950092da4879fbd6e6a54a82d f=857 m10080=5731fbb8f6ca4cb75ab5110def76cdaa|xmm9=a0c0160900012500870c886628502005 f=855/0
  #|andpd xmm9, xmmword ptr [rdi + 0x10]|66440f544f10|ANDPDrm:%XMM9,%XMM9,%RDI,1,%,16,%|rbx=1 xmm9=fabb46870d0f90e8757cd368790f7342 f=886 m10110=6e673d4644eaaf3ddb13cbf93d91a4cf|xmm9=caa00005090b10c8352cc240400d6342 f=884/0
  #|andpd xmm9, xmmword ptr [rsi + rbx*8 + 0x10]|66440f544cde10|ANDPDrm:%XMM9,%XMM9,%RSI,8,%RBX,16,%|rbx=1 xmm9=6dfe3bda956a2a986b2e5ca027451c1f f=853 m10098=7558da9538107c122897811a2f9a6ff9|xmm9=696e1a0a10000208022c102005401815 f=851/0
  #|orps xmm10, xmm12|450f56d4|ORPSrr:%XMM10,%XMM10,%XMM12|xmm10=0 xmm12=0 f=8c3|f=8c1/0
  #|orps xmm10, xmm12|450f56d4|ORPSrr:%XMM10,%XMM10,%XMM12|xmm10=a73130ebf02d066ee250ebc7ee1a25ef xmm12=3db0dd02d79ef92e3ac529bafba29410 f=c6|xmm10=bfb1fdebf7bfff6efad5ebffffbab5ff f=c4/0
  #|orps xmm10, xmm12|450f56d4|ORPSrr:%XMM10,%XMM10,%XMM12|xmm10=ffffffffffffffffffffffffffffffff xmm12=744f3e88ece1fe4e4f9c2aa21389b405 f=46|f=44/0
  #|orps xmm10, xmmword ptr [rsi]|440f5616|ORPSrm:%XMM10,%XMM10,%RSI,1,%,0,%|rbx=0 xmm10=96c6758ea761e83719637f7a7832ce84 f=c57 m10080=a11df73dc673632e00dfcf7d0b034e00|xmm10=96ce778fffefff373f637ffe7df7dfa5 f=c55/0
  #|orps xmm10, xmmword ptr [rdi + 0x10]|440f565710|ORPSrm:%XMM10,%XMM10,%RDI,1,%,16,%|rbx=2 xmm10=0 f=83 m10110=e856c081fb84e01f49f5b8673193ad1d|xmm10=1dad933167b8f5491fe084fb81c056e8 f=81/0
  #|orps xmm10, xmmword ptr [rsi + rbx*8 + 0x10]|440f5654de10|ORPSrm:%XMM10,%XMM10,%RSI,8,%RBX,16,%|rbx=0 xmm10=274be17c8eb570cae854c91baf7dfc06 f=d7 m10090=17f7daefd81c6d435f30860dbd38b1e4|xmm10=e7fbf9fd8fb770dfeb7ddddbefffff17 f=d5/0
  #|orpd xmm14, xmm6|66440f56f6|ORPDrr:%XMM14,%XMM14,%XMM6|xmm6=2112fc744413fb4a4dc26f6f0509dc7b xmm14=e01d158d174908baba0bb504001d707 f=7|xmm14=2f13fd7cd577fbcbefe2ff7f4509df7f f=5/0
  #|orpd xmm14, xmm6|66440f56f6|ORPDrr:%XMM14,%XMM14,%XMM6|xmm6=e44165549d15c558a23272fe9ea9fe98 xmm14=0 f=cc6|xmm14=e44165549d15c558a23272fe9ea9fe98 f=cc4/0
  #|orpd xmm14, xmm6|66440f56f6|ORPDrr:%XMM14,%XMM14,%XMM6|xmm6=6590f4a866d97b34fdd06fce960db977 xmm14=19a779265f1af9751da1094829121cf f=887|xmm14=659af7ba67f9ffb7fdda7fde969db9ff f=885/0
  #|orpd xmm14, xmmword ptr [rsi]|66440f5636|ORPDrm:%XMM14,%XMM14,%RSI,1,%,0,%|rbx=1 xmm14=c761d1803bc3b7be021929b599fc7a5d f=8c6 m10080=8602c77af1220fe73dc2367b942bf98a|xmm14=cff9fb947bf7f7bfe71f2bf5fbff7adf f=8c4/0
  #|orpd xmm14, xmmword ptr [rdi + 0x10]|66440f567710|ORPDrm:%XMM14,%XMM14,%RDI,1,%,16,%|rbx=2 xmm14=32defbe9e08f3457d5ddfeca8562cef1 f=4d2 m10110=17ef95f8c46162946e983e4f5191dd22|xmm14=32dffbf9efbfbc7fd5ffffcefdf7eff7 f=4d0/0
  #|orpd xmm14, xmmword ptr [rsi + rbx*8 + 0x10]|66440f5674de10|ORPDrm:%XMM14,%XMM14,%RSI,8,%RBX,16,%|rbx=0 xmm14=d7072c98729ace49e43e2afa61644cb f=406 m10090=9745c3c8163dc9083a979e203e1e0f7e|xmm14=7f7f7effa7bfbffe9ecbffbfeed745df f=404/0
  #|xorps xmm9, xmm13|450f57cd|XORPSrr:%XMM9,%XMM9,%XMM13|xmm9=423dc7c3ca4e72e164574ca946211c64 xmm13=6903b9e69997371cbea1b6b8da67b12f f=443|xmm9=2b3e7e2553d945fddaf6fa119c46ad4b f=441/0
  #|xorps xmm9, xmm13|450f57cd|XORPSrr:%XMM9,%XMM9,%XMM13|xmm9=dcba3314df530d3774414f833ecded88 xmm13=5989ee7c2289708d970077ea03ece617 f=d2|xmm9=8533dd68fdda7dbae34138693d210b9f f=d0/0
  #|xorps xmm9, xmm13|450f57cd|XORPSrr:%XMM9,%XMM9,%XMM13|xmm9=d9d30d42ddabb01f663e77f3ea42c3b6 xmm13=0 f=17|f=15/0
  #|xorps xmm9, xmmword ptr [rsi]|440f570e|XORPSrm:%XMM9,%XMM9,%RSI,1,%,0,%|rbx=0 xmm9=80008000800080008000800080008000 f=93 m10080=fc3ec79145223c3e6be12de88a71a55f|xmm9=dfa5f18a682d616bbe3ca24511c7befc f=91/0
  #|xorps xmm9, xmmword ptr [rdi + 0x10]|440f574f10|XORPSrm:%XMM9,%XMM9,%RDI,1,%,16,%|rbx=1 xmm9=e961bda8750c901ad1d8909309cf98f4 f=12 m10110=2c9bcfc9cb4eb2647a9cf9923c08c9ad|xmm9=44a8b594e7f50c60b56ade58c00003d8 f=10/0
  #|xorps xmm9, xmmword ptr [rsi + rbx*8 + 0x10]|440f574cde10|XORPSrm:%XMM9,%XMM9,%RSI,8,%RBX,16,%|rbx=1 xmm9=af2afa0802d7c0aba5a028c6a5c70f0c f=c87 m10098=c51a42682a782082ae9380c9184cca85|xmm9=2ae0b610cb575305278050eccd8515c9 f=c85/0
  #|xorpd xmm14, xmm11|66450f57f3|XORPDrr:%XMM14,%XMM14,%XMM11|xmm11=91a33a6db66b9524784d8481dc62388b xmm14=3515de62dfd86a011d20a6180cbac321 f=cc2|xmm14=a4b6e40f69b3ff25656d2299d0d8fbaa f=cc0/0
  #|xorpd xmm14, xmm11|66450f57f3|XORPDrr:%XMM14,%XMM14,%XMM11|xmm11=d4daca31bffbeb0c662a398518467b86 xmm14=ffffffffffffffffffffffffffffffff f=86|xmm14=2b2535ce400414f399d5c67ae7b98479 f=84/0
  #|xorpd xmm14, xmm11|66450f57f3|XORPDrr:%XMM14,%XMM14,%XMM11|xmm11=169464a847fe0272bc7e3079931368f6 xmm14=ffffffffffffffffffffffffffffffff f=42|xmm14=e96b9b57b801fd8d4381cf866cec9709 f=40/0
  #|xorpd xmm14, xmmword ptr [rsi]|66440f5736|XORPDrm:%XMM14,%XMM14,%RSI,1,%,0,%|rbx=0 xmm14=80008000800080008000800080008000 f=12 m10080=13ff59b2e86e597aceb2342647224c4e|xmm14=ce4ca247a63432cefa59eee832597f13 f=10/0
  #|xorpd xmm14, xmmword ptr [rdi + 0x10]|66440f577710|XORPDrm:%XMM14,%XMM14,%RDI,1,%,16,%|rbx=0 xmm14=8dfd9c7fcc24865409c680938fbb0817 f=c2 m10110=e7eaaca412693b2cf1c1631c5af0238e|xmm14=3de6c25d04747a525fde9812b17e2f0 f=c0/0
  #|xorpd xmm14, xmmword ptr [rsi + rbx*8 + 0x10]|66440f5774de10|XORPDrm:%XMM14,%XMM14,%RSI,8,%RBX,16,%|rbx=0 xmm14=ca3d2d43d054a332625f8a3d3cb97e84 f=8c2 m10090=a07e9951ea0cb6000218e8bfdb80b91b|xmm14=d184ad986fbcbb3062e986d76d200024 f=8c0/0
  #|andnps xmm4, xmm1|0f55e1|ANDNPSrr:%XMM4,%XMM4,%XMM1|xmm1=0 xmm4=b0b2e4247712344878e19a5fe02da3a f=482|xmm4=0 f=480/0
  #|andnps xmm4, xmm1|0f55e1|ANDNPSrr:%XMM4,%XMM4,%XMM1|xmm1=20423710861b3fe2a9e0720836ca39c1 xmm4=928059d7497dd168d1a9817f372671ed f=93|xmm4=2042260086022e822840720000c80800 f=91/0
  #|andnps xmm4, xmm1|0f55e1|ANDNPSrr:%XMM4,%XMM4,%XMM1|xmm1=820223083533f5ca64b61e32663d921c xmm4=80e33a92ff843d7979c35e20493078c8 f=c13|xmm4=20001080033c08204340012260d8214 f=c11/0
  #|andnps xmm4, xmmword ptr [rsi]|0f5526|ANDNPSrm:%XMM4,%XMM4,%RSI,1,%,0,%|rbx=4 xmm4=4f6b78dd4951718cc883edbce48485a3 f=42 m10080=dcf6a36342c93b2c9cd86b17aafa0285|xmm4=80008222162a8810243800420323725c f=40/0
  #|andnps xmm4, xmmword ptr [rdi + 0x10]|0f556710|ANDNPSrm:%XMM4,%XMM4,%RDI,1,%,16,%|rbx=4 xmm4=0 f=842 m10110=bf097950ccad111ff4a815f8c03273a7|xmm4=a77332c0f815a8f41f11adcc507909bf f=840/0
  #|andnps xmm4, xmmword ptr [rsi + rbx*8 + 0x10]|0f5564de10|ANDNPSrm:%XMM4,%XMM4,%RSI,8,%RBX,16,%|rbx=4 xmm4=df9be089929e81dabd8afbf43b3b079e f=83 m100b0=568abb143fbfd47039a9a72e7d324773|xmm4=204412742c2128214054040b04808840 f=81/0
  #|andnpd xmm8, xmm11|66450f55c3|ANDNPDrr:%XMM8,%XMM8,%XMM11|xmm8=80008000800080008000800080008000 xmm11=d604153b6bb7e8fefb5167c88b1acf87 f=8c2|xmm8=5604153b6bb768fe7b5167c80b1a4f87 f=8c0/0
  #|andnpd xmm8, xmm11|66450f55c3|ANDNPDrr:%XMM8,%XMM8,%XMM11|xmm8=50440f4b0405d3dd419341c8ea12ac15 xmm11=73e1c2fe7753fb78b22382ec11239faf f=3|xmm8=23a1c0b473522820b2208224112113aa f=1/0
  #|andnpd xmm8, xmm11|66450f55c3|ANDNPDrr:%XMM8,%XMM8,%XMM11|xmm8=dab6cb785bea971590f335ce67864242 xmm11=5faaa6ea634891f1551c03b3e5946b30 f=817|xmm8=5082482200000e0450c023180102930 f=815/0
  #|andnpd xmm8, xmmword ptr [rsi]|66440f5506|ANDNPDrm:%XMM8,%XMM8,%RSI,1,%,0,%|rbx=0 xmm8=a2f3d90994487a54d10db5a690cbd2c2 f=886 m10080=427560cd32070ede3fbf1d294bcff42f|xmm8=d0406422915852b0e0202104d202500 f=884/0
  #|andnpd xmm8, xmmword ptr [rdi + 0x10]|66440f554710|ANDNPDrm:%XMM8,%XMM8,%RDI,1,%,16,%|rbx=2 xmm8=0 f=42 m10110=b698bf96e378477f316521c9daf71832|xmm8=3218f7dac92165317f4778e396bf98b6 f=40/0
  #|andnpd xmm8, xmmword ptr [rsi + rbx*8 + 0x10]|66440f5544de10|ANDNPDrm:%XMM8,%XMM8,%RSI,8,%RBX,16,%|rbx=2 xmm8=693fc4aae8720ebd41b4941fcb93fc02 f=406 m100a0=8d6e0735befb7c0d6ad6c0c06c52f0d1|xmm8=90c012440080d0420c486ba03404028d f=404/0
  #|shufps xmm9, xmm5, 0|440fc6cd00|SHUFPSrri:%XMM9,%XMM9,%XMM5,0|xmm5=d72976c5d265f45ced5c64fb1b815f56 xmm9=ffffffffffffffffffffffffffffffff f=443|xmm9=1b815f561b815f56ffffffffffffffff f=441/0
  #|shufps xmm9, xmmword ptr [rsi + rbx*8 + 0x10], 0|440fc64cde1000|SHUFPSrmi:%XMM9,%XMM9,%RSI,8,%RBX,16,%,0|rbx=1 xmm9=b55e434ddf26eb5a032b9bb788d96f74 f=846 m10098=298ef6caedb43422c26524a5732e68cf|xmm9=caf68e29caf68e2988d96f7488d96f74 f=844/0
  #|shufps xmm2, xmm14, 27|410fc6d61b|SHUFPSrri:%XMM2,%XMM2,%XMM14,27|xmm2=ffffffffffffffffffffffffffffffff xmm14=aeff1f1abebddac85ce4b5db2227bb3f f=12|xmm2=2227bb3f5ce4b5dbffffffffffffffff f=10/0
  #|shufps xmm2, xmmword ptr [rsi + rbx*8 + 0x10], 27|0fc654de101b|SHUFPSrmi:%XMM2,%XMM2,%RSI,8,%RBX,16,%,27|rbx=4 xmm2=70b57b6a9343b0892b976d69f64bd9d f=42 m100b0=55c4c0aca458048c02471a7caa88ef23|xmm2=acc0c4558c0458a4a9343b08070b57b6 f=40/0
  #|shufps xmm15, xmm9, 78|450fc6f94e|SHUFPSrri:%XMM15,%XMM15,%XMM9,78|xmm9=d46f1cac7c40d8118cbcc809d03348ec xmm15=f6d729b8dd118fcede15b15d0d207b24 f=847|xmm15=8cbcc809d03348ecf6d729b8dd118fce f=845/0
  #|shufps xmm15, xmmword ptr [rsi + rbx*8 + 0x10], 78|440fc67cde104e|SHUFPSrmi:%XMM15,%XMM15,%RSI,8,%RBX,16,%,78|rbx=0 xmm15=8acc85ed7395053e2805912193d18450 f=6 m10090=c4f621f111aa3c9b5fad37b0c7efdd7a|xmm15=9b3caa11f121f6c48acc85ed7395053e f=4/0
  #|shufps xmm10, xmm1, 228|440fc6d1e4|SHUFPSrri:%XMM10,%XMM10,%XMM1,228|xmm1=679bffd94c0843eacece3c28972d6349 xmm10=0 f=c6|xmm10=679bffd94c0843ea0000000000000000 f=c4/0
  #|shufps xmm10, xmmword ptr [rsi + rbx*8 + 0x10], 228|440fc654de10e4|SHUFPSrmi:%XMM10,%XMM10,%RSI,8,%RBX,16,%,228|rbx=0 xmm10=c46a2d0bb69fcaf4b5563a6991ac8822 f=8c3 m10090=9627ae6383153099d0f40ea18c75e41c|xmm10=1ce4758ca10ef4d0b5563a6991ac8822 f=8c1/0
  #|shufps xmm5, xmm11, 50|410fc6eb32|SHUFPSrri:%XMM5,%XMM5,%XMM11,50|xmm5=ffffffffffffffffffffffffffffffff xmm11=98f6a297d737e5bcd03162c8c7a7f092 f=482|xmm5=c7a7f09298f6a297ffffffffffffffff f=480/0
  #|shufps xmm5, xmmword ptr [rsi + rbx*8 + 0x10], 50|0fc66cde1032|SHUFPSrmi:%XMM5,%XMM5,%RSI,8,%RBX,16,%,50|rbx=2 xmm5=f626ee87bda35c9851e48d97c3a187d2 f=8d7 m100a0=88e0cdfc535ba0741e6bd4e0afcb34bb|xmm5=fccde088bb34cbafc3a187d2bda35c98 f=8d5/0
  #|shufps xmm2, xmm1, 255|0fc6d1ff|SHUFPSrri:%XMM2,%XMM2,%XMM1,255|xmm1=ffffffffffffffffffffffffffffffff xmm2=5c8ba30aed6d8635e18ff29222117f06 f=c12|xmm2=ffffffffffffffff5c8ba30a5c8ba30a f=c10/0
  #|shufps xmm2, xmmword ptr [rsi + rbx*8 + 0x10], 255|0fc654de10ff|SHUFPSrmi:%XMM2,%XMM2,%RSI,8,%RBX,16,%,255|rbx=0 xmm2=ffffffffffffffffffffffffffffffff f=482 m10090=b8adbb91bd6f38a02c9dc5b28b95e524|xmm2=24e5958b24e5958bffffffffffffffff f=480/0
  #|shufps xmm3, xmm12, 202|410fc6dcca|SHUFPSrri:%XMM3,%XMM3,%XMM12,202|xmm3=37f66eac851a041bb28682da65443951 xmm12=5740e3438a7de28c4a17823c2a634074 f=412|xmm3=5740e3432a634074851a041b851a041b f=410/0
  #|shufps xmm3, xmmword ptr [rsi + rbx*8 + 0x10], 202|0fc65cde10ca|SHUFPSrmi:%XMM3,%XMM3,%RSI,8,%RBX,16,%,202|rbx=1 xmm3=b1bcd5a26716f4c33a4469088189aec4 f=86 m10098=51a717142ee78e596e935a55927aa685|xmm3=85a67a921417a7516716f4c36716f4c3 f=84/0
  #|movntdq xmmword ptr [rsi], xmm5|660fe72e|MOVNTDQmr:%RSI,1,%,0,%,%XMM5|rbx=0 xmm5=0 f=487 m10080=8640fda393c038c3c31c86fb13e737bd|f=485/0 m10080=00000000000000000000000000000000
  #|movntdq xmmword ptr [rdi + 0x10], xmm5|660fe76f10|MOVNTDQmr:%RDI,1,%,16,%,%XMM5|rbx=0 xmm5=801763d71d3bbb2c3c932e2961803a06 f=c03 m10110=e7cede88602f21ed1ee76e3063258649|f=c01/0 m10110=063a8061292e933c2cbb3b1dd7631780
  #|movntdq xmmword ptr [rsi + rbx*8 + 0x10], xmm5|660fe76cde10|MOVNTDQmr:%RSI,8,%RBX,16,%,%XMM5|rbx=1 xmm5=6e842f67062655407c2d88e4676a5520 f=cc2 m10098=c5e5b491d67780ab2fda63d65bc24167|f=cc0/0 m10098=20556a67e4882d7c40552606672f846e

///|
let lisp32_cases : String =
  #|xchg al, bl|86c3|XCHG8rr:%AL,%BL,%AL,%BL|eax=ffffffff edx=c81398f7 ebx=84ad2c80 f=813|eax=ffffff80 ebx=84ad2cff f=811/0
  #|xchg al, bl|86c3|XCHG8rr:%AL,%BL,%AL,%BL|eax=0 edx=b3be970f ebx=326be88 f=53|eax=88 ebx=326be00 f=51/0
  #|xchg ch, dl|86ea|XCHG8rr:%CH,%DL,%CH,%DL|eax=d9c9 ecx=1aeec6fc edx=d7e99719 f=43|ecx=1aee19fc edx=d7e997c6 f=41/0
  #|xchg ch, dl|86ea|XCHG8rr:%CH,%DL,%CH,%DL|eax=6dd00f92 ecx=96601e17 edx=dc9c272e f=886|ecx=96602e17 edx=dc9c271e f=884/0
  #|xchg ah, bh|86e7|XCHG8rr:%AH,%BH,%AH,%BH|eax=95 ecx=a53e8000 ebx=d609676f f=843|eax=6795 ebx=d609006f f=841/0
  #|xchg ah, bh|86e7|XCHG8rr:%AH,%BH,%AH,%BH|eax=d5c48405 ecx=565bb163 ebx=3 f=843|eax=d5c40005 ebx=8403 f=841/0
  #|xchg byte ptr [esi], cl|860e|XCHG8rm:%CL,%CL,%ESI,1,%,0,%|ecx=d8647fff edx=4c9f46ad ebx=3 f=d6 m10080=a428a67137ed72aaf56ef7072c413e11|ecx=d8647fa4 f=d4/0 m10080=ff
  #|xchg byte ptr [esi], cl|860e|XCHG8rm:%CL,%CL,%ESI,1,%,0,%|eax=8ba2 ecx=3 ebx=4 f=d3 m10080=0cf2d0b5aae9e510a4632d471fe3a409|ecx=c f=d1/0 m10080=03
  #|xchg byte ptr [edi + 0x10], cl|864f10|XCHG8rm:%CL,%CL,%EDI,1,%,16,%|eax=1ad7bc0d ecx=58 ebx=6 f=17 m10110=e3bae46424c9bf2020987203dbbe65a5|ecx=e3 f=15/0 m10110=58
  #|xchg byte ptr [edi + 0x10], cl|864f10|XCHG8rm:%CL,%CL,%EDI,1,%,16,%|eax=914d28c ecx=714de4fb ebx=d f=857 m10110=0fd68b864afbb722eb0c74f6ba633d24|ecx=714de40f f=855/0 m10110=fb
  #|xchg byte ptr [ebp - 0x20], cl|864de0|XCHG8rm:%CL,%CL,%EBP,1,%,-32,%|eax=a380d9eb ecx=fffffffe edx=11c8253a ebx=0 f=82 m20160=290ee999ee7e9cd92f223364ed6ca514|ecx=ffffff29 f=80/0 m20160=fe
  #|xchg byte ptr [ebp - 0x20], cl|864de0|XCHG8rm:%CL,%CL,%EBP,1,%,-32,%|eax=903486de ecx=e30c3c73 edx=1 ebx=6 f=2 m20160=23fc72bbad33ddc041a89157acdea504|ecx=e30c3c23 f=0/0 m20160=73
  #|xchg byte ptr [esi + ebx*4 + 0x8], cl|864c9e08|XCHG8rm:%CL,%CL,%ESI,4,%EBX,8,%|eax=3e95923d ecx=fa6907b5 edx=6a901fb4 ebx=8 f=8c7 m100a8=9d4bb441c24c335b42a4cb9a27963bff|ecx=fa69079d f=8c5/0 m100a8=b5
  #|xchg byte ptr [esi + ebx*4 + 0x8], cl|864c9e08|XCHG8rm:%CL,%CL,%ESI,4,%EBX,8,%|eax=b3e5d7b9 ecx=ffffffff edx=ce82 ebx=6 f=42 m100a0=9120db6a9cc671d197d11b6930cf4f0d|ecx=ffffff91 f=40/0 m100a0=ff
  #|xchg byte ptr [esp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%ESP,1,%,8,%|ecx=ff7ec061 edx=580832ad ebx=9 f=812 m20108=383259626e9be2fde4403debf9e38269|ecx=ff7ec038 f=810/0 m20108=61
  #|xchg byte ptr [esp + 0x8], cl|864c2408|XCHG8rm:%CL,%CL,%ESP,1,%,8,%|ecx=95 edx=91e16161 ebx=6 f=2 m20108=75560fe49b76ba6162eadcb0df8fc059|ecx=75 f=0/0 m20108=95
  #|popal|61|POPA32:|f=17|eax=cb156fb ecx=a045ea8f edx=34d97e23 ebx=c86d12b7 esp=20120 ebp=f0953adf esi=8429ce73 edi=18bd6207 f=15/0
  #|popal|61|POPA32:|f=c07|eax=cb156fb ecx=a045ea8f edx=34d97e23 ebx=c86d12b7 esp=20120 ebp=f0953adf esi=8429ce73 edi=18bd6207 f=c05/0
  #|popal|61|POPA32:|f=43|eax=cb156fb ecx=a045ea8f edx=34d97e23 ebx=c86d12b7 esp=20120 ebp=f0953adf esi=8429ce73 edi=18bd6207 f=41/0
