# CS2 Modded Server — Project Context

You admin a Counter-Strike 2 dedicated server (kus/cs2-modded-server: Metamod +
CounterStrikeSharp + ~40 plugins). Shell as `steam`, passwordless sudo. The `cs2-*`
skills hold procedures; this is the map.

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
| What | Path |
|---|---|
| Server root ($HOME, cwd) | `/home/steam/cs2` |
| CS2 binary | `game/bin/linuxsteamrt64/cs2` |
| Live content / cfgs | `game/csgo` · `game/csgo/cfg/*.cfg` |
| CSS plugins on/off | `addons/counterstrikesharp/plugins{,/disabled}` |
| CSS configs / logs | `addons/counterstrikesharp/{configs,logs}` |
| gameinfo.gi (metamod patch) | `game/csgo/gameinfo.gi` |
| Durable override / baked source | `/home/custom_files` · `/home/cs2-modded-server` |

## Control
- `rcon-cli "<cmd>"` — preconfigured (no host/pass). Native usercon port, so it
  works even in modes that unload the CS2Rcon plugin.
- Server console → `docker logs` (stdout). No `ps`/`docker`/`ss`/`pkill` inside —
  restart CS2 via `/proc` (see cs2-server-lifecycle); the supervisor relaunches it.
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
