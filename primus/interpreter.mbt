///|
/// The registers of the interpreter (upstream `Interpreter` state): the
/// clock, the program counter, the current position, the stack of call
/// prompts (return destinations) and the previously executed block (used
/// to select phi-node options). A local (per-fork) state; all interpreter
/// operations are static functions taking the machine
/// (upstream `Interpreter.Make(Machine)`).
pub struct Interpreter {
  priv time : Int
  priv addr : @types.Word
  priv curr : Pos
  priv prompts : @list.List[@types.Tid]
  priv last_blk : @types.Tid?
  priv prev_blk : @types.Tid?
}

///|
fn null_addr(p : @project.Project) -> @types.Word {
  let t = p.target()
  let width = if t.code_addr_size() > 0 {
    t.code_addr_size()
  } else {
    target_bits(t)
  }
  try! @types.Word::zero(width~)
}

///|
let interpreter_state : State[Interpreter] = State::declare_(
  uuid="14a17161-173b-46da-9e95-7819104cc220",
  name="interpreter",
  inspect=s => s.curr.to_sexp(),
  p => {
    time: 0,
    addr: null_addr(p),
    curr: Pos::top(p.program()),
    prompts: @list.List::new(),
    last_blk: None,
    prev_blk: None,
  },
)

///|
/// The name of the division-by-zero trap handler.
pub let division_by_zero_handler : String = "__primus_division_by_zero_handler"

///|
/// The name of the page-fault trap handler.
pub let pagefault_handler : String = "__primus_pagefault_handler"

///|
/// The name of the CFI-violation trap handler.
pub let cfi_violation_handler : String = "__primus_cfi_violation_handler"

///|
fn value(m : Machine, w : @types.Word) -> Value {
  Value::of_word(m, w)
}

///|
fn failf(m : Machine, msg : String) -> Value raise {
  m.raise_exn(RuntimeError(msg))
}

///|
/// Halts the machine: posts `halting` and raises `Halt` (`Interpreter.halt`).
pub fn[T] Interpreter::halt(m : Machine) -> T raise {
  m.make(will_halt_stmt, ())
  m.raise_exn(Halt)
}

///|
/// Posts an interrupt (`Interpreter.interrupt`).
pub fn Interpreter::interrupt(m : Machine, n : Int) -> Unit raise {
  m.make(will_interrupt_stmt, n)
}

///|
/// The program counter (`Interpreter.pc`).
pub fn Interpreter::pc(m : Machine) -> @types.Word {
  m.get_local(interpreter_state).addr
}

///|
/// The current position (`Interpreter.pos`).
pub fn Interpreter::pos(m : Machine) -> Pos {
  m.get_local(interpreter_state).curr
}

///|
/// The number of clocks elapsed (`Interpreter.time`).
pub fn Interpreter::time(m : Machine) -> Int {
  m.get_local(interpreter_state).time
}

///|
/// Advances the clock, posting `clock` (`Interpreter.tick`).
pub fn Interpreter::tick(m : Machine) -> Unit raise {
  let s = m.get_local(interpreter_state)
  m.make(clock_stmt, s.time)
  m.put_local(interpreter_state, {
    ..m.get_local(interpreter_state),
    time: s.time + 1,
  })
}

///|
fn call_when_provided(m : Machine, name : String) -> Bool raise {
  if Linker::is_linked(m, Symbol(name)) {
    Linker::exec(m, Symbol(name))
    true
  } else {
    false
  }
}

///|
fn word_of_type(t : @types.ValueType) -> @types.Word {
  match t {
    Imm(w) if w > 0 => try! @types.Word::zero(width=w)
    _ => @types.Word::b0()
  }
}

///|
/// Creates an undefined value of the type, posting `undefined`.
pub fn Interpreter::undefined(m : Machine, t : @types.ValueType) -> Value raise {
  let r = value(m, word_of_type(t))
  m.make(on_undefined_stmt, r)
  r
}

///|
/// Reads a variable, posting `reading` and `read` (`Interpreter.get`).
pub fn Interpreter::get(m : Machine, v : @types.Var) -> Value raise {
  m.make(on_reading_stmt, v)
  let r = Env::get(m, v)
  m.post(on_read_stmt, () => (v, r))
  r
}

