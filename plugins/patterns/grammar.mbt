// A parser combinator library for XML signal streams (upstream `Parser`).
//
// A parser recognizes a sequence of XML signals and produces a value. The
// input is destructive, so the parser state records whether the parser
// consumed any signal (`empty`): a soft failure (an unexpected signal, or
// a missing required element) of a parser that consumed nothing can be
// backtracked with `alt` and ends the repetition in `fold`; any other
// failure is a hard error that stops parsing.

///|
priv enum Reject {
  NoInput
  Unexpected(@xml.Signal)
  UserError(String)
  MissingAttribute(String, String)
  IsRequired
  /// the XML input is malformed (upstream `Xmlm` raises an exception)
  Malformed(String)
}

///|
priv struct St {
  input : @xml.Input
  empty : Bool
}

///|
priv struct P[A]((St) -> (St, Result[A, Reject]))

///|
fn[A] P::run_p(self : P[A], s : St) -> (St, Result[A, Reject]) {
  (self.0)(s)
}

///|
fn[A] ret(x : A) -> P[A] {
  P(s => (s, Ok(x)))
}

///|
fn[A] fail_p(err : Reject) -> P[A] {
  P(s => (s, Err(err)))
}

///|
fn[A, B] P::bind(self : P[A], f : (A) -> P[B]) -> P[B] {
  P(s => {
    match self.run_p(s) {
      (s, Ok(r)) => f(r).run_p(s)
      (s, Err(e)) => (s, Err(e))
    }
  })
}

///|
fn[A, B] P::map(self : P[A], f : (A) -> B) -> P[B] {
  self.bind(x => ret(f(x)))
}

///|
/// `p >> q`
fn[A, B] P::then(self : P[A], q : P[B]) -> P[B] {
  self.bind(_ => q)
}

///|
/// `p << q`
fn[A, B] P::before(self : P[A], q : P[B]) -> P[A] {
  self.bind(x => q.then(ret(x)))
}

///|
fn eof(s : St) -> (St, Result[@xml.Signal, Reject]) {
  ({ ..s, empty: true, }, Err(NoInput))
}

///|
let read_signal : P[@xml.Signal] = P(s => {
  if s.input.eoi() {
    eof(s)
  } else {
    let sig = s.input.input() catch {
      e => return (s, Err(Malformed(e.to_string())))
    }
    ({ ..s, empty: false, }, Ok(sig))
  }
})

///|
let peek_signal : P[@xml.Signal] = P(s => {
  if s.input.eoi() {
    eof(s)
  } else {
    let sig = s.input.peek() catch {
      e => return (s, Err(Malformed(e.to_string())))
    }
    (s, Ok(sig))
  }
})

///|
fn[A] reject(signal : @xml.Signal) -> P[A] {
  P(s => ({ ..s, empty: true, }, Err(Unexpected(signal))))
}

///|
fn[A] consumed(r : A) -> P[A] {
  read_signal.then(ret(r))
}

///|
/// Recognizes the DTD or its absence.
let dtd : P[String?] = peek_signal.bind(sig => {
  match sig {
    Dtd(x) => consumed(x)
    _ => ret(None)
  }
})

///|
fn name_matches(what : String, name : @xml.Name) -> Bool {
  name.uri == "" && name.local_name == what
}

///|
/// Recognizes a start tag with any name.
let start : P[@xml.Tag] = peek_signal.bind(sig => {
  match sig {
    ElStart(tag) => consumed(tag)
    s => reject(s)
  }
})

///|
/// Recognizes an end tag.
let close : P[Unit] = peek_signal.bind(sig => {
  match sig {
    ElEnd => consumed(())
    s => reject(s)
  }
})

///|
/// Recognizes the start tag of an element with the given name.
fn tag(name : String) -> P[Array[@xml.Attribute]] {
  peek_signal.bind(sig => {
    match sig {
      ElStart(t) if name_matches(name, t.name) => consumed(t.attrs)
      s => reject(s)
    }
  })
}

///|
/// Recognizes the start tag of an element with the given attribute and
/// returns the attribute value.
fn attr(tname : String, aname : String) -> P[String] {
  tag(tname).bind(attrs => {
    match attrs.search_by(a => a.name.local_name == aname) {
      None => fail_p(MissingAttribute(tname, aname))
      Some(i) => ret(attrs[i].value)
    }
  })
}

///|
/// Recognizes character data.
let data : P[String] = peek_signal.bind(sig => {
  match sig {
    Data(payload) => consumed(payload)
    s => reject(s)
  }
})

