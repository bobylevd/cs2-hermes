---
name: cs2-troubleshooting
description: Diagnose mod/plugin crashes and server issues
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, debugging, logs, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Troubleshooting

## Signal
- Server console → `docker logs` (host). CSS logs → `addons/counterstrikesharp/logs/log-*.txt`.
- Live: `rcon-cli "meta list"` (Metamod/CSS loaded?), `rcon-cli "css_plugins list"`.
- Metamod fatal: `addons/metamod/bin/linuxsteamrt64/metamod-fatal.log`.

## Whole stack dead ("Unknown command 'meta'/'css_plugins'")
1. `grep -n csgo/addons/metamod game/csgo/gameinfo.gi` — patch present? (restart re-adds it).
2. `ls addons/metamod.vdf addons/metamod_x64.vdf` — if missing, restore from
   `/home/cs2-modded-server/game/csgo/addons/` + copy to `custom_files`.
3. `metamod-fatal.log` shows `undefined symbol: g_bUpdateStringTokenDatabase` →
   baked binaries older than the CS2 build. Update Metamod + CounterStrikeSharp,
   persist to `custom_files` — see cs2-modded-server-ops → `references/cs2-mod-version-mismatch.md`.

## Single plugin won't load
`css_plugins list` + newest CSS log. Usual: bad JSON (`python3 -m json.tool`),
missing dependency (named in the exception), or wrong-mode plugin (expected, not a bug).

## Method
Read newest log → correlate to a recent change → revert (from `.bak`/`custom_files`)
→ retest. Connection refused = server not up yet (slow first boot); wait, check `docker logs`.

## Verify
CSS log clean, `meta list`/`css_plugins list` right, works in-game. State root cause
and whether the fix was persisted.
