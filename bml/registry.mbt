// Port of `Bap_bml`: the standard library of the BAP Mapping Language
// (BML) and the registries that allow extending it.

///|
using @types {type Attr, type IrTerm}

///|
/// A predicate over IR terms (upstream `bool Term.visitor`, of which only
/// `enter_term` is used). Predicates may be stateful: they are called on
/// the terms in the traversal order, parents before children.
pub type Predicate = (IrTerm) -> Bool

///|
/// A term mapper (upstream `Term.mapper`). Mappers returned by the standard
/// library transform a term together with all of its subterms, as upstream
/// markers do.
pub type Mapper = (IrTerm) -> IrTerm

///|
/// A parser error (upstream `Parse_error`), raised by unary constructors
/// on a malformed argument.
pub(all) suberror ParseError {
  ParseError(String)
} derive(Eq, Debug)

///|
pub extend ParseError with Eq::{not_equal, equal}

///|
pub extend ParseError with Debug::{to_repr}

///|
/// A key value storage (upstream `Registry`).
pub struct Registry[T] {
  priv registered : Map[String, T]
}

///|
/// Creates an empty registry.
pub fn[T] Registry::new() -> Registry[T] {
  { registered: Map([]), }
}

///|
/// [registry.register(name, value)] registers [value] with the given
/// [name], superseding a previous binding of [name].
pub fn[T] Registry::register(
  self : Registry[T],
  name : String,
  value : T,
) -> Unit {
  self.registered[name] = value
}

///|
/// [registry.find(name)] finds the value associated with [name].
pub fn[T] Registry::find(self : Registry[T], name : String) -> T? {
  self.registered.get(name)
}

///|
/// Lists all bindings, in the order of their first registration.
pub fn[T] Registry::list(self : Registry[T]) -> Array[(String, T)] {
  self.registered.to_array()
}

///|
/// Nullary and unary operations of the same kind (upstream `Ops`).
pub struct Ops[T] {
  nullary : Registry[T]
  unary : Registry[(String) -> T raise ParseError]
}

///|
fn[T] Ops::new() -> Ops[T] {
  { nullary: Registry::new(), unary: Registry::new(), }
}

///|
/// The registered predicates (upstream `Predicates`), initialized with the
/// standard library and the `map_terms` plugin predicates.
pub let predicates : Ops[Predicate] = stdlib_predicates()

///|
/// The registered mappers (upstream `Mappers`), initialized with the
/// standard library and the `map_terms` plugin mappers.
pub let mappers : Ops[Mapper] = stdlib_mappers()

///|
/// [map_deep(term, f)] applies [f] to [term] and then, recursively, to all
/// subterms of the result (parents before children), like upstream
/// `Term.mapper` subclasses that call `super#map_term`.
pub fn map_deep(term : IrTerm, f : (IrTerm) -> IrTerm) -> IrTerm {
  map_children(f(term), child => map_deep(child, f))
}

///|
/// [map_children(term, f)] applies [f] to the direct subterms of [term]
/// (subroutines of a program; arguments and blocks of a subroutine; phi
/// nodes, definitions and jumps of a block).
pub fn map_children(term : IrTerm, f : (IrTerm) -> IrTerm) -> IrTerm {
  match term {
    ProgramTerm(p) => {
      let subs = p.payload().subs.map(s => {
        match f(SubTerm(s)) {
          SubTerm(s) => s
          _ => s
        }
      })
      ProgramTerm(p.with_payload({ subs, }))
    }
    SubTerm(s) => {
      let payload = s.payload()
      let args = payload.args.map(a => {
        match f(ArgTerm(a)) {
          ArgTerm(a) => a
          _ => a
        }
      })
      let blks = payload.blks.map(b => {
        match f(BlkTerm(b)) {
          BlkTerm(b) => b
          _ => b
        }
      })
      SubTerm(s.with_payload({ ..payload, args, blks, }))
    }
    BlkTerm(b) => {
      let payload = b.payload()
      let phis = payload.phis.map(t => {
        match f(PhiTerm(t)) {
          PhiTerm(t) => t
          _ => t
        }
      })
      let defs = payload.defs.map(t => {
        match f(DefTerm(t)) {
          DefTerm(t) => t
          _ => t
        }
      })
      let jmps = payload.jmps.map(t => {
        match f(JmpTerm(t)) {
          JmpTerm(t) => t
          _ => t
        }
      })
      BlkTerm(b.with_payload({ phis, defs, jmps, }))
    }
    ArgTerm(_) | PhiTerm(_) | DefTerm(_) | JmpTerm(_) => term
  }
}

///|
/// [marker(attr)] is a mapper that sets [attr] on a term and all of its
/// subterms (upstream `marker`).
pub fn marker(attr : Attr) -> Mapper {
  term => map_deep(term, t => t.set_attr(attr))
}

///|
/// [has(key)] is satisfied by terms that have the attribute [key].
pub fn has(key : String) -> Predicate {
  term => term.has_attr(key)
}
