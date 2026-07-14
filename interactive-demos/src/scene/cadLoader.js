import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';

/**
 * Optional CAD hook — drop exported GLB files into public/models/:
 *   water-tank.glb  (export from Water Tank 400 LTR.SLDPRT)
 *   inline-pump.glb (export from Assem2.SLDASM)
 */
export async function tryLoadGltf(url, scale = 1) {
  try {
    const gltf = await new GLTFLoader().loadAsync(url);
    const root = gltf.scene;
    root.scale.setScalar(scale);
    root.traverse((o) => {
      if (o.isMesh) {
        o.castShadow = true;
        o.receiveShadow = true;
      }
    });
    return root;
  } catch {
    return null;
  }
}
