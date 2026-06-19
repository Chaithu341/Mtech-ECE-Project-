#==============================================================================
#  SDevice command file  -- AlN/GaN DH-HEMT (Soni & Shrivastava, JEDS 2020, Fig.1)
#
#  Sequence:
#    (0) equilibrium
#    (1) ramp VDS = 1 V
#    (2) TRANSFER : VGS  -3 -> +2 V at VDS = 1 V   (calibrate gm, Vth)
#    (3) OUTPUT   : VDS   0 -> +5 V at fixed VGS    (calibrate Idsat)
#    (4) AC small-signal sweep -> extract fT (|h21| = 1)
#
#  Calibration targets:  fT(sim) ~ 328 GHz ; Imax ~ 2.5-3 A/mm ; Ecrit(GaN)=3MV/cm
#==============================================================================

#------------------------------------------------------------------------------
File {
   Grid      = "hemt_msh.tdr"
   Plot      = "hemt_des.tdr"
   Current   = "hemt_des.plt"
   Output    = "hemt_des.log"
   Parameter = "hemt.par"
}

#------------------------------------------------------------------------------
Electrode {
   { Name = "source" Voltage = 0.0 }
   { Name = "drain"  Voltage = 0.0 }
   # Schottky gate (Ni-like). Barrier tuned so Vth < 0 (normally-ON, as in paper).
   { Name = "gate"   Voltage = 0.0  Schottky  Barrier = 1.0
                     eRecVelocity = 2.573e6  hRecVelocity = 1.93e6 }
}

#------------------------------------------------------------------------------
#  POLARIZATION as fixed interface charges (verified, convergence-friendly).
#  Positive sheet charge at the LOWER barrier/channel interface forms the 2DEG.
#  Negative sheet charge at the UPPER cap/barrier interface (charge neutrality).
#  Magnitudes (~/cm^2) chosen to give 2DEG ns > 1e13 cm^-2 for the 3.5nm AlN.
#------------------------------------------------------------------------------
# Lower AlN-barrier / GaN-channel interface : +polarization -> 2DEG
Physics (RegionInterface = "R.Barrier/R.Channel") {
   Traps ( ( FixedCharge Conc = 5.5e13 ) )   # cm^-2 , positive
}
# Upper GaN-cap / AlN-barrier interface : -polarization
Physics (RegionInterface = "R.Cap/R.Barrier") {
   Traps ( ( FixedCharge Conc = -5.5e13 ) )  # cm^-2 , negative
}
# Nucleation AlN / GaN-buffer (back interface) : small compensation
Physics (RegionInterface = "R.Buffer/R.Nucleation") {
   Traps ( ( FixedCharge Conc = -3.0e13 ) )
}

#------------------------------------------------------------------------------
#  Surface donor states (virtual-gate physics, Sec.V-A): GaN-cap / SiN interface
#  Donor-type states that ionize under high drain field and deplete the 2DEG.
#------------------------------------------------------------------------------
Physics (RegionInterface = "R.Cap/R.SiN") {
   Traps (
      ( Donor Level fromCondBand EnergyMid = 0.37  Conc = 1e13
        eXsection = 1e-14  hXsection = 1e-14 )
   )
}

#------------------------------------------------------------------------------
#  C-doped buffer traps (Joshi/Shrivastava): deep acceptor + donor
#------------------------------------------------------------------------------
Physics (Region = "R.CBuffer") {
   Traps (
      ( Acceptor Level fromCondBand EnergyMid = 0.90 Conc = 1e18
        eXsection = 1e-15 hXsection = 1e-15 )
      ( Donor    Level fromValBand  EnergyMid = 0.90 Conc = 5e17
        eXsection = 1e-15 hXsection = 1e-15 )
   )
}

