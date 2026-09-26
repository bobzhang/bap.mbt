// The Primus Lisp interface of the constant tracker (upstream component
// `constant-tracker-primitives`).

///|
/// Defines the constant tracker primitives as Primus Lisp primitives.
pub fn install_lisp_primitives(m : @primus.Machine) -> Unit raise {
  install_primitives(p => {
    @primus_lisp.define_host_primitive(
      m,
      p.name,
      types=p.types,
      docs=p.docs,
      p.run,
    )
  })
}
