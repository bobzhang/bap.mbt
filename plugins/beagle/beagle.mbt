///|
/// # Beagle (upstream `plugins/beagle`)
///
/// Beagle is an obfuscated string solver that uses CPU emulation for
/// discovering and decoding strings. Data that pass through the emulator
/// (the values stored to memory) are processed with a low-pass filter
/// (`@strings.StringsDetector`) and string-like patterns are detected. At
/// the final step, words are recovered from a detected shuffled sequence
/// of characters with a scrabble-like algorithm
/// (`@strings.StringsUnscrambler`), parameterized by a dictionary.
///
/// The `bap:beagle-hunter` component watches the Primus machine:
///
/// - `loading` saves the loaded addresses in the hunters club;
/// - `stored` feeds the bytes of the stored value to the detector of the
///   machine; each time the detector decides that a sequence of characters
///   is text, the `beagle-prey` statement is made;
/// - `machine-kill` aborts the detector, reporting the pending prey;
/// - `beagle-prey` prints the characters (`--beagle-print-chars`) and hunts
///   for words, making the `beagle` statement with the words that can be
///   built from the prey (cached across machines);
/// - `beagle` prints the words (`--beagle-print-words`).
///
/// Upstream also has a (disabled) handler for the variable reads and
/// writes; it is not ported.
pub let component_name : String = "beagle-hunter"

///|
/// The name of the plugin.
pub let name : String = "beagle"

///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="beagle",
)

///|
/// The parameters of the analysis (the plugin's command-line options).
pub(all) struct Params {
  /// dictionary files (`--beagle-dictionary`)
  dicts : Array[String]
  /// extra dictionary words (`--beagle-words`)
  words : Array[String]
  /// print all buildable words (`--beagle-print-words`)
  print_words : Bool
  /// print all observed letters (`--beagle-print-chars`)
  print_chars : Bool
  /// expected amount of noise characters (`--beagle-noise`)
  noise : Double
  /// desired probability of a false positive (`--beagle-alpha`)
  alpha : Double
  /// desired probability of a false negative (`--beagle-beta`)
  beta : Double
  /// a prior probability of the search data (`--beagle-text-probability`)
  p1 : Double
  /// the alphabet of words (`--beagle-alphabet`), see `alphabets`
  alphabet : String
  /// where the printed lines go
  output : (String) -> Unit
}

///|
/// The default parameters (upstream defaults).
pub fn Params::default() -> Params {
  {
    dicts: [],
    words: [],
    print_words: false,
    print_chars: false,
    noise: 0.05,
    alpha: 0.05,
    beta: 1.0e-3,
    p1: 0.1,
    alphabet: "printable",
    output: s => println(s),
  }
}

///|
let params : Ref[Params] = { val: Params::default(), }

///|
/// Sets the parameters used by the machines started afterwards.
pub fn configure(p : Params) -> Unit {
  params.val = p
}

///|
/// The current parameters.
pub fn current_params() -> Params {
  params.val
}

///|
/// The names of the supported alphabets (upstream `--beagle-alphabet`).
pub let alphabets : Array[String] = [
  "printable", "alpha", "alpha.caseless", "alphanum", "alphanum.caseless", "digits",
]

///|
/// The alphabet with the given name.
pub fn alphabet_of_name(name : String) -> @strings.StringsAlphabet? {
  match name {
    "printable" => Some(@strings.StringsAlphabet::printable())
    "alpha" => Some(@strings.StringsAlphabet::alpha())
    "alpha.caseless" => Some(@strings.StringsAlphabet::alpha_caseless())
    "alphanum" => Some(@strings.StringsAlphabet::alphanum())
    "alphanum.caseless" => Some(@strings.StringsAlphabet::alphanum_caseless())
    "digits" => Some(@strings.StringsAlphabet::digits())
    _ => None
  }
}

///|
fn selected_alphabet(p : Params) -> @strings.StringsAlphabet {
  alphabet_of_name(p.alphabet).unwrap_or(@strings.StringsAlphabet::printable())
}

///|
/// Builds the word hunter (upstream `hunter` state): a function that
/// returns all words of the dictionary (the dictionary files plus the
/// extra words) that can be built from the given characters.
pub fn make_hunter(p : Params) -> (BytesView) -> @beagle_prey.Words {
  let alphabet = selected_alphabet(p)
  let dict = match @strings.StringsUnscrambler::of_files(alphabet~, p.dicts) {
    Ok(d) => d
    Err(msg) => {
      log.warning(message="failed to load the dictionary: \{msg}")
      @strings.StringsUnscrambler::empty(alphabet~)
    }
  }
  let dict = p.words.fold(init=dict, (d, w) => {
    d.add_word(Bytes::makei(w.length(), i => w[i].to_byte()))
  })
  chars => {
    @beagle_prey.Words::of_array(
      dict.build(chars).map(w => @beagle_prey.latin1(w)),
    )
  }
}

