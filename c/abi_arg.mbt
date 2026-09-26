// Port of the `C.Abi.Arg` eDSL from `bap_c_abi.ml`: a choice monad (a
// state monad over an option) for specifying the semantics of argument
// passing. A rejected computation backtracks: all side effects of the
// rejected branch (consumed registers, stack slots, passed arguments) are
// discarded.

///|
priv enum Where {
  Return
  Inputs
  Hidden
}

///|
priv struct StackInfo {
  datum : Data
  ctype : CType
}

///|
/// The stack of memory arguments (upstream `Arg.Stack`). `data` is sorted
/// by the (byte) offset and holds `(offset, info, bits)`; skipped slots
/// have no info.
priv struct ArgStack {
  base : @types.Var
  data : Array[(Int, StackInfo?, Int)]
  min_alignment : Int
  ruler : &Ruler
}

///|
fn bytes_of_bits(bits : Int) -> Int {
  (bits - 1) / 8 + 1
}

///|
fn ArgStack::create(ruler : &Ruler, target : @core_theory.Target) -> ArgStack? {
  let min_alignment = @cmp.maximum(
    target.data_alignment() / 8,
    target.data_addr_size() / 8,
  )
  match stack_pointer(target) {
    None => None
    Some(sp) => Some({ base: reify_var(sp), data: [], min_alignment, ruler, })
  }
}

///|
fn ArgStack::align(self : ArgStack, info : StackInfo?, offset : Int) -> Int {
  match info {
    None => next_multitude_of(n=self.min_alignment, offset)
    Some({ ctype, .. }) => {
      let m = self.ruler.alignment(ctype).in_bytes()
      next_multitude_of(n=@cmp.maximum(self.min_alignment, m), offset)
    }
  }
}

///|
fn ArgStack::append(self : ArgStack, info : StackInfo?, size : Int) -> ArgStack {
  let data = self.data.copy()
  match self.data.last() {
    None => data.push((0, info, size))
    Some((k, _, s)) =>
      data.push((self.align(info, k + bytes_of_bits(s)), info, size))
  }
  { ..self, data, }
}

///|
fn ArgStack::add(
  self : ArgStack,
  ctype : CType,
  datum : Data,
  size : Int,
) -> ArgStack {
  self.append(Some({ ctype, datum, }), size)
}

///|
fn ArgStack::skip(self : ArgStack, size : Int) -> ArgStack {
  self.append(None, size)
}

///|
fn ArgStack::push(
  self : ArgStack,
  ctype : CType,
  datum : Data,
  size : Int,
) -> ArgStack {
  let init : ArgStack = { ..self, data: [(0, Some({ ctype, datum, }), size)], }
  self.data.fold(init~, (stack, entry) => stack.append(entry.1, entry.2))
}

///|
fn ArgStack::is_empty(self : ArgStack) -> Bool {
  self.data.is_empty()
}

///|
fn ArgStack::slots(self : ArgStack) -> Array[(Int, Data, Int)] {
  self.data.filter_map(entry => {
    match entry {
      (off, Some({ datum, .. }), bits) => Some((off, datum, bits))
      (_, None, _) => None
    }
  })
}

///|
/// An ordered collection of locations (upstream `Arg.File`); `args` is
/// sorted by the location number.
priv struct File {
  args : Array[(Int, @types.Exp)]
  bits : Int
}

///|
fn File::of_exps(xs : Array[@types.Exp]) -> File {
  let bits = match xs {
    [] => -1
    [x, ..] =>
      match x.infer_type() {
        Ok(Imm(n)) => n
        _ => -1
      }
  }
  { args: xs.mapi((i, x) => (i, x)), bits, }
}

///|
fn File::pop(self : File) -> (File, @types.Exp)? {
  match self.args {
    [] => None
    [(_, x), .. rest] => Some(({ ..self, args: rest.to_owned(), }, x))
  }
}

