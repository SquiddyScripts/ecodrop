# Judge-facing justification: physics, formulas, and how every part of the code maps to your systems

This document answers: **what physics equations we use**, **why each modeling choice is deliberate**, and **how each element of your board diagrams** (dual drums, variable modules and “spinners,” buoyancy tower, tubular linear motors and Halbach thrust, tension hoist) **appears in the software**—including the **ODE-based electromechanical core** and the **multi-system cycle models**.

**Vocabulary we use with judges:** A *lumped-parameter* or *zero-dimensional* model replaces thousands of internal degrees of freedom (every tooth, every drop of water, every coil turn) with a **small set of measurable or estimable quantities** (effective mass, phase time, efficiency, auxiliary power). That is standard in energy engineering: the **First Law** is enforced as **power integrated over time**; detailed field equations are used when a subsystem is the research focus. Here the focus is **comparing architectures** under the same gravitational energy budget.

---

## Part A — Your four systems on the board vs the two software layers

**Layer 1 — Physics core (ODE):** `system_parameters.m`, `main_simulation.m`, `solvers/system_ode.m`, `models/*.m`, `analysis/energy_analysis.m`, `analysis/validation_checks.m`, `utils/reflect_inertia.m`.  
This layer implements **Newton–Euler rotational dynamics** for a **single translating mass** coupled to a **motor–generator** through **fixed gear ratios**, plus **Ohmic electrical behavior** and an **electrical load**. It is the **most detailed** electromechanical path in the project. It is **not** forked into four different `.m` files; it represents **one canonical “hoist + drivetrain + electrical port” plant**. Judges should hear: *we validated the electromechanical chain with differential equations; the four concepts share the same energy accounting principles but differ in cycle topology.*

**Layer 2 — Architecture comparison (pseudotime / cycle integration):** `scripts/plot_dual_weight_results.m`, `scripts/plot_variable_counterweight_results.m`, `scripts/plot_buoyancy_gravity_results.m`, `scripts/plot_halbach_gravity_results.m`, plus `scripts/analysis_compare_systems.m` and the function `get_gravity_system_data` inside `scripts/run_tiered_gravity_analysis.m`.  
These encode **each board system’s operating sequence** (phases), **prescribed kinematics** (smooth velocity profiles so accelerations stay finite), and **lumped electrical/mechanical efficiencies** so **round-trip energy** and **efficiency** can be compared fairly.

Both layers obey the same **fundamental energy logic**: mechanical power from gravity or applied forces, times efficiency, integrated over the cycle, equals electrical energy transferred minus losses.

---

## Part B — Every formula in the ODE physics core (why it is valid)

### B.1 Parameterization (`system_parameters.m`)

All quantities are **SI**. The file is deliberate: it separates **geometry** (mass, drum radius, inertias), **loss policy** (efficiency factors and Coulomb/viscous torques per stage), **motor constants**, **electrical load**, and **solver tolerances** so measured values from your build can replace defaults without restructuring code.

**Motor constants from Kv:** For a BLDC model, back-EMF constant in V·s/rad is derived from the catalog Kv in RPM/V:

\[
K_e = \frac{60}{2\pi \cdot K_v}
\]

We set **\(K_t = K_e\)** in SI (ideal torque constant equality). That is the standard first-order model for demonstration; torque–saturation and iron loss can be added if you have curves.

### B.2 Kinematics of the drum and mass (`mass_drum_model.m`)

**Height** (rope wraps on drum, no slip assumed):

\[
h = \max\bigl(0,\; h_0 - r_{\mathrm{drum}}\,\theta\bigr)
\]

**Linear speed:**

\[
v = r_{\mathrm{drum}}\,\omega_{\mathrm{mass}}
\]

**Gravitational torque on the drum** (cable tension × lever arm, sign convention fixed so positive \(\theta\) corresponds to paying out cable and lowering mass in the chosen coordinate sense):

\[
T_{\mathrm{grav}} = m\,g\,r_{\mathrm{drum}}
\]

**Effective inertia at the drum** (point mass reflected as \(m r^2\) plus drum inertia):

