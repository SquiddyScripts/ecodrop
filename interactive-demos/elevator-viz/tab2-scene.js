/**
 * Variable counterweight tab — clean assembly from whole CAD solids.
 */
window.initTab2Scene = function initTab2Scene(S) {
  // Keep rope refs if re-init; clear everything else on t2Root
  const keep = new Set([window.ropeT2A, window.ropeT2B].filter(Boolean));
  for (let i = t2Root.children.length - 1; i >= 0; i--) {
    if (!keep.has(t2Root.children[i])) t2Root.remove(t2Root.children[i]);
  }

  if (!S.cab || !S.barbell || !S.varcwt) {
    throw new Error('Missing CAD solids — check assets/ and use a local server');
  }

  const M2 = {
    frame: M.steelDk,
    beam: M.steelDk,
    rail: M.rail,
    cab: M.car,
    cabTrim: M.steel,
    cw: M.cw,
    cwPlate: M.cwPlate,
    barbell: M.cwPlate,
    station: M.housing,
    shaft: M.steelDk,
    rope: M.rope,
    drum: M.drum,
    rollerWheel: M.gen,
    rollerArm: M.gearA,
    ramFrame: M.steelDk,
    ramSheave: M.drum,
    accent: M.gearC,
  };

  /** Build mesh from centered STL geometry. */
  function cadMesh(solid, material, targetSize, upAxis) {
    if (!solid || !solid.geo) return null;
    const mat = material.clone();
    mat.side = THREE.DoubleSide;
    const mesh = new THREE.Mesh(solid.geo, mat);
    mesh.castShadow = true;
    mesh.receiveShadow = true;

    const sz = solid.size.slice();
    const scale = targetSize / solid.maxSpan;
    mesh.scale.setScalar(scale);

    if (upAxis === 2) mesh.rotation.x = -Math.PI / 2;

    let h, w, d;
    if (upAxis === 2) {
      h = sz[2] * scale;
      w = sz[0] * scale;
      d = sz[1] * scale;
    } else if (upAxis === 0) {
      w = sz[0] * scale;
      h = sz[1] * scale;
      d = sz[2] * scale;
    } else {
      h = sz[1] * scale;
      w = sz[0] * scale;
      d = sz[2] * scale;
    }
    return { mesh, h, w, d, scale };
  }

  function box2(w, h, d, mat, x, y, z, parent = t2Root) {
    const o = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
    o.position.set(x, y, z);
    o.castShadow = true;
    o.receiveShadow = true;
    parent.add(o);
    return o;
  }

  // ─── Hoistway (matches tab-1 proportions) ───
  const halfW = 1.05;
  const halfD = 0.95;
  const frame = new THREE.Group();
  t2Root.add(frame);

  [[halfW, halfD], [-halfW, halfD], [halfW, -1.1], [-halfW, -1.1]].forEach(([x, z]) => {
    box2(0.1, V.H, 0.1, M2.frame, x, V.H / 2, z, frame);
  });
  [0.2, V.H - 0.12, V.H * 0.5].forEach((y) => {
    box2(2.3, 0.1, 0.1, M2.beam, 0, y, halfD, frame);
    box2(2.3, 0.1, 0.1, M2.beam, 0, y, -1.1, frame);
    box2(0.1, 0.1, 2.15, M2.beam, halfW, y, -0.08, frame);
    box2(0.1, 0.1, 2.15, M2.beam, -halfW, y, -0.08, frame);
  });
  box2(2.35, 0.2, 2.2, M2.beam, 0, V.H + 0.08, -0.08, frame);

  [0.92, -0.92].forEach((x) => box2(0.06, V.H - 0.5, 0.1, M2.rail, x, V.H / 2, V.carZ, frame));
  [0.32, -0.32].forEach((x) => box2(0.05, V.H - 0.5, 0.1, M2.rail, x, V.H / 2, V.cwZ, frame));

  const sheave = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.28, 0.16, 32), M2.drum);
  sheave.rotation.z = Math.PI / 2;
  sheave.position.set(0, V.H - 0.06, (V.carZ + V.cwZ) / 2);
  sheave.castShadow = true;
  frame.add(sheave);

  // ─── Elevator car (cab STL: Z-up in file → Y-up in scene) ───
  const carGroup = new THREE.Group();
  t2Root.add(carGroup);

  const cab = cadMesh(S.cab, M2.cab, V.carH, S.cab.upAxis);
  if (cab) {
    cab.mesh.position.y = cab.h / 2;
    carGroup.add(cab.mesh);
  }

  const ramGrp = new THREE.Group();
  carGroup.add(ramGrp);
  ramGrp.position.set(0, V.carH + 0.02, 0);
  const ram = cadMesh(S.ram, M2.ramFrame, 1.25, S.ram.upAxis);
  if (ram) {
    ramGrp.add(ram.mesh);
    ram.mesh.position.y = ram.h * 0.15;
  }

  function addRoller(side) {
    const g = new THREE.Group();
    const rg = cadMesh(S.roller, M2.rollerArm, 0.38, S.roller.upAxis);
    if (rg) g.add(rg.mesh);
    g.position.set(side * (V.carW / 2 + 0.14), V.carH * 0.42, 0);
    g.rotation.y = side > 0 ? -Math.PI / 2 : Math.PI / 2;
    carGroup.add(g);
  }
  addRoller(1);
  addRoller(-1);

  carGroup.position.set(0, V.carMid - V.carH / 2, V.carZ);

  // ─── Counterweight column (behind car) ───
  const cwtCol = new THREE.Group();
  t2Root.add(cwtCol);
  cwtCol.position.set(0, 0, V.cwZ);

  const baseH = 0.45;
  box2(0.64, baseH, 0.52, M2.cw, 0, baseH / 2, 0, cwtCol);

  const bbTargetH = 0.28;
  const barbellStack = new THREE.Group();
  cwtCol.add(barbellStack);
  barbellStack.position.y = baseH + 0.02;

  const stationGrp = new THREE.Group();
  cwtCol.add(stationGrp);
  const station = cadMesh(S.varcwt, M2.station, 0.92, S.varcwt.upAxis);
  if (station) {
    station.mesh.position.y = station.h / 2;
    stationGrp.add(station.mesh);
  }
  stationGrp.position.y = baseH + 0.15;

  const shaftVis = new THREE.Mesh(
    new THREE.CylinderGeometry(0.012, 0.012, 0.35, 12),
    new THREE.MeshStandardMaterial({ color: 0x2a323a, metalness: 0.8, roughness: 0.5 })
  );
  shaftVis.position.y = baseH + 0.55;
  cwtCol.add(shaftVis);

  function makeBarbell() {
    const g = new THREE.Group();
    const bb = cadMesh(S.barbell, M2.barbell, bbTargetH, S.barbell.upAxis);
    if (bb) {
      bb.mesh.position.y = bb.h / 2;
      g.add(bb.mesh);
      g.userData.bbH = bb.h;
    }
    return g;
  }

  const activeBarbells = [];
  function layoutStack() {
    let y = 0;
    activeBarbells.forEach((b) => {
      b.position.set(0, y, 0);
      y += b.userData.bbH || bbTargetH + 0.02;
    });
    stationGrp.position.y = baseH + 0.08 + y;
    shaftVis.position.y = baseH + 0.2 + y * 0.5;
    shaftVis.scale.y = Math.max(0.2, y * 0.5);
  }

  const storage = new THREE.Group();
  t2Root.add(storage);
  storage.position.set(0.7, V.H - 0.55, V.cwZ - 0.2);
  box2(0.95, 0.05, 0.45, M2.accent, 0, 0.38, 0, storage);
  box2(0.95, 0.05, 0.45, M2.cwPlate, 0, -0.02, 0, storage);

  const storageBarbells = [];
  for (let i = 0; i < V.maxBarbells; i++) {
    const b = makeBarbell();
    b.rotation.z = Math.PI / 2;
    b.position.set(-0.35 + (i % 4) * 0.24, i < 4 ? 0.48 : 0.12, 0);
    storage.add(b);
    storageBarbells.push(b);
  }

  const flightBarbell = makeBarbell();
  flightBarbell.visible = false;
  t2Root.add(flightBarbell);

  const spinInner = station && station.mesh;
  stationGrp.userData.spinMesh = spinInner;

  const Vs = window.Vs;
  Vs.paxCycle = 0;
  Vs.demoTimer = 0;
  Vs.camTrack = null;

  function targetBarbellsFor(pax) {
    return Math.max(0, Math.min(V.maxBarbells, Math.round((pax * V.paxMass) / V.barbellMass)));
  }

  function updateStorageVisibility() {
    storageBarbells.forEach((b, i) => {
      b.visible = i >= activeBarbells.length;
    });
  }

  function startTransfer(dir) {
    Vs.transferring = true;
    Vs.transferT = 0;
    Vs.transferDir = dir;
    Vs.rotarySpinSpeed = 5.5;
    Vs.camTrack = dir > 0 ? 'drop' : 'rotary';
    if (dir > 0) {
      const src = storageBarbells.find((b) => b.visible);
      if (src) src.visible = false;
      flightBarbell.visible = true;
      flightBarbell.rotation.set(0, 0, 0);
      storage.getWorldPosition(flightBarbell.position);
      flightBarbell.position.y = V.H - 0.45;
    } else {
      activeBarbells.pop();
      layoutStack();
      flightBarbell.visible = true;
      flightBarbell.rotation.set(0, 0, 0);
      cwtCol.localToWorld(flightBarbell.position.set(0, stationGrp.position.y, 0));
    }
  }

  window.requestAdjust = function requestAdjust() {
    Vs.targetN = targetBarbellsFor(Vs.paxCount);
    if (Vs.targetN > activeBarbells.length && !Vs.transferring) startTransfer(1);
    else if (Vs.targetN < activeBarbells.length && !Vs.transferring) startTransfer(-1);
  };

  window.tickTransfer = function tickTransfer(dt) {
    if (!Vs.transferring) return;
    const dur = 2.6;
    Vs.transferT += dt;
    const t = Math.min(1, Vs.transferT / dur);
    const stackTop = baseH + 0.15;
    let stackY = stackTop;
    activeBarbells.forEach((b) => {
      stackY += (b.userData.bbH || bbTargetH) + 0.02;
    });
    const dropY = cwtCol.position.y + stackY;
    const intakeY = cwtCol.position.y + stationGrp.position.y + 0.05;
    const storageY = V.H - 0.45;

    if (Vs.transferDir > 0) {
      if (t < 0.25) {
        const k = t / 0.25;
        flightBarbell.position.lerpVectors(
          new THREE.Vector3(storage.position.x, storageY, storage.position.z),
          new THREE.Vector3(0, intakeY, V.cwZ),
          k
        );
      } else if (t < 0.45) {
        flightBarbell.position.set(0, intakeY - 0.08 * ((t - 0.25) / 0.2), V.cwZ);
      } else {
        const k = (t - 0.45) / 0.55;
        flightBarbell.position.set(0, intakeY * (1 - k) + dropY * k, V.cwZ);
        Vs.energy += V.barbellMass * 9.81 * 0.04 * dt;
      }
      if (t >= 1) {
        Vs.transferring = false;
        Vs.rotarySpinSpeed = 0;
        Vs.camTrack = null;
        flightBarbell.visible = false;
        const nb = makeBarbell();
        barbellStack.add(nb);
        activeBarbells.push(nb);
        layoutStack();
        updateStorageVisibility();
        if (Vs.targetN !== activeBarbells.length) setTimeout(requestAdjust, 600);
      }
    } else {
      if (t < 0.4) {
        const k = t / 0.4;
        flightBarbell.position.set(0, dropY * (1 - k) + intakeY * k, V.cwZ);
      } else if (t < 0.6) {
        flightBarbell.position.set(0, intakeY + 0.1 * ((t - 0.4) / 0.2), V.cwZ);
      } else {
        const k = (t - 0.6) / 0.4;
        flightBarbell.position.lerpVectors(
          new THREE.Vector3(0, intakeY, V.cwZ),
          new THREE.Vector3(storage.position.x, storageY, storage.position.z),
          k
        );
      }
      if (t >= 1) {
        Vs.transferring = false;
        Vs.rotarySpinSpeed = 0;
        Vs.camTrack = null;
        flightBarbell.visible = false;
        const slot = storageBarbells.find((b) => !b.visible);
        if (slot) slot.visible = true;
        updateStorageVisibility();
        if (Vs.targetN !== activeBarbells.length) setTimeout(requestAdjust, 600);
      }
    }
    stationGrp.rotation.y += Vs.rotarySpinSpeed * dt;
  };

  window.tickTab2Motion = function tickTab2Motion(dt) {
    const carM = V.carEmpty + Vs.paxCount * V.paxMass;
    const cwtM = V.baseCwt + activeBarbells.length * V.barbellMass;
    const delta = cwtM - carM;
    if (!Vs.transferring) {
      const target = V.carMid + Math.sign(delta) * Math.min(Math.abs(delta) * 0.004, V.travel / 2);
      Vs.cabY += (target - Vs.cabY) * Math.min(1, dt * 1.1);
      Vs.cwtY = V.H - 0.5 - (Vs.cabY - V.carMid) - V.carH / 2 - 1.2;
    }
    carGroup.position.y = Vs.cabY - V.carH / 2;
    cwtCol.position.y = Math.max(0.8, Vs.cwtY);

    const el = document.getElementById('d2_status');
    if (Vs.transferring) el.textContent = Vs.transferDir > 0 ? 'Deploying barbell ↓' : 'Retrieving barbell ↑';
    else if (Math.abs(delta) > V.barbellMass * 0.4) el.textContent = 'Rebalancing…';
    else el.textContent = 'Balanced';
    document.getElementById('d2_pax').textContent = Vs.paxCount;
    document.getElementById('d2_load').textContent = carM.toFixed(0) + ' kg';
    document.getElementById('d2_target').textContent = cwtM.toFixed(0) + ' kg';
    document.getElementById('d2_n').textContent = activeBarbells.length + (Vs.transferring ? ' (±1)' : '');
    document.getElementById('d2_egy').textContent = (Vs.energy / 3600).toFixed(2) + ' Wh';

    const topY = V.H - 0.04;
    const carTop = carGroup.position.y + V.carH + 0.2;
    const cwTop = cwtCol.position.y + stationGrp.position.y + (station ? station.h * 0.5 : 0.5);
    setRopeT2(ropeT2A, topY, carTop, V.cabRopeX, V.carZ);
    setRopeT2(ropeT2B, topY, cwTop, V.cwRopeX, V.cwZ);
  };

  window.tickTab2Demo = function tickTab2Demo(dt) {
    if (paused2 || Vs.transferring) return;
    Vs.demoTimer += dt;
    if (Vs.demoTimer > 5) {
      Vs.demoTimer = 0;
      Vs.paxCycle = (Vs.paxCycle + 1) % 14;
      Vs.paxCount = Vs.paxCycle <= 7 ? Vs.paxCycle : 14 - Vs.paxCycle;
      requestAdjust();
    }
  };

  window.tickTab2Cam = function tickTab2Cam() {
    if (Vs.camTrack === 'drop' && flightBarbell.visible) {
      const wp = new THREE.Vector3();
      flightBarbell.getWorldPosition(wp);
      controls.target.lerp(wp, 0.07);
      controls.radius += (2.4 - controls.radius) * 0.05;
    } else if (Vs.camTrack === 'rotary') {
      const wp = new THREE.Vector3(0, cwtCol.position.y + stationGrp.position.y, V.cwZ);
      controls.target.lerp(wp, 0.06);
    }
  };

  layoutStack();
  updateStorageVisibility();
  requestAdjust();

  window.cams2 = {
    over: { t: [0, 4.8, 0.2], th: 0.55, phi: 1.08, r: 13 },
    cwt: { t: [0, V.carMid, V.cwZ], th: 0.6, phi: 1.15, r: 4.8 },
    rotary: { t: [0.4, V.H - 0.8, V.cwZ], th: 0.65, phi: 0.95, r: 2.6 },
    drop: { t: [0.15, V.carMid + 0.5, V.cwZ], th: 0.72, phi: 1.02, r: 3.0 },
    mech: { t: [0.45, V.H - 1.0, V.cwZ], th: 0.78, phi: 0.9, r: 2.0 },
    cab: { t: [0, V.carMid, V.carZ + 0.9], th: 0.68, phi: 1.08, r: 5.5 },
    cross: { t: [0, V.carMid, 0], th: Math.PI / 2, phi: 1.18, r: 9 },
  };

  TAGS2 = [
    {
      txt: 'Rotary discharge station',
      cls: 'green',
      p: () =>
        new THREE.Vector3(
          0.35,
          cwtCol.position.y + stationGrp.position.y + (station ? station.h * 0.5 : 0.5),
          V.cwZ
        ),
    },
    {
      txt: 'Modular barbell masses',
      cls: 'amber',
      p: () => new THREE.Vector3(0.5, cwtCol.position.y + baseH + 0.5, V.cwZ),
    },
    {
      txt: 'Cabled base mass',
      cls: '',
      p: () => new THREE.Vector3(-0.45, cwtCol.position.y + baseH / 2, V.cwZ),
    },
    {
      txt: 'Storage rack',
      cls: '',
      p: () => new THREE.Vector3(storage.position.x + 0.5, storage.position.y, storage.position.z),
    },
    {
      txt: 'Cab + ram head',
      cls: '',
      p: () => new THREE.Vector3(0, carGroup.position.y + V.carH + 0.7, V.carZ + 0.75),
    },
  ];

  if (typeof buildTagEls2 === 'function') buildTagEls2();

  console.log('[tab2] CAD loaded:', {
    cab: S.cab.maxSpan,
    barbell: S.barbell.maxSpan,
    varcwt: S.varcwt.maxSpan,
    ram: S.ram.maxSpan,
    roller: S.roller.maxSpan,
  });
};
