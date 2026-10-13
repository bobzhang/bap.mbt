// Tests of the lexer and the preprocessor subset.

///|
fn pp(
  text : String,
  files~ : Map[String, String] = {},
  include_dirs~ : Array[String] = [],
) -> String raise {
  let p = @c_parser.Preprocessor::new(
    read_file=path => files.get(path),
    include_dirs~,
  )
  @c_parser.tokens_to_string(p.run(text, file="main.h")[:])
}

///|
fn pp_error(text : String, files~ : Map[String, String] = {}) -> String {
  try pp(text, files~) catch {
    @c_parser.ParseError(msg) => msg
    e => e.to_string()
  } noraise {
    out => "no error: " + out
  }
}

///|
test "tokens" {
  let toks = @c_parser.tokenize(
    (
      #|int x = 0x1fUL + 1.5e-3 + .5f; // comment
      #|char *s = "a\"b\n" /* multi
      #|line */ 'c' '\x41' L"w" ...;
    ),
  )
  inspect(
    toks.map(t => "\{t.line}:\{t.text}").join(" "),
    content=(
      #|1:int 1:x 1:= 1:0x1fUL 1:+ 1:1.5e-3 1:+ 1:.5f 1:; 2:char 2:* 2:s 2:= 2:a"b
      #| 3:c 3:A 3:w 3:... 3:;
    ),
  )
  debug_inspect(
    toks.map(t => t.kind),
    content=(
      #|[
      #|  Ident,
      #|  Ident,
      #|  Punct,
      #|  IntLit,
      #|  Punct,
      #|  FloatLit,
      #|  Punct,
      #|  FloatLit,
      #|  Punct,
      #|  Ident,
      #|  Punct,
      #|  Ident,
      #|  Punct,
      #|  StrLit,
      #|  CharLit,
      #|  CharLit,
      #|  StrLit,
      #|  Punct,
      #|  Punct,
      #|]
    ),
  )
  // lenient lexing of stray characters and unterminated literals
  debug_inspect(
    @c_parser.tokenize("don't @").map(t => (t.kind, t.text)),
    content=(
      #|[(Ident, "don"), (Other, "'t @")]
    ),
  )
}

///|
test "comments and line continuations" {
  inspect(
    pp(
      (
        #|int /* a
        #|   comment */ a; // line comment \
        #|continued comment
        #|#define LONG_MACRO 1 + \
        #|  2
        #|int b[LONG_MACRO];
        #|int c\
        #|d;
      ),
    ),
    content=(
      #|int a;
      #|int b[1 + 2];
      #|int cd;
    ),
  )
}

///|
test "object-like and function-like macros" {
  inspect(
    pp(
      (
        #|#define N 16
        #|#define M N
        #|#define SELF SELF + 1
        #|#define EMPTY
        #|#define MAX(a, b) ((a) > (b) ? (a) : (b))
        #|#define STR(x) #x
        #|#define CAT(a, b) a ## b
        #|#define CALL(f, ...) f(__VA_ARGS__)
        #|#define F2 MAX
        #|int a[N], b[M]; int s = SELF; EMPTY int e;
        #|int m = MAX(N, 2); const char *str = STR(hello world);
        #|int CAT(foo, 1); int c = CALL(g, 1, 2); int d = CALL(h);
        #|int f2 = F2(1, 2); int nf = MAX;
        #|#undef N
        #|int n = N;
      ),
    ),
    content=(
      #|int a[16], b[16]; int s = SELF + 1; int e;
      #|int m = ((16) > (2) ? (16) : (2)); const char *str = "hello world";
      #|int foo1; int c = g(1, 2); int d = h();
      #|int f2 = ((1) > (2) ? (1) : (2)); int nf = MAX;
      #|int n = N;
    ),
  )
  inspect(
    pp_error("#define MAX(a, b) a\nMAX(1)"),
    content="main.h:2: macro MAX expects 2 arguments, got 1",
  )
  inspect(
    pp_error("#define F(x) x\nF(1"),
    content="main.h:2: unterminated invocation of macro F",
  )
}

///|
test "conditional compilation" {
  inspect(
    pp(
      (
        #|#define ONE 1
        #|#if 0
        #|this isn't C at all @ '
        #|#if 1
        #|nested
        #|#endif
        #|#else
        #|int a;
        #|#endif
        #|#ifdef ONE
        #|int b;
        #|#endif
        #|#ifndef ONE
        #|int c;
        #|#elif defined(ONE) && ONE + 1 == 2
        #|int d;
        #|#elif 1
        #|int e;
        #|#else
        #|int f;
        #|#endif
        #|#if (UNDEFINED || !defined ONE) || (3 * 4 / 2 - 6) || ('a' != 97)
        #|int g;
        #|#elif (1 << 4) == 16 && -1 < 0 && ~0 == -1 && 7 % 4 == 3 && (0 ? 0 : 1)
        #|int h;
        #|#endif
      ),
    ),
    content=(
      #|int a;
      #|int b;
      #|int d;
      #|int h;
    ),
  )
  inspect(
    pp_error("#if 1\nint x;"),
    content="main.h: unterminated conditional directive",
  )
  inspect(pp_error("#endif"), content="main.h:1: #endif without #if")
  inspect(pp_error("#else"), content="main.h:1: #else without #if")
  inspect(
    pp_error("#if 1\n#else\n#else\n#endif"),
    content="main.h:3: #else after #else",
  )
  inspect(
    pp_error("#if 1/0\n#endif"),
    content="main.h:1: division by zero in #if",
  )
}

