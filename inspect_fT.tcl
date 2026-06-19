#==============================================================================
#  inspect_fT.tcl  --  Extract cut-off frequency fT from SDevice AC results
#
#  fT is the frequency at which the small-signal current gain |h21| = 1 (0 dB).
#  From the simulated Y-parameters:
#         h21 = Y21 / Y11
#  We load the AC .plt, compute |h21| vs frequency, and find the -20 dB/dec
#  crossing of unity (matches Fig.1(b): |h21| extrapolates to fT ~ 328 GHz).
#
#  Run:  inspect -f inspect_fT.tcl
#==============================================================================

# --- load the AC current/Y-parameter plot file ---
set plt "hemt_des_ac_des.plt"
if { ![file exists $plt] } { set plt "hemt_des.plt" }
proj_load $plt AC

# Dataset names depend on the SDevice version; typical AC outputs are:
#   AC(gate drain) ->  "frequency", "Y(drain,gate)", "Y(gate,gate)", ...
# Adjust the exact curve labels below to match your .plt header.

set f      [lindex [proj_dataset_list AC] 0] ;# frequency vector
set freq   "frequency"

# Real/Imag parts of the relevant Y-parameters
set ReY11 "AC Intr Y(gate,gate) real"
set ImY11 "AC Intr Y(gate,gate) imag"
set ReY21 "AC Intr Y(drain,gate) real"
set ImY21 "AC Intr Y(drain,gate) imag"

# |Y11| and |Y21|
cv_create magY11 \
   [cv_compute "sqrt(<$ReY11>^2 + <$ImY11>^2)" A A A A]
cv_create magY21 \
   [cv_compute "sqrt(<$ReY21>^2 + <$ImY21>^2)" A A A A]

# |h21| = |Y21| / |Y11|
cv_create h21mag [cv_compute "<magY21>/<magY11>" A A A A]

# fT : interpolate frequency at which |h21| = 1
set fT [cv_compute "vecvalx(<h21mag>,1.0)" A A A A]
puts "============================================="
puts "  Extracted cut-off frequency fT = $fT Hz"
puts [format "  fT = %.1f GHz" [expr {$fT/1e9}]]
puts "  (paper simulated target ~ 328 GHz)"
puts "============================================="

# Plot |h21| in dB vs frequency
cv_create h21dB [cv_compute "20*log(<h21mag>)/log(10)" A A A A]
cv_display h21dB
cv_lineStyle h21dB solid
cv_lineColor h21dB blue
