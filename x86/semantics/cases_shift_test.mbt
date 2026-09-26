// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let shift64_cases : String =
  #|shl dl, 1|d0e2|SHL8r1:%DL,%DL|rdx=9a5d439cc9026cad f=13|rdx=9a5d439cc9026c5a f=805/10
  #|shl dl, 1|d0e2|SHL8r1:%DL,%DL|rdx=94662248647455b3 f=86|rdx=9466224864745566 f=805/10
  #|shl dl, cl|d2e2|SHL8rCL:%DL,%DL|rcx=3 rdx=2696bd44b80f33f8 f=8c3|rdx=2696bd44b80f33c0 f=85/810
  #|shl dl, cl|d2e2|SHL8rCL:%DL,%DL|rcx=3 rdx=eaae453911e83e76 f=d3|rdx=eaae453911e83eb0 f=81/810
  #|shl dl, cl|d2e2|SHL8rCL:%DL,%DL|rcx=0 rdx=f6399ca95b32f17a f=887|f=885/0
  #|shl dl, cl|d2e2|SHL8rCL:%DL,%DL|rcx=4 rdx=a51a4cc073096dc1 f=813|rdx=a51a4cc073096d10 f=0/810
  #|shl dl, cl|d2e2|SHL8rCL:%DL,%DL|rcx=6 rdx=8000000000000000 f=6|f=44/810
  #|shl dl, 0|c0e200|SHL8ri:%DL,%DL,0|rdx=a9e006d302424ccd f=82|f=80/0
  #|shl dl, 0|c0e200|SHL8ri:%DL,%DL,0|rdx=90cd08e274fa91ac f=843|f=841/0
  #|shl dl, 7|c0e207|SHL8ri:%DL,%DL,7|rdx=7f f=492|rdx=80 f=481/810
  #|shl dl, 7|c0e207|SHL8ri:%DL,%DL,7|rdx=79860cf8684a1b4f f=c7|rdx=79860cf8684a1b80 f=81/810
  #|shl dl, 8|c0e208|SHL8ri:%DL,%DL,8|rdx=ffffffff f=813|rdx=ffffff00 f=845/811
  #|shl dl, 8|c0e208|SHL8ri:%DL,%DL,8|rdx=8000000000000000 f=87|f=44/811
  #|shl dl, 9|c0e209|SHL8ri:%DL,%DL,9|rdx=50 f=c3|rdx=0 f=44/811
  #|shl dl, 9|c0e209|SHL8ri:%DL,%DL,9|rdx=eccffa9e582936fd f=492|rdx=eccffa9e58293600 f=444/811
  #|shl dl, 31|c0e21f|SHL8ri:%DL,%DL,31|rdx=ef677fc4ddc8247a f=883|rdx=ef677fc4ddc82400 f=44/811
  #|shl dl, 31|c0e21f|SHL8ri:%DL,%DL,31|rdx=683d958d4f0794d1 f=c6|rdx=683d958d4f079400 f=44/811
  #|shl byte ptr [rsi + rbx*4 + 0x8], 1|d0649e08|SHL8m1:%RSI,4,%RBX,8,%|rbx=4 r9=1 f=896 m10098=58b8f5fdc81e068766389977648d52e2|f=880/10 m10098=b0
  #|shl byte ptr [rsi + rbx*4 + 0x8], 1|d0649e08|SHL8m1:%RSI,4,%RBX,8,%|rbx=f r9=e f=803 m100c4=08095d2ded2271acd9edecf161700921|f=0/10 m100c4=10
  #|shl byte ptr [rsi + rbx*4 + 0x8], cl|d2649e08|SHL8mCL:%RSI,4,%RBX,8,%|rcx=19 rbx=e r9=5 f=892 m100c0=a61a76c94ccf2a07c6d5417d920d22b4|f=44/811 m100c0=00
  #|shl byte ptr [rsi + rbx*4 + 0x8], cl|d2649e08|SHL8mCL:%RSI,4,%RBX,8,%|rcx=14 rbx=2 r9=5 f=8d2 m10090=fa9bc3bf85bfc201871aa6cfe3000bb1|f=44/811 m10090=00
  #|shl byte ptr [rsi + rbx*4 + 0x8], cl|d2649e08|SHL8mCL:%RSI,4,%RBX,8,%|rcx=1 rbx=6 r9=3 f=887 m100a0=c34939f1adfed19a2a1c28d01bad2e42|f=81/10 m100a0=86
  #|shl byte ptr [rsi + rbx*4 + 0x8], cl|d2649e08|SHL8mCL:%RSI,4,%RBX,8,%|rcx=e rbx=b r9=6 f=487 m100b4=cbcbf46231d5eb4c45543119a9a9b96b|f=444/811 m100b4=00
  #|shl byte ptr [rsi + rbx*4 + 0x8], 5|c0649e0805|SHL8mi:%RSI,4,%RBX,8,%,5|rbx=e r9=c f=43 m100c0=2672e509479e71b1ea827bbe3a9c3f5a|f=884/810 m100c0=c0
  #|shl byte ptr [rsi + rbx*4 + 0x8], 5|c0649e0805|SHL8mi:%RSI,4,%RBX,8,%,5|rbx=5 r9=7 f=893 m1009c=d3ed2d3610684f22dccf53d822f614b7|f=4/810 m1009c=60
  #|shl r8w, 1|6641d1e0|SHL16r1:%R8W,%R8W|r8=66935b2f369a44fc f=96|r8=66935b2f369a89f8 f=880/10
  #|shl r8w, 1|6641d1e0|SHL16r1:%R8W,%R8W|r8=2c525836b9f181ea f=c6|r8=2c525836b9f103d4 f=805/10
  #|shl r8w, cl|6641d3e0|SHL16rCL:%R8W,%R8W|rcx=3 r8=0 f=93|f=44/810
  #|shl r8w, cl|6641d3e0|SHL16rCL:%R8W,%R8W|rcx=6 r8=77d88a3ca46a75d5 f=c2|r8=77d88a3ca46a7540 f=801/810
  #|shl r8w, cl|6641d3e0|SHL16rCL:%R8W,%R8W|rcx=1f r8=d37f40a977a4080 f=7|r8=d37f40a977a0000 f=44/811
  #|shl r8w, cl|6641d3e0|SHL16rCL:%R8W,%R8W|rcx=20 r8=4447008816a49821 f=807|f=805/0
  #|shl r8w, cl|6641d3e0|SHL16rCL:%R8W,%R8W|rcx=0 r8=4a36ef27d4d0a803 f=97|f=95/0
  #|shl r8w, 0|6641c1e000|SHL16ri:%R8W,%R8W,0|r8=7fffffff f=457|f=455/0
  #|shl r8w, 0|6641c1e000|SHL16ri:%R8W,%R8W,0|r8=628275c264534ea1 f=806|f=804/0
  #|shl r8w, 4|6641c1e004|SHL16ri:%R8W,%R8W,4|r8=8000000000000000 f=97|f=44/810
  #|shl r8w, 4|6641c1e004|SHL16ri:%R8W,%R8W,4|r8=ec58fe79879da4f3 f=887|r8=ec58fe79879d4f30 f=4/810
  #|shl r8w, 15|6641c1e00f|SHL16ri:%R8W,%R8W,15|r8=421192e4da507fff f=492|r8=421192e4da508000 f=485/810
  #|shl r8w, 15|6641c1e00f|SHL16ri:%R8W,%R8W,15|r8=ee8dc9393ab58b7b f=8d6|r8=ee8dc9393ab58000 f=85/810
  #|shl r8w, 16|6641c1e010|SHL16ri:%R8W,%R8W,16|r8=9efeed6b54ba027f f=852|r8=9efeed6b54ba0000 f=845/811
  #|shl r8w, 16|6641c1e010|SHL16ri:%R8W,%R8W,16|r8=ff f=453|r8=0 f=c45/811
  #|shl r8w, 17|6641c1e011|SHL16ri:%R8W,%R8W,17|r8=15d0d199c57c34f9 f=847|r8=15d0d199c57c0000 f=44/811
  #|shl r8w, 17|6641c1e011|SHL16ri:%R8W,%R8W,17|r8=4c9c4cb1300766ff f=93|r8=4c9c4cb130070000 f=44/811
  #|shl r8w, 65|6641c1e041|SHL16ri:%R8W,%R8W,65|r8=560fb6c8c4cbc5ad f=16|r8=560fb6c8c4cb8b5a f=85/10
  #|shl r8w, 65|6641c1e041|SHL16ri:%R8W,%R8W,65|r8=fa02fa831a4dc1 f=c06|r8=fa02fa831a9b82 f=c84/10
  #|shl word ptr [rbp - 0x20], 1|66d165e0|SHL16m1:%RBP,1,%,-32,%|rbx=9 r9=2 f=43 m20160=5670c35b641d39909003df5be73d184c|f=884/10 m20160=ace0
  #|shl word ptr [rbp - 0x20], 1|66d165e0|SHL16m1:%RBP,1,%,-32,%|rbx=3 r9=c f=892 m20160=56b74317f20da9d3fab8e238bcfe5fac|f=805/10 m20160=ac6e
  #|shl word ptr [rbp - 0x20], cl|66d365e0|SHL16mCL:%RBP,1,%,-32,%|rcx=10 rbx=b r9=8 f=816 m20160=d502ae0e0a7cb3069065f601c428a4e1|f=845/811 m20160=0000
  #|shl word ptr [rbp - 0x20], cl|66d365e0|SHL16mCL:%RBP,1,%,-32,%|rcx=16 rbx=0 r9=e f=c02 m20160=3b149bdec77df6f5a94ea808a11dd53c|f=444/811 m20160=0000
  #|shl word ptr [rbp - 0x20], cl|66d365e0|SHL16mCL:%RBP,1,%,-32,%|rcx=2 rbx=9 r9=2 f=4d3 m20160=2219b7d27bfa12e29d7b6cdde07e3ffd|f=404/810 m20160=8864
  #|shl word ptr [rbp - 0x20], cl|66d365e0|SHL16mCL:%RBP,1,%,-32,%|rcx=14 rbx=3 r9=1 f=886 m20160=06473af809e6bc0c988775950b16fa58|f=44/811 m20160=0000
  #|shl word ptr [rbp - 0x20], 15|66c165e00f|SHL16mi:%RBP,1,%,-32,%,15|rbx=b r9=d f=896 m20160=fd3e5fab9ec8c17fc1e78edb64d5223b|f=884/810 m20160=0080
  #|shl word ptr [rbp - 0x20], 15|66c165e00f|SHL16mi:%RBP,1,%,-32,%,15|rbx=4 r9=a f=17 m20160=98c93236bb4e1023e2fad0be429890cc|f=44/810 m20160=0000
  #|shl r8d, 1|41d1e0|SHL32r1:%R8D,%R8D|r8=18e90f49e0f113a3 f=813|r8=c1e22746 f=81/10
  #|shl r8d, cl|41d3e0|SHL32rCL:%R8D,%R8D|rcx=2 r8=9d8d54e09cc98e7f f=856|r8=732639fc f=4/810
  #|shl r8d, cl|41d3e0|SHL32rCL:%R8D,%R8D|rcx=21 r8=e3e59764f2077fff f=c3|r8=e40efffe f=81/10
  #|shl r8d, cl|41d3e0|SHL32rCL:%R8D,%R8D|rcx=3 r8=869b77be7fffffff f=406|r8=fffffff8 f=481/810
  #|shl r8d, cl|41d3e0|SHL32rCL:%R8D,%R8D|rcx=2 r8=f587408fa80f2837 f=807|r8=a03ca0dc f=880/810
  #|shl r8d, cl|41d3e0|SHL32rCL:%R8D,%R8D|rcx=0 r8=7fffffffffffffff f=447|r8=ffffffff f=445/0
  #|shl r8d, 0|41c1e000|SHL32ri:%R8D,%R8D,0|r8=80 f=46|f=44/0
  #|shl r8d, 14|41c1e00e|SHL32ri:%R8D,%R8D,14|r8=23b6d7aaa6177fff f=847|r8=dfffc000 f=85/810
  #|shl r8d, 31|41c1e01f|SHL32ri:%R8D,%R8D,31|r8=8ee28a3bc6919d66 f=847|r8=0 f=845/810
  #|shl r8d, 32|41c1e020|SHL32ri:%R8D,%R8D,32|r8=621f f=c12|f=c10/0
  #|shl r8d, 33|41c1e021|SHL32ri:%R8D,%R8D,33|r8=7a68c5571d4dcf7b f=53|r8=3a9b9ef6 f=4/10
  #|shl dword ptr [rsp + 0x8], 1|d1642408|SHL32m1:%RSP,1,%,8,%|rbx=e r9=7 f=417 m20108=ec82af6243e27b9abf3fb23b8018e083|f=c84/10 m20108=d8055fc5
  #|shl dword ptr [rsp + 0x8], 1|d1642408|SHL32m1:%RSP,1,%,8,%|rbx=9 r9=5 f=c2 m20108=4c01c32c87c8918169b3097acb3832b8|f=0/10 m20108=98028659
  #|shl dword ptr [rsp + 0x8], cl|d3642408|SHL32mCL:%RSP,1,%,8,%|rcx=16 rbx=0 r9=d f=892 m20108=06cdc52f8c7f0152e478d29e85b09cfc|f=805/810 m20108=00008041
  #|shl dword ptr [rsp + 0x8], cl|d3642408|SHL32mCL:%RSP,1,%,8,%|rcx=19 rbx=3 r9=5 f=883 m20108=338448562e81c929e16d22b4f3bf08fa|f=4/810 m20108=00000066
  #|shl dword ptr [rsp + 0x8], cl|d3642408|SHL32mCL:%RSP,1,%,8,%|rcx=4 rbx=1 r9=7 f=93 m20108=42bb909c48d98bb9e8b28cee11ab3dd1|f=81/810 m20108=20b40bc9
  #|shl dword ptr [rsp + 0x8], cl|d3642408|SHL32mCL:%RSP,1,%,8,%|rcx=b rbx=5 r9=3 f=882 m20108=570d96dcbf134e0e13610c94613a6ece|f=884/810 m20108=00b86ab0
  #|shl dword ptr [rsp + 0x8], 8|c164240808|SHL32mi:%RSP,1,%,8,%,8|rbx=f r9=8 f=16 m20108=43405ae93aa44679d9faacab6bd5d9cc|f=805/810 m20108=0043405a
  #|shl dword ptr [rsp + 0x8], 8|c164240808|SHL32mi:%RSP,1,%,8,%,8|rbx=a r9=e f=c3 m20108=c9ca8d064c9b404e1edd1dfd9fb8cd21|f=884/810 m20108=00c9ca8d
  #|shl r8, 1|49d1e0|SHL64r1:%R8,%R8|r8=b1c2813525cb0a1e f=886|r8=6385026a4b96143c f=805/10
  #|shl r8, cl|49d3e0|SHL64rCL:%R8,%R8|rcx=6 r8=8e331965822fc464 f=c97|r8=8cc659608bf11900 f=485/810
  #|shl r8, cl|49d3e0|SHL64rCL:%R8,%R8|rcx=21 r8=d0 f=817|r8=1a000000000 f=4/810
  #|shl r8, cl|49d3e0|SHL64rCL:%R8,%R8|rcx=1 r8=13cda0b12f9debac f=857|r8=279b41625f3bd758 f=0/10
  #|shl r8, cl|49d3e0|SHL64rCL:%R8,%R8|rcx=40 r8=e861eb64ad3f8a32 f=406|f=404/0
  #|shl r8, cl|49d3e0|SHL64rCL:%R8,%R8|rcx=3f r8=7eb7386d189f55d3 f=897|r8=8000000000000000 f=85/810
  #|shl r8, 0|49c1e000|SHL64ri:%R8,%R8,0|r8=d0494fdceb915015 f=8c7|f=8c5/0
  #|shl r8, 42|49c1e02a|SHL64ri:%R8,%R8,42|r8=436ef87b23182b3a f=87|r8=60ace80000000000 f=4/810
  #|shl r8, 63|49c1e03f|SHL64ri:%R8,%R8,63|r8=58e710075673c49f f=82|r8=8000000000000000 f=85/810
  #|shl r8, 64|49c1e040|SHL64ri:%R8,%R8,64|r8=1 f=857|f=855/0
  #|shl r8, 65|49c1e041|SHL64ri:%R8,%R8,65|r8=af4043faf153bc8c f=813|r8=5e8087f5e2a77918 f=805/10
  #|shl qword ptr [rbp - 0x20], 1|48d165e0|SHL64m1:%RBP,1,%,-32,%|rbx=3 r9=f f=c2 m20160=a5e6e795c5d0896c69382a4aaa0c100a|f=880/10 m20160=4acdcf2b8ba113d9
  #|shl qword ptr [rbp - 0x20], 1|48d165e0|SHL64m1:%RBP,1,%,-32,%|rbx=6 r9=4 f=8c7 m20160=df7dd04a1ba77afcd57c91f66ea15c07|f=85/10 m20160=befba095364ef5f8
  #|shl qword ptr [rbp - 0x20], cl|48d365e0|SHL64mCL:%RBP,1,%,-32,%|rcx=5 rbx=2 r9=a f=c2 m20160=a058a76b4f8aa4dd609fa8abedc21e8c|f=85/810 m20160=0014eb74ed4991b4
  #|shl qword ptr [rbp - 0x20], cl|48d365e0|SHL64mCL:%RBP,1,%,-32,%|rcx=15 rbx=c r9=3 f=842 m20160=2c506c1418a957af5fab62cbc664bac7|f=805/810 m20160=000080058a8d0223
  #|shl qword ptr [rbp - 0x20], cl|48d365e0|SHL64mCL:%RBP,1,%,-32,%|rcx=5 rbx=4 r9=f f=446 m20160=c27b19b45f7c2a2b241543208f833eec|f=c01/810 m20160=40782f83f68b4f65
  #|shl qword ptr [rbp - 0x20], cl|48d365e0|SHL64mCL:%RBP,1,%,-32,%|rcx=4 rbx=b r9=8 f=886 m20160=0e97d32b5daba9fdd004edf0c660d0c5|f=81/810 m20160=e07039bdd2b59ada
  #|shl qword ptr [rbp - 0x20], 33|48c165e021|SHL64mi:%RBP,1,%,-32,%,33|rbx=c r9=7 f=883 m20160=d6d2c616592b61974eccc6397d692b2a|f=4/810 m20160=00000000aca58d2d
  #|shl qword ptr [rbp - 0x20], 33|48c165e021|SHL64mi:%RBP,1,%,-32,%,33|rbx=1 r9=f f=887 m20160=a86eea3fe1b4bf65f703072ebd5e6c40|f=4/810 m20160=0000000050ddd47f
  #|shr al, 1|d0e8|SHR8r1:%AL,%AL|rax=ffffffffffffffff f=cd2|rax=ffffffffffffff7f f=c01/10
  #|shr al, 1|d0e8|SHR8r1:%AL,%AL|rax=e0fc108a51381a8c f=892|rax=e0fc108a51381a46 f=800/10
  #|shr al, cl|d2e8|SHR8rCL:%AL,%AL|rax=3 rcx=ff f=83|rax=0 f=44/811
  #|shr al, cl|d2e8|SHR8rCL:%AL,%AL|rax=806eddf38a2c9178 rcx=1f f=842|rax=806eddf38a2c9100 f=44/811
  #|shr al, cl|d2e8|SHR8rCL:%AL,%AL|rax=4ef186a5227994d5 rcx=3 f=8c6|rax=4ef186a52279941a f=1/810
  #|shr al, cl|d2e8|SHR8rCL:%AL,%AL|rax=b49ae6a3621c8000 rcx=1 f=412|f=444/10
  #|shr al, cl|d2e8|SHR8rCL:%AL,%AL|rax=566e44f069f48df5 rcx=6 f=c46|rax=566e44f069f48d03 f=405/810
  #|shr al, 0|c0e800|SHR8ri:%AL,%AL,0|rax=ffffffffffffffff f=853|f=851/0
  #|shr al, 0|c0e800|SHR8ri:%AL,%AL,0|rax=def267f92cefa562 f=83|f=81/0
  #|shr al, 5|c0e805|SHR8ri:%AL,%AL,5|rax=456e13f5ad50a7 f=12|rax=456e13f5ad5005 f=4/810
  #|shr al, 5|c0e805|SHR8ri:%AL,%AL,5|rax=d57f5bfefc28b634 f=887|rax=d57f5bfefc28b601 f=1/810
  #|shr al, 7|c0e807|SHR8ri:%AL,%AL,7|rax=953342131926f34f f=8c3|rax=953342131926f300 f=45/810
  #|shr al, 7|c0e807|SHR8ri:%AL,%AL,7|rax=7737cbf324752a6 f=93|rax=7737cbf32475201 f=0/810
  #|shr al, 8|c0e808|SHR8ri:%AL,%AL,8|rax=67a8 f=42|rax=6700 f=45/811
  #|shr al, 8|c0e808|SHR8ri:%AL,%AL,8|rax=0 f=42|f=44/811
  #|shr al, 9|c0e809|SHR8ri:%AL,%AL,9|rax=c731fd9e36dcdf1d f=cc7|rax=c731fd9e36dcdf00 f=444/811
  #|shr al, 9|c0e809|SHR8ri:%AL,%AL,9|rax=3b22b24fe59069fe f=896|rax=3b22b24fe5906900 f=44/811
  #|shr al, 65|c0e841|SHR8ri:%AL,%AL,65|rax=5a4e0bcc344398f3 f=802|rax=5a4e0bcc34439879 f=801/10
  #|shr al, 65|c0e841|SHR8ri:%AL,%AL,65|rax=66afe6d0484511ec f=487|rax=66afe6d048451176 f=c00/10
  #|shr byte ptr [rdi + r9*2 - 0x4], 1|42d06c4ffc|SHR8m1:%RDI,2,%R9,-4,%|rbx=1 r9=a f=8d3 m10110=5ea1acdc70e020ed3753ae382fa4a8be|f=0/10 m10110=2f
  #|shr byte ptr [rdi + r9*2 - 0x4], 1|42d06c4ffc|SHR8m1:%RDI,2,%R9,-4,%|rbx=4 r9=c f=57 m10114=27690657c4d90d132c6bc474ef03dcaa|f=1/10 m10114=13
  #|shr byte ptr [rdi + r9*2 - 0x4], cl|42d26c4ffc|SHR8mCL:%RDI,2,%R9,-4,%|rcx=4 rbx=1 r9=1 f=882 m100fe=cb32325e9eaf24b34da87ce41d758cc0|f=5/810 m100fe=0c
  #|shr byte ptr [rdi + r9*2 - 0x4], cl|42d26c4ffc|SHR8mCL:%RDI,2,%R9,-4,%|rcx=17 rbx=3 r9=6 f=cc7 m10108=b4973f49d01decf83c82e88b8e645ad6|f=444/811 m10108=00
  #|shr byte ptr [rdi + r9*2 - 0x4], cl|42d26c4ffc|SHR8mCL:%RDI,2,%R9,-4,%|rcx=15 rbx=d r9=f f=886 m1011a=251e4eaf5854e47827da58ae974b3393|f=44/811 m1011a=00
  #|shr byte ptr [rdi + r9*2 - 0x4], cl|42d26c4ffc|SHR8mCL:%RDI,2,%R9,-4,%|rcx=23 rbx=8 r9=b f=883 m10112=a2695331edd1afeb52266a0e4767cf91|f=4/810 m10112=14
  #|shr byte ptr [rdi + r9*2 - 0x4], 2|42c06c4ffc02|SHR8mi:%RDI,2,%R9,-4,%,2|rbx=0 r9=4 f=47 m10104=1790e9abd9a1c5604d57956f8cdbbad9|f=5/810 m10104=05
  #|shr byte ptr [rdi + r9*2 - 0x4], 2|42c06c4ffc02|SHR8mi:%RDI,2,%R9,-4,%,2|rbx=1 r9=a f=803 m10110=48d91e02dded7fcad8605c668ce10986|f=4/810 m10110=12
  #|shr ax, 1|66d1e8|SHR16r1:%AX,%AX|rax=37 f=807|rax=1b f=5/10
  #|shr ax, 1|66d1e8|SHR16r1:%AX,%AX|rax=c2b1bafadb60ba14 f=842|rax=c2b1bafadb605d0a f=804/10
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|rax=fffffffffffffffe rcx=3f f=97|rax=ffffffffffff0000 f=44/811
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|rax=e rcx=20 f=403|f=401/0
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|rax=4353877436258c06 rcx=1 f=46|rax=4353877436254603 f=804/10
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|rax=c37943fb09f22407 rcx=21 f=c03|rax=c37943fb09f21203 f=405/10
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|rax=2f8db33f10078275 rcx=40 f=8d7|f=8d5/0
  #|shr ax, 0|66c1e800|SHR16ri:%AX,%AX,0|rax=6932 f=cc3|f=cc1/0
  #|shr ax, 0|66c1e800|SHR16ri:%AX,%AX,0|rax=3917741de336f376 f=92|f=90/0
  #|shr ax, 6|66c1e806|SHR16ri:%AX,%AX,6|rax=28523400c41a37a f=2|rax=28523400c41028d f=5/810
  #|shr ax, 6|66c1e806|SHR16ri:%AX,%AX,6|rax=c4de f=52|rax=313 f=0/810
  #|shr ax, 15|66c1e80f|SHR16ri:%AX,%AX,15|rax=6523e6e1fb1e9614 f=2|rax=6523e6e1fb1e0001 f=0/810
  #|shr ax, 15|66c1e80f|SHR16ri:%AX,%AX,15|rax=51 f=887|rax=0 f=44/810
  #|shr ax, 16|66c1e810|SHR16ri:%AX,%AX,16|rax=7790e499df4d3f2a f=c46|rax=7790e499df4d0000 f=444/811
  #|shr ax, 16|66c1e810|SHR16ri:%AX,%AX,16|rax=537debb7ac07a8e7 f=887|rax=537debb7ac070000 f=45/811
  #|shr ax, 17|66c1e811|SHR16ri:%AX,%AX,17|rax=ffffffff f=8d6|rax=ffff0000 f=44/811
  #|shr ax, 17|66c1e811|SHR16ri:%AX,%AX,17|rax=58a4 f=813|rax=0 f=44/811
  #|shr ax, 33|66c1e821|SHR16ri:%AX,%AX,33|rax=7aa39e9e4e0a1fb7 f=c6|rax=7aa39e9e4e0a0fdb f=5/10
  #|shr ax, 33|66c1e821|SHR16ri:%AX,%AX,33|rax=6f1d38466acd96af f=cd6|rax=6f1d38466acd4b57 f=c01/10
  #|shr word ptr [rdi + 0x10], 1|66d16f10|SHR16m1:%RDI,1,%,16,%|rbx=4 r9=f f=d3 m10110=19c107ae8f5477410021862ba351418f|f=801/10 m10110=8c60
  #|shr word ptr [rdi + 0x10], 1|66d16f10|SHR16m1:%RDI,1,%,16,%|rbx=a r9=0 f=816 m10110=57b5e7a101633de5fe0f18bdd5c54ce9|f=801/10 m10110=ab5a
  #|shr word ptr [rdi + 0x10], cl|66d36f10|SHR16mCL:%RDI,1,%,16,%|rcx=3 rbx=2 r9=1 f=802 m10110=10b2bfc06d542dc8ba01c508748d5d57|f=4/810 m10110=4216
  #|shr word ptr [rdi + 0x10], cl|66d36f10|SHR16mCL:%RDI,1,%,16,%|rcx=17 rbx=1 r9=e f=802 m10110=31dd0b2f73f982caab47045f9aff5865|f=44/811 m10110=0000
  #|shr word ptr [rdi + 0x10], cl|66d36f10|SHR16mCL:%RDI,1,%,16,%|rcx=1 rbx=6 r9=c f=8c7 m10110=19a9541cae840829a129f72e85ad238d|f=801/10 m10110=8c54
  #|shr word ptr [rdi + 0x10], cl|66d36f10|SHR16mCL:%RDI,1,%,16,%|rcx=14 rbx=8 r9=a f=c47 m10110=7798c97d12c569e3d20881ec270b45a9|f=444/811 m10110=0000
  #|shr word ptr [rdi + 0x10], 12|66c16f100c|SHR16mi:%RDI,1,%,16,%,12|rbx=8 r9=b f=52 m10110=7a1e3bdd919725794ebe1aec8bbc923e|f=1/810 m10110=0100
  #|shr word ptr [rdi + 0x10], 12|66c16f100c|SHR16mi:%RDI,1,%,16,%,12|rbx=c r9=6 f=43 m10110=874ecbae857dc7b880d2eac6e7b20ffd|f=1/810 m10110=0400
  #|shr ebx, 1|d1eb|SHR32r1:%EBX,%EBX|rbx=a8 f=817|rbx=54 f=0/10
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|rcx=40 rbx=2973ca0db382988c f=813|rbx=b382988c f=811/0
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|rcx=5 rbx=d19fe6eedfa5060b f=843|rbx=6fd2830 f=4/810
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|rcx=3 rbx=fffffffffffffffe f=886|rbx=1fffffff f=5/810
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|rcx=1 rbx=548e3b9880000000 f=17|rbx=40000000 f=804/10
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|rcx=1 rbx=7fffffffffffffff f=c42|rbx=7fffffff f=c05/10
  #|shr ebx, 0|c1eb00|SHR32ri:%EBX,%EBX,0|rbx=78acea5580974996 f=853|rbx=80974996 f=851/0
  #|shr ebx, 14|c1eb0e|SHR32ri:%EBX,%EBX,14|rbx=100 f=856|rbx=0 f=44/810
  #|shr ebx, 31|c1eb1f|SHR32ri:%EBX,%EBX,31|rbx=1 f=412|rbx=0 f=444/810
  #|shr ebx, 32|c1eb20|SHR32ri:%EBX,%EBX,32|rbx=a208cf2c009b33a2 f=13|rbx=9b33a2 f=11/0
  #|shr ebx, 33|c1eb21|SHR32ri:%EBX,%EBX,33|rbx=7fff f=813|rbx=3fff f=5/10
  #|shr dword ptr [rsi], 1|d12e|SHR32m1:%RSI,1,%,0,%|rbx=f r9=c f=c6 m10080=41df93e66ceda8fd436aa10da47b73e0|f=805/10 m10080=a0ef4973
  #|shr dword ptr [rsi], 1|d12e|SHR32m1:%RSI,1,%,0,%|rbx=a r9=e f=406 m10080=29854ad2043e428c46dca88b122fc5b4|f=c01/10 m10080=94422569
  #|shr dword ptr [rsi], cl|d32e|SHR32mCL:%RSI,1,%,0,%|rcx=a rbx=e r9=e f=4d6 m10080=5c27005653aca780909121d606804926|f=405/810 m10080=09801500
  #|shr dword ptr [rsi], cl|d32e|SHR32mCL:%RSI,1,%,0,%|rcx=a rbx=5 r9=e f=83 m10080=8ba30665a94f537e7169bf9ec8b2ee1c|f=1/810 m10080=a8411900
  #|shr dword ptr [rsi], cl|d32e|SHR32mCL:%RSI,1,%,0,%|rcx=19 rbx=4 r9=5 f=c03 m10080=3b88264eafa6214f23a0b935ef531984|f=404/810 m10080=27000000
  #|shr dword ptr [rsi], cl|d32e|SHR32mCL:%RSI,1,%,0,%|rcx=9 rbx=3 r9=a f=812 m10080=d5bf2e61f369a655aa64c7aa1111776f|f=5/810 m10080=5f973000
  #|shr dword ptr [rsi], 21|c12e15|SHR32mi:%RSI,1,%,0,%,21|rbx=7 r9=a f=452 m10080=95a74b95622f5f40873aca7bb5fc1517|f=404/810 m10080=aa040000
  #|shr dword ptr [rsi], 21|c12e15|SHR32mi:%RSI,1,%,0,%,21|rbx=1 r9=c f=8d3 m10080=a76fc887ea8ff40ea1f641f09849db17|f=0/810 m10080=3e040000
  #|shr rdx, 1|48d1ea|SHR64r1:%RDX,%RDX|rdx=a f=87|rdx=5 f=4/10
  #|shr rdx, cl|48d3ea|SHR64rCL:%RDX,%RDX|rcx=21 rdx=9c4155bbb49feab f=453|rdx=4e20aad f=401/810
  #|shr rdx, cl|48d3ea|SHR64rCL:%RDX,%RDX|rcx=40 rdx=a914b6c77c6014ee f=2|f=0/0
  #|shr rdx, cl|48d3ea|SHR64rCL:%RDX,%RDX|rcx=2 rdx=fdb72deffa8a7ea2 f=853|rdx=3f6dcb7bfea29fa8 f=1/810
  #|shr rdx, cl|48d3ea|SHR64rCL:%RDX,%RDX|rcx=3f rdx=a6d8e033152f5df0 f=7|rdx=1 f=0/810
  #|shr rdx, cl|48d3ea|SHR64rCL:%RDX,%RDX|rcx=20 rdx=8000 f=c12|rdx=0 f=444/810
  #|shr rdx, 0|48c1ea00|SHR64ri:%RDX,%RDX,0|rdx=ff f=92|f=90/0
  #|shr rdx, 34|48c1ea22|SHR64ri:%RDX,%RDX,34|rdx=4d031f2d96497a57 f=892|rdx=1340c7cb f=0/810
  #|shr rdx, 63|48c1ea3f|SHR64ri:%RDX,%RDX,63|rdx=48224af41ffce416 f=886|rdx=0 f=45/810
  #|shr rdx, 64|48c1ea40|SHR64ri:%RDX,%RDX,64|rdx=9f309ffc7fc4763f f=883|f=881/0
  #|shr rdx, 65|48c1ea41|SHR64ri:%RDX,%RDX,65|rdx=9aef f=842|rdx=4d77 f=5/10
  #|shr qword ptr [rbp - 0x20], 1|48d16de0|SHR64m1:%RBP,1,%,-32,%|rbx=8 r9=f f=483 m20160=f16ffa802ce8957416af13ddd5654fb4|f=401/10 m20160=f8377d4016f44a3a
  #|shr qword ptr [rbp - 0x20], 1|48d16de0|SHR64m1:%RBP,1,%,-32,%|rbx=6 r9=2 f=d6 m20160=215cc240bc6ab20b86850173a0278b86|f=1/10 m20160=102e61205e35d905
  #|shr qword ptr [rbp - 0x20], cl|48d36de0|SHR64mCL:%RBP,1,%,-32,%|rcx=1 rbx=9 r9=e f=d6 m20160=3d340f0e1c2522e5a5ee5169a52eb784|f=805/10 m20160=1e9a07078e129172
  #|shr qword ptr [rbp - 0x20], cl|48d36de0|SHR64mCL:%RBP,1,%,-32,%|rcx=18 rbx=1 r9=e f=817 m20160=2fc7b001360f2de5a21e1afa6e88064c|f=1/810 m20160=01360f2de5000000
  #|shr qword ptr [rbp - 0x20], cl|48d36de0|SHR64mCL:%RBP,1,%,-32,%|rcx=a rbx=a r9=f f=53 m20160=0c544717319f23a8466b81a47d4c17e0|f=0/810 m20160=d5d145cce7082a00
  #|shr qword ptr [rbp - 0x20], cl|48d36de0|SHR64mCL:%RBP,1,%,-32,%|rcx=11 rbx=f r9=3 f=8d6 m20160=b0d94300ea95a5738626c5f2c32057c6|f=5/810 m20160=2100f5cad2390000
  #|shr qword ptr [rbp - 0x20], 29|48c16de01d|SHR64mi:%RBP,1,%,-32,%,29|rbx=b r9=6 f=897 m20160=25f1c2c98110a5c4fbc8b89e095a751f|f=0/810 m20160=0e84282506000000
  #|shr qword ptr [rbp - 0x20], 29|48c16de01d|SHR64mi:%RBP,1,%,-32,%,29|rbx=0 r9=f f=853 m20160=24bfa9f072e2c0b613b9e36fbde18792|f=1/810 m20160=971307b605000000
  #|sar r12b, 1|41d0fc|SAR8r1:%R12B,%R12B|r12=df39e31030b0768a f=843|r12=df39e31030b076c5 f=84/10
  #|sar r12b, 1|41d0fc|SAR8r1:%R12B,%R12B|r12=ffffffffffffffff f=47|f=85/10
  #|sar r12b, cl|41d2fc|SAR8rCL:%R12B,%R12B|rcx=8 r12=5900836a7fffffff f=92|f=85/810
  #|sar r12b, cl|41d2fc|SAR8rCL:%R12B,%R12B|rcx=21 r12=9692f86bb55b251b f=842|r12=9692f86bb55b250d f=1/10
  #|sar r12b, cl|41d2fc|SAR8rCL:%R12B,%R12B|rcx=21 r12=c1924d7a5140ca97 f=886|r12=c1924d7a5140cacb f=81/10
  #|sar r12b, cl|41d2fc|SAR8rCL:%R12B,%R12B|rcx=3 r12=5e7dde2d34cc5247 f=d3|r12=5e7dde2d34cc5208 f=1/810
  #|sar r12b, cl|41d2fc|SAR8rCL:%R12B,%R12B|rcx=9 r12=787c26b08616600e f=886|r12=787c26b086166000 f=44/810
  #|sar r12b, 0|41c0fc00|SAR8ri:%R12B,%R12B,0|r12=fd2c308a01398ade f=8d7|f=8d5/0
  #|sar r12b, 0|41c0fc00|SAR8ri:%R12B,%R12B,0|r12=9caf f=53|f=51/0
  #|sar r12b, 7|41c0fc07|SAR8ri:%R12B,%R12B,7|r12=30a5 f=c53|r12=30ff f=484/810
  #|sar r12b, 7|41c0fc07|SAR8ri:%R12B,%R12B,7|r12=3b271d483df64886 f=c16|r12=3b271d483df648ff f=484/810
  #|sar r12b, 8|41c0fc08|SAR8ri:%R12B,%R12B,8|r12=de63a2b8be68e266 f=846|r12=de63a2b8be68e200 f=44/810
  #|sar r12b, 8|41c0fc08|SAR8ri:%R12B,%R12B,8|r12=ad8d1cbebdf25439 f=816|r12=ad8d1cbebdf25400 f=44/810
  #|sar r12b, 9|41c0fc09|SAR8ri:%R12B,%R12B,9|r12=28a806af4623bb1 f=807|r12=28a806af4623bff f=85/810
  #|sar r12b, 9|41c0fc09|SAR8ri:%R12B,%R12B,9|r12=4aa9ce1fe179e189 f=8d7|r12=4aa9ce1fe179e1ff f=85/810
  #|sar r12b, 64|41c0fc40|SAR8ri:%R12B,%R12B,64|r12=5d161edd9af3682f f=813|f=811/0
  #|sar r12b, 64|41c0fc40|SAR8ri:%R12B,%R12B,64|r12=b44322804fe6810c f=d7|f=d5/0
  #|sar byte ptr [rdi + r9*2 - 0x4], 1|42d07c4ffc|SAR8m1:%RDI,2,%R9,-4,%|rbx=b r9=b f=8d3 m10112=4cb6de1f93f655894e892a22245a57c4|f=0/10 m10112=26
  #|sar byte ptr [rdi + r9*2 - 0x4], 1|42d07c4ffc|SAR8m1:%RDI,2,%R9,-4,%|rbx=1 r9=7 f=8c2 m1010a=c51f74e0a14528f9046c12ed5d7dbf81|f=85/10 m1010a=e2
  #|sar byte ptr [rdi + r9*2 - 0x4], cl|42d27c4ffc|SAR8mCL:%RDI,2,%R9,-4,%|rcx=15 rbx=0 r9=c f=803 m10114=a843e306ec8ed22183e1b1462376e511|f=85/810 m10114=ff
  #|sar byte ptr [rdi + r9*2 - 0x4], cl|42d27c4ffc|SAR8mCL:%RDI,2,%R9,-4,%|rcx=18 rbx=5 r9=e f=92 m10118=4d614fd241f77d88b0e634068cfca7f9|f=44/810 m10118=00
  #|sar byte ptr [rdi + r9*2 - 0x4], cl|42d27c4ffc|SAR8mCL:%RDI,2,%R9,-4,%|rcx=16 rbx=b r9=e f=403 m10118=0788b4128fd5f01219a659940555b7fe|f=444/810 m10118=00
  #|sar byte ptr [rdi + r9*2 - 0x4], cl|42d27c4ffc|SAR8mCL:%RDI,2,%R9,-4,%|rcx=7 rbx=a r9=1 f=cc6 m100fe=ad5b129f7bcd74ee3cf3a52e612636c8|f=484/810 m100fe=ff
  #|sar byte ptr [rdi + r9*2 - 0x4], 3|42c07c4ffc03|SAR8mi:%RDI,2,%R9,-4,%,3|rbx=b r9=1 f=442 m100fe=5af0e4cdf120bb8392ccaa4a417b375f|f=400/810 m100fe=0b
  #|sar byte ptr [rdi + r9*2 - 0x4], 3|42c07c4ffc03|SAR8mi:%RDI,2,%R9,-4,%,3|rbx=d r9=7 f=887 m1010a=6b65199ddc038c6c8984da3fad14924d|f=0/810 m1010a=0d
  #|sar bx, 1|66d1fb|SAR16r1:%BX,%BX|rbx=ffffffff f=c87|f=485/10
  #|sar bx, 1|66d1fb|SAR16r1:%BX,%BX|rbx=3 f=17|rbx=1 f=1/10
  #|sar bx, cl|66d3fb|SAR16rCL:%BX,%BX|rcx=10 rbx=cbe1cd726dafbaf7 f=882|rbx=cbe1cd726dafffff f=85/810
  #|sar bx, cl|66d3fb|SAR16rCL:%BX,%BX|rcx=4 rbx=4a4148cbc6344081 f=92|rbx=4a4148cbc6340408 f=0/810
  #|sar bx, cl|66d3fb|SAR16rCL:%BX,%BX|rcx=4 rbx=ba9c0033d4b0a923 f=c93|rbx=ba9c0033d4b0fa92 f=480/810
  #|sar bx, cl|66d3fb|SAR16rCL:%BX,%BX|rcx=3 rbx=b798d90540ddbea9 f=853|rbx=b798d90540ddf7d5 f=80/810
  #|sar bx, cl|66d3fb|SAR16rCL:%BX,%BX|rcx=0 rbx=99 f=c17|f=c15/0
  #|sar bx, 0|66c1fb00|SAR16ri:%BX,%BX,0|rbx=6d6f5fc8c739a87a f=816|f=814/0
  #|sar bx, 0|66c1fb00|SAR16ri:%BX,%BX,0|rbx=c39723c853d6bb53 f=846|f=844/0
  #|sar bx, 3|66c1fb03|SAR16ri:%BX,%BX,3|rbx=f0deef1ed9d7ea52 f=93|rbx=f0deef1ed9d7fd4a f=80/810
  #|sar bx, 3|66c1fb03|SAR16ri:%BX,%BX,3|rbx=1f8e060a2aca2d56 f=882|rbx=1f8e060a2aca05aa f=5/810
  #|sar bx, 15|66c1fb0f|SAR16ri:%BX,%BX,15|rbx=4d0eb22d470364f9 f=8c6|rbx=4d0eb22d47030000 f=45/810
  #|sar bx, 15|66c1fb0f|SAR16ri:%BX,%BX,15|rbx=fffffffffffffffe f=816|rbx=ffffffffffffffff f=85/810
  #|sar bx, 16|66c1fb10|SAR16ri:%BX,%BX,16|rbx=7fffffff f=8c7|f=85/810
  #|sar bx, 16|66c1fb10|SAR16ri:%BX,%BX,16|rbx=8cb7b5367fffffff f=846|f=85/810
  #|sar bx, 17|66c1fb11|SAR16ri:%BX,%BX,17|rbx=a4832b0190651242 f=16|rbx=a4832b0190650000 f=44/810
  #|sar bx, 17|66c1fb11|SAR16ri:%BX,%BX,17|rbx=163e06d710c0dfb6 f=2|rbx=163e06d710c0ffff f=85/810
  #|sar bx, 31|66c1fb1f|SAR16ri:%BX,%BX,31|rbx=ffffffffffffffff f=c43|f=485/810
  #|sar bx, 31|66c1fb1f|SAR16ri:%BX,%BX,31|rbx=fd8ba864a451f5b1 f=c12|rbx=fd8ba864a451ffff f=485/810
  #|sar word ptr [rdi + 0x10], 1|66d17f10|SAR16m1:%RDI,1,%,16,%|rbx=e r9=1 f=c56 m10110=9871dc0b826c568590c7b6922c391d86|f=404/10 m10110=cc38
  #|sar word ptr [rdi + 0x10], 1|66d17f10|SAR16m1:%RDI,1,%,16,%|rbx=7 r9=6 f=12 m10110=f2987fde7cc530d51978826580a5662f|f=80/10 m10110=79cc
  #|sar word ptr [rdi + 0x10], cl|66d37f10|SAR16mCL:%RDI,1,%,16,%|rcx=24 rbx=0 r9=f f=cd7 m10110=9b9578942a0661c842e141a7bc4956a6|f=485/810 m10110=59f9
  #|sar word ptr [rdi + 0x10], cl|66d37f10|SAR16mCL:%RDI,1,%,16,%|rcx=1a rbx=7 r9=8 f=d3 m10110=4f6974eb946c84baa3b7af229f6d226d|f=44/810 m10110=0000
  #|sar word ptr [rdi + 0x10], cl|66d37f10|SAR16mCL:%RDI,1,%,16,%|rcx=17 rbx=a r9=2 f=492 m10110=dc94404a4bcdf9e1436731960329a733|f=485/810 m10110=ffff
  #|sar word ptr [rdi + 0x10], cl|66d37f10|SAR16mCL:%RDI,1,%,16,%|rcx=27 rbx=0 r9=8 f=82 m10110=c354834dff958ae30fb4e1e013953c3c|f=5/810 m10110=a900
  #|sar word ptr [rdi + 0x10], 13|66c17f100d|SAR16mi:%RDI,1,%,16,%,13|rbx=7 r9=d f=816 m10110=139c8169036b6cc5dbf7c006f232f4f6|f=85/810 m10110=fcff
  #|sar word ptr [rdi + 0x10], 13|66c17f100d|SAR16mi:%RDI,1,%,16,%,13|rbx=8 r9=9 f=16 m10110=9881537d0c8d42a13cf507bfb08b13d6|f=84/810 m10110=fcff
  #|sar eax, 1|d1f8|SAR32r1:%EAX,%EAX|rax=5 f=856|rax=2 f=1/10
  #|sar eax, cl|d3f8|SAR32rCL:%EAX,%EAX|rax=1a6546dac2a828b8 rcx=6 f=813|rax=ff0aa0a2 f=81/810
  #|sar eax, cl|d3f8|SAR32rCL:%EAX,%EAX|rax=684d5e13b6d9cce1 rcx=40 f=802|rax=b6d9cce1 f=800/0
  #|sar eax, cl|d3f8|SAR32rCL:%EAX,%EAX|rax=82d9bc28ab7d360f rcx=1f f=8c7|rax=ffffffff f=84/810
  #|sar eax, cl|d3f8|SAR32rCL:%EAX,%EAX|rax=80000000 rcx=1f f=842|rax=ffffffff f=84/810
  #|sar eax, cl|d3f8|SAR32rCL:%EAX,%EAX|rax=80 rcx=7 f=17|rax=1 f=0/810
  #|sar eax, 0|c1f800|SAR32ri:%EAX,%EAX,0|rax=23964279fd1d9f25 f=453|rax=fd1d9f25 f=451/0
  #|sar eax, 19|c1f813|SAR32ri:%EAX,%EAX,19|rax=d32786829a9ba27f f=8d6|rax=fffff353 f=84/810
  #|sar eax, 31|c1f81f|SAR32ri:%EAX,%EAX,31|rax=3071b24798bae889 f=c13|rax=ffffffff f=484/810
  #|sar eax, 32|c1f820|SAR32ri:%EAX,%EAX,32|rax=c8dc12c11f45a058 f=896|rax=1f45a058 f=894/0
  #|sar eax, 33|c1f821|SAR32ri:%EAX,%EAX,33|rax=9e9f576d1b1e90f2 f=57|rax=d8f4879 f=0/10
  #|sar eax, 65|c1f841|SAR32ri:%EAX,%EAX,65|rax=f1e3991c7385befd f=807|rax=39c2df7e f=5/10
  #|sar dword ptr [rsp + 0x8], 1|d17c2408|SAR32m1:%RSP,1,%,8,%|rbx=5 r9=7 f=c7 m20108=6cdcebb171321d42b412c06b8fa5b295|f=84/10 m20108=36eef5d8
  #|sar dword ptr [rsp + 0x8], 1|d17c2408|SAR32m1:%RSP,1,%,8,%|rbx=8 r9=e f=413 m20108=c2306e98d6935dca88f7bbc52d0c9b65|f=480/10 m20108=611837cc
  #|sar dword ptr [rsp + 0x8], cl|d37c2408|SAR32mCL:%RSP,1,%,8,%|rcx=1e rbx=6 r9=8 f=887 m20108=4689bc6669c07e64d5c4e39c74786e53|f=1/810 m20108=01000000
  #|sar dword ptr [rsp + 0x8], cl|d37c2408|SAR32mCL:%RSP,1,%,8,%|rcx=17 rbx=b r9=0 f=53 m20108=0bdaca91e8862310e220331e07341c01|f=81/810 m20108=23ffffff
  #|sar dword ptr [rsp + 0x8], cl|d37c2408|SAR32mCL:%RSP,1,%,8,%|rcx=17 rbx=9 r9=5 f=86 m20108=1e534e23cc9123632c5dbc00fd6b42a3|f=1/810 m20108=46000000
  #|sar dword ptr [rsp + 0x8], cl|d37c2408|SAR32mCL:%RSP,1,%,8,%|rcx=7 rbx=3 r9=e f=886 m20108=01b8ccaa03a9a93d486a6a2c088aba63|f=80/810 m20108=709955ff
  #|sar dword ptr [rsp + 0x8], 25|c17c240819|SAR32mi:%RSP,1,%,8,%,25|rbx=f r9=a f=3 m20108=b05a531271d3a35fa4eea2f989806a63|f=4/810 m20108=09000000
  #|sar dword ptr [rsp + 0x8], 25|c17c240819|SAR32mi:%RSP,1,%,8,%,25|rbx=c r9=e f=852 m20108=e0c16d18ad88a9e49008b08ba7688299|f=4/810 m20108=0c000000
  #|sar r8, 1|49d1f8|SAR64r1:%R8,%R8|r8=8987d0000d93753d f=806|r8=c4c3e80006c9ba9e f=81/10
  #|sar r8, cl|49d3f8|SAR64rCL:%R8,%R8|rcx=41 r8=d4214fe6f334a9b9 f=d6|r8=ea10a7f3799a54dc f=81/10
  #|sar r8, cl|49d3f8|SAR64rCL:%R8,%R8|rcx=3f r8=4c239e31176c5287 f=857|r8=0 f=45/810
  #|sar r8, cl|49d3f8|SAR64rCL:%R8,%R8|rcx=3f r8=f44d1a42bdeed973 f=3|r8=ffffffffffffffff f=85/810
  #|sar r8, cl|49d3f8|SAR64rCL:%R8,%R8|rcx=4 r8=7 f=c97|r8=0 f=444/810
  #|sar r8, cl|49d3f8|SAR64rCL:%R8,%R8|rcx=20 r8=f f=57|r8=0 f=44/810
  #|sar r8, 0|49c1f800|SAR64ri:%R8,%R8,0|r8=d f=457|f=455/0
  #|sar r8, 57|49c1f839|SAR64ri:%R8,%R8,57|r8=ffffffffffffffff f=97|f=85/810
  #|sar r8, 63|49c1f83f|SAR64ri:%R8,%R8,63|r8=a33b410e9e344a80 f=856|r8=ffffffffffffffff f=84/810
  #|sar r8, 64|49c1f840|SAR64ri:%R8,%R8,64|r8=c460302db92f7d64 f=4d6|f=4d4/0
  #|sar r8, 65|49c1f841|SAR64ri:%R8,%R8,65|r8=ee7d58ed1e17f96f f=82|r8=f73eac768f0bfcb7 f=85/10
  #|sar qword ptr [rbp - 0x20], 1|48d17de0|SAR64m1:%RBP,1,%,-32,%|rbx=2 r9=f f=8d6 m20160=4ec8aa635a473e1034a40e616e262149|f=4/10 m20160=2764d531ad231f08
  #|sar qword ptr [rbp - 0x20], 1|48d17de0|SAR64m1:%RBP,1,%,-32,%|rbx=a r9=f f=c53 m20160=d59996cac75aa15d0aba15b13fa162d7|f=401/10 m20160=ea4c4be563add02e
  #|sar qword ptr [rbp - 0x20], cl|48d37de0|SAR64mCL:%RBP,1,%,-32,%|rcx=4 rbx=8 r9=c f=417 m20160=3b4901f64eebedef0da5ef74709c4c2f|f=485/810 m20160=931460efb4defefe
  #|sar qword ptr [rbp - 0x20], cl|48d37de0|SAR64mCL:%RBP,1,%,-32,%|rcx=24 rbx=4 r9=e f=407 m20160=da48cfb8669192f546fa43833a995bec|f=480/810 m20160=162959ffffffffff
  #|sar qword ptr [rbp - 0x20], cl|48d37de0|SAR64mCL:%RBP,1,%,-32,%|rcx=26 rbx=6 r9=9 f=2 m20160=728da41b1ffb9ccc819c5c6cf8dd82cc|f=80/810 m20160=ec7332ffffffffff
  #|sar qword ptr [rbp - 0x20], cl|48d37de0|SAR64mCL:%RBP,1,%,-32,%|rcx=6 rbx=c r9=9 f=c06 m20160=ebc4e802193ae1a4e5d5e5744634b04b|f=481/810 m20160=13a30b64e88493fe
  #|sar qword ptr [rbp - 0x20], 42|48c17de02a|SAR64mi:%RBP,1,%,-32,%,42|rbx=8 r9=1 f=843 m20160=6d38998197c801bcd2da4cfe949fcab0|f=84/810 m20160=7200efffffffffff
  #|sar qword ptr [rbp - 0x20], 42|48c17de02a|SAR64mi:%RBP,1,%,-32,%,42|rbx=a r9=8 f=cd6 m20160=a96413fda7376d37b64aa63db684639f|f=405/810 m20160=4ddb0d0000000000
  #|rol r8b, 1|41d0c0|ROL8r1:%R8B,%R8B|r8=980967f4bb4d911b f=c82|r8=980967f4bb4d9136 f=480/0
  #|rol r8b, 1|41d0c0|ROL8r1:%R8B,%R8B|r8=9 f=17|r8=12 f=14/0
  #|rol r8b, cl|41d2c0|ROL8rCL:%R8B,%R8B|rcx=1 r8=4cc9239d9ab00a19 f=53|r8=4cc9239d9ab00a32 f=50/0
  #|rol r8b, cl|41d2c0|ROL8rCL:%R8B,%R8B|rcx=3f r8=80000000 f=457|f=454/800
  #|rol r8b, cl|41d2c0|ROL8rCL:%R8B,%R8B|rcx=9 r8=4aac2f99a83cb5b2 f=82|r8=4aac2f99a83cb565 f=881/800
  #|rol r8b, cl|41d2c0|ROL8rCL:%R8B,%R8B|rcx=3f r8=fffffffffffffffe f=887|r8=ffffffffffffff7f f=885/800
  #|rol r8b, cl|41d2c0|ROL8rCL:%R8B,%R8B|rcx=4 r8=116fa18ba8a63bd0 f=c93|r8=116fa18ba8a63b0d f=c91/800
  #|rol r8b, 0|41c0c000|ROL8ri:%R8B,%R8B,0|r8=33 f=d7|f=d5/0
  #|rol r8b, 0|41c0c000|ROL8ri:%R8B,%R8B,0|r8=5decb6218113bcb f=413|f=411/0
  #|rol r8b, 7|41c0c007|ROL8ri:%R8B,%R8B,7|r8=ff f=407|f=405/800
  #|rol r8b, 7|41c0c007|ROL8ri:%R8B,%R8B,7|r8=dc21db2101d320da f=d7|r8=dc21db2101d3206d f=8d5/800
  #|rol r8b, 8|41c0c008|ROL8ri:%R8B,%R8B,8|r8=4ec f=847|f=844/800
  #|rol r8b, 8|41c0c008|ROL8ri:%R8B,%R8B,8|r8=9f775197f46d24ff f=c6|f=c5/800
  #|rol r8b, 9|41c0c009|ROL8ri:%R8B,%R8B,9|r8=1 f=893|r8=2 f=90/800
  #|rol r8b, 9|41c0c009|ROL8ri:%R8B,%R8B,9|r8=a135 f=802|r8=a16a f=0/800
  #|rol r8b, 65|41c0c041|ROL8ri:%R8B,%R8B,65|r8=b387e4ad725b44b f=d6|r8=b387e4ad725b496 f=8d4/0
  #|rol r8b, 65|41c0c041|ROL8ri:%R8B,%R8B,65|r8=e f=52|r8=1c f=50/0
  #|rol byte ptr [rsi], 1|d006|ROL8m1:%RSI,1,%,0,%|rbx=6 r9=5 f=892 m10080=d7155dac34ab08fbea1306eea1d81555|f=91/0 m10080=af
  #|rol byte ptr [rsi], 1|d006|ROL8m1:%RSI,1,%,0,%|rbx=3 r9=2 f=852 m10080=419074b394272795c9f8ba7609e63fb3|f=850/0 m10080=82
  #|rol byte ptr [rsi], cl|d206|ROL8mCL:%RSI,1,%,0,%|rcx=c rbx=5 r9=1 f=52 m10080=6e3922abcea9cbd336881d685b8f2bd3|f=850/800 m10080=e6
  #|rol byte ptr [rsi], cl|d206|ROL8mCL:%RSI,1,%,0,%|rcx=18 rbx=1 r9=8 f=802 m10080=1d2886ed30bb80d063001c4d1df084f4|f=801/800
  #|rol byte ptr [rsi], cl|d206|ROL8mCL:%RSI,1,%,0,%|rcx=11 rbx=7 r9=2 f=842 m10080=4d2c6de856b88b2e119e167e83a37ca5|f=840/800 m10080=9a
  #|rol byte ptr [rsi], cl|d206|ROL8mCL:%RSI,1,%,0,%|rcx=10 rbx=9 r9=0 f=8d6 m10080=c6bd22ce22ee5ad8765d531464cfcd3e|f=8d4/800
  #|rol byte ptr [rsi], 6|c00606|ROL8mi:%RSI,1,%,0,%,6|rbx=3 r9=0 f=c52 m10080=83590da8a53e9d6951214faf3833b4d2|f=c50/800 m10080=e0
  #|rol byte ptr [rsi], 6|c00606|ROL8mi:%RSI,1,%,0,%,6|rbx=d r9=c f=c03 m10080=73aee05f68ab4ebb3580ceb137af32a1|f=c00/800 m10080=dc
  #|rol bx, 1|66d1c3|ROL16r1:%BX,%BX|rbx=2 f=42|rbx=4 f=40/0
  #|rol bx, 1|66d1c3|ROL16r1:%BX,%BX|rbx=80000000 f=52|f=50/0
  #|rol bx, cl|66d3c3|ROL16rCL:%BX,%BX|rcx=3f rbx=80000000 f=12|f=10/800
  #|rol bx, cl|66d3c3|ROL16rCL:%BX,%BX|rcx=1f rbx=8000000000000000 f=8c3|f=c0/800
  #|rol bx, cl|66d3c3|ROL16rCL:%BX,%BX|rcx=4 rbx=86568062db157fff f=8c2|rbx=86568062db15fff7 f=c1/800
  #|rol bx, cl|66d3c3|ROL16rCL:%BX,%BX|rcx=10 rbx=27ec7e56a380b667 f=4c2|f=4c1/800
  #|rol bx, cl|66d3c3|ROL16rCL:%BX,%BX|rcx=3f rbx=6f2cf3f646edacf f=c2|rbx=6f2cf3f646eed67 f=c1/800
  #|rol bx, 0|66c1c300|ROL16ri:%BX,%BX,0|rbx=ffff f=96|f=94/0
  #|rol bx, 0|66c1c300|ROL16ri:%BX,%BX,0|rbx=53dd863f28173801 f=893|f=891/0
  #|rol bx, 8|66c1c308|ROL16ri:%BX,%BX,8|rbx=ef51bb84598fad00 f=c12|rbx=ef51bb84598f00ad f=c11/800
  #|rol bx, 8|66c1c308|ROL16ri:%BX,%BX,8|rbx=b38ee0a027def332 f=cc7|rbx=b38ee0a027de32f3 f=cc5/800
  #|rol bx, 15|66c1c30f|ROL16ri:%BX,%BX,15|rbx=f93b79705863fbf f=802|rbx=f93b79705869fdf f=1/800
  #|rol bx, 15|66c1c30f|ROL16ri:%BX,%BX,15|rbx=776c2cd87c38d4ff f=882|rbx=776c2cd87c38ea7f f=81/800
  #|rol bx, 16|66c1c310|ROL16ri:%BX,%BX,16|rbx=46f4a267d24060e2 f=d7|f=d4/800
  #|rol bx, 16|66c1c310|ROL16ri:%BX,%BX,16|rbx=1f47b0dccc4aeddb f=8d2|f=d1/800
  #|rol bx, 17|66c1c311|ROL16ri:%BX,%BX,17|rbx=d27301ddfdf7c825 f=56|rbx=d27301ddfdf7904b f=55/800
  #|rol bx, 17|66c1c311|ROL16ri:%BX,%BX,17|rbx=defd85364a48c5e2 f=42|rbx=defd85364a488bc5 f=41/800
  #|rol bx, 64|66c1c340|ROL16ri:%BX,%BX,64|rbx=7b67f46315108d33 f=497|f=495/0
  #|rol bx, 64|66c1c340|ROL16ri:%BX,%BX,64|rbx=918ed650917efdc3 f=c6|f=c4/0
  #|rol word ptr [rsi + rbx*4 + 0x8], 1|66d1449e08|ROL16m1:%RSI,4,%RBX,8,%|rbx=5 r9=e f=8d6 m1009c=2db27250fe213634db3be9591bbe025d|f=8d5/0 m1009c=5b64
  #|rol word ptr [rsi + rbx*4 + 0x8], 1|66d1449e08|ROL16m1:%RSI,4,%RBX,8,%|rbx=7 r9=6 f=8c2 m100a4=6066cc2ec2d62c30fbf1b3bb5fba4ed9|f=8c0/0 m100a4=c0cc
  #|rol word ptr [rsi + rbx*4 + 0x8], cl|66d3449e08|ROL16mCL:%RSI,4,%RBX,8,%|rcx=22 rbx=8 r9=c f=803 m100a8=2fad2a6a5ea687abbcfb8fbebeaaf01b|f=800/800 m100a8=beb4
  #|rol word ptr [rsi + rbx*4 + 0x8], cl|66d3449e08|ROL16mCL:%RSI,4,%RBX,8,%|rcx=1c rbx=a r9=4 f=d2 m100b0=4ef71ce6dada95b2c023c828f9744aa7|f=8d0/800 m100b0=74ef
  #|rol word ptr [rsi + rbx*4 + 0x8], cl|66d3449e08|ROL16mCL:%RSI,4,%RBX,8,%|rcx=c rbx=5 r9=5 f=82 m1009c=ff75b07c4f73c504513ab630e8bde421|f=81/800 m1009c=5ff7
  #|rol word ptr [rsi + rbx*4 + 0x8], cl|66d3449e08|ROL16mCL:%RSI,4,%RBX,8,%|rcx=22 rbx=6 r9=0 f=93 m100a0=d41d05133229859fb1bb30fef36ed287|f=90/800 m100a0=5077
  #|rol word ptr [rsi + rbx*4 + 0x8], 9|66c1449e0809|ROL16mi:%RSI,4,%RBX,8,%,9|rbx=a r9=4 f=896 m100b0=d346696d39f81aa9d1ffe393403db2a3|f=95/800 m100b0=8da6
  #|rol word ptr [rsi + rbx*4 + 0x8], 9|66c1449e0809|ROL16mi:%RSI,4,%RBX,8,%,9|rbx=f r9=e f=97 m100c4=c91b372715f67a3f073ea4c27e37b1fe|f=95/800 m100c4=3792
  #|rol r12d, 1|41d1c4|ROL32r1:%R12D,%R12D|r12=9e9316b201db54dc f=c03|r12=3b6a9b8 f=400/0
  #|rol r12d, cl|41d3c4|ROL32rCL:%R12D,%R12D|rcx=3 r12=48515a63dbe6dd74 f=4c6|r12=df36eba6 f=cc4/800
  #|rol r12d, cl|41d3c4|ROL32rCL:%R12D,%R12D|rcx=3f r12=a1622932319cfa78 f=cd2|r12=18ce7d3c f=4d0/800
  #|rol r12d, cl|41d3c4|ROL32rCL:%R12D,%R12D|rcx=1 r12=a4414a361ec08d6f f=8c6|r12=3d811ade f=c4/0
  #|rol r12d, cl|41d3c4|ROL32rCL:%R12D,%R12D|rcx=1 r12=40 f=853|r12=80 f=50/0
  #|rol r12d, cl|41d3c4|ROL32rCL:%R12D,%R12D|rcx=81 r12=51 f=96|r12=a2 f=94/0
  #|rol r12d, 0|41c1c400|ROL32ri:%R12D,%R12D,0|r12=462f65d9d8221b9d f=843|r12=d8221b9d f=841/0
  #|rol r12d, 28|41c1c41c|ROL32ri:%R12D,%R12D,28|r12=a4024eff8b94ffff f=c56|r12=f8b94fff f=455/800
  #|rol r12d, 31|41c1c41f|ROL32ri:%R12D,%R12D,31|r12=93d f=93|r12=8000049e f=890/800
  #|rol r12d, 32|41c1c420|ROL32ri:%R12D,%R12D,32|r12=8000000000000000 f=857|r12=0 f=855/0
  #|rol r12d, 33|41c1c421|ROL32ri:%R12D,%R12D,33|r12=8000000000000000 f=d6|r12=0 f=d4/0
  #|rol r12d, 63|41c1c43f|ROL32ri:%R12D,%R12D,63|r12=cf3269878a07c879 f=53|r12=c503e43c f=850/800
  #|rol dword ptr [rsp + 0x8], 1|d1442408|ROL32m1:%RSP,1,%,8,%|rbx=d r9=0 f=4c7 m20108=f6fd5d371a29b29d33ef3660879572dc|f=4c4/0 m20108=ecfbbb6e
  #|rol dword ptr [rsp + 0x8], 1|d1442408|ROL32m1:%RSP,1,%,8,%|rbx=f r9=2 f=c2 m20108=0e8fb79d0dc13bcfccd333ce86e5ff9e|f=8c1/0 m20108=1d1e6f3b
  #|rol dword ptr [rsp + 0x8], cl|d3442408|ROL32mCL:%RSP,1,%,8,%|rcx=13 rbx=5 r9=c f=c87 m20108=8483432eeb46aed2498c2227a22b8358|f=484/800 m20108=1c72211c
  #|rol dword ptr [rsp + 0x8], cl|d3442408|ROL32mCL:%RSP,1,%,8,%|rcx=2 rbx=e r9=e f=4c2 m20108=9074575e499c99bb094a51d119c1f304|f=cc1/800 m20108=41d25d79
  #|rol dword ptr [rsp + 0x8], cl|d3442408|ROL32mCL:%RSP,1,%,8,%|rcx=24 rbx=2 r9=0 f=8d6 m20108=5fbaee31dac163e1071eac550767b47d|f=8d5/800 m20108=f3a5eb1e
  #|rol dword ptr [rsp + 0x8], cl|d3442408|ROL32mCL:%RSP,1,%,8,%|rcx=11 rbx=9 r9=b f=d3 m20108=294d153879283a12e17e61599772316b|f=8d0/800 m20108=2a70529a
  #|rol dword ptr [rsp + 0x8], 6|c144240806|ROL32mi:%RSP,1,%,8,%,6|rbx=c r9=7 f=852 m20108=971962b5933e4728b1b2882a8237cc9f|f=851/800 m20108=ed658658
  #|rol dword ptr [rsp + 0x8], 6|c144240806|ROL32mi:%RSP,1,%,8,%,6|rbx=e r9=4 f=c2 m20108=5d6b2e2447edfe1ee34c49b94fecf86c|f=8c1/800 m20108=49d79a0b
  #|rol rdx, 1|48d1c2|ROL64r1:%RDX,%RDX|rdx=70ae05738ad05864 f=4d3|rdx=e15c0ae715a0b0c8 f=cd0/0
  #|rol rdx, cl|48d3c2|ROL64rCL:%RDX,%RDX|rcx=81 rdx=29b0ff9a252f2a92 f=807|rdx=5361ff344a5e5524 f=4/0
  #|rol rdx, cl|48d3c2|ROL64rCL:%RDX,%RDX|rcx=6 rdx=d f=893|rdx=340 f=90/800
  #|rol rdx, cl|48d3c2|ROL64rCL:%RDX,%RDX|rcx=1 rdx=9822a2584fa120d3 f=857|rdx=304544b09f4241a7 f=855/0
  #|rol rdx, cl|48d3c2|ROL64rCL:%RDX,%RDX|rcx=2 rdx=ffffffffffffffff f=c17|f=415/800
  #|rol rdx, cl|48d3c2|ROL64rCL:%RDX,%RDX|rcx=40 rdx=7fffffffffffffff f=7|f=5/0
  #|rol rdx, 0|48c1c200|ROL64ri:%RDX,%RDX,0|rdx=2a95849b5bce0ac4 f=8d3|f=8d1/0
  #|rol rdx, 48|48c1c230|ROL64ri:%RDX,%RDX,48|rdx=1fe8ad819a9014f3 f=893|rdx=14f31fe8ad819a90 f=90/800
  #|rol rdx, 63|48c1c23f|ROL64ri:%RDX,%RDX,63|rdx=2 f=8c6|rdx=1 f=8c5/800
  #|rol rdx, 64|48c1c240|ROL64ri:%RDX,%RDX,64|rdx=b f=847|f=845/0
  #|rol rdx, 65|48c1c241|ROL64ri:%RDX,%RDX,65|rdx=c2601474efb014b4 f=42|rdx=84c028e9df602969 f=41/0
  #|rol qword ptr [rdi + 0x10], 1|48d14710|ROL64m1:%RDI,1,%,16,%|rbx=0 r9=c f=802 m10110=f1f6e3d682f6b14a2a42461a4257861e|f=800/0 m10110=e2edc7ad05ed6395
  #|rol qword ptr [rdi + 0x10], 1|48d14710|ROL64m1:%RDI,1,%,16,%|rbx=0 r9=7 f=813 m10110=45ef0b303cb2b5cabd0f7c3cd81bdbac|f=11/0 m10110=8bde176078646b95
  #|rol qword ptr [rdi + 0x10], cl|48d34710|ROL64mCL:%RDI,1,%,16,%|rcx=0 rbx=5 r9=9 f=487 m10110=4208a922bbc048f00dadcf9afe75c023|f=485/0
  #|rol qword ptr [rdi + 0x10], cl|48d34710|ROL64mCL:%RDI,1,%,16,%|rcx=8 rbx=b r9=6 f=cc7 m10110=eb575abd39242498901ab71bb6d51bbd|f=4c4/800 m10110=98eb575abd39 m10117=24
  #|rol qword ptr [rdi + 0x10], cl|48d34710|ROL64mCL:%RDI,1,%,16,%|rcx=1a rbx=d r9=d f=16 m10110=b5c5f710c74d05db4889eac5939773c1|f=815/800 m10110=37156cd716df431c
  #|rol qword ptr [rdi + 0x10], cl|48d34710|ROL64mCL:%RDI,1,%,16,%|rcx=1f rbx=4 r9=9 f=407 m10110=5e077294453ebb6dafcef17c45632191|f=c04/800 m10110=229fdd36af0339ca
  #|rol qword ptr [rdi + 0x10], 21|48c1471015|ROL64mi:%RDI,1,%,16,%,21|rbx=c r9=5 f=93 m10110=f4ee510ccbaad4eca2f365c4ab171813|f=891/800 m10110=959a9dde3d8a6159
  #|rol qword ptr [rdi + 0x10], 21|48c1471015|ROL64mi:%RDI,1,%,16,%,21|rbx=8 r9=5 f=846 m10110=9954f32a3da7772fd3af2a18304988fe|f=844/800 m10110=f4ee25936a5ea5e7
  #|ror al, 1|d0c8|ROR8r1:%AL,%AL|rax=4fab216a78e00023 f=4d2|rax=4fab216a78e00091 f=cd1/0
  #|ror al, 1|d0c8|ROR8r1:%AL,%AL|rax=f7dfbd34ef592099 f=2|rax=f7dfbd34ef5920cc f=1/0
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|rax=8 rcx=8 f=813|f=10/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|rax=85a184a98ea029ca rcx=1f f=92|rax=85a184a98ea02995 f=891/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|rax=ff rcx=5 f=8c6|f=c5/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|rax=84cd09905d3ead9d rcx=1 f=812|rax=84cd09905d3eadce f=11/0
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|rax=6700068880000000 rcx=21 f=c86|f=484/0
  #|ror al, 0|c0c800|ROR8ri:%AL,%AL,0|rax=306f9e070d7aabd5 f=57|f=55/0
  #|ror al, 0|c0c800|ROR8ri:%AL,%AL,0|rax=f8cd f=8c3|f=8c1/0
  #|ror al, 3|c0c803|ROR8ri:%AL,%AL,3|rax=33cec0545a40d006 f=802|rax=33cec0545a40d0c0 f=1/800
  #|ror al, 3|c0c803|ROR8ri:%AL,%AL,3|rax=5a8df83da99c7e4b f=892|rax=5a8df83da99c7e69 f=890/800
  #|ror al, 7|c0c807|ROR8ri:%AL,%AL,7|rax=5f6461a9a1c84574 f=52|rax=5f6461a9a1c845e8 f=51/800
  #|ror al, 7|c0c807|ROR8ri:%AL,%AL,7|rax=c989371dee06259d f=3|rax=c989371dee06253b f=0/800
  #|ror al, 8|c0c808|ROR8ri:%AL,%AL,8|rax=3600e57d64e33a31 f=802|f=0/800
  #|ror al, 8|c0c808|ROR8ri:%AL,%AL,8|rax=1d11f9c934fb9d96 f=c56|f=c55/800
  #|ror al, 9|c0c809|ROR8ri:%AL,%AL,9|rax=7a1e53c083f5a8af f=852|rax=7a1e53c083f5a8d7 f=51/800
  #|ror al, 9|c0c809|ROR8ri:%AL,%AL,9|rax=44227f3752a84ed7 f=8d6|rax=44227f3752a84eeb f=d5/800
  #|ror al, 255|c0c8ff|ROR8ri:%AL,%AL,255|rax=ffff f=893|f=91/800
  #|ror al, 255|c0c8ff|ROR8ri:%AL,%AL,255|rax=8000000000000000 f=17|f=14/800
  #|ror byte ptr [rbp - 0x20], 1|d04de0|ROR8m1:%RBP,1,%,-32,%|rbx=0 r9=4 f=c12 m20160=150ee62864f70628a221d159ce5630c5|f=c11/0 m20160=8a
  #|ror byte ptr [rbp - 0x20], 1|d04de0|ROR8m1:%RBP,1,%,-32,%|rbx=8 r9=d f=96 m20160=e012bf9098927fc3ec98288270199200|f=894/0 m20160=70
  #|ror byte ptr [rbp - 0x20], cl|d24de0|ROR8mCL:%RBP,1,%,-32,%|rcx=26 rbx=e r9=a f=c57 m20160=f1f82891e6e5c236ccfa6bd5024ff0f4|f=455/800 m20160=c7
  #|ror byte ptr [rbp - 0x20], cl|d24de0|ROR8mCL:%RBP,1,%,-32,%|rcx=7 rbx=e r9=1 f=83 m20160=28b4db41268d1f88b0447e9ec14e23a0|f=880/800 m20160=50
  #|ror byte ptr [rbp - 0x20], cl|d24de0|ROR8mCL:%RBP,1,%,-32,%|rcx=19 rbx=3 r9=d f=43 m20160=61ad87df44fc3a11a4d91f31f83f8c68|f=841/800 m20160=b0
  #|ror byte ptr [rbp - 0x20], cl|d24de0|ROR8mCL:%RBP,1,%,-32,%|rcx=1 rbx=6 r9=6 f=853 m20160=d73ce7bf98419190672a4e9327ae3e95|f=51/0 m20160=eb
  #|ror byte ptr [rbp - 0x20], 3|c04de003|ROR8mi:%RBP,1,%,-32,%,3|rbx=7 r9=9 f=856 m20160=0d9be7336b5e20c05b244caa695f4c0c|f=855/800 m20160=a1
  #|ror byte ptr [rbp - 0x20], 3|c04de003|ROR8mi:%RBP,1,%,-32,%,3|rbx=4 r9=5 f=c06 m20160=ca8b1dceeaea21afdca542efa7472c4b|f=c04/800 m20160=59
  #|ror dx, 1|66d1ca|ROR16r1:%DX,%DX|rdx=9cc35d81b85cba f=d2|rdx=9cc35d81b82e5d f=d0/0
  #|ror dx, 1|66d1ca|ROR16r1:%DX,%DX|rdx=3f30b7870a7f5a71 f=846|rdx=3f30b7870a7fad38 f=845/0
  #|ror dx, cl|66d3ca|ROR16rCL:%DX,%DX|rcx=20 rdx=1c4fcf2071391f8 f=8d2|f=8d0/0
  #|ror dx, cl|66d3ca|ROR16rCL:%DX,%DX|rcx=3f rdx=7fff f=8c6|rdx=fffe f=c5/800
  #|ror dx, cl|66d3ca|ROR16rCL:%DX,%DX|rcx=f rdx=8b47733571a4f807 f=d6|rdx=8b47733571a4f00f f=d5/800
  #|ror dx, cl|66d3ca|ROR16rCL:%DX,%DX|rcx=81 rdx=bed578d2a9bed167 f=443|rdx=bed578d2a9bee8b3 f=441/0
  #|ror dx, cl|66d3ca|ROR16rCL:%DX,%DX|rcx=1 rdx=16f87c5b3dadb80f f=13|rdx=16f87c5b3daddc07 f=11/0
  #|ror dx, 0|66c1ca00|ROR16ri:%DX,%DX,0|rdx=5f37c3b0d6245395 f=c07|f=c05/0
  #|ror dx, 0|66c1ca00|ROR16ri:%DX,%DX,0|rdx=b5fe6781d0223070 f=d2|f=d0/0
  #|ror dx, 7|66c1ca07|ROR16ri:%DX,%DX,7|rdx=8000000000000000 f=97|f=94/800
  #|ror dx, 7|66c1ca07|ROR16ri:%DX,%DX,7|rdx=109a63ba65073c9d f=86|rdx=109a63ba65073a79 f=84/800
  #|ror dx, 15|66c1ca0f|ROR16ri:%DX,%DX,15|rdx=b86b f=492|rdx=70d7 f=c90/800
  #|ror dx, 15|66c1ca0f|ROR16ri:%DX,%DX,15|rdx=50bc8d584fc4a9ab f=842|rdx=50bc8d584fc45357 f=840/800
  #|ror dx, 16|66c1ca10|ROR16ri:%DX,%DX,16|rdx=afd2f37bbcf9adaf f=8c7|f=8c5/800
  #|ror dx, 16|66c1ca10|ROR16ri:%DX,%DX,16|rdx=2 f=892|f=90/800
  #|ror dx, 17|66c1ca11|ROR16ri:%DX,%DX,17|rdx=e907bc3c84bed0ff f=852|rdx=e907bc3c84bee87f f=51/800
  #|ror dx, 17|66c1ca11|ROR16ri:%DX,%DX,17|rdx=10683edbf1efc992 f=812|rdx=10683edbf1ef64c9 f=810/800
  #|ror dx, 255|66c1caff|ROR16ri:%DX,%DX,255|rdx=ffff f=483|f=481/800
  #|ror dx, 255|66c1caff|ROR16ri:%DX,%DX,255|rdx=4 f=56|rdx=8 f=54/800
  #|ror word ptr [rsi], 1|66d10e|ROR16m1:%RSI,1,%,0,%|rbx=c r9=2 f=56 m10080=9d7c6b5095cf386be77973bf76b23720|f=855/0 m10080=4ebe
  #|ror word ptr [rsi], 1|66d10e|ROR16m1:%RSI,1,%,0,%|rbx=c r9=c f=456 m10080=597ca8ba86ec0fbb5892d385ea294431|f=c55/0 m10080=2cbe
  #|ror word ptr [rsi], cl|66d30e|ROR16mCL:%RSI,1,%,0,%|rcx=23 rbx=e r9=c f=846 m10080=305ea37c6b8984d00bf3815273f8efdc|f=44/800 m10080=c60b
  #|ror word ptr [rsi], cl|66d30e|ROR16mCL:%RSI,1,%,0,%|rcx=7 rbx=6 r9=6 f=847 m10080=db153e815e3d70f824c0a2196755e6c2|f=845/800 m10080=2bb6
  #|ror word ptr [rsi], cl|66d30e|ROR16mCL:%RSI,1,%,0,%|rcx=13 rbx=c r9=f f=16 m10080=9b3615091386aa19151be44e8786cdb5|f=814/800 m10080=d366
  #|ror word ptr [rsi], cl|66d30e|ROR16mCL:%RSI,1,%,0,%|rcx=1e rbx=e r9=e f=842 m10080=3a02b59c5f961feeca132f2f59c78df6|f=40/800 m10080=e808
  #|ror word ptr [rsi], 12|66c10e0c|ROR16mi:%RSI,1,%,0,%,12|rbx=c r9=9 f=803 m10080=c2e4a42a88edc092ea65fa0b1659883d|f=800/800 m10080=2e4c
  #|ror word ptr [rsi], 12|66c10e0c|ROR16mi:%RSI,1,%,0,%,12|rbx=6 r9=a f=853 m10080=f93e0cb62d17165641042ce1fdea5564|f=51/800 m10080=93ef
  #|ror edx, 1|d1ca|ROR32r1:%EDX,%EDX|rdx=d2dcac96a6908095 f=97|rdx=d348404a f=95/0
  #|ror edx, cl|d3ca|ROR32rCL:%EDX,%EDX|rcx=20 rdx=2321e5d0be47a76c f=882|rdx=be47a76c f=880/0
  #|ror edx, cl|d3ca|ROR32rCL:%EDX,%EDX|rcx=3 rdx=7f f=2|rdx=e000000f f=1/800
  #|ror edx, cl|d3ca|ROR32rCL:%EDX,%EDX|rcx=21 rdx=206609d8bb5f4b7 f=452|rdx=c5dafa5b f=451/0
  #|ror edx, cl|d3ca|ROR32rCL:%EDX,%EDX|rcx=1 rdx=7ecba8530e8b5aeb f=8d6|rdx=8745ad75 f=8d5/0
  #|ror edx, cl|d3ca|ROR32rCL:%EDX,%EDX|rcx=3 rdx=c8fe1fa44a5265ca f=883|rdx=494a4cb9 f=880/800
  #|ror edx, 0|c1ca00|ROR32ri:%EDX,%EDX,0|rdx=6359cc9dd2b77002 f=6|rdx=d2b77002 f=4/0
  #|ror edx, 20|c1ca14|ROR32ri:%EDX,%EDX,20|rdx=c f=d7|rdx=c000 f=d4/800
  #|ror edx, 31|c1ca1f|ROR32ri:%EDX,%EDX,31|rdx=56bdd449841d43ac f=87|rdx=83a8759 f=84/800
  #|ror edx, 32|c1ca20|ROR32ri:%EDX,%EDX,32|rdx=a f=46|f=44/0
  #|ror edx, 33|c1ca21|ROR32ri:%EDX,%EDX,33|rdx=a7f17cde2beb4ac2 f=47|rdx=15f5a561 f=44/0
  #|ror edx, 65|c1ca41|ROR32ri:%EDX,%EDX,65|rdx=443a533ba71dde90 f=802|rdx=538eef48 f=800/0
  #|ror dword ptr [rsp + 0x8], 1|d14c2408|ROR32m1:%RSP,1,%,8,%|rbx=0 r9=7 f=83 m20108=f1782f510a6f6e14095221626f27a051|f=881/0 m20108=78bc97a8
  #|ror dword ptr [rsp + 0x8], 1|d14c2408|ROR32m1:%RSP,1,%,8,%|rbx=c r9=1 f=d2 m20108=f92373f6c6e7e1c4a785392f3636a188|f=d1/0 m20108=fc9139fb
  #|ror dword ptr [rsp + 0x8], cl|d34c2408|ROR32mCL:%RSP,1,%,8,%|rcx=d rbx=d r9=9 f=886 m20108=6f62cab2a4ad988b4d81dab68244d4ab|f=84/800 m20108=53967d13
  #|ror dword ptr [rsp + 0x8], cl|d34c2408|ROR32mCL:%RSP,1,%,8,%|rcx=1a rbx=c r9=2 f=893 m20108=321875625ad78ff1019e64c6af912ff9|f=891/800 m20108=980c469d
  #|ror dword ptr [rsp + 0x8], cl|d34c2408|ROR32mCL:%RSP,1,%,8,%|rcx=25 rbx=4 r9=4 f=883 m20108=3c0ffb0ecc3f749afb98e2e1d9b9ec08|f=81/800 m20108=79d877e0
  #|ror dword ptr [rsp + 0x8], cl|d34c2408|ROR32mCL:%RSP,1,%,8,%|rcx=0 rbx=3 r9=8 f=812 m20108=9a8ab726fa190e106e0d072eb1d680b9|f=810/0
  #|ror dword ptr [rsp + 0x8], 17|c14c240811|ROR32mi:%RSP,1,%,8,%,17|rbx=0 r9=4 f=846 m20108=4ea539280931747476aff2e77b62bee1|f=45/800 m20108=1c14a7d2
  #|ror dword ptr [rsp + 0x8], 17|c14c240811|ROR32mi:%RSP,1,%,8,%,17|rbx=7 r9=9 f=96 m20108=fc587ce4cf884704f16e6ffef49cb74b|f=94/800 m20108=3e727e2c
  #|ror r12, 1|49d1cc|ROR64r1:%R12,%R12|r12=91 f=52|r12=8000000000000048 f=851/0
  #|ror r12, cl|49d3cc|ROR64rCL:%R12,%R12|rcx=40 r12=e1162c17649685c0 f=d2|f=d0/0
  #|ror r12, cl|49d3cc|ROR64rCL:%R12,%R12|rcx=3f r12=96ecd7f103a46619 f=897|r12=2dd9afe20748cc33 f=94/800
  #|ror r12, cl|49d3cc|ROR64rCL:%R12,%R12|rcx=3 r12=3e36 f=896|r12=c0000000000007c6 f=95/800
  #|ror r12, cl|49d3cc|ROR64rCL:%R12,%R12|rcx=3f r12=d705f662ffffffff f=8c6|r12=ae0becc5ffffffff f=8c5/800
  #|ror r12, cl|49d3cc|ROR64rCL:%R12,%R12|rcx=21 r12=a67d1e66c8e0b6a1 f=7|r12=64705b50d33e8f33 f=804/800
  #|ror r12, 0|49c1cc00|ROR64ri:%R12,%R12,0|r12=bb2461dbdf39728e f=8d3|f=8d1/0
  #|ror r12, 21|49c1cc15|ROR64ri:%R12,%R12,21|r12=2 f=47|r12=100000000000 f=44/800
  #|ror r12, 63|49c1cc3f|ROR64ri:%R12,%R12,63|r12=42debb4d3d2ef3d0 f=817|r12=85bd769a7a5de7a0 f=815/800
  #|ror r12, 64|49c1cc40|ROR64ri:%R12,%R12,64|r12=cfcf7b78ef5fbd9f f=92|f=90/0
  #|ror r12, 65|49c1cc41|ROR64ri:%R12,%R12,65|r12=2 f=8c3|r12=1 f=c0/0
  #|ror qword ptr [rdi + r9*2 - 0x4], 1|4ad14c4ffc|ROR64m1:%RDI,2,%R9,-4,%|rbx=a r9=3 f=853 m10102=7065d3e283823514f3c27e6ba1f5dfa6|f=50/0 m10102=b8b269f141c11a0a
  #|ror qword ptr [rdi + r9*2 - 0x4], 1|4ad14c4ffc|ROR64m1:%RDI,2,%R9,-4,%|rbx=4 r9=c f=856 m10114=5288ffeee5f3bdb677e2d62793176def|f=854/0 m10114=29c47ff7f2f95e5b
  #|ror qword ptr [rdi + r9*2 - 0x4], cl|4ad34c4ffc|ROR64mCL:%RDI,2,%R9,-4,%|rcx=19 rbx=9 r9=2 f=492 m10100=fc03f2de8b4dc4d66ad279a9b8803382|f=c90/800 m10100=efc526626bfe0179
  #|ror qword ptr [rdi + r9*2 - 0x4], cl|4ad34c4ffc|ROR64mCL:%RDI,2,%R9,-4,%|rcx=a rbx=8 r9=a f=806 m10110=99decf6f6dbd0a841b408f284cd010a2|f=805/800 m10110=f7f35b5baf0261a6
  #|ror qword ptr [rdi + r9*2 - 0x4], cl|4ad34c4ffc|ROR64mCL:%RDI,2,%R9,-4,%|rcx=1f rbx=6 r9=b f=c03 m10112=96c142c84971700220529c6650c54070|f=c01/800 m10112=93e2e0042c838590
  #|ror qword ptr [rdi + r9*2 - 0x4], cl|4ad34c4ffc|ROR64mCL:%RDI,2,%R9,-4,%|rcx=b rbx=3 r9=8 f=852 m1010c=6346013e21ddbf0e305ac5963cf0db21|f=51/800 m1010c=28c027a4fbd761cc
  #|ror qword ptr [rdi + r9*2 - 0x4], 46|4ac14c4ffc2e|ROR64mi:%RDI,2,%R9,-4,%,46|rbx=0 r9=c f=897 m10114=4dfd601b6f9414b88cd7fb5db0ef1e69|f=894/800 m10114=52e036f5836dbc51
  #|ror qword ptr [rdi + r9*2 - 0x4], 46|4ac14c4ffc2e|ROR64mi:%RDI,2,%R9,-4,%,46|rbx=0 r9=4 f=2 m10104=9d641ce4659088a0680019de489d0757|f=800/800 m10104=2282769271 m1010a=9741
  #|rcl r12b, 1|41d0d4|RCL8r1:%R12B,%R12B|r12=7fff f=807|f=5/0
  #|rcl r12b, 1|41d0d4|RCL8r1:%R12B,%R12B|r12=7fffffff f=843|f=41/0
  #|rcl r12b, cl|41d2d4|RCL8rCL:%R12B,%R12B|rcx=ff r12=1561941e80000000 f=852|f=50/800
  #|rcl r12b, cl|41d2d4|RCL8rCL:%R12B,%R12B|rcx=1f r12=607cbc6eff6017a8 f=887|r12=607cbc6eff60178d f=84/800
  #|rcl r12b, cl|41d2d4|RCL8rCL:%R12B,%R12B|rcx=ff r12=80 f=817|r12=c f=814/800
  #|rcl r12b, cl|41d2d4|RCL8rCL:%R12B,%R12B|rcx=0 r12=b24fdc996e7feeaa f=886|f=884/0
  #|rcl r12b, cl|41d2d4|RCL8rCL:%R12B,%R12B|rcx=3f r12=5c93c863ea0735d6 f=cc2|r12=5c93c863ea073566 f=cc1/800
  #|rcl r12b, 0|41c0d400|RCL8ri:%R12B,%R12B,0|r12=340f943ca9c1c8ff f=887|f=885/0
  #|rcl r12b, 0|41c0d400|RCL8ri:%R12B,%R12B,0|r12=b8ffacd9ea74891a f=892|f=890/0
  #|rcl r12b, 7|41c0d407|RCL8ri:%R12B,%R12B,7|r12=8000000000000000 f=47|r12=8000000000000040 f=44/800
  #|rcl r12b, 7|41c0d407|RCL8ri:%R12B,%R12B,7|r12=b3b504068b461f f=806|r12=b3b504068b4687 f=805/800
  #|rcl r12b, 8|41c0d408|RCL8ri:%R12B,%R12B,8|r12=aba72f1d89547f41 f=92|r12=aba72f1d89547f20 f=91/800
  #|rcl r12b, 8|41c0d408|RCL8ri:%R12B,%R12B,8|r12=80000000 f=c17|r12=80000080 f=c14/800
  #|rcl r12b, 9|41c0d409|RCL8ri:%R12B,%R12B,9|r12=6f519fc30438bcbe f=c6|f=c4/800
  #|rcl r12b, 9|41c0d409|RCL8ri:%R12B,%R12B,9|r12=2 f=3|f=1/800
  #|rcl r12b, 31|41c0d41f|RCL8ri:%R12B,%R12B,31|r12=80000000 f=c96|f=494/800
  #|rcl r12b, 31|41c0d41f|RCL8ri:%R12B,%R12B,31|r12=504d0e79d9945577 f=8c3|r12=504d0e79d994557b f=c1/800
  #|rcl byte ptr [rsi], 1|d016|RCL8m1:%RSI,1,%,0,%|rbx=1 r9=6 f=802 m10080=86aada095d50880256e3f1482ac12440|f=801/0 m10080=0c
  #|rcl byte ptr [rsi], 1|d016|RCL8m1:%RSI,1,%,0,%|rbx=4 r9=4 f=456 m10080=53422d0caa4c30d0c4f9cba999979bf0|f=c54/0 m10080=a6
  #|rcl byte ptr [rsi], cl|d216|RCL8mCL:%RSI,1,%,0,%|rcx=5 rbx=f r9=6 f=843 m10080=b96110d70cf378807befc9665009205b|f=841/800 m10080=3b
  #|rcl byte ptr [rsi], cl|d216|RCL8mCL:%RSI,1,%,0,%|rcx=1f rbx=b r9=9 f=16 m10080=13c0a2c6e74a124cba460744670d4184|f=15/800 m10080=30
  #|rcl byte ptr [rsi], cl|d216|RCL8mCL:%RSI,1,%,0,%|rcx=1f rbx=4 r9=6 f=846 m10080=705ae1b5146883c85205abd0451116f1|f=45/800 m10080=03
  #|rcl byte ptr [rsi], cl|d216|RCL8mCL:%RSI,1,%,0,%|rcx=11 rbx=2 r9=c f=57 m10080=36f0c529c81084581a897aabb6ab9172|f=854/800 m10080=9b
  #|rcl byte ptr [rsi], 5|c01605|RCL8mi:%RSI,1,%,0,%,5|rbx=e r9=e f=493 m10080=a25657f734c6353dc8820eb25f7203e1|f=c90/800 m10080=5a
  #|rcl byte ptr [rsi], 5|c01605|RCL8mi:%RSI,1,%,0,%,5|rbx=0 r9=7 f=16 m10080=199ec7586b7d33db2a16077843c11f71|f=15/800 m10080=21
  #|rcl r8w, 1|6641d1d0|RCL16r1:%R8W,%R8W|r8=bc68b8d48e4ca178 f=56|r8=bc68b8d48e4c42f0 f=855/0
  #|rcl r8w, 1|6641d1d0|RCL16r1:%R8W,%R8W|r8=872d1e2d6830aef5 f=816|r8=872d1e2d68305dea f=815/0
  #|rcl r8w, cl|6641d3d0|RCL16rCL:%R8W,%R8W|rcx=1 r8=b6dcaeabfe48dfdc f=47|r8=b6dcaeabfe48bfb9 f=45/0
  #|rcl r8w, cl|6641d3d0|RCL16rCL:%R8W,%R8W|rcx=f r8=76d2279f759587 f=856|r8=76d2279f75a561 f=55/800
  #|rcl r8w, cl|6641d3d0|RCL16rCL:%R8W,%R8W|rcx=4 r8=c9be716c7fffffff f=2|r8=c9be716c7ffffff7 f=1/800
  #|rcl r8w, cl|6641d3d0|RCL16rCL:%R8W,%R8W|rcx=f r8=3f4d888ed0d9fa28 f=802|r8=3f4d888ed0d93e8a f=800/800
  #|rcl r8w, cl|6641d3d0|RCL16rCL:%R8W,%R8W|rcx=10 r8=f f=43|r8=8007 f=841/800
  #|rcl r8w, 0|6641c1d000|RCL16ri:%R8W,%R8W,0|r8=d5416bd03863ce3f f=457|f=455/0
  #|rcl r8w, 0|6641c1d000|RCL16ri:%R8W,%R8W,0|r8=4fe5d4d99ac79a9c f=47|f=45/0
  #|rcl r8w, 4|6641c1d004|RCL16ri:%R8W,%R8W,4|r8=aeb357088e929215 f=843|r8=aeb357088e92215c f=841/800
  #|rcl r8w, 4|6641c1d004|RCL16ri:%R8W,%R8W,4|r8=fffffffffffffffe f=883|r8=ffffffffffffffef f=81/800
  #|rcl r8w, 15|6641c1d00f|RCL16ri:%R8W,%R8W,15|r8=2 f=17|r8=4000 f=15/800
  #|rcl r8w, 15|6641c1d00f|RCL16ri:%R8W,%R8W,15|r8=ffff f=c2|r8=bfff f=c1/800
  #|rcl r8w, 16|6641c1d010|RCL16ri:%R8W,%R8W,16|r8=4353b7685f8dc691 f=442|r8=4353b7685f8d6348 f=c41/800
  #|rcl r8w, 16|6641c1d010|RCL16ri:%R8W,%R8W,16|r8=41acd0dd09217763 f=803|r8=41acd0dd0921bbb1 f=801/800
  #|rcl r8w, 17|6641c1d011|RCL16ri:%R8W,%R8W,17|r8=c32af2c4f0105b00 f=897|f=895/800
  #|rcl r8w, 17|6641c1d011|RCL16ri:%R8W,%R8W,17|r8=bd09c9ed11ac45c8 f=4c2|f=4c0/800
  #|rcl r8w, 65|6641c1d041|RCL16ri:%R8W,%R8W,65|r8=f34f92dbdf430179 f=92|r8=f34f92dbdf4302f2 f=90/0
  #|rcl r8w, 65|6641c1d041|RCL16ri:%R8W,%R8W,65|r8=100 f=8d3|r8=201 f=d0/0
  #|rcl word ptr [rbp - 0x20], 1|66d155e0|RCL16m1:%RBP,1,%,-32,%|rbx=b r9=7 f=492 m20160=0c6c743fa0b9c62c238bb07df2fd2dae|f=c90/0 m20160=18d8
  #|rcl word ptr [rbp - 0x20], 1|66d155e0|RCL16m1:%RBP,1,%,-32,%|rbx=2 r9=3 f=853 m20160=e3cdc876e5a437c9a7bc7744abac6b9b|f=51/0 m20160=c79b
  #|rcl word ptr [rbp - 0x20], cl|66d355e0|RCL16mCL:%RBP,1,%,-32,%|rcx=17 rbx=f r9=c f=96 m20160=9b06a46a65e60b9a63178cf016ec19b7|f=895/800 m20160=c0a6
  #|rcl word ptr [rbp - 0x20], cl|66d355e0|RCL16mCL:%RBP,1,%,-32,%|rcx=2 rbx=5 r9=a f=12 m20160=bf2187674e8f30d0a7ffd1ba8e2115db|f=810/800 m20160=fc86
  #|rcl word ptr [rbp - 0x20], cl|66d355e0|RCL16mCL:%RBP,1,%,-32,%|rcx=12 rbx=1 r9=3 f=c7 m20160=3e29c9b7dd763cd3451d5afd1e8cd848|f=c4/800 m20160=7d52
  #|rcl word ptr [rbp - 0x20], cl|66d355e0|RCL16mCL:%RBP,1,%,-32,%|rcx=13 rbx=6 r9=3 f=8c2 m20160=86131172882e92bc0afb107050861bae|f=c0/800 m20160=184e
  #|rcl word ptr [rbp - 0x20], 8|66c155e008|RCL16mi:%RBP,1,%,-32,%,8|rbx=8 r9=a f=806 m20160=4aad0da6ed99e62c08f40dea9a2e915a|f=805/800 m20160=564a
  #|rcl word ptr [rbp - 0x20], 8|66c155e008|RCL16mi:%RBP,1,%,-32,%,8|rbx=e r9=9 f=893 m20160=392b8d3f9a9b159e4c32bfc3902edfdf|f=91/800 m20160=9539
  #|rcl r12d, 1|41d1d4|RCL32r1:%R12D,%R12D|r12=1cac90bc136708f1 f=17|r12=26ce11e3 f=14/0
  #|rcl r12d, cl|41d3d4|RCL32rCL:%R12D,%R12D|rcx=20 r12=1 f=847|f=845/0
  #|rcl r12d, cl|41d3d4|RCL32rCL:%R12D,%R12D|rcx=4 r12=e f=12|r12=e0 f=10/800
  #|rcl r12d, cl|41d3d4|RCL32rCL:%R12D,%R12D|rcx=ff r12=bb9648f92d2d1d0a f=847|r12=4b4b4742 f=45/800
  #|rcl r12d, cl|41d3d4|RCL32rCL:%R12D,%R12D|rcx=4 r12=289ecdfa0c522e2f f=853|r12=c522e2f8 f=850/800
  #|rcl r12d, cl|41d3d4|RCL32rCL:%R12D,%R12D|rcx=1 r12=afbf1d6dfa2dda50 f=8c7|r12=f45bb4a1 f=c5/0
  #|rcl r12d, 0|41c1d400|RCL32ri:%R12D,%R12D,0|r12=924cc1685efa597b f=53|r12=5efa597b f=51/0
  #|rcl r12d, 15|41c1d40f|RCL32ri:%R12D,%R12D,15|r12=ffffffffffffffff f=897|r12=ffffffff f=95/800
  #|rcl r12d, 31|41c1d41f|RCL32ri:%R12D,%R12D,31|r12=c2f2b72034d5a21 f=457|r12=c0d35688 f=c54/800
  #|rcl r12d, 32|41c1d420|RCL32ri:%R12D,%R12D,32|r12=fafd476e30904f3b f=887|r12=30904f3b f=885/0
  #|rcl r12d, 33|41c1d421|RCL32ri:%R12D,%R12D,33|r12=233bc86ad83d85b5 f=12|r12=b07b0b6a f=11/0
  #|rcl dword ptr [rdi + 0x10], 1|d15710|RCL32m1:%RDI,1,%,16,%|rbx=d r9=7 f=c82 m10110=3bd4ebd56d849af7045b3679ae5f8049|f=481/0 m10110=76a8d7ab
  #|rcl dword ptr [rdi + 0x10], 1|d15710|RCL32m1:%RDI,1,%,16,%|rbx=6 r9=8 f=6 m10110=3267537c9ed1355b71aaa7a70c294e08|f=804/0 m10110=64cea6f8
  #|rcl dword ptr [rdi + 0x10], cl|d35710|RCL32mCL:%RDI,1,%,16,%|rcx=21 rbx=4 r9=2 f=46 m10110=e306310c61ac8760d8975313d781da1c|f=44/0 m10110=c60d6218
  #|rcl dword ptr [rdi + 0x10], cl|d35710|RCL32mCL:%RDI,1,%,16,%|rcx=23 rbx=9 r9=4 f=812 m10110=cffcd54582060569bcac2bfcff013ec2|f=10/800 m10110=79e6af2e
  #|rcl dword ptr [rdi + 0x10], cl|d35710|RCL32mCL:%RDI,1,%,16,%|rcx=1a rbx=b r9=4 f=c6 m10110=183bca66f6f92b1acf7c97c0fd1c896c|f=c4/800 m10110=7694cd60
  #|rcl dword ptr [rdi + 0x10], cl|d35710|RCL32mCL:%RDI,1,%,16,%|rcx=a rbx=5 r9=7 f=896 m10110=b5a5447e67bd452cf07f5b335ca17a40|f=95/800 m10110=fcd49612
  #|rcl dword ptr [rdi + 0x10], 25|c1571019|RCL32mi:%RDI,1,%,16,%,25|rbx=2 r9=9 f=8c6 m10110=214f0e8c572aefb025df8f87c0c8b89f|f=8c4/800 m10110=4f0e8c42
  #|rcl dword ptr [rdi + 0x10], 25|c1571019|RCL32mi:%RDI,1,%,16,%,25|rbx=7 r9=b f=c7 m10110=9d02bfb359a2a8b32c32a9fe806dadbc|f=8c5/800 m10110=02bfb33b
  #|rcl rbx, 1|48d1d3|RCL64r1:%RBX,%RBX|rbx=e43d72a3cf15c7b f=8c3|rbx=1c87ae5479e2b8f7 f=c0/0
  #|rcl rbx, cl|48d3d3|RCL64rCL:%RBX,%RBX|rcx=6 rbx=f645e3979adb9a05 f=46|rbx=9178e5e6b6e6815e f=45/800
  #|rcl rbx, cl|48d3d3|RCL64rCL:%RBX,%RBX|rcx=40 rbx=bb2aef54736a048a f=13|f=11/0
  #|rcl rbx, cl|48d3d3|RCL64rCL:%RBX,%RBX|rcx=41 rbx=41a14398041f2a79 f=6|rbx=83428730083e54f2 f=804/0
  #|rcl rbx, cl|48d3d3|RCL64rCL:%RBX,%RBX|rcx=4 rbx=a373bd12d8eb06c8 f=16|rbx=373bd12d8eb06c85 f=814/800
  #|rcl rbx, cl|48d3d3|RCL64rCL:%RBX,%RBX|rcx=3f rbx=3a81fb74e6bb7fff f=52|rbx=8ea07edd39aedfff f=851/800
  #|rcl rbx, 0|48c1d300|RCL64ri:%RBX,%RBX,0|rbx=e1ae5572b38f9f0e f=8d2|f=8d0/0
  #|rcl rbx, 42|48c1d32a|RCL64ri:%RBX,%RBX,42|rbx=23238ea880000000 f=c97|rbx=246471d5100 f=494/800
  #|rcl rbx, 63|48c1d33f|RCL64ri:%RBX,%RBX,63|rbx=ff f=12|rbx=800000000000003f f=811/800
  #|rcl rbx, 64|48c1d340|RCL64ri:%RBX,%RBX,64|rbx=4f981f368e7097bd f=807|f=805/0
  #|rcl rbx, 65|48c1d341|RCL64ri:%RBX,%RBX,65|rbx=7fff f=16|rbx=fffe f=14/0
  #|rcl qword ptr [rsi], 1|48d116|RCL64m1:%RSI,1,%,0,%|rbx=d r9=9 f=846 m10080=834aed173cf30350ddd824a461c326fe|f=844/0 m10080=0695da2f78e607a0
  #|rcl qword ptr [rsi], 1|48d116|RCL64m1:%RSI,1,%,0,%|rbx=a r9=a f=6 m10080=4914bb90f5752a3beaa3fb35bab0aadf|f=4/0 m10080=92287621ebeb5476
  #|rcl qword ptr [rsi], cl|48d316|RCL64mCL:%RSI,1,%,0,%|rcx=13 rbx=8 r9=0 f=806 m10080=3369086aac23ba253febb1018251afe1|f=5/800 m10080=e89698494350631d
  #|rcl qword ptr [rsi], cl|48d316|RCL64mCL:%RSI,1,%,0,%|rcx=1d rbx=8 r9=c f=6 m10080=412d10fdec78d0a0f93e7945d710f131|f=5/800 m10080=8e070d2aa805a29f
  #|rcl qword ptr [rsi], cl|48d316|RCL64mCL:%RSI,1,%,0,%|rcx=a rbx=e r9=5 f=86 m10080=cb4268b6f50c7aa48a03c91cce92a93f|f=85/800 m10080=482d0ba1d9d633e8
  #|rcl qword ptr [rsi], cl|48d316|RCL64mCL:%RSI,1,%,0,%|rcx=11 rbx=3 r9=5 f=886 m10080=be41b72219a6d30a6b67c2e6bc2ce5a8|f=85/800 m10080=d30a7c836e45324c
  #|rcl qword ptr [rsi], 29|48c1161d|RCL64mi:%RSI,1,%,0,%,29|rbx=4 r9=6 f=806 m10080=9dcab05d6679b9ca858b2d79a583f9ae|f=4/800 m10080=9697abac5319b6cb
  #|rcl qword ptr [rsi], 29|48c1161d|RCL64mi:%RSI,1,%,0,%,29|rbx=c r9=4 f=8d2 m10080=55d9b1fd51dc65a619fd46687aba565b|f=8d0/800 m10080=c55d66aa2a3bb63f
  #|rcr al, 1|d0d8|RCR8r1:%AL,%AL|rax=3 f=897|rax=81 f=895/0
  #|rcr al, 1|d0d8|RCR8r1:%AL,%AL|rax=dbbb80cf0336cd66 f=413|rax=dbbb80cf0336cdb3 f=c10/0
  #|rcr al, cl|d2d8|RCR8rCL:%AL,%AL|rax=fffffffffffffffe rcx=8 f=82|rax=fffffffffffffffc f=81/800
  #|rcr al, cl|d2d8|RCR8rCL:%AL,%AL|rax=7fffffffffffffff rcx=3f f=886|rax=7fffffffffffffef f=85/800
  #|rcr al, cl|d2d8|RCR8rCL:%AL,%AL|rax=0 rcx=2 f=57|rax=40 f=54/800
  #|rcr al, cl|d2d8|RCR8rCL:%AL,%AL|rax=8000 rcx=7 f=56|f=54/800
  #|rcr al, cl|d2d8|RCR8rCL:%AL,%AL|rax=2 rcx=3f f=893|rax=50 f=90/800
  #|rcr al, 0|c0d800|RCR8ri:%AL,%AL,0|rax=91 f=842|f=840/0
  #|rcr al, 0|c0d800|RCR8ri:%AL,%AL,0|rax=c0301e73b507fba6 f=852|f=850/0
  #|rcr al, 6|c0d806|RCR8ri:%AL,%AL,6|rax=ea f=892|rax=53 f=891/800
  #|rcr al, 6|c0d806|RCR8ri:%AL,%AL,6|rax=bcc4d8c308a55df8 f=97|rax=bcc4d8c308a55dc7 f=95/800
  #|rcr al, 7|c0d807|RCR8ri:%AL,%AL,7|rax=ffff f=8d6|rax=fffd f=d5/800
  #|rcr al, 7|c0d807|RCR8ri:%AL,%AL,7|rax=e62d035790ef914e f=d7|rax=e62d035790ef913a f=d5/800
  #|rcr al, 8|c0d808|RCR8ri:%AL,%AL,8|rax=3d f=c2|rax=7a f=c0/800
  #|rcr al, 8|c0d808|RCR8ri:%AL,%AL,8|rax=c8d79d0a50b26239 f=12|rax=c8d79d0a50b26272 f=10/800
  #|rcr al, 9|c0d809|RCR8ri:%AL,%AL,9|rax=6237c79d72284345 f=7|f=5/800
  #|rcr al, 9|c0d809|RCR8ri:%AL,%AL,9|rax=bab6962dd6553052 f=893|f=891/800
  #|rcr al, 33|c0d821|RCR8ri:%AL,%AL,33|rax=a0b87ea337793a79 f=82|rax=a0b87ea337793a3c f=81/0
  #|rcr al, 33|c0d821|RCR8ri:%AL,%AL,33|rax=5168e0191709fcb6 f=cd3|rax=5168e0191709fcdb f=4d0/0
  #|rcr byte ptr [rdi + 0x10], 1|d05f10|RCR8m1:%RDI,1,%,16,%|rbx=b r9=b f=8d2 m10110=8128c5dc8a065a83b54009890f6cd539|f=8d1/0 m10110=40
  #|rcr byte ptr [rdi + 0x10], 1|d05f10|RCR8m1:%RDI,1,%,16,%|rbx=d r9=2 f=887 m10110=9bc1d0c73907a2ac2d9c08325bb102da|f=85/0 m10110=cd
  #|rcr byte ptr [rdi + 0x10], cl|d25f10|RCR8mCL:%RDI,1,%,16,%|rcx=25 rbx=e r9=2 f=2 m10110=ef45693179cb3a35f874fab171c6846b|f=0/800 m10110=f7
  #|rcr byte ptr [rdi + 0x10], cl|d25f10|RCR8mCL:%RDI,1,%,16,%|rcx=27 rbx=0 r9=2 f=52 m10110=bdbb9a24b01655e05e07c8605cadb842|f=50/800 m10110=f5
  #|rcr byte ptr [rdi + 0x10], cl|d25f10|RCR8mCL:%RDI,1,%,16,%|rcx=12 rbx=6 r9=c f=87 m10110=fda48eb874f3c9d70bf50110ef7c374f|f=85/800
  #|rcr byte ptr [rdi + 0x10], cl|d25f10|RCR8mCL:%RDI,1,%,16,%|rcx=12 rbx=9 r9=2 f=812 m10110=6f4ffafc406b8a940d5b76b9986ff632|f=810/800
  #|rcr byte ptr [rdi + 0x10], 2|c05f1002|RCR8mi:%RDI,1,%,16,%,2|rbx=9 r9=d f=403 m10110=d8562bc21c224721e166fbb739b1fc3c|f=c00/800 m10110=76
  #|rcr byte ptr [rdi + 0x10], 2|c05f1002|RCR8mi:%RDI,1,%,16,%,2|rbx=6 r9=3 f=d7 m10110=7c239beee0d5737af4322b2510667994|f=d4/800 m10110=5f
  #|rcr r12w, 1|6641d1dc|RCR16r1:%R12W,%R12W|r12=1 f=8d7|r12=8000 f=8d5/0
  #|rcr r12w, 1|6641d1dc|RCR16r1:%R12W,%R12W|r12=b8ccaaa8f1e93b2b f=2|r12=b8ccaaa8f1e91d95 f=1/0
  #|rcr r12w, cl|6641d3dc|RCR16rCL:%R12W,%R12W|rcx=6 r12=100 f=892|r12=4 f=90/800
  #|rcr r12w, cl|6641d3dc|RCR16rCL:%R12W,%R12W|rcx=81 r12=4a3e4b8effffffff f=47|f=45/0
  #|rcr r12w, cl|6641d3dc|RCR16rCL:%R12W,%R12W|rcx=0 r12=80000000 f=92|f=90/0
  #|rcr r12w, cl|6641d3dc|RCR16rCL:%R12W,%R12W|rcx=3f r12=5ef05af29ea79a04 f=417|r12=5ef05af29ea7d026 f=414/800
  #|rcr r12w, cl|6641d3dc|RCR16rCL:%R12W,%R12W|rcx=40 r12=89eff29c832683eb f=c52|f=c50/0
  #|rcr r12w, 0|6641c1dc00|RCR16ri:%R12W,%R12W,0|r12=c0 f=cc3|f=cc1/0
  #|rcr r12w, 0|6641c1dc00|RCR16ri:%R12W,%R12W,0|r12=7fffffffffffffff f=57|f=55/0
  #|rcr r12w, 8|6641c1dc08|RCR16ri:%R12W,%R12W,8|r12=8f62de13105de27f f=56|r12=8f62de13105dfee2 f=54/800
  #|rcr r12w, 8|6641c1dc08|RCR16ri:%R12W,%R12W,8|r12=b0a1 f=cc7|r12=43b0 f=cc5/800
  #|rcr r12w, 15|6641c1dc0f|RCR16ri:%R12W,%R12W,15|r12=9675ab475067260 f=883|r12=9675ab47506c982 f=881/800
  #|rcr r12w, 15|6641c1dc0f|RCR16ri:%R12W,%R12W,15|r12=9 f=7|r12=26 f=4/800
  #|rcr r12w, 16|6641c1dc10|RCR16ri:%R12W,%R12W,16|r12=204a904844309e5c f=86|r12=204a904844303cb8 f=885/800
  #|rcr r12w, 16|6641c1dc10|RCR16ri:%R12W,%R12W,16|r12=b851f940614d24ec f=42|r12=b851f940614d49d8 f=40/800
  #|rcr r12w, 17|6641c1dc11|RCR16ri:%R12W,%R12W,17|r12=57db9a0360940009 f=96|f=94/800
  #|rcr r12w, 17|6641c1dc11|RCR16ri:%R12W,%R12W,17|r12=ffffffffffffffff f=12|f=10/800
  #|rcr r12w, 64|6641c1dc40|RCR16ri:%R12W,%R12W,64|r12=2892621a84b0fff7 f=852|f=850/0
  #|rcr r12w, 64|6641c1dc40|RCR16ri:%R12W,%R12W,64|r12=cecf f=2|f=0/0
  #|rcr word ptr [rsi], 1|66d11e|RCR16m1:%RSI,1,%,0,%|rbx=7 r9=5 f=42 m10080=7248a19649dba673e2c5655c8fafeda6|f=40/0 m10080=3924
  #|rcr word ptr [rsi], 1|66d11e|RCR16m1:%RSI,1,%,0,%|rbx=4 r9=6 f=803 m10080=8cf7c553ad6dcd2425265ffa647e6ce6|f=0/0 m10080=c6fb
  #|rcr word ptr [rsi], cl|66d31e|RCR16mCL:%RSI,1,%,0,%|rcx=0 rbx=7 r9=6 f=cc7 m10080=5743a50c3e746c0c7892916e1c3687fd|f=cc5/0
  #|rcr word ptr [rsi], cl|66d31e|RCR16mCL:%RSI,1,%,0,%|rcx=c rbx=e r9=7 f=812 m10080=d8515ba2b1953a9da2f7d4f903a036cb|f=10/800 m10080=053b
  #|rcr word ptr [rsi], cl|66d31e|RCR16mCL:%RSI,1,%,0,%|rcx=24 rbx=1 r9=6 f=806 m10080=f6cb0555f5279aa9bcea0ab200adaa05|f=4/800 m10080=bfcc
  #|rcr word ptr [rsi], cl|66d31e|RCR16mCL:%RSI,1,%,0,%|rcx=d rbx=6 r9=2 f=4d3 m10080=8193158f86deeed1ae40793c2e58f8b1|f=cd1/800 m10080=1c38
  #|rcr word ptr [rsi], 5|66c11e05|RCR16mi:%RSI,1,%,0,%,5|rbx=2 r9=5 f=8c3 m10080=9c36c9a5b2c6122f2f61ce2c8cb08109|f=8c1/800 m10080=b4c9
  #|rcr word ptr [rsi], 5|66c11e05|RCR16mi:%RSI,1,%,0,%,5|rbx=2 r9=3 f=c03 m10080=705ef4103b06afbc4aff1a97f5cf5f41|f=401/800 m10080=f30a
  #|rcr eax, 1|d1d8|RCR32r1:%EAX,%EAX|rax=6075eb4f2d62b3b3 f=c6|rax=16b159d9 f=c5/0
  #|rcr eax, cl|d3d8|RCR32rCL:%EAX,%EAX|rax=4e63647e9c9441dc rcx=20 f=13|rax=9c9441dc f=11/0
  #|rcr eax, cl|d3d8|RCR32rCL:%EAX,%EAX|rax=e691182e8045a4fb rcx=81 f=817|rax=c022d27d f=15/0
  #|rcr eax, cl|d3d8|RCR32rCL:%EAX,%EAX|rax=1df1b4df7fffffff rcx=1f f=8d7|rax=fffffffe f=8d5/800
  #|rcr eax, cl|d3d8|RCR32rCL:%EAX,%EAX|rax=d1d6a66d42813ec8 rcx=2 f=53|rax=50a04fb2 f=50/800
  #|rcr eax, cl|d3d8|RCR32rCL:%EAX,%EAX|rax=80 rcx=2 f=8c2|rax=20 f=c0/800
  #|rcr eax, 0|c1d800|RCR32ri:%EAX,%EAX,0|rax=fbd9be2a3a33bf54 f=412|rax=3a33bf54 f=410/0
  #|rcr eax, 23|c1d817|RCR32ri:%EAX,%EAX,23|rax=7fffffff f=c7|rax=fffffeff f=8c5/800
  #|rcr eax, 31|c1d81f|RCR32ri:%EAX,%EAX,31|rax=acfaf1131865f992 f=802|rax=6197e648 f=0/800
  #|rcr eax, 32|c1d820|RCR32ri:%EAX,%EAX,32|rax=8f8f481ad64f6c6a f=843|rax=d64f6c6a f=841/0
  #|rcr eax, 33|c1d821|RCR32ri:%EAX,%EAX,33|rax=7fffffffffffffff f=846|rax=7fffffff f=845/0
  #|rcr eax, 64|c1d840|RCR32ri:%EAX,%EAX,64|rax=81b204c22ee852a6 f=c7|rax=2ee852a6 f=c5/0
  #|rcr dword ptr [rdi + r9*2 - 0x4], 1|42d15c4ffc|RCR32m1:%RDI,2,%R9,-4,%|rbx=2 r9=f f=446 m1011a=22d762bc26a60383b92cf485ada2fdb0|f=c44/0 m1011a=916b315e
  #|rcr dword ptr [rdi + r9*2 - 0x4], 1|42d15c4ffc|RCR32m1:%RDI,2,%R9,-4,%|rbx=b r9=2 f=c6 m10100=154afa415c2143dd9291892c796766f2|f=c5/0 m10100=0a25fd20
  #|rcr dword ptr [rdi + r9*2 - 0x4], cl|42d35c4ffc|RCR32mCL:%RDI,2,%R9,-4,%|rcx=9 rbx=5 r9=5 f=8d3 m10106=531bffb708b4c439011950af681888a8|f=8d1/800 m10106=8dffdb53
  #|rcr dword ptr [rdi + r9*2 - 0x4], cl|42d35c4ffc|RCR32mCL:%RDI,2,%R9,-4,%|rcx=25 rbx=b r9=0 f=d2 m100fc=496ef1659cd4dc5825d2234721f1a350|f=8d0/800 m100fc=728b2f93
  #|rcr dword ptr [rdi + r9*2 - 0x4], cl|42d35c4ffc|RCR32mCL:%RDI,2,%R9,-4,%|rcx=3 rbx=4 r9=5 f=806 m10106=f287963571f05585f7456835077528bd|f=804/800 m10106=fed0b286
  #|rcr dword ptr [rdi + r9*2 - 0x4], cl|42d35c4ffc|RCR32mCL:%RDI,2,%R9,-4,%|rcx=d rbx=a r9=8 f=cd7 m1010c=b038792a989fb5e0cb8037ca5372bbc0|f=cd5/800 m1010c=c953098b
  #|rcr dword ptr [rdi + r9*2 - 0x4], 28|42c15c4ffc1c|RCR32mi:%RDI,2,%R9,-4,%,28|rbx=a r9=1 f=57 m100fe=acbd7eec28c53e712afc4480876cf44a|f=55/800 m100fe=9eb5d78f
  #|rcr dword ptr [rdi + r9*2 - 0x4], 28|42c15c4ffc1c|RCR32mi:%RDI,2,%R9,-4,%,28|rbx=5 r9=1 f=416 m100fe=080edf0cf3c7f55eae0d174234ff5224|f=c15/800 m100fe=00c1e19b
  #|rcr r8, 1|49d1d8|RCR64r1:%R8,%R8|r8=bd225a3c95e3c434 f=82|r8=5e912d1e4af1e21a f=880/0
  #|rcr r8, cl|49d3d8|RCR64rCL:%R8,%R8|rcx=1f r8=7a325e6057f436f8 f=886|r8=5fd0dbe0f464bcc0 f=85/800
  #|rcr r8, cl|49d3d8|RCR64rCL:%R8,%R8|rcx=7 r8=692f79cdba75a900 f=807|r8=2d25ef39b74eb52 f=4/800
  #|rcr r8, cl|49d3d8|RCR64rCL:%R8,%R8|rcx=40 r8=d90f18041d952814 f=c86|f=c84/0
  #|rcr r8, cl|49d3d8|RCR64rCL:%R8,%R8|rcx=41 r8=2c01f73f6501a6ff f=496|r8=1600fb9fb280d37f f=495/0
  #|rcr r8, cl|49d3d8|RCR64rCL:%R8,%R8|rcx=4 r8=ed167e2715b0335c f=4c7|r8=9ed167e2715b0335 f=4c5/800
  #|rcr r8, 0|49c1d800|RCR64ri:%R8,%R8,0|r8=e0 f=d6|f=d4/0
  #|rcr r8, 18|49c1d812|RCR64ri:%R8,%R8,18|r8=8000 f=56|r8=4000000000000000 f=54/800
  #|rcr r8, 63|49c1d83f|RCR64ri:%R8,%R8,63|r8=9c5dedb1cbf6e95f f=47|r8=7177b6c72fdba57f f=844/800
  #|rcr r8, 64|49c1d840|RCR64ri:%R8,%R8,64|r8=0 f=82|f=80/0
  #|rcr r8, 65|49c1d841|RCR64ri:%R8,%R8,65|r8=ffffffffffffffff f=46|r8=7fffffffffffffff f=845/0
  #|rcr qword ptr [rdi + r9*2 - 0x4], 1|4ad15c4ffc|RCR64m1:%RDI,2,%R9,-4,%|rbx=4 r9=e f=847 m10118=4998a50c75e78141b365aa3d1f306e2e|f=845/0 m10118=24cc5286baf3c0a0
  #|rcr qword ptr [rdi + r9*2 - 0x4], 1|4ad15c4ffc|RCR64m1:%RDI,2,%R9,-4,%|rbx=f r9=c f=846 m10114=6d84ee8006a38d8b593e3d5fb2984f5e|f=845/0 m10114=3642774083d1c645
  #|rcr qword ptr [rdi + r9*2 - 0x4], cl|4ad35c4ffc|RCR64mCL:%RDI,2,%R9,-4,%|rcx=17 rbx=8 r9=5 f=82 m10106=e65911bf995ac9806718d58fe4d405a9|f=880/800 m10106=7e33b59201996745
  #|rcr qword ptr [rdi + r9*2 - 0x4], cl|4ad35c4ffc|RCR64mCL:%RDI,2,%R9,-4,%|rcx=17 rbx=7 r9=d f=813 m10116=aa048cfcb6b302c37e3c150f72638dcf|f=810/800 m10116=f96d670586ab1230
  #|rcr qword ptr [rdi + r9*2 - 0x4], cl|4ad35c4ffc|RCR64mCL:%RDI,2,%R9,-4,%|rcx=7 rbx=1 r9=6 f=803 m10108=b760d3c33c0d4678ec93b0e41c31b64f|f=800/800 m10108=c1a687791a8cf0de
  #|rcr qword ptr [rdi + r9*2 - 0x4], cl|4ad35c4ffc|RCR64mCL:%RDI,2,%R9,-4,%|rcx=3 rbx=f r9=6 f=d6 m10108=1ba1a6e4daaf60a7a36371c24ba15538|f=d4/800 m10108=23d4945cfb15ecd4
  #|rcr qword ptr [rdi + r9*2 - 0x4], 5|4ac15c4ffc05|RCR64mi:%RDI,2,%R9,-4,%,5|rbx=d r9=f f=847 m1011a=daa7d5ac05bafd9ff1cf8d01dcdd498e|f=45/800 m1011a=3ead662dd0edffac
  #|rcr qword ptr [rdi + r9*2 - 0x4], 5|4ac15c4ffc05|RCR64mi:%RDI,2,%R9,-4,%,5|rbx=e r9=8 f=43 m1010c=1dfbf51590ed41770815cee99ba2a027|f=841/800 m1010c=d8afaf806c0fbadb
  #|shl eax, 1 (c1)|c1e001|SHL32ri:%EAX,%EAX,1|rax=4d37301c447e0082 f=86|rax=88fc0104 f=880/10
  #|shl eax, 1 (c1)|c1e001|SHL32ri:%EAX,%EAX,1|rax=d068f140ffffffff f=8d3|rax=fffffffe f=81/10
  #|shl eax, 1 (c1)|c1e001|SHL32ri:%EAX,%EAX,1|rax=da1aeefecd2a719 f=d3|rax=d9a54e32 f=81/10
  #|rol ebx, 1 (c1)|c1c301|ROL32ri:%EBX,%EBX,1|rbx=dd9ccf6cb81417f f=847|rbx=970282ff f=45/0
  #|rol ebx, 1 (c1)|c1c301|ROL32ri:%EBX,%EBX,1|rbx=7cec019952c75240 f=12|rbx=a58ea480 f=810/0
  #|rol ebx, 1 (c1)|c1c301|ROL32ri:%EBX,%EBX,1|rbx=288fe49cffffffff f=493|rbx=ffffffff f=491/0
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|rdx=57a8b5a5ea148c03 f=c47|rdx=57a8b5a5ea148c01 f=401/10
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|rdx=ac914a8d00b5372e f=8d3|rdx=ac914a8d00b53717 f=4/10
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|rdx=ffffffff f=57|f=85/10
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|rcx=40 f=882|rcx=20 f=80/0
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|rcx=d6b451eecae87bfb f=8c2|rcx=65743dfd f=8c1/0
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|rcx=47298148ade72285 f=883|rcx=d6f39142 f=81/0
  #|sal eax, cl (d3 /6)|d3f0|?|rax=893dbb8a481d2a98 rcx=1 f=816|rax=903a5530 f=884/10
  #|sal eax, cl (d3 /6)|d3f0|?|rax=a6e8f2d7a41c2bfd rcx=1c f=53|rax=d0000000 f=85/810
  #|sal eax, cl (d3 /6)|d3f0|?|rax=44cea4d7805e12e8 rcx=7 f=892|rax=2f097400 f=4/810
  #|shld ax, r11w, 1|66440fa4d801|SHLD16rri8:%AX,%AX,%R11W,1|rax=6da6e5e34889217b r11=8000000000000000 f=87|rax=6da6e5e3488942f6 f=4/10
  #|shld ax, r11w, 1|66440fa4d801|SHLD16rri8:%AX,%AX,%R11W,1|rax=ff r11=2fd7be87c52edc07 f=16|rax=1ff f=4/10
  #|shld ax, r11w, 0|66440fa4d800|SHLD16rri8:%AX,%AX,%R11W,0|rax=845835a29f631cda r11=54c6cbbe7e1e0733 f=806|f=804/0
  #|shld ax, r11w, 0|66440fa4d800|SHLD16rri8:%AX,%AX,%R11W,0|rax=8f r11=80000000 f=53|f=51/0
  #|shld ax, r11w, 14|66440fa4d80e|SHLD16rri8:%AX,%AX,%R11W,14|rax=fffffffffffffffe r11=50c4e1353a2316b1 f=52|rax=ffffffffffff85ac f=85/810
  #|shld ax, r11w, 14|66440fa4d80e|SHLD16rri8:%AX,%AX,%R11W,14|rax=817f7dc64f5f323d r11=8c f=c02|rax=817f7dc64f5f4023 f=c01/810
  #|shld ax, r11w, 15|66440fa4d80f|SHLD16rri8:%AX,%AX,%R11W,15|rax=ab66b4424a3963d0 r11=b923f616abac17e7 f=7|rax=ab66b4424a390bf3 f=4/810
  #|shld ax, r11w, 15|66440fa4d80f|SHLD16rri8:%AX,%AX,%R11W,15|rax=69b4d2721f05746e r11=99280221038f57b4 f=412|rax=69b4d2721f052bda f=c01/810
  #|shld ax, r11w, 17|66440fa4d811|SHLD16rri8:%AX,%AX,%R11W,17|rax=8 r11=ecc41965f816507f f=c57|rax=? f=c80/8d5
  #|shld ax, r11w, 17|66440fa4d811|SHLD16rri8:%AX,%AX,%R11W,17|rax=2 r11=f2384c5433b526dc f=887|rax=? f=4/8d5
  #|shld ax, r11w, 20|66440fa4d814|SHLD16rri8:%AX,%AX,%R11W,20|rax=0 r11=ff f=403|rax=? f=404/8d5
  #|shld ax, r11w, 20|66440fa4d814|SHLD16rri8:%AX,%AX,%R11W,20|rax=e45cd15b077a3d8c r11=3fc7a4ea6a3500a9 f=857|rax=? f=4/8d5
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=7fffffff rcx=f r11=32 f=483|rax=7fff8019 f=481/810
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=251e6b55fde5988a rcx=3 r11=24b2cb480000000 f=8c7|rax=251e6b55fde5c450 f=884/810
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=a08b9966d8108000 rcx=1 r11=76 f=c53|rax=a08b9966d8100000 f=c45/10
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=9648b4a6110ca878 rcx=4 r11=ffffffffffffffff f=56|rax=9648b4a6110c878f f=880/810
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=2901f7cf5b7cd477 rcx=40 r11=ffffffffffffffff f=446|f=444/0
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=fffffffffffffffe rcx=3 r11=397817526a8dea94 f=892|rax=fffffffffffffff7 f=81/810
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=66f847a03fd09d58 rcx=4 r11=5b42a9427253f769 f=847|rax=66f847a03fd0d58f f=81/810
  #|shld ax, r11w, cl|66440fa5d8|SHLD16rrCL:%AX,%AX,%R11W|rax=1b rcx=ff r11=149a070680000000 f=8c7|rax=? f=0/8d5
  #|shld word ptr [rbp - 0x20], r11w, 11|66440fa45de00b|SHLD16mri8:%RBP,1,%,-32,%,%R11W,11|rbx=1 r9=a r11=ffff f=803 m20160=5276bc1dbc9b1702d5a21f1ae937a99d|f=884/810 m20160=ff97
  #|shld word ptr [rbp - 0x20], r11w, 11|66440fa45de00b|SHLD16mri8:%RBP,1,%,-32,%,%R11W,11|rbx=a r9=a r11=2cd435e0733b6c19 f=857 m20160=60155c401124c66e926c7224af1381c1|f=805/810 m20161=03
  #|shld r12d, eax, 1|410fa4c401|SHLD32rri8:%R12D,%R12D,%EAX,1|rax=2 r12=b0bcc4666198bfd3 f=803|r12=c3317fa6 f=884/10
  #|shld r12d, eax, 1|410fa4c401|SHLD32rri8:%R12D,%R12D,%EAX,1|rax=6aa62745062c318a r12=fffffffffffffffe f=893|r12=fffffffc f=85/10
  #|shld r12d, eax, 0|410fa4c400|SHLD32rri8:%R12D,%R12D,%EAX,0|rax=cd3dee1c777c182 r12=76ac861551e5f2c0 f=c03|r12=51e5f2c0 f=c01/0
  #|shld r12d, eax, 0|410fa4c400|SHLD32rri8:%R12D,%R12D,%EAX,0|rax=4d6b1f0cc5949d4b r12=1 f=803|f=801/0
  #|shld r12d, eax, 28|410fa4c41c|SHLD32rri8:%R12D,%R12D,%EAX,28|rax=8a7c83f94e98a7f r12=1a0d2c1aab773ff1 f=817|r12=194e98a7 f=801/810
  #|shld r12d, eax, 28|410fa4c41c|SHLD32rri8:%R12D,%R12D,%EAX,28|rax=6b63c5c46860a19d r12=4 f=8c2|r12=46860a19 f=0/810
  #|shld r12d, eax, 31|410fa4c41f|SHLD32rri8:%R12D,%R12D,%EAX,31|rax=ffffffffffffffff r12=334ac995baf1f5fc f=42|r12=7fffffff f=4/810
  #|shld r12d, eax, 31|410fa4c41f|SHLD32rri8:%R12D,%R12D,%EAX,31|rax=c1243b75b4e05a61 r12=a3677b269a63dca2 f=852|r12=5a702d30 f=805/810
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=1b23f3dab9291e2e rcx=3 r12=a246bc529e21403b f=c12|r12=f10a01dd f=c84/810
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=2dbb77977a07a9f3 rcx=40 r12=37be9dbd188dc929 f=893|r12=188dc929 f=891/0
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=7a7488d323bc6363 rcx=3f r12=b3be f=883|r12=11de31b1 f=805/810
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=99 rcx=1f r12=21b2ce5643168a93 f=442|r12=8000004c f=481/810
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=32b9a68d461df6cd rcx=21 r12=5d5cf7ebff81b0fd f=412|r12=ff0361fa f=485/10
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=1d7daddacde63851 rcx=21 r12=8000000000000000 f=7|r12=1 f=0/10
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=aaa3fe30fe3337b5 rcx=4 r12=a7 f=813|r12=a7f f=0/810
  #|shld r12d, eax, cl|410fa5c4|SHLD32rrCL:%R12D,%R12D,%EAX|rax=41c6ede0a1669500 rcx=2 r12=b3989eac979b9b5e f=802|r12=5e6e6d7a f=0/810
  #|shld dword ptr [rsp + 0x8], eax, 5|0fa444240805|SHLD32mri8:%RSP,1,%,8,%,%EAX,5|rax=52716a918d90a2ff rbx=8 r9=1 f=c43 m20108=b2b23db0033ddfec9fc6c7c4b27e1af3|f=400/810 m20108=5156b607
  #|shld dword ptr [rsp + 0x8], eax, 5|0fa444240805|SHLD32mri8:%RSP,1,%,8,%,%EAX,5|rax=f2 rbx=0 r9=a f=412 m20108=c73e6abb433fb6496473ab96737380b7|f=c01/810 m20108=e0d8476d
  #|shld r14, rcx, 1|490fa4ce01|SHLD64rri8:%R14,%R14,%RCX,1|rcx=ffff r14=1eb97c6f4c6d1042 f=16|r14=3d72f8de98da2084 f=4/10
  #|shld r14, rcx, 1|490fa4ce01|SHLD64rri8:%R14,%R14,%RCX,1|rcx=35bb5016a4aecb93 r14=820a3a4cfc144266 f=892|r14=4147499f82884cc f=805/10
  #|shld r14, rcx, 0|490fa4ce00|SHLD64rri8:%R14,%R14,%RCX,0|rcx=f1b3 r14=8d557f4c039a3dfe f=d3|f=d1/0
  #|shld r14, rcx, 0|490fa4ce00|SHLD64rri8:%R14,%R14,%RCX,0|rcx=6dbf61851afc8000 r14=c0ddcf44d8802fc f=7|f=5/0
  #|shld r14, rcx, 55|490fa4ce37|SHLD64rri8:%R14,%R14,%RCX,55|rcx=37 r14=da3c30f920fd2f3a f=56|r14=9d00000000000000 f=85/810
  #|shld r14, rcx, 55|490fa4ce37|SHLD64rri8:%R14,%R14,%RCX,55|rcx=100 r14=6c f=7|r14=3600000000000000 f=4/810
  #|shld r14, rcx, 63|490fa4ce3f|SHLD64rri8:%R14,%R14,%RCX,63|rcx=242476e330ef72af r14=170c62d7e56356ba f=813|r14=12123b719877b957 f=801/810
  #|shld r14, rcx, 63|490fa4ce3f|SHLD64rri8:%R14,%R14,%RCX,63|rcx=f67fdd7e4bef40ec r14=ffff f=d7|r14=fb3feebf25f7a076 f=81/810
  #|shld qword ptr [rbp - 0x20], rcx, 17|480fa44de011|SHLD64mri8:%RBP,1,%,-32,%,%RCX,17|rcx=368d478b4787d531 rbx=f r9=d f=802 m20160=b2500c3bc6f27e4d9a10bb1df6b322c3|f=81/810 m20160=1a6d64a118768ce5
  #|shld qword ptr [rbp - 0x20], rcx, 17|480fa44de011|SHLD64mri8:%RBP,1,%,-32,%,%RCX,17|rcx=898238c148b69385 rbx=d r9=1 f=c82 m20160=7cb9352e0b9d5c34c644abc03c1d8ebd|f=c01/810 m20160=0413f9726b5c163a
  #|shrd r12w, r11w, 1|66450facdc01|SHRD16rri8:%R12W,%R12W,%R11W,1|r11=fffffffffffffffe r12=4cb2b23d00ffae0b f=847|r12=4cb2b23d00ff5705 f=805/10
  #|shrd r12w, r11w, 1|66450facdc01|SHRD16rri8:%R12W,%R12W,%R11W,1|r11=f379acc5500fdd5e r12=8 f=897|r12=4 f=0/10
  #|shrd r12w, r11w, 0|66450facdc00|SHRD16rri8:%R12W,%R12W,%R11W,0|r11=d098767f33c561c4 r12=ad56c0147d6b9571 f=6|f=4/0
  #|shrd r12w, r11w, 0|66450facdc00|SHRD16rri8:%R12W,%R12W,%R11W,0|r11=70746d9aa1a29429 r12=6f38b3ddbc0d982d f=cc2|f=cc0/0
  #|shrd r12w, r11w, 11|66450facdc0b|SHRD16rri8:%R12W,%R12W,%R11W,11|r11=1 r12=104b f=802|r12=22 f=4/810
  #|shrd r12w, r11w, 11|66450facdc0b|SHRD16rri8:%R12W,%R12W,%R11W,11|r11=8041ce7a0fb9231b r12=de8b2778435eff9d f=c42|r12=de8b2778435e637f f=c01/810
  #|shrd r12w, r11w, 15|66450facdc0f|SHRD16rri8:%R12W,%R12W,%R11W,15|r11=f r12=4d3d7735a872261a f=8d3|r12=4d3d7735a872001e f=4/810
  #|shrd r12w, r11w, 15|66450facdc0f|SHRD16rri8:%R12W,%R12W,%R11W,15|r11=7a6b0db0a40c12df r12=284bbf4080000000 f=52|r12=284bbf40800025be f=4/810
  #|shrd r12w, r11w, 17|66450facdc11|SHRD16rri8:%R12W,%R12W,%R11W,17|r11=9240c67e4baa8b84 r12=e3aee5d8351eb200 f=897|r12=? f=800/8d5
  #|shrd r12w, r11w, 17|66450facdc11|SHRD16rri8:%R12W,%R12W,%R11W,17|r11=45 r12=811362e210c8867f f=2|r12=? f=885/8d5
  #|shrd r12w, r11w, 20|66450facdc14|SHRD16rri8:%R12W,%R12W,%R11W,20|r11=3fe8160cd0755296 r12=21126898a4c45a13 f=c2|r12=? f=0/8d5
  #|shrd r12w, r11w, 20|66450facdc14|SHRD16rri8:%R12W,%R12W,%R11W,20|r11=ca7fb12123406741 r12=365f2a67f797cd00 f=8d2|r12=? f=4/8d5
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=1f r11=83c3260d39145200 r12=759f03297f82fa0a f=897|r12=? f=85/8d5
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=0 r11=fa6ec6a318a68003 r12=7fffffffffffffff f=52|f=50/0
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=f r11=3202acb145614f6f r12=0 f=13|r12=9ede f=884/810
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=1 r11=1 r12=39 f=806|r12=801c f=881/10
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=40 r11=16717a479b31bc88 r12=d442f2a67f67c223 f=4d2|f=4d0/0
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=1 r11=7f r12=8 f=853|r12=8004 f=880/10
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=ff r11=a1f3fa9d3aac7e00 r12=6e9f11bda57358d2 f=8c7|r12=? f=881/8d5
  #|shrd r12w, r11w, cl|66450faddc|SHRD16rrCL:%R12W,%R12W,%R11W|rcx=0 r11=46ec4f392148cbd9 r12=18f3fe9e5b2f7900 f=96|f=94/0
  #|shrd word ptr [rdi + r9*2 - 0x4], r11w, 5|66460fac5c4ffc05|SHRD16mri8:%RDI,2,%R9,-4,%,%R11W,5|rbx=c r9=d r11=ec f=8d3 m10116=d5f0f6b3d331c8af4200c7b7517b1e53|f=801/810 m10116=8667
  #|shrd word ptr [rdi + r9*2 - 0x4], r11w, 5|66460fac5c4ffc05|SHRD16mri8:%RDI,2,%R9,-4,%,%R11W,5|rbx=0 r9=5 r11=783b54494741556e f=57 m10106=45ef9ffa6bbdd5ab1cee6ab0319274a2|f=800/810 m10106=7a77
  #|shrd r9d, r13d, 1|450face901|SHRD32rri8:%R9D,%R9D,%R13D,1|r9=ca60c3728931561e r13=1a795905f9ce8554 f=8c2|r9=4498ab0f f=804/10
  #|shrd r9d, r13d, 1|450face901|SHRD32rri8:%R9D,%R9D,%R13D,1|r9=7fff r13=5 f=43|r9=80003fff f=885/10
  #|shrd r9d, r13d, 0|450face900|SHRD32rri8:%R9D,%R9D,%R13D,0|r9=abb15f11c5b2e555 r13=8c2d9fa24c225836 f=857|r9=c5b2e555 f=855/0
  #|shrd r9d, r13d, 0|450face900|SHRD32rri8:%R9D,%R9D,%R13D,0|r9=fffffffffffffffe r13=f97ae790233e47cc f=4d3|r9=fffffffe f=4d1/0
  #|shrd r9d, r13d, 5|450face905|SHRD32rri8:%R9D,%R9D,%R13D,5|r9=4c76e42e1f22425d r13=d95f42584eb9e099 f=d3|r9=c8f91212 f=85/810
  #|shrd r9d, r13d, 5|450face905|SHRD32rri8:%R9D,%R9D,%R13D,5|r9=583b677480000000 r13=bcd68e21d22141e8 f=847|r9=44000000 f=804/810
  #|shrd r9d, r13d, 31|450face91f|SHRD32rri8:%R9D,%R9D,%R13D,31|r9=780457081edadeea r13=e2c5 f=856|r9=1c58a f=0/810
  #|shrd r9d, r13d, 31|450face91f|SHRD32rri8:%R9D,%R9D,%R13D,31|r9=a3c1c029ab755bd9 r13=efe79bb050de77a0 f=897|r9=a1bcef41 f=884/810
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=0 r9=7fb7fbd8cc698b8d r13=ffffffffffffffff f=12|r9=cc698b8d f=10/0
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=20 r9=9e3c0bb12ccf23d0 r13=1fdd194ff11b1a84 f=8c3|r9=2ccf23d0 f=8c1/0
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=4 r9=9 r13=f1623d764d16073f f=c2|r9=f0000000 f=85/810
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=40 r9=4e5e4706e6b5e41b r13=180878464a32a230 f=82|r9=e6b5e41b f=80/0
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=ff r9=bce478fb8adf35f4 r13=7d0f17370e081955 f=17|r9=1c1032ab f=0/810
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=4 r9=7a635142bf76ead1 r13=1 f=817|r9=1bf76ead f=0/810
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=1 r9=cd3e2c6276c6ac8e r13=819035b60c2ab1f4 f=842|r9=3b635647 f=4/10
  #|shrd r9d, r13d, cl|450fade9|SHRD32rrCL:%R9D,%R9D,%R13D|rcx=1f r9=b r13=80 f=c12|r9=100 f=404/810
  #|shrd dword ptr [rdi + r9*2 - 0x4], r13d, 30|460fac6c4ffc1e|SHRD32mri8:%RDI,2,%R9,-4,%,%R13D,30|rbx=7 r9=3 r13=829fee436ed8d9e0 f=8d7 m10102=fead53450ac5d7c864307b33cd4a0772|f=884/810 m10102=816763bb
  #|shrd dword ptr [rdi + r9*2 - 0x4], r13d, 30|460fac6c4ffc1e|SHRD32mri8:%RDI,2,%R9,-4,%,%R13D,30|rbx=6 r9=7 r13=ff f=8d2 m1010a=8ce717c0fd5c5cd59c26d2b47fcbfc1f|f=4/810 m1010a=ff030000
  #|shrd r13, r9, 1|4d0faccd01|SHRD64rri8:%R13,%R13,%R9,1|r9=d319305680000000 r13=661d148b7eb5c1a8 f=402|r13=330e8a45bf5ae0d4 f=404/10
  #|shrd r13, r9, 1|4d0faccd01|SHRD64rri8:%R13,%R13,%R9,1|r9=0 r13=2e7d86e06a882bbd f=93|r13=173ec370354415de f=5/10
  #|shrd r13, r9, 0|4d0faccd00|SHRD64rri8:%R13,%R13,%R9,0|r9=e9132d88a9e55735 r13=fffffffffffffffe f=c6|f=c4/0
  #|shrd r13, r9, 0|4d0faccd00|SHRD64rri8:%R13,%R13,%R9,0|r9=c37d540e80000000 r13=a202d3b5aa10e47f f=816|f=814/0
  #|shrd r13, r9, 7|4d0faccd07|SHRD64rri8:%R13,%R13,%R9,7|r9=176e97bd7fffffff r13=f0fcd083fc945b5e f=816|r13=ffe1f9a107f928b6 f=881/810
  #|shrd r13, r9, 7|4d0faccd07|SHRD64rri8:%R13,%R13,%R9,7|r9=6705828b3d74baf2 r13=dc750a1d3c3d0f1a f=c2|r13=e5b8ea143a787a1e f=884/810
  #|shrd r13, r9, 63|4d0faccd3f|SHRD64rri8:%R13,%R13,%R9,63|r9=a7ff78d6e7bb6d99 r13=91d2e6ad27b49ca8 f=893|r13=4ffef1adcf76db33 f=4/810
  #|shrd r13, r9, 63|4d0faccd3f|SHRD64rri8:%R13,%R13,%R9,63|r9=2816e2917fffffff r13=7cceff6df564f05e f=d6|r13=502dc522fffffffe f=1/810
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=40 r9=f9813808fb20ffff r13=7fffffffffffffff f=887|f=885/0
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=ff r9=390136f81b9cb71f r13=c2316948a2207f7f f=c07|r13=72026df037396e3f f=405/810
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=1 r9=d6b78d120b6a5af3 r13=e3da6f2e95b17a87 f=886|r13=f1ed37974ad8bd43 f=81/10
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=40 r9=caf463d17668ad2d r13=aab75f57f16c57ae f=82|f=80/0
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=0 r9=82528a392c9b4c8a r13=777a57891c1a3746 f=453|f=451/0
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=21 r9=ffffffff r13=b1ad56d67038567f f=13|r13=7fffffffd8d6ab6b f=0/810
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=40 r9=52bb r13=2ff78d7fad5f993b f=c56|f=c54/0
  #|shrd r13, r9, cl|4d0fadcd|SHRD64rrCL:%R13,%R13,%R9|rcx=20 r9=4932eccce21d8fbb r13=c955bad88b63926c f=13|r13=e21d8fbbc955bad8 f=885/810
  #|shrd qword ptr [rsi], r9, 14|4c0fac0e0e|SHRD64mri8:%RSI,1,%,0,%,%R9,14|rbx=e r9=6 f=817 m10080=b9b9e31aef79ccb2a813493d6e87339c|f=5/810 m10080=8e6bbce731cb1a00
  #|shrd qword ptr [rsi], r9, 14|4c0fac0e0e|SHRD64mri8:%RSI,1,%,0,%,%R9,14|rbx=5 r9=f f=c3 m10080=6c85bc6ac7bb3b3aa29da095da148231|f=0/810 m10080=f2aa1defeee83c00

