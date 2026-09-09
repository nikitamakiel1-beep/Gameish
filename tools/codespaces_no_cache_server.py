#!/usr/bin/env python3
"""No-cache static server for EDEN//FALL Codespaces/Web preview.

Stable Godot filenames such as index.pck and index.wasm make stale browser
caches especially confusing during rapid iteration. This server forces network
reads, supplies deterministic Godot MIME types, and leaves IndexedDB/local
storage untouched so local Web saves are not destroyed.
"""
from __future__ import annotations

import argparse
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "text/javascript",
        ".json": "application/json",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        super().end_headers()

    def log_message(self, fmt: str, *args: object) -> None:
        # Preserve ordinary server visibility while making the prefix obvious in
        # the shared Codespaces terminal/log file.
        super().log_message("[EDEN] " + fmt, *args)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--directory", required=True)
    args = parser.parse_args()

    if not (1 <= args.port <= 65535):
        parser.error("--port must be between 1 and 65535")

    handler = functools.partial(NoCacheHandler, directory=args.directory)
    server = ThreadingHTTPServer((args.bind, args.port), handler)
    server.daemon_threads = True
    print(f"EDEN preview no-cache server: http://{args.bind}:{args.port} -> {args.directory}", flush=True)
    try:
        server.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
