// Port of `plugins/propagate_taint/propagate_taint_main.ml`: the legacy
// taint propagation pass.
//
// The taint is propagated from the seeds (definitions marked with the
// `tainted-reg` or `tainted-ptr` attributes, e.g. by the `taint` plugin)
// to its maximum extent by microexecuting every subroutine that contains
// a seed and all their callers. The results are stored in the
// `tainted-regs` and `tainted-ptrs` attributes of the terms, and every
// executed term is marked as `visited`.
//
// Not ported: the result cache (upstream `Data.Cache`, keyed by a digest
// of the program and the options) and the progress reports.

///|
/// The options of the pass (upstream `args`).
pub(all) struct Args {
  /// the maximum length of a path, in blocks (`--max-trace`)
  max_trace : Int
  /// the maximum number of loop iterations (`--max-iterations`)
  max_loop : Int
  /// follow only one path, without backtracking (`--deterministic`)
  deterministic : Bool
  /// the seed of the random generator (`--random-seed`)
  random_seed : Int?
  /// the concretization policy of registers (`--reg-value`)
  reg_policy : @microx.Policy
  /// the concretization policy of memory cells (`--mem-value`)
  mem_policy : @microx.Policy
  /// only the subroutines with these names are analyzed, if not empty
  /// (`--interesting`)
  interesting : Array[String]
  /// print the coverage (`--print-coverage`)
  print_coverage : Bool
}

///|
/// The options with the upstream default values.
pub fn Args::new(
  max_trace? : Int = 1_000_000,
  max_loop? : Int = 10,
  deterministic? : Bool = false,
  random_seed? : Int,
  reg_policy? : @microx.Policy = Random,
  mem_policy? : @microx.Policy = Random,
  interesting? : Array[String] = [],
  print_coverage? : Bool = false,
) -> Args {
  {
    max_trace,
    max_loop,
    deterministic,
    random_seed,
    reg_policy,
    mem_policy,
    interesting,
    print_coverage,
  }
}

///|
fn parse_int64(s : String) -> Int64? {
  let (neg, body) = if s.has_prefix("-") {
    (true, s.view(start_offset=1))
  } else {
    (false, s[:])
  }
  if body.is_empty() {
    return None
  }
  let (radix, digits) = if body.has_prefix("0x") || body.has_prefix("0X") {
    (16UL, body.view(start_offset=2))
  } else {
    (10UL, body)
  }
  if digits.is_empty() {
    return None
  }
  let mut acc = 0UL
  for c in digits {
    let d = match c {
      '0'..='9' => c.to_int() - '0'.to_int()
      'a'..='f' if radix == 16UL => c.to_int() - 'a'.to_int() + 10
      'A'..='F' if radix == 16UL => c.to_int() - 'A'.to_int() + 10
      '_' => continue
      _ => return None
    }
    acc = acc * radix + d.to_uint64()
  }
  let v = acc.reinterpret_as_int64()
  Some(if neg { -v } else { v })
}

///|
/// Parses a concretization policy (upstream `Policy.parser`):
/// `random`, a number, or an interval `(<num> <num>)`.
pub fn parse_policy(input : String) -> Result[@microx.Policy, String] {
  let error = Err("policy ::= random | <num> | (<num> <num>)")
  let s = input.trim(chars=" \t\n").to_owned()
  if s == "random" {
    return Ok(Random)
  }
  if s.has_prefix("(") && s.has_suffix(")") {
    let body = s.view(start_offset=1, end_offset=s.length() - 1)
    let parts = body
      .split(" ")
      .filter(p => !p.is_empty())
      .map(p => p.to_owned())
      .collect()
    guard parts is [b, e] else { return error }
    match (parse_int64(b), parse_int64(e)) {
      (Some(b), Some(e)) => Ok(Interval(b, e))
      _ => error
    }
  } else {
    match parse_int64(s) {
      Some(n) => Ok(Fixed(n))
      None => error
    }
  }
}

///|
/// Renders a policy as upstream (`Policy.printer`).
pub fn policy_to_string(p : @microx.Policy) -> String {
  match p {
    Random => "random"
    Fixed(n) => n.to_string()
    Interval(n, m) => "(\{n} \{m})"
  }
}

///|
fn contains_seed(sub : @types.Term[@types.Sub]) -> Bool {
  sub.blks().iter().any(blk => blk.defs().iter().any(is_seeded))
}

///|
/// The subroutines that contain seeds, and all their callers (upstream
/// `seeded`).
fn seeded(
  prog : @types.Term[@types.Program],
  subs : Array[@types.Term[@types.Sub]],
) -> @immut_hashset.HashSet[@types.Tid] {
  let callgraph = prog.program_callgraph()
  let mut out : @immut_hashset.HashSet[@types.Tid] = @immut_hashset.HashSet::new()
  for sub in subs {
    if contains_seed(sub) {
      for caller in callgraph.reachable(sub.tid(), rev=true) {
        out = out.add(caller)
      }
      out = out.add(sub.tid())
    }
  }
  out
}

