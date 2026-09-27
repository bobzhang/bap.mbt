// The `strings` plugin (upstream `Strings_main`): searches for
// string-like artifacts in the memory of the binary.

///|
/// The name of the plugin.
pub let name : String = "strings"

///|
/// The project storage key of the collected strings (upstream
/// `Beagle_prey.statics`).
pub let statics_key : String = "beagle-prey:statics"

///|
/// Scans the memory region for strings (upstream `scan`): the strings
/// by their addresses.
fn scan(start : UInt64, data : Bytes, strs : Map[UInt64, String]) -> Unit {
  for found in @strings_lib.StringsScanner::scan_bytes(data) {
    let (off, bytes) = found
    let addr = start + off.to_uint64()
    let str = latin1(bytes)
    match strs.get(addr) {
      // keep the longest string (upstream `union`)
      Some(old) if old.length() >= str.length() => ()
      _ => strs[addr] = str
    }
  }
}

///|
fn latin1(bytes : Bytes) -> String {
  let sb = StringBuilder()
  for b in bytes {
    sb.write_char(b.to_int().unsafe_to_char())
  }
  sb.to_string()
}

///|
/// Collects the strings of at least `min_length` characters from the
/// project memory (upstream `collect`), in the order of addresses.
pub fn collect(
  min_length~ : Int,
  proj : @project.Project,
) -> Array[(UInt64, String)] {
  let strs : Map[UInt64, String] = Map([])
  for entry in proj.memory().entries() {
    let mem = entry.0
    scan(mem.min_addr(), mem.to_bytes(), strs)
  }
  let result = []
  for addr, str in strs {
    if str.length() >= min_length {
      result.push((addr, str))
    }
  }
  result.sort_by((a, b) => a.0.compare(b.0))
  result
}

///|
/// Escapes the newline, tab, and carriage return characters (upstream
/// `escape`).
pub fn escape(s : String) -> String {
  let sb = StringBuilder()
  for c in s {
    match c {
      '\n' => sb.write_string("\\n")
      '\t' => sb.write_string("\\t")
      '\r' => sb.write_string("\\r")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// Encodes the strings as the project value: one `<hex-addr> <string>`
/// line per string, with the string escaped.
fn encode(strs : Array[(UInt64, String)]) -> String {
  let sb = StringBuilder()
  for entry in strs {
    let escaped = escape(entry.1.replace_all(old="\\", new="\\\\"))
    sb.write_string("\{entry.0.to_string(radix=16)} \{escaped}\n")
  }
  sb.to_string()
}

///|
fn unescape(s : String) -> String {
  let sb = StringBuilder()
  let mut escaped = false
  for c in s {
    if escaped {
      sb.write_char(
        match c {
          'n' => '\n'
          't' => '\t'
          'r' => '\r'
          c => c
        },
      )
      escaped = false
    } else if c == '\\' {
      escaped = true
    } else {
      sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn parse_hex(s : String) -> UInt64 {
  let mut v = 0UL
  for c in s {
    let d = match c {
      '0'..='9' => c.to_int() - '0'.to_int()
      'a'..='f' => c.to_int() - 'a'.to_int() + 10
      _ => 0
    }
    v = v * 16UL + d.to_uint64()
  }
  v
}

///|
/// The strings stored in the project by the `strings-collect` pass.
pub fn statics(proj : @project.Project) -> Array[(UInt64, String)]? {
  match proj.get(statics_key) {
    None => None
    Some(text) => {
      let out = []
      for line in text.split("\n") {
        let line = line.to_owned()
        if line != "" {
          match line.find(" ") {
            Some(i) =>
              out.push(
                (
                  parse_hex(line.view(end_offset=i).to_owned()),
                  unescape(line.view(start_offset=i + 1).to_owned()),
                ),
              )
            None => ()
          }
        }
      }
      Some(out)
    }
  }
}

///|
/// Renders the strings (upstream `print_str`).
pub fn render(strs : Array[(UInt64, String)], with_address~ : Bool) -> String {
  let sb = StringBuilder()
  for entry in strs {
    let str = escape(entry.1)
    if with_address {
      sb.write_string("\{entry.0.to_string(radix=16)}: \{str}\n")
    } else {
      sb.write_string("\{str}\n")
    }
  }
  sb.to_string()
}

///|
/// The configuration of the passes.
priv struct Config {
  mut min_length : Int
  mut with_address : Bool
  mut out : (String) -> Unit
}

///|
let config : Config = {
  min_length: 4,
  with_address: false,
  out: s => println(s.trim_end(chars="\n")),
}

///|
/// Registers the `strings-collect` and `strings` passes (upstream
/// `Config.declare_extension`); the passes use the latest configuration.
pub fn register(
  min_length? : Int = 4,
  with_address? : Bool = false,
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Result[Unit, String] {
  config.min_length = min_length
  config.with_address = with_address
  config.out = out
  let collect_pass = @project.ProjectPass::create(name="strings-collect", run=proj => {
    Ok(
      proj.set(statics_key, encode(collect(min_length=config.min_length, proj))),
    )
  })
  let print_pass = @project.ProjectPass::create(
    name~,
    deps=["strings-collect"],
    run=proj => {
      match statics(proj) {
        Some(strs) =>
          (config.out)(render(strs, with_address=config.with_address))
        None => ()
      }
      Ok(proj)
    },
  )
  match @project.register_pass_if_absent(collect_pass) {
    Ok(_) => ()
    Err(e) => return Err(e)
  }
  match @project.register_pass_if_absent(print_pass) {
    Ok(_) => Ok(())
    Err(e) => Err(e)
  }
}

///|
/// Declares the `strings` plugin (the `--strings-min-len` and
/// `--strings-print-address` options) in the `bap_main` framework. Does
/// nothing if it is already registered.
pub fn declare_plugin(
  out? : (String) -> Unit = s => println(s.trim_end(chars="\n")),
) -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["pass", "strings"],
    doc="searches in binaries for string-like artifacts",
    () => {
      let min_length = @bap_main.Configuration::parameter(
        doc="ignore strings that has length less then $(docv)",
        aliases=["bytes"],
        @bap_main.Type::int().with_default(4),
        "min-len",
      )
      let address = @bap_main.Configuration::flag(
        doc="prints an address of each found string",
        "print-address",
      )
      @bap_main.Extension::register(ctxt => {
        match
          register(
            min_length=ctxt.get(min_length),
            with_address=ctxt.get(address),
            out~,
          ) {
          Ok(_) => ()
          Err(msg) => fail(msg)
        }
      })
    },
  )
}