///|
/// Applies a unary operation (`Interpreter.unop`).
pub fn Interpreter::unop(
  m : Machine,
  op : @types.UnOp,
  x : Value,
) -> Value raise {
  let r = match op.apply(x.value) {
    Ok(w) => value(m, w)
    Err(msg) => failf(m, msg)
  }
  Interpreter::tick(m)
  m.post(on_unop_stmt, () => ((op, x), r))
  r
}

///|
/// Applies a cast (`Interpreter.cast`).
pub fn Interpreter::cast(
  m : Machine,
  t : @types.CastKind,
  s : Int,
  x : Value,
) -> Value raise {
  let r = match t.apply(s, x.value) {
    Ok(w) => value(m, w)
    Err(msg) => failf(m, msg)
  }
  m.post(on_cast_stmt, () => ((t, s, x), r))
  r
}

///|
/// Concatenates two values (`Interpreter.concat`).
pub fn Interpreter::concat(m : Machine, x : Value, y : Value) -> Value raise {
  let r = value(m, wrap_word(() => x.value.concat(y.value)))
  m.post(on_concat_stmt, () => ((x, y), r))
  r
}

///|
/// Extracts bits `[hi:lo]` (`Interpreter.extract`). Extracting past the
/// width zero-extends.
pub fn Interpreter::extract(
  m : Machine,
  hi~ : Int,
  lo~ : Int,
  x : Value,
) -> Value raise {
  let r = value(m, wrap_word(() => x.value.extract(hi~, lo~)))
  m.post(on_extract_stmt, () => ((hi, lo, x), r))
  r
}

///|
fn coerce(m : Machine, s : Int, x : Value) -> Value raise {
  if x.bitwidth() != s {
    Interpreter::extract(m, hi=s - 1, lo=0, x)
  } else {
    x
  }
}

///|
/// Applies a binary operation (`Interpreter.binop`). Operands of different
/// widths are zero-extended to the wider width. Division by zero posts
/// `division_by_zero` and calls the `division_by_zero_handler` if linked
/// (producing an undefined value), otherwise raises `DivisionByZero`.
pub fn Interpreter::binop(
  m : Machine,
  op : @types.BinOp,
  x : Value,
  y : Value,
) -> Value raise {
  match op {
    Div | SignedDiv | Mod | SignedMod if y.value.is_zero() => {
      m.make(will_divide_by_zero_stmt, ())
      if call_when_provided(m, division_by_zero_handler) {
        Interpreter::undefined(m, Imm(x.bitwidth()))
      } else {
        m.raise_exn(DivisionByZero)
      }
    }
    _ => {
      let s = if x.bitwidth() > y.bitwidth() {
        x.bitwidth()
      } else {
        y.bitwidth()
      }
      let x = coerce(m, s, x)
      let y = coerce(m, s, y)
      let r = match op.apply(x.value, y.value) {
        Ok(w) => value(m, w)
        Err(msg) => failf(m, msg)
      }
      Interpreter::tick(m)
      m.post(on_binop_stmt, () => ((op, x, y), r))
      r
    }
  }
}

///|
/// Creates a constant, posting `const` (`Interpreter.const`).
pub fn Interpreter::constant(m : Machine, w : @types.Word) -> Value raise {
  let r = value(m, w)
  m.make(on_const_stmt, r)
  r
}

///|
/// Selects `yes` if `cond` is one, `no` otherwise (`Interpreter.ite`).
pub fn Interpreter::ite(
  m : Machine,
  cond : Value,
  yes : Value,
  no : Value,
) -> Value raise {
  let r = value(m, if cond.value.is_one() { yes.value } else { no.value })
  m.post(on_ite_stmt, () => ((cond, yes, no), r))
  r
}

