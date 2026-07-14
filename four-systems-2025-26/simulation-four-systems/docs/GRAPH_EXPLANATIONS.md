# Graph-by-Graph Explanations — EcoDrop Gravity Battery Simulation

Use this as a reference when presenting or when a judge asks what a figure shows. Each section: **what the graph is**, **how to read it**, and **what to say**.

---

## Core comparison figures (from `run_presentation_plots_dark.m`)

### 1A — Round-trip efficiency, all 4 systems (vertical bar)
**File:** `1A_RTE_All_4.png`  
**Title:** Round-Trip Efficiency: All 4 Systems Comparison

**What it is:** Vertical bar chart of discharge efficiency (%) for Variable CW, Dual Weight, Buoyancy, and Halbach Array. Reference lines for pumped hydro (77.5%) and lithium-ion (88.5%). Error bars show spread over 100 replicate runs.

**How to read it:** Higher bar = more of the gravitational potential energy (PE) is converted to useful electrical output per cycle. Bars below the reference lines mean the system is less efficient than that benchmark. Variable CW is highest; Halbach is lowest.

**One line:** “This is our headline efficiency comparison: Variable Counterweight leads, and all four sit below lithium-ion, which is what we expect for gravity-based storage.”

---

### 1B — Loss breakdown, all 4 (stacked bar)
**File:** `1B_Loss_Breakdown_All_4.png`  
**Title:** Where Energy Is Lost Per Cycle: All 4 Systems

**What it is:** Stacked bars for each system. Each bar is total loss (J) split into five segments: rope, bearing, gearbox, motor, system-specific. Total loss is labeled on top of each stack.

**How to read it:** Same total height = same total loss. Different colors show where the loss comes from. Variable CW has a large “system-specific” (purple) slice; Halbach and Buoyancy have very large system-specific shares (pump, drag, linear motors, etc.).

**One line:** “We can see exactly where each system loses energy—rope, bearing, gearbox, motor, and system-specific—so we know where to improve.”

---

### 1C — Net energy per cycle, all 4
**File:** `1C_Net_Energy_All_4.png`  
**Title:** Net Energy Per Cycle: All 4 Systems

**What it is:** One bar per system: net energy per cycle in joules (E_out − energy consumed that cycle). All are negative. Zero line is drawn. Error bars from 100 replicates.

**How to read it:** More negative = more net energy “lost” or consumed per cycle (e.g. Halbach most negative, Variable CW least negative). This is the cost of running one full cycle.

**One line:** “Net energy per cycle is negative for all systems; Variable CW loses the least per cycle, Halbach the most.”

---

### 2A — Round-trip efficiency, horizontal (all 4)
**File:** `2A_RTE_All_4_Horizontal.png`  
**Title:** Round-Trip Efficiency: All 4 Systems (Comparison)

**What it is:** Same as 1A but horizontal bars. Same reference lines (pumped hydro, Li-ion). Same ranking.

**How to read it:** Longer bar = higher efficiency. Useful when you want system names on the left and a clear left-to-right comparison.

**One line:** “Same efficiency comparison in horizontal form—Variable CW longest, Halbach shortest.”

---

### 2B — Loss breakdown, all 4 (wider bars)
**File:** `2B_Loss_Breakdown_All_4.png`  
**Title:** Energy Loss Breakdown Per Cycle: All 4 Systems

**What it is:** Same content as 1B (stacked loss by component) with slightly wider bars. Use 1B or 2B depending on layout.

**How to read it:** Same as 1B.

---

### 3A — RTE headline (horizontal, with benchmarks)
**File:** `3A_RTE_All_Headline.png`  
**Title:** Round-Trip Power Efficiency: All 4 Gravitational Storage Systems vs. Industry Benchmarks

**What it is:** The main “poster” version: horizontal bars, all four systems, with pumped hydro and lithium-ion reference lines. Large, readable for a backboard.

**How to read it:** Same as 2A. This is the one to use as the single “headline” efficiency figure.

**One line:** “Our four systems compared to industry benchmarks; Variable CW is best among ours and sits between pumped hydro and lithium-ion.”

---

### 3B — Energy in to charge vs. energy out on discharge
**File:** `3B_Energy_In_vs_Out.png`  
**Title:** Energy In to Charge vs. Energy Out on Discharge Per Cycle: All 4 Systems

**What it is:** Grouped bars per system. For each system: one bar = energy in to charge (PE input, same 1471.5 J for all); other bar = electrical energy out on discharge (from presentation data). The gap between them is the loss.

**How to read it:** Input bar is the same height for all (same PE). Output bar is lower; the difference is total loss. Variable CW has the smallest gap; Halbach the largest.

**One line:** “Same energy in for everyone; the difference in bar height is how much each system loses between input and output.”

---

### 3C — Full loss breakdown (stacked, all 4)
**File:** `3C_Loss_Breakdown_All.png`  
**Title:** Energy Loss Breakdown Per Cycle: Where Each System Loses Power

**What it is:** Same idea as 1B/2B: stacked bars by loss component (rope, bearing, gearbox, motor, system-specific), with total loss on top.

**How to read it:** Same as 1B. Use this if you want the title that says “Where Each System Loses Power.”

---

### 3D — Cumulative net energy over 500 cycles
**File:** `3D_Cumulative_Net_500.png`  
**Title:** Cumulative Net Energy Output Over 500 Cycles: All 4 Systems

**What it is:** Line plot: x = cycle number (1–500), y = cumulative net energy (kJ). One line per system. All lines go downward (negative net). Labels at 500 cycles show final cumulative value.

**How to read it:** Steeper downward = more net energy lost per cycle. Variable CW is least steep; Halbach most steep. Shows how the “debt” builds over many cycles.