///|
/// Recognizes an element with the given name whose contents are
/// recognized by `children`.
fn[A] tree(name : String, children : P[A]) -> P[(Array[@xml.Attribute], A)] {
  tag(name)
  .bind(attrs => children.bind(child => ret((attrs, child))))
  .before(close)
}

///|
/// `p <|> q`
fn[A] P::alt(self : P[A], q : P[A]) -> P[A] {
  P(s => {
    match self.run_p({ ..s, empty: true, }) {
      (s1, Ok(x)) => (s1, Ok(x))
      (s1, Err(Unexpected(_) | IsRequired)) if s1.empty => q.run_p(s)
      (s1, Err(e)) => (s1, Err(e))
    }
  })
}

///|
/// Folds over the longest sequence of derivations of `p`.
fn[A, B] fold_p(p : P[A], f : (B, A) -> B, init : B, plus~ : Bool) -> P[B] {
  P(s => {
    let finish = (xs : B, empty : Bool, s : St) => {
      ({ ..s, empty, }, if empty && plus { Err(IsRequired) } else { Ok(xs) })
    }
    let mut xs = init
    let mut empty = true
    let mut s = { ..s, empty: true, }
    for ;; {
      match p.run_p(s) {
        (s1, Ok(x)) if !s1.empty => {
          xs = f(xs, x)
          empty = false
          s = s1
        }
        (s1, Ok(x)) => break finish(f(xs, x), empty, s1)
        (s1, Err(NoInput | Unexpected(_) | IsRequired)) if s1.empty =>
          break finish(xs, empty, s)
        (s1, Err(e)) => break (s1, Err(e))
      }
    }
  })
}

///|
fn[A] list_p(p : P[A], plus~ : Bool) -> P[Array[A]] {
  fold_p(p, (xs : @list.List[A], x) => xs.prepend(x), @list.List([]), plus~).map(xs => {
      xs.rev().to_array()
    },
  )
}

///|
/// Zero or more `p`.
fn[A] star(p : P[A]) -> P[Array[A]] {
  list_p(p, plus=false)
}

///|
/// One or more `p`.
fn[A] plus(p : P[A]) -> P[Array[A]] {
  list_p(p, plus=true)
}

///|
/// Rejects the derivation if `p` returns `None`.
fn[A] required(p : P[A?]) -> P[A] {
  p.bind(x => {
    match x {
      None => fail_p(IsRequired)
      Some(x) => ret(x)
    }
  })
}

///|
/// A parser that stops with an error.
fn[A] error_p(msg : String) -> P[A] {
  fail_p(UserError(msg))
}

///|
fn reject_to_string(r : Reject) -> String {
  match r {
    NoInput => "Unexpected end of input"
    Unexpected(ElStart(tag)) => "An unexpected tag \{tag.name}"
    Unexpected(ElEnd) => "An unexpected end-tag"
    Unexpected(Dtd(_)) => "An unexpected start of the document (DTD)"
    Unexpected(Data(data)) =>
      "An unexpected element content: \"\{ocaml_escaped(data)}\""
    UserError(msg) => msg
    MissingAttribute(tag, attr) =>
      "The attribute \"\{attr}\" of the tag '\{tag}' is required"
    IsRequired => "The element is required"
    Malformed(msg) => "Malformed XML: \{msg}"
  }
}

///|
/// Runs the parser on the input; the error message includes the position.
fn[A] run_parser(p : P[A], input : @xml.Input) -> Result[A, String] {
  match p.run_p({ input, empty: true, }) {
    (_, Ok(x)) => Ok(x)
    (s, Err(r)) => {
      let pos = s.input.pos()
      Err(
        "Parser failed at line \{pos.line}, column \{pos.col}.\n" +
        reject_to_string(r),
      )
    }
  }
}

// The grammars of the patterns files and the table of contents.

///|
/// OCaml's `int_of_string` (decimal, `0x`, `0o`, `0b` prefixes, `_`
/// separators and a sign).
fn ocaml_int(s : String) -> Int32? {
  let s = s.replace_all(old="_", new="")
  let (neg, body) = if s.has_prefix("-") {
    (true, s.unsafe_substring(start=1, end=s.length()))
  } else if s.has_prefix("+") {
    (false, s.unsafe_substring(start=1, end=s.length()))
  } else {
    (false, s)
  }
  let lower = body.to_lower()
  let (base, digits) = if lower.has_prefix("0x") {
    (16, body.unsafe_substring(start=2, end=body.length()))
  } else if lower.has_prefix("0o") {
    (8, body.unsafe_substring(start=2, end=body.length()))
  } else if lower.has_prefix("0b") {
    (2, body.unsafe_substring(start=2, end=body.length()))
  } else {
    (10, body)
  }
  if digits == "" {
    return None
  }
  let n = @string.parse_int(digits, base~) catch { _ => return None }
  Some(if neg { -n } else { n })
}

