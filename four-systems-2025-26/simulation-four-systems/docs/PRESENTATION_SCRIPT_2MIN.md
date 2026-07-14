# 2-Minute Presentation Script — EcoDrop Gravity Battery Results

Use this script when presenting the simulation results. **Show the figure in brackets** when you reach that line. Speak at a steady pace; this is about 320 words (~2 minutes).

---

**[Show 3A or 1A — headline efficiency]**

“We compared four gravitational energy storage designs: Variable Counterweight, Dual Weight, Buoyancy, and Halbach Array. The first two are regenerative—they use the weight’s motion to help reset the system. The other two are storage systems—pump or linear motors do the lifting.

Our main question: which design turns gravitational potential energy into electricity most efficiently? We don’t use round-trip efficiency the same way as for a battery, because our systems don’t all ‘charge’ with electricity. So we report **discharge efficiency**: electrical energy out divided by the gravitational PE of the drop. Same PE input for everyone—fair comparison.”

**[Show 3A again or 1A]**

“Variable Counterweight comes out on top at 77%, then Dual Weight at 60%, Buoyancy at 39.5%, and Halbach at 27%. All four sit below lithium-ion, which is what we expect for gravity-based storage. So our ranking is clear: Variable CW is best among our designs.”

**[Show 3B or 1B / 3C — loss or energy in vs out]**

“The next graph shows energy in to charge versus energy out on discharge. Same input for all; the gap is the loss. We also broke that loss into components—rope, bearing, gearbox, motor, and system-specific. For Variable CW, a lot of the loss is system-specific—control and modular generators. For Halbach and Buoyancy, system-specific loss dominates because of the pump, drag, and linear motors. That tells us where each design would need improvement.”

**[Show Scale to 1 kWh or Cycles to 1 kWh]**

“For real-world scale, we asked: how much mass do you need to deliver one kilowatt-hour at different heights? Variable CW needs the least mass at any height; Halbach needs the most. Or in terms of cycles: Variable CW reaches one kilowatt-hour in the fewest cycles. So the efficiency gap translates directly into less mass or fewer cycles for the same output.”

**[Show 3E or sensitivity heatmap]**

“We checked robustness. When we varied friction by plus or minus 10%, or ran a parameter sweep on motor and system losses, the ranking didn’t change—Variable CW stayed on top. So our conclusion isn’t sensitive to those uncertainties.”

**[Optional: show 3D cumulative]**

“Over 500 cycles, cumulative net energy is negative for all systems—they all consume more than they deliver in net—but Variable CW accumulates the smallest deficit.”

**[Closing]**

“In short: we compared four gravity storage designs on discharge efficiency with the same gravitational input. Variable Counterweight performed best, and that result is robust to parameter variation. Thank you.”

---

## Cue card — figures in order

1. **3A or 1A** — Headline efficiency (Variable CW 77% … Halbach 27%).
2. **3B** — Energy in vs out (gap = loss).
3. **1B or 3C** — Loss breakdown (rope, bearing, gearbox, motor, system-specific).
4. **Scale_to_1kWh** or **Cycles_to_1kWh** — Mass or cycles for 1 kWh.
5. **3E** or **Sensitivity heatmap** — Ranking robust.
6. **3D** (optional) — Cumulative net over 500 cycles.

---

## If asked: “Why discharge efficiency and not RTE?”

“Our systems don’t all charge the same way—regenerative ones use mechanical work, storage ones use pumps or motors. So ‘energy in’ isn’t the same type for everyone. We use discharge efficiency: electrical out over gravitational PE of the drop. Same PE for all four, so we’re comparing apples to apples. We have a short doc that explains this in detail.”
