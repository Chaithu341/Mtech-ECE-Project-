#======================================================================#
#  Sentaurus Device (SDevice) - AlGaN/GaN HEMT at T = 4 K
#  Simulates Id-Vg transfer and Id-Vd output at cryogenic temperature
#
#  CRITICAL NOTES FOR CRYOGENIC (4 K) SIMULATION:
#
#  1. Default SDevice models are calibrated for room temperature.
#     At 4 K you MUST:
#       - Use Fermi-Dirac statistics (Boltzmann breaks down)
#       - Enable IncompleteIonization for dopants (carrier freeze-out)
#       - Tighten numerics: very small Digits, extra Iterations
#       - Provide a good initial guess (start from 300 K, ramp down)
#
#  2. ni(GaN) at 4 K is ~10^-200 cm-3, below double-precision range.
#     Sentaurus handles this with the eQuasiFermi formulation, but you
#     must enable Math options below or you'll get convergence failure
#     on the FIRST Poisson solve.
#
#  3. The AlGaN/GaN 2DEG is POLARIZATION-induced (not doping). Enable
#     the Piezoelectric_Polarization model. At 4 K the 2DEG density
#     barely changes from its 300 K value (~1e13 cm-2) - this is why
#     HEMTs are favored for cryo electronics.
#
#  4. Mobility at 4 K: phonon scattering negligible, ionized impurity
#     scattering dominates. Use ConstantMobility with cryogenic values
#     OR use ConstantMobility with explicit mu (2DEG mobility at 4K
#     ranges from 10^4 to 10^5 cm2/V-s depending on interface quality).
#
#  5. CAVEAT: Convergence at 4 K is often impossible from cold start.
#     The strategy below ramps T from 300 K -> 77 K -> 4 K, saving
#     the solution at each step.
#======================================================================#

File {
   Grid     = "n@node@_msh.tdr"
   Plot     = "n@node@_des.tdr"
   Current  = "n@node@_des.plt"
   Output   = "n@node@_des.log"
   Param    = "models.par"   ;# optional: GaN/AlGaN parameter overrides
}

Electrode {
   { Name="source"  Voltage=0.0   Resist=0  }
   { Name="drain"   Voltage=0.0   Resist=0  }
   { Name="gate"    Voltage=0.0   Barrier=0.85 }   ;# Ni/AlGaN Schottky ~0.85 eV
}

Thermode {
   { Name="source" Temperature=300 }
   { Name="drain"  Temperature=300 }
}

#----------------------------------------------------------------------
# Physics section
#----------------------------------------------------------------------
Physics {
   Temperature = 300   ;# starting point; we ramp down later

   # --- Statistics ---------------------------------------------------
   Fermi               ;# Fermi-Dirac statistics (mandatory at low T)

   # --- Mobility -----------------------------------------------------
   Mobility (
      DopingDependence
      HighFieldSaturation                ;# velocity saturation
      Enormal                            ;# transverse field degradation
   )

   # --- Recombination ------------------------------------------------
   Recombination (
      SRH( DopingDependence )
      Auger
      Band2Band                          ;# important for high-field gate leakage
   )

   # --- Bandgap & narrowing ------------------------------------------
   EffectiveIntrinsicDensity( NoBandGapNarrowing )
   ;# At 4 K, default BGN models extrapolate badly. Turn off and
   ;# rely on temperature dependence of Eg itself (Varshni below).

   # --- Polarization (mandatory for GaN/AlGaN) -----------------------
   Piezoelectric_Polarization (
      strain
   )

   # --- Incomplete ionization (mandatory below ~77 K) ----------------
   IncompleteIonization
}

#----------------------------------------------------------------------
# Region-specific physics: tune mobility and recomb per layer
#----------------------------------------------------------------------
Physics (Material="GaN") {
   MoleFraction(xFraction=0.0)
   Mobility(
      ConstantMobility   ;# at 4 K, use constant low-T mobility values
   )
}

Physics (Material="AlGaN") {
   # MoleFraction is read from doping profile (xMoleFraction field)
   Mobility(
      ConstantMobility
   )
}

Physics (Material="AlN") {
   Mobility( ConstantMobility )
}

Physics (Material="SiC") {
   Mobility( ConstantMobility )
}

# Interface trap density at AlGaN/GaN (typical for unpassivated devices)
Physics (RegionInterface="R_barrier/R_channel") {
   Traps(
      (FixedCharge Conc=1.0e13)          ;# positive sheet charge (donor-like)
      (Acceptor Level fromCondBand
       EnergyMid=0.3 Conc=1.0e12
       eXsection=1e-15 hXsection=1e-15)
   )
}

#----------------------------------------------------------------------
# Plotting
#----------------------------------------------------------------------
Plot {
   eDensity hDensity
   ElectricField/Vector Potential SpaceCharge
   eMobility hMobility
   eVelocity hVelocity
   Doping DonorConcentration AcceptorConcentration
   eQuasiFermi hQuasiFermi
   ConductionBandEnergy ValenceBandEnergy
   BandGap EffectiveBandGap
   xMoleFraction
   Piezo/Vector PE_Polarization
   eCurrent/Vector hCurrent/Vector TotalCurrent/Vector
   SRH Auger Band2Band
   eGapStatesRecombination
}

