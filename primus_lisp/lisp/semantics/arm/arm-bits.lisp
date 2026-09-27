(defpackage arm (:use core target))
(declare (context (target arm-family)))

(in-package arm)

(defun set-nzcv-from-registers (r x y)
  "(set-nzcv-from-registers r x y) sets the processor state flags
   to the result of some arithmetic operation (op x y) with r as the result.
   Common examples include:
    (set-nzcv-from-registers (+ x y) x y)
   or
    (set-nzcv-from-registers (+ x y 1) x y)
   This function was formerly named set-flags, but was renamed to improve clarity."
  (set NF (msb r))
  (set VF (overflow r x y))
  (set ZF (is-zero r))
  (set CF (carry r x y)))

(defun set-nzcv (nzcv)
  "(set-nzcv nzcv) sets the negative, zero, carry and overflow flags to
   the bottom 4 bits of nzcv."
  (set NF (select 3 nzcv))
  (set ZF (select 2 nzcv))
  (set CF (select 1 nzcv))
  (set VF (select 0 nzcv)))

(defun add-with-carry (rd x y c)
  "(add-with-carry rd x y c) sets rd to the result of adding x and y
   with carry bit c, and sets processor flags."
  (let ((r (+ c y x)))
    (set-nzcv-from-registers r x y)
    (set$ rd r)))

(defun add-with-carry/clear-base (rd x y c)
  "(add-with-carry/clear-base rd x y c) sets rd to the result of adding x and y
   with carry bit c after clearing the base register rd, and sets processor flags."
  (let ((r (+ c y x)))
    (set-nzcv-from-registers r y x)
    (setw rd r)))

(defun add-with-carry/it-block (rd x y c cnd)
  "(add-with-carry/it-block rd x y c cnd) sets rd to the result of adding x and y
   with carry bit c if cnd holds, and sets processor flags if cnd is unconditional."
  (when (condition-holds cnd)
    (let ((r (+ c y x)))
      (when (is-unconditional cnd)
        (set-nzcv-from-registers r x y))
      (set$ rd r))))

(defmacro shift-with-carry (shift rd rn rm cnd)
  "(shift-with-carry shift rd rn rm cnd) sets rd to the shifted
   value of rn and rm, and relevant processor flags, when cnd holds.
   The overflow flag is not changed."
  (when (condition-holds cnd)
    (let ((r (cast-signed (word-width) rn)))
      (when (is-unconditional cnd)
        (set CF (msb r))
        (set$ rd (shift r rm))
        (set ZF (is-zero rd))
        (set NF (msb rd))))))

(defun condition-holds (cnd)
  "(condition-holds cnd) calculates the result of the given condition cnd
   based on the values of processor flags."
  (case cnd
    0b0000 ZF
    0b0001 (lnot ZF)
    0b0010 CF
    0b0011 (lnot CF)
    0b0100 NF
    0b0101 (lnot NF)
    0b0110 VF
    0b0111 (lnot VF)
    0b1000 (logand CF (lnot ZF))
    0b1001 (logor (lnot CF) ZF)
    0b1010 (= NF VF)
    0b1011 (/= NF VF)
    0b1100 (logand (= NF VF) (lnot ZF))
    0b1101 (logor (/= NF VF) ZF)
    true))

(defun is-unconditional (cnd)
  "(is-unconditional cnd) checks whether cnd is unconditional, i.e. 0b1110."
  (= cnd 0b1110))

(defmacro setw (reg val)
  "(set Wx V) sets a Wx register clearing the upper 32 bits."
  ;; port: the low word of V is written (V is often computed at 64 bits
  ;; from sign-extended W operands, whose upper half upstream writes too)
  (set$ (alias-base-register reg) (cast-low 32 (cast-unsigned 64 val))))

(defun replicate-to-fill (bitv n)
  "(replicate-to-fill bitv n) returns the result of repeating bitv
   to a total of n bits. Requires that n is a multiple of bitv's length.
   Modified from the bits(N) Replicate(bits(M) x) function from
   ARMv8 ISA pseudocode."
  (let ((bitv-length (word-width bitv)))
    (assert-msg (= 0 (mod n bitv-length)) "replicate-to-fill n not multiple of len(bitv)")
    (replicate bitv (/ n bitv-length))))

(defun i-shift (r simm)
  "(i-shift r simm) shifts r according to the encoded shift simm.
   The first three bits of simm indicate the shift type, and the
   remaining bits indicate the shift amount."
  ;; port: lsr and asr by 0 encode shifts by 32 (upstream shifts by 0)
  (let ((amt (rshift simm 3)))
    (case (extract 2 0 simm)
      0b000 r ; none
      0b001 (arshift r (if (= amt 0) 31 amt)) ; asr
      0b010 (lshift r amt) ; lsl
      0b011 (if (= amt 0) 0 (rshift r amt)) ; lsr
      0b100 (rotate-right r amt) ; ror
      0b101 (logor (lshift (cast-unsigned 32 CF) 31) (rshift r 1))))) ; rrx

(defun i-shift-carry (r simm)
  "(i-shift-carry r simm) is the carry out of (i-shift r simm) ; port: added"
  (let ((amt (rshift simm 3)))
    (case (extract 2 0 simm)
      0b000 CF
      0b001 (if (= amt 0) (msb r) (lsb (rshift r (- amt 1))))
      0b010 (if (= amt 0) CF (msb (lshift r (- amt 1))))
      0b011 (if (= amt 0) (msb r) (lsb (rshift r (- amt 1))))
      0b100 (lsb (rshift r (- amt 1)))
      0b101 (lsb r))))

;; port: added, the register-specified shifts of R by the dynamic amount
;; N (0 to 255) and their carry out for a non-zero N

(defun lsl-by (r n) (if (< n 32) (lshift r n) 0))
(defun lsr-by (r n) (if (< n 32) (rshift r n) 0))
(defun asr-by (r n) (arshift r (if (< n 32) n 31)))
(defun ror-by (r n) (rotate-right r (logand n 31)))

(defun lsl-carry (r n) (if (< n 33) (msb (lshift r (- n 1))) 0))
(defun lsr-carry (r n) (if (< n 33) (lsb (rshift r (- n 1))) 0))
(defun asr-carry (r n) (if (< n 33) (lsb (rshift r (- n 1))) (msb r)))
(defun ror-carry (r n) (msb (ror-by r n)))
