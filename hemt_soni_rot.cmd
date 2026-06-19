;;==================================================================;;
;; Sentaurus Structure Editor (SDE)  -  T-2022.03
;; AlN/GaN HEMT (after Soni & Shrivastava, Fig. 1a)
;; *** ROTATED 90 DEGREES CLOCKWISE vs the upright cross-section ***
;;
;; ORIENTATION AFTER ROTATION:
;;   Growth/stack direction runs HORIZONTALLY (now the 2nd position arg).
;;   Lateral source->drain runs VERTICALLY   (now the 1st position arg).
;;   (position A B Z): A = lateral (source..drain), B = growth (cap..substrate)
;;   Growth B increases to the RIGHT: GaN-cap/SiN/gate at small B (LEFT),
;;     SiC substrate at large B (RIGHT).
;;   Lateral A: Source at small A (TOP), Drain at large A (BOTTOM).
;;   => clockwise-rotated device: substrate on the right, gate on the left,
;;      source on top, drain on bottom.
;;
;; STACK (left -> right after rotation):
;;   Gate metal / SiN passivation / GaN cap / AlN barrier (2DEG) /
;;   UID GaN channel / C-doped GaN buffer / GaN buffer /
;;   AlN nucleation / SiC substrate
;;
;; DIMENSIONS unchanged from the upright file.
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")

;;-------- 1. PARAMETERS -------------------------------------------;;
;; Growth-direction thicknesses (um)
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

;; Lateral (source..drain) lengths (um)
(define L_src   0.200)
(define L_sg    0.040)
(define L_gate  0.020)
(define L_gd    0.040)
(define L_drn   0.200)

;; Doping
(define N_cbuf  1.0e18)
(define N_uid   1.0e15)

;;-------- 2. GROWTH-DIRECTION (B) COORDINATES --------------------;;
;; B = 0 at GaN-cap surface; +B to the RIGHT into the substrate;
;; -B to the LEFT toward air (SiN, gate).
(define b_surf      0.0)
(define b_cap_bot   (+ b_surf     t_cap))    ; 0.0025
(define b_barr_bot  (+ b_cap_bot  t_barr))   ; 0.0060  (2DEG)
(define b_chan_bot  (+ b_barr_bot t_chan))   ; 0.1560
(define b_cbuf_bot  (+ b_chan_bot t_cbuf))   ; 1.6560
(define b_buf_bot   (+ b_cbuf_bot t_buf))    ; 1.9060
(define b_aln_bot   (+ b_buf_bot  t_aln))    ; 2.0060
(define b_sic_bot   (+ b_aln_bot  t_sic))    ; 3.0060

(define b_sin_top   (- b_surf t_sin))        ; -0.040
(define b_gate_top  (- b_sin_top t_gm))      ; -0.090
(define b_sdm_top   (- b_surf t_sdm))        ; -0.050
(define b_recess    (+ b_barr_bot 0.010))    ; 0.016

;;-------- 3. LATERAL (A) COORDINATES (source TOP -> drain BOTTOM) -;;
(define as1 0.0)
(define as2 L_src)                 ; 0.200
(define ag1 (+ L_src L_sg))        ; 0.240
(define ag2 (+ ag1 L_gate))        ; 0.260
(define ad1 (+ ag2 L_gd))          ; 0.300
(define ad2 (+ ad1 L_drn))         ; 0.500
(define Amax ad2)                  ; 0.500
(define amid (/ Amax 2.0))         ; 0.250

;;-------- 4. SEMICONDUCTOR LAYERS --------------------------------;;
;; (position A_lateral B_growth Z) : layers now stack along B (horizontal)
(sdegeo:create-rectangle (position as1 b_surf     0) (position Amax b_cap_bot  0)
                         "GaN"   "R_cap")
(sdegeo:create-rectangle (position as1 b_cap_bot  0) (position Amax b_barr_bot 0)
                         "AlN"   "R_barrier")
(sdegeo:create-rectangle (position as1 b_barr_bot 0) (position Amax b_chan_bot 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position as1 b_chan_bot 0) (position Amax b_cbuf_bot 0)
                         "GaN"   "R_cbuffer")
(sdegeo:create-rectangle (position as1 b_cbuf_bot 0) (position Amax b_buf_bot  0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position as1 b_buf_bot  0) (position Amax b_aln_bot  0)
                         "AlN"   "R_nucleation")
(sdegeo:create-rectangle (position as1 b_aln_bot  0) (position Amax b_sic_bot  0)
                         "SiC"   "R_substrate")

