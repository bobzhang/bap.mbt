///|
fn def_lhs_names(defs : Array[@types.Term[@types.Def]]) -> Array[String] {
  [
    for term in defs => term.lhs().name
  ]
}

///|
fn phi_lhs_names(phis : Array[@types.Term[@types.Phi]]) -> Array[String] {
  [
    for term in phis => term.phi_lhs().name
  ]
}

///|
fn jmp_names(jmps : Array[@types.Term[@types.Jmp]]) -> Array[String] {
  [
    for term in jmps => term.name()
  ]
}

///|
fn sub_names(subs : Array[@types.Term[@types.Sub]]) -> Array[String] {
  [
    for term in subs => term.sub_name()
  ]
}

///|
fn arg_lhs_names(args : Array[@types.Term[@types.Arg]]) -> Array[String] {
  [
    for term in args => term.arg_lhs().name
  ]
}

///|
fn blk_names(blks : Array[@types.Term[@types.Blk]]) -> Array[String] {
  [
    for term in blks => {
      match term.tid().name() {
        Some(name) => name
        None => term.name()
      }
    }
  ]
}

///|
fn assert_def_lhs_names(
  block : @types.Term[@types.Blk],
  expected : Array[String],
) -> Unit raise {
  assert_true(def_lhs_names(block.defs()) == expected)
}

///|
test "program sub sequence helpers follow BAP term order" {
  let main = @types.Sub::create(name="main")
  let helper = @types.Sub::create(name="helper")
  let exit = @types.Sub::create(name="exit")
  let program = @types.Program::create(subs=[main, helper, exit])
  assert_true(program.sub_count() == 3)
  assert_true(program.first_sub().map(term => term.sub_name()) == Some("main"))
  assert_true(program.last_sub().map(term => term.sub_name()) == Some("exit"))
  assert_true(program.nth_sub(1).map(term => term.sub_name()) == Some("helper"))
  assert_true(program.nth_sub(-1) is None)
  assert_true(program.nth_sub(3) is None)
  assert_true(
    program.next_sub(main.tid()).map(term => term.sub_name()) == Some("helper"),
  )
  assert_true(
    program.prev_sub(exit.tid()).map(term => term.sub_name()) == Some("helper"),
  )
  assert_true(program.prev_sub(main.tid()) is None)
  assert_true(sub_names(program.subs_after(main.tid())) == ["helper", "exit"])
  assert_true(
    sub_names(program.subs_after(main.tid(), rev=true)) == ["exit", "helper"],
  )
  assert_true(sub_names(program.subs_before(exit.tid())) == ["main", "helper"])
  assert_true(
    sub_names(program.subs_before(exit.tid(), rev=true)) == ["helper", "main"],
  )
  let prologue = @types.Sub::create(name="prologue")
  let middle = @types.Sub::create(name="middle")
  let inserted = program
    .insert_sub_after(middle, after=main.tid())
    .insert_sub_before(prologue)
  assert_true(
    sub_names(inserted.subs()) ==
    ["prologue", "main", "middle", "helper", "exit"],
  )
  assert_true(
    inserted
    .insert_sub_after(
      @types.Sub::create(name="absent"),
      after=@types.Tid::for_name("absent"),
    )
    .sub_count() ==
    5,
  )
}

