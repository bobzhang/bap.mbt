// The standard Primus Lisp primitives (upstream
// `plugins/primus_lisp/primus_lisp_primitives.ml`).

///|
fn addr_width(m : @primus.Machine) -> Int {
  get_state(m).width
}

///|
fn to_small_int(m : @primus.Machine, v : @primus.Value) -> Int raise {
  match word_to_int(v.to_word()) {
    Some(n) => n
    None => {
      failf(m, "expected smallint")
      0
    }
  }
}

///|
fn msb_of(m : @primus.Machine, x : @primus.Value) -> @primus.Value raise {
  let hi = x.bitwidth() - 1
  @primus.Interpreter::extract(m, hi~, lo=hi, x)
}

///|
fn all_of(
  m : @primus.Machine,
  f : (@primus.Value) -> @primus.Value raise,
  xs : Array[@primus.Value],
) -> @primus.Value raise {
  let mut r = @primus.Value::one(m, 1)
  for x in xs {
    let y = f(x)
    if !y.is_one() {
      return y
    }
    r = @primus.Interpreter::binop(m, And, r, y)
  }
  r
}

///|
fn ordered(
  m : @primus.Machine,
  order : (@primus.Value, @primus.Value) -> @primus.Value raise,
  xs : Array[@primus.Value],
) -> @primus.Value raise {
  let mut r = @primus.Value::one(m, 1)
  for i in 1..<xs.length() {
    let y = order(xs[i - 1], xs[i])
    if !y.is_one() {
      return y
    }
    r = @primus.Interpreter::binop(m, And, r, y)
  }
  r
}

///|
fn reduce(
  null : () -> @primus.Value raise,
  op : (@primus.Value, @primus.Value) -> @primus.Value raise,
  xs : Array[@primus.Value],
) -> @primus.Value raise {
  match xs {
    [] => null()
    [x, .. rest] => {
      let mut r = x
      for y in rest {
        r = op(r, y)
      }
      r
    }
  }
}

///|
fn is_zero_prim(
  m : @primus.Machine,
  xs : Array[@primus.Value],
) -> @primus.Value raise {
  all_of(
    m,
    x => {
      @primus.Interpreter::binop(m, Eq, x, @primus.Value::zero(m, x.bitwidth()))
    },
    xs,
  )
}

///|
fn symbol_of_cstring(m : @primus.Machine, ptr : @primus.Value) -> String raise {
  let buf = StringBuilder()
  let mut p = ptr.to_word()
  for i = 0; i < 1_000_000; i = i + 1 {
    let c = @primus.Memory::load(m, p)
    if c.is_zero() {
      break
    }
    buf.write_char(c.to_int().unsafe_to_char())
    p = p.succ()
  }
  buf.to_string()
}

///|
fn memory_allocate(
  m : @primus.Machine,
  addr : @primus.Value,
  size : @primus.Value,
  rest : ArrayView[@primus.Value],
) -> @primus.Value raise {
  let width = addr_width(m)
  let is_nil = (x : @primus.Value) => x.to_word().is_zero()
  let generator : @primus.Generator? = match rest {
    [] => None
    [x] => Some(@primus.Generator::static_value(width~, to_small_int(m, x)))
    [lo, hi] =>
      if is_nil(lo) && is_nil(hi) {
        None
      } else {
        let min = if is_nil(lo) { None } else { Some(to_small_int(m, lo)) }
        let max = if is_nil(hi) { None } else { Some(to_small_int(m, hi)) }
        Some(@primus.Generator::seeded_lcg(width~, min?, max?))
      }
    _ => {
      failf(m, "memory-allocate: bad generator specification")
      None
    }
  }
  let lower = addr.to_word()
  let n = to_small_int(m, size)
  if n > 0 {
    let upper = lower.nsucc(n - 1)
    @primus.Memory::add_region(m, generator?, lower~, upper~)
  }
  @primus.Value::zero(m, 8)
}

