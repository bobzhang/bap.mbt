// OCaml standard-library and Cmdliner helpers whose exact behavior is part
// of BAP's command-line contract: integer/float literal syntax, float
// printing, whitespace stripping, and the Cmdliner prefix trie and error
// message wording (following Cmdliner 1.x).

///|
/// OCaml's `String.compare`: lexicographic order (MoonBit's `String`
/// comparison orders by length first).
fn lex_compare(a : String, b : String) -> Int32 {
  let n = if a.length() < b.length() { a.length() } else { b.length() }
  for i in 0..<n {
    let c = a[i].compare(b[i])
    if c != 0 {
      return c
    }
  }
  a.length().compare(b.length())
}

///|
fn sort_strings(xs : Array[String]) -> Unit {
  xs.sort_by(lex_compare)
}

///|
/// Cmdliner's `quote`.
fn quote(s : String) -> String {
  "'\{s}'"
}

///|
/// Cmdliner's `alts_str ~quoted:true`.
fn alts_str(alts : Array[String]) -> String {
  match alts.length() {
    0 => ""
    1 => quote(alts[0])
    2 => "either \{quote(alts[0])} or \{quote(alts[1])}"
    n => {
      let init = alts[:n - 1].to_owned().map(quote).join(", ")
      "one of \{init} or \{quote(alts[n - 1])}"
    }
  }
}

///|
fn err_invalid_val(s : String, exp : String) -> String {
  "invalid value \{quote(s)}, \{exp}"
}

///|
fn err_ambiguous(kind : String, s : String, ambs : Array[String]) -> String {
  "\{kind} \{quote(s)} ambiguous and could be \{alts_str(ambs)}"
}

///|
fn err_unknown(kind : String, v : String, hints : Array[String]) -> String {
  let hints = if hints.is_empty() {
    "."
  } else {
    ", did you mean \{alts_str(hints)}?"
  }
  "unknown \{kind} \{quote(v)}\{hints}"
}

///|
/// Base's `Char.is_whitespace`.
fn is_ws(c : Char) -> Bool {
  c is (' ' | '\t' | '\n' | '\r' | '\u{0B}' | '\u{0C}')
}

///|
/// Base's `String.strip`.
fn strip(s : StringView) -> String {
  let mut start = 0
  let mut stop = s.length()
  while start < stop && is_ws(s.code_unit_at(start).to_int().unsafe_to_char()) {
    start += 1
  }
  while stop > start &&
        is_ws(s.code_unit_at(stop - 1).to_int().unsafe_to_char()) {
    stop -= 1
  }
  s.view(start_offset=start, end_offset=stop).to_owned()
}

///|
fn lstrip(s : StringView) -> String {
  let mut start = 0
  while start < s.length() &&
        is_ws(s.code_unit_at(start).to_int().unsafe_to_char()) {
    start += 1
  }
  s.view(start_offset=start).to_owned()
}

///|
fn rstrip(s : StringView) -> String {
  let mut stop = s.length()
  while stop > 0 && is_ws(s.code_unit_at(stop - 1).to_int().unsafe_to_char()) {
    stop -= 1
  }
  s.view(end_offset=stop).to_owned()
}

///|
/// Splits `s` at the first occurrence of `sep` (Base `String.lsplit2`).
fn lsplit2(s : String, sep : Char) -> (String, String)? {
  match s.find(sep.to_string()) {
    None => None
    Some(i) =>
      Some(
        (s.view(end_offset=i).to_owned(), s.view(start_offset=i + 1).to_owned()),
      )
  }
}

// Prefix trie lookups (Cmdliner_trie) --------------------------------------

///|
priv enum TrieResult[V] {
  Found(V)
  Ambiguous
  NotFound
}

