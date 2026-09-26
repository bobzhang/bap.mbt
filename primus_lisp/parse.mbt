// The Lisp parser: from syntax trees to definitions and expressions
// (upstream `Bap_primus_lisp_parse`).

///|
/// Kinds of top-level definitions.
pub(all) enum DefKind {
  KFunc
  KMacro
  KConst
  KSubst
  KMeth
  KPara
  KInpkg
  KDefpkg
} derive(Eq, Debug)

///|
/// Parse errors (upstream `parse_error`).
pub(all) enum ParseProblem {
  BadVarLiteral(VarReadError)
  BadWordLiteral(WordReadError)
  BadForm(String)
  BadApp
  BadLetBinding
  BadParamList
  BadMacroParamList
  BadRequire
  UnknownToplevel
  BadToplevel
  BadDef(DefKind)
  BadAscii
  BadHex
  UnknownSubstSyntax
  Unresolved(DefKind, @knowledge.Name, Resolution)
  BadAttribute(AttributeError)
  BadMacroSubst
  MacroExpansionLimit
}

///|
/// Errors in format strings of the `msg` form.
pub(all) enum FormatProblem {
  ExpectDigit
  IllegalEscape(Char)
  UnterminatedEsc
  UnterminatedExp
} derive(Eq, Debug)

///|
/// Who requested a feature.
pub(all) enum Request {
  Cmdline
  Module(Loc)
} derive(Eq, Debug)

///|
/// Errors of the Lisp program loader (upstream `Load.error`).
pub(all) suberror LoadError {
  ParseError(ParseProblem, Loc)
  FormatError(FormatProblem, Loc)
  SexpParseError(String, Request, SexpError)
  UnresolvedFeature(String, Request)
}

///|
/// The source store of the program that is being parsed, used to compute
/// the locations of parse errors.
let current_source : Ref[Source] = Ref(Source::new())

///|
fn pfail(p : ParseProblem, trees : Array[Tree]) -> LoadError {
  ParseError(p, current_source.val.loc_of_trees(trees))
}

///|
fn string_of_defkind(k : DefKind) -> String {
  match k {
    KFunc => "function"
    KMeth => "method"
    KPara => "parameter"
    KMacro => "macro"
    KConst => "constant"
    KSubst => "substitution"
    KInpkg => "in-package"
    KDefpkg => "defpackage"
  }
}

///|
fn string_of_def_syntax(k : DefKind) -> String {
  match k {
    KFunc =>
      "(defun <ident> (<var> ...) [<docstring>] [<declarations>] <exp> ...)"
    KMeth =>
      "(defmethod <ident> (<var> ...) [<docstring>] [<declarations>] <exp> ..."
    KPara => "(defparameter <ident> <exp> [<docstring>] [<declarations>])"
    KMacro =>
      "(defmacro <ident> (<ident> ...) [<docstring>] [<declarations>] <exp>)"
    KConst => "(defconstant <ident> [<docstring>] [<declarations>] <atom>)"
    KSubst =>
      "(defsubst <ident> [<docstring>] [<declarations>] [:<syntax>] <atom> ...)"
    KInpkg => "(in-package <ident>)"
    KDefpkg =>
      "(defpackage <ident> (:use <package-list>) (:documentation <docstring>))"
  }
}

///|
fn string_of_form_syntax(name : String) -> String {
  match name {
    "if" => "(if <exp> <exp> <exp> ...)"
    "let" => "(let ((<var> <exp>) ...) <exp> ...)"
    "while" => "(while <exp> <exp> <exp> ...)"
    "msg" => "(msg <fmt> <exp> ...)"
    "set" => "(set <var> <exp>)"
    "prog" => "(prog <exp> ...)"
    "error" => "(error \"<msg>\")"
    _ => name
  }
}

///|
pub impl Show for ParseProblem with fn output(self, logger) {
  let msg = match self {
    BadVarLiteral(e) => "bad variable literal - \{string_of_var_error(e)}"
    BadWordLiteral(e) => "bad word literal - \{string_of_word_error(e)}"
    BadForm(name) =>
      "bad \{name} syntax - expected \{string_of_form_syntax(name)}"
    BadApp => "head of the list in the application form shall be an atom"
    BadLetBinding => "expected a variable literal"
    BadParamList => "expected a list of variables"
    BadMacroParamList => "expected a list of atoms"
    BadRequire => "expected (require <feature>)"
    UnknownToplevel => "unknown toplevel form"
    BadToplevel => "bad toplevel syntax"
    BadAscii | BadHex => "expected a list of atoms"
    UnknownSubstSyntax => "unknown substitution syntax"
    Unresolved(k, n, r) =>
      "unable to resolve \{string_of_defkind(k)} `\{n.show()}', because \{r}"
    BadDef(d) =>
      "bad \{string_of_defkind(d)} definition, expect \{string_of_def_syntax(d)}"
    BadAttribute(e) => e.to_string()
    BadMacroSubst => "a macro parameter is substituted with several trees"
    MacroExpansionLimit => "the macro expansion depth limit is reached"
  }
  logger.write_string(msg)
}

