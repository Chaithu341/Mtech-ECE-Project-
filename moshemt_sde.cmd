;;==================================================================;;
;; Sentaurus Structure Editor (SDE) - Cryogenic AlGaN/GaN MOS-HEMT
;; Tested syntax for Sentaurus T-2022.03
;;
;; Structure (top -> bottom):
;;   Gate metal (Al, WF=4.7eV) : 100 nm  (centered, length 0.25 um)
;;   HfO2 high-k             :   5 nm  (under gate only)
;;   Al2O3 interfacial       :   2 nm  (under gate only)
;;   AlGaN barrier           :  22 nm  (x_Al = 0.25)
;;   AlN spacer              :   1 nm
;;   UID GaN channel         : 100 nm
;;   Fe-doped GaN buffer     :   2 um  (semi-insulating, [Fe] = 5e18)
;;   SiC substrate           :   2 um
;;
;; Lateral (total = 5.0 um):
;;   Source ohmic            : 0.50 um
;;   S-G gap                 : 1.00 um
;;   Gate stack              : 0.25 um
;;   G-D gap                 : 2.75 um  (asymmetric for breakdown)
;;   Drain ohmic             : 0.50 um
;;
;; Coordinate convention:
;;   First arg of (position) = lateral y, second = depth (down +ve)
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")

;;-------- 1. PARAMETERS -------------------------------------------;;
(define L_src   0.50)
(define L_sg    1.00)
(define L_gate  0.25)
(define L_gd    2.75)
(define L_drn   0.50)
(define L_dev   (+ L_src L_sg L_gate L_gd L_drn))    ; = 5.00

(define t_gate  0.100)   ; TiN gate metal
(define t_hfo2  0.005)   ; HfO2
(define t_al2o3 0.002)   ; Al2O3 IL
(define t_barr  0.022)   ; AlGaN barrier
(define t_spcr  0.001)   ; AlN spacer
(define t_chan  0.100)   ; UID GaN channel
(define t_buf   2.000)   ; Fe-doped GaN buffer
(define t_sic   2.000)   ; SiC substrate

(define x_Al    0.25)    ; AlGaN Al fraction
(define N_Fe    5.0e18)  ; Fe doping in buffer
(define N_uid   1.0e15)  ; UID background

;;-------- 2. LATERAL EDGES ----------------------------------------;;
(define ys1 0.0)
(define ys2 L_src)                          ; 0.50
(define yg1 (+ L_src L_sg))                 ; 1.50
(define yg2 (+ yg1 L_gate))                 ; 1.75
(define yd1 (+ yg2 L_gd))                   ; 4.50
(define yd2 L_dev)                          ; 5.00

;;-------- 3. DEPTH COORDINATES (top down) -------------------------;;
(define d_gtop  (- 0 t_gate))               ; -0.100 (gate metal top)
(define d_hf_t  (- 0 (+ t_hfo2 t_al2o3)))   ; -0.007 (HfO2 top)
(define d_al_t  (- 0 t_al2o3))              ; -0.002 (Al2O3 top)
(define d0      0.0)                        ; AlGaN barrier top (semiconductor surface)
(define d1      (+ d0  t_barr))             ; 0.022   barrier/spacer
(define d2      (+ d1  t_spcr))             ; 0.023   spacer/channel  (2DEG !)
(define d3      (+ d2  t_chan))             ; 0.123   channel/buffer
(define d4      (+ d3  t_buf))              ; 2.123   buffer/SiC
(define d5      (+ d4  t_sic))              ; 4.123   SiC bottom

;;-------- 4. SEMICONDUCTOR LAYERS (bottom -> top) -----------------;;
(sdegeo:create-rectangle (position 0     d4 0) (position L_dev d5 0)
                         "SiC"   "R_sub")
(sdegeo:create-rectangle (position 0     d3 0) (position L_dev d4 0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position 0     d2 0) (position L_dev d3 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position 0     d1 0) (position L_dev d2 0)
                         "AlN"   "R_spacer")
(sdegeo:create-rectangle (position 0     d0 0) (position L_dev d1 0)
                         "AlGaN" "R_barrier")

;;-------- 5. GATE DIELECTRIC STACK (only under gate) --------------;;
(sdegeo:create-rectangle (position yg1 d_al_t 0) (position yg2 d0     0)
                         "Aluminum2O3" "R_Al2O3")
(sdegeo:create-rectangle (position yg1 d_hf_t 0) (position yg2 d_al_t 0)
                         "HfO2"        "R_HfO2")

;;-------- 6. GATE METAL -------------------------------------------;;
;; NOTE: Material is "Aluminum" (always present in datexcodes.txt).
;; Actual workfunction is set in the SDevice Electrode block
;; (Workfunction=4.7 eV gives TiN-like behavior).
(sdegeo:create-rectangle (position yg1 d_gtop 0) (position yg2 d_hf_t 0)
                         "Aluminum"  "R_gate_metal")

