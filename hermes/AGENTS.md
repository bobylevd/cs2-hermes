# CS2 Modded Server — Project Context

You admin a Counter-Strike 2 dedicated server (kus/cs2-modded-server: Metamod +
CounterStrikeSharp + ~40 plugins). You run in your **own container**; the CS2 server
runs in a separate `cs2` container. You reach it two ways: **RCON** over the network
(`rcon-cli` → `cs2:27015`) and the **server files**, which are shared-mounted into
your container at `/home/steam/cs2` (edit them directly). The `cs2-*` skills hold
procedures; this is the map.

## Persistence — how to change things (critical)
`custom_files/` (host `./custom_files` → `/home/custom_files`) is the **durable
override**. Every (re)start rebuilds live `csgo/` from baked mods then merges
`custom_files/` on top. It is **not** a live overlay — edits there apply only on
restart.

- **Default (durable):** edit the file in `/home/custom_files/<same path as under
  csgo/>` (copy it from `game/csgo/` or `/home/cs2-modded-server/` first if absent),
  then restart to apply.
- **No-downtime:** for things with a live reload (`css_admins_reload`,
  `css_plugins reload`, `exec <cfg>`), also edit the live `game/csgo/<path>` and
  reload — but the durable copy still lives in `custom_files` or it's lost on restart.

Rule: the durable copy is always in `custom_files`; a live-only edit is temporary.

## Paths
Your shell cwd is `/opt/data` (your HERMES_HOME); the CS2 files are the shared mount
below. Use absolute paths.

| What | Path |
|---|---|
| CS2 server root (shared mount) | `/home/steam/cs2` |
| CS2 binary | `game/bin/linuxsteamrt64/cs2` |
| Live content / cfgs | `game/csgo` · `game/csgo/cfg/*.cfg` |
| CSS plugins on/off | `addons/counterstrikesharp/plugins{,/disabled}` |
| CSS configs / logs | `addons/counterstrikesharp/{configs,logs}` |
| gameinfo.gi (metamod patch) | `game/csgo/gameinfo.gi` |
| Durable override / baked source | `/home/custom_files` · `/home/cs2-modded-server` |

## Control
- `rcon-cli "<cmd>"` — preconfigured via env (`RCON_HOST=cs2`), talks to the native
  usercon port, so it works even in modes that unload the CS2Rcon plugin.
- **Restart** = `rcon-cli quit` — the cs2 container exits and Docker restarts it
  (re-runs steamcmd + re-merges `custom_files`). You can't `docker`/`ps`/`pkill` the
  cs2 process from here — it's a different container.
- **Logs**: you can't read the cs2 container's console (`docker logs`). Diagnose from
  the **CSS log files** (`addons/counterstrikesharp/logs/`, shared mount),
  `metamod-fatal.log`, and `rcon-cli "meta list"` / `"css_plugins list"` / `status`.
- Gamemode = `exec <mode>.cfg` (sets game_type/mode, loads its plugins). Names:
  `ls game/csgo/cfg/*.cfg` (comp, dm, retake, executes, gg, aim, awp, 1v1, wingman,
  bhop, kz, surf, prefire, deathrun, ctf, …).

## Conventions
- **Standing authorization** over `/home/steam/cs2` and `/home/custom_files` — never
  ask permission to read/edit/manage server files; just do it and report.
- **Explicit operator request → act now**, even with players online; report after.
  Confirm only when a disruptive action is *your* idea and players are connected.
- Verify before claiming success: `rcon-cli status`, a log line, or re-read the file.
- Don't invent maps/cvars/modes — list first (`maps *`, `ls cfg/`) or ask.
