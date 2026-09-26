// Tests of the C declaration parser and of its mapping to `@c` types.

///|
/// A compact rendering of C types for the tests.
fn show(t : @c.CType) -> String {
  let attrs = (xs : Array[@c.Attr]) => {
    if xs.is_empty() {
      ""
    } else {
      " [[" + xs.map(a => a.to_string()).join(", ") + "]]"
    }
  }
  let cv = (c : Bool, v : Bool) => {
    (if c { "const " } else { "" }) + (if v { "volatile " } else { "" })
  }
  match t {
    Void => "void"
    Basic(s) =>
      cv(s.qualifier.const_, s.qualifier.volatile_) +
      (match s.t {
        Enum(items) =>
          "enum{" +
          items
          .map(i => {
            match i.1 {
              Some(v) => "\{i.0}=\{v}"
              None => i.0
            }
          })
          .join(",") +
          "}"
        b => b.to_string()
      }) +
      attrs(s.attrs)
    Pointer(s) =>
      cv(s.qualifier.const_, s.qualifier.volatile_) +
      (if s.qualifier.restrict { "restrict " } else { "" }) +
      "ptr(" +
      show(s.t) +
      ")" +
      attrs(s.attrs)
    Array(s) => {
      let size = match s.t.size {
        Some(n) => n.to_string()
        None => ""
      }
      show(s.t.element) + "[" + size + "]" + attrs(s.attrs)
    }
    Structure(s) | Union(s) => {
      let kw = if t is Structure(_) { "struct" } else { "union" }
      kw +
      " " +
      s.t.name +
      "{" +
      s.t.fields.map(f => "\{f.0}: \{show(f.1)}").join("; ") +
      "}" +
      attrs(s.attrs)
    }
    Function(s) => {
      let args = s.t.args.map(a => {
        if a.0 == "" {
          show(a.1)
        } else {
          "\{a.0}: \{show(a.1)}"
        }
      })
      if s.t.variadic {
        args.push("...")
      }
      "fn(" + args.join(", ") + ") -> " + show(s.t.return_) + attrs(s.attrs)
    }
  }
}

///|
fn lp64() -> &@c.Ruler {
  @c.SizeBase::new(LP64)
}

///|
/// Parses `text` and renders the declarations except the predefined ones.
fn decls(text : String, size? : &@c.Ruler = lp64()) -> String raise {
  let predefined = @c_parser.predefined_types(size).map(p => p.0)
  @c_parser.parse_string(size, text)
  .filter(d => !predefined.contains(d.0))
  .map(d => "\{d.0}: \{show(d.1)}")
  .join("\n")
}

///|
test "basic types" {
  inspect(
    decls(
      (
        #|char c; signed char sc; unsigned char uc;
        #|short s; short int si; unsigned short us; signed short ss;
        #|int i; signed sg; unsigned u; unsigned int ui;
        #|long l; long int li; unsigned long ul; long unsigned int lui;
        #|long long ll; unsigned long long ull; long long int lli;
        #|float f; double d; long double ld; _Bool b;
        #|float _Complex cf; double _Complex cd; long double _Complex cld;
        #|_Complex c2; void *vp;
      ),
    ),
    content=(
      #|c: char
      #|sc: signed char
      #|uc: unsigned char
      #|s: signed short
      #|si: signed short
      #|us: unsigned short
      #|ss: signed short
      #|i: signed
      #|sg: signed
      #|u: unsigned
      #|ui: unsigned
      #|l: signed long
      #|li: signed long
      #|ul: unsigned long
      #|lui: unsigned long
      #|ll: signed long long
      #|ull: unsigned long long
      #|lli: signed long long
      #|f: float
      #|d: double
      #|ld: long double
      #|b: _Bool
      #|cf: float complex
      #|cd: double complex
      #|cld: long double complex
      #|c2: double complex
      #|vp: ptr(void)
    ),
  )
}

