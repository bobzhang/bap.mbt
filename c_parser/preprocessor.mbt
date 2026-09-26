// A subset of the C preprocessor.
//
// Upstream BAP parses API headers with FrontC, optionally running an
// external preprocessor first (`--frontc-parser-preprocess`). The port
// cannot spawn processes, so it implements the part of the preprocessor
// that API specification files need:
//
// - comments and line continuations (in the lexer);
// - object-like and function-like `#define` macros (with `#`, `##`, and
//   `__VA_ARGS__`), and `#undef`;
// - conditional compilation: `#if`, `#ifdef`, `#ifndef`, `#elif`, `#else`,
//   `#endif`, with integer constant expressions and `defined`;
// - `#include "file"` (relative to the including file, then the include
//   directories) and `#include <file>` (the include directories), and
//   `#pragma once`;
// - `#error` stops the preprocessing; `#pragma`, `#line`, `#ident`,
//   `#warning`, and line markers (`# 1 "file"`) are ignored.
//
// No macros are predefined.

///|
/// A parsing (or preprocessing) error with the location of the offending
/// token.
pub(all) suberror ParseError {
  ParseError(String)
} derive(Eq, Debug)

///|
pub extend ParseError with Eq::{equal, not_equal}

///|
pub extend ParseError with Debug::{to_repr}

///|
fn error_at(t : Token, msg : String) -> ParseError {
  ParseError("\{t.loc()}: \{msg}")
}

///|
/// A macro definition.
pub(all) struct Macro {
  /// The parameters of a function-like macro (`None` for object-like ones).
  params : Array[String]?
  /// Whether the last parameter is `...` (`__VA_ARGS__`).
  variadic : Bool
  /// The replacement list.
  body : Array[Token]
} derive(Debug)

///|
pub extend Macro with Debug::{to_repr}

///|
priv struct Cond {
  parent_active : Bool
  mut active : Bool
  mut taken : Bool
  mut seen_else : Bool
}

///|
/// The state of the preprocessor: the macro table, the file reader, and the
/// include search path.
pub struct Preprocessor {
  macros : Map[String, Macro]
  read_file : (String) -> String?
  include_dirs : Array[String]
  once : Map[String, Unit]
  mut depth : Int
}

///|
/// Creates a preprocessor that reads included files with `read_file` and
/// searches them in `include_dirs`. `defines` are predefined object-like
/// macros (`(name, replacement)`).
pub fn Preprocessor::new(
  read_file? : (String) -> String? = _ => None,
  include_dirs? : Array[String] = [],
  defines? : Array[(String, String)] = [],
) -> Preprocessor {
  let pp = {
    macros: Map([]),
    read_file,
    include_dirs: include_dirs.copy(),
    once: Map([]),
    depth: 0,
  }
  for d in defines {
    pp.macros[d.0] = {
      params: None,
      variadic: false,
      body: tokenize(d.1, file="<command-line>"),
    }
  }
  pp
}

///|
/// The currently defined macros.
pub fn Preprocessor::macros(self : Preprocessor) -> Map[String, Macro] {
  self.macros
}

///|
fn split_lines(tokens : Array[Token]) -> Array[Array[Token]] {
  let lines : Array[Array[Token]] = []
  for t in tokens {
    if t.bol || lines.is_empty() {
      lines.push([t])
    } else {
      lines[lines.length() - 1].push(t)
    }
  }
  lines
}

///|
/// Preprocesses `text`, the contents of `file`, and returns the resulting
/// tokens.
pub fn Preprocessor::run(
  self : Preprocessor,
  text : String,
  file? : String = "<string>",
) -> Array[Token] raise ParseError {
  let out = []
  self.process(file, text, out)
  out
}

