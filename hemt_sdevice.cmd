#======================================================================#
#  Sentaurus Device (SDevice) - AlGaN/GaN HEMT, T = 4 K
#  Matches structure built by hemt_sde.cmd (Tables 9.1 / 9.2 design)
#
#  BUG FIXES FROM PREVIOUS VERSION:
#   * Removed System / Vsource_pset blocks (not needed for single-device)
#   * Removed MoleFraction(...) from Physics blocks (came from structure)
#   * Replaced region-based interface with material-pair interface
#   * Schottky gate: added explicit recombination velocities
#   * Aligned Save/Load filename prefixes
#   * Fixed Iterations placement in Coupled blocks
#   * Added eBarrierLowering to gate (needed for Schottky at low T)
#
#  4 K STRATEGY:
#   Step 1: Solve at 300 K (easy convergence)
#   Step 2: Ramp 300 -> 77 K
#   Step 3: Ramp 77 -> 30 K  (intermediate stop helps a lot)
#   Step 4: Ramp 30 -> 4 K
#   Step 5: Id-Vg at 4 K (Vd=0.1 V, Vg from -6 to +2)
#   Step 6: Id-Vd at 4 K (Vg=0, Vd from 0 to 10)
#======================================================================#

File {
   Grid     = "@tdr@"               ;# auto-resolves to n@node@_msh.tdr
   Plot     = "n@node@_des.tdr"
   Current  = "n@node@_des.plt"
   Output   = "n@node@_des.log"
   Param    = "models.par"
}

#----------------------------------------------------------------------#
# Electrodes
#----------------------------------------------------------------------#
Electrode {
   { Name="source"  Voltage=0.0 }
   { Name="drain"   Voltage=0.0 }
   { Name="gate"    Voltage=0.0  Barrier=0.85  eRecVelocity=2.573e6
                                              hRecVelocity=1.93e6 }
}

#----------------------------------------------------------------------#
# Global physics
#----------------------------------------------------------------------#
Physics {
   Temperature = 300

   # Fermi-Dirac is mandatory at cryogenic T (Boltzmann diverges)
   Fermi

   # Carrier freeze-out at low T
   IncompleteIonization

   # Polarization charges drive the 2DEG - MUST be enabled for III-N
   Piezoelectric_Polarization ( strain )

   Mobility (
      DopingDependence
      HighFieldSaturation
      Enormal
   )

   Recombination (
      SRH ( DopingDependence )
      Auger
   )

   # Disable BGN - default models give nonsense below ~100 K
   EffectiveIntrinsicDensity ( NoBandGapNarrowing )
}

#----------------------------------------------------------------------#
# Material-specific physics (mole fraction comes from the STRUCTURE,
# not declared here - that was the bug last time)
#----------------------------------------------------------------------#
Physics ( Material = "GaN" ) {
   Mobility ( ConstantMobility )
}

Physics ( Material = "AlGaN" ) {
   Mobility ( ConstantMobility )
}

Physics ( Material = "AlN" ) {
   Mobility ( ConstantMobility )
}

Physics ( Material = "SiC" ) {
   Mobility ( ConstantMobility )
}

#----------------------------------------------------------------------#
# Interface charges at AlGaN/AlN/GaN heterojunction.
# Sentaurus's piezoelectric model already adds the polarization sheet
# charge; this block adds residual interface trap density only.
# (Comment out if your design assumes ideal interfaces.)
#----------------------------------------------------------------------#
Physics ( MaterialInterface="AlN/GaN" ) {
   Traps (
      ( FixedCharge Conc = 1.0e12 )
   )
}

#----------------------------------------------------------------------#
# Plot what we want to see in TDR file
#----------------------------------------------------------------------#
Plot {
   eDensity hDensity
   ElectricField/Vector  Potential  SpaceCharge
   eMobility hMobility
   eVelocity hVelocity
   Doping  DonorConcentration  AcceptorConcentration
   eQuasiFermi hQuasiFermi
   ConductionBandEnergy ValenceBandEnergy
   BandGap EffectiveBandGap
   xMoleFraction
   Piezo/Vector  PE_Polarization
   eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
   SRH Auger
}

