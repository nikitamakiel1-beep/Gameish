#!/usr/bin/env python3
"""Fail closed on an EDEN//FALL Web export.

Modes are deliberately staged:

* --structural validates a freshly exported payload while metadata is pending.
* --pre-final validates the provisionally qualified artifact plus the first two
  portable counteraudit reports; this is used only to mutation-test the final
  proof boundary.
* strict/default additionally requires the final-artifact mutation report and
  binds its hash into qualification-proof.json. Only strict mode is publishable.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re

EXPECTED_VERSION = "0.6.4-authored-art4"
EXPECTED_BRANCH = "godmode/production-assets-v6-rebuild"
EXPECTED_CHANNEL = "github-pages-test-no-actions"
EXPECTED_QUALIFICATION = "all-gdscript+release-integrity+live-binding+art4-reference+art4-pixel+systems-stress+input-lifecycle+legacy+boot+web+counteraudit+mutation-countercounteraudit+final-artifact-countercounteraudit"
SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def load_json(path: pathlib.Path, label: str) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid {label}: {exc}")
    if not isinstance(value, dict):
        fail(f"{label} must contain a JSON object")
    return value


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_mutation_report(report: dict, label: str, minimum: int = 8) -> int:
    if report.get("passed") is not True:
        fail(f"{label} is not passing")
    count = int(report.get("mutation_tests", 0))
    if count < minimum:
        fail(f"{label} contains too few mutation tests")
    rejected = report.get("rejected_mutations", [])
    if not isinstance(rejected, list) or len(rejected) != count:
        fail(f"{label} does not prove rejection of every mutation")
    if len(set(str(value) for value in rejected)) != count:
        fail(f"{label} contains duplicate mutation evidence")
    return count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build/web")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--structural", action="store_true")
    mode.add_argument("--pre-final", action="store_true")
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve()
    strictish = not args.structural
    fully_strict = not args.structural and not args.pre_final

    required = ["index.html", "index.js", "index.wasm", "index.pck", ".nojekyll", "build-info.json"]
    if strictish:
        required.extend([
            "qualification-proof.json",
            "qualification/counteraudit-report.json",
            "qualification/countercounteraudit-report.json",
        ])
    if fully_strict:
        required.append("qualification/final-artifact-countercounteraudit-report.json")
    for name in required:
        path = root / name
        if not path.exists():
            fail(f"missing {name}")
        if name != ".nojekyll" and path.stat().st_size == 0:
            fail(f"empty {name}")

    html = (root / "index.html").read_text(encoding="utf-8", errors="replace")
    js = (root / "index.js").read_text(encoding="utf-8", errors="replace")
    info = load_json(root / "build-info.json", "build-info.json")

    if info.get("version") != EXPECTED_VERSION:
        fail(f"unexpected build version: {info.get('version')!r}; expected {EXPECTED_VERSION!r}")
    if info.get("godot") != "4.7.1":
        fail(f"unexpected Godot version: {info.get('godot')!r}")
    if info.get("source_branch") != EXPECTED_BRANCH:
        fail("build-info source branch is not the production feature branch")
    if info.get("channel") != EXPECTED_CHANNEL:
        fail(f"unexpected build channel: {info.get('channel')!r}")
    source_commit = str(info.get("source_commit", ""))
    if not SHA40.fullmatch(source_commit):
        fail(f"source_commit is not a full lowercase Git SHA: {source_commit!r}")
    if info.get("pwa") is not False or info.get("threads") is not False:
        fail("GitHub Pages test channel must be non-PWA and non-threaded")

    if EXPECTED_VERSION not in html:
        fail("HTML does not contain the expected Art4 build marker")
    if "serviceWorker.register" in html or "index.service.worker.js" in html:
        fail("HTML still registers the obsolete PWA service worker")
    if not re.search(r"index(?:\.\w+)?\.wasm|\.wasm", html + js):
        fail("Web loader does not reference a WASM payload")
    if not re.search(r"index(?:\.\w+)?\.pck|\.pck", html + js):
        fail("Web loader does not reference a PCK payload")

    wasm_path = root / "index.wasm"
    pck_path = root / "index.pck"
    if wasm_path.read_bytes()[:4] != b"\x00asm":
        fail("index.wasm does not have the WebAssembly magic header")
    if wasm_path.stat().st_size < 5 * 1024 * 1024:
        fail("index.wasm is suspiciously small")
    if pck_path.stat().st_size < 1024 * 1024:
        fail(f"index.pck is suspiciously small: {pck_path.stat().st_size} bytes")

    prohibited = ["index.service.worker.js", "index.offline.html"]
    present = [name for name in prohibited if (root / name).exists()]
    if present:
        fail("PWA-only files present in Pages test export: " + ", ".join(present))

    proof_summary: dict = {}
    if strictish:
        if info.get("playable") is not True or info.get("qualified") is not True:
            fail("artifact is not explicitly marked playable and qualified")
        if info.get("qualification") != EXPECTED_QUALIFICATION:
            fail(f"unexpected qualification contract: {info.get('qualification')!r}")

        proof = load_json(root / "qualification-proof.json", "qualification-proof.json")
        if proof.get("revision") != EXPECTED_VERSION:
            fail("qualification proof revision mismatch")
        if proof.get("source_commit") != source_commit:
            fail("qualification proof source commit mismatch")
        if proof.get("qualification") != EXPECTED_QUALIFICATION:
            fail("qualification proof contract mismatch")
        if proof.get("counteraudit_passed") is not True:
            fail("qualification proof does not attest counteraudit success")
        if proof.get("countercounteraudit_passed") is not True:
            fail("qualification proof does not attest countercounteraudit success")

        counter_path = root / "qualification" / "counteraudit-report.json"
        countercounter_path = root / "qualification" / "countercounteraudit-report.json"
        counter = load_json(counter_path, "qualification/counteraudit-report.json")
        countercounter = load_json(countercounter_path, "qualification/countercounteraudit-report.json")
        if counter.get("passed") is not True:
            fail("portable counteraudit report is not passing")
        if counter.get("revision") != EXPECTED_VERSION:
            fail("portable counteraudit report revision mismatch")
        if counter.get("source_commit") != source_commit:
            fail("portable counteraudit report source commit mismatch")
        countercounter_tests = verify_mutation_report(countercounter, "portable countercounteraudit report")

        expected_counter_hash = str(proof.get("counteraudit_report_sha256", ""))
        expected_countercounter_hash = str(proof.get("countercounteraudit_report_sha256", ""))
        for key, value in (
            ("counteraudit_report_sha256", expected_counter_hash),
            ("countercounteraudit_report_sha256", expected_countercounter_hash),
        ):
            if not SHA256.fullmatch(value):
                fail(f"qualification proof has malformed {key}")
        actual_counter_hash = sha256(counter_path)
        actual_countercounter_hash = sha256(countercounter_path)
        if actual_counter_hash != expected_counter_hash:
            fail("portable counteraudit report hash does not match qualification proof")
        if actual_countercounter_hash != expected_countercounter_hash:
            fail("portable countercounteraudit report hash does not match qualification proof")

        proof_summary = {
            "counteraudit_report_sha256": actual_counter_hash,
            "countercounteraudit_report_sha256": actual_countercounter_hash,
            "countercounteraudit_mutation_tests": countercounter_tests,
        }

        if fully_strict:
            if proof.get("final_countercounteraudit_passed") is not True:
                fail("qualification proof does not attest final-artifact countercounteraudit success")
            final_path = root / "qualification" / "final-artifact-countercounteraudit-report.json"
            final_report = load_json(final_path, "qualification/final-artifact-countercounteraudit-report.json")
            final_tests = verify_mutation_report(final_report, "final-artifact countercounteraudit report")
            expected_final_hash = str(proof.get("final_countercounteraudit_report_sha256", ""))
            if not SHA256.fullmatch(expected_final_hash):
                fail("qualification proof has malformed final_countercounteraudit_report_sha256")
            actual_final_hash = sha256(final_path)
            if actual_final_hash != expected_final_hash:
                fail("final-artifact countercounteraudit report hash does not match qualification proof")
            proof_summary["final_countercounteraudit_report_sha256"] = actual_final_hash
            proof_summary["final_countercounteraudit_mutation_tests"] = final_tests

    report = {
        "passed": True,
        "mode": "structural" if args.structural else ("pre-final" if args.pre_final else "strict"),
        "root": str(root),
        "version": info["version"],
        "source_commit": source_commit,
        "qualification": info.get("qualification"),
        "wasm_bytes": wasm_path.stat().st_size,
        "pck_bytes": pck_path.stat().st_size,
        "pwa": False,
        "threads": False,
        "proof": proof_summary,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    if args.structural:
        print("EDEN_WEB_EXPORT_STRUCTURAL_VERIFIER=PASS")
    elif args.pre_final:
        print("EDEN_WEB_EXPORT_PRE_FINAL_VERIFIER=PASS")
    else:
        print("EDEN_WEB_EXPORT_VERIFIER=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
