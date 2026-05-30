///|
struct BilMemory {
  addr_width_value : Int
  value_width_value : Int
  cells_value : Map[UInt64, Byte]
} derive(Eq, Debug)

///|
pub(all) enum BilValue {
  BilWord(Word)
  BilMem(BilMemory)
} derive(Eq, Debug)

///|
fn byte_offset(i : Int) -> UInt64 {
  i.to_uint64()
}

///|
fn word_addr(addr : Word) -> Result[UInt64, String] {
  try addr.to_uint64() catch {
    _ => Err("memory address is too wide")
  } noraise {
    value => Ok(value)
  }
}

///|
fn require_byte_memory(memory : BilMemory) -> Result[Unit, String] {
  if memory.value_width_value == 8 {
    Ok(())
  } else {
    Err("only 8-bit memory cells are supported")
  }
}

///|
fn require_byte_width(width : Int) -> Result[Int, String] {
  if width <= 0 || width % 8 != 0 {
    Err("memory access width must be a positive multiple of 8")
  } else {
    Ok(width / 8)
  }
}

///|
fn scalar(value : BilValue) -> Result[Word, String] {
  match value {
    BilWord(word) => Ok(word)
    BilMem(_) => Err("expected scalar value")
  }
}

///|
fn storage(value : BilValue) -> Result[BilMemory, String] {
  match value {
    BilMem(memory) => Ok(memory)
    BilWord(_) => Err("expected memory value")
  }
}

///|
fn eval_scalar(exp : Exp, env : Map[String, BilValue]) -> Result[Word, String] {
  match exp.eval_value(env) {
    Ok(value) => scalar(value)
    Err(reason) => Err(reason)
  }
}

///|
fn eval_storage(
  exp : Exp,
  env : Map[String, BilValue],
) -> Result[BilMemory, String] {
  match exp.eval_value(env) {
    Ok(value) => storage(value)
    Err(reason) => Err(reason)
  }
}

///|
pub fn BilMemory::empty(addr_width~ : Int, value_width? : Int = 8) -> BilMemory {
  {
    addr_width_value: addr_width,
    value_width_value: value_width,
    cells_value: Map([]),
  }
}

///|
pub fn BilMemory::from_bytes(
  addr_width~ : Int,
  start? : UInt64 = 0UL,
  data : Bytes,
) -> BilMemory {
  let cells : Map[UInt64, Byte] = Map([])
  for i in 0..<data.length() {
    cells[start + byte_offset(i)] = data[i]
  }
  { addr_width_value: addr_width, value_width_value: 8, cells_value: cells }
}

///|
pub fn BilMemory::addr_width(self : BilMemory) -> Int {
  self.addr_width_value
}

///|
pub fn BilMemory::value_width(self : BilMemory) -> Int {
  self.value_width_value
}

///|
pub fn BilMemory::cell(self : BilMemory, addr : UInt64) -> Byte? {
  self.cells_value.get(addr)
}

///|
pub fn BilMemory::load(
  self : BilMemory,
  addr : Word,
  endian~ : @bitvec.Endian,
  width~ : Int,
) -> Result[Word, String] {
  match
    (require_byte_memory(self), require_byte_width(width), word_addr(addr)) {
    (Ok(_), Ok(byte_count), Ok(base)) => {
      let data = []
      for i in 0..<byte_count {
        let current = base + byte_offset(i)
        match self.cells_value.get(current) {
          Some(byte) => data.push(byte)
          None => return Err("uninitialized memory at \{current}")
        }
      }
      try Word::from_bytes(Bytes::from_array(data), endian~, width~) catch {
        _ => word_error()
      } noraise {
        word => Ok(word)
      }
    }
    (Err(reason), _, _) | (_, Err(reason), _) | (_, _, Err(reason)) =>
      Err(reason)
  }
}

///|
pub fn BilMemory::store(
  self : BilMemory,
  addr : Word,
  value : Word,
  endian~ : @bitvec.Endian,
) -> Result[BilMemory, String] {
  match (require_byte_memory(self), word_addr(addr)) {
    (Ok(_), Ok(base)) => {
      let bytes = value.to_bytes(endian~)
      let cells = self.cells_value.copy()
      for i in 0..<bytes.length() {
        cells[base + byte_offset(i)] = bytes[i]
      }
      Ok({ ..self, cells_value: cells })
    }
    (Err(reason), _) | (_, Err(reason)) => Err(reason)
  }
}

///|
pub fn BilValue::word(self : BilValue) -> Word? {
  match self {
    BilWord(word) => Some(word)
    BilMem(_) => None
  }
}

///|
pub fn BilValue::memory(self : BilValue) -> BilMemory? {
  match self {
    BilMem(memory) => Some(memory)
    BilWord(_) => None
  }
}

///|
pub fn Exp::eval_value(
  self : Exp,
  env : Map[String, BilValue],
) -> Result[BilValue, String] {
  match self {
    Int(word) => Ok(BilWord(word))
    Var(variable) =>
      match env.get(variable.name) {
        Some(value) => Ok(value)
        None => Err("unbound variable \{variable.name}")
      }
    Unknown(name, _) => Err("unknown expression \{name}")
    Load(mem~, addr~, endian~, typ~) =>
      match typ {
        Imm(width) =>
          match (eval_storage(mem, env), eval_scalar(addr, env)) {
            (Ok(memory), Ok(address)) =>
              memory.load(address, endian~, width~).map(word => BilWord(word))
            (Err(reason), _) | (_, Err(reason)) => Err(reason)
          }
        Mem(_) => Err("memory load result must be an immediate type")
      }
    Store(mem~, addr~, value~, endian~) =>
      match
        (
          eval_storage(mem, env),
          eval_scalar(addr, env),
          eval_scalar(value, env),
        ) {
        (Ok(memory), Ok(address), Ok(word)) =>
          memory.store(address, word, endian~).map(next => BilMem(next))
        (Err(reason), _, _) | (_, Err(reason), _) | (_, _, Err(reason)) =>
          Err(reason)
      }
    Let(variable, value, body) =>
      match value.eval_value(env) {
        Ok(bound) => {
          let next = env.copy()
          next[variable.name] = bound
          body.eval_value(next)
        }
        Err(reason) => Err(reason)
      }
    Cast(typ, exp) =>
      match eval_scalar(exp, env) {
        Ok(word) => cast_word(typ, word).map(next => BilWord(next))
        Err(reason) => Err(reason)
      }
    UnOp(op, exp) =>
      match eval_scalar(exp, env) {
        Ok(word) => eval_unop(op, word).map(next => BilWord(next))
        Err(reason) => Err(reason)
      }
    BinOp(op, lhs, rhs) =>
      match (eval_scalar(lhs, env), eval_scalar(rhs, env)) {
        (Ok(left), Ok(right)) =>
          eval_binop(op, left, right).map(word => BilWord(word))
        (Err(reason), _) | (_, Err(reason)) => Err(reason)
      }
    Ite(cond~, yes~, no~) =>
      match eval_scalar(cond, env) {
        Ok(word) =>
          if word.is_zero() {
            no.eval_value(env)
          } else {
            yes.eval_value(env)
          }
        Err(reason) => Err(reason)
      }
  }
}
