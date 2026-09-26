///|
/// The program level (upstream `Pos.level3`).
pub struct TopLevel {
  me : @types.Term[@types.Program]
}

///|
/// The subroutine level (upstream `Pos.level2`).
pub struct SubLevel {
  me : @types.Term[@types.Sub]
  up : TopLevel
}

///|
/// Arguments and blocks live directly inside a subroutine
/// (upstream `'a Pos.level1`).
pub struct Level1[T] {
  me : @types.Term[T]
  up : SubLevel
}

///|
/// Phi nodes, definitions and jumps live inside a block
/// (upstream `'a Pos.level0`).
pub struct Level0[T] {
  me : @types.Term[T]
  up : Level1[@types.Blk]
}

///|
/// The position of the interpreter in the program (upstream `Primus.Pos.t`).
pub enum Pos {
  Top(TopLevel)
  Sub(SubLevel)
  Arg(Level1[@types.Arg])
  Blk(Level1[@types.Blk])
  Phi(Level0[@types.Phi])
  Def(Level0[@types.Def])
  Jmp(Level0[@types.Jmp])
}

///|
/// The initial position of a program.
pub fn Pos::top(prog : @types.Term[@types.Program]) -> Pos {
  Top({ me: prog, })
}

///|
pub fn Pos::tid(self : Pos) -> @types.Tid {
  match self {
    Top(t) => t.me.tid()
    Sub(t) => t.me.tid()
    Arg(t) => t.me.tid()
    Blk(t) => t.me.tid()
    Phi(t) => t.me.tid()
    Def(t) => t.me.tid()
    Jmp(t) => t.me.tid()
  }
}

///|
/// Reads an attribute of the term at the position (upstream `Pos.get`).
pub fn Pos::get_attr(self : Pos, key : String) -> String? {
  match self {
    Top(t) => t.me.get_attr(key)
    Sub(t) => t.me.get_attr(key)
    Arg(t) => t.me.get_attr(key)
    Blk(t) => t.me.get_attr(key)
    Phi(t) => t.me.get_attr(key)
    Def(t) => t.me.get_attr(key)
    Jmp(t) => t.me.get_attr(key)
  }
}

///|
/// The name of the level (`top`, `sub`, `arg`, ...).
pub fn Pos::level_name(self : Pos) -> String {
  match self {
    Top(_) => "top"
    Sub(_) => "sub"
    Arg(_) => "arg"
    Blk(_) => "blk"
    Phi(_) => "phi"
    Def(_) => "def"
    Jmp(_) => "jmp"
  }
}

///|
/// Renders the position as `<level>(<term name>)` (upstream `Pos.to_string`).
pub fn Pos::to_string(self : Pos) -> String {
  let name = match self {
    Top(t) => t.me.name()
    Sub(t) => t.me.name()
    Arg(t) => t.me.name()
    Blk(t) => t.me.name()
    Phi(t) => t.me.name()
    Def(t) => t.me.name()
    Jmp(t) => t.me.name()
  }
  "\{self.level_name()}(\{name})"
}

///|
pub impl Show for Pos with fn output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// The S-expression representation (upstream `Pos.sexp_of_t`).
pub fn Pos::to_sexp(self : Pos) -> Sexp {
  match self {
    Top(_) => Atom("top")
    Sub(t) => List([Atom("sub"), Atom(@types.Sub::name(t.me))])
    Arg(t) => List([Atom("arg"), Atom(t.me.arg_lhs().name())])
    Blk(t) => List([Atom("blk"), Atom(t.me.tid().to_string())])
    Phi(t) => List([Atom("phi"), Atom(t.me.phi_to_string().trim().to_owned())])
    Def(t) => List([Atom("def"), Atom(t.me.def_to_string().trim().to_owned())])
    Jmp(t) => List([Atom("jmp"), Atom(t.me.jmp_to_string().trim().to_owned())])
  }
}

///|
fn Pos::reject(self : Pos, dst : String) -> PrimusError {
  BrokenInvariant(level=self.to_string(), dst~)
}

///|
fn Pos::top_level(self : Pos) -> TopLevel {
  match self {
    Top(t) => t
    Sub(l) => l.up
    Arg(l) => l.up.up
    Blk(l) => l.up.up
    Phi(l) => l.up.up.up
    Def(l) => l.up.up.up
    Jmp(l) => l.up.up.up
  }
}

