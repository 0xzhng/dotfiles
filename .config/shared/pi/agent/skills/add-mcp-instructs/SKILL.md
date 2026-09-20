---
name: add-mcp-instructs
description: "Step-by-step global procedure for adding a new MCP server to this Mac. Use when the user asks to add/install/register an MCP, wire it into Pi/OpenCode, Open WebUI bridges, shell helpers, or asks how new MCPs should be formatted."
license: "private"
metadata:
  version: "1.0"
  type: workflow
---

# Add MCP Instructs

Use this skill whenever the user says to add a new MCP server.

Goal: wire the MCP through every relevant local layer, matching the existing formatting.

## Critical rules

- Canonical MCP root: `$HOME/mcp`.
- Local server implementations live under: `$HOME/mcp/server/`.
- Pi config: `$HOME/.pi/agent/mcp.json`.
- OpenCode configs:
  - `$HOME/.config/opencode/opencode.json`
  - `$HOME/.config/opencode/config.json`
- Open WebUI bridge manager: `$HOME/mcp/scripts/start-openwebui-bridges.sh`.
- Bridge wrappers: `$HOME/mcp/scripts/bridges/<name>.sh`.
- Shell config: `$HOME/.zshrc`.
- Main docs:
  - `$HOME/mcp/README.md`
  - `$HOME/mcp/mcp-info.md`
- Do **not** bind HTTP MCP bridges to LAN, `0.0.0.0`, `*`, or `[::]`.
- Open WebUI URLs must be `http://127.0.0.1:<port>/mcp`.
- Do **not** add login autostart unless user explicitly asks.

## Step-by-step procedure

### 1. Inspect current MCP docs and configs

Read first:

```text
$HOME/mcp/mcp-info.md
$HOME/mcp/README.md
$HOME/.pi/agent/mcp.json
$HOME/.config/opencode/opencode.json
$HOME/.config/opencode/config.json
$HOME/mcp/scripts/start-openwebui-bridges.sh
```

Look for existing names, command style, ports, and wrappers. Do not duplicate an existing MCP name.

### 2. Normalize the MCP name

Choose a short lowercase public name, usually kebab-case:

```text
reactbits
google-drive
youtube
obsidian
```

Use the same public name across Pi, OpenCode, bridge registry, wrapper, docs, and shell helpers unless there is a strong reason not to.

### 3. Install or locate server under `$HOME/mcp/server/`

Preferred location:

```text
$HOME/mcp/server/<name>/
```

If upstream repo already has a name like `reactbits-mcp-server`, keeping that folder is OK, but use the clean public name in configs.

Determine the stdio launch command. Common patterns:

```bash
node $HOME/mcp/server/<name>/dist/index.js
uv run --directory $HOME/mcp/server/<name> python server.py
npx -y <package>@latest
```

If it is TypeScript/Node and has a build step, run/build before registering:

```bash
npm install
npm run build
```

Confirm the target entry file exists.

### 4. Add Pi config

Edit:

```text
$HOME/.pi/agent/mcp.json
```

Add under `mcpServers` using existing format:

```json
"<name>": {
  "command": "node",
  "args": [
    "$HOME/mcp/server/<name>/dist/index.js"
  ],
  "lifecycle": "lazy"
}
```

Use `env`, `timeoutMs`, or `exposeResources` only when needed, matching nearby entries.

### 5. Add OpenCode configs

Edit both files when present:

```text
$HOME/.config/opencode/opencode.json
$HOME/.config/opencode/config.json
```

Add under `mcp` using existing format:

```json
"<name>": {
  "type": "local",
  "command": [
    "node",
    "$HOME/mcp/server/<name>/dist/index.js"
  ],
  "enabled": true
}
```

For `config.json`, preserve its existing enable/disable convention where obvious. If user explicitly asks to add the MCP, default to enabled.

### 6. Create Open WebUI bridge wrapper

Create:

```text
$HOME/mcp/scripts/bridges/<name>.sh
```

Example Node wrapper:

