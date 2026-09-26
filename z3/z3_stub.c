/* A binding to the subset of the Z3 C API used by the Primus symbolic
   executor (bitvector and boolean terms, solvers and models).

   The Z3 library is loaded at run time with dlopen (LoadLibrary on
   Windows) instead of being linked, so that packages depending on this
   binding build and run on hosts without Z3: every entry point reports
   that the solver is unavailable until a library is loaded. The library
   is searched, in order, at

   - the path given to `bap_z3_load` (the MoonBit `@z3.load_library`);
   - the path in the `BAP_Z3_LIBRARY` environment variable;
   - the platform defaults (`libz3.dylib`/`libz3.so` on the dynamic
     linker path, then the Homebrew and /usr/local locations).

   The Z3 declarations below mirror `z3_api.h` (4.x); the header itself is
   not needed to build the stub.

   Contexts are reference-counting contexts (`Z3_mk_context_rc`). Every
   term, solver, model and parameter set is wrapped in a MoonBit external
   object that holds a Z3 reference and a MoonBit reference to its
   context object, so a context is deleted only after all objects created
   in it are released. Errors never abort: the context error handler is a
   no-op and the MoonBit side reads the error code after each call. */

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include <moonbit.h>

typedef void *Z3_config;
typedef void *Z3_context;
typedef void *Z3_ast;
typedef void *Z3_sort;
typedef void *Z3_symbol;
typedef void *Z3_solver;
typedef void *Z3_model;
typedef void *Z3_params;
typedef const char *Z3_string;
typedef int Z3_lbool;
typedef int Z3_error_code;
typedef void (*Z3_error_handler)(Z3_context, Z3_error_code);

