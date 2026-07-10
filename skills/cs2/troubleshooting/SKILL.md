---
name: cs2-troubleshooting
description: Diagnose mod/plugin crashes and server issues
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, debugging, logs, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Troubleshooting

Diagnose why a plugin/mod won't load, why the server crashed, or why something
isn't behaving.

## Where the signal is
- **CS2 server console** → container stdout: `docker logs`. Inside the container
  you see it in the process output; from the host: `docker logs -f <container>`.
- **CounterStrikeSharp logs**: `/home/steam/cs2/game/csgo/addons/counterstrikesharp/logs/`
  (per-day `log-YYYYMMDD.txt`) — plugin load errors, C# exceptions.
- **Metamod status** (live): `rcon-cli "meta list"`.
- **CSS plugin status** (live): `rcon-cli "css_plugins list"`.

## Procedure
1. Reproduce / locate the failure and read the newest CSS log:
   ```bash
   LOGS=/home/steam/cs2/game/csgo/addons/counterstrikesharp/logs
   ls -t "$LOGS" | head; tail -n 100 "$LOGS/$(ls -t "$LOGS" | head -1)"
   ```
2. For a plugin that won't load, check it's present, loaded, and dependency-satisfied:
   ```bash
   rcon-cli "css_plugins list"
   rcon-cli "meta list"          # is Metamod itself loaded / is CSS loaded under it?
   ```
3. Confirm the Metamod patch in `gameinfo.gi` is intact (the installer adds a
   `Game csgo/addons/metamod` line; if missing, Metamod/CSS won't load at all):
   ```bash
   grep -n "csgo/addons/metamod" /home/steam/cs2/game/csgo/gameinfo.gi
   ```
4. Correlate to a recent change (a plugin you enabled, a config edit, a CS2
   update). Revert the suspect change (restore from `.bak` or `custom_files`) and
   retest.

## Common causes
- **Metamod line missing from `gameinfo.gi`** → nothing modded loads. The
  entrypoint re-patches on boot; a restart usually restores it.
- **Bad JSON** in a plugin/admin config → that plugin errors on load. Validate
  with `python3 -m json.tool`.
- **Missing dependency** (e.g. an API plugin) → exception in the CSS log naming
  the missing type/assembly.
- **Wrong gamemode** → a plugin only loaded by a specific mode cfg won't be there
  in another mode. That's expected, not a bug.
- **Server not up yet** → `rcon-cli` connection refused during the (slow) first
  boot download. Wait and recheck `docker logs`.

## Verification
After a fix: the CSS log shows a clean load with no exception, `css_plugins list`
/ `meta list` show the expected state, and the behavior works in-game. State the
root cause and whether the fix was persisted to `custom_files`.
