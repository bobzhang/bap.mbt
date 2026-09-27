///|
/// The semantic actions for bitvector expressions (`Grammar.Bitv`),
/// applied to the sub-terms `E` of the parsed language (`R` are rounding
/// modes). Actions are fields: call them as `(g.add)(x, y)`.
pub(all) struct BitvGrammar[E, R] {
  error : Pure
  unsigned : (Int, E) -> Pure
  signed : (Int, E) -> Pure
  high : (Int, E) -> Pure
  low : (Int, E) -> Pure
  cast : (Int, E, E) -> Pure
  extract : (Int, E, E, E) -> Pure
  add : (E, E) -> Pure
  sub : (E, E) -> Pure
  mul : (E, E) -> Pure
  div : (E, E) -> Pure
  sdiv : (E, E) -> Pure
  modulo : (E, E) -> Pure
  smodulo : (E, E) -> Pure
  lshift : (E, E) -> Pure
  rshift : (E, E) -> Pure
  arshift : (E, E) -> Pure
  logand : (E, E) -> Pure
  logor : (E, E) -> Pure
  logxor : (E, E) -> Pure
  neg : (E) -> Pure
  not : (E) -> Pure
  /// `load_word size dir mem key` (big endian if `dir` holds)
  load_word : (Int, E, E, E) -> Pure
  load : (E, E) -> Pure
  /// `var name size`
  var_ : (String, Int) -> Pure
  /// `int word size`
  int : (@bitvec.BitVec, Int) -> Pure
  unknown : (Int) -> Pure
  ite : (E, E, E) -> Pure
  let_bit : (String, E, E) -> Pure
  let_reg : (String, E, E) -> Pure
  let_mem : (String, E, E) -> Pure
  let_float : (String, E, E) -> Pure
  append : (E, E) -> Pure
  concat : (Array[E]) -> Pure
  cast_int : (Int, R, E) -> Pure
  cast_sint : (Int, R, E) -> Pure
  fbits : (E) -> Pure
}

///|
/// The semantic actions for boolean expressions (`Grammar.Bool`).
pub(all) struct BoolGrammar[E] {
  error : Pure
  eq : (E, E) -> Pure
  neq : (E, E) -> Pure
  lt : (E, E) -> Pure
  le : (E, E) -> Pure
  slt : (E, E) -> Pure
  sle : (E, E) -> Pure
  var_ : (String) -> Pure
  int : (@bitvec.BitVec) -> Pure
  unknown : () -> Pure
  ite : (E, E, E) -> Pure
  let_bit : (String, E, E) -> Pure
  let_reg : (String, E, E) -> Pure
  let_mem : (String, E, E) -> Pure
  let_float : (String, E, E) -> Pure
  high : (E) -> Pure
  low : (E) -> Pure
  /// `extract n x`: the `n`-th bit of `x`
  extract : (Int, E) -> Pure
  not : (E) -> Pure
  logand : (E, E) -> Pure
  logor : (E, E) -> Pure
  logxor : (E, E) -> Pure
  is_inf : (E) -> Pure
  is_nan : (E) -> Pure
  is_fzero : (E) -> Pure
  is_fpos : (E) -> Pure
  is_fneg : (E) -> Pure
  fle : (E, E) -> Pure
  flt : (E, E) -> Pure
  feq : (E, E) -> Pure
}

///|
/// The semantic actions for memory expressions (`Grammar.Mem`).
pub(all) struct MemGrammar[E] {
  error : Pure
  /// `store mem key data`
  store : (E, E, E) -> Pure
  /// `store_word dir mem key data`
  store_word : (E, E, E, E) -> Pure
  /// `var name key_size value_size`
  var_ : (String, Int, Int) -> Pure
  unknown : (Int, Int) -> Pure
  ite : (E, E, E) -> Pure
  let_bit : (String, E, E) -> Pure
  let_reg : (String, E, E) -> Pure
  let_mem : (String, E, E) -> Pure
  let_float : (String, E, E) -> Pure
}

