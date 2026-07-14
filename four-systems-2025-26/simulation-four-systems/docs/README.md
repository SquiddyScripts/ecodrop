# EcoDrop Gravity Battery — Documentation

Documentation for the MATLAB simulation and results.

---

## Data and control flow

How the pieces connect (config → physics → systems → runs → metrics → outputs):

```mermaid
flowchart LR
  subgraph config [config]
    Config[Constants, motor specs]
  end
  subgraph physics [physics_core]
    Friction[Rope, bearing, gearbox]
    Motor[Motor generator model]
    ODE[Descent ODE integration]
  end
  subgraph systems [systems]
    DW[Dual Weight]
    VCW[Variable CW]
    Buoy[Buoyancy]
    Halb[Halbach]
  end
  subgraph run [run_simulation]
    Runs[100 runs with perturbations]
    Sens[Parameter sensitivity]
  end
  subgraph metrics [metrics]
    Eff[Discharge efficiency]
    Loss[Loss breakdown]
    Net[Net energy]
    ANOVA[ANOVA]
  end
  subgraph out [outputs]
    Table[CSV]
    Plots[PNG graphs]
  end
  Config --> Friction
  Config --> Motor
  Friction --> ODE
  Motor --> ODE
  ODE --> DW
  ODE --> VCW
  ODE --> Buoy
  ODE --> Halb
  DW --> Runs
  VCW --> Runs
  Buoy --> Runs
  Halb --> Runs
  Runs --> Eff
  Runs --> Loss
  Runs --> Net
  Eff --> Table
  Loss --> Table
  Net --> Table
  Eff --> Plots
  Loss --> Plots
  Net --> Plots
```

*(Rendered in any Markdown viewer that supports Mermaid, e.g. GitHub or VS Code.)*

---

## Doc index

| Doc | Description |
|-----|--------------|
| [matlab/README.md](../matlab/README.md) | MATLAB file list, ODE description, how to run, outputs |
| [GRAPH_EXPLANATIONS.md](GRAPH_EXPLANATIONS.md) | What each figure shows (for presentation or reporting) |
| [WHY_DISCHARGE_EFFICIENCY.md](WHY_DISCHARGE_EFFICIENCY.md) | Why we use discharge efficiency instead of RTE |
| [PRESENTATION_SCRIPT_2MIN.md](PRESENTATION_SCRIPT_2MIN.md) | 2-minute script and figure order for presenting results |
