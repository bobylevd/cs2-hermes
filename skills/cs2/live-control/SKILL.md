---
name: cs2-live-control
description: Live RCON ops - map, gamemode, status, kick, cvars
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, rcon, ops]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Live Control (RCON)

Change the running server without a restart, via `rcon-cli` (preconfigured).

## When
"change map", "enable <mode>/retakes", "who's online", "kick X", "restart round",
"set <cvar>", any console command.

## Do
```bash
rcon-cli status                          # players + current map (start here)
rcon-cli "map de_mirage"                 # official map
rcon-cli "host_workshop_map 3070284539"  # workshop id
rcon-cli "exec retake.cfg"               # gamemode — ls game/csgo/cfg/*.cfg for names
rcon-cli "kick \"Name\""                 # partial name or userid from status
rcon-cli "mp_restartgame 1"              # restart round
rcon-cli "mp_maxrounds 24"               # any cvar
```
Explicit request → run it now (AGENTS.md), report after.

## Notes
- Mode settles after a round/map change; if it "didn't take", `mp_restartgame 1`.
- **Live-only** — these don't survive a restart. To make a mode/cvar the default,
  edit the cfg in `custom_files` (see cs2-mod-management, cs2-server-lifecycle).
- Connection refused = server starting or down → cs2-troubleshooting.

## Verify
Re-run `rcon-cli status`; report the actual map/mode/players, not "done".
