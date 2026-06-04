///|
test "project analysis args parse positional keyword flag and rest inputs" {
  let args = @project.ProjectAnalysisArgs::triple(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::keyword(
      "limit",
      @project.ProjectAnalysisArg::int(),
    ),
    @project.ProjectAnalysisArg::flag("verbose"),
  )
  assert_true(args.grammar_string() == "<string> [:limit <int>] [:verbose]")
  match args.parse(["main", ":verbose", ":limit", "7"]) {
    Ok(value) => {
      assert_true(value.0 == "main")
      assert_true(value.1 == Some(7))
      assert_true(value.2)
    }
    Err(reason) => fail(reason)
  }
  let rest_args = @project.ProjectAnalysisArgs::pair(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::rest(@project.ProjectAnalysisArg::string()),
  )
  match rest_args.parse(["head", "tail-a", "tail-b"]) {
    Ok(value) => {
      assert_true(value.0 == "head")
      assert_true(value.1 == ["tail-a", "tail-b"])
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project analysis grammar exposes BAP-style string rendering" {
  let rules = ["<string>", "[:dry-run]"]
  let grammar = @project.ProjectAnalysisGrammar::create(rules)
  rules.push("<mutated>")
  assert_true(grammar.rules() == ["<string>", "[:dry-run]"])
  assert_true(grammar.to_string() == "<string> [:dry-run]")
  let args = @project.ProjectAnalysisArgs::pair(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::flag("dry-run"),
  )
  assert_true(args.grammar_rules() == ["<string>", "[:dry-run]"])
  let analysis = @project.ProjectAnalysis::create(
    name="unit-analysis-grammar",
    args~,
    run=_ => Ok(()),
  )
  assert_true(analysis.grammar().to_string() == "<string> [:dry-run]")
  assert_true(analysis.grammar_rules() == ["<string>", "[:dry-run]"])
  let info = analysis.info()
  assert_true(info.grammar().to_string() == "<string> [:dry-run]")
  assert_true(info.grammar_rules() == ["<string>", "[:dry-run]"])
}

///|
test "project analysis args parse four and five argument tuples" {
  let quad = @project.ProjectAnalysisArgs::quad(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::int(),
    @project.ProjectAnalysisArg::keyword(
      "mode",
      @project.ProjectAnalysisArg::string(),
    ),
    @project.ProjectAnalysisArg::flag("force"),
  )
  assert_true(
    quad.grammar_string() == "<string> <int> [:mode <string>] [:force]",
  )
  match quad.parse(["main", "7", ":force", ":mode", "fast"]) {
    Ok(value) => {
      assert_true(value.0 == "main")
      assert_true(value.1 == 7)
      assert_true(value.2 == Some("fast"))
      assert_true(value.3)
    }
    Err(reason) => fail(reason)
  }
  let quint = @project.ProjectAnalysisArgs::quint(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::int(),
    @project.ProjectAnalysisArg::optional(@project.ProjectAnalysisArg::string()),
    @project.ProjectAnalysisArg::flag("dry-run"),
  )
  assert_true(
    quint.grammar_string() == "<string> <string> <int> [<string>] [:dry-run]",
  )
  match quint.parse(["from", "to", "3", "label", ":dry-run"]) {
    Ok(value) => {
      assert_true(value.0 == "from")
      assert_true(value.1 == "to")
      assert_true(value.2 == 3)
      assert_true(value.3 == Some("label"))
      assert_true(value.4)
    }
    Err(reason) => fail(reason)
  }
}

///|
test "project analysis args report syntax failures" {
  let empty = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::empty(),
  )
  assert_true(empty.parse([]) == Ok(()))
  assert_true(empty.parse(["unexpected"]) is Err(_))
  let limit = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::keyword(
      "limit",
      @project.ProjectAnalysisArg::int(),
    ),
  )
  assert_true(limit.parse([":limit"]) is Err(_))
  assert_true(limit.parse([":limit", "nope"]) is Err(_))
}

///|
test "project analysis bitvec and core object arguments parse" {
  let bits = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::bitvec(),
  )
  match bits.parse(["0x2a:8u"]) {
    Ok(value) => {
      assert_true(value.width() == 8)
      assert_true(value.to_hex() == "0x2a")
    }
    Err(reason) => fail(reason)
  }
  match bits.parse(["42:8"]) {
    Ok(value) => assert_true(value.to_hex() == "0x2a")
    Err(reason) => fail(reason)
  }
  match bits.parse(["true"]) {
    Ok(value) => assert_true(value == @bitvec.b1())
    Err(reason) => fail(reason)
  }
  assert_true(bits.parse(["0x2a"]) is Err(_))
  let label_arg = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::program(),
  )
  match label_arg.parse(["entry"]) {
    Ok(label) => assert_true(label.name() == Some("entry"))
    Err(reason) => fail(reason)
  }
  let unit_arg = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::unit(),
  )
  match unit_arg.parse(["main.o"]) {
    Ok(unit) => assert_true(unit.path() == Some("main.o"))
    Err(reason) => fail(reason)
  }
}