///|
fn Preprocessor::process(
  self : Preprocessor,
  file : String,
  text : String,
  out : Array[Token],
) -> Unit raise ParseError {
  let conds : Array[Cond] = []
  let pending : Array[Token] = []
  let is_active = () => conds.is_empty() || conds[conds.length() - 1].active
  let flush = () => {
    if !pending.is_empty() {
      out.append(self.expand(pending))
      pending.clear()
    }
  }
  for line in split_lines(tokenize(text, file~)) {
    if !line[0].is_punct("#") {
      if is_active() {
        pending.append(line)
      }
      continue
    }
    let hash = line[0]
    let name = if line.length() > 1 { line[1].text } else { "" }
    let args = line[2:]
    match name {
      "if" | "ifdef" | "ifndef" => {
        let parent = is_active()
        let value = parent &&
          (match name {
            "ifdef" => self.macros.contains(directive_name(hash, args))
            "ifndef" => !self.macros.contains(directive_name(hash, args))
            _ => self.eval_condition(hash, args)
          })
        conds.push({
          parent_active: parent,
          active: value,
          taken: value,
          seen_else: false,
        })
      }
      "elif" => {
        guard conds.last() is Some(c) else {
          raise error_at(hash, "#elif without #if")
        }
        if c.seen_else {
          raise error_at(hash, "#elif after #else")
        }
        if c.parent_active && !c.taken {
          let value = self.eval_condition(hash, args)
          c.active = value
          c.taken = value
        } else {
          c.active = false
        }
      }
      "else" => {
        guard conds.last() is Some(c) else {
          raise error_at(hash, "#else without #if")
        }
        if c.seen_else {
          raise error_at(hash, "#else after #else")
        }
        c.seen_else = true
        c.active = c.parent_active && !c.taken
        c.taken = true
      }
      "endif" => {
        guard conds.pop() is Some(_) else {
          raise error_at(hash, "#endif without #if")
        }
      }
      _ if !is_active() => ()
      "define" => {
        flush()
        self.define_macro(hash, args)
      }
      "undef" => {
        flush()
        self.macros.remove(directive_name(hash, args))
      }
      "include" | "include_next" => {
        flush()
        self.include_file(file, hash, args, out)
      }
      "pragma" =>
        if args is [{ kind: Ident, text: "once", .. }, ..] {
          self.once[file] = ()
        }
      "error" => raise error_at(hash, "#error \{tokens_to_string(args[:])}")
      "" | "line" | "ident" | "sccs" | "warning" | "assert" | "unassert" => ()
      _ if line[1].kind is IntLit => () // a line marker
      _ => raise error_at(hash, "unknown directive #\{name}")
    }
  }
  flush()
  if !conds.is_empty() {
    raise ParseError("\{file}: unterminated conditional directive")
  }
}

///|
fn directive_name(
  hash : Token,
  args : ArrayView[Token],
) -> String raise ParseError {
  match args {
    [{ kind: Ident, text, .. }, ..] => text
    _ => raise error_at(hash, "expected a macro name")
  }
}

///|
fn Preprocessor::define_macro(
  self : Preprocessor,
  hash : Token,
  args : ArrayView[Token],
) -> Unit raise ParseError {
  let name = directive_name(hash, args)
  // a function-like macro has `(` immediately after its name
  if args.length() > 1 && args[1].is_punct("(") && !args[1].space {
    let params = []
    let mut variadic = false
    let mut i = 2
    for ;; {
      guard i < args.length() else {
        raise error_at(hash, "unterminated parameter list of \{name}")
      }
      let t = args[i]
      if t.is_punct(")") {
        i += 1
        break
      } else if t.is_punct(",") {
        i += 1
      } else if t.is_punct("...") {
        variadic = true
        params.push("__VA_ARGS__")
        i += 1
      } else if t.kind is Ident {
        params.push(t.text)
        i += 1
      } else {
        raise error_at(hash, "invalid parameter list of \{name}")
      }
    }
    self.macros[name] = {
      params: Some(params),
      variadic,
      body: args[i:].to_owned(),
    }
  } else {
    self.macros[name] = {
      params: None,
      variadic: false,
      body: args[1:].to_owned(),
    }
  }
}

///|
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path.unsafe_substring(start=0, end=i)
    None => ""
  }
}

///|
fn join_path(dir : String, file : String) -> String {
  if dir == "" || file.has_prefix("/") {
    file
  } else if dir.has_suffix("/") {
    dir + file
  } else {
    dir + "/" + file
  }
}