///|
test "program sub rewrite helpers update remove map and filter" {
  let main = @types.Sub::create(name="main")
  let helper = @types.Sub::create(name="helper")
  let exit = @types.Sub::create(name="exit")
  let program = @types.Program::create(subs=[main, helper, exit])
  let helper2 = @types.Sub::create(name="helper2", tid=helper.tid())
  assert_true(
    sub_names(program.update_sub(helper2).subs()) == ["main", "helper2", "exit"],
  )
  assert_true(
    sub_names(program.remove_sub(helper.tid()).subs()) == ["main", "exit"],
  )
  assert_true(
    sub_names(
      program
      .map_subs(term => {
        if term.same(helper) {
          term.with_sub_name("mapped")
        } else {
          term
        }
      })
      .subs(),
    ) ==
    ["main", "mapped", "exit"],
  )
  assert_true(
    sub_names(program.filter_subs(term => term.sub_name() != "helper").subs()) ==
    ["main", "exit"],
  )
  assert_true(
    sub_names(
      program
      .filter_map_subs(term => {
        if term.sub_name() == "helper" {
          None
        } else {
          Some(term)
        }
      })
      .subs(),
    ) ==
    ["main", "exit"],
  )
  assert_true(
    sub_names(
      program
      .concat_map_subs(term => {
        if term.same(helper) {
          [term, @types.Sub::create(name="helper-copy")]
        } else {
          [term]
        }
      })
      .subs(),
    ) ==
    ["main", "helper", "helper-copy", "exit"],
  )
  assert_true(
    sub_names(
      program
      .change_sub(helper.tid(), current => {
        match current {
          Some(term) => Some(term.with_sub_name("changed"))
          None => None
        }
      })
      .subs(),
    ) ==
    ["main", "changed", "exit"],
  )
  assert_true(
    sub_names(program.change_sub(helper.tid(), _ => None).subs()) ==
    ["main", "exit"],
  )
  let plugin_tid = @types.Tid::for_name("plugin")
  assert_true(
    sub_names(
      program
      .change_sub(plugin_tid, current => {
        match current {
          Some(term) => Some(term)
          None => Some(@types.Sub::create(name="plugin", tid=plugin_tid))
        }
      })
      .subs(),
    ) ==
    ["main", "helper", "exit", "plugin"],
  )
}

///|
test "sub argument and block sequence helpers follow BAP term order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let w = @types.Var::new(name="w", typ~)
  let arg_x = @types.Arg::create(x, Var(x))
  let arg_y = @types.Arg::create(y, Var(y))
  let arg_z = @types.Arg::create(z, Var(z))
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let sub = @types.Sub::create(name="main", args=[arg_x, arg_y, arg_z], blks=[
    entry, body, exit,
  ])
  assert_true(sub.arg_count() == 3)
  assert_true(sub.first_arg().map(term => term.arg_lhs()) == Some(x))
  assert_true(sub.last_arg().map(term => term.arg_lhs()) == Some(z))
  assert_true(sub.nth_arg(1).map(term => term.arg_lhs()) == Some(y))
  assert_true(sub.nth_arg(-1) is None)
  assert_true(sub.next_arg(arg_x.tid()).map(term => term.arg_lhs()) == Some(y))
  assert_true(sub.prev_arg(arg_z.tid()).map(term => term.arg_lhs()) == Some(y))
  assert_true(sub.prev_arg(arg_x.tid()) is None)
  assert_true(arg_lhs_names(sub.args_after(arg_x.tid())) == ["y", "z"])
  assert_true(
    arg_lhs_names(sub.args_after(arg_x.tid(), rev=true)) == ["z", "y"],
  )
  assert_true(arg_lhs_names(sub.args_before(arg_z.tid())) == ["x", "y"])
  assert_true(
    arg_lhs_names(sub.args_before(arg_z.tid(), rev=true)) == ["y", "x"],
  )
  let arg_w = @types.Arg::create(w, Var(w))
  let arg_head = @types.Arg::create(x, Var(z))
  let inserted_args = sub
    .insert_arg_after(arg_w, after=arg_x.tid())
    .insert_arg_before(arg_head)
  assert_true(arg_lhs_names(inserted_args.args()) == ["x", "x", "w", "y", "z"])
  assert_true(
    inserted_args
    .insert_arg_before(
      @types.Arg::create(y, Var(x)),
      before=@types.Tid::for_name("absent"),
    )
    .arg_count() ==
    5,
  )
  assert_true(sub.blk_count() == 3)
  assert_true(sub.first_blk().map(term => term.tid()) == Some(entry.tid()))
  assert_true(sub.last_blk().map(term => term.tid()) == Some(exit.tid()))
  assert_true(sub.nth_blk(1).map(term => term.tid()) == Some(body.tid()))
  assert_true(sub.nth_blk(-1) is None)
  assert_true(
    sub.next_blk(entry.tid()).map(term => term.tid()) == Some(body.tid()),
  )
  assert_true(
    sub.prev_blk(exit.tid()).map(term => term.tid()) == Some(body.tid()),
  )
  assert_true(sub.next_blk(exit.tid()) is None)
  assert_true(blk_names(sub.blks_after(entry.tid())) == ["body", "exit"])
  assert_true(
    blk_names(sub.blks_after(entry.tid(), rev=true)) == ["exit", "body"],
  )
  assert_true(blk_names(sub.blks_before(exit.tid())) == ["entry", "body"])
  assert_true(
    blk_names(sub.blks_before(exit.tid(), rev=true)) == ["body", "entry"],
  )
  let pre = @types.Blk::create(tid=@types.Tid::for_name("pre"))
  let mid = @types.Blk::create(tid=@types.Tid::for_name("mid"))
  let inserted_blks = sub
    .insert_blk_after(mid, after=entry.tid())
    .insert_blk_before(pre)
  assert_true(
    blk_names(inserted_blks.blks()) == ["pre", "entry", "mid", "body", "exit"],
  )
  assert_true(
    inserted_blks
    .insert_blk_before(
      @types.Blk::create(tid=@types.Tid::for_name("nope")),
      before=@types.Tid::for_name("absent"),
    )
    .blk_count() ==
    5,
  )
}