```bash
#!/bin/bash
# <Name> MCP stdio wrapper
exec node $HOME/mcp/server/<name>/dist/index.js
```

Example uv wrapper:

```bash
#!/bin/bash
# <Name> MCP stdio wrapper
exec uv run --directory $HOME/mcp/server/<name> python server.py
```

Then make executable:

```bash
chmod +x $HOME/mcp/scripts/bridges/<name>.sh
```

### 7. Add bridge registry entry

Edit:

```text
$HOME/mcp/scripts/start-openwebui-bridges.sh
```

Find `ENTRIES=(...)`. Add next free port after the highest current MCP bridge port:

```bash
"<name> <name> <port> $BRIDGE_DIR/<name>.sh"
```

Example:

```bash
"reactbits reactbits 8832 $BRIDGE_DIR/reactbits.sh"
```

This automatically makes these commands work:

```bash
mcp <name>
mcp-kill <name>
mcp list
```

### 8. Add zsh helpers only when asked

If user asks to add it “in zsh” or wants shell helpers, edit:

```text
$HOME/.zshrc
```

Add aliases near existing aliases:

```bash
alias mcp-<name>='mcp <name>'
alias mcp-kill-<name>='mcp-kill <name>'
```

Usually no alias is needed because `mcp <name>` is registry-driven.

### 9. Update docs

Update:

```text
$HOME/mcp/README.md
$HOME/mcp/mcp-info.md
```

Add:

- public name to available names list.
- server directory to directory list.
- Open WebUI endpoint table:

```text
http://127.0.0.1:<port>/mcp
```

If the documented port range changes, update all validation commands/ranges.

### 10. Add to Open WebUI

The bridge endpoint for the browser UI is:

```text
http://127.0.0.1:<port>/mcp
```

If browser automation is available, add the server in the Open WebUI MCP settings. If not, at minimum report the exact URL the user must add.

Never use LAN IPs or `localhost` when documenting the canonical URL. Use `127.0.0.1`.

### 11. Validate everything

Run JSON validation:

```bash
python3 -m json.tool $HOME/.pi/agent/mcp.json >/dev/null
python3 -m json.tool $HOME/.config/opencode/opencode.json >/dev/null
python3 -m json.tool $HOME/.config/opencode/config.json >/dev/null
```

Check bridge registry and status:

```bash
$HOME/mcp/scripts/start-openwebui-bridges.sh list
$HOME/mcp/scripts/start-openwebui-bridges.sh status <name>
```

Start and verify localhost-only:

```bash
$HOME/mcp/scripts/start-openwebui-bridges.sh start <name>
$HOME/mcp/scripts/start-openwebui-bridges.sh status <name>
lsof -nP -iTCP:<port> -sTCP:LISTEN
```

Expected bind:

```text
127.0.0.1:<port>
```

Bad binds, must fix immediately:

```text
*:<port>
0.0.0.0:<port>
[::]:<port>
```

### 12. Final response format

Be concise. Report:

- MCP name.
- Configs changed.
- Bridge URL.
- Whether bridge started and localhost-only verification passed.
- Any manual Open WebUI action still needed.

Example:

```text
Done.
- Added <name> to Pi and OpenCode.
- Added llama.cpp bridge: http://127.0.0.1:<port>/mcp
- Verified listener: 127.0.0.1:<port>

Files:
- $HOME/.pi/agent/mcp.json
- $HOME/.config/opencode/opencode.json
- $HOME/.config/opencode/config.json
- $HOME/mcp/scripts/bridges/<name>.sh
- $HOME/mcp/scripts/start-openwebui-bridges.sh
```

## Safety checklist

Before saying done:

- [ ] Server command points to real executable/file.
- [ ] Pi JSON valid.
- [ ] OpenCode JSON valid.
- [ ] Wrapper executable.
- [ ] Registry includes a unique free port.
- [ ] `mcp list` includes the name.
- [ ] Bridge starts.
- [ ] Listener is `127.0.0.1` only.
- [ ] Docs updated.
- [ ] No login autostart added unless requested.
