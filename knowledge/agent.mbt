///|
pub(all) enum AgentReliability {
  Authorative
  Reliable
  Trustworthy
  Doubtful
  Unreliable
} derive(Eq, Debug)

///|
pub extend AgentReliability with Eq::{not_equal, equal}

///|
pub extend AgentReliability with Debug::{to_repr}

///|
struct Agent {
  id_value : String
} derive(Eq, Debug)

///|
pub extend Agent with Eq::{not_equal, equal}

///|
pub extend Agent with Debug::{to_repr}

///|
priv struct AgentInfo {
  name_value : Name
  desc_value : String
  reliability_value : AgentReliability
}

///|
let agent_registry : Map[String, AgentInfo] = Map([])

///|
fn agent_id_of_name(name : Name) -> String {
  @regular.digest_string(name.show()).to_string()
}

///|
fn AgentReliability::weight(self : AgentReliability) -> Int32 {
  match self {
    Authorative => 16
    Reliable => 8
    Trustworthy => 4
    Doubtful => 2
    Unreliable => 1
  }
}

///|
pub fn AgentReliability::authorative() -> AgentReliability {
  Authorative
}

///|
pub fn AgentReliability::reliable() -> AgentReliability {
  Reliable
}

///|
pub fn AgentReliability::trustworthy() -> AgentReliability {
  Trustworthy
}

///|
pub fn AgentReliability::doubtful() -> AgentReliability {
  Doubtful
}

///|
pub fn AgentReliability::unreliable() -> AgentReliability {
  Unreliable
}

///|
pub fn Agent::register(
  name : String,
  pkg? : String,
  desc~ : String = "no description provided",
  reliability~ : AgentReliability = Trustworthy,
) -> Result[Agent, String] {
  let full_name = Name::create(name, pkg?)
  let id = agent_id_of_name(full_name)
  if agent_registry.contains(id) {
    Err("agent \{full_name.show()} is already registered")
  } else {
    agent_registry[id] = {
      name_value: full_name,
      desc_value: desc,
      reliability_value: reliability,
    }
    Ok({ id_value: id, })
  }
}

///|
pub fn Agent::id(self : Agent) -> String {
  self.id_value
}

///|
pub fn Agent::read(id : String, pkg? : String) -> Agent {
  ignore(pkg)
  { id_value: id, }
}

///|
pub fn Agent::persistent() -> Persistent[Agent] {
  Persistent::convert(
    to_persistent=agent => agent.id(),
    of_persistent=id => Ok(Agent::read(id)),
    Persistent::string(),
  )
}

///|
pub fn Agent::registry() -> Array[Agent] {
  let agents = []
  agent_registry.each((id, _) => agents.push({ id_value: id, }))
  agents.sort_by((left, right) => left.id().compare(right.id()))
  agents
}

///|
pub fn Agent::name(self : Agent) -> Name {
  match agent_registry.get(self.id_value) {
    Some(info) => info.name_value
    None => Name::read(self.id_value)
  }
}

///|
pub fn Agent::desc(self : Agent) -> String {
  match agent_registry.get(self.id_value) {
    Some(info) => info.desc_value
    None => ""
  }
}

///|
pub fn Agent::reliability(self : Agent) -> AgentReliability {
  match agent_registry.get(self.id_value) {
    Some(info) => info.reliability_value
    None => Unreliable
  }
}

///|
pub fn Agent::set_reliability(
  self : Agent,
  reliability : AgentReliability,
) -> Result[Unit, String] {
  match agent_registry.get(self.id_value) {
    Some(info) => {
      agent_registry[self.id_value] = {
        ..info,
        reliability_value: reliability,
      }
      Ok(())
    }
    None => Err("unknown agent \{self.id_value}")
  }
}

///|
pub fn Agent::weight(self : Agent) -> Int32 {
  self.reliability().weight()
}
