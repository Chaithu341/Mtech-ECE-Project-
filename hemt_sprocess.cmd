#----------------------------------------------------------------------#
# Sentaurus Process (SProcess) - AlGaN/GaN HEMT
# Built to Table 9.1 / 9.2 dimensions (deposition-only flow)
#
# Layer stack (bottom -> top, built by sequential deposit):
#   SiC substrate      :   2 um
#   AlN nucleation     : 100 nm
#   GaN buffer         : 250 nm
#   C-doped GaN buffer : 1.5 um  ([C] = 1e18 cm-3)
#   AlGaN back-barrier :  23 nm  (x_Al = 0.07, assumed)
#   GaN channel (UID)  : 150 nm
#   AlN spacer         :   1 nm
#   AlGaN barrier      :  40 nm  (x_Al = 0.25)
#   Gate metal (Ni)    :  50 nm  (patterned)
#
# Lateral (total device width = 6.75 um):
#   Source contact: 250 nm
#   S-G gap       :   1 um
#   Gate          : 250 nm
#   G-D gap       :   5 um
#   Drain contact : 250 nm
#
# NOTE: SProcess is built for Si processes (diffusion/implant). For
# GaN MOCVD we use only deposition steps. The SDE flow remains the
# recommended approach for III-Nitride HEMTs.
#----------------------------------------------------------------------#

math coord.ucs
AdvancedCalibration

# --- Simulation grid (SProcess uses x=depth, y=lateral) ---------------
# x: 0 at top, increasing downward; depth coords match SDE file's d*.
line x location= -0.050 spacing=0.010 tag=top      ;# top of gate metal
line x location=  0.000 spacing=0.001              ;# top of AlGaN barrier
line x location=  0.020 spacing=0.001              ;# mid AlGaN barrier
line x location=  0.040 spacing=0.0002             ;# AlN spacer top - very fine
line x location=  0.041 spacing=0.0002             ;# AlN spacer / GaN channel (2DEG !)
line x location=  0.050 spacing=0.0005             ;# just below 2DEG
line x location=  0.191 spacing=0.002              ;# channel / back-barrier
line x location=  0.214 spacing=0.002              ;# back-barrier / C-buffer
line x location=  1.714 spacing=0.020              ;# C-buffer / GaN buffer
line x location=  1.964 spacing=0.020              ;# GaN buffer / AlN nucl
line x location=  2.064 spacing=0.005              ;# AlN nucl / SiC
line x location=  4.064 spacing=0.050 tag=bot      ;# bottom of SiC

# y: lateral, 0 at left (source), 6.75 at right (drain)
line y location=  0.000  spacing=0.05  tag=left
line y location=  0.250  spacing=0.02              ;# source edge
line y location=  1.250  spacing=0.005             ;# gate left edge - fine
line y location=  1.500  spacing=0.005             ;# gate right edge - fine
line y location=  6.500  spacing=0.02              ;# drain edge
line y location=  6.750  spacing=0.05  tag=right

# --- Substrate: 4H-SiC ------------------------------------------------
region SiC  xlo=top  xhi=bot  ylo=left yhi=right
init concentration=1.0e15<cm-3> field=Phosphorus  wafer.orient=0001

# NOTE: 'init' creates a substrate the full grid height. We must etch
# back to the SiC depth (2.064 um), then deposit each layer in sequence.
# Simpler approach: skip init's full fill and use deposit on a thin SiC.
# Below we use the simpler 'reset and stack from bottom' style:

# --- Wipe the structure and rebuild as a deposition stack on SiC ------
# (the init above gives us a baseline SiC; now we deposit upward)

# After init: top of SiC sits at top of simulation (x = -0.050).
# We need to first ETCH SiC down to x = 2.064 (SiC top in the final
# stack), then deposit upward.
etch material= {SiC} type=anisotropic thickness=2.114<um>
# Now top of SiC is at x = 2.064 (we removed -0.050 to 2.064 = 2.114 um)

# --- Deposit AlN nucleation (100 nm) ----------------------------------
deposit material= {AlN}     type=isotropic thickness=0.100<um>

# --- Deposit GaN buffer (250 nm) --------------------------------------
deposit material= {GaN}     type=isotropic thickness=0.250<um>

# --- Deposit C-doped GaN buffer (1.5 um) ------------------------------
deposit material= {GaN}     type=isotropic thickness=1.500<um> \
        fields.values= { Boron=1.0e18 }
# (C modeled as acceptor via Boron concentration; trap level in models.par)

# --- Deposit AlGaN back-barrier (23 nm, x_Al = 0.07) ------------------
deposit material= {AlGaN}   type=isotropic thickness=0.023<um> \
        fields.values= { xMoleFraction=0.07 }

# --- Deposit GaN channel (UID, 150 nm) --------------------------------
deposit material= {GaN}     type=isotropic thickness=0.150<um>

# --- Deposit AlN spacer (1 nm) ----------------------------------------
deposit material= {AlN}     type=isotropic thickness=0.001<um>

# --- Deposit AlGaN barrier (40 nm, x_Al = 0.25) -----------------------
deposit material= {AlGaN}   type=isotropic thickness=0.040<um> \
        fields.values= { xMoleFraction=0.25 }

# --- Source contact (250 nm wide, y = 0 to 0.25) ----------------------
mask name=source   segments= { -0.1  0.25 }   negative
deposit material= {Titanium} type=anisotropic thickness=0.020<um> mask=source
contact name="source" point material= {Titanium} \
        x=-0.071 y=0.125 replace

# --- Drain contact (250 nm wide, y = 6.50 to 6.75) --------------------
mask name=drain    segments= { 6.50  6.85 }   negative
deposit material= {Titanium} type=anisotropic thickness=0.020<um> mask=drain
contact name="drain"  point material= {Titanium} \
        x=-0.071 y=6.625 replace

# --- Gate metal (Ni, 50 nm tall, y = 1.25 to 1.50) --------------------
mask name=gate     segments= { 1.25  1.50 }   negative
deposit material= {Nickel}   type=anisotropic thickness=0.050<um> mask=gate
contact name="gate"   point material= {Nickel} \
        x=-0.071 y=1.375 replace

# --- Save structure ---------------------------------------------------
struct tdr=   n@node@_str.tdr
struct smesh= n@node@_msh

exit
