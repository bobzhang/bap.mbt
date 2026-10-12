// Port of `plugins/taint/taint_main.ml`: the legacy taint seeding pass.
//
// Injects taints into a program based on a specification. A definition
// that matches a *strain* is marked as a taint source: with the
// `tainted-reg` attribute (the value stored in the register is tainted)
// or with the `tainted-ptr` attribute (the value pointed by the register
// is tainted). The value of the attribute is the seed of the taint: the
// origin of the definition if it is synthetic, otherwise its own term
// identifier.

///|
/// A condition of a strain specification (upstream `strain`).
pub(all) enum Strain {
  /// the definition corresponds to an instruction at the address
  Addr(Int64)
  /// the definition has the given term identifier (e.g. `%42`; the
  /// textual identifier of the term, as upstream, or any spelling of the
  /// same numeric identifier accepted by `Tid::from_string`)
  Tid(String)
  /// the definition defines a variable with the given name
  Var(String)
} derive(Eq, Debug)

///|
pub extend Strain with Eq::{not_equal, equal}

///|
pub extend Strain with Debug::{to_repr}

///|
/// The grammar of strain specifications.
pub let grammar : String =
  #|
  #|    strain ::= <tid>
  #|             | <var>
  #|             | <addr>
  #|             | (<strain1> <strain2> .. <strainK>)
  #|    tid    ::= %<hex-digits>
  #|    var    ::= <alpha> .. <alpha-num>
  #|    addr   ::= 0x<hex-digits>
  #|

///|
fn expect(what : String, got~ : String) -> String {
  "expected \{what} got \{quote(got)}"
}

///|
fn quote(s : String) -> String {
  let buf = StringBuilder()
  buf.write_char('"')
  for c in s {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\t' => buf.write_string("\\t")
      c => buf.write_char(c)
    }
  }
  buf.write_char('"')
  buf.to_string()
}

