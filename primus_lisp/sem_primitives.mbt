// The semantic primitives (upstream
// `plugins/primus_lisp/primus_lisp_semantic_primitives.ml`), compiled to
// BIL.

///|
/// A parameter specification of a primitive signature (upstream
/// `Type.Spec` parameters).
priv enum Params {
  All(Typ)
  Tuple(Array[Typ])
  Gen(Array[Typ], Typ)
}

///|
fn arrow(p : Params, ret : Typ) -> Signature {
  match p {
    All(t) => { args: [], rest: Some(t), ret, }
    Tuple(ts) => { args: ts, rest: None, ret, }
    Gen(ts, t) => { args: ts, rest: Some(t), ret, }
  }
}

///|
/// The type signatures of the semantic primitives for a target with words
/// of `bits` bits.
fn semantic_primitive_types(bits : Int) -> Array[(String, Signature, String)] {
  let any : Typ = Any
  let sym : Typ = Symbol
  let int : Typ = Type(bits)
  let bool : Typ = Type(1)
  let byte : Typ = Type(8)
  let a : Typ = Name("a")
  let b : Typ = Name("b")
  let all_any = arrow(All(any), any)
  let fop = arrow(Gen([sym], any), any)
  let one = (t : Typ, r : Typ) => arrow(Tuple([t]), r)
  let tuple = (ts : Array[Typ], r : Typ) => arrow(Tuple(ts), r)
  [
    ("+", all_any, "(+ X Y ... Z) returns X + Y + ... + Z"),
    ("+.", fop, "(+. MODE X Y ... Z) floating-point addition"),
    ("-", all_any, "(- X Y ... Z) returns X - Y - ... - Z"),
    ("-.", fop, "(-. MODE X Y ... Z) floating-point subtraction"),
    ("neg", one(any, any), "(neg X) returns the two complement of X"),
    ("lnot", one(a, a), "(lnot X) returns a bitwise logical negation of X"),
    ("*", all_any, "(* X Y ... Z) returns X * Y * ... * Z"),
    ("*.", fop, "(*. MODE X Y ... Z) floating-point multiplication"),
    ("/", all_any, "(/ X Y ... Z) returns X / Y / ... / Z"),
    ("/.", fop, "(/. MODE X Y ... Z) floating-point division"),
    ("s/", all_any, "(s/ X Y ... Z) signed division"),
    ("mod", all_any, "(mod X Y ... Z) the remainder"),
    ("signed-mod", all_any, "(signed-mod X Y ... Z) the signed remainder"),
    ("lshift", all_any, "(lshift X Y ... Z) logical shift left"),
    ("rshift", all_any, "(rshift X Y ... Z) logical shift right"),
    ("arshift", all_any, "(arshift X Y ... Z) arithmetic shift right"),
    ("logand", all_any, "(logand X Y ... Z) bitwise and"),
    ("logor", all_any, "(logor X Y ... Z) bitwise or"),
    ("logxor", all_any, "(logxor X Y ... Z) bitwise exclusive or"),
    ("<.", all_any, "(<. X Y ... Z) floating-point strict increasing order"),
    ("forder", all_any, "(forder X Y ... Z) floating-point strict order"),
    ("=.", all_any, "(=. X Y ... Z) floating-point equality"),
    (">.", all_any, "(>. X Y ... Z) floating-point strict decreasing order"),
    ("<=.", all_any, "(<=. X Y ... Z) floating-point increasing order"),
    (">=.", all_any, "(>=. X Y ... Z) floating-point decreasing order"),
    ("is-finite", all_any, "(is-finite X ...) all values are finite"),
    ("is-nan", all_any, "(is-nan X ...) all values are NaN"),
    ("is-inf", all_any, "(is-inf X ...) all values are infinities"),
    ("is-fzero", all_any, "(is-fzero X ...) all values are zeros"),
    ("is-fpos", all_any, "(is-fpos X ...) all values are positive"),
    ("is-fneg", all_any, "(is-fneg X ...) all values are negative"),
    ("=", all_any, "(= X Y ... Z) all numbers are equal"),
    ("/=", all_any, "(/= X Y ... Z) all numbers are distinct"),
    ("<", all_any, "(< X Y ... Z) strictly increasing order"),
    (">", all_any, "(> X Y ... Z) strictly decreasing order"),
    ("<=", all_any, "(<= X Y ... Z) increasing order"),
    (">=", all_any, "(>= X Y ... Z) decreasing order"),
    ("s<", all_any, "(s< X Y ... Z) strictly increasing signed order"),
    ("s>", all_any, "(s> X Y ... Z) strictly decreasing signed order"),
    ("s<=", all_any, "(s<= X Y ... Z) increasing signed order"),
    ("s>=", all_any, "(s>= X Y ... Z) decreasing signed order"),
    ("is-zero", all_any, "(is-zero X Y ... Z) all numbers are zero"),
    ("not", all_any, "(not X Y ... Z) all numbers are zero"),
    ("is-positive", all_any, "(is-positive X ...) all numbers are positive"),
    ("is-negative", all_any, "(is-negative X ...) all numbers are negative"),
    ("word-width", all_any, "(word-width X ...) the maximum width"),
    ("exec-addr", one(int, any), "(exec-addr ADDR) transfers control to ADDR"),
    (
      "invoke-subroutine",
      one(sym, any),
      "(invoke-subroutine NAME) passes control to the subroutine NAME",
    ),
    (
      "goto-subinstruction",
      one(int, any),
      "(goto-subinstruction N) transfers control to a subinstruction",
    ),
    ("load-byte", one(int, byte), "(load-byte PTR) loads one byte"),
    ("memory-read", one(int, byte), "(memory-read PTR) loads one byte"),
    ("load-word", one(int, int), "(load-word PTR) loads one word"),
    (
      "load-bits",
      tuple([any, int], int),
      "(load-bits SIZE PTR) loads SIZE bits",
    ),
    ("load-hword", one(int, any), "(load-hword PTR) loads a half-word"),
    ("load-dword", one(int, any), "(load-dword PTR) loads a double-word"),
    ("load-qword", one(int, any), "(load-qword PTR) loads a quad-word"),
    ("store-byte", tuple([int, any], any), "(store-byte POS VAL) stores a byte"),
    ("store-word", tuple([int, any], any), "(store-word POS VAL) stores a word"),
    ("memory-write", tuple([int, byte], int), "(memory-write PTR X) stores X"),
    ("get-program-counter", tuple([], int), "(get-program-counter) the address"),
    (
      "get-current-program-counter",
      tuple([], int),
      "(get-current-program-counter) the address",
    ),
    ("set-symbol-value", tuple([any, a], a), "(set-symbol-value S X) S := X"),
    ("symbol", one(any, sym), "(symbol X) a symbol representation of X"),
    ("unquote", one(sym, any), "(unquote 'X) evaluates to X"),
    ("is-symbol", one(any, bool), "(is-symbol X) X has a symbolic value"),
    ("symbol-concat", arrow(All(sym), sym), "(symbol-concat S1 S2 ...)"),
    (
      "alias-base-register",
      one(int, int),
      "(alias-base-register X) the base register of an alias",
    ),
    ("cast-low", tuple([int, a], b), "(cast-low S X) low S bits of X"),
    ("cast-high", tuple([int, a], b), "(cast-high S X) high S bits of X"),
    ("cast-signed", tuple([int, a], b), "(cast-signed S X) signed extension"),
    ("cast-unsigned", tuple([int, a], b), "(cast-unsigned S X) extension"),
    ("cast-saturate", tuple([sym, int, a], b), "(cast-saturate T S X)"),
    ("extract", tuple([any, any, any], any), "(extract HI LO X)"),
    ("concat", all_any, "(concat X Y Z ...) concatenation"),
    ("select", all_any, "(select B1 ... BN X) selects bits of X"),
    ("nth", one(any, bool), "(nth N X) the N-th bit of X"),
    ("empty", tuple([], any), "(empty) a nop"),
    ("intrinsic", fop, "(intrinsic 'NAME ARG ... PARAMS ...) an intrinsic call"),
    ("fabs", tuple([any], any), "(fabs X) the absolute value"),
    ("fsqrt", tuple([sym, any], any), "(fsqrt M X) the square root"),
    ("fround", tuple([sym, any], any), "(fround M X) rounds X"),
    ("cast-float", tuple([sym, int, any], any), "(cast-float M S X)"),
    ("cast-sfloat", tuple([sym, int, any], any), "(cast-sfloat M S X)"),
    ("cast-int", tuple([sym, int, any], any), "(cast-int M S X)"),
    ("cast-sint", tuple([sym, int, any], any), "(cast-sint M S X)"),
  ]
}

