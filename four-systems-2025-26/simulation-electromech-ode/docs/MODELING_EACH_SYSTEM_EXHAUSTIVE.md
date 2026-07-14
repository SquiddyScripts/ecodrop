# Exhaustive detail: how each system is modeled in code

This matches `scripts/plot_*_results.m`, `scripts/analysis_compare_systems.m`, and `get_gravity_system_data` inside `scripts/run_tiered_gravity_analysis.m`.

**Critical honesty — what is NOT modeled**

- **No elevator traction machine**, **no diverter / deflector sheaves**, **no “spinners”** (grooved sheaves), **no rope elasticity**, **no slip**, **no multiple rope branches**, **no car/counterweight rope ratio other than 1:1 implied story**.
- **No 3D dynamics**, **no guide rails friction as F=μN**, **no magnetic field / CFD / buoyancy integrals**.
- Everything is **scalar lumped-parameter**: prescribed **vertical velocity** vs time, **effective masses**, **efficiencies** on mechanical→electrical conversion, **fixed auxiliary powers** (pumps, hoist hold, “station” loads), then **`trapz` / `cumtrapz`** for energy.

If you **replaced parameters with measured values from your physical build**, those edits must live in the **same numeric constants** in each script (or you centralize one `physical_build_params.m` and load it everywhere). The repo snapshot may still show older demo numbers.

---

## 1. Variable counterweight (your question)

**File:** `scripts/plot_variable_counterweight_results.m`

**Concept encoded in code (not full mechanical CAD):**

- One **cabled mass** `m_cabled` (kg).
- **Stackable modules** each `m_module` (kg); count `n_modules(t)` is a **discrete schedule**, not a physics simulation of latches or rotary carousel kinematics.
- **Cycle phases** with fixed durations: descent → dock → ascent → load modules (`T_descent`, `T_dock`, `T_ascent`, `T_load`).

**Mass vs time**

- `m_total(t) = m_cabled + n_modules(t) * m_module`.
- During descent, code forces **2 modules until normalized time τ ≥ 0.6**, then **1 module** (step change). Dock/ascent/load phases use hard-coded counts (1 or 2). This is the entire “variable counterweight” effect in the math: **different weight on the rope during different parts of the cycle**.

**Kinematics (prescribed, not F = ma integration)**

- Descent height: `h = H_max * (1 - tau^1.15)` from top to bottom.
- Descent velocity: `v = -v_dn_max * 4*tau*(1-tau)` (smooth zero at ends, peak mid-stroke). Same **family** as other systems.
- Ascent: `h = H_max * tau^1.1`, `v = v_up_max * 4*tau*(1-tau)`.
- Dock and load: position pinned; velocity zero.

**Why “elevator like” but no sheaves**

- **Mechanical power into the “main generator”** on descent is computed as:
  - `P_mech_main = m_total(descent) .* g .* (-v)`  
  i.e. **gravitational power** of the moving part you treat as generating side: \(P \approx m g |v|\) with sign convention baked into `-v` when descending.
- That is **one number per time step**, not separate tensions on multiple rope segments or wrap angles on sheaves.

**Electrical “main gen”**

- `P_main_gen = eta_main_gen * max(P_mech_main, 0)` on descent only (`eta_main_gen` default 0.74 in plot script).

**“Module generators” (release burst)**

- When the step from 2→1 modules occurs, code finds index `release_idx` and adds a **Gaussian burst**:
  - `P_module_gen = 80 * exp(-(t-t_rel)^2 / 0.4^2)` on a short index window.
- This stands in for “energy when a module decouples / secondary generator” — **not** a multibody or pulley simulation.

**Ascent motor load (“variable counterweight reduces motor work”)**

- Defines an **ideal counterweight mass** `m_ideal_cw = m_cabled + 1*m_module`.
- Net mechanical motor power approximated as:
  - `net_load = max(0, m_total(ascent)*g - m_ideal_cw*g*0.95)`  
  then `P_motor_mech = net_load .* v` on ascent, then `P_motor = P_motor_mech / eta_drive`, with a **floor** (e.g. 20 W).
- The **0.95** factor is a lumped “counterweight not perfect” fudge — **not** from rope circuit geometry.

**Supercap / dock**

