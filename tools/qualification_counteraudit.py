#!/usr/bin/env python3
"""Independent counteraudit for an EDEN//FALL qualification run.

Re-reads raw Godot logs, exact PASS markers, source provenance and Web payload
hashes while build-info.json is still explicitly pending/unqualified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_VERSION = "0.6.4-authored-art4"
EXPECTED_BRANCH = "godmode/production-assets-v6-rebuild"
PENDING_QUALIFICATION = "pending-counteraudits"
SHA40 = re.compile(r"^[0-9a-f]{40}$")
FAIL_RE = re.compile(r"\bEDEN_[A-Z0-9_]*(?:AUDIT|CHAIN|COUNTERAUDIT)=FAIL\b", re.IGNORECASE)
FATAL_RE = re.compile(
    r"SCRIPT ERROR|Parse Error|Parser Error|Compile Error|Invalid call|Invalid get index|"
    r"Failed to load script|Failed to load resource|Cannot get class|FATAL:|"
    r"ERROR:.*(?:script|resource|load|invalid)",
    re.IGNORECASE,
)

EXPECTED_AUDIT_MARKERS = {
    "all_gdscript_compile_audit.log": "EDEN_ALL_GDSCRIPT_COMPILE_AUDIT=PASS",
    "v8_compile_chain_probe.log": "EDEN_COMPILE_CHAIN=PASS",
    "v8_release_integrity_audit.log": "EDEN_FALL_V8_RELEASE_INTEGRITY_AUDIT=PASS",
    "v8_live_binding_counteraudit.log": "EDEN_FALL_V8_LIVE_BINDING_COUNTERAUDIT=PASS",
    "v8_art4_reference_audit.log": "EDEN_FALL_V8_ART4_REFERENCE_AUDIT=PASS",
    "v8_art4_pixel_counteraudit.log": "EDEN_FALL_V8_ART4_PIXEL_COUNTERAUDIT=PASS",
    "v8_systems_stress_counteraudit.log": "EDEN_FALL_V8_SYSTEMS_STRESS_COUNTERAUDIT=PASS",
    "v8_art_direction_audit.log": "EDEN_FALL_V8_ART_DIRECTION_AUDIT=PASS",
    "v8_presentation_audit.log": "EDEN_FALL_V8_PRESENTATION_AUDIT=PASS",
    "v6_factory_audit.log": "EDEN_FALL_V6_FACTORY_AUDIT=PASS",
    "v6_product_rebuild_audit.log": "EDEN_FALL_V6_COMPAT_AUDIT=PASS",
    "v6_input_lifecycle_audit.log": "EDEN_FALL_V6_INPUT_LIFECYCLE_AUDIT=PASS",
    "v7_masterpiece_audit.log": "EDEN_FALL_V7_COMPAT_AUDIT=PASS",
    "v7_runtime_quality_audit.log": "EDEN_FALL_V7_RUNTIME_COMPAT_AUDIT=PASS",
    "v8_entropy_audit.log": "EDEN_FALL_V8_ENTROPY_AUDIT=PASS",
    "v8_sprite_streaming_audit.log": "EDEN_FALL_V8_SPRITE_STREAMING_AUDIT=PASS",
}
REQUIRED_LOGS = [
    "tooling-audit.log",
    "audit-source-counteraudit.log",
    "import.log",
    *EXPECTED_AUDIT_MARKERS,
    "boot.log",
    "export.log",
    "structural-verifier.log",
]
NON_GODOT_MARKERS = {
    "tooling-audit.log": "EDEN_STATIC_TOOLING_AUDIT=PASS",
    "audit-source-counteraudit.log": "EDEN_AUDIT_SOURCE_COUNTERAUDIT=PASS",
    "structural-verifier.log": "EDEN_WEB_EXPORT_STRUCTURAL_VERIFIER=PASS",
}
CORE_FILES = ("index.html", "index.js", "index.wasm", "index.pck")


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git_head() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def git_branch() -> str:
    result = subprocess.run(
        ["git", "rev-parse", "--abbrev-ref", "HEAD"],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    return result.stdout.strip() if result.returncode == 0 else ""


def parse_hash_manifest(path: pathlib.Path) -> dict[str, str]:
    parsed: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) < 2:
            continue
        name = pathlib.Path(parts[-1]).name
        parsed[name] = parts[0]
    return parsed


def marker_exact_once(path: pathlib.Path, marker: str, errors: list[str]) -> None:
    text = path.read_text(encoding="utf-8", errors="replace")
    if text.count(marker) != 1:
        errors.append(f"required marker must appear exactly once in {path.name}: {marker}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default=str(ROOT / "build" / "web"))
    parser.add_argument("--validation", default=str(ROOT / "validation" / "no-actions-art4"))
    parser.add_argument("--report")
    args = parser.parse_args()

    build = pathlib.Path(args.build).resolve()
    validation = pathlib.Path(args.validation).resolve()
    errors: list[str] = []

    head = git_head()
    branch = git_branch()
    if not SHA40.fullmatch(head):
        errors.append(f"cannot resolve current source HEAD: {head!r}")
    if branch not in (EXPECTED_BRANCH, "HEAD"):
        errors.append(f"counteraudit running from unexpected branch: {branch!r}")

    info_path = build / "build-info.json"
    try:
        info = json.loads(info_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        info = {}
        errors.append(f"invalid pending build-info.json: {exc}")

    if info.get("version") != EXPECTED_VERSION:
        errors.append("pending build version mismatch")
    if info.get("godot") != "4.7.1":
        errors.append("pending build Godot version mismatch")
    if info.get("source_branch") != EXPECTED_BRANCH:
        errors.append("pending build source branch mismatch")
    if info.get("source_commit") != head:
        errors.append("pending build source commit does not equal current HEAD")
    if info.get("pwa") is not False or info.get("threads") is not False:
        errors.append("pending Web build must be non-PWA and non-threaded")
    if info.get("playable") is not False or info.get("qualified") is not False:
        errors.append("build was marked playable/qualified before counteraudits completed")
    if info.get("qualification") != PENDING_QUALIFICATION:
        errors.append("pending qualification state is missing or incorrect")

    source_commit_path = validation / "source-commit.txt"
    try:
        recorded_head = source_commit_path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        recorded_head = ""
        errors.append(f"missing source-commit evidence: {exc}")
    if recorded_head != head:
        errors.append("source-commit evidence does not equal current HEAD")

    for name in REQUIRED_LOGS:
        path = validation / name
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"required qualification log missing/empty: {name}")
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        fatal = FATAL_RE.search(text)
        if fatal:
            errors.append(f"fatal diagnostic {fatal.group(0)!r} found in {name}")
        if FAIL_RE.search(text):
            errors.append(f"explicit FAIL marker found in {name}")

    for name, marker in EXPECTED_AUDIT_MARKERS.items():
        path = validation / name
        if path.is_file():
            marker_exact_once(path, marker, errors)
    for name, marker in NON_GODOT_MARKERS.items():
        path = validation / name
        if path.is_file():
            marker_exact_once(path, marker, errors)

    hash_manifest_path = validation / "web-sha256.txt"
    try:
        manifest = parse_hash_manifest(hash_manifest_path)
    except OSError as exc:
        manifest = {}
        errors.append(f"missing Web hash manifest: {exc}")
    if set(manifest) != set(CORE_FILES):
        errors.append("Web hash manifest must contain exactly the four core payload files")
    for name in CORE_FILES:
        path = build / name
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"core Web payload missing/empty: {name}")
            continue
        actual = sha256(path)
        recorded = manifest.get(name, "")
        if actual != recorded:
            errors.append(f"Web payload hash mismatch for {name}")

    html_path = build / "index.html"
    if html_path.is_file():
        html = html_path.read_text(encoding="utf-8", errors="replace")
        if EXPECTED_VERSION not in html:
            errors.append("Art4 revision marker absent from index.html")
        if "serviceWorker.register" in html or "index.service.worker.js" in html:
            errors.append("obsolete service-worker registration found in index.html")

    report = {
        "revision": EXPECTED_VERSION,
        "source_commit": head,
        "source_branch": branch,
        "required_logs": len(REQUIRED_LOGS),
        "audit_logs": len(EXPECTED_AUDIT_MARKERS),
        "exact_markers": len(EXPECTED_AUDIT_MARKERS) + len(NON_GODOT_MARKERS),
        "core_hashes_checked": len(CORE_FILES),
        "errors": errors,
        "passed": not errors,
    }
    serialized = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.report:
        report_path = pathlib.Path(args.report)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(serialized, encoding="utf-8")
    print("EDEN_QUALIFICATION_COUNTERAUDIT_REPORT=" + json.dumps(report, sort_keys=True))
    if errors:
        for error in errors:
            print("ERROR: " + error, file=sys.stderr)
        return 1
    print("EDEN_QUALIFICATION_COUNTERAUDIT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