;;-------- 7. SPLIT TOP EDGE FOR S/D CONTACTS ----------------------;;
;; Inserts vertices at y=0.50 and y=4.50 on the AlGaN top edge so
;; that source and drain contacts land on clean, defined segments.
(sdegeo:insert-vertex (position ys2 d0 0))
(sdegeo:insert-vertex (position yd1 d0 0))

;;-------- 8. MOLE FRACTION ----------------------------------------;;
(sdedr:define-constant-profile        "Prof_xAl"
   "xMoleFraction" x_Al)
(sdedr:define-constant-profile-region "Place_xAl"
   "Prof_xAl" "R_barrier")

;;-------- 9. DOPING -----------------------------------------------;;
;; Fe-doped GaN buffer (Fe is deep acceptor in GaN, ~0.6 eV below CB)
;; We use Boron concentration as a proxy acceptor; the trap level is
;; defined in models.par to give Fe-like behavior.
(sdedr:define-constant-profile        "Prof_Fe"
   "BoronActiveConcentration" N_Fe)
(sdedr:define-constant-profile-region "Place_Fe"
   "Prof_Fe" "R_buffer")

;; UID GaN channel - very light n-type background
(sdedr:define-constant-profile        "Prof_UID"
   "PhosphorusActiveConcentration" N_uid)
(sdedr:define-constant-profile-region "Place_UID"
   "Prof_UID" "R_channel")

;; SiC substrate - light n-type
(sdedr:define-constant-profile        "Prof_SiC"
   "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_SiC"
   "Prof_SiC" "R_sub")

;;-------- 10. CONTACTS --------------------------------------------;;
;; Source (ohmic, on top of AlGaN barrier)
(sdegeo:define-contact-set "source" 4.0 (color:rgb 1 0 0) "##")
(sdegeo:set-current-contact-set "source")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (* 0.5 (+ ys1 ys2)) d0 0))))
   "source")

;; Drain (ohmic)
(sdegeo:define-contact-set "drain"  4.0 (color:rgb 0 0 1) "##")
(sdegeo:set-current-contact-set "drain")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (* 0.5 (+ yd1 yd2)) d0 0))))
   "drain")

;; Gate (on top of TiN metal block)
(sdegeo:define-contact-set "gate"   4.0 (color:rgb 0 1 0) "##")
(sdegeo:set-current-contact-set "gate")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (* 0.5 (+ yg1 yg2)) d_gtop 0))))
   "gate")

;; Substrate (thermode / back contact for thermal boundary)
(sdegeo:define-contact-set "substrate" 4.0 (color:rgb 0.5 0.5 0.5) "##")
(sdegeo:set-current-contact-set "substrate")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (* 0.5 L_dev) d5 0))))
   "substrate")

;;-------- 11. MESH REFINEMENT -------------------------------------;;
;; Global coarse
(sdedr:define-refinement-size "Ref_Global"
   0.25 0.25
   0.05 0.05)
(sdedr:define-refinement-region "Place_Global"
   "Ref_Global" "R_sub")

;; 2DEG: very fine vertical mesh at AlN/GaN interface (d = 0.023 um)
(sdedr:define-refinement-window "RW_2DEG"
   "Rectangle"
   (position 0     (- d2 0.005) 0)
   (position L_dev (+ d2 0.010) 0))
(sdedr:define-refinement-size "Ref_2DEG"
   0.05  0.0005
   0.005 0.0001)
(sdedr:define-refinement-placement "Place_2DEG"
   "Ref_2DEG" "RW_2DEG")

;; Gate stack: fine vertical mesh through Al2O3/HfO2
(sdedr:define-refinement-window "RW_GateOx"
   "Rectangle"
   (position (- yg1 0.05) d_hf_t 0)
   (position (+ yg2 0.05) d0     0))
(sdedr:define-refinement-size "Ref_GateOx"
   0.02  0.0005
   0.005 0.0001)
(sdedr:define-refinement-placement "Place_GateOx"
   "Ref_GateOx" "RW_GateOx")

;; Lateral refinement at gate edges (field crowding)
(sdedr:define-refinement-window "RW_GateEdge"
   "Rectangle"
   (position (- yg1 0.15) d_gtop 0)
   (position (+ yg2 0.15) d3     0))
(sdedr:define-refinement-size "Ref_GateEdge"
   0.01 0.005
   0.002 0.001)
(sdedr:define-refinement-placement "Place_GateEdge"
   "Ref_GateEdge" "RW_GateEdge")

;;-------- 12. BUILD MESH AND SAVE ---------------------------------;;
(sde:build-mesh "snmesh" "" "n@node@_msh")
(sde:save-model "n@node@")
