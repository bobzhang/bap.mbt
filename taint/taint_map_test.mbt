///|
test "taint maps render as s-expressions and round trip" {
  let t1 = @types.Tid::for_name("t1")
  let t2 = @types.Tid::restore(id=3)
  let map = @taint.TaintMap::empty()
    .add("RAX", [t2])
    .add("RAX", [t1, t2])
    .add("RBX", [t1])
    .add("RCX", [])
  let text = map.to_string()
  inspect(
    text,
    content=(
      #|((RAX (@t1 %3)) (RBX (@t1)))
    ),
  )
  let back = @taint.TaintMap::parse(text)
  assert_true(back == map)
  inspect(back.get("RAX").length(), content="2")
  inspect(back.get("RDX").length(), content="0")
  inspect(map.taints().length(), content="2")
  let other = @taint.TaintMap::empty().add("RDX", [t1])
  inspect(
    map.union(other).bindings().map(p => p.0).join(" "),
    content=(
      #|RAX RBX RDX
    ),
  )
  try @taint.TaintMap::parse("(RAX)") catch {
    _ => ()
  } noraise {
    _ => fail("expected a parse error")
  }
}

///|
test "taint map attributes are understood by BML predicates" {
  // the attribute names agree with the BML taint predicates
  assert_eq(@taint.tainted_regs_attr, @bml.tainted_regs_attr)
  assert_eq(@taint.tainted_ptrs_attr, @bml.tainted_ptrs_attr)
  let seed = @types.Tid::for_name("seed")
  let def = @types.Def::create(reg("x"), int64(1))
  let def = @taint.merge_term_taint_map(
    def,
    @taint.tainted_regs_attr,
    @taint.TaintMap::empty().add("x", [seed]),
  )
  let def = @taint.merge_term_taint_map(
    def,
    @taint.tainted_regs_attr,
    @taint.TaintMap::empty().add("y", [seed]),
  )
  inspect(
    def.get_attr(@taint.tainted_regs_attr).unwrap(),
    content=(
      #|((x (@seed)) (y (@seed)))
    ),
  )
  let prog = @types.Program::create(subs=[
    @types.Sub::create(name="main", blks=[@types.Blk::create(defs=[def])]),
  ])
  let marked = @bml.map_terms(
    ["((has-tainted-reg \{seed.to_string()}) (set-mark))"],
    prog,
  ).unwrap()
  let def = marked.subs()[0].blks()[0].defs()[0]
  assert_true(def.has_attr("mark"))
}
