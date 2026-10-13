// The x86 C calling conventions: a port of the `Abi` module of upstream
// `lib/x86_cpu/x86_target.ml` (installed by the upstream `x86` plugin).
//
// The conventions are defined with the `@c` argument-passing language and
// installed with `@c.Language::install`, which registers the ABI processor
// under the target name, the data model, and an ABI pass that makes the C
// API processor available to the `api` pass for projects of the target.
//
// Deviation: upstream fails when a register of an arena is not defined by
// the target; here the calling convention is rejected instead.

///|
/// Looks up a register of the target by its name, ignoring the case.
pub fn target_var(
  target : @core_theory.Target,
  name : String,
) -> @core_theory.Var? {
  let name = name.to_lower()
  target.vars().iter().find_first(v => v.name().to_lower() == name)
}

///|
/// An arena of the named registers of the target; with `low`, only the
/// `low` least significant bits of each register are used.
fn arena(
  target : @core_theory.Target,
  names : Array[String],
  low? : Int32,
) -> @c.Arg[@c.Arena] {
  let exps = []
  for name in names {
    guard target_var(target, name) is Some(v) else { return @c.Arg::reject() }
    let e = @types.Exp::var_exp(@c.reify_var(v))
    exps.push(
      match low {
        None => e
        Some(bits) => @types.Exp::cast(Low, bits, e)
      },
    )
  }
  @c.Arena::of_exps(exps)
}

///|
fn is_integer(t : @c.CType) -> Bool {
  t.is_integer() || t.is_pointer() || t.is_function()
}

///|
fn is_composite(t : @c.CType) -> Bool {
  t.is_structure() || t.is_union()
}

///|
fn is_sse(t : @c.CType) -> Bool {
  t is Basic({ t: Float | Double, .. })
}

///|
fn is_csse(t : @c.CType) -> Bool {
  t is Basic({ t: CFloat | CDouble, .. })
}

///|
fn is_x87(t : @c.CType) -> Bool {
  t is Basic({ t: LongDouble, .. })
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
  @c.Language::install(target, @c.SizeBase::new(model), spec) catch {
    _ => ()
  }
}

///|
fn ia16(target : @core_theory.Target, memory : @c.Statement) -> Unit {
  install(target, LP32, describer => {
    arena(target, ["AX", "DX"]).bind(irets => {
      describer.describe(
        return_=(_, _) => {
          @c.Language::choose([t => @c.Arg::registers(irets, t), memory])
        },
        (_, _) => memory,
      )
    })
  })
}

///|
/// The 16-bit `cdecl` convention: everything is passed in memory.
pub fn cdecl16(target : @core_theory.Target) -> Unit {
  ia16(target, @c.Arg::memory)
}

///|
/// The 16-bit `pascal` convention: arguments are pushed left to right.
pub fn pascal16(target : @core_theory.Target) -> Unit {
  ia16(target, @c.Arg::push)
}

///|
/// The 32-bit conventions; `make_pass` creates the rule that passes an
/// argument (memory by default).
fn ia32(target : @core_theory.Target, make_pass : @c.Arg[@c.Statement]) -> Unit {
  install(target, ILP32, describer => {
    arena(target, ["EAX", "EDX"]).bind(irets => {
      arena(target, ["ST0"]).bind(frets => {
        let return_ = (_ : Int32, size : Int32) => {
          @c.Language::select([
            (t => t.is_real(), t => @c.Arg::register(frets, t)),
            (
              @c.Language::is_(size > 64),
              @c.Language::combine([
                t => @c.Arg::reference(irets, t),
                @c.Arg::hidden,
              ]),
            ),
            (@c.Language::otherwise(), t => @c.Arg::registers(irets, t)),
          ])
        }
        @c.Arg::rebase(1).then(
          make_pass.bind(pass => describer.describe(return_~, (_, _) => pass)),
        )
      })
    })
  })
}

///|
/// The `cdecl` convention (also `stdcall`, `ms32`, and the watcom stack
/// convention): arguments are passed in memory.
pub fn cdecl(target : @core_theory.Target) -> Unit {
  ia32(target, @c.Arg::pure(@c.Arg::memory))
}

