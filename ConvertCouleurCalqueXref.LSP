(defun c:cst (/ acdoc LayerPattern Val RGB HSL lRGB)
  (vl-load-com)
  (setq	acdoc	   (vla-get-ActiveDocument (vlax-get-acad-object))
	ColorDecal 7
	)
  (if (setq LayerPattern (getstring "Prefixe des calques � griser : ")
	    Val		 (if (and (> 10 (setq Val (getint "Attenuation 10-100 : "))) (<= Val 100))
			   Val
			   40
			   )
	    )
    (progn (vla-StartUndoMark acdoc)
	   (vlax-for l (vla-get-Layers acdoc)
	     (if (wcmatch (vla-get-Name l) (strcat LayerPattern "*"))
	       (progn (or (vlax-ldata-get l "laycol") (vlax-ldata-put l "laycol" (vla-get-Color l)))
		      (setq RGB	 (vla-get-TrueColor l)
			    HSL	 (LM:RGB->HSL (vla-get-Red RGB) (vla-get-Green RGB) (vla-get-Blue RGB))
			    lRGB (LM:HSL->RGB (car HSL) (cadr HSL) (max 0 (- (last HSL) Val)))
			    )
		      (vla-SetRGB RGB (car lRGB) (cadr lRGB) (last lRGB))
		      (vla-put-TrueColor l RGB)
		      )
	       )
	     )
	   (vla-EndUndoMark acdoc)
	   )
    )
  (princ)
  )

(defun c:crt (/ acdoc Col)
  (vl-load-com)
  (setq acdoc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (if (setq LayerPattern (getstring "Prefixe des calques � d�griser : "))
    (progn (vla-StartUndoMark acdoc)
	   (vlax-for l (vla-get-Layers acdoc)
	     (if (setq Col (vlax-ldata-get l "laycol"))
	       (progn (vla-put-Color l Col) (vlax-ldata-delete l "laycol"))
	       )
	     )
	   (vla-EndUndoMark acdoc)
	   )
    )
  (princ)
  )

;; RGB -> HSL - Lee Mac 2011
;; Args: r,g,b - Red,Green,Blue values

(defun LM:RGB->HSL (r g b / _round d h l m n s)
  (setq	r (/ r 255.)
	g (/ g 255.)
	b (/ b 255.)
	n (min r g b)
	m (max r g b)
	d (- m n)
	l (/ (+ m n) 2.)
	)
  (defun _round	(n)
    (fix (+ n
	    (if	(minusp n)
	      -0.5
	      0.5
	      )
	    )
	 )
    )
  (mapcar '_round
	  (cond	((zerop d) (list 0 0 (* m 100)))
		(t
		 (setq s (if (< l 0.5)
			   (/ d (+ m n))
			   (/ d (- 2. m n))
			   )
		       )
		 (setq h (cond ((= g m) (+ (/ (- b r) d) 2))
			       ((= b m) (+ (/ (- r g) d) 4))
			       ((/ (- g b) d))
			       )
		       )
		 (list (rem (+ 360 (* h 60)) 360) (* s 100) (* l 100))
		 )
		)
	  )
  )

;; HSL -> RGB - Lee Mac 2011
;; Args: 0 <= h <= 360, 0 <= s,l <= 100

(defun LM:HSL->RGB (h s l / _sub _round u v)
  (setq	h (/ h 360.)
	s (/ s 100.)
	l (/ l 100.)
	)
  (defun _sub (u v h)
    (setq h (rem (1+ h) 1))
    (cond ((< (* 6 h) 1) (+ u (* 6 h (- v u))))
	  ((< (* 2 h) 1) v)
	  ((< (* 3 h) 2) (+ u (* 6 (- (/ 2. 3.) h) (- v u))))
	  (u)
	  )
    )
  (defun _round	(n)
    (fix (+ n
	    (if	(minusp n)
	      -0.5
	      0.5
	      )
	    )
	 )
    )
  (mapcar '_round
	  (mapcar '*
		  '(255 255 255)
		  (cond	((zerop s) (list l l l))
			((zerop l) '(0 0 0))
			(t
			 (setq v (if (< l 0.5)
				   (* l (1+ s))
				   (- (+ l s) (* l s))
				   )
			       u (- (* 2 l) v)
			       )
			 (mapcar '(lambda (h) (_sub u v h)) (list (+ h (/ 1. 3.)) h (- h (/ 1. 3.))))
			 )
			)
		  )
	  )
  )