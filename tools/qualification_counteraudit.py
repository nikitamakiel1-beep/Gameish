#!/usr/bin/env python3
"""Independent counteraudit for an EDEN//FALL qualification run.

Re-reads raw Godot logs, exact PASS markers, source provenance, independently
recomputed toolchain provenance, and Web payload hashes while build-info.json
is still explicitly pending/unqualified.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXPECTED_VERSION = "0.6.4-authored-art4"
EXPECTED_BRANCH = "godmode/production-assets-v6-rebuild"
PENDING_QUALIFICATION = "pending-counteraudits"
GODOT_VERSION = "4.7.1"
GODOT_ARCHIVE_SHA256 = "c7ff14fd28472c8d4f193043de30278dcf7e5241a1dcf7566b02e27addaa33ba"
TEMPLATES_ARCHIVE_SHA256 = "86409db6200b6f8fd3230989c2d2002851f3dd18acf11d7bdbafddf5a0dd0f72"
SHA40 = re.compile(r"^[0-9a-f]{40}$")
SHA256 = re.compile(r"^[0-9a-f]{64}$")
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
    "v8_expressive_range_counteraudit.log": "EDEN_FALL_V8_EXPRESSIVE_RANGE_COUNTERAUDIT=PASS",
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
    "toolchain-provenance.log",
    "import.log",
    *EXPECTED_AUDIT_MARKERS,
    "boot.log",
    "export.log",
    "structural-verifier.log",
]
NON_GODOT_MARKERS = {
    "tooling-audit.log": "EDEN_STATIC_TOOLING_AUDIT=PASS",
    "audit-source-counteraudit.log": "EDEN_AUDIT_SOURCE_COUNTERAUDIT=PASS",
    "toolchain-provenance.log": "EDEN_TOOLCHAIN_PROVENANCE=PASS",
    "structural-verifier.log": "EDEN_WEB_EXPORT_STRUCTURAL_VERIFIER=PASS",
}
CORE_FILES = ("index.html", "index.js", "index.wasm", "index.pck")


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def zip_member_digest(archive: pathlib.Path, member: str) -> str:
    digest = hashlib.sha256()
    with zipfile.ZipFile(archive) as outer:
        with outer.open(member) as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    return digest.hexdigest()


def unique_zip_member(archive: pathlib.Path, predicate, label: str, errors: list[str]) -> str:
    try:
        with zipfile.ZipFile(archive) as outer:
            members = [name for name in outer.namelist() if predicate(name)]
    except (OSError, zipfile.BadZipFile) as exc:
        errors.append(f"cannot inspect {label} archive: {exc}")
        return ""
    if len(members) != 1:
        errors.append(f"expected exactly one {label} archive member, found {len(members)}")
        return ""
    return members[0]


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


def parse_toolchain_log(path: pathlib.Path, errors: list[str]) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if not line.startswith("EDEN_TOOLCHAIN_") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            if key in values:
                errors.append(f"duplicate toolchain evidence key: {key}")
            values[key] = value.strip()
    except OSError as exc:
        errors.append(f"cannot read toolchain provenance: {exc}")
        return values
    expected = {
        "EDEN_TOOLCHAIN_GODOT_ARCHIVE_SHA256": GODOT_ARCHIVE_SHA256,
        "EDEN_TOOLCHAIN_TEMPLATES_ARCHIVE_SHA256": TEMPLATES_ARCHIVE_SHA256,
        "EDEN_TOOLCHAIN_PROVENANCE": "PASS",
    }
    for key, value in expected.items():
        if values.get(key) != value:
            errors.append(f"toolchain provenance mismatch for {key}")
    expected_template_hash = values.get("EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256", "")
    installed_template_hash = values.get("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256", "")
    if not SHA256.fullmatch(expected_template_hash):
        errors.append("TPZ-derived Web template evidence is not a SHA-256 digest")
    if not SHA256.fullmatch(installed_template_hash):
        errors.append("installed Web template evidence is not a SHA-256 digest")
    if expected_template_hash and installed_template_hash and expected_template_hash != installed_template_hash:
        errors.append("installed Web template digest does not match the member derived from the verified official TPZ")
    template_member = values.get("EDEN_TOOLCHAIN_WEB_TEMPLATE_MEMBER", "")
    if not template_member.endswith("web_nothreads_release.zip"):
        errors.append(f"toolchain Web template member is unexpected: {template_member!r}")
    engine_version = values.get("EDEN_TOOLCHAIN_ENGINE_VERSION", "")
    if not engine_version.startswith("4.7.1.stable"):
        errors.append(f"toolchain engine evidence is not exact 4.7.1 stable: {engine_version!r}")
    return values


def template_home() -> pathlib.Path:
    xdg = os.environ.get("XDG_DATA_HOME", "").strip()
    data_home = pathlib.Path(xdg).expanduser() if xdg else pathlib.Path.home() / ".local" / "share"
    return data_home / "godot" / "export_templates" / f"{GODOT_VERSION}.stable"


def recompute_toolchain(log_values: dict[str, str], errors: list[str]) -> dict[str, str]:
    configured = os.environ.get("EDEN_TOOLS_DIR", "").strip()
    tools_dir = pathlib.Path(configured).expanduser() if configured else ROOT / ".tools"
    downloads = tools_dir / "downloads"
    godot_archive = downloads / f"Godot_v{GODOT_VERSION}-stable_linux.x86_64.zip"
    templates_archive = downloads / f"Godot_v{GODOT_VERSION}-stable_export_templates.tpz"
    installed_editor = tools_dir / f"godot-{GODOT_VERSION}" / "godot"
    installed_template = template_home() / "web_nothreads_release.zip"
    evidence: dict[str, str] = {}

    for path, expected, label in (
        (godot_archive, GODOT_ARCHIVE_SHA256, "Godot editor archive"),
        (templates_archive, TEMPLATES_ARCHIVE_SHA256, "Godot templates archive"),
    ):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"independent toolchain evidence missing/empty: {label}")
            continue
        actual = sha256(path)
        evidence[label] = actual
        if actual != expected:
            errors.append(f"independent {label} SHA-256 mismatch")

    if godot_archive.is_file() and godot_archive.stat().st_size > 0:
        editor_member = unique_zip_member(
            godot_archive,
            lambda name: name.endswith("stable_linux.x86_64") and not name.endswith("/"),
            "Godot Linux editor",
            errors,
        )
        if editor_member:
            archive_editor_hash = zip_member_digest(godot_archive, editor_member)
            evidence["editor_member"] = editor_member
            evidence["editor_member_sha256"] = archive_editor_hash
            if not installed_editor.is_file() or installed_editor.stat().st_size == 0:
                errors.append("installed Godot editor is missing/empty during independent counteraudit")
            else:
                installed_editor_hash = sha256(installed_editor)
                evidence["installed_editor_sha256"] = installed_editor_hash
                if installed_editor_hash != archive_editor_hash:
                    errors.append("installed Godot editor differs from the member in the verified official archive")

    if templates_archive.is_file() and templates_archive.stat().st_size > 0:
        template_member = unique_zip_member(
            templates_archive,
            lambda name: name == "web_nothreads_release.zip" or name.endswith("/web_nothreads_release.zip"),
            "Web no-threads template",
            errors,
        )
        if template_member:
            derived_template_hash = zip_member_digest(templates_archive, template_member)
            evidence["template_member"] = template_member
            evidence["template_member_sha256"] = derived_template_hash
            if log_values.get("EDEN_TOOLCHAIN_WEB_TEMPLATE_MEMBER") != template_member:
                errors.append("toolchain log template member differs from independently derived TPZ member")
            if log_values.get("EDEN_TOOLCHAIN_EXPECTED_WEB_TEMPLATE_SHA256") != derived_template_hash:
                errors.append("toolchain log expected template digest differs from independently derived TPZ digest")
            if not installed_template.is_file() or installed_template.stat().st_size == 0:
                errors.append("installed Web no-threads template is missing/empty during independent counteraudit")
            else:
                installed_template_hash = sha256(installed_template)
                evidence["installed_template_sha256"] = installed_template_hash
                if installed_template_hash != derived_template_hash:
                    errors.append("installed Web no-threads template differs from the verified official TPZ member")
                if log_values.get("EDEN_TOOLCHAIN_WEB_TEMPLATE_SHA256") != installed_template_hash:
                    errors.append("toolchain log installed template digest differs from independent rehash")

    return evidence


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--build", default=str(ROOT / "build" / "web"))
    parser.add_argument("--validation", default=str(ROOT / "validation" / "no-actions-art4"))
    parser.add_argument("--report")
    # Test-only optimization used by qualification_countercounteraudit.py after
    # its baseline full recomputation. Production exporter never passes it.
    parser.add_argument("--test-log-only-toolchain", action="store_true", help=argparse.SUPPRESS)
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
    if info.get("godot") != GODOT_VERSION:
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
    if info.get("qualification_stage") != "pending":
        errors.append("pending build must declare qualification_stage=pending")

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

    toolchain = parse_toolchain_log(validation / "toolchain-provenance.log", errors)
    if args.test_log_only_toolchain:
        if os.environ.get("EDEN_MUTATION_TEST") != "1":
            errors.append("test-only toolchain fast path requires EDEN_MUTATION_TEST=1")
        recomputed_toolchain: dict[str, str] = {}
    else:
        recomputed_toolchain = recompute_toolchain(toolchain, errors)

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
        "toolchain": toolchain,
        "recomputed_toolchain": recomputed_toolchain,
        "toolchain_recomputed": not args.test_log_only_toolchain,
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
