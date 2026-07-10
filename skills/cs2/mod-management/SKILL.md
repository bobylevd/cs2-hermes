---
name: cs2-mod-management
description: Enable/disable/install CounterStrikeSharp plugins
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, plugins, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Mod / Plugin Management

Enable, disable, install, and configure CounterStrikeSharp (CSS) plugins.

## Layout
- Enabled (auto-loaded on boot): `/home/steam/cs2/game/csgo/addons/counterstrikesharp/plugins/`
- Available but off: `.../plugins/disabled/`
- Per-plugin config: `.../counterstrikesharp/configs/plugins/<Plugin>/`

**This mod's pattern:** most plugins sit in `disabled/`, and gamemode cfgs pull in
what they need at runtime with `css_plugins load "plugins/disabled/<X>/<X>.dll"`.
Base always-on plugins (GameModeManager, CS2Rcon, SimpleAdmin, …) live in
`plugins/`.

## When to Use
"enable/disable <plugin>", "install <plugin>", "why isn't <plugin> loading",
"turn on <feature>", editing a plugin's config.

## Procedure

**Check what's loaded (live):**
```bash
rcon-cli "css_plugins list"
```

**Enable a plugin permanently** (auto-load every boot) = move it into `plugins/`:
```bash
SRC=/home/steam/cs2/game/csgo/addons/counterstrikesharp/plugins
mv "$SRC/disabled/<Plugin>" "$SRC/<Plugin>"
```
**Load it right now without a restart:**
```bash
rcon-cli "css_plugins load \"<Plugin>/<Plugin>.dll\""   # or the disabled/ path
```

**Disable a plugin:** `css_plugins unload "<Plugin>"` (live) and move it back into
`disabled/` (permanent).

**Install a new plugin:** unzip its `<Plugin>/` folder into `plugins/` (or
`disabled/`), drop any config under `configs/plugins/<Plugin>/`, then
`css_plugins load`. Check the log for load errors (see `cs2-troubleshooting`).

## PERSIST IT (required)
Anything under `game/csgo/` is wiped on restart and replaced by the baked copy +
`custom_files`. So mirror every change into `custom_files`:
```bash
# e.g. persist an enabled plugin and its config
DST=/home/custom_files/addons/counterstrikesharp
mkdir -p "$DST/plugins" "$DST/configs/plugins"
cp -r "$SRC/<Plugin>"                "$DST/plugins/<Plugin>"
cp -r ".../configs/plugins/<Plugin>" "$DST/configs/plugins/<Plugin>"
```
For a plugin you *disabled*, remove it from the live `plugins/` AND ensure it is
not present under `custom_files/.../plugins/` (else it comes back on restart).

## Pitfalls
- Editing a plugin config live takes effect on plugin reload
  (`css_plugins reload "<Plugin>"`) or restart — but is lost on restart unless
  mirrored to `custom_files`.
- Load order / dependencies: some plugins depend on APIs (e.g. WASDMenuAPI).
  A missing dependency shows in the CSS log at load.
- Not every plugin is safe to load in every gamemode (the mode cfgs deliberately
  load/unload sets). Don't force-load a mode plugin outside its mode.

## Verification
`rcon-cli "css_plugins list"` shows the plugin in the expected state; the CSS log
shows a clean load (no exception); and the `custom_files` mirror exists.
