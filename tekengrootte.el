;;; tekengrootte.el --- Proportionally sized faces -*- lexical-binding: t -*-

;; Copyright (C) 2024 Free Software Foundation, Inc.

;; Version: 0.1.3
;; Author: Josep Bigorra <jjbigorra@gmail.com>
;; Maintainer: Josep Bigorra <jjbigorra@gmail.com>
;; URL: https://codeberg.org/jjba23/tekengrootte.el
;; Keywords: faces
;; Package: tekengrootte
;; Package-Requires: ((emacs "25.1"))

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TODO

;;; Code:

(defgroup tekengrootte ()
  "Tekengrootte customization group."
  :group 'tools)

(defcustom tekengrootte-scale 1.1
  "Tekengrootte scale to multiply."
  :type 'number
  :group 'tekengrootte)

(defcustom tekengrootte-set-scale-hook nil
  "Hooks to be run upon changing the text scale."
  :type 'hook
  :group 'tekengrootte)


(defcustom tekengrootte-sizes
  '(
    (nano . 0.7)
    (tiny . 0.8)
    (small . 0.9)
    (regular . 1.05)
    (large . 1.15)
    (larger . 1.25)
    (jumbo . 1.4)
    (colossal . 1.5)
    (t . 1.1))
  "Tekengrootte sizes for scaling."
  :type 'alist
  :group 'tekengrootte)

(defun tekengrootte-mk-font-size (x)
  "Adapt a font size to a scaled Emacs compatible one.
X is the numeric size to be adjusted to the right tekengrootte."
  (interactive)
  (* tekengrootte-scale x))

(defun tekengrootte-set-scale-colossal ()
  "Set the font scale to the 'colossal' size."
  (interactive)
  (tekengrootte-set-scale 'colossal))

(defun tekengrootte-set-scale-jumbo ()
  "Set the font scale to the 'jumbo' size."
  (interactive)
  (tekengrootte-set-scale 'jumbo))

(defun tekengrootte-set-scale-larger ()
  "Set the font scale to the 'larger' size."
  (interactive)
  (tekengrootte-set-scale 'larger))

(defun tekengrootte-set-scale-large ()
  "Set the font scale to the 'large' size."
  (interactive)
  (tekengrootte-set-scale 'large))

(defun tekengrootte-set-scale-regular ()
  "Set the font scale to the 'regular' size."
  (interactive)
  (tekengrootte-set-scale 'regular))

(defun tekengrootte-set-scale-small ()
  "Set the font scale to the 'small' size."
  (interactive)
  (tekengrootte-set-scale 'small))

(defun tekengrootte-set-scale-tiny ()
  "Set the font scale to the 'tiny' size."
  (interactive)
  (tekengrootte-set-scale 'tiny))

(defun tekengrootte-set-scale-nano ()
  "Set the font scale to the 'nano' size."
  (interactive)
  (tekengrootte-set-scale 'nano))

(defun tekengrootte-set-scale (k)
  "Set the font scale to the size associated with key K."
  (interactive)
  (let ((fs (alist-get k tekengrootte-sizes)))
    (message (format "setting font scale to %s: * %s" k fs))
    (setq tekengrootte-scale fs)
    (run-hooks 'tekengrootte-set-scale-hook)))

(provide 'tekengrootte)

;;; tekengrootte.el ends here
