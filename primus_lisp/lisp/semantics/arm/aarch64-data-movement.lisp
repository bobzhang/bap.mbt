(declare (context (target arm-family)
                  (bits 64)))


(in-package aarch64)

;;; LOADS, MOVES, STORES

;; LD...

(defun LDRXui (dst reg off)
  (set$ dst (load-word (+ reg (lshift off 3)))))

(defun LDRSWui (dst base off)
  (set$ dst (cast-signed
             (word)
             (load-hword (+ base (lshift off 2))))))

(defun LDRWui (dst reg off)
  (setw dst
        (cast-unsigned (word) (load-hword (+ reg (lshift off 2))))))

(defun LDRBBui (dst reg off)
  (setw dst
        (cast-unsigned (word) (load-byte (+ reg off)))))

(defun LDRBBroX (dst reg off _ _)
  (set$ dst
        (cast-unsigned (word) (load-byte (+ reg off)))))

(defun LDPXpost (dst r1 r2 base off)
  (let ((off (lshift off 3)))
    (set$ r1 (load-word base))
    (set$ r2 (load-word (+ base (sizeof word))))
    (set$ dst (+ dst off))))

(defun LDPXi (r1 r2 base off)
  ;; port: both words are loaded before r1 (which may be the base) is
  ;; written
  (ldp-x r1 r2 (+ base (lshift off 3))))

(defun LDRXroX (rt rn rm _ shift)
  (set$ rt (load-word (+ rn (lshift rm (* shift 3))))))

;; MOV...

(defmacro MOVZ*i (set dst imm off)
  (set dst (lshift imm off)))

(defun MOVZWi (dst imm off) (MOVZ*i setw dst imm off))
(defun MOVZXi (dst imm off) (MOVZ*i set$ dst imm off))

(defmacro MOVN*i (set dst imm off)
  (set dst (lnot (lshift imm off))))

(defun MOVNWi (dst imm off) (MOVN*i setw dst imm off))
(defun MOVNXi (dst imm off) (MOVN*i set$ dst imm off))

(defmacro MOVK*i (dst reg imm off)
  (let ((mask (lnot (lshift (- (lshift 1 16) 1) off))))
    (set$ dst (logor (logand reg mask) (lshift imm off)))))

(defun MOVKWi (dst reg imm off) (MOVK*i dst reg imm off))
(defun MOVKXi (dst reg imm off) (MOVK*i dst reg imm off))

;; ST...

(defun STRBBui (src reg off)
  (store-byte (+ reg off) src))

(defun STPXpre (dst t1 t2 _ off)
  (let ((off (lshift off 3)))
    (store-word (+ dst off) t1)
    (store-word (+ dst off (sizeof word)) t2)
    (set$ dst (+ dst off))))

(defun STPXi (t1 t2 base off)
  ;; port: the offset is scaled by 8 and the stored values are t1 and t2
  ;; (upstream scales by 16 and stores the base register twice)
  (let ((off (lshift off 3)))
    (store-word (+ base off) t1)
    (store-word (+ base off (sizeof word)) t2)))

(defun STRXui (src reg off)
  (let ((off (lshift off 3)))
    (store-word (+ reg off) src)))

(defun STRWui (src reg off)
  (let ((off (lshift off 2)))
    (store-word (+ reg off) (cast-low 32 src))))

(defun STRXroX (rt rn rm _ shift)
  (store-word (+ rn (lshift rm (* shift 3))) rt))

(defmacro STUR*i (src base off size)
  "Takes `size` bits from src and stores at base + off"
  (store-word (+ base off) (cast-low size src)))

(defun STURXi  (src base off) (STUR*i src base off 64))

(defun STURWi  (src base off) (STUR*i src base off 32))

(defun STURHHi  (src base off) (STUR*i src base off 16))

(defun STURBBi (src base off) (STUR*i src base off 8))

;; port: added, the loads and stores of all sizes with unsigned offsets,
;; pre/post-indexing, register offsets and unscaled offsets, the pairs,
;; PC-relative loads, the exclusive and acquire/release accesses and the
;; LSE atomic memory operations

