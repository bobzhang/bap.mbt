// The `riscv` plugin (upstream `plugins/riscv/riscv_main.ml`): the RISC-V
// C ABI, the default LLVM encodings, and the RISC-V semantics (Primus Lisp
// definitions from `plugins/riscv/semantics/riscv.lisp`).
//
// The targets (`riscv`, `riscv32`, `riscv64`) are declared by
// `core_theory`, and their default encodings (`llvm-riscv32`,
// `llvm-riscv64`) by `mc.default_encoding`. There is no LLVM (or Ghidra)
// in the port: the `llvm` backend is the native decoder of the `riscv`
// package, which produces LLVM MC compatible instructions.

///|
/// The name of the plugin.
pub let name : String = "riscv"

///|
/// The features provided by the plugin.
pub let provides : Array[String] = [
  "semantics", "lifter", "riscv", "riscv64", "riscv32",
]

///|
/// The data model of the target: ILP32 for 32-bit targets, LP64
/// otherwise.
pub fn data_model(t : @core_theory.Target) -> @c.Model {
  if t.bits() == 32 {
    ILP32
  } else {
    LP64
  }
}

///|
fn integer(regs : @c.Arena, t : @c.CType) -> @c.Arg[Unit] {
  @c.Arg::count(regs, t).bind(count => {
    match count {
      None => @c.Arg::reject()
      Some(1) => @c.Arg::choice([@c.Arg::register(regs, t), @c.Arg::memory(t)])
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
    }
  })
}

///|
fn float(iregs : @c.Arena, fregs : @c.Arena, t : @c.CType) -> @c.Arg[Unit] {
  @c.Arg::count(fregs, t).bind(count => {
    match count {
      Some(1) =>
        @c.Arg::choice([
          @c.Arg::register(fregs, t),
          @c.Arg::register(iregs, t),
          @c.Arg::memory(t),
        ])
      _ => integer(iregs, t)
    }
  })
}

///|
/// The RISC-V calling convention (upstream `Abi.define`): integer values
/// are passed in the argument registers (a pair of aligned registers for
/// two-word values, by reference for larger ones), then in memory;
/// floating-point values are passed in the floating-point registers when
/// possible.
pub fn calling_convention(
  target : @core_theory.Target,
  proto : @c.Proto,
) -> @c.Arg[Unit] {
  @c.Arena::iargs(target).bind(iargs => {
    @c.Arena::irets(target).bind(irets => {
      @c.Arena::fargs(target).bind(fargs => {
        @c.Arena::frets(target).bind(frets => {
          let arg = (iregs : @c.Arena, fregs : @c.Arena, t : @c.CType) => {
            if t.is_real() {
              float(iregs, fregs, t)
            } else {
              integer(iregs, t)
            }
          }
          let return_ = match proto.return_ {
            Void => @c.Arg::pure(())
            r => arg(irets, frets, r)
          }
          @c.Arg::define_semantics(
            return_~,
            @c.Arg::iter(proto.args, a => arg(iargs, fargs, a.1)),
          )
        })
      })
    })
  })
}

///|
/// Defines the C ABI of the target (idempotent).
pub fn define_abi(target : @core_theory.Target) -> Unit {
  if @c.lookup(target) is Some(_) {
    return
  }
  @c.define_abi(target, @c.SizeBase::new(data_model(target)), (_, proto) => {
    calling_convention(target, proto)
  }) catch {
    _ => ()
  }
}

///|
/// Enables the plugin (upstream `main`): defines the ABIs of `riscv32` and
/// `riscv64`, registers the RISC-V decoder (`@rv.register_decoder`) and
/// the Primus Lisp RISC-V semantics lifter in the registry. Only the
/// `llvm` backend (the default) is supported.
pub fn enable(
  backend~ : String = "llvm",
  registry~ : @mc.Registry = @mc.Registry::global(),
) -> Result[Unit, String] {
  match backend {
    "llvm" => ()
    "ghidra" => return Err("the ghidra backend is not available")
    other => return Err("unknown backend \{other}")
  }
  define_abi(@core_theory.Target::riscv32())
  define_abi(@core_theory.Target::riscv64())
  @rv.register_decoder()
  let provider = "primus-lisp-riscv"
  if registry.find(provider) is None {
    registry.register(
      @primus_lisp.semantics_provider(
        provider,
        @core_theory.Target::riscv(),
        @primus_lisp.semantic_dirs,
      ),
    )
  }
  Ok(())
}

///|
/// Declares the plugin (with the `--riscv-backend` option) in the
/// `bap_main` registry.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides~, doc="provides RISCV semantics", () => {
    let backend = @bap_main.Configuration::parameter(
      doc="the disassembler backend (llvm or ghidra)",
      @bap_main.Type::string().with_default("llvm"),
      "backend",
    )
    @bap_main.Extension::register(ctxt => {
      match enable(backend=ctxt.get(backend)) {
        Ok(_) => ()
        Err(msg) => fail(msg)
      }
    })
  })
}
