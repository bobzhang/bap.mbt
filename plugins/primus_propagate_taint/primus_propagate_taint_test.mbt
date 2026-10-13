///|
fn w64(n : Int32) -> @types.Word {
  try! @types.Word::of_int(width=64, n)
}

///|
fn int64(n : Int32) -> @types.Exp {
  Int(w64(n))
}

///|
fn reg(name : String) -> @types.Var {
  @types.Var::create(name, Imm(64))
}

///|
fn mem_var() -> @types.Var {
  @types.Var::create("mem", Mem(addr_width=64, value_width=8))
}

///|
fn load64(addr : @types.Exp) -> @types.Exp {
  Load(mem=Var(mem_var()), addr~, endian=LittleEndian, typ=Imm(64))
}

///|
fn store64(addr : @types.Exp, value : @types.Exp) -> @types.Exp {
  Store(mem=Var(mem_var()), addr~, value~, endian=LittleEndian)
}

///|
fn def(
  name : String,
  v : @types.Var,
  e : @types.Exp,
) -> @types.Term[@types.Def] {
  @types.Def::create(v, e, tid=@types.Tid::for_name(name))
}

///|
/// Runs `main` with all components of the plugin, the
/// propagate-by-computation policy and 32 bytes of memory at 0x1000.
/// Returns the final program and the report produced by `fini`.
fn run(
  blks : Array[@types.Term[@types.Blk]],
  fini~ : (@primus.Machine) -> Unit raise = _ => (),
) -> (String, @types.Term[@types.Program]) {
  let main = @types.Sub::create(name="main", blks~)
  let prog = @types.Program::create(subs=[main])
  let proj = @project.Project::empty(@core_theory.Target::x86_64()).with_program(
    prog,
  )
  let (status, proj) = @primus.Machine::run(
    proj,
    init=m => {
      @primus.Interpreter::link_program(m)
      @primus.Memory::allocate(m, w64(0x1000), 32)
      @taint.propagate_by_computation(m)
      @taint.Policy::set_default(
        m,
        @taint.Policy::of_name(m, @taint.computation_policy_name),
      )
      @primus_propagate_taint.intro_component(m)
      @primus_propagate_taint.mapper_component(m)
      @primus_propagate_taint.marker_component(m)
    },
    start=m => @primus.Linker::schedule_exec(m, Symbol("main")),
    fini~,
  )
  (status.to_string(), proj.program())
}

///|
fn attrs(prog : @types.Term[@types.Program]) -> Array[String] {
  let out = []
  let add = (tid : @types.Tid, regs : String?, ptrs : String?) => {
    match (regs, ptrs) {
      (None, None) => ()
      _ =>
        out.push(
          "\{tid.to_string()}: regs=\{regs.unwrap_or("-")} ptrs=\{ptrs.unwrap_or("-")}",
        )
    }
  }
  for sub in prog.subs() {
    for blk in sub.blks() {
      for d in blk.defs() {
        add(
          d.tid(),
          d.get_attr(@taint.tainted_regs_attr),
          d.get_attr(@taint.tainted_ptrs_attr),
        )
      }
      for j in blk.jmps() {
        add(
          j.tid(),
          j.get_attr(@taint.tainted_regs_attr),
          j.get_attr(@taint.tainted_ptrs_attr),
        )
      }
    }
  }
  out
}

///|
fn seeds(
  m : @primus.Machine,
  objs : @sorted_set.SortedSet[@taint.Object],
) -> String {
  objs
  .to_array()
  .map(o => {
    match @primus_propagate_taint.seed_of(m, o) {
      Some(t) => t.to_string()
      None => "?"
    }
  })
  .join(",")
}

///|
test "taints introduced from tainted-reg are reflected to term attributes" {
  let x = reg("x")
  let y = reg("y")
  let z = reg("z")
  let w = reg("w")
  let q = reg("q")
  let r = reg("r")
  let seed = @types.Tid::for_name("seed")
  let exit = @types.Blk::create(tid=@types.Tid::for_name("exit"))
  let b0 = @types.Blk::create(
    defs=[
      def("d1", x, int64(5)).set_attr(@types.Attr::tainted_reg(seed)),
      def("d2", y, BinOp(Plus, Var(x), int64(1))),
      def("d3", mem_var(), store64(int64(0x1000), Var(y))),
      def("d4", z, load64(int64(0x1000))),
      def("d5", w, BinOp(Plus, Var(z), int64(0))),
      def("d6", q, int64(0x1000)),
      def("d7", r, load64(Var(q))),
    ],
    jmps=[
      @types.Jmp::create_goto(
        Direct(exit.tid()),
        cond=BinOp(Eq, Var(w), int64(6)),
        tid=@types.Tid::for_name("j"),
      ),
    ],
  )
  let report = []
  let (status, prog) = run([b0, exit], fini=m => {
    let d2 = @types.Tid::for_name("d2")
    report.push(
      "mapper d2: \{@primus_propagate_taint.tainted_regs(m, d2)} \{@primus_propagate_taint.tainted_ptrs(m, d2)}",
    )
    report.push(
      "x: \{seeds(m, @taint.Tracker::lookup(m, @primus.Env::get(m, x), Direct))}",
    )
    report.push(
      "kinds: \{@taint.Tracker::objects(m).to_array().map(o => (try! o.kind(m)).name(m)).join(",")}",
    )
  })
  inspect(status, content="Normal")
  debug_inspect(
    attrs(prog),
    content=(
      #|[
      #|  "@d2: regs=((x (@seed))) ptrs=-",
      #|  "@d3: regs=((y (@seed))) ptrs=-",
      #|  "@d5: regs=((z (@seed))) ptrs=-",
      #|  "@d7: regs=- ptrs=((q (@seed)))",
      #|  "@j: regs=((w (@seed))) ptrs=-",
      #|]
    ),
  )
  debug_inspect(
    report,
    content=(
      #|["mapper d2: ((x (@seed))) ()", "x: @seed", "kinds: user-@seed"]
    ),
  )
}