///|
/// The semantic actions for floating-point expressions (`Grammar.Float`).
pub(all) struct FloatGrammar[E, R] {
  error : Pure
  ieee754 : (Ieee754Parameters, E) -> Pure
  ieee754_var : (Ieee754Parameters, String) -> Pure
  ieee754_unk : (Ieee754Parameters) -> Pure
  ieee754_cast : (Ieee754Parameters, R, E) -> Pure
  ieee754_cast_signed : (Ieee754Parameters, R, E) -> Pure
  ieee754_convert : (Ieee754Parameters, R, E) -> Pure
  ite : (E, E, E) -> Pure
  fadd : (R, E, E) -> Pure
  fsub : (R, E, E) -> Pure
  fmul : (R, E, E) -> Pure
  fdiv : (R, E, E) -> Pure
  frem : (R, E, E) -> Pure
  fmin : (E, E) -> Pure
  fmax : (E, E) -> Pure
  fabs : (E) -> Pure
  fneg : (E) -> Pure
  fsqrt : (R, E) -> Pure
  fround : (R, E) -> Pure
  let_bit : (String, E, E) -> Pure
  let_reg : (String, E, E) -> Pure
  let_mem : (String, E, E) -> Pure
  let_float : (String, E, E) -> Pure
}

///|
/// The semantic actions for rounding modes (`Grammar.Rmode`).
pub(all) struct RmodeGrammar {
  error : Pure
  rne : Pure
  rtz : Pure
  rtp : Pure
  rtn : Pure
  rna : Pure
}

///|
/// The semantic actions for statements (`Grammar.Stmt`); `S` are the
/// statements of the parsed language.
pub(all) struct StmtGrammar[E, R, S] {
  error : Eff
  /// `set_mem name key_size value_size x`
  set_mem : (String, Int, Int, E) -> Eff
  /// `set_reg name size x`
  set_reg : (String, Int, E) -> Eff
  set_bit : (String, E) -> Eff
  set_ieee754 : (String, Ieee754Parameters, E) -> Eff
  set_rmode : (String, R) -> Eff
  /// `tmp_* name x`: binds a fresh temporary to `x` in the rest of the
  /// statements, where it is referenced as `name`
  tmp_mem : (String, E) -> Eff
  tmp_reg : (String, E) -> Eff
  tmp_bit : (String, E) -> Eff
  tmp_float : (String, E) -> Eff
  tmp_rmode : (String, R) -> Eff
  /// `let_* name x body`: binds `name` to `x` in the statement `body`
  let_mem : (String, E, S) -> Eff
  let_reg : (String, E, S) -> Eff
  let_bit : (String, E, S) -> Eff
  let_float : (String, E, S) -> Eff
  let_rmode : (String, R, S) -> Eff
  jmp : (E) -> Eff
  /// `goto addr`
  goto : (@bitvec.BitVec) -> Eff
  call : (String) -> Eff
  special : (String) -> Eff
  cpuexn : (Int) -> Eff
  while_ : (E, Array[S]) -> Eff
  if_ : (E, Array[S], Array[S]) -> Eff
  seq : (Array[S]) -> Eff
}

///|
/// `Theory.Parser.t`: a parser of a language with expressions `E`,
/// rounding modes `R` and statements `S` into Core Theory terms.
///
/// Each field dispatches one syntactic category of the language: it
/// inspects a term and applies the matching semantic action of the
/// grammar (e.g., `bitv=(g, e) => match e { Plus(x, y) => (g.add)(x, y)
/// ... }`). Sub-terms are passed back to the actions unparsed, and the
/// parser (`Core::parse`) recursively parses them in the right category
/// and scope. Upstream the grammars are first-class modules and the
/// parser is polymorphic in their result; here the results are Core
/// Theory terms (`Pure`/`Eff`).
pub(all) struct Parser[E, R, S] {
  bitv : (BitvGrammar[E, R], E) -> Pure
  bool : (BoolGrammar[E], E) -> Pure
  mem : (MemGrammar[E], E) -> Pure
  stmt : (StmtGrammar[E, R, S], S) -> Eff
  float : (FloatGrammar[E, R], E) -> Pure
  rmode : (RmodeGrammar, R) -> Pure
}

