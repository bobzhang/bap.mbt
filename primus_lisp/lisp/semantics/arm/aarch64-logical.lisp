(declare (context (target arm-family)
                  (bits 64)))

(in-package aarch64)

;;; LOGICAL/BITFIELD OPERATIONS

;; Logical

(defmacro ORN*rs (set rd rn rm is)
  "(ORN*rs set rd rn rm is) implements the OR NOT instruction
   accepting either a W or X register."
  ;; port: the operand is shifted as encoded (upstream shifts left by the
  ;; whole encoded shift operand)
  (set rd (logor rn (lnot (shift-encoded rm is)))))

(defun ORNWrs (rd rn rm is) (ORN*rs setw rd rn rm is))
(defun ORNXrs (rd rn rm is) (ORN*rs set$ rd rn rm is))

(defmacro log*rs (set op rd rn rm is)
  "(log*rs set op rd rn is) implements the logical operation (shift) instruction
   accepting either a W or X register. op is the binary logical operation."
  (set rd (op rn (shift-encoded rm is))))

(defun ORRWrs (rd rn rm is) (log*rs setw logor  rd rn rm is))
(defun EORWrs (rd rn rm is) (log*rs setw logxor rd rn rm is))
(defun ANDWrs (rd rn rm is) (log*rs setw logand rd rn rm is))
(defun ORRXrs (rd rn rm is) (log*rs set$ logor  rd rn rm is))
(defun EORXrs (rd rn rm is) (log*rs set$ logxor rd rn rm is))
(defun ANDXrs (rd rn rm is) (log*rs set$ logand rd rn rm is))

(defmacro log*ri (set op rd rn imm register-width)
  "(log*ri set op rd rn imm register-width) implements the logical operation (immediate) instruction
   accepting either a W or X register. op is the binary logical operation, and register-width
   is the width of the given registers."
  (set rd (op rn (immediate-from-bitmask imm register-width))))

(defun ANDWri (rd rn imm) (log*ri setw logand rd rn imm 32))
(defun ANDXri (rd rn imm) (log*ri set$ logand rd rn imm 64))
(defun EORWri (rd rn imm) (log*ri setw logxor rd rn imm 32))
(defun EORXri (rd rn imm) (log*ri set$ logxor rd rn imm 64))
(defun ORRWri (rd rn imm) (log*ri setw logor  rd rn imm 32))
(defun ORRXri (rd rn imm) (log*ri set$ logor  rd rn imm 64))

;; UBFM and SBFM
;; (bitfield moves)

(defmacro make-eBFM (set cast xd xr ir is)
  "(make-BFM  cast xd xr ir is) implements bitfield move instructions
   accepting either a W or X register, with cast being an unsigned or signed cast."
  (let ((rs (word-width xd)))
    (if (< is ir)
        (set xd (lshift
                 (cast rs (cast-low (+1 is) xr))
                 (- rs ir)))
      (set xd (cast rs (extract is ir xr))))))

(defun UBFMXri (xd xr ir is)
  (make-eBFM set$ cast-unsigned xd xr ir is))

(defun UBFMWri (xd xr ir is)
  (make-eBFM setw cast-unsigned xd xr ir is))

(defun SBFMXri (xd xr ir is)
  (make-eBFM set$ cast-signed xd xr ir is))

(defun SBFMWri (xd xr ir is)
  (make-eBFM setw cast-signed xd xr ir is))

(defmacro BFM (set rd rn r s)
  ;; port: for s < r, the s + 1 low bits of rn are inserted at bit
  ;; size - r (upstream misplaces them by one bit)
  (let ((size (word-width rd)))
    (if (>= s r)
      (if (= (- s r) (- size 1))
          (set rd rn)
        (set rd (concat
                 (cast-high (- size (+1 (- s r))) rd)
                 (if (= r 0)
                   (cast-low (+1 s) rn)
                   (extract s r rn)))))
      (if (= r (+1 s))
          (set rd (concat
                   (cast-low (+1 s) rn)
                   (cast-low (- size r) rd)))
        (set rd (concat
                 (cast-high (- r (+1 s)) rd)
                 (cast-low (+1 s) rn)
                 (cast-low (- size r) rd)))))))

