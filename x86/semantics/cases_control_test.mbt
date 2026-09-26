// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let control64_cases : String =
  #|push rax|50|PUSH64r:%RAX|rax=ad01b7a7ce9b5449 f=4c2|rsp=200f8 f=4c0/0 m200f8=49549bcea7b701ad
  #|pop rax|58|POP64r:%RAX|rax=72f5ca7b9b014497 f=442|rax=8429ce7318bd6207 rsp=20108 f=440/0
  #|push rcx|51|PUSH64r:%RCX|rcx=2b2c819e7f5eb76f f=56|rsp=200f8 f=54/0 m200f8=6fb75e7f9e812c2b
  #|pop rcx|59|POP64r:%RCX|rcx=33c365dfd7c6148d f=d2|rcx=8429ce7318bd6207 rsp=20108 f=d0/0
  #|push rdx|52|PUSH64r:%RDX|rdx=afa1a518cf29bf58 f=857|rsp=200f8 f=855/0 m200f8=58bf29cf18a5a1af
  #|pop rdx|5a|POP64r:%RDX|rdx=2227dc735a293480 f=486|rdx=8429ce7318bd6207 rsp=20108 f=484/0
  #|push rbx|53|PUSH64r:%RBX|rbx=e5617bd485460d9 f=93|rsp=200f8 f=91/0 m200f8=d9605448bd17560e
  #|pop rbx|5b|POP64r:%RBX|rbx=a316f2f984973ac f=7|rbx=8429ce7318bd6207 rsp=20108 f=5/0
  #|push r8|4150|PUSH64r:%R8|r8=f230097d4d014eb5 f=8d7|rsp=200f8 f=8d5/0 m200f8=b54e014d7d0930f2
  #|pop r8|4158|POP64r:%R8|r8=e6a0922d781c6ca5 f=56|rsp=20108 r8=8429ce7318bd6207 f=54/0
  #|push r9|4151|PUSH64r:%R9|r9=f9578ce2d982956e f=416|rsp=200f8 f=414/0 m200f8=6e9582d9e28c57f9
  #|pop r9|4159|POP64r:%R9|r9=7069f0afab996b79 f=13|rsp=20108 r9=8429ce7318bd6207 f=11/0
  #|push rsp|54|PUSH64r:%RSP|f=8d7|rsp=200f8 f=8d5/0 m200f8=0001020000000000
  #|pop rbp|5d|POP64r:%RBP|f=817|rsp=20108 rbp=8429ce7318bd6207 f=815/0
  #|push ax|6650|PUSH16r:%AX|rax=a602f37a968668ae f=82|rsp=200fe f=80/0 m200fe=ae68
  #|pop cx|6659|POP16r:%CX|rcx=67d80e90a035697 f=12|rcx=67d80e90a036207 rsp=20102 f=10/0
  #|push -0x2|6afe|PUSH64i8:-2|f=442|rsp=200f8 f=440/0 m200f8=feffffffffffffff
  #|push 0x12345678|6878563412|PUSH64i32:305419896|f=93|rsp=200f8 f=91/0 m200f8=7856341200000000
  #|push qword ptr [rsi]|ff36|PUSH64rmm:%RSI,1,%,0,%|f=453 m10080=2c9aecde22e41d8cb8a02efb984d072d|rsp=200f8 f=451/0 m200f8=2c9aecde22e41d8c
  #|push qword ptr [rsi]|ff36|PUSH64rmm:%RSI,1,%,0,%|f=d2 m10080=79795e3509fed314c8a88a8ac08f3ce1|rsp=200f8 f=d0/0 m200f8=79795e3509fed314
  #|pop qword ptr [rsi]|8f06|POP64rmm:%RSI,1,%,0,%|f=96 m10080=508a26699236b7f2b0312d595743d027|rsp=20108 f=94/0 m10080=0762bd1873ce2984
  #|pop qword ptr [rsi]|8f06|POP64rmm:%RSI,1,%,0,%|f=4c7 m10080=d7c04ae23c3e897e21ea29f00f4f806b|rsp=20108 f=4c5/0 m10080=0762bd1873ce2984
  #|pushf|9c|PUSHF64:|f=c2|rsp=200f8 f=c0/0 m=?
  #|pushf|9c|PUSHF64:|f=16|rsp=200f8 f=14/0 m=?
  #|popf|9d|POPF64:|f=86 m20100=9600000000000000|rsp=20108 f=94/0
  #|popf|9d|POPF64:|f=813 m20100=4604000000000000|rsp=20108 f=444/0
  #|popf|9d|POPF64:|f=47 m20100=c300000000000000|rsp=20108 f=c1/0
  #|leave|c9|LEAVE64:|f=852|rsp=20188 rbp=4a94ef3983de287 f=850/0
  #|leave|c9|LEAVE64:|f=c2|rsp=20188 rbp=4a94ef3983de287 f=c0/0
  #|enter 0x10, 0|c8100000|ENTER:16,0|f=c2|rsp=200e8 rbp=200f8 f=c0/0 m200f8=8001020000000000
  #|enter 0x8, 1|c8080001|ENTER:8,1|f=c52|rsp=200e8 rbp=200f8 f=c50/0 m200f0=f8000200000000008001020000000000
  #|call +0x100|e800010000|CALL64pcrel32:256|f=8c3|rsp=200f8 f=8c1/0 m200f8=0500400000000000 j=400105
  #|call +0x100|e800010000|CALL64pcrel32:256|f=813|rsp=200f8 f=811/0 m200f8=0500400000000000 j=400105
  #|call +0x100|e800010000|CALL64pcrel32:256|f=c2|rsp=200f8 f=c0/0 m200f8=0500400000000000 j=400105
  #|jmp +0x10|eb10|JMP_1:16|f=97|f=95/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=486|f=484/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=4c7|f=4c5/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=52|f=50/0 j=400012
  #|jmp -0x10|ebf0|JMP_1:-16|f=816|f=814/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=447|f=445/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=493|f=491/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=13|f=11/0 j=3ffff2
  #|jmp +0x1000|e900100000|JMP_4:4096|f=82|f=80/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=8d2|f=8d0/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=82|f=80/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=842|f=840/0 j=401005
  #|ret|c3|RET64:|f=842 m20100=3412400000000000|rsp=20108 f=840/0 j=401234
  #|ret|c3|RET64:|f=896 m20100=3412400000000000|rsp=20108 f=894/0 j=401234
  #|ret|c3|RET64:|f=47 m20100=3412400000000000|rsp=20108 f=45/0 j=401234
  #|ret 0x10|c21000|RETI64:16|f=47 m20100=3412400000000000|rsp=20118 f=45/0 j=401234
  #|ret 0x10|c21000|RETI64:16|f=852 m20100=3412400000000000|rsp=20118 f=850/0 j=401234
  #|ret 0x10|c21000|RETI64:16|f=52 m20100=3412400000000000|rsp=20118 f=50/0 j=401234
  #|jo +0x20|7020|JCC_1:32,0|f=d2|f=d0/0
  #|jo +0x20|7020|JCC_1:32,0|f=806|f=804/0 j=400022
  #|jo +0x20|7020|JCC_1:32,0|f=853|f=851/0 j=400022
  #|jo +0x20|7020|JCC_1:32,0|f=802|f=800/0 j=400022
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=87|f=85/0
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=857|f=855/0 j=3fff06
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=12|f=10/0
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=c92|f=c90/0 j=3fff06
  #|jno +0x20|7120|JCC_1:32,1|f=82|f=80/0 j=400022
  #|jno +0x20|7120|JCC_1:32,1|f=6|f=4/0 j=400022
  #|jno +0x20|7120|JCC_1:32,1|f=c3|f=c1/0 j=400022
  #|jno +0x20|7120|JCC_1:32,1|f=817|f=815/0
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=13|f=11/0 j=3fff06
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=896|f=894/0
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=807|f=805/0
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=816|f=814/0
  #|jb +0x20|7220|JCC_1:32,2|f=4d2|f=4d0/0
  #|jb +0x20|7220|JCC_1:32,2|f=2|f=0/0
  #|jb +0x20|7220|JCC_1:32,2|f=83|f=81/0 j=400022
  #|jb +0x20|7220|JCC_1:32,2|f=817|f=815/0 j=400022
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=d3|f=d1/0 j=3fff06
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=93|f=91/0 j=3fff06
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=cd7|f=cd5/0 j=3fff06
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=8c6|f=8c4/0
  #|jae +0x20|7320|JCC_1:32,3|f=817|f=815/0
  #|jae +0x20|7320|JCC_1:32,3|f=847|f=845/0
  #|jae +0x20|7320|JCC_1:32,3|f=8d2|f=8d0/0 j=400022
  #|jae +0x20|7320|JCC_1:32,3|f=857|f=855/0
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=842|f=840/0 j=3fff06
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=456|f=454/0 j=3fff06
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=412|f=410/0 j=3fff06
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=842|f=840/0 j=3fff06
  #|je +0x20|7420|JCC_1:32,4|f=843|f=841/0 j=400022
  #|je +0x20|7420|JCC_1:32,4|f=896|f=894/0
  #|je +0x20|7420|JCC_1:32,4|f=8d7|f=8d5/0 j=400022
  #|je +0x20|7420|JCC_1:32,4|f=c93|f=c91/0
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=d7|f=d5/0 j=3fff06
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=802|f=800/0
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=812|f=810/0
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=93|f=91/0
  #|jne +0x20|7520|JCC_1:32,5|f=56|f=54/0
  #|jne +0x20|7520|JCC_1:32,5|f=c86|f=c84/0 j=400022
  #|jne +0x20|7520|JCC_1:32,5|f=57|f=55/0
  #|jne +0x20|7520|JCC_1:32,5|f=c87|f=c85/0 j=400022
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=96|f=94/0 j=3fff06
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=d3|f=d1/0
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=802|f=800/0 j=3fff06
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=803|f=801/0 j=3fff06
  #|jbe +0x20|7620|JCC_1:32,6|f=802|f=800/0
  #|jbe +0x20|7620|JCC_1:32,6|f=893|f=891/0 j=400022
  #|jbe +0x20|7620|JCC_1:32,6|f=856|f=854/0 j=400022
  #|jbe +0x20|7620|JCC_1:32,6|f=8c3|f=8c1/0 j=400022
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=453|f=451/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=93|f=91/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=c2|f=c0/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=12|f=10/0
  #|ja +0x20|7720|JCC_1:32,7|f=402|f=400/0 j=400022
  #|ja +0x20|7720|JCC_1:32,7|f=d6|f=d4/0
  #|ja +0x20|7720|JCC_1:32,7|f=456|f=454/0
  #|ja +0x20|7720|JCC_1:32,7|f=897|f=895/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=453|f=451/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=882|f=880/0 j=3fff06
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=87|f=85/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=12|f=10/0 j=3fff06
  #|js +0x20|7820|JCC_1:32,8|f=887|f=885/0 j=400022
  #|js +0x20|7820|JCC_1:32,8|f=843|f=841/0
  #|js +0x20|7820|JCC_1:32,8|f=8d6|f=8d4/0 j=400022
  #|js +0x20|7820|JCC_1:32,8|f=7|f=5/0
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=886|f=884/0 j=3fff06
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=c57|f=c55/0
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=7|f=5/0
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=803|f=801/0
  #|jns +0x20|7920|JCC_1:32,9|f=8c7|f=8c5/0
  #|jns +0x20|7920|JCC_1:32,9|f=896|f=894/0
  #|jns +0x20|7920|JCC_1:32,9|f=c2|f=c0/0
  #|jns +0x20|7920|JCC_1:32,9|f=86|f=84/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=d7|f=d5/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=883|f=881/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=4c6|f=4c4/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=43|f=41/0 j=3fff06
  #|jp +0x20|7a20|JCC_1:32,10|f=807|f=805/0 j=400022
  #|jp +0x20|7a20|JCC_1:32,10|f=7|f=5/0 j=400022
  #|jp +0x20|7a20|JCC_1:32,10|f=883|f=881/0
  #|jp +0x20|7a20|JCC_1:32,10|f=8c7|f=8c5/0 j=400022
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=853|f=851/0
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=12|f=10/0
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=c3|f=c1/0
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=8d3|f=8d1/0
  #|jnp +0x20|7b20|JCC_1:32,11|f=c57|f=c55/0
  #|jnp +0x20|7b20|JCC_1:32,11|f=13|f=11/0 j=400022
  #|jnp +0x20|7b20|JCC_1:32,11|f=887|f=885/0
  #|jnp +0x20|7b20|JCC_1:32,11|f=d3|f=d1/0 j=400022
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=447|f=445/0
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=13|f=11/0 j=3fff06
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=896|f=894/0
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=817|f=815/0
  #|jl +0x20|7c20|JCC_1:32,12|f=882|f=880/0
  #|jl +0x20|7c20|JCC_1:32,12|f=92|f=90/0 j=400022
  #|jl +0x20|7c20|JCC_1:32,12|f=806|f=804/0 j=400022
  #|jl +0x20|7c20|JCC_1:32,12|f=d6|f=d4/0 j=400022
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=97|f=95/0 j=3fff06
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=13|f=11/0
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=806|f=804/0 j=3fff06
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=8c2|f=8c0/0
  #|jge +0x20|7d20|JCC_1:32,13|f=887|f=885/0 j=400022
  #|jge +0x20|7d20|JCC_1:32,13|f=2|f=0/0 j=400022
  #|jge +0x20|7d20|JCC_1:32,13|f=887|f=885/0 j=400022
  #|jge +0x20|7d20|JCC_1:32,13|f=852|f=850/0
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=c02|f=c00/0
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=82|f=80/0
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=13|f=11/0 j=3fff06
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=c16|f=c14/0
  #|jle +0x20|7e20|JCC_1:32,14|f=846|f=844/0 j=400022
  #|jle +0x20|7e20|JCC_1:32,14|f=887|f=885/0
  #|jle +0x20|7e20|JCC_1:32,14|f=d3|f=d1/0 j=400022
  #|jle +0x20|7e20|JCC_1:32,14|f=856|f=854/0 j=400022
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=c2|f=c0/0 j=3fff06
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=6|f=4/0
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=97|f=95/0 j=3fff06
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=83|f=81/0 j=3fff06
  #|jg +0x20|7f20|JCC_1:32,15|f=4d2|f=4d0/0
  #|jg +0x20|7f20|JCC_1:32,15|f=c3|f=c1/0
  #|jg +0x20|7f20|JCC_1:32,15|f=83|f=81/0
  #|jg +0x20|7f20|JCC_1:32,15|f=8c7|f=8c5/0
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=c6|f=c4/0
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=803|f=801/0
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=6|f=4/0 j=3fff06
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=443|f=441/0
  #|jrcxz +0x8|e308|JRCXZ:8|rax=ec7a9161f834c4d8 rcx=0 rdx=26ca24343f55aabf f=853|f=851/0 j=40000a
  #|jrcxz +0x8|e308|JRCXZ:8|rax=42bd010a9d0f03d3 rcx=2 rdx=76b8e35ab1a810e f=43|f=41/0
  #|jrcxz +0x8|e308|JRCXZ:8|rax=fffffffffffffffe rcx=1 rdx=160f42232b6207fe f=17|f=15/0
  #|jrcxz +0x8|e308|JRCXZ:8|rax=7fffffff rcx=1 rdx=f9da f=4d3|f=4d1/0
  #|loop +0x8|e208|LOOP:8|rax=31f6440b5fdde587 rcx=5 rdx=e00a711cc678fcff f=8d3|rcx=4 f=8d1/0 j=40000a
  #|loop +0x8|e208|LOOP:8|rax=fffffffffffffffe rcx=1 f=92|rcx=0 f=90/0
  #|loop +0x8|e208|LOOP:8|rax=7df04d6064b60fd9 rcx=5 f=cc7|rcx=4 f=cc5/0 j=40000a
  #|loope +0x8|e108|LOOPE:8|rax=0 rcx=2 f=852|rcx=1 f=850/0 j=40000a
  #|loope +0x8|e108|LOOPE:8|rcx=100000000 f=896|rcx=ffffffff f=894/0
  #|loope +0x8|e108|LOOPE:8|rax=2818eaac0d370d9a rcx=0 rdx=2 f=92|rcx=ffffffffffffffff f=90/0
  #|loopne +0x8|e008|LOOPNE:8|rax=8000 rcx=ffffffff00000001 rdx=80 f=43|rcx=ffffffff00000000 f=41/0
  #|loopne +0x8|e008|LOOPNE:8|rcx=1 rdx=639b0303afb96bd9 f=857|rcx=0 f=855/0
  #|loopne +0x8|e008|LOOPNE:8|rax=47ce95abe6f48000 rcx=1 rdx=9ab2f40a5b6bc878 f=cc6|rcx=0 f=cc4/0
  #|call rbx|ffd3|CALL64r:%RBX|rbx=400008 f=842|rsp=200f8 f=840/0 m200f8=0200400000000000 j=400008
  #|call rbx|ffd3|CALL64r:%RBX|rbx=400008 f=882|rsp=200f8 f=880/0 m200f8=0200400000000000 j=400008
  #|jmp rbx|ffe3|JMP64r:%RBX|rbx=401000 f=c12|f=c10/0 j=401000
  #|jmp rbx|ffe3|JMP64r:%RBX|rbx=401000 f=802|f=800/0 j=401000
  #|call qword ptr [rsi]|ff16|CALL64m:%RSI,1,%,0,%|f=93 m10080=0020400000000000|rsp=200f8 f=91/0 m200f8=0200400000000000 j=402000
  #|call qword ptr [rsi]|ff16|CALL64m:%RSI,1,%,0,%|f=c13 m10080=0020400000000000|rsp=200f8 f=c11/0 m200f8=0200400000000000 j=402000
  #|jmp qword ptr [rsi]|ff26|JMP64m:%RSI,1,%,0,%|f=12 m10080=0020400000000000|f=10/0 j=402000
  #|jmp qword ptr [rsi]|ff26|JMP64m:%RSI,1,%,0,%|f=886 m10080=0020400000000000|f=884/0 j=402000

