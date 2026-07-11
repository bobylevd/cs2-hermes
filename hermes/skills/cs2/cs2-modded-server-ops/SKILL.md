---
name: cs2-modded-server-ops
description: This host's operator conventions and CS2 mod-stack gotchas
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, modded-server, ops]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Ops — This Host

Host conventions + hard-won gotchas. Load alongside the other `cs2-*` skills.
(Authored by Hermes from experience; keep extending it.)

## Operator preference
Explicit request ("start retakes", "change map", "restart", "add me as admin") →
**do it now, even with players on**; report after. Confirm only when a disruptive
action is *your own* idea and players are connected.

## Gotchas
- **Retakes: lone player spawns at default T spawn.** Needs ≥2 humans to split
  T/CT; with one it falls back to normal spawns — not a bug. Also per-map spawn
  configs may be missing after a fresh install: copy
  `plugins/disabled/RetakesPlugin/map_config/*.json` →
  `configs/plugins/RetakesPlugin/map_config/`, mirror to `custom_files`, restart round.
- **Mod stack won't load** (`Unknown command 'meta'`): `.vdf`/binaries missing or
  ABI-mismatched. Check `metamod-fatal.log`; binary update in
  `references/cs2-mod-version-mismatch.md`.

## Restart
`rcon-cli quit` — the cs2 container exits and Docker restarts it (re-runs steamcmd,
re-merges `custom_files`). Wait 30–60s; verify `rcon-cli status`, `meta list`,
`css_plugins list`. (You can't kill the process directly — cs2 is a separate container.)

## Persist
Durable copy in `/home/custom_files/<same path>`; restart re-merges it (AGENTS.md).
