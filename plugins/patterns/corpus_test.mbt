// A small corpus in the format of the Ghidra byte-search patterns.

///|
let constraints_xml : String =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<!-- The table of contents -->
  #|<patternconstraints>
  #|  <language id="x86:LE:64:default">
  #|    <compiler id="gcc">
  #|      <patternfile>x86-64gcc_patterns.xml</patternfile>
  #|    </compiler>
  #|    <compiler id="windows">
  #|      <patternfile>x86-64win_patterns.xml</patternfile>
  #|    </compiler>
  #|  </language>
  #|  <language id="x86:LE:32:default">
  #|    <patternfile>x86gcc_patterns.xml</patternfile>
  #|  </language>
  #|  <language id="ARM:BE:32:v8">
  #|    <patternfile>ARM_BE_patterns.xml</patternfile>
  #|  </language>
  #|  <language id="x86_64">
  #|    <patternfile>x86-64gcc_patterns_copy.xml</patternfile>
  #|  </language>
  #|</patternconstraints>

///|
let x86_64_gcc_xml : String =
  #|<patternlist>
  #|  <patternpairs totalbits="32" postbits="16">
  #|    <prepatterns>
  #|      <data>0xc3</data>               <!-- RET -->
  #|      <data>0xe9........</data>       <!-- JMP big -->
  #|      <data>0xeb..</data>             <!-- JMP small -->
  #|      <data>0x0f0b</data>             <!-- UD2 -->
  #|    </prepatterns>
  #|    <postpatterns>
  #|      <data>0x554889e5</data>         <!-- PUSH RBP; MOV RBP,RSP -->
  #|      <data>0x4883ec 0x..</data>      <!-- SUB RSP,imm8 -->
  #|      <codeboundary/>
  #|      <possiblefuncstart/>
  #|    </postpatterns>
  #|  </patternpairs>
  #|  <pattern>
  #|    <data>0xf30f1efa</data>           <!-- ENDBR64 -->
  #|    <funcstart after="defined"/>
  #|  </pattern>
  #|</patternlist>

///|
let x86_64_win_xml : String =
  #|<patternlist>
  #|  <pattern>
  #|    <data>0x48895c24 0x08</data>
  #|    <funcstart/>
  #|  </pattern>
  #|</patternlist>

///|
let arm_xml : String =
  #|<patternlist>
  #|  <pattern>
  #|    <data>0xe92d.... 0xe24dd...</data>
  #|    <funcstart/>
  #|    <setcontext name="TMode" value="0"/>
  #|  </pattern>
  #|  <pattern>
  #|    <data>1011010. ........</data>
  #|    <possiblefuncstart/>
  #|    <setcontext name="TMode" value="1"/>
  #|  </pattern>
  #|</patternlist>

///|
fn corpus_fs() -> @bap_main.FileSystem {
  @bap_main.FileSystem::in_memory(
    files=[
      ("/ghidra/x86/patternconstraints.xml", constraints_xml),
      ("/ghidra/x86/x86-64gcc_patterns.xml", x86_64_gcc_xml),
      // the same contents under another name (deduplicated by digest)
      ("/ghidra/x86/x86-64gcc_patterns_copy.xml", x86_64_gcc_xml),
      ("/ghidra/x86/x86-64win_patterns.xml", x86_64_win_xml),
      ("/ghidra/x86/ARM_BE_patterns.xml", arm_xml),
      ("/ghidra/broken/patternconstraints.xml", "<patternconstraints><lang"),
    ],
    dirs=["/ghidra", "/ghidra/x86", "/ghidra/broken"],
  )
}