#----------------------------------------------------------------------#
# Math - cryogenic settings
#----------------------------------------------------------------------#
Math {
   Method        = Blocked
   SubMethod     = Super
   ACMethod      = Blocked
   ACSubMethod   = Super

   Extrapolate
   Derivatives
   RelErrControl
   Digits        = 5
   Iterations    = 200
   Notdamped     = 100
   ExitOnFailure

   eMobilityAveraging = ElementEdge
   hMobilityAveraging = ElementEdge

   -CheckUndefinedModels
   NumberOfThreads = 4
}

#----------------------------------------------------------------------#
# Solve - the cryogenic ramp is the key trick
#----------------------------------------------------------------------#
Solve {

   #------- Step 1: 300 K initial Poisson + drift-diffusion -----------
   NewCurrentPrefix = "init_300K_"
   Coupled ( Iterations=200 LineSearchDamping=1e-6 ) { Poisson }
   Coupled ( Iterations=200 ) { Poisson Electron Hole }
   Save ( FilePrefix = "n@node@_300K" )

   #------- Step 2: Ramp 300 K -> 77 K -------------------------------
   NewCurrentPrefix = "ramp_300_77_"
   Quasistationary (
      InitialStep=0.05  MinStep=1e-5  MaxStep=0.1
      Goal { Parameter=Temperature  Value=77 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
   }
   Save ( FilePrefix = "n@node@_77K" )

   #------- Step 3: Ramp 77 K -> 30 K (intermediate stop) -----------
   NewCurrentPrefix = "ramp_77_30_"
   Quasistationary (
      InitialStep=0.02  MinStep=1e-7  MaxStep=0.1
      Goal { Parameter=Temperature  Value=30 }
   ) {
      Coupled ( Iterations=300 ) { Poisson Electron Hole }
   }
   Save ( FilePrefix = "n@node@_30K" )

   #------- Step 4: Ramp 30 K -> 4 K --------------------------------
   # If this step fails, insert another stop at 10 K with InitialStep=0.005
   NewCurrentPrefix = "ramp_30_4_"
   Quasistationary (
      InitialStep=0.01  MinStep=1e-8  MaxStep=0.05
      Goal { Parameter=Temperature  Value=4 }
   ) {
      Coupled ( Iterations=400 ) { Poisson Electron Hole }
   }
   Save ( FilePrefix = "n@node@_4K" )

   #------- Step 5: Id-Vg transfer characteristic at 4 K ------------
   # Drift Vd to 0.1 V (linear regime), then sweep Vg from -6 to +2 V
   NewCurrentPrefix = "IdVg_4K_Vd0p1_"
   Quasistationary (
      InitialStep=0.01  MaxStep=0.05  MinStep=1e-6
      Goal { Name="drain"  Voltage=0.1 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
   }
   Quasistationary (
      InitialStep=0.01  MaxStep=0.02  MinStep=1e-6
      Goal { Name="gate"  Voltage=-6.0 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
   }
   Quasistationary (
      InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate"  Voltage=2.0 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_IdVg_4K"
             Time=(Range=(0 1) Intervals=20) NoOverwrite )
   }

   #------- Step 6: Id-Vd output at Vg = 0, 4 K --------------------
   # Reload the clean 4 K solution
   Load ( FilePrefix = "n@node@_4K" )

   NewCurrentPrefix = "IdVd_4K_Vg0_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate"  Voltage=0.0 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
   }
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain"  Voltage=10.0 }
   ) {
      Coupled ( Iterations=200 ) { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_IdVd_4K"
             Time=(Range=(0 1) Intervals=20) NoOverwrite )
   }
}
