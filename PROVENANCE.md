# Provenance — What Every Number Actually Is

This project spans physical experiments, three generations of simulation code, and
conceptual designs. This file is the honest map. **Categories:**

- 🔬 **Measured** — recorded from the physical prototype with instruments
- 🧮 **Calculated** — derived arithmetically from measurements
- 💻 **Simulated** — output of a MATLAB model (specify which generation)
- 📐 **Estimate** — engineering judgment / literature value
- 💡 **Conceptual** — designed but never built or simulated
- 🔶 **Placeholder** — explicitly provisional values in draft documents

---

## 🔬 Measured (the physical ground truth)

The only fully physical dataset is the Year-1 generation prototype
([data](prototype-2024-25/data/measured_results.csv)):

- Masses 10/15/20/25 kg → average voltages 3.13/4.90/6.33/8.23 V (3 multimeter trials each)
- 🧮 From those: average power 6.53/16.0/26.7/45.2 W and end-to-end efficiency
  18.7/25.2/25.6/28.7 % (assumes ~3 s effective generation window, h ≈ 2.5 m)
- The logbook's calibration note (25 kg, ~2.7 m, multimeter) refers to this same campaign

**Known inconsistency (flagged):** drop height appears as 2 m (research plan), 2.5 m
(analysis script), and ~2.7 m (logbook). The rig was rebuilt at least once; which height
belongs to which trial set is not recorded.

## 💻 Simulated — three generations, in chronological order

| Gen | Codebase | Date | Headline numbers (VCW/Dual/Buoy/Halbach) | Where the numbers appeared |
|-----|----------|------|------------------------------------------|---------------------------|
| 1 | `four-systems-2025-26/simulation-electromech-ode` | Jan 2026 | **89.7 / 60.5 / 42.0 / 28.9 % "round-trip efficiency"** (10 replicates, ANOVA F(3,36)=6.10) | Jan-2026 fair presentation script; `output/analysis_conclusion.txt`; Research.docx explainer (~90 %) |
| 2 | `simulation-four-systems` presentation pipeline | Mar 2026 | **77.0 / 60.0 / 39.5 / 27.0 % "discharge efficiency"** (replicates in `presentation_replicates.csv`) | Final backboard, engineering logbook, ISEF materials |
| 3 | `simulation-four-systems` full ODE run (`main`) | Mar 2026 | 76.0 / 74.4 / 56.8 / 56.5 % RTE (`matlab/outputs/summary_table.csv`) | Not used in presentations |

**Notes:**
- The identical ANOVA statistics (F(3,36)=6.10, p<0.001, η²=0.337) are quoted alongside both
  Gen-1 and Gen-2 headline numbers in different documents. The logbook pairs them with the
  Gen-2 (77.0 %) numbers.
- The presentation script draft (`documents/notes/Presentation_Script_Draft_2026.docx`)
  contains the team's own correction note that the electromagnetic system's descent
  generation was mis-modeled at that stage — evidence the team caught and revised the Gen-1
  model.
- Gen 3's much higher Buoyancy/Halbach values come from a different loss treatment in the
  full ODE run; it was never presented. Treat Gen 2 as the project's numbers of record.
- Research-plan wording ("100 replicates") vs. logbook ("10 runs"): the code supports both;
  the archived replicate CSV contains 10 per system for the presentation pipeline.

## 📐 Estimates / literature values

- Benchmark ranges: pumped hydro 70–85 %, lithium-ion 85–92 % (literature, cited in logbook)
- Motor operating efficiency 85–92 % (manufacturer/derived, logbook)
- Component costs in the logbook (~$0.50–$27.50 per subsystem) are recalled build costs
- Cost-per-kWh column in `backboard_summary_table.txt` is a simple cost model, not a quote

## 💡 Conceptual (designed, never built)

- All four storage/regeneration systems as physical machines (only simulated)
- Supercapacitor barbell modules, self-locking mechanism, elevator retrofit module
- Eddy-current "accelerated descent" idea — the logbook itself notes it cannot exceed
  conservation of energy and would actually brake the descent; preserved as a corrected
  theoretical exploration
- Vertical-lift-bridge integration (notes)

## 🔶 Placeholder

- `documents/concept-paper/gravity_battery_concept_paper.tex` is **self-labeled** a
  demonstration draft: its architecture names, some equations, and all numerical values are
  provisional by design. Do not quote numbers from it.

---

## Open questions flagged for the team (do not resolve by guessing)

1. **Awards/placements** at every event (school fair, regionals ×2, states, nationals,
   ISEF 2026) are not recorded in any recovered file. Add from certificates.
2. **"Dr. Jim" and the summer-2025 internship** — full name, affiliation, and the
   internship host are not in the files. The ISEF task list references elevator work
   "we did in VTech" (Virginia Tech). Clarify and credit properly.
3. **Drop-height inconsistency** (2 / 2.5 / 2.7 m) — see above.
4. **3D-printed gearbox STL origin** — `prototype-2024-25/3d-printing/` includes
   "PLANETARY GEARBOX - Unlimited Gear Ratio.zip", which looks like a downloaded community
   design, alongside what appear to be custom stackable-gearbox files. Confirm which STLs
   are original vs. adapted, and credit the source design if used.
5. **Onshape source models** — only screenshots are archived; export STEP/native files from
   the team Onshape workspace before access is lost.
6. **Raw Year-1 lab notes** — if handwritten data sheets still exist, scan them into
   `prototype-2024-25/data/`.
7. **Invention Convention videos** — full States/Nationals recordings (~700 MB each) are in
   the Google Drive export, not in this repo; compress and add web versions.
8. **Blog post** mentioned in Kavin's email (sent for review to "Chris"/"Hudson") — was it
   published? If so, link it here.