///|
test "sub argument and block rewrite helpers update remove map and filter" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let w = @types.Var::new(name="w", typ~)
  let arg_x = @types.Arg::create(x, Var(x))
  let arg_y = @types.Arg::create(y, Var(y))
  let arg_z = @types.Arg::create(z, Var(z))
  let entry = @types.Blk::create(tid=@types.Tid::for_name("entry"))
  let body = @types.Blk::create(tid=@types.Tid::for_name("body"))
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let sub = @types.Sub::create(name="main", args=[arg_x, arg_y, arg_z], blks=[
    entry, body, exit,
  ])
  let arg_w = @types.Arg::create(w, Var(w), tid=arg_y.tid())
  assert_true(arg_lhs_names(sub.update_arg(arg_w).args()) == ["x", "w", "z"])
  assert_true(arg_lhs_names(sub.remove_arg(arg_y.tid()).args()) == ["x", "z"])
  assert_true(
    arg_lhs_names(
      sub
      .map_args(term => {
        if term.same(arg_y) {
          @types.Arg::create(w, term.arg_rhs(), tid=term.tid())
        } else {
          term
        }
      })
      .args(),
    ) ==
    ["x", "w", "z"],
  )
  assert_true(
    arg_lhs_names(sub.filter_args(term => term.arg_lhs() != y).args()) ==
    ["x", "z"],
  )
  assert_true(
    arg_lhs_names(
      sub
      .filter_map_args(term => {
        if term.arg_lhs() == y {
          None
        } else {
          Some(term)
        }
      })
      .args(),
    ) ==
    ["x", "z"],
  )
  assert_true(
    arg_lhs_names(
      sub
      .concat_map_args(term => {
        if term.same(arg_y) {
          [term, @types.Arg::create(w, Var(w))]
        } else {
          [term]
        }
      })
      .args(),
    ) ==
    ["x", "y", "w", "z"],
  )
  assert_true(
    arg_lhs_names(
      sub
      .change_arg(arg_y.tid(), current => {
        match current {
          Some(term) =>
            Some(@types.Arg::create(w, term.arg_rhs(), tid=term.tid()))
          None => None
        }
      })
      .args(),
    ) ==
    ["x", "w", "z"],
  )
  assert_true(
    arg_lhs_names(sub.change_arg(arg_y.tid(), _ => None).args()) == ["x", "z"],
  )
  let arg_tail_tid = @types.Tid::for_name("arg-tail")
  assert_true(
    arg_lhs_names(
      sub
      .change_arg(arg_tail_tid, current => {
        match current {
          Some(term) => Some(term)
          None => Some(@types.Arg::create(w, Var(w), tid=arg_tail_tid))
        }
      })
      .args(),
    ) ==
    ["x", "y", "z", "w"],
  )
  let rewritten_body = body.append_def(@types.Def::create(x, Var(y)))
  assert_true(
    sub.update_blk(rewritten_body).find_blk(body.tid()).unwrap().def_count() ==
    1,
  )
  assert_true(blk_names(sub.remove_blk(body.tid()).blks()) == ["entry", "exit"])
  assert_true(
    sub
    .map_blks(blk => {
      if blk.same(body) {
        blk.append_def(@types.Def::create(y, Var(x)))
      } else {
        blk
      }
    })
    .find_blk(body.tid())
    .unwrap()
    .def_count() ==
    1,
  )
  assert_true(
    blk_names(sub.filter_blks(blk => blk.tid() != body.tid()).blks()) ==
    ["entry", "exit"],
  )
  assert_true(
    blk_names(
      sub
      .filter_map_blks(blk => {
        if blk.tid() == body.tid() {
          None
        } else {
          Some(blk)
        }
      })
      .blks(),
    ) ==
    ["entry", "exit"],
  )
  assert_true(
    blk_names(
      sub
      .concat_map_blks(blk => {
        if blk.same(body) {
          [blk, @types.Blk::create(tid=@types.Tid::for_name("body-tail"))]
        } else {
          [blk]
        }
      })
      .blks(),
    ) ==
    ["entry", "body", "body-tail", "exit"],
  )
  assert_true(
    sub
    .change_blk(body.tid(), current => {
      match current {
        Some(blk) => Some(blk.append_def(@types.Def::create(z, Var(x))))
        None => None
      }
    })
    .find_blk(body.tid())
    .unwrap()
    .def_count() ==
    1,
  )
  assert_true(
    blk_names(sub.change_blk(body.tid(), _ => None).blks()) == ["entry", "exit"],
  )
  let tail_tid = @types.Tid::for_name("tail-block")
  assert_true(
    blk_names(
      sub
      .change_blk(tail_tid, current => {
        match current {
          Some(blk) => Some(blk)
          None => Some(@types.Blk::create(tid=tail_tid))
        }
      })
      .blks(),
    ) ==
    ["entry", "body", "exit", "tail-block"],
  )
}

