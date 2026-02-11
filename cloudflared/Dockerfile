# ── Stage: final ──────────────────────────────────────────────────────
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Layer 1: System packages ─────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    jq \
    git \
    unzip \
    zip \
    build-essential \
    ca-certificates \
    openssh-client \
    gnupg \
    software-properties-common \
    ripgrep \
    tmux \
    vim \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
  && rm -rf /var/lib/apt/lists/*

# ── Layer 2: Node.js 22 LTS via NodeSource ───────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

# ── Layer 3: Build OpenClaw from source (matches official Dockerfile) ─
RUN corepack enable
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

ARG OPENCLAW_DOCKER_APT_PACKAGES=""
RUN if [ -n "$OPENCLAW_DOCKER_APT_PACKAGES" ]; then \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $OPENCLAW_DOCKER_APT_PACKAGES && \
      apt-get clean && \
      rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*; \
    fi

RUN git clone --depth 1 https://github.com/openclaw/openclaw.git /app
WORKDIR /app
RUN pnpm install --frozen-lockfile
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build \
  && rm -rf /app/.git /root/.cache /tmp/* \
  && pnpm store prune

# ── Layer 4: Claude Code (native installer) ──────────────────────────
RUN curl -fsSL https://claude.ai/install.sh | bash

# ── Layer 5: OpenCode CLI ────────────────────────────────────────────
RUN curl -fsSL https://opencode.ai/install | bash

# ── Layer 6: Install uv system-wide ─────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 bash \
  && cp /root/.local/bin/uv /usr/local/bin/uv \
  && cp /root/.local/bin/uvx /usr/local/bin/uvx \
  && chmod 755 /usr/local/bin/uv /usr/local/bin/uvx

# ── Layer 7: Security hardening ──────────────────────────────────────
# Ubuntu 24.04 ships with a 'ubuntu' user (uid 1000) — rename it to 'agent'
RUN usermod -l agent -d /home/agent -m ubuntu \
  && groupmod -n agent ubuntu

# Copy CLI tools installed under /root to a shared PATH location
RUN cp /root/.local/bin/claude /usr/local/bin/claude \
  && cp /root/.opencode/bin/opencode /usr/local/bin/opencode \
  && chmod 755 /usr/local/bin/claude /usr/local/bin/opencode

# Set ownership of OpenClaw app to agent
RUN chown -R agent:agent /app

ENV NODE_ENV=production

WORKDIR /home/agent/workspace

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chown=agent:agent openclaw.json /home/agent/.openclaw/openclaw.json

USER agent

# ── Layer 8: Kimi CLI (installed as agent user) ─────────────────────
ENV PATH="/home/agent/.local/bin:${PATH}"
RUN uv tool install --python 3.13 kimi-cli

ENTRYPOINT ["entrypoint.sh"]
CMD ["bash"]
