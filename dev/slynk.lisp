;;;; Start a Slynk server on a Cloture image, for SLY-driven interactive work.
;;;;
;;;; Usage:
;;;;   sbcl --load dev/slynk.lisp                    ; port 4005
;;;;   CLOTURE_SLYNK_PORT=4010 sbcl --load dev/slynk.lisp
;;;;
;;;; Then M-x sly-connect RET localhost RET <port> RET.
;;;;
;;;; SLYNK_LOADER overrides the slynk location; the default is SLY's straight.el
;;;; build directory.

(require :asdf)

(let ((quicklisp-init (merge-pathnames "quicklisp/setup.lisp"
                                       (user-homedir-pathname))))
  (when (and (not (find-package "QUICKLISP")) (probe-file quicklisp-init))
    (load quicklisp-init)))

(defun cloture-dev-env (name default)
  (or (uiop:getenv name) default))

(defun cloture-dev-slynk-loader ()
  (let ((explicit (uiop:getenv "SLYNK_LOADER")))
    (if explicit
        (pathname explicit)
        (first (directory
                (merge-pathnames ".emacs.d/.local/straight/build-*/sly/slynk/slynk-loader.lisp"
                                 (user-homedir-pathname)))))))

(let ((loader (cloture-dev-slynk-loader)))
  (unless loader
    (error "No slynk-loader.lisp found. Set SLYNK_LOADER to SLY's slynk/slynk-loader.lisp."))
  (load loader)
  (funcall (uiop:find-symbol* '#:init '#:slynk-loader)
           :delete nil
           :reload nil
           :load-contribs t))

(uiop:symbol-call '#:ql '#:quickload "cloture" :verbose nil)

(let ((port (parse-integer (cloture-dev-env "CLOTURE_SLYNK_PORT" "4005"))))
  (uiop:symbol-call '#:slynk '#:create-server
                    :port port
                    :dont-close t)
  (format t "~&;; Cloture image ready. Slynk listening on port ~a.~%~
             ;; Clojure namespaces are packages: (in-package \"clojure.core\")~%~
             ;; or from CL: (|clojure.core|:|inc| 1)~%"
          port))
