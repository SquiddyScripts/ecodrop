/**
 * Buoyancy gravity battery cycle — ported from plot_buoyancy_gravity_results.m
 */

import * as THREE from 'three';
import { WEIGHT } from './scene/constants.js';

export const CYCLE = {
  T_lift: 25,
  T_water: 18,
  T_drop: 3.2,
  H_max: 3,
  g: 9.81,
  m_weight: 50,
  buoyancy_fraction: 0.55,
  eta_gen: 0.74,
};

CYCLE.T_tot = CYCLE.T_lift + CYCLE.T_water + CYCLE.T_drop;

const PHASES = [
  {
    id: 1,
    name: 'Lift',
    title: 'Lift — water fills chamber',
    desc: 'Water enters through the lower through-pipe from the top reservoir. Buoyancy lifts the weight as the chamber fills.',
    start: 0,
    end: CYCLE.T_lift,
  },
  {
    id: 2,
    name: 'Water transfer',
    title: 'Drain — turbine spins',
    desc: 'The weight stays at the top. Chamber water drains through the through-pipe, spinning the inline turbine into the bottom sump.',
    start: CYCLE.T_lift,
    end: CYCLE.T_lift + CYCLE.T_water,
  },
  {
    id: 3,
    name: 'Drop',
    title: 'Drop — generation',
    desc: 'With the chamber empty, the weight falls with momentum and drives the hoist generator.',
    start: CYCLE.T_lift + CYCLE.T_water,
    end: CYCLE.T_tot,
  },
];

function clamp(v, lo, hi) {
  return Math.min(Math.max(v, lo), hi);
}

export function getPhase(t) {
  const tt = ((t % CYCLE.T_tot) + CYCLE.T_tot) % CYCLE.T_tot;
  return PHASES.find((p) => tt >= p.start && tt < p.end) ?? PHASES[PHASES.length - 1];
}

export function getCycleState(t) {
  const tt = ((t % CYCLE.T_tot) + CYCLE.T_tot) % CYCLE.T_tot;
  const { T_lift, T_water, T_drop, H_max, g, m_weight, buoyancy_fraction, eta_gen } = CYCLE;

  let h_weight = 0;
  let v_weight = 0;
  let fill_chamber = 0;
  let level_top = 1;
  let level_bottom = 0.1;
  let P_motor = 0;
  let P_pump = 0;
  let P_gen = 0;

  const v_lift_max = 0.65;
  const v_drop_max = 4.2;
  const P_lift_base = m_weight * g * v_lift_max * 0.6;

  if (tt <= T_lift) {
    const tau_l = tt / T_lift;
    fill_chamber = Math.min(1 - Math.exp(-3 * tau_l), 1);
    h_weight = H_max * (1 - (1 - tau_l) ** 1.1);
    v_weight = v_lift_max * 4 * tau_l * (1 - tau_l);
    level_top = 1 - 0.85 * tau_l;
    level_bottom = 0.1 + 0.15 * tau_l;
    P_motor = Math.max(
      P_lift_base * (1 - buoyancy_fraction * fill_chamber) * (4 * tau_l * (1 - tau_l) + 0.2),
      50
    );
  } else if (tt <= T_lift + T_water) {
    const tau_w = clamp((tt - T_lift) / T_water, 0, 1);
    h_weight = H_max;
    v_weight = 0;
    fill_chamber = Math.max(1 - 0.95 * (1 - (1 - tau_w) ** 0.9), 0.05);
    level_top = Math.min(0.15 + 0.8 * tau_w ** 1.2, 1);
    level_bottom = Math.min(0.25 + 0.65 * tau_w, 0.9);

    const pump_frac = 0.6;
    const pump_on = tau_w >= 1 - pump_frac;
    const arg = clamp((tau_w - (1 - pump_frac)) / pump_frac, 0, 1);
    P_pump = pump_on ? Math.max(200 + 150 * Math.sin(Math.PI * arg), 0) : 0;
  } else {
    const tau_d = clamp((tt - T_lift - T_water) / T_drop, 0, 1);
    h_weight = Math.max(H_max * (1 - tau_d ** 1.25), 0);
    v_weight = -v_drop_max * (1 - (1 - tau_d) ** 0.7);
    fill_chamber = 0.02;
    level_top = 0.98;
    level_bottom = Math.max(0.9 - 0.7 * tau_d, 0.15);
    const P_mech_drop = m_weight * g * -v_weight;
    P_gen = Math.max(eta_gen * P_mech_drop, 0);
  }

  const phase = getPhase(tt);
  const P_cons = P_motor + P_pump;
  const powerLabel =
    P_gen > 10 ? `Gen ${P_gen.toFixed(0)} W` : P_cons > 10 ? `Load ${P_cons.toFixed(0)} W` : 'Idle';

  const tau_w_now = tt > T_lift ? clamp((tt - T_lift) / T_water, 0, 1) : 0;
  const drainRate =
    phase.id === 2 ? clamp((1 - fill_chamber) * 4 + tau_w_now * 0.5, 0, 4) : 0;

  return {
    t: tt,
    phase,
    h_weight,
    v_weight,
    fill_chamber,
    level_top,
    level_bottom,
    P_motor,
    P_pump,
    P_gen,
    P_cons,
    powerLabel,
    fillPct: fill_chamber * 100,
    topPct: level_top * 100,
    bottomPct: level_bottom * 100,
    isPumping: P_pump > 50,
    isGenerating: P_gen > 50,
    isLifting: phase.id === 1 && v_weight > 0.01,
    isDraining: phase.id === 2 && fill_chamber > 0.08,
    drainRate,
  };
}

