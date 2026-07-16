#!/usr/bin/env python3

import re
import subprocess
import sys

rows = subprocess.check_output(
    ["ps", "-axo", "pid=,ppid=,stat=,command="],
    text=True,
    errors="replace",
).splitlines()

entries = {}


def detect_name(cmd: str):
    patterns = [
        r"/scripts/bridges/([^/\s]+)\.sh",
        r"/server/([^/\s]+)/",
        r"@modelcontextprotocol/server-([^/\s]+)",
        r"mcp-server-([^/\s]+)",
    ]
    for pattern in patterns:
        match = re.search(pattern, cmd)
        if match:
            return match.group(1)
    if "@playwright/mcp" in cmd:
        return "playwright"
    return None


def detect_port(cmd: str):
    match = re.search(r"--port(?:=|\s+)(\d+)", cmd)
    return match.group(1) if match else "-"


def detect_source(cmd: str, name: str):
    if re.search(rf"/scripts/bridges/{re.escape(name)}\.sh", cmd):
        return f"scripts/bridges/{name}.sh"
    if re.search(rf"/server/{re.escape(name)}/", cmd):
        return f"server/{name}"
    if f"server-{name}" in cmd or f"mcp-server-{name}" in cmd:
        return f"package:{name}"
    if "@playwright/mcp" in cmd:
        return "package:@playwright/mcp"
    return "-"

for line in rows:
    parts = line.strip().split(None, 3)
    if len(parts) < 4:
        continue
    pid, ppid, stat, cmd = parts
    name = detect_name(cmd)
    if not name:
        continue

    entry = entries.setdefault(
        name,
        {
            "ports": [],
            "gateway_pids": [],
            "server_pids": [],
            "sources": [],
        },
    )

    port = detect_port(cmd)
    if port != "-" and port not in entry["ports"]:
        entry["ports"].append(port)

    source = detect_source(cmd, name)
    if source != "-" and source not in entry["sources"]:
        entry["sources"].append(source)

    if "supergateway" in cmd or "/scripts/bridges/" in cmd:
        entry["gateway_pids"].append(pid)
    else:
        entry["server_pids"].append(pid)

if not entries:
    print("No MCP processes found.")
    sys.exit(1)

print(f"{'MCP':<22} {'PORT':<8} {'GATEWAY_PIDS':<18} {'SERVER_PIDS':<24} SOURCE")
for name in sorted(entries):
    entry = entries[name]
    ports = ",".join(entry["ports"]) if entry["ports"] else "-"
    gateway_pids = ",".join(entry["gateway_pids"]) if entry["gateway_pids"] else "-"
    server_pids = ",".join(entry["server_pids"]) if entry["server_pids"] else "-"
    source = ", ".join(entry["sources"]) if entry["sources"] else "-"
    print(f"{name:<22} {ports:<8} {gateway_pids:<18} {server_pids:<24} {source}")
