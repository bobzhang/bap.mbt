// Definitions (upstream `Bap_primus_lisp_def`).

///|
/// A definition of kind `T`: its name, documentation, attributes, the
/// definition itself, and the identifier of the tree from which it was
/// created (`0` for definitions that do not originate from sources, e.g.,
/// primitives).
pub struct Def[T] {
  name : String
  docs : String
  attrs : Attrs
  code : T
  id : Int
}

///|
pub fn[T] Def::new(
  name : String,
  docs? : String = "",
  attrs? : Attrs = Attrs::empty(),
  id? : Int = 0,
  code : T,
) -> Def[T] {
  { name, docs, attrs, code, id, }
}

///|
pub fn[T] Def::rename(self : Def[T], name : String) -> Def[T] {
  { ..self, name, }
}

///|
/// The context of the definition.
pub fn[T] Def::context(self : Def[T]) -> Context {
  self.attrs.context
}

///|
/// A function or a method (upstream `Def.func`, `Def.meth`).
pub(all) struct Func {
  args : Array[LVar]
  body : Ast
}

///|
pub fn Def::with_body(self : Def[Func], body : Ast) -> Def[Func] {
  { ..self, code: { ..self.code, body, }, }
}

///|
/// A macro: formal parameters and the body (upstream `Def.macro`).
pub(all) struct Macro {
  params : Array[String]
  body : Tree
}

///|
/// A substitution (upstream `Def.subst`).
pub(all) struct Subst {
  elts : Array[Tree]
}

///|
/// A constant (upstream `Def.const`).
pub(all) struct Const {
  value : String
}

///|
/// The value of a constant as a tree with the identity of the constant.
pub fn Def::const_value(self : Def[Const]) -> Tree {
  { data: Atom(self.code.value), id: self.id, }
}

///|
/// A place, i.e., a variable that is known to the Lisp program, e.g., a
/// register or a global variable (upstream `Def.place`).
pub(all) struct Place {
  location : @types.Var
}

///|
/// A parameter (upstream `Def.para`).
pub(all) struct Para {
  default : Ast
}

///|
/// A host function that implements a primitive: takes the machine, the
/// name of the primitive (as it was called), and the arguments.
pub struct Closure {
  run : (@primus.Machine, String, Array[@primus.Value]) -> @primus.Value raise
}

///|
pub fn Closure::new(
  run : (@primus.Machine, String, Array[@primus.Value]) -> @primus.Value raise,
) -> Closure {
  { run, }
}

///|
/// A primitive: its implementation and the optional type signature
/// (upstream `Def.prim`).
pub(all) struct Prim {
  lambda : Closure
  types : Signature?
}

///|
/// A semantic primitive, used by the Lisp-to-BIL compiler (upstream
/// `Def.sema`).
pub(all) struct Sema {
  types : Signature
  apply : SemaBody
}

///|
/// A signal, i.e., an observation reflected into the Lisp methods (upstream
/// `Def.signal`).
pub(all) struct Signal {
  types : Signature
}

///|
/// Binds the macro parameters to the actual arguments (upstream
/// `Macro.bind`). The last parameter captures the rest of the arguments if
/// there are more arguments than parameters. Returns the number of the
/// arguments captured by the last parameter and the bindings.
pub fn Def::macro_bind(
  self : Def[Macro],
  args : Array[Tree],
) -> (Int, Array[(String, Array[Tree])])? {
  let ps = self.code.params
  let bs = []
  let np = ps.length()
  let na = args.length()
  let mut i = 0
  while true {
    if i == np && i == na {
      break
    } else if i == np - 1 && na - i >= 2 {
      bs.push((ps[i], args[i:].to_owned()))
      break
    } else if i < np && i < na {
      bs.push((ps[i], [args[i]]))
      i += 1
    } else {
      return None
    }
  }
  match bs {
    [] => Some((0, []))
    _ => Some((bs[bs.length() - 1].1.length(), bs))
  }
}

///|
pub(all) suberror MacroError {
  BadSubst(Tree, Array[Tree])
} derive(Debug)

///|
fn find_binding(bs : Array[(String, Array[Tree])], x : String) -> Array[Tree]? {
  for b in bs {
    if b.0 == x {
      return Some(b.1)
    }
  }
  None
}

///|
/// Substitutes the macro parameters in the macro body with the bound
/// trees (upstream `Macro.apply`).
pub fn Def::macro_apply(
  self : Def[Macro],
  bs : Array[(String, Array[Tree])],
) -> Tree raise MacroError {
  fn sub(t : Tree) -> Array[Tree] {
    match t.data {
      List(xs) => {
        let out = []
        for x in xs {
          out.append(sub(x))
        }
        [{ data: List(out), id: t.id, }]
      }
      Atom(x) =>
        match find_binding(bs, x) {
          None => [t]
          Some(cs) => cs
        }
    }
  }

  let body = self.code.body
  match body.data {
    List(xs) => {
      let out = []
      for x in xs {
        out.append(sub(x))
      }
      { data: List(out), id: body.id, }
    }
    Atom(x) =>
      match find_binding(bs, x) {
        None => body
        Some([x]) => x
        Some(xs) => raise BadSubst(body, xs)
      }
  }
}
