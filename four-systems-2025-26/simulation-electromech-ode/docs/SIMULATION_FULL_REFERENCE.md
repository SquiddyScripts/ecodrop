# Simulation full reference: physics, ODE, and the four systems

This document explains **what is actually simulated in code**, how pieces connect, and where the four project concepts (Dual Weight, Buoyancy, Halbach / electromagnetic, Variable Counterweight) live.

---

## 1. Two separate simulation tracks (important)

| Track | Purpose | Entry points | Uses four system names? |
|--------|---------|--------------|-------------------------|
| **A. Rotating-drum electromechanical ODE** | Detailed **single** hoist path: mass on drum → sprocket → gearbox → bevel → motor → electrical load. | `main_simulation.m` → `solvers/system_ode.m` + `models/*.m` | **No.** One generic plant; `system_parameters.m` does not branch by concept. |
| **B. Four-system “scenario” models** | Compare **your four architectures** using **prescribed motion** (velocity profiles), **lumped efficiencies**, and **numerical integration** (`trapz` / `cumtrapz`) of power vs time. | `scripts/plot_*_results.m`, `scripts/analysis_compare_systems.m`, `scripts/run_tiered_gravity_analysis.m` (helper `get_gravity_system_data`) | **Yes.** Each script encodes its own phases and aux loads. |

The **Turnigy SK3-5065-236KV** motor parameters in `system_parameters.m` apply only to **Track A** (`main_simulation`). The four-system comparison does **not** run that ODE for each concept.

---

## 2. Track A — ODE model (detailed)

### 2.1 State vector

Defined in `solvers/system_ode.m`:

| Index | Symbol | Meaning |
|-------|--------|---------|
| 1 | `theta_mass` | Drum angle [rad] |
| 2 | `omega_mass` | Drum angular velocity [rad/s] |
| 3 | `omega_motor` | Motor shaft speed [rad/s] (also tied kinematically to drum) |
| 4 | `I_motor` | Motor current [A] — **only if** `params.simulation.include_electrical_dynamics == true` (default is **false**) |

With electrical dynamics off, current is found by **fixed-point iteration**: back-EMF → terminal voltage → `load_model` → update torque (`system_ode.m`).

### 2.2 Core physics

1. **Mass and drum** (`models/mass_drum_model.m`):  
   - Height \(h = h_0 - r_{\mathrm{drum}}\theta\).  
   - Constant gravitational torque on drum: \(T_{\mathrm{grav}} = m g r_{\mathrm{drum}}\).  
   - Effective inertia at drum: \(J_{\mathrm{eff}} = J_{\mathrm{drum}} + m r_{\mathrm{drum}}^2\).

2. **Kinematic chain**:  
   \(\omega_{\mathrm{motor}} = \omega_{\mathrm{mass}} / N_{\mathrm{total}}\) with  
   \(N_{\mathrm{total}} = N_{\mathrm{sprocket}} \cdot (\prod \text{gearbox ratios}) \cdot N_{\mathrm{bevel}}\).

3. **Torque path** (each returns loss power):  
   `sprocket_model` → `gearbox_model` → `bevel_gear_model` → `motor_model` → optional `load_model` refinement.

4. **Equation of motion at drum**:  
   \(J_{\mathrm{total,eff}} \, \alpha_{\mathrm{mass}} = T_{\mathrm{grav}} - T_{\mathrm{motor,reflected}}\)  
   where reflected motor torque uses gear ratios (see `system_ode.m`).

5. **Losses**: Mix of **stage efficiencies** (e.g. drum, sprocket, gearbox, bevel) and **Coulomb + viscous** friction in `system_parameters.m` → consumed inside each component model.

6. **Motor**: Back-EMF \(V_{\mathrm{emf}} = K_e \omega_{\mathrm{motor}}\), winding resistance, torque \(T \propto I\) (`models/motor_model.m`).

7. **Electrical load**: Default **`load_type = 'resistive'`** with `R_load` (`system_parameters.m`).

8. **Stop condition**: Event in `main_simulation.m` — simulation can terminate when \(h = 0\) (`mass_reached_bottom`).

### 2.3 Post-processing

- `main_simulation.m` calls `energy_analysis` each step for powers and energies.
- `analysis/validation_checks.m` runs on the `results` structure.

### 2.4 What calls Track A

Examples: `scripts/diagnose_issues.m`, `scripts/optimize_gearbox.m`.  
`analysis/plot_results.m` is written to consume `main_simulation` output (see its header comments).

---

## 3. Track B — Four systems (how each is modeled)

**Common comparison assumptions** (see `INPUT_PARAMETERS_WHAT_YOU_GAVE_VS_CODE.md`):

- Often **50 kg** effective storage mass, **3 m** height, **g = 9.81 m/s²**.
- Each system is a **scripted cycle**: times and velocity shapes are **explicit formulas**, not produced by the ODE.