///|
/// Adds the semantic primitives to the program (upstream `link_library`).
pub fn link_semantic_primitives(
  prog : Program,
  target : @core_theory.Target,
) -> Program {
  let bits = if target.bits() <= 0 { 32 } else { target.bits() }
  let mut prog = prog
  for spec in semantic_primitive_types(bits) {
    let (name, types, docs) = spec
    prog = prog.add(
      semantics,
      Def::new("core:" + name, docs~, { types, apply: { run: dispatch, }, }),
    )
  }
  prog
}

// ---------------------------------------------------------------------------
// Helpers

///|
fn static_int(name : String, x : SValue) -> Int raise SemanticsError {
  match x.static_value {
    Some(w) =>
      match word_to_int(w) {
        Some(n) => n
        None => raise illformed(name, "the value is too big")
      }
    None => raise illformed(name, "expects a staticly known value")
  }
}

///|
fn max_width(s : Int, xs : ArrayView[SValue]) -> Int {
  let mut r = 0
  for x in xs {
    r = @cmp.maximum(r, x.width)
  }
  if r == 0 {
    s
  } else {
    r
  }
}

///|
fn apply_binop(
  op : @types.BinOp,
  a : @types.Word,
  b : @types.Word,
) -> @types.Word? {
  match op.apply(a, b) {
    Ok(w) => Some(w)
    Err(_) => None
  }
}

