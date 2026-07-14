# EcoDrop Gravity Battery — MATLAB Simulation

MATLAB port of the EcoDrop gravity battery simulation. It compares four gravitational storage systems (Dual Weight, Variable CW, Buoyancy, Halbach Array) with 10 perturbed runs per system, sensitivity analysis, and publication-style figures.

## How to run

1. Open MATLAB and set the current folder to this `matlab/` directory (or add it and `matlab/systems` to the path).
2. Run the main script:
   ```matlab
   main
   ```
   Or from the project root:
   ```matlab
   addpath('matlab');
   addpath('matlab/systems');
   main
   ```

The script runs the full pipeline: 10 runs per system (η_motor ±2%, friction ±5%), sensitivity (±10% friction), summary table, ANOVA, validation, and all 10 plots.

## Requirements

- **MATLAB R2016b or later** (for `ode45`, `table`, `anova1`, `containers.Map`).
- No extra toolboxes required if you have the base product and **Statistics and Machine Learning Toolbox** (for `anova1`). If `anova1` is missing, you can replace it with a manual one-way ANOVA implementation.

## Outputs

- **`outputs/summary_table.csv`** — Master summary: System, Category, Mean RTE (%), SD RTE, Net Energy/Cycle (J), loss breakdown, etc.
- **`outputs/*.png`** — Ten figures at 300 DPI:
  - 1A: RTE Regenerative (Dual vs Variable)
  - 1B: Loss breakdown Regenerative
  - 1C: Net energy Regenerative
  - 2A: RTE Storage (Buoyancy vs Halbach)
  - 2B: Loss breakdown Storage
  - 3A: RTE all four (headline)
  - 3B: Mechanical vs electrical power
  - 3C: Full loss breakdown all four
  - 3D: Cumulative net energy over 500 cycles (kJ)
  - 3E: Sensitivity ±10% friction

Console output includes the summary table, ANOVA (F, p, eta²), and validation PASS/FAIL.

## Sanity checks

The script runs three checks and reports PASS or FAIL:

1. **Energy conservation** — For each run, discharge balance is checked:  
   `PE_input ≈ E_electrical_out + (rope + bearing + gearbox + motor) losses`  
   within 5% tolerance.

2. **RTE bounds** — Round-trip efficiency is in [0, 100]% for every run.

3. **Ranking** — Systems are ordered by mean RTE (descending). The expected order is:  
   **Variable CW > Dual Weight > Buoyancy > Halbach Array**.

Re-run `main` and confirm all three show PASS. If any fail, check config constants and physics (e.g. `config.m`, `physics_core.m`).

## File layout

- `config.m` — Physical constants, run protocol, plot style.
- `physics_core.m` — PE, rope/bearing/gearbox/motor helpers, descent ODE integration, friction losses.
- `systems/run_cycle_dual_weight.m`, `run_cycle_variable_cw.m`, `run_cycle_buoyancy.m`, `run_cycle_halbach.m` — One cycle per system.
- `run_simulation.m` — `run_one`, `run_ten_per_system`, `run_sensitivity`, `run_cumulative_net`, `run_all`.
- `metrics.m` — `build_summary_table`, `anova_rte_and_net`.
- `calibration.m` — Energy balance, RTE bounds, ranking, `run_all_validation`.
- `plotting.m` — All 10 plot functions and `plot_all`.
- `main.m` — Entry point: run all, print table, ANOVA, validation, export CSV, generate figures.
