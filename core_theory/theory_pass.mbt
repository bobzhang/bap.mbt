///|
/// A Core Theory transformation (`Theory.Pass`): a function from a theory
/// to a theory (upstream a functor `Core -> Core`).
pub type Pass = (Core) -> Core

///|
let registered_passes : Map[String, (Pass, String?)] = Map([])

///|
/// `Pass.register ?desc ?package name pass`: registers a named pass. The
/// (qualified) name must be unique.
pub fn register_pass(
  name : String,
  pass : Pass,
  desc? : String,
  pkg? : String,
) -> Unit raise {
  let name = @knowledge.Name::create(name, pkg?).show()
  if registered_passes.contains(name) {
    fail("The name \{name} is already taken, please select a unique name")
  }
  registered_passes[name] = (pass, desc)
}

///|
/// `Pass.lookup name`: the registered pass (by its qualified name).
pub fn lookup_pass(name : String) -> Pass raise {
  match registered_passes.get(@knowledge.Name::read(name).show()) {
    Some((pass, _)) => pass
    None => fail("Unknown core theory pass \{name}")
  }
}

///|
/// `Pass.apply names ct`: applies the named passes to `core` (the first
/// pass of the list is applied first).
pub fn apply_passes(names : Array[String], core : Core) -> Core raise {
  let mut result = core
  for name in names {
    result = lookup_pass(name)(result)
  }
  result
}

///|
/// The variables bound by `let_` in the scope of the desugared term
/// (`desugar-scope-vars`), with their binding multiplicity.
let desugar_scope_vars : @knowledge.Var[Map[String, Int]] = @knowledge.Var::new(
  "desugar-scope-vars",
  _ => {},
  pkg="core",
)

///|
fn desugar_scope_mem(state : @knowledge.State, v : Var) -> Bool raise {
  desugar_scope_vars.get(state).contains(v.ident())
}

///|
fn desugar_scope_push(state : @knowledge.State, v : Var) -> Unit raise {
  desugar_scope_vars.update(state, vars => {
    let vars = vars.copy()
    vars[v.ident()] = vars.get_or_default(v.ident(), 0) + 1
    vars
  })
}

///|
fn desugar_scope_pop(state : @knowledge.State, v : Var) -> Unit raise {
  desugar_scope_vars.update(state, vars => {
    let vars = vars.copy()
    match vars.get(v.ident()) {
      None | Some(1) => vars.remove(v.ident())
      Some(n) => vars[v.ident()] = n - 1
    }
    vars
  })
}

///|
/// The target of the current program (`KB.Object.scoped Program.cls
/// Label.target`).
fn desugar_target(state : @knowledge.State) -> Target raise {
  state.scoped(Label::cls(), obj => state.collect(Label::target_slot(), obj))
}

