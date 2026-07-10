---
name: cs2-admin-management
description: Manage server admins, groups, and permissions
version: 1.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [cs2, admins, counterstrikesharp]
    category: cs2
    requires_toolsets: [terminal]
---

# CS2 Admin Management

Files in `addons/counterstrikesharp/configs/`: `admins.json` (name → SteamID64 +
groups/flags), `admin_groups.json` (group → flags), `admin_overrides.json`.
`*.example.json` show the exact groups/flags this install ships.

```json
{ "Name": { "identity": "76561198XXXXXXXXX", "groups": ["#css/admin"],
            "flags": ["@css/generic"], "immunity": 50 } }
```

## Do
1. Get the 17-digit SteamID64 (starts `7656119…`); convert a vanity/SteamID2 or
   ask — don't guess.
2. Edit `admins.json`, back up + validate:
   `cp admins.json{,.bak} && python3 -m json.tool admins.json >/dev/null`
3. Apply: `rcon-cli "css_admins_reload"` (or restart if unavailable).
4. Persist: `cp admins.json admin_groups.json /home/custom_files/addons/counterstrikesharp/configs/`

## Notes
- Invalid JSON breaks the admin system — always validate before reload.
- SteamID64 ≠ SteamID2/3 → admin silently fails; verify the 17-digit form.
- Skip `custom_files` → admin vanishes on restart.

## Verify
JSON valid, reload clean, `custom_files` matches, admin confirms in-game.
