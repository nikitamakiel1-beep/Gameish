#!/usr/bin/env python3
"""Generate deterministic eight-direction EDEN//FALL sprite sheets and HUD icons."""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path

from generate_assets import Canvas, write_png, shadow, mix

RGBA = tuple[int, int, int, int]
FRAME = 48
FRAMES = 8
DIRECTIONS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
ACTIONS = ["idle", "walk", "attack", "dash", "hurt", "death"]

PLAYER_STYLES = {
    "adam": {
        "skin": (177, 111, 66, 255), "skin_hi": (224, 153, 94, 255),
        "hair": (229, 222, 190, 255), "hair_shadow": (159, 150, 124, 255),
        "cloth": (69, 98, 39, 255), "accent": (138, 191, 78, 255), "eye": (70, 176, 255, 255),
    },
    "abel": {
        "skin": (201, 151, 111, 255), "skin_hi": (240, 194, 148, 255),
        "hair": (185, 139, 92, 255), "hair_shadow": (112, 78, 56, 255),
        "cloth": (224, 215, 187, 255), "accent": (177, 54, 51, 255), "eye": (74, 118, 126, 255),
    },
    "cain": {
        "skin": (150, 91, 64, 255), "skin_hi": (205, 129, 82, 255),
        "hair": (36, 30, 28, 255), "hair_shadow": (13, 15, 16, 255),
        "cloth": (54, 47, 43, 255), "accent": (207, 48, 42, 255), "eye": (255, 91, 55, 255),
    },
    "seth": {
        "skin": (178, 128, 94, 255), "skin_hi": (224, 173, 126, 255),
        "hair": (43, 50, 62, 255), "hair_shadow": (17, 22, 30, 255),
        "cloth": (45, 83, 131, 255), "accent": (218, 169, 65, 255), "eye": (92, 190, 255, 255),
    },
    "naamah": {
        "skin": (159, 100, 78, 255), "skin_hi": (213, 143, 109, 255),
        "hair": (39, 28, 46, 255), "hair_shadow": (16, 13, 21, 255),
        "cloth": (91, 49, 102, 255), "accent": (190, 96, 209, 255), "eye": (164, 225, 178, 255),
    },
}

ENEMY_IDS = [
    "feral_scavenger", "outlaw_gunner", "raider_brute", "wasteland_hunter", "scrap_cultist", "caravan_outlaw",
    "cherub_drone", "fallen_angel", "watcher_acolyte", "halo_sentinel", "biomech_pilgrim", "ophanim_scout",
    "nephilim_husk", "nephilim_giant", "horned_berserker", "bone_shepherd", "grafted_colossus", "serpent_spawn",
]

BOSS_IDS = ["watcher_engine", "first_nephilim", "gate_cherub", "tower_enoch", "serpent_interface"]


def dir_components(direction: int) -> tuple[int, int]:
    angle = -math.pi / 2 + direction * math.pi / 4
    return int(round(math.cos(angle))), int(round(math.sin(angle)))


def draw_hair(c: Canvas, cx: int, cy: int, style: dict, direction: int, variant: int) -> None:
    c.ellipse(cx, cy, 7, 6, style["hair_shadow"])
    for i in range(7):
        angle = i * math.tau / 7 + variant * 0.17
        x = cx + int(math.cos(angle) * (6 + i % 2))
        y = cy - 3 + int(math.sin(angle) * 4)
        c.ellipse(x, y, 3, 3, style["hair"])
    dx, dy = dir_components(direction)
    if dy >= 0:
        c.rect(cx - 5, cy + 1, 10, 4, style["hair_shadow"])


