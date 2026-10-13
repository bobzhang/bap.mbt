// The symbolic path explorer (upstream `forker`).
//
// When the system starts the current machine becomes the *master*: it
// forks a first worker that executes the program with the initial
// (generated) inputs and stays suspended at the start of the program.
// Every time a worker evaluates a symbolic branch condition that
// deviates from the concrete execution, it queues a *task*: the
// constraints under which the other side is taken, together with the
// inputs they mention. When the master is resumed (a scheduler switches
// back to it once the worker is finished), it pops the newest task whose
// constraints are satisfiable, forks a new worker, and the worker stores
// the inputs of the model into the machine before it re-executes the
// program from the start. When no task is left the master halts.

///|
/// A control flow edge: its destination (upstream also keeps the source
/// block and jump, which are only printed).
priv struct Edge {
  dst : @types.JmpDst
}

///|
/// A queued execution: the constraints the inputs must satisfy, the
/// inputs to generate, the edge it should take (if it is a branch) and
/// the term that created it.
priv struct Task {
  constraints : @sorted_set.SortedSet[@z3.Expr]
  inputs : @sorted_set.SortedSet[Input]
  edge : Edge?
  id : @types.Tid
}

///|
priv struct Master {
  self_ : @primus.Id?
  ready : Int32
  tasks : @sorted_map.SortedMap[Int32, Task]
  /// the number of queued or finished forks per term
  tries : @immut_hashmap.HashMap[@types.Tid, Int32]
}

///|
let master : @primus.State[Master] = @primus.State::declare_(
  uuid="8d2b41d4-4852-40e9-917a-33f1f5af01a1",
  name="symbolic-executor-master",
  _ => {
    self_: None,
    ready: 0,
    tasks: @sorted_map.new(),
    tries: @immut_hashmap.new(),
  },
)

///|
let null_tid : @types.Tid = @types.Tid::create()

///|
priv struct Worker {
  tid : @types.Tid
  task : Task
}

///|
let worker : @primus.State[Worker] = @primus.State::declare_(
  uuid="92f3042c-ba8f-465a-9d57-4c1b9ec7c186",
  name="symbolic-executor-worker",
  _ => {
    tid: null_tid,
    task: {
      id: null_tid,
      edge: None,
      constraints: @sorted_set.new(),
      inputs: @sorted_set.new(),
    },
  },
)

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-symbolic-executor",
)

///|
/// The number of times the same branch is retried (the `cutoff-level`
/// option, 1 by default).
let cutoff : Ref[Int32] = Ref(1)

///|
/// Sets the number of times the same branch is retried.
pub fn set_cutoff(n : Int32) -> Unit {
  cutoff.val = n
}

///|
/// The number of tasks queued by the workers and not yet processed.
pub fn pending_tasks(m : @primus.Machine) -> Int32 {
  m.get_global(master).tasks.length()
}

///|
fn max_key(tasks : @sorted_map.SortedMap[Int32, Task]) -> Int32? {
  for k in tasks.rev_keys() {
    return Some(k)
  }
  None
}

///|
fn count(
  tries : @immut_hashmap.HashMap[@types.Tid, Int32],
  key : @types.Tid,
) -> Int32 {
  tries.get(key).unwrap_or(0)
}

///|
fn is_visited(m : @primus.Machine, dst : @types.JmpDst) -> Bool {
  match @types.Jmp::resolve(dst) {
    ResolvedTarget(tid) => @primus_track_visited.mem(m, tid)
    IndirectTarget(_) => false
  }
}

///|
/// The edge of the current position, if it is a jump of a block with
/// several jumps (a branch point).
fn compute_edge(pos : @primus.Pos) -> Edge? {
  guard pos is Jmp({ me: src, up: { me: blk, .. }, }) else { return None }
  guard blk.jmps().length() > 1 else { return None }
  let dst = match src.alt() {
    None => src.dst()
    dst => dst
  }
  match dst {
    None => None
    Some(dst) => Some({ dst, })
  }
}

///|
fn new_task(
  m : @primus.Machine,
  constr : @z3.Expr,
  refute~ : Bool,
  edge? : Edge,
) -> Unit raise @z3.Z3Error {
  let formula = smt_formula(constr, refute~)
  let contra = smt_formula(constr, refute=!refute)
  let self_ = m.get_local(worker)
  if self_.task.constraints.contains(contra) {
    return
  }
  let user = get_constraints(m, User)
  let constraints = user.union(self_.task.constraints).add(formula)
  let inputs = m.get_local(executor).inputs.union(self_.task.inputs)
  let task = { inputs, constraints, edge, id: self_.tid, }
  m.update_global(master, s => {
    let key = match max_key(s.tasks) {
      None => 0
      Some(k) => k + 1
    }
    { ..s, tasks: s.tasks.add(key, task), }
  })
}