///|
/// Global information shared by all hunters (upstream `hunters_club`): the
/// loaded addresses and the words built for each sequence of characters.
priv struct Addr(@types.Word)

///|
impl Eq for Addr with fn equal(self, other) {
  self.0.compare(other.0) == 0
}

///|
impl Compare for Addr with fn compare(self, other) {
  self.0.compare(other.0)
}

///|
priv struct Club {
  addrs : @sorted_set.SortedSet[Addr]
  cache : @sorted_map.SortedMap[String, @beagle_prey.Words]
}

///|
let club : @primus.State[Club] = @primus.State::declare_(
  uuid="1fa35cfe-f720-473c-a5ac-50fa8fa9f1fd",
  name="beagle-hunters-club",
  _ => { addrs: @sorted_set.new(), cache: @sorted_map.new(), },
)

///|
/// The detector of the machine (upstream `beagle` state).
let beagle : @primus.State[@strings.StringsDetector[@types.Tid]] = @primus.State::declare_(
  uuid="5d404352-722d-4ea1-bddb-aa4e4dc65c1d",
  name="beagle",
  _ => {
    let p = params.val
    @strings.StringsDetector::create(
      selected_alphabet(p),
      alpha=p.alpha,
      beta=p.beta,
      p1=p.p1,
      ps=p.noise,
    )
  },
)

///|
priv struct Hunter((BytesView) -> @beagle_prey.Words)

///|
/// The word hunter of the machine (upstream `hunter` state).
let hunter : @primus.State[Hunter] = @primus.State::declare_(
  uuid="14d5eef5-4b04-418d-8a9f-3a20f52a5e10",
  name="beagle-hunter",
  _ => Hunter(make_hunter(params.val)),
)

///|
/// The addresses loaded by all machines so far.
pub fn loaded_addresses(m : @primus.Machine) -> Array[@types.Word] {
  m.get_global(club).addrs.to_array().map(a => a.0)
}

///|
fn got_prey(
  m : @primus.Machine,
  d : @strings.StringsDecision[@types.Tid],
) -> Unit raise {
  let prey = @beagle_prey.Prey::create(d.data(rev=false), d.chars())
  m.make(@beagle_prey.finished(), prey)
}

///|
/// `true` for the bytes that are never fed to the detector: `\255` and the
/// control characters up to the line feed.
fn is_skipped(c : Byte) -> Bool {
  c == 0xff || c <= 10
}

///|
/// Feeds the bytes of a word (little-endian order) to the detector of the
/// machine, reporting every decided prey (upstream `process_word`).
pub fn process_word(m : @primus.Machine, w : @types.Word) -> Unit raise {
  let curr = @primus.Interpreter::pos(m).tid()
  let mut d = m.get_local(beagle)
  for c in w.enum_chars(endian=LittleEndian) {
    if is_skipped(c) {
      continue
    }
    d = d.step(curr, c)
    match d.decision() {
      Some(dec) => got_prey(m, dec)
      None => ()
    }
  }
  m.put_local(beagle, d)
}

///|
/// Aborts the detector of the machine and reports the pending prey
/// (upstream `gohome`, run when a machine is killed).
pub fn gohome(m : @primus.Machine) -> Unit raise {
  match m.get_local(beagle).abort() {
    None => ()
    Some(d) => got_prey(m, d)
  }
}

///|
/// Builds the words from the prey, caching them by the prey characters,
/// and makes the `beagle` statement (upstream `hunt`).
fn hunt(m : @primus.Machine, prey : @beagle_prey.Prey) -> Unit raise {
  let key = prey.text()
  let words = match m.get_global(club).cache.get(key) {
    Some(words) => words
    None => {
      let Hunter(hunt) = m.get_local(hunter)
      let words = hunt(prey.data())
      m.update_global(club, c => { ..c, cache: c.cache.add(key, words), })
      words
    }
  }
  m.make(@beagle_prey.catch_(), (prey, words))
}

///|
/// Initializes the hunter in the machine (the `bap:beagle-hunter`
/// component body, upstream `Hunter.init`).
pub fn install(m : @primus.Machine) -> Unit {
  m.observe(@primus.loading, addr => {
    m.update_global(club, c => {
      ..c,
      addrs: c.addrs.add(Addr(addr.to_word())),
    })
  })
  m.observe(@primus.stored, x => process_word(m, x.1.to_word()))
  m.observe(@primus.machine_kill, _ => gohome(m))
  m.observe(@beagle_prey.detected(), prey => {
    let p = params.val
    if p.print_chars {
      (p.output)("chars: \{prey.text()}")
    }
  })
  m.observe(@beagle_prey.detected(), prey => hunt(m, prey))
  m.observe(@beagle_prey.caught(), caught => {
    let p = params.val
    if p.print_words {
      for w in caught.1.to_array() {
        (p.output)("word: \{w}")
      }
    }
  })
}