///|
/// `trie_find keys k`: an exact key wins; otherwise `k` must be a prefix of
/// exactly one key (distinct keys bound to the same value still make the
/// prefix ambiguous, as in Cmdliner).
fn[V] trie_find(keys : Array[(String, V)], k : String) -> TrieResult[V] {
  let mut found : V? = None
  let mut count = 0
  for entry in keys {
    if entry.0 == k {
      return Found(entry.1)
    }
    if entry.0.has_prefix(k) {
      count += 1
      found = Some(entry.1)
    }
  }
  match (count, found) {
    (1, Some(v)) => Found(v)
    (0, _) => NotFound
    _ => Ambiguous
  }
}

///|
/// The keys that make `prefix` ambiguous, sorted.
fn[V] trie_ambiguities(
  keys : Array[(String, V)],
  prefix : String,
) -> Array[String] {
  if trie_find(keys, prefix) is Ambiguous {
    let out = keys.filter(e => e.0.has_prefix(prefix)).map(e => e.0)
    sort_strings(out)
    out
  } else {
    []
  }
}

///|
fn min3(a : Int32, b : Int32, c : Int32) -> Int32 {
  let m = if a < b { a } else { b }
  if m < c {
    m
  } else {
    c
  }
}

///|
/// Levenshtein distance (Cmdliner_base.edit_distance).
fn edit_distance(s0 : String, s1 : String) -> Int32 {
  let a = s0.to_array()
  let b = s1.to_array()
  let m = a.length()
  let n = b.length()
  let row0 = Array::makei(n + 1, i => i)
  let row = Array::make(n + 1, 0)
  for i in 1..<=m {
    row[0] = i
    for j in 1..<=n {
      row[j] = if a[i - 1] == b[j - 1] {
        row0[j - 1]
      } else {
        min3(row0[j - 1] + 1, row0[j] + 1, row[j - 1] + 1)
      }
    }
    for j in 0..<=n {
      row0[j] = row[j]
    }
  }
  row0[n]
}

///|
/// Cmdliner's `suggest`: the candidates at the minimal edit distance, if
/// that distance is less than 3.
fn suggest(s : String, candidates : Array[String]) -> Array[String] {
  let mut min = 2147483647
  let mut acc : Array[String] = []
  for name in candidates {
    let d = edit_distance(s, name)
    if d == min {
      acc = [name, ..acc]
    } else if d < min {
      min = d
      acc = [name]
    }
  }
  if min < 3 {
    acc
  } else {
    []
  }
}

// OCaml integer literals ---------------------------------------------------

///|
fn digit_value(c : Char) -> Int32 {
  match c {
    '0'..<='9' => c.to_int() - '0'.to_int()
    'a'..<='f' => c.to_int() - 'a'.to_int() + 10
    'A'..<='F' => c.to_int() - 'A'.to_int() + 10
    _ => 99
  }
}

///|
/// Parses an OCaml integer literal (`int_of_string` and friends): an
/// optional sign, an optional `0x`/`0o`/`0b`/`0u` prefix, digits, and `_`
/// separators after the first digit. Decimal literals are range checked as
/// signed `bits`-wide integers; other bases accept the full unsigned range
/// and wrap. Returns `None` on failure.
fn parse_ocaml_int(s : String, bits : Int32) -> Int64? {
  let cs = s.to_array()
  let n = cs.length()
  let mut i = 0
  let mut negative = false
  if i < n && cs[i] == '-' {
    negative = true
    i += 1
  } else if i < n && cs[i] == '+' {
    i += 1
  }
  let mut base = 10
  let mut signed = true
  if i + 1 < n && cs[i] == '0' {
    match cs[i + 1] {
      'x' | 'X' => {
        base = 16
        signed = false
        i += 2
      }
      'o' | 'O' => {
        base = 8
        signed = false
        i += 2
      }
      'b' | 'B' => {
        base = 2
        signed = false
        i += 2
      }
      'u' | 'U' => {
        signed = false
        i += 2
      }
      _ => ()
    }
  }
  if i >= n || digit_value(cs[i]) >= base {
    return None
  }
  let base64 = base.to_uint64()
  let max_u64 : UInt64 = 0xFFFFFFFFFFFFFFFF
  let mut res : UInt64 = 0
  while i < n {
    let c = cs[i]
    i += 1
    if c == '_' {
      continue
    }
    let d = digit_value(c)
    if d >= base {
      return None
    }
    if res > (max_u64 - d.to_uint64()) / base64 {
      return None
    }
    res = res * base64 + d.to_uint64()
  }
  let limit : UInt64 = if bits >= 64 {
    max_u64
  } else {
    ((1 : UInt64) << bits) - 1
  }
  if signed {
    let half : UInt64 = (1 : UInt64) << (bits - 1)
    if negative {
      if res > half {
        return None
      }
    } else if res >= half {
      return None
    }
  } else if res > limit {
    return None
  }
  let v = if negative { (0 : UInt64) - res } else { res }
  // truncate to `bits` with sign extension
  if bits >= 64 {
    Some(v.reinterpret_as_int64())
  } else {
    let shift = 64 - bits
    Some((v << shift).reinterpret_as_int64() >> shift)
  }
}

