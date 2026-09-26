// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let muldiv64_cases : String =
  #|mul r8b|41f6e0|MUL8r:%R8B|rcx=bc9dabba80000000 rdx=73b2 r8=ff f=c6|rax=5b791f3dd3f1b44b f=805/d4
  #|mul r8b|41f6e0|MUL8r:%R8B|rcx=c8303143ad4bef60 rdx=87758e7b69f59b09 r8=2166 f=8c6|rax=5b791f3dd3f1481e f=805/d4
  #|mul r8b|41f6e0|MUL8r:%R8B|rax=127af9fce368b66f rcx=3125 rdx=e69a0f3e804a298b r8=94 f=7|rax=127af9fce368402c f=801/d4
  #|mul r8b|41f6e0|MUL8r:%R8B|rax=fc5cabece034b42f rcx=ffffffffffffffff rdx=d9168dc75b90148a r8=c9f941ef19f9675b f=d7|rax=fc5cabece03410b5 f=881/d4
  #|mul byte ptr [rsp + 0x8]|f6642408|MUL8m:%RSP,1,%,8,%|rcx=fffffffffffffffe rbx=c r9=9 f=83 m20108=f58826b264373ff8e43f3522015a4b0d|rax=5b791f3dd3f1ad39 f=805/d4
  #|mul byte ptr [rsp + 0x8]|f6642408|MUL8m:%RSP,1,%,8,%|rax=c5149e147d4ecdb rdx=4cab8cb560515eff rbx=9 r9=3 f=d7 m20108=4b307413cdf404d9359062bd69c1a6d7|rax=c5149e147d44029 f=801/d4
  #|mul byte ptr [rsp + 0x8]|f6642408|MUL8m:%RSP,1,%,8,%|rax=32283e0c915a0494 rcx=ee0e64a55a0df6ff rbx=5 r9=3 f=c02 m20108=c9638d1c22a2d759b168f038263db958|rax=32283e0c915a7434 f=c01/d4
  #|imul cl|f6e9|IMUL8r:%CL|rax=8b6b48b6ad2f8a8d rcx=3486440e50909922 rdx=ffffffff f=457|rax=8b6b48b6ad2ff0ba f=c81/d4
  #|imul cl|f6e9|IMUL8r:%CL|rax=ef476ddb6939ba80 rcx=0 rdx=62ff7f484ac3056 f=806|rax=ef476ddb69390000 f=44/d4
  #|imul cl|f6e9|IMUL8r:%CL|rcx=f797765609d65db6 rdx=ef28fcbdd45462cb f=c12|rax=5b791f3dd3f115ae f=c81/d4
  #|imul cl|f6e9|IMUL8r:%CL|rax=2ee83963a5c8c09d rcx=c4ee5e8af1f4b900 rdx=e51e f=97|rax=2ee83963a5c80000 f=44/d4
  #|imul byte ptr [rsi]|f62e|IMUL8m:%RSI,1,%,0,%|rax=85895ca1112e4f33 rcx=b0d0d650656491c6 rdx=612bb9f0732971dc rbx=2 r9=0 f=c6 m10080=6452bcbc6593e805326b5131be0d8e1b|rax=85895ca1112e13ec f=881/d4
  #|imul byte ptr [rsi]|f62e|IMUL8m:%RSI,1,%,0,%|rax=54641592edec0322 rcx=1917aa53d30f3f1 rdx=a6 rbx=4 r9=e f=492 m10080=672b6c764d85ec74b0419dfbb6cd6b25|rax=54641592edec0dae f=c81/d4
  #|imul byte ptr [rsi]|f62e|IMUL8m:%RSI,1,%,0,%|rcx=eb773cbc893c2a4 rdx=3 rbx=4 r9=3 f=852 m10080=4618462279605ca3608dfab731933541|rax=5b791f3dd3f1eb7e f=805/d4
  #|div bl|f6f3|DIV8r:%BL|rax=26 rdx=fffffffffffffffe rbx=e46af2e70cee8003 f=442|rax=20c f=440/8d5
  #|div bl|f6f3|DIV8r:%BL|rax=32 rcx=ba748a625bafa89b rdx=7bceaaa8db4b986c rbx=6e7b6da40b39b801 f=813|f=811/8d5
  #|div bl|f6f3|DIV8r:%BL|rax=dcf3 rcx=dab6062cf09802a7 rdx=8e80e368824066ef rbx=25b43b08fdc5ece9 f=86|rax=b1f2 f=84/8d5
  #|div bl|f6f3|DIV8r:%BL|rax=37 rdx=ac3d70f00d40113f rbx=50129bebd1b479ff f=842|rax=3700 f=840/8d5
  #|div bl|f6f3|DIV8r:%BL|rax=4f23689a814e0081 rcx=f rdx=7f09bd2233466239 rbx=c485260bd4a28007 f=52|rax=4f23689a814e0312 f=50/8d5
  #|div bl|f6f3|DIV8r:%BL|rax=a8af747b67cd002d rcx=492c8c6e6179e36a rdx=16e67bb120831bfe rbx=33d4b564f6e5fbed f=893|rax=a8af747b67cd2d00 f=891/8d5
  #|div byte ptr [rdi + r9*2 - 0x4]|42f6744ffc|DIV8m:%RDI,2,%R9,-4,%|rax=ffffffffffff963b rcx=ff rbx=e r9=1 f=853 m100fe=509de37cae53520707c08456125e62a5|e=0 f=851/8d5
  #|div byte ptr [rdi + r9*2 - 0x4]|42f6744ffc|DIV8m:%RDI,2,%R9,-4,%|rax=2c rcx=80000000 rbx=e r9=e f=803 m10118=ee62975805c37eb1687fc86126563a82|rax=2c00 f=801/8d5
  #|div byte ptr [rdi + r9*2 - 0x4]|42f6744ffc|DIV8m:%RDI,2,%R9,-4,%|rax=efd2 rcx=97844d688a34e8f0 rdx=3c4f912ccc50d5f2 rbx=4 r9=d f=492 m10116=4e9ce053b3d8cf7deb1bc71fca7cfc66|e=0 f=490/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=2f39e91df361004f rcx=0 rdx=7fffffffffffffff r8=5c2cc5f2f7e08600 f=57|e=0 f=55/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=9597f354899d0089 rdx=7 r8=dd315bb0d2cf499f f=8d2|rax=9597f354899d28ff f=8d0/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=efedfdf0db3a6805 rcx=9aa3e830fada6684 rdx=3d9e4e3b869389d5 r8=789e83055e94d187 f=42|e=0 f=40/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=57 rcx=100 r8=1df6a400e21627ad f=87|rax=4ff f=85/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=4951f08e7fff1927 rdx=b4189a8fde554973 r8=c5 f=853|rax=4951f08e7fff0893 f=851/8d5
  #|idiv r8b|41f6f8|IDIV8r:%R8B|rax=5235615e0d2500d6 rcx=5a rdx=0 r8=ffc9 f=8d2|rax=5235615e0d2531fd f=8d0/8d5
  #|idiv byte ptr [rbp - 0x20]|f67de0|IDIV8m:%RBP,1,%,-32,%|rax=5f rdx=8e6d6092c03b5bc1 rbx=1 r9=5 f=47 m20160=8e0fe33cc3104c4d843695c4f5c7275b|rax=5f00 f=45/8d5
  #|idiv byte ptr [rbp - 0x20]|f67de0|IDIV8m:%RBP,1,%,-32,%|rax=b74884f451bf662a rcx=712d94312e2ac262 rbx=b r9=e f=83 m20160=bdf3a73523bb0b07421ab0980b87c3d4|e=0 f=81/8d5
  #|idiv byte ptr [rbp - 0x20]|f67de0|IDIV8m:%RBP,1,%,-32,%|rax=83 rcx=5903a3f877a456b6 rbx=3 r9=5 f=6 m20160=013865b970b434d0b07cca355d9c1c70|e=0 f=4/8d5
  #|mul cx|66f7e1|MUL16r:%CX|rax=db829785ec2e2a25 rcx=856afe46a91d558e rdx=b35f9ba07d80b87b f=c43|rax=db829785ec2ea986 rdx=b35f9ba07d800e15 f=c81/d4
  #|mul cx|66f7e1|MUL16r:%CX|rax=a rcx=19058c901124cef4 rdx=f f=882|rax=1588 rdx=8 f=805/d4
  #|mul cx|66f7e1|MUL16r:%CX|rcx=baa198dc60661296 rdx=d621 f=93|rax=5b791f3dd3f19e0e rdx=b03 f=881/d4
  #|mul cx|66f7e1|MUL16r:%CX|rcx=4e96318dd6d7ba6c rdx=8c39d5d9f48f6253 f=8c3|rax=5b791f3dd3f1825c rdx=8c39d5d9f48f6e79 f=885/d4
  #|mul word ptr [rsi]|66f726|MUL16m:%RSI,1,%,0,%|rax=d5c0e1bf074acef4 rcx=532b396a5e6212b0 rdx=4ce5f650de393a2f rbx=d r9=b f=8d7 m10080=e1f0e9701aff272cb037bf64aeccb3f9|rax=d5c0e1bf074aa474 rdx=4ce5f650de39c2ba f=885/d4
  #|mul word ptr [rsi]|66f726|MUL16m:%RSI,1,%,0,%|rax=a348228e9f0d926f rcx=45438ff8027b416e rdx=ffffffff rbx=e r9=d f=8d3 m10080=79bc4dad401c7c92b943899e18c5e766|rax=a348228e9f0dba77 rdx=ffff6bce f=885/d4
  #|mul word ptr [rsi]|66f726|MUL16m:%RSI,1,%,0,%|rdx=d1f1abc1940b8e24 rbx=c r9=8 f=412 m10080=1434beeeb07357d2f406437c60c367c9|rax=5b791f3dd3f19e24 rdx=d1f1abc1940b1edc f=c85/d4
  #|imul cx|66f7e9|IMUL16r:%CX|rax=f7007ba04183c55f rcx=c8 f=887|rax=f7007ba041833238 rdx=59338a6cc759ffd2 f=801/d4
  #|imul cx|66f7e9|IMUL16r:%CX|rcx=795f7b40f50678d9 rdx=7cb49dbc3c86ef25 f=892|rax=5b791f3dd3f1706d rdx=7cb49dbc3c86cec4 f=801/d4
  #|imul cx|66f7e9|IMUL16r:%CX|rax=3f8709870a83d9bb rcx=c55bf96f4ba66634 rdx=7 f=c96|rax=3f8709870a83bbfc rdx=f0b8 f=c85/d4
  #|imul cx|66f7e9|IMUL16r:%CX|rax=42b1714d57b714e9 rcx=31e25d4d60b0f93f f=d7|rax=42b1714d57b7c657 rdx=59338a6cc759ff72 f=881/d4
  #|imul word ptr [rsi]|66f72e|IMUL16m:%RSI,1,%,0,%|rax=6bacc7c749e046b4 rcx=4931d7fb2da298d2 rdx=bf5fca498c06b281 rbx=e r9=f f=853 m10080=26278495c9c166b4473db80b7d81675b|rax=6bacc7c749e0eab8 rdx=bf5fca498c060acf f=885/d4
  #|imul word ptr [rsi]|66f72e|IMUL16m:%RSI,1,%,0,%|rax=6560e9ee5ecd529 rdx=b29b7d3c7f1dd892 rbx=b r9=e f=847 m10080=f4ac84bb21e995d41b79e0ef2f6d8139|rax=6560e9ee5ecb714 rdx=b29b7d3c7f1d0de5 f=885/d4
  #|imul word ptr [rsi]|66f72e|IMUL16m:%RSI,1,%,0,%|rax=9f1462337bd8c2d5 rcx=c2950afd7b5a3fba rbx=2 r9=5 f=457 m10080=3af23967d15d3adc53b2694b0f6cafc8|rax=9f1462337bd87e42 rdx=59338a6cc759034a f=c05/d4
  #|div bx|66f7f3|DIV16r:%BX|rax=2cbf35e01d8e2525 rcx=de17d2d7e0a3f rdx=0 rbx=e297 f=812|rax=2cbf35e01d8e0000 rdx=2525 f=810/8d5
  #|div bx|66f7f3|DIV16r:%BX|rcx=32 rdx=e rbx=3d6ee5d68000222d f=97|rax=5b791f3dd3f1006d rdx=a8c f=95/8d5
  #|div bx|66f7f3|DIV16r:%BX|rax=1b01312586911669 rdx=27a05e764ac0000 rbx=28a39d0cb609692d f=53|rax=1b01312586910000 rdx=27a05e764ac1669 f=51/8d5
  #|div bx|66f7f3|DIV16r:%BX|rax=53bcd69e57e7376b rcx=cfe07b74eaf77146 rdx=0 rbx=67993851a5701c2f f=856|rax=53bcd69e57e70001 rdx=1b3c f=854/8d5
  #|div bx|66f7f3|DIV16r:%BX|rax=485bc44fbd20241e rcx=2ada920fb0b2200e rdx=0 rbx=80d5 f=d6|rax=485bc44fbd200000 rdx=241e f=d4/8d5
  #|div bx|66f7f3|DIV16r:%BX|rax=7e2e02cf1e40da3b rdx=1040db1f72e3000a rbx=0 f=403|e=0 f=401/8d5
  #|div word ptr [rdi + 0x10]|66f77710|DIV16m:%RDI,1,%,16,%|rcx=cfa99f81804b7080 rdx=0 rbx=3 r9=4 f=52 m10110=79c906ae095653cd9c640f21a382ccf8|rax=5b791f3dd3f10000 rdx=97b5 f=50/8d5
  #|div word ptr [rdi + 0x10]|66f77710|DIV16m:%RDI,1,%,16,%|rax=5 rcx=8000000000000000 rdx=0 rbx=9 r9=6 f=2 m10110=09730a7b193b4ef06f2107c469937546|rax=0 rdx=5 f=0/8d5
  #|div word ptr [rdi + 0x10]|66f77710|DIV16m:%RDI,1,%,16,%|rax=2c22c40f2fa893cc rcx=5dc4c53fc89358e9 rdx=25cd5984b751cfa8 rbx=1 r9=0 f=3 m10110=7b82dfbe87d737a27ecd3a58232de792|e=0 f=1/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rax=1aa65ed8d32c0e23 rcx=8b2c9c15fd9c5f43 rdx=ffff r8=2a04bfc986a10000 f=8d6|e=0 f=8d4/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rdx=ffffffffffffffff r8=c24d f=802|rax=5b791f3dd3f10001 rdx=ffffffffffffd568 f=800/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rdx=ffff r8=fdf9 f=802|rax=5b791f3dd3f10033 rdx=ff1a f=800/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rax=f82f8e934bc3c636 rdx=169c2e15fa6effff r8=45bb f=8c6|rax=f82f8e934bc30000 rdx=169c2e15fa6ec636 f=8c4/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rax=83e rcx=9999e67ea55f4a4e rdx=7becd69ce4ad0001 r8=76b9df33a8310001 f=8d6|e=0 f=8d4/8d5
  #|idiv r8w|6641f7f8|IDIV16r:%R8W|rdx=b r8=7 f=83|e=0 f=81/8d5
  #|idiv word ptr [rdi + 0x10]|66f77f10|IDIV16m:%RDI,1,%,16,%|rax=901 rcx=80 rdx=17c59ac683bffff rbx=6 r9=1 f=812 m10110=c72858830a20cfc46eaec3624eb616ce|rax=fffa rdx=17c59ac683bfdab f=810/8d5
  #|idiv word ptr [rdi + 0x10]|66f77f10|IDIV16m:%RDI,1,%,16,%|rdx=4d8679bde3b7ffff rbx=1 r9=f f=806 m10110=678e503bf328e1a259cee7bb850fc88f|rax=5b791f3dd3f10000 rdx=4d8679bde3b797b5 f=804/8d5
  #|idiv word ptr [rdi + 0x10]|66f77f10|IDIV16m:%RDI,1,%,16,%|rax=cd063a420aba013b rcx=f3d0b158dfa86637 rdx=f0bcf41e8bbb0000 rbx=a r9=7 f=812 m10110=2077e5d2350e1780f3dece8d9bc4ad33|rax=cd063a420aba0000 rdx=f0bcf41e8bbb013b f=810/8d5
  #|imul r11w, r8w|66450fafd8|IMUL16rr:%R11W,%R11W,%R8W|rax=7a0d85dc3218ffff rcx=c0dbd08e4c34aa80 rdx=c2c85d9608005725 r8=0 r11=a f=d3|r11=0 f=44/d4
  #|imul r11w, r8w|66450fafd8|IMUL16rr:%R11W,%R11W,%R8W|rax=40a5aeacd8304c46 rcx=4d76b5e069e5349a rdx=35b8fd00cd5b1158 r8=37b26c692ebe219c r11=7455f8f921d096d1 f=93|r11=7455f8f921d0d85c f=885/d4
  #|imul r11w, r8w|66450fafd8|IMUL16rr:%R11W,%R11W,%R8W|rax=2 r8=80 r11=ce149f79c77dea1c f=843|r11=ce149f79c77d0e00 f=805/d4
  #|imul r11w, r8w|66450fafd8|IMUL16rr:%R11W,%R11W,%R8W|rax=951a2fdfeaacffff rcx=ca7fbe10545c99f1 rdx=22 r8=b991c4f659c47921 r11=65d94ef6da04965e f=806|r11=65d94ef6da04d01e f=885/d4
  #|imul r11w, word ptr [rsp + 0x8]|66440faf5c2408|IMUL16rm:%R11W,%R11W,%RSP,1,%,8,%|rax=8000000000000000 rdx=c575168d8066ce51 rbx=4 r9=0 r11=fc95 f=83 m20108=c81155fa62063db59d52e9fe121b9517|r11=3968 f=801/d4
  #|imul r11w, word ptr [rsp + 0x8]|66440faf5c2408|IMUL16rm:%R11W,%R11W,%RSP,1,%,8,%|rcx=7fffffffffffffff rdx=5d142264cd64845d rbx=4 r9=0 r11=f7 f=812 m20108=617de7fb2c77e25a77d254a013244091|r11=f897 f=881/d4
  #|imul r11w, word ptr [rsp + 0x8]|66440faf5c2408|IMUL16rm:%R11W,%R11W,%RSP,1,%,8,%|rax=937fdbd7fdf9c1b8 rcx=bbe3a7b961ef4d8f rbx=f r9=e r11=fec3c51c4cc0b53 f=c7 m20108=9dedbb20eb80a59e87088c9afeb0899b|r11=fec3c51c4ccc8e7 f=885/d4
  #|imul r11w, r8w, -0x80|66456bd880|IMUL16rri8:%R11W,%R8W,-128|rax=6c3e486f63d49a0d rcx=e73b285410262bc1 rdx=56361ce894b8a1c4 r8=51b03a890093723e r11=2f54883330e8ce45 f=812|r11=2f54883330e8e100 f=885/d4
  #|imul r11w, r8w, -0x80|66456bd880|IMUL16rri8:%R11W,%R8W,-128|rax=dd0b4707fb248000 rdx=5f845f1b444c5b70 r8=db r11=7fffffffffffffff f=cd2|r11=7fffffffffff9280 f=480/d4
  #|imul r11w, r8w, -0x80|66456bd880|IMUL16rri8:%R11W,%R8W,-128|rax=8000000000000000 rcx=68d60cb3db973721 rdx=fffffffffffffffe r8=4a024d89340e96cf r11=fdc9a54bf7c742e f=cc6|r11=fdc9a54bf7c9880 f=c81/d4
  #|imul r11w, r8w, 0x7fff|664569d8ff7f|IMUL16rri:%R11W,%R8W,32767|rcx=7a10e236c3f3a084 rdx=66 r8=cd219d9c80000000 r11=f8284d5476adcb24 f=93|r11=f8284d5476ad0000 f=44/d4
  #|imul r11w, r8w, 0x7fff|664569d8ff7f|IMUL16rri:%R11W,%R8W,32767|rax=9d9607f5e755cf7 rdx=3710b989008b55b8 r8=c0 r11=99 f=807|r11=ff40 f=881/d4
  #|imul r11w, r8w, 0x7fff|664569d8ff7f|IMUL16rri:%R11W,%R8W,32767|rax=b2d223eb896fff49 rdx=9a5f35549089873e r8=ffffffffffffffff r11=7360b9c023afa627 f=47|r11=7360b9c023af8001 f=80/d4
  #|imul r11w, word ptr [rsp + 0x8], 0x11|66446b5c240811|IMUL16rmi8:%R11W,%RSP,1,%,8,%,17|rax=ff rbx=5 r9=c r11=14b598c3bc815003 f=53 m20108=9124e257559ab5b44f3550be9f6bdf0f|r11=14b598c3bc816da1 f=801/d4
  #|imul r11w, word ptr [rsp + 0x8], 0x11|66446b5c240811|IMUL16rmi8:%R11W,%RSP,1,%,8,%,17|rax=8f296912c9db85f0 rcx=2e rdx=dcbc8cd77a9307c6 rbx=5 r9=e r11=b546a0ec8452ffff f=887 m20108=2704a9aeef2b0f67e15aa61129d7f3a1|r11=b546a0ec84524697 f=0/d4
  #|mul r13d|41f7e5|MUL32r:%R13D|rax=e6e00f3731f5d1a1 rcx=1 r13=66 f=403|rax=e7f18626 rdx=13 f=c81/d4
  #|mul r13d|41f7e5|MUL32r:%R13D|rcx=ae06404813246932 r13=fffffffffffffffe f=8d7|rax=581cd096 rdx=d3f197b3 f=805/d4
  #|mul r13d|41f7e5|MUL32r:%R13D|rax=f8f8cd6fa3017fff r13=fffffffffffffffe f=856|rax=b9fd0002 rdx=a3017ffd f=881/d4
  #|mul r13d|41f7e5|MUL32r:%R13D|rcx=f703ed80e89884a rdx=2d9a335694226a2 r13=5ebd3fe3ffcdce6d f=8c2|rax=6ce23e11 rdx=d3c8097a f=805/d4
  #|mul dword ptr [rdi + r9*2 - 0x4]|42f7644ffc|MUL32m:%RDI,2,%R9,-4,%|rcx=30cae97f37cb7c6a rdx=b76cc9817749dbdf rbx=1 r9=a f=97 m10110=f697d4af6a8ad907969882bcaf1969be|rax=87878aee rdx=91922895 f=885/d4
  #|mul dword ptr [rdi + r9*2 - 0x4]|42f7644ffc|MUL32m:%RDI,2,%R9,-4,%|rax=e69ca4f3d425b517 rbx=2 r9=5 f=53 m10106=c637cc92c7f8fd699487bf43f311d2fd|rax=9b6600ca rdx=79a6bd8b f=885/d4
  #|mul dword ptr [rdi + r9*2 - 0x4]|42f7644ffc|MUL32m:%RDI,2,%R9,-4,%|rax=5 rcx=8b120b1b0f58ec64 rdx=f7a247d5f458eee2 rbx=8 r9=4 f=843 m10104=c01a8f227355ac52a19e30df62e8a94a|rax=accb85c0 rdx=0 f=84/d4
  #|imul r13d|41f7ed|IMUL32r:%R13D|rax=185a2e64cb7cff98 rcx=61568bb7a733a0d0 rdx=74b692b575cdc40a r13=40dfaa49d1cecc7f f=c07|rax=52ffec68 rdx=979a1b6 f=c01/d4
  #|imul r13d|41f7ed|IMUL32r:%R13D|rcx=7fffffffffffffff r13=ba f=812|rax=fd883982 rdx=ffffffdf f=885/d4
  #|imul r13d|41f7ed|IMUL32r:%R13D|rax=4936072fb02dd118 rcx=dfa0c847273448f4 r13=fffffffffffffffe f=4d6|rax=9fa45dd0 rdx=0 f=c81/d4
  #|imul r13d|41f7ed|IMUL32r:%R13D|rcx=b3218f8623843ab2 rdx=e29fd5b7e88f99f r13=f728edb5db05097d f=8d2|rax=c8d57061 rdx=65d3728 f=881/d4
  #|imul dword ptr [rsp + 0x8]|f76c2408|IMUL32m:%RSP,1,%,8,%|rcx=5b841ad0ff62e2c rdx=b1b77ef4a9adc726 rbx=d r9=b f=93 m20108=2024852f533db55e6e94a7df87736a9c|rax=83916aa0 rdx=f7d27126 f=885/d4
  #|imul dword ptr [rsp + 0x8]|f76c2408|IMUL32m:%RSP,1,%,8,%|rax=c3713b7412d736bc rcx=a45ec31cb853f686 rdx=8000000000000000 rbx=7 r9=4 f=812 m20108=7791db98dc2c37b2575e7165441a5188|rax=1adeed64 rdx=f868ba94 f=801/d4
  #|imul dword ptr [rsp + 0x8]|f76c2408|IMUL32m:%RSP,1,%,8,%|rax=8e66 rcx=f0049c5f7fffffff rdx=843e2575b86a3e43 rbx=4 r9=a f=46 m20108=24eb72de5f44019925fd45c9d5f71106|rax=6037a858 rdx=ffffed56 f=801/d4
  #|div ecx|f7f1|DIV32r:%ECX|rax=d9d8c522089f99e rcx=0 rdx=5872990e00000000 f=83|e=0 f=81/8d5
  #|div ecx|f7f1|DIV32r:%ECX|rax=cfea62151590bd6e rcx=264c5c3f97cbce63 rdx=df548b8c000000cf f=87|rax=15d rdx=24b86077 f=85/8d5
  #|div ecx|f7f1|DIV32r:%ECX|rax=388d9d0a2d13f28a rcx=3ac126437bfd642f rdx=c f=887|rax=19 rdx=115529f3 f=885/8d5
  #|div ecx|f7f1|DIV32r:%ECX|rax=4b47cf1d1408341b rcx=378e4e11 rdx=f2582dcf00000000 f=8d3|rax=0 rdx=1408341b f=8d1/8d5
  #|div ecx|f7f1|DIV32r:%ECX|rax=3 rcx=780e5eee00000007 rdx=0 f=cc2|rax=0 rdx=3 f=cc0/8d5
  #|div ecx|f7f1|DIV32r:%ECX|rcx=ba98a2fd2cc1e8f1 rdx=a7 f=403|rax=3bf rdx=2989f8e6 f=401/8d5
  #|div dword ptr [rdi + 0x10]|f77710|DIV32m:%RDI,1,%,16,%|rax=5a20a83572454fac rcx=ffff rdx=976dca0c00000000 rbx=9 r9=3 f=803 m10110=edc811f097984177156df5efc9ae6d1e|rax=0 rdx=72454fac f=801/8d5
  #|div dword ptr [rdi + 0x10]|f77710|DIV32m:%RDI,1,%,16,%|rcx=2499b5c080000000 rdx=b0 rbx=6 r9=f f=c17 m10110=708bdd83287206e3b77669233e9369ba|rax=157 rdx=261bc4a5 f=c15/8d5
  #|div dword ptr [rdi + 0x10]|f77710|DIV32m:%RDI,1,%,16,%|rax=a6263363efcf7b71 rcx=e5 rdx=0 rbx=8 r9=d f=c06 m10110=4bd6f463af3fa72ead0b9e93a7953715|rax=2 rdx=27e5cedb f=c04/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=e7e7 rcx=3a3e1b8df635a551 rdx=87 f=7|rax=fffff237 rdx=984d180 f=5/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=9e68ef044b08e394 rcx=6dd221f997d1c481 rdx=5a982660ffffffff f=2|rax=1 rdx=b3371f13 f=0/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=8efb39d84a4ae900 rcx=ffffffffc3d554b3 rdx=a34b85dc000000c7 f=c6|rax=fffffcb1 rdx=391e253d f=c4/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=ea8603fa8520b3b1 rcx=2622c2ce0cbc2477 rdx=4f95f4f00000003f f=2|rax=4fc rdx=b5af28d f=0/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=282e78e315f75ecd rcx=3 rdx=0 f=446|rax=75274ef f=444/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|rax=630b3602853c521c rcx=c13cd320acf0735b rdx=0 f=cd6|rax=ffffffff rdx=322cc577 f=cd4/8d5
  #|idiv dword ptr [rdi + 0x10]|f77f10|IDIV32m:%RDI,1,%,16,%|rax=8bb19941a9d4e983 rcx=23 rdx=ffffffff rbx=0 r9=3 f=8d2 m10110=4ddb0bfc8f169e4f90d1077aabca57b1|rax=15 rdx=fcdbec32 f=8d0/8d5
  #|idiv dword ptr [rdi + 0x10]|f77f10|IDIV32m:%RDI,1,%,16,%|rax=1 rcx=452669e280daffff rdx=ffffffff rbx=6 r9=3 f=96 m10110=39f1a07e555f7d8e93307bfa19ffd59f|rax=fffffffe rdx=fd41e273 f=94/8d5
  #|idiv dword ptr [rdi + 0x10]|f77f10|IDIV32m:%RDI,1,%,16,%|rax=522a5ca2d98cb759 rcx=27f51a989ef1277f rdx=e6659ba946799b5c rbx=3 r9=5 f=812 m10110=21a4663661a914068db322374d7d7583|e=0 f=810/8d5
  #|imul r14d, r10d|450faff2|IMUL32rr:%R14D,%R14D,%R10D|rax=3 rdx=3181d28be8b68693 r10=5488a42246dacde2 r14=8092cc925533aeff f=402|r14=59e8b01e f=c05/d4
  #|imul r14d, r10d|450faff2|IMUL32rr:%R14D,%R14D,%R10D|rax=8000000000000000 rcx=ff rdx=e314666add298a2d r10=fe r14=dc767dc8f15f6dfc f=53|r14=7caf2008 f=801/d4
  #|imul r14d, r10d|450faff2|IMUL32rr:%R14D,%R14D,%R10D|rax=dbb0 rcx=9ea30666c0d69ca rdx=6fd6b12567a71d4 r10=fffffffffffffffe r14=187544f4a2d6cf91 f=812|r14=ba5260de f=885/d4
  #|imul r14d, r10d|450faff2|IMUL32rr:%R14D,%R14D,%R10D|rax=60fed4a729a52900 rcx=c97196992fd520cb rdx=2dc10d21f0f188d2 r10=e6a4eccc9c1d776d r14=6b4634f82b3b58ff f=16|r14=77866d93 f=805/d4
  #|imul r14d, dword ptr [rdi + r9*2 - 0x4]|460faf744ffc|IMUL32rm:%R14D,%R14D,%RDI,2,%R9,-4,%|rax=76531b5d85628df0 rcx=97 rbx=e r9=f r14=40f3143845453eff f=892 m1011a=f82380847322e38048d3b1b6bb2c9834|r14=8e31e408 f=881/d4
  #|imul r14d, dword ptr [rdi + r9*2 - 0x4]|460faf744ffc|IMUL32rm:%R14D,%R14D,%RDI,2,%R9,-4,%|rax=20 rcx=b559d0b2e54009d rbx=9 r9=c r14=3da9f04c0ae7a903 f=c6 m10114=46a4e7becc13e99d20ea910e1360689c|r14=1f5322d2 f=805/d4
  #|imul r14d, dword ptr [rdi + r9*2 - 0x4]|460faf744ffc|IMUL32rm:%R14D,%R14D,%RDI,2,%R9,-4,%|rax=e4aa683ad2800bda rcx=215979e383b68000 rbx=1 r9=1 r14=addb507dc9770fb1 f=13 m100fe=59677aa1af0b567c5554e87ef971f450|r14=bd0eab89 f=881/d4
  #|imul r14d, r10d, 0x3|456bf203|IMUL32rri8:%R14D,%R10D,3|rax=34c8583bcfe768c1 rcx=8b659288125ef2c3 r10=4875a0bfbd31e903 r14=d9956d67dcd84723 f=897|r14=3795bb09 f=805/d4
  #|imul r14d, r10d, 0x3|456bf203|IMUL32rri8:%R14D,%R10D,3|rax=7 rcx=4a rdx=c r10=c254a347704b998c r14=b5df424330b4bc2f f=87|r14=50e2cca4 f=801/d4
  #|imul r14d, r10d, 0x3|456bf203|IMUL32rri8:%R14D,%R10D,3|rdx=dcce6adfd819a2ab r10=80 r14=5474c49b7087f23b f=8d6|r14=180 f=0/d4
  #|imul r14d, r10d, -0x80000000|4569f200000080|IMUL32rri:%R14D,%R10D,2147483648|rax=ebb26856096879e6 rcx=a0b1ed553ff51eff rdx=9e55f6957660aeb2 r10=8000 r14=9b475fdb3379eeff f=c82|r14=0 f=c45/d4
  #|imul r14d, r10d, -0x80000000|4569f200000080|IMUL32rri:%R14D,%R10D,2147483648|rcx=432475061c988501 rdx=2 r10=43c61a3cfe256957 r14=6feb281e9d2b839d f=c2|r14=80000000 f=885/d4
  #|imul r14d, r10d, -0x80000000|4569f200000080|IMUL32rri:%R14D,%R10D,2147483648|rax=ffffffff rcx=9170dfc1014c3d38 rdx=100 r10=73e9233bb7be9e9d r14=f f=852|r14=80000000 f=885/d4
  #|imul r14d, dword ptr [rdi + r9*2 - 0x4], 0x11|466b744ffc11|IMUL32rmi8:%R14D,%RDI,2,%R9,-4,%,17|rax=b17bc2c37d0722b9 rdx=d050f80fe1f0a303 rbx=5 r9=8 r14=bb3eaf3f5bbc4daa f=802 m1010c=e2e1c69ac65a375afe59fd91fcb8f2c7|r14=47350002 f=801/d4
  #|imul r14d, dword ptr [rdi + r9*2 - 0x4], 0x11|466b744ffc11|IMUL32rmi8:%R14D,%RDI,2,%R9,-4,%,17|rax=4f33cd99b89a2468 rcx=80000000 rbx=8 r9=b r14=97e44e1d7d89355f f=82 m10112=4cf16f4d7959b3335f0bc10c5d078898|r14=246f060c f=805/d4
  #|mul r13|49f7e5|MUL64r:%R13|rcx=4b539618e68cc835 rdx=50c29fb9dc3b3ed5 r13=8000 f=843|rax=8f9ee9f8cbda8000 rdx=2dbc f=885/d4
  #|mul r13|49f7e5|MUL64r:%R13|rcx=1767d048458558b4 rdx=b941aba6c1039d9 r13=fffffffffffffffe f=56|rax=490dc184581cd096 rdx=5b791f3dd3f197b4 f=805/d4
  #|mul r13|49f7e5|MUL64r:%R13|rax=bbe8 rcx=ed40e63f62640c9d rdx=552fa571aa987fff r13=1 f=17|rdx=0 f=4/d4
  #|mul r13|49f7e5|MUL64r:%R13|rax=80000000 rdx=f87422a860298c64 r13=399468feffde9931 f=d7|rax=7fef4c9880000000 rdx=1cca347f f=805/d4
  #|mul qword ptr [rsp + 0x8]|48f7642408|MUL64m:%RSP,1,%,8,%|rax=3fd7beaf91d7abbd rbx=c r9=5 f=96 m20108=506c46f1f271470630d7b3c782a8bb7e|rax=844557b472876710 rdx=190dfb8d165ecb3 f=881/d4
  #|mul qword ptr [rsp + 0x8]|48f7642408|MUL64m:%RSP,1,%,8,%|rax=41bcae0fbac7258d rdx=84 rbx=d r9=7 f=846 m20108=16ffaca538f60820cf549b3f961452fd|rax=b39a2e3f8740ad1e rdx=839e2e142eaf44c f=885/d4
  #|mul qword ptr [rsp + 0x8]|48f7642408|MUL64m:%RSP,1,%,8,%|rcx=c61b25a01295d2fc rdx=9ef72f1983be8c40 rbx=0 r9=1 f=843 m20108=aaffa94b6805f50b203e933edcca6a14|rax=eacb31a392090932 rdx=445c13130215873 f=881/d4
  #|imul rbx|48f7eb|IMUL64r:%RBX|rcx=b992707546bbd0c6 rdx=850a3b49ecd27fff rbx=bb5c2373f54a2427 f=d6|rax=24ded38e56759093 rdx=e77946c68e6bf283 f=805/d4
  #|imul rbx|48f7eb|IMUL64r:%RBX|rax=ce3ef8b7185b914b rcx=d2c2fde880000000 rdx=6e rbx=887552ec2a35a5f3 f=c2|rax=ec36206e86174131 rdx=173bae141dc70bec f=881/d4
  #|imul rbx|48f7eb|IMUL64r:%RBX|rcx=75 rdx=744cdde78cba181b rbx=f434460c64c65bee f=d3|rax=bce4ec6bf5866146 rdx=fbc9002afeda498b f=881/d4
  #|imul rbx|48f7eb|IMUL64r:%RBX|rax=8000 rcx=8b3403cd13a7b1d5 rdx=28cca082eb812e71 rbx=17ad7fb413776427 f=cc7|rax=bfda09bbb2138000 rdx=bd6 f=c85/d4
  #|imul qword ptr [rbp - 0x20]|48f76de0|IMUL64m:%RBP,1,%,-32,%|rax=269726eba6acb4bc rcx=b6d2fd88c394ecd rdx=7fffffffffffffff rbx=2 r9=5 f=46 m20160=b7e6c13f98dca82c1796aba8343ccfe5|rax=5ee9281d5921a64 rdx=6bb6f22e4191cde f=801/d4
  #|imul qword ptr [rbp - 0x20]|48f76de0|IMUL64m:%RBP,1,%,-32,%|rbx=0 r9=2 f=803 m20160=35e6f98884a9ed8007c5c2ae069cab83|rax=b62a3920a65e0679 rdx=d2985c155349fb44 f=881/d4
  #|imul qword ptr [rbp - 0x20]|48f76de0|IMUL64m:%RBP,1,%,-32,%|rax=6 rdx=a4ca7c5e9ed99d83 rbx=8 r9=9 f=c87 m20160=42b2b76a1c9eac2264057157b051ef62|rax=d00bb4aa804e2d8c rdx=0 f=c81/d4
  #|div r8|49f7f0|DIV64r:%R8|rax=de69aa9d8a661f24 rcx=a92e234a919cc210 rdx=0 r8=92edaa265fcc7383 f=8c7|rax=1 rdx=4b7c00772a99aba1 f=8c5/8d5
  #|div r8|49f7f0|DIV64r:%R8|rax=1c8dfafda71471fd rcx=68664d1a47331388 rdx=0 r8=25d2f8c31472d755 f=c3|rax=0 rdx=1c8dfafda71471fd f=c1/8d5
  #|div r8|49f7f0|DIV64r:%R8|rcx=6 rdx=0 r8=1b9f082d10cfbf91 f=802|rax=3 rdx=89c06b6a1825902 f=800/8d5
  #|div r8|49f7f0|DIV64r:%R8|rdx=c3196811ae7b9717 r8=3b6d395f8bec79a5 f=806|e=0 f=804/8d5
  #|div r8|49f7f0|DIV64r:%R8|rcx=88c29d37cc43f87b rdx=0 r8=bf239f26f76b1d2f f=96|rax=0 rdx=5b791f3dd3f197b5 f=94/8d5
  #|div r8|49f7f0|DIV64r:%R8|rax=32e62879045364db rcx=bb5064904de779bf rdx=e84d r8=279c46c1e5d0de79 f=896|rax=5dd59 rdx=22b2ae96764a97ca f=894/8d5
  #|div qword ptr [rdi + 0x10]|48f77710|DIV64m:%RDI,1,%,16,%|rax=ff rcx=a7437c55ff5caf25 rdx=0 rbx=a r9=2 f=2 m10110=55d0efd7c0d96d6c22482f530f890042|rax=0 rdx=ff f=0/8d5
  #|div qword ptr [rdi + 0x10]|48f77710|DIV64m:%RDI,1,%,16,%|rdx=e0f9 rbx=2 r9=a f=43 m10110=20dc8950082607d3a442a142d489c497|rax=110eb rdx=b8060096b828655 f=41/8d5
  #|div qword ptr [rdi + 0x10]|48f77710|DIV64m:%RDI,1,%,16,%|rax=6900e619447f8fd5 rdx=ce86 rbx=f r9=f f=cd7 m10110=705be358b73667c7764d78aef6f8fbe5|rax=10924 rdx=86d9694d6adfc415 f=cd5/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rax=b74dc0e304b8aaff rdx=0 r8=0 f=893|e=0 f=891/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rax=f rdx=ffffffffffffffff r8=66ff646feb00b5f5 f=d2|rax=fffffffffffffffe rdx=cdfec8dfd6016bf9 f=d0/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rax=5088e9f9b4370b85 rcx=bf320bc6c259e5cd rdx=ffffffffffffffff r8=49269cb64e365533 f=c82|rax=fffffffffffffffe rdx=e2d6236650a3b5eb f=c80/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rcx=4e64cc38938ebd0b rdx=ba1aed21f2de819f r8=e6201511ea007a63 f=82|e=0 f=80/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rcx=ffffffffffffffff rdx=3a52 r8=f436975cd285f8cf f=853|rax=fffffffffffb0d4c rdx=a64959c62943741 f=851/8d5
  #|idiv r8|49f7f8|IDIV64r:%R8|rcx=a933894e28ab62c1 rdx=8aa2379e7f6abed9 r8=951ad4ab1405081d f=896|e=0 f=894/8d5
  #|idiv qword ptr [rsi]|48f73e|IDIV64m:%RSI,1,%,0,%|rax=59791c1e76d52070 rcx=c2b77b8fc62883c2 rdx=bea79bd518d034ae rbx=6 r9=0 f=4d6 m10080=fc023f1c0191c1e31fea7ce17f34d7ad|e=0 f=4d4/8d5
  #|idiv qword ptr [rsi]|48f73e|IDIV64m:%RSI,1,%,0,%|rax=56f2ad7d67d958c5 rcx=a02dcbbbaf076273 rdx=ffffffffffffffff rbx=9 r9=3 f=52 m10080=5e3af20013ea8e6945fb59003e67fa86|rax=ffffffffffffffff rdx=c081979068cb9323 f=50/8d5
  #|idiv qword ptr [rsi]|48f73e|IDIV64m:%RSI,1,%,0,%|rax=96d43cf6e02322e9 rdx=9da1 rbx=3 r9=f f=16 m10080=a333df228103f096cc4e2b6b14481bd4|rax=fffffffffffe7fe9 rdx=2ba641dfcfa5468e f=14/8d5
  #|imul r10, r11|4d0fafd3|IMUL64rr:%R10,%R10,%R11|rax=182a4e65fa108230 r10=21fef83ba6778284 r11=8438c5c6f6a41aa7 f=843|r10=bf75ffe42fc78c1c f=881/d4
  #|imul r10, r11|4d0fafd3|IMUL64rr:%R10,%R10,%R11|rax=a4e9 rdx=8000000000000000 r10=c1971e3081814365 r11=3ec6039c84111e2c f=47|r10=42f6064f5d26b5c f=805/d4
  #|imul r10, r11|4d0fafd3|IMUL64rr:%R10,%R10,%R11|rcx=59e88bf6bd14dff3 r10=5117cb6b564ec570 r11=9c34ccc4c5e71bb4 f=92|r10=e2d942565645a2c0 f=885/d4
  #|imul r10, r11|4d0fafd3|IMUL64rr:%R10,%R10,%R11|rax=222f0002fdf33611 rcx=ce3449aa4ef97fff rdx=5fc6ae564a563be0 r10=9 r11=dc2f f=7|r10=7bda7 f=0/d4
  #|imul r10, qword ptr [rbp - 0x20]|4c0faf55e0|IMUL64rm:%R10,%R10,%RBP,1,%,-32,%|rcx=c025cc09d84ce3fd rdx=53342e9d5dffa340 rbx=7 r9=4 r10=e92dc0d24894ac29 f=487 m20160=3970cb0622bad1ea94112cf63ee627f5|r10=744c9ff2aeef4521 f=c05/d4
  #|imul r10, qword ptr [rbp - 0x20]|4c0faf55e0|IMUL64rm:%R10,%R10,%RBP,1,%,-32,%|rax=8e69598c957204a5 rcx=4e4324ce4e79862e rdx=3853f216e9641827 rbx=6 r9=9 r10=de8fe0af40b35330 f=c02 m20160=d425c4b64e5394487dc3361efaa7cf30|r10=2b28548b5046d3c0 f=c05/d4
  #|imul r10, qword ptr [rbp - 0x20]|4c0faf55e0|IMUL64rm:%R10,%R10,%RBP,1,%,-32,%|rdx=8000000000000000 rbx=b r9=d r10=15f0d1ad2563b3f6 f=c3 m20160=ba72cb8a5111d1108e63d4eda3f880af|r10=88211e5be0a64cbc f=881/d4
  #|imul r10, r11, 0x3|4d6bd303|IMUL64rri8:%R10,%R11,3|rax=a rcx=1fb146325c820113 rdx=1 r10=70a63a970d7357b r11=155e1a42d9ae93c1 f=13|r10=401a4ec88d0bbb43 f=0/d4
  #|imul r10, r11, 0x3|4d6bd303|IMUL64rri8:%R10,%R11,3|rcx=ab8a830b0913a012 r10=daaea5ba714c7fff r11=ff f=92|r10=2fd f=0/d4
  #|imul r10, r11, 0x3|4d6bd303|IMUL64rri8:%R10,%R11,3|rax=583131073caba605 rcx=16a51ffeb8382a2b rdx=64b073ac0782722 r10=c9d9 r11=b80f0dbf0545428e f=816|r10=282d293d0fcfc7aa f=805/d4
  #|imul r10, r11, 0x100|4d69d300010000|IMUL64rri32:%R10,%R11,256|rax=9de3a40fe9d53eb8 rcx=7f rdx=5b72a2d141bd5a2d r10=98600191cd47e952 r11=9137e3ce71fe6b48 f=2|r10=37e3ce71fe6b4800 f=805/d4
  #|imul r10, r11, 0x100|4d69d300010000|IMUL64rri32:%R10,%R11,256|rax=f6c0db5c5987fff rdx=fffffffffffffffe r10=a2fdcb9a9141c2dd r11=7fffffffffffffff f=8c3|r10=ffffffffffffff00 f=885/d4
  #|imul r10, r11, 0x100|4d69d300010000|IMUL64rri32:%R10,%R11,256|rax=bd61fbd7d70fd6b8 rcx=242f6070306e12da r10=9eafb23996ddd064 r11=267af003dcfa7b26 f=2|r10=7af003dcfa7b2600 f=805/d4
  #|imul r10, qword ptr [rbp - 0x20], 0x11|4c6b55e011|IMUL64rmi8:%R10,%RBP,1,%,-32,%,17|rax=8000000000000000 rcx=7fffffffffffffff rdx=fbda3c7d5f842f6d rbx=8 r9=8 r10=f6bdd69cb59cc82 f=887 m20160=8443113e48106f42b5ccb2bd5b18a2e8|r10=696014cc1f257bc4 f=801/d4
  #|imul r10, qword ptr [rbp - 0x20], 0x11|4c6b55e011|IMUL64rmi8:%R10,%RBP,1,%,-32,%,17|rax=f rcx=2d99 rdx=ffffffffffffffff rbx=4 r9=2 r10=ebe779e46ede7986 f=842 m20160=de62a08a851b69409ee63530843e12fc|r10=46fad3de34a690be f=805/d4

