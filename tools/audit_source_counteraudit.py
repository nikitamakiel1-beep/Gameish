#!/usr/bin/env python3
"""Counteraudit the EDEN//FALL qualification machinery itself.

Independent of Godot: verifies that critical audit sources contain failure paths,
that the export pipeline wires every stage, and that export/verifier/publisher
agree on the exact final qualification contract.
"""
from __future__ import annotations

import ast
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_REVISION = "0.6.4-authored-art4"
FULL_QUALIFICATION = (
    "all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+"
    "systems-stress+input-lifecycle+legacy+boot+web+counteraudit+"
    "mutation-countercounteraudit+final-artifact-countercounteraudit"
)

AUDITS: dict[str, tuple[str, ...]] = {
    "tests/all_gdscript_compile_audit.gd": (
        "EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS", "script.can_instantiate()", "push_error", "quit(1)"
    ),
    "tests/v8_compile_chain_probe.gd": (
        "EDEN_COMPILE_CHAIN=PASS", "script.can_instantiate()", "EDEN_COMPILE_CHAIN=FAIL", "quit(1)"
    ),
    "tests/v8_release_integrity_audit.gd": (
        "EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS", EXPECTED_REVISION, "legacy_art3_preinstall", "push_error", "quit(1)"
    ),
    "tests/v8_live_binding_counteraudit.gd": (
        "EDEN_FALL_V8_LIVE_BINDING_COUNTERAUDIT=PASS", "root.add_child(instance)", "sprite_forge", "genome_director", "world_director", "push_error", "quit(1)"
    ),
    "tests/v8_art4_reference_audit.gd": (
        "EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS", EXPECTED_REVISION, "build_player_sheet", "build_enemy_sheet", "push_error", "quit(1)"
    ),
    "tests/v8_art4_pixel_counteraudit.gd": (
        "EDEN_FALL_V8_ART4_PIXEL_COUNTERAUDIT=PASS", EXPECTED_REVISION, "get_used_rect", "build_player_sheet", "build_enemy_sheet", "build_floor_image", "push_error", "quit(1)"
    ),
    "tests/v8_systems_stress_counteraudit.gd": (
        "EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT=PASS", EXPECTED_REVISION, "write_json_atomic", "backup_corruption_recovery", "admit_bullet", "materialize_delay", "compose", "unique_tokens", "push_error", "quit(1)"
    ),
    "tests/v6_input_lifecycle_audit.gd": (
        "EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=PASS", "Input.action_press", "NOTIFICATION_OS_MEMORY_WARNING", "NOTIFICATION_APPLICATION_FOCUS_OUT", "get_tree().quit(1)"
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
    "final_artifact_countercounteraudit.py",
    "qualification/counteraudit-report.json",
    "qualification/countercounteraudit-report.json",
    "final-artifact-countercounteraudit-report.json",
    "verify_web_export.py\" --pre-final",
    "payload_sha256",
    "qualification_stage",
    "BOOT_CODE -ne 0",
    "final_countercounteraudit_passed",
)


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file() or path.stat().st_size == 0:
        raise FileNotFoundError(relative)
    return path.read_text(encoding="utf-8")


def require(source: str, needles: tuple[str, ...], label: str, errors: list[str]) -> None:
    for needle in needles:
        if needle not in source:
            errors.append(f"{label} is missing required guard: {needle}")


def python_string_constant(source: str, name: str) -> str:
    try:
        tree = ast.parse(source)
    except SyntaxError:
        return ""
    for node in tree.body:
        if isinstance(node, ast.Assign):
            if any(isinstance(target, ast.Name) and target.id == name for target in node.targets):
                try:
                    value = ast.literal_eval(node.value)
                except (ValueError, TypeError):
                    return ""
                return value if isinstance(value, str) else ""
    return ""


def main() -> int:
    errors: list[str] = []

    for relative, needles in AUDITS.items():
        try:
            source = read(relative)
        except (OSError, UnicodeError) as exc:
            errors.append(f"missing/unreadable audit source {relative}: {exc}")
            continue
        require(source, needles, f"audit source {relative}", errors)

    try:
        pipeline = read("tools/export_web_no_actions.sh")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect export pipeline: {exc}")
        pipeline = ""
    require(pipeline, PIPELINE_REQUIRED, "export pipeline", errors)
    if f'FULL_QUALIFICATION="{FULL_QUALIFICATION}"' not in pipeline:
        errors.append("export pipeline final qualification contract drifted")

    try:
        verifier = read("tools/verify_web_export.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect Web verifier: {exc}")
        verifier = ""
    require(
        verifier,
        (
            EXPECTED_REVISION,
            "source_commit",
            "qualified",
            "qualification-proof.json",
            "qualification/counteraudit-report.json",
            "qualification/countercounteraudit-report.json",
            "qualification/final-artifact-countercounteraudit-report.json",
            "payload_sha256",
            "qualification_stage",
            "verify_payload_hashes",
            "final_countercounteraudit_report_sha256",
            "serviceWorker.register",
            "\\x00asm",
        ),
        "Web verifier",
        errors,
    )
    if python_string_constant(verifier, "EXPECTED_QUALIFICATION") != FULL_QUALIFICATION:
        errors.append("Web verifier final qualification contract drifted")

    try:
        publisher = read("tools/publish_gh_pages_no_actions.sh")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect Pages publisher: {exc}")
        publisher = ""
    require(
        publisher,
        (
            "verify_web_export.py",
            "source_commit",
            "qualification-proof.json",
            "qualification/counteraudit-report.json",
            "qualification/countercounteraudit-report.json",
            "qualification/final-artifact-countercounteraudit-report.json",
            "final_countercounteraudit_passed",
            "final_countercounteraudit_report_sha256",
            "git rev-parse HEAD",
        ),
        "Pages publisher",
        errors,
    )
    if f'FULL_QUALIFICATION="{FULL_QUALIFICATION}"' not in publisher:
        errors.append("Pages publisher final qualification contract drifted")

    try:
        static_audit = read("tools/static_tooling_audit.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect static tooling audit: {exc}")
        static_audit = ""
    if 'TOOLS / "final_artifact_countercounteraudit.py"' not in static_audit:
        errors.append("static tooling audit does not classify final-artifact countercounteraudit as critical")

    try:
        final_mutation = read("tools/final_artifact_countercounteraudit.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect final-artifact mutation audit: {exc}")
        final_mutation = ""
    require(
        final_mutation,
        (
            "EDEN_FINAL_ARTIFACT_COUNTERCOUNTERAUDIT=PASS",
            "payload-html-tamper",
            "proof-payload-hash-forged",
            "--pre-final",
            "mutation_tests",
        ),
        "final-artifact mutation audit",
        errors,
    )

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
