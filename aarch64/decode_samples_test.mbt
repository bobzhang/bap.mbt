// Checks the decoder against the LLVM samples of `decode_llvm_test.mbt`.

///|
/// `NAME op op | assembly`, in the format of the LLVM samples.
fn render_insn(insn : @mc.Insn) -> String {
  let ops = insn.ops
    .iter()
    .map(op => {
      match op {
        Reg(name~, ..) => "Reg:" + name
        Imm(v) => "Imm:" + v.to_string()
        Fmm(v) => "Fmm:" + v.to_string()
      }
    })
    .collect()
  if ops.is_empty() {
    "\{insn.name} | \{insn.assembly}"
  } else {
    "\{insn.name} \{ops.join(" ")} | \{insn.assembly}"
  }
}

///|
/// The kinds of an instruction in the order and spelling of the samples.
fn render_kinds(insn : @mc.Insn) -> String {
  let order : Array[(@mc.Kind, String)] = [
    (ConditionalBranch, "cond"),
    (UnconditionalBranch, "uncond"),
    (IndirectBranch, "indirect"),
    (Return, "return"),
    (Call, "call"),
    (Barrier, "barrier"),
    (Terminator, "terminator"),
    (MayAffectControlFlow, "affect_cf"),
    (MayLoad, "may_load"),
    (MayStore, "may_store"),
  ]
  order.filter(k => insn.kinds.contains(k.0)).map(k => k.1).join(",")
}

///|
test "decode: every sample decodes like llvm-mc, with LLVM's kinds" {
  let names : Map[String, Unit] = Map([])
  for sample in llvm_samples {
    let (word, expected, kinds) = sample
    let hex = "0x" + word.to_string(radix=16)
    guard @aarch64.decode_a64_word(word) is Some(insn) else {
      fail("\{hex}: not decoded, expected \{expected}")
    }
    assert_eq(render_insn(insn), expected, msg=hex)
    assert_eq(render_kinds(insn), kinds, msg=hex)
    assert_eq(insn.size, 4)
    names[insn.name] = ()
  }
  // the number of distinct LLVM opcodes covered by the samples
  inspect(names.length(), content="549")
}

///|
test "decode: SIMD/FP and unallocated words are invalid, FlagM is decoded" {
  // valid for LLVM but outside the decoder: SIMD and floating point
  for word in [0x1E622820U, 0x4EA11C20U, 0x3D8003E0U] {
    assert_true(@aarch64.decode_a64_word(word) is None)
  }
  // invalid for LLVM too: SVE (not enabled) and unallocated
  for word in [0x04A00000U, 0x00010000U] {
    assert_true(@aarch64.decode_a64_word(word) is None)
  }
  // FlagM needs +flagm in LLVM (upstream does not enable it), but the Lisp
  // semantics define these, so they are decoded as `llvm-mc -mattr=+flagm`
  // does; without FlagM LLVM reads 0xD500401F as `msr S0_0_C4_C0_0, xzr`
  let flagm = [0xD500401FU, 0x3A00082DU, 0xBA018422U].map(w => {
    match @aarch64.decode_a64_word(w) {
      Some(insn) => render_insn(insn)
      None => "invalid"
    }
  })
  inspect(
    flagm.join("\n"),
    content=(
      #|CFINV | cfinv
      #|SETF8 Reg:W1 | setf8 w1
      #|RMIF Reg:X1 Imm:3 Imm:2 | rmif x1, #3, #2
    ),
  )
}
