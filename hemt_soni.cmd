;;==================================================================;;
;; Sentaurus Structure Editor (SDE)  -  T-2022.03
;; AlN/GaN HEMT  (after Soni & Shrivastava, Fig. 1a)
;;   AlN barrier (3.5 nm) + GaN cap (2.5 nm) + SiN passivation (40 nm),
;;   recessed gate (foot on GaN cap) and recessed ohmic source/drain.
;;
;; ORIENTATION:
;;   X = VERTICAL (growth); Y = HORIZONTAL (lateral, source->drain).
;;   (position X Y Z): 1st arg = X (vertical), 2nd = Y (lateral).
;;   X=0 at GaN-cap top surface; +X DOWN into substrate; -X UP to air.
;;   Source = LEFT, Drain = RIGHT, Substrate = BOTTOM.
;;
;; STACK (top -> bottom):
;;   Gate metal (recessed through SiN to GaN cap)
;;   SiN passivation        40 nm   (access regions only)
;;   GaN cap               2.5 nm
;;   AlN barrier           3.5 nm   <- 2DEG at its base (X=0.006)
;;   UID GaN channel        150 nm
;;   C-doped GaN buffer     1.5 um
;;   GaN buffer             250 nm
;;   AlN nucleation         100 nm
;;   SiC substrate          1.0 um
;;
;; LATERAL: Ls 0.20 / Lsg 0.04 / Lg 0.02 / Lgd 0.04 / Ld 0.20 um
;;          (total 0.50 um ; gate centered)
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")   ; new region overrides old in overlap

;;-------- 1. PARAMETERS -------------------------------------------;;
;; Vertical thicknesses (um)
(define t_cap   0.0025)  ; GaN cap
(define t_barr  0.0035)  ; AlN barrier
(define t_chan  0.150)   ; UID GaN channel
(define t_cbuf  1.500)   ; C-doped GaN buffer
(define t_buf   0.250)   ; GaN buffer
(define t_aln   0.100)   ; AlN nucleation
(define t_sic   1.000)   ; SiC substrate
(define t_sin   0.040)   ; SiN passivation
(define t_gm    0.050)   ; gate metal
(define t_sdm   0.050)   ; source/drain metal

;; Lateral lengths (um)
(define L_src   0.200)
(define L_sg    0.040)
(define L_gate  0.020)
(define L_gd    0.040)
(define L_drn   0.200)

;; Doping
(define N_cbuf  1.0e18)  ; C in buffer (acceptor proxy, isolation)
(define N_uid   1.0e15)  ; UID background

;;-------- 2. VERTICAL (X) COORDINATES (surface=0, +down) ----------;;
(define x_surf      0.0)
(define x_cap_bot   (+ x_surf     t_cap))    ; 0.0025
(define x_barr_bot  (+ x_cap_bot  t_barr))   ; 0.0060  (2DEG)
(define x_chan_bot  (+ x_barr_bot t_chan))   ; 0.1560
(define x_cbuf_bot  (+ x_chan_bot t_cbuf))   ; 1.6560
(define x_buf_bot   (+ x_cbuf_bot t_buf))    ; 1.9060
(define x_aln_bot   (+ x_buf_bot  t_aln))    ; 2.0060
(define x_sic_bot   (+ x_aln_bot  t_sic))    ; 3.0060

(define x_sin_top   (- x_surf t_sin))        ; -0.040
(define x_gate_top  (- x_sin_top t_gm))      ; -0.090
(define x_sdm_top   (- x_surf t_sdm))        ; -0.050
(define x_recess    (+ x_barr_bot 0.010))    ; 0.016 (10 nm past 2DEG)

;;-------- 3. LATERAL (Y) COORDINATES ------------------------------;;
(define ys1 0.0)
(define ys2 L_src)                 ; 0.200
(define yg1 (+ L_src L_sg))        ; 0.240
(define yg2 (+ yg1 L_gate))        ; 0.260
(define yd1 (+ yg2 L_gd))          ; 0.300
(define yd2 (+ yd1 L_drn))         ; 0.500
(define Ymax yd2)                  ; 0.500
(define ymid (/ Ymax 2.0))         ; 0.250

;;-------- 4. SEMICONDUCTOR LAYERS (top -> bottom in X) ------------;;
(sdegeo:create-rectangle (position x_surf     ys1 0) (position x_cap_bot  Ymax 0)
                         "GaN"   "R_cap")
