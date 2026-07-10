---
name: cs2-live-control
description: Live RCON ops - map, gamemode, status, kick, cvars
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, rcon, ops]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Live Control (RCON)

Control the **running** server without restarting it, via `rcon-cli` (already
configured — no host/password needed). This is the least-disruptive way to make
changes; prefer it over restarts.

## When to Use
"change map", "enable retakes / switch to <mode>", "who's online", "what map",
"kick <player>", "restart the round", "set <cvar>", "run <console command>".

## Procedure

**Always start with a status check for disruptive actions:**
```bash
rcon-cli status          # hostname, current map, connected players (name + userid)
```
If players are connected and the action is disruptive (map/mode change, kick),
confirm with the operator first (see SOUL.md). If empty, proceed.

**Change map** — official name, or a Steam Workshop numeric id:
```bash
rcon-cli "map de_mirage"
rcon-cli "host_workshop_map 3070284539"
```
Unsure it's installed? `rcon-cli "maps *"` lists installed maps.

**Switch gamemode** — this mod switches modes by exec'ing a cfg (it sets
game_type/game_mode, runs css_gamemode, loads that mode's plugins):
```bash
rcon-cli "exec retake.cfg"      # retakes
rcon-cli "exec dm.cfg"          # deathmatch
rcon-cli "exec gg.cfg"          # gungame
rcon-cli "exec comp.cfg"        # competitive
```
Discover the full list: `ls /home/steam/cs2/game/csgo/cfg/*.cfg`. Common modes:
`comp, dm, retake, executes, gg, aim, awp, 1v1, wingman, bhop, kz, surf, course,
hns, minigames, scoutzknivez, prefire, deathrun, br, battle, ctf, oitc, soccer,
casual, practice`.

**Kick / round / cvars:**
```bash
rcon-cli "kick \"PlayerName\""      # partial name or userid from `status`
rcon-cli "mp_restartgame 1"          # restart current round
rcon-cli "mp_maxrounds 24"           # set a cvar
```

**Any console command** you know: `rcon-cli "<command>"`.

## Pitfalls
- A mode change fully settles after a round/map change; if it "didn't take",
  offer `mp_restartgame 1` or a map change.
- These are **live-only**. Gamemode/cvar changes made this way do NOT persist a
  server restart. To make a mode the default, that's a cfg edit — see
  `cs2-mod-management` / `cs2-server-lifecycle` and the `custom_files` rule.
- If `rcon-cli` errors with connection refused, the CS2 process is starting or
  down — check `docker logs` / `cs2-troubleshooting`, don't assume it worked.

## Verification
Re-run `rcon-cli status` and confirm the map/mode/player list reflects the change.
Report the actual status back, not just "done".
