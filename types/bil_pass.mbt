///|
struct BilPass {
  name_value : String
  desc_value : String
  body_value : (Array[Stmt]) -> Array[Stmt]
}

///|
let bil_pass_registry : Map[String, BilPass] = Map([])

///|
let bil_selected_passes : Array[(Array[Stmt]) -> Array[Stmt]] = []

///|
pub fn register_pass(
  name : String,
  body : (Array[Stmt]) -> Array[Stmt],
  desc~ : String = "No description provided",
) -> BilPass {
  let pass = { name_value: name, desc_value: desc, body_value: body, }
  bil_pass_registry[name] = pass
  pass
}

///|
pub fn passes() -> Array[BilPass] {
  let result = []
  bil_pass_registry.each((_, pass) => result.push(pass))
  result.sort_by((left, right) => left.name().compare(right.name()))
  result
}

///|
pub fn select_passes(selected : Array[BilPass]) -> Unit {
  bil_selected_passes.clear()
  for pass in selected {
    bil_selected_passes.push(pass.body_value)
  }
}

///|
pub fn selected_passes() -> Array[(Array[Stmt]) -> Array[Stmt]] {
  bil_selected_passes.copy()
}

///|
pub fn run_selected_passes(stmts : Array[Stmt]) -> Array[Stmt] {
  let mut result = stmts
  for pass in selected_passes() {
    result = pass(result)
  }
  result
}

///|
pub fn BilPass::name(self : BilPass) -> String {
  self.name_value
}

///|
pub fn BilPass::desc(self : BilPass) -> String {
  self.desc_value
}

///|
pub fn BilPass::run(self : BilPass, stmts : Array[Stmt]) -> Array[Stmt] {
  (self.body_value)(stmts)
}

///|
pub fn BilPass::to_string(self : BilPass) -> String {
  self.name_value.pad_end(24, ' ') + " " + self.desc_value
}