///|
let shift32_cases : String =
  #|shl bl, 1|d0e3|SHL8r1:%BL,%BL|ebx=e356b009 f=817|ebx=e356b012 f=4/10
  #|shl bl, 1|d0e3|SHL8r1:%BL,%BL|ebx=c835 f=4c6|ebx=c86a f=404/10
  #|shl bl, cl|d2e3|SHL8rCL:%BL,%BL|ecx=6 ebx=6089d7a4 f=d6|ebx=6089d700 f=845/810
  #|shl bl, cl|d2e3|SHL8rCL:%BL,%BL|ecx=9 ebx=ff8b511e f=847|ebx=ff8b5100 f=44/811
  #|shl bl, cl|d2e3|SHL8rCL:%BL,%BL|ecx=3 ebx=24c222d4 f=92|ebx=24c222a0 f=884/810
  #|shl bl, cl|d2e3|SHL8rCL:%BL,%BL|ecx=1 ebx=c f=13|ebx=18 f=4/10
  #|shl bl, cl|d2e3|SHL8rCL:%BL,%BL|ecx=81 ebx=3 f=d6|ebx=6 f=4/10
  #|shl bl, 8|c0e308|SHL8ri:%BL,%BL,8|ebx=31f9c4eb f=c7|ebx=31f9c400 f=845/811
  #|shl bl, 8|c0e308|SHL8ri:%BL,%BL,8|ebx=5b8f8b2e f=d3|ebx=5b8f8b00 f=44/811
  #|shl byte ptr [esi + ebx*4 + 0x8], cl|d2649e08|SHL8mCL:%ESI,4,%EBX,8,%|ecx=7 ebx=f f=6 m100c4=51f08fb90ee5df4b33e05507a86307ff|f=880/810 m100c4=80
  #|shl byte ptr [esi + ebx*4 + 0x8], cl|d2649e08|SHL8mCL:%ESI,4,%EBX,8,%|ecx=7 ebx=2 f=57 m10090=47142d073d5933b3c9d527a02b77c2ae|f=81/810 m10090=80
  #|shl byte ptr [esi + ebx*4 + 0x8], cl|d2649e08|SHL8mCL:%ESI,4,%EBX,8,%|ecx=f ebx=e f=8d6 m100c0=b1dd2fbb988da3994d02334aa45738e6|f=44/811 m100c0=00
  #|shl byte ptr [esi + ebx*4 + 0x8], cl|d2649e08|SHL8mCL:%ESI,4,%EBX,8,%|ecx=6 ebx=f f=cd2 m100c4=fa177de94ec69cf1ce56f60aa677843c|f=c80/810 m100c4=80
  #|shl byte ptr [esi + ebx*4 + 0x8], 5|c0649e0805|SHL8mi:%ESI,4,%EBX,8,%,5|ebx=e f=8c2 m100c0=25b96919628a4bc25c71b7fa1b4609a7|f=884/810 m100c0=a0
  #|shl byte ptr [esi + ebx*4 + 0x8], 5|c0649e0805|SHL8mi:%ESI,4,%EBX,8,%,5|ebx=f f=13 m100c4=e712e4b151d30090e6f4e2126ae64e3d|f=880/810 m100c4=e0
  #|shl dx, 1|66d1e2|SHL16r1:%DX,%DX|edx=2bbb8a8 f=843|edx=2bb7150 f=805/10
  #|shl dx, 1|66d1e2|SHL16r1:%DX,%DX|edx=1be90624 f=813|edx=1be90c48 f=4/10
  #|shl dx, cl|66d3e2|SHL16rCL:%DX,%DX|ecx=81 edx=80000000 f=857|f=44/10
  #|shl dx, cl|66d3e2|SHL16rCL:%DX,%DX|ecx=3 edx=2 f=13|edx=10 f=0/810
  #|shl dx, cl|66d3e2|SHL16rCL:%DX,%DX|ecx=81 edx=b825476e f=c16|edx=b8258edc f=c80/10
  #|shl dx, cl|66d3e2|SHL16rCL:%DX,%DX|ecx=f edx=e0841872 f=57|edx=e0840000 f=845/810
  #|shl dx, cl|66d3e2|SHL16rCL:%DX,%DX|ecx=0 edx=f15e5d8b f=816|f=814/0
  #|shl dx, 16|66c1e210|SHL16ri:%DX,%DX,16|edx=b4affff f=807|edx=b4a0000 f=845/811
  #|shl dx, 16|66c1e210|SHL16ri:%DX,%DX,16|edx=6da4 f=817|edx=0 f=44/811
  #|shl word ptr [esp + 0x8], cl|66d3642408|SHL16mCL:%ESP,1,%,8,%|ecx=26 ebx=d f=c7 m20108=73ce9bc8c8dc457cb8a4b434932ac789|f=85/810 m20108=c09c
  #|shl word ptr [esp + 0x8], cl|66d3642408|SHL16mCL:%ESP,1,%,8,%|ecx=24 ebx=0 f=892 m20108=96d87e2a996f493b1b340be5893395eb|f=85/810 m20108=6089
  #|shl word ptr [esp + 0x8], cl|66d3642408|SHL16mCL:%ESP,1,%,8,%|ecx=21 ebx=9 f=812 m20108=400191b62f29dcffddf799832ad0a9b0|f=0/10 m20108=8002
  #|shl word ptr [esp + 0x8], cl|66d3642408|SHL16mCL:%ESP,1,%,8,%|ecx=19 ebx=3 f=c43 m20108=b5f460be74dd7bc902a909996dfeb3e0|f=444/811 m20108=0000
  #|shl word ptr [esp + 0x8], 11|66c16424080b|SHL16mi:%ESP,1,%,8,%,11|ebx=2 f=8c3 m20108=3421f485722eee5a2acd7208d7c01278|f=85/810 m20108=00a0
  #|shl word ptr [esp + 0x8], 11|66c16424080b|SHL16mi:%ESP,1,%,8,%,11|ebx=a f=893 m20108=9e433c7db1d81d3a5dbb7147e8bf06e4|f=884/810 m20108=00f0
  #|shl eax, 1|d1e0|SHL32r1:%EAX,%EAX|eax=929ddec5 f=842|eax=253bbd8a f=801/10
  #|shl eax, 16|c1e010|SHL32ri:%EAX,%EAX,16|eax=ffffffff f=83|eax=ffff0000 f=85/810
  #|shl eax, 31|c1e01f|SHL32ri:%EAX,%EAX,31|eax=80000000 f=882|eax=0 f=44/810
  #|shl eax, 32|c1e020|SHL32ri:%EAX,%EAX,32|eax=2381b1f9 f=893|f=891/0
  #|shl eax, 33|c1e021|SHL32ri:%EAX,%EAX,33|eax=e18856e9 f=4c7|eax=c310add2 f=485/10
  #|shl eax, 63|c1e03f|SHL32ri:%EAX,%EAX,63|eax=100 f=d3|eax=0 f=44/810
  #|shl dword ptr [ebp - 0x20], 1|d165e0|SHL32m1:%EBP,1,%,-32,%|ebx=0 f=52 m20160=d93d3945aa6293bd43acd39ba410f9b3|f=884/10 m20160=b27b728a
  #|shl dword ptr [ebp - 0x20], 1|d165e0|SHL32m1:%EBP,1,%,-32,%|ebx=0 f=92 m20160=30ad080e214f1a619e3d04742384f66a|f=4/10 m20160=605a111c
  #|shl dword ptr [ebp - 0x20], cl|d365e0|SHL32mCL:%EBP,1,%,-32,%|ecx=15 ebx=0 f=8c7 m20160=74556a245d7cf82714d2b2fdf2ef65f8|f=884/810 m20160=000080ae
  #|shl dword ptr [ebp - 0x20], cl|d365e0|SHL32mCL:%EBP,1,%,-32,%|ecx=a ebx=f f=53 m20160=1abe46d5d5cc90b5f3fff2bdaef970ba|f=805/810 m20160=0068f81a
  #|shl dword ptr [ebp - 0x20], cl|d365e0|SHL32mCL:%EBP,1,%,-32,%|ecx=1b ebx=d f=87 m20160=3073eb5a32a10854c281e748d2da62e8|f=85/810 m20160=00000080
  #|shl dword ptr [ebp - 0x20], cl|d365e0|SHL32mCL:%EBP,1,%,-32,%|ecx=1 ebx=5 f=82 m20160=828984ae8d9fd2f3529d34a924d88dfe|f=801/10 m20160=0413095d
  #|shl dword ptr [ebp - 0x20], 13|c165e00d|SHL32mi:%EBP,1,%,-32,%,13|ebx=1 f=807 m20160=c0d82b1b21fd91fb5546cdd530ae70b1|f=805/810 m20160=0000187b
  #|shl dword ptr [ebp - 0x20], 13|c165e00d|SHL32mi:%EBP,1,%,-32,%,13|ebx=a f=8c6 m20160=18e05c9991d510213287eb4adfb30a1f|f=85/810 m20160=0000039c
  #|shr bl, 1|d0eb|SHR8r1:%BL,%BL|ebx=4d484013 f=8d3|ebx=4d484009 f=5/10
  #|shr bl, 1|d0eb|SHR8r1:%BL,%BL|ebx=22d9a3f6 f=803|ebx=22d9a37b f=804/10
  #|shr bl, cl|d2eb|SHR8rCL:%BL,%BL|ecx=7 ebx=3e2d65ba f=856|ebx=3e2d6501 f=0/810
  #|shr bl, cl|d2eb|SHR8rCL:%BL,%BL|ecx=9 ebx=1f6f9b61 f=897|ebx=1f6f9b00 f=44/811
  #|shr bl, cl|d2eb|SHR8rCL:%BL,%BL|ecx=8 ebx=306a3079 f=57|ebx=306a3000 f=44/811
  #|shr bl, cl|d2eb|SHR8rCL:%BL,%BL|ecx=9 ebx=4b0a4900 f=846|f=44/811
  #|shr bl, cl|d2eb|SHR8rCL:%BL,%BL|ecx=21 ebx=751acb0b f=803|ebx=751acb05 f=5/10
  #|shr bl, 7|c0eb07|SHR8ri:%BL,%BL,7|ebx=0 f=402|f=444/810
  #|shr bl, 7|c0eb07|SHR8ri:%BL,%BL,7|ebx=6a7a17a3 f=452|ebx=6a7a1701 f=400/810
  #|shr byte ptr [ebp - 0x20], 1|d06de0|SHR8m1:%EBP,1,%,-32,%|ebx=e f=97 m20160=feea54061d898f521867b46cfa5960e9|f=800/10 m20160=7f
  #|shr byte ptr [ebp - 0x20], 1|d06de0|SHR8m1:%EBP,1,%,-32,%|ebx=6 f=7 m20160=faad67d8ce855113fde9a5cb0e7765ee|f=804/10 m20160=7d
  #|shr byte ptr [ebp - 0x20], cl|d26de0|SHR8mCL:%EBP,1,%,-32,%|ecx=1e ebx=8 f=856 m20160=5b0c955ed4d7537a7362794babd023ed|f=44/811 m20160=00
  #|shr byte ptr [ebp - 0x20], cl|d26de0|SHR8mCL:%EBP,1,%,-32,%|ecx=6 ebx=5 f=886 m20160=ef65cadc3e3c5422ffb89ff45a82a96e|f=5/810 m20160=03
  #|shr byte ptr [ebp - 0x20], cl|d26de0|SHR8mCL:%EBP,1,%,-32,%|ecx=1a ebx=2 f=402 m20160=ed1a96e7437726efbd9a95e213a61b3c|f=444/811 m20160=00
  #|shr byte ptr [ebp - 0x20], cl|d26de0|SHR8mCL:%EBP,1,%,-32,%|ecx=25 ebx=4 f=813 m20160=d0e2df0f43438ba6468f2a3486021d9b|f=5/810 m20160=06
  #|shr byte ptr [ebp - 0x20], 7|c06de007|SHR8mi:%EBP,1,%,-32,%,7|ebx=6 f=896 m20160=bb54fd89e7159887a2c93059bae66b95|f=0/810 m20160=01
  #|shr byte ptr [ebp - 0x20], 7|c06de007|SHR8mi:%EBP,1,%,-32,%,7|ebx=e f=8c2 m20160=b54daec588df1b03a1ba795b86a9e8a8|f=0/810 m20160=01
  #|shr ax, 1|66d1e8|SHR16r1:%AX,%AX|eax=5814e092 f=c06|eax=58147049 f=c00/10
  #|shr ax, 1|66d1e8|SHR16r1:%AX,%AX|eax=ffffffff f=453|eax=ffff7fff f=c05/10
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|eax=a54accdd ecx=7 f=53|eax=a54a0199 f=5/810
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|eax=2 ecx=10 f=8d6|eax=0 f=44/811
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|eax=4e ecx=6 f=853|eax=1 f=0/810
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|eax=7f ecx=0 f=852|f=850/0
  #|shr ax, cl|66d3e8|SHR16rCL:%AX,%AX|eax=ceede342 ecx=7 f=96|eax=ceed01c6 f=5/810
  #|shr ax, 5|66c1e805|SHR16ri:%AX,%AX,5|eax=89723b43 f=52|eax=897201da f=0/810
  #|shr ax, 5|66c1e805|SHR16ri:%AX,%AX,5|eax=3f9e f=3|eax=1fc f=5/810
  #|shr ax, 15|66c1e80f|SHR16ri:%AX,%AX,15|eax=71e33150 f=c02|eax=71e30000 f=444/810
  #|shr ax, 15|66c1e80f|SHR16ri:%AX,%AX,15|eax=d1 f=847|eax=0 f=44/810
  #|shr word ptr [esp + 0x8], 1|66d16c2408|SHR16m1:%ESP,1,%,8,%|ebx=0 f=893 m20108=9ee1b3a68975ca71dc0c15a5fc36ef55|f=804/10 m20108=cf70
  #|shr word ptr [esp + 0x8], 1|66d16c2408|SHR16m1:%ESP,1,%,8,%|ebx=7 f=86 m20108=192b3dac686eabd8b0f092035e32f415|f=1/10 m20108=8c15
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|ecx=4 ebx=80000000 f=803|ebx=8000000 f=4/810
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|ecx=ff ebx=ffffffff f=96|ebx=1 f=1/810
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|ecx=0 ebx=3ec5bbcb f=816|f=814/0
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|ecx=ff ebx=f12cddd5 f=c13|ebx=1 f=401/810
  #|shr ebx, cl|d3eb|SHR32rCL:%EBX,%EBX|ecx=6 ebx=0 f=886|f=44/810
  #|shr ebx, 0|c1eb00|SHR32ri:%EBX,%EBX,0|ebx=fdb93b7e f=c2|f=c0/0
  #|shr ebx, 32|c1eb20|SHR32ri:%EBX,%EBX,32|ebx=7fffffff f=843|f=841/0
  #|shr ebx, 33|c1eb21|SHR32ri:%EBX,%EBX,33|ebx=8000 f=57|ebx=4000 f=4/10
  #|shr dword ptr [esi + ebx*4 + 0x8], 1|d16c9e08|SHR32m1:%ESI,4,%EBX,8,%|ebx=d f=4c6 m100bc=9a57b220be5047facc97cad72ab7eb72|f=400/10 m100bc=cd2b5910
  #|shr dword ptr [esi + ebx*4 + 0x8], 1|d16c9e08|SHR32m1:%ESI,4,%EBX,8,%|ebx=2 f=c2 m10090=86038fb22f87ea23dd83703065de012e|f=804/10 m10090=c3814759
  #|shr dword ptr [esi + ebx*4 + 0x8], cl|d36c9e08|SHR32mCL:%ESI,4,%EBX,8,%|ecx=23 ebx=b f=cd3 m100b4=a727fda3c03ef731dc490d39ad755b77|f=401/810 m100b4=f4a47f14
  #|shr dword ptr [esi + ebx*4 + 0x8], cl|d36c9e08|SHR32mCL:%ESI,4,%EBX,8,%|ecx=8 ebx=2 f=d7 m10090=579adf3f2156c458e644f3f6f0d9a68c|f=4/810 m10090=9adf3f00
  #|shr dword ptr [esi + ebx*4 + 0x8], cl|d36c9e08|SHR32mCL:%ESI,4,%EBX,8,%|ecx=22 ebx=d f=c3 m100bc=74819246f958e933d771232a5d818dce|f=0/810 m100bc=5da0a411
  #|shr dword ptr [esi + ebx*4 + 0x8], cl|d36c9e08|SHR32mCL:%ESI,4,%EBX,8,%|ecx=10 ebx=7 f=12 m100a4=7fea2f956b1e851a40e9a7cbbbcda14f|f=1/810 m100a4=2f950000
  #|shr dword ptr [esi + ebx*4 + 0x8], 2|c16c9e0802|SHR32mi:%ESI,4,%EBX,8,%,2|ebx=c f=402 m100b8=c31f172ed7ec3f3b54fae1fdf22bef5e|f=405/810 m100b8=f0c7850b
  #|shr dword ptr [esi + ebx*4 + 0x8], 2|c16c9e0802|SHR32mi:%ESI,4,%EBX,8,%,2|ebx=2 f=82 m10090=f72bb6567eced9416179a27304bc7a4e|f=1/810 m10090=fd8aad15
  #|sar al, 4|c0f804|SAR8ri:%AL,%AL,4|eax=cbf63565 f=897|eax=cbf63506 f=4/810
  #|sar al, 4|c0f804|SAR8ri:%AL,%AL,4|eax=fffffffe f=cd2|eax=ffffffff f=485/810
  #|sar al, 8|c0f808|SAR8ri:%AL,%AL,8|eax=b4817501 f=402|eax=b4817500 f=444/810
  #|sar al, 8|c0f808|SAR8ri:%AL,%AL,8|eax=39e56f95 f=13|eax=39e56fff f=85/810
  #|sar al, 64|c0f840|SAR8ri:%AL,%AL,64|eax=fffffffe f=8c2|f=8c0/0
  #|sar al, 64|c0f840|SAR8ri:%AL,%AL,64|eax=300ca305 f=c43|f=c41/0
  #|sar byte ptr [esp + 0x8], 1|d07c2408|SAR8m1:%ESP,1,%,8,%|ebx=f f=92 m20108=3a6036dd5732a1c021f6559240f0dc57|f=4/10 m20108=1d
  #|sar byte ptr [esp + 0x8], 1|d07c2408|SAR8m1:%ESP,1,%,8,%|ebx=3 f=86 m20108=0f833c61065466fb7725f687882a7bab|f=1/10 m20108=07
  #|sar byte ptr [esp + 0x8], cl|d27c2408|SAR8mCL:%ESP,1,%,8,%|ecx=17 ebx=c f=882 m20108=aadb81759ea08e14980ef67243164239|f=85/810 m20108=ff
  #|sar byte ptr [esp + 0x8], cl|d27c2408|SAR8mCL:%ESP,1,%,8,%|ecx=4 ebx=b f=806 m20108=3dbb9eade04090583b5d2595db2dd5ed|f=5/810 m20108=03
  #|sar byte ptr [esp + 0x8], cl|d27c2408|SAR8mCL:%ESP,1,%,8,%|ecx=19 ebx=d f=853 m20108=ecb925292d537f06b6dbc1ac295dcf42|f=85/810 m20108=ff
  #|sar byte ptr [esp + 0x8], cl|d27c2408|SAR8mCL:%ESP,1,%,8,%|ecx=25 ebx=2 f=12 m20108=969e6eef204eeea80efba6ed066c706c|f=85/810 m20108=fc
  #|sar ax, 1|66d1f8|SAR16r1:%AX,%AX|eax=ac9a15cf f=856|eax=ac9a0ae7 f=5/10
  #|sar ax, 1|66d1f8|SAR16r1:%AX,%AX|eax=7c7a2c80 f=852|eax=7c7a1640 f=0/10
  #|sar ax, 0|66c1f800|SAR16ri:%AX,%AX,0|eax=266e727f f=c86|f=c84/0
  #|sar ax, 0|66c1f800|SAR16ri:%AX,%AX,0|eax=7fffffff f=893|f=891/0
  #|sar ax, 8|66c1f808|SAR16ri:%AX,%AX,8|eax=8a295140 f=53|eax=8a290051 f=0/810
  #|sar ax, 8|66c1f808|SAR16ri:%AX,%AX,8|eax=86633219 f=12|eax=86630032 f=0/810
  #|sar ax, 15|66c1f80f|SAR16ri:%AX,%AX,15|eax=259ab4ab f=cd2|eax=259affff f=484/810
  #|sar ax, 15|66c1f80f|SAR16ri:%AX,%AX,15|eax=6895bc17 f=887|eax=6895ffff f=84/810
  #|sar ax, 16|66c1f810|SAR16ri:%AX,%AX,16|eax=ffff f=83|f=85/810
  #|sar ax, 16|66c1f810|SAR16ri:%AX,%AX,16|eax=12cf2953 f=57|eax=12cf0000 f=44/810
  #|sar ax, 31|66c1f81f|SAR16ri:%AX,%AX,31|eax=90e61d7c f=882|eax=90e60000 f=44/810
  #|sar ax, 31|66c1f81f|SAR16ri:%AX,%AX,31|eax=4ab9541 f=52|eax=4abffff f=85/810
  #|sar word ptr [esi + ebx*4 + 0x8], 6|66c17c9e0806|SAR16mi:%ESI,4,%EBX,8,%,6|ebx=0 f=3 m10088=14776ad8108ed1575f01f8e20e54f132|f=0/810 m10088=dc01
  #|sar word ptr [esi + ebx*4 + 0x8], 6|66c17c9e0806|SAR16mi:%ESI,4,%EBX,8,%,6|ebx=3 f=12 m10094=2dd565b09a2045dabf9f879f6e18a881|f=81/810 m10094=54ff
  #|sar eax, 31|c1f81f|SAR32ri:%EAX,%EAX,31|eax=8105928e f=8d3|eax=ffffffff f=84/810
  #|sar dword ptr [ebp - 0x20], 1|d17de0|SAR32m1:%EBP,1,%,-32,%|ebx=4 f=16 m20160=8c49cd020e9de46a1459a640cd3ac789|f=4/10 m20160=c6a46601
  #|sar dword ptr [ebp - 0x20], 1|d17de0|SAR32m1:%EBP,1,%,-32,%|ebx=f f=56 m20160=6553cb643ca6d31833fca8b90ce8ec79|f=5/10 m20160=b2a96532
  #|sar dword ptr [ebp - 0x20], 25|c17de019|SAR32mi:%EBP,1,%,-32,%,25|ebx=0 f=16 m20160=dbe3624768df2f137bb745ae2484a5a5|f=1/810 m20160=23000000
  #|sar dword ptr [ebp - 0x20], 25|c17de019|SAR32mi:%EBP,1,%,-32,%,25|ebx=b f=d2 m20160=d434198b3ccbc4adb12c861bd8ff6065|f=85/810 m20160=c5ffffff
  #|rol dl, 1|d0c2|ROL8r1:%DL,%DL|edx=0 f=402|f=400/0
  #|rol dl, 1|d0c2|ROL8r1:%DL,%DL|edx=5c27e4ae f=893|edx=5c27e45d f=891/0
  #|rol dl, cl|d2c2|ROL8rCL:%DL,%DL|ecx=81 edx=3318 f=52|edx=3330 f=50/0
  #|rol dl, cl|d2c2|ROL8rCL:%DL,%DL|ecx=1f edx=76cbc191 f=93|edx=76cbc1c8 f=890/800
  #|rol dl, cl|d2c2|ROL8rCL:%DL,%DL|ecx=1 edx=ffffffff f=847|f=45/0
  #|rol dl, cl|d2c2|ROL8rCL:%DL,%DL|ecx=0 edx=af5414f6 f=c6|f=c4/0
  #|rol dl, cl|d2c2|ROL8rCL:%DL,%DL|ecx=4 edx=fffffffe f=447|edx=ffffffef f=445/800
  #|rol dl, 4|c0c204|ROL8ri:%DL,%DL,4|edx=6b96691e f=806|edx=6b9669e1 f=5/800
  #|rol dl, 4|c0c204|ROL8ri:%DL,%DL,4|edx=a8 f=487|edx=8a f=c84/800
  #|rol dl, 7|c0c207|ROL8ri:%DL,%DL,7|edx=1a9c8ebc f=846|edx=1a9c8e5e f=44/800
  #|rol dl, 7|c0c207|ROL8ri:%DL,%DL,7|edx=a5445f85 f=d7|edx=a5445fc2 f=8d4/800
  #|rol byte ptr [esi + ebx*4 + 0x8], 1|d0449e08|ROL8m1:%ESI,4,%EBX,8,%|ebx=4 f=807 m10098=8d3cff3441155d385ca66ec9a3bf0c83|f=805/0 m10098=1b
  #|rol byte ptr [esi + ebx*4 + 0x8], 1|d0449e08|ROL8m1:%ESI,4,%EBX,8,%|ebx=6 f=cc7 m100a0=71c39cac4cb9a89e678af44b4f8481d3|f=cc4/0 m100a0=e2
  #|rol byte ptr [esi + ebx*4 + 0x8], cl|d2449e08|ROL8mCL:%ESI,4,%EBX,8,%|ecx=3 ebx=a f=817 m100b0=6c37bde855fb0e269f331a64b4742563|f=815/800 m100b0=63
  #|rol byte ptr [esi + ebx*4 + 0x8], cl|d2449e08|ROL8mCL:%ESI,4,%EBX,8,%|ecx=21 ebx=6 f=7 m100a0=26d6bf731c028e24b2396b13bf4ed85e|f=4/0 m100a0=4c
  #|rol byte ptr [esi + ebx*4 + 0x8], cl|d2449e08|ROL8mCL:%ESI,4,%EBX,8,%|ecx=12 ebx=3 f=57 m10094=bfe8c84e362ec89d4cc9138dea572bf8|f=854/800 m10094=fe
  #|rol byte ptr [esi + ebx*4 + 0x8], cl|d2449e08|ROL8mCL:%ESI,4,%EBX,8,%|ecx=18 ebx=b f=883 m100b4=f9192064270bdc6ecb0185e9043bee85|f=81/800
  #|rol ax, 1|66d1c0|ROL16r1:%AX,%AX|eax=fffffffe f=16|eax=fffffffd f=15/0
  #|rol ax, 1|66d1c0|ROL16r1:%AX,%AX|eax=1f5d1292 f=8c6|eax=1f5d2524 f=c4/0
  #|rol ax, 0|66c1c000|ROL16ri:%AX,%AX,0|eax=2a95b9a f=86|f=84/0
  #|rol ax, 0|66c1c000|ROL16ri:%AX,%AX,0|eax=8000 f=806|f=804/0
  #|rol ax, 15|66c1c00f|ROL16ri:%AX,%AX,15|eax=673865d7 f=803|eax=6738b2eb f=1/800
  #|rol ax, 15|66c1c00f|ROL16ri:%AX,%AX,15|eax=d3ac717f f=6|eax=d3acb8bf f=5/800
  #|rol ax, 16|66c1c010|ROL16ri:%AX,%AX,16|eax=7fff f=52|f=851/800
  #|rol ax, 16|66c1c010|ROL16ri:%AX,%AX,16|eax=2227b63d f=86|f=85/800
  #|rol ax, 17|66c1c011|ROL16ri:%AX,%AX,17|eax=80000000 f=897|f=94/800
  #|rol ax, 17|66c1c011|ROL16ri:%AX,%AX,17|eax=2dcc67e6 f=c56|eax=2dcccfcc f=c54/800
  #|rol ax, 65|66c1c041|ROL16ri:%AX,%AX,65|eax=897a53a3 f=87|eax=897aa746 f=884/0
  #|rol ax, 65|66c1c041|ROL16ri:%AX,%AX,65|eax=4d48622f f=452|eax=4d48c45e f=c50/0
  #|rol word ptr [esp + 0x8], cl|66d3442408|ROL16mCL:%ESP,1,%,8,%|ecx=1f ebx=1 f=2 m20108=9c5c7ad937c92642de10c7e013175df1|f=0/800 m20108=4e2e
  #|rol word ptr [esp + 0x8], cl|66d3442408|ROL16mCL:%ESP,1,%,8,%|ecx=17 ebx=f f=4c7 m20108=b79ddc4b7dd837bbc7abed245f2b7c40|f=cc4/800 m20108=cedb
  #|rol word ptr [esp + 0x8], cl|66d3442408|ROL16mCL:%ESP,1,%,8,%|ecx=7 ebx=5 f=887 m20108=bb343efed947b9baf525b7e59a02fce1|f=84/800 m20108=9a5d
  #|rol word ptr [esp + 0x8], cl|66d3442408|ROL16mCL:%ESP,1,%,8,%|ecx=9 ebx=4 f=8c3 m20108=80edb06280cae5eabc4349a5b9abed53|f=8c1/800 m20108=db01
  #|rol edx, 1|d1c2|ROL32r1:%EDX,%EDX|edx=44c3 f=c93|edx=8986 f=490/0
  #|rol edx, 0|c1c200|ROL32ri:%EDX,%EDX,0|edx=1c3a6487 f=452|f=450/0
  #|rol edx, 31|c1c21f|ROL32ri:%EDX,%EDX,31|edx=e f=897|edx=7 f=895/800
  #|rol edx, 33|c1c221|ROL32ri:%EDX,%EDX,33|edx=1a2a3a25 f=483|edx=3454744a f=480/0
  #|ror al, 1|d0c8|ROR8r1:%AL,%AL|eax=5c10 f=16|eax=5c08 f=14/0
  #|ror al, 1|d0c8|ROR8r1:%AL,%AL|eax=7a565a4c f=8c3|eax=7a565a26 f=c0/0
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|eax=8f5cac72 ecx=9 f=d3|eax=8f5cac39 f=d0/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|eax=ca8c799a ecx=4 f=c82|eax=ca8c79a9 f=c81/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|eax=ce257bcf ecx=9 f=16|eax=ce257be7 f=15/800
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|eax=370dc979 ecx=20 f=852|f=850/0
  #|ror al, cl|d2c8|ROR8rCL:%AL,%AL|eax=51c12d00 ecx=8 f=c57|f=454/800
  #|ror al, 9|c0c809|ROR8ri:%AL,%AL,9|eax=39ee6500 f=492|f=490/800
  #|ror al, 9|c0c809|ROR8ri:%AL,%AL,9|eax=56bcd8dc f=8d2|eax=56bcd86e f=8d0/800
  #|ror byte ptr [edi + 0x10], cl|d24f10|ROR8mCL:%EDI,1,%,16,%|ecx=c ebx=1 f=87 m10110=d5ea6bd1e3fefde136dfec7a55b56906|f=884/800 m10110=5d
  #|ror byte ptr [edi + 0x10], cl|d24f10|ROR8mCL:%EDI,1,%,16,%|ecx=25 ebx=c f=8c7 m10110=bcd82ec122229d403df6033d1e927900|f=c5/800 m10110=e5
  #|ror byte ptr [edi + 0x10], cl|d24f10|ROR8mCL:%EDI,1,%,16,%|ecx=d ebx=5 f=43 m10110=c5d04c65db4e7def3a5c537cba11c0ba|f=40/800 m10110=2e
  #|ror byte ptr [edi + 0x10], cl|d24f10|ROR8mCL:%EDI,1,%,16,%|ecx=1 ebx=e f=897 m10110=dce64717e80c811aedb842d066fd2ba9|f=894/0 m10110=6e
  #|ror bx, 0|66c1cb00|ROR16ri:%BX,%BX,0|ebx=e45d1e9f f=d2|f=d0/0
  #|ror bx, 0|66c1cb00|ROR16ri:%BX,%BX,0|ebx=93833260 f=17|f=15/0
  #|ror bx, 4|66c1cb04|ROR16ri:%BX,%BX,4|ebx=5cd03943 f=8d6|ebx=5cd03394 f=d4/800
  #|ror bx, 4|66c1cb04|ROR16ri:%BX,%BX,4|ebx=6a4b f=c03|ebx=b6a4 f=c01/800
  #|ror bx, 17|66c1cb11|ROR16ri:%BX,%BX,17|ebx=cb8ef122 f=c2|ebx=cb8e7891 f=8c0/800
  #|ror bx, 17|66c1cb11|ROR16ri:%BX,%BX,17|ebx=8cd0467 f=856|ebx=8cd8233 f=855/800
  #|ror word ptr [edi + 0x10], 1|66d14f10|ROR16m1:%EDI,1,%,16,%|ebx=7 f=8c3 m10110=6f2571c55ea8ead6184a24c7331c1f94|f=8c1/0 m10110=b792
  #|ror word ptr [edi + 0x10], 1|66d14f10|ROR16m1:%EDI,1,%,16,%|ebx=1 f=8d2 m10110=9010e7e1b2c5117982b6e42b5b38e44a|f=d0/0 m10110=4808
  #|ror word ptr [edi + 0x10], cl|66d34f10|ROR16mCL:%EDI,1,%,16,%|ecx=13 ebx=4 f=857 m10110=ee23d48c22561359f56fd789970d058f|f=55/800 m10110=7dc4
  #|ror word ptr [edi + 0x10], cl|66d34f10|ROR16mCL:%EDI,1,%,16,%|ecx=1b ebx=e f=12 m10110=f24b955dff203aae669f1d0fe66eb2cc|f=810/800 m10110=497e
  #|ror word ptr [edi + 0x10], cl|66d34f10|ROR16mCL:%EDI,1,%,16,%|ecx=16 ebx=3 f=46 m10110=20a9fb064dd07cdb25f604b2c8ce4276|f=845/800 m10110=a482
  #|ror word ptr [edi + 0x10], cl|66d34f10|ROR16mCL:%EDI,1,%,16,%|ecx=12 ebx=2 f=d2 m10110=db239622b95fdcaf649777e2c4c9c524|f=d1/800 m10110=f6c8
  #|ror word ptr [edi + 0x10], 4|66c14f1004|ROR16mi:%EDI,1,%,16,%,4|ebx=a f=803 m10110=63bf5179b53b8b2c761c4a8dadeb141b|f=0/800 m10110=f63b
  #|ror word ptr [edi + 0x10], 4|66c14f1004|ROR16mi:%EDI,1,%,16,%,4|ebx=a f=cd2 m10110=ee04fe6af187dd34051e614f86fc582d|f=4d1/800 m10110=4ee0
  #|ror ebx, 16|c1cb10|ROR32ri:%EBX,%EBX,16|ebx=640c7ec5 f=c13|ebx=7ec5640c f=c10/800
  #|ror dword ptr [esi + ebx*4 + 0x8], 1|d14c9e08|ROR32m1:%ESI,4,%EBX,8,%|ebx=4 f=57 m10098=2296fde874e0fea6d56db0132cfec6ea|f=854/0 m10098=11cb7e74
  #|ror dword ptr [esi + ebx*4 + 0x8], 1|d14c9e08|ROR32m1:%ESI,4,%EBX,8,%|ebx=2 f=8d2 m10090=29a7c503e0b2cffb9088db53d0a857ed|f=8d1/0 m10090=94d3e281
  #|ror dword ptr [esi + ebx*4 + 0x8], cl|d34c9e08|ROR32mCL:%ESI,4,%EBX,8,%|ecx=24 ebx=f f=482 m100c4=d34c8ef8400d6bc2a9dae220c94431b3|f=480/800 m100c4=cde4883f
  #|ror dword ptr [esi + ebx*4 + 0x8], cl|d34c9e08|ROR32mCL:%ESI,4,%EBX,8,%|ecx=6 ebx=1 f=852 m1008c=3a24a15e3a2256622204676c977bb083|f=51/800 m1008c=90847ae9
  #|ror dword ptr [esi + ebx*4 + 0x8], cl|d34c9e08|ROR32mCL:%ESI,4,%EBX,8,%|ecx=23 ebx=c f=c3 m100b8=98da01c66bab14a9b7a19eb4e722ceb1|f=c0/800 m100b8=533bc018
  #|ror dword ptr [esi + ebx*4 + 0x8], cl|d34c9e08|ROR32mCL:%ESI,4,%EBX,8,%|ecx=5 ebx=0 f=c3 m10088=a0600950f7f3ecc3cfafa546d2882593|f=c0/800 m10088=054b8002
  #|ror dword ptr [esi + ebx*4 + 0x8], 24|c14c9e0818|ROR32mi:%ESI,4,%EBX,8,%,24|ebx=7 f=56 m100a4=47b00a05696089b22b61ed6becf2b4ee|f=54/800 m100a4=0547b00a
  #|ror dword ptr [esi + ebx*4 + 0x8], 24|c14c9e0818|ROR32mi:%ESI,4,%EBX,8,%,24|ebx=3 f=8d3 m10094=4abdffc16db6f193ba94863ece0551e7|f=d1/800 m10094=c14abdff
  #|rcl al, 1|d0d0|RCL8r1:%AL,%AL|eax=9daebcba f=c7|eax=9daebc75 f=8c5/0
  #|rcl al, 1|d0d0|RCL8r1:%AL,%AL|eax=aef35f2d f=887|eax=aef35f5b f=84/0
  #|rcl al, cl|d2d0|RCL8rCL:%AL,%AL|eax=34672148 ecx=3f f=852|eax=34672182 f=850/800
  #|rcl al, cl|d2d0|RCL8rCL:%AL,%AL|eax=9685c4c7 ecx=81 f=86|eax=9685c48e f=85/0
  #|rcl al, cl|d2d0|RCL8rCL:%AL,%AL|eax=372c2549 ecx=0 f=46|f=44/0
  #|rcl al, cl|d2d0|RCL8rCL:%AL,%AL|eax=56548f64 ecx=6 f=846|eax=56548f0c f=45/800
  #|rcl al, cl|d2d0|RCL8rCL:%AL,%AL|eax=3d65658c ecx=8 f=53|eax=3d6565c6 f=50/800
  #|rcl al, 0|c0d000|RCL8ri:%AL,%AL,0|eax=e f=82|f=80/0
  #|rcl al, 0|c0d000|RCL8ri:%AL,%AL,0|eax=96bdfe6a f=812|f=810/0
  #|rcl al, 2|c0d002|RCL8ri:%AL,%AL,2|eax=76 f=97|eax=da f=895/800
  #|rcl al, 2|c0d002|RCL8ri:%AL,%AL,2|eax=3835890 f=817|eax=3835843 f=814/800
  #|rcl al, 9|c0d009|RCL8ri:%AL,%AL,9|eax=7 f=57|f=55/800
  #|rcl al, 9|c0d009|RCL8ri:%AL,%AL,9|eax=ffa0dca1 f=8d7|f=8d5/800
  #|rcl al, 63|c0d03f|RCL8ri:%AL,%AL,63|eax=5b2ea105 f=846|eax=5b2ea150 f=44/800
  #|rcl al, 63|c0d03f|RCL8ri:%AL,%AL,63|eax=9c66 f=93|eax=9c6b f=90/800
  #|rcl byte ptr [esp + 0x8], cl|d2542408|RCL8mCL:%ESP,1,%,8,%|ecx=5 ebx=d f=43 m20108=fdb6b9a48e92beb3b5cebb1db6d3be81|f=41/800 m20108=bf
  #|rcl byte ptr [esp + 0x8], cl|d2542408|RCL8mCL:%ESP,1,%,8,%|ecx=b ebx=d f=853 m20108=efa02c5f82d4c6d8faa723861507dd1d|f=51/800 m20108=bf
  #|rcl byte ptr [esp + 0x8], cl|d2542408|RCL8mCL:%ESP,1,%,8,%|ecx=12 ebx=c f=816 m20108=d9adaf0b1638ec55c87c8bdd2c9c9e75|f=814/800
  #|rcl byte ptr [esp + 0x8], cl|d2542408|RCL8mCL:%ESP,1,%,8,%|ecx=18 ebx=b f=57 m20108=b8848bf8f8ebe0690cbfb15dd6f3aa7a|f=854/800 m20108=37
  #|rcl byte ptr [esp + 0x8], 5|c054240805|RCL8mi:%ESP,1,%,8,%,5|ebx=b f=8c6 m20108=1c703053cab8f16548f4eadccad4b037|f=8c5/800 m20108=81
  #|rcl byte ptr [esp + 0x8], 5|c054240805|RCL8mi:%ESP,1,%,8,%,5|ebx=0 f=c3 m20108=42d448e20c8c39defb35b417e15f78c7|f=c0/800 m20108=54
  #|rcl ax, 1|66d1d0|RCL16r1:%AX,%AX|eax=a98b9c79 f=c46|eax=a98b38f2 f=c45/0
  #|rcl ax, 1|66d1d0|RCL16r1:%AX,%AX|eax=1 f=cc6|eax=2 f=4c4/0
  #|rcl ax, 0|66c1d000|RCL16ri:%AX,%AX,0|eax=241d5cff f=842|f=840/0
  #|rcl ax, 0|66c1d000|RCL16ri:%AX,%AX,0|eax=86d3899a f=53|f=51/0
  #|rcl ax, 16|66c1d010|RCL16ri:%AX,%AX,16|eax=de324841 f=413|eax=de32a420 f=c11/800
  #|rcl ax, 16|66c1d010|RCL16ri:%AX,%AX,16|eax=f2bb62ea f=c83|eax=f2bbb175 f=c80/800
  #|rcl ax, 17|66c1d011|RCL16ri:%AX,%AX,17|eax=59182eea f=c57|f=c55/800
  #|rcl ax, 17|66c1d011|RCL16ri:%AX,%AX,17|eax=a458f186 f=c07|f=c05/800
  #|rcl ax, 33|66c1d021|RCL16ri:%AX,%AX,33|eax=ddf2e3c6 f=852|eax=ddf2c78c f=51/0
  #|rcl ax, 33|66c1d021|RCL16ri:%AX,%AX,33|eax=15d3d546 f=c86|eax=15d3aa8c f=485/0
  #|rcl word ptr [edi + 0x10], cl|66d35710|RCL16mCL:%EDI,1,%,16,%|ecx=19 ebx=6 f=887 m10110=93c8c83619e8fe85ce8a94a5e74e9064|f=84/800 m10110=e493
  #|rcl word ptr [edi + 0x10], cl|66d35710|RCL16mCL:%EDI,1,%,16,%|ecx=2 ebx=9 f=8c7 m10110=9e9f94e1de4290825dc5b294fb76b838|f=8c4/800 m10110=7b7e
  #|rcl word ptr [edi + 0x10], cl|66d35710|RCL16mCL:%EDI,1,%,16,%|ecx=1e ebx=7 f=c2 m10110=ea9ec20804faf41ef8b915ae5147536f|f=8c1/800 m10110=ee49
  #|rcl word ptr [edi + 0x10], cl|66d35710|RCL16mCL:%EDI,1,%,16,%|ecx=5 ebx=e f=817 m10110=a73b3bab4f6e269c8a278319623854c1|f=15/800 m10110=f374
  #|rcl word ptr [edi + 0x10], 4|66c1571004|RCL16mi:%EDI,1,%,16,%,4|ebx=3 f=846 m10110=65191d5bc406c2ab44dfe3d1079a3970|f=845/800 m10110=5096
  #|rcl word ptr [edi + 0x10], 4|66c1571004|RCL16mi:%EDI,1,%,16,%,4|ebx=8 f=887 m10110=916012f554b3a16cfdc0ec6a1a7ec441|f=84/800 m10110=1b09
  #|rcl eax, 30|c1d01e|RCL32ri:%EAX,%EAX,30|eax=727c7d4a f=83|eax=ae4f8fa9 f=880/800
  #|rcl eax, 32|c1d020|RCL32ri:%EAX,%EAX,32|eax=7f f=17|f=15/0
  #|rcl eax, 33|c1d021|RCL32ri:%EAX,%EAX,33|eax=94bb975c f=8c2|eax=29772eb8 f=8c1/0
  #|rcl dword ptr [esi + ebx*4 + 0x8], 29|c1549e081d|RCL32mi:%ESI,4,%EBX,8,%,29|ebx=5 f=892 m1009c=1b97603ed9aeaf87a78d3cccd669700c|f=91/800 m1009c=7109e663
  #|rcl dword ptr [esi + ebx*4 + 0x8], 29|c1549e081d|RCL32mi:%ESI,4,%EBX,8,%,29|ebx=1 f=846 m1008c=435994c158612f87c4af8920aa68d46a|f=844/800 m1008c=9445196c
  #|rcr bl, 0|c0db00|RCR8ri:%BL,%BL,0|ebx=b5e9 f=807|f=805/0
  #|rcr bl, 0|c0db00|RCR8ri:%BL,%BL,0|ebx=a3217eca f=8d3|f=8d1/0
  #|rcr bl, 8|c0db08|RCR8ri:%BL,%BL,8|ebx=a4aeffff f=893|f=91/800
  #|rcr bl, 8|c0db08|RCR8ri:%BL,%BL,8|ebx=b58c3392 f=56|ebx=b58c3324 f=855/800
  #|rcr bl, 33|c0db21|RCR8ri:%BL,%BL,33|ebx=a f=887|ebx=85 f=884/0
  #|rcr bl, 33|c0db21|RCR8ri:%BL,%BL,33|ebx=4d3fdd79 f=8d7|ebx=4d3fddbc f=8d5/0
  #|rcr byte ptr [esi + ebx*4 + 0x8], 1|d05c9e08|RCR8m1:%ESI,4,%EBX,8,%|ebx=c f=43 m100b8=2a0be4d2f79cd5765082be097ad37fc4|f=840/0 m100b8=95
  #|rcr byte ptr [esi + ebx*4 + 0x8], 1|d05c9e08|RCR8m1:%ESI,4,%EBX,8,%|ebx=a f=856 m100b0=87b5dc8d3ab0bd7fd498cce18f0a3ec6|f=855/0 m100b0=43
  #|rcr byte ptr [esi + ebx*4 + 0x8], 4|c05c9e0804|RCR8mi:%ESI,4,%EBX,8,%,4|ebx=2 f=8c3 m10090=2b3af1c30f31a5ab904dec9f90c6773c|f=c1/800 m10090=72
  #|rcr byte ptr [esi + ebx*4 + 0x8], 4|c05c9e0804|RCR8mi:%ESI,4,%EBX,8,%,4|ebx=5 f=96 m1009c=a59834336a034c48fe8560a22088b390|f=94/800 m1009c=aa
  #|rcr ax, 1|66d1d8|RCR16r1:%AX,%AX|eax=461de955 f=4c6|eax=461d74aa f=cc5/0
  #|rcr ax, 1|66d1d8|RCR16r1:%AX,%AX|eax=e5ba773e f=892|eax=e5ba3b9f f=90/0
  #|rcr ax, 0|66c1d800|RCR16ri:%AX,%AX,0|eax=bfbc1553 f=843|f=841/0
  #|rcr ax, 0|66c1d800|RCR16ri:%AX,%AX,0|eax=bec6aeb4 f=c52|f=c50/0
  #|rcr ax, 15|66c1d80f|RCR16ri:%AX,%AX,15|eax=5459837f f=cc3|eax=54590dff f=cc0/800
  #|rcr ax, 15|66c1d80f|RCR16ri:%AX,%AX,15|eax=b36bdfd3 f=16|eax=b36b7f4d f=815/800
  #|rcr ax, 16|66c1d810|RCR16ri:%AX,%AX,16|eax=449a9968 f=13|eax=449a32d1 f=811/800
  #|rcr ax, 16|66c1d810|RCR16ri:%AX,%AX,16|eax=c3010d96 f=893|eax=c3011b2d f=90/800
  #|rcr word ptr [ebp - 0x20], 1|66d15de0|RCR16m1:%EBP,1,%,-32,%|ebx=9 f=457 m20160=67ec35acef696295d210fa1454c2a700|f=455/0 m20160=33f6
  #|rcr word ptr [ebp - 0x20], 1|66d15de0|RCR16m1:%EBP,1,%,-32,%|ebx=f f=856 m20160=3b1447cc1fc88b29c864b1d2f953a9e4|f=55/0 m20160=1d0a
  #|rcr word ptr [ebp - 0x20], cl|66d35de0|RCR16mCL:%EBP,1,%,-32,%|ecx=4 ebx=0 f=53 m20160=3fb94b8c04c814f9d97aaf3417ebb18d|f=51/800 m20160=93fb
  #|rcr word ptr [ebp - 0x20], cl|66d35de0|RCR16mCL:%EBP,1,%,-32,%|ecx=19 ebx=2 f=c87 m20160=5609d4642451beea7c9087347815514e|f=c84/800 m20160=09ad
  #|rcr word ptr [ebp - 0x20], cl|66d35de0|RCR16mCL:%EBP,1,%,-32,%|ecx=0 ebx=5 f=42 m20160=b333fe3b37023b2987014b07fad91d7b|f=40/0
  #|rcr word ptr [ebp - 0x20], cl|66d35de0|RCR16mCL:%EBP,1,%,-32,%|ecx=19 ebx=d f=493 m20160=163d9684f5b1e52c6dd500f8300664bf|f=490/800 m20160=3d2d
  #|rcr ebx, 1|d1db|RCR32r1:%EBX,%EBX|ebx=38e5b8c1 f=8d7|ebx=9c72dc60 f=8d5/0
  #|rcr ebx, cl|d3db|RCR32rCL:%EBX,%EBX|ecx=1f ebx=33b7a355 f=813|ebx=cede8d56 f=810/800
  #|rcr ebx, cl|d3db|RCR32rCL:%EBX,%EBX|ecx=40 ebx=7a f=8c6|f=8c4/0
  #|rcr ebx, cl|d3db|RCR32rCL:%EBX,%EBX|ecx=1f ebx=ffffffff f=97|f=95/800
  #|rcr ebx, cl|d3db|RCR32rCL:%EBX,%EBX|ecx=0 ebx=1773bd00 f=8d2|f=8d0/0
  #|rcr ebx, cl|d3db|RCR32rCL:%EBX,%EBX|ecx=81 ebx=41 f=d2|ebx=20 f=d1/0
  #|rcr ebx, 31|c1db1f|RCR32ri:%EBX,%EBX,31|ebx=8000 f=447|ebx=20002 f=444/800
  #|rcr ebx, 32|c1db20|RCR32ri:%EBX,%EBX,32|ebx=3793 f=803|f=801/0
  #|rcr ebx, 33|c1db21|RCR32ri:%EBX,%EBX,33|ebx=304efb81 f=847|ebx=98277dc0 f=845/0
  #|rcr ebx, 65|c1db41|RCR32ri:%EBX,%EBX,65|ebx=430dfc37 f=897|ebx=a186fe1b f=895/0
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|edx=19 f=812|edx=c f=5/10
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|edx=c92e2765 f=893|edx=c92e2732 f=1/10
  #|sar dl, 1 (c0)|c0fa01|SAR8ri:%DL,%DL,1|edx=bdeea6f5 f=46|edx=bdeea6fa f=85/10
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|ecx=7a4efc7e f=896|ecx=3d277e3f f=94/0
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|ecx=ffffffff f=c6|ecx=7fffffff f=8c5/0
  #|rcr ecx, 1 (c1)|c1d901|RCR32ri:%ECX,%ECX,1|ecx=fffffffe f=3|ecx=ffffffff f=0/0
  #|sal eax, cl (d3 /6)|d3f0|?|eax=fae60100 ecx=1e f=853|eax=0 f=44/810
  #|sal eax, cl (d3 /6)|d3f0|?|eax=ef519d2f ecx=11 f=402|eax=3a5e0000 f=c05/810
  #|sal eax, cl (d3 /6)|d3f0|?|eax=d6ba889 ecx=27 f=42|eax=b5d44480 f=880/810
  #|shld ax, cx, 4|660fa4c804|SHLD16rri8:%AX,%AX,%CX,4|eax=bb99bb82 ecx=b5520694 f=d3|eax=bb99b820 f=81/810
  #|shld ax, cx, 4|660fa4c804|SHLD16rri8:%AX,%AX,%CX,4|eax=ffffffff ecx=7f f=6|eax=fffffff0 f=85/810
  #|shld ax, cx, 15|660fa4c80f|SHLD16rri8:%AX,%AX,%CX,15|eax=d76529ff ecx=18d81444 f=cc6|eax=d7658a22 f=485/810
  #|shld ax, cx, 15|660fa4c80f|SHLD16rri8:%AX,%AX,%CX,15|eax=3479678c ecx=a474230b f=882|eax=34791185 f=0/810
  #|shld ax, cx, 20|660fa4c814|SHLD16rri8:%AX,%AX,%CX,20|eax=e459e1e8 ecx=85b6f980 f=816|eax=? f=81/8d5
  #|shld ax, cx, 20|660fa4c814|SHLD16rri8:%AX,%AX,%CX,20|eax=4f50 ecx=1 f=806|eax=? f=4/8d5
  #|shld ebx, eax, 1|0fa4c301|SHLD32rri8:%EBX,%EBX,%EAX,1|eax=c368ba22 ebx=b f=8c6|ebx=17 f=4/10
  #|shld ebx, eax, 1|0fa4c301|SHLD32rri8:%EBX,%EBX,%EAX,1|eax=53816f9 ebx=a04c2613 f=c12|ebx=40984c26 f=c01/10
  #|shld ebx, eax, 0|0fa4c300|SHLD32rri8:%EBX,%EBX,%EAX,0|eax=aeac6df9 ebx=e9 f=3|f=1/0
  #|shld ebx, eax, 0|0fa4c300|SHLD32rri8:%EBX,%EBX,%EAX,0|eax=33029ff2 ebx=e2 f=87|f=85/0
  #|shld ebx, eax, 18|0fa4c312|SHLD32rri8:%EBX,%EBX,%EAX,18|eax=bf7df278 ebx=a4fba967 f=816|ebx=a59efdf7 f=880/810
  #|shld ebx, eax, 18|0fa4c312|SHLD32rri8:%EBX,%EBX,%EAX,18|eax=0 ebx=ea75fd13 f=893|ebx=f44c0000 f=85/810
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=80000000 ecx=3 ebx=4ff7 f=496|ebx=27fbc f=400/810
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=38bd428 ecx=20 ebx=e580778d f=3|f=1/0
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=14c05641 ecx=20 ebx=75bb7933 f=c6|f=c4/0
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=7 ecx=4 ebx=f950ffff f=17|ebx=950ffff0 f=85/810
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=9dc9afba ecx=1 ebx=cc f=813|ebx=199 f=4/10
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=a0113104 ecx=1f ebx=84d0e359 f=c82|ebx=d0089882 f=c84/810
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=ed39b87e ecx=2 ebx=47f68000 f=93|ebx=1fda0003 f=805/810
  #|shld ebx, eax, cl|0fa5c3|SHLD32rrCL:%EBX,%EBX,%EAX|eax=5b9f838c ecx=1f ebx=902adc84 f=87|ebx=2dcfc1c6 f=4/810
  #|shld dword ptr [esi], eax, 21|0fa40615|SHLD32mri8:%ESI,1,%,0,%,%EAX,21|eax=68b98d36 ebx=0 f=83 m10080=c2d5a0816eab8fe9e7095c76cc46c9b3|f=880/810 m10080=31174db8
  #|shld dword ptr [esi], eax, 21|0fa40615|SHLD32mri8:%ESI,1,%,0,%,%EAX,21|eax=0 ebx=f f=47 m10080=57dc09a6648cec0344302da757212dca|f=85/810 m10080=0000e08a
  #|shrd dx, bx, 1|660facda01|SHRD16rri8:%DX,%DX,%BX,1|edx=4c289fda ebx=100 f=86|edx=4c284fed f=804/10
  #|shrd dx, bx, 1|660facda01|SHRD16rri8:%DX,%DX,%BX,1|edx=7f ebx=30f3c094 f=8c6|edx=3f f=5/10
  #|shrd dx, bx, 10|660facda0a|SHRD16rri8:%DX,%DX,%BX,10|edx=1 ebx=8d106d46 f=806|edx=5180 f=800/810
  #|shrd dx, bx, 10|660facda0a|SHRD16rri8:%DX,%DX,%BX,10|edx=cb40c458 ebx=7f f=d7|edx=cb401ff1 f=0/810
  #|shrd dx, bx, 15|660facda0f|SHRD16rri8:%DX,%DX,%BX,15|edx=38c25b7 ebx=ac021e17 f=843|edx=38c3c2e f=4/810
  #|shrd dx, bx, 15|660facda0f|SHRD16rri8:%DX,%DX,%BX,15|edx=d4d3 ebx=2f13 f=6|edx=5e27 f=805/810
  #|shrd dx, bx, 17|660facda11|SHRD16rri8:%DX,%DX,%BX,17|edx=a524853e ebx=2560a141 f=816|edx=? f=805/8d5
  #|shrd dx, bx, 17|660facda11|SHRD16rri8:%DX,%DX,%BX,17|edx=9b419646 ebx=7fff f=807|edx=? f=5/8d5
  #|shrd dx, bx, 20|660facda14|SHRD16rri8:%DX,%DX,%BX,20|edx=f579687f ebx=2209d6f f=886|edx=? f=81/8d5
  #|shrd dx, bx, 20|660facda14|SHRD16rri8:%DX,%DX,%BX,20|edx=2aeccfcf ebx=67f6 f=6|edx=? f=80/8d5
  #|shrd word ptr [esi], bx, 9|660fac1e09|SHRD16mri8:%ESI,1,%,0,%,%BX,9|ebx=6 f=496 m10080=5e80d3616732a984e8786b7423518436|f=400/810 m10080=4003
  #|shrd word ptr [esi], bx, 9|660fac1e09|SHRD16mri8:%ESI,1,%,0,%,%BX,9|ebx=e f=887 m10080=5127f711c0c518dfefaa9a0d2ed833d2|f=1/810 m10080=1307
  #|shrd ecx, edx, 0|0facd100|SHRD32rri8:%ECX,%ECX,%EDX,0|ecx=359d138b edx=1b1861f4 f=8c6|f=8c4/0
  #|shrd ecx, edx, 0|0facd100|SHRD32rri8:%ECX,%ECX,%EDX,0|ecx=387b9b96 edx=888861f2 f=886|f=884/0
  #|shrd ecx, edx, 19|0facd113|SHRD32rri8:%ECX,%ECX,%EDX,19|ecx=7fff edx=5d108eb f=d7|ecx=211d6000 f=4/810
  #|shrd ecx, edx, 19|0facd113|SHRD32rri8:%ECX,%ECX,%EDX,19|ecx=66814994 edx=9f347f1e f=c42|ecx=8fe3ccd0 f=c80/810
