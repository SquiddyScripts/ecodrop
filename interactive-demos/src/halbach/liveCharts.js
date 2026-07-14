/** Live engineering charts — canvas2D panels matching MATLAB time-series */

import { CYCLE, HISTORY } from './cycleModel.js';

const BG = '#0c0e14';
const GRID = '#2a3040';
const FG = 'rgba(235,235,240,0.55)';
const C_THRUST = '#f2bf40';
const C_MOTOR = '#bf7af0';
const C_GEN = '#66d98c';
const C_HEIGHT = '#ff804d';
const C_CURRENT = '#59adff';

function setupCanvas(canvas, w, h) {
  canvas.width = w * devicePixelRatio;
  canvas.height = h * devicePixelRatio;
  canvas.style.width = `${w}px`;
  canvas.style.height = `${h}px`;
  const ctx = canvas.getContext('2d');
  ctx.scale(devicePixelRatio, devicePixelRatio);
  return ctx;
}

function drawSparkline(ctx, w, h, data, tNow, color, yMax, label, unit, bipolar = false) {
  ctx.fillStyle = BG;
  ctx.fillRect(0, 0, w, h);
  ctx.strokeStyle = GRID;
  ctx.lineWidth = 1;
  for (let i = 0; i <= 4; i++) {
    const y = (h - 18) * (i / 4) + 8;
    ctx.beginPath();
    ctx.moveTo(4, y);
    ctx.lineTo(w - 4, y);
    ctx.stroke();
  }

  ctx.fillStyle = FG;
  ctx.font = '10px Segoe UI';
  ctx.fillText(label, 8, 14);
  ctx.textAlign = 'right';
  ctx.fillText(unit, w - 8, 14);
  ctx.textAlign = 'left';

  const n = data.length;
  const ix = Math.floor((tNow / CYCLE.T_tot) * (n - 1));
  const x0 = 8;
  const x1 = w - 8;
  const y0 = 18;
  const y1 = h - 6;

  ctx.beginPath();
  ctx.strokeStyle = color;
  ctx.lineWidth = 1.5;
  ctx.globalAlpha = 0.35;
  for (let i = 0; i < n; i++) {
    const x = x0 + (i / (n - 1)) * (x1 - x0);
    let norm = data[i] / yMax;
    if (bipolar) norm = data[i] / yMax * 0.5 + 0.5;
    else norm = data[i] / yMax;
    const y = y1 - norm * (y1 - y0);
    if (i === 0) ctx.moveTo(x, y);
    else ctx.lineTo(x, y);
  }
  ctx.stroke();
  ctx.globalAlpha = 1;

  const cx = x0 + (ix / (n - 1)) * (x1 - x0);
  ctx.strokeStyle = 'rgba(255,255,255,0.25)';
  ctx.lineWidth = 1;
  ctx.setLineDash([3, 3]);
  ctx.beginPath();
  ctx.moveTo(cx, y0);
  ctx.lineTo(cx, y1);
  ctx.stroke();
  ctx.setLineDash([]);

  const cy = y1 - (bipolar ? data[ix] / yMax * 0.5 + 0.5 : data[ix] / yMax) * (y1 - y0);
  ctx.fillStyle = color;
  ctx.beginPath();
  ctx.arc(cx, cy, 4, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = FG;
  ctx.font = '11px Segoe UI';
  ctx.fillText(data[ix].toFixed(0), cx + 6, cy - 4);
}

export function createLiveCharts(container) {
  const charts = [
    { id: 'chart-height', color: C_HEIGHT, key: 'height', max: CYCLE.H_max * 1.1, label: 'Weight height', unit: 'm' },
    { id: 'chart-thrust', color: C_THRUST, key: 'thrust', max: 600, label: 'Motor thrust', unit: 'N' },
    { id: 'chart-power', color: C_MOTOR, key: 'pMotor', max: 900, label: 'Electrical load', unit: 'W' },
    { id: 'chart-gen', color: C_GEN, key: 'pGen', max: 1600, label: 'Regeneration', unit: 'W' },
    { id: 'chart-current', color: C_CURRENT, key: 'current', max: 22, label: 'Phase current', unit: 'A' },
  ];

  const canvases = charts.map((c) => {
    const wrap = document.createElement('div');
    wrap.className = 'chart-cell';
    const canvas = document.createElement('canvas');
    canvas.id = c.id;
    wrap.appendChild(canvas);
    container.appendChild(wrap);
    return { ...c, canvas, ctx: null };
  });

  function resize() {
    for (const c of canvases) {
      const w = c.canvas.parentElement.clientWidth;
      c.ctx = setupCanvas(c.canvas, w, 72);
    }
  }

  function update(tNow) {
    for (const c of canvases) {
      if (!c.ctx) continue;
      const data = HISTORY[c.key];
      const max = c.key === 'current' ? Math.max(22, ...data.map(Math.abs)) : c.max;
      drawSparkline(c.ctx, c.canvas.width / devicePixelRatio, 72, data, tNow, c.color, max, c.label, c.unit, c.key === 'current');
    }
  }

  resize();
  window.addEventListener('resize', resize);
  return { update, resize };
}
