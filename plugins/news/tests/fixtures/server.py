"""Serve this folder on a free port of 127.0.0.1 and print the port; /blocked answers 403."""

import functools
import http.server
from pathlib import Path


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/blocked":
            self.send_error(403)
        else:
            super().do_GET()


server = http.server.HTTPServer(("127.0.0.1", 0), functools.partial(Handler, directory=str(Path(__file__).parent)))
print(f"port {server.server_port}", flush=True)
server.serve_forever()
