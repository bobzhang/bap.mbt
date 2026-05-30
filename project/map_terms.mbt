///|
pub fn Project::map_program_terms(
  self : Project,
  f : (@types.IrTerm) -> @types.IrTerm,
) -> Project {
  self.map_program(program => program.map_program_terms(f))
}

///|
pub fn Project::mark_program_terms(
  self : Project,
  predicate : (@types.IrTerm) -> Bool,
  attr : @types.Attr,
) -> Project {
  self.map_program_terms(term => {
    if predicate(term) {
      term.set_attr(attr)
    } else {
      term
    }
  })
}

///|
pub fn Project::unmark_program_terms(self : Project, key : String) -> Project {
  self.map_program_terms(term => term.del_attr(key))
}