///|
fn Preprocessor::include_file(
  self : Preprocessor,
  file : String,
  hash : Token,
  args : ArrayView[Token],
  out : Array[Token],
) -> Unit raise ParseError {
  let args = match args {
    [{ kind: StrLit, .. }, ..] | [{ kind: Punct, text: "<", .. }, ..] => args
    _ => self.expand(args.to_owned())[:]
  }
  let (target, quoted) = match args {
    [{ kind: StrLit, text, .. }, ..] => (text, true)
    [{ kind: Punct, text: "<", .. }, .. rest] => {
      let buf = StringBuilder()
      let mut closed = false
      for t in rest {
        if t.is_punct(">") {
          closed = true
          break
        }
        buf.write_string(t.text)
      }
      if !closed {
        raise error_at(hash, "expected > in #include")
      }
      (buf.to_string(), false)
    }
    _ => raise error_at(hash, "expected a file name in #include")
  }
  let candidates = []
  if target.has_prefix("/") {
    candidates.push(target)
  } else {
    if quoted {
      candidates.push(join_path(dirname(file), target))
    }
    for dir in self.include_dirs {
      candidates.push(join_path(dir, target))
    }
  }
  for path in candidates {
    if (self.read_file)(path) is Some(text) {
      if self.once.contains(path) {
        return
      }
      if self.depth >= 200 {
        raise error_at(hash, "#include nested too deeply")
      }
      self.depth += 1
      defer {
        self.depth -= 1
      }
      self.process(path, text, out)
      return
    }
  }
  raise error_at(hash, "cannot find include file \{target}")
}

// Macro expansion (a simplified Prosser's algorithm: every token carries
// the set of macros that must not be expanded in it).

///|
priv struct PTok {
  tok : Token
  hide : Array[String]
}

///|
fn with_hide(hide : Array[String], name : String) -> Array[String] {
  if hide.contains(name) {
    hide
  } else {
    hide + [name]
  }
}

///|
/// Fully macro-expands `tokens`.
pub fn Preprocessor::expand(
  self : Preprocessor,
  tokens : Array[Token],
) -> Array[Token] raise ParseError {
  self.expand_ptoks(tokens.map(tok => { tok, hide: [], })).map(p => p.tok)
}

///|
fn Preprocessor::expand_ptoks(
  self : Preprocessor,
  tokens : Array[PTok],
) -> Array[PTok] raise ParseError {
  // `stack` holds the tokens to scan in reverse order
  let stack = tokens.rev()
  let out = []
  while stack.pop() is Some(p) {
    let t = p.tok
    guard t.kind is Ident &&
      self.macros.get(t.text) is Some(m) &&
      !p.hide.contains(t.text) else {
      out.push(p)
      continue
    }
    match m.params {
      None => {
        let hide = with_hide(p.hide, t.text)
        let body = relocate(m.body, t)
        for i = body.length() - 1; i >= 0; i = i - 1 {
          stack.push({ tok: body[i], hide, })
        }
      }
      Some(params) => {
        guard stack.last() is Some(next) && next.tok.is_punct("(") else {
          out.push(p)
          continue
        }
        stack.pop() |> ignore
        let args = collect_args(t, stack)
        let args = if args is [[]] && params.is_empty() { [] } else { args }
        let args = if m.variadic && args.length() >= params.length() {
          merge_variadic(t, args, params.length())
        } else if m.variadic && args.length() == params.length() - 1 {
          args + [[]]
        } else {
          args
        }
        if args.length() != params.length() {
          raise error_at(
            t,
            "macro \{t.text} expects \{params.length()} arguments, got \{args.length()}",
          )
        }
        let hide = with_hide(p.hide, t.text)
        let body = self.substitute(t, m, params, args)
        for i = body.length() - 1; i >= 0; i = i - 1 {
          stack.push({ tok: body[i].tok, hide: merge_hide(body[i].hide, hide), })
        }
      }
    }
  }
  out
}

///|
fn merge_hide(a : Array[String], b : Array[String]) -> Array[String] {
  b.fold(init=a, (acc, x) => with_hide(acc, x))
}

///|
/// Places the replacement tokens at the location of the macro invocation.
fn relocate(body : Array[Token], at : Token) -> Array[Token] {
  body.mapi((i, b) => {
    ..b,
    file: at.file,
    line: at.line,
    bol: i == 0 && at.bol,
    space: if i == 0 {
      at.space
    } else {
      b.space
    },
  })
}

///|
/// Collects the arguments of a macro invocation (the `(` is consumed).
fn collect_args(
  name : Token,
  stack : Array[PTok],
) -> Array[Array[PTok]] raise ParseError {
  let args : Array[Array[PTok]] = [[]]
  let mut depth = 0
  for ;; {
    guard stack.pop() is Some(p) else {
      raise error_at(name, "unterminated invocation of macro \{name.text}")
    }
    let t = p.tok
    if t.is_punct("(") {
      depth += 1
    } else if t.is_punct(")") {
      if depth == 0 {
        break
      }
      depth -= 1
    } else if t.is_punct(",") && depth == 0 {
      args.push([])
      continue
    }
    args[args.length() - 1].push(p)
  }
  args
}

