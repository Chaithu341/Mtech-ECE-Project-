#----------------------------------------------------------------------#
# Sentaurus Process (SProcess) - AlGaN/GaN HEMT Structure Build
# Design: Back-barrier HEMT on SiC substrate for cryogenic operation (4 K)
# Layer stack (bottom -> top):
#   SiC substrate / AlN nucleation / GaN buffer / C-doped GaN buffer /
#   AlGaN back-barrier / UID GaN channel / AlGaN barrier
# Contacts: Source (S), Gate (G), Drain (D)
#
# NOTE: SProcess is intended for Si/SiGe process emulation. For III-Nitride
# HEMTs the standard industry practice is to build the structure directly
# in SDE (Sentaurus Structure Editor) rather than emulate epitaxy in
# SProcess, because GaN/AlGaN MOCVD is not a diffusion/implant process.
# This file uses a deposition-only flow (no implants, no anneals) so the
# layer stack matches your figure exactly. If your workflow uses SDE
# instead, skip this file and use the SDE script (provided separately).
#----------------------------------------------------------------------#

# --- Simulation grid setup (2D cross-section) ---------------------
math coord.ucs                       ;# device coordinate system
AdvancedCalibration                   ;# enable advanced models (harmless here)

line x location= 0.0    spacing=0.005 tag=top
line x location= 0.025  spacing=0.001          ;# AlGaN barrier - fine
line x location= 0.045  spacing=0.001          ;# 2DEG region - very fine
line x location= 0.075  spacing=0.002          ;# UID GaN channel
line x location= 0.095  spacing=0.002          ;# AlGaN back-barrier
line x location= 1.095  spacing=0.020          ;# C-doped GaN buffer
line x location= 2.095  spacing=0.050          ;# GaN buffer
line x location= 2.145  spacing=0.005          ;# AlN nucleation
line x location= 2.645  spacing=0.020 tag=bot  ;# SiC substrate

line y location= 0.0   spacing=0.05  tag=left
line y location= 1.0   spacing=0.02                ;# source region
line y location= 2.0   spacing=0.01                ;# gate region (fine)
line y location= 3.0   spacing=0.02                ;# drain region
line y location= 4.0   spacing=0.05  tag=right

# --- Substrate: 4H-SiC -------------------------------------------------
# Start with SiC substrate (region from x=2.145 to x=2.645 um, 500 nm)
# SProcess does not have a native SiC material; we initialize a 'pseudo'
# substrate and rely on SDevice to apply proper SiC parameters.
region SiC  xlo=top  xhi=bot  ylo=left yhi=right
init concentration=1.0e15<cm-3> field=Phosphorus wafer.orient=0001

# --- Deposit AlN nucleation layer (~50 nm) -----------------------------
deposit material= {AlN}      type=isotropic thickness=0.050<um>

# --- Deposit GaN buffer (~1.0 um) --------------------------------------
deposit material= {GaN}      type=isotropic thickness=1.000<um>

# --- Deposit Carbon-doped GaN buffer (~1.0 um) -------------------------
# C-doping suppresses buffer leakage; here Carbon acts as deep acceptor.
deposit material= {GaN}      type=isotropic thickness=1.000<um> \
        fields.values= { Carbon=1.0e18 }

# --- Deposit AlGaN back-barrier (~20 nm, Al ~5-8%) ---------------------
# Back-barrier improves carrier confinement (key for cryogenic 2DEG).
deposit material= {AlGaN}    type=isotropic thickness=0.020<um> \
        fields.values= { xMoleFraction=0.07 }

# --- Deposit UID GaN channel (~30 nm) ----------------------------------
# Unintentionally doped - background n-type ~1e16 from native defects
deposit material= {GaN}      type=isotropic thickness=0.030<um>

# --- Deposit AlGaN barrier (~25 nm, Al ~25%) ---------------------------
deposit material= {AlGaN}    type=isotropic thickness=0.025<um> \
        fields.values= { xMoleFraction=0.25 }

# --- Define contacts (S, G, D) -----------------------------------------
# Source ohmic contact (y = 0.0 to 0.8 um)
mask name=source  segments= { -0.1 0.8 }   negative
etch material= {AlGaN} type=anisotropic thickness=0.030<um> mask=source
deposit material= {Titanium} type=anisotropic thickness=0.020<um> mask=source
contact name="source" point material= {Titanium} x=-0.001 y=0.4 replace

# Drain ohmic contact (y = 3.2 to 4.0 um)
mask name=drain   segments= { 3.2 4.1 }    negative
etch material= {AlGaN} type=anisotropic thickness=0.030<um> mask=drain
deposit material= {Titanium} type=anisotropic thickness=0.020<um> mask=drain
contact name="drain"  point material= {Titanium} x=-0.001 y=3.6 replace

# Gate Schottky contact (y = 1.85 to 2.15 um, Lg = 0.3 um)
mask name=gate    segments= { 1.85 2.15 }  negative
deposit material= {Nickel}   type=anisotropic thickness=0.050<um> mask=gate
contact name="gate"   point material= {Nickel} x=-0.001 y=2.0 replace

# --- Save final structure ---------------------------------------------
struct tdr= n@node@_str.tdr
struct smesh= n@node@_msh

exit
