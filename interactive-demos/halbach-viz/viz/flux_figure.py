"""Figure 32 style — Halbach flux density cross-section with magnetization vectors."""

from __future__ import annotations

import sys
from pathlib import Path

import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from matplotlib import colormaps
from matplotlib.colors import Normalize

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from physics.halbach_field import halbach_ring_field, tubular_motor_flux_slice

BG = "#0c0e14"
FG = "#ebebf0"
GRID = "#2a3040"


def draw_halbach_octagon(ax, inner_r, outer_r, n_seg=8, alpha=0.95):
    """Draw segmented Halbach ring with magnetization arrows."""
    for seg in range(n_seg):
        t0 = 360 * seg / n_seg
        t1 = 360 * (seg + 1) / n_seg
        wedge = mpatches.Wedge(
            (0, 0),
            outer_r,
            t0,
            t1,
            width=outer_r - inner_r,
            facecolor="#2a3038",
            edgecolor="#8899aa",
            linewidth=1.2,
            alpha=alpha,
        )
        ax.add_patch(wedge)
        mid = np.deg2rad((t0 + t1) / 2)
        r_mid = (inner_r + outer_r) / 2
        mag = seg * np.pi / 2
        ax.annotate(
            "",
            xy=(r_mid * np.cos(mid) + 0.012 * np.cos(mag), r_mid * np.sin(mid) + 0.012 * np.sin(mag)),
            xytext=(r_mid * np.cos(mid), r_mid * np.sin(mid)),
            arrowprops=dict(arrowstyle="-|>", color="white", lw=1.8, mutation_scale=12),
        )


def figure_halbach_flux(out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)

    fig = plt.figure(figsize=(14, 6.5), facecolor=BG)
    gs = fig.add_gridspec(1, 2, width_ratios=[1.05, 1], wspace=0.22)

    # --- Panel A: Octagonal Halbach ring (board Figure 32) ---
    ax1 = fig.add_subplot(gs[0, 0], facecolor=BG)
    ax1.set_aspect("equal")
    ax1.set_xlim(-0.12, 0.12)
    ax1.set_ylim(-0.12, 0.12)

    res = 320
    lim = 0.16
    xs = np.linspace(-lim, lim, res)
    ys = np.linspace(-lim, lim, res)
    gx, gy = np.meshgrid(xs, ys)
    bx, by, bmag = halbach_ring_field(gx, gy, 0.045, 0.085, n_segments=8, remanence=1.35)

    # Mask inside hole
    r = np.sqrt(gx * gx + gy * gy)
    bmag = np.where(r < 0.042, np.nan, bmag)

    norm = Normalize(vmin=0.05, vmax=1.15)
    cf = ax1.contourf(gx, gy, bmag, levels=40, cmap="turbo", norm=norm, alpha=0.92)
    ax1.contour(gx, gy, bmag, levels=14, colors="white", linewidths=0.35, alpha=0.35)

    step = 12
    ax1.quiver(
        gx[::step, ::step],
        gy[::step, ::step],
        bx[::step, ::step],
        by[::step, ::step],
        color="white",
        alpha=0.55,
        scale=28,
        width=0.003,
    )

    draw_halbach_octagon(ax1, 0.045, 0.085, n_seg=8)
    ax1.set_title("Halbach array — flux concentration (2D model)", color=FG, fontsize=13, pad=10)
    ax1.set_xlabel("x [m]", color=FG)
    ax1.set_ylabel("y [m]", color=FG)
    ax1.tick_params(colors=FG)
    for spine in ax1.spines.values():
        spine.set_color(GRID)

    cbar1 = fig.colorbar(cf, ax=ax1, fraction=0.046, pad=0.02)
    cbar1.set_label("|B| [T] (normalized scale)", color=FG)
    cbar1.ax.yaxis.set_tick_params(color=FG)
    plt.setp(cbar1.ax.yaxis.get_ticklabels(), color=FG)

    # --- Panel B: Tubular linear motor slice (Figure 31d) ---
    ax2 = fig.add_subplot(gs[0, 1], facecolor=BG)
    ax2.set_aspect("equal")
    ax2.set_xlim(-0.09, 0.09)
    ax2.set_ylim(-0.09, 0.09)

    bx2, by2, bm2 = tubular_motor_flux_slice(gx, gy)
    r2 = np.sqrt(gx * gx + gy * gy)
    bm2 = np.where(r2 < 0.018, np.nan, bm2)

    cf2 = ax2.contourf(gx, gy, bm2, levels=40, cmap="inferno", norm=norm, alpha=0.9)
    ax2.contour(gx, gy, bm2, levels=12, colors="#ffd166", linewidths=0.3, alpha=0.45)

    # Stator shell
    stator = plt.Circle((0, 0), 0.055, fill=False, ec="#8899aa", lw=2)
    stator_in = plt.Circle((0, 0), 0.042, fill=False, ec="#8899aa", lw=1.2, ls="--")
    mover = plt.Circle((0, 0), 0.038, fill=False, ec="#59adff", lw=2)
    shaft = plt.Circle((0, 0), 0.018, color="#3a4048", ec="#667788", lw=1)
    ax2.add_patch(stator)
    ax2.add_patch(stator_in)
    ax2.add_patch(mover)
    ax2.add_patch(shaft)

    draw_halbach_octagon(ax2, 0.022, 0.036, n_seg=8, alpha=0.75)

    ax2.set_title("Tubular linear motor — cross-section flux", color=FG, fontsize=13, pad=10)
    ax2.set_xlabel("x [m]", color=FG)
    ax2.set_ylabel("y [m]", color=FG)
    ax2.tick_params(colors=FG)
    for spine in ax2.spines.values():
        spine.set_color(GRID)

    cbar2 = fig.colorbar(cf2, ax=ax2, fraction=0.046, pad=0.02)
    cbar2.set_label("|B| [T]", color=FG)
    cbar2.ax.yaxis.set_tick_params(color=FG)
    plt.setp(cbar2.ax.yaxis.get_ticklabels(), color=FG)

    fig.suptitle(
        "Electromagnetic Gravitational Energy Storage — Halbach Flux Analysis",
        color=FG,
        fontsize=15,
        fontweight="bold",
        y=0.98,
    )
    fig.text(
        0.5,
        0.02,
        "Dipole-superposition field model · flux vectors show Halbach one-sided concentration toward bore",
        ha="center",
        color="#8899aa",
        fontsize=9,
    )

    png = out_dir / "01_halbach_flux_field.png"
    fig.savefig(png, dpi=200, facecolor=BG, bbox_inches="tight")
    plt.close(fig)
    return png


if __name__ == "__main__":
    figure_halbach_flux(Path(__file__).resolve().parents[1] / "output")