///|
fn hex_digit(c : Char) -> Int32? {
  match c {
    '0'..<='9' => Some(c.to_int() - '0'.to_int())
    'a'..<='f' => Some(c.to_int() - 'a'.to_int() + 10)
    'A'..<='F' => Some(c.to_int() - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// Parses an OCaml `Int64.of_string` hexadecimal literal (`0x...`, the
/// value wraps modulo 2^64).
fn parse_word(s : String) -> Int64? {
  guard s.has_prefix("0x") || s.has_prefix("0X") else { None }
  let digits = s.view(start_offset=2)
  if digits.is_empty() || digits.length() > 16 {
    return None
  }
  let mut acc = 0UL
  for c in digits {
    match hex_digit(c) {
      Some(d) => acc = (acc << 4) | d.to_uint64()
      None => return None
    }
  }
  Some(acc.reinterpret_as_int64())
}

///|
fn is_alpha(c : Char) -> Bool {
  (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
fn parse_atom(s : String) -> Result[Strain, String] {
  if s.has_prefix("0x") {
    match parse_word(s) {
      Some(a) => Ok(Addr(a))
      None => Err(expect("0x<hex-digits>", got=s))
    }
  } else if s.has_prefix("%") {
    Ok(Tid(s))
  } else if s.get_char(0) is Some(c) && is_alpha(c) {
    Ok(Var(s))
  } else {
    Err(expect("<tid> | <var> | <addr>", got=s))
  }
}

///|
/// Splits the specification into atoms; returns `None` if it is not an
/// atom or a flat list of atoms.
fn tokens(s : String) -> (Array[String], Bool)? {
  let text = s.trim(chars=" \t\n\r").to_owned()
  let is_list = text.has_prefix("(")
  let body = if is_list {
    guard text.has_suffix(")") else { return None }
    text.view(start_offset=1, end_offset=text.length() - 1).to_owned()
  } else {
    text
  }
  let atoms = []
  let buf = StringBuilder()
  for c in body {
    match c {
      ' ' | '\t' | '\n' | '\r' => {
        let atom = buf.to_string()
        buf.reset()
        if !atom.is_empty() {
          atoms.push(atom)
        }
      }
      '(' | ')' | '"' | ';' => return None
      c => buf.write_char(c)
    }
  }
  let atom = buf.to_string()
  if !atom.is_empty() {
    atoms.push(atom)
  }
  if !is_list && atoms.length() != 1 {
    return None
  }
  Some((atoms, is_list))
}

///|
/// Parses a strain specification (upstream `Strain.parse`): an atom or a
/// list of atoms, all of which must be satisfied.
pub fn parse_strain(s : String) -> Result[Array[Strain], String] {
  guard tokens(s) is Some((atoms, _)) else { Err(expect(grammar, got=s)) }
  let out = []
  for atom in atoms {
    match parse_atom(atom) {
      Ok(x) => out.push(x)
      Err(e) => return Err(e)
    }
  }
  Ok(out)
}

///|
/// Renders a strain condition (upstream `Strain.to_string`: addresses are
/// printed in hexadecimal without a prefix).
pub fn Strain::to_string(self : Strain) -> String {
  match self {
    Addr(a) => {
      let hex = "0123456789abcdef"
      let mut n = a.reinterpret_as_uint64()
      if n == 0UL {
        return "0"
      }
      let buf = []
      while n != 0UL {
        buf.push(hex[(n & 15UL).to_int()].unsafe_to_char())
        n = n >> 4
      }
      String::from_array(buf.rev())
    }
    Tid(s) | Var(s) => s
  }
}

///|
/// Renders a strain specification as `(s1 s2 ...)` (upstream `Strain.pp`).
pub fn strain_to_string(strain : ArrayView[Strain]) -> String {
  "(" + strain.iter().map(s => s.to_string()).join(" ") + ")"
}

///|
fn def_address(def : @types.Term[@types.Def]) -> Int64? {
  guard def.get_attr("address") is Some(text) else { None }
  let w = @types.Word::from_string(text) catch { _ => return None }
  let n = w.to_int64() catch {
    _ => w.to_uint64().reinterpret_as_int64() catch { _ => return None }
  }
  Some(n)
}

///|
/// [satisfies(strain, def)] is `true` if the definition satisfies every
/// condition of the strain (upstream `Marker.sats`).
pub fn satisfies(
  strain : ArrayView[Strain],
  def : @types.Term[@types.Def],
) -> Bool {
  strain
  .iter()
  .all(s => {
    match s {
      Tid(name) =>
        def.tid().to_string() == name ||
        (
          def.tid().name() is None &&
          @types.Tid::from_string(name) is Ok(tid) &&
          tid.id() == def.tid().id()
        )
      Var(name) => def.lhs().name() == name
      Addr(a) => def_address(def) == Some(a)
    }
  })
}

///|
/// The seed of a taint introduced by the term: its origin, if any,
/// otherwise its own identifier (upstream `Marker.seed`).
pub fn[T] seed(term : @types.Term[T]) -> @types.Tid {
  match term.origin() {
    Some(tid) => tid
    None => term.tid()
  }
}

///|
fn mark_def(
  key : String,
  strains : ArrayView[Array[Strain]],
  def : @types.Term[@types.Def],
) -> @types.Term[@types.Def] {
  strains.fold(init=def, (def, strain) => {
    if satisfies(strain, def) {
      def.set_attr(@types.Attr::new(key~, value=seed(def).to_string()))
    } else {
      def
    }
  })
}

///|
/// Marks every definition of the program that satisfies one of the
/// register strains with `tainted-reg` and every definition that
/// satisfies one of the pointer strains with `tainted-ptr` (upstream
/// `Marker.run`).
pub fn mark(
  regs~ : ArrayView[Array[Strain]],
  ptrs~ : ArrayView[Array[Strain]],
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    sub.map_blks(blk => {
      blk.map_defs(def => {
        let def = mark_def(@taint_lib.tainted_reg_attr, regs, def)
        mark_def(@taint_lib.tainted_ptr_attr, ptrs, def)
      })
    })
  })
}

///|
/// The name of the pass.
pub let name : String = "taint"

///|
/// The seeding pass (upstream `Project.register_pass ~deps:["callsites"]
/// ~autorun:true (mark regs ptrs)`).
pub fn pass(
  regs~ : Array[Array[Strain]],
  ptrs~ : Array[Array[Strain]],
) -> @project.ProjectPass {
  @project.ProjectPass::create(name~, autorun=true, deps=["callsites"], run=proj => {
    Ok(proj.map_program(prog => mark(regs~, ptrs~, prog)))
  })
}

///|
/// Registers the seeding pass for the given `--taint-reg` and
/// `--taint-ptr` specifications. As upstream, nothing is registered when
/// both lists are empty. Idempotent: returns `Ok(false)` if nothing was
/// registered.
pub fn register(
  regs~ : Array[Array[Strain]] = [],
  ptrs~ : Array[Array[Strain]] = [],
) -> Result[Bool, String] {
  if regs.is_empty() && ptrs.is_empty() {
    return Ok(false)
  }
  @project.register_pass_if_absent(pass(regs~, ptrs~))
}
