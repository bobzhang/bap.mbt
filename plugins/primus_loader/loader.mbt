///|
/// # The generic Primus program loader (upstream `plugins/primus_loader`)
///
/// A basic loader that works more or less correctly for all architectures
/// and ABIs. When the `bap:program-loader` component is initialized it:
///
/// - allocates the stack segment `[stack_base - stack_size, stack_base)`
///   and points the stack pointer register (the target register with the
///   `stack-pointer` role) to `stack_base`;
/// - sets up the main frame just above `stack_base`: `argc` (one address
///   sized word) at `stack_base`, followed by the null-terminated tables
///   of pointers to the command line arguments and to the environment
///   variables, followed by the null-terminated strings themselves; the
///   `posix:environ` variable points to the environment table;
/// - maps the segments described in the specifications of the project
///   (and its libraries) as zero-filled regions (read-only unless the
///   segment is writable), and the memory of the project (and of its
///   libraries) as static data (`.text` sets `etext`, `.data` sets
///   `edata`);
/// - applies the relocations (and, when a base address is specified, the
///   relative relocations) of the specifications;
/// - sets `posix:endp` and `posix:brk` to the first address past the last
///   loaded segment;
/// - adds a zero generator for every register of the target;
/// - sets a variable named after every subroutine and block that has an
///   address to that address.
///
/// Note: the port's memory map is tagged with segment names only; the
/// executability of a memory chunk is taken from the image segment with
/// the same name and address (chunks without a segment are mapped as
/// data).
pub let component_name : String = "program-loader"

///|
/// The default stack size (8 MiB).
pub let default_stack_size : Int = 8 * 1024 * 1024

///|
/// The default address of the stack base (1 GiB).
pub let default_stack_base : Int64 = 0x40000000L

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-loader",
)

///|
fn word_error(what : String) -> Error {
  @primus.RuntimeError("primus-loader: \{what}")
}

///|
fn make_word(m : @primus.Machine, addr : Int64) -> @types.Word raise {
  let width = m.target().code_addr_size()
  let u = addr.reinterpret_as_uint64()
  let u = if width < 64 { u & ((1UL << width) - 1UL) } else { u }
  @types.Word::of_uint64(width~, u) catch {
    _ => raise word_error("invalid address \{addr}")
  }
}

///|
fn set_word(m : @primus.Machine, name : String, x : @types.Word) -> Unit {
  let v = @types.Var::create(name, Imm(x.bitwidth()))
  @primus.Env::set(m, v, @primus.Value::of_word(m, x))
}

///|
/// Converts a Core Theory variable into a BIL variable (`Var.reify`).
fn reify(v : @core_theory.Var) -> @types.Var {
  let sort = v.sort()
  let typ : @types.ValueType = match sort.bitv_size() {
    Some(n) => Imm(n)
    None =>
      match (sort.mem_keys(), sort.mem_values()) {
        (Some(ks), Some(vs)) =>
          Mem(
            addr_width=ks.bitv_size().unwrap_or(0),
            value_width=vs.bitv_size().unwrap_or(0),
          )
        _ => Imm(1)
      }
  }
  @types.Var::new(name=v.name(), typ~, is_virtual=v.is_virtual())
}

///|
/// The stack pointer register of the target, if any.
pub fn stack_pointer(target : @core_theory.Target) -> @types.Var? {
  target.reg(@core_theory.Role::stack_pointer()).map(reify)
}

///|
fn max_word(a : @types.Word, b : @types.Word) -> @types.Word {
  if a.compare(b) >= 0 {
    a
  } else {
    b
  }
}

///|
fn sub_int(w : @types.Word, n : Int) -> @types.Word raise {
  w.sub(@types.Word::of_int(width=w.bitwidth(), n)) catch {
    _ => raise word_error("address underflow")
  }
}

///|
fn setup_stack(
  m : @primus.Machine,
  stack_size : Int,
  stack_base : Int64,
) -> Unit raise {
  let bottom = make_word(m, stack_base)
  let top = sub_int(bottom, stack_size)
  match stack_pointer(m.target()) {
    None => log.warning(message="unable to initialize stack - no stack pointer")
    Some(sp) => {
      @primus.Env::set(m, sp, @primus.Value::of_word(m, bottom))
      @primus.Memory::allocate(
        m,
        read_only=false,
        executable=false,
        top,
        stack_size,
      )
    }
  }
}