///|
/// `Pass.Desugar(CT)`: the variable desugarer.
///
/// De-aliases registers according to the aliasing specification of the
/// target of the current program: accesses to and assignments of
/// registers that are aliases of (parts of) other registers are
/// translated into accesses to the base registers; assignments to
/// constant registers become no-ops and reads of the zero/one registers
/// become constants. Variables bound by `let_` are never desugared.
///
/// This pass is applied by `require` to every theory created by
/// `instance`. Deviation: bits of super-registers and bit sets are
/// extracted with the correct (inclusive) bounds; upstream starts from
/// one bit past the most significant bit.
pub fn Core::desugar(self : Core) -> Core {
  let ct = self
  let pass : Eff = _ => Effect::empty(EffectSort::bot())
  let pos : (Int) -> Pure = x => {
    state => ct.int(Sort::bitv(32), bitvec_of_int(32, x))(state)
  }
  let take : ((Sort, Pure) -> Pure, Int, Var) -> Pure = (what, bits, x) => {
    what(Sort::bitv(bits), ct.var_(x))
  }
  let assign_sub : (Var, Pure, Int) -> Eff = (dst, src, off) => {
    state => {
      let src = src(state)
      let s = dst.sort()
      let dst_len = sort_size(s)
      let src_len = sort_size(src.sort())
      let ulen = dst_len - src_len - off
      let high : (Sort, Pure) -> Pure = (s, x) => ct.high(s, x)
      let low : (Sort, Pure) -> Pure = (s, x) => ct.low(s, x)
      let value = match (ulen, off) {
        (0, 0) => pure_const(src)
        (_, 0) => ct.append(s, take(high, ulen, dst), pure_const(src))
        (0, _) => ct.append(s, pure_const(src), take(low, off, dst))
        _ =>
          ct.concat(s, [
            take(high, ulen, dst),
            pure_const(src),
            take(low, off, dst),
          ])
      }
      ct.set(dst, value)(state)
    }
  }
  let assign_multi : (Array[Var], Pure, (Pure) -> Pure) -> Eff = (
    lhs,
    rhs,
    cast,
  ) => {
    state => {
      let rhs = rhs(state)
      let mut data = pass
      let mut hi = sort_size(rhs.sort()) - 1
      for v in lhs {
        let bits = sort_size(v.sort())
        let lo = hi - bits + 1
        let part = cast(
          ct.extract(Sort::bitv(bits), pos(hi), pos(lo), pure_const(rhs)),
        )
        data = ct.seq(data, ct.set(v, part))
        hi = lo - 1
      }
      data(state)
    }
  }
  let set : (Var, Pure) -> Eff = (v, x) => {
    state => {
      if desugar_scope_mem(state, v) {
        return ct.set(v, x)(state)
      }
      let t = desugar_target(state)
      if t.has_roles([Role::constant()], v) {
        return pass(state)
      }
      let eff = match t.unalias(v) {
        None => ct.set(v, x)
        Some(origin) =>
          match origin.cast_sub() {
            Some(sub) =>
              match sub.reg() {
                Some(reg) if sub.is_alias() => ct.set(reg, x)
                Some(reg) => assign_sub(reg, x, sub.lo().unwrap_or(0))
                None => pass
              }
            None =>
              match origin.cast_sup() {
                Some(sup) => assign_multi(sup.regs(), x, part => part)
                None =>
                  match origin.cast_set() {
                    Some(set) =>
                      assign_multi(set.bits(), x, part => {
                        ct.ite(ct.is_zero(part), ct.b0(), ct.b1())
                      })
                    None => pass
                  }
              }
          }
      }
      eff(state)
    }
  }
  let var_ : (Var) -> Pure = r => {
    state => {
      if desugar_scope_mem(state, r) {
        return ct.var_(r)(state)
      }
      let t = desugar_target(state)
      let s = r.sort()
      let ret : (Pure) -> Pure = x => state => x(state).refine(s)
      let constant : (Role, Int) -> Pure? = (role, value) => {
        if t.has_roles([role], r) {
          match s.refine_bitv() {
            None => Some(ct.unk(s))
            Some(bits) =>
              Some(
                ret(state => {
                  ct.int(bits, bitvec_of_int(sort_size(bits), value))(state)
                }),
              )
          }
        } else {
          None
        }
      }
      let term = match constant(Role::zero(), 0) {
        Some(term) => term
        None =>
          match constant(Role::one(), 1) {
            Some(term) => term
            None =>
              match t.unalias(r) {
                None => ct.var_(r)
                Some(origin) =>
                  match origin.cast_sub() {
                    Some(sub) =>
                      match sub.reg() {
                        Some(reg) if sub.is_alias() => ct.var_(reg.resort(s))
                        Some(reg) => {
                          let hi = sub.hi().unwrap_or(0)
                          let lo = sub.lo().unwrap_or(0)
                          ret(
                            ct.extract(
                              Sort::bitv(hi - lo + 1),
                              pos(hi),
                              pos(lo),
                              ct.var_(reg),
                            ),
                          )
                        }
                        None => ct.unk(s)
                      }
                    None =>
                      match origin.cast_sup() {
                        Some(sup) => {
                          let regs = sup.regs()
                          let total = regs.fold(init=0, (sum, reg) => {
                            sum + sort_size(reg.sort())
                          })
                          ret(ct.concat(Sort::bitv(total), regs.map(ct.var_)))
                        }
                        None =>
                          match origin.cast_set() {
                            Some(set) => {
                              let bits = set.bits()
                              let us = Sort::bitv(1)
                              let m0 : Pure = state => {
                                ct.int(us, bitvec_of_int(1, 0))(state)
                              }
                              let m1 : Pure = state => {
                                ct.int(us, bitvec_of_int(1, 1))(state)
                              }
                              ret(
                                ct.concat(
                                  Sort::bitv(bits.length()),
                                  bits.map(v => ct.ite(ct.var_(v), m1, m0)),
                                ),
                              )
                            }
                            None => ct.unk(s)
                          }
                      }
                  }
              }
          }
      }
      term(state)
    }
  }
  let let_ : (Var, Pure, Pure) -> Pure = (v, x, y) => {
    state => {
      let x = x(state)
      desugar_scope_push(state, v)
      let y = y(state)
      desugar_scope_pop(state, v)
      ct.let_(v, pure_const(x), pure_const(y))(state)
    }
  }
  { ..ct, set, var_, let_, }
}

///|
fn register_builtin_passes() -> Unit {
  register_pass(
    "desugar-variables",
    core => core.desugar(),
    pkg="core",
    desc="desugars assignments and access to register aliases",
  ) catch {
    _ => ()
  }
}

///|
fn init {
  register_builtin_passes()
}
