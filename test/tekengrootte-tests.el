;;; tekengrootte-tests.el --- ERT tests for tekengrootte.el -*- lexical-binding: t -*-

;;; SPDX-License-Identifier: MIT
;;; Copyright © Josep Bigorra <jjbigorra@gmail.com>

;;; Author: Josep Bigorra <jjbigorra@gmail.com>
;;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;;; URL: https://github.com/jjba23/tekengrootte.el
;;; Package-Requires: ((emacs "25.1"))

;;; This file is not part of GNU Emacs.

;;; Commentary:

;;; ERT tests for tekengrootte.el.
;;;
;;; Run the whole suite from the project root with:
;;;
;;; maak test
;;;
;;; The README shows the equivalent batch invocation, as well as how to
;;; run a single test from within Emacs.

;;; Code:

(require 'ert)
(require 'cl-lib)
(require 'tekengrootte)

(defconst tekengrootte-tests--default-sizes
  '((nano . 0.7)
    (tiny . 0.8)
    (small . 0.9)
    (regular . 1.05)
    (large . 1.15)
    (larger . 1.25)
    (jumbo . 1.4)
    (colossal . 1.5))
  "Shipped `tekengrootte-sizes' value, as used by the tests.")

(defconst tekengrootte-tests--expected-names
  '("nano" "tiny" "small" "regular" "large" "larger" "jumbo" "colossal")
  "Expected `tekengrootte--size-names' result, smallest first.")

(defmacro tekengrootte-tests--with-defaults (&rest body)
  "Evaluate BODY with the shipped sizes and a pristine scale state.

Messages are inhibited, so the tests do not spam the batch output."
  (declare (indent 0) (debug t))
  `(let ((tekengrootte-scale 1.1)
         (tekengrootte-sizes tekengrootte-tests--default-sizes)
         (tekengrootte-set-scale-hook nil)
         (inhibit-message t))
     ,@body))

(defun tekengrootte-tests--approx-equal (a b)
  "Return non-nil when the numbers A and B differ by less than 1e-9."
  (< (abs (- a b)) 1e-9))

(ert-deftest tekengrootte-tests-defaults ()
  "The shipped defaults should be the documented ones."
  (should (equal tekengrootte-tests--default-sizes
                 (eval (car (get 'tekengrootte-sizes 'standard-value)))))
  (should (tekengrootte-tests--approx-equal
           1.1 (eval (car (get 'tekengrootte-scale 'standard-value))))))

(ert-deftest tekengrootte-tests-mk-font-size-relative ()
  "Relative heights are scaled and stay floats."
  (tekengrootte-tests--with-defaults
   (let ((scaled (tekengrootte-mk-font-size 1.2)))
     (should (floatp scaled))
     (should (tekengrootte-tests--approx-equal 1.32 scaled)))
   (let ((tekengrootte-scale 2.0))
     (should (tekengrootte-tests--approx-equal
              2.4 (tekengrootte-mk-font-size 1.2))))))

(ert-deftest tekengrootte-tests-mk-font-size-absolute ()
  "Absolute (integer) heights are scaled and rounded to integers."
  (tekengrootte-tests--with-defaults
   (should (integerp (tekengrootte-mk-font-size 114)))
   (should (= 125 (tekengrootte-mk-font-size 114)))
   (let ((tekengrootte-scale 1.5))
     (should (= 171 (tekengrootte-mk-font-size 114))))))

(ert-deftest tekengrootte-tests-set-scale-sets-value ()
  "`tekengrootte-set-scale' stores and returns the requested scale."
  (tekengrootte-tests--with-defaults
   (should (= 1.4 (tekengrootte-set-scale 'jumbo)))
   (should (= 1.4 tekengrootte-scale))
   (should (= 0.8 (tekengrootte-set-scale 'tiny)))
   (should (= 0.8 tekengrootte-scale))))

(ert-deftest tekengrootte-tests-set-scale-runs-hook ()
  "`tekengrootte-set-scale' runs the hook exactly once, after the change."
  (tekengrootte-tests--with-defaults
   (let ((calls 0)
         (scale-during-hook nil))
     (let ((tekengrootte-set-scale-hook
            (list (lambda ()
                    (setq calls (1+ calls)
                      scale-during-hook tekengrootte-scale)))))
       (tekengrootte-set-scale 'small))
     (should (= 1 calls))
     (should (= 0.9 scale-during-hook)))))

(ert-deftest tekengrootte-tests-set-scale-error-skips-hook ()
  "A rejected size runs no hook, so faces are not repainted needlessly."
  (tekengrootte-tests--with-defaults
   (let ((calls 0))
     (let ((tekengrootte-set-scale-hook
            (list (lambda () (setq calls (1+ calls))))))
       (should-error (tekengrootte-set-scale 'nonexistent) :type 'user-error))
     (should (= 0 calls)))))

(ert-deftest tekengrootte-tests-customize-runs-hook ()
  "Customize sets the scale through the same path, so it repaints too."
  (let ((tekengrootte-sizes tekengrootte-tests--default-sizes)
        (tekengrootte-set-scale-hook nil)
        (inhibit-message t)
        (previous tekengrootte-scale)
        (calls 0))
    (unwind-protect
        (progn
          (let ((tekengrootte-set-scale-hook
                 (list (lambda () (setq calls (1+ calls))))))
            (customize-set-variable 'tekengrootte-scale 1.6))
          (should (= 1.6 (default-value 'tekengrootte-scale)))
          (should (= 1 calls))
          ;; Setting the same value again repaints nothing.
          (let ((tekengrootte-set-scale-hook
                 (list (lambda () (setq calls (1+ calls))))))
            (customize-set-variable 'tekengrootte-scale 1.6))
          (should (= 1 calls)))
      (set-default 'tekengrootte-scale previous)
      (put 'tekengrootte-scale 'customized-value nil))))

(ert-deftest tekengrootte-tests-set-scale-unknown-signals ()
  "An unknown size signals a `user-error' and leaves the scale alone."
  (tekengrootte-tests--with-defaults
   (should-error (tekengrootte-set-scale 'nonexistent) :type 'user-error)
   (should (= 1.1 tekengrootte-scale))
   ;; The old behaviour was to store nil, which broke every later call.
   (should (tekengrootte-tests--approx-equal
            1.32 (tekengrootte-mk-font-size 1.2)))))

(ert-deftest tekengrootte-tests-set-scale-ignores-non-numeric-entry ()
  "A size whose multiplier is not a number is rejected."
  (tekengrootte-tests--with-defaults
   (let* ((tekengrootte-sizes (cons '(broken . "big") tekengrootte-sizes)))
     (should-error (tekengrootte-set-scale 'broken) :type 'user-error)
     (should (= 1.1 tekengrootte-scale)))))

(ert-deftest tekengrootte-tests-step-up-and-down ()
  "The step commands walk the sizes one at a time."
  (tekengrootte-tests--with-defaults
    (should (= 1.15 (tekengrootte-set-scale-increase)))
    (should (= 1.25 (tekengrootte-set-scale-increase)))
    (should (= 1.15 (tekengrootte-set-scale-decrease)))
    (should (= 1.05 (tekengrootte-set-scale-decrease)))))

(ert-deftest tekengrootte-tests-step-stops-at-the-ends ()
  "Stepping past the largest or smallest size changes nothing."
  (tekengrootte-tests--with-defaults
    (tekengrootte-set-scale 'colossal)
    (should (= 1.5 (tekengrootte-set-scale-increase)))
    (should (= 1.5 tekengrootte-scale))
    (tekengrootte-set-scale 'nano)
    (should (= 0.7 (tekengrootte-set-scale-decrease)))
    (should (= 0.7 tekengrootte-scale))))

(ert-deftest tekengrootte-tests-step-from-a-hand-set-scale ()
  "A scale set by hand steps to the nearest size on either side."
  (tekengrootte-tests--with-defaults
    (let ((tekengrootte-scale 3.0))
      (should (= 1.5 (tekengrootte-set-scale-decrease))))
    (let ((tekengrootte-scale 0.5))
      (should (= 0.7 (tekengrootte-set-scale-increase))))))

(ert-deftest tekengrootte-tests-size-names-are-sorted ()
  "Size names are reported from smallest to largest multiplier."
  (tekengrootte-tests--with-defaults
   (should (equal (mapcar #'symbol-name (tekengrootte--size-names))
                  tekengrootte-tests--expected-names))))

(ert-deftest tekengrootte-tests-size-names-skip-broken-entries ()
  "Entries without a numeric multiplier are not offered."
  (tekengrootte-tests--with-defaults
   (let ((tekengrootte-sizes '((broken . "big") (huge . 3.0) (tiny . 0.8))))
     (should (equal '(tiny huge) (tekengrootte--size-names))))))

(ert-deftest tekengrootte-tests-read-size ()
  "Interactive reading offers every size name and returns a symbol."
  (tekengrootte-tests--with-defaults
   (let (collection prompt)
     (cl-letf (((symbol-function 'completing-read)
                (lambda (p coll &rest _)
                  (setq prompt p collection coll)
                  "jumbo")))
       (should (eq 'jumbo (tekengrootte--read-size))))
     (should (equal tekengrootte-tests--expected-names collection))
     (should (stringp prompt)))))

(ert-deftest tekengrootte-tests-per-size-commands ()
  "Every shipped size has a command that selects it."
  (tekengrootte-tests--with-defaults
   (dolist (cell tekengrootte-tests--default-sizes)
     (let* ((name (car cell))
            (command (intern (format "tekengrootte-set-scale-%s" name))))
       (should (commandp command))
       (should (= (cdr cell) (call-interactively command)))
       (should (= (cdr cell) tekengrootte-scale))))))

(provide 'tekengrootte-tests)

;;; tekengrootte-tests.el ends here
