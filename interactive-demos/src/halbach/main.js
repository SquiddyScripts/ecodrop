import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader.js';
import { CYCLE, getCycleState } from './cycleModel.js';
import { buildHalbachTower } from './scene/HalbachTower.js';
import { createLiveCharts } from './liveCharts.js';
import { createFEMPanel } from './femPanel.js';
import { loadTexture } from '../scene/assetLoader.js';

const canvas = document.getElementById('canvas');
const hud = document.getElementById('hud');
const statusEl = document.getElementById('load-status');

function setStatus(msg, isError = false) {
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = isError ? '#ff8080' : 'rgba(235,235,240,0.7)';
}

const renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.15;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x0c0e14);
scene.fog = new THREE.FogExp2(0x0c0e14, 0.024);

const camera = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.1, 100);
camera.position.set(5.8, 4.2, 7.2);

const controls = new OrbitControls(camera, canvas);
controls.target.set(0, 3.2, 0);
controls.enableDamping = true;
controls.maxPolarAngle = Math.PI * 0.48;
controls.minDistance = 4;
controls.maxDistance = 16;
controls.update();

const loader = new THREE.TextureLoader();
const rgbeLoader = new RGBELoader();

async function loadAssets() {
  const [floorDiff, floorNor, floorRough, hdr] = await Promise.all([
    loadTexture(loader, '/assets/textures/floor_diff.jpg'),
    loadTexture(loader, '/assets/textures/floor_nor.jpg'),
    loadTexture(loader, '/assets/textures/floor_rough.jpg'),
    loadTexture(rgbeLoader, '/assets/hdri/studio.hdr').catch(() =>
      loadTexture(rgbeLoader, '/assets/hdri/industrial.hdr')
    ),
  ]);
  if (hdr) {
    hdr.mapping = THREE.EquirectangularReflectionMapping;
    scene.environment = hdr;
    scene.background = hdr;
  }
  return { floorDiff, floorNor, floorRough };
}

const key = new THREE.DirectionalLight(0xfff0dc, 0.9);
key.position.set(5, 10, 4);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
key.shadow.camera.near = 1;
key.shadow.camera.far = 30;
key.shadow.camera.left = -8;
key.shadow.camera.right = 8;
key.shadow.camera.top = 8;
key.shadow.camera.bottom = -1;
scene.add(key);
scene.add(new THREE.DirectionalLight(0x59adff, 0.35).translateX(-5).translateY(6));
scene.add(new THREE.AmbientLight(0x404860, 0.35));

let demo;
let simTime = 0;
let playing = true;
let speed = 1;
let lastWall = performance.now();

const charts = createLiveCharts(document.getElementById('charts-grid'));
const femPanel = createFEMPanel(document.getElementById('fem-panel'));

const ui = {
  phaseBadge: document.getElementById('phase-badge'),
  phaseTitle: document.getElementById('phase-title'),
  phaseDesc: document.getElementById('phase-desc'),
  mHeight: document.getElementById('m-height'),
  mVelocity: document.getElementById('m-velocity'),
  mThrust: document.getElementById('m-thrust'),
  mFlux: document.getElementById('m-flux'),
  mMotor: document.getElementById('m-motor'),
  mHoist: document.getElementById('m-hoist'),
  mCurrent: document.getElementById('m-current'),
  mPower: document.getElementById('m-power'),
  btnPlay: document.getElementById('btn-play'),
  btnReset: document.getElementById('btn-reset'),
  scrubber: document.getElementById('scrubber'),
  speed: document.getElementById('speed'),
  speedLabel: document.getElementById('speed-label'),
  toggleLabels: document.getElementById('toggle-labels'),
  toggleXray: document.getElementById('toggle-xray'),
  toggleFlux: document.getElementById('toggle-flux'),
};
ui.scrubber.max = '1000';

function updateHud(state) {
  hud.classList.remove('phase-lift', 'phase-hold', 'phase-drop');
  hud.classList.add(state.phase.css);
  ui.phaseBadge.textContent = `Phase ${state.phase.id} · ${state.phase.name}`;
  ui.phaseTitle.textContent = state.phase.title;
  ui.phaseDesc.textContent = state.phase.desc;
  ui.mHeight.textContent = `${state.h.toFixed(2)} m`;
  ui.mVelocity.textContent = `${state.v.toFixed(2)} m/s`;
  ui.mThrust.textContent = `${state.thrust.toFixed(0)} N`;
  ui.mFlux.textContent = `${(state.flux * 100).toFixed(0)}%`;
  ui.mMotor.textContent = `${state.p_linear_elec.toFixed(0)} W`;
  ui.mHoist.textContent = `${state.p_hoist.toFixed(0)} W`;
  ui.mCurrent.textContent = `${state.i_phase.toFixed(1)} A`;
  ui.mPower.textContent = state.powerLabel;
  ui.scrubber.value = String(Math.round((state.t / CYCLE.T_tot) * 1000));
}

ui.btnPlay.onclick = () => {
  playing = !playing;
  ui.btnPlay.textContent = playing ? 'Pause' : 'Play';
};
ui.btnReset.onclick = () => {
  simTime = 0;
  playing = true;
  ui.btnPlay.textContent = 'Pause';
};
ui.scrubber.oninput = () => {
  simTime = (Number(ui.scrubber.value) / 1000) * CYCLE.T_tot;
};
ui.speed.oninput = () => {
  speed = Number(ui.speed.value);
  ui.speedLabel.textContent = `${speed.toFixed(2)}×`;
};
ui.toggleLabels.onchange = () => demo?.setLabelsVisible(ui.toggleLabels.checked);
ui.toggleXray.onchange = () => demo?.setXray(ui.toggleXray.checked);
ui.toggleFlux.onchange = () => demo?.setFluxVisible(ui.toggleFlux.checked);

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

function tick(now) {
  requestAnimationFrame(tick);
  if (!demo) return;

  const dt = Math.min((now - lastWall) / 1000, 0.05);
  lastWall = now;
  if (playing) simTime += dt * speed;

  const state = getCycleState(simTime);
  demo.update(state, simTime);
  updateHud(state);
  charts.update(state.t);
  femPanel.draw(state.flux, state.t);

  controls.update();
  renderer.render(scene, camera);
}

requestAnimationFrame(tick);

loadAssets()
  .then((tex) => {
    setStatus('Building Halbach tower…');
    demo = buildHalbachTower(scene, tex);
    demo.setXray(ui.toggleXray.checked);
    demo.setLabelsVisible(ui.toggleLabels.checked);
    demo.setFluxVisible(ui.toggleFlux.checked);
    updateHud(getCycleState(0));
    setStatus('');
  })
  .catch((err) => {
    console.error(err);
    setStatus(`Failed: ${err.message}`, true);
  });
