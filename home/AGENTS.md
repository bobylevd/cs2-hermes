# Project Context: CS2 Modded Server

This machine runs a **Counter-Strike 2 dedicated server** using the
[kus/cs2-modded-server](https://github.com/kus/cs2-modded-server) stack
(Metamod:Source + CounterStrikeSharp + ~40 plugins). You are its admin. You have
a shell here as the `steam` user, with **passwordless sudo**.

Your `cs2/*` skills contain the step-by-step playbooks. This file is the map.

## The one rule that will bite you: persistence

On **every server (re)start**, the launch script does this, in order:

1. `cp -R /home/cs2-modded-server/game/csgo/  →  /home/steam/cs2/game/csgo/`
   (baked mod files **overwrite** the live server files)
2. `cp -RT /home/custom_files/  →  /home/steam/cs2/game/csgo/`
   (your `custom_files` are merged **on top**)

**Therefore:** editing a file under `/home/steam/cs2/game/csgo/` gives an
*immediate* effect, but it is **wiped on the next restart** unless you also mirror
the change into `/home/custom_files/` at the same relative path.

The persistence workflow for any config/plugin change is:
1. Edit the **live** file (for immediate effect, usually + a reload command).
2. Copy the same change into **`/home/custom_files/<same relative path>`** (so it
   survives restarts and mod updates).
3. Verify.

## Key paths

| What | Path |
|------|------|
| Server root (`$HOME`, your cwd) | `/home/steam/cs2` |
| CS2 binary | `/home/steam/cs2/game/bin/linuxsteamrt64/cs2` |
| Live game content (`csgo`) | `/home/steam/cs2/game/csgo` |
| Config (cfg) files | `/home/steam/cs2/game/csgo/cfg` |
| Gamemode cfgs (exec these) | `.../cfg/<mode>.cfg` (e.g. `retake.cfg`, `dm.cfg`, `gg.cfg`, `comp.cfg`) |
| CounterStrikeSharp plugins (enabled) | `.../csgo/addons/counterstrikesharp/plugins/` |
| Plugins available but off | `.../counterstrikesharp/plugins/disabled/` |
| CSS configs (admins, core) | `.../counterstrikesharp/configs/` |
| CSS logs | `.../counterstrikesharp/logs/` |
| Metamod | `.../csgo/addons/metamod/` |
| `gameinfo.gi` (metamod-patched) | `/home/steam/cs2/game/csgo/gameinfo.gi` |
| Map groups / modes | `/home/steam/cs2/game/csgo/gamemodes_server.txt` |
| **Persistence mirror** | `/home/custom_files/` (mirrors `csgo/`) |
| Baked mod source | `/home/cs2-modded-server/` (installer copies from here) |

## How the server runs

- Started/kept-alive by the container entrypoint, which **auto-restarts** the CS2
  process if it exits. So killing/quitting CS2 = a restart, **not** a dead server.
- Launched with `-usercon` + `+rcon_password`, so RCON is available locally.
- The server's console output goes to the **container stdout** (`docker logs`),
  not a file. CSS plugin logs are under `.../counterstrikesharp/logs/`.

## Controlling the running server (RCON)

Use `rcon-cli` (preconfigured with host/port/password via `~/.rcon-cli.yaml` —
**no flags or password needed**). It sends one console command and prints the reply:

```bash
rcon-cli status                       # who's online, current map
rcon-cli "map de_mirage"              # change map (official)
rcon-cli "host_workshop_map 3070284539"   # change to a workshop map by id
rcon-cli "exec retake.cfg"            # switch gamemode (see cfg/*.cfg)
rcon-cli "css_plugins list"           # loaded CounterStrikeSharp plugins
rcon-cli "css_admins_reload"          # reload admins.json after editing it
rcon-cli "kick \"PlayerName\""        # kick
```

Gamemode switching in this mod = `exec <mode>.cfg` (it sets game_type/game_mode,
runs `css_gamemode`, and loads that mode's plugins). Modes available as cfgs:
`comp, dm, retake, executes, gg, aim, awp, 1v1, wingman, bhop, kz, surf, course,
hns, minigames, scoutzknivez, prefire, deathrun, br, battle, ctf, oitc, soccer,
casual, practice` (see `ls /home/steam/cs2/game/csgo/cfg/`).

## Safety conventions

- Before anything disruptive (map/mode change, plugin move, restart, update),
  run `rcon-cli status`. **If players are connected, confirm with the operator
  first.** If empty, proceed and report.
- Never leave a change un-persisted: if it should outlast a restart, it goes in
  `custom_files`. Say explicitly whether a change is persisted or live-only.
- When a command/plugin name is version-dependent and you're unsure, check
  (`css_plugins list`, `--help`, the logs) before asserting it worked.
- Prefer editing `custom_files` + reload over hand-patching live files you'll
  forget to mirror.
