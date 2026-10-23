# Petit client pour le serveur MCP d'OMEdit (http://localhost:3000/mcp).
# Usage : python mcp_call.py <outil> '<arguments JSON>'
import json
import sys
import urllib.request

URL = "http://localhost:3000/mcp"
HDRS = {"Content-Type": "application/json", "mcp-protocol-version": "2025-11-25"}


def call(name, args):
    body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                       "params": {"name": name, "arguments": args}}).encode()
    req = urllib.request.Request(URL, data=body, headers=HDRS)
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)


if __name__ == "__main__":
    res = call(sys.argv[1], json.loads(sys.argv[2]))
    print(json.dumps(res, indent=1)[:8000])
