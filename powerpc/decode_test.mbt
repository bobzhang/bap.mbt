// Tests of the native decoder: hand-assembled encodings of every opcode
// supported by the lifter (fields from the Power ISA 3.0 B), common
// compiler-generated code, invalid encodings, byte orders and the decoder
// registered with `@mc`.

///|
fn kind_name(kind : @mc.Kind) -> String {
  match kind {
    ConditionalBranch => "cond"
    UnconditionalBranch => "jump"
    IndirectBranch => "indirect"
    Return => "return"
    Call => "call"
    Barrier => "barrier"
    Terminator => "term"
    MayAffectControlFlow => "flow"
    MayLoad => "load"
    MayStore => "store"
  }
}

///|
/// One line per word: the decoded instruction, its assembly and kinds.
fn listing(a : @powerpc.AddrSize, words : Array[UInt]) -> String {
  words
  .map(word => {
    let hex = word.to_string(radix=16).pad_start(8, '0')
    match @powerpc.decode(word_bytes(word), 0, mode=a) {
      None => "\{hex}  invalid"
      Some(insn) => {
        let kinds = insn.kinds().iter().map(kind_name).collect().join(",")
        let line = "\{hex}  \{show_insn(insn.name(), insn.ops()[:])}  | \{insn.assembly()}"
        if kinds.is_empty() {
          line
        } else {
          "\{line}  | \{kinds}"
        }
      }
    }
  })
  .join("\n")
}

///|
test "compiler-generated code" {
  let words : Array[UInt] = [
    0x9421fff0, // stwu r1, -16(r1)
     0x7c0802a6, // mflr r0
     0x90010014, // stw r0, 20(r1)
     0x93e1000c, // stw r31, 12(r1)
     0x7c3f0b78, // mr r31, r1
     0x3d200000, // lis r9, 0
     0x38000000, // li r0, 0
     0x3929ffff, // addi r9, r9, -1
     0x2f890000, // cmpwi cr7, r9, 0
     0x409e0010, // bne cr7, .+16
     0x419e0008, // beq cr7, .+8
     0x4800000d, // bl .+12
     0x4bfffff0, // b .-16
     0x7d2903a6, // mtctr r9
     0x4e800420, // bctr
     0x7c0803a6, // mtlr r0
     0x83e1fffc, // lwz r31, -4(r1)
     0x4e800020, // blr
     0x5463103a, // rlwinm r3, r3, 2, 0, 29 (slwi r3, r3, 2)
     0x7c630214, // add r3, r3, r0
     0x60000000, // nop
     0x4200fff8, // bdnz .-8
  ]
  inspect(
    listing(R32, words),
    content=(
      #|9421fff0  STWU R1, R1, -16, R1  | stwu 1, -16(1)  | store
      #|7c0802a6  MFLR R0  | mflr 0
      #|90010014  STW R0, 20, R1  | stw 0, 20(1)  | store
      #|93e1000c  STW R31, 12, R1  | stw 31, 12(1)  | store
      #|7c3f0b78  OR R31, R1, R1  | mr 31, 1
      #|3d200000  ADDIS R9, ZERO, 0  | lis 9, 0
      #|38000000  ADDI R0, ZERO, 0  | li 0, 0
      #|3929ffff  ADDI R9, R9, -1  | addi 9, 9, -1
      #|2f890000  CMPWI CR7, R9, 0  | cmpwi 7, 9, 0
      #|409e0010  gBC 4, CR7EQ, 4  | bc 4, 30, .+16  | cond,flow
      #|419e0008  gBC 12, CR7EQ, 2  | bc 12, 30, .+8  | cond,flow
      #|4800000d  BL 3  | bl .+12  | call,flow
      #|4bfffff0  B -4  | b .-16  | jump,barrier,term,flow
      #|7d2903a6  MTCTR R9  | mtctr 9
      #|4e800420  BCTR  | bctr  | indirect,barrier,term,flow
      #|7c0803a6  MTLR R0  | mtlr 0
      #|83e1fffc  LWZ R31, -4, R1  | lwz 31, -4(1)  | load
      #|4e800020  BLR  | blr  | return,barrier,term,flow
      #|5463103a  RLWINM R3, R3, 2, 0, 29  | rlwinm 3, 3, 2, 0, 29
      #|7c630214  ADD4 R3, R3, R0  | add 3, 3, 0
      #|60000000  NOP  | nop
      #|4200fff8  BDNZ -2  | bdnz .-8  | cond,term,flow
    ),
  )
  let words64 : Array[UInt] = [
    0xf821ff91, // stdu r1, -112(r1)
     0xe8010010, // ld r0, 16(r1)
     0xf8010010, // std r0, 16(r1)
     0x78630020, // rldicl r3, r3, 0, 32 (clrldi r3, r3, 32)
     0x7c6307b4, // extsw r3, r3
     0x2fa30000, // cmpdi cr7, r3, 0
     0x7c2a4a14, // add r1, r10, r9
  ]
  inspect(
    listing(R64, words64),
    content=(
      #|f821ff91  STDU R1, X1, -112, R1  | stdu 1, -112(1)  | store
      #|e8010010  LD X0, 16, R1  | ld 0, 16(1)  | load
      #|f8010010  STD X0, 16, R1  | std 0, 16(1)  | store
      #|78630020  RLDICL X3, X3, 0, 32  | rldicl 3, 3, 0, 32
      #|7c6307b4  EXTSW X3, X3  | extsw 3, 3
      #|2fa30000  CMPDI CR7, X3, 0  | cmpdi 7, 3, 0
      #|7c2a4a14  ADD4 R1, R10, R9  | add 1, 10, 9
    ),
  )
}
