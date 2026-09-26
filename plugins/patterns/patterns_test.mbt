///|
test "ditted patterns" {
  let p = @patterns.Pattern::create("0x55 0x89e5")
  assert_eq(p.length(), 3)
  assert_eq(p.weight(), 24)
  assert_true(p.matches(pos=0, 0x55))
  assert_true(p.matches(pos=2, 0xe5))
  assert_false(p.matches(pos=1, 0x88))
  assert_false(p.matches(pos=3, 0x00))
  // nibble and bit masks
  let p = @patterns.Pattern::create("0x5. 10.1....")
  assert_eq(p.length(), 2)
  assert_eq(p.weight(), 7)
  assert_true(p.matches(pos=0, 0x5f))
  assert_false(p.matches(pos=0, 0x6f))
  assert_true(p.matches(pos=1, 0b1011_0000))
  assert_true(p.matches(pos=1, 0b1001_1111))
  assert_false(p.matches(pos=1, 0b1101_0000))
  // underscores are ignored in nibbles
  let p = @patterns.Pattern::create("0xde_ad")
  assert_eq(p.length(), 2)
  assert_true(p.matches(pos=1, 0xad))
  // a leading zero starts a binary sequence: "01" is two bits
  let p = @patterns.Pattern::create("0110 0101 00001111")
  assert_eq(p.length(), 2)
  assert_true(p.matches(pos=0, 0b0110_0101))
  // a lone zero is dropped (upstream quirk): 7 + 8 bits, the leading bit
  // is ignored when split into bytes but counted by the weight
  let p = @patterns.Pattern::create("0 1111111 11110000")
  assert_eq(p.weight(), 15)
  assert_eq(p.length(), 1)
  assert_true(p.matches(pos=0, 0b1111_0000))
  // concatenation
  let q = @patterns.Pattern::create("0xc3").concat(
    @patterns.Pattern::create("0x90"),
  )
  assert_eq(q.length(), 2)
  assert_eq(q.weight(), 16)
  inspect(q, content="0xc30x90")
  assert_eq(@patterns.Pattern::empty().length(), 0)
  assert_false(@patterns.Pattern::empty().matches(pos=0, 0))
  let err = try @patterns.Pattern::create("0x5z") catch {
    PatternError(msg) => msg
  } noraise {
    _ => "ok"
  }
  inspect(err, content="invalid digit `z' in pattern 0x5z")
}

///|
test "actions" {
  let input = @xml.Input::from_string(
    "<r xmlns:e=\"http://example.com/ns\" xmlns:u=\"urn:foo\"><funcstart after=\"defined\" validcode=\"1\"/><e:mark e:x=\"1\"/><u:mark/></r>",
  )
  let _ = input.input()
  let _ = input.input()
  let tags = []
  while !input.eoi() {
    match input.input() {
      ElStart(t) => tags.push(t)
      _ => ()
    }
  }
  let actions = tags.map(@patterns.Action::of_tag)
  inspect(
    actions.map(a => a.to_string()).join("\n"),
    content=(
      #|(bap:funcstart :after "defined" :validcode "1")
      #|(example.com:mark example.com:x "1")
      #|(urn\:foo:mark)
    ),
  )
  assert_eq(actions[0].attribute("after"), Some("defined"))
  assert_eq(actions[0].attribute(":validcode"), Some("1"))
  assert_eq(actions[0].attribute("missing"), None)
  let set = @patterns.ActionSet::of_array([actions[1], actions[0], actions[1]])
  assert_eq(set.to_array().length(), 2)
  assert_true(set.mem(actions[0]))
  assert_false(set.mem(actions[2]))
  assert_true(set.diff(set).is_empty())
  let a = @patterns.Action::create(@patterns.bap_action("funcstart"))
  inspect(a, content="(bap:funcstart)")
}

///|
test "target specifications" {
  let x86_64 = @core_theory.Target::x86_64()
  let spec = (s : String) => {
    @patterns.TargetSpec::parse(s) catch {
      e => fail(e.to_string())
    }
  }
  assert_true(spec("x86:LE:64:default").matches(x86_64))
  assert_true(spec("X86:*:default").matches(x86_64))
  assert_false(spec("x86:LE:32:default").matches(x86_64))
  assert_false(spec("x86:BE:64:default").matches(x86_64))
  assert_true(spec("x86:LEBE:64:default:gcc").matches(x86_64))
  assert_false(spec("ARM:LE:64:v8").matches(x86_64))
  assert_true(spec("x86_64").matches(x86_64))
  // x86_64 is a descendant of i386
  assert_true(spec("i386").matches(x86_64))
  assert_false(spec("armeb").matches(x86_64))
  guard spec("x86:LE:64:v1:gcc") is Spec(variant~, compiler~, ..) else {
    fail("expected a spec")
  }
  debug_inspect((variant, compiler), content="(Some(\"v1\"), Some(\"gcc\"))")
  let err = (s : String) => {
    try @patterns.TargetSpec::parse(s) catch {
      e => e.to_string()
    } noraise {
      _ => "ok"
    }
  }
  inspect(
    err("x86:XE:64:default"),
    content="wrong endianness in x86:XE:64:default",
  )
  inspect(err("no-such-target"), content="unrecognized target no-such-target")
}

///|
test "parse errors" {
  inspect(
    @patterns.parse_patterns(
      "<patternlist><pattern><data>0x55</data><funcstart><x/></funcstart></pattern></patternlist>",
    ).unwrap_err(),
    content=(
      #|Parser failed at line 1, column 51.
      #|An unexpected tag x
    ),
  )
  inspect(
    @patterns.parse_patterns(
      "<patternlist><patternpairs><prepatterns/></patternpairs></patternlist>",
    ).unwrap_err(),
    content=(
      #|Parser failed at line 1, column 14.
      #|The element is required
    ),
  )
  inspect(
    @patterns.parse_patterns("<patternconstraints/>").unwrap_err(),
    content=(
      #|Parser failed at line 1, column 1.
      #|An unexpected tag patternconstraints
    ),
  )
  inspect(
    @patterns.parse_constraints(
      "<patternconstraints><language><patternfile>a</patternfile></language></patternconstraints>",
    ).unwrap_err(),
    content=(
      #|Parser failed at line 1, column 21.
      #|The attribute "id" of the tag 'language' is required
    ),
  )
  inspect(
    @patterns.parse_patterns("<patternlist><pattern>").unwrap_err(),
    content=(
      #|Parser failed at line 1, column 23.
      #|Malformed XML: 1:23: unexpected end of input inside an element
    ),
  )
  inspect(
    @patterns.parse_patterns(
      "<patternlist><pattern><data>0xzz</data></pattern></patternlist>",
    ).unwrap_err(),
    content=(
      #|Parser failed at line 1, column 33.
      #|invalid digit `z' in pattern 0xzz
    ),
  )
  // an empty list is fine
  assert_eq(@patterns.parse_patterns("<patternlist/>").unwrap().length(), 0)
}