///|
pub impl Show for LoadError with fn output(self, logger) {
  match self {
    ParseError(err, loc) => logger.write_string("\{loc}\nParse error: \{err}")
    FormatError(err, loc) => {
      let msg = match err {
        ExpectDigit => "expected digit"
        UnterminatedEsc => "unterminated escape sequence"
        UnterminatedExp => "unterminated reference"
        IllegalEscape(c) => "illegal escape character '\{c}'"
      }
      logger.write_string("\{loc}\nFormat error: \{msg}")
    }
    SexpParseError(name, req, err) =>
      logger.write_string(
        "\{err}\nOccured when parsing feature \{name} \{show_request(req)}",
      )
    UnresolvedFeature(name, req) =>
      logger.write_string(
        "Error: no implementation provided for feature `\{name}' \{show_request(req)}",
      )
  }
}

///|
fn show_request(r : Request) -> String {
  match r {
    Cmdline => "requested by a user"
    Module(loc) => "requested in \{loc}"
  }
}

///|
fn is_quoted(s : String) -> Bool {
  let n = s.length()
  n > 1 && s.has_prefix("\"") && s.has_suffix("\"")
}

///|
fn is_symbol_literal(s : String) -> Bool {
  s.length() > 1 && (s.has_prefix("'") || s.has_prefix(":"))
}

///|
fn is_keyword(s : String) -> Bool {
  s.length() > 1 && s.has_prefix(":")
}

///|
/// Removes the double quotes around the string, if any.
pub fn unquote(s : String) -> String {
  if is_quoted(s) {
    s.unsafe_substring(start=1, end=s.length() - 1)
  } else {
    s
  }
}

///|
fn symbol_name(pkg : String, s : String) -> @knowledge.Name {
  if is_keyword(s) {
    @knowledge.Name::read(s)
  } else {
    @knowledge.Name::read(s.unsafe_substring(start=1, end=s.length()), pkg~)
  }
}

///|
/// Interprets an OCaml escape sequence `\c` (upstream `Scanf.unescaped`).
fn unescape_char(c : Char) -> Char? {
  match c {
    'n' => Some('\n')
    't' => Some('\t')
    'b' => Some('\b')
    'r' => Some('\r')
    ' ' => Some(' ')
    '\\' => Some('\\')
    '"' => Some('"')
    '\'' => Some('\'')
    _ => None
  }
}

///|
/// Unescapes an OCaml string literal body (upstream `Scanf.unescaped`).
pub fn unescape_string(s : String) -> String? {
  let buf = StringBuilder()
  let chars = s.to_array()
  let n = chars.length()
  let mut i = 0
  while i < n {
    let c = chars[i]
    if c == '\\' {
      if i + 1 >= n {
        return None
      }
      let d = chars[i + 1]
      if d >= '0' && d <= '9' {
        if i + 3 >= n + 0 && i + 3 > n {
          return None
        }
        let mut v = 0
        for k in 1..<=3 {
          let e = chars[i + k]
          if e < '0' || e > '9' {
            return None
          }
          v = v * 10 + (e.to_int() - '0'.to_int())
        }
        buf.write_char(v.unsafe_to_char())
        i += 4
      } else if d == 'x' {
        if i + 3 >= n {
          return None
        }
        let h = digit_value(chars[i + 2]) * 16 + digit_value(chars[i + 3])
        if h > 255 {
          return None
        }
        buf.write_char(h.unsafe_to_char())
        i += 4
      } else if d == '\n' {
        // an escaped newline skips the leading blanks of the next line
        i += 2
        while i < n && (chars[i] == ' ' || chars[i] == '\t') {
          i += 1
        }
      } else {
        match unescape_char(d) {
          Some(u) => buf.write_char(u)
          None => return None
        }
        i += 2
      }
    } else {
      buf.write_char(c)
      i += 1
    }
  }
  Some(buf.to_string())
}

///|
/// The parser state: the program (for the resolution of macros,
/// constants, and substitutions) and the macro expansion depth.
priv struct Parser {
  prog : Program
  mut depth : Int
}

///|
fn Parser::fresh(self : Parser, t : Tree) -> Int {
  self.prog.sources.derive_id(t.id)
}

