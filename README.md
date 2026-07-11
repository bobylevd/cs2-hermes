# cs2-hermes

A **Counter-Strike 2 modded server with a resident AI admin** in one container.
It layers a pre-configured **[Hermes Agent](https://hermes-agent.nousresearch.com)**
on top of the published [`kus/cs2-modded-server`](https://github.com/kus/cs2-modded-server)
image, so you can run and manage the server by talking to it over chat:

> "enable retakes" · "change map to mirage" · "add 7656119… as a moderator"
> "MatchZy won't load, check the logs" · "who's online?" · "restart the server"

Hermes doesn't just relay RCON — it **administers the server**: edits configs,
enables/disables plugins, manages admins, reads logs, fixes issues, and persists
changes correctly. It uses its own shell for filesystem work and `rcon-cli` for
live, non-disruptive control.

## Deploy (build on the server)

Because it's `FROM ghcr.io/kus/cs2-modded-server:latest`, the machine pulls the
base image and builds only the thin Hermes layer. No registry account needed.

```bash
git clone git@github.com:bobylevd/cs2-hermes.git
cd cs2-hermes
cp .env.example .env      # fill in RCON_PASSWORD, LLM backend, gateway token
docker compose up -d --build
docker logs -f cs2-hermes
```

First run downloads the base image + CS2 (several GB) — be patient. Once the
Hermes gateway is up, message your bot: **"who's online?"** then **"enable retakes"**.

### Update later
```bash
git pull
docker compose up -d --build          # rebuild the layer + restart
docker compose build --pull && docker compose up -d   # also refresh the base image
```

Prefer a terminal instead of chat? `docker exec -it cs2-hermes hermes`.

## Configure (`.env`)

| Variable | What |
|----------|------|
| `RCON_PASSWORD` | **Required.** Server admin password; how the agent controls the live server. Use a strong value. |
| `HERMES_PROVIDER` / `HERMES_BASE_URL` / `HERMES_MODEL` / `HERMES_API_KEY` | LLM backend (Kimi/Moonshot, OpenAI Codex, or any OpenAI-compatible endpoint). Examples in `.env.example`. |
| `GATEWAY_PLATFORM` | `telegram` or `discord`. |
| `TELEGRAM_BOT_TOKEN` / `DISCORD_BOT_TOKEN` | Token for the platform you chose. |
| `STEAM_ACCOUNT` | GSLT — public/online play only (empty + `LAN=1` for LAN). |
| `API_KEY` | Steam Web API key — only for Workshop map downloads. |

## How it's built

The intelligence is **markdown, not code**. The only added binary is `rcon-cli`
(a standard tool); everything else is Hermes' built-in shell/file/process tools
plus these config surfaces:

| File | Role |
|------|------|
| `hermes/SOUL.md` | Persona — a careful, terse CS2 server admin |
| `hermes/AGENTS.md` | Project knowledge — paths, launch model, **the `custom_files` persistence rule**, safety |
| `hermes/USER.md` | Who the operator is |
| `hermes/config.yaml` | Model (env), terminal backend, approvals, gateway |
| `hermes/skills/cs2/*` | Playbooks: `live-control`, `mod-management`, `admin-management`, `troubleshooting`, `server-lifecycle`, `cs2-modded-server-ops` |

Two bind-mounted folders hold everything: **`hermes/`** *is* HERMES_HOME (the files
above are git-tracked; Hermes' runtime `memories`/`sessions`/`state.db`/self-authored
skills live alongside, gitignored), and **`cs2/`** is the server-override
`custom_files`. Because the curated files are read live from the mount, **config
and skill changes ship via `git pull` — no image rebuild.** The skills are also
writable, so Hermes refines them and you commit the improvements.

**Persistence, the one rule:** this mod overwrites live server files from a baked
copy on every restart, then merges `custom_files/` on top (bind-mounted to `./cs2`).
So the durable copy of any change lives in `cs2/` — a live edit alone is wiped on restart.

**Live control:** `rcon-cli` talks straight to the native usercon RCON port, so it
works even in modes where the in-game `CS2Rcon` plugin is unloaded (comp/MatchZy).
Source RCON is a binary protocol bash can't practically speak — hence the one binary.

**Restart/update:** the entrypoint *supervises* CS2 (auto-restarts if it exits),
so the agent can restart/update the server without killing the container, and each
relaunch re-applies `custom_files`.

## CI

`.github/workflows/build.yml` builds the image on push/PR as a **validation only**
(no registry push, no secrets) so breakage is caught before you `git pull` on the
server. Delete it if you don't want CI.

## Security notes

- **RCON is exposed on 27015/tcp** (shared game port), protected by
  `RCON_PASSWORD`. Use a strong value and firewall it on public servers; the agent
  connects locally, so restricting external RCON doesn't break it.
- **No secrets in the image or git** — keys/tokens live in `.env` (gitignored) and
  are written to `$HERMES_HOME/.env` and `~/.rcon-cli.yaml` (chmod 600) at runtime.
- Hermes acts with a real shell and sudo, and runs `approvals: smart` (auto-approves
  low-risk actions, prompts only on dangerous ones; a hardline blocklist for
  `rm -rf /` etc. always applies). Give the bot token only to trusted admins — the
  Telegram allowlist (`TELEGRAM_ALLOWED_USERS`) is what gates who can command it.

## Caveats

- The full image build hasn't been run end-to-end here (base pulls the SteamRT
  runtime; first boot downloads multi-GB CS2). The first `docker compose up --build`
  is the real test.
- Hermes' `gateway:`/`platforms:` config keys are version-dependent; tokens are
  also exported as env vars in the container as a fallback. See
  `docker exec -it cs2-hermes hermes --help`.

## Customizing

Config/identity/skills are git-tracked files in `hermes/`, read live from the
bind mount — so changes apply with **`git pull` + a restart, no rebuild**:

- Teach the agent about *your* server: edit `hermes/AGENTS.md`.
- Adjust persona / autonomy: `hermes/SOUL.md`, `hermes/config.yaml`.
- Add/adjust a playbook: `hermes/skills/cs2/<skill>/SKILL.md`.
- Commit Hermes' own refinements: on the server, `git add hermes && git commit`.
- Apply: on the server `git pull`, then `docker compose up -d` (recreate). Only a
  Dockerfile/dependency change needs `--build`.
