# EcoDrop Gravity Battery — MATLAB Code

This folder contains the full MATLAB simulation: shared physics (including **descent ODE**), four system models, run protocol, metrics, validation, and all figures. Use it as the single place for the “organized” MATLAB code and for public repo clarity.

---

## Does the MATLAB code have an ODE? **Yes.**

The **descent dynamics** are implemented with an ODE in **`physics_core.m`**:

- **`descent_rhs(t, y, m, g, F_friction_const, b_load, h_drop)`** — ODE right-hand side: state `y = [position; velocity]`, with acceleration `a = g - (F_friction_const + b_load*v)/m`. Integration stops when position ≥ drop height.
- **`run_descent_integration(...)`** — Calls **`ode45`** on `descent_rhs`, trims the solution to the first time the mass reaches the drop height, then computes mechanical power (F×v), gearbox and motor efficiency, and electrical power. Fall time and power vs. time come from this integration.

So **fall time and Watts are not assumed** in the physics run; they come from the ODE. The presentation power-vs-time figure uses a fixed duration for comparison only; see docs for that distinction.

---

## How to run

**From MATLAB:**

1. Set current directory to `matlab/` (or add `matlab` and `matlab/systems` to the path).
2. **Presentation figures + CSV (recommended first):**
   ```matlab
   run_presentation_plots_dark
   ```
   Generates all presentation figures (1A–3E, sensitivity, scale to 1 kWh, cycles vs height, energy vs height, ANOVA), writes `outputs/loss_breakdown_figures.csv` and `outputs/presentation_replicates.csv`, and saves PNGs to `outputs/`.

3. **Full physics run (ODE, 100 runs, validation):**
   ```matlab
   main
   ```
   Runs 100 perturbed runs per system, builds summary table, ANOVA, validation (energy balance, RTE bounds, ranking), and physics-based plots. Writes `outputs/summary_table.csv` and PNGs.

**From project root:**

```matlab
addpath('matlab');
addpath('matlab/systems');
run_presentation_plots_dark   % or: main
```

---

## Requirements

- **MATLAB R2016b or later.** Uses `ode45`, `table`, `containers.Map`, and (in `metrics.m`) either `anova1` (Statistics and Machine Learning Toolbox) or a manual one-way ANOVA if you’ve replaced it.
- No other toolboxes required for the core pipeline.

---

## File layout (all MATLAB code)

| File | Purpose |
|------|--------|
| **config.m** | Central config: g, h, masses, μ, η_gear, Kv, Rm, η_motor, system params, run protocol, plot colors. |
| **physics_core.m** | **ODE here.** PE, rope/bearing/gearbox/motor helpers; `descent_rhs` + `run_descent_integration` (ode45); friction loss formulas. |
| **systems/run_cycle_dual_weight.m** | One full cycle: Dual Weight (two drums, counterweight, reversible gearbox). |
| **systems/run_cycle_variable_cw.m** | One cycle: Variable Counterweight (modular masses, main + modular generators). |
| **systems/run_cycle_buoyancy.m** | One cycle: Buoyancy (pump charge, water drag, descent generation). |
| **systems/run_cycle_halbach.m** | One cycle: Halbach (linear motors, auxiliary hoist, descent generation). |
| **run_simulation.m** | Orchestration: `run_one`, multi-run per system, sensitivity, cumulative net; calls system run_cycle and physics_core. |
| **metrics.m** | Summary table (mean RTE, net energy, loss breakdown), ANOVA on RTE and net energy. |
| **calibration.m** | Validation: energy conservation, RTE in [0,100]%, ranking (Variable CW > Dual Weight > Buoyancy > Halbach). |
| **plotting.m** | Physics-based figures (1A–3E) from simulation output. |
| **main.m** | Entry for full run: simulation → metrics → validation → CSV + plots. |
| **run_presentation_plots_dark.m** | **Single entry for presentation:** builds presentation data (and replicates), writes `loss_breakdown_figures.csv`, generates all dark-mode figures, calls sensitivity, scale-to-1kWh, cycles/energy vs height, power profiles, ANOVA on replicates. |
| **sensitivity_motor_system.m** | Parameter sweep (motor + system loss scale); heatmap Variable CW vs Dual Weight. Reads `loss_breakdown_figures.csv`. |
| **scale_to_1kWh.m** | Mass required to deliver 1 kWh vs height. Reads `loss_breakdown_figures.csv`. |
| **cycles_to_1kWh_vs_height.m** | Cycles to 1 kWh vs drop height. Reads `loss_breakdown_figures.csv`. |
| **energy_vs_height.m** | Energy delivered per cycle vs height. Reads `loss_breakdown_figures.csv`. |
| **power_profiles.m** | Instantaneous power vs time (presentation-style, fixed duration). Reads `loss_breakdown_figures.csv`. |
| **anova_presentation_replicates.m** | ANOVA on presentation replicate CSV. Reads `presentation_replicates.csv`. |
| **plot_3b_energy_in_out_presentation.m** | Standalone 3B (energy in vs out) from presentation data. |

---

## Outputs

- **`outputs/loss_breakdown_figures.csv`** — Written by `run_presentation_plots_dark`. One row per system: PE_input_J, E_out_J, loss components, RTE_pct. Used by sensitivity, scale-to-1kWh, cycles/energy vs height, power profiles.
- **`outputs/presentation_replicates.csv`** — 100 replicates per system (RTE, net energy) for ANOVA.
- **`outputs/summary_table.csv`** — From `main`: full summary table from physics runs.
- **`outputs/*.png`** — All figures (1A–3E, sensitivity heatmap, scale to 1 kWh, cycles to 1 kWh, energy vs height, power profile, etc.). Sankey diagrams are generated by the Python script `sankey_energy_flow.py` if run from the project root.

---

## Validation (when running `main`)

1. **Energy conservation** — E_out + discharge losses ≈ PE_input (within tolerance).
2. **RTE bounds** — Discharge efficiency in [0, 100]% for every run.
3. **Ranking** — Variable CW > Dual Weight > Buoyancy > Halbach.

All three must PASS for a clean public run.