(defun BFMXri (_ xd xr ir is)
  (BFM set$ xd xr ir is))

(defun BFMWri (_ xd xr ir is)
  (BFM setw xd xr ir is))

;; port: added, the flag-setting, BIC and EON forms, the variable shifts,
;; the bit and byte reversals, the leading zero/sign bit counts and EXTR

(defmacro logs*rs (set op rd rn rm is)
  (let ((r (op rn (shift-encoded rm is))))
    (set-nz-cv0 r)
    (set rd r)))

(defun ANDSWrs (rd rn rm is) (logs*rs setw logand rd rn rm is))
(defun ANDSXrs (rd rn rm is) (logs*rs set$ logand rd rn rm is))
(defun BICSWrs (rd rn rm is) (logs*rs setw logandnot rd rn rm is))
(defun BICSXrs (rd rn rm is) (logs*rs set$ logandnot rd rn rm is))
(defun BICWrs (rd rn rm is) (log*rs setw logandnot rd rn rm is))
(defun BICXrs (rd rn rm is) (log*rs set$ logandnot rd rn rm is))
(defun EONWrs (rd rn rm is) (setw rd (logxor rn (lnot (shift-encoded rm is)))))
(defun EONXrs (rd rn rm is) (set$ rd (logxor rn (lnot (shift-encoded rm is)))))

(defun ANDSWri (rd rn imm)
  (let ((r (logand rn (immediate-from-bitmask imm 32))))
    (set-nz-cv0 r)
    (setw rd r)))

(defun ANDSXri (rd rn imm)
  (let ((r (logand rn (immediate-from-bitmask imm 64))))
    (set-nz-cv0 r)
    (set$ rd r)))

(defun LSLVWr (rd rn rm) (setw rd (lshift rn (logand rm 31))))
(defun LSLVXr (rd rn rm) (set$ rd (lshift rn (logand rm 63))))
(defun LSRVWr (rd rn rm) (setw rd (rshift rn (logand rm 31))))
(defun LSRVXr (rd rn rm) (set$ rd (rshift rn (logand rm 63))))
(defun ASRVWr (rd rn rm) (setw rd (arshift rn (logand rm 31))))
(defun ASRVXr (rd rn rm) (set$ rd (arshift rn (logand rm 63))))
(defun RORVWr (rd rn rm) (setw rd (rotate-right rn (logand rm 31))))
(defun RORVXr (rd rn rm) (set$ rd (rotate-right rn (logand rm 63))))

(defun CLZWr (rd rn) (setw rd (clz rn)))
(defun CLZXr (rd rn) (set$ rd (clz rn)))
(defun CLSWr (rd rn) (setw rd (count-leading-sign-bits rn)))
(defun CLSXr (rd rn) (set$ rd (count-leading-sign-bits rn)))
(defun RBITWr (rd rn) (setw rd (reverse-bits32 rn)))
(defun RBITXr (rd rn) (set$ rd (reverse-bits64 rn)))
(defun REVWr (rd rn) (setw rd (reverse-bytes32 rn)))
(defun REVXr (rd rn) (set$ rd (reverse-bytes64 rn)))
(defun REV16Wr (rd rn) (setw rd (reverse-halfword-bytes rn)))
(defun REV16Xr (rd rn) (set$ rd (reverse-halfword-bytes rn)))
(defun REV32Xr (rd rn)
  (set$ rd (concat (reverse-bytes32 (cast-high 32 rn))
                   (reverse-bytes32 (cast-low 32 rn)))))

(defun EXTRWrri (rd rn rm lsb)
  (setw rd (extract (+ lsb 31) lsb (concat rn rm))))
(defun EXTRXrri (rd rn rm lsb)
  (set$ rd (extract (+ lsb 63) lsb (concat rn rm))))
