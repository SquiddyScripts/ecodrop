import * as THREE from 'three';

/** Procedural water normal map — used if /assets/textures/water_normal.jpg is missing */
export function createProceduralWaterNormals(size = 256) {
  const data = new Uint8Array(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4;
      const nx = Math.sin(x * 0.08) * 0.35 + Math.sin(y * 0.11) * 0.25;
      const ny = Math.cos(y * 0.09) * 0.35 + Math.cos(x * 0.1) * 0.25;
      data[i] = Math.floor((nx * 0.5 + 0.5) * 255);
      data[i + 1] = Math.floor((ny * 0.5 + 0.5) * 255);
      data[i + 2] = 255;
      data[i + 3] = 255;
    }
  }
  const tex = new THREE.DataTexture(data, size, size, THREE.RGBAFormat);
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.needsUpdate = true;
  return tex;
}

export async function loadTexture(loader, url) {
  try {
    return await loader.loadAsync(url);
  } catch {
    return null;
  }
}
