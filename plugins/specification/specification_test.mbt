///|
fn run_bap(argv : Array[String]) -> String {
  @bap_main.reset()
  @bap_main.set_file_system(
    @fixtures.file_system([("bin/true", @fixtures.x86_64_elf())]),
  )
  let buf = StringBuilder()
  try {
    @specification.declare_plugin(out=s => buf.write_string(s))
    @bap_main.initialize(argv=["bap", ..argv], out=s => buf.write_string(s), err=s => {
      buf.write_string(s)
    })
  } catch {
    e => buf.write_string(@bap_main.error_to_string(e))
  }
  @bap_main.reset()
  buf.to_string()
}

///|
test "specification prints the ogre specification" {
  inspect(
    run_bap(["specification", "bin/true"]),
    content=(
      #|(declare abi (name str))
      #|(declare arch (name str))
      #|(declare bits (size int))
      #|(declare code-start (addr int))
      #|(declare entry-point (addr int))
      #|(declare format (name str))
      #|(declare is-little-endian (flag bool))
      #|(declare llvm:code-entry (name str) (off int) (size int))
      #|(declare llvm:elf-program-header (name str) (off int) (size int))
      #|(declare llvm:elf-program-header-flags (name str) (ld bool) (r bool) 
      #| (w bool) (x bool))
      #|(declare llvm:elf-virtual-program-header (name str) (addr int) (size int))
      #|(declare llvm:entry-point (addr int))
      #|(declare llvm:section-entry (name str) (addr int) (size int) (off int))
      #|(declare llvm:section-flags (name str) (r bool) (w bool) (x bool))
      #|(declare mapped (addr int) (size int) (off int))
      #|(declare named-region (addr int) (size int) (name str))
      #|(declare named-symbol (addr int) (name str))
      #|(declare section (addr int) (size int))
      #|(declare segment (addr int) (size int) (r bool) (w bool) (x bool))
      #|(declare symbol-chunk (addr int) (size int) (root int))
      #|
      #|(abi sysv)
      #|(arch x86_64)
      #|(bits 64)
      #|(code-start 4198400)
      #|(code-start 4198414)
      #|(entry-point 4198400)
      #|(format elf)
      #|(is-little-endian true)
      #|(llvm:code-entry .text 4096 17)
      #|(llvm:elf-program-header 00 4096 17)
      #|(llvm:elf-program-header-flags 00 true true false true)
      #|(llvm:elf-virtual-program-header 00 4198400 17)
      #|(llvm:entry-point 4198400)
      #|(llvm:section-entry .shstrtab 0 33 4195)
      #|(llvm:section-entry .strtab 0 10 4185)
      #|(llvm:section-entry .symtab 0 72 4113)
      #|(llvm:section-entry .text 4198400 17 4096)
      #|(llvm:section-flags .shstrtab true false false)
      #|(llvm:section-flags .strtab true false false)
      #|(llvm:section-flags .symtab true false false)
      #|(llvm:section-flags .text true false true)
      #|(mapped 4198400 17 4096)
      #|(named-region 4198400 17 .load0)
      #|(named-region 4198400 17 .text)
      #|(named-region 0 72 .symtab)
      #|(named-region 0 10 .strtab)
      #|(named-region 0 33 .shstrtab)
      #|(named-symbol 4198400 main)
      #|(named-symbol 4198414 foo)
      #|(section 4198400 17)
      #|(section 0 72)
      #|(section 0 10)
      #|(section 0 33)
      #|(segment 4198400 17 true false true)
      #|(symbol-chunk 4198400 11 4198400)
      #|(symbol-chunk 4198414 3 4198414)
      #|
      #|
    ),
  )
  inspect(
    run_bap(["specification", "-oyaml", "bin/true"]),
    content=(
      #|scheme:
      #|  "abi" : {"name" : str}
      #|  "arch" : {"name" : str}
      #|  "bits" : {"size" : int}
      #|  "code-start" : {"addr" : int}
      #|  "entry-point" : {"addr" : int}
      #|  "format" : {"name" : str}
      #|  "is-little-endian" : {"flag" : bool}
      #|  "llvm:code-entry" : {"name" : str, "off" : int, "size" : int}
      #|  "llvm:elf-program-header" : {"name" : str, "off" : int, "size" : int}
      #|  "llvm:elf-program-header-flags" : {"name" : str, "ld" : bool, "r" : bool, "w" : bool, "x" : bool}
      #|  "llvm:elf-virtual-program-header" : {"name" : str, "addr" : int, "size" : int}
      #|  "llvm:entry-point" : {"addr" : int}
      #|  "llvm:section-entry" : {"name" : str, "addr" : int, "size" : int, "off" : int}
      #|  "llvm:section-flags" : {"name" : str, "r" : bool, "w" : bool, "x" : bool}
      #|  "mapped" : {"addr" : int, "size" : int, "off" : int}
      #|  "named-region" : {"addr" : int, "size" : int, "name" : str}
      #|  "named-symbol" : {"addr" : int, "name" : str}
      #|  "section" : {"addr" : int, "size" : int}
      #|  "segment" : {"addr" : int, "size" : int, "r" : bool, "w" : bool, "x" : bool}
      #|  "symbol-chunk" : {"addr" : int, "size" : int, "root" : int}
      #|"abi":
      #|  - "name": "sysv"
      #|"arch":
      #|  - "name": "x86_64"
      #|"bits":
      #|  - "size": 64
      #|"code-start":
      #|  - "addr": 4198400
      #|  - "addr": 4198414
      #|"entry-point":
      #|  - "addr": 4198400
      #|"format":
      #|  - "name": "elf"
      #|"is-little-endian":
      #|  - "flag": true
      #|"llvm:code-entry":
      #|  - "name": ".text"
      #|    "off": 4096
      #|    "size": 17
      #|"llvm:elf-program-header":
      #|  - "name": "00"
      #|    "off": 4096
      #|    "size": 17
      #|"llvm:elf-program-header-flags":
      #|  - "name": "00"
      #|    "ld": true
      #|    "r": true
      #|    "w": false
      #|    "x": true
      #|"llvm:elf-virtual-program-header":
      #|  - "name": "00"
      #|    "addr": 4198400
      #|    "size": 17
      #|"llvm:entry-point":
      #|  - "addr": 4198400
      #|"llvm:section-entry":
      #|  - "name": ".shstrtab"
      #|    "addr": 0
      #|    "size": 33
      #|    "off": 4195
      #|  - "name": ".strtab"
      #|    "addr": 0
      #|    "size": 10
      #|    "off": 4185
      #|  - "name": ".symtab"
      #|    "addr": 0
      #|    "size": 72
      #|    "off": 4113
      #|  - "name": ".text"
      #|    "addr": 4198400
      #|    "size": 17
      #|    "off": 4096
      #|"llvm:section-flags":
      #|  - "name": ".shstrtab"
      #|    "r": true
      #|    "w": false
      #|    "x": false
      #|  - "name": ".strtab"
      #|    "r": true
      #|    "w": false
      #|    "x": false
      #|  - "name": ".symtab"
      #|    "r": true
      #|    "w": false
      #|    "x": false
      #|  - "name": ".text"
      #|    "r": true
      #|    "w": false
      #|    "x": true
      #|"mapped":
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "off": 4096
      #|"named-region":
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "name": ".load0"
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "name": ".text"
      #|  - "addr": 0
      #|    "size": 72
      #|    "name": ".symtab"
      #|  - "addr": 0
      #|    "size": 10
      #|    "name": ".strtab"
      #|  - "addr": 0
      #|    "size": 33
      #|    "name": ".shstrtab"
      #|"named-symbol":
      #|  - "addr": 4198400
      #|    "name": "main"
      #|  - "addr": 4198414
      #|    "name": "foo"
      #|"section":
      #|  - "addr": 4198400
      #|    "size": 17
      #|  - "addr": 0
      #|    "size": 72
      #|  - "addr": 0
      #|    "size": 10
      #|  - "addr": 0
      #|    "size": 33
      #|"segment":
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "r": true
      #|    "w": false
      #|    "x": true
      #|"symbol-chunk":
      #|  - "addr": 4198400
      #|    "size": 11
      #|    "root": 4198400
      #|  - "addr": 4198414
      #|    "size": 3
      #|    "root": 4198414
      #|
      #|
    ),
  )
}

///|
test "specification reports problems" {
  inspect(
    run_bap(["specification", "bin/false"]),
    content=(
      #|Failed to load the binary: unable to read the file bin/false
    ),
  )
  inspect(
    run_bap(["specification", "--loader=nope", "bin/true"]),
    content=(
      #|The loader `nope' is not registers, known loaders are: raw, ogre, elf, macho, coff, llvm.
    ),
  )
}
