;;==================================================================;;
;; Sentaurus Structure Editor (SDE)  -  T-2022.03
;; AlGaN/GaN MIS-HEMT  (Al2O3 gate dielectric, recessed ohmic S/D)
;; Single clean publishable device for cryogenic low-noise study.
;;
;; ORIENTATION:
;;   X = VERTICAL (growth); Y = HORIZONTAL (lateral, source->drain).
;;   (position X Y Z): 1st arg = X (vertical), 2nd = Y (lateral).
;;   X=0 at semiconductor surface; +X DOWN into substrate;
;;   -X UP toward air (dielectric, metals).
;;   Source = LEFT, Drain = RIGHT, Substrate = BOTTOM.
;;
;; STACK (top -> bottom):
;;   Gate metal (Al)        50 nm   (on dielectric, MIS gate)
;;   Al2O3 dielectric        8 nm
;;   AlGaN barrier          22 nm   (x_Al = 0.25)   <- 2DEG at its base
;;   UID GaN channel       200 nm
;;   C-doped GaN buffer    1.0 um   (isolation, low leakage)
;;   AlN nucleation        100 nm
;;   SiC substrate         1.0 um
;;
;; RECESSED OHMICS: source/drain metal is etched through the AlGaN
;; barrier and into the channel so the metal sidewall directly contacts
;; the 2DEG -> low contact resistance, real mA-level currents.
;;
;; LATERAL: Src 0.5 / S-G 0.5 / Gate 0.25 / G-D 1.0 / Drn 0.5 um
;;          (total 2.75 um)
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")   ; new region overrides old in overlap

;;-------- 1. PARAMETERS -------------------------------------------;;
;; Vertical thicknesses (um)
(define t_barr  0.022)   ; AlGaN barrier
(define t_chan  0.200)   ; UID GaN channel
(define t_buf   1.000)   ; C-doped GaN buffer
(define t_aln   0.100)   ; AlN nucleation
(define t_sic   1.000)   ; SiC substrate
(define t_diel  0.008)   ; Al2O3 gate dielectric
(define t_gm    0.050)   ; gate metal
(define t_sdm   0.050)   ; source/drain metal

;; Lateral lengths (um)
(define L_src   0.50)
(define L_sg    0.50)
(define L_gate  0.25)
(define L_gd    1.00)
(define L_drn   0.50)

;; Mole fraction / doping
(define x_Al    0.25)
(define N_buf   1.0e18)  ; C in buffer (acceptor proxy, isolation)
(define N_uid   1.0e15)  ; UID channel background

;;-------- 2. VERTICAL (X) COORDINATES -----------------------------;;
(define x_surf      0.0)
(define x_barr_bot  (+ x_surf     t_barr))   ; 0.022  (2DEG here)
(define x_chan_bot  (+ x_barr_bot t_chan))   ; 0.222
(define x_buf_bot   (+ x_chan_bot t_buf))    ; 1.222
(define x_aln_bot   (+ x_buf_bot  t_aln))    ; 1.322
(define x_sic_bot   (+ x_aln_bot  t_sic))    ; 2.322

(define x_diel_top  (- x_surf t_diel))       ; -0.008
(define x_gate_top  (- x_diel_top t_gm))     ; -0.058
(define x_sdm_top   (- x_surf t_sdm))        ; -0.050
(define x_recess    (+ x_barr_bot 0.010))    ; 0.032 (10 nm past 2DEG)

;;-------- 3. LATERAL (Y) COORDINATES ------------------------------;;
(define ys1 0.0)
(define ys2 L_src)                 ; 0.50
(define yg1 (+ L_src L_sg))        ; 1.00
(define yg2 (+ yg1 L_gate))        ; 1.25
(define yd1 (+ yg2 L_gd))          ; 2.25
(define yd2 (+ yd1 L_drn))         ; 2.75
(define Ymax yd2)                  ; 2.75
(define ymid (/ Ymax 2.0))         ; 1.375

;;-------- 4. SEMICONDUCTOR LAYERS (top -> bottom in X) ------------;;
(sdegeo:create-rectangle (position x_surf     ys1 0) (position x_barr_bot Ymax 0)
                         "AlGaN" "R_barrier")