///|
test "block definition sequence helpers follow BAP term order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  assert_true(block.def_count() == 3)
  assert_true(block.first_def().map(term => term.lhs()) == Some(x))
  assert_true(block.last_def().map(term => term.lhs()) == Some(z))
  assert_true(block.nth_def(1).map(term => term.lhs()) == Some(y))
  assert_true(block.nth_def(-1) is None)
  assert_true(block.nth_def(3) is None)
  assert_true(block.next_def(def_x.tid()).map(term => term.lhs()) == Some(y))
  assert_true(block.prev_def(def_z.tid()).map(term => term.lhs()) == Some(y))
  assert_true(block.prev_def(def_x.tid()) is None)
}

///|
test "block before and after definition slices support reverse order" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  assert_true(def_lhs_names(block.defs_after(def_x.tid())) == ["y", "z"])
  assert_true(
    def_lhs_names(block.defs_after(def_x.tid(), rev=true)) == ["z", "y"],
  )
  assert_true(def_lhs_names(block.defs_before(def_z.tid())) == ["x", "y"])
  assert_true(
    def_lhs_names(block.defs_before(def_z.tid(), rev=true)) == ["y", "x"],
  )
  assert_true(block.defs_after(@types.Tid::for_name("missing")).is_empty())
  assert_true(block.def_occurs_after(def_x.tid(), def_z.tid()))
  assert_true(block.def_occurs_after(def_y.tid(), def_y.tid()))
  assert_true(!block.def_occurs_after(def_z.tid(), def_x.tid()))
  assert_true(block.occurs(after=def_x.tid(), def_z.tid()))
  assert_true(block.occurs(after=def_y.tid(), def_y.tid()))
  assert_true(!block.occurs(after=def_z.tid(), def_x.tid()))
}

