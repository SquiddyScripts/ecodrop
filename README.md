<p align="center">
  <img src="docs/assets/img/hero_scaffold.jpg" width="820" alt="EcoDrop prototype — wooden scaffold, hoist drum, gearbox, and generator in the garage">
</p>

<h1 align="center">EcoDrop</h1>

<p align="center">
  <b>Amaan S. Khan · Aiman Ullah · Kavin Paturu Muralikrishnan</b><br>
  Chantilly High School · 2024 – present<br>
  <a href="https://squiddyscripts.github.io/ecodrop/">Project site</a> · <a href="documents/logbook/EcoDropGravity_Engineering_Logbook.pdf">Engineering logbook (PDF)</a>
</p>

---

### Abstract

*Gravitational Storage–Regeneration Systems* · [`documents/abstracts/`](documents/abstracts/)

This study evaluates the energy efficiency of four small-scale gravitational storage–regeneration concepts — buoyant displacement, electromagnetic assist, dual-weight counterbalance, and variable counterweight — using a MATLAB simulation with strict end-to-end energy bookkeeping. Each design is modeled under identical baseline conditions and assessed by generated electrical energy per drop, electrical energy required for lift, round-trip efficiency (E<sub>out</sub>/E<sub>in</sub> and E<sub>out</sub>/(mgh)), peak power, and detailed loss attribution. The analysis ranks concepts by realistic round-trip efficiency and identifies dominant mechanical and electrical loss channels. It also evaluates when active control elements produce a net benefit after accounting for coil and actuation energy. Reproducible test protocols and parameter files are provided to guide prototype selection and future experimental validation.

---

## Year 1 — we actually built it

<p align="center">
  <img src="prototype-2024-25/photos/build/BikeSpool.jpg" width="260" alt="Early spool experiment using a discarded bicycle wheel">
  &nbsp;
  <img src="prototype-2024-25/photos/build/LegoStackableGearbox.jpg" width="260" alt="Stackable planetary gearbox iteration">
  &nbsp;
  <img src="docs/assets/img/drum_motor.jpg" width="260" alt="Cleated hoist drum coupled to BLDC generator">
</p>

~9 ft wooden frame. Weed-whacker spool → cleated hoist drum. Vex/Lego gearbox → 3D-printed double-helix spur. Brushed DC → Turnigy SK3 BLDC. Multimeter trials at 10–25 kg.

| What we measured | Value |
|------------------|-------|
| Peak end-to-end efficiency | **28.7 %** at 25 kg |
| Average electrical output | **~45 W** at 25 kg |
| Raw data | [`prototype-2024-25/data/measured_results.csv`](prototype-2024-25/data/measured_results.csv) |

<p align="center">
  <img src="docs/assets/img/garage_wide.jpg" width="400" alt="Full garage setup">
  &nbsp;
  <img src="docs/assets/img/team_working.jpg" width="400" alt="Team assembling the rig">
</p>

Every failed iteration is in the [**engineering logbook**](documents/logbook/EcoDropGravity_Engineering_Logbook.pdf) — gearbox v1 through v4, spool redesign, motor swap, weight box, couplers.

<p align="center">
  <img src="documents/logbook/figures/image3.png" width="240" alt="Logbook — gearbox iteration 1">
  <img src="documents/logbook/figures/image5.png" width="240" alt="Logbook — gearbox iteration 2">
  <img src="documents/logbook/figures/image7.png" width="240" alt="Logbook — final double-helix gearbox">
</p>

→ Full Year 1 folder: [`prototype-2024-25/`](prototype-2024-25/)

---

## Year 2 — four ways to store gravity

After the prototype worked, the question changed: **which architecture makes small-scale gravity storage practical?**

Four systems, same baseline (50 kg, 3 m drop, same motor model), modeled in MATLAB. Diagrams and CAD below are from the engineering logbook and Onshape.

| System | Simulated discharge efficiency |
|--------|-------------------------------|
| **Variable counterweight** | **77.0 ± 0.5 %** |
| **Dual weight** | 60.0 ± 1.2 % |
| **Buoyancy** | 39.5 ± 1.8 % |
| **Halbach linear** | 27.0 ± 2.1 % |

### 1 · Variable counterweight — **77.0 ± 0.5 %**

Modular masses deploy/retract so the counterweight matches the load. Motor only pays for imbalance + friction.

<p align="center">
  <img src="docs/assets/img/lb_vcw1.jpg" width="380" alt="Variable counterweight system diagram from engineering logbook">
  &nbsp;
  <img src="docs/assets/img/cad_vcw.jpg" width="380" alt="Onshape CAD of variable counterweight mechanism">
</p>

<p align="center">
  <img src="docs/assets/img/lb_vcw2.jpg" width="480" alt="Variable counterweight mechanism detail">
  &nbsp;
  <img src="docs/assets/img/fig_vcw_ts.jpg" width="480" alt="Variable counterweight time-series simulation">
</p>

### 2 · Dual weight — **60.0 ± 1.2 %**

Two hoist drums, opposite rope wind — generate on both directions of travel (elevator-style regen).

<p align="center">
  <img src="docs/assets/img/lb_dual1.jpg" width="560" alt="Dual weight regeneration system diagram">
</p>

### 3 · Buoyancy — **39.5 ± 1.8 %**

Flood a chamber to lift the mass (Archimedes), then discharge through the generator / turbine path.

<p align="center">
  <img src="docs/assets/img/lb_buoyancy1.jpg" width="380" alt="Buoyant weight tower skeleton — hand sketch">
  &nbsp;
  <img src="docs/assets/img/lb_buoyancy2.jpg" width="380" alt="Buoyancy system detail">
