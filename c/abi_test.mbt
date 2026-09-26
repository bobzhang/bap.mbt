///|
fn cint() -> @c.CType {
  @c.CType::basic(SInt)
}

///|
fn show_args(args : @c.Args?) -> String {
  guard args is Some({ return_, hidden, params, }) else { return "rejected" }
  let lines = []
  if return_ is Some((d, e)) {
    lines.push("return: \{e.to_string()} : \{@c.data_to_string(d)}")
  }
  for h in hidden {
    let (t, (_, e)) = h
    lines.push("hidden: \{e.to_string()} : \{t}")
  }
  for p in params {
    lines.push("param: \{p.1.to_string()} : \{@c.data_to_string(p.0)}")
  }
  lines.join("\n")
}

///|
/// A RISC-V like convention: integers go in registers, then in memory;
/// 64-bit values use an aligned register pair; the return value goes in
/// the return registers.
fn riscv_like(target : @core_theory.Target, proto : @c.Proto) -> @c.Arg[Unit] {
  @c.Arena::iargs(target).bind(iargs => {
    @c.Arena::irets(target).bind(irets => {
      let pass = (regs : @c.Arena, t : @c.CType) => {
        @c.Arg::count(regs, t).bind(count => {
          match count {
            Some(1) =>
              @c.Arg::choice([@c.Arg::register(regs, t), @c.Arg::memory(t)])
            Some(2) =>
              @c.Arg::choice([
                @c.Arg::sequence([
                  @c.Arg::align_even(regs),
                  @c.Arg::registers(limit=2, regs, t),
                ]),
                @c.Arg::split_with_memory(regs, t),
                @c.Arg::memory(t),
              ])
            Some(_) => @c.Arg::reference(regs, t)
            None => @c.Arg::reject()
          }
        })
      }
      let return_ = match proto.return_ {
        Void => @c.Arg::pure(())
        r => pass(irets, r)
      }
      @c.Arg::define_semantics(
        return_~,
        @c.Arg::iter(proto.args, arg => pass(iargs, arg.1)),
      )
    })
  })
}

///|
fn proto_of(args : Array[@c.CType], return_? : @c.CType = Void) -> @c.Proto {
  { return_, args: args.mapi((i, t) => ("x\{i}", t)), variadic: false, }
}

///|
test "arena of roles excludes aliases and is sorted" {
  let t = @core_theory.Target::riscv32()
  let sem = @c.Arena::iargs(t).bind(iargs => {
    @c.Arg::iter(Array::make(8, cint()), a => @c.Arg::register(iargs, a))
  })
  inspect(
    show_args(@c.Arg::reify(t, @c.SizeBase::new(ILP32), sem)),
    content=(
      #|param: X10:imm32 : Top:u32
      #|param: X11:imm32 : Top:u32
      #|param: X12:imm32 : Top:u32
      #|param: X13:imm32 : Top:u32
      #|param: X14:imm32 : Top:u32
      #|param: X15:imm32 : Top:u32
      #|param: X16:imm32 : Top:u32
      #|param: X17:imm32 : Top:u32
    ),
  )
  // the ninth register argument is rejected
  let sem9 = @c.Arena::iargs(t).bind(iargs => {
    @c.Arg::iter(Array::make(9, cint()), a => @c.Arg::register(iargs, a))
  })
  inspect(
    show_args(@c.Arg::reify(t, @c.SizeBase::new(ILP32), sem9)),
    content="rejected",
  )
}

///|
test "registers, memory, and the return value" {
  let t = @core_theory.Target::riscv32()
  let ruler = @c.SizeBase::new(ILP32)
  let proto = proto_of(Array::make(10, cint()), return_=cint())
  inspect(
    show_args(@c.Arg::reify(t, ruler, riscv_like(t, proto))),
    content=(
      #|return: X10:imm32 : Top:u32
      #|param: X10:imm32 : Top:u32
      #|param: X11:imm32 : Top:u32
      #|param: X12:imm32 : Top:u32
      #|param: X13:imm32 : Top:u32
      #|param: X14:imm32 : Top:u32
      #|param: X15:imm32 : Top:u32
      #|param: X16:imm32 : Top:u32
      #|param: X17:imm32 : Top:u32
      #|param: load(mem:mem32x8, X2:imm32):imm32 : Top:u32
      #|param: load(mem:mem32x8, (X2:imm32 + 4:32u)):imm32 : Top:u32
    ),
  )
}

