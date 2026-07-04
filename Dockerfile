# syntax=docker/dockerfile:1

FROM ghcr.io/getpaseo/paseo:latest

USER root

ARG CODEX_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest
ARG OPENCODE_VERSION=latest

ENV AUTO_UPDATE_AGENT_CLIS=true \
    AUTO_UPDATE_AGENT_CLIS_BACKGROUND=true \
    AGENT_CLI_UPDATE_INTERVAL_HOURS=72 \
    AGENT_CLI_UPDATE_CHECK_INTERVAL_SECONDS=3600 \
    AGENT_CLI_IDLE_PROCESS_NAMES="codex claude opencode" \
    AGENT_CLI_CODEX_VERSION=latest \
    AGENT_CLI_CLAUDE_CODE_VERSION=latest \
    AGENT_CLI_OPENCODE_VERSION=latest

RUN npm install -g \
      "@openai/codex@${CODEX_VERSION}" \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "opencode-ai@${OPENCODE_VERSION}" \
    && npm cache clean --force

RUN mv /usr/local/bin/paseo-docker-entrypoint /usr/local/bin/paseo-docker-entrypoint.base

COPY scripts/paseo-docker-entrypoint /usr/local/bin/paseo-docker-entrypoint

RUN chmod +x /usr/local/bin/paseo-docker-entrypoint
