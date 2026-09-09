#!/usr/bin/env python3
"""Counteraudit the EDEN//FALL qualification machinery itself.

Independent of Godot: verifies critical runtime hardening, audit failure paths,
qualification wiring, pinned/recomputed toolchain provenance, and agreement
between exporter/verifier/publisher/preview on the final qualification contract.
"""
from __future__ import annotations

import ast
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_REVISION = "0.6.4-authored-art4"
GODOT_ARCHIVE_SHA256 = "c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"
TEMPLATES_ARCHIVE_SHA256 = "86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
FULL_QUALIFICATION = (
    "all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+"
    "systems-stress+expressive-range+input-lifecycle+legacy+boot+web+counteraudit+"
    "mutation-countercounteraudit+final-artifact-countercounteraudit"
)

RUNTIME_HARDENING: dict[str, tuple[str, ...]] = {
    "scripts/v5/save_repository.gd": (
        "_integrity_sha256",
        "HashingContext.HASH_SHA256",
        "_candidate_is_valid",
        "valid_json_tamper_detection",
        "prepromotion_readback",
        "preserve_good_backup_on_bad_primary",
        "legacy_read_compatibility",
    ),
    "scripts/v6/performance_budget.gd": (
        "func observe_frame",
        "adaptive_scale",
        "PRESSURE_SAMPLES",
        "RECOVERY_SAMPLES",
        "effective_limit",
        "post_frame_auto_observation",
        "gameplay_only_observation",
        "player_bullet_priority",
    ),
    "scripts/edenfall_v6_runtime.gd": (
        'performance_budget.call("enforce_post_frame"',
        'state == "run" and not paused',
        'performance_budget.call("report")',
    ),
    "scripts/v8/entropy_director.gd": (
        "func derive_seed",
        "HashingContext.HASH_SHA256",
        "context_counters",
        "context_isolated_forks",
        "sha256_substream_derivation",
        "rng_algorithm_not_persistence_abi",
    ),
}

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
        "EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT=PASS",
        EXPECTED_REVISION,
        "write_json_atomic",
        "valid_json_tamper_recovery",
        "pressure_scale_observed",
        "context_isolated_forks",
        "signature_diversity",
        "materialize_delay",
        "compose",
        "unique_tokens",
        "push_error",
        "quit(1)",
    ),
    "tests/v8_expressive_range_counteraudit.gd": (
        "EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=PASS",
        EXPECTED_REVISION,
        "story_landmark_pairs",
        "semantic_cells",
        "global_semantic_cells",
        "identity_anchor_cells",
        "legal_variant_cells",
        "approved_modules_only",
        "push_error",
        "quit(1)",
    ),
    "tests/v6_input_lifecycle_audit.gd": (
        "EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=PASS", "Input.action_press", "NOTIFICATION_OS_MEMORY_WARNING", "NOTIFICATION_APPLICATION_FOCUS_OUT", "get_tree().quit(1)"
    ),
}

