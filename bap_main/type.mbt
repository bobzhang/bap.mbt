// Port of `Bap_main.Extension.Type`: typed value converters used by
// configuration parameters and command arguments.

///|
/// A data type for parameters (`'a Extension.typ`).
///
/// A type defines the textual syntax of its values (`parse`/`print`), a
/// digest used to compare values for caching purposes, the default value,
/// and the variable name used to refer to its values in documentation.
pub struct Type[A] {
  priv name : String
  priv default : A
  priv digest : (A) -> String
  priv parse : (String) -> A raise
  priv print : (A) -> String
}

///|
/// `Type::create(parse~, print~, default)` defines a new data type.
///
/// `parse` may raise to reject a value; `MainError::Invalid(msg)` is the
/// conventional way to do so (the `msg` is reported verbatim). The digest
/// defaults to the MD5 of the printed value; `name` defaults to `"VAL"`.
///
/// ```mbt check
/// test {
///   let t = @bap_main.Type::create(
///     parse=s => s.length(),
///     print=n => "x".repeat(n),
///     0,
///   )
///   inspect(t.parse("abc"), content="3")
///   inspect(t.print(2), content="xx")
/// }
/// ```
pub fn[A] Type::create(
  name? : String = "VAL",
  digest? : (A) -> String,
  parse~ : (String) -> A raise,
  print~ : (A) -> String,
  default : A,
) -> Type[A] {
  let digest = match digest {
    Some(f) => f
    None => x => md5_string(print(x))
  }
  { name, default, digest, parse, print, }
}

///|
/// `t.parse(s)` is the value represented by `s`.
pub fn[A] Type::parse(self : Type[A], s : String) -> A raise {
  (self.parse)(s)
}

///|
/// `t.print(x)` is the textual representation of `x`.
pub fn[A] Type::print(self : Type[A], x : A) -> String {
  (self.print)(x)
}

///|
/// `t.name()` is the name of the variable that ranges over `t`.
pub fn[A] Type::name(self : Type[A]) -> String {
  self.name
}

///|
/// `t.default()` is the default value of `t`.
pub fn[A] Type::default(self : Type[A]) -> A {
  self.default
}

///|
/// `t.digest(x)` is the (hexadecimal MD5) digest of `x`.
pub fn[A] Type::digest(self : Type[A], x : A) -> String {
  (self.digest)(x)
}

///|
/// `t.refine(valid)` narrows `t` to the values accepted by `valid`, which
/// shall raise for the values that do not belong to the new type. The
/// default value is validated immediately, as in BAP.
///
/// Unlike BAP, `print` does not re-validate its argument (printing is
/// total in this port).
pub fn[A] Type::refine(
  self : Type[A],
  valid : (A) -> Unit raise,
) -> Type[A] raise {
  valid(self.default)
  let parse = self.parse
  {
    ..self,
    parse: s => {
      let x = parse(s)
      valid(x)
      x
    },
  }
}

///|
/// `t.rename(name)` denotes elements of `t` with a new variable name
/// (`%:` in BAP).
pub fn[A] Type::rename(self : Type[A], name : String) -> Type[A] {
  { ..self, name, }
}

///|
/// `t.with_default(x)` is `t` with the default value `x` (`=?` in BAP).
pub fn[A] Type::with_default(self : Type[A], default : A) -> Type[A] {
  { ..self, default, }
}

///|
/// Wraps a Cmdliner-style converter with BAP's defaults (name `"VAL"`,
/// digest of the printed value).
fn[A] wrap_conv(
  digest? : (A) -> String,
  parse : (String) -> Result[A, String],
  print : (A) -> String,
  default : A,
) -> Type[A] {
  Type::create(
    digest?,
    parse=s => {
      match parse(s) {
        Ok(v) => v
        Err(msg) => raise Invalid(msg)
      }
    },
    print~,
    default,
  )
}

///|
/// The message carried by a parse failure.
fn parse_error_message(err : Error) -> String {
  match err {
    Invalid(msg) => msg
    e => error_to_string(e)
  }
}

///|
/// Adapts a `Type` parser to a Cmdliner-style `Result` parser.
fn[A] converter(t : Type[A]) -> (String) -> Result[A, String] {
  s => {
    try (t.parse)(s) catch {
      e => Err(parse_error_message(e))
    } noraise {
      v => Ok(v)
    }
  }
}

