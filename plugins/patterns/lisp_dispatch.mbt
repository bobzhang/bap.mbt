///|
/// The name of the Lisp signal made for every matching action (upstream
/// `Action.property` signal).
pub let patterns_action_signal : String = "bap:patterns-action"

///|
/// The file name under which the default action semantics is loaded.
pub let pattern_actions_file : String = "pattern-actions.lisp"

///|
/// Loads the Lisp program that implements the actions: the default
/// `pattern-actions.lisp` (as a feature named `pattern-actions`), the
/// `extra` sources (name and text, each loaded as a feature named after the
/// file without `.lisp`), on top of the embedded Lisp library. The program
/// is loaded in the context of the target extended with
/// `(patterns enabled)` (upstream `setup_context`).
pub fn load_actions_program(
  target : @core_theory.Target,
  extra? : ArrayView[(String, String)] = [],
) -> @primus_lisp.Program raise {
  let files = [(pattern_actions_file, pattern_actions_lisp), ..extra]
  let features = ["core"]
  for f in files {
    let name = if f.0.has_suffix(".lisp") {
      f.0.unsafe_substring(start=0, end=f.0.length() - 5)
    } else {
      f.0
    }
    features.push(name)
  }
  let loader = @primus_lisp.Loader::chain([
    @primus_lisp.Loader::of_files(files),
    @primus_lisp.Loader::embedded(["lisp"]),
  ])
  let context = @primus_lisp.Context::of_target(target).merge(
    @primus_lisp.Context::create([("patterns", ["enabled"])]),
  )
  @primus_lisp.load_program(loader, features, context~)
}

///|
fn word64(n : UInt64) -> @types.Word {
  @types.Word::of_uint64(width=64, n) catch {
    _ => @types.Word::b0()
  }
}

///|
/// Interprets the matching actions with the Primus Lisp methods of the
/// `bap:patterns-action` signal (upstream: the actions are signaled to the
/// Lisp semantics). Each action is signaled with its name (a symbol), its
/// address and its attributes, accessible with the
/// `(patterns-attribute ATTRS NAME)` primitive; the
/// `(promise-function-start ADDR)` primitive promises a function start.
///
/// Fails if the program can't be run; see `analyze_image` for the fallback
/// to the native handlers.
pub fn analyze_lisp(
  rules : Rules,
  code : ArrayView[@memory.Memory],
  program : @primus_lisp.Program,
  target? : @core_theory.Target = @core_theory.Target::unknown(),
) -> Outcome raise {
  let actions = match_actions(rules, code)
  let ctxt = ActionContext::new()
  // the attributes of the signaled actions, referred by their indices
  let attrs : Array[Action] = []
  let failure : Ref[String?] = { val: None, }
  let proj = @project.Project::empty(target)
  let (status, _) = @primus.Machine::run(
    proj,
    init=m => {
      @primus_lisp.init_runtime(m)
      @primus_lisp.link_program(m, program)
      @primus_lisp.define_host_primitive(
        m,
        "promise-function-start",
        types="(int) -> bool",
        docs="(promise-function-start ADDR) promises that a function starts at ADDR",
        pkg="bap",
        (m, args) => {
          match args {
            [addr] => {
              let accepted = ctxt.promise_function_start(
                addr.to_word().to_uint64(),
              )
              @primus.Value::of_bool(m, accepted)
            }
            _ => raise Failure("promise-function-start: expects one argument")
          }
        },
      )
      @primus_lisp.define_host_primitive(
        m,
        "patterns-attribute",
        types="(any sym) -> sym",
        docs="(patterns-attribute ATTRS NAME) returns the attribute NAME of the attributes ATTRS or NIL if no such attribute is present",
        pkg="bap",
        (m, args) => {
          match args {
            [handle, name] => {
              let i = handle.to_word().to_int() catch { _ => -1 }
              let name = @primus.Value::symbol_of_value(m, name)
              match attrs.get(i) {
                Some(action) =>
                  match action.attribute(name) {
                    Some(v) => @primus.Value::symbol_to_value(m, v)
                    None => @primus.Value::b0(m)
                  }
                None => @primus.Value::b0(m)
              }
            }
            _ => raise Failure("patterns-attribute: expects two arguments")
          }
        },
      )
    },
    start=m => {
      let signal = @knowledge.Name::read(patterns_action_signal)
      let jobs : Array[(UInt64, Action)] = []
      for entry in actions {
        for a in entry.1.to_array() {
          jobs.push((entry.0, a))
        }
      }
      fn go(m : @primus.Machine, i : Int) -> Unit raise {
        if i < jobs.length() {
          let (addr, action) = jobs[i]
          let handle = attrs.length()
          attrs.push(action)
          let args = [
            @primus.Value::symbol_to_value(m, action.name().unqualified()),
            @primus.Value::of_word(m, word64(addr)),
            @primus.Value::of_int(m, width=64, handle),
          ]
          @primus_lisp.eval_signal(m, signal, args, m => go(m, i + 1))
        }
      }

      go(m, 0)
    },
  )
  match status {
    Exn(e) => failure.val = Some(@primus.exn_to_string(e))
    _ => ()
  }
  match failure.val {
    Some(msg) => raise Failure("patterns: the Lisp actions failed: \{msg}")
    None => ctxt.outcome()
  }
}
