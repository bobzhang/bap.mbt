///|
fn describe_terms(
  state : @knowledge.State,
  terms : Array[(String, @core_theory.Pure)],
) -> String raise {
  let lines = []
  for term in terms {
    let value = (term.1)(state)
    let empty = if value.is_empty() { "" } else { " (non-empty)" }
    lines.push("\{term.0}: \{value.sort().to_string()}\{empty}")
  }
  lines.join("\n")
}

///|
fn describe_effects(
  state : @knowledge.State,
  terms : Array[(String, @core_theory.Eff)],
) -> String raise {
  let lines = []
  for term in terms {
    let effect = (term.1)(state)
    let empty = if effect.is_empty() { "" } else { " (non-empty)" }
    lines.push("\{term.0}: \{effect.sort().to_string()}\{empty}")
  }
  lines.join("\n")
}

///|
test "empty theory: Init, Bool, Bitv and Memory sorts" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::empty()
  let s8 = @core_theory.Sort::bitv(8)
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let y = ct.var_(@core_theory.Var::create(s8, "y"))
  let a = ct.var_(@core_theory.Var::create(s32, "a"))
  let m = ct.var_(
    @core_theory.Var::create(@core_theory.Sort::mem(s32, s8), "mem"),
  )
  let t = @core_theory.Var::create(s32, "t")
  let terms : Array[(String, @core_theory.Pure)] = [
    ("var", x),
    ("unk", ct.unk(s32)),
    ("let_", ct.let_(t, a, x)),
    ("ite", ct.ite(ct.b1(), x, y)),
    ("b0", ct.b0()),
    ("b1", ct.b1()),
    ("inv", ct.inv(ct.b0())),
    ("and_", ct.and_(ct.b0(), ct.b1())),
    ("or_", ct.or_(ct.b0(), ct.b1())),
    ("int", ct.int(s32, @bitvec.of_int(width=32, 7))),
    ("msb", ct.msb(x)),
    ("lsb", ct.lsb(x)),
    ("neg", ct.neg(x)),
    ("not", ct.not(x)),
    ("add", ct.add(x, y)),
    ("sub", ct.sub(x, y)),
    ("mul", ct.mul(x, y)),
    ("div", ct.div(x, y)),
    ("sdiv", ct.sdiv(x, y)),
    ("modulo", ct.modulo(x, y)),
    ("smodulo", ct.smodulo(x, y)),
    ("logand", ct.logand(x, y)),
    ("logor", ct.logor(x, y)),
    ("logxor", ct.logxor(x, y)),
    ("shiftr", ct.shiftr(ct.b0(), x, a)),
    ("shiftl", ct.shiftl(ct.b0(), x, a)),
    ("sle", ct.sle(x, y)),
    ("ule", ct.ule(x, y)),
    ("cast", ct.cast(s32, ct.b0(), x)),
    ("concat", ct.concat(@core_theory.Sort::bitv(16), [x, y])),
    ("append", ct.append(@core_theory.Sort::bitv(16), x, y)),
    ("load", ct.load(m, a)),
    ("store", ct.store(m, a, x)),
  ]
  inspect(
    describe_terms(state, terms),
    content=(
      #|var: core:bitv<8>
      #|unk: core:bitv<32>
      #|let_: core:bitv<8>
      #|ite: core:bitv<8>
      #|b0: core:bool
      #|b1: core:bool
      #|inv: core:bool
      #|and_: core:bool
      #|or_: core:bool
      #|int: core:bitv<32>
      #|msb: core:bool
      #|lsb: core:bool
      #|neg: core:bitv<8>
      #|not: core:bitv<8>
      #|add: core:bitv<8>
      #|sub: core:bitv<8>
      #|mul: core:bitv<8>
      #|div: core:bitv<8>
      #|sdiv: core:bitv<8>
      #|modulo: core:bitv<8>
      #|smodulo: core:bitv<8>
      #|logand: core:bitv<8>
      #|logor: core:bitv<8>
      #|logxor: core:bitv<8>
      #|shiftr: core:bitv<8>
      #|shiftl: core:bitv<8>
      #|sle: core:bool
      #|ule: core:bool
      #|cast: core:bitv<32>
      #|concat: core:bitv<16>
      #|append: core:bitv<16>
      #|load: core:bitv<8>
      #|store: core:mem<core:bitv<32>><core:bitv<8>>
    ),
  )
}

