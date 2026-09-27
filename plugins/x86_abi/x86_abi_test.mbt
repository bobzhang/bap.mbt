// Tests of the x86 calling conventions.

///|
/// Applies the ABI of `target` to stubs of the functions declared in
/// `header` and renders their arguments.
fn args_of(target : @core_theory.Target, header : String) -> String raise {
  guard @c.lookup(target) is Some(abi) else { fail("no ABI") }
  let ruler = @c.model(target)
  let lines = []
  for decl in @c_parser.parse_string(ruler, header) {
    guard decl.1 is Function(spec) else { continue }
    let sub = @c.apply(
      abi,
      ruler,
      spec.attrs,
      spec.t,
      @types.Sub::create(name=decl.0),
    )
    let args = sub
      .args()
      .map(a => @types.Arg::to_string(a).trim_end(chars="\n").to_owned())
    lines.push(
      "\{decl.0}: " + (if args.is_empty() { "-" } else { args.join("; ") }),
    )
  }
  lines.join("\n")
}

///|
test "System V AMD64" {
  @x86_abi.install_calling_conventions()
  inspect(
    args_of(
      @core_theory.Target::x86_64(),
      (
        #|struct pair { long a; long b; };
        #|struct mix { long a; double d; };
        #|struct dd { double x; double y; };
        #|struct big { long a, b, c; };
        #|struct small { char c; short s; int i; };
        #|double hypot(double x, double y);
        #|struct pair mk(long a, long b);
        #|void take_mix(struct mix m);
        #|struct dd take_dd(struct dd v);
        #|void take_big(struct big b);
        #|struct big ret_big(void);
        #|struct small take_small(struct small s);
        #|long double ld(long double x);
        #|float _Complex cf(float _Complex z);
        #|int seven(int a, int b, int c, int d, int e, int f, int g);
      ),
      // as upstream, integers are passed only in registers, so a function
      // with more than six integer arguments is rejected
    ),
    content=(
      #|hypot: hypot_x :: in imm64 = low:64[YMM0:imm256]; hypot_y :: in imm64 = low:64[YMM1:imm256]; hypot_result :: out imm64 = low:64[YMM0:imm256]
      #|mk: mk_a :: in imm64 = RDI:imm64; mk_b :: in imm64 = RSI:imm64; mk_result :: out imm128 = concat(RDX:imm64, RAX:imm64)
      #|take_mix: take_mix_m :: in imm128 = concat(RDI:imm64, low:64[YMM0:imm256])
      #|take_dd: take_dd_v :: in imm128 = concat(low:64[YMM1:imm256], low:64[YMM0:imm256]); take_dd_result :: out imm128 = concat(low:64[YMM1:imm256], low:64[YMM0:imm256])
      #|take_big: take_big_b :: in imm192 = low:192[concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(concat(load(mem:mem64x8, (RSP:imm64 + 0x17:64u)):imm8, load(mem:mem64x8, (RSP:imm64 + 0x16:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x15:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x14:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x13:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x12:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x11:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0x10:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xF:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xE:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xD:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xC:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xB:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 0xA:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 9:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 8:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 7:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 6:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 5:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 4:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 3:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 2:64u)):imm8), load(mem:mem64x8, (RSP:imm64 + 1:64u)):imm8), load(mem:mem64x8, RSP:imm64):imm8)]
      #|ret_big: ret_big_hidden :: in out imm64 = RDI:imm64
      #|take_small: take_small_s :: in imm64 = RDI:imm64; take_small_result :: out imm64 = RAX:imm64
      #|ld: -
      #|cf: cf_z :: in imm64 = low:64[YMM0:imm256]; cf_result :: out imm64 = low:64[YMM0:imm256]
      #|seven: -
    ),
  )
}