///|
/// The identifiers of the arguments, phi nodes, definitions and jumps of
/// the subroutine (upstream `tids_of_sub`).
fn tids_of_sub(
  sub : @types.Term[@types.Sub],
) -> @immut_hashset.HashSet[@types.Tid] {
  let mut out : @immut_hashset.HashSet[@types.Tid] = @immut_hashset.HashSet::new()
  for arg in sub.args() {
    out = out.add(arg.tid())
  }
  for blk in sub.blks() {
    for t in blk.phis() {
      out = out.add(t.tid())
    }
    for t in blk.defs() {
      out = out.add(t.tid())
    }
    for t in blk.jmps() {
      out = out.add(t.tid())
    }
  }
  out
}

///|
/// The outcome of the analysis (upstream `State.t`, without the progress
/// counters).
pub struct Analysis {
  /// the number of analyzed subroutines
  subs : Int
  /// the visited terms
  priv visited : @immut_hashset.HashSet[@types.Tid]
  /// the terms of the analyzed subroutines
  priv terms : @immut_hashset.HashSet[@types.Tid]
  /// the merged results of all analyzed subroutines
  result : PropagationResult
}

///|
/// The coverage: the number of visited terms of the analyzed subroutines
/// and the number of their terms (upstream `State.coverage`).
pub fn Analysis::coverage(self : Analysis) -> (Int, Int) {
  (self.terms.intersection(self.visited).length(), self.terms.length())
}

///|
/// Renders the coverage as upstream (`[x/y] p%`).
pub fn Analysis::coverage_to_string(self : Analysis) -> String {
  let (x, y) = self.coverage()
  let percent = if y == 0 {
    0
  } else {
    (100.0 * x.to_double() / y.to_double()).to_int()
  }
  let p = percent.to_string()
  let pad = if p.length() < 3 { " ".repeat(3 - p.length()) } else { "" }
  "[\{x}/\{y}] \{pad}\{p}%"
}

///|
/// Propagates the taints through every interesting subroutine that
/// contains a seed and through their callers (upstream `process`).
pub fn analyze(args : Args, proj : @project.Project) -> Analysis {
  let prog = proj.program()
  let candidates = prog
    .subs()
    .filter(sub => {
      args.interesting.is_empty() || args.interesting.contains(sub.sub_name())
    })
  let selected = seeded(prog, candidates)
  let mut state : Analysis = {
    subs: 0,
    visited: @immut_hashset.HashSet::new(),
    terms: @immut_hashset.HashSet::new(),
    result: PropagationResult::empty(),
  }
  for sub in prog.subs() {
    guard selected.contains(sub.tid()) else { continue }
    state = {
      ..state,
      subs: state.subs + 1,
      terms: state.terms.union(tids_of_sub(sub)),
    }
    let result = run(
      max_steps=args.max_trace,
      max_loop=args.max_loop,
      deterministic=args.deterministic,
      random_seed?=args.random_seed,
      reg_policy=args.reg_policy,
      mem_policy=args.mem_policy,
      proj,
      Term(sub.tid()),
    ) catch {
      _ => continue
    }
    let visited = result
      .visited()
      .keys()
      .fold(init=state.visited, (acc, t) => acc.add(t))
    state = { ..state, visited, result: state.result.union(result), }
  }
  state
}

///|
fn[T] mark_term(
  result : PropagationResult,
  t : @types.Term[T],
) -> @types.Term[T] {
  let tid = t.tid()
  let t = if result.is_visited(tid) { t.with_visited() } else { t }
  let regs = result.tainted_regs(tid)
  let t = if regs.is_empty() {
    t
  } else {
    @taint.set_term_taint_map(t, @taint.tainted_regs_attr, regs)
  }
  let ptrs = result.tainted_ptrs(tid)
  if ptrs.is_empty() {
    t
  } else {
    @taint.set_term_taint_map(t, @taint.tainted_ptrs_attr, ptrs)
  }
}

///|
/// Marks the program with the results (upstream `marker`): visited terms
/// get the `visited` attribute and tainted terms the `tainted-regs` and
/// `tainted-ptrs` attributes.
pub fn mark(
  result : PropagationResult,
  prog : @types.Term[@types.Program],
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    mark_term(result, sub)
    .map_args(t => mark_term(result, t))
    .map_blks(blk => {
      mark_term(result, blk)
      .map_phis(t => mark_term(result, t))
      .map_defs(t => mark_term(result, t))
      .map_jmps(t => mark_term(result, t))
    })
  })
}

///|
/// Runs the analysis and marks the program (upstream `main`). With
/// `print_coverage` the coverage is printed.
pub fn propagate(args : Args, proj : @project.Project) -> @project.Project {
  let state = analyze(args, proj)
  if args.print_coverage {
    println("Coverage: \{state.coverage_to_string()}")
  }
  proj.map_program(prog => mark(state.result, prog))
}

///|
/// The name of the pass.
pub let name : String = "propagate-taint"

///|
/// The legacy taint propagation pass.
pub fn pass(args? : Args = Args::new()) -> @project.ProjectPass {
  @project.ProjectPass::create(name~, run=proj => Ok(propagate(args, proj)))
}

///|
/// Registers the `propagate-taint` pass (upstream `declare_extension`).
/// Idempotent: returns `Ok(false)` if the pass was already registered.
pub fn register(args? : Args = Args::new()) -> Result[Bool, String] {
  @project.register_pass_if_absent(pass(args~))
}
