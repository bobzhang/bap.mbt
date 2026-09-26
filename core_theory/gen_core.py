"""Generates the Core Theory record, its accessor methods, the Empty theory
and the theory join for core_theory (see bap_core_theory_definition.ml,
bap_core_theory_empty.ml and bap_core_theory_manager.ml upstream)."""
import os
import re
import sys

TY = {
    "P": "Pure", "E": "Eff", "S": "Sort", "W": "@bitvec.BitVec", "V": "Var",
    "L": "Label", "ES": "EffectSort", "I": "Int", "PA": "Array[Pure]",
}

# (group, name, [(param, kind)], result kind, empty rule, doc)
OPS = []


def op(group, name, params, res, empty, doc):
    ps = []
    for p in params.split():
        n, k = p.split(":")
        ps.append((n, k))
    OPS.append((group, name, ps, res, empty, doc))


# Init
op("Init", "var_", "v:V", "P", "var", "`var v` is the value of the variable `v` (upstream `var`).")
op("Init", "unk", "s:S", "P", "s", "`unk s` is an unknown value of sort `s`.")
op("Init", "let_", "v:V x:P body:P", "P", ("arg", "body"), "`let_ v x body` binds the value of `x` to `v` in `body`.")
op("Init", "ite", "c:P x:P y:P", "P", ("arg", "x"), "`ite c x y` is `x` if `c` evaluates to `b1`, else `y`.")
# Bool
op("Bool", "b0", "", "P", "bool", "`b0` is false (the zero bit).")
op("Bool", "b1", "", "P", "bool", "`b1` is true (the one bit).")
op("Bool", "inv", "x:P", "P", "bool", "`inv x` inverts `x`.")
op("Bool", "and_", "x:P y:P", "P", "bool", "`and_ x y` is the conjunction of `x` and `y`.")
op("Bool", "or_", "x:P y:P", "P", "bool", "`or_ x y` is the disjunction of `x` and `y`.")
# Bitv
op("Bitv", "int", "s:S x:W", "P", "s", "`int s x` is the bitvector constant `x` of sort `s`.")
op("Bitv", "msb", "x:P", "P", "bool", "`msb x` is the most significant bit of `x`.")
op("Bitv", "lsb", "x:P", "P", "bool", "`lsb x` is the least significant bit of `x`.")
op("Bitv", "neg", "x:P", "P", ("arg", "x"), "`neg x` is the two-complement unary minus.")
op("Bitv", "not", "x:P", "P", ("arg", "x"), "`not x` is the one-complement negation.")
for n, d in [("add", "addition"), ("sub", "subtraction"), ("mul", "multiplication"),
             ("div", "unsigned division (division by zero is all ones)"),
             ("sdiv", "signed division"), ("modulo", "unsigned remainder"),
             ("smodulo", "signed remainder (the sign follows the dividend)"),
             ("logand", "bitwise and"), ("logor", "bitwise or"), ("logxor", "bitwise xor")]:
    op("Bitv", n, "x:P y:P", "P", ("arg", "x"), f"`{n} x y` is the {d} modulo `2^size`.")