///|
test "block definition editing helpers insert update remove and map" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let o = @types.Var::new(name="o", typ~)
  let s = @types.Var::new(name="s", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let def_o = @types.Def::create(o, Int(word8(4)))
  let def_s = @types.Def::create(s, Int(word8(5)))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z])
  let inserted = block
    .insert_def_after(def_o, after=def_x.tid())
    .insert_def_before(def_s)
  assert_def_lhs_names(inserted, ["s", "x", "o", "y", "z"])
  let unchanged = inserted.insert_def_after(
    @types.Def::create(o, Int(word8(6))),
    after=@types.Tid::for_name("absent"),
  )
  assert_def_lhs_names(unchanged, ["s", "x", "o", "y", "z"])
  let renamed_y = def_y.with_lhs(s)
  assert_def_lhs_names(block.update_def(renamed_y), ["x", "s", "z"])
  assert_def_lhs_names(inserted.remove_def(def_o.tid()), ["s", "x", "y", "z"])
  assert_def_lhs_names(
    block.map_defs(term => if term.lhs() == y { term.with_lhs(s) } else { term }),
    ["x", "s", "z"],
  )
  assert_def_lhs_names(block.filter_defs(term => term.lhs() != y), ["x", "z"])
  assert_def_lhs_names(
    block.filter_map_defs(term => {
      if term.lhs() == y {
        None
      } else {
        Some(term)
      }
    }),
    ["x", "z"],
  )
  assert_def_lhs_names(
    block.concat_map_defs(term => {
      if term.lhs() == y {
        [term, term]
      } else {
        [term]
      }
    }),
    ["x", "y", "y", "z"],
  )
  assert_def_lhs_names(
    block.change_def(def_y.tid(), current => {
      match current {
        Some(term) => Some(term.with_lhs(s))
        None => None
      }
    }),
    ["x", "s", "z"],
  )
  assert_def_lhs_names(block.change_def(def_y.tid(), _ => None), ["x", "z"])
  let def_tail_tid = @types.Tid::for_name("def-tail")
  let def_tail = @types.Def::create(s, Int(word8(6)), tid=def_tail_tid)
  assert_def_lhs_names(
    block.change_def(def_tail_tid, current => {
      match current {
        Some(term) => Some(term)
        None => Some(def_tail)
      }
    }),
    ["x", "y", "z", "s"],
  )
}