///|
fn File::popn(self : File, n : Int) -> (File, Array[@types.Exp])? {
  guard self.args is [(k, _), ..] else { return None }
  let last = k + n - 1
  guard self.args.search_by(entry => entry.0 == last) is Some(i) else {
    return None
  }
  let taken = self.args[:i + 1].map(entry => entry.1)
  Some(({ ..self, args: self.args[i + 1:].to_owned(), }, taken))
}

///|
fn File::align(self : File, n : Int) -> File? {
  guard self.args is [(k, _), ..] else { return None }
  let k1 = next_multitude_of(n~, k)
  if k == k1 {
    return Some(self)
  }
  guard self.args.search_by(entry => entry.0 == k1) is Some(i) else {
    return None
  }
  // upstream rejects the alignment if nothing follows the aligned location
  if i + 1 >= self.args.length() {
    return None
  }
  Some({ ..self, args: self.args[i:].to_owned(), })
}

///|
fn File::deplet(self : File) -> File {
  { ..self, args: [], }
}

///|
fn File::available(self : File) -> Int {
  self.args.length()
}

///|
/// The state of the argument-passing computation.
priv struct ArgState {
  files : Array[File]
  stack : ArgStack?
  ruler : &Ruler
  where_ : Where
  return_ : Param?
  inputs : Array[Param]
  hidden : Array[(CType, Param)]
  target : @core_theory.Target
}

///|
/// A computation in the argument-passing eDSL (upstream `C.Abi.Arg.t`).
///
/// It is a state monad over an option: `reject()` aborts the computation
/// up to the nearest choice point (`either`, `choice`).
pub struct Arg[A] {
  priv run : (ArgState) -> (A, ArgState)?
}

///|
/// An arena: an ordered, expendable collection of locations (usually
/// registers) used to pass arguments (upstream `C.Abi.Arg.arena`).
pub struct Arena {
  priv id : Int
} derive(Eq, Debug)

///|
fn[A] make(run : (ArgState) -> (A, ArgState)?) -> Arg[A] {
  { run, }
}

///|
fn get_state() -> Arg[ArgState] {
  make(s => Some((s, s)))
}

///|
fn update_state(f : (ArgState) -> ArgState) -> Arg[Unit] {
  make(s => Some(((), f(s))))
}

///|
/// A computation that returns `x` (upstream `return`).
pub fn[A] Arg::pure(x : A) -> Arg[A] {
  make(s => Some((x, s)))
}

///|
/// A rejected computation.
pub fn[A] Arg::reject() -> Arg[A] {
  make(_ => None)
}

///|
/// Monadic bind: runs `self` and continues with `f`.
pub fn[A, B] Arg::bind(self : Arg[A], f : (A) -> Arg[B]) -> Arg[B] {
  make(s => {
    match (self.run)(s) {
      None => None
      Some((x, s)) => (f(x).run)(s)
    }
  })
}

///|
pub fn[A, B] Arg::map(self : Arg[A], f : (A) -> B) -> Arg[B] {
  make(s => {
    match (self.run)(s) {
      None => None
      Some((x, s)) => Some((f(x), s))
    }
  })
}

///|
/// Runs `self`, discards its result, and continues with `next`.
pub fn[A, B] Arg::then(self : Arg[A], next : Arg[B]) -> Arg[B] {
  self.bind(_ => next)
}

///|
/// Runs the computations in order and collects their results.
pub fn[A] Arg::all(xs : Array[Arg[A]]) -> Arg[Array[A]] {
  make(s => {
    let results = []
    let mut s = s
    for x in xs {
      match (x.run)(s) {
        None => return None
        Some((r, s1)) => {
          results.push(r)
          s = s1
        }
      }
    }
    Some((results, s))
  })
}

///|
/// Runs the computations in order (upstream `Arg.sequence`).
pub fn Arg::sequence(xs : Array[Arg[Unit]]) -> Arg[Unit] {
  Arg::all(xs).map(_ => ())
}

