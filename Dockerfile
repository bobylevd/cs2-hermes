# Hermes agent (official image) + rcon-cli. The only custom bit — everything else
# (messaging/telegram, anthropic, shell, s6 supervision) is baked into the image.
# Runs as a separate container from the CS2 server; manages it over RCON + shared
# volumes. See docker-compose.yml.
FROM nousresearch/hermes-agent:latest

USER root

# rcon-cli: single static binary for live control of the cs2 container.
ARG RCON_CLI_VERSION=1.7.6
RUN (command -v curl >/dev/null 2>&1 || (apt-get update \
        && apt-get install -y --no-install-recommends curl ca-certificates \
        && rm -rf /var/lib/apt/lists/*)) \
    && curl -fsSL "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_amd64.tar.gz" \
        -o /tmp/rcon-cli.tgz \
    && tar -xzf /tmp/rcon-cli.tgz -C /usr/local/bin rcon-cli \
    && rm /tmp/rcon-cli.tgz \
    && chmod +x /usr/local/bin/rcon-cli \
    && test -x /usr/local/bin/rcon-cli