///|
fn Parser::let_var(self : Parser, t : Tree) -> LVar raise LoadError {
  match t.data {
    List(_) => raise pfail(BadLetBinding, [t])
    Atom(x) =>
      match read_var(pkg=self.prog.pkg, self.fresh(t), x) {
        Ok(v) => v
        Err(e) => raise pfail(BadVarLiteral(e), [t])
      }
  }
}

///|
fn Parser::expand(
  self : Parser,
  cs : ArrayView[Tree],
) -> Array[Tree] raise LoadError {
  let out = []
  for c in cs {
    match c.data {
      List(_) => out.push(c)
      Atom(x) => {
        let name = @knowledge.Name::read(x, pkg=self.prog.pkg)
        match resolve_simple(self.prog, subst, name) {
          None => out.push(c)
          Some(Err(r)) => raise pfail(Unresolved(KSubst, name, r), [c])
          Some(Ok(d)) =>
            for t in d.code.elts {
              out.push({ data: t.data, id: c.id, })
            }
        }
      }
    }
  }
  out
}

///|
/// Parses a `msg` format string: literal text, `$N` positional references,
/// and escape sequences.
fn Parser::fmt(
  self : Parser,
  fmt : String,
  tree : Tree,
) -> Array[Fmt] raise LoadError {
  let fmt = unquote(fmt)
  let fail = (err : FormatProblem, off : Int) => {
    let loc = self.prog.sources.loc_of_trees([tree]).nth_char(off + 1)
    raise FormatError(err, loc)
  }
  let out : Array[Fmt] = []
  let lit = StringBuilder()
  let flush = () => {
    let s = lit.to_string()
    if s != "" {
      out.push(Lit(s))
    }
    lit.reset()
  }
  let chars = fmt.to_array()
  let mut state = 0 // 0 - literal, 1 - escape, 2 - reference
  for off, c in chars {
    match state {
      0 =>
        if c == '\\' {
          flush()
          state = 1
        } else if c == '$' {
          flush()
          state = 2
        } else {
          lit.write_char(c)
        }
      1 => {
        if c == '$' {
          out.push(Lit("$"))
        } else {
          match unescape_char(c) {
            Some(u) => out.push(Lit(u.to_string()))
            None => fail(IllegalEscape(c), off)
          }
        }
        state = 0
      }
      _ => {
        if c >= '0' && c <= '9' {
          out.push(Pos(c.to_int() - '0'.to_int()))
        } else {
          fail(ExpectDigit, off)
        }
        state = 0
      }
    }
  }
  match state {
    0 => flush()
    1 => fail(UnterminatedEsc, chars.length())
    _ => fail(UnterminatedExp, chars.length())
  }
  out
}

///|
fn Parser::parse(self : Parser, tree : Tree) -> Ast raise LoadError {
  match tree.data {
    List(xs) => self.list(tree, xs)
    Atom(ux) => {
      let x = @knowledge.Name::read(ux, pkg=self.prog.pkg)
      match resolve_simple(self.prog, const_item, x) {
        None => self.lit(tree, ux)
        Some(Err(r)) => raise pfail(Unresolved(KConst, x, r), [tree])
        Some(Ok(c)) => {
          self.enter(tree)
          let r = self.parse(c.const_value())
          self.depth -= 1
          r
        }
      }
    }
  }
}

///|
fn Parser::enter(self : Parser, tree : Tree) -> Unit raise LoadError {
  self.depth += 1
  if self.depth > 2000 {
    raise pfail(MacroExpansionLimit, [tree])
  }
}

///|
fn Parser::cons(self : Parser, tree : Tree, data : Exp) -> Ast {
  { data, id: self.fresh(tree), }
}

///|
fn Parser::exps(
  self : Parser,
  xs : ArrayView[Tree],
) -> Array[Ast] raise LoadError {
  let out = []
  for x in xs {
    out.push(self.parse(x))
  }
  out
}

///|
fn Parser::seq(
  self : Parser,
  e : Tree,
  es : ArrayView[Tree],
) -> Ast raise LoadError {
  let xs = [self.parse(e)]
  xs.append(self.exps(es))
  { data: Seq(xs), id: self.prog.sources.derive_id(0), }
}

///|
fn Parser::lit(self : Parser, t : Tree, r : String) -> Ast raise LoadError {
  match read_word(self.fresh(t), r) {
    Ok(x) => self.cons(t, Int(x))
    Err(NotAnInt) => self.sym(t, r)
    Err(other) => raise pfail(BadWordLiteral(other), [t])
  }
}

