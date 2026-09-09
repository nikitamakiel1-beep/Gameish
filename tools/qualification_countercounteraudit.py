#!/usr/bin/env python3
"""Mutation-test the EDEN//FALL verifier and qualification counteraudit.

A verifier that only passes good input is not enough; this script deliberately
corrupts provenance, cache policy, payload presence, audit markers and hashes,
then requires the lower-level checks to reject every mutation.
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


def expect_failure(name: str, command: list[str], errors: list[str], passed_mutations: list[str]) -> None:
    result = run(command)
    if result.returncode == 0:
        errors.append(f"mutation unexpectedly passed: {name}")
    else:
        passed_mutations.append(name)
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
    passed_mutations: list[str] = []

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

    # Mutate Web metadata and HTML independently. Large WASM/PCK files remain
    # symlinked so counter-counter-auditing is fast and does not duplicate them.
    with tempfile.TemporaryDirectory(prefix="eden-web-mutations-") as temp_root_text:
        temp_root = pathlib.Path(temp_root_text)

        case = temp_root / "stale-version"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["version"] = "0.6.0-stale"
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("stale-version", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, passed_mutations)

        case = temp_root / "malformed-source-sha"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["source_commit"] = "deadbeef"
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("malformed-source-sha", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, passed_mutations)

        case = temp_root / "pwa-enabled"
        link_build(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["pwa"] = True
        (case / "build-info.json").write_text(json.dumps(info), encoding="utf-8")
        expect_failure("pwa-enabled", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, passed_mutations)

        case = temp_root / "service-worker-registration"
        link_build(build, case)
        html = (case / "index.html").read_text(encoding="utf-8", errors="replace")
        (case / "index.html").write_text(html + "\n<script>navigator.serviceWorker.register('bad.js')</script>\n", encoding="utf-8")
        expect_failure("service-worker-registration", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, passed_mutations)

        case = temp_root / "missing-wasm"
        link_build(build, case)
        (case / "index.wasm").unlink()
        expect_failure("missing-wasm", [sys.executable, str(VERIFIER), "--structural", str(case)], errors, passed_mutations)

        # The higher-level counteraudit must also reject altered evidence even
        # when the Web payload itself remains untouched.
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
            passed_mutations,
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
            passed_mutations,
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
            passed_mutations,
        )

    expected_mutations = 8
    if len(passed_mutations) != expected_mutations:
        errors.append(f"expected {expected_mutations} rejected mutations, got {len(passed_mutations)}")

    report = {
        "passed": not errors,
        "mutation_tests": expected_mutations,
        "rejected_mutations": passed_mutations,
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
