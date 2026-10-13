// Upstream-compatible BIR printers (`Bap_ir` `pp` functions). Every term
// is prefixed with its identifier and the term attributes are emitted as
// semantic tags `.name value`, so that the `attr` text-tags mode can
// print the attributes selected with `--print-bir-attr`.

///|
fn hex8(n : Int32) -> String {
  let digits = n.to_uint64().to_string(radix=16)
  if digits.length() >= 8 {
    digits
  } else {
    String::make(8 - digits.length(), '0') + digits
  }
}

///|
/// Renders a term identifier like upstream `Tid.to_string` (`%0000002a`).
pub fn tid_to_string(tid : @types.Tid) -> String {
  "%" + hex8(tid.id())
}

///|
/// Renders a term identifier like upstream `Tid.name`: `@name` for named
/// terms, `@interrupt:#n` for interrupt vectors, and `%xxxxxxxx`
/// otherwise.
pub fn tid_name(tid : @types.Tid) -> String {
  match tid.name() {
    Some(name) => "@" + name
    None =>
      match tid.ivec() {
        Some(ivec) => "@interrupt:#\{ivec}"
        None => tid_to_string(tid)
      }
  }
}

///|
fn pp_label(fmt : @text_tags.Formatter, label : @types.Label) -> Unit {
  match label {
    Direct(tid) => fmt.print_string(tid_name(tid))
    Indirect(exp) => pp_exp(fmt, exp)
  }
}

///|
/// Prints a term: opens a semantic tag per attribute, prints the term
/// identifier and the term body (upstream `term_pp`).
fn[T] pp_term(
  fmt : @text_tags.Formatter,
  term : @types.Term[T],
  no_cut~ : Bool = false,
  vertical~ : Bool = false,
  pp_self : () -> Unit,
) -> Unit {
  let attrs = term.attrs()
  for key, value in attrs {
    fmt.open_tag(".\{key} \{value}")
  }
  if vertical {
    fmt.open_vbox(0)
  } else {
    fmt.open_box(10)
  }
  fmt.print_string(hex8(term.tid().id()) + ":")
  if no_cut {
    fmt.print_string(" ")
  } else {
    fmt.print_break(1, 0)
  }
  pp_self()
  fmt.close_box()
  for _ in attrs {
    fmt.close_tag()
  }
}

///|
fn intent_prefix(intent : @types.Intent?) -> String {
  match intent {
    Some(In) => "in "
    Some(Out) => "out "
    Some(Both) => "in out "
    None => ""
  }
}

///|
/// Prints an argument term, e.g., `00000012: x :: in u32 = RDI`.
pub fn pp_arg(
  fmt : @text_tags.Formatter,
  arg : @types.Term[@types.Arg],
) -> Unit {
  pp_term(fmt, arg, () => {
    let lhs = arg.arg_lhs()
    fmt.print_string(
      "\{var_ident(lhs)} :: \{intent_prefix(arg.intent())}\{type_to_string(lhs.typ())} = ",
    )
    pp_exp(fmt, arg.arg_rhs())
  })
}

///|
/// Prints a definition term, e.g., `00000012: RAX := 1`.
pub fn pp_def(
  fmt : @text_tags.Formatter,
  def : @types.Term[@types.Def],
) -> Unit {
  pp_term(fmt, def, () => {
    fmt.print_string(var_ident(def.lhs()))
    fmt.print_format("@ :=@ ")
    pp_exp(fmt, def.rhs())
  })
}

///|
/// Prints a phi-node term, e.g., `00000012: x <- phi([1, %00000010])`.
pub fn pp_phi(
  fmt : @text_tags.Formatter,
  phi : @types.Term[@types.Phi],
) -> Unit {
  pp_term(fmt, phi, () => {
    fmt.print_string(var_ident(phi.phi_lhs()))
    fmt.print_format("@ <-@ ")
    let values = phi
      .values()
      .map(v => "[\{exp_to_string(v.1)}, \{tid_to_string(v.0)}]")
    fmt.print_string("phi(\{values.join(", ")})")
  })
}

///|
fn is_always(cond : @types.Exp) -> Bool {
  cond is Int(w) && w.bitwidth() == 1 && w.is_one()
}

