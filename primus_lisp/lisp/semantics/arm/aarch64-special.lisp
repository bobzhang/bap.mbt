(declare (context (target arm-family)
                  (bits 64)))

(in-package aarch64)

;;; SPECIAL INSTRUCTIONS

(defun make-barrier (barrier-type option)
  (intrinsic (symbol-concat 'barrier
                             barrier-type
                             (barrier-option-to-symbol option))))

(defun DMB (option) (make-barrier 'dmb option))

(defun DSB (option) (make-barrier 'dsb option))

;; strictly speaking, only the sy option is valid and is
;; the default option (it can be omitted from the mnemonic).
;; still including option here though
(defun ISB (option) (make-barrier 'isb option))

(defun HINT (_)
  (empty))

;; recent LLVM versions decode `hint #0` as NOP, an opcode without operands
(defun NOP ()
  (empty))

(defun UDF (exn)
  (intrinsic 'undefined-instruction))

;; port: pointer authentication (ARMv8.3 PAuth), added; upstream has no
;; semantics for it. The semantics model the instructions with pointer
;; authentication disabled (SCTLR_ELx.EnIA/EnIB/EnDA/EnDB clear), as a
;; process without keys sees them: the PAC* and AUT* instructions leave
;; their register unchanged, XPAC* strip nothing, and the authenticating
;; branches and returns are the plain ones.

(defun PACIASP () (empty))
(defun PACIBSP () (empty))
(defun PACIAZ () (empty))
(defun PACIBZ () (empty))
(defun PACIA1716 () (empty))
(defun PACIB1716 () (empty))
(defun AUTIASP () (empty))
(defun AUTIBSP () (empty))
(defun AUTIAZ () (empty))
(defun AUTIBZ () (empty))
(defun AUTIA1716 () (empty))
(defun AUTIB1716 () (empty))
(defun XPACLRI () (empty))

(defun PACIA (_ _ _) (empty))
(defun PACIB (_ _ _) (empty))
(defun PACDA (_ _ _) (empty))
(defun PACDB (_ _ _) (empty))
(defun AUTIA (_ _ _) (empty))
(defun AUTIB (_ _ _) (empty))
(defun AUTDA (_ _ _) (empty))
(defun AUTDB (_ _ _) (empty))
(defun PACIZA (_ _) (empty))
(defun PACIZB (_ _) (empty))
(defun PACDZA (_ _) (empty))
(defun PACDZB (_ _) (empty))
(defun AUTIZA (_ _) (empty))
(defun AUTIZB (_ _) (empty))
(defun AUTDZA (_ _) (empty))
(defun AUTDZB (_ _) (empty))
(defun XPACI (_ _) (empty))
(defun XPACD (_ _) (empty))

(defun BRK (_)
  "brk #imm ; port: added, a software breakpoint"
  (intrinsic 'software-breakpoint))
