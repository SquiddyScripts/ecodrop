# Electromechanical System Simulation

A physics-accurate, time-domain electromechanical simulation of a gravity-driven generator system. The simulation models a falling mass driving a motor/generator through a multi-stage drivetrain (drum → sprocket → gearbox → bevel gears → motor).

## Simulation Results

### Time-Series Results
![Time-Series Results](figs/FIGURE%201%20TIMESERIESRESULTS.jpg)

### Energy Analysis
![Energy Analysis](figs/FIGURE_2%20ENERGY%20ANALYSIS.jpg)

### Gearbox Optimization Results
![Gearbox Optimization](figs/FIGURE%203%20GEARBOX%20OPTIMIZATION%20RESULTS.jpg)

## System Overview

The simulation models:
- **Falling mass** attached to a rope wrapped around a drum
- **Drum** driving a sprocket
- **Sprocket** driving a gearbox
- **Gearbox** output connecting through 1:1 bevel gears (axis redirection)
- **DC/BLDC motor** (Turnigy Aerodrive SK3-5065-236KV) operating in generator mode

## Features

- **Time-domain dynamics**: Full transient simulation, not steady-state
- **Energy flow tracking**: Gravitational → kinetic → electrical energy conversion
- **Loss modeling**: Hybrid approach (efficiency factors + detailed friction)
- **Modular design**: Each component modeled separately
- **Gearbox optimization**: Continuous parameter sweep to find optimal ratio
- **Professional-grade**: System-level simulation suitable for engineering analysis

## File Structure

```
project root/
├── setup_path.m                 % Add project to MATLAB path (run first)
├── system_parameters.m          % Parameter definition
├── main_simulation.m            % Single simulation run
├── models/                      % Component models (drum, gearbox, motor, etc.)
├── solvers/                     % ODE and dynamics (system_ode.m)
├── analysis/                    % Energy analysis, plot_results, validation
├── utils/                       % Inertia reflection, gear ratios
├── scripts/                     % Run and plot scripts
│   ├── run_example.m            % Example usage
│   ├── run_all_systems.m        % Run all gravity systems
│   ├── run_tiered_gravity_analysis.m   % Tiered comparison (tables + figures)
│   ├── plot_science_fair_graphs.m      % Six science-fair comparison graphs
│   ├── analysis_compare_systems.m     % 4-system comparison + conclusion
│   ├── plot_demo_results.m      % Demo plots + CSV export
│   ├── plot_*_results.m         % Per-system result plotters
│   ├── diagnose_issues.m
│   └── optimize_gearbox.m
├── docs/                        % Documentation and presentation notes
│   ├── WHERE_ANALYSIS_AND_TABLES_ARE.txt
│   ├── explanation_of_six_science_fair_graphs.txt
│   ├── science_fair_speech.txt
│   └── ... (other .txt guides)
├── output/                      % Generated files (tables, figures, CSV)
│   ├── tiered_analysis_tables.txt
│   ├── tiered_conclusion.txt
│   ├── analysis_conclusion.txt
│   ├── results_and_conclusion_figure.png
│   ├── graph1_*.png ... graph6_*.png
│   └── simulation_data.csv
└── images/                      % Static assets
```

## Quick Start

1. **Open the project folder in MATLAB** and set up the path:
   ```matlab
   setup_path   % or: addpath(genpath(pwd));
   ```

2. **Run example simulation**:
   ```matlab
   run('scripts/run_example')
   ```

3. **Run single simulation**:
   ```matlab
   params = system_parameters();
   results = main_simulation(params);
   analysis.plot_results(results);
   ```

4. **Gravity storage comparison and science-fair graphs** (output goes to `output/`):
   ```matlab
   run('scripts/run_tiered_gravity_analysis')   % Tier 1/2/3 analysis, tables, conclusion
   run('scripts/plot_science_fair_graphs')       % Six PNGs in output/
   run('scripts/analysis_compare_systems')       % Conclusion figure + analysis_conclusion.txt
   ```

5. **Gearbox optimization**:
   ```matlab
   params = system_parameters();
   opt_results = optimize_gearbox(params);
   plot_results([], opt_results);
   ```

## Motor Specifications

The simulation uses the **Turnigy Aerodrive SK3-5065-236KV** motor:
- Kv: 236 RPM/V
- Back-EMF constant (K_e): 0.0405 V·s/rad
- Torque constant (K_t): 0.0405 N·m/A
- Winding resistance: 0.019 Ω
- Maximum current: 60 A

## Parameter Configuration

All parameters are defined in `system_parameters.m`. Key parameters include:

- **Physical**: mass, drum radius, initial height
- **Motor**: K_e, K_t, R_winding, J_rotor
- **Losses**: stage efficiencies, friction coefficients
- **Electrical**: load type and parameters
- **Simulation**: time span, solver options, tolerances
- **Optimization**: gearbox ratio range and step size

## Outputs

The simulation provides:
- Time-series data (position, velocity, current, voltage, power)
- Energy flow analysis (gravitational, kinetic, electrical, losses)
- Efficiency metrics (per stage and overall)
- Optimization results (efficiency vs. gearbox ratio)

## Validation

The simulation includes automatic validation checks:
- Energy conservation (error < 1%)
- Unit consistency
- Physical reasonableness
- Numerical stability

## Requirements

- MATLAB R2016b or later
- Optimization Toolbox (optional, for advanced optimization)

## Notes

- All units are SI (kg, m, s, N, N·m, W, J, Ω, V, A)
- The system is kinematically constrained (one dominant rotational degree of freedom)
- Electrical dynamics can be included or treated as quasi-static
- Loss models use a hybrid approach (efficiency + friction)
