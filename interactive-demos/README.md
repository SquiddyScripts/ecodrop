# Interactive Visual Demonstrations (2026)

Coded 3D demonstrations of the four systems, built with Three.js + Vite in spring 2026 to
explain the architectures visually — for judges, teachers, and anyone who has never seen a
gravity battery.

## The Gravity Battery Lab (this folder)

```bash
npm install
npm run dev        # open http://127.0.0.1:5190/
```

| Page | System | Notes |
|------|--------|-------|
| `index.html` | Hub | Landing page linking all four demos |
| `buoyancy.html` | Buoyancy | Water-chamber charge/discharge cycle, 400 L tank model |
| `halbach.html` | Halbach electromagnetic | Tubular linear-motor tower with live flux/telemetry panels driven by a JS port of the physics model |
| `elevator-dual.html` | Dual Weight | Elevator machine-room regeneration with real CAD meshes (standalone, CDN Three.js) |
| `elevator-variable.html` | Variable Counterweight | Rotary barbell-module deployment mechanism |

## `halbach-viz/` (Python)

Matplotlib companion package: Halbach flux-field figure, system dashboard, and an animated
charge/discharge cycle GIF (`output/03_halbach_cycle_animation.gif`).

```bash
pip install -r requirements.txt
python run_all.py
```

## `elevator-viz/` + `elevator-animation-evolution/`

The elevator demo went through many standalone-HTML iterations (late May → June 2026);
`elevator-animation-evolution/` preserves an early version, a late version, and the v2
template so the design evolution is visible. `elevator-viz/` contains the mesh-packing
tooling (`pack_meshes.py`) that inlines STL geometry into the standalone HTML files.

## Asset provenance

The elevator demos load **third-party CAD meshes** (elevator cab, roller guides, ram head —
GrabCAD community models) alongside team-modeled geometry. `meshes_packed.js` (31 MB,
generated) and the `dist/` build are excluded from the repo; regenerate with
`elevator-viz/pack_meshes.py` or `npm run build`. See [../cad/third-party/SOURCES.md](../cad/third-party/SOURCES.md).
