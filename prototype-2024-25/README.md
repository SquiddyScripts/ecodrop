# Year 1 (2024–25) — The Generation Prototype

> *"The Effect of Mass on Gravitational Energy Production"* — Chantilly HS Science Fair,
> January 23, 2025 · Fairfax County Regional Science & Engineering Fair, March 2025 ·
> Invention Convention (States → Nationals), spring 2025.

This is where the project started: a question — **can gravity be a practical, small-scale
energy source?** — answered with a physical build in a garage.

## The build

A ~9-foot wooden scaffold frame. Barbell weights (10–25 kg) tied to polypropylene rope,
routed through a pulley, wound on a spool salvaged and modified from a **weed-whacker**
(later re-engineered into a cleated hoist drum), driving a gearbox into a DC generator motor.
The first gearbox was built from Vex/Lego robotics parts; a discarded **bicycle wheel** served
as an early spool/flywheel experiment (see `photos/build/BikeSpool.jpg`).

What worked, what failed, and every component iteration (gearbox ×4, couplers, spool → hoist
drum, weight box, brushed DC → BLDC motor selection) is documented in the
[Engineering Logbook](../documents/logbook/).

## Contents

| Folder | What's inside |
|--------|---------------|
| `photos/build/` | Real build photos: bike spool, materials, gearbox iterations, the full scaffold, team members assembling parts (HEIC originals + JPG conversions) |
| `data/` | The multimeter measurements from drop trials — the project's only fully physical dataset |
| `analysis/` | Python analysis scripts (March 2025): regression, ANOVA, efficiency plots of the measured data |
| `3d-printing/` | STL files for the stackable planetary gearbox prints and printed couplers *(origin partly uncertain — see PROVENANCE.md)* |
| `blender/` | Blender models of the rig (`Gravity.blend`, Oct 2024; `scifair.blend`, Jan 2025) |

## Key results (measured)

Peak measured end-to-end efficiency was **~28.7 % at 25 kg** — mass up, efficiency up,
confirming the hypothesis and revealing the loss channels (gear slippage, rope friction,
brushed-motor losses) that drove every redesign in Year 2.
