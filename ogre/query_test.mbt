// Expected results were cross-checked against upstream `Ogre.foreach`.

///|
fn[T, B] run_query(
  query : @ogre.Query[T],
  f : (T) -> B,
  doc : @ogre.Doc,
) -> Array[B] raise @ogre.OgreError {
  @ogre.eval(@ogre.foreach(query, f), doc)
}

///|
test "select with where clauses" {
  let doc = loaded()
  debug_inspect(
    run_query(@ogre.select(@ogre.from(segment)), s => s.addr, doc),
    content="[4096, 0]",
  )
  // a bool field is a predicate by itself
  debug_inspect(
    run_query(
      @ogre.select(where_=segment[executable], @ogre.from(segment)),
      s => s.addr,
      doc,
    ),
    content="[0]",
  )
  debug_inspect(
    run_query(
      @ogre.select(
        where_=segment[writable]
          .negate()
          .disj(segment[size].gt(@ogre.Exp::int(5000))),
        @ogre.from(segment),
      ),
      s => s.addr,
      doc,
    ),
    content="[4096, 0]",
  )
  debug_inspect(
    run_query(
      @ogre.select(
        where_=named_symbol[name].eq(@ogre.Exp::str("main")),
        @ogre.from(named_symbol),
      ),
      s => s.0,
      doc,
    ),
    content="[16]",
  )
  debug_inspect(
    run_query(
      @ogre.select(
        where_=named_symbol[name].lt(@ogre.Exp::str("b")),
        @ogre.from(named_symbol),
      ),
      s => s.1,
      doc,
    ),
    content=(
      #|["a very long name with spaces (and parens)"]
    ),
  )
  // symbols inside segments: a join through the where clause
  debug_inspect(
    run_query(
      @ogre.select(
        where_=segment[addr]
          .le(named_symbol[addr])
          .conj(named_symbol[addr].lt(segment[addr] + segment[size])),
        @ogre.from2(segment, named_symbol),
      ),
      p => "\{p.1.1} in \{p.0.addr}",
      doc,
    ),
    content=(
      #|["a very long name with spaces (and parens) in 0", "main in 0"]
    ),
  )
  // an attribute without facts yields no rows
  debug_inspect(
    run_query(@ogre.select(@ogre.from2(segment, entry_point)), p => p.1, doc),
    content="[]",
  )
}

///|
test "joins on unqualified and qualified fields" {
  let doc = loaded()
  // an unqualified field joins every selected attribute that has it
  debug_inspect(
    run_query(
      @ogre.select(
        join=[[@ogre.field(addr)]],
        @ogre.from(named_symbol).add(symbol_chunk),
      ),
      p => "\{p.0.1}@\{p.0.0}+\{p.1.1}",
      doc,
    ),
    content=(
      #|["a very long name with spaces (and parens)@32+4", "main@16+8"]
    ),
  )
  // qualified fields, plus a positional variable in the where clause
  debug_inspect(
    run_query(
      @ogre.select(
        where_=addr.at(0).ne(addr.at(1)),
        join=[
          [
            @ogre.field_of(symbol_chunk, root),
            @ogre.field_of(named_symbol, addr),
          ],
        ],
        @ogre.from3(symbol_chunk, named_symbol, segment),
      ),
      p => "\{p.0.0}/\{p.1.1}/\{p.2.addr}",
      doc,
    ),
    content="[]",
  )
  debug_inspect(
    run_query(
      @ogre.select(
        where_=addr.at(0).eq(addr.at(1)).conj(addr.at(2).eq(@ogre.Exp::int(0))),
        join=[
          [
            @ogre.field_of(symbol_chunk, root),
            @ogre.field_of(named_symbol, addr),
          ],
        ],
        @ogre.from3(symbol_chunk, named_symbol, segment),
      ),
      p => "\{p.0.0}/\{p.1.1}/\{p.2.addr}",
      doc,
    ),
    content=(
      #|["32/a very long name with spaces (and parens)/0", "16/main/0"]
    ),
  )
}

