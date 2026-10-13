///|
fn w64(n : Int64) -> @types.Word {
  try! @types.Word::of_int64(n, width=64)
}

///|
fn read_var(m : @primus.Machine, name : String) -> String raise {
  let v = @types.Var::create(name, Imm(64))
  @primus.Env::get(m, v).to_word().to_hex()
}

///|
fn read_u64(m : @primus.Machine, addr : @types.Word) -> UInt64 raise {
  let mut x = 0UL
  for i in 0..<8 {
    let b = @primus.Memory::load(m, addr.nsucc(i)).to_uint64()
    x = x | (b << (8 * i))
  }
  x
}

///|
fn read_cstring(m : @primus.Machine, addr : @types.Word) -> String raise {
  let buf = StringBuilder()
  for a = addr {
    let b = @primus.Memory::load(m, a).to_uint64().to_int()
    if b == 0 {
      break
    }
    buf.write_char(Int32::unsafe_to_char(b))
    continue a.succ()
  }
  buf.to_string()
}

///|
fn test_project() -> @project.Project {
  let data = @image.Segment::create(
    name=".data",
    endian=LittleEndian,
    addr=0x1000UL,
    Bytes::make(16, b'\x11'),
    writable=true,
    executable=false,
  )
  let text = @image.Segment::create(
    name=".text",
    endian=LittleEndian,
    addr=0x2000UL,
    Bytes::make(8, b'\x90'),
    writable=false,
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x2000UL,
    endian=LittleEndian,
    [data, text],
    target=@core_theory.Target::x86_64(),
    // the loader reads segments and relocations from the specification
    spec=try! @ogre.Doc::from_string(
      "(declare segment (addr int) (size int) (r bool) (w bool) (x bool))" +
      " (declare relocation (fixup int) (addr int))" +
      " (declare relative-relocation (fixup int))" +
      " (declare base-address (addr int))" +
      " (segment 4096 16 true true false)" +
      " (segment 8192 8 true false true)" +
      " (segment 12288 32 true true false)" +
      " (relocation 4104 8196)" +
      " (base-address 65536)" +
      " (relative-relocation 4096)",
    ),
  )
  let main = @types.Sub::create(name="main", tid=@types.Tid::for_name("main"), blks=[]).set_attr(
    @types.Attr::address(w64(0x2000L)),
  )
  @project.Project::from_image(image, target=@core_theory.Target::x86_64()).with_program(
    @types.Program::create(subs=[main]),
  )
}

///|
test "the loader sets up the stack, the main frame, segments and variables" {
  let log = []
  let (status, _) = @primus.Machine::run(
    test_project(),
    args=["prog", "-v"],
    envp=["HOME=/root"],
    boot=m => @primus_loader.install(m, stack_size=0x1000),
    start=m => {
      let rsp = @primus.Env::get(m, @types.Var::create("RSP", Imm(64))).to_word()
      log.push("RSP=\{rsp.to_hex()}")
      log.push(
        "stack mapped: \{@primus.Memory::is_mapped(m, rsp.npred(0x1000))} \{@primus.Memory::is_mapped(m, rsp.npred(0x1001))}",
      )
      let argc = read_u64(m, rsp)
      log.push("argc=\{argc}")
      for i in 0..<argc.to_int() {
        let p = read_u64(m, rsp.nsucc(8 + 8 * i))
        log.push("argv[\{i}]=\{read_cstring(m, w64(p.reinterpret_as_int64()))}")
      }
      log.push("argv[argc]=\{read_u64(m, rsp.nsucc(8 + 8 * argc.to_int()))}")
      let environ = @primus.Env::get(
        m,
        @types.Var::create("posix:environ", Imm(64)),
      ).to_word()
      let e0 = read_u64(m, environ)
      log.push("environ[0]=\{read_cstring(m, w64(e0.reinterpret_as_int64()))}")
      log.push("environ[1]=\{read_u64(m, environ.nsucc(8))}")
      log.push(
        "brk=\{read_var(m, "posix:brk")} endp=\{read_var(m, "posix:endp")}",
      )
      log.push("etext=\{read_var(m, "etext")} edata=\{read_var(m, "edata")}")
      // the relocation is applied to the data segment
      log.push("reloc=\{read_u64(m, w64(0x1008L)).to_string(radix=16)}")
      log.push("relative=\{read_u64(m, w64(0x1000L)).to_string(radix=16)}")
      // a segment without data (bss) is zero-filled
      log.push("bss=\{@primus.Memory::load(m, w64(0x3010L)).to_hex()}")
      log.push("text writable: \{@primus.Memory::is_writable(m, w64(0x2000L))}")
      log.push("data writable: \{@primus.Memory::is_writable(m, w64(0x1000L))}")
      // registers are zero
      log.push("RAX=\{read_var(m, "RAX")}")
      // subroutines and blocks with addresses are named by their term names
      log.push("@main=\{read_var(m, "@main")}")
    },
  )
  inspect(
    status,
    content=(
      #|Normal
    ),
  )
  debug_inspect(
    log,
    content=(
      #|[
      #|  "RSP=0x0000000040000000",
      #|  "stack mapped: true false",
      #|  "argc=2",
      #|  "argv[0]=prog",
      #|  "argv[1]=-v",
      #|  "argv[argc]=0",
      #|  "environ[0]=HOME=/root",
      #|  "environ[1]=0",
      #|  "brk=0x0000000000003020 endp=0x0000000000003020",
      #|  "etext=0x0000000000002007 edata=0x000000000000100f",
      #|  "reloc=2004",
      #|  "relative=1111111111121111",
      #|  "bss=0x00",
      #|  "text writable: false",
      #|  "data writable: true",
      #|  "RAX=0x0000000000000000",
      #|  "@main=0x0000000000002000",
      #|]
    ),
  )
}

///|
test "the loader component is registered once" {
  assert_true(@primus_loader.register())
  assert_false(@primus_loader.register())
  debug_inspect(
    @primus_loader.stack_pointer(@core_theory.Target::x86()).map(v => v.name()),
    content=(
      #|Some("ESP")
    ),
  )
}
