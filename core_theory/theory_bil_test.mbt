///|
fn bil_of(state : @knowledge.State, term : @core_theory.Pure) -> String raise {
  let value = term(state)
  let exp = match value.bil() {
    Some(exp) => exp.to_string()
    None => "<none>"
  }
  "\{exp} : \{value.sort().to_string()}"
}

///|
fn bil_stmts(state : @knowledge.State, term : @core_theory.Eff) -> String raise {
  term(state).bil().map(stmt => stmt.to_string()).join("; ")
}

///|
fn bv(width : Int, n : Int) -> @bitvec.BitVec raise {
  @core_theory.bitvec_of_int(width, n)
}

///|
test "BIL theory: bitvector and boolean operations" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil()
  let s8 = @core_theory.Sort::bitv(8)
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let y = ct.var_(@core_theory.Var::create(s8, "y"))
  let a = ct.var_(@core_theory.Var::create(s32, "a"))
  let terms : Array[(String, @core_theory.Pure)] = [
    ("int", ct.int(s8, bv(8, 42))),
    ("add", ct.add(x, ct.int(s8, bv(8, 1)))),
    ("sub", ct.sub(x, y)),
    ("mul", ct.mul(x, y)),
    ("div", ct.div(x, y)),
    ("sdiv", ct.sdiv(x, y)),
    ("modulo", ct.modulo(x, y)),
    ("smodulo", ct.smodulo(x, y)),
    ("logand", ct.logand(x, y)),
    ("logor", ct.logor(x, y)),
    ("logxor", ct.logxor(x, y)),
    ("neg", ct.neg(x)),
    ("not", ct.not(x)),
    ("msb", ct.msb(x)),
    ("lsb", ct.lsb(x)),
    ("inv", ct.inv(ct.msb(x))),
    ("and_", ct.and_(ct.msb(x), ct.lsb(x))),
    ("or_", ct.or_(ct.msb(x), ct.lsb(x))),
    ("eq", ct.eq(x, y)),
    ("neq", ct.neq(x, y)),
    ("ult", ct.ult(x, y)),
    ("ule", ct.ule(x, y)),
    ("slt", ct.slt(x, y)),
    ("sle", ct.sle(x, y)),
    ("ugt", ct.ugt(x, y)),
    ("sge", ct.sge(x, y)),
    ("is_zero", ct.is_zero(x)),
    ("non_zero", ct.non_zero(x)),
    ("rshift", ct.rshift(x, y)),
    ("arshift", ct.arshift(x, y)),
    ("lshift", ct.lshift(x, y)),
    ("shiftr b1", ct.shiftr(ct.b1(), x, y)),
    ("succ", ct.succ(x)),
    ("npred", ct.npred(x, 2)),
    ("unk", ct.unk(s32)),
    ("unk bool", ct.unk(@core_theory.Sort::bool())),
  ]
  let lines = []
  for term in terms {
    lines.push("\{term.0}: \{bil_of(state, term.1)}")
  }
  inspect(
    lines.join("\n"),
    content=(
      #|int: 0x2A:8u : core:bitv<8>
      #|add: (x:imm8 + 1:8u) : core:bitv<8>
      #|sub: (x:imm8 - y:imm8) : core:bitv<8>
      #|mul: (x:imm8 * y:imm8) : core:bitv<8>
      #|div: (x:imm8 / y:imm8) : core:bitv<8>
      #|sdiv: (x:imm8 s/ y:imm8) : core:bitv<8>
      #|modulo: (x:imm8 % y:imm8) : core:bitv<8>
      #|smodulo: (x:imm8 s% y:imm8) : core:bitv<8>
      #|logand: (x:imm8 & y:imm8) : core:bitv<8>
      #|logor: (x:imm8 | y:imm8) : core:bitv<8>
      #|logxor: (x:imm8 ^ y:imm8) : core:bitv<8>
      #|neg: (neg x:imm8) : core:bitv<8>
      #|not: (not x:imm8) : core:bitv<8>
      #|msb: high:1[x:imm8] : core:bool
      #|lsb: low:1[x:imm8] : core:bool
      #|inv: (not high:1[x:imm8]) : core:bool
      #|and_: (high:1[x:imm8] & low:1[x:imm8]) : core:bool
      #|or_: (high:1[x:imm8] | low:1[x:imm8]) : core:bool
      #|eq: (x:imm8 == y:imm8) : core:bool
      #|neq: (x:imm8 != y:imm8) : core:bool
      #|ult: (x:imm8 < y:imm8) : core:bool
      #|ule: (x:imm8 <= y:imm8) : core:bool
      #|slt: (x:imm8 s< y:imm8) : core:bool
      #|sle: (x:imm8 s<= y:imm8) : core:bool
      #|ugt: (y:imm8 < x:imm8) : core:bool
      #|sge: (y:imm8 s<= x:imm8) : core:bool
      #|is_zero: (x:imm8 == 0:8u) : core:bool
      #|non_zero: (x:imm8 != 0:8u) : core:bool
      #|rshift: (x:imm8 >> y:imm8) : core:bitv<8>
      #|arshift: (x:imm8 a>> y:imm8) : core:bitv<8>
      #|lshift: (x:imm8 << y:imm8) : core:bitv<8>
      #|shiftr b1: ite(1:1u, ((x:imm8 >> y:imm8) | (not (0xFF:8u >> y:imm8))), (x:imm8 >> y:imm8)) : core:bitv<8>
      #|succ: (x:imm8 + 1:8u) : core:bitv<8>
      #|npred: (x:imm8 - 2:8u) : core:bitv<8>
      #|unk: unknown(bits:imm32) : core:bitv<32>
      #|unk bool: unknown(bits:imm1) : core:bool
    ),
  )
  ignore(a)
}

