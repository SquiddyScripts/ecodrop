# Why We Use Discharge Efficiency (Not Round-Trip Efficiency) and What It Tells Us

This document explains why the simulation and presentation report **discharge efficiency** (electrical out per unit gravitational potential energy in) instead of classic **round-trip efficiency**, and what that choice means for interpreting results.

---

## 1. What we report: discharge efficiency

**Definition:**

- **Discharge efficiency** = (electrical energy out on discharge) / (gravitational potential energy of the drop)  
- In numbers: **η_discharge = E_out / PE_input**, often expressed as a percentage.  
- **PE_input** = m × g × h (e.g. 50 kg × 9.81 m/s² × 3 m ≈ 1471.5 J). We use the **same** PE_input for every system so the comparison is fair.

So we ask: *“Of the gravitational PE you put in by dropping the mass, what fraction do you get back as useful electricity?”*

---

## 2. Why not “round-trip efficiency” (RTE)?

**Classic RTE** is usually:

- **RTE** = (electrical energy out) / (electrical energy in to charge the system).

That makes sense for a battery you plug in: same “currency” (electricity) in and out. For gravity systems we have two different situations:

- **Regenerative systems (Variable CW, Dual Weight):**  
  “Charge” is not always a single electrical input; it’s the work to lift the weight (or rebalance), which can come from regeneration in the other half of the cycle, plus some motor input. So “energy in” is not a single, clearly defined electrical number in the same way as for a lithium-ion cell.

- **Storage systems (Buoyancy, Halbach):**  
  “Charge” is pump work or electrical input to linear motors. So we *could* define RTE = E_out / E_consumed. But then we’re comparing:
  - Regenerative: “efficiency of the cycle using mechanical/regenerative work”
  - Storage: “efficiency of electrical in → electrical out”

Those two “RTEs” are **not the same kind of number**. One mixes mechanical and electrical; the other is purely electrical. Putting them on one bar chart as “RTE” would be comparing apples and oranges.

So we **don’t** define one universal “round-trip efficiency” for all four systems and use that as the main metric.

---

## 3. Why discharge efficiency is the right choice

We want **one fair, comparable number** across all four systems:

- **Same input:** For every system we use the **same** gravitational PE (same m, g, h). That’s the “fuel” that nature gives you when you drop the weight.
- **Same “question”:** For each system we ask: *“When this mass drops through this height, what fraction of that PE becomes useful electricity?”*
- **Same units:** PE_input in joules, E_out in joules → η = E_out / PE_input is a dimensionless fraction (or %). No mixing of electrical-in vs mechanical-in.

So:

- **Regenerative systems:** We’re not penalizing them for “not using electricity to charge”; we’re just measuring how good they are at turning **gravitational PE** into **electrical output** on the way down.
- **Storage systems:** We’re not mixing in their different “charge” mechanisms; we’re still asking the same question: *“Per joule of PE in the drop, how much electricity do you get out?”*

That’s why we **chose discharge efficiency (E_out / PE_input)** as the main reported metric: it’s **consistent, comparable, and physically clear** for every system.

---

## 4. What discharge efficiency tells us

- **Physically:** It is the **fraction of gravitational potential energy (of the drop) that is converted to useful electrical energy** in one discharge. The rest is lost (rope, bearing, gearbox, motor, and system-specific losses).

- **Practically:**  
  - Higher η_discharge ⇒ more electricity per drop for the same mass and height.  
  - It directly tells you how much mass (or how many cycles) you need to deliver a target energy (e.g. 1 kWh) at a given height—which is what the “mass for 1 kWh” and “cycles to 1 kWh” graphs use.

- **For the project:** It lets us rank the four systems on a **level playing field**: Variable CW (highest), then Dual Weight, Buoyancy, then Halbach (lowest), and we can say that ranking is about “how efficiently each system turns gravitational PE into electricity,” not about different definitions of “round-trip.”

---

## 5. Short summary for a judge or report

- We report **discharge efficiency** = **E_out / PE_input** (electrical out over gravitational PE of the drop), not classic round-trip efficiency.
- **Reason:** Our systems have different “charge” mechanisms (regenerative vs pump vs linear motors). A single “round-trip efficiency” would mix different types of “energy in” and wouldn’t be comparable. Discharge efficiency uses the **same** input (PE of the drop) for all systems, so the comparison is fair.
- **What it tells us:** What fraction of the gravitational PE becomes useful electricity on discharge. Higher discharge efficiency ⇒ more electricity per drop and fewer cycles (or less mass) to reach a target output like 1 kWh.