///|
fn endian_of_target(target : @core_theory.Target) -> @bitvec.Endian {
  if target.endianness() == @core_theory.Endianness::eb() {
    BigEndian
  } else {
    LittleEndian
  }
}

///|
/// The bytes of the word in the memory order.
fn bytes_of_word(
  word : @types.Word,
  endian : @bitvec.Endian,
) -> Array[@types.Word] raise {
  let n = (word.bitwidth() + 7) / 8
  let bytes = []
  for i in 0..<n {
    let lo = i * 8
    bytes.push(
      word.extract(hi=lo + 7, lo~) catch {
        _ => raise word_error("cannot split a word into bytes")
      },
    )
  }
  if endian is BigEndian {
    bytes.rev_in_place()
  }
  bytes
}

///|
fn save_word(
  m : @primus.Machine,
  force? : Bool = false,
  endian : @bitvec.Endian,
  word : @types.Word,
  ptr : @types.Word,
) -> @types.Word raise {
  let mut ptr = ptr
  for byte in bytes_of_word(word, endian) {
    if force {
      @primus.Memory::store_never_fail(m, ptr, byte)
    } else {
      @primus.Memory::store(m, ptr, byte)
    }
    ptr = ptr.succ()
  }
  ptr
}

///|
/// Reads a word of the width of the pointer (upstream `read_word`).
fn read_word(
  m : @primus.Machine,
  endian : @bitvec.Endian,
  ptr : @types.Word,
) -> @types.Word raise {
  let n = (ptr.bitwidth() + 7) / 8
  let bytes = []
  let mut a = ptr
  for _ in 0..<n {
    bytes.push(@primus.Memory::load(m, a))
    a = a.succ()
  }
  // the most significant byte first
  if endian is LittleEndian {
    bytes.rev_in_place()
  }
  let mut w = bytes[0]
  for i in 1..<bytes.length() {
    w = w.concat(bytes[i]) catch { _ => raise word_error("cannot read a word") }
  }
  w
}

///|
fn save_bytes(
  m : @primus.Machine,
  bytes : BytesView,
  ptr : @types.Word,
) -> @types.Word raise {
  let mut ptr = ptr
  for b in bytes {
    @primus.Memory::store(m, ptr, @types.Word::of_int(width=8, b.to_int()))
    ptr = ptr.succ()
  }
  ptr
}

///|
fn save_string(
  m : @primus.Machine,
  s : String,
  ptr : @types.Word,
) -> @types.Word raise {
  save_bytes(m, @utf8.encode(s), ptr)
}

///|
fn bytes_in_array(xs : Array[String]) -> Int {
  xs.fold(init=0, (sum, s) => sum + @utf8.encode(s).length() + 1)
}

///|
/// Saves the null-terminated strings starting at `ptr`; returns the end
/// pointer and the addresses of the strings.
fn save_args(
  m : @primus.Machine,
  xs : Array[String],
  ptr : @types.Word,
) -> (@types.Word, Array[@types.Word]) raise {
  let mut ptr = ptr
  let ptrs = []
  for s in xs {
    ptrs.push(ptr)
    ptr = save_string(m, s, ptr)
    ptr = save_bytes(m, b"\x00", ptr)
  }
  (ptr, ptrs)
}

///|
fn save_table(
  m : @primus.Machine,
  endian : @bitvec.Endian,
  addrs : Array[@types.Word],
  ptr : @types.Word,
) -> @types.Word raise {
  let mut ptr = ptr
  for addr in addrs {
    ptr = save_word(m, endian, addr, ptr)
  }
  ptr
}

///|
fn setup_main_frame(m : @primus.Machine, stack_base : Int64) -> Unit raise {
  let target = m.target()
  let argv = m.args()
  let envp = m.envp()
  let sp = make_word(m, stack_base)
  let endian = endian_of_target(target)
  let width = target.code_addr_size()
  let argc = @types.Word::of_int(width~, argv.length())
  let bytes_in_addr = width / 8
  let null = Bytes::make(bytes_in_addr, b'\x00')
  let table_size = (xs : Array[String]) => bytes_in_addr * (xs.length() + 1)
  let total_size = bytes_in_addr +
    table_size(argv) +
    table_size(envp) +
    bytes_in_array(argv) +
    bytes_in_array(envp)
  let argv_frame_ptr = sp.nsucc(
    bytes_in_addr + table_size(argv) + table_size(envp),
  )
  let argv_table_ptr = sp.nsucc(bytes_in_addr)
  @primus.Memory::allocate(m, read_only=false, executable=false, sp, total_size)
  let (envp_frame_ptr, argv_table) = save_args(m, argv, argv_frame_ptr)
  let (_, envp_table) = save_args(m, envp, envp_frame_ptr)
  let end_of_argv_table = save_table(m, endian, argv_table, argv_table_ptr)
  let envp_table_ptr = save_bytes(m, null, end_of_argv_table)
  let end_of_envp_table = save_table(m, endian, envp_table, envp_table_ptr)
  let frame_ptr = save_bytes(m, null, end_of_envp_table)
  guard frame_ptr == argv_frame_ptr else {
    raise word_error("inconsistent main frame layout")
  }
  save_word(m, endian, argc, sp) |> ignore
  set_word(m, "posix:environ", envp_table_ptr)
}

