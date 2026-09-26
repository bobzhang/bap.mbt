// Lifting instructions with the Lisp semantics.

///|
fn show_bil(stmts : Array[@types.Stmt]?) -> String {
  match stmts {
    None => "<no definition>"
    Some(ss) => {
      let buf = StringBuilder()
      pp_stmts(buf, "", ss)
      buf.to_string()
    }
  }
}

///|
fn pp_stmts(
  buf : StringBuilder,
  indent : String,
  ss : Array[@types.Stmt],
) -> Unit {
  for s in ss {
    match s {
      If(cond~, yes~, no~) => {
        buf.write_string("\{indent}if (\{cond.to_string()}) {\n")
        pp_stmts(buf, indent + "  ", yes)
        if no.is_empty() {
          buf.write_string("\{indent}}\n")
        } else {
          buf.write_string("\{indent}} else {\n")
          pp_stmts(buf, indent + "  ", no)
          buf.write_string("\{indent}}\n")
        }
      }
      While(cond~, body~) => {
        buf.write_string("\{indent}while (\{cond.to_string()}) {\n")
        pp_stmts(buf, indent + "  ", body)
        buf.write_string("\{indent}}\n")
      }
      s => buf.write_string("\{indent}\{s.to_string()}\n")
    }
  }
}

///|
test "lift riscv instructions" {
  let lifter = @primus_lisp.load_semantics(@core_theory.Target::riscv64(), [
    "semantics/riscv",
  ])
  let lift = (name : String, ops : Array[@primus_lisp.Operand]) => {
    show_bil(
      lifter.lift(
        @knowledge.Name::create(name, pkg="llvm-riscv64"),
        ops,
        pc=@types.Word::of_int(width=64, 0x1000),
      ),
    )
  }
  inspect(
    lift("ADDI", [Reg("X1"), Reg("X2"), Imm(5)]),
    content=(
      #|X1:imm64 := (X2:imm64 + 5:64u)
      #|
    ),
  )
  inspect(
    lift("ADDIW", [Reg("X1"), Reg("X2"), Imm(5)]),
    content=(
      #|X1:imm64 := extend:64[low:32[(X2:imm64 + 5:64u)]]
      #|
    ),
  )
  inspect(
    lift("LD", [Reg("X1"), Reg("X2"), Imm(8)]),
    content=(
      #|X1:imm64 := load(mem:mem64x8, (X2:imm64 + 8:64u)):imm64
      #|
    ),
  )
  inspect(
    lift("SW", [Reg("X1"), Reg("X2"), Imm(8)]),
    content=(
      #|mem:mem64x8 := store(mem:mem64x8, (X2:imm64 + 8:64u), low:32[X1:imm64])
      #|
    ),
  )
  inspect(
    lift("AUIPC", [Reg("X1"), Imm(1)]),
    content=(
      #|X1:imm64 := 0x1001:64u
      #|
    ),
  )
  inspect(
    lift("BEQ", [Reg("X1"), Reg("X2"), Imm(16)]),
    content=(
      #|%#2:imm1 := (X1:imm64 == X2:imm64)
      #|if (%#2:imm1) {
      #|  jmp 0x1010:64u
      #|}
      #|
    ),
  )
  inspect(
    lift("NOSUCHINSN", []),
    content=(
      #|<no definition>
    ),
  )
}
