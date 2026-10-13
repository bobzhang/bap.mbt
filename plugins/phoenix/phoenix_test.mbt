///|
fn block(
  start : UInt64,
  insns : Array[
    (Bytes, String, String, Array[@project.ProjectInstructionOperand]),
  ],
) -> @project.ProjectDisassemblyBlock {
  let all = []
  let mut addr = start
  let parts = []
  for insn in insns {
    let mem = @memory.Memory::from_bytes(
      endian=LittleEndian,
      start=addr,
      insn.0,
    )
    parts.push(
      @project.ProjectDisassemblyInstruction::create(
        mem,
        assembly=insn.1,
        name=insn.2,
        operands=insn.3,
      ),
    )
    for b in insn.0 {
      all.push(b)
    }
    addr = addr + insn.0.length().to_uint64()
  }
  let mem = @memory.Memory::from_bytes(
    endian=LittleEndian,
    start~,
    Bytes::from_array(all),
  )
  @project.ProjectDisassemblyBlock::create(mem, parts).unwrap()
}

///|
fn sample_env(
  options~ : @phoenix.Options = @phoenix.Options::new(),
) -> (@project.Project, @phoenix.Env) {
  let b1 = block(0x1000UL, [
    (
      b"\x55",
      "push rbp",
      "PUSH64r",
      [@project.ProjectInstructionOperand::register(name="RBP")],
    ),
    (
      b"\x48\x89\xe5",
      "mov rbp, rsp",
      "MOV64rr",
      [
        @project.ProjectInstructionOperand::register(name="RBP"),
        @project.ProjectInstructionOperand::register(name="RSP"),
      ],
    ),
  ])
  let b2 = block(0x1004UL, [(b"\xc3", "ret", "RETQ", [])])
  let main = @project.ProjectDisassemblyFunction::create(
    name="main",
    entry=b1,
    blocks=[b1, b2],
  )
  let symtab = @project.ProjectDisassemblySymtab::empty().add_symbol(main)
  let cfg = @project.ProjectDisassemblyCfg::create(nodes=[b1, b2], edges=[
    @project.ProjectDisassemblyCfgEdge::create(src=b1, dst=b2, kind=FallEdge),
  ])
  let project = @project.Project::empty(@core_theory.Target::unknown())
  (project, @phoenix.Env::new(project, options~, symtab~, cfg~))
}

///|
test "block names are relative to the enclosing function" {
  let (_, env) = sample_env()
  assert_eq(env.block_name(0x1000UL), "main_ENTRY")
  assert_eq(env.block_name(0x1004UL), "main_4")
  assert_eq(env.block_name(0x2000UL), "text_0x2000")
  assert_eq(env.block_name(0x5UL), "text_5")
}

///|
test "temporaries are inlined" {
  let t = @types.Var::new(name="t", typ=Imm(64), is_virtual=true)
  let rax = @types.Var::new(name="RAX", typ=Imm(64))
  let rbx = @types.Var::new(name="RBX", typ=Imm(64))
  let one = @types.Word::of_int(width=64, 1)
  let bil : Array[@types.Stmt] = [
    Move(t, BinOp(Plus, Var(rbx), Int(one))),
    Move(rax, Var(t)),
  ]
  assert_eq(
    @print.bil_to_string(@phoenix.inline_variables(bil)),
    "{\n  RAX := RBX + 1\n}",
  )
  // a temporary is kept when its source changes in its scope
  let kept : Array[@types.Stmt] = [
    Move(t, Var(rbx)),
    Move(rbx, Int(one)),
    Move(rax, Var(t)),
  ]
  assert_eq(@phoenix.inline_variables(kept).length(), 3)
}

///|
test "addresses are resolved to symbols" {
  let (_, env) = sample_env()
  let jmp : Array[@types.Stmt] = [
    Jmp(Int(@types.Word::of_int(width=64, 0x1004))),
    Jmp(Int(@types.Word::of_int(width=64, 0x1000))),
    Jmp(Int(@types.Word::of_int(width=64, 0x2000))),
  ]
  inspect(
    @print.bil_to_string(env.optimize(jmp)),
    content=(
      #|{
      #|  jmp (main + 4)
      #|  jmp main
      #|  jmp 0x2000
      #|}
    ),
  )
  let (_, raw) = sample_env(
    options=@phoenix.Options::new(no_optimizations=true),
  )
  inspect(
    @print.bil_to_string(raw.optimize(jmp)),
    content=(
      #|{
      #|  jmp 0x1004
      #|  jmp 0x1000
      #|  jmp 0x2000
      #|}
    ),
  )
}

