import * as THREE from 'three';

/** Soft air-gap glow ring — no glitchy ArrowHelpers */
export function createAirGapGlow() {
  const geo = new THREE.TorusGeometry(0.075, 0.004, 8, 48);
  const mat = new THREE.MeshBasicMaterial({
    color: 0x59adff,
    transparent: true,
    opacity: 0,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const ring = new THREE.Mesh(geo, mat);
  ring.rotation.x = Math.PI / 2;
  return ring;
}

export function updateAirGapGlow(ring, intensity, active) {
  ring.visible = active && intensity > 0.05;
  if (!ring.visible) return;
  ring.material.opacity = 0.08 + intensity * 0.35;
  ring.material.color.setHSL(0.58, 0.85, 0.45 + intensity * 0.15);
}
