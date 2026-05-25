;;==================================================================;;
;; Sentaurus Structure Editor (SDE) - AlGaN/GaN HEMT
;; Built to exact dimensions from Table 9.1 / 9.2 of the proposed
;; design. Cross-section is 2D in the (lateral, depth) plane.
;;
;; CONVENTION in this file:
;;   First coordinate in (position a b c)  = lateral (source->drain)
;;   Second coordinate                     = depth (0 at top surface,
;;                                            positive going down)
;;   Third coordinate                      = 0 (2D simulation)
;;
;; LAYER STACK (top -> bottom, from Table 9.1):
;;   Gate metal       :  50 nm  (Ni, only under gate, sits at d<0)
;;   AlGaN barrier    :  40 nm  (x_Al = 0.25)
;;   AlN spacer       :   1 nm  (interlayer - boosts 2DEG mobility)
;;   GaN channel      : 150 nm  (UID)
;;   AlGaN back barr. :  23 nm  (x_Al = 0.07, assumed - see note)
;;   C-doped GaN buf. : 1.5 um  ([C] = 1e18 cm-3, deep acceptor)
;;   GaN buffer       : 250 nm
;;   AlN nucleation   : 100 nm
;;   SiC substrate    :   2 um
;;
;; LATERAL DIMENSIONS (Table 9.2):
;;   Source contact   : 250 nm
;;   Source-Gate gap  :   1 um
;;   Gate length      : 250 nm
;;   Gate-Drain gap   :   5 um
;;   Drain contact    : 250 nm
;;   TOTAL            : 6.75 um
;;==================================================================;;

(sde:clear)
(sdegeo:set-default-boolean "ABA")   ; new rectangles override existing

;;------------------------------------------------------------------;;
;; 1. DIMENSION PARAMETERS (edit only here if you change geometry)
;;------------------------------------------------------------------;;
;; Lateral (all in um)
(define L_src      0.250)
(define L_sg       1.000)
(define L_gate     0.250)
(define L_gd       5.000)
(define L_drn      0.250)
(define L_dev      (+ L_src L_sg L_gate L_gd L_drn))   ; = 6.75

;; Depth (all in um, positive = into device)
(define t_gate_m   0.050)   ; gate metal height (sits above d=0)
(define t_barr     0.040)   ; AlGaN barrier
(define t_spacer   0.001)   ; AlN spacer (1 nm)
(define t_chan     0.150)   ; GaN channel
(define t_bbarr    0.023)   ; AlGaN back-barrier
(define t_cbuf     1.500)   ; C-doped GaN buffer
(define t_buf      0.250)   ; GaN buffer
(define t_aln_n    0.100)   ; AlN nucleation
(define t_sic      2.000)   ; SiC substrate

;; Mole fractions
(define x_Al_top   0.25)    ; from caption "0.25 mole fraction"
(define x_Al_back  0.07)    ; NOT specified in figure; typical value.
                            ; Change if your design uses a different x.

;; Doping
(define N_cbuf     1.0e18)  ; C concentration in C-doped buffer

;;------------------------------------------------------------------;;
;; 2. COMPUTE Y-RANGES FOR EACH FEATURE
;;------------------------------------------------------------------;;
;; Lateral coordinates of contact edges
(define y_src1 0.0)
(define y_src2 L_src)                       ; 0.25
(define y_g1   (+ L_src L_sg))              ; 1.25
(define y_g2   (+ y_g1 L_gate))             ; 1.50
(define y_drn1 (+ y_g2 L_gd))               ; 6.50
(define y_drn2 L_dev)                       ; 6.75

;; Depth coordinates (positive = down)
(define d_gtop  (- 0 t_gate_m))             ; top of gate metal = -0.050
(define d0      0.0)                        ; top of AlGaN barrier
(define d1      (+ d0  t_barr))             ; AlGaN/AlN-spacer  = 0.040
(define d2      (+ d1  t_spacer))           ; AlN/GaN channel   = 0.041
(define d3      (+ d2  t_chan))             ; channel/back-barr = 0.191
(define d4      (+ d3  t_bbarr))            ; back-barr/C-buf   = 0.214
(define d5      (+ d4  t_cbuf))             ; C-buf/buf         = 1.714
(define d6      (+ d5  t_buf))              ; buf/AlN nucl      = 1.964
(define d7      (+ d6  t_aln_n))            ; AlN nucl/SiC      = 2.064
(define d8      (+ d7  t_sic))              ; SiC bottom        = 4.064

;;------------------------------------------------------------------;;
;; 3. CREATE SEMICONDUCTOR LAYERS (bottom-up so overlay rules are clean)
;;------------------------------------------------------------------;;
(sdegeo:create-rectangle (position 0     d7 0) (position L_dev d8 0)
                         "SiC"   "R_substrate")
(sdegeo:create-rectangle (position 0     d6 0) (position L_dev d7 0)
                         "AlN"   "R_nucleation")
(sdegeo:create-rectangle (position 0     d5 0) (position L_dev d6 0)
                         "GaN"   "R_buffer")
(sdegeo:create-rectangle (position 0     d4 0) (position L_dev d5 0)
                         "GaN"   "R_cbuffer")
(sdegeo:create-rectangle (position 0     d3 0) (position L_dev d4 0)
                         "AlGaN" "R_bbarrier")
(sdegeo:create-rectangle (position 0     d2 0) (position L_dev d3 0)
                         "GaN"   "R_channel")
(sdegeo:create-rectangle (position 0     d1 0) (position L_dev d2 0)
                         "AlN"   "R_spacer")
