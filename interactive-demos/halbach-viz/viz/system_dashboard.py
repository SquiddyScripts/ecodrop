"""3D system schematic + cycle dashboard — engineering presentation figure."""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.gridspec import GridSpec
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from physics.cycle_model import G, H_MAX, M_WEIGHT, N_MOTORS, T_TOT, get_cycle

BG = "#0c0e14"
FG = "#ebebf0"
GRID = "#2a3040"
C_THRUST = "#ff804d"
C_GEN = "#66d98c"
C_CONS = "#bf7af0"
C_PHASE = "#59adff"


def draw_motor_tower(ax, x, z, height, phase_h):
    """Single tubular linear motor column."""
    theta = np.linspace(0, 2 * np.pi, 32)
    r_outer, r_inner, r_mover = 0.09, 0.07, 0.055
    y0 = phase_h

    for r, color, alpha in [
        (r_outer, "#667788", 0.35),
        (r_mover, "#59adff", 0.55),
        (r_inner * 0.45, "#2a3038", 0.9),
    ]:
        xs = x + r * np.cos(theta)
        zs = z + r * np.sin(theta)
        ys = np.full_like(xs, y0)
        ax.plot(xs, ys, zs, color=color, alpha=alpha, lw=1.2)
        ax.plot(xs, ys + height, zs, color=color, alpha=alpha, lw=1.2)
        for k in [0, 8, 16, 24]:
            ax.plot([xs[k], xs[k]], [y0, y0 + height], [zs[k], zs[k]], color=color, alpha=alpha * 0.7, lw=0.8)


