(declare (context (target riscv)))
(defpackage riscv (:use core target program))
(defpackage llvm-riscv64 (:use riscv riscv64))
(defpackage llvm-riscv32 (:use riscv riscv32))
(in-package riscv)

;;; The BAP MoonBit port: the definitions follow the RISC-V ISA for the
;;; operands produced by LLVM's disassembler (and the port's native
;;; decoder). Definitions marked "port:" deliberately deviate from
;;; upstream's `plugins/riscv/semantics/riscv.lisp`, or are not defined
;;; upstream.

;;; Helpers

(defun word-bits (bits x)
  "(word-bits BITS X) sign-extends the low BITS bits of X to the register
   width (the result of a *W instruction). port: not in upstream."
  (declare (visibility :private))
  (cast-signed (word-width) (cast-low bits x)))

(defun shift-amount (x)
  "(shift-amount X) the low 5 (RV32) or 6 (RV64) bits of X. port: not in
   upstream."
  (declare (visibility :private))
  (logand x (- (word-width) 1)))

;;; Core Arithmetic

(defun ADDI (dst src off)
  (set$ dst (+ src off)))

(defun C_ADDI (dst src off)
  (set$ dst (+ src off)))

(defun add3 (dst src off)
  (declare (visibility :private))
  (set$ dst (cast-signed
             (word-width)
             (cast-low (/ (word-width) 2)
                       (+ src off)))))

(defun ADDIW (dst src off)
  (add3 dst src off))

(defun C_ADDIW (dst src off)
  (add3 dst src off))

(defun ADDW (dst src off)
  (add3 dst src off))

(defun C_ADDW (rd r1 r2)
  (add3 rd r1 r2))

(defun ADD (rd r1 r2)
  "port: not in upstream."
  (set$ rd (+ r1 r2)))

(defun C_ADD (rd r1 r2)
  (set$ rd (+ r1 r2)))

(defun C_ADDI4SPN (dst src off)
  (set$ dst (+ src off)))

(defun C_ADDI16SP (dst src off)
  (set$ dst (+ src off)))

(defun SUB (rd r1 r2)
  (set$ rd (- r1 r2)))

(defun C_SUB (rd r1 r2)
  (set$ rd (- r1 r2)))

(defun SUBW (rd r1 r2)
  "port: not in upstream."
  (set$ rd (word-bits 32 (- r1 r2))))

(defun C_SUBW (rd r1 r2)
  "port: not in upstream."
  (set$ rd (word-bits 32 (- r1 r2))))

;;; Multiplication and division (the M extension; port: not in upstream)

(defun double-width ()
  (declare (visibility :private))
  (* 2 (word-width)))

(defun MUL (rd r1 r2)
  (set$ rd (* r1 r2)))

(defun MULH (rd r1 r2)
  (set$ rd (cast-high (word-width)
                      (* (cast-signed (double-width) r1)
                         (cast-signed (double-width) r2)))))

(defun MULHU (rd r1 r2)
  (set$ rd (cast-high (word-width)
                      (* (cast-unsigned (double-width) r1)
                         (cast-unsigned (double-width) r2)))))

(defun MULHSU (rd r1 r2)
  (set$ rd (cast-high (word-width)
                      (* (cast-signed (double-width) r1)
                         (cast-unsigned (double-width) r2)))))

(defun DIV (rd r1 r2)
  (if (is-zero r2)
      (set$ rd -1)
    (set$ rd (s/ r1 r2))))

(defun DIVU (rd r1 r2)
  (if (is-zero r2)
      (set$ rd -1)
    (set$ rd (/ r1 r2))))

(defun REM (rd r1 r2)
  (if (is-zero r2)
      (set$ rd r1)
    (set$ rd (signed-mod r1 r2))))

(defun REMU (rd r1 r2)
  (if (is-zero r2)
      (set$ rd r1)
    (set$ rd (mod r1 r2))))

(defun MULW (rd r1 r2)
  (set$ rd (word-bits 32 (* r1 r2))))

(defun DIVW (rd r1 r2)
  (let ((a (cast-low 32 r1))
        (b (cast-low 32 r2)))
    (if (is-zero b)
        (set$ rd -1)
      (set$ rd (word-bits 32 (s/ a b))))))

(defun DIVUW (rd r1 r2)
  (let ((a (cast-low 32 r1))
        (b (cast-low 32 r2)))
    (if (is-zero b)
        (set$ rd -1)
      (set$ rd (word-bits 32 (/ a b))))))

(defun REMW (rd r1 r2)
  (let ((a (cast-low 32 r1))
        (b (cast-low 32 r2)))
    (if (is-zero b)
        (set$ rd (word-bits 32 a))
      (set$ rd (word-bits 32 (signed-mod a b))))))

