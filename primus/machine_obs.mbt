///|
/// Identifier of a machine (fork). The initial machine is `Id::global()`
/// (upstream `Monad.State.Multi.Id` / `Machine.global`).
pub(all) struct Id(Int) derive(Eq, Compare, Hash, Debug)

///|
pub fn Id::global() -> Id {
  Id(0)
}

///|
pub fn Id::to_int(self : Id) -> Int {
  self.0
}

///|
pub impl Show for Id with fn output(self, logger) {
  logger.write_string(self.0.to_string())
}

///|
fn id_sexp(id : Id) -> Sexp {
  Atom(id.0.to_string())
}

///|
fn id_pair_sexp(p : (Id, Id)) -> Sexp {
  List([id_sexp(p.0), id_sexp(p.1)])
}

///|
let exn_raised_stmt : Statement[Error] = Statement::provide(
  "exception",
  inspect=e => Atom(exn_to_string(e)),
  desc="Occurs just before the Machine exception is raised.",
)

///|
/// Occurs just before a machine exception is raised (`Machine.exn_raised`).
pub let exn_raised : Observation[Error] = exn_raised_stmt.obs

///|
let forked_stmt : Statement[(Id, Id)] = Statement::provide(
  "machine-fork",
  inspect=id_pair_sexp,
  desc="Occurs after a machine fork is created.",
)

///|
/// Occurs after a fork is created, with `(parent, child)` (`Machine.fork`).
pub let machine_fork : Observation[(Id, Id)] = forked_stmt.obs

///|
let switched_stmt : Statement[(Id, Id)] = Statement::provide(
  "machine-switch",
  inspect=id_pair_sexp,
  desc="Occurs when machines are switched.",
)

///|
/// Occurs when machines are switched, with `(from, to)` (`Machine.switch`).
pub let machine_switch : Observation[(Id, Id)] = switched_stmt.obs

///|
let killed_stmt : Statement[Id] = Statement::provide(
  "machine-kill",
  inspect=id_sexp,
  desc="Occurs after the given machine is killed. Observations are in the restricted mode.",
)

///|
/// Occurs when a machine is killed (`Machine.kill`); observers run in the
/// restricted mode and in the context of the killed machine.
pub let machine_kill : Observation[Id] = killed_stmt.obs

///|
let started_stmt : Statement[String] = Statement::provide(
  "system-start",
  inspect=s => Atom(s),
  desc="Occurs after the system start.",
)

///|
/// Occurs after the system starts (`Machine.start` / `System.start`).
pub let system_start : Observation[String] = started_stmt.obs

///|
let stopped_stmt : Statement[String] = Statement::provide(
  "system-stop",
  inspect=s => Atom(s),
  desc="Occurs after the system is stopped. Observations are in the restricted mode",
)

///|
/// Occurs after the system is stopped (`Machine.stop` / `System.stop`).
pub let system_stop : Observation[String] = stopped_stmt.obs

///|
let inited_stmt : Statement[Unit] = Statement::provide(
  "init",
  inspect=_ => List([]),
  desc="Occurs when all components of the machine are initialized.",
)

///|
/// Occurs when all components are initialized (`System.init`,
/// `Machine.init`).
pub let system_init : Observation[Unit] = inited_stmt.obs

///|
let finish_stmt : Statement[Unit] = Statement::provide(
  "fini",
  inspect=_ => List([]),
  desc="Occurs when machine finishes.",
)

///|
/// Occurs when a machine finishes (`System.fini`, `Machine.finished`).
pub let system_fini : Observation[Unit] = finish_stmt.obs
