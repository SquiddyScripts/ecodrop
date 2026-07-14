import * as THREE from 'three';
import { DIM } from './constants.js';
import { createMaterials } from './materials.js';
import { createTubularMotor, createFluxParticles, updateFluxParticles } from './tubularMotor.js';
import { updateAirGapGlow } from './fluxVectors3D.js';
import { getVisualState } from '../cycleModel.js';

function makeCallout(text, color = '#e8ecf2') {
  const c = document.createElement('canvas');
  c.width = 640;
  c.height = 128;
  const ctx = c.getContext('2d');
  ctx.fillStyle = 'rgba(8,10,16,0.82)';
  ctx.strokeStyle = 'rgba(255,255,255,0.15)';
  ctx.lineWidth = 2;
  roundRect(ctx, 10, 10, 620, 108, 14);
  ctx.fill();
  ctx.stroke();
  ctx.fillStyle = color;
  ctx.font = '600 34px Segoe UI';
  ctx.textAlign = 'center';
  ctx.fillText(text, 320, 68);
  const tex = new THREE.CanvasTexture(c);
  tex.colorSpace = THREE.SRGBColorSpace;
  const sp = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false }));
  sp.scale.set(2.4, 0.48, 1);
  return sp;
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

function createWeight(mat) {
  const g = new THREE.Group();
  const plate = new THREE.Mesh(
    new THREE.BoxGeometry(0.52, 0.08, 0.52),
    mat.steel
  );
  plate.position.y = 0.04;
  g.add(plate);

  const mass = new THREE.Mesh(
    new THREE.BoxGeometry(0.44, 0.58, 0.44),
    new THREE.MeshStandardMaterial({ color: 0x3a4048, metalness: 0.88, roughness: 0.25, emissive: 0x101010, emissiveIntensity: 0.2 })
  );
  mass.position.y = 0.37;
  mass.castShadow = true;
  g.add(mass);

  const cap = new THREE.Mesh(
    new THREE.CylinderGeometry(0.1, 0.12, 0.07, 20),
    mat.steelDark
  );
  cap.position.y = 0.72;
  g.add(cap);

  for (const [x, z] of [[0.28, 0.22], [-0.28, 0.22], [0.28, -0.22], [-0.28, -0.22]]) {
    const shoe = new THREE.Mesh(new THREE.BoxGeometry(0.07, 0.12, 0.06), mat.steel);
    shoe.position.set(x, 0.1, z);
    g.add(shoe);
  }

  g.userData.ropeAttach = new THREE.Vector3(0, 0.78, 0);
  return g;
}

function createWinch(mat) {
  const g = new THREE.Group();
  g.position.y = DIM.baseY + DIM.winchY;

  const deck = new THREE.Mesh(new THREE.BoxGeometry(1.6, 0.14, 1.2), mat.steelDark);
  deck.position.y = 0.07;
  deck.castShadow = true;
  g.add(deck);

  const tensionMotor = new THREE.Mesh(
    new THREE.BoxGeometry(0.42, 0.32, 0.32),
    mat.steelDark
  );
  tensionMotor.position.set(-0.55, 0.32, 0);
  g.add(tensionMotor);

  const gearbox = new THREE.Mesh(new THREE.BoxGeometry(0.32, 0.28, 0.32), mat.steel);
  gearbox.position.set(-0.15, 0.3, 0);
  g.add(gearbox);

  const drum = new THREE.Mesh(
    new THREE.CylinderGeometry(0.17, 0.17, 0.36, 32),
    mat.steel
  );
  drum.rotation.z = Math.PI / 2;
  drum.position.set(0.2, 0.34, 0);
  drum.name = 'drum';
  g.add(drum);

  for (let i = 0; i < 7; i++) {
    const g2 = new THREE.Mesh(
      new THREE.TorusGeometry(0.155, 0.007, 6, 28),
      mat.steelDark
    );
    g2.rotation.y = Math.PI / 2;
    g2.position.set(0.2 + (i - 3) * 0.042, 0.34, 0);
    g.add(g2);
  }

  const generator = new THREE.Mesh(
    new THREE.BoxGeometry(0.38, 0.32, 0.38),
    new THREE.MeshStandardMaterial({ color: 0x2d6b44, metalness: 0.45, roughness: 0.4 })
  );
  generator.position.set(0.62, 0.32, 0);
  generator.name = 'generator';
  g.add(generator);

  const sheave = new THREE.Mesh(
    new THREE.TorusGeometry(0.09, 0.015, 10, 28),
    mat.copper
  );
  sheave.rotation.y = Math.PI / 2;
  sheave.position.set(0.2, 0.1, 0);
  g.add(sheave);

  return { group: g, drum, generator, tensionMotor };
}

