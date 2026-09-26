// IO channels (upstream `plugins/primus_lisp/primus_lisp_io.ml`).
//
// The standard channels 0 (input), 1 (output), and 2 (error output) always
// exist; their output is accumulated in the per-fork state (see
// `channel_output`) and their input is provided by the host (see
// `set_channel_input`). As upstream, other channels are opened by
// `channel-open` only for the emulated paths that are redirected to host
// files (`set_redirections`); the host files are accessed with `native_io`,
// so they are only available on the native backend (elsewhere
// `channel-open` fails with the error result).

///|
priv struct Channel {
  /// the input contents and the position of the next byte
  input : Bytes?
  pos : Int
  /// the output, the most recent chunk first
  output : @list.List[String]
  /// the host file of the channel, if any
  file : String?
  /// the contents of the host file when the channel was opened (the
  /// output is appended to them)
  base : Bytes
}

///|
priv struct Io {
  channels : @sorted_map.SortedMap[Int, Channel]
  /// emulated path -> host path
  redirections : @sorted_map.SortedMap[String, String]
}

///|
fn std_channel(input : Bytes?) -> Channel {
  { input, pos: 0, output: @list.empty(), file: None, base: b"", }
}

///|
let io_state : @primus.State[Io] = @primus.State::declare_(
  uuid="f326a07d-16ed-42ec-958d-76ef584cb341",
  name="io-channels",
  _ => {
    channels: @sorted_map.SortedMap::from_iter(
      [
        (0, std_channel(Some(b""))),
        (1, std_channel(None)),
        (2, std_channel(None)),
      ].iter(),
    ),
    redirections: @sorted_map.SortedMap::new(),
  },
)

///|
fn update_channel(m : @primus.Machine, fd : Int, c : Channel) -> Unit {
  m.update_local(io_state, io => { ..io, channels: io.channels.add(fd, c), })
}

///|
/// The contents written to the channel with the descriptor `fd` (e.g.,
/// `1` for the standard output), including the data that was not flushed.
pub fn channel_output(m : @primus.Machine, fd : Int) -> String {
  match m.get_local(io_state).channels.get(fd) {
    None => ""
    Some(c) => c.output.rev().to_array().join("")
  }
}

///|
/// Sets the input of the channel `fd` (e.g., `0` for the standard input).
pub fn set_channel_input(m : @primus.Machine, fd : Int, input : Bytes) -> Unit {
  let c = match m.get_local(io_state).channels.get(fd) {
    Some(c) => { ..c, input: Some(input), pos: 0, }
    None => { ..std_channel(Some(input)), input: Some(input), }
  }
  update_channel(m, fd, c)
}

///|
/// The standard channels (upstream `Primus_lisp_io.standard_channels`).
pub let standard_channels : Array[String] = ["<stdin>", "<stdout>", "<stderr>"]

///|
fn fd_of_channel_name(name : String) -> Int? {
  match name {
    "<stdin>" => Some(0)
    "<stdout>" => Some(1)
    "<stderr>" => Some(2)
    _ => None
  }
}

///|
/// Establishes redirections `(emulated, host)` (upstream `init`): a
/// standard channel (`<stdin>`, `<stdout>`, `<stderr>`) is associated with
/// the host file (the input is read from it, the output replaces its
/// contents when flushed), any other emulated path can be opened with
/// `channel-open` and is associated with the host path.
pub fn set_redirections(
  m : @primus.Machine,
  redirections : Array[(String, String)],
) -> Unit {
  for r in redirections {
    match fd_of_channel_name(r.0) {
      Some(0) =>
        match @native_io.read_file(r.1) {
          Ok(bytes) => set_channel_input(m, 0, bytes)
          Err(_) => set_channel_input(m, 0, b"")
        }
      Some(fd) => {
        let c = match m.get_local(io_state).channels.get(fd) {
          Some(c) => c
          None => std_channel(None)
        }
        update_channel(m, fd, { ..c, file: Some(r.1), base: b"", })
      }
      None =>
        m.update_local(io_state, io => {
          ..io,
          redirections: io.redirections.add(r.0, r.1),
        })
    }
  }
}

///|
fn bytes_of_chunks(base : Bytes, chunks : Array[String]) -> Bytes {
  let buf = Buffer()
  buf.write_bytes(base)
  for c in chunks {
    for ch in c {
      buf.write_byte(ch.to_int().to_byte())
    }
  }
  buf.to_bytes()
}

///|
/// Writes the output of the channel to its host file. Returns `false` on
/// an IO error.
fn flush_channel(m : @primus.Machine, fd : Int) -> Bool {
  match m.get_local(io_state).channels.get(fd) {
    None => false
    Some({ file: None, .. }) => true
    Some({ file: Some(path), base, output, .. }) => {
      let chunks = output.rev().to_array()
      match @native_io.write_file(path, bytes_of_chunks(base, chunks)) {
        Ok(_) => true
        Err(_) => false
      }
    }
  }
}

///|
/// Flushes all channels that are associated with host files (the host
/// channels are flushed when the machine stops, as upstream output channels
/// are flushed at exit).
pub fn flush_channels(m : @primus.Machine) -> Unit {
  for kv in m.get_local(io_state).channels.iter() {
    ignore(flush_channel(m, kv.0))
  }
}

///|
fn io_error(m : @primus.Machine) -> @primus.Value raise {
  @primus.Value::of_word(m, @types.Word::ones(width=addr_width(m)))
}

///|
fn io_ok(m : @primus.Machine) -> @primus.Value raise {
  @primus.Value::zero(m, addr_width(m))
}

///|
fn fd_of_value(v : @primus.Value) -> Int? {
  word_to_int(v.to_word())
}