Below: **intent** + **where to read the exact numbers**.

### 3.1 Dual Weight (`scripts/plot_dual_weight_results.m`)

- **Idea**: Elevator-style cab + counterweight; net imbalance drives regeneration on descent and motor load on ascent.
- **Mechanics**: \(P_{\mathrm{mech}} = m_{\mathrm{net}} g (-v_{\mathrm{cab}})\) with smooth velocity curves (e.g. \(4\tau(1-\tau)\) style) over descent/ascent phases.
- **Electrical**: `eta_gen` on generation, `eta_drive` on consumption (fixed nominal values in script; perturbed in `analysis_compare_systems` / `get_gravity_system_data`).

### 3.2 Buoyancy (`scripts/plot_buoyancy_gravity_results.m`)

- **Idea**: Longer cycle with **lift**, **water / pumping**, and **drop** phases.
- **Mechanics**: Piecewise velocity `v3`; drop phase drives \(P_{\mathrm{gen}} \propto mg(-v)\) on discharge.
- **Auxiliary**: Motor power during lift (`P_motor3`), pump power during water phase (`P_pump3`) — **hand-defined curves**, not fluid dynamics PDEs.

### 3.3 Halbach / electromagnetic (`scripts/plot_halbach_gravity_results.m`)

- **Idea**: Linear motor lift segment + hoist power + drop regeneration.
- **Mechanics**: Lift uses \(F \approx 1.15\, m g\) against velocity; separate **hoist** power; drop uses gravity work × regeneration efficiency.
- **Note**: “Halbach” here is **conceptual** (high-level forces/powers), not a finite-element magnetic field solve.

### 3.4 Variable Counterweight (`scripts/plot_variable_counterweight_results.m`)

- **Idea**: Mass on cab changes (modules); counterweight matching; docking/load phases.
- **Mechanics**: Time-varying total mass `m_tot5`; descent and ascent velocities; optional bursts (e.g. module handling power); **auxiliary** dock/load powers to represent station energy.

### 3.5 Statistics / ANOVA (`scripts/analysis_compare_systems.m`)

- Repeats the **same algebraic structure** as the plot scripts for **10 replicates**.
- Perturbs efficiency-like scalars with `randn` (bounded) to simulate run-to-run variation — **not** sensor noise on measured hardware.

### 3.6 Tiered tables + figures (`scripts/run_tiered_gravity_analysis.m`)

- Uses local function **`get_gravity_system_data`**: same dual/buoyancy/halbach/variable math as above, plus **`friction_scale`** per system per replicate on **consumption** side.
- **Loss breakdown** (rope / bearing / gear / motor) is **allocated by fixed fractions** `loss_frac` — a display split of total loss, not separate physical sub-models.

---

## 4. File map (quick)

| File / folder | Role |
|---------------|------|
| `system_parameters.m` | All SI parameters for Track A. |
| `main_simulation.m` | ODE setup, integration, energy integration, results struct. |
| `solvers/system_ode.m` | RHS: torques, inertias, \(\dot\omega\), optional \(\dot I\). |
| `models/mass_drum_model.m` | \(h\), \(T_{\mathrm{grav}}\), \(J_{\mathrm{eff}}\). |
| `models/sprocket_model.m`, `gearbox_model.m`, `bevel_gear_model.m` | Shaft torques, speeds, loss power. |
| `models/motor_model.m` | EM torque, voltages, electrical power, copper-like losses. |
| `models/load_model.m` | Current vs terminal voltage for resistive / other load types. |
| `analysis/energy_analysis.m` | Instantaneous powers and staging for Track A. |
| `analysis/validation_checks.m` | Checks on `results`. |
| `scripts/plot_*_results.m` | Track B time-series + energy plots per system. |
| `scripts/analysis_compare_systems.m` | Four-system metrics + ANOVA-style breakdown + figures. |
| `scripts/run_tiered_gravity_analysis.m` | Tier charts + `output/tiered_*.txt` tables. |
| `docs/INPUT_PARAMETERS_WHAT_YOU_GAVE_VS_CODE.md` | Which numbers are “yours” vs code defaults. |

---

## 5. Honest scope statement

- **Track A** is a **coherent 1-DOF electromechanical simulation** suitable for gearbox/motor/load studies.
- **Track B** is a **structured comparison** of four architectures using **documented assumptions** (phase timings, efficiency lumps, auxiliary powers). It is **not** claiming that every equation was fitted to your physical prototype unless you later replace parameters with measured data.

For judge/teacher Q&A, say: *the ODE validates the electromechanical chain in principle; the four-system study uses the same high-level energy accounting (power × time) with architecture-specific phases and losses encoded in the scripts listed above.*