///|
test "aligned register pairs, splitting, and references" {
  let t = @core_theory.Target::riscv32()
  let ruler = @c.SizeBase::new(ILP32)
  let ll = @c.CType::basic(SLongLong)
  // x0 in X10, the pair is aligned to X12:X13, then the pair X14:X15,
  // then x3 in X16, and the last pair is split between X17 and the stack
  let proto = proto_of([cint(), ll, ll, cint(), ll])
  inspect(
    show_args(@c.Arg::reify(t, ruler, riscv_like(t, proto))),
    content=(
      #|param: X10:imm32 : Top:u32
      #|param: concat(X12:imm32, X13:imm32) : Top:u64
      #|param: concat(X14:imm32, X15:imm32) : Top:u64
      #|param: X16:imm32 : Top:u32
      #|param: concat(X17:imm32, load(mem:mem32x8, X2:imm32):imm32) : Top:u64
    ),
  )
  // a structure larger than two words is passed by reference
  let big = @c.CType::structure("big", [
    ("a", cint()),
    ("b", cint()),
    ("c", cint()),
  ])
  inspect(
    show_args(
      @c.Arg::reify(t, ruler, riscv_like(t, proto_of([big], return_=big))),
    ),
    content=(
      #|hidden: X10:imm32 : struct big*
      #|hidden: X10:imm32 : struct big*
    ),
  )
}

///|
test "rejected branches are rolled back" {
  let t = @core_theory.Target::riscv32()
  let ruler = @c.SizeBase::new(ILP32)
  let sem = @c.Arena::iargs(t).bind(iargs => {
    @c.Arg::choice([
      @c.Arg::sequence([
        @c.Arg::register(iargs, cint()),
        @c.Arg::memory(cint()),
        @c.Arg::reject(),
      ]),
      @c.Arg::discard(n=2, iargs).then(@c.Arg::register(iargs, cint())),
    ])
  })
  inspect(
    show_args(@c.Arg::reify(t, ruler, sem)),
    content=(
      #|param: X12:imm32 : Top:u32
    ),
  )
  // an empty choice and a failed requirement are rejections
  inspect(
    show_args(@c.Arg::reify(t, ruler, @c.Arg::choice([]))),
    content="rejected",
  )
  inspect(
    show_args(@c.Arg::reify(t, ruler, @c.Arg::require(false))),
    content="rejected",
  )
  // incomplete types can't be passed
  let sem = @c.Arena::iargs(t).bind(iargs => @c.Arg::register(iargs, Void))
  inspect(show_args(@c.Arg::reify(t, ruler, sem)), content="rejected")
}

