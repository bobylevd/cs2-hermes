---
name: cs2-server-lifecycle
description: Restart, update, back up the server; persist changes
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, lifecycle, updates, backup]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Server Lifecycle

## Model
The entrypoint supervises CS2: if it exits it relaunches (re-copy baked mods →
merge `custom_files/` → re-patch gameinfo.gi → start). So **restart = apply
`custom_files` + discard un-mirrored live edits**. Killing CS2 ≠ killing the container.

## Restart
`rcon-cli status` first (act on explicit requests regardless). Then end the process;
the supervisor revives it. No `ps`/`pkill` here — use `/proc`:
```bash
rcon-cli quit
# fallback:
for p in /proc/[0-9]*; do grep -qs linuxsteamrt64/cs2 "$p/cmdline" && kill -9 "$(basename "$p")"; done
```
Wait 30–60s; confirm `rcon-cli status`.

## Update
- CS2 game: a restart re-runs `steamcmd +app_update 730`.
- Mod files: baked into the image. New upstream release → rebuild the image on the
  host (`docker compose up -d --build`). A live binary fix (Metamod/CSS ABI break)
  → cs2-modded-server-ops → `references/cs2-mod-version-mismatch.md`.

## Backup
```bash
tar czf /home/steam/backup-cf-$(date +%F-%H%M).tgz -C /home custom_files
```

## Verify
`rcon-cli status` returns right map/mode; `meta list`/`css_plugins list` ok; log clean.