(sdegeo:create-rectangle (position x_barr_bot ys1 0) (position x_chan_bot Ymax 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position x_chan_bot ys1 0) (position x_buf_bot  Ymax 0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position x_buf_bot  ys1 0) (position x_aln_bot  Ymax 0)
                         "AlN"   "R_nucleation")
(sdegeo:create-rectangle (position x_aln_bot  ys1 0) (position x_sic_bot  Ymax 0)
                         "SiC"   "R_substrate")

;;-------- 5. GATE DIELECTRIC (Al2O3, between source & drain) ------;;
(sdegeo:create-rectangle (position x_diel_top ys2 0) (position x_surf yd1 0)
                         "Aluminum2O3" "R_dielectric")

;;-------- 6. METALS (RECESSED ohmic S/D reaching the 2DEG) -------;;
;; Source/drain metal recessed through AlGaN into the channel; the
;; sidewall crosses the 2DEG plane (x=0.022) for a direct ohmic contact.
(sdegeo:create-rectangle (position x_sdm_top ys1 0) (position x_recess ys2 0)
                         "Aluminum" "R_source_metal")
(sdegeo:create-rectangle (position x_sdm_top yd1 0) (position x_recess yd2 0)
                         "Aluminum" "R_drain_metal")
;; Gate metal on top of dielectric (MIS gate)
(sdegeo:create-rectangle (position x_gate_top yg1 0) (position x_diel_top yg2 0)
                         "Aluminum" "R_gate_metal")

;;-------- 7. MOLE FRACTION & DOPING -------------------------------;;
(sdedr:define-constant-profile        "Prof_xAl"  "xMoleFraction" x_Al)
(sdedr:define-constant-profile-region "Place_xAl" "Prof_xAl" "R_barrier")

(sdedr:define-constant-profile        "Prof_buf"  "BoronActiveConcentration" N_buf)
(sdedr:define-constant-profile-region "Place_buf" "Prof_buf" "R_buffer")
(sdedr:define-constant-profile        "Prof_uid"  "PhosphorusActiveConcentration" N_uid)
(sdedr:define-constant-profile-region "Place_uid" "Prof_uid" "R_channel")
(sdedr:define-constant-profile        "Prof_sic"  "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_sic" "Prof_sic" "R_substrate")

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

;; Global coarse
(sdedr:define-refinement-size   "Ref_Glob" 0.10 0.20 0.02 0.05)
(sdedr:define-refinement-window "RW_Glob" "Rectangle"
   (position x_gate_top ys1 0) (position x_sic_bot Ymax 0))
(sdedr:define-refinement-placement "Pl_Glob" "Ref_Glob" "RW_Glob")

;; 2DEG: very fine vertical mesh at AlGaN/channel interface (x=0.022)
(sdedr:define-refinement-size   "Ref_2DEG" 0.0005 0.05 0.0001 0.01)
(sdedr:define-refinement-window "RW_2DEG" "Rectangle"
   (position 0.012 ys1 0) (position 0.040 Ymax 0))
(sdedr:define-refinement-placement "Pl_2DEG" "Ref_2DEG" "RW_2DEG")

;; Dielectric / barrier surface (x ~ 0)
(sdedr:define-refinement-size   "Ref_Surf" 0.001 0.05 0.0002 0.01)
(sdedr:define-refinement-window "RW_Surf" "Rectangle"
   (position -0.009 ys2 0) (position 0.005 yd1 0))
(sdedr:define-refinement-placement "Pl_Surf" "Ref_Surf" "RW_Surf")

;; Gate region (lateral field crowding at gate edges)
(sdedr:define-refinement-size   "Ref_Gate" 0.005 0.01 0.001 0.002)
(sdedr:define-refinement-window "RW_Gate" "Rectangle"
   (position x_gate_top (- yg1 0.15) 0) (position x_chan_bot (+ yg2 0.15) 0))
(sdedr:define-refinement-placement "Pl_Gate" "Ref_Gate" "RW_Gate")

;;-------- 10. BUILD MESH & SAVE -----------------------------------;;
(sde:build-mesh "snmesh" "" "mishemt_msh")
(sde:save-model "mishemt")
