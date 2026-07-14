/**
 * Clean 2D cross-section — colormap in air gap + radial B vectors only.
 */

import {
  MOTOR,
  sampleFieldGrid,
  segmentMagAngle,
  backEMF,
  coggingTorque,
  bFieldColor,
  fieldAt,
} from './physics/halbachFieldModel.js';

const BG = '#0c0e14';
const FG = 'rgba(235,235,240,0.55)';

function setupCanvas(canvas) {
  const w = canvas.clientWidth;
  const h = canvas.clientHeight;
  canvas.width = w * devicePixelRatio;
  canvas.height = h * devicePixelRatio;
  const ctx = canvas.getContext('2d');
  ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  return { ctx, w, h };
}

export function createFEMPanel(container) {
  const wrap = document.createElement('div');
  wrap.className = 'fem-panel';

  wrap.innerHTML =
    '<div class="fem-panel-header">' +
    '<h3>Motor cross-section</h3>' +
    '<p>Radial air-gap flux · Halbach array on mover · 12-slot stator</p>' +
    '</div>';

  const mainCanvas = document.createElement('canvas');
  mainCanvas.id = 'fem-flux-canvas';
  mainCanvas.height = 200;
  wrap.appendChild(mainCanvas);

  const row = document.createElement('div');
  row.className = 'fem-mini-row';
  row.innerHTML =
    '<div class="fem-mini"><span>Back-EMF</span><canvas height="56"></canvas></div>' +
    '<div class="fem-mini"><span>Cogging</span><canvas height="56"></canvas></div>';
  wrap.appendChild(row);

  const legend = document.createElement('div');
  legend.className = 'fem-legend';
  legend.innerHTML =
    '<span class="low">low |B|</span><div class="bar"></div><span class="high">high |B|</span>';
  wrap.appendChild(legend);

  container.appendChild(wrap);

  const emfCanvas = row.querySelectorAll('canvas')[0];
  const cogCanvas = row.querySelectorAll('canvas')[1];
  const B_MAX = MOTOR.gapB0;

  function drawMain(intensity) {
    const { ctx, w, h } = setupCanvas(mainCanvas);
    ctx.fillStyle = BG;
    ctx.fillRect(0, 0, w, h);

    const cx = w / 2;
    const cy = h / 2;
    const scale = (Math.min(w, h) * 0.44) / MOTOR.statorOuter;
    const nx = 64;
    const ny = 64;
    const { bmagGrid, R } = sampleFieldGrid(nx, ny, intensity);

    for (let j = 0; j < ny; j++) {
      for (let i = 0; i < nx; i++) {
        const x = -R + (2 * R * i) / (nx - 1);
        const y = -R + (2 * R * j) / (ny - 1);
        const r = Math.hypot(x, y);
        if (r > MOTOR.statorOuter * 1.05) continue;

        const bmag = bmagGrid[j * nx + i];
        if (bmag < 0.01) continue;

        const [r8, g8, b8] = bFieldColor(bmag / B_MAX);
        const sx = cx + x * scale;
        const sy = cy - y * scale;
        const cell = (scale * 2 * R) / nx + 1;

        ctx.fillStyle = `rgba(${r8},${g8},${b8},${r <= MOTOR.moverR ? 0.15 : 0.85})`;
        ctx.fillRect(sx - cell / 2, sy - cell / 2, cell, cell);
      }
    }

    drawMotorGeometry(ctx, cx, cy, scale);

    const gapMid = (MOTOR.moverR + MOTOR.statorInner) / 2;
    const nArrows = 16;
    for (let k = 0; k < nArrows; k++) {
      const theta = (k / nArrows) * Math.PI * 2 - Math.PI / 2;
      const x = Math.cos(theta) * gapMid;
      const y = Math.sin(theta) * gapMid;
      const f = fieldAt(x, y, intensity);
      if (f.bmag < 0.05) continue;

      const sx = cx + x * scale;
      const sy = cy - y * scale;
      const len = 10 + 18 * (f.bmag / B_MAX);
      const dx = (f.bx / f.bmag) * len;
      const dy = -(f.by / f.bmag) * len;

      ctx.strokeStyle = `rgba(255,255,255,${0.5 + 0.5 * (f.bmag / B_MAX)})`;
      ctx.lineWidth = 1.2;
      ctx.beginPath();
      ctx.moveTo(sx, sy);
      ctx.lineTo(sx + dx, sy + dy);
      ctx.stroke();

      const ang = Math.atan2(dy, dx);
      ctx.beginPath();
      ctx.moveTo(sx + dx, sy + dy);
      ctx.lineTo(sx + dx - 5 * Math.cos(ang - 0.45), sy + dy - 5 * Math.sin(ang - 0.45));
      ctx.lineTo(sx + dx - 5 * Math.cos(ang + 0.45), sy + dy - 5 * Math.sin(ang + 0.45));
      ctx.closePath();
      ctx.fillStyle = ctx.strokeStyle;
      ctx.fill();
    }

    ctx.fillStyle = FG;
    ctx.font = '10px Segoe UI';
    ctx.fillText(`Peak |B| ≈ ${(B_MAX * intensity).toFixed(2)} T`, 8, 14);
    ctx.textAlign = 'right';
    ctx.fillText('→ radial flux', w - 8, 14);
    ctx.textAlign = 'left';
  }

  function drawMotorGeometry(ctx, cx, cy, scale) {
    ctx.save();
    ctx.translate(cx, cy);

    ctx.fillStyle = 'rgba(50,56,66,0.92)';
    ctx.beginPath();
    ctx.arc(0, 0, MOTOR.statorOuter * scale, 0, Math.PI * 2);
    ctx.arc(0, 0, MOTOR.statorInner * scale, 0, Math.PI * 2, true);
    ctx.fill('evenodd');

    for (let s = 0; s < MOTOR.slotCount; s++) {
      const a = (s / MOTOR.slotCount) * Math.PI * 2;
      const r0 = MOTOR.statorInner * scale;
      const r1 = MOTOR.statorOuter * scale * 0.9;
      ctx.fillStyle = '#1a1e26';
      ctx.beginPath();
      ctx.moveTo(Math.cos(a - 0.035) * r0, -Math.sin(a - 0.035) * r0);
      ctx.lineTo(Math.cos(a + 0.035) * r0, -Math.sin(a + 0.035) * r0);
      ctx.lineTo(Math.cos(a + 0.02) * r1, -Math.sin(a + 0.02) * r1);
      ctx.lineTo(Math.cos(a - 0.02) * r1, -Math.sin(a - 0.02) * r1);
      ctx.closePath();
      ctx.fill();
    }

    for (let s = 0; s < MOTOR.nSeg; s++) {
      const a0 = (s / MOTOR.nSeg) * Math.PI * 2;
      const a1 = ((s + 1) / MOTOR.nSeg) * Math.PI * 2;
      ctx.fillStyle = s % 2 === 0 ? '#c94040' : '#4060c9';
      ctx.beginPath();
      ctx.arc(0, 0, MOTOR.moverR * scale, -a1, -a0, true);
      ctx.arc(0, 0, MOTOR.moverR * 0.5 * scale, -a0, -a1);
      ctx.closePath();
      ctx.fill();

      const mid = (a0 + a1) / 2;
      const mag = segmentMagAngle(s);
      const ax = Math.cos(mid) * MOTOR.moverR * scale * 0.72;
      const ay = -Math.sin(mid) * MOTOR.moverR * scale * 0.72;
      ctx.strokeStyle = 'rgba(255,255,255,0.7)';
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(ax, ay);
      ctx.lineTo(ax + Math.cos(mag) * 8, ay - Math.sin(mag) * 8);
      ctx.stroke();
    }

    ctx.fillStyle = '#14161c';
    ctx.beginPath();
    ctx.arc(0, 0, MOTOR.moverR * 0.46 * scale, 0, Math.PI * 2);
    ctx.fill();

    ctx.strokeStyle = 'rgba(89,173,255,0.5)';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.arc(0, 0, MOTOR.moverR * scale, 0, Math.PI * 2);
    ctx.stroke();
    ctx.beginPath();
    ctx.arc(0, 0, MOTOR.statorInner * scale, 0, Math.PI * 2);
    ctx.stroke();

    ctx.fillStyle = 'rgba(89,173,255,0.7)';
    ctx.font = '600 8px Segoe UI';
    ctx.textAlign = 'center';
    const gapMid = (MOTOR.moverR + MOTOR.statorInner) / 2;
    ctx.fillText('AIR GAP', 0, -gapMid * scale);
    ctx.restore();
  }

  function drawMini(canvas, fn, color, yMax) {
    const { ctx, w, h } = setupCanvas(canvas);
    ctx.fillStyle = BG;
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(42,48,64,0.8)';
    ctx.beginPath();
    ctx.moveTo(4, h / 2);
    ctx.lineTo(w - 4, h / 2);
    ctx.stroke();
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    for (let i = 0; i <= 60; i++) {
      const t = (i / 60) * Math.PI * 2;
      const x = 6 + (i / 60) * (w - 12);
      const y = h / 2 - (fn(t) / yMax) * (h / 2 - 8);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
  }

  function draw(intensity) {
    const i = Math.max(0.08, intensity);
    drawMain(i);
    drawMini(emfCanvas, (t) => backEMF(t / (2 * Math.PI), i), '#59adff', 50);
    drawMini(cogCanvas, coggingTorque, '#f2bf40', 0.5);
  }

  return { draw, resize: () => draw(0.6) };
}
