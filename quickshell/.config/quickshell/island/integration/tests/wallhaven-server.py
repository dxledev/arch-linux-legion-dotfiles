import json, sys, os
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
root = sys.argv[1]
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def send(self, body, kind="application/json", code=200):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(code); self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data))); self.end_headers(); self.wfile.write(data)
    def do_GET(self):
        url = urlparse(self.path); query = parse_qs(url.query)
        with open(os.path.join(root, "requests.log"), "a") as log:
            log.write(json.dumps({"path": url.path, "query": {k: v[0] for k, v in query.items()},
                                  "key": self.headers.get("X-API-Key", "")}) + "\n")
        port = self.server.server_port
        item = {"id": "abc123", "url": "http://x/w/abc123", "short_url": "x", "views": 12, "favorites": 3,
                "source": "", "purity": "sfw", "category": "general", "dimension_x": 160, "dimension_y": 90,
                "resolution": "160x90", "ratio": "1.78", "file_size": 1000, "file_type": "image/png",
                "created_at": "2026-01-01 00:00:00", "colors": ["#660000", "#bad"],
                "path": "http://127.0.0.1:%d/full/wallhaven-abc123.png" % port,
                "thumbs": {"large": "http://127.0.0.1:%d/thumb/l.png" % port, "original": "http://127.0.0.1:%d/thumb/o.png" % port,
                             "small": "http://127.0.0.1:%d/thumb/s.png" % port}}
        if url.path.endswith("/search"):
            page = int(query.get("page", ["1"])[0])
            items = [item if (page, n) == (1, 0) else dict(item, id="p%di%02d" % (page, n)) for n in range(24)]
            self.send({"data": items, "meta": {"current_page": int(query.get("page", ["1"])[0]), "last_page": 3, "per_page": 24, "total": 60,
                                                "query": query.get("q", [""])[0], "seed": "Ab12Cd"}})
        elif url.path.endswith("/w/abc123"):
            self.send({"data": dict(item, tags=[{"id": 1, "name": "sky", "category": "Nature", "purity": "sfw"}],
                                    uploader={"username": "someone", "group": "User"})})
        elif url.path.startswith("/full/") or url.path.startswith("/thumb/"):
            with open(os.path.join(root, "source.png"), "rb") as f: self.send(f.read(), "image/png")
        elif url.path.endswith("/collections/someone"):
            self.send({"data": [{"id": 7, "label": "Skies", "views": 1, "public": 1, "count": 4}]})
        elif url.path.endswith("/w/missing"):
            self.send({"error": "nope"}, code=404)
        else:
            self.send({"error": "unknown"}, code=404)
server = HTTPServer(("127.0.0.1", 0), Handler)
with open(os.path.join(root, "port"), "w") as f: f.write(str(server.server_port))
server.serve_forever()