(defun REMUW (rd r1 r2)
  (let ((a (cast-low 32 r1))
        (b (cast-low 32 r2)))
    (if (is-zero b)
        (set$ rd (word-bits 32 a))
      (set$ rd (word-bits 32 (mod a b))))))

;;; Moves

(defun C_MV (dst src)
  (set$ dst src))

(defun upper (imm)
  "(upper IMM) the 20-bit upper immediate IMM shifted into place and
   sign-extended from 32 bits. port: upstream does not sign-extend."
  (declare (visibility :private))
  (word-bits 32 (lshift imm 12)))

(defun C_LUI (dst imm)
  (set$ dst (upper imm)))

(defun AUIPC (dst off)
  "port: upstream adds the unshifted immediate."
  (set$ dst (+ (get-program-counter) (upper off))))

(defun LUI (dst imm)
  (set$ dst (upper imm)))

(defun LI (dst imm)
  (set$ dst (cast-signed (word-width) imm)))

(defun C_LI (dst imm)
  (set$ dst (cast-signed (word-width) imm)))

;;; Memory operations

(defmacro load-bits-as (cast bits dst reg off)
  "port: loads BITS bits (upstream loads a fraction of the word width,
   which is wrong on RV32)."
  (set$ dst (cast (word-width) (load-bits bits (+ reg off)))))

(defun LD (dst reg off)
  (set$ dst (core:load-word (+ reg off))))

(defun C_LD (dst reg off)
  (set$ dst (core:load-word (+ reg off))))

(defun C_LDSP (dst reg off)
  (set$ dst (core:load-word (+ reg off))))

(defun LW (dst reg off)
  (load-bits-as cast-signed 32 dst reg off))

(defun C_LW (dst reg off)
  (load-bits-as cast-signed 32 dst reg off))

(defun C_LWSP (dst reg off)
  "port: not in upstream."
  (load-bits-as cast-signed 32 dst reg off))

(defun LWU (dst reg off)
  (load-bits-as cast-unsigned 32 dst reg off))

(defun LH (dst reg off)
  (load-bits-as cast-signed 16 dst reg off))

(defun LHU (dst reg off)
  (load-bits-as cast-unsigned 16 dst reg off))

(defun LB (dst reg off)
  (set$ dst (cast-signed (word-width) (load-byte (+ reg off)))))

(defun LBU (dst reg off)
  (set$ dst (cast-unsigned (word-width) (load-byte (+ reg off)))))

(defun C_SDSP (val sp imm)
  (store-word (+ sp imm) val))

(defun SDSP (val sp imm)
  (store-word (+ sp imm) val))

(defun SD (val reg imm)
  (store-word (+ reg imm) val))

(defun C_SD (val reg imm)
  (store-word (+ reg imm) val))

(defun SW (val reg imm)
  "port: stores 32 bits (upstream stores half of the word width)."
  (store-word (+ reg imm) (cast-low 32 val)))

(defun C_SW (val reg imm)
  "port: not in upstream."
  (store-word (+ reg imm) (cast-low 32 val)))

(defun C_SWSP (val reg imm)
  "port: not in upstream."
  (store-word (+ reg imm) (cast-low 32 val)))

(defun SH (val reg imm)
  "port: stores 16 bits (upstream stores a quarter of the word width)."
  (store-word (+ reg imm) (cast-low 16 val)))

(defun SB (val reg imm)
  (store-byte (+ reg imm) val))

;;; Bitwise Operations

(defun ANDI (dst src off)
  (set$ dst (logand src off)))

(defun ORI (dst src off)
  (set$ dst (logor src off)))

(defun XORI (dst src off)
  (set$ dst (logxor src off)))

(defun AND (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logand r1 r2)))

(defun OR (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logor r1 r2)))

(defun XOR (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logxor r1 r2)))

(defun C_ANDI (dst src off)
  "port: not in upstream."
  (set$ dst (logand src off)))

(defun C_AND (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logand r1 r2)))

(defun C_OR (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logor r1 r2)))

(defun C_XOR (rd r1 r2)
  "port: not in upstream."
  (set$ rd (logxor r1 r2)))

(defun SRLI (dst reg off)
  (set$ dst (rshift reg off)))

(defun C_SRLI (dst reg off)
  (set$ dst (rshift reg off)))

(defun C_SRAI (dst src imm)
  (set$ dst (arshift src imm)))

(defun SRAI (dst src imm)
  (set$ dst (arshift src imm)))

(defun SLLI (dst reg off)
  (set$ dst (lshift reg off)))

(defun C_SLLI (dst reg off)
  (set$ dst (lshift reg off)))

;; register shifts use the low 5 (RV32) or 6 (RV64) bits of the amount;
;; the *W shifts operate on the low words (port: not in upstream)