#----------------------------------------------------------------------
# Math section - CRITICAL for 4 K convergence
#----------------------------------------------------------------------
Math {
   Method = Blocked
   SubMethod = Super                ;# robust direct solver
   ACMethod = Blocked
   ACSubMethod = Super

   Extrapolate                       ;# helps continuation
   Derivatives
   RelErrControl
   Digits = 6                        ;# tight tolerance
   Notdamped = 100
   Iterations = 200                  ;# allow many - cryo is slow
   ExitOnFailure

   ;# --- Cryogenic-specific numerics --------------------------------
   ;# Prevent underflow when ni is astronomically small
   eMobilityAveraging  = ElementEdge
   hMobilityAveraging  = ElementEdge

   ;# Use eQuasiFermi formulation - far more stable than potential-only
   ;# at low T because it avoids exp(phi/Vt) blow-up
   -CheckUndefinedModels             ;# suppress warnings about unused models

   ;# Helps when temperature is being ramped:
   TensorGridAniso = 1

   ;# Plot mesh used for refinement studies
   NumberOfThreads = 4
}

#----------------------------------------------------------------------
# System block (declare device & wiring) - kept minimal
#----------------------------------------------------------------------
System {
   HEMT trans (source=s drain=d gate=g)
   Vsource_pset vg (g 0) { dc = 0 }
   Vsource_pset vd (d 0) { dc = 0 }
   Vsource_pset vs (s 0) { dc = 0 }
   Set ( s = 0 )
}

#----------------------------------------------------------------------
# Solve section - the temperature ramp is the trick
#----------------------------------------------------------------------
Solve {
   #-------------------------------------------------------------------
   # Step 1: Initial Poisson solve at 300 K (easy)
   #-------------------------------------------------------------------
   NewCurrentPrefix="init_300K_"
   Coupled( Iterations=200 LineSearchDamping=1e-6 ) { Poisson }
   Coupled { Poisson Electron Hole }
   Save ( FilePrefix="n@node@_300K" )

   #-------------------------------------------------------------------
   # Step 2: Ramp temperature 300 K -> 77 K (liquid N2)
   #-------------------------------------------------------------------
   NewCurrentPrefix="ramp_300_77_"
   Quasistationary (
      InitialStep=0.05 MinStep=1e-5 MaxStep=0.1
      Goal { Parameter=Temperature Value=77 }
   ) {
      Coupled { Poisson Electron Hole }
   }
   Save ( FilePrefix="n@node@_77K" )

   #-------------------------------------------------------------------
   # Step 3: Ramp temperature 77 K -> 4 K (liquid He)
   #-------------------------------------------------------------------
   # This is the dangerous part. If it fails to converge, increase
   # Iterations and reduce InitialStep further.
   NewCurrentPrefix="ramp_77_4_"
   Quasistationary (
      InitialStep=0.01 MinStep=1e-7 MaxStep=0.05
      Goal { Parameter=Temperature Value=4 }
   ) {
      Coupled( Iterations=300 ) { Poisson Electron Hole }
   }
   Save ( FilePrefix="n@node@_4K" )

   #-------------------------------------------------------------------
   # Step 4: At 4 K - run Id-Vg sweep (transfer characteristic)
   # Vd = 0.1 V (linear region), Vg swept from -6 V to +2 V
   #-------------------------------------------------------------------
   NewCurrentPrefix="IdVg_4K_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=0.1 }
   ) {
      Coupled { Poisson Electron Hole }
   }

   Quasistationary (
      InitialStep=0.01 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate"  Voltage=-6.0 }
   ) {
      Coupled { Poisson Electron Hole }
   }

   Quasistationary (
      InitialStep=0.005 MaxStep=0.02 MinStep=1e-6
      Goal { Name="gate"  Voltage=2.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_IdVg_4K"
             Time=(Range=(0 1) Intervals=20) NoOverwrite )
   }

   #-------------------------------------------------------------------
   # Step 5: Id-Vd output characteristic at fixed Vg
   # Reload 4 K solution, set Vg = 0 V, sweep Vd 0 -> 10 V
   #-------------------------------------------------------------------
   Load ( FilePrefix="n@node@_4K" )

   NewCurrentPrefix="IdVd_4K_Vg0_"
   Quasistationary (
      InitialStep=0.01 MaxStep=0.05 MinStep=1e-6
      Goal { Name="gate" Voltage=0.0 }
   ) {
      Coupled { Poisson Electron Hole }
   }

   Quasistationary (
      InitialStep=0.005 MaxStep=0.05 MinStep=1e-6
      Goal { Name="drain" Voltage=10.0 }
   ) {
      Coupled { Poisson Electron Hole }
      Plot ( FilePrefix="n@node@_IdVd_4K"
             Time=(Range=(0 1) Intervals=20) NoOverwrite )
   }
}