PIPELINE_REQUIRED = (
    "python3 \"$ROOT/tools/static_tooling_audit.py\"",
    "python3 \"$ROOT/tools/audit_source_counteraudit.py\"",
    GODOT_ARCHIVE_SHA256,
    TEMPLATES_ARCHIVE_SHA256,
    "ensure_verified_archive",
    "zipfile.ZipFile",
    "EXPECTED_TEMPLATE_HASH",
    "EDEN_TOOLCHAIN_GODOT_ARCHIVE_SHA256",
    "EDEN_TOOLCHAIN_TEMPLATES_ARCHIVE_SHA256",
    "EDEN_TOOLCHAIN_WEB_TEMPLATE_MEMBER",
    "EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256",
    "EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256",
    "EDEN_TOOLCHAIN_PROVENANCE=PASS",
    "toolchain-provenance.log",
    'run_audit "res://tests/all_gdscript_compile_audit.gd"',
    'run_audit "res://tests/v8_compile_chain_probe.gd"',
    '"res://tests/v8_release_integrity_audit.gd"',
    '"res://tests/v8_live_binding_counteraudit.gd"',
    '"res://tests/v8_art4_reference_audit.gd"',
    '"res://tests/v8_art4_pixel_counteraudit.gd"',
    '"res://tests/v8_systems_stress_counteraudit.gd"',
    '"res://tests/v8_expressive_range_counteraudit.gd"',
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

    for relative, needles in RUNTIME_HARDENING.items():
        try:
            source = read(relative)
        except (OSError, UnicodeError) as exc:
            errors.append(f"missing/unreadable hardened runtime {relative}: {exc}")
            continue
        require(source, needles, f"hardened runtime {relative}", errors)

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
        counteraudit = read("tools/qualification_counteraudit.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect qualification counteraudit: {exc}")
        counteraudit = ""
    require(
        counteraudit,
        (
            GODOT_ARCHIVE_SHA256,
            TEMPLATES_ARCHIVE_SHA256,
            "v8_expressive_range_counteraudit.log",
            "EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=PASS",
            "toolchain-provenance.log",
            "EDEN_TOOLCHAIN_WEB_TEMPLATE_MEMBER",
            "EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256",
            "recompute_toolchain",
            "unique_zip_member",
            "installed Godot editor differs from the member in the verified official archive",
        ),
        "qualification counteraudit",
        errors,
    )

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
            "verify_portable_counteraudit",
            "EXPECTED_AUDIT_LOGS = 17",
            "EXPECTED_REQUIRED_LOGS = 24",
            "EXPECTED_EXACT_MARKERS = 21",
            "EXPECTED_COUNTERCOUNTER_MUTATIONS = 15",
            "EXPECTED_FINAL_MUTATIONS = 12",
            "final_countercounteraudit_report_sha256",
            "portable countercounteraudit report source commit mismatch",
            "serviceWorker.register",
            "\\x00asm",
            "expressive-range",
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
            "expressive-range",
        ),
        "Pages publisher",
        errors,
    )
    if f'FULL_QUALIFICATION="{FULL_QUALIFICATION}"' not in publisher:
        errors.append("Pages publisher final qualification contract drifted")

    try:
        preview = read("tools/codespaces_serve.sh")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect Codespaces preview boundary: {exc}")
        preview = ""
    require(
        preview,
        (
            "verify_web_export.py",
            "qualification/final-artifact-countercounteraudit-report.json",
            "final_countercounteraudit_passed",
            "source_commit",
            "qualified",
            "playable",
        ),
        "Codespaces preview boundary",
        errors,
    )

    try:
        static_audit = read("tools/static_tooling_audit.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect static tooling audit: {exc}")
        static_audit = ""
    if 'TOOLS / "final_artifact_countercounteraudit.py"' not in static_audit:
        errors.append("static tooling audit does not classify final-artifact countercounteraudit as critical")

    try:
        lower_mutation = read("tools/qualification_countercounteraudit.py")
    except (OSError, UnicodeError) as exc:
        errors.append(f"cannot inspect qualification mutation audit: {exc}")
        lower_mutation = ""
    require(
        lower_mutation,
        (
            EXPECTED_REVISION,
            "source_commit",
            "expected_mutations = 15",
            "missing-expressive-range-pass-marker",
            "wrong-audit-pass-marker",
            "case-insensitive-fatal-diagnostic",
            "corrupt-toolchain-archive-digest",
            "malformed-installed-template-digest",
            "mismatched-installed-template-digest",
            "forged-matching-template-digests",
        ),
        "qualification mutation audit",
        errors,
    )

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
            "counter-report-expressive-contract-forged",
            "counter-report-toolchain-evidence-forged",
            "rebind_counter_hash",
            "expected = 12",
            "--pre-final",
            "mutation_tests",
        ),
        "final-artifact mutation audit",
        errors,
    )

    report = {
        "revision": EXPECTED_REVISION,
        "hardened_runtime_sources": len(RUNTIME_HARDENING),
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
