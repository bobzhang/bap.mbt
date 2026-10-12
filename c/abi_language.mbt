// Port of `C.Abi.Arg.install`, `C.Abi.define`, and the high-level
// `C.Abi.Arg.Language` (V1) combinators from `bap_c_abi.ml`.
//
// The language describes calling conventions declaratively with commands,
// i.e., pairs of a predicate over the argument type and a statement that
// passes the argument. Upstream exposes the combinators as the module
// `Arg.Language`; here they are static functions of the `Language` type.

///|
/// A predicate over an argument type.
pub type Predicate = (CType) -> Bool

///|
/// A statement that passes an argument of the given type.
pub type Statement = (CType) -> Arg[Unit]

///|
/// A guarded statement.
pub type Command = (Predicate, Statement)

///|
/// The namespace of the high-level ABI specification language (upstream
/// `C.Abi.Arg.Language`).
pub(all) struct Language {}

///|
/// `Language::sequence(cmds)` executes all commands whose predicates hold,
/// in the specified order; if any executed statement is rejected, the whole
/// sequence is rejected.
pub fn Language::sequence(cmds : Array[Command]) -> Statement {
  arg => {
    Arg::iter(cmds, cmd => {
      if (cmd.0)(arg) {
        (cmd.1)(arg)
      } else {
        Arg::pure(())
      }
    })
  }
}

///|
/// `Language::select(cmds)` selects the first command whose predicate holds
/// and runs its statement. Rejected if none applies.
pub fn Language::select(cmds : Array[Command]) -> Statement {
  arg => {
    for cmd in cmds {
      if (cmd.0)(arg) {
        return (cmd.1)(arg)
      }
    }
    Arg::reject()
  }
}

///|
/// `Language::case(classify, cases)` classifies the argument and runs the
/// statement of the matching class. Rejected if no class matches.
pub fn[K : Eq] Language::case(
  classify : (CType) -> Arg[K],
  cases : Array[(K, Statement)],
) -> Statement {
  arg => {
    classify(arg).bind(cls => {
      for entry in cases {
        if entry.0 == cls {
          return (entry.1)(arg)
        }
      }
      Arg::reject()
    })
  }
}

///|
/// Holds if any of the predicates holds.
pub fn Language::any(ps : Array[Predicate]) -> Predicate {
  x => ps.iter().any(p => p(x))
}

///|
/// Holds if all of the predicates hold.
pub fn Language::all(ps : Array[Predicate]) -> Predicate {
  x => ps.iter().all(p => p(x))
}

///|
/// Holds if none of the predicates holds.
pub fn Language::neither(ps : Array[Predicate]) -> Predicate {
  x => ps.iter().all(p => !p(x))
}

///|
/// `Language::is_(cnd)` (upstream `is`) holds if `cnd` holds.
pub fn Language::is_(cnd : Bool) -> Predicate {
  _ => cnd
}

///|
/// Always holds; intended as the last catch-all predicate of `select`.
pub fn Language::otherwise() -> Predicate {
  _ => true
}

///|
/// Always holds.
pub fn Language::always() -> Predicate {
  _ => true
}

///|
/// Never holds.
pub fn Language::never() -> Predicate {
  _ => false
}

///|
/// `Language::choose(options)` tries the options in order until the first
/// one that is not rejected.
pub fn Language::choose(options : Array[Statement]) -> Statement {
  arg => Arg::choice(options.map(f => f(arg)))
}

///|
/// `Language::combine(xs)` evaluates all statements in order; rejected if
/// any of them is rejected.
pub fn Language::combine(xs : Array[Statement]) -> Statement {
  arg => Arg::iter(xs, x => x(arg))
}

///|
/// The argument-passing rule of a calling convention: it is given the
/// alignment (in bits) and the size (in bits) of the argument type.
pub type SizedStatement = (Int32, Int32) -> Statement

///|
/// The `describe` callback of `Language::install` for one prototype.
pub struct Describer {
  priv proto : Proto
}

///|
/// A describer for the given prototype (`Language::install` creates one
/// per processed subroutine).
pub fn Describer::new(proto : Proto) -> Describer {
  { proto, }
}

///|
/// Describes a calling convention: `return_` passes the return value (if
/// it is not `void`), `args` passes each argument, and `finish` runs after
/// all arguments are passed. Both rules receive the alignment and the size
/// of the type (the computation is rejected if the size is unknown).
pub fn Describer::describe(
  self : Describer,
  finish~ : Arg[Unit] = Arg::pure(()),
  return_~ : SizedStatement,
  args : SizedStatement,
) -> Arg[Unit] {
  let r = self.proto.return_
  let ret = match r {
    Void => Arg::pure(())
    _ =>
      Arg::size(r).bind(size => {
        Arg::alignment(r).bind(alignment => return_(alignment, size)(r))
      })
  }
  let inputs = Arg::iter(self.proto.args, arg => {
    let t = arg.1
    Arg::size(t).bind(size => {
      Arg::alignment(t).bind(alignment => args(alignment, size)(t))
    })
  })
  Arg::sequence([switch_to(Return), ret, switch_to(Inputs), inputs, finish])
}

///|
/// `define_abi(target, ruler, pass)` creates an ABI processor from the
/// argument-passing specification `pass` (upstream `C.Abi.define`, aka
/// `Arg.install`), registers it under the unqualified target name, and
/// registers `ruler` as the data model of the target. It also registers an
/// ABI pass (`@abi.register_pass`) that, for projects of this target,
/// registers the C API processor (`process_api`) and sets the project's ABI
/// name.
pub fn define_abi(
  target : @core_theory.Target,
  ruler : &Ruler,
  pass : (Array[Attr], Proto) -> Arg[Unit],
) -> Unit raise AbiError {
  let abi_name = target.name().unqualified()
  let processor : AbiProcessor = {
    apply_attrs: (_, sub) => sub,
    insert_args: (_, attrs, proto) => {
      Arg::reify(target, ruler, pass(attrs, proto))
    },
  }
  register_abi(abi_name, processor)
  register_model(target, ruler)
  @abi.register_pass(proj => {
    if proj.target().equal(target) {
      process_api(create_api_processor(ruler, processor))
      proj.set_tag(@abi.name(), abi_name)
    } else {
      proj
    }
  })
}

///|
/// `Language::install(target, ruler, spec)` installs the calling convention
/// for the target (upstream `Arg.Language.install`); `spec` receives a
/// `Describer` for the prototype being processed.
///
/// For example, a convention that passes integers in registers and falls
/// back to memory:
///
/// ```mbt nocheck
/// Language::install(target, ruler, describer => {
///   Arena::iargs(target).bind(iargs => {
///     Arena::irets(target).bind(irets => {
///       describer.describe(
///         return_=(_, _) => t => Arg::register(irets, t),
///         (_, _) => Language::choose([
///           t => Arg::register(iargs, t),
///           Arg::memory,
///         ]),
///       )
///     })
///   })
/// })
/// ```
pub fn Language::install(
  target : @core_theory.Target,
  ruler : &Ruler,
  spec : (Describer) -> Arg[Unit],
) -> Unit raise AbiError {
  define_abi(target, ruler, (_, proto) => spec({ proto, }))
}