///|
/// `bool` is `"true" | "false"`.
pub fn Type::bool() -> Type[Bool] {
  wrap_conv(
    s => {
      match s {
        "true" => Ok(true)
        "false" => Ok(false)
        _ => Err(err_invalid_val(s, alts_str(["true", "false"])))
      }
    },
    b => if b { "true" } else { "false" },
    false,
  )
}

///|
/// `char` is a single character.
pub fn Type::char() -> Type[Char] {
  wrap_conv(
    s => {
      match s.to_array() {
        [c] => Ok(c)
        _ => Err(err_invalid_val(s, "expected a character"))
      }
    },
    c => c.to_string(),
    '\u{0}',
  )
}

///|
fn int_type(
  bits : Int,
  expected : String,
  of_int64 : (Int64) -> Int,
) -> Type[Int] {
  wrap_conv(
    s => {
      match parse_ocaml_int(s, bits) {
        Some(v) => Ok(of_int64(v))
        None => Err(err_invalid_val(s, expected))
      }
    },
    n => n.to_string(),
    0,
  )
}

///|
/// `int` is an integer in OCaml literal syntax (decimal, `0x`, `0o`, `0b`
/// prefixes, `_` separators).
///
/// OCaml `int` is 63 bits wide; this port uses MoonBit's 32-bit `Int` and
/// rejects decimal literals outside of its range.
pub fn Type::int() -> Type[Int] {
  int_type(32, "expected an integer", v => v.to_int())
}

///|
/// `int32` is a 32-bit integer.
pub fn Type::int32() -> Type[Int] {
  int_type(32, "expected a 32-bit integer", v => v.to_int())
}

///|
fn int64_type(expected : String) -> Type[Int64] {
  wrap_conv(
    s => {
      match parse_ocaml_int(s, 64) {
        Some(v) => Ok(v)
        None => Err(err_invalid_val(s, expected))
      }
    },
    n => n.to_string(),
    0,
  )
}

///|
/// `int64` is a 64-bit integer.
pub fn Type::int64() -> Type[Int64] {
  int64_type("expected a 64-bit integer")
}

///|
/// `nativeint` is a processor-native (here 64-bit) integer.
pub fn Type::nativeint() -> Type[Int64] {
  int64_type("expected a processor-native integer")
}

///|
/// `float` is a floating point number in OCaml syntax, printed like OCaml's
/// `string_of_float`.
pub fn Type::float() -> Type[Double] {
  wrap_conv(
    s => {
      match parse_ocaml_float(s) {
        Some(v) => Ok(v)
        None => Err(err_invalid_val(s, "expected a floating point number"))
      }
    },
    ocaml_string_of_float,
    0.0,
  )
}

///|
/// `string` is any string.
pub fn Type::string() -> Type[String] {
  wrap_conv(s => Ok(s), s => s, "")
}

///|
/// `path` denotes a file path; its digest is the digest of the path text.
pub fn Type::path() -> Type[String] {
  wrap_conv(s => Ok(s), s => s, "")
}

///|
/// `some(t)` extends `t` with an empty value: `None` prints as `""`.
/// Parsing always goes through `t` (as Cmdliner's `Arg.some`).
pub fn[A] Type::some(t : Type[A]) -> Type[A?] {
  let parse = converter(t)
  wrap_conv(
    s => {
      match parse(s) {
        Ok(v) => Ok(Some(v))
        Err(e) => Err(e)
      }
    },
    v => {
      match v {
        None => ""
        Some(x) => (t.print)(x)
      }
    },
    None,
  )
}

///|
/// `enumeration(repr)` defines a type from `(text, value)` pairs (`enum` in
/// BAP). The first value is the default. Unambiguous prefixes of the
/// textual representations are accepted (as in Cmdliner's `Arg.enum`).
///
/// Raises `Invalid` when `repr` is empty.
pub fn[A : Eq] Type::enumeration(repr : Array[(String, A)]) -> Type[A] raise {
  guard repr is [(_, default), ..] else { raise Invalid("empty list") }
  wrap_conv(
    s => {
      match trie_find(repr, s) {
        Found(v) => Ok(v)
        Ambiguous =>
          Err(err_ambiguous("enum value", s, trie_ambiguities(repr, s)))
        NotFound =>
          Err(err_invalid_val(s, "expected " + alts_str(repr.map(p => p.0))))
      }
    },
    v => {
      for i = repr.length() - 1; i >= 0; i = i - 1 {
        if repr[i].1 == v {
          return repr[i].0
        }
      }
      abort(
        "Arg.enum: missing printable string for a value, other strings are: " +
        repr.map(p => p.0).join(", "),
      )
    },
    default,
  )
}

