;;------------------------------------------------------------------;;
;; Sentaurus Structure Editor (SDE) - AlGaN/GaN HEMT
;; RECOMMENDED for III-Nitride HEMT structures (use this instead of
;; SProcess for cleaner geometry control).
;;
;; Layer stack (built from substrate up):
;;   1. 4H-SiC substrate          (500 nm shown; really thicker)
;;   2. AlN nucleation             (50 nm)
;;   3. GaN buffer                 (1000 nm)
;;   4. C-doped GaN buffer         (1000 nm, [C] = 1e18 cm-3)
;;   5. AlGaN back-barrier         (20 nm, x_Al = 0.07)
;;   6. UID GaN channel            (30 nm)
;;   7. AlGaN barrier              (25 nm, x_Al = 0.25)
;;
;; Device dimensions (lateral, y-axis):
;;   Lsg = 1.0 um, Lg = 0.3 um, Lgd = 1.5 um  -> total y = 4.0 um
;;------------------------------------------------------------------;;

(sde:clear)

;; ---- Geometry definitions (x is vertical, y is lateral) -----------
;; x grows DOWNWARD here: top of device at x=0, substrate at bottom
;; All units in micrometers.

(define Lsg   1.0)   ; source-to-gate
(define Lg    0.3)   ; gate length
(define Lgd   1.5)   ; gate-to-drain
(define Wcont 0.8)   ; ohmic contact width (source/drain)
(define Ydev  (+ Wcont Lsg Lg Lgd Wcont))   ; total device width = 4.0 um

(define t_barr   0.025)   ; AlGaN barrier
(define t_chan   0.030)   ; UID GaN channel
(define t_bbarr  0.020)   ; AlGaN back-barrier
(define t_cbuf   1.000)   ; C-doped GaN buffer
(define t_buf    1.000)   ; GaN buffer
(define t_aln    0.050)   ; AlN nucleation
(define t_sic    0.500)   ; SiC substrate (truncated for sim speed)

;; Compute x-coordinates (top-down)
(define x0  0.0)                                   ; top surface
(define x1  (+ x0  t_barr))                        ; AlGaN / UID-GaN
(define x2  (+ x1  t_chan))                        ; UID-GaN / back-barrier
(define x3  (+ x2  t_bbarr))                       ; back-barrier / C-GaN
(define x4  (+ x3  t_cbuf))                        ; C-GaN / GaN buffer
(define x5  (+ x4  t_buf))                         ; GaN / AlN
(define x6  (+ x5  t_aln))                         ; AlN / SiC
(define x7  (+ x6  t_sic))                         ; SiC bottom

;; ---- Build layers as rectangles ----------------------------------
(sdegeo:create-rectangle (position 0.0  x6 0.0) (position Ydev x7 0.0)
                         "SiC"             "R_substrate")
(sdegeo:create-rectangle (position 0.0  x5 0.0) (position Ydev x6 0.0)
                         "AlN"             "R_nucleation")
(sdegeo:create-rectangle (position 0.0  x4 0.0) (position Ydev x5 0.0)
                         "GaN"             "R_buffer")
(sdegeo:create-rectangle (position 0.0  x3 0.0) (position Ydev x4 0.0)
                         "GaN"             "R_cbuffer")
(sdegeo:create-rectangle (position 0.0  x2 0.0) (position Ydev x3 0.0)
                         "AlGaN"           "R_bbarrier")
(sdegeo:create-rectangle (position 0.0  x1 0.0) (position Ydev x2 0.0)
                         "GaN"             "R_channel")
(sdegeo:create-rectangle (position 0.0  x0 0.0) (position Ydev x1 0.0)
                         "AlGaN"           "R_barrier")

;; ---- Define AlGaN mole fractions ---------------------------------
(sdedr:define-constant-profile "Prof_Barrier_x"
        "xMoleFraction" 0.25)
(sdedr:define-constant-profile-region "Place_Barrier_x"
        "Prof_Barrier_x" "R_barrier")

(sdedr:define-constant-profile "Prof_BBarr_x"
        "xMoleFraction" 0.07)
(sdedr:define-constant-profile-region "Place_BBarr_x"
        "Prof_BBarr_x" "R_bbarrier")

;; ---- Define doping ------------------------------------------------
;; C-doped buffer: Carbon as compensating acceptor (deep level)
(sdedr:define-constant-profile "Prof_C_doping"
        "CarbonActiveConcentration" 1.0e18)
(sdedr:define-constant-profile-region "Place_C_doping"
        "Prof_C_doping" "R_cbuffer")

;; UID GaN channel: light unintentional n-type background
(sdedr:define-constant-profile "Prof_UID"
        "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_UID"
        "Prof_UID" "R_channel")

;; ---- Contacts (S, G, D) on top surface ---------------------------
;; Source: y = 0 to Wcont = 0 to 0.8
;; Gate:   y = Wcont+Lsg to Wcont+Lsg+Lg = 1.8 to 2.1
;; Drain:  y = Ydev-Wcont to Ydev = 3.2 to 4.0
(define ys1 0.0)
(define ys2 Wcont)
(define yg1 (+ Wcont Lsg))
(define yg2 (+ yg1 Lg))
(define yd1 (- Ydev Wcont))
(define yd2 Ydev)

;; Source contact (recessed ohmic - extend slightly into AlGaN)
(sdegeo:define-contact-set "source" 4.0 (color:rgb 1 0 0) "##")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ ys1 ys2) 2.0) x0 0.0)) "source")

;; Drain contact
(sdegeo:define-contact-set "drain"  4.0 (color:rgb 0 0 1) "##")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ yd1 yd2) 2.0) x0 0.0)) "drain")

;; Gate contact (Schottky - Ni)
(sdegeo:define-contact-set "gate"   4.0 (color:rgb 0 1 0) "##")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ yg1 yg2) 2.0) x0 0.0)) "gate")

;; ---- Mesh refinement -----------------------------------------------
;; Global mesh
(sdedr:define-refinement-size "Ref_Global"
   0.20 0.20      ; max element size (y, x)
   0.05 0.05)     ; min element size

(sdedr:define-refinement-region "Place_Global"
   "Ref_Global" "R_substrate")

;; 2DEG refinement at AlGaN/GaN interface (x ~ x1, top channel)
(sdedr:define-refinement-window "RW_2DEG"
   "Rectangle"
   (position 0.0 (- x1 0.005) 0.0)
   (position Ydev (+ x1 0.005) 0.0))

(sdedr:define-refinement-size "Ref_2DEG"
   0.05  0.0005
   0.01  0.0001)

(sdedr:define-refinement-placement "Place_2DEG"
   "Ref_2DEG" "RW_2DEG")

;; Gate region fine mesh
(sdedr:define-refinement-window "RW_Gate"
   "Rectangle"
   (position yg1 0.0 0.0)
   (position yg2 x2  0.0))

(sdedr:define-refinement-size "Ref_Gate"
   0.02 0.005
   0.005 0.001)

(sdedr:define-refinement-placement "Place_Gate"
   "Ref_Gate" "RW_Gate")

;; ---- Generate mesh and save --------------------------------------
(sde:build-mesh "snmesh" "" "n@node@_msh")
(sde:save-model "n@node@_str")
