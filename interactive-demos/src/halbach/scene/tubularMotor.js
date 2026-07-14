import * as THREE from 'three';
import { fluxGlowMaterial } from './materials.js';
import { DIM } from './constants.js';
import { segmentMagAngle } from '../physics/halbachFieldModel.js';
import { createAirGapGlow } from './fluxVectors3D.js';

/** Detailed tubular linear motor — Halbach mover, slotted stator, copper windings */
export function createTubularMotor(materials, index) {
  const root = new THREE.Group();
  const motorH = DIM.towerH - 0.35;
  const y0 = 0.15;

  const statorOuter = 0.105;
  const statorInner = 0.082;
  const moverR = 0.068;

  const statorShell = new THREE.Mesh(
    new THREE.CylinderGeometry(statorOuter, statorOuter, motorH, 48, 1, true),
    new THREE.MeshPhysicalMaterial({
      color: 0x6a7580,
      metalness: 0.88,
      roughness: 0.28,
      transparent: true,
      opacity: 0.38,
      side: THREE.DoubleSide,
      depthWrite: false,
    })
  );
  statorShell.position.y = y0 + motorH / 2;
  statorShell.name = 'statorShell';
  root.add(statorShell);

  for (let i = 0; i <= 10; i++) {
    const y = y0 + (motorH / 10) * i;
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(statorOuter + 0.008, 0.011, 8, 40),
      materials.steel
    );
    ring.rotation.x = Math.PI / 2;
    ring.position.y = y;
    root.add(ring);
  }

  for (let s = 0; s < 12; s++) {
    const ang = (s / 12) * Math.PI * 2;
    const tooth = new THREE.Mesh(
      new THREE.BoxGeometry(0.016, motorH * 0.94, 0.014),
      materials.steelDark
    );
    tooth.position.set(Math.sin(ang) * (statorInner + 0.006), y0 + motorH / 2, Math.cos(ang) * (statorInner + 0.006));
    tooth.lookAt(0, y0 + motorH / 2, 0);
    root.add(tooth);
  }

  const moverGroup = new THREE.Group();
  moverGroup.name = 'mover';
  moverGroup.position.y = y0 + motorH / 2;

  const nSeg = 8;
  for (let i = 0; i < nSeg; i++) {
    const ang0 = (i / nSeg) * Math.PI * 2;
    const ang1 = ((i + 1) / nSeg) * Math.PI * 2;
    const mid = (ang0 + ang1) / 2;
    const magAngle = segmentMagAngle(i, nSeg);
    const isNorth = i % 2 === 0;

    const seg = new THREE.Mesh(
      new THREE.BoxGeometry(0.052, motorH * 0.9, 0.022),
      isNorth ? materials.magnetN : materials.magnetS
    );
    seg.position.set(Math.sin(mid) * moverR, 0, Math.cos(mid) * moverR);
    seg.lookAt(0, 0, 0);
    seg.rotateY(Math.PI / 2);
    seg.userData.magAngle = magAngle;
    moverGroup.add(seg);
  }

  const backIron = new THREE.Mesh(
    new THREE.CylinderGeometry(0.026, 0.026, motorH * 0.94, 20),
    materials.steelDark
  );
  moverGroup.add(backIron);
  root.add(moverGroup);

  for (let c = 0; c < 6; c++) {
    const cy = y0 + 0.35 + c * (motorH / 6);
    const coilRing = new THREE.Mesh(
      new THREE.TorusGeometry(statorInner - 0.006, 0.01, 8, 32),
      materials.coil.clone()
    );
    coilRing.rotation.x = Math.PI / 2;
    coilRing.position.y = cy;
    coilRing.name = 'coilRing';
    root.add(coilRing);
  }

  const gapRing = new THREE.Mesh(
    new THREE.TorusGeometry((statorInner + moverR) / 2, 0.003, 6, 48),
    new THREE.MeshBasicMaterial({ color: 0x59adff, transparent: true, opacity: 0.35 })
  );
  gapRing.rotation.x = Math.PI / 2;
  gapRing.position.y = y0 + motorH / 2;
  gapRing.name = 'gapRing';
  root.add(gapRing);

  const airGapGlow = createAirGapGlow();
  airGapGlow.position.y = y0 + motorH / 2;
  root.add(airGapGlow);

  const fluxShell = new THREE.Mesh(
    new THREE.CylinderGeometry(moverR + 0.018, moverR + 0.018, motorH * 0.92, 48, 1, true),
    fluxGlowMaterial()
  );
  fluxShell.position.y = y0 + motorH / 2;
  fluxShell.name = 'fluxShell';
  root.add(fluxShell);

  const label = makeMotorLabel(`TLM ${index + 1} · Halbach`);
  label.position.set(statorOuter + 0.15, y0 + motorH + 0.25, 0);
  root.add(label);

  root.userData.coilRings = root.children.filter((c) => c.name === 'coilRing');
  root.userData.fluxShell = fluxShell;
  root.userData.statorShell = statorShell;
  root.userData.mover = moverGroup;
  root.userData.gapRing = gapRing;
  root.userData.airGapGlow = airGapGlow;
  return root;
}

function makeMotorLabel(text) {
  const c = document.createElement('canvas');
  c.width = 320;
  c.height = 64;
  const ctx = c.getContext('2d');
  ctx.fillStyle = 'rgba(8,10,16,0.85)';
  ctx.fillRect(0, 0, 320, 64);
  ctx.fillStyle = '#59adff';
  ctx.font = '600 22px Segoe UI';
  ctx.textAlign = 'center';
  ctx.fillText(text, 160, 40);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false }));
  sp.scale.set(0.95, 0.22, 1);
  return sp;
}

export function createFluxParticles(count = 120) {
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);
  const phase = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    phase[i] = Math.random();
  }
  geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  geo.userData.phase = phase;

  const mat = new THREE.PointsMaterial({
    color: 0x59adff,
    size: 0.018,
    transparent: true,
    opacity: 0.5,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  return new THREE.Points(geo, mat);
}

export function updateFluxParticles(points, motorPos, intensity, time, active) {
  if (!active || intensity < 0.05) {
    points.visible = false;
    return;
  }
  points.visible = true;
  const attr = points.geometry.attributes.position;
  const phases = points.geometry.userData.phase;
  const [mx, mz] = motorPos;
  const gapR = 0.075;
  for (let i = 0; i < attr.count; i++) {
    const p = phases[i];
    const ang = p * Math.PI * 2;
    const y = 0.6 + ((p + time * 0.15) % 1) * 5.0;
    attr.setXYZ(i, mx + Math.cos(ang) * gapR, y, mz + Math.sin(ang) * gapR);
  }
  attr.needsUpdate = true;
  points.material.opacity = 0.15 + intensity * 0.35;
}

