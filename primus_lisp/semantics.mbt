// The semantics mode: a compiler from Primus Lisp definitions to BIL
// (upstream `Bap_primus_lisp_semantics` and the semantic primitives of
// `plugins/primus_lisp/primus_lisp_semantic_primitives.ml`).
//
// Upstream reifies Lisp definitions into Core Theory terms; the port
// compiles them directly to BIL statements, which is what the `mc` lifter
// interface consumes. The compilation is a partial evaluation: values that
// are statically known (literals, immediate operands, arithmetic over
// them) are folded, and control flow on static conditions is resolved at
// compile time (including loops), so the generated BIL mentions only the
// dynamic parts of the computation.

///|
/// Errors of the semantics compiler.
pub(all) suberror SemanticsError {
  /// no definition for the name, or a failed resolution
  UnresolvedDefinition(String)
  /// an `(error "...")` form was evaluated
  UserError(String)
  /// a primitive was applied to arguments that it can't handle
  Illformed(String, String)
  /// the program has type errors
  IllTyped(Array[TypeError])
}

///|
pub impl Show for SemanticsError with fn output(self, logger) {
  match self {
    UnresolvedDefinition(msg) => logger.write_string(msg)
    UserError(msg) => logger.write_string("error: \{msg}")
    Illformed(name, msg) =>
      logger.write_string("illformed lisp program: \{name}: \{msg}")
    IllTyped(errs) => {
      logger.write_string("the Lisp program is ill-typed:\n")
      for e in errs {
        logger.write_string(e.summary())
        logger.write_char('\n')
      }
    }
  }
}

///|
/// A semantic value: a pure BIL expression of the given width, optionally
/// with its statically known value, and the symbol that it denotes (e.g.,
/// the name of a register operand).
pub struct SValue {
  exp : @types.Exp
  width : Int
  static_value : @types.Word?
  symbol : String?
}

///|
/// A semantic value together with the effects that compute it.
pub struct SEff {
  stmts : Array[@types.Stmt]
  value : SValue
}

///|
/// The implementation of a semantic primitive.
pub struct SemaBody {
  run : (SemCtx, String, Array[SValue]) -> SEff raise SemanticsError
}

///|
priv enum SemKind {
  KPrim
  KDefn
  KMeth
  KData
}

///|
/// The compilation context of one instruction.
pub struct SemCtx {
  target : @core_theory.Target
  priv lifter : Lifter
  priv binds : Map[String, SValue]
  priv bvars : Map[String, @types.Var]
  priv scope : Map[String, Array[@types.Var]]
  priv out : StringBuilder
  /// the address of the instruction, if known
  pc : @types.Word?
}

///|
fn SemCtx::word(self : SemCtx) -> Int {
  let b = self.target.bits()
  if b <= 0 {
    32
  } else {
    b
  }
}

///|
fn illformed(name : String, msg : String) -> SemanticsError {
  Illformed(name, msg)
}

// ---------------------------------------------------------------------------
// Values

///|
fn word_zero(w : Int) -> @types.Word {
  try! @types.Word::zero(width=@cmp.maximum(1, w))
}

///|
fn resize(w : @types.Word, s : Int, signed? : Bool = false) -> @types.Word {
  let n = w.bitwidth()
  if n == s {
    w
  } else {
    let kind : @types.CastKind = if s < n {
      Low
    } else if signed {
      Signed
    } else {
      Unsigned
    }
    match kind.apply(s, w) {
      Ok(r) => r
      Err(_) => word_zero(s)
    }
  }
}

///|
fn const_word(w : @types.Word) -> SValue {
  { exp: Int(w), width: w.bitwidth(), static_value: Some(w), symbol: None, }
}

///|
fn const_int(s : Int, n : Int) -> SValue {
  const_word(word_of_bigint(@bigint.BigInt::from_int(n), s))
}

///|
fn const_bool(b : Bool) -> SValue {
  const_word(if b { @types.Word::b1() } else { @types.Word::b0() })
}

///|
fn dynv(exp : @types.Exp, width : Int) -> SValue {
  { exp, width, static_value: None, symbol: None, }
}

