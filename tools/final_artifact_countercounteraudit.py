#!/usr/bin/env python3
"""Mutation-test the finalized EDEN//FALL qualification boundary.

This runs after the first two counteraudit reports have been embedded and the
artifact has been provisionally promoted. It requires the pre-final verifier to
reject forged metadata, proofs, portable evidence and post-audit payload edits
before the final mutation report itself is bound into qualification-proof.json.
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
EXPECTED_VERSION = "0.6.4-authored-art4"


def run(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )


def clone_lightweight(source: pathlib.Path, destination: pathlib.Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    for name in ("index.js", "index.wasm", "index.pck"):
        os.symlink(source / name, destination / name)
    for name in ("index.html", "build-info.json", "qualification-proof.json", ".nojekyll"):
        shutil.copy2(source / name, destination / name)
    shutil.copytree(source / "qualification", destination / "qualification")


def expect_rejected(name: str, case: pathlib.Path, errors: list[str], rejected: list[str]) -> None:
    result = run([sys.executable, str(VERIFIER), "--pre-final", str(case)])
    if result.returncode == 0:
        errors.append(f"final-artifact mutation unexpectedly passed: {name}")
    else:
        rejected.append(name)
        print(f"EDEN_FINAL_MUTATION_REJECTED={name}")


def write_json(path: pathlib.Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default=str(ROOT / "build" / "web"))
    parser.add_argument("--report")
    args = parser.parse_args()
    build = pathlib.Path(args.build).resolve()
    errors: list[str] = []
    rejected: list[str] = []

    try:
        baseline_info = json.loads((build / "build-info.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read baseline build metadata: {exc}", file=sys.stderr)
        return 1
    source_commit = str(baseline_info.get("source_commit", ""))

    baseline = run([sys.executable, str(VERIFIER), "--pre-final", str(build)])
    if baseline.returncode != 0 or "EDEN_WEB_EXPORT_PRE_FINAL_VERIFIER=PASS" not in baseline.stdout:
        errors.append("baseline pre-final verifier does not pass")

    with tempfile.TemporaryDirectory(prefix="eden-final-mutations-") as temporary:
        root = pathlib.Path(temporary)

        case = root / "qualified-false"
        clone_lightweight(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["qualified"] = False
        write_json(case / "build-info.json", info)
        expect_rejected("qualified-false", case, errors, rejected)

        case = root / "stale-qualification"
        clone_lightweight(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["qualification"] = "stale-contract"
        write_json(case / "build-info.json", info)
        expect_rejected("stale-qualification", case, errors, rejected)

        case = root / "proof-source-mismatch"
        clone_lightweight(build, case)
        proof = json.loads((case / "qualification-proof.json").read_text(encoding="utf-8"))
        proof["source_commit"] = "0" * 40
        write_json(case / "qualification-proof.json", proof)
        expect_rejected("proof-source-mismatch", case, errors, rejected)

        case = root / "proof-counter-hash-forged"
        clone_lightweight(build, case)
        proof = json.loads((case / "qualification-proof.json").read_text(encoding="utf-8"))
        proof["counteraudit_report_sha256"] = "0" * 64
        write_json(case / "qualification-proof.json", proof)
        expect_rejected("proof-counter-hash-forged", case, errors, rejected)

        case = root / "proof-payload-hash-forged"
        clone_lightweight(build, case)
        proof = json.loads((case / "qualification-proof.json").read_text(encoding="utf-8"))
        payload = dict(proof.get("payload_sha256", {}))
        payload["index.pck"] = "0" * 64
        proof["payload_sha256"] = payload
        write_json(case / "qualification-proof.json", proof)
        expect_rejected("proof-payload-hash-forged", case, errors, rejected)

        case = root / "payload-html-tamper"
        clone_lightweight(build, case)
        html_path = case / "index.html"
        html_path.write_text(
            html_path.read_text(encoding="utf-8", errors="replace") + "\n<!-- mutation -->\n",
            encoding="utf-8",
        )
        expect_rejected("payload-html-tamper", case, errors, rejected)

        case = root / "counter-report-failed"
        clone_lightweight(build, case)
        report_path = case / "qualification" / "counteraudit-report.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        report["passed"] = False
        write_json(report_path, report)
        expect_rejected("counter-report-failed", case, errors, rejected)

        case = root / "countercounter-evidence-truncated"
        clone_lightweight(build, case)
        report_path = case / "qualification" / "countercounteraudit-report.json"
        report = json.loads(report_path.read_text(encoding="utf-8"))
        rejected_mutations = list(report.get("rejected_mutations", []))
        report["rejected_mutations"] = rejected_mutations[:-1]
        write_json(report_path, report)
        expect_rejected("countercounter-evidence-truncated", case, errors, rejected)

        case = root / "counter-report-missing"
        clone_lightweight(build, case)
        (case / "qualification" / "counteraudit-report.json").unlink()
        expect_rejected("counter-report-missing", case, errors, rejected)

        case = root / "malformed-source-sha"
        clone_lightweight(build, case)
        info = json.loads((case / "build-info.json").read_text(encoding="utf-8"))
        info["source_commit"] = "deadbeef"
        write_json(case / "build-info.json", info)
        expect_rejected("malformed-source-sha", case, errors, rejected)

    expected = 10
    if len(rejected) != expected:
        errors.append(f"expected {expected} final-artifact mutations to be rejected, got {len(rejected)}")

    report = {
        "revision": EXPECTED_VERSION,
        "source_commit": source_commit,
        "passed": not errors,
        "mutation_tests": expected,
        "rejected_mutations": rejected,
        "errors": errors,
    }
    serialized = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.report:
        path = pathlib.Path(args.report)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(serialized, encoding="utf-8")
    print("EDEN_FINAL_ARTIFACT_COUNTERCOUNTERAUDIT_REPORT=" + json.dumps(report, sort_keys=True))
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        return 1
    print("EDEN_FINAL_ARTIFACT_COUNTERCOUNTERAUDIT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