///|
fn int_attr(attrs : Array[@xml.Attribute], name : String) -> Int32? {
  for a in attrs {
    if name_matches(name, a.name) {
      return ocaml_int(a.value)
    }
  }
  None
}

///|
let file_p : P[String] = tree("patternfile", data).map(x => x.1)

///|
let file_with_compiler : P[(String, String)] = attr("compiler", "id")
  .bind(compiler => file_p.bind(file => ret((compiler, file))))
  .before(close)

///|
fn with_compilers(id : String) -> P[Array[(String, String)]] {
  plus(file_with_compiler).map(xs => xs.map(x => ("\{id}:\{x.0}", x.1)))
}

///|
fn without_compilers(id : String) -> P[Array[(String, String)]] {
  file_p.bind(file => ret([(id, file)]))
}

///|
let language : P[Array[(String, String)]] = attr("language", "id")
  .bind(id => with_compilers(id).alt(without_compilers(id)))
  .before(close)

///|
/// The grammar of `patternconstraints.xml`: the list of languages, each a
/// list of `(target, file)` pairs.
let files_grammar : P[Array[Array[(String, String)]]] = dtd
  .then(tag("patternconstraints"))
  .then(plus(language))
  .before(close)

///|
let data_p : P[String] = tree("data", data).map(x => x.1)

///|
fn create_pattern(p : String) -> P[Pattern] {
  ret(Pattern::create(p)) catch {
    PatternError(msg) => error_p(msg)
  }
}

///|
fn create_patterns(ps : Array[String]) -> P[Array[Pattern]] {
  let out = []
  for p in ps {
    out.push(Pattern::create(p)) catch {
      PatternError(msg) => return error_p(msg)
    }
  }
  ret(out)
}

///|
let prepatterns : P[Array[Pattern]] = tree("prepatterns", plus(data_p)).bind(x => {
  create_patterns(x.1)
})

///|
let patternpairs_open_tag : P[Sizes?] = tag("patternpairs").map(attrs => {
  match (int_attr(attrs, "totalbits"), int_attr(attrs, "postbits")) {
    (Some(total), Some(post)) => Some({ total, post, })
    _ => None
  }
})

///|
let action_p : P[Rule] = start
  .before(close)
  .map(a => { ..Rule::empty(), actions: [Action::of_tag(a)], })

///|
let data_elt : P[Rule] = data_p.bind(p => {
  create_pattern(p).map(p => { ..Rule::empty(), postpatterns: [p], })
})

///|
fn patterns_with_actions(name : String) -> P[Rule] {
  tag(name)
  .then(star(data_elt.alt(action_p)))
  .bind(matches => ret(Rule::collapse(matches)))
  .before(close)
}

///|
let patternpair : P[Rule] = required(patternpairs_open_tag)
  .bind(sizes => {
    prepatterns.bind(pre => {
      patterns_with_actions("postpatterns").bind(matcher => {
        ret({ ..matcher, prepatterns: pre, sizes: Some(sizes), })
      })
    })
  })
  .before(close)

///|
let entries : P[Array[Rule]] = star(
  patternpair.alt(patterns_with_actions("pattern")),
)

///|
/// The grammar of a patterns file.
let patterns_grammar : P[Array[Rule]] = dtd
  .then(tag("patternlist"))
  .then(entries)
  .before(close)

///|
fn xml_input(text : String) -> @xml.Input {
  @xml.Input::from_string(text, strip=true)
}

///|
/// Parses a patterns file (a `patternlist`).
pub fn parse_patterns(text : String) -> Result[Array[Rule], String] {
  run_parser(dtd.then(patterns_grammar), xml_input(text))
}

///|
/// Parses a table of contents (a `patternconstraints` file) into the list
/// of `(target specification, patterns file)` pairs, where the compiler of
/// a `compiler` entry is appended to the language identifier.
pub fn parse_constraints(
  text : String,
) -> Result[Array[(String, String)], String] {
  run_parser(files_grammar, xml_input(text)).map(xs => {
    let out = []
    for x in xs {
      out.append(x)
    }
    out
  })
}
