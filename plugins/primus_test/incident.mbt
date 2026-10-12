// The Primus Testing and Verification framework: incidents and their
// locations (upstream `plugins/primus_test/primus_test_main.ml`).
//
// Each incident is represented by its name and a tuple of locations.
// Each location is a trace of the program counters (the ends of the
// executed blocks) of the machine that created the location. Incidents
// of the same name are partitioned into locality classes: an incident
// `i` subsumes an incident `j` if the endpoint (the last block) of each
// location of `j` is in the trace of the corresponding location of `i`.
// When an incident is reported, it either becomes an instance of an
// existing class (and possibly its new representative), or starts a new
// class.

///|
/// A trace of program counters (upstream `Location.trace`). The most
/// recent point is the first one.
priv struct Trace {
  trace : @list.List[@types.Word]
  switches : @list.List[(Int32, String)]
  initial : String
  length : Int32
}

///|
let empty_trace : Trace = {
  trace: @list.List([]),
  switches: @list.List([]),
  initial: "unknown",
  length: 0,
}

///|
fn Trace::push(self : Trace, pc : @types.Word, machine : String) -> Trace {
  match self.trace {
    Empty =>
      {
        trace: @list.singleton(pc),
        initial: machine,
        switches: @list.List([]),
        length: 1,
      }
    More(last, ..) => {
      let current = match self.switches {
        More((_, id), ..) => id
        Empty => self.initial
      }
      let t = if last == pc {
        self
      } else {
        { ..self, trace: self.trace.prepend(pc), length: self.length + 1, }
      }
      if current == machine {
        t
      } else {
        {
          ..t,
          trace: t.trace.prepend(pc),
          switches: t.switches.prepend((t.length, machine)),
          length: t.length + 1,
        }
      }
    }
  }
}

///|
/// The points of the trace, prefixed with the machine that visited them
/// (the oldest first), e.g., `0:400120`.
fn Trace::points(self : Trace) -> Array[String] {
  let sw = self.switches.rev().to_array()
  let pts = self.trace.rev().to_array()
  let out = []
  let mut id = self.initial
  let mut k = 0
  for pos, p in pts {
    while k < sw.length() && sw[k].0 == pos {
      id = sw[k].1
      k += 1
    }
    out.push("\{id}:\{p.to_hex(prefix=false)}")
  }
  out
}

///|
fn Trace::point_set(self : Trace) -> @sorted_set.SortedSet[String] {
  @sorted_set.SortedSet::from_iter(self.trace.iter().map(w => w.to_hex()))
}

///|
fn Trace::last_blk(self : Trace) -> String? {
  match self.trace {
    More(_, tail=More(blk, ..)) => Some(blk.to_hex())
    More(blk, tail=Empty) => Some(blk.to_hex())
    Empty => None
  }
}

///|
/// An incident class: the point sets and the traces of its representative.
priv struct Cls {
  points : Array[@sorted_set.SortedSet[String]]
  traces : Array[Trace]
}

///|
priv struct Incidents {
  locations : @sorted_map.SortedMap[Int32, Trace]
  incidents : @sorted_map.SortedMap[String, @sorted_map.SortedMap[Int32, Cls]]
}

///|
let trace_state : @primus.State[Trace] = @primus.State::declare_(
  uuid="3663b645-87a6-4561-b75f-c447cdc221bc",
  name="program-trace",
  _ => empty_trace,
)

///|
let incidents_state : @primus.State[Incidents] = @primus.State::declare_(
  uuid="22d66ae9-82ad-4185-a1f8-5eb99f5569df",
  name="incident-locations",
  _ => {
    locations: @sorted_map.SortedMap::new(),
    incidents: @sorted_map.SortedMap::new(),
  },
)

///|
fn key_value(m : @primus.Machine, key : Int32) -> @primus.Value raise {
  @primus.Value::of_int(m, width=63, key)
}

///|
fn value_key(v : @primus.Value) -> Int32 {
  v.to_word().to_int() catch {
    _ => -1
  }
}

///|
let location_obs : (
  @primus.Observation[(Int32, Array[String])],
  @primus.Statement[(Int32, Array[String])],
) = @primus.Observation::provide(
  "incident-location",
  desc="Occurs when the location of a possible incident is created.",
  inspect=x => List([Atom(x.0.to_string()), List(x.1.map(p => Atom(p)))]),
)

///|
/// Occurs when the location of a possible incident is created: the key of
/// the location and its trace (the oldest point first).
pub let incident_location : @primus.Observation[(Int32, Array[String])] = location_obs.0

///|
fn inspect_instance(x : (String, Int32, Array[Int32])) -> @primus.Sexp {
  List(
    [@primus.Sexp::Atom(x.0), Atom(x.1.to_string())] +
    x.2.map(k => @primus.Sexp::Atom(k.to_string())),
  )
}

///|
let new_instance_obs : (
  @primus.Observation[(String, Int32, Array[Int32])],
  @primus.Statement[(String, Int32, Array[Int32])],
) = @primus.Observation::provide(
  "incident-new-instance",
  desc="Occurs on a new instance of the incident class",
  inspect=inspect_instance,
)

///|
/// Occurs on a new instance of an incident class: the name of the
/// incident, the class, and the locations.
pub let incident_new_instance : @primus.Observation[
  (String, Int32, Array[Int32]),
] = new_instance_obs.0