function createFrame(mat) {
  const g = new THREE.Group();
  const h = DIM.towerH;
  const s = 0.95;
  const postGeo = new THREE.BoxGeometry(0.07, h, 0.07);
  for (const [x, z] of [[-s, -s], [s, -s], [-s, s], [s, s]]) {
    const p = new THREE.Mesh(postGeo, mat.steel);
    p.position.set(x, DIM.baseY + h / 2, z);
    p.castShadow = true;
    g.add(p);
  }
  for (let i = 0; i <= 5; i++) {
    const y = DIM.baseY + (h / 5) * i;
    for (const [bx, bz, sx, sy, sz] of [
      [0, -s, s * 2, 0.06, 0.06],
      [0, s, s * 2, 0.06, 0.06],
      [-s, 0, 0.06, 0.06, s * 2],
      [s, 0, 0.06, 0.06, s * 2],
    ]) {
      const b = new THREE.Mesh(new THREE.BoxGeometry(sx, sy, sz), mat.steelDark);
      b.position.set(bx, y, bz);
      g.add(b);
    }
  }
  return g;
}

function createPowerCables(mat, motorPositions) {
  const g = new THREE.Group();
  const top = new THREE.Vector3(0, DIM.baseY + DIM.winchY + 0.05, 0);
  for (const [mx, mz] of motorPositions) {
    const end = new THREE.Vector3(mx, DIM.baseY + DIM.towerH - 0.2, mz);
    const mid = top.clone().lerp(end, 0.5);
    mid.y += 0.35;
    const curve = new THREE.CatmullRomCurve3([top, mid, end], false, 'catmullrom', 0.35);
    const tube = new THREE.Mesh(
      new THREE.TubeGeometry(curve, 24, 0.012, 8, false),
      mat.copper
    );
    g.add(tube);
  }
  return g;
}