///|
test "table of contents" {
  debug_inspect(
    @patterns.parse_constraints(constraints_xml),
    content=(
      #|Ok(
      #|  [
      #|    ("x86:LE:64:default:gcc", "x86-64gcc_patterns.xml"),
      #|    ("x86:LE:64:default:windows", "x86-64win_patterns.xml"),
      #|    ("x86:LE:32:default", "x86gcc_patterns.xml"),
      #|    ("ARM:BE:32:v8", "ARM_BE_patterns.xml"),
      #|    ("x86_64", "x86-64gcc_patterns_copy.xml"),
      #|  ],
      #|)
    ),
  )
  let fs = corpus_fs()
  debug_inspect(
    @patterns.find_patternconstraints("/ghidra", fs~),
    content=(
      #|[
      #|  "/ghidra/broken/patternconstraints.xml",
      #|  "/ghidra/x86/patternconstraints.xml",
      #|]
    ),
  )
  debug_inspect(
    @patterns.select(["/ghidra"], @core_theory.Target::x86_64(), fs~),
    content=(
      #|[
      #|  "/ghidra/x86/x86-64gcc_patterns.xml",
      #|  "/ghidra/x86/x86-64win_patterns.xml",
      #|]
    ),
  )
  debug_inspect(
    @patterns.select(["/ghidra"], @core_theory.Target::i386(), fs~),
    content="[]",
  )
  debug_inspect(
    @patterns.select(["/ghidra"], @core_theory.Target::armeb(), fs~),
    content="[]",
  )
}

///|
test "patterns files" {
  let rules = match @patterns.parse_patterns(x86_64_gcc_xml) {
    Ok(rules) => rules
    Err(e) => fail(e)
  }
  inspect(
    rules.map(r => r.to_string()).join("\n--\n"),
    content=(
      #|preps {
      #|  0xc3
      #|  0xe9........
      #|  0xeb..
      #|  0x0f0b
      #|}
      #|posts {
      #|  0x554889e5
      #|  0x4883ec 0x..
      #|}
      #|actions {
      #|  (bap:codeboundary)
      #|  (bap:possiblefuncstart)
      #|}
      #|--
      #|preps {
      #|}
      #|posts {
      #|  0xf30f1efa
      #|}
      #|actions {
      #|  (bap:funcstart :after "defined")
      #|}
    ),
  )
  debug_inspect(rules[0].sizes, content="Some({ total: 32, post: 16 })")
  let compiled = @patterns.Rules::create(rules)
  // 4 x 2 pairs, but `0xc3` + `0x4883ec..` has 8 + 32 = 40 >= 32 total
  // bits, while each pair has at least 16 bits in the postpattern
  inspect(
    compiled.to_string(),
    content=(
      #|0xf30f1efa -> (bap:funcstart :after "defined")
      #|0x0f0b0x4883ec 0x.. -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0x0f0b0x554889e5 -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xeb..0x4883ec 0x.. -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xeb..0x554889e5 -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xe9........0x4883ec 0x.. -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xe9........0x554889e5 -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xc30x4883ec 0x.. -> (bap:codeboundary) (bap:possiblefuncstart)
      #|0xc30x554889e5 -> (bap:codeboundary) (bap:possiblefuncstart)
    ),
  )
  let arm = match @patterns.parse_patterns(arm_xml) {
    Ok(rules) => @patterns.Rules::create(rules)
    Err(e) => fail(e)
  }
  inspect(
    arm.to_string(),
    content=(
      #|1011010. ........ -> (bap:setcontext :name "TMode" :value "1") (bap:possiblefuncstart)
      #|0xe92d.... 0xe24dd... -> (bap:funcstart) (bap:setcontext :name "TMode" :value "0")
    ),
  )
}

///|
test "size constraints filter the pairs" {
  let xml =
    #|<patternlist>
    #|  <patternpairs totalbits="24" postbits="12">
    #|    <prepatterns><data>0x..</data><data>0xc3</data></prepatterns>
    #|    <postpatterns><data>0x55..</data><data>0x5589</data><funcstart/></postpatterns>
    #|  </patternpairs>
    #|</patternlist>
  let rules = @patterns.Rules::create(@patterns.parse_patterns(xml).unwrap())
  inspect(
    rules.to_string(),
    content=(
      #|0xc30x5589 -> (bap:funcstart)
    ),
  )
}

///|
fn memory(start : UInt64, bytes : Bytes) -> @memory.Memory {
  @memory.Memory::from_bytes(endian=LittleEndian, start~, bytes)
}

