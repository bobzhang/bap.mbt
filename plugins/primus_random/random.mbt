///|
/// # Primus state randomization (upstream `plugins/primus_random`)
///
/// Three components randomize the state of Primus machines using
/// generators selected by specifications (see `Spec`):
///
/// - `bap:var-randomizer`: when the system starts, every (immediate)
///   variable of the program gets a generator, so reading an unset
///   variable produces a value instead of failing;
/// - `bap:mem-randomizer`: when the system starts, memory regions
///   described by `(mem ...)` specifications are mapped with their
///   generators (the last specified first, so earlier specifications take
///   precedence); on every page fault the missing page (up to 4096 bytes)
///   is mapped with the default memory generator, and pages that are not
///   writable are remapped as writable unless `keep_protected` is set;
/// - `bap:arg-randomizer`: links the unresolved handler, so calls of
///   unresolved functions do not fail; when the handler is reached in the
///   entry block of a subroutine the output arguments of the subroutine
///   are assigned values from their generators.
///
/// The specifications are processed in order; the default `random`
/// specification is always appended as the last one.
pub let var_randomizer : String = "var-randomizer"

///|
/// The name of the memory randomizer component.
pub let mem_randomizer : String = "mem-randomizer"

///|
/// The name of the argument randomizer component.
pub let arg_randomizer : String = "arg-randomizer"

///|
let debug_pair : (@primus.Observation[String], @primus.Statement[String]) = @primus.Observation::provide(
  "random-debug",
  inspect=s => Atom(s),
)

///|
/// Debugging messages of the argument randomizer.
pub let debug_msg : @primus.Observation[String] = debug_pair.0

///|
fn debug(m : @primus.Machine, msg : String) -> Unit raise {
  m.make(debug_pair.1, msg)
}

///|
/// The specifications with the default one appended.
fn with_default(specs : Array[Spec]) -> Array[Spec] {
  [..specs, default_spec]
}

///|
fn spec_failure(e : Error) -> Error {
  match e {
    SpecError(msg) => @primus.RuntimeError(msg)
    e => e
  }
}

///|
/// All variables that occur in the program.
fn program_vars(prog : @types.Term[@types.Program]) -> Array[@types.Var] {
  let seen : Map[String, @types.Var] = Map([])
  let add = (vs : Array[@types.Var]) => {
    for v in vs {
      seen[v.to_string()] = v
    }
  }
  for sub in prog.subs() {
    for arg in sub.args() {
      add([arg.arg_var()])
      add(arg.arg_free_vars())
    }
    for blk in sub.blks() {
      add(blk.blk_defined_vars())
      add(blk.blk_free_vars())
      for phi in blk.phis() {
        add(phi.phi_free_vars())
      }
      for def in blk.defs() {
        add(def.def_free_vars())
      }
      for jmp in blk.jmps() {
        add(jmp.jmp_free_vars())
      }
    }
  }
  let vars = seen.values().collect()
  vars.sort_by((a, b) => a.compare(b))
  vars
}

///|
/// Adds generators for all immediate variables of the program.
pub fn randomize_vars(
  m : @primus.Machine,
  specs : Array[Spec],
  seed~ : Int32 = 0,
) -> Unit raise {
  for v in program_vars(m.program()) {
    guard v.typ() is Imm(width) else { continue }
    let gen = for_var(specs, seed~, width~, v) catch {
      e => raise spec_failure(e)
    }
    match gen {
      None => ()
      Some(gen) => @primus.Env::add(m, v, gen)
    }
  }
}

///|
/// Initializes the variable randomizer (the `bap:var-randomizer`
/// component body).
pub fn install_var_randomizer(
  m : @primus.Machine,
  specs~ : Array[Spec] = [],
  seed~ : Int32 = 0,
) -> Unit {
  let specs = with_default(specs)
  m.observe(@primus.system_start, _ => randomize_vars(m, specs, seed~))
}

///|
fn parse_exp(width : Int32, s : String) -> @types.Exp {
  if s.length() > 0 && s[0] >= '0' && s[0] <= '9' {
    let w = try @string.parse_int64(s, base=0) catch {
      _ => 0L
    } noraise {
      x => x
    }
    Int(
      @types.Word::create(bitvec_of_int64(width, w), width) catch {
        _ => @types.Word::of_bool(false)
      },
    )
  } else {
    Var(@types.Var::create(s, Imm(width)))
  }
}

///|
fn allocate_region(
  m : @primus.Machine,
  width : Int32,
  lower : String,
  upper : String?,
  generator : @primus.Generator,
) -> Unit raise {
  let eval = (s : String) => {
    @primus.Interpreter::exp(m, parse_exp(width, s)).to_word()
  }
  let lower = eval(lower)
  match upper {
    None => @primus.Memory::allocate(m, generator~, lower, 1)
    Some(upper) =>
      @primus.Memory::add_region(m, generator~, lower~, upper=eval(upper))
  }
}