(defmacro ld-x (rt bits addr) (set$ rt (cast-unsigned 64 (load-bits bits addr))))
(defmacro ld-w (rt bits addr) (setw rt (cast-unsigned 32 (load-bits bits addr))))
(defmacro lds-x (rt bits addr) (set$ rt (cast-signed 64 (load-bits bits addr))))
(defmacro lds-w (rt bits addr) (setw rt (cast-signed 32 (load-bits bits addr))))
(defmacro st-n (rt bits addr) (store-word addr (cast-low bits rt)))

;; unsigned (scaled) offsets
(defun LDRHHui (rt rn off) (ld-w rt 16 (+ rn (lshift off 1))))
(defun LDRSBXui (rt rn off) (lds-x rt 8 (+ rn off)))
(defun LDRSBWui (rt rn off) (lds-w rt 8 (+ rn off)))
(defun LDRSHXui (rt rn off) (lds-x rt 16 (+ rn (lshift off 1))))
(defun LDRSHWui (rt rn off) (lds-w rt 16 (+ rn (lshift off 1))))
(defun STRHHui (rt rn off) (st-n rt 16 (+ rn (lshift off 1))))

;; unscaled offsets
(defun LDURXi (rt rn off) (ld-x rt 64 (+ rn off)))
(defun LDURWi (rt rn off) (ld-w rt 32 (+ rn off)))
(defun LDURHHi (rt rn off) (ld-w rt 16 (+ rn off)))
(defun LDURBBi (rt rn off) (ld-w rt 8 (+ rn off)))
(defun LDURSBXi (rt rn off) (lds-x rt 8 (+ rn off)))
(defun LDURSBWi (rt rn off) (lds-w rt 8 (+ rn off)))
(defun LDURSHXi (rt rn off) (lds-x rt 16 (+ rn off)))
(defun LDURSHWi (rt rn off) (lds-w rt 16 (+ rn off)))
(defun LDURSWi (rt rn off) (lds-x rt 32 (+ rn off)))

;; pre/post-indexed loads (the loaded register differs from the base)
(defun LDRXpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (ld-x rt 64 a)))
(defun LDRWpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (ld-w rt 32 a)))
(defun LDRHHpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (ld-w rt 16 a)))
(defun LDRBBpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (ld-w rt 8 a)))
(defun LDRSBXpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (lds-x rt 8 a)))
(defun LDRSBWpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (lds-w rt 8 a)))
(defun LDRSHXpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (lds-x rt 16 a)))
(defun LDRSHWpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (lds-w rt 16 a)))
(defun LDRSWpre (wb rt rn off) (let ((a (+ rn off))) (set$ wb a) (lds-x rt 32 a)))
(defun LDRXpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (ld-x rt 64 a)))
(defun LDRWpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (ld-w rt 32 a)))
(defun LDRHHpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (ld-w rt 16 a)))
(defun LDRBBpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (ld-w rt 8 a)))
(defun LDRSBXpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (lds-x rt 8 a)))
(defun LDRSBWpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (lds-w rt 8 a)))
(defun LDRSHXpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (lds-x rt 16 a)))
(defun LDRSHWpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (lds-w rt 16 a)))
(defun LDRSWpost (wb rt rn off) (let ((a rn)) (set$ wb (+ rn off)) (lds-x rt 32 a)))

;; stores write the value before the base is written back (the stored
;; register may be the base, as the stack pointer)
(defun STRXpre (wb rt rn off) (let ((a (+ rn off))) (st-n rt 64 a) (set$ wb a)))
(defun STRWpre (wb rt rn off) (let ((a (+ rn off))) (st-n rt 32 a) (set$ wb a)))
(defun STRHHpre (wb rt rn off) (let ((a (+ rn off))) (st-n rt 16 a) (set$ wb a)))
(defun STRBBpre (wb rt rn off) (let ((a (+ rn off))) (st-n rt 8 a) (set$ wb a)))
(defun STRXpost (wb rt rn off) (let ((a rn)) (st-n rt 64 a) (set$ wb (+ rn off))))
(defun STRWpost (wb rt rn off) (let ((a rn)) (st-n rt 32 a) (set$ wb (+ rn off))))
(defun STRHHpost (wb rt rn off) (let ((a rn)) (st-n rt 16 a) (set$ wb (+ rn off))))
(defun STRBBpost (wb rt rn off) (let ((a rn)) (st-n rt 8 a) (set$ wb (+ rn off))))