///|
test "searching memory" {
  let rules = @patterns.load(
    ["/ghidra"],
    @core_theory.Target::x86_64(),
    fs=corpus_fs(),
  )
  let code = memory(
    0x1000, b"\xc3\x55\x48\x89\xe5\x90\xf3\x0f\x1e\xfa\x90\xeb\x10\x48\x83\xec\x20\x90\x48\x89\x5c\x24\x08\x90\x90",
  )
  inspect(
    @patterns.matches(rules, code).join("\n"),
    content=(
      #|matching 0x1001 -> (bap:codeboundary)
      #|matching 0x1001 -> (bap:possiblefuncstart)
      #|matching 0x1006 -> (bap:funcstart :after "defined")
      #|matching 0x100d -> (bap:codeboundary)
      #|matching 0x100d -> (bap:possiblefuncstart)
      #|matching 0x1012 -> (bap:funcstart)
    ),
  )
  let outcome = @patterns.analyze(rules, [code])
  debug_inspect(
    outcome,
    content=(
      #|{ roots: [4097, 4102, 4109, 4114], names: [] }
    ),
  )
  assert_true(outcome.rooter().contains(0x1006))
}

///|
test "the search stops at the end of memory" {
  let xml =
    #|<patternlist>
    #|  <pattern><data>0xaabbccdd</data><funcstart/></pattern>
    #|  <pattern><data>0x90</data><funcstart/></pattern>
    #|  <pattern><data>0x90......</data><possiblefuncstart/></pattern>
    #|</patternlist>
  let rules = @patterns.Rules::create(@patterns.parse_patterns(xml).unwrap())
  // at 0x1 the long pattern runs out of bytes, which stops the search, so
  // the nop at 0x2 is never matched (upstream behavior); the last byte is
  // never tried
  let mem = memory(0, b"\x00\x90\x90\x90")
  inspect(
    @patterns.matches(rules, mem).join("\n"),
    content=(
      #|matching 0x1 -> (bap:funcstart)
    ),
  )
  let mem = memory(0, b"\x90\xaa\xbb\xcc\xdd\x00\x90\x90")
  inspect(
    @patterns.matches(rules, mem).join("\n"),
    content=(
      #|matching 0x0 -> (bap:funcstart)
      #|matching 0x0 -> (bap:possiblefuncstart)
      #|matching 0x1 -> (bap:funcstart)
      #|matching 0x6 -> (bap:funcstart)
    ),
  )
}

///|
test "bit patterns and custom action handlers" {
  let arm = @patterns.Rules::create(@patterns.parse_patterns(arm_xml).unwrap())
  let mem = memory(
    0x100, b"\x00\xb5\x10\xe9\x2d\x48\x00\xe2\x4d\xd0\x08\x00\x00",
  )
  let contexts = []
  let outcome = @patterns.analyze(arm, [mem], handlers=[
    @patterns.default_action_handler,
    (ctxt, action, addr) => {
      if action.name() == @patterns.bap_action("setcontext") {
        contexts.push(
          (addr, action.attribute("name"), action.attribute(":value")),
        )
        ctxt.promise_name(addr, "thumb_\{addr}") |> ignore
      }
    },
  ])
  debug_inspect(
    outcome,
    content=(
      #|{ roots: [257, 259], names: [(257, "thumb_257"), (259, "thumb_259")] }
    ),
  )
  debug_inspect(
    contexts,
    content=(
      #|[(257, Some("TMode"), Some("1")), (259, Some("TMode"), Some("0"))]
    ),
  )
}

///|
test "registering the rooter for an image" {
  @patterns.enable(paths=["/ghidra"])
  assert_true(@patterns.enabled_roots().contains("/ghidra"))
  assert_true(@patterns.enabled_roots().contains("/usr/share/ghidra"))
  let seg = @image.Segment::create(
    name="text",
    endian=LittleEndian,
    addr=0x400000,
    b"\xf3\x0f\x1e\xfa\xc3\x55\x48\x89\xe5\xc3\x00",
    executable=true,
  )
  let data = @image.Segment::create(
    name="data",
    endian=LittleEndian,
    addr=0x600000,
    b"\xf3\x0f\x1e\xfa\x00",
  )
  let image = @image.Image::from_segments(
    entry=0x400000,
    endian=LittleEndian,
    [seg, data],
    target=@core_theory.Target::x86_64(),
  )
  let outcome = @patterns.register_for_image(image, fs=corpus_fs())
  debug_inspect(
    outcome,
    content=(
      #|{ roots: [4194304, 4194309], names: [] }
    ),
  )
  assert_true(@project.find_rooter_source("patterns") is Some(_))
  @patterns.enable()
}