///|
test "i686 cdecl" {
  @x86_abi.install_calling_conventions()
  // `i386` has no x87 registers, so its return arena (`ST0`) is undefined
  // and every prototype is rejected (upstream fails)
  inspect(args_of(@core_theory.Target::i386(), "int f(void);"), content="f: -")
  inspect(
    args_of(
      @core_theory.Target::i686(),
      (
        #|struct big { long a, b, c; };
        #|int add(int a, int b);
        #|long long ll(char c);
        #|double d(double x);
        #|struct big s(int x);
      ),
    ),
    content=(
      #|add: add_a :: in imm32 = load(mem:mem32x8, (ESP:imm32 + 4:32u)):imm32; add_b :: in imm32 = load(mem:mem32x8, (ESP:imm32 + 8:32u)):imm32; add_result :: out imm32 = EAX:imm32
      #|ll: ll_c :: in imm8 = load(mem:mem32x8, (ESP:imm32 + 4:32u)):imm8; ll_result :: out imm64 = concat(EAX:imm32, EDX:imm32)
      #|d: d_x :: in imm64 = load(mem:mem32x8, (ESP:imm32 + 8:32u)):imm64; d_result :: out imm64 = low:64[ST0:imm80]
      #|s: -
    ),
  )
}

///|
test "other conventions on declared sub-targets" {
  let ms = @core_theory.Target::declare_target(
    "x86_64-ms-test",
    parent=@core_theory.Target::x86_64(),
    abi=@core_theory.Abi::ms(),
  ).unwrap()
  let fast = @core_theory.Target::declare_target(
    "i686-fastcall-test",
    parent=@core_theory.Target::i686(),
    abi=@core_theory.Abi::fastcall(),
  ).unwrap()
  let pascal = @core_theory.Target::declare_target(
    "i686-pascal-test",
    parent=@core_theory.Target::i686(),
    abi=@core_theory.Abi::pascal(),
  ).unwrap()
  let i16 = @core_theory.Target::declare_target(
    "i286-pascal-test",
    parent=@core_theory.Target::i286(),
    abi=@core_theory.Abi::pascal(),
  ).unwrap()
  @x86_abi.install_calling_conventions()
  let header =
    #|int f(int a, double b, long long c, int d, int e);
    #|
  inspect(
    [ms, fast, pascal, i16]
    .map(t => {
      let text = args_of(t, header) catch { e => e.to_string() }
      "\{t.name().unqualified()}: \{text}"
    })
    .join("\n"),
    content=(
      #|x86_64-ms-test: f: f_a :: in imm32 = low:32[RCX:imm64]; f_b :: in imm64 = low:64[YMM1:imm256]; f_c :: in imm64 = R8:imm64; f_d :: in imm32 = low:32[R9:imm64]; f_e :: in imm32 = load(mem:mem64x8, RSP:imm64):imm32; f_result :: out imm32 = low:32[RAX:imm64]
      #|i686-fastcall-test: f: f_a :: in imm32 = ECX:imm32; f_b :: in imm64 = extend:64[EDX:imm32]; f_c :: in imm64 = load(mem:mem32x8, (ESP:imm32 + 8:32u)):imm64; f_d :: in imm32 = low:32[load(mem:mem32x8, (ESP:imm32 + 0x10:32u)):imm64]; f_e :: in imm32 = load(mem:mem32x8, (ESP:imm32 + 0x18:32u)):imm32; f_result :: out imm32 = EAX:imm32
      #|i686-pascal-test: f: -
      #|i286-pascal-test: f: f_a :: in imm16 = load(mem:mem16x8, SP:imm16):imm16; f_b :: in imm64 = extend:64[load(mem:mem16x8, (SP:imm16 + 2:16u)):imm16]; f_c :: in imm64 = load(mem:mem16x8, (SP:imm16 + 8:16u)):imm64; f_d :: in imm16 = low:16[load(mem:mem16x8, (SP:imm16 + 0x10:16u)):imm64]; f_e :: in imm16 = load(mem:mem16x8, (SP:imm16 + 0x18:16u)):imm16; f_result :: out imm16 = AX:imm16
    ),
  )
}