///|
fn pure(v : SValue) -> SEff {
  { stmts: [], value: v, }
}

///|
fn nil_value() -> SValue {
  const_bool(false)
}

///|
fn word_to_int(w : @types.Word) -> Int? {
  if w.bitwidth() <= 31 {
    try w.to_int() catch {
      _ => None
    } noraise {
      x => Some(x)
    }
  } else {
    let r = resize(w, 64)
    try r.to_int64() catch {
      _ => None
    } noraise {
      x => if x >= 0L && x < 0x40000000L { Some(x.to_int()) } else { None }
    }
  }
}

///|
/// The symbol table of the semantics mode (upstream `KB.Symbol.intern`).
let symbol_table : Map[String, Int] = Map([])

///|
fn intern(name : String) -> @types.Word {
  let name = @knowledge.Name::read(name).unqualified()
  let id = match symbol_table.get(name) {
    Some(id) => id
    None => {
      let id = symbol_table.length() + 2
      symbol_table[name] = id
      id
    }
  }
  word_of_bigint(@bigint.BigInt::from_int(id), 64)
}

///|
fn sym_value(s : String) -> SValue {
  let w = match s {
    "t" => word_of_bigint(1N, 64)
    "nil" => word_of_bigint(0N, 64)
    name => intern(name)
  }
  { ..const_word(w), symbol: Some(s), }
}

///|
fn reify_sym(v : SValue) -> SValue {
  match (v.static_value, v.symbol) {
    (None, Some(name)) => { ..v, static_value: Some(intern(name)), }
    _ => v
  }
}

///|
/// Coerces a value to the given width: static values are truncated or
/// zero-extended, dynamic values are sign-extended or truncated (upstream
/// `coerce`, which uses `CT.signed`).
fn coerce(s : Int, x : SValue) -> SValue {
  if x.width == s {
    x
  } else {
    match x.static_value {
      Some(w) => const_word(resize(w, s))
      None =>
        dynv(
          Cast(kind=if s < x.width { Low } else { Signed }, width=s, exp=x.exp),
          s,
        )
    }
  }
}

///|
fn coerce_unsigned(s : Int, x : SValue) -> SValue {
  if x.width == s {
    x
  } else {
    match x.static_value {
      Some(w) => const_word(resize(w, s))
      None =>
        dynv(
          Cast(
            kind=if s < x.width { Low } else { Unsigned },
            width=s,
            exp=x.exp,
          ),
          s,
        )
    }
  }
}

///|
/// A one-bit value that is true if `x` is non-zero.
fn to_bool(x : SValue) -> SValue {
  if x.width == 1 {
    x
  } else {
    match x.static_value {
      Some(w) => const_bool(!w.is_zero())
      None => dynv(BinOp(Neq, x.exp, Int(word_zero(x.width))), 1)
    }
  }
}

///|
fn and_bool(x : SValue, y : SValue) -> SValue {
  match (x.static_value, y.static_value) {
    (Some(a), Some(b)) => const_bool(!a.is_zero() && !b.is_zero())
    (Some(a), None) => if a.is_zero() { x } else { y }
    (None, Some(b)) => if b.is_zero() { y } else { x }
    _ => dynv(BinOp(And, x.exp, y.exp), 1)
  }
}

// ---------------------------------------------------------------------------
// The lifter

///|
/// A Lisp program prepared for lifting: the program with the semantic
/// primitives and the places of the target, type checked.
pub struct Lifter {
  target : @core_theory.Target
  program : Program
  typed : TypedProgram
  priv places : Map[(String, String), @types.Var]
  priv names : Map[(String, String), SemKind]
  priv mem : @types.Var
}

///|
/// The type errors of the lifter program.
pub fn Lifter::errors(self : Lifter) -> Array[TypeError] {
  self.typed.errors()
}

///|
fn target_memory(t : @core_theory.Target) -> @types.Var {
  match bil_var_of_theory(t.data()) {
    Some(v) => v
    None => {
      let bits = if t.bits() <= 0 { 32 } else { t.bits() }
      @types.Var::create("mem", Mem(addr_width=bits, value_width=8))
    }
  }
}

