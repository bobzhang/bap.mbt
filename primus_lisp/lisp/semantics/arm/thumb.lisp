(require bits)
(require arm-bits)


;; Note: page references are from ARM DDI 0403E.b

(declare (context (target arm-family)))

(defpackage thumb (:use core target arm))
(defpackage llvm-thumb (:use thumb))

(in-package thumb)

;; port: the definitions marked `port:` are fixed to the ISA (checked
;; against Unicorn by the `unicorn_diff` tables) or added.

(defun tCMPhir (rn rm cnd _)
  "cmp rn, rm"
  ;; port: rn - rm = rn + ~rm + 1 (upstream adds -rm, which gets the
  ;; carry of rm = 0 wrong)
  (when (condition-holds cnd)
    (let ((x (t2reg rn))
          (y (lnot (t2reg rm)))
          (r (+ x y 1)))
      (set-nzcv-from-registers r x y))))

(defun tCMNz (rn rm cnd _)
  "cmn rn, rm ; port: added"
  (when (condition-holds cnd)
    (let ((r (+ rn rm)))
      (set-nzcv-from-registers r rn rm))))

(defun tADR (rd lbl cnd _)
  "adr rd, lbl"
  (when (condition-holds cnd)
    (let ((pc (* 4 (/ (t2pc) 4))))
      (set$ rd (+ pc (lshift lbl 2))))))

(defmacro tLOGs (op rd rn rm cnd)
  ;; port: conditional in IT blocks (upstream writes rd unconditionally)
  (when (condition-holds cnd)
    (let ((r (op rn rm)))
      (when (is-unconditional cnd)
        (set ZF (is-zero r))
        (set NF (msb r)))
      (set$ rd r))))

(defun tEOR (rd _ rn rm cnd _)
  (tLOGs logxor rd rn rm cnd))

(defun t2EORrs (rd rn rm simm cnd _ s)
  "eor.w rd, rn, rm, simm"
  ;; port: eors sets the flags (upstream ignores the S operand)
  (when (condition-holds cnd)
    (let ((r (logxor rn (i-shift rm simm))))
      (when (is-cpsr s)
        (set CF (i-shift-carry rm simm))
        (set ZF (is-zero r))
        (set NF (msb r)))
      (set$ rd r))))

(defun tAND (rd _ rn rm cnd _)
  (tLOGs logand rd rn rm cnd))

(defun tBIC (rd _ rn rm cnd _)
  "bics rd, rn, rm ; with rn = rd"
  (tLOGs logandnot rd rn rm cnd))

(defun tMVN (rd _ rn cnd _)
  (tLOGs logor rd 0 (lnot rn) cnd))

(defun tREV (rd rn cnd _)
  (when (condition-holds cnd)
    (set$ rd (concat
              (extract 7 0 rn)
              (extract 15 8 rn)
              (extract 23 16 rn)
              (extract 31 24 rn)))))

(defun tREVSH (rd rm cnd _)
  "revsh rd, rm ; port: added"
  (when (condition-holds cnd)
    (set$ rd (cast-signed 32 (concat (extract 7 0 rm) (extract 15 8 rm))))))

(defun tREV16 (rd rm cnd _)
  "rev16 rd rm"
  (when (condition-holds cnd)
    (set$ rd (concat
              (extract 23 16 rm)
              (extract 31 24 rm)
              (extract 7 0 rm)
              (extract 15 8 rm)))))

;; port: the register-specified shifts use the least significant byte of
;; the shift register (amounts of 32 and more shift all bits out), keep
;; the carry for a zero amount and set the flags outside of IT blocks
;; only (upstream sets the carry to the msb of the operand and shifts by
;; the whole register)

(defmacro t-shift-reg (shift carry rd rn rm cnd set-flags)
  (when (condition-holds cnd)
    (let ((n (cast-unsigned 32 (extract 7 0 rm)))
          (r (shift rn n)))
      (when set-flags
        (set CF (if (= n 0) CF (carry rn n)))
        (set ZF (is-zero r))
        (set NF (msb r)))
      (set$ rd r))))

(defun tLSLrr (rd _ rn rm cnd _)
  "lsls rd, rn, rm"
  (t-shift-reg lsl-by lsl-carry rd rn rm cnd (is-unconditional cnd)))

(defun tLSRrr (rd _ rn rm cnd _)
  "lsrs rd, rn, rm"
  (t-shift-reg lsr-by lsr-carry rd rn rm cnd (is-unconditional cnd)))

(defun tASRrr (rd _ rn rm cnd _)
  "asrs rd, rn, rm ; port: added"
  (t-shift-reg asr-by asr-carry rd rn rm cnd (is-unconditional cnd)))

(defun tROR (rd _ rn rm cnd _)
  "rors rd, rn, rm ; port: added"
  (t-shift-reg ror-by ror-carry rd rn rm cnd (is-unconditional cnd)))

