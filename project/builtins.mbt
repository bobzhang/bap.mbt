///|
pub fn register_builtin_services() -> Result[Unit, String] {
  match register_builtin_input_loaders() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_branchers() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_disassembly_drivers() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_builtin_reconstructors() {
    Ok(_) => ()
    Err(reason) => return Err(reason)
  }
  match register_ir_transform_passes() {
    Ok(_) => Ok(())
    Err(reason) => Err(reason)
  }
}