///|
test "predefined integer types follow the data model" {
  let names = (size : &@c.Ruler) => {
    @c_parser.predefined_types(size).map(p => "\{p.0}=\{show(p.1)}").join(" ")
  }
  inspect(
    names(@c.SizeBase::new(LP64)),
    content=(
      #|uint8_t=_Bool int8_t=signed char uint16_t=unsigned short int16_t=signed short uint32_t=unsigned int32_t=signed uint64_t=unsigned long int64_t=signed long
    ),
  )
  inspect(
    names(@c.SizeBase::new(ILP32)),
    content=(
      #|uint8_t=_Bool int8_t=signed char uint16_t=unsigned short int16_t=signed short uint32_t=unsigned int32_t=signed uint64_t=unsigned long long int64_t=signed long long
    ),
  )
  inspect(
    decls("uint32_t x; int64_t y;", size=@c.SizeBase::new(ILP32)),
    content=(
      #|x: unsigned
      #|y: signed long long
    ),
  )
}

///|
test "qualifiers" {
  inspect(
    decls(
      (
        #|const int ci; int const ic; volatile int vi; const volatile int cvi;
        #|const char *pc; char *const cp; char *const *cpp;
        #|char *restrict rp; char *__restrict rp2; const char *__restrict__ crp;
        #|volatile char *const volatile vcv;
        #|const int arr[3];
      ),
    ),
    content=(
      #|ci: const signed
      #|ic: const signed
      #|vi: volatile signed
      #|cvi: const volatile signed
      #|pc: ptr(const char)
      #|cp: const ptr(char)
      #|cpp: ptr(const ptr(char))
      #|rp: restrict ptr(char)
      #|rp2: restrict ptr(char)
      #|crp: restrict ptr(const char)
      #|vcv: const volatile ptr(volatile char)
      #|arr: const signed[3]
    ),
  )
}

///|
test "arrays and pointers" {
  inspect(
    decls(
      (
        #|int a[10]; int b[]; int m[2][3]; int *ap[4]; int (*pa)[5];
        #|char **argv; int h[0x10]; int o[010]; int e[2 * 3]; int p[(7)];
        #|int neg[-1];
      ),
    ),
    content=(
      #|a: signed[10]
      #|b: signed[]
      #|m: signed[3][2]
      #|ap: ptr(signed)[4]
      #|pa: ptr(signed[5])
      #|argv: ptr(ptr(char))
      #|h: signed[16]
      #|o: signed[10]
      #|e: signed[]
      #|p: signed[7]
      #|neg: signed[]
    ),
  )
}

///|
test "function prototypes" {
  inspect(
    decls(
      (
        #|void f0(void);
        #|int f1();
        #|int f2(int x, char *s);
        #|int f3(int, char *);
        #|int printf(const char *fmt, ...);
        #|void *f4(void *);
        #|int f5(int fds[2]);
        #|extern int f6(register int r);
        #|static inline int f7(int x) { if (x) { return 1; } return 0; }
        #|int f8(a, b);
        #|int f9(a, b) int a; char b; { return a; }
      ),
    ),
    content=(
      #|f0: fn() -> void
      #|f1: fn() -> signed
      #|f2: fn(x: signed, s: ptr(char)) -> signed
      #|f3: fn(signed, ptr(char)) -> signed
      #|printf: fn(fmt: ptr(const char), ...) -> signed
      #|f4: fn(ptr(void)) -> ptr(void)
      #|f5: fn(fds: signed[2]) -> signed
      #|f6: fn(r: signed) -> signed
      #|f7: fn(x: signed) -> signed
      #|f8: void
      #|f9: void
    ),
  )
}

