///|
struct BilState {
  values_value : Map[String, BilValue]
} derive(Eq, Debug)

///|
pub fn BilState::new() -> BilState {
  { values_value: Map([]) }
}

///|
pub fn BilState::from_values(values : Map[String, BilValue]) -> BilState {
  { values_value: values.copy() }
}

///|
pub fn BilState::values(self : BilState) -> Map[String, BilValue] {
  self.values_value.copy()
}

///|
pub fn BilState::get(self : BilState, name : String) -> BilValue? {
  self.values_value.get(name)
}

///|
pub fn BilState::get_var(self : BilState, variable : Var) -> BilValue? {
  self.get(variable.name)
}

///|
pub fn BilState::get_word(self : BilState, name : String) -> Word? {
  match self.get(name) {
    Some(value) => value.word()
    None => None
  }
}

///|
pub fn BilState::get_memory(self : BilState, name : String) -> BilMemory? {
  match self.get(name) {
    Some(value) => value.memory()
    None => None
  }
}

///|
pub fn BilState::set(
  self : BilState,
  name : String,
  value : BilValue,
) -> BilState {
  let values = self.values_value.copy()
  values[name] = value
  { values_value: values }
}

///|
fn value_fits(variable : Var, value : BilValue) -> Bool {
  match (variable.typ, value) {
    (Imm(width), BilWord(word)) => word.width() == width
    (Mem(addr_width~, value_width~), BilMem(memory)) =>
      memory.addr_width() == addr_width && memory.value_width() == value_width
    _ => false
  }
}

///|
pub fn BilState::set_var(
  self : BilState,
  variable : Var,
  value : BilValue,
) -> Result[BilState, String] {
  if value_fits(variable, value) {
    Ok(self.set(variable.name, value))
  } else {
    Err("value does not match type of \{variable.name}")
  }
}

///|
fn consume_fuel(fuel : Ref[Int]) -> Result[Unit, String] {
  if fuel.val <= 0 {
    Err("BIL statement fuel exhausted")
  } else {
    fuel.val = fuel.val - 1
    Ok(())
  }
}

///|
fn eval_condition(cond : Exp, state : BilState) -> Result[Bool, String] {
  match cond.eval_value(state.values_value) {
    Ok(BilWord(word)) => Ok(!word.is_zero())
    Ok(BilMem(_)) => Err("condition evaluated to memory")
    Err(reason) => Err(reason)
  }
}

///|
fn exec_stmt(
  stmt : Stmt,
  state : BilState,
  fuel : Ref[Int],
) -> Result[BilState, String] {
  match consume_fuel(fuel) {
    Err(reason) => Err(reason)
    Ok(_) =>
      match stmt {
        Move(variable, exp) =>
          match exp.eval_value(state.values_value) {
            Ok(value) => state.set_var(variable, value)
            Err(reason) => Err(reason)
          }
        Jmp(exp) =>
          match exp.eval_value(state.values_value) {
            Ok(BilWord(_)) => Ok(state)
            Ok(BilMem(_)) => Err("jump target evaluated to memory")
            Err(reason) => Err(reason)
          }
        Special(_) => Ok(state)
        CpuExn(code) => Err("CPU exception \{code}")
        If(cond~, yes~, no~) =>
          match eval_condition(cond, state) {
            Ok(true) => exec_sequence(yes, state, fuel)
            Ok(false) => exec_sequence(no, state, fuel)
            Err(reason) => Err(reason)
          }
        While(cond~, body~) => {
          let mut current = state
          let mut running = true
          while running {
            match consume_fuel(fuel) {
              Err(reason) => return Err(reason)
              Ok(_) =>
                match eval_condition(cond, current) {
                  Ok(true) =>
                    match exec_sequence(body, current, fuel) {
                      Ok(next) => current = next
                      Err(reason) => return Err(reason)
                    }
                  Ok(false) => running = false
                  Err(reason) => return Err(reason)
                }
            }
          }
          Ok(current)
        }
      }
  }
}

///|
fn exec_sequence(
  stmts : Array[Stmt],
  state : BilState,
  fuel : Ref[Int],
) -> Result[BilState, String] {
  let mut current = state
  for stmt in stmts {
    match exec_stmt(stmt, current, fuel) {
      Ok(next) => current = next
      Err(reason) => return Err(reason)
    }
  }
  Ok(current)
}

///|
pub fn exec_stmts(
  stmts : Array[Stmt],
  state? : BilState,
  max_steps? : Int = 10000,
) -> Result[BilState, String] {
  let fuel = Ref(max_steps)
  let initial = match state {
    Some(value) => value
    None => BilState::new()
  }
  exec_sequence(stmts, initial, fuel)
}

///|
pub fn Stmt::exec(
  self : Stmt,
  state? : BilState,
  max_steps? : Int = 10000,
) -> Result[BilState, String] {
  exec_stmts([self], state?, max_steps~)
}