def figure_system_dashboard(out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    t = np.linspace(0, T_TOT, 500)
    data = get_cycle(t)

    fig = plt.figure(figsize=(16, 9), facecolor=BG)
    gs = GridSpec(2, 3, figure=fig, height_ratios=[1.15, 1], hspace=0.32, wspace=0.28)

    # --- 3D system (4 tubular motors + weight + hoist) ---
    ax3d = fig.add_subplot(gs[0, 0], projection="3d", facecolor=BG)
    ax3d.set_facecolor(BG)

    h_anim = H_MAX * 0.62
    corners = [(0.28, 0.28), (-0.28, 0.28), (-0.28, -0.28), (0.28, -0.28)]
    for i, (cx, cz) in enumerate(corners):
        draw_motor_tower(ax3d, cx, cz, H_MAX * 0.85, 0.05)
        ax3d.text(cx, H_MAX + 0.35, cz, f"TLM {i+1}", color=C_PHASE, fontsize=8, ha="center")

    # Weight slab
    wx, wz = 0.18, 0.18
    wy = h_anim
    for dx, dz in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
        ax3d.plot([dx * wx, dx * wx], [wy, wy + 0.35], [dz * wz, dz * wz], color=C_THRUST, lw=2)
    ax3d.plot([0, 0], [wy + 0.35, H_MAX + 0.55], [0, 0], color="#ccddee", lw=1.5, ls="--")

    # Hoist drum at top
    th = np.linspace(0, 2 * np.pi, 40)
    ax3d.plot(0.12 * np.cos(th), np.full(40, H_MAX + 0.55), 0.12 * np.sin(th), color="#8899aa", lw=2)

    ax3d.set_xlim(-0.5, 0.5)
    ax3d.set_ylim(0, H_MAX + 0.8)
    ax3d.set_zlim(-0.5, 0.5)
    ax3d.set_xlabel("X [m]", color=FG, labelpad=6)
    ax3d.set_ylabel("Height [m]", color=FG, labelpad=6)
    ax3d.set_zlabel("Z [m]", color=FG, labelpad=6)
    ax3d.set_title("4× tubular Halbach linear motors + tension hoist", color=FG, fontsize=11, pad=8)
    ax3d.tick_params(colors=FG)
    ax3d.xaxis.pane.fill = ax3d.yaxis.pane.fill = ax3d.zaxis.pane.fill = False
    ax3d.grid(True, color=GRID, alpha=0.4)

    # --- Height & velocity ---
    ax_h = fig.add_subplot(gs[0, 1], facecolor=BG)
    ax_h.plot(data["t"], data["h"], color=C_THRUST, lw=2.2, label="Weight height")
    ax_h.set_ylabel("Height [m]", color=FG)
    ax_h.set_xlabel("Time [s]", color=FG)
    ax_h.set_title("Lift → hold → drop cycle", color=FG)
    ax_h.tick_params(colors=FG)
    ax_h.grid(True, color=GRID, alpha=0.5)
    ax_h.legend(facecolor="#1a2030", edgecolor=GRID, labelcolor=FG)
    ax_v = ax_h.twinx()
    ax_v.plot(data["t"], data["v"], color=C_PHASE, lw=1.5, alpha=0.85, ls="--", label="Velocity")
    ax_v.set_ylabel("Velocity [m/s]", color=C_PHASE)
    ax_v.tick_params(colors=C_PHASE)

    # --- Power ---
    ax_p = fig.add_subplot(gs[0, 2], facecolor=BG)
    ax_p.fill_between(data["t"], 0, data["p_linear_elec"], color=C_CONS, alpha=0.35, label="Linear motor (elec)")
    ax_p.fill_between(data["t"], 0, data["p_hoist"], color="#f2bf40", alpha=0.35, label="Hoist tension")
    ax_p.fill_between(data["t"], 0, data["p_gen"], color=C_GEN, alpha=0.45, label="Regeneration")
    ax_p.set_xlabel("Time [s]", color=FG)
    ax_p.set_ylabel("Power [W]", color=FG)
    ax_p.set_title("Electrical power balance", color=FG)
    ax_p.tick_params(colors=FG)
    ax_p.grid(True, color=GRID, alpha=0.5)
    ax_p.legend(facecolor="#1a2030", edgecolor=GRID, labelcolor=FG, fontsize=8)

    # --- 6-phase current proxy ---
    ax_i = fig.add_subplot(gs[1, 0], facecolor=BG)
    ax_i.plot(data["t"], data["i_phase"], color=C_PHASE, lw=2)
    ax_i.axhline(0, color=GRID, lw=0.8)
    ax_i.set_xlabel("Time [s]", color=FG)
    ax_i.set_ylabel("Phase current [A] (proxy)", color=FG)
    ax_i.set_title("Six-phase drive — representative phase ripple", color=FG)
    ax_i.tick_params(colors=FG)
    ax_i.grid(True, color=GRID, alpha=0.5)

    # --- Thrust vs gravity ---
    ax_f = fig.add_subplot(gs[1, 1], facecolor=BG)
    ax_f.plot(data["t"], data["thrust"] / 1000, color=C_THRUST, lw=2, label="Motor thrust")
    ax_f.axhline(M_WEIGHT * G / 1000, color="#8899aa", ls=":", lw=1.5, label=f"Weight ({M_WEIGHT}g)")
    ax_f.set_xlabel("Time [s]", color=FG)
    ax_f.set_ylabel("Force [kN]", color=FG)
    ax_f.set_title("Halbach linear thrust envelope", color=FG)
    ax_f.tick_params(colors=FG)
    ax_f.grid(True, color=GRID, alpha=0.5)
    ax_f.legend(facecolor="#1a2030", edgecolor=GRID, labelcolor=FG, fontsize=8)

    # --- Energy summary ---
    ax_e = fig.add_subplot(gs[1, 2], facecolor=BG)
    ax_e.plot(data["t"], data["e_cons"] / 1000, color=C_CONS, lw=2, label="Consumed")
    ax_e.plot(data["t"], data["e_gen"] / 1000, color=C_GEN, lw=2.2, label="Generated")
    ax_e.fill_between(data["t"], data["e_gen"] / 1000, data["e_cons"] / 1000, alpha=0.12, color="white")
    ax_e.set_xlabel("Time [s]", color=FG)
    ax_e.set_ylabel("Energy [kJ]", color=FG)
    ax_e.set_title(f"Cumulative energy · η_rt = {data['round_trip_pct']:.1f}%", color=FG)
    ax_e.tick_params(colors=FG)
    ax_e.grid(True, color=GRID, alpha=0.5)
    ax_e.legend(facecolor="#1a2030", edgecolor=GRID, labelcolor=FG, fontsize=8)

    fig.suptitle(
        "Halbach Electromagnetic Gravity Battery — System Operation",
        color=FG,
        fontsize=15,
        fontweight="bold",
        y=0.98,
    )
    fig.text(
        0.5,
        0.01,
        f"{N_MOTORS} tubular linear motors (6-phase Halbach) · separate hoist maintains rope tension · {H_MAX} m stroke · {M_WEIGHT} kg payload",
        ha="center",
        color="#8899aa",
        fontsize=9,
    )

    png = out_dir / "02_system_dashboard.png"
    fig.savefig(png, dpi=200, facecolor=BG, bbox_inches="tight")
    plt.close(fig)
    return png


if __name__ == "__main__":
    figure_system_dashboard(Path(__file__).resolve().parents[1] / "output")