///|
test "function pointers" {
  inspect(
    decls(
      (
        #|int (*cmp)(const void *, const void *);
        #|void (*signal(int sig, void (*handler)(int)))(int);
        #|int atexit(void (*callback)(void));
        #|typedef int (*handler_t)(int);
        #|handler_t install(handler_t h);
        #|int (*table[4])(void);
        #|int __libc_start_main(int (*main) (int, char **, char **), int, char **, void *auxv);
      ),
    ),
    content=(
      #|cmp: ptr(fn(ptr(void), ptr(void)) -> signed)
      #|signal: fn(sig: signed, handler: ptr(fn(signed) -> void)) -> ptr(fn(signed) -> void)
      #|atexit: fn(callback: ptr(fn() -> void)) -> signed
      #|handler_t: ptr(fn(signed) -> signed)
      #|install: fn(h: ptr(fn(signed) -> signed)) -> ptr(fn(signed) -> signed)
      #|table: ptr(fn() -> signed)[4]
      #|__libc_start_main: fn(main: ptr(fn(signed, ptr(ptr(char)), ptr(ptr(char))) -> signed), signed, ptr(ptr(char)), auxv: ptr(void)) -> signed
    ),
  )
}

///|
test "typedefs" {
  inspect(
    decls(
      (
        #|typedef unsigned long int size_t;
        #|typedef void *FILE;
        #|typedef int a_t, b_t;
        #|size_t strlen(const char *);
        #|FILE *fopen(const char *path, const char *mode);
        #|a_t use_a(b_t x);
        #|typedef size_t my_size;
        #|my_size g(my_size my_size);
      ),
    ),
    content=(
      #|size_t: unsigned long
      #|FILE: ptr(void)
      #|strlen: fn(ptr(const char)) -> unsigned long
      #|fopen: fn(path: ptr(const char), mode: ptr(const char)) -> ptr(ptr(void))
      #|use_a: fn() -> void
      #|my_size: unsigned long
      #|g: fn(my_size: unsigned long) -> unsigned long
    ),
  )
}

///|
test "structures and unions" {
  inspect(
    decls(
      (
        #|struct point { int x, y; };
        #|struct point origin;
        #|struct point *moved(const struct point *p, int dx);
        #|union value { int i; double d; char *s; };
        #|union value v;
        #|typedef struct pair { struct point a; struct point *b; } pair_t;
        #|struct pair p1;
        #|struct flags { unsigned a : 1; int : 3; signed b : 2; };
        #|struct flags fl;
        #|struct later *lp;
        #|struct later { char c; };
        #|struct { int anon; } an;
        #|struct outer { struct { int x; } in; union { int u; } un; } out;
      ),
    ),
    content=(
      #|origin: struct point{x: signed; y: signed}
      #|moved: fn(p: ptr(struct point{x: const signed; y: const signed}), dx: signed) -> ptr(struct point{x: signed; y: signed})
      #|v: union value{i: signed; d: double; s: ptr(char)}
      #|pair_t: struct pair{a: struct point{x: signed; y: signed}; b: ptr(struct point{x: signed; y: signed})}
      #|p1: struct pair{}
      #|fl: struct flags{a: void; : void; b: void}
      #|lp: ptr(struct later{c: char})
      #|an: struct {anon: signed}
      #|out: struct outer{in: struct {x: signed}; un: union {u: signed}}
    ),
  )
}

///|
test "empty compounds resolve one level deep" {
  inspect(
    decls(
      (
        #|struct a;
        #|struct b { struct a *pa; };
        #|struct b *pb;
        #|struct a { int x; };
      ),
    ),
    content=(
      #|pb: ptr(struct b{pa: ptr(struct a{})})
    ),
  )
}

///|
test "enumerations" {
  inspect(
    decls(
      (
        #|enum color { RED, GREEN = 5, BLUE = 0x10, NEG = -1, SUF = 2U, OCT = 010, };
        #|enum color c;
        #|enum unknown u;
        #|typedef enum { A = 1, B } ab_t;
        #|ab_t ab;
      ),
    ),
    content=(
      #|c: enum{RED,GREEN=5,BLUE=16,NEG,SUF,OCT=10}
      #|u: enum{}
      #|ab_t: enum{A=1,B}
      #|ab: enum{A=1,B}
    ),
  )
}

