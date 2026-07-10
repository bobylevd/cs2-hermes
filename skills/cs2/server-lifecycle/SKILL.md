---
name: cs2-server-lifecycle
description: Restart, update, back up the server; persist changes
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, lifecycle, updates, backup]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Server Lifecycle

Restart, update, and back up the server — and understand what each does to your
changes.

## Mental model
The container entrypoint **supervises** the CS2 process: if it exits, the
entrypoint **relaunches** it. Relaunch re-runs the install/boot sequence, which:
1. copies baked mods over the live `csgo/`, then
2. merges `custom_files/` on top, then
3. re-patches `gameinfo.gi` for Metamod, then starts CS2.

So a **restart re-applies `custom_files`** and **discards un-mirrored live edits**.
Killing/quitting CS2 does NOT kill the container (Hermes stays up).

## Restart the server
Least disruptive first — check who's on:
```bash
rcon-cli status
```
If safe (or confirmed), trigger a restart by ending the CS2 process; the
supervisor brings it back:
```bash
rcon-cli quit          # graceful; server exits, supervisor relaunches it
# fallback if RCON is unresponsive:
# sudo pkill -f 'bin/linuxsteamrt64/cs2'
```
Watch it come back in `docker logs`; confirm with `rcon-cli status` once up
(first line of the map load can take ~30–60s).

## Update CS2 and/or mods
- **CS2 game update**: a normal restart re-runs `steamcmd +app_update 730`, so a
  restart picks up game updates. Announce/confirm if players are on.
- **Mod files update**: the baked mods come from the image
  (`/home/cs2-modded-server`). To take a new upstream mod release you rebuild the
  image (`./hermes/build.sh`) and recreate the container — that's an operator/host
  action, not something to do from inside. Explain that when asked to "update the
  mods".

## Back up before risky changes
```bash
TS=$(date +%Y%m%d-%H%M%S)
tar czf "/home/steam/backup-customfiles-$TS.tgz" -C /home custom_files
# and/or snapshot the configs you're about to touch:
cp admins.json "admins.json.$TS.bak"
```
`custom_files` is the durable source of truth — back that up, plus any live config
you edit.

## The persistence checklist (run it after every change)
1. Did the change take effect live? (reload command / `status` / log)
2. Is it mirrored into `/home/custom_files/<same path>`? If not, it dies on restart.
3. For removals: is it gone from BOTH the live tree AND `custom_files`?

## Verification
After a restart/update: `rcon-cli status` returns and shows the right map/mode;
`css_plugins list` and `meta list` look right; the CSS log is clean. Report what
changed and confirm persistence.