(defun t2LSLrr (rd rn rm cnd _ s)
  "lsl.w rd, rn, rm ; port: added"
  (t-shift-reg lsl-by lsl-carry rd rn rm cnd (is-cpsr s)))

(defun t2LSRrr (rd rn rm cnd _ s)
  "lsr.w rd, rn, rm ; port: added"
  (t-shift-reg lsr-by lsr-carry rd rn rm cnd (is-cpsr s)))

(defun t2ASRrr (rd rn rm cnd _ s)
  "asr.w rd, rn, rm ; port: added"
  (t-shift-reg asr-by asr-carry rd rn rm cnd (is-cpsr s)))

(defun t2RORrr (rd rn rm cnd _ s)
  "ror.w rd, rn, rm ; port: added"
  (t-shift-reg ror-by ror-carry rd rn rm cnd (is-cpsr s)))

;; port: the immediate shifts decode `lsr`/`asr` #32 (encoded as 0) and
;; set the flags of the S forms (upstream shifts by 0 and ignores S)

(defmacro t2-shift-imm (typ rd rm imm cnd s)
  (when (condition-holds cnd)
    (let ((simm (logor (lshift imm 3) typ))
          (r (i-shift rm simm)))
      (when (is-cpsr s)
        (set CF (i-shift-carry rm simm))
        (set ZF (is-zero r))
        (set NF (msb r)))
      (set$ rd r))))

(defun t2LSLri (rd rm imm cnd _ s)
  "lsl.w rd, rm, #imm"
  (t2-shift-imm 0b010 rd rm imm cnd s))

(defun t2LSRri (rd rm imm cnd _ s)
  "lsr.w rd, rm, #imm"
  (t2-shift-imm 0b011 rd rm imm cnd s))

(defun t2ASRri (rd rm imm cnd _ s)
  "asr.w rd, rm, #imm ; port: added"
  (t2-shift-imm 0b001 rd rm imm cnd s))

(defun t2RORri (rd rm imm cnd _ s)
  "ror.w rd, rm, #imm ; port: added"
  (t2-shift-imm 0b100 rd rm imm cnd s))

(defun tTST (rn rm cnd _)
  "tst rn, rm"
  ;; port: conditional in IT blocks
  (when (condition-holds cnd)
    (let ((rd (logand rn rm)))
      (set ZF (is-zero rd))
      (set NF (msb rd)))))

(defun tADDhirr (rd rn rm cnd _)
  ;; port: reads of pc are the address of the instruction plus 4 and
  ;; writes to pc are jumps
  (when (condition-holds cnd)
    (t2set rd (+ (t2reg rn) (t2reg rm)))))

(defun t2ADDrs (rd rn rm simm cnd _ s)
  "add.w rd, rn, rm, simm"
  ;; port: adds sets the flags
  (when (condition-holds cnd)
    (let ((y (i-shift rm simm))
          (r (+ rn y)))
      (when (is-cpsr s)
        (set-nzcv-from-registers r rn y))
      (set$ rd r))))

(defun tSBC (rd _ rn rm cnd _)
  ;; port: the carry is zero-extended (upstream sign-extends it)
  (add-with-carry/it-block rd rn (lnot rm) (cast-unsigned 32 CF) cnd))

(defun tRSB (rd _ rn cnd _)
  "rsbs	r3, r2, #0"
  (add-with-carry/it-block rd 0 (lnot rn) 1 cnd))

(defun t2RSBrs (rd rn rm simm cnd _ s)
  "rsb rd, rn, rm, simm"
  ;; port: rsbs sets the flags
  (when (condition-holds cnd)
    (let ((x (i-shift rm simm))
          (y (lnot rn))
          (r (+ x y 1)))
      (when (is-cpsr s)
        (set-nzcv-from-registers r x y))
      (set$ rd r))))

(defun tMUL (rd _ rn rm cnd _)
  (when (condition-holds cnd)
    (set$ rd (* rn rm))
    (when (is-unconditional cnd)
      (set ZF (is-zero rd))
      (set NF (msb rd)))))

(defun t2STR_PRE (_ rt rn off cnd _)
  "str rt [rn, #off]!"
  (when (condition-holds cnd)
    (set$ rn (+ rn (t2off off)))
    (store-word rn rt)))

(defun t2STRDi8 (rt1 rt2 rn imm pre _)
  "strd rt1, rt2, [rn, off]"
  (when (condition-holds pre)
    (store-word (+ rn (t2off imm)) rt1)
    (store-word (+ rn (t2off imm) (sizeof word-width)) rt2)))

(defun t2STRs (rt rn rm imm cnd _)
  "str.w rt [rn, rm, lsl imm]"
  (when (condition-holds cnd)
    (store-word (+ rn (lshift rm imm)) rt)))