///|
fn Parser::sym(self : Parser, t : Tree, r : String) -> Ast raise LoadError {
  if is_symbol_literal(r) {
    let name = symbol_name(self.prog.pkg, r)
    self.cons(t, Sym({ name, id: self.fresh(t), }))
  } else {
    match read_var(pkg=self.prog.pkg, self.fresh(t), r) {
      Ok(v) => self.cons(t, Var(v))
      Err(e) => raise pfail(BadVarLiteral(e), [t])
    }
  }
}

///|
fn Parser::list(
  self : Parser,
  tree : Tree,
  xs : Array[Tree],
) -> Ast raise LoadError {
  match xs {
    [] =>
      self.cons(tree, Int({ value: 0N, typ: Type(1), id: self.fresh(tree), }))
    [{ data: List(_), .. } as s, ..] => raise pfail(BadApp, [s])
    [{ data: Atom(op), .. }, .. args] =>
      match op {
        "if" =>
          match args {
            [c, e1, e2, .. es] =>
              self.cons(
                tree,
                Ite(self.parse(c), self.parse(e1), self.seq(e2, es)),
              )
            _ => raise pfail(BadForm("if"), [tree])
          }
        "let" =>
          match args {
            [{ data: List(bs), .. }, e, .. es] => {
              let mut body = self.seq(e, es)
              for i = bs.length() - 1; i >= 0; i = i - 1 {
                let b = bs[i]
                match b.data {
                  List([v, x]) =>
                    body = {
                      data: Let(self.let_var(v), self.parse(x), body),
                      id: self.fresh(b),
                    }
                  _ => raise pfail(BadLetBinding, [b])
                }
              }
              body
            }
            _ => raise pfail(BadForm("let"), [tree])
          }
        "prog" => self.cons(tree, Seq(self.exps(args)))
        "while" =>
          match args {
            [c, e, .. es] =>
              self.cons(tree, Rep(self.parse(c), self.seq(e, es)))
            _ => raise pfail(BadForm("while"), [tree])
          }
        "msg" =>
          match args {
            [{ data: Atom(msg), .. } as t, .. es] if is_quoted(msg) =>
              self.cons(tree, Msg(self.fmt(msg, t), self.exps(es)))
            _ => raise pfail(BadForm("msg"), [tree])
          }
        "set" =>
          match args {
            [v, e] => self.cons(tree, Set(self.let_var(v), self.parse(e)))
            _ => raise pfail(BadForm("set"), [tree])
          }
        "error" =>
          match args {
            [{ data: Atom(msg), .. }] if is_quoted(msg) =>
              self.cons(tree, Err(msg))
            _ => raise pfail(BadForm("error"), [tree])
          }
        _ => {
          let name = @knowledge.Name::read(op, pkg=self.prog.pkg)
          let args = self.expand(args)
          match resolve_macro(self.prog, name, args) {
            None => self.cons(tree, App(Dynamic(name), self.exps(args)))
            Some(Ok((m, bs))) => {
              let body = m.macro_apply(bs) catch {
                BadSubst(_, _) => raise pfail(BadMacroSubst, [tree])
              }
              self.enter(tree)
              let r = self.parse(body)
              self.depth -= 1
              r
            }
            Some(Err(r)) => raise pfail(Unresolved(KMacro, name, r), [tree])
          }
        }
      }
  }
}

///|
/// Parses a single expression in the context of the program (upstream
/// `Parse.parse`).
pub fn Program::parse_exp(self : Program, tree : Tree) -> Ast raise LoadError {
  current_source.val = self.sources
  let p = { prog: self, depth: 0, }
  p.parse(tree)
}

// ---------------------------------------------------------------------------
// Top-level forms

///|
fn params(p : Parser, t : Tree) -> Array[LVar] raise LoadError {
  match t.data {
    List(vars) => {
      let out = []
      for v in vars {
        out.push(p.let_var(v))
      }
      out
    }
    Atom(_) => raise pfail(BadParamList, [t])
  }
}

///|
fn metaparams(t : Tree) -> Array[String] raise LoadError {
  match t.data {
    List(vars) => {
      let out = []
      for v in vars {
        match v.data {
          Atom(x) => out.push(x)
          List(_) => raise pfail(BadMacroParamList, [v])
        }
      }
      out
    }
    Atom(_) => raise pfail(BadMacroParamList, [t])
  }
}

///|
fn parse_declarations(
  prog : Program,
  attrs : Attrs,
  trees : ArrayView[Tree],
) -> Attrs raise LoadError {
  let mut attrs = attrs
  for t in trees {
    attrs = Attrs::parse(attrs, pkg=prog.pkg, t) catch {
      e => raise pfail(BadAttribute(e), [t])
    }
  }
  attrs
}

///|
fn constrained(prog : Program, attrs : Attrs) -> Program {
  prog.with_context(prog.context.merge(attrs.context))
}

