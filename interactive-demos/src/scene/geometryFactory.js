import * as THREE from 'three';
import { Water } from 'three/examples/jsm/objects/Water.js';
import { flangeMaterial, pipeMaterial } from './materials.js';

/**
 * Realistic liquid volume: transmission body + animated Water surface.
 * Sized to fit inside a container without clipping.
 */
export class LiquidVolume {
  constructor({
    width,
    depth,
    maxHeight,
    inset = 0.06,
    scene,
    sunDirection,
    waterNormals,
    shape = 'box',
    radius,
  }) {
    this.maxHeight = maxHeight;
    this.inset = inset;
    this.shape = shape;
    this.innerW = width - inset * 2;
    this.innerD = depth - inset * 2;
    this.radius = radius ?? Math.min(this.innerW, this.innerD) * 0.48;
    this.group = new THREE.Group();

    const bodyGeo =
      shape === 'cylinder'
        ? new THREE.CylinderGeometry(this.radius, this.radius, 1, 48)
        : new THREE.BoxGeometry(this.innerW, 1, this.innerD);

    this.body = new THREE.Mesh(
      bodyGeo,
      new THREE.MeshPhysicalMaterial({
        color: 0x0d5f9f,
        transparent: true,
        opacity: 0.58,
        transmission: 0.78,
        thickness: 1.4,
        roughness: 0.06,
        metalness: 0,
        ior: 1.33,
        depthWrite: false,
      })
    );
    this.body.renderOrder = 2;

    const surfaceSize =
      shape === 'cylinder' ? this.radius * 2.05 : Math.max(this.innerW, this.innerD);
    const geo = new THREE.CircleGeometry(surfaceSize * 0.5, 64);
    this.surface = new Water(geo, {
      textureWidth: 512,
      textureHeight: 512,
      waterNormals,
      sunDirection: sunDirection.clone(),
      sunColor: 0xffffff,
      waterColor: 0x0a4a78,
      distortionScale: 3.2,
      fog: scene.fog !== undefined,
    });
    this.surface.rotation.x = -Math.PI / 2;
    this.surface.renderOrder = 3;

    this.meniscus = this.makeMeniscusRing();

    this.swirlGroup = new THREE.Group();
    this.swirlGroup.add(this.body);
    this.swirlGroup.add(this.surface);
    this.swirlGroup.add(this.meniscus);
    this.group.add(this.swirlGroup);

    this.bubbles = this.makeBubbles();
    this.group.add(this.bubbles.points);
  }

  makeBubbles() {
    const count = 36;
    const positions = new Float32Array(count * 3);
    const phases = new Float32Array(count);
    for (let i = 0; i < count; i++) {
      phases[i] = Math.random();
      positions[i * 3 + 1] = 0.05;
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geo.userData.phases = phases;
    const points = new THREE.Points(
      geo,
      new THREE.PointsMaterial({
        color: 0x9fdcff,
        size: 0.035,
        transparent: true,
        opacity: 0.75,
        depthWrite: false,
        blending: THREE.AdditiveBlending,
      })
    );
    points.visible = false;
    points.renderOrder = 5;
    return { points, geo };
  }

  makeMeniscusRing() {
    const ringR = this.shape === 'cylinder' ? this.radius * 0.98 : Math.min(this.innerW, this.innerD) * 0.46;
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(ringR, 0.014, 8, 64),
      new THREE.MeshPhysicalMaterial({
        color: 0x4db8ff,
        transparent: true,
        opacity: 0.7,
        transmission: 0.45,
        roughness: 0.04,
        depthWrite: false,
      })
    );
    ring.rotation.x = Math.PI / 2;
    ring.renderOrder = 4;
    this.meniscus = ring;
    return ring;
  }

  setLevel(fraction, time = 0, opts = {}) {
    const f = THREE.MathUtils.clamp(fraction, 0.01, 1);
    const h = Math.max(f * this.maxHeight, 0.04);
    const { swirl = 0, bubbleRate = 0, flowSpeed = 1 } = opts;

    this.body.scale.y = h;
    this.body.position.y = h / 2;

    this.surface.position.y = h + 0.002;
    this.meniscus.position.y = h + 0.004;

    if (this.surface.material.uniforms?.time) {
      this.surface.material.uniforms.time.value = time * flowSpeed;
    }
    if (this.surface.material.uniforms?.distortionScale) {
      this.surface.material.uniforms.distortionScale.value = 2.5 + swirl * 4 + bubbleRate * 2;
    }

    this.swirlGroup.rotation.y = time * swirl * 1.8;

    this.animateBubbles(h, time, bubbleRate);

    this.level = h;
    return h;
  }

