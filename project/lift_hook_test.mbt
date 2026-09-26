///|
test "post-lift hooks transform the lifted semantics" {
  let x = @types.Var::create("x", Imm(32))
  let registry = @mc.Registry::new()
  registry.register(
    @mc.Provider::create("hook-test", accepts=_ => true, lift=(_, _) => {
      @mc.Lifted::create(
        [Move(x, Int(try! @types.Word::of_int(width=32, 1))), Special("s")],
        delay=1,
      )
    }),
  )
  let insn = bridge_insn(0x100, "TEST", [])
  let target = @core_theory.Target::x86()
  let lift = () => {
    match insn.lift(target~, registry~) {
      Ok(l) => "\{l.delay()}: \{bridge_stmts(l.bil())}"
      Err(e) => "error: \{e}"
    }
  }
  inspect(
    lift(),
    content=(
      #|1: x:imm32 := 1:32u
      #|special s
    ),
  )
  @project.register_lift_hook(name="drop-specials", bil => {
    Ok(bil.filter(s => !(s is Special(_))))
  })
  inspect(
    lift(),
    content=(
      #|1: x:imm32 := 1:32u
    ),
  )
  @project.register_lift_hook(name="fail", _ => Err("rejected"))
  debug_inspect(
    @project.lift_hooks(),
    content=(
      #|["drop-specials", "fail"]
    ),
  )
  inspect(
    lift(),
    content=(
      #|error: rejected
    ),
  )
  assert_true(@project.unregister_lift_hook("fail"))
  assert_false(@project.unregister_lift_hook("fail"))
  assert_true(@project.unregister_lift_hook("drop-specials"))
  inspect(
    lift(),
    content=(
      #|1: x:imm32 := 1:32u
      #|special s
    ),
  )
}