///|
fn parse_body(
  prog : Program,
  body : ArrayView[Tree],
  tree : Tree,
) -> Ast raise LoadError {
  let p = { prog, depth: 0, }
  let es = []
  for b in body {
    es.push(p.parse(b))
  }
  { data: Seq(es), id: prog.sources.derive_id(tree.id), }
}

///|
fn docstring(docs : String?) -> String {
  match docs {
    Some(d) => unescape_string(unquote(d)).unwrap_or(unquote(d))
    None => ""
  }
}

///|
fn defun(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  ps : Tree,
  body : ArrayView[Tree],
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
  item? : Item[Func] = func,
) -> Program raise LoadError {
  let attrs = parse_declarations(prog, gattrs, attrs)
  let body = parse_body(constrained(prog, attrs), body, tree)
  let args = params({ prog, depth: 0, }, ps)
  prog.add(item, {
    name,
    docs: docstring(docs),
    attrs,
    code: { args, body, },
    id: tree.id,
  })
}

///|
fn defmethod(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  ps : Tree,
  body : ArrayView[Tree],
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
) -> Program raise LoadError {
  let name = @knowledge.Name::read(name, pkg="primus").show()
  defun(docs?, attrs~, name, ps, body, prog, gattrs, tree, item=meth)
}

///|
fn defmacro(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  ps : Tree,
  body : Tree,
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
) -> Program raise LoadError {
  let attrs = parse_declarations(prog, gattrs, attrs)
  prog.add(macro_item, {
    name,
    docs: docstring(docs),
    attrs,
    code: { params: metaparams(ps), body, },
    id: tree.id,
  })
}

///|
fn defparameter(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  body : Tree,
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
) -> Program raise LoadError {
  let attrs = parse_declarations(prog, gattrs, attrs)
  let p = { prog: constrained(prog, attrs), depth: 0, }
  prog.add(para, {
    name,
    docs: docstring(docs),
    attrs,
    code: { default: p.parse(body), },
    id: tree.id,
  })
}

///|
fn ascii(xs : ArrayView[Tree]) -> Array[Tree] raise LoadError {
  let out = []
  for s in xs {
    match s.data {
      Atom(x) if is_quoted(x) => {
        let x = match unescape_string(unquote(x)) {
          Some(x) => x
          None => raise pfail(BadAscii, [s])
        }
        for c in x {
          let code = c.to_int()
          let text = if code == 0 {
            "0"
          } else {
            "0x" + code.to_string(radix=16)
          }
          out.push(({ data: Atom(text), id: s.id, } : Tree))
        }
      }
      _ => raise pfail(BadAscii, [s])
    }
  }
  out
}

///|
fn hex(xs : ArrayView[Tree]) -> Array[Tree] raise LoadError {
  let out = []
  for s in xs {
    match s.data {
      List(_) => raise pfail(BadHex, [s])
      Atom(x) => {
        let x = if x.length() % 2 == 1 { "0" + x } else { x }
        let chars = x.to_array()
        for i = 1; i < chars.length(); i = i + 2 {
          out.push(
            ({ data: Atom("0x\{chars[i - 1]}\{chars[i]}"), id: s.id, } : Tree),
          )
        }
      }
    }
  }
  out
}

///|
fn is_keyarg(t : Tree) -> Bool {
  match t.data {
    Atom(s) => is_keyword(s)
    List(_) => false
  }
}

///|
fn defsubst(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  body : ArrayView[Tree],
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
) -> Program raise LoadError {
  let elts = match body {
    [{ data: Atom(":ascii"), .. }, .. rest] => ascii(rest)
    [{ data: Atom(":hex"), .. }, .. rest] => hex(rest)
    [s, ..] if is_keyarg(s) => raise pfail(UnknownSubstSyntax, [s])
    _ => body.to_owned()
  }
  let attrs = parse_declarations(prog, gattrs, attrs)
  prog.add(subst, {
    name,
    docs: docstring(docs),
    attrs,
    code: { elts, },
    id: tree.id,
  })
}

///|
fn defconst(
  docs? : String,
  attrs? : ArrayView[Tree] = [],
  name : String,
  value : String,
  prog : Program,
  gattrs : Attrs,
  tree : Tree,
) -> Program raise LoadError {
  let attrs = parse_declarations(prog, gattrs, attrs)
  prog.add(const_item, {
    name,
    docs: docstring(docs),
    attrs,
    code: { value, },
    id: tree.id,
  })
}

///|
fn atom_of(t : Tree) -> String raise LoadError {
  match t.data {
    Atom(x) => x
    List(_) => raise pfail(BadMacroParamList, [t])
  }
}