///|
let muldiv32_cases : String =
  #|mul bl|f6e3|MUL8r:%BL|ecx=17bebb1a edx=e189d7cd ebx=172c5355 f=6|eax=d3f13c19 f=801/d4
  #|mul bl|f6e3|MUL8r:%BL|eax=66431b4c edx=ffffffff ebx=9eb15480 f=8d6|eax=66432600 f=845/d4
  #|mul bl|f6e3|MUL8r:%BL|eax=80dfabc1 ecx=8 edx=79cf0ae1 ebx=2907338 f=d3|eax=80df2a38 f=801/d4
  #|mul bl|f6e3|MUL8r:%BL|eax=4406 ecx=c57e552f ebx=719735fa f=882|eax=5dc f=881/d4
  #|mul byte ptr [edi + 0x10]|f66710|MUL8m:%EDI,1,%,16,%|eax=2ae87a7f ecx=3afc382 edx=d672 ebx=1 f=c47 m10110=ab0c5ec10c7440d011e4eb71cb5a647f|eax=2ae854d5 f=c81/d4
  #|mul byte ptr [edi + 0x10]|f66710|MUL8m:%EDI,1,%,16,%|eax=726e ecx=35d73939 ebx=b f=812 m10110=c49f54d6fa6dcc2085e4159b81c9d6be|eax=5438 f=801/d4
  #|mul byte ptr [edi + 0x10]|f66710|MUL8m:%EDI,1,%,16,%|eax=7a523556 edx=7af6cf8d ebx=c f=13 m10110=e6e8eb8c93f1eb6038e32d70085dc344|eax=7a524d44 f=805/d4
  #|imul bl|f6eb|IMUL8r:%BL|eax=e070c2b5 ecx=f82831b9 ebx=3d61c3f1 f=87|eax=e0700465 f=805/d4
  #|imul bl|f6eb|IMUL8r:%BL|eax=4ddcffff ecx=60179730 edx=b ebx=a349396d f=817|eax=4ddcff93 f=84/d4
  #|imul bl|f6eb|IMUL8r:%BL|eax=ff ecx=189561e9 ebx=5f05b8d5 f=883|eax=2b f=4/d4
  #|imul bl|f6eb|IMUL8r:%BL|eax=9c81c7e7 ecx=d648c805 edx=eb7a2f42 ebx=c37e4a1d f=4c6|eax=9c81fd2b f=c05/d4
  #|imul byte ptr [esi]|f62e|IMUL8m:%ESI,1,%,0,%|eax=5ad1bb01 edx=f74e5b94 ebx=e f=493 m10080=b05f73dbfd71501765623fea5654bdbd|eax=5ad1ffb0 f=480/d4
  #|imul byte ptr [esi]|f62e|IMUL8m:%ESI,1,%,0,%|edx=4809de74 ebx=3 f=7 m10080=cef13959157f4ca329c7e3f65f0c53e5|eax=d3f10ea6 f=885/d4
  #|imul byte ptr [esi]|f62e|IMUL8m:%ESI,1,%,0,%|ecx=8d74bbc1 edx=0 ebx=1 f=856 m10080=971bd9ba4c30eff83f2d012c18a77e73|eax=d3f11ec3 f=885/d4
  #|div bl|f6f3|DIV8r:%BL|eax=39c30045 edx=0 ebx=f507 f=cc6|eax=39c30609 f=cc4/8d5
  #|div bl|f6f3|DIV8r:%BL|eax=4d ecx=b edx=3a3de607 ebx=89 f=887|eax=4d00 f=885/8d5
  #|div bl|f6f3|DIV8r:%BL|eax=e8f9 ebx=f4da123f f=17|e=0 f=15/8d5
  #|div bl|f6f3|DIV8r:%BL|eax=2f ecx=c402 edx=4b22f40d ebx=f357 f=847|eax=2f00 f=845/8d5
  #|div bl|f6f3|DIV8r:%BL|eax=13110038 ecx=b edx=ffffffff ebx=f53cfff7 f=56|eax=13113800 f=54/8d5
  #|div bl|f6f3|DIV8r:%BL|eax=d6 edx=1 ebx=b8831100 f=56|e=0 f=54/8d5
  #|div byte ptr [esi]|f636|DIV8m:%ESI,1,%,0,%|eax=2696008c ecx=5513af60 ebx=c f=c47 m10080=61e9b9d8230791fee3978364b751b845|eax=26962b01 f=c45/8d5
  #|div byte ptr [esi]|f636|DIV8m:%ESI,1,%,0,%|eax=7c ecx=1 edx=e718e59 ebx=e f=c2 m10080=04582faabe97f2e9fc84ced080b6c7a3|eax=1f f=c0/8d5
  #|div byte ptr [esi]|f636|DIV8m:%ESI,1,%,0,%|eax=fe ecx=9a009401 edx=ffff ebx=1 f=6 m10080=b4dc97bab451a477eadf42121abf5a7a|eax=4a01 f=4/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=42fa00f4 ecx=8bcc5159 edx=f40d9d58 f=d2|eax=42fa4202 f=d0/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=ffff0095 ecx=7ee6d001 f=817|e=0 f=815/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=92df ecx=76f60ee5 edx=80 f=46|e=0 f=44/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=bdafa55c ecx=6b628e1d edx=f395d227 f=457|e=0 f=455/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=800000fc ecx=a3 edx=50e649b f=883|eax=800042fe f=881/8d5
  #|idiv cl|f6f9|IDIV8r:%CL|eax=4aca000c ecx=eef5351d edx=b f=842|eax=4aca0c00 f=840/8d5
  #|idiv byte ptr [esi + ebx*4 + 0x8]|f67c9e08|IDIV8m:%ESI,4,%EBX,8,%|eax=a900086 ecx=e3 edx=3ab0fa5d ebx=8 f=8d3 m100a8=b6c766045c2794ea5ca7874081a8b756|eax=a903cff f=8d1/8d5
  #|idiv byte ptr [esi + ebx*4 + 0x8]|f67c9e08|IDIV8m:%ESI,4,%EBX,8,%|eax=8b710059 ecx=1478d858 ebx=b f=487 m100b4=88b938a96280c33f980a71e6927d5995|eax=8b715900 f=485/8d5
  #|idiv byte ptr [esi + ebx*4 + 0x8]|f67c9e08|IDIV8m:%ESI,4,%EBX,8,%|eax=fd ecx=7071 edx=0 ebx=2 f=c13 m10090=cb814e124a1e08deb8c4974db6291ea6|eax=29fc f=c11/8d5
  #|mul cx|66f7e1|MUL16r:%CX|ecx=f14b3735 edx=94c938ba f=93|eax=d3f14b79 edx=94c920b7 f=801/d4
  #|mul cx|66f7e1|MUL16r:%CX|eax=34f3761f ecx=269f3b72 edx=b f=cc2|eax=34f3bece edx=1b6d f=c81/d4
  #|mul cx|66f7e1|MUL16r:%CX|eax=ffffffff ecx=70eef7a8 edx=ffffffff f=42|eax=ffff0858 edx=fffff7a7 f=801/d4
  #|mul cx|66f7e1|MUL16r:%CX|eax=b5900747 ecx=95 edx=17dc95e4 f=97|eax=b5903c53 edx=17dc0004 f=805/d4
  #|mul word ptr [ebp - 0x20]|66f765e0|MUL16m:%EBP,1,%,-32,%|ecx=4dc650ed edx=eb784d1 ebx=5 f=487 m20160=8f3bce40e17a75719968e658ddad1bb8|eax=d3f1751b edx=eb7234b f=c05/d4
  #|mul word ptr [ebp - 0x20]|66f765e0|MUL16m:%EBP,1,%,-32,%|eax=8b894952 ecx=fd5b1ca edx=73db1a50 ebx=c f=c2 m20160=cfff28c02edec3f47dfe87ec0074e992|eax=8b89f74e edx=73db4943 f=885/d4
  #|mul word ptr [ebp - 0x20]|66f765e0|MUL16m:%EBP,1,%,-32,%|eax=ffffffff ecx=8973fe5f edx=2187b4d0 ebx=6 f=c43 m20160=91ccd739e04128e09e997e11e5a4f4db|eax=ffff336f edx=2187cc90 f=c05/d4
  #|imul cx|66f7e9|IMUL16r:%CX|ecx=a8355cdd edx=33c2 f=16|eax=d3f10341 edx=da2b f=805/d4
  #|imul cx|66f7e9|IMUL16r:%CX|eax=6d ecx=b265d73f edx=17f07a1f f=806|eax=a5d3 edx=17f0ffee f=881/d4
  #|imul cx|66f7e9|IMUL16r:%CX|eax=8447e16b ecx=43d53273 edx=f60aae4b f=17|eax=84472911 edx=f60af9f9 f=805/d4
  #|imul cx|66f7e9|IMUL16r:%CX|eax=2 ecx=f0f1cda edx=27bbc513 f=92|eax=39b4 edx=27bb0000 f=4/d4
  #|imul word ptr [ebp - 0x20]|66f76de0|IMUL16m:%EBP,1,%,-32,%|ecx=1c8e edx=ffffffff ebx=4 f=d7 m20160=5a4dbc766bc193ab214f8443bb33987b|eax=d3f1c6a2 edx=ffffe07c f=881/d4
  #|imul word ptr [ebp - 0x20]|66f76de0|IMUL16m:%EBP,1,%,-32,%|ecx=b1bd6842 ebx=7 f=43 m20160=99f730e101466cf694a89122cafbf3cd|eax=d3f14e2d edx=c759036c f=805/d4
  #|imul word ptr [ebp - 0x20]|66f76de0|IMUL16m:%EBP,1,%,-32,%|eax=89ed097d ecx=9ee8 edx=ca23aeb4 ebx=8 f=883 m20160=ae27471a2c1140d3b31fe9a2c5a86f68|eax=89ed7df6 edx=ca230178 f=805/d4
  #|div cx|66f7f1|DIV16r:%CX|eax=4af3 ecx=2d1c81 edx=0 f=496|eax=2 edx=11f1 f=494/8d5
  #|div cx|66f7f1|DIV16r:%CX|eax=e ecx=3 edx=a f=42|e=0 f=40/8d5
  #|div cx|66f7f1|DIV16r:%CX|eax=d1950e96 ecx=6b890007 edx=f f=93|e=0 f=91/8d5
  #|div cx|66f7f1|DIV16r:%CX|ecx=d5608553 edx=76e40006 f=83|eax=d3f1000c edx=76e457d1 f=81/8d5
  #|div cx|66f7f1|DIV16r:%CX|ecx=4f5f0007 edx=0 f=8c7|eax=d3f115ac edx=1 f=8c5/8d5
  #|div cx|66f7f1|DIV16r:%CX|eax=bbdbee6d ecx=636f0000 edx=184d0003 f=806|e=0 f=804/8d5
  #|div word ptr [esi]|66f736|DIV16m:%ESI,1,%,0,%|eax=154adbd3 ecx=80c0d3f4 edx=0 ebx=1 f=cc3 m10080=9a9c0d80fe7a6b5741e7bfc4644f6df3|eax=154a0001 edx=3f39 f=cc1/8d5
  #|div word ptr [esi]|66f736|DIV16m:%ESI,1,%,0,%|ecx=776d99c3 edx=0 ebx=c f=6 m10080=8b93b3a2bcee09d495a5b327a064017c|eax=d3f10001 edx=42a f=4/8d5
  #|div word ptr [esi]|66f736|DIV16m:%ESI,1,%,0,%|ecx=6894a90 edx=0 ebx=6 f=4d7 m10080=071970f4bf4eed19f7203bd65add137d|eax=d3f10006 edx=18b f=4d5/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|eax=8489da8c ecx=75c8584f edx=c ebx=e7ecf9b7 f=806|eax=8489fdf5 edx=369 f=804/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|edx=0 ebx=b46e8000 f=c7|eax=d3f1ffff edx=17b5 f=c5/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|ecx=fffffffe edx=0 ebx=ffffbc23 f=43|eax=d3f1fffe edx=ffb f=41/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|eax=c2467422 ecx=1fdb3965 edx=cc510000 ebx=9f5cf1eb f=86|eax=c246fff8 edx=cc51037a f=84/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|eax=2b74be9b edx=a711ffff ebx=f3c50000 f=c6|e=0 f=c4/8d5
  #|idiv bx|66f7fb|IDIV16r:%BX|edx=821dffff ebx=1 f=17|edx=821d0000 f=15/8d5
  #|idiv word ptr [esi + ebx*4 + 0x8]|66f77c9e08|IDIV16m:%ESI,4,%EBX,8,%|eax=a1b279cc ecx=576e895a edx=ffff ebx=5 f=16 m1009c=ec25b6f6f927568034ca75b70aa5e17e|eax=a1b2fffd edx=eb90 f=14/8d5
  #|idiv word ptr [esi + ebx*4 + 0x8]|66f77c9e08|IDIV16m:%ESI,4,%EBX,8,%|eax=40d5b0f2 ecx=80000000 edx=ffff ebx=3 f=852 m10094=82c633de59c64946a36c62bfd241e355|eax=40d50001 edx=ea70 f=850/8d5
  #|idiv word ptr [esi + ebx*4 + 0x8]|66f77c9e08|IDIV16m:%ESI,4,%EBX,8,%|eax=8660c8af edx=ac8a0000 ebx=f f=46 m100c4=47f934c5aa6bbd091ba4a668429ec769|eax=8660ffe3 edx=ac8a05ba f=44/8d5
  #|imul bx, dx|660fafda|IMUL16rr:%BX,%BX,%DX|eax=6e65af9e edx=e595a8dd ebx=1af6a9f1 f=c2|ebx=1af6dd0d f=881/d4
  #|imul bx, dx|660fafda|IMUL16rr:%BX,%BX,%DX|eax=ddefd0d3 edx=af53e3a7 ebx=f01cd8a7 f=87|ebx=f01c69f1 f=801/d4
  #|imul bx, dx|660fafda|IMUL16rr:%BX,%BX,%DX|eax=6f490008 ecx=c5b9 edx=f ebx=ddb080c7 f=8d7|ebx=ddb08ba9 f=885/d4
  #|imul bx, dx|660fafda|IMUL16rr:%BX,%BX,%DX|eax=1aea953 edx=d0a10ffc ebx=ffffffff f=c03|ebx=fffff004 f=480/d4
  #|imul bx, word ptr [esi]|660faf1e|IMUL16rm:%BX,%BX,%ESI,1,%,0,%|eax=ffffffff ecx=aff930a edx=abbc3f00 ebx=3 f=46 m10080=cf898466c2bc553f129df7558dfa7ff0|ebx=9d6d f=881/d4
  #|imul bx, word ptr [esi]|660faf1e|IMUL16rm:%BX,%BX,%ESI,1,%,0,%|ecx=c86aadf1 edx=41fb09b7 ebx=e f=806 m10080=76cbd8d3bc6f2a1ec869fdc671181a8b|ebx=2074 f=805/d4
  #|imul bx, word ptr [esi]|660faf1e|IMUL16rm:%BX,%BX,%ESI,1,%,0,%|eax=c7c30dda ebx=5 f=87 m10080=06eca76e856f187daca803088692ac62|ebx=9c1e f=84/d4
  #|imul bx, dx, -0x2|666bdafe|IMUL16rri8:%BX,%DX,-2|eax=1ebc28fc ecx=74 edx=c12a7cd6 ebx=ffffffff f=456|ebx=ffff0654 f=c01/d4
  #|imul bx, dx, -0x2|666bdafe|IMUL16rri8:%BX,%DX,-2|eax=6755de68 edx=19061d4a ebx=5e2a6788 f=c03|ebx=5e2ac56c f=484/d4
  #|imul bx, dx, -0x2|666bdafe|IMUL16rri8:%BX,%DX,-2|eax=ff ecx=7e7b edx=0 ebx=ebd3769e f=842|ebx=ebd30000 f=44/d4
  #|imul bx, dx, 0x100|6669da0001|IMUL16rri:%BX,%DX,256|eax=46d8ac0b ecx=d32cffff edx=c002dccc ebx=8 f=86|ebx=cc00 f=885/d4
  #|imul bx, dx, 0x100|6669da0001|IMUL16rri:%BX,%DX,256|ecx=1540ffff edx=f97af8a ebx=0 f=13|ebx=8a00 f=885/d4
  #|imul bx, dx, 0x100|6669da0001|IMUL16rri:%BX,%DX,256|eax=169dfde8 ecx=6be1b3a6 edx=c34fd1d2 ebx=6909ca03 f=96|ebx=6909d200 f=885/d4
  #|imul bx, word ptr [esi], 0x11|666b1e11|IMUL16rmi8:%BX,%ESI,1,%,0,%,17|eax=6bedc47 edx=bfaaffff ebx=8 f=6 m10080=2a9a7fcde58f3b290f8ce92c1caf4525|ebx=3cca f=805/d4
  #|imul bx, word ptr [esi], 0x11|666b1e11|IMUL16rmi8:%BX,%ESI,1,%,0,%,17|eax=2d32ffff ecx=12 ebx=9 f=d7 m10080=9c43388cba5dff07cf8e87207fbc0355|ebx=7d5c f=805/d4
  #|mul ecx|f7e1|MUL32r:%ECX|eax=b7c42f08 ecx=7bb7bb37 edx=dfbccf2c f=53|eax=4038f2b8 edx=58cf263a f=805/d4
  #|mul ecx|f7e1|MUL32r:%ECX|eax=2bebabba ecx=dad1b813 edx=36a8c347 f=56|eax=3cc56ece edx=258aab38 f=801/d4
  #|mul ecx|f7e1|MUL32r:%ECX|eax=33a4 ecx=e31 edx=4f01cd71 f=806|eax=2dcda64 edx=0 f=0/d4
  #|mul ecx|f7e1|MUL32r:%ECX|ecx=2444795 edx=41cfbbd7 f=887|eax=12c47f59 edx=1e06a9f f=805/d4
  #|mul dword ptr [esp + 0x8]|f7642408|MUL32m:%ESP,1,%,8,%|edx=0 ebx=3 f=d6 m20108=6c18e8ade13178e27745c44f7ffe0a6a|eax=dd2cf85c edx=8ffa6aae f=885/d4
  #|mul dword ptr [esp + 0x8]|f7642408|MUL32m:%ESP,1,%,8,%|eax=1 ecx=897935c1 edx=ff0d ebx=d f=8c7 m20108=67cc62c88b40ee848009a12da6ef1f73|eax=c862cc67 edx=0 f=80/d4
  #|mul dword ptr [esp + 0x8]|f7642408|MUL32m:%ESP,1,%,8,%|ecx=2919aa0d edx=45 ebx=a f=42 m20108=46f46af44c7be5179d992738f5d3310a|eax=8d99ff7e edx=ca5ad0dd f=885/d4
  #|imul ecx|f7e9|IMUL32r:%ECX|ecx=9096db83 f=802|eax=d576789f edx=132c5768 f=885/d4
  #|imul ecx|f7e9|IMUL32r:%ECX|ecx=cdee9954 f=8c6|eax=ea36f464 edx=89dcefe f=881/d4
  #|imul ecx|f7e9|IMUL32r:%ECX|ecx=1e6064f0 edx=9 f=c16|eax=2ba0edb0 edx=fac5b901 f=c01/d4
  #|imul ecx|f7e9|IMUL32r:%ECX|eax=f9acd942 ecx=76887418 edx=0 f=806|eax=91b64630 edx=fd124d19 f=885/d4
  #|imul dword ptr [ebp - 0x20]|f76de0|IMUL32m:%EBP,1,%,-32,%|eax=faabf776 ecx=2c6e3ee6 edx=0 ebx=b f=cc2 m20160=49ba8efb5ad48a27f5f54364fb0c44b6|eax=62494ca6 edx=17abad f=c05/d4
  #|imul dword ptr [ebp - 0x20]|f76de0|IMUL32m:%EBP,1,%,-32,%|eax=ac699ab9 ecx=68fabc30 edx=1a ebx=a f=442 m20160=72a9b0faa23ff7a0f9268c1f76242c68|eax=875b0762 edx=1bbd7a6 f=c81/d4
  #|imul dword ptr [ebp - 0x20]|f76de0|IMUL32m:%EBP,1,%,-32,%|eax=da403047 ecx=3897d3b3 edx=0 ebx=0 f=8d7 m20160=6fd74603325fc61805232f0facf2ef94|eax=92ca8fc9 edx=ff844e59 f=885/d4
  #|div ecx|f7f1|DIV32r:%ECX|eax=1a2a8379 ecx=1 edx=0 f=c53|f=c51/8d5
  #|div ecx|f7f1|DIV32r:%ECX|eax=c86995bf ecx=a5353e19 edx=5d f=802|eax=91 edx=35416996 f=800/8d5
  #|div ecx|f7f1|DIV32r:%ECX|ecx=1 edx=50 f=57|e=0 f=55/8d5
  #|div ecx|f7f1|DIV32r:%ECX|eax=114c961f ecx=b7e41dbf edx=0 f=446|eax=0 edx=114c961f f=444/8d5
  #|div ecx|f7f1|DIV32r:%ECX|eax=5782b5d3 ecx=e67318a1 edx=0 f=7|eax=0 edx=5782b5d3 f=5/8d5
  #|div ecx|f7f1|DIV32r:%ECX|eax=6 ecx=ea008913 edx=0 f=843|eax=0 edx=6 f=841/8d5
  #|div dword ptr [esi + ebx*4 + 0x8]|f7749e08|DIV32m:%ESI,4,%EBX,8,%|eax=f0585156 ecx=c9754879 edx=0 ebx=0 f=4c6 m10088=cb2c270da3792c1564516d23a9ddfc7f|eax=12 edx=3972b10 f=4c4/8d5
  #|div dword ptr [esi + ebx*4 + 0x8]|f7749e08|DIV32m:%ESI,4,%EBX,8,%|eax=8b19 ecx=965b5219 edx=79 ebx=7 f=856 m100a4=7216b7aa86e800212bc0d5a0a86a647b|eax=b5 edx=4c8dac7f f=854/8d5
  #|div dword ptr [esi + ebx*4 + 0x8]|f7749e08|DIV32m:%ESI,4,%EBX,8,%|eax=7c62443 ecx=3de78a15 edx=aa ebx=4 f=87 m10098=8578d62dc4bbbe56e9dc8d26fdbdf643|eax=3b5 edx=1bb95f3a f=85/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=d093815b ecx=91d46b01 edx=f6bb813b f=856|eax=1588e946 edx=ad925615 f=854/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=e2a11494 ecx=0 edx=b6 f=813|e=0 f=811/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=15 ecx=9de36d7d edx=ffffffff f=847|eax=2 edx=c439251b f=845/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=983a90bb ecx=1 edx=0 f=83|e=0 f=81/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=6f36c62a ecx=e81bbe65 edx=c8 f=46|eax=fffff79d edx=fe48f39 f=44/8d5
  #|idiv ecx|f7f9|IDIV32r:%ECX|eax=ffffffff ecx=0 edx=3c f=847|e=0 f=845/8d5
  #|idiv dword ptr [esi]|f73e|IDIV32m:%ESI,1,%,0,%|ecx=923050eb edx=ffffffff ebx=a f=17 m10080=bf42d4415271f4c1074dc6010bb40cc2|eax=0 edx=d3f197b5 f=15/8d5
  #|idiv dword ptr [esi]|f73e|IDIV32m:%ESI,1,%,0,%|eax=2 ecx=3f428b35 edx=0 ebx=2 f=d2 m10080=da78733b55e2284a2036258a704a18bc|eax=0 edx=2 f=d0/8d5
  #|idiv dword ptr [esi]|f73e|IDIV32m:%ESI,1,%,0,%|eax=ca4bec43 ecx=d1092d71 edx=ffffffff ebx=3 f=8d2 m10080=eb0f0565c71e0480990c4e26f4e01bf0|eax=0 edx=ca4bec43 f=8d0/8d5
  #|imul ebx, eax|0fafd8|IMUL32rr:%EBX,%EBX,%EAX|eax=dd3e1ec6 ecx=718d962 edx=5f4a0d32 ebx=dc711602 f=47|ebx=ce87418c f=881/d4
  #|imul ebx, eax|0fafd8|IMUL32rr:%EBX,%EBX,%EAX|eax=ffffffff ecx=4b11b57f edx=8000 ebx=c9df8254 f=8c2|ebx=36207dac f=4/d4
  #|imul ebx, eax|0fafd8|IMUL32rr:%EBX,%EBX,%EAX|eax=8000 ecx=1629c900 edx=b887f8ba ebx=7fffffff f=8c2|ebx=ffff8000 f=885/d4
  #|imul ebx, eax|0fafd8|IMUL32rr:%EBX,%EBX,%EAX|eax=a ebx=0 f=887|f=44/d4
  #|imul ebx, dword ptr [esi]|0faf1e|IMUL32rm:%EBX,%EBX,%ESI,1,%,0,%|ecx=ffffffff ebx=2 f=c2 m10080=83de60b5056d2bac528dee7e8cea3479|ebx=6ac1bd06 f=805/d4
  #|imul ebx, dword ptr [esi]|0faf1e|IMUL32rm:%EBX,%EBX,%ESI,1,%,0,%|ecx=70a94a5c edx=ffffffff ebx=4 f=8c6 m10080=ef362f2a1e24c60cbab0bf37880247f7|ebx=a8bcdbbc f=881/d4
  #|imul ebx, dword ptr [esi]|0faf1e|IMUL32rm:%EBX,%EBX,%ESI,1,%,0,%|ecx=67641919 edx=b279 ebx=5 f=d6 m10080=f53210b16e2c16540649b9492238d1da|ebx=7550fec9 f=805/d4
  #|imul ebx, eax, 0x3|6bd803|IMUL32rri8:%EBX,%EAX,3|eax=85be ecx=f12b39fb edx=82a5e21a ebx=d5a0e18c f=83|ebx=1913a f=4/d4
  #|imul ebx, eax, 0x3|6bd803|IMUL32rri8:%EBX,%EAX,3|eax=7fffffff ecx=ff edx=e65e1c3a ebx=1 f=c7|ebx=7ffffffd f=801/d4
  #|imul ebx, eax, 0x3|6bd803|IMUL32rri8:%EBX,%EAX,3|eax=87b226fd ebx=1156adee f=52|ebx=971674f7 f=881/d4
  #|imul ebx, eax, 0x100|69d800010000|IMUL32rri:%EBX,%EAX,256|eax=1f433add edx=d924de6c ebx=fffffffe f=803|ebx=433add00 f=805/d4
  #|imul ebx, eax, 0x100|69d800010000|IMUL32rri:%EBX,%EAX,256|eax=8c70ef24 edx=e3a9b2b6 ebx=2fc90959 f=816|ebx=70ef2400 f=805/d4
  #|imul ebx, eax, 0x100|69d800010000|IMUL32rri:%EBX,%EAX,256|eax=7221db9 ebx=e7d2324f f=43|ebx=221db900 f=805/d4
  #|imul ebx, dword ptr [esi], 0x11|6b1e11|IMUL32rmi8:%EBX,%ESI,1,%,0,%,17|eax=81106787 edx=865c9c63 ebx=d f=d7 m10080=55c5482064de4e7eb1aecbc9a94fd5d4|ebx=24d51aa5 f=805/d4
  #|imul ebx, dword ptr [esi], 0x11|6b1e11|IMUL32rmi8:%EBX,%ESI,1,%,0,%,17|eax=9 ecx=1740bbdf ebx=5 f=856 m10080=7e56ce35c35f8773bb1a906e1ef7262c|ebx=92b3be5e f=881/d4
