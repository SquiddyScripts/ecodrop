# EcoDrop Gravity Battery — MATLAB Simulation

Simulation and analysis of **four gravitational energy storage systems**: Dual Weight, Variable Counterweight, Buoyancy, and Halbach Array. Compares **discharge efficiency** (electrical out per gravitational PE), loss breakdown, net energy per cycle, and scaling to 1 kWh. Built for science-fair presentation and reproducible research.

---

## Quick start

1. Clone the repo and open MATLAB.
2. Add the MATLAB folder to your path and run the presentation pipeline (all figures + CSV):

   ```matlab
   addpath('matlab');
   addpath('matlab/systems');
   run_presentation_plots_dark
   ```

   Figures and CSVs are written to `matlab/outputs/`.

3. **Full physics run** (ODE integration, 100 runs per system, validation):

   ```matlab
   main
   ```

**Requirements:** MATLAB R2016b or later (base product). The simulation uses **`ode45`** in `matlab/physics_core.m` to integrate the descent dynamics. See [matlab/README.md](matlab/README.md) for details.

---

## Repo structure

```
gravity battery/
├── matlab/                    # Simulation (MATLAB)
│   ├── config.m               # Constants, motor specs, run protocol
│   ├── physics_core.m         # PE, friction, gearbox, motor, descent ODE (ode45)
│   ├── systems/               # One cycle per system
│   │   ├── run_cycle_dual_weight.m
│   │   ├── run_cycle_variable_cw.m
│   │   ├── run_cycle_buoyancy.m
│   │   └── run_cycle_halbach.m
│   ├── run_simulation.m       # 100 runs × 4 systems, perturbations
│   ├── metrics.m              # Summary table, ANOVA
│   ├── calibration.m          # Energy balance, ranking checks
│   ├── plotting.m             # Physics-based figures
│   ├── run_presentation_plots_dark.m   # Presentation figures (single entry)
│   ├── main.m                 # Full run: simulation → table → validation → plots
│   ├── outputs/               # CSV + PNGs
│   └── README.md              # MATLAB file list + ODE description
├── docs/                      # Documentation
│   ├── README.md              # Doc index + flow diagram
│   ├── GRAPH_EXPLANATIONS.md  # What each figure shows
│   ├── WHY_DISCHARGE_EFFICIENCY.md
│   └── PRESENTATION_SCRIPT_2MIN.md
└── README.md                  # This file
```

---

## What the simulation does

- **Physics:** Gravitational PE, rope/bearing/gearbox friction, motor–generator model. **Descent is simulated with an ODE** (`physics_core.m`: `descent_rhs` + `ode45`) so fall time and power vs. time come from the dynamics.
- **Metrics:** Discharge efficiency (E_out / PE_input), loss breakdown (rope, bearing, gearbox, motor, system-specific), net energy per cycle, ANOVA over 100 replicates.
- **Outputs:** Bar charts (efficiency, loss, net energy), energy in vs out, cumulative net over 500 cycles, sensitivity, mass/cycles to 1 kWh, energy vs height. All driven from `matlab/outputs/loss_breakdown_figures.csv` when using `run_presentation_plots_dark`.

---

## Documentation

| Doc | Description |
|-----|-------------|
| [matlab/README.md](matlab/README.md) | MATLAB file list, **where the ODE is**, how to run, outputs |
| [docs/GRAPH_EXPLANATIONS.md](docs/GRAPH_EXPLANATIONS.md) | Explanation of every figure |
| [docs/WHY_DISCHARGE_EFFICIENCY.md](docs/WHY_DISCHARGE_EFFICIENCY.md) | Why we use discharge efficiency instead of RTE |
| [docs/PRESENTATION_SCRIPT_2MIN.md](docs/PRESENTATION_SCRIPT_2MIN.md) | 2-minute script + figure order for presenting results |

---

## License

See repository license file (if present). Otherwise use for education and research with attribution.
