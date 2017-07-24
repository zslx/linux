;; 2017-07-06 14:24:05 zsl ∏ﬂ¡¡œ‘ æ È«©
(defun highlight-bookmarks-the-buffer ()
  (interactive)
  (mapcar
   (lambda (bmk)
	 (if (string= (buffer-file-name) (bookmark-get-filename bmk))
		 (let ((pos (bookmark-get-position bmk))
			   )
		   (setq hlpos (make-overlay pos (+ 6 pos)))
		   (prin1 hlpos)
		   (overlay-put hlpos 'face '(:background "green"))
		   (overlay-put hlpos 'line-highlight-overlay-marker t))
	   ;; (message bmk)
	   ))
   (bookmark-all-names))
  )

(defun highlight-bookmarks-clean ()
  (interactive)
  (remove-overlays (point-min) (point-max)))


(defun find-overlays-specifying (prop pos)
  (let ((overlays (overlays-at pos))
        found)
    (while overlays
      (let ((overlay (car overlays)))
        (if (overlay-get overlay prop)
            (setq found (cons overlay found))))
      (setq overlays (cdr overlays)))
    found))

(defun highlight-or-dehighlight-line ()
  (interactive)
  (if (find-overlays-specifying
       'line-highlight-overlay-marker
       (line-beginning-position))
      (remove-overlays (line-beginning-position) (+ 1 (line-end-position)))
    (let ((overlay-highlight (make-overlay
                              (line-beginning-position)
                              (+ 1 (line-end-position)))))
	  (overlay-put overlay-highlight 'face '(:background "lightgreen"))
	  (overlay-put overlay-highlight 'line-highlight-overlay-marker t))))


(global-set-key [f8] 'highlight-or-dehighlight-line)

;; (Here find-overlays-specifying came from the manual page)
;; http://www.gnu.org/software/emacs/manual/html_node/elisp/Finding-Overlays.html

;; if you need to change the color, this is the list 
;; http://raebear.net/comp/emacscolors.html

;; It will highlight current line, and when used again it will remove it.

;; Maybe the following could be useful as well: removing all your highlight from the buffer (could be dangerous, you might not want it if you highlight important things)

(defun remove-all-highlight ()
  (interactive)
  (remove-overlays (point-min) (point-max))
  )

(global-set-key [f9] 'remove-all-highlight)
