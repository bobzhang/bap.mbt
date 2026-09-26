///|
fn w(width : Int, n : Int) -> @types.Word {
  try! @types.Word::of_int(width~, n)
}

///|
fn v(name : String) -> @types.Var {
  @types.Var::create(name, Imm(32))
}

///|
fn int(n : Int) -> @types.Exp {
  Int(w(32, n))
}

///|
fn bool_var(name : String) -> @types.Exp {
  Var(@types.Var::create(name, Imm(1)))
}

///|
fn show_bil(bil : Array[@types.Stmt]) -> String {
  bil.map(s => s.to_string()).join("\n")
}

///|
/// Prints the blocks with canonical block names (`%0`, `%1`, ... in the
/// order of the blocks).
fn show_bir(blks : Array[@types.Term[@types.Blk]]) -> String {
  let names : Map[@types.Tid, String] = Map([])
  for b in blks {
    names[b.tid()] = "%\{names.length()}"
  }
  let tid = (t : @types.Tid) => {
    match names.get(t) {
      Some(n) => n
      None => t.to_string()
    }
  }
  let label = (l : @types.Label) => {
    match l {
      Direct(t) => tid(t)
      Indirect(e) => "(\{e.to_string()})"
    }
  }
  let buf = StringBuilder()
  for b in blks {
    buf.write_string("\{tid(b.tid())}:\n")
    for d in b.defs() {
      buf.write_string(
        "  \{@types.Def::lhs(d).to_string()} := \{@types.Def::rhs(d).to_string()}\n",
      )
    }
    for j in b.jmps() {
      buf.write_string("  ")
      match @types.Jmp::guard_(j) {
        Some(c) => buf.write_string("when \{c.to_string()} ")
        None => ()
      }
      match @types.Jmp::kind(j) {
        Goto(l) => buf.write_string("goto \{label(l)}")
        Ret(l) => buf.write_string("return \{label(l)}")
        JmpCall(c) => {
          buf.write_string("call \{label(c.target())}")
          match c.return_label() {
            Some(r) => buf.write_string(" with return \{label(r)}")
            None => buf.write_string(" with noreturn")
          }
        }
        Interrupt(n, r) => buf.write_string("interrupt \{n} return \{tid(r)}")
      }
      buf.write_string("\n")
    }
  }
  buf.to_string()
}

///|
test "passes are registered and selected by levels" {
  let names = @types.passes().map(p => p.name())
  for
    n in [
      "bnf1", "bnf2", "constant-folding", "constant-propagation", "prune-dead-virtuals",
    ] {
    assert_true(names.contains(n))
  }
  let listing = @bil.list_passes()
  assert_true(listing.iter().any(l => l.has_prefix("bnf1 ")))
  let names = (r : Result[Array[@types.BilPass], String]) => {
    match r {
      Ok(ps) => ps.map(p => p.name()).join(",")
      Err(e) => e
    }
  }
  inspect(
    names(@bil.pipeline()),
    content="constant-folding,constant-propagation,prune-dead-virtuals",
  )
  inspect(
    names(@bil.pipeline(normalization="2", optimization="0", passes=["bnf1"])),
    content="bnf2,bnf1",
  )
  inspect(
    names(@bil.pipeline(normalization="3")),
    content="unknown normalization level 3",
  )
  inspect(
    names(@bil.pipeline(optimization="2")),
    content="unknown optimization level 2",
  )
  inspect(
    names(@bil.pipeline(passes=["nope"])),
    content="unknown BIL pass nope",
  )
}

///|
test "the selected passes are applied to a fixed point" {
  let x = v("x")
  let t = @types.Var::create("t", Imm(32), is_virtual=true)
  let bil : Array[@types.Stmt] = [
    Move(t, BinOp(Plus, int(1), int(2))),
    Move(x, BinOp(Plus, Var(t), int(3))),
  ]
  @bil.select() |> ignore
  inspect(
    show_bil(@bil.apply_passes(bil).unwrap()),
    content=(
      #|x:imm32 := 6:32u
    ),
  )
  @bil.select(optimization="0") |> ignore
  assert_eq(@bil.apply_passes(bil).unwrap(), bil)
  // ill-typed code is rejected
  let bad : Array[@types.Stmt] = [Move(x, Int(w(8, 1)))]
  assert_true(@bil.apply_passes(bad) is Err(_))
  @types.select_passes([])
}