op("Bitv", "shiftr", "fill:P x:P m:P", "P", ("arg", "x"), "`shiftr fill x m` shifts `x` right by `m` bits filling with `fill`.")
op("Bitv", "shiftl", "fill:P x:P m:P", "P", ("arg", "x"), "`shiftl fill x m` shifts `x` left by `m` bits filling with `fill`.")
op("Bitv", "sle", "x:P y:P", "P", "bool", "`sle x y` is the signed less than or equal predicate.")
op("Bitv", "ule", "x:P y:P", "P", "bool", "`ule x y` is the unsigned less than or equal predicate.")
op("Bitv", "cast", "s:S fill:P x:P", "P", "s", "`cast s fill x` casts `x` to sort `s`, prepending bits `fill` when widening.")
op("Bitv", "concat", "s:S xs:PA", "P", "s", "`concat s xs` concatenates `xs` (the first is the most significant) and casts the result to `s`.")
op("Bitv", "append", "s:S x:P y:P", "P", "s", "`append s x y` puts `x` in the most significant part, `y` in the least, and casts to `s`.")
# Memory
op("Memory", "load", "mem:P key:P", "P", "vals", "`load mem key` is the value associated with `key` in `mem`.")
op("Memory", "store", "mem:P key:P x:P", "P", ("arg", "mem"), "`store mem key x` is `mem` with `key` associated with `x`.")
# Effect
op("Effect", "perform", "s:ES", "E", "perform", "`perform s` performs a generic effect of sort `s`.")
op("Effect", "set", "v:V x:P", "E", "bot", "`set v x` stores the value of `x` in the variable `v`.")
op("Effect", "jmp", "dst:P", "E", "bot", "`jmp dst` passes the control to the program located at `dst`.")
op("Effect", "goto", "lbl:L", "E", "bot", "`goto lbl` passes the control to the program labeled with `lbl`.")
op("Effect", "seq", "x:E y:E", "E", ("earg", "x"), "`seq x y` performs `x`, then `y`.")
op("Effect", "blk", "lbl:L data:E ctrl:E", "E", "bot", "`blk lbl data ctrl` is an (optionally labeled, see `Label::null`) block of effects.")
op("Effect", "repeat", "c:P body:E", "E", "bot", "`repeat c body` repeats `body` while `c` holds.")
op("Effect", "branch", "c:P x:E y:E", "E", ("earg", "x"), "`branch c x y` performs `x` if `c` holds, else `y`.")
# Basic
op("Basic", "zero", "s:S", "P", "s", "`zero s` is the zero bitvector of sort `s`.")
op("Basic", "is_zero", "x:P", "P", "bool", "`is_zero x` holds if `x` is zero.")
op("Basic", "non_zero", "x:P", "P", "bool", "`non_zero x` holds if `x` is not zero.")
op("Basic", "succ", "x:P", "P", ("arg", "x"), "`succ x` is `x + 1`.")
op("Basic", "pred", "x:P", "P", ("arg", "x"), "`pred x` is `x - 1`.")
op("Basic", "nsucc", "x:P n:I", "P", ("arg", "x"), "`nsucc x n` is `x + n`.")
op("Basic", "npred", "x:P n:I", "P", ("arg", "x"), "`npred x n` is `x - n`.")
op("Basic", "high", "s:S x:P", "P", "s", "`high s x` is the `size s` most significant bits of `x`.")
op("Basic", "low", "s:S x:P", "P", "s", "`low s x` is the `size s` least significant bits of `x`.")
op("Basic", "signed", "s:S x:P", "P", "s", "`signed s x` casts `x` to `s` with sign extension.")
op("Basic", "unsigned", "s:S x:P", "P", "s", "`unsigned s x` casts `x` to `s` with zero extension.")
op("Basic", "extract", "s:S hi:P lo:P x:P", "P", "s", "`extract s hi lo x` is the bits `hi..lo` of `x` casted to `s`.")
op("Basic", "loadw", "s:S dir:P mem:P key:P", "P", "s", "`loadw s dir mem key` loads a word of sort `s` (big endian if `dir` holds).")
op("Basic", "storew", "dir:P mem:P key:P x:P", "P", ("arg", "mem"), "`storew dir mem key x` stores the word `x` (big endian if `dir` holds).")
op("Basic", "arshift", "x:P m:P", "P", ("arg", "x"), "`arshift x m` is the arithmetic right shift.")
op("Basic", "rshift", "x:P m:P", "P", ("arg", "x"), "`rshift x m` is the logical right shift.")
op("Basic", "lshift", "x:P m:P", "P", ("arg", "x"), "`lshift x m` is the left shift.")
for n, d in [("eq", "equality"), ("neq", "disequality"), ("slt", "signed less than"),
             ("ult", "unsigned less than"), ("sgt", "signed greater than"),
             ("ugt", "unsigned greater than"), ("sge", "signed greater or equal"),
             ("uge", "unsigned greater or equal")]:
    op("Basic", n, "x:P y:P", "P", "bool", f"`{n} x y` is the {d} predicate.")
