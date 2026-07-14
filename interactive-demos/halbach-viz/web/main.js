import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

const CYCLE = { T_lift: 6.5, T_hold: 1.0, T_drop: 2.2, H_max: 3, m: 50, g: 9.81 };
CYCLE.T_tot = CYCLE.T_lift + CYCLE.T_hold + CYCLE.T_drop;

function cycleState(t) {
  const tt = ((t % CYCLE.T_tot) + CYCLE.T_tot) % CYCLE.T_tot;
  let h = 0, v = 0, thrust = 0, phase = 1, flux = 0.3;
  const Fg = CYCLE.m * CYCLE.g;
  if (tt <= CYCLE.T_lift) {
    phase = 1;
    const tau = tt / CYCLE.T_lift;
    h = CYCLE.H_max * (1 - (1 - tau) ** 1.05);
    v = 1.5 * Math.sin(Math.PI * tau);
    thrust = Math.max(Fg * (1.15 + 0.25 * Math.sin(2 * Math.PI * tau)), Fg * 1.05);
    flux = 0.4 + 0.6 * Math.sin(Math.PI * tau);
  } else if (tt <= CYCLE.T_lift + CYCLE.T_hold) {
    phase = 2;
    h = CYCLE.H_max;
    flux = 0.15;
    thrust = 0;
  } else {
    phase = 3;
    const tau = (tt - CYCLE.T_lift - CYCLE.T_hold) / CYCLE.T_drop;
    h = Math.max(CYCLE.H_max * (1 - tau ** 1.2), 0);
    v = -4 * (1 - (1 - tau) ** 0.65);
    flux = 0.1 + 0.4 * tau;
    thrust = 0;
  }
  return { h, v, thrust, phase, flux, tt };
}

const canvas = document.getElementById('c');
const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.1;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0c0e14);
scene.fog = new THREE.FogExp2(0x0c0e14, 0.035);

const camera = new THREE.PerspectiveCamera(45, innerWidth / innerHeight, 0.1, 80);
camera.position.set(4.5, 3.2, 5.5);

const controls = new OrbitControls(camera, canvas);
controls.target.set(0, 1.8, 0);
controls.enableDamping = true;
controls.update();

scene.add(new THREE.AmbientLight(0x404860, 0.4));
const key = new THREE.DirectionalLight(0xfff0dc, 1.1);
key.position.set(5, 8, 4);
key.castShadow = true;
scene.add(key);
scene.add(new THREE.DirectionalLight(0x59adff, 0.35).translateX(-4).translateY(5));

const floor = new THREE.Mesh(
  new THREE.PlaneGeometry(20, 20),
  new THREE.MeshStandardMaterial({ color: 0x151820, roughness: 0.95 })
);
floor.rotation.x = -Math.PI / 2;
floor.receiveShadow = true;
scene.add(floor);

const motorGlowMats = [];
const motors = [];

function makeHalbachMotor(x, z) {
  const g = new THREE.Group();
  g.position.set(x, 0, z);

  const stator = new THREE.Mesh(
    new THREE.CylinderGeometry(0.11, 0.11, 3.2, 24, 1, true),
    new THREE.MeshStandardMaterial({ color: 0x667788, metalness: 0.8, roughness: 0.35, side: THREE.DoubleSide, transparent: true, opacity: 0.45 })
  );
  stator.position.y = 1.6;
  g.add(stator);

  const mover = new THREE.Mesh(
    new THREE.CylinderGeometry(0.075, 0.075, 3.0, 24, 1, true),
    new THREE.MeshStandardMaterial({ color: 0x334455, metalness: 0.6, roughness: 0.4, side: THREE.DoubleSide })
  );
  mover.position.y = 1.55;
  g.add(mover);

  const glow = new THREE.Mesh(
    new THREE.CylinderGeometry(0.082, 0.082, 3.0, 24, 1, true),
    new THREE.MeshStandardMaterial({
      color: 0x59adff,
      emissive: 0x2266aa,
      emissiveIntensity: 0.2,
      transparent: true,
      opacity: 0.35,
      side: THREE.DoubleSide,
      depthWrite: false,
    })
  );
  glow.position.y = 1.55;
  g.add(glow);
  motorGlowMats.push(glow.material);

  for (let i = 0; i < 8; i++) {
    const seg = new THREE.Mesh(
      new THREE.BoxGeometry(0.04, 0.35, 0.06),
      new THREE.MeshStandardMaterial({ color: i % 2 ? 0x4488cc : 0x2266aa, metalness: 0.5 })
    );
    seg.rotation.y = (i / 8) * Math.PI * 2;
    seg.position.set(Math.sin(seg.rotation.y) * 0.07, 1.2 + (i % 4) * 0.55, Math.cos(seg.rotation.y) * 0.07);
    g.add(seg);
  }
  motors.push(g);
  scene.add(g);
}

