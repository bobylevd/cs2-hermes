# CS2 Mod Version Mismatch Fix

## Symptom
`rcon-cli "meta list"` → `Unknown command 'meta'!` or a `<ERROR>` for CSS.
`metamod-fatal.log` (`addons/metamod/bin/linuxsteamrt64/`) shows:
`undefined symbol: g_bUpdateStringTokenDatabase`.

## Cause
A CS2 update changed the engine ABI; the baked Metamod/CounterStrikeSharp binaries
are too old. Fix = update both, persist to `custom_files`, restart.

## 1. Metamod
Latest Linux tarball from the MMS drop, then copy CS2/Linux64 binaries to live +
`custom_files`:
```bash
curl -s https://mms.alliedmods.net/mmsdrop/2.0/ | grep -o 'mmsource-2.0.0-git[0-9]*-linux.tar.gz' | sort -u | tail -1
cd /tmp && rm -rf mm && mkdir mm && cd mm
curl -sLo mm.tgz https://mms.alliedmods.net/mmsdrop/2.0/<TARBALL>   # from above
tar -xzf mm.tgz
L=addons/metamod/bin/linuxsteamrt64
for d in /home/steam/cs2/game/csgo /home/custom_files; do
  mkdir -p "$d/$L" "$d/addons/metamod/bin/linux64"
  cp $L/metamod.2.cs2.so $L/libserver.so "$d/$L/"
  cp addons/metamod/bin/linux64/server.so "$d/addons/metamod/bin/linux64/"
done
```

## 2. CounterStrikeSharp
Latest Linux runtime from the GitHub API, copy the `.so` to live + `custom_files`:
```bash
curl -sL https://api.github.com/repos/roflmuffin/CounterStrikeSharp/releases/latest \
  | python3 -c "import json,sys;d=json.load(sys.stdin);print(d['tag_name']);[print(a['browser_download_url']) for a in d['assets'] if 'linux' in a['name']]"
cd /tmp && rm -rf css && mkdir css && cd css
curl -sLo css.zip <LINUX_RUNTIME_ZIP_URL>   # from above
python3 -m zipfile -e css.zip x
B=addons/counterstrikesharp/bin/linuxsteamrt64
for d in /home/steam/cs2/game/csgo /home/custom_files; do
  mkdir -p "$d/$B"; cp x/$B/counterstrikesharp.so "$d/$B/"
done
```

## 3. Restart + verify
```bash
for p in /proc/[0-9]*; do grep -qs linuxsteamrt64/cs2 "$p/cmdline" && kill -9 "$(basename "$p")"; done
# wait 30-60s
rcon-cli status; rcon-cli "meta list"; rcon-cli "css_plugins list"
```
`meta list` should show Metamod + CounterStrikeSharp loaded.

## Sources
- Metamod: https://mms.alliedmods.net/mmsdrop/2.0/
- CounterStrikeSharp: https://github.com/roflmuffin/CounterStrikeSharp/releases
