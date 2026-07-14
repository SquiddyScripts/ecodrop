"""Patch elevator_regen_base.html → elevator_regen.html with rebuilt tab 2."""
import re
from pathlib import Path

ROOT = Path(__file__).parent
SRC = ROOT / "elevator_regen_base.html"
DST = ROOT / "elevator_regen.html"

TAB2_STUB = r"""
const V={
  H:9.5,
  carW:1.30,carH:2.10,carD:1.30,
  carZ:0.6,
  cwZ:-0.85,
  cabRopeX:0, cwRopeX:-0.05,
  travel:2.6, carMid:4.3,
  drumY:8.95, bedTop:8.78,
  paxMass:75,
  carEmpty:480,
  baseCwt:480,
  barbellMass:80,
  maxBarbells:8,
  rotaryY:8.10,
  stackBaseY:1.05,
  storageY:8.95,
};
window.Vs={
  paxCount:2, targetN:0, transferring:false, transferT:0, transferDir:0,
  rotaryAngle:0, rotarySpinSpeed:0, energy:0,
  cabY:V.carMid, cwtY:V.H-V.carMid,
  paxCycle:0, demoTimer:0, camTrack:null,
};

// ---- Tab 2 ropes (kept outside init for early declare) ----
const ropeT2A=new THREE.Mesh(new THREE.CylinderGeometry(0.02,0.02,1,8),M.rope); t2Root.add(ropeT2A);
const ropeT2B=new THREE.Mesh(new THREE.CylinderGeometry(0.02,0.02,1,8),M.rope); t2Root.add(ropeT2B);
function setRopeT2(cyl, topY, botY, x, z){
  const h=Math.max(0.01,topY-botY); cyl.scale.y=h;
  cyl.position.set(x,(topY+botY)/2,z);
}
const sheaveT2=new THREE.Mesh(new THREE.CylinderGeometry(0.30,0.30,0.18,28),M.drum);
sheaveT2.rotation.z=Math.PI/2; sheaveT2.position.set(0, V.H-0.05, (V.carZ+V.cwZ)/2); t2Root.add(sheaveT2);

let tab2Ready=false;
const loadEl=document.getElementById('load');
loadEl.style.display='none';
const d2StatusEl=document.getElementById('d2_status');
if(d2StatusEl) d2StatusEl.textContent='Loading CAD models…';
loadVcwtParts('assets/').then(solids=>{
  initTab2Scene(solids);
  tab2Ready=true;
  if(d2StatusEl) d2StatusEl.textContent='Balanced';
}).catch(err=>{
  console.error(err);
  if(d2StatusEl) d2StatusEl.textContent='CAD load failed — run: python -m http.server 8765';
});
"""

LOADER_SCRIPTS = """
<script src="stl-loader.js"></script>
<script src="tab2-scene.js"></script>
"""


def main():
    text = SRC.read_text(encoding="utf-8", errors="replace")

    # Drop embedded tab-2 mesh blob (fallback only)
    text = re.sub(
        r"const VARCWT_PACKED=\"[^\"]+\";\s*",
        "const VARCWT_PACKED=null; // loaded from assets/ via stl-loader.js\n",
        text,
        count=1,
    )
    text = text.replace(
        "const VCWT_PARTS=parseNamedPacked(b64ToBuf(VARCWT_PACKED));",
        "const VCWT_PARTS={};",
    )

    start = text.find("//  TAB 2 — VARIABLE COUNTERWEIGHT")
    end = text.find("// ============================================================\n//  EDIT MODE")
    if start < 0 or end < 0:
        raise SystemExit("Tab 2 markers not found")

    text = text[:start] + TAB2_STUB + "\n" + text[end:]

    # tickTab2: add demo + camera + transfer from window
    text = text.replace(
        "function tickTab2(dt){\n  if(paused2) return;\n  tickTransfer(dt);\n  tickTab2Motion(dt);",
        "function tickTab2(dt){\n  if(paused2||!tab2Ready) return;\n  tickTransfer(dt);\n  tickTab2Motion(dt);\n  tickTab2Demo(dt);\n  tickTab2Cam(dt);",
    )

    # Auto-orbit on tab 2 for judge-friendly demo
    text = text.replace(
        "  if(name==='t1') goCam('over'); else goCam2('over');",
        "  if(name==='t1'){controls.auto=false;goCam('over');}\n  else{controls.auto=true;goCam2('over');}",
    )

    # Frame loop: show loader until tab2 ready when on t2
    text = text.replace(
        "  if(typeof currentTab!=='undefined' && currentTab==='t2'){\n    // Tab 2 path\n    tickTab2(dt);",
        "  if(typeof currentTab!=='undefined' && currentTab==='t2'){\n    if(!tab2Ready){applyCam();renderer.render(scene,camera);return requestAnimationFrame(frame);}\n    tickTab2(dt);",
    )

    # Remove duplicate load hide at end (keep loader until CAD ready)
    text = text.replace(
        "\ndocument.getElementById('load').style.display='none';\nrequestAnimationFrame(frame);",
        "\nrequestAnimationFrame(frame);",
    )

    text = text.replace(
        "const tagEls2=TAGS2.map(d=>{const e=document.createElement('div');e.className='tag '+d.cls;\n"
        "  e.textContent=d.txt;app.appendChild(e);return e;});",
        "let TAGS2=[];\nlet tagEls2=[];\n"
        "function buildTagEls2(){tagEls2.forEach(e=>e.remove());tagEls2=TAGS2.map(d=>{const e=document.createElement('div');"
        "e.className='tag '+d.cls;e.textContent=d.txt;app.appendChild(e);return e;});}\n",
    )

    if 'src="stl-loader.js"' not in text:
        text = text.replace(
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>\n<script>',
            '<script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>\n'
            '<script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/STLLoader.js"></script>\n'
            + LOADER_SCRIPTS.strip()
            + "\n<script>",
        )

    DST.write_text(text, encoding="utf-8")
    print(f"Wrote {DST} ({DST.stat().st_size/1e6:.2f} MB)")


if __name__ == "__main__":
    main()