///|
/// A monoid operation over the arguments (upstream `monoid`).
fn monoid(
  s0 : Int,
  first_width : Bool,
  op : @types.BinOp,
  init : Int,
  xs : Array[SValue],
) -> SValue {
  match xs {
    [] => const_int(s0, init)
    [x0, .. rest] => {
      let s = if first_width { x0.width } else { max_width(s0, xs) }
      let mut res = coerce(s, x0)
      for x in rest {
        let y = coerce(s, x)
        res = match (res.static_value, y.static_value) {
          (Some(a), Some(b)) =>
            match apply_binop(op, a, b) {
              Some(w) => const_word(w)
              None => dynv(BinOp(op, res.exp, y.exp), s)
            }
          _ => dynv(BinOp(op, res.exp, y.exp), s)
        }
      }
      res
    }
  }
}

///|
fn compare_values(
  cmp : (SValue, SValue) -> SValue,
  xs : Array[SValue],
) -> SValue {
  let mut r = const_bool(true)
  for i in 1..<xs.length() {
    r = and_bool(r, cmp(xs[i - 1], xs[i]))
  }
  r
}

///|
fn binary_cmp(op : @types.BinOp, swap : Bool) -> (SValue, SValue) -> SValue {
  (x, y) => {
    let (x, y) = if swap { (y, x) } else { (x, y) }
    let s = @cmp.maximum(x.width, y.width)
    let signed = op is (SignedLt | SignedLe)
    let x = if signed { coerce(s, x) } else { coerce_unsigned(s, x) }
    let y = if signed { coerce(s, y) } else { coerce_unsigned(s, y) }
    match (x.static_value, y.static_value) {
      (Some(a), Some(b)) =>
        match apply_binop(op, a, b) {
          Some(w) => const_bool(!w.is_zero())
          None => dynv(BinOp(op, x.exp, y.exp), 1)
        }
      _ => dynv(BinOp(op, x.exp, y.exp), 1)
    }
  }
}

///|
fn all_values(f : (SValue) -> SValue, xs : Array[SValue]) -> SValue {
  let mut r = const_bool(true)
  for x in xs {
    r = and_bool(r, f(x))
  }
  r
}

///|
fn is_zero_value(x : SValue) -> SValue {
  match x.static_value {
    Some(w) => const_bool(w.is_zero())
    None => dynv(BinOp(Eq, x.exp, Int(word_zero(x.width))), 1)
  }
}

///|
fn msb_value(x : SValue) -> SValue {
  match x.static_value {
    Some(w) => const_bool(w.msb())
    None => dynv(Extract(hi=x.width - 1, lo=x.width - 1, exp=x.exp), 1)
  }
}

///|
fn not_value(x : SValue) -> SValue {
  match x.static_value {
    Some(w) => const_bool(w.is_zero())
    None => dynv(UnOp(Not, x.exp), 1)
  }
}

///|
fn SemCtx::endian(self : SemCtx) -> @bitvec.Endian {
  match self.target.endianness() {
    BigEndian => BigEndian
    _ => LittleEndian
  }
}

///|
fn SemCtx::addr(self : SemCtx, x : SValue) -> @types.Exp {
  let w = match self.lifter.mem.typ {
    Mem(addr_width~, ..) => addr_width
    Imm(n) => n
  }
  coerce_unsigned(w, x).exp
}

///|
fn SemCtx::load(self : SemCtx, bits : Int, p : SValue) -> SValue {
  dynv(
    Load(
      mem=Var(self.lifter.mem),
      addr=self.addr(p),
      endian=self.endian(),
      typ=Imm(bits),
    ),
    bits,
  )
}

///|
fn SemCtx::store(self : SemCtx, p : SValue, x : SValue) -> SEff {
  let mem = self.lifter.mem
  {
    stmts: [
      Move(
        mem,
        Store(
          mem=Var(mem),
          addr=self.addr(p),
          value=x.exp,
          endian=self.endian(),
        ),
      ),
    ],
    value: nil_value(),
  }
}