///|
test "stack helpers: push, hidden, rebase, deplet, split" {
  let t = @core_theory.Target::riscv32()
  let ruler = @c.SizeBase::new(ILP32)
  let ll = @c.CType::basic(SLongLong)
  // push prepends: the last pushed argument has the minimal address
  let pushed = @c.Arg::sequence([
    @c.Arg::push(cint()),
    @c.Arg::push(@c.CType::basic(Char)),
  ])
  inspect(
    show_args(@c.Arg::reify(t, ruler, pushed)),
    content=(
      #|param: load(mem:mem32x8, X2:imm32):imm8 : Top:u8
      #|param: load(mem:mem32x8, (X2:imm32 + 4:32u)):imm32 : Top:u32
    ),
  )
  let rebased = @c.Arg::sequence([
    @c.Arg::memory(cint()),
    @c.Arg::rebase(2),
    @c.Arg::memory(ll),
  ])
  inspect(
    show_args(@c.Arg::reify(t, ruler, rebased)),
    content=(
      #|param: load(mem:mem32x8, X2:imm32):imm32 : Top:u32
      #|param: load(mem:mem32x8, (X2:imm32 + 0x10:32u)):imm64 : Top:u64
    ),
  )
  let hidden = @c.Arg::hidden(ll)
  inspect(
    show_args(@c.Arg::reify(t, ruler, hidden)),
    content=(
      #|param: load(mem:mem32x8, X2:imm32):imm32 : Top:u64 ptr
    ),
  )
  let depleted = @c.Arena::iargs(t).bind(iargs => {
    @c.Arg::deplet(iargs).then(@c.Arg::register(iargs, cint()))
  })
  inspect(show_args(@c.Arg::reify(t, ruler, depleted)), content="rejected")
  let split = @c.Arena::iargs(t).bind(iargs => {
    @c.Arena::irets(t).bind(irets => @c.Arg::split(iargs, irets, ll))
  })
  inspect(
    show_args(@c.Arg::reify(t, ruler, split)),
    content=(
      #|param: concat(X10:imm32, X10:imm32) : Top:u64
    ),
  )
  let exps = @c.Arena::of_exps([
    @types.Exp::var_exp(@types.Var::create("r1", Imm(16))),
    @types.Exp::var_exp(@types.Var::create("r2", Imm(16))),
  ]).bind(regs => @c.Arg::registers(rev=true, regs, cint()))
  inspect(
    show_args(@c.Arg::reify(t, ruler, exps)),
    content=(
      #|param: concat(r2:imm16, r1:imm16) : Top:u32
    ),
  )
  let size = @c.Arg::size(ll).bind(bits => {
    @c.Arg::alignment(ll).bind(align => {
      @c.Arg::require(bits == 64 && align == 64)
    })
  })
  inspect(show_args(@c.Arg::reify(t, ruler, size)), content="")
}

///|
test "arg intents" {
  let cchar = @c.CType::basic(const_=true, Char)
  debug_inspect(
    [
      @c.arg_intent(cint()),
      @c.arg_intent(@c.CType::pointer(cint())),
      @c.arg_intent(@c.CType::pointer(cchar)),
      @c.arg_intent(@c.CType::pointer(const_=true, cchar)),
      @c.arg_intent(@c.CType::pointer(@c.CType::pointer(cchar))),
      @c.arg_intent(@c.CType::array(cchar)),
      @c.arg_intent(@c.CType::array(cint())),
      @c.arg_intent(@c.CType::pointer(@c.CType::function_([]))),
      @c.arg_intent(@c.CType::pointer(@c.CType::structure("s", [("x", cchar)]))),
      @c.arg_intent(
        @c.CType::pointer(@c.CType::structure("s", [("x", cint())])),
      ),
      @c.arg_intent(@c.CType::structure("s", [("x", cint())])),
      @c.arg_intent(@c.CType::pointer(Void)),
    ],
    content="[In, Both, In, In, Both, In, Both, In, In, Both, In, Both]",
  )
}

