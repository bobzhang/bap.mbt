///|
test "byteweight finds the trained function starts" {
  let mem = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start=0x401000UL,
    @fixtures.x86_64_code,
  )
  let starts = [0x401000UL, 0x40100eUL]
  let sigs = @bw.Byteweight::create().train(
    max_length=4,
    m => starts.contains(m.min_addr()),
    mem,
  )
  debug_inspect(
    @byteweight.find_roots(
      sigs,
      [mem],
      min_length=1,
      max_length=4,
      threshold=0.5,
    ).map(a => a.to_string(radix=16)),
    content=(
      #|["401000"]
    ),
  )
}

///|
test "the plugin registers a root provider only when enabled" {
  @bap_main.reset()
  @byteweight.declare_plugin()
  @bap_main.initialize(argv=["bap", "--byteweight-enabled"])
  @bap_main.reset()
  @byteweight.declare_plugin()
  @bap_main.initialize(argv=["bap"])
  @bap_main.reset()
}
