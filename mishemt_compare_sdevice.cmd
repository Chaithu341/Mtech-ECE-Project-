#======================================================================#
#  Sentaurus Device (SDevice) - T-2022.03
#  Cryogenic AlGaN/GaN MIS-HEMT characterization & comparison deck
#
#  Runs against ANY of the three SDE meshes (one at a time):
#     Structure_A_msh.tdr  (Al2O3 8 nm)
#     Structure_B_msh.tdr  (HfO2  8 nm)
#     Structure_C_msh.tdr  (Al2O3 3nm / HfO2 7nm stack)
#
#  Replicates the comparison methodology of Mebarki et al.,
#  EuMIC 2023 (HEMT vs MIS-HEMT, RT vs CT ~4 K). Here the comparison
#  is across the three GATE-DIELECTRIC variants of YOUR structure:
#     1. Id-Vd output (paper Fig. 2)
#     2. Id-Vg transfer + gm   -> Vth, gm,max (paper Table 1)
#     3. Ig-Vg gate leakage    (paper Fig. 3)   [from same Id-Vg run]
#     4. C-V  (Cgs vs Vg)       (paper Fig. 4b)
#  at BOTH 300 K (RT) and 4 K (CT).
#
#  -------------------------------------------------------------------
#  SELECT THE STRUCTURE:
#   * In Sentaurus Workbench: leave @tdr@ etc.; SWB feeds the mesh.
#   * Command line: replace "@tdr@" with the mesh, e.g.
#       Grid = "Structure_A_msh.tdr"
#     and replace @tdrdat@/@plot@/@log@/@acplot@ with literal names
#     (see the run guide).
#  -------------------------------------------------------------------
#
#  Region names (match SDE): R_barrier R_channel R_bbarrier R_cbuffer
#     R_buffer R_nucleation R_substrate ; dielectric = R_dielectric
#     (A,B) or R_al2o3 + R_hfo2 (C). No region is referenced by name
#     in this deck, so the SAME file works for all three.
#  Contacts: source drain gate substrate
#======================================================================#

File {
   Grid      = "@tdr@"
   Plot      = "@tdrdat@"
   Current   = "@plot@"
   Output    = "@log@"
   Param     = "models.par"
   ACExtract = "@acplot@"
}

#----------------------------------------------------------------------#
# Electrodes. Gate workfunction 4.7 eV (Ni/Au-like MIS gate).
#----------------------------------------------------------------------#
Electrode {
   { Name="source"    Voltage=0.0 }
   { Name="drain"     Voltage=0.0 }
   { Name="gate"      Voltage=0.0  Workfunction=4.7 }
   { Name="substrate" Voltage=0.0 }
}

#----------------------------------------------------------------------#
# Thermode: thermal boundary at the substrate back side.
#----------------------------------------------------------------------#
Thermode {
   { Name="substrate" Temperature=300 SurfaceResistance=0 }
}

#----------------------------------------------------------------------#
# Global physics
#----------------------------------------------------------------------#
Physics {
   Temperature = 300

   Fermi                                ;# Fermi-Dirac (needed at cryo)
   IncompleteIonization                 ;# carrier freeze-out at 4 K
   Piezoelectric_Polarization (strain)  ;# generates the 2DEG

   Mobility (
      DopingDependence
      HighFieldSaturation
      Enormal
   )

   Recombination (
      SRH (DopingDependence)
   )
}

#----------------------------------------------------------------------#
# Material-specific mobility (constant model; cryo-stable)
#----------------------------------------------------------------------#
Physics (Material="GaN")   { Mobility(ConstantMobility) }
Physics (Material="AlGaN") { Mobility(ConstantMobility) }
Physics (Material="AlN")   { Mobility(ConstantMobility) }
Physics (Material="SiC")   { Mobility(ConstantMobility) }
# Al2O3 / HfO2 are insulators: no transport models required.

#----------------------------------------------------------------------#
# Residual interface fixed charge at the 2DEG heterojunction.
#----------------------------------------------------------------------#
Physics (MaterialInterface="AlGaN/GaN") {
   Traps ( (FixedCharge Conc=1.0e12) )
}

#----------------------------------------------------------------------#
# Plot quantities (structure plots in SVisual)
#----------------------------------------------------------------------#
Plot {
   eDensity hDensity
   ElectricField/Vector Potential SpaceCharge
   eMobility hMobility eVelocity hVelocity
   Doping DonorConcentration AcceptorConcentration
   eQuasiFermi hQuasiFermi
   ConductionBandEnergy ValenceBandEnergy
   BandGap
   xMoleFraction
   Piezo/Vector PE_Polarization
   eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
   SRH
}