\[
J_{\mathrm{eff}} = J_{\mathrm{drum}} + m\,r_{\mathrm{drum}}^2
\]

**Why this matches your dual-drum slide:** Your figure states net shaft torque scales as \((m_{\mathrm{cab}} - m_{\mathrm{cw}}) g r\). In the ODE core we use a **single equivalent mass** \(m\) on one drum; **that \(m\) is deliberately the same physical idea as “net imbalance mass”** when you calibrate the core to the prototype. The two drums opposite-wind on your board are **kinematically one constraint** if both sheaves are locked to one shaft: one degree of freedom for vertical motion. Lumping to one drum is therefore **valid for energy scaling** of the shaft.

### B.3 Gear kinematics (global constraint in `system_ode.m`)

Define the compound ratio

\[
N_{\mathrm{tot}} = N_{\mathrm{sprocket}} \cdot \Bigl(\prod_i N_{\mathrm{gear},i}\Bigr) \cdot N_{\mathrm{bevel}}
\]

**Kinematic constraint** (chosen so motor spins faster than drum when \(N_{\mathrm{tot}}>1\)):

\[
\omega_{\mathrm{motor}} = \frac{\omega_{\mathrm{mass}}}{N_{\mathrm{tot}}}
\]

This is the textbook relationship **\(\omega_{\mathrm{out}} = \omega_{\mathrm{in}}/N\)** chained through stages. It is **exactly** what your slide calls out for a reversible gearbox: torque multiplies, speed divides.

### B.4 Hybrid loss model on each mechanical stage (`sprocket_model.m`, `gearbox_model.m`, `bevel_gear_model.m`)

For each stage the code uses:

1. **Shaft power in:** \(P_{\mathrm{in}} = T_{\mathrm{in}}\,\omega_{\mathrm{in}}\).

