///|
priv struct OpinionEntry[T] {
  value : T
  votes : Array[Agent]
}

///|
struct Opinions[T] {
  entries_value : Array[OpinionEntry[T]]
  empty_value : T
  equal_fn : (T, T) -> Bool
  inspect_fn : (T) -> String
}

///|
pub fn[T] Opinions::empty(
  empty~ : T,
  equal~ : (T, T) -> Bool,
  inspect~ : (T) -> String,
) -> Opinions[T] {
  {
    entries_value: [],
    empty_value: empty,
    equal_fn: equal,
    inspect_fn: inspect,
  }
}

///|
pub fn[T] Opinions::of_list(
  entries : Array[(Agent, T)],
  empty~ : T,
  equal~ : (T, T) -> Bool,
  inspect~ : (T) -> String,
) -> Opinions[T] {
  let mut result = Opinions::empty(empty~, equal~, inspect~)
  for entry in entries {
    result = result.add(entry.0, entry.1)
  }
  result
}

///|
fn[T] Opinions::copy(self : Opinions[T]) -> Opinions[T] {
  {
    entries_value: self.entries_value.map(entry => {
      value: entry.value,
      votes: entry.votes.copy(),
    }),
    empty_value: self.empty_value,
    equal_fn: self.equal_fn,
    inspect_fn: self.inspect_fn,
  }
}

///|
fn agent_vote_key(agents : Array[Agent]) -> String {
  let ids = [ for agent in agents => agent.id() ]
  ids.sort_by((left, right) => left.compare(right))
  ids.join("|")
}

///|
fn agent_vote_weight(agents : Array[Agent]) -> Int32 {
  let mut weight = 0
  for agent in agents {
    weight = weight + agent.weight()
  }
  weight
}

///|
fn[T] opinion_entry_compare(
  left : OpinionEntry[T],
  right : OpinionEntry[T],
) -> Int32 {
  let weight_order = agent_vote_weight(left.votes).compare(
    agent_vote_weight(right.votes),
  )
  if weight_order != 0 {
    weight_order
  } else {
    agent_vote_key(left.votes).compare(agent_vote_key(right.votes))
  }
}

///|
fn[T] Opinions::add_entry(
  self : Opinions[T],
  value : T,
  votes : Array[Agent],
) -> Opinions[T] {
  if (self.equal_fn)(value, self.empty_value) {
    return self.copy()
  }
  let next = self.copy()
  for i in 0..<next.entries_value.length() {
    let entry = next.entries_value[i]
    if (self.equal_fn)(entry.value, value) {
      let merged = entry.votes.copy()
      for agent in votes {
        if !merged.contains(agent) {
          merged.push(agent)
        }
      }
      next.entries_value[i] = { value: entry.value, votes: merged, }
      return next
    }
  }
  next.entries_value.push({ value, votes: votes.copy(), })
  next
}

///|
pub fn[T] Opinions::add(
  self : Opinions[T],
  agent : Agent,
  value : T,
) -> Opinions[T] {
  self.add_entry(value, [agent])
}

///|
pub fn[T] Opinions::merge(
  self : Opinions[T],
  other : Opinions[T],
) -> Opinions[T] {
  let mut result = self.copy()
  for entry in other.entries_value {
    result = result.add_entry(entry.value, entry.votes)
  }
  result
}

///|
pub fn[T] Opinions::join(
  self : Opinions[T],
  other : Opinions[T],
) -> Opinions[T] {
  self.merge(other)
}

///|
pub fn[T] Opinions::is_empty(self : Opinions[T]) -> Bool {
  self.entries_value.is_empty()
}

///|
pub fn[T] Opinions::total_weight(self : Opinions[T]) -> Int32 {
  let mut weight = 0
  for entry in self.entries_value {
    weight = weight + agent_vote_weight(entry.votes)
  }
  weight
}

///|
pub fn[T] Opinions::compare_votes(
  self : Opinions[T],
  other : Opinions[T],
) -> Int32 {
  self.total_weight().compare(other.total_weight())
}

///|
pub fn[T] Opinions::choice(self : Opinions[T]) -> T {
  let mut best : OpinionEntry[T]? = None
  for entry in self.entries_value {
    match best {
      Some(current) =>
        if opinion_entry_compare(entry, current) > 0 {
          best = Some(entry)
        }
      None => best = Some(entry)
    }
  }
  match best {
    Some(entry) => entry.value
    None => self.empty_value
  }
}

///|
pub fn[T] Opinions::entries(self : Opinions[T]) -> Array[(T, Array[Agent])] {
  self.entries_value.map(entry => (entry.value, entry.votes.copy()))
}

///|
fn[T] persistent_opinion_entry(
  value_codec : Persistent[T],
) -> Persistent[(T, Array[Agent])] {
  let fields_codec = Persistent::array(Persistent::string())
  let agents_codec = Persistent::array(Agent::persistent())
  Persistent::convert(
    to_persistent=entry => {
      [value_codec.encode(entry.0), agents_codec.encode(entry.1)]
    },
    of_persistent=fields => {
      if fields.length() != 2 {
        return Err(
          "invalid persistent opinion entry encoding: expected 2 fields, got \{fields.length()}",
        )
      }
      let value = match value_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let agents = match agents_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok((value, agents))
    },
    fields_codec,
  )
}

///|
pub fn[T] Opinions::persistent(
  value : Persistent[T],
  empty~ : T,
  equal~ : (T, T) -> Bool,
  inspect~ : (T) -> String,
) -> Persistent[Opinions[T]] {
  let entries_codec = Persistent::array(persistent_opinion_entry(value))
  Persistent::convert(
    to_persistent=opinions => opinions.entries(),
    of_persistent=entries => {
      let mut opinions = Opinions::empty(empty~, equal~, inspect~)
      for entry in entries {
        opinions = opinions.add_entry(entry.0, entry.1)
      }
      Ok(opinions)
    },
    entries_codec,
  )
}

///|
pub fn[T] Opinions::inspect(self : Opinions[T]) -> String {
  "[\{[ for entry in self.entries_value => (self.inspect_fn)(entry.value) ].join(", ")}]"
}
