#!/usr/bin/env python3
"""Apply Godot 4.6 strict typing corrections after v3 materialization."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
runtime_path = root / "scripts/edenfall_v3.gd"
text = runtime_path.read_text(encoding="utf-8")
replacements = {
    'var candidate := base + DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)]':
        'var candidate: Vector2i = base + Vector2i(DIRECTIONS[rng.randi_range(0, DIRECTIONS.size() - 1)])',
    'var target := nearest_enemy(Vector2(player["pos"]))':
        'var target: Variant = nearest_enemy(Vector2(player["pos"]))',
    'var legacy := ["watcher_engine","nephilim_king","seraph_reactor","void_archon","eden_warden"][index]':
        'var legacy: String = String(["watcher_engine","nephilim_king","seraph_reactor","void_archon","eden_warden"][index])',
    'var row := directional_row(action,dir); var fps := [5.0,10.0,14.0,16.0,10.0,8.0][int(ACTION_ROWS[action])]; var frame := posmod(int(visual_clock*fps),8)':
        'var row: int = directional_row(action,dir); var fps: float = float([5.0,10.0,14.0,16.0,10.0,8.0][int(ACTION_ROWS[action])]); var frame: int = posmod(int(visual_clock*fps),8)',
}
for old, new in replacements.items():
    if old not in text:
        raise SystemExit(f"expected runtime expression not found: {old}")
    text = text.replace(old, new, 1)
runtime_path.write_text(text, encoding="utf-8")

# Make the audit's runtime types explicit as well.
audit_path = root / "tests/v3_audit.gd"
audit = audit_path.read_text(encoding="utf-8")
audit = audit.replace('var runtime_script = load(script_path)', 'var runtime_script: Script = load(script_path) as Script')
audit = audit.replace('var runtime = runtime_script.new()', 'var runtime: Node2D = runtime_script.new() as Node2D')
audit_path.write_text(audit, encoding="utf-8")
print("Applied Godot 4.6 strict typing corrections")
