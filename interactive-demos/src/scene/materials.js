import * as THREE from 'three';

export function createMaterials(textures = {}) {
  const steel = new THREE.MeshStandardMaterial({
    color: 0x8a939f,
    metalness: 0.82,
    roughness: 0.38,
  });

  const steelDark = steel.clone();
  steelDark.color.setHex(0x4f5864);

  const paintedBlue = new THREE.MeshStandardMaterial({
    color: 0x1f5f99,
    metalness: 0.55,
    roughness: 0.42,
  });

  const paintedOrange = new THREE.MeshStandardMaterial({
    color: 0xd85a2a,
    metalness: 0.35,
    roughness: 0.48,
  });

  const castIron = new THREE.MeshStandardMaterial({
    color: 0x3a3f46,
    metalness: 0.7,
    roughness: 0.55,
  });

  const polycarbonate = new THREE.MeshPhysicalMaterial({
    color: 0xa8c4dd,
    metalness: 0,
    roughness: 0.12,
    transmission: 0.55,
    thickness: 0.15,
    transparent: true,
    opacity: 0.35,
    side: THREE.DoubleSide,
    depthWrite: false,
  });

  const ropeMat = new THREE.MeshStandardMaterial({
    color: 0xc8cdd4,
    metalness: 0.15,
    roughness: 0.75,
  });

  const floorMat = new THREE.MeshStandardMaterial({
    color: 0x555860,
    metalness: 0.05,
    roughness: 0.92,
  });

  if (textures.floorDiff) {
    floorMat.map = textures.floorDiff;
    floorMat.normalMap = textures.floorNor;
    floorMat.roughnessMap = textures.floorRough;
    floorMat.roughness = 1;
    [floorMat.map, floorMat.normalMap, floorMat.roughnessMap].forEach((t) => {
      t.wrapS = t.wrapT = THREE.RepeatWrapping;
      t.repeat.set(4, 4);
    });
  }

  return { steel, steelDark, paintedBlue, paintedOrange, castIron, polycarbonate, ropeMat, floorMat };
}

export function pipeMaterial() {
  return new THREE.MeshStandardMaterial({
    color: 0x6a7684,
    metalness: 0.75,
    roughness: 0.35,
  });
}

export function flangeMaterial() {
  return new THREE.MeshStandardMaterial({
    color: 0x7d8794,
    metalness: 0.85,
    roughness: 0.3,
  });
}
