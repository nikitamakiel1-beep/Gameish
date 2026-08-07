#!/usr/bin/env python3
"""Fail closed on an EDEN//FALL GitHub Pages Web export.

This verifier does not require Godot. It validates the static artifact after the
Godot CLI export and before gh-pages is replaced.
"""
from __future__ import annotations

import json
import pathlib
import re
import sys


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
    info = json.loads((root / "build-info.json").read_text(encoding="utf-8"))

    if info.get("version") != "0.6.2-entropy":
        fail(f"unexpected build version: {info.get('version')!r}")
    if info.get("godot") != "4.7.1":
        fail(f"unexpected Godot version: {info.get('godot')!r}")
    if info.get("source_branch") != "godmode/production-assets-v6-rebuild":
        fail("build-info source branch is not the production feature branch")
    if info.get("pwa") is not False or info.get("threads") is not False:
        fail("GitHub Pages test channel must be non-PWA and non-threaded")

    if "serviceWorker.register" in html or "index.service.worker.js" in html:
        fail("HTML still registers the obsolete PWA service worker")
    if not re.search(r"index(?:\.\w+)?\.wasm|\.wasm", html + js):
        fail("Web loader does not reference a WASM payload")
    if not re.search(r"index(?:\.\w+)?\.pck|\.pck", html + js):
        fail("Web loader does not reference a PCK payload")

    wasm = (root / "index.wasm").read_bytes()[:4]
    if wasm != b"\x00asm":
        fail("index.wasm does not have the WebAssembly magic header")

    pck = root / "index.pck"
    if pck.stat().st_size < 64 * 1024:
        fail(f"index.pck is suspiciously small: {pck.stat().st_size} bytes")

    if (root / "index.wasm").stat().st_size < 5 * 1024 * 1024:
        fail("index.wasm is suspiciously small")

    prohibited = ["index.service.worker.js", "index.offline.html"]
    present = [name for name in prohibited if (root / name).exists()]
    if present:
        fail("PWA-only files present in Pages test export: " + ", ".join(present))

    print(json.dumps({
        "passed": True,
        "root": str(root),
        "version": info["version"],
        "source_commit": info.get("source_commit"),
        "wasm_bytes": (root / "index.wasm").stat().st_size,
        "pck_bytes": pck.stat().st_size,
        "pwa": False,
        "threads": False,
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