///|
test "the cfg is printed like ocamlgraph" {
  let (_, env) = sample_env(
    options=@phoenix.Options::new(cfg_format=[WithAsm, WithName]),
  )
  inspect(
    env.cfg_to_dot(),
    content=(
      #|digraph G {
      #|  fontsize=14;
      #|  node [width=1.000000, fontname="Monospace", fontcolor="#666699",
      #|        fontsize=14, shape=box, ];
      #|  "main_ENTRY" [label="«main_ENTRY»\n\l1000: 55 PUSH64r(RBP)\l1001: 48 89 e5 MOV64rr(RBP RSP)\l",
      #|                ];
      #|  "main_4" [label="«main_4»\n\l1004: c3 RETQ()\l", ];
      #|  
      #|  
      #|  edge [penwidth=1.000000, ];
      #|  "main_ENTRY" -> "main_4" [weight=8, labelfloat=true, tailport=s,
      #|                            headport=n, arrowsize=0.500000, color="#000066", ];
      #|  
      #|  }
      #|
    ),
  )
}

///|
test "index, function list, and code pages" {
  let (_, env) = sample_env()
  inspect(
    env.index_json(filename="a.out", root="/tmp/phoenix"),
    content=(
      #|{
      #|  "text": ".",
      #|  "children": [
      #|    {
      #|      "text": "a.out",
      #|      "id": "/tmp/phoenix",
      #|      "expanded": true,
      #|      "root": true,
      #|      "children": [
      #|        {
      #|          "text": "main",
      #|          "id": "main",
      #|          "expanded": false,
      #|          "function": true,
      #|          "children": [
      #|            {
      #|              "text": "main_ENTRY",
      #|              "id": "main*main_ENTRY",
      #|              "expanded": false,
      #|              "function": false,
      #|              "leaf": true
      #|            },
      #|            {
      #|              "text": "main_4",
      #|              "id": "main*main_4",
      #|              "expanded": false,
      #|              "function": false,
      #|              "leaf": true
      #|            }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  ]
      #|}
    ),
  )
  inspect(
    env.functions_json(filename="a.out"),
    content=(
      #|{
      #|  "binary": {
      #|    "name": "a.out",
      #|    "functionNumber": 1,
      #|    "functions": [
      #|      {
      #|        "name": "main",
      #|        "startAddress": "1000",
      #|        "endAddress": "1004",
      #|        "hash": "0000000000000000000"
      #|      }
      #|    ]
      #|  }
      #|}
    ),
  )
  inspect(
    env.dump_page(),
    content=(
      #|
      #|
      #|
      #| <html>
      #|  <head>
      #|   <link rel="stylesheet" type="css" href="../../../css/code-panel.css"></link>
      #|  </head>
      #| 
      #|  <body>
      #|   <pre class="prettyprint linenums">
      #|   
      #|    <div id="main">
      #|     <a id="main_ENTRY">
      #|      <pre style="margin : 0">
      #|      1000: 55                 PUSH64r(RBP)
      #|      1001: 48 89 e5           MOV64rr(RBP,RSP)
      #|      </pre>
      #|     </a>
      #|    
      #|     <a id="main_4">
      #|      <pre style="margin : 0">
      #|      1004: c3                 RETQ()
      #|      </pre>
      #|     </a>
      #|    </div>
      #|     </pre>
      #|  
      #|  </body>
      #| </html>
      #|
    ),
  )
  let main = env.function_blocks(
    @project.ProjectDisassemblyFunction::create(
      name="main",
      entry=block(0x1000UL, [(b"\x55", "push rbp", "PUSH64r", [])]),
    ),
  )
  assert_eq(main.length(), 1)
}

///|
test "the site layout" {
  let (_, env) = sample_env()
  let files = env.render(filename="a.out", root="/tmp/phoenix")
  debug_inspect(
    files.map(f => f.0),
    content=(
      #|[
      #|  "cfg/main.cfg",
      #|  "sacfg/main.sacfg",
      #|  "bil/main.html",
      #|  "hil/main.html",
      #|  "phoenix.json",
      #|  "phoenix.functionlist",
      #|  "phoenix.html",
      #|]
    ),
  )
}

///|
test "the plugin is declared in the bap_main framework" {
  @bap_main.reset()
  @bap_main.set_file_system(@bap_main.FileSystem::in_memory(files=[]))
  @phoenix.declare_plugin()
  @bap_main.initialize(argv=[
    "bap", "--phoenix-labels-with=asm,bil", "--phoenix-no-inline",
  ])
  assert_eq(@bap_main.loaded_plugins(), ["phoenix"])
  assert_true(@project.find_pass(@phoenix.pass_name) is Some(_))
  @bap_main.reset()
}
