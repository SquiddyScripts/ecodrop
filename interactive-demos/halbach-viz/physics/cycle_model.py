"""Halbach gravity storage cycle — aligned with plot_halbach_gravity_results.m"""

from __future__ import annotations

import numpy as np
from scipy.integrate import cumulative_trapezoid

G = 9.81
M_WEIGHT = 50.0
H_MAX = 3.0
T_LIFT = 6.5
T_HOLD = 1.0
T_DROP = 2.2
T_TOT = T_LIFT + T_HOLD + T_DROP
ETA_LIFT = 0.82
ETA_GEN = 0.78
N_MOTORS = 4


def get_cycle(t: np.ndarray) -> dict[str, np.ndarray]:
    t = np.asarray(t)
    n = t.size
    h = np.zeros(n)
    v = np.zeros(n)
    thrust = np.zeros(n)
    p_linear = np.zeros(n)
    p_linear_elec = np.zeros(n)
    p_hoist = np.zeros(n)
    p_gen = np.zeros(n)
    i_phase = np.zeros(n)
    phase_id = np.zeros(n, dtype=int)

    f_gravity = M_WEIGHT * G
    v_lift_max = 1.5
    v_drop_max = 4.0

    for i, ti in enumerate(t):
        tt = ti % T_TOT
        if tt <= T_LIFT:
            phase_id[i] = 1
            tau = tt / T_LIFT
            h[i] = H_MAX * (1 - (1 - tau) ** 1.05)
            v[i] = v_lift_max * np.sin(np.pi * tau)
            thrust[i] = max(f_gravity * (1.15 + 0.25 * np.sin(2 * np.pi * tau)), f_gravity * 1.05)
            p_linear[i] = thrust[i] * v[i]
            p_linear_elec[i] = p_linear[i] / ETA_LIFT
            p_hoist[i] = 45
            phase_angle = 2 * np.pi * 3 * tau
            i_phase[i] = 12 + 8 * np.sin(phase_angle) * (0.7 + 0.3 * np.sin(np.pi * tau))
        elif tt <= T_LIFT + T_HOLD:
            phase_id[i] = 2
            h[i] = H_MAX
            p_hoist[i] = 40
            i_phase[i] = 5
        else:
            phase_id[i] = 3
            tau = min(max((tt - T_LIFT - T_HOLD) / T_DROP, 0), 1)
            h[i] = max(H_MAX * (1 - tau ** 1.2), 0)
            v[i] = -v_drop_max * (1 - (1 - tau) ** 0.65)
            p_mech = M_WEIGHT * G * (-v[i])
            p_gen[i] = max(ETA_GEN * p_mech, 0)
            i_phase[i] = -8 * (1 - (1 - tau) ** 0.7)

    p_cons = p_linear_elec + p_hoist
    e_cons = cumulative_trapezoid(p_cons, t, initial=0)
    e_gen = cumulative_trapezoid(p_gen, t, initial=0)
    round_trip = 100 * e_gen[-1] / (e_cons[-1] + 1e-9)

    return {
        "t": t,
        "h": h,
        "v": v,
        "thrust": thrust,
        "p_linear": p_linear,
        "p_linear_elec": p_linear_elec,
        "p_hoist": p_hoist,
        "p_gen": p_gen,
        "p_cons": p_cons,
        "i_phase": i_phase,
        "phase_id": phase_id,
        "e_cons": e_cons,
        "e_gen": e_gen,
        "round_trip_pct": round_trip,
    }


def motor_thrust_scale(t: float) -> float:
    """Normalized thrust envelope for flux animation (0–1)."""
    tt = t % T_TOT
    if tt <= T_LIFT:
        tau = tt / T_LIFT
        return 0.35 + 0.65 * np.sin(np.pi * tau)
    if tt <= T_LIFT + T_HOLD:
        return 0.15
    return 0.0