// Files and directories -------------------------------------------------------

///|
fn digest_of_file_contents(path : String) -> String {
  match (current_file_system.val.read_file)(path) {
    Some(bytes) => md5_hex(bytes)
    None => md5_string("no-file")
  }
}

///|
/// Approximates BAP's recursive directory digest. BAP folds the paths and
/// modification times of at most 4096 entries; without `stat` this port
/// folds paths and file contents instead. Too large (or unreadable) trees
/// yield a digest of the path and the current time.
fn digest_directory(path : String) -> String {
  let max_checks = 4096
  let mut checked = 0
  let mut acc = ""
  let mut stopped = false
  let stack = [path]
  while stack.pop() is Some(p) {
    if checked >= max_checks {
      stopped = true
      break
    }
    match fs_kind(p) {
      Some(RegularFile) => {
        checked += 1
        acc = md5_string(acc + md5_string(p + ":" + digest_of_file_contents(p)))
      }
      Some(Directory) => {
        checked += 1
        acc = md5_string(acc + md5_string(p + ":dir"))
        match (current_file_system.val.read_dir)(p) {
          Some(entries) => {
            let entries = entries.copy()
            sort_strings(entries)
            entries.rev_in_place()
            for e in entries {
              stack.push(filename_concat(p, e))
            }
          }
          None => {
            stopped = true
            break
          }
        }
      }
      _ => {
        stopped = true
        break
      }
    }
  }
  if stopped {
    md5_string("\{path}:\{@env.now()}")
  } else {
    acc
  }
}

///|
fn digest_path(p : String) -> String {
  match fs_kind(p) {
    None => md5_string("no-file")
    Some(Directory) => digest_directory(p)
    Some(_) => digest_of_file_contents(p)
  }
}

///|
fn digest_file(p : String) -> String {
  digest_of_file_contents(p)
}

///|
/// `file` is the name of an existing file or directory. Its digest is the
/// digest of the referenced contents rather than of the name.
pub fn Type::file() -> Type[String] {
  wrap_conv(
    digest=digest_path,
    s => {
      if fs_kind(s) is Some(_) {
        Ok(s)
      } else {
        Err("no \{quote(s)} file or directory")
      }
    },
    s => s,
    "",
  )
}

///|
/// `dir` is the name of an existing directory.
pub fn Type::dir() -> Type[String] {
  wrap_conv(
    digest=digest_path,
    s => {
      match fs_kind(s) {
        Some(Directory) => Ok(s)
        Some(_) => Err("\{quote(s)} is not a directory")
        None => Err("no \{quote(s)} directory")
      }
    },
    s => s,
    "",
  )
}

///|
/// `non_dir_file` is the name of an existing file that is not a directory.
pub fn Type::non_dir_file() -> Type[String] {
  wrap_conv(
    digest=digest_file,
    s => {
      match fs_kind(s) {
        Some(Directory) => Err("\{quote(s)} is a directory")
        Some(_) => Ok(s)
        None => Err("no \{quote(s)} file")
      }
    },
    s => s,
    "",
  )
}

// Compound types ----------------------------------------------------------------

///|
/// Cmdliner's `split_and_parse`: splits on `sep`, skipping empty pieces.
fn[A] split_and_parse(
  sep : Char,
  parse : (String) -> Result[A, String],
  s : String,
) -> Result[Array[A], String] {
  let out = []
  for piece in s.split(sep.to_string()) {
    let piece = piece.to_owned()
    if piece != "" {
      match parse(piece) {
        Ok(v) => out.push(v)
        Err(e) => return Err(e)
      }
    }
  }
  Ok(out)
}

///|
/// `list(t, sep?)` is a `sep`-separated (default `,`) list of `t` values.
pub fn[A] Type::list(t : Type[A], sep? : Char = ',') -> Type[Array[A]] {
  let parse = converter(t)
  wrap_conv(
    s => {
      match split_and_parse(sep, parse, s) {
        Ok(v) => Ok(v)
        Err(e) => Err("invalid element in list ('\{s}'): \{e}")
      }
    },
    xs => xs.map(x => (t.print)(x)).join(sep.to_string()),
    [],
  )
}