///|
fn merge_variadic(
  at : Token,
  args : Array[Array[PTok]],
  n : Int,
) -> Array[Array[PTok]] {
  let fixed = args[0:n - 1].to_owned()
  let rest = []
  for i in (n - 1)..<args.length() {
    if i > n - 1 {
      rest.push({ tok: comma_like(at), hide: [], })
    }
    rest.append(args[i])
  }
  fixed + [rest]
}

///|
fn comma_like(at : Token) -> Token {
  { ..at, kind: Punct, text: ",", bol: false, space: false, }
}

///|
fn Preprocessor::substitute(
  self : Preprocessor,
  at : Token,
  m : Macro,
  params : Array[String],
  args : Array[Array[PTok]],
) -> Array[PTok] raise ParseError {
  let param_index = (t : Token) => {
    if t.kind is Ident {
      params.search(t.text)
    } else {
      None
    }
  }
  let expanded : Map[Int, Array[PTok]] = Map([])
  let body = relocate(m.body, at)
  let out : Array[PTok] = []
  let mut i = 0
  while i < body.length() {
    let t = body[i]
    // stringification
    if t.is_punct("#") &&
      i + 1 < body.length() &&
      param_index(body[i + 1]) is Some(k) {
      let text = tokens_to_string(args[k].map(p => p.tok)[:])
      out.push({ tok: { ..t, kind: StrLit, text, }, hide: [], })
      i += 2
      continue
    }
    // token pasting
    if i + 1 < body.length() && body[i + 1].is_punct("##") {
      let left = match param_index(t) {
        Some(k) => args[k].copy()
        None => [{ tok: t, hide: [], }]
      }
      out.append(left)
      i += 1
      while i + 1 < body.length() && body[i].is_punct("##") {
        let r = body[i + 1]
        let right = match param_index(r) {
          Some(k) => args[k].copy()
          None => [{ tok: r, hide: [], }]
        }
        paste(out, right)
        i += 2
      }
      continue
    }
    match param_index(t) {
      Some(k) => {
        let arg = match expanded.get(k) {
          Some(a) => a
          None => {
            let a = self.expand_ptoks(args[k])
            expanded[k] = a
            a
          }
        }
        for j, p in arg {
          let tok = if j == 0 { { ..p.tok, space: t.space, } } else { p.tok }
          out.push({ tok, hide: p.hide, })
        }
      }
      None => out.push({ tok: t, hide: [], })
    }
    i += 1
  }
  out
}

///|
fn paste(out : Array[PTok], right : Array[PTok]) -> Unit {
  match (out.last(), right) {
    (_, []) => ()
    (None, _) => out.append(right)
    (Some(l), [r, .. rest]) => {
      out.pop() |> ignore
      let text = l.tok.text + r.tok.text
      let toks = tokenize(text, file=l.tok.file)
      for k, tok in toks {
        out.push({
          tok: {
            ..tok,
            line: l.tok.line,
            bol: l.tok.bol && k == 0,
            space: k == 0 && l.tok.space,
          },
          hide: [],
        })
      }
      out.append(rest.to_owned())
    }
  }
}

// `#if` expressions.

///|
fn Preprocessor::eval_condition(
  self : Preprocessor,
  hash : Token,
  args : ArrayView[Token],
) -> Bool raise ParseError {
  // replace `defined X` and `defined(X)` before the expansion
  let toks = []
  let mut i = 0
  while i < args.length() {
    let t = args[i]
    if t.is_ident("defined") {
      let (name, next) = match args[i + 1:] {
        [{ kind: Ident, text, .. }, ..] => (text, i + 2)
        [
          { kind: Punct, text: "(", .. },
          { kind: Ident, text, .. },
          { kind: Punct, text: ")", .. },
          ..,
        ] => (text, i + 4)
        _ => raise error_at(hash, "invalid use of defined")
      }
      let v = if self.macros.contains(name) { "1" } else { "0" }
      toks.push({ ..t, kind: IntLit, text: v, })
      i = next
    } else {
      toks.push(t)
      i += 1
    }
  }
  let toks = self.expand(toks)
  let parser = { toks, pos: 0, hash, }
  let v = parser.ternary()
  if parser.pos < toks.length() {
    raise error_at(hash, "unexpected \{toks[parser.pos].text} in #if")
  }
  v != 0L
}

///|
priv struct CondParser {
  toks : Array[Token]
  mut pos : Int
  hash : Token
}

///|
fn CondParser::peek(self : CondParser) -> String {
  match self.toks.get(self.pos) {
    Some({ kind: Punct, text, .. }) => text
    _ => ""
  }
}