///|
test "tainted-ptr on a load taints the dereferenced pointer" {
  let p = reg("p")
  let x = reg("x")
  let y = reg("y")
  let seed = @types.Tid::for_name("pseed")
  let b0 = @types.Blk::create(defs=[
    def("s1", mem_var(), store64(int64(0x1000), int64(0x1010))),
    def("s2", p, int64(0x1000)),
    def("s3", x, load64(Var(p))).set_attr(@types.Attr::tainted_ptr(seed)),
    def("s4", y, load64(Var(x))),
  ])
  let report = []
  let (status, prog) = run([b0], fini=m => {
    for a in [0x1000, 0x1010] {
      let v = @primus.Value::of_word(m, w64(a))
      report.push(
        "indirect \{a}: \{seeds(m, @taint.Tracker::lookup(m, v, Indirect))}",
      )
    }
    report.push(
      "y: \{seeds(m, @taint.Tracker::lookup(m, @primus.Env::get(m, y), Direct))}",
    )
  })
  inspect(status, content="Normal")
  debug_inspect(
    attrs(prog),
    content=(
      #|["@s4: regs=- ptrs=((x (@pseed)))"]
    ),
  )
  debug_inspect(
    report,
    content=(
      #|["indirect 4096: ", "indirect 4112: @pseed", "y: @pseed"]
    ),
  )
}

///|
test "tainted-reg on loads and stores taints the address" {
  let x = reg("x")
  let y = reg("y")
  let b0 = @types.Blk::create(defs=[
    def("l1", x, load64(int64(0x1000))).set_attr(
      @types.Attr::tainted_reg(@types.Tid::for_name("lseed")),
    ),
    def("l2", y, int64(3)),
    def("l3", mem_var(), store64(int64(0x1008), Var(y))).set_attr(
      @types.Attr::tainted_reg(@types.Tid::for_name("sseed")),
    ),
  ])
  let report = []
  let (status, _) = run([b0], fini=m => {
    for a in [0x1000, 0x1001, 0x1008] {
      let v = @primus.Value::of_word(m, w64(a))
      report.push(
        "indirect \{a}: \{seeds(m, @taint.Tracker::lookup(m, v, Indirect))}",
      )
    }
    report.push(
      "x: \{seeds(m, @taint.Tracker::lookup(m, @primus.Env::get(m, x), Direct))}",
    )
  })
  inspect(status, content="Normal")
  debug_inspect(
    report,
    content=(
      #|[
      #|  "indirect 4096: @lseed",
      #|  "indirect 4097: ",
      #|  "indirect 4104: @sseed",
      #|  "x: @lseed",
      #|]
    ),
  )
}

///|
test "configuration" {
  let first = @primus_propagate_taint.register()
  let again = @primus_propagate_taint.register()
  inspect(
    "\{first} \{again}",
    content=(
      #|3 0
    ),
  )
  try @primus_propagate_taint.enable(from_attributes=true, run=true) catch {
    e =>
      debug_inspect(
        e,
        content=(
          #|ConfigError("Incorrect mix of old and new parameters")
        ),
      )
  } noraise {
    _ => fail("expected a configuration error")
  }
  try @primus_propagate_taint.enable(no_marks=true) catch {
    e =>
      debug_inspect(
        e,
        content=(
          #|ConfigError("The no-marks option is only valid if the run option is specified")
        ),
      )
  } noraise {
    _ => fail("expected a configuration error")
  }
  debug_inspect(
    @primus_propagate_taint.enabled(),
    content=(
      #|(false, false)
    ),
  )
  @primus_propagate_taint.enable(run=true, no_marks=true)
  debug_inspect(
    @primus_propagate_taint.enabled(),
    content=(
      #|(true, false)
    ),
  )
  @primus_propagate_taint.enable(to_attributes=true)
  debug_inspect(
    @primus_propagate_taint.enabled(),
    content=(
      #|(true, true)
    ),
  )
}