///|
fn specifications(proj : @project.Project) -> Array[@image.OgreDoc] {
  [proj.specification(), ..proj.libraries().map(lib => lib.specification())]
}

///|
fn load_segments(m : @primus.Machine) -> @types.Word raise {
  let mut endp = make_word(m, 0L)
  for spec in specifications(m.project()) {
    for seg in spec.get(@image.Scheme::segment()).rev() {
      let (_, w, x) = seg.info
      guard seg.size != 0L else { raise word_error("empty segment") }
      let lower = make_word(m, seg.addr)
      let upper = lower.nsucc((seg.size - 1L).to_int())
      log.info(message="loading segment [\{lower.to_hex()}, \{upper.to_hex()}]")
      @primus.Memory::add_region(
        m,
        lower~,
        upper~,
        read_only=!w,
        executable=x,
        generator=@primus.Generator::static_value(0),
      )
      endp = max_word(endp, upper.succ())
    }
  }
  endp
}

///|
fn is_executable_chunk(
  proj : @project.Project,
  mem : @memory.Memory,
  name : String,
) -> Bool {
  match proj.image() {
    None => false
    Some(image) =>
      image
      .segments()
      .iter()
      .any(seg => {
        seg.name() == name &&
        seg.addr() == mem.min_addr() &&
        seg.is_executable()
      })
  }
}

///|
fn map_memmap(
  m : @primus.Machine,
  memmap : @memory.MemMap[String],
  init : @types.Word,
) -> @types.Word raise {
  let proj = m.project()
  let width = m.target().code_addr_size()
  let addr = (x : UInt64) => {
    @types.Word::of_uint64(width~, x) catch {
      _ => raise word_error("invalid address")
    }
  }
  let mut endp = init
  for entry in memmap.entries() {
    let (mem, name) = entry
    if is_executable_chunk(proj, mem, name) {
      @primus.Memory::add_text(m, mem)
    } else {
      @primus.Memory::add_data(m, mem)
    }
    let lower = addr(mem.min_addr())
    let upper = addr(mem.max_addr())
    log.info(message="mapping segment [\{lower.to_hex()}, \{upper.to_hex()}]")
    match name {
      ".text" => set_word(m, "etext", upper)
      ".data" => set_word(m, "edata", upper)
      _ => ()
    }
    endp = max_word(endp, upper)
  }
  endp
}

///|
fn map_segments(m : @primus.Machine) -> @types.Word raise {
  let proj = m.project()
  let mut endp = map_memmap(m, proj.memory(), make_word(m, 0L))
  for lib in proj.libraries() {
    endp = map_memmap(m, lib.memory(), endp)
  }
  endp
}

///|
fn fixup_one_reloc(
  m : @primus.Machine,
  endian : @bitvec.Endian,
  fixup : Int64,
  addr : Int64,
) -> Unit raise {
  let fixup = make_word(m, fixup)
  let addr = make_word(m, addr)
  log.debug(message="writing \{addr.to_hex()} for relocation \{fixup.to_hex()}")
  save_word(m, force=true, endian, addr, fixup) |> ignore
}

///|
fn fixup_relocs(m : @primus.Machine) -> Unit raise {
  let target = m.target()
  let endian = endian_of_target(target)
  for spec in specifications(m.project()) {
    let rels = spec.get(@image.Scheme::relocation()).rev()
    let rrels = match spec.get(@image.Scheme::base_address()) {
      [] => []
      [base, ..] => {
        let out = []
        for fixup in spec.get(@image.Scheme::relative_relocation()).rev() {
          let v = read_word(m, endian, make_word(m, fixup))
          let v = v.to_uint64() catch {
            _ => raise word_error("invalid relative relocation")
          }
          out.push((fixup, base + v.reinterpret_as_int64()))
        }
        out
      }
    }
    for rel in rels {
      fixup_one_reloc(m, endian, rel.0, rel.1)
    }
    for rel in rrels {
      fixup_one_reloc(m, endian, rel.0, rel.1)
    }
  }
}