///|
/// `iter(xs, f)` runs `f(x)` for every element in order (upstream
/// `Arg.List.iter`).
pub fn[T] Arg::iter(xs : Array[T], f : (T) -> Arg[Unit]) -> Arg[Unit] {
  make(s => {
    let mut s = s
    for x in xs {
      match (f(x).run)(s) {
        None => return None
        Some((_, s1)) => s = s1
      }
    }
    Some(((), s))
  })
}

///|
/// `require(cnd)` rejects the computation if `cnd` doesn't hold.
pub fn Arg::require(cnd : Bool) -> Arg[Unit] {
  if cnd {
    Arg::pure(())
  } else {
    Arg::reject()
  }
}

///|
/// `either(option1, option2)` tries `option1` and, if it is rejected,
/// `option2` (with the state as it was before `option1`).
pub fn[A] Arg::either(option1 : Arg[A], option2 : Arg[A]) -> Arg[A] {
  make(s => {
    match (option1.run)(s) {
      None => (option2.run)(s)
      r => r
    }
  })
}

///|
/// `choice(options)` tries the options in order until the first one that
/// is not rejected. An empty list is rejected.
pub fn[A] Arg::choice(options : Array[Arg[A]]) -> Arg[A] {
  match options {
    [] => Arg::reject()
    [first, .. rest] => rest.fold(init=first, Arg::either)
  }
}

///|
fn switch_to(where_ : Where) -> Arg[Unit] {
  update_state(s => { ..s, where_, })
}

///|
/// The toplevel function for defining the argument-passing semantics
/// (upstream `Arg.define`): the `return_` rule (if any) is evaluated first,
/// then the `inputs` rule. If `return_` is rejected, the whole semantics
/// is rejected.
pub fn Arg::define_semantics(
  return_? : Arg[Unit] = Arg::pure(()),
  inputs : Arg[Unit],
) -> Arg[Unit] {
  Arg::sequence([switch_to(Return), return_, switch_to(Inputs), inputs])
}

///|
/// `size(t)` is the size in bits of an object of type `t`; rejected if the
/// type is incomplete.
pub fn Arg::size(t : CType) -> Arg[Int] {
  get_state().bind(s => {
    match s.ruler.bits(t) {
      None => Arg::reject()
      Some(x) => Arg::pure(x)
    }
  })
}

///|
/// `alignment(t)` is the alignment in bits of the type `t`.
pub fn Arg::alignment(t : CType) -> Arg[Int] {
  get_state().map(s => s.ruler.alignment(t).in_bits())
}

///|
fn push_arg(t : CType, exp : @types.Exp) -> Arg[Unit] {
  update_state(s => {
    match s.where_ {
      Return => { ..s, return_: Some((data(s.ruler, t), exp)), }
      Hidden => { ..s, hidden: s.hidden + [(t, (data(s.ruler, t), exp))], }
      Inputs => { ..s, inputs: s.inputs + [(data(s.ruler, t), exp)], }
    }
  })
}

///|
fn[R] update_file(arena : Arena, f : (File) -> (File, R)?) -> Arg[R] {
  make(s => {
    guard s.files.get(arena.id) is Some(file) else { return None }
    match f(file) {
      None => None
      Some((file, r)) => {
        let files = s.files.copy()
        files[arena.id] = file
        Some((r, { ..s, files, }))
      }
    }
  })
}

///|
fn get_file(arena : Arena) -> Arg[File] {
  get_state().bind(s => {
    match s.files.get(arena.id) {
      None => Arg::reject()
      Some(file) => Arg::pure(file)
    }
  })
}

///|
fn add_file(file : File) -> Arg[Arena] {
  make(s => {
    let files = s.files + [file]
    Some(({ id: files.length() - 1, }, { ..s, files, }))
  })
}

///|
/// Creates an arena from the ordered list of registers.
pub fn Arena::create(regs : Array[@core_theory.Var]) -> Arg[Arena] {
  Arena::of_exps(regs.map(r => @types.Exp::var_exp(reify_var(r))))
}