///|
/// Prepares the program for lifting instructions of the target (upstream
/// `obtain_typed_program`): the program context is refined with the
/// target context, the semantic primitives and the target registers are
/// added, and the program is type checked. When `strict` is `true` (the
/// default, as upstream) an ill-typed program is rejected.
pub fn Lifter::create(
  prog : Program,
  target : @core_theory.Target,
  strict? : Bool = true,
) -> Lifter raise SemanticsError {
  let context = prog.context.merge(Context::of_target(target))
  let prog = link_semantic_primitives(prog.with_context(context), target).with_places(
    target,
  )
  let typed = prog.infer_types()
  if strict {
    let errs = typed.errors()
    if !errs.is_empty() {
      raise IllTyped(errs)
    }
  }
  let places = Map([])
  prog.fold(place, init=(), (pkg, def, _) => {
    places[key(@knowledge.Name::create(def.name, pkg~))] = def.code.location
  })
  let names : Map[(String, String), SemKind] = Map([])
  // later kinds override earlier ones (upstream `merge_names`)
  let collect = (kind : SemKind, pkg : String, name : String, attrs : Attrs) => {
    if attrs.context.le(prog.context) {
      names[key(@knowledge.Name::create(name, pkg~))] = kind
    }
  }
  prog.fold(func, init=(), (p, d, _) => collect(KDefn, p, d.name, d.attrs))
  prog.fold(semantics, init=(), (p, d, _) => collect(KPrim, p, d.name, d.attrs))
  prog.fold(para, init=(), (p, d, _) => collect(KData, p, d.name, d.attrs))
  prog.fold(const_item, init=(), (p, d, _) => collect(KData, p, d.name, d.attrs))
  prog.fold(meth, init=(), (p, d, _) => collect(KMeth, p, d.name, d.attrs))
  { target, program: prog, typed, places, names, mem: target_memory(target), }
}

///|
/// Finds a register of the target or one of its ancestors by name.
fn find_target_var(t : @core_theory.Target, name : String) -> @types.Var? {
  for p in [t].iter().concat(t.parents().iter()) {
    if p.find_var(name) is Some(v) {
      return bil_var_of_theory(v)
    }
  }
  None
}

///|
/// Loads the Lisp semantics from the embedded upstream library: the core
/// library (`lisp`), the generic semantic definitions (`semantics/primus`)
/// and the definitions of the given directories (e.g.,
/// `["semantics/riscv"]`). All features of the semantic directories are
/// loaded, as upstream does.
pub fn load_semantics(
  target : @core_theory.Target,
  dirs : Array[String],
  strict? : Bool = true,
) -> Lifter raise Error {
  let sdirs = ["semantics/primus"] + dirs
  let features = ["core"] + embedded_features(sdirs)
  let loader = Loader::embedded(sdirs + ["lisp"])
  let prog = load_program(loader, features)
  Lifter::create(prog, target, strict~)
}

///|
/// An operand of an instruction.
pub(all) enum Operand {
  /// an immediate value
  Imm(Int64)
  /// a register (by name)
  Reg(String)
  /// an unknown (e.g., floating-point) operand
  Unknown
} derive(Eq, Debug)

///|
fn Lifter::operand(self : Lifter, op : Operand) -> SValue {
  let bits = if self.target.bits() <= 0 { 32 } else { self.target.bits() }
  match op {
    Imm(x) => const_word(word_of_bigint(@bigint.BigInt::from_int64(x), bits))
    Reg(name) => {
      let v = match find_target_var(self.target, name) {
        Some(v) => v
        None => @types.Var::create(name, Imm(bits))
      }
      let width = match v.typ {
        Imm(n) => n
        _ => bits
      }
      { exp: Var(v), width, static_value: None, symbol: Some(name), }
    }
    Unknown => dynv(Unknown("fmm", Imm(bits)), bits)
  }
}

