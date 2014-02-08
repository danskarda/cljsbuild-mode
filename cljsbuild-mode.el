;;; cljsbuild-mode.el --- A minor mode for the ClojureScript 'lein cljsbuild' command

;; Copyright 2012 Kototama

;; Authors: Kototama <kototamo gmail com>
;; Version: 0.2.0
;; Package-version: 0.2.0
;; Keywords: clojure, clojurescript, leiningen, compilation
;; URL: http://github.com/kototama/cljsbuild-mode

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;; An Emacs minor mode for the ClojureScript 'lein cljsbuild' command
;; that will automatically watch the compilation buffer, pops it when the
;; compilation failed and (optionally) hides it when the compilation
;; succeed.

;; Installation:
;;
;; Packages are available in the Marmalade and MELPA repositories.
;; Install the mode with "M-x package-install RET cljsbuild-mode".
;;
;; Usage:
;;
;; 1. M-x cljsbuild-auto
;; 2. Enjoy!
;;
;; This version of cljsbuild-mode is based on compilation-mode for Emacs
;; You can use C-x ` hotkeys to advance to errors etc.

(require 'ansi-color)
(require 'compile)

(defgroup cljsbuild-mode nil
  "A helper mode for running 'lein cljsbuild' within Emacs."
  :prefix "cljsbuild-"
  :group 'applications)

;;;###autoload
(define-derived-mode cljsbuild-mode compilation-mode "CljsBuild"
  "ClojureScript Build mode"
  :init-value nil
  :group 'cljsbuild-mode

  (make-variable-buffer-local 'compilation-error-regexp-alist)
  (setq compilation-error-regexp-alist cljsbuild-error-regexp-alist)
  (add-hook 'compilation-filter-hook 'cljsbuild-compilation-filter nil t))

(defcustom cljsbuild-verbose t
  "When non-nil, provide progress feedback in the minibuffer."
  :type 'boolean
  :group 'cljsbuild-mode)

(defcustom cljsbuild-show-buffer-function 'display-buffer
  "A function to use to show a compilation buffer")

(defcustom cljsbuild-show-buffer-on-failure t
  "When non-nil, pop up the build buffer when failures are seen."
  :type 'boolean
  :group 'cljsbuild-mode)

(defcustom cljsbuild-hide-buffer-on-success nil
  "When non-nil, hide the build buffer when a build succeeds."
  :type 'boolean
  :group 'cljsbuild-mode)

(defcustom cljsbuild-show-buffer-on-warnings t
  "When non-nil, pop up the build buffer when warnings are seen."
  :type 'boolean
  :group 'cljsbuild-mode)

(defcustom cljsbuild-compilation-command "lein cljsbuild auto"
  "Default cljsbuild compilation command"
  :type 'boolean
  :group 'cljsbuild-mode)

(defvar cljsbuild-error-regexp-alist
  '(("^\\(ERROR\\): .* at line \\(\\([0-9]+\\) \\(.*\\)\\)$"
     4 3 nil 2 2)
    ("^\\(WARNING\\): .* at line \\(\\([0-9]+\\) \\(.*\\)$\\)"
     4 3 nil 1 2))
  "Error matching expression for `compilation-error-regexp-alist'")

(defun cljsbuild-message (format-string &rest args)
  "Pass FORMAT-STRING and ARGS through to `message' if `cljsbuild-verbose' is non-nil."
  (when cljsbuild-verbose
    (apply #'message format-string args)))

(defun cljsbuild-compilation-filter (&rest args)
  (let* ((inhibit-read-only t)
	 (begin		    compilation-filter-start)
 	 (inserted	    (buffer-substring-no-properties begin (point)))
	 (buffer-visible    (get-buffer-window (buffer-name) 'visible)))
    (ansi-color-apply-on-region begin (point))
    (cond ((string-match "^Successfully compiled" inserted)
           (cljsbuild-message "Cljsbuild compilation success")
           (when cljsbuild-hide-buffer-on-success
             ;; hides the compilation buffer
             (delete-windows-on (buffer-name))))
          ((string-match "^Compiling.+failed.$" inserted)
           (cljsbuild-message "Cljsbuild compilation failure")
           (when (and (not buffer-visible) cljsbuild-show-buffer-on-failure)
             ;; if the compilation buffer is not visible, shows it
             (funcall cljsbuild-show-buffer-function (buffer-name))))
          ((string-match "^WARNING:" inserted)
           (cljsbuild-message "Cljsbuild compilation warning")
           (when (and (not buffer-visible) cljsbuild-show-buffer-on-warnings)
             (funcall cljsbuild-show-buffer-function (buffer-name) t))))))

(defun cljsbuild-run (command)
  (let ((default-directory (or (locate-dominating-file default-directory "project.clj")
			       (error "Cannot locate project.clj"))))
    (compilation-start command 'cljsbuild-mode
		       nil compilation-highlight-regexp)))

(defun cljsbuild-compile (command)
  (interactive (list
		(if current-prefix-arg
		    (compilation-read-command cljsbuild-compilation-command)
		  cljsbuild-compilation-command)))
  (cljsbuild-run command)
  (setq cljsbuild-compilation-command command))

(defun cljsbuild-clean ()
  (interactive)
  (cljbsuild-run "lein cljsbuild clean"))

(defalias 'cljsbuild-auto 'cljsbuild-compile)

(provide 'cljsbuild-mode)

;;; cljsbuild-mode.el ends here
