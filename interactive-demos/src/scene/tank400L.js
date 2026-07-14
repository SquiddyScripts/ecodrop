import * as THREE from 'three';

/** Procedural replica of Water Tank 400 LTR (HDPE vertical tank) */
export function createWaterTank400L(materials) {
  const group = new THREE.Group();
  const radius = 0.46;
  const height = 5.05;

  const hdpe = new THREE.MeshPhysicalMaterial({
    color: 0x2a2e34,
    roughness: 0.48,
    metalness: 0.08,
    clearcoat: 0.35,
    clearcoatRoughness: 0.4,
  });

  const shell = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius * 1.02, height, 64, 1, true),
    hdpe
  );
  shell.position.y = height / 2;
  shell.castShadow = true;
  shell.receiveShadow = true;
  group.add(shell);

  const inner = new THREE.Mesh(
    new THREE.CylinderGeometry(radius - 0.025, radius - 0.025, height - 0.08, 48, 1, true),
    new THREE.MeshPhysicalMaterial({
      color: 0x1a1e24,
      roughness: 0.55,
      metalness: 0.05,
      side: THREE.BackSide,
    })
  );
  inner.position.y = height / 2;
  group.add(inner);

  for (let i = 1; i <= 4; i++) {
    const y = (height / 5) * i;
    const band = new THREE.Mesh(
      new THREE.TorusGeometry(radius + 0.004, 0.028, 8, 64),
      materials.steelDark
    );
    band.rotation.x = Math.PI / 2;
    band.position.y = y;
    group.add(band);

    const groove = new THREE.Mesh(
      new THREE.TorusGeometry(radius - 0.012, 0.018, 6, 64),
      new THREE.MeshStandardMaterial({ color: 0x1e2228, roughness: 0.7, metalness: 0.1 })
    );
    groove.rotation.x = Math.PI / 2;
    groove.position.y = y - 0.04;
    group.add(groove);
  }

  const dome = new THREE.Mesh(
    new THREE.SphereGeometry(radius * 0.98, 48, 24, 0, Math.PI * 2, 0, Math.PI * 0.42),
    hdpe.clone()
  );
  dome.position.y = height + radius * 0.12;
  group.add(dome);

  for (let i = 0; i < 4; i++) {
    const rib = new THREE.Mesh(
      new THREE.BoxGeometry(radius * 1.05, 0.045, 0.12),
      hdpe.clone()
    );
    rib.rotation.y = (i / 4) * Math.PI * 2;
    rib.position.y = height + 0.08;
    group.add(rib);
  }

  const lidRing = new THREE.Mesh(
    new THREE.TorusGeometry(0.11, 0.022, 12, 32),
    materials.steel
  );
  lidRing.rotation.x = Math.PI / 2;
  lidRing.position.y = height + 0.14;
  group.add(lidRing);

  const baseRing = new THREE.Mesh(
    new THREE.TorusGeometry(radius * 1.04, 0.035, 8, 48),
    materials.steelDark
  );
  baseRing.rotation.x = Math.PI / 2;
  baseRing.position.y = 0.04;
  group.add(baseRing);

  group.userData.innerRadius = radius - 0.06;
  group.userData.height = height;
  return { group, radius, height, hdpe };
}

export function createWireframeCage(size, height, materials) {
  const g = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({
    color: 0xd8dee8,
    metalness: 0.85,
    roughness: 0.25,
  });

  const half = size / 2;
  const postGeo = new THREE.BoxGeometry(0.06, height, 0.06);
  for (const [x, z] of [
    [-half, -half],
    [half, -half],
    [-half, half],
    [half, half],
  ]) {
    const p = new THREE.Mesh(postGeo, mat);
    p.position.set(x, height / 2, z);
    g.add(p);
  }

  for (let i = 0; i <= 6; i++) {
    const y = (height / 6) * i;
    for (const [bx, bz, sx, sy, sz] of [
      [0, -half, size, 0.05, 0.05],
      [0, half, size, 0.05, 0.05],
      [-half, 0, 0.05, 0.05, size],
      [half, 0, 0.05, 0.05, size],
    ]) {
      const b = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), mat);
      b.position.set(bx, y, bz);
      g.add(b);
    }
  }

  return g;
}

