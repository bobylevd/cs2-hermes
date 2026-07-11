#!/usr/bin/env bash
# Entrypoint for the combined CS2-modded-server + Hermes admin image.
#
# Design: Hermes is the primary lifecycle process; the CS2 dedicated server is
# *supervised* — if it exits (e.g. Hermes restarts it, or it crashes), it is
# relaunched. This lets the admin agent restart/update the game server without
# taking down the container, and each relaunch re-applies custom_files.
#
# Layout:
#   HOME (=cwd)   /home/steam/cs2         server root; AGENTS.md lives here
#   HERMES_HOME   /home/steam/cs2/.hermes SOUL.md, config.yaml, memory, skills
#   rcon config   /home/steam/cs2/.rcon-cli.yaml (host/port/password)

set -uo pipefail
log() { echo "[entrypoint] $*"; }

# ---- defaults the stock server script expects ----------------------------- #
export PORT="${PORT:-27015}"
export EXEC="${EXEC:-on_boot.cfg}"
export LAN="${LAN:-0}"
export SERVER_PASSWORD="${SERVER_PASSWORD:-}"
export RCON_PORT="${RCON_PORT:-27015}"

# CS2 binds RCON to the container's primary interface (eth0), NOT loopback, so
# 127.0.0.1 gets "connection refused". Detect this container's IPv4 and use it
# unless the operator set an explicit non-loopback RCON_HOST. rcon-cli reads the
# RCON_HOST env var (it overrides the config file), and the Hermes gateway +
# its rcon-cli subprocesses inherit this exported value.
_container_ip="$(hostname -i 2>/dev/null | tr ' ' '\n' | grep -m1 -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')"
case "${RCON_HOST:-}" in
  ""|127.0.0.1|localhost) RCON_HOST="${_container_ip:-127.0.0.1}" ;;
esac
export RCON_HOST
log "RCON target: ${RCON_HOST}:${RCON_PORT}"

if [ -z "${RCON_PASSWORD:-}" ]; then
  log "FATAL: RCON_PASSWORD is empty. It is the server admin password AND how the"
  log "       agent controls the running server. Set it in .env and restart."
  exit 1
fi
export RCON_PASSWORD

HERMES_HOME="${HERMES_HOME:-${HOME%/}/.hermes}"
export HERMES_HOME
SEED_DIR="/opt/hermes/seed"

# ---- seed Hermes home ($HERMES_HOME = ./hermes bind mount) ---------------- #
# Curated files (SOUL.md, USER.md, AGENTS.md, config.yaml, skills/cs2) come from
# the git-tracked ./hermes bind mount. Here we only seed the installer's runtime
# assets (bundled skills, node, uv) if absent — cp -rn never clobbers the git
# files — and regenerate .env from the container environment.
mkdir -p "$HERMES_HOME"
cp -rn "$SEED_DIR/hermes_home/." "$HERMES_HOME/" 2>/dev/null || true
{
  echo "# Auto-generated from the container environment on every boot."
  for v in RCON_HOST RCON_PORT RCON_PASSWORD \
           HERMES_MODEL HERMES_PROVIDER HERMES_API_KEY HERMES_BASE_URL \
           GATEWAY_PLATFORM TELEGRAM_BOT_TOKEN DISCORD_BOT_TOKEN \
           TELEGRAM_ALLOWED_USERS DISCORD_ALLOWED_USERS GATEWAY_ALLOW_ALL_USERS; do
    printf '%s=%s\n' "$v" "${!v:-}"
  done
} > "$HERMES_HOME/.env"
chmod 600 "$HERMES_HOME/.env"

# ---- AGENTS.md is loaded as project context from the server-root cwd. Symlink
# it to the copy in HERMES_HOME so it lives in the ./hermes folder (git, one source).
mkdir -p "$HOME"
ln -sf "$HERMES_HOME/AGENTS.md" "$HOME/AGENTS.md"

# ---- rcon-cli config so the agent runs `rcon-cli "<cmd>"` with no secrets --- #
cat > "$HOME/.rcon-cli.yaml" <<EOF
host: ${RCON_HOST}
port: ${RCON_PORT}
password: ${RCON_PASSWORD}
EOF
chmod 600 "$HOME/.rcon-cli.yaml"

# ---- process management --------------------------------------------------- #
FLAG=/tmp/hermes-shutdown
rm -f "$FLAG"
HERMES_PID=""
SUP_PID=""

shutdown() {
  log "Shutting down..."
  touch "$FLAG"
  [ -n "$HERMES_PID" ] && kill "$HERMES_PID" 2>/dev/null
  [ -n "$SUP_PID" ] && kill "$SUP_PID" 2>/dev/null
  sudo pkill -TERM -f 'bin/linuxsteamrt64/cs2' 2>/dev/null
  pkill -TERM -f 'install_docker.sh' 2>/dev/null
  wait 2>/dev/null
  exit 0
}
trap shutdown TERM INT

# CS2 supervisor: (re)launch the server until shutdown is requested.
supervise_cs2() {
  while [ ! -f "$FLAG" ]; do
    log "Launching CS2 dedicated server..."
    setsid sudo -E bash /home/cs2-modded-server/install_docker.sh &
    local cs2_pid=$!
    wait "$cs2_pid"
    local code=$?
    [ -f "$FLAG" ] && break
    log "CS2 server exited (code ${code}). Relaunching in 3s..."
    sleep 3
  done
}

# Foreground gateway command differs across Hermes versions: newer builds use
# `hermes gateway run`, older `hermes gateway`. Detect which this build has.
GW="gateway"
if hermes gateway --help 2>&1 | grep -qw run; then GW="gateway run"; fi
log "Starting Hermes gateway ($GW; platform: ${GATEWAY_PLATFORM:-telegram})..."
cd "$HOME"
hermes $GW &
HERMES_PID=$!

supervise_cs2 &
SUP_PID=$!

# Whichever primary exits first, tear the rest down. Normally that's Hermes
# (the CS2 supervisor only exits on shutdown).
wait -n "$HERMES_PID" "$SUP_PID"
log "A primary process exited; cleaning up."
shutdown
