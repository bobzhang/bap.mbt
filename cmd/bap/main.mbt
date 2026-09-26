// The `bap` executable: a thin native wrapper around `@frontend.run`.

///|
#borrow(data)
extern "c" fn write_ffi(fd : Int, data : Bytes) -> Int = "bap_cli_write"

///|
extern "c" fn read_line_ffi() -> Bytes = "bap_cli_read_line"

///|
extern "c" fn exit_ffi(code : Int) = "bap_cli_exit"

///|
fn write(fd : Int, s : String) -> Unit {
  write_ffi(fd, @utf8.encode(s)) |> ignore
}

///|
fn read_line() -> String? {
  let line = read_line_ffi()
  if line.length() == 0 || line[0] == b'\x00' {
    None
  } else {
    Some(@utf8.decode_lossy(line[1:]))
  }
}

///|
fn main {
  let code = @frontend.run(
    @env.args(),
    env=@env.get_env_var,
    out=s => write(1, s),
    err=s => write(2, s),
    read_line~,
  )
  exit_ffi(code)
}
