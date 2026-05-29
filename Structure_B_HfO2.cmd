;;==================================================================;;
;; Sentaurus Structure Editor (SDE)  -  T-2022.03
;; STRUCTURE B : AlGaN/GaN MIS-HEMT, HfO2-only gate dielectric (8 nm)
;;
;; ORIENTATION (as required):
;;   X axis = VERTICAL   (growth direction; layers stack along X)
;;   Y axis = HORIZONTAL (lateral; source->drain along Y)
;;   (position X Y Z) : 1st arg = X (vertical), 2nd = Y (lateral)
;;   X = 0 at semiconductor surface; +X goes DOWN into substrate;
;;   -X goes UP toward air (dielectric, gate metal).
;;   Source = LEFT (small Y), Drain = RIGHT (large Y),
;;   Substrate = BOTTOM (large X), Air = TOP (negative X).
;;   NOT rotated: layers are horizontal slabs stacked vertically.
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")

;;-------- 1. PARAMETERS -------------------------------------------;;
;; Vertical thicknesses (um)
(define t_barr   0.020)   ; AlGaN barrier  (x_Al = 0.25)
(define t_chan   0.150)   ; UID GaN channel
(define t_bbarr  0.025)   ; AlGaN back-barrier (x_Al = 0.08)
(define t_cbuf   1.500)   ; Carbon-doped GaN buffer
(define t_buf    0.200)   ; GaN buffer
(define t_aln    0.100)   ; AlN nucleation
(define t_sic    2.000)   ; SiC substrate

(define t_diel   0.008)   ; HfO2 gate dielectric (8 nm) -- STRUCTURE B
(define t_sdm    0.050)   ; source/drain metal thickness
(define t_gm     0.050)   ; gate metal thickness

;; Lateral lengths (um)
(define L_src    0.250)
(define L_sg     1.000)
(define L_gate   0.250)
(define L_gd     5.000)
(define L_drn    0.250)

;; Mole fractions / doping
(define x_top    0.25)
(define x_back   0.08)
(define N_cbuf   1.0e18)  ; C in buffer (acceptor proxy)
(define N_uid    1.0e15)  ; UID background

;;-------- 2. VERTICAL (X) COORDINATES (surface=0, +down) ----------;;
(define x_surf      0.0)
(define x_barr_bot  (+ x_surf     t_barr))    ; 0.020
(define x_chan_bot  (+ x_barr_bot t_chan))    ; 0.170
(define x_bbarr_bot (+ x_chan_bot t_bbarr))   ; 0.195
(define x_cbuf_bot  (+ x_bbarr_bot t_cbuf))   ; 1.695
(define x_buf_bot   (+ x_cbuf_bot t_buf))     ; 1.895
(define x_aln_bot   (+ x_buf_bot  t_aln))     ; 1.995
(define x_sic_bot   (+ x_aln_bot  t_sic))     ; 3.995

(define x_diel_top  (- x_surf t_diel))        ; -0.008
(define x_gate_top  (- x_diel_top t_gm))      ; -0.058
(define x_sdm_top   (- x_surf t_sdm))         ; -0.050

;;-------- 3. LATERAL (Y) COORDINATES (source left -> drain right) -;;
(define ys1 0.0)
(define ys2 L_src)                ; 0.25
(define yg1 (+ L_src L_sg))       ; 1.25
(define yg2 (+ yg1 L_gate))       ; 1.50
(define yd1 (+ yg2 L_gd))         ; 6.50
(define yd2 (+ yd1 L_drn))        ; 6.75
(define Ymax yd2)                 ; 6.75
(define ymid (/ Ymax 2.0))        ; 3.375

;;-------- 4. SEMICONDUCTOR LAYERS (top -> bottom in X) ------------;;
;; (position X_top Y_left)  (position X_bottom Y_right)
(sdegeo:create-rectangle (position x_surf      ys1 0) (position x_barr_bot  Ymax 0)
                         "AlGaN" "R_barrier")
(sdegeo:create-rectangle (position x_barr_bot  ys1 0) (position x_chan_bot  Ymax 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position x_chan_bot  ys1 0) (position x_bbarr_bot Ymax 0)
                         "AlGaN" "R_bbarrier")
(sdegeo:create-rectangle (position x_bbarr_bot ys1 0) (position x_cbuf_bot  Ymax 0)
                         "GaN"   "R_cbuffer")
(sdegeo:create-rectangle (position x_cbuf_bot  ys1 0) (position x_buf_bot   Ymax 0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position x_buf_bot   ys1 0) (position x_aln_bot   Ymax 0)
                         "AlN"   "R_nucleation")
(sdegeo:create-rectangle (position x_aln_bot   ys1 0) (position x_sic_bot   Ymax 0)
                         "SiC"   "R_substrate")

;;-------- 5. GATE DIELECTRIC (HfO2, between source & drain) -------;;
(sdegeo:create-rectangle (position x_diel_top ys2 0) (position x_surf yd1 0)
                         "HfO2" "R_dielectric")

;;-------- 6. METALS ----------------------------------------------;;
;; Source metal (on AlGaN surface, LEFT)
(sdegeo:create-rectangle (position x_sdm_top ys1 0) (position x_surf ys2 0)
                         "Aluminum" "R_source_metal")
;; Drain metal (on AlGaN surface, RIGHT)
(sdegeo:create-rectangle (position x_sdm_top yd1 0) (position x_surf yd2 0)
                         "Aluminum" "R_drain_metal")