///|
/// Prints a jump term, e.g., `00000012: when ZF goto %00000010`.
pub fn pp_jmp(
  fmt : @text_tags.Formatter,
  jmp : @types.Term[@types.Jmp],
) -> Unit {
  pp_term(fmt, jmp, () => {
    let cond = jmp.cond()
    if !is_always(cond) {
      fmt.print_string("when ")
      pp_exp(fmt, cond)
      fmt.print_string(" ")
    }
    match jmp.kind() {
      Goto(label) => {
        fmt.print_string("goto ")
        pp_label(fmt, label)
      }
      Ret(label) => {
        fmt.print_string("return ")
        pp_label(fmt, label)
      }
      JmpCall(call) => {
        fmt.print_string("call ")
        pp_label(fmt, call.target())
        match call.return_label() {
          Some(label) => {
            fmt.print_string(" with return ")
            pp_label(fmt, label)
          }
          None => fmt.print_string(" with noreturn")
        }
      }
      Interrupt(n, tid) =>
        // upstream prints `%%a` with `Tid.pp`, hence the double percent
        fmt.print_string(
          "interrupt 0x\{n.to_string(radix=16).to_upper()} return %\{tid_to_string(tid)}",
        )
    }
  })
}

///|
fn[T] pp_cut_array(
  fmt : @text_tags.Formatter,
  xs : Array[T],
  pp : (@text_tags.Formatter, T) -> Unit,
) -> Unit {
  for i, x in xs {
    pp(fmt, x)
    if i != xs.length() - 1 {
      fmt.print_cut()
    }
  }
}

///|
/// Prints a block term (upstream `Blk.pp`).
pub fn pp_blk(
  fmt : @text_tags.Formatter,
  blk : @types.Term[@types.Blk],
) -> Unit {
  pp_term(fmt, blk, vertical=true, () => {
    let phis = blk.phis()
    let defs = blk.defs()
    let jmps = blk.jmps()
    pp_cut_array(fmt, phis, pp_phi)
    if (phis.length() != 0 && defs.length() != 0) ||
      (phis.length() != 0 && defs.length() == 0 && jmps.length() != 0) {
      fmt.print_cut()
    }
    pp_cut_array(fmt, defs, pp_def)
    if defs.length() != 0 && jmps.length() != 0 {
      fmt.print_cut()
    }
    pp_cut_array(fmt, jmps, pp_jmp)
  })
}

///|
/// Prints a subroutine term (upstream `Sub.pp`).
pub fn pp_sub(
  fmt : @text_tags.Formatter,
  sub : @types.Term[@types.Sub],
) -> Unit {
  pp_term(fmt, sub, no_cut=true, vertical=true, () => {
    let args = sub.args()
    let names = args.map(arg => var_ident(arg.arg_lhs()))
    fmt.print_string("sub \{sub.sub_name()}(\{names.join(", ")})")
    fmt.print_format("@;")
    pp_cut_array(fmt, args, pp_arg)
    fmt.print_format("@;")
    for blk in sub.blks() {
      fmt.print_format("@;")
      pp_blk(fmt, blk)
      fmt.print_format("@;")
    }
  })
}

///|
/// Prints a program term (upstream `Program.pp`).
pub fn pp_program(
  fmt : @text_tags.Formatter,
  program : @types.Term[@types.Program],
) -> Unit {
  pp_term(fmt, program, no_cut=true, vertical=true, () => {
    fmt.print_string("program")
    fmt.print_format("@;")
    pp_cut_array(fmt, program.subs(), pp_sub)
  })
}

///|
/// Prints any IR term with the upstream printer of its class.
pub fn pp_ir_term(fmt : @text_tags.Formatter, term : @types.IrTerm) -> Unit {
  match term {
    ProgramTerm(t) => pp_program(fmt, t)
    SubTerm(t) => pp_sub(fmt, t)
    ArgTerm(t) => pp_arg(fmt, t)
    BlkTerm(t) => pp_blk(fmt, t)
    PhiTerm(t) => pp_phi(fmt, t)
    DefTerm(t) => pp_def(fmt, t)
    JmpTerm(t) => pp_jmp(fmt, t)
  }
}

///|
/// Renders an IR term in the upstream BIR syntax, in the `attr` text-tags
/// mode, i.e., the attributes enabled with `@text_tags.attr_show` are
/// printed before the terms that carry them.
pub fn ir_term_to_string(term : @types.IrTerm) -> String {
  let fmt = @text_tags.Formatter::new()
  @text_tags.with_mode(fmt, "attr", () => pp_ir_term(fmt, term)) catch {
    _ => pp_ir_term(fmt, term)
  }
  fmt.flush_str()
}

///|
/// Renders a program in the upstream BIR syntax (see `ir_term_to_string`).
pub fn program_to_string(program : @types.Term[@types.Program]) -> String {
  ir_term_to_string(ProgramTerm(program))
}
