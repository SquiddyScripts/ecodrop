# Elevator regeneration visualization

## Dual-weight (working)

```powershell
cd elevator-viz
python -m http.server 8765
```

Open **http://localhost:8765/elevator_regen.html**

## Variable counterweight (rebuilt — use this)

**http://localhost:8765/variable-counterweight.html**

Standalone page: procedural geometry (same dark/cyan style as dual-weight), no CAD loading.

- Auto demo: passengers cycle 0→6→0, barbells deploy/retrieve, car & counterweight rebalance
- Rotary station spins during transfer
- Views: Overview, Mechanism, Counterweight, Cab
- Auto-orbit on by default

Switch between demos via the top nav tabs.