///|
test "empty theory: Basic sorts" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::empty()
  let s8 = @core_theory.Sort::bitv(8)
  let s16 = @core_theory.Sort::bitv(16)
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(s8, "x"))
  let y = ct.var_(@core_theory.Var::create(s8, "y"))
  let a = ct.var_(@core_theory.Var::create(s32, "a"))
  let m = ct.var_(
    @core_theory.Var::create(@core_theory.Sort::mem(s32, s8), "mem"),
  )
  let terms : Array[(String, @core_theory.Pure)] = [
    ("zero", ct.zero(s16)),
    ("is_zero", ct.is_zero(x)),
    ("non_zero", ct.non_zero(x)),
    ("succ", ct.succ(x)),
    ("pred", ct.pred(x)),
    ("nsucc", ct.nsucc(x, 3)),
    ("npred", ct.npred(x, 3)),
    ("high", ct.high(s16, a)),
    ("low", ct.low(s16, a)),
    ("signed", ct.signed(s16, x)),
    ("unsigned", ct.unsigned(s16, x)),
    ("extract", ct.extract(s16, a, a, a)),
    ("loadw", ct.loadw(s32, ct.b1(), m, a)),
    ("storew", ct.storew(ct.b1(), m, a, a)),
    ("arshift", ct.arshift(x, a)),
    ("rshift", ct.rshift(x, a)),
    ("lshift", ct.lshift(x, a)),
    ("eq", ct.eq(x, y)),
    ("neq", ct.neq(x, y)),
    ("slt", ct.slt(x, y)),
    ("ult", ct.ult(x, y)),
    ("sgt", ct.sgt(x, y)),
    ("ugt", ct.ugt(x, y)),
    ("sge", ct.sge(x, y)),
    ("uge", ct.uge(x, y)),
  ]
  inspect(
    describe_terms(state, terms),
    content=(
      #|zero: core:bitv<16>
      #|is_zero: core:bool
      #|non_zero: core:bool
      #|succ: core:bitv<8>
      #|pred: core:bitv<8>
      #|nsucc: core:bitv<8>
      #|npred: core:bitv<8>
      #|high: core:bitv<16>
      #|low: core:bitv<16>
      #|signed: core:bitv<16>
      #|unsigned: core:bitv<16>
      #|extract: core:bitv<16>
      #|loadw: core:bitv<32>
      #|storew: core:mem<core:bitv<32>><core:bitv<8>>
      #|arshift: core:bitv<8>
      #|rshift: core:bitv<8>
      #|lshift: core:bitv<8>
      #|eq: core:bool
      #|neq: core:bool
      #|slt: core:bool
      #|ult: core:bool
      #|sgt: core:bool
      #|ugt: core:bool
      #|sge: core:bool
      #|uge: core:bool
    ),
  )
}

