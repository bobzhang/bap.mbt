///|
test "tid strains match the textual term identifier" {
  let d = @types.Def::create(
    @types.Var::create("x", Imm(8)),
    Int(try! @types.Word::of_int(width=8, 1)),
    tid=@types.Tid::restore(id=0x2a),
  )
  inspect(
    d.tid().to_string(),
    content=(
      #|%42
    ),
  )
  inspect(
    @taint.satisfies(@taint.parse_strain("%0000002a").unwrap(), d),
    content=(
      #|false
    ),
  )
  inspect(
    @taint.satisfies(@taint.parse_strain("%42").unwrap(), d),
    content=(
      #|true
    ),
  )
  inspect(
    @taint.satisfies(@taint.parse_strain("%0042").unwrap(), d),
    content=(
      #|true
    ),
  )
  // an empty conjunction is satisfied by every definition
  inspect(@taint.satisfies([], d), content="true")
}