///|
fn SemCtx::possibly_register(
  self : SemCtx,
  name : String,
  x : SValue,
) -> @types.Var raise SemanticsError {
  match x.symbol {
    None => raise illformed(name, "not a symbolic value")
    Some(v) =>
      match find_target_var(self.target, v) {
        Some(r) => r
        None => @types.Var::create(v, Imm(self.word()))
      }
  }
}

///|
fn make_symbol(s : String) -> SValue {
  sym_value(s)
}

///|
fn mk_cast(
  name : String,
  kind : @types.CastKind,
  xs : Array[SValue],
) -> SValue raise SemanticsError {
  guard xs is [sz, x] else {
    raise illformed(name, "requires exactly two arguments")
  }
  let r = static_int(name, sz)
  if r <= 0 {
    raise illformed(name, "the size must be positive")
  }
  match x.static_value {
    Some(w) =>
      match kind.apply(r, w) {
        Ok(v) => const_word(v)
        Err(e) => raise illformed(name, e)
      }
    None =>
      if r == x.width && kind is (Signed | Unsigned | Low) {
        // the value of a register, not the register: a symbol would be
        // reified into a constant by `call_primitive`
        { ..x, symbol: None, }
      } else {
        dynv(Cast(kind~, width=r, exp=x.exp), r)
      }
  }
}

///|
fn saturate_max(bits : Int, signed : Bool) -> @bigint.BigInt {
  let m = 1N << bits
  if signed {
    (m >> 1) - 1N
  } else {
    m - 1N
  }
}

///|
fn bigint_of_word(w : @types.Word) -> @bigint.BigInt {
  @bigint.BigInt::from_string(w.to_hex(prefix=false), radix=16)
}

///|
fn signed_bigint_of_word(w : @types.Word) -> @bigint.BigInt {
  let v = bigint_of_word(w)
  if w.msb() {
    v - (1N << w.bitwidth())
  } else {
    v
  }
}

///|
fn saturate(xs : Array[SValue]) -> SValue raise SemanticsError {
  guard xs is [t, sz, x] else {
    raise illformed("cast-saturate", "requires exactly three arguments")
  }
  let signed = match t.symbol {
    Some(":signed") => true
    Some(":unsigned") => false
    _ => raise illformed("cast-saturate", "expected :signed or :unsigned")
  }
  let ds = static_int("cast-saturate", sz)
  match x.static_value {
    Some(w) => {
      let v = if signed { signed_bigint_of_word(w) } else { bigint_of_word(w) }
      let hi = saturate_max(ds, signed)
      let lo = if signed { -(hi + 1N) } else { 0N }
      let r = if v > hi { hi } else if v < lo { lo } else { v }
      const_word(word_of_bigint(r, ds))
    }
    None => {
      let ss = x.width
      // lower bits if all upper bits are equal to the sign (or zero),
      // otherwise the saturated bound
      let hi = saturate_max(ds, signed)
      let upper = const_word(word_of_bigint(hi, ss))
      let msb = dynv(Extract(hi=ss - 1, lo=ss - 1, exp=x.exp), 1)
      let bound = dynv(
        BinOp(Plus, upper.exp, Cast(kind=Unsigned, width=ss, exp=msb.exp)),
        ss,
      )
      let shift = if signed { ds - 1 } else { ds }
      let ubits : @types.Exp = BinOp(
        if signed {
          ARShift
        } else {
          RShift
        },
        x.exp,
        Int(word_of_bigint(@bigint.BigInt::from_int(shift), ss)),
      )
      let zero : @types.Exp = Int(word_zero(ss))
      let cnd : @types.Exp = if signed {
        BinOp(Or, BinOp(Eq, ubits, zero), BinOp(Eq, UnOp(Not, ubits), zero))
      } else {
        BinOp(Eq, ubits, zero)
      }
      dynv(
        Cast(kind=Low, width=ds, exp=Ite(cond=cnd, yes=x.exp, no=bound.exp)),
        ds,
      )
    }
  }
}

///|
fn extract_prim(xs : Array[SValue]) -> SValue raise SemanticsError {
  guard xs is [hi, lo, x] else {
    raise illformed("extract", "requires exactly three arguments")
  }
  let hi = static_int("extract", hi)
  let lo = static_int("extract", lo)
  if hi < lo {
    raise illformed("extract", "high must be no less than low")
  }
  match x.static_value {
    Some(w) => {
      let v = (bigint_of_word(w) >> lo) % (1N << (hi - lo + 1))
      const_word(word_of_bigint(v, hi - lo + 1))
    }
    None => dynv(Extract(hi~, lo~, exp=x.exp), hi - lo + 1)
  }
}

