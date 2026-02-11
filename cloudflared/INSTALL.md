# Installation Guide

Step-by-step guide to install, configure, and run RAG OpenClaw with Cloudflare Zero Trust protection.

---

## Prerequisites

- **Docker Desktop** (macOS/Windows) or **Docker Engine + Docker Compose v2** (Linux)
- A **Cloudflare account** (free tier works) with at least one domain added
- A terminal with `bash` or `zsh`

---

## Step 1: Clone the Repository

```bash
git clone <your-repo-url> Charvis
cd Charvis
```

---

## Step 2: Set Up Cloudflare Zero Trust Tunnel

The OpenClaw gateway UI must not be exposed directly to the internet. A Cloudflare Tunnel creates an encrypted outbound-only connection from your Docker host to Cloudflare's edge, so no inbound ports need to be opened on your firewall.

### 2.1 Log in to Cloudflare Zero Trust

1. Go to [https://one.dash.cloudflare.com/](https://one.dash.cloudflare.com/)
2. Select your account
3. You should land on the Zero Trust dashboard

> If this is your first time, Cloudflare will walk you through creating a Zero Trust organization. The free plan supports up to 50 users.
>
> Docs: [Get started with Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/)

### 2.2 Create a Tunnel

1. In the sidebar, go to **Networks** > **Tunnels**
2. Click **Create a tunnel**
3. Select **Cloudflared** as the connector type
4. Name your tunnel (e.g., `openclaw-gateway`)
5. Click **Save tunnel**

> Docs: [Create a remotely-managed tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/)

### 2.3 Copy the Tunnel Token

After saving, Cloudflare displays connector install commands. Look for:

```
cloudflared service install eyJhIjoiNjQ1...
```

The long string after `install` is your **tunnel token**. Copy it — you will need it in the setup script.

> Do not share this token. It grants full access to run a connector for your tunnel.

### 2.4 Configure the Public Hostname

Still on the tunnel configuration page:

1. Click the **Public Hostname** tab
2. Click **Add a public hostname**
3. Fill in:

| Field | Value |
|---|---|
| **Subdomain** | Your choice, e.g. `openclaw` |
| **Domain** | Select a domain managed by Cloudflare |
| **Type** | `HTTP` |
| **URL** | `rag-openclaw:18789` |

> **Why `rag-openclaw:18789`?** The `cloudflared` container and the `rag-openclaw` container share a Docker network. Docker DNS resolves the container name `rag-openclaw` automatically. Port `18789` is the OpenClaw gateway default.

4. Leave TLS settings as default — Cloudflare terminates TLS on the public side automatically
5. Click **Save hostname**

Your gateway will be available at `https://openclaw.yourdomain.com` once the stack is running.

> Docs: [Route traffic to your tunnel (public hostnames)](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/routing-to-tunnel/)

### 2.5 (Recommended) Add a Zero Trust Access Policy

By default, anyone with the URL and gateway token can access the UI. To add an extra authentication layer in front of it:

1. Go to **Access** > **Applications**
2. Click **Add an application**
3. Select **Self-hosted**
4. Set:
   - **Application name:** `OpenClaw Gateway`
   - **Application domain:** `openclaw.yourdomain.com`
5. Click **Next**
6. Create an **Access Policy**:
   - **Policy name:** `Allow team`
   - **Action:** `Allow`
   - **Include rule:** Choose an identity method, e.g.:
     - **Emails** — allowlist specific email addresses
     - **Email domains** — allow everyone at `@yourcompany.com`
     - **Login methods** — require SSO (Google, GitHub, etc.)
     - **One-time PIN** — Cloudflare emails a code to the user
7. Click **Save**

Now users must authenticate through Cloudflare Access before reaching the OpenClaw gateway.

> Docs:
> - [Self-hosted applications](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/self-hosted-apps/)
> - [Access policies](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/)
> - [Designing ZTNA access policies](https://developers.cloudflare.com/reference-architecture/design-guides/designing-ztna-access-policies/)

---

## Step 3: Run the Setup Script

The interactive setup script configures everything in one pass:

```bash
./setup.sh
```

It will prompt you for:

| Prompt | Required | Notes |
|---|---|---|
| Cloudflare Tunnel token | **Yes** | The token you copied in Step 2.3 |
| Anthropic API key | No | Enables Claude Code and OpenClaw AI features |
| OpenAI API key | No | Enables OpenCode CLI with OpenAI models |
| Kimi API key | No | Enables Kimi CLI |
| GitHub token | No | Enables Git operations via HTTPS |

All API keys are **optional** — you can add them later by editing `.env`. Only the Cloudflare Tunnel token and `OPENCLAW_GATEWAY_TOKEN` (auto-generated) are needed to start the stack.

The script will automatically:

1. Write all variables to `.env`
2. Generate a random `OPENCLAW_GATEWAY_TOKEN` for gateway authentication
3. Generate an SSH key pair (Ed25519) for Git operations
4. Make the helper scripts executable
5. Add `outside-scripts/` to your shell PATH

At the end, it prints a summary with:
- Your gateway token
- Your SSH public key (to add to GitHub/GitLab)
- Commands to start the stack

---

## Step 4: Add the SSH Key to GitHub/GitLab

The setup script generated an SSH key pair and printed the public key. Add it to your Git provider:

### GitHub

1. Go to [https://github.com/settings/keys](https://github.com/settings/keys)
2. Click **New SSH key**
3. Title: `openclaw-agent`
4. Paste the public key
5. Click **Add SSH key**

### GitLab

1. Go to **Preferences** > **SSH Keys**
2. Paste the public key
3. Click **Add key**

You can view the public key again at any time:

```bash
cat .ssh-agent/id_ed25519.pub
```

---

## Step 5: Start the Stack

```bash
docker compose up -d
```

This starts two always-on containers:

| Container | Image | Purpose |
|---|---|---|
| `rag-openclaw` | `hosteurdkuser/rag-openclaw:v0.7.0` | Agent environment + OpenClaw gateway |
| `cloudflared` | `cloudflare/cloudflared:latest` | Tunnel connector to Cloudflare edge |

A third service, `openclaw-cli`, is available on demand for running OpenClaw CLI commands:

```bash
# Via the helper script
openclaw-cli <command>

# Or directly via Docker Compose
docker compose run --rm openclaw-cli <command>
```

Check that everything is running:

```bash
docker compose ps
```

View logs:

```bash
docker compose logs -f
```

---

## Step 6: Connect

### Via terminal (local)

```bash
sh-openclaw
```

Or directly:

```bash
docker exec -it rag-openclaw bash
```

### Via HTTPS gateway (remote)

Open your browser and go to:

```
https://openclaw.yourdomain.com
```

Authenticate with the gateway token printed by the setup script. You can retrieve it from `.env`:

```bash
grep OPENCLAW_GATEWAY_TOKEN .env
```

---

## Updating

### Pull the latest image

```bash
docker compose pull rag-openclaw
docker compose up -d
```

### Rebuild from source

```bash
docker compose build --no-cache
docker compose up -d
```

---

## Stopping

```bash
# Stop containers (keeps volumes)
docker compose down

# Stop and delete all volumes (data loss!)
docker compose down -v
```

---

## File Overview

```
cloudflared/
  Dockerfile            # Image definition
  docker-compose.yml    # Service orchestration (gateway + CLI + cloudflared)
  entrypoint.sh         # Container entrypoint
  openclaw.json         # OpenClaw gateway config
  setup.sh              # Interactive setup script
  .env.example          # Environment variable template
  .env                  # Your actual config (created by setup.sh)
  .ssh-agent/           # SSH key pair (created by setup.sh)
  .dockerignore         # Build exclusions
  workspace/            # Bind-mounted working directory
  outside-scripts/
    sh-openclaw         # Host helper: attach to running gateway container
    openclaw-cli        # Host helper: run OpenClaw CLI commands
    README.md           # Helper scripts documentation
  INSTALL.md            # This file
```

---

## Troubleshooting

### Tunnel not connecting

```bash
docker compose logs cloudflared
```

- Verify `CLOUDFLARE_TUNNEL_TOKEN` in `.env` matches the token from the Cloudflare dashboard
- Ensure the tunnel status is **Active** in Zero Trust > Networks > Tunnels

> Docs: [Cloudflare Tunnel troubleshooting](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)

### Gateway unreachable via HTTPS

- Verify the public hostname in Cloudflare points to `rag-openclaw:18789` (not `localhost`)
- Both containers must be on the same Docker network (default compose behavior)
- Test from inside cloudflared:
  ```bash
  docker exec cloudflared wget -qO- http://rag-openclaw:18789 || echo "unreachable"
  ```

### SSH key not working inside container

The key is mounted read-only from `.ssh-agent/`. Verify:

```bash
docker exec rag-openclaw ls -la /home/agent/.ssh/
```

The private key must have permissions `600` or stricter. If Git complains, check the host-side permissions:

```bash
chmod 600 .ssh-agent/id_ed25519
chmod 644 .ssh-agent/id_ed25519.pub
```

### "Permission denied" for CLI tools

Ensure the container runs as `agent`:

```bash
docker exec rag-openclaw whoami
# Expected: agent
```

---

## Reference Links

- [Cloudflare Zero Trust — Getting started](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/)
- [Create a remotely-managed tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/)
- [Route traffic to your tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/routing-to-tunnel/)
- [Self-hosted applications](https://developers.cloudflare.com/cloudflare-one/applications/configure-apps/self-hosted-apps/)
- [Access policies](https://developers.cloudflare.com/cloudflare-one/access-controls/policies/)
- [Designing ZTNA access policies](https://developers.cloudflare.com/reference-architecture/design-guides/designing-ztna-access-policies/)
- [Cloudflare Tunnel downloads](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/downloads/)