///|
fn use_packages(
  pkg? : String,
  prog : Program,
  packages : ArrayView[Tree],
) -> Program raise LoadError {
  let mut prog = prog
  for p in packages {
    prog = prog.use_package(target?=pkg, atom_of(p))
  }
  prog
}

///|
fn defpackage(
  name : String,
  prog : Program,
  trees : ArrayView[Tree],
) -> Program raise LoadError {
  let mut prog = prog
  for t in trees {
    match t.data {
      List([{ data: Atom(":use"), .. }, .. packages]) =>
        prog = use_packages(pkg=name, prog, packages)
      List([{ data: Atom(":documentation"), .. }, { data: Atom(docs), .. }]) =>
        prog = prog.update_package_documentation(name, docstring(Some(docs)))
      _ => raise pfail(BadDef(KDefpkg), [t])
    }
  }
  prog
}

///|
let toplevels : Array[String] = [
  "declare", "defconstant", "defparameter", "defmacro", "defsubst", "defun", "defmethod",
  "require", "in-package", "defpackage", "use-package",
]

///|
/// Collects the global declarations of a file.
fn declarations(prog : Program, trees : Array[Tree]) -> Attrs raise LoadError {
  let mut prog = prog
  let mut attrs = Attrs::empty()
  for s in trees {
    match s.data {
      List([{ data: Atom("in-package"), .. }, { data: Atom(pkg), .. }]) =>
        prog = prog.with_package(pkg)
      List([{ data: Atom("declare"), .. }, .. decls]) =>
        attrs = parse_declarations(prog, attrs, decls)
      List([{ data: Atom(toplevel), .. } as here, ..]) =>
        if !toplevels.contains(toplevel) {
          raise pfail(UnknownToplevel, [here])
        }
      _ => raise pfail(BadToplevel, [s])
    }
  }
  attrs
}

///|
fn is_declare(t : Tree) -> ArrayView[Tree]? {
  match t.data {
    List([{ data: Atom("declare"), .. }, .. attrs]) => Some(attrs)
    _ => None
  }
}

///|
fn quoted_atom(t : Tree) -> String? {
  match t.data {
    Atom(d) if is_quoted(d) => Some(d)
    _ => None
  }
}

///|
/// Parses the definitions of functions, methods, and parameters (the second
/// pass, upstream `Parse.stmt`).
fn stmt(gattrs : Attrs, state : Program, s : Tree) -> Program raise LoadError {
  match s.data {
    List([{ data: Atom("defpackage"), .. }, { data: Atom(name), .. }, .. elts]) =>
      defpackage(name, state, elts)
    List([{ data: Atom("use-package"), .. }, .. elts]) =>
      use_packages(state, elts)
    List([{ data: Atom("in-package"), .. }, { data: Atom(pkg), .. }]) =>
      state.with_package(pkg)
    List([{ data: Atom("defun" | "defmethod" as kind), .. }, .. rest]) => {
      let is_meth = kind == "defmethod"
      match rest {
        [{ data: Atom(name), .. }, ps, .. body] => {
          let (docs, body) = match body {
            [d, .. b] if quoted_atom(d) is Some(docs) => (Some(docs), b)
            _ => (None, body)
          }
          let (attrs, body) = match body {
            [d, .. b] if is_declare(d) is Some(attrs) => (attrs, b)
            _ => ([][:], body)
          }
          if is_meth {
            defmethod(docs?, attrs~, name, ps, body, state, gattrs, s)
          } else {
            defun(docs?, attrs~, name, ps, body, state, gattrs, s)
          }
        }
        _ => raise pfail(BadDef(if is_meth { KMeth } else { KFunc }), [s])
      }
    }
    List([{ data: Atom("defparameter"), .. }, .. rest]) =>
      match rest {
        [{ data: Atom(name), .. }, body] =>
          defparameter(name, body, state, gattrs, s)
        [{ data: Atom(name), .. }, body, d] if is_declare(d) is Some(attrs) =>
          defparameter(attrs~, name, body, state, gattrs, s)
        [{ data: Atom(name), .. }, body, { data: Atom(docs), .. }] =>
          defparameter(docs~, name, body, state, gattrs, s)
        [{ data: Atom(name), .. }, body, { data: Atom(docs), .. }, d] if is_declare(
            d,
          )
          is Some(attrs) =>
          defparameter(docs~, attrs~, name, body, state, gattrs, s)
        _ => raise pfail(BadDef(KPara), [s])
      }
    _ => state
  }
}

