
## TESTING PROJECT 

## UPDATED - V2

STEP 1 — Set up your work directory
Open a terminal on your Linux machine where Sentaurus T-2022.03 is installed. Then:
bash# 1. Create a clean working directory
mkdir -p ~/work/moshemt_cryo
cd ~/work/moshemt_cryo

# 2. Verify Sentaurus is available (you should see /path/to/T-2022.03)
which sde
which sdevice
which swb
If those commands show "not found", run your Sentaurus environment script first (something like source /opt/synopsys/sentaurus_setup.sh — your sysadmin will know the exact path).
STEP 2 — Place the three files
Copy the three downloaded files into ~/work/moshemt_cryo/ so the directory looks like this:
~/work/moshemt_cryo/
├── moshemt_sde.cmd
├── moshemt_sdevice.cmd
└── models.par
That's it. No subdirectories needed.
STEP 3 — Choose how to run: Workbench OR command-line
Option A — Sentaurus Workbench (recommended, easier)
bashcd ~/work/moshemt_cryo
swb &
In the SWB window:

File → New → Project → name it moshemt_cryo, save it in ~/work/.
In the Tool Bar on the left, find and drag two tools into your project flow:

sde (Sentaurus Structure Editor)
sdevice (Sentaurus Device)


Right-click the sde tool node → Edit Input → paste contents of moshemt_sde.cmd. Save.
Right-click the sdevice tool node → Edit Input → paste contents of moshemt_sdevice.cmd. Save.
Make sure models.par is in the project directory (copy it there if SWB created a subdirectory).
Right-click the project node → Run All (or right-click sdevice → Run if SDE already ran).
Watch progress in the bottom log pane. Each tool node turns green when complete.

Expected runtime on a modern 8-core machine:

SDE: 30 seconds – 2 minutes
SDevice: 45 minutes to 3 hours depending on whether the 20 K convergence is clean

Option B — Command line (without SWB)
You need to manually substitute n@node@ and @tdr@ since SWB token expansion isn't happening.
bashcd ~/work/moshemt_cryo

# 1. Replace @node@ placeholders with literal "n0" in SDE file
sed -i 's/n@node@/n0/g' moshemt_sde.cmd

# 2. Run SDE - builds the structure and mesh
sde -e -l moshemt_sde.cmd

# After this, you should see: n0_msh.tdr, n0_msh.grd, n0_msh.dat

# 3. Patch SDevice to use the actual mesh filename
sed -i 's/n@node@/n0/g' moshemt_sdevice.cmd
sed -i 's/"@tdr@"/"n0_msh.tdr"/g' moshemt_sdevice.cmd

# 4. Run SDevice
sdevice moshemt_sdevice.cmd
STEP 4 — Check that each stage completed
After the run, check the log file:
bashtail -30 n0_des.log     # last 30 lines should say "End of simulation"
Look for these milestone messages in the log:
init_300K_  ...  Convergence reached      ← Step 1 done
ramp_300_77_ ... Convergence reached      ← Step 2 done
ramp_77_30_  ... Convergence reached      ← Step 3 done
ramp_30_20_  ... Convergence reached      ← Step 4 done (HARDEST)
CV_20K_     ...  Convergence reached      ← Step 5 done
Cf_20K_     ...  Convergence reached      ← Step 6 done
IdVg_20K_   ...  Convergence reached      ← Step 7 done
If it fails at any stage, the log shows the last attempted step. See troubleshooting below.
STEP 5 — View the results
You have three result files to inspect:
5a. Structure and band diagrams → SVisual
bashsvisual n0_des.tdr &
In SVisual:

Left panel → Materials → toggle visibility of layers
Plot → Add 2D Plot → eDensity → you should see a bright stripe at the AlN/GaN interface (the 2DEG)
Tools → Cutline → Vertical cut at y=2.5 µm → plot ConductionBandEnergy vs depth → you'll see the conduction-band notch where the 2DEG sits

5b. Id-Vg and C-V curves → Inspect
bashinspect n0_des.plt &
In Inspect:

Curve → New → X axis: gate OuterVoltage → Y axis: drain TotalCurrent → this is your Id-Vg at 20 K
For C-V: X axis: gate OuterVoltage → Y axis: gate gate Capacitance → C-V at 1 MHz, 20 K

5c. C-f (frequency vs Capacitance) → Inspect
bashinspect n0_ac.plt &
# or it might be embedded in n0_des.plt; try both

X axis: Frequency → Y axis: gate gate Capacitance → this is your C-f curve at 20 K, Vg = 0
Set the X axis to log scale (right-click axis → Logarithmic) to span 1 kHz to 1 GHz

