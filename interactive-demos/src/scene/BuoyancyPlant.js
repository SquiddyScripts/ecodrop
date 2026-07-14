import * as THREE from 'three';
import { DIM, WEIGHT } from './constants.js';
import { createMaterials } from './materials.js';
import {
  LiquidVolume,
  createPipeRun,
  createFlange,
  createFlowSystem,
  animateFlowAlongCurve,
  makeCallout,
} from './geometryFactory.js';
import {
  createWaterTank400L,
  createWireframeCage,
  createInlineTurbine,
  createInlinePump,
  createThroughPipe,
  createHeavyWeight,
  createWinchDeck,
  createBasinTank,
  createPedestalTank,
} from './tank400L.js';
import { getVisualState } from '../cycleModel.js';

export async function buildBuoyancyPlant(scene, assets) {
  const textures = {};
  if (assets.floorDiff) {
    textures.floorDiff = assets.floorDiff;
    textures.floorNor = assets.floorNor;
    textures.floorRough = assets.floorRough;
  }
  const mat = createMaterials(textures);
  const root = new THREE.Group();
  scene.add(root);

  const sunDir = new THREE.Vector3(-0.55, 0.85, 0.25).normalize();

  const floor = new THREE.Mesh(new THREE.PlaneGeometry(22, 16), mat.floorMat);
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  root.add(floor);

  const pad = new THREE.Mesh(new THREE.BoxGeometry(7, 0.12, 5.5), mat.steelDark);
  pad.position.set(0, 0.06, 0);
  pad.receiveShadow = true;
  root.add(pad);

  const chamberRoot = new THREE.Group();
  chamberRoot.position.y = DIM.baseY;
  root.add(chamberRoot);

  const tank400 = createWaterTank400L(mat);
  tank400.group.position.y = 0.02;
  chamberRoot.add(tank400.group);

  const cage = createWireframeCage(DIM.cage.size, DIM.cage.height, mat);
  cage.position.y = 0.02;
  chamberRoot.add(cage);

  const chamberMaxH = DIM.chamber.height - 0.2;
  const chamberWater = new LiquidVolume({
    width: DIM.chamber.radius * 1.55,
    depth: DIM.chamber.radius * 1.55,
    maxHeight: chamberMaxH,
    inset: 0.05,
    scene,
    sunDirection: sunDir,
    waterNormals: assets.waterNormals,
    shape: 'cylinder',
    radius: DIM.chamber.radius - 0.1,
  });
  chamberWater.group.position.set(0, 0.1, 0);
  chamberRoot.add(chamberWater.group);

  const weight = createHeavyWeight(mat);
  weight.position.set(0, 0.15, 0);
  chamberRoot.add(weight);

  const winch = createWinchDeck(mat, DIM.baseY + DIM.winchY);
  root.add(winch.group);

  const rope = new THREE.Mesh(
    new THREE.CylinderGeometry(0.012, 0.012, 1, 8),
    mat.ropeMat
  );
  rope.renderOrder = 25;
  root.add(rope);

  const topAssembly = createPedestalTank(
    DIM.topTank.radius,
    DIM.topTank.tankH,
    DIM.topTank.pedestalH,
    mat
  );
  topAssembly.group.position.set(DIM.topTank.x, DIM.baseY, DIM.topTank.z);
  root.add(topAssembly.group);

  const topWater = new LiquidVolume({
    width: DIM.topTank.radius * 2,
    depth: DIM.topTank.radius * 2,
    maxHeight: DIM.topTank.tankH - 0.12,
    inset: 0.05,
    scene,
    sunDirection: sunDir,
    waterNormals: assets.waterNormals,
    shape: 'cylinder',
    radius: DIM.topTank.radius - 0.07,
  });
  topWater.group.position.set(DIM.topTank.x, DIM.baseY + DIM.topTank.pedestalH + 0.06, DIM.topTank.z);
  root.add(topWater.group);

  const basin = createBasinTank(DIM.bottomBasin.radius, DIM.bottomBasin.depth, mat);
  basin.group.position.set(DIM.bottomBasin.x, DIM.baseY, DIM.bottomBasin.z);
  root.add(basin.group);

  const bottomWater = new LiquidVolume({
    width: DIM.bottomBasin.radius * 2,
    depth: DIM.bottomBasin.radius * 2,
    maxHeight: DIM.bottomBasin.depth - 0.08,
    inset: 0.05,
    scene,
    sunDirection: sunDir,
    waterNormals: assets.waterNormals,
    shape: 'cylinder',
    radius: DIM.bottomBasin.radius - 0.08,
  });
  bottomWater.group.position.set(DIM.bottomBasin.x, DIM.baseY + 0.05, DIM.bottomBasin.z);
  root.add(bottomWater.group);

  const pump = createInlinePump(mat);
  pump.position.set(DIM.pump.x, DIM.pump.y, DIM.pump.z);
  pump.rotation.y = Math.PI / 2;
  root.add(pump);

  const turbine = createInlineTurbine(mat);
  const throughLen = DIM.chamber.radius * 2.55;

  const fillThrough = createThroughPipe(throughLen, DIM.pipeR, mat);
  fillThrough.position.set(0, DIM.throughPipeY + 0.35, 0);
  chamberRoot.add(fillThrough);

  const drainThrough = createThroughPipe(throughLen, DIM.pipeR * 0.95, mat);
  drainThrough.position.set(0, DIM.throughPipeY, 0);
  chamberRoot.add(drainThrough);

  turbine.group.position.set(0, DIM.throughPipeY, 0);
  chamberRoot.add(turbine.group);

  const fillVertical = createPipeRun(
    [
      new THREE.Vector3(DIM.topTank.x, DIM.baseY + topAssembly.topY - 0.05, DIM.topTank.z),
      new THREE.Vector3(DIM.topTank.x, DIM.baseY + 2.8, DIM.topTank.z),
      new THREE.Vector3(DIM.chamber.radius + 0.08, DIM.baseY + DIM.throughPipeY + 0.35, 0),
    ],
    DIM.pipeR
  );
  root.add(fillVertical.mesh);

  const drainOut = createPipeRun(
    [
      new THREE.Vector3(DIM.chamber.radius + 0.08, DIM.baseY + DIM.throughPipeY, 0),
      new THREE.Vector3(1.5, DIM.baseY + DIM.throughPipeY, 0),
      new THREE.Vector3(DIM.bottomBasin.x + 0.15, DIM.baseY + 0.38, DIM.bottomBasin.z),
    ],
    DIM.pipeR * 0.95
  );
  root.add(drainOut.mesh);

  const returnPipe = createPipeRun(
    [
      new THREE.Vector3(DIM.pump.x + 0.35, DIM.pump.y, DIM.pump.z),
      new THREE.Vector3(DIM.pump.x + 0.35, DIM.baseY + 2.5, DIM.pump.z),
      new THREE.Vector3(DIM.topTank.x - 0.4, DIM.baseY + 4.2, DIM.topTank.z),
      new THREE.Vector3(DIM.topTank.x, DIM.baseY + topAssembly.topY - 0.05, DIM.topTank.z),
    ],
    DIM.pipeR * 0.9
  );
  root.add(returnPipe.mesh);

  const fillFlow = createFlowSystem(60, 0x5ec4ff);
  const drainFlow = createFlowSystem(50, 0x7ad8ff);
  const returnFlow = createFlowSystem(40, 0xffd166);
  root.add(fillFlow, drainFlow, returnFlow);

  const labels = new THREE.Group();
  const callouts = [
    { text: '400 L chamber (HDPE tank)', pos: [-1.05, DIM.baseY + 3.2, 0.75], color: '#59adff' },
    { text: 'Composite weight', pos: [0.85, DIM.baseY + 1.6, 0.65], color: '#ff804d' },
    { text: 'Top reservoir', pos: [DIM.topTank.x, DIM.baseY + topAssembly.topY + 0.85, 0], color: '#59adff' },
    { text: 'Drain turbine', pos: [0.55, DIM.baseY + DIM.throughPipeY + 0.55, 0.55], color: '#66d98c' },
    { text: 'Bottom sump', pos: [DIM.bottomBasin.x, DIM.baseY + 1.05, 0.75], color: '#59adff' },
    { text: 'Inline pump', pos: [DIM.pump.x, DIM.baseY + 0.95, 1.05], color: '#59adff' },
    { text: 'Hoist / generator', pos: [0.75, DIM.baseY + DIM.winchY + 0.75, 0.45], color: '#d8dee8' },
  ];
  for (const c of callouts) {
    const s = makeCallout(c.text, c.color);
    s.position.set(c.pos[0], c.pos[1], c.pos[2]);
    labels.add(s);
  }
  root.add(labels);

  tank400.hdpe.transparent = true;
  tank400.hdpe.opacity = 0.55;
  tank400.hdpe.depthWrite = false;

  return {
    root,
    tankShell: tank400.hdpe,
    chamberWater,
    topWater,
    bottomWater,
    weight,
    rope,
    drum: winch.drum,
    generator: winch.generator,
    pump,
    turbine,
    fillVertical,
    drainOut,
    returnPipe,
    fillFlow,
    drainFlow,
    returnFlow,
    labels,

    update(state, simTime) {
      const vis = getVisualState(state);

      chamberWater.setLevel(vis.chamberFill, simTime, {
        swirl: vis.waterSwirl,
        bubbleRate: vis.bubbleRate,
        flowSpeed: vis.waterFlowSpeed,
      });
      topWater.setLevel(vis.topFill, simTime, { flowSpeed: vis.waterFlowSpeed * 0.7 });
      bottomWater.setLevel(vis.bottomFill, simTime, {
        swirl: vis.waterSwirl * 0.5,
        flowSpeed: vis.waterFlowSpeed,
      });

      weight.position.y = vis.weightY;
      weight.rotation.z = vis.weightTilt;
      weight.rotation.x = vis.weightPitch;
      weight.updateMatrixWorld(true);

      const ropeTop = new THREE.Vector3(0, DIM.baseY + DIM.winchY + 0.12, 0);
      const attach = weight.userData.ropeAttach.clone();
      weight.localToWorld(attach);
      const curve = new THREE.CatmullRomCurve3(
        [ropeTop, ropeTop.clone().lerp(attach, 0.5), attach],
        false,
        'catmullrom',
        0.35
      );
      rope.geometry.dispose();
      rope.geometry = new THREE.TubeGeometry(curve, 20, 0.012, 8, false);

      winch.drum.rotation.x += vis.drumSpeed;
      winch.generator.material.emissive.setHex(state.isGenerating ? 0x1a5533 : 0x000000);
      winch.generator.material.emissiveIntensity = state.isGenerating ? 0.9 : 0;

      turbine.blades.rotation.x += vis.turbineSpeed;
      turbine.generator.material.emissive.setHex(vis.turbineSpeed > 0.05 ? 0x164428 : 0x000000);
      turbine.generator.material.emissiveIntensity = vis.turbineSpeed > 0.05 ? 0.7 : 0;

      if (pump.userData.spinParts) {
        for (const part of pump.userData.spinParts) {
          part.rotation.y += state.isPumping ? 0.16 : 0;
        }
      }

      animateFlowAlongCurve(fillFlow, fillVertical.curve, simTime, 0.5, vis.showInletFlow);
      animateFlowAlongCurve(drainFlow, drainOut.curve, simTime, 0.65, vis.showDrainFlow);
      animateFlowAlongCurve(returnFlow, returnPipe.curve, simTime, 0.42, vis.showReturnFlow);
    },

    setXray(enabled) {
      tank400.hdpe.opacity = enabled ? 0.28 : 0.55;
      tank400.hdpe.transmission = enabled ? 0.15 : 0;
    },

    setLabelsVisible(v) {
      labels.visible = v;
    },
  };
}
