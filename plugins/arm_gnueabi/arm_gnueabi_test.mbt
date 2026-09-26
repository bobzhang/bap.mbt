// Tests of the ARM calling conventions.

///|
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
test "data model" {
  let m : @arm_gnueabi.ArmData = { model: ILP32, }
  inspect(@c.Ruler::real(m, LongDouble).in_bits(), content="64")
  inspect(@c.Ruler::enum_(m, [("A", Some(1L))]).in_bits(), content="32")
  inspect(@c.Ruler::enum_(m, [("A", Some(1L << 40))]).in_bits(), content="64")
}

///|
test "AAPCS32" {
  @arm_gnueabi.setup()
  inspect(
    args_of(
      @core_theory.Target::arm(),
      (
        #|struct pair { int a; int b; };
        #|struct big { int a, b, c, d, e; };
        #|long long ll(int a, long long b);
        #|double d(double x, int y);
        #|struct pair mk(struct pair p);
        #|struct big take(struct big b);
        #|int five(int a, int b, int c, int d, int e);
      ),
    ),
    content=(
      #|ll: ll_a :: in imm32 = R0:imm32; ll_b :: in imm64 = concat(R3:imm32, R2:imm32); ll_result :: out imm64 = concat(R1:imm32, R0:imm32)
      #|d: d_x :: in imm64 = concat(R1:imm32, R0:imm32); d_y :: in imm32 = R2:imm32; d_result :: out imm64 = concat(R1:imm32, R0:imm32)
      #|mk: mk_p :: in imm64 = concat(R2:imm32, R1:imm32); mk_hidden :: in out imm32 = R0:imm32
      #|take: take_b :: in imm160 = concat(concat(concat(load(mem:mem32x8, SP:imm32):imm64, R3:imm32), R2:imm32), R1:imm32); take_hidden :: in out imm32 = R0:imm32
      #|five: five_a :: in imm32 = R0:imm32; five_b :: in imm32 = R1:imm32; five_c :: in imm32 = R2:imm32; five_d :: in imm32 = R3:imm32; five_e :: in imm32 = load(mem:mem32x8, SP:imm32):imm32; five_result :: out imm32 = R0:imm32
    ),
  )
}

///|
test "AAPCS64" {
  @arm_gnueabi.setup()
  // `d` is rejected: the floating-point argument arena of the port's
  // AArch64 target (`X0`-`X7`, aliases of `R0`-`R7`) is empty once the
  // aliases are excluded. `take` is left without arguments: its argument
  // is passed by a hidden reference, and (as upstream) the ABI processor
  // then produces fewer parameters than the prototype has.
  inspect(
    args_of(
      @core_theory.Target::aarch64(),
      (
        #|struct pair { long a; long b; };
        #|struct big { long a, b, c; };
        #|double d(double x, float y, long z);
        #|struct pair mk(struct pair p);
        #|struct big take(struct big b);
        #|int nine(int a, int b, int c, int d, int e, int f, int g, int h, int i);
      ),
    ),
    content=(
      #|d: -
      #|mk: mk_p :: in imm128 = concat(R1:imm64, R0:imm64); mk_result :: out imm128 = concat(R1:imm64, R0:imm64)
      #|take: -
      #|nine: nine_a :: in imm32 = low:32[R0:imm64]; nine_b :: in imm32 = low:32[R1:imm64]; nine_c :: in imm32 = low:32[R2:imm64]; nine_d :: in imm32 = low:32[R3:imm64]; nine_e :: in imm32 = low:32[R4:imm64]; nine_f :: in imm32 = low:32[R5:imm64]; nine_g :: in imm32 = low:32[R6:imm64]; nine_h :: in imm32 = low:32[R7:imm64]; nine_i :: in imm32 = load(mem:mem64x8, R31:imm64):imm32; nine_result :: out imm32 = low:32[R0:imm64]
    ),
  )
}