(sdegeo:create-rectangle (position 0     d0 0) (position L_dev d1 0)
                         "AlGaN" "R_barrier")

;;------------------------------------------------------------------;;
;; 4. CREATE GATE METAL (Ni, sits on top of AlGaN barrier in gate area)
;;------------------------------------------------------------------;;
(sdegeo:create-rectangle (position y_g1 d_gtop 0) (position y_g2 d0 0)
                         "Nickel" "R_gate_metal")

;;------------------------------------------------------------------;;
;; 5. SPLIT TOP EDGE OF AlGaN BARRIER FOR SOURCE / DRAIN CONTACTS
;;    (gate metal already splits the top edge at y_g1 and y_g2)
;;------------------------------------------------------------------;;
(sdegeo:insert-vertex (position y_src2 d0 0))   ; split at 0.25
(sdegeo:insert-vertex (position y_drn1 d0 0))   ; split at 6.50

;;------------------------------------------------------------------;;
;; 6. DEFINE MOLE FRACTIONS FOR AlGaN REGIONS
;;------------------------------------------------------------------;;
(sdedr:define-constant-profile        "Prof_xTop"
   "xMoleFraction" x_Al_top)
(sdedr:define-constant-profile-region "Place_xTop"
   "Prof_xTop"  "R_barrier")

(sdedr:define-constant-profile        "Prof_xBack"
   "xMoleFraction" x_Al_back)
(sdedr:define-constant-profile-region "Place_xBack"
   "Prof_xBack" "R_bbarrier")

;;------------------------------------------------------------------;;
;; 7. DEFINE DOPING (C-doped buffer modeled as deep acceptor;
;;    deep-level energy set in models.par)
;;------------------------------------------------------------------;;
(sdedr:define-constant-profile        "Prof_C_dop"
   "BoronActiveConcentration" N_cbuf)
(sdedr:define-constant-profile-region "Place_C_dop"
   "Prof_C_dop" "R_cbuffer")

;; Light n-type SiC substrate (just so it's not floating)
(sdedr:define-constant-profile        "Prof_SiC_dop"
   "PhosphorusActiveConcentration" 1.0e15)
(sdedr:define-constant-profile-region "Place_SiC_dop"
   "Prof_SiC_dop" "R_substrate")

;;------------------------------------------------------------------;;
;; 8. CONTACTS
;;    Source/Drain: ohmic, on top of AlGaN barrier
;;    Gate: Schottky, on top of Ni gate metal
;;------------------------------------------------------------------;;
(sdegeo:define-contact-set "source" 4.0 (color:rgb 1 0 0) "##")
(sdegeo:set-current-contact-set "source")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (/ (+ y_src1 y_src2) 2.0) d0 0))))
   "source")

(sdegeo:define-contact-set "drain"  4.0 (color:rgb 0 0 1) "##")
(sdegeo:set-current-contact-set "drain")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (/ (+ y_drn1 y_drn2) 2.0) d0 0))))
   "drain")

(sdegeo:define-contact-set "gate"   4.0 (color:rgb 0 1 0) "##")
(sdegeo:set-current-contact-set "gate")
(sdegeo:define-2d-contact
   (list (car (find-edge-id (position (/ (+ y_g1 y_g2) 2.0) d_gtop 0))))
   "gate")

;;------------------------------------------------------------------;;
;; 9. MESH REFINEMENT
;;    - Coarse everywhere
;;    - Very fine at 2DEG (AlN-spacer / GaN-channel interface, depth d2)
;;    - Fine at back-barrier interface (depth d3)
;;    - Fine laterally under and around the gate
;;------------------------------------------------------------------;;
;; Global (whole device)
(sdedr:define-refinement-size "Ref_Global"
   0.30 0.30      ; max element size (lateral, depth)
   0.05 0.05)     ; min
(sdedr:define-refinement-region "Place_Global"
   "Ref_Global" "R_substrate")

;; 2DEG window (just above and below the AlN spacer)
(sdedr:define-refinement-window "RW_2DEG"
   "Rectangle"
   (position 0     (- d2 0.005) 0)
   (position L_dev (+ d2 0.010) 0))
(sdedr:define-refinement-size "Ref_2DEG"
   0.05  0.0005
   0.005 0.0001)     ; 0.1 nm vertical at the 2DEG
(sdedr:define-refinement-placement "Place_2DEG"
   "Ref_2DEG" "RW_2DEG")

;; Back-barrier interface
(sdedr:define-refinement-window "RW_BBarr"
   "Rectangle"
   (position 0     (- d3 0.005) 0)
   (position L_dev (+ d3 0.005) 0))
(sdedr:define-refinement-size "Ref_BBarr"
   0.10  0.002
   0.02  0.0005)
(sdedr:define-refinement-placement "Place_BBarr"
   "Ref_BBarr" "RW_BBarr")

;; Gate region (lateral refinement around gate edges - hot spots)
(sdedr:define-refinement-window "RW_Gate"
   "Rectangle"
   (position (- y_g1 0.2) d_gtop 0)
   (position (+ y_g2 0.2) d3    0))
(sdedr:define-refinement-size "Ref_Gate"
   0.02 0.005
   0.005 0.001)
(sdedr:define-refinement-placement "Place_Gate"
   "Ref_Gate" "RW_Gate")

;;------------------------------------------------------------------;;
;; 10. BUILD MESH & SAVE
;;------------------------------------------------------------------;;
(sde:build-mesh "snmesh" "" "n@node@_msh")
(sde:save-model "n@node@")