///|
/// Maps the memory regions described by `(mem ...)` specifications. The
/// last added region has precedence, so the specifications are processed
/// from the last to the first.
pub fn initialize_regions(
  m : @primus.Machine,
  specs : Array[Spec],
  seed~ : Int32 = 0,
) -> Unit raise {
  let width = m.target().bits()
  for i = specs.length() - 1; i >= 0; i = i - 1 {
    let spec = specs[i]
    guard spec.predicate is Mem(region) && !(region is Default) else {
      continue
    }
    let generator = spec.create(seed~, width~) catch {
      e => raise spec_failure(e)
    }
    match region {
      Address(lower) => allocate_region(m, width, lower, None, generator)
      Section(name) =>
        allocate_region(
          m,
          width,
          "bap\{name}-lower",
          Some("bap\{name}-upper"),
          generator,
        )
      Interval(lower, upper) =>
        allocate_region(m, width, lower, Some(upper), generator)
      Default => ()
    }
  }
}

///|
let default_page_size : Int32 = 4096

///|
fn map_page(
  m : @primus.Machine,
  generator : @primus.Generator?,
  already_mapped : (@types.Word) -> Bool,
  addr : @types.Word,
) -> Unit raise {
  for len = default_page_size {
    let last = addr.nsucc(len - 1)
    if len > 1 && already_mapped(last) {
      continue len / 2
    } else {
      @primus.Memory::allocate(m, generator?, addr, len)
      break
    }
  }
}

///|
/// Links a pagefault handler that unlinks itself: the page was already
/// mapped by the observer, so the faulting access is simply retried.
fn trap(m : @primus.Machine) -> Unit {
  @primus.Linker::link(
    m,
    name=@primus.pagefault_handler,
    Host(m => @primus.Linker::unlink(m, Symbol(@primus.pagefault_handler))),
  )
}

///|
fn pagefault(
  m : @primus.Machine,
  generator : @primus.Generator?,
  keep_protected : Bool,
  x : @types.Word,
) -> Unit raise {
  if !@primus.Memory::is_mapped(m, x) {
    map_page(m, generator, a => @primus.Memory::is_mapped(m, a), x)
    trap(m)
  } else if !@primus.Memory::is_writable(m, x) && !keep_protected {
    map_page(m, generator, a => @primus.Memory::is_writable(m, a), x)
    trap(m)
  }
}

///|
/// Initializes the memory randomizer (the `bap:mem-randomizer` component
/// body).
pub fn install_mem_randomizer(
  m : @primus.Machine,
  specs~ : Array[Spec] = [],
  seed~ : Int32 = 0,
  keep_protected~ : Bool = false,
) -> Unit raise {
  let specs = with_default(specs)
  let width = m.target().bits()
  let generator = first_match(specs, seed~, width~, p => {
    p is (Mem(Default) | Any)
  }) catch {
    e => raise spec_failure(e)
  }
  m.observe(@primus.pagefault, x => pagefault(m, generator, keep_protected, x))
  m.observe(@primus.system_start, _ => initialize_regions(m, specs, seed~))
}

///|
/// The generators of the output arguments of the subroutines.
let args_state : @primus.State[Array[(@types.Var, @primus.Generator)]?] = @primus.State::declare_(
  uuid="2d9a70fb-8433-4a53-a750-3151f9366cb6",
  name="generators-for-arguments",
  _ => None,
)

///|
fn arg_generators(
  m : @primus.Machine,
  specs : Array[Spec],
  seed : Int32,
) -> Array[(@types.Var, @primus.Generator)] raise {
  match m.get_local(args_state) {
    Some(gens) => gens
    None => {
      let gens : Array[(@types.Var, @primus.Generator)] = []
      for sub in m.program().subs() {
        for arg in sub.args() {
          if arg.intent() is Some(In) {
            continue
          }
          let v = arg.arg_var()
          guard v.typ() is Imm(width) else { continue }
          if gens.iter().any(p => p.0 == v) {
            continue
          }
          let gen = for_var(specs, seed~, width~, v) catch {
            e => raise spec_failure(e)
          }
          match gen {
            None => ()
            Some(gen) => gens.push((v, gen))
          }
        }
      }
      m.put_local(args_state, Some(gens))
      gens
    }
  }
}

///|
fn pertube_var(
  m : @primus.Machine,
  gen : @primus.Generator,
  v : @types.Var,
) -> Unit raise {
  guard v.typ() is Imm(width) else { return }
  let w = @primus.Generator::word(m, gen, gen.width())
  let w = w.extract(hi=width - 1, lo=0) catch {
    _ => raise @primus.RuntimeError("cannot extract \{width} bits")
  }
  @primus.Interpreter::set(m, v, @primus.Value::of_word(m, w))
}

///|
fn pertube(
  m : @primus.Machine,
  gen : @primus.Generator,
  exp : @types.Exp,
) -> Unit raise {
  match exp {
    Var(v) => pertube_var(m, gen, v)
    Load(addr~, endian~, typ~, ..) => {
      guard typ is Imm(bits) else { return }
      let ptr = @primus.Interpreter::exp(m, addr)
      guard @types.Size::of_int_opt(bits) is Some(size) else { return }
      let value = @primus.Value::of_word(
        m,
        @primus.Generator::word(m, gen, bits),
      )
      @primus.Interpreter::store(m, ptr, value, endian, size)
    }
    exp =>
      for v in exp.free_vars() {
        pertube_var(m, gen, v)
      }
  }
}