</p>

### 4 · Halbach linear (electromagnetic) — **27.0 ± 2.1 %**

Tubular quasi-Halbach magnets lift the mass with no ropes. Lowest simulated efficiency — current design focus for Year 3.

<p align="center">
  <img src="docs/assets/img/fig_halbach_flux.jpg" width="560" alt="Halbach flux concentration analysis">
</p>

<p align="center">
  <img src="docs/assets/img/fig_halbach_dash.jpg" width="480" alt="Halbach system dashboard">
  &nbsp;
  <img src="docs/assets/img/halbach_cycle.gif" width="380" alt="Halbach charge-discharge cycle animation">
</p>

### Comparison figures

<p align="center">
  <img src="four-systems-2025-26/presentation-graphs/Fig5_RTE.png" width="420" alt="Round-trip efficiency comparison">
  &nbsp;
  <img src="four-systems-2025-26/presentation-graphs/Fig1_LossBreakdown.png" width="420" alt="Loss breakdown by system">
</p>

<p align="center">
  <img src="docs/assets/img/backboard_2026.jpg" width="700" alt="2026 science fair backboard">
</p>

None of these four exist as full physical machines yet — CAD + simulation + demos. Year 1 prototype data is what calibrated the models.

→ [`four-systems-2025-26/`](four-systems-2025-26/) · [`PROVENANCE.md`](PROVENANCE.md)

---

## Year 3 — electromagnetic + elevator retrofit (in progress)

T-shaped quasi-Halbach tubular linear machine + elevator machine-room integration. Concept paper draft in LaTeX.

<p align="center">
  <img src="docs/assets/img/cad_hoistway.jpg" width="380" alt="Elevator hoistway CAD">
  &nbsp;
  <img src="docs/assets/img/cad_bevel.jpg" width="380" alt="Motor bevel connection CAD">
</p>

→ [`documents/concept-paper/`](documents/concept-paper/) · [`interactive-demos/`](interactive-demos/) (Three.js demos you can run locally)

**Project site versions:** the live GitHub Pages page is `docs/index.html`. Older layouts are saved under [`docs/archive/`](docs/archive/) so you can switch later without losing either one.

---

## Competitions

### Fairfax County Regional Science & Engineering Fair · March 2026

<p align="center">
  <img src="competitions/featured/regional_fair_2026_awards.png" width="720" alt="71st Annual Fairfax County Regional Science and Engineering Fair awards ceremony, March 15–17, 2026">
</p>

### Invention Convention U.S. Nationals · June 2026

<p align="center">
  <img src="competitions/featured/invention_convention_logo.png" width="200" alt="Invention Convention Worldwide">
  &nbsp;&nbsp;
  <img src="competitions/featured/invention_convention_nationals_2026.png" width="520" alt="EcoDrop team at RTX Invention Convention U.S. Nationals, June 3–5, 2026">
</p>

### Regeneron ISEF · 2026

<p align="center">
  <img src="competitions/featured/isef_logo.png" width="200" alt="Regeneron ISEF">
  &nbsp;&nbsp;
  <img src="competitions/featured/isef_2026_team.png" width="520" alt="Chantilly HS ISEF team">
</p>

Backboards, event photos, videos: [`competitions/`](competitions/) · full photo gallery on the [project site](https://squiddyscripts.github.io/ecodrop/gallery.html)

---

## Technical documentation

| Document | Path |
|----------|------|
| **Engineering logbook** (component-by-component iteration history) | [`documents/logbook/EcoDropGravity_Engineering_Logbook.pdf`](documents/logbook/EcoDropGravity_Engineering_Logbook.pdf) |
| **LaTeX technical documentation** (equations, drivetrain ODE, per-file reference) | [`four-systems-2025-26/latex/TECHNICAL_DOCUMENTATION.pdf`](four-systems-2025-26/latex/TECHNICAL_DOCUMENTATION.pdf) |
| **Provenance map** (measured vs simulated vs conceptual for every number) | [`PROVENANCE.md`](PROVENANCE.md) |
| **Timeline** (dated chronology from file evidence) | [`TIMELINE.md`](TIMELINE.md) |
| **Abstracts & research plans** | [`documents/`](documents/) |
| **Annotated bibliography** | [`research/`](research/) |

---

## Run the code

**MATLAB** (R2016b+):

```matlab
% Final four-system pipeline (numbers used on backboard)
cd four-systems-2025-26/simulation-four-systems
addpath('matlab'); addpath('matlab/systems');
run_presentation_plots_dark
main
```

**Interactive demos** (Node 18+):

```bash
cd interactive-demos && npm install && npm run dev
# http://127.0.0.1:5190/
```

**Halbach figures** (Python 3.10+):

```bash
cd interactive-demos/halbach-viz && pip install -r requirements.txt && python run_all.py
```

**Year 1 data analysis**:

```bash
cd prototype-2024-25/analysis && python gravenv.py
```

---

## Repository layout

```
prototype-2024-25/      Build photos, multimeter data, Python analysis, 3D prints, Blender
four-systems-2025-26/   Both MATLAB codebases, LaTeX docs, presentation figures
interactive-demos/      Three.js lab + Python Halbach viz (source — not the built copy)
documents/              Logbook, abstracts, research plans, concept paper, notes
cad/                    Onshape screenshots, renders, credited third-party models
competitions/           Backboards, event photos/videos
research/               Bibliography, reference papers
docs/                   GitHub Pages site
```

---

## Authors

**Amaan S. Khan · Aiman Ullah · Kavin Paturu Muralikrishnan**

Attribution details: [`AUTHORS.md`](AUTHORS.md)
