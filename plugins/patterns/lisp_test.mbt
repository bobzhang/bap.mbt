///|
test "actions are dispatched through the Lisp methods" {
  let rules = @patterns.load(
    ["/ghidra"],
    @core_theory.Target::x86_64(),
    fs=corpus_fs(),
  )
  let code = memory(
    0x1000, b"\xc3\x55\x48\x89\xe5\x90\xf3\x0f\x1e\xfa\x90\xeb\x10\x48\x83\xec\x20\x90\x48\x89\x5c\x24\x08\x90\x90",
  )
  let program = @patterns.load_actions_program(@core_theory.Target::x86_64())
  let lisp = @patterns.analyze_lisp(
    rules,
    [code],
    program,
    target=@core_theory.Target::x86_64(),
  )
  // the default Lisp method agrees with the native handler
  assert_eq(lisp, @patterns.analyze(rules, [code]))
  debug_inspect(
    lisp,
    content=(
      #|{ roots: [4097, 4102, 4109, 4114], names: [] }
    ),
  )
}

///|
test "custom Lisp methods and patterns-attribute" {
  let extra =
    #|(in-package bap)
    #|(declare (context (patterns enabled)))
    #|(defmethod patterns-action (action addr attrs)
    #|  (when (= action 'setcontext)
    #|    (when (= (patterns-attribute attrs :name) 'TMode)
    #|      (promise-function-start (+ addr 1)))))
  let arm = @patterns.Rules::create(@patterns.parse_patterns(arm_xml).unwrap())
  let mem = memory(
    0x100, b"\x00\xb5\x10\xe9\x2d\x48\x00\xe2\x4d\xd0\x08\x00\x00",
  )
  let program = @patterns.load_actions_program(@core_theory.Target::armeb(), extra=[
    ("thumb.lisp", extra),
  ])
  let outcome = @patterns.analyze_lisp(arm, [mem], program)
  debug_inspect(
    outcome,
    content=(
      #|{ roots: [257, 258, 259, 260], names: [] }
    ),
  )
}

///|
test "analyze_image falls back to the native handlers" {
  let seg = @image.Segment::create(
    name="text",
    endian=LittleEndian,
    addr=0x400000,
    b"\xf3\x0f\x1e\xfa\xc3\x55\x48\x89\xe5\xc3\x00",
    executable=true,
  )
  let image = @image.Image::from_segments(
    entry=0x400000,
    endian=LittleEndian,
    [seg],
    target=@core_theory.Target::x86_64(),
  )
  let rules = @patterns.load(
    ["/ghidra"],
    @core_theory.Target::x86_64(),
    fs=corpus_fs(),
  )
  let native = @patterns.analyze(rules, @patterns.code_regions(image))
  // a broken extra source makes the Lisp program fail to load
  @patterns.set_action_semantics(extra=[("broken.lisp", "(defun oops (")])
  assert_eq(@patterns.analyze_image(image, rules), native)
  @patterns.set_action_semantics(lisp=false)
  assert_eq(@patterns.analyze_image(image, rules), native)
  @patterns.set_action_semantics()
  assert_eq(@patterns.analyze_image(image, rules), native)
}
