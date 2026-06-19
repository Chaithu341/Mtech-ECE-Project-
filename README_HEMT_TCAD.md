# AlN/GaN DH-HEMT — Sentaurus TCAD Deck

Reconstruction of the normally-ON AlN/GaN double-heterostructure HEMT from
Fig. 1(a) of Soni & Shrivastava, *"Computational Modelling-Based Device Design
for Improved mmWave Performance and Linearity of GaN HEMTs"*, IEEE J. Electron
Devices Soc., Vol. 8, pp. 33–41, 2020 (original device after Shinohara et al.,
IEDM 2011, ref. [15]).

## Files

| File | Purpose |
|------|---------|
| `hemt_sde.cmd` | Sentaurus Structure Editor (SDE) — geometry, contacts, doping, mesh |
| `hemt_des.cmd` | Sentaurus Device (SDevice) — physics, polarization, traps, DC + AC solve |
| `hemt.par` | Material parameter file (GaN, AlN, SiN, SiC) |
| `inspect_fT.tcl` | Inspect script — extracts fT (|h21| = 1) from the AC results |

## Run order

```
sde   -e -l hemt_sde.cmd          # builds hemt_msh.tdr
sdevice    hemt_des.cmd           # runs DC + AC, writes hemt_des*.plt / .tdr
inspect -f inspect_fT.tcl         # prints extracted fT
```
(Or drop the four files into a Sentaurus Workbench project node.)

## Device geometry (from Fig. 1(a), top → bottom)

| Layer | Material | Thickness |
|-------|----------|-----------|
| Passivation | SiN | 40 nm |
| Cap | GaN | 2.5 nm |
| Barrier | AlN | 3.5 nm |
| Channel | UID GaN | 150 nm (tChannel baseline, Sec. IV) |
| C-doped buffer | GaN (Na=1e18, Nd=5e17 cm⁻³) | 150 nm |
| Buffer | UID GaN | 250 nm |
| Nucleation | AlN | 100 nm |
| Substrate | SiC | (modeled 200 nm) |

Lateral: **Lsg = 40 nm, Lg = 20 nm, Lgd = 40 nm** (paper baseline, Sec. III).

## Physics models (exactly those stated in the paper, Sec. III)

- Polarization at all heterointerfaces → implemented as bias-independent
  `FixedCharge` interface traps (positive at the lower AlN/GaN interface to form
  the 2DEG, negative at the upper interfaces for charge neutrality).
- 2DEG electrostatics & band offsets → `HeteroInterfaces`, `Thermionic`.
- Carrier + lattice heating → `Hydrodynamic(eTemperature)` + `Thermodynamic`.
- C-dopant scattering → `Masetti` doping-dependent mobility.
- Surface/buffer traps → donor surface states at GaN/SiN (virtual gate, Sec. V-A);
  deep acceptor + donor traps in the C-doped buffer (Joshi/Shrivastava model).
- Gate leakage → Fowler–Nordheim barrier tunneling (`eBarrierTunneling`).
- Breakdown → impact ionization (`Avalanche`, van Overstraeten/Chynoweth) with
  GaN coefficients giving a critical field ≈ 3 MV/cm.

## Calibration procedure (matching Fig. 1(b)–(d))

The simulation has four independent "knobs". Tune them in this order:

1. **2DEG sheet density `ns` (target > 1×10¹³ cm⁻²)**
   Knob: `FixedCharge Conc` at `R.Barrier/R.Channel` in `hemt_des.cmd`
   (start 5.5×10¹³ cm⁻²). After an equilibrium solve, integrate `eDensity`
   across the channel in SVisual; scale the charge until ns > 1×10¹³.

2. **Threshold voltage `Vth` (normally-ON ⇒ Vth < 0)**
   Knob: Schottky `Barrier` of the gate electrode in `hemt_des.cmd`
   (start 1.0 eV). Raise the barrier to push Vth more negative, lower it to
   push positive. Check against the transfer curve (Fig. 1(c)): conduction
   should turn on around VGS ≈ −2 to −1 V.

3. **On-current / transconductance gm**
   Knobs: `mumax_n` (low-field mobility) and `Vsat0` (saturation velocity) in
   `hemt.par`. Match the output curves (Fig. 1(d)): Idmax ≈ 2.5 A/mm at
   VGS = +2 V, VDS = 5 V. gm peak directly sets fT.

4. **Cut-off frequency `fT` (target ≈ 328 GHz simulated)**
   Knob: `Vsat0` in `hemt.par` (GaN). Higher vsat / more overshoot → higher fT.
   Run the AC sweep, then `inspect -f inspect_fT.tcl`. fT is the −20 dB/decade
   extrapolation of |h21| to 0 dB. Iterate vsat0 (typically 2.0–2.7×10⁷ cm/s)
   until the extracted fT lands at ~328 GHz.

## Notes / caveats

- **2DEG mesh is critical.** The vertical mesh at the lower AlN/GaN interface is
  set to ~0.5 Å (`Ref.2DEG`). If the equilibrium solve shows no 2DEG peak,
  refine further — an under-resolved interface is the most common failure.
- **Contacts:** source/drain are defined as ohmic top-surface contacts; for the
  self-aligned recessed ohmics of the real Shinohara device you can recess the
  S/D regions in SDE down to the barrier so the contact directly meets the 2DEG.
  This mainly affects Rs/Rd (the extrinsic-delay term in the fT expression).
- **Convergence:** if the coupled hydrodynamic+thermodynamic solve stalls, first
  obtain a drift-diffusion solution (drop `Hydrodynamic`/`Thermodynamic` and the
  `eTemperature lTemperature` from the `Coupled` braces), then switch them on and
  re-solve. The `vanOverstraetendeMan` avalanche block only matters for the
  off-state breakdown (VBD) part of the VBD·fT figure of merit.
- **Polarization sign** follows Ga-face growth (positive bound charge at the
  lower barrier/channel interface). If you see a 2DHG instead of a 2DEG, flip
  the signs of the two `FixedCharge` interface blocks.
- Material parameters (vsat, mobility, affinities, avalanche coefficients) are
  literature values for GaN/AlN and are the intended fitting targets — adjust
  them to your own calibrated reference data set.
