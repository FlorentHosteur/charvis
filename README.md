# RAG OpenClaw

Docker runtime for the **OpenClaw** agent bot -- a pre-configured container packed with Claude Code, OpenCode CLI, Kimi CLI, and a full suite of developer tooling. Ship it behind a Cloudflare Zero Trust Tunnel for secure remote access, or expose ports directly for local development.

**Docker Hub:** [`hosteurdkuser/rag-openclaw:v0.5.0`](https://hub.docker.com/r/hosteurdkuser/rag-openclaw)

---

## Table of Contents

- [What Is Included](#what-is-included)
- [Choose Your Deployment](#choose-your-deployment)
- [Quick Start](#quick-start)
  - [Cloudflared (Tunnel)](#cloudflared-tunnel)
  - [Direct Access](#direct-access)
- [Installed Tools](#installed-tools)
- [Project Structure](#project-structure)
- [Docker Hub](#docker-hub)
- [Security Considerations](#security-considerations)
- [Building from Source](#building-from-source)
- [License](#license)

---

## What Is Included

Both deployment variants use the same Docker image and ship with:

- **Claude Code** -- Anthropic's official CLI for Claude
- **OpenCode CLI** -- AI-powered coding assistant
- **OpenClaw** -- Personal AI assistant with a gateway web UI on port 18789
- **Kimi CLI** -- Moonshot AI coding agent
- **Node.js 22 LTS**, **Python 3**, **uv**, **Git**, **ripgrep**, **tmux**, **vim**, **build-essential**, **sqlite3**, **jq**, and more

The container runs as a non-root user `agent` (UID 1000).

---

## Choose Your Deployment

Two ready-made installation variants live in subdirectories. Pick the one that fits your environment.

| | Cloudflared (Tunnel) | Direct Access |
|---|---|---|
| **Directory** | `cloudflared/` | `direct/` |
| **Security** | Cloudflare Zero Trust + TLS | Firewall / VPN required |
| **Remote access** | Yes, via HTTPS tunnel | Manual port forwarding needed |
| **Setup complexity** | Moderate (Cloudflare account required) | Simple |
| **Best for** | Production, remote teams, public internet | Local development, trusted networks |

Both variants pull the same image from Docker Hub: `hosteurdkuser/rag-openclaw:v0.5.0`.

---

## Quick Start

### Cloudflared (Tunnel)

Recommended for production and remote access. Traffic is routed through a Cloudflare Zero Trust Tunnel with automatic TLS.

```bash
cd cloudflared
./setup.sh
```

See [`cloudflared/INSTALL.md`](cloudflared/INSTALL.md) for full instructions, including Cloudflare account setup, tunnel creation, and environment variable configuration.

### Direct Access

Simpler setup for local development or use on a trusted network. Container ports are exposed directly on the host.

```bash
cd direct
./setup.sh
```

See [`direct/INSTALL.md`](direct/INSTALL.md) for full instructions and environment variable configuration.

---

## Installed Tools

| Tool | Version | Description |
|---|---|---|
| Claude Code | 2.x | Anthropic CLI for Claude |
| OpenCode CLI | 1.x | AI coding assistant |
| OpenClaw | latest | Personal AI assistant with gateway UI |
| Kimi CLI | 1.x | Moonshot AI coding agent |
| Node.js | 22 LTS | JavaScript runtime |
| Python 3 | 3.12 | Python runtime |
| uv | latest | Fast Python package manager |
| Git | 2.x | Version control |
| ripgrep | 14.x | Fast recursive search |
| jq | 1.x | JSON processor |
| tmux | -- | Terminal multiplexer |
| vim | -- | Text editor |
| build-essential | -- | C/C++ compiler toolchain |
| sqlite3 | -- | SQLite database engine |

---

## Project Structure

```
Charvis/
  README.md                  # This file
  cloudflared/               # Cloudflare tunnel variant
    Dockerfile
    docker-compose.yml
    setup.sh
    INSTALL.md
    .env.example
    .dockerignore
    entrypoint.sh
    openclaw.json
    outside-scripts/
      sh-openclaw
  direct/                    # Direct access variant
    Dockerfile
    docker-compose.yml
    setup.sh
    INSTALL.md
    .env.example
    .dockerignore
    entrypoint.sh
    openclaw.json
    outside-scripts/
      sh-openclaw
```

Each variant is self-contained. You can `cd` into either directory and follow its own `INSTALL.md` without touching the other.

---

## Docker Hub

The pre-built image is published to Docker Hub:

```
hosteurdkuser/rag-openclaw:v0.5.0
```

Pull it explicitly:

```bash
docker pull hosteurdkuser/rag-openclaw:v0.5.0
```

Both `docker-compose.yml` files reference this image and will pull it automatically on first `docker compose up`.

---

## Security Considerations

- **Non-root execution.** The container runs as user `agent` (UID 1000), not root.
- **No secrets baked into the image.** All API keys and tokens are injected at runtime through `.env` files that are excluded from version control via `.dockerignore` and `.gitignore`.
- **Token authentication.** The OpenClaw gateway requires a `OPENCLAW_GATEWAY_TOKEN` for access. No anonymous connections are accepted.
- **Cloudflare TLS (tunnel variant).** External traffic is encrypted end-to-end via Cloudflare's edge. TLS termination happens at Cloudflare before the tunnel forwards traffic to the container.
- **Zero Trust policies (tunnel variant).** You can layer Cloudflare Access policies (email allowlist, SSO, one-time PIN) on top of the tunnel for an additional authentication gate.
- **Trusted proxies.** The gateway trusts only the Docker bridge network range (`172.16.0.0/12`) for `X-Forwarded-For` headers.
- **`.dockerignore` enforced.** Files such as `.env`, `.git`, and `node_modules` are excluded from the build context.

When using the **direct** variant, you are responsible for securing access through your own firewall rules, VPN, or network segmentation.

---

## Building from Source

If you want to rebuild the image locally instead of pulling from Docker Hub:

```bash
# From either variant directory
cd cloudflared   # or: cd direct

# Build for amd64
docker build --platform linux/amd64 -t hosteurdkuser/rag-openclaw:v0.5.0 .

# Or build via Docker Compose
docker compose build
```

To push a custom build to Docker Hub:

```bash
docker login
docker push hosteurdkuser/rag-openclaw:v0.5.0
docker tag hosteurdkuser/rag-openclaw:v0.5.0 hosteurdkuser/rag-openclaw:latest
docker push hosteurdkuser/rag-openclaw:latest
```

---

## License

This project is not yet published under a specific license. A license file will be added in a future release.
