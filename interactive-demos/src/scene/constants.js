/** Scene dimensions — 1 unit ≈ 0.5 m */
export const DIM = {
  baseY: 0.12,
  chamber: { radius: 0.46, height: 5.05 },
  cage: { size: 1.2, height: 5.55 },
  winchY: 5.72,
  throughPipeY: 0.62,
  throughPipeZ: 0,
  pipeR: 0.042,
  topTank: { x: 3.15, z: 0, pedestalH: 4.35, radius: 0.52, tankH: 1.05 },
  bottomBasin: { x: -3.05, z: 0, radius: 0.72, depth: 0.55 },
  pump: { x: -3.05, y: 0.38, z: 0.85 },
};

export const WEIGHT = {
  buoyantH: 0.78,
  massH: 0.62,
  width: 0.6,
  draft: 0.68,
  travel: 4.55,
};