// OCaml floats ---------------------------------------------------------------

///|
fn parse_hex_float(s : String) -> Double? {
  // s is the part after the `0x` prefix, e.g. "1.8p3"
  let cs = s.to_array()
  let mut i = 0
  let mut mant = 0.0
  let mut exp = 0
  let mut any = false
  while i < cs.length() && digit_value(cs[i]) < 16 {
    mant = mant * 16.0 + digit_value(cs[i]).to_double()
    i += 1
    any = true
  }
  if i < cs.length() && cs[i] == '.' {
    i += 1
    while i < cs.length() && digit_value(cs[i]) < 16 {
      mant = mant * 16.0 + digit_value(cs[i]).to_double()
      exp -= 4
      i += 1
      any = true
    }
  }
  if !any {
    return None
  }
  if i < cs.length() && (cs[i] == 'p' || cs[i] == 'P') {
    i += 1
    let rest = String::from_array(cs[i:])
    match parse_ocaml_int(rest, 32) {
      Some(e) => exp += e.to_int()
      None => return None
    }
    i = cs.length()
  }
  if i != cs.length() {
    return None
  }
  Some(mant * @math.pow(2.0, exp.to_double()))
}

///|
/// OCaml `float_of_string`: decimal and hexadecimal literals, `_`
/// separators, `nan`, `inf`, and `infinity`.
fn parse_ocaml_float(s : String) -> Double? {
  let cleaned = s.replace_all(old="_", new="")
  if cleaned == "" {
    return None
  }
  let (negative, body) = if cleaned.has_prefix("-") {
    (true, cleaned[1:].to_owned())
  } else if cleaned.has_prefix("+") {
    (false, cleaned[1:].to_owned())
  } else {
    (false, cleaned)
  }
  let lower = body.to_lower()
  let value : Double? = if lower == "nan" {
    Some(0.0 / 0.0)
  } else if lower == "inf" || lower == "infinity" {
    Some(1.0 / 0.0)
  } else if lower.has_prefix("0x") {
    parse_hex_float(body[2:].to_owned())
  } else {
    let ok = body
      .iter()
      .all(c => c is ('0'..<='9' | '.' | 'e' | 'E' | '+' | '-')) &&
      body.iter().any(c => c is ('0'..<='9'))
    if !ok {
      None
    } else {
      // `strtod` accepts "1." and ".5"
      let normalized = if body.has_prefix(".") { "0" + body } else { body }
      let normalized = normalized
        .replace_all(old=".e", new=".0e")
        .replace_all(old=".E", new=".0E")
      let normalized = if normalized.has_suffix(".") {
        normalized + "0"
      } else {
        normalized
      }
      try @string.parse_double(normalized) catch {
        _ => None
      } noraise {
        v => Some(v)
      }
    }
  }
  match value {
    Some(v) => Some(if negative { -v } else { v })
    None => None
  }
}

