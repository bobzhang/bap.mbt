// Shared helpers for the ARM lifter tests.

///|
fn r(name : String) -> @mc.Op {
  @mc.Op::reg(name)
}

///|
fn i(value : Int) -> @mc.Op {
  Imm(value.to_int64())
}

///|
/// Condition "always" and the unused predicate register.
let al : Array[@mc.Op] = [i(14), r("Nil")]

///|
/// A condition code followed by the unused predicate register.
fn cc(code : Int) -> Array[@mc.Op] {
  [i(code), r("Nil")]
}

///|
fn render(stmts : Array[@types.Stmt]) -> String {
  let buf = StringBuilder()
  render_to(buf, stmts, "")
  buf.to_string()
}

///|
/// Render statements one per line, expanding nested blocks.
fn render_to(
  buf : StringBuilder,
  stmts : Array[@types.Stmt],
  indent : String,
) -> Unit {
  for s in stmts {
    if buf.to_string() != "" {
      buf.write_string("\n")
    }
    match s {
      If(cond~, yes~, no~) => {
        buf.write_string("\{indent}if \{cond.to_string()} {")
        render_to(buf, yes, indent + "  ")
        if no.length() > 0 {
          buf.write_string("\n\{indent}} else {")
          render_to(buf, no, indent + "  ")
        }
        buf.write_string("\n\{indent}}")
      }
      While(cond~, body~) => {
        buf.write_string("\{indent}while \{cond.to_string()} {")
        render_to(buf, body, indent + "  ")
        buf.write_string("\n\{indent}}")
      }
      _ => buf.write_string(indent + s.to_string())
    }
  }
}

///|
fn lift_insn(
  name : String,
  ops : Array[@mc.Op],
  addr? : UInt64 = 0,
  raw? : UInt,
) -> Array[@types.Stmt] raise {
  @arm.lift(@mc.Insn::create(name, ops, addr~), raw?)
}

///|
fn lift_str(
  name : String,
  ops : Array[@mc.Op],
  addr? : UInt64 = 0,
  raw? : UInt,
) -> String raise {
  render(lift_insn(name, ops, addr~, raw?))
}

///|
fn lift_error(name : String, ops : Array[@mc.Op]) -> String {
  try lift_insn(name, ops) catch {
    @mc.LiftError::Failure(msg) => "Failure: " + msg
    @mc.LiftError::BadOperands(msg) => "BadOperands: " + msg
    @mc.LiftError::Unsupported(msg) => "Unsupported: " + msg
    err => "other: \{err}"
  } noraise {
    stmts => "unexpected success:\n" + render(stmts)
  }
}

///|
fn word32(x : UInt) -> @types.Word {
  try! @types.Word::of_uint64(width=32, x.to_uint64())
}

///|
fn bit(b : Bool) -> @types.BilValue {
  BilWord(@types.Word::of_bool(b))
}

///|
/// Initial machine state: the given 32-bit registers, the given flags (all
/// other flags cleared), and a memory holding `bytes` at address `0x1000`.
fn state(
  regs : Array[(String, UInt)],
  flags? : Array[(String, Bool)] = [],
  bytes? : Bytes = b"",
) -> @types.BilState {
  let values : Map[String, @types.BilValue] = Map([])
  for f in ["NF", "ZF", "CF", "VF", "QF", "GE0", "GE1", "GE2", "GE3"] {
    values[f] = bit(false)
  }
  for pair in flags {
    values[pair.0] = bit(pair.1)
  }
  for pair in regs {
    values[pair.0] = BilWord(word32(pair.1))
  }
  values["mem"] = BilMem(
    @types.BilMemory::from_bytes(addr_width=32, start=0x1000, bytes),
  )
  @types.BilState::from_values(values)
}

///|
fn exec(
  stmts : Array[@types.Stmt],
  init : @types.BilState,
) -> @types.BilState raise {
  match @types.exec_stmts(stmts, state=init) {
    Ok(s) => s
    Err(msg) => fail("evaluation failed: \{msg}\n\{render(stmts)}")
  }
}

///|
/// Lift `name ops` and run the resulting BIL from `init`.
fn run(
  name : String,
  ops : Array[@mc.Op],
  init : @types.BilState,
  addr? : UInt64 = 0,
  raw? : UInt,
) -> @types.BilState raise {
  exec(lift_insn(name, ops, addr~, raw?), init)
}

///|
fn reg_value(s : @types.BilState, name : String) -> UInt raise {
  match s.get_word(name) {
    Some(w) => w.to_uint64().to_uint()
    None => fail("register \{name} is undefined")
  }
}

///|
fn flag_value(s : @types.BilState, name : String) -> Bool raise {
  match s.get_word(name) {
    Some(w) => w.is_one()
    None => fail("flag \{name} is undefined")
  }
}

///|
/// Render the flags as `NZCV` letters (`-` when cleared).
fn nzcv(s : @types.BilState) -> String raise {
  let buf = StringBuilder()
  for pair in [("NF", 'N'), ("ZF", 'Z'), ("CF", 'C'), ("VF", 'V')] {
    buf.write_char(if flag_value(s, pair.0) { pair.1 } else { '-' })
  }
  buf.to_string()
}

///|
/// Read a little-endian 32-bit word from memory.
fn mem_word(s : @types.BilState, addr : UInt) -> UInt raise {
  guard s.get_memory("mem") is Some(m) else { fail("no memory") }
  match m.load(word32(addr), endian=LittleEndian, width=32) {
    Ok(w) => w.to_uint64().to_uint()
    Err(msg) => fail(msg)
  }
}

///|
/// Execute `stmts` and return the target of the first jump taken, if any.
fn jump_target(
  stmts : Array[@types.Stmt],
  init : @types.BilState,
) -> UInt? raise {
  let mut st = init
  for s in stmts {
    match s {
      Jmp(e) =>
        match e.eval_value(st.values()) {
          Ok(BilWord(w)) => return Some(w.to_uint64().to_uint())
          _ => fail("bad jump target")
        }
      If(cond~, yes~, no~) => {
        let taken = match cond.eval_value(st.values()) {
          Ok(BilWord(w)) => !w.is_zero()
          _ => fail("bad condition")
        }
        let branch = if taken { yes } else { no }
        match jump_target(branch, st) {
          Some(t) => return Some(t)
          None => st = exec(branch, st)
        }
      }
      _ => st = exec([s], st)
    }
  }
  None
}
