///|
let log : @main_event.MainLogReporter = @main_event.MainLogReporter::create(
  section="patterns",
)

///|
/// The outcome of the analysis of a unit (upstream `Analysis.outcome`):
/// the promised function starts and function names.
pub struct Outcome {
  roots : Array[UInt64]
  names : Array[(UInt64, String)]
} derive(Eq, Debug)

///|
pub extend Outcome with Eq::{not_equal, equal}

///|
pub extend Outcome with Debug::{to_repr}

///|
/// The context in which the actions are interpreted: the knowledge
/// accumulated by the actions (upstream `patterns-roots` and
/// `patterns-names` contexts).
pub struct ActionContext {
  priv roots : Map[UInt64, Unit]
  priv names : Map[UInt64, String]
  priv named : Map[String, UInt64]
}

///|
fn ActionContext::new() -> ActionContext {
  { roots: Map([]), names: Map([]), named: Map([]), }
}

///|
/// Promises that a function starts at the address (upstream
/// `promise-function-start` primitive). Always accepted.
pub fn ActionContext::promise_function_start(
  self : ActionContext,
  addr : UInt64,
) -> Bool {
  self.roots[addr] = ()
  true
}

///|
/// Promises a name to the function at the address (upstream
/// `promise_name`): accepted only if neither the address nor the name is
/// already named.
pub fn ActionContext::promise_name(
  self : ActionContext,
  addr : UInt64,
  name : String,
) -> Bool {
  if self.names.contains(addr) || self.named.contains(name) {
    false
  } else {
    self.names[addr] = name
    self.named[name] = addr
    true
  }
}

///|
fn ActionContext::outcome(self : ActionContext) -> Outcome {
  let roots = self.roots.keys().collect()
  roots.sort()
  let names = self.names.iter().collect()
  names.sort_by((a, b) => a.0.compare(b.0))
  { roots, names, }
}

///|
/// An interpretation of the actions: called for each action that matches
/// at an address (upstream signals `bap:patterns-action` with the action
/// name, the address and the attributes, and the Primus Lisp methods of the
/// signal implement the actions).
pub type ActionHandler = (ActionContext, Action, UInt64) -> Unit

///|
/// The name of the `bap` package action with the given name.
pub fn bap_action(name : String) -> @knowledge.Name {
  @knowledge.Name::create(name, pkg="bap")
}

///|
/// The default interpretation of actions, the method shipped with the
/// plugin (`semantics/pattern-actions.lisp`): the `funcstart` and
/// `possiblefuncstart` actions promise a function start.
pub fn default_action_handler(
  ctxt : ActionContext,
  action : Action,
  addr : UInt64,
) -> Unit {
  let name = action.name()
  if name == bap_action("funcstart") || name == bap_action("possiblefuncstart") {
    ctxt.promise_function_start(addr) |> ignore
  }
}

///|
/// The Primus Lisp source of the default action semantics (upstream
/// `plugins/patterns/semantics/pattern-actions.lisp`), for the Primus Lisp
/// semantics compiler.
pub let pattern_actions_lisp : String =
  #|(in-package bap)
  #|
  #|(declare (context (patterns enabled)))
  #|
  #|(defmethod bap:patterns-action (action addr attrs)
  #|  (when (is-in action 'funcstart 'possiblefuncstart)
  #|    (promise-function-start addr)))

///|
let action_handlers : Array[ActionHandler] = [default_action_handler]

///|
/// Adds an interpretation of actions (like adding a Lisp method to the
/// `bap:patterns-action` signal).
pub fn register_action_handler(h : ActionHandler) -> Unit {
  action_handlers.push(h)
}

///|
/// Adds the actions matching in the memory to the map from addresses to
/// actions (upstream `collect_actions`).
pub fn collect_actions(
  rules : Rules,
  mem : @memory.Memory,
  actions : Map[UInt64, ActionSet],
) -> Unit {
  rules.search(
    mem,
    (addr, action, _) => {
      let one = ActionSet::of_array([action])
      actions[addr] = match actions.get(addr) {
        None => one
        Some(xs) => xs.union(one)
      }
    },
    (),
  )
}

///|
/// The actions matching in the memory regions, by address (ascending).
pub fn match_actions(
  rules : Rules,
  code : ArrayView[@memory.Memory],
) -> Array[(UInt64, ActionSet)] {
  let actions : Map[UInt64, ActionSet] = Map([])
  for mem in code {
    collect_actions(rules, mem, actions)
  }
  let out = actions.iter().collect()
  out.sort_by((a, b) => a.0.compare(b.0))
  out
}

///|
/// Applies the rules to the code regions and interprets the matching
/// actions (upstream `promise_outcome`): actions are applied in the order
/// of addresses.
pub fn analyze(
  rules : Rules,
  code : ArrayView[@memory.Memory],
  handlers? : ArrayView[ActionHandler] = action_handlers,
) -> Outcome {
  let ctxt = ActionContext::new()
  for entry in match_actions(rules, code) {
    for action in entry.1.to_array() {
      for h in handlers {
        h(ctxt, action, entry.0)
      }
    }
  }
  ctxt.outcome()
}

///|
/// The code regions of an image (its executable segments).
pub fn code_regions(image : @image.Image) -> Array[@memory.Memory] {
  image
  .segments()
  .filter(s => s.is_executable())
  .map(s => image.memory_of_segment(s))
}

///|
let lisp_sources : Ref[Array[(String, String)]] = { val: [], }

///|
let use_lisp : Ref[Bool] = { val: true, }

///|
/// Selects how the actions are interpreted by `analyze_image`: with the
/// Primus Lisp methods of `bap:patterns-action` (the default, as upstream),
/// with `extra` Lisp sources loaded after `pattern-actions.lisp`; or, when
/// `lisp` is false, with the native action handlers.
pub fn set_action_semantics(
  lisp? : Bool = true,
  extra? : ArrayView[(String, String)] = [],
) -> Unit {
  use_lisp.val = lisp
  lisp_sources.val = extra.to_owned()
}

///|
/// Analyzes the code of an image with the rules. The actions are
/// interpreted by the Lisp methods (see `set_action_semantics`); if the
/// Lisp program can't be loaded or run, the native handlers are used
/// instead.
pub fn analyze_image(
  image : @image.Image,
  rules : Rules,
  handlers? : ArrayView[ActionHandler] = action_handlers,
) -> Outcome {
  let code = code_regions(image)
  if use_lisp.val {
    let target = image.target().unwrap_or(image.arch())
    let result = try {
      let program = load_actions_program(target, extra=lisp_sources.val)
      analyze_lisp(rules, code, program, target~)
    } catch {
      e => {
        log.warning(message="falling back to the native actions: \{e}")
        None
      }
    } noraise {
      outcome => Some(outcome)
    }
    match result {
      Some(outcome) => return outcome
      None => ()
    }
  }
  analyze(rules, code, handlers~)
}

///|
/// A rooter that provides the function starts of the outcome (upstream
/// promises `Theory.Label.is_subroutine` for them).
pub fn Outcome::rooter(
  self : Outcome,
  path? : String,
) -> @project.ProjectRooter {
  @project.ProjectRooter::create(self.roots, path?)
}

///|
/// A symbolizer that provides the names of the outcome.
pub fn Outcome::symbolizer(
  self : Outcome,
  path? : String,
) -> @project.ProjectSymbolizer {
  let names : Map[UInt64, String] = Map::from_array(self.names)
  @project.ProjectSymbolizer::create(addr => names.get(addr), path?)
}
