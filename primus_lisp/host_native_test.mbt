// Host files: channels and user folders (native backend only).

///|
fn fresh_dir(name : String) -> String {
  @native_io.mkdir_p("_build/primus-lisp-tests").unwrap()
  @native_io.make_temp_dir(dir="_build/primus-lisp-tests", prefix=name).unwrap()
}

///|
fn read_text(path : String) -> String {
  match @native_io.read_file(path) {
    Ok(b) => @utf8.decode_lossy(b)
    Err(e) => "<error: \{e}>"
  }
}

///|
test "channels on host files" {
  let dir = fresh_dir("channels")
  let data = dir + "/data.txt"
  let dropped = dir + "/dropped.txt"
  let out = dir + "/stdout.txt"
  @native_io.write_file(data, b"abc").unwrap()
  @native_io.write_file(dropped, b"keep").unwrap()
  let prog = lisp_program(
    (
      #|(defun copy (path other missing)
      #|  (let ((fd (channel-open path))
      #|        (c1 (channel-input fd))
      #|        (c2 (channel-input fd)))
      #|    (msg "fd=$0 read $1 $2" fd c1 c2)
      #|    (channel-output fd ?x ?y ?z)
      #|    (msg "flush $0" (channel-flush fd))
      #|    (msg "close $0" (channel-close fd))
      #|    (msg "closed input $0" (channel-input fd))
      #|    (let ((fd2 (channel-open other)))
      #|      (channel-output fd2 ?!)
      #|      (channel-close fd2))
      #|    (msg "not redirected $0" (channel-open missing))
      #|    (channel-output 1 ?o ?k)))
    ),
  )
  let log : Array[String] = []
  let (status, _) = @primus.Machine::run(
    empty_project(),
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, prog)
      @primus_lisp.set_redirections(m, [
        ("/emu/data", data),
        ("/emu/dropped", dropped),
        ("<stdout>", out),
      ])
      store_string(m, 0x1000, "/emu/data")
      store_string(m, 0x2000, "/emu/dropped")
      store_string(m, 0x3000, "/emu/missing")
      m.observe(@primus_lisp.message, s => log.push(s))
    },
    start=m => {
      @primus_lisp.eval_fun(m, "copy", [
        @primus.Value::of_word(m, w64(0x1000)),
        @primus.Value::of_word(m, w64(0x2000)),
        @primus.Value::of_word(m, w64(0x3000)),
      ])
    },
  )
  inspect(status, content="Normal")
  debug_inspect(
    log,
    content=(
      #|[
      #|  "fd=3:64u read 0x61:64u 0x62:64u",
      #|  "flush 0:64u",
      #|  "close 0:64u",
      #|  "closed input 0xFFFFFFFFFFFFFFFF:64u",
      #|  "not redirected 0xFFFFFFFFFFFFFFFF:64u",
      #|]
    ),
  )
  // the output is appended to the file when flushed
  inspect(read_text(data), content="abcxyz")
  // the unflushed data is discarded when the channel is closed
  inspect(read_text(dropped), content="keep")
  // the redirected standard output is written when the machine stops
  inspect(read_text(out), content="ok")
}

///|
test "user semantics folders" {
  let dir = fresh_dir("semantics")
  @native_io.write_file(
    dir + "/custom.lisp",
    b"(declare (context (target riscv)))\n(in-package riscv)\n(defun CUSTOM (rd) (set$ rd 42))\n",
  ).unwrap()
  @native_io.write_file(dir + "/notes.txt", b"ignored").unwrap()
  inspect(@primus_lisp.folder_features([dir]).join(","), content="custom")
  let lifter = @primus_lisp.load_semantics(
    @core_theory.Target::riscv64(),
    @primus_lisp.semantic_dirs,
    paths=[dir],
  )
  inspect(
    show_bil(
      lifter.lift(@knowledge.Name::create("CUSTOM", pkg="llvm-riscv64"), [
        Reg("X5"),
      ]),
    ),
    content=(
      #|X5:imm64 := 0x2A:64u
      #|
    ),
  )
  let err = try
    @primus_lisp.load_semantics(@core_theory.Target::riscv64(), [], paths=[
      dir + "/nope",
    ])
  catch {
    e => e.to_string().contains("the path must exist and be a folder")
  } noraise {
    _ => false
  }
  inspect(err, content="true")
}