[[-0.32, -0.32], [0.32, -0.32], [-0.32, 0.32], [0.32, 0.32]].forEach(([x, z]) => makeHalbachMotor(x, z));

const weight = new THREE.Group();
const buoy = new THREE.Mesh(
  new THREE.BoxGeometry(0.55, 0.35, 0.55),
  new THREE.MeshStandardMaterial({ color: 0xff804d, emissive: 0x441800, emissiveIntensity: 0.3, roughness: 0.45 })
);
buoy.position.y = 0.18;
buoy.castShadow = true;
weight.add(buoy);
const mass = new THREE.Mesh(
  new THREE.BoxGeometry(0.42, 0.42, 0.42),
  new THREE.MeshStandardMaterial({ color: 0x3a4048, metalness: 0.85, roughness: 0.3 })
);
mass.position.y = 0.58;
mass.castShadow = true;
weight.add(mass);
scene.add(weight);

const drum = new THREE.Mesh(
  new THREE.CylinderGeometry(0.14, 0.14, 0.28, 24),
  new THREE.MeshStandardMaterial({ color: 0x8899aa, metalness: 0.85, roughness: 0.3 })
);
drum.rotation.z = Math.PI / 2;
drum.position.set(0, 3.55, 0);
scene.add(drum);

const rope = new THREE.Line(
  new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3()]),
  new THREE.LineBasicMaterial({ color: 0xccddee })
);
scene.add(rope);

let simT = 0, playing = true, speed = 1, showFlux = true, last = performance.now();
const ui = {
  h: document.getElementById('m-h'),
  p: document.getElementById('m-p'),
  f: document.getElementById('m-f'),
  b: document.getElementById('m-b'),
  scrub: document.getElementById('scrub'),
  speed: document.getElementById('speed'),
  play: document.getElementById('play'),
  flux: document.getElementById('flux'),
};

ui.play.onclick = () => { playing = !playing; ui.play.textContent = playing ? 'Pause' : 'Play'; };
ui.flux.onclick = () => { showFlux = !showFlux; };
ui.scrub.oninput = () => { simT = (ui.scrub.value / 1000) * CYCLE.T_tot; };
ui.speed.oninput = () => { speed = Number(ui.speed.value); };

addEventListener('resize', () => {
  camera.aspect = innerWidth / innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(innerWidth, innerHeight);
});

function tick(now) {
  requestAnimationFrame(tick);
  const dt = Math.min((now - last) / 1000, 0.05);
  last = now;
  if (playing) simT += dt * speed;

  const s = cycleState(simT);
  weight.position.y = s.h * 0.95;
  drum.rotation.x += s.phase === 1 ? 0.04 : s.phase === 3 ? -0.12 : 0;

  rope.geometry.dispose();
  rope.geometry = new THREE.BufferGeometry().setFromPoints([
    new THREE.Vector3(0, 3.42, 0),
    new THREE.Vector3(0, weight.position.y + 0.85, 0),
  ]);

  const fluxInt = showFlux ? s.flux : 0.05;
  motorGlowMats.forEach((m) => { m.emissiveIntensity = fluxInt * 1.2; m.opacity = 0.15 + fluxInt * 0.45; });

  ui.h.textContent = `${s.h.toFixed(2)} m`;
  ui.p.textContent = s.phase === 1 ? 'Lift' : s.phase === 2 ? 'Hold' : 'Drop';
  ui.f.textContent = `${s.thrust.toFixed(0)} N`;
  ui.b.textContent = `${(s.flux * 100).toFixed(0)}%`;
  ui.scrub.value = String(Math.round((s.tt / CYCLE.T_tot) * 1000));

  controls.update();
  renderer.render(scene, camera);
}
tick(performance.now());