export function buildHalbachTower(scene, textures) {
  const mat = createMaterials(textures);
  const root = new THREE.Group();
  scene.add(root);

  const floor = new THREE.Mesh(new THREE.PlaneGeometry(22, 18), mat.floorMat);
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  root.add(floor);

  const pad = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.12, 2.4), mat.steelDark);
  pad.position.y = 0.06;
  pad.receiveShadow = true;
  root.add(pad);

  root.add(createFrame(mat));

  const motors = [];
  const fluxSystems = [];
  DIM.motorPositions.forEach(([x, z], i) => {
    const m = createTubularMotor(mat, i);
    m.position.set(x, 0, z);
    root.add(m);
    motors.push(m);
    const particles = createFluxParticles(80);
    particles.position.set(x, 0, z);
    root.add(particles);
    fluxSystems.push({ particles, pos: [x, z], motor: m });
  });

  const weight = createWeight(mat);
  weight.position.set(0, DIM.baseY + 0.18, 0);
  root.add(weight);

  const winch = createWinch(mat);
  root.add(winch.group);

  const rope = new THREE.Mesh(
    new THREE.CylinderGeometry(0.011, 0.011, 1, 8),
    new THREE.MeshStandardMaterial({ color: 0xc8cdd4, roughness: 0.7 })
  );
  root.add(rope);

  root.add(createPowerCables(mat, DIM.motorPositions));

  const labels = new THREE.Group();
  const callouts = [
    { t: '8-seg Halbach mover (90°/seg)', p: [0.75, 3.5, 0.55], c: '#ff804d' },
    { t: '12-slot stator · 6-phase coils', p: [-0.75, 2.8, 0.55], c: '#f2bf40' },
    { t: 'Air-gap flux (lift phase)', p: [0.55, 4.2, -0.75], c: '#59adff' },
    { t: 'Tension hoist motor', p: [-0.95, DIM.winchY + 0.55, 0.35], c: '#8899aa' },
    { t: 'Generator / regen', p: [1.05, DIM.winchY + 0.5, 0.35], c: '#66d98c' },
    { t: '50 kg payload', p: [0.65, 1.2, 0.55], c: '#ebebf0' },
  ];
  for (const c of callouts) {
    const s = makeCallout(c.t, c.c);
    s.position.set(...c.p);
    labels.add(s);
  }
  root.add(labels);

  return {
    root,
    motors,
    fluxSystems,
    weight,
    rope,
    drum: winch.drum,
    generator: winch.generator,
    tensionMotor: winch.tensionMotor,
    labels,

    update(state, simTime) {
      const vis = getVisualState(state);

      weight.position.y = vis.weightY;
      weight.rotation.z = vis.weightTilt;
      weight.rotation.x = vis.weightPitch;
      weight.updateMatrixWorld(true);

      const attach = weight.userData.ropeAttach.clone();
      weight.localToWorld(attach);
      const ropeTop = new THREE.Vector3(0.2, DIM.baseY + DIM.winchY + 0.1, 0);
      const mid = ropeTop.clone().lerp(attach, 0.5);
      mid.x += 0.06;
      const curve = new THREE.CatmullRomCurve3([ropeTop, mid, attach], false, 'catmullrom', 0.35);
      rope.geometry.dispose();
      rope.geometry = new THREE.TubeGeometry(curve, 20, 0.011, 8, false);

      winch.drum.rotation.x += vis.drumSpeed;
      winch.generator.material.emissive = new THREE.Color(state.isGenerating ? 0x1a5533 : 0x000000);
      winch.generator.material.emissiveIntensity = state.isGenerating ? 0.95 : 0;
      winch.tensionMotor.material.emissive = new THREE.Color(
        state.isLifting || state.isHolding ? 0x222228 : 0x000000
      );
      winch.tensionMotor.material.emissiveIntensity = state.isLifting || state.isHolding ? 0.35 : 0;

      const fluxOn = state.phase.id === 1 && vis.fluxIntensity > 0.1;
      for (const fs of fluxSystems) {
        const m = fs.motor;
        m.userData.fluxShell.material.opacity = 0.05 + vis.fluxIntensity * 0.25;
        m.userData.gapRing.material.opacity = 0.1 + vis.fluxIntensity * 0.35;
        m.userData.mover.position.y = vis.moverTravel - 2.4;
        for (const ring of m.userData.coilRings) {
          ring.material.emissiveIntensity = 0.08 + vis.coilPulse * vis.fluxIntensity * 0.55;
        }
        updateFluxParticles(fs.particles, fs.pos, vis.fluxIntensity, simTime, fluxOn);
        updateAirGapGlow(m.userData.airGapGlow, vis.fluxIntensity, fluxOn);
      }
    },

    setXray(on) {
      for (const m of motors) {
        m.userData.statorShell.material.opacity = on ? 0.12 : 0.42;
      }
    },

    setLabelsVisible(v) {
      labels.visible = v;
    },

    setFluxVisible(v) {
      for (const fs of fluxSystems) {
        fs.particles.visible = v;
        fs.motor.userData.fluxShell.visible = v;
        fs.motor.userData.gapRing.visible = v;
        if (fs.motor.userData.airGapGlow) fs.motor.userData.airGapGlow.visible = v;
      }
    },
  };
}
