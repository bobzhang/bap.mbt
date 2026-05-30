///|
struct ProjectCollator[S, R] {
  name_value : String
  description_value : String
  prepare_fn : (Project) -> S
  collate_fn : (Int, S, Project) -> S
  summary_fn : (S) -> R
}

///|
struct ProjectCollatorInfo {
  name_value : String
  description_value : String
}

///|
struct RegisteredProjectCollator {
  info_value : ProjectCollatorInfo
  apply_fn : (Array[Project]) -> Unit
}

///|
let project_collator_registry : Map[String, RegisteredProjectCollator] = {}

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
pub fn ProjectCollatorInfo::name(self : ProjectCollatorInfo) -> String {
  self.name_value
}

///|
pub fn ProjectCollatorInfo::description(self : ProjectCollatorInfo) -> String {
  self.description_value
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
pub fn[S, R] ProjectCollator::info(
  self : ProjectCollator[S, R],
) -> ProjectCollatorInfo {
  { name_value: self.name(), description_value: self.description() }
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

///|
pub fn[S] RegisteredProjectCollator::create(
  name~ : String,
  description? : String,
  prepare~ : (Project) -> S,
  collate~ : (Int, S, Project) -> S,
  summary~ : (S) -> Unit,
) -> RegisteredProjectCollator {
  let collator = ProjectCollator::create(
    name~,
    description?,
    prepare~,
    collate~,
    summary~,
  )
  RegisteredProjectCollator::from_collator(collator)
}

///|
pub fn[S] RegisteredProjectCollator::from_collator(
  collator : ProjectCollator[S, Unit],
) -> RegisteredProjectCollator {
  {
    info_value: collator.info(),
    apply_fn: projects => ignore(collator.apply(projects)),
  }
}

///|
pub fn RegisteredProjectCollator::name(
  self : RegisteredProjectCollator,
) -> String {
  self.info_value.name()
}

///|
pub fn RegisteredProjectCollator::description(
  self : RegisteredProjectCollator,
) -> String {
  self.info_value.description()
}

///|
pub fn RegisteredProjectCollator::info(
  self : RegisteredProjectCollator,
) -> ProjectCollatorInfo {
  self.info_value
}

///|
pub fn RegisteredProjectCollator::apply(
  self : RegisteredProjectCollator,
  projects : Array[Project],
) -> Unit {
  (self.apply_fn)(projects)
}

///|
pub fn register_collator(
  collator : RegisteredProjectCollator,
) -> Result[Unit, String] {
  let name = collator.name()
  if project_collator_registry.contains(name) {
    Err("project collator \{name} is already registered")
  } else {
    project_collator_registry[name] = collator
    Ok(())
  }
}

///|
pub fn find_collator(name : String) -> RegisteredProjectCollator? {
  project_collator_registry.get(name)
}

///|
pub fn registered_collators() -> Array[ProjectCollatorInfo] {
  let result = []
  project_collator_registry.each((_, collator) => result.push(collator.info()))
  result
}
