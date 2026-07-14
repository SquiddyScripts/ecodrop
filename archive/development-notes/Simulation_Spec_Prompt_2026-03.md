# EcoDrop Gravity Battery — Complete Simulation Prompt
## Paste this entire document into your simulation AI. Attach the system diagrams/CAD images when prompted.

---

## WHO YOU ARE AND WHAT YOU ARE BUILDING

You are a physics simulation engineer helping a science fair research team build a rigorous, publication-quality Python simulation of four gravitational energy storage systems. This simulation will be the core evidence behind a research conclusion that will be judged at a high-level science fair competition.

The goal is NOT to make impressive-looking graphs. The goal is to answer a specific research question with honest, defensible numbers.

**The research question:**
"Among four novel gravitational energy storage-regeneration system designs, which achieves the highest round-trip power efficiency — and does any approach the viability threshold set by existing commercial energy storage technologies (pumped hydro: 70–85%, lithium-ion: 85–92%)?"

Everything you build must serve that question directly.

---

## PROJECT CONTEXT — READ THIS CAREFULLY

### The problem we are solving

Renewable energy generation (solar, wind) is intermittent — it generates power when nature allows, not when humans need it. The gap between generation and demand requires energy storage. The dominant solution today is lithium-ion batteries, but they have serious problems: toxic materials, energy-intensive production, chemical degradation over hundreds of cycles, dependence on mining supply chains, and high cost/inaccessibility at small scale in developing regions.

Pumped hydro is the most efficient large-scale storage (70–85% round-trip efficiency) and is essentially a gravity battery — but it requires mountains, reservoirs, and massive civil infrastructure. It cannot be scaled down.

**The specific gap we are filling:** No viable small-scale, mechanically simple, non-chemical gravity storage system has been validated. If one can be built that achieves efficiency competitive with lithium-ion, it could provide reliable energy storage to off-grid communities, rural areas, and buildings — using only mechanical components, no toxic materials, and no chemical degradation.

### What was already built and validated

Before this simulation, the team physically built and validated a gravitational generation system:
- 9-foot wooden scaffolding frame
- 25 kg effective mass (dumbbells tied to rope)
- 8:1 mechanical advantage pulley system
- Polypropylene rope → makeshift spool → compound gearbox (1:25 ratio) → BLDC inrunner motor
- Measured with a multimeter: voltage, current recorded at multiple mass values
- A Python simulation was previously built and calibrated against these measurements

**This physical build is your calibration anchor.** The friction coefficients, motor efficiency, and gearbox efficiency values used in this new simulation must be consistent with what was observed in that physical build. We are not estimating from scratch — we are extending a validated model.

### The four new systems

These four systems all use the same validated generation mechanism (weight drop → rope → hoist drum → gearbox → motor/generator) but differ in how the weight is returned to its starting position for the next cycle. This is the critical engineering difference. Reference the attached system diagrams for each.

---

## THE FOUR SYSTEMS — MECHANICS AND RETURN MECHANISMS

### System 1: Dual Weight Regeneration System (REGENERATIVE)

**How it works:**
Two hoist drums are connected by a rod. The rope winding directions are opposite — when one unwinds (weight descending, generating electricity), the other winds (counterweight ascending). When the first weight reaches the bottom, the system reverses: the counterweight descends and generates electricity while the first weight is pulled back up.

**Key mechanical feature:** A reversible-stackable gearbox that amplifies torque (not speed) during the lifting phase. The same BLDC motor both generates electricity on descent and drives lifting on ascent.

**Return mechanism:** The descending counterweight on the opposite drum provides the return energy. The motor assists when the counterweight alone is insufficient.

**Parameters to model:**
- Mass of primary weight: 50 kg
- Mass of counterweight: adjustable (start at 40 kg — net imbalance drives generation)
- Drop height: 3 m
- Gearbox ratio discharge: 1:25 (speed amplification for generation)
- Gearbox ratio charge: 25:1 (torque amplification for lifting)
- Rope: polypropylene, pulley friction coefficient μ = 0.02 (ball bearing assisted)
- Motor/generator efficiency: derive from physical build calibration
- Energy consumed by motor during ascent phase: calculate from net mass imbalance × g × h + friction losses