///|
test "apply inserts typed arguments into a subroutine" {
  let t = @core_theory.Target::riscv32()
  let ruler : &@c.Ruler = @c.SizeBase::new(ILP32)
  let abi : @c.AbiProcessor = {
    insert_args: (_, _, proto) => @c.Arg::reify(t, ruler, riscv_like(t, proto)),
    apply_attrs: (attrs, sub) => {
      if attrs.is_empty() {
        sub
      } else {
        sub.set_attr(@types.Attr::flag("abi-attrs-applied"))
      }
    },
  }
  let buf = @c.CType::array(size=8, @c.CType::basic(Char))
  let proto : @c.Proto = {
    return_: @c.CType::basic(SShort),
    args: [
      ("fmt", @c.CType::pointer(@c.CType::basic(const_=true, Char))),
      ("", buf),
      ("n", @c.CType::basic(SLongLong)),
    ],
    variadic: true,
  }
  let attrs = [
    @c.Attr::new("format", args=["printf", "1", "2"]),
    @c.Attr::new("nonnull", args=["2"]),
    @c.Attr::new("noreturn"),
  ]
  let sub = @c.apply(abi, ruler, attrs, proto, @types.Sub::create(name="log"))
  debug_inspect(
    sub
    .args()
    .map(arg => {
      (
        @types.Arg::to_string(arg),
        @types.Arg::intent(arg),
        @c.type_tag().get(arg).map(t => t.to_string()),
      )
    }),
    content=(
      #|[
      #|  ("log_fmt :: in imm32 = X10:imm32", Some(In), Some(" const char*")),
      #|  ("log_arg2 :: in out imm32 = X11:imm32", Some(Both), Some("char*")),
      #|  (
      #|    "log_n :: in imm64 = concat(X12:imm32, X13:imm32)",
      #|    Some(In),
      #|    Some("signed long long"),
      #|  ),
      #|  (
      #|    "log_result :: out imm16 = low:16[X10:imm32]",
      #|    Some(Out),
      #|    Some("signed short"),
      #|  ),
      #|]
    ),
  )
  assert_eq(@c.proto_tag().get(sub), Some(proto))
  let args = sub.args()
  assert_eq(args[0].format(), Some("printf"))
  assert_true(args[1].is_nonnull())
  assert_true(sub.is_noreturn() && sub.has_flag("abi-attrs-applied"))
  assert_eq(
    @c.layout_tag().get(args[1]).map(l => l.to_string()),
    Some("*[char : 8]"),
  )
  assert_eq(@c.data_tag().get(args[2]).map(@c.data_to_string), Some("Top:u64"))
  // a processor that produces a wrong number of parameters is ignored
  let bad : @c.AbiProcessor = {
    insert_args: (_, _, _) => Some({ return_: None, hidden: [], params: [], }),
    apply_attrs: (_, sub) => sub,
  }
  let same = @c.apply(bad, ruler, [], proto, @types.Sub::create(name="bad"))
  assert_eq(same.args().length(), 0)
  assert_true(@c.proto_tag().has(same))
}

///|
test "hidden arguments are named and placed before the result" {
  let t = @core_theory.Target::riscv32()
  let ruler : &@c.Ruler = @c.SizeBase::new(ILP32)
  let abi : @c.AbiProcessor = {
    insert_args: (_, _, proto) => @c.Arg::reify(t, ruler, riscv_like(t, proto)),
    apply_attrs: (_, sub) => sub,
  }
  let big = @c.CType::structure("big", [
    ("a", cint()),
    ("b", cint()),
    ("c", cint()),
  ])
  let sub = @c.apply(
    abi,
    ruler,
    [],
    proto_of([cint()], return_=big),
    @types.Sub::create(name="mk"),
  )
  debug_inspect(
    sub.args().map(@types.Arg::to_string),
    content=(
      #|[
      #|  "mk_x0 :: in imm32 = X10:imm32",
      #|  "mk_hidden :: in out imm32 = X10:imm32",
      #|]
    ),
  )
}