///|
fn is_entry(
  sub : @types.Term[@types.Sub],
  blk : @types.Term[@types.Blk],
) -> Bool {
  match sub.first_blk() {
    Some(entry) => entry.tid() == blk.tid()
    None => false
  }
}

///|
/// The unresolved handler of the argument randomizer (upstream
/// `PertubeOutputs.exec`).
fn pertube_outputs(
  m : @primus.Machine,
  specs : Array[Spec],
  seed : Int32,
) -> Unit raise {
  debug(m, "the unresolved handler is called")
  match @primus.Interpreter::pos(m) {
    Jmp({ up: { me: blk, up: { me: sub, .. }, }, .. }) if is_entry(sub, blk) => {
      let gens = arg_generators(m, specs, seed)
      for arg in sub.args() {
        let v = arg.arg_var()
        match gens.iter().find_first(p => p.0 == v) {
          Some((_, gen)) => {
            debug(m, "pertubing argument \{arg.arg_to_string()}")
            pertube(m, gen, arg.arg_rhs())
          }
          None =>
            debug(
              m,
              "skipping \{arg.arg_to_string()} as there is no matching generator",
            )
        }
      }
    }
    p => debug(m, "called in a wrong position: \{p}")
  }
}

///|
/// Initializes the argument randomizer (the `bap:arg-randomizer`
/// component body): links the unresolved handler.
pub fn install_arg_randomizer(
  m : @primus.Machine,
  specs~ : Array[Spec] = [],
  seed~ : Int32 = 0,
) -> Unit {
  let specs = with_default(specs)
  @primus.Linker::link(
    m,
    name=@primus.unresolved_handler,
    Host(m => pertube_outputs(m, specs, seed)),
  )
}

///|
/// Registers the `bap:var-randomizer`, `bap:mem-randomizer` and
/// `bap:arg-randomizer` components with the given specifications (the
/// default `random` specification is appended). Idempotent: returns
/// `false` if the components were already registered (the configuration
/// of the first registration is used).
pub fn register(
  specs~ : Array[Spec] = [],
  seed~ : Int32 = 0,
  keep_protected~ : Bool = false,
) -> Bool {
  @primus.Components::register_generic(
    var_randomizer,
    m => install_var_randomizer(m, specs~, seed~),
    pkg="bap",
    desc="Randomizes registers.",
  ) catch {
    _ => return false
  }
  @primus.Components::register_generic(
    mem_randomizer,
    m => install_mem_randomizer(m, specs~, seed~, keep_protected~),
    pkg="bap",
    desc="Randomizes process memory.",
  ) catch {
    _ => ()
  }
  @primus.Components::register_generic(
    arg_randomizer,
    m => install_arg_randomizer(m, specs~, seed~),
    pkg="bap",
    desc="Randomizes output arguments of unbound procedures, as well as prevents failures when such procedures are called by trapping the unresolved handler.",
  ) catch {
    _ => ()
  }
  true
}

///|
/// The name of the plugin.
pub let name : String = "primus-random"

///|
let doc : String =
  #|Provides components for Primus state randomization and controls their
  #|parameters.
  #|
  #|This module provides three highly customizable components for state
  #|randomization: bap:var-randomizer, bap:mem-randomizer and
  #|bap:arg-randomizer. All three components use Primus generators to
  #|produce random or static values. The generators can be specified with
  #|the --primus-random-generators command line argument or put in files and
  #|loaded with --primus-random-init.

///|
/// Declares the `primus-random` plugin to `bap_main` with its
/// `generators`, `init`, `seed` and `preserve-protection` parameters. Does
/// nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["primus"], doc~, () => {
    let generators = @bap_main.Configuration::parameter(
      spec_type().list(),
      "generators",
      doc="A list of generator specifications. The generators are processed in order, with the first matching operator having the precedence. This option also has precedence over the generators specified via the initialization files.",
    )
    let init = @bap_main.Configuration::parameters(
      @bap_main.Type::file().list(),
      "init",
      doc="A list of generator initialization scripts. Files are processed in order, with the first matching operator having the precedence.",
    )
    let seed = @bap_main.Configuration::parameter(
      @bap_main.Type::int(),
      "seed",
      doc="The seed that will be used to initialize all generators.",
    )
    let keep_protected = @bap_main.Configuration::flag(
      "preserve-protection",
      doc="Preserves page protection flags when a new page is swapped in. When this flag is not set the bap:mem-randomizer will map missing memory pages as writable.",
    )
    @bap_main.Extension::register(ctxt => {
      let specs = [..ctxt.get(generators)]
      for files in ctxt.get(init) {
        for file in files {
          specs.append(Spec::from_file(file))
        }
      }
      register(
        specs~,
        seed=ctxt.get(seed),
        keep_protected=ctxt.get(keep_protected),
      )
      |> ignore
    })
  })
}
