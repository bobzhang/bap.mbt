// Instruction word fields of the MIPS32/MIPS64 encodings.

///|
/// The fields of a 32-bit MIPS instruction word.
priv struct Fields {
  opcode : Int32
  rs : Int32
  rt : Int32
  rd : Int32
  sa : Int32
  funct : Int32
  /// the low 16 bits, unsigned
  imm16 : Int32
  word : UInt32
}

///|
fn bits(word : UInt32, lo : Int32, count : Int32) -> Int32 {
  ((word >> lo) & ((1U << count) - 1U)).reinterpret_as_int()
}

///|
fn fields(word : UInt32) -> Fields {
  {
    opcode: bits(word, 26, 6),
    rs: bits(word, 21, 5),
    rt: bits(word, 16, 5),
    rd: bits(word, 11, 5),
    sa: bits(word, 6, 5),
    funct: bits(word, 0, 6),
    imm16: bits(word, 0, 16),
    word,
  }
}

///|
/// Sign-extend the low `width` bits of `value`.
fn sext(value : Int32, width : Int32) -> Int64 {
  let v = value.to_int64() & ((1L << width) - 1L)
  if v >> (width - 1) != 0L {
    v - (1L << width)
  } else {
    v
  }
}

///|
/// The signed 16-bit immediate.
fn Fields::simm16(self : Fields) -> Int64 {
  sext(self.imm16, 16)
}

///|
/// The unsigned 16-bit immediate.
fn Fields::uimm16(self : Fields) -> Int64 {
  self.imm16.to_int64()
}

///|
/// The branch target operand of LLVM's `DecodeBranchTarget` (and its 21-
/// and 26-bit variants): the sign-extended word offset scaled by four, plus
/// four, i.e. the target relative to the address of the branch.
fn branch_target(offset : Int32, width : Int32) -> Int64 {
  sext(offset, width) * 4L + 4L
}