def draw_directional_humanoid(c: Canvas, ox: int, oy: int, style: dict, direction: int, action: int, frame: int, variant: int = 0, enemy: bool = False) -> None:
    dx, dy = dir_components(direction)
    bob = [0, 1, 0, -1, 0, 1, 0, -1][frame]
    stride = [0, 2, 3, 2, 0, -2, -3, -2][frame] if action == 1 else 0
    recoil = [0, 2, 4, 2, 0, 0, 0, 0][frame] if action == 2 else 0
    dash = [0, 3, 6, 9, 7, 4, 2, 0][frame] if action == 3 else 0
    collapse = min(13, frame * 2) if action == 5 else 0
    hurt_shift = 2 if action == 4 else 0
    cx = ox + 24 - dx * dash
    base = oy + 41 - collapse
    shadow(c, ox + 24, oy + 42, 12, 4)

    # Legs use directional asymmetry so north/south/side movement reads distinctly.
    if abs(dx) > abs(dy):
        c.line(cx - 4, base - 12, cx - 6 - stride * dx, base, style["cloth"], 4)
        c.line(cx + 4, base - 12, cx + 5 + stride * dx, base, style["cloth"], 4)
    else:
        spread = 4 if dy >= 0 else 3
        c.line(cx - spread, base - 12, cx - spread - stride // 2, base, style["cloth"], 4)
        c.line(cx + spread, base - 12, cx + spread + stride // 2, base, style["cloth"], 4)
    c.rect(cx - 9, base - 2, 7, 3, (20, 20, 19, 255))
    c.rect(cx + 2, base - 2, 7, 3, (20, 20, 19, 255))

    body = mix(style["cloth"], (255, 255, 255, 255), 0.55) if action == 4 else style["cloth"]
    c.polygon([(cx - 9, base - 28 + bob), (cx + 9, base - 28 + bob), (cx + 10, base - 11), (cx - 10, base - 11)], body)
    c.rect(cx - 7, base - 24 + bob, 14, 3, style["accent"])
    c.rect(cx - 2, base - 26 + bob, 4, 15, style["hair_shadow"])

    head_x = cx + dx * 2
    head_y = base - 33 + bob + dy
    c.ellipse(head_x, head_y, 7, 7, style["skin"])
    c.rect(head_x - 5, head_y, 10, 4, style["skin_hi"])
    draw_hair(c, head_x, head_y - 4, style, direction, variant)

    # Eyes only on front and side directions; north shows the back of the head.
    if dy >= 0:
        eye_y = head_y
        if dx == 0:
            c.rect(head_x - 4, eye_y, 2, 2, style["eye"])
            c.rect(head_x + 2, eye_y, 2, 2, style["eye"])
        else:
            c.rect(head_x + (3 if dx > 0 else -5), eye_y, 2, 2, style["eye"])

    # Arms and weapon point in the true eight-direction aim vector.
    hand_x = cx + dx * (11 + recoil) + (-dy) * 2
    hand_y = base - 20 + bob + dy * (9 + recoil) + dx * 2
    c.line(cx - 6, base - 23 + bob, cx - dx * 3 - dy * 7, base - 16 + bob, style["skin"], 4)
    c.line(cx + 6, base - 23 + bob, hand_x, hand_y, style["skin"], 4)
    muzzle_x = hand_x + dx * 11
    muzzle_y = hand_y + dy * 11
    c.line(hand_x, hand_y, muzzle_x, muzzle_y, style["accent"], 3)
    c.rect(hand_x - 2, hand_y - 2, 4, 4, style["hair_shadow"])

    if action == 2:
        for trail in range(1, 4):
            tx = muzzle_x + dx * trail * 5
            ty = muzzle_y + dy * trail * 5
            c.ellipse(tx, ty, max(1, 4 - trail), max(1, 4 - trail), (*style["accent"][:3], 240 - trail * 45))
        if variant % 5 == 0:
            c.line(muzzle_x, muzzle_y, muzzle_x + dx * 15 - dy * 5, muzzle_y + dy * 15 + dx * 5, style["accent"], 2)
            c.line(muzzle_x, muzzle_y, muzzle_x + dx * 15 + dy * 5, muzzle_y + dy * 15 - dx * 5, style["accent"], 2)
    if action == 3:
        for t in range(3):
            c.line(cx - dx * (8 + t * 5), base - 24 - dy * t * 2, cx - dx * (16 + t * 7), base - 24 - dy * t * 2, (*style["accent"][:3], 160 - t * 35), 2)
    if action == 4:
        c.line(cx - 10, base - 30, cx - 15, base - 36, (255, 65, 50, 255), 2)
    if action == 5 and frame >= 5:
        c.rect(cx - 13, base - 8, 26, 7, style["cloth"])

    if enemy:
        if dy >= 0:
            c.rect(head_x - 3, head_y, 2, 2, (255, 68, 54, 255))
            c.rect(head_x + 2, head_y, 2, 2, (255, 68, 54, 255))
        if variant % 3 == 0:
            c.line(cx - 10, base - 26, cx - 15, base - 35, style["accent"], 3)
        elif variant % 3 == 1:
            c.ring(cx, base - 20, 12, style["accent"], 1)
        else:
            c.rect(cx - 12, base - 23, 4, 12, style["accent"])


def make_directional_sheet(path: Path, style: dict, variant: int = 0, enemy: bool = False) -> dict:
    sheet = Canvas(FRAME * 8, FRAME * len(ACTIONS) * 8)
    for action in range(len(ACTIONS)):
        for direction in range(8):
            row = action * 8 + direction
            for frame in range(FRAMES):
                draw_directional_humanoid(sheet, frame * FRAME, row * FRAME, style, direction, action, frame, variant, enemy)
    write_png(path, sheet)
    return {
        "path": "res://assets/" + path.as_posix().split("assets/", 1)[1],
        "frame": [FRAME, FRAME], "frames": FRAMES, "directions": DIRECTIONS,
        "actions": {name: i for i, name in enumerate(ACTIONS)}, "row_formula": "action*8+direction",
    }


def enemy_style(index: int) -> dict:
    category = index // 6
    palettes = [
        ((126, 83, 52, 255), (188, 127, 73, 255), (70, 60, 47, 255), (184, 99, 48, 255)),
        ((157, 130, 92, 255), (222, 187, 126, 255), (62, 66, 72, 255), (220, 173, 64, 255)),
        ((126, 91, 73, 255), (191, 135, 99, 255), (66, 48, 44, 255), (184, 63, 48, 255)),
    ]
    skin, skin_hi, cloth, accent = palettes[min(category, 2)]
    if index in (6, 7, 8, 9, 10, 11):
        hair = (194, 187, 165, 255); hair_shadow = (58, 55, 62, 255); eye = (240, 190, 67, 255)
    elif index >= 12:
        hair = (57, 44, 41, 255); hair_shadow = (18, 16, 17, 255); eye = (255, 67, 48, 255)
    else:
        hair = (54, 42, 32, 255); hair_shadow = (22, 20, 18, 255); eye = (225, 80, 53, 255)
    return {"skin": skin, "skin_hi": skin_hi, "hair": hair, "hair_shadow": hair_shadow, "cloth": cloth, "accent": accent, "eye": eye}


def draw_boss(c: Canvas, ox: int, oy: int, direction: int, action: int, frame: int, variant: int) -> None:
    dx, dy = dir_components(direction)
    cx, cy = ox + 48, oy + 52
    pulse = [0, 1, 2, 1, 0, -1, -2, -1][frame]
    palettes = [
        ((46, 83, 102, 255), (104, 174, 205, 255), (226, 177, 74, 255)),
        ((68, 39, 43, 255), (157, 53, 46, 255), (231, 103, 71, 255)),
        ((106, 84, 39, 255), (223, 181, 72, 255), (248, 225, 155, 255)),
        ((54, 36, 68, 255), (139, 71, 164, 255), (225, 133, 242, 255)),
        ((36, 61, 40, 255), (105, 154, 64, 255), (196, 233, 99, 255)),
    ]
    base, mid, glow = palettes[variant]
    shadow(c, cx, oy + 88, 31, 8)
    c.ellipse(cx, cy, 27 + pulse, 25 + pulse, base)
    c.ring(cx, cy, 32 + pulse, mid, 2)
    c.ellipse(cx + dx * 4, cy + dy * 4, 12, 8, (18, 18, 22, 255))
    c.ellipse(cx + dx * 7, cy + dy * 7, 5, 5, glow)
    for arm in range(6):
        a = arm * math.tau / 6 + frame * 0.15 + direction * 0.08
        ax = cx + int(math.cos(a) * 35); ay = cy + int(math.sin(a) * 29)
        c.line(cx + int(math.cos(a) * 20), cy + int(math.sin(a) * 17), ax, ay, mid, 5)
        c.ellipse(ax, ay, 5, 5, glow)
    if action == 1:
        for spread in (-1, 0, 1):
            angle = math.atan2(dy, dx) + spread * 0.22
            ex = cx + int(math.cos(angle) * (38 + frame * 5))
            ey = cy + int(math.sin(angle) * (38 + frame * 5))
            c.ellipse(ex, ey, 4, 4, glow)
            c.line(cx + dx * 18, cy + dy * 18, ex, ey, (*glow[:3], 180), 2)
    elif action == 2:
        c.ring(cx, cy, 38 + frame, glow, 3)
    elif action == 3:
        c.line(cx - 30, cy - 20 + frame * 2, cx + 30, cy + 20 - frame * 2, (255, 70, 55, 255), 4)


def make_boss_sheet(path: Path, variant: int) -> dict:
    frame = 96
    actions = ["idle", "attack", "phase", "death"]
    sheet = Canvas(frame * 8, frame * len(actions) * 8)
    for action in range(len(actions)):
        for direction in range(8):
            row = action * 8 + direction
            for fr in range(8):
                draw_boss(sheet, fr * frame, row * frame, direction, action, fr, variant)
    write_png(path, sheet)
    return {"frame": [96, 96], "frames": 8, "directions": DIRECTIONS, "actions": {n:i for i,n in enumerate(actions)}, "row_formula": "action*8+direction"}


def make_hud_icons(path: Path) -> dict:
    names = ["health", "shield", "scrap", "genome", "dash", "ability", "interact", "pause", "map", "settings", "audio", "haptics", "accessibility", "objective", "weapon", "relic"]
    cell = 16
    sheet = Canvas(cell * 4, cell * 4)
    colors = [(205, 62, 67, 255), (91, 173, 229, 255), (221, 164, 75, 255), (118, 196, 142, 255), (164, 111, 211, 255)]
    for i, name in enumerate(names):
        ox, oy = (i % 4) * cell, (i // 4) * cell
        color = colors[i % len(colors)]
        sheet.ring(ox + 8, oy + 8, 6, (37, 45, 46, 255), 2)
        if name == "health":
            sheet.rect(ox + 6, oy + 3, 4, 10, color); sheet.rect(ox + 3, oy + 6, 10, 4, color)
        elif name == "shield": sheet.polygon([(ox+8,oy+2),(ox+13,oy+5),(ox+12,oy+11),(ox+8,oy+14),(ox+4,oy+11),(ox+3,oy+5)],color)
        elif name == "pause": sheet.rect(ox+4,oy+3,3,10,color); sheet.rect(ox+9,oy+3,3,10,color)
        elif name == "settings":
            sheet.ring(ox+8,oy+8,4,color,2); sheet.ellipse(ox+8,oy+8,2,2,(15,18,19,255))
        elif name == "map":
            sheet.line(ox+3,oy+4,ox+3,oy+12,color,2); sheet.line(ox+8,oy+3,ox+8,oy+13,color,2); sheet.line(ox+13,oy+4,ox+13,oy+12,color,2)
        elif name == "dash": sheet.line(ox+2,oy+10,ox+13,oy+5,color,3)
        else:
            sheet.ellipse(ox+8,oy+8,4,4,color); sheet.rect(ox+7,oy+2,2,3,color)
    write_png(path, sheet)
    return {"frame": [16, 16], "columns": 4, "rows": 4, "icons": {name:i for i,name in enumerate(names)}}


def generate(out: Path) -> dict:
    out.mkdir(parents=True, exist_ok=True)
    manifest = {"version": 3, "directions": DIRECTIONS, "actions": ACTIONS, "players": {}, "enemies": {}, "bosses": {}, "ui": {}}
    for i, (name, style) in enumerate(PLAYER_STYLES.items()):
        path = out / "players" / f"{name}.png"
        manifest["players"][name] = make_directional_sheet(path, style, i, False)
    for i, name in enumerate(ENEMY_IDS):
        path = out / "enemies" / f"{name}.png"
        manifest["enemies"][name] = make_directional_sheet(path, enemy_style(i), i, True)
    for i, name in enumerate(BOSS_IDS):
        path = out / "bosses" / f"{name}.png"
        manifest["bosses"][name] = make_boss_sheet(path, i)
    manifest["ui"]["hud_icons"] = make_hud_icons(out / "ui" / "hud_icons.png")
    files = []
    for path in sorted(out.rglob("*")):
        if path.is_file():
            files.append({"path": path.relative_to(out).as_posix(), "bytes": path.stat().st_size, "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    manifest["files"] = files
    (out / "manifest_v3.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (out / "DIRECTIONAL_ASSET_NOTICE.txt").write_text(
        "EDEN//FALL V3 DIRECTIONAL ASSETS\nOriginal deterministic pixel art generated by tools/generate_directional_assets.py.\n"
        "Eight directions: N, NE, E, SE, S, SW, W, NW. No third-party art or samples are included.\n",
        encoding="utf-8",
    )
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="assets/generated_v3")
    args = parser.parse_args()
    manifest = generate(Path(args.out))
    print(f"Generated {len(manifest['players'])} players, {len(manifest['enemies'])} enemies, {len(manifest['bosses'])} bosses")


if __name__ == "__main__":
    main()