///|
/// Compiles the semantics of the instruction `name` applied to the
/// operands into BIL (upstream `reify`). Returns `None` if there is no
/// definition with this name. Messages printed by `msg` are appended to
/// `out`.
pub fn Lifter::lift(
  self : Lifter,
  name : @knowledge.Name,
  ops : Array[Operand],
  pc? : @types.Word,
  out? : StringBuilder = StringBuilder(),
) -> Array[@types.Stmt]? raise SemanticsError {
  fresh_counter.val = 0
  let ctx : SemCtx = {
    target: self.target,
    lifter: self,
    binds: Map([]),
    bvars: Map([]),
    scope: Map([]),
    out,
    pc,
  }
  if !self.names.contains(key(name)) {
    return None
  }
  let args = ops.map(op => self.operand(op))
  let eff = ctx.call(name, args)
  Some(eff.stmts)
}

///|
/// Evaluates a Lisp function (by name) with the given semantic values as
/// arguments and returns the effects and the result.
pub fn Lifter::apply(
  self : Lifter,
  name : @knowledge.Name,
  args : Array[SValue],
  pc? : @types.Word,
  out? : StringBuilder = StringBuilder(),
) -> SEff raise SemanticsError {
  fresh_counter.val = 0
  let ctx : SemCtx = {
    target: self.target,
    lifter: self,
    binds: Map([]),
    bvars: Map([]),
    scope: Map([]),
    out,
    pc,
  }
  ctx.call(name, args)
}

///|
/// The Lisp package of the instructions of the encoding (e.g.,
/// `llvm-riscv64`). An unknown encoding is derived from the target.
pub fn encoding_package(
  encoding : @core_theory.Language,
  target : @core_theory.Target,
) -> String {
  let name = encoding.to_string()
  let name = match name.rev_find(":") {
    Some(i) => name.unsafe_substring(start=i + 1, end=name.length())
    None => name
  }
  if name != "unknown" && name != "" {
    name
  } else if target.belongs(@core_theory.Target::riscv()) {
    if target.bits() == 32 {
      "llvm-riscv32"
    } else {
      "llvm-riscv64"
    }
  } else {
    @mc.default_encoding(target).to_string()
  }
}

///|
/// The `mc` lifter provider (upstream `Semantics.enable_lifter`): the name
/// of an instruction is looked up in the package named after its encoding
/// (e.g., `llvm-riscv64:ADDI`), register operands are passed as their
/// target registers, immediates as static words.
pub fn Lifter::provider(
  self : Lifter,
  name? : String = "primus-lisp",
) -> @mc.Provider {
  @mc.Provider::create(
    name,
    accepts=ctx => {
      ctx.target().belongs(self.target) || self.target.belongs(ctx.target())
    },
    lift=(ctx, insn) => {
      let pkg = encoding_package(insn.encoding(), ctx.target())
      let lname = @knowledge.Name::create(insn.name(), pkg~)
      let ops = insn
        .ops()
        .iter()
        .map(op => {
          match op {
            Reg(name~, ..) => Operand::Reg(name)
            Imm(x) => Operand::Imm(x)
            Fmm(_) => Operand::Unknown
          }
        })
        .collect()
      let pc = @types.Word::of_uint64(
        width=@cmp.maximum(1, ctx.target().bits()),
        insn.addr(),
      ) catch {
        _ => @types.Word::b0()
      }
      let r = self.lift(lname, ops, pc~) catch {
        e => raise @mc.LiftError::Failure("primus-lisp: \{insn.name()}: \{e}")
      }
      match r {
        None =>
          raise @mc.LiftError::Unsupported(
            opcode=insn.name(),
            target=ctx.target().to_string(),
          )
        Some(bil) => @mc.Lifted::of_bil(bil)
      }
    },
  )
}

// ---------------------------------------------------------------------------
// The compiler

///|
fn SemCtx::make_var(
  self : SemCtx,
  name : @knowledge.Name,
  t? : Int,
) -> @types.Var {
  match self.lifter.places.get(key(name)) {
    Some(v) => v
    None => {
      let w = match t {
        Some(t) => t
        None => self.word()
      }
      @types.Var::create(name.show(), Imm(w))
    }
  }
}