///|
/// Creates an arena from the ordered list of expressions, which must have
/// the same type.
pub fn Arena::of_exps(xs : Array[@types.Exp]) -> Arg[Arena] {
  add_file(File::of_exps(xs))
}

///|
/// Creates an arena from the registers of the target that have all the
/// specified roles, in the alphabetic order (aliases are excluded).
pub fn Arena::of_roles(
  roles : Array[@core_theory.Role],
  target : @core_theory.Target,
) -> Arg[Arena] {
  let regs = target.regs(roles~).filter(v => target.unalias(v) is None)
  regs.sort_by((x, y) => x.compare(y))
  Arena::create(regs)
}

///|
/// The integer argument arena (`[function_argument; integer]`).
pub fn Arena::iargs(target : @core_theory.Target) -> Arg[Arena] {
  Arena::of_roles(
    [@core_theory.Role::function_argument(), @core_theory.Role::integer()],
    target,
  )
}

///|
/// The integer return values arena (`[function_return; integer]`).
pub fn Arena::irets(target : @core_theory.Target) -> Arg[Arena] {
  Arena::of_roles(
    [@core_theory.Role::function_return(), @core_theory.Role::integer()],
    target,
  )
}

///|
/// The floating-point argument arena (`[function_argument; floating]`).
pub fn Arena::fargs(target : @core_theory.Target) -> Arg[Arena] {
  Arena::of_roles(
    [@core_theory.Role::function_argument(), @core_theory.Role::floating()],
    target,
  )
}

///|
/// The floating-point return values arena (`[function_return; floating]`).
pub fn Arena::frets(target : @core_theory.Target) -> Arg[Arena] {
  Arena::of_roles(
    [@core_theory.Role::function_return(), @core_theory.Role::floating()],
    target,
  )
}

///|
fn concat_exps(rev : Bool, xs : Array[@types.Exp]) -> @types.Exp {
  let xs = if rev { xs.rev() } else { xs }
  let mut result = xs[0]
  for i in 1..<xs.length() {
    result = @types.Exp::concat(result, xs[i])
  }
  result
}

///|
/// `register(arena, t)` passes the argument of type `t` via the next
/// available register in `arena`. Rejected if no registers are available,
/// if `t` doesn't fit into a register, or if the size of `t` is unknown.
pub fn Arg::register(arena : Arena, t : CType) -> Arg[Unit] {
  Arg::size(t).bind(bits => {
    get_file(arena).bind(file => {
      Arg::require(file.bits >= bits)
      .then(update_file(arena, File::pop))
      .bind(arg => push_arg(t, arg))
    })
  })
}

///|
/// `discard(arena, n?)` discards `n` (default 1) locations from `arena`.
pub fn Arg::discard(n? : Int = 1, arena : Arena) -> Arg[Unit] {
  update_file(arena, file => file.popn(n)).map(_ => ())
}

///|
fn registers_for_bits(arena : Arena, bits : Int) -> Arg[Int?] {
  get_file(arena).map(file => {
    if file.bits > 0 {
      Some((bits - 1) / file.bits + 1)
    } else {
      None
    }
  })
}

///|
/// `count(arena, t)` is the number of registers needed to pass a value of
/// type `t`; `None` if the size of `t` is unknown or the arena is empty.
pub fn Arg::count(arena : Arena, t : CType) -> Arg[Int?] {
  get_state().bind(s => {
    match s.ruler.bits(t) {
      None => Arg::pure(None)
      Some(bits) => registers_for_bits(arena, bits)
    }
  })
}

///|
fn registers_needed(arena : Arena, bits : Int) -> Arg[Int] {
  registers_for_bits(arena, bits).bind(n => {
    match n {
      None => Arg::reject()
      Some(n) => Arg::pure(n)
    }
  })
}