///|
let new_class_obs : (
  @primus.Observation[(String, Int32, Array[Int32])],
  @primus.Statement[(String, Int32, Array[Int32])],
) = @primus.Observation::provide(
  "incident-new-class",
  desc="Occurs when a new incident class is created",
  inspect=inspect_instance,
)

///|
/// Occurs when a new incident class is created.
pub let incident_new_class : @primus.Observation[(String, Int32, Array[Int32])] = new_class_obs.0

///|
let new_representative_obs : (
  @primus.Observation[(String, Int32, Array[Int32])],
  @primus.Statement[(String, Int32, Array[Int32])],
) = @primus.Observation::provide(
  "incident-new-representative",
  desc="Occurs when a new representative of the class is selected",
  inspect=inspect_instance,
)

///|
/// Occurs when a new representative of an incident class is selected.
pub let incident_new_representative : @primus.Observation[
  (String, Int32, Array[Int32]),
] = new_representative_obs.0

///|
let incident_obs : (
  @primus.Observation[(String, Array[Int32])],
  @primus.Statement[(String, Array[Int32])],
) = @primus.Observation::provide(
  "incident",
  desc="Occurs when the incident is reported that involves the given locations.",
  inspect=x => {
    List(
      [@primus.Sexp::Atom(x.0)] +
      x.1.map(k => @primus.Sexp::Atom(k.to_string())),
    )
  },
)

///|
/// Occurs when an incident is reported: its name and the keys of its
/// locations.
pub let incident : @primus.Observation[(String, Array[Int32])] = incident_obs.0

///|
/// Records the end of every executed block in the trace of the machine
/// (upstream component `incident-location-recorder`).
pub fn record_locations(m : @primus.Machine) -> Unit {
  m.observe(@primus.leave_blk, _ => {
    let pc = @primus.Interpreter::pc(m)
    let id = m.current().to_string()
    m.update_local(trace_state, t => t.push(pc, id))
  })
}

///|
/// Creates a new location from the current trace and returns its key
/// (upstream `incident-location`).
pub fn new_location(m : @primus.Machine) -> Int32 raise {
  let pc = @primus.Interpreter::pc(m)
  let t = m.get_local(trace_state).push(pc, m.current().to_string())
  let s = m.get_global(incidents_state)
  let key = match s.locations.rev_keys().head() {
    None => 1
    Some(k) => k + 1
  }
  m.put_global(incidents_state, { ..s, locations: s.locations.add(key, t), })
  m.post(location_obs.1, () => (key, t.points()))
  key
}

///|
fn is_member(cls : Cls, traces : Array[Trace]) -> Bool {
  if cls.points.length() != traces.length() {
    return false
  }
  for i, t in traces {
    match t.last_blk() {
      Some(b) => if !cls.points[i].contains(b) { return false }
      None => return false
    }
  }
  true
}

///|
/// Reports an incident with the given locations (upstream
/// `incident-report`) and classifies it.
pub fn report(
  m : @primus.Machine,
  name : String,
  locations : Array[Int32],
) -> Unit raise {
  m.make(incident_obs.1, (name, locations))
  let s = m.get_global(incidents_state)
  let traces = locations.map(k => {
    match s.locations.get(k) {
      Some(t) => t
      None => empty_trace
    }
  })
  let cls1 = { points: traces.map(t => t.point_set()), traces, }
  let set_cls = (id : Int32, cls : Cls) => {
    let s = m.get_global(incidents_state)
    let classes = match s.incidents.get(name) {
      Some(c) => c
      None => @sorted_map.SortedMap::new()
    }
    m.put_global(incidents_state, {
      ..s,
      incidents: s.incidents.add(name, classes.add(id, cls)),
    })
  }
  let classes = match s.incidents.get(name) {
    Some(c) => c
    None => @sorted_map.SortedMap::new()
  }
  let mut found = false
  for kv in classes.iter() {
    let (id, cls) = kv
    if is_member(cls, traces) {
      m.make(new_instance_obs.1, (name, id, locations))
      found = true
      break
    } else if is_member(cls1, cls.traces) {
      m.make(new_instance_obs.1, (name, id, locations))
      m.make(new_representative_obs.1, (name, id, locations))
      set_cls(id, cls1)
      found = true
      break
    }
  }
  if !found {
    let id = match classes.rev_keys().head() {
      None => 1
      Some(k) => k + 1
    }
    m.make(new_class_obs.1, (name, id, locations))
    m.make(new_instance_obs.1, (name, id, locations))
    set_cls(id, cls1)
  }
}

///|
/// Defines the Lisp primitives `(incident-location)` and
/// `(incident-report NAME LOC ...)` (upstream component `lisp-incidents`).
pub fn install_lisp(m : @primus.Machine) -> Unit {
  @primus_lisp.define_host_primitive(
    m,
    "incident-location",
    types="() -> sym",
    docs="(incident-location) creates a new location of a possible incident",
    (m, _) => key_value(m, new_location(m)),
  )
  @primus_lisp.define_host_primitive(
    m,
    "incident-report",
    types="(sym // all sym) -> bool",
    docs="(incident-report NAME LOC ...) reports an incident with the given locations",
    (m, args) => {
      match args {
        [name, .. locs] => {
          let name = @primus.Value::symbol_of_value(m, name)
          report(m, name, locs.to_owned().map(value_key))
          @primus.Value::b1(m)
        }
        _ =>
          m.raise_exn(
            @primus.PrimusError::RuntimeError("incident-report: expects a name"),
          )
      }
    },
  )
}