  animateBubbles(waterH, time, rate) {
    if (rate <= 0.01) {
      this.bubbles.points.visible = false;
      return;
    }
    this.bubbles.points.visible = true;
    const pos = this.bubbles.geo.attributes.position;
    const phases = this.bubbles.geo.userData.phases;
    const spread = this.shape === 'cylinder' ? this.radius * 0.75 : this.innerW * 0.42;
    for (let i = 0; i < pos.count; i++) {
      const t = (phases[i] + time * (0.25 + rate * 0.5)) % 1;
      pos.setXYZ(
        i,
        Math.sin(phases[i] * 40 + time) * spread * 0.35,
        t * waterH * 0.95 + 0.05,
        Math.cos(phases[i] * 33 + time) * spread * 0.35
      );
    }
    pos.needsUpdate = true;
  }
}

export function createPipeRun(points, radius = 0.055, mat = pipeMaterial()) {
  const curve = new THREE.CatmullRomCurve3(points, false, 'catmullrom', 0.35);
  const mesh = new THREE.Mesh(
    new THREE.TubeGeometry(curve, 64, radius, 16, false),
    mat
  );
  mesh.castShadow = true;
  mesh.receiveShadow = true;
  return { mesh, curve, points };
}

export function createFlange(position, normal, radius = 0.11) {
  const g = new THREE.Group();
  const disc = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius, 0.03, 24),
    flangeMaterial()
  );
  const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), normal.clone().normalize());
  disc.quaternion.copy(q);
  disc.position.copy(position);
  g.add(disc);

  for (let i = 0; i < 6; i++) {
    const bolt = new THREE.Mesh(
      new THREE.CylinderGeometry(0.008, 0.008, 0.04, 8),
      flangeMaterial()
    );
    const ang = (i / 6) * Math.PI * 2;
    const offset = new THREE.Vector3(Math.cos(ang) * radius * 0.75, 0, Math.sin(ang) * radius * 0.75);
    offset.applyQuaternion(q);
    bolt.position.copy(position).add(offset);
    bolt.quaternion.copy(q);
    g.add(bolt);
  }
  return g;
}

export function createSteelTank({ radius, height, mat, shellOpacity = 0.22 }) {
  const group = new THREE.Group();

  const shell = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius, height, 48, 1, true),
    new THREE.MeshPhysicalMaterial({
      color: 0x7a8592,
      metalness: 0.88,
      roughness: 0.32,
      transparent: true,
      opacity: shellOpacity,
      side: THREE.DoubleSide,
      depthWrite: false,
    })
  );
  shell.position.y = height / 2;
  group.add(shell);

  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(radius - 0.02, 48),
    mat.steelDark
  );
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = 0.02;
  group.add(floor);

  for (let i = 1; i <= 3; i++) {
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(radius + 0.015, 0.025, 8, 64),
      mat.steel
    );
    ring.rotation.x = Math.PI / 2;
    ring.position.y = (height / 3) * i;
    group.add(ring);
  }

  const legs = 4;
  for (let i = 0; i < legs; i++) {
    const ang = (i / legs) * Math.PI * 2 + Math.PI / 4;
    const leg = new THREE.Mesh(new THREE.BoxGeometry(0.08, height * 0.45, 0.08), mat.steelDark);
    leg.position.set(Math.cos(ang) * (radius + 0.12), height * 0.22, Math.sin(ang) * (radius + 0.12));
    group.add(leg);
  }

  return { group, shell, radius, height };
}

