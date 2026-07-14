/**
 * Clean Halbach tubular-motor field model for cross-section visualization.
 * Air-gap flux is predominantly radial (Lorentz force direction) with Halbach
 * enhancement on the strong side — not dipole soup.
 */

export const MOTOR = {
  nSeg: 8,
  Br: 1.15,
  moverR: 0.068,
  statorInner: 0.082,
  statorOuter: 0.105,
  slotCount: 12,
  airGap: 0.014,
  gapB0: 0.72,
};

export function segmentMagAngle(segIndex, nSeg = MOTOR.nSeg) {
  return ((segIndex % 4) * Math.PI) / 2;
}

function inAirGap(r) {
  return r >= MOTOR.moverR * 1.002 && r <= MOTOR.statorInner * 0.998;
}

function inStatorIron(r) {
  return r > MOTOR.statorInner && r <= MOTOR.statorOuter;
}

function inMover(r) {
  return r <= MOTOR.moverR * 0.998;
}

/** Radial air-gap B with Halbach concentration toward angle 0 (+X) */
export function fieldAt(x, y, intensity = 1) {
  const r = Math.hypot(x, y);
  const theta = Math.atan2(y, x);
  const ux = x / (r + 1e-9);
  const uy = y / (r + 1e-9);

  if (inMover(r)) {
    return { bx: 0, by: 0, bmag: 0, region: 'mover' };
  }

  if (inAirGap(r)) {
    const gapT = (r - MOTOR.moverR) / MOTOR.airGap;
    const profile = Math.sin(Math.PI * gapT);
    const halbach = 0.25 + 0.75 * Math.max(0, Math.cos(theta));
    const br = MOTOR.gapB0 * intensity * profile * halbach;
    return { bx: ux * br, by: uy * br, bmag: Math.abs(br), region: 'gap' };
  }

  if (inStatorIron(r)) {
    const tooth = Math.abs(Math.sin(theta * MOTOR.slotCount * 0.5));
    const bmag = 0.35 * intensity * (0.3 + 0.7 * tooth);
    return { bx: ux * bmag * 0.6, by: uy * bmag * 0.6, bmag, region: 'stator' };
  }

  const falloff = MOTOR.gapB0 * intensity * 0.15 * (MOTOR.statorOuter / (r + 0.02)) ** 2;
  return { bx: ux * falloff, by: uy * falloff, bmag: falloff, region: 'outside' };
}

export function sampleFieldGrid(nx, ny, intensity) {
  const R = MOTOR.statorOuter * 1.25;
  const bxGrid = new Float32Array(nx * ny);
  const byGrid = new Float32Array(nx * ny);
  const bmagGrid = new Float32Array(nx * ny);

  for (let j = 0; j < ny; j++) {
    for (let i = 0; i < nx; i++) {
      const x = -R + (2 * R * i) / (nx - 1);
      const y = -R + (2 * R * j) / (ny - 1);
      const f = fieldAt(x, y, intensity);
      const idx = j * nx + i;
      bxGrid[idx] = f.bx;
      byGrid[idx] = f.by;
      bmagGrid[idx] = f.bmag;
    }
  }
  return { bxGrid, byGrid, bmagGrid, nx, ny, R };
}

export function backEMF(t, intensity = 1) {
  return 42 * intensity * Math.sin(2 * Math.PI * 3 * t);
}

export function coggingTorque(theta) {
  return 0.35 * Math.sin(MOTOR.slotCount * theta) + 0.12 * Math.sin(MOTOR.slotCount * 2 * theta + 0.4);
}

export function bFieldColor(tNorm) {
  const t = Math.max(0, Math.min(1, tNorm));
  const stops = [
    [13, 28, 68],
    [25, 95, 140],
    [40, 160, 110],
    [180, 200, 60],
    [230, 90, 40],
  ];
  const seg = t * (stops.length - 1);
  const i = Math.min(Math.floor(seg), stops.length - 2);
  const u = seg - i;
  return stops[i].map((c, k) => Math.round(c + (stops[i + 1][k] - c) * u));
}