# Fbasic
op("Fbasic", "float", "s:S x:P", "P", "s", "`float s x` interprets the bitvector `x` as a float of sort `s`.")
op("Fbasic", "fbits", "x:P", "P", "fbits", "`fbits x` is the bitvector representation of the float `x`.")
for n, d in [("is_finite", "finite"), ("is_nan", "not a number"), ("is_inf", "an infinity"),
             ("is_fzero", "a zero"), ("is_fpos", "positive"), ("is_fneg", "negative")]:
    op("Fbasic", n, "x:P", "P", "bool", f"`{n} x` holds if `x` is {d}.")
for n, d in [("rne", "round to nearest, ties to even"), ("rna", "round to nearest, ties away"),
             ("rtp", "round towards positive"), ("rtn", "round towards negative"),
             ("rtz", "round towards zero")]:
    op("Fbasic", n, "", "P", "rmode", f"`{n}`: {d}.")
op("Fbasic", "requal", "x:P y:P", "P", "bool", "`requal x y` holds if the rounding modes are equal.")
op("Fbasic", "cast_float", "s:S rm:P x:P", "P", "s", "`cast_float s rm x` is the unsigned integer `x` as a float of sort `s`.")
op("Fbasic", "cast_sfloat", "s:S rm:P x:P", "P", "s", "`cast_sfloat s rm x` is the signed integer `x` as a float of sort `s`.")
op("Fbasic", "cast_int", "s:S rm:P x:P", "P", "s", "`cast_int s rm x` is the float `x` as an unsigned integer of sort `s`.")
op("Fbasic", "cast_sint", "s:S rm:P x:P", "P", "s", "`cast_sint s rm x` is the float `x` as a signed integer of sort `s`.")
op("Fbasic", "fneg", "x:P", "P", ("arg", "x"), "`fneg x` is `-x`.")
op("Fbasic", "fabs", "x:P", "P", ("arg", "x"), "`fabs x` is the absolute value of `x`.")
for n in ["fadd", "fsub", "fmul", "fdiv"]:
    op("Fbasic", n, "rm:P x:P y:P", "P", ("arg", "x"), f"`{n} rm x y` is the floating-point {n[1:]} rounded with `rm`.")
op("Fbasic", "fsqrt", "rm:P x:P", "P", ("arg", "x"), "`fsqrt rm x` is the square root of `x`.")
op("Fbasic", "fmodulo", "rm:P x:P y:P", "P", ("arg", "x"), "`fmodulo rm x y` is the floating-point remainder.")
op("Fbasic", "fmad", "rm:P x:P y:P z:P", "P", ("arg", "x"), "`fmad rm x y z` is `x * y + z` rounded once.")
op("Fbasic", "fround", "rm:P x:P", "P", ("arg", "x"), "`fround rm x` rounds `x` to an integral float.")
op("Fbasic", "fconvert", "s:S rm:P x:P", "P", "s", "`fconvert s rm x` converts the float `x` to the float sort `s`.")
op("Fbasic", "fsucc", "x:P", "P", ("arg", "x"), "`fsucc x` is the least float greater than `x`.")
op("Fbasic", "fpred", "x:P", "P", ("arg", "x"), "`fpred x` is the greatest float less than `x`.")
op("Fbasic", "forder", "x:P y:P", "P", "bool", "`forder x y` holds if `x` is strictly less than `y`.")
# Float
for n in ["pow", "compound", "rootn", "pown", "hypot"]:
    op("Float", n, "rm:P x:P y:P", "P", ("arg", "x"), f"`{n} rm x y`.")
