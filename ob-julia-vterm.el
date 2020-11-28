;;; ob-julia-vterm.el --- Babel Fucntions for Julia in VTerm -*- lexical-binding: t -*-

;; Copyright (C) 2020 Shigeaki Nishina

;; Author: Shigeaki Nishina
;; Maintainer: Shigeaki Nishina
;; Created: October 31, 2020
;; URL: https://github.com/shg/ob-julia-vterm.el
;; Package-Requires: ((emacs "25.1") (julia-vterm "0.10"))
;; Version: 0.1
;; Keywords: julia, Org, literate programming, reproducible research

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see https://www.gnu.org/licenses/.

;;; Commentary:

;; 

;;; Usage:

;; 

;;; Code:

(require 'ob)
(require 'org-macs)
(require 'julia-vterm)

(add-to-list 'org-src-lang-modes '("julia-vterm" . "julia"))

(defun org-babel-julia-vterm--make-src (result-type with-session body)
  "RESULT-TYPE WITH-SESSION BODY."
  (concat
   (if (eq result-type 'output)
       "_julia_vterm_output = @capture_out " "_julia_vterm_output = ")
   (if with-session
       "begin\n" "let\n")
   body
   "\nend\n"))

(defun org-babel-julia-vterm--make-str-to-run (src-file out-file)
  "SRC-FILE OUT-FILE."
  (format "using Suppressor; include(\"%s\");  open(\"%s\", \"w\") do file; print(file, _julia_vterm_output); end\n" src-file out-file))

(unless (fboundp 'org-babel-execute:julia)
  (defalias 'org-babel-execute:julia 'org-babel-execute:julia-vterm))

(defun org-babel-execute:julia-vterm (body params)
  "Execute a block of Julia code with Babel.
This function is called by `org-babel-execute-src-block'.
BODY is the contents and PARAMS are header arguments of the code block."
  (let* ((session (cdr (assq :session params)))
	 (result-params (cdr (assq :result-params params)))
	 (result-type (cdr (assq :result-type params)))
	 (full-body (org-babel-expand-body:generic body params)))
    (org-babel-julia-vterm-evaluate session full-body result-type result-params)))

(defun org-babel-julia-vterm-evaluate (session body result-type result-params)
  "Evaluate BODY as Julia code in a julia-vterm buffer specified with SESSION."
  (let ((src-file (org-babel-temp-file "julia-vterm-src-"))
	(out-file (org-babel-temp-file "julia-vterm-out-"))
	(src (org-babel-julia-vterm--make-src result-type (not (string= session "none")) body)))
    (with-temp-file src-file (insert src))
    (julia-vterm-paste-string
     (org-babel-julia-vterm--make-str-to-run src-file out-file)
     (if (string= session "none") nil session))
    (while (= 0 (file-attribute-size (file-attributes out-file)))
      (sit-for 0.1))
    (let ((result (with-temp-buffer (insert-file-contents out-file) (buffer-string))))
      result)))

(provide 'ob-julia-vterm)

;;; ob-julia-vterm.el ends here