///|
/// The error of ill-formed terms (upstream `Parser.Error`).
let parser_error : Pure = _ => {
  raise @knowledge.Failure("Theory.Parser: ill-formed term")
}

///|
let parser_eff_error : Eff = _ => {
  raise @knowledge.Failure("Theory.Parser: ill-formed statement")
}

///|
/// The scope of the parser: the names bound by `let`/`tmp` constructs.
priv struct ParserEnv[E, R, S] {
  ct : Core
  ctxt : @list.List[(String, Var)]
  parser : Parser[E, R, S]
}

///|
fn[E, R, S] ParserEnv::bind(
  self : ParserEnv[E, R, S],
  name : String,
  v : Var,
) -> ParserEnv[E, R, S] {
  { ..self, ctxt: self.ctxt.add((name, v)), }
}

///|
/// `mkvar sort name` with `rename`: the variable named `name` (a bound
/// variable if `name` is in scope).
fn[E, R, S] ParserEnv::var_(
  self : ParserEnv[E, R, S],
  sort : Sort,
  name : String,
) -> Var {
  for entry in self.ctxt {
    if entry.0 == name {
      return entry.1.resort(sort)
    }
  }
  parser_mkvar(sort, name)
}

///|
fn parser_mkvar(sort : Sort, name : String) -> Var {
  match Var::of_ident(sort, name) {
    Ok(v) => v
    Err(_) => Var::create(sort, name)
  }
}

///|
fn[E, R, S] ParserEnv::expw(self : ParserEnv[E, R, S], e : E) -> Pure {
  (self.parser.bitv)(self.bitv_grammar(), e)
}

///|
fn[E, R, S] ParserEnv::expb(self : ParserEnv[E, R, S], e : E) -> Pure {
  (self.parser.bool)(self.bool_grammar(), e)
}

///|
fn[E, R, S] ParserEnv::expm(self : ParserEnv[E, R, S], e : E) -> Pure {
  (self.parser.mem)(self.mem_grammar(), e)
}

///|
fn[E, R, S] ParserEnv::expf(self : ParserEnv[E, R, S], e : E) -> Pure {
  (self.parser.float)(self.float_grammar(), e)
}

///|
fn[E, R, S] ParserEnv::expr(self : ParserEnv[E, R, S], r : R) -> Pure {
  let ct = self.ct
  (self.parser.rmode)(
    {
      error: parser_error,
      rne: ct.rne(),
      rtz: ct.rtz(),
      rtp: ct.rtp(),
      rtn: ct.rtn(),
      rna: ct.rna(),
    },
    r,
  )
}

///|
/// `let_* v x y`: binds `v` to the value of `x` (parsed with `parse_x`)
/// in `y` (parsed with `parse_y` in the extended scope).
fn[E, R, S] ParserEnv::let_gen(
  self : ParserEnv[E, R, S],
  parse_x : (ParserEnv[E, R, S], E) -> Pure,
  parse_y : (ParserEnv[E, R, S], E) -> Pure,
) -> (String, E, E) -> Pure {
  (name, x, y) => {
    state => {
      let x = parse_x(self, x)(state)
      Var::scoped_pure(x.sort(), r => {
        self.ct.let_(r, pure_const(x), parse_y(self.bind(name, r), y))
      })(state)
    }
  }
}

///|
fn parser_join_sizes(x : Sort, y : Sort) -> Sort {
  Sort::bitv(sort_size(x) + sort_size(y))
}

