///|
pub fn Project::callgraph(
  self : Project,
) -> @graphlib.Graph[@types.Tid, Array[@types.Term[@types.Jmp]]] {
  self.program().program_callgraph()
}

///|
pub fn Project::resolved_callgraph(
  self : Project,
  resolve_indirect~ : (@types.Exp) -> Array[@types.Tid],
) -> @graphlib.Graph[@types.Tid, Array[@types.Term[@types.Jmp]]] {
  self.program().program_resolved_callgraph(resolve_indirect~)
}

///|
pub fn Project::callees(
  self : Project,
  sub : @types.Term[@types.Sub],
) -> Array[@types.Tid] {
  self.program().program_callees(sub)
}

///|
pub fn Project::callers(
  self : Project,
  sub : @types.Term[@types.Sub],
) -> Array[@types.Tid] {
  self.program().program_callers(sub)
}

///|
pub fn Project::resolved_callees(
  self : Project,
  sub : @types.Term[@types.Sub],
  resolve_indirect~ : (@types.Exp) -> Array[@types.Tid],
) -> Array[@types.Tid] {
  self.program().program_resolved_callees(sub, resolve_indirect~)
}

///|
pub fn Project::resolved_callers(
  self : Project,
  sub : @types.Term[@types.Sub],
  resolve_indirect~ : (@types.Exp) -> Array[@types.Tid],
) -> Array[@types.Tid] {
  self.program().program_resolved_callers(sub, resolve_indirect~)
}
