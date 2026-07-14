"""Animated GIF — weight motion + flux intensity through cycle."""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
from matplotlib.patches import Wedge

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from physics.cycle_model import H_MAX, T_TOT, get_cycle, motor_thrust_scale
from physics.halbach_field import halbach_ring_field

BG = "#0c0e14"
FG = "#ebebf0"


def figure_animation(out_dir: Path, n_frames: int = 90):
    out_dir.mkdir(parents=True, exist_ok=True)
    t_all = np.linspace(0, T_TOT, n_frames)
    cycle = get_cycle(t_all)

    res = 200
    lim = 0.14
    xs = np.linspace(-lim, lim, res)
    ys = np.linspace(-lim, lim, res)
    gx, gy = np.meshgrid(xs, ys)

    fig, axes = plt.subplots(1, 2, figsize=(12, 5.2), facecolor=BG)
    ax_flux, ax_sys = axes

    for ax in axes:
        ax.set_facecolor(BG)
        ax.tick_params(colors=FG)
        for spine in ax.spines.values():
            spine.set_color("#2a3040")

    # Static flux setup
    bx0, by0, bmag0 = halbach_ring_field(gx, gy, 0.04, 0.08, n_segments=8, remanence=1.2)
    r = np.sqrt(gx * gx + gy * gy)
    bmag0 = np.where(r < 0.038, np.nan, bmag0)

    im = ax_flux.contourf(gx, gy, bmag0 * 0.2, levels=30, cmap="turbo", alpha=0.85)
    ax_flux.set_aspect("equal")
    ax_flux.set_title("Halbach flux intensity (scales with thrust)", color=FG, fontsize=11)
    ax_flux.set_xlabel("x [m]", color=FG)
    ax_flux.set_ylabel("y [m]", color=FG)

    for seg in range(8):
        w = Wedge((0, 0), 0.08, 360 * seg / 8, 360 * (seg + 1) / 8, width=0.04, facecolor="none", edgecolor="#8899aa", lw=1)
        ax_flux.add_patch(w)

    # System side view
    ax_sys.set_xlim(-0.2, 2.5)
    ax_sys.set_ylim(0, H_MAX + 0.8)
    ax_sys.set_title("Four-motor tower — operation cycle", color=FG, fontsize=11)
    ax_sys.set_xlabel("Motor column index", color=FG)
    ax_sys.set_ylabel("Height [m]", color=FG)

    motor_xs = [0.3, 0.9, 1.5, 2.1]
    for i, mx in enumerate(motor_xs):
        ax_sys.plot([mx, mx], [0, H_MAX + 0.4], color="#667788", lw=3, alpha=0.5)
        ax_sys.text(mx, H_MAX + 0.55, f"TLM{i+1}", ha="center", color="#59adff", fontsize=8)

    weight_rect = plt.Rectangle((0.05, 0), 2.3, 0.25, color="#ff804d", ec="white", lw=1)
    ax_sys.add_patch(weight_rect)
    rope_line, = ax_sys.plot([1.2, 1.2], [0.25, H_MAX + 0.4], color="#ccddee", lw=1.5, ls="--")
    phase_text = ax_sys.text(0.02, H_MAX + 0.65, "", color=FG, fontsize=10)
    height_text = ax_sys.text(0.02, H_MAX + 0.48, "", color="#ff804d", fontsize=9)

    def update(frame):
        t = t_all[frame]
        scale = motor_thrust_scale(t) + 0.05
        bmag = bmag0 * scale
        pid = cycle["phase_id"][frame]
        names = {1: "Phase 1 — Lift (Halbach thrust)", 2: "Phase 2 — Hold (tension only)", 3: "Phase 3 — Drop (regen)"}

        ax_flux.clear()
        ax_flux.set_facecolor(BG)
        ax_flux.contourf(gx, gy, bmag, levels=30, cmap="turbo", alpha=0.88)
        ax_flux.set_aspect("equal")
        ax_flux.set_xlim(-lim, lim)
        ax_flux.set_ylim(-lim, lim)
        ax_flux.set_title("Halbach flux intensity (scales with thrust)", color=FG, fontsize=11)
        ax_flux.set_xlabel("x [m]", color=FG)
        ax_flux.set_ylabel("y [m]", color=FG)
        ax_flux.text(0.02, 0.97, f"t = {t:.2f} s · {names.get(pid, '')}", transform=ax_flux.transAxes, color=FG, fontsize=9, va="top")
        for seg in range(8):
            w = Wedge((0, 0), 0.08, 360 * seg / 8, 360 * (seg + 1) / 8, width=0.04, facecolor="none", edgecolor="#8899aa", lw=1)
            ax_flux.add_patch(w)

        h = cycle["h"][frame]
        weight_rect.set_y(h)
        rope_line.set_data([1.2, 1.2], [h + 0.25, H_MAX + 0.4])
        phase_text.set_text(names.get(pid, ""))
        height_text.set_text(f"h = {h:.2f} m · v = {cycle['v'][frame]:.2f} m/s")
        return []

    anim = animation.FuncAnimation(fig, update, frames=n_frames, interval=60, blit=False)
    gif_path = out_dir / "03_halbach_cycle_animation.gif"
    anim.save(gif_path, writer="pillow", fps=15, dpi=120)
    plt.close(fig)
    return gif_path


if __name__ == "__main__":
    figure_animation(Path(__file__).resolve().parents[1] / "output")
