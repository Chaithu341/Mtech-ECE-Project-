#======================================================================#
#  Sentaurus Device (SDevice) - Cryogenic AlGaN/GaN MOS-HEMT
#  Target version: T-2022.03
#
#  Simulations performed:
#    1. DC initialization at 300 K
#    2. Temperature ramp 300 -> 77 -> 30 -> 20 K
#    3. C-V at 20 K  (Vg sweep, fixed frequency 1 MHz)
#    4. C-f at 20 K  (frequency sweep at Vg = 0, log freq 1 kHz - 1 GHz)
#    5. Id-Vg at 20 K (Vd = 0.1 V)
#
#  Region names from SDE: R_sub R_buffer R_channel R_spacer R_barrier
#                         R_Al2O3 R_HfO2 R_gate_metal
#  Contact names:         source drain gate substrate
#======================================================================#

File {
   Grid     = "@tdr@"
   Plot     = "n@node@_des.tdr"
   Current  = "n@node@_des.plt"
   Output   = "n@node@_des.log"
   Param    = "models.par"
   ACExtract = "n@node@_ac.plt"
}

#----------------------------------------------------------------------#
# Electrodes
#----------------------------------------------------------------------#
Electrode {
   { Name="source"    Voltage=0.0 }
   { Name="drain"     Voltage=0.0 }
   { Name="gate"      Voltage=0.0  Workfunction=4.7 }   ;# TiN
   { Name="substrate" Voltage=0.0 }
}

#----------------------------------------------------------------------#
# Thermode (thermal boundary, required for cryogenic study)
# Set lattice T = 300 K initially; ramped via global temperature later
#----------------------------------------------------------------------#
Thermode {
   { Name="substrate" Temperature=300 SurfaceResistance=0 }
}

#----------------------------------------------------------------------#
# Global physics
#----------------------------------------------------------------------#
Physics {
   Temperature = 300

   Fermi                                ;# Fermi-Dirac (mandatory at cryo)
   IncompleteIonization                 ;# carrier freeze-out
   Piezoelectric_Polarization (strain)  ;# 2DEG source

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
# Material-specific
#----------------------------------------------------------------------#
Physics (Material="GaN")   { Mobility(ConstantMobility) }
Physics (Material="AlGaN") { Mobility(ConstantMobility) }
Physics (Material="AlN")   { Mobility(ConstantMobility) }
Physics (Material="SiC")   { Mobility(ConstantMobility) }

# Note: Al2O3 and HfO2 are insulators; no Physics block needed
# (Sentaurus treats them as ideal dielectrics by default).

#----------------------------------------------------------------------#
# Interface charges (residual, on top of polarization)
#----------------------------------------------------------------------#
Physics (MaterialInterface="AlN/GaN") {
   Traps ( (FixedCharge Conc=1.0e12) )
}

Physics (MaterialInterface="AlGaN/Aluminum2O3") {
   Traps ( (FixedCharge Conc=5.0e11) )
}

#----------------------------------------------------------------------#
# Plot
#----------------------------------------------------------------------#
Plot {
   eDensity hDensity
   ElectricField/Vector Potential SpaceCharge
   eMobility hMobility eVelocity hVelocity
   Doping DonorConcentration AcceptorConcentration
   eQuasiFermi hQuasiFermi
   ConductionBandEnergy ValenceBandEnergy
   BandGap EffectiveBandGap
   xMoleFraction
   Piezo/Vector PE_Polarization
   eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
   SRH
}

#----------------------------------------------------------------------#
# Math - conservative settings for cryogenic convergence
#----------------------------------------------------------------------#
Math {
   Method     = Blocked
   SubMethod  = Super
   ACMethod   = Blocked
   ACSubMethod = Super

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
# Solve
#----------------------------------------------------------------------#
Solve {

   #----- 1. Initial Poisson at 300 K (gentle ramp of damping) -------
   NewCurrentPrefix = "init_300K_"
   Coupled (Iterations=200 LineSearchDamping=1.0e-6) { Poisson }
   Coupled (Iterations=200) { Poisson Electron Hole }
   Save (FilePrefix = "n@node@_300K")

   #----- 2. Temperature ramp 300 -> 77 K ----------------------------
   NewCurrentPrefix = "ramp_300_77_"
   Quasistationary (
      InitialStep=0.05 MinStep=1e-5 MaxStep=0.1
      Goal { Parameter=Temperature Value=77 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
   }
   Save (FilePrefix = "n@node@_77K")

   #----- 3. 77 -> 30 K ----------------------------------------------
   NewCurrentPrefix = "ramp_77_30_"
   Quasistationary (
      InitialStep=0.02 MinStep=1e-7 MaxStep=0.05
      Goal { Parameter=Temperature Value=30 }
   ) {
      Coupled (Iterations=300) { Poisson Electron Hole }
   }
   Save (FilePrefix = "n@node@_30K")

   #----- 4. 30 -> 20 K ----------------------------------------------
   NewCurrentPrefix = "ramp_30_20_"
   Quasistationary (
      InitialStep=0.01 MinStep=1e-8 MaxStep=0.05
      Goal { Parameter=Temperature Value=20 }
   ) {
      Coupled (Iterations=400) { Poisson Electron Hole }
   }
   Save (FilePrefix = "n@node@_20K")

   #----- 5. C-V sweep at 20 K (frequency = 1 MHz fixed) -------------
   #  Sweep Vg from -8 V (depletion) to +2 V (accumulation)
   #  AC small-signal at every DC step gives C(Vg)
   NewCurrentPrefix = "CV_20K_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
   }

   NewCurrentPrefix = "CV_20K_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      ACCoupled (
         StartFrequency=1e6  EndFrequency=1e6  NumberOfPoints=1
         Decade
         Node(source drain gate substrate)
      ) { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_CV_20K"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }
   Save (FilePrefix = "n@node@_CV_done")

   #----- 6. C-f sweep at 20 K (Vg = 0 V, frequency 1 kHz -> 1 GHz) --
   Load (FilePrefix = "n@node@_20K")
   NewCurrentPrefix = "Cf_20K_setVg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
   }

   NewCurrentPrefix = "Cf_20K_"
   ACCoupled (
      StartFrequency=1e3  EndFrequency=1e9  NumberOfPoints=7
      Decade
      Node(source drain gate substrate)
   ) { Poisson Electron Hole }

   #----- 7. Id-Vg transfer at 20 K (Vd = 0.1 V) ---------------------
   Load (FilePrefix = "n@node@_20K")
   NewCurrentPrefix = "IdVg_20K_setVd_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=0.1 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
   }
   NewCurrentPrefix = "IdVg_20K_toNeg_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
   }
   NewCurrentPrefix = "IdVg_20K_sweep_"
   Quasistationary (
      InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 }
   ) {
      Coupled (Iterations=200) { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_IdVg_20K"
             Time=(Range=(0 1) Intervals=5) NoOverwrite )
   }
}