///|
/// The `fastcall` convention: the first two small non-floating arguments
/// are passed in `ECX` and `EDX`.
pub fn fastcall(target : @core_theory.Target) -> Unit {
  ia32(
    target,
    arena(target, ["ECX", "EDX"]).map(iregs => {
      arg => {
        @c.Arg::size(arg).bind(size => {
          @c.Language::select([
            (
              @c.Language::any([
                @c.Language::is_(size > 32),
                t => t.is_floating(),
              ]),
              @c.Arg::memory,
            ),
            (
              @c.Language::otherwise(),
              @c.Language::choose([
                t => @c.Arg::register(iregs, t),
                @c.Arg::memory,
              ]),
            ),
          ])(arg)
        })
      }
    }),
  )
}

///|
/// The watcom register convention (`EAX`, `EDX`, `EBX`, `ECX`).
pub fn watcomregs(target : @core_theory.Target) -> Unit {
  ia32(
    target,
    arena(target, ["eax", "edx", "ebx", "ecx"]).map(iregs => {
      arg => @c.Arg::choice([@c.Arg::register(iregs, arg), @c.Arg::memory(arg)])
    }),
  )
}

///|
/// The `pascal` convention (aka borland register): integers, characters,
/// and pointers in `EAX`, `EDX`, `ECX`, then memory; other types are not
/// supported.
pub fn pascal(target : @core_theory.Target) -> Unit {
  ia32(
    target,
    arena(target, ["eax", "edx", "ecx"]).map(iregs => {
      @c.Language::select([
        (
          @c.Language::any([
            t => t.is_cint(),
            t => t.is_char(),
            t => t.is_pointer(),
          ]),
          @c.Language::choose([t => @c.Arg::register(iregs, t), @c.Arg::memory]),
        ),
      ])
    }),
  )
}

///|
/// The Microsoft x64 convention.
pub fn ms64(target : @core_theory.Target) -> Unit {
  install(target, LP64, describer => {
    arena(target, ["rcx", "rdx", "r8", "r9"]).bind(iregs => {
      arena(target, ["rax", "rdx"]).bind(irets => {
        arena(target, low=64, ["ymm0", "ymm1", "ymm2", "ymm3"]).bind(vregs => {
          arena(target, low=128, ["ymm0"]).bind(vrets => {
            let iregs = (iregs, [vregs])
            let vregs = (vregs, [iregs.0])
            let irets = (irets, [])
            let vrets = (vrets, [])
            let use_ = (
              how : (@c.Arena, @c.CType) -> @c.Arg[Unit],
              arenas : (@c.Arena, Array[@c.Arena]),
              arg : @c.CType,
            ) => {
              @c.Arg::sequence([
                how(arenas.0, arg),
                @c.Arg::iter(arenas.1, a => @c.Arg::discard(a)),
              ])
            }
            let pass = (
              how : (@c.Arena, @c.CType) -> @c.Arg[Unit],
              arenas : (@c.Arena, Array[@c.Arena]),
            ) => {
              @c.Language::choose([
                arg => use_(how, arenas, arg),
                @c.Arg::memory,
              ])
            }
            let reference = (a : @c.Arena, t : @c.CType) => {
              @c.Arg::reference(a, t)
            }
            let register = (a : @c.Arena, t : @c.CType) => {
              @c.Arg::register(a, t)
            }
            let pointer = (a : @c.Arena, t : @c.CType) => @c.Arg::pointer(a, t)
            describer.describe(
              return_=(_, size) => {
                @c.Language::select([
                  (is_x87, pass(reference, iregs)),
                  (t => t.is_floating(), pass(register, vrets)),
                  (@c.Language::is_(size > 64), pass(reference, iregs)),
                  (@c.Language::otherwise(), pass(register, irets)),
                ])
              },
              (_, size) => {
                @c.Language::select([
                  (@c.Language::is_(size > 64), pass(pointer, iregs)),
                  (t => t.is_floating(), pass(register, vregs)),
                  (@c.Language::otherwise(), pass(register, iregs)),
                ])
              },
            )
          })
        })
      })
    })
  })
}