#define BAP_Z3_FUNCTIONS(X)                                                   \
  X(Z3_config, Z3_mk_config, (void))                                          \
  X(void, Z3_del_config, (Z3_config))                                         \
  X(void, Z3_set_param_value, (Z3_config, Z3_string, Z3_string))              \
  X(Z3_context, Z3_mk_context_rc, (Z3_config))                                \
  X(void, Z3_del_context, (Z3_context))                                       \
  X(void, Z3_update_param_value, (Z3_context, Z3_string, Z3_string))          \
  X(void, Z3_set_error_handler, (Z3_context, Z3_error_handler))               \
  X(Z3_error_code, Z3_get_error_code, (Z3_context))                           \
  X(Z3_string, Z3_get_error_msg, (Z3_context, Z3_error_code))                 \
  X(void, Z3_get_version, (unsigned *, unsigned *, unsigned *, unsigned *))   \
  X(void, Z3_inc_ref, (Z3_context, Z3_ast))                                   \
  X(void, Z3_dec_ref, (Z3_context, Z3_ast))                                   \
  X(Z3_sort, Z3_mk_bool_sort, (Z3_context))                                   \
  X(Z3_sort, Z3_mk_bv_sort, (Z3_context, unsigned))                           \
  X(Z3_symbol, Z3_mk_string_symbol, (Z3_context, Z3_string))                  \
  X(Z3_ast, Z3_mk_const, (Z3_context, Z3_symbol, Z3_sort))                    \
  X(Z3_ast, Z3_mk_numeral, (Z3_context, Z3_string, Z3_sort))                  \
  X(Z3_ast, Z3_mk_true, (Z3_context))                                         \
  X(Z3_ast, Z3_mk_false, (Z3_context))                                        \
  X(Z3_ast, Z3_mk_bvadd, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvsub, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvmul, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvudiv, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvsdiv, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvurem, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvsrem, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvsmod, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvand, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvor, (Z3_context, Z3_ast, Z3_ast))                         \
  X(Z3_ast, Z3_mk_bvxor, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvshl, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvlshr, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvashr, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_concat, (Z3_context, Z3_ast, Z3_ast))                       \
  X(Z3_ast, Z3_mk_bvult, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvule, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvugt, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvuge, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvslt, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvsle, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvsgt, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_bvsge, (Z3_context, Z3_ast, Z3_ast))                        \
  X(Z3_ast, Z3_mk_eq, (Z3_context, Z3_ast, Z3_ast))                           \
  X(Z3_ast, Z3_mk_implies, (Z3_context, Z3_ast, Z3_ast))                      \
  X(Z3_ast, Z3_mk_iff, (Z3_context, Z3_ast, Z3_ast))                          \
  X(Z3_ast, Z3_mk_xor, (Z3_context, Z3_ast, Z3_ast))                          \
  X(Z3_ast, Z3_mk_and, (Z3_context, unsigned, Z3_ast const *))                \
  X(Z3_ast, Z3_mk_or, (Z3_context, unsigned, Z3_ast const *))                 \
  X(Z3_ast, Z3_mk_distinct, (Z3_context, unsigned, Z3_ast const *))           \
  X(Z3_ast, Z3_mk_bvnot, (Z3_context, Z3_ast))                                \
  X(Z3_ast, Z3_mk_bvneg, (Z3_context, Z3_ast))                                \
  X(Z3_ast, Z3_mk_bvredor, (Z3_context, Z3_ast))                              \
  X(Z3_ast, Z3_mk_bvredand, (Z3_context, Z3_ast))                             \
  X(Z3_ast, Z3_mk_not, (Z3_context, Z3_ast))                                  \
  X(Z3_ast, Z3_mk_extract, (Z3_context, unsigned, unsigned, Z3_ast))          \
  X(Z3_ast, Z3_mk_zero_ext, (Z3_context, unsigned, Z3_ast))                   \
  X(Z3_ast, Z3_mk_sign_ext, (Z3_context, unsigned, Z3_ast))                   \
  X(Z3_ast, Z3_mk_rotate_left, (Z3_context, unsigned, Z3_ast))                \
  X(Z3_ast, Z3_mk_rotate_right, (Z3_context, unsigned, Z3_ast))               \
  X(Z3_ast, Z3_mk_ite, (Z3_context, Z3_ast, Z3_ast, Z3_ast))                  \
  X(Z3_ast, Z3_simplify, (Z3_context, Z3_ast))                                \
  X(Z3_sort, Z3_get_sort, (Z3_context, Z3_ast))                               \
  X(int, Z3_get_sort_kind, (Z3_context, Z3_sort))                             \
  X(unsigned, Z3_get_bv_sort_size, (Z3_context, Z3_sort))                     \
  X(bool, Z3_is_numeral_ast, (Z3_context, Z3_ast))                            \
  X(Z3_string, Z3_get_numeral_string, (Z3_context, Z3_ast))                   \
  X(Z3_lbool, Z3_get_bool_value, (Z3_context, Z3_ast))                        \
  X(Z3_string, Z3_ast_to_string, (Z3_context, Z3_ast))                        \
  X(unsigned, Z3_get_ast_id, (Z3_context, Z3_ast))                            \
  X(unsigned, Z3_get_ast_hash, (Z3_context, Z3_ast))                          \
  X(bool, Z3_is_eq_ast, (Z3_context, Z3_ast, Z3_ast))                         \
  X(Z3_params, Z3_mk_params, (Z3_context))                                    \
  X(void, Z3_params_inc_ref, (Z3_context, Z3_params))                         \
  X(void, Z3_params_dec_ref, (Z3_context, Z3_params))                         \
  X(void, Z3_params_set_uint, (Z3_context, Z3_params, Z3_symbol, unsigned))   \
  X(void, Z3_params_set_bool, (Z3_context, Z3_params, Z3_symbol, bool))       \
  X(Z3_solver, Z3_mk_solver, (Z3_context))                                    \
  X(Z3_solver, Z3_mk_simple_solver, (Z3_context))                             \
  X(void, Z3_solver_inc_ref, (Z3_context, Z3_solver))                         \
  X(void, Z3_solver_dec_ref, (Z3_context, Z3_solver))                         \
  X(void, Z3_solver_set_params, (Z3_context, Z3_solver, Z3_params))           \
  X(void, Z3_solver_push, (Z3_context, Z3_solver))                            \
  X(void, Z3_solver_pop, (Z3_context, Z3_solver, unsigned))                   \
  X(void, Z3_solver_reset, (Z3_context, Z3_solver))                           \
  X(unsigned, Z3_solver_get_num_scopes, (Z3_context, Z3_solver))              \
  X(void, Z3_solver_assert, (Z3_context, Z3_solver, Z3_ast))                  \
  X(Z3_lbool, Z3_solver_check, (Z3_context, Z3_solver))                       \
  X(Z3_model, Z3_solver_get_model, (Z3_context, Z3_solver))                   \
  X(Z3_string, Z3_solver_get_reason_unknown, (Z3_context, Z3_solver))         \
  X(Z3_string, Z3_solver_to_string, (Z3_context, Z3_solver))                  \
  X(void, Z3_model_inc_ref, (Z3_context, Z3_model))                           \
  X(void, Z3_model_dec_ref, (Z3_context, Z3_model))                           \
  X(bool, Z3_model_eval, (Z3_context, Z3_model, Z3_ast, bool, Z3_ast *))      \
  X(Z3_string, Z3_model_to_string, (Z3_context, Z3_model))

