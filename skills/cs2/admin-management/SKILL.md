---
name: cs2-admin-management
description: Manage server admins, groups, and permissions
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, admins, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Admin Management

Add/remove admins and manage permissions (CounterStrikeSharp admin system,
used by SimpleAdmin and other plugins).

## Files (`.../counterstrikesharp/configs/`)
- `admins.json` — the admins: name → identity (SteamID64) + groups/flags.
- `admin_groups.json` — group definitions → permission flags.
- `admin_overrides.json` — per-command permission overrides.
- `*.example.json` — reference copies of each format.

## admins.json format
```json
{
  "Display Name": {
    "identity": "76561198XXXXXXXXX",   // SteamID64 (17 digits)
    "groups": ["#css/admin"],           // or #css/moderator, etc.
    "flags": ["@css/generic"],          // optional direct flags
    "immunity": 50                       // optional
  }
}
```
Groups (`#css/...`) are defined in `admin_groups.json`; flags (`@css/...`) grant
specific permissions. Read the `.example.json` files to see the exact groups and
flags this install ships with before inventing names.

## When to Use
"add <person> as admin/mod", "remove <person>", "give <person> <permission>",
"list admins", "reload admins".

## Procedure
1. Get the person's **SteamID64** (17-digit, starts `7656119…`). If given a
   vanity URL or SteamID2, convert it; if you can't, ask the operator for the
   SteamID64 rather than guessing.
2. Edit the **live** file:
   ```bash
   cd /home/steam/cs2/game/csgo/addons/counterstrikesharp/configs
   # add/modify the entry in admins.json (keep valid JSON — verify!)
   python3 -m json.tool admins.json >/dev/null && echo "JSON ok"
   ```
3. Apply without a full restart:
   ```bash
   rcon-cli "css_admins_reload"
   ```
   (If your build doesn't have that command, a server restart reloads admins —
   confirm which via `css` command list / logs.)
4. **PERSIST** — mirror to `custom_files` so it survives restarts/updates:
   ```bash
   mkdir -p /home/custom_files/addons/counterstrikesharp/configs
   cp admins.json admin_groups.json \
      /home/custom_files/addons/counterstrikesharp/configs/
   ```

## Pitfalls
- **Invalid JSON breaks the admin system.** Always validate with
  `python3 -m json.tool` before reloading. Keep a backup: `cp admins.json{,.bak}`.
- SteamID64 vs SteamID2/SteamID3 mismatch = admin silently won't work. Verify the
  17-digit form.
- If you edit only the live file and skip `custom_files`, the admin vanishes on
  the next restart. Always do both.

## Verification
`python3 -m json.tool admins.json` passes; `css_admins_reload` runs clean; the
`custom_files` copy matches; ideally the admin confirms their commands work
in-game.
