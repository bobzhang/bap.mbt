///|
pub fn Term::sub_phis(self : Term[Sub]) -> Array[Term[Phi]] {
  let result = []
  for blk in self.payload_value.blks {
    for phi in blk.phis() {
      result.push(phi)
    }
  }
  result
}

///|
pub fn Term::sub_defs(self : Term[Sub]) -> Array[Term[Def]] {
  let result = []
  for blk in self.payload_value.blks {
    for def in blk.defs() {
      result.push(def)
    }
  }
  result
}

///|
pub fn Term::sub_jmps(self : Term[Sub]) -> Array[Term[Jmp]] {
  let result = []
  for blk in self.payload_value.blks {
    for jmp in blk.jmps() {
      result.push(jmp)
    }
  }
  result
}

///|
pub fn Term::program_args(self : Term[Program]) -> Array[Term[Arg]] {
  let result = []
  for sub in self.payload_value.subs {
    for arg in sub.args() {
      result.push(arg)
    }
  }
  result
}

///|
pub fn Term::program_blks(self : Term[Program]) -> Array[Term[Blk]] {
  let result = []
  for sub in self.payload_value.subs {
    for blk in sub.blks() {
      result.push(blk)
    }
  }
  result
}

///|
pub fn Term::program_phis(self : Term[Program]) -> Array[Term[Phi]] {
  let result = []
  for sub in self.payload_value.subs {
    for phi in sub.sub_phis() {
      result.push(phi)
    }
  }
  result
}

///|
pub fn Term::program_defs(self : Term[Program]) -> Array[Term[Def]] {
  let result = []
  for sub in self.payload_value.subs {
    for def in sub.sub_defs() {
      result.push(def)
    }
  }
  result
}

///|
pub fn Term::program_jmps(self : Term[Program]) -> Array[Term[Jmp]] {
  let result = []
  for sub in self.payload_value.subs {
    for jmp in sub.sub_jmps() {
      result.push(jmp)
    }
  }
  result
}

///|
pub fn Term::find_phi(self : Term[Blk], tid : Tid) -> Term[Phi]? {
  self.payload_value.phis
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.phis[i])
}

///|
pub fn Term::find_jmp(self : Term[Blk], tid : Tid) -> Term[Jmp]? {
  self.payload_value.jmps
  .search_by(term => term.tid() == tid)
  .map(i => self.payload_value.jmps[i])
}

///|
pub fn Term::program_find_blk(self : Term[Program], tid : Tid) -> Term[Blk]? {
  for blk in self.program_blks() {
    if blk.tid() == tid {
      return Some(blk)
    }
  }
  None
}

///|
pub fn Term::program_find_phi(self : Term[Program], tid : Tid) -> Term[Phi]? {
  for phi in self.program_phis() {
    if phi.tid() == tid {
      return Some(phi)
    }
  }
  None
}

///|
pub fn Term::program_find_def(self : Term[Program], tid : Tid) -> Term[Def]? {
  for def in self.program_defs() {
    if def.tid() == tid {
      return Some(def)
    }
  }
  None
}

///|
pub fn Term::program_find_jmp(self : Term[Program], tid : Tid) -> Term[Jmp]? {
  for jmp in self.program_jmps() {
    if jmp.tid() == tid {
      return Some(jmp)
    }
  }
  None
}