///|
/// Assigns a variable, posting `writing` and `written` (`Interpreter.set`).
/// Immediate values are truncated/extended to the variable width.
pub fn Interpreter::set(m : Machine, v : @types.Var, x : Value) -> Unit raise {
  m.make(on_writing_stmt, v)
  let x = match v.typ() {
    Imm(w) if x.bitwidth() != w => Interpreter::extract(m, hi=w - 1, lo=0, x)
    _ => x
  }
  Env::set(m, v, x)
  m.post(on_written_stmt, () => (v, x))
}

///|
fn trapped_memory_access(
  m : Machine,
  access : () -> Value raise,
) -> Value raise {
  access() catch {
    Pagefault(a) => {
      m.make(page_fail_stmt, a)
      if call_when_provided(m, pagefault_handler) {
        access()
      } else {
        m.make(will_segfault_stmt, a)
        m.raise_exn(SegmentationFault(a))
      }
    }
    e => raise e
  }
}

///|
fn load_byte(m : Machine, a : Value) -> Value raise {
  m.make(on_loading_stmt, a)
  let r = trapped_memory_access(m, () => Memory::get(m, a.value))
  Interpreter::tick(m)
  m.post(on_loaded_stmt, () => (a, r))
  r
}

///|
fn store_byte(m : Machine, a : Value, x : Value) -> Unit raise {
  m.make(on_storing_stmt, a)
  ignore(
    trapped_memory_access(m, () => {
      Memory::set(m, a.value, x)
      x
    }),
  )
  Interpreter::tick(m)
  m.post(on_stored_stmt, () => (a, x))
}

///|
fn succ_value(m : Machine, x : Value) -> Value raise {
  let one = Value::one(m, x.bitwidth())
  Interpreter::binop(m, Plus, x, one)
}

///|
fn do_load(m : Machine, a : Value, e : @bitvec.Endian, s : Int) -> Value raise {
  let v = load_byte(m, a)
  if s <= 8 {
    v
  } else {
    let a = succ_value(m, a)
    let u = do_load(m, a, e, s - 8)
    match e {
      LittleEndian => Interpreter::concat(m, u, v)
      BigEndian => Interpreter::concat(m, v, u)
    }
  }
}

///|
/// Loads `size` bits starting at the address, byte by byte
/// (`Interpreter.load`).
pub fn Interpreter::load(
  m : Machine,
  a : Value,
  e : @bitvec.Endian,
  size : @types.Size,
) -> Value raise {
  do_load(m, a, e, size.in_bits())
}

///|
fn load_bits(
  m : Machine,
  a : Value,
  e : @bitvec.Endian,
  bits : Int,
) -> Value raise {
  do_load(m, a, e, bits)
}

///|
fn do_store(
  m : Machine,
  a : Value,
  x : Value,
  s : Int,
  hd : @types.CastKind,
  tl : @types.CastKind,
) -> Unit raise {
  let b = Interpreter::cast(m, hd, 8, x)
  store_byte(m, a, b)
  if s > 8 {
    let a = succ_value(m, a)
    let x = Interpreter::cast(m, tl, s - 8, x)
    do_store(m, a, x, s - 8, hd, tl)
  }
}

///|
fn store_bits(
  m : Machine,
  a : Value,
  x : Value,
  e : @bitvec.Endian,
  s : Int,
) -> Unit raise {
  let x = coerce(m, s, x)
  match e {
    LittleEndian => do_store(m, a, x, s, Low, High)
    BigEndian => do_store(m, a, x, s, High, Low)
  }
}

///|
/// Stores `size` bits of the value starting at the address, byte by byte
/// (`Interpreter.store`).
pub fn Interpreter::store(
  m : Machine,
  a : Value,
  x : Value,
  e : @bitvec.Endian,
  size : @types.Size,
) -> Unit raise {
  store_bits(m, a, x, e, size.in_bits())
}

///|
/// A lexical scope of `let`-bound variables.
priv enum Scope {
  Empty
  Bind(@types.Var, Value, Scope)
}

///|
fn Scope::find(self : Scope, v : @types.Var) -> Value? {
  for s = self {
    match s {
      Empty => break None
      Bind(x, value, rest) =>
        if x.compare(v) == 0 {
          break Some(value)
        } else {
          continue rest
        }
    }
  }
}

