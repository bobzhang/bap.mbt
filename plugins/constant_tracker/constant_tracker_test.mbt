///|
test "constants propagate through operations" {
  let t = @constant_tracker.ConstantTracker::new()
  t.intro(1)
  t.intro(2)
  t.on_binop(1, 2, 3) // const + const
  t.on_binop(3, 99, 4) // const + input
  t.on_unop(3, 5)
  t.on_cast(4, 6)
  t.on_extract(5, 7)
  t.on_concat(7, 3, 8)
  debug_inspect(
    [1L, 2, 3, 4, 5, 6, 7, 8, 99].map(id => t.is_const(id)),
    content="[true, true, true, false, true, false, true, true, false]",
  )
  inspect(t.all_static_constant([1, 3, 8]), content="true")
  inspect(t.all_static_constant([1, 4]), content="false")
  inspect(t.all_static_constant([]), content="true")
}

///|
test "static data and the lisp checks" {
  let t = @constant_tracker.ConstantTracker::new()
  let memory : Map[UInt64, Int64] = Map([])
  for i in 0..<16 {
    let id = (100 + i).to_int64()
    t.intro(id)
    memory[(0x1000 + i).to_uint64()] = id
  }
  memory[0x2000] = 7
  let load = (addr : UInt64) => memory.get(addr)
  inspect(t.points_to_static_data(0x1000, 16, load), content="true")
  inspect(t.points_to_static_data(0x1000, 17, load), content="false")
  inspect(t.points_to_static_data(0x2000, 1, load), content="false")
  inspect(t.points_to_static_data(0x5000, 0, load), content="true")
  debug_inspect(
    [
      t.check_call("connect", [3, 0x1000, 16], load),
      t.check_call("sendto", [3, 0, 0, 0, 0x1000, 16], load),
      t.check_call("connect", [3, 0x2000, 16], load),
      t.check_call("open", [0x1000], load),
    ],
    content=(
      #|[
      #|  Some("hardcoded-socket-address"),
      #|  Some("hardcoded-socket-address"),
      #|  None,
      #|  None,
      #|]
    ),
  )
  debug_inspect(
    [
      t.check_null_pointer(0, 100),
      t.check_null_pointer(0, 7),
      t.check_null_pointer(8, 100),
    ],
    content=(
      #|[Some("null-pointer-dereference"), None, None]
    ),
  )
}

///|
test "components and registration" {
  debug_inspect(
    @constant_tracker.components().map(c => "\{c.pkg}:\{c.name}"),
    content=(
      #|["bap:constant-tracker-primitives", "bap:constant-tracker"]
    ),
  )
  debug_inspect(
    @constant_tracker.lisp_primitives().map(p => "\{p.name} : \{p.types}"),
    content=(
      #|[
      #|  "all-static-constant : (all any) -> bool",
      #|  "points-to-static-data : (int int) -> bool",
      #|]
    ),
  )
  inspect(@constant_tracker.register(enable=true), content="true")
  inspect(@constant_tracker.register(), content="false")
  inspect(@constant_tracker.is_enabled(), content="true")
}
