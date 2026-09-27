// Select queries (upstream `Query`) and their evaluation (upstream
// `Exp.eval`).

///|
/// A selection of attributes (upstream `'a tables`), built with [from] and
/// [Tables::add]. The type parameter is the type of one result row: `from(a)`
/// selects rows of type `A`, `from(a).add(b)` rows of type `(A, B)`, and so
/// on.
struct Tables[T] {
  names : Array[String]
  read : (Array[Entry]) -> T raise OgreError
}

///|
fn[A, K] read_column(
  row : Array[Entry],
  attr : Attribute[A, K],
  pos : Int,
) -> A raise OgreError {
  match (attr.read)(row[pos]) {
    Some(value) => value
    None => ogre_fail("can't parse attribute \{attr.name}")
  }
}

///|
/// Selects one attribute (upstream `from`).
pub fn[A, K] from(attr : Attribute[A, K]) -> Tables[A] {
  { names: [attr.name], read: row => read_column(row, attr, 0), }
}

///|
/// Appends an attribute to a selection (upstream `$`).
pub fn[T, B, K] Tables::add(
  self : Tables[T],
  attr : Attribute[B, K],
) -> Tables[(T, B)] {
  let arity = self.names.length()
  let names = self.names.copy()
  names.push(attr.name)
  { names, read: row => ((self.read)(row), read_column(row, attr, arity)), }
}

///|
/// Selects two attributes, producing flat pairs.
pub fn[A, KA, B, KB] from2(
  a : Attribute[A, KA],
  b : Attribute[B, KB],
) -> Tables[(A, B)] {
  from(a).add(b)
}

///|
/// Selects three attributes, producing flat triples.
pub fn[A, KA, B, KB, C, KC] from3(
  a : Attribute[A, KA],
  b : Attribute[B, KB],
  c : Attribute[C, KC],
) -> Tables[(A, B, C)] {
  let t = from(a).add(b).add(c)
  {
    names: t.names,
    read: row => {
      let ((x, y), z) = (t.read)(row)
      (x, y, z)
    },
  }
}

///|
/// The names of the selected attributes, in selection order.
pub fn[T] Tables::names(self : Tables[T]) -> Array[String] {
  self.names.copy()
}

///|
/// A join variable (upstream `join`): a field, optionally qualified by the
/// attribute it belongs to. See [field] and [field_of].
struct Join {
  attr : String?
  field : Header
} derive(Eq, Debug)

///|
/// An unqualified join variable (upstream `field fld`): it stands for the
/// field `fld` of every selected attribute that has such a field.
pub fn[T] field(fld : Field[T]) -> Join {
  { attr: None, field: fld.header(), }
}

///|
/// A qualified join variable (upstream `field fld ~from:attr`).
pub fn[A, K, T] field_of(attr : Attribute[A, K], fld : Field[T]) -> Join {
  { attr: Some(attr.name), field: fld.header(), }
}

///|
/// A select query (upstream `'a query`).
struct Query[T] {
  where_ : Exp
  join : Array[Array[Join]]
  tables : Tables[T]
}

///|
/// `select(where_?, join?, tables)` selects the rows of the cross product of
/// `tables` that satisfy every join class (all variables of a class are
/// equal) and the `where_` condition (upstream `select`).
pub fn[T] select(
  where_? : Exp = Exp::bool(true),
  join? : Array[Array[Join]] = [],
  tables : Tables[T],
) -> Query[T] {
  { where_, join: join.map(cls => cls.copy()), tables, }
}

// --- evaluation ---

///|
/// A compiled variable: reads the value of a field from a row.
priv struct Getter {
  get : (Array[Entry]) -> Term[Getter] raise OgreError
}

///|
fn lift_value(typ : Typ, value : String) -> Term[Getter] raise OgreError {
  match typ {
    Int =>
      match parse_ocaml_int64(value) {
        Some(x) => Int(x)
        None => ogre_fail("expression parse error")
      }
    Str => Str(value)
    Float =>
      match parse_ocaml_float(value) {
        Some(x) => Flt(x)
        None => ogre_fail("expression parse error")
      }
    Bool =>
      match parse_ocaml_bool(value) {
        Some(x) => Term::bool(x)
        None => ogre_fail("expression parse error")
      }
  }
}

///|
fn row_field(
  row : Array[Entry],
  idx : Int,
  name : String,
) -> String raise OgreError {
  match row.get(idx) {
    None => ogre_fail("query refers to attribute #\{idx} outside the selection")
    Some(entry) =>
      match entry.get(name) {
        Some(value) => value
        None => ogre_fail("query refers to a missing field \{name}")
      }
  }
}

///|
fn vars_of_join(
  names : Array[String],
  doc : Doc,
  join : Join,
) -> Array[Column[Name]] {
  match join.attr {
    Some(name) => [{ attr: ByName(name), field: join.field, }]
    None => {
      let result = []
      for pos, name in names {
        match doc.scheme.get(name) {
          Some(sign) if sign.contains(join.field) =>
            result.push(Column::{ attr: ByPos(pos), field: join.field, })
          _ => ()
        }
      }
      result
    }
  }
}

