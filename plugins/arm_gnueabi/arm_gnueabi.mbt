// The ARM C calling conventions: a port of upstream
// `plugins/arm/arm_gnueabi.ml` (AAPCS32 and AAPCS64 defined with the
// `@c` argument-passing language), installed for the ARM targets with an
// unknown, `gnu`, `eabi`, or `gnueabi` ABI.
//
// (The `arm` package has a separate, register-location model of the same
// rules that does not produce `@c` argument terms.)

///|
/// The ARM data model: enumerations are `unsigned int` when all values
/// fit in 32 bits (`unsigned long long` otherwise), and `long double` is a
/// 64-bit `double`.
pub(all) struct ArmData {
  model : @c.Model
}

///|
pub extend ArmData with @c.Ruler::{
  model,
  pointer,
  complex,
  scalar,
  array,
  alignment,
  union,
  basic,
  bits,
  structure,
  integer,
  real,
  enum_,
  floating,
}

///|
pub impl @c.Ruler for ArmData with fn model(self) {
  self.model
}

///|
pub impl @c.Ruler for ArmData with fn enum_(self, elts) {
  if @c.max_enum_elt(elts) < 1L << 32 {
    @c.Ruler::integer(self, UInt)
  } else {
    @c.Ruler::integer(self, ULongLong)
  }
}

///|
pub impl @c.Ruler for ArmData with fn real(_self, t) {
  match t {
    Float => R32
    _ => R64
  }
}

///|
fn install(
  target : @core_theory.Target,
  model : @c.Model,
  spec : (@c.Describer) -> @c.Arg[Unit],
) -> Unit {
  if @c.lookup(target) is Some(_) {
    return
  }
  @c.Language::install(target, { model, }, spec) catch {
    _ => ()
  }
}

///|
fn const_(x : @c.Arg[Unit]) -> @c.Statement {
  _ => x
}

///|
fn is_little(target : @core_theory.Target) -> Bool {
  target.endianness() is LittleEndian
}

///|
/// Defines the AAPCS32 calling convention for the target.
pub fn aapcs32(target : @core_theory.Target) -> Unit {
  let rev = is_little(target)
  install(target, ILP32, describer => {
    @c.Arena::iargs(target).bind(iargs => {
      @c.Arena::irets(target).bind(irets => {
        describer.describe(
          return_=(_, size) => {
            @c.Language::select([
              (
                t => t.is_basic(),
                @c.Language::select([
                  (
                    @c.Language::is_(size <= 32 * 2),
                    t => @c.Arg::registers(rev~, irets, t),
                  ),
                  (@c.Language::otherwise(), t => @c.Arg::reference(iargs, t)),
                ]),
              ),
              (@c.Language::is_(size <= 32), t => @c.Arg::register(irets, t)),
              (@c.Language::otherwise(), t => @c.Arg::reference(iargs, t)),
            ])
          },
          (alignment, _) => {
            @c.Language::sequence([
              (
                @c.Language::is_(alignment == 64),
                const_(@c.Arg::align_even(iargs)),
              ),
              (
                @c.Language::always(),
                @c.Language::choose([
                  t => @c.Arg::split_with_memory(rev~, iargs, t),
                  @c.Arg::memory,
                ]),
              ),
            ])
          },
        )
      })
    })
  })
}

///|
/// Defines the AAPCS64 calling convention for the target.
pub fn aapcs64(target : @core_theory.Target) -> Unit {
  let rev = is_little(target)
  let is_composite = (t : @c.CType) => t.is_structure() || t.is_union()
  install(target, LP64, describer => {
    @c.Arena::iargs(target).bind(iargs => {
      @c.Arena::irets(target).bind(irets => {
        @c.Arena::fargs(target).bind(fargs => {
          @c.Arena::frets(target).bind(frets => {
            let x8 = match
              target.vars().iter().find_first(v => v.name() == "X8") {
              Some(v) => @c.Arena::create([v])
              None => @c.Arg::reject()
            }
            x8.bind(x8 => {
              describer.describe(
                return_=(alignment, size) => {
                  @c.Language::select([
                    (
                      t => t.is_floating(),
                      @c.Language::choose([
                        t => @c.Arg::registers(rev~, frets, t),
                        t => @c.Arg::reference(x8, t),
                      ]),
                    ),
                    (
                      @c.Language::otherwise(),
                      @c.Language::sequence([
                        (
                          @c.Language::is_(alignment >= 128),
                          const_(@c.Arg::align_even(irets)),
                        ),
                        (
                          @c.Language::always(),
                          @c.Language::select([
                            (
                              @c.Language::is_(size > 16 * 8),
                              t => @c.Arg::reference(x8, t),
                            ),
                            (
                              @c.Language::always(),
                              @c.Language::choose([
                                t => @c.Arg::registers(rev~, irets, t),
                                t => @c.Arg::reference(x8, t),
                              ]),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ])
                },
                (alignment, size) => {
                  @c.Language::select([
                    (
                      t => t.is_floating(),
                      @c.Language::choose([
                        t => @c.Arg::registers(rev~, fargs, t),
                        t => @c.Arg::reference(iargs, t),
                      ]),
                    ),
                    (
                      @c.Language::otherwise(),
                      @c.Language::sequence([
                        (
                          @c.Language::is_(alignment >= 128),
                          const_(@c.Arg::align_even(iargs)),
                        ),
                        (
                          @c.Language::always(),
                          @c.Language::select([
                            (
                              @c.Language::is_(size > 16 * 8),
                              t => @c.Arg::reference(iargs, t),
                            ),
                            (
                              is_composite,
                              @c.Language::choose([
                                t => @c.Arg::split_with_memory(rev~, iargs, t),
                                @c.Arg::memory,
                              ]),
                            ),
                            (
                              @c.Language::otherwise(),
                              @c.Language::choose([
                                t => @c.Arg::registers(rev~, iargs, t),
                                @c.Language::combine([
                                  const_(@c.Arg::deplet(iargs)),
                                  @c.Arg::memory,
                                ]),
                              ]),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ])
                },
              )
            })
          })
        })
      })
    })
  })
}

///|
fn is_our_abi(abi : @core_theory.Abi) -> Bool {
  [
    @core_theory.Abi::unknown(),
    @core_theory.Abi::gnu(),
    @core_theory.Abi::eabi(),
    @core_theory.Abi::gnueabi(),
  ].contains(abi)
}

///|
/// Installs AAPCS64 for the 64-bit and AAPCS32 for the 32-bit ARM targets
/// (upstream `setup`). Idempotent.
pub fn setup() -> Unit {
  for t in @core_theory.Target::family(@core_theory.Target::arm_family()) {
    if is_our_abi(t.abi()) {
      match t.bits() {
        64 => aapcs64(t)
        32 => aapcs32(t)
        _ => ()
      }
    }
  }
}
