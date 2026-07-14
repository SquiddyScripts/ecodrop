#!/usr/bin/env python3
"""Generate all Halbach electromagnetic visualization assets."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT))

from viz.flux_figure import figure_halbach_flux
from viz.system_dashboard import figure_system_dashboard
from viz.animate_cycle import figure_animation


def main():
    out = ROOT / "output"
    out.mkdir(exist_ok=True)

    print("Generating Halbach flux field figure...")
    p1 = figure_halbach_flux(out)
    print(f"  -> {p1}")

    print("Generating system dashboard...")
    p2 = figure_system_dashboard(out)
    print(f"  -> {p2}")

    print("Generating cycle animation (this may take ~30s)...")
    p3 = figure_animation(out)
    print(f"  -> {p3}")

    print("\nDone. Open output/ for PNG + GIF figures.")
    print("For interactive 3D: open halbach-viz/web/index.html in a browser.")


if __name__ == "__main__":
    main()