///|
fn[E, R, S] ParserEnv::bitv_grammar(
  self : ParserEnv[E, R, S],
) -> BitvGrammar[E, R] {
  let ct = self.ct
  let expw = x => self.expw(x)
  let run : (ParserEnv[E, R, S], E) -> Pure = (env, x) => env.expw(x)
  {
    error: parser_error,
    load_word: (sz, dir, mem, key) => {
      ct.loadw(Sort::bitv(sz), self.expb(dir), self.expm(mem), expw(key))
    },
    load: (mem, key) => ct.load(self.expm(mem), expw(key)),
    add: (x, y) => ct.add(expw(x), expw(y)),
    sub: (x, y) => ct.sub(expw(x), expw(y)),
    mul: (x, y) => ct.mul(expw(x), expw(y)),
    div: (x, y) => ct.div(expw(x), expw(y)),
    sdiv: (x, y) => ct.sdiv(expw(x), expw(y)),
    modulo: (x, y) => ct.modulo(expw(x), expw(y)),
    smodulo: (x, y) => ct.smodulo(expw(x), expw(y)),
    lshift: (x, y) => ct.lshift(expw(x), expw(y)),
    rshift: (x, y) => ct.rshift(expw(x), expw(y)),
    arshift: (x, y) => ct.arshift(expw(x), expw(y)),
    logand: (x, y) => ct.logand(expw(x), expw(y)),
    logor: (x, y) => ct.logor(expw(x), expw(y)),
    logxor: (x, y) => ct.logxor(expw(x), expw(y)),
    var_: (name, size) => ct.var_(self.var_(Sort::bitv(size), name)),
    int: (x, size) => ct.int(Sort::bitv(size), x),
    ite: (c, x, y) => ct.ite(self.expb(c), expw(x), expw(y)),
    signed: (w, x) => ct.signed(Sort::bitv(w), expw(x)),
    unsigned: (w, x) => ct.unsigned(Sort::bitv(w), expw(x)),
    high: (w, x) => ct.high(Sort::bitv(w), expw(x)),
    low: (w, x) => ct.low(Sort::bitv(w), expw(x)),
    append: (x, y) => {
      state => {
        let x = expw(x)(state)
        let y = expw(y)(state)
        ct.append(
          parser_join_sizes(x.sort(), y.sort()),
          pure_const(x),
          pure_const(y),
        )(state)
      }
    },
    cast: (size, bit, x) => ct.cast(Sort::bitv(size), self.expb(bit), expw(x)),
    concat: xs => {
      state => {
        let parts = []
        let mut size = 0
        for x in xs {
          let x = expw(x)(state)
          size = size + sort_size(x.sort())
          parts.push(pure_const(x))
        }
        ct.concat(Sort::bitv(size), parts)(state)
      }
    },
    let_bit: self.let_gen((env, x) => env.expb(x), run),
    let_reg: self.let_gen((env, x) => env.expw(x), run),
    let_mem: self.let_gen((env, x) => env.expm(x), run),
    let_float: self.let_gen((env, x) => env.expf(x), run),
    unknown: w => ct.unk(Sort::bitv(w)),
    extract: (size, hi, lo, x) => {
      ct.extract(Sort::bitv(size), expw(hi), expw(lo), expw(x))
    },
    neg: x => ct.neg(expw(x)),
    not: x => ct.not(expw(x)),
    cast_int: (s, m, w) => {
      ct.cast_int(Sort::bitv(s), self.expr(m), self.expf(w))
    },
    cast_sint: (s, m, w) => {
      ct.cast_sint(Sort::bitv(s), self.expr(m), self.expf(w))
    },
    fbits: x => ct.fbits(self.expf(x)),
  }
}

///|
fn[E, R, S] ParserEnv::mem_grammar(self : ParserEnv[E, R, S]) -> MemGrammar[E] {
  let ct = self.ct
  let run : (ParserEnv[E, R, S], E) -> Pure = (env, x) => env.expm(x)
  {
    error: parser_error,
    store: (m, k, x) => ct.store(self.expm(m), self.expw(k), self.expw(x)),
    store_word: (d, m, k, x) => {
      ct.storew(self.expb(d), self.expm(m), self.expw(k), self.expw(x))
    },
    var_: (name, ks, vs) => {
      ct.var_(self.var_(Sort::mem(Sort::bitv(ks), Sort::bitv(vs)), name))
    },
    unknown: (ks, vs) => ct.unk(Sort::mem(Sort::bitv(ks), Sort::bitv(vs))),
    ite: (c, x, y) => ct.ite(self.expb(c), self.expm(x), self.expm(y)),
    let_bit: self.let_gen((env, x) => env.expb(x), run),
    let_reg: self.let_gen((env, x) => env.expw(x), run),
    let_mem: self.let_gen((env, x) => env.expm(x), run),
    let_float: self.let_gen((env, x) => env.expf(x), run),
  }
}