**What makes this regenerative:** Both the descending weight AND the descending counterweight generate electricity. Net energy consumption per cycle = energy to lift net imbalance + all friction losses.

---

### System 2: Variable Counterweight Regeneration System (REGENERATIVE)

**How it works:**
A primary cabled mass (connected to a generator/motor) is the main generating weight. Magnetic barbell mass modules can be added to or removed from the counterweight side. Sensors measure the load and the control system deploys or retracts modular masses to keep the counterweight as close as possible to the primary weight mass — minimizing the net work the motor must do on ascent.

As modular masses descend along guide rails, small generators in each module produce electricity stored in supercapacitors. This electricity is discharged back into the building grid when the modules dock at the storage station.

**Key mechanical feature:** Dynamic mass matching. By making counterweight ≈ primary weight, the motor only needs to supply the difference (imbalance + friction). This is why it achieves the highest efficiency — it minimizes net gravitational work per cycle.

**Return mechanism:** The counterweight system plus modular mass redistribution. The primary motor handles residual imbalance only.

**Parameters to model:**
- Primary mass: 50 kg
- Counterweight mass range: 45–50 kg (variable, controlled)
- Drop height: 3 m
- Number of modular mass units: assume 5 modules of 1 kg each deployable
- Each module generator efficiency: 0.75 (supercapacitor round-trip included)
- Main generator efficiency: derive from physical build calibration
- Control system power consumption: 5W estimated (small sensors and actuators)
- Friction: same rope/bearing parameters as Dual Weight

**What makes this regenerative:** Both the primary weight descent AND the modular mass descent generate electricity. Net consumption is minimized because counterweight ≈ primary weight, so ascent requires very little motor energy.

---

### System 3: Buoyancy Gravitational Energy Storage (STORAGE)

**How it works:**
A buoyant weight is held submerged at depth. To charge (store energy): a pump moves water from the bottom tank to the top tank, which floods the chamber and uses buoyant force to lift the weight to the top. To discharge (generate electricity): water drains passively back to the bottom tank, the buoyant force is removed, and the weight descends under gravity through the generator.

**Two-layer design:** Inner layer for weight travel, outer layer for water flow, to prevent rope getting wet.

**Return mechanism:** Buoyant force (water flooding the chamber) lifts the weight. A submersible pump moves water from bottom to top tank. This pump energy is the primary cost of the cycle.

**Parameters to model:**
- Weight mass: 50 kg
- Weight volume (to achieve buoyancy): calculate from Archimedes principle — weight must be buoyant in water, so volume > 0.05 m³ (50 kg / 1000 kg/m³). Use volume = 0.06 m³ giving net buoyant force = (0.06 × 1000 - 50) × 9.81 = 98.1 N upward
- Drop height: 3 m
- Water volume to flood chamber: 0.06 m³ per cycle
- Pump efficiency: 0.70 (standard submersible pump)
- Pump energy per cycle: ρ × g × h × V / pump_efficiency (lifting 0.06 m³ of water 3 m)
- Generator efficiency: derive from physical build calibration
- Additional losses: water drag on descending weight (estimate drag force using drag equation with Cd = 0.8 for bluff body in water)

**What makes this storage (not regenerative):** The weight only generates electricity on descent. The return (ascent) is powered entirely by the pump — no electricity is generated on the way up.

---

### System 4: Electromagnetic Gravitational Energy Storage — Halbach Array (STORAGE)

**How it works:**
Four tubular linear motors (each containing a 6-phase coil and T-shaped neodymium magnets in a Halbach array configuration) are attached directly to the weight. To charge: electricity drives the linear motors to push the weight upward (no rope tension needed for lifting). To discharge: the weight descends under gravity, the linear motors act as generators, and electricity is produced. A separate hoist drum with high-stall-torque motor maintains rope tension during discharge.

**Halbach array advantage:** Concentrates magnetic flux on one side, increasing thrust force per amp of current — theoretically reducing electrical input needed for lifting.

**Return mechanism:** Linear motors acting as actuators, driven by electrical input.