///|
fn setup_registers(m : @primus.Machine) -> Unit {
  let zero = @primus.Generator::static_value(0)
  for reg in m.target().vars() {
    @primus.Env::add(m, reify(reg), zero)
  }
}

///|
fn init_names(m : @primus.Machine) -> Unit {
  let names : Map[String, @types.Word] = Map([])
  for sub in m.program().subs() {
    if @primus.term_address(sub) is Some(a) {
      names[sub.name()] = a
    }
    for blk in sub.blks() {
      if @primus.term_address(blk) is Some(a) {
        names[blk.name()] = a
      }
    }
  }
  let keys = names.keys().collect()
  keys.sort()
  for name in keys {
    set_word(m, name, names[name])
  }
}

///|
/// Loads the program into the machine (the `bap:program-loader` component
/// body, upstream `Primus_loader_basic.Make(Param).init`).
pub fn install(
  m : @primus.Machine,
  stack_size? : Int = default_stack_size,
  stack_base? : Int64 = default_stack_base,
) -> Unit raise {
  log.debug(message="setting up stack")
  setup_stack(m, stack_size, stack_base)
  log.debug(message="setting up main frame")
  setup_main_frame(m, stack_base)
  log.debug(message="loading segments")
  let e1 = load_segments(m)
  log.debug(message="mapping segments")
  let e2 = map_segments(m)
  log.debug(message="fixing up relocations")
  fixup_relocs(m)
  log.debug(message="setting up registers")
  let endp = max_word(e1, e2)
  set_word(m, "posix:endp", endp)
  set_word(m, "posix:brk", endp)
  setup_registers(m)
  log.debug(message="initializing names")
  init_names(m)
}

///|
let desc : String = "Initializes the runtime environment. This is a generic loader that should work with most of the ABIs. It loads memory segments, including virtual,  sets up [brk], [end], [edata], [etext], and [environ] variables (see any unix man page for the description of these symbols). Note that ([edata] and [etext] are not guaranteed, while [end] and [brk] are). The loader also initializes all CPU registers to zero and setups and alloocates the main stack frame (copies arguments from the ctxt to the stack), and points the stack-pointer register to the command line arguments. (The environment variables follows the arguments)."

///|
/// Registers the `bap:program-loader` component with the given stack
/// parameters. Idempotent: returns `false` if it was already registered.
pub fn register(
  stack_size? : Int = default_stack_size,
  stack_base? : Int64 = default_stack_base,
) -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m, stack_size~, stack_base~),
    pkg="bap",
    desc~,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the component and adds it to the legacy main system, as the
/// upstream plugin does when it is loaded. Idempotent.
pub fn enable(
  stack_size? : Int = default_stack_size,
  stack_base? : Int64 = default_stack_base,
) -> Unit {
  register(stack_size~, stack_base~) |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m, stack_size~, stack_base~))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-loader"

///|
let doc : String =
  #|generic Primus dynamic loader
  #|
  #|Loads a binary and sets up the environment. This loader is generic and
  #|sets things in an architecture independent way. The loading process is
  #|finished by the backend (target specific) loaders if necessary. The
  #|loader setups stack, prepares a callframe for the main function, fills
  #|it the environment and command line arguments. Finally it loads memory
  #|segments and allocates BSS sections. It also initializes several
  #|variables, that are usually defined by C programs - the environ variable
  #|points to the list of environment variables, endp points to the first
  #|address past the end of the last loaded segment, and brk is the program
  #|break.

///|
/// Declares the `primus-loader` plugin to `bap_main` with its `stack-size`
/// and `stack-base` parameters. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["abi", "loader", "primus", "emulator"],
    doc~,
    () => {
      let stack_size = @bap_main.Configuration::parameter(
        @bap_main.Type::int().with_default(default_stack_size),
        "stack-size",
        doc="the size of the stack",
      )
      let stack_base = @bap_main.Configuration::parameter(
        @bap_main.Type::int64().with_default(default_stack_base),
        "stack-base",
        doc="default address of the stack base",
      )
      @bap_main.Extension::register(ctxt => {
        enable(stack_size=ctxt.get(stack_size), stack_base=ctxt.get(stack_base))
      })
    },
  )
}