///|
fn[E, R, S] ParserEnv::bool_grammar(
  self : ParserEnv[E, R, S],
) -> BoolGrammar[E] {
  let ct = self.ct
  let expb = x => self.expb(x)
  let expw = x => self.expw(x)
  let run : (ParserEnv[E, R, S], E) -> Pure = (env, x) => env.expb(x)
  let feq : (Pure, Pure) -> Pure = (x, y) => {
    ct.and_(ct.inv(ct.forder(x, y)), ct.inv(ct.forder(y, x)))
  }
  {
    error: parser_error,
    var_: name => ct.var_(self.var_(Sort::bool(), name)),
    ite: (c, x, y) => ct.ite(expb(c), expb(x), expb(y)),
    le: (x, y) => ct.ule(expw(x), expw(y)),
    sle: (x, y) => ct.sle(expw(x), expw(y)),
    lt: (x, y) => ct.ult(expw(x), expw(y)),
    slt: (x, y) => ct.slt(expw(x), expw(y)),
    logor: (x, y) => ct.or_(expb(x), expb(y)),
    logand: (x, y) => ct.and_(expb(x), expb(y)),
    logxor: (x, y) => {
      let x = expb(x)
      let y = expb(y)
      ct.and_(ct.or_(x, y), ct.inv(ct.and_(x, y)))
    },
    eq: (x, y) => ct.eq(expw(x), expw(y)),
    neq: (x, y) => ct.neq(expw(x), expw(y)),
    let_bit: self.let_gen((env, x) => env.expb(x), run),
    let_reg: self.let_gen((env, x) => env.expw(x), run),
    let_mem: self.let_gen((env, x) => env.expm(x), run),
    let_float: self.let_gen((env, x) => env.expf(x), run),
    not: x => ct.inv(expb(x)),
    unknown: () => ct.unk(Sort::bool()),
    int: x => if x.is_zero() { ct.b0() } else { ct.b1() },
    high: x => ct.lsb(ct.high(Sort::bitv(1), expw(x))),
    low: x => ct.lsb(ct.low(Sort::bitv(1), expw(x))),
    extract: (n, x) => {
      state => {
        let x = expw(x)(state)
        let xs = x.sort()
        ct.lsb(
          ct.extract(
            Sort::bitv(1),
            ct.of_int(xs, n),
            ct.of_int(xs, n),
            pure_const(x),
          ),
        )(state)
      }
    },
    fle: (x, y) => {
      let x = self.expf(x)
      let y = self.expf(y)
      ct.or_(ct.forder(x, y), feq(x, y))
    },
    flt: (x, y) => ct.forder(self.expf(x), self.expf(y)),
    feq: (x, y) => feq(self.expf(x), self.expf(y)),
    is_fneg: x => ct.is_fneg(self.expf(x)),
    is_fpos: x => ct.is_fpos(self.expf(x)),
    is_fzero: x => ct.is_fzero(self.expf(x)),
    is_nan: x => ct.is_nan(self.expf(x)),
    is_inf: x => ct.is_inf(self.expf(x)),
  }
}