;;-------- 5. SiN PASSIVATION (access regions, split by gate) ------;;
(sdegeo:create-rectangle (position as2 b_sin_top 0) (position ag1 b_surf 0)
                         "Si3N4" "R_sin_L")
(sdegeo:create-rectangle (position ag2 b_sin_top 0) (position ad1 b_surf 0)
                         "Si3N4" "R_sin_R")

;;-------- 6. METALS ----------------------------------------------;;
;; Recessed source/drain reaching the 2DEG
(sdegeo:create-rectangle (position as1 b_sdm_top 0) (position as2 b_recess 0)
                         "Aluminum" "R_source_metal")
(sdegeo:create-rectangle (position ad1 b_sdm_top 0) (position ad2 b_recess 0)
                         "Aluminum" "R_drain_metal")
;; Recessed gate: foot through SiN onto the GaN cap
(sdegeo:create-rectangle (position ag1 b_gate_top 0) (position ag2 b_surf 0)
                         "Aluminum" "R_gate_metal")

;;-------- 7. DOPING ---------------------------------------------;;
(sdedr:define-constant-profile        "Prof_cbuf"  "BoronActiveConcentration" N_cbuf)
(sdedr:define-constant-profile-region "Place_cbuf" "Prof_cbuf" "R_cbuffer")
(sdedr:define-constant-profile        "Prof_uid"   "PhosphorusActiveConcentration" N_uid)
(sdedr:define-constant-profile-region "Place_uid"  "Prof_uid" "R_channel")
(sdedr:define-constant-profile        "Prof_sic"   "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_sic"  "Prof_sic" "R_substrate")

;;-------- 8. CONTACTS -------------------------------------------;;
;; Source: outer (left) edge of source metal -> at growth B = b_sdm_top
(sdegeo:define-contact-set "source" 4.0 (color:rgb 1 0 0) "##")
(sdegeo:set-current-contact-set "source")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ as1 as2) 2.0) b_sdm_top 0)) "source")

(sdegeo:define-contact-set "drain" 4.0 (color:rgb 0 0 1) "##")
(sdegeo:set-current-contact-set "drain")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ ad1 ad2) 2.0) b_sdm_top 0)) "drain")

(sdegeo:define-contact-set "gate" 4.0 (color:rgb 0 1 0) "##")
(sdegeo:set-current-contact-set "gate")
(sdegeo:define-2d-contact
   (find-edge-id (position (/ (+ ag1 ag2) 2.0) b_gate_top 0)) "gate")

;; Substrate: far (right) edge of SiC -> at growth B = b_sic_bot
(sdegeo:define-contact-set "substrate" 4.0 (color:rgb 0.5 0.5 0.5) "##")
(sdegeo:set-current-contact-set "substrate")
(sdegeo:define-2d-contact
   (find-edge-id (position amid b_sic_bot 0)) "substrate")

;;-------- 9. MESH REFINEMENT ------------------------------------;;
;; refinement-size args order follows (size_along_1st_arg, size_along_2nd_arg, ...)
;; i.e. (A-size  B-size  A-min  B-min). B (growth) needs the fine resolution.

;; Global coarse
(sdedr:define-refinement-size   "Ref_Glob" 0.02 0.10 0.005 0.02)
(sdedr:define-refinement-window "RW_Glob" "Rectangle"
   (position as1 b_gate_top 0) (position Amax b_sic_bot 0))
(sdedr:define-refinement-placement "Pl_Glob" "Ref_Glob" "RW_Glob")

;; Top stack: GaN cap + AlN barrier + 2DEG (B from -0.001 to 0.020), fine in B
(sdedr:define-refinement-size   "Ref_Top" 0.01 0.0003 0.002 0.00005)
(sdedr:define-refinement-window "RW_Top" "Rectangle"
   (position as1 -0.001 0) (position Amax 0.020 0))
(sdedr:define-refinement-placement "Pl_Top" "Ref_Top" "RW_Top")

;; Gate region (fine along lateral A around the 20 nm gate)
(sdedr:define-refinement-size   "Ref_Gate" 0.003 0.002 0.001 0.0005)
(sdedr:define-refinement-window "RW_Gate" "Rectangle"
   (position (- ag1 0.03) b_gate_top 0) (position (+ ag2 0.03) b_chan_bot 0))
(sdedr:define-refinement-placement "Pl_Gate" "Ref_Gate" "RW_Gate")

;;-------- 10. BUILD MESH & SAVE -----------------------------------;;
(sde:build-mesh "snmesh" "" "hemt_soni_rot_msh")
(sde:save-model "hemt_soni_rot")
