///|
/// # Primus machine limits (upstream `plugins/primus_limit`)
///
/// Ensures termination by limiting the life time of each Primus machine:
///
/// - `max-length` bounds the number of events of a given kind a single
///   machine can make: blocks (`<n>b`, counted with `enter_blk`),
///   instructions (`<n>i`, `pc_change`), terms (`<n>t`, `enter_term`),
///   expressions (`<n>e`) or clock ticks (`<n>` or `<n>c`, both counted
///   with `clock`). Without the parameter the component uses the default
///   bound of 32768 clock ticks;
/// - `max-visited` bounds the number of executions of the same block in a
///   given machine.
///
/// When a bound is exceeded the machine is halted (`Interpreter::halt`).
/// The counters are local to each machine, so forks inherit the counters
/// of their parent.
pub let component_name : String = "limit"

///|
/// The kind of events counted by a length bound.
pub(all) enum Counter {
  Blk
  Insn
  Term
  Exp
  Clk
} derive(Eq, Debug)

///|
/// A length bound: at most `limit` events of the kind `counter`.
pub(all) struct Bound {
  counter : Counter
  limit : Int32
} derive(Eq, Debug)

///|
/// Errors of the bound syntax.
pub suberror BoundParseError {
  BoundParseError(String)
} derive(Debug)

///|
pub impl Show for BoundParseError with fn output(self, logger) {
  match self {
    BoundParseError(msg) => logger.write_string(msg)
  }
}

///|
/// The default bound (32768 clock ticks).
pub let default_bound : Bound = { counter: Clk, limit: 32768, }

///|
fn counter_of_suffix(c : UInt16) -> Counter? {
  match c {
    'b' => Some(Blk)
    'i' => Some(Insn)
    't' => Some(Term)
    'e' => Some(Exp)
    'c' => Some(Clk)
    _ => None
  }
}

///|
fn suffix_of_counter(c : Counter) -> String {
  match c {
    Blk => "b"
    Insn => "i"
    Term => "t"
    Exp => "e"
    Clk => ""
  }
}

///|
fn parse_int(s : StringView) -> Int32 raise BoundParseError {
  @string.parse_int(s) catch {
    _ => raise BoundParseError("Expected a number, got \{s}")
  }
}

///|
/// Parses a bound: a number optionally followed by a counter suffix
/// (`b`, `i`, `t`, `e` or `c`); a number without a suffix counts clocks.
///
/// ```mbt check
/// test {
///   let b = @primus_limit.Bound::parse("100b")
///   assert_true(b.counter is Blk && b.limit == 100)
///   inspect(b.to_string(), content="100b")
///   inspect(@primus_limit.Bound::parse("7c").to_string(), content="7")
/// }
/// ```
pub fn Bound::parse(s : String) -> Bound raise BoundParseError {
  let n = s.length()
  match (if n > 0 { counter_of_suffix(s[n - 1]) } else { None }) {
    None => { counter: Clk, limit: parse_int(s), }
    Some(counter) => { counter, limit: parse_int(s.view(end_offset=n - 1)), }
  }
}

///|
/// Prints a bound in the syntax accepted by `Bound::parse`.
pub fn Bound::to_string(self : Bound) -> String {
  "\{self.limit}\{suffix_of_counter(self.counter)}"
}

///|
fn string_of_counter(c : Counter) -> String {
  match c {
    Blk => "blocks"
    Insn => "instructions"
    Term => "terms"
    Exp => "expressions"
    Clk => "clocks"
  }
}

///|
priv struct Limits {
  visited : @immut_hashmap.HashMap[@types.Tid, Int32]
  length : Int32
}

///|
let state : @primus.State[Limits] = @primus.State::declare_(
  uuid="b1b58dff-54de-4611-abf8-88ff8f6c7481",
  name="primus-limiter",
  _ => { visited: @immut_hashmap.new(), length: 0, },
)