///|
/// Transition to a program term.
pub fn Pos::next_top(
  self : Pos,
  prog : @types.Term[@types.Program],
) -> Pos raise PrimusError {
  match self {
    Top(_) => Top({ me: prog, })
    _ => raise self.reject("top")
  }
}

///|
/// Transition to a subroutine term. Upstream accepts the `top`, `sub` and
/// `jmp` levels; this port accepts every level, so that subroutines can be
/// called synchronously by host code in the middle of a definition (e.g.
/// trap handlers invoked while an expression is evaluated).
pub fn Pos::next_sub(self : Pos, sub : @types.Term[@types.Sub]) -> Pos {
  Sub({ me: sub, up: self.top_level(), })
}

///|
/// Transition to an argument term. Upstream accepts only the `sub`, `arg`
/// and `jmp` levels; this port also accepts the block-internal levels so
/// that a subroutine whose last block falls through (has no jump) can bind
/// its output arguments.
pub fn Pos::next_arg(
  self : Pos,
  arg : @types.Term[@types.Arg],
) -> Pos raise PrimusError {
  match self {
    Sub(up) => Arg({ me: arg, up, })
    Arg(l) => Arg({ me: arg, up: l.up, })
    Blk(l) => Arg({ me: arg, up: l.up, })
    Jmp(l) => Arg({ me: arg, up: l.up.up, })
    Def(l) => Arg({ me: arg, up: l.up.up, })
    Phi(l) => Arg({ me: arg, up: l.up.up, })
    Top(_) => raise self.reject("arg")
  }
}

///|
fn find_parent_sub(
  prog : @types.Term[@types.Program],
  blk : @types.Term[@types.Blk],
) -> @types.Term[@types.Sub]? {
  let tid = blk.tid()
  for sub in prog.payload().subs {
    if sub.find_blk(tid) is Some(_) {
      return Some(sub)
    }
  }
  None
}

///|
/// Transition to a block term. From the top level, the parent subroutine
/// is looked up in the program.
pub fn Pos::next_blk(
  self : Pos,
  blk : @types.Term[@types.Blk],
) -> Pos raise PrimusError {
  match self {
    Def(l) => Blk({ me: blk, up: l.up.up, })
    Jmp(l) => Blk({ me: blk, up: l.up.up, })
    Phi(l) => Blk({ me: blk, up: l.up.up, })
    Sub(up) => Blk({ me: blk, up, })
    Arg(l) => Blk({ me: blk, up: l.up, })
    Blk(l) => Blk({ me: blk, up: l.up, })
    Top(top) =>
      match find_parent_sub(top.me, blk) {
        Some(sub) => Blk({ me: blk, up: { me: sub, up: top, }, })
        None => raise self.reject("blk")
      }
  }
}

///|
/// Transition to a phi term.
pub fn Pos::next_phi(
  self : Pos,
  phi : @types.Term[@types.Phi],
) -> Pos raise PrimusError {
  match self {
    Blk(up) => Phi({ me: phi, up, })
    Phi(l) => Phi({ me: phi, up: l.up, })
    _ => raise self.reject("phi")
  }
}

///|
/// Transition to a definition term.
pub fn Pos::next_def(
  self : Pos,
  def : @types.Term[@types.Def],
) -> Pos raise PrimusError {
  match self {
    Blk(up) => Def({ me: def, up, })
    Phi(l) => Def({ me: def, up: l.up, })
    Def(l) => Def({ me: def, up: l.up, })
    _ => raise self.reject("def")
  }
}

///|
/// Transition to a jump term.
pub fn Pos::next_jmp(
  self : Pos,
  jmp : @types.Term[@types.Jmp],
) -> Pos raise PrimusError {
  match self {
    Blk(up) => Jmp({ me: jmp, up, })
    Phi(l) => Jmp({ me: jmp, up: l.up, })
    Def(l) => Jmp({ me: jmp, up: l.up, })
    Jmp(l) => Jmp({ me: jmp, up: l.up, })
    _ => raise self.reject("jmp")
  }
}