///|
test "BIL theory: casts, concatenation and extraction" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil()
  let s8 = @core_theory.Sort::bitv(8)
  let s16 = @core_theory.Sort::bitv(16)
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let y = ct.var_(@core_theory.Var::create(s8, "y"))
  let a = ct.var_(@core_theory.Var::create(s32, "a"))
  let c = ct.var_(@core_theory.Var::create(@core_theory.Sort::bool(), "c"))
  let pos = n => ct.int(s32, bv(32, n))
  let terms : Array[(String, @core_theory.Pure)] = [
    ("cast same", ct.cast(s8, ct.b0(), x)),
    ("cast zero fill", ct.cast(s32, ct.b0(), x)),
    ("cast one fill", ct.cast(s16, ct.b1(), x)),
    ("cast dynamic fill", ct.cast(s16, c, x)),
    ("cast narrow", ct.cast(s8, ct.b0(), a)),
    ("high", ct.high(s8, a)),
    ("low", ct.low(s8, a)),
    ("signed", ct.signed(s32, x)),
    ("unsigned", ct.unsigned(s32, x)),
    ("append", ct.append(s16, x, y)),
    ("append widen", ct.append(s32, x, y)),
    ("append narrow", ct.append(s8, x, y)),
    ("concat", ct.concat(s32, [x, y, x, y])),
    ("extract const", ct.extract(s8, pos(15), pos(8), a)),
    ("extract derived", ct.extract(s16, pos(15), pos(8), a)),
    ("ite", ct.ite(c, x, y)),
    ("ite as cond", ct.ite(c, ct.b1(), ct.b0())),
    ("ite as not cond", ct.ite(c, ct.b0(), ct.b1())),
  ]
  let lines = []
  for term in terms {
    lines.push("\{term.0}: \{bil_of(state, term.1)}")
  }
  inspect(
    lines.join("\n"),
    content=(
      #|cast same: x:imm8 : core:bitv<8>
      #|cast zero fill: pad:32[x:imm8] : core:bitv<32>
      #|cast one fill: ite(high:1[x:imm8], extend:16[x:imm8], (pad:16[x:imm8] | 0xFF00:16u)) : core:bitv<16>
      #|cast dynamic fill: ite(c:imm1, (pad:16[x:imm8] | 0xFF00:16u), pad:16[x:imm8]) : core:bitv<16>
      #|cast narrow: low:8[a:imm32] : core:bitv<8>
      #|high: high:8[a:imm32] : core:bitv<8>
      #|low: low:8[a:imm32] : core:bitv<8>
      #|signed: extend:32[x:imm8] : core:bitv<32>
      #|unsigned: pad:32[x:imm8] : core:bitv<32>
      #|append: concat(x:imm8, y:imm8) : core:bitv<16>
      #|append widen: pad:32[concat(x:imm8, y:imm8)] : core:bitv<32>
      #|append narrow: low:8[concat(x:imm8, y:imm8)] : core:bitv<8>
      #|concat: concat(concat(concat(x:imm8, y:imm8), x:imm8), y:imm8) : core:bitv<32>
      #|extract const: extract[15:8](a:imm32) : core:bitv<8>
      #|extract derived: low:16[((not ((not 0:32u) << ((0xF:32u - 8:32u) + 1:32u))) & (a:imm32 >> 8:32u))] : core:bitv<16>
      #|ite: ite(c:imm1, x:imm8, y:imm8) : core:bitv<8>
      #|ite as cond: c:imm1 : core:bool
      #|ite as not cond: (not c:imm1) : core:bool
    ),
  )
}

