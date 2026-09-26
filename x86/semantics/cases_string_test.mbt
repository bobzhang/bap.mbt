// Generated differential test cases for the x86 lifters (do not edit).
//
// Each instruction was assembled with llvm-mc 22 and executed in Unicorn
// 2.1.4 from a random initial state; the expected final state keeps only
// the architecturally defined outputs (the flags undefined by the Intel
// SDM are masked, see `semantics_harness_test.mbt` for the format).

///|
let string64_cases : String =
  #|movsb|a4|MOVSB:%RDI,%RSI,%|rax=cb f=86|rsi=10081 rdi=10101 f=84/0 m10100=8b
  #|movsb|a4|MOVSB:%RDI,%RSI,%|rdx=1 f=447|rsi=1007f rdi=100ff f=445/0 m10100=8b
  #|movsb|a4|MOVSB:%RDI,%RSI,%|rax=3659b3e5c6ff8ac3 rdx=22593c069d441af0 f=c6|rsi=10081 rdi=10101 f=c4/0 m10100=8b
  #|rep movsb|f3a4|MOVSB:%RDI,%RSI,%|rcx=3 rdx=b76f f=d3|rcx=0 rsi=10083 rdi=10103 f=d1/0 m10100=8bb0d5
  #|rep movsb|f3a4|MOVSB:%RDI,%RSI,%|rax=a8 rcx=3 rdx=35256c4a769c8000 f=446|rcx=0 rsi=1007d rdi=100fd f=444/0 m100fe=41668b
  #|rep movsb|f3a4|MOVSB:%RDI,%RSI,%|rax=e06c04b41aaef14b rcx=2 rdx=957703f9debc450f f=46|rcx=0 rsi=10082 rdi=10102 f=44/0 m10100=8bb0
  #|stosb|aa|STOSB:%RDI|rax=7fffffffffffffff rcx=b884a4ee608e1c7f rdx=eaa6e866985bb95 f=8d3|rdi=10101 f=8d1/0 m10100=ff
  #|stosb|aa|STOSB:%RDI|rcx=3d8a26af64232bcf f=853|rdi=10101 f=851/0 m10100=b5
  #|stosb|aa|STOSB:%RDI|rax=100 f=c7|rdi=10101 f=c5/0 m10100=00
  #|rep stosb|f3aa|STOSB:%RDI|rax=2a144ff14c311f22 rcx=1 rdx=ed f=856|rcx=0 rdi=10101 f=854/0 m10100=22
  #|rep stosb|f3aa|STOSB:%RDI|rax=21bcc4b68e465d50 rcx=1 rdx=f2e1864ffd466a11 f=c7|rcx=0 rdi=10101 f=c5/0 m10100=50
  #|rep stosb|f3aa|STOSB:%RDI|rax=5d657d894340d42b rcx=0 rdx=d48d38f89b51a400 f=457|f=455/0
  #|lodsb|ac|LODSB:%RSI,%|rax=d29876daacf704a rcx=296823450874e331 rdx=b64c6fd0e00082f5 f=897|rax=d29876daacf708b rsi=10081 f=895/0
  #|lodsb|ac|LODSB:%RSI,%|rax=4e5e674dd7cf8821 rcx=2e081240747331b0 f=896|rax=4e5e674dd7cf888b rsi=10081 f=894/0
  #|lodsb|ac|LODSB:%RSI,%|rax=ae rcx=dfdd4144d12ba304 f=c12|rax=8b rsi=1007f f=c10/0
  #|cmpsb|a6|CMPSB:%RDI,%RSI,%|rax=af5d3d7e126b4011 rcx=b6f3e6e4c9794a98 rdx=d823 f=806 m10068=3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a m100e8=3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a3b816a8cd59ef35a69816a8cd59ef35a|rsi=10081 rdi=10101 f=44/0
  #|cmpsb|a6|CMPSB:%RDI,%RSI,%|rax=a1b35fd486587186 rcx=2fe6a3440f943d6c rdx=ca9c517be5fc5454 f=c47 m10068=03f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f1 m100e8=03f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f103f99593f1e8b5f199f99593f1e8b5f1|rsi=1007f rdi=100ff f=444/0
  #|cmpsb|a6|CMPSB:%RDI,%RSI,%|rax=10 rcx=1037e9d6caa87486 f=cc7 m10068=0c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a09 m100e8=0c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a090c6f8e8184b60a095a6f8e8184b60a09|rsi=1007f rdi=100ff f=444/0
  #|repe cmpsb|f3a6|CMPSB:%RDI,%RSI,%|rax=8000000000000000 rcx=0 rdx=1fdefbb26a33b0da f=52 m10068=96c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce5 m100e8=96c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce596c9006a4fc73ce5e1c9006a4fc73ce5|f=50/0
  #|repe cmpsb|f3a6|CMPSB:%RDI,%RSI,%|rax=96c2e68413dd7e7a rcx=5 f=8d2|rcx=4 rsi=10081 rdi=10101 f=80/0
  #|repe cmpsb|f3a6|CMPSB:%RDI,%RSI,%|rax=ff48b6ceee5e7b3d rcx=2 rdx=232ac5d135d7ed4f f=96|rcx=1 rsi=10081 rdi=10101 f=80/0
  #|repne cmpsb|f2a6|CMPSB:%RDI,%RSI,%|rax=0 rcx=3 rdx=f68dfc6e5d8b2e1c f=cc7|rcx=0 rsi=1007d rdi=100fd f=c81/0
  #|repne cmpsb|f2a6|CMPSB:%RDI,%RSI,%|rax=2e18f47bc25606b2 rcx=2 f=c06 m10068=e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3 m100e8=e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea3e4aa95f0a349eea307aa95f0a349eea3|rcx=1 rsi=1007f rdi=100ff f=444/0
  #|repne cmpsb|f2a6|CMPSB:%RDI,%RSI,%|rcx=3 rdx=f88f0e90d8daef9 f=97 m10068=33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac m100e8=33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac33df47c39d2019ac54df47c39d2019ac|rcx=2 rsi=10081 rdi=10101 f=44/0
  #|scasb|ae|SCASB:%RDI|rax=b7f770de4ea6b2ff rcx=62 rdx=ef31347c55448c6a f=883|rdi=10101 f=80/0
  #|scasb|ae|SCASB:%RDI|rax=62509325b208549b rcx=e1d68ed02a81e253 rdx=426a0d32af75aba0 f=96 m100e8=9b9a9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b9b|rdi=10101 f=44/0
  #|scasb|ae|SCASB:%RDI|rax=fffffffffffffffe rcx=e57c rdx=1156c208f23154bb f=486|rdi=100ff f=484/0
  #|repe scasb|f3ae|SCASB:%RDI|rax=9700e7cf7611ac5d rcx=2 f=c07 m100e8=5d5d5d5d5d5d5d5d5d5d5d5c5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d5d|rcx=0 rdi=100fe f=444/0
  #|repe scasb|f3ae|SCASB:%RDI|rax=aeb279c3f58e0151 rcx=1 rdx=be43d2767e2bcd30 f=817 m100e8=515151515151515151515151515151515151515151515151515151515151515151515151505151515151515151515151|rcx=0 rdi=10101 f=44/0
  #|repe scasb|f3ae|SCASB:%RDI|rcx=0 rdx=856a736e6e182280 f=52|f=50/0
  #|repne scasb|f2ae|SCASB:%RDI|rax=18 rcx=2 rdx=46c1ad2dbeadeaf3 f=406|rcx=0 rdi=100fe f=401/0
  #|repne scasb|f2ae|SCASB:%RDI|rax=fafba79cb44274c rcx=5 rdx=7bd13d3cc0629680 f=802 m100e8=4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4d4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c4c|rcx=4 rdi=10101 f=44/0
  #|repne scasb|f2ae|SCASB:%RDI|rax=cd21dcea37a51b96 rcx=5 rdx=8000000000000000 f=896|rcx=0 rdi=10105 f=91/0
  #|movsw|66a5|MOVSW:%RDI,%RSI,%|rdx=143d07eed7a47707 f=882|rsi=10082 rdi=10102 f=880/0 m10100=8bb0
  #|movsw|66a5|MOVSW:%RDI,%RSI,%|rcx=ffffffffffffffff rdx=12aed6688af12c8d f=417|rsi=1007e rdi=100fe f=415/0 m10100=8bb0
  #|movsw|66a5|MOVSW:%RDI,%RSI,%|rcx=e f=86|rsi=10082 rdi=10102 f=84/0 m10100=8bb0
  #|rep movsw|f366a5|MOVSW:%RDI,%RSI,%|rax=d906 rcx=0 rdx=3ace5796b3d28000 f=846|f=844/0
  #|rep movsw|f366a5|MOVSW:%RDI,%RSI,%|rcx=3 rdx=fffffffffffffffe f=97|rcx=0 rsi=10086 rdi=10106 f=95/0 m10100=8bb0d5fa1f44
  #|rep movsw|f366a5|MOVSW:%RDI,%RSI,%|rax=80ee885afc74780c rcx=2 f=813|rcx=0 rsi=10084 rdi=10104 f=811/0 m10100=8bb0d5fa
  #|stosw|66ab|STOSW:%RDI|rax=ff rcx=c44f278a58525107 rdx=7fffffff f=806|rdi=10102 f=804/0 m10100=ff00
  #|stosw|66ab|STOSW:%RDI|rcx=aa6a1d539d0996ba f=8c3|rdi=10102 f=8c1/0 m10100=b597
  #|stosw|66ab|STOSW:%RDI|rax=f7f105c63707c4fb rdx=6d4a87a4e46d84a7 f=883|rdi=10102 f=881/0 m10100=fbc4
  #|rep stosw|f366ab|STOSW:%RDI|rax=100 rcx=2 rdx=8491 f=53|rcx=0 rdi=10104 f=51/0 m10100=00010001
  #|rep stosw|f366ab|STOSW:%RDI|rax=f51e8ca222228917 rcx=0 rdx=1 f=4d2|f=4d0/0
  #|rep stosw|f366ab|STOSW:%RDI|rax=7fffffff rcx=2 rdx=946bc31aa94d7bfa f=d6|rcx=0 rdi=10104 f=d4/0 m10100=ffffffff
  #|lodsw|66ad|LODSW:%RSI,%|rax=85c2eb1a7e818617 rcx=8d4792a22b15b555 f=42|rax=85c2eb1a7e81b08b rsi=10082 f=40/0
  #|lodsw|66ad|LODSW:%RSI,%|rax=8000000000000000 f=4d6|rax=800000000000b08b rsi=1007e f=4d4/0
  #|lodsw|66ad|LODSW:%RSI,%|rcx=503e2e3ba2ae0db8 rdx=ec0a7e59368440ff f=8d6|rax=5b791f3dd3f1b08b rsi=10082 f=8d4/0
  #|cmpsw|66a7|CMPSW:%RDI,%RSI,%|rax=3a9c52f3606705ff rcx=ffff rdx=b f=8c2|rsi=10082 rdi=10102 f=80/0
  #|cmpsw|66a7|CMPSW:%RDI,%RSI,%|rax=f04a0f0eabce851c f=56|rsi=10082 rdi=10102 f=80/0
  #|cmpsw|66a7|CMPSW:%RDI,%RSI,%|rax=b rcx=f62d8a48a77d74ff rdx=22cfa3fb3327fec f=406 m10068=117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0 m100e8=117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada0117fdfd0cb29ada07f7fdfd0cb29ada0|rsi=1007e rdi=100fe f=444/0
  #|repe cmpsw|f366a7|CMPSW:%RDI,%RSI,%|rax=80000000 rcx=5 rdx=ab96b3f8a34014a5 f=4d2 m10068=5d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a044 m100e8=5d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0445d3d7fc68946a0446c3d7fc68946a044|rcx=0 rsi=10076 rdi=100f6 f=444/0
  #|repe cmpsw|f366a7|CMPSW:%RDI,%RSI,%|rax=9a rcx=5 rdx=7a1998ec59855dc1 f=cc2 m10068=5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f m100e8=5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f5c8d97d44674266f718d97d44674266f|rcx=0 rsi=10076 rdi=100f6 f=444/0
  #|repe cmpsw|f366a7|CMPSW:%RDI,%RSI,%|rcx=1 rdx=ffff f=cc3|rcx=0 rsi=1007e rdi=100fe f=480/0
  #|repne cmpsw|f266a7|CMPSW:%RDI,%RSI,%|rcx=5 f=c7 m10068=8dceb5dd814780d08dceb5dd814780d08dceb5dd814780d08dceb5dd814780d08dceb5dd814780d08dceb5dd814780d0 m100e8=8dceb5dd814780d08dceb5dd814780d08dceb5dd814780d08dceb5dd814780d08dceb5dd814780d0fbceb5dd814780d0|rcx=4 rsi=10082 rdi=10102 f=44/0
  #|repne cmpsw|f266a7|CMPSW:%RDI,%RSI,%|rcx=3 rdx=35a7d1582dc4d4e9 f=457|rcx=0 rsi=1007a rdi=100fa f=c81/0
  #|repne cmpsw|f266a7|CMPSW:%RDI,%RSI,%|rax=40a83ea8a06b0638 rcx=5 rdx=74caf041b7856685 f=4d6 m10068=c8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3a m100e8=c8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3ac8c92efd1be4ee3a31c92efd1be4ee3a|rcx=4 rsi=1007e rdi=100fe f=444/0
  #|scasw|66af|SCASW:%RDI|rax=76315c62e5a07b84 rcx=7fffffff f=456|rdi=100fe f=410/0
  #|scasw|66af|SCASW:%RDI|rax=7fffffffffffffff rcx=8000 f=817|rdi=10102 f=80/0
  #|scasw|66af|SCASW:%RDI|rax=6df6acb412d48000 rcx=4739ba7181fa7026 f=483|rdi=100fe f=c14/0
  #|repe scasw|f366af|SCASW:%RDI|rax=e8c89341637c1744 rcx=0 rdx=a0cc255f975827c f=83 m100e8=441744174417441744174417441744174417441744174417441744164417441744174417441744174417441744174417|f=81/0
  #|repe scasw|f366af|SCASW:%RDI|rax=ffffffffffffffff rcx=2 rdx=6 f=403|rcx=1 rdi=100fe f=480/0
  #|repe scasw|f366af|SCASW:%RDI|rax=91e9b18f1bee870b rcx=5 rdx=b2fc f=407 m100e8=0b870b870b870b870b870b870b870b870b860b870b870b870b870b870b870b870b870b870b870b870b870b870b870b87|rcx=0 rdi=100f6 f=404/0
  #|repne scasw|f266af|SCASW:%RDI|rax=b7f2bbeacfbfd64b rcx=5 rdx=2 f=c87 m100e8=4bd64bd64bd74bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd64bd6|rcx=4 rdi=100fe f=444/0
  #|repne scasw|f266af|SCASW:%RDI|rax=7fff rcx=3 f=c57|rcx=0 rdi=100fa f=c85/0
  #|repne scasw|f266af|SCASW:%RDI|rax=4a3ae00c896a1112 rcx=0 rdx=522f628d6d55231b f=56 m100e8=121112111211121112111211121112111211121112111211121112111211121113111211121112111211121112111211|f=54/0
  #|movsd|a5|MOVSL:%RDI,%RSI,%|rax=10920f263780b32e rcx=8cc027fb694daf9b f=493|rsi=1007c rdi=100fc f=491/0 m10100=8bb0d5fa
  #|movsd|a5|MOVSL:%RDI,%RSI,%|rax=3 rdx=d0ed0c7a8ef4a f=7|rsi=10084 rdi=10104 f=5/0 m10100=8bb0d5fa
  #|movsd|a5|MOVSL:%RDI,%RSI,%|rax=2a4a54fdc6582eb6 rdx=ce393b520117b496 f=883|rsi=10084 rdi=10104 f=881/0 m10100=8bb0d5fa
  #|rep movsd|f3a5|MOVSL:%RDI,%RSI,%|rax=a7520f807e7a9a rcx=0 rdx=4 f=853|f=851/0
  #|rep movsd|f3a5|MOVSL:%RDI,%RSI,%|rax=ffff rcx=5 f=853|rcx=0 rsi=10094 rdi=10114 f=851/0 m10100=8bb0d5fa1f44698eb3d8fd22476c91b6db00254a
  #|rep movsd|f3a5|MOVSL:%RDI,%RSI,%|rax=b5a4916e7b4a3cda rcx=1 rdx=f973ea8aac564f32 f=8d3|rcx=0 rsi=10084 rdi=10104 f=8d1/0 m10100=8bb0d5fa
  #|stosd|ab|STOSL:%RDI|rax=7fffffff rcx=3d614ee026be0bc0 rdx=2a9aa3d44d99df92 f=cc2|rdi=100fc f=cc0/0 m10100=ffffff7f
  #|stosd|ab|STOSL:%RDI|rax=43dd4bf401e3182b rcx=7829 f=807|rdi=10104 f=805/0 m10100=2b18e301
  #|stosd|ab|STOSL:%RDI|rax=5e85de621f50070b rcx=6ea300a00e58cbae rdx=8691 f=d6|rdi=10104 f=d4/0 m10101=07501f
  #|rep stosd|f3ab|STOSL:%RDI|rax=a279f829330b337f rcx=5 rdx=1160ca343b5e14da f=802|rcx=0 rdi=10114 f=800/0 m10100=7f330b337f330b337f330b337f330b337f330b33
  #|rep stosd|f3ab|STOSL:%RDI|rcx=5 f=882|rcx=0 rdi=10114 f=880/0 m10100=b597f1d3b597f1d3b597f1d3b597f1d3b597f1d3
  #|rep stosd|f3ab|STOSL:%RDI|rax=b1b858f64b2b2c73 rcx=2 rdx=23a86cc4791ea78d f=8d7|rcx=0 rdi=10108 f=8d5/0 m10100=732c2b4b732c2b4b
  #|lodsd|ad|LODSL:%RSI,%|rax=8000 rcx=0 rdx=7fffffffffffffff f=4d3|rax=fad5b08b rsi=1007c f=4d1/0
  #|lodsd|ad|LODSL:%RSI,%|rax=4b762e7e16dce657 rdx=a96bd60deb68440f f=cc3|rax=fad5b08b rsi=1007c f=cc1/0
  #|lodsd|ad|LODSL:%RSI,%|rax=76e85853c994f11b rdx=91e9b7a9ed0eac7c f=843|rax=fad5b08b rsi=10084 f=841/0
  #|cmpsd|a7|CMPSL:%RDI,%RSI,%|rcx=b rdx=41 f=cd7|rsi=1007c rdi=100fc f=480/0
  #|cmpsd|a7|CMPSL:%RDI,%RSI,%|rax=e2132b838fd30f2d f=806 m10068=bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091 m100e8=bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f7091bdd584c2af4f70915dd584c2af4f7091|rsi=10084 rdi=10104 f=44/0
  #|cmpsd|a7|CMPSL:%RDI,%RSI,%|rax=332dafac5fafb78 rcx=35c3ab3319f5c049 f=86|rsi=10084 rdi=10104 f=80/0
  #|repe cmpsd|f3a7|CMPSL:%RDI,%RSI,%|rax=1 rcx=1 f=492|rcx=0 rsi=1007c rdi=100fc f=480/0
  #|repe cmpsd|f3a7|CMPSL:%RDI,%RSI,%|rax=b14f6a6f009cea3 rcx=5 f=493|rcx=4 rsi=1007c rdi=100fc f=480/0
  #|repe cmpsd|f3a7|CMPSL:%RDI,%RSI,%|rcx=2 rdx=80000000 f=842 m10068=043721598697593004372159869759300437215986975930043721598697593004372159869759300437215986975930 m100e8=043721598697593004372159869759300437215986975930043721598697593004372159869759308d37215986975930|rcx=0 rsi=10088 rdi=10108 f=44/0
  #|repne cmpsd|f2a7|CMPSL:%RDI,%RSI,%|rax=25c1 rcx=3 rdx=44f7 f=86 m10068=fb4d88668082260cfb4d88668082260cfb4d88668082260cfb4d88668082260cfb4d88668082260cfb4d88668082260c m100e8=fb4d88668082260cfb4d88668082260cfb4d88668082260cfb4d88668082260cfb4d88668082260ce64d88668082260c|rcx=2 rsi=10084 rdi=10104 f=44/0
  #|repne cmpsd|f2a7|CMPSL:%RDI,%RSI,%|rax=9d721ed50ece0c09 rcx=0 rdx=5a45d5357bf625e9 f=c93 m10068=2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b m100e8=2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8b2467ec69ec7aef8ba767ec69ec7aef8b|f=c91/0
  #|repne cmpsd|f2a7|CMPSL:%RDI,%RSI,%|rax=b63197747528f462 rcx=0 rdx=49e93132b73f4a90 f=42|f=40/0
  #|scasd|af|SCASL:%RDI|rdx=a2f31741fcbc3d5e f=c82|rdi=100fc f=c14/0
  #|scasd|af|SCASL:%RDI|rax=9d0f rcx=ffffffffffffffff rdx=0 f=d3|rdi=10104 f=81/0
  #|scasd|af|SCASL:%RDI|rax=d4b1fe6e8592bf45 rcx=45dba3c912f3bb7d f=882 m100e8=45be928545bf928545bf928545bf928545bf928545bf928545bf928545bf928545bf928545bf928545bf928545bf9285|rdi=10104 f=44/0
  #|repe scasd|f3af|SCASL:%RDI|rcx=1 rdx=7f f=446|rcx=0 rdi=100fc f=c14/0
  #|repe scasd|f3af|SCASL:%RDI|rax=e48dad1b68707990 rcx=5 rdx=d3b1e67fb4ad5909 f=883 m100e8=907970689079706890797068907970689079706890797068907970689079706890797168907970689079706890797068|rcx=2 rdi=1010c f=85/0
  #|repe scasd|f3af|SCASL:%RDI|rax=de6d18542eb18b1c rcx=2 rdx=7efae8306db430f3 f=c06|rcx=1 rdi=100fc f=485/0
  #|repne scasd|f2af|SCASL:%RDI|rax=caeb rcx=1 f=487|rcx=0 rdi=100fc f=481/0
  #|repne scasd|f2af|SCASL:%RDI|rax=a3d180d639edb49a rcx=3 rdx=f935 f=846 m100e8=9ab4ed399ab4ed399ab4ed389ab4ed399ab4ed399ab4ed399ab4ed399ab4ed399ab4ed399ab4ed399ab4ed399ab4ed39|rcx=2 rdi=10104 f=44/0
  #|repne scasd|f2af|SCASL:%RDI|rax=4da9356cac14b262 rcx=0 rdx=ffffffff f=52 m100e8=62b214ac62b214ac62b215ac62b214ac62b214ac62b214ac62b214ac62b214ac62b214ac62b214ac62b214ac62b214ac|f=50/0
  #|movsq|48a5|MOVSQ:%RDI,%RSI,%|rdx=e45b16f1a02e6cf f=17|rsi=10088 rdi=10108 f=15/0 m10100=8bb0d5fa1f44698e
  #|movsq|48a5|MOVSQ:%RDI,%RSI,%|rax=24f3c73e7fffffff rcx=80 f=893|rsi=10088 rdi=10108 f=891/0 m10100=8bb0d5fa1f44698e
  #|movsq|48a5|MOVSQ:%RDI,%RSI,%|rcx=1d127d1bd0daf722 rdx=83a0973aa11a8000 f=813|rsi=10088 rdi=10108 f=811/0 m10100=8bb0d5fa1f44698e
  #|rep movsq|f348a5|MOVSQ:%RDI,%RSI,%|rcx=5 f=93|rcx=0 rsi=100a8 rdi=10128 f=91/0 m10100=8bb0d5fa1f44698eb3d8fd22476c91b6db00254a6f94b9de03284d7297bce1062b50759abfe4092e
  #|rep movsq|f348a5|MOVSQ:%RDI,%RSI,%|rax=f394ab0c3cf6ffff rcx=2 rdx=60b5e9a0e19bccc1 f=4d2|rcx=0 rsi=10070 rdi=100f0 f=4d0/0 m100f8=6388add2f71c41668bb0d5fa1f44698e
  #|rep movsq|f348a5|MOVSQ:%RDI,%RSI,%|rax=18d74e4bc78fc810 rcx=1 f=c02|rcx=0 rsi=10078 rdi=100f8 f=c00/0 m10100=8bb0d5fa1f44698e
  #|stosq|48ab|STOSQ:%RDI|rax=7f rcx=ed rdx=98ffc73bee71d245 f=86|rdi=10108 f=84/0 m10100=7f00000000000000
  #|stosq|48ab|STOSQ:%RDI|rax=ce55168717e7dfe9 rcx=5a6352e4ffffffff f=447|rdi=100f8 f=445/0 m10100=e9dfe717871655ce
  #|stosq|48ab|STOSQ:%RDI|rcx=49b5a53d3305b82d f=896|rdi=10108 f=894/0 m10100=b597f1d33d1f795b
  #|rep stosq|f348ab|STOSQ:%RDI|rax=e11d7299d64d3347 rcx=2 f=853|rcx=0 rdi=10110 f=851/0 m10100=47334dd699721de147334dd699721de1
  #|rep stosq|f348ab|STOSQ:%RDI|rax=ffffffffffffffff rcx=1 rdx=20e7fc1053e09cd1 f=c57|rcx=0 rdi=100f8 f=c55/0 m10100=ffffffffffffffff
  #|rep stosq|f348ab|STOSQ:%RDI|rax=8000 rcx=5 rdx=5 f=c87|rcx=0 rdi=100d8 f=c85/0 m100e0=00800000000000000080000000000000008000000000000000800000000000000080000000000000
  #|lodsq|48ad|LODSQ:%RSI,%|rdx=583a94e9acc3a27f f=8c7|rax=8e69441ffad5b08b rsi=10088 f=8c5/0
  #|lodsq|48ad|LODSQ:%RSI,%|rax=7fffffffffffffff f=c93|rax=8e69441ffad5b08b rsi=10078 f=c91/0
  #|lodsq|48ad|LODSQ:%RSI,%|rax=9 rdx=8536b051c76c0171 f=882|rax=8e69441ffad5b08b rsi=10088 f=880/0
  #|cmpsq|48a7|CMPSQ:%RDI,%RSI,%|rcx=5cb7047ffcdccdd0 rdx=e26b f=857|rsi=10088 rdi=10108 f=800/0
  #|cmpsq|48a7|CMPSQ:%RDI,%RSI,%|rax=271ca1caf88348f1 rdx=aadef82aa8db9842 f=d2 m10068=3de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c1 m100e8=3de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c13de7cac6cf8b07c1a9e7cac6cf8b07c1|rsi=10088 rdi=10108 f=44/0
  #|cmpsq|48a7|CMPSQ:%RDI,%RSI,%|rax=2ce23448696fa5fc rdx=da6c7bc957aeaa80 f=8d6|rsi=10088 rdi=10108 f=800/0
  #|repe cmpsq|f348a7|CMPSQ:%RDI,%RSI,%|rcx=2 rdx=ca63fed6ccb5f0d0 f=847 m10068=b227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56a m100e8=b227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56ab227a0e6f516e56a5b27a0e6f516e56a|rcx=0 rsi=10090 rdi=10110 f=44/0
  #|repe cmpsq|f348a7|CMPSQ:%RDI,%RSI,%|rax=df rcx=5 rdx=f49d0ca75c3db0f1 f=817 m10068=da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499 m100e8=da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499da2b7dfd9f1a7499a12b7dfd9f1a7499|rcx=2 rsi=10098 rdi=10118 f=4/0
  #|repe cmpsq|f348a7|CMPSQ:%RDI,%RSI,%|rax=3681b2319ba9e7a rcx=0 rdx=8f2a8187d993b3a4 f=496 m10068=ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702 m100e8=ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702ac9ab3779f2e6702799ab3779f2e6702|f=494/0
  #|repne cmpsq|f248a7|CMPSQ:%RDI,%RSI,%|rax=fd757b45b5b6ca13 rcx=3 f=43|rcx=0 rsi=10098 rdi=10118 f=80/0
  #|repne cmpsq|f248a7|CMPSQ:%RDI,%RSI,%|rax=b443671b77f67fff rcx=5 rdx=e f=c92|rcx=0 rsi=10058 rdi=100d8 f=480/0
  #|repne cmpsq|f248a7|CMPSQ:%RDI,%RSI,%|rax=efdfd642e5008e2d rcx=3 rdx=c1a0215228ff55d7 f=cc3|rcx=0 rsi=10068 rdi=100e8 f=401/0
  #|scasq|48af|SCASQ:%RDI|rax=4fe0ca1f96d87670 rdx=745d95b721eb0693 f=812 m100e8=7076d8961fcae04f7076d8961fcae04f7176d8961fcae04f7076d8961fcae04f7076d8961fcae04f7076d8961fcae04f|rdi=10108 f=44/0
  #|scasq|48af|SCASQ:%RDI|rcx=c977fc04df3dff3c rdx=7fff f=406|rdi=100f8 f=414/0
  #|scasq|48af|SCASQ:%RDI|rdx=46bd65eab694fd2a f=83|rdi=10108 f=14/0
  #|repe scasq|f348af|SCASQ:%RDI|rax=9af33d5ad546a24 rcx=5 rdx=9ee7096238c6257d f=cc2 m100e8=246a54add533af08246a54add533af09246a54add533af09246a54add533af09246a54add533af09246a54add533af09|rcx=1 rdi=100e0 f=404/0
  #|repe scasq|f348af|SCASQ:%RDI|rax=af7e205c8769bb0b rcx=1 rdx=37128888fb0e9a26 f=4c3 m100e8=0bbb69875c207eaf0bbb69875c207eaf0bbb69875c207eaf0bbb69875c207eaf0abb69875c207eaf0bbb69875c207eaf|rcx=0 rdi=100f8 f=444/0
  #|repe scasq|f348af|SCASQ:%RDI|rcx=5 f=2|rcx=4 rdi=10108 f=14/0
  #|repne scasq|f248af|SCASQ:%RDI|rcx=5 rdx=1965283eeeefc576 f=96|rcx=0 rdi=10128 f=895/0
  #|repne scasq|f248af|SCASQ:%RDI|rcx=2 f=c2|rcx=0 rdi=10110 f=4/0
  #|repne scasq|f248af|SCASQ:%RDI|rax=fa00d3cc0db344c6 rcx=0 rdx=166244b7093cb6b5 f=47 m100e8=c644b30dccd300fac644b20dccd300fac644b30dccd300fac644b30dccd300fac644b30dccd300fac644b30dccd300fa|f=45/0