#------------------------------------------------------------------------------
#  Global physical models
#------------------------------------------------------------------------------
Physics {
   AreaFactor = 1.0

   Hydrodynamic ( eTemperature )       # carrier heating / velocity overshoot
   Thermodynamic                       # lattice self-heating

   Mobility (
      DopingDependence ( Masetti )     # C-dopant scattering
      HighFieldSaturation ( CarrierTempDrive )
      Enormal                          # 2DEG / interface mobility
   )

   EffectiveIntrinsicDensity ( OldSlotboom )

   Recombination (
      SRH ( DopingDependence )
      Auger
      Avalanche ( vanOverstraeten Eparallel )   # impact ionization
   )

   # Gate leakage : barrier (Fowler-Nordheim) tunneling at the Schottky gate
   eBarrierTunneling "FN"

   Thermionic                          # thermionic emission at heterojunctions
   HeteroInterfaces

   Temperature = 300
}

#------------------------------------------------------------------------------
Plot {
   eDensity hDensity eCurrent hCurrent
   ElectricField/Vector Potential SpaceCharge
   eMobility hMobility eVelocity
   eTemperature lTemperature
   ConductionBandEnergy ValenceBandEnergy eQuasiFermiEnergy
   SRHRecombination Auger AvalancheGeneration
   eTrappedCharge hTrappedCharge
}

#------------------------------------------------------------------------------
Math {
   Extrapolate
   Derivatives
   RelErrControl
   Digits = 5
   ErrReff(electron) = 1e8
   ErrReff(hole)     = 1e8
   Iterations = 20
   Notdamped  = 80
   Method = Blocked
   SubMethod = Super
   ACMethod   = Blocked
   ACSubMethod = Super
   ExitOnFailure
   CNormPrint
   DirectCurrent
   # 2DEG numerics
   eMobilityAveraging = ElementEdge
}

#------------------------------------------------------------------------------
Solve {
   #--- (0) equilibrium -------------------------------------------------------
   NewCurrentPrefix = "init_"
   Coupled ( Iterations = 150 ) { Poisson }
   Coupled { Poisson Electron Hole }
   Coupled { Poisson Electron Hole eTemperature lTemperature }

   #--- (1) ramp drain to 1 V -------------------------------------------------
   Quasistationary (
      InitialStep = 0.01 MaxStep = 0.1 MinStep = 1e-6 Increment = 1.3
      Goal { Name = "drain" Voltage = 1.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }

   #--- (2) TRANSFER : VGS -3 -> +2 V at VDS=1V -------------------------------
   NewCurrentPrefix = "transfer_VD1_"
   # go down to -3 first
   Quasistationary (
      InitialStep = 0.02 MaxStep = 0.05 MinStep = 1e-6
      Goal { Name = "gate" Voltage = -3.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }
   # sweep up to +2
   Quasistationary (
      InitialStep = 0.01 MaxStep = 0.05 MinStep = 1e-6
      Goal { Name = "gate" Voltage = 2.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }

   #--- (3) set bias for OUTPUT, then sweep VDS 0->5 V ------------------------
   NewCurrentPrefix = "setVG_"
   Quasistationary (
      InitialStep = 0.02 MaxStep = 0.05 MinStep = 1e-6
      Goal { Name = "gate" Voltage = 0.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }
   # reset drain to 0
   NewCurrentPrefix = "resetVD_"
   Quasistationary (
      InitialStep = 0.05 MaxStep = 0.1 MinStep = 1e-6
      Goal { Name = "drain" Voltage = 0.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }
   # output sweep
   NewCurrentPrefix = "output_VG0_"
   Quasistationary (
      InitialStep = 0.01 MaxStep = 0.05 MinStep = 1e-6
      Goal { Name = "drain" Voltage = 5.0 }
   ){ Coupled { Poisson Electron Hole eTemperature lTemperature } }

   #--- (4) AC small-signal at fT bias (VGS=0, VDS=3V) -> extract fT ----------
   NewCurrentPrefix = "ac_"
   Quasistationary (
      InitialStep = 0.05 MaxStep = 0.1 MinStep = 1e-6
      Goal { Name = "drain" Voltage = 3.0 }
   ){
      ACCoupled (
         StartFrequency = 1e8  EndFrequency = 1e12
         NumberOfPoints = 61  Decade
         Node ( "gate" "drain" "source" )
         Exclude ( "source" )
      ){ Poisson Electron Hole }
   }
}
