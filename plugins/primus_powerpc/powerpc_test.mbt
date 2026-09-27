///|
fn read_ctr(target : @core_theory.Target) -> String {
  let out = Ref("")
  let (_, _) = @primus.Machine::run(
    @project.Project::empty(target),
    init=m => @primus_powerpc.install(m),
    start=m => {
      let v = @types.Var::create("CTR", Imm(32))
      out.val = @primus.Env::get(m, v).to_word().to_hex() catch {
          e => @primus.exn_to_string(e)
        }
    },
  )
  out.val
}

///|
test "the PowerPC registers are initialized on 32-bit PowerPC only" {
  debug_inspect(
    [
      @primus_powerpc.is_ppc(@core_theory.Target::powerpc()),
      @primus_powerpc.is_ppc(@core_theory.Target::powerpc64()),
      @primus_powerpc.is_ppc(@core_theory.Target::powerpcle()),
      @primus_powerpc.is_ppc(@core_theory.Target::x86()),
    ],
    content=(
      #|[true, false, false, false]
    ),
  )
  inspect(
    read_ctr(@core_theory.Target::powerpc()),
    content=(
      #|0x00000000
    ),
  )
  inspect(
    read_ctr(@core_theory.Target::x86()),
    content=(
      #|undefined variable `CTR'
    ),
  )
  assert_true(@primus_powerpc.register())
  assert_false(@primus_powerpc.register())
}
