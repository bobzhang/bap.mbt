///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn system(name : String) -> @primus.System {
  @primus_x86.register() |> ignore
  @primus.System::define_(name, components=[
    @primus.System::component(@primus_x86.registers_component, pkg="bap"),
    @primus.System::component(@primus_x86.plt_component, pkg="bap"),
  ])
}

///|
fn read(m : @primus.Machine, v : @types.Var) -> String {
  let x = @primus.Env::get(m, v) catch { e => return @primus.exn_to_string(e) }
  x.to_word().to_hex()
}

///|
test "registers and flags are initialized to zero" {
  let proj = @project.Project::empty(@core_theory.Target::x86_64())
  let log = []
  let (status, _) = system("x86-test-regs-64").run(proj, start=m => {
    for v in ["YMM15", "GS_BASE", "CF", "DF"] {
      let typ : @types.ValueType = if v.length() == 2 {
        Imm(1)
      } else if v.has_prefix("YMM") {
        Imm(256)
      } else {
        Imm(64)
      }
      log.push("\{v}=\{read(m, @types.Var::create(v, typ))}")
    }
  })
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "YMM15=0x0000000000000000000000000000000000000000000000000000000000000000",
      #|  "GS_BASE=0x0000000000000000",
      #|  "CF=0x0",
      #|  "DF=0x0",
      #|]
    ),
  )
  let proj = @project.Project::empty(@core_theory.Target::x86())
  let log = []
  let (_, _) = system("x86-test-regs-32").run(proj, start=m => {
    log.push(read(m, @types.Var::create("YMM7", Imm(256))))
    log.push(read(m, @types.Var::create("YMM8", Imm(256))))
    log.push(read(m, @types.Var::create("FS_BASE", Imm(32))))
  })
  debug_inspect(
    log,
    content=(
      #|[
      #|  "0x0000000000000000000000000000000000000000000000000000000000000000",
      #|  "undefined variable `YMM8'",
      #|  "0x00000000",
      #|]
    ),
  )
  debug_inspect(
    [
      @primus_x86.mode_of_target(@core_theory.Target::x86_64()),
      @primus_x86.mode_of_target(@core_theory.Target::i386()),
      @primus_x86.mode_of_target(@core_theory.Target::arm()),
    ],
    content=(
      #|[Some(AMD64), Some(IA32), None]
    ),
  )
}

///|
test "PLT entries are unresolved and stubs pop the return address" {
  // .plt at 0x1000 (16 bytes), .got.plt at 0x2000 with two entries: one
  // pointing into .plt (0x1006) and one outside of it (0x5000)
  let got = Bytes::makei(16, i => {
    let x = if i < 8 { 0x1006 } else { 0x5000 }
    if i % 8 < 4 {
      ((x >> (8 * (i % 8))) & 0xff).to_byte()
    } else {
      b'\x00'
    }
  })
  let plt_seg = @image.Segment::create(
    name="plt",
    endian=LittleEndian,
    addr=0x1000UL,
    Bytes::make(16, b'\x90'),
    executable=true,
  )
  let got_seg = @image.Segment::create(
    name="got",
    endian=LittleEndian,
    addr=0x2000UL,
    got,
    writable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x1000UL,
    endian=LittleEndian,
    [plt_seg, got_seg],
    sections=[
      @image.Section::create(name=".plt", addr=0x1000UL, size=16),
      @image.Section::create(name=".got.plt", addr=0x2000UL, size=16),
    ],
    target=@core_theory.Target::x86_64(),
  )
  let intrinsic = @types.Sub::create(name="llvm.trap").with_intrinsic()
  let proj = @project.Project::from_image(
    image,
    target=@core_theory.Target::x86_64(),
  ).with_program(@types.Program::create(subs=[intrinsic]))
  let log = []
  let rsp = @types.Var::create("RSP", Imm(64))
  let (status, _) = system("x86-test-plt").run(
    proj,
    init=m => {
      @primus.Linker::link(
        m,
        name=@primus.unresolved_handler,
        Host(_ => log.push("unresolved")),
      )
      @primus.Env::set(m, rsp, @primus.Value::of_word(m, w64(0x100)))
    },
    start=m => {
      log.push(
        "linked 0x1006: \{@primus.Linker::is_linked(m, Addr(w64(0x1006)))}",
      )
      log.push(
        "linked 0x5000: \{@primus.Linker::is_linked(m, Addr(w64(0x5000)))}",
      )
      @primus.Linker::exec(m, Addr(w64(0x1006)))
      m.make(@primus.lisp_call_returned, ("puts", []))
      log.push("RSP=\{read(m, rsp)}")
      m.make(@primus.lisp_call_returned, ("llvm.trap", []))
      log.push("RSP=\{read(m, rsp)}")
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "linked 0x1006: true",
      #|  "linked 0x5000: false",
      #|  "unresolved",
      #|  "RSP=0x0000000000000108",
      #|  "RSP=0x0000000000000108",
      #|]
    ),
  )
}
