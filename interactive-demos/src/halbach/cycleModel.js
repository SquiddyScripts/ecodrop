/** Halbach electromagnetic cycle — from plot_halbach_gravity_results.m */

export const CYCLE = {
  T_lift: 6.5,
  T_hold: 1.0,
  T_drop: 2.2,
  H_max: 3,
  g: 9.81,
  m_weight: 50,
  eta_lift: 0.82,
  eta_gen: 0.78,
  v_lift_max: 1.5,
  v_drop_max: 4.0,
  n_motors: 4,
};
CYCLE.T_tot = CYCLE.T_lift + CYCLE.T_hold + CYCLE.T_drop;

const PHASES = [
  {
    id: 1,
    name: 'Lift',
    title: 'Lift — Halbach thrust',
    desc: 'Four tubular linear motors (6-phase Halbach arrays) provide combined thrust. The hoist drum maintains rope tension separately.',
    css: 'phase-lift',
  },
  {
    id: 2,
    name: 'Hold',
    title: 'Hold — tension only',
    desc: 'Weight at full stroke. Linear motor thrust cuts off; hoist motor holds cable tension with stall torque.',
    css: 'phase-hold',
  },
  {
    id: 3,
    name: 'Drop',
    title: 'Drop — regeneration',
    desc: 'Weight falls under gravity. Linear motors / generator recover electrical energy through the hoist drivetrain.',
    css: 'phase-drop',
  },
];

function clamp(v, lo, hi) {
  return Math.min(Math.max(v, lo), hi);
}

export function getCycleState(t) {
  const tt = ((t % CYCLE.T_tot) + CYCLE.T_tot) % CYCLE.T_tot;
  const { T_lift, T_hold, T_drop, H_max, g, m_weight, eta_lift, eta_gen, v_lift_max, v_drop_max } = CYCLE;

  let h = 0, v = 0, thrust = 0, p_linear = 0, p_linear_elec = 0, p_hoist = 0, p_gen = 0, i_phase = 0;
  const Fg = m_weight * g;

  if (tt <= T_lift) {
    const tau = tt / T_lift;
    h = H_max * (1 - (1 - tau) ** 1.05);
    v = v_lift_max * Math.sin(Math.PI * tau);
    thrust = Math.max(Fg * (1.15 + 0.25 * Math.sin(2 * Math.PI * tau)), Fg * 1.05);
    p_linear = thrust * v;
    p_linear_elec = p_linear / eta_lift;
    p_hoist = 45;
    const phaseAngle = 2 * Math.PI * 3 * tau;
    i_phase = 12 + 8 * Math.sin(phaseAngle) * (0.7 + 0.3 * Math.sin(Math.PI * tau));
  } else if (tt <= T_lift + T_hold) {
    h = H_max;
    p_hoist = 40;
    i_phase = 5;
  } else {
    const tau = clamp((tt - T_lift - T_hold) / T_drop, 0, 1);
    h = Math.max(H_max * (1 - tau ** 1.2), 0);
    v = -v_drop_max * (1 - (1 - tau) ** 0.65);
    p_gen = Math.max(eta_gen * m_weight * g * -v, 0);
    i_phase = -8 * (1 - (1 - tau) ** 0.7);
  }

  const phase = PHASES.find((p) => p.id === (tt <= T_lift ? 1 : tt <= T_lift + T_hold ? 2 : 3));
  const p_cons = p_linear_elec + p_hoist;
  const flux = tt <= T_lift ? 0.35 + 0.65 * Math.sin(Math.PI * (tt / T_lift)) : tt <= T_lift + T_hold ? 0.12 : 0.08 + 0.25 * clamp((tt - T_lift - T_hold) / T_drop, 0, 1);

  return {
    t: tt,
    phase,
    h,
    v,
    thrust,
    p_linear,
    p_linear_elec,
    p_hoist,
    p_gen,
    p_cons,
    i_phase,
    flux,
    fillPct: 0,
    powerLabel: p_gen > 10 ? `Gen ${p_gen.toFixed(0)} W` : p_cons > 10 ? `Load ${p_cons.toFixed(0)} W` : 'Idle',
    isLifting: phase.id === 1 && v > 0.02,
    isGenerating: p_gen > 50,
    isHolding: phase.id === 2,
  };
}

export function getVisualState(state) {
  const travel = 5.65;
  const baseY = 0.18;
  let weightY = baseY + (state.h / CYCLE.H_max) * travel;

  if (state.phase.id === 3) {
    const tau = clamp((state.t - CYCLE.T_lift - CYCLE.T_hold) / CYCLE.T_drop, 0, 1);
    weightY = baseY + travel * (1 - (1 - (1 - tau) ** 2.2));
  }

  const motorStroke = 4.8;
  const moverTravel = (state.h / CYCLE.H_max) * motorStroke;

  return {
    weightY,
    drumSpeed: state.isLifting ? 0.055 : state.isGenerating ? -0.18 : state.isHolding ? 0.004 : 0.008,
    fluxIntensity: state.flux,
    coilPulse: 0.5 + 0.5 * Math.sin(state.t * 14),
    weightTilt: state.v * 0.011,
    weightPitch: state.phase.id === 3 ? -Math.abs(state.v) * 0.007 : 0,
    moverTravel,
  };
}

export { PHASES };

/** Precompute history for live charts */
export function buildHistory(n = 400) {
  const t = [];
  const thrust = [], pMotor = [], pGen = [], current = [], height = [];
  for (let i = 0; i <= n; i++) {
    const ti = (i / n) * CYCLE.T_tot;
    const s = getCycleState(ti);
    t.push(ti);
    thrust.push(s.thrust);
    pMotor.push(s.p_linear_elec + s.p_hoist);
    pGen.push(s.p_gen);
    current.push(s.i_phase);
    height.push(s.h);
  }
  return { t, thrust, pMotor, pGen, current, height };
}

export const HISTORY = buildHistory();
