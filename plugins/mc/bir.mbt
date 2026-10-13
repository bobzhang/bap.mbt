// The IR of a single instruction (upstream `Blk.from_insn`, which reifies
// the instruction semantics with the BIR theory).

///|
priv struct BlkBuilder {
  tid : @types.Tid
  defs : Array[@types.Term[@types.Def]]
  jmps : Array[@types.Term[@types.Jmp]]
}

///|
fn BlkBuilder::new(tid~ : @types.Tid = @types.Tid::fresh()) -> BlkBuilder {
  { tid, defs: [], jmps: [], }
}

///|
fn BlkBuilder::finish(self : BlkBuilder) -> @types.Term[@types.Blk] {
  @types.Blk::create(defs=self.defs, jmps=self.jmps, tid=self.tid)
}

///|
/// The translation state: the finished blocks and the current one.
priv struct Lifter {
  blks : Array[BlkBuilder]
  mut current : BlkBuilder
}

///|
fn Lifter::start(self : Lifter, blk : BlkBuilder) -> Unit {
  self.blks.push(blk)
  self.current = blk
}

///|
/// The current block, or a fresh one if the current block already has
/// jumps (definitions can not follow jumps).
fn Lifter::open(self : Lifter) -> BlkBuilder {
  if self.current.jmps.is_empty() {
    self.current
  } else {
    let blk = BlkBuilder::new()
    self.start(blk)
    blk
  }
}

///|
fn goto_(tid : @types.Tid, cond? : @types.Exp) -> @types.Term[@types.Jmp] {
  @types.Jmp::create_goto(@types.Label::direct(tid), cond?)
}

///|
fn Lifter::stmts(self : Lifter, bil : ArrayView[@types.Stmt]) -> Unit {
  for stmt in bil {
    self.stmt(stmt)
  }
}

///|
fn Lifter::stmt(self : Lifter, stmt : @types.Stmt) -> Unit {
  match stmt {
    Move(v, e) => self.open().defs.push(@types.Def::create(v, e))
    Jmp(dst) => {
      let blk = self.open()
      blk.jmps.push(@types.Jmp::create_goto(@types.Label::indirect(dst)))
    }
    Special(_) => ()
    CpuExn(n) => {
      let blk = self.open()
      let next = BlkBuilder::new()
      blk.jmps.push(@types.Jmp::create_int(n, next.tid))
      self.start(next)
    }
    If(cond~, yes~, no~) => {
      let head = self.open()
      let after = BlkBuilder::new()
      let yes_blk = BlkBuilder::new()
      let no_blk = BlkBuilder::new()
      head.jmps.push(goto_(yes_blk.tid, cond~))
      head.jmps.push(goto_(if no.is_empty() { after.tid } else { no_blk.tid }))
      self.start(yes_blk)
      self.stmts(yes)
      self.current.jmps.push(goto_(after.tid))
      if !no.is_empty() {
        self.start(no_blk)
        self.stmts(no)
        self.current.jmps.push(goto_(after.tid))
      }
      self.start(after)
    }
    While(cond~, body~) => {
      let head = BlkBuilder::new()
      let body_blk = BlkBuilder::new()
      let after = BlkBuilder::new()
      self.current.jmps.push(goto_(head.tid))
      self.start(head)
      head.jmps.push(goto_(body_blk.tid, cond~))
      head.jmps.push(goto_(after.tid))
      self.start(body_blk)
      self.stmts(body)
      self.current.jmps.push(goto_(head.tid))
      self.start(after)
    }
  }
}

///|
/// Translates the BIL of an instruction to IR blocks; the first block is
/// the entry. Moves become definitions, jumps become `goto` terms, CPU
/// exceptions become interrupts, and conditionals and loops are split
/// into blocks connected with (conditional) jumps.
pub fn blks_of_bil(
  bil : ArrayView[@types.Stmt],
) -> Array[@types.Term[@types.Blk]] {
  let entry = BlkBuilder::new()
  let lifter = { blks: [entry], current: entry, }
  lifter.stmts(bil)
  lifter.blks.map(b => b.finish())
}
