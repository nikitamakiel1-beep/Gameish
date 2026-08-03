#!/usr/bin/env python3
"""Materialize the audited EDEN//FALL v0.3 package from checksum-locked staging data."""
from __future__ import annotations

import base64
import hashlib
import io
import json
import pathlib
import tarfile
import zlib


def decode_payload(path: pathlib.Path) -> bytes:
    return zlib.decompress(base64.b85decode(path.read_text(encoding="ascii").encode("ascii")))


def checked(data: bytes, expected: str, label: str) -> bytes:
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        raise SystemExit(f"checksum mismatch for {label}: {actual} != {expected}")
    return data


def main() -> None:
    root = pathlib.Path(__file__).resolve().parents[1]
    staged = root / ".v3"
    manifest = json.loads((staged / "manifest.json").read_text(encoding="utf-8"))

    encoded_runtime = "".join(
        (staged / f"runtime_{index:02d}.b85").read_text(encoding="ascii")
        for index in range(int(manifest["runtime_parts"]))
    )
    runtime = zlib.decompress(base64.b85decode(encoded_runtime.encode("ascii")))
    checked(runtime, manifest["runtime_sha256"], "scripts/edenfall_v3.gd")
    runtime_target = root / "scripts/edenfall_v3.gd"
    runtime_target.parent.mkdir(parents=True, exist_ok=True)
    runtime_target.write_bytes(runtime)

    generator = checked(decode_payload(staged / "generator.b85"), manifest["generator_sha256"], "directional generator")
    generator_target = root / "tools/generate_directional_assets.py"
    generator_target.write_bytes(generator)

    support = checked(decode_payload(staged / "support.b85"), manifest["support_sha256"], "support bundle")
    with tarfile.open(fileobj=io.BytesIO(support), mode="r:") as archive:
        for member in archive.getmembers():
            destination = (root / member.name).resolve()
            if root.resolve() not in destination.parents and destination != root.resolve():
                raise SystemExit(f"unsafe support path: {member.name}")
        archive.extractall(root, filter="data")

    print("Materialized EDEN//FALL v0.3 runtime, UI/HUD, audit and directional generator")


if __name__ == "__main__":
    main()