**One line:** “Over 500 cycles, Variable CW accumulates the smallest negative net energy; Halbach the largest.”

---

### 3E — Sensitivity to friction variation (±10%)
**File:** `3E_Sensitivity_Friction.png`  
**Title:** Efficiency Robustness: Effect of ±10% Friction Variation on All 4 Systems

**What it is:** Grouped bars per system: baseline, +10% friction, −10% friction. Shows how efficiency changes when friction is scaled up or down.

**How to read it:** Compare the three bars for each system. If they’re close, ranking is robust to friction uncertainty. Variable CW stays on top across the three scenarios.

**One line:** “When we change friction by ±10%, the ranking doesn’t change—Variable CW stays best.”

---

## Sankey energy flow diagrams

**Files:** Individual Sankeys per system + one combined figure (from `sankey_energy_flow.py`).

**What they are:** Flow diagrams: one input (gravitational PE, e.g. 1471.5 J), then losses “peel off” (rope, bearing, gearbox, motor, system-specific), and the remainder is useful electrical output. Width of each stream is proportional to energy.

**How to read them:** Follow left to right. The main stream shrinks as losses branch off. The final stream is E_out. Variable CW has a thick final stream; Halbach has a thin one.

**One line:** “Sankeys show exactly how much energy is lost at each stage and how much reaches the output.”

---

## Analysis figures (from separate scripts, same presentation data)

### Sensitivity heatmap — Variable CW vs. Dual Weight
**File:** `Sensitivity_VariableCW_vs_DualWeight.png`  
**Title:** RTE Advantage of Variable CW over Dual Weight (R_VCW − R_DW)

**What it is:** 2D heatmap. X = motor loss scale (e.g. 0.8–1.2); Y = system-specific loss scale (e.g. 0.5–1.5). Color = difference in discharge efficiency (Variable CW minus Dual Weight). No contour at zero means Variable CW is always better in this grid.

**How to read it:** Warmer color = bigger advantage for Variable CW. Even when we vary motor and system losses (e.g. ±20%), Variable CW stays ahead of Dual Weight.

**One line:** “Across a range of motor and system losses, Variable CW always beats Dual Weight.”

---

### Mass required to deliver 1 kWh vs. height
**File:** `Scale_to_1kWh_Mass_vs_Height.png`  
**Title:** Mass-Height Requirement to Store 1 kWh (Delivered) for Each System

**What it is:** Line plot: x = height (e.g. 10–100 m), y = mass (kg) needed so that delivered energy = 1 kWh. One line per system. Higher efficiency ⇒ less mass at a given height.

**How to read it:** At any height, Variable CW needs the least mass; Halbach the most. Steeper drop with height = “height helps more” for that system.

**One line:** “To deliver 1 kWh, Variable CW needs the least mass at any height; Halbach needs the most.”

---

### Cycles to 1 kWh vs. drop height
**File:** `Cycles_to_1kWh_vs_Height.png`  
**Title:** Cycles to 1 kWh vs. Drop Height: How Hard Each System Has to Work

**What it is:** x = drop height (e.g. 3–50 m), y = number of cycles required to deliver 1 kWh. One line per system. Buoyancy and Halbach may go dashed after an “engineering wall” (e.g. 15 m) to show design limits.

**How to read it:** Fewer cycles = better. At higher height, fewer cycles needed. Variable CW needs fewest cycles; Halbach most. Dashed part = beyond typical design range.

**One line:** “Variable CW reaches 1 kWh in the fewest cycles; at higher heights the gap grows.”

---

### Energy delivered per cycle vs. drop height
**File:** `Energy_vs_Height_Eout_per_Cycle.png`  
**Title:** Energy Delivered Per Cycle vs. Drop Height: How Each System Scales

**What it is:** x = drop height (e.g. 3–100 m), y = energy delivered per cycle (kWh). One line per system. E_out = efficiency × m × g × h (scaled to kWh). Solid vs dashed as in cycles plot for engineering limits.

**How to read it:** Higher line = more energy per cycle at that height. Variable CW highest; all scale with height. Dashed = beyond assumed design range.

**One line:** “More height means more energy per cycle for every system; Variable CW delivers the most at every height.”

---

### Instantaneous power during discharge (optional)
**File:** `Power_Profile_Instantaneous_All_4.png`  
**Title:** Instantaneous Electrical Power During Discharge: All 4 Systems

**What it is:** Rectangular power-vs-time profiles over a fixed discharge duration (e.g. 6 s). Average power = E_out / duration so area = E_out. For comparison only; not from the ODE.

**How to read it:** Higher rectangle = higher average power. Same duration for all so you compare “how much power each system would deliver over the same window.”

**One line:** “Same time window; the height of each bar is average power so the area equals the energy out we report.”

---

## Quick reference — figure → message

| Figure       | Main message |
|-------------|--------------|
| 1A / 2A / 3A | Variable CW most efficient; all below Li-ion. |
| 1B / 2B / 3C | Loss breakdown shows where to improve (system-specific dominates for some). |
| 1C           | Net energy per cycle most negative for Halbach, least for Variable CW. |
| 3B           | Same PE in; gap between in and out = total loss. |
| 3D           | Cumulative net over 500 cycles: Variable CW best. |
| 3E           | Ranking robust to ±10% friction. |
| Sensitivity heatmap | Variable CW beats Dual Weight across parameter grid. |
| Scale to 1 kWh | Variable CW needs least mass for 1 kWh at any height. |
| Cycles to 1 kWh | Variable CW needs fewest cycles to reach 1 kWh. |
| Energy vs height | Variable CW delivers most energy per cycle at every height. |
| Sankey       | Visual flow from PE to losses to electrical output. |