///|
/// The number of counted events of the current machine.
pub fn length(m : @primus.Machine) -> Int32 {
  m.get_local(state).length
}

///|
/// How many times the current machine entered the block.
pub fn visits(m : @primus.Machine, tid : @types.Tid) -> Int32 {
  m.get_local(state).visited.get(tid).unwrap_or(0)
}

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-limit",
)

///|
fn terminate(m : @primus.Machine, reason : String) -> Unit raise {
  log.info(
    message="terminating machine \{m.current()} because a maximum number of \{reason} has been reached",
  )
  @primus.Interpreter::halt(m)
}

///|
fn check(m : @primus.Machine, bound : Bound) -> Unit raise {
  let s = m.get_local(state)
  if s.length > bound.limit {
    terminate(m, string_of_counter(bound.counter))
  } else {
    m.put_local(state, { ..s, length: s.length + 1, })
  }
}

///|
fn on_blk(
  m : @primus.Machine,
  max_visited : Int32?,
  blk : @types.Term[@types.Blk],
) -> Unit raise {
  let tid = blk.tid()
  let s = m.get_local(state)
  if max_visited is Some(max) && s.visited.get(tid) is Some(visits) {
    if visits > max {
      terminate(m, "visits of the \{tid.to_string()} destination")
    }
  }
  m.put_local(state, {
    ..s,
    visited: s.visited.add(tid, s.visited.get(tid).unwrap_or(0) + 1),
  })
}

///|
/// Initializes the limits in the machine (the component body).
/// `max_length` defaults to `default_bound`.
pub fn install(
  m : @primus.Machine,
  max_length~ : Bound = default_bound,
  max_visited? : Int32,
) -> Unit {
  m.observe(@primus.enter_blk, blk => on_blk(m, max_visited, blk))
  let bound = max_length
  match bound.counter {
    Clk | Exp => m.observe(@primus.clock, _ => check(m, bound))
    Blk => m.observe(@primus.enter_blk, _ => check(m, bound))
    Insn => m.observe(@primus.pc_change, _ => check(m, bound))
    Term => m.observe(@primus.enter_term, _ => check(m, bound))
  }
}

///|
/// Registers the `bap:limit` component with the given limits. Idempotent:
/// returns `false` if the component was already registered (the limits of
/// the first registration are used).
pub fn register(max_length? : Bound, max_visited? : Int32) -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m, max_length?, max_visited?),
    pkg="bap",
    desc="Enables program termination by limiting the maximum life time of each Primus Machine.",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the limits to the legacy main system (upstream does it when
/// either limit is specified). Idempotent.
pub fn enable(max_length? : Bound, max_visited? : Int32) -> Unit {
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m, max_length?, max_visited?))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-limit"

///|
/// The configuration type of bounds (upstream `Bound.t`).
pub fn bound_type() -> @bap_main.Type[Bound] {
  @bap_main.Type::create(
    name="BOUND",
    parse=s => Bound::parse(s),
    print=Bound::to_string,
    default_bound,
  )
}

///|
/// Declares the `primus-limit` plugin to `bap_main` with its `max-length`
/// and `max-visited` parameters. Does nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["termination", "primus", "microexecution", "microx"],
    doc="ensures termination by limiting Primus machines",
    () => {
      let max_length = @bap_main.Configuration::parameter(
        bound_type().some(),
        "max-length",
        doc="Limits the maximum number of basic blocks a single machinine can execute.",
      )
      let max_visited = @bap_main.Configuration::parameter(
        @bap_main.Type::int().some(),
        "max-visited",
        doc="Limits the maximum number of executions of the same block in a given machine.",
      )
      @bap_main.Extension::register(ctxt => {
        let max_length = ctxt.get(max_length)
        let max_visited = ctxt.get(max_visited)
        if max_length is Some(_) || max_visited is Some(_) {
          enable(max_length?, max_visited?)
        }
        register(max_length?, max_visited?) |> ignore
      })
    },
  )
}
