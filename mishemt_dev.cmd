#======================================================================#
#  Sentaurus Device (SDevice) - T-2022.03
#  AlGaN/GaN MIS-HEMT characterization (recessed-ohmic device)
#
#  Produces (a complete simple publishable set):
#    RT (300 K):  Id-Vd family (Vg = 0,-2,-4) ; Id-Vg transfer ; C-V
#    CT (4 K):    Id-Vd at Vg=0 ; Id-Vg transfer
#
#  Region names (match SDE): R_barrier R_channel R_buffer
#       R_nucleation R_substrate R_dielectric
#       R_source_metal R_drain_metal R_gate_metal
#  Contacts: source drain gate substrate
#
#  Command line: replace tokens with literal names (see run guide):
#    @tdr@   -> mishemt_msh.tdr
#    @tdrdat@-> mishemt_des.tdr
#    @plot@  -> mishemt_des.plt
#    @log@   -> mishemt_des.log
#    @acplot@-> mishemt_ac.plt
#======================================================================#

File {
   Grid      = "@tdr@"
   Plot      = "@tdrdat@"
   Current   = "@plot@"
   Output    = "@log@"
   Param     = "models.par"
   ACExtract = "@acplot@"
}

Electrode {
   { Name="source"    Voltage=0.0 }          ;# ohmic (no WF/barrier)
   { Name="drain"     Voltage=0.0 }          ;# ohmic
   { Name="gate"      Voltage=0.0  Workfunction=4.7 }   ;# MIS gate
   { Name="substrate" Voltage=0.0 }
}

Thermode {
   { Name="substrate" Temperature=300 SurfaceResistance=0 }
}

Physics {
   Temperature = 300
   Fermi                                ;# Fermi-Dirac (needed at cryo)
   IncompleteIonization                 ;# freeze-out at low T
   Piezoelectric_Polarization (strain)  ;# generates the 2DEG
   Mobility ( DopingDependence HighFieldSaturation Enormal )
   Recombination ( SRH (DopingDependence) )
}

Physics (Material="GaN")   { Mobility(ConstantMobility) }
Physics (Material="AlGaN") { Mobility(ConstantMobility) }
Physics (Material="AlN")   { Mobility(ConstantMobility) }
Physics (Material="SiC")   { Mobility(ConstantMobility) }

Physics (MaterialInterface="AlGaN/GaN") {
   Traps ( (FixedCharge Conc=1.0e12) )
}

Plot {
   eDensity hDensity
   ElectricField/Vector Potential SpaceCharge
   eMobility eVelocity
   Doping DonorConcentration AcceptorConcentration
   eQuasiFermi hQuasiFermi
   ConductionBandEnergy ValenceBandEnergy BandGap
   xMoleFraction
   Piezo/Vector PE_Polarization
   eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
}

Math {
   Method = Blocked   SubMethod = Super
   ACMethod = Blocked ACSubMethod = Super
   Extrapolate
   Derivatives
   RelErrControl
   Digits = 5
   Iterations = 200
   Notdamped = 100
   ExitOnFailure
   eMobilityAveraging = ElementEdge
   hMobilityAveraging = ElementEdge
   -CheckUndefinedModels
   NumberOfThreads = 4
}

Solve {

   #--- Initial solution at 300 K ------------------------------------
   NewCurrentPrefix = "init_"
   Coupled (Iterations=200 LineSearchDamping=1e-6) { Poisson }
   Coupled (Iterations=200) { Poisson Electron Hole }
   Save (FilePrefix = "n_init_RT")

   #==================================================================#
   #  ROOM TEMPERATURE (300 K)
   #==================================================================#

   #--- RT Id-Vd family: Vg = 0, -2, -4 (each: set Vg, sweep Vd 0->10)
   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "RT_IdVd_Vg0_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 } ) { Coupled { Poisson Electron Hole } }
   Quasistationary ( InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=10.0 } ) { Coupled { Poisson Electron Hole } }

   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "RT_IdVd_Vg-2_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-2.0 } ) { Coupled { Poisson Electron Hole } }
   Quasistationary ( InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=10.0 } ) { Coupled { Poisson Electron Hole } }

   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "RT_IdVd_Vg-4_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-4.0 } ) { Coupled { Poisson Electron Hole } }
   Quasistationary ( InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=10.0 } ) { Coupled { Poisson Electron Hole } }

   #--- RT Id-Vg + Ig-Vg transfer at Vd = 1 V (for Vth, gm, leakage)
   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "RT_IdVg_setVd_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=1.0 } ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_IdVg_toNeg_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 } ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_IdVg_sweep_"
   Quasistationary ( InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 } ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_RT_IdVg" Time=(Range=(0 1) Intervals=4) NoOverwrite )
   }

   #--- RT C-V (Cgs vs Vg) at Vd=0, f=1 MHz --------------------------
   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "RT_CV_toNeg_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 } ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "RT_CV_sweep_"
   Quasistationary ( InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 } ) {
      ACCoupled ( StartFrequency=1e6 EndFrequency=1e6 NumberOfPoints=1 Decade
                  Node(source drain gate substrate) ) { Poisson Electron Hole }
   }

   #==================================================================#
   #  RAMP 300 -> 77 -> 30 -> 4 K
   #==================================================================#
   Load (FilePrefix = "n_init_RT")
   NewCurrentPrefix = "ramp_77_"
   Quasistationary ( InitialStep=0.05 MinStep=1e-5 MaxStep=0.1
      Goal { Parameter=Temperature Value=77 } )
      { Coupled (Iterations=200) { Poisson Electron Hole } }
   NewCurrentPrefix = "ramp_30_"
   Quasistationary ( InitialStep=0.02 MinStep=1e-7 MaxStep=0.05
      Goal { Parameter=Temperature Value=30 } )
      { Coupled (Iterations=300) { Poisson Electron Hole } }
   NewCurrentPrefix = "ramp_4_"
   Quasistationary ( InitialStep=0.01 MinStep=1e-8 MaxStep=0.05
      Goal { Parameter=Temperature Value=4 } )
      { Coupled (Iterations=400) { Poisson Electron Hole } }
   Save (FilePrefix = "n_init_CT")

   #==================================================================#
   #  CRYOGENIC (4 K)
   #==================================================================#

   #--- CT Id-Vd at Vg = 0 -------------------------------------------
   Load (FilePrefix = "n_init_CT")
   NewCurrentPrefix = "CT_IdVd_Vg0_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 } ) { Coupled { Poisson Electron Hole } }
   Quasistationary ( InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=10.0 } ) { Coupled { Poisson Electron Hole } }

   #--- CT Id-Vg transfer at Vd = 1 V --------------------------------
   Load (FilePrefix = "n_init_CT")
   NewCurrentPrefix = "CT_IdVg_setVd_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=1.0 } ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_IdVg_toNeg_"
   Quasistationary ( InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=-8.0 } ) { Coupled { Poisson Electron Hole } }
   NewCurrentPrefix = "CT_IdVg_sweep_"
   Quasistationary ( InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate" Voltage=2.0 } ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n_CT_IdVg" Time=(Range=(0 1) Intervals=4) NoOverwrite )
   }
}
