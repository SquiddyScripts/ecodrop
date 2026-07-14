# Year 2 (2025–26) — Four Gravitational Storage–Regeneration Systems

> *"The Effect of Different Gravitational Storage–Regeneration Applications on Power
> Efficiency"* — Chantilly HS Science Fair (Jan 2026) → Regionals (Mar 2026) → ISEF 2026
> season.

Year 2 asked a bigger question: **which architecture makes gravity storage practical?**
Four systems were designed and compared under identical conditions (50 kg effective mass,
3 m drop, same drivetrain and motor model — the Turnigy SK3-5065-236KV selected in Year 1):

| System | Category | Core idea |
|--------|----------|-----------|
| **Variable Counterweight** | Regenerative | Dynamically match counterweight mass to the load with modular magnetic barbell masses (supercapacitor-equipped), so the motor only pays for imbalance + friction |
| **Dual Weight** | Regenerative | Elevator-style: two hoist drums on one shaft, ropes wound opposite, generate on both directions of travel |
| **Buoyancy** | Storage | Lift the weight with Archimedes' force by flooding a dual-layer chamber; drop it through the generator on discharge |
| **Halbach Array (Electromagnetic)** | Storage | Tubular linear motors with T-shaped quasi-Halbach magnets lift the weight without ropes; gravity discharges it |

## The two simulation codebases

### `simulation-electromech-ode/` (January 2026)
The first full MATLAB codebase: a time-domain electromechanical ODE model
(mass → drum → sprocket → gearbox → bevel gears → motor) with energy-conservation
validation, gearbox-ratio optimization, per-system cycle models, tiered comparisons and
the six science-fair graphs. Includes extensive judge-prep documentation in `docs/`.
**Its comparison run produced the first generation of results: Variable CW ≈ 89.7 % RTE.**

### `simulation-four-systems/` (March 2026)
The rebuilt, calibrated pipeline used for the final backboard and logbook: `ode45` descent
dynamics in `physics_core.m`, per-system loss models, 10–100 perturbed replicates, one-way
ANOVA, Sankey loss-flow figures, and the dark-theme presentation plot pipeline.
**Its presentation pipeline produced the final reported numbers:**

| System | Discharge efficiency | Net energy/cycle |
|--------|---------------------|------------------|
| Variable Counterweight | **77.0 ± 0.5 %** | −0.1 kJ |
| Dual Weight | 60.0 ± 1.2 % | −0.6 kJ |
| Buoyancy | 39.5 ± 1.8 % | −2.8 kJ |
| Halbach Array | 27.0 ± 2.1 % | −3.3 kJ |

ANOVA: F(3, 36) = 6.10, p < 0.001, η² = 0.337 — system architecture significantly affects
efficiency. All numbers are **simulation results** calibrated against the Year-1 physical
measurements; none of the four systems has been physically built at full scale.
⚠️ The two codebases report different absolute numbers — see [PROVENANCE.md](../PROVENANCE.md)
for the honest reconciliation.

## Other contents

| Item | Description |
|------|-------------|
| `latex/TECHNICAL_DOCUMENTATION.pdf` | Formal LaTeX technical documentation of the ODE codebase: equations, architecture, per-file mathematical reference (compiled PDF + source) |
| `presentation-graphs/` | Final presentation figures (dark theme), regenerative-tier plots, per-system time-series dashboards, and the MATLAB scripts that generated them |
| `EcoDrop_Data_Table.xlsx` | Backboard data table |
| `simulation-electromech-ode/docs/` | Judge Q&A prep: physics justifications, "how the calculations work", speech scripts — a snapshot of how the team prepared to defend the work |

## Reproducing

Both codebases run on MATLAB (R2016b+; developed on R2025b):

```matlab
% Four-systems pipeline (final figures + CSV)
cd simulation-four-systems
addpath('matlab'); addpath('matlab/systems');
run_presentation_plots_dark    % figures -> matlab/outputs/
main                           % full ODE run + ANOVA + validation

% Electromech ODE codebase
cd simulation-electromech-ode
setup_path
run('scripts/run_tiered_gravity_analysis')
run('scripts/plot_science_fair_graphs')
```
