;;; tekengrootte-checkdoc.el --- Fail when checkdoc reports findings -*- lexical-binding: t -*-

;;; SPDX-License-Identifier: MIT
;;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;;; Commentary:

;;; Run by maak's `lint' task, from the project root:
;;;
;;; emacs -Q --batch -l test/tekengrootte-checkdoc.el
;;;
;;; Plain `checkdoc-file' only *reports* findings and always exits 0, so the
;;; gate would never bite.  Here we count findings ourselves and exit non-zero
;;; when there is at least one, turning checkdoc into a real quality gate.  The
;;; warnings are still printed, through the original reporting function.

;;; Code:

(require 'checkdoc)

(defconst tekengrootte-checkdoc-files
  '("tekengrootte.el" "test/tekengrootte-tests.el")
  "Files checked by this gate, relative to the project root.")

(let ((count 0)
      (original checkdoc-create-error-function))
  (setq checkdoc-create-error-function
    (lambda (text start end &optional unfixable)
      (setq count (1+ count))
      (funcall original text start end unfixable)))
  (dolist (file tekengrootte-checkdoc-files)
    (checkdoc-file file))
  (if (> count 0)
    (progn
      (message "checkdoc: %d finding(s) in %s" count
               (mapconcat #'identity tekengrootte-checkdoc-files " and "))
      (kill-emacs 1))
    (message "checkdoc: clean")))

;;; tekengrootte-checkdoc.el ends here
