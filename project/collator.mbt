///|
struct ProjectCollator[S, R] {
  name_value : @knowledge.Name
  description_value : String
  prepare_fn : (Project) -> S
  collate_fn : (Int, S, Project) -> S
  summary_fn : (S) -> R
}

///|
struct ProjectCollatorInfo {
  name_value : @knowledge.Name
  description_value : String
}

///|
struct RegisteredProjectCollator {
  info_value : ProjectCollatorInfo
  apply_fn : (Array[Project]) -> Unit
}

///|
let project_collator_registry : Map[String, RegisteredProjectCollator] = Map([])

///|
let project_collator_registry_order : Array[String] = []

///|
let project_registry_default_description = "not provided"

///|
pub fn[S, R] ProjectCollator::create(
  name~ : String,
  pkg? : String,
  description? : String,
  prepare~ : (Project) -> S,
  collate~ : (Int, S, Project) -> S,
  summary~ : (S) -> R,
) -> ProjectCollator[S, R] {
  {
    name_value: @knowledge.Name::read(name, pkg?),
    description_value: match description {
      Some(text) => text
      None => project_registry_default_description
    },
    prepare_fn: prepare,
    collate_fn: collate,
    summary_fn: summary,
  }
}

///|
pub fn ProjectCollatorInfo::name(self : ProjectCollatorInfo) -> String {
  self.name_value.unqualified()
}

///|
pub fn ProjectCollatorInfo::qualified_name(
  self : ProjectCollatorInfo,
) -> @knowledge.Name {
  self.name_value
}

///|
pub fn ProjectCollatorInfo::pkg(self : ProjectCollatorInfo) -> String {
  self.name_value.pkg()
}

///|
pub fn ProjectCollatorInfo::description(self : ProjectCollatorInfo) -> String {
  self.description_value
}

///|
pub fn ProjectCollatorInfo::desc(self : ProjectCollatorInfo) -> String {
  self.description()
}

///|
pub fn[S, R] ProjectCollator::name(self : ProjectCollator[S, R]) -> String {
  self.name_value.unqualified()
}

///|
pub fn[S, R] ProjectCollator::qualified_name(
  self : ProjectCollator[S, R],
) -> @knowledge.Name {
  self.name_value
}

///|
pub fn[S, R] ProjectCollator::pkg(self : ProjectCollator[S, R]) -> String {
  self.name_value.pkg()
}

///|
pub fn[S, R] ProjectCollator::description(
  self : ProjectCollator[S, R],
) -> String {
  self.description_value
}

///|
pub fn[S, R] ProjectCollator::desc(self : ProjectCollator[S, R]) -> String {
  self.description()
}

///|
pub fn[S, R] ProjectCollator::info(
  self : ProjectCollator[S, R],
) -> ProjectCollatorInfo {
  { name_value: self.qualified_name(), description_value: self.description(), }
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
  pkg? : String,
  description? : String,
  prepare~ : (Project) -> S,
  collate~ : (Int, S, Project) -> S,
  summary~ : (S) -> Unit,
) -> RegisteredProjectCollator {
  let collator = ProjectCollator::create(
    name~,
    pkg?,
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
pub fn RegisteredProjectCollator::qualified_name(
  self : RegisteredProjectCollator,
) -> @knowledge.Name {
  self.info_value.qualified_name()
}

///|
pub fn RegisteredProjectCollator::pkg(
  self : RegisteredProjectCollator,
) -> String {
  self.info_value.pkg()
}

///|
pub fn RegisteredProjectCollator::description(
  self : RegisteredProjectCollator,
) -> String {
  self.info_value.description()
}

///|
pub fn RegisteredProjectCollator::desc(
  self : RegisteredProjectCollator,
) -> String {
  self.description()
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
  let name = collator.qualified_name().show()
  if project_collator_registry.contains(name) {
    Err("project collator \{name} is already registered")
  } else {
    project_collator_registry[name] = collator
    project_collator_registry_order.push(name)
    Ok(())
  }
}

///|
pub fn[S] register_project_collator(
  name~ : String,
  pkg? : String,
  description? : String,
  prepare~ : (Project) -> S,
  collate~ : (Int, S, Project) -> S,
  summary~ : (S) -> Unit,
) -> Result[Unit, String] {
  register_collator(
    RegisteredProjectCollator::create(
      name~,
      pkg?,
      description?,
      prepare~,
      collate~,
      summary~,
    ),
  )
}

///|
pub fn find_collator(
  name : String,
  pkg? : String,
) -> RegisteredProjectCollator? {
  project_collator_registry.get(@knowledge.Name::read(name, pkg?).show())
}

///|
pub fn registered_collators() -> Array[ProjectCollatorInfo] {
  let result = []
  for name in project_collator_registry_order {
    match project_collator_registry.get(name) {
      Some(collator) => result.push(collator.info())
      None => ()
    }
  }
  result
}
