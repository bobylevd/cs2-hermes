---
name: cs2-live-control-ops
description: Live RCON ops for this specific CS2 modded-server host — map, mode, bots, cvars
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, rcon, ops, live-control]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Live Control (RCON) — Host-specific

Change the running server without a restart, via `rcon-cli` (preconfigured, no host/pass needed).

## When
"change map", "enable <mode>/retakes", "who's online", "kick X", "restart round",
"set <cvar>", "add bot", any console command.

## Do
```bash
rcon-cli status                          # players + current map (start here)
rcon-cli "maps de_*"                     # list official maps; wildcard search works
rcon-cli "map de_mirage"                 # official map
rcon-cli "host_workshop_map 3070284539"  # workshop id
rcon-cli "exec retake.cfg"               # gamemode — ls game/csgo/cfg/*.cfg for names
rcon-cli "kick "Name""                 # partial name or userid from status
rcon-cli "mp_restartgame 1"              # restart round
rcon-cli "mp_maxrounds 24"               # any cvar
```
Explicit request → run it now (AGENTS.md), report after.

## Adding/removing bots
`bot_add` / `bot_kick` / `bot_quota N` work live but are overwritten by the next mode cfg exec. If the user asked for a bot in the current session only, issue `rcon-cli "bot_add"` and verify. For a persistent bot count, edit `settings/no_bots.cfg` or the mode-specific `_settings.cfg` in `custom_files`.

## Notes
- Mode settles after a round/map change; if it "didn't take", `mp_restartgame 1`.
- **Live-only** — these don't survive a restart. To make a mode/cvar/bot count the default,
  edit the cfg in `custom_files` (see cs2-mod-management, cs2-server-lifecycle).
- Connection refused = server starting or down → cs2-troubleshooting.
- Workshop maps: `maps` wildcard doesn't show them; use `host_workshop_map <id>` or download first.

## Verify
Re-run `rcon-cli status`; report the actual map/mode/players, not "done".