///|
fn var_width(v : @types.Var) -> Int {
  match v.typ {
    Imm(n) => n
    Mem(..) => 0
  }
}

///|
fn SemCtx::is_machine_var(self : SemCtx, v : @types.Var) -> Bool {
  match find_target_var(self.target, v.name) {
    Some(_) => true
    None => v.name == self.lifter.mem.name
  }
}

///|
fn SemCtx::lookup_parameter(self : SemCtx, v : @types.Var) -> Ast? {
  let name = @knowledge.Name::read(v.name)
  let prog = self.lifter.program.with_package(name.pkg())
  match prog.get(para, name=name.unqualified()) {
    [p, ..] => Some(p.code.default)
    [] => None
  }
}

///|
fn SemCtx::full(_self : SemCtx, effs : Array[SEff], v : SValue) -> SEff {
  let stmts = []
  for e in effs {
    stmts.append(e.stmts)
  }
  { stmts, value: v, }
}

///|
fn fresh_var(width : Int) -> @types.Var {
  fresh_counter.val += 1
  @types.Var::new(
    name="#\{fresh_counter.val}",
    typ=Imm(@cmp.maximum(1, width)),
    is_virtual=true,
  )
}

///|
/// The counter of temporary variables, reset for every lifted
/// instruction, so that the temporaries are named `#1`, `#2`, ...
let fresh_counter : Ref[Int] = Ref(0)

///|
fn SemCtx::assign(
  self : SemCtx,
  is_local? : Bool = false,
  v : @types.Var,
  eff : SEff,
) -> SEff {
  let x = eff.value
  if x.static_value is Some(_) && (is_local || !self.is_machine_var(v)) {
    self.binds[v.name] = x
    self.bvars[v.name] = v
    eff
  } else {
    self.binds.remove(v.name)
    let w = var_width(v)
    let e = if w > 0 && w != x.width {
      coerce_unsigned(w, x).exp
    } else {
      x.exp
    }
    let stmts = eff.stmts.copy()
    stmts.push(Move(v, e))
    { stmts, value: x, }
  }
}

///|
fn SemCtx::lookup(self : SemCtx, v : @types.Var) -> SEff raise SemanticsError {
  match self.scope.get(v.name) {
    Some([t, ..]) => self.lookup(t)
    _ =>
      match self.binds.get(v.name) {
        Some(x) => pure(x)
        None =>
          match self.lookup_parameter(v) {
            Some(def) => {
              let eff = self.eval(def)
              self.assign(v, eff)
            }
            None => {
              let w = var_width(v)
              pure(dynv(Var(v), if w == 0 { self.word() } else { w }))
            }
          }
      }
  }
}

///|
fn SemCtx::eval(self : SemCtx, e : Ast) -> SEff raise SemanticsError {
  match e.data {
    Int({ value, typ: Type(m), .. }) =>
      pure(const_word(word_of_bigint(value, m)))
    Int({ value, .. }) => pure(const_word(word_of_bigint(value, self.word())))
    Var({ name, typ: Type(t), .. }) => self.lookup(self.make_var(name, t~))
    Var({ name, .. }) => self.lookup(self.make_var(name))
    Sym({ name, .. }) => pure(sym_value(name.unqualified()))
    Ite(c, yes, nay) => self.ite(c, yes, nay)
    Let(v, x, b) => self.let_(v.name, x, b)
    App(Dynamic(name), args) => self.app(name, args)
    App(Static(_), _) => pure(nil_value())
    Seq(xs) => {
      let mut eff = pure(nil_value())
      for x in xs {
        let e2 = self.eval(x)
        eff = self.full([eff, e2], e2.value)
      }
      eff
    }
    Set({ name, typ: Type(t), .. }, x) => self.set_(self.make_var(name, t~), x)
    Set({ name, .. }, x) => self.set_(self.make_var(name), x)
    Rep(c, body) => self.rep(c, body, 0)
    Msg(fmt, args) => {
      let (aeff, args) = self.map(args)
      for f in fmt {
        match f {
          Lit(s) => self.out.write_string(s)
          Pos(n) =>
            match args.get(n) {
              None => raise UserError("bad positional \{n}")
              Some(v) =>
                match v.static_value {
                  Some(w) => self.out.write_string(w.to_hex())
                  None => self.out.write_string(v.exp.to_string())
                }
            }
        }
      }
      self.out.write_char('\n')
      { stmts: aeff.stmts, value: nil_value(), }
    }
    Err(msg) => raise UserError(unquote(msg))
  }
}

