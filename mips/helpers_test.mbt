// Shared helpers for the MIPS lifter tests: instruction construction, a
// BAP-like BIL pretty printer and a tiny evaluator front-end.

///|
fn r(name : String) -> @mc.Op {
  @mc.Op::reg(name)
}

///|
fn i(value : Int64) -> @mc.Op {
  Imm(value)
}

///|
fn insn(
  name : String,
  ops : Array[@mc.Op],
  addr? : UInt64 = 0x1000,
) -> @mc.Insn {
  @mc.Insn::create(name, ops, addr~, size=4)
}

///|
fn render_endian(e : @bitvec.Endian) -> String {
  match e {
    BigEndian => "be"
    LittleEndian => "el"
  }
}

///|
fn render_exp(e : @types.Exp) -> String {
  match e {
    Int(w) => w.to_string()
    Var(v) => v.name
    Load(mem~, addr~, endian~, typ~) => {
      let bits = typ.bitwidth().unwrap_or(0)
      "\{render_exp(mem)}[\{render_exp(addr)}, \{render_endian(endian)}]:u\{bits}"
    }
    Store(mem~, addr~, value~, endian~) => {
      let bits = value.infer_type().unwrap_or(Imm(0)).bitwidth().unwrap_or(0)
      "\{render_exp(mem)} with [\{render_exp(addr)}, \{render_endian(endian)}]:u\{bits} <- \{render_exp(value)}"
    }
    Cast(kind~, width~, exp~) =>
      "\{kind.to_string()}:\{width}[\{render_exp(exp)}]"
    Extract(hi~, lo~, exp~) => "extract:\{hi}:\{lo}[\{render_exp(exp)}]"
    Concat(high~, low~) => "(\{render_exp(high)} . \{render_exp(low)})"
    UnOp(Not, exp) => "~\{render_exp(exp)}"
    UnOp(Neg, exp) => "-\{render_exp(exp)}"
    BinOp(op, lhs, rhs) =>
      "(\{render_exp(lhs)} \{op.to_string()} \{render_exp(rhs)})"
    _ => e.to_string()
  }
}

///|
fn render_stmts(
  buf : StringBuilder,
  stmts : Array[@types.Stmt],
  indent : String,
) -> Unit {
  for s in stmts {
    match s {
      Move(v, e) => buf <+ "\{indent}\{v.name} := \{render_exp(e)}\n"
      Jmp(e) => buf <+ "\{indent}jmp \{render_exp(e)}\n"
      If(cond~, yes~, no~) => {
        buf <+ "\{indent}if \{render_exp(cond)} {\n"
        render_stmts(buf, yes, indent + "  ")
        if no.is_empty() {
          buf <+ "\{indent}}\n"
        } else {
          buf <+ "\{indent}} else {\n"
          render_stmts(buf, no, indent + "  ")
          buf <+ "\{indent}}\n"
        }
      }
      _ => buf <+ "\{indent}\{s.to_string()}\n"
    }
  }
}

///|
fn render(stmts : Array[@types.Stmt]) -> String {
  let buf = StringBuilder()
  render_stmts(buf, stmts, "")
  buf.to_string()
}

///|
/// The core-theory target named `name` (one of `@mips.targets`).
fn target_of(name : String) -> @core_theory.Target {
  match name {
    "mips" => @core_theory.Target::mips()
    "mipsel" => @core_theory.Target::mipsel()
    "mips64" => @core_theory.Target::mips64()
    "mips64el" => @core_theory.Target::mips64el()
    _ => @core_theory.Target::unknown()
  }
}

///|
/// Lift `insn` through a registry holding the MIPS provider, in the context
/// of the target named `target`.
fn lift_on(target : String, insn : @mc.Insn) -> Array[@types.Stmt] raise {
  let registry = @mc.Registry::new()
  @mips.register(registry~)
  registry.lift(@mc.Context::create(target_of(target)), insn).bil
}

///|
/// Lift every sample through the `@mc` registry for `target` and render
/// each as a header line (`NAME op, op`) followed by its indented BIL.
fn show(
  target : String,
  samples : Array[(String, Array[@mc.Op])],
) -> String raise {
  let buf = StringBuilder()
  for sample in samples {
    let (name, ops) = sample
    let bil = lift_on(target, insn(name, ops))
    buf <+ "\{name} \{ops.map(op => op.to_string()).join(", ")}\n"
    render_stmts(buf, bil, "  ")
  }
  buf.to_string()
}

///|
fn word_value(width : Int, value : Int64) -> @types.BilValue raise {
  BilWord(@types.Word::of_int64(value, width~))
}

///|
/// Execute `stmts` from the register values `regs` and return the state.
fn run(
  stmts : Array[@types.Stmt],
  regs : Array[(String, @types.BilValue)],
) -> @types.BilState raise {
  let mut state = @types.BilState::new()
  for reg in regs {
    state = state.set(reg.0, reg.1)
  }
  match @types.exec_stmts(stmts, state~) {
    Ok(state) => state
    Err(msg) => fail(msg)
  }
}

///|
fn reg_hex(state : @types.BilState, name : String) -> String {
  match state.get_word(name) {
    Some(w) => w.to_string()
    None => "<unset>"
  }
}

///|
/// Lift `name ops` for `mips` (or `mips64` when `wide`) and run it from
/// `regs`, returning the final value of `out`.
fn eval32(
  name : String,
  ops : Array[@mc.Op],
  regs : Array[(String, Int64)],
  out : String,
  wide? : Bool = false,
) -> String raise {
  let width = if wide { 64 } else { 32 }
  let bil = if wide {
    @mips.lift_mips64(insn(name, ops))
  } else {
    @mips.lift_mips(insn(name, ops))
  }
  let state = run(bil, regs.map(reg => (reg.0, word_value(width, reg.1))))
  reg_hex(state, out)
}