;; Gate metal (on top of dielectric, CENTER-ish)
(sdegeo:create-rectangle (position x_gate_top yg1 0) (position x_diel_top yg2 0)
                         "Aluminum" "R_gate_metal")

;;-------- 7. MOLE FRACTIONS --------------------------------------;;
(sdedr:define-constant-profile        "Prof_xTop"  "xMoleFraction" x_top)
(sdedr:define-constant-profile-region "Place_xTop" "Prof_xTop"  "R_barrier")
(sdedr:define-constant-profile        "Prof_xBack" "xMoleFraction" x_back)
(sdedr:define-constant-profile-region "Place_xBack" "Prof_xBack" "R_bbarrier")

;;-------- 8. DOPING ---------------------------------------------;;
(sdedr:define-constant-profile        "Prof_Cbuf"  "BoronActiveConcentration" N_cbuf)
(sdedr:define-constant-profile-region "Place_Cbuf" "Prof_Cbuf" "R_cbuffer")
(sdedr:define-constant-profile        "Prof_UID"   "PhosphorusActiveConcentration" N_uid)
(sdedr:define-constant-profile-region "Place_UID"  "Prof_UID" "R_channel")
(sdedr:define-constant-profile        "Prof_SiC"   "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_SiC"  "Prof_SiC" "R_substrate")

;;-------- 9. CONTACTS (Source, Drain, Gate, Substrate) -----------;;
;; Contacts placed on the TOP edge of each metal / bottom of substrate.
(sdegeo:define-contact-set "source" 4.0 (color:rgb 1 0 0) "##")
(sdegeo:set-current-contact-set "source")
(sdegeo:define-2d-contact
   (find-edge-id (position x_sdm_top (/ (+ ys1 ys2) 2.0) 0)) "source")

(sdegeo:define-contact-set "drain" 4.0 (color:rgb 0 0 1) "##")
(sdegeo:set-current-contact-set "drain")
(sdegeo:define-2d-contact
   (find-edge-id (position x_sdm_top (/ (+ yd1 yd2) 2.0) 0)) "drain")

(sdegeo:define-contact-set "gate" 4.0 (color:rgb 0 1 0) "##")
(sdegeo:set-current-contact-set "gate")
(sdegeo:define-2d-contact
   (find-edge-id (position x_gate_top (/ (+ yg1 yg2) 2.0) 0)) "gate")

(sdegeo:define-contact-set "substrate" 4.0 (color:rgb 0.5 0.5 0.5) "##")
(sdegeo:set-current-contact-set "substrate")
(sdegeo:define-2d-contact
   (find-edge-id (position x_sic_bot ymid 0)) "substrate")

;;-------- 10. MESH REFINEMENT ------------------------------------;;
;; refinement-size args: (maxX maxY minX minY)  -- X=vertical, Y=lateral

;; Global (coarse)
(sdedr:define-refinement-size   "Ref_Global" 0.10 0.30 0.02 0.05)
(sdedr:define-refinement-window "RW_Global" "Rectangle"
   (position x_gate_top ys1 0) (position x_sic_bot Ymax 0))
(sdedr:define-refinement-placement "Place_Global" "Ref_Global" "RW_Global")

;; (1) AlGaN barrier / GaN channel interface  (2DEG, X ~ 0.020) -- fine
(sdedr:define-refinement-size   "Ref_2DEG" 0.0005 0.05 0.0001 0.01)
(sdedr:define-refinement-window "RW_2DEG" "Rectangle"
   (position 0.010 ys1 0) (position 0.035 Ymax 0))
(sdedr:define-refinement-placement "Place_2DEG" "Ref_2DEG" "RW_2DEG")

;; (2) Dielectric / AlGaN interface (X ~ 0.0)
(sdedr:define-refinement-size   "Ref_DielIF" 0.0005 0.05 0.0001 0.01)
(sdedr:define-refinement-window "RW_DielIF" "Rectangle"
   (position -0.005 ys2 0) (position 0.005 yd1 0))
(sdedr:define-refinement-placement "Place_DielIF" "Ref_DielIF" "RW_DielIF")

;; (3) Gate edges
(sdedr:define-refinement-size   "Ref_Gate" 0.005 0.01 0.001 0.002)
(sdedr:define-refinement-window "RW_Gate" "Rectangle"
   (position x_gate_top (- yg1 0.20) 0) (position x_chan_bot (+ yg2 0.20) 0))
(sdedr:define-refinement-placement "Place_Gate" "Ref_Gate" "RW_Gate")

;; (4) Source edge
(sdedr:define-refinement-size   "Ref_Src" 0.005 0.01 0.001 0.002)
(sdedr:define-refinement-window "RW_Src" "Rectangle"
   (position x_sdm_top (- ys2 0.15) 0) (position 0.050 (+ ys2 0.15) 0))
(sdedr:define-refinement-placement "Place_Src" "Ref_Src" "RW_Src")

;; (5) Drain edge
(sdedr:define-refinement-size   "Ref_Drn" 0.005 0.01 0.001 0.002)
(sdedr:define-refinement-window "RW_Drn" "Rectangle"
   (position x_sdm_top (- yd1 0.15) 0) (position 0.050 (+ yd1 0.15) 0))
(sdedr:define-refinement-placement "Place_Drn" "Ref_Drn" "RW_Drn")

;;-------- 11. BUILD MESH & SAVE ----------------------------------;;
(sde:build-mesh "snmesh" "" "Structure_B_msh")
(sde:save-model "Structure_B")
