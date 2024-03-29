;; (version< "1alpha" "1beta")
;; (version= "2.4-alpha" "2.4-git")
;; (version< "2.4-snapshot3" "2.4-snapshot2-snapshot2019")
;; (version-to-list "6.0.2-snapshot10")
;; (last (version-to-list "32-alpha0-snapshot20210321.852"))
;; (package-version-join (version-to-list "6.0b"))

;; (cl-every (cl-function (lambda (what &aux (x (car what)) (y (cdr what)))
;; 			 (version-list-< (version-to-list x) (version-to-list y))))
;; 	  '(("0.17.0pre" . "0.17.0pre1-snapshot20210330.1531")
;; 	    ("0.17.0pre3" . "0.17.0pre3.1-snapshot20210330.1531")
;; 	    ;; ("0.17.0pre" . "0.17.0pre.1-snapshot20210330.1531")
;; 	    ("0.17.0snapshot" . "0.17.0snapshot20210330.1531")
;; 	    ("0.17.0snapshot2" . "0.17.0snapshot2.1-snapshot20210330.1531")
;; 	    ))

(require 'subr-x)
(require 'package)
(require 'url-http)
(require 'lisp-mnt)
(require 'tar-mode)

(defvar shmelpa--outliers nil)

(defconst shmelpa--problematic-longlink '(ac-html ox-ioslide ptemplate-templates stan-snippets yasnippet-snippets))

(defconst shmelpa--outliers-check-pkg
  '(weechat
    tracking
    expand-region
    vdiff
    caml
    slime
    all-the-icons
    bind-map
    ov
    evil-cleverparens
    treepy
    base16-theme
    snapshot-timemachine
    uuidgen
    thrift
    haml-mode
    jump
    yasnippet
    transient
    purescript-mode
    codesearch
    paredit
    pager
    ox-gfm
    forge
    s
    bibtex-completion
    frecency
    alert
    org-present
    matlab-mode
    ox-slimhtml
    graphql-mode
    ess
    jest
    virtualenvwrapper
    flim
    mozc
    eval-in-repl
    calfw
    mandoku
    github-clone
    friendly-shell-command
    hl-todo
    look-mode
    stem
    graphql
    highlight
    f
    inflections
    ddskk
    keypress-multi-event
    cfrs
    gitignore-mode
    bm
    avy-menu
    haskell-emacs
    exec-path-from-shell
    names
    gitlab-ci-mode
    magit
    with-editor
    ghub
    add-node-modules-path
    less-css-mode
    flymake-easy
    request-deferred
    merlin
    keg
    flx
    faust-mode
    projectile-rails
    smartparens
    polymode
    ctable
    helm
    closql
    dash
    inheritenv
    iedit
    emms
    package-lint
    initsplit
    ace-jump-mode
    osx-location
    web-server
    websocket
    auto-complete
    ede-php-autoload
    e2wm
    inlineR
    debian-el
    json-mode
    ledger-mode
    js2-refactor
    w3m
    pg
    page-break-lines
    popup
    notmuch
    ycmd
    know-your-http-well
    lean-mode
    erlang
    ivy
    math-symbol-lists
    axiom-environment
    company-c-headers
    evil
    shell-split-string
    emacsql-sqlite
    clang-format
    package-build
    tree-mode
    dash-functional
    choice-program
    langdoc
    epkg
    clmemo
    key-chord
    bbdb
    outline-minor-faces
    magit-popup
    deferred
    packed
    reformatter
    markdown-mode
    projectile
    flycheck
    request
    ccc
    xcscope
    skewer-mode
    helm-core
    geiser
    pos-tip
    parseedn))

(defconst shmelpa-inception "0.1.0")

(defconst shmelpa-recipes-dir
  (expand-file-name "recipes" "~/melpa"))

(defconst shmelpa-melpa-dir "/opt/bitnami/nginx/html/packages/melpa")

(defconst shmelpa-targets-dir
  (if (string= user-login-name "bitnami")
      "/opt/bitnami/nginx/tmp/targets"
    default-directory))

(defconst shmelpa-packages-dir
  (if (string= user-login-name "bitnami")
      "/opt/bitnami/nginx/html/packages"
    default-directory))

(defconst shmelpa-ingested-file
  (concat (file-name-as-directory
	   (if (string= user-login-name "bitnami")
	       shmelpa-melpa-dir
	     default-directory))
	  "archive-contents-ingested"))

(defconst shmelpa-final-file
  (concat (file-name-as-directory
	   (if (string= user-login-name "bitnami")
	       shmelpa-melpa-dir
	     default-directory))
	  "archive-contents-final"))

(defconst shmelpa-staging-file
  (concat (file-name-as-directory
	   (if (string= user-login-name "bitnami")
	       shmelpa-melpa-dir
	     default-directory))
	  "archive-contents-staging"))

(cl-defun shmelpa--pkg-el-version (name* commit &aux version (name (symbol-name name*)))
  (when-let* ((recipe
	       (cdr (shmelpa--file-to-sexpr (expand-file-name name shmelpa-recipes-dir))))
	      (fetcher (plist-get recipe :fetcher))
	      (repo (plist-get recipe :repo))
	      (fragile (pcase fetcher
			 ('github
			  (mapconcat #'identity
				     (list "https://raw.githubusercontent.com"
					   repo
					   commit)
				     "/"))
			 ('gitlab
			  (mapconcat #'identity
				     (list "https://gitlab.com"
					   repo
					   "-"
					   "raw"
					   commit)
				     "/"))))
	      (search-dirs
	       (append '("" "lisp") ;; melpa recipe :defaults keyword
		       (cl-remove-if-not
		        #'identity
		        (mapcar #'file-name-directory
			        (cl-remove-if-not
			         #'stringp
			         (plist-get recipe :files))))))
	      (search-urls
	       (mapcar (lambda (dir) (format "%s/%s%s-pkg.el" fragile (file-name-as-directory dir) name))
		       search-dirs)))
    (dolist (url search-urls)
      (if-let ((buffer (url-retrieve-synchronously url t nil 5)))
	  (unwind-protect
	      (with-current-buffer buffer
		(when (and (ignore-errors (url-http-parse-headers)) (= url-http-response-status 200))
		  (goto-char (marker-position url-http-end-of-headers))
		  (when-let* ((desc (ignore-errors
				      (package-process-define-package
				       (read (current-buffer)))))
			      (candidate (package-desc-version desc)))
		    (when (or (null version)
			      (version-list-< version candidate))
		      (setq version candidate)))))
	    (let (kill-buffer-query-functions)
	      (ignore-errors (kill-buffer buffer))))
	(message "url-retrieve (%s): no response" url))))
  (when version (package-version-join version)))

(defun shmelpa-ingest ()
  (interactive)
  (if-let* ((url "https://melpa.org/packages/archive-contents")
	    (buffer (url-retrieve-synchronously url t nil 5)))
      (unwind-protect
	  (with-current-buffer buffer
	    (goto-char (marker-position url-http-end-of-headers))
	    (let ((contents (shmelpa--winnow (read (current-buffer)))))
	      (write-region (pp-to-string contents) nil
			    shmelpa-ingested-file
			    nil 'silent)))
	(let (kill-buffer-query-functions)
	  (ignore-errors (kill-buffer buffer))))
    (error "url-retrieve (%s): no response" url)))

(defun shmelpa--undesired-p (version)
  (let* ((vlist (if (listp version) version (version-to-list version))))
    (and (= (length vlist) 2)
	 (> (cl-first vlist) 20101231)
	 (>= (cl-second vlist) 0)
	 (<= (cl-second vlist) 2359))))

(defun shmelpa--guess-version (version)
  (condition-case err
      (progn
	(version-to-list version)
	version)
    (error (when (cl-search "Invalid version" (error-message-string err))
	     (when (string-match "^\\([0-9.]+\\)" version)
	       (match-string 1 version))))))

(defun shmelpa--genuine-version ()
  (cl-flet ((strip-rcs-id
	     (str)
	     (when str
	       (if (string-match "\\`[ \t]*[$]Revision:[ \t]+" str)
		   (substring str (match-end 0))
		 str))))
    (let ((version (shmelpa--guess-version (strip-rcs-id (lm-header "version"))))
	  (pkg-version (shmelpa--guess-version (strip-rcs-id (lm-header "package-version")))))
      (cond ((and pkg-version (not (shmelpa--undesired-p pkg-version)))
	     pkg-version)
	    (t version)))))

(defun shmelpa--buffer-info ()
  (let ((foo (lambda (args)
	       (when (and (stringp (car args))
			(string= (car args) "package-version"))
		 (setcar args "version"))
	       args)))
    ;; later: `foo' cannot help since `package-desc-version'
    ;; returns a version-list.  Resort to `shmelpa--genuine-version'.
    (unwind-protect
	(progn
	  (add-function :filter-args (symbol-function 'lm-header) foo)
	  (package-buffer-info))
      (remove-function (symbol-function 'lm-header) foo))))

(defun shmelpa--untar-buffer ()
  "Counterpart `package-untar-buffer'."
  (tar-mode)
  (let ((data-buf (if (tar-data-swapped-p)
		      tar-data-buffer
                    (current-buffer))))
    (with-current-buffer data-buf
      (cl-assert (not enable-multibyte-characters)))
    (cl-loop with version
	     for descriptor in tar-parse-info
	     do (let* ((name (tar-header-name descriptor))
		       (dir-p (eq (tar-header-link-type descriptor) 5))
		       (start (tar-header-data-start descriptor))
		       (end (+ start (tar-header-size descriptor))))
		  (when (and (not dir-p)
			     (string= "el" (file-name-extension name)))
		    (with-current-buffer data-buf
		      (let ((body (buffer-substring-no-properties start end)))
			(with-temp-buffer
			  (save-excursion (insert body))
			  (when-let ((candidate (shmelpa--genuine-version)))
			    (when (or (null version)
				      (string> candidate version))
			      (setq version candidate))))))))
	     finally return version)))

(defun shmelpa--winnow (contents)
  (cl-flet ((winnow-p
	     (name-desc)
	     (cl-destructuring-bind (name . desc)
		 name-desc
	       (let ((pkg-version (package--ac-desc-version desc)))
		 (or (version-list-< pkg-version
				     (version-to-list "20130101"))
		     (memq name shmelpa--problematic-longlink))))))
    (cons (car contents) (cl-remove-if #'winnow-p (cdr contents)))))

(defun shmelpa--file-to-sexpr (infile)
  (read (with-temp-buffer
	  (let ((coding-system-for-read 'utf-8))
	    (insert-file-contents infile)
	    (buffer-string)))))

(defun shmelpa--doctor-tar (name src dest undesired desired)
  (save-excursion
    (let (large-file-warning-threshold)
      (find-file src))
    (write-file dest)
    (unwind-protect
	(cl-loop
	 do (when-let* ((descriptor (tar-current-descriptor t))
			(oname (tar-header-name descriptor))
			(dirname (file-name-directory oname))
			(therest (cl-subseq oname (length dirname)))
			(nname
			 (concat (replace-regexp-in-string
				  (regexp-quote undesired)
				  desired dirname nil 'literal)
				 therest)))
	      (condition-case err
		  (tar-rename-entry nname)
		(error (message "tar-rename-entry[%s]: %s" name (error-message-string err))))
	      (when (string= (file-name-nondirectory oname)
			     (package--description-file (file-name-directory oname)))
		(save-excursion
		  (tar-extract)
		  (when tar-subfile-mode
		    (unwind-protect
			(progn
			  (save-excursion
			    (while (re-search-forward
				    (regexp-quote
				     (concat "\"" (cl-subseq undesired (1+ (length name))) "\""))
				    nil t)
			      (replace-match
			       (concat "\"" (cl-subseq desired (1+ (length name))) "\""))))
			  (save-buffer))
		      (let (kill-buffer-query-functions)
			(ignore-errors (kill-buffer))))))))
	 until (not (zerop (forward-line)))
	 finally do (save-buffer))
      (let (kill-buffer-query-functions)
	(ignore-errors (kill-buffer))))))

(defun shmelpa-doctor-one-deliverable (name file kind undesired desired)
  (let* ((src (expand-file-name file shmelpa-targets-dir))
	 (srcr (expand-file-name (concat name "-readme.txt") shmelpa-targets-dir))
	 (destr (expand-file-name (concat name "-readme.txt") shmelpa-packages-dir))
	 (nfile (replace-regexp-in-string
		 (regexp-quote undesired)
		 desired file nil 'literal))
	 (dest (expand-file-name nfile shmelpa-packages-dir))
	 (to-delete (cl-remove-if
		     (lambda (f) (member f (list src dest srcr destr)))
		     (directory-files (file-name-directory dest) t
				      (concat "^" (regexp-quote name) "-[^-]+$")))))
    (mapc #'delete-file to-delete)
    (when (and (file-exists-p srcr) (not (string= srcr destr)))
      (copy-file srcr destr t))
    (when (file-exists-p src)
      (pcase kind
	('tar (shmelpa--doctor-tar name src dest undesired desired))
	('single (let ((coding-system-for-write 'raw-text))
		   (with-temp-file dest
		     (let ((coding-system-for-read 'utf-8))
		       (save-excursion
			 (insert-file-contents src))
		       (save-excursion
			 (while (re-search-forward
				 (regexp-quote (cl-subseq undesired (1+ (length name))))
				 nil t)
			   (replace-match (cl-subseq desired (1+ (length name))))))))))))))

(defun shmelpa-check-one-deliverable (name file kind undesired desired)
  (let* ((src (expand-file-name file shmelpa-targets-dir))
	 (srcr (expand-file-name (concat name "-readme.txt") shmelpa-targets-dir))
	 (destr (expand-file-name (concat name "-readme.txt") shmelpa-packages-dir))
	 (nfile (replace-regexp-in-string
		 (regexp-quote undesired)
		 desired file nil 'literal))
	 (dest (expand-file-name nfile shmelpa-packages-dir)))
    (cl-every #'file-exists-p (list src dest srcr destr))))

(cl-defun shmelpa-check-deliverables ()
  (cl-loop with bad
	   with contents = (shmelpa--file-to-sexpr shmelpa-final-file)
	   for (name . desc) in (cdr contents)
	   for desired = (package--ac-desc-version desc)
	   for undesired = (nthcdr (- (length desired) 2) desired)
	   unless (shmelpa--undesired-p desired)
	   do (let* ((kind (package--ac-desc-kind desc))
		     (desired-desc
		      (package-desc-create
		       :name name
		       :version desired
		       :kind kind))
		     (undesired-desc
		      (package-desc-create
		       :name name
		       :version undesired
		       :kind kind)))
		(unless (shmelpa-check-one-deliverable
			 (symbol-name name)
			 (concat (package-desc-full-name undesired-desc)
				 (package-desc-suffix undesired-desc))
			 kind
			 (package-desc-full-name undesired-desc)
			 (package-desc-full-name desired-desc))
		  (push name bad)))
	   finally return bad))

(defun shmelpa-all-contents ()
  (mapcar #'car (cdr (shmelpa--file-to-sexpr shmelpa-final-file))))

(cl-defun shmelpa-doctor-contents (infile outfile midfile &key specific (at-most most-positive-fixnum))
  (let ((package-archives '(("shmelpa" . "https://shmelpa.commandlinesystems.com/packages/")))
	(ocontents (and (file-exists-p midfile)
			(cdr (shmelpa--file-to-sexpr midfile))))
	(contents (shmelpa--file-to-sexpr infile)))
    (cl-loop with nchanged = 0
	     for (name . desc) in (cdr contents)
	     for version = (let ((full (package--ac-desc-version desc)))
			     (nthcdr (- (length full) 2) full))
	     for odesc = (alist-get name ocontents)
	     for full-oversion = (when odesc (package--ac-desc-version odesc))
	     for oversion = (when full-oversion	(nthcdr (- (length full-oversion) 2) full-oversion))
	     if full-oversion
	     do (setf (package--ac-desc-version desc) full-oversion)
	     end
	     if (and (< nchanged at-most)
		     (if specific
			 (memq name specific)
		       (or (null oversion)
			   (not (version-list-= version oversion))
			   (shmelpa--undesired-p full-oversion))))
	     do (let* ((pkg-desc
			(package-desc-create
			 :name name
			 :version version
			 :reqs (package--ac-desc-reqs desc)
			 :summary (package--ac-desc-summary desc)
			 :kind (package--ac-desc-kind desc)
			 :archive (cl-first (car package-archives))
			 :extras (and (> (length desc) 4)
				      ;; Older archive-contents files have only 4
				      ;; elements here.
				      (package--ac-desc-extras desc))))
		       (location (file-name-directory (directory-file-name (package-archive-base pkg-desc))))
		       (commit (alist-get :commit (package-desc-extras pkg-desc)))
		       (undesired (package-desc-full-name pkg-desc))
		       (file (concat undesired (package-desc-suffix pkg-desc)))
		       (url (directory-file-name (concat location file)))
		       (save-silently t))
		  (message "%s" url)
		  (if-let ((buffer (url-retrieve-synchronously url t nil 5)))
		      (unwind-protect
			  (condition-case-unless-debug err
			      (package--with-response-buffer location :file file
				(let* ((version*
					(or (pcase (package-desc-kind pkg-desc)
					      ('tar
					       (let* ((easy (or (shmelpa--untar-buffer) ""))
						      (pkg-version
						       (or (when (or (zerop (length easy))
								     (memq name shmelpa--outliers-check-pkg))
							     (shmelpa--pkg-el-version name commit))
							   "")))
						 (if (string< easy pkg-version)
						     pkg-version
						   (unless (zerop (length easy))
						     easy))))
					      ('single
					       (shmelpa--genuine-version)))
					    shmelpa-inception))
				       (vlist (version-to-list version*))
				       (version ;; 6.0z => 6.0.26
					(if (and (> (car (last vlist)) 0)
						 (not (string-match-p
						       "[0-9]"
						       (cl-subseq version* -1))))
					    (package-version-join vlist)
					  version*))
				       (shmelpa-version*
					(format "%s%s%s"
						version
						(if (= (car (last vlist)) -4)
						    ""
						  (if (< (car (last vlist)) 0)
						      "1-snapshot"
						    (concat version-separator "1-snapshot")))
						(mapconcat (apply-partially #'format "%s")
							   (package-desc-version pkg-desc) ".")))
				       (shmelpa-version
					(package-version-join
					 (version-to-list shmelpa-version*))))
				  (shmelpa-doctor-one-deliverable
				   (symbol-name name)
				   file
				   (package-desc-kind pkg-desc)
				   undesired
				   (package-desc-full-name
				    (package-desc-create
				     :name name
				     :version (version-to-list shmelpa-version))))
				  (setf (package--ac-desc-version desc)
					(version-to-list shmelpa-version))
				  (cl-incf nchanged)))
			    (error (message "next time then (%s): %s"
					    name (error-message-string err))))
			(let (kill-buffer-query-functions)
			  (ignore-errors (kill-buffer buffer))))
		    (message "url-retrieve (%s): no response" url)))
	     end)
    (write-region (pp-to-string contents) nil outfile nil 'silent)))

(cl-defun shmelpa-doit (&optional ingest-p at-most)
  (when ingest-p
    (shmelpa-ingest))
  (shmelpa-doctor-contents
   shmelpa-ingested-file
   shmelpa-staging-file
   shmelpa-final-file :at-most (or at-most 30)))

(defun shmelpa--gnutls-advice (f &rest args)
  (let ((gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))
       (apply f args)))

(defun shmelpa-test-install ()
  (let* (package-alist
	 package-archive-contents
	 (user-emacs-directory "/var/tmp")
	 (package-user-dir (locate-user-emacs-file "elpa"))
	 (load-path load-path)
	 (package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                             ("shmelpa" . "https://shmelpa.commandlinesystems.com/packages/")))
	 (_ (package-refresh-contents))
	 (lst
	  (cl-remove-if-not
	   (lambda (desc) (string= (package-desc-archive desc) "shmelpa"))
	   (mapcar #'cl-second package-archive-contents))))
    (cl-letf (((symbol-function 'package-activate-1) #'ignore))
      (dolist (shmelp (list (car lst)))
	(let ((key (intern (package-desc-full-name shmelp))))
	  (condition-case err
	      (package-install shmelp)
	    (error (setf (alist-get key shmelpa--outliers)
			 (error-message-string err))))
	  (unless (alist-get key shmelpa--outliers)
	    (let ((package-table
		   (mapcar
		    (lambda (p) (cons (package-desc-full-name p) p))
		    (delq nil
			  (mapcar (lambda (p) (unless (package-built-in-p p) p))
				  (apply #'append (mapcar #'cdr (package--alist))))))))
	      (dolist (desc (mapcar #'cdr package-table))
		(package-delete desc t nil)))))))))

(when (< emacs-major-version 27)
  (condition-case err
      (progn (advice-remove 'url-retrieve-synchronously #'shmelpa--gnutls-advice)
             (advice-add 'url-retrieve-synchronously :around
                         #'shmelpa--gnutls-advice))
    (error
     (advice-remove 'url-retrieve-synchronously #'shmelpa--gnutls-advice)
     (display-warning 'error
                      (format "advice aborted: %s"
                              (error-message-string err))))))