op("Float", "rsqrt", "rm:P x:P", "P", ("arg", "x"), "`rsqrt rm x` is `1 / sqrt x`.")
# Trans
for n in ["exp", "expm1", "exp2", "exp2m1", "exp10", "exp10m1", "log", "log2", "log10",
          "logp1", "log2p1", "log10p1", "sin", "cos", "tan", "sinpi", "cospi", "atanpi"]:
    op("Trans", n, "rm:P x:P", "P", ("arg", "x"), f"`{n} rm x`.")
op("Trans", "atan2pi", "rm:P x:P y:P", "P", ("arg", "x"), "`atan2pi rm x y`.")
for n in ["asin", "acos", "atan"]:
    op("Trans", n, "rm:P x:P", "P", ("arg", "x"), f"`{n} rm x`.")
op("Trans", "atan2", "rm:P x:P y:P", "P", ("arg", "x"), "`atan2 rm x y`.")
for n in ["sinh", "cosh", "tanh", "asinh", "acosh", "atanh"]:
    op("Trans", n, "rm:P x:P", "P", ("arg", "x"), f"`{n} rm x`.")

GROUP_DOC = {
    "Init": "The initial theory (`Init`).",
    "Bool": "The theory of booleans (`Bool`).",
    "Bitv": "The theory of bitvectors (`Bitv`).",
    "Memory": "The theory of memories (`Memory`).",
    "Effect": "The theory of effects (`Effect`).",
    "Basic": "The Basic theory of bitvector machines (`Basic`), derivable from the Minimal theory with `Core::basic`.",
    "Fbasic": "The basic theory of floating points (`Fbasic`).",
    "Float": "The theory of floating points (`Float`).",
    "Trans": "The theory of transcendental functions (`Trans`).",
}


def field_type(ps, res):
    if not ps:
        return TY[res]
    return "(" + ", ".join(TY[k] for _, k in ps) + ") -> " + TY[res]


def gen_core():
    out = []
    out.append("""// Generated by gen_core.py from the upstream Core signatures
// (bap_core_theory_definition.ml); edit the generator, not this file.

///|
/// A term of the theory (`'a pure = 'a value knowledge`): a knowledge
/// computation that evaluates to a value. Terms are not evaluated until
/// they are applied to the knowledge base state, so that a theory can
/// decide which subterms to evaluate (and how many times).
pub type Pure = (@knowledge.State) -> Value raise

///|
/// An effectful term of the theory (`'a eff = 'a effect knowledge`).
pub type Eff = (@knowledge.State) -> Effect raise

///|
/// An instance of the Core Theory (`module type Core`): a record of the
/// denotations of all Core Theory operations.
///
/// The record includes the `Init`, `Bool`, `Bitv`, `Memory` and `Effect`
/// signatures (together the `Minimal` theory), the `Basic` theory, the
/// floating-point theories `Fbasic` and `Float` and the transcendental
/// theory `Trans`. Sorts are not statically indexed in the port: each
/// term carries its sort at run time (`Value::sort`).
///
/// A theory is usually written as an update of an existing one, e.g.,
/// `{ ..Core::empty(), add: ..., sub: ... }` (the analog of `include
/// Theory.Empty`), or derived from a minimal one with `Core::basic`.
/// Operations are called with the methods of the same name
/// (`core.add(x, y)`); the fields are exposed for record updates.
pub(all) struct Core {""")
    group = None
    for g, n, ps, res, _, doc in OPS:
        if g != group:
            out.append(f"  // {GROUP_DOC[g]}")
            group = g
        out.append(f"  /// {doc}")
        out.append(f"  {n} : {field_type(ps, res)}")
    out.append("}\n")
    for g, n, ps, res, _, doc in OPS:
        params = "".join(f", {p} : {TY[k]}" for p, k in ps)
        call = f"(self.{n})(" + ", ".join(p for p, _ in ps) + ")" if ps else f"self.{n}"
        out.append("///|")
        out.append(f"/// {doc}")
        out.append(f"pub fn Core::{n}(self : Core{params}) -> {TY[res]} {{\n  {call}\n}}\n")
    return "\n".join(out)