///|
/// The System V AMD64 classes of eightbytes.
priv enum Kind {
  Nil
  Int
  Sse
}

///|
fn merge_kinds(k1 : Kind, k2 : Kind) -> Kind {
  match (k1, k2) {
    (Nil, t) | (t, Nil) => t
    (Int, _) | (_, Int) => Int
    (Sse, Sse) => Sse
  }
}

///|
/// Groups the classified fields into eightbytes.
fn partition(fields : Array[(Kind, Int32)]) -> Array[Kind] {
  let words = []
  let mut k = Nil
  let mut s = 0
  for field in fields {
    let (k1, s1) = field
    if s + s1 <= 64 {
      k = merge_kinds(k, k1)
      s = s + s1
    } else {
      words.push(k)
      k = k1
      s = s1
    }
  }
  words.push(k)
  words
}

///|
fn classify(t : @c.CType) -> Kind {
  if is_integer(t) {
    Int
  } else if is_sse(t) || is_csse(t) {
    Sse
  } else {
    match t {
      Structure(s) | Union(s) => classify_fields(s.t.fields)
      Array(s) => classify(s.t.element)
      _ => Nil
    }
  }
}

///|
fn classify_fields(fields : Array[(String, @c.CType)]) -> Kind {
  fields.fold(init=Nil, (k, f) => merge_kinds(k, classify(f.1)))
}

///|
fn[S, T] fold_arg(
  xs : Array[T],
  init : S,
  f : (S, T) -> @c.Arg[S],
) -> @c.Arg[S] {
  xs.fold(init=@c.Arg::pure(init), (acc, x) => acc.bind(s => f(s, x)))
}

///|
/// The System V AMD64 convention.
pub fn sysv(target : @core_theory.Target) -> Unit {
  let data = @c.SizeBase::new(LP64)
  install(target, LP64, describer => {
    arena(target, ["rdi", "rsi", "rdx", "rcx", "r8", "r9"]).bind(iregs => {
      arena(target, low=64, [ for i in 0..<8 => "ymm\{i}" ]).bind(vregs => {
        arena(target, ["rax", "rdx"]).bind(irets => {
          arena(target, low=64, ["ymm0", "ymm1"]).bind(vrets => {
            let union_fields = (
              size : Int32,
              fields : Array[(String, @c.CType)],
            ) => @c.Arg::pure([(classify_fields(fields), size)])
            fn fields(c : @c.Compound) -> @c.Arg[Array[(Kind, Int32)]] {
              fold_arg(c.fields, (0, []), (state, field) => {
                let (off, acc) = state
                let t = field.1
                let alignment = data.alignment(t)
                @c.Arg::size(t).bind(size => {
                  let size = size + @c.padding(alignment, off)
                  let off = off + size
                  if is_integer(t) {
                    @c.Arg::pure((off, acc + [[(Int, size)]]))
                  } else if is_sse(t) || is_csse(t) {
                    @c.Arg::pure((off, acc + [[(Sse, size)]]))
                  } else {
                    match t {
                      Structure(s) => fields(s.t).map(fs => (off, acc + [fs]))
                      Union(s) =>
                        union_fields(size, s.t.fields).map(fs => {
                          (off, acc + [fs])
                        })
                      Array({ t: { element, size: Some(n), }, .. }) =>
                        @c.Arg::size(element).map(size => {
                          let kind = classify(element)
                          (off, acc + [Array::make(n, (kind, size))])
                        })
                      _ => @c.Arg::reject()
                    }
                  }
                })
              }).map(state => state.1.fold(init=[], (a, b) => a + b))
            }
            let composite_fields = (t : @c.CType) => {
              match t {
                Structure(s) => fields(s.t).map(partition)
                Union(s) =>
                  @c.Arg::size(t).bind(size => {
                    union_fields(size, s.t.fields).map(partition)
                  })
                _ => @c.Arg::pure([])
              }
            }
            let registers = (a : @c.Arena, t : @c.CType) => {
              @c.Arg::registers(rev=true, limit=2, a, t)
            }
            let pass_composite = (
              memory : @c.Statement,
              iregs : @c.Arena,
              vregs : @c.Arena,
            ) => {
              (t : @c.CType) => {
                @c.Arg::choice([
                  composite_fields(t).bind(kinds => {
                    match kinds {
                      [Int] => @c.Arg::register(iregs, t)
                      [Sse] => @c.Arg::register(vregs, t)
                      [Int, Int] => registers(iregs, t)
                      [Int, Sse] => @c.Arg::split(iregs, vregs, t)
                      [Sse, Int] => @c.Arg::split(vregs, iregs, t)
                      [Sse, Sse] => registers(vregs, t)
                      _ => @c.Arg::reject()
                    }
                  }),
                  memory(t),
                ])
              }
            }
            describer.describe(
              return_=(_, bits) => {
                @c.Language::select([
                  (
                    @c.Language::is_(bits > 128),
                    t => @c.Arg::reference(iregs, t),
                  ),
                  (is_integer, t => @c.Arg::register(irets, t)),
                  (is_sse, t => @c.Arg::register(vrets, t)),
                  (is_csse, t => registers(vrets, t)),
                  (
                    is_composite,
                    pass_composite(
                      t => @c.Arg::reference(iregs, t),
                      irets,
                      vrets,
                    ),
                  ),
                ])
              },
              (_, bits) => {
                @c.Language::select([
                  (@c.Language::is_(bits > 128), @c.Arg::memory),
                  (is_integer, t => @c.Arg::register(iregs, t)),
                  (is_sse, t => @c.Arg::register(vregs, t)),
                  (is_csse, t => registers(vregs, t)),
                  (is_composite, pass_composite(@c.Arg::memory, iregs, vregs)),
                ])
              },
            )
          })
        })
      })
    })
  })
}

