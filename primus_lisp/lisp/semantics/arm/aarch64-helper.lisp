;; Helper functions specific to aarch64.
(declare (context (target arm-family)
                  (bits 64)))

(in-package aarch64)

(require bits)
(require arm-bits)

(defun word () (word-width))

(defun shift-encoded (rm off)
  "(shift-encoded rm off) decodes the 8-bit shift value
   into its type and offset, and shifts rm accordingly."
  (let ((typ (extract 7 6 off))
        (off (extract 5 0 off)))
    (case typ
      0b00 (lshift rm off)
      0b01 (rshift rm off)
      0b10 (arshift rm off)
      0b11 (rotate-right rm off)
      )))

(defun unsigned-extend (n rm)
  "(unsigned-extend n rm) returns the unsigned extension (prepend with zeros)
   of the lowest n bits of rm."
  (cast-unsigned (word-width) (cast-low n rm)))

(defun signed-extend (n rm)
  "(signed-extend n rm) returns the signed extension (prepend with rm[n-1])
   of the lowest n bits of rm."
  (cast-signed (word-width) (cast-low n rm)))

(defun extended (rm bits)
  "(extended rm bits) decodes the extension type and amount from bits,
   and returns the value of the extension on rm."
  (let ((typ (extract 5 3 bits))
        (off (extract 2 0 bits)))
    (lshift (case typ
              0b000 (unsigned-extend 8 rm)
              0b001 (unsigned-extend 16 rm)
              0b010 (unsigned-extend 32 rm)
              0b011 rm
              0b100 (signed-extend 8 rm)
              0b101 (signed-extend 16 rm)
              0b110 (signed-extend 32 rm)
              0b111 rm)
            off)))

(defun decode-bit-masks (immN imms immr immediate register-width)
  "(decode-bit-masks immN imms immr immediate register-width) returns the immediate value
   corresponding to the immN:immr:imms bit pattern within opcodes of
   ARMv8 logical operation instructions like AND, ORR etc.
   register-width denotes the width of the registers to be acted on (32 or 64).
   I'm not sure what the immediate parameter does, but it's nearly always
   called with true.
   Modified from ARMv8 ISA pseudocode."
  (let ((len (- 64 (clz (cast-unsigned 64 (concat immN (lnot imms)))) 1))
        (levels (cast-unsigned 6 (ones len)))
        (S (logand imms levels))
        (R (logand immr levels))
        (diff (- S R))) ; assuming "6-bit subtract with borrow" is regular 2'c subtraction
    (assert-msg (>= len 1) "decode-bit-masks len < 1")
    (assert-msg (not (and immediate (= levels (logand imms levels)))) "decode-bit-masks long condition")
    (let ((esize (lshift 1 len))
          (d (extract (- len 1) 0 diff))
          (welem (cast-unsigned esize (ones (+ S 1))))
          (telem (cast-unsigned esize (ones (+ d 1))))
          (wmask (replicate-to-fill (rotate-right welem R) register-width))
          (tmask (replicate-to-fill telem register-width)))
      ; it seems like wmask is for logical immediates, and tmask is not used
      ; anywhere in the ISA except for the BFM instruction and its aliases.
      ; we're just returning wmask here.
      wmask)))

(defun immediate-from-bitmask (mask register-width)
  "(immediate-from-bitmask mask register-width) returns the immediate value corresponding to
   the given 13-bit mask in the form of N:immr:imms.
   register-width denotes the width of the registers to be acted on (32 or 64)."
  (let ((N (select 12 mask))
        (immr (extract 11 6 mask))
        (imms (extract 5 0 mask)))
    (decode-bit-masks N imms immr true register-width)))

(defun barrier-option-to-symbol (option)
  "(barrier-option-to-symbol option) converts the
   4-bit optional value to a symbol.
   This is to be used with the (special) primitive."
  (case option
    0b1111 :sy
    0b1110 :st
    0b1101 :ld
    0b1011 :ish
    0b1010 :ishst
    0b1001 :ishld
    0b0111 :nsh
    0b0110 :nshst
    0b0101 :nshld
    0b0011 :osh
    0b0010 :oshst
    0b0001 :oshld
    :unknown))

