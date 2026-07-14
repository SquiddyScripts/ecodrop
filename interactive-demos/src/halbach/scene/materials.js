import * as THREE from 'three';

export function createMaterials(tex = {}) {
  const steel = new THREE.MeshStandardMaterial({ color: 0x8a939f, metalness: 0.85, roughness: 0.35 });
  const steelDark = new THREE.MeshStandardMaterial({ color: 0x4a525c, metalness: 0.82, roughness: 0.4 });
  const copper = new THREE.MeshStandardMaterial({ color: 0xb87333, metalness: 0.9, roughness: 0.32 });
  const magnetN = new THREE.MeshStandardMaterial({ color: 0xd94040, metalness: 0.25, roughness: 0.45, emissive: 0x330808, emissiveIntensity: 0.15 });
  const magnetS = new THREE.MeshStandardMaterial({ color: 0x4060d9, metalness: 0.25, roughness: 0.45, emissive: 0x080833, emissiveIntensity: 0.15 });
  const coil = new THREE.MeshStandardMaterial({ color: 0xc87830, metalness: 0.75, roughness: 0.38, emissive: 0x331800, emissiveIntensity: 0.1 });
  const floorMat = new THREE.MeshStandardMaterial({ color: 0x555860, roughness: 0.92, metalness: 0.05 });
  if (tex.floorDiff) {
    floorMat.map = tex.floorDiff;
    floorMat.normalMap = tex.floorNor;
    floorMat.roughnessMap = tex.floorRough;
    floorMat.roughness = 1;
    [floorMat.map, floorMat.normalMap, floorMat.roughnessMap].forEach((t) => {
      t.wrapS = t.wrapT = THREE.RepeatWrapping;
      t.repeat.set(4, 4);
    });
  }
  return { steel, steelDark, copper, magnetN, magnetS, coil, floorMat };
}

export function fluxGlowMaterial() {
  return new THREE.MeshBasicMaterial({
    color: 0x59adff,
    transparent: true,
    opacity: 0.35,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
    side: THREE.DoubleSide,
  });
}