**Parameters to model:**
- Weight mass: 50 kg
- Drop height: 3 m
- Number of linear motors: 4
- Linear motor efficiency (actuator mode, lifting): 0.65 (linear motors are less efficient than rotary in practice)
- Linear motor efficiency (generator mode, descending): 0.70
- Halbach array flux concentration factor: 1.4 (increases effective force by 40% vs standard array)
- Auxiliary hoist drum motor power consumption during discharge: 20W (tension maintenance)
- Control electronics power consumption: 10W
- Magnetic drag during descent (parasitic loss from eddy currents): model as additional braking force = 0.05 × weight velocity × motor constant
- Note: No rope friction for lifting phase (linear motors lift directly), but rope/drum friction applies during discharge phase

**What makes this storage (not regenerative):** Weight ascent is powered entirely by electrical input to linear motors. Descent generates electricity. Net efficiency is limited by multiple conversion steps: electrical → magnetic → mechanical (up) and mechanical → magnetic → electrical (down), plus auxiliary power.

---

## SIMULATION ARCHITECTURE

Build this as a Python simulation with the following structure:

### Required libraries
```python
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from scipy.integrate import odeint
import pandas as pd
```

### Core physics for ALL systems

Every system shares this baseline physics. Build it as a reusable function:

```
Gravitational PE input per cycle = m × g × h
where m = 50 kg, g = 9.81 m/s², h = 3.0 m
PE_input = 1471.5 J per cycle (this is your denominator for RTE)

Velocity of weight during free descent (no motor connected):
v(t) from Newton's second law: m×a = m×g - F_friction - F_rope_tension

Mechanical power at any instant:
P_mechanical = F_net × v

Electrical power output:
P_electrical = V × I = η_motor × P_mechanical

Energy generated per discharge:
E_out = ∫ P_electrical dt over discharge duration

Energy consumed per charge (lifting):
E_in_lift = work done against gravity + work done against friction
         = m_net × g × h + F_friction_total × h
```

### Friction model (apply consistently to ALL systems)

```
Rope tension loss over pulley:
T_tight / T_slack = e^(μ × θ)
where μ = 0.02 (ball bearing pulley), θ = π radians (180° wrap)
Tension efficiency per pulley = 1 / e^(0.02×π) ≈ 0.939

Bearing friction torque:
T_bearing = μ_bearing × F_radial × r_shaft
where μ_bearing = 0.001 (ball bearing), r_shaft = 0.01 m

Gearbox efficiency:
η_gear = 0.94 per stage (helical double-helix gears as built)
For 1:25 ratio (2 stages): η_gearbox = 0.94² = 0.883
```

### Motor/generator model (calibrated from physical build)

```
Use the following values calibrated from the physical prototype multimeter data:
- Motor Kv rating: [INSERT FROM YOUR MOTOR SPEC]
- Motor resistance (winding): [INSERT FROM YOUR MOTOR SPEC]  
- Motor efficiency at operating RPM: η_motor = 0.82 (from physical build calibration)
- Back-EMF constant: Ke = 1/Kv (in V·s/rad)

Electrical output per cycle:
V_out = Ke × ω_shaft
I_out = (V_out - V_back_EMF) / R_winding
P_electrical = V_out × I_out × η_motor
E_electrical = ∫ P_electrical dt
```

---

## WHAT TO SIMULATE AND MEASURE

Run each system for **10 simulation cycles** with the following parameter perturbation for statistical validity:
- Each run: perturb motor efficiency by ±2% (uniform random within range)
- Each run: perturb friction coefficient by ±5% (uniform random within range)
- Record all metrics for each run, then report mean ± standard deviation

### Metric 1: Round-Trip Efficiency (PRIMARY METRIC — most important)

```
RTE (%) = (E_electrical_out_discharge / E_input_PE) × 100
        = (V × I × t_discharge) / (m × g × h) × 100

For regenerative systems: E_electrical_out includes BOTH the main generator output 
AND any secondary generator output (modular masses, counterweight descent)

For storage systems: E_electrical_out is only from the main generator on descent
```

Report: Mean RTE ± SD for each system across 10 runs.
Benchmark lines to draw on graph: pumped hydro (77.5%, midpoint of 70–85%) and lithium-ion (88.5%, midpoint of 85–92%).

### Metric 2: Energy Loss Breakdown Per Cycle