///|
/// Splits a finite, nonzero, positive double into its shortest decimal
/// digits and the decimal exponent of the first digit.
fn decimal_digits(v : Double) -> (String, Int32) {
  let s = v.to_string()
  let (mantissa, exp) = match s.find("e") {
    Some(i) => {
      let e = s[i + 1:].to_owned()
      let e = if e.has_prefix("+") { e[1:].to_owned() } else { e }
      (s[:i].to_owned(), @string.parse_int(e) catch { _ => 0 })
    }
    None => (s, 0)
  }
  let (int_part, frac_part) = match mantissa.find(".") {
    Some(i) => (mantissa[:i].to_owned(), mantissa[i + 1:].to_owned())
    None => (mantissa, "")
  }
  let all = int_part + frac_part
  // position of the decimal point relative to `all`
  let mut point = int_part.length() + exp
  let mut digits = all
  // drop leading zeros
  while digits.length() > 1 && digits.has_prefix("0") {
    digits = digits[1:].to_owned()
    point -= 1
  }
  while digits.length() > 1 && digits.has_suffix("0") {
    digits = digits[:digits.length() - 1].to_owned()
  }
  (digits, point - 1)
}

///|
/// Rounds a digit string to `prec` significant digits (half-up on the
/// shortest representation). Returns the digits and an exponent carry.
fn round_digits(digits : String, prec : Int32) -> (String, Int32) {
  if digits.length() <= prec {
    return (digits, 0)
  }
  let ds = digits.to_array().map(c => c.to_int() - '0'.to_int())
  let kept = ds[:prec].to_owned()
  if ds[prec] >= 5 {
    let mut i = prec - 1
    let mut carry = true
    while carry && i >= 0 {
      kept[i] += 1
      if kept[i] == 10 {
        kept[i] = 0
        i -= 1
      } else {
        carry = false
      }
    }
    if carry {
      let out = [1, ..kept[:prec - 1]]
      return (
        String::from_array(out.map(d => (d + '0'.to_int()).unsafe_to_char())),
        1,
      )
    }
  }
  let s = String::from_array(kept.map(d => (d + '0'.to_int()).unsafe_to_char()))
  let mut t = s
  while t.length() > 1 && t.has_suffix("0") {
    t = t[:t.length() - 1].to_owned()
  }
  (t, 0)
}

///|
/// OCaml `Printf.sprintf "%.12g"`.
fn format_g12(v : Double) -> String {
  if v.is_nan() {
    return "nan"
  }
  if v.is_inf() {
    return if v > 0.0 { "inf" } else { "-inf" }
  }
  if v == 0.0 {
    return if 1.0 / v < 0.0 { "-0" } else { "0" }
  }
  let sign = if v < 0.0 { "-" } else { "" }
  let (digits0, exp0) = decimal_digits(v.abs())
  let (digits, carry) = round_digits(digits0, 12)
  let exp = exp0 + carry
  if exp < -4 || exp >= 12 {
    let mant = if digits.length() == 1 {
      digits
    } else {
      digits[:1].to_owned() + "." + digits[1:].to_owned()
    }
    let esign = if exp < 0 { "-" } else { "+" }
    let e = exp.abs().to_string()
    let e = if e.length() < 2 { "0" + e } else { e }
    "\{sign}\{mant}e\{esign}\{e}"
  } else if exp < 0 {
    "\{sign}0.\{"0".repeat(-exp - 1)}\{digits}"
  } else if digits.length() <= exp + 1 {
    "\{sign}\{digits}\{"0".repeat(exp + 1 - digits.length())}"
  } else {
    "\{sign}\{digits[:exp + 1]}.\{digits[exp + 1:]}"
  }
}

///|
/// OCaml `string_of_float`: `%.12g` with a trailing `.` for integral
/// values.
fn ocaml_string_of_float(v : Double) -> String {
  let s = format_g12(v)
  if s.iter().all(c => c == '-' || c is ('0'..<='9')) {
    s + "."
  } else {
    s
  }
}