///|
fn[E, R, S] ParserEnv::float_grammar(
  self : ParserEnv[E, R, S],
) -> FloatGrammar[E, R] {
  let ct = self.ct
  let expf = x => self.expf(x)
  let expr = x => self.expr(x)
  let run : (ParserEnv[E, R, S], E) -> Pure = (env, x) => env.expf(x)
  let floats = p => Sort::ieee754(p)
  {
    error: parser_error,
    ieee754: (s, x) => ct.float(floats(s), self.expw(x)),
    ieee754_var: (s, name) => ct.var_(parser_mkvar(floats(s), name)),
    ieee754_unk: s => ct.unk(floats(s)),
    fadd: (m, x, y) => ct.fadd(expr(m), expf(x), expf(y)),
    fsub: (m, x, y) => ct.fsub(expr(m), expf(x), expf(y)),
    fmul: (m, x, y) => ct.fmul(expr(m), expf(x), expf(y)),
    fdiv: (m, x, y) => ct.fdiv(expr(m), expf(x), expf(y)),
    frem: (m, x, y) => ct.fmodulo(expr(m), expf(x), expf(y)),
    fmin: (x, y) => {
      let x = expf(x)
      let y = expf(y)
      ct.ite(ct.forder(x, y), x, y)
    },
    fmax: (x, y) => {
      let x = expf(x)
      let y = expf(y)
      ct.ite(ct.forder(x, y), y, x)
    },
    ite: (c, x, y) => ct.ite(self.expb(c), expf(x), expf(y)),
    fabs: x => ct.fabs(expf(x)),
    fneg: x => ct.fneg(expf(x)),
    fsqrt: (m, x) => ct.fsqrt(expr(m), expf(x)),
    fround: (m, x) => ct.fround(expr(m), expf(x)),
    ieee754_cast: (s, m, x) => ct.cast_float(floats(s), expr(m), self.expw(x)),
    ieee754_cast_signed: (s, m, x) => {
      ct.cast_sfloat(floats(s), expr(m), self.expw(x))
    },
    ieee754_convert: (s, m, x) => ct.fconvert(floats(s), expr(m), expf(x)),
    let_bit: self.let_gen((env, x) => env.expb(x), run),
    let_reg: self.let_gen((env, x) => env.expw(x), run),
    let_mem: self.let_gen((env, x) => env.expm(x), run),
    let_float: self.let_gen((env, x) => env.expf(x), run),
  }
}

///|
fn[E, R, S] ParserEnv::set_bit(
  self : ParserEnv[E, R, S],
  name : String,
  x : E,
) -> Eff {
  self.ct.set(parser_mkvar(Sort::bool(), name), self.expb(x))
}

///|
fn[E, R, S] ParserEnv::set_reg(
  self : ParserEnv[E, R, S],
  name : String,
  size : Int,
  x : E,
) -> Eff {
  self.ct.set(parser_mkvar(Sort::bitv(size), name), self.expw(x))
}

///|
fn[E, R, S] ParserEnv::set_mem(
  self : ParserEnv[E, R, S],
  name : String,
  ks : Int,
  vs : Int,
  x : E,
) -> Eff {
  let sort = Sort::mem(Sort::bitv(ks), Sort::bitv(vs))
  self.ct.set(parser_mkvar(sort, name), self.expm(x))
}

///|
fn[E, R, S] ParserEnv::set_ieee754(
  self : ParserEnv[E, R, S],
  name : String,
  format : Ieee754Parameters,
  x : E,
) -> Eff {
  self.ct.set(parser_mkvar(Sort::ieee754(format), name), self.expf(x))
}

///|
fn[E, R, S] ParserEnv::set_rmode(
  self : ParserEnv[E, R, S],
  name : String,
  x : R,
) -> Eff {
  self.ct.set(parser_mkvar(Sort::rmode(), name), self.expr(x))
}

