---
name: cs2-mod-management
description: Enable/disable/install CounterStrikeSharp plugins
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, plugins, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Plugin Management

Under `game/csgo/addons/counterstrikesharp/`: `plugins/` (auto-load),
`plugins/disabled/` (off), `configs/plugins/<P>/` (config). This mod keeps most
plugins in `disabled/` and mode cfgs pull them in via `css_plugins load`.

## Do
```bash
rcon-cli "css_plugins list"                    # what's loaded
mv plugins/disabled/<P> plugins/<P>            # enable permanently
rcon-cli "css_plugins load \"<P>/<P>.dll\""    # …load now (no restart)
rcon-cli "css_plugins unload \"<P>\""          # disable now; also mv back to disabled/
```
Install: unzip `<P>/` into `plugins/`, config into `configs/plugins/<P>/`, load.

## Persist (see AGENTS.md)
Durable copy goes in `custom_files` or it's wiped on restart:
```bash
DST=/home/custom_files/addons/counterstrikesharp
cp -r plugins/<P> "$DST/plugins/<P>"
cp -r configs/plugins/<P> "$DST/configs/plugins/<P>"   # if any
```
Disabling: remove from live `plugins/` AND from `custom_files`, else it returns.

## Notes
- Config edits apply on `css_plugins reload "<P>"` (durable copy still in custom_files).
- Missing deps (e.g. WASDMenuAPI) show in the CSS log at load.
- Mode cfgs load/unload specific sets — don't force a mode plugin outside its mode.

## Verify
`css_plugins list` shows expected state, CSS log clean, `custom_files` mirror exists.
