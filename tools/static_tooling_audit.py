#!/usr/bin/env python3
"""Fail-closed syntax audit for EDEN//FALL repository tooling.

No third-party dependencies are used. Python helpers are parsed with `ast` and
shell helpers are checked with `bash -n`. This catches wrapper failures before a
long Godot import/qualification run begins.
"""
from __future__ import annotations

import ast
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
CRITICAL = [
    TOOLS / "codespaces_sync_preview.sh",
    TOOLS / "codespaces_preview.sh",
    TOOLS / "codespaces_serve.sh",
    TOOLS / "export_web_no_actions.sh",
    TOOLS / "publish_gh_pages_no_actions.sh",
    TOOLS / "verify_web_export.py",
    TOOLS / "codespaces_no_cache_server.py",
    TOOLS / "audit_source_counteraudit.py",
    TOOLS / "qualification_counteraudit.py",
    TOOLS / "qualification_countercounteraudit.py",
]


def fail(errors: list[str]) -> int:
    report = {
        "passed": False,
        "errors": errors,
    }
    print("EDEN_STATIC_TOOLING_REPORT=" + json.dumps(report, sort_keys=True))
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    return 1


def main() -> int:
    errors: list[str] = []
    for path in CRITICAL:
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"critical tool missing/empty: {path.relative_to(ROOT)}")

    shell_files = sorted(TOOLS.rglob("*.sh"))
    python_files = sorted(TOOLS.rglob("*.py"))

    for path in shell_files:
        result = subprocess.run(
            ["bash", "-n", str(path)],
            cwd=ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )
        if result.returncode != 0:
            detail = result.stderr.strip() or result.stdout.strip() or f"exit {result.returncode}"
            errors.append(f"shell syntax: {path.relative_to(ROOT)}: {detail}")
        else:
            print(f"EDEN_TOOLING_SHELL_PASS={path.relative_to(ROOT)}")

    for path in python_files:
        try:
            source = path.read_text(encoding="utf-8")
            ast.parse(source, filename=str(path))
        except (OSError, UnicodeError, SyntaxError) as exc:
            errors.append(f"python syntax: {path.relative_to(ROOT)}: {exc}")
        else:
            print(f"EDEN_TOOLING_PYTHON_PASS={path.relative_to(ROOT)}")

    if errors:
        return fail(errors)

    report = {
        "passed": True,
        "shell_files": len(shell_files),
        "python_files": len(python_files),
        "critical_files": len(CRITICAL),
    }
    print("EDEN_STATIC_TOOLING_REPORT=" + json.dumps(report, sort_keys=True))
    print("EDEN_STATIC_TOOLING_AUDIT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
