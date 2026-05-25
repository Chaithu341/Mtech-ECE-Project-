
## TESTING PROJECT 

## UPDATED

All four files updated with Table 9.1 / 9.2 dimensions:

- **`hemt_sde.cmd`** — recommended structure builder (SDE)
- **`hemt_sprocess.cmd`** — alternative SProcess flow (now updated with new dimensions + AlN spacer + correct contact placements)
- **`hemt_sdevice.cmd`** — device simulation with 4 K ramp
- **`models.par`** — material parameters

**Use only ONE structure file** — either SDE *or* SProcess, not both. They produce the same structure. SDE remains my recommendation; SProcess is there only if your lab/supervisor mandates it.

**Run order:**
```
# Option A (recommended):
sde -e -l hemt_sde.cmd
sdevice hemt_sdevice.cmd

# Option B (if SProcess required):
sprocess hemt_sprocess.cmd
sdevice hemt_sdevice.cmd
```

**One caveat specific to the SProcess file:** SProcess doesn't model strain or polarization during deposition the way III-N epitaxy actually works — it just stacks layers geometrically. The polarization physics is still applied by SDevice at runtime, so the final electrical simulation is the same. But the *process* file is essentially a geometric script, not a physical process emulation. That's why SDE is cleaner for GaN.

Same honest caveats as before — I can't run Sentaurus to verify execution, but every dimension is hand-checked against your table, and the known bugs from earlier are fixed.

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