///|
test "the college example from the upstream documentation" {
  let gpa = @ogre.def("gpa", @ogre.Type::float())
  let classid = @ogre.def("classid", @ogre.Type::int())
  let teacher_id = @ogre.def("teacher", @ogre.Type::int())
  let id = @ogre.def("id", @ogre.Type::int())
  let student = @ogre.Attribute::new(
    name="student",
    @ogre.scheme4(name, gpa, classid, teacher_id),
    t => t,
  )
  let teacher = @ogre.Attribute::new(
    name="teacher",
    @ogre.scheme3(id, name, classid),
    t => t,
  )
  let doc = @ogre.Doc::from_string(
    (
      #|(declare student (name str) (gpa float) (classid int) (teacher int))
      #|(declare teacher (id int) (name str) (classid int))
      #|(student Joe 3.9 1 10) (student Ann 3.2 1 11) (student Bob 3.95 2 11)
      #|(teacher 10 Smith 1) (teacher 11 Jones 2) (teacher 12 Brown 1)
    ),
  )
  let pair = (p : ((String, Double, Int64, Int64), (Int64, String, Int64))) => {
    p.0.0 + "/" + p.1.1
  }
  debug_inspect(
    run_query(
      @ogre.select(
        where_=student[gpa].gt(@ogre.Exp::float(3.5)),
        join=[
          [@ogre.field(classid)],
          [@ogre.field_of(student, teacher_id), @ogre.field_of(teacher, id)],
        ],
        @ogre.from2(student, teacher),
      ),
      pair,
      doc,
    ),
    content=(
      #|["Bob/Jones", "Joe/Smith"]
    ),
  )
  debug_inspect(
    run_query(
      @ogre.select(join=[[@ogre.field(classid)]], @ogre.from2(student, teacher)),
      pair,
      doc,
    ),
    content=(
      #|["Bob/Jones", "Ann/Brown", "Ann/Smith", "Joe/Brown", "Joe/Smith"]
    ),
  )
  debug_inspect(
    run_query(
      @ogre.select(
        where_=student[gpa]
          .ge(@ogre.Exp::float(3.9))
          .implies(student[classid].eq(@ogre.Exp::int(2))),
        @ogre.from(student),
      ),
      s => s.0,
      doc,
    ),
    content=(
      #|["Bob", "Ann"]
    ),
  )
  // a self join with positional variables and arithmetic
  debug_inspect(
    run_query(
      @ogre.select(
        where_=(gpa.at(0) - @ogre.Exp::float(0.5)).gt(gpa.at(1)),
        @ogre.from2(student, student),
      ),
      p => p.0.0 + ">" + p.1.0,
      doc,
    ),
    content=(
      #|["Bob>Ann", "Joe>Ann"]
    ),
  )
}

///|
test "query evaluation errors" {
  let doc = loaded()
  // upstream raises `Failure "sat ~> bot"`: comparing two booleans with `=`
  // is not simplified to a truth value
  inspect(
    ogre_error(() => {
      ignore(
        run_query(
          @ogre.select(
            where_=segment[executable].eq(@ogre.Exp::bool(true)),
            @ogre.from(segment),
          ),
          s => s.addr,
          doc,
        ),
      )
    }),
    content="sat ~> bot",
  )
  inspect(
    ogre_error(() => {
      ignore(
        run_query(
          @ogre.select(
            where_=arch[name].eq(@ogre.Exp::str("x")),
            @ogre.from(segment),
          ),
          s => s.addr,
          doc,
        ),
      )
    }),
    content="attribute arch is not selected by the query",
  )
  inspect(
    ogre_error(() => {
      ignore(
        run_query(
          @ogre.select(
            where_=segment[root].eq(@ogre.Exp::int(0)),
            @ogre.from(segment),
          ),
          s => s.addr,
          doc,
        ),
      )
    }),
    content="query refers to a missing field root",
  )
  // a scheme that does not match the stored facts cannot be read
  let wide = @ogre.Attribute::new(name="arch", @ogre.scheme2(name, addr), t => t)
  inspect(
    ogre_error(() => {
      ignore(run_query(@ogre.select(@ogre.from(wide)), p => p.0, doc))
    }),
    content="can't parse attribute arch",
  )
  debug_inspect(doc.get(wide), content="[]")
}

///|
test "expressions are simplified as they are built" {
  debug_inspect(@ogre.Exp::int(1) + @ogre.Exp::int(2), content="Int(3)")
  debug_inspect(
    @ogre.Exp::float(1.5) - @ogre.Exp::float(0.0),
    content="Flt(1.5)",
  )
  debug_inspect(@ogre.Exp::str("a").lt(@ogre.Exp::str("b")), content="True")
  debug_inspect(@ogre.Exp::int(1).ge(@ogre.Exp::int(2)), content="Not(True)")
  debug_inspect(
    @ogre.Exp::bool(true).conj(segment[executable]),
    content=(
      #|Var({ attr: ByName("segment"), field: { name: "x", typ: Bool } })
    ),
  )
  debug_inspect(
    @ogre.Exp::bool(false).implies(segment[executable]),
    content=(
      #|Bop(
      #|  Or,
      #|  True,
      #|  Var({ attr: ByName("segment"), field: { name: "x", typ: Bool } }),
      #|)
    ),
  )
  // negations are pushed inwards (NNF)
  debug_inspect(
    segment[readable].disj(segment[writable]).negate(),
    content=(
      #|Bop(
      #|  And,
      #|  Not(Var({ attr: ByName("segment"), field: { name: "r", typ: Bool } })),
      #|  Not(Var({ attr: ByName("segment"), field: { name: "w", typ: Bool } })),
      #|)
    ),
  )
  debug_inspect(
    size.at(1).le(@ogre.Exp::int(4)),
    content=(
      #|Not(
      #|  Bop(
      #|    Lt,
      #|    Int(4),
      #|    Var({ attr: ByPos(1), field: { name: "size", typ: Int } }),
      #|  ),
      #|)
    ),
  )
  debug_inspect(
    @ogre.field_of(segment, addr),
    content=(
      #|{ attr: Some("segment"), field: { name: "addr", typ: Int } }
    ),
  )
}