///|
/// Parses constants, macros, substitutions and packages (the first pass,
/// upstream `Parse.meta`).
fn meta(gattrs : Attrs, state : Program, s : Tree) -> Program raise LoadError {
  match s.data {
    List([{ data: Atom("in-package"), .. }, { data: Atom(pkg), .. }]) =>
      state.with_package(pkg)
    List([{ data: Atom("defpackage"), .. }, { data: Atom(name), .. }, .. elts]) =>
      defpackage(name, state, elts)
    List([{ data: Atom("use-package"), .. }, .. elts]) =>
      use_packages(state, elts)
    List([{ data: Atom("defconstant"), .. }, .. rest]) =>
      match rest {
        [
          { data: Atom(name), .. },
          { data: Atom(body), .. },
          { data: Atom(docs), .. },
          d,
        ] if is_quoted(docs) && is_declare(d) is Some(attrs) =>
          defconst(docs~, attrs~, name, body, state, gattrs, s)
        [
          { data: Atom(name), .. },
          { data: Atom(body), .. },
          { data: Atom(docs), .. },
        ] if is_quoted(docs) => defconst(docs~, name, body, state, gattrs, s)
        [{ data: Atom(name), .. }, { data: Atom(body), .. }, d] if is_declare(d)
          is Some(attrs) => defconst(attrs~, name, body, state, gattrs, s)
        [{ data: Atom(name), .. }, { data: Atom(body), .. }] =>
          defconst(name, body, state, gattrs, s)
        _ => raise pfail(BadDef(KConst), [s])
      }
    List([{ data: Atom("defmacro"), .. }, .. rest]) =>
      match rest {
        [{ data: Atom(name), .. }, ps, { data: Atom(docs), .. }, d, body] if is_quoted(
            docs,
          ) &&
          is_declare(d) is Some(attrs) =>
          defmacro(docs~, attrs~, name, ps, body, state, gattrs, s)
        [{ data: Atom(name), .. }, ps, { data: Atom(docs), .. }, body] if is_quoted(
            docs,
          ) => defmacro(docs~, name, ps, body, state, gattrs, s)
        [{ data: Atom(name), .. }, ps, d, body] if is_declare(d) is Some(attrs) =>
          defmacro(attrs~, name, ps, body, state, gattrs, s)
        [{ data: Atom(name), .. }, ps, body] =>
          defmacro(name, ps, body, state, gattrs, s)
        _ => raise pfail(BadDef(KMacro), [s])
      }
    List([{ data: Atom("defsubst"), .. }, .. rest]) =>
      match rest {
        [{ data: Atom(name), .. }, .. body] => {
          let (docs, body) = match body {
            [d, .. b] if quoted_atom(d) is Some(docs) => (Some(docs), b)
            _ => (None, body)
          }
          let (attrs, body) = match body {
            [d, .. b] if is_declare(d) is Some(attrs) => (attrs, b)
            _ => ([][:], body)
          }
          defsubst(docs?, attrs~, name, body, state, gattrs, s)
        }
        _ => raise pfail(BadDef(KSubst), [s])
      }
    List([{ data: Atom("defconst"), .. }, ..]) =>
      raise pfail(BadDef(KConst), [s])
    _ => state
  }
}

///|
/// Parses all files of the source store into a program (upstream
/// `Parse.source`). The program is parsed in two passes: first all meta
/// definitions (constants, macros, substitutions, packages) of all files,
/// then all functions, methods, and parameters.
pub fn parse_source(
  context : Context,
  source : Source,
) -> Program raise LoadError {
  let init = Program::empty().with_context(context).with_sources(source)
  let files = source.filenames()
  current_source.val = source
  let wrap = (f : () -> Program raise LoadError) => f()
  let mut state = init
  for file in files {
    let trees = source.find(file).unwrap()
    state = wrap(() => {
      let mut st = state.reset_package()
      let gattrs = declarations(st, trees)
      for t in trees {
        st = meta(gattrs, st, t)
      }
      st
    })
  }
  for file in files {
    let trees = source.find(file).unwrap()
    state = wrap(() => {
      let mut st = state.reset_package()
      let gattrs = declarations(st, trees)
      for t in trees {
        st = stmt(gattrs, st, t)
      }
      st
    })
  }
  state.reset_package()
}

// ---------------------------------------------------------------------------
// Loading features

///|
/// Finds the implementation of a feature: returns the file name and its
/// contents. A feature `f` is usually implemented in a file named
/// `f.lisp`.
pub struct Loader {
  priv find : (String) -> (String, String)?
}

///|
pub fn Loader::new(find : (String) -> (String, String)?) -> Loader {
  { find, }
}