///|
/// The calling conventions of the sub-targets with a specific ABI, per
/// target family (upstream `calling_conventions`).
fn calling_conventions() -> Array[
  (
    @core_theory.Target,
    Array[(@core_theory.Abi, (@core_theory.Target) -> Unit)],
  ),
] {
  [
    (
      @core_theory.Target::i286(),
      [
        (@core_theory.Abi::cdecl(), cdecl16),
        (@core_theory.Abi::pascal(), pascal16),
        (@core_theory.Abi::fortran(), pascal16),
      ],
    ),
    (
      @core_theory.Target::i386(),
      [
        (@core_theory.Abi::gnu(), cdecl),
        (@core_theory.Abi::cdecl(), cdecl),
        (@core_theory.Abi::pascal(), pascal),
        (@core_theory.Abi::fastcall(), fastcall),
        (@core_theory.Abi::stdcall(), cdecl),
        (@core_theory.Abi::ms(), cdecl),
      ],
    ),
    (
      @core_theory.Target::x86_64(),
      [(@core_theory.Abi::ms(), ms64), (@core_theory.Abi::gnu(), sysv)],
    ),
  ]
}

///|
/// The default calling conventions of the base targets.
fn default_calling_conventions() -> Array[
  (Array[@core_theory.Target], (@core_theory.Target) -> Unit),
] {
  [
    ([@core_theory.Target::i86()], cdecl16),
    (
      [
        @core_theory.Target::i386(),
        @core_theory.Target::i486(),
        @core_theory.Target::i586(),
        @core_theory.Target::i686(),
      ],
      cdecl,
    ),
    ([@core_theory.Target::x86_64()], sysv),
  ]
}

///|
/// Installs the calling conventions of all declared x86 targets (upstream
/// `install_calling_conventions`). Idempotent.
pub fn install_calling_conventions() -> Unit {
  for entry in calling_conventions() {
    let (parent, abis) = entry
    for abi_entry in abis {
      let (abi, install) = abi_entry
      for t in @core_theory.Target::filter(parent~, abi~) {
        if t.bits() == parent.bits() {
          install(t)
        }
      }
    }
  }
  for entry in default_calling_conventions() {
    for t in entry.0 {
      (entry.1)(t)
    }
  }
}
