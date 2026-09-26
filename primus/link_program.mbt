///|
fn[T] is_term_linked(m : Machine, name : String, t : @types.Term[T]) -> Bool {
  Linker::is_linked(m, Tid(t.tid())) ||
  Linker::is_linked(m, Symbol(name)) ||
  (term_address(t) is Some(a) && Linker::is_linked(m, Addr(a)))
}

///|
/// Links every subroutine and block of the project program into the
/// machine (upstream `Interpreter.LinkBinaryProgram`, the `load-binary`
/// component). Terms are linked weakly: if a term is already linked under
/// its tid, name or address it is left untouched. Subroutines are linked
/// under their names, blocks under their term names; both also under their
/// tids and addresses.
pub fn Interpreter::link_program(m : Machine) -> Unit {
  let prog = m.program()
  let subs = prog.payload().subs
  let linked : @immut_hashmap.HashMap[@types.Tid, Unit] = {
    let mut acc = @immut_hashmap.HashMap::new()
    for sub in subs {
      if is_term_linked(m, @types.Sub::name(sub), sub) {
        acc = acc.add(sub.tid(), ())
      }
      for blk in sub.payload().blks {
        if is_term_linked(m, blk.name(), blk) {
          acc = acc.add(blk.tid(), ())
        }
      }
    }
    acc
  }
  for sub in subs {
    for blk in sub.payload().blks {
      if linked.get(blk.tid()) is None {
        Linker::link(
          m,
          name=blk.name(),
          tid=blk.tid(),
          addr?=term_address(blk),
          Block(blk),
        )
      }
    }
    if linked.get(sub.tid()) is None {
      Linker::link(
        m,
        name=@types.Sub::name(sub),
        tid=sub.tid(),
        addr?=term_address(sub),
        Subroutine(sub),
      )
    }
  }
}