///|
test "BIL theory: memory" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil()
  let s8 = @core_theory.Sort::bitv(8)
  let s32 = @core_theory.Sort::bitv(32)
  let mem_sort = @core_theory.Sort::mem(s32, s8)
  let m = ct.var_(@core_theory.Var::create(mem_sort, "mem"))
  let a = ct.var_(@core_theory.Var::create(s32, "a"))
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let c = ct.var_(@core_theory.Var::create(@core_theory.Sort::bool(), "c"))
  let big = ct.loadw(s32, ct.b1(), m, a)(state)
  let little = ct.loadw(s32, ct.b0(), m, a)(state)
  guard big.bil() is Some(Load(endian=BigEndian, typ=Imm(32), ..)) else {
    fail("expected a big endian load")
  }
  guard little.bil() is Some(Load(endian=LittleEndian, typ=Imm(32), ..)) else {
    fail("expected a little endian load")
  }
  let stored = ct.storew(ct.b0(), m, a, a)(state)
  guard stored.bil() is Some(Store(endian=LittleEndian, ..)) else {
    fail("expected a little endian store")
  }
  assert_true(stored.sort() == mem_sort)
  let terms : Array[(String, @core_theory.Pure)] = [
    ("load", ct.load(m, a)),
    ("store", ct.store(m, a, x)),
    ("loadw dynamic", ct.loadw(s32, c, m, a)),
    // not a BIL size: derived from the minimal theory
    ("loadw 24", ct.loadw(@core_theory.Sort::bitv(24), ct.b1(), m, a)),
  ]
  let lines = []
  for term in terms {
    lines.push("\{term.0}: \{bil_of(state, term.1)}")
  }
  inspect(
    lines.join("\n"),
    content=(
      #|load: load(mem:mem32x8, a:imm32):imm8 : core:bitv<8>
      #|store: store(mem:mem32x8, a:imm32, x:imm8) : core:mem<core:bitv<32>><core:bitv<8>>
      #|loadw dynamic: ite(c:imm1, load(mem:mem32x8, a:imm32):imm32, load(mem:mem32x8, a:imm32):imm32) : core:bitv<32>
      #|loadw 24: let %$0:imm8 = load(mem:mem32x8, (a:imm32 + 0:32u)):imm8 in let %$1:imm8 = load(mem:mem32x8, (a:imm32 + 1:32u)):imm8 in let %$2:imm8 = load(mem:mem32x8, (a:imm32 + 2:32u)):imm8 in ite(1:1u, concat(concat(%$0:imm8, %$1:imm8), %$2:imm8), concat(concat(%$2:imm8, %$1:imm8), %$0:imm8)) : core:bitv<24>
    ),
  )
}

