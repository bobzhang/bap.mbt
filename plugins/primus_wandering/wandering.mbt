///|
/// # The random wandering Primus scheduler (upstream `plugins/primus_wandering`)
///
/// After every position (`leave_pos`) the scheduler picks the machine to
/// continue with at random. A party of contestants (all live machines,
/// numbered from zero) is drawn and kept in the local state of the
/// machine; every step makes up to four attempts to pick a live
/// contestant with a pseudo-random generator seeded with the `seed`
/// parameter. The winner is removed from the party and the machine
/// switches to it. When the attempts are exhausted (or the party is
/// empty) a new party is drawn and the machine continues. The algorithm
/// terminates since there is always at least one live machine (the
/// global one).
///
/// As upstream, the state of the scheduler is stored in the local state
/// of the machine that makes the draw, and it is saved when that machine
/// is resumed (the `then` continuation of the switch). The scheduler does
/// not react to finished machines, so it is usually combined with a
/// scheduler that does (e.g., the greedy one).
pub let component_name : String = "wondering-scheduler"

///|
/// The number of attempts to pick a live machine before the next draw.
let attempts : Int = 4

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="primus-wandering",
)

///|
let state : @primus.State[@sorted_map.SortedMap[Int, @primus.Id]] = @primus.State::declare_(
  uuid="99883d0e-94b2-41a4-bce6-1e4a949fd919",
  name="wandering-scheduler",
  _ => @sorted_map.new(),
)

///|
/// The current party of contestants of the machine: pairs of the draw
/// number and the machine identifier.
pub fn pending(m : @primus.Machine) -> Array[(Int, @primus.Id)] {
  m.get_local(state).to_array()
}

///|
fn schedule(
  m : @primus.Machine,
  generator : @primus.Generator,
  pending : @sorted_map.SortedMap[Int, @primus.Id],
) -> Unit raise {
  for n = attempts, t = pending {
    if n > 0 && !t.is_empty() {
      let max = t.rev_keys().head().unwrap()
      let i = @primus.Generator::next(m, generator) % (max + 1)
      match t.get(i) {
        None => continue n - 1, t
        Some(id) =>
          if m.status(id) is Dead {
            continue n - 1, t.remove(i)
          } else {
            let t = t.remove(i)
            m.switch(id, then=m => m.put_local(state, t))
            break
          }
      }
    } else {
      let fs = m.forks()
      let party = @sorted_map.SortedMap(fs.mapi((i, id) => (i, id)))
      m.put_local(state, party)
      break
    }
  }
}

///|
/// Initializes the scheduler in the machine (the component body), using
/// a pseudo-random generator with the given seed.
pub fn install(m : @primus.Machine, seed? : Int = 0) -> Unit {
  let generator = @primus.Generator::random_lcg(seed)
  m.observe(@primus.leave_pos, _ => schedule(m, generator, m.get_local(state)))
}

///|
/// Registers the `bap:wondering-scheduler` component (the upstream
/// spelling). Idempotent: returns `false` if the component was already
/// registered (the seed of the first registration is used).
pub fn register(seed? : Int = 0) -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m, seed~),
    pkg="bap",
    desc="Enables the random wonderning scheduler (experimental). The scheduler will pick between the states randomly.",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the scheduler to the legacy main system (upstream
/// `--primus-wandering-scheduler`). Idempotent.
pub fn enable(seed? : Int = 0) -> Unit {
  if !enabled.val {
    enabled.val = true
    log.info(message="enabling the scheduler, using \{seed} as the seed")
    @primus.Machine::add_component(m => install(m, seed~))
  }
}

///|
/// The name of the plugin.
pub let name : String = "primus-wandering"

///|
let doc : String =
  #|schedules Primus machines in a random order
  #|
  #|The random wandering scheduler will pick between the states randomly.

///|
/// Declares the `primus-wandering` plugin to `bap_main` with its
/// `scheduler` flag and `seed` parameter. Does nothing if already
/// declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(name, provides=["primus", "scheduler"], doc~, () => {
    let flag = @bap_main.Configuration::flag(
      "scheduler",
      doc="Enable the scheduler.",
    )
    let seed = @bap_main.Configuration::parameter(
      @bap_main.Type::int(),
      "seed",
      doc="random generator seed",
    )
    @bap_main.Extension::register(ctxt => {
      let seed = ctxt.get(seed)
      register(seed~) |> ignore
      if ctxt.get(flag) {
        enable(seed~)
      }
    })
  })
}