///|
fn memory_of_storage(m : Machine, e : @types.Exp) -> Descriptor raise {
  let desc = fn(t : @types.ValueType, name : String) -> Descriptor raise {
    match t {
      Mem(addr_width~, value_width~) =>
        Descriptor::create(addr_size=addr_width, data_size=value_width, name)
      _ =>
        m.raise_exn(
          RuntimeError("type error - load from \{name}:\{t.to_string()}"),
        )
    }
  }
  match e {
    Var(v) => desc(v.typ(), v.name())
    Unknown(_, t) => desc(t, "unknown")
    Store(mem~, ..) | Ite(yes=mem, ..) | Let(_, _, mem) =>
      memory_of_storage(m, mem)
    _ =>
      m.raise_exn(
        RuntimeError("expression `\{e.to_string()}' is not a storage"),
      )
  }
}

///|
fn switch_memory(m : Machine, e : @types.Exp) -> Descriptor raise {
  let d = memory_of_storage(m, e)
  if d != Memory::memory(m) {
    m.make(memory_switch_stmt, d)
    Memory::switch(m, d)
  }
  d
}

///|
fn eval_exp(m : Machine, x : @types.Exp, scope : Scope) -> Value raise {
  m.make(enter_exp_stmt, x)
  let r = match x {
    Load(mem~, addr~, endian~, typ~) => {
      let a = eval_exp(m, addr, scope)
      let d = switch_memory(m, mem)
      eval_storage(m, mem, scope)
      let bits = match typ {
        Imm(w) => w
        _ => d.data_size
      }
      if bits == d.data_size {
        load_byte(m, a)
      } else {
        load_bits(m, a, endian, bits)
      }
    }
    Store(mem~, addr~, value=v, endian~) => {
      let a = eval_exp(m, addr, scope)
      let x = eval_exp(m, v, scope)
      let d = switch_memory(m, mem)
      eval_storage(m, mem, scope)
      if x.bitwidth() == d.data_size {
        store_byte(m, a, x)
      } else {
        store_bits(m, a, x, endian, x.bitwidth())
      }
      a
    }
    BinOp(op, x, y) => {
      let x = eval_exp(m, x, scope)
      let y = eval_exp(m, y, scope)
      Interpreter::binop(m, op, x, y)
    }
    UnOp(op, x) => {
      let x = eval_exp(m, x, scope)
      Interpreter::unop(m, op, x)
    }
    Var(v) =>
      match scope.find(v) {
        Some(r) => r
        None => Interpreter::get(m, v)
      }
    Int(c) => Interpreter::constant(m, c)
    Cast(kind~, width~, exp~) => {
      let x = eval_exp(m, exp, scope)
      Interpreter::cast(m, kind, width, x)
    }
    Unknown(_, t) => Interpreter::undefined(m, t)
    Extract(hi~, lo~, exp~) => {
      let x = eval_exp(m, exp, scope)
      Interpreter::extract(m, hi~, lo~, x)
    }
    Concat(high~, low~) => {
      let x = eval_exp(m, high, scope)
      let y = eval_exp(m, low, scope)
      Interpreter::concat(m, x, y)
    }
    Ite(cond~, yes~, no~) => {
      let yes = eval_exp(m, yes, scope)
      let no = eval_exp(m, no, scope)
      let cond = eval_exp(m, cond, scope)
      Interpreter::ite(m, cond, yes, no)
    }
    Let(v, x, y) => {
      let x = eval_exp(m, x, scope)
      eval_exp(m, y, Bind(v, x, scope))
    }
  }
  m.make(leave_exp_stmt, x)
  r
}

///|
fn eval_storage(m : Machine, mem : @types.Exp, scope : Scope) -> Unit raise {
  match mem {
    Var(_) => ()
    _ => ignore(eval_exp(m, mem, scope))
  }
}

///|
/// Evaluates an expression (`Interpreter.exp`). Multi-byte loads and
/// stores are performed byte by byte through the current memory bank.
pub fn Interpreter::exp(m : Machine, x : @types.Exp) -> Value raise {
  eval_exp(m, x, Empty)
}