///|
/// `registers(arena, t)` passes the argument in consecutive registers from
/// `arena`. Rejected if there are not enough registers, if more than
/// `limit` registers are needed, or if the size of `t` is unknown. If
/// `rev` is true, the registers are concatenated in the reversed order.
pub fn Arg::registers(
  rev? : Bool = false,
  limit? : Int,
  arena : Arena,
  t : CType,
) -> Arg[Unit] {
  Arg::size(t).bind(bits => {
    registers_needed(arena, bits).bind(needed => {
      let limit = limit.unwrap_or(needed)
      Arg::require(needed <= limit)
      .then(update_file(arena, file => file.popn(needed)))
      .bind(args => push_arg(t, concat_exps(rev, args)))
    })
  })
}

///|
/// `align_even(arena)` ensures that the next available register in `arena`
/// has an even number. Rejected if there are no more even registers.
pub fn Arg::align_even(arena : Arena) -> Arg[Unit] {
  update_file(arena, file => {
    match file.align(2) {
      None => None
      Some(file) => Some((file, ()))
    }
  })
}

///|
/// `deplet(arena)` unconditionally consumes all registers in the arena.
pub fn Arg::deplet(arena : Arena) -> Arg[Unit] {
  update_file(arena, file => Some((file.deplet(), ())))
}

///|
fn with_hidden(f : () -> Arg[Unit]) -> Arg[Unit] {
  get_state().bind(s => {
    let was = s.where_
    switch_to(Hidden).then(f()).then(switch_to(was))
  })
}

///|
/// `reference(arena, t)` passes a hidden pointer to `t` via the next
/// available register in `arena`. The size of `t` is not required.
pub fn Arg::reference(arena : Arena, t : CType) -> Arg[Unit] {
  with_hidden(() => Arg::register(arena, CType::pointer(t)))
}

///|
/// `pointer(arena, t)` passes the argument `t` as a pointer.
pub fn Arg::pointer(arena : Arena, t : CType) -> Arg[Unit] {
  Arg::register(arena, CType::pointer(t))
}

///|
fn update_stack(f : (ArgStack) -> ArgStack) -> Arg[Unit] {
  make(s => {
    match s.stack {
      None => None
      Some(stack) => Some(((), { ..s, stack: Some(f(stack)), }))
    }
  })
}

///|
/// `push(t)` pushes the argument of type `t` to the beginning of the
/// stack, so that the last pushed argument has the minimal address (the
/// left-to-right, aka Pascal, order). Rejected if the size is unknown.
pub fn Arg::push(t : CType) -> Arg[Unit] {
  get_state().bind(s => {
    Arg::size(t).bind(bits => {
      update_stack(stack => stack.push(t, data(s.ruler, t), bits))
    })
  })
}

///|
/// `memory(t)` passes the argument of type `t` in the next available stack
/// slot, aligned according to `t` (but no less than the minimal data
/// alignment of the target). Rejected if the size of `t` is unknown or the
/// target has no stack pointer.
pub fn Arg::memory(t : CType) -> Arg[Unit] {
  get_state().bind(s => {
    Arg::size(t).bind(bits => {
      update_stack(stack => stack.add(t, data(s.ruler, t), bits))
    })
  })
}

///|
/// `hidden(t)` inserts a hidden pointer to `t` into the next available
/// stack slot.
pub fn Arg::hidden(t : CType) -> Arg[Unit] {
  with_hidden(() => Arg::memory(CType::pointer(t)))
}

///|
fn skip_memory(bits : Int) -> Arg[Unit] {
  update_stack(stack => stack.skip(bits))
}

///|
/// `rebase(n)` rebases the stack position by `n` words.
pub fn Arg::rebase(slots : Int) -> Arg[Unit] {
  get_state().bind(s => skip_memory(slots * s.target.data_addr_size()))
}

