# CS2 Modded Server + Hermes admin agent.
#
# Thin layer on top of the published base image, so this repo needs none of the
# upstream project's files. Built locally on the server via docker compose:
#     docker compose up -d --build
#
# Refresh the base image too with: docker compose build --pull

ARG BASE_IMAGE=ghcr.io/kus/cs2-modded-server:latest
FROM ${BASE_IMAGE}

USER root

# Tools for fetching Hermes + rcon-cli.
RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends curl ca-certificates ripgrep \
    && rm -rf /var/lib/apt/lists/*

# --- rcon-cli: single static binary for live server control ---------------- #
# (Debian has no rcon client; the game's CS2Rcon plugin is in-game only and is
# unloaded in comp/MatchZy modes. rcon-cli talks to the native usercon port and
# always works.)
ARG RCON_CLI_VERSION=1.7.6
RUN curl -fsSL "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_amd64.tar.gz" \
      -o /tmp/rcon-cli.tgz \
    && tar -xzf /tmp/rcon-cli.tgz -C /usr/local/bin rcon-cli \
    && rm /tmp/rcon-cli.tgz \
    && chmod +x /usr/local/bin/rcon-cli \
    && test -x /usr/local/bin/rcon-cli

# --- Hermes Agent ---------------------------------------------------------- #
# Root/FHS: code -> /usr/local/lib/hermes-agent, launcher -> /usr/local/bin/hermes
# (on PATH). Bundled data (default SOUL.md, built-in skills) seeded to
# /opt/hermes/seed/hermes_home; we overlay our identity + config next.
ENV HERMES_INSTALL_DIR=/usr/local/lib/hermes-agent
RUN mkdir -p /opt/hermes/seed/hermes_home \
    && HERMES_HOME=/opt/hermes/seed/hermes_home \
       bash -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive --skip-setup --skip-browser' \
    # The installer's launcher shim lands in root's ~/.local/bin, which the steam
    # user can't reach. Symlink the real venv entrypoint onto the global PATH and
    # make the code tree world-readable/executable.
    && HERMES_ENTRY="$(ls /usr/local/lib/hermes-agent/venv/bin/hermes 2>/dev/null \
         || find /usr/local/lib/hermes-agent -type f -name hermes 2>/dev/null | head -1)" \
    && test -n "$HERMES_ENTRY" \
    && ln -sf "$HERMES_ENTRY" /usr/local/bin/hermes \
    && chmod -R a+rX /usr/local/lib/hermes-agent \
    && test -x /usr/local/bin/hermes

# Extras the base install omits but the gateway needs:
#   - messaging: Telegram/Discord/Slack adapters (no adapter => can't connect)
#   - anthropic: Hermes builds an Anthropic client at agent init for auxiliary
#     features (title-gen/vision/fallback); its absence is fatal even when the
#     main model is an OpenAI-compatible provider.
# The uv-managed venv has no pip, so add them with the bundled uv.
RUN /opt/hermes/seed/hermes_home/bin/uv pip install --link-mode=copy \
      --python /usr/local/lib/hermes-agent/venv/bin/python \
      '/usr/local/lib/hermes-agent[messaging,anthropic]' \
    && /usr/local/lib/hermes-agent/venv/bin/python -c "import telegram, discord, anthropic"

# --- Our identity, project context, config, and admin skills --------------- #
COPY home/SOUL.md     /opt/hermes/seed/hermes_home/SOUL.md
COPY home/USER.md     /opt/hermes/seed/hermes_home/USER.md
COPY home/config.yaml /opt/hermes/seed/hermes_home/config.yaml
COPY home/AGENTS.md   /opt/hermes/seed/AGENTS.md
COPY skills           /opt/hermes/skills
COPY entrypoint.sh    /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh \
    && chown -R steam:steam /opt/hermes

# Runtime Hermes home (persisted via the cs2 volume, reseeded on boot).
ENV HERMES_HOME=/home/steam/cs2/.hermes

USER steam
WORKDIR /home/steam/cs2
CMD ["/usr/local/bin/entrypoint.sh"]