export function createCentrifugalPump(mat) {
  const g = new THREE.Group();

  const volute = new THREE.Mesh(
    new THREE.TorusGeometry(0.18, 0.08, 16, 32, Math.PI * 1.35),
    mat.paintedBlue
  );
  volute.rotation.x = Math.PI / 2;
  volute.rotation.z = Math.PI * 0.15;
  g.add(volute);

  const casing = new THREE.Mesh(
    new THREE.CylinderGeometry(0.14, 0.16, 0.22, 24),
    mat.paintedBlue
  );
  casing.rotation.z = Math.PI / 2;
  g.add(casing);

  const motor = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.12, 0.42, 24),
    mat.steelDark
  );
  motor.rotation.z = Math.PI / 2;
  motor.position.x = 0.34;
  g.add(motor);

  const coupling = new THREE.Mesh(
    new THREE.CylinderGeometry(0.055, 0.055, 0.08, 16),
    mat.castIron
  );
  coupling.rotation.z = Math.PI / 2;
  coupling.position.x = 0.16;
  g.add(coupling);

  const inlet = new THREE.Mesh(new THREE.CylinderGeometry(0.045, 0.045, 0.12, 12), mat.steel);
  inlet.position.set(-0.08, 0.12, 0);
  g.add(inlet);

  const outlet = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 0.14, 12), mat.steel);
  outlet.rotation.x = Math.PI / 2;
  outlet.position.set(0, 0.18, 0.1);
  g.add(outlet);

  g.userData.spinParts = [volute, casing];
  return g;
}

export function createWeightAssembly(mat) {
  const g = new THREE.Group();

  const buoyShell = new THREE.Mesh(
    new THREE.CylinderGeometry(0.28, 0.3, 0.72, 32),
    mat.paintedOrange
  );
  buoyShell.position.y = 0.36;
  buoyShell.castShadow = true;
  g.add(buoyShell);

  for (let i = 0; i < 6; i++) {
    const rib = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.62, 0.55),
      mat.paintedOrange.clone()
    );
    rib.material.color.multiplyScalar(0.85);
    rib.rotation.y = (i / 6) * Math.PI;
    rib.position.y = 0.36;
    g.add(rib);
  }

  const mass = new THREE.Mesh(
    new THREE.BoxGeometry(0.42, 0.55, 0.42),
    mat.castIron
  );
  mass.position.y = 0.98;
  mass.castShadow = true;
  g.add(mass);

  const cap = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.14, 0.08, 20),
    mat.steel
  );
  cap.position.y = 1.32;
  g.add(cap);

  const shoeGeo = new THREE.BoxGeometry(0.1, 0.14, 0.08);
  const shoeMat = mat.steel.clone();
  shoeMat.metalness = 0.92;
  const shoePos = [
    [0.31, 0.2, 0.22],
    [-0.31, 0.2, 0.22],
    [0.31, 0.2, -0.22],
    [-0.31, 0.2, -0.22],
  ];
  for (const [x, y, z] of shoePos) {
    const shoe = new THREE.Mesh(shoeGeo, shoeMat);
    shoe.position.set(x, y, z);
    g.add(shoe);
  }

  g.userData.ropeAttach = new THREE.Vector3(0, 1.38, 0);
  g.userData.buoyantCenter = 0.36;
  g.userData.totalHeight = 1.42;
  return g;
}

export function createTowerFrame(mat, dim) {
  const g = new THREE.Group();
  const h = dim.towerHeight;
  const outer = dim.towerOuter;
  const inner = dim.chamberInner;

  const beam = (sx, sy, sz, bx, by, bz) => {
    const m = new THREE.Mesh(new THREE.BoxGeometry(bx, by, bz), mat.steel);
    m.position.set(sx, sy, sz);
    m.castShadow = true;
    g.add(m);
  };

  const half = outer / 2;
  const posts = [
    [-half, h / 2, -half],
    [half, h / 2, -half],
    [-half, h / 2, half],
    [half, h / 2, half],
  ];
  for (const [x, y, z] of posts) beam(x, y, z, 0.1, h, 0.1);

  for (let i = 0; i <= 5; i++) {
    const y = (h / 5) * i + 0.1;
    beam(0, y, -half, outer, 0.08, 0.08);
    beam(-half, y, 0, 0.08, 0.08, outer);
    beam(half, y, 0, 0.08, 0.08, outer);
    beam(0, y, half, outer, 0.08, 0.08);
  }

  const chamber = new THREE.Mesh(
    new THREE.BoxGeometry(inner, h - 0.15, inner),
    mat.polycarbonate.clone()
  );
  chamber.position.y = h / 2;
  chamber.name = 'chamberGlass';
  g.add(chamber);

  const railInset = inner / 2 - 0.07;
  for (const sx of [-railInset, railInset]) {
    for (const sz of [-railInset, railInset]) {
      const rail = new THREE.Mesh(
        new THREE.BoxGeometry(0.045, h - 0.35, 0.045),
        mat.steel.clone()
      );
      rail.material.color.setHex(0xaab4c0);
      rail.position.set(sx, h / 2, sz);
      g.add(rail);
    }
  }

  const dryChannel = new THREE.Mesh(
    new THREE.BoxGeometry(dim.annulusWidth, h - 0.2, inner * 0.55),
    new THREE.MeshStandardMaterial({
      color: 0x2a3038,
      metalness: 0.2,
      roughness: 0.85,
      transparent: true,
      opacity: 0.15,
    })
  );
  dryChannel.position.set(inner / 2 + dim.annulusWidth / 2 + 0.04, h / 2, 0);
  g.add(dryChannel);

  return { group: g, chamberMat: chamber.material, chamberInner: inner };
}