- During dock, `P_supercap` is a **sinusoid + floor** (regulated discharge story). Counted as **generation** in `P_gen_total`.

**Energy accounting**

- `P_gen_total = P_main_gen + P_module_gen + P_supercap`
- `P_cons = P_motor` (motor only in this script — **not** the large `P_aux5` used in `analysis_compare_systems` for variable CW).
- Round-trip efficiency: `100 * total_generated_energy / total_consumed_energy`.

**Relevance:** Shows **why** a variable-mass / variable-counterweight *idea* can lower ascent electrical work **relative to** a fixed net mass — in code, that is literally **`net_load` smaller when masses are chosen to nearly balance**. It does **not** prove your physical carousel/sheave design without replacing every fudge with measurements.

**Important:** `analysis_compare_systems.m` uses **extra** terms for variable CW — **`P_aux5`** (large dock/load station power) — so its efficiency story **does not match** the standalone `plot_variable_counterweight_results.m` one-to-one. Tiered script aligns with the analysis copy.

---

## 2. Dual weight (“elevator-style” fixed net mass)

**File:** `scripts/plot_dual_weight_results.m`

- Two masses: cab `m_cab`, counterweight `m_cw`, **net** `m_net = m_cab - m_cw` (50 kg in default).
- **Phases:** descent time `T1`, ascent `T2`; cab height profiles + CW height profiles (opposite motion).
- **Mechanical power at drum:** `P_mech_drum = m_net * g * (-v_cab)` for both phases (sign matters).
- **Electrical:** `eta_gen * P_mech` when generating (descent), `|P_mech|/eta_drive` when motoring (ascent).
- **No second drum geometry**, **no sheave count**, **no regeneration topology** — only **net weight × velocity × efficiency**.

**Relevance:** Isolates **fixed counterweight** vs **variable** case — same comparison methodology as other scripts.

---

## 3. Buoyancy gravity battery

**File:** `scripts/plot_buoyancy_gravity_results.m`

- **Phases:** lift (long) → water management (pump/drain) → short drop (gen).
- **Lift:** fill fraction `fill_chamber = 1 - exp(-3*tau)`; height/velocity smooth curves; motor power reduced as fill increases using `buoyancy_fraction` (lumped **55%** assist).
- **Water phase:** weight at top; **pump power** is a **hand-shaped** curve (200 + 150*sin(...)) gated to part of the phase.
- **Drop:** velocity profile → `P_mech_drop = m_weight*g*(-v)` → `P_gen = eta_gen * P_mech_drop`.

**Relevance:** Captures **high auxiliary parasitic load** (pumping) vs **one-shot gravitational recovery** on drop — without solving Navier–Stokes.

---

## 4. Halbach / electromagnetic (concept name)

**File:** `scripts/plot_halbach_gravity_results.m`

- **Phases:** lift → hold → drop.
- **Lift:** thrust ~ `1.15 * m*g` variation; `P_linear = thrust * v`, divided by `eta_lift` for electrical; **constant hoist draw** (45 W lift, 40 W hold) — stands in for **rope tension maintenance**, not sheave slip.
- **Drop:** same **`m g (-v)` × eta_gen** pattern as others.
- **“6-phase current”** is a **plot proxy** (`sin` waves), not inverter simulation.

**Relevance:** Separates **linear-motor lift cost + hoist parasitics** from **drop recovery** — still lumped.

---

## 5. Statistical / tiered reruns

- **`analysis_compare_systems.m`:** Same kinematic blocks as above; adds **randomized etas** per replicate for dual/buoy/halbach/var CW; variable CW includes **`P_aux5`** dock/load terms.
- **`get_gravity_system_data`:** Same + **`friction_scale`** on consumption.

---

## 6. ODE path (`main_simulation` / `system_ode`) — separate world

- Single rotating plant: drum → train → motor → load.
- **Not** parameterized per the four narrative systems above unless **you** wire different `params` per concept.

---

## Checklist after swapping in physical-build numbers

1. Set **`m_common`, `H`, phase times, v_max, etas, aux powers** everywhere they appear.
2. Reconcile **plot script** vs **`analysis_compare_systems`** vs **`get_gravity_system_data`** (variable CW aux terms differ).
3. In write-ups, state clearly: **lumped cycle model**, **no sheave/pulley mechanical advantage matrix**, parameters **from measurement**.
