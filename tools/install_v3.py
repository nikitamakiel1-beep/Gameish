#!/usr/bin/env python3
"""Materialize the audited EDEN//FALL v0.3 package from checksum-locked Base64 data."""
from __future__ import annotations

import base64
import hashlib
import io
import pathlib
import tarfile
import zlib

RUNTIME_SHA = "9ca3cdafe68a349716ed773187dd9369cb35ccae8e6d0308363bcc86da32d94a"
GENERATOR_SHA = "5260e5fc06173a7d9ad752d6b80a6d8cefc3fd7d045687b4dbb9c30f6c8ae19a"
SUPPORT_SHA = "25b966cff36f50cc4c39b8444f470c494f954a2c90b4ae9921f04e9b7bc31bd4"


def decode_text(encoded: str) -> bytes:
    return zlib.decompress(base64.b64decode(encoded, validate=True))


def checked(data: bytes, expected: str, label: str) -> bytes:
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected:
        raise SystemExit(f"checksum mismatch for {label}: {actual} != {expected}")
    return data


def main() -> None:
    root = pathlib.Path(__file__).resolve().parents[1]
    staged = root / ".v3b"

    runtime_encoded = "".join(
        (staged / f"runtime_{index:02d}.b64").read_text(encoding="ascii").strip()
        for index in range(4)
    )
    runtime = checked(decode_text(runtime_encoded), RUNTIME_SHA, "scripts/edenfall_v3.gd")
    runtime_target = root / "scripts/edenfall_v3.gd"
    runtime_target.parent.mkdir(parents=True, exist_ok=True)
    runtime_target.write_bytes(runtime)

    generator = checked(
        decode_text((staged / "generator.b64").read_text(encoding="ascii").strip()),
        GENERATOR_SHA,
        "tools/generate_directional_assets.py",
    )
    generator_target = root / "tools/generate_directional_assets.py"
    generator_target.write_bytes(generator)

    support = checked(
        decode_text((staged / "support.b64").read_text(encoding="ascii").strip()),
        SUPPORT_SHA,
        "support bundle",
    )
    with tarfile.open(fileobj=io.BytesIO(support), mode="r:") as archive:
        for member in archive.getmembers():
            destination = (root / member.name).resolve()
            if root.resolve() not in destination.parents and destination != root.resolve():
                raise SystemExit(f"unsafe support path: {member.name}")
        archive.extractall(root, filter="data")

    print("Materialized checksum-verified EDEN//FALL v0.3 runtime, UI/HUD and directional assets")


if __name__ == "__main__":
    main()
