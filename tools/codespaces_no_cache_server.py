#!/usr/bin/env python3
"""No-cache static server for EDEN//FALL Codespaces/Web preview.

The preview channel is iterated frequently using stable filenames such as
index.pck and index.wasm. Explicit no-store headers prevent browser HTTP cache
from masking a newly qualified export. This intentionally does not clear
IndexedDB/local storage, where Web saves may live.
"""
from __future__ import annotations

import argparse
import functools
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--directory", required=True)
    args = parser.parse_args()

    handler = functools.partial(NoCacheHandler, directory=args.directory)
    server = ThreadingHTTPServer((args.bind, args.port), handler)
    print(f"EDEN preview no-cache server: http://{args.bind}:{args.port} -> {args.directory}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
