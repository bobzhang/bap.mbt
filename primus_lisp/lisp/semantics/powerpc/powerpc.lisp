(declare (context (target powerpc)))

(defpackage powerpc (:use core target))
(defpackage llvm-powerpc32 (:use powerpc))
;; port: upstream defines NOP outside of the powerpc package, so no
;; instruction ever resolves to it
(in-package powerpc)

(defun NOP ()
  (empty))