(sdegeo:create-rectangle (position x_cap_bot  ys1 0) (position x_barr_bot Ymax 0)
                         "AlN"   "R_barrier")
(sdegeo:create-rectangle (position x_barr_bot ys1 0) (position x_chan_bot Ymax 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position x_chan_bot ys1 0) (position x_cbuf_bot Ymax 0)
                         "GaN"   "R_cbuffer")
(sdegeo:create-rectangle (position x_cbuf_bot ys1 0) (position x_buf_bot  Ymax 0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position x_buf_bot  ys1 0) (position x_aln_bot  Ymax 0)
                         "AlN"   "R_nucleation")
(sdegeo:create-rectangle (position x_aln_bot  ys1 0) (position x_sic_bot  Ymax 0)
                         "SiC"   "R_substrate")

;;-------- 5. SiN PASSIVATION (access regions, split by gate) ------;;
;; Left  passivation: source-side access (ys2 -> yg1)
(sdegeo:create-rectangle (position x_sin_top ys2 0) (position x_surf yg1 0)
                         "Si3N4" "R_sin_L")
;; Right passivation: drain-side access (yg2 -> yd1)
(sdegeo:create-rectangle (position x_sin_top yg2 0) (position x_surf yd1 0)
                         "Si3N4" "R_sin_R")

;;-------- 6. METALS ----------------------------------------------;;
;; Recessed source/drain: punch through GaN cap + AlN barrier into the
;; channel so the metal sidewall directly contacts the 2DEG.
(sdegeo:create-rectangle (position x_sdm_top ys1 0) (position x_recess ys2 0)
                         "Aluminum" "R_source_metal")
(sdegeo:create-rectangle (position x_sdm_top yd1 0) (position x_recess yd2 0)
                         "Aluminum" "R_drain_metal")
;; Recessed gate: foot fills the SiN trench and sits on the GaN cap.
(sdegeo:create-rectangle (position x_gate_top yg1 0) (position x_surf yg2 0)
                         "Aluminum" "R_gate_metal")

;;-------- 7. DOPING ---------------------------------------------;;
(sdedr:define-constant-profile        "Prof_cbuf"  "BoronActiveConcentration" N_cbuf)
(sdedr:define-constant-profile-region "Place_cbuf" "Prof_cbuf" "R_cbuffer")
(sdedr:define-constant-profile        "Prof_uid"   "PhosphorusActiveConcentration" N_uid)
(sdedr:define-constant-profile-region "Place_uid"  "Prof_uid" "R_channel")
(sdedr:define-constant-profile        "Prof_sic"   "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_sic"  "Prof_sic" "R_substrate")

;;-------- 8. CONTACTS (source, drain, gate, substrate) -----------;;
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

;;-------- 9. MESH REFINEMENT --------------------------------------;;
;; refinement-size args: (maxX maxY minX minY)  X=vertical, Y=lateral
;; NOTE: the cap (2.5 nm) + barrier (3.5 nm) are extremely thin, so the
;; top region needs sub-nm vertical resolution.

;; Global coarse
(sdedr:define-refinement-size   "Ref_Glob" 0.10 0.02 0.02 0.005)
(sdedr:define-refinement-window "RW_Glob" "Rectangle"
   (position x_gate_top ys1 0) (position x_sic_bot Ymax 0))
(sdedr:define-refinement-placement "Pl_Glob" "Ref_Glob" "RW_Glob")

;; Top stack: GaN cap + AlN barrier + 2DEG (x from -0.001 to 0.020)
(sdedr:define-refinement-size   "Ref_Top" 0.0003 0.01 0.00005 0.002)
(sdedr:define-refinement-window "RW_Top" "Rectangle"
   (position -0.001 ys1 0) (position 0.020 Ymax 0))
(sdedr:define-refinement-placement "Pl_Top" "Ref_Top" "RW_Top")

;; Gate region (lateral, around the 20 nm gate)
(sdedr:define-refinement-size   "Ref_Gate" 0.002 0.003 0.0005 0.001)
(sdedr:define-refinement-window "RW_Gate" "Rectangle"
   (position x_gate_top (- yg1 0.03) 0) (position x_chan_bot (+ yg2 0.03) 0))
(sdedr:define-refinement-placement "Pl_Gate" "Ref_Gate" "RW_Gate")

;;-------- 10. BUILD MESH & SAVE -----------------------------------;;
(sde:build-mesh "snmesh" "" "hemt_soni_msh")
(sde:save-model "hemt_soni")