///|
/// Registers the `bap:beagle-hunter` component. Idempotent: returns
/// `false` if it was already registered.
pub fn register() -> Bool {
  @primus.Components::register_generic(
    component_name,
    m => install(m),
    pkg="bap",
    desc="Monitors execution and detects data that looks like words from the provided dictionary.",
  ) catch {
    _ => return false
  }
  true
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// The `beagle` project pass (depends on `strings-collect`): adds the
/// hunter to the legacy main system.
pub fn pass() -> @project.ProjectPass {
  @project.ProjectPass::create(name~, deps=["strings-collect"], run=proj => {
    if !enabled.val {
      enabled.val = true
      @primus.Machine::add_component(m => install(m))
    }
    Ok(proj)
  })
}

///|
/// Registers the component and the project pass.
pub fn enable(p~ : Params = params.val) -> Unit {
  configure(p)
  register() |> ignore
  @project.register_pass_if_absent(pass()) |> ignore
}

///|
let doc : String =
  #|Beagle is an obfuscated string solver that uses CPU emulation for
  #|discovering and decoding strings. Beagle can also be used as an advanced
  #|data cross-referrence tool. Beagle combines Microexecution with digital
  #|signal processing techniques and efficient dictionary search. Data that
  #|pass through a CPU emulator is processed with a low-pass filter and
  #|string-like patterns are detected. At the final step, words are
  #|recovered from a detected shuffled sequence of characters. For this we
  #|employ a scrabble-like algorithm, that will detect all possible words,
  #|that can be built from a given sequence of characters. The algorithm is
  #|parameterized by a dictionary.

///|
/// Declares the `beagle` plugin to `bap_main` with its parameters. Does
/// nothing if already declared.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["deobfuscator", "microx", "primus", "pass", "string", "analysis"],
    doc~,
    () => {
      let d = Params::default()
      let _ = @bap_main.Configuration::flag(
        doc="don't put static strings into the initial dictionary",
        "ignore-strings",
      )
      let dicts = @bap_main.Configuration::parameter(
        doc="Add dictionary file(s).",
        @bap_main.Type::list(@bap_main.Type::file()),
        "dictionary",
      )
      let words = @bap_main.Configuration::parameter(
        doc="Add specified words to the dictionary.",
        @bap_main.Type::list(@bap_main.Type::string()),
        "words",
      )
      let pwords = @bap_main.Configuration::flag(
        doc="Print all buildable words.",
        "print-words",
      )
      let pchars = @bap_main.Configuration::flag(
        doc="Print all observed letters.",
        "print-chars",
      )
      let _ = @bap_main.Configuration::flag(
        doc="Print static strings",
        "print-strings",
      )
      let _ = @bap_main.Configuration::flag(
        doc="Don't try to build words from a dictionary",
        "no-words",
      )
      let noise = @bap_main.Configuration::parameter(
        doc="expected amount of noise characters",
        @bap_main.Type::float().with_default(d.noise),
        "noise",
      )
      let alpha = @bap_main.Configuration::parameter(
        doc="desired probability of a false positive",
        @bap_main.Type::float().with_default(d.alpha),
        "alpha",
      )
      let beta = @bap_main.Configuration::parameter(
        doc="desired probability of a false negative",
        @bap_main.Type::float().with_default(d.beta),
        "beta",
      )
      let p1 = @bap_main.Configuration::parameter(
        doc="a prior probability of the search data",
        @bap_main.Type::float().with_default(d.p1),
        "text-probability",
      )
      let alphabet = @bap_main.Configuration::parameter(
        doc="Build words from the specified alphabet",
        @bap_main.Type::enumeration(alphabets.map(a => (a, a))).with_default(
          d.alphabet,
        ),
        "alphabet",
      )
      @bap_main.Extension::register(ctxt => {
        enable(p={
          ..d,
          dicts: ctxt.get(dicts),
          words: ctxt.get(words),
          print_words: ctxt.get(pwords),
          print_chars: ctxt.get(pchars),
          noise: ctxt.get(noise),
          alpha: ctxt.get(alpha),
          beta: ctxt.get(beta),
          p1: ctxt.get(p1),
          alphabet: ctxt.get(alphabet),
        })
      })
    },
  )
}