///|
test "empty theory: floating-point and transcendental sorts" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::empty()
  let f32 = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary32(),
  )
  let f64 = @core_theory.Sort::ieee754(
    @core_theory.Ieee754Parameters::binary64(),
  )
  let s32 = @core_theory.Sort::bitv(32)
  let x = ct.var_(@core_theory.Var::create(f32, "x"))
  let y = ct.var_(@core_theory.Var::create(f32, "y"))
  let n = ct.var_(@core_theory.Var::create(s32, "n"))
  let rm = ct.rne()
  let terms : Array[(String, @core_theory.Pure)] = [
    ("float", ct.float(f32, n)),
    ("fbits", ct.fbits(x)),
    ("is_finite", ct.is_finite(x)),
    ("is_nan", ct.is_nan(x)),
    ("is_inf", ct.is_inf(x)),
    ("is_fzero", ct.is_fzero(x)),
    ("is_fpos", ct.is_fpos(x)),
    ("is_fneg", ct.is_fneg(x)),
    ("rne", ct.rne()),
    ("rna", ct.rna()),
    ("rtp", ct.rtp()),
    ("rtn", ct.rtn()),
    ("rtz", ct.rtz()),
    ("requal", ct.requal(ct.rne(), ct.rtz())),
    ("cast_float", ct.cast_float(f64, rm, n)),
    ("cast_sfloat", ct.cast_sfloat(f64, rm, n)),
    ("cast_int", ct.cast_int(s32, rm, x)),
    ("cast_sint", ct.cast_sint(s32, rm, x)),
    ("fneg", ct.fneg(x)),
    ("fabs", ct.fabs(x)),
    ("fadd", ct.fadd(rm, x, y)),
    ("fsub", ct.fsub(rm, x, y)),
    ("fmul", ct.fmul(rm, x, y)),
    ("fdiv", ct.fdiv(rm, x, y)),
    ("fsqrt", ct.fsqrt(rm, x)),
    ("fmodulo", ct.fmodulo(rm, x, y)),
    ("fmad", ct.fmad(rm, x, y, x)),
    ("fround", ct.fround(rm, x)),
    ("fconvert", ct.fconvert(f64, rm, x)),
    ("fsucc", ct.fsucc(x)),
    ("fpred", ct.fpred(x)),
    ("forder", ct.forder(x, y)),
    ("pow", ct.pow(rm, x, y)),
    ("compound", ct.compound(rm, x, n)),
    ("rootn", ct.rootn(rm, x, n)),
    ("pown", ct.pown(rm, x, n)),
    ("rsqrt", ct.rsqrt(rm, x)),
    ("hypot", ct.hypot(rm, x, y)),
  ]
  inspect(
    describe_terms(state, terms),
    content=(
      #|float: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fbits: core:bitv<32>
      #|is_finite: core:bool
      #|is_nan: core:bool
      #|is_inf: core:bool
      #|is_fzero: core:bool
      #|is_fpos: core:bool
      #|is_fneg: core:bool
      #|rne: core:rmode
      #|rna: core:rmode
      #|rtp: core:rmode
      #|rtn: core:rmode
      #|rtz: core:rmode
      #|requal: core:bool
      #|cast_float: core:float<core:bitv<core:IEEE754<2><11><52>><64>>
      #|cast_sfloat: core:float<core:bitv<core:IEEE754<2><11><52>><64>>
      #|cast_int: core:bitv<32>
      #|cast_sint: core:bitv<32>
      #|fneg: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fabs: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fadd: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fsub: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fmul: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fdiv: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fsqrt: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fmodulo: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fmad: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fround: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fconvert: core:float<core:bitv<core:IEEE754<2><11><52>><64>>
      #|fsucc: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|fpred: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|forder: core:bool
      #|pow: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|compound: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|rootn: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|pown: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|rsqrt: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
      #|hypot: core:float<core:bitv<core:IEEE754<2><8><23>><32>>
    ),
  )
  // all transcendental functions preserve the sort of their argument
  let trans : Array[(String, @core_theory.Pure)] = [
    ("exp", ct.exp(rm, x)),
    ("expm1", ct.expm1(rm, x)),
    ("exp2", ct.exp2(rm, x)),
    ("exp2m1", ct.exp2m1(rm, x)),
    ("exp10", ct.exp10(rm, x)),
    ("exp10m1", ct.exp10m1(rm, x)),
    ("log", ct.log(rm, x)),
    ("log2", ct.log2(rm, x)),
    ("log10", ct.log10(rm, x)),
    ("logp1", ct.logp1(rm, x)),
    ("log2p1", ct.log2p1(rm, x)),
    ("log10p1", ct.log10p1(rm, x)),
    ("sin", ct.sin(rm, x)),
    ("cos", ct.cos(rm, x)),
    ("tan", ct.tan(rm, x)),
    ("sinpi", ct.sinpi(rm, x)),
    ("cospi", ct.cospi(rm, x)),
    ("atanpi", ct.atanpi(rm, x)),
    ("atan2pi", ct.atan2pi(rm, x, y)),
    ("asin", ct.asin(rm, x)),
    ("acos", ct.acos(rm, x)),
    ("atan", ct.atan(rm, x)),
    ("atan2", ct.atan2(rm, x, y)),
    ("sinh", ct.sinh(rm, x)),
    ("cosh", ct.cosh(rm, x)),
    ("tanh", ct.tanh(rm, x)),
    ("asinh", ct.asinh(rm, x)),
    ("acosh", ct.acosh(rm, x)),
    ("atanh", ct.atanh(rm, x)),
  ]
  for term in trans {
    let value = (term.1)(state)
    assert_true(value.sort() == f32, msg=term.0)
    assert_true(value.is_empty(), msg=term.0)
  }
}

///|
test "empty theory: effects" {
  let state = @knowledge.State::new()
  let ct = @core_theory.Core::empty()
  let s32 = @core_theory.Sort::bitv(32)
  let r = @core_theory.Var::create(s32, "r")
  let data = ct.set(r, ct.var_(r))
  let jump = ct.perform(@core_theory.EffectSort::jump())
  let terms : Array[(String, @core_theory.Eff)] = [
    ("perform", jump),
    ("set", data),
    ("jmp", ct.jmp(ct.var_(r))),
    ("goto", ct.goto(@core_theory.Label::null())),
    ("seq", ct.seq(jump, data)),
    ("blk", ct.blk(@core_theory.Label::null(), data, jump)),
    ("repeat", ct.repeat(ct.b1(), data)),
    ("branch", ct.branch(ct.b1(), jump, data)),
  ]
  inspect(
    describe_effects(state, terms),
    content=(
      #|perform: jump
      #|set: bot
      #|jmp: bot
      #|goto: bot
      #|seq: jump
      #|blk: bot
      #|repeat: bot
      #|branch: jump
    ),
  )
}
