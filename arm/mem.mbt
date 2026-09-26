// Port of `Arm_mem`: single- and multiple-register memory accesses.

///|
/// `Arm_mem.lift_r`: a single (or dual, for size `D`) register load or
/// store with offset, pre-indexed or post-indexed addressing.
fn mem_lift_r(
  dst1~ : @types.Var,
  dst2? : @types.Var,
  base~ : @types.Var,
  offset~ : @types.Exp,
  mode : ModeR,
  sign : Sign,
  size : MemSize,
  operation : Operation,
) -> Array[@types.Stmt] raise @mc.LiftError {
  let o_base = tmp(@types.ValueType::reg32_t())
  // port: a register offset is read before the load writes its
  // destination (which may be the offset register), and the address of a
  // dual load before its first destination (which may be the base) is
  // written
  let loaded = (x : @types.Var) => x == dst1 || (dst2 is Some(d) && x == d)
  let (offset, read_offset) = match offset {
    _ if operation is St || !offset.free_vars().iter().any(loaded) =>
      (offset, [])
    _ => {
      let saved = tmp(@types.ValueType::reg32_t())
      (v(saved), [assign(saved, offset)])
    }
  }
  // A word load into PC is a jump; the write-back must then happen before
  // the load, so the original base is saved in a temporary.
  let pc_load = operation is Ld && size is W && dst1 == pc
  let address = match mode {
    PostIndex if pc_load => v(o_base)
    PreIndex if pc_load => bin(Plus, v(o_base), offset)
    PostIndex => v(base)
    PreIndex | Offset => bin(Plus, v(base), offset)
  }
  let pre_write_back = match mode {
    PreIndex | PostIndex if pc_load =>
      [assign(o_base, v(base)), assign(base, bin(Plus, v(base), offset))]
    _ => []
  }
  let write_back = match mode {
    PreIndex | PostIndex if pc_load => []
    Offset => []
    _ => [assign(base, bin(Plus, v(base), offset))]
  }
  let typ : @types.Size = match size {
    B => R8
    H => R16
    W | D => R32
  }
  let temp = match size {
    B => tmp(@types.ValueType::reg8_t())
    H => tmp(@types.ValueType::reg16_t())
    _ => dst1
  }
  let four = int32(4)
  let m = v(mem)
  match operation {
    Ld => {
      let rhs = cast_of_sign(sign, 32, v(temp))
      let extension = match size {
        B | H => [assign(dst1, rhs)]
        W | D => []
      }
      let loads = if size is D {
        guard dst2 is Some(dst2) else {
          fail("dual load requires a second destination")
        }
        let first = tmp(@types.ValueType::reg32_t())
        [
          assign(first, load(m, address, typ)),
          assign(dst2, load(m, bin(Plus, address, four), typ)),
          assign(dst1, v(first)),
        ]
      } else {
        [assn(temp, load(m, address, typ))]
      }
      [..read_offset, ..pre_write_back, ..loads, ..extension, ..write_back]
    }
    St => {
      let trunc = match size {
        B => [assign(temp, cast(Low, 8, v(dst1)))]
        H => [assign(temp, cast(Low, 16, v(dst1)))]
        W | D => []
      }
      let stores = match size {
        D => {
          guard dst2 is Some(dst2) else {
            fail("dual store requires a second source")
          }
          [
            assign(mem, store(m, address, v(dst1), typ)),
            assign(mem, store(m, bin(Plus, address, four), v(dst2), typ)),
          ]
        }
        B | H | W => [assign(mem, store(m, address, v(temp), typ))]
      }
      [..read_offset, ..trunc, ..stores, ..write_back]
    }
  }
}

///|
/// `Arm_mem.lift_m`: load/store multiple. Any jump produced by a load into
/// `PC` is moved to the end of the sequence.
fn mem_lift_m(
  dest_list : Array[@types.Var],
  base : @types.Var,
  mode : ModeM,
  update : UpdateM,
  operation : Operation,
) -> Array[@types.Stmt] {
  let o_base = tmp(@types.ValueType::reg32_t())
  let calc_offset = (ith : Int) => {
    match mode {
      IB => 4 * (ith + 1)
      DB => -4 * (ith + 1)
      IA => 4 * ith
      DA => -4 * ith
    }
  }
  let writeback = match update {
    NoUpdate => []
    Update => {
      let dest_len = int32((4 * dest_list.length()).reinterpret_as_uint())
      let op : @types.BinOp = match mode {
        IB | IA => Plus
        DB | DA => Minus
      }
      [assign(base, bin(op, v(base), dest_len))]
    }
  }
  let stmts = [assign(o_base, v(base))]
  for i, dest in dest_list {
    let offset_e = int32(calc_offset(i).reinterpret_as_uint())
    let m = v(mem)
    let addr = bin(Plus, v(o_base), offset_e)
    stmts.push(
      match operation {
        Ld => assn(dest, load(m, addr, R32))
        St => assign(mem, store(m, addr, v(dest), R32))
      },
    )
  }
  stmts.append(writeback)
  move_jump_to_end(stmts)
}

///|
/// Move the first jump of `stmts` to the end.
fn move_jump_to_end(stmts : Array[@types.Stmt]) -> Array[@types.Stmt] {
  match stmts.search_by(s => s is Jmp(_)) {
    None => stmts
    Some(i) => {
      let jmp = stmts[i]
      let result = stmts.copy()
      result.remove(i) |> ignore
      result.push(jmp)
      result
    }
  }
}
