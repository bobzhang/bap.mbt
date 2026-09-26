// Tests of the `resolve-indirects` pass.

///|
fn word(width : Int, v : Int) -> @types.Word {
  @types.Word::of_int(width~, v) catch {
    _ => panic()
  }
}

///|
fn load(
  addr : @types.Exp,
  bits : Int,
  endian? : @bitvec.Endian = LittleEndian,
) -> @types.Exp {
  Load(mem=@types.Exp::var_exp(mem_var()), addr~, endian~, typ=Imm(bits))
}

///|
fn mem_var() -> @types.Var {
  @types.Var::new(name="mem", typ=Mem(addr_width=32, value_width=8))
}

///|
fn const_(v : Int) -> @types.Exp {
  @types.Exp::int(word(32, v))
}

///|
/// A project whose memory has a little-endian region at 0x1000 holding
/// `04 10 00 00 11 22 33 44` and a big-endian region at 0x3000 holding
/// `aa bb cc dd`.
fn project_with(
  defs : Array[(String, @types.Exp)],
  cond? : @types.Exp,
) -> @project.Project {
  let le = @memory.Memory::create(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x04\x10\x00\x00\x11\x22\x33\x44",
  ).unwrap()
  let be = @memory.Memory::create(
    endian=BigEndian,
    start=0x3000UL,
    b"\xaa\xbb\xcc\xdd",
  ).unwrap()
  let memory = @memory.MemMap::empty().add(le, "le").add(be, "be")
  let defs = defs.map(d => {
    @types.Def::create(@types.Var::new(name=d.0, typ=Imm(32)), d.1)
  })
  let jmps = match cond {
    Some(c) => [@types.Jmp::create_goto(Indirect(c), cond=c)]
    None => []
  }
  let blk = @types.Blk::create(defs~, jmps~)
  let sub = @types.Sub::create(name="f", blks=[blk])
  @project.Project::create(
    target=@core_theory.Target::i386(),
    memory~,
    program=@types.Program::create(subs=[sub]),
  )
}

///|
fn render(project : @project.Project) -> String {
  let lines = []
  for sub in project.program().subs() {
    for blk in sub.blks() {
      for def in blk.defs() {
        lines.push("\{def.lhs().to_string()} := \{def.rhs().to_string()}")
      }
      for jmp in blk.jmps() {
        lines.push("when \{@types.Jmp::cond(jmp).to_string()}")
      }
    }
  }
  lines.join("\n")
}

///|
test "constant-address loads are replaced with the memory contents" {
  let project = project_with(
    [
      ("a", load(const_(0x1004), 32)),
      ("b", load(const_(0x1004), 16)),
      ("c", load(const_(0x1005), 8)),
      ("d", load(const_(0x3000), 32)),
      // the endianness of the region wins over the one of the load
      ("e", load(const_(0x3000), 16, endian=LittleEndian)),
      ("f", @types.Exp::binop(Plus, load(const_(0x1000), 32), const_(1))),
      // no region, the word crosses the end of a region, and a non-constant
      // address
      ("g", load(const_(0x2000), 32)),
      ("h", load(const_(0x1006), 32)),
      (
        "i",
        load(@types.Exp::var_exp(@types.Var::new(name="p", typ=Imm(32))), 32),
      ),
      // the outer address is not a constant before its load is resolved
      ("j", load(load(const_(0x1000), 32), 8)),
    ],
    cond=@types.Exp::binop(Eq, load(const_(0x1004), 8), const_(0x11)),
  )
  let resolved = @resolve_indirects.run(project)
  inspect(
    render(resolved),
    content=(
      #|a:imm32 := 0x44332211:32u
      #|b:imm32 := 0x2211:16u
      #|c:imm32 := 0x22:8u
      #|d:imm32 := 0xAABBCCDD:32u
      #|e:imm32 := 0xAABB:16u
      #|f:imm32 := (0x1004:32u + 1:32u)
      #|g:imm32 := load(mem:mem32x8, 0x2000:32u):imm32
      #|h:imm32 := load(mem:mem32x8, 0x1006:32u):imm32
      #|i:imm32 := load(mem:mem32x8, p:imm32):imm32
      #|j:imm32 := load(mem:mem32x8, 0x1004:32u):imm8
      #|when (0x11:8u == 0x11:32u)
    ),
  )
  // running the pass again resolves the load that became constant
  inspect(
    render(@resolve_indirects.run(resolved))
    .split("\n")
    .filter(l => l.has_prefix("j"))
    .map(l => l.to_owned())
    .collect()
    .join("\n"),
    content=(
      #|j:imm32 := 0x11:8u
    ),
  )
}

///|
test "the pass is registered under its upstream name" {
  let pass = @resolve_indirects.pass()
  inspect(pass.name(), content="resolve-indirects")
  inspect(pass.autorun(), content="false")
  let project = project_with([("a", load(const_(0x1004), 32))])
  guard pass.run(project) is Ok(p) else { fail("the pass failed") }
  inspect(
    render(p),
    content=(
      #|a:imm32 := 0x44332211:32u
    ),
  )
}
