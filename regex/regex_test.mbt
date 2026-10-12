///|
fn execp(pattern : String, input : String, caseless~ : Bool = false) -> Bool {
  match @regex.Regex::compile(pattern, caseless~) {
    Ok(regex) => regex.execp(input)
    Err(reason) => abort("\{pattern}: \{reason}")
  }
}

///|
fn error_of(pattern : String) -> String {
  match @regex.Regex::compile(pattern) {
    Ok(_) => "compiled"
    Err(reason) => reason
  }
}

///|
test "unanchored search" {
  debug_inspect(
    [
      execp("mem", "__memcpy"),
      execp("^mem", "__memcpy"),
      execp("^_+mem", "__memcpy"),
      execp("cpy$", "__memcpy"),
      execp("cpy$", "__memcpy\n"),
      execp("cpy$", "__memcpy\n\n"),
      execp("^(str|mem)cpy$", "strcpy"),
      execp("^(str|mem)cpy$", "wcscpy"),
      execp("[a-c]{3}", "xxabcxx"),
      execp("[a-c]{3}", "xxabxx"),
      execp("[^a-z]", "abc"),
      execp("\\d+_\\w", "sub_12_a"),
      execp("a.c", "abc"),
      execp("a.c", "a\nc"),
      execp("a.c", "ac"),
      execp("x*", ""),
      execp("\\bfoo\\b", "a foo b"),
      execp("\\bfoo\\b", "afoob"),
      execp("\\Boo\\B", "afoob"),
      execp("colou?r", "color"),
      execp("(?:ab)+c", "ababc"),
      execp("a{2,}", "caab"),
      execp("a{2,3}b", "ab"),
      execp("a{,2}", "a{,2}"),
      execp("x{", "x{"),
    ],
    content=(
      #|[
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  false,
      #|  true,
      #|  false,
      #|  false,
      #|  true,
      #|  true,
      #|  false,
      #|  false,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|  true,
      #|  true,
      #|  false,
      #|  true,
      #|  true,
      #|]
    ),
  )
}

///|
test "classes and escapes" {
  debug_inspect(
    [
      execp("[\\d_]+$", "x_12"),
      execp("[\\w-]", "-"),
      execp("[a\\-z]", "-"),
      execp("[]a]", "]"),
      execp("\\s", "a\tb"),
      execp("\\S", " \t"),
      execp("\\.", "abc"),
      execp("\\.", "a.c"),
      execp("\\t", "a\tb"),
      execp("[^\\s]", "  "),
    ],
    content=(
      #|[true, true, true, true, true, false, false, true, true, false]
    ),
  )
}

///|
test "quantifier modes and whole matches" {
  let find = (pattern : String, input : String) => {
    @regex.Regex::compile(pattern).unwrap().find(input)
  }
  debug_inspect(
    [
      find("a+", "baaab"),
      find("a+?", "baaab"),
      find("<.*>", "<a><b>"),
      find("<.*?>", "<a><b>"),
      find("a{2}", "aaaa"),
      find("z", "abc"),
    ],
    content=(
      #|[
      #|  Some("aaa"),
      #|  Some("a"),
      #|  Some("<a><b>"),
      #|  Some("<a>"),
      #|  Some("aa"),
      #|  None,
      #|]
    ),
  )
  // possessive repetitions do not give characters back
  inspect(execp("a*+a", "aaa"), content="false")
  inspect(execp("a*a", "aaa"), content="true")
  inspect(execp("x?+y", "xy"), content="true")
  let re = @regex.Regex::compile("(ab)*c").unwrap()
  inspect(re.matches("ababc"), content="true")
  inspect(re.matches("ababcd"), content="false")
  inspect(re.execp("ababcd"), content="true")
  inspect(re, content="(ab)*c")
  inspect(re.source(), content="(ab)*c")
}

///|
test "case-insensitive matching" {
  inspect(execp("memcpy", "MEMCPY"), content="false")
  inspect(execp("memcpy", "MEMCPY", caseless=true), content="true")
  inspect(execp("[a-c]+X", "ABx", caseless=true), content="true")
  inspect(execp("[^a]", "A", caseless=true), content="false")
}

///|
test "syntax errors" {
  debug_inspect(
    [
      error_of("(ab"),
      error_of("ab)"),
      error_of("*a"),
      error_of("a**"),
      error_of("^*"),
      error_of("(?<x>a)"),
      error_of("[abc"),
      error_of("[z-a]"),
      error_of("a{3,1}"),
      error_of("a\\"),
    ],
    content=(
      #|[
      #|  "unexpected end of regular expression",
      #|  "unbalanced parenthesis",
      #|  "nothing to repeat",
      #|  "nothing to repeat",
      #|  "nothing to repeat",
      #|  "unsupported group syntax",
      #|  "unexpected end of regular expression",
      #|  "range out of order in character class",
      #|  "numbers out of order in {} quantifier",
      #|  "unexpected end of regular expression",
      #|]
    ),
  )
}

///|
test "deep inputs do not blow up simple patterns" {
  let input = String::make(2000, 'a') + "b"
  inspect(execp("a*b", input), content="true")
  inspect(execp("^a+$", input), content="false")
}
