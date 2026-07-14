"""Split elevator STLs into named parts and emit meshes_packed.js for the web viz."""
import base64
import struct
from pathlib import Path

import numpy as np

ROOT = Path(__file__).parent / "assets"
OUT = Path(__file__).parent / "meshes_packed.js"


def read_stl(path: Path):
    data = path.read_bytes()
    n = struct.unpack("<I", data[80:84])[0]
    tris = []
    o = 84
    for _ in range(n):
        tri = data[o : o + 50]
        o += 50
        if len(tri) < 48:
            break
        vals = struct.unpack("<12f", tri[:48])
        verts = [(vals[j], vals[j + 1], vals[j + 2]) for j in range(0, 9, 3)]
        tris.append(verts)
    return tris


def tris_to_positions(tris):
    pos = []
    for t in tris:
        for v in t:
            pos.extend(v)
    return np.array(pos, dtype=np.float32)


def bbox(pos):
    p = pos.reshape(-1, 3)
    return p.min(0).tolist(), p.max(0).tolist()


def pack_named(parts: dict) -> str:
    """Named packed format: u16 len, name, 3*f32 bmin, 3*f32 bmax, u32 nf, nf*9*f32."""
    chunks = []
    enc = "utf-8"
    for name, pos in parts.items():
        if pos.size == 0:
            continue
        bmin, bmax = bbox(pos)
        nf = pos.size // 9
        nm = name.encode(enc)
        buf = bytearray()
        buf += struct.pack("<H", len(nm))
        buf += nm
        buf += struct.pack("<6f", *bmin, *bmax)
        buf += struct.pack("<I", nf)
        buf += pos.tobytes()
        chunks.append(bytes(buf))
    chunks.append(struct.pack("<H", 0))  # terminator
    return base64.b64encode(b"".join(chunks)).decode("ascii")


def split_barbell(tris):
    groups = {
        "bb_disc": [],
        "bb_hub": [],
        "bb_roller": [],
        "bb_coil": [],
    }
    for t in tris:
        cx = sum(v[0] for v in t) / 3
        cy = sum(v[1] for v in t) / 3
        cz = sum(v[2] for v in t) / 3
        r = (cx * cx + cy * cy) ** 0.5
        flat = abs(cz) < 0.08 and r > 0.22
        if r > 0.30 or flat:
            groups["bb_disc"].append(t)
        elif r < 0.14:
            groups["bb_hub"].append(t)
        elif 0.14 <= r < 0.26 and abs(cz) < 0.14:
            groups["bb_roller"].append(t)
        else:
            groups["bb_coil"].append(t)
    return {k: tris_to_positions(v) for k, v in groups.items() if v}


def split_varcwt(tris):
    groups = {
        "vc_frame": [],
        "vc_weight_a": [],
        "vc_weight_b": [],
        "vc_weight_c": [],
        "vc_rotary": [],
    }
    for t in tris:
        cx = sum(v[0] for v in t) / 3
        cy = sum(v[1] for v in t) / 3
        cz = sum(v[2] for v in t) / 3
        r = (cx * cx + cy * cy) ** 0.5
        # Teardrop masses sit in the middle Z band; frame is outer shell / top knob.
        if cz > 0.22 or (r > 0.42 and cz > -0.05):
            groups["vc_rotary"].append(t)
        elif r > 0.38 and cz < 0.05:
            groups["vc_frame"].append(t)
        elif cz < -0.28:
            groups["vc_weight_a"].append(t)
        elif cz < -0.12:
            groups["vc_weight_b"].append(t)
        elif cz < 0.12:
            groups["vc_weight_c"].append(t)
        else:
            groups["vc_frame"].append(t)
    return {k: tris_to_positions(v) for k, v in groups.items() if v}


def split_cab(tris):
    groups = {"cab_side": [], "cab_front": [], "cab_roof": [], "cab_base": []}
    for t in tris:
        cx = sum(v[0] for v in t) / 3
        cy = sum(v[1] for v in t) / 3
        cz = sum(v[2] for v in t) / 3
        if cz > 1.55:
            groups["cab_roof"].append(t)
        elif cz < 0.35:
            groups["cab_base"].append(t)
        elif abs(cx) > 0.35:
            groups["cab_side"].append(t)
        else:
            groups["cab_front"].append(t)
    return {k: tris_to_positions(v) for k, v in groups.items() if v}


def split_ram(tris):
    # Ram head STL is in mm; normalize later in viewer. Split by dominant color regions via Z bands.
    zs = [sum(v[2] for v in t) / 3 for t in tris]
    zmin, zmax = min(zs), max(zs)
    span = zmax - zmin
    groups = {"ram_frame": [], "ram_sheave": [], "ram_mount": []}
    for t in tris:
        cz = sum(v[2] for v in t) / 3
        rel = (cz - zmin) / max(span, 1)
        cx = sum(v[0] for v in t) / 3
        if rel > 0.55:
            groups["ram_sheave"].append(t)
        elif rel < 0.25:
            groups["ram_mount"].append(t)
        else:
            groups["ram_frame"].append(t)
    return {k: tris_to_positions(v) for k, v in groups.items() if v}


def split_roller(tris):
    groups = {"rg_rail": [], "rg_wheel": [], "rg_arm": [], "rg_spring": []}
    for t in tris:
        cx = sum(v[0] for v in t) / 3
        cy = sum(v[1] for v in t) / 3
        cz = sum(v[2] for v in t) / 3
        r = (cx * cx + cy * cy) ** 0.5
        if r > 80 and cz > 120:
            groups["rg_rail"].append(t)
        elif r > 25 or (abs(cx) < 40 and abs(cy) < 40 and cz > 80):
            groups["rg_wheel"].append(t)
        elif cz < 80:
            groups["rg_spring"].append(t)
        else:
            groups["rg_arm"].append(t)
    return {k: tris_to_positions(v) for k, v in groups.items() if v}


def main():
    all_parts = {}
    all_parts.update(split_barbell(read_stl(ROOT / "BARBELL ASSEMBLY.stl")))
    all_parts.update(split_varcwt(read_stl(ROOT / "varaible counterweight.stl")))
    all_parts.update(split_cab(read_stl(ROOT / "Ensamble cabina (paneles + techo).stl")))
    all_parts.update(split_ram(read_stl(ROOT / "ram-head.stl")))
    all_parts.update(split_roller(read_stl(ROOT / "roller-guide.stl")))

    packed = pack_named(all_parts)
    OUT.write_text(
        f"// Auto-generated by pack_meshes.py — do not edit\n"
        f"export const MESHES_PACKED = '{packed}';\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT} ({OUT.stat().st_size/1e6:.2f} MB)")
    for k, v in all_parts.items():
        print(f"  {k}: {v.size//9} tris")


if __name__ == "__main__":
    main()
