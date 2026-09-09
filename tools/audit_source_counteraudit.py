#!/usr/bin/env python3
"""Counteraudit the EDEN//FALL qualification machinery itself.

This is intentionally independent of Godot. It verifies that critical audit
sources contain real failure paths and that export_web_no_actions.sh actually
wires them into the release path. The goal is to prevent a strong audit from
silently becoming dead code.
"""
from __future__ import annotations

import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_REVISION = "0.6.4-authored-art4"

AUDITS: dict[str, tuple[str, ...]] = {
    "tests/all_gdscript_compile_audit.gd": (
        "EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS",
        "script.can_instantiate()",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_compile_chain_probe.gd": (
        "EDEN_COMPILE_CHAIN=PASS",
        "script.can_instantiate()",
        "EDEN_COMPILE_CHAIN=FAIL",
        "quit(1)",
    ),
    "tests/v8_release_integrity_audit.gd": (
        "EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS",
        EXPECTED_REVISION,
        "legacy_art3_preinstall",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_live_binding_counteraudit.gd": (
        "EDEN_FALL_V8_LIVE_BINDING_COUNTERAUDIT=PASS",
        "root.add_child(instance)",
        "sprite_forge",
        "genome_director",
        "world_director",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_art4_reference_audit.gd": (
        "EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS",
        EXPECTED_REVISION,
        "build_player_sheet",
        "build_enemy_sheet",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_art4_pixel_counteraudit.gd": (
        "EDEN_FALL_V8_ART4_PIXEL_COUNTERAUDIT=PASS",
        EXPECTED_REVISION,
        "get_used_rect",
        "build_player_sheet",
        "build_enemy_sheet",
        "build_floor_image",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_systems_stress_counteraudit.gd": (
        "EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT=PASS",
        EXPECTED_REVISION,
        "write_json_atomic",
        "backup_corruption_recovery",
        "admit_bullet",
        "materialize_delay",
        "compose",
        "unique_tokens",
        "push_error",
        "quit(1)",
    ),
    "tests/v6_input_lifecycle_audit.gd": (
        "EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=PASS",
        "Input.action_press",
        "NOTIFICATION_OS_MEMORY_WARNING",
        "NOTIFICATION_APPLICATION_FOCUS_OUT",
        "get_tree().quit(1)",
    ),
}

PIPELINE_REQUIRED = (
    "python3 \"$ROOT/tools/static_tooling_audit.py\"",
    "python3 \"$ROOT/tools/audit_source_counteraudit.py\"",
    'run_audit "res://tests/all_gdscript_compile_audit.gd"',
    'run_audit "res://tests/v8_compile_chain_probe.gd"',
    '"res://tests/v8_release_integrity_audit.gd"',
    '"res://tests/v8_live_binding_counteraudit.gd"',
    '"res://tests/v8_art4_reference_audit.gd"',
    '"res://tests/v8_art4_pixel_counteraudit.gd"',
    '"res://tests/v8_systems_stress_counteraudit.gd"',
    'run_scene_audit "res://tests/v6_input_lifecycle_audit.tscn" "v6_input_lifecycle_audit"',
    "qualification_counteraudit.py",
    "qualification_countercounteraudit.py",
    "qualification/counteraudit-report.json",
    "qualification/countercounteraudit-report.json",
    "verify_web_export.py",
)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise FileNotFoundError(relative)
    return path.read_text(encoding="utf-8")


def main() -> int:
    errors: list[str] = []

    for relative, needles in AUDITS.items():
        try:
            source = read(relative)
        except (OSError, UnicodeError) as exc:
            errors.append(f"missing/unreadable audit source {relative}: {exc}")
            continue
        for needle in needles:
            if needle not in source:
                errors.append(f"audit source {relative} is missing required behavior: {needle}")

    try:
        pipeline = read("tools/export_web_no_actions.sh")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect export pipeline: {exc}")
        pipeline = ""
    for needle in PIPELINE_REQUIRED:
        if needle not in pipeline:
            errors.append(f"export pipeline is not wired to required gate: {needle}")

    try:
        verifier = read("tools/verify_web_export.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect Web verifier: {exc}")
        verifier = ""
    for needle in (
        EXPECTED_REVISION,
        "source_commit",
        "qualified",
        "qualification-proof.json",
        "qualification/counteraudit-report.json",
        "qualification/countercounteraudit-report.json",
        "sha256(counter_path)",
        "serviceWorker.register",
        "\\x00asm",
    ):
        if needle not in verifier:
            errors.append(f"Web verifier is missing required guard: {needle}")

    try:
        publisher = read("tools/publish_gh_pages_no_actions.sh")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect Pages publisher: {exc}")
        publisher = ""
    for needle in (
        "verify_web_export.py",
        "source_commit",
        "qualification-proof.json",
        "qualification/counteraudit-report.json",
        "qualification/countercounteraudit-report.json",
        "git rev-parse HEAD",
    ):
        if needle not in publisher:
            errors.append(f"Pages publisher is missing required provenance guard: {needle}")

    report = {
        "revision": EXPECTED_REVISION,
        "audit_sources": len(AUDITS),
        "pipeline_gates": len(PIPELINE_REQUIRED),
        "errors": errors,
        "passed": not errors,
    }
    print("EDEN_AUDIT_SOURCE_COUNTERAUDIT_REPORT=" + json.dumps(report, sort_keys=True))
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        return 1
    print("EDEN_AUDIT_SOURCE_COUNTERAUDIT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