///|
test "block phi jump and sub update helpers map terms" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let w = @types.Var::new(name="w", typ~)
  let pred = @types.Tid::for_name("pred")
  let dst = @types.Tid::for_name("dst")
  let fall = @types.Tid::for_name("fall")
  let phi = @types.Phi::of_list(x, [(pred, Var(y))])
  let phi_z = @types.Phi::of_list(z, [(pred, Var(x))])
  let jmp = @types.Jmp::create_goto(@types.Label::direct(dst), cond=Var(x))
  let fall_jmp = @types.Jmp::create_goto(
    @types.Label::direct(fall),
    cond=Var(y),
  )
  let block = @types.Blk::create(phis=[phi, phi_z], jmps=[jmp, fall_jmp])
  assert_true(block.phi_count() == 2)
  assert_true(block.first_phi().map(term => term.phi_lhs()) == Some(x))
  assert_true(block.last_phi().map(term => term.phi_lhs()) == Some(z))
  assert_true(block.nth_phi(1).map(term => term.phi_lhs()) == Some(z))
  assert_true(block.nth_phi(-1) is None)
  assert_true(block.next_phi(phi.tid()).map(term => term.phi_lhs()) == Some(z))
  assert_true(
    block.prev_phi(phi_z.tid()).map(term => term.phi_lhs()) == Some(x),
  )
  assert_true(block.prev_phi(phi.tid()) is None)
  assert_true(block.jmp_count() == 2)
  assert_true(block.first_jmp().map(term => term.tid()) == Some(jmp.tid()))
  assert_true(block.last_jmp().map(term => term.tid()) == Some(fall_jmp.tid()))
  assert_true(block.nth_jmp(1).map(term => term.tid()) == Some(fall_jmp.tid()))
  assert_true(block.nth_jmp(2) is None)
  assert_true(
    block.next_jmp(jmp.tid()).map(term => term.tid()) == Some(fall_jmp.tid()),
  )
  assert_true(
    block.prev_jmp(fall_jmp.tid()).map(term => term.tid()) == Some(jmp.tid()),
  )
  assert_true(block.next_jmp(fall_jmp.tid()) is None)
  assert_true(phi_lhs_names(block.phis_after(phi.tid())) == ["z"])
  assert_true(phi_lhs_names(block.phis_before(phi_z.tid())) == ["x"])
  assert_true(phi_lhs_names(block.phis_before(phi_z.tid(), rev=true)) == ["x"])
  assert_true(block.phis_after(phi_z.tid()).is_empty())
  assert_true(jmp_names(block.jmps_after(jmp.tid())) == [fall_jmp.name()])
  assert_true(jmp_names(block.jmps_before(fall_jmp.tid())) == [jmp.name()])
  assert_true(
    jmp_names(block.jmps_before(fall_jmp.tid(), rev=true)) == [jmp.name()],
  )
  assert_true(block.jmps_after(fall_jmp.tid()).is_empty())
  let phi_y = @types.Phi::of_list(y, [(pred, Var(x))])
  let phi_w = @types.Phi::of_list(w, [(pred, Var(z))])
  let inserted_phis = block
    .insert_phi_after(phi_w, after=phi.tid())
    .insert_phi_before(phi_y)
  assert_true(phi_lhs_names(inserted_phis.phis()) == ["y", "x", "w", "z"])
  assert_true(
    inserted_phis
    .insert_phi_after(
      @types.Phi::of_list(w, [(pred, Var(y))]),
      after=@types.Tid::for_name("absent"),
    )
    .phi_count() ==
    4,
  )
  let head_jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("head")),
  )
  let mid_jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("mid")),
  )
  let inserted_jmps = block
    .insert_jmp_after(mid_jmp, after=jmp.tid())
    .insert_jmp_before(head_jmp)
  assert_true(
    jmp_names(inserted_jmps.jmps()) ==
    [head_jmp.name(), jmp.name(), mid_jmp.name(), fall_jmp.name()],
  )
  assert_true(
    inserted_jmps
    .insert_jmp_before(
      @types.Jmp::create_goto(
        @types.Label::direct(@types.Tid::for_name("nope")),
      ),
      before=@types.Tid::for_name("absent"),
    )
    .jmp_count() ==
    4,
  )
  let updated_phi = phi.with_phi_lhs(y)
  let updated_block = block.update_phi_term(updated_phi)
  assert_true(updated_block.phis()[0].phi_lhs() == y)
  assert_true(
    block.map_phis(term => term.with_phi_lhs(y)).phis()[0].phi_lhs() == y,
  )
  assert_true(
    phi_lhs_names(block.filter_phis(term => term.phi_lhs() != x).phis()) ==
    ["z"],
  )
  assert_true(
    phi_lhs_names(
      block
      .filter_map_phis(term => {
        if term.phi_lhs() == x {
          None
        } else {
          Some(term)
        }
      })
      .phis(),
    ) ==
    ["z"],
  )
  assert_true(
    phi_lhs_names(
      block
      .concat_map_phis(term => {
        if term.same(phi) {
          [term, @types.Phi::of_list(w, [(pred, Var(z))])]
        } else {
          [term]
        }
      })
      .phis(),
    ) ==
    ["x", "w", "z"],
  )
  assert_true(
    phi_lhs_names(
      block
      .change_phi_term(phi.tid(), current => {
        match current {
          Some(term) => Some(term.with_phi_lhs(w))
          None => None
        }
      })
      .phis(),
    ) ==
    ["w", "z"],
  )
  assert_true(block.change_phi_term(phi.tid(), _ => None).phi_count() == 1)
  let phi_tail_tid = @types.Tid::for_name("phi-tail")
  assert_true(
    phi_lhs_names(
      block
      .change_phi_term(phi_tail_tid, current => {
        match current {
          Some(term) => Some(term)
          None =>
            Some(@types.Phi::of_list(w, [(pred, Var(y))], tid=phi_tail_tid))
        }
      })
      .phis(),
    ) ==
    ["x", "z", "w"],
  )
  let without_phi = block.remove_phi_term(phi.tid())
  assert_true(without_phi.phi_count() == 1)
  assert_true(
    without_phi.first_phi().map(term => term.tid()) == Some(phi_z.tid()),
  )
  let updated_jmp = jmp.with_cond(Var(y))
  assert_true(block.update_jmp(updated_jmp).jmps()[0].cond() == Var(y))
  assert_true(
    block.map_jmps(term => term.with_cond(Var(y))).jmps()[0].cond() == Var(y),
  )
  assert_true(
    jmp_names(block.filter_jmps(term => !term.same(jmp)).jmps()) ==
    [fall_jmp.name()],
  )
  assert_true(
    jmp_names(
      block
      .filter_map_jmps(term => if term.same(jmp) { None } else { Some(term) })
      .jmps(),
    ) ==
    [fall_jmp.name()],
  )
  let tail_jmp = @types.Jmp::create_goto(
    @types.Label::direct(@types.Tid::for_name("tail")),
  )
  assert_true(
    jmp_names(
      block
      .concat_map_jmps(term => {
        if term.same(jmp) {
          [term, tail_jmp]
        } else {
          [term]
        }
      })
      .jmps(),
    ) ==
    [jmp.name(), tail_jmp.name(), fall_jmp.name()],
  )
  assert_true(
    block
    .change_jmp(jmp.tid(), current => {
      match current {
        Some(term) => Some(term.with_cond(Var(z)))
        None => None
      }
    })
    .jmps()[0].cond() ==
    Var(z),
  )
  assert_true(block.change_jmp(jmp.tid(), _ => None).jmp_count() == 1)
  let jmp_tail_tid = @types.Tid::for_name("jmp-tail")
  assert_true(
    block
    .change_jmp(jmp_tail_tid, current => {
      match current {
        Some(term) => Some(term)
        None =>
          Some(
            @types.Jmp::create_goto(
              @types.Label::direct(fall),
              tid=jmp_tail_tid,
            ),
          )
      }
    })
    .jmp_count() ==
    3,
  )
  let elt_def = @types.Def::create(x, Var(y))
  let elt_block = @types.Blk::create(phis=[phi], defs=[elt_def], jmps=[jmp])
  let mapped_elts = elt_block.map_blk_elts(
    phi=term => term.with_phi_lhs(y),
    def=term => term.with_lhs(y),
    jmp=term => term.with_cond(Var(y)),
  )
  assert_true(mapped_elts.phis()[0].phi_lhs() == y)
  assert_true(mapped_elts.defs()[0].lhs() == y)
  assert_true(mapped_elts.jmps()[0].cond() == Var(y))
  let mapped_elts_alias = elt_block.map_elts(
    phi=term => term.with_phi_lhs(y),
    def=term => term.with_lhs(y),
    jmp=term => term.with_cond(Var(y)),
  )
  assert_true(mapped_elts_alias.phis()[0].phi_lhs() == y)
  assert_true(mapped_elts_alias.defs()[0].lhs() == y)
  assert_true(mapped_elts_alias.jmps()[0].cond() == Var(y))
  let def_only = elt_block.map_blk_elts(def=term => term.with_lhs(y))
  let def_only_alias = elt_block.map_elts(def=term => term.with_lhs(y))
  assert_true(def_only.phis()[0].same(phi))
  assert_true(def_only.defs()[0].lhs() == y)
  assert_true(def_only.jmps()[0].same(jmp))
  assert_true(def_only_alias.phis()[0].same(phi))
  assert_true(def_only_alias.defs()[0].lhs() == y)
  assert_true(def_only_alias.jmps()[0].same(jmp))
  let without_jmp = block.remove_jmp(jmp.tid())
  assert_true(without_jmp.jmp_count() == 1)
  assert_true(
    without_jmp.first_jmp().map(term => term.tid()) == Some(fall_jmp.tid()),
  )
  let sub = @types.Sub::create(name="main", blks=[block])
  let rewritten = block.append_def(@types.Def::create(y, Var(x)))
  assert_true(
    sub.update_blk(rewritten).find_blk(block.tid()).map(blk => blk.def_count()) ==
    Some(1),
  )
  assert_true(
    sub.map_blks(blk => blk.append_def(@types.Def::create(y, Var(x)))).blks()[0].def_count() ==
    1,
  )
}

