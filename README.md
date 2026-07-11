# cs2-hermes

A **Counter-Strike 2 modded server with a resident AI admin**. Two containers:

- **`cs2`** — the [`kus/cs2-modded-server`](https://github.com/kus/cs2-modded-server)
  image, unmodified.
- **`hermes`** — the official [Hermes Agent](https://hermes-agent.nousresearch.com)
  image + `rcon-cli`, pre-configured to run and administer the server. You talk to it
  over chat:

> "enable retakes" · "change map to mirage" · "add 7656119… as a moderator"
> "MatchZy won't load, check the logs" · "who's online?" · "restart the server"

Hermes doesn't just relay RCON — it **administers the server**: edits configs,
enables/disables plugins, manages admins, reads logs, fixes issues, and persists
changes correctly. It manages the `cs2` container over RCON + shared volumes.

## Architecture

```
┌───────────── cs2 ─────────────┐        ┌──────────── hermes ────────────┐
│ ghcr.io/kus/cs2-modded-server │        │ nousresearch/hermes-agent       │
│ (official, unmodified)        │        │  + rcon-cli                     │
│ restart: unless-stopped       │◄──RCON─┤ rcon-cli → cs2:27015            │
│ /home/steam (cs2-volume)      │◄─files─┤ shared volumes: edits files     │
└───────────────────────────────┘        │ gateway → Telegram/Discord      │
        ▲ shared cs2-volume + ./cs2 ──────┘ /opt/data (./hermes)            │
        └─────────────────────────────────┴─────────────────────────────────┘
```

- **RCON**: `rcon-cli` reaches `cs2:27015` over the Docker network.
- **Files**: the CS2 install (`cs2-volume`) and `custom_files` (`./cs2`) are shared
  into `hermes`, so it edits server files directly at `/home/steam/cs2`.
- **Restart**: `rcon-cli quit` → the `cs2` container exits and Docker restarts it
  (re-runs steamcmd, re-merges `custom_files`). No Docker socket needed.

## Deploy

```bash
git clone git@github.com:bobylevd/cs2-hermes.git
cd cs2-hermes
cp .env.example .env      # RCON_PASSWORD, LLM backend, gateway token, allowlist
docker compose up -d --build
docker logs -f hermes     # gateway   ·   docker logs -f cs2   for the server
```

First run pulls both images and downloads CS2 (tens of GB) — be patient. Once the
gateway is up, DM your bot: **"who's online?"** then **"change map to mirage"**.

## Configure (`.env`, shared by both containers)

| Variable | What |
|----------|------|
| `RCON_PASSWORD` | **Required.** Server admin password. Use a strong value. |
| `RCON_HOST` | `cs2` (the service name) — leave as-is. |
| `HERMES_PROVIDER`/`HERMES_BASE_URL`/`HERMES_MODEL`/`HERMES_API_KEY` | LLM backend. Default is **Kimi for Coding** (`api.kimi.com/coding/v1`, model `kimi-for-coding`). Examples in `.env.example`. |
| `GATEWAY_PLATFORM` + `TELEGRAM_BOT_TOKEN` | Chat platform + bot token. |
| `TELEGRAM_ALLOWED_USERS` | **Your** numeric Telegram id(s) — the gateway denies everyone else. Get it from @userinfobot. |
| `STEAM_ACCOUNT` | GSLT — public/online play only (empty + `LAN=1` for LAN). |
| `API_KEY` | Steam Web API key — only for Workshop map downloads. |

## Repo layout — two folders, two mounts

| Folder | Mounts to | Holds |
|--------|-----------|-------|
| `hermes/` | `/opt/data` (HERMES_HOME) | `SOUL.md`, `USER.md`, `AGENTS.md`, `config.yaml`, `skills/cs2/` — git-tracked. Hermes' runtime (`memories`, `sessions`, `state.db`, bundled skills) lives alongside, gitignored. |
| `cs2/` | `/home/custom_files` | The server-override `custom_files` (durable persistence). |

Everything Hermes *is* — persona, project knowledge, skills — are **git-tracked
files read live from the `hermes/` mount**. So **config/identity/skill changes ship
via `git pull` + `docker restart hermes` — no rebuild.** The skills are writable, so
Hermes refines them and you commit the improvements (`git add hermes && git commit`).
Only a Dockerfile change (e.g. `rcon-cli` version) needs `docker compose up -d --build`.

The one custom thing in the whole stack is the Dockerfile: `FROM
nousresearch/hermes-agent` + download `rcon-cli`. The image already bundles the
messaging (Telegram) and Anthropic extras, a shell, and s6 supervision.

## Persistence (the one server-side rule)

The mod rebuilds live `csgo/` from baked mods on every restart, then merges
`custom_files/` on top. So the **durable** copy of any server-file change lives in
`cs2/` (→ `/home/custom_files`); a live edit alone is wiped on restart. AGENTS.md and
the skills drill this into Hermes.

## Skills

Hermes **authors its own** `cs2/*` skills from experience (they land in
`hermes/skills/cs2/`, git-trackable, committable). `cs2-modded-server-ops` seeds
host-specific conventions and hard-won gotchas (Metamod ABI fixes, retakes spawn
configs, etc.) — extend it or let Hermes grow new ones.

## Security

- **RCON is exposed on 27015/tcp** (shared game port), protected by `RCON_PASSWORD` —
  use a strong value and firewall it on public servers.
- **No secrets in the image or git** — keys/tokens live in `.env` (gitignored).
- Hermes acts with a real shell, `approvals: smart` (auto-approves low-risk work,
  prompts on genuinely dangerous commands; a hardline blocklist for `rm -rf /` etc.
  always applies). The **`TELEGRAM_ALLOWED_USERS`** allowlist gates who can command it.

## Customizing

- Teach it about *your* server: edit `hermes/AGENTS.md`.
- Adjust persona / autonomy: `hermes/SOUL.md`, `hermes/config.yaml`.
- Then: `git commit` → on the server `git pull && docker restart hermes`.