///|
test "includes" {
  let files : Map[String, String] = {
    "types.h": "#pragma once\ntypedef unsigned long size_t;",
    "sys/api.h": "#include \"types.h\"\nsize_t f(void);",
    "sys/types.h": "#pragma once\ntypedef int local_t;",
    "/usr/include/stdio.h": "int puts(const char *);",
  }
  // `"sys/api.h"` includes `sys/types.h` (relative to the including file)
  inspect(
    pp(
      (
        #|#include "types.h"
        #|#include "types.h"
        #|#include "sys/api.h"
        #|#include <stdio.h>
        #|#define HDR "types.h"
        #|#include HDR
      ),
      files~,
      include_dirs=["/usr/include"],
    ),
    content=(
      #|typedef unsigned long size_t;
      #|typedef int local_t;
      #|size_t f(void);
      #|int puts(const char *);
    ),
  )
  inspect(
    pp_error("#include <missing.h>", files~),
    content="main.h:1: cannot find include file missing.h",
  )
  inspect(
    pp_error("#include \"loop.h\"", files={ "loop.h": "#include \"loop.h\"" }),
    content="loop.h:1: #include nested too deeply",
  )
}

///|
test "other directives" {
  inspect(
    pp(
      (
        #|# 1 "file.h"
        #|#line 10
        #|#pragma pack(1)
        #|#ident "x"
        #|#warning careful
        #|#
        #|int x;
      ),
    ),
    content="int x;",
  )
  inspect(pp_error("#error stop here"), content="main.h:1: #error stop here")
  inspect(
    pp_error("#frobnicate"),
    content="main.h:1: unknown directive #frobnicate",
  )
}

///|
test "macros in declarations" {
  let decls = @c_parser.parse_string(
    @c.SizeBase::new(LP64),
    (
      #|#define BUFSIZE 0x20
      #|#define FIRST 3
      #|#define ATTR __attribute__((nonnull(1)))
      #|enum e { A = FIRST, B };
      #|enum e v;
      #|char buf[BUFSIZE];
      #|int f(char *s) ATTR;
    ),
    defines=[("EXTRA", "1")],
  )
  inspect(
    decls
    .filter(d => d.0 is ("v" | "buf" | "f"))
    .map(d => "\{d.0}: \{d.1}")
    .join("\n"),
    content=(
      #|v: enum {
      #|    A= 3,,
      #|    B,,
      #|}
      #|
      #|buf: char[32]
      #|f: signed (*)(char* s) __attribute__((nonnull(1))) ;
    ),
  )
}

///|
test "parse_definitions produces the FrontC-like AST" {
  let defs = @c_parser.parse_definitions(
    @c_parser.tokenize("typedef const char *str; str f(str, ...);"),
  )
  debug_inspect(
    defs,
    content=(
      #|[
      #|  TypeDef(
      #|    {
      #|      typ: Const(Char(NoSign)),
      #|      storage: NoStorage,
      #|      names: [
      #|        {
      #|          name: "str",
      #|          typ: Ptr(Const(Char(NoSign))),
      #|          attrs: [],
      #|          init: Nothing,
      #|        },
      #|      ],
      #|    },
      #|    [],
      #|  ),
      #|  DecDef(
      #|    {
      #|      typ: NamedType("str"),
      #|      storage: NoStorage,
      #|      names: [
      #|        {
      #|          name: "f",
      #|          typ: Proto(
      #|            NamedType("str"),
      #|            [
      #|              {
      #|                typ: NamedType("str"),
      #|                storage: NoStorage,
      #|                name: { name: "", typ: NamedType("str"), attrs: [], init: Nothing },
      #|              },
      #|            ],
      #|            true,
      #|          ),
      #|          attrs: [],
      #|          init: Nothing,
      #|        },
      #|      ],
      #|    },
      #|  ),
      #|]
    ),
  )
}

///|
test "parse_file reads through the reader" {
  let files : Map[String, String] = {
    "/api/c/lib.h": "#include \"inc.h\"\nT g(T);",
    "/api/c/inc.h": "typedef long T;",
  }
  let result = @c_parser.parse_file(@c.SizeBase::new(LP64), "/api/c/lib.h", read_file=p => {
    files.get(p)
  })
  guard result is Ok(decls) else { fail("expected success") }
  inspect(
    decls.filter(d => d.0 is ("T" | "g")).map(d => d.0).join(","),
    content="T,g",
  )
  debug_inspect(
    @c_parser.parse_file(@c.SizeBase::new(LP64), "/nope.h", read_file=_ => None),
    content=(
      #|Err("/nope.h: no such file")
    ),
  )
  debug_inspect(
    @c_parser.parse_file(@c.SizeBase::new(LP64), "/bad.h", read_file=_ => {
      Some("int f(")
    }),
    content=(
      #|Err("/bad.h:1: expected a parameter declaration at the end of input")
    ),
  )
}

///|
test "provide registers the parser" {
  @c_parser.provide(read_file=p => {
    if p == "x.h" {
      Some("int x(void);")
    } else {
      None
    }
  })
  guard @c.run_parser(@c.SizeBase::new(LP64), "x.h") is Ok(decls) else {
    fail("parser failed")
  }
  assert_true(decls.iter().any(d => d.0 == "x"))
}