export function createInlineTurbine(materials) {
  const g = new THREE.Group();

  const housing = new THREE.Mesh(
    new THREE.CylinderGeometry(0.16, 0.16, 0.38, 24),
    materials.steelDark
  );
  housing.rotation.z = Math.PI / 2;
  g.add(housing);

  const hub = new THREE.Mesh(
    new THREE.CylinderGeometry(0.045, 0.045, 0.12, 16),
    materials.castIron
  );
  hub.rotation.z = Math.PI / 2;
  g.add(hub);

  const blades = new THREE.Group();
  blades.name = 'turbineBlades';
  for (let i = 0; i < 7; i++) {
    const blade = new THREE.Mesh(
      new THREE.BoxGeometry(0.11, 0.025, 0.055),
      new THREE.MeshStandardMaterial({ color: 0xb8c4d0, metalness: 0.9, roughness: 0.2 })
    );
    blade.rotation.z = (i / 7) * Math.PI * 2;
    blade.position.x = 0.07;
    blade.rotation.y = (i / 7) * Math.PI * 2;
    blades.add(blade);
  }
  g.add(blades);

  const gen = new THREE.Mesh(
    new THREE.BoxGeometry(0.18, 0.18, 0.18),
    new THREE.MeshStandardMaterial({ color: 0x2d6b44, metalness: 0.4, roughness: 0.45 })
  );
  gen.name = 'turbineGen';
  gen.position.x = 0.28;
  g.add(gen);

  return { group: g, blades, generator: gen };
}

export function createInlinePump(materials) {
  const g = new THREE.Group();

  const body = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.14, 0.55, 24),
    materials.paintedBlue
  );
  body.rotation.z = Math.PI / 2;
  g.add(body);

  const motor = new THREE.Mesh(
    new THREE.CylinderGeometry(0.1, 0.1, 0.38, 20),
    materials.steelDark
  );
  motor.rotation.z = Math.PI / 2;
  motor.position.x = 0.42;
  g.add(motor);

  const flangeIn = new THREE.Mesh(
    new THREE.CylinderGeometry(0.075, 0.075, 0.04, 20),
    materials.steel
  );
  flangeIn.rotation.z = Math.PI / 2;
  flangeIn.position.x = -0.3;
  g.add(flangeIn);

  const flangeOut = flangeIn.clone();
  flangeOut.position.x = 0.3;
  g.add(flangeOut);

  g.userData.spinParts = [body];
  return g;
}

/** Straight horizontal pipe segment through the tank wall */
export function createThroughPipe(length, radius, materials) {
  const g = new THREE.Group();

  const pipe = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius, length, 20),
    materials.steel.clone()
  );
  pipe.rotation.z = Math.PI / 2;
  pipe.castShadow = true;
  g.add(pipe);

  for (const x of [-length / 2, length / 2]) {
    const flange = new THREE.Mesh(
      new THREE.CylinderGeometry(radius * 2.2, radius * 2.2, 0.025, 20),
      materials.steel
    );
    flange.rotation.z = Math.PI / 2;
    flange.position.x = x;
    g.add(flange);
  }

  return g;
}

export function createHeavyWeight(materials) {
  const g = new THREE.Group();
  g.renderOrder = 20;

  const buoy = new THREE.Mesh(
    new THREE.CylinderGeometry(0.28, 0.3, 0.78, 32),
    new THREE.MeshStandardMaterial({
      color: 0xff6b2b,
      emissive: 0x441800,
      emissiveIntensity: 0.35,
      roughness: 0.42,
      metalness: 0.15,
    })
  );
  buoy.position.y = 0.39;
  buoy.castShadow = true;
  g.add(buoy);

  for (let i = 0; i < 8; i++) {
    const rib = new THREE.Mesh(
      new THREE.BoxGeometry(0.035, 0.65, 0.52),
      new THREE.MeshStandardMaterial({ color: 0xcc5522, roughness: 0.5 })
    );
    rib.rotation.y = (i / 8) * Math.PI;
    rib.position.y = 0.39;
    g.add(rib);
  }

  const mass = new THREE.Mesh(
    new THREE.BoxGeometry(0.38, 0.62, 0.38),
    new THREE.MeshStandardMaterial({
      color: 0x3a4048,
      metalness: 0.82,
      roughness: 0.28,
      emissive: 0x101010,
      emissiveIntensity: 0.15,
    })
  );
  mass.position.y = 1.08;
  mass.castShadow = true;
  g.add(mass);

  const eye = new THREE.Mesh(
    new THREE.TorusGeometry(0.06, 0.014, 8, 20),
    materials.steel
  );
  eye.rotation.x = Math.PI / 2;
  eye.position.y = 1.42;
  g.add(eye);

  const shoeMat = new THREE.MeshStandardMaterial({ color: 0x99aabb, metalness: 0.92, roughness: 0.18 });
  for (const [x, z] of [
    [0.3, 0.24],
    [-0.3, 0.24],
    [0.3, -0.24],
    [-0.3, -0.24],
  ]) {
    const shoe = new THREE.Mesh(new THREE.BoxGeometry(0.09, 0.16, 0.07), shoeMat);
    shoe.position.set(x, 0.18, z);
    g.add(shoe);
  }

  g.userData.ropeAttach = new THREE.Vector3(0, 1.48, 0);
  g.userData.buoyantCenter = 0.39;
  g.userData.totalHeight = 1.52;
  return g;
}

