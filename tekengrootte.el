;;; tekengrootte.el --- Proportionally scaled face sizes -*- lexical-binding: t -*-

;; Copyright (C) 2024-2026 Josep Bigorra <jjbigorra@gmail.com>

;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; Version: 0.2.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: faces, convenience
;; URL: https://codeberg.org/jjba23/tekengrootte.el

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; tekengrootte ("character size" in Dutch) keeps face heights
;; proportional to a single, adjustable scale.
;;
;; Instead of hard-coding a face height such as 1.3, express it as a
;; multiple of the current scale:
;;
;;   (set-face-attribute 'org-level-1 nil
;;                       :height (tekengrootte-mk-font-size 1.2))
;;
;; When the scale is then changed with `tekengrootte-set-scale' (or with
;; one of the `tekengrootte-set-scale-NAME' commands), every face set up
;; this way grows or shrinks along with it.  The available sizes and
;; their multipliers live in `tekengrootte-sizes'.
;;
;; Faces are not re-applied automatically, so hook your face-setting
;; function to `tekengrootte-set-scale-hook':
;;
;;   (defun my/set-faces ()
;;     (set-face-attribute 'default nil
;;                         :height (tekengrootte-mk-font-size 114)))
;;
;;   (add-hook 'tekengrootte-set-scale-hook #'my/set-faces)

;;; Code:

(defgroup tekengrootte nil
  "Proportionally scaled face sizes."
  :group 'faces
  :prefix "tekengrootte-"
  :link '(url-link "https://codeberg.org/jjba23/tekengrootte.el"))

(defcustom tekengrootte-scale 1.1
  "Current multiplier used by `tekengrootte-mk-font-size'.

Use `tekengrootte-set-scale' to set this to the multiplier of one
of the sizes in `tekengrootte-sizes'."
  :type 'number
  :group 'tekengrootte)

(defcustom tekengrootte-sizes
  '((nano . 0.7)
    (tiny . 0.8)
    (small . 0.9)
    (regular . 1.05)
    (large . 1.15)
    (larger . 1.25)
    (jumbo . 1.4)
    (colossal . 1.5))
  "Available size names and their multipliers.

Each element is a cons cell of a size name (a symbol) and a
number.  The names are offered with completion by
`tekengrootte-set-scale', and each of them also has a matching
`tekengrootte-set-scale-NAME' command.

Add your own entries to taste; a name whose multiplier is not a
number is ignored."
  :type '(alist :key-type symbol :value-type number)
  :group 'tekengrootte)

(defcustom tekengrootte-set-scale-hook nil
  "Hook run after the scale has been changed.

It is run by `tekengrootte-set-scale', which see.  Use it to
re-apply face heights computed with `tekengrootte-mk-font-size'."
  :type 'hook
  :group 'tekengrootte)

(defun tekengrootte--sizes ()
  "Return the usable entries of `tekengrootte-sizes'.

Entries whose multiplier is not a number are dropped, and the
remaining entries are sorted by ascending multiplier."
  (let (sizes)
    (dolist (cell tekengrootte-sizes)
      (when (numberp (cdr cell))
        (push cell sizes)))
    (sort sizes (lambda (a b) (< (cdr a) (cdr b))))))

(defun tekengrootte--size-names ()
  "Return the names of the usable sizes, from smallest to largest."
  (mapcar #'car (tekengrootte--sizes)))

(defun tekengrootte--size-scale (size)
  "Return the multiplier that `tekengrootte-sizes' defines for SIZE.

Signal a `user-error' when SIZE is not a usable size name."
  (let ((scale (cdr (assq size tekengrootte-sizes))))
    (unless (numberp scale)
      (user-error "Unknown tekengrootte size: %S (expected one of %s)"
                  size
                  (mapconcat #'symbol-name (tekengrootte--size-names) ", ")))
    scale))

(defun tekengrootte--read-size ()
  "Read a size name from `tekengrootte-sizes' and return it as a symbol."
  (intern (completing-read "Font scale: "
                           (mapcar #'symbol-name (tekengrootte--size-names))
                           nil t)))

(defun tekengrootte-mk-font-size (size)
  "Return SIZE scaled by the current `tekengrootte-scale'.

SIZE is an unscaled height, in the same units as the `:height'
face attribute.  When SIZE is an integer the result is rounded to
an integer too, so that absolute heights remain valid:

  (tekengrootte-mk-font-size 114)

Relative heights are returned as floats:

  (tekengrootte-mk-font-size 1.2)"
  (if (integerp size)
      (round (* tekengrootte-scale size))
    (* tekengrootte-scale size)))

;;;###autoload
(defun tekengrootte-set-scale (size)
  "Set `tekengrootte-scale' to the multiplier configured for SIZE.

SIZE is a size name from `tekengrootte-sizes', such as `tiny' or
`colossal'.  Interactively, SIZE is read with completion, so size
names you added yourself are offered as well.

Return the new scale, after running `tekengrootte-set-scale-hook'.
Signal a `user-error' when SIZE has no numeric multiplier, leaving
the current scale untouched."
  (interactive (list (tekengrootte--read-size)))
  (let ((scale (tekengrootte--size-scale size)))
    (setq tekengrootte-scale scale)
    (message "tekengrootte scale: %s (%sx)" size scale)
    (run-hooks 'tekengrootte-set-scale-hook)
    scale))

;;;###autoload
(defun tekengrootte-set-scale-colossal ()
  "Set the font scale to the `colossal' size."
  (interactive)
  (tekengrootte-set-scale 'colossal))

;;;###autoload
(defun tekengrootte-set-scale-jumbo ()
  "Set the font scale to the `jumbo' size."
  (interactive)
  (tekengrootte-set-scale 'jumbo))

;;;###autoload
(defun tekengrootte-set-scale-larger ()
  "Set the font scale to the `larger' size."
  (interactive)
  (tekengrootte-set-scale 'larger))

;;;###autoload
(defun tekengrootte-set-scale-large ()
  "Set the font scale to the `large' size."
  (interactive)
  (tekengrootte-set-scale 'large))

;;;###autoload
(defun tekengrootte-set-scale-regular ()
  "Set the font scale to the `regular' size."
  (interactive)
  (tekengrootte-set-scale 'regular))

;;;###autoload
(defun tekengrootte-set-scale-small ()
  "Set the font scale to the `small' size."
  (interactive)
  (tekengrootte-set-scale 'small))

;;;###autoload
(defun tekengrootte-set-scale-tiny ()
  "Set the font scale to the `tiny' size."
  (interactive)
  (tekengrootte-set-scale 'tiny))

;;;###autoload
(defun tekengrootte-set-scale-nano ()
  "Set the font scale to the `nano' size."
  (interactive)
  (tekengrootte-set-scale 'nano))

;;; History:

;; 0.2.0  Signal an error for unknown sizes instead of storing nil,
;;        read the size with completion, round integer heights,
;;        autoload all commands, add tests and a Makefile.
;; 0.1.1  First published version.

(provide 'tekengrootte)

;;; tekengrootte.el ends here