def empty_body(n, ps, res, rule):
    names = [p for p, _ in ps]
    if rule == "bool":
        body = "_ => Value::empty(Sort::bool())"
    elif rule == "rmode":
        body = "_ => Value::empty(Sort::rmode())"
    elif rule == "s":
        body = "_ => Value::empty(s)"
    elif rule == "var":
        body = "_ => Value::empty(v.sort())"
    elif rule == "vals":
        body = "state => Value::empty(sort_mem_values(mem(state).sort()))"
    elif rule == "fbits":
        body = "state => Value::empty(sort_float_bits(x(state).sort()))"
    elif rule == "bot":
        body = "_ => Effect::empty(EffectSort::bot())"
    elif rule == "perform":
        body = "_ => Effect::empty(s)"
    elif rule[0] == "arg":
        body = f"state => Value::empty({rule[1]}(state).sort())"
    elif rule[0] == "earg":
        body = f"state => Effect::empty({rule[1]}(state).sort())"
    else:
        raise Exception(rule)
    if not ps:
        return body
    args = ", ".join(p if re.search(r"\b" + p + r"\b", body) else "_" for p in names)
    return f"({args}) => {body}"


def gen_empty():
    out = ["""// Generated by gen_core.py from bap_core_theory_empty.ml; edit the
// generator, not this file.

///|
/// `Theory.Empty`: the theory in which every operation denotes the empty
/// value of the right sort (the sort of the result is computed from the
/// sorts of the arguments, which are evaluated when needed).
///
/// The empty theory is the base of all theories: a theory that provides
/// only some operations is written as `{ ..Core::empty(), ... }`.
pub fn Core::empty() -> Core {
  empty_core
}

///|
let empty_core : Core = {"""]
    for g, n, ps, res, rule, _ in OPS:
        out.append(f"  {n}: {empty_body(n, ps, res, rule)},")
    out.append("}\n")
    return "\n".join(out)


def gen_join():
    out = ["""// Generated by gen_core.py from `Join` in bap_core_theory_manager.ml;
// edit the generator, not this file.

///|
/// `Theory.join`: the join of two theories (upstream `Join(P)(Q)`).
///
/// Every operation of the joined theory evaluates its term arguments
/// once, applies the operations of both theories to the (constant)
/// results and merges the two denotations (`KB.Value.merge`), so that the
/// properties provided by different theories are joined in one value of
/// the sort computed by `self`.
pub fn Core::join(self : Core, other : Core) -> Core {
  let p = self
  let q = other
  {"""]
    for g, n, ps, res, _, _ in OPS:
        thunks = [(p, k) for p, k in ps if k in ("P", "E", "PA")]
        if not ps:
            out.append(f"    {n}: state => (p.{n})(state).merge((q.{n})(state)),")
            continue
        args = ", ".join(p for p, _ in ps)
        lines = []
        for p_, k in thunks:
            if k == "PA":
                lines.append(f"let {p_} = {p_}.map(x => pure_const(x(state)))")
            elif k == "P":
                lines.append(f"let {p_} = pure_const({p_}(state))")
            else:
                lines.append(f"let {p_} = eff_const({p_}(state))")
        lines.append(f"(p.{n})({args})(state).merge((q.{n})({args})(state))")
        inner = "\n        ".join(lines)
        out.append(f"    {n}: ({args}) => state => {{\n        {inner}\n      }},")
    out.append("  }\n}\n")
    return "\n".join(out)


def main(root):
    open(f"{root}/theory_core.mbt", "w").write(gen_core())
    open(f"{root}/theory_empty.mbt", "w").write(gen_empty())
    open(f"{root}/theory_join.mbt", "w").write(gen_join())


main(sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__)))
