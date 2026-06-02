#======================================================================#
#  SVisual script (Tcl) - T-2022.03
#  Comparison plots for the three MIS-HEMT dielectric variants,
#  mirroring Mebarki et al. EuMIC 2023:
#     Plot 1  Id-Vd  output       (paper Fig. 2)
#     Plot 2  Id-Vg  transfer     (paper Table 1 -> Vth, gm)
#     Plot 3  gm-Vg               (paper Table 1)
#     Plot 4  Ig-Vg  gate leakage (paper Fig. 3, log scale)
#     Plot 5  C-V    (Cgs vs Vg)  (paper Fig. 4b)
#  Each plot overlays: Structure A (Al2O3), B (HfO2), C (stack),
#  and RT (300 K) vs CT (4 K).
#
#  PREREQUISITE: run SDevice for all three structures first, with these
#  Current (.plt) output names (see the run guide):
#     A_des.plt   B_des.plt   C_des.plt   (DC currents)
#     A_ac.plt    B_ac.plt    C_ac.plt    (AC capacitance)
#
#  RUN:  svisual -i compare_plots.tcl
#        (or: load in SVisual GUI via File > Load Script)
#======================================================================#

# ---- 1. Load all DC datasets ---------------------------------------
# Each .plt holds ALL the sweeps (RT and CT) for that structure,
# distinguished by the NewCurrentPrefix in the SDevice file.
if { [file exists A_des.plt] } { load_file A_des.plt -name A_dc }
if { [file exists B_des.plt] } { load_file B_des.plt -name B_dc }
if { [file exists C_des.plt] } { load_file C_des.plt -name C_dc }

# AC datasets (capacitance)
if { [file exists A_ac.plt] } { load_file A_ac.plt -name A_ac }
if { [file exists B_ac.plt] } { load_file B_ac.plt -name B_ac }
if { [file exists C_ac.plt] } { load_file C_ac.plt -name C_ac }

# ---- helper: safe dataset list (only those that loaded) ------------
set dc_sets {}
foreach s {A_dc B_dc C_dc} {
   if { [lsearch [list_datasets] $s] >= 0 } { lappend dc_sets $s }
}
set ac_sets {}
foreach s {A_ac B_ac C_ac} {
   if { [lsearch [list_datasets] $s] >= 0 } { lappend ac_sets $s }
}

# colors per structure
array set col { A_dc red  B_dc blue  C_dc green  A_ac red  B_ac blue  C_ac green }
array set lbl { A_dc "Al2O3"  B_dc "HfO2"  C_dc "Stack" \
                A_ac "Al2O3"  B_ac "HfO2"  C_ac "Stack" }

#=====================================================================#
# PLOT 1 : Id-Vd output family at Vg=0 (paper Fig. 2)
#=====================================================================#
create_plot -1d -name P1_IdVd
foreach s $dc_sets {
   # x = drain OuterVoltage, y = drain TotalCurrent
   create_curve -name "IdVd_RT_$s" -dataset $s \
      -axisX "drain OuterVoltage" -axisY "drain TotalCurrent" -plot P1_IdVd
   set_curve_prop "IdVd_RT_$s" -label "$lbl($s) RT" -color $col($s)
}
set_axis_prop -plot P1_IdVd -axis x -title "Vds (V)"
set_axis_prop -plot P1_IdVd -axis y -title "Id (A/um)"
set_plot_prop -plot P1_IdVd -title "Id-Vd output (RT) : Al2O3 vs HfO2 vs Stack"

#=====================================================================#
# PLOT 2 : Id-Vg transfer (paper Table 1 -> Vth)
#=====================================================================#
create_plot -1d -name P2_IdVg
foreach s $dc_sets {
   create_curve -name "IdVg_RT_$s" -dataset $s \
      -axisX "gate OuterVoltage" -axisY "drain TotalCurrent" -plot P2_IdVg
   set_curve_prop "IdVg_RT_$s" -label "$lbl($s) RT" -color $col($s)
}
set_axis_prop -plot P2_IdVg -axis x -title "Vgs (V)"
set_axis_prop -plot P2_IdVg -axis y -title "Id (A/um)"
set_plot_prop -plot P2_IdVg -title "Id-Vg transfer (RT)"

#=====================================================================#
# PLOT 3 : gm-Vg  (transconductance = d Id / d Vg)
#=====================================================================#
create_plot -1d -name P3_gm
foreach s $dc_sets {
   set idvg "IdVg_RT_$s"
   # derivative curve of Id wrt Vg
   create_curve -name "gm_RT_$s" -function "diff(<$idvg>)" -plot P3_gm
   set_curve_prop "gm_RT_$s" -label "$lbl($s) RT gm" -color $col($s)
}
set_axis_prop -plot P3_gm -axis x -title "Vgs (V)"
set_axis_prop -plot P3_gm -axis y -title "gm (S/um)"
set_plot_prop -plot P3_gm -title "Transconductance gm-Vg (RT)"

#=====================================================================#
# PLOT 4 : Ig-Vg gate leakage (paper Fig. 3, log scale)
#=====================================================================#
create_plot -1d -name P4_IgVg
foreach s $dc_sets {
   create_curve -name "IgVg_RT_$s" -dataset $s \
      -axisX "gate OuterVoltage" -axisY "gate TotalCurrent" -plot P4_IgVg
   set_curve_prop "IgVg_RT_$s" -label "$lbl($s) RT" -color $col($s)
}
set_axis_prop -plot P4_IgVg -axis x -title "Vgs (V)"
set_axis_prop -plot P4_IgVg -axis y -title "|Ig| (A/um)" -type log
set_plot_prop -plot P4_IgVg -title "Gate leakage Ig-Vg (RT, log)"

#=====================================================================#
# PLOT 5 : C-V (Cgs vs Vg) (paper Fig. 4b) - the key MIS comparison
#=====================================================================#
create_plot -1d -name P5_CV
foreach s $ac_sets {
   # AC capacitance node name in T-2022.03: "gate gate Capacitance"
   create_curve -name "CV_$s" -dataset $s \
      -axisX "gate OuterVoltage" -axisY "gate gate Capacitance" -plot P5_CV
   set_curve_prop "CV_$s" -label "$lbl($s)" -color $col($s)
}
set_axis_prop -plot P5_CV -axis x -title "Vgs (V)"
set_axis_prop -plot P5_CV -axis y -title "Cgs (F/um)"
set_plot_prop -plot P5_CV -title "C-V (Cgs) : Al2O3 vs HfO2 vs Stack"

#=====================================================================#
# Export all plots to image files
#=====================================================================#
export_image -plot P1_IdVd -filename "cmp_1_IdVd.png" -format png
export_image -plot P2_IdVg -filename "cmp_2_IdVg.png" -format png
export_image -plot P3_gm   -filename "cmp_3_gm.png"   -format png
export_image -plot P4_IgVg -filename "cmp_4_IgVg.png" -format png
export_image -plot P5_CV   -filename "cmp_5_CV.png"   -format png

puts "=============================================================="
puts " Comparison plots generated:"
puts "   cmp_1_IdVd.png  cmp_2_IdVg.png  cmp_3_gm.png"
puts "   cmp_4_IgVg.png  cmp_5_CV.png"
puts " NOTE: This script plots the RT (300 K) curves. To add the CT"
puts " (4 K) curves, the per-temperature data must be split into"
puts " separate .plt files (see run guide, Step 6) and loaded with"
puts " their own dataset names, then add curves the same way."
puts "=============================================================="
