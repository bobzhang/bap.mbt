// The Lisp-to-BIL compiler on hand-written definitions.

///|
fn custom_lifter(src : String) -> @primus_lisp.Lifter raise {
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files([("insns.lisp", src)]),
    @primus_lisp.Loader::embedded(["semantics/primus", "lisp"]),
  ])
  let prog = @primus_lisp.load_program(loader, ["core", "insns"])
  @primus_lisp.Lifter::create(prog, @core_theory.Target::riscv64())
}

///|
fn lift_custom(
  lifter : @primus_lisp.Lifter,
  name : String,
  ops : Array[@primus_lisp.Operand],
  out~ : StringBuilder = StringBuilder(),
) -> String raise {
  show_bil(lifter.lift(@knowledge.Name::read(name), ops, out~))
}

///|
fn exec_bil(
  lifter : @primus_lisp.Lifter,
  name : String,
  ops : Array[@primus_lisp.Operand],
  inputs : Array[(String, Int32)],
  output : String,
) -> String raise {
  let bil = lifter.lift(@knowledge.Name::read(name), ops).unwrap()
  let mut state = @types.BilState::new()
  for i in inputs {
    state = state.set(i.0, BilWord(w(64, i.1)))
  }
  match @types.exec_stmts(bil, state~) {
    Ok(s) => s.get_word(output).unwrap().to_string()
    Err(e) => "error: \{e}"
  }
}

///|
test "static and dynamic control flow" {
  let lifter = custom_lifter(
    (
      #|(defun UNROLL (rd rs)
      #|  (let ((i 0) (acc 0))
      #|    (while (< i 3)
      #|      (set acc (+ acc rs))
      #|      (incr i))
      #|    (set$ rd acc)))
      #|(defun COUNTDOWN (rd rs)
      #|  (let ((n rs) (k 0))
      #|    (while (> n 0)
      #|      (set n (- n 1))
      #|      (set k (+ k 2)))
      #|    (set$ rd k)))
      #|(defun SELECT (rd rs imm)
      #|  (if (= imm 0) (set$ rd rs) (set$ rd (lnot rs))))
      #|(defun MAXU (rd rs rt)
      #|  (set$ rd (if (< rs rt) rt rs)))
      #|(defun NOISY (rd imm)
      #|  (msg "imm=$0" imm)
      #|  (set$ rd imm))
      #|(defun BAD () (error "unsupported"))
    ),
  )
  inspect(
    lift_custom(lifter, "UNROLL", [Reg("X1"), Reg("X2")]),
    content=(
      #|%#2:imm64 := (0:64u + X2:imm64)
      #|%#2:imm64 := (%#2:imm64 + X2:imm64)
      #|%#2:imm64 := (%#2:imm64 + X2:imm64)
      #|X1:imm64 := %#2:imm64
      #|
    ),
  )
  inspect(
    exec_bil(lifter, "UNROLL", [Reg("X1"), Reg("X2")], [("X2", 7)], "X1"),
    content="0x15:64u",
  )
  inspect(
    exec_bil(lifter, "COUNTDOWN", [Reg("X1"), Reg("X2")], [("X2", 5)], "X1"),
    content=(
      #|0xA:64u
    ),
  )
  inspect(
    lift_custom(lifter, "SELECT", [Reg("X1"), Reg("X2"), Imm(0)]),
    content=(
      #|X1:imm64 := X2:imm64
      #|
    ),
  )
  inspect(
    lift_custom(lifter, "SELECT", [Reg("X1"), Reg("X2"), Imm(1)]),
    content=(
      #|X1:imm64 := (not X2:imm64)
      #|
    ),
  )
  inspect(
    exec_bil(
      lifter,
      "MAXU",
      [Reg("X1"), Reg("X2"), Reg("X3")],
      [("X2", 3), ("X3", 9)],
      "X1",
    ),
    content="9:64u",
  )
  let out = StringBuilder()
  inspect(
    lift_custom(lifter, "NOISY", [Reg("X1"), Imm(42)], out~),
    content=(
      #|X1:imm64 := 0x2A:64u
      #|
    ),
  )
  inspect(
    out.to_string(),
    content=(
      #|imm=0x000000000000002a
      #|
    ),
  )
  let err = try lift_custom(lifter, "BAD", []) catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
  inspect(err, content="error: unsupported")
}