///|
fn CondParser::ternary(self : CondParser) -> Int64 raise ParseError {
  let c = self.binary(0)
  if self.peek() == "?" {
    self.pos += 1
    let a = self.ternary()
    if self.peek() != ":" {
      raise error_at(self.hash, "expected : in #if")
    }
    self.pos += 1
    let b = self.ternary()
    if c != 0L {
      a
    } else {
      b
    }
  } else {
    c
  }
}

///|
let binary_levels : Array[Array[String]] = [
  ["||"],
  ["&&"],
  ["|"],
  ["^"],
  ["&"],
  ["==", "!="],
  ["<", ">", "<=", ">="],
  ["<<", ">>"],
  ["+", "-"],
  ["*", "/", "%"],
]

///|
fn CondParser::binary(self : CondParser, level : Int) -> Int64 raise ParseError {
  if level >= binary_levels.length() {
    return self.unary()
  }
  let mut acc = self.binary(level + 1)
  while binary_levels[level].contains(self.peek()) {
    let op = self.peek()
    self.pos += 1
    let r = self.binary(level + 1)
    let b = (x : Bool) => if x { 1L } else { 0L }
    acc = match op {
      "||" => b(acc != 0L || r != 0L)
      "&&" => b(acc != 0L && r != 0L)
      "|" => acc | r
      "^" => acc ^ r
      "&" => acc & r
      "==" => b(acc == r)
      "!=" => b(acc != r)
      "<" => b(acc < r)
      ">" => b(acc > r)
      "<=" => b(acc <= r)
      ">=" => b(acc >= r)
      "<<" => acc << r.to_int()
      ">>" => acc >> r.to_int()
      "+" => acc + r
      "-" => acc - r
      "*" => acc * r
      _ => {
        if r == 0L {
          raise error_at(self.hash, "division by zero in #if")
        }
        if op == "/" {
          acc / r
        } else {
          acc % r
        }
      }
    }
  }
  acc
}

///|
fn CondParser::unary(self : CondParser) -> Int64 raise ParseError {
  guard self.toks.get(self.pos) is Some(t) else {
    raise error_at(self.hash, "unexpected end of #if expression")
  }
  self.pos += 1
  match t {
    { kind: Punct, text: "!", .. } => if self.unary() == 0L { 1L } else { 0L }
    { kind: Punct, text: "~", .. } => self.unary().lnot()
    { kind: Punct, text: "-", .. } => -self.unary()
    { kind: Punct, text: "+", .. } => self.unary()
    { kind: Punct, text: "(", .. } => {
      let v = self.ternary()
      if self.peek() != ")" {
        raise error_at(self.hash, "expected ) in #if")
      }
      self.pos += 1
      v
    }
    { kind: IntLit, text, .. } =>
      match parse_int_literal(text) {
        Some(v) => v
        None => raise error_at(t, "invalid integer \{text}")
      }
    { kind: CharLit, text, .. } =>
      match text.get_char(0) {
        Some(c) => c.to_int().to_int64()
        None => 0L
      }
    // identifiers that are not macros evaluate to 0
    { kind: Ident, .. } => 0L
    _ => raise error_at(t, "unexpected \{t.text} in #if")
  }
}

///|
/// Parses a C integer literal (decimal, octal, hexadecimal, or binary, with
/// optional `u`/`l` suffixes).
pub fn parse_int_literal(text : String) -> Int64? {
  let mut end = text.length()
  while end > 0 && text.code_unit_at(end - 1) is ('u' | 'U' | 'l' | 'L') {
    end -= 1
  }
  let s = text.unsafe_substring(start=0, end~)
  let (base, digits) = if s.has_prefix("0x") || s.has_prefix("0X") {
    (16, s.unsafe_substring(start=2, end=s.length()))
  } else if s.has_prefix("0b") || s.has_prefix("0B") {
    (2, s.unsafe_substring(start=2, end=s.length()))
  } else if s.length() > 1 && s.has_prefix("0") {
    (8, s.unsafe_substring(start=1, end=s.length()))
  } else {
    (10, s)
  }
  if digits.is_empty() {
    return None
  }
  let mut v = 0UL
  for c in digits {
    let d = match hex_digit(c.to_int().to_uint16()) {
      Some(d) if d < base => d
      _ => return None
    }
    v = v * base.to_uint64() + d.to_uint64()
  }
  Some(v.reinterpret_as_int64())
}