///|
let control32_cases : String =
  #|push eax|50|PUSH32r:%EAX|eax=6fe8cc2b f=93|esp=200fc f=91/0 m200fc=2bcce86f
  #|pop eax|58|POP32r:%EAX|eax=19fad854 f=4c7|eax=18bd6207 esp=20104 f=4c5/0
  #|push ecx|51|PUSH32r:%ECX|ecx=1f3e1675 f=c93|esp=200fc f=c91/0 m200fc=75163e1f
  #|pop ecx|59|POP32r:%ECX|ecx=e42f3a7 f=8c7|ecx=18bd6207 esp=20104 f=8c5/0
  #|push edx|52|PUSH32r:%EDX|edx=1c9c6407 f=846|esp=200fc f=844/0 m200fc=07649c1c
  #|pop edx|5a|POP32r:%EDX|edx=35754f1c f=c57|edx=18bd6207 esp=20104 f=c55/0
  #|push ebx|53|PUSH32r:%EBX|ebx=5a4d7f04 f=97|esp=200fc f=95/0 m200fc=047f4d5a
  #|pop ebx|5b|POP32r:%EBX|ebx=17145900 f=8c3|ebx=18bd6207 esp=20104 f=8c1/0
  #|push esp|54|PUSH32r:%ESP|f=7|esp=200fc f=5/0 m200fc=00010200
  #|pop ebp|5d|POP32r:%EBP|f=8c3|esp=20104 ebp=18bd6207 f=8c1/0
  #|push ax|6650|PUSH16r:%AX|eax=2986 f=843|esp=200fe f=841/0 m200fe=8629
  #|pop cx|6659|POP16r:%CX|ecx=100 f=97|ecx=6207 esp=20102 f=95/0
  #|push -0x2|6afe|PUSH32i8:-2|f=43|esp=200fc f=41/0 m200fc=feffffff
  #|push 0x12345678|6878563412|PUSH32i:305419896|f=d6|esp=200fc f=d4/0 m200fc=78563412
  #|push dword ptr [esi]|ff36|PUSH32rmm:%ESI,1,%,0,%|f=803 m10080=86312d98dcbed8fddb0ccc8e6462fef8|esp=200fc f=801/0 m200fc=86312d98
  #|push dword ptr [esi]|ff36|PUSH32rmm:%ESI,1,%,0,%|f=cc2 m10080=2276eff5cf0003ced983e0acd77f90ba|esp=200fc f=cc0/0 m200fc=2276eff5
  #|pop dword ptr [esi]|8f06|POP32rmm:%ESI,1,%,0,%|f=893 m10080=7395be2abbac771bc575c46a68df4cba|esp=20104 f=891/0 m10080=0762bd18
  #|pop dword ptr [esi]|8f06|POP32rmm:%ESI,1,%,0,%|f=96 m10080=39523f6bc08936e1b6db7cda7ff576e6|esp=20104 f=94/0 m10080=0762bd18
  #|pushf|9c|PUSHF32:|f=86|esp=200fc f=84/0 m=?
  #|pushf|9c|PUSHF32:|f=897|esp=200fc f=895/0 m=?
  #|popf|9d|POPF32:|f=842 m20100=97000000|esp=20104 f=95/0
  #|popf|9d|POPF32:|f=c16 m20100=12000000|esp=20104 f=10/0
  #|popf|9d|POPF32:|f=3 m20100=87040000|esp=20104 f=485/0
  #|leave|c9|LEAVE:|f=86|esp=20184 ebp=983de287 f=84/0
  #|leave|c9|LEAVE:|f=886|esp=20184 ebp=983de287 f=884/0
  #|enter 0x10, 0|c8100000|ENTER:16,0|f=87|esp=200ec ebp=200fc f=85/0 m200fc=80010200
  #|enter 0x8, 1|c8080001|ENTER:8,1|f=853|esp=200f0 ebp=200fc f=851/0 m200f8=fc00020080010200
  #|call +0x100|e800010000|CALLpcrel32:256|f=c2|esp=200fc f=c0/0 m200fc=05004000 j=400105
  #|call +0x100|e800010000|CALLpcrel32:256|f=c82|esp=200fc f=c80/0 m200fc=05004000 j=400105
  #|call +0x100|e800010000|CALLpcrel32:256|f=c3|esp=200fc f=c1/0 m200fc=05004000 j=400105
  #|jmp +0x10|eb10|JMP_1:16|f=3|f=1/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=807|f=805/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=c02|f=c00/0 j=400012
  #|jmp +0x10|eb10|JMP_1:16|f=8d2|f=8d0/0 j=400012
  #|jmp -0x10|ebf0|JMP_1:-16|f=46|f=44/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=493|f=491/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=8c2|f=8c0/0 j=3ffff2
  #|jmp -0x10|ebf0|JMP_1:-16|f=892|f=890/0 j=3ffff2
  #|jmp +0x1000|e900100000|JMP_4:4096|f=c52|f=c50/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=8c2|f=8c0/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=806|f=804/0 j=401005
  #|jmp +0x1000|e900100000|JMP_4:4096|f=12|f=10/0 j=401005
  #|ret|c3|RET32:|f=816 m20100=34124000|esp=20104 f=814/0 j=401234
  #|ret|c3|RET32:|f=16 m20100=34124000|esp=20104 f=14/0 j=401234
  #|ret|c3|RET32:|f=886 m20100=34124000|esp=20104 f=884/0 j=401234
  #|ret 0x10|c21000|RETI32:16|f=856 m20100=34124000|esp=20114 f=854/0 j=401234
  #|ret 0x10|c21000|RETI32:16|f=d3 m20100=34124000|esp=20114 f=d1/0 j=401234
  #|ret 0x10|c21000|RETI32:16|f=893 m20100=34124000|esp=20114 f=891/0 j=401234
  #|jo +0x20|7020|JCC_1:32,0|f=813|f=811/0 j=400022
  #|jo +0x20|7020|JCC_1:32,0|f=856|f=854/0 j=400022
  #|jo +0x20|7020|JCC_1:32,0|f=3|f=1/0
  #|jo +0x20|7020|JCC_1:32,0|f=843|f=841/0 j=400022
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=82|f=80/0
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=457|f=455/0
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=c16|f=c14/0 j=3fff06
  #|jo -0x100 (near)|0f8000ffffff|JCC_4:-256,0|f=56|f=54/0
  #|jno +0x20|7120|JCC_1:32,1|f=847|f=845/0
  #|jno +0x20|7120|JCC_1:32,1|f=852|f=850/0
  #|jno +0x20|7120|JCC_1:32,1|f=886|f=884/0
  #|jno +0x20|7120|JCC_1:32,1|f=92|f=90/0 j=400022
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=4d3|f=4d1/0 j=3fff06
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=46|f=44/0 j=3fff06
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=803|f=801/0
  #|jno -0x100 (near)|0f8100ffffff|JCC_4:-256,1|f=442|f=440/0 j=3fff06
  #|jb +0x20|7220|JCC_1:32,2|f=846|f=844/0
  #|jb +0x20|7220|JCC_1:32,2|f=883|f=881/0 j=400022
  #|jb +0x20|7220|JCC_1:32,2|f=446|f=444/0
  #|jb +0x20|7220|JCC_1:32,2|f=53|f=51/0 j=400022
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=443|f=441/0 j=3fff06
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=c7|f=c5/0 j=3fff06
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=2|f=0/0
  #|jb -0x100 (near)|0f8200ffffff|JCC_4:-256,2|f=7|f=5/0 j=3fff06
  #|jae +0x20|7320|JCC_1:32,3|f=c52|f=c50/0 j=400022
  #|jae +0x20|7320|JCC_1:32,3|f=407|f=405/0
  #|jae +0x20|7320|JCC_1:32,3|f=d7|f=d5/0
  #|jae +0x20|7320|JCC_1:32,3|f=4d3|f=4d1/0
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=892|f=890/0 j=3fff06
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=816|f=814/0 j=3fff06
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=817|f=815/0
  #|jae -0x100 (near)|0f8300ffffff|JCC_4:-256,3|f=47|f=45/0
  #|je +0x20|7420|JCC_1:32,4|f=17|f=15/0
  #|je +0x20|7420|JCC_1:32,4|f=8d7|f=8d5/0 j=400022
  #|je +0x20|7420|JCC_1:32,4|f=852|f=850/0 j=400022
  #|je +0x20|7420|JCC_1:32,4|f=4c6|f=4c4/0 j=400022
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=896|f=894/0
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=896|f=894/0
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=c2|f=c0/0 j=3fff06
  #|je -0x100 (near)|0f8400ffffff|JCC_4:-256,4|f=806|f=804/0
  #|jne +0x20|7520|JCC_1:32,5|f=92|f=90/0 j=400022
  #|jne +0x20|7520|JCC_1:32,5|f=887|f=885/0 j=400022
  #|jne +0x20|7520|JCC_1:32,5|f=8c2|f=8c0/0
  #|jne +0x20|7520|JCC_1:32,5|f=d2|f=d0/0
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=887|f=885/0 j=3fff06
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=803|f=801/0 j=3fff06
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=97|f=95/0 j=3fff06
  #|jne -0x100 (near)|0f8500ffffff|JCC_4:-256,5|f=c3|f=c1/0
  #|jbe +0x20|7620|JCC_1:32,6|f=8d2|f=8d0/0 j=400022
  #|jbe +0x20|7620|JCC_1:32,6|f=812|f=810/0
  #|jbe +0x20|7620|JCC_1:32,6|f=7|f=5/0 j=400022
  #|jbe +0x20|7620|JCC_1:32,6|f=53|f=51/0 j=400022
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=807|f=805/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=846|f=844/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=843|f=841/0 j=3fff06
  #|jbe -0x100 (near)|0f8600ffffff|JCC_4:-256,6|f=803|f=801/0 j=3fff06
  #|ja +0x20|7720|JCC_1:32,7|f=56|f=54/0
  #|ja +0x20|7720|JCC_1:32,7|f=57|f=55/0
  #|ja +0x20|7720|JCC_1:32,7|f=c3|f=c1/0
  #|ja +0x20|7720|JCC_1:32,7|f=d7|f=d5/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=c53|f=c51/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=802|f=800/0 j=3fff06
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=d2|f=d0/0
  #|ja -0x100 (near)|0f8700ffffff|JCC_4:-256,7|f=c93|f=c91/0
  #|js +0x20|7820|JCC_1:32,8|f=8d2|f=8d0/0 j=400022
  #|js +0x20|7820|JCC_1:32,8|f=483|f=481/0 j=400022
  #|js +0x20|7820|JCC_1:32,8|f=97|f=95/0 j=400022
  #|js +0x20|7820|JCC_1:32,8|f=d7|f=d5/0 j=400022
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=8c6|f=8c4/0 j=3fff06
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=893|f=891/0 j=3fff06
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=83|f=81/0 j=3fff06
  #|js -0x100 (near)|0f8800ffffff|JCC_4:-256,8|f=843|f=841/0
  #|jns +0x20|7920|JCC_1:32,9|f=d6|f=d4/0
  #|jns +0x20|7920|JCC_1:32,9|f=82|f=80/0
  #|jns +0x20|7920|JCC_1:32,9|f=887|f=885/0
  #|jns +0x20|7920|JCC_1:32,9|f=883|f=881/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=93|f=91/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=97|f=95/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=c83|f=c81/0
  #|jns -0x100 (near)|0f8900ffffff|JCC_4:-256,9|f=c86|f=c84/0
  #|jp +0x20|7a20|JCC_1:32,10|f=2|f=0/0
  #|jp +0x20|7a20|JCC_1:32,10|f=813|f=811/0
  #|jp +0x20|7a20|JCC_1:32,10|f=857|f=855/0 j=400022
  #|jp +0x20|7a20|JCC_1:32,10|f=56|f=54/0 j=400022
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=c82|f=c80/0
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=8d3|f=8d1/0
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=8d6|f=8d4/0 j=3fff06
  #|jp -0x100 (near)|0f8a00ffffff|JCC_4:-256,10|f=83|f=81/0
  #|jnp +0x20|7b20|JCC_1:32,11|f=813|f=811/0 j=400022
  #|jnp +0x20|7b20|JCC_1:32,11|f=806|f=804/0
  #|jnp +0x20|7b20|JCC_1:32,11|f=c2|f=c0/0 j=400022
  #|jnp +0x20|7b20|JCC_1:32,11|f=4c6|f=4c4/0
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=cd7|f=cd5/0
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=52|f=50/0 j=3fff06
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=857|f=855/0
  #|jnp -0x100 (near)|0f8b00ffffff|JCC_4:-256,11|f=6|f=4/0
  #|jl +0x20|7c20|JCC_1:32,12|f=93|f=91/0 j=400022
  #|jl +0x20|7c20|JCC_1:32,12|f=497|f=495/0 j=400022
  #|jl +0x20|7c20|JCC_1:32,12|f=887|f=885/0
  #|jl +0x20|7c20|JCC_1:32,12|f=847|f=845/0 j=400022
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=847|f=845/0 j=3fff06
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=43|f=41/0
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=813|f=811/0 j=3fff06
  #|jl -0x100 (near)|0f8c00ffffff|JCC_4:-256,12|f=882|f=880/0
  #|jge +0x20|7d20|JCC_1:32,13|f=82|f=80/0
  #|jge +0x20|7d20|JCC_1:32,13|f=c87|f=c85/0 j=400022
  #|jge +0x20|7d20|JCC_1:32,13|f=897|f=895/0 j=400022
  #|jge +0x20|7d20|JCC_1:32,13|f=3|f=1/0 j=400022
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=843|f=841/0
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=843|f=841/0
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=57|f=55/0 j=3fff06
  #|jge -0x100 (near)|0f8d00ffffff|JCC_4:-256,13|f=87|f=85/0
  #|jle +0x20|7e20|JCC_1:32,14|f=c6|f=c4/0 j=400022
  #|jle +0x20|7e20|JCC_1:32,14|f=c2|f=c0/0 j=400022
  #|jle +0x20|7e20|JCC_1:32,14|f=13|f=11/0
  #|jle +0x20|7e20|JCC_1:32,14|f=846|f=844/0 j=400022
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=886|f=884/0
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=843|f=841/0 j=3fff06
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=c7|f=c5/0 j=3fff06
  #|jle -0x100 (near)|0f8e00ffffff|JCC_4:-256,14|f=883|f=881/0
  #|jg +0x20|7f20|JCC_1:32,15|f=13|f=11/0 j=400022
  #|jg +0x20|7f20|JCC_1:32,15|f=d2|f=d0/0
  #|jg +0x20|7f20|JCC_1:32,15|f=16|f=14/0 j=400022
  #|jg +0x20|7f20|JCC_1:32,15|f=83|f=81/0
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=8c6|f=8c4/0
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=16|f=14/0 j=3fff06
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=887|f=885/0 j=3fff06
  #|jg -0x100 (near)|0f8f00ffffff|JCC_4:-256,15|f=7|f=5/0 j=3fff06
  #|jecxz +0x8|e308|JECXZ:8|eax=d6fc325c ecx=2 edx=100 f=883|f=881/0
  #|jecxz +0x8|e308|JECXZ:8|eax=c ecx=1 edx=d5856220 f=97|f=95/0
  #|jecxz +0x8|e308|JECXZ:8|ecx=2 f=8d6|f=8d4/0
  #|jecxz +0x8|e308|JECXZ:8|eax=687a6dd9 ecx=0 edx=2330413d f=57|f=55/0 j=40000a
  #|loop +0x8|e208|LOOP:8|eax=8e3d888c ecx=5 f=d7|ecx=4 f=d5/0 j=40000a
  #|loop +0x8|e208|LOOP:8|eax=2 ecx=5 f=13|ecx=4 f=11/0 j=40000a
  #|loop +0x8|e208|LOOP:8|ecx=2 f=8c2|ecx=1 f=8c0/0 j=40000a
  #|loope +0x8|e108|LOOPE:8|ecx=0 edx=60019808 f=57|ecx=ffffffff f=55/0 j=40000a
  #|loope +0x8|e108|LOOPE:8|ecx=2 edx=7ba68fd0 f=16|ecx=1 f=14/0
  #|loope +0x8|e108|LOOPE:8|ecx=5 edx=f91bac8d f=2|ecx=4 f=0/0
  #|loopne +0x8|e008|LOOPNE:8|eax=fffffffe ecx=1 f=407|ecx=0 f=405/0
  #|loopne +0x8|e008|LOOPNE:8|ecx=0 f=c43|ecx=ffffffff f=c41/0
  #|loopne +0x8|e008|LOOPNE:8|eax=866b84d6 ecx=5 edx=6cf013e0 f=887|ecx=4 f=885/0 j=40000a
  #|call ebx|ffd3|CALL32r:%EBX|ebx=400008 f=803|esp=200fc f=801/0 m200fc=02004000 j=400008
  #|call ebx|ffd3|CALL32r:%EBX|ebx=401000 f=8d2|esp=200fc f=8d0/0 m200fc=02004000 j=401000
  #|jmp ebx|ffe3|JMP32r:%EBX|ebx=400008 f=c96|f=c94/0 j=400008
  #|jmp ebx|ffe3|JMP32r:%EBX|ebx=401000 f=13|f=11/0 j=401000
  #|call dword ptr [esi]|ff16|CALL32m:%ESI,1,%,0,%|f=c7 m10080=00204000|esp=200fc f=c5/0 m200fc=02004000 j=402000
  #|call dword ptr [esi]|ff16|CALL32m:%ESI,1,%,0,%|f=842 m10080=00204000|esp=200fc f=840/0 m200fc=02004000 j=402000
  #|jmp dword ptr [esi]|ff26|JMP32m:%ESI,1,%,0,%|f=c87 m10080=00204000|f=c85/0 j=402000
  #|jmp dword ptr [esi]|ff26|JMP32m:%ESI,1,%,0,%|f=7 m10080=00204000|f=5/0 j=402000