;; port: added helpers of the semantics added or fixed by the port

(defun adc64 (rd x y c)
  "(adc64 rd x y c) sets the X register rd to x + y + c and the flags."
  (adc64/ rd (cast-low 64 x) (cast-low 64 y) (cast-unsigned 64 c)))

(defun adc64/ (rd x y c)
  (let ((r (+ x y c)))
    (set-nzcv-from-registers r x y)
    (set$ rd r)))

(defun adc32 (rd x y c)
  "(adc32 rd x y c) sets the W register rd to x + y + c (low words) and
   the flags."
  (adc32/ rd (cast-low 32 x) (cast-low 32 y) (cast-unsigned 32 c)))

(defun adc32/ (rd x y c)
  (let ((r (+ x y c)))
    (set-nzcv-from-registers r x y)
    (setw rd r)))

(defun set-nzcv-of-sum (x y c)
  "sets the flags of x + y + c computed at the width of x"
  (set-nzcv-of-sum/ x (cast-low (word-width x) y) (cast-unsigned (word-width x) c)))

(defun set-nzcv-of-sum/ (x y c)
  (set-nzcv-from-registers (+ x y c) x y))

(defun set-nz-cv0 (r)
  "sets N and Z from r and clears C and V (logical flag-setting forms)"
  (set NF (msb r))
  (set ZF (is-zero r))
  (set CF 0:1)
  (set VF 0:1))

(defun extended32 (rm bits)
  "(extended32 rm bits) is the extended register operand of a W form"
  (cast-low 32 (extended rm bits)))

(defun mem-extend (rm signed shift scale)
  "(mem-extend rm signed shift scale) is the register offset of the
   register-offset loads and stores: rm (a W register is sign- or
   zero-extended to 64 bits) shifted left by scale when shift is set."
  (lshift (if signed (cast-signed 64 rm) (cast-unsigned 64 rm))
          (if (= shift 1) scale 0)))

(defun reverse-bits64 (x)
  (let ((x (logor (rshift (logand x 0xAAAAAAAAAAAAAAAA) 1)
                  (lshift (logand x 0x5555555555555555) 1)))
        (x (logor (rshift (logand x 0xCCCCCCCCCCCCCCCC) 2)
                  (lshift (logand x 0x3333333333333333) 2)))
        (x (logor (rshift (logand x 0xF0F0F0F0F0F0F0F0) 4)
                  (lshift (logand x 0x0F0F0F0F0F0F0F0F) 4))))
    (reverse-bytes64 x)))

(defun reverse-bits32 (x)
  (let ((x (logor (rshift (logand x 0xAAAAAAAA) 1)
                  (lshift (logand x 0x55555555) 1)))
        (x (logor (rshift (logand x 0xCCCCCCCC) 2)
                  (lshift (logand x 0x33333333) 2)))
        (x (logor (rshift (logand x 0xF0F0F0F0) 4)
                  (lshift (logand x 0x0F0F0F0F) 4))))
    (reverse-bytes32 x)))

(defun reverse-bytes64 (x)
  (concat (extract 7 0 x) (extract 15 8 x) (extract 23 16 x) (extract 31 24 x)
          (extract 39 32 x) (extract 47 40 x) (extract 55 48 x) (extract 63 56 x)))

(defun reverse-bytes32 (x)
  (concat (extract 7 0 x) (extract 15 8 x) (extract 23 16 x) (extract 31 24 x)))

(defun reverse-halfword-bytes (x)
  "swaps the bytes of each halfword of x (32 or 64 bits)"
  (if (= (word-width x) 64)
      (concat (extract 55 48 x) (extract 63 56 x) (extract 39 32 x) (extract 47 40 x)
              (extract 23 16 x) (extract 31 24 x) (extract 7 0 x) (extract 15 8 x))
    (concat (extract 23 16 x) (extract 31 24 x) (extract 7 0 x) (extract 15 8 x))))

(defun count-leading-sign-bits (x)
  "the number of bits below the most significant one equal to it"
  (- (clz (rshift (logxor x (lshift x 1)) 1)) 1))
