# Outside Scripts

Host-side helper scripts for interacting with the running OpenClaw containers.

## Setup

Add this folder to your PATH or create aliases:

```bash
# Option A: add to PATH
export PATH="/path/to/Charvis/outside-scripts:$PATH"

# Option B: create aliases
alias sh-openclaw='/path/to/Charvis/outside-scripts/sh-openclaw'
alias openclaw-cli='/path/to/Charvis/outside-scripts/openclaw-cli'
```

Make the scripts executable (one-time):

```bash
chmod +x /path/to/Charvis/outside-scripts/sh-openclaw
chmod +x /path/to/Charvis/outside-scripts/openclaw-cli
```

## Scripts

### sh-openclaw

Opens an interactive OpenClaw shell inside the running `rag-openclaw` container.

**Prerequisites:** The container must be running.

```bash
# Start the stack
docker compose up -d

# Attach to OpenClaw
sh-openclaw
```

If the container is not running, the script will print an error and exit.

### openclaw-cli

Runs OpenClaw CLI commands in a temporary container. The container is created from
the `openclaw-cli` service profile and removed automatically after the command
finishes. This is useful for one-off administrative tasks without exec-ing into
the long-running gateway container.

**Prerequisites:** The Docker Compose stack does not need to be running. The CLI
container shares the same volumes and env file as the gateway, so state is
consistent between both.

```bash
# Run the onboarding wizard
openclaw-cli onboard

# Log in to configured channels
openclaw-cli channels login

# Check gateway and agent status
openclaw-cli status

# List registered agents
openclaw-cli agents list

# Any other openclaw subcommand works the same way
openclaw-cli <subcommand> [args...]
```