export function createWinchAssembly(mat, y) {
  const g = new THREE.Group();
  g.position.y = y;

  const deck = new THREE.Mesh(
    new THREE.BoxGeometry(2.4, 0.14, 1.6),
    mat.steelDark
  );
  deck.position.y = 0.07;
  deck.castShadow = true;
  g.add(deck);

  const motor = new THREE.Mesh(
    new THREE.BoxGeometry(0.55, 0.42, 0.42),
    mat.steelDark
  );
  motor.position.set(-0.75, 0.38, 0);
  g.add(motor);

  const gearbox = new THREE.Mesh(
    new THREE.BoxGeometry(0.38, 0.32, 0.38),
    mat.castIron
  );
  gearbox.position.set(-0.2, 0.36, 0);
  g.add(gearbox);

  const drum = new THREE.Mesh(
    new THREE.CylinderGeometry(0.22, 0.22, 0.42, 32),
    mat.steel
  );
  drum.rotation.z = Math.PI / 2;
  drum.position.set(0.35, 0.42, 0);
  drum.name = 'drum';
  g.add(drum);

  for (let i = 0; i < 8; i++) {
    const groove = new THREE.Mesh(
      new THREE.TorusGeometry(0.2, 0.008, 6, 32),
      mat.steelDark
    );
    groove.rotation.y = Math.PI / 2;
    groove.position.set(0.35 + (i - 4) * 0.045, 0.42, 0);
    g.add(groove);
  }

  const generator = new THREE.Mesh(
    new THREE.BoxGeometry(0.48, 0.38, 0.48),
    new THREE.MeshStandardMaterial({ color: 0x3d7a52, metalness: 0.45, roughness: 0.42 })
  );
  generator.position.set(0.95, 0.36, 0);
  generator.name = 'generator';
  g.add(generator);

  const sheave = new THREE.Mesh(
    new THREE.TorusGeometry(0.11, 0.018, 12, 32),
    mat.steel
  );
  sheave.rotation.y = Math.PI / 2;
  sheave.position.set(0.35, 0.12, 0);
  g.add(sheave);

  return { group: g, drum, generator };
}

export function createFlowSystem(count, color) {
  const geo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const phases = new Float32Array(count);
  for (let i = 0; i < count; i++) {
    phases[i] = Math.random();
  }
  geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  geo.userData.phases = phases;

  const mat = new THREE.PointsMaterial({
    color,
    size: 0.045,
    transparent: true,
    opacity: 0.9,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
  });
  return new THREE.Points(geo, mat);
}

export function animateFlowAlongCurve(pointsObj, curve, time, speed = 0.35, active = true) {
  if (!active || !curve) {
    pointsObj.visible = false;
    return;
  }
  pointsObj.visible = true;
  const pos = pointsObj.geometry.attributes.position;
  const phases = pointsObj.geometry.userData.phases;
  for (let i = 0; i < pos.count; i++) {
    const t = (phases[i] + time * speed) % 1;
    const p = curve.getPoint(t);
    const tan = curve.getTangent(t);
    pos.setXYZ(i, p.x + tan.y * 0.02, p.y, p.z + tan.z * 0.02);
  }
  pos.needsUpdate = true;
}

export function makeCallout(text, color = '#e8ecf2') {
  const canvas = document.createElement('canvas');
  canvas.width = 640;
  canvas.height = 160;
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = 'rgba(8,10,16,0.82)';
  ctx.strokeStyle = 'rgba(255,255,255,0.18)';
  ctx.lineWidth = 2;
  roundRect(ctx, 10, 10, 620, 140, 18);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = color;
  ctx.font = '600 38px Segoe UI, system-ui, sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, 320, 80);
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  const sprite = new THREE.Sprite(
    new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false })
  );
  sprite.scale.set(2.8, 0.7, 1);
  return sprite;
}

function roundRect(ctx, x, y, w, h, r) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}