///|
/// `array(t, sep?)` is a `sep`-separated (default `,`) array of `t`
/// values.
pub fn[A] Type::array(t : Type[A], sep? : Char = ',') -> Type[FixedArray[A]] {
  let parse = converter(t)
  wrap_conv(
    s => {
      match split_and_parse(sep, parse, s) {
        Ok(v) => Ok(FixedArray::from_array(v[:]))
        Err(e) => Err("invalid element in array ('\{s}'): \{e}")
      }
    },
    xs => xs.map(x => (t.print)(x)).join(sep.to_string()),
    [],
  )
}

///|
fn split_left(sep : Char, s : String) -> (String, String)? {
  lsplit2(s, sep)
}

///|
fn err_sep_miss(sep : Char, s : String) -> String {
  err_invalid_val(s, "missing a '\{sep}' separator")
}

///|
/// `pair(a, b, sep?)` is a pair of values separated with `sep` (default
/// `,`) at its first occurrence.
pub fn[A, B] Type::pair(
  a : Type[A],
  b : Type[B],
  sep? : Char = ',',
) -> Type[(A, B)] {
  let pa = converter(a)
  let pb = converter(b)
  wrap_conv(
    s => {
      match split_left(sep, s) {
        None => Err(err_sep_miss(sep, s))
        Some((v0, v1)) =>
          match (pa(v0), pb(v1)) {
            (Ok(x), Ok(y)) => Ok((x, y))
            (Err(e), _) | (_, Err(e)) =>
              Err("invalid element in pair ('\{s}'): \{e}")
          }
      }
    },
    p => (a.print)(p.0) + sep.to_string() + (b.print)(p.1),
    (a.default, b.default),
  )
}

///|
/// `t2` is `pair`.
pub fn[A, B] Type::t2(
  a : Type[A],
  b : Type[B],
  sep? : Char = ',',
) -> Type[(A, B)] {
  Type::pair(a, b, sep~)
}

///|
/// `t3(a, b, c, sep?)` is a triple of values separated with `sep`.
pub fn[A, B, C] Type::t3(
  a : Type[A],
  b : Type[B],
  c : Type[C],
  sep? : Char = ',',
) -> Type[(A, B, C)] {
  let pa = converter(a)
  let pb = converter(b)
  let pc = converter(c)
  wrap_conv(
    s => {
      match split_left(sep, s) {
        None => Err(err_sep_miss(sep, s))
        Some((v0, s)) =>
          match split_left(sep, s) {
            None => Err(err_sep_miss(sep, s))
            Some((v1, v2)) =>
              match (pa(v0), pb(v1), pc(v2)) {
                (Ok(x), Ok(y), Ok(z)) => Ok((x, y, z))
                (Err(e), _, _) | (_, Err(e), _) | (_, _, Err(e)) =>
                  Err("invalid element in triple ('\{s}'): \{e}")
              }
          }
      }
    },
    p => {
      let sep = sep.to_string()
      (a.print)(p.0) + sep + (b.print)(p.1) + sep + (c.print)(p.2)
    },
    (a.default, b.default, c.default),
  )
}

///|
/// `t4(a, b, c, d, sep?)` is a quadruple of values separated with `sep`.
pub fn[A, B, C, D] Type::t4(
  a : Type[A],
  b : Type[B],
  c : Type[C],
  d : Type[D],
  sep? : Char = ',',
) -> Type[(A, B, C, D)] {
  let pa = converter(a)
  let pb = converter(b)
  let pc = converter(c)
  let pd = converter(d)
  wrap_conv(
    s => {
      match split_left(sep, s) {
        None => Err(err_sep_miss(sep, s))
        Some((v0, s)) =>
          match split_left(sep, s) {
            None => Err(err_sep_miss(sep, s))
            Some((v1, s)) =>
              match split_left(sep, s) {
                None => Err(err_sep_miss(sep, s))
                Some((v2, v3)) =>
                  match (pa(v0), pb(v1), pc(v2), pd(v3)) {
                    (Ok(w), Ok(x), Ok(y), Ok(z)) => Ok((w, x, y, z))
                    (Err(e), _, _, _)
                    | (_, Err(e), _, _)
                    | (_, _, Err(e), _)
                    | (_, _, _, Err(e)) =>
                      Err("invalid element in quadruple ('\{s}'): \{e}")
                  }
              }
          }
      }
    },
    p => {
      let sep = sep.to_string()
      (a.print)(p.0) +
      sep +
      (b.print)(p.1) +
      sep +
      (c.print)(p.2) +
      sep +
      (d.print)(p.3)
    },
    (a.default, b.default, c.default, d.default),
  )
}
