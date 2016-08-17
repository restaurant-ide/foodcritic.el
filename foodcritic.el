;;; foodcritic.el --- An Emacs interface for Foodcritic -*- lexical-binding: t -*-

;; Copyright © 2016 Alexander aka 'CosmonauT' Vynnyk

;; Author: Alexander aka 'CosmonauT' Vynnyk
;; URL: https://github.com/restaurant-ide/foodcritic.el
;; Version: 0.1.0
;; Keywords: project, convenience
;; Package-Requires: ((dash "1.0.0") (emacs "24"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library allows the user to easily invoke foodcritic to get feedback
;; about stylistic issues in Ruby code.
;;
;;; Code:

(require 'dash)
(require 'tramp)

(defgroup foodcritic nil
  "An Emacs interface for Foodcritic."
  :group 'tools
  :group 'convenience)

(defvar foodcritic-project-root-files
  '(".projectile" "metadata.rb" "Berksfile" "Gemfile" ".git" ".hg" ".bzr" "_darcs")
  "A list of files considered to mark the root of a project.")

(defcustom foodcritic-ignore-tags nil
  "The command used to run Foodcritic checks."
  :group 'foodcritic
  :type 'string)

(defcustom foodcritic-check-command
  (concat "foodcritic"
	  (if foodcritic-ignore-tags "-t" ""))
  "The command used to run Foodcritic checks."
  :group 'foodcritic
  :type 'string)

(defcustom foodcritic-keymap-prefix (kbd "C-c C-f")
  "Foodcritic keymap prefix."
  :group 'foodcritic
  :type 'string)

;; (defun foodcritic-colorize-compilation-buffer ()
;;   (toggle-read-only)
;;   (ansi-color-apply-on-region compilation-filter-start (point))
;;   (toggle-read-only))

;; (define-compilation-mode foodcritic-compilation-mode "Foodcritic Compilation"
;;   "Compilation mode for RSpec output."
;;   (add-hook 'compilation-filter-hook 'foodcritic-colorize-compilation-buffer nil t))

;; (add-to-list 'compilation-error-regexp-alist 'foodcritic)
;; (add-to-list 'compilation-error-regexp-alist-alist (cons 'foodcritic "^FC[0-9].*\\:.*"))

(defun foodcritic-local-file-name (file-name)
  "Retrieve local filename if FILE-NAME is opened via TRAMP."
  (cond ((tramp-tramp-file-p file-name)
         (tramp-file-name-localname (tramp-dissect-file-name file-name)))
        (t
         file-name)))

(defun foodcritic-project-root ()
  "Retrieve the root directory of a project if available.
The current directory is assumed to be the project's root otherwise."
  (or (->> foodcritic-project-root-files
        (--map (locate-dominating-file default-directory it))
        (-remove #'null)
        (car))
      (error "You're not into a project")))

(defun foodcritic-buffer-name (file-or-dir)
  "Generate a name for the Foodcritic buffer from FILE-OR-DIR."
  (concat "*Foodcritic " file-or-dir "*"))

(defun foodcritic--dir-command (command &optional directory)
  "Run COMMAND on DIRECTORY (if present).
Alternatively prompt user for directory."
  (foodcritic-ensure-installed)
  (let ((directory
         (or directory
             (read-directory-name "Select directory:"))))
    (compilation-start
     (concat command " " (foodcritic-local-file-name directory))
     'compilation-mode
     (lambda (arg) (message arg) (foodcritic-buffer-name directory)))))

;;;###autoload
(defun foodcritic-check-project ()
  "Run on current project."
  (interactive)
  (foodcritic-check-directory (foodcritic-project-root)))

;;;###autoload
(defun foodcritic-check-directory (&optional directory)
  "Run on DIRECTORY if present.
Alternatively prompt user for directory."
  (interactive)
  (foodcritic--dir-command foodcritic-check-command directory))

(defun foodcritic--file-command (command)
  "Run COMMAND on currently visited file."
  (foodcritic-ensure-installed)
  (let ((file-name (buffer-file-name (current-buffer))))
    (if file-name
        (compilation-start
         (concat command " " (foodcritic-local-file-name file-name))
         'compilation-mode
         (lambda (_arg) (foodcritic-buffer-name file-name)))
      (error "Buffer is not visiting a file"))))

;;;###autoload
(defun foodcritic-check-current-file ()
  "Run on current file."
  (interactive)
  (foodcritic--file-command foodcritic-check-command))

(defun foodcritic-ensure-installed ()
  "Check if Foodcritic is installed."
  (unless (executable-find "foodcritic")
    (error "Foodcritic is not installed")))

;;; Minor mode
(defvar foodcritic-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "p") 'foodcritic-check-project)
      (define-key prefix-map (kbd "d") 'foodcritic-check-directory)
      (define-key prefix-map (kbd "f") 'foodcritic-check-current-file)
      
      (define-key map foodcritic-keymap-prefix prefix-map))
    map)
  "Keymap for Foodcritic mode.")

;;;###autoload
(define-minor-mode foodcritic-mode
  "Minor mode to interface with Foodcritic."
  :lighter " Foodcritic"
  :keymap foodcritic-mode-map
  :group 'foodcritic)

(provide 'foodcritic)

;;; foodcritic.el ends here