///|
/// Looks up the feature in the given in-memory files, `files` is an array of
/// `(path, contents)`; a feature `f` matches a path whose base name is
/// `f.lisp`, the first match wins.
pub fn Loader::of_files(files : Array[(String, String)]) -> Loader {
  {
    find: feature => {
      let base = feature + ".lisp"
      for f in files {
        if f.0 == base || f.0.has_suffix("/" + base) {
          return Some(f)
        }
      }
      None
    },
  }
}

///|
/// Looks up the feature in the embedded upstream Lisp library. The
/// directories are searched in order, e.g., `["lisp", "site-lisp"]` (the
/// Primus Lisp standard library) or `["semantics/primus",
/// "semantics/riscv", "lisp"]`.
pub fn Loader::embedded(dirs : Array[String]) -> Loader {
  let files = embedded_lisp_files()
  {
    find: feature => {
      for d in dirs {
        let path = d + "/" + feature + ".lisp"
        for f in files {
          if f.0 == path {
            return Some(f)
          }
        }
      }
      None
    },
  }
}

///|
/// Looks up the feature in the given folders of the host file system (native
/// backend only, other backends never find anything).
pub fn Loader::paths(paths : Array[String]) -> Loader {
  {
    find: feature => {
      for p in paths {
        let file = if p.has_suffix("/") {
          p + feature + ".lisp"
        } else {
          p + "/" + feature + ".lisp"
        }
        match @native_io.read_file(file) {
          Ok(bytes) => return Some((file, @utf8.decode_lossy(bytes)))
          Err(_) => ()
        }
      }
      None
    },
  }
}

///|
/// Tries the loaders in order.
pub fn Loader::chain(loaders : Array[Loader]) -> Loader {
  {
    find: feature => {
      for l in loaders {
        if (l.find)(feature) is Some(r) {
          return Some(r)
        }
      }
      None
    },
  }
}

///|
/// All features provided by the embedded library directories.
pub fn embedded_features(dirs : Array[String]) -> Array[String] {
  let out = []
  for f in embedded_lisp_files() {
    for d in dirs {
      if f.0.has_prefix(d + "/") {
        let rest = f.0.unsafe_substring(start=d.length() + 1, end=f.0.length())
        if !rest.contains("/") && rest.has_suffix(".lisp") {
          out.push(rest.unsafe_substring(start=0, end=rest.length() - 5))
        }
      }
    }
  }
  out
}

///|
fn load_feature(
  loader : Loader,
  source : Source,
  feature : String,
  req : Request,
) -> Unit raise LoadError {
  match (loader.find)(feature) {
    None => raise UnresolvedFeature(feature, req)
    Some((file, text)) =>
      if source.find(file) is None {
        ignore(
          source.load_string(file, text) catch {
            e => raise SexpParseError(feature, req, e)
          },
        )
      }
  }
}

///|
fn required(
  loader : Loader,
  source : Source,
) -> Array[(String, Request)] raise LoadError {
  let out : Array[(String, Request)] = []
  for file in source.filenames() {
    for tree in source.find(file).unwrap() {
      match tree.data {
        List([{ data: Atom("require"), .. }, { data: Atom(name), .. }]) => {
          let req = Module(source.loc(tree.id))
          match (loader.find)(name) {
            None => raise UnresolvedFeature(name, req)
            Some((file, _)) =>
              if source.find(file) is None && !out.iter().any(r => r.0 == name) {
                out.push((name, req))
              }
          }
        }
        List([{ data: Atom("require"), .. }, .. xs]) =>
          raise ParseError(BadRequire, source.loc_of_trees(xs))
        _ => ()
      }
    }
  }
  out
}

///|
/// Loads the sources of the features and all features that they require
/// (transitively).
pub fn load_sources(
  loader : Loader,
  features : Array[String],
  source? : Source = Source::new(),
) -> Source raise LoadError {
  let fs = features.copy()
  fs.sort()
  for f in fs {
    load_feature(loader, source, f, Cmdline)
  }
  while true {
    let req = required(loader, source)
    if req.is_empty() {
      break
    }
    for r in req {
      load_feature(loader, source, r.0, r.1)
    }
  }
  source
}

///|
/// Loads a program that consists of the given features (and all features
/// they require) in the given context (upstream `Load.program`).
///
/// ```mbt check
/// test {
///   let loader = @primus_lisp.Loader::of_files([
///     ("main.lisp", "(defun main () 42)"),
///   ])
///   let prog = @primus_lisp.load_program(loader, ["main"])
///   inspect(prog.get(@primus_lisp.func).length(), content="1")
/// }
/// ```
pub fn load_program(
  loader : Loader,
  features : Array[String],
  context? : Context = Context::empty(),
) -> Program raise LoadError {
  let source = load_sources(loader, features)
  parse_source(context, source)
}