export function createWinchDeck(materials, y) {
  const g = new THREE.Group();
  g.position.y = y;

  const deck = new THREE.Mesh(
    new THREE.BoxGeometry(1.35, 0.12, 1.0),
    materials.steelDark
  );
  deck.position.y = 0.06;
  g.add(deck);

  const drum = new THREE.Mesh(
    new THREE.CylinderGeometry(0.16, 0.16, 0.32, 32),
    materials.steel
  );
  drum.rotation.z = Math.PI / 2;
  drum.position.set(0, 0.28, 0);
  drum.name = 'drum';
  g.add(drum);

  const motor = new THREE.Mesh(
    new THREE.BoxGeometry(0.38, 0.28, 0.28),
    materials.steelDark
  );
  motor.position.set(-0.42, 0.26, 0);
  g.add(motor);

  const generator = new THREE.Mesh(
    new THREE.BoxGeometry(0.32, 0.28, 0.32),
    new THREE.MeshStandardMaterial({ color: 0x2d6b44, metalness: 0.45, roughness: 0.4 })
  );
  generator.position.set(0.42, 0.26, 0);
  generator.name = 'generator';
  g.add(generator);

  return { group: g, drum, generator };
}

export function createBasinTank(radius, depth, materials) {
  const g = new THREE.Group();
  const shell = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius * 1.05, depth, 48, 1, true),
    new THREE.MeshPhysicalMaterial({
      color: 0x6a7684,
      metalness: 0.75,
      roughness: 0.35,
      transparent: true,
      opacity: 0.35,
      side: THREE.DoubleSide,
      depthWrite: false,
    })
  );
  shell.position.y = depth / 2;
  g.add(shell);

  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(radius - 0.02, 48),
    materials.steelDark
  );
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = 0.02;
  g.add(floor);

  return { group: g, radius, depth };
}

export function createPedestalTank(radius, tankH, pedestalH, materials) {
  const g = new THREE.Group();

  const pedestal = new THREE.Mesh(
    new THREE.BoxGeometry(1.05, pedestalH, 1.05),
    materials.steelDark
  );
  pedestal.position.y = pedestalH / 2;
  pedestal.castShadow = true;
  g.add(pedestal);

  const tank = new THREE.Mesh(
    new THREE.CylinderGeometry(radius, radius, tankH, 48, 1, true),
    new THREE.MeshPhysicalMaterial({
      color: 0x7a8592,
      metalness: 0.82,
      roughness: 0.32,
      transparent: true,
      opacity: 0.32,
      side: THREE.DoubleSide,
      depthWrite: false,
    })
  );
  tank.position.y = pedestalH + tankH / 2;
  g.add(tank);

  for (let i = 1; i <= 2; i++) {
    const ring = new THREE.Mesh(
      new THREE.TorusGeometry(radius + 0.01, 0.018, 8, 48),
      materials.steel
    );
    ring.rotation.x = Math.PI / 2;
    ring.position.y = pedestalH + (tankH / 3) * i;
    g.add(ring);
  }

  return { group: g, radius, tankH, pedestalH, topY: pedestalH + tankH };
}
