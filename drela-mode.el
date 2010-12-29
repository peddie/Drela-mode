;;; drela-mode.el --- mode for editing files used in Drela's aerodynamic codes

;; Copyright (C) 2010, Kenneth Jensen.

;; Author: Kenneth Jensen <kjensen@alum.mit.edu>
;; Keywords: aerodynamics, AVL

;;; Commentary:

;; This is a major mode for editing files used in Drela's aerodynamic
;; codes.  The mode supports syntax highlighting, easy tabbing through
;; and indentation of data elements, and other features.  This version
;; only supports AVL.  Future versions will support other Drela codes.

;;; Code:


(defgroup avl nil
  "Major mode for editing AVL (.avl) files."
  :group 'languages)


(defcustom avl-indent-level 10
  "Indentation between number fields"
  :type 'integer
  :group 'avl)


(defvar avl-mode-map ()
  "Keymap used in AVL mode.")
(if (null avl-mode-map)
    (progn
      (setq avl-mode-map (make-sparse-keymap))
      (set-keymap-name avl-mode-map 'avl-mode-map)
      (define-key avl-mode-map "\t" 'avl-indent-command)
      (define-key avl-mode-map [(control return)] 'avl-insert-standard-comment)
      (define-key avl-mode-map [(control shift return)] 'avl-uninsert-comment)
      (define-key avl-mode-map [(shift tab)] 'avl-unindent-command)))


(defvar avl-mode-syntax-table nil
  "Syntax table in use in avl-mode buffers.")
(if (null avl-mode-syntax-table)
    (progn
      (setq avl-mode-syntax-table (make-syntax-table))
      (modify-syntax-entry ?\n ">" avl-mode-syntax-table)
      (modify-syntax-entry ?\f ">" avl-mode-syntax-table)
      (modify-syntax-entry ?\# "<" avl-mode-syntax-table)
      (modify-syntax-entry ?! "<" avl-mode-syntax-table)))


(defcustom avl-mode-hook nil
  "Hook run on entry to AVL mode."
  :type 'hook
  :group 'avl)


(defvar avl-standard-comments
  '(("^ *[Ss][Es][Cc][Tt][^ \n]*"  "#Xle     Yle     Zle     Chord   Ainc    [Nspan]   [Sspace]")
    ("^ *[Cc][Oo][Nn][Tt][^ \n]*"  "#name    gain    Xhinge  Xhvec   Yhvec   Zhvec     SgnDup" )
    ("^ *[Cc][Dd][Cc][Ll][^ \n]*"  "#CL1   CD1   CL2   CD2   CL3   CD3" )
    ("^ *[Ss][Uu][Rr][Ff][^\n]*\n[^\n]*"  "#Nchord  Cspace   [Nspan]  [Sspace]")
    ("^ *[Sc][Cc][Aa][Ll][^ \n]*"  "#Xscale   Yscale   Zscale")
    ("^ *[Tt][Rr][Aa][Nn][^ \n]*"  "#dX   dY   dZ")
    ("^ *[Bb][Oo][Dd][Yy][^ \n]*"  "#Nbody   Bspace")))


(defvar avl-keyword-list
  '(; Section headings
    "^ *[Ss][Uu][Rr][Ff][^ \n]*" 
    "^ *[Ii][Nn][Dd][Ee][^ \n]*" 
    "^ *[Yy][Dd][Uu][Pp][^ \n]*" 
    "^ *[Ss][Cc][Aa][Ll][^ \n]*" 
    "^ *[Tt][Rr][Aa][Nn][^ \n]*" 
    "^ *[Aa][Nn][Gg][Ll][^ \n]*" 
    "^ *[Ss][Es][Cc][Tt][^ \n]*" 
    "^ *[Nn][Aa][Cc][Aa][^ \n]*" 
    "^ *[Aa][Ii][Rr][Ff][^ \n]*" 
    "^ *[Cc][Ll][Aa][Ff][^ \n]*" 
    "^ *[Cc][Dd][Cc][Ll][^ \n]*" 
    "^ *[Aa][Ff][Ii][Ll][^ \n]*" 
    "^ *[Cc][Oo][Nn][Tt][^ \n]*" 
    "^ *[Bb][Oo][Dd][Yy][^ \n]*" 
    "^ *[Bb][Ff][Ii][Ll][^ \n]*" 
    "^ *[Dd][Ee][Ss][Ii][^ \n]*"))


(defvar avl-last-point nil
  "The point before the last command")
(if (null avl-last-point)
    (make-variable-buffer-local 'avl-last-point))


(defvar avl-use-wide-fontify-buffer nil
  "Widen the fontify buffer for items that require multiline regexps")
(if (null avl-use-wide-fontify-buffer)
    (make-variable-buffer-local 'avl-use-wide-fontify-buffer))


(defconst avl-font-lock-keywords
  (list
   (cons "\\(?:[Ss][Uu][Rr][Ff].*\\|[Aa][Ff][Ii][Ll].*\\|[Bb][Oo][Dd][Yy]\\)\n\\(.*\\)$"
	 (list 1 'font-lock-type-face))
   (cons "[Cc][Oo][Nn][Tt].*\n\\([a-zA-Z0-9]*\\) "
	 (list 1 'font-lock-type-face))
   (cons (concat "\\(\\s-\\|^\\)\\("
		 (mapconcat 'identity avl-keyword-list "\\|")
		 "\\)\\(\\s-\\|$\\)")
	 'font-lock-keyword-face)
   (cons "^\\([a-zA-Z ]+\\)$"   ; for non SURFACE/AFILE/BODY/CONTROL strings
	 (list 1 'font-lock-type-face))
   )
  "Keywords to highlight for AVL.  See variable `font-lock-keywords'.")



(defun avl-mode ()
  "Major mode for editing AVL code."
  (interactive)
  (kill-all-local-variables)

  (setq major-mode 'avl-mode)
  (setq mode-name "AVL")

  (set-syntax-table avl-mode-syntax-table)
  (use-local-map avl-mode-map)

  (setq indent-tabs-mode nil)     ; spaces not tabs!
  (setq tab-stop-list (number-sequence 0 100 avl-indent-level))

; this is necessary because font-lock defaults to "not immediately" which messes
; with the avl-pre/post-commands
  (set (make-local-variable 'font-lock-always-fontify-immediately) t) 

  (add-local-hook 'pre-command-hook 'avl-pre-command)
  (add-local-hook 'post-command-hook 'avl-post-command)
  (run-hooks 'avl-mode-hook)

  (font-lock-fontify-buffer)
)


(defun avl-uninsert-comment ()
  "Removes the preceding comment"
  (interactive)
  (search-backward-regexp "^ *[#!]")
  (kill-entire-line))


(defun avl-insert-standard-comment ()
  "Inserts a comment describing the fields below a section heading"
  (interactive)
  (search-backward-for-section)
  (let ((final-point (point)))
    (dolist (standard-comment avl-standard-comments)
      (save-excursion
	(if (search-forward-regexp (car standard-comment) (point-at-eol 2) t)
	    (progn
	      (forward-line 1)
	      (save-excursion (insert (concat (second standard-comment) "\n")))
	      (avl-indent-region (cons '(point-at-bol) '(point-at-eol)))
	      (setq final-point (1+ (point-at-eol)))))))
    (goto-char final-point)))


(defun search-backward-for-section ()
  "Positions cursor at the beginning of the previous section heading"
  (if (search-backward-regexp              
       (concat "\\(\\s-\\|^\\)\\(" 
	       (mapconcat 'identity avl-keyword-list "\\|")
	       "\\)\\(\\s-\\|$\\)") nil t)
      (point)
    (point-min)))


(defun avl-pre-command ()
  "Actions before a command is executed.  Used for font-lock on multiline regexps"
  (save-excursion 
    (setq avl-last-point (point))
    (setq avl-use-wide-fontify-buffer 
	  (or (is-face 'font-lock-type-face)
	      (progn 	      ; this second bit helps with backspace edits to the control surface string 
		(search-backward-regexp "^") 
		(is-face 'font-lock-type-face))))))


(defun avl-post-command ()
  "Actions after a command is executed.  Used for font-lock on multiline regexps"
  (save-excursion 
    (if avl-use-wide-fontify-buffer
	(let ((beg (save-excursion
		     (if avl-last-point (goto-char avl-last-point))   ; goto point where there was a font-lock-type-face
		     (search-backward-regexp "^" nil t)               ; goto beginning of line
		     (search-backward-for-section)))
	      (end (min (save-excursion (forward-line 1) (point)) (point-max))))
	  (copy-region-as-kill beg end)
	  (font-lock-fontify-region beg end t)))))


(defun avl-unindent-command ()
  "Skips to previous indent point"
  (interactive)
  (avl-skip-field-backward))


(defun avl-indent-command ()
  "Indents text to appropriate tab stop or skips to next field"
  (interactive)
  (if (or (not (avl-in-comment))
	  (avl-is-tabable-comment))
      (progn
	(skip-chars-backward "^ \t\n")
	(let ((orig (point)))
	  (delete-horizontal-space)
	  (or (bolp) (tab-to-tab-stop))
	  (if (eq orig (point))
	      (progn
		(skip-chars-forward "^ \t\n")
		(avl-skip-field-forward)
		))))
    (progn 
      (skip-chars-forward "^\n")
      (forward-char))))


(defun avl-indent-region (region)
  "Indents a region where region is a cons of two functions identifying the beginning
and ending points"
  (save-excursion
    (goto-char (eval (car region)))
    (let ((last-point (point))
	  (last-last-point (point)))
      (avl-indent-command) 
      (avl-indent-command)
      (while (and (< (point) (eval (cdr region))) (> (point) last-last-point))
	(setq last-last-point last-point)
	(setq last-point (point))
	(avl-indent-command)
	(avl-indent-command))))
  (font-lock-fontify-region (eval (car region)) (eval (cdr region))))
  

(defun avl-indent-all () 
  "Indents the entire file"
  (interactive)
  (avl-indent-region (cons '(point-min) '(point-max))))


(defun avl-skip-field-forward ()
  (interactive)
  (skip-face-forward 'font-lock-type-face)
  (search-forward-regexp "\\(\\s-\\|^\\)\\([^ \t\n]+\\)\\(\\s-\\|$\\)" nil t)
  (goto-char (match-beginning 2)))


(defun avl-skip-field-backward ()
  (interactive)
  (search-backward-regexp "\\(\\s-\\|^\\)\\([^ \t\n]+\\)\\(\\s-\\|$\\)")
  (goto-char (match-beginning 2))
  (if (save-excursion 
	(forward-char)
	(is-face 'font-lock-type-face))
      (progn
	(forward-char)
	(skip-face-backward 'font-lock-type-face)
	(forward-char))))


(defun avl-is-tabable-comment ()
  "A tabable comment is one where tabbing through it affects spacing.  These
are comments where the first character of a line is # or ! and the next character
is not a space"
  (save-excursion
    (beginning-of-line)
    (looking-at "[#!][^ ]")))


(defun avl-in-comment ()
  "Returns the point of the beginning of comment, nil if not in comment"
  (save-excursion
    (let ((orig (point)))
      (beginning-of-line)
      (search-forward-regexp "[#!]" orig t))))


(add-to-list 'auto-mode-alist '("\\.avl\\'" . avl-mode))




;;; Helper functions

(defun is-face (face)
  "bleh"
  (eq (get-text-property (point) 'face) face))

(defun skip-face-forward (face)
  (skip-face 'forward-char face))

(defun skip-face-backward (face)
  (skip-face 'backward-char face))

(defun skip-face (cmd face)
  "bleh"
  (let ((num-skipped 0))
    (while (is-face face)
      (funcall cmd)
      (setq num-skipped (1+ num-skipped)))
    num-skipped))


;;; Compatibility functions (Emacs -> XEmacs)

; In addition the function number-sequence is not defined in XEmacs. So I 
; copied the definition from the emacs distribution (in subr.el):
(defun number-sequence (from &optional to inc)
  "Return a sequence of numbers from FROM to TO (both inclusive) as a list. 
INC is the increment used between numbers in the sequence and defaults to 1. 
So, the Nth element of the list is \(+ FROM \(* N INC)) where N counts from 
zero. TO is only included if there is an N for which TO = FROM + N * INC. 
If TO is nil or numerically equal to FROM, return \(FROM).
If INC is positive and TO is less than FROM, or INC is negative
and TO is larger than FROM, return nil.
If INC is zero and TO is neither nil nor numerically equal to
FROM, signal an error.

This function is primarily designed for integer arguments.
Nevertheless, FROM, TO and INC can be integer or float. However,
floating point arithmetic is inexact. For instance, depending on
the machine, it may quite well happen that
\(number-sequence 0.4 0.6 0.2) returns the one element list \(0.4),
whereas \(number-sequence 0.4 0.8 0.2) returns a list with three
elements. Thus, if some of the arguments are floats and one wants
to make sure that TO is included, one may have to explicitly write
TO as \(+ FROM \(* N INC)) or use a variable whose value was
computed with this exact expression. Alternatively, you can,
of course, also replace TO with a slightly larger value
\(or a slightly more negative value if INC is negative)."
  (if (or (not to) (= from to))
      (list from)
    (or inc (setq inc 1))
    (when (zerop inc) (error "The increment can not be zero"))
    (let (seq (n 0) (next from))
      (if (> inc 0)
	  (while (<= next to)
	    (setq seq (cons next seq)
		  n (1+ n)
		  next (+ from (* n inc))))
	(while (>= next to)
	  (setq seq (cons next seq)
		n (1+ n)
		next (+ from (* n inc)))))
      (nreverse seq))))