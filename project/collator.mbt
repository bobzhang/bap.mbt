///|
struct ProjectCollator[S, R] {
  name_value : String
  description_value : String
  prepare_fn : (Project) -> S
  collate_fn : (Int, S, Project) -> S
  summary_fn : (S) -> R
}

///|
pub fn[S, R] ProjectCollator::create(
  name~ : String,
  description? : String,
  prepare~ : (Project) -> S,
  collate~ : (Int, S, Project) -> S,
  summary~ : (S) -> R,
) -> ProjectCollator[S, R] {
  {
    name_value: name,
    description_value: match description {
      Some(text) => text
      None => ""
    },
    prepare_fn: prepare,
    collate_fn: collate,
    summary_fn: summary,
  }
}

///|
pub fn[S, R] ProjectCollator::name(self : ProjectCollator[S, R]) -> String {
  self.name_value
}

///|
pub fn[S, R] ProjectCollator::description(
  self : ProjectCollator[S, R],
) -> String {
  self.description_value
}

///|
pub fn[S, R] ProjectCollator::prepare(
  self : ProjectCollator[S, R],
  project : Project,
) -> S {
  (self.prepare_fn)(project)
}

///|
pub fn[S, R] ProjectCollator::collate(
  self : ProjectCollator[S, R],
  version : Int,
  state : S,
  project : Project,
) -> S {
  (self.collate_fn)(version, state, project)
}

///|
pub fn[S, R] ProjectCollator::summary(
  self : ProjectCollator[S, R],
  state : S,
) -> R {
  (self.summary_fn)(state)
}

///|
pub fn[S, R] ProjectCollator::apply(
  self : ProjectCollator[S, R],
  projects : Array[Project],
) -> R? {
  if projects.is_empty() {
    None
  } else {
    let mut state = self.prepare(projects[0])
    for i in 1..<projects.length() {
      state = self.collate(i - 1, state, projects[i])
    }
    Some(self.summary(state))
  }
}