///|
fn SemCtx::ite(
  self : SemCtx,
  c : Ast,
  yes : Ast,
  nay : Ast,
) -> SEff raise SemanticsError {
  let cnd = self.eval(c)
  match cnd.value.static_value {
    Some(w) => {
      let r = if w.is_zero() { self.eval(nay) } else { self.eval(yes) }
      self.full([cnd, r], r.value)
    }
    None => {
      let cres = to_bool(cnd.value)
      let cv = fresh_var(1)
      let saved = self.binds.copy()
      let y = self.eval(yes)
      let ybinds = self.binds.copy()
      self.binds.clear()
      for k, v in saved {
        self.binds[k] = v
      }
      let n = self.eval(nay)
      let nbinds = self.binds.copy()
      // keep the static bindings that agree in both branches, the others
      // are materialized at the end of the branches that have them
      let ystmts = y.stmts.copy()
      let nstmts = n.stmts.copy()
      self.binds.clear()
      let keys = ybinds.keys().collect()
      for k in nbinds.keys() {
        if !ybinds.contains(k) {
          keys.push(k)
        }
      }
      for k in keys {
        match (ybinds.get(k), nbinds.get(k)) {
          (Some(yv), Some(nv)) if yv.static_value == nv.static_value &&
            yv.width == nv.width => self.binds[k] = yv
          (yv, nv) => {
            if yv is Some(v) {
              ystmts.push(self.materialize(k, v))
            }
            if nv is Some(v) {
              nstmts.push(self.materialize(k, v))
            }
          }
        }
      }
      let y = { ..y, stmts: ystmts, }
      let n = { ..n, stmts: nstmts, }
      let width = @cmp.maximum(y.value.width, n.value.width)
      let yv = coerce_unsigned(width, y.value)
      let nv = coerce_unsigned(width, n.value)
      let stmts = cnd.stmts.copy()
      stmts.push(Move(cv, cres.exp))
      stmts.push(If(cond=Var(cv), yes=y.stmts, no=n.stmts))
      { stmts, value: dynv(Ite(cond=Var(cv), yes=yv.exp, no=nv.exp), width), }
    }
  }
}

///|
fn SemCtx::rep(
  self : SemCtx,
  c : Ast,
  body : Ast,
  n : Int,
) -> SEff raise SemanticsError {
  let saved = self.binds.copy()
  let saved_scope = self.scope.copy()
  let r = self.eval(c)
  match r.value.static_value {
    Some(x) =>
      if x.is_zero() {
        r
      } else if n > 100_000 {
        raise illformed("while", "the loop does not terminate statically")
      } else {
        let b = self.eval(body)
        let rest = self.rep(c, body, n + 1)
        self.full([r, b, rest], rest.value)
      }
    None => {
      // the condition is re-evaluated below, after the flush
      self.binds.clear()
      for k, v in saved {
        self.binds[k] = v
      }
      ignore(saved_scope)
      // the variables assigned in the loop are not static
      let assigned = self.assigned_vars([c, body])
      let pre = self.flush(assigned)
      let r = self.eval(c)
      let b = self.eval(body)
      let post = self.flush(assigned)
      // re-evaluate the condition at the end of each iteration
      let r2 = self.eval(c)
      let cres = to_bool(r.value)
      let cres2 = to_bool(r2.value)
      let cv = fresh_var(1)
      let stmts = pre
      stmts.append(r.stmts)
      stmts.push(Move(cv, cres.exp))
      let body_stmts = b.stmts.copy()
      body_stmts.append(post)
      body_stmts.append(r2.stmts)
      body_stmts.push(Move(cv, cres2.exp))
      stmts.push(While(cond=Var(cv), body=body_stmts))
      { stmts, value: dynv(Var(cv), 1), }
    }
  }
}

