#!/usr/bin/env python3
"""Fail closed on an EDEN//FALL GitHub Pages Web export.

This verifier does not require Godot. It validates the static artifact after the
Godot CLI export and before gh-pages is replaced. It deliberately rejects stale
Art3/v0.6.0 packages, PWA leftovers, malformed provenance, and suspicious payloads.
"""
from __future__ import annotations

import json
import pathlib
import re
import sys

EXPECTED_VERSION = "0.6.4-authored-art4"
EXPECTED_BRANCH = "godmode/production-assets-v6-rebuild"
EXPECTED_CHANNEL = "github-pages-test-no-actions"
EXPECTED_QUALIFICATION = "all-gdscript+release-integrity+art4+legacy+boot+web"
SHA40 = re.compile(r"^[0-9a-f]{40}$")


def fail(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")


def main() -> int:
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "build/web").resolve()
    required = ["index.html", "index.js", "index.wasm", "index.pck", ".nojekyll", "build-info.json"]
    for name in required:
        path = root / name
        if not path.exists():
            fail(f"missing {name}")
        if name != ".nojekyll" and path.stat().st_size == 0:
            fail(f"empty {name}")

    html = (root / "index.html").read_text(encoding="utf-8", errors="replace")
    js = (root / "index.js").read_text(encoding="utf-8", errors="replace")
    try:
        info = json.loads((root / "build-info.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        fail(f"invalid build-info.json: {exc}")

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
    if info.get("playable") is not True or info.get("qualified") is not True:
        fail("artifact is not explicitly marked playable and qualified")
    if info.get("qualification") != EXPECTED_QUALIFICATION:
        fail(f"unexpected qualification contract: {info.get('qualification')!r}")

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

    print(json.dumps({
        "passed": True,
        "root": str(root),
        "version": info["version"],
        "source_commit": source_commit,
        "qualification": info["qualification"],
        "wasm_bytes": wasm_path.stat().st_size,
        "pck_bytes": pck_path.stat().st_size,
        "pwa": False,
        "threads": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
