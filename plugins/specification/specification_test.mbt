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
      #|(code-start 4198414)
      #|(code-start 4198400)
      #|(entry-point 4198400)
      #|(format elf)
      #|(is-little-endian true)
      #|(mapped 4198400 17 4096)
      #|(named-region 0 33 .shstrtab)
      #|(named-region 0 10 .strtab)
      #|(named-region 0 72 .symtab)
      #|(named-region 4198400 17 .text)
      #|(named-region 4198400 17 .load0)
      #|(named-symbol 4198414 foo)
      #|(named-symbol 4198400 main)
      #|(section 0 33)
      #|(section 0 10)
      #|(section 0 72)
      #|(section 4198400 17)
      #|(segment 4198400 17 true false true)
      #|(symbol-chunk 4198414 3 4198414)
      #|(symbol-chunk 4198400 11 4198400)
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
      #|  - "addr": 4198414
      #|  - "addr": 4198400
      #|"entry-point":
      #|  - "addr": 4198400
      #|"format":
      #|  - "name": "elf"
      #|"is-little-endian":
      #|  - "flag": true
      #|"mapped":
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "off": 4096
      #|"named-region":
      #|  - "addr": 0
      #|    "size": 33
      #|    "name": ".shstrtab"
      #|  - "addr": 0
      #|    "size": 10
      #|    "name": ".strtab"
      #|  - "addr": 0
      #|    "size": 72
      #|    "name": ".symtab"
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "name": ".text"
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "name": ".load0"
      #|"named-symbol":
      #|  - "addr": 4198414
      #|    "name": "foo"
      #|  - "addr": 4198400
      #|    "name": "main"
      #|"section":
      #|  - "addr": 0
      #|    "size": 33
      #|  - "addr": 0
      #|    "size": 10
      #|  - "addr": 0
      #|    "size": 72
      #|  - "addr": 4198400
      #|    "size": 17
      #|"segment":
      #|  - "addr": 4198400
      #|    "size": 17
      #|    "r": true
      #|    "w": false
      #|    "x": true
      #|"symbol-chunk":
      #|  - "addr": 4198414
      #|    "size": 3
      #|    "root": 4198414
      #|  - "addr": 4198400
      #|    "size": 11
      #|    "root": 4198400
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
      #|The loader `nope' is not registers, known loaders are: raw, ogre, elf.
    ),
  )
}