STEP 6 — Common errors and exact fixes
Error in log fileMeaningExact fixMaterial "Aluminum2O3" not foundYour install uses Al2O3In moshemt_sde.cmd and models.par: change all "Aluminum2O3" to "Al2O3". Also change MaterialInterface in SDevice.Material "HfO2" not foundOlder installChange to "HafniumOxide" everywhereCannot find edge near position ...Mesh didn't reach that depthOpen SDE structure in SVisual, verify y/d coordinates of the contact match a real edge. Increase mesh density.Convergence failure at T=27.5 (during 30 → 20 K ramp)Most common cryo problemIn SDevice, add an intermediate stop. Find the ramp_30_20_ block and split it: first ramp to 25 K, then to 20 K, with InitialStep=0.005 for the second leg.Quasistationary not converged at gate voltage 0.3 VThreshold region instabilityReduce MaxStep from 0.02 to 0.005 in the Id-Vg sweep blockxMoleFraction undefined warningAlGaN parameter resolutionAdd MoleFraction explicit to the AlGaN constant profile region. If still fails, hardcode AlGaN parameters by creating a new material AlGaN025 in models.par and using it in SDE.Singular JacobianNumerical breakdownIn Math block, change Method = Blocked to Method = ILS; usually resolves itLicense checkout failedSynopsys licensingNot your code — talk to sysadmincommand not found: sdeEnvironment not loadedSource your Sentaurus setup script
STEP 7 — If the 30 K → 20 K ramp fails (the most common case)
This is the cryogenic crisis point. If it fails, replace the existing ramp_30_20_ block in moshemt_sdevice.cmd with this two-step version:
   #----- 4a. 30 -> 25 K ---------------------------------------------
   NewCurrentPrefix = "ramp_30_25_"
   Quasistationary (
      InitialStep=0.01 MinStep=1e-8 MaxStep=0.05
      Goal { Parameter=Temperature Value=25 }
   ) {
      Coupled (Iterations=400) { Poisson Electron Hole }
   }
   Save (FilePrefix = "n@node@_25K")

   #----- 4b. 25 -> 20 K ---------------------------------------------
   NewCurrentPrefix = "ramp_25_20_"
   Quasistationary (
      InitialStep=0.005 MinStep=1e-10 MaxStep=0.02
      Goal { Parameter=Temperature Value=20 }
   ) {
      Coupled (Iterations=500) { Poisson Electron Hole }
   }
   Save (FilePrefix = "n@node@_20K")
STEP 8 — Expected results sanity check
When everything runs successfully, your results should show:
QuantityExpected range at 20 K2DEG density (peak eDensity)10¹² – 10¹³ cm⁻²Threshold voltage (Id-Vg)between −5 V and −2 VMax gate capacitance (C-V)5–15 fF/µm (per gate length)C(1 MHz) / C(1 kHz) ratio0.7 – 1.0 (lower ratio means more trap response)Id at Vg=0, Vd=0.1 V0.1 – 10 mA/mm
If results are wildly different (e.g., zero current everywhere, or capacitance is 0), the most likely cause is that polarization wasn't applied. Open the TDR in SVisual and plot PE_Polarization — it should be nonzero in AlGaN and AlN regions.

Honest closing note
I've been careful with syntax, but I cannot run Sentaurus to verify these files actually execute on your machine. Different Sentaurus installs have different default material lists, different datexcodes.txt content, and different licensing of advanced features. The fixes above cover the most likely issues; if you hit an error not in my troubleshooting table, paste the exact error message from the log file and I can pinpoint the fix.
Cryogenic GaN TCAD is genuinely difficult — even published papers usually mention "convergence assisted by parameter tuning." Be patient with the 30 → 20 K step, and don't be discouraged if it takes two or three iterations to get there.
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Good, this is a useful concrete task. Before I write the code, one important honest note about 4 K simulation in Sentaurus that will save you debugging time:

**TCAD at cryogenic temperatures is genuinely hard.** Default Sentaurus models (Fermi-Dirac, incomplete ionization, mobility, bandgap narrowing) are calibrated for ~250–400 K. At 4 K you hit:
- Carrier freeze-out (dopants don't ionize) — must enable `IncompleteIonization`
- Numerical underflow from `exp(-Eg/kT)` — intrinsic carrier density becomes ~10⁻²⁰⁰⁰ cm⁻³
- Mobility models like Caughey-Thomas give nonsense — phonon scattering wrong, ionized impurity scattering dominates differently
- Convergence collapses without aggressive numerics settings

For AlGaN/GaN HEMTs specifically, the 2DEG at the AlGaN/GaN interface is **polarization-induced, not doping-induced**, so the freeze-out hits the buffer/contacts but the 2DEG itself survives. That's actually why HEMTs are studied at cryo — they keep conducting when MOSFETs die. Your simulation needs to capture this correctly.

I'll give you working code with the right numerics, plus comments where you'll likely need to tweak. Layer stack from your figure: SiC substrate → AlN nucleation → GaN buffer → C-doped GaN buffer → AlGaN back-barrier → UID GaN channel → AlGaN barrier → S/G/D contacts.Now the SDevice file — this is where the cryogenic physics matters most:Now the parameter file — without this, GaN/AlGaN defaults won't be reasonable at 4 K:All four files are ready. Here's how to use them and what to watch for:

## What each file does

- **`hemt_sde.cmd`** — Builds the structure (SiC → AlN → GaN buffer → C-GaN → AlGaN back-barrier → UID GaN → AlGaN barrier → Ni gate, Ti S/D) and meshes it with fine refinement at the 2DEG and under the gate. **This is the one you should actually use** for III-Nitride HEMTs.
- **`hemt_sprocess.cmd`** — Process-flow version for if your supervisor/lab requires SProcess. Note: SProcess isn't really the right tool for GaN MOCVD (no diffusion/implant physics to emulate), but the file works as a deposition-only flow.
- **`hemt_sdevice.cmd`** — Device simulation with the **temperature ramp** (300 K → 77 K → 4 K → Id-Vg + Id-Vd sweeps). This is where the cryogenic physics lives.
- **`models.par`** — GaN/AlGaN/AlN/SiC material parameters, including incomplete-ionization activation energies, polarization, and low-T mobilities.

## Run order

```
sde   -e -l hemt_sde.cmd            # build structure & mesh
sdevice  hemt_sdevice.cmd            # run physics simulation
```

(If you're using a Sentaurus Workbench project, drop them as nodes; the `n@node@` placeholders are already in place.)

## What you'll most likely hit, and the fixes

1. **Convergence failure during the 77 K → 4 K ramp.** This is the #1 problem in cryo TCAD. If it stalls:
   - Insert an intermediate stop at 30 K, then 10 K, then 4 K.
   - Increase `Iterations=500`, drop `MinStep` to `1e-8`.
   - Make sure `Fermi` and `IncompleteIonization` were on from the *first* Poisson solve, not added mid-ramp.

2. **2DEG density looks wrong (too low or zero).** Check that `Piezoelectric_Polarization` is enabled and that `xMoleFraction` is actually applied to the AlGaN regions (open the mesh in Tecplot/SVisual, plot `xMoleFraction` — should be 0.25 in the top barrier, 0.07 in the back-barrier). If it's zero, the constant profile didn't bind properly.

3. **Mobility values.** The `ConstantMobility` I set (1500 cm²/V·s for GaN electrons at 4 K) is a conservative bulk value. **The actual 2DEG mobility at 4 K can be 10–100× higher** because the 2DEG sits in undoped GaN with minimal ionized-impurity scattering. If you want the realistic 2DEG mobility, you'll need to either (a) measure it and plug in, or (b) use the `HighFieldDependence` + `Lombardi` models — but those are calibrated for Si, so you'd need to recalibrate from your Hall data.

4. **Gate leakage / Band2Band tunneling.** At 4 K the gate leakage drops by many orders of magnitude. If your simulation shows high gate current, it's almost certainly numerical noise from the `Band2Band` model — you can comment that line out for cleaner results.

5. **The C-doped buffer.** I modeled it as a Phosphorus-compensated region for simplicity. If you want C to act as a deep acceptor properly, you need to add a `Traps` block in `models.par` for the C-related deep level (E_C - 0.9 eV is the commonly cited value). I left that out because it makes convergence even harder; add it once the baseline works.

## Things I had to guess — change if your design specifies otherwise

- **Layer thicknesses** (25 nm barrier, 30 nm UID channel, 20 nm back-barrier, etc.) — your figure showed the stack but no numbers. These are typical values; replace with yours.
- **Al mole fractions** (0.25 in top barrier, 0.07 in back-barrier) — typical, but check your reference.
- **Gate length** (300 nm) and **S-G / G-D spacing** (1.0 / 1.5 µm) — typical RF HEMT geometry.
- **Gate metal Schottky barrier** (0.85 eV for Ni/AlGaN) — depends on Al%.

Adjust those at the top of `hemt_sde.cmd` (variables are right there) and at the `Electrode` and `Physics` blocks of the SDevice file.

One last thing — if you're doing this for a thesis or paper, **calibrate against any room-temperature measured Id-Vg you can get first**, then ramp to 4 K. Going straight to 4 K with uncalibrated material parameters and trusting the output is the most common way these simulations produce results that look reasonable but are wrong by 2-3×. Sentaurus is faithful to whatever you put in `models.par`; if those numbers are off, the cryogenic result is off.