For each system, decompose total energy loss (PE_input - E_electrical_out) into:
1. Rope/cable friction losses (J)
2. Bearing friction losses (J)  
3. Gearbox losses (J)
4. Motor/generator conversion losses (J)
5. System-specific losses:
   - Dual Weight: motor energy consumed during lifting phase (J)
   - Variable CW: control system power × cycle time (J)
   - Buoyancy: pump energy consumed per cycle (J)
   - Halbach: linear motor actuator losses + auxiliary hoist + control electronics (J)

Express each as both Joules and % of PE_input.

### Metric 3: Net Energy Per Cycle

```
Net energy per cycle (J) = E_electrical_out - E_consumed_for_return

For Dual Weight: E_consumed = motor energy to lift net mass imbalance + friction
For Variable CW: E_consumed = motor energy for residual imbalance + control power
For Buoyancy: E_consumed = pump energy to move water to top tank
For Halbach: E_consumed = linear motor electrical input for lifting + auxiliary systems
```

This is negative for all systems (you always consume more than you recover — that's physics). The system with the smallest negative value is most efficient. This directly shows which system loses the least energy per cycle.

### Metric 4: Mechanical Power Input vs. Electrical Power Output

```
P_mechanical_in = F_weight × v_weight (instantaneous, during discharge)
P_electrical_out = V × I (instantaneous, during discharge)

Plot both over time for one representative cycle of each system.
Also plot the ratio P_electrical/P_mechanical over time — this is your instantaneous conversion efficiency curve.
```

### Metric 5: Cumulative Net Energy Over 500 Cycles

```
Cumulative_net(n) = n × net_energy_per_cycle

Plot for all 4 systems on one graph, cycles 1–500.
This shows the compounding effect of per-cycle losses over time.
```

### Metric 6: Sensitivity Analysis

Run each system three times with:
- Baseline friction coefficients
- All friction coefficients +10%  
- All friction coefficients -10%

Show: Does the efficiency ranking of the four systems change? If Variable CW still wins at +10% friction, the conclusion is robust. Report this explicitly.

---

## GRAPHS TO PRODUCE

All graphs must follow these formatting rules — non-negotiable:
- **Title: 18pt bold, fully descriptive** — e.g. "Round-Trip Efficiency Comparison: All 4 Gravitational Storage Systems vs. Industry Benchmarks"  
- Axis labels: 14pt, always include units
- Legend: 12pt, clearly labeled
- Line width: 2.5 minimum
- Error bars on all bar charts (mean ± SD from 10 runs)
- White background, high contrast
- Save as PNG at 300 DPI, 10×7 inches minimum
- **Use a consistent color scheme across ALL graphs:** Dual Weight = blue, Buoyancy = orange, Halbach = green, Variable CW = purple

---

### GRAPH SET 1: Regenerative Systems Head-to-Head (Dual Weight vs. Variable CW)

**Graph 1A: Round-Trip Efficiency — Dual Weight vs. Variable CW**
- Grouped bar chart, error bars, benchmark lines for pumped hydro and lithium-ion
- Title: "Round-Trip Efficiency: Regenerative Systems Comparison"

**Graph 1B: Energy Loss Breakdown — Dual Weight vs. Variable CW**
- Stacked bar chart, one bar per system
- Stacks: rope friction | bearing friction | gearbox | motor conversion | return energy cost
- Title: "Where Energy Is Lost Per Cycle: Dual Weight vs. Variable Counterweight"

**Graph 1C: Net Energy Per Cycle — Dual Weight vs. Variable CW**
- Simple bar chart (values will be negative)
- Add a horizontal line at 0 labeled "zero loss (theoretical maximum)"
- Title: "Net Energy Recovery Per Cycle: Dual Weight vs. Variable Counterweight"

---

### GRAPH SET 2: Storage Systems Head-to-Head (Buoyancy vs. Halbach)

**Graph 2A: Round-Trip Efficiency — Buoyancy vs. Halbach**
- Same format as Graph 1A
- Title: "Round-Trip Efficiency: Storage Systems Comparison"

**Graph 2B: Energy Loss Breakdown — Buoyancy vs. Halbach**
- Same format as Graph 1B, but system-specific losses replace return energy cost:
  - Buoyancy stack includes: pump energy, water drag, rope/bearing/gearbox/motor
  - Halbach stack includes: linear motor actuator losses, magnetic drag, auxiliary power, rope/gearbox/motor
- Title: "Where Energy Is Lost Per Cycle: Buoyancy vs. Halbach Array"

---

### GRAPH SET 3: All 4 Systems — Master Comparison

**Graph 3A: Round-Trip Efficiency — All 4 Systems ⭐ HEADLINE GRAPH**
- Horizontal bar chart (makes ranking visually clearest)
- Error bars from 10-run SD
- Two vertical dashed reference lines: pumped hydro (77.5%) and lithium-ion (88.5%), both clearly labeled
- Color-coded by category: regenerative systems (blue/purple tones), storage systems (orange/green tones)
- Title: "Round-Trip Power Efficiency: All 4 Gravitational Storage Systems vs. Industry Benchmarks"

**Graph 3B: Mechanical Power Input vs. Electrical Power Output — All 4 Systems**
- Grouped bar chart, two bars per system
- Title: "Mechanical Power Input vs. Electrical Power Output Per Cycle: All 4 Systems"

**Graph 3C: Full Energy Loss Breakdown — All 4 Systems**
- Stacked bar chart, all 4 systems, consistent loss categories
- Title: "Energy Loss Breakdown Per Cycle: Where Each System Loses Power"

**Graph 3D: Cumulative Net Energy Over 500 Cycles — All 4 Systems**
- Line chart, one line per system, cycles 1–500
- Title: "Cumulative Net Energy Output Over 500 Cycles: All 4 Systems"
- Add annotation showing the gap between best and worst system at cycle 500

**Graph 3E: Sensitivity Analysis — Efficiency Under ±10% Friction Variation**
- Grouped bar chart showing efficiency at baseline, +10%, -10% friction for all 4 systems
- Title: "Efficiency Robustness: Effect of ±10% Friction Variation on All 4 Systems"

---

## DATA TABLES TO OUTPUT

For every graph, print a corresponding data table to console AND export as CSV.

**Master Summary Table (print first, before any graphs):**

| System | Category | Mean RTE (%) | SD RTE | Net Energy/Cycle (J) | SD Net | Total Loss/Cycle (J) | Rope Loss (J) | Bearing Loss (J) | Gearbox Loss (J) | Motor Loss (J) | System-Specific Loss (J) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Dual Weight | Regenerative | | | | | | | | | | |
| Variable CW | Regenerative | | | | | | | | | | |
| Buoyancy | Storage | | | | | | | | | | |
| Halbach Array | Storage | | | | | | | | | | |

**Statistical Results Table:**
Report ANOVA results: F-statistic, p-value, eta-squared for both RTE and net energy per cycle.
If p < 0.05: "System type significantly affects efficiency (p < 0.05). Differences are not due to chance."

---

## WHAT NOT TO DO

- Do NOT plot voltage vs. time or RPM vs. time for a single system — these are diagnostics, not results
- Do NOT report any metric for only one system in isolation — always compare
- Do NOT skip error bars — the 10-run perturbation is what makes this statistically valid
- Do NOT use vague titles — every title must be fully descriptive
- Do NOT hardcode efficiency as a single assumed value — derive it from the physics equations

---

## VALIDATION CHECK — RUN THIS BEFORE FINALIZING

Before producing final graphs, verify your simulation passes these sanity checks:

1. **Energy conservation:** For every system, confirm: E_electrical_out + all losses = PE_input (within 1%)
2. **Physical bounds:** RTE must be between 0% and 100% for all systems
3. **Ranking sanity:** Variable CW should rank highest (it has the lowest return energy cost due to near-balanced counterweight). Halbach should rank lowest (most conversion steps, most auxiliary power). If your simulation produces a different ranking, debug before proceeding.
4. **Calibration check:** Run the simulation with the parameters from the original physical build (25 kg mass, ~2.7 m height, 1:25 gearbox, ball bearing pulleys, BLDC motor). The simulated electrical output should match the multimeter measurements from that build within 15%. If it doesn't, adjust friction and motor efficiency parameters until it does — those calibrated values then become your input parameters for all four new systems.

---

## OUTPUT FORMAT

- Single Python script with clearly labeled sections for each system and each graph
- All graphs saved as high-res PNGs (300 DPI) in an /outputs folder
- Master summary CSV exported to /outputs/summary_table.csv
- Console output: print master data table first, then statistical results, then confirm all sanity checks passed
- Comment every major equation in the code with its physical meaning
