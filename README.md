# RAG OpenClaw

A Docker-based runtime environment for the OpenClaw agent bot, pre-loaded with Claude Code, OpenCode CLI, Kimi CLI, and common developer tooling. Exposed securely via Cloudflare Zero Trust Tunnel.

**Docker Hub:** `hosteurdkuser/rag-openclaw`

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [OpenClaw Gateway Config](#openclaw-gateway-config)
- [Cloudflare Zero Trust Tunnel Setup](#cloudflare-zero-trust-tunnel-setup)
  - [1. Create a Tunnel](#1-create-a-tunnel)
  - [2. Get the Tunnel Token](#2-get-the-tunnel-token)
  - [3. Configure the Public Hostname](#3-configure-the-public-hostname)
  - [4. Start the Stack](#4-start-the-stack)
- [Usage](#usage)
  - [Start the Stack](#start-the-stack)
  - [Stop the Stack](#stop-the-stack)
  - [Access the OpenClaw Gateway UI](#access-the-openclaw-gateway-ui)
  - [Attach to the Container](#attach-to-the-container)
  - [Run CLI Tools](#run-cli-tools)
  - [Generate an SSH Key](#generate-an-ssh-key)
  - [Clone Repositories](#clone-repositories)
- [Host Helper Scripts](#host-helper-scripts)
- [Building from Source](#building-from-source)
- [Volumes](#volumes)
- [Installed Tools](#installed-tools)
- [Security](#security)
- [Architecture](#architecture)

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine + Docker Compose v2
- A [Cloudflare](https://www.cloudflare.com/) account (free tier works) with a domain configured
- An Anthropic API key (for Claude Code / OpenClaw)

---

## Quick Start

```bash
# 1. Clone this repository
git clone <your-repo-url> && cd Charvis

# 2. Create your .env file
cp .env.example .env
# Edit .env and fill in your keys (see Configuration below)

# 3. Start the stack
docker compose up -d

# 4. Check logs
docker compose logs -f
```

The OpenClaw gateway UI will be available at `http://localhost:18789`.

---

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

| Variable | Required | Description |
|---|---|---|
| `ANTHROPIC_API_KEY` | Yes | Anthropic API key for Claude Code and OpenClaw |
| `OPENAI_API_KEY` | No | OpenAI API key for OpenCode CLI |
| `GH_TOKEN` | No | GitHub personal access token for GitHub operations |
| `CLOUDFLARE_TUNNEL_TOKEN` | Yes | Cloudflare Tunnel token (see setup below) |
| `OPENCLAW_GATEWAY_TOKEN` | Yes | Token for authenticating with the OpenClaw gateway |
| `OPENCLAW_GATEWAY_PORT` | No | Gateway port (default: `18789`) |
| `OPENCLAW_BRIDGE_PORT` | No | Bridge port (default: `18790`) |
| `KIMI_API_KEY` | No | Moonshot AI API key for Kimi CLI |

### OpenClaw Gateway Config

The gateway configuration is baked into the image at `/home/agent/.openclaw/openclaw.json`:

```json
{
  "gateway": {
    "bind": "lan",
    "port": 18789,
    "trustedProxies": ["172.16.0.0/12"],
    "auth": {
      "mode": "token"
    },
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
```

Key settings:
- **`bind: "lan"`** -- Binds to `0.0.0.0` so the gateway is reachable from other containers (cloudflared) and the host
- **`trustedProxies`** -- Trusts the Docker bridge network range for `X-Forwarded-For` headers
- **`auth.mode: "token"`** -- Requires `OPENCLAW_GATEWAY_TOKEN` for access
- **`controlUi.allowInsecureAuth: true`** -- Allows token auth over HTTP (TLS is terminated at Cloudflare)

To override this config at runtime, bind-mount your own file:

```yaml
volumes:
  - ./my-openclaw.json:/home/agent/.openclaw/openclaw.json
```

---

## Cloudflare Zero Trust Tunnel Setup

The `cloudflared` container creates a secure tunnel from Cloudflare's edge to your OpenClaw gateway. This lets you access the UI from anywhere without exposing ports to the internet.

### 1. Create a Tunnel

1. Log in to the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/)
2. Go to **Networks** > **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** as the connector type
5. Give your tunnel a name (e.g., `openclaw-gateway`)
6. Click **Save tunnel**

### 2. Get the Tunnel Token

After creating the tunnel, Cloudflare shows you an install command like:

```
cloudflared service install eyJhIjoiNjQ1...
```

The long string after `install` is your **tunnel token**. Copy it and set it in your `.env` file:

```
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoiNjQ1...
```

### 3. Configure the Public Hostname

Still in the tunnel configuration page:

1. Click the **Public Hostname** tab
2. Click **Add a public hostname**
3. Configure:
   - **Subdomain:** e.g., `openclaw` (this creates `openclaw.yourdomain.com`)
   - **Domain:** Select your Cloudflare-managed domain
   - **Type:** `HTTP`
   - **URL:** `rag-openclaw:18789`

   > The URL uses the container name `rag-openclaw` because cloudflared resolves it via the Docker network.

4. Under **Additional application settings** > **TLS**, you can leave defaults (Cloudflare handles TLS on the public side)
5. Click **Save hostname**

### 4. Start the Stack

```bash
docker compose up -d
```

After a few seconds, your OpenClaw gateway will be accessible at `https://openclaw.yourdomain.com`.

### Optional: Add Zero Trust Access Policies

For extra security, you can restrict who can access the gateway:

1. Go to **Access** > **Applications** in Zero Trust dashboard
2. Click **Add an application** > **Self-hosted**
3. Set the application domain to `openclaw.yourdomain.com`
4. Add access policies (e.g., email allowlist, SSO, one-time PIN)

This adds an authentication layer before users even reach the OpenClaw gateway.

---

## Usage

### Start the Stack

```bash
docker compose up -d
```

This starts both `rag-openclaw` (the agent container) and `cloudflared` (the tunnel).

### Stop the Stack

```bash
docker compose down
```

Add `-v` to also remove named volumes (this deletes persisted state):

```bash
docker compose down -v
```

### Access the OpenClaw Gateway UI

- **Locally:** `http://localhost:18789`
- **Remotely:** `https://openclaw.yourdomain.com` (via Cloudflare tunnel)

Authenticate with your `OPENCLAW_GATEWAY_TOKEN`.

### Attach to the Container

Open an interactive shell inside the running container:

```bash
docker exec -it rag-openclaw bash
```

Or use the helper script (see [Host Helper Scripts](#host-helper-scripts)):

```bash
./outside-scripts/sh-openclaw
```

### Run CLI Tools

```bash
# Claude Code
docker exec -it rag-openclaw claude --version

# OpenCode CLI
docker exec -it rag-openclaw opencode --version

# Kimi CLI
docker exec -it rag-openclaw kimi --version

# OpenClaw
docker exec -it rag-openclaw openclaw --version
```

### Generate an SSH Key

To use Git over SSH inside the container:

```bash
docker exec -it rag-openclaw gen-ssh-key
```

This generates an Ed25519 key pair and prints the public key. Add the public key to your GitHub/GitLab account under SSH keys.

The key persists in the `openclaw-state` volume at `/home/agent/.openclaw`. To persist it separately, consider mounting `~/.ssh` as a volume.

### Clone Repositories

A dedicated `repos` volume is mounted at `/home/agent/repos`:

```bash
docker exec -it rag-openclaw bash
cd ~/repos
git clone git@github.com:your-org/your-repo.git
```

The `repos` volume persists across container restarts.

---

## Host Helper Scripts

The `outside-scripts/` directory contains host-side helper scripts.

### Setup

```bash
# Make scripts executable
chmod +x outside-scripts/*

# Option A: Add to PATH
export PATH="$(pwd)/outside-scripts:$PATH"

# Option B: Create an alias
alias sh-openclaw='./outside-scripts/sh-openclaw'
```

### sh-openclaw

Attaches to the running `rag-openclaw` container and starts an interactive OpenClaw session:

```bash
sh-openclaw
```

If the container is not running, it will show an error and suggest starting it.

---

## Building from Source

To build the image locally instead of pulling from Docker Hub:

```bash
# Build for amd64
docker build --platform linux/amd64 -t hosteurdkuser/rag-openclaw:v0.3.0 .

# Or use docker compose
docker compose build
```

To push to Docker Hub:

```bash
docker login
docker push hosteurdkuser/rag-openclaw:v0.3.0
docker push hosteurdkuser/rag-openclaw:latest
```

---

## Volumes

| Volume | Mount Point | Purpose |
|---|---|---|
| `./workspace` (bind mount) | `/home/agent/workspace` | Working directory, synced with host |
| `openclaw-state` (named) | `/home/agent/.openclaw` | OpenClaw config, state, and SSH keys |
| `repos` (named) | `/home/agent/repos` | Git cloned repositories |

Named volumes persist across container restarts and rebuilds. Use `docker compose down -v` to remove them.

---

## Installed Tools

| Tool | Version | Purpose |
|---|---|---|
| Claude Code | 2.1.x | Anthropic's CLI for Claude |
| OpenCode CLI | 1.1.x | AI coding assistant |
| OpenClaw | latest | Personal AI assistant with gateway UI |
| Kimi CLI | 1.11.x | Moonshot AI coding agent |
| Node.js | 22 LTS | JavaScript runtime |
| Python 3 | 3.12 | Python runtime |
| uv | latest | Python package manager |
| Git | 2.43 | Version control |
| ripgrep | 14.x | Fast search |
| jq | 1.7 | JSON processor |
| tmux | - | Terminal multiplexer |
| vim | - | Text editor |
| build-essential | - | C/C++ compiler toolchain |
| sqlite3 | - | SQLite database |

---

## Security

- **Non-root user:** The container runs as `agent` (UID 1000), not root
- **No secrets in the image:** All API keys and tokens are provided at runtime via `.env`
- **Token authentication:** The OpenClaw gateway requires a token for access
- **Cloudflare TLS:** All external traffic is encrypted via Cloudflare's edge
- **Trusted proxies:** Only the Docker bridge network is trusted for proxy headers
- **`.dockerignore`:** Prevents `.env`, `.git`, and `node_modules` from being included in the image

---

## Architecture

```
                    Internet
                       |
                 [Cloudflare Edge]
                   TLS termination
                       |
              ┌────────┴────────┐
              │   cloudflared   │
              │  (tunnel agent) │
              └────────┬────────┘
                       │ Docker network
              ┌────────┴────────┐
              │  rag-openclaw   │
              │                 │
              │  - OpenClaw GW  │ :18789 (UI + WebSocket)
              │  - Claude Code  │
              │  - OpenCode CLI │
              │  - Kimi CLI     │
              │  - Dev tools    │
              └─────────────────┘
                       │
              ┌────────┴────────┐
              │    Volumes      │
              │                 │
              │ - workspace     │ (bind mount)
              │ - openclaw-state│ (named volume)
              │ - repos         │ (named volume)
              └─────────────────┘
```

---

## Troubleshooting

### Container won't start

Check logs:
```bash
docker compose logs rag-openclaw
```

### Cloudflare tunnel not connecting

1. Verify the `CLOUDFLARE_TUNNEL_TOKEN` in `.env` is correct
2. Check cloudflared logs:
   ```bash
   docker compose logs cloudflared
   ```
3. Ensure the tunnel is active in the Cloudflare Zero Trust dashboard

### OpenClaw gateway unreachable via tunnel

1. Verify the public hostname points to `rag-openclaw:18789` (not `localhost`)
2. Ensure both containers are on the same Docker network (default compose network)
3. Check that the gateway is running:
   ```bash
   docker exec rag-openclaw curl -s http://localhost:18789
   ```

### SSH key not persisting

The SSH key is stored in `/home/agent/.ssh/`. To persist it, add an explicit volume mount:
```yaml
volumes:
  - ssh-keys:/home/agent/.ssh
```

### CLI tool not found

If a tool isn't found as the `agent` user, check it's in PATH:
```bash
docker exec rag-openclaw which claude opencode kimi openclaw
```