///|
fn concat_prim(xs : Array[SValue]) -> SValue {
  match xs {
    [] => const_int(1, 0)
    [x0, .. rest] => {
      let mut r = x0
      for y in rest {
        let w = r.width + y.width
        r = match (r.static_value, y.static_value) {
          (Some(a), Some(b)) =>
            const_word(
              word_of_bigint(
                (bigint_of_word(a) << y.width) + bigint_of_word(b),
                w,
              ),
            )
          _ => dynv(Concat(high=r.exp, low=y.exp), w)
        }
      }
      r
    }
  }
}

///|
fn select_prim(s : Int, xs : Array[SValue]) -> SValue raise SemanticsError {
  match xs {
    [] => const_int(s, 0)
    _ => {
      let x = xs[xs.length() - 1]
      let bs = []
      for i in 0..<(xs.length() - 1) {
        bs.push(static_int("select", xs[i]))
      }
      if bs.is_empty() {
        return const_int(s, 0)
      }
      let bits = bs.map(b => dynv(Extract(hi=b, lo=b, exp=x.exp), 1))
      match x.static_value {
        Some(w) => {
          let v = bigint_of_word(w)
          let bits = bs.map(b => const_word(word_of_bigint((v >> b) % 2N, 1)))
          concat_prim(bits)
        }
        None => concat_prim(bits)
      }
    }
  }
}

///|
fn distinct_prim(xs : Array[SValue]) -> SValue {
  let mut r = const_bool(true)
  for i in 0..<xs.length() {
    for j in (i + 1)..<xs.length() {
      r = and_bool(r, binary_cmp(Neq, false)(xs[i], xs[j]))
    }
  }
  r
}

// ---------------------------------------------------------------------------
// Floating-point operations are compiled to intrinsic calls named as the
// BIL intrinsics of the Core Theory floating-point operations, e.g.,
// `intrinsic:fadd_rne_ieee754_binary64`, with the inputs passed in
// `intrinsic:x0`, ... and the result in `intrinsic:y0`. Static 64-bit
// operands are folded.

///|
fn double_of_word(w : @types.Word) -> Double {
  let v = resize(w, 64)
  (try! v.to_int64()).reinterpret_as_double()
}

///|
fn word_of_double(x : Double, s : Int) -> @types.Word {
  let bits = x.reinterpret_as_int64()
  resize(try! @types.Word::of_int64(bits, width=64), s)
}

///|
fn rmode_name(name : String, x : SValue) -> String raise SemanticsError {
  match x.symbol {
    Some(k) =>
      match k {
        ":rne" | ":rna" | ":rtp" | ":rtn" | ":rtz" =>
          k.unsafe_substring(start=1, end=k.length())
        _ => raise illformed(name, "unrecognized rounding mode: \{k}")
      }
    None => raise illformed(name, "requires the floating-point rounding mode")
  }
}

///|
fn intrinsic_var(d : Char, i : Int, s : Int) -> @types.Var {
  @types.Var::create("intrinsic:\{d}\{i}", Imm(@cmp.maximum(1, s)))
}

///|
fn float_intrinsic(name : String, args : Array[SValue], ret : Int) -> SEff {
  let stmts : Array[@types.Stmt] = []
  for i, x in args {
    stmts.push(Move(intrinsic_var('x', i, x.width), x.exp))
  }
  stmts.push(@types.Stmt::encode(@types.Stmt::intrinsic(), "intrinsic:" + name))
  { stmts, value: dynv(Var(intrinsic_var('y', 0, ret)), ret), }
}

///|
fn float_monoid(
  name : String,
  opname : String,
  host : (Double, Double) -> Double,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  guard xs is [m, .. xs] else {
    raise illformed(name, "requires the rounding mode")
  }
  let mode = rmode_name(name, m)
  let xs = xs.to_owned()
  let s = max_width(64, xs)
  match xs {
    [] =>
      pure(
        const_word(
          word_of_double(
            if opname == "fadd" || opname == "fsub" {
              0.0
            } else {
              1.0
            },
            s,
          ),
        ),
      )
    [x0, .. rest] => {
      let stmts = []
      let mut r = coerce(s, x0)
      for y in rest {
        let y = coerce(s, y)
        match (r.static_value, y.static_value) {
          (Some(a), Some(b)) if s == 64 =>
            r = const_word(
              word_of_double(host(double_of_word(a), double_of_word(b)), s),
            )
          _ => {
            let e = float_intrinsic(
              "\{opname}_\{mode}_ieee754_binary\{s}",
              [r, y],
              s,
            )
            stmts.append(e.stmts)
            let t = fresh_var(s)
            stmts.push(Move(t, e.value.exp))
            r = dynv(Var(t), s)
          }
        }
      }
      { stmts, value: r, }
    }
  }
}