///|
fn next_fd(io : Io) -> Int {
  match io.channels.rev_keys().head() {
    None => 0
    Some(fd) => fd + 1
  }
}

///|
/// `(channel-open PTR)` (upstream `Open`).
fn channel_open(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [ptr, ..] else { return io_error(m) }
  let path = symbol_of_cstring(m, ptr)
  let io = m.get_local(io_state)
  match io.redirections.get(path) {
    None => io_error(m)
    Some(host) =>
      match @native_io.read_file(host) {
        Err(_) => io_error(m)
        Ok(contents) => {
          let fd = next_fd(io)
          update_channel(m, fd, {
            input: Some(contents),
            pos: 0,
            output: @list.empty(),
            file: Some(host),
            base: contents,
          })
          @primus.Value::of_int(m, width=addr_width(m), fd)
        }
      }
  }
}

///|
/// `(channel-close DESCR)` (upstream `Close`): the unflushed data is
/// discarded.
fn channel_close(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [fd] else { return io_error(m) }
  match fd_of_value(fd) {
    Some(n) if m.get_local(io_state).channels.contains(n) => {
      m.update_local(io_state, io => { ..io, channels: io.channels.remove(n), })
      io_ok(m)
    }
    _ => io_error(m)
  }
}

///|
/// `(channel-flush DESCR)` (upstream `Flush`).
fn channel_flush(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [fd] else { return io_error(m) }
  match fd_of_value(fd) {
    Some(n) => if flush_channel(m, n) { io_ok(m) } else { io_error(m) }
    None => io_error(m)
  }
}

///|
/// `(channel-input DESCR)` (upstream `Input`).
fn channel_input(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [fd] else { return io_error(m) }
  guard fd_of_value(fd) is Some(n) else { return io_error(m) }
  match m.get_local(io_state).channels.get(n) {
    Some({ input: Some(bytes), pos, .. } as c) if pos < bytes.length() => {
      update_channel(m, n, { ..c, pos: pos + 1, })
      @primus.Value::of_int(m, width=addr_width(m), bytes[pos].to_int())
    }
    _ => io_error(m)
  }
}

///|
/// `(channel-output DESCR CHAR ...)` (upstream `Output`): the output of the
/// channels that are associated with host files is buffered until
/// `channel-flush`.
fn channel_output_prim(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [fd, .. chars] else { return io_error(m) }
  guard fd_of_value(fd) is Some(n) else { return io_error(m) }
  match m.get_local(io_state).channels.get(n) {
    Some(c) => {
      let buf = StringBuilder()
      for ch in chars {
        let byte = match word_to_int(resize(ch.to_word(), 8)) {
          Some(b) => b
          None => 0
        }
        buf.write_char(byte.unsafe_to_char())
      }
      update_channel(m, n, { ..c, output: c.output.add(buf.to_string()), })
      io_ok(m)
    }
    None => io_error(m)
  }
}

///|
fn io_primitives(bits : Int) -> Array[(String, Signature, String, Closure)] {
  let int : Typ = Type(bits)
  let byte : Typ = Type(8)
  let sync = (
    f : (@primus.Machine, Array[@primus.Value]) -> @primus.Value raise,
  ) => Closure::sync((m, _, args) => f(m, args))
  [
    (
      "channel-open",
      arrow(Gen([int], int), int),
      "(channel-open PTR) creates a new channel that is associated with a null-terminated path pointed by PTR. Returns a non-negative channel descriptor, if the channel subsystem have a mapping from the obtained path to a physical file and this file is accessible. Otherwise returns a negative value.",
      sync(channel_open),
    ),
    (
      "channel-close",
      arrow(Tuple([int]), int),
      "(channel-close DESCR) closes a channel that has the specified descriptor DESCR. If no such channel exists, then returns -1. Otherwise returns 0. If the channel had any data associated with it and not yet flushed, then the data is discarded.",
      sync(channel_close),
    ),
    (
      "channel-flush",
      arrow(Tuple([int]), int),
      "(channel-flush DESCR) forces data that were written to a channel that has the descriptor DESCR to be outputted to the associated destination. Returns -1 if no such channel exists or if in case of an IO error.",
      sync(channel_flush),
    ),
    (
      "channel-input",
      arrow(Tuple([int]), int),
      "(channel-input DESC) reads one byte from a channel that has the descriptor DESC. Returns -1 if no such channel exists, or if any IO error occurs, if the channel is not readable, or if the channel is in the end-of-file condition.",
      sync(channel_input),
    ),
    (
      "channel-output",
      arrow(Gen([int], byte), int),
      "(channel-output DESCR CHAR ...) outputs one or more characters to a channel that has the descriptor DESCR. Returns -1 if no such channel exits, if a channel is not writable, or if any IO error occurs in an associated physical file. Otherwise, returns 0.",
      sync(channel_output_prim),
    ),
  ]
}

///|
/// Defines the IO primitives and the standard channel variables (upstream
/// `Primus_lisp_io`); the host channels are flushed when the machine
/// stops.
pub fn init_io(m : @primus.Machine) -> Unit raise {
  let width = addr_width(m)
  let set = (name : String, fd : Int) => {
    let v = @types.Var::create(name, Imm(width))
    @primus.Env::set(m, v, @primus.Value::of_int(m, width~, fd))
  }
  set("posix:*standard-input*", 0)
  set("posix:*standard-output*", 1)
  set("posix:*error-output*", 2)
  set("posix:*standard-error*", 2)
  for p in io_primitives(width) {
    define_primitive(m, p.0, types=p.1, docs=p.2, p.3)
  }
  m.observe(@primus.system_stop, _ => flush_channels(m))
}