///|
fn load_slot(
  target : @core_theory.Target,
  bits : Int,
  sp : @types.Var,
  base : Int,
) -> @types.Exp {
  let mem = @types.Exp::var_exp(reify_var(target.data()))
  let width = target.data_addr_size()
  let addr = (off : Int) => {
    if off == 0 {
      @types.Exp::var_exp(sp)
    } else {
      @types.Exp::binop(Plus, @types.Exp::var_exp(sp), word_exp(width, off))
    }
  }
  let endian = bil_endian(target.endianness())
  match @types.Size::of_int_opt(bits) {
    Some(r) => @types.Exp::load(mem~, addr=addr(base), endian, r)
    None => {
      let bytes = []
      let mut loaded = 0
      let mut off = base
      while loaded < bits {
        bytes.push(@types.Exp::load(mem~, addr=addr(off), endian, R8))
        loaded += 8
        off += 1
      }
      // upstream conses the bytes, so for little endian the byte with the
      // highest address comes first (it is the most significant)
      let bytes = match endian {
        LittleEndian => bytes.rev()
        BigEndian => bytes
      }
      @types.Exp::cast(Low, bits, concat_exps(false, bytes))
    }
  }
}

///|
/// `split_with_memory(arena, t)` passes the low-order part of the value in
/// the available registers (at most `limit`) and the rest in memory. If
/// the whole value fits in the available registers, only registers are
/// used. Rejected if the size of `t` is unknown, if `arena` is empty, or if
/// some other argument is already passed via memory.
pub fn Arg::split_with_memory(
  rev? : Bool = false,
  limit? : Int,
  arena : Arena,
  t : CType,
) -> Arg[Unit] {
  get_state().bind(s => {
    Arg::size(t).bind(bits => {
      registers_needed(arena, bits).bind(needed => {
        get_file(arena).bind(regs => {
          let limit = limit.unwrap_or(regs.available())
          let available = @cmp.minimum(limit, regs.available())
          if available >= needed {
            update_file(arena, file => file.popn(needed)).bind(args => {
              push_arg(t, concat_exps(rev, args))
            })
          } else {
            guard s.stack is Some(stack) else { return Arg::reject() }
            let mbits = bits - available * regs.bits
            Arg::require(stack.is_empty() && available > 0)
            .then(update_file(arena, file => file.popn(available)))
            .bind(args => {
              skip_memory(mbits).then(
                push_arg(
                  t,
                  concat_exps(
                    rev,
                    args + [load_slot(s.target, mbits, stack.base, 0)],
                  ),
                ),
              )
            })
          }
        })
      })
    })
  })
}

///|
fn popn_bits(arena : Arena, bits : Int) -> Arg[Array[@types.Exp]] {
  registers_needed(arena, bits).bind(n => {
    update_file(arena, file => file.popn(n))
  })
}

///|
/// `split(a1, a2, t)` passes the lower half of the value via the registers
/// of `a1` and the higher half via the registers of `a2`. Rejected if
/// either arena doesn't have enough registers, or if the size of `t` is
/// odd or unknown.
pub fn Arg::split(a1 : Arena, a2 : Arena, t : CType) -> Arg[Unit] {
  Arg::size(t).bind(bits => {
    popn_bits(a1, bits / 2).bind(regs1 => {
      popn_bits(a2, bits / 2).bind(regs2 => {
        Arg::require(bits % 2 == 0).then(
          push_arg(t, concat_exps(false, regs1 + regs2)),
        )
      })
    })
  })
}

///|
/// `reify(target, ruler, semantics)` compiles the argument-passing
/// specification. Returns `None` if the specification is rejected.
pub fn Arg::reify(
  target : @core_theory.Target,
  ruler : &Ruler,
  semantics : Arg[Unit],
) -> Args? {
  let init : ArgState = {
    stack: ArgStack::create(ruler, target),
    ruler,
    files: [],
    where_: Inputs,
    return_: None,
    inputs: [],
    hidden: [],
    target,
  }
  match (semantics.run)(init) {
    None => None
    Some((_, { stack, return_, inputs, hidden, .. })) => {
      let memory = match stack {
        None => []
        Some(stack) =>
          stack
          .slots()
          .map(slot => {
            let (off, datum, bits) = slot
            (datum, load_slot(target, bits, stack.base, off))
          })
      }
      Some({ return_, params: inputs + memory, hidden, })
    }
  }
}
