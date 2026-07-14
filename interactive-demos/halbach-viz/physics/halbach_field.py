"""Halbach array magnetic field — 2D dipole-superposition model (presentation-grade)."""

from __future__ import annotations

import numpy as np

MU0 = 4e-7 * np.pi


def dipole_field_2d(grid_x: np.ndarray, grid_y: np.ndarray, x0: float, y0: float, mx: float, my: float):
    """B-field [T] from an in-plane magnetic dipole at (x0, y0)."""
    dx = grid_x - x0
    dy = grid_y - y0
    r2 = dx * dx + dy * dy + 1e-14
    r4 = r2 * r2
    coeff = MU0 / (4 * np.pi * r4)
    bx = coeff * (2 * mx * dx * dy + my * (dx * dx - dy * dy))
    by = coeff * (2 * my * dx * dy - mx * (dx * dx - dy * dy))
    return bx, by


def halbach_ring_field(
    grid_x: np.ndarray,
    grid_y: np.ndarray,
    inner_r: float,
    outer_r: float,
    n_segments: int = 8,
    remanence: float = 1.25,
    dipoles_per_segment: int = 6,
):
    """
    Approximate a Halbach ring cross-section using oriented dipoles on inner/outer arcs.
    Magnetization rotates 90° per segment (classic Halbach pattern).
    """
    bx = np.zeros_like(grid_x)
    by = np.zeros_like(grid_y)

    for seg in range(n_segments):
        theta0 = 2 * np.pi * seg / n_segments
        theta1 = 2 * np.pi * (seg + 1) / n_segments
        # Halbach: magnetization angle advances 90° per segment
        mag_angle = seg * np.pi / 2
        mx_unit = np.cos(mag_angle)
        my_unit = np.sin(mag_angle)

        for k in range(dipoles_per_segment):
            t = theta0 + (theta1 - theta0) * (k + 0.5) / dipoles_per_segment
            for radius in (inner_r + outer_r) * 0.5, inner_r * 1.05, outer_r * 0.95:
                x0 = radius * np.cos(t)
                y0 = radius * np.sin(t)
                moment = remanence * (outer_r - inner_r) * (theta1 - theta0) * radius / dipoles_per_segment
                mx = moment * mx_unit
                my = moment * my_unit
                dbx, dby = dipole_field_2d(grid_x, grid_y, x0, y0, mx, my)
                bx += dbx
                by += dby

    bmag = np.sqrt(bx * bx + by * by)
    return bx, by, bmag


def tubular_motor_flux_slice(
    grid_x: np.ndarray,
    grid_y: np.ndarray,
    stator_outer: float = 0.055,
    stator_inner: float = 0.042,
    mover_outer: float = 0.038,
    remanence: float = 1.25,
):
    """
    Tubular linear motor cross-section (Figure 31d style):
    outer stator shell + inner Halbach mover ring.
    """
    bx_s, by_s, bm_s = halbach_ring_field(
        grid_x, grid_y, stator_inner, stator_outer, n_segments=12, remanence=remanence * 0.15
    )
    bx_m, by_m, bm_m = halbach_ring_field(
        grid_x, grid_y, mover_outer * 0.55, mover_outer, n_segments=8, remanence=remanence
    )
    bx = bx_s + bx_m
    by = by_s + by_m
    bmag = np.sqrt(bx * bx + by * by)
    return bx, by, bmag
