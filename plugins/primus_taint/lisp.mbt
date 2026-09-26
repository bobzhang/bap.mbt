// The Primus Lisp interface of the taint engine (upstream components
// `taint-primitives` and `taint-signals`).

///|
/// Defines the taint primitives as Primus Lisp primitives (upstream
/// component `taint-primitives`).
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

///|
/// Reflects the `taint-finalize` observation into the Lisp signal
/// `(taint-finalize T L)` (upstream component `taint-signals`).
pub fn install_lisp_signals(m : @primus.Machine) -> Unit {
  let params = @primus_lisp.parse_type_spec("(any bool) -> any", 64)
  ignore(
    @primus_lisp.signal(
      m,
      @taint.taint_finalize,
      params?,
      docs=finalize_signal_doc,
      (m, p) => finalize_signal_args(m, p.0, p.1),
    ),
  )
}
