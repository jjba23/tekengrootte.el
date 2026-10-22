;;; tekengrootte-checkdoc.el --- Fail when checkdoc reports findings -*- lexical-binding: t -*-

;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;; tekengrootte is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; tekengrootte is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with tekengrootte.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Run by maak's `lint' task, from the project root:
;;
;;   emacs -Q --batch -l test/tekengrootte-checkdoc.el
;;
;; Plain `checkdoc-file' only *reports* findings and always exits 0, so the
;; gate would never bite.  Here we count findings ourselves and exit non-zero
;; when there is at least one, turning checkdoc into a real quality gate.  The
;; warnings are still printed, through the original reporting function.

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