#----------------------------------------------------------------------#
# Math - conservative cryogenic convergence settings
#----------------------------------------------------------------------#
Math {
   Method      = Blocked
   SubMethod   = Super
   ACMethod    = Blocked
   ACSubMethod = Super

   Extrapolate
   Derivatives
   RelErrControl
   Digits     = 5
   Iterations = 200
   Notdamped  = 100
   ExitOnFailure

   eMobilityAveraging = ElementEdge
   hMobilityAveraging = ElementEdge

   -CheckUndefinedModels
   NumberOfThreads = 4
}

#======================================================================#
#  SOLVE
#======================================================================#
Solve {

   #==================================================================#
   #  INITIAL SOLUTION at 300 K
   #==================================================================#
   NewCurrentPrefix = "init_RT_"
   Coupled (Iterations=200 LineSearchDamping=1e-6) { Poisson }
   Coupled (Iterations=200) { Poisson Electron Hole }
   Save (FilePrefix = "n_RT_init")

   #==================================================================#
   #  ============ ROOM TEMPERATURE (300 K) ======================== #
   #==================================================================#

   #----- RT 1: Id-Vd output at Vg = 0 (paper Fig. 2) --------------
   Load (FilePrefix = "n_RT_init")
   NewCurrentPrefix = "RT_IdVd_setVg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_IdVd_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=7.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_RT_IdVd_Vg0"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }

   #----- RT 2: Id-Vg + Ig-Vg transfer at Vd = 0.1 V ---------------
   #  (gives Vth, gm from Id; gate leakage from Ig - paper Fig. 3)
   Load (FilePrefix = "n_RT_init")
   NewCurrentPrefix = "RT_IdVg_setVd_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=0.1 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_IdVg_toNeg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_IdVg_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_RT_IdVg"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }

   #----- RT 3: C-V (Cgs vs Vg) at Vd = 0, f = 1 MHz (Fig. 4b) -----
   Load (FilePrefix = "n_RT_init")
   NewCurrentPrefix = "RT_CV_toNeg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_CV_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      ACCoupled (
         StartFrequency=1e6 EndFrequency=1e6 NumberOfPoints=1 Decade
         Node(source drain gate substrate)
      ) { Poisson Electron Hole }
   }

   #==================================================================#
   #  TEMPERATURE RAMP  300 -> 77 -> 30 -> 4 K
   #==================================================================#
   Load (FilePrefix = "n_RT_init")
   NewCurrentPrefix = "ramp_300_77_"
   Quasistationary (
      InitialStep=0.05 MinStep=1e-5 MaxStep=0.1
      Goal { Parameter=Temperature Value=77 }
   ) { Coupled (Iterations=200) { Poisson Electron Hole } }

   NewCurrentPrefix = "ramp_77_30_"
   Quasistationary (
      InitialStep=0.02 MinStep=1e-7 MaxStep=0.05
      Goal { Parameter=Temperature Value=30 }
   ) { Coupled (Iterations=300) { Poisson Electron Hole } }

   NewCurrentPrefix = "ramp_30_4_"
   Quasistationary (
      InitialStep=0.01 MinStep=1e-8 MaxStep=0.05
      Goal { Parameter=Temperature Value=4 }
   ) { Coupled (Iterations=400) { Poisson Electron Hole } }
   Save (FilePrefix = "n_CT_init")

   #==================================================================#
   #  ============ CRYOGENIC (4 K) ================================= #
   #==================================================================#

   #----- CT 1: Id-Vd output at Vg = 0 -----------------------------
   Load (FilePrefix = "n_CT_init")
   NewCurrentPrefix = "CT_IdVd_setVg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_IdVd_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=7.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_CT_IdVd_Vg0"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }

   #----- CT 2: Id-Vg + Ig-Vg transfer at Vd = 0.1 V ---------------
   Load (FilePrefix = "n_CT_init")
   NewCurrentPrefix = "CT_IdVg_setVd_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=0.1 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_IdVg_toNeg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_IdVg_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_CT_IdVg"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }

   #----- CT 3: C-V (Cgs vs Vg) at Vd = 0, f = 1 MHz ---------------
   Load (FilePrefix = "n_CT_init")
   NewCurrentPrefix = "CT_CV_toNeg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_CV_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      ACCoupled (
         StartFrequency=1e6 EndFrequency=1e6 NumberOfPoints=1 Decade
         Node(source drain gate substrate)
      ) { Poisson Electron Hole }
   }
}
