#!/usr/bin/env python3
"""Fail closed on an EDEN//FALL Web export.

Two modes are intentional:

* --structural validates the freshly exported payload while it is still marked
  pending/unqualified.
* strict/default validates a publishable artifact and requires the qualification
  proof written only after audit, counteraudit and mutation countercounteraudit.
"""
from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

EXPECTED_VERSION = "0.6.4-authored-art4"
EXPECTED_BRANCH = "godmode/production-assets-v6-rebuild"
EXPECTED_CHANNEL = "github-pages-test-no-actions"
EXPECTED_QUALIFICATION = "all-gdscript+release-integrity+live-binding+art4+legacy+boot+web+counteraudit+mutation-countercounteraudit"
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


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default="build/web")
    parser.add_argument("--structural", action="store_true")
    args = parser.parse_args()

    root = pathlib.Path(args.root).resolve()
    required = ["index.html", "index.js", "index.wasm", "index.pck", ".nojekyll", "build-info.json"]
    if not args.structural:
        required.append("qualification-proof.json")
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
    if not args.structural:
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
        for key in ("counteraudit_report_sha256", "countercounteraudit_report_sha256"):
            value = str(proof.get(key, ""))
            if not SHA256.fullmatch(value):
                fail(f"qualification proof has malformed {key}")
        proof_summary = {
            "counteraudit_report_sha256": proof["counteraudit_report_sha256"],
            "countercounteraudit_report_sha256": proof["countercounteraudit_report_sha256"],
        }

    report = {
        "passed": True,
        "mode": "structural" if args.structural else "strict",
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
    else:
        print("EDEN_WEB_EXPORT_VERIFIER=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