///|
test "data models and processor registries" {
  let t = @core_theory.Target::riscv64()
  // the default model is chosen from the target bitness
  assert_eq(@c.model(t).model(), LP64)
  assert_eq(@c.model(@core_theory.Target::riscv32()).model(), LP32)
  @c.define_abi(t, @c.SizeBase::new(LLP64), (_, proto) => riscv_like(t, proto))
  assert_eq(@c.model(t).model(), LLP64)
  guard @c.lookup(t) is Some(abi) else { fail("the ABI is not registered") }
  assert_true(@c.get_processor("riscv64") is Some(_))
  assert_true(@c.get_processor("definitely-not-a-target") is None)
  let args = (abi.insert_args)(
    @types.Sub::create(name="f"),
    [],
    proto_of([cint()], return_=@c.CType::basic(SLong)),
  )
  inspect(
    show_args(args),
    content=(
      #|return: X10:imm64 : Top:u32
      #|param: X10:imm64 : Top:u32
    ),
  )
  try
    @c.define_abi(t, @c.SizeBase::new(LP64), (_, _) => @c.Arg::reject())
  catch {
    err => debug_inspect(err, content="DuplicateAbi(\"riscv64\")")
  } noraise {
    _ => fail("expected a duplicate")
  }
  try @c.register_abi("definitely-not-a-target", abi) catch {
    err =>
      debug_inspect(err, content="InvalidAbiName(\"definitely-not-a-target\")")
  } noraise {
    _ => fail("expected an invalid name")
  }
  try @c.register_model(t, @c.SizeBase::new(LP64)) catch {
    err => debug_inspect(err, content="DuplicateModel(\"target:riscv64\")")
  } noraise {
    _ => fail("expected a duplicate model")
  }
}

///|
test "language combinators" {
  let t = @core_theory.Target::riscv32()
  let ruler = @c.SizeBase::new(ILP32)
  let describe = (proto : @c.Proto) => {
    @c.Arena::iargs(t).bind(iargs => {
      @c.Arena::irets(t).bind(irets => {
        let d = @c.Describer::new(proto)
        d.describe(
          return_=(_, size) => {
            @c.Language::select([
              (@c.Language::is_(size <= 32), x => @c.Arg::register(irets, x)),
              (@c.Language::otherwise(), x => @c.Arg::reference(iargs, x)),
            ])
          },
          (alignment, _) => {
            @c.Language::sequence([
              (
                @c.Language::is_(alignment == 64),
                _ => @c.Arg::align_even(iargs),
              ),
              (
                @c.Language::always(),
                @c.Language::choose([
                  x => @c.Arg::register(iargs, x),
                  x => @c.Arg::registers(limit=2, iargs, x),
                  @c.Arg::memory,
                ]),
              ),
            ])
          },
        )
      })
    })
  }
  let proto = proto_of(
    [cint(), @c.CType::basic(Double)],
    return_=@c.CType::basic(Double),
  )
  inspect(
    show_args(@c.Arg::reify(t, ruler, describe(proto))),
    content=(
      #|hidden: X10:imm32 : double*
      #|param: X11:imm32 : Top:u32
      #|param: concat(X12:imm32, X13:imm32) : Top:u64
    ),
  )
  let is_int : @c.Predicate = x => x.is_integer()
  let is_ptr : @c.Predicate = x => x.is_pointer()
  assert_true(@c.Language::any([is_int, is_ptr])(cint()))
  assert_true(!@c.Language::all([is_int, is_ptr])(cint()))
  assert_true(@c.Language::neither([is_ptr])(cint()))
  assert_true(!@c.Language::never()(cint()))
  let classify = (x : @c.CType) => {
    @c.Arg::pure(if x.is_integer() { 1 } else { 2 })
  }
  let by_class = @c.Arena::iargs(t).bind(iargs => {
    @c.Arg::iter([cint(), @c.CType::basic(Float)], x => {
      @c.Language::case(classify, [
        (1, y => @c.Arg::register(iargs, y)),
        (2, @c.Language::combine([@c.Arg::memory, @c.Arg::memory])),
      ])(x)
    })
  })
  inspect(
    show_args(@c.Arg::reify(t, ruler, by_class)),
    content=(
      #|param: X10:imm32 : Top:u32
      #|param: load(mem:mem32x8, X2:imm32):imm32 : Top:u32
      #|param: load(mem:mem32x8, (X2:imm32 + 4:32u)):imm32 : Top:u32
    ),
  )
  let unmatched = @c.Language::case(classify, [(3, @c.Arg::memory)])(cint())
  inspect(show_args(@c.Arg::reify(t, ruler, unmatched)), content="rejected")
  let none = @c.Language::select([(@c.Language::never(), @c.Arg::memory)])(
    cint(),
  )
  inspect(show_args(@c.Arg::reify(t, ruler, none)), content="rejected")
}