///|
/// Parses statements into a (unit) effect (`stmts`): every statement
/// becomes an unlabeled block.
fn[E, R, S] ParserEnv::stmts(
  self : ParserEnv[E, R, S],
  xs : ArrayView[S],
) -> Eff {
  let ct = self.ct
  let pass = ct.perform(EffectSort::bot())
  let skip = ct.perform(EffectSort::bot())
  let null = Label::null()
  guard xs is [x, .. rest] else { return ct.blk(null, pass, skip) }
  let rest = rest.to_owned()
  let next : (Array[S]) -> Eff = ys => self.stmts(ys)
  let bind : (Pure, (Var) -> Eff) -> Eff = (exp, body) => {
    state => {
      let exp = exp(state)
      let v = Var::fresh(exp.sort())
      ct.seq(ct.blk(null, ct.set(v, pure_const(exp)), skip), body(v))(state)
    }
  }
  let move_ : (Eff) -> Eff = eff => ct.seq(ct.blk(null, eff, skip), next(rest))
  let push : (String) -> (Var) -> Eff = name => {
    r => self.bind(name, r).stmts(rest)
  }
  let let_gen : ((ParserEnv[E, R, S]) -> Pure) -> (String, S) -> Eff = exp => {
    (name, body) => {
      ct.seq(bind(exp(self), r => self.bind(name, r).stmts([body])), next(rest))
    }
  }
  (self.parser.stmt)(
    {
      error: parser_eff_error,
      special: _ => ct.seq(ct.blk(null, pass, skip), next(rest)),
      cpuexn: n => {
        ct.seq(ct.blk(null, pass, ct.goto(Label::for_ivec(n))), next(rest))
      },
      while_: (cnd, ys) => {
        ct.seq(
          ct.blk(null, ct.repeat(self.expb(cnd), self.stmtd(ys)), skip),
          next(rest),
        )
      },
      if_: (cnd, yes, nay) => {
        ct.seq(
          ct.branch(self.expb(cnd), self.stmts(yes), self.stmts(nay)),
          next(rest),
        )
      },
      jmp: exp => ct.seq(ct.blk(null, pass, ct.jmp(self.expw(exp))), next(rest)),
      call: name => {
        let dst = Label::for_name(name).with_subroutine(is_subroutine=true)
        ct.seq(ct.blk(null, pass, ct.goto(dst)), next(rest))
      },
      goto: addr => {
        let dst = Label::for_addr(@types.Word::from_bitvec(addr))
        ct.seq(ct.blk(null, pass, ct.goto(dst)), next(rest))
      },
      set_bit: (name, x) => move_(self.set_bit(name, x)),
      set_reg: (name, size, x) => move_(self.set_reg(name, size, x)),
      set_mem: (name, ks, vs, x) => move_(self.set_mem(name, ks, vs, x)),
      set_ieee754: (name, s, x) => move_(self.set_ieee754(name, s, x)),
      set_rmode: (name, x) => move_(self.set_rmode(name, x)),
      tmp_bit: (name, x) => bind(self.expb(x), push(name)),
      tmp_reg: (name, x) => bind(self.expw(x), push(name)),
      tmp_mem: (name, x) => bind(self.expm(x), push(name)),
      tmp_float: (name, x) => bind(self.expf(x), push(name)),
      tmp_rmode: (name, x) => bind(self.expr(x), push(name)),
      let_bit: (name, x, body) => let_gen(env => env.expb(x))(name, body),
      let_reg: (name, x, body) => let_gen(env => env.expw(x))(name, body),
      let_mem: (name, x, body) => let_gen(env => env.expm(x))(name, body),
      let_float: (name, x, body) => let_gen(env => env.expf(x))(name, body),
      let_rmode: (name, x, body) => let_gen(env => env.expr(x))(name, body),
      seq: ys => ct.seq(next(ys), next(rest)),
    },
    x,
  )
}