///|
test "block definition split helpers preserve control transfer shape" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let def_x = @types.Def::create(x, Int(word8(1)))
  let def_y = @types.Def::create(y, Int(word8(2)))
  let def_z = @types.Def::create(z, Int(word8(3)))
  let exit = @types.Tid::for_name("exit")
  let jmp = @types.Jmp::create_goto(@types.Label::direct(exit))
  let block = @types.Blk::create(defs=[def_x, def_y, def_z], jmps=[jmp])
  let before = block.split_before_def(def_y)
  assert_def_lhs_names(before.0, ["x"])
  assert_def_lhs_names(before.1, ["y", "z"])
  let before_alias = block.split_before(def_y)
  assert_def_lhs_names(before_alias.0, ["x"])
  assert_def_lhs_names(before_alias.1, ["y", "z"])
  match before.0.jmps()[0].kind() {
    Goto(Direct(tid)) => assert_true(tid == before.1.tid())
    _ => fail("split block must jump to the second block")
  }
  match before_alias.0.jmps()[0].kind() {
    Goto(Direct(tid)) => assert_true(tid == before_alias.1.tid())
    _ => fail("split-before alias must jump to the second block")
  }
  assert_true(before.1.jmps()[0].same(jmp))
  assert_true(before_alias.1.jmps()[0].same(jmp))
  let after = block.split_after_def(def_y)
  assert_def_lhs_names(after.0, ["x", "y"])
  assert_def_lhs_names(after.1, ["z"])
  let after_alias = block.split_after(def_y)
  assert_def_lhs_names(after_alias.0, ["x", "y"])
  assert_def_lhs_names(after_alias.1, ["z"])
  assert_true(after_alias.1.jmps()[0].same(jmp))
  let while_split = block.split_defs_while(term => term.lhs() != y)
  assert_true(while_split.0.tid() == block.tid())
  assert_def_lhs_names(while_split.0, ["x"])
  assert_def_lhs_names(while_split.1, ["y", "z"])
  let while_alias = block.split_while(term => term.lhs() != y)
  assert_true(while_alias.0.tid() == block.tid())
  assert_def_lhs_names(while_alias.0, ["x"])
  assert_def_lhs_names(while_alias.1, ["y", "z"])
  match while_split.0.jmps()[0].kind() {
    Goto(Direct(tid)) => assert_true(tid == while_split.1.tid())
    _ => fail("split-while block must jump to the second block")
  }
  match while_alias.0.jmps()[0].kind() {
    Goto(Direct(tid)) => assert_true(tid == while_alias.1.tid())
    _ => fail("split-while alias must jump to the second block")
  }
  assert_true(while_split.1.jmps()[0].same(jmp))
  assert_true(while_alias.1.jmps()[0].same(jmp))
  let all_left = block.split_defs_while(_ => true)
  assert_def_lhs_names(all_left.0, ["x", "y", "z"])
  assert_def_lhs_names(all_left.1, [])
  let top = block.split_top_defs()
  assert_def_lhs_names(top.0, [])
  assert_def_lhs_names(top.1, ["x", "y", "z"])
  let top_alias = block.split_top()
  assert_def_lhs_names(top_alias.0, [])
  assert_def_lhs_names(top_alias.1, ["x", "y", "z"])
  let bottom = block.split_bottom_defs()
  assert_def_lhs_names(bottom.0, ["x", "y", "z"])
  assert_def_lhs_names(bottom.1, [])
  let bot_alias = block.split_bot()
  assert_def_lhs_names(bot_alias.0, ["x", "y", "z"])
  assert_def_lhs_names(bot_alias.1, [])
}

///|
test "block variable lookup prefers latest definitions then phi bindings" {
  let typ = @types.ValueType::Imm(8)
  let x = @types.Var::new(name="x", typ~)
  let y = @types.Var::new(name="y", typ~)
  let z = @types.Var::new(name="z", typ~)
  let pred = @types.Tid::for_name("pred")
  let phi = @types.Phi::of_list(x, [(pred, Var(z))])
  let def_y1 = @types.Def::create(y, Int(word8(1)))
  let def_y2 = @types.Def::create(y, BinOp(Plus, Var(x), Int(word8(2))))
  let block = @types.Blk::create(phis=[phi], defs=[def_y1, def_y2])
  match block.find_var(y) {
    Some(DefBinding(term)) => assert_true(term.same(def_y2))
    _ => fail("expected latest def binding")
  }
  match block.find_var(x) {
    Some(PhiBinding(term)) => assert_true(term.same(phi))
    _ => fail("expected phi binding")
  }
  assert_true(block.uses_var(x))
  assert_true(!block.uses_var(y))
  assert_true(block.find_var(z) is None)
}
