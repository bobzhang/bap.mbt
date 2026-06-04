///|
fn project_read_persistent_int64(input : String) -> Result[Int64, String] {
  try @string.parse_int64(input) catch {
    _ => Err("invalid persistent project IR int64")
  } noraise {
    value => Ok(value)
  }
}

///|
fn project_read_persistent_double(input : String) -> Result[Double, String] {
  try @string.parse_double(input) catch {
    _ => Err("invalid persistent project IR double")
  } noraise {
    value => Ok(value)
  }
}

///|
fn project_ir_fields() -> @knowledge.Persistent[Array[String]] {
  @knowledge.Persistent::array(@knowledge.Persistent::string())
}

///|
fn project_ir_tid_persistent() -> @knowledge.Persistent[@types.Tid] {
  let int_codec = @knowledge.Persistent::int()
  let name_codec = @knowledge.Persistent::optional(
    @knowledge.Persistent::string(),
  )
  let ivec_codec = @knowledge.Persistent::optional(int_codec)
  let string_codec = @knowledge.Persistent::string()
  @knowledge.Persistent::convert(
    to_persistent=tid => {
      [
        int_codec.encode(tid.id()),
        name_codec.encode(tid.name()),
        ivec_codec.encode(tid.ivec()),
        string_codec.encode(tid.pkg()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 && fields.length() != 4 {
        return Err("invalid persistent project IR tid")
      }
      let id = match int_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let name = match name_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let ivec = match ivec_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let pkg = if fields.length() == 4 {
        match string_codec.decode(fields[3]) {
          Ok(value) => value
          Err(reason) => return Err(reason)
        }
      } else {
        "user"
      }
      Ok(@types.Tid::restore(id~, pkg~, name?, ivec?))
    },
    project_ir_fields(),
  )
}

///|
fn project_ir_word_persistent() -> @knowledge.Persistent[@types.Word] {
  @knowledge.Persistent::create(to_string=word => word.to_string(), of_string=input => {
    try @types.Word::from_string(input[:]) catch {
      _ => Err("invalid persistent project IR word")
    } noraise {
      word => Ok(word)
    }
  })
}

///|
fn project_ir_attrs_persistent() -> @knowledge.Persistent[Map[String, String]] {
  @knowledge.Persistent::map(
    @knowledge.Persistent::string(),
    @knowledge.Persistent::string(),
  )
}

///|
fn[T] project_ir_term_fields(
  term : @types.Term[T],
  payload : String,
) -> Array[String] {
  [
    project_ir_tid_persistent().encode(term.tid()),
    project_ir_attrs_persistent().encode(term.attrs()),
    payload,
  ]
}

///|
fn project_ir_decode_term_fields(
  fields : Array[String],
  context : String,
) -> Result[(@types.Tid, Map[String, String], String), String] {
  if fields.length() != 3 {
    return Err("invalid persistent project IR \{context} term")
  }
  let tid = match project_ir_tid_persistent().decode(fields[0]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  let attrs = match project_ir_attrs_persistent().decode(fields[1]) {
    Ok(value) => value
    Err(reason) => return Err(reason)
  }
  Ok((tid, attrs, fields[2]))
}

///|
fn project_value_type_persistent() -> @knowledge.Persistent[@types.ValueType] {
  let int_codec = @knowledge.Persistent::int()
  @knowledge.Persistent::convert(
    to_persistent=typ => {
      match typ {
        Imm(width) => ["imm", int_codec.encode(width)]
        Mem(addr_width~, value_width~) =>
          ["mem", int_codec.encode(addr_width), int_codec.encode(value_width)]
      }
    },
    of_persistent=fields => {
      match fields {
        ["imm", width_text] => {
          let width = match int_codec.decode(width_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Imm(width))
        }
        ["mem", addr_text, value_text] => {
          let addr_width = match int_codec.decode(addr_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          let value_width = match int_codec.decode(value_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Mem(addr_width~, value_width~))
        }
        _ => Err("invalid persistent project IR value type")
      }
    },
    project_ir_fields(),
  )
}

///|
fn project_var_persistent() -> @knowledge.Persistent[@types.Var] {
  let type_codec = project_value_type_persistent()
  let bool_codec = @knowledge.Persistent::bool()
  @knowledge.Persistent::convert(
    to_persistent=variable => {
      [
        variable.name(),
        type_codec.encode(variable.typ()),
        bool_codec.encode(variable.is_virtual()),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 3 {
        return Err("invalid persistent project IR variable")
      }
      let typ = match type_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let is_virtual = match bool_codec.decode(fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Var::new(name=fields[0], typ~, is_virtual~))
    },
    project_ir_fields(),
  )
}

///|
fn project_ir_unop_name(op : @types.UnOp) -> String {
  match op {
    Not => "not"
    Neg => "neg"
  }
}

///|
fn project_ir_read_unop(input : String) -> Result[@types.UnOp, String] {
  match input {
    "not" => Ok(Not)
    "neg" => Ok(Neg)
    _ => Err("invalid persistent project IR unary operator")
  }
}

///|
fn project_ir_binop_name(op : @types.BinOp) -> String {
  match op {
    Plus => "plus"
    Minus => "minus"
    Times => "times"
    Div => "div"
    SignedDiv => "signed-div"
    Mod => "mod"
    SignedMod => "signed-mod"
    And => "and"
    Or => "or"
    Xor => "xor"
    LShift => "lshift"
    RShift => "rshift"
    ARShift => "arshift"
    Eq => "eq"
    Neq => "neq"
    Lt => "lt"
    Le => "le"
    SignedLt => "signed-lt"
    SignedLe => "signed-le"
  }
}

///|
fn project_ir_read_binop(input : String) -> Result[@types.BinOp, String] {
  match input {
    "plus" => Ok(Plus)
    "minus" => Ok(Minus)
    "times" => Ok(Times)
    "div" => Ok(Div)
    "signed-div" => Ok(SignedDiv)
    "mod" => Ok(Mod)
    "signed-mod" => Ok(SignedMod)
    "and" => Ok(And)
    "or" => Ok(Or)
    "xor" => Ok(Xor)
    "lshift" => Ok(LShift)
    "rshift" => Ok(RShift)
    "arshift" => Ok(ARShift)
    "eq" => Ok(Eq)
    "neq" => Ok(Neq)
    "lt" => Ok(Lt)
    "le" => Ok(Le)
    "signed-lt" => Ok(SignedLt)
    "signed-le" => Ok(SignedLe)
    _ => Err("invalid persistent project IR binary operator")
  }
}

///|
fn project_ir_cast_name(kind : @types.CastKind) -> String {
  match kind {
    Unsigned => "unsigned"
    Signed => "signed"
    High => "high"
    Low => "low"
  }
}

///|
fn project_ir_read_cast(input : String) -> Result[@types.CastKind, String] {
  match input {
    "unsigned" => Ok(Unsigned)
    "signed" => Ok(Signed)
    "high" => Ok(High)
    "low" => Ok(Low)
    _ => Err("invalid persistent project IR cast")
  }
}

///|
fn project_exp_persistent() -> @knowledge.Persistent[@types.Exp] {
  @knowledge.Persistent::create(
    to_string=exp => project_ir_fields().encode(project_exp_fields(exp)),
    of_string=input => {
      match project_ir_fields().decode(input) {
        Ok(fields) => project_exp_of_fields(fields)
        Err(reason) => Err(reason)
      }
    },
  )
}

///|
fn project_exp_fields(exp : @types.Exp) -> Array[String] {
  let exp_codec = project_exp_persistent()
  let var_codec = project_var_persistent()
  let type_codec = project_value_type_persistent()
  let word_codec = project_ir_word_persistent()
  let int_codec = @knowledge.Persistent::int()
  match exp {
    Int(word) => ["int", word_codec.encode(word)]
    Var(variable) => ["var", var_codec.encode(variable)]
    Unknown(name, typ) => ["unknown", name, type_codec.encode(typ)]
    Load(mem~, addr~, endian~, typ~) =>
      [
        "load",
        exp_codec.encode(mem),
        exp_codec.encode(addr),
        project_persistent_endian(endian),
        type_codec.encode(typ),
      ]
    Store(mem~, addr~, value~, endian~) =>
      [
        "store",
        exp_codec.encode(mem),
        exp_codec.encode(addr),
        exp_codec.encode(value),
        project_persistent_endian(endian),
      ]
    Let(variable, value, body) =>
      [
        "let",
        var_codec.encode(variable),
        exp_codec.encode(value),
        exp_codec.encode(body),
      ]
    Cast(kind~, width~, exp~) =>
      [
        "cast",
        project_ir_cast_name(kind),
        int_codec.encode(width),
        exp_codec.encode(exp),
      ]
    Extract(hi~, lo~, exp~) =>
      [
        "extract",
        int_codec.encode(hi),
        int_codec.encode(lo),
        exp_codec.encode(exp),
      ]
    Concat(high~, low~) =>
      ["concat", exp_codec.encode(high), exp_codec.encode(low)]
    UnOp(op, nested) =>
      ["unop", project_ir_unop_name(op), exp_codec.encode(nested)]
    BinOp(op, left, right) =>
      [
        "binop",
        project_ir_binop_name(op),
        exp_codec.encode(left),
        exp_codec.encode(right),
      ]
    Ite(cond~, yes~, no~) =>
      [
        "ite",
        exp_codec.encode(cond),
        exp_codec.encode(yes),
        exp_codec.encode(no),
      ]
  }
}

///|
fn project_exp_of_fields(fields : Array[String]) -> Result[@types.Exp, String] {
  let exp_codec = project_exp_persistent()
  let var_codec = project_var_persistent()
  let type_codec = project_value_type_persistent()
  let word_codec = project_ir_word_persistent()
  let int_codec = @knowledge.Persistent::int()
  match fields {
    ["int", word_text] => {
      let word = match word_codec.decode(word_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Int(word))
    }
    ["var", var_text] => {
      let variable = match var_codec.decode(var_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Var(variable))
    }
    ["unknown", name, typ_text] => {
      let typ = match type_codec.decode(typ_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Unknown(name, typ))
    }
    ["load", mem_text, addr_text, endian_text, typ_text] => {
      let mem = match exp_codec.decode(mem_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let addr = match exp_codec.decode(addr_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let endian = match project_read_persistent_endian(endian_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let typ = match type_codec.decode(typ_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Load(mem~, addr~, endian~, typ~))
    }
    ["store", mem_text, addr_text, value_text, endian_text] => {
      let mem = match exp_codec.decode(mem_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let addr = match exp_codec.decode(addr_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let value = match exp_codec.decode(value_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let endian = match project_read_persistent_endian(endian_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Store(mem~, addr~, value~, endian~))
    }
    ["let", var_text, value_text, body_text] => {
      let variable = match var_codec.decode(var_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let value = match exp_codec.decode(value_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let body = match exp_codec.decode(body_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Let(variable, value, body))
    }
    ["cast", kind_text, width_text, exp_text] => {
      let kind = match project_ir_read_cast(kind_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let width = match int_codec.decode(width_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let exp = match exp_codec.decode(exp_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Cast(kind~, width~, exp~))
    }
    ["extract", hi_text, lo_text, exp_text] => {
      let hi = match int_codec.decode(hi_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let lo = match int_codec.decode(lo_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let exp = match exp_codec.decode(exp_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Extract(hi~, lo~, exp~))
    }
    ["concat", high_text, low_text] => {
      let high = match exp_codec.decode(high_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let low = match exp_codec.decode(low_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Concat(high~, low~))
    }
    ["unop", op_text, exp_text] => {
      let op = match project_ir_read_unop(op_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let exp = match exp_codec.decode(exp_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(UnOp(op, exp))
    }
    ["binop", op_text, left_text, right_text] => {
      let op = match project_ir_read_binop(op_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let left = match exp_codec.decode(left_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let right = match exp_codec.decode(right_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(BinOp(op, left, right))
    }
    ["ite", cond_text, yes_text, no_text] => {
      let cond = match exp_codec.decode(cond_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let yes = match exp_codec.decode(yes_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let no = match exp_codec.decode(no_text) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(Ite(cond~, yes~, no~))
    }
    _ => Err("invalid persistent project IR expression")
  }
}

///|
fn project_label_persistent() -> @knowledge.Persistent[@types.Label] {
  let tid_codec = project_ir_tid_persistent()
  let exp_codec = project_exp_persistent()
  @knowledge.Persistent::convert(
    to_persistent=label => {
      match label {
        Direct(tid) => ["direct", tid_codec.encode(tid)]
        Indirect(exp) => ["indirect", exp_codec.encode(exp)]
      }
    },
    of_persistent=fields => {
      match fields {
        ["direct", tid_text] => {
          let tid = match tid_codec.decode(tid_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Direct(tid))
        }
        ["indirect", exp_text] => {
          let exp = match exp_codec.decode(exp_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Indirect(exp))
        }
        _ => Err("invalid persistent project IR label")
      }
    },
    project_ir_fields(),
  )
}

///|
fn project_call_persistent() -> @knowledge.Persistent[@types.Call] {
  let label_codec = project_label_persistent()
  let opt_label_codec = @knowledge.Persistent::optional(label_codec)
  @knowledge.Persistent::convert(
    to_persistent=call => {
      [
        label_codec.encode(call.target),
        opt_label_codec.encode(call.return_label),
      ]
    },
    of_persistent=fields => {
      if fields.length() != 2 {
        return Err("invalid persistent project IR call")
      }
      let target = match label_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let return_label = match opt_label_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Call::create(target~, return_label?))
    },
    project_ir_fields(),
  )
}

///|
fn project_jmp_kind_persistent() -> @knowledge.Persistent[@types.JmpKind] {
  let int_codec = @knowledge.Persistent::int()
  let tid_codec = project_ir_tid_persistent()
  let label_codec = project_label_persistent()
  let call_codec = project_call_persistent()
  @knowledge.Persistent::convert(
    to_persistent=kind => {
      match kind {
        JmpCall(call) => ["call", call_codec.encode(call)]
        Goto(label) => ["goto", label_codec.encode(label)]
        Ret(label) => ["ret", label_codec.encode(label)]
        Interrupt(num, tid) =>
          ["interrupt", int_codec.encode(num), tid_codec.encode(tid)]
      }
    },
    of_persistent=fields => {
      match fields {
        ["call", call_text] => {
          let call = match call_codec.decode(call_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(JmpCall(call))
        }
        ["goto", label_text] => {
          let label = match label_codec.decode(label_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Goto(label))
        }
        ["ret", label_text] => {
          let label = match label_codec.decode(label_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Ret(label))
        }
        ["interrupt", num_text, tid_text] => {
          let num = match int_codec.decode(num_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          let tid = match tid_codec.decode(tid_text) {
            Ok(value) => value
            Err(reason) => return Err(reason)
          }
          Ok(Interrupt(num, tid))
        }
        _ => Err("invalid persistent project IR jump kind")
      }
    },
    project_ir_fields(),
  )
}

///|
fn project_intent_persistent() -> @knowledge.Persistent[@types.Intent] {
  @knowledge.Persistent::create(
    to_string=intent => {
      match intent {
        In => "in"
        Out => "out"
        Both => "both"
      }
    },
    of_string=input => {
      match input {
        "in" => Ok(In)
        "out" => Ok(Out)
        "both" => Ok(Both)
        _ => Err("invalid persistent project IR argument intent")
      }
    },
  )
}

///|
fn project_def_persistent() -> @knowledge.Persistent[@types.Term[@types.Def]] {
  let var_codec = project_var_persistent()
  let exp_codec = project_exp_persistent()
  @knowledge.Persistent::convert(
    to_persistent=def => {
      project_ir_term_fields(
        def,
        project_ir_fields().encode([
          var_codec.encode(def.lhs()),
          exp_codec.encode(def.rhs()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "definition") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 2 {
        return Err("invalid persistent project IR definition")
      }
      let lhs = match var_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let rhs = match exp_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Def::create(lhs, rhs, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}

///|
fn project_phi_value_persistent() -> @knowledge.Persistent[
  (@types.Tid, @types.Exp),
] {
  let tid_codec = project_ir_tid_persistent()
  let exp_codec = project_exp_persistent()
  @knowledge.Persistent::convert(
    to_persistent=value => {
      [tid_codec.encode(value.0), exp_codec.encode(value.1)]
    },
    of_persistent=fields => {
      if fields.length() != 2 {
        return Err("invalid persistent project IR phi value")
      }
      let tid = match tid_codec.decode(fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let exp = match exp_codec.decode(fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok((tid, exp))
    },
    project_ir_fields(),
  )
}

///|
fn project_phi_persistent() -> @knowledge.Persistent[@types.Term[@types.Phi]] {
  let var_codec = project_var_persistent()
  let values_codec = @knowledge.Persistent::array(
    project_phi_value_persistent(),
  )
  @knowledge.Persistent::convert(
    to_persistent=phi => {
      project_ir_term_fields(
        phi,
        project_ir_fields().encode([
          var_codec.encode(phi.phi_lhs()),
          values_codec.encode(phi.values()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "phi") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 2 {
        return Err("invalid persistent project IR phi")
      }
      let lhs = match var_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let values = match values_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Phi::of_list(lhs, values, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}

///|
fn project_jmp_persistent() -> @knowledge.Persistent[@types.Term[@types.Jmp]] {
  let kind_codec = project_jmp_kind_persistent()
  let exp_codec = project_exp_persistent()
  @knowledge.Persistent::convert(
    to_persistent=jmp => {
      project_ir_term_fields(
        jmp,
        project_ir_fields().encode([
          kind_codec.encode(jmp.kind()),
          exp_codec.encode(jmp.cond()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "jump") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 2 {
        return Err("invalid persistent project IR jump")
      }
      let kind = match kind_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let cond = match exp_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Jmp::create(kind, cond~, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}

///|
fn project_arg_persistent() -> @knowledge.Persistent[@types.Term[@types.Arg]] {
  let var_codec = project_var_persistent()
  let exp_codec = project_exp_persistent()
  let intent_codec = @knowledge.Persistent::optional(
    project_intent_persistent(),
  )
  @knowledge.Persistent::convert(
    to_persistent=arg => {
      project_ir_term_fields(
        arg,
        project_ir_fields().encode([
          var_codec.encode(arg.arg_lhs()),
          exp_codec.encode(arg.arg_rhs()),
          intent_codec.encode(arg.intent()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "argument") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 3 {
        return Err("invalid persistent project IR argument")
      }
      let lhs = match var_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let rhs = match exp_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let intent = match intent_codec.decode(payload_fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Arg::create(lhs, rhs, intent?, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}

///|
fn project_blk_persistent() -> @knowledge.Persistent[@types.Term[@types.Blk]] {
  let phis_codec = @knowledge.Persistent::array(project_phi_persistent())
  let defs_codec = @knowledge.Persistent::array(project_def_persistent())
  let jmps_codec = @knowledge.Persistent::array(project_jmp_persistent())
  @knowledge.Persistent::convert(
    to_persistent=blk => {
      project_ir_term_fields(
        blk,
        project_ir_fields().encode([
          phis_codec.encode(blk.phis()),
          defs_codec.encode(blk.defs()),
          jmps_codec.encode(blk.jmps()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "block") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 3 {
        return Err("invalid persistent project IR block")
      }
      let phis = match phis_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let defs = match defs_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let jmps = match jmps_codec.decode(payload_fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Blk::create(phis~, defs~, jmps~, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}

///|
fn project_sub_persistent() -> @knowledge.Persistent[@types.Term[@types.Sub]] {
  let args_codec = @knowledge.Persistent::array(project_arg_persistent())
  let blks_codec = @knowledge.Persistent::array(project_blk_persistent())
  @knowledge.Persistent::convert(
    to_persistent=sub => {
      project_ir_term_fields(
        sub,
        project_ir_fields().encode([
          sub.sub_name(),
          args_codec.encode(sub.args()),
          blks_codec.encode(sub.blks()),
        ]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "subroutine") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 3 {
        return Err("invalid persistent project IR subroutine")
      }
      let args = match args_codec.decode(payload_fields[1]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let blks = match blks_codec.decode(payload_fields[2]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(
        @types.Sub::create(name=payload_fields[0], args~, blks~, tid~).with_attrs(
          attrs,
        ),
      )
    },
    project_ir_fields(),
  )
}

///|
fn project_program_persistent() -> @knowledge.Persistent[
  @types.Term[@types.Program],
] {
  let subs_codec = @knowledge.Persistent::array(project_sub_persistent())
  @knowledge.Persistent::convert(
    to_persistent=program => {
      project_ir_term_fields(
        program,
        project_ir_fields().encode([subs_codec.encode(program.subs())]),
      )
    },
    of_persistent=fields => {
      let (tid, attrs, payload) = match
        project_ir_decode_term_fields(fields, "program") {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      let payload_fields = match project_ir_fields().decode(payload) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      if payload_fields.length() != 1 {
        return Err("invalid persistent project IR program")
      }
      let subs = match subs_codec.decode(payload_fields[0]) {
        Ok(value) => value
        Err(reason) => return Err(reason)
      }
      Ok(@types.Program::create(subs~, tid~).with_attrs(attrs))
    },
    project_ir_fields(),
  )
}