#define BAP_Z3_DECLARE(ret, name, args) static ret(*p_##name) args;
BAP_Z3_FUNCTIONS(BAP_Z3_DECLARE)

static void *bap_z3_handle = NULL;
static char bap_z3_load_error[1024] = "the Z3 library is not loaded";
static int bap_z3_tried_defaults = 0;

static void *bap_z3_open(const char *path) {
#ifdef _WIN32
  return (void *)LoadLibraryA(path);
#else
  return dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
}

static void *bap_z3_sym(void *handle, const char *name) {
#ifdef _WIN32
  return (void *)GetProcAddress((HMODULE)handle, name);
#else
  return dlsym(handle, name);
#endif
}

static void bap_z3_close(void *handle) {
#ifdef _WIN32
  FreeLibrary((HMODULE)handle);
#else
  dlclose(handle);
#endif
}

/* Loads the library at `path` and resolves all entry points. Returns 1 on
   success; on failure records the reason in `bap_z3_load_error`. */
static int bap_z3_try(const char *path) {
  void *h = bap_z3_open(path);
  if (h == NULL) {
#ifdef _WIN32
    snprintf(bap_z3_load_error, sizeof(bap_z3_load_error),
             "unable to load %s", path);
#else
    const char *e = dlerror();
    snprintf(bap_z3_load_error, sizeof(bap_z3_load_error), "%s",
             e ? e : path);
#endif
    return 0;
  }
#define BAP_Z3_RESOLVE(ret, name, args)                                       \
  p_##name = (ret(*) args)bap_z3_sym(h, #name);                              \
  if (p_##name == NULL) {                                                     \
    snprintf(bap_z3_load_error, sizeof(bap_z3_load_error),                    \
             "%s: missing symbol %s", path, #name);                          \
    bap_z3_close(h);                                                          \
    return 0;                                                                 \
  }
  BAP_Z3_FUNCTIONS(BAP_Z3_RESOLVE)
  bap_z3_handle = h;
  bap_z3_load_error[0] = '\0';
  return 1;
}

static const char *bap_z3_default_paths[] = {
#if defined(__APPLE__)
  "libz3.dylib",
  "/opt/homebrew/opt/z3/lib/libz3.dylib",
  "/opt/homebrew/lib/libz3.dylib",
  "/usr/local/opt/z3/lib/libz3.dylib",
  "/usr/local/lib/libz3.dylib",
#elif defined(_WIN32)
  "libz3.dll",
  "z3.dll",
#else
  "libz3.so",
  "libz3.so.4",
  "/usr/local/lib/libz3.so",
  "/usr/lib/x86_64-linux-gnu/libz3.so.4",
  "/usr/lib/aarch64-linux-gnu/libz3.so.4",
  "/usr/lib64/libz3.so",
#endif
  NULL
};

static int bap_z3_ensure(void) {
  if (bap_z3_handle != NULL) return 1;
  if (bap_z3_tried_defaults) return 0;
  bap_z3_tried_defaults = 1;
  const char *env = getenv("BAP_Z3_LIBRARY");
  if (env != NULL && env[0] != '\0') {
    return bap_z3_try(env);
  }
  char first[1024] = "";
  for (int i = 0; bap_z3_default_paths[i] != NULL; i++) {
    if (bap_z3_try(bap_z3_default_paths[i])) return 1;
    if (first[0] == '\0') {
      snprintf(first, sizeof(first), "%s", bap_z3_load_error);
    }
  }
  snprintf(bap_z3_load_error, sizeof(bap_z3_load_error),
           "the Z3 library was not found (set BAP_Z3_LIBRARY): %s", first);
  return 0;
}

static moonbit_bytes_t bap_z3_bytes(const char *s) {
  if (s == NULL) s = "";
  int32_t len = (int32_t)strlen(s);
  moonbit_bytes_t out = moonbit_make_bytes(len, 0);
  memcpy(out, s, (size_t)len);
  return out;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_available(void) {
  return bap_z3_ensure();
}

/* Loads the library from an explicit path (replacing none if one is
   already loaded). Returns an empty string on success. */
MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_load(moonbit_bytes_t path) {
  if (bap_z3_handle != NULL) return bap_z3_bytes("");
  if (bap_z3_try((const char *)path)) return bap_z3_bytes("");
  return bap_z3_bytes(bap_z3_load_error);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_load_error_message(void) {
  return bap_z3_bytes(bap_z3_load_error);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_version(void) {
  if (!bap_z3_ensure()) return bap_z3_bytes("");
  unsigned a = 0, b = 0, c = 0, d = 0;
  p_Z3_get_version(&a, &b, &c, &d);
  char buf[64];
  snprintf(buf, sizeof(buf), "%u.%u.%u.%u", a, b, c, d);
  return bap_z3_bytes(buf);
}

/* ---------------------------------------------------------------------- */
/* Contexts                                                                */

typedef struct {
  Z3_context ctx;
} bap_z3_ctx;

static void bap_z3_ctx_finalize(void *self) {
  bap_z3_ctx *c = (bap_z3_ctx *)self;
  if (c->ctx != NULL) {
    p_Z3_del_context(c->ctx);
    c->ctx = NULL;
  }
}

static void bap_z3_ignore_error(Z3_context c, Z3_error_code e) {
  (void)c;
  (void)e;
}

/* Creates a context from a configuration given as a string of
   `key=value` pairs separated by NUL characters. */
MOONBIT_FFI_EXPORT bap_z3_ctx *bap_z3_mk_context(moonbit_bytes_t config) {
  bap_z3_ctx *c = (bap_z3_ctx *)moonbit_make_external_object(
    bap_z3_ctx_finalize, sizeof(bap_z3_ctx));
  c->ctx = NULL;
  if (!bap_z3_ensure()) return c;
  Z3_config cfg = p_Z3_mk_config();
  int32_t len = (int32_t)Moonbit_array_length(config);
  int32_t pos = 0;
  while (pos < len) {
    const char *key = (const char *)config + pos;
    int32_t klen = (int32_t)strlen(key);
    const char *value = key + klen + 1;
    int32_t vlen = (int32_t)strlen(value);
    p_Z3_set_param_value(cfg, key, value);
    pos += klen + vlen + 2;
  }
  c->ctx = p_Z3_mk_context_rc(cfg);
  p_Z3_del_config(cfg);
  if (c->ctx != NULL) {
    p_Z3_set_error_handler(c->ctx, bap_z3_ignore_error);
  }
  return c;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_ctx_is_null(bap_z3_ctx *c) {
  return c->ctx == NULL;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_error_code(bap_z3_ctx *c) {
  if (c->ctx == NULL) return -1;
  return (int32_t)p_Z3_get_error_code(c->ctx);
}

/* Returns the message of the last error of the context, or an empty
   string if the last call succeeded. */
MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_error(bap_z3_ctx *c) {
  if (c->ctx == NULL) return bap_z3_bytes("SMT solver unavailable");
  Z3_error_code code = p_Z3_get_error_code(c->ctx);
  if (code == 0) return bap_z3_bytes("");
  const char *msg = p_Z3_get_error_msg(c->ctx, code);
  return bap_z3_bytes(msg != NULL && msg[0] != '\0' ? msg : "Z3 error");
}

MOONBIT_FFI_EXPORT void bap_z3_update_param(bap_z3_ctx *c, moonbit_bytes_t key,
                                            moonbit_bytes_t value) {
  p_Z3_update_param_value(c->ctx, (const char *)key, (const char *)value);
}

/* ---------------------------------------------------------------------- */
/* Terms                                                                   */

typedef struct {
  bap_z3_ctx *owner;
  Z3_ast ast;
} bap_z3_ast;

static void bap_z3_ast_finalize(void *self) {
  bap_z3_ast *a = (bap_z3_ast *)self;
  if (a->ast != NULL) {
    p_Z3_dec_ref(a->owner->ctx, a->ast);
    a->ast = NULL;
  }
  if (a->owner != NULL) {
    moonbit_decref(a->owner);
    a->owner = NULL;
  }
}

static bap_z3_ast *bap_z3_wrap(bap_z3_ctx *c, Z3_ast ast) {
  bap_z3_ast *a = (bap_z3_ast *)moonbit_make_external_object(
    bap_z3_ast_finalize, sizeof(bap_z3_ast));
  moonbit_incref(c);
  a->owner = c;
  a->ast = ast;
  if (ast != NULL) p_Z3_inc_ref(c->ctx, ast);
  return a;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_ast_is_null(bap_z3_ast *a) {
  return a->ast == NULL;
}

MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_bool_val(bap_z3_ctx *c, int32_t b) {
  return bap_z3_wrap(c, b ? p_Z3_mk_true(c->ctx) : p_Z3_mk_false(c->ctx));
}

MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_bv_const(bap_z3_ctx *c,
                                              moonbit_bytes_t name,
                                              int32_t width) {
  Z3_sort s = p_Z3_mk_bv_sort(c->ctx, (unsigned)width);
  if (s == NULL) return bap_z3_wrap(c, NULL);
  Z3_symbol sym = p_Z3_mk_string_symbol(c->ctx, (const char *)name);
  return bap_z3_wrap(c, p_Z3_mk_const(c->ctx, sym, s));
}

MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_bool_const(bap_z3_ctx *c,
                                                moonbit_bytes_t name) {
  Z3_sort s = p_Z3_mk_bool_sort(c->ctx);
  Z3_symbol sym = p_Z3_mk_string_symbol(c->ctx, (const char *)name);
  return bap_z3_wrap(c, p_Z3_mk_const(c->ctx, sym, s));
}

/* A bitvector numeral from its unsigned decimal representation. */
MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_bv_numeral(bap_z3_ctx *c,
                                                moonbit_bytes_t dec,
                                                int32_t width) {
  Z3_sort s = p_Z3_mk_bv_sort(c->ctx, (unsigned)width);
  if (s == NULL) return bap_z3_wrap(c, NULL);
  return bap_z3_wrap(c, p_Z3_mk_numeral(c->ctx, (const char *)dec, s));
}

/* Binary operators, see `BinOp` in `z3.mbt` for the numbering. */
MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_binop(bap_z3_ctx *c, int32_t op,
                                           bap_z3_ast *x, bap_z3_ast *y) {
  Z3_context k = c->ctx;
  Z3_ast a = x->ast, b = y->ast, r = NULL;
  Z3_ast args[2] = {a, b};
  switch (op) {
  case 0: r = p_Z3_mk_bvadd(k, a, b); break;
  case 1: r = p_Z3_mk_bvsub(k, a, b); break;
  case 2: r = p_Z3_mk_bvmul(k, a, b); break;
  case 3: r = p_Z3_mk_bvudiv(k, a, b); break;
  case 4: r = p_Z3_mk_bvsdiv(k, a, b); break;
  case 5: r = p_Z3_mk_bvurem(k, a, b); break;
  case 6: r = p_Z3_mk_bvsrem(k, a, b); break;
  case 7: r = p_Z3_mk_bvsmod(k, a, b); break;
  case 8: r = p_Z3_mk_bvand(k, a, b); break;
  case 9: r = p_Z3_mk_bvor(k, a, b); break;
  case 10: r = p_Z3_mk_bvxor(k, a, b); break;
  case 11: r = p_Z3_mk_bvshl(k, a, b); break;
  case 12: r = p_Z3_mk_bvlshr(k, a, b); break;
  case 13: r = p_Z3_mk_bvashr(k, a, b); break;
  case 14: r = p_Z3_mk_concat(k, a, b); break;
  case 15: r = p_Z3_mk_bvult(k, a, b); break;
  case 16: r = p_Z3_mk_bvule(k, a, b); break;
  case 17: r = p_Z3_mk_bvugt(k, a, b); break;
  case 18: r = p_Z3_mk_bvuge(k, a, b); break;
  case 19: r = p_Z3_mk_bvslt(k, a, b); break;
  case 20: r = p_Z3_mk_bvsle(k, a, b); break;
  case 21: r = p_Z3_mk_bvsgt(k, a, b); break;
  case 22: r = p_Z3_mk_bvsge(k, a, b); break;
  case 23: r = p_Z3_mk_eq(k, a, b); break;
  case 24: r = p_Z3_mk_distinct(k, 2, args); break;
  case 25: r = p_Z3_mk_and(k, 2, args); break;
  case 26: r = p_Z3_mk_or(k, 2, args); break;
  case 27: r = p_Z3_mk_xor(k, a, b); break;
  case 28: r = p_Z3_mk_implies(k, a, b); break;
  case 29: r = p_Z3_mk_iff(k, a, b); break;
  default: break;
  }
  return bap_z3_wrap(c, r);
}

/* Unary operators, see `UnOp` in `z3.mbt` for the numbering. */
MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_unop(bap_z3_ctx *c, int32_t op,
                                          bap_z3_ast *x) {
  Z3_context k = c->ctx;
  Z3_ast a = x->ast, r = NULL;
  switch (op) {
  case 0: r = p_Z3_mk_bvnot(k, a); break;
  case 1: r = p_Z3_mk_bvneg(k, a); break;
  case 2: r = p_Z3_mk_bvredor(k, a); break;
  case 3: r = p_Z3_mk_bvredand(k, a); break;
  case 4: r = p_Z3_mk_not(k, a); break;
  case 5: r = p_Z3_simplify(k, a); break;
  default: break;
  }
  return bap_z3_wrap(c, r);
}

/* Parameterized unary operators: 0 - zero_ext, 1 - sign_ext,
   2 - rotate_left, 3 - rotate_right. */
MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_indexed(bap_z3_ctx *c, int32_t op,
                                             int32_t n, bap_z3_ast *x) {
  Z3_context k = c->ctx;
  Z3_ast r = NULL;
  switch (op) {
  case 0: r = p_Z3_mk_zero_ext(k, (unsigned)n, x->ast); break;
  case 1: r = p_Z3_mk_sign_ext(k, (unsigned)n, x->ast); break;
  case 2: r = p_Z3_mk_rotate_left(k, (unsigned)n, x->ast); break;
  case 3: r = p_Z3_mk_rotate_right(k, (unsigned)n, x->ast); break;
  default: break;
  }
  return bap_z3_wrap(c, r);
}

MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_extract(bap_z3_ctx *c, int32_t hi,
                                             int32_t lo, bap_z3_ast *x) {
  return bap_z3_wrap(c,
                     p_Z3_mk_extract(c->ctx, (unsigned)hi, (unsigned)lo, x->ast));
}

MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_ite(bap_z3_ctx *c, bap_z3_ast *cnd,
                                         bap_z3_ast *x, bap_z3_ast *y) {
  return bap_z3_wrap(c, p_Z3_mk_ite(c->ctx, cnd->ast, x->ast, y->ast));
}

/* The sort of a term: -1 - unknown, 0 - boolean, n > 0 - bitvector of
   width n. */
MOONBIT_FFI_EXPORT int32_t bap_z3_sort_of(bap_z3_ctx *c, bap_z3_ast *x) {
  Z3_sort s = p_Z3_get_sort(c->ctx, x->ast);
  if (s == NULL) return -1;
  int kind = p_Z3_get_sort_kind(c->ctx, s);
  if (kind == 1) return 0;
  if (kind == 4) return (int32_t)p_Z3_get_bv_sort_size(c->ctx, s);
  return -1;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_is_numeral(bap_z3_ctx *c, bap_z3_ast *x) {
  return p_Z3_is_numeral_ast(c->ctx, x->ast) ? 1 : 0;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_numeral_string(bap_z3_ctx *c,
                                                        bap_z3_ast *x) {
  return bap_z3_bytes(p_Z3_get_numeral_string(c->ctx, x->ast));
}

/* -1 - false, 0 - undefined, 1 - true */
MOONBIT_FFI_EXPORT int32_t bap_z3_bool_value(bap_z3_ctx *c, bap_z3_ast *x) {
  return p_Z3_get_bool_value(c->ctx, x->ast);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_ast_to_string(bap_z3_ctx *c,
                                                       bap_z3_ast *x) {
  return bap_z3_bytes(p_Z3_ast_to_string(c->ctx, x->ast));
}

MOONBIT_FFI_EXPORT int32_t bap_z3_ast_id(bap_z3_ctx *c, bap_z3_ast *x) {
  return (int32_t)p_Z3_get_ast_id(c->ctx, x->ast);
}

MOONBIT_FFI_EXPORT int32_t bap_z3_ast_hash(bap_z3_ctx *c, bap_z3_ast *x) {
  return (int32_t)p_Z3_get_ast_hash(c->ctx, x->ast);
}

MOONBIT_FFI_EXPORT int32_t bap_z3_ast_eq(bap_z3_ctx *c, bap_z3_ast *x,
                                        bap_z3_ast *y) {
  return p_Z3_is_eq_ast(c->ctx, x->ast, y->ast) ? 1 : 0;
}

/* ---------------------------------------------------------------------- */
/* Solvers                                                                 */

typedef struct {
  bap_z3_ctx *owner;
  Z3_solver solver;
} bap_z3_solver;

static void bap_z3_solver_finalize(void *self) {
  bap_z3_solver *s = (bap_z3_solver *)self;
  if (s->solver != NULL) {
    p_Z3_solver_dec_ref(s->owner->ctx, s->solver);
    s->solver = NULL;
  }
  if (s->owner != NULL) {
    moonbit_decref(s->owner);
    s->owner = NULL;
  }
}

/* kind: 0 - the default solver, 1 - the simple solver */
MOONBIT_FFI_EXPORT bap_z3_solver *bap_z3_mk_solver(bap_z3_ctx *c,
                                                  int32_t kind) {
  bap_z3_solver *s = (bap_z3_solver *)moonbit_make_external_object(
    bap_z3_solver_finalize, sizeof(bap_z3_solver));
  moonbit_incref(c);
  s->owner = c;
  s->solver =
    kind == 1 ? p_Z3_mk_simple_solver(c->ctx) : p_Z3_mk_solver(c->ctx);
  if (s->solver != NULL) p_Z3_solver_inc_ref(c->ctx, s->solver);
  return s;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_solver_is_null(bap_z3_solver *s) {
  return s->solver == NULL;
}

MOONBIT_FFI_EXPORT void bap_z3_solver_set_uint(bap_z3_ctx *c,
                                               bap_z3_solver *s,
                                               moonbit_bytes_t key,
                                               int32_t value) {
  Z3_params p = p_Z3_mk_params(c->ctx);
  p_Z3_params_inc_ref(c->ctx, p);
  Z3_symbol k = p_Z3_mk_string_symbol(c->ctx, (const char *)key);
  p_Z3_params_set_uint(c->ctx, p, k, (unsigned)value);
  p_Z3_solver_set_params(c->ctx, s->solver, p);
  p_Z3_params_dec_ref(c->ctx, p);
}

MOONBIT_FFI_EXPORT void bap_z3_solver_push(bap_z3_ctx *c, bap_z3_solver *s) {
  p_Z3_solver_push(c->ctx, s->solver);
}

MOONBIT_FFI_EXPORT void bap_z3_solver_pop(bap_z3_ctx *c, bap_z3_solver *s,
                                          int32_t n) {
  p_Z3_solver_pop(c->ctx, s->solver, (unsigned)n);
}

MOONBIT_FFI_EXPORT void bap_z3_solver_reset(bap_z3_ctx *c, bap_z3_solver *s) {
  p_Z3_solver_reset(c->ctx, s->solver);
}

MOONBIT_FFI_EXPORT int32_t bap_z3_solver_num_scopes(bap_z3_ctx *c,
                                                    bap_z3_solver *s) {
  return (int32_t)p_Z3_solver_get_num_scopes(c->ctx, s->solver);
}

MOONBIT_FFI_EXPORT void bap_z3_solver_assert(bap_z3_ctx *c, bap_z3_solver *s,
                                             bap_z3_ast *x) {
  p_Z3_solver_assert(c->ctx, s->solver, x->ast);
}

MOONBIT_FFI_EXPORT int32_t bap_z3_solver_check(bap_z3_ctx *c,
                                               bap_z3_solver *s) {
  return p_Z3_solver_check(c->ctx, s->solver);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_solver_reason_unknown(
  bap_z3_ctx *c, bap_z3_solver *s) {
  return bap_z3_bytes(p_Z3_solver_get_reason_unknown(c->ctx, s->solver));
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_solver_to_string(bap_z3_ctx *c,
                                                          bap_z3_solver *s) {
  return bap_z3_bytes(p_Z3_solver_to_string(c->ctx, s->solver));
}

/* ---------------------------------------------------------------------- */
/* Models                                                                  */

typedef struct {
  bap_z3_ctx *owner;
  Z3_model model;
} bap_z3_model;

static void bap_z3_model_finalize(void *self) {
  bap_z3_model *m = (bap_z3_model *)self;
  if (m->model != NULL) {
    p_Z3_model_dec_ref(m->owner->ctx, m->model);
    m->model = NULL;
  }
  if (m->owner != NULL) {
    moonbit_decref(m->owner);
    m->owner = NULL;
  }
}

MOONBIT_FFI_EXPORT bap_z3_model *bap_z3_solver_model(bap_z3_ctx *c,
                                                    bap_z3_solver *s) {
  bap_z3_model *m = (bap_z3_model *)moonbit_make_external_object(
    bap_z3_model_finalize, sizeof(bap_z3_model));
  moonbit_incref(c);
  m->owner = c;
  m->model = p_Z3_solver_get_model(c->ctx, s->solver);
  if (m->model != NULL) p_Z3_model_inc_ref(c->ctx, m->model);
  return m;
}

MOONBIT_FFI_EXPORT int32_t bap_z3_model_is_null(bap_z3_model *m) {
  return m->model == NULL;
}

/* Evaluates a term in the model; the result is a null term on failure. */
MOONBIT_FFI_EXPORT bap_z3_ast *bap_z3_model_eval(bap_z3_ctx *c,
                                                bap_z3_model *m,
                                                bap_z3_ast *x,
                                                int32_t completion) {
  Z3_ast out = NULL;
  if (!p_Z3_model_eval(c->ctx, m->model, x->ast, completion != 0, &out)) {
    out = NULL;
  }
  return bap_z3_wrap(c, out);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t bap_z3_model_to_string(bap_z3_ctx *c,
                                                         bap_z3_model *m) {
  return bap_z3_bytes(p_Z3_model_to_string(c->ctx, m->model));
}