2. **Mesh / hysteresis / generic viscous loss** as a **constant efficiency** \(\eta\) applied to power: \(P' = \eta P_{\mathrm{in}}\). For multiple gearbox stages of equal \(\eta\), the implementation compounds: \(\eta_{\mathrm{tot}} = \eta^{n_{\mathrm{stages}}}\). That matches the engineering approximation that independent loss mechanisms multiply survival of power.

3. **Coulomb + viscous friction torque** on the **input** shaft:

\[
T_{\mathrm{fric}} = T_{\mathrm{coulomb}}\,\mathrm{sign}(\omega_{\mathrm{in}}) + B_{\mathrm{viscous}}\,\omega_{\mathrm{in}}
\]

\[
P_{\mathrm{fric}} = |T_{\mathrm{fric}}\,\omega_{\mathrm{in}}|
\]

4. **Net power** after both mechanisms: \(P_{\mathrm{net}} = \max(0,\; P' - P_{\mathrm{fric}})\).

5. **Output torque** from power balance when rotating: \(T_{\mathrm{out}} = P_{\mathrm{net}} / \omega_{\mathrm{out}}\) with \(\omega_{\mathrm{out}} = \omega_{\mathrm{in}}/N\).

**Why deliberate:** Real drivetrains show **both** speed-dependent viscous loss and **roughly constant** loss per revolution (Coulomb). Separating them lets you tune from **measured friction torque** vs speed sweeps. Efficiency-only models miss stall behavior; friction-only models miss gear mesh. The hybrid is a **standard compromise** for system-level simulation.

### B.5 Reflected inertia (`utils/reflect_inertia.m` and algebra inside `system_ode.m`)

Reflecting inertia \(J\) through a speed ratio \(N\) (output speed / input speed) to the input:

\[
J_{\mathrm{reflected\ at\ input}} = \frac{J}{N^2}
\]

The ODE then sums inertias **all referred to the drum shaft** as \(J_{\mathrm{mass}} + J_{\mathrm{drum}} + \sum J_k/N_k^2\) style terms so **\(J\,\alpha = T_{\mathrm{net}}\)** is dimensionally correct. That is textbook rigid-body gearing.

### B.6 Motor and electrical port (`motor_model.m`)

**Back-EMF:**

\[
V_{\mathrm{emf}} = K_e\,\omega_{\mathrm{motor}}
\]

**Terminal voltage (generator convention with positive current leaving the machine into the defined load branch):**

\[
V_{\mathrm{terminal}} = V_{\mathrm{emf}} - I\,R
\]

**Electromagnetic torque (braking when generating):**

\[
T_{\mathrm{em}} = -K_t\,I
\]

**Electrical power at terminals:**

\[
P_{\mathrm{elec}} = V_{\mathrm{terminal}}\,I
\]

**Copper loss:**

\[
P_{\mathrm{Cu}} = I^2 R
\]

**Optional core and bearing terms** (coefficients in `system_parameters.m`; default core zero unless you set it).

Then bearing friction torque is subtracted from the electromagnetic torque so **mechanical power balance** includes spin losses. This mirrors your slide: **BLDC + \(I^2R\)** and **mechanical friction** cap recovery.

### B.7 Electrical load (`load_model.m`)

**Resistive load** (default):

\[
I = \frac{V_{\mathrm{terminal}}}{R_{\mathrm{load}}}
\]

with clamp \(I \leftarrow \min(I, I_{\max})\). That is **Ohm’s law** at the terminals. It is deliberate: it creates a **unique operating point** for \((V,I)\) together with the motor equation, representing **energy dissipation into a resistor bank or equivalent electronic load** you can measure.

**Battery** and **constant-power converter** branches implement piecewise **charging** and **\(P/V\)** current laws—deliberate extensions if you later replace the resistor with your actual charger.

### B.8 Quasi-static current solve (when `include_electrical_dynamics` is false, inside `system_ode.m`)

The code iterates **fixed-point** updates \(I \leftarrow f(V_{\mathrm{emf}}(I))\) because **algebraic coupling** exists between \(V_{\mathrm{terminal}}(I)\) and \(I(V_{\mathrm{terminal}})\). That is a **standard** way to resolve the nonlinear load without stiff inductance dynamics when \(L\) is negligible for the time scales of interest.

### B.9 Equation of motion at the drum (`system_ode.m`)

Let \(T_{\mathrm{grav}}\) be the driving torque from weight, and \(T_{\mathrm{motor,refl}}\) the **motor electromagnetic torque reflected to the drum** (magnitude scaled by \(N_{\mathrm{tot}}\) in the implementation so it opposes acceleration). Then:

\[
\alpha_{\mathrm{mass}} = \frac{T_{\mathrm{grav}} - T_{\mathrm{motor,refl}}}{J_{\mathrm{total,eff}}}
\]

\[
\dot\theta = \omega_{\mathrm{mass}},\qquad \dot\omega_{\mathrm{mass}} = \alpha_{\mathrm{mass}},\qquad \dot\omega_{\mathrm{motor}} = \alpha_{\mathrm{mass}}/N_{\mathrm{tot}}
\]

**Why valid:** This is **one rotational DOF** with **algebraic coupling** to electrical power. It is exactly the level of model used in **early-stage motor–gear–load matching** before adding elasticity, backlash, or multi-body rope dynamics.

### B.10 Optional electrical state (`include_electrical_dynamics` true)

If inductance \(L>0\), the code uses a simplified \(\mathrm{d}I/\mathrm{d}t\) from \(L\,\mathrm{d}I/\mathrm{d}t = V_{\mathrm{emf}} - V_{\mathrm{terminal}} - IR\) structure. Default **false** is deliberate: your fair question is **energy**, and \(L\) often negligible for slow hoist transients.

### B.11 Event stopping (`main_simulation.m`, local function `mass_reached_bottom`)

Stops when \(h\) crosses zero downward. That enforces **finite travel** like a real hoistway.

### B.12 Post-integration energy accounting (`main_simulation.m`)

Cumulative electrical and loss energies use **trapezoidal integration** of instantaneous powers:

\[
E(t_n) \approx E(t_{n-1}) + \tfrac{1}{2}\bigl(P(t_n)+P(t_{n-1})\bigr)\,(t_n-t_{n-1})
\]

**Why:** Trapezoidal rule is **second-order accurate** for smooth power curves—appropriate when `ode45` already adapted time steps.

### B.13 Instantaneous energy breakdown (`energy_analysis.m`)

- **Gravitational potential:** \(E_g = m g h\).
- **Kinetic:** drum uses \(J_{\mathrm{eff}}\omega^2/2\); motor rotor uses \(J_{\mathrm{rotor}}\omega_{\mathrm{motor}}^2/2\).
- **Mechanical power at drum:** \(P_{\mathrm{mech,drum}} = T_{\mathrm{grav}}\,\omega_{\mathrm{mass}}\).
- **Stage efficiencies** computed as ratios of **power out / power in** along the loss chain so you can report **where** energy is lost—deliberate for **Sankey-style** explanations to judges.

### B.14 Conservation and sanity checks (`validation_checks.m`)

Compares initial \(m g h_0\) to final sum of **electrical energy delivered**, **integrated losses**, and **remaining kinetic** (linear mass + reflected rotations). Uses **\(v_{\max}\)** vs free-fall speed \(\sqrt{2gh}\) as a plausibility bound. **Why:** proves the ODE integration is **self-consistent** with the First Law within numerical tolerance.

---

## Part C — Dual Weight Regeneration (board → `plot_dual_weight_results.m`)

**Board physics emphasized:** coupled cab and counterweight, opposite winding, net imbalance drives shaft, bi-directional regeneration, motor+gearbox losses.

**Model mapping:**

1. **Opposite motion and one DOF:** We plot **both** \(h_{\mathrm{cab}}\) and \(h_{\mathrm{cw}}\) moving in opposite directions with smooth profiles so judges see the **coupled motion**. The **power** channel uses **only** the **net imbalance mass** \(m_{\mathrm{net}} = m_{\mathrm{cab}} - m_{\mathrm{cw}}\) because **potential energy release rate** of the shaft depends on **net weight** when both sides move symmetrically in height.

2. **Mechanical power to/from the shaft** (equivalent to your \(\tau_{\mathrm{net}}\omega\) with \(\tau_{\mathrm{net}} \sim m_{\mathrm{net}} g r\) and \(v=\dot h\)):

\[
P_{\mathrm{mech}} = m_{\mathrm{net}}\,g\,(-v_{\mathrm{cab}})
\]

Sign convention: descent of the heavier side yields **positive** \(P_{\mathrm{mech}}\) into the machine (generation window).

3. **Bi-directional regeneration narrative:** When \(P_{\mathrm{mech}}>0\), electrical power is **\(\eta_{\mathrm{gen}} P_{\mathrm{mech}}\)**. When \(P_{\mathrm{mech}}<0\) (ascent), electrical draw is **\(|P_{\mathrm{mech}}|/\eta_{\mathrm{drive}}\)**. That pair is the **deliberate** representation of **reversible electromechanics**: the same transducer path has **different efficiency** in motoring vs generating because **conduction, mapping, and iron** losses partition differently—here captured by two scalar efficiencies you can replace with **measured split-cycle efficiencies** from the bench.

4. **Cumulative energies:**

\[
E_{\mathrm{gen}} = \int \max(P_{\mathrm{elec}},0)\,\mathrm{d}t,\qquad
E_{\mathrm{cons}} = \int \max(-P_{\mathrm{elec}},0)\,\mathrm{d}t
\]

5. **Motor current plot:** uses a **smooth bounded proxy** vs time for visualization only; it is **not** the ODE’s \(I\) unless you run the core. Deliberate: judges see **shape correlation** with power phases without requiring full motor–drive identification in the fair script.

**Every remaining line** in that file sets **figure colors**, **axis labels**, **legends**, **summary `uitable`**, and **resets graphics defaults**—presentation, not physics. Those choices exist so **results are readable on a poster** (high contrast, consistent fonts).

---

## Part D — Variable Counterweight (board → `plot_variable_counterweight_results.m`)

**Board physics emphasized:** cabled base mass, stackable modules, mass release, **module-internal regeneration** (rollers/motors as generators), **supercapacitor storage**, **dock discharge**, rotary charging at top, **reduced main motor work** when counterweight matches load.

**How regeneration with a changing counterweight is modeled (step by step, tied to outputs):**

1. **State schedule \(n_{\mathrm{modules}}(t)\)** is **discrete** (2 → 1 during descent, 1 during dock/ascent, 1→2 during load). That is the **control-level** model of “we changed how much mass hangs on the rope.” It is deliberate: your mechanism is **digital** (modules latch or release), not continuous density of rope.

2. **Total moving mass:**

\[
m_{\mathrm{tot}}(t) = m_{\mathrm{cabled}} + n_{\mathrm{modules}}(t)\,m_{\mathrm{module}}
\]

When \(n\) drops, **\(m_{\mathrm{tot}}\)** drops **before** the end of descent in the script’s timing. That directly changes the **main descent mechanical power**:

\[
P_{\mathrm{mech,main}}(t) = m_{\mathrm{tot}}(t)\,g\,(-v(t))\quad\text{on descent}
\]

and therefore changes **main generator electrical power**:

\[
P_{\mathrm{main,elec}} = \eta_{\mathrm{main,gen}}\,\max(P_{\mathrm{mech,main}},0)
\]

**So yes: the code “sees” the counterweight mass change and changes the output power”** through **\(m_{\mathrm{tot}}(t)\)** in the product **\(mgv\)**. That is exactly the **First Law** statement judges expect: **less weight descending ⇒ less gravitational power available ⇒ less electrical power unless velocity increases** (here velocity profile is fixed smooth shape, so power drops).

3. **Secondary regeneration path (“spinners” / module motors):** Your board describes **local generation** as modules interact with rails. In code this is **not** four separate ODEs for roller angular velocity. It is deliberately abstracted as a **short Gaussian power burst** \(P_{\mathrm{module}}(t)\) centered at the **release index** when \(n_{\mathrm{modules}}\) steps from 2 to 1. **Why valid as a modeling choice:** the **energy** of that event is \(\int P_{\mathrm{module}}\,\mathrm{d}t\); for judging you only need to show **order-of-magnitude** and **phase placement** correct relative to release, unless you have waveform captures. The **exact** shape belongs in a **future** submodule with \(\sum \tau_{\mathrm{roller},i}\omega_i\) and efficiency per roller.

4. **Supercapacitor path at dock:** Your board describes **store locally, discharge at checkpoint**. The script uses **\(P_{\mathrm{supercap}}(t)\)** during the dock phase as a **regulated positive power** (sinusoid + floor) added into **generation**. Deliberate: supercaps act as a **time-shifted energy buffer**; for cycle accounting, what matters is **when energy re-enters the bus**, not the internal \(v_C(t)\) unless ripple limits performance. A **next refinement** is an RC branch with efficiency on charge/discharge; the current form is the **minimum** buffer story.

5. **Ascent motor reduction (variable counterweight benefit):** Define an **ideal counterweight** mass \(m_{\mathrm{ideal,CW}} = m_{\mathrm{cabled}} + 1\cdot m_{\mathrm{module}}\). Net force magnitude approximated as:

\[
F_{\mathrm{net}} = \max\bigl(0,\; m_{\mathrm{tot,asc}} g - \lambda\,m_{\mathrm{ideal,CW}} g\bigr)
\]

with \(\lambda\) a deliberate **balance imperfection** (script uses 0.95). **Mechanical motor power** \(F_{\mathrm{net}}\cdot v\) then **divided by \(\eta_{\mathrm{drive}}\)** for electrical draw, with a **floor power** so the model never pretends zero loss at zero net load. **Why this matches your slide:** when the counterweight side **matches** the cab side, **net rope tension work** approaches zero; the motor only supplies **losses and imbalance**—exactly the design intent you drew.

6. **Round-trip efficiency in the plot script:**

\[
\eta_{\mathrm{RT}} = 100\%\times \frac{\int (P_{\mathrm{main}}+P_{\mathrm{module}}+P_{\mathrm{supercap}})\,\mathrm{d}t}{\int P_{\mathrm{motor}}\,\mathrm{d}t}
\]

**Note for internal consistency:** `analysis_compare_systems.m` adds **large auxiliary dock/load electrical terms** in the denominator for variable CW when computing comparative statistics. That is a **deliberate second scenario** (“station services”)—not identical to the standalone plot script’s denominator. If you tell judges one number, **run the script that matches that figure** and say which one.

**All remaining lines** in the variable-counterweight script are **graphics**, **tables**, and **default resets**—same rationale as dual-weight plots.

---

## Part E — Buoyancy Gravitational Storage (board → `plot_buoyancy_gravity_results.m`)

**Board physics emphasized:** buoyant lift, motor maintains rope tension, pumping to reset tanks, drop for generation, two-layer water path.

**Model mapping:**

1. **Lift phase:** height rises with a smooth profile; velocity uses a **symmetric bell** in normalized time. **Motor electrical power** is shaped so that as **chamber fill** increases, **effective buoyancy support** reduces required motor power via a **fill state** \(f(t)\in[0,1]\) and a **buoyancy_fraction** multiplier. This is a **lumped** representation of **\(F_{\mathrm{net}} = F_b - mg - \dots\)** without solving **\(\rho g V_{\mathrm{disp}}\)** explicitly—deliberate when you **have not** measured displaced volume vs time. When you **do** have measurements, you replace \(f(t)\) and **buoyancy_fraction** with **identified** functions from data.

2. **Water management phase:** **pump power** is a **positive electrical load** with a gated time window. That stands in for **\(\Delta E_{\mathrm{pump}} \approx \rho g Q H \cdot (1/\eta_{\mathrm{pump}})\)** lumped across the phase: the **physics principle** is **moving fluid against gravity costs energy**; the **exact curve** is a stand-in until you log **power vs time** from your pump motor driver.

3. **Drop phase:** **generator electrical power**:

\[
P_{\mathrm{gen}} = \eta_{\mathrm{gen}}\,m\,g\,(-v)\quad (>0)
\]

Same **\(mgv\)** core as other systems—because **once the weight falls**, storage is **gravitational** regardless of how it was lifted.

**Remaining lines:** plotting, tables, defaults.

---

## Part F — Electromagnetic / Halbach / TLM + tension hoist (board → `plot_halbach_gravity_results.m`)

**Board physics emphasized:** tubular linear motors, Halbach flux concentration, 6-phase drive, **separate hoist** for rope tension, lift then hold then drop.

**Model mapping:**

1. **Lift electrical power to linear motors:** **Mechanical** thrust power \(P_{\mathrm{lin,mech}} = F_{\mathrm{thrust}}\,v\) with \(F_{\mathrm{thrust}}\) taken as **order \(1.15\,mg\)** with mild variation—deliberate: linear motors must supply **weight plus acceleration**; 1.15 is a **safety/acceleration margin** you can replace with **measured thrust / weight** from a load cell.

2. **Electrical lift power:** \(P_{\mathrm{lin,elec}} = P_{\mathrm{lin,mech}}/\eta_{\mathrm{lift}}\). That is the standard **motor input power** relation when **mechanical output** is known.

3. **Hoist tension maintenance:** **constant electrical draw** during lift and hold. This is the **direct** implementation of your slide’s **“high stall torque motor keeps tension”**: it is modeled as **parasitic electrical power** independent of detailed slip, because the **fair-level** question is **how much energy the tension servo burns per cycle**.

4. **Drop regeneration:** again \(P_{\mathrm{gen}} = \eta_{\mathrm{gen}}\,mg(-v)\).

5. **“6-phase current” plot:** sinusoidal proxy for visualization—**not** a dq0 Park transform. Deliberate: shows **AC ripple** qualitatively without needing **inverter switching model**.

**Remaining lines:** plotting, tables, defaults.

---

## Part G — Statistical replication (`analysis_compare_systems.m`, `get_gravity_system_data`)

**Formulas:** same power constructions as Parts C–F, then for replicate \(r\):

- Efficiencies \(\eta\) drawn from **bounded normal** perturbations (reproducible RNG seed in analysis script). **Why deliberate:** represents **manufacturing tolerance, temperature, lubrication**, without claiming false precision. Judges hear: **Monte Carlo / uncertainty band**, not fake repeated experiments.

- Trapezoidal integration over the same time bases.

**Tiered script** adds **`friction_scale`** multipliers on consumption energies—deliberate sensitivity on **parasitic side** only.

---

## Part H — Path configuration (`setup_path.m`)

Adds project folders to MATLAB path. **Why:** reproducible runs on any machine for judges who clone the repo.

---

## Part I — What “theoretically complete” means in this project (honest, judge-safe)

**Theoretically complete for the fair’s purpose** means:

1. **First Law** accounting everywhere: \(\int P\,\mathrm{d}t\) splits into **useful electrical**, **loss**, and **residual kinetic** (ODE path).

2. **Each architecture’s distinct physics story** appears as **distinct terms**: net mass (dual), fluid/pump parasitics (buoyancy), thrust+hoist parasitics (TLM), variable mass schedule + secondary burst + buffer discharge (variable CW).

3. **The ODE core** proves you can couple **\(J\ddot\theta\)** to **motor electrical equations** and a **load**.

**Theoretically complete in the PhD sense** would add: multi-body rope elasticity, sheave wrap friction, magnetic FEA, buoyancy PDE, supercap RC–DC–DC, and inverter switching—**each** a thesis. The **deliberate** fair choice is **lumped** models **traceable to your diagrams** and **upgradable** as you paste in **measured parameters**.

---

## Part J — Checklist: after you substitute physical-build measurements

Replace constants in **both** Layer 1 (`system_parameters.m`) **and** Layer 2 (all `plot_*` scripts **and** `analysis_compare_systems.m` / `get_gravity_system_data`) so every figure cites the **same** measured mass, height, times, efficiencies, pump power, hoist power, module burst energy, and dock auxiliary policy you choose to disclose.

---

## Index of files this document exhaustively covers

| File | Role |
|------|------|
| `system_parameters.m` | All SI inputs for ODE core |
| `main_simulation.m` | ODE driver, trapezoidal energy, results struct, event |
| `solvers/system_ode.m` | RHS, kinematic constraint, torque balance, optional dI/dt |
| `models/mass_drum_model.m` | \(h,v,T_{\mathrm{grav}},J_{\mathrm{eff}}\) |
| `models/sprocket_model.m` | Power-based loss stage |
| `models/gearbox_model.m` | Multi-stage \(\eta^n\), inertia reflection |
| `models/bevel_gear_model.m` | 1:1 redirect losses |
| `models/motor_model.m` | \(V_{\mathrm{emf}}\), \(V_t\), \(T\), \(P\), \(I^2R\) |
| `models/load_model.m` | Ohm / battery / constant-power load |
| `utils/reflect_inertia.m` | \(J/N^2\) |
| `analysis/energy_analysis.m` | Stage efficiencies from powers |
| `analysis/validation_checks.m` | Energy balance, plausibility |
| `scripts/plot_dual_weight_results.m` | Dual-weight cycle |
| `scripts/plot_variable_counterweight_results.m` | Variable CW cycle |
| `scripts/plot_buoyancy_gravity_results.m` | Buoyancy cycle |
| `scripts/plot_halbach_gravity_results.m` | TLM + hoist + drop cycle |
| `scripts/analysis_compare_systems.m` | Replicates + ANOVA-style comparison |
| `scripts/run_tiered_gravity_analysis.m` (`get_gravity_system_data`) | Tiered tables + friction scaling |
| `setup_path.m` | MATLAB path |

Supporting presentation scripts (`plot_figure7_figure8_presentation.m`, `plot_figure4_cycles_vs_height.m`, etc.) use **fixed summary numbers** for boards—not dynamic simulation exports—unless you wire them to CSV outputs.

---

*End of document.*