///|
test "api processor" {
  let t = @core_theory.Target::riscv32()
  let ruler : &@c.Ruler = @c.SizeBase::new(ILP32)
  let abi : @c.AbiProcessor = {
    insert_args: (_, _, proto) => @c.Arg::reify(t, ruler, riscv_like(t, proto)),
    apply_attrs: (_, sub) => sub,
  }
  let processor = @c.create_api_processor(ruler, abi)
  assert_eq(processor.language, "c")
  // no parser is provided yet
  match (processor.parse)(api => Some(api + ".h"), ["libc"]) {
    Err(e) =>
      inspect(e, content="Parser error in libc: C parser is not available")
    Ok(_) => fail("expected a parser error")
  }
  @c.provide_parser((_, file) => {
    if file == "libc.h" {
      Ok([
        (
          "puts",
          @c.CType::function_(
            attrs=[@c.Attr::new("nonnull", args=["1"])],
            return_=cint(),
            [("s", @c.CType::pointer(@c.CType::basic(const_=true, Char)))],
          ),
        ),
        ("errno", cint()),
      ])
    } else {
      Err("no such file: \{file}")
    }
  })
  match (processor.parse)(_ => None, ["libm"]) {
    Err(e) => inspect(e, content="Unknown interface: libm")
    Ok(_) => fail("expected an unknown interface")
  }
  match (processor.parse)(api => Some(api), ["libm"]) {
    Err(e) => inspect(e, content="Parser error in libm: no such file: libm")
    Ok(_) => fail("expected a parser error")
  }
  let mapper = match (processor.parse)(api => Some(api + ".h"), ["libc"]) {
    Ok(mapper) => mapper
    Err(e) => fail(e)
  }
  let annotated = @c.proto_tag().set(
    @types.Sub::create(name="done"),
    proto_of([]),
  )
  let program = @types.Program::create(subs=[
    @types.Sub::create(name="puts"),
    @types.Sub::create(name="errno"),
    @types.Sub::create(name="intrinsic").with_intrinsic(),
    annotated,
  ])
  let subs = mapper(program).subs()
  debug_inspect(
    subs.map(sub => {
      (@types.Sub::name(sub), sub.args().map(@types.Arg::to_string))
    }),
    content=(
      #|[
      #|  (
      #|    "puts",
      #|    [
      #|      "puts_s :: in imm32 = X10:imm32",
      #|      "puts_result :: out imm32 = X10:imm32",
      #|    ],
      #|  ),
      #|  ("errno", ["errno_result :: out imm32 = X10:imm32"]),
      #|  ("intrinsic", []),
      #|  ("done", []),
      #|]
    ),
  )
  assert_true(subs[0].args()[0].is_nonnull())
  assert_eq(@c.run_parser(ruler, "libc.h").map(decls => decls.length()), Ok(2))
  assert_true(@c.api_processors().is_empty())
  @c.process_api(processor)
  assert_eq(@c.api_processors().length(), 1)
}

///|
test "stack slots" {
  let t = @core_theory.Target::x86_64()
  debug_inspect(
    [
      @c.stack_slot(t, 0),
      @c.stack_slot(t, 2),
      @c.stack_slot(growsup=true, t, 1),
    ].map(e => e.map(e => e.to_string())),
    content=(
      #|[
      #|  Some("load(mem:mem64x8, RSP:imm64):imm64"),
      #|  Some("load(mem:mem64x8, (RSP:imm64 + 0x10:64u)):imm64"),
      #|  Some("load(mem:mem64x8, (RSP:imm64 - 8:64u)):imm64"),
      #|]
    ),
  )
  assert_eq(
    @c.stack_slot_of_arch(X86_64, 1).map(e => e.to_string()),
    Some("load(mem:mem64x8, (RSP:imm64 + 8:64u)):imm64"),
  )
  assert_eq(@c.stack_slot(@core_theory.Target::unknown(), 0), None)
}