;; register offsets: `roX` (X register, lsl or sxtx) and `roW` (W register,
;; uxtw or sxtw); the first flag is the signedness of the extension, the
;; second whether the offset is scaled
(defun LDRXroW (rt rn rm s sh) (ld-x rt 64 (+ rn (mem-extend rm s sh 3))))
(defun LDRWroX (rt rn rm s sh) (ld-w rt 32 (+ rn (mem-extend rm s sh 2))))
(defun LDRWroW (rt rn rm s sh) (ld-w rt 32 (+ rn (mem-extend rm s sh 2))))
(defun LDRHHroX (rt rn rm s sh) (ld-w rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRHHroW (rt rn rm s sh) (ld-w rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRBBroW (rt rn rm s sh) (ld-w rt 8 (+ rn (mem-extend rm s sh 0))))
(defun LDRSBXroX (rt rn rm s sh) (lds-x rt 8 (+ rn (mem-extend rm s sh 0))))
(defun LDRSBXroW (rt rn rm s sh) (lds-x rt 8 (+ rn (mem-extend rm s sh 0))))
(defun LDRSBWroX (rt rn rm s sh) (lds-w rt 8 (+ rn (mem-extend rm s sh 0))))
(defun LDRSBWroW (rt rn rm s sh) (lds-w rt 8 (+ rn (mem-extend rm s sh 0))))
(defun LDRSHXroX (rt rn rm s sh) (lds-x rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRSHXroW (rt rn rm s sh) (lds-x rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRSHWroX (rt rn rm s sh) (lds-w rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRSHWroW (rt rn rm s sh) (lds-w rt 16 (+ rn (mem-extend rm s sh 1))))
(defun LDRSWroX (rt rn rm s sh) (lds-x rt 32 (+ rn (mem-extend rm s sh 2))))
(defun LDRSWroW (rt rn rm s sh) (lds-x rt 32 (+ rn (mem-extend rm s sh 2))))
(defun STRXroW (rt rn rm s sh) (st-n rt 64 (+ rn (mem-extend rm s sh 3))))
(defun STRWroX (rt rn rm s sh) (st-n rt 32 (+ rn (mem-extend rm s sh 2))))
(defun STRWroW (rt rn rm s sh) (st-n rt 32 (+ rn (mem-extend rm s sh 2))))
(defun STRHHroX (rt rn rm s sh) (st-n rt 16 (+ rn (mem-extend rm s sh 1))))
(defun STRHHroW (rt rn rm s sh) (st-n rt 16 (+ rn (mem-extend rm s sh 1))))
(defun STRBBroX (rt rn rm s sh) (st-n rt 8 (+ rn (mem-extend rm s sh 0))))
(defun STRBBroW (rt rn rm s sh) (st-n rt 8 (+ rn (mem-extend rm s sh 0))))

;; pairs (scaled signed offsets); both words are loaded before the
;; registers are written
(defmacro ldp-x (r1 r2 addr)
  (let ((w1 (load-word addr)) (w2 (load-word (+ addr 8))))
    (set$ r1 w1)
    (set$ r2 w2)))
(defmacro ldp-w (r1 r2 addr)
  (let ((w1 (load-bits 32 addr)) (w2 (load-bits 32 (+ addr 4))))
    (setw r1 w1)
    (setw r2 w2)))
(defmacro stp-n (bits t1 t2 addr)
  (prog (store-word addr (cast-low bits t1))
        (store-word (+ addr (/ bits 8)) (cast-low bits t2))))

(defun LDPWi (r1 r2 rn off) (ldp-w r1 r2 (+ rn (lshift off 2))))
(defun LDPXpre (wb r1 r2 rn off)
  (let ((a (+ rn (lshift off 3)))) (set$ wb a) (ldp-x r1 r2 a)))
(defun LDPWpre (wb r1 r2 rn off)
  (let ((a (+ rn (lshift off 2)))) (set$ wb a) (ldp-w r1 r2 a)))
(defun LDPWpost (wb r1 r2 rn off)
  (let ((a rn)) (set$ wb (+ rn (lshift off 2))) (ldp-w r1 r2 a)))
(defun STPWi (t1 t2 rn off) (stp-n 32 t1 t2 (+ rn (lshift off 2))))
(defun STPWpre (wb t1 t2 rn off)
  (let ((a (+ rn (lshift off 2)))) (stp-n 32 t1 t2 a) (set$ wb a)))
(defun STPXpost (wb t1 t2 rn off)
  (let ((a rn)) (stp-n 64 t1 t2 a) (set$ wb (+ rn (lshift off 3)))))
(defun STPWpost (wb t1 t2 rn off)
  (let ((a rn)) (stp-n 32 t1 t2 a) (set$ wb (+ rn (lshift off 2)))))
(defun LDPSWi (r1 r2 rn off)
  (let ((a (+ rn (lshift off 2)))
        (w1 (cast-signed 64 (load-bits 32 a)))
        (w2 (cast-signed 64 (load-bits 32 (+ a 4)))))
    (set$ r1 w1)
    (set$ r2 w2)))

;; PC-relative (literal) loads
(defun LDRXl (rt off) (ld-x rt 64 (+ (get-program-counter) (lshift (cast-signed 64 off) 2))))
(defun LDRWl (rt off) (ld-w rt 32 (+ (get-program-counter) (lshift (cast-signed 64 off) 2))))
(defun LDRSWl (rt off) (lds-x rt 32 (+ (get-program-counter) (lshift (cast-signed 64 off) 2))))

;; exclusive and acquire/release accesses; an exclusive store always
;; succeeds (as in the ARM lifter, there is no exclusive monitor)
(defun LDXRX (rt rn) (ld-x rt 64 rn))
(defun LDXRW (rt rn) (ld-w rt 32 rn))
(defun LDXRH (rt rn) (ld-w rt 16 rn))
(defun LDXRB (rt rn) (ld-w rt 8 rn))
(defun LDAXRX (rt rn) (ld-x rt 64 rn))
(defun LDAXRW (rt rn) (ld-w rt 32 rn))
(defun LDAXRH (rt rn) (ld-w rt 16 rn))
(defun LDAXRB (rt rn) (ld-w rt 8 rn))
(defun LDARX (rt rn) (ld-x rt 64 rn))
(defun LDARW (rt rn) (ld-w rt 32 rn))
(defun LDARH (rt rn) (ld-w rt 16 rn))
(defun LDARB (rt rn) (ld-w rt 8 rn))
(defun STXRX (ws rt rn) (st-n rt 64 rn) (setw ws 0))
(defun STXRW (ws rt rn) (st-n rt 32 rn) (setw ws 0))
(defun STXRH (ws rt rn) (st-n rt 16 rn) (setw ws 0))
(defun STXRB (ws rt rn) (st-n rt 8 rn) (setw ws 0))
(defun STLXRX (ws rt rn) (st-n rt 64 rn) (setw ws 0))
(defun STLXRW (ws rt rn) (st-n rt 32 rn) (setw ws 0))
(defun STLXRH (ws rt rn) (st-n rt 16 rn) (setw ws 0))
(defun STLXRB (ws rt rn) (st-n rt 8 rn) (setw ws 0))
(defun STLRX (rt rn) (st-n rt 64 rn))
(defun STLRW (rt rn) (st-n rt 32 rn))
(defun STLRH (rt rn) (st-n rt 16 rn))
(defun STLRB (rt rn) (st-n rt 8 rn))
