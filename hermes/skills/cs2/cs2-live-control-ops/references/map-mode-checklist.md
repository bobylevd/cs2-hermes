# CS2 Map / Mode / Bot Checklist

Use this before and after a live change to avoid false "it didn't work" reports.

## Change map
- [ ] Official map: `rcon-cli "map de_<name>"` or `rcon-cli "map cs_<name>"`
- [ ] Workshop map: `rcon-cli "host_workshop_map <ID>"`
- [ ] Wait 10–15s, then `rcon-cli status` to confirm the new map.
- [ ] If mode changed unexpectedly, re-exec the desired mode cfg.

## Change mode
- [ ] `rcon-cli "exec <mode>.cfg"` — examples: `dm`, `aim`, `retake`, `gg`, `awp`, `1v1`
- [ ] Wait 5s; `rcon-cli "css_plugins list"` to confirm expected plugins loaded.
- [ ] Run `rcon-cli "mp_restartgame 1"` if the new settings didn't visibly take effect.

## Add bots live
- [ ] `rcon-cli "sv_cheats 1"` if needed (aim mode already sets it).
- [ ] `rcon-cli "bot_add"`
- [ ] `rcon-cli status` to confirm bot count.
- [ ] Warn user: bot count is live-only; next mode cfg exec will reset it.

## Verify
- [ ] `rcon-cli status` — map, player count, bot count, version/secure.
- [ ] `rcon-cli "css_plugins list"` — expected mode plugins loaded/unloaded.