///|
let string32_cases : String =
  #|movsb|a4|MOVSB:%EDI,%ESI,%|eax=74174e2b ecx=7fff f=883|esi=10081 edi=10101 f=881/0 m10100=8b
  #|movsb|a4|MOVSB:%EDI,%ESI,%|ecx=9a492ca edx=8000 f=882|esi=10081 edi=10101 f=880/0 m10100=8b
  #|movsb|a4|MOVSB:%EDI,%ESI,%|eax=4dcb367f ecx=aa2fc815 edx=730654be f=c3|esi=10081 edi=10101 f=c1/0 m10100=8b
  #|rep movsb|f3a4|MOVSB:%EDI,%ESI,%|eax=ffffffff ecx=5 edx=60fa673e f=882|ecx=0 esi=10085 edi=10105 f=880/0 m10100=8bb0d5fa1f
  #|rep movsb|f3a4|MOVSB:%EDI,%ESI,%|ecx=1 f=c07|ecx=0 esi=1007f edi=100ff f=c05/0 m10100=8b
  #|rep movsb|f3a4|MOVSB:%EDI,%ESI,%|ecx=0 edx=7 f=492|f=490/0
  #|stosb|aa|STOSB:%EDI|eax=91b5aa69 edx=e14fb7cb f=4d7|edi=100ff f=4d5/0 m10100=69
  #|stosb|aa|STOSB:%EDI|eax=23366d43 ecx=5dfc8398 edx=ff f=97|edi=10101 f=95/0 m10100=43
  #|stosb|aa|STOSB:%EDI|eax=b42a8000 ecx=59677c97 edx=5578f11f f=8c6|edi=10101 f=8c4/0 m10100=00
  #|rep stosb|f3aa|STOSB:%EDI|eax=e3ff482a ecx=1 edx=89f78f43 f=4c7|ecx=0 edi=100ff f=4c5/0 m10100=2a
  #|rep stosb|f3aa|STOSB:%EDI|eax=94fc7fff ecx=5 edx=2 f=8d3|ecx=0 edi=10105 f=8d1/0 m10100=ffffffffff
  #|rep stosb|f3aa|STOSB:%EDI|eax=669a05a7 ecx=5 edx=5ea88900 f=8d2|ecx=0 edi=10105 f=8d0/0 m10100=a7a7a7a7a7
  #|lodsb|ac|LODSB:%ESI,%|eax=8000 ecx=ffffffff f=12|eax=808b esi=10081 f=10/0
  #|lodsb|ac|LODSB:%ESI,%|ecx=bc9f edx=7ed3ed26 f=492|eax=d3f1978b esi=1007f f=490/0
  #|lodsb|ac|LODSB:%ESI,%|f=cc2|eax=d3f1978b esi=1007f f=cc0/0
  #|cmpsb|a6|CMPSB:%EDI,%ESI,%|eax=497e0e47 edx=92693a4d f=8c2 m10068=e18596a89c940633e18596a89c940633e18596a89c940633e18596a89c940633e18596a89c940633e18596a89c940633 m100e8=e18596a89c940633e18596a89c940633e18596a89c940633e18596a89c940633e18596a89c940633d38596a89c940633|esi=10081 edi=10101 f=44/0
  #|cmpsb|a6|CMPSB:%EDI,%ESI,%|eax=c33b173 f=4d6|esi=1007f edi=100ff f=480/0
  #|cmpsb|a6|CMPSB:%EDI,%ESI,%|ecx=911f91bb f=c03 m10068=a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9 m100e8=a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9a720dfed19c1d1e9f720dfed19c1d1e9|esi=1007f edi=100ff f=444/0
  #|repe cmpsb|f3a6|CMPSB:%EDI,%ESI,%|eax=f45b84b1 ecx=3 edx=5f2f4eff f=16 m10068=7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f m100e8=7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7ee31b6dea68dd2f7fe31b6dea68dd2f|ecx=0 esi=10083 edi=10103 f=44/0
  #|repe cmpsb|f3a6|CMPSB:%EDI,%ESI,%|eax=4c47a59a ecx=0 edx=6873da5b f=443 m10068=d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4 m100e8=d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4d5b3673006332dc4d5b3673006332dc496b3673006332dc4|f=441/0
  #|repe cmpsb|f3a6|CMPSB:%EDI,%ESI,%|ecx=2 edx=d49b20a f=97|ecx=1 esi=10081 edi=10101 f=80/0
  #|repne cmpsb|f2a6|CMPSB:%EDI,%ESI,%|eax=ffffffff ecx=1 edx=20f09c05 f=87|ecx=0 esi=10081 edi=10101 f=80/0
  #|repne cmpsb|f2a6|CMPSB:%EDI,%ESI,%|eax=444401fe ecx=1 f=492|ecx=0 esi=1007f edi=100ff f=480/0
  #|repne cmpsb|f2a6|CMPSB:%EDI,%ESI,%|eax=b1797fff ecx=1 f=cd3 m10068=186a130b01dc324a186a130b01dc324a186a130b01dc324a186a130b01dc324a186a130b01dc324a186a130b01dc324a m100e8=186a130b01dc324a186a130b01dc324a186a130b01dc324a186a130b01dc324a186a130b01dc324afc6a130b01dc324a|ecx=0 esi=1007f edi=100ff f=444/0
  #|scasb|ae|SCASB:%EDI|eax=2444ccd7 edx=ffffffff f=13|edi=10101 f=94/0
  #|scasb|ae|SCASB:%EDI|ecx=5854fb3b f=407|edi=100ff f=494/0
  #|scasb|ae|SCASB:%EDI|ecx=3c184187 edx=b012b878 f=483|edi=100ff f=494/0
  #|repe scasb|f3ae|SCASB:%EDI|eax=98ba0631 ecx=5 f=443 m100e8=313131313131313131313131313131313131313130313131313131313131313131313131313131313131313131313131|ecx=0 edi=100fb f=400/0
  #|repe scasb|f3ae|SCASB:%EDI|ecx=3 f=447|ecx=2 edi=100ff f=494/0
  #|repe scasb|f3ae|SCASB:%EDI|eax=b3c5a120 ecx=2 edx=4c68bdfe f=813|ecx=1 edi=10101 f=10/0
  #|repne scasb|f2ae|SCASB:%EDI|eax=805665cd ecx=3 edx=e57020de f=493|ecx=0 edi=100fd f=404/0
  #|repne scasb|f2ae|SCASB:%EDI|ecx=0 edx=74f1f100 f=c3|f=c1/0
  #|repne scasb|f2ae|SCASB:%EDI|eax=abc69396 ecx=2 edx=7fffffff f=c97|ecx=0 edi=100fe f=481/0
  #|movsw|66a5|MOVSW:%EDI,%ESI,%|ecx=80000000 edx=996f2d95 f=c82|esi=1007e edi=100fe f=c80/0 m10100=8bb0
  #|movsw|66a5|MOVSW:%EDI,%ESI,%|eax=a8bbec12 ecx=51fc8a87 f=cc3|esi=1007e edi=100fe f=cc1/0 m10100=8bb0
  #|movsw|66a5|MOVSW:%EDI,%ESI,%|eax=fedca46 ecx=4d edx=ffffffff f=847|esi=10082 edi=10102 f=845/0 m10100=8bb0
  #|rep movsw|f366a5|MOVSW:%EDI,%ESI,%|eax=6032ad97 ecx=1 edx=d f=87|ecx=0 esi=10082 edi=10102 f=85/0 m10100=8bb0
  #|rep movsw|f366a5|MOVSW:%EDI,%ESI,%|eax=ff ecx=2 edx=99ebf6d4 f=887|ecx=0 esi=10084 edi=10104 f=885/0 m10100=8bb0d5fa
  #|rep movsw|f366a5|MOVSW:%EDI,%ESI,%|eax=8 ecx=1 f=412|ecx=0 esi=1007e edi=100fe f=410/0 m10100=8bb0
  #|stosw|66ab|STOSW:%EDI|eax=8c848000 ecx=ffffffff edx=39 f=407|edi=100fe f=405/0 m10100=0080
  #|stosw|66ab|STOSW:%EDI|ecx=1022d863 edx=e42f31b5 f=8c7|edi=10102 f=8c5/0 m10100=b597
  #|stosw|66ab|STOSW:%EDI|eax=f5e76800 ecx=814d250e edx=425077c5 f=493|edi=100fe f=491/0 m10100=0068
  #|rep stosw|f366ab|STOSW:%EDI|ecx=3 edx=2 f=496|ecx=0 edi=100fa f=494/0 m100fc=b597b597b597
  #|rep stosw|f366ab|STOSW:%EDI|eax=79c16ef1 ecx=5 edx=24 f=897|ecx=0 edi=1010a f=895/0 m10100=f16ef16ef16ef16ef16e
  #|rep stosw|f366ab|STOSW:%EDI|ecx=2 edx=2e6327a f=56|ecx=0 edi=10104 f=54/0 m10100=b597b597
  #|lodsw|66ad|LODSW:%ESI,%|eax=ff ecx=d01457ba edx=7f f=c06|eax=b08b esi=1007e f=c04/0
  #|lodsw|66ad|LODSW:%ESI,%|eax=f0 edx=fffffffe f=846|eax=b08b esi=10082 f=844/0
  #|lodsw|66ad|LODSW:%ESI,%|edx=61dd6dcf f=43|eax=d3f1b08b esi=10082 f=41/0
  #|cmpsw|66a7|CMPSW:%EDI,%ESI,%|eax=c112cd5c ecx=0 edx=7255c0f9 f=7|esi=10082 edi=10102 f=80/0
  #|cmpsw|66a7|CMPSW:%EDI,%ESI,%|eax=47 ecx=891a862d edx=f94f43dc f=843|esi=10082 edi=10102 f=80/0
  #|cmpsw|66a7|CMPSW:%EDI,%ESI,%|eax=699e3e99 ecx=5ac18cd1 f=4c3 m10068=dace48370c0298efdace48370c0298efdace48370c0298efdace48370c0298efdace48370c0298efdace48370c0298ef m100e8=dace48370c0298efdace48370c0298efdace48370c0298efdace48370c0298efdace48370c0298ef18ce48370c0298ef|esi=1007e edi=100fe f=444/0
  #|repe cmpsw|f366a7|CMPSW:%EDI,%ESI,%|eax=0 ecx=0 f=803 m10068=084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0 m100e8=084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0084229ca3ebb7bb0154229ca3ebb7bb0|f=801/0
  #|repe cmpsw|f366a7|CMPSW:%EDI,%ESI,%|eax=ffffffff ecx=3 f=8d7 m10068=c175f08ae171e68fc175f08ae171e68fc175f08ae171e68fc175f08ae171e68fc175f08ae171e68fc175f08ae171e68f m100e8=c175f08ae171e68fc175f08ae171e68fc175f08ae171e68fc175f08ae171e68fc175f08ae171e68fe275f08ae171e68f|ecx=0 esi=10086 edi=10106 f=44/0
  #|repe cmpsw|f366a7|CMPSW:%EDI,%ESI,%|eax=a18 ecx=3 edx=c10 f=887|ecx=2 esi=10082 edi=10102 f=80/0
  #|repne cmpsw|f266a7|CMPSW:%EDI,%ESI,%|eax=725f4368 ecx=3 f=846|ecx=0 esi=10086 edi=10106 f=1/0
  #|repne cmpsw|f266a7|CMPSW:%EDI,%ESI,%|ecx=3 f=813 m10068=3a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb7 m100e8=3a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb73a9a87d6febfacb7e19a87d6febfacb7|ecx=2 esi=10082 edi=10102 f=44/0
  #|repne cmpsw|f266a7|CMPSW:%EDI,%ESI,%|eax=60400b07 ecx=5 edx=d582d59a f=8d3 m10068=0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff m100e8=0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ff0987b975bb8a67ffb087b975bb8a67ff|ecx=4 esi=10082 edi=10102 f=44/0
  #|scasw|66af|SCASW:%EDI|eax=2dddb1e edx=ff f=4d6|edi=100fe f=480/0
  #|scasw|66af|SCASW:%EDI|eax=18ab8808 ecx=cdfcd1b8 edx=230a4219 f=c56 m100e8=088808880888088808880888088808880888088808880888088808880889088808880888088808880888088808880888|edi=100fe f=444/0
  #|scasw|66af|SCASW:%EDI|eax=d7e77162 ecx=bc4f90c9 edx=c218da53 f=8d7 m100e8=627162716271627162716271627162716271627162716271627162716271627162706271627162716271627162716271|edi=10102 f=44/0
  #|repe scasw|f366af|SCASW:%EDI|ecx=1 edx=4daa f=7|ecx=0 edi=10102 f=814/0
  #|repe scasw|f366af|SCASW:%EDI|eax=b4bcd54f ecx=3 f=816|ecx=2 edi=10102 f=84/0
  #|repe scasw|f366af|SCASW:%EDI|eax=bd27ac6 ecx=2 edx=80000000 f=486 m100e8=c67ac67ac67ac67ac67bc67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67ac67a|ecx=0 edi=100fc f=444/0
  #|repne scasw|f266af|SCASW:%EDI|eax=88d32aff ecx=3 f=413|ecx=0 edi=100fa f=c85/0
  #|repne scasw|f266af|SCASW:%EDI|eax=7fd611b9 ecx=3 edx=5 f=443 m100e8=b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b911b811|ecx=2 edi=100fe f=444/0
  #|repne scasw|f266af|SCASW:%EDI|eax=8187014f ecx=5 f=882 m100e8=4f014f014f014e014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f014f01|ecx=4 edi=10102 f=44/0
  #|movsd|a5|MOVSL:%EDI,%ESI,%|eax=9c60ccad ecx=a0aca9c f=7|esi=10084 edi=10104 f=5/0 m10100=8bb0d5fa
  #|movsd|a5|MOVSL:%EDI,%ESI,%|ecx=10f4485c edx=3c5e8d93 f=406|esi=1007c edi=100fc f=404/0 m10100=8bb0d5fa
  #|movsd|a5|MOVSL:%EDI,%ESI,%|eax=69610d4d f=8c2|esi=10084 edi=10104 f=8c0/0 m10100=8bb0d5fa
  #|rep movsd|f3a5|MOVSL:%EDI,%ESI,%|eax=80 ecx=3 edx=e8971623 f=53|ecx=0 esi=1008c edi=1010c f=51/0 m10100=8bb0d5fa1f44698eb3d8fd22
  #|rep movsd|f3a5|MOVSL:%EDI,%ESI,%|eax=1c5ce09a ecx=1 f=483|ecx=0 esi=1007c edi=100fc f=481/0 m10100=8bb0d5fa
  #|rep movsd|f3a5|MOVSL:%EDI,%ESI,%|eax=eb13d4d1 ecx=1 edx=17c071c4 f=82|ecx=0 esi=10084 edi=10104 f=80/0 m10100=8bb0d5fa
  #|stosd|ab|STOSL:%EDI|eax=8000 edx=ce6dd414 f=c46|edi=100fc f=c44/0 m10100=00800000
  #|stosd|ab|STOSL:%EDI|eax=29f646a3 ecx=c5b73d45 edx=c8fb f=842|edi=10104 f=840/0 m10100=a346f629
  #|stosd|ab|STOSL:%EDI|ecx=e61989c5 edx=78ac35aa f=803|edi=10104 f=801/0 m10100=b597f1d3
  #|rep stosd|f3ab|STOSL:%EDI|eax=a5608a11 ecx=0 f=92|f=90/0
  #|rep stosd|f3ab|STOSL:%EDI|ecx=5 f=46|ecx=0 edi=10114 f=44/0 m10100=b597f1d3b597f1d3b597f1d3b597f1d3b597f1d3
  #|rep stosd|f3ab|STOSL:%EDI|ecx=2 edx=34b55fd2 f=c7|ecx=0 edi=10108 f=c5/0 m10100=b597f1d3b597f1d3
  #|lodsd|ad|LODSL:%ESI,%|eax=391fd080 f=7|eax=fad5b08b esi=10084 f=5/0
  #|lodsd|ad|LODSL:%ESI,%|eax=85beffff f=c97|eax=fad5b08b esi=1007c f=c95/0
  #|lodsd|ad|LODSL:%ESI,%|ecx=f533 edx=b8 f=817|eax=fad5b08b esi=10084 f=815/0
  #|cmpsd|a7|CMPSL:%EDI,%ESI,%|eax=d25c6886 edx=8cdb219b f=c57 m10068=566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36 m100e8=566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db36566af4ca2fc6db367c6af4ca2fc6db36|esi=1007c edi=100fc f=444/0
  #|cmpsd|a7|CMPSL:%EDI,%ESI,%|eax=7fff ecx=9ee3b7aa edx=1 f=c57|esi=1007c edi=100fc f=480/0
  #|cmpsd|a7|CMPSL:%EDI,%ESI,%|eax=fbfc1f12 ecx=7fffffff f=2 m10068=891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5 m100e8=891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5891d0c6ac7b982c5bb1d0c6ac7b982c5|esi=10084 edi=10104 f=44/0
  #|repe cmpsd|f3a7|CMPSL:%EDI,%ESI,%|ecx=0 edx=8ca6146a f=d7|f=d5/0
  #|repe cmpsd|f3a7|CMPSL:%EDI,%ESI,%|eax=3aac28b1 ecx=3 edx=5089da34 f=897|ecx=2 esi=10084 edi=10104 f=80/0
  #|repe cmpsd|f3a7|CMPSL:%EDI,%ESI,%|eax=1f78dc7f ecx=5 edx=5fb85900 f=817 m10068=dd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5de m100e8=dd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5dedd12d568b53cd5de0612d568b53cd5de|ecx=0 esi=10094 edi=10114 f=4/0
  #|repne cmpsd|f2a7|CMPSL:%EDI,%ESI,%|eax=ff439bd5 ecx=0 edx=f25fc203 f=96|f=94/0
  #|repne cmpsd|f2a7|CMPSL:%EDI,%ESI,%|ecx=2 edx=37450a22 f=d2|ecx=0 esi=10088 edi=10108 f=800/0
  #|repne cmpsd|f2a7|CMPSL:%EDI,%ESI,%|eax=80000000 ecx=5 edx=ffffffff f=c06|ecx=0 esi=1006c edi=100ec f=480/0
  #|scasd|af|SCASL:%EDI|eax=d251e4b4 ecx=2049f688 edx=279d9701 f=886|edi=10104 f=814/0
  #|scasd|af|SCASL:%EDI|eax=de9c0d85 ecx=8 edx=65d6b21a f=883 m100e8=850d9cde850d9cde850d9cde850d9cde840d9cde850d9cde850d9cde850d9cde850d9cde850d9cde850d9cde850d9cde|edi=10104 f=44/0
  #|scasd|af|SCASL:%EDI|eax=e63cac2f ecx=d788ec85 edx=fffffffe f=c83 m100e8=2fac3ce62eac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce62fac3ce6|edi=100fc f=444/0
  #|repe scasd|f3af|SCASL:%EDI|eax=50e3fa7e ecx=3 edx=8c9d751b f=c83|ecx=2 edi=100fc f=481/0
  #|repe scasd|f3af|SCASL:%EDI|eax=7 ecx=1 f=d2|ecx=0 edi=10104 f=95/0
  #|repe scasd|f3af|SCASL:%EDI|eax=47a02b3f ecx=1 edx=a406e959 f=452|ecx=0 edi=100fc f=481/0
  #|repne scasd|f2af|SCASL:%EDI|eax=ff6c8c0f ecx=5 edx=343ecf71 f=c2|ecx=0 edi=10114 f=4/0
  #|repne scasd|f2af|SCASL:%EDI|eax=466237d7 ecx=2 edx=78bfe3d5 f=496|ecx=0 edi=100f8 f=405/0
  #|repne scasd|f2af|SCASL:%EDI|eax=87bfc25e ecx=5 edx=a2f977f f=cd2|ecx=0 edi=100ec f=c04/0
