# Input Parameters: What You Gave vs What’s in the Code

**Purpose:** So you can rebuild a simulation using only **real inputs you actually gave**.  
Nothing below is assumed to be “from you” unless you remember providing it.

---

## 1. What you said you have (your words)

You said you have (or think you have):

- **Which motors** (specific motor(s))
- **Diagrams of the system**
- **Short explanations**

**In this repo:**

- **Motors:** The only named motor in the code is **Turnigy Aerodrive SK3-5065-236KV** in `system_parameters.m` (used by `main_simulation.m`). There is no note in the repo that *you* provided this; it may have been chosen for the drum+motor demo.
- **Diagrams:** No diagram/sketch/image files (e.g. system layout, motor wiring) were found. README references `figs/FIGURE 1 TIMESERIESRESULTS.jpg` etc.; those paths don’t exist in the repo. If you have diagrams, they may be in another folder or only in chat.
- **Short explanations:** The `docs/` folder has many .txt files (speech, presentation, Q&A). Those were written to explain the project; they are not tagged as “direct quotes from you,” so treat them as “possibly based on what you said” unless you recognize your own wording.

**Action for you:** Check your own files and chat history for: (1) any motor datasheet or model name you actually sent, (2) any diagram/image you uploaded, (3) any short explanation you wrote. Add those to a folder (e.g. `my_inputs/`) and list them in one place so your new simulation uses only those.

---

## 2. Things that are clearly “from you” (project concept)

These are the only items that clearly reflect **your** project choices (names/concepts you used or agreed on):

| Item | What |
|------|------|
| **System names / concepts** | (1) **Dual Weight** (regenerative), (2) **Variable Counterweight** (regenerative), (3) **Buoyancy** (gravitational storage), (4) **Halbach Array / Electromagnetic** (storage). You also asked to compare “regen vs regen” and “storage vs storage” and then all four. |
| **“Electromagnetic” vs “Halbach”** | You said the system is “electromagnetic” and that Halbach arrays are a **component** of it, not the full system name. So “Halbach Array” in the code is one implementation of the electromagnetic system. |

Everything else in the next section is **in the code but not confirmed as something you explicitly said** (no direct quote from you in the repo).

---

## 3. Every concrete input currently in the code (not confirmed as your input)

Treat these as **candidate** inputs. For a “real” simulation, only keep values you actually provided (datasheets, your numbers, your diagrams). The rest were chosen to make the comparison and demos run.

### 3.1 Test conditions (four-system comparison scripts)

Used in `scripts/run_tiered_gravity_analysis.m`, `scripts/plot_science_fair_graphs.m`, `scripts/analysis_compare_systems.m`:

| Parameter | Value in code | Where | Confirmed by you? |
|-----------|----------------|-------|--------------------|
| Effective storage mass | **50 kg** | `m_common = 50` | ? (you fill) |
| Drop height | **3 m** | `H = 3` | ? (you fill) |
| Gravitational acceleration | 9.81 m/s² | `g = 9.81` | ? (you fill) |

### 3.2 Phase durations and motion (four systems)

All of these are **in code only**; none are tagged as “user provided.”

**Dual Weight**

- Descent duration: 2.8 s  
- Ascent duration: 3.2 s  
- Velocity curves: coefficients 1.35, 1.25, and formula shapes (e.g. 4*τ*(1−τ))

**Buoyancy**

- Lift phase: 25 s  
- Water phase: 18 s  
- Drop phase: 3.2 s  
- Motor power curve: 50 + 80*τ*(1−τ) W  
- Pump power: 200 + 150*sin(...) W (with a defined time window)  
- Velocity curves: 0.65 and 4.2 and exponent 0.7 in formulas

**Halbach / Electromagnetic**

- Lift: 6.5 s, hold: 1 s, drop: 2.2 s  
- Lift force: 1.15 * m * g  
- Hoist power: 45 W (40 W during hold)  
- Velocity curves: 1.5*sin(π*τ), 4*(1−(1−τ)^0.65)

**Variable Counterweight**

- Descent: 2.5 s, dock: 1.5 s, ascent: 2.8 s, load: 1.2 s  
- Cab mass: same as `m_common` (50 kg in scripts)  
- Module mass: **10 kg**  
- Counterweight: cab + 1 module  
- Auxiliary power: 450 W (dock), 380 W (load)  
- Small generator burst (80 W Gaussian) and 25 W support power in defined intervals  

None of the above durations, power levels, or curve shapes are marked in the repo as coming from you.

### 3.3 Efficiencies and scaling (four-system comparison)

- Generator/motor efficiencies: ranges like 0.72±0.02, 0.88±0.02, 0.74±0.02, etc., and bounds (e.g. 0.5–0.92).  
- Consumption scaling: e.g. 1±0.03, clamped to 0.85–1.15.  
- Friction scale: ±10% per system for error analysis.  

All of these are **chosen for the comparison**, not attributed to you in the repo.

### 3.4 Loss breakdown (tiered analysis only)

- Split of total loss into rope / bearing / gear / motor (e.g. 15%, 20%, 25%, 40% for Dual Weight).  
- Stored in `run_tiered_gravity_analysis.m` as `loss_frac`.  

Explicitly **assumed for reporting**; the simulation does not output these components. Not from you unless you gave such a split.

### 3.5 Cost and lifecycle (tiered analysis)

- Base build cost: **500** (currency not specified in code)  
- Life: **10,000** cycles  
- Build factors per system: 1.0, 1.2, 1.8, 1.4  

Not marked as user input.

### 3.6 Drum + motor system (`main_simulation.m` + `system_parameters.m`)

Used by `main_simulation.m` (single drum + gearbox + motor), **not** by the four-system comparison.

**Motor (in `system_parameters.m`)**

- Name in comments: **Turnigy Aerodrive SK3-5065-236KV**
- Kv = 236 RPM/V  
- K_e from Kv; K_t = K_e  
- R_winding = 0.019 Ω  
- L_winding = 0.0001 H  
- J_rotor = 0.001 kg·m²  
- I_max = 60 A  

**Physical**

- mass = 15 kg  
- drum_radius = 0.06 m  
- drum_inertia = 0.012 kg·m²  
- initial_height = 3.0 m  
- sprocket_ratio = 1.2  
- gearbox ratio = 4.0  
- bevel 1:1  

**Losses**

- Drum/sprocket/gearbox/bevel efficiencies and Coulomb/viscous terms (numerical values in `system_parameters.m`).  

None of these are tagged in the repo as “given by the user.”

---

## 4. Summary checklist for your new simulation

- [ ] **50 kg, 3 m** – Did you ever specify these? If yes, keep; if no, replace with your real values.  
- [ ] **Motor(s)** – Did you give a specific motor (name/datasheet)? If yes, that’s your only motor input; if the Turnigy was not from you, don’t use it as “your” spec.  
- [ ] **Diagrams** – Locate any diagram you actually provided (file or chat); use only those for system layout and components.  
- [ ] **Phase times and power curves** – All current values (2.8 s, 25 s, 45 W, etc.) are code-chosen. For a real simulation, replace with data from your diagrams, measurements, or specs.  
- [ ] **Efficiencies** – Currently generic ranges. Replace with datasheet or measured values if you have them.  

**Bottom line:** The only things that are clearly “yours” in this repo are the **four system concepts and names** and the note that the electromagnetic system uses Halbach arrays as a component. Every number and curve in the code (mass, height, times, powers, efficiencies, motor constants, loss splits, cost, lifecycle) is **not** confirmed as something you said. Use this list to decide what to keep and what to replace when you start from scratch.