///|
fn unify_class(
  names : Array[String],
  doc : Doc,
  cls : Array[Join],
) -> Term[Column[Name]] {
  let vars = []
  for join in cls {
    vars.append(vars_of_join(names, doc, join))
  }
  if vars.length() < 2 {
    return True
  }
  let x = vars[0]
  let mut cs = equal(Var(x), Var(vars[1]))
  for z in vars[2:] {
    cs = conj(cs, equal(Var(x), Var(z)))
  }
  cs
}

///|
fn unify(
  names : Array[String],
  doc : Doc,
  joins : Array[Array[Join]],
) -> Term[Column[Name]] {
  let mut cs = True
  for cls in joins {
    cs = conj(cs, unify_class(names, doc, cls))
  }
  cs
}

///|
fn normalize_vars(
  names : Array[String],
  e : Term[Column[Name]],
) -> Term[Column[Int]] raise OgreError {
  let offsets : Map[String, Int] = Map([])
  for pos, name in names {
    offsets[name] = pos
  }
  fn subst(e : Term[Column[Name]]) -> Term[Column[Int]] raise OgreError {
    match e {
      True => True
      Int(x) => Int(x)
      Str(x) => Str(x)
      Flt(x) => Flt(x)
      Not(x) => simpl(Not(subst(x)))
      Bop(op, x, y) => simpl(Bop(op, subst(x), subst(y)))
      Var({ attr, field, }) => {
        let idx = match attr {
          ByName(name) =>
            match offsets.get(name) {
              Some(idx) => idx
              None =>
                ogre_fail("attribute \{name} is not selected by the query")
            }
          ByPos(pos) => pos
        }
        Var({ attr: idx, field, })
      }
    }
  }

  subst(e)
}

///|
fn lambda(e : Term[Column[Int]]) -> Term[Getter] {
  match e {
    True => True
    Int(x) => Int(x)
    Str(x) => Str(x)
    Flt(x) => Flt(x)
    Bop(EqOp, Var({ attr: x, field: f1, }), Var({ attr: y, field: f2, })) =>
      Var({
        get: row => {
          Term::bool(row_field(row, x, f1.name) == row_field(row, y, f2.name))
        },
      })
    Bop(op, x, y) => Bop(op, lambda(x), lambda(y))
    Not(x) => Not(lambda(x))
    Var({ attr: idx, field, }) =>
      Var({
        get: row => lift_value(field.typ, row_field(row, idx, field.name)),
      })
  }
}

///|
fn sat(row : Array[Entry], exp : Term[Getter]) -> Bool raise OgreError {
  fn eval(e : Term[Getter]) -> Term[Getter] raise OgreError {
    match e {
      True | Int(_) | Str(_) | Flt(_) => e
      Var(getter) => (getter.get)(row)
      Not(x) => simpl(Not(eval(x)))
      Bop(And, x, y) =>
        match eval(x) {
          True => eval(y)
          Not(True) as r => r
          _ => ogre_fail("type error: and ~> bot")
        }
      Bop(Or, x, y) =>
        match eval(x) {
          True => True
          Not(True) => eval(y)
          _ => ogre_fail("type error: or ~> bot")
        }
      Bop(op, x, y) => simpl(Bop(op, eval(x), eval(y)))
    }
  }

  match eval(exp) {
    True => true
    Not(True) => false
    _ => ogre_fail("sat ~> bot")
  }
}

///|
/// Evaluates a selection: the rows of the cross product of the selected
/// attributes' facts (in fact order, first attribute outermost) that satisfy
/// the join classes and the condition.
fn eval_rows(
  names : Array[String],
  joins : Array[Array[Join]],
  exp : Term[Column[Name]],
  doc : Doc,
) -> Array[Array[Entry]] raise OgreError {
  let cs = unify(names, doc, joins)
  let exp = lambda(simpl(normalize_vars(names, conj(cs, exp))))
  let columns = []
  for name in names {
    match doc.entries.get(name) {
      None => return []
      Some(facts) => columns.push(facts.items.to_array())
    }
  }
  let result = []
  let row = []
  fn cross(i : Int) -> Unit raise OgreError {
    if i == columns.length() {
      if row.length() > 0 && sat(row, exp) {
        result.push(row.copy())
      }
    } else {
      for entry in columns[i] {
        row.push(entry)
        cross(i + 1)
        ignore(row.pop())
      }
    }
  }

  cross(0)
  result
}

///|
/// Runs a query against a document, applying `f` to every selected row
/// (the pure core of upstream `foreach`).
pub fn[T, B] Query::eval(
  self : Query[T],
  doc : Doc,
  f : (T) -> B,
) -> Array[B] raise OgreError {
  let result = []
  for row in eval_rows(self.tables.names, self.join, self.where_.term, doc) {
    result.push(f((self.tables.read)(row)))
  }
  result
}

///|
pub extend Join with Eq::{equal, not_equal}

///|
pub extend Join with Debug::{to_repr}