///|
fn SemCtx::let_(
  self : SemCtx,
  name : @knowledge.Name,
  x : Ast,
  b : Ast,
) -> SEff raise SemanticsError {
  let xeff = self.eval(x)
  let orig = @types.Var::create(
    name.show(),
    Imm(@cmp.maximum(1, xeff.value.width)),
  )
  if self.lookup_parameter(orig) is Some(_) {
    let old = self.binds.get(orig.name)
    self.binds[orig.name] = xeff.value
    let beff = self.eval(b)
    match old {
      Some(o) => self.binds[orig.name] = o
      None => self.binds.remove(orig.name)
    }
    self.full([xeff, beff], beff.value)
  } else {
    let t = fresh_var(xeff.value.width)
    match self.scope.get(orig.name) {
      Some(vs) => vs.insert(0, t)
      None => self.scope[orig.name] = [t]
    }
    let aeff = self.assign(is_local=true, t, xeff)
    let beff = self.eval(b)
    match self.scope.get(orig.name) {
      Some([_]) | None => self.scope.remove(orig.name)
      Some(vs) => vs.remove(0) |> ignore
    }
    self.full([aeff, beff], beff.value)
  }
}

///|
fn SemCtx::set_(
  self : SemCtx,
  v : @types.Var,
  x : Ast,
) -> SEff raise SemanticsError {
  match self.scope.get(v.name) {
    Some([t, ..]) => {
      let eff = self.eval(x)
      self.assign(is_local=true, t, eff)
    }
    _ => {
      let eff = self.eval(x)
      self.assign(v, eff)
    }
  }
}

///|
fn SemCtx::map(
  self : SemCtx,
  args : Array[Ast],
) -> (SEff, Array[SValue]) raise SemanticsError {
  let stmts = []
  let vals = []
  for a in args {
    let e = self.eval(a)
    stmts.append(e.stmts)
    vals.push(e.value)
  }
  ({ stmts, value: nil_value(), }, vals)
}

///|
fn SemCtx::app(
  self : SemCtx,
  name : @knowledge.Name,
  args : Array[Ast],
) -> SEff raise SemanticsError {
  let (aeff, xs) = self.map(args)
  let peff = self.call(name, xs)
  self.full([aeff, peff], peff.value)
}

///|
fn unresolved(name : @knowledge.Name, why : String) -> SemanticsError {
  UnresolvedDefinition("Failed to find a definition for \{name.show()}. \{why}")
}

///|
fn SemCtx::call(
  self : SemCtx,
  name : @knowledge.Name,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  match self.lifter.names.get(key(name)) {
    Some(KDefn) => self.call_defn(name, xs)
    Some(KMeth) => self.call_meth(name, xs)
    Some(KData) => raise unresolved(name, "This item is not callable")
    Some(KPrim) | None => self.call_primitive(name, xs)
  }
}

///|
fn SemCtx::bind_args(
  self : SemCtx,
  bs : Array[(LVar, SValue)],
) -> Array[(String, SValue?)] {
  let old = []
  for b in bs {
    let n = b.0.name.show()
    old.push((n, self.binds.get(n)))
    self.binds[n] = b.1
  }
  old
}

///|
fn SemCtx::unbind_args(self : SemCtx, old : Array[(String, SValue?)]) -> Unit {
  for i = old.length() - 1; i >= 0; i = i - 1 {
    match old[i].1 {
      None => self.binds.remove(old[i].0)
      Some(v) => self.binds[old[i].0] = v
    }
  }
}

///|
fn SemCtx::with_frame(
  self : SemCtx,
  bs : Array[(LVar, SValue)],
  body : Ast,
) -> SEff raise SemanticsError {
  let old = self.bind_args(bs)
  let scope = self.scope.copy()
  self.scope.clear()
  errdefer {
    self.scope.clear()
    for k, v in scope {
      self.scope[k] = v
    }
    self.unbind_args(old)
  }
  let r = self.eval(body)
  self.scope.clear()
  for k, v in scope {
    self.scope[k] = v
  }
  self.unbind_args(old)
  r
}

