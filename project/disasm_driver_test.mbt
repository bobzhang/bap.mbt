///|
/// push rbp; call 0x1010; test eax, eax; je 0x100c; xor eax, eax;
/// pop rbp; ret; nop; nop; xor eax, eax; ret
fn driver_test_code() -> @memory.Memory {
  @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x1000UL,
    b"\x55\xe8\x0a\x00\x00\x00\x85\xc0\x74\x02\x31\xc0\x5d\xc3\x90\x90\x31\xc0\xc3",
  )
}

///|
fn driver_test_hex(addrs : Array[UInt64]) -> String {
  addrs.map(addr => addr.to_string(radix=16)).join(" ")
}

///|
fn driver_test_jumps(driver : @project.ProjectDisassemblyDriverState) -> String {
  let lines = []
  for addr in 0x1000UL..<0x1013UL {
    match driver.jump(addr) {
      Some(jump) =>
        lines.push(
          "\{addr.to_string(radix=16)} -> [\{driver_test_hex(jump.destinations())}] call=\{jump.is_call()} barrier=\{jump.is_barrier()} indirect=\{jump.is_indirect()}",
        )
      None => ()
    }
  }
  lines.join("\n")
}

///|
test "the incremental disassembler scans memory into blocks, jumps and subroutines" {
  let kb = @knowledge.State::new()
  let code = driver_test_code()
  let unit = @core_theory.ProgramUnit::for_file(
    "driver-test",
    target=@core_theory.Target::x86_64(),
  )
  let driver = @core_theory.Label::unit_slot().promising(
    promise=(_, _) => Some(unit),
    () => @project.ProjectDisassemblyDriverState::init().scan(code, kb),
  )
  inspect(
    driver_test_hex(driver.blocks()),
    content=(
      #|1000 100c 100e 1010 1013
    ),
  )
  // the call destination is a subroutine
  inspect(driver_test_hex(driver.subroutines()), content="1010")
  inspect(
    driver_test_jumps(driver),
    content=(
      #|1001 -> [1010] call=true barrier=false indirect=false
      #|1008 -> [100c] call=false barrier=false indirect=false
      #|100d -> [] call=false barrier=true indirect=true
      #|1012 -> [] call=false barrier=true indirect=true
    ),
  )
  assert_true(driver.is_block(0x100cUL))
  assert_true(driver.is_jump(0x1008UL))
  assert_true(driver.is_subroutine(0x1010UL))
  assert_true(!driver.is_data(0x1000UL))
  // the destination after the last return lies outside of the memory
  assert_eq(driver.debt_count(), 1)
  // scanning the same memory again changes nothing
  let again = driver.scan(code, kb)
  assert_true(again.equal(driver))
  // exploring from the start visits the blocks along the edges
  let visited = driver.explore(
    kb,
    entry=0x1000UL,
    init=[],
    block=(mem, insns) => (mem.min_addr(), insns.list().length()),
    node=(n, acc) => {
      acc.push("node \{n.0.to_string(radix=16)}/\{n.1}")
      acc
    },
    edge=(src, dst, acc) => {
      acc.push(
        "edge \{src.0.to_string(radix=16)}->\{dst.0.to_string(radix=16)}",
      )
      acc
    },
  )
  inspect(
    visited.join("\n"),
    content=(
      #|node 1000/2
      #|node 1006/2
      #|node 100a/1
      #|node 100c/2
      #|edge 100a->100c
      #|edge 1006->100a
      #|edge 1006->100c
      #|edge 1000->1006
      #|node 1010/2
      #|edge 1000->1010
    ),
  )
}
