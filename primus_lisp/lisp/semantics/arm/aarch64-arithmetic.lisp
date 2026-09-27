(declare (context (target arm-family)
                  (bits 64)))


(in-package aarch64)

;;; INTEGER ARITHMETIC OPERATIONS

(defmacro ADD*r* (set shift-function rd rn imm-or-rm off)
  "Implements ADD*ri and ADD*rs by specifying the shift function."
  (set rd (+ rn (shift-function imm-or-rm off))))

;; ADD*ri only uses lshift since the shift arg only zero-extends
;; and doesn't actually change from lshift
(defun ADDWri (rd rn imm off) (ADD*r* setw lshift rd rn imm off))
(defun ADDXri (rd rn imm off) (ADD*r* set$ lshift rd rn imm off))
;; shift-encoded decodes the shift type and shifts
(defun ADDWrs (rd rn rm off) (ADD*r* setw shift-encoded rd rn rm off))
(defun ADDXrs (rd rn rm off) (ADD*r* set$ shift-encoded rd rn rm off))

(defun ADRP (dst imm)
  (set$ dst (+
             (logand (get-program-counter) (lshift -1 12))
             (cast-signed (word) (lshift imm 12)))))

(defmacro SUB*r* (set shift-function rd rn imm-or-rm off)
  "Implements SUB*ri and SUB*rs by specifying the shift function."
  (set rd (- rn (shift-function imm-or-rm off))))

;; see ADD*ri vs ADD*rs
(defun SUBWri (rd rn rm off) (SUB*r* setw lshift rd rn rm off))
(defun SUBXri (rd rn rm off) (SUB*r* set$ lshift rd rn rm off))
(defun SUBWrs (rd rn rm off) (SUB*r* setw shift-encoded rd rn rm off))
(defun SUBXrs (rd rn rm off) (SUB*r* set$ shift-encoded rd rn rm off))

(defun SUBXrx64 (rd rn rm off)
  (set$ rd (- rn (extended rm off))))

;; port: the flags of the W forms are computed on the low words (upstream
;; computes them on 64-bit sign extensions)
(defun SUBSWrs (rd rn rm off)
  (adc32 rd rn (lnot (shift-encoded rm off)) 1))

(defun SUBSXrs (rd rn rm off)
  (adc64 rd rn (lnot (shift-encoded rm off)) 1))

(defun SUBSWri (rd rn imm off)
  (adc32 rd rn (lnot (lshift imm off)) 1))

(defun SUBSXri (rd rn imm off)
  (adc64 rd rn (lnot (lshift imm off)) 1))

;; port: added, the flag-setting additions, the extended-register forms and
;; the additions and subtractions with carry
(defun ADDSWri (rd rn imm off) (adc32 rd rn (lshift imm off) 0))
(defun ADDSXri (rd rn imm off) (adc64 rd rn (lshift imm off) 0))
(defun ADDSWrs (rd rn rm off) (adc32 rd rn (shift-encoded rm off) 0))
(defun ADDSXrs (rd rn rm off) (adc64 rd rn (shift-encoded rm off) 0))

(defun ADDWrx (rd rn rm ext) (setw rd (+ rn (extended32 rm ext))))
(defun ADDXrx (rd rn rm ext) (set$ rd (+ rn (extended rm ext))))
(defun ADDXrx64 (rd rn rm ext) (set$ rd (+ rn (extended rm ext))))
(defun SUBWrx (rd rn rm ext) (setw rd (- rn (extended32 rm ext))))
(defun SUBXrx (rd rn rm ext) (set$ rd (- rn (extended rm ext))))
(defun ADDSWrx (rd rn rm ext) (adc32 rd rn (extended32 rm ext) 0))
(defun ADDSXrx (rd rn rm ext) (adc64 rd rn (extended rm ext) 0))
(defun ADDSXrx64 (rd rn rm ext) (adc64 rd rn (extended rm ext) 0))
(defun SUBSWrx (rd rn rm ext) (adc32 rd rn (lnot (extended32 rm ext)) 1))
(defun SUBSXrx (rd rn rm ext) (adc64 rd rn (lnot (extended rm ext)) 1))
(defun SUBSXrx64 (rd rn rm ext) (adc64 rd rn (lnot (extended rm ext)) 1))

(defun ADCWr (rd rn rm) (setw rd (+ rn rm (cast-unsigned 32 CF))))
(defun ADCXr (rd rn rm) (set$ rd (+ rn rm (cast-unsigned 64 CF))))
(defun SBCWr (rd rn rm) (setw rd (+ rn (lnot rm) (cast-unsigned 32 CF))))
(defun SBCXr (rd rn rm) (set$ rd (+ rn (lnot rm) (cast-unsigned 64 CF))))
(defun ADCSWr (rd rn rm) (adc32 rd rn rm CF))
(defun ADCSXr (rd rn rm) (adc64 rd rn rm CF))
(defun SBCSWr (rd rn rm) (adc32 rd rn (lnot rm) CF))
(defun SBCSXr (rd rn rm) (adc64 rd rn (lnot rm) CF))

(defun ADR (dst imm)
  "adr dst, imm ; port: added"
  (set$ dst (+ (get-program-counter) (cast-signed 64 imm))))

(defmacro Mop*rrr (set op rd rn rm ra)
  "(Mop*rrr set op rd rn rm ra) implements multiply-add, multiply-subtract
   etc with W or X registers. op is the binary operation used after *."
  (set rd (op ra (* rn rm))))

(defun MADDWrrr (rd rn rm ra) (Mop*rrr setw + rd rn rm ra))
(defun MADDXrrr (rd rn rm ra) (Mop*rrr set$ + rd rn rm ra))
(defun MSUBWrrr (rd rn rm ra) (Mop*rrr setw - rd rn rm ra))
(defun MSUBXrrr (rd rn rm ra) (Mop*rrr set$ - rd rn rm ra))

(defmacro *DIV*r (set div rd rn rm)
  "(*DIV*r set div rd rn rm) implements the SDIV or UDIV instructions
   on W or X registers, with div set to s/ or / respectively."
  (if (= rm 0)
    (set rd 0)
    (set rd (div rn rm))))

(defun SDIVWr (rd rn rm) (*DIV*r setw s/ rd rn rm))

;; port: added, the long and high multiplies
(defun SMADDLrrr (rd rn rm ra)
  (set$ rd (+ ra (* (cast-signed 64 rn) (cast-signed 64 rm)))))
(defun UMADDLrrr (rd rn rm ra)
  (set$ rd (+ ra (* (cast-unsigned 64 rn) (cast-unsigned 64 rm)))))
(defun SMSUBLrrr (rd rn rm ra)
  (set$ rd (- ra (* (cast-signed 64 rn) (cast-signed 64 rm)))))
(defun UMSUBLrrr (rd rn rm ra)
  (set$ rd (- ra (* (cast-unsigned 64 rn) (cast-unsigned 64 rm)))))
(defun SMULHrr (rd rn rm)
  (set$ rd (cast-high 64 (* (cast-signed 128 rn) (cast-signed 128 rm)))))
(defun UMULHrr (rd rn rm)
  (set$ rd (cast-high 64 (* (cast-unsigned 128 rn) (cast-unsigned 128 rm)))))
(defun SDIVXr (rd rn rm) (*DIV*r set$ s/ rd rn rm))
(defun UDIVWr (rd rn rm) (*DIV*r setw /  rd rn rm))
(defun UDIVXr (rd rn rm) (*DIV*r set$ /  rd rn rm))