///|
/// Parses statements into a data effect (`stmtd`, the bodies of loops):
/// control-flow statements are ill-formed here.
fn[E, R, S] ParserEnv::stmtd(
  self : ParserEnv[E, R, S],
  xs : ArrayView[S],
) -> Eff {
  let ct = self.ct
  let pass = ct.perform(EffectSort::bot())
  guard xs is [x, .. rest] else { return pass }
  let rest = rest.to_owned()
  let next : (Array[S]) -> Eff = ys => self.stmtd(ys)
  let bind : (Pure, (Var) -> Eff) -> Eff = (exp, body) => {
    state => {
      let exp = exp(state)
      let v = Var::fresh(exp.sort())
      ct.seq(ct.set(v, pure_const(exp)), body(v))(state)
    }
  }
  let move_ : (Eff) -> Eff = eff => ct.seq(eff, next(rest))
  let push : (String) -> (Var) -> Eff = name => {
    r => self.bind(name, r).stmtd(rest)
  }
  let let_gen : ((ParserEnv[E, R, S]) -> Pure) -> (String, S) -> Eff = exp => {
    (name, body) => {
      ct.seq(bind(exp(self), r => self.bind(name, r).stmtd([body])), next(rest))
    }
  }
  (self.parser.stmt)(
    {
      error: parser_eff_error,
      special: _ => ct.seq(pass, next(rest)),
      cpuexn: _ => parser_eff_error,
      jmp: _ => parser_eff_error,
      goto: _ => parser_eff_error,
      call: _ => parser_eff_error,
      while_: (cnd, ys) => {
        ct.seq(ct.repeat(self.expb(cnd), next(ys)), next(rest))
      },
      if_: (cnd, yes, nay) => {
        ct.seq(
          ct.branch(self.expb(cnd), self.stmtd(yes), self.stmtd(nay)),
          next(rest),
        )
      },
      set_bit: (name, x) => move_(self.set_bit(name, x)),
      set_reg: (name, size, x) => move_(self.set_reg(name, size, x)),
      set_mem: (name, ks, vs, x) => move_(self.set_mem(name, ks, vs, x)),
      set_ieee754: (name, s, x) => move_(self.set_ieee754(name, s, x)),
      set_rmode: (name, x) => move_(self.set_rmode(name, x)),
      tmp_bit: (name, x) => bind(self.expb(x), push(name)),
      tmp_reg: (name, x) => bind(self.expw(x), push(name)),
      tmp_mem: (name, x) => bind(self.expm(x), push(name)),
      tmp_float: (name, x) => bind(self.expf(x), push(name)),
      tmp_rmode: (name, x) => bind(self.expr(x), push(name)),
      let_bit: (name, x, body) => let_gen(env => env.expb(x))(name, body),
      let_reg: (name, x, body) => let_gen(env => env.expw(x))(name, body),
      let_mem: (name, x, body) => let_gen(env => env.expm(x))(name, body),
      let_float: (name, x, body) => let_gen(env => env.expf(x))(name, body),
      let_rmode: (name, x, body) => let_gen(env => env.expr(x))(name, body),
      seq: ys => ct.seq(next(ys), next(rest)),
    },
    x,
  )
}

///|
/// `Parser.Make(CT).run parser program`: parses the statements of a
/// program into a Core Theory effect of the theory `self`.
pub fn[E, R, S] Core::parse(
  self : Core,
  parser : Parser[E, R, S],
  program : ArrayView[S],
) -> Eff {
  let env : ParserEnv[E, R, S] = { ct: self, ctxt: @list.empty(), parser, }
  env.stmts(program)
}

///|
/// Parses a single expression of the parsed language as a bitvector term.
pub fn[E, R, S] Core::parse_bitv(
  self : Core,
  parser : Parser[E, R, S],
  exp : E,
) -> Pure {
  let env : ParserEnv[E, R, S] = { ct: self, ctxt: @list.empty(), parser, }
  env.expw(exp)
}

///|
/// Parses a single expression of the parsed language as a boolean term.
pub fn[E, R, S] Core::parse_bool(
  self : Core,
  parser : Parser[E, R, S],
  exp : E,
) -> Pure {
  let env : ParserEnv[E, R, S] = { ct: self, ctxt: @list.empty(), parser, }
  env.expb(exp)
}

///|
/// Parses a single expression of the parsed language as a memory term.
pub fn[E, R, S] Core::parse_mem(
  self : Core,
  parser : Parser[E, R, S],
  exp : E,
) -> Pure {
  let env : ParserEnv[E, R, S] = { ct: self, ctxt: @list.empty(), parser, }
  env.expm(exp)
}