///|
test "project analyses register find and apply typed callbacks" {
  let seen : Ref[String] = Ref("")
  let args = @project.ProjectAnalysisArgs::pair(
    @project.ProjectAnalysisArg::string(),
    @project.ProjectAnalysisArg::flag("dry-run"),
  )
  let analysis = @project.ProjectAnalysis::create(
    name="unit-analysis-registry",
    description="unit test analysis",
    args~,
    run=value => {
      seen.val = "\{value.0}:\{value.1}"
      Ok(())
    },
  )
  match @project.register_analysis(analysis) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_analysis(analysis) is Err(_))
  match @project.find_analysis("unit-analysis-registry") {
    Some(found) => {
      assert_true(found.name() == "unit-analysis-registry")
      assert_true(found.pkg() == "user")
      assert_true(found.qualified_name().show() == "unit-analysis-registry")
      assert_true(found.description() == "unit test analysis")
      assert_true(found.desc() == "unit test analysis")
      assert_true(found.grammar_string() == "<string> [:dry-run]")
      match found.apply(["target", ":dry-run"]) {
        Ok(_) => assert_true(seen.val == "target:true")
        Err(reason) => fail(reason)
      }
    }
    None => fail("analysis was not registered")
  }
  match @project.apply_analysis("unit-analysis-registry", ["target"]) {
    Ok(_) => assert_true(seen.val == "target:false")
    Err(reason) => fail(reason)
  }
  let mut seen_info = false
  for info in @project.registered_analyses() {
    if info.name() == "unit-analysis-registry" {
      seen_info = true
      assert_true(info.pkg() == "user")
      assert_true(info.qualified_name().show() == "unit-analysis-registry")
      assert_true(info.desc() == "unit test analysis")
    }
  }
  assert_true(seen_info)
  assert_true(@project.apply_analysis("missing-analysis", []) is Err(_))
}

///|
test "project analyses support package-qualified lookup and apply" {
  let left_seen : Ref[String] = Ref("")
  let right_seen : Ref[String] = Ref("")
  let args = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::string(),
  )
  let left = @project.ProjectAnalysis::create(
    name="unit-packaged-analysis",
    pkg="left",
    args~,
    run=value => {
      left_seen.val = "L:" + value
      Ok(())
    },
  )
  let right = @project.ProjectAnalysis::create(
    name="unit-packaged-analysis",
    pkg="right",
    args~,
    run=value => {
      right_seen.val = "R:" + value
      Ok(())
    },
  )
  match @project.register_analysis(left) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  match @project.register_analysis(right) {
    Ok(_) => ()
    Err(reason) => fail(reason)
  }
  assert_true(@project.register_analysis(left) is Err(_))
  match @project.find_analysis("unit-packaged-analysis", pkg="left") {
    Some(found) => {
      assert_true(found.name() == "unit-packaged-analysis")
      assert_true(found.pkg() == "left")
      assert_true(found.description() == "not provided")
      assert_true(found.desc() == "not provided")
      assert_true(
        found.qualified_name().show() == "left:unit-packaged-analysis",
      )
      match found.apply(["alpha"]) {
        Ok(_) => assert_true(left_seen.val == "L:alpha")
        Err(reason) => fail(reason)
      }
    }
    None => fail("left analysis was not registered")
  }
  match @project.find_analysis("right:unit-packaged-analysis") {
    Some(found) => {
      assert_true(found.pkg() == "right")
      assert_true(found.description() == "not provided")
      match found.apply(["beta"]) {
        Ok(_) => assert_true(right_seen.val == "R:beta")
        Err(reason) => fail(reason)
      }
    }
    None => fail("right analysis was not registered")
  }
  assert_true(@project.find_analysis("unit-packaged-analysis") is None)
  assert_true(
    @project.apply_analysis("unit-packaged-analysis", ["gamma"]) is Err(_),
  )
  match
    @project.apply_analysis("unit-packaged-analysis", ["gamma"], pkg="left") {
    Ok(_) => assert_true(left_seen.val == "L:gamma")
    Err(reason) => fail(reason)
  }
}

///|
test "registered project analyses preserve registration order" {
  let args = @project.ProjectAnalysisArgs::one(
    @project.ProjectAnalysisArg::string(),
  )
  let make = name => {
    @project.ProjectAnalysis::create(name~, args~, run=_ => Ok(()))
  }
  let first = make("unit-order-analysis-z")
  let second = make("unit-order-analysis-a")
  let third = make("unit-order-analysis-m")
  for analysis in [first, second, third] {
    match @project.register_analysis(analysis) {
      Ok(_) => ()
      Err(reason) => fail(reason)
    }
  }
  let names = @project.registered_analyses()
    .map(info => info.name())
    .filter(name => name.has_prefix("unit-order-analysis-"))
  assert_true(
    names ==
    ["unit-order-analysis-z", "unit-order-analysis-a", "unit-order-analysis-m"],
  )
}