///|
fn on_cond(m : @primus.Machine, cond : @primus.Value) -> Unit {
  guard value_formula(m, cond) is Some(constr) else { return }
  match compute_edge(@primus.Interpreter::pos(m)) {
    Some(edge) =>
      if cond.is_zero() && !is_visited(m, edge.dst) {
        new_task(m, constr, refute=false, edge~) catch {
          _ => ()
        }
      }
    None => {
      let self_ = m.get_local(worker)
      if count(m.get_global(master).tries, self_.tid) < cutoff.val {
        new_task(m, constr, refute=cond.is_one()) catch {
          _ => ()
        }
      }
    }
  }
}

///|
/// Pops the newest task that is not exhausted, whose edge is not visited
/// yet, and whose constraints are satisfiable.
fn pop_task(m : @primus.Machine) -> (@z3.Model, Task)? {
  let s = m.get_global(master)
  let queued = s.tasks.length()
  let mut ts = s.tasks
  let mut found = None
  while max_key(ts) is Some(k) {
    let t = ts.get(k).unwrap()
    ts = ts.remove(k)
    let exhausted = count(s.tries, t.id) > cutoff.val ||
      (match t.edge {
        None => false
        Some(e) => is_visited(m, e.dst)
      })
    if exhausted {
      continue
    }
    match smt_check(t.constraints.to_array()) {
      None => continue
      Some(model) => {
        found = Some((model, t))
        break
      }
    }
  }
  match found {
    None => {
      let ready = s.ready + queued
      log.report_progress(stage=ready - 1, total=ready)
      m.put_global(master, { ..s, tasks: @sorted_map.new(), })
      None
    }
    Some((model, t)) => {
      let left = ts.length()
      let processed = queued - left
      log.report_progress(stage=s.ready + processed - 2, total=s.ready + queued)
      m.put_global(master, {
        ..s,
        tasks: ts,
        ready: s.ready + processed,
        tries: s.tries.add(t.id, count(s.tries, t.id) + 1),
      })
      Some((model, t))
    }
  }
}

///|
/// Stores the model values of the task inputs into the worker.
fn exec_task(m : @primus.Machine, model : @z3.Model, task : Task) -> Unit raise {
  debug(m, "SAT")
  m.update_local(worker, w => { ..w, task, })
  for input in task.inputs {
    guard model_get(model, input) is Some(value) else { continue }
    guard value.to_word() is Some(word) else { continue }
    debug(m, "\{input.to_symbol()} = \{value}")
    let v = @primus.Value::of_word(m, word)
    set_input(m, input, v)
    input.set(m, v)
  }
}

///|
fn run_master(m : @primus.Machine) -> Unit raise {
  let s = m.get_global(master)
  match s.self_ {
    None => {
      let master_pid = m.current()
      debug(m, "starting the master process with pid \{master_pid}")
      m.put_global(master, { ..s, self_: Some(master_pid), })
      m.fork(then=m => {
        let client_pid = m.current()
        debug(m, "the first fork returns at \{client_pid}")
        if client_pid == master_pid {
          run_master(m)
        }
      })
    }
    Some(master_pid) =>
      match pop_task(m) {
        None => {
          debug(m, "Worklist is empty, finishing")
          @primus.Interpreter::halt(m)
        }
        Some((model, task)) => {
          debug(m, "We have some tasks")
          m.fork(then=m => {
            if m.current() == master_pid {
              debug(m, "Client is finished, master is resumed")
              run_master(m)
            } else {
              debug(m, "Forked a new machine")
              exec_task(m, model, task)
            }
          })
        }
      }
  }
}

///|
/// Installs the path explorer in the machine (the
/// `bap:symbolic-path-explorer` component).
pub fn install_path_explorer(m : @primus.Machine) -> Unit {
  m.observe(@primus.eval_cond, cond => on_cond(m, cond))
  m.observe(@primus.enter_term, tid => {
    m.update_local(worker, w => { ..w, tid, })
  })
  m.observe(@primus.system_start, _ => run_master(m))
}