///|
fn set_symbol_value(
  m : @primus.Machine,
  reg : @primus.Value,
  x : @primus.Value,
) -> @primus.Value raise {
  let name = @primus.Value::symbol_of_value(m, reg)
  let v = @types.Var::create(name, Imm(x.bitwidth()))
  @primus.Interpreter::set(m, v, x)
  x
}

///|
fn find_sub_by_addr(
  m : @primus.Machine,
  addr : @types.Word,
) -> @types.Term[@types.Sub]? {
  for s in m.program().subs() {
    if @primus.term_address(s) is Some(a) && a == addr {
      return Some(s)
    }
  }
  None
}

///|
/// The standard primitives: name, signature, documentation, implementation.
fn standard_primitives(
  bits : Int,
) -> Array[(String, Signature, String, Closure)] {
  let any : Typ = Any
  let sym : Typ = Symbol
  let int : Typ = Type(bits)
  let bool : Typ = Type(1)
  let byte : Typ = Type(8)
  let a : Typ = Name("a")
  let b : Typ = Name("b")
  let all = (t : Typ, r : Typ) => arrow(All(t), r)
  let one = (t : Typ, r : Typ) => arrow(Tuple([t]), r)
  let tuple = (ts : Array[Typ], r : Typ) => arrow(Tuple(ts), r)
  let sync = Closure::sync
  let null = (m : @primus.Machine) => {
    fn() -> @primus.Value raise { @primus.Value::zero(m, addr_width(m)) }
  }
  let binop = (op : @types.BinOp) => {
    sync((m, _, args) => {
      reduce(null(m), (x, y) => @primus.Interpreter::binop(m, op, x, y), args)
    })
  }
  let order = (op : @types.BinOp, swap : Bool) => {
    sync((m, _, args) => {
      ordered(
        m,
        (x, y) => {
          if swap {
            @primus.Interpreter::binop(m, op, y, x)
          } else {
            @primus.Interpreter::binop(m, op, x, y)
          }
        },
        args,
      )
    })
  }
  let shift = (op : @types.BinOp) => {
    sync((m, name, args) => {
      match args {
        [x, y] => @primus.Interpreter::binop(m, op, x, y)
        _ => {
          failf(m, "\{name}: invalid number of arguments")
          @primus.Value::b0(m)
        }
      }
    })
  }
  let unary = (f : (@primus.Machine, @primus.Value) -> @primus.Value raise) => {
    sync((m, name, args) => {
      match args {
        [x] => f(m, x)
        _ => {
          failf(m, "\{name}: invalid number of arguments")
          @primus.Value::b0(m)
        }
      }
    })
  }
  let negone = (m : @primus.Machine) => {
    fn() -> @primus.Value raise { @primus.Value::one(m, 8) }
  }
  let logop = (op : @types.BinOp) => {
    sync((m, _, args) => {
      reduce(negone(m), (x, y) => @primus.Interpreter::binop(m, op, x, y), args)
    })
  }
  [
    (
      "exec-addr",
      one(int, any),
      "(exec-addr D) passes the control flow to D and never returns",
      Closure::new((m, name, args, _) => {
        match args {
          [dst] =>
            m.call(Addr(dst.to_word()), then=(m, _) => {
              @primus.Interpreter::halt(m)
            })
          _ => failf(m, "\{name}: invalid number of arguments")
        }
      }),
    ),
    (
      "exec-symbol",
      one(sym, any),
      "(exec-symbol D) passes the control flow to D and never returns",
      Closure::new((m, name, args, _) => {
        match args {
          [dst] => {
            let s = @primus.Value::symbol_of_value(m, dst)
            m.call(Symbol(s), then=(m, _) => @primus.Interpreter::halt(m))
          }
          _ => failf(m, "\{name}: invalid number of arguments")
        }
      }),
    ),
    (
      "is-zero",
      all(any, bool),
      "(is-zero X Y ...) returns true if all arguments are zeros",
      sync((m, _, args) => is_zero_prim(m, args)),
    ),
    (
      "is-positive",
      all(any, bool),
      "(is-positive X Y ...) returns true if all arguments are positive",
      sync((m, _, args) => {
        all_of(m, x => @primus.Interpreter::unop(m, Not, msb_of(m, x)), args)
      }),
    ),
    (
      "is-negative",
      all(any, bool),
      "(is-negative X Y ...) returns true if all arguments are negative",
      sync((m, _, args) => all_of(m, x => msb_of(m, x), args)),
    ),
    (
      "word-width",
      all(int, int),
      "(word-width) returns machine word width in bits",
      sync((m, _, args) => {
        let width = addr_width(m)
        let w = args.fold(init=0, (acc, x) => @cmp.maximum(acc, x.bitwidth()))
        @primus.Value::of_int(
          m,
          width~,
          if args.is_empty() {
            width
          } else {
            w
          },
        )
      }),
    ),
    (
      "exit-with",
      one(int, any),
      "(exit-with N) terminates program with the exit code N",
      sync((m, _, _) => @primus.Interpreter::halt(m)),
    ),
    (
      "memory-read",
      one(int, byte),
      "(memory-read A) loads one byte from the address A",
      unary((m, x) => @primus.Interpreter::load(m, x, BigEndian, R8)),
    ),
    (
      "memory-write",
      tuple([int, byte], int),
      "(memory-write A X) stores by X to A",
      sync((m, name, args) => {
        match args {
          [a, x] => {
            @primus.Interpreter::store(m, a, x, BigEndian, R8)
            @primus.Value::succ(m, a)
          }
          _ => {
            failf(m, "\{name}: invalid number of arguments")
            @primus.Value::b0(m)
          }
        }
      }),
    ),
    (
      "memory-allocate",
      arrow(Gen([int, int], byte), byte),
      "(memory-allocate P N V?) maps memory region [P,P+N), if V is provided, then fills the newly mapped region with the value V",
      sync((m, name, args) => {
        match args {
          [x, y, .. rest] => memory_allocate(m, x, y, rest)
          _ => {
            failf(m, "\{name}: invalid number of arguments")
            @primus.Value::b0(m)
          }
        }
      }),
    ),
    (
      "get-current-program-counter",
      tuple([], int),
      "(get-current-program-counter) returns current program counter",
      sync((m, _, _) => @primus.Value::of_word(m, @primus.Interpreter::pc(m))),
    ),
    ("+", all(a, a), "(+ X Y ...) returns the sum of arguments", binop(Plus)),
    ("-", all(a, a), "(- X Y Z ...) returns X - Y - Z - ...", binop(Minus)),
    (
      "*",
      all(a, a),
      "(* X Y Z ...) returns the product of arguments",
      binop(Times),
    ),
    ("/", all(a, a), "(/ X Y Z ...) returns X / Y / Z / ...", binop(Div)),
    ("s/", all(a, a), "(s/ X Y Z ...) signed division", binop(SignedDiv)),
    ("mod", all(a, a), "(mod X Y Z ...) the modulo operation", binop(Mod)),
    (
      "signed-mod",
      all(a, a),
      "(signed-mod X Y Z ...) signed modulo",
      binop(SignedMod),
    ),
    (
      "lshift",
      tuple([a, b], a),
      "(lshift X N) logically shifts X left by N bits",
      shift(LShift),
    ),
    (
      "rshift",
      tuple([a, b], a),
      "(rshift X N) logically shifts X right by N bits",
      shift(RShift),
    ),
    (
      "arshift",
      tuple([a, b], a),
      "(arshift X N) arithmetically shifts X right by N bits",
      shift(ARShift),
    ),
    (
      "=",
      all(a, bool),
      "(= X Y Z ...) returns true if all arguments are equal",
      order(Eq, false),
    ),
    (
      "/=",
      all(a, bool),
      "(/= X Y Z ...) returns true if at least one argument is not equal to another argument",
      order(Neq, false),
    ),
    ("logand", all(a, a), "(logand X Y Z ...) the bitwise AND", logop(And)),
    ("logor", all(a, a), "(logor X Y Z ...) the bitwise OR", logop(Or)),
    ("logxor", all(a, a), "(logxor X Y Z ...) the bitwise XOR", logop(Xor)),
    (
      "concat",
      all(any, any),
      "(concat X Y Z ...) concatenates words X, Y, Z, ... into one big word",
      sync((m, _, args) => {
        reduce(
          fn() -> @primus.Value raise { @primus.Value::zero(m, 1) },
          (x, y) => @primus.Interpreter::concat(m, x, y),
          args,
        )
      }),
    ),
    (
      "extract",
      tuple([any, any, any], any),
      "(extract HI LO X) extracts bits from HI to LO (including both) from the word X",
      sync((m, name, args) => {
        match args {
          [hi, lo, x] =>
            @primus.Interpreter::extract(
              m,
              hi=to_small_int(m, hi),
              lo=to_small_int(m, lo),
              x,
            )
          _ => {
            failf(m, "\{name}: invalid number of arguments")
            @primus.Value::b0(m)
          }
        }
      }),
    ),
    (
      "lnot",
      one(a, a),
      "(lnot X) returns the one complement of X",
      unary((m, x) => @primus.Interpreter::unop(m, Not, x)),
    ),
    (
      "not",
      one(a, a),
      "(not X) returns true if X is zero",
      unary((m, x) => is_zero_prim(m, [x])),
    ),
    (
      "neg",
      one(a, a),
      "(neg X) returns the two complement of X",
      unary((m, x) => @primus.Interpreter::unop(m, Neg, x)),
    ),
    (
      "<",
      all(a, bool),
      "(< X Y Z ...) is true if the list of arguments is a strict ascending chain",
      order(Lt, false),
    ),
    (
      ">",
      all(a, bool),
      "(> X Y Z ...) is true if the list of arguments is a strict descending chain",
      order(Lt, true),
    ),
    (
      "<=",
      all(a, bool),
      "(<= X Y Z ...) is true if the list of arguments is an ascending chain",
      order(Le, false),
    ),
    (
      ">=",
      all(a, bool),
      "(>= X Y Z ...) is true if the list of arguments is a descending chain",
      order(Le, true),
    ),
    (
      "symbol-concat",
      all(sym, sym),
      "(symbol-concat X Y Z ...) returns a new symbol that is a concatenation of symbols X,Y,Z,...",
      sync((m, _, args) => {
        let s = args.map(x => @primus.Value::symbol_of_value(m, x)).join("")
        @primus.Value::symbol_to_value(m, s)
      }),
    ),
    (
      "set-symbol-value",
      tuple([sym, a], a),
      "(set-symbol-value S X) sets the value of the symbol S to X. Returns X",
      sync((m, name, args) => {
        match args {
          [s, x] => set_symbol_value(m, s, x)
          _ => {
            failf(m, "\{name}: invalid number of arguments")
            @primus.Value::b0(m)
          }
        }
      }),
    ),
    (
      "symbol-of-string",
      one(int, sym),
      "(symbol-of-string ptr) returns a symbol from a null-terminated string.",
      unary((m, p) => @primus.Value::symbol_to_value(m, symbol_of_cstring(m, p))),
    ),
    (
      "invoke-subroutine",
      arrow(Gen([int], any), any),
      "(invoke-subroutine addr args ...) calls the subroutine at the specified address.",
      Closure::new((m, name, args, k) => {
        match args {
          [] => failf(m, "\{name}: requires at least one argument")
          [addr, .. rest] =>
            match find_sub_by_addr(m, addr.to_word()) {
              None => failf(m, "\{name}: no function for \{addr}")
              Some(sub) =>
                m.call_code(Subroutine(sub), args=rest.to_owned(), then=(m, r) => {
                  match r {
                    Some(r) => k(m, r)
                    None =>
                      step(
                        m,
                        m => @primus.Interpreter::constant(m, @types.Word::b0()),
                        k,
                      )
                  }
                })
            }
        }
      }),
    ),
  ]
}

///|
/// Defines the standard primitives in the machine (upstream
/// `Primus_lisp_primitives.init`).
pub fn init_primitives(m : @primus.Machine) -> Unit {
  for p in standard_primitives(addr_width(m)) {
    define_primitive(m, p.0, types=p.1, docs=p.2, p.3)
  }
}
