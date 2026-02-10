# Outside Scripts

Host-side helper scripts for interacting with the running OpenClaw containers.

## Setup

Add this folder to your PATH or create aliases:

```bash
# Option A: add to PATH
export PATH="/path/to/Charvis/direct/outside-scripts:$PATH"

# Option B: create aliases
alias sh-openclaw='/path/to/Charvis/direct/outside-scripts/sh-openclaw'
alias openclaw-cli='/path/to/Charvis/direct/outside-scripts/openclaw-cli'
```

Make the scripts executable (one-time):

```bash
chmod +x /path/to/Charvis/direct/outside-scripts/sh-openclaw
chmod +x /path/to/Charvis/direct/outside-scripts/openclaw-cli
```

## Scripts

### sh-openclaw

Opens an interactive OpenClaw shell inside the running `rag-openclaw-direct` container.

**Prerequisites:** The container must be running.

```bash
# Start the stack
docker compose up -d

# Attach to OpenClaw
sh-openclaw
```

If the container is not running, the script will print an error and exit.

### openclaw-cli

Runs OpenClaw CLI commands inside a temporary container. The container is created
from the `openclaw-cli` service (which uses the `cli` profile) and is automatically
removed after the command finishes.

**Prerequisites:** None -- the container is spun up on demand; the gateway does not
need to be running.

```bash
# Onboard / initial setup
openclaw-cli onboard

# Log in to channels
openclaw-cli channels login

# Check status
openclaw-cli status

# List agents
openclaw-cli agents list
```

Any arguments you pass are forwarded directly to the `openclaw` binary inside the
container. Run without arguments for the default interactive CLI.