///|
fn float_order(
  name : String,
  host : (Double, Double) -> Bool,
  xs : Array[SValue],
) -> SEff {
  let stmts = []
  let mut r = const_bool(true)
  for i in 1..<xs.length() {
    let x = xs[i - 1]
    let y = xs[i]
    match (x.static_value, y.static_value) {
      (Some(a), Some(b)) if x.width == 64 && y.width == 64 =>
        r = and_bool(r, const_bool(host(double_of_word(a), double_of_word(b))))
      _ => {
        let e = float_intrinsic("\{name}_ieee754_binary\{x.width}", [x, y], 1)
        stmts.append(e.stmts)
        let t = fresh_var(1)
        stmts.push(Move(t, e.value.exp))
        r = and_bool(r, dynv(Var(t), 1))
      }
    }
  }
  { stmts, value: r, }
}

///|
fn float_class(name : String, xs : Array[SValue]) -> SEff {
  let stmts = []
  let mut r = const_bool(true)
  for x in xs {
    let e = float_intrinsic("\{name}_ieee754_binary\{x.width}", [x], 1)
    stmts.append(e.stmts)
    let t = fresh_var(1)
    stmts.push(Move(t, e.value.exp))
    r = and_bool(r, dynv(Var(t), 1))
  }
  { stmts, value: r, }
}

///|
fn float_unary(
  name : String,
  prefix : String,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  match xs {
    [x] => float_intrinsic("\{prefix}_ieee754_binary\{x.width}", [x], x.width)
    [m, x] => {
      let mode = rmode_name(name, m)
      float_intrinsic(
        "\{prefix}_\{mode}_ieee754_binary\{x.width}",
        [x],
        x.width,
      )
    }
    _ => raise illformed(name, "requires a mode and a single operand")
  }
}

///|
fn float_cast(name : String, xs : Array[SValue]) -> SEff raise SemanticsError {
  guard xs is [m, sz, x] else {
    raise illformed(name, "requires rmode and two operands")
  }
  let mode = rmode_name(name, m)
  let s = static_int(name, sz)
  let prefix = match name {
    "cast-float" => "cast_float"
    "cast-sfloat" => "cast_sfloat"
    "cast-int" => "cast_int"
    _ => "cast_sint"
  }
  float_intrinsic("\{prefix}_\{mode}_ieee754_binary\{s}", [x], s)
}

// ---------------------------------------------------------------------------
// Intrinsics

///|
fn intrinsic_call(
  ctx : SemCtx,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  guard xs is [dst, .. args] else {
    raise illformed("intrinsic", "requires the name of the intrinsic")
  }
  let name = match dst.symbol {
    Some(n) => @knowledge.Name::read(n).unqualified()
    None => raise illformed("intrinsic", "not a symbolic value")
  }
  // parse parameters
  let inputs = []
  let results : Array[Array[SValue]] = []
  let writes : Array[Array[SValue]] = []
  let stores : Array[Array[SValue]] = []
  let mut current : Array[SValue] = inputs
  let mut group = 0
  let flush = (g : Int, c : Array[SValue]) => {
    match g {
      1 => results.push(c)
      2 => writes.push(c)
      3 => stores.push(c)
      _ => ()
    }
  }
  for v in args {
    let kw = match v.symbol {
      Some(":result") => 1
      Some(":writes") => 2
      Some(":stores") => 3
      Some(":aborts") => 4
      _ => 0
    }
    if kw > 0 {
      if group > 0 {
        flush(group, current)
      }
      group = kw
      current = []
    } else {
      current.push(v)
    }
  }
  if group > 0 {
    flush(group, current)
  }
  let stmts : Array[@types.Stmt] = []
  for i, x in inputs {
    stmts.push(Move(intrinsic_var('x', i, x.width), x.exp))
  }
  stmts.push(@types.Stmt::encode(@types.Stmt::intrinsic(), "intrinsic:" + name))
  let base = results.length()
  for i, w in writes {
    match w {
      [reg] => {
        let v = ctx.possibly_register("intrinsic", reg)
        let s = var_width(v)
        stmts.push(Move(v, Var(intrinsic_var('y', base + i, s))))
      }
      [reg, typ] => {
        let s = static_int("intrinsic", typ)
        guard reg.symbol is Some(r) else {
          raise illformed("intrinsic", "not a symbolic value")
        }
        let v = @types.Var::create(r, Imm(s))
        stmts.push(Move(v, Var(intrinsic_var('y', base + i, s))))
      }
      _ => raise illformed("intrinsic", "incorrect :writes parameters")
    }
  }
  let base = base + writes.length()
  for i, st in stores {
    let (ptr, s) = match st {
      [ptr] => (ptr, ctx.target.data_addr_size())
      [ptr, typ] => (ptr, static_int("intrinsic", typ))
      _ => raise illformed("intrinsic", "incorrect :stores parameters")
    }
    let y = dynv(Var(intrinsic_var('y', base + i, s)), s)
    stmts.append(ctx.store(ptr, y).stmts)
  }
  match results {
    [] => { stmts, value: nil_value(), }
    [[t]] => {
      let s = static_int("intrinsic", t)
      { stmts, value: dynv(Var(intrinsic_var('y', 0, s)), s), }
    }
    _ =>
      raise illformed(
        "intrinsic", ":result may occur once and with a single argument",
      )
  }
}