///|
test "BIL theory: effects" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil()
  let s32 = @core_theory.Sort::bitv(32)
  let r = @core_theory.Var::create(s32, "R0")
  let t = @core_theory.Var::create(s32, "t")
  let c = ct.var_(@core_theory.Var::create(@core_theory.Sort::bool(), "c"))
  let set = ct.set(r, ct.add(ct.var_(r), ct.int(s32, bv(32, 4))))
  let jmp = ct.jmp(ct.var_(r))
  let addr = @types.Word::of_int(width=32, 0x1000)
  let terms : Array[(String, @core_theory.Eff)] = [
    ("set", set),
    ("jmp", jmp),
    ("seq", ct.seq(set, jmp)),
    ("branch", ct.branch(c, set, jmp)),
    (
      "branch empty",
      ct.branch(
        c,
        ct.perform(@core_theory.EffectSort::bot()),
        ct.perform(@core_theory.EffectSort::bot()),
      ),
    ),
    ("repeat", ct.repeat(c, set)),
    ("blk unlabeled", ct.blk(@core_theory.Label::null(), set, jmp)),
    ("goto addr", ct.goto(@core_theory.Label::for_addr(addr))),
    ("goto ivec", ct.goto(@core_theory.Label::for_ivec(3))),
    ("goto name", ct.goto(@core_theory.Label::for_name("malloc"))),
    (
      "let",
      ct.set(
        r,
        ct.let_(t, ct.int(s32, bv(32, 1)), ct.add(ct.var_(t), ct.var_(r))),
      ),
    ),
    (
      "let non-constant",
      ct.set(r, ct.let_(t, ct.var_(r), ct.add(ct.var_(t), ct.var_(t)))),
    ),
  ]
  let lines = []
  for term in terms {
    lines.push("\{term.0}: \{bil_stmts(state, term.1)}")
  }
  inspect(
    lines.join("\n"),
    content=(
      #|set: R0:imm32 := (R0:imm32 + 4:32u)
      #|jmp: jmp R0:imm32
      #|seq: R0:imm32 := (R0:imm32 + 4:32u); jmp R0:imm32
      #|branch: if c:imm1 then 1 stmts else 1 stmts
      #|branch empty: 
      #|repeat: while c:imm1 do 1 stmts
      #|blk unlabeled: R0:imm32 := (R0:imm32 + 4:32u); jmp R0:imm32
      #|goto addr: jmp 0x1000:32u
      #|goto ivec: cpuexn 3
      #|goto name: special @attribute:(bap:call malloc)
      #|let: R0:imm32 := (1:32u + R0:imm32)
      #|let non-constant: R0:imm32 := let t:imm32 = R0:imm32 in (t:imm32 + t:imm32)
    ),
  )
  let fresh = @core_theory.Label::fresh()
  let labeled = ct.blk(fresh, set, jmp)(state).bil()
  assert_true(labeled.length() == 3)
  assert_true(
    @types.Stmt::decode(@types.Stmt::label(), labeled[0]) ==
    Some("%\{fresh.id()}"),
  )
}

///|
test "BIL theory: rounding modes and floats" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::bil()
  let rne = ct.rne()(state)
  assert_true(rne.sort() == @core_theory.Sort::rmode())
  let lines = []
  lines.push("rne: \{bil_of(state, ct.rne())}")
  lines.push("rtz: \{bil_of(state, ct.rtz())}")
  lines.push("requal: \{bil_of(state, ct.requal(ct.rne(), ct.rtz()))}")
  let f32 = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary32(),
  )
  let f = ct.var_(@core_theory.Var::create(f32, "f"))
  lines.push("fbits: \{bil_of(state, ct.fbits(f))}")
  // floating-point operations are not emulated: empty values
  lines.push("fadd: \{bil_of(state, ct.fadd(ct.rne(), f, f))}")
  inspect(
    lines.join("\n"),
    content=(
      #|rne: 0:8u : core:rmode
      #|rtz: 4:8u : core:rmode
      #|requal: (0:8u == 4:8u) : core:bool
      #|fbits: unknown(bits:imm32) : core:bitv<32>
      #|fadd: <none> : core:float<core:bitv<core:IEEE754<2><8><23>><32>>
    ),
  )
}