export { PHASES };

/** Visual coupling — buoyancy, momentum fall, turbine/drain motion */
export function getVisualState(state) {
  const baseY = 0.15;
  const travel = WEIGHT.travel;
  const chamberMax = 5.05 - 0.2;

  const waterH = state.fill_chamber * chamberMax;
  const waterSurfaceY = 0.1 + waterH;

  let weightY = baseY + (state.h_weight / CYCLE.H_max) * travel;

  if (state.phase.id === 1) {
    const submerged = THREE.MathUtils.clamp(waterSurfaceY / WEIGHT.draft, 0, 1);
    const buoyLift = submerged * CYCLE.buoyancy_fraction * travel;
    const floatY = baseY + buoyLift;
    weightY = THREE.MathUtils.lerp(floatY, baseY + (state.h_weight / CYCLE.H_max) * travel, 0.25 + submerged * 0.55);
  } else if (state.phase.id === 2) {
    weightY = baseY + travel;
  } else if (state.phase.id === 3) {
    const t = state.t - CYCLE.T_lift - CYCLE.T_water;
    const tau = THREE.MathUtils.clamp(t / CYCLE.T_drop, 0, 1);
    const accelFall = 1 - (1 - tau) ** 2.2;
    weightY = baseY + travel * (1 - accelFall);
  }

  const drainSwirl = state.isDraining ? state.drainRate * 0.35 + 0.35 : 0;

  return {
    weightY,
    chamberFill: state.fill_chamber,
    topFill: state.level_top,
    bottomFill: state.level_bottom,
    waterHeight: waterH,
    waterSwirl: drainSwirl,
    bubbleRate: state.phase.id === 1 ? state.fill_chamber * 1.2 : 0,
    waterFlowSpeed: state.phase.id === 1 ? 1.4 : state.isDraining ? 2.2 : 0.6,
    showInletFlow: state.phase.id === 1 && state.fill_chamber < 0.98,
    showDrainFlow: state.isDraining && state.drainRate > 0.01,
    showReturnFlow: state.isPumping,
    drumSpeed: state.isLifting ? 0.055 : state.isGenerating ? -0.2 : 0.006,
    turbineSpeed: state.isDraining ? state.drainRate * 0.12 + 0.06 : 0,
    weightTilt: state.v_weight * 0.012,
    weightPitch: state.phase.id === 3 ? -Math.abs(state.v_weight) * 0.008 : 0,
  };
}