///|
fn infer_width(m : Machine, x : @types.Exp) -> Int raise {
  match x.infer_type() {
    Ok(Imm(w)) => w
    _ =>
      m.raise_exn(
        RuntimeError(
          "ill-typed expression, expected a bitvector: \{x.to_string()}",
        ),
      )
  }
}

///|
/// Assigns a value to an lvalue expression (`Interpreter.assign`):
/// variables, `ite`, casts, extracts, loads (stores to memory) and
/// concatenations are supported.
pub fn Interpreter::assign(
  m : Machine,
  rhs : @types.Exp,
  x : Value,
) -> Unit raise {
  match rhs {
    Var(v) => Interpreter::set(m, v, x)
    Ite(cond~, yes~, no~) => {
      let c = Interpreter::exp(m, cond)
      if c.is_one() {
        Interpreter::assign(m, yes, x)
      } else {
        Interpreter::assign(m, no, x)
      }
    }
    Cast(kind=Low, width=part, exp=v) => {
      let width = infer_width(m, v)
      let y = Interpreter::exp(m, v)
      let hi = Interpreter::cast(m, High, width - part, y)
      let x = Interpreter::concat(m, hi, x)
      Interpreter::assign(m, v, x)
    }
    Cast(kind=High, width=part, exp=v) => {
      let width = infer_width(m, v)
      let y = Interpreter::exp(m, v)
      let lo = Interpreter::cast(m, Low, width - part, y)
      let x = Interpreter::concat(m, x, lo)
      Interpreter::assign(m, v, x)
    }
    Cast(exp=v, ..) => {
      let part = infer_width(m, v)
      let x = Interpreter::cast(m, Low, part, x)
      Interpreter::assign(m, v, x)
    }
    Extract(hi~, lo~, exp=v) => {
      let size = infer_width(m, v)
      let y = Interpreter::exp(m, v)
      let x = if hi + 1 < size {
        let h = Interpreter::cast(m, High, size - hi - 1, y)
        Interpreter::concat(m, h, x)
      } else {
        x
      }
      let x = if lo > 0 {
        let l = Interpreter::cast(m, Low, lo, y)
        Interpreter::concat(m, x, l)
      } else {
        x
      }
      Interpreter::assign(m, v, x)
    }
    Load(mem~, addr~, endian~, typ~) => {
      ignore(Interpreter::exp(m, mem))
      let a = Interpreter::exp(m, addr)
      let bits = match typ {
        Imm(w) => w
        _ => x.bitwidth()
      }
      store_bits(m, a, x, endian, bits)
    }
    Concat(high~, low~) => {
      let size = infer_width(m, high)
      let hix = Interpreter::cast(m, High, size, x)
      let lox = Interpreter::cast(m, Low, x.bitwidth() - size, x)
      Interpreter::assign(m, high, hix)
      Interpreter::assign(m, low, lox)
    }
    _ => ignore(failf(m, "not an lvalue: \{rhs.to_string()}"))
  }
}

///|
/// Branches on the value: runs `yes` if it is non-zero, `no` otherwise,
/// posting `eval_cond` with the zero test (`Interpreter.branch`).
pub fn[T] Interpreter::branch(
  m : Machine,
  cnd : Value,
  yes : () -> T raise,
  no : () -> T raise,
) -> T raise {
  let zero = Value::zero(m, cnd.bitwidth())
  let is_zero = Interpreter::binop(m, Eq, cnd, zero)
  m.make(on_cond_stmt, is_zero)
  if is_zero.is_one() {
    no()
  } else {
    yes()
  }
}

///|
/// Runs `body` while `cnd` evaluates to a non-zero value and returns the
/// final (true) stop condition (`Interpreter.repeat`).
pub fn Interpreter::repeat(
  m : Machine,
  cnd : () -> Value raise,
  body : () -> Unit raise,
) -> Value raise {
  for ;; {
    let x = cnd()
    let zero = Value::zero(m, x.bitwidth())
    let stop = Interpreter::binop(m, Eq, x, zero)
    m.make(on_cond_stmt, stop)
    if stop.is_one() {
      break stop
    }
    body()
  }
}
