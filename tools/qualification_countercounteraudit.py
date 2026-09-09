#!/usr/bin/env python3
"""Mutation-test the EDEN//FALL verifier and qualification counteraudit.

A verifier that passes good input is insufficient. This script corrupts Web
metadata, payload presence, exact audit markers, diagnostics, toolchain
provenance and hash evidence, then requires the lower-level gates to reject
every mutation.
"""
from __future__ import annotations

import argparse
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "tools" / "verify_web_export.py"
COUNTERAUDIT = ROOT / "tools" / "qualification_counteraudit.py"
EXPECTED_VERSION = "0.6.4-authored-art4"
GODOT_ARCHIVE_SHA256 = "c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def link_build(source: pathlib.Path, destination: pathlib.Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("index.js", "index.wasm", "index.pck"):
        os.symlink(source / name, destination / name)
    for name in ("index.html", "build-info.json", ".nojekyll"):
        shutil.copy2(source / name, destination / name)


def expect_failure(name: str, command: list[str], errors: list[str], rejected: list[str]) -> None:
    result = run(command)
    if result.returncode == 0:
        errors.append(f"mutation unexpectedly passed: {name}")
    else:
        rejected.append(name)
        print(f"EDEN_MUTATION_REJECTED={name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default=str(ROOT / "build" / "web"))
    parser.add_argument("--validation", default=str(ROOT / "validation" / "no-actions-art4"))
    parser.add_argument("--report")
    args = parser.parse_args()

    build = pathlib.Path(args.build).resolve()
    validation = pathlib.Path(args.validation).resolve()
    errors: list[str] = []
    rejected: list[str] = []
    try:
        baseline_info = json.loads((build / "build-info.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        baseline_info = {}
        errors.append(f"cannot read baseline build metadata: {exc}")
    source_commit = str(baseline_info.get("source_commit", ""))

    baseline_verifier = run([sys.executable, str(VERIFIER), "--structural", str(build)])
    if baseline_verifier.returncode != 0 or "EDEN_WEB_EXPORT_STRUCTURAL_VERIFIER=PASS" not in baseline_verifier.stdout:
        errors.append("baseline structural verifier does not pass before mutation testing")

    baseline_counteraudit = run([
        sys.executable,
        str(COUNTERAUDIT),
        "--build", str(build),
        "--validation", str(validation),
    ])
    if baseline_counteraudit.returncode != 0 or "EDEN_QUALIFICATION_COUNTERAUDIT=PASS" not in baseline_counteraudit.stdout:
        errors.append("baseline qualification counteraudit does not pass before mutation testing")

    with tempfile.TemporaryDirectory(prefix="eden-web-mutations-") as temp_root_text:
        temp_root = pathlib.Path(temp_root_text)

        case = temp_root / "stale-version"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["version"] = "0.6.0-stale"
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("stale-version", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, rejected)

        case = temp_root / "malformed-source-sha"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["source_commit"] = "deadbeef"
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("malformed-source-sha", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, rejected)

        case = temp_root / "pwa-enabled"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["pwa"] = True
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("pwa-enabled", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, rejected)

        case = temp_root / "service-worker-registration"
        link_build(build, case)
        html = (case / "index.html").read_text(encoding="utf-8", errors="replace")
        (case / "index.html").write_text(html + "\n<script>navigator.serviceWorker.register('bad.js')</script>\n", encoding="utf-8")
        expect_failure("service-worker-registration", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, rejected)

        case = temp_root / "missing-wasm"
        link_build(build, case)
        (case / "index.wasm").unlink()
        expect_failure("missing-wasm", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, rejected)

        validation_case = temp_root / "validation-marker-missing"
        shutil.copytree(validation, validation_case)
        release_log = validation_case / "v8_release_integrity_audit.log"
        text = release_log.read_text(encoding="utf-8", errors="replace")
        text = text.replace("EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS", "EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=MISSING")
        release_log.write_text(text, encoding="utf-8")
        expect_failure(
            "missing-release-pass-marker",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "expressive-marker-missing"
        shutil.copytree(validation, validation_case)
        expressive_log = validation_case / "v8_expressive_range_counteraudit.log"
        text = expressive_log.read_text(encoding="utf-8", errors="replace")
        text = text.replace(
            "EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=PASS",
            "EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=MISSING",
        )
        expressive_log.write_text(text, encoding="utf-8")
        expect_failure(
            "missing-expressive-range-pass-marker",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "wrong-pass-marker"
        shutil.copytree(validation, validation_case)
        presentation_log = validation_case / "v8_presentation_audit.log"
        text = presentation_log.read_text(encoding="utf-8", errors="replace")
        text = text.replace(
            "EDEN_FALL_V8_PRESENTATION_AUDIT=PASS",
            "EDEN_FALL_V8_ART_DIRECTION_AUDIT=PASS",
        )
        presentation_log.write_text(text, encoding="utf-8")
        expect_failure(
            "wrong-audit-pass-marker",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "case-insensitive-fatal"
        shutil.copytree(validation, validation_case)
        entropy_log = validation_case / "v8_entropy_audit.log"
        with entropy_log.open("a", encoding="utf-8") as handle:
            handle.write("\nscript error: synthetic mutation\n")
        expect_failure(
            "case-insensitive-fatal-diagnostic",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "validation-hash-corrupt"
        shutil.copytree(validation, validation_case)
        hash_path = validation_case / "web-sha256.txt"
        lines = hash_path.read_text(encoding="utf-8").splitlines()
        if lines:
            first = lines[0]
            lines[0] = ("0" if not first.startswith("0") else "1") + first[1:]
            hash_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        expect_failure(
            "corrupt-web-hash-evidence",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "toolchain-archive-corrupt"
        shutil.copytree(validation, validation_case)
        toolchain_path = validation_case / "toolchain-provenance.log"
        text = toolchain_path.read_text(encoding="utf-8")
        text = text.replace(GODOT_ARCHIVE_SHA256, "0" * 64)
        toolchain_path.write_text(text, encoding="utf-8")
        expect_failure(
            "corrupt-toolchain-archive-digest",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "toolchain-template-malformed"
        shutil.copytree(validation, validation_case)
        toolchain_path = validation_case / "toolchain-provenance.log"
        lines = toolchain_path.read_text(encoding="utf-8").splitlines()
        lines = [
            "EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=deadbeef"
            if line.startswith("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=") else line
            for line in lines
        ]
        toolchain_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        expect_failure(
            "malformed-installed-template-digest",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "toolchain-template-mismatch"
        shutil.copytree(validation, validation_case)
        toolchain_path = validation_case / "toolchain-provenance.log"
        lines = toolchain_path.read_text(encoding="utf-8").splitlines()
        lines = [
            "EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=" + ("0" * 64)
            if line.startswith("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=") else line
            for line in lines
        ]
        toolchain_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        expect_failure(
            "mismatched-installed-template-digest",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        validation_case = temp_root / "toolchain-template-pair-forged"
        shutil.copytree(validation, validation_case)
        toolchain_path = validation_case / "toolchain-provenance.log"
        lines = toolchain_path.read_text(encoding="utf-8").splitlines()
        forged = "0" * 64
        rewritten = []
        for line in lines:
            if line.startswith("EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256="):
                rewritten.append("EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256=" + forged)
            elif line.startswith("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256="):
                rewritten.append("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256=" + forged)
            else:
                rewritten.append(line)
        toolchain_path.write_text("\n".join(rewritten) + "\n", encoding="utf-8")
        expect_failure(
            "forged-matching-template-digests",
            [sys.executable, str(COUNTERAUDIT), "--build", str(build), "--validation", str(validation_case)],
            errors,
            rejected,
        )

        case = temp_root / "premature-qualified"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["playable"] = True
        info["qualified"] = True
        info["qualification"] = "forged-before-counteraudits"
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure(
            "premature-qualified-metadata",
            [sys.executable, str(COUNTERAUDIT), "--build", str(case), "--validation", str(validation)],
            errors,
            rejected,
        )

    expected_mutations = 15
    if len(rejected) != expected_mutations:
        errors.append(f"expected {expected_mutations} rejected mutations, got {len(rejected)}")

    report = {
        "revision": EXPECTED_VERSION,
        "source_commit": source_commit,
        "passed": not errors,
        "mutation_tests": expected_mutations,
        "rejected_mutations": rejected,
        "errors": errors,
    }
    serialized = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.report:
        report_path = pathlib.Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(serialized, encoding="utf-8")
    print("EDEN_QUALIFICATION_COUNTERCOUNTERAUDIT_REPORT=" + json.dumps(report, sort_keys=True))
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        return 1
    print("EDEN_QUALIFICATION_COUNTERCOUNTERAUDIT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