///|
fn SemCtx::call_defn(
  self : SemCtx,
  name : @knowledge.Name,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  let prog = self.lifter.program
  match resolve_defun(prog, (_, _) => true, name, xs) {
    Some(Ok((fn_, _))) if !fn_.attrs.externals.is_empty() => {
      let dst = sym_value(fn_.name)
      self.call_primitive(
        @knowledge.Name::create("invoke-subroutine", pkg="core"),
        [dst] + xs,
      )
    }
    Some(Ok((fn_, bs))) => self.with_frame(bs, fn_.code.body)
    Some(Err(r)) => raise unresolved(name, r.to_string())
    None => raise unresolved(name, "internal error, unexpected function")
  }
}

///|
fn SemCtx::call_meth(
  self : SemCtx,
  name : @knowledge.Name,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  match resolve_meth(self.lifter.program, (_, _) => true, name, xs) {
    Some(Err(r)) => raise unresolved(name, r.to_string())
    None => raise unresolved(name, "internal error, unexpected method")
    Some(Ok(mets)) => {
      let stmts = []
      let mut value = nil_value()
      for m in mets {
        let e = self.with_frame(m.1, m.0.code.body)
        stmts.append(e.stmts)
        value = e.value
      }
      { stmts, value, }
    }
  }
}

///|
fn SemCtx::call_primitive(
  self : SemCtx,
  name : @knowledge.Name,
  xs : Array[SValue],
) -> SEff raise SemanticsError {
  match resolve_simple(self.lifter.program, semantics, name) {
    Some(Ok(sema)) => {
      let r = (sema.code.apply.run)(self, name.unqualified(), xs)
      { ..r, value: reify_sym(r.value), }
    }
    Some(Err(r)) => raise unresolved(name, r.to_string())
    None => raise unresolved(name, "no such function or primitive")
  }
}

///|
/// A move that materializes a static binding.
fn SemCtx::materialize(self : SemCtx, name : String, v : SValue) -> @types.Stmt {
  let bvar = match self.bvars.get(name) {
    Some(x) => x
    None => @types.Var::create(name, Imm(@cmp.maximum(1, v.width)))
  }
  let w = var_width(bvar)
  Move(
    bvar,
    if w > 0 && w != v.width {
      coerce_unsigned(w, v).exp
    } else {
      v.exp
    },
  )
}

///|
/// Materializes and forgets the static bindings of the given variables.
fn SemCtx::flush(self : SemCtx, names : Array[String]) -> Array[@types.Stmt] {
  let out = []
  for n in names {
    if self.binds.get(n) is Some(v) {
      out.push(self.materialize(n, v))
      self.binds.remove(n)
    }
  }
  out
}

///|
fn collect_sets(e : Ast, out : Array[LVar]) -> Unit {
  match e.data {
    Set(v, x) => {
      out.push(v)
      collect_sets(x, out)
    }
    Int(_) | Var(_) | Sym(_) | Err(_) => ()
    Ite(x, y, z) => {
      collect_sets(x, out)
      collect_sets(y, out)
      collect_sets(z, out)
    }
    Let(_, x, y) | Rep(x, y) => {
      collect_sets(x, out)
      collect_sets(y, out)
    }
    App(_, xs) | Seq(xs) | Msg(_, xs) =>
      for x in xs {
        collect_sets(x, out)
      }
  }
}

///|
/// The names (after the resolution of the local scopes) of the variables
/// that are assigned in the expressions.
fn SemCtx::assigned_vars(self : SemCtx, es : Array[Ast]) -> Array[String] {
  let vs = []
  for e in es {
    collect_sets(e, vs)
  }
  vs.map(v => {
    let bvar = match v.typ {
      Type(t) => self.make_var(v.name, t~)
      _ => self.make_var(v.name)
    }
    match self.scope.get(bvar.name) {
      Some([t, ..]) => t.name
      _ => bvar.name
    }
  })
}
