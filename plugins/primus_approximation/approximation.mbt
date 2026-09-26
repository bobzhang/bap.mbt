// Approximations of elementary functions for Primus Lisp (upstream
// `plugins/primus_approximation/approximation.ml`).
//
// Upstream builds the approximation as a Core Theory floating-point term
// (Remez polynomial evaluated with the Horner scheme, after a range
// reduction to [0, pi] using the oddness of sine), reifies it to BIL and
// evaluates the BIL expression in the Primus interpreter. The port
// evaluates the same polynomial with the host floating-point arithmetic.
// The range reduction uses `x - 2pi * floor(x / 2pi)`; upstream computes
// `x - floor(x / 2pi) / 2pi`, which does not reduce the range.

///|
/// The name of the plugin.
pub let name : String = "primus-approximation"

///|
/// Remez's coefficients for sine over [0, pi] (the constant term first).
let sin_coefficients : Array[Double] = [
  -2.1872506537704514e-10, 1.0000000200128274, -3.0302439009453449e-7, -1.6666487069033565e-1,
  -5.4940340462839474e-6, 8.3432342039387503e-3, -1.1282260464920005e-5, -1.8998652204112551e-4,
  -4.1639895115337191e-6, 4.0918788476303817e-6, -2.6049442541122577e-7,
]

///|
let pi : Double = 4.0 * @math.atan(1.0)

///|
fn horner(coefs : Array[Double], x : Double) -> Double {
  let rank = coefs.length() - 1
  let mut y = coefs[rank]
  for i = rank - 1; i >= 0; i = i - 1 {
    y = x * y + coefs[i]
  }
  y
}

///|
/// The approximation of sine (upstream `Sin.build`).
pub fn approx_sin(x : Double) -> Double {
  let pi2 = 2.0 * pi
  let n = x - pi2 * @math.floor(x / pi2)
  let pn = if n < 0.0 { pi2 + n } else { n }
  let x_m_pi = pn - pi
  let is_pos = x_m_pi > 0.0
  let reduced = if is_pos { x_m_pi } else { pn }
  let p = horner(sin_coefficients, reduced)
  if is_pos {
    -p
  } else {
    p
  }
}

///|
/// The approximation of cosine: `sin(x + pi/2)`.
pub fn approx_cos(x : Double) -> Double {
  approx_sin(x + pi / 2.0)
}

///|
fn to_double(w : @types.Word, size : Int) -> Double {
  if size == 32 {
    let bits = (try! w.truncate(width=32).to_uint64()).to_uint()
    Float::reinterpret_from_uint(bits).to_double()
  } else {
    (try! w.to_int64()).reinterpret_as_double()
  }
}

///|
fn of_double(x : Double, size : Int) -> @types.Word {
  if size == 32 {
    let bits = Float::from_double(x).reinterpret_as_uint()
    try! @types.Word::of_uint64(width=32, bits.to_uint64())
  } else {
    try! @types.Word::of_int64(x.reinterpret_as_int64(), width=64)
  }
}

///|
/// Computes `(approximate NAME SIZE X)`: `NAME` is `sin` or `cos`, `SIZE`
/// is the size of the IEEE754 binary format (32 or 64), and `X` is the
/// bit representation of the argument.
pub fn approximate(
  m : @primus.Machine,
  args : Array[@primus.Value],
) -> @primus.Value raise {
  guard args is [name, size, x] else {
    m.raise_exn(
      @primus.PrimusError::RuntimeError("approximate: expects three arguments"),
    )
  }
  let name = @primus.Value::symbol_of_value(m, name)
  let size = size_of(size)
  let f = match name {
    "sin" | "Sin" => approx_sin
    "cos" | "Cos" => approx_cos
    _ =>
      m.raise_exn(
        @primus.PrimusError::RuntimeError(
          "approximate: unsupported function \{name}",
        ),
      )
  }
  let v = to_double(x.to_word(), size)
  @primus.Value::of_word(m, of_double(f(v), size))
}

///|
fn size_of(v : @primus.Value) -> Int {
  let n = v.to_word().to_int() catch { _ => 64 }
  if n == 32 {
    32
  } else {
    64
  }
}

///|
/// Defines the `approximate` primitive in the Lisp program of the machine
/// (upstream component `Main`).
pub fn install(m : @primus.Machine) -> Unit {
  @primus_lisp.define_host_primitive(
    m,
    "approximate",
    types="(sym int int) -> int",
    docs="(approximate NAME SIZE X) approximates the elementary function NAME (sin or cos) of the floating-point number X of the SIZE bits",
    approximate,
  )
}

///|
let enabled : Ref[Bool] = { val: false, }

///|
/// Adds the component to the legacy main system, as the upstream plugin
/// does. Idempotent.
pub fn enable() -> Unit {
  if !enabled.val {
    enabled.val = true
    @primus.Machine::add_component(m => install(m))
  }
}

///|
/// Declares the plugin in the `bap_main` registry.
pub fn declare_plugin() -> Unit raise {
  if @bap_main.registered_plugins().contains(name) {
    return
  }
  @bap_main.register_plugin(
    name,
    provides=["primus", "lisp", "approximation"],
    doc="provides approximations of elementary functions to Primus Lisp",
    () => @bap_main.Extension::register(_ => enable()),
  )
}