// ---------------------------------------------------------------------------
// The dispatcher

///|
fn ctrl(s : @types.Stmt) -> SEff {
  { stmts: [s], value: nil_value(), }
}

///|
fn dispatch(
  ctx : SemCtx,
  name : String,
  args : Array[SValue],
) -> SEff raise SemanticsError {
  let s = ctx.word()
  match (name, args) {
    ("+", _) => pure(monoid(s, false, Plus, 0, args))
    ("-" | "neg", [x]) =>
      pure(
        match x.static_value {
          Some(w) => const_word(w.neg())
          None => dynv(UnOp(Neg, x.exp), x.width)
        },
      )
    ("-", _) => pure(monoid(s, false, Minus, 0, args))
    ("*", _) => pure(monoid(s, false, Times, 1, args))
    ("/", [x]) =>
      pure(monoid(s, false, Div, 1, [coerce(x.width, const_int(s, 1)), x]))
    ("/", _) => pure(monoid(s, false, Div, 1, args))
    ("s/", [x]) =>
      pure(
        monoid(s, false, SignedDiv, 1, [coerce(x.width, const_int(s, 1)), x]),
      )
    ("s/", _) => pure(monoid(s, false, SignedDiv, 1, args))
    ("mod", _) => pure(monoid(s, false, Mod, 1, args))
    ("signed-mod", _) => pure(monoid(s, false, SignedMod, 1, args))
    ("lnot", [x]) =>
      pure(
        match x.static_value {
          Some(w) => const_word(w.lnot())
          None => dynv(UnOp(Not, x.exp), x.width)
        },
      )
    ("lshift", _) => pure(monoid(s, true, LShift, 1, args))
    ("rshift", _) => pure(monoid(s, true, RShift, 1, args))
    ("arshift", _) => pure(monoid(s, true, ARShift, 1, args))
    ("logand", _) => pure(monoid(s, false, And, 1, args))
    ("logor", _) => pure(monoid(s, false, Or, 0, args))
    ("logxor", _) => pure(monoid(s, false, Xor, 0, args))
    ("+.", _) => float_monoid(name, "fadd", (a, b) => a + b, args)
    ("-.", _) => float_monoid(name, "fsub", (a, b) => a - b, args)
    ("*.", _) => float_monoid(name, "fmul", (a, b) => a * b, args)
    ("/.", _) => float_monoid(name, "fdiv", (a, b) => a / b, args)
    ("fabs", _) => float_unary(name, "fabs", args)
    ("fsqrt", _) => float_unary(name, "fsqrt", args)
    ("fround", _) => float_unary(name, "fround", args)
    ("cast-float" | "cast-sfloat" | "cast-int" | "cast-sint", _) =>
      float_cast(name, args)
    ("<." | "forder", _) => float_order("forder", (a, b) => a < b, args)
    ("<=.", _) => float_order("fle", (a, b) => a <= b, args)
    (">.", _) => float_order("fgt", (a, b) => a > b, args)
    (">=.", _) => float_order("fge", (a, b) => a >= b, args)
    ("=.", _) => float_order("feq", (a, b) => a == b, args)
    ("is-finite", _) => float_class("is_finite", args)
    ("is-nan", _) => float_class("is_nan", args)
    ("is-inf", _) => float_class("is_inf", args)
    ("is-fzero", _) => float_class("is_fzero", args)
    ("is-fpos", _) => float_class("is_fpos", args)
    ("is-fneg", _) => float_class("is_fneg", args)
    ("=", _) => pure(compare_values(binary_cmp(Eq, false), args))
    ("<", _) => pure(compare_values(binary_cmp(Lt, false), args))
    (">", _) => pure(compare_values(binary_cmp(Lt, true), args))
    ("<=", _) => pure(compare_values(binary_cmp(Le, false), args))
    (">=", _) => pure(compare_values(binary_cmp(Le, true), args))
    ("s<", _) => pure(compare_values(binary_cmp(SignedLt, false), args))
    ("s>", _) => pure(compare_values(binary_cmp(SignedLt, true), args))
    ("s<=", _) => pure(compare_values(binary_cmp(SignedLe, false), args))
    ("s>=", _) => pure(compare_values(binary_cmp(SignedLe, true), args))
    ("/=" | "distinct", _) => pure(distinct_prim(args))
    ("is-zero" | "not", _) => pure(all_values(is_zero_value, args))
    ("is-positive", _) =>
      pure(
        all_values(
          x => and_bool(not_value(is_zero_value(x)), not_value(msb_value(x))),
          args,
        ),
      )
    ("is-negative", _) => pure(all_values(msb_value, args))
    ("word-width", _) => pure(const_int(s, max_width(s, args)))
    ("exec-addr", [dst]) =>
      ctrl(
        match dst.static_value {
          Some(w) => Jmp(Int(w))
          None => Jmp(dst.exp)
        },
      )
    ("goto-subinstruction", [n]) =>
      ctrl(
        @types.Stmt::encode(
          @types.Stmt::goto(),
          "subinstruction:\{static_int(name, n)}",
        ),
      )
    ("load-byte" | "memory-read", [p]) => pure(ctx.load(8, p))
    ("load-word", [p]) => pure(ctx.load(s, p))
    ("load-hword", [p]) => pure(ctx.load(s / 2, p))
    ("load-dword", [p]) => pure(ctx.load(s * 2, p))
    ("load-qword", [p]) => pure(ctx.load(s * 4, p))
    ("load-bits", [sz, p]) => pure(ctx.load(static_int(name, sz), p))
    ("store-byte" | "memory-write", [p, x]) =>
      ctx.store(p, coerce_unsigned(8, x))
    ("store-word", [p, x]) => ctx.store(p, x)
    ("get-program-counter" | "get-current-program-counter", []) =>
      pure(
        match ctx.pc {
          Some(w) => const_word(resize(w, s))
          None => dynv(Unknown("program-counter", Imm(s)), s)
        },
      )
    ("set-symbol-value", [sym, _]) if sym.symbol is Some(r) &&
      is_zero_register(ctx.target, r) =>
      // writes to a hardwired zero register are discarded (see
      // `Lifter::operand`)
      pure(args[1])
    ("set-symbol-value", [sym, x]) => {
      let v = ctx.possibly_register(name, sym)
      let w = var_width(v)
      ctx.binds.remove(v.name)
      let e = if w > 0 && w != x.width {
        coerce_unsigned(w, x).exp
      } else {
        x.exp
      }
      { stmts: [Move(v, e)], value: x, }
    }
    ("symbol-concat", syms) => {
      let names = []
      for x in syms {
        match x.symbol {
          Some(n) => names.push(n)
          None => raise illformed(name, "require all symbols")
        }
      }
      let (parts, sep) = match names.search(":sep") {
        None => (names, "")
        Some(i) =>
          if i == names.length() - 2 {
            (names[:i].to_owned(), names[i + 1])
          } else {
            raise illformed(
              name, ":sep must be last and followed by an argument",
            )
          }
      }
      pure(make_symbol(parts.join(sep)))
    }
    ("symbol", [x]) =>
      match x.symbol {
        Some(n) => pure(make_symbol(n))
        None => raise illformed(name, "symbol requires a symbolic value")
      }
    ("unquote", [x]) => {
      let v = ctx.possibly_register(name, x)
      let w = var_width(v)
      pure({ ..dynv(Var(v), if w == 0 { s } else { w }), symbol: x.symbol, })
    }
    ("is-symbol", [x]) => pure(const_bool(x.symbol is Some(_)))
    ("alias-base-register", [x]) => {
      let r = ctx.possibly_register(name, x)
      let origin = ctx.target.origin_of_name(r.name)
      match origin {
        Some(SubRegister(source~, ..)) =>
          match bil_var_of_theory(source) {
            Some(v) =>
              pure({ ..dynv(Var(v), var_width(v)), symbol: Some(v.name), })
            None => raise illformed(name, "the register is not a bitvector")
          }
        _ =>
          raise illformed(
            name,
            "the register \{r.name} is not a subregister alias",
          )
      }
    }
    ("cast-low", xs) => pure(mk_cast(name, Low, xs))
    ("cast-high", xs) => pure(mk_cast(name, High, xs))
    ("cast-signed", xs) => pure(mk_cast(name, Signed, xs))
    ("cast-unsigned", xs) => pure(mk_cast(name, Unsigned, xs))
    ("cast-saturate", xs) => pure(saturate(xs))
    ("extract", xs) => pure(extract_prim(xs))
    ("concat", xs) => pure(concat_prim(xs))
    ("select" | "nth", xs) => pure(select_prim(s, xs))
    ("empty", []) => { stmts: [], value: nil_value(), }
    ("intrinsic", _) => intrinsic_call(ctx, args)
    ("invoke-subroutine", [dst, ..]) =>
      match dst.symbol {
        Some(n) => ctrl(@types.Stmt::encode(@types.Stmt::call(), n))
        None => raise illformed(name, "not a symbolic value")
      }
    _ => raise illformed(name, "unsupported arguments (\{args.length()} given)")
  }
}
