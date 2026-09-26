///|
test "semantics promised by lifters in two theories join in the knowledge base" {
  declare_test_theories()
  let state = @knowledge.State::new()
  let s32 = @core_theory.Sort::bitv(32)
  let r = @core_theory.Var::create(s32, "R1")
  // a theory-polymorphic lifter: it lifts in the current theory
  let lifter : (@knowledge.State) -> @core_theory.Semantics raise = state => {
    let ct = @core_theory.current(state)
    let effect = ct.set(r, ct.add(ct.of_int(s32, 20), ct.of_int(s32, 22)))(
      state,
    )
    @core_theory.Semantics::of_effect(effect)
  }
  let bil = @core_theory.instance(state, requires=["test-bil"])
  let consts = @core_theory.instance(state, requires=["test-consts"])
  let slot = @core_theory.Semantics::slot()
  let label = state.create(@core_theory.Program::cls())
  let semantics = slot.promising(
    promise=(state, _) => {
      @core_theory.with_current(state, bil, () => lifter(state))
    },
    () => {
      slot.promising(
        promise=(state, _) => {
          @core_theory.with_current(state, consts, () => lifter(state))
        },
        () => state.collect(slot, label),
      )
    },
  )
  assert_eq(semantics.get(test_written), Some("R1"))
  inspect(
    semantics.bil().map(stmt => stmt.to_string()).join("; "),
    content=(
      #|R1:imm32 := (0x14:32u + 0x16:32u)
    ),
  )
}
