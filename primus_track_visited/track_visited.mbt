///|
/// # Tracking of the terms visited by Primus (upstream `lib/bap_primus_track_visited`)
///
/// Provides the `bap:mark-visited` component and an interface to the set
/// of basic blocks visited during Primus evaluation.
///
/// - When the system starts, the component adds all blocks that have the
///   `visited` attribute to the set of already visited blocks (this is
///   done when the state is first used), and marks with the `dead`
///   attribute every block (and its definitions and jumps) that is not
///   already marked with the `visited` attribute.
/// - Every time a block is entered it is added to the set and the
///   `visited-blocks (visited, total)` observation is posted.
/// - When a stubbed function is called (a Lisp call), all blocks of the
///   subroutine with the same name are added to the set.
/// - When the system stops, the program of the project is updated: every
///   visited block and its definitions and jumps get the `visited`
///   attribute and lose the `dead` attribute.
///
/// The set is shared by all machines (it is a global state).
pub let component_name : String = "mark-visited"

///|
priv struct Tracked {
  visited : @immut_hashset.HashSet[@types.Tid]
  total : Int32
}

///|
fn count_blks(prog : @types.Term[@types.Program]) -> Int32 {
  prog.subs().fold(init=0, (n, sub) => n + sub.blk_count())
}

///|
fn init_visited(
  prog : @types.Term[@types.Program],
) -> @immut_hashset.HashSet[@types.Tid] {
  let mut visited = @immut_hashset.new()
  for sub in prog.subs() {
    for blk in sub.blks() {
      if blk.is_visited() {
        visited = visited.add(blk.tid())
      }
    }
  }
  visited
}

///|
let state : @primus.State[Tracked] = @primus.State::declare_(
  uuid="6edf3c44-3665-4ec1-8537-ef7fbba78d3d",
  name="primus-track-visited",
  inspect=s => {
    List([Atom(s.visited.iter().count().to_string()), Atom(s.total.to_string())])
  },
  proj => {
    let prog = proj.program()
    { visited: init_visited(prog), total: count_blks(prog), }
  },
)

///|
let progress_pair : (
  @primus.Observation[(Int32, Int32)],
  @primus.Statement[(Int32, Int32)],
) = @primus.Observation::provide(
  "visited-blocks",
  inspect=p => List([Atom(p.0.to_string()), Atom(p.1.to_string())]),
  desc="visited-blocks (visited,total) is posted every time a new basic block is visited, where [visited] is the number of already visited blocks and [total] is the total number of blocks in the program.",
)

///|
/// `progress (visited, total)` is posted every time a Primus machine
/// enters a basic block: `visited` is the number of visited blocks and
/// `total` is the number of blocks in the program.
pub let progress : @primus.Observation[(Int32, Int32)] = progress_pair.0

///|
fn visit(m : @primus.Machine, tid : @types.Tid) -> Unit raise {
  let s = m.get_global(state)
  let s = { ..s, visited: s.visited.add(tid), }
  m.post(progress_pair.1, () => (s.visited.iter().count(), s.total))
  m.put_global(state, s)
}

///|
fn visit_stub(m : @primus.Machine, name : String) -> Unit raise {
  guard @primus.Linker::resolve_tid(m, Symbol(name)) is Some(tid) else {
    return
  }
  guard m.program().find_sub(tid) is Some(sub) else { return }
  for blk in sub.blks() {
    visit(m, blk.tid())
  }
}

///|
/// The two markers of upstream: `Live` removes the `dead` attribute and
/// adds the `visited` one, `Dead` adds the `dead` attribute.
priv enum Marker {
  Live
  Dead
}

///|
fn[T] Marker::mark(self : Marker, t : @types.Term[T]) -> @types.Term[T] {
  match self {
    Live => t.del_attr(@types.Attr::dead().key).set_attr(@types.Attr::visited())
    Dead => t.set_attr(@types.Attr::dead())
  }
}

///|
/// Applies the marker to the block and to its definitions and jumps.
fn mark_block(
  blk : @types.Term[@types.Blk],
  marker : Marker,
) -> @types.Term[@types.Blk] {
  marker.mark(blk).map_defs(t => marker.mark(t)).map_jmps(t => marker.mark(t))
}

///|
fn mark_program(
  prog : @types.Term[@types.Program],
  pred : (@types.Term[@types.Blk]) -> Bool,
  marker : Marker,
) -> @types.Term[@types.Program] {
  prog.map_subs(sub => {
    sub.map_blks(blk => if pred(blk) { mark_block(blk, marker) } else { blk })
  })
}

///|
/// Marks the visited blocks of the project program (and their subterms)
/// with the `visited` attribute and removes their `dead` attribute.
pub fn mark_live(m : @primus.Machine) -> Unit {
  let visited = m.get_global(state).visited
  m.update_project(proj => {
    proj.with_program(
      mark_program(proj.program(), b => visited.contains(b.tid()), Live),
    )
  })
}

///|
/// Marks the blocks of the project program that are not marked as
/// `visited` (and their subterms) with the `dead` attribute.
pub fn mark_dead(m : @primus.Machine) -> Unit {
  m.update_project(proj => {
    proj.with_program(mark_program(proj.program(), b => !b.is_visited(), Dead))
  })
}

///|
/// Initializes the tracker in the machine (the `bap:mark-visited`
/// component body).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.enter_blk, blk => visit(m, blk.tid()))
  m.observe(@primus.system_stop, _ => mark_live(m))
  m.observe(@primus.lisp_call, call => visit_stub(m, call.0))
  m.observe(@primus.system_start, _ => mark_dead(m))
}

///|
/// Whether the term was visited: some machine entered it, it was marked
/// with the `visited` attribute when the system started, or it was added
/// with `add`.
///
/// Note: upstream reads the set from the local state, which the tracker
/// never updates (it updates the global one); the port follows the
/// documented behavior and reads the global set.
pub fn mem(m : @primus.Machine, tid : @types.Tid) -> Bool {
  m.get_global(state).visited.contains(tid)
}

///|
/// Forcefully adds the term to the set of visited terms.
pub fn add(m : @primus.Machine, tid : @types.Tid) -> Unit {
  m.update_global(state, s => { ..s, visited: s.visited.add(tid), })
}

///|
/// Forcefully removes the term from the set of visited terms.
pub fn del(m : @primus.Machine, tid : @types.Tid) -> Unit {
  m.update_global(state, s => { ..s, visited: s.visited.remove(tid), })
}

///|
/// All visited terms.
pub fn all(m : @primus.Machine) -> Array[@types.Tid] {
  m.get_global(state).visited.iter().collect()
}

///|
/// The total number of blocks in the program.
pub fn total(m : @primus.Machine) -> Int32 {
  m.get_global(state).total
}

///|
let desc : String = "Marks visited (by Primus) program terms with the [Term.visited] attribute and unvisited with the [Term.dead] attribute. Note, that the attributes are attached only when the system exits"

///|
/// Registers the `bap:mark-visited` component. Idempotent: returns
/// `false` if it was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc~,
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Registers the component and adds it to the legacy main system
/// (upstream `init`). Idempotent.
pub fn init_tracker() -> Unit {
  register() |> ignore
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// Returns the project with all visited-tracking attributes removed (a
/// helper for tests and repeated runs).
pub fn clear_marks(proj : @project.Project) -> @project.Project {
  proj
  .unmark_program_terms(@types.Attr::visited().key)
  .unmark_program_terms(@types.Attr::dead().key)
}