(defun SLL (rd r1 r2)
  (set$ rd (lshift r1 (shift-amount r2))))

(defun SRL (rd r1 r2)
  (set$ rd (rshift r1 (shift-amount r2))))

(defun SRA (rd r1 r2)
  (set$ rd (arshift r1 (shift-amount r2))))

(defun SLLIW (rd r1 imm)
  (set$ rd (word-bits 32 (lshift (cast-low 32 r1) imm))))

(defun SRLIW (rd r1 imm)
  (set$ rd (word-bits 32 (rshift (cast-low 32 r1) imm))))

(defun SRAIW (rd r1 imm)
  (set$ rd (word-bits 32 (arshift (cast-low 32 r1) imm))))

(defun SLLW (rd r1 r2)
  (set$ rd (word-bits 32 (lshift (cast-low 32 r1) (logand r2 31)))))

(defun SRLW (rd r1 r2)
  (set$ rd (word-bits 32 (rshift (cast-low 32 r1) (logand r2 31)))))

(defun SRAW (rd r1 r2)
  (set$ rd (word-bits 32 (arshift (cast-low 32 r1) (logand r2 31)))))

;;; Comparison

(defun SLTI (dst src off)
  "port: a signed comparison of SRC (upstream compares DST, unsigned)."
  (set$ dst (s< src off)))

(defun SLTIU (dst src off)
  "port: not in upstream."
  (set$ dst (< src off)))

(defun SLT (rd r1 r2)
  "port: not in upstream."
  (set$ rd (s< r1 r2)))

(defun SLTU (rd r1 r2)
  "port: not in upstream."
  (set$ rd (< r1 r2)))

;;; Jumps

(defun JAL (lr off)
  (let ((pc (get-program-counter)))
    (set$ lr (+ pc 4))
    (exec-addr (+ pc off))))

(defun C_JAL (off)
  "port: not in upstream."
  (let ((pc (get-program-counter)))
    (set X1 (+ pc 2))
    (exec-addr (+ pc off))))

(defun JALR (lr rs off)
  "port: jumps to (RS + OFF) & ~1, read before LR is written (upstream
   jumps to PC + RS + OFF)."
  (let ((pc (get-program-counter))
        (dst (logand (+ rs off) (lnot 1))))
    (set$ lr (+ pc 4))
    (exec-addr dst)))

(defun C_JR (dst)
  (exec-addr dst))

(defun C_J (dst)
  (exec-addr (+ (get-program-counter) dst)))

(defun C_JALR (dst)
  "port: the target is read before X1 is written."
  (let ((target dst))
    (set X1 (+ (get-program-counter) 2))
    (exec-addr target)))

(defun conditional-jump (cmp off)
  (declare (visibility :private))
  (let ((pc (get-program-counter)))
    (when cmp
      (exec-addr (+ pc off)))))

(defun BEQ (rs1 rs2 off)
  (conditional-jump (= rs1 rs2) off))

(defun BLT (rs1 rs2 off)
  "port: a signed comparison (upstream: unsigned)."
  (conditional-jump (s< rs1 rs2) off))

(defun BNE (rs1 rs2 off)
  (conditional-jump (/= rs1 rs2) off))

(defun BGE (rs1 rs2 off)
  "port: a signed comparison (upstream: unsigned)."
  (conditional-jump (s>= rs1 rs2) off))

(defun BLTU (rs1 rs2 off)
  "port: not in upstream."
  (conditional-jump (< rs1 rs2) off))

(defun BGEU (rs1 rs2 off)
  "port: not in upstream."
  (conditional-jump (>= rs1 rs2) off))

(defun C_BEQ (rs1 rs2 off)
  (conditional-jump (= rs1 rs2) off))

(defun C_BLT (rs1 rs2 off)
  (conditional-jump (s< rs1 rs2) off))

(defun C_BNE (rs1 rs2 off)
  (conditional-jump (/= rs1 rs2) off))

(defun C_BGE (rs1 rs2 off)
  (conditional-jump (s>= rs1 rs2) off))

(defun BEQZ (rs1 off)
  (conditional-jump (is-zero rs1) off))

(defun C_BEQZ (rs1 off)
  (conditional-jump (is-zero rs1) off))

(defun BNEZ (rs1 off)
  (conditional-jump (not (is-zero rs1)) off))

(defun C_BNEZ (rs1 off)
  (conditional-jump (not (is-zero rs1)) off))

;;; No-ops and fences

(defun C_NOP ()
  (empty))

(defun NOP ()
  (empty))

(defun FENCE (pred succ)
  "port: not in upstream."
  (empty))

(defun FENCE_TSO ()
  "port: not in upstream."
  (empty))

(defun FENCE_I ()
  "port: not in upstream."
  (empty))