(defun t2ADDri12 (rd rn imm pre _)
  "addw rd, rn, imm; A7-189, T4 "
  (when (condition-holds pre)
    (set$ rd (+ rn imm))))

(defun t2STRHi12 (rt rn imm pre _)
  "strh.w rt, [rn, imm]; A7-442; T2"
  (when (condition-holds pre)
    (store-word (+ rn imm) (cast-low 16 rt))))

(defun t2B (off pre _)
  "b.w imm; A7-207, T3"
  (when (condition-holds pre)
    (exec-addr (+ (t2pc) off))))

(defun t2Bcc (off pre _)
  "bcc.w imm"
  (when (condition-holds pre)
    (exec-addr (+ (t2pc) off))))

(defun t2TBB (rn rm _ _)
  "tbb [rn, rm]"
  (let ((addr (+ (t2reg rn) (t2reg rm)))
        (halfwords (cast-unsigned 32 (load-bits 8 addr))))
    (exec-addr (+ (t2pc) (* halfwords 2)))))

(defun t2TBH (rn rm _ _)
  "tbh [rn, rm, lsl #1]"
  (let ((addr (+ (t2reg rn) (lshift rm 1)))
        (halfwords (cast-unsigned 32 (load-hword addr))))
    (exec-addr (+ (t2pc) (* halfwords 2)))))

(defun t2LDRs (rt rn rm imm pre _)
  (when (condition-holds pre)
    (t2set rt (load-word (+ rn (lshift rm imm))))))

(defun t2LDRi8 (rt rn imm cnd _)
  "ldr rt, [rn, #-imm]"
  (when (condition-holds cnd)
    (t2set rt (load-word (+ rn (t2off imm))))))

(defun t2LDRDi8 (rt rt2 rn imm cnd _)
  "ldrd rt, rt2, [rn, #imm]"
  ;; port: both words are loaded before rt (which may be rn) is written
  (when (condition-holds cnd)
    (let ((addr (+ rn (t2off imm)))
          (w1 (load-word addr))
          (w2 (load-word (+ addr 4))))
      (set$ rt w1)
      (set$ rt2 w2))))

(defun t2LDR_POST (rt _ rn off cnd _)
  "ldr rt, [rn], #imm"
  (when (condition-holds cnd)
    (let ((tmp rn))
      (set$ rn (+ rn (t2off off)))
      (t2set rt (load-word tmp)))))

(defun t2LDRB_PRE (rt _ rn off cnd _)
  "ldrb rt, [rn, #off]!"
  (when (condition-holds cnd)
    (set$ rn (+ rn (t2off off)))
    (set$ rt (cast-unsigned 32 (load-bits 8 rn)))))

(defun t2LDRSBi12 (rt rn imm pre _)
  "ldrsb.w rt, [rn, imm]"
  (when (condition-holds pre)
    (t2set rt (cast-signed 32 (load-bits 8 (+ rn imm))))))

(defun t2LDRSHi12 (rt rn imm pre _)
  "ldrsh.w rt, [rn, imm]"
  (when (condition-holds pre)
    (t2set rt (cast-signed 32 (load-bits 16 (+ rn imm))))))

(defun t2LDRHi12 (rt rn imm pre _)
  "ldrh.w rt, [rn, imm]"
  (when (condition-holds pre)
    (t2set rt (cast-unsigned 32 (load-bits 16 (+ rn imm))))))

(defun tMOVr (rt rn pre _)
  (when (condition-holds pre)
    (t2set rt (t2reg rn))))

(defun tHINT (_ _ _)
  "nop, yield, wfe, wfi, sev ; port: added"
  (empty))

(defun t2CLZ (rd rm pre _)
  "clz rd, rm ; port: added"
  (when (condition-holds pre)
    (set$ rd (clz rm))))

(defun t2SDIV (rd rn rm pre _)
  "sdiv rd, rn, rm ; port: added (division by zero yields zero)"
  (when (condition-holds pre)
    (set$ rd (if (= rm 0) 0 (s/ rn rm)))))

(defun t2UDIV (rd rn rm pre _)
  "udiv rd, rn, rm ; port: added (division by zero yields zero)"
  (when (condition-holds pre)
    (set$ rd (if (= rm 0) 0 (/ rn rm)))))

(defun is-cpsr (r) (= (symbol r) 'CPSR))

(defun t2off (imm)
  "LLVM encodes the 8-bit offset #-0 as INT32_MIN"
  (if (= imm 0x80000000) 0 imm))

(defun t2pc () (+ (get-program-counter) 4))

(defun is-pc (r) (= (symbol r) 'PC))

(defun t2reg (r)
  (if (is-pc r) (t2pc) r))

(defun t2set (reg val)
  (if (is-pc reg)
      (exec-addr val)
    (set$ reg val)))
