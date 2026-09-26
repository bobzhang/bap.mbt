///|
test "a function at address 0 is named after its symbol" {
  // objects put the first function at address 0, where compilers also
  // emit local labels (RISC-V `.L0 `) and data symbols
  let project = @project.Project::empty(@core_theory.Target::riscv64()).with_symbols([
      @image.Symbol::create(name=".L0 ", addr=0UL),
      @image.Symbol::create(name="sq", addr=0UL, is_function=true),
      @image.Symbol::create(name=".L0 ", addr=6UL),
      @image.Symbol::create(name="f", addr=6UL, is_function=true),
      @image.Symbol::create(name="table", addr=0x40UL),
    ],
  )
  let symbolizer = project.symbolizer()
  assert_eq(symbolizer.run(0UL), Some("sq"))
  assert_eq(symbolizer.run(6UL), Some("f"))
  assert_eq(symbolizer.run(0x40UL), Some("table"))
  assert_eq(symbolizer.resolve(0UL), "sq")
}