///|
test "gnu attributes" {
  inspect(
    decls(
      (
        #|void exit(int code) __attribute__((noreturn));
        #|void *malloc(unsigned long size)
        #|    __attribute__((malloc, warn_unused_result, alloc_size(1)));
        #|int abs(int x) __attribute__((__const__, warn_unused_result));
        #|int printf(const char *restrict format, ...) __attribute__((format(printf,1,2)));
        #|void strxfrm(char *dst, const char *src, unsigned long n)
        #|    __attribute__((nonnull(1,2), storage(dst,n)));
        #|int f(int x __attribute__((unused)), char *s __attribute__((nonnull)));
        #|__attribute__((noreturn)) void g(void);
        #|int h(void) __attribute__(()) __asm__("h_impl");
        #|int k(void) __attribute__((section(".text.k"), aligned(16), weird(-1, a + b)));
        #|typedef int int_attr __attribute__((mode(SI)));
        #|struct __attribute__((packed)) s { char c; int i; } __attribute__((aligned(4)));
        #|struct s ps;
      ),
    ),
    content=(
      #|exit: fn(code: signed) -> void [[noreturn]]
      #|malloc: fn(size: unsigned long) -> ptr(void) [[malloc, warn_unused_result, alloc_size(1)]]
      #|abs: fn(x: signed) -> signed [[const, warn_unused_result]]
      #|printf: fn(format: restrict ptr(const char), ...) -> signed [[format(printf, 1, 2)]]
      #|strxfrm: fn(dst: ptr(char), src: ptr(const char), n: unsigned long) -> void [[nonnull(1, 2), storage(dst, n)]]
      #|f: fn(x: signed [[unused]], s: ptr(char) [[nonnull]]) -> signed
      #|g: fn() -> void
      #|h: fn() -> signed
      #|k: fn() -> signed [[section(.text.k), aligned(16), weird]]
      #|int_attr: signed [[mode(SI)]]
      #|ps: struct s{c: char; i: signed} [[packed, aligned(4)]]
    ),
  )
}

///|
test "multiple declarators and redefinitions" {
  inspect(
    decls(
      (
        #|int a, b;
        #|int c = 1, d;
        #|int e = 2;
        #|int fgetc(void *stream);
        #|int fgetc(void *s2);
        #|const char *names[] = { "a", "b" };
        #|extern const int K;
      ),
    ),
    content=(
      #|e: signed
      #|fgetc: fn(s2: ptr(void)) -> signed
      #|names: ptr(const char)[]
      #|K: const signed
    ),
  )
}

///|
test "extensions are skipped" {
  inspect(
    decls(
      (
        #|__extension__ typedef long long quad_t;
        #|quad_t q;
        #|__builtin_va_list va;
        #|int vprintf(const char *, __builtin_va_list);
        #|_Static_assert(sizeof(int) == 4, "int");
        #|__asm__(".symver foo, foo@1");
        #|__typeof__(q) tq;
        #|static __inline__ __attribute__((always_inline)) int inl(void) { return 0; }
      ),
    ),
    content=(
      #|quad_t: signed long long
      #|q: signed long long
      #|va: void
      #|vprintf: fn(ptr(const char), void) -> signed
      #|tq: void
      #|inl: fn() -> signed [[always_inline]]
    ),
  )
}

///|
test "parse errors" {
  let err = (text : String) => {
    try decls(text) catch {
      @c_parser.ParseError(msg) => msg
      e => e.to_string()
    } noraise {
      _ => "no error"
    }
  }
  inspect(
    err("int x"),
    content=(
      #|<string>:1: expected `;` at the end of input
    ),
  )
  inspect(
    err("int f(int;"),
    content=(
      #|<string>:1: expected `)` before `;`
    ),
  )
  inspect(
    err("unknown_t x;"),
    content=(
      #|<string>:1: expected `;` before `x`
    ),
  )
  inspect(
    err("struct { int x; "),
    content=(
      #|<string>:1: expected `}` at the end of input
    ),
  )
  inspect(
    err("int a;\n@"),
    content=(
      #|<string>:2: expected a declaration before `@`
    ),
  )
}
