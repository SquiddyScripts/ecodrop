import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader.js';
import { CYCLE, getCycleState } from './cycleModel.js';
import { buildBuoyancyPlant } from './scene/BuoyancyPlant.js';
import { createProceduralWaterNormals, loadTexture } from './scene/assetLoader.js';

const canvas = document.getElementById('canvas');
const hud = document.getElementById('hud');
const statusEl = document.getElementById('load-status');

function setStatus(msg, isError = false) {
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = isError ? '#ff8080' : 'rgba(235,235,240,0.7)';
}

const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  powerPreference: 'high-performance',
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.2;

const scene = new THREE.Scene();
scene.background = new THREE.Color(0x1a2030);
scene.fog = new THREE.FogExp2(0x1a2030, 0.022);

const camera = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.1, 120);
camera.position.set(7.5, 4.8, 9.2);

const controls = new OrbitControls(camera, canvas);
controls.target.set(0, 3.4, 0);
controls.enableDamping = true;
controls.maxPolarAngle = Math.PI * 0.48;
controls.minDistance = 5;
controls.maxDistance = 22;
controls.update();

const loader = new THREE.TextureLoader();
const rgbeLoader = new RGBELoader();

const key = new THREE.DirectionalLight(0xfff0dc, 1.0);
key.position.set(6, 12, 4);
key.castShadow = true;
key.shadow.mapSize.set(2048, 2048);
key.shadow.camera.near = 2;
key.shadow.camera.far = 35;
key.shadow.camera.left = -12;
key.shadow.camera.right = 12;
key.shadow.camera.top = 12;
key.shadow.camera.bottom = -2;
key.shadow.bias = -0.0002;
scene.add(key);

const fill = new THREE.DirectionalLight(0x6eb8ff, 0.45);
fill.position.set(-8, 6, -5);
scene.add(fill);

scene.add(new THREE.AmbientLight(0x404860, 0.35));

async function loadAssets() {
  setStatus('Loading textures…');

  const [waterFile, floorDiff, floorNor, floorRough, hdr] = await Promise.all([
    loadTexture(loader, '/assets/textures/water_normal.jpg'),
    loadTexture(loader, '/assets/textures/floor_diff.jpg'),
    loadTexture(loader, '/assets/textures/floor_nor.jpg'),
    loadTexture(loader, '/assets/textures/floor_rough.jpg'),
    loadTexture(rgbeLoader, '/assets/hdri/studio.hdr').catch(() =>
      loadTexture(rgbeLoader, '/assets/hdri/industrial.hdr')
    ),
  ]);

  const waterNormals = waterFile ?? createProceduralWaterNormals(256);
  waterNormals.wrapS = waterNormals.wrapT = THREE.RepeatWrapping;

  if (hdr) {
    hdr.mapping = THREE.EquirectangularReflectionMapping;
    scene.environment = hdr;
    scene.background = hdr;
  }

  return { waterNormals, floorDiff, floorNor, floorRough };
}

let demo = null;
let simTime = 0;
let playing = true;
let speed = 1;
let lastWall = performance.now();

const ui = {
  phaseBadge: document.getElementById('phase-badge'),
  phaseTitle: document.getElementById('phase-title'),
  phaseDesc: document.getElementById('phase-desc'),
  mHeight: document.getElementById('m-height'),
  mChamber: document.getElementById('m-chamber'),
  mReservoir: document.getElementById('m-reservoir'),
  mPower: document.getElementById('m-power'),
  btnPlay: document.getElementById('btn-play'),
  btnReset: document.getElementById('btn-reset'),
  scrubber: document.getElementById('scrubber'),
  speed: document.getElementById('speed'),
  speedLabel: document.getElementById('speed-label'),
  toggleLabels: document.getElementById('toggle-labels'),
  toggleXray: document.getElementById('toggle-xray'),
};

ui.scrubber.max = String(1000);

function updateHud(state) {
  hud.classList.remove('phase-lift', 'phase-water', 'phase-drop');
  hud.classList.add(
    state.phase.id === 1 ? 'phase-lift' : state.phase.id === 2 ? 'phase-water' : 'phase-drop'
  );

  ui.phaseBadge.textContent = `Phase ${state.phase.id} · ${state.phase.name}`;
  ui.phaseTitle.textContent = state.phase.title;
  ui.phaseDesc.textContent = state.phase.desc;
  ui.mHeight.textContent = `${state.h_weight.toFixed(2)} m`;
  ui.mChamber.textContent = `${state.fillPct.toFixed(0)}%`;
  ui.mReservoir.textContent = `${state.topPct.toFixed(0)}%`;
  ui.mPower.textContent = state.powerLabel;
  ui.scrubber.value = String(Math.round((state.t / CYCLE.T_tot) * 1000));
}

ui.btnPlay.addEventListener('click', () => {
  playing = !playing;
  ui.btnPlay.textContent = playing ? 'Pause' : 'Play';
});

ui.btnReset.addEventListener('click', () => {
  simTime = 0;
  playing = true;
  ui.btnPlay.textContent = 'Pause';
});

ui.scrubber.addEventListener('input', () => {
  simTime = (Number(ui.scrubber.value) / 1000) * CYCLE.T_tot;
});

ui.speed.addEventListener('input', () => {
  speed = Number(ui.speed.value);
  ui.speedLabel.textContent = `${speed.toFixed(2)}×`;
});

ui.toggleLabels.addEventListener('change', () => {
  demo?.setLabelsVisible(ui.toggleLabels.checked);
});

ui.toggleXray.addEventListener('change', () => {
  demo?.setXray(ui.toggleXray.checked);
});

window.addEventListener('resize', () => {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

function tick(now) {
  requestAnimationFrame(tick);

  const dt = Math.min((now - lastWall) / 1000, 0.05);
  lastWall = now;

  if (demo) {
    if (playing) simTime += dt * speed;
    try {
      const state = getCycleState(simTime);
      demo.update(state, simTime);
      updateHud(state);
    } catch (err) {
      console.error('Update error:', err);
      setStatus(`Simulation error: ${err.message}`, true);
    }
  }

  controls.update();
  renderer.render(scene, camera);
}

requestAnimationFrame(tick);

loadAssets()
  .then(async (assets) => {
    setStatus('Building scene…');
    demo = await buildBuoyancyPlant(scene, assets);
    demo.setXray(ui.toggleXray.checked);
    demo.setLabelsVisible(ui.toggleLabels.checked);
    updateHud(getCycleState(0));
    setStatus('');
  })
  .catch((err) => {
    console.error(err);
    setStatus(`Failed to load: ${err.message}`, true);
  });
