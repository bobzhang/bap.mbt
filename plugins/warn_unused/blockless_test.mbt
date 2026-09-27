///|
test "end to end: a blockless external ends the microexecution path" {
  // As upstream (`Microx_conqueror` over `Biri`), the conqueror returns from
  // a callee only through one of its jumps: with the blockless `malloc`
  // stub the return block is never visited, the seed isn't collected, and
  // nothing is reported.
  let out = StringBuilder()
  ignore(@warn_unused.register())
  let passes = ["warn-unused-taint", "propagate-taint"]
  guard project_of(program(false)).run_passes(passes) is Ok(proj) else {
    fail("the passes failed")
  }
  @warn_unused.print(proj, out=s => out.write_string(s))
  inspect(out.to_string(), content="")
  let seed_def = proj.program().subs()[0].blks()[1].defs()[0]
  inspect(seed_def.taints_reg(), content="true")
  inspect(seed_def.is_visited(), content="false")
}
