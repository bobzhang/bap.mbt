///|
fn ct(name : String, lp64~ : Bool = false) -> @arm.CType {
  @arm.CType::arm_basic(name, lp64~).unwrap()
}

///|
fn layout32(ret : @arm.CType?, params : Array[@arm.CType]) -> String {
  match @arm.aapcs32_layout(ret, params) {
    None => "rejected"
    Some(l) => Repr(l).to_string()
  }
}

///|
fn layout64(ret : @arm.CType?, params : Array[@arm.CType]) -> String {
  match @arm.aapcs64_layout(ret, params) {
    None => "rejected"
    Some(l) => Repr(l).to_string()
  }
}

///|
test "C basic types of the ARM data models" {
  debug_inspect(
    @arm.CType::arm_basic("long"),
    content="Some({ kind: Integer, bits: 32, alignment: 32 })",
  )
  debug_inspect(
    @arm.CType::arm_basic("long", lp64=true),
    content="Some({ kind: Integer, bits: 64, alignment: 64 })",
  )
  debug_inspect(
    @arm.CType::arm_basic("long double"),
    content="Some({ kind: Floating, bits: 64, alignment: 64 })",
  )
  debug_inspect(@arm.CType::arm_basic("__int256"), content="None")
  // sizes are rounded up to the alignment
  debug_inspect(
    @arm.CType::new(Structure, bits=40, alignment=32),
    content="{ kind: Structure, bits: 64, alignment: 32 }",
  )
}

///|
test "AAPCS32 integer arguments and results" {
  // int f(int, char, short, int, int, int)
  inspect(
    layout32(Some(ct("int")), [
      ct("int"),
      ct("char"),
      ct("short"),
      ct("int"),
      ct("int"),
      ct("int"),
    ]),
    content=(
      #|{
      #|  return_value: Some(Registers(["R0"])),
      #|  params: [
      #|    Registers(["R0"]),
      #|    Registers(["R1"]),
      #|    Registers(["R2"]),
      #|    Registers(["R3"]),
      #|    Stack(offset=0, bits=32),
      #|    Stack(offset=4, bits=32),
      #|  ],
      #|  hidden: [],
      #|}
    ),
  )
  // long long f(int, long long): 64-bit values start at an even register
  inspect(
    layout32(Some(ct("long long")), [ct("int"), ct("long long")]),
    content=(
      #|{
      #|  return_value: Some(Registers(["R0", "R1"])),
      #|  params: [Registers(["R0"]), Registers(["R2", "R3"])],
      #|  hidden: [],
      #|}
    ),
  )
  // void f(double, float)
  inspect(
    layout32(None, [ct("double"), ct("float")]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [Registers(["R0", "R1"]), Registers(["R2"])],
      #|  hidden: [],
      #|}
    ),
  )
  // pointers are not basic types, but fit in a register
  inspect(
    layout32(Some(ct("pointer")), [ct("pointer")]),
    content=(
      #|{
      #|  return_value: Some(Registers(["R0"])),
      #|  params: [Registers(["R0"])],
      #|  hidden: [],
      #|}
    ),
  )
}

///|
test "AAPCS32 composite values" {
  let s12 = @arm.CType::new(Structure, bits=96, alignment=32)
  let s4 = @arm.CType::new(Structure, bits=32, alignment=32)
  // large structures are returned through a hidden reference in R0
  inspect(
    layout32(Some(s12), [ct("int")]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [Registers(["R1"])],
      #|  hidden: [Registers(["R0"])],
      #|}
    ),
  )
  inspect(
    layout32(Some(s4), []),
    content=(
      #|{ return_value: Some(Registers(["R0"])), params: [], hidden: [] }
    ),
  )
  // a structure that does not fit in the remaining registers is split
  inspect(
    layout32(None, [ct("int"), ct("int"), s12, ct("int")]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [
      #|    Registers(["R0"]),
      #|    Registers(["R1"]),
      #|    Split(regs=["R2", "R3"], bits=32),
      #|    Stack(offset=4, bits=32),
      #|  ],
      #|  hidden: [],
      #|}
    ),
  )
  // ... unless something is already on the stack
  inspect(
    layout32(None, [ct("int"), ct("int"), ct("int"), ct("int"), ct("int"), s12]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [
      #|    Registers(["R0"]),
      #|    Registers(["R1"]),
      #|    Registers(["R2"]),
      #|    Registers(["R3"]),
      #|    Stack(offset=0, bits=32),
      #|    Stack(offset=4, bits=96),
      #|  ],
      #|  hidden: [],
      #|}
    ),
  )
  // upstream cannot align a 64-bit value when only R3 is left
  inspect(
    layout32(None, [ct("int"), ct("int"), ct("int"), ct("double")]),
    content="rejected",
  )
}

///|
test "AAPCS64 layouts" {
  let l = (name : String) => ct(name, lp64=true)
  inspect(
    layout64(Some(l("long")), [
      l("int"),
      l("long"),
      l("pointer"),
      l("char"),
      l("short"),
      l("long long"),
      l("int"),
      l("int"),
      l("int"),
      l("int"),
    ]),
    content=(
      #|{
      #|  return_value: Some(Registers(["R0"])),
      #|  params: [
      #|    Registers(["R0"]),
      #|    Registers(["R1"]),
      #|    Registers(["R2"]),
      #|    Registers(["R3"]),
      #|    Registers(["R4"]),
      #|    Registers(["R5"]),
      #|    Registers(["R6"]),
      #|    Registers(["R7"]),
      #|    Stack(offset=0, bits=32),
      #|    Stack(offset=8, bits=32),
      #|  ],
      #|  hidden: [],
      #|}
    ),
  )
  let s24 = @arm.CType::new(Structure, bits=192, alignment=64)
  let s16 = @arm.CType::new(Structure, bits=128, alignment=64)
  let i128 = @arm.CType::new(Integer, bits=128, alignment=128)
  // large composites are passed and returned by reference
  inspect(
    layout64(Some(s24), [s24, s16]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [Registers(["R1", "R2"])],
      #|  hidden: [Registers(["X8"]), Registers(["R0"])],
      #|}
    ),
  )
  // 128-bit aligned values start at an even register
  inspect(
    layout64(Some(i128), [l("int"), i128]),
    content=(
      #|{
      #|  return_value: Some(Registers(["R0", "R1"])),
      #|  params: [Registers(["R0"]), Registers(["R2", "R3"])],
      #|  hidden: [],
      #|}
    ),
  )
  // floating-point values go through the (empty) floating arena
  inspect(
    layout64(Some(l("double")), [l("float")]),
    content=(
      #|{
      #|  return_value: None,
      #|  params: [],
      #|  hidden: [Registers(["X8"]), Registers(["R0"])],
      #|}
    ),
  )
